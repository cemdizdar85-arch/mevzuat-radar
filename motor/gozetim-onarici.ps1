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
  [switch]$Uygula
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

# ---------- HAKEM + UYGULAMA -------------------------------------------------
function Normalle([string]$v){ ($v -replace '\s','') }

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

  # gtip-durum yamasi (13.08 revalorizasyon deseni)
  $yol = Join-Path $kok 'veri\gtip-durum.json'
  $d = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $kaynak = "https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=$mno&MevzuatTur=9&MevzuatTertip=5"
  $sonucMap=[ordered]@{}
  foreach($p in $d.PSObject.Properties){ $kalan=@(@($p.Value)|Where-Object{$_.teblig -ne $tno}); if($kalan.Count){ $sonucMap[$p.Name]=$kalan } }
  foreach($k in $final.Keys){
    $kayit=[pscustomobject]@{ deger=("{0} USD/{1}" -f $final[$k], $birim); teblig=$tno; kaynak=$kaynak }
    if($sonucMap.Contains($k)){ $sonucMap[$k]=@($sonucMap[$k])+$kayit } else { $sonucMap[$k]=@($kayit) }
  }
  [IO.File]::WriteAllText($yol, ($sonucMap|ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Mail "GOZETIM ONARICI DEGISTIRDIM ($tno)" ("Iki bagimsiz okuma BIREBIR ayni cikti; gtip-durum guncellendi:`n" + (($final.GetEnumerator()|ForEach-Object{"$($_.Key) = $($_.Value) USD/$birim"}) -join "`n"))
  Write-Host "UYGULANDI + mail gitti."; return $true
}

# ---------- GIRIS -------------------------------------------------------------
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
