param(
  [Parameter(Mandatory=$true)][string]$Sahne,
  [string]$Cozunurluk = "",
  [string]$Model = "",
  [int]$BeklemeSn = 20,
  [int]$AzamiDk = 15,
  [string]$Tur = "deneme",
  [string]$DenetimYok = "",
  [string]$Kok = ""
)
# ASCII-only script (PS 5.1 BOM trap). Turkish text lives in the JSON scene file (UTF-8).
# Tetikte copy of dizdar-denetim/video/seedance/uret.ps1 + reference images (Seedance 2.5 omni reference).
# Scene JSON may carry "referanslar": list of PNG/JPG paths; "kasa/..." = under _yerel-veri-kasasi, else relative to this folder.
$ErrorActionPreference = 'Stop'
# 24.09.2026 DEPOYA TASINDI: tek kaynak mevzuat-radar\arac\video\uret.ps1. video\sorunun-gunlugu\uret.ps1 yalniz yonlendirici.
# Sahne dosyalari, ciktilar ve harcama defteri video\sorunun-gunlugu altinda kalir (git disi, buyuk mp4).
$depo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = if ($Kok) { $Kok } else { Join-Path $depo 'video\sorunun-gunlugu' }
$kasa = Join-Path (Split-Path -Parent $depo) '_yerel-veri-kasasi'
$key  = [IO.File]::ReadAllText((Join-Path $kasa 'byteplus-ark.key')).Trim()
$base = 'https://ark.ap-southeast.bytepluses.com/api/v3'

$sahneYol = Join-Path $root ("sahne-" + $Sahne + ".json")
$s = [IO.File]::ReadAllText($sahneYol, [Text.Encoding]::UTF8) | ConvertFrom-Json
# 20.09.2026 Cem karari: "720 varsayilan yap". Olculdu (B2a maskot klibi, 3 sn):
# 720p basip 1080'e buyutme vs 1080p orijinal, HER IKISI de Instagram sikistirmasindan (3.5 Mbps) sonra
#   PSNR 48,0 dB / SSIM 0,991  -> 40 dB "gozle ayirt edilemez" esiginin cok ustunde.
# Ek kanit: referans ses 720p'de tuttu (H1e 29 sn), 1080p'de bir kez tamamen coktu (B3a, 11,47 USD yandi).
# ISTISNA: klipte OKUNACAK yazi/ince cizgi varsa 1080p -> -Cozunurluk 1080p ile acikca istenir.
if (-not $s.PSObject.Properties['resolution'] -or -not $s.resolution) { $s.resolution = '720p' }
if ($Cozunurluk) { $s.resolution = $Cozunurluk }
elseif ($s.resolution -eq '1080p') {
  throw ("1080p sahne dosyasindan geliyor (" + $Sahne + "). Cem karari 20.09.2026: varsayilan 720p. " +
         "Gercekten 1080p gerekiyorsa (klipte okunacak yazi var) -Cozunurluk 1080p ile acikca iste.")
}
if ($Model)      { $s.model = $Model }

# 24.09.2026 Cem: "basimdan sonra her cumleyi tek tek kontrol et ... bu cok onemli ve kural olsun video basiminda".
# BASIM SONRASI DENETIM ZORUNLU: sahne json'da "beklenen_replikler" (klipte duyulmasi gereken cumleler) yoksa
# denetim yapilamaz -> PARA HARCANMADAN burada durulur. Bilerek atlamak: -DenetimYok "<gerekce>" (defterde kalir).
$denetimGerekli = -not $DenetimYok
if ($denetimGerekli -and -not ($s.PSObject.Properties['beklenen_replikler'] -and $s.beklenen_replikler)) {
  throw ("sahne-" + $Sahne + ".json icinde 'beklenen_replikler' yok. Basim sonrasi cumle denetimi yapilamaz; basim DURDU (ucret yok). " +
         "Replikleri ekle ya da bilerek -DenetimYok '<gerekce>' ver.")
}

# 20.09.2026 Cem "bunu kalici olarak kapat, bir daha boyle bir hata olmasin":
# pazarlamada kullanilacak sorunun DAYANAK CERCEVESI basimdan ONCE denetlenir.
# Olay: yazilim itfasi sorusu TMS 38'e gore dogruydu ama VUK m.320 varsayilani tam yil;
# videoda tek cerceveyle "yanlis" demek diger cerceveye gore dusuneni haksiz gosterirdi (3,71 USD yandi).
# Sahne dosyasina "soru_id" yazilirsa kapi kosar; KIRMIZI ise basim YAPILMAZ.
if ($s.PSObject.Properties['soru_id'] -and $s.soru_id) {
  $kapiYolu = Join-Path $depo 'arac\pazarlama-soru-kapisi.ps1'
  if (Test-Path $kapiYolu) {
    Write-Host ("KAPI: soru cercevesi denetleniyor -> " + $s.soru_id)
    & powershell -NoProfile -File $kapiYolu -SoruId $s.soru_id
    if ($LASTEXITCODE -ne 0) {
      throw ("PAZARLAMA SORU KAPISI KIRMIZI: " + $s.soru_id + " -- bu soru pazarlamada kullanilmaz (VUK/TMS catali). Baska soru sec ya da video metninde cerceveyi acikca soyle.")
    }
  } else {
    Write-Host ("UYARI: pazarlama soru kapisi bulunamadi, denetim ATLANDI: " + $kapiYolu)
  }
}

$content = @(); $content += @{ type = 'text'; text = $s.prompt }
$refSayi = 0
if ($s.PSObject.Properties['referanslar'] -and $s.referanslar) {
  foreach ($r in @($s.referanslar)) {
    if ($r -like 'kasa/*') { $p = Join-Path $kasa ($r.Substring(5) -replace '/','\') } else { $p = Join-Path $root ($r -replace '/','\') }
    if (-not (Test-Path $p)) { throw ("referans yok: " + $p) }
    $ext = ([IO.Path]::GetExtension($p)).TrimStart('.').ToLower(); if ($ext -eq 'jpg') { $ext = 'jpeg' }
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
    $content += @{ type = 'image_url'; image_url = @{ url = ("data:image/" + $ext + ";base64," + $b64) }; role = 'reference_image' }
    $refSayi++
  }
}

if ($s.PSObject.Properties['referans_sesler'] -and $s.referans_sesler) {
  foreach ($r in @($s.referans_sesler)) {
    if ($r -like 'kasa/*') { $p = Join-Path $kasa ($r.Substring(5) -replace '/','\') } else { $p = Join-Path $root ($r -replace '/','\') }
    if (-not (Test-Path $p)) { throw ("referans ses yok: " + $p) }
    $ext = ([IO.Path]::GetExtension($p)).TrimStart('.').ToLower(); if ($ext -eq 'mp3') { $ext = 'mpeg' }
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
    $content += @{ type = 'audio_url'; audio_url = @{ url = ("data:audio/" + $ext + ";base64," + $b64) }; role = 'reference_audio' }
    $refSayi++
  }
}
$bodyObj = [ordered]@{
  model = $s.model
  content = $content
  ratio = $s.ratio
  duration = [int]$s.duration
  resolution = $s.resolution
  generate_audio = [bool]$s.generate_audio
  watermark = [bool]$s.watermark
}
if ($refSayi -gt 0) { $bodyObj.omni_reference_task_type = 'reference' }
$body = $bodyObj | ConvertTo-Json -Depth 8

$hdr = @{ Authorization = "Bearer $key"; 'Content-Type' = 'application/json; charset=utf-8' }
$bytes = [Text.Encoding]::UTF8.GetBytes($body)
Write-Host ("model=" + $s.model + " res=" + $s.resolution + " ratio=" + $s.ratio + " dur=" + $s.duration + " ref=" + $refSayi + " body=" + [math]::Round($bytes.Length/1MB,2) + "MB")
$t = Invoke-RestMethod -Uri "$base/contents/generations/tasks" -Method Post -Headers $hdr -Body $bytes
Write-Host ("task=" + $t.id)

$deadline = (Get-Date).AddMinutes($AzamiDk)
do {
  Start-Sleep -Seconds $BeklemeSn
  $g = Invoke-RestMethod -Uri "$base/contents/generations/tasks/$($t.id)" -Method Get -Headers $hdr
  Write-Host ("durum=" + $g.status)
} while ($g.status -notin @('succeeded','failed','cancelled') -and (Get-Date) -lt $deadline)

if ($g.status -ne 'succeeded') { Write-Host ("SONUC: " + $g.status + " " + ($g.error | ConvertTo-Json -Compress)); exit 1 }

$url = $g.content.video_url
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$out = Join-Path $root ($s.ad + "-" + $s.resolution + "-" + $stamp + ".mp4")
Invoke-WebRequest -Uri $url -OutFile $out
$tok = $g.usage.completion_tokens
Write-Host ("indi=" + $out)
Write-Host ("tokens=" + $tok)
# harcama defteri (flat list; PS 5.1 nested-array trap avoided with explicit ArrayList)
$defter = Join-Path $root 'harcama.jsonl'
# 1080p birimi 8.42 idi = %28 indirimli fiyat; indirim 17.09.2026 14:00 (UTC+8) BITTI -> liste 11.70.
# TAZELEME BEKLIYOR: liste fiyati 08.09.2026 dokumanindan; BytePlus fiyat sayfasindan teyit edilmedi.
$birim = if ($s.resolution -eq '1080p') { 11.70 } else { 10.70 }
$usd = [math]::Round([double]$tok / 1000000 * $birim, 2)

# ---- BASIM SONRASI CUMLE DENETIMI (klip-denetim.js) ----
# Whisper tum ses + ada ada dokum, beklenen replik hizalama: dusen cumle / kekeleme / fazladan konusma = KIRMIZI.
# Dudak senkronunu OTOMATIK OLCMEZ: <klip>.denetim.png kare tabakasi gozle okunur (yesil cerceve agiz acik, kirmizi kapali).
$denetimSonuc = 'ATLANDI: ' + $DenetimYok
if ($denetimGerekli) {
  $denetciYolu = Join-Path $PSScriptRoot 'klip-denetim.js'
  & node $denetciYolu $out $sahneYol
  $denetimKodu = $LASTEXITCODE
  $denetimSonuc = switch ($denetimKodu) { 0 { 'YESIL' } 1 { 'SARI' } 2 { 'KIRMIZI' } default { 'CALISMADI' } }
}
$kayit = @{ zaman = (Get-Date).ToString('s'); sahne = $s.ad; tur = $Tur; res = $s.resolution; dur = $s.duration; ref = $refSayi; task = $t.id; tokens = $tok; usd = $usd; dosya = (Split-Path -Leaf $out); denetim = $denetimSonuc } | ConvertTo-Json -Compress
[IO.File]::AppendAllText($defter, $kayit + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
Write-Host ("usd=" + $usd)
Write-Host ("DENETIM=" + $denetimSonuc)
if ($denetimSonuc -eq 'KIRMIZI' -or $denetimSonuc -eq 'CALISMADI') {
  Write-Host "!!! KLIP KIRMIZI/DENETLENEMEDI - KURGUYA GECILMEZ. Once parasiz kurtarma yollari (bkz. instagram-ilk-gonderi hafiza notu), sonra Cem'e rapor."
  exit 2
}
