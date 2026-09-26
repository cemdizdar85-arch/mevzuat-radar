#requires -Version 5.1
# ============================================================================
#  KGK (BAĞIMSIZ DENETÇİLİK) → KİLİTLİ KASA YAYINI   27.09.2026  (bedel 0, model yok)
#
#  Cem: "SGS ve SMMM'deki bütün kurallar KGK'da da olacak (kaydırmalı Nöbetçi çözüm sayfası, sadelik, formül/hesap kontrolü,
#  eski mevzuatla soru yok, ikiz kapısı, ret kütüğü, elle ret…)". 27.09: "bu oturum YALNIZ KGK" → bitirme yolunun
#  (arac/smmm-kasa-yayin.ps1) KGK eşi AYRI dosya; ortak araçlar DEĞİŞTİRİLMEDEN çağrılır:
#    arac/kgk-yayin-sarti.ps1 (→ arac/smmm-yayin-sarti.ps1 SmmmYayinSarti, birebir) · arac/kgk-ders-adi.ps1 ·
#    arac/ikiz-olcusu.ps1 · motor/kaydir-coz.ps1 (sayfa) · motor/kgk-kasa-yukle.js (→ motor/kasa-soru-yukle.js) ·
#    motor/kasa-kabuk.js + arac/kasa-modu.json (-SiteKabuk).
#
#  SIRA
#   1) Ambardaki kgk-* partileri veri/fabrika'ya iner (arac/parti-senkron.ps1 -Indir -OnEk 'kgk-'; -IndirmeYok ile atlanır).
#   2) SEÇİM: pilot ve ESKİ HAT (kgk-bosluk-*, kgk-kurfin-30, kgk-muhstd-20) girmez · bulutta KOŞAN parti atlanır (yarım iş
#      yayına çıkmaz) · YAYIN ŞARTI (arac/kgk-yayin-sarti.ps1) · RET KÜTÜĞÜ (veri/ret-kutugu.json) · ELLE RET
#      (veri/sinav/kgk-elle-ret.json) · ders çözülemeyen düşer · KAPI-IK İKİZ modül içinde (soru VE doğru şık ≥%60, arac/ikiz-olcusu.ps1)
#      + ANLAMCA İKİZ (aynı modül+konu+ilk kaynak).
#   3) Modül modül Kaydır-Çöz sayfası motor/kaydir-coz.ps1 ile sql-yerel/ (gitignore) altına kurulur.
#      SON KAPI (KGK): kaydir-coz yayın şartını yalnız smmm-* etiketinde yeniden koşar (27.09 okundu, satır 35) — o yüzden
#      burada sayfa KURULDUKTAN SONRA sayfadaki her kimliğin bu koşuda yayın şartını geçmiş seçimde olduğu denetlenir;
#      tek yabancı kimlik → DUR. (kaydir-coz'a kgk-* dalı eklenmesi SMMM/SGS oturumuna iletilecek not.)
#   4) motor/kgk-kasa-yukle.js sayfaları okur → paket_soru (sinav='kgk', sayfa='kaydir/kgk/<slug>.html'). -Yaz yoksa KURU.
#   5) Kurulan sayfa dosyaları silinir (içerik diskte kalmaz). Seçim listesi yalnız kimlik taşır.
#  EKRAN: soru metni basılmaz (bulutta günlük herkese açık) — yalnız sayı.
#  KULLANIM: powershell -NoProfile -File arac/kgk-kasa-yayin.ps1 [-Yaz] [-IndirmeYok] [-SiteKabuk]
#  🚫 GÖRMEZ: yayın şartının görmediklerini (arac/smmm-yayin-sarti.ps1 başlığı) · KGK cevap dağılımı (çırçır) — KGK'da kapı yok ·
#     bulut koşu adı plan taşımıyorsa o işin partileri bilinmez (uyarı basılır; -Yaz'da DURUR).
# ============================================================================
param([switch]$Yaz, [switch]$IndirmeYok, [double]$IkizEsik = 0.60, [double]$IkizSikEsik = 0.60, [switch]$AnlamIkizYok,
  # -SiteKabuk: sayfalar kaydir/kgk/<slug>.html'e kurulur, motor/kasa-kabuk.js --yaz ile SORUSUZ kabuğa çevrilir
  #   (eşdeğerlik kapısı) ve YALNIZ kabuk diskte kalır. Kabuk yazılamazsa sayfa SİLİNİR. (Site kolu işi — Cem kararıyla koşulur.)
  [switch]$SiteKabuk)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'kgk-yayin-sarti.ps1')
. (Join-Path $PSScriptRoot 'kgk-ders-adi.ps1')
. (Join-Path $PSScriptRoot 'ikiz-olcusu.ps1')

if (-not $IndirmeYok) {
  & powershell -NoProfile -File (Join-Path $PSScriptRoot 'parti-senkron.ps1') -Indir -Yaz -OnEk 'kgk-' | Select-Object -Last 3
  if ($LASTEXITCODE) { throw "parti indirme düştü ($LASTEXITCODE)" }
}
$fabrika = Join-Path $depoKok 'veri\fabrika'
$onay = KgkOnayHarita $depoKok

# bulutta koşan partiler: bulut işi partiyi sonunda TOPTAN yükler; yarım partiyi yayınlamak onay/ret dengesini bozar → atlanır
$kosanEtiket = @{}
try { foreach ($ke in @(& (Join-Path $PSScriptRoot 'bulut-kosan-etiketler.ps1'))) { if ("$ke") { $kosanEtiket["$ke"] = 1 } } }
catch { if ($Yaz) { throw "bulutta koşan partiler okunamadı ($($_.Exception.Message)) — yazma durdu" }; Write-Host "⚠ bulutta koşan partiler okunamadı — kuru koşuda bu süzgeç KÖR" -ForegroundColor Yellow }

$ret = @{}
$retYol = Join-Path $depoKok 'veri\ret-kutugu.json'
if (Test-Path $retYol) { foreach ($rk in @((Get-Content $retYol -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar)) { $ret["$($rk.etiket)|$($rk.id)"] = "$($rk.kapi) $($rk.sinif)" } }
else { Write-Host '⚠ RET KÜTÜĞÜ yok (veri/ret-kutugu.json) — kapı uygulanamadı, yayın DURDU' -ForegroundColor Red; exit 1 }
# ELLE RET (SMMM smmm-elle-ret.json'un eşi): kimlik → {gerekce,…}; soru metni YOK. Dosya bozuksa DUR.
$elleRetYol = Join-Path $depoKok 'veri\sinav\kgk-elle-ret.json'
if (Test-Path $elleRetYol) {
  $elleRetDosyasi = Get-Content $elleRetYol -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($null -eq $elleRetDosyasi.PSObject.Properties['kayitlar']) { throw "KAPI-ELLE: $elleRetYol 'kayitlar' alanı yok — yayın durdu" }
  foreach ($p in $elleRetDosyasi.kayitlar.PSObject.Properties) { $ret["$($p.Name)" -replace '/', '|'] = "ELLE $($p.Value.gerekce)" }
}

$aday = New-Object System.Collections.Generic.List[object]
$dusen = @{}
function DusenSay([string]$neden, [int]$adet = 1) { $script:dusen[$neden] = $adet + [int]$script:dusen[$neden] }
$sartNeden = @{}   # yayın şartı düşüş nedenleri (ayrıntı; soru metni yok)
foreach ($f in @(Get-ChildItem $fabrika -Filter 'kalip-parti-kgk-*.json')) {
  $et = $f.BaseName -replace '^kalip-parti-', ''
  if ($et -match '(^|-)pilot\d*(-|$)') { continue }
  $c = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  $soruAdet = @($c.PSObject.Properties | Where-Object { $_.Value -and $_.Value.PSObject.Properties['soru'] -and $_.Value.soru }).Count
  if ($et -match $script:KGK_ESKI_HAT) { if ($soruAdet) { DusenSay 'eski hat (yayına girmez)' $soruAdet }; continue }
  if ($kosanEtiket.ContainsKey($et)) { if ($soruAdet) { DusenSay 'bulutta koşuyor (atlandı)' $soruAdet }; continue }
  foreach ($p in $c.PSObject.Properties) {
    $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }
    $anah = "$et|$($p.Name)"
    $sart = KgkYayinSarti "$et/$($p.Name)" $v $onay
    if (-not $sart.gecer) { DusenSay 'yayın şartı'; $kisa = ("$($sart.neden)" -replace ':.*$', ''); $sartNeden[$kisa] = 1 + [int]$sartNeden[$kisa]; continue }
    $korOnay = ("$($ret[$anah])" -like 'KAPI-KOR*' -and "$($sart.neden)" -match 'Cem onay')
    if ($ret.ContainsKey($anah) -and -not $korOnay) { DusenSay $(if ("$($ret[$anah])" -like 'ELLE*') { 'elle ret' } else { 'ret kütüğü' }); continue }
    if ($korOnay) { DusenSay '(bilgi) Cem onayıyla KAPI-KOR aşıldı' }
    $ders = KgkDersAdi $et $v
    if (-not $ders) { DusenSay 'ders çözülemedi'; continue }
    $aday.Add([pscustomobject]@{ etiket = $et; id = $p.Name; ders = $ders; konu = "$($v.konu)"; donem = [int]$v.donem; boy = "$($v.soru)".Length
        uc = (IkizUcluler (IkizKatla "$($v.soru)")); ucD = (IkizUcluler (IkizKatla (IkizDogruMetin $v)))
        ai = (IkizAnlamIz (IkizAnlamGrup $ders "$($v.konu)" $v.kaynak_adlar) "$($v.soru)" (IkizDogruMetin $v)) })
  }
}
# KAPI-IK (modül içinde, iki ölçüt + anlamca ikiz) — arac/smmm-kasa-yayin.ps1 ile aynı sıra: uzun olan kalır
$ikizDisi = @{}; $anlamIkiz = @{}
foreach ($g in @($aday | Group-Object ders)) {
  $l = @($g.Group | Sort-Object @{ e = { $_.boy }; Descending = $true }, etiket, id)
  for ($i = 0; $i -lt $l.Count; $i++) {
    if ($ikizDisi.ContainsKey("$($l[$i].etiket)|$($l[$i].id)")) { continue }
    for ($j = $i + 1; $j -lt $l.Count; $j++) {
      $kj = "$($l[$j].etiket)|$($l[$j].id)"; if ($ikizDisi.ContainsKey($kj)) { continue }
      $klasik = ((IkizBenzerlik $l[$i].uc $l[$j].uc) -ge $IkizEsik) -and ((IkizBenzerlik $l[$i].ucD $l[$j].ucD) -ge $IkizSikEsik)
      if ($klasik) { $ikizDisi[$kj] = "$($l[$i].etiket)|$($l[$i].id)"; continue }
      if (-not $AnlamIkizYok -and (IkizAnlamMi $l[$i].ai $l[$j].ai)) { $ikizDisi[$kj] = "$($l[$i].etiket)|$($l[$i].id)"; $anlamIkiz[$kj] = 1 }
    }
  }
}
$secim = @($aday | Where-Object { -not $ikizDisi.ContainsKey("$($_.etiket)|$($_.id)") })
if ($ikizDisi.Count - $anlamIkiz.Count) { $dusen['KAPI-IK ikiz'] = $ikizDisi.Count - $anlamIkiz.Count }; if ($anlamIkiz.Count) { $dusen['KAPI-IK anlam ikiz'] = $anlamIkiz.Count }
"KGK KASA SEÇİMİ: aday $($aday.Count) · seçilen $($secim.Count) · düşen: $(($dusen.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ' · ')"
if ($sartNeden.Count) { "  yayın şartı nedenleri: $(($sartNeden.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ' · ')" }
"  modül: $((@($secim | Group-Object ders | Sort-Object Count -Descending) | ForEach-Object { "$($_.Name) $($_.Count)" }) -join ' · ')"
# ONAY YAYIN KAPISI (SMMM'nin eşi): onaylı KGK sorusu yayında değilse nedeni söylenir; beklenmedikse sonda çıkış 1
$secimAn = @{}; foreach ($s in $secim) { $secimAn["$($s.etiket)|$($s.id)"] = 1 }
$adayAn = @{}; foreach ($s in $aday) { $adayAn["$($s.etiket)|$($s.id)"] = 1 }
$onayDurum = @{}; $script:onayKirmizi = New-Object System.Collections.Generic.List[string]
foreach ($ok in @($onay.Keys)) {
  if ("$($onay[$ok].karar)" -ne 'ONAY') { continue }
  $k = "$ok" -replace '/', '|'
  $durum = $(if ($secimAn.ContainsKey($k)) { 'yayında' } elseif ($ikizDisi.ContainsKey($k)) { 'ikiz' } elseif ("$($ret[$k])" -like 'ELLE*') { 'elle ret' } elseif ($ret.ContainsKey($k)) { 'ONAYA RAĞMEN RET KÜTÜĞÜ' } elseif (-not $adayAn.ContainsKey($k)) { 'yayın şartı' } else { 'BİLİNMİYOR' })
  $onayDurum[$durum] = 1 + [int]$onayDurum[$durum]
  if ($durum -in 'ONAYA RAĞMEN RET KÜTÜĞÜ', 'BİLİNMİYOR') { $script:onayKirmizi.Add("$ok ($durum)") }
}
"ONAY YAYIN KAPISI: " + $(if ($onayDurum.Count) { ($onayDurum.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ' · ' } else { 'onay kaydı yok (veri/sinav/kgk-insan-onay.json yok → kör istisnası kapalı)' })
if ($script:onayKirmizi.Count) { Write-Host ("⛔ ONAY YAYIN KAPISI KIRMIZI: {0} onaylı soru beklenmedik biçimde yayında değil: {1}" -f $script:onayKirmizi.Count, (@($script:onayKirmizi | Select-Object -First 5) -join ', ')) -ForegroundColor Red }
if (-not $secim.Count) { 'seçilen soru yok — kasaya yazılacak bir şey yok'; exit 0 }

# sayfalar (depo dışı klasör: sql-yerel gitignore'da)
$calisma = Join-Path $depoKok 'sql-yerel\kgk-kasa'
New-Item -ItemType Directory -Force $calisma | Out-Null
$nodeArg = New-Object System.Collections.Generic.List[string]
$yazilanDosya = New-Object System.Collections.Generic.List[string]
$siteSayfa = New-Object System.Collections.Generic.List[object]
$kimlikOkuyucu = Join-Path $calisma 'kimlik-oku.js'   # sayfadaki SORULAR kimliklerini (yalnız kimlik) döker
[IO.File]::WriteAllText($kimlikOkuyucu, "const {sorulariCek}=require(process.argv[2]);const fs=require('fs');for(const q of sorulariCek(fs.readFileSync(process.argv[3],'utf8')))console.log(String(q.id||''));", [Text.UTF8Encoding]::new($false))
$yazilanDosya.Add($kimlikOkuyucu)
try {
  foreach ($g in @($secim | Group-Object ders | Sort-Object Name)) {
    $slug = KgkDersSlug $g.Name
    if (-not $slug) { throw "modülün sayfa adı (slug) yok: $($g.Name) — arac/kgk-ders-adi.ps1 haritasına satır ekle" }
    $secYol = Join-Path $calisma "secim-kgk-$slug.json"
    [IO.File]::WriteAllText($secYol, (ConvertTo-Json -InputObject @($g.Group | Sort-Object etiket, id | ForEach-Object { [ordered]@{ etiket = $_.etiket; id = $_.id; ders = $_.ders; konu = $_.konu; donem = $_.donem } }) -Depth 3), [Text.UTF8Encoding]::new($false))
    $cikti = "kgk-kasa\sayfa-kgk-$slug.html"
    $sayfa = Join-Path $depoKok "sql-yerel\$cikti"
    $yazilanDosya.Add($sayfa); $yazilanDosya.Add($secYol)   # çağrıdan ÖNCE: kaydir-coz düşse de finally siler
    # ⚠ 27.09 ilk kuru koşuda ölçüldü: kaydir-coz'un zararsız stderr satırı (başka oturumun sildiği bir parti dosyası, satır 78
    #   Get-ChildItem → Get-Content yarışı) EAP=Stop + 2>&1 altında BU betiği öldürdü. Çağrı süresince Continue; sonuç çıkış
    #   koduyla ve sayfanın varlığıyla denetlenir (aşağıda).
    $eapOnceki = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $log = & powershell -NoProfile -File (Join-Path $depoKok 'motor\kaydir-coz.ps1') -SecimDosya $secYol -Cikti $cikti 2>&1; $kod = $LASTEXITCODE }
    finally { $ErrorActionPreference = $eapOnceki }
    $stderrSatir = @($log | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }).Count
    if ($stderrSatir) { "  not: kaydir-coz $stderrSatir stderr satırı bastı (çıkış $kod) — içerik ekrana basılmadı" }
    $yazilanDosya.Add("C:\TETIKTE-YEDEK\kaydir-coz-$(Get-Date -Format yyyyMMdd)\sayfa-kgk-$slug.html")   # kaydir-coz'un yerel yedek kopyası
    if ($kod -or -not (Test-Path $sayfa)) { throw "sayfa kurulamadı: $($g.Name) (çıkış $kod)" }
    # SON KAPI (KGK): sayfadaki her kimlik bu koşunun seçiminde olmalı (yayın şartı + ret + ikiz geçmiş)
    $sayfaKimlik = @(& node $kimlikOkuyucu (Join-Path $depoKok 'motor\kasa-soru-yukle.js') $sayfa)
    if ($LASTEXITCODE) { throw "SON KAPI: sayfa kimlikleri okunamadı: $($g.Name)" }
    $yabanci = @($sayfaKimlik | Where-Object { -not $secimAn.ContainsKey(("$_" -replace '/', '|')) })
    if ($yabanci.Count) { throw "SON KAPI RED: $($g.Name) sayfasında seçim dışı $($yabanci.Count) kimlik (ilk: $($yabanci[0])) — yükleme durdu" }
    $eksik = $g.Count - $sayfaKimlik.Count
    "  $($g.Name): seçilen $($g.Count) · sayfada $($sayfaKimlik.Count)$(if ($eksik) { " · sayfaya girmeyen $eksik (kaydir-coz: parti dosyasında YOK)" })"
    if ($SiteKabuk) {
      $siteYol = Join-Path $depoKok "kaydir\kgk\$slug.html"
      New-Item -ItemType Directory -Force (Split-Path $siteYol -Parent) | Out-Null
      Copy-Item -LiteralPath $sayfa -Destination $siteYol -Force
      $siteSayfa.Add(@{ yol = $siteYol; sayfa = "kaydir/kgk/$slug.html" })
    }
    $nodeArg.Add('--dosya'); $nodeArg.Add($sayfa); $nodeArg.Add('--sayfa'); $nodeArg.Add("kaydir/kgk/$slug.html")
  }
  if ($Yaz) { $nodeArg.Add('--yaz') }
  & node (Join-Path $depoKok 'motor\kgk-kasa-yukle.js') @($nodeArg.ToArray())
  $kodN = $LASTEXITCODE
  if ($kodN -eq 3) { 'KASA TABLOSU YOK — yazılmadı (radar-app/sql/2026-09-16-paket-soru.sql basılınca yeniden koş)' }
  elseif ($kodN) { throw "kasa yükleyici düştü ($kodN)" }
  if ($SiteKabuk -and $siteSayfa.Count) {
    if (-not $Yaz) { throw '-SiteKabuk yalnız -Yaz ile: kabuk kasadaki satırlarla eşdeğerlik ister (kuru koşuda kasa boş)' }
    $kmYol = Join-Path $depoKok 'arac\kasa-modu.json'
    $km = Get-Content $kmYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $liste = New-Object System.Collections.Generic.List[string]; foreach ($s in @($km.sayfalar)) { $liste.Add("$s") }
    foreach ($s in $siteSayfa) { if (-not $liste.Contains($s.sayfa)) { $liste.Add($s.sayfa) } }
    $km.sayfalar = [string[]]$liste.ToArray()
    [IO.File]::WriteAllText($kmYol, (ConvertTo-Json -InputObject $km -Depth 4), [Text.UTF8Encoding]::new($false))
    "kasa modu listesi: $($liste.Count) sayfa"
    & node (Join-Path $depoKok 'motor\kasa-kabuk.js') --yaz
    if ($LASTEXITCODE) { throw "KABUK YAZILAMADI (çıkış $LASTEXITCODE) — depoya soru içeriği bırakılmıyor, sayfalar silinecek" }
    foreach ($s in $siteSayfa) {
      $ham = [IO.File]::ReadAllText($s.yol, [Text.Encoding]::UTF8)
      if ($ham -notmatch 'data-kasa-sayfa=' -or $ham.Length -gt 400000) { throw "KABUK DOĞRULANAMADI: $($s.sayfa)" }
      "  kabuk hazır: $($s.sayfa) · $([math]::Round($ham.Length/1024)) KB"
    }
    $siteSayfa.Clear()
  }
} finally {
  foreach ($s in $siteSayfa) { if (Test-Path $s.yol) { Remove-Item -LiteralPath $s.yol -Force; "  ⚠ kabuğa çevrilemeyen sayfa silindi: $($s.sayfa)" } }
  foreach ($d in $yazilanDosya) { if (Test-Path $d) { Remove-Item -LiteralPath $d -Force } }
  'çalışma dosyaları silindi (soru içeriği diskte bırakılmadı)'
}
if ($script:onayKirmizi -and $script:onayKirmizi.Count) { exit 1 }
