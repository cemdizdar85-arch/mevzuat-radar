# Kampanya: 17 Ekim canlı deneme — Meta reklam planı

> 09.10.2026, Cem: **"1.500 TL verdim günlük."** Bütçe kararı Cem'in; bu dosya o bütçeyle kampanyanın nasıl kurulacağını ve ne zaman durdurulacağını yazar.
> Ön şart: site açık (perde kalkmış) + Pixel ID + alan adı Meta'da doğrulanmış (bkz. `pazarlama/META-REKLAM-KURULUM.md`). Bunlar yokken reklam YOK (29.09 kararı).

## 1 · Bütçenin alabileceği şey (dürüst hesap)

- 15 gün × 1.500 TL = **22.500 TL**. 17 Ekim'e kadar reklam en fazla 7 gün çalışır (Pixel bugün kurulursa) = 10.500 TL; sonrası 24 Ekim Yeterlilik provasına.
- Üye başı maliyet ÖLÇÜLMEDİ. Varsayımla 30–100 TL arası ise 22.500 TL'den **225–750 ücretsiz üye** gelir. **5.000 üye hedefi bu bütçeyle reklamdan gelmez**; gelirse organik + gruplar + deneme sonuç kartının yayılmasından gelir. 48 saat sonra gerçek rakamla yeniden hesaplanır.
- Başabaş (ödeyen müşteri): 2.988 TL − KDV − komisyon ≈ 2.400 TL. Müşteri başı reklam maliyeti bunun altında kaldıkça kârlı.

## 2 · Kurulum (Meta Ads Manager)

| Alan | Değer |
|---|---|
| Kampanya hedefi | Leads (potansiyel müşteri) · dönüşüm olayı **Lead** (Pixel `donusum.js`: `content_name = canli-deneme` / `seviye-testi`) |
| Günlük bütçe | **1.500 TL**, kampanya düzeyinde (Advantage campaign budget), iki reklam seti eşit başlar |
| Yer | Türkiye · 20–32 yaş · Instagram Reels + Feed + Stories, Facebook Feed (Audience Network KAPALI) |
| Kitle 1 (ilgi) | muhasebe, mali müşavirlik, finansal muhasebe, SMMM, staj, TESMER, iktisat/işletme mezunu (ilgi alanı olarak; metinde kurum adı YOK) |
| Kitle 2 (benzer) | 3. günden itibaren: "Lead: seviye-testi" olayından %1 benzer kitle (Meta en az ~100 olay ister; gelene kadar Kitle 1) |
| Dil | Türkçe |
| Takip | her bağlantı `?k=reklam` (sitede kaynak sayacı) + Meta UTM: `utm_source=meta&utm_campaign=17ekim` |

## 3 · Reklamlar (A/B, metinler `reklam-17-ekim-canli-deneme.md`, kapı YEŞİL)

| Reklam | Görsel | Metin | Bağlantı |
|---|---|---|---|
| A · Deneme | ders kartı `rontgen-ders/ders-ticaret-hukuku.png` (32/32) + ekran yazısı "17 EKİM · 10:00 · ÜCRETSİZ" | Metin 1 (uzun) | `tetikte.com/canli-deneme.html?k=reklam` |
| B · Ürün | `urun-ekran/urun-1-dikey-yuzde.png` ("Yanlış yaptın. Nedenini anında gör.") | Metin 2 (kısa) | `tetikte.com/canli-deneme.html?k=reklam` |

Her ikisinde "Reklam" ibaresi metinde; maskot YOK → yapay zekâ etiketi gerekmez. Maskotlu video reklama girerse etiket zorunlu (`_sablon.md`).

## 4 · Ölçüm ve durdurma kuralları (her sabah 09:00, Claude yazar)

Günlük satır: `dün harcama · tıklama · Lead(canli-deneme) · Lead(seviye-testi) · üye (site sayacı ?k=reklam) · üye başı TL · ödeyen müşteri`

| Zaman | Eşik | Karar |
|---|---|---|
| 48. saat | üye başı maliyet hesaplanır | Cem'e: "5.000 için gereken bütçe = X" |
| Her gün | üye başı **> 100 TL** iki gün üst üste | reklam seti durdurulur, kazanan sete geçilir; ikisi de aşarsa kampanya DURUR, Cem'e yazılır |
| 4. gün | A/B | pahalı set kapanır, bütçe kazanana |
| 16 Ekim | kayıt kapanış günü | metin "Kayıt bu gece 23:59'da kapanıyor" (ayrı reklam, aynı görsel) |
| 17 Ekim 10:00 | deneme | kampanya durur; akşam sonuç kartıyla **24 Ekim Yeterlilik** kampanyası aynı düzenle |

Kill-switch Cem'de de: Ads Manager'da kampanyayı "Kapat" tek tık; ben durduramam (hesap Cem'in).

## 5 · Site tarafı (reklam açılmadan önce)
- Kart ödemesi 5 TL denemesi (ACILIS-GUNU-LISTESI 0.1) — reklam parası kart tutmayan siteye akmasın.
- Politika metni Pixel ile aynı commit'te (META-REKLAM-KURULUM.md).
- Ders sayfası yükü (ACILIS-GUVENLIK-DENETIMI 2.9): ilk hafta Supabase egress izlenir.

GÖRMEZ: Meta panelinde elle değiştirilen metin · Meta'nın kendi raporuyla site sayacının farkı (Pixel engelleyen tarayıcılar) · ödeyen müşteriyi Purchase olayı yok (havale/iyzico onayı site kolunda).
