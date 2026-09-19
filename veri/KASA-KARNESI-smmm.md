# KASA KARNESİ — bitirme (SMMM) · 20.09.2026

Kasadaki soruların **bugünkü** ölçütlerle taranmış hâli. Bedel 0 (yalnız yerel parti dosyaları
okundu). Üretici: `scratchpad/kasa-karne.ps1` — ölçüt tanımları üreticinin kapılarıyla aynı.

> **Niye var:** kasadaki soruların çoğu, bugünkü kapılar konmadan önce yazıldı. "4.000 soru"
> hedefinin ne kadarının bugünün standardını karşıladığı ölçülmeden yeni basıma girmek,
> sağlam sanılan bir temele kat çıkmaktır.

## Ölçüm

**Taranan: 2.031 soru** (yayın şartını geçen bitirme soruları; canlı kasada 1.932 görünüyor,
aradaki fark ambara henüz yüklenmemiş son koşulardan).

| Kusur | Soru | Pay |
|---|---|---|
| Doğru şık **en uzun** şık | 538 | %26,5 |
| Doğru şık **en kısa** şık | 421 | %20,7 |
| Doğru şıkta **yuvarlak tutar** (…000 / …500) | 507 | %25,0 |
| Gövde 900 karakter tavanını aşıyor | 5 | %0,2 |
| **Dördünün hiçbiri yok (temiz)** | **797** | **%39,2** |

### Nasıl okunmalı

- **Şans payı 5 şıkta %20'dir.** "En uzun" %26,5 → şans üstü ama felaket değil (+6,5 puan).
  "En kısa" %20,7 → tam şans seviyesinde, yani orada sistematik kusur YOK.
- **Yuvarlak tutar %25** gerçek kusur sinyali: yapay zekâ izi kapısının (KAPI-O) tam olarak
  cezalandırdığı desen. Bu, 20.09 ölçümünde üretimde de en çok döndüren kapıydı (53 soru).
- Uzunluk fiilen sorun değil (%0,2) — o kapı işini yapıyor.

## Doğru harf dağılımı

| | A | B | C | D | E | uç harf payı |
|---|---|---|---|---|---|---|
| tüm kasa (2.031) | 380 | 442 | 444 | 427 | 338 | **%35,4** |
| yalnız sayı şıklı (899) | 122 | 240 | 228 | 191 | 118 | %26,7 |

Gerçek sınavda uç harf payı **%36**. Kasanın tamamı **%35,4** — yani dağılım gerçek sınava
oturmuş durumda. Sayı şıklı alt kümede %26,7 ile biraz düşük, ama 17-20.09'daki iki A/B turu
bu farkı istemle kapatmanın işe yaramadığını gösterdi (bkz. `AB-KARAR-KARTI-celdirici-yayilimi.md`).

## Sonuç

Kasadaki soruların **%39'u dört kusurun hiçbirini taşımıyor**. Geri kalanın büyük kısmı tek bir
kusur taşıyor ve bunların hiçbiri sorunun DOĞRULUĞUNU bozmuyor — hepsi "sınav gibi durma"
kusuru. Yani kasa çöp değil; ama yeni basımda bu üç deseni ilk taslakta önlemek, hem kaliteyi
hem bedeli doğrudan iyileştirir (20.09: yayına giren soru başı 0,381 USD, harcamanın çoğu
kapıdan dönen soruların yeniden yazımına gidiyor).

**Karar gerektiren:** kasadaki kusurlu soruları geri dönüp onarmak ayrı bir iş emridir; bugün
yapılmadı ve bedeli ölçülmedi.
