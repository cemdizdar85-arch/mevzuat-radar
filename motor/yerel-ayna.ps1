# ============================================================================
#  YEREL AYNA — 07.08.2026 (Cem: "eksik resmi veri istemiyorum, hemen yapalim")
#
#  NEDEN: mevzuat.gov.tr, GitHub kosucu IP'lerini engelliyor (03.08'den beri
#  gunluk kanun aynasi TAM kosamiyor - "AYNA SARMALI"). Bu makine TURKIYE
#  IP'sinde: indirme buradan yapilir, yutucu ayni makinede kosar, sonuc
#  git'e basilir. Windows Gorev Zamanlayici bu scripti HER GUN kosturur.
#
#  BOT KORUMASI DERSI (07.08 gece): oturum cerezsiz ardisik GeneratePdf
#  istekleri 200 + HTML bot-sayfasi donduruyor (ilk tekil istek PDF verir!).
#  Cozum: once ana sayfadan cerez alinir (-WebSession), indirme o oturumla
#  yapilir; %PDF imzasi dogrulanir; HTML gelirse oturum tazelenip BIR kez
#  daha denenir. Devre kesici yalniz AG hatalarinda (HTML veri-sorunu sayilir).
#
#  ENV: SUPABASE_SERVICE_KEY (User-env'den okunur). Kor kalma: her kosu
#  veri/yerel-ayna-raporu.json + git commit (bakan herkes gorur).
# ============================================================================
$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kok = 'C:\Users\cemdi\OneDrive\Masaüstü\mevzuat işi\mevzuat-radar'
Set-Location -LiteralPath $kok
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$pdftotext = 'C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe'
$raporYol = Join-Path $kok 'veri\yerel-ayna-raporu.json'
New-Item -ItemType Directory -Force (Join-Path $kok '_txt') | Out-Null
$kokTxt = (Resolve-Path '_txt').Path

function OturumAc {
  $s = $null
  try { Invoke-WebRequest -Uri 'https://www.mevzuat.gov.tr/' -UserAgent $UA -TimeoutSec 45 -UseBasicParsing -SessionVariable s | Out-Null } catch {}
  return $s
}
function PdfMi([string]$yol){
  if(-not (Test-Path $yol)){ return $false }
  try { $b = [IO.File]::ReadAllBytes($yol); if($b.Length -lt 400){ return $false }; return ([Text.Encoding]::ASCII.GetString($b[0..4]) -like '%PDF*') } catch { return $false }
}

$man = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oturum = OturumAc
$ok=0; $hazir=0; $htmlRed=0; $agHata=0; $ardisikAg=0; $kesik=$false; $say=0; $onceden=0
foreach($law in $man.kanunlar){
  $say++
  $slug = $law.slug; $lpid = "$($law.pdfId)"
  $txtYol = Join-Path $kokTxt "$slug.txt"
  if(Test-Path (Join-Path $kok "veri\mevzuat-hazir\$slug.txt")){ Copy-Item (Join-Path $kok "veri\mevzuat-hazir\$slug.txt") $txtYol -Force; $hazir++; continue }
  if(Test-Path $txtYol){ $onceden++; continue }   # bu gunun onceki denemesinden saglam metin
  if($kesik){ continue }
  $url = if($lpid -like 'G7:*'){ 'https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=' + $lpid.Substring(3) + '&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5' }
         elseif($lpid -like 'G9:*'){ 'https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=' + $lpid.Substring(3) + '&mevzuatTur=Teblig&mevzuatTertip=5' }
         else { "https://www.mevzuat.gov.tr/MevzuatMetin/$lpid.pdf" }
  $pdfYol = Join-Path $kokTxt "$slug.pdf"
  $indi = $false
  for($dn=1; $dn -le 2; $dn++){
    try {
      Invoke-WebRequest -Uri $url -OutFile $pdfYol -UserAgent $UA -Headers @{ Referer='https://www.mevzuat.gov.tr/' } -WebSession $oturum -TimeoutSec 60 -UseBasicParsing
      $ardisikAg = 0
      if(PdfMi $pdfYol){ $indi = $true; break }
      # HTML bot-sayfasi: oturumu tazele, bekle, bir kez daha
      if($dn -eq 1){ Start-Sleep -Seconds 9; $oturum = OturumAc }
    } catch {
      $agHata++; $ardisikAg++
      if($ardisikAg -ge 6){ $kesik = $true }
      break
    }
  }
  if($indi){
    $p = Start-Process -FilePath $pdftotext -ArgumentList @('-enc','UTF-8', ('"'+$pdfYol+'"'), ('"'+$txtYol+'"')) -NoNewWindow -Wait -PassThru
    if((Test-Path $txtYol) -and (Get-Item $txtYol).Length -gt 200){ $ok++ } else { $htmlRed++ }
  } else { $htmlRed++ }
  Start-Sleep -Seconds (3 + (Get-Random -Maximum 3))
  if(($say % 80) -eq 0){ Write-Host ("  {0}/{1} ok:{2} hazir:{3} htmlRed:{4} agHata:{5}" -f $say, @($man.kanunlar).Count, $ok, $hazir, $htmlRed, $agHata) }
}
Write-Host ("INDIRME: ok={0} hazir={1} onceden={2} htmlRed={3} agHata={4} kesik={5}" -f $ok,$hazir,$onceden,$htmlRed,$agHata,$kesik)

Write-Host '=== YUTUCU ==='
& (Join-Path $kok 'motor\mevzuat-yut.ps1')
$yutKod = $LASTEXITCODE

[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); makine='yerel (TR-IP)'
  indirilen=$ok; hazir=$hazir; onceden=$onceden; htmlRed=$htmlRed; agHata=$agHata; devreKesik=$kesik
  yutucuCikis=$yutKod
})), (New-Object Text.UTF8Encoding($false)))

# --- sonucu bas (ayna ciktilarindaki degisiklikler + rapor)
git add veri/yerel-ayna-raporu.json veri/mevzuat veri/mevzuat-rapor*.json 2>$null
git diff --cached --quiet
if($LASTEXITCODE -ne 0){
  git commit -m 'Yerel ayna kosusu (TR-IP) [veri-operasyonu]' | Out-Null
  git pull --rebase origin main 2>$null | Out-Null
  git push origin HEAD:main 2>$null | Out-Null
  Write-Host 'commit + push tamam'
} else { Write-Host 'degisiklik yok - commit atlanildi' }
Write-Host 'YEREL AYNA TAMAM'
