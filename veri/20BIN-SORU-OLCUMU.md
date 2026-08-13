# 20 BİN SORU AÇMA — MALİYET ÖLÇÜMÜ (13.08.2026)
> Cem: *"açılışta en kötü 20 bin soru açmak istiyorum; 100 USD ile olur dersen yaparız, bir ölç."*
> Bu dosya ÖLÇÜMDÜR — tahmin edilen yerler açıkça "TAHMİN" damgalıdır.

## 1) DUVAR NEREDE — ölçüldü
| Ölçüm | Sayı |
|---|---|
| Kasa | 30.569 |
| K1-K10 kapılarından temiz geçen | **3.540** (%11,6) |
| Kasada "Doğrusu:" kalıbı OLAN | **3.295** |
| Kasada "Doğrusu:" kalıbı OLMAYAN | **27.274** |
| K11+K13+K16+K17+GM kara listesi düşülünce kalan | **3.414** |

**Sonuç:** 3.540'lık temiz küme ile 3.295'lik "Doğrusu:" olan küme neredeyse aynı. Yani
**yayını tıkayan tek büyük kapı K5 (yanlış şıklarda "Doğrusu:" yok).** Diğer kapıların
toplam etkisi 126 soru. 20 bine çıkmak = **~17-20 bin soruya "Doğrusu:" yazdırmak.**

## 2) BU BİR YAZIM İŞİ — makine ile olmaz
"Doğrusu:" satırı her yanlış şık için ayrı ayrı, o şıkkın neden yanlış olduğunu ve
doğrusunun ne olduğunu söylemek zorundadır. Deterministik betikle üretilemez; model gerekir.
Bu, kasadaki tek "para ile çözülebilir" büyük kalemdir.

## 3) MALİYET TAHMİNİ (ölçülmüş jeton verisinden türetildi — kesin değil)
Bugünkü okuyucu ajanları soru başına ~7.500 jeton harcadı; **ama o mimari yanlıştı**
(her ajan ambarı baştan okuyor, araç şeması taşıyor, çok turlu konuşuyor).
Doğru mimari: **tek seferlik toplu çağrı** — girdi yalnız soru + şıklar + doğru cevap +
mevcut açıklama; çıktı yalnız 4 satır "Doğrusu:". Araç yok, ajan yok, tur yok.

| Mimari | Soru başına tahmini jeton | 17.000 soru için TAHMİNİ maliyet |
|---|---|---|
| Bugünkü ajan mimarisi (Fable 5) | ~7.500 | çok yüksek — **yapılmaz** |
| Toplu çağrı, Sonnet 5 | ~1.000 girdi + ~400 çıktı | **~150 USD** (Batch indirimiyle ~75 USD) |
| Toplu çağrı, Haiku 4.5 | aynı | **~50 USD** (Batch ile ~25 USD) |

**TAHMİN UYARISI:** bu rakamlar liste fiyatlarından hesaplandı, gerçek koşuyla
DOĞRULANMADI. Sapma iki katına kadar çıkabilir. Kesin rakam için 100 soruluk
pilot şart (tahmini maliyeti ~1 USD).

## 4) KALİTE KISITI
Haiku ucuz ama "Doğrusu:" içeriği yüzeysel/yanlış olabilir — bu satır öğrenciye
öğreten satırdır, ucuza kaçmak riskli. Önerilen: **Sonnet 5 + Batch**, üstüne
ücretsiz kapılardan geçirme + örneklem okuma.

## 5) PARANIN NEREDEN ÇIKACAĞI — dikkat
Bu iş **API kredisi** ister (console.anthropic.com), Claude Code aboneliğinden değil.
Abonelik tavanıyla API kredisi ayrı hesaplardır. 13.08 itibarıyla API tarafında
Build tier tavanı sorunu vardı ([[api-tavan-engeli]]) — pilot öncesi bu kontrol edilmeli.

## 6) SEÇENEKLER (Cem kararı)
- **A — Öde ve yaz:** ~17 bin soruya "Doğrusu:" yazdır. Tahmini 75-150 USD (Sonnet+Batch).
  Önce 100 soruluk pilot (~1 USD) ile gerçek rakam ölçülür. Açılış 20 bin+ soruyla olur.
- **B — Standardı açılışta gevşet:** K5'i "yayın şartı" olmaktan çıkar, "kalite rozeti" yap.
  Ayrıntılı açıklamalı sorular rozetli görünür; diğerleri temel açıklamayla yayında olur.
  0 USD, ama ürün vaadi zayıflar (dürüst kalmak için sayfada açıkça yazılır).
- **C — Az soruyla aç:** 3.414 tam standart soruyla açılış; kalan sorular okundukça/yazıldıkça eklenir.
  0 USD, en güvenli, ama vitrin küçük.

**GM önerisi:** önce 100 soruluk pilot (A'nın ilk adımı, ~1 USD) — gerçek rakam görülmeden
17 bin soruluk koşu başlatılmaz. Pilot rakamı 100 USD'nin altında çıkarsa A; üstünde çıkarsa
B+C karması (en iyi 8-10 bin soruya "Doğrusu:" yazdırıp gerisini rozetsiz açmak).
