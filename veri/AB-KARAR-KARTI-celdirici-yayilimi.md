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

## SONUÇ

_(koşular bitince buraya yazılacak: kol · üretilen · yayına giren · A B C D E · uç harf payı
· soru başı bedel · KARAR)_
