# ============================================================================
#  YEREL INDIRICI (05.08.2026) — Cem'in makinesinde gunde bir kosar. 0 USD.
#
#  NEDEN VAR: mevzuat.gov.tr GitHub runner IP'lerini ENGELLIYOR (05.08 kaniti:
#  runner'dan 6/6 indirme basarisiz, ayni URL'ler Cem'in makinesinden 6/6
#  HTTP 200). Gunluk ayna bu yuzden olum sarmalindaydi: indirmeler timeout'a
#  takila takila 6 saat tavaninda oluyor, _durum hic commit'lenmiyordu.
#
#  COZUM MIMARISI: indirme isi TR-IP'li bu makineye tasindi. Bu betik:
#   1) repo'yu gunceller (pull --rebase)
#   2) manifest'i okur; su kaynaklari indirir:
#      - seyrek OLMAYANLAR (kanunlar + temel yonetmelikler): her gun taze
#      - seyrek olup _durum'da OLMAYANLAR (hic yutulmamis birikim): kosu
#        basina 60 tavanla, birikim gunler icinde erir
#   3) pdftotext ile metne doker, HASH degismediyse dosyaya DOKUNMAZ
#      (bos commit/sisme olmaz)
#   4) degisenleri veri/mevzuat-hazir/'a yazar, commit+push eder
#   5) nabiz dosyasi yazar (kor kalma: robot calisti mi, kac dosya?)
#  Push, mevzuat.yml'yi tetikler (hazir yolu izleniyor); ayna hazir metni
#  indirme YAPMADAN kullanir -> kosu dakikalara iner, sarmal kirilir.
#
#  ZAMANLANMIS GOREV (kurulum bir kez):
#    schtasks /Create /TN "MevzuatRadar-YerelIndirici" /SC DAILY /ST 09:30 ...
#  Elle kosturmak: powershell -File motor\yerel-indirici.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $kok
$logYol = Join-Path $kok '_yerel-indirici-log.txt'   # yerel log (repoya girmez, .gitignore'a eklendi)
function Log([string]$m){ $s = "{0} {1}" -f (Get-Date -Format 'HH:mm:ss'), $m; Write-Host $s; Add-Content -LiteralPath $logYol -Value $s -Encoding UTF8 }
Set-Content -LiteralPath $logYol -Value ("YEREL INDIRICI {0}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm')) -Encoding UTF8

$SEYREK_TAVAN = 60
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$hazirDir = Join-Path $kok 'veri/mevzuat-hazir'
if(-not (Test-Path $hazirDir)){ New-Item -ItemType Directory -Path $hazirDir | Out-Null }
$tmp = Join-Path $env:TEMP 'mevzuat-yerel-indirici'
if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp | Out-Null }

# pdftotext var mi (poppler winget'te kurulu olmali)
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
if($null -eq $pdftotext){ Log "HATA: pdftotext bulunamadi (poppler kurulu degil?)"; exit 1 }

try { git pull --rebase origin main 2>&1 | Out-Null; Log "git pull tamam" } catch { Log "git pull UYARI: $_" }

$manifest = Get-Content (Join-Path $kok 'veri/mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = @{}
try {
  $dj = Get-Content (Join-Path $kok 'veri/mevzuat/_durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $dj.PSObject.Properties){ $durum[$p.Name] = $true }
} catch {}

function UrlKur($law){
  $pid2 = "$($law.pdfId)"
  if($pid2 -like 'G7:*'){ return "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pid2.Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
  if($pid2 -like 'G9:*'){ return "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pid2.Substring(3))&mevzuatTur=Teblig&mevzuatTertip=5" }
  return "https://www.mevzuat.gov.tr/MevzuatMetin/$pid2.pdf"
}
function Sha([string]$s){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16) }

$indirilen=0; $degisen=0; $ayni=0; $hata=0; $seyrekYeni=0; $atlanan=0
foreach($law in $manifest.kanunlar){
  $slug = "$($law.slug)"
  $seyrek = $false; try { $seyrek = ($law.PSObject.Properties['seyrek'] -and $law.seyrek -eq $true) } catch {}
  if($seyrek){
    if($durum.ContainsKey($slug) -and (Get-Date).DayOfWeek -ne 'Sunday'){ $atlanan++; continue }  # yutulmus seyrek: yalniz pazar tazelenir
    $seyrekYeni++
    if($seyrekYeni -gt $SEYREK_TAVAN){ $atlanan++; continue }                                      # birikim gunlere yayilir
  }
  $pdf = Join-Path $tmp "$slug.pdf"; $txt = Join-Path $tmp "$slug.txt"
  try {
    Invoke-WebRequest -Uri (UrlKur $law) -OutFile $pdf -UserAgent $UA -Headers @{ Referer='https://www.mevzuat.gov.tr/' } -TimeoutSec 90 -UseBasicParsing
    & pdftotext -enc UTF-8 $pdf $txt 2>$null
    if(-not (Test-Path $txt) -or (Get-Item $txt).Length -lt 2000){ $hata++; Log "KISA/BOS: $slug"; continue }
    $indirilen++
    $yeni = Get-Content $txt -Raw -Encoding UTF8
    $hedef = Join-Path $hazirDir "$slug.txt"
    $eskiH = if(Test-Path $hedef){ Sha ((Get-Content $hedef -Raw -Encoding UTF8) -replace '\s+',' ') } else { '' }
    $yeniH = Sha ($yeni -replace '\s+',' ')
    if($yeniH -ne $eskiH){ Set-Content -LiteralPath $hedef -Value $yeni -Encoding UTF8 -NoNewline; $degisen++; Log "DEGISTI: $slug" }
    else { $ayni++ }
  } catch { $hata++; Log "INDIRME HATASI: $slug ($($_.Exception.Message))" }
  Start-Sleep -Milliseconds 1200   # site yagmuru sevmez - kibar aralik
}
Log ("OZET: indirilen={0} degisen={1} ayni={2} hata={3} atlanan={4}" -f $indirilen,$degisen,$ayni,$hata,$atlanan)

# NABIZ (kor kalma): robot bugun calisti mi, sonucu neydi - repoya yazilir
$nabiz = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); makine=$env:COMPUTERNAME
  indirilen=$indirilen; degisen=$degisen; ayni=$ayni; hata=$hata; atlanan=$atlanan
  not='Yerel indirici (Cem makinesi, TR IP). mevzuat.gov.tr GitHub runnerlarini engelledigi icin indirme buradan beslenir.' }
Set-Content -LiteralPath (Join-Path $kok 'veri/yerel-indirici-nabiz.json') -Value (ConvertTo-Json $nabiz -Depth 3) -Encoding UTF8 -NoNewline

git add veri/mevzuat-hazir veri/yerel-indirici-nabiz.json 2>&1 | Out-Null
$degisiklikVar = $true
git diff --cached --quiet 2>$null; if($LASTEXITCODE -eq 0){ $degisiklikVar = $false }
if($degisiklikVar){
  git commit -m "Yerel indirici: $degisen kaynak guncellendi [veri-operasyonu]" 2>&1 | Out-Null
  $pushOk = $false
  foreach($i in 1..3){
    git pull --rebase origin main 2>&1 | Out-Null
    git push origin HEAD:main 2>&1 | Out-Null
    if($LASTEXITCODE -eq 0){ $pushOk = $true; break }
    Start-Sleep -Seconds 7
  }
  if($pushOk){ Log "PUSH tamam ($degisen degisiklik) - ayna tetiklenecek" } else { Log "!! PUSH TUTMADI" ; exit 1 }
} else { Log "degisiklik yok - push edilmedi" }
