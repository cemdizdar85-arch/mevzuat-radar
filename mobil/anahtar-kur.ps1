# ============================================================================
#  ANDROID YÜKLEME ANAHTARI KURULUMU (25.09.2026) — CEM ÇALIŞTIRIR, BİR KEZ
#
#  Ne yapar:
#    1) Google Play "yükleme anahtarı"nı (upload key) üretir: C:\TETIKTE-YEDEK\mobil\tetikte-yukleme.jks
#       (OneDrive DIŞI — OneDrive dosyayı sessizce geri alabiliyor).
#    2) Rastgele 32 karakterlik şifre üretir, yanına anahtar-sifre.txt olarak yazar.
#       Şifre EKRANA BASILMAZ; Claude oturumları görmez.
#    3) İkisini GitHub sırrı olarak depoya koyar (gh ile):
#       MOBIL_ANDROID_ANAHTAR_B64 · MOBIL_ANDROID_ANAHTAR_SIFRE
#
#  Play "Uygulama imzalama" açıkken asıl imza anahtarını Google tutar; bu yalnız YÜKLEME
#  anahtarıdır. Kaybolursa Play Console'dan sıfırlama istenir (birkaç gün sürer) —
#  yine de C:\TETIKTE-YEDEK\mobil\ klasörünü ayrıca yedekle (USB / şifre yöneticisi).
#
#  Var olan anahtarın ÜSTÜNE YAZMAZ: klasörde .jks varsa durur (-SirlariYenidenYaz ile
#  yalnız GitHub sırları mevcut dosyadan yeniden yazılır).
#
#  Çalıştırma:  powershell -NoProfile -File mobil/anahtar-kur.ps1
# ============================================================================
param([switch]$SirlariYenidenYaz)
$ErrorActionPreference = 'Stop'

# Yerel araç çağrısı: PS 5.1'de EAP=Stop altında yerel aracın stderr'i yönlendirilince betik ölür
# (CLAUDE.md K6 dersi). Çağrı süresince EAP Continue; çıkış kodu $LASTEXITCODE'dan okunur.
function YerelCalistir([scriptblock]$isBlogu) {
  $eskiTercih = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & $isBlogu } finally { $ErrorActionPreference = $eskiTercih }
}

$depoAdi     = 'cemdizdar85-arch/mevzuat-radar'
$klasorYolu  = 'C:\TETIKTE-YEDEK\mobil'
$jksYolu     = Join-Path $klasorYolu 'tetikte-yukleme.jks'
$sifreYolu   = Join-Path $klasorYolu 'anahtar-sifre.txt'
$ghYolu      = 'C:\Program Files\GitHub CLI\gh.exe'

function AracBul([string]$adi, [string[]]$adaylar) {
  foreach ($aday in $adaylar) { $bulunan = @(Get-ChildItem -Path $aday -ErrorAction SilentlyContinue); if ($bulunan.Count -gt 0) { return $bulunan[0].FullName } }
  $komut = Get-Command $adi -ErrorAction SilentlyContinue
  if ($komut) { return $komut.Source }
  throw "$adi bulunamadı. Java (keytool) kurulu olmalı."
}

if (-not (Test-Path $ghYolu)) { $ghYolu = 'gh' }
YerelCalistir { & $ghYolu auth status *> $null }
if ($LASTEXITCODE -ne 0) { throw "GitHub girişi yok. Önce: gh auth login" }

New-Item -ItemType Directory -Force -Path $klasorYolu | Out-Null

if (Test-Path $jksYolu) {
  if (-not $SirlariYenidenYaz) {
    Write-Host "DUR: $jksYolu zaten var. Üstüne yazılmadı."
    Write-Host "     Yalnız GitHub sırlarını yeniden yazmak için: powershell -NoProfile -File mobil/anahtar-kur.ps1 -SirlariYenidenYaz"
    exit 1
  }
  if (-not (Test-Path $sifreYolu)) { throw "$sifreYolu yok; mevcut anahtarın şifresi olmadan sır yazılamaz." }
  $gizliSifre = (Get-Content -Path $sifreYolu -Raw).Trim()
} else {
  $keytoolYolu = AracBul 'keytool' @('C:\Program Files\Java\*\bin\keytool.exe', 'C:\Program Files\Eclipse Adoptium\*\bin\keytool.exe', 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe')
  $harfler = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
  $rastgele = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rastgele)
  $gizliSifre = -join ($rastgele | ForEach-Object { $harfler[$_ % $harfler.Length] })

  YerelCalistir { & $keytoolYolu -genkeypair -storetype PKCS12 -keystore $jksYolu -alias tetikte -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $gizliSifre -keypass $gizliSifre `
    -dname 'CN=Tetikte, O=Dizdar Denetim Danismanlik ve Yazilim A.S., L=Izmir, C=TR' *> $null }
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jksYolu)) { throw "keytool anahtarı üretemedi (çıkış $LASTEXITCODE)." }
  Set-Content -Path $sifreYolu -Value $gizliSifre -NoNewline -Encoding ASCII
  Write-Host "Anahtar üretildi: $jksYolu"
  Write-Host "Şifre dosyası:   $sifreYolu  (ekrana basılmadı)"
}

$anahtarB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($jksYolu))
YerelCalistir { & $ghYolu secret set MOBIL_ANDROID_ANAHTAR_B64 --repo $depoAdi --body $anahtarB64 *> $null }
if ($LASTEXITCODE -ne 0) { throw "MOBIL_ANDROID_ANAHTAR_B64 yazılamadı." }
YerelCalistir { & $ghYolu secret set MOBIL_ANDROID_ANAHTAR_SIFRE --repo $depoAdi --body $gizliSifre *> $null }
if ($LASTEXITCODE -ne 0) { throw "MOBIL_ANDROID_ANAHTAR_SIFRE yazılamadı." }

$liste = (YerelCalistir { & $ghYolu secret list --repo $depoAdi }) -join "`n"
$ikisiVar = ($liste -match 'MOBIL_ANDROID_ANAHTAR_B64') -and ($liste -match 'MOBIL_ANDROID_ANAHTAR_SIFRE')
if (-not $ikisiVar) { throw "Sırlar listede görünmüyor; gh secret list çıktısına bak." }
Write-Host "TAMAM: iki sır GitHub'da (MOBIL_ANDROID_ANAHTAR_B64, MOBIL_ANDROID_ANAHTAR_SIFRE)."
Write-Host "Sıradaki: gh workflow run mobil-android.yml  (mobil/OKU.md adım 2)"
