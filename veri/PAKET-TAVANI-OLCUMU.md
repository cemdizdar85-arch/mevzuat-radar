# Hakem/kör kaynak paketi tavanı ölçümü — 15.09.2026

**Soru:** `motor/kalip-parti-uret.ps1` hakeme ve kör çözücüye giden kaynak paketini **4.500 karakterde** kırpıyor (`PaketKirp`, satır 2648/3064/3647; `-KorKaynakTavan 4500`). Bu tavan retlere yol açıyor mu?
**Bedel:** 0 (model çağrısı yok, ambar yalnız okundu). Cem 15.09 "1.2.3 üçünüde yap", öneri 3. **Tavanın değiştirilmesi Cem kararıdır; bu ölçüm hiçbir şeyi değiştirmedi.**

## Yöntem

- Kaynak: yerel parti önbellekleri `veri/fabrika/kalip-parti-*.json` (938 dosya, 6.762 soru, `kaynak_adlar` taşıyan).
- Her soru için paket boyu ≈ Σ (kaynak_ad metni + ad) — hakemin gerçekte gördüğü paketin **vekili** (üretimde paket AmbarCek'ten kurulup kırpılır; `kaynak_adlar` hakem sonrası dolar).
- Hakem kararı ve gerekçe önbellekten; "kaynakta yok / yer almıyor / doğrulanamadı" kalıbı ayrıca sayıldı.
- Betik: oturum scratchpad `paket-tavan-olcumu.ps1` (yeniden koşulabilir).

## Sonuç

| Sınav | Soru | Paketi 4.500'ü aşan | Tek parçası tek başına aşan | Hakem reddi — aşanlarda | Hakem reddi — altındakilerde | "Kaynakta yok" gerekçesi (aşan / altında) |
|---|---|---|---|---|---|---|
| SGS | 5.757 | 3.356 (%58,3) | 299 | 697/3.332 (**%20,9**) | 204/2.377 (%8,6) | 310 / 93 |
| SMMM | 672 | 511 (%76,0) | 3 | 125/511 (**%24,5**) | 20/161 (%12,4) | 36 / 9 |
| KGK | 333 | 237 (%71,2) | 12 | 20/222 (**%9,0**) | 4/93 (%4,3) | 2 / 1 |

Paket boyu dağılımı (tüm sınavlar): medyan 6.363 · %75 11.963 · %90 16.625 · %95 19.764 · en büyük 106.861 karakter.
Tavan 6.000 olsaydı aşan 3.476 · 8.000 olsaydı 2.862 · 10.000 olsaydı 2.210.

## Okuma

1. **Tavanı aşan sorularda hakem reddi üç sınavda da ~2,1–2,4 kat.** "Kaynakta yok" gerekçesi SGS'de aşanlarda 310, altındakilerde 93.
2. **Bu bir korelasyondur, nedensellik kanıtı değildir:** büyük paketler zor/çok maddeli konulara ait olabilir. Nedenselliği yalnız aynı soruları iki tavanla hakeme sormak gösterir (aşağıda prova önerisi).
3. **15.09'da iki somut vaka tavan kaynaklıydı:** SPK kp-03 (i-SPK.128.23 ilke kararı paketten düştü → kör çözücü "750.000.000 TL eşiği kaynakta yok") ve GDS kp-03 (GDS 3402 p.9, 6.408 kr, tek başına tavanı aştığı için tamamen düştü → hakem "1 inci tip rapor tanımı kaynakta yok"). İkisi de dayanak kısa paragraflara taşınınca geçti.
4. **Tek parçası tek başına tavanı aşan 314 soru** (SGS 299) tavan yükselmeden hiçbir koşulda tam paket göremez.

## Bedel etkisi (tahmin — fiyat tablosu varsayımı: Haiku 1/5, Sonnet 3/15 USD/M; toplu yarı fiyat)

Tavanı 4.500 → 9.000 karakter yapmak soru başına en fazla ≈ 4.500 karakter (≈ 1.300–1.500 jeton) ek girdi demek:
- hakem (Haiku, toplu): ≈ +0,0007 USD
- kör çözüm (Sonnet, toplu): ≈ +0,002 USD
- hakem2 paketi de büyürse (ölçülmedi): ≈ +0,002 USD
- **Toplam ≈ +0,003–0,005 USD/soru.** 1.068 soruluk bitirme planında ≈ +3–5 USD.

Karşılaştırma: bir soruyu reddedip yeniden yazdırmak/doğrulatmak bu farkın ~10 katı.

## Karar Cem'de — önerilen prova (≈ 0,5 USD)

Hakem reddi almış ve paketi tavanı aşan **100 SGS/SMMM sorusunu** (soru metni değişmeden) tavan 9.000 ile yalnız hakeme yeniden sor (`-HakemYenileId`, toplu). Karar değişimi oranı nedenselliği ölçer; oran %20'nin üstündeyse tavanı yükselt, altındaysa bırak.

## Bu ölçümün değiştirmediği şeyler

Üretici koduna, tavana, hiçbir soruya ve kasaya dokunulmadı.
