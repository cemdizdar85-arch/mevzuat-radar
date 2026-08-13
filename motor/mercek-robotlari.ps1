# ============================================================================
#  UC MERCEK ROBOTU (13.08.2026) — 0 USD, MODEL YOK, KASAYA YAZMAZ
#
#  CEM: "robot kurun elle birebir dogrulasin; birisi KANUN dogru diye baksin,
#        birisi MUHASEBE HESAPLARI dogru diye baksin."
#  Karsiligi: ayni gun ornekleme okurken bulunan dort kusurun UCU deterministik
#  olarak yakalanabilir - model gerekmez. Bu betik uc merceği ayri ayri kosar:
#
#  MERCEK A — MEVZUAT: sorunun dayandigi maddeyi AMBARDAN cekip, dogru sikkin
#     "Kural:" bolumundeki kilit terimlerin o madde metninde gecip gecmedigine
#     bakar. Hic ortusme yoksa "kaynak var ama soyledigini soylemiyor" (KIRMIZI).
#     NOT: anlam denetimi degil ORTUSME denetimidir; sifir ortusme kesin kusurdur,
#     ortusme varsa "temiz" demez, yalnizca supheyi kaldirir.
#
#  MERCEK B — HESAP: iki is yapar.
#     B1 THP KOD-AD: soru + SIKLAR + aciklama icindeki "NNN - AD" ciftlerini
#        resmi THP listesiyle karsilastirir. Ornek vakasi: sikta "500 - ODENECEK
#        VERGI VE FONLAR" yaziyordu (500 = SERMAYE). Eski K4 kapisi SIKLARA
#        BAKMIYORDU; bu mercek bakar.
#     B2 ARITMETIK: dogru sikkin aciklamasindaki "a + b + c = X" kaliplarini
#        yeniden hesaplar; toplam tutmuyorsa ya da X dogru sikkin degeriyle
#        uyusmuyorsa KIRMIZI. Ornek vakasi: 307.840 yazilmisti, dogrusu 307.700.
#
#  MERCEK C — CELISKI: dogru sikkin aciklamasi baska bir sikki DOGRULUYOR mu?
#     (cift dogru sik tespiti). Ornek vakasi: D'nin aciklamasi B'yi teyit ediyordu.
#
#  Kapsam: yayin havuzu (veri/yayin-havuzu-olcum.json) | -tumKasa ile hepsi
#  Cikti: veri/mercek-robotlari.json   ·   KARAR VERMEZ, ADAY URETIR.
# ============================================================================
# ESIKLER VERIDEN SECILDI (13.08 kalibrasyon, 1.500 soruluk olcum):
#   MERCEK A — ortusme dagilimi: ortanca %53,3 · en yuksek %100 · alt %5 dilim SIFIR.
#     Esik 12 -> 186 aday (%16, cok gurultulu) | Esik 1 -> 68 aday (%5,9, yalniz
#     SIFIR ortusmeliler). SIFIR ortusme "kaynak soyledigini soylemiyor"un en guclu
#     gostergesidir; okuyucuya once bunlar gider. VARSAYILAN 1 SECILDI.
#   MERCEK C — esik 85 -> 102 aday (%6,8) | esik 95 -> 45 aday (%3). Yuksek esik
#     "dogru sikkin aciklamasi yanlis sikkin NEREDEYSE TUM kelimelerini iceriyor"
#     demektir; cift-dogru ihtimali cok daha yuksek. VARSAYILAN 95 SECILDI.
#   Esikler gevsetilebilir (-aEsik 12 -cEsik 85) - genis tarama gerekince.
param([switch]$tumKasa, [int]$enCok = 0, [double]$aEsik = 1, [double]$cEsik = 95)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buradaKlasor = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokKlasor = Split-Path -Parent $buradaKlasor
$veriYolu = Join-Path $kokKlasor 'veri'
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$baslik = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$adres = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$harfler = @('A','B','C','D','E')

# --- Turkce duyarsiz sadelestirme (yayin-kapisi ile ayni mantik) ---
$harfEsleme = @{ [char]0x0130='I'; [char]0x0131='I'; [char]'i'='I'; [char]'I'='I'
  [char]0x015E='S'; [char]0x015F='S'; [char]0x011E='G'; [char]0x011F='G'
  [char]0x00DC='U'; [char]0x00FC='U'; [char]0x00D6='O'; [char]0x00F6='O'
  [char]0x00C7='C'; [char]0x00E7='C' }
function Sade([string]$metin){
  if($null -eq $metin){ return '' }
  $yazi = New-Object Text.StringBuilder
  foreach($karakter in $metin.ToCharArray()){
    if($harfEsleme.ContainsKey($karakter)){ [void]$yazi.Append($harfEsleme[$karakter]); continue }
    $buyuk = [char]::ToUpperInvariant($karakter)
    if(($buyuk -ge 'A' -and $buyuk -le 'Z') -or ($buyuk -ge '0' -and $buyuk -le '9')){ [void]$yazi.Append($buyuk) } else { [void]$yazi.Append(' ') }
  }
  return (($yazi.ToString()) -replace '\s+',' ').Trim()
}

# --- THP resmi kod->ad sozlugu ---
$thpSozluk = @{}
foreach($dosya in (Get-ChildItem (Join-Path $veriYolu 'mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try{
    $icerik = Get-Content $dosya.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($belge in @($icerik.belgeler)){
      $eslesme = [regex]::Match("$($belge.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($eslesme.Success -and -not $thpSozluk.ContainsKey($eslesme.Groups[1].Value)){ $thpSozluk[$eslesme.Groups[1].Value] = $eslesme.Groups[2].Value.Trim() }
    }
  } catch {}
}
Write-Host ("THP sozlugu: {0} hesap" -f $thpSozluk.Count)
if($thpSozluk.Count -lt 200){ Write-Host 'DURDU: THP sozlugu eksik - Mercek B1 calisamaz.'; exit 1 }

# --- ambar madde metinleri (Mercek A icin): kanun_no -> madde_no -> metin ---
$ambar = @{}
foreach($dosya in (Get-ChildItem (Join-Path $veriYolu 'mevzuat') -Filter '*.json' | Where-Object { $_.Name -notmatch '^_' })){
  try{
    $icerik = Get-Content $dosya.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($belge in @($icerik.belgeler)){
      $ad = "$($belge.kaynak_ad)"
      $m = [regex]::Match($ad, '(?i)(\d{3,5})\s*s\..*?\bm\.(\d+(?:/[A-Za-zÇĞİÖŞÜçğıöşü])?)')
      if(-not $m.Success){ $m = [regex]::Match($ad, '(?i)\bm\.(\d+)') ; if($m.Success){ continue } }
      if($m.Success -and $m.Groups.Count -ge 3){
        $anahtar = "$($m.Groups[1].Value)|$($m.Groups[2].Value)"
        if(-not $ambar.ContainsKey($anahtar)){ $ambar[$anahtar] = '' }
        $ambar[$anahtar] += ' ' + "$($belge.metin)"
      }
    }
  } catch {}
}
Write-Host ("Ambar madde anahtari: {0}" -f $ambar.Count)

# --- hedef kume ---
$hedef = $null
if(-not $tumKasa){
  $olcum = Get-Content (Join-Path $veriYolu 'yayin-havuzu-olcum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $hedef = @{}; foreach($kimlik in @($olcum.idler)){ $hedef["$kimlik"] = $true }
  Write-Host ("Kapsam: yayin havuzu {0} soru" -f $hedef.Count)
}

# --- kasayi cek ---
$sorular = New-Object System.Collections.Generic.List[object]
for($kayma=0; $kayma -lt 40000; $kayma+=500){
  $sayfa = $null
  for($deneme=1; $deneme -le 3; $deneme++){
    try{ $cevap = Invoke-WebRequest -UseBasicParsing -Uri "$adres`?select=id,ders,soru,siklar,dogru,aciklama,kanun_no,madde_no,kaynak&order=id&limit=500&offset=$kayma" -Headers $baslik -TimeoutSec 180
         $sayfa = ([Text.Encoding]::UTF8.GetString($cevap.RawContentStream.ToArray()) | ConvertFrom-Json); break }
    catch { if($deneme -eq 3){ $sayfa=@() } else { Start-Sleep -Seconds (3*$deneme) } }
  }
  if(@($sayfa).Count -eq 0){ if($kayma -gt 30000){ break } else { continue } }
  foreach($soru in $sayfa){ if($null -eq $hedef -or $hedef.ContainsKey("$($soru.id)")){ $sorular.Add($soru) } }
  if(@($sayfa).Count -lt 500){ break }
  if($enCok -gt 0 -and $sorular.Count -ge $enCok){ break }
}
if($enCok -gt 0 -and $sorular.Count -gt $enCok){ $sorular = $sorular[0..($enCok-1)] }
Write-Host ("Denetlenecek: {0} soru" -f $sorular.Count)

# --- desenler ---
# 13.08 DENETCI DERSI (yanlis alarm 6/30): desen "487.300 - Hammadde odemesi"
# gibi TUTARIN son uc hanesini hesap kodu saniyordu. Cozum: kodun onunde rakam,
# nokta ya da virgul OLMAYACAK (negatif lookbehind). Denetci raporu:
# veri/denetci/muhasebe-b1-hukum.json
$reKodAd  = [regex]'(?<![\d.,])(?<kod>[1-7]\d{2})\s*[-–—:]\s*(?<ad>[A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\s\.,\/]{4,60})'
$reAdKod  = [regex]'(?<ad>[A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\s\.,\/]{4,60}?)\s*\(\s*(?<kod>[1-7]\d{2})\s*\)'
$reToplam = [regex]'(?<liste>(?:\d{1,3}(?:\.\d{3})*(?:,\d+)?\s*\+\s*){1,8}\d{1,3}(?:\.\d{3})*(?:,\d+)?)\s*=\s*(?<sonuc>\d{1,3}(?:\.\d{3})*(?:,\d+)?)'
$reKuralBl= [regex]'(?s)Kural\s*:\s*(.+?)(?:\n\s*\n|Bu olayda)'
$birimler = @('TL','ADET','KG','GUN','AY','YIL','SAAT','METRE','M2','TON','LITRE','PUAN')

# 13.08 KENDI HATAM: TryParse varsayilan olarak MAKINE KULTURUNU (tr-TR) kullaniyordu;
# "486.56" degeri 48656 diye okunuyordu (tr-TR'de nokta binlik ayracidir) ve mercek
# sahte bulgu uretiyordu. Ayrıştırma artik INVARIANT kulturle yapilir.
function SayiCoz([string]$metin){
  $t = ($metin -replace '\.','') -replace ',','.'
  $deger = 0.0
  if([double]::TryParse($t, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$deger)){ return $deger }
  return $null
}

$aOranlar = New-Object System.Collections.Generic.List[double]
$aBulgu = New-Object System.Collections.Generic.List[object]
$b1Bulgu = New-Object System.Collections.Generic.List[object]
$b2Bulgu = New-Object System.Collections.Generic.List[object]
$cBulgu  = New-Object System.Collections.Generic.List[object]
$aOlculen=0; $b2Olculen=0

foreach($soru in $sorular){
  $dogruHarf = "$($soru.dogru)".Trim().ToUpper()
  if($harfler -notcontains $dogruHarf){ continue }
  $dogruAciklama = ''; try { if($soru.aciklama -and $soru.aciklama.PSObject.Properties[$dogruHarf]){ $dogruAciklama = "$($soru.aciklama.$dogruHarf)" } } catch {}
  $sikMetinleri = @{}
  foreach($harf in $harfler){ $deger=''; try { if($soru.siklar -and $soru.siklar.PSObject.Properties[$harf]){ $deger = "$($soru.siklar.$harf)" } } catch {}; $sikMetinleri[$harf] = $deger }

  # ---------- MERCEK B1: THP kod-ad (SIKLAR DAHIL) ----------
  $taranacak = @{ 'soru' = "$($soru.soru)"; 'aciklama' = $dogruAciklama }
  foreach($harf in $harfler){ $taranacak["sik-$harf"] = $sikMetinleri[$harf] }
  foreach($alan in $taranacak.Keys){
    $metin = $taranacak[$alan]
    if([string]::IsNullOrWhiteSpace($metin)){ continue }
    $ciftler = New-Object System.Collections.Generic.List[object]
    foreach($e in $reKodAd.Matches($metin)){ $ciftler.Add(@{ kod=$e.Groups['kod'].Value; ad=$e.Groups['ad'].Value.Trim() }) }
    foreach($e in $reAdKod.Matches($metin)){ $ciftler.Add(@{ kod=$e.Groups['kod'].Value; ad=$e.Groups['ad'].Value.Trim() }) }
    foreach($cift in $ciftler){
      if(-not $thpSozluk.ContainsKey($cift.kod)){ continue }
      $yazilan = Sade $cift.ad
      if($yazilan.Length -lt 5){ continue }
      $ilkKelime = ($yazilan -split ' ')[0]
      if($birimler -contains $ilkKelime){ continue }
      $resmi = Sade $thpSozluk[$cift.kod]
      # ortusme: yazilanin ilk anlamli kelimesi resmi adda geciyor mu (ya da tersi)
      $ortusme = $false
      foreach($kelime in ($yazilan -split ' ')){
        if($kelime.Length -lt 4){ continue }
        if($resmi -like "*$kelime*"){ $ortusme = $true; break }
      }
      if(-not $ortusme){
        $b1Bulgu.Add([pscustomobject]@{ id="$($soru.id)"; ders="$($soru.ders)"; alan=$alan; kod=$cift.kod; yazilan=$cift.ad; resmi=$thpSozluk[$cift.kod] })
      }
    }
  }

  # ---------- MERCEK B2: aritmetik ----------
  if($dogruAciklama -match '\+'){
    foreach($e in $reToplam.Matches($dogruAciklama)){
      $b2Olculen++
      $terimler = @($e.Groups['liste'].Value -split '\+' | ForEach-Object { SayiCoz ($_.Trim()) })
      if($terimler -contains $null){ continue }
      $beklenen = 0.0; foreach($t in $terimler){ $beklenen += $t }
      $yazilanSonuc = SayiCoz $e.Groups['sonuc'].Value
      if($null -eq $yazilanSonuc){ continue }
      if([math]::Abs($beklenen - $yazilanSonuc) -gt 0.51){
        $b2Bulgu.Add([pscustomobject]@{ id="$($soru.id)"; ders="$($soru.ders)"; ifade=$e.Value; yazilan=$yazilanSonuc; hesaplanan=$beklenen; fark=[math]::Round($beklenen-$yazilanSonuc,2) })
        break
      }
    }
  }

  # ---------- MERCEK A: mevzuat ortusmesi ----------
  $kanunNo = "$($soru.kanun_no)".Trim(); $maddeNo = "$($soru.madde_no)".Trim()
  if($kanunNo -ne '' -and $maddeNo -ne ''){
    $anahtar = "$kanunNo|$maddeNo"
    if($ambar.ContainsKey($anahtar)){
      $aOlculen++
      $kuralEsl = $reKuralBl.Match($dogruAciklama)
      $kuralMetni = if($kuralEsl.Success){ $kuralEsl.Groups[1].Value } else { $dogruAciklama }
      $maddeSade = Sade $ambar[$anahtar]
      # 13.08 SESSIZ HATA: parantezsiz yazilinca PowerShell "-split" ifadesini
      # Sade fonksiyonuna ARGUMAN sandi; $kilitler tek bir string oldu, Count hep 1
      # kaldi ve "if(Count -ge 5)" hic saglanmadi -> MERCEK A HIC OLCUM YAPMADAN
      # "0 bulgu" raporladi. Sifir bulgu veren kapiya inanmama kurali burada isledi.
      $kilitler = @(((Sade $kuralMetni) -split ' ') | Where-Object { $_.Length -ge 6 } | Select-Object -Unique)
      if($kilitler.Count -ge 5){
        $bulunan = 0
        foreach($kilit in $kilitler){ if($maddeSade -like "*$kilit*"){ $bulunan++ } }
        $oran = [math]::Round(100.0*$bulunan/$kilitler.Count,1)
        # 13.08 KALIBRASYON: esik korlemesine secilmesin diye TUM oranlar toplanir;
        # "hic bulgu vermeyen kapi" supheli sayilir (bugunun dersi). Dagilim rapora yazilir.
        $script:aOranlar.Add($oran)
        # Esik ARTIK VERIDEN secilir: ilk kosuda tum oranlar toplanip dagilim
        # raporlanir; %5'lik dilim esik alinir (yani en dusuk ortusmeli %5).
        # -aEsik parametresiyle disaridan da verilebilir.
        if($oran -lt $aEsik){
          $aBulgu.Add([pscustomobject]@{ id="$($soru.id)"; ders="$($soru.ders)"; kaynak="$($soru.kaynak)"; kanun=$kanunNo; madde=$maddeNo; ortusme_yuzde=$oran; kilit_sayisi=$kilitler.Count })
        }
      }
    }
  }

  # ---------- MERCEK C: dogru sikkin aciklamasi baska sikki dogruluyor mu ----------
  if($dogruAciklama.Length -ge 100){
    $aciklamaSade = Sade $dogruAciklama
    foreach($harf in $harfler){
      if($harf -eq $dogruHarf){ continue }
      $sik = $sikMetinleri[$harf]
      if($sik.Length -lt 40){ continue }
      $sikSade = Sade $sik
      $kelimeler = @($sikSade -split ' ' | Where-Object { $_.Length -ge 6 } | Select-Object -Unique)
      if($kelimeler.Count -lt 5){ continue }
      $gecen = 0; foreach($kelime in $kelimeler){ if($aciklamaSade -like "*$kelime*"){ $gecen++ } }
      $ortusme = [math]::Round(100.0*$gecen/$kelimeler.Count,1)
      # dogru sikkin aciklamasi yanlis sikkin NEREDEYSE TAMAMINI iceriyorsa,
      # o sikki dogrulamis olma ihtimali yuksektir (cift dogru adayi)
      if($ortusme -ge $cEsik){
        $cBulgu.Add([pscustomobject]@{ id="$($soru.id)"; ders="$($soru.ders)"; dogru=$dogruHarf; supheli_sik=$harf; ortusme_yuzde=$ortusme })
        break
      }
    }
  }
}

$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  kapsam=$(if($tumKasa){'tum-kasa'}else{'yayin-havuzu'}); denetlenen=$sorular.Count
  MercekA_kalibrasyon=$(if($aOranlar.Count -gt 0){ $sirali=@($aOranlar | Sort-Object); [ordered]@{ olculen=$sirali.Count; en_dusuk=$sirali[0]; yuzde1=$sirali[[int]($sirali.Count*0.01)]; yuzde5=$sirali[[int]($sirali.Count*0.05)]; ortanca=$sirali[[int]($sirali.Count*0.5)]; en_yuksek=$sirali[$sirali.Count-1]; not='Esik %12 idi ve 0 bulgu verdi. Yuzde1/yuzde5 degerlerine bakip esik yeniden secilecek - hic bulgu vermeyen kapi supheli sayilir.' } } else { 'olculemedi' })
  MercekA_mevzuat=[ordered]@{ olculen=$aOlculen; bulgu=$aBulgu.Count; not='dogru sikkin Kural bolumu ile ambar madde metni arasinda %12 alti kelime ortusmesi = "kaynak soyledigini soylemiyor" adayi'; ornek=@($aBulgu | Select-Object -First 25); idler=@($aBulgu | ForEach-Object { $_.id } | Sort-Object -Unique) }
  MercekB1_thp_kod_ad=[ordered]@{ bulgu=$b1Bulgu.Count; not='SIKLAR DAHIL taranir - eski K4 kapisi siklara bakmiyordu'; ornek=@($b1Bulgu | Select-Object -First 25); idler=@($b1Bulgu | ForEach-Object { $_.id } | Sort-Object -Unique) }
  MercekB2_aritmetik=[ordered]@{ olculen=$b2Olculen; bulgu=$b2Bulgu.Count; not='aciklamadaki a+b+c=X ifadesi yeniden hesaplandi'; ornek=@($b2Bulgu | Select-Object -First 25); idler=@($b2Bulgu | ForEach-Object { $_.id } | Sort-Object -Unique) }
  MercekC_celiski=[ordered]@{ bulgu=$cBulgu.Count; not='dogru sikkin aciklamasi bir yanlis sikkin %85+ kelimesini iceriyor = cift dogru adayi'; ornek=@($cBulgu | Select-Object -First 25); idler=@($cBulgu | ForEach-Object { $_.id } | Sort-Object -Unique) }
  kural='MERCEKLER ADAY URETIR, KARAR VERMEZ. Her aday elle okunur (GM-OKUYUCU-SARTNAME.md).'
}
[IO.File]::WriteAllText((Join-Path $veriYolu 'mercek-robotlari.json'), (ConvertTo-Json $rapor -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("MERCEK A (mevzuat)   : {0} bulgu ({1} soruda olculebildi)" -f $aBulgu.Count, $aOlculen)
Write-Host ("MERCEK B1 (THP kod)  : {0} bulgu" -f $b1Bulgu.Count)
Write-Host ("MERCEK B2 (aritmetik): {0} bulgu ({1} ifade olculdu)" -f $b2Bulgu.Count, $b2Olculen)
Write-Host ("MERCEK C (celiski)   : {0} bulgu" -f $cBulgu.Count)
Write-Host ("-> {0}" -f (Join-Path $veriYolu 'mercek-robotlari.json'))
