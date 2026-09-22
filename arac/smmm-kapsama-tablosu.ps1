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
param(
  [int]$HedefKat = 3, [string]$Ders = '', [switch]$Sessiz,
  # ⭐ 22.09.2026 (Cem "1 ve 2 yap"): "hedef = çıkmış × kat" formülü bitirme hedefiyle
  #   KONUŞMUYORDU. Ölçüldü: kat 1'de bile açık 8.434, kat 3'te 16.697 çıkıyor — çünkü
  #   köprüde 8.318 konu var ve her birine en az 1 hedef düşüyor. Cem'in hedefi ise
  #   BANKANIN TOPLAMI (4.000 soru), konu başına kat değil.
  #   -ToplamHedef verilince hedef, SIKLIK AĞIRLIKLI olarak o toplamdan dağıtılır:
  #     hedef_i = ToplamHedef × çıkmış_i / Σçıkmış   (çıkmış=0 olan konuya hedef 0)
  #   Böylece "bitirdik mi" sorusunun cevabı tek sayıdır: toplam açık.
  #   ⚠ Taban yok: çıkmışı 1 olan konu bu dağıtımda 1'in altında kalıp 0 hedef alabilir.
  #     Bu bilinçlidir — nadir konu bankanın önceliği değildir. Kat modu hâlâ duruyor.
  #   VARSAYILAN 4000: Cem'in bitirme hedefi (bkz. hafıza "bitirme hedefi 4.000→8.000").
  #   Kat moduna dönmek için: -ToplamHedef 0 -HedefKat 3
  [int]$ToplamHedef = 4000,
  # ⛔⭐ 23.09.2026 YENİLİK KURALI (Cem: "çıkmış sorularda yeni olanlardan basmak lazım,
  #   10 yıldır sorulmayan bir soruya bizde soru basmamalıyız").
  #   ÖLÇÜLDÜ (veri/smmm-analiz.json, 419 dönem×ders kaydı, 2008–2026): eski hedef dağıtımı
  #   1.121 soruluk hedefi 10+ YILDIR SORULMAYAN 1.013 konuya veriyordu; bu konulara bugüne
  #   kadar 223 soru basılmıştı ("sebepsiz zenginleşme davası" son 2014/2 — bizde 12 soru).
  #   Yeni kural: AĞIRLIK tüm zamanların çıkma sayısı DEĞİL, -YenilikYil'dan (varsayılan
  #   2016 = son 10 yıl) bu yana kaç kez sorulduğu. Bu pencerede hiç sorulmayan konunun
  #   hedefi 0'dır — plan kurucu ona soru yazmaz.
  #   🚫 GÖRMEZ: analizde adı eşleşmeyen konu ("analizde YOK") için yenilik ÖLÇÜLEMEZ; bu
  #     konulara da hedef verilmez (yeni olduğunu kanıtlayamadığımız konuya para vermeyiz).
  #     Bu, ad eşleşmesi düzeltilince bazı gerçekten yeni konuları geri getirecek.
  [int]$YenilikYil = 2016
)
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

# --- 2b) YENİLİK: çıkmış kitapçık analizi (dönem × ders × konu sayımı) ---
#   Anahtar biçimi "Ders|konu" (23.09 ölçüldü) — ders öneki atılır, eşleme sözlüğüyle köprü adına çevrilir.
$anYol = Join-Path $kok 'veri\smmm-analiz.json'
if (-not (Test-Path $anYol)) { throw "çıkmış analizi yok: $anYol — yenilik ölçülemez, tablo YAZILMADI" }
$sonSira = @{}; $pencereSay = @{}; $anGorulen = @{}
foreach ($dd in @((Get-Content $anYol -Raw -Encoding UTF8 | ConvertFrom-Json).donemler | ForEach-Object { $_ })) {
  if (-not $dd -or -not $dd.konuSayim) { continue }
  $anah = "$($dd.donem)|$($dd.ders)"; if ($anGorulen.ContainsKey($anah)) { continue }; $anGorulen[$anah] = 1
  $yil = [int]("$($dd.donem)" -replace '/.*$', ''); $sira = $yil * 10 + [int]("$($dd.donem)" -replace '^.*/', '')
  foreach ($p in $dd.konuSayim.PSObject.Properties) {
    $n = Nrm ("$($p.Name)" -replace '^[^|]*\|', ''); if (-not $n) { continue }
    if ($es.ContainsKey($n)) { $n = $es[$n] }
    if (-not $sonSira.ContainsKey($n) -or $sira -gt $sonSira[$n]) { $sonSira[$n] = $sira }
    if ($yil -ge $YenilikYil) { $pencereSay[$n] = [int]$pencereSay[$n] + [int]$p.Value }
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
# AĞIRLIK: son $YenilikYil'dan bu yana kaç kez soruldu (YENİLİK KURALI, 23.09). Pencerede sorulmayan = 0.
$pencereToplam = 0
if ($ToplamHedef -gt 0) { foreach ($n in $tumKonu) { $pencereToplam += [int]$pencereSay[$n] } }
# ⭐ 23.09: EN BÜYÜK KALAN YÖNTEMİ — düz yuvarlamada 4.000'in ~520'si kayboluyordu (küçük payların
#   hepsi 0'a yuvarlanıyordu, toplam hedef 3.479 çıkıyordu). Cem "4.000 olsun" dedi: tablo toplamı
#   TAM 4.000 olmalı. Önce taban (aşağı yuvarlama) verilir, eksik kalan birimler en büyük kesirli
#   paya sahip konulara birer birer dağıtılır.
$hedefHarita = @{}
if ($ToplamHedef -gt 0 -and $pencereToplam -gt 0) {
  $kesir = New-Object System.Collections.Generic.List[object]
  $dagitilan = 0
  foreach ($n in $tumKonu) {
    $pc0 = [int]$pencereSay[$n]; if ($pc0 -le 0) { continue }
    $tam = $ToplamHedef * $pc0 / [double]$pencereToplam
    $taban = [int][Math]::Floor($tam)
    $hedefHarita[$n] = $taban; $dagitilan += $taban
    $kesir.Add([pscustomobject]@{ n = $n; k = ($tam - $taban); pc = $pc0 })
  }
  $kalan = $ToplamHedef - $dagitilan
  foreach ($x in ($kesir | Sort-Object @{e = { $_.k }; Descending = $true }, @{e = { $_.pc }; Descending = $true }, n | Select-Object -First $kalan)) { $hedefHarita[$x.n]++ }
}
foreach ($n in $tumKonu) {
  $c = [int]$cikmis[$n]
  $pc = [int]$pencereSay[$n]
  $d = $(if ($kopruDers.ContainsKey($n) -and $kopruDers[$n]) { $kopruDers[$n] } elseif ($dersKonu.ContainsKey($n)) { $dersKonu[$n] } else { '' })
  if ($Ders -and $d -notmatch $Ders) { continue }
  $hedef = $(if ($ToplamHedef -gt 0) {
      $(if ($hedefHarita.ContainsKey($n)) { [int]$hedefHarita[$n] } else { 0 })
    } else { $(if ($pc -le 0) { 0 } else { [Math]::Max(1, $c * $HedefKat) }) })
  $sonAd = $(if ($sonSira.ContainsKey($n)) { '{0}/{1}' -f [Math]::Floor($sonSira[$n] / 10), ($sonSira[$n] % 10) } else { '' })
  $yenilik = $(if (-not $sonSira.ContainsKey($n)) { 'OLCULMEDI' } elseif ($pc -gt 0) { 'YENI' } else { "ESKI (son $sonAd)" })
  $yay = [int]$yayin[$n]
  $acik = [Math]::Max(0, $hedef - $yay)
  $durum = $(if ($yay -ge $hedef) { 'YETER' } elseif ($yay -eq 0) { 'HIC YOK' } else { 'EKSIK' })
  $satir.Add([pscustomobject]@{
      ders = $d; konu = $(if ($kopruAd.ContainsKey($n)) { $kopruAd[$n] } else { $n })
      cikmis = $c; son10 = $pc; son_soruldu = $sonAd; yenilik = $yenilik
      yazdik = [int]$yazdik[$n]; yayinlanabilir = $yay
      hedef = $hedef; acik = $acik; durum = $durum
      engel = $(if ($engel.ContainsKey($n)) { $engel[$n] } else { '' })
    })
}

$csv = Join-Path $kok 'veri\fabrika\smmm-kapsama.csv'
$satir | Sort-Object @{e = { $_.ders } }, @{e = { $_.acik }; Descending = $true } | Export-Csv -NoTypeInformation -Encoding UTF8 $csv

if (-not $Sessiz) {
  $acikToplam = ($satir | Where-Object { -not $_.engel } | Measure-Object acik -Sum).Sum
  $engelliAcik = ($satir | Where-Object { $_.engel } | Measure-Object acik -Sum).Sum
  $kuralAd = $(if ($ToplamHedef -gt 0) { "hedef = SIKLIK AGIRLIKLI, banka toplami $ToplamHedef" } else { "hedef = cikmis x $HedefKat" })
  "SMMM KAPSAMA ($kuralAd) · parti dosyasi $partiSay"
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

# --- KOMMIT EDİLEBİLİR ÖZET (veri/fabrika gitignore'da; robot bunu yayınlar) ---
$fazlaTop = 0; foreach ($s in $satir) { $fazlaTop += [Math]::Max(0, [int]$s.yayinlanabilir - [int]$s.hedef) }
$hic = @($satir | Where-Object { [int]$_.yayinlanabilir -eq 0 -and [int]$_.hedef -gt 0 })
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# SMMM BİTİRME — KONU KAPSAMA')
$md.Add('')
$md.Add("> Türetilmiştir (``arac/smmm-kapsama-tablosu.ps1``), **elle düzenlenmez**. Ölçüm: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$md.Add("> Kural: " + $(if ($ToplamHedef -gt 0) { "hedef **sıklık ağırlıklı**, banka toplamı **$ToplamHedef**" } else { "hedef = çıkmış × $HedefKat" }))
$md.Add('> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`')
$md.Add('')
$md.Add('| | soru |')
$md.Add('|---|---:|')
$md.Add("| hedef | $(($satir | Measure-Object hedef -Sum).Sum) |")
$md.Add("| bugün yayınlanabilir | $(($satir | Measure-Object yayinlanabilir -Sum).Sum) |")
$md.Add("| **EKSİK (açık)** | **$(($satir | Measure-Object acik -Sum).Sum)** |")
$md.Add("| …bunun engellisi (kısır/kaynak borcu) | $(($satir | Where-Object { $_.engel } | Measure-Object acik -Sum).Sum) |")
$md.Add("| FAZLA yazdığımız (hedef üstü) | $fazlaTop |")
$md.Add("| hiç yazmadığımız konu | $($hic.Count) (hedefi $(($hic | Measure-Object hedef -Sum).Sum) soru) |")
$md.Add('')
$md.Add('## Ders ders')
$md.Add('')
$md.Add('| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|')
foreach ($g in ($satir | Where-Object { $_.ders -notmatch '/' } | Group-Object ders | Sort-Object { ($_.Group | Where-Object { -not $_.engel } | Measure-Object acik -Sum).Sum } -Descending)) {
  $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f $(if ($g.Name) { $g.Name } else { '(ders yok)' }), $g.Count,
      ($g.Group | Measure-Object cikmis -Sum).Sum, ($g.Group | Measure-Object yayinlanabilir -Sum).Sum,
      ($g.Group | Measure-Object hedef -Sum).Sum,
      (($g.Group | Where-Object { -not $_.engel } | Measure-Object acik -Sum).Sum),
      (($g.Group | Where-Object { $_.engel } | Measure-Object acik -Sum).Sum)))
}
$md.Add('')
$md.Add('## En çok çıkmış ama hiç yazmadığımız 25 konu')
$md.Add('')
$md.Add('| çıkmış | hedef | konu | ders | engel |')
$md.Add('|---:|---:|---|---|---|')
foreach ($x in ($hic | Sort-Object { [int]$_.cikmis } -Descending | Select-Object -First 25)) {
  $md.Add(("| {0} | {1} | {2} | {3} | {4} |" -f $x.cikmis, $x.hedef, ("$($x.konu)" -replace '\|', '/'), $x.ders, $x.engel))
}
$md.Add('')
$md.Add('## Bu tablo şunu GÖRMEZ')
$md.Add('')
$md.Add('- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.')
$md.Add('- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.')
$md.Add('- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.')
$md.Add('')
[IO.File]::WriteAllText((Join-Path $kok 'veri\SMMM-KAPSAMA.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
if (-not $Sessiz) { 'MD : veri/SMMM-KAPSAMA.md' }
