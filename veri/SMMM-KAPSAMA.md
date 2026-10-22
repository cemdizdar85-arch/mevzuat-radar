# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-10-22 21:07
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3979 |
| **EKSİK (açık)** | **1173** |
| …bunun engellisi (kısır/kaynak borcu) | 101 |
| FAZLA yazdığımız (hedef üstü) | 1152 |
| hiç yazmadığımız konu | 305 (hedefi 508 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2118 | 2030 | 1192 | 1530 | 477 | 9 |
| Muhasebe Denetimi | 357 | 333 | 414 | 350 | 123 | 1 |
| Sermaye Piyasası Mevzuatı | 350 | 204 | 277 | 350 | 111 | 28 |
| Vergi Mevzuatı ve Uygulaması | 1281 | 416 | 424 | 350 | 105 | 18 |
| Maliyet Muhasebesi | 798 | 323 | 417 | 350 | 80 | 4 |
| Finansal Tablolar ve Analizi | 461 | 498 | 390 | 350 | 69 | 15 |
| Hukuk | 1961 | 340 | 454 | 350 | 55 | 20 |
| Muh. ve Mali Müş. Meslek Hukuku | 978 | 374 | 394 | 350 | 44 | 6 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe |  |
| 8 | 11 | faiz geliri tahakkuku | Finansal Muhasebe |  |
| 7 | 4 | alacak senedi reeskontu | Finansal Muhasebe |  |
| 5 | 1 | alacak borc senedi reeskontu | Finansal Muhasebe |  |
| 5 | 9 | kredili satis kaydi | Finansal Muhasebe |  |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 2 | reeskont hesaplama | Finansal Muhasebe |  |
| 3 | 6 | reeskont faiz kaydi | Finansal Muhasebe |  |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 3 | 5 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 4 | alacak senedi iskonto | Finansal Muhasebe |  |
| 3 | 5 | ticari mal devir hizi | Finansal Tablolar ve Analizi | KISIR+KAYNAK-BORCU |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KISIR+KAYNAK-BORCU |
| 3 | 2 | senet reeskontu | Finansal Muhasebe |  |
| 3 | 5 | borc senedi finansman gideri | Finansal Muhasebe |  |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe | KISIR+KAYNAK-BORCU |
| 2 | 3 | isyeri kira geliri beyani | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | kdv hizmet tanimi | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | borc senedi odeme finansman gideri | Finansal Muhasebe |  |
| 2 | 2 | iliskili taraf islemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 2 | halka arz yontemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 4 | telif kazanci istisnasi | Vergi Mevzuatı ve Uygulaması | KISIR |
| 2 | 2 | satistan iade kdv | Finansal Muhasebe |  |
| 2 | 2 | alacak senedi tahsil komisyon | Finansal Muhasebe |  |
| 2 | 2 | senet kirdirma iskonto | Finansal Muhasebe |  |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
