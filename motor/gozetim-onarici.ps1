# ============================================================================
#  GOZETIM ONARICI (13.08.2026) — Cem: "2 kontrol 3 kontrol, elle birebir
#  okuyarak, haber beklemeden degissin."
#
#  ILKE: HICBIR DEGER TEK OKUMAYLA BASILMAZ.
#   Okuyucu A = deterministik PDF parser (pdftotext -layout). Birlesik hucre
#               yuzunden bir satirin degerini KESIN cozemiyorsa BELIRSIZ der,
#               ASLA tahmin etmez.
#   Okuyucu B = Claude (api-hedef cift hat: Anthropic ya da AWS). PDF'i belge
#               olarak okur, tabloyu JSON dondurur. Anahtar yoksa atlanir.
#   HAKEM    = A'nin KESIN satirlari B ile BIREBIR ayni + B, A'nin BELIRSIZ
#              satirlarini tamamliyor ve kod kumesi tutuyorsa -> MUTABAKAT:
#              gtip-durum.json'a o tebligin satirlari yazilir (-Uygula ile).
#              Uyusmazlik -> KIRMIZI: yazilmaz, mail + cikis 1.
#
#  KULLANIM:
#    ./motor/gozetim-onarici.ps1 -TebligNo "2020/1" -MevzuatNo 34304 [-Uygula]
#    ./motor/gozetim-onarici.ps1 -Damgadan [-Uygula]   # teblig-damga.json'daki degisenler
# ============================================================================
param(
  [string]$TebligNo,
  [int]$MevzuatNo,
  [switch]$Damgadan,
  [switch]$Uygula,
  [switch]$Bekleyenler,  # yururlugu gelmis BEKLEMEDE kayitlari basar (gunluk kosu)
  [string]$RgTarihi      # PDF'te RG tarihi yoksa elle: "11.07.2026"
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0'

function Mail([string]$konu,[string]$govde){
  $mb = @{ access_key='5b227e56-94fb-4123-a39a-4286f63db14a'; subject=$konu; from_name='Tetikte Gozetim Onarici'; email='cemdizdar85@hotmail.com'; message=$govde } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Uri 'https://api.web3forms.com/submit' -Method Post -ContentType 'application/json' -UserAgent 'Mozilla/5.0 (TetikteNobetci)' -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 30 | Out-Null } catch { Write-Host "mail gitmedi: $($_.Exception.Message)" }
}

# ---------- OKUYUCU A: deterministik parser ---------------------------------
function OkuyucuA([string]$pdfYol){
  $txt = [IO.Path]::ChangeExtension($pdfYol, '.layout.txt')
  & pdftotext -layout -enc UTF-8 $pdfYol $txt 2>$null
  if(-not (Test-Path $txt)){ throw "pdftotext uretmedi: $pdfYol" }
  $satirlar = Get-Content $txt -Encoding UTF8
  # tablo bolgesi: 'Birim Gumruk Kiymeti' basligindan '*Kg:'/'*Ton:' dipnotuna
  $bas=-1; $son=-1; $birim=''
  for($i=0;$i -lt $satirlar.Count;$i++){
    if($bas -lt 0 -and $satirlar[$i] -match 'Birim\s+G.mr.k'){ $bas=$i }
    if($bas -ge 0 -and $birim -eq '' -and $satirlar[$i] -match 'Dolar[ıi]\s*/\s*([A-Za-z]+)'){ $birim=$Matches[1] }
    if($bas -ge 0 -and $satirlar[$i] -match '^\s*\*\s*(Kg|Ton|Adet)'){ $son=$i; break }
  }
  if($bas -lt 0 -or $son -lt 0){ return @{ kesin=$false; birim=''; satirlar=@{}; belirsiz=@('TABLO BULUNAMADI') } }
  # blok = bir GTIP kodundan sonrakine kadar; blokta tam 1 sayisal deger varsa KESIN
  $rxKod = '^\s*((?:\d{2}\.\d{2})|(?:\d{4}\.\d{2}(?:\.\d{2}\.\d{2}\.\d{2})?))'
  $bloklar=@(); $aktif=$null
  for($i=$bas+1;$i -lt $son;$i++){
    $L=$satirlar[$i]
    if($L -match $rxKod -and $L -notmatch 'hari[cç]\)'){
      if($aktif){ $bloklar+=,$aktif }
      $aktif=@{ kod=$Matches[1]; icerik=@($L) }
    } elseif($aktif){ $aktif.icerik += $L }
  }
  if($aktif){ $bloklar+=,$aktif }
  $sonuc=@{}; $belirsiz=@()
  foreach($b in $bloklar){
    # satir sonundaki yalniz sayi (deger sutunu): 0,6 / 4,5 / 1.000 / 25 gibi
    $degerler=@()
    foreach($L in $b.icerik){
      if($L -match '(\d{1,3}(?:\.\d{3})*(?:,\d+)?|\d+(?:,\d+)?)\s*$'){
        $aday=$Matches[1]
        # kodun kendisini deger sanma: satir yalniz koddan ibaretse atla
        if($L.Trim() -ne $b.kod -and $aday -ne $b.kod){ $degerler += $aday }
      }
    }
    $degerler = @($degerler | Select-Object -Unique)
    if($degerler.Count -eq 1){ $sonuc[$b.kod] = $degerler[0] }
    else { $belirsiz += $b.kod }
  }
  return @{ kesin=($belirsiz.Count -eq 0 -and $sonuc.Count -gt 0); birim=$birim; satirlar=$sonuc; belirsiz=$belirsiz }
}

# ---------- OKUYUCU B: Claude (cift hat) ------------------------------------
function OkuyucuB([string]$pdfYol){
  . (Join-Path $here 'api-hedef.ps1')
  $hedef = Get-ApiHedef   # anahtar yoksa firlatir -> cagiran yakalar
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pdfYol))
  $istem = "Bu PDF bir Ithalatta Gozetim Tebligi. MADDE 1'deki tabloyu OKU ve YALNIZ su JSON'u dondur (baska hicbir sey yazma): {""birim"":""Kg|Ton|Adet"",""satirlar"":{""GTIPKODU"":""deger""}}. Kurallar: (1) degerler tablodaki BIREBIR sayi (or. 0,6 / 1.000 / 4,5) - tahmin YASAK; (2) birlesik hucrede ayni deger gruptaki HER koda yazilir; (3) parantezli (hharic) satir basi kodlar (or. '70.05 (7005.29 haric)') SADECE ana kod olarak yazilir; (4) okuyamadigin satiri ""BELIRSIZ"" yaz."
  $gov = @{ model='claude-haiku-4-5'; max_tokens=1500; messages=@(@{ role='user'; content=@(
      @{ type='document'; source=@{ type='base64'; media_type='application/pdf'; data=$b64 } },
      @{ type='text'; text=$istem }) }) } | ConvertTo-Json -Depth 8
  $r = Invoke-RestMethod -Uri ($hedef.taban + '/v1/messages') -Method Post -Headers $hedef.basliklar -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -ContentType 'application/json' -TimeoutSec 180
  $m = [regex]::Match(($r.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join '', '\{[\s\S]*\}')
  if(-not $m.Success){ throw 'B: JSON bulunamadi' }
  return $m.Value | ConvertFrom-Json
}

# ---------- YURURLUK ZEKASI (13.08 Cem) ---------------------------------------
# Degisiklik tebligleri cogu kez "yayimi takip eden otuzuncu gun" yururluge
# girer. Sinyal yayim GUNU geldigi icin mutabakatta hemen basmak, HENUZ
# YURURLUKTE OLMAYAN degeri gostermek olur. Kural: tarih coz; gelmediyse
# BEKLEMEDE kasasina yaz, yururluk gunu bas. COZULEMEZSE basma (temkin).
function YururlukCoz([string]$pdfYol){
  $txt = [IO.Path]::ChangeExtension($pdfYol, '.layout.txt')
  if(-not (Test-Path $txt)){ return $null }
  $ham = (Get-Content $txt -Raw -Encoding UTF8) -replace '\s+',' '
  $rgTarih = $null; $cumle = $null
  # 1) degisiklik dipnotu + tablo damgasi: "(Degisik tablo:RG-11/7/2026-33307)"
  $mT = [regex]::Match($ham,'\(De[gğ]i[sş]ik[^)]*RG-(\d{1,2})/(\d{1,2})/(\d{4})')
  $mC = [regex]::Match($ham,'Bu de[gğ]i[sş]iklik[^.]{0,120}y[üu]r[üu]rl[üu][gğ]e girer')
  if($mT.Success -and $mC.Success){
    $rgTarih = Get-Date -Year $mT.Groups[3].Value -Month $mT.Groups[2].Value -Day $mT.Groups[1].Value
    $cumle = $mC.Value
  } else {
    # 2) yeni teblig: Yururluk maddesi + "Yayimlandigi Resmi Gazete" tarihi
    $mC2 = [regex]::Match($ham,'Bu Tebli[gğ][^.]{0,120}y[üu]r[üu]rl[üu][gğ]e girer')
    $mT2 = [regex]::Match($ham,'Yay[ıi]mland[ıi][gğ][ıi] Resm[îi] Gazete[^0-9]{0,40}(\d{1,2})[./](\d{1,2})[./](\d{4})')
    if($mC2.Success -and $mT2.Success){
      $rgTarih = Get-Date -Year $mT2.Groups[3].Value -Month $mT2.Groups[2].Value -Day $mT2.Groups[1].Value
      $cumle = $mC2.Value
    } elseif($mC2.Success -and $script:RgTarihi){
      # PDF'te RG tarih tablosu yok (bazi yeni tebliglerde basilmiyor) - elle verilen tarih
      $p3 = $script:RgTarihi.Split('.')
      $rgTarih = Get-Date -Year $p3[2] -Month $p3[1] -Day $p3[0]
      $cumle = $mC2.Value
    }
  }
  if(-not $cumle){ return $null }
  # gun farkini coz: rakamli ("30 uncu gun") ya da yazili sira sayisi
  $gun = $null
  if($cumle -match 'yay[ıi]m[ıi] tarihinde'){ $gun = 0 }
  elseif($cumle -match '(\d+)\s*(?:uncu|üncü|inci|ıncı|nci|ncı)?\s*g[üu]n'){ $gun = [int]$Matches[1] }
  else {
    $sira = @{ 'birinci'=1;'besinci'=5;'beşinci'=5;'yedinci'=7;'onuncu'=10;'on besinci'=15;'on beşinci'=15;'yirminci'=20;'otuzuncu'=30;'kirk besinci'=45;'kırk beşinci'=45;'altmisinci'=60;'altmışıncı'=60 }
    foreach($k in $sira.Keys){ if($cumle -match $k){ $gun = $sira[$k]; break } }
  }
  if($null -eq $gun){ return $null }
  return @{ tarih = $rgTarih.AddDays($gun); cumle = $cumle; rg = $rgTarih.ToString('dd.MM.yyyy') }
}

# ---------- HAKEM + UYGULAMA -------------------------------------------------
function Normalle([string]$v){ ($v -replace '\s','') }

function YamaUygula([string]$tno,[hashtable]$final,[string]$birim,[string]$kaynak){
  $yol = Join-Path $kok 'veri\gtip-durum.json'
  $d = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $sonucMap=[ordered]@{}
  foreach($p in $d.PSObject.Properties){ $kalan=@(@($p.Value)|Where-Object{$_.teblig -ne $tno}); if($kalan.Count){ $sonucMap[$p.Name]=$kalan } }
  foreach($k in $final.Keys){
    $kayit=[pscustomobject]@{ deger=("{0} USD/{1}" -f $final[$k], $birim); teblig=$tno; kaynak=$kaynak }
    if($sonucMap.Contains($k)){ $sonucMap[$k]=@($sonucMap[$k])+$kayit } else { $sonucMap[$k]=@($kayit) }
  }
  [IO.File]::WriteAllText($yol, ($sonucMap|ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
}

function TebligOnar([string]$tno,[int]$mno){
  Write-Host "=== $tno (mevzuatNo $mno) ==="
  $pdf = Join-Path $env:TEMP ("onarici-" + ($tno -replace '/','-') + ".pdf")
  Invoke-WebRequest -Uri "https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.$mno.pdf" -OutFile $pdf -UserAgent $UA -Headers @{Referer='https://www.mevzuat.gov.tr/'} -TimeoutSec 90 -UseBasicParsing
  $A = OkuyucuA $pdf
  Write-Host ("A: kesin={0} satir={1} belirsiz={2} birim={3}" -f $A.kesin, $A.satirlar.Count, ($A.belirsiz -join ','), $A.birim)
  $B = $null
  try { $B = OkuyucuB $pdf; Write-Host ("B: satir={0} birim={1}" -f (@($B.satirlar.PSObject.Properties).Count), $B.birim) }
  catch { Write-Host ("B kosamadi (anahtar/hat): {0}" -f $_.Exception.Message) }

  if(-not $B){
    $rapor = "Okuyucu B yok (API anahtari takilinca tam otomatik olur). A sonucu:`n" + (($A.satirlar.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" }) -join "`n") + $(if($A.belirsiz){ "`nBELIRSIZ: " + ($A.belirsiz -join ', ') })
    Mail "GOZETIM ONARICI RAPOR ($tno) - tek okuma, BASILMADI" $rapor
    return $false
  }
  # mutabakat: kod kumeleri ayni + A'nin KESIN dedigi her deger B ile birebir
  $bs=@{}; foreach($p in $B.satirlar.PSObject.Properties){ $bs[$p.Name]=$p.Value }
  $uyusmaz=@()
  foreach($k in $A.satirlar.Keys){ if(-not $bs.ContainsKey($k)){ $uyusmaz+="$k yalniz A'da" } elseif((Normalle $A.satirlar[$k]) -ne (Normalle $bs[$k])){ $uyusmaz+="$k A=$($A.satirlar[$k]) B=$($bs[$k])" } }
  foreach($k in $bs.Keys){ if(-not $A.satirlar.ContainsKey($k) -and $A.belirsiz -notcontains $k){ $uyusmaz+="$k yalniz B'de" }; if($bs[$k] -eq 'BELIRSIZ'){ $uyusmaz+="$k B'de BELIRSIZ" } }
  if($uyusmaz.Count -gt 0){
    Mail "GOZETIM ONARICI KIRMIZI ($tno) - iki okuma UYUSMADI, basilmadi" ("Uyusmazlik:`n" + ($uyusmaz -join "`n") + "`nElle bak: RG gorseli + PDF.")
    Write-Host "UYUSMAZLIK - basilmadi."; return $false
  }
  # birlesik kume: A'nin kesinleri + B'nin (A'da belirsiz kalan) tamamlamalari
  $final=@{}; foreach($k in $bs.Keys){ $final[$k]=$bs[$k] }
  $birim = if($A.birim){ $A.birim } else { $B.birim }
  Write-Host ("MUTABAKAT: {0} satir, birim {1}" -f $final.Count, $birim)
  if(-not $Uygula){ Write-Host "(-Uygula verilmedi: rapor modu)"; Mail "GOZETIM ONARICI MUTABAKAT ($tno) - rapor modu" (($final.GetEnumerator()|ForEach-Object{"$($_.Key) = $($_.Value) $birim"}) -join "`n"); return $true }

  $kaynak = "https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=$mno&MevzuatTur=9&MevzuatTertip=5"
  # --- YURURLUK KAPISI: tarih gelmeden BASILMAZ ---
  $y = YururlukCoz $pdf
  if(-not $y){
    Mail "GOZETIM ONARICI KIRMIZI ($tno) - yururluk tarihi COZULEMEDI, basilmadi" ("Mutabakat var ama yururluk cumlesi/RG tarihi metinden cikartilamadi (bazi PDF'lerde RG-tarih tablosu basilmiyor). RG tarihini bul ve soyle kostur:`n./motor/gozetim-onarici.ps1 -TebligNo '$tno' -MevzuatNo $mno -RgTarihi 'GG.AA.YYYY' -Uygula")
    Write-Host "YURURLUK COZULEMEDI - temkin: basilmadi."; return $false
  }
  Write-Host ("Yururluk: {0} (RG {1}; '{2}')" -f $y.tarih.ToString('dd.MM.yyyy'), $y.rg, $y.cumle)
  if((Get-Date).Date -lt $y.tarih.Date){
    # BEKLEMEDE kasasina yaz - yururluk gunu gunluk kosu (-Bekleyenler) basar
    $bYol = Join-Path $kok 'veri\gozetim-bekleyen.json'
    $bek = if(Test-Path $bYol){ Get-Content $bYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { @() }
    $bek = @($bek | Where-Object { $_.teblig -ne $tno })
    $bek += [pscustomobject]@{ teblig=$tno; yururluk=$y.tarih.ToString('yyyy-MM-dd'); birim=$birim; kaynak=$kaynak; satirlar=[pscustomobject]$final; kayitTarihi=(Get-Date).ToString('yyyy-MM-dd') }
    [IO.File]::WriteAllText($bYol, (ConvertTo-Json @($bek) -Depth 6), (New-Object Text.UTF8Encoding($false)))
    Mail "GOZETIM ONARICI BEKLEMEDE ($tno) - yururluk $($y.tarih.ToString('dd.MM.yyyy'))" ("Iki okuma BIREBIR ayni; ama degisiklik henuz yururlukte degil (RG $($y.rg) + '$($y.cumle)').`nO gun OTOMATIK basilacak. Satirlar:`n" + (($final.GetEnumerator()|ForEach-Object{"$($_.Key) = $($_.Value) USD/$birim"}) -join "`n"))
    Write-Host "BEKLEMEDE: yururluk gunu basilacak."; return $true
  }
  YamaUygula $tno $final $birim $kaynak
  Mail "GOZETIM ONARICI DEGISTIRDIM ($tno)" ("Iki bagimsiz okuma BIREBIR ayni cikti (yururluk $($y.tarih.ToString('dd.MM.yyyy')) gecmis); gtip-durum guncellendi:`n" + (($final.GetEnumerator()|ForEach-Object{"$($_.Key) = $($_.Value) USD/$birim"}) -join "`n"))
  Write-Host "UYGULANDI + mail gitti."; return $true
}

# ---------- BEKLEYENLERI BAS (gunluk, anahtarsiz) ------------------------------
function BekleyenleriBas(){
  $bYol = Join-Path $kok 'veri\gozetim-bekleyen.json'
  if(-not (Test-Path $bYol)){ Write-Host "bekleyen yok."; return $true }
  $bek = @(Get-Content $bYol -Raw -Encoding UTF8 | ConvertFrom-Json)
  $kalan=@(); $basilan=0
  foreach($b in $bek){
    if((Get-Date).Date -lt ([datetime]$b.yururluk).Date){ $kalan += $b; continue }
    $final=@{}; foreach($p in $b.satirlar.PSObject.Properties){ $final[$p.Name]=$p.Value }
    YamaUygula $b.teblig $final $b.birim $b.kaynak
    Mail "GOZETIM ONARICI DEGISTIRDIM ($($b.teblig)) - yururluk gunu geldi" ("$($b.yururluk) yururluk tarihi geldi; $($b.kayitTarihi)'de iki okumayla mutabik kalinan satirlar basildi:`n" + (($final.GetEnumerator()|ForEach-Object{"$($_.Key) = $($_.Value) USD/$($b.birim)"}) -join "`n"))
    Write-Host ("BASILDI (yururluk): {0}" -f $b.teblig); $basilan++
  }
  [IO.File]::WriteAllText($bYol, (ConvertTo-Json @($kalan) -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("bekleyen: basilan={0} kalan={1}" -f $basilan, $kalan.Count)
  return $true
}

# ---------- GIRIS -------------------------------------------------------------
if($Bekleyenler){ if(BekleyenleriBas){ exit 0 } else { exit 1 } }
$isler=@()
if($Damgadan){
  $t = Get-Content (Join-Path $kok 'veri\teblig-damga.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($x in @($t.degisen)){
    # mevzuatNo -> teblig no eslemesi gtip-durum'daki kayitlardan bulunur
    $d = Get-Content (Join-Path $kok 'veri\gtip-durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $tn=$null
    foreach($p in $d.PSObject.Properties){ foreach($e in @($p.Value)){ if($e.kaynak -match "MevzuatNo=$($x.mevzuatNo)&"){ $tn=$e.teblig; break } } ; if($tn){break} }
    if($tn){ $isler += @{ tno=$tn; mno=$x.mevzuatNo } } else { Write-Host "eslesmedi: mevzuatNo $($x.mevzuatNo)" }
  }
} else {
  if(-not $TebligNo -or -not $MevzuatNo){ throw 'Ya -Damgadan ya da -TebligNo + -MevzuatNo ver.' }
  $isler = @(@{ tno=$TebligNo; mno=$MevzuatNo })
}
$hepsiTamam=$true
foreach($i in $isler){ if(-not (TebligOnar $i.tno $i.mno)){ $hepsiTamam=$false } }
if(-not $hepsiTamam){ exit 1 }
