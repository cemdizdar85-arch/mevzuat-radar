#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) → KİLİTLİ KASA YAYINI   16.09.2026  (bedel 0, model yok)
#
#  Cem 16.09: "bu bastığımız soruları kilitli yere alacaksın direkt" + "SGS'nin yapıp bizim atladığımız bir şey varsa
#  basmadan onları yapalım". SGS yayın yolu (arac/sgs-650-bas.ps1 → kaydir/sgs/*.html → motor/kasa-soru-yukle.js) açık
#  depoya sayfa yazıyor; bitirmede bu adım HİÇ YOK: sorular açık depoya/kaydir klasörüne girmez, doğrudan paket_soru'ya.
#
#  SIRA
#   1) Ambardaki bütün SMMM partileri veri/fabrika'ya iner (arac/parti-senkron.ps1 -Indir; veri/fabrika gitignore).
#   2) SEÇİM — SGS yayınının bütün süzgeçleri + bitirme şartı:
#      · pilot partiler girmez · yayın şartı arac/smmm-yayin-sarti.ps1 (hakem EVET, ders/konu/tek anlam, HESAP-YANLIS, KAPI-KH,
#        doğru şık açıklaması, simülasyon koşmuş ve doğru, kör çözüm doğru ya da Cem onaylı istisna, hakem2 EVET)
#      · RET KÜTÜĞÜ (veri/ret-kutugu.json) · KAPI-IK İKİZ: aynı DERS içinde soru metni VE doğru şık metni ≥%60 benzer
#        (arac/ikiz-soru.ps1 ile aynı ölçü: üçlü-harf Jaccard, rakam korunur); ciftte uzun olan kalır.
#   3) Ders ders Kaydır-Çöz sayfası motor/kaydir-coz.ps1 ile sql-yerel/ (gitignore) altına kurulur; kaydir-coz SMMM
#      sorusunu yayın şartından BİR KEZ DAHA geçirir (son kapı).
#   4) motor/kasa-smmm-yukle.js sayfaları okur → paket_soru (sinav='smmm', sayfa='kaydir/smmm/<slug>.html'). -Yaz yoksa KURU.
#   5) Kurulan sayfa dosyaları silinir (içerik diskte kalmaz). Seçim listesi yalnız kimlik taşır.
#  EKRAN: soru metni basılmaz (bulutta günlük herkese açık) — yalnız sayı.
#  KULLANIM: powershell -NoProfile -File arac/smmm-kasa-yayin.ps1 [-Yaz] [-IndirmeYok]
# ============================================================================
param([switch]$Yaz, [switch]$IndirmeYok, [double]$IkizEsik = 0.60, [double]$IkizSikEsik = 0.60)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'smmm-yayin-sarti.ps1')

if (-not $IndirmeYok) {
  & powershell -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Indir -Sinav SMMM | Select-Object -Last 3
  if ($LASTEXITCODE) { throw "parti indirme düştü ($LASTEXITCODE)" }
}
$fabrika = Join-Path $depoKok 'veri\fabrika'
$onay = SmmmOnayHarita $depoKok

$ret = @{}
$retYol = Join-Path $depoKok 'veri\ret-kutugu.json'
if (Test-Path $retYol) { foreach ($rk in @((Get-Content $retYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar)) { $ret["$($rk.etiket)|$($rk.id)"] = "$($rk.kapi) $($rk.sinif)" } }
else { Write-Host '⚠ RET KÜTÜĞÜ yok (veri/ret-kutugu.json) — kapı uygulanamadı, yayın DURDU' -ForegroundColor Red; exit 1 }

# ders adı: etiketteki kısaltmadan (plan kurucunun kısaltmaları) ekran adına
$DERS_KISA = [ordered]@{ 'ymeslek' = 'Meslek Hukuku'; 'fmuh' = 'Finansal Muhasebe'; 'yfta' = 'Finansal Tablolar ve Analizi'; 'maliyet' = 'Maliyet Muhasebesi'; 'ydenetim' = 'Muhasebe Denetimi'; 'yspk' = 'Sermaye Piyasası Mevzuatı'; 'yvergi' = 'Vergi Mevzuatı ve Uygulaması'; 'yhukuk' = 'Hukuk' }
$DERS_SLUG = @{ 'Meslek Hukuku' = 'meslek-hukuku'; 'Finansal Muhasebe' = 'finansal-muhasebe'; 'Finansal Tablolar ve Analizi' = 'finansal-tablolar'; 'Maliyet Muhasebesi' = 'maliyet-muhasebesi'; 'Muhasebe Denetimi' = 'muhasebe-denetimi'; 'Sermaye Piyasası Mevzuatı' = 'sermaye-piyasasi'; 'Vergi Mevzuatı ve Uygulaması' = 'vergi'; 'Hukuk' = 'hukuk' }
# eski adlı partiler (ölçüldü 16.09: parti içinde ders alanı BOŞ): boşluk partileri ders adını bitişik yazar, GM partileri kısa ad kullanır
$DERS_ESKI = [ordered]@{ 'smmm-bosluk-finansalmuhasebe' = 'Finansal Muhasebe'; 'smmm-bosluk-hukuk' = 'Hukuk'; 'smmm-bosluk-muhasebedenetimi' = 'Muhasebe Denetimi'; 'smmm-bosluk-sermayepiyasas' = 'Sermaye Piyasası Mevzuatı'; 'smmm-bosluk-vergimevzuat' = 'Vergi Mevzuatı ve Uygulaması'; 'smmm-bosluk-muhasebecilik' = 'Meslek Hukuku'; 'smmm-bosluk-finansaltablo' = 'Finansal Tablolar ve Analizi'; 'smmm-bosluk-maliyet' = 'Maliyet Muhasebesi'; 'smmm-denetim-' = 'Muhasebe Denetimi'; 'smmm-gm-p2-fta' = 'Finansal Tablolar ve Analizi'; 'smmm-gm-p2-vergi' = 'Vergi Mevzuatı ve Uygulaması'; 'smmm-gm-p2-maliyet' = 'Maliyet Muhasebesi' }
function DersBul([string]$etiket, $v) {
  foreach ($k in $DERS_KISA.Keys) { if ($etiket -match "(^|-)$k(-|$)") { return $DERS_KISA[$k] } }
  foreach ($k in $DERS_ESKI.Keys) { if ($etiket.StartsWith($k)) { return $DERS_ESKI[$k] } }
  $h = "$($v.ders)"
  foreach ($d in $DERS_KISA.Values) { if ($h -and ($h -like "$($d.Split(' ')[0])*")) { return $d } }
  return ''
}
function Katla([string]$s) {
  $x = "$s".ToLowerInvariant(); foreach ($c in @(@('ç', 'c'), @('ğ', 'g'), @('ı', 'i'), @('İ', 'i'), @('ö', 'o'), @('ş', 's'), @('ü', 'u'))) { $x = $x.Replace($c[0], $c[1]) }
  $x = $x.Replace('²', '2').Replace('³', '3').Replace('¹', '1'); return ((($x -replace '[^a-z0-9]', ' ') -replace '\s+', ' ').Trim())
}
function Ucluler([string]$t) { $k = ($t -replace ' ', ''); $h = New-Object 'System.Collections.Generic.HashSet[string]'; for ($i = 0; $i -le $k.Length - 3; $i++) { [void]$h.Add($k.Substring($i, 3)) }; return , $h }
function Benzerlik($ax, $bx) { if ($ax.Count -eq 0 -or $bx.Count -eq 0) { return 0.0 }; $n = 0; foreach ($u in $ax) { if ($bx.Contains($u)) { $n++ } }; $b = $ax.Count + $bx.Count - $n; if ($b -le 0) { return 0.0 }; return $n / [double]$b }

$aday = New-Object System.Collections.Generic.List[object]
$dusen = @{}
foreach ($f in @(Get-ChildItem $fabrika -Filter 'kalip-parti-smmm-*.json')) {
  $et = $f.BaseName -replace '^kalip-parti-', ''
  if ($et -match '(^|-)pilot\d*(-|$)') { continue }
  $c = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($p in $c.PSObject.Properties) {
    $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $anah = "$et|$($p.Name)"
    $sart = SmmmYayinSarti "$et/$($p.Name)" $v $onay
    if (-not $sart.gecer) { $dusen['yayın şartı'] = 1 + [int]$dusen['yayın şartı']; continue }
    if ($ret.ContainsKey($anah)) { $dusen['ret kütüğü'] = 1 + [int]$dusen['ret kütüğü']; continue }
    $ders = DersBul $et $v
    if (-not $ders) { $dusen['ders çözülemedi'] = 1 + [int]$dusen['ders çözülemedi']; continue }
    $aday.Add([pscustomobject]@{ etiket = $et; id = $p.Name; ders = $ders; konu = "$($v.konu)"; donem = [int]$v.donem; boy = "$($v.soru)".Length
        uc = (Ucluler (Katla "$($v.soru)")); ucD = (Ucluler (Katla "$($v.siklar.$("$($v.dogru)".Trim().ToUpperInvariant()))")) })
  }
}
# KAPI-IK (ders içinde, iki ölçüt)
$ikizDisi = @{}
foreach ($g in @($aday | Group-Object ders)) {
  $l = @($g.Group | Sort-Object @{ e = { $_.boy }; Descending = $true }, etiket, id)   # uzun olan önce → kalan
  for ($i = 0; $i -lt $l.Count; $i++) {
    if ($ikizDisi.ContainsKey("$($l[$i].etiket)|$($l[$i].id)")) { continue }
    for ($j = $i + 1; $j -lt $l.Count; $j++) {
      $kj = "$($l[$j].etiket)|$($l[$j].id)"; if ($ikizDisi.ContainsKey($kj)) { continue }
      if ((Benzerlik $l[$i].uc $l[$j].uc) -lt $IkizEsik) { continue }
      if ((Benzerlik $l[$i].ucD $l[$j].ucD) -ge $IkizSikEsik) { $ikizDisi[$kj] = "$($l[$i].etiket)|$($l[$i].id)" }
    }
  }
}
$secim = @($aday | Where-Object { -not $ikizDisi.ContainsKey("$($_.etiket)|$($_.id)") })
if ($ikizDisi.Count) { $dusen['KAPI-IK ikiz'] = $ikizDisi.Count }
"SMMM KASA SEÇİMİ: aday $($aday.Count) · seçilen $($secim.Count) · düşen: $(($dusen.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ' · ')"
if (-not $secim.Count) { 'seçilen soru yok — kasaya yazılacak bir şey yok'; exit 0 }

# sayfalar (depo dışı klasör: sql-yerel gitignore'da)
$calisma = Join-Path $depoKok 'sql-yerel\smmm-kasa'
New-Item -ItemType Directory -Force $calisma | Out-Null
$nodeArg = New-Object System.Collections.Generic.List[string]
$yazilanDosya = New-Object System.Collections.Generic.List[string]
try {
  foreach ($g in @($secim | Group-Object ders | Sort-Object Name)) {
    $slug = $DERS_SLUG[$g.Name]
    $secYol = Join-Path $calisma "secim-$slug.json"
    [IO.File]::WriteAllText($secYol, (ConvertTo-Json -InputObject @($g.Group | Sort-Object etiket, id | ForEach-Object { [ordered]@{ etiket = $_.etiket; id = $_.id; ders = $_.ders; konu = $_.konu; donem = $_.donem } }) -Depth 3), [Text.UTF8Encoding]::new($false))
    $cikti = "smmm-kasa\sayfa-$slug.html"
    $log = & powershell -NoProfile -File (Join-Path $depoKok 'motor\kaydir-coz.ps1') -SecimDosya $secYol -Cikti $cikti 2>&1
    $kod = $LASTEXITCODE
    $sonKapi = @($log | Where-Object { "$_" -match 'SON KAPI RED' }).Count
    $sayfa = Join-Path $depoKok "sql-yerel\$cikti"
    if ($kod -or -not (Test-Path $sayfa)) { throw "sayfa kurulamadı: $($g.Name) (çıkış $kod)" }
    $yazilanDosya.Add($sayfa); $yazilanDosya.Add($secYol)
    $yazilanDosya.Add("C:\TETIKTE-YEDEK\kaydir-coz-$(Get-Date -Format yyyyMMdd)\sayfa-$slug.html")   # kaydir-coz'un yerel yedek kopyası (bulutta yok)
    "  $($g.Name): seçilen $($g.Count) · son kapıda düşen $sonKapi"
    $nodeArg.Add('--dosya'); $nodeArg.Add($sayfa); $nodeArg.Add('--sayfa'); $nodeArg.Add("kaydir/smmm/$slug.html")
  }
  if ($Yaz) { $nodeArg.Add('--yaz') }
  & node (Join-Path $depoKok 'motor\kasa-smmm-yukle.js') @($nodeArg.ToArray())
  $kodN = $LASTEXITCODE
  if ($kodN -eq 3) { 'KASA TABLOSU YOK — yazılmadı (radar-app/sql/2026-09-16-paket-soru.sql basılınca yeniden koş)' }
  elseif ($kodN) { throw "kasa yükleyici düştü ($kodN)" }
} finally {
  foreach ($d in $yazilanDosya) { if (Test-Path $d) { Remove-Item -LiteralPath $d -Force } }
  'çalışma dosyaları silindi (soru içeriği diskte bırakılmadı)'
}
