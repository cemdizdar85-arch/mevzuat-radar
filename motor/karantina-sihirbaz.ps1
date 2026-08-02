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
Write-Host "  https://supabase.com/dashboard/project/bjrleanjpyujtajmazxn/settings/api"
Write-Host "Oradaki 'service_role' (secret) anahtarini KOPYALA."
Write-Host ""

# --- anahtari al ve dogrula (3 deneme) ---
$KEY = $null
for($deneme = 1; $deneme -le 3; $deneme++){
  $girilen = Read-Host "Anahtari buraya YAPISTIR (sag tik = yapistir) ve Enter'a bas"
  $girilen = "$girilen".Trim().Trim('"').Trim("'")
  if(-not $girilen){ Write-Host "Bos girdin, tekrar dene."; continue }
  $H = @{ apikey = $girilen; Authorization = "Bearer $girilen" }
  try {
    $test = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&limit=1" -Headers $H -TimeoutSec 30
    if(@($test).Count -ge 1){ $KEY = $girilen; break }
    Write-Host "Bu anahtar kasayi GOREMIYOR - buyuk ihtimalle 'anon/publishable' kopyaladin."
    Write-Host "Gizli olani lazim: 'service_role' yazan satir (Reveal -> Copy). Tekrar dene."
  } catch {
    Write-Host "Anahtar kabul edilmedi (sunucu reddetti). Eksik/yanlis kopyalanmis olabilir, tekrar dene."
  }
}
if(-not $KEY){
  Write-Host ""
  Write-Host "3 denemede olmadi. Pencereyi kapat, anahtari yeniden kopyalayip .bat dosyasina tekrar cift tikla."
  Read-Host "Kapatmak icin Enter"
  exit 1
}
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
