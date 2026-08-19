# ============================================================================
#  TGTC NOBETI (19.08.2026) - GGM'nin resmi TGTC Excel seti degisti mi?
#
#  NEDEN: Karar 11507 (RG 11.07.2026/33307) ~200 GTIP'i yeniden kodladi.
#  Vergi/ulke/IGV verisi rejim zip'inden tazelendi (9b1a48b1) ama ESYA TANIMLARI
#  (veri/gtip-tanim.json) icin makinece okunur resmi kaynak HENUZ YOK:
#    - GGM "2026 TGTC.zip" hala 10781'in orijinal seti (19.08 olculdu)
#    - mevzuat.gov.tr 20.5.11507.pdf ekli cetveli TARANMIS GORUNTU (OCR yasak)
#    - ticaret.gov.tr 13.07 haberinde ek dosya yok; TARA captcha'li
#  Ikincil siteden tanim YUTULMAZ (kaynak kurali). Bu nobet bekleyisi otomatige
#  baglar: GGM seti guncellenince MAIL atar -> tanim-hasat.ps1 YERELDE kosulur
#  (Excel COM ister, ubuntu robotta kosamaz; bu yuzden nobet hasat yapmaz,
#  haber verir).
#
#  KOR KALMA KURALI: duyuru sayfasi/zip linki cozulemezse ya da zip kuculmusse
#  MAIL + exit 1. Sha ayni ise sessiz yesil. Sha DEGISMISSE mail + damga
#  guncellenir (tek mail garanti) + exit 0 (workflow kirmizi olmaz, is FYI).
#
#  Link SABIT YAZILMAZ (CDN id degisir): duyuru listesi -> TGTC duyurusu ->
#  zip zinciri her kosuda yeniden cozulur.
#
#  PARA HARCAMAZ: yalniz ggm.ticaret.gov.tr'den sayfa + zip indirir.
# ============================================================================
param(
  [switch]$MailKapali
)
$ErrorActionPreference = "Continue"
if($PSVersionTable.PSVersion.Major -lt 6){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$LISTE  = 'https://ggm.ticaret.gov.tr/duyurular'
$KOKURL = 'https://ggm.ticaret.gov.tr'
$ENAZ   = 2000000   # bugunku set 2.653.111 bayt; bunun cok altinda zip = bozuk/yanlis dosya
$CURL = if($IsLinux -or $IsMacOS){ 'curl' } else { 'curl.exe' }
$UA   = 'Mozilla/5.0 (compatible; mevzuat-radar-robot/1.0)'

function Mail([string]$konu,[string]$govde){
  if($MailKapali){ Write-Host "  (mail kapali) $konu"; return }
  try {
    $mb = @{ access_key='5b227e56-94fb-4123-a39a-4286f63db14a'; subject=$konu; from_name='Tetikte TGTC Nobeti'; email='cemdizdar85@hotmail.com'; message=$govde } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Uri 'https://api.web3forms.com/submit' -Method Post -ContentType 'application/json' -Body $mb -TimeoutSec 30 | Out-Null
  } catch { Write-Host ("  mail gonderilemedi: {0}" -f $_.Exception.Message) }
}
function SayfaCek([string]$url){
  $gecici = [IO.Path]::GetTempFileName()
  & $CURL -s -L --max-time 60 -A $UA $url -o $gecici 2>$null | Out-Null
  if(-not (Test-Path $gecici)){ return '' }
  $t = [IO.File]::ReadAllText($gecici); Remove-Item $gecici -Force -ErrorAction SilentlyContinue
  if($t -match 'Internal Server Error'){ return '' }
  return $t
}

Write-Host '======== TGTC NOBETI ========'

# (1) duyuru listesinden en ustteki TGTC duyurusunu bul
$listeHtml = SayfaCek $LISTE
if(-not $listeHtml){
  Mail 'TETIKTE KIRMIZI - TGTC nobeti: DUYURU LISTESI ACILMADI' "Adres: $LISTE`nSayfa bos dondu. GGM site yapisi degismis olabilir."
  Write-Host 'KIRMIZI: duyuru listesi acilmadi.' -ForegroundColor Red; exit 1
}
$duyuruYollari = [regex]::Matches($listeHtml, 'href="([^"]*turk-gumruk-tarife-cetveli[^"]*)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
if(-not $duyuruYollari){
  Mail 'TETIKTE KIRMIZI - TGTC nobeti: TGTC DUYURUSU BULUNAMADI' "Listede 'turk-gumruk-tarife-cetveli' gecen duyuru linki yok. Slug degismis olabilir: $LISTE"
  Write-Host 'KIRMIZI: TGTC duyurusu bulunamadi.' -ForegroundColor Red; exit 1
}

# (2) duyurulardan zip linkini coz (en ustteki = en yeni; ilk zip bulunan kazanir)
$zipUrl = ''
foreach($yol in $duyuruYollari){
  $u = if($yol -match '^https?:'){ $yol } else { $KOKURL + $yol }
  $sayfa = SayfaCek $u
  if(-not $sayfa){ continue }
  $m = [regex]::Match($sayfa, 'href="([^"]*\.zip)"')
  if($m.Success){
    $zipUrl = $m.Groups[1].Value
    if($zipUrl -notmatch '^https?:'){ $zipUrl = $KOKURL + $zipUrl }
    Write-Host ("  duyuru: {0}" -f $u)
    break
  }
}
if(-not $zipUrl){
  Mail 'TETIKTE KIRMIZI - TGTC nobeti: ZIP LINKI COZULEMEDI' ("TGTC duyurulari bulundu ama iclerinde .zip linki yok. Bakilan: " + ($duyuruYollari -join ', '))
  Write-Host 'KIRMIZI: zip linki cozulemedi.' -ForegroundColor Red; exit 1
}
Write-Host ("  zip: {0}" -f $zipUrl)

# (3) indir + sha
$zipYol = Join-Path ([IO.Path]::GetTempPath()) 'tgtc-nobet.zip'
& $CURL -s -L --max-time 300 -A $UA ($zipUrl -replace ' ','%20') -o $zipYol 2>$null | Out-Null
if(-not (Test-Path $zipYol) -or (Get-Item $zipYol).Length -lt $ENAZ){
  $bayt = if(Test-Path $zipYol){ (Get-Item $zipYol).Length } else { 0 }
  Mail 'TETIKTE KIRMIZI - TGTC nobeti: ZIP INDIRILEMEDI/KUCUK' "Adres: $zipUrl`nInen: $bayt bayt (en az $ENAZ beklenirdi)."
  Write-Host 'KIRMIZI: zip indirilemedi ya da supheli kucuk.' -ForegroundColor Red; exit 1
}
$sha = (Get-FileHash $zipYol -Algorithm SHA256).Hash
$bayt = (Get-Item $zipYol).Length
Write-Host ("  indirildi: {0} bayt | sha {1}" -f $bayt, $sha.Substring(0,12))

# (4) damga karsilastir
$damgaYol = Join-Path $kok 'veri/tgtc-kaynak-damga.json'
$eskiSha = ''
if(Test-Path $damgaYol){
  try { $eskiSha = (Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json).damga.sha256 } catch {}
}
if($eskiSha -eq $sha){
  Write-Host 'Kaynak degismemis - tanim seti ayni, is yok.'
  exit 0
}

# (5) degisti (ya da ilk kosu): damga yaz + mail
$ilk = ($eskiSha -eq '')
$damga = @{
  aciklama = 'GGM TGTC Excel seti damgasi. Sha degisince tanim-hasat YERELDE kosulmali (Excel COM).'
  guncelleme = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  damga = @{ url = $zipUrl; bayt = $bayt; sha256 = $sha }
}
($damga | ConvertTo-Json -Depth 3) | Out-File $damgaYol -Encoding utf8
if($ilk){
  Write-Host 'Ilk damga yazildi (mevcut set kayit altina alindi).'
} else {
  Mail 'TETIKTE - TGTC SETI GUNCELLENDI: tanim hasadi zamani' "GGM TGTC Excel seti degisti (muhtemelen Karar 11507 tanimlari islendi).`nYeni: $bayt bayt, sha $sha`nZip: $zipUrl`n`nYapilacak (YEREL, Excel COM ister):`n1) zip'i indir-ac`n2) motor/tanim-hasat.ps1 -TgtcKlasor <acilan klasor>`n3) veri/gtip-tanim.json'u yaz-geri oku kapisiyla commit+push et."
  Write-Host 'DEGISTI: mail atildi + damga guncellendi.' -ForegroundColor Yellow
}
exit 0
