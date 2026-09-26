# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-09-26 13:50
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3648 |
| **EKSİK (açık)** | **1636** |
| …bunun engellisi (kısır/kaynak borcu) | 125 |
| FAZLA yazdığımız (hedef üstü) | 1284 |
| hiç yazmadığımız konu | 904 (hedefi 1245 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2117 | 2038 | 1070 | 1528 | 622 | 22 |
| Muhasebe Denetimi | 352 | 333 | 358 | 350 | 174 | 5 |
| Sermaye Piyasası Mevzuatı | 346 | 204 | 224 | 350 | 165 | 28 |
| Vergi Mevzuatı ve Uygulaması | 1273 | 416 | 361 | 350 | 143 | 30 |
| Maliyet Muhasebesi | 798 | 323 | 404 | 350 | 120 | 11 |
| Hukuk | 1966 | 340 | 427 | 350 | 109 | 14 |
| Finansal Tablolar ve Analizi | 471 | 515 | 396 | 350 | 103 | 10 |
| Muh. ve Mali Müş. Meslek Hukuku | 979 | 374 | 382 | 350 | 72 | 4 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 25 | 1 | supheli alacak karsiligi | Finansal Muhasebe |  |
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe | KISIR |
| 5 | 6 | faaliyet kârliligi | Finansal Tablolar ve Analizi | KISIR+KAYNAK-BORCU |
| 5 | 6 | kredili satis kaydi | Finansal Muhasebe | KAYNAK-BORCU |
| 4 | 7 | brut satis karliligi | Maliyet Muhasebesi | KISIR+KAYNAK-BORCU |
| 3 | 4 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 1 | otv beyannamesi mukellefi | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 2 | yan urun maliyeti | Maliyet Muhasebesi |  |
| 3 | 2 | meslek mensubu genel sartlari | Muh. ve Mali Müş. Meslek Hukuku |  |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 3 | 1 | vergi ziyai | Vergi Mevzuatı ve Uygulaması |  |
| 3 | 4 | ticari mal devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi |  |
| 3 | 2 | aciz hali | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 6 | emsal bedeli | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 1 | kamu kesimi tahvil alimi | Finansal Muhasebe |  |
| 2 | 1 | varlik kârliligi | Finansal Tablolar ve Analizi |  |
| 2 | 1 | brut satis kari | Finansal Muhasebe |  |
| 2 | 1 | sayim noksani | Finansal Muhasebe |  |
| 2 | 1 | erken odeme iskontosu | Finansal Muhasebe | KAYNAK-BORCU |
| 2 | 2 | denetim kaniti faktorleri | Muhasebe Denetimi |  |
| 2 | 7 | is sozlesmesi tanimi ve unsurlari | Hukuk |  |
| 2 | 6 | izahname sorumlulugu | Sermaye Piyasası Mevzuatı |  |
| 2 | 1 | mizan ve bilanco duzenleme | Finansal Muhasebe |  |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
