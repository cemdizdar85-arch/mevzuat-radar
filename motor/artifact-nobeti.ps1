# ============================================================================
#  ARTIFACT NOBETCISI (08.09.2026, Cem "1 yap")
#
#  NEDEN VAR: 25.07'de yazilan "artifact ozeldir" hukmu YANLISTI - PUBLIC repoda
#  artifact'i okuma yetkisi olan HERKES indirir (GitHub belgesi). 7 haftalik
#  yedek (248 MB) firmalar/mukellefler/belgeler dokumunu SIFRESIZ koymustu ve
#  hic kimse fark etmedi. Bu nobetci her gun deponun TUM artifact'lerini sayar:
#    - github-pages-*         -> site derlemesi, zaten kamu (indirilmez)
#    - izinli adlar           -> ilan.gov.tr verisi, kamu kaynagi (indirilmez, kaydedilir)
#    - geri kalan her sey     -> INDIRILIR, icindeki dosyalar SADECE .enc ise SIFRELI,
#                                degilse ACIK -> KIRMIZI
#  Daha once hukum verilmis artifact (id) yeniden indirilmez (rapor onbellegi).
#
#  UC HAL: YESIL (acik yok) - KIRMIZI (acik var; hangi id, hangi dosya) - KOR (API
#  okunamadi - yesil SAYILMAZ). Kapi neden dustugunu raporda ve annotation'da soyler.
#
#  KOSAR: .github/workflows/artifact-nobeti.yml (GITHUB_TOKEN, actions:read).
#  Yerelde: $env:GITHUB_TOKEN + $env:GITHUB_REPOSITORY='cemdizdar85-arch/mevzuat-radar'
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. ([IO.Path]::Combine($kok, 'arac', 'rapor-yaz.ps1'))
$raporYol = [IO.Path]::Combine($kok, 'veri', 'artifact-nobeti.json')

$repo  = "$($env:GITHUB_REPOSITORY)".Trim(); if (-not $repo) { $repo = 'cemdizdar85-arch/mevzuat-radar' }
$token = "$($env:GITHUB_TOKEN)".Trim()
$IZINLI = @('^alacak-okuma-pilot-', '^alacak-damga-yedek-')   # ilan.gov.tr kaynakli, kisisel veri degil

$eski = @{}
if (Test-Path $raporYol) {
  try { $r0 = Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json; foreach ($k in $r0.hukumler.PSObject.Properties) { $eski[$k.Name] = $k.Value } } catch {}
}

function Bitir($durum, $neden, $liste, $hukumler) {
  $cikti = [ordered]@{
    olcum   = (Get-Date).ToString('dd.MM.yyyy HH:mm')
    durum   = $durum          # YESIL / KIRMIZI / KOR
    neden   = $neden
    aciklama = 'Depodaki artifactler: github-pages kamu, izinli adlar kamu ilan verisi, gerisi yalniz .enc icermeli. ACIK = sifresiz dosya tasiyan artifact; public repoda herkes indirir.'
    sayim   = [ordered]@{ toplam = @($liste).Count; acik = @($liste | Where-Object { $_.hukum -eq 'ACIK' }).Count; sifreli = @($liste | Where-Object { $_.hukum -eq 'sifreli' }).Count; kamu = @($liste | Where-Object { $_.hukum -in 'site','kamu-ilan' }).Count }
    acik    = @($liste | Where-Object { $_.hukum -eq 'ACIK' } | ForEach-Object { [ordered]@{ id = $_.id; ad = $_.ad; mb = $_.mb; dosyalar = $_.dosyalar; sil = "gh api -X DELETE repos/$repo/actions/artifacts/$($_.id)" } })
    hukumler = $hukumler
  }
  RaporYaz -Hedef $raporYol -Nesne $cikti | Out-Null
  Write-Host ("SONUC: {0} - {1}" -f $durum, $neden)
  if ($durum -eq 'KIRMIZI') { Write-Host ("::error title=artifact nobeti::{0}" -f $neden); exit 1 }
  if ($durum -eq 'KOR')     { Write-Host ("::warning title=artifact nobeti::{0}" -f $neden); exit 2 }
  Write-Host ("::notice title=artifact nobeti::{0}" -f $neden)
  exit 0
}

if (-not $token) { Bitir 'KOR' 'GITHUB_TOKEN yok - artifact listesi okunamadi' @() $eski }
$H = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'MevzuatRadar-ArtifactNobeti'; 'X-GitHub-Api-Version' = '2022-11-28' }
# Beklenmeyen cokme de annotation'a yazilir (Actions gunlugu yetkisiz okunamiyor; ilk kosu
# 08.09'da sebepsiz dustu). 'exit' try icinden gecer, yakalanmaz.
trap {
  $satir = $_.InvocationInfo.ScriptLineNumber
  Write-Host ("::error title=artifact nobeti COKTU::satir {0}: {1}" -f $satir, ("$($_.Exception.Message)" -replace '[\r\n]',' '))
  try { Bitir 'KOR' ("betik coktu (satir {0}): {1}" -f $satir, $_.Exception.Message) @() $eski } catch {}
  exit 2
}

# --- 1) LISTE (sayfali) -----------------------------------------------------------
$hepsi = New-Object System.Collections.Generic.List[object]
try {
  $sayfa = 1
  while ($true) {
    $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/actions/artifacts?per_page=100&page=$sayfa" -Headers $H -TimeoutSec 60
    foreach ($a in @($r.artifacts)) { if (-not $a.expired) { $hepsi.Add($a) } }
    if (@($r.artifacts).Count -lt 100) { break }
    $sayfa++
  }
} catch { Bitir 'KOR' ("artifact listesi alinamadi: {0}" -f $_.Exception.Message) @() $eski }
Write-Host ("artifact (suresi dolmamis): {0}" -f $hepsi.Count)

# --- 2) HUKUM ------------------------------------------------------------------------
$liste = New-Object System.Collections.Generic.List[object]
$hukumler = [ordered]@{}
$tmp = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'artifact-nobeti'); New-Item -ItemType Directory -Force $tmp | Out-Null
foreach ($a in $hepsi) {
  $id = "$($a.id)"; $ad = "$($a.name)"; $mb = [math]::Round($a.size_in_bytes / 1MB, 1)
  $hukum = ''; $dosyalar = @()
  if ($ad -like 'github-pages*') { $hukum = 'site' }
  elseif ($IZINLI | Where-Object { $ad -match $_ }) { $hukum = 'kamu-ilan' }
  elseif ($eski.ContainsKey($id) -and "$($eski[$id].hukum)" -in 'sifreli','ACIK') { $hukum = $eski[$id].hukum; $dosyalar = @($eski[$id].dosyalar) }
  else {
    # INDIR ve icine bak: yalniz dosya ADLARI okunur, icerik acilmaz
    $zip = [IO.Path]::Combine($tmp, "$id.zip")
    try {
      Invoke-WebRequest -Uri $a.archive_download_url -Headers $H -OutFile $zip -TimeoutSec 600
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      $z = [IO.Compression.ZipFile]::OpenRead($zip)
      $dosyalar = @($z.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object { $_.FullName })
      $z.Dispose()
      [IO.File]::Delete($zip)
      $acik = @($dosyalar | Where-Object { $_ -notmatch '\.enc$' })
      $hukum = if ($dosyalar.Count -eq 0) { 'bos' } elseif ($acik.Count -eq 0) { 'sifreli' } else { 'ACIK' }
      $dosyalar = @($dosyalar | Select-Object -First 12)
    } catch {
      $hukum = 'indirilemedi'; $dosyalar = @("$($_.Exception.Message)")
    }
  }
  $liste.Add([ordered]@{ id = $id; ad = $ad; mb = $mb; olusturma = "$($a.created_at)"; hukum = $hukum; dosyalar = $dosyalar })
  $hukumler[$id] = [ordered]@{ ad = $ad; hukum = $hukum; dosyalar = $dosyalar }
  Write-Host ("  {0,-34} {1,7} MB  {2}" -f $ad, $mb, $hukum)
}

$acikler = @($liste | Where-Object { $_.hukum -eq 'ACIK' })
$indirilemeyen = @($liste | Where-Object { $_.hukum -eq 'indirilemedi' })
if ($acikler.Count) {
  Bitir 'KIRMIZI' ("{0} artifact SIFRESIZ dosya tasiyor (public repoda herkes indirebilir): {1}. Silme komutlari raporda (veri/artifact-nobeti.json)." -f $acikler.Count, (($acikler | ForEach-Object { $_.ad }) -join ', ')) $liste $hukumler
}
if ($indirilemeyen.Count) {
  Bitir 'KOR' ("{0} artifact indirilemedi, hukum verilemedi: {1}" -f $indirilemeyen.Count, (($indirilemeyen | ForEach-Object { $_.ad }) -join ', ')) $liste $hukumler
}
Bitir 'YESIL' ("acik artifact yok ({0} artifact: {1} sifreli, {2} kamu)" -f $liste.Count, @($liste | Where-Object { $_.hukum -eq 'sifreli' }).Count, @($liste | Where-Object { $_.hukum -in 'site','kamu-ilan' }).Count) $liste $hukumler
