#requires -Version 5.1
<#
================================================================================
  SMMM (BİTİRME) KAPSAMA TABLOSU — "ders · konu · sınavda kaç kez · bizde kaç"
  22.09.2026 · bedel 0 (model yok, ağ yok — yalnız yerel dosyalar)

  NİYE VAR: SGS'nin kapsama tablosu (arac/konu-kapsama-tablosu.ps1) var ama SMMM'nin
  YOK — o betik veri/sgs-analiz.json okur ve bitirmede karşılığı yoktur. Bitirme
  basım planı bugüne kadar bu tablo olmadan kuruldu. Tablo olmayınca "hangi konuya
  kaç soru lazım" sorusu her seferinde elde hesaplandı.

  SÜTUNLAR
    ders · konu · cikmis (çıkmış sınavlarda kaç kez göründü) · yazdik (parti
    dosyalarındaki taslak) · yayinlanabilir (SMMM yayın şartını geçen) · hedef
    (cikmis × HedefKat, en az 1) · acik (hedef − yayinlanabilir) · durum · engel

  ENGEL sütunu: konu şu an plana giremiyorsa nedeni — KISIR / KAYNAK-BORCU
  (veri/sinav/kisir-konu-smmm.json). Engelli konu "açık" görünse de basılmaz.

  🚫 BU TABLO ŞUNU GÖRMEZ:
    · Konu adının farklı yazımlarını tek konuya indirmez (eşleme sözlüğü
      veri/sinav/smmm-konu-es.json ayrı iş; burada köprü adı esas alınır).
    · "cikmis" köprüden gelir; köprü yanlışsa hedef de yanlış olur.
    · İkiz süzgecinin yayında eleyeceğini görmez — "yayinlanabilir" yayın şartıdır,
      ikiz kapısı değil (yayıncı ayrıca eler).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/smmm-kapsama-tablosu.ps1
    ... -HedefKat 2        (hedefi düşür)
    ... -Ders 'Vergi'      (tek ders)
================================================================================
#>
param([int]$HedefKat = 3, [string]$Ders = '', [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1')
. (Join-Path $buDizin 'smmm-ders-adi.ps1')
$onay = SmmmOnayHarita $kok

function Nrm([string]$s) {
  $t = "$s".ToLowerInvariant() -replace 'ı', 'i' -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}

# --- 1) ÇIKMIŞ: konu köprüsünden (SMMM/yeterlilik satırları) ---
$kopruYol = Join-Path $kok 'veri\fabrika\konu-koprusu.json'
if (-not (Test-Path $kopruYol)) { throw "konu köprüsü yok: $kopruYol — ölçülemez" }
$cikmis = @{}; $kopruAd = @{}; $kopruDers = @{}
foreach ($r in @((Get-Content $kopruYol -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) {
  if ("$($r.sinav)" -notmatch 'SMMM|smmm|yeterlilik') { continue }
  $n = Nrm "$($r.konu)"; if (-not $n) { continue }
  $c = [int]$r.cikmis
  if (-not $cikmis.ContainsKey($n) -or $c -gt $cikmis[$n]) { $cikmis[$n] = $c }
  if (-not $kopruAd.ContainsKey($n)) { $kopruAd[$n] = "$($r.konu)" }
  $d = "$($r.bizim_ders)"; if (-not $d) { $d = "$($r.arsiv_ders)" }
  if ($d -and -not $kopruDers.ContainsKey($n)) { $kopruDers[$n] = $d }
}

# --- 2) EŞLEME SÖZLÜĞÜ: kasa yazımı -> köprü yazımı ---
$es = @{}
$esYol = Join-Path $kok 'veri\sinav\smmm-konu-es.json'
if (Test-Path $esYol) {
  foreach ($e in @((Get-Content $esYol -Raw -Encoding UTF8 | ConvertFrom-Json).eslemeler | ForEach-Object { $_ })) {
    if ($e) { $es[(Nrm "$($e.analiz)")] = (Nrm "$($e.kopru)") }
  }
}

# --- 3) BİZDE NE VAR: parti dosyaları ---
$yazdik = @{}; $yayin = @{}; $dersKonu = @{}
$partiSay = 0
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json' -ErrorAction SilentlyContinue)) {
  $et = $f.BaseName -replace '^kalip-parti-', ''
  if ($et -match '(^|-)pilot\d*(-|$)') { continue }
  $partiSay++
  $dersEt = SmmmDersAdi $et $null
  $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($o in $j.PSObject.Properties) {
    if ($o.Name -notlike 'kp-*') { continue }
    $v = $o.Value; if (-not $v -or -not $v.soru) { continue }
    $n = Nrm "$($v.konu)"; if (-not $n) { continue }
    if ($es.ContainsKey($n)) { $n = $es[$n] }
    $yazdik[$n] = 1 + [int]$yazdik[$n]
    if ((SmmmYayinSarti "$et/$($o.Name)" $v $onay).gecer) { $yayin[$n] = 1 + [int]$yayin[$n] }
    if (-not $dersKonu.ContainsKey($n)) { $dersKonu[$n] = $(if ($dersEt) { $dersEt } else { '' }) }
  }
}
if ($partiSay -lt 50) { throw "parti dosyası az ($partiSay) — ambardan inmemiş olabilir (arac/parti-senkron.ps1 -Indir -Yaz -Sinav SMMM -OnEk 'smmm-')" }

# --- 4) ENGEL: kısır / kaynak borcu ---
$engel = @{}
$kisirYol = Join-Path $kok 'veri\sinav\kisir-konu-smmm.json'
if (Test-Path $kisirYol) {
  foreach ($kk in @((Get-Content $kisirYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular | ForEach-Object { $_ })) {
    if ($kk) { $engel[(Nrm "$($kk.konu)")] = $(if ("$($kk.neden)") { "$($kk.neden)" } else { 'KISIR' }) }
  }
}

# --- 5) TABLO ---
$satir = New-Object System.Collections.Generic.List[object]
$tumKonu = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($n in $cikmis.Keys) { [void]$tumKonu.Add($n) }
foreach ($n in $yazdik.Keys) { [void]$tumKonu.Add($n) }
foreach ($n in $tumKonu) {
  $c = [int]$cikmis[$n]
  $d = $(if ($kopruDers.ContainsKey($n) -and $kopruDers[$n]) { $kopruDers[$n] } elseif ($dersKonu.ContainsKey($n)) { $dersKonu[$n] } else { '' })
  if ($Ders -and $d -notmatch $Ders) { continue }
  $hedef = [Math]::Max(1, $c * $HedefKat)
  $yay = [int]$yayin[$n]
  $acik = [Math]::Max(0, $hedef - $yay)
  $durum = $(if ($yay -ge $hedef) { 'YETER' } elseif ($yay -eq 0) { 'HIC YOK' } else { 'EKSIK' })
  $satir.Add([pscustomobject]@{
      ders = $d; konu = $(if ($kopruAd.ContainsKey($n)) { $kopruAd[$n] } else { $n })
      cikmis = $c; yazdik = [int]$yazdik[$n]; yayinlanabilir = $yay
      hedef = $hedef; acik = $acik; durum = $durum
      engel = $(if ($engel.ContainsKey($n)) { $engel[$n] } else { '' })
    })
}

$csv = Join-Path $kok 'veri\fabrika\smmm-kapsama.csv'
$satir | Sort-Object @{e = { $_.ders } }, @{e = { $_.acik }; Descending = $true } | Export-Csv -NoTypeInformation -Encoding UTF8 $csv

if (-not $Sessiz) {
  $acikToplam = ($satir | Where-Object { -not $_.engel } | Measure-Object acik -Sum).Sum
  $engelliAcik = ($satir | Where-Object { $_.engel } | Measure-Object acik -Sum).Sum
  "SMMM KAPSAMA (hedef = cikmis x $HedefKat) · parti dosyasi $partiSay"
  "  konu {0} · yayinlanabilir {1} · hedef {2}" -f $satir.Count, (($satir | Measure-Object yayinlanabilir -Sum).Sum), (($satir | Measure-Object hedef -Sum).Sum)
  "  ACIK (basilabilir)  : {0}" -f $acikToplam
  "  ACIK ama ENGELLI    : {0}  (kisir/kaynak borcu - once kaynak)" -f $engelliAcik
  ''
  'DERS DERS:'
  '  ders                              konu  cikmis  yayin  hedef   acik  engelli'
  foreach ($g in ($satir | Group-Object ders | Sort-Object { ($_.Group | Measure-Object acik -Sum).Sum } -Descending)) {
    $ad = $(if ($g.Name) { $g.Name } else { '(ders yok)' })
    "  {0,-32} {1,4} {2,7} {3,6} {4,6} {5,6} {6,8}" -f $ad.Substring(0, [Math]::Min(32, $ad.Length)), $g.Count,
    ($g.Group | Measure-Object cikmis -Sum).Sum, ($g.Group | Measure-Object yayinlanabilir -Sum).Sum,
    ($g.Group | Measure-Object hedef -Sum).Sum,
    (($g.Group | Where-Object { -not $_.engel } | Measure-Object acik -Sum).Sum),
    (($g.Group | Where-Object { $_.engel } | Measure-Object acik -Sum).Sum)
  }
  ''
  'EN BUYUK 15 ACIK (engelsiz, cikmis sirasina gore):'
  foreach ($x in ($satir | Where-Object { -not $_.engel -and $_.acik -gt 0 } | Sort-Object cikmis, acik -Descending | Select-Object -First 15)) {
    "  {0,3} acik · cikmis {1,2} · yayin {2,2} · {3,-40} [{4}]" -f $x.acik, $x.cikmis, $x.yayinlanabilir, "$($x.konu)".Substring(0, [Math]::Min(40, "$($x.konu)".Length)), $x.ders
  }
  ''
  "CSV: veri/fabrika/smmm-kapsama.csv"
}
