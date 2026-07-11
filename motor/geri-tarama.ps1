# ============================================================================
#  GERI TARAMA - gece gorevlisi: gecmis gunlerin RG fihrist + ilgili teblig
#  HTML'lerini indirir (SadeceArsiv modu - siteye dokunmaz, LLM harcamaz).
#  Kullanim: powershell -ExecutionPolicy Bypass -File geri-tarama.ps1 -GunSayisi 365
# ============================================================================
param(
  [int]$GunSayisi = 365,
  [int]$BaslangicOffset = 1   # 1 = dunden geriye
)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $here "cikti\geri-tarama.log"
$tarayici = Join-Path $here "rg-tarayici.ps1"

Add-Content $log ("BASLADI: " + (Get-Date).ToString("dd.MM.yyyy HH:mm") + " | hedef: $GunSayisi gun")
$islenen = 0; $atlanan = 0; $hatalar = 0
for($i = $BaslangicOffset; $i -lt ($BaslangicOffset + $GunSayisi); $i++){
  $t = (Get-Date).AddDays(-$i)
  $tarih = $t.ToString("dd.MM.yyyy")
  $klas = $t.ToString("dd-MM-yyyy")
  $hedefDir = Join-Path $here ("arsiv\" + $klas)
  if(Test-Path $hedefDir){ $atlanan++; continue }   # zaten inmis gun
  try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tarayici -Tarih $tarih -SadeceArsiv *>> $log
    $islenen++
  } catch {
    $hatalar++
    Add-Content $log ("HATA " + $tarih + ": " + $_.Exception.Message)
  }
  Start-Sleep -Seconds 2   # kamu sunucusuna nazik: gunler arasi bekleme
  if(($islenen % 25) -eq 0 -and $islenen -gt 0){
    Add-Content $log ("ILERLEME: $islenen gun islendi, $atlanan atlandi, $hatalar hata - " + (Get-Date).ToString("HH:mm"))
  }
}
Add-Content $log ("BITTI: " + (Get-Date).ToString("dd.MM.yyyy HH:mm") + " | islenen: $islenen | atlanan: $atlanan | hata: $hatalar")