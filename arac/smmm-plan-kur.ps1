#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) DALGA PLANI — ders hakkı + son N yıl + ders içi sıklık payı   15.09.2026  (bedel 0, SORU BASMAZ)
#
#  NEDEN (Cem 15.09): "7 yıldan beri çıkmayan sorular varsa almayalım … 8 bin soru çok, smmm 4 bin … senin fikrin ne" → "1.2.3 üçünü de yap".
#  Eski yol (motor/konu-plani.ps1 + plandan-parti-kur.ps1) 19 yılın tamamını sayıyor ve "3+ kez çıkan konu × 4 tur" ile kuruyordu:
#  FMuh 608/1.068 soru (%57), SPK 20. Sınavda her ders 40 soru.
#  Bu betik:
#   1) yalnız -YilEsik ve sonrası (varsayılan 2020 = son 7 yıl) çıkan konuları alır (veri/smmm-analiz.json, yıl yıl);
#   2) her derse eşit soru HAKKI verir (-DersHak; dalga 1 = 125 → 1.000, tam hedef 500 → 4.000);
#   3) hakkı ders içinde GRUPLARA sıklık payıyla dağıtır (veri/sinav/smmm-konu-grup.json: FMuh 28 · Hukuk 15 · SPK 11 · FTA 14 · Maliyet 12 grup;
#      öteki derslerde her konu kendi grubu); 2026 test dönemlerinde çıkan konu -TestAgirlik kat sayılır;
#   4) grubun payını üyelerine sıklıkla dağıtır; soru yine gerçek (köprüdeki) konu adına basılır;
#   5) bizde sağlam soru varsa düşer (aynı soru iki kez yok); harita MULGA konu girmez; istisna dosyası elle konu ekler;
#   5b) 15.09: aynı konunun harf farklı yazımları birleşir; köprüde adı olmayan ad smmm-konu-es.json ile köprü adına bağlanır; bir konu dalgada
#       en çok -KonuTavan soru alır (artan grup içinde, sonra ders içinde dağılır); FTA 14 · Maliyet 12 grup eklendi;
#   6) zorluğu bitirme ölçümüne göre dağıtır (veri/sinav/smmm-zorluk-olcumu.json, en büyük açık kuralı).
#  Çıktı: -Yaz ile veri/sinav/plan-<Ad>.json + veri/sinav/konu/<etiket>.json; her durumda inceleme sayfası (depo DIŞI).
#  Üretim ayrı komut ve AYRI ONAY: powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-<Ad>.json
# ============================================================================
param([int]$DersHak = 125, [int]$YilEsik = 2020, [int]$PartiTavan = 30,
  # 15.09 (Cem "1.2.3 üçünü de yap"): kesin 7 yıl sınırı yerine YIL AĞIRLIĞI. ÖLÇÜLDÜ: 2008-2025 kitapçıkları KLASİK (2023/1 Maliyet "Cevap 1 (Toplam Puan: 35)",
  # ders başına dönemde 3-8 uzun soru), 2026 TEST (A-E, kitapçık başına 20). Klasik sınav az konuya dokunduğu için "7 yıldır çıkmadı" diye 2.029 konu dışarıda kalıyordu.
  # Bir konunun ağırlığı = EskiAgirlik × (YilEsik öncesi çıkma) + YeniAgirlik × (YilEsik–2025 çıkma) + TestAgirlik × (2026 test çıkma).
  # EskiAgirlik 0 · YeniAgirlik 1 · TestAgirlik 2 = 15.09 öğleden sonraki "yalnız son 7 yıl" planı (eşdeğerlik provası bununla yapıldı).
  [double]$EskiAgirlik = 1, [double]$YeniAgirlik = 2, [double]$TestAgirlik = 4,
  [int]$KonuTavan = -1,   # -1 = kendiliğinden max(2, ⌈DersHak/50⌉) (125 → 3, 500 → 10) · 0 = tavansız (15.09 öncesi davranış)
  [int]$KaynakSuzgeci = 1,   # 1 = ambar ölçümünde KAYNAK YOK çıkan konu plana girmez (veri/sinav/smmm-kaynak-olcumu.json) · 0 = eski davranış
  [ValidatePattern('^[a-z0-9-]{2,16}$')][string]$EtiketOn = 'smmm-d1', [string]$Ad = 'smmm-dalga1', [switch]$Yaz,
  [string]$HakemsizCikti = '',   # 16.09: planda olup ilgi hakeminden geçmemiş (ya da ölçülemeyen) konuların csv'si (ders,konu) — sonraki hakem turu
  [string]$SayfaYolu = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
function Katla([string]$s) { ("$s" -creplace 'İ', 'i' -creplace 'I', 'i' -creplace 'ı', 'i' -creplace 'Ğ', 'g' -creplace 'ğ', 'g' -creplace 'Ü', 'u' -creplace 'ü', 'u' -creplace 'Ş', 's' -creplace 'ş', 's' -creplace 'Ö', 'o' -creplace 'ö', 'o' -creplace 'Ç', 'c' -creplace 'ç', 'c' -creplace 'â', 'a').ToLowerInvariant() }
function HtmlK([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
$RESMI = [ordered]@{ 'meslek' = @('Muhasebecilik ve Mali Müşavirlik Meslek Hukuku', 'ymeslek'); 'finansal muhasebe' = @('Finansal Muhasebe', 'fmuh'); 'finansal tablo' = @('Finansal Tablolar ve Analizi', 'yfta'); 'maliyet' = @('Maliyet Muhasebesi', 'maliyet'); 'denetim' = @('Muhasebe Denetimi', 'ydenetim'); 'sermaye' = @('Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093)', 'yspk'); 'vergi' = @('Vergi Mevzuatı ve Uygulaması', 'yvergi'); 'hukuk' = @('Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.)', 'yhukuk') }
function ResmiDers([string]$ad) { $k = Katla $ad; foreach ($a in $RESMI.Keys) { if ($k.Contains($a)) { return $RESMI[$a] } }; return $null }

# --- 1) çıkmış sayımı (yıl yıl) ---
$an = Get-Content (Join-Path $depoKok 'veri\smmm-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
# 15.09 (GM 3): köprüde adı olmayan analiz adı, köprüde AYNI konuyu anlatan kayda bağlanır (veri/sinav/smmm-konu-es.json; yalnız ad denkliği, okunarak)
$esAd = @{}; $esYol = Join-Path $depoKok 'veri\sinav\smmm-konu-es.json'
if (Test-Path $esYol) { foreach ($e in @((Get-Content $esYol -Raw -Encoding UTF8 | ConvertFrom-Json).eslemeler)) { $rdE = ResmiDers $e.ders; if ($rdE) { $esAd["$($rdE[0])|$(Katla $e.analiz)"] = "$($e.kopru)" } } }
$konu = @{}   # "resmi|KATLANMIŞ konu" -> @{ yeni; test; son; adlar }
# 15.09 (Cem "1 ve 3 yap", GM 3): anahtar KATLANMIŞ ad. Analizde aynı konu harf farkıyla iki kez sayılıyordu ("satislarin karliligi" / "satislarin kârliligi",
# "kayİk" — ToLower 'İ'yi indirmiyor). Üretici konu dosyasını Katla2 ile okuyup aynı partide tekilliyor → planda 2 sayılan konudan 1 soru çıkardı.
# Görünen ad: en sık yazım, 'İ' → 'i'.
foreach ($r in $an.donemler) {
  $yil = [int]("$($r.donem)".Split('/')[0])
  foreach ($p in $r.konuSayim.PSObject.Properties) {
    $parca = $p.Name -split '\|', 2; $rd = ResmiDers $parca[0]; if (-not $rd) { continue }
    if ($esAd.ContainsKey("$($rd[0])|$(Katla $parca[1])")) { $parca[1] = $esAd["$($rd[0])|$(Katla $parca[1])"] }
    $key = "$($rd[0])|$(Katla $parca[1])"; if (-not $konu.ContainsKey($key)) { $konu[$key] = @{ yeni = 0; test = 0; eski = 0; son = 0; adlar = @{} } }
    $x = $konu[$key]; if ($yil -gt $x.son) { $x.son = $yil }; if ($yil -ge $YilEsik) { $x.yeni += [int]$p.Value } else { $x.eski += [int]$p.Value }; if ($yil -ge 2026) { $x.test += [int]$p.Value }
    $x.adlar[$parca[1]] = [int]$x.adlar[$parca[1]] + [int]$p.Value
  }
}
function KonuAgirlik([string]$key) { $v = $konu[$key]; $EskiAgirlik * [double]$v.eski + $YeniAgirlik * ([double]$v.yeni - [double]$v.test) + $TestAgirlik * [double]$v.test }
function GorunenAd([string]$key) { $a = $konu[$key].adlar; if (-not $a -or $a.Count -eq 0) { return ($key -split '\|', 2)[1] }; (@($a.Keys | Sort-Object @{e = { $a[$_] }; Descending = $true }, @{e = { $_ } })[0]) -creplace 'İ', 'i' }
# --- 2) yardımcı veriler ---
$grupJ = Get-Content (Join-Path $depoKok 'veri\sinav\smmm-konu-grup.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$grupOf = @{}   # "resmi|konu" -> grup
foreach ($dp in $grupJ.dersler.PSObject.Properties) { $rd = ResmiDers $dp.Name; foreach ($gp in $dp.Value.PSObject.Properties) { foreach ($k in @($gp.Value)) { $kk = "$($rd[0])|$(Katla $k)"; $dolayli = $esAd.ContainsKey($kk); if ($dolayli) { $kk = "$($rd[0])|$(Katla $esAd[$kk])" }; if (-not $dolayli -or -not $grupOf.ContainsKey($kk)) { $grupOf[$kk] = $gp.Name } } } }   # 15.09: kanonik adın kendi grubu, eş yazımının grubunu ezer
$mulga = @{}; foreach ($h in (Get-Content (Join-Path $depoKok 'veri\sinav\smmm-konu-dayanak.json') -Raw -Encoding UTF8 | ConvertFrom-Json).konular) { if ("$($h.durum)" -like 'MULGA*') { $mulga[(Katla $h.konu)] = 1 } }
# 16.09 (Cem "1.2.3 üçünü de yapalım", GM 2): KAYNAK SÜZGECİ. arac/smmm-kaynak-olcum.ps1 ambardan ölçtü; paketi 300 kr'ın altında kalan konuya
# üretici zaten soru BASMIYOR (kaynak borcuna yazıyor). O konu plana da girmez, payı aynı grubun kaynağı olan konularına dağılır.
# Dosya yoksa ya da -KaynakSuzgeci 0 ise davranış birebir eskisi (eşdeğerlik provası bununla yapıldı).
$kaynakYok = @{}; $koYol = Join-Path $depoKok 'veri\sinav\smmm-kaynak-olcumu.json'
if ($KaynakSuzgeci -ne 0 -and (Test-Path $koYol)) { foreach ($z in @((Get-Content $koYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular)) { if ("$($z.durum)" -eq 'KAYNAK YOK') { $kaynakYok["$(ResmiDers $z.ders | Select-Object -First 1)|$(Katla $z.konu)"] = 1 } } }
# 16.09 İLGİ HAKEMİ (Cem "1.2.3", GM 1): konunun paketi konuyla ilgili mi sorusunu MODEL hakemi verir (arac/smmm-ilgi-hakemi.ps1, bulutta
# smmm-ilgi-hakemi.yml → veri/sinav/smmm-ilgi-hakemi-*.json). Kelime kuralının İLGİSİZ kararı YOK SAYILIR (26 elle doğrulanmış konuda %73;
# hakem geçerli 22 cevabın 22'sinde doğru). Hakemin İLGİSİZ dediği konu plana girmez; hakem kararı olmayan konu girer ve -HakemsizCikti'ya yazılır.
$hakem = @{}; $hakemAtilan = 0
if ($KaynakSuzgeci -ne 0) {
  foreach ($hf in @(Get-ChildItem (Join-Path $depoKok 'veri\sinav') -Filter 'smmm-ilgi-hakemi-*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)) {
    foreach ($z in @((Get-Content $hf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).konular)) {
      $hk = "$(ResmiDers $z.ders | Select-Object -First 1)|$(Katla $z.konu)"
      if ("$($z.durum)" -eq 'OLCULEMEDI' -and $hakem.ContainsKey($hk)) { continue }   # yeni tur ölçemediyse eski kararı koru
      $hakem[$hk] = "$($z.durum)"
    }
  }
  foreach ($hk in $hakem.Keys) { if ($hakem[$hk] -eq 'ILGISIZ' -and -not $kaynakYok.ContainsKey($hk)) { $kaynakYok[$hk] = 'H' } }
}
# 16.09 KANUN UYUŞMAZLIĞI KAPISI (ölçüldü): harita "MADDE OKUNDU" ile köprü dayanağı FARKLI kanunu gösteriyorsa üretici köprüyü kullanır
# (harita yalnız köprü dayanağı boşken devreye girer). "kdv'nin konusu": harita KDVK (3065) m.1, köprü ÖTV K. (4760) m.1 — ÖTV kısaltması
# eklenince paket 0 -> 1.239 kr oldu ve ölçüm GÜÇLÜ dedi; yani plan bu konuya ÖTV metniyle KDV sorusu bastıracaktı. 97 okunmuş konuda 2 uyuşmaz.
# Uyuşmaz konu KAYNAK YOK gibi plandan düşer; üretici tarafı onarılınca kapı kendiliğinden boşalır.
function KanunNo([string]$s) { if ($s -match '\b(\d{4})\b\s*(s\.|sayılı)') { return 'K' + $matches[1] }; if ($s -match 'THP|Tekdüzen|\b[1-7]\d\d\b') { return 'THP' }; if ($s -match 'TMS|TFRS|BDS') { return 'STD' }; return '?' }
$kanunUyusmaz = 0
if ($KaynakSuzgeci -ne 0 -and $env:SMMM_KANUN_KAPISI -ne '0') {   # ortam değişkeni yalnız eşdeğerlik provası için
  $kbD = @{}; foreach ($x in (Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { if ($x.sinav -eq 'SMMM' -and -not $kbD.ContainsKey((Katla $x.konu))) { $kbD[(Katla $x.konu)] = $x } }
  foreach ($h in (Get-Content (Join-Path $depoKok 'veri\sinav\smmm-konu-dayanak.json') -Raw -Encoding UTF8 | ConvertFrom-Json).konular) {
    if ("$($h.durum)" -ne 'MADDE OKUNDU' -or -not $kbD.ContainsKey((Katla $h.konu))) { continue }
    $x = $kbD[(Katla $h.konu)]; $kd = $(if ("$($x.dayanak)".Trim()) { "$($x.dayanak)" } else { "$($x.cikmis_dayanak)" })
    if ($kd.Trim() -and (KanunNo $kd) -ne (KanunNo "$($h.dayanak)")) {
      $kanunUyusmaz++
      # 16.09 ikinci karar: üretici okunmuş haritayı artık köprünün önüne koyuyor (kalip-parti-uret.ps1), uyuşmaz konu doğru kanunla basılır → plandan DÜŞÜRÜLMEZ, yalnız sayılır.
    }
  }
}
$bizde = @{}; $kpYol =Join-Path $depoKok 'veri\konu-plani-smmm.json'; if (Test-Path $kpYol) { foreach ($s in (Get-Content $kpYol -Raw -Encoding UTF8 | ConvertFrom-Json).satirlar) { $rd = ResmiDers $s.ders; if ($rd -and [int]$s.bizde -gt 0) { $bizde["$($rd[0])|$(Katla $s.konu)"] = [int]$s.bizde } } }
$kopru = @{}; foreach ($x in (Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { if ($x.sinav -eq 'SMMM') { $kopru[(Katla $x.konu)] = 1 } }
$istisnaYol = Join-Path $depoKok 'veri\sinav\smmm-konu-istisna.json'; $istisna = @()
if (Test-Path $istisnaYol) { $istisna = @(foreach ($i in (Get-Content $istisnaYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular) { $i }) }
foreach ($i in $istisna) { $rd = ResmiDers $i.ders; if (-not $rd) { continue }; $key = "$($rd[0])|$(Katla $i.konu)"; if (-not $konu.ContainsKey($key)) { $konu[$key] = @{ yeni = 0; test = 0; eski = 0; son = $YilEsik; adlar = @{ "$($i.konu)" = 1 } } }; $konu[$key].yeni += [math]::Max(1, [int]$i.agirlik); $konu[$key].istisna = "$($i.neden)" }
$zor = Get-Content (Join-Path $depoKok 'veri\sinav\smmm-zorluk-olcumu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$zt = [double]$zor.kolay + [double]$zor.zor + [double]$zor.cokzor; $ZPAY = [ordered]@{ kolay = [double]$zor.kolay / $zt; zor = [double]$zor.zor / $zt; cokzor = [double]$zor.cokzor / $zt }

# --- 3) dağıtım ---
function EnBuyukKalan([hashtable]$agirlik, [int]$toplam) {
  $sonuc = @{}; $w = 0.0; foreach ($k in $agirlik.Keys) { $w += $agirlik[$k] }; if ($w -le 0 -or $toplam -le 0) { foreach ($k in $agirlik.Keys) { $sonuc[$k] = 0 }; return $sonuc }
  $kalan = @(); $dagit = 0
  foreach ($k in $agirlik.Keys) { $ham = $toplam * $agirlik[$k] / $w; $taban = [math]::Floor($ham); $sonuc[$k] = [int]$taban; $dagit += $taban; $kalan += , @($k, ($ham - $taban), $agirlik[$k]) }
  $sirali = @($kalan | Sort-Object @{e = { $_[1] }; Descending = $true }, @{e = { $_[2] }; Descending = $true }, @{e = { $_[0] } })
  for ($i = 0; $i -lt ($toplam - $dagit) -and $i -lt $sirali.Count; $i++) { $sonuc[$sirali[$i][0]]++ }
  return $sonuc
}
# 15.09 (Cem "1 ve 3 yap", GM 1): KONU TAVANI. Gruplama tek başına yığılmayı çözmez (konu payı grup içinde aynı oranda kalır); FTA'da
# "dikey yuzde analizi" 5, Maliyet'te "gug yukleme katsayisi" 5 soru alıyordu. Bir konu dalgada en çok $tavanKonu soru alır; artan önce
# AYNI grubun tavanı dolmamış konularına, sonra ders içindeki öteki konulara ağırlıkla dağılır (ders hakkı korunur).
$tavanKonu = $(if ($KonuTavan -gt 0) { $KonuTavan } elseif ($KonuTavan -eq 0) { [int]::MaxValue } else { [int][math]::Max(2, [math]::Ceiling($DersHak / 50.0)) })
$tavanTasan = 0; $tavanKalan = 0; $kaynakAtilan = 0
function TavanliDagit([hashtable]$agirlik, [int]$toplam, [hashtable]$mevcut, [int]$tavan) {
  $sonuc = @{}; foreach ($k in $agirlik.Keys) { $sonuc[$k] = 0 }; $kalan = $toplam
  while ($kalan -gt 0) {
    $acik = @{}; foreach ($k in $agirlik.Keys) { if ([int]$mevcut[$k] + $sonuc[$k] -lt $tavan -and $agirlik[$k] -gt 0) { $acik[$k] = $agirlik[$k] } }
    if ($acik.Count -eq 0) { break }
    $pay = EnBuyukKalan $acik $kalan; $dolan = 0
    foreach ($k in $pay.Keys) { $bos = $tavan - [int]$mevcut[$k] - $sonuc[$k]; $ver = [math]::Min($pay[$k], $bos); $sonuc[$k] += $ver; $kalan -= $ver; if ($pay[$k] -ge $bos) { $dolan++ } }
    if ($dolan -eq 0) { break }
  }
  return @{ sonuc = $sonuc; artan = $kalan }
}
$dersOzet = New-Object System.Collections.Generic.List[object]; $grupSatir = New-Object System.Collections.Generic.List[object]; $slotTum = New-Object System.Collections.Generic.List[object]
$kopruDisi = New-Object System.Collections.Generic.List[string]; $mulgaAtilan = 0
foreach ($rd in $RESMI.Values) {
  $ders = $rd[0]
  $uyeler = @($konu.Keys | Where-Object { $_.StartsWith("$ders|") -and $(if ($EskiAgirlik -gt 0) { (KonuAgirlik $_) -gt 0 } else { $konu[$_].son -ge $YilEsik -and $konu[$_].yeni -gt 0 }) })
  $uyeler = @($uyeler | Where-Object { if ($mulga.ContainsKey((Katla ($_ -split '\|', 2)[1]))) { $script:mulgaAtilan++; $false } else { $true } })
  $uyeler = @($uyeler | Where-Object { $kyA = $(if ($kaynakYok.ContainsKey($_)) { $_ } else { "$(($_ -split '\|',2)[0])|$(Katla (GorunenAd $_))" }); if ($kaynakYok.ContainsKey($kyA)) { if ($kaynakYok[$kyA] -eq 'H') { $script:hakemAtilan++ } else { $script:kaynakAtilan++ }; $false } else { $true } })
  $gAg = @{}; $gUye = @{}
  foreach ($key in $uyeler) { $g = $(if ($grupOf.ContainsKey($key)) { $grupOf[$key] } else { GorunenAd $key }); $w = KonuAgirlik $key; $gAg[$g] = [double]$gAg[$g] + $w; if (-not $gUye.ContainsKey($g)) { $gUye[$g] = New-Object System.Collections.Generic.List[string] }; $gUye[$g].Add($key) }
  $gSoru = EnBuyukKalan $gAg $DersHak
  # konu tavanı: grup payı önce grubun konularına tavanlı dağılır; taşan ders içinde tavanı dolmamış konulara ağırlıkla gider
  $uAgTum = @{}; foreach ($key in $uyeler) { $uAgTum[$key] = KonuAgirlik $key }
  $uSoruTum = @{}; $tasan = 0
  foreach ($g in $gSoru.Keys) { if ($gSoru[$g] -le 0) { continue }; $uAg = @{}; foreach ($key in $gUye[$g]) { $uAg[$key] = $uAgTum[$key] }
    $td = TavanliDagit $uAg $gSoru[$g] @{} $tavanKonu; foreach ($key in $td.sonuc.Keys) { $uSoruTum[$key] = $td.sonuc[$key] }; $tasan += $td.artan }
  if ($tasan -gt 0) { $td = TavanliDagit $uAgTum $tasan $uSoruTum $tavanKonu; foreach ($key in $td.sonuc.Keys) { $uSoruTum[$key] = [int]$uSoruTum[$key] + $td.sonuc[$key] }; $tavanTasan += $tasan; $tavanKalan += $td.artan }
  $dersSlot = New-Object System.Collections.Generic.List[object]; $dusulen = 0
  foreach ($g in ($gSoru.Keys | Sort-Object { -$gSoru[$_] }, { $_ })) {
    $uSoru = @{}; foreach ($key in $gUye[$g]) { $uSoru[$key] = [int]$uSoruTum[$key] }; $gToplam = ($uSoru.Values | Measure-Object -Sum).Sum
    if ($gToplam -le 0) { $grupSatir.Add([pscustomobject]@{ ders = $ders; grup = $g; agirlik = $gAg[$g]; soru = 0; konu = $gUye[$g].Count; ornek = '' }); continue }
    $uAg = $uAgTum
    $ornekler = @()
    foreach ($key in ($uSoru.Keys | Sort-Object { -$uSoru[$_] }, { $_ })) {
      $kAd = GorunenAd $key; $n = $uSoru[$key]; if ($n -le 0) { continue }
      $bz = [int]$bizde["$ders|$(Katla $kAd)"]; if ($bz -gt 0) { $dus = [math]::Min($bz, $n); $n -= $dus; $dusulen += $dus }
      if ($n -le 0) { continue }
      if (-not $kopru.ContainsKey((Katla $kAd))) { $kopruDisi.Add("$ders | $kAd") }
      for ($t = 1; $t -le $n; $t++) { $dersSlot.Add([pscustomobject]@{ ders = $ders; kis = $rd[1]; konu = $kAd; tur = $t; w = $uAg[$key] }) }
      $ornekler += "$kAd ($n)"
    }
    $grupSatir.Add([pscustomobject]@{ ders = $ders; grup = $g; agirlik = $gAg[$g]; soru = $gToplam; konu = $gUye[$g].Count; ornek = ($ornekler -join ' · ') })
  }
  # zorluk: turlara göre sıralı (önce bütün r1'ler, ağırlığa göre), en büyük açık
  $atanan = @{ kolay = 0; zor = 0; cokzor = 0 }; $i = 0
  foreach ($sl in @($dersSlot | Sort-Object tur, @{e = { $_.w }; Descending = $true }, konu)) { $i++; $en = $null; $ef = [double]::MinValue; foreach ($z in $ZPAY.Keys) { $f = $ZPAY[$z] * $i - $atanan[$z]; if ($f -gt $ef) { $ef = $f; $en = $z } }; $atanan[$en]++; $sl | Add-Member -NotePropertyName zorluk -NotePropertyValue $en; $slotTum.Add($sl) }
  $dersOzet.Add([pscustomobject]@{ ders = $ders; kis = $rd[1]; konu7 = $uyeler.Count; grup = $gAg.Count; hak = $DersHak; plan = $dersSlot.Count; bizdeDusulen = $dusulen; kolay = $atanan.kolay; zor = $atanan.zor; cokzor = $atanan.cokzor })
}
# --- 4) partiler ---
$planSatir = New-Object System.Collections.Generic.List[object]; $konuDosya = @{}
foreach ($grp in ($slotTum | Group-Object ders, zorluk, tur | Sort-Object Name)) {
  $ilk = $grp.Group[0]; $liste = @($grp.Group | Sort-Object @{e = { $_.w }; Descending = $true }, konu)
  $parca = 0
  for ($b = 0; $b -lt $liste.Count; $b += $PartiTavan) {
    $parca++; $dilim = @($liste[$b..([math]::Min($b + $PartiTavan, $liste.Count) - 1)])
    $et = "$EtiketOn-$($ilk.kis)-$($ilk.zorluk)-r$($ilk.tur)" + $(if ($parca -gt 1) { "-$parca" } else { '' })
    $konuDosya[$et] = @($dilim | ForEach-Object { $_.konu })
    $planSatir.Add([pscustomobject][ordered]@{ ders = $ilk.ders; dersAd = $ilk.ders; etiket = $et; adet = $dilim.Count; zorluk = $ilk.zorluk; sinav = 'SMMM'; konuDosya = "veri/sinav/konu/$et.json"; toplu = $true; disla = ''; tur = $ilk.tur })
  }
}
# hakem kararı olmayan plan konuları (sonraki tur)
$hakemsiz = @($slotTum | ForEach-Object { "$($_.ders)|$($_.konu)" } | Sort-Object -Unique | Where-Object { $hk2 = "$(($_ -split '\|',2)[0])|$(Katla (($_ -split '\|',2)[1]))"; -not $hakem.ContainsKey($hk2) -or $hakem[$hk2] -eq 'OLCULEMEDI' })
if ($HakemsizCikti) { @($hakemsiz | ForEach-Object { $pp = $_ -split '\|', 2; [pscustomobject]@{ ders = $pp[0]; konu = $pp[1] } }) | Export-Csv $HakemsizCikti -NoTypeInformation -Encoding UTF8 }
$cakisan = @($planSatir | Where-Object { (Test-Path (Join-Path $depoKok "veri\fabrika\kalip-parti-$($_.etiket).json")) -or (Test-Path (Join-Path $depoKok "veri\sinav\konu\$($_.etiket).json")) } | ForEach-Object etiket)
$topPlan = ($planSatir | Measure-Object adet -Sum).Sum
"SMMM DALGA PLANI [$Ad] · yıl ağırlığı: $YilEsik öncesi ×$EskiAgirlik · $YilEsik–2025 ×$YeniAgirlik · 2026 test ×$TestAgirlik · ders hakkı $DersHak · konu tavanı $(if ($tavanKonu -eq [int]::MaxValue) { 'yok' } else { $tavanKonu }) (gruptan taşan $tavanTasan, yer bulunamayan $tavanKalan) · ad eşlemesi $($esAd.Count) · MÜLGA atılan $mulgaAtilan · KAYNAK YOK atılan $kaynakAtilan · HAKEM İLGİSİZ atılan $hakemAtilan (hakem kararı $($hakem.Count) konu) (kanun uyuşmazlığı $kanunUyusmaz konu) · istisna $($istisna.Count)"
foreach ($d in $dersOzet) { "  {0,-48} $(if ($EskiAgirlik -gt 0) { 'tüm yıllar' } else { "son $(2026 - $YilEsik + 1) yıl" }) konu {2,3} · grup {3,3} · plan {4,4} (bizde düşülen {5}) · kolay {6} zor {7} çok zor {8}" -f $d.ders.Substring(0, [math]::Min(48, $d.ders.Length)), (2026 - $YilEsik + 1), $d.konu7, $d.grup, $d.plan, $d.bizdeDusulen, $d.kolay, $d.zor, $d.cokzor }
"TOPLAM soru $topPlan · parti $($planSatir.Count) · hakemden geçmemiş konu $($hakemsiz.Count) · köprü dışı konu adı $($kopruDisi.Count) · mevcut etiketle çakışan $($cakisan.Count)"
if ($cakisan.Count) { throw "ETİKET ÇAKIŞMASI — yeni plan yeni önek ister: $($cakisan -join ', ')" }

# --- 5) inceleme sayfası (depo dışı) ---
if (-not $SayfaYolu) { $SayfaYolu = Join-Path (Split-Path $depoKok -Parent) "SMMM-Plan-$Ad.html" }
$sb = New-Object Text.StringBuilder
[void]$sb.Append("<!doctype html><html lang=tr><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>SMMM $Ad</title><style>:root{--z:#faf9f6;--y:#1c1c1c;--s:#666;--c:#ddd;--b:#eee}@media (prefers-color-scheme:dark){:root{--z:#161616;--y:#eee;--s:#aaa;--c:#333;--b:#222}}body{background:var(--z);color:var(--y);font:14px/1.45 -apple-system,Segoe UI,Arial,sans-serif;margin:0;padding:16px;max-width:1100px}h1{font-size:19px;margin:0 0 4px}h2{font-size:16px;margin:22px 0 8px}.s{color:var(--s);font-size:12px}.tk{overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:13px}th,td{border-bottom:1px solid var(--c);padding:5px 6px;text-align:left;vertical-align:top}th{background:var(--b)}td.n{text-align:right}details{border:1px solid var(--c);border-radius:8px;margin:8px 0;padding:6px 10px}summary{cursor:pointer;font-weight:600}</style></head><body>")
[void]$sb.Append("<h1>SMMM bitirme — $(HtmlK $Ad) planı (SORU BASILMADI)</h1><div class=s>Kural: $(if ($EskiAgirlik -gt 0) { "tüm yıllar, ağırlık $YilEsik öncesi ×$EskiAgirlik · $YilEsik–2025 ×$YeniAgirlik" } else { "yalnız $YilEsik ve sonrası çıkan konular" }) · her derse $DersHak soru hakkı · ders içinde grup/konu sıklık payı · 2026 test konuları ×$TestAgirlik · bizde olan soru düşülür · MÜLGA konu girmez · zorluk bitirme ölçümü (%$($zor.kolay) / %$($zor.zor) / %$($zor.cokzor)). Kaynak: veri/smmm-analiz.json, veri/sinav/smmm-konu-grup.json (ONAY BEKLİYOR).</div>")
[void]$sb.Append("<h2>Ders özeti</h2><div class=tk><table><tr><th>Ders</th><th>$(if ($EskiAgirlik -gt 0) { 'Konu (tüm yıllar)' } else { "Son $(2026-$YilEsik+1) yılda konu" })</th><th>Grup</th><th>Plan soru</th><th>Bizde olduğu için düşülen</th><th>Kolay</th><th>Zor</th><th>Çok zor</th></tr>")
foreach ($d in $dersOzet) { [void]$sb.Append("<tr><td>$(HtmlK $d.ders)</td><td class=n>$($d.konu7)</td><td class=n>$($d.grup)</td><td class=n>$($d.plan)</td><td class=n>$($d.bizdeDusulen)</td><td class=n>$($d.kolay)</td><td class=n>$($d.zor)</td><td class=n>$($d.cokzor)</td></tr>") }
[void]$sb.Append("<tr><th>TOPLAM</th><th></th><th></th><th class=n>$topPlan</th><th></th><th class=n>$(($dersOzet|Measure-Object kolay -Sum).Sum)</th><th class=n>$(($dersOzet|Measure-Object zor -Sum).Sum)</th><th class=n>$(($dersOzet|Measure-Object cokzor -Sum).Sum)</th></tr></table></div>")
[void]$sb.Append("<p class=s>Bedel tahmini (basılmadı): pilot ölçümü plan satırı başına ≈0,40 USD → ≈$([math]::Round($topPlan*0.35)) – $([math]::Round($topPlan*0.45)) USD. Yayın oranı toplu basımda ölçülmedi (pilot 24 satırda 12).</p>")
[void]$sb.Append("<h2>Ders ders gruplar ve konular</h2>")
foreach ($d in $dersOzet) { [void]$sb.Append("<details><summary>$(HtmlK $d.ders) — $($d.plan) soru</summary><div class=tk><table><tr><th>Grup</th><th>Ağırlık (son yıllarda çıkma)</th><th>Soru</th><th>Konular (soru)</th></tr>")
  foreach ($g in @($grupSatir | Where-Object { $_.ders -eq $d.ders } | Sort-Object @{e = { $_.soru }; Descending = $true }, grup)) { [void]$sb.Append("<tr><td>$(HtmlK $g.grup)</td><td class=n>$($g.agirlik)</td><td class=n>$($g.soru)</td><td class=s>$(HtmlK $g.ornek)</td></tr>") }
  [void]$sb.Append("</table></div></details>") }
if ($kopruDisi.Count) { [void]$sb.Append("<h2>Köprüde adı olmayan konular ($($kopruDisi.Count))</h2><p class=s>Üretici bunları köprü dışı sentez olarak alır (dayanak boş; SPK'da harita devreye girer).</p><div class=s>$(HtmlK ($kopruDisi -join ' · '))</div>") }
[void]$sb.Append("</body></html>")
[IO.File]::WriteAllText($SayfaYolu, $sb.ToString(), [Text.UTF8Encoding]::new($false)); "inceleme sayfası: $SayfaYolu"

if ($Yaz) {
  $u8 = [Text.UTF8Encoding]::new($false)
  foreach ($et in $konuDosya.Keys) { [IO.File]::WriteAllText((Join-Path $depoKok "veri\sinav\konu\$et.json"), (ConvertTo-Json -InputObject @($konuDosya[$et]) -Depth 3), $u8) }
  [IO.File]::WriteAllText((Join-Path $depoKok "veri\sinav\plan-$Ad.json"), (ConvertTo-Json -InputObject $planSatir.ToArray() -Depth 4), $u8)
  "YAZILDI: veri/sinav/plan-$Ad.json + $($konuDosya.Count) konu dosyası · ÜRETİM AYRI ONAY: motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-$Ad.json"
} else { "KURU KOŞU — plan dosyası yazılmadı (-Yaz ile yazar)" }
