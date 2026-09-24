#requires -Version 5.1
# ============================================================================
#  HAZIR SORU (GM YAZIMI) DOSYALARI — YEREL <-> AMBAR   24.09.2026 · bedel 0
#
#  NEDEN (Cem "1.2.3" — 40 DÜZELT sorusu): GM'in elle düzelttiği/yazdığı sorular veri/fabrika/hazir-<ad>.json
#  dosyasında durur; dosya SORU METNİ taşıdığı için .gitignore'dadır → depoda ve BULUT koşucusunda YOKTUR.
#  motor/kalip-kosucu.ps1 HazirYoluCoz dosya yoksa bilerek DURUR. Basım yalnız bulutta (Cem kuralı) olduğu için
#  hazır sorular bulutta hiç koşamıyordu. Taşıma, ödenmiş parti kayıtlarıyla AYNI yoldan: ambar kalip_parti.
#
#  NEREDE: kalip_parti satırı — etiket '__hazir/<ad>', sinav 'SISTEM' (soru sayımları sinav=SGS/SMMM/KGK süzer, bu satır
#  hiçbir sayıma girmez). İçerik: { dosya, sorular[] }. Soru metni ambarda zaten parti içeriği olarak durur; depoya GİRMEZ.
#
#  KULLANIM
#    powershell -NoProfile -File arac/hazir-senkron.ps1 -Yukle -Ad duzelt-fmuh      (yerel hazir-duzelt-fmuh.json -> ambar)
#    powershell -NoProfile -File arac/hazir-senkron.ps1 -Indir                        (ambardaki bütün __hazir/* -> yerel dosya)
#  Yükleme geri okunur: ambardaki soru sayısı yereldekine eşit değilse çıkış 1.
# ============================================================================
param([switch]$Indir, [switch]$Yukle, [string]$Ad = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ($Indir -xor $Yukle)) { throw 'Tek yön seç: -Indir YA DA -Yukle' }
$depoKok = Split-Path -Parent $PSScriptRoot
$servisAnahtari = "$env:SUPABASE_SERVICE_KEY"; if (-not $servisAnahtari) { $servisAnahtari = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
if (-not $servisAnahtari.Trim()) { throw 'SUPABASE_SERVICE_KEY yok' }
$servisAnahtari = $servisAnahtari.Trim()
$tabloUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$istekBaslik = @{ apikey = $servisAnahtari; Authorization = "Bearer $servisAnahtari"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$fabrika = Join-Path $depoKok 'veri\fabrika'

function AmbarGetir([string]$filtre) {
  $r = Invoke-WebRequest -UseBasicParsing -Uri ("$tabloUcu" + "?select=etiket,icerik&$filtre&order=etiket.asc&limit=200") -Headers $istekBaslik -TimeoutSec 120
  return @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
}
function SoruDizisi($ic) { if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }; return @(@($ic.sorular) | ForEach-Object { $_ } | Where-Object { $_ -and $_.soru }) }

if ($Yukle) {
  if ($Ad -notmatch '^[a-z0-9][a-z0-9-]{1,60}$') { throw "Ad kucuk harf/rakam/tire olmali: '$Ad'" }
  $yol = Join-Path $fabrika "hazir-$Ad.json"; if (-not (Test-Path $yol)) { throw "dosya yok: $yol" }
  $sorular = @((ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($yol, [Text.Encoding]::UTF8))) | ForEach-Object { $_ } | Where-Object { $_ -and $_.soru })
  if (-not $sorular.Count) { throw "dosyada soru yok: $yol" }
  $govde = [ordered]@{ etiket = "__hazir/$Ad"; sinav = 'SISTEM'; yazan = 'hazir-senkron'
    icerik = [ordered]@{ aciklama = 'GM yazımı hazır soru dosyası (arac/hazir-senkron.ps1). Bulut koşucusu -Indir ile veri/fabrika/hazir-<ad>.json yazar.'; dosya = "hazir-$Ad.json"; sorular = $sorular } }
  $bayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 12 -Compress))
  $bas = $istekBaslik + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }
  [void](Invoke-RestMethod -Method Post -Uri "$tabloUcu`?on_conflict=etiket" -Headers $bas -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 120)
  $geri = @(AmbarGetir ("etiket=eq." + [uri]::EscapeDataString("__hazir/$Ad")))
  $n = $(if ($geri.Count) { @(SoruDizisi $geri[0].icerik).Count } else { 0 })
  if ($n -ne $sorular.Count) { Write-Host "⛔ GERİ OKUMA TUTMADI: yerel $($sorular.Count) soru, ambarda $n" -ForegroundColor Red; exit 1 }
  "YÜKLENDİ: __hazir/$Ad · $n soru (geri okundu)"
  return
}
# -Indir
New-Item -ItemType Directory -Force $fabrika | Out-Null
$satir = @(AmbarGetir ("etiket=like." + [uri]::EscapeDataString('__hazir/*')))
$yazilan = 0
foreach ($s in $satir) {
  $adi = "$($s.etiket)".Substring('__hazir/'.Length); if ($Ad -and $adi -ne $Ad) { continue }
  if ($adi -notmatch '^[a-z0-9][a-z0-9-]{1,60}$') { Write-Host "  atlandı (geçersiz ad): $adi" -ForegroundColor Yellow; continue }
  $sorular = @(SoruDizisi $s.icerik); if (-not $sorular.Count) { continue }
  [IO.File]::WriteAllText((Join-Path $fabrika "hazir-$adi.json"), (ConvertTo-Json -InputObject $sorular -Depth 12), (New-Object Text.UTF8Encoding $false))
  "  indi: hazir-$adi.json · $($sorular.Count) soru"; $yazilan++
}
"HAZIR İNDİRME: $yazilan dosya"
