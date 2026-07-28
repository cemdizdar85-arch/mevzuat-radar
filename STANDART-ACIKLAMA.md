# TETİKTE — AÇIKLAMA STANDARDI (kilitli)

**Karar tarihi:** 29.07.2026 · **Karar veren:** Cem Dizdar · **Uygulayan:** GM

Bu belge **son karardır.** Üretilen ve yenilenen her açıklama buna uyar. Tekrar
tartışılmaz; değişmesi gerekirse bu dosya değişir ve sebebi buraya yazılır.

**Hedef:** Konuyu hiç bilmeyen biri, soruyu çözdükten sonra konuyu anlamış olsun.
Kitap ezberleterek değil, **soru çözdürerek öğretmek.** ABD'deki emsali örnek
alıyoruz ve **ondan iyisini** yapıyoruz.

---

## 1. Doğru şıkkın açıklaması — dört parça, bu sırayla

```
Ne soruluyor: <tek cümle, hiç muhasebe bilmeyene>
Kural: <maddeye dayalı ama günlük dille>
Bu olayda: <kuralın soruya uygulanışı, adım adım, varsa rakamlı>
Akılda kalsın: <tek cümle>
```

**Uzunluk: 400–700 karakter.** (Bugünkü ortalama 162 — yani iki cümle; o boyda
"bu şık yanlış çünkü" denir, konu öğretilmez.)

"Kural" parçası örneği:
> Kanun diyor ki: alacağın şüpheli sayılması için dava ya da icra aşamasında olması lazım.

## 2. Yanlış şıklarda tek iş: **tuzağı adlandırmak**

"Yanlıştır" demek öğretmez. Kalıp:

```
Bu şık A ile B'yi karıştırıyor. A şudur; B ise budur.
```

**120–250 karakter.** Sınavda kaybettiren şey bilgi eksiği değil, **karıştırma**.
Öğrenci neyi karıştırdığını görmeli.

## 3. Dil kapısı — ölçülür, temenni değildir

Robot ölçer; **geçmeyen açıklama yayına çıkmaz** (yayın kapısı kurulu).

| kural | sınır |
|---|---|
| Cümle ortalaması | ≤ 20 kelime |
| Tek cümle | ≤ 30 kelime |
| Teknik terim | ilk geçtiği yerde parantez içinde bir cümlelik karşılığı |
| Çatı | edilgen değil **etken** — "kayıt yapılır" değil, "işletme şu kaydı yapar" |

## 4. Görsel borcu — muhasebe sorusu tablosuz olmaz

Site bunları **zaten çiziyor**; veri boştu.

- **`tablo`** — bilanço / gelir tablosu / nakit akış / analiz soruları.
  Yapı: `{baslik, kolonlar:[...], satirlar:[[...],[...]]}`.
  Vurgulanacak satırda hücreye `←` konur, site o satırı öne çıkarır.
- **`yevmiye`** — kayıt soruları. Yapı: `[{hesap, borc, alacak}]`.
- **`yanlis_kayitlar`** — *hayalet kayıt*: yanlış şıkkı seçen, **kendi cevabının
  defterdeki hâlini** soluk/kırmızı görür, yanına doğrusu gelir.
  Yapı: `{"B":[{hesap,borc,alacak}], ...}`.

**Kural:** Finansal Muhasebe, Maliyet Muhasebesi, Mali Tablolar Analizi ve
Finansal Tablolar ve Analizi derslerinde tablo ya da yevmiye **zorunludur** —
konu elveriyorsa. Elvermiyorsa sebebi açıklamada görünür.

## 5. Değişmeyenler

**Değişir:** `aciklama`, `hap`, `tablo`, `yevmiye`, `yanlis_kayitlar`
**ASLA değişmez:** `soru`, `siklar`, `dogru`, `kaynak`

Açıklamayı zenginleştirmek için sorunun kendisine dokunmak **yeni soru
üretmektir**; bu kanaldan geçmez.

## 6. Rakam kapısı — en sıkı kural

Açıklamada geçen **her sayı**, kaynakta (madde metni + soru + şıklar) geçmek
zorundadır. Geçmiyorsa o yenileme **çöpe atılır, eski açıklama kalır.**

Sebebi: 28.07 gecesi bulunan üç gerçek hatanın üçü de **uydurulmuş rakam/süre**
idi — SGK primi %20 yerine %21, AATUHK 7 gün yerine 15 gün, 3568 alıkoyma
süresi. **Açıklamayı zenginleştirirken aynı hatayı üretmek, hiç
zenginleştirmemekten kötüdür.**

Soru bir maddeye bağlıysa (kasada 4.101 soru bağlı) madde metni isteme konur —
model hafızasından değil **metinden** yazar.

## 7. Sıra

1. Pilot (150 soru, Finansal Muhasebe) → GM elle okur
2. Geçerse ders ders tamamı
3. Her parti sonrası: rakam kapısı + dil kapısı red oranı raporlanır
