# Yurt dışına aktarım: yol seçimi — 14.09.2026

> Cem 14.09: "yurt dışı aktarım için yol seçelim" (GM önerisi 2). Hukuki görüş değildir; kaynaklar dipte.
> Rakamlar kaynağıyla; ölçülmeyen "ölçülmedi" yazar.

## 0. Önce kendi yanlışımı düzeltiyorum

Daha önce "AB'deki bir sağlayıcıya geçelim, sorun kalmaz" gibi konuştum. **Yanlıştı.** KVKK'da
Türkiye dışındaki her ülke yurt dışıdır; AB'nin ayrıcalığı yok. Kurul'un yayımladığı bir
yeterlilik kararı bulamadım. Bu yüzden İrlanda'daki Supabase veritabanı da, Finlandiya'daki GoatCounter da
m.9 kapsamında. kvkk.html 6. bölüm "ABD'deki sağlayıcılar" diye yazıyordu; bu turda
"İrlanda, Almanya ve Finlandiya dahil" diye düzeltildi. **14.09 ek düzeltme:** veritabanı Almanya'da değil **İrlanda'da** (AWS eu-west-1). Veritabanı adresinin IPv6 öneki AWS'nin resmî adres listesinde eu-west-1'e düşüyor; 20.08 panel ölçümü de aynı. Sunucu fonksiyonları ise Frankfurt'ta çalışıyor (`x-sb-edge-region: eu-central-1` başlığı).

## 1. Bugün ne nereye gidiyor (ölçülmüş hâl, kvkk.html v2 tablosu)

| Sağlayıcı | Ülke | Giden kişisel veri | Ağırlık |
|---|---|---|---|
| Supabase | İrlanda (veritabanı), Almanya (fonksiyonlar) | **Hepsi**: üyelik, e-posta, firma izleme, sonuçlar, formlar, soru çözme kayıtları | 🔴 çekirdek |
| Resend | ABD | Mail adresi + mail içeriği (karne, uyarı, form bildirimi) | 🟠 sürekli |
| GitHub Pages | ABD | Ziyaretçinin IP'si ve tarayıcı bilgisi (her web sunucusu gibi) | 🟡 teknik |
| GoatCounter | Finlandiya/Almanya | Konum için IP (saklamıyor), tarayıcı bilgisi | 🟡 teknik |
| Anthropic / OpenRouter | ABD | Kullanıcının yazdığı soru metni (içine kişisel bilgi yazabilir) | 🟡 metne bağlı |

## 2. Kanunun bıraktığı yollar (7499 sonrası m.9)

1. **Yeterlilik kararı**: bulamadım, bizim elimizde değil.
2. **Standart sözleşme**: Kurul'un metni, **Türkçe metin üzerinde iki tarafın da imzası**. Metin değiştirilemez,
   yalnız seçimli maddeler değişir. İmza yetki belgesi gerekir; yabancı belge için apostil ve noter onaylı çeviri
   gerekebilir. **İmzadan sonra 5 iş günü içinde** Kurum'a bildirilir: fiziki olarak, KEP ile ya da
   Standart Sözleşme Bildirim Modülü'nden (standartsozlesme.kvkk.gov.tr).
3. **Bağlayıcı şirket kuralları / yazılı taahhüt**: grup şirketi ya da Kurul izni ister, bize uymaz.
4. **Arızi aktarım (açık rıza vb.)**: yalnız tekrarlanmayan aktarım için. Veritabanı gibi sürekli akış buna dayanamaz.

**Çekirdek sorun:** 2. yol karşı tarafın **Türkçe metni imzalamasını** ister. Supabase, Resend ve Anthropic
AB standart sözleşmesi (SCC) sunuyor, Türk metnini değil. Büyük bir ABD sağlayıcısının Türk metnini imzaladığına
dair kamuya açık örnek bulamadım. Microsoft'a aynı soru soruldu (10.11.2025), doğrudan cevap verilmedi.
**Bizim sağlayıcılara henüz sorulmadı, sonuç ölçülmedi.**

**Ceza aralıkları, 2026 (yeniden değerlenmiş):** standart sözleşmeyi bildirmemek **90.308 – 1.806.377 TL**.
Hukuka aykırı aktarım veri güvenliği ihlali sayılırsa **256.357 – 17.092.242 TL**.

## 3. Seçenekler ve bedeli

| | A. Olduğu yerde kal + sözleşme iste | B. Tamamen Türkiye'ye taşın | **C. Kademeli (önerim)** |
|---|---|---|---|
| Ne yapılır | 5 sağlayıcıya Türk standart sözleşmesi gönderilir. İmzalayan olursa 5 iş günü içinde modülden bildirilir. | Veritabanı, üyelik ve fonksiyonlar İzmir'de bir sunucuda kendi kurduğumuz Supabase'e taşınır. Mail yerli sağlayıcıdan, site ve sayaç aynı sunucudan çıkar. | **1)** A'yı hemen başlat. **2)** Kişisel veriyi yurt dışına göndermeyi bırak: soru metnini maskele, site/sayaç IP'si için kararı ver. **3)** Supabase 30 gün içinde imzalamazsa yalnız çekirdeği (veritabanı + mail) Türkiye'ye taşı. |
| Doğrudan para | ~0 TL. Modül ücretsiz. KEP gerekirse yıllık ücret ölçülmedi. | Sunucu: Alastyr Cloud-8G, 4 vCPU / 8 GB, İzmir, **2.011,55 TL/ay KDV dahil ≈ 24.100 TL/yıl**. Yedek sunucu ve depolama ayrıca, ölçülmedi. Yerli işlemsel mail fiyatı ölçülmedi (Uzman Posta fiyat vermiyor). | 1-2. adım ~0 TL. 3. adıma gelinirse B'nin çekirdek bedeli: ~24 bin TL/yıl + mail. |
| Emek | Birkaç saat yazışma | **Haftalar**: üyelik ve şifre özetleri taşınır, 4 fonksiyon Deno sunucusuna geçer, yedek/güncelleme/güvenlik bizde. | 1-2: 1 gün. 3: haftalar, ama yalnız gerekirse. |
| Uyum sonucu | İmzalanırsa tam. **İmzalanmazsa değişen bir şey olmaz.** | Tam; yalnız soru metni için Anthropic kalır, maskelemeyle kapanır. | İmza gelirse A kadar tam; gelmezse B'ye iner, parayı yalnız o gün harcarız. |
| Risk | Sağlayıcı cevap vermez, zaman geçer. | **Güvenlik olgunluğu düşer.** Supabase'in yönettiği yamayı, yedeği ve saldırı korumasını biz yaparız. "Müşteri verisi güvenli yerde" kuralıyla çatışır. Kesinti riski bizde. | Karar noktası tarihli, sessiz uzamaz. |

## 4. Önerim: C, tarihleriyle

1. **Bu hafta (0 TL):**
   - Supabase, Resend, GitHub, GoatCounter ve Anthropic'e Kurul'un "veri sorumlusundan veri işleyene" standart sözleşmesi, Türkçe metinle gider.
   - Net Cevap'a gönderimden önce maskeleme eklenir: TCKN, VKN, telefon ve e-posta kalıpları gizlenir. Böylece Anthropic/OpenRouter satırı "kişisel veri gitmez" olur.
   - **Mail gönderimi Cem onayıyla yapılır.**
2. **30 gün sonra (14.10.2026) karar:** Supabase imzaladıysa modülden 5 iş günü içinde bildir, bitti.
   İmzalamadıysa taşıma planı bedeliyle Cem'e gelir. İlk ücretli öğrenci ya da İYS kampanyasından önce çekirdek yurt içinde olur.
3. **Metin:** kvkk.html 6. bölüm, hangi yol seçildiyse o gün güncellenir ("süreç yürütülmektedir" cümlesi kalkar).

**Neden B'yi hemen önermiyorum:** 24 bin TL/yıl ucuz. Ama asıl bedel güvenlik ve bakım. Bugün kasada 69 cevap,
8 kâğıt, 3 form, 0 öğrenci sonucu var. Risk küçükken haftalarca taşıma işine girip güvenliği zayıflatmak
yanlış sıra olur. Veri büyümeden, yani ücretli öğrenci gelmeden önce karar verilir.

## 5. Ek ölçüm, 14.09 ("1.2.3 üçüne de bak")

### 5.1 Sözleşme metni neden imzalatılması zor bir metin
Kurul'un resmî Standart Sözleşme 2 metnini (TR + Kurum'un İngilizce çevirisi) okudum. Veri alıcısına şu yükleri koyuyor:
- **Madde 12:** Kurul'un yetkisine tabi olmak, istenen belgeyi vermek, **gerekirse yerinde incelemeye izin vermek**.
- **Madde 13:** "Ülkemde bu sözleşmeyle çelişen mevzuat ya da uygulama yok" diye beyan etmek. ABD'li bir şirketin bunu
  kendi ülkesinde kamu makamlarının veriye erişim yetkileri varken beyan etmesi zor.
- **Madde 7.9(c-d):** veri aktaranın, yani bizim, **yerinde denetimine** izin vermek.
- **Madde 11(b):** ilgili kişiye doğrudan tazminat sorumluluğu.
- **Madde 17-18:** Türk hukuku ve **Türk mahkemeleri**.

Supabase ve Resend'in kendi sözleşmelerinde bunların yerine AB/İngiltere/İsviçre mekanizmaları var. **Sonuç: imzalamamaları
güçlü ihtimal. Bu, belgelerden gelen tahmin; ölçüm maille gelir.** Taslaklar hazır, git dışında duruyor:
`_yerel-veri-kasasi/sozlesmeler/kvkk-standart-sozlesme-2026/`. İçinde resmî PDF'ler, Supabase ve Resend için Ek I-II-III ve
İngilizce kapak mailleri var. **Gönderilmedi.**

### 5.2 Türkiye'de barındırma: ölçülen seçenekler
| Seçenek | Ne var | Fiyat (kaynak) | Not |
|---|---|---|---|
| **AWS İstanbul Local Zone** (`eu-central-1-ist-1a`) | 20.05.2026'da açıldı (AWS duyurusu). EC2, EBS, S3 One Zone-IA, ECS, EKS. **Yönetilen veritabanı (RDS) listede yok** | m7i.large (2 vCPU/8 GB) **0,1268 USD/saat ≈ 92,6 USD/ay**; disk ve trafik ayrıca, ölçülmedi (aws-pricing.com, 12.09.2026) | Ana bölge Frankfurt. Türkiye'deki hesapların sözleşme tarafı **AWS Turkey Ltd. Şti.** (AWS SSS). Veri Türkiye'de durur, güvenlik altyapısı AWS'nin. **Açık soru:** uzaktan yönetim ve destek erişimi yurt dışı aktarım sayılır mı? Hukuken tartışmalı |
| **Alastyr bulut sunucu, İzmir** | 4 vCPU / 8 GB / 120 GB NVMe | **2.011,55 TL/ay KDV dahil** (Alastyr sayfası) | Yerli şirket, yerli veri merkezi. Güvenlik ve yama tamamen bizde |
| Turkcell Bulut / Türk Telekom Bulut | Yönetilen ilişkisel veritabanı var denmiş | **Fiyat yayımlanmıyor**, teklif gerekir | Kurumsal satış süreci |

Üç seçenekte de Supabase'i kendimiz kurarız (açık kaynak, Docker) ya da düz Postgres ve kendi üyelik sistemimize geçeriz.
Taşıma emeği haftalar (bkz. bölüm 3).

### 5.3 Yerli işlemsel mail
| Sağlayıcı | Türkiye'de mi | SMTP/API | Fiyat (kaynak) |
|---|---|---|---|
| **SenderTR** (Alastyr Telekomünikasyon A.Ş., İzmir) | "Tüm sunucular Türkiye'de" (kendi sayfası) | SMTP 587 + REST API, işlemsel ayrı IP havuzu | **10.000 kredi 1.050 TL · 100.000 kredi 5.900 TL · 250.000 kredi 12.750 TL**, KDV hariç, süresiz (kendi sayfası, 14.09) |
| Uzman Posta İşlemsel | Türkiye lokasyonu (kendi sayfası) | SMTP + API | Yayımlanmıyor, teklif gerekir |
| Euromsg Express | Şirket İstanbul'da; veri merkezi yazmıyor | API | Sayfada fiyat yok |

**Ölçülen tercih: SenderTR.** Türkiye'de tutma sözü, SMTP ve API desteği ve açık fiyatı olan tek sağlayıcı bu.
Aylık gönderim hacmimiz ölçülmedi; Resend panelinden okunur. Kaç kredilik paketin yeteceği bu sayıyla hesaplanır.
Krediler süresiz olduğu için en küçük paket (1.050 TL) deneme için yeterli. Resend'den geçiş: 24 dosyada `api.resend.com` çağrısı var.
Tek bir ortak gönderici yazılıp hepsi ona bağlanır. **Teklif ya da üyelik açmak Cem kararı** (hesap açma ve ödeme ben yapamam).

## Kaynaklar
- KVKK, standart sözleşmelerde dikkat edilecek hususlar: https://www.kvkk.gov.tr/Icerik/8170/
- KVKK, Standart Sözleşme Bildirim Modülü duyurusu (17.10.2024 açıldı): https://www.kvkk.gov.tr/Icerik/8043/
- 2026 ceza tutarları (%25,49 yeniden değerleme): https://www.cottgroup.com/tr/mevzuat/item/yeniden-degerleme-oranina-gore-2026-yili-kvkk-idari-para-cezalari
- Türk SCC ≠ AB SCC, değiştirilemez metin: https://istanbullawyerfirm.com/blog/kvkk-cross-border-data-transfers-standard-contracts-notification-guide-2025
- Microsoft Q&A, Azure için KVKK standart sözleşmesi: https://learn.microsoft.com/en-us/answers/questions/5615914/
- Supabase DPA'sı AB SCC içerir: https://github.com/orgs/supabase/discussions/2341
- Sunucu fiyatı (Alastyr Cloud-8G, İzmir): https://www.alastyr.com/sunucu-fiyatlari
- Yerli işlemsel mail (fiyat yayımlanmıyor): https://uzmanposta.com/islemsel-e-posta/
- Kurul standart sözleşmeleri (TR): https://www.kvkk.gov.tr/Icerik/7929/Standart-Sozlesmeler · (EN): https://www.kvkk.gov.tr/Icerik/7991/Standard-Contracts
- AWS İstanbul Local Zone duyurusu: https://aws.amazon.com/about-aws/whats-new/2026/05/aws-local-zones-istanbul-turkiye/
- AWS Türkiye sözleşme tarafı SSS: https://aws.amazon.com/legal/awstr/
- İstanbul Local Zone fiyatları: https://aws-pricing.com/eu-central-1-ist-1.html
- SenderTR: https://sendertr.com/
- Supabase DPA: https://supabase.com/legal/dpa · Resend DPA: https://resend.com/legal/dpa
