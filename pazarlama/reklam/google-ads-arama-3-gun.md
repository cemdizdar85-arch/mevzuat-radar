---
tur: reklam
yz: hayir
kanal: google-arama
durum: taslak
---

<!-- 09.10.2026, Cem: "kuralım, öne çıkalım" — Google Ads arama reklamı, 3 gün × 300 TL deneme (Meta'nın 1.500 TL/gün'ünden AYRI).
Google arama reklamına kendisi "Sponsorlu" etiketi basar; dosyadaki "Reklam" ibaresi kapı içindir.
Karakter sınırı (Google, duyarlı arama reklamı): başlık ≤ 30, açıklama ≤ 90 — `node` ile sayıldı (aşağıdaki DENETİM). -->

# Reklam · Google arama · 3 gün deneme

## Kampanya ayarları (Google Ads paneli)

| Alan | Değer |
|---|---|
| Kampanya türü | Arama (Search) · **Görüntülü Reklam Ağı KAPALI** · arama ortakları KAPALI |
| Bütçe | **300 TL / gün**, 3 gün (10–12.10), sonra 3. gün sonucuna göre karar |
| Teklif | Tıklamaları en üst düzeye çıkar, **TBM tavanı 10 TL** (tıklama fiyatı ÖLÇÜLMEDİ; 1. gün sonunda bakılır) |
| Yer | Türkiye · "bu konumda bulunan kişiler" |
| Dil | Türkçe |
| Reklam grubu 1 | Staja Giriş → `https://tetikte.com/seviye-testi.html?k=gads` |
| Reklam grubu 2 | Yeterlilik → `https://tetikte.com/seviye-testi.html?k=gads` |
| Reklam grubu 3 | Canlı deneme → `https://tetikte.com/canli-deneme.html?k=gads` |

## Anahtar kelimeler (ifade eşlemesi, tırnakla girilir)

Grup 1 · Staja Giriş:
"smmm staja giriş sınavı" · "staja giriş sınavı soruları" · "staja giriş çıkmış sorular" · "sgs soruları" · "smmm staj sınavı" · "staja giriş deneme"

Grup 2 · Yeterlilik:
"smmm yeterlilik sınavı" · "yeterlilik sınavı soruları" · "smmm yeterlilik soruları" · "smmm bitirme sınavı" · "yeterlilik çıkmış sorular"

Grup 3 · Canlı deneme:
"smmm deneme sınavı" · "ücretsiz smmm deneme" · "staja giriş deneme sınavı" · "online smmm deneme"

Negatif kelimeler (kampanya düzeyi): iş ilanı · maaş · kpss · ales · yds · pdf indir · başvuru ücreti · sonuç açıklandı mı

## Başlıklar (≤ 30 karakter)

1. SMMM Staja Giriş Soruları
2. Yeterlilik Sınavı Soruları
3. 30 Soruda Seviyeni Ölç
4. Ücretsiz, Kart İstenmez
5. Yanlışının Nedenini Gör
6. Her Yanlışta Dayanak Madde
7. 17 Ekim Ücretsiz Canlı Deneme
8. 130 Soru, Gerçek Sınav Süresi
9. Staja Giriş 21 Kasım'da
10. Yeterlilik 28 Kasım'da
11. Yanlışın 2 Gün Sonra Döner
12. Tetikte: Soru Çöz, Öğren

## Açıklamalar (≤ 90 karakter)

1. Staja Giriş ve Yeterlilik için soru çöz; her yanlışta nedeni ve dayanak madde yanında.
2. 30 soruluk seviye testi ücretsiz, kart istenmez. Sonucunu hemen gör.
3. 17 Ekim 10:00: 130 soruluk ücretsiz canlı deneme, gerçek süre, yüzdelik sıralama.
4. Tetikte'nin TÜRMOB ve TESMER'in resmî sınavlarıyla bağlantısı yoktur.

<!-- Grup 3 reklamında başlık 7 + 8 ve açıklama 3 + 4 SABİTLENİR (pin): canlı deneme anılan her gösterimde bağlantı yok uyarısı da görünsün. -->

## Ölçüm

- Sitede kaynak sayacı: `?k=gads`.
- Google dönüşüm etiketi: hesap açılınca verilen `AW-…` kimliğiyle `donusum.js`'e eklenecek (Lead = seviye testi bitti / canlı deneme kaydı). Kimlik gelmeden reklam açılabilir ama dönüşüm sayılmaz → yalnız tıklama + site sayacı.
- 3. gün sonu tek satır: harcama · tıklama · ort. TBM · `?k=gads` ile gelen üye · üye başı TL. Eşik: üye başı > 100 TL → durdur (Meta kampanyasıyla aynı ölçüt).

GÖRMEZ: Google panelinde elle değiştirilen metin · Google'ın reklam politikası incelemesi (TÜRMOB/TESMER adı reddedilirse açıklama 4 "Resmî sınavla bağlantısı yoktur." olur) · tıklama fiyatı (ölçülmedi).
