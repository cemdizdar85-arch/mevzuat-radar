# 20 BİN SORU — KARAR NOTU (13.08.2026 akşamı, ölçümle güncellendi)
> Önceki ölçüm (`20BIN-SORU-OLCUMU.md`) "duvar K5, 17 bin soruya para lazım" diyordu.
> **O teşhis EKSİKTİ.** Soruları okuyunca tablo değişti — kayıt aşağıda.

## 1) API KAPISI KAPALI (kesin, sunucudan birebir)
`https://api.anthropic.com` → HTTP 429:
> *"your organization has crossed its monthly API usage threshold... You will regain access on **2026-09-01** at 00:00 UTC"* (`enforced_spend_limit_reached`)

Yani 1 USD'lik pilot dahi bugün koşulamaz. Para meselesi değil, **kapı 1 Eylül'e kadar kapalı**.
AWS/Vertex anahtarları da tanımlı değil (kontrol edildi: yok). Bkz. [[api-tavan-engeli]].

## 2) ASIL BULGU: "Doğrusu:" eksikliği KALİTE değil BİÇİM sorunu
| Ölçüm (30.569 soru) | Sayı |
|---|---|
| Her yanlış şıkta **dolu açıklama** (60+ karakter) | **30.521** |
| Her yanlış şıkta **tuzak anlatımı** (TUZAK/karıştırılıyor/sanılıyor…) | **19.663** |
| Kısmen tuzak anlatımı olan | 3.782 |
| Hiç olmayan | 7.123 |
| Her yanlış şıkta literal **"Doğrusu:"** ibaresi | 3.161 |

**Okunan kanıt (kural: raporu değil SORUYU oku):** `00034ecd` — K5'e takılıyor ama
dört yanlış şıkkın dördünde de "TUZAK: … Kanun metni … şart koşmuştur" biçiminde
tam açıklama var; doğru şıkta 4 parça düzeni eksiksiz. Eksik olan tek şey
"Doğrusu:" kelimesi. **Soru öğretiyor; kapı kelime arıyor.**

## 3) KARAR (GM önerisi)
K5 kapısı **"Doğrusu:" kelimesini değil, DÜZELTİCİ BİLGİYİ** aramalı. Tuzak anlatımı
+ doğru kuralı söyleyen açıklama, standardın ruhunu karşılar. Kapı bu şekilde
güncellenirse:
- **19.663 soru** (her yanlış şıkta tuzak anlatımlı) yayın adayı olur — **20 bin hedefine 0 USD ile ulaşılır.**
- **7.123 soru** (tuzak anlatımı hiç yok) → gerçek eksik, para/model işi; 1 Eylül sonrası
  ya da AWS hattıyla yazdırılır. Bunlar açılışta yayına GİRMEZ.
- **3.782 kısmi** → ikinci öncelik.

## 4) ŞART — bu bir gevşetme DEĞİL, doğru ölçme olmalı
Kapı güncellenirken kanıt aranacak: yanlış şık açıklaması (a) tuzağı adlandıracak,
(b) doğru bilgiyi söyleyecek (kanun/kural/rakam), (c) en az 60 karakter olacak.
Yalnız "yanlıştır" diyen açıklama YİNE reddedilir. Kapı güncellendikten sonra:
`sik-karistir` + `k15` + `k16` + `k17` + GM okuyucu havuzu yeniden kesişecek.

## 5) SIRA
1. K5'i "düzeltici bilgi" ölçütüyle yeniden yaz (0 USD) → yeni temiz havuzu ölç
2. Havuza K11/K13/K16/K17 kara listesini uygula → gerçek yayın sayısı
3. GM okuyucu örneklemi (yeni havuzdan 60 soru) → kusur oranı ölç
4. Cem onayıyla vana aç
5. 7.123 eksik soru: 1 Eylül'de API açılınca ya da AWS hattıyla tamamlanır
