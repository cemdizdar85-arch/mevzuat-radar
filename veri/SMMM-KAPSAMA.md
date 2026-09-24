# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-09-24 07:29
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3170 |
| **EKSİK (açık)** | **2063** |
| …bunun engellisi (kısır/kaynak borcu) | 125 |
| FAZLA yazdığımız (hedef üstü) | 1233 |
| hiç yazmadığımız konu | 1034 (hedefi 1547 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2117 | 2038 | 832 | 1528 | 846 | 22 |
| Hukuk | 1966 | 340 | 328 | 350 | 202 | 14 |
| Muhasebe Denetimi | 352 | 333 | 337 | 350 | 192 | 5 |
| Sermaye Piyasası Mevzuatı | 346 | 204 | 206 | 350 | 183 | 28 |
| Vergi Mevzuatı ve Uygulaması | 1273 | 416 | 345 | 350 | 152 | 30 |
| Maliyet Muhasebesi | 798 | 323 | 392 | 350 | 129 | 11 |
| Finansal Tablolar ve Analizi | 471 | 515 | 369 | 350 | 120 | 10 |
| Muh. ve Mali Müş. Meslek Hukuku | 979 | 374 | 335 | 350 | 111 | 4 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 25 | 1 | supheli alacak karsiligi | Finansal Muhasebe |  |
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe | KISIR |
| 5 | 6 | kredili satis kaydi | Finansal Muhasebe | KAYNAK-BORCU |
| 5 | 6 | faaliyet kârliligi | Finansal Tablolar ve Analizi | KISIR+KAYNAK-BORCU |
| 4 | 4 | donem kari vergi karsiligi | Finansal Muhasebe |  |
| 4 | 7 | brut satis karliligi | Maliyet Muhasebesi | KISIR+KAYNAK-BORCU |
| 4 | 4 | sgk vergi odemesi | Finansal Muhasebe |  |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 3 | 4 | mamul devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 4 | ticari mal devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 2 | yan urun maliyeti | Maliyet Muhasebesi |  |
| 3 | 2 | reeskont hesaplama | Finansal Muhasebe |  |
| 3 | 1 | otv beyannamesi mukellefi | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 4 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 1 | vergi ziyai | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi |  |
| 3 | 2 | meslek mensubu genel sartlari | Muh. ve Mali Müş. Meslek Hukuku |  |
| 3 | 2 | oran analizi hesaplama | Finansal Tablolar ve Analizi |  |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 2 | aciz hali | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 4 | idari para cezasi | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe |  |
| 2 | 3 | acilis kaydi bilanco | Finansal Muhasebe |  |
| 2 | 2 | iliskili taraf islemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 6 | izahname sorumlulugu | Sermaye Piyasası Mevzuatı |  |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
