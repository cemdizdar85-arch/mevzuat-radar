# CEM'İN İSTEK LİSTESİ — 10.11.2026

> Kaynak: Cem'in 10.11.2026 tarihli brifinin 5. bölümü ("Cem'in ekleyecekleri") ve aynı günkü konuşma.
> Amaç: hiçbir istek kaybolmasın. Her oturum işini **buradan** alır, bitince satırın durumunu günceller.
> Yeni düzenin taslağı: [`BASIM-ONCESI-DUZEN-TASLAK.md`](../../BASIM-ONCESI-DUZEN-TASLAK.md) (aşağıda "D" ile anılır).
>
> **Durum sözlüğü:** `PLANDA` = taslakta maddesi var, yapılmadı · `KISMEN VAR` = depoda bir parçası kurulu ·
> `PLAN YAZILDI` = bu dosyada nasıl yapılacağı yazılı, yapılmadı · `AYRI İŞ` = soru kalitesi dışı, kendi kolunda yürür ·
> `CEM KARARI` = Cem cevaplamadan ilerlemez. Hiçbir satır "yapıldı" değildir; yapılan satıra tarih ve ölçü yazılır.
>
> **Para:** bu listedeki hiçbir iş onaysız para harcamaz. Basım freni (07.11) yerindedir; freni yalnız Cem kaldırır.

---

## A · Yanlış soru çıkmasın

| No | İstek | Durum | Nerede |
|---|---|---|---|
| A-01 | Yanlış soru bir daha çıkmasın; soruda, cevapta, anlatımda, kanun maddesinde, derste, konuda hata olmasın | PLANDA (D1–D9). Sıfır hata sözü verilmedi; verilen söz taslağın 4. bölümünde | sinav · sgs · kgk |
| A-02 | Eski (değişmiş, mülga) kanundan soru basılmasın | PLANDA (D3 kaynak kapısı) | sinav |
| A-03 | Kanun değişince o kanuna bağlı sorular geri alınsın | PLANDA (D4: kart kırmızıya döner, bağlı sorular iner) | sinav · altyapi |
| A-04 | Okunmamış mevzuat, kanun, kitap varsa önce okunsun; okunmadıysa soru basılmasın ve "bu konuda soru basmadık" diye Cem uyarılsın | PLANDA (D3 + panelde "basılmayan konular") | sinav · site |
| A-05 | Mevzuat Resmî Gazete'den ve kanunun kendisinden okunsun, başka sitelerden değil | PLANDA (D3). Ambardaki her kaynağın nereden yutulduğu ÖLÇÜLMEDİ | altyapi |
| A-06 | Model her basımda kendi kafasına göre gitmesin; yalnız verilen kanun ve çıkmış sorulardan yazsın (sıfır bilgi kuralı) | PLANDA (D1 + D2: anlatım karttan gelir, model yeniden yazmaz) | sinav |
| A-07 | Kanunu olmayan dersler (matematik, İngilizce, Türkçe) nasıl basılacak | PLAN YAZILDI: matematikte cevabı kod hesaplar; dil derslerinde iki bağımsız çözücü aynı şıkkı bulmazsa soru basılmaz; kalıp yalnız çıkmış sorudan | sgs |
| A-08 | 20 soru basılıyor 6'sı düşüyor; bu basmadan önce çözülsün | PLANDA (D3 + D8; kanıt dalgası hedefi: düşen en çok %10) | sinav |
| A-09 | Çıkmış sorular ve kanunlar okutuldu ama hâlâ hata çıkıyor; tümden engellensin | Kök neden taslağın 1. bölümünde | sinav |
| A-10 | Sorunun dersi ve konusu yanlış olmasın; site hem ders ders hem konu konu çözdürebilsin | KISMEN VAR (A3 konu kartı, ders-etiket denetimi). Yayındaki bankada oran ÖLÇÜLMEDİ | sinav · site |
| A-11 | Sorular birbirinin kopyası olmasın; bilgi, hesap, istisna, kural ihlali senaryosu gibi çeşit olsun | KISMEN VAR (B7, B22, B30, KAPI-IK) | sinav |

## B · Yıl kuralı

| No | İstek | Durum | Nerede |
|---|---|---|---|
| B-01 | "2026 sınavı 2025 verisini sorar": eski sınavlarda tam olarak nasıl yapıldığı öğrenilsin, kural olarak yazılsın | KISMEN VAR (B27, B28, `yillik-tutarlar.json`; 28.10'da bitirme Vergi için ölçüldü). SGS ve KGK için ayrı ölçüm YAPILMADI | sinav · sgs · kgk |
| B-02 | 2027'ye geçince bütün sorular tek seferde 2026 kanun ve tutarlarına çekilebilsin | PLANDA (D5 yıl parametresi) | sinav |

## C · Çıkmış soruyu çözmek, sınava benzemek

| No | İstek | Durum | Nerede |
|---|---|---|---|
| C-01 | Çıkmış sorular en ince ayrıntısına kadar incelensin: soru kalıbı, cevap kalıbı, uzunluk, olumlu/olumsuz kök, çeldirici mantığı, zorlama biçimi | KISMEN VAR (sınav profili 27.10, KGK kalıp tablosu 03.11, B30). SGS ve Yeterlilik için konu başı kalıp tablosu ÖLÇÜLMEDİ | sinav · sgs · kgk |
| C-02 | Hangi konudan çok soru çıkıyorsa sitede o konudan çok soru olsun (ders ders, konu konu ağırlık) | KISMEN VAR (kapsama tablosu, sıklık sırası). Sitedeki dağılımın sınav dağılımına oranı panelde gösterilecek | sinav · site |
| C-03 | Çeldiriciler adayın en sık düştüğü hatalardan kurulsun; sınavdaki uzunlukta olsun | KISMEN VAR (B6, B7, Ş1–Ş10) | sinav |
| C-04 | Hiç sorulmamış ama sorulabilecek konular bulunsun; oradan da soru basılsın | PLAN YAZILDI: kart maddeleri çıkmış sorularla eşlenir; hiç sorulmayan madde, tek açıdan sorulan konu listelenir; soru ancak Cem listeyi görünce basılır. Okuma işi, 0 USD, hak harcar | sinav |
| C-05 | Sınavda ilk kez sorulan konular nasıl girmiş, hangi mantıkla; "sorulmamışı sorma taktiği" çıkarılsın | PLAN YAZILDI: son üç yılın ilk kez giren konuları listelenir, giriş biçimi (kalıp, zorluk, hangi açı) yazılır | sinav |
| C-06 | "Bu konuyu hep X açısından sormuşlar, Y açısından hiç sormamışlar" listesi | PLAN YAZILDI (C-04 ile aynı ölçüm) | sinav |
| C-07 | Sorulmuş ama ambarda metni olmayan kanun, tebliğ varsa "eksik/okunmayan kanun" diye raporlansın | KISMEN VAR (`YET-S20-KAYNAK-EKSIK.md`, ambar envanteri). Üç sınavın tamamı için ÖLÇÜLMEDİ | altyapi |
| C-08 | Soru yazanların taktiği çözülsün; bizden çalışan öğrenci o taktiği bilerek sınava girsin | PLAN YAZILDI: her konu kartında "bu konuda böyle düşürürler" satırı; çıkmış sorudan sayılarak yazılır | sinav · site |
| C-09 | Çıkmış sorular ders ders, konu konu "ezberlensin" (her basımda elde olsun) | KISMEN VAR (ambar `cikmis-soru`, 309 bitirme kartı) | sinav |
| C-10 | Bitirme sınavı teste döndü; yazılı sorulardan çevirdiğimiz sorular iyi çevrilmiş mi, atlanan var mı | PLAN YAZILDI: örneklem gerçek test dönemi sorularıyla kök uzunluğu, kalıp, çeldirici açısından kıyaslanır; ölçüm 0 USD, onarım bedeli sonuca göre | sinav |
| C-11 | Çıkmış soru kopyalanmasın, mantığı alınsın | VAR (A1, B29, KAPI-A1). Bulut yazımında bu kapı KOŞMUYOR | sinav |

## D · Anlatım ve öğretme

| No | İstek | Durum | Nerede |
|---|---|---|---|
| D-01 | Soru çözen kişiye konu yalın ve doğru anlatılsın; yanında öğretmen varmış gibi; muhasebe bilmeyen de anlasın | PLANDA (D2 kart + D7 anlatım standardı) | sinav · site |
| D-02 | Her şıkkın açıklaması olsun; yanlış şıkkı seçene neden yanlış olduğu öğretilsin | KISMEN VAR (şık açıklamaları, karne). Standart D7'de | sinav · site |
| D-03 | Çözüm yalnız cevabı vermesin; kanunun mantığını, istisnayı, formülü ve kısa yolu anlatsın | PLANDA (D7) | sinav |
| D-04 | Hiç bilmeyen kişi zor soruyla başlayınca kaçıyor | PLAN YAZILDI: yeni üyeye ilk sorular en sık konunun en kısa köklü sorularından; üç doğrudan sonra gerçek sınav düzeyi. 12.10'da kurulan bitirme sırası yeniden ele alınır | site |
| D-05 | Çözüm sonrası anlatım insanları sıkıyor, üye olanlar çıkıyor; sıkmasın, eğlenceli olsun, bir daha gelsin | PLAN YAZILDI: günlük kısa hedef, seri sayacı, konu kapatma işareti, uzun metin yerine tek görsel; tek derste denenir, geri gelme oranı ölçülür | site |
| D-06 | Anlatım görsel olsun: tablo, daire, şekil; siteye yakışsın | KISMEN VAR (çizerek çöz KGK 1.145 soru; "tek görselde çözüm" kuralı 06.11) | site · sinav |
| D-07 | Anlatım gelir tablosu ve bilanço üstünden yapılsın; telefonda anlaşılsın | KISMEN VAR (yevmiye şeması, hesap tablosu). Kaç soruda olduğu ÖLÇÜLMEDİ | sinav · site |
| D-08 | Soruyu ve çözümü sesli anlatan biri olsun | KISMEN VAR (10 KGK soruda ses pilotu 22.10). Ses işi abonelik kredisiyle anlatılır | site |
| D-09 | Soruyu gerçek öğretmen gibi çizerek anlatan olsun | KISMEN VAR (çizerek çöz pilotu) | site |
| D-10 | Site "yapay zekâ yapıyor" havası vermesin; sorular gerçek bir üstadın sorusu gibi olsun | KISMEN VAR (B9 izler). Ekran dili ayrıca gözden geçirilecek | sinav · site |

## E · Site ve satış

| No | İstek | Durum | Nerede |
|---|---|---|---|
| E-01 | Site kullanışlı değil; üye olmayı, ödemeyi, ne yapacağını kimse anlamıyor | AYRI İŞ | site |
| E-02 | Kurumsal ve kolay anlaşılır bir görünüm (büyük e-ticaret siteleri gibi yalın) | AYRI İŞ | site |
| E-03 | "Satın al" düğmesi için renk ve yer denemesi yapılsın, ölçüyle karar verilsin | AYRI İŞ. Ziyaret sayısı deneme için yeterli mi, önce o ölçülür | site · pazarlama |
| E-04 | Satış kötü; nasıl artar, müşteri nasıl çekilir | AYRI İŞ | pazarlama |
| E-05 | Yurt dışındaki güçlü rakipten daha iyi olmak; onlarda olup bizde olmayan ve satış getiren özellikler | AYRI İŞ. 06.11 kıyas raporu DOĞRULANMADI, iş emri değil | site · pazarlama |
| E-06 | Öğrencinin soru çözmeye bayıldığı, alanın çok beğendiği, en çok sınav kazandıran site | Hedef. Ölçüsü: geri gelme oranı, üye başına çözülen soru, sınav sonucu bildirimi | hepsi |
| E-07 | Kaliteden hiçbir şekilde ödün verilmesin | Kural (B21) | hepsi |

## F · Paneller

| No | İstek | Durum | Nerede |
|---|---|---|---|
| F-01 | Cem'in yaptırdığı işleri takip edeceği site paneli | PLAN YAZILDI: fren durumu · konu başına sınav sıklığı / sitedeki soru / kaynak tam mı / kart onaylı mı · basılmayan konular ve nedeni · üye hata bildirimleri · harcama · bekleyen Cem kararları | site |
| F-02 | Uygulama mağazalarına (Apple, Play) güncellemeyi kolaylaştıran panel | PLAN YAZILDI: sürüm, inceleme durumu, tek tuşla gönderim; mevcut `mobil-android` ve `mobil-ios` hatlarının üstüne ekran. Mağaza incelemesini hızlandırmaz | altyapi · site |

## G · Para, hız, yeni sınavlar

| No | İstek | Durum | Nerede |
|---|---|---|---|
| G-01 | API harcaması azalsın; az harcayıp çok soru basılsın; daha hızlı olsun | PLANDA: anlatım konu başına bir kez yazılır, düşen soru azalır. Rakam kanıt dalgasından çıkar; şimdi rakam verilmez | sinav |
| G-02 | Eski yazılmış sorular yeni kalıba az parayla ve çabuk uyarlansın | PLANDA (D9: yeniden basım değil, karta bağlama) | sinav · sgs · kgk |
| G-03 | Yeni sınavlar: YMM, SPK lisanslama, bağımsız denetim ve benzerleri | Sıra kanıt dalgasından sonra. SPK için 19.10 araştırması var (çıkmış soru yayımlanmıyor). YMM için arşiv ÖLÇÜLMEDİ | spk · sinav |

## H · Çalışma biçimi

| No | İstek | Durum |
|---|---|---|
| H-01 | Bütün isteklerden tek bir kural oluşsun; birlikte yazılsın | Taslak yazıldı, Cem onayı bekliyor |
| H-02 | Kafana uymayan bir şey varsa sor, beni yönlendir, yanlış yönlendirme | Her teslimde "kafama uymayan" bölümü |
| H-03 | Atladığımız, aklıma gelmeyen bir şey varsa söyle | Her teslimde "sormadığın ama gördüğüm" bölümü |
| H-04 | "Söz ver, yanlış soru basılmayacak" | Sıfır hata sözü verilmedi. Verilen dört söz taslağın 4. bölümünde |

---

## CEM KARARLARI (10.11.2026: "bunlara onay verdim")

1. Konu kartı düzeni: ONAYLANDI.
2. Kart onayı: onaylandı, ama "Cem örneklem mi okur, meslektaş mı okur" seçimi AÇIK; Cem'e yeniden soruldu.
3. Kanıt dalgası: tek ders, tavan 25 USD ONAYLANDI. Ders önerisi ölçümden: Muhasebe Denetimi
   ([`OLCUM-BASIM-ONCESI-1011.md`](OLCUM-BASIM-ONCESI-1011.md)). Basım freni ayrıca Cem'in açık sözüyle açılır; bu onay freni kaldırmaz.
4. Soru kalitesi ile site ve çözüm ekranı işi iki oturumda aynı anda: ONAYLANDI.
5. Resmî metni olmayan konularda (oran analizi, dikey analiz, trend analizi gibi) kaynak **çıkmış sınav sorusu ve komisyon cevabı** sayılır:
   ONAYLANDI (10.11, "Evet, çıkmış soru"). Kural taslağı D3'e işlendi.

### Hâlâ açık sorular (cevap gelene kadar her teslimde yeniden sorulur)

- Kartları kim onaylayacak: Cem örneklem mi okur, meslektaş mı okur?
- İlk 6 Denetim kartı okundu mu; dil yalın mı, biçim uygun mu?
- Kalan 13 Denetim kartı aynı biçimde yazılsın mı?
- Ölçekli tekrar sorusu doğruluğu ölçülene kadar sitede kapatılsın mı?
- Site ve çözüm ekranı işi için ikinci oturum açıldı mı?

## SIRA

1. Bu liste ve taslak (10.11, yazıldı).
2. 0 USD ölçüm: ekrana basılan alanların tam envanteri · bir dersin kartlarının kaynak durumu · C-04/C-06 · C-10.
3. Cem onayıyla kanıt dalgası.
4. Aynı anda ayrı oturumda: D-04, D-05, F-01, F-02.
