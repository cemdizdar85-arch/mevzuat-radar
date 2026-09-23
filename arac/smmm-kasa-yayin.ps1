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
param([switch]$Yaz, [switch]$IndirmeYok, [double]$IkizEsik = 0.60, [double]$IkizSikEsik = 0.60,
  # 18.09 (Cem "kasadaki soruları siteye bağla"): site kasa modu için sayfaların DEPODA kabuğa çevrilecek hâli gerekiyor.
  #   -SiteKabuk: sayfalar kaydir/smmm/<slug>.html'e kurulur, hemen ardından motor/kasa-kabuk.js --yaz ile SORUSUZ kabuğa
  #   çevrilir (eşdeğerlik kapısı: kasadaki satırlar sayfadaki SORULAR ile alan alan aynı olmalı) ve YALNIZ kabuk diskte kalır.
  #   Kabuk yazılamazsa (eşdeğerlik tutmazsa) sayfa SİLİNİR — depoda soru içeriği bırakılmaz.
  [switch]$SiteKabuk)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'smmm-yayin-sarti.ps1')

if (-not $IndirmeYok) {
  & powershell -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Indir -Yaz -OnEk 'smmm-' | Select-Object -Last 3
  if ($LASTEXITCODE) { throw "parti indirme düştü ($LASTEXITCODE)" }
}
$fabrika = Join-Path $depoKok 'veri\fabrika'
$onay = SmmmOnayHarita $depoKok

$ret = @{}
$retYol = Join-Path $depoKok 'veri\ret-kutugu.json'
if (Test-Path $retYol) { foreach ($rk in @((Get-Content $retYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar)) { $ret["$($rk.etiket)|$($rk.id)"] = "$($rk.kapi) $($rk.sinif)" } }
else { Write-Host '⚠ RET KÜTÜĞÜ yok (veri/ret-kutugu.json) — kapı uygulanamadı, yayın DURDU' -ForegroundColor Red; exit 1 }
# ⭐ 23.09.2026 ELLE RET: ret kütüğü yalnız üretim kapılarından beslenir; insanın OKUYARAK bulduğu kusurun (yanlış/iki
#   cevaplı soru) yolu yoktu. İlk vaka: site oturumu smmm-4k-a-yvergi-cokzor-r5/kp-01'de ithalat KDV matrahına müşavirlik
#   ücretini katan açıklama buldu (KDV m.21/c "vergilendirilmeyenler"), soru iki şıkta savunulabilir. Liste: kimlik →
#   {gerekce, kaynak, tarih}; soru metni YOK. Kalkması için kimlik listeden çıkarılır (soru yeniden yazılınca yeni kimlik alır).
$elleRetYol = Join-Path $depoKok 'veri\sinav\smmm-elle-ret.json'
if (Test-Path $elleRetYol) { foreach ($p in (Get-Content $elleRetYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar.PSObject.Properties) { $ret["$($p.Name)" -replace '/', '|'] = "ELLE $($p.Value.gerekce)" } }

# ⭐ 22.09.2026 — DERS EŞLEMESİ ARTIK ORTAK DOSYADA: arac/smmm-ders-adi.ps1
#   ÖLÇÜLDÜ: harita yalnız burada duruyordu ve dersini çözemediği partiyi sessizce "ders çözülemedi"
#   diye düşürüyordu. 439 parti etiketinin 5'i ('-vergi' / '-hukuk' yazımlı ölçüm ve A/B partileri)
#   çözülemiyordu → 187 taslak, bunların 58'i YAYIN ŞARTINI GEÇEN soru, ambara hiç girmedi.
#   Harita tek yerde tutulur, öz-sınavı vardır (arac/smmm-ders-adi-sinavi.ps1) ve öz-sınav yerel
#   parti etiketlerinin TAMAMINI tarayıp çözülemeyeni KÖR diye bildirir.
. (Join-Path $PSScriptRoot 'smmm-ders-adi.ps1')
function DersBul([string]$etiket, $v) { return (SmmmDersAdi $etiket $v) }
# ⭐ 22.09.2026 — İKİZ CETVELİ DE ORTAK DOSYADA: arac/ikiz-olcusu.ps1
#   ÖLÇÜLDÜ: üretici bu işi BAŞKA bir cetvelle yapıyordu (≥4 harfli kelime kümesi, yalnız soru
#   metni). Yayın cetvelinin ikiz saydığı 78 çiftte üretim cetvelinin değeri 0,33'e kadar
#   iniyordu; ambara girmeyen 107 sorunun 47'sinin ikizi vardı ve bunların 24'ünü üretim
#   cetveli KAÇIRMIŞTI — yani soru yazıldı, hakemden geçti, parası ödendi, sonra burada elendi.
#   Cetvel artık tek dosyada; öz-sınavı var: arac/ikiz-olcusu-sinavi.ps1
. (Join-Path $PSScriptRoot 'ikiz-olcusu.ps1')
function Katla([string]$s) { return (IkizKatla $s) }
function Ucluler([string]$t) { return (IkizUcluler $t) }
function Benzerlik($ax, $bx) { return (IkizBenzerlik $ax $bx) }

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
$siteSayfa = New-Object System.Collections.Generic.List[object]   # 18.09 -SiteKabuk: depodaki kaydir/smmm sayfaları (kabuğa çevrilecek)
try {
  foreach ($g in @($secim | Group-Object ders | Sort-Object Name)) {
    $slug = SmmmDersSlug $g.Name
    $secYol = Join-Path $calisma "secim-$slug.json"
    [IO.File]::WriteAllText($secYol, (ConvertTo-Json -InputObject @($g.Group | Sort-Object etiket, id | ForEach-Object { [ordered]@{ etiket = $_.etiket; id = $_.id; ders = $_.ders; konu = $_.konu; donem = $_.donem } }) -Depth 3), [Text.UTF8Encoding]::new($false))
    $cikti = "smmm-kasa\sayfa-$slug.html"
    $log = & powershell -NoProfile -File (Join-Path $depoKok 'motor\kaydir-coz.ps1') -SecimDosya $secYol -Cikti $cikti 2>&1
    $kod = $LASTEXITCODE
    $sonKapi = @($log | Where-Object { "$_" -match 'SON KAPI RED' }).Count
    $sayfa = Join-Path $depoKok "sql-yerel\$cikti"
    if ($SiteKabuk -and (Test-Path $sayfa)) {
      # sayfa depodaki site yoluna TAŞINIR; kabuğa çevrilene kadar soru içeriği burada durur, çevrilmezse silinir (aşağıdaki finally)
      $siteYol = Join-Path $depoKok "kaydir\smmm\$slug.html"
      New-Item -ItemType Directory -Force (Split-Path $siteYol -Parent) | Out-Null
      Copy-Item -LiteralPath $sayfa -Destination $siteYol -Force
      $siteSayfa.Add(@{ yol = $siteYol; sayfa = "kaydir/smmm/$slug.html" })
    }
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
  # 18.09 -SiteKabuk: kasa modu listesine ekle + sayfaları SORUSUZ kabuğa çevir (motor/kasa-kabuk.js eşdeğerlik kapısı)
  if ($SiteKabuk -and $siteSayfa.Count) {
    $kmYol = Join-Path $depoKok 'arac\kasa-modu.json'
    $km = Get-Content $kmYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $liste = New-Object System.Collections.Generic.List[string]; foreach ($s in @($km.sayfalar)) { $liste.Add("$s") }
    foreach ($s in $siteSayfa) { if (-not $liste.Contains($s.sayfa)) { $liste.Add($s.sayfa) } }
    $km.sayfalar = [string[]]$liste.ToArray()
    [IO.File]::WriteAllText($kmYol, (ConvertTo-Json -InputObject $km -Depth 4), [Text.UTF8Encoding]::new($false))
    "kasa modu listesi: $($liste.Count) sayfa"
    & node (Join-Path $depoKok 'motor\kasa-kabuk.js') --yaz
    $kodK = $LASTEXITCODE
    if ($kodK) { throw "KABUK YAZILAMADI (çıkış $kodK) — depoya soru içeriği bırakılmıyor, sayfalar silinecek" }
    foreach ($s in $siteSayfa) {
      $ham = [IO.File]::ReadAllText($s.yol, [Text.Encoding]::UTF8)
      if ($ham -notmatch 'data-kasa-sayfa=' -or $ham.Length -gt 400000) { throw "KABUK DOĞRULANAMADI: $($s.sayfa) (işaret yok ya da $([math]::Round($ham.Length/1024)) KB fazla büyük)" }
      "  kabuk hazır: $($s.sayfa) · $([math]::Round($ham.Length/1024)) KB"
    }
    $siteSayfa.Clear()   # kabuk doğrulandı: bu dosyalar SİLİNMEZ, depoda kalır
  }
} finally {
  foreach ($s in $siteSayfa) { if (Test-Path $s.yol) { Remove-Item -LiteralPath $s.yol -Force; "  ⚠ kabuğa çevrilemeyen sayfa silindi: $($s.sayfa)" } }
  foreach ($d in $yazilanDosya) { if (Test-Path $d) { Remove-Item -LiteralPath $d -Force } }
  'çalışma dosyaları silindi (soru içeriği diskte bırakılmadı)'
}
