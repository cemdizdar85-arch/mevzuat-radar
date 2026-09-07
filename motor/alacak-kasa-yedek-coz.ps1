# ============================================================================
#  ALACAK KASA YEDEGI COZUCU (07.09.2026)
#
#  Bulut yedegi (alacak-kasa-yedek.yml) artifact'i iki dosya tasir:
#    alacak-kasa-YYYYMMDD-HHMM.json.enc    AES-256 ile sifreli yedek
#    alacak-kasa-YYYYMMDD-HHMM.json.k.enc  AES anahtarinin RSA-4096 zarfi
#  Bu betik zarfi OZEL anahtarla acar, dosyayi cozer, satir sayisini dogrular.
#
#  KULLANIM (GitHub'dan artifact zip'ini indirip bir klasore ac):
#    powershell -NoProfile -File motor\alacak-kasa-yedek-coz.ps1 -Klasor "C:\indirilen\alacak-kasa-yedek-12"
#  Ozel anahtar: C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key (varsayilan; -Anahtar ile degisir)
#  openssl: Git for Windows ile gelir; -OpenSsl ile yol verilebilir.
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Klasor,
  [string]$Anahtar = 'C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key',
  [string]$OpenSsl = ''
)
$ErrorActionPreference = 'Stop'

if (-not $OpenSsl) {
  foreach ($aday in @("$env:ProgramFiles\Git\mingw64\bin\openssl.exe", "$env:ProgramFiles\Git\usr\bin\openssl.exe")) {
    if (Test-Path $aday) { $OpenSsl = $aday; break }
  }
  if (-not $OpenSsl) { $c = Get-Command openssl -ErrorAction SilentlyContinue; if ($c) { $OpenSsl = $c.Source } }
}
if (-not $OpenSsl -or -not (Test-Path $OpenSsl)) { throw 'openssl bulunamadi - Git for Windows kur ya da -OpenSsl ile yol ver.' }
if (-not (Test-Path $Anahtar)) { throw "Ozel anahtar yok: $Anahtar (ikinci kopyayi USB/parola kasasindan geri koy)." }

$sifreli = Get-ChildItem $Klasor -Filter 'alacak-kasa-*.json.enc' | Sort-Object Name -Descending | Select-Object -First 1
if (-not $sifreli) { throw "Klasorde alacak-kasa-*.json.enc yok: $Klasor" }
$zarf = Join-Path $Klasor ($sifreli.Name -replace '\.json\.enc$', '.json.k.enc')
if (-not (Test-Path $zarf)) { throw "Anahtar zarfi yok: $zarf" }
$cikti = Join-Path $Klasor ($sifreli.Name -replace '\.enc$', '')
$gecici = Join-Path $Klasor '_k.tmp'

Write-Host ("COZULUYOR: {0}" -f $sifreli.Name)
& $OpenSsl pkeyutl -decrypt -inkey $Anahtar -in $zarf -out $gecici
if ($LASTEXITCODE -ne 0) { throw 'Zarf acilamadi - ozel anahtar bu yedegin acik anahtariyla eslesmiyor olabilir.' }
& $OpenSsl enc -d -aes-256-cbc -pbkdf2 -in $sifreli.FullName -out $cikti -pass "file:$gecici"
$kod = $LASTEXITCODE
[System.IO.File]::Delete($gecici)
if ($kod -ne 0) { throw 'Dosya cozulemedi.' }

# yaz -> geri oku -> karsilastir
$j = Get-Content $cikti -Raw -Encoding UTF8 | ConvertFrom-Json
$adet = @($j.satirlar).Count
Write-Host ("TAMAM: {0} - yedek zamani {1} - kasa={2} dosya={3} satir" -f (Split-Path $cikti -Leaf), $j.yedekZamani, $j.kasaSayi, $adet)
if ($adet -ne [int]$j.kasaSayi) { Write-Host 'UYARI: dosyadaki satir sayisi yedek anindaki kasa sayisiyla esit degil.' }
Write-Host 'Bu dosya TCKN tasir: OneDrive/depo DISINDA tut, is bitince sil.'
