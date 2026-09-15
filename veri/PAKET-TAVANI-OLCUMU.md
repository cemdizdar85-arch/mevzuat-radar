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

---

## GÜNCELLEME 15.09 ~20:10 · Cem "yap tavansız" — kod değişti + iki kollu prova

**Kod (`66c413f6`):** 15 karakter tavanı `PaketTavani()` işlevine bağlandı; varsayılan **tavansız**, `-EskiPaketTavani` eski değerleri birebir getirir. Kaynak sayısı sınırları (AmbarCek 10, KaynakSirala 4) ve model çıktı jetonu sınırları değişmedi.

**Prova:** SGS Finansal Muhasebe T2 partilerinden (kolay/zor/çokzor) paketi tavanı aşan 60 tarihsel RET + 60 tarihsel KABUL soru. Asıl parti dosyalarına yazılmadı: kopya etiketler, yalnız hakem (`-SadeceHakem -HakemYenileId`, toplu), paket `kaynak_adlar`tan yeniden kuruldu; her soru iki kez soruldu (eski tavan / tavansız). Kopyalar prova sonunda silindi. **Bedel ≈1,31 USD** (eski kol 0,63 · tavansız kol 0,68); tahminim ≈0,8 idi, kopya partilerin atıf genişletmesi ve istem boyu tahminin üstünde çıktı.

| Tarihsel | Soru | EVET — eski tavan | EVET — tavansız | HAYIR→EVET | EVET→HAYIR |
|---|---|---|---|---|---|
| RET | 60 | 10 | 15 | 8 | 3 |
| KABUL | 60 | 56 | 54 | 1 | 3 |

- **Gürültü kontrolü:** eski kolda paketi kırpılmayan 43 soruda (iki kolda paket aynı) karar değişen 2 (%4,7). Paketi gerçekten kırpılan 77 soruda karar değişen 13 (%16,9). → Tavanın hakem kararına etkisi **gerçek** (gürültünün ~3,6 katı).
- **Yön karışık:** retten kabule dönen 8 sorunun gerekçelerinde hakem kuralı artık pakette buluyor (ör. "320 Satıcılar tanımı", "TMS 7 net gösterim istisnası") → tavanın yol açtığı yanlış retler. Kabulden redde dönen 3 sorudan biri (kp-13) açık dikkat dağılması: hakem "kaynak yalnız TMS 7, iç kontrol ve TMS 41 içerir" diyerek büyüyen paketteki ilgisiz metne takılmış. Bir şüpheli kabul: kp-125 eski kolda "ders dışı" (IIA/COSO), tavansızda EVET.
- **Net etki bu örneklemde ~nötr:** retlerde +5/60, kabullerde −2/60. Tavanı aşan 100 soruya ölçeklenince (ret oranı ~%21) kazanç ≈ +1,8, kayıp ≈ −2,6 soru — gürültü payı içinde.

**Okuma:** Tavan bazı doğru soruları kesik paket yüzünden düşürüyordu, bu kanıtlandı. Ama tavanı tamamen kaldırmak pakete ilgisiz kaynakları da (atıf genişletmesi 10 kaynağa kadar) doldurduğu için hakemi başka sorularda şaşırtıyor. Sorunun kökü karakter sayısı değil, **pakete ilgisiz kaynağın girmesi**.

**Durum:** Kod tavansız kaldı (Cem kararı; bedel etkisi +%8 hakem girdisi). Önerilen sonraki adım Cem onayında: tavansız + atıf genişletmesinde yalnız dayanakla aynı aileden kaynak (KGK'daki KAPI-AILE mantığının SGS/SMMM'ye taşınması), aynı 120 soruda yeniden prova (≈0,7 USD).

---

## GÜNCELLEME 15.09 ~20:45 · Cem "1.2.3 üçünüde yap"

**Öneri 1 — atıf genişletmesine süzgeç: yapılmadı, para harcanmadı.** Parasız incelemede önerdiğim "aile süzgeci" ölçülen gürültüyü yakalamıyor: kp-24'teki ilgisiz notların hepsi TEORİ ailesinden (izinli aile), kp-13'teki TMS 7 p.1/p.3/p.45 da izinli ailede. Kök neden ölçüldü: dayanak paragraf numarası vermeden standart anınca ("TMS 7 …") atıf deseni `TMS 7 p.%` olup ambardan standardın ilk kayıtları (sırasız, limit 6) geliyor. Bunun yerine "dayanak+konu kelimelerine göre en ilgili 4 paragraf" seçimi yazıldı ve 120 prova sorusunda parasız sınandı: yalnız 28 atıfta devreye giriyor, seçtiği paragraflar çoğu kez yine ilgisiz (ör. "TMS 16 amortisman" → TMS 1 p.104; "kontrol çevresi" → BDS 315 p.A241) ve kp-13'ü çözmüyor (dayanağa ilgisiz standart yazılmış). 120 soruluk ödemeli prova bu kadar küçük etkiyi ölçemeyeceği için ≈0,7 USD harcanmadı; kod geri alındı (ölü kod bırakılmadı).
**Asıl kök (ölçüldü, iş emri):** gürültü hakem aşamasında değil ÜRETİM aşamasında doğuyor — `kaynak_adlar` listeleri soruyla ilgisiz TEORİ notlarıyla dolu (kp-24 "satış iskontosu": hisse senedi getirisi, ortak maliyet dağıtımı, tahvil türleri…) ve model dayanağa ilgisiz standart yazabiliyor (kp-13 "faaliyet kârı" → TMS 7).

**Öneri 2 — bitirme oturumuna not:** açık oturumlara gönderildi; ikisi de bitirme değildi (SGS GM ve site oturumu), bitirme oturumu şu an açık değil. Not kalıcı olarak hafıza endeksinde (`paket-tavani`) ve bu raporda. SGS GM oturumunun bildirdiği karıştırıcı: 7223deb6 (15.09 19:36) KAPI-HG'yi değiştirdi; muhasebe partilerinde ret farkının bir kısmı ondan gelebilir.

**Öneri 3 — izleme:** `arac/tavan-izleme.ps1` → `veri/tavan-izleme.json` (bedel 0). Dönem ayrımı: dosya 66c413f6 sonrası değişmiş + saklı paket > 4.500 kr (tavansız izi). Başlangıç çizgisi (20:40):

| Sınav | Dönem | Parti | Hakemli | Ret | Ret oranı |
|---|---|---|---|---|---|
| SGS | önce | 893 | 6.315 | 1.042 | %16,5 |
| SMMM | önce | 34 | 102 | 16 | %15,7 |
| KGK | önce | 14 | 325 | 24 | %7,4 |

Tavansız dönem partisi henüz yok. Yeni üretimden sonra aynı betik koşulur; ret oranı başlangıç çizgisinin belirgin üstüne çıkarsa `-EskiPaketTavani` ile karşılaştırılır.
