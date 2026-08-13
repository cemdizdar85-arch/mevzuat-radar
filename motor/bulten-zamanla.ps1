# ============================================================================
#  BULTEN ZAMANLAMA KURULUMU (bir kez calistirilir)
#  Windows Gorev Zamanlayicisi'na gunluk bir gorev ekler: her sabah 09:00'da
#  Kamu Ihale Bulteni'nden iptal/duzeltme hasadi yapar, degisiklik varsa
#  commit'leyip push'lar.
#
#  YONETICI GEREKMEZ - gorev mevcut kullanici adina kurulur.
#  Kaldirmak icin:  motor/bulten-zamanla.ps1 -Kaldir
#  Durumu gormek icin: schtasks /Query /TN "Tetikte - Kamu Ihale Bulteni" /V /FO LIST
# ============================================================================
param(
  [string]$Saat = "09:00",
  [switch]$Kaldir
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$gorevAd = "Tetikte - Kamu Ihale Bulteni"
$kosucu  = Join-Path $here "bulten-gunluk.ps1"

if($Kaldir){
  schtasks /Delete /TN $gorevAd /F
  Write-Host "Gorev kaldirildi: $gorevAd"
  exit 0
}
if(-not (Test-Path $kosucu)){ Write-Host "DUR: $kosucu bulunamadi."; exit 1 }

# Yol icinde bosluk ve Turkce karakter var (OneDrive\Masaüstü\mevzuat işi) -
# tirnaklama sart, yoksa gorev sessizce kosmaz.
$komut = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$kosucu`""

schtasks /Create /TN $gorevAd /TR $komut /SC DAILY /ST $Saat /F
if($LASTEXITCODE -ne 0){ Write-Host "DUR: gorev kurulamadi."; exit 1 }

Write-Host ""
Write-Host "KURULDU: '$gorevAd' - her gun $Saat"
Write-Host "  Kosu kaydi : veri\bulten-gunluk-son-kosu.txt"
Write-Host "  Elle dene  : schtasks /Run /TN `"$gorevAd`""
Write-Host "  Kaldir     : motor\bulten-zamanla.ps1 -Kaldir"
Write-Host ""
Write-Host "NOT: bilgisayar o saatte kapaliysa gorev kacar. Kacan gorevi acilista"
Write-Host "kosturmak icin Gorev Zamanlayicisi'nda gorevin Ayarlar sekmesinde"
Write-Host "'Zamanlanmis baslangic kacirilirsa gorevi en kisa surede baslat' isaretlenir."
