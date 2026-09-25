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
#
#  25.09.2026 - TEK SAHIP (Cem "1 ve 2 yap"): veri/mevzuat/ (yutma durumu) IKI robot tarafindan yaziliyordu -
#  bu betik + bulut 'Gunluk Kanun Aynasi' (mevzuat.yml, gunde 2). 25.09 07:00'de cakistilar, depo kilitlendi.
#  Olcum 12-25.09: bu betik 13 kosunun 13'unde 0 metin INDIRDI; hepsi veri/mevzuat-hazir'den (yerel-indirici,
#  TR-IP, 09:30) geliyordu = bulutun da okudugu ayni girdi. Yani yutma burada IKINCI KEZ yapiliyordu.
#  SAHIPLIK:  veri/mevzuat/**            -> YALNIZ bulut Kanun Aynasi
#             veri/mevzuat-hazir/**      -> YALNIZ motor/yerel-indirici.ps1 (TR-IP indirme, gecici worktree'den push)
#             veri/mevzuat-kaynaklar.json + teblig-hasat-raporu -> BU BETIK (teblig hasadi; mevzuat.gov.tr GitHub'i
#             engelledigi icin bulut yapamaz). Onceden bu iki dosya HIC commit'lenmiyordu - yeni teblig makinede kaliyordu.
#  Yeni teblig zinciri: 06:30 hasat -> manifest push -> 09:30 yerel-indirici G9'u indirir -> hazir push -> bulut yutar.
#  Soru-dayanak nobeti bulutta (soru-dayanak.yml). Eski davranis (indir + yut + dayanak + veri/mevzuat commit): -EskiYol
# ============================================================================
param([switch]$EskiYol)
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

# 07.08: TEBLIG HASAT once kosar - fihriste dusen yeni teblig manifeste
# girer ve AYNI kosuda indirilip yutulur (asgari ucret karari dahil).
Write-Host '=== TEBLIG HASAT ==='
try { & (Join-Path $kok 'motor\teblig-hasat.ps1') } catch { Write-Host ('hasat atlandi: ' + $_.Exception.Message) }

$ok=0; $hazir=0; $htmlRed=0; $agHata=0; $kesik=$false; $onceden=0; $yutKod='bulutta (mevzuat.yml)'
if($EskiYol){   # 25.09: indir + yut + dayanak yalniz -EskiYol ile (tek sahip notu dosya basinda)
$man = Get-Content (Join-Path $kok 'veri\mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oturum = OturumAc
$ok=0; $hazir=0; $htmlRed=0; $agHata=0; $ardisikAg=0; $kesik=$false; $say=0; $onceden=0
foreach($law in $man.kanunlar){
  $say++
  $slug = $law.slug; $lpid = "$($law.pdfId)"
  $txtYol = Join-Path $kokTxt "$slug.txt"
  if(Test-Path (Join-Path $kok "veri\mevzuat-hazir\$slug.txt")){ Copy-Item (Join-Path $kok "veri\mevzuat-hazir\$slug.txt") $txtYol -Force; $hazir++; continue }
  if(Test-Path $txtYol){ $onceden++; continue }   # bu gunun onceki denemesinden saglam metin
  # 07.08 aksam: taranmis-goruntu kaynaklar (GeneratePdf govdesi resim) her gun
  # bosuna indirilmesin - gozle aktarim yapilinca mevzuat-hazir'a girecekler.
  if($law.taranmis){ continue }
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

# 07.08: SORU-DAYANAK NOBETCISI - yutma sonrasi damgasi degisen maddeye
# dayanan sorular otomatik cekilir (Cem'e verilen sozun zinciri).
Write-Host '=== SORU-DAYANAK NOBETCISI ==='
& (Join-Path $kok 'motor\soru-dayanak-nobetcisi.ps1')
} else { Write-Host 'INDIRME/YUTMA/DAYANAK: bulutta (tek sahip, 25.09) - burada yalniz teblig hasadi' }

[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); makine='yerel (TR-IP)'
  rol=$(if($EskiYol){ 'eski yol: indir + yut + dayanak' } else { 'teblig hasadi (veri/mevzuat sahibi: bulut Kanun Aynasi)' })
  indirilen=$ok; hazir=$hazir; onceden=$onceden; htmlRed=$htmlRed; agHata=$agHata; devreKesik=$kesik
  yutucuCikis=$yutKod
})), (New-Object Text.UTF8Encoding($false)))

# --- sonucu bas (ayna ciktilarindaki degisiklikler + rapor)
# 07.08 ilk kosu dersi: eslesmeyen joker (mevzuat-rapor*.json) git add'i sessizce
# bosa dusurdu, commit atlandi. Klasor -A ile, rapor tek tek eklenir.
# 30.08.2026 - iki onarim (yerel-indirici ile ayni kusurlar):
#  (1) commit YOLSUZDU -> indekste bekleyen baskasinin dosyalarini da yayina
#      iterdi. Artik yol belirtilerek commit edilir.
#  (2) pull --autostash'siz -> kirli agacta duserdi ("cannot pull with rebase:
#      You have unstaged changes"). Robotlar veri dosyasi yazdigi icin agac
#      neredeyse HER ZAMAN kirlidir; bu, aynayi kilitleyen dugumdu.
if($EskiYol){
  $AYNA_YOLLAR = @('veri/mevzuat','veri/yerel-ayna-raporu.json','veri/soru-dayanak-raporu.json')
  git add -A -- veri/mevzuat
  git add -- veri/soru-dayanak-raporu.json 2>$null
} else {
  # 25.09 tek sahip: veri/mevzuat'a DOKUNULMAZ; teblig hasadinin ciktisi (once hic commit'lenmiyordu) + kendi rapor
  $AYNA_YOLLAR = @('veri/mevzuat-kaynaklar.json','veri/teblig-hasat-raporu.json','veri/yerel-ayna-raporu.json')
  git add -- veri/mevzuat-kaynaklar.json 2>$null
  git add -- veri/teblig-hasat-raporu.json 2>$null
}
git add -- veri/yerel-ayna-raporu.json
git diff --cached --quiet -- $AYNA_YOLLAR
if($LASTEXITCODE -ne 0){
  git commit -m 'Yerel ayna kosusu (TR-IP) [veri-operasyonu]' -- $AYNA_YOLLAR | Out-Null
  # 25.09.2026 DERSI: pull/push hatalari 2>$null ile YUTULUYORDU. 07:00 kosusunda rebase veri/mevzuat'ta cakisti,
  # YARIDA KALDI (.git/rebase-merge), push dustu - betik yine "commit + push tamam" yazdi, gorev 0 (basarili) bitti.
  # Yarim rebase butun oturumlarin kol acmasini kilitledi. Artik: cakisma -> rebase GERI ALINIR (depo yarim kalmaz),
  # KIRMIZI yazilir, gorev 1 ile biter (Gorev Zamanlayicisi'nda gorunur). Hangi surumun kazanacagina KARAR VERMEZ.
  $cek = git pull --rebase --autostash origin main 2>&1
  if($LASTEXITCODE -ne 0){
    git rebase --abort 2>&1 | Out-Null
    Write-Host ('KIRMIZI: ana tel cekilemedi (cakisma) - rebase GERI ALINDI, ayna commitin yerelde bekliyor. ' + (@($cek | ForEach-Object { "$_" } | Where-Object { $_ -match 'CONFLICT|error' } | Select-Object -First 3) -join ' / ')) -ForegroundColor Red
    $script:aynaHata = $true
  } else {
    git push origin HEAD:main 2>&1 | Out-Null
    if($LASTEXITCODE -ne 0){ Write-Host 'KIRMIZI: push reddedildi - commit yerelde bekliyor' -ForegroundColor Red; $script:aynaHata = $true }
    else { Write-Host 'commit + push tamam' }
  }
} else { Write-Host 'degisiklik yok - commit atlanildi' }
if($script:aynaHata){ Write-Host 'YEREL AYNA: VERI YAYINLANAMADI'; exit 1 }
Write-Host 'YEREL AYNA TAMAM'
