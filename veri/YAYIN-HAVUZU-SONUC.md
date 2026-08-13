# YAYIN HAVUZU — SONUÇ (13.08.2026 gecesi)
> Cem: *"yap hepsini, kaç soru çıkar görürüz."* Zincir koştu, rakam ölçüldü.

## SONUÇ: **12.672 soru** — 17 kapının HEPSİNDEN temiz
| Aşama | Sayı |
|---|---|
| Kasa | 30.569 |
| K1-K10 temiz (K5 düzeltilmiş ölçütle) | **15.550** |
| Kara liste (K11+K13+K16+K17+GM) | 3.368 |
| **HEPSİNDEN TEMİZ — yayına aday** | **12.672** |

### Kara listenin dökümü
| Kapı | Adet | Ne demek |
|---|---|---|
| K13 aritmetik bulgu | 1.302 | açıklamadaki hesap tutmuyor — okunmadan yayına GİRMEZ |
| K17-F5 kelime tekrarı ipucu | 808 | kökteki nadir kelime yalnız doğru şıkta |
| K17-F3 uzunluk ipucu | 525 | doğru şık diğerlerinin 1,6 katı+ |
| K17-F1 mutlak terim | 332 | "asla/her zaman" içeren şık |
| K13 kalıplı sapma | 129 | yuvarlama vb. sistematik fark |
| K13 dengesiz yevmiye | 87 | borç ≠ alacak |
| K11 çoklu doğru şık | 65 | iki şık savunulabilir |
| K16 uydurma rakam / yapı bozuk | 52 / 50 | tabloda metinde geçmeyen sayı; kolon-hücre uyumsuz |
| GM okuyucu kusurlu | 16 | insan-gibi okuyucunun elle yakaladığı |

## BU GECE YAPILAN ONARIMLAR (hepsi 0 USD, doğrulamalı)
| İş | Önce | Sonra |
|---|---|---|
| Şık karıştırma (harf dengesi) | A %47,5 (KIRMIZI) | A %19,8 · B %20,2 · C %23,4 · D %21,2 · E %15,3 — **YEŞİL** (azami sapma 4,7 puan) |
| Sayısal şık sıralama | 4.909 sırasız (%31,6) | **179** (%1,2) — kalanı harf-atıflı, bilinçli dokunulmadı |
| Doğru şık en uzun mu | — | %31,7 **YEŞİL** (rastgele beklenen ~%20, sınır %45) |

## AÇIK KALAN — açılış öncesi karar gerektiren
1. **83 yakın-kopya çifti (K15-T3 KIRMIZI):** aynı denemede iki kopya soru çıkmasın diye her çiftin biri yayından tutulmalı. Mekanik iş, 0 USD — onay verilirse yapılır (havuz ~83 azalır).
2. **12.672'nin okunmamış olması:** GM okuyucu pilotunda kapı-temiz sorularda %37 kusur çıkmıştı; o pilot ESKİ havuzdaydı (kara liste uygulanmamıştı). Yeni havuzda oran çok daha düşük beklenir ama **ölçülmedi**. Okuma bandı aylık limit nedeniyle durdu; 1 Eylül'de API açılınca ya da limit yükseltilince örneklem okunmalı.
3. **VANA KURALI şu an "okuyucu-uygun" şartı arıyor** (yayina-al.ps1): bu şart korunursa yalnız okunmuş 37 soru açılır. Açılışta 12.672 açılacaksa kural "kapı-temiz + örneklem doğrulanmış" şeklinde gevşetilmeli — **Cem kararı**.

## DERSLER (bu gece yakalanan 5 sessiz hata — hepsi koda yazıldı)
1. K5 yanlış şeyi ölçüyordu ("Doğrusu:" kelimesi ≠ düzeltici bilgi) → 12 bin soru haksız kırmızıydı
2. `$k` döngü değişkeni `$K` kapı sayacını eziyordu (PS büyük/küçük harf ayırmaz)
3. Kapı temiz-id listesini hiç yazmıyordu → elimizdeki liste 3 gün bayattı
4. Aritmetik raporu 1.302 bulgunun 400'ünü kaydediyordu → kara liste eksik süzüyordu
5. Sıralayıcının döngü çıkışı sayfa boyuyla uyumsuzdu → ilk sayfada kırılıp "düzelen 0" diyordu
