# KGK — ÖLÇÜ TABLOSU (sözleşme B31 "her kural ölçülür"; Cem 03.11.2026 "Evet, kur")

> BITIRME-SORU-STANDARDI.md §7'nin KGK eşi. Her kuralın yanında ölçüsü yazılıdır; yazar "kurala uydum" diyemez, ölçünün çıktısını gösterir.
> Ölçüsü olmayan kural **ÖLÇÜLMÜYOR**, düzeni olmayan **KURULMAMIŞ** diye işaretlidir. Araçlar çalışma kopyasında: `C:\TETIKTE-CALISMA\kgk-is`
> (depoda anlık kopya: `arac/kgk-olcu/`). Basım planı (`plan-kur.js`) zorunlu kapı 1–4'ten geçmeden YAZILMAZ.

## Gerçek veri (03.11)
- **3.893 çıkmış KGK sorusu** (2016+; 24 sınav), soru ↔ etiket konusu **içerikle** bağlı (`kalip/bagla.js`). Eski sıra kuralı iki sütunlu
  kitapçıkta %18–35 kayıyordu (kesin işaretli sorularda ölçüldü; yeni bağda %0–9, kalan kısmı meşru çapraz atıf + gözle 8'de 2 kayma).
- **Elle kalıp etiketi**: 30 okuyucu, 3.905 soru (`veri/sinav/kgk-kalip-elle-3905.json`; okunamayan 3).
- **Kapsam dışı**: 2013, 2014, Mart 2015, Kasım 2018 (kitapçık metni bozuk) · eski genel muhasebe / genel hukuk modülleri.
- **Ayırıcı uyumu** (`kalip/kgk-kalip-ayirici.js` ↔ elle): **%87,6** (3.418/3.904). Eşik %90 → **sitedeki/yeni sorunun kalıbı ±%12 hatalı
  okunabilir**; gerçek tarafı ayırıcıya değil elle etikete dayanır. Bitirme ayırıcısı KGK'da %76 tuttu (dokunulmadı). Kalan farkın bir kısmı
  okuyucular arası tutarsızlık ("söylenemez" B/C, "boşluk + sırasıyla" E/L).

## Ölçü tablosu
| Kural | Nasıl ölçülür (araç / kim) | Geçme şartı |
|---|---|---|
| Kaynak okunmadan yazılmaz (B1) · metinde olmayan rakam (B2) | okuyucu r1–r5 (`RN-OKUYUCU.md`, `IKINCI-GOZ.md`) | son okuma TEMIZ |
| Kök olgusu (şart kökte) | okuyucu r1–r5 KÖK OLGUSU ADIMI | son okuma TEMIZ |
| İki kör çözüm | ölçü satırı `oku1`/`oku2` (r1/r2 `benim_cevabim`) | ikisi de anahtar; okuma yoksa **ÖLÇÜLMEDİ** (geçmez) |
| Teslim kapıları (A1 çıkmış kopya, Ş şık dengesi, O klişe, MM mülga, Y yıl, K tavan…) | `arac/hazir-soru-denetle.ps1` (kapı 1) | 0 KUSUR |
| Çizim · "doğru cevap" kayması · öncül tek fark · eski makam | `arac/kgk-ek-kapi.js` KGK-CZ/DC/G2/MK (kapı 2) | satır yok |
| Kök tavanı | modülün gerçek p90'ı (`kalip/tavan-olc.js`): TMS 707 · TDS 653 · FY 366 · KY 341 · SPK 428 · Banka 501 · Sigorta 519 · TSRS 995 · GDS 780 | tek soru ≤ tavan (ölçü satırı) |
| Konu karışımı: kök/olumsuz/hesap | `konu-profil.js denetle` (kapı 3) — grup kök medyanı ≤ konu gerçek medyanı ×1,3 · olumsuz ≥ gerçek karışımın yarısı · hesap sapması ≤ max(3, yarı) · sözel konuya 3 hesap yok | temiz (öz-sınav: gerçek grupların %92'si geçer) |
| Gizli izler | kapı 3: tek harfli ad "(K) A.Ş." (gerçek 0/3.893) · kökte yıl ≤ 6/21 · şık en uzun/en kısa medyanı ≥ 1,7 (gerçek 2,2) | temiz |
| **Kalıp karışımı (B30)** | kapı 3: kalıp = KGK ayırıcısı; modülün gerçek sınavında görülmemiş kalıp yok · sitede ≥%60 tek kalıba yığılmış konuya yine aynı kalıp yok | temiz |
| Konu × kalıp tablosu | `kalip/konu-kalip-tablo.js` → `veri/sinav/kgk-duzeltme/konu-konu-kalip.md` | dalga planı "ÖNCE YAZ" kalıplarına göre |
| **Soru başı ölçü satırı (B31)** | `olcu-satiri.js` (kapı 4) → `olcu/<dalga>-<grup>.tsv`: kimlik · konu · kalıp · konuda/modülde gerçek mi · kök/hedef/tavan · şık türü · oku1/oku2/anahtar · kaynak sayısı · ek kapı · yıl · tek harf · şık oranı · DURUM | her soru GEÇER |
| Adet (konu başına soru) | `arac/kgk-konu-kapsama.js` → `veri/sinav/KGK-KAPSAMA.md` (son 10 yılda çıkan × 1) | plan konu sırası eksik/sıklık sırası |
| **K1 kartlı soru** (BITIRME-SORU-STANDARDI K1, 05.11) | sorunun `konu` ↔ `veri/sinav/kgk-konu-kartlari.json` (`KGK-KONU-KARTLARI.md`; üretim `arac/kgk-kart/`) — kartın 4 alanı dolu olmalı; dayanak "AMBARDA YOK/BOZUK" ise soru YAZILMAZ (K1b) | konu dolu bir kartla birebir eşleşir |
| Bulut | hakem (karar+ders+konu+tek anlam) · sim · kör · hakem2 · açıklama hakemi · kalite · ikiz · ret kütüğü | yayın şartı |

## ÖLÇÜLMÜYOR
- **Dayanak cümlesinin ambarda AYNEN bulunduğu** — mekanik değil; okuyucu r1–r5 okur (bitirme D2'nin eşi KGK'da yok).
- **Çeldirici gücü / öğrenci verisi** — KGK sitede kapalı; `cevap_kayit` yok.
- **Konunun hangi paragrafının sorulduğu** — ölçülmedi.

## KURULMAMIŞ (kurulana kadar "yapıldı" denmez)
- **Sitede "sınava benzer önce" sıralaması** KGK kaydırma sayfalarında YOK (Yeterlilik'te var: `motor/smmm-ders-sira.js`).
- **Kalan basım planı konu × kalıp kotasıyla** — araçlar hazır; plan kurulmadı (basım frende, Cem kararı).
- **KGK anatomi dosyası** `veri/sinav-anatomisi-kgk.json` hâlâ eski (SGS sözlüğü); bu tablonun ölçüleri ona dayanmaz.

## 03.11 durum (ölçüldü)
- Mevcut t1–t9 gruplarının hiçbiri yeni kapı 3'ten temiz geçmiyor; t9'da ana neden kök uzunluğu (ör. SPK grup 206 ↔ gerçek konu 142).
- Sitede (1.883 soru, `konu-konu-kalip.md`): 420 konuda gerçekte ≥2 kez görülen bir kalıp sitede hiç yok · Denetim Standartları'nda 5+ sorulu
  32 konunun 20'si tek tip (>%60).
