#requires -Version 5.1
<#
================================================================================
  TOPLU KUYRUK HIZI — "gece mi hızlı, gündüz mü?" sorusunun ÖLÇÜLÜ cevabı   23.09.2026 · bedel 0

  Cem 23.09: "belki gece daha hızlı soru basıyordur" → GM önerisi "dalgaları gündüz aç".
  ⛔ O ÖNERİ VERİYE DAYANMIYORDU: w6 gece başladı 75–95 dk sürdü (hızlı), w5-2 gündüz 13 saat (yavaş),
  w7 gece 315 dk. Kural koymadan önce ölçü lazım. Bu betik Anthropic'in kendi kaydını okur:
  her toplu partinin GÖNDERİLDİĞİ (created_at) ve BİTTİĞİ (ended_at) an → bekleme süresi, gönderildiği
  TR saatine göre gruplanır.

  ⛔ PARA HARCAMAZ: yalnız GET /v1/messages/batches (liste). Sonuç indirilmez, istek gönderilmez.
  🚫 GÖRMEZ: partinin BÜYÜKLÜĞÜNÜ ayırmaz (30 istekli parti 1 istekliden yavaş olabilir) — istek sayısı
    ayrıca yazılır; ve yalnız bizim hesabımızın partilerine bakar (Anthropic'in genel yükü değil).
  ÇIKTI: veri/TOPLU-KUYRUK-HIZI.md (depoya girer; soru metni yok)
  KULLANIM: powershell -NoProfile -File arac/toplu-kuyruk-hizi.ps1 [-Gun 7]
================================================================================
#>
param([int]$Gun = 7, [int]$SayfaTavan = 60)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
$k = "$($env:ANTHROPIC_API_KEY)"; if (-not $k) { $k = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', 'User') }
if (-not "$k".Trim()) { throw 'ANTHROPIC_API_KEY yok' }
$H = @{ 'x-api-key' = "$k".Trim(); 'anthropic-version' = '2023-06-01' }
$sinir = (Get-Date).ToUniversalTime().AddDays(-$Gun)
$tum = New-Object System.Collections.Generic.List[object]; $after = ''
for ($s = 0; $s -lt $SayfaTavan; $s++) {
  $u = 'https://api.anthropic.com/v1/messages/batches?limit=100' + $(if ($after) { "&after_id=$after" } else { '' })
  $r = Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 60
  foreach ($b in @($r.data)) { $tum.Add($b) }
  if (-not $r.has_more) { break }; $after = $r.last_id
  if (@($r.data | Where-Object { ([datetime]$_.created_at).ToUniversalTime() -lt $sinir }).Count) { break }
}
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('Turkey Standard Time')
$olc = New-Object System.Collections.Generic.List[object]
foreach ($b in $tum) {
  $c = ([datetime]$b.created_at).ToUniversalTime(); if ($c -lt $sinir) { continue }
  if ("$($b.processing_status)" -ne 'ended' -or -not $b.ended_at) { continue }
  $e = ([datetime]$b.ended_at).ToUniversalTime()
  $ist = [int]$b.request_counts.succeeded + [int]$b.request_counts.errored + [int]$b.request_counts.canceled + [int]$b.request_counts.expired
  $olc.Add([pscustomobject]@{ saat = [TimeZoneInfo]::ConvertTimeFromUtc($c, $tz).Hour; dk = ($e - $c).TotalMinutes; istek = $ist })
}
function Yuzdelik($dizi, [double]$p) { $s = @($dizi | Sort-Object); if (-not $s.Count) { return 0 }; return $s[[int][Math]::Min($s.Count - 1, [Math]::Floor($p * ($s.Count - 1)))] }
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# TOPLU KUYRUK HIZI — gönderildiği saate göre bekleme')
$md.Add('')
$md.Add("> Türetilmiştir (``arac/toplu-kuyruk-hizi.ps1``), elle düzenlenmez. Ölçüm: $(Get-Date -Format 'yyyy-MM-dd HH:mm') · son $Gun gün · biten parti $($olc.Count) · bedel 0")
$md.Add('> Kaynak: Anthropic toplu parti kaydı (created_at → ended_at). Saat = partinin gönderildiği **TR** saati.')
$md.Add('> 🚫 Parti büyüklüğünü ayırmaz; yalnız bizim hesabımızın partilerine bakar.')
$md.Add('')
$md.Add('| TR saat | parti | istek | medyan dk | %90 dk | en uzun dk |')
$md.Add('|---:|---:|---:|---:|---:|---:|')
foreach ($g in ($olc | Group-Object saat | Sort-Object { [int]$_.Name })) {
  $d = @($g.Group | ForEach-Object { $_.dk })
  $md.Add(("| {0:00}:00 | {1} | {2} | {3:N0} | {4:N0} | {5:N0} |" -f [int]$g.Name, $g.Count, (($g.Group | Measure-Object istek -Sum).Sum), (Yuzdelik $d 0.5), (Yuzdelik $d 0.9), (($d | Measure-Object -Maximum).Maximum)))
}
$tumD = @($olc | ForEach-Object { $_.dk })
# 23.09 (Cem "1.2.3"): SABAH KARARI için son 24 saat + şu an bekleyen. O gün 81 parti 3 saat 0 işlendi; 7 günlük medyan (2 dk)
# bunu göstermiyordu — dalga açma kararı "bugün kuyruk ne durumda" sorusuyla verilir.
$simdi = (Get-Date).ToUniversalTime()
$son24 = @($tum | Where-Object { "$($_.processing_status)" -eq 'ended' -and $_.ended_at -and ([datetime]$_.created_at).ToUniversalTime() -ge $simdi.AddHours(-24) } | ForEach-Object { (([datetime]$_.ended_at).ToUniversalTime() - ([datetime]$_.created_at).ToUniversalTime()).TotalMinutes })
$bekleyen = @($tum | Where-Object { "$($_.processing_status)" -eq 'in_progress' })
$enEski = if ($bekleyen.Count) { [int](($bekleyen | ForEach-Object { ($simdi - ([datetime]$_.created_at).ToUniversalTime()).TotalMinutes } | Measure-Object -Maximum).Maximum) } else { 0 }
$md.Add('')
$md.Add(("**Son 24 saat:** biten parti {0} · medyan {1:N0} dk · %90 {2:N0} dk · **şu an bekleyen {3} parti, en eskisi {4} dk** (liste sınırı: son {5} sayfa)" -f $son24.Count, (Yuzdelik $son24 0.5), (Yuzdelik $son24 0.9), $bekleyen.Count, $enEski, $SayfaTavan))
$durumK = if ($bekleyen.Count -and $enEski -gt 120) { 'YAVAŞ — en eski bekleyen 2 saati geçti; yeni dalga kuyruğu uzatır, süre belirsiz' } elseif ((Yuzdelik $son24 0.5) -gt 30) { 'YAVAŞ — son 24 saat medyanı 30 dk üstü' } else { 'NORMAL' }
$md.Add("**Kuyruk durumu: $durumK**")
$md.Add(("**Genel:** medyan {0:N0} dk · %90 {1:N0} dk · parti {2}" -f (Yuzdelik $tumD 0.5), (Yuzdelik $tumD 0.9), $olc.Count))
$md.Add('')
$md.Add('Kural koymak için: bir saat diliminin medyanı ötekilerden **belirgin ve birkaç gün üst üste** düşükse o saat "tercih" olur. Tek gecelik veri kural değildir.')
[IO.File]::WriteAllText((Join-Path $kok 'veri\TOPLU-KUYRUK-HIZI.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
$md | Select-Object -Skip 6
