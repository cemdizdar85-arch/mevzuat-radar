# DOĞRULAMA KAPISI — KALICI KIRMIZI İŞ EMRİ (02.10.2026)

**Neden var:** `dogrula.yml` 30.09–01.10 arası 100 koşunun **71'ini iptal**, 28'ini kırmızı, **0'ını yeşil** bitirdi
(paralel oturum push'ları çalışan koşuyu yarıda kesiyordu). 02.10'da `cancel-in-progress: false` yapıldı (f4987ea9),
koşular ilk kez sonuna kadar gitti ve **13 kapı kırmızı** çıktı (koşu 36928575112, 72424856). Kırmızı uzun süre
görünmediği için **sahipsiz** kaldı. Cem 02.10: "1.2.3 üçünü de yap" → her kapının nedeni günlükten okundu, sahibine yazıldı.

**Kural:** kapının tabanını gerekçesiz indirmek/genişletmek = borcu gizlemek. Taban yalnız "bilerek böyle" kararıyla,
gerekçe commit mesajına yazılarak tazelenir.

## ✅ ALTYAPI — kapatıldı (c64f72a6, 02.10)

| Kapı | Neden | Ne yapıldı |
|---|---|---|
| JSON bütünlük (257 dosya) | **Kapının yanlış alarmı:** `veri/sinav/konu/*.json` tek metin değeri taşıyor, geçerli JSON | Tek metin kabul; öz-sınav +3 vaka; mutasyon 2/2 |
| Açıklama hakemi MUTASYON | **Ortam:** Linux runner'da `powershell` yok | `pwsh`'e düşer; yerelde 3/3 |
| Kimlik denetimi (4 betik) | UserAgent satırı eksik | Satır eklendi, ParseFile 4/4 |
| SQL kapısı | `rag-motor/sql/011_kalip_parti.sql` BOM | BOM silindi (11.09 basılı, içerik aynı) |
| Açılış kapısı (5 sayfa) | Turnstile (`challenges.cloudflare.com`, Cem 01.10) izinli listede yoktu | `veri/dis-kaynak-izinli.json`'a gerekçeyle |

## 🔴 AÇIK — sahibine verildi

| # | Kapı | Bulgu (ölçülen) | Sahibi | Not |
|---|---|---|---|---|
| 1 | Kontrast | `pano.html` 1 okunmayan metin · `index.html` görünmez sınır: `p.bz-fiyat` üst çerçeve `rgba(214,180,126,.18)` açık zeminde görünmüyor | **site** | jeton: `var(--line)` |
| 2 | Renk sabiti | `index.html` 3→6 (+3) · `radar.html` 3→4 (+1) · `donusum.js` YENİ, 10 sabit renk | **site** (donusum.js: pazarlama/Meta) | Bilerek sabitse taban + gerekçe |
| 3 | Tazelik | `ogrenci.html` ve `_kapali-araclar/ihale-radari.html` tazelik iddiası kuruyor, `tazelik.js` bağlı değil | **site** | ogrenci açılış sayfası |
| 4 | Koku ölçer | `kurulus-nobeti.html` JARGON "know-how" | **site** | tek kelime |
| 5 | Otomasyon | Yazanı olmayan veri: `kurulus-maliyet.json`, `oda-tarifeleri.json` (kuruluş) · `siklik-kunyesi-kgk.json` (kgk) · `siklik-kunyesi-smmm.json`, `soru-dizini.json` (sinav) · `vitrin-kart-ozet.json` (sgs/site) | **destek · kgk · sinav · sgs** | Hasatçıyı workflow'a bağla ya da `veri/otomasyon-borcu.json`'a gerekçeyle |
| 6 | İhale firma adı | Kesik firma adı **115 → 541** | **ihale** | Gerçek veri gerilemesi; ayrıştırıcı ya da kaynak değişti — ölç |
| 7 | KAPI-KALITE bitirme bağı | Öz-sınav 15/16: vaka "yeni soru ISO tarih (01.10 08:00) → DÜŞER" KIRMIZI | **sinav (SMMM)** | Tarih sınırı/saat dilimi şüphesi — ÖLÇÜLMEDİ |
| 8 | Türkçe katlama | Riskli satır 174 → **316**; taban 31.08'den, 35 betikte artış (en büyük: `kalip-parti-uret.ps1` +81, `standart-yut.ps1` +19) | **altyapı** (betik sahipleriyle) | Her satır okunmalı: ASCII-sabit ise taban+gerekçe, değilse `Katla` |

## 🚫 Bu iş emri şunu GÖRMEZ
- Yalnız 36928575112 koşusu okundu; sonraki push'lar yeni kırmızı getirmiş olabilir.
- "Rapor yayınla" adımı (kontrast/açılış/ihale) push çakışmasında `|| true` ile sessiz geçiyor; raporların depoya
  ulaşıp ulaşmadığı ÖLÇÜLMEDİ.
