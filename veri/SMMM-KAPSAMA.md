# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-09-26 19:12
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3730 |
| **EKSİK (açık)** | **1479** |
| …bunun engellisi (kısır/kaynak borcu) | 128 |
| FAZLA yazdığımız (hedef üstü) | 1209 |
| hiç yazmadığımız konu | 855 (hedefi 1125 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2111 | 2030 | 1096 | 1530 | 593 | 22 |
| Muhasebe Denetimi | 352 | 333 | 363 | 350 | 158 | 5 |
| Sermaye Piyasası Mevzuatı | 345 | 204 | 232 | 350 | 154 | 26 |
| Vergi Mevzuatı ve Uygulaması | 1272 | 416 | 366 | 350 | 128 | 30 |
| Maliyet Muhasebesi | 798 | 323 | 401 | 350 | 102 | 16 |
| Finansal Tablolar ve Analizi | 461 | 498 | 403 | 350 | 91 | 12 |
| Hukuk | 1961 | 340 | 453 | 350 | 73 | 12 |
| Muh. ve Mali Müş. Meslek Hukuku | 978 | 374 | 390 | 350 | 52 | 4 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe | KISIR |
| 5 | 6 | kredili satis kaydi | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 2 | aciz hali | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi |  |
| 3 | 4 | ticari mal devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 4 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 1 | zamanasimi | Hukuk | KISIR |
| 2 | 2 | halka arz yontemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 4 | idari para cezasi | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 1 | erken odeme iskontosu | Finansal Muhasebe | KAYNAK-BORCU |
| 2 | 3 | isyeri kira geliri beyani | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | otv mukellefiyeti | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 3 | kdv hizmet tanimi | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 1 | yenileme fonu iptali | Finansal Muhasebe |  |
| 2 | 3 | kollektif sirket kurulusu | Hukuk |  |
| 2 | 1 | mizan ve bilanco duzenleme | Finansal Muhasebe |  |
| 2 | 1 | sayim noksani | Finansal Muhasebe |  |
| 2 | 1 | brut satis kari | Finansal Muhasebe |  |
| 2 | 3 | telif kazanci istisnasi | Vergi Mevzuatı ve Uygulaması | KISIR |
| 2 | 2 | iliskili taraf islemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 2 | mamul stok devir hizi | Finansal Tablolar ve Analizi |  |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe |  |
| 2 | 2 | sermaye piyasasi suclari | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
