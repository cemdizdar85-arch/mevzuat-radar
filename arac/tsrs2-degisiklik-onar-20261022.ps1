#requires -Version 5.1
# ============================================================================
#  TSRS 2 DEĞİŞİKLİKLERİ (RG 28.07.2026-33323) — ambar kaydı resmî metne uyduruldu   22.10.2026 · BEDEL 0
#
#  NEDEN: "TSRS 2 Degisiklikleri - Sera Gazi Emisyonlarinin Aciklanmasi (RG 28.07.2026-33323) m.29 [1/9]…[9/9]"
#    kayıtları RG 33323 Kurul Kararı (KGK, Karar No 75935942-050.01.04-[01/44275], 22/07/2026) ekindeki metinle
#    satır satır karşılaştırıldı (altı çizili = eklenen, üstü çizili = silinen; sayfa görüntüsünden doğrulandı).
#    ESAS SAPMA:
#    (1) B24 ilk cümle: ambarda "işletme, ... Standardını (2004) kullanmaya zorunlu tutulmaz" yazıyordu — ANLAM TERS.
#        Resmî metin (değişmeyen gri metin): "... Standardını (2004) kullanmakla zorunlu tutulmuştur."
#    BİÇİM / SÖZCÜK SAPMALARI (anlam değiştirmeyen, aynı yazımda birebire çekildi):
#    (2) B24 ikinci cümle "Yetkili makam" → "Yetkili bir makam"; B28 "aşağıdakileri açıklar" → "aşağıdakileri de açıklar",
#        "neden veya nedenleri" → "nedeni veya nedenleri"; B59 "emisyonlar da dâhil" → "emisyonları da dâhil";
#        29(a)(ii) "işletmenin, sera" virgülü; B62(b)/B63(b) "TFRS'lere" → "Türkiye Finansal Raporlama Standartlarına";
#        B62A(a) "işletme:" → "işletme;"; C4(b) "emisyonlara … emisyonları (Bkz." → "emisyonlarına … emisyonlarını (Bkz.";
#        C6(a) "karşılaştırma bilgileri" → "karşılaştırmalı bilgileri".
#    (3) Büyük harfli vurgular (TAMAMI VEYA BİR KISMI İÇİN, 1 OCAK 2027…, ERKEN UYGULAMAYA…) resmî yazımla küçültüldü.
#    (4) "[SİLİNEN: … GICS … KALDIRILMIŞTIR …]" özetleri, kararda üstü çizili metnin BİREBİR yazımıyla değiştirildi.
#    (5) Künye eklendi ([1/9] başı): karar no/tarih, Konu, karar cümlesi resmî metinden.
#    [7/9] (B63A) ve [9/9] (C6(b) sonu, C6(c)) resmî metinle aynı — dokunulmaz.
#    kaynak_url: anlamsız "https://www.mevzuat.gov.tr/mevzuatmetin/HAZIR.pdf" → RG PDF'i.
#  RESMÎ KAYNAK: https://www.resmigazete.gov.tr/eskiler/2026/07/20260728-7.pdf (RG 28.07.2026 sayı 33323) okundu.
#  TSRS 2 standart kayıtlarına DOKUNULMAZ (değişiklik 1 Ocak 2027 ve sonrası dönemler için; erken uygulama serbest).
#  YÖNTEM: tms28-degisiklik-onar-20261022.ps1 ile aynı (depo + ambar, ön kontrol, yedek, geri okuma, "zaten yazılı"
#    atlaması). Eski metin, betiğe gömülü SHA-256 ile tanınır (depo ve ambar AYNI eski metni taşımalı). -Uygula yoksa KURU.
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
$depoDosya = Join-Path $depoKok 'veri\mevzuat\kgk-tsrs2-degisiklik-2026.json'
$adKok = 'TSRS 2 Degisiklikleri - Sera Gazi Emisyonlarinin Aciklanmasi (RG 28.07.2026-33323) m.29 '
$eskiUrl = 'https://www.mevzuat.gov.tr/mevzuatmetin/HAZIR.pdf'
$yeniUrl = 'https://www.resmigazete.gov.tr/eskiler/2026/07/20260728-7.pdf'
$sha = [Security.Cryptography.SHA256]::Create()
function Ozet([string]$m) { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($m)) | ForEach-Object { $_.ToString('x2') }) }

$yeni = @{}
$yeni[1] = @'
TSRS 2'DE YAPILAN DEĞİŞİKLİKLER: SERA GAZI EMİSYONLARININ AÇIKLANMASINA İLİŞKİN DEĞİŞİKLİKLER Resmî Gazete: 28 Temmuz 2026 SALI, Sayı: 33323 - KURUL KARARI Kamu Gözetimi, Muhasebe ve Denetim Standartları Kurumundan Karar No: 75935942-050.01.04-[01/44275] Karar Tarihi: 22/07/2026 Konu: TSRS 2'de Yapılan Değişiklikler: Sera Gazı Emisyonlarının Açıklanmasına İlişkin Değişiklikler. 660 sayılı Kanun Hükmünde Kararnamenin 9'uncu maddesi uyarınca; uluslararası standartlara uyum sağlamak üzere, Uluslararası Sürdürülebilirlik Standartları Kurulu tarafından "Amendments to IFRS S2: Amendments to Greenhouse Gas Emissions Disclosures" başlığıyla yapılan değişikliklerin mevzuata kazandırılması amacıyla "TSRS 2'de Yapılan Değişiklikler: Sera Gazı Emisyonlarının Açıklanmasına İlişkin Değişiklikler"in yayımlanmasına karar verilmiştir. AMBAR NOTU (karar metninin parçası değildir): Bu belge TSRS 2'yi DEĞİŞTİREN metindir. 29(a)(ii), 29(a)(vi)(2), B21-B22, B24, B28, B37, B59, B62(a), B63(a) ve C4(b) paragrafları değiştirilmiş; 29A-29C, B62A, B63A, C1A-C1B ve C6 paragrafları eklenmiştir. B62(a)(i) ve B63(a)(i) silinmiş; B62(a)(ii) ve B63(a)(ii) B62A(b) ile B63A(b) olarak yeniden numaralandırılmıştır. Aşağıda paragrafların YENİ hâli resmî metinden yazılmıştır; kararda üstü çizili gösterilen silinen ifadeler paragrafın ardından köşeli parantezle birebir belirtilmiştir. MADDE 29 - İklimle ilgili metrikler (değişen hükümler) MADDE 29(a)(ii) (YENİ HÂLİ) - Yetkili bir makam veya işletmenin kote olduğu borsa, işletmenin, sera gazı emisyonlarının tamamı veya bir kısmı için farklı bir yöntem kullanarak ölçmesini zorunlu kılmadıkça, Sera Gazı Protokolü: Kurumsal Muhasebe ve Raporlama Standardına (2004) uygun olarak ölçer (Bkz. B23-B25 paragrafları). [SİLİNEN: "kullanılarak ölçülmesini". EKLENEN: "işletmenin,"; "tamamı veya bir kısmı için".] MADDE 29(a)(vi)(2) (YENİ HÂLİ) - İşletme faaliyetlerinin varlık yönetimi, ticari bankacılık veya sigortacılık faaliyetlerini içermesi durumunda, işletmenin (Kategori 15 sera gazı emisyonlarının bir parçası olan) finanse edilen emisyonları hakkında ilave bilgiler (Bkz. B58-B63A paragrafları). [SİLİNEN: "Kategori 15 sera gazı emisyonları veya yatırımlarıyla ilişkili olanlar (finanse edilen emisyonlar)"; "B63". EKLENEN: "(Kategori 15 sera gazı emisyonlarının bir parçası olan) finanse edilen emisyonları"; "B63A".] MADDE 29A (EKLENDİ) - 29(a)(i)(3) paragrafındaki hükmü yerine getirmek üzere açıklamaları hazırlarken işletmenin, Kapsam 3 Kategori 15 sera gazı emisyon ölçümüne dâhil ettiklerini yalnızca finanse edilen emisyonlarıyla sınırlamasına izin verilir. Diğer bir ifadeyle, işletmenin, Kategori 15 sera gazı emisyonlarını, yatırım yapılanlara veya karşı taraflara kullandırdığı kredi ve yaptığı yatırımlarla ilişkilendirilen emisyonlarla sınırlamasına izin verilir. "Krediler ve yatırımlar"; kredileri, proje finansmanını, tahvilleri, özkaynak yatırımlarını ve çekilmemiş kredi taahhütlerini içerir. Varlık yönetimi faaliyetlerinde bulunan bir işletme için finanse edilen emisyonlar, yönetilen varlıklarla ilişkilendirilen sera gazı emisyonlarını içerir. Bu sınırlama kapsamında işletmenin, türev araçlarla ilişkilendirilebilen sera gazı emisyonlarını hariç tutmasına izin verilir.
'@
$yeni[2] = @'
MADDE 29B (EKLENDİ) - 29A paragrafındaki sınırlamayı uygulaması durumunda işletme; (a) Genel amaçlı finansal rapor kullanıcılarının söz konusu sınırlamanın nasıl uygulandığını anlamalarını sağlamak amacıyla neleri türev araç olarak kabul ettiğini açıklar. Örneğin işletme, bu sınırlamayı uygularken, ilgili finansal tablolarının hazırlanmasında kullanılan TFRS'lerdeki veya geçerli diğer genel kabul görmüş muhasebe ilkelerindeki (GKGMİ) türev araç tanımını karşılayan kalemleri türev araç olarak kabul ettiğini açıklayabilir. (b) 29A paragrafının uygulanması sonucunda, türev araçlarla ilişkili faaliyetler de dâhil olmak üzere, Kapsam 3 Kategori 15 sera gazı emisyon ölçümünden hariç tuttuğu finansal faaliyetleri tanımlar. MADDE 29C (EKLENDİ) - 29(a)(i)(3) paragrafı uyarınca açıklanan Kapsam 3 sera gazı emisyon ölçümüne Kategori 15 sera gazı emisyonlarını dâhil etmesi durumunda işletme, toplam Kategori 15 sera gazı emisyonlarını ve bu toplam içerisinde yer alan finanse edilen emisyonların ara toplamını açıklar. EK B - UYGULAMA REHBERİ (değişen hükümler) B21 (SONUNA EKLENEN CÜMLELER; önceki metin değişmedi) - ... Bu tür küresel ısınma potansiyeli değerlerinin kullanılmasına ilişkin zorunluluk; yetkili bir makam veya işletmenin kote olduğu borsa, yedi sera gazı bileşeninin CO2 eşdeğerine dönüştürülmesinde (işletmenin tamamı veya bir kısmı için) farklı küresel ısınma potansiyeli değerlerinin kullanılmasını zorunlu kılmadıkça uygulanır. Böyle bir durumda işletmenin, söz konusu zorunluluk ilgili kısım için yürürlükte olduğu sürece, yetkili makam veya borsa tarafından zorunlu kılınan küresel ısınma potansiyeli değerlerini kullanmasına izin verilir. B22 (SONUNA EKLENEN CÜMLELER; önceki metin değişmedi) - ...
'@
$yeni[3] = @'
(B22 sonuna eklenen cümleler) Bu tür küresel ısınma potansiyeli değerlerinin kullanılmasına ilişkin zorunluluk; yetkili bir makam veya işletmenin kote olduğu borsa, yedi sera gazı bileşeninin CO2 eşdeğerine dönüştürülmesinde (işletmenin tamamı veya bir kısmı için) farklı küresel ısınma potansiyeli değerlerinin kullanılmasını zorunlu kılmadıkça uygulanır. Böyle bir durumda işletmenin, söz konusu zorunluluk ilgili kısım için yürürlükte olduğu sürece, yetkili makam veya borsa tarafından zorunlu kılınan küresel ısınma potansiyeli değerlerini kullanmasına izin verilir. B24 (YENİ HÂLİ) - Yetkili bir makam veya işletmenin kote olduğu borsa tarafından sera gazı emisyonlarının tamamı veya bir kısmı için farklı bir yöntem kullanılarak ölçülmesi zorunlu kılınmadıkça, işletme, Sera Gazı Protokolü: Kurumsal Muhasebe ve Raporlama Standardını (2004) kullanmakla zorunlu tutulmuştur. Yetkili bir makam veya işletmenin kote olduğu borsa tarafından sera gazı emisyonlarının tamamı veya bir kısmı için farklı bir yöntem kullanılarak ölçülmesinin zorunlu tutulması durumunda, söz konusu zorunluluk işletme için geçerli olduğu sürece, işletmenin söz konusu zorunluluğun uygulandığı kısmı için Sera Gazı Protokolü: Kurumsal Muhasebe ve Raporlama Standardı (2004) yerine söz konusu farklı yöntemi kullanmasına izin verilir. [EKLENEN: iki yerde "tamamı veya bir kısmı için"; "söz konusu zorunluluğun uygulandığı kısmı için".] B28 (YENİ HÂLİ) - İşletme, 29(a)(ii), B24-B25 veya C4(a) paragrafları uyarınca başka bir yönteme göre ölçülen sera gazı emisyonlarını açıkladığında, kullanılan her bir alternatif yöntem için aşağıdakileri de açıklar: (a) İşletmenin sera gazı emisyonlarını belirlemek için kullandığı geçerli yöntem ile ölçüm yaklaşımı ve (b) İşletmenin yöntem ile ölçüm yaklaşımını seçmesinin nedeni veya nedenleri ile bu yaklaşımın 27 nci paragrafta yer alan açıklama amacıyla ne şekilde ilişkili olduğu. [EKLENEN: "kullanılan her bir alternatif yöntem için".]
'@
$yeni[4] = @'
B37 (YENİ HÂLİ) - Varlık yönetimi, ticari bankacılık ve sigortacılıkla ilgili bir veya daha fazla finansal faaliyette bulunan bir işletme, Kapsam 3 sera gazı emisyonlarına ilişkin açıklamasının bir parçası olarak, bu faaliyetlerle ilişkili finanse edilen emisyonlar hakkında ilave bilgi açıklar (Bkz. B58-B63A paragrafları). [SİLİNEN: "B63". EKLENEN: "B63A".] B59 (YENİ HÂLİ) - 29(a)(i)(3) paragrafı, bir işletmenin, yukarı ve aşağı yönlü emisyonları da dâhil olmak üzere, raporlama döneminde üretilen mutlak brüt Kapsam 3 sera gazı emisyonlarını açıklamasını zorunlu kılar. Aşağıdaki finansal faaliyetlerden bir veya daha fazlasını yürüten bir işletme, (Kategori 15 sera gazı emisyonlarının bir parçası olan) finanse edilen emisyonları hakkında ilave ve özellikli bilgileri açıklamakla zorunlu kılınmıştır: (a) Varlık yönetimi (Bkz. B61 paragrafı), (b) Ticari bankacılık (Bkz. B62-B62A paragrafları) ve (c) Sigortacılık (Bkz. B63-B63A paragrafları). [SİLİNEN: "Kategori 15 emisyonları veya yatırımlarıyla ilişkili emisyonları ("finanse edilen emisyonlar" olarak da bilinmektedir)". EKLENEN: "(Kategori 15 sera gazı emisyonlarının bir parçası olan) finanse edilen emisyonları"; "-B62A"; "-B63A".] B62 - Ticari bankacılık (YENİ HÂLİ) - Ticari bankacılık faaliyetlerinde bulunan bir işletme aşağıdakileri açıklar: (a) Varlık sınıfına göre her sektör için Kapsam 1, Kapsam 2 ve Kapsam 3 sera gazı emisyonlarına göre ayrıştırılmış mutlak brüt finanse edilen emisyonlar. [SİLİNEN: "İşletme;" ile (i) "Sektöre göre ayrıştırma yaparken sınıflandırma sisteminin raporlama tarihinde mevcut olan en son sürümünü yansıtacak şekilde; karşı tarafları sınıflandırmak için, Küresel Endüstri Sınıflandırma Standardı (GICS) 6-haneli endüstri-seviyesi kodu kullanır," ve (ii) "Varlık sınıfına göre ayrıştırma yaparken yapılan açıklama; kredileri, proje finansmanını, tahvilleri, sermaye yatırımlarını ve çekilmemiş kredi taahhütlerini içerir. Diğer varlık sınıfları için finanse edilen emisyonları hesaplaması ve açıklaması durumunda işletme, ilave varlık sınıflarının dâhil edilmesinin genel amaçlı finansal raporların kullanıcılarına neden ihtiyaca uygun bilgi sağladığına dair bir izahı da dâhil eder." Eski (ii), B62A(b) olarak yeniden numaralandırılmıştır.] (b) Varlık sınıfına göre her sektöre ilişkin brüt risk tutarı, işletmenin finansal tablolarının sunulduğu para birimi cinsinden ifade edilir.
'@
$yeni[5] = @'
Bu kapsamda: (i) Finanse edilen tutarlar için brüt risk, Türkiye Finansal Raporlama Standartlarına veya diğer genel kabul görmüş muhasebe ilkelerine göre hazırlanıp hazırlanmadığına bakılmaksızın, finanse edilen defter değerleri olarak (uygulanabilir olması durumunda, zarar karşılığı düşülmeden) hesaplanır. (ii) Çekilmemiş kredi taahhütleri için işletme, taahhüdün tamamını kredi taahhütlerinin çekilmiş kısmından ayrı olarak açıklar. B62A (EKLENDİ) - B62(a)-(b) paragrafı uyarınca açıklanan bilgileri: (a) Sektöre göre ayrıştırırken işletme; (i) Genel amaçlı finansal rapor kullanıcılarının işletmenin iklimle ilgili geçiş risklerine maruz kalma durumunu anlamalarını sağlayacak bilgiler sunacak şekilde, yatırım yapılanların veya karşı tarafların sınıflandırılmasına imkân veren bir sektör sınıflandırma sistemi seçer. Diğer işletmeler (örneğin aynı sektörde veya coğrafyada faaliyet gösterenler) tarafından yaygın olarak kullanılan bir sistem (yaygın kullanılan sistem), yalnızca işletme tarafından kullanılan bir sisteme (işletmeye özgü sistem) kıyasla bilgilerin karşılaştırılabilirliğini daha fazla destekleyecektir. Yaygın kullanılan sistemin -diğer her şey eşit olduğunda- işletmenin iklimle ilgili geçiş risklerine maruz kalma durumu hakkında faydalı bilgiler sağlamasına imkân vermesi durumunda, işletme söz konusu sisteme öncelik verir. Hem ticari bankacılık hem de sigortacılık faaliyetlerinde bulunan bir işletmenin, ticari bankacılık ve sigortacılık faaliyetleri için, yatırım yapılanları veya karşı tarafları sınıflandırırken aynı sistemi kullanması zorunlu değildir (Bkz. B63A(a)(i) paragrafı).
'@
$yeni[6] = @'
(ii) Aşağıdakileri açıklar: (1) Yatırım yapılanları veya karşı tarafları sınıflandırmak için kullandığı sektör sınıflandırma sistemini ve (2) Genel amaçlı finansal rapor kullanıcılarının, işletmenin söz konusu sistemi seçmesinin B62A(a)(i) paragrafındaki hükümleri nasıl yerine getirdiğini anlamalarını sağlayacak bilgileri. (b) Varlık sınıfına göre ayrıştırırken; yapılan açıklama; kredileri, proje finansmanını, tahvilleri, özkaynak yatırımlarını ve çekilmemiş kredi taahhütlerini içerir. Diğer varlık sınıfları için finanse edilen emisyonları hesaplaması ve açıklaması durumunda işletme, ilave varlık sınıflarının dâhil edilmesinin genel amaçlı finansal rapor kullanıcılarına neden ihtiyaca uygun bilgi sağladığına dair bir izahı da dâhil eder. B63 - Sigortacılık (YENİ HÂLİ) - Sigortacılık sektörüyle bağlantılı finansal faaliyetlerde bulunan bir işletme aşağıdakileri açıklar: (a) Varlık sınıfına göre her sektör için Kapsam 1, Kapsam 2 ve Kapsam 3 sera gazı emisyonlarına göre ayrıştırılmış mutlak brüt finanse edilen emisyonlar. [SİLİNEN: "İşletme;" ile (i) "Sektöre göre ayrıştırma yaparken sınıflandırma sisteminin raporlama tarihinde mevcut olan en son sürümünü yansıtacak şekilde; karşı tarafları sınıflandırmak için, Küresel Endüstri Sınıflandırma Standardı (GICS) 6-haneli endüstri-seviyesi kodu kullanır." ve (ii) "Varlık sınıfına göre ayrıştırma yaparken yapılan açıklama; kredileri, tahvilleri, sermaye yatırımlarını ve çekilmemiş kredi taahhütlerini içerir. Diğer varlık sınıfları için finanse edilen emisyonları hesaplaması ve açıklaması durumunda işletme, ilave varlık sınıflarının dâhil edilmesinin genel amaçlı finansal raporların kullanıcılarına neden ihtiyaca uygun bilgi sağladığına dair bir izahı da dâhil eder." Eski (ii), B63A(b) olarak yeniden numaralandırılmıştır.] (b) Varlık sınıfına göre her sektöre ilişkin brüt risk tutarı, işletmenin finansal tablolarının sunulduğu para birimi cinsinden ifade edilir. Bu kapsamda; (i) Finanse edilen tutarlar için brüt risk, Türkiye Finansal Raporlama Standartlarına veya diğer genel kabul görmüş muhasebe ilkelerine göre hazırlanıp hazırlanmadığına bakılmaksızın, finanse edilen defter değerleri olarak (uygulanabilir olması durumunda, zarar karşılığı düşülmeden) hesaplanır. (ii) Çekilmemiş kredi taahhütleri için işletme, taahhüdün tamamını kredi taahhütlerinin çekilmiş kısmından ayrı olarak açıklar.
'@
$yeni[8] = @'
EK C - Yürürlük tarihi ve geçiş C1A (EKLENDİ) - Temmuz 2026'da yayımlanan Sera Gazı Emisyon Açıklamalarına İlişkin Değişiklikler: (a) 29(a)(ii), 29(a)(vi)(2), B21-B22, B24, B28, B37, B59, B62(a), B63(a) ve C4(b) paragraflarını değiştirmiş ve (b) 29A-29C, B62A, B63A, C1B ve C6 paragraflarını eklemiştir. C1B (EKLENDİ) - İşletme C1A paragrafında listelenen değişiklikleri 1 Ocak 2027 tarihinde veya sonrasında başlayan raporlama dönemleri için uygular. Erken uygulamaya izin verilir. Söz konusu değişiklikleri erken uygulaması durumunda işletme, bu durumu açıklar. C4(b) (YENİ HÂLİ) - İşletmenin; varlık yönetimi, ticari bankacılık veya sigortacılık faaliyetlerinde bulunması durumunda, finanse edilen emisyonlarına ilişkin ilave bilgileri içeren Kapsam 3 sera gazı emisyonlarını (Bkz. 29(a)(vi)(2) ve B58-B63A paragrafları) açıklaması zorunlu değildir (Bkz. 29(a) paragrafı). [SİLİNEN: "B63". EKLENEN: "B63A".] C6 (EKLENDİ) - Sera Gazı Emisyon Açıklamalarına İlişkin Değişiklikler İçin Geçiş - Daha önceden TSRS 2'yi uygulamış olması durumunda işletme, Sera Gazı Emisyon Açıklamalarına İlişkin Değişiklikler'i ilk kez uyguladığı yıllık raporlama döneminde -uygulama açısından mümkün olmama durumu hariç- önceki döneme ait karşılaştırmalı bilgileri aşağıdaki şekilde düzeltir: (a) İşletmenin 29(a)(ii) ve B24 paragraflarındaki veya B21-B22 paragraflarındaki muafiyeti uygulaması sonucu sera gazı emisyonlarını ölçme yöntemini değiştirmiş olması durumunda; karşılaştırmalı bilgileri, sera gazı emisyonlarını ölçme yöntemini söz konusu önceki dönemde değiştirmiş gibi düzeltir, (b) İşletmenin önceki dönemde Kapsam 3 sera gazı emisyonlarını açıklamış olması ve bu emisyonların ölçümünün Kategori 15 sera gazı emisyonlarını içermesi durumunda; karşılaştırmalı bilgileri, 29C paragrafındaki hükmü söz konusu önceki dönemde uygulamış gibi, toplam
'@
# eski metinlerin SHA-256'sı (22.10.2026 ambar = depo); [7/9] ve [9/9] metni değişmez, yalnız kaynak_url
$eskiOzet = @{
  1 = 'b6189489becde4c4bd10f6baedf1fcdf4026cdb6c6cd5387aa6b104c6d5c904b'; 2 = '27614bc5281a63ae4fa935b249fe3056317bef6374e9fd0e77e38a507625c12f'
  3 = 'ffe64959922e2e7d6b72b277a82fe2dd3a3da42cbd81e494c9e36c7d44ec5716'; 4 = 'e29f5a1d5d25c78901c6affad3b64c6a864457b0fd82b1059b27269ad94da947'
  5 = 'ef92fbd68c5b0e4dcbf08c78eebb56ad6339807047f72fbcf8b2e7d797351fe3'; 6 = 'ccf1981a55a3ad0ffb0ea1ff6fe0f9eeaafda669feba66677618fd1cbff743e6'
  7 = '175db2e5dad071e237c406d99fc36f80a880a8a36d5193144529db446723abc0'; 8 = '46a978b631eff702b792927b4b0624162e03f7b9a9b3eb2bdda5dbe94ae0fab8'
  9 = '10cc6703fafec9e9a58e65269cdba12e202a4f753171ec0463c428a0aad7899e'
}

# 0) ÖZ-SINAV — yeni metinlerde bulunması / bulunmaması gerekenler (resmî metinden)
$yeniTum = (($yeni.Keys | Sort-Object) | ForEach-Object { $yeni[$_].Trim() }) -join ' '
foreach ($olmali in @('Standardını (2004) kullanmakla zorunlu tutulmuştur.', 'aşağıdakileri de açıklar:', 'seçmesinin nedeni veya nedenleri', 'yukarı ve aşağı yönlü emisyonları da dâhil',
    'Küresel Endüstri Sınıflandırma Standardı (GICS) 6-haneli endüstri-seviyesi kodu kullanır,', '1 Ocak 2027 tarihinde veya sonrasında başlayan raporlama dönemleri için uygular. Erken uygulamaya izin verilir.',
    '75935942-050.01.04-[01/44275]', 'Karar Tarihi: 22/07/2026', 'işletmenin, sera gazı emisyonlarının tamamı veya bir kısmı için', 'Yetkili bir makam veya işletmenin kote olduğu borsa tarafından sera gazı emisyonlarının tamamı veya bir kısmı için farklı bir yöntem kullanılarak ölçülmesinin',
    'finanse edilen emisyonlarına ilişkin ilave bilgileri içeren Kapsam 3 sera gazı emisyonlarını (Bkz.', 'karşılaştırmalı bilgileri, sera gazı emisyonlarını ölçme')) {
  if (-not $yeniTum.Contains($olmali)) { throw "ÖZ-SINAV: yeni metinde yok: $olmali" } }
foreach ($olmamali in @('kullanmaya zorunlu tutulmaz', 'KALDIRILMIŞTIR', 'TAMAMI VEYA', 'OCAK 2027', 'ERKEN', 'neden veya nedenleri', 'emisyonlar da dâhil', "TFRS'lere", 'karşılaştırma bilgileri', 'Yetkili makam veya işletmenin', 'aynı istisna', 'DEĞİŞEN KISIM')) {
  if ($yeniTum.Contains($olmamali)) { throw "ÖZ-SINAV: yeni metinde olmamalı: $olmamali" } }
if (($yeniTum.Split('[').Count - 1) -ne ($yeniTum.Split(']').Count - 1)) { throw 'ÖZ-SINAV: köşeli parantez dengesiz' }

# 1) ÖN KONTROL — hepsi tutmazsa hiçbir şey yazılmaz
$depo = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = New-Object System.Collections.Generic.List[object]
foreach ($no in 1..9) {
  $ad = "$adKok[$no/9]"
  $hedef = $(if ($yeni.ContainsKey($no)) { $yeni[$no].Trim() } else { $null })
  $kayit = @($depo.belgeler | Where-Object { $_.kaynak_ad -eq $ad })
  $satir = @((Invoke-RestMethod -Uri "$tabloAdr`?select=id,metin,kaynak_url&kaynak_ad=eq.$([uri]::EscapeDataString($ad))" -Headers $basliklarSb -TimeoutSec 120) | ForEach-Object { $_ })
  if ($kayit.Count -ne 1 -or $satir.Count -ne 1) { throw "ÖN KONTROL TUTMADI: $ad — depo $($kayit.Count) / ambar $($satir.Count) kayıt" }
  function Durum($metin, $url) {
    $m = $(if ((Ozet $metin) -eq $eskiOzet[$no]) { 'eski' } elseif ($hedef -and $metin -ceq $hedef) { 'yeni' } else { 'FARKLI' })
    $u = $(if ($url -ceq $yeniUrl) { 'yeni' } elseif ($url -ceq $eskiUrl) { 'eski' } else { 'FARKLI' })
    if (-not $hedef -and $m -eq 'eski') { $m = 'ayni' }
    [pscustomobject]@{ metin = $m; url = $u } }
  $dd = Durum "$($kayit[0].metin)" "$($kayit[0].kaynak_url)"; $da = Durum "$($satir[0].metin)" "$($satir[0].kaynak_url)"
  Write-Host ("  [{0}/9] depo metin {1}/url {2} · ambar metin {3}/url {4} · uzunluk {5} → {6}" -f $no, $dd.metin, $dd.url, $da.metin, $da.url, "$($satir[0].metin)".Length, $(if ($hedef) { $hedef.Length } else { '=' }))
  foreach ($d in @($dd, $da)) { if ($d.metin -eq 'FARKLI' -or $d.url -eq 'FARKLI') { throw "ÖN KONTROL TUTMADI: $ad — hiçbir şey yazılmadı" } }
  $ambarYaz = ($da.metin -eq 'eski' -or $da.url -eq 'eski'); $depoYaz = ($dd.metin -eq 'eski' -or $dd.url -eq 'eski')
  if (-not $ambarYaz -and -not $depoYaz) { Write-Host '    zaten yazılı (depo + ambar) — atlandı'; continue }
  $plan.Add([pscustomobject]@{ no = $no; ad = $ad; id = "$($satir[0].id)"; hedef = $hedef; eskiAmbar = "$($satir[0].metin)"; ambarYaz = $ambarYaz; depoYaz = $depoYaz })
}
if (-not $Uygula) { "KURU: $($plan.Count) kayıt hazır, öz-sınav + ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — yedek, ambar PATCH, geri okuma, depo
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
foreach ($p in $plan) {
  $sonMetin = $(if ($p.hedef) { $p.hedef } else { $p.eskiAmbar })
  if ($p.ambarYaz) {
    $simdi = @(Invoke-RestMethod -Uri "$tabloAdr`?select=metin,kaynak_url&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0]
    if ("$($simdi.metin)" -cne $p.eskiAmbar) { throw "YAZMADAN ÖNCE ambar değişmiş: $($p.ad)" }
    $yedekAd = ($p.ad -replace '[^\w\-]+', '_')
    [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').txt"), "kaynak_url: $($simdi.kaynak_url)`r`n$($simdi.metin)", (New-Object Text.UTF8Encoding $false))
    $govdeNesne = @{ kaynak_url = $yeniUrl }; if ($p.hedef) { $govdeNesne.metin = $p.hedef }
    $govde = ConvertTo-Json -InputObject $govdeNesne -Compress
    Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
    $geri = @(Invoke-RestMethod -Uri "$tabloAdr`?select=metin,kaynak_url&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0]
    if ("$($geri.metin)" -cne $sonMetin -or "$($geri.kaynak_url)" -cne $yeniUrl) { throw "GERİ OKUMA TUTMADI: $($p.ad)" }
    Write-Host "  AMBAR YAZILDI + geri okundu (birebir, $("$($geri.metin)".Length) karakter, url RG): $($p.ad)"
  }
  if ($p.depoYaz) { $k = $depo.belgeler | Where-Object { $_.kaynak_ad -eq $p.ad }; $k.metin = $sonMetin; $k.kaynak_url = $yeniUrl }
}
[IO.File]::WriteAllText($depoDosya, (ConvertTo-Json -InputObject $depo -Depth 5), (New-Object Text.UTF8Encoding $false))
$depoGeri = Get-Content $depoDosya -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($no in 1..9) {
  $ad = "$adKok[$no/9]"; $k = @($depoGeri.belgeler | Where-Object { $_.kaynak_ad -eq $ad })
  if ($k.Count -ne 1 -or $k[0].kaynak_url -cne $yeniUrl) { throw "DEPO GERİ OKUMA TUTMADI: $ad" }
  if ($yeni.ContainsKey($no) -and $k[0].metin -cne $yeni[$no].Trim()) { throw "DEPO GERİ OKUMA TUTMADI (metin): $ad" }
  if (-not $yeni.ContainsKey($no) -and (Ozet $k[0].metin) -ne $eskiOzet[$no]) { throw "DEPO GERİ OKUMA TUTMADI (değişmemesi gereken metin): $ad" }
}
"UYGULANDI: $($plan.Count) kayıt (depo + ambar), depo dosyası geri okundu"
