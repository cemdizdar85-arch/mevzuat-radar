# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-09-26 18:41
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3712 |
| **EKSİK (açık)** | **1492** |
| …bunun engellisi (kısır/kaynak borcu) | 121 |
| FAZLA yazdığımız (hedef üstü) | 1204 |
| hiç yazmadığımız konu | 863 (hedefi 1144 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2117 | 2038 | 1092 | 1530 | 596 | 22 |
| Muhasebe Denetimi | 352 | 333 | 363 | 350 | 158 | 5 |
| Sermaye Piyasası Mevzuatı | 346 | 204 | 231 | 350 | 156 | 26 |
| Vergi Mevzuatı ve Uygulaması | 1273 | 416 | 366 | 350 | 128 | 30 |
| Maliyet Muhasebesi | 798 | 323 | 397 | 350 | 108 | 11 |
| Finansal Tablolar ve Analizi | 471 | 515 | 402 | 350 | 95 | 10 |
| Hukuk | 1966 | 340 | 448 | 350 | 77 | 12 |
| Muh. ve Mali Müş. Meslek Hukuku | 979 | 374 | 387 | 350 | 53 | 4 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe | KISIR |
| 5 | 6 | faaliyet kârliligi | Finansal Tablolar ve Analizi | KISIR+KAYNAK-BORCU |
| 5 | 6 | kredili satis kaydi | Finansal Muhasebe | KAYNAK-BORCU |
| 4 | 7 | brut satis karliligi | Maliyet Muhasebesi | KISIR+KAYNAK-BORCU |
| 3 | 2 | aciz hali | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 4 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 4 | ticari mal devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi |  |
| 2 | 1 | brut satis kari | Finansal Muhasebe |  |
| 2 | 3 | otv mukellefiyeti | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 3 | telif kazanci istisnasi | Vergi Mevzuatı ve Uygulaması | KISIR |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe |  |
| 2 | 1 | zamanasimi | Hukuk | KISIR |
| 2 | 1 | sayim noksani | Finansal Muhasebe |  |
| 2 | 3 | kdv hizmet tanimi | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | isyeri kira geliri beyani | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 4 | idari para cezasi | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 1 | mizan ve bilanco duzenleme | Finansal Muhasebe |  |
| 2 | 1 | yenileme fonu iptali | Finansal Muhasebe |  |
| 2 | 2 | sermaye piyasasi suclari | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 2 | mamul stok devir hizi | Finansal Tablolar ve Analizi |  |
| 2 | 2 | varliklarin kârliligi | Finansal Tablolar ve Analizi |  |
| 2 | 1 | erken odeme iskontosu | Finansal Muhasebe | KAYNAK-BORCU |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
