# ============================================================================
#  ŞİFRELİ AAB'Yİ İNDİR + ÇÖZ (25.09.2026) — CEM ÇALIŞTIRIR
#
#  mobil-android.yml, Play servis hesabı yokken AAB'yi .enc olarak 3 günlük artifact bırakır
#  (açık depoda şifresiz artifact yasak — motor/artifact-nobeti.ps1). Bu betik:
#    1) son başarılı mobil-android koşusunun artifact'ini C:\TETIKTE-YEDEK\mobil\aab\ altına indirir,
#    2) anahtar-kur.ps1'in yazdığı şifreyle çözer → tetikte-<no>.aab
#  Sonra Play Console → Test → Dahili test → Yeni sürüm → bu .aab dosyası sürüklenir.
#
#  Çalıştırma:  powershell -NoProfile -File mobil/aab-indir.ps1 [-KosuNo <run id>]
# ============================================================================
param([string]$KosuNo = '')
$ErrorActionPreference = 'Stop'

# Yerel araç çağrısı: PS 5.1'de EAP=Stop altında yerel aracın stderr'i yönlendirilince betik ölür
# (CLAUDE.md K6 dersi). Çağrı süresince EAP Continue; çıkış kodu $LASTEXITCODE'dan okunur.
function YerelCalistir([scriptblock]$isBlogu) {
  $eskiTercih = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & $isBlogu } finally { $ErrorActionPreference = $eskiTercih }
}

$depoAdi    = 'cemdizdar85-arch/mevzuat-radar'
$hedefKlasor = 'C:\TETIKTE-YEDEK\mobil\aab'
$sifreYolu  = 'C:\TETIKTE-YEDEK\mobil\anahtar-sifre.txt'
$ghYolu     = 'C:\Program Files\GitHub CLI\gh.exe'
$opensslYolu = 'C:\Program Files\Git\usr\bin\openssl.exe'
if (-not (Test-Path $ghYolu)) { $ghYolu = 'gh' }
if (-not (Test-Path $opensslYolu)) { throw "openssl bulunamadı ($opensslYolu). Git for Windows kurulu olmalı." }
if (-not (Test-Path $sifreYolu)) { throw "$sifreYolu yok. Önce mobil/anahtar-kur.ps1 çalıştırılmalı." }

if (-not $KosuNo) {
  $KosuNo = (YerelCalistir { & $ghYolu run list --repo $depoAdi --workflow mobil-android.yml --status success --limit 1 --json databaseId --jq '.[0].databaseId' })
  if (-not $KosuNo) { throw "Başarılı mobil-android koşusu bulunamadı." }
}
New-Item -ItemType Directory -Force -Path $hedefKlasor | Out-Null
$geciciKlasor = Join-Path $hedefKlasor ("indir-" + $KosuNo)
if (Test-Path $geciciKlasor) { Remove-Item -Recurse -Force $geciciKlasor }
YerelCalistir { & $ghYolu run download $KosuNo --repo $depoAdi --dir $geciciKlasor }
if ($LASTEXITCODE -ne 0) { throw "Artifact indirilemedi (3 günlük süre dolmuş olabilir; iş yeniden koşturulur)." }

$sifreliler = @(Get-ChildItem -Path $geciciKlasor -Recurse -Filter '*.aab.enc')
if ($sifreliler.Count -eq 0) { throw "İndirilen artifact'te .aab.enc yok (servis hesabıyla Play'e yüklenmiş olabilir)." }
foreach ($sifreli in $sifreliler) {
  $cozulmus = Join-Path $hedefKlasor ($sifreli.Name -replace '\.enc$', '')
  YerelCalistir { & $opensslYolu enc -d -aes-256-cbc -pbkdf2 -iter 200000 -in $sifreli.FullName -out $cozulmus -pass ("file:" + $sifreYolu) }
  if ($LASTEXITCODE -ne 0) { throw "Çözülemedi: $($sifreli.Name) (şifre dosyası bu anahtarın mı?)" }
  Write-Host ("HAZIR: {0}  ({1:N1} MB)" -f $cozulmus, ((Get-Item $cozulmus).Length / 1MB))
}
Remove-Item -Recurse -Force $geciciKlasor
Write-Host "Play Console → Test ve yayınla → Dahili test → Yeni sürüm oluştur → .aab dosyasını yükle."
