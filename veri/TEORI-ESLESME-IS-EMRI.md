# TEORİ NOTU EŞLEŞTİRME KUSURU — ölçüldü, çaresi BULUNAMADI

> 12.09.2026, Cem "3. yapalım". Ölçüm yapıldı, kusur **doğrulandı**, ama
> denenen çare sınavda **kötüleştirdi** ve UYGULANMADI.

## Kusur (ölçüldü)

777 KAYNAK-EKSİK retinde, TEORİ notu çekilen **363 soru** var.
Bunların **91'inde (%25)** çekilen not ile konunun **tek ortak kelimesi yok**:

| konu | çekilen teori notu |
|---|---|
| `kdv belgesiz mal` | Zeyilname (sigorta sözleşmesinde değişiklik belgesi) |
| `kar payi odeme kaydi` | Ödemeler dengesi ve kayıt sistemi |
| `bds 260 ust yonetimle iletisim` | Bağlı menkul kıymet, iştirak ve bağlı ortaklık ayrımı |
| `denetim gorusu turleri` | BDS 570 işletmenin sürekliliği |
| `standart oranlar` | Marj oranlarından satış maliyetinin bulunması |

Hakem bu paketlere "kaynak konuyu kapsamıyor" deyip soruyu düşürüyor.

## Kök sebep (bulundu)

`motor/kalip-parti-uret.ps1` > `PaketKirp` satır 1770:

    if(-not "$paket".Trim() -or $paket.Length -le $tavan){ return $paket }

Fonksiyonun içinde **alaka puanlaması var** (konu kökleri kaynak adında geçiyor mu)
ama bu erken çıkış yüzünden **yalnızca paket 4.500 karakteri aştığında** çalışıyor.
Paket tavanın altındaysa alakasız kaynak olduğu gibi modele gidiyor.

## Denenen çare ve NİYE UYGULANMADI

Süzgeci tavandan bağımsız çalıştırmayı denedim (alaka puanı 0 olan blok düşsün,
en az bir alakalı blok kalmak şartıyla). Gerçek vakalarla sınandı:

| vaka | sonuç |
|---|---|
| `kdv belgesiz mal` | hiçbir şey atılmadı (her iki kaynak da 0 puan) — çare işlemedi |
| `kar payi odeme kaydi` | **YANLIŞ blok atıldı**: alakasız "Ödemeler dengesi" TUTULDU (adında "ödeme" geçiyor), doğru kaynak `THP 570 Geçmiş Yıllar Kârları` DÜŞÜRÜLDÜ |

İkinci vaka **gerileme**dir: çare, doğru kaynağı atıyor. Uygulanmadı, geri alındı.

## Niye kelime örtüşmesi yetmiyor

- **Ad üzerinden puanlama fazla agresif**: doğru kaynağın ADINDA konu kelimesi
  geçmeyebilir (`THP 570 Geçmiş Yıllar Kârları` ile `kar payi odeme kaydi`).
- **Metin üzerinden puanlama fazla gevşek**: alakasız not da konu kelimesini
  taşıyabilir (`çek zorunlu unsurları` ile Meslek notundaki "zorunluluğu").
- Kısa konu adlarında 4+ harf kuralı çoğu kökü eliyor (`kdv`, `mal`, `kar` düşüyor).

## Ne gerekiyor

Kelime örtüşmesinden **daha güçlü bir alaka sinyali**. Üç aday:
1. **Dayanak eşleşmesi**: çekilen kaynağın künyesi sorunun dayanağıyla uyuşuyor mu
   (bu ölçüm zaten var: 777 retin 158'i "künye var ama bulunamadı").
2. **Hesap/madde numarası eşleşmesi**: `THP 570` ↔ konu metnindeki hesap kodu.
3. **Anlamsal benzerlik** (gömme vektörü) — ambar zaten vektör taşıyorsa en sağlam yol.

⛔ Bu iş emri kapanmadı. Ölçüm elde, çare yok.