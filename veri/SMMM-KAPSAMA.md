# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-10-07 02:28
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 4008 |
| **EKSİK (açık)** | **1104** |
| …bunun engellisi (kısır/kaynak borcu) | 101 |
| FAZLA yazdığımız (hedef üstü) | 1112 |
| hiç yazmadığımız konu | 286 (hedefi 458 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2111 | 2030 | 1226 | 1530 | 434 | 9 |
| Muhasebe Denetimi | 352 | 333 | 397 | 350 | 123 | 1 |
| Sermaye Piyasası Mevzuatı | 345 | 204 | 264 | 350 | 116 | 28 |
| Vergi Mevzuatı ve Uygulaması | 1282 | 416 | 394 | 350 | 113 | 18 |
| Maliyet Muhasebesi | 798 | 323 | 419 | 350 | 79 | 4 |
| Hukuk | 1961 | 340 | 459 | 350 | 54 | 20 |
| Finansal Tablolar ve Analizi | 461 | 498 | 426 | 350 | 42 | 15 |
| Muh. ve Mali Müş. Meslek Hukuku | 978 | 374 | 397 | 350 | 41 | 6 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe |  |
| 8 | 11 | faiz geliri tahakkuku | Finansal Muhasebe |  |
| 5 | 9 | kredili satis kaydi | Finansal Muhasebe |  |
| 3 | 5 | ticari mal devir hizi | Finansal Tablolar ve Analizi | KISIR+KAYNAK-BORCU |
| 3 | 2 | senet reeskontu | Finansal Muhasebe |  |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KISIR+KAYNAK-BORCU |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 5 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 1 | zamanasimi | Hukuk | KISIR |
| 2 | 2 | iliskili taraf islemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 2 | halka arz yontemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 3 | mal alimi kdv | Finansal Muhasebe |  |
| 2 | 6 | idari para cezasi | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe | KISIR+KAYNAK-BORCU |
| 2 | 3 | kdv hizmet tanimi | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | isyeri kira geliri beyani | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | doviz kur degerlemesi | Finansal Muhasebe |  |
| 2 | 2 | sermaye piyasasi suclari | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 2 | erken odeme iskontosu | Finansal Muhasebe | KISIR+KAYNAK-BORCU |
| 2 | 4 | telif kazanci istisnasi | Vergi Mevzuatı ve Uygulaması | KISIR |
| 2 | 2 | satistan iade kdv | Finansal Muhasebe |  |
| 2 | 4 | mamul stok devir hizi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 1 | 2 | devir tarihi tespiti | Vergi Mevzuatı ve Uygulaması |  |
| 1 | 2 | kismi bolunme turleri | Maliyet Muhasebesi |  |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
