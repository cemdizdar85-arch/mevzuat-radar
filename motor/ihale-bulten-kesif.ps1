# ============================================================================
#  KAMU IHALE BULTENI KESIF - 4734 s.K. m.47: "ihale sonuclari ... Kurum
#  tarafindan Kamu Ihale Bulteninde yayimlanir". ilan.gov.tr sonuc ilani
#  YAYIMLAMIYOR (600 ilan olculdu), EKAP arama API'si korumali (401).
#  Bu betik TEK gunluk bulten PDF'ini indirir ve icindeki SONUC ILANI bolumunu
#  olcer. Cem onayi 13.08: "bir gunluk bulten PDF'ini indirip ... olc".
#  OLCUM betigi - kasaya/siteye HICBIR SEY YAZMAZ.
#  Cikti: scratchpad'e PDF + metin, ekrana olcum.
# ============================================================================
param(
  [ValidateSet('Mal','Yapim','Hizmet','Danismanlik')][string]$Tur = 'Mal',
  [string]$Klasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\94aa3424-c78a-4612-b9eb-65883203c30d\scratchpad"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if(-not (Test-Path $Klasor)){ New-Item -ItemType Directory -Force $Klasor | Out-Null }

$adres = "https://ekap.kik.gov.tr/ekap/ilan/bultenindirme.aspx"
# 12.08 dersi: PS 5.1 IWR'nin varsayilan Mozilla UA'si bazi kamu uclarinda reddediliyor;
# UA acikca yazilir. (Bkz. supabase-tarayici-kimligi dersi - ayni tuzagin akrabasi.)
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-BultenKesif/1.0"
$oturum = $null

Write-Host "1) Sayfa aliniyor (ViewState icin)..."
$s1 = Invoke-WebRequest -Uri $adres -Headers @{ "User-Agent" = $ua } -SessionVariable oturum -TimeoutSec 90 -UseBasicParsing
Write-Host ("   HTTP {0} · {1} bayt" -f $s1.StatusCode, $s1.RawContentLength)

# ASP.NET gizli alanlarini oku
function GizliAl([string]$html, [string]$ad){
  $m = [regex]::Match($html, 'id="' + [regex]::Escape($ad) + '"[^>]*value="([^"]*)"')
  if($m.Success){ return $m.Groups[1].Value }
  $m2 = [regex]::Match($html, 'name="' + [regex]::Escape($ad) + '"[^>]*value="([^"]*)"')
  if($m2.Success){ return $m2.Groups[1].Value }
  return ""
}
$html = $s1.Content
# OLCUM (tarayicida gercek formu POST ederek bulundu): bu sayfa __VIEWSTATE'i BOS
# birakiyor ama __PIT / __PITC / hdnAktIKN alanlari olmadan "Hata" sayfasi donuyor.
# Formdaki TUM gizli alanlar aynen tasinir - eksigi hatayi sessizce dogurur.
$govde = @{
  '__EVENTTARGET'        = "ctl00`$ContentPlaceHolder1`$lnkBtn$Tur"
  '__EVENTARGUMENT'      = ''
  '__VIEWSTATE'          = (GizliAl $html '__VIEWSTATE')
  '__PIT'                = (GizliAl $html '__PIT')
  '__PITC'               = (GizliAl $html '__PITC')
  '__SCROLLPOSITIONX'    = (GizliAl $html '__SCROLLPOSITIONX')
  '__SCROLLPOSITIONY'    = (GizliAl $html '__SCROLLPOSITIONY')
  '__EVENTVALIDATION'    = (GizliAl $html '__EVENTVALIDATION')
  'ctl00$Menu1$hdnAktIKN' = (GizliAl $html 'ctl00_Menu1_hdnAktIKN')
  'ctl00$ContentPlaceHolder1$ddlstBxIhaleTur' = '0'
  'ctl00$ContentPlaceHolder1$etBultenTarihi$EkapTakvimTextBox_etBultenTarihi' = ''
}
Write-Host ("   VIEWSTATE {0} karakter · EVENTVALIDATION {1} karakter" -f $govde['__VIEWSTATE'].Length, $govde['__EVENTVALIDATION'].Length)
# NOT: bu sayfada __VIEWSTATE BOS geliyor (olculdu) - ASP.NET ViewState'i kapatilmis.
# Bos ViewState ile postback gecerli; kapiyi __EVENTVALIDATION tutuyor.
if(-not $govde['__EVENTVALIDATION']){ Write-Host "DUR: EventValidation okunamadi - sayfa yapisi degismis."; exit 1 }

Write-Host "2) Bulten isteniyor ($Tur, bugun)..."
$pdfYol = Join-Path $Klasor ("kamu-ihale-bulteni-{0}.pdf" -f $Tur.ToLower())
$inenYol = Join-Path $Klasor ("kamu-ihale-bulteni-{0}.ham" -f $Tur.ToLower())
# TUZAK (13.08 olculdu): Invoke-WebRequest'in .Content'i IKILI veriyi metne cevirip
# BOZUYOR - 10,5 MB'lik ZIP 15,8 MB "metin" olarak geldi ve acilmadi. Ikili indirme
# -OutFile ile yapilir. (Ayni ailenin dersi: kor-kalma-kurali, PS byte[] tuzagi.)
try {
  Invoke-WebRequest -Uri $adres -Method Post -Body $govde -WebSession $oturum `
    -Headers @{ "User-Agent" = $ua; "Referer" = $adres } -TimeoutSec 300 -UseBasicParsing `
    -OutFile $inenYol
} catch {
  Write-Host ("HATA: {0}" -f $_.Exception.Message); exit 1
}
if(-not (Test-Path $inenYol)){ Write-Host "DUR: dosya inmedi."; exit 1 }
$boyHam = (Get-Item $inenYol).Length
Write-Host ("   inen: {0:N0} bayt" -f $boyHam)
if($boyHam -lt 100000){
  Write-Host "   Bulten gelmedi (hata sayfasi dondu). Ilk 300 karakter:"
  Write-Host ("   " + ((Get-Content $inenYol -Raw -Encoding UTF8) -replace '\s+',' ').Substring(0,300))
  exit 1
}
# PS 7 uyumu: "Get-Content -Encoding Byte" kaldirildi, .NET ile okunur
$fsK = [IO.File]::OpenRead($inenYol); $ilkIki = @($fsK.ReadByte(), $fsK.ReadByte()); $fsK.Close()
$zipMi = ($ilkIki[0] -eq 0x50 -and $ilkIki[1] -eq 0x4B)
if($zipMi){
  $zipYol = Join-Path $Klasor ("kamu-ihale-bulteni-{0}.zip" -f $Tur.ToLower())
  Copy-Item $inenYol $zipYol -Force
  Write-Host ("   ZIP indi: {0} ({1:N0} bayt) - aciliyor..." -f $zipYol, $boyHam)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $arsiv = [IO.Compression.ZipFile]::OpenRead($zipYol)
  $giris = @($arsiv.Entries | Where-Object { $_.Name -match '\.pdf$' })[0]
  if(-not $giris){ Write-Host "DUR: ZIP icinde PDF yok."; $arsiv.Dispose(); exit 1 }
  Write-Host ("   ZIP icindeki dosya: {0} ({1:N0} bayt)" -f $giris.Name, $giris.Length)
  [IO.Compression.ZipFileExtensions]::ExtractToFile($giris, $pdfYol, $true)
  $arsiv.Dispose()
} else {
  Copy-Item $inenYol $pdfYol -Force
}
$boy = (Get-Item $pdfYol).Length
Write-Host ("   -> {0} ({1:N0} bayt)" -f $pdfYol, $boy)

# --- PDF -> metin (Turkce icin -enc UTF-8 SART, eski ders) --------------------
$txtYol = [IO.Path]::ChangeExtension($pdfYol, '.txt')
$pdftotext = (Get-Command pdftotext -ErrorAction SilentlyContinue)
if(-not $pdftotext){ Write-Host "NOT: pdftotext yok - metin olcumu atlandi. PDF indi, elle bakilabilir."; exit 0 }
& pdftotext -enc UTF-8 -layout $pdfYol $txtYol
if(-not (Test-Path $txtYol)){ Write-Host "DUR: metne cevrilemedi."; exit 1 }
$metin = Get-Content $txtYol -Raw -Encoding UTF8
Write-Host ("3) Metin: {0:N0} karakter" -f $metin.Length)

# --- SONUC ILANI olcumu ------------------------------------------------------
Write-Host "`n=== BOLUM IZLERI ==="
$desenler = [ordered]@{
  'SONUC ILANI basligi'   = '(?im)^\s*.{0,60}SONU[ÇC]\s*[İI]LAN'
  'Ihale sonuc ilani'     = '(?i)ihale\s+sonu[çc]\s+ilan'
  'Sozlesme bedeli'       = '(?i)s[öo]zle[şs]me\s+bedeli'
  'Yuklenici / kazanan'   = '(?i)y[üu]klenici|[üu]zerine\s+b[ıi]rak[ıi]l|ihale\s+edilen'
  'Ihale kayit numarasi'  = '(?i)ihale\s+kay[ıi]t\s+numaras[ıi]'
  'Teklif edilen bedel'   = '(?i)teklif\s+edilen\s+bedel'
  'IPTAL ilani'           = '(?i)iptal\s+ilan'
  'DUZELTME ilani'        = '(?i)d[üu]zeltme\s+ilan'
  'On ilan'               = '(?i)[öo]n\s+ilan'
}
foreach($d in $desenler.GetEnumerator()){
  $n = ([regex]::Matches($metin, $d.Value)).Count
  Write-Host ("  {0,-22} : {1}" -f $d.Key, $n)
}

# Sonuc ilani gercekten varsa, ilk ornegi goster (yapiyi gormek icin)
$mm = [regex]::Match($metin, '(?is)(ihale\s+sonu[çc]\s+ilan.{0,2500})')
if($mm.Success){
  Write-Host "`n=== ILK SONUC ILANI ORNEGI (yapi icin) ==="
  Write-Host ($mm.Groups[1].Value -replace '\r?\n\s*\r?\n', "`n")
} else {
  Write-Host "`nSONUC: Bu bultende 'ihale sonuc ilani' ifadesi GECMIYOR."
}
Write-Host ("`nMetin dosyasi: {0}" -f $txtYol)
