# Yurt dışına aktarım: yol seçimi — 14.09.2026

> Cem 14.09: "yurt dışı aktarım için yol seçelim" (GM önerisi 2). Hukuki görüş değildir; kaynaklar dipte.
> Rakamlar kaynağıyla; ölçülmeyen "ölçülmedi" yazar.

## 0. Önce kendi yanlışımı düzeltiyorum

Daha önce "AB'deki bir sağlayıcıya geçelim, sorun kalmaz" gibi konuştum. **Yanlıştı.** KVKK'da
Türkiye dışındaki her ülke yurt dışıdır; AB'nin ayrıcalığı yok. Kurul'un yayımladığı bir
yeterlilik kararı bulamadım. Bu yüzden Almanya'daki Supabase de, Finlandiya'daki GoatCounter da
m.9 kapsamında. kvkk.html 6. bölüm "ABD'deki sağlayıcılar" diye yazıyordu; bu turda
"Almanya ve Finlandiya dahil" diye düzeltildi.

## 1. Bugün ne nereye gidiyor (ölçülmüş hâl, kvkk.html v2 tablosu)

| Sağlayıcı | Ülke | Giden kişisel veri | Ağırlık |
|---|---|---|---|
| Supabase | Almanya | **Hepsi**: üyelik, e-posta, firma izleme, sonuçlar, formlar, soru çözme kayıtları | 🔴 çekirdek |
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

## Kaynaklar
- KVKK, standart sözleşmelerde dikkat edilecek hususlar: https://www.kvkk.gov.tr/Icerik/8170/
- KVKK, Standart Sözleşme Bildirim Modülü duyurusu (17.10.2024 açıldı): https://www.kvkk.gov.tr/Icerik/8043/
- 2026 ceza tutarları (%25,49 yeniden değerleme): https://www.cottgroup.com/tr/mevzuat/item/yeniden-degerleme-oranina-gore-2026-yili-kvkk-idari-para-cezalari
- Türk SCC ≠ AB SCC, değiştirilemez metin: https://istanbullawyerfirm.com/blog/kvkk-cross-border-data-transfers-standard-contracts-notification-guide-2025
- Microsoft Q&A, Azure için KVKK standart sözleşmesi: https://learn.microsoft.com/en-us/answers/questions/5615914/
- Supabase DPA'sı AB SCC içerir: https://github.com/orgs/supabase/discussions/2341
- Sunucu fiyatı (Alastyr Cloud-8G, İzmir): https://www.alastyr.com/sunucu-fiyatlari
- Yerli işlemsel mail (fiyat yayımlanmıyor): https://uzmanposta.com/
