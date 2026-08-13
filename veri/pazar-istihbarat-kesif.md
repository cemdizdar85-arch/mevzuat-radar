# PAZAR İSTİHBARATI — VERİ KEŞFİ (13.08.2026, Cem talimatı "keşfe gir")

Vitrin kutusunun (30.07, YAKINDA rozetli, eski motor işi #65 — defter kaybolunca izlemeden düşmüştü) veri fizibilitesi ölçüldü.

## SONUÇ: MOTOR KURULABİLİR — 0 USD, anahtarsız, robot dostu

**Çalışan kaynak: BM Comtrade public preview API** (kaynağı TÜİK'in resmî bildirimi):
`https://comtradeapi.un.org/public/v1/preview/C/M/HS?reporterCode=792&period=YYYYMM&cmdCode=HS6&flowCode=M&partnerCode=0`
- Anahtar İSTEMİYOR; JSON döner (~300 kayıt/kod-ay).
- **Toplam satırı süzme kalıbı (ölçüldü):** `partnerCode=0 & partner2Code=0 & customsCode='C00' & motCode=0` → tek satır.
- **Kanıt çekimi:** Aralık 2025, HS 950300 (oyuncak) TR ithalatı = **35.062.311 USD · 2.815.503 kg · birim fiyat 12,45 USD/kg** ✓ (değer/netWgt).
- Ülke kırılımı da aynı yanıtta var (partnerCode≠0) → "en çok hangi ülkeden" bonusu mümkün.

## KISITLAR (dürüst)
1. **Gecikme ~8 ay:** son dolu dönem 202512 (202601+ boş, 13.08.2026 itibarıyla). Araç "güncel nabız" değil **yapısal trend** anlatır — kutunun vaadi ("pazar büyüyor mu, ortalama birim fiyat ne") zaten trend dili, uyumlu. TÜİK 2026'yı BM'ye yükleyince kendiliğinden dolar.
2. **HS6 düzeyi:** GTİP 12 hanenin ilk 6 hanesi (ürün ailesi). Ekranda dürüst yazılır: "GTİP'inin ilk 6 hanesi düzeyinde".
3. **Uç bazen yavaş/askıda:** bir istek 2 dk timeout yedi; sonra 0,5 sn'ye döndü. Hasat: istek arası 8-10 sn bekleme + tekrar deneme + gece cron'u. İzlenen kod listesi küçük tutulur (gtip-durum.json'daki kodların HS6 kümesi ya da lead'lerin tanıttığı kodlar).
4. Kapalı alternatifler: biruni.tuik.gov.tr/disticaretapp ZK/JS kabuğu (robota kapalı), data.tuik.gov.tr JS kabuğu.

## MOTOR TASLAĞI (kurulum açılış sonrası — Cem sırası)
- `motor/pazar-hasat.ps1`: izleme listesindeki HS6 kodları × son 24 ay → `veri/pazar/{hs6}.json` {ay, degerUsd, netKg, birimUsdKg, topUlkeler[]}; idempotent, dolu ayı yeniden çekmez; K4-tarzı sapma kapısı + yazma sonrası sayım.
- Ekran: kutudaki vaat — hacim trendi çubukları + birim fiyat çizgisi + YoY %; tazelik rozeti "veri dönemi: 2025-12 (Comtrade/TÜİK)".
- Lead bağlantısı: ?niyet=gtip kayıtları açılınca "ilk kullananlar" e-postasıyla buluşur.
