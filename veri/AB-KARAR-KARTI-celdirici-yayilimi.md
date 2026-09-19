# A/B KARAR KARTI — çeldirici yayılımı (KURAL 2b)

> **Bu kart sonuç görülmeden yazıldı (18.09.2026, koşular sürerken).** Sebebi: rakam geldikten
> sonra eşik koymak, eşik koymamaktır — hangi sonuç çıkarsa ona uyan bir gerekçe her zaman
> bulunur. Aşağıdaki eşikler **kilitlidir**; değiştirilecekse gerekçesi bu dosyaya, sonucun
> ALTINA, ayrı satır olarak yazılır.

## Ölçülen şey

Bitirme sorularında doğru şıkkın harf dağılımı bozuk: 891 artan sayısal soruda
**A 91 · B 266 · C 293 · D 199 · E 42** (ki-kare 266,4; uç harf payı **%14,9**).
Gerçek sınavda (2019–2025 çıkmış soru ölçümü) uç harf payı **%36**. Yani üretim,
doğru cevabı ortaya (B/C/D) yığıyor; sınav gibi değil, tahmin edilebilir.

Düzeltme (KURAL 2b): sayı şıklı sorularda doğru değerin **en küçük ya da en büyük**
olabileceği isteme yazılır. `motor/kalip-parti-uret.ps1` · anahtar `MEVZUAT_SAYI_SIRA=1`
· bulut girdisi `sayi_sira` (18.09'da eklendi).

## Koşu

| Kol | Anahtar | Plan | Bütçe | Koşu |
|---|---|---|---|---|
| A | 2b KAPALI (bugünkü davranış) | `veri/sinav/plan-smmm-ab2-maliyet-a.json` | 10 USD | 35312936972 |
| B | 2b AÇIK | `veri/sinav/plan-smmm-ab2-maliyet-b.json` | 10 USD | 35312940380 |

Aynı 60 konu · aynı ders (Maliyet) · aynı zorluk (`zor`) · tek fark anahtar.
Ölçüm betiği: `olc-ab2.ps1` (bedel 0; parti + bedel defteri ambardan okunur).

## KARAR EŞİĞİ (kilitli)

**Kural 2b asıl basımda AÇILIR**, ancak ve ancak iki şart birlikte sağlanırsa:

1. **Uç harf payı** (A+E) B kolunda, A koluna göre **en az 10 puan** yüksek.
   (Ör. A %15 → B ≥ %25. Hedef %36; tek seferde oraya varması beklenmiyor.)
2. **Yayın oranı** (üretilen soruya göre yayın şartını geçen soru) B kolunda A koluna
   göre **5 puandan fazla düşmemiş**.

Şartlardan biri düşerse kural 2b **KAPALI kalır** ve bu kart "denendi, tutmadı" olarak
kapanır — 20 USD bilgiye gitmiştir, yeniden denenmeden önce istem değişikliği yeniden
yazılır.

## Ölçüm okunurken bilinecek iki şey

- **Yayın oranı düşük çıkabilir, sebebi kural 2b olmayabilir:** A/B'nin 60 konusu 16.09
  basımında zaten kullanıldı; benzerlik kapısı iki kolda da aynı baskıyı yapar. Bu yüzden
  karar, kolların **birbirine göre farkıyla** verilir, mutlak orana göre değil.
- **Örneklem küçük.** Kol başına ~60 üretilen sorunun sayısal olanları sayılacak; ki-kare
  değeri yön gösterir, tek başına kanıt sayılmaz. Eşik bu yüzden "10 puan" gibi kaba
  tutuldu — küçük örneklemde 2-3 puanlık fark gürültüdür.

## SONUÇ (19.09.2026, iki koşu da YEŞİL bitti)

| | A — 2b KAPALI | B — 2b AÇIK |
|---|---|---|
| üretilen soru | 47 | 46 |
| sayısal soru (tümü) · A B C D E | 39 · 6 7 9 10 7 | 41 · 8 8 9 7 9 |
| **uç harf payı (tüm sayısal)** | **%33,3** | **%41,5** |
| sayısal + artan sıralı · A B C D E | 27 · 0 4 9 10 4 | 35 · 6 8 9 3 9 |
| **uç harf payı (artan sıralı)** | **%14,8** (ki-kare 12,4) | **%42,9** (ki-kare 3,7) |
| hakem "EVET değil" reti | 5/47 (%10,6) | 6/46 (%13,0) |
| yayın şartını geçen | 38 (%80,9) | **0 — ölçülemedi** |
| harcama | 12,04 USD | 10,48 USD |
| yayına giren soru başı | 0,317 USD | ölçülemedi |

**Ölçüt 1 GEÇTİ, hem de farkla.** Artan sıralı sayısal sorularda uç harf payı %14,8 → %42,9
(+28,1 puan; eşik +10 idi). Gerçek sınav %36 — B kolu hedefin üstünde, A kolu yarısının altında.
Doğru şıkkın "hep ortada" olma eğilimi (A kolunda A harfi 27 soruda **0 kez**) B kolunda kırıldı.

**Ölçüt 2 ÖLÇÜLEMEDİ.** B kolu 10 USD bütçe kapısına FAZ B'den (çözüm adımları) ÖNCE çarptı:
46 sorunun 40'ı hakemden geçmiş ama çözüm anlatımı hiç basılmamış, o yüzden simülasyon koşamadı
ve yayın şartı hepsini düşürdü. Bu bir kalite sonucu DEĞİL, yarım iştir. A kolu aynı bütçeyle
zinciri bitirdi (12,04 USD), çünkü fazları farklı sırada tamamladı.

**KARAR: ASKIDA.** Kart iki şart birden ister; biri ölçülemediği için kural 2b bugün **KAPALI
kalır**. Kapatmanın tek yolu B kolunu bitirmektir: aynı plan, aynı etiket (`smmm-ab2-b-maliyet`)
yeniden başlatılır, ödenmiş toplu sonuçlar bedavaya hasat edilir, yalnız kalan fazlar (B/S/G/
simülasyon/hakem2) ödenir. **Tahmini ek bedel 5–8 USD** (A kolunun tamamı 12,04 USD tuttu,
B kolu 10,48 USD'yi zaten harcadı). Bu para Cem'in onayıyla harcanır.

Bir işaret daha: hakem reddi iki kolda neredeyse aynı (%10,6 · %13,0 — bir soruluk fark).
Yani kural 2b'nin hakem kapısından geçişi düşürdüğüne dair iz YOK; ölçüt 2'nin geçmesi olası
görünüyor ama "olası" ölçüm değildir, o yüzden karar askıda.
