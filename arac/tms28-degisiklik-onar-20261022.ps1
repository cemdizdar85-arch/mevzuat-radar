#requires -Version 5.1
# ============================================================================
#  TMS 28 DEĞİŞİKLİKLERİ (RG 31.07.2026-33326) — ambar kaydı resmî metne birebir uyduruldu   22.10.2026 · BEDEL 0
#
#  NEDEN: "TMS 28 Degisiklikleri - Istiraklerde Gercege Uygun Deger Secenegi (RG 31.07.2026-33326) bolum 1-3"
#    kayıtları RG 33326 Kurul Kararı ekindeki metinle satır satır karşılaştırıldı (altı çizili = eklenen,
#    üstü çizili = silinen). Sapmalar:
#    (1) p.18: "yatırım fonu" atılmış ve "SİLİNEN" denmişti — YANLIŞ: resmî metinde "yatırım fonu" KALIR,
#        yalnız önündeki "veya" silinir, "kuruluşu"ndan sonra virgül eklenir.
#    (2) p.18: "bir yatırımın;" → "bir yatırım;" · "kâr ya da zarara" → "kâr veya zarara".
#    (3) p.18/p.19: "benzer işletmeler" → "benzer işletme" (resmî metinde "-ler" eki üstü çizili),
#        p.19 ikinci yerde "benzer işletmelerin" → "benzer işletmenin" ("n" eklendi, "ler" silindi).
#    (4) p.19: resmî Türkçe metinde OLMAYAN "veya bu işletmeler tarafından" ve "iştirak veya iş ortaklığı yatırımına"
#        eklemeleri çıkarıldı → "yoluyla dolaylı olarak elde tutulan iştirak yatırımına".
#    (5) p.19: ikinci ve üçüncü yerde "kuruluşu"ndan sonra resmî metinde virgül YOK (birebir korunur); "hâlinde" → "halinde".
#    (6) Büyük harfle vurgulanmış ifadeler (VEYA, YATIRIM, BENZER İŞLETMELER…) resmî yazımla küçültüldü;
#        silinen/eklenen ifadeler paragraf sonunda köşeli parantezle, silinen cümleler birebir yazıldı.
#    (7) Künye: karar cümlesi resmî metinden birebir (Konu satırı dahil) yazıldı.
#    bolum 3 (45M son cümlesi) resmî metinle aynı — dokunulmaz.
#  RESMÎ KAYNAK: https://www.resmigazete.gov.tr/eskiler/2026/07/20260731-12.pdf (RG 31.07.2026 sayı 33326) okundu.
#  TMS 28 p.18/p.19 standart kayıtlarına DOKUNULMAZ (eski metin 2026'da geçerli; değişiklik TFRS 18 ile uygulanır).
#  YÖNTEM: teori-notu-duzelt-20261021c.ps1 ile aynı (depo + ambar, ön kontrol, yedek, geri okuma, "zaten yazılı" atlaması).
#    Bu kayıtlar 'ad|TEORI' ya da kanun anahtarı olmadığından nöbetçi belirteci (_degisen-kokler) yazılmaz.
#    -Uygula yoksa KURU.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'
$depoDosya = Join-Path $depoKok 'veri\mevzuat\kgk-tms28-degisiklik-2026.json'
$adKok = 'TMS 28 Degisiklikleri - Istiraklerde Gercege Uygun Deger Secenegi (RG 31.07.2026-33326) bolum '

$eski1 = @'
TMS 28 İŞTİRAKLERDEKİ VE İŞ ORTAKLIKLARINDAKİ YATIRIMLAR'A İLİŞKİN DEĞİŞİKLİKLER (İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler) Resmî Gazete: 31 Temmuz 2026 CUMA, Sayı: 33326 - KURUL KARARI Kamu Gözetimi, Muhasebe ve Denetim Standartları Kurumundan Karar No: 75935942-050.01.04-[44558] Karar Tarihi: 28.07.2026 Dayanak: 660 sayılı KHK m.9. Uluslararası Muhasebe Standartları Kurumunun "Amendments to the Fair Value Option for Investments in Associates and Joint Ventures - Amendments to IAS 28" başlıklı değişikliğinin mevzuatımıza kazandırılması. AMBAR NOTU (karar metninin parçası değildir): Bu belge TMS 28'i DEĞİŞTİREN metindir; ambardaki TMS 28 paragrafları değişiklik ÖNCESİ sürümdür. Paragraf 18-19 değiştirilmiş, paragraf 45M eklenmiştir. Yürürlük TFRS 18'in uygulanmasına bağlıdır (aşağıda 45M). Aşağıda YENİ hâl yazılmıştır; kararda üstü çizili gösterilen silinmiş ifadeler köşeli parantezle belirtilmiştir. ÖZKAYNAK YÖNTEMİNİN UYGULANMASINA İLİŞKİN İSTİSNALAR PARAGRAF 18 (YENİ HÂLİ) - İştirakteki veya iş ortaklığındaki bir yatırımın; bir girişim sermayesi kuruluşu, yatırım ortaklığı VEYA benzer işletmeler yoluyla dolaylı olarak ya da bu işletmelerce doğrudan elde tutuluyorsa, işletme bu yatırımı TFRS 9 uyarınca gerçeğe uygun değer değişimi kâr ya da zarara yansıtılan olarak ölçmeyi tercih edebilir. BENZER İŞLETMELER, BELİRLENMİŞ ANA FAALİYETLERİ BELİRLİ VARLIK TÜRLERİNE YATIRIM YAPMAK OLAN İŞLETMELERİ İÇERİR (BAKINIZ: TFRS 18 PARAGRAF 49(a)). İşletme bu tercihi, iştirak veya iş ortaklığı ilk defa finansal tablolara alınırken her bir iştirak veya iş ortaklığı için ayrı ayrı yapar.
'@
$yeni1 = @'
TMS 28 İŞTİRAKLERDEKİ VE İŞ ORTAKLIKLARINDAKİ YATIRIMLAR'A İLİŞKİN DEĞİŞİKLİKLER (İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler) Resmî Gazete: 31 Temmuz 2026 CUMA, Sayı: 33326 - KURUL KARARI Kamu Gözetimi, Muhasebe ve Denetim Standartları Kurumundan Karar No: 75935942-050.01.04-[44558] Karar Tarihi: 28.07.2026 Konu: İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler'in yayımlanması. 660 sayılı Kanun Hükmünde Kararname'nin 9'uncu maddesi uyarınca; uluslararası standartlarla uyum sağlamak üzere, Uluslararası Muhasebe Standartları Kurumu tarafından "Amendments to the Fair Value Option for Investments in Associates and Joint Ventures—Amendments to IAS 28" başlığıyla yayımlanan değişikliğin mevzuatımıza kazandırılması amacıyla, "İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler" in yayımlanmasına karar verilmiştir. AMBAR NOTU (karar metninin parçası değildir): Bu belge TMS 28'i DEĞİŞTİREN metindir; ambardaki TMS 28 paragrafları değişiklik ÖNCESİ sürümdür. Paragraf 18-19 değiştirilmiştir ve paragraf 45M eklenmiştir. Yürürlük TFRS 18'in uygulanmasına bağlıdır (aşağıda 45M). Aşağıda paragrafların YENİ hâli resmî metinden birebir yazılmıştır; kararda altı çizili gösterilen eklenen ve üstü çizili gösterilen silinen ifadeler her paragrafın ardından köşeli parantezle belirtilmiştir. Özkaynak yönteminin uygulanmasına ilişkin istisnalar PARAGRAF 18 (YENİ HÂLİ) - İştirakteki veya iş ortaklığındaki bir yatırım; bir girişim sermayesi kuruluşu, yatırım fonu, yatırım ortaklığı veya benzer işletme yoluyla dolaylı olarak ya da bu işletmelerce doğrudan elde tutuluyorsa, işletme bu yatırımı TFRS 9 uyarınca gerçeğe uygun değer değişimi kâr veya zarara yansıtılan olarak ölçmeyi tercih edebilir. Benzer işletmeler, belirlenmiş ana faaliyetleri belirli varlık türlerine yatırım yapmak olan işletmeleri içerir (bakınız: TFRS 18 paragraf 49(a)). İşletme bu tercihi, iştirak veya iş ortaklığı ilk defa finansal tablolara alınırken her bir iştirak veya iş ortaklığı için ayrı ayrı yapar.
'@
$eski2 = @'
[SİLİNEN: "yatırım fonu", "yatırım amaçlı sigorta fonlarını kapsayan" ifadeleri; yatırım amaçlı sigorta fonlarına örnek olarak doğrudan katılım özelliği bulunan sigorta sözleşmeleri grubuna ilişkin dayanak kalem açıklaması; tercihin amaçları açısından sigorta sözleşmelerinin isteğe bağlı katılım özelliği bulunan yatırım-sigorta sözleşmelerini içerdiğine dair cümle; "Bu paragrafta kullanılan terimlerin tanımları için TFRS 17 Sigorta Sözleşmeleri'ne bakınız." cümlesi.] PARAGRAF 19 (YENİ HÂLİ) - İşletmenin, bir kısmı girişim sermayesi kuruluşu, YATIRIM fonu, yatırım ortaklığı VEYA benzer işletmeler yoluyla dolaylı olarak veya bu işletmeler tarafından elde tutulan iştirak veya iş ortaklığı yatırımına sahip olması durumunda işletme, iştirak yatırımının bu kısmını TFRS 9 uyarınca gerçeğe uygun değer farkı kâr veya zarara yansıtılan olarak ölçmeyi seçebilir. Bu durumda girişim sermayesi kuruluşu, YATIRIM fonu, yatırım ortaklığı VEYA benzer işletmelerin, yatırımın söz konusu bu kısmı üzerinde önemli etkisinin bulunup bulunmadığı dikkate alınmaz. İşletmenin böyle bir seçimde bulunması hâlinde, girişim sermayesi kuruluşu, YATIRIM fonu, yatırım ortaklığı VEYA benzer işletmeler yoluyla elde bulundurulmayan iştirak yatırımının kalan kısmına özkaynak yöntemi uygulanır. [SİLİNEN: "yatırım amaçlı sigorta fonlarını kapsayan" ifadeleri.] YÜRÜRLÜK TARİHİ VE GEÇİŞ PARAGRAF 45M (EKLENDİ) - Temmuz 2026'da yayımlanan İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler, 18 ve 19 uncu paragrafları değiştirmiştir. İşletme bu değişiklikleri, TFRS 18'i uyguladığında TFRS 18'in C7 paragrafı uyarınca uygular.
'@
$yeni2 = @'
[PARAGRAF 18 — SİLİNEN: "girişim sermayesi kuruluşu"ndan sonraki "veya"; "yatırım ortaklığı"ndan sonraki "ve yatırım amaçlı sigorta fonlarını kapsayan"; "benzer işletmeler"deki "-ler" eki; "Yatırım amaçlı sigorta fonlarına örnek olarak, doğrudan katılım özelliği bulunan sigorta sözleşmeleri grubuna ilişkin dayanak kalem olarak işletme tarafından elde tutulan bir fon verilebilir." cümlesi; "Bu tercihin amaçları açısından, sigorta sözleşmeleri isteğe bağlı katılım özelliği bulunan yatırım sözleşmelerini içerir." cümlesi; "(Bu paragrafta kullanılan terimlerin tanımları için TFRS 17 Sigorta Sözleşmeleri'ne bakınız.)" cümlesi. EKLENEN: "kuruluşu"ndan sonraki virgül; "yatırım ortaklığı"ndan sonraki "veya"; "Benzer işletmeler, belirlenmiş ana faaliyetleri belirli varlık türlerine yatırım yapmak olan işletmeleri içerir (bakınız: TFRS 18 paragraf 49(a))." cümlesi. "yatırım fonu" ifadesi silinmemiştir, yerinde kalır.] PARAGRAF 19 (YENİ HÂLİ) - İşletmenin, bir kısmı girişim sermayesi kuruluşu, yatırım fonu, yatırım ortaklığı veya benzer işletme yoluyla dolaylı olarak elde tutulan iştirak yatırımına sahip olması durumunda işletme, iştirak yatırımının bu kısmını TFRS 9 uyarınca gerçeğe uygun değer farkı kâr veya zarara yansıtılan olarak ölçmeyi seçebilir. Bu durumda girişim sermayesi kuruluşu yatırım fonu, yatırım ortaklığı veya benzer işletmenin, yatırımın söz konusu bu kısmı üzerinde önemli etkisinin bulunup bulunmadığı dikkate alınmaz. İşletmenin böyle bir seçimde bulunması halinde, girişim sermayesi kuruluşu yatırım fonu, yatırım ortaklığı veya benzer işletme yoluyla elde bulundurulmayan iştirak yatırımının kalan kısmına özkaynak yöntemi uygulanır. [PARAGRAF 19 — SİLİNEN (üç yerde): "fon" önündeki "veya"; "ve yatırım amaçlı sigorta fonlarını kapsayan"; "benzer işletmeler/işletmelerin"deki "-ler" eki. EKLENEN: "fon" önüne "yatırım" ve sonuna "-u" (yatırım fonu); birinci ve üçüncü yerde "yatırım ortaklığı"ndan sonra "veya"; birinci yerde "kuruluşu"ndan sonra virgül; ikinci yerde "işletme"ye "-n" eki (benzer işletmenin). Resmî metinde ikinci ve üçüncü yerde "kuruluşu"ndan sonra virgül yoktur.] Yürürlük tarihi ve geçiş PARAGRAF 45M (EKLENDİ) - Temmuz 2026'da yayımlanan İştiraklerdeki ve İş Ortaklıklarındaki Yatırımlarda Gerçeğe Uygun Değer Seçeneğine İlişkin Değişiklikler, 18 ve 19 uncu paragrafları değiştirmiştir. İşletme bu değişiklikleri, TFRS 18'i uyguladığında TFRS 18'in C7 paragrafı uyarınca uygular.
'@
$metin3 = @'
İşletmenin TFRS 18'i, TFRS 18'in C1 paragrafı uyarınca daha önceki bir dönem için uygulamayı tercih etmiş olması ve söz konusu önceki dönemin bu değişikliklerin yayımlanmasından önce başlaması durumunda işletme, değişiklikleri TFRS 18'in C7 paragrafı uyarınca, değişikliklerin yayımlandığı tarihte veya sonrasında sona eren raporlama dönemi için uygular.
'@
$duzeltmeler = @(
  @{ ad = "${adKok}1"; eski = $eski1.Trim(); yeni = $yeni1.Trim() }
  @{ ad = "${adKok}2"; eski = $eski2.Trim(); yeni = $yeni2.Trim() }
  @{ ad = "${adKok}3"; eski = $metin3.Trim(); yeni = $metin3.Trim() }
)
# resmî metinde bulunması / bulunmaması gereken ifadeler — yeni metinlerin öz-sınavı
$yeniTum = ($duzeltmeler | ForEach-Object { $_.yeni }) -join ' '
foreach ($olmali in @('bir yatırım; bir girişim sermayesi kuruluşu, yatırım fonu, yatırım ortaklığı veya benzer işletme yoluyla', 'değer değişimi kâr veya zarara', 'kuruluşu, yatırım fonu, yatırım ortaklığı veya benzer işletme yoluyla dolaylı olarak elde tutulan iştirak yatırımına sahip')) {
  if (-not $yeniTum.Contains($olmali)) { throw "ÖZ-SINAV: yeni metinde yok: $olmali" } }
foreach ($olmamali in @('bu işletmeler tarafından', 'iştirak veya iş ortaklığı yatırımına', 'kâr ya da zarara', 'bir yatırımın;', 'hâlinde', 'VEYA', 'YATIRIM fonu', 'SİLİNEN: "yatırım fonu"')) {
  if ($yeniTum.Contains($olmamali)) { throw "ÖZ-SINAV: yeni metinde olmamalı: $olmamali" } }

# 1) ÖN KONTROL — hepsi tutmazsa hiçbir şey yazılmaz
$depo = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = New-Object System.Collections.Generic.List[object]
foreach ($dz in $duzeltmeler) {
  $kayit = @($depo.belgeler | Where-Object { $_.kaynak_ad -eq $dz.ad })
  $satir = @((Invoke-RestMethod -Uri "$tabloAdr`?select=id,metin&kaynak_ad=eq.$([uri]::EscapeDataString($dz.ad))" -Headers $basliklarSb -TimeoutSec 120) | ForEach-Object { $_ })
  $durumDepo = $(if ($kayit.Count -ne 1) { "kayıt $($kayit.Count)" } elseif ($kayit[0].metin -ceq $dz.yeni) { 'yeni' } elseif ($kayit[0].metin -ceq $dz.eski) { 'eski' } else { 'FARKLI' })
  $durumAmbar = $(if ($satir.Count -ne 1) { "satır $($satir.Count)" } elseif ("$($satir[0].metin)" -ceq $dz.yeni) { 'yeni' } elseif ("$($satir[0].metin)" -ceq $dz.eski) { 'eski' } else { 'FARKLI' })
  Write-Host ("  {0} | depo {1} · ambar {2} · uzunluk {3} → {4}" -f $dz.ad.Substring($dz.ad.Length - 7), $durumDepo, $durumAmbar, $dz.eski.Length, $dz.yeni.Length)
  if ($durumDepo -eq 'yeni' -and $durumAmbar -eq 'yeni') { Write-Host "    zaten yazılı (depo + ambar) — atlandı"; continue }
  if ($durumDepo -notin @('eski', 'yeni') -or $durumAmbar -notin @('eski', 'yeni')) { throw "ÖN KONTROL TUTMADI: $($dz.ad) — hiçbir şey yazılmadı" }
  $plan.Add([pscustomobject]@{ dz = $dz; id = "$($satir[0].id)"; ambarYaz = ($durumAmbar -eq 'eski'); depoYaz = ($durumDepo -eq 'eski') })
}
if (-not $Uygula) { "KURU: $($plan.Count) düzeltme hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — depo + ambar, yedek, geri okuma
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
foreach ($p in $plan) {
  $dz = $p.dz
  if ($p.ambarYaz) {
    $ambar = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
    if ($ambar -cne $dz.eski) { throw "YAZMADAN ÖNCE ambar değişmiş: $($dz.ad)" }
    $yedekAd = ($dz.ad -replace '[^\w\-]+', '_'); [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').txt"), $ambar, (New-Object Text.UTF8Encoding $false))
    $govde = ConvertTo-Json -InputObject @{ metin = $dz.yeni } -Compress
    Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
    $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
    if ($geri -cne $dz.yeni) { throw "GERİ OKUMA TUTMADI: $($dz.ad)" }
    Write-Host "  AMBAR YAZILDI + geri okundu (birebir, $($geri.Length) karakter): $($dz.ad)"
  }
  if ($p.depoYaz) { ($depo.belgeler | Where-Object { $_.kaynak_ad -eq $dz.ad }).metin = $dz.yeni }
}
[IO.File]::WriteAllText($depoDosya, (ConvertTo-Json -InputObject $depo -Depth 5), (New-Object Text.UTF8Encoding $false))
$depoGeri = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($dz in $duzeltmeler) { if (@($depoGeri.belgeler | Where-Object { $_.kaynak_ad -eq $dz.ad -and $_.metin -ceq $dz.yeni }).Count -ne 1) { throw "DEPO GERİ OKUMA TUTMADI: $($dz.ad)" } }
"UYGULANDI: $($plan.Count) düzeltme (depo + ambar), depo dosyası geri okundu"
