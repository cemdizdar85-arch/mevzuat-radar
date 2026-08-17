# ============================================================================
#  REJIM / IGV KAYNAK INDIRICISI (17.08.2026)
#
#  Cem: "otomatik indirsin ama hep ayni seyi konusmayalim, her sey otomatik
#  olacak." Bu betik GTIP ailesinin EKSIK HALKASIYDI.
#
#  SORUN (olculdu): vergi-hasat / tarim-hasat / askiya-hasat / balik-hasat /
#  emy-hasat / nihai-hasat / igv-hasat-ulke betiklerinin hepsi ZATEN yazili ve
#  calisiyor - ama varsayilan kaynaklari eski bir oturumun GECICI klasoruydu
#  (.../45bc0a17.../scratchpad/rejim2026). O klasorler bugun BOS. Yani 7 veri
#  dosyasi Ithalat Rejimi Karari degistiginde SESSIZCE eskiyordu.
#
#  13.08 NOTU DUZELTILDI: "ticaret.gov.tr'de xlsx linkleri govdede YOK" tespiti
#  DIZIN sayfasi icin dogruydu, ama ALT SAYFALAR taranmamisti. Bugun olculdu:
#    /ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri
#      -> .../1-ithalat-rejimi-karari...        icinde  "rejim 2026.zip" (1,37 MB, 22 girdi)
#      -> .../2-ithalatta-ilave-gumruk-vergisi... icinde "IGV.zip"
#  Yani RG'ye gerek YOK; kaynak dogrudan ve robota acik.
#
#  LINK ID'SI SABIT YAZILMAZ: /data/68d2951f.../ gibi CDN kimlikleri Bakanlik
#  dosyayi yeniden yukleyince DEGISIR. Bu yuzden her kosuda dizin -> alt sayfa
#  -> zip zinciri YENIDEN cozulur. Sabit link yazmak, bu betigi bir yil sonra
#  sessizce olu birakirdi.
#
#  KOR KALMA KURALI: link bulunamaz / zip bozuk / beklenenden kucukse
#  MAIL gider ve exit 1. "Sessizce eski veriyle devam" YOK.
#
#  Kullanim:
#    ./motor/rejim-indir.ps1              # OLCUM: indirir, sayar, rapor eder
#    ./motor/rejim-indir.ps1 -Uygula      # + hasatcilari kosar (veri/*.json yazilir)
#    ./motor/rejim-indir.ps1 -Zorla       # damga ayni olsa da yeniden isle
#
#  PARA HARCAMAZ: yalniz ticaret.gov.tr'den sayfa + zip indirir.
# ============================================================================
param(
  [switch]$Uygula,
  [switch]$Zorla,
  [string]$Klasor = "",          # bos ise gecici klasor kullanilir
  [switch]$MailKapali
)
$ErrorActionPreference = "Continue"
if($PSVersionTable.PSVersion.Major -lt 6){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$DIZIN = 'https://www.ticaret.gov.tr/ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri'
# alt sayfa slug'i tam eslesmez (yil/adlandirma degisebilir) - DESEN ile aranir
$KAYNAKLAR = @(
  @{ ad='rejim'; altDesen='1-ithalat-rejimi-karari';           enAzBayt = 400000; param='RejimKlasor' },
  @{ ad='igv';   altDesen='2-ithalatta-ilave-gumruk-vergisi';  enAzBayt =  20000; param='IgvKlasor'   }
)

# curl: PS5.1'in TLS'i ticaret.gov.tr'ye yetmiyor (yanveri-onarici.ps1'de de
# ayni sebeple curl kullaniliyor). Linux pwsh'te ad "curl", Windows'ta "curl.exe".
$CURL = if($IsLinux -or $IsMacOS){ 'curl' } else { 'curl.exe' }
$UA   = 'Mozilla/5.0 (compatible; mevzuat-radar-robot/1.0)'

function Mail([string]$konu,[string]$govde){
  if($MailKapali){ Write-Host "  (mail kapali) $konu"; return }
  try {
    $mb = @{ access_key='5b227e56-94fb-4123-a39a-4286f63db14a'; subject=$konu; from_name='Tetikte Rejim Indirici'; email='cemdizdar85@hotmail.com'; message=$govde } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Uri 'https://api.web3forms.com/submit' -Method Post -ContentType 'application/json' -Body $mb -TimeoutSec 30 | Out-Null
  } catch { Write-Host ("  mail gonderilemedi: {0}" -f $_.Exception.Message) }
}

function SayfaCek([string]$url){
  $gecici = [IO.Path]::GetTempFileName()
  & $CURL -s -L --max-time 60 -A $UA $url -o $gecici 2>$null | Out-Null
  if(-not (Test-Path $gecici)){ return '' }
  $t = [IO.File]::ReadAllText($gecici); Remove-Item $gecici -Force -ErrorAction SilentlyContinue
  # Bakanligin hata sayfasi HTTP 200 ile geliyor - govdeden anlamak sart
  if($t -match 'Internal Server Error'){ return '' }
  return $t
}

Write-Host '======== REJIM / IGV KAYNAK INDIRICISI ========'
Write-Host ("  mod: {0}" -f $(if($Uygula){'UYGULA (hasatcilar kosacak)'}else{'OLCUM (veri/ yazilmaz)'}))

$dizinHtml = SayfaCek $DIZIN
if(-not $dizinHtml){
  Mail 'TETIKTE KIRMIZI - rejim indirici: DIZIN SAYFASI ACILMADI' "Adres: $DIZIN`nSayfa bos dondu ya da Internal Server Error verdi. Bakanlik site yapisi degismis olabilir."
  Write-Host 'KIRMIZI: dizin sayfasi acilmadi.' -ForegroundColor Red; exit 1
}
Write-Host ("  dizin sayfasi: {0} bayt" -f $dizinHtml.Length)

# indirme klasoru
if(-not $Klasor){ $Klasor = Join-Path ([IO.Path]::GetTempPath()) 'mevzuat-rejim-kaynak' }
if(-not (Test-Path $Klasor)){ New-Item -ItemType Directory -Path $Klasor -Force | Out-Null }

# onceki damga
$damgaYol = Join-Path $kok 'veri/rejim-kaynak-damga.json'
$eskiDamga = @{}
if(Test-Path $damgaYol){
  try { foreach($p in ((Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json).damga.PSObject.Properties)){ $eskiDamga[$p.Name] = $p.Value } } catch {}
}

$yeniDamga = @{}; $degisen = @(); $klasorler = @{}; $hata = 0
foreach($K in $KAYNAKLAR){
  Write-Host ''
  Write-Host ("--- {0} ---" -f $K.ad.ToUpper())

  # (1) dizin -> alt sayfa
  $altYol = $null
  foreach($m in [regex]::Matches($dizinHtml, 'href="(/ithalat/ithalat-mevzuati/ithalat-rejimi-karari-igv-karari-ve-ithalat-tebligleri/[^"]+)"')){
    if($m.Groups[1].Value -match [regex]::Escape($K.altDesen)){ $altYol = $m.Groups[1].Value; break }
  }
  if(-not $altYol){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} ALT SAYFASI BULUNAMADI" -f $K.ad) "Dizin sayfasinda '$($K.altDesen)' desenine uyan link yok. Sayfa yapisi degismis olabilir: $DIZIN"
    Write-Host ("  KIRMIZI: alt sayfa bulunamadi (desen: {0})" -f $K.altDesen) -ForegroundColor Red; $hata++; continue
  }
  Write-Host ("  alt sayfa: {0}" -f $altYol)

  # (2) alt sayfa -> zip linki
  $altHtml = SayfaCek ('https://www.ticaret.gov.tr' + $altYol)
  if(-not $altHtml){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} alt sayfasi acilmadi" -f $K.ad) "Adres: https://www.ticaret.gov.tr$altYol"
    Write-Host '  KIRMIZI: alt sayfa acilmadi.' -ForegroundColor Red; $hata++; continue
  }
  $zipUrl = $null
  foreach($m in [regex]::Matches($altHtml, 'href="(https://ticaret\.gov\.tr/data/[^"]+\.zip)"')){ $zipUrl = [Net.WebUtility]::HtmlDecode($m.Groups[1].Value); break }
  if(-not $zipUrl){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} ZIP LINKI YOK" -f $K.ad) "Alt sayfada .zip linki bulunamadi: https://www.ticaret.gov.tr$altYol`nBakanlik dosya bicimini degistirmis olabilir."
    Write-Host '  KIRMIZI: zip linki bulunamadi.' -ForegroundColor Red; $hata++; continue
  }
  Write-Host ("  zip: {0}" -f $zipUrl)

  # (3) indir
  $zipYol = Join-Path $Klasor ($K.ad + '.zip')
  if(Test-Path $zipYol){ Remove-Item $zipYol -Force }
  & $CURL -s -L --max-time 300 -A $UA ([Uri]::EscapeUriString($zipUrl)) -o $zipYol 2>$null | Out-Null
  if(-not (Test-Path $zipYol)){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} indirilemedi" -f $K.ad) "Adres: $zipUrl"
    Write-Host '  KIRMIZI: indirilemedi.' -ForegroundColor Red; $hata++; continue
  }
  $boyut = (Get-Item $zipYol).Length
  # ZIP magic + taban boyut: HTML hata sayfasi .zip adiyla kaydedilirse yakalanir
  $ilk2 = [IO.File]::ReadAllBytes($zipYol) | Select-Object -First 2
  if($boyut -lt $K.enAzBayt -or $ilk2[0] -ne 0x50 -or $ilk2[1] -ne 0x4B){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} zip BOZUK" -f $K.ad) "Indirilen dosya {0} bayt ve ZIP imzasi tasimiyor (beklenen en az {1}). Adres: {2}" -f $boyut, $K.enAzBayt, $zipUrl
    Write-Host ("  KIRMIZI: zip bozuk / cok kucuk ({0} bayt)" -f $boyut) -ForegroundColor Red; $hata++; continue
  }
  $sha = (Get-FileHash $zipYol -Algorithm SHA256).Hash
  $yeniDamga[$K.ad] = @{ sha256=$sha; bayt=$boyut; url=$zipUrl; tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm') }
  Write-Host ("  indirildi: {0:N0} bayt | sha {1}" -f $boyut, $sha.Substring(0,12))

  $eski = $null; if($eskiDamga.ContainsKey($K.ad)){ $eski = $eskiDamga[$K.ad].sha256 }
  if($eski -eq $sha -and -not $Zorla){
    Write-Host '  DEGISMEMIS (kaynak taze) - acilmadi.'
    continue
  }
  if($eski){ Write-Host ("  DEGISMIS! eski sha {0} -> yeni {1}" -f $eski.Substring(0,12), $sha.Substring(0,12)) -ForegroundColor Yellow }
  else     { Write-Host '  ilk indirme (onceki damga yok).' }

  # (4) ac
  $cikarDir = Join-Path $Klasor $K.ad
  if(Test-Path $cikarDir){ Remove-Item $cikarDir -Recurse -Force }
  New-Item -ItemType Directory -Path $cikarDir -Force | Out-Null
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    [IO.Compression.ZipFile]::ExtractToDirectory($zipYol, $cikarDir)
  } catch {
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} zip acilmadi" -f $K.ad) ("Hata: " + $_.Exception.Message)
    Write-Host ("  KIRMIZI: zip acilmadi - {0}" -f $_.Exception.Message) -ForegroundColor Red; $hata++; continue
  }
  $xlsx = @(Get-ChildItem $cikarDir -Filter *.xlsx -Recurse)
  Write-Host ("  acildi: {0} dosya ({1} xlsx)" -f @(Get-ChildItem $cikarDir -Recurse -File).Count, $xlsx.Count)
  if($xlsx.Count -eq 0){
    Mail ("TETIKTE KIRMIZI - rejim indirici: {0} icinde xlsx YOK" -f $K.ad) "Zip acildi ama tek bir .xlsx cikmadi. Bakanlik dosya bicimini degistirmis olabilir (xls/pdf?). Adres: $zipUrl"
    Write-Host '  KIRMIZI: xlsx yok.' -ForegroundColor Red; $hata++; continue
  }
  $klasorler[$K.param] = $cikarDir
  $degisen += $K.ad
}

Write-Host ''
Write-Host ("  degisen kaynak: {0}" -f $(if($degisen.Count){ $degisen -join ', ' } else { 'yok' }))

if($hata -gt 0){ Write-Host ("KIRMIZI bitis - {0} kaynak alinamadi." -f $hata) -ForegroundColor Red; exit 1 }

if(-not $Uygula){
  Write-Host ''
  Write-Host 'OLCUM MODU - hasatcilar kosmadi, veri/ ve damga YAZILMADI.'
  Write-Host 'Yazmak icin: ./motor/rejim-indir.ps1 -Uygula'
  exit 0
}

if($degisen.Count -eq 0){
  Write-Host 'Kaynak degismemis - hasat gereksiz, veri korundu.'
  exit 0
}

# (5) hasatcilari kos
Write-Host ''
Write-Host '--- HASAT ---'
$hepsi = Join-Path $here 'hepsini-hasat.ps1'
$hp = @{}
foreach($k in $klasorler.Keys){ $hp[$k] = $klasorler[$k] }
$global:LASTEXITCODE = 0
& $hepsi @hp
# $LASTEXITCODE MIRAS KALABILIR: "duserek" biten bir betikten sonra deger
# icerideki son komuttan gelir. Bu yuzden cagrindan once sifirlanir ve $null
# basari sayilir. (Ilk kosuda 7/7 basarili hasat HATA sanilmisti.)
$hasatKod = if($null -eq $LASTEXITCODE){ 0 } else { $LASTEXITCODE }
if($hasatKod -ne 0){
  Mail 'TETIKTE KIRMIZI - rejim indirici: HASAT HATALI' "Kaynak indirildi ve acildi ama hepsini-hasat.ps1 hata kodu $hasatKod dondu. veri/ dosyalari kismi kalmis olabilir - kontrol et."
  Write-Host 'KIRMIZI: hasat hatali - damga YAZILMADI (bir dahaki kosuda yeniden denenecek).' -ForegroundColor Red
  exit 1
}

# (6) damga - YALNIZ hasat basarili olduysa. Basarisiz kosuda damga yazilirsa
#     kaynak "islenmis" sayilir ve bir daha hic denenmez (sessiz olum).
$damgaObj = [ordered]@{
  aciklama = 'Ithalat Rejimi / IGV kaynak zip damgasi. Ayni sha256 gelirse hasat tekrarlanmaz.'
  guncelleme = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  damga = $yeniDamga
}
[IO.File]::WriteAllText($damgaYol, ($damgaObj | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($true)))
Write-Host ("Damga yazildi: veri/rejim-kaynak-damga.json")
Mail 'TETIKTE - Ithalat Rejimi/IGV verisi tazelendi' ("Degisen kaynak: " + ($degisen -join ', ') + "`nHasat basarili, GTIP veri dosyalari yeniden uretildi.")
Write-Host 'BITTI - yesil.'
exit 0
