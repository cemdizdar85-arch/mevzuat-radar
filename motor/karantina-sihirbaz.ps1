# ============================================================================
#  KARANTINA SIHIRBAZI - Cem icin tek-tik akis (03.08.2026)
#  Cift tiklanan KARANTINA-TASI-TIKLA.bat bunu acar. Anahtar sorar, dogrular,
#  once olcum kosar, onay alir, sonra gercek tasimayi (-yaz) kosar.
#  Anahtar hicbir dosyaya YAZILMAZ - yalniz bu pencerenin belleginde durur.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

Write-Host ""
Write-Host "=============================================="
Write-Host "  KARANTINA TASIMA SIHIRBAZI"
Write-Host "  575 odenmis soru kasaya tasinacak (yayin kapali)"
Write-Host "=============================================="
Write-Host ""
Write-Host "Anahtar su sayfada: (Ctrl ile tiklanabilir ya da tarayiciya yapistir)"
Write-Host "  https://supabase.com/dashboard/project/bjrleanjpyujtajmazxn/settings/api-keys"
Write-Host "Oradaki 'Secret keys' bolumunden sb_secret_ ile baslayan anahtari KOPYALA."
Write-Host ""

# --- anahtar deneme fonksiyonu: kabulse anahtari, degilse $null dondurur ---
function Dene-Anahtar([string]$aday){
  $aday = "$aday".Trim().Trim('"').Trim("'")
  if(-not $aday -or $aday -like '*BURAYA*'){ return $null }
  $maske = if($aday.Length -gt 12){ $aday.Substring(0,12) + "..." } else { $aday }
  Write-Host ("Deneniyor: {0} (uzunluk {1})" -f $maske, $aday.Length)
  # sb_secret icin yalniz apikey; eski JWT (eyJ...) icin Bearer da eklenir
  $H = @{ apikey = $aday }
  if($aday -like 'eyJ*'){ $H.Authorization = "Bearer $aday" }
  try {
    $test = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&limit=1" -Headers $H -TimeoutSec 30
    if(@($test).Count -ge 1){ return $aday }
    Write-Host "Bu anahtar kasayi GOREMIYOR - herkese-acik (publishable) anahtar olabilir. sb_secret_ olan lazim."
  } catch {
    $kod = ""; $govde = ""
    if($_.Exception.Response -and $_.Exception.Response.StatusCode){ $kod = " HTTP $([int]$_.Exception.Response.StatusCode)" }
    if($_.ErrorDetails -and $_.ErrorDetails.Message){ $govde = " | sunucu: $($_.ErrorDetails.Message)" }
    Write-Host "Anahtar kabul edilmedi.$kod$govde"
  }
  return $null
}

# --- 1. yol: Not Defteri dosyasi (veri\fabrika\ANAHTAR.txt - gitignore'da, depoya gidemez) ---
$KEY = $null
$anahtarDosya = Join-Path (Split-Path $here -Parent) "veri\fabrika\ANAHTAR.txt"
if(Test-Path $anahtarDosya){
  Write-Host "ANAHTAR.txt bulundu, oradan okunuyor..."
  $KEY = Dene-Anahtar (Get-Content -Raw $anahtarDosya)
  if(-not $KEY){ Write-Host "Dosyadaki anahtar kabul edilmedi - elle yapistirma yoluna geciliyor."; Write-Host "" }
}

# --- 2. yol: elle yapistirma (3 deneme) ---
if(-not $KEY){
  for($deneme = 1; $deneme -le 3; $deneme++){
    $girilen = Read-Host "Anahtari buraya YAPISTIR (sag tik = yapistir) ve Enter'a bas"
    $KEY = Dene-Anahtar $girilen
    if($KEY){ break }
  }
}
if(-not $KEY){
  Write-Host ""
  Write-Host "Olmadi. Yukaridaki 'Anahtar kabul edilmedi' satirini oldugu gibi GM'ye (sohbete) YAZ - kod ve"
  Write-Host "sunucu mesajiyla kesin teshis konulacak. (Ekran goruntusu ATMA - anahtar gorunuyor olabilir.)"
  Read-Host "Kapatmak icin Enter"
  exit 1
}
# anahtar kabul edildi - diskte iz birakma
if(Test-Path $anahtarDosya){ Remove-Item $anahtarDosya -Force }
Write-Host "Anahtar dogrulandi (kasa gorunuyor)."
$env:SUPABASE_SERVICE_KEY = $KEY

# --- 1) olcum (hicbir sey yazmaz) ---
Write-Host ""
Write-Host "--- ADIM 1/2: OLCUM (hicbir sey yazilmaz, sadece sayilir) ---"
& (Join-Path $here "karantina-tasi.ps1")
if($LASTEXITCODE -ne 0){
  Write-Host ""
  Write-Host "Olcum hata verdi. Yukaridaki HATA satirini GM'ye (sohbete) aynen yaz."
  Read-Host "Kapatmak icin Enter"
  exit 1
}

# --- 2) onay + gercek tasima ---
Write-Host ""
$cevap = Read-Host "Yukaridaki sayilar tamam mi? Gercek tasimayi baslatmak icin E yaz, vazgecmek icin H"
if("$cevap".Trim().ToUpper() -ne "E"){
  Write-Host "Vazgecildi - hicbir sey yazilmadi. Pencereyi kapatabilirsin."
  Read-Host "Kapatmak icin Enter"
  exit 0
}
Write-Host ""
Write-Host "--- ADIM 2/2: GERCEK TASIMA (birkac dakika surebilir) ---"
& (Join-Path $here "karantina-tasi.ps1") -yaz
$son = $LASTEXITCODE

Write-Host ""
if($son -eq 0){
  Write-Host "=============================================="
  Write-Host "  BITTI. Rapor: veri\karantina-tasima.json"
  Write-Host "  Sohbete 'tasima bitti' yazman yeterli - GM dogrulayacak."
  Write-Host "=============================================="
} else {
  Write-Host "Tasima hata verdi. Yukaridaki HATA satirini GM'ye (sohbete) aynen yaz."
}
Read-Host "Kapatmak icin Enter"
exit $son
