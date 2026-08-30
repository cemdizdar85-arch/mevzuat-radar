# ============================================================================
#  JSON BÜTÜNLÜK KAPISI — bozuk veri dosyası yayına çıkamaz
#
#  NEDEN VAR (30.08.2026): O gün veri/ihale-kesik-firma-adi.json'a ÇAKIŞMA
#  İŞARETLİ bir sürüm itildi — autostash birleştirmesi çözülmeden
#  commit'lenmişti. Dosya şöyle duruyordu ve depoda ÖYLE kaldı:
#      {
#      <<<<<<< Updated upstream
#        "olcum": "30.08.2026 09:54",
#      =======
#        "olcum": "30.08.2026 09:57",
#      >>>>>>> Stashed changes
#  Üzerine iki koşu daha yapıldı ve kimse fark etmedi. Fark edilince de
#  ancak dosyayı okumaya çalışırken anlaşıldı ("Geçersiz nesne geçirildi").
#  Bu dosyaları site okuyor; bozuk JSON = sayfa sessizce boş.
#
#  İKİ KATMANLI ÖLÇÜM (202 MB / 1.515 dosya, tam parse dakikalar sürer):
#   1) HIZLI - HER dosyada: çakışma işareti (<<<<<<< / ======= / >>>>>>>)
#      satır başında mı + dosya { [ ile başlayıp } ] ile bitiyor mu.
#      Kesik yazma ve çakışma bunlarla yakalanır.
#   2) TAM PARSE - eşik altındaki dosyalarda ConvertFrom-Json.
#      Büyükler atlanır ama ATLANDIĞI YAZILIR - "ölçülmedi" ile "temiz"
#      birbirine karışmasın (kör kalma kuralı).
#
#  Kullanım: powershell -NoProfile -File arac/json-butunluk-kapisi.ps1
#            ... -ParseTavanMB 5     (varsayılan 2)
# ============================================================================
param([double]$ParseTavanMB = 2, [switch]$Ayrinti)

$ErrorActionPreference = 'Continue'
$KOK = Split-Path $PSScriptRoot -Parent

# --- ÖZ-SINAV (93 kapı kuralı) --------------------------------------------
# Kapının iki ölçütü de sınanır; gevşerse ÖLÇÜM YAPILMAZ.
function CakismaVarMi([string]$metin){
  return [bool]([regex]::IsMatch($metin, '(?m)^(<<<<<<< |=======$|>>>>>>> )'))
}
function YapiBozukMu([string]$metin){
  $t = $metin.Trim()
  if($t.Length -eq 0){ return $true }
  $ilk = $t[0]; $son = $t[$t.Length-1]
  if($ilk -eq '{' -and $son -eq '}'){ return $false }
  if($ilk -eq '[' -and $son -eq ']'){ return $false }
  return $true
}
$SINAV = @(
  @{ ad='saglam nesne';      m='{ "a": 1 }';                                   c=$false; y=$false },
  @{ ad='saglam dizi';       m='[1,2,3]';                                      c=$false; y=$false },
  @{ ad='cakisma isaretli';  m="{`n<<<<<<< Updated upstream`n  `"a`":1,`n=======`n  `"a`":2,`n>>>>>>> Stashed changes`n}"; c=$true;  y=$false },
  @{ ad='kesik yazma';       m='{ "a": 1';                                     c=$false; y=$true  },
  @{ ad='bos dosya';         m='';                                             c=$false; y=$true  },
  # "=======" metin ICINDE gecerse kusur DEGILDIR - yalniz satir basinda sayilir
  @{ ad='metin icinde esittir'; m='{ "not": "a ======= b" }';                  c=$false; y=$false }
)
$kotu = @($SINAV | Where-Object { (CakismaVarMi $_.m) -ne $_.c -or (YapiBozukMu $_.m) -ne $_.y })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - kapi bozuk, olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  vaka: {0}" -f $_.ad) -ForegroundColor Red }
  exit 2
}

# --- ölçüm ----------------------------------------------------------------
$dosyalar = @(Get-ChildItem (Join-Path $KOK 'veri') -Filter *.json -Recurse -File)
$tavanBayt = $ParseTavanMB * 1MB
$cakisan = @(); $yapiBozuk = @(); $parseBozuk = @(); $atlanan = 0; $parsedi = 0

foreach($f in $dosyalar){
  $metin = $null
  try { $metin = [System.IO.File]::ReadAllText($f.FullName) } catch { $yapiBozuk += "$($f.Name) (okunamadi)"; continue }
  $yol = $f.FullName.Replace($KOK + [IO.Path]::DirectorySeparatorChar, '')

  if(CakismaVarMi $metin){ $cakisan += $yol; continue }   # en agir kusur, tek basina yeter
  if(YapiBozukMu $metin){ $yapiBozuk += $yol; continue }

  if($f.Length -le $tavanBayt){
    try { $null = $metin | ConvertFrom-Json; $parsedi++ }
    catch {
      $m = "$($_.Exception.Message)"; if($m.Length -gt 70){ $m = $m.Substring(0,70) }
      $parseBozuk += ("{0}  ({1})" -f $yol, $m)
    }
  } else { $atlanan++ }
}

$kusur = $cakisan.Count + $yapiBozuk.Count + $parseBozuk.Count
Write-Host ("JSON BUTUNLUK KAPISI: {0} dosya · {1} tam parse · {2} buyuk dosya PARSE EDILMEDI (>{3} MB)" -f `
  $dosyalar.Count, $parsedi, $atlanan, $ParseTavanMB)
Write-Host ("  (atlananlarda yalniz cakisma ve yapi kontrolu yapildi - 'temiz' degil 'olculmedi')") -ForegroundColor DarkGray

if($kusur -eq 0){
  Write-Host "  Temiz - cakisma isareti yok, yapi saglam, parse edilenler gecerli." -ForegroundColor Green
  exit 0
}
Write-Host ""
if($cakisan.Count){
  Write-Host ("  KIRMIZI - CAKISMA ISARETI ({0} dosya): birlestirme cozulmeden commit'lenmis" -f $cakisan.Count) -ForegroundColor Red
  $cakisan | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}
if($yapiBozuk.Count){
  Write-Host ("  KIRMIZI - YAPI BOZUK ({0} dosya): bos, kesik ya da okunamiyor" -f $yapiBozuk.Count) -ForegroundColor Red
  $yapiBozuk | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}
if($parseBozuk.Count){
  Write-Host ("  KIRMIZI - GECERSIZ JSON ({0} dosya)" -f $parseBozuk.Count) -ForegroundColor Red
  $parseBozuk | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}
Write-Host ""
Write-Host "  Cakisma isareti varsa: dosyayi yeniden uret ya da dogru surumu al." -ForegroundColor Yellow
Write-Host "  Bu dosyalari SITE okuyor - bozuk JSON = sayfa sessizce bos." -ForegroundColor Yellow
exit 1
