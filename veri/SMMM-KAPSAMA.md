# SMMM BİTİRME — KONU KAPSAMA

> Türetilmiştir (`arac/smmm-kapsama-tablosu.ps1`), **elle düzenlenmez**. Ölçüm: 2026-09-26 19:42
> Kural: hedef **sıklık ağırlıklı**, banka toplamı **4000**
> Excel: `arac/smmm-basim-excel.ps1` (yerelde, Excel COM ister) · Plan: `arac/smmm-plan-kur.ps1`

| | soru |
|---|---:|
| hedef | 4000 |
| bugün yayınlanabilir | 3730 |
| **EKSİK (açık)** | **1397** |
| …bunun engellisi (kısır/kaynak borcu) | 141 |
| FAZLA yazdığımız (hedef üstü) | 1127 |
| hiç yazmadığımız konu | 550 (hedefi 786 soru) |

## Ders ders

| ders | konu | sınavda çıktı | yayınlanabilir | hedef | açık | açık-engelli |
|---|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 2111 | 2030 | 1096 | 1530 | 555 | 27 |
| Muhasebe Denetimi | 352 | 333 | 363 | 350 | 151 | 8 |
| Sermaye Piyasası Mevzuatı | 345 | 204 | 232 | 350 | 148 | 28 |
| Vergi Mevzuatı ve Uygulaması | 1272 | 416 | 366 | 350 | 119 | 32 |
| Maliyet Muhasebesi | 798 | 323 | 401 | 350 | 89 | 16 |
| Finansal Tablolar ve Analizi | 461 | 498 | 403 | 350 | 74 | 13 |
| Hukuk | 1961 | 340 | 453 | 350 | 70 | 12 |
| Muh. ve Mali Müş. Meslek Hukuku | 978 | 374 | 390 | 350 | 50 | 4 |

## En çok çıkmış ama hiç yazmadığımız 25 konu

| çıkmış | hedef | konu | ders | engel |
|---:|---:|---|---|---|
| 11 | 8 | borc senedi reeskontu | Finansal Muhasebe | KISIR |
| 5 | 9 | kredili satis kaydi | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 1 | faaliyet kari orani | Finansal Tablolar ve Analizi |  |
| 3 | 5 | satislardan nakit girisi | Finansal Tablolar ve Analizi | KAYNAK-BORCU |
| 3 | 1 | ozel maliyet gideri | Finansal Muhasebe | KAYNAK-BORCU |
| 3 | 5 | ticari mal devir hizi | Finansal Tablolar ve Analizi |  |
| 3 | 6 | spk suc tipleri | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 1 | yenileme fonu iptali | Finansal Muhasebe |  |
| 2 | 2 | kredi karti tahsilati | Finansal Muhasebe |  |
| 2 | 3 | kdv hizmet tanimi | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 3 | kollektif sirket kurulusu | Hukuk |  |
| 2 | 6 | idari para cezasi | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 4 | mamul stok devir hizi | Finansal Tablolar ve Analizi |  |
| 2 | 1 | brut satis kari | Finansal Muhasebe |  |
| 2 | 2 | halka arz yontemleri | Sermaye Piyasası Mevzuatı |  |
| 2 | 4 | telif kazanci istisnasi | Vergi Mevzuatı ve Uygulaması | KISIR |
| 2 | 3 | otv mukellefiyeti | Vergi Mevzuatı ve Uygulaması |  |
| 2 | 1 | zamanasimi | Hukuk | KISIR |
| 2 | 2 | sermaye piyasasi suclari | Sermaye Piyasası Mevzuatı | KISIR+KAYNAK-BORCU |
| 2 | 3 | isyeri kira geliri beyani | Vergi Mevzuatı ve Uygulaması | KISIR+KAYNAK-BORCU |
| 2 | 2 | erken odeme iskontosu | Finansal Muhasebe | KAYNAK-BORCU |
| 2 | 2 | iliskili taraf islemleri | Sermaye Piyasası Mevzuatı |  |
| 1 | 2 | kamu denetcisi | Muhasebe Denetimi |  |
| 1 | 2 | bagimsiz denetci sartlari | Muhasebe Denetimi |  |
| 1 | 2 | dar mukellef kurum vergilendirme | Vergi Mevzuatı ve Uygulaması |  |

## Bu tablo şunu GÖRMEZ

- Konu adının farklı yazımlarını tek konuya indirmez — aynı konu iki satırda görünür ve "hiç yazmadık" sayısını ŞİŞİRİR.
- "sınavda çıktı" konu köprüsünden gelir; köprü yanlışsa hedef de yanlıştır.
- İkiz süzgecini görmez: yayınlanabilir bir soru, yayında benzeri olduğu için yine de elenebilir.
