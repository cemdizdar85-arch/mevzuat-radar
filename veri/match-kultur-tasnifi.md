# `-match` kültür tuzağı — 30 kanıtlı kusurun tasnifi (30.08.2026)

Tarayıcı (`arac/match-kultur-tuzagi-tarayici.ps1`) 360 betikte 66.226 satır
taradı ve **30 kanıtlı kusur** buldu. Kanıt: kalıbın karakter sınıfı `I`/`i`
harfinde `-match` (IgnoreCase, kültüre bağlı) ile `-cmatch` (ordinal) farklı
sonuç veriyor.

**Kanıtlı desen, kanıtlı ZARAR demek değildir.** 30 satırın her biri elle
okundu ve işlediği verinin ne olduğuna göre üçe ayrıldı. Toptan düzeltme
yapılmadı — yalnız A sınıfı düzeltilir.

| sınıf | adet | ne demek |
|---|---:|---|
| **A — gerçek zarar** | **9** | Türkçe metin işliyor, `I`/`ı` kesin geçiyor, sonuç sessizce bozuluyor |
| B — düşük risk | 15 | Latin veri (madde eki, standart kodu, dosya yolu); `I` pratikte gelmiyor |
| C — zararsız | 6 | Kalıptan önce `ToLowerInvariant()` var, harf zaten normalleşmiş |

---

## A sınıfı — düzeltilecek (9 satır)

Ortak özellik: **sessiz** bozulma. Hata vermiyor, yanlış sonucu doğru gibi
üretiyor. Çözüm her birinde aynı: o satırda `-match`/`-replace` yerine
`-cmatch`/`-creplace` (ordinal).

### 1. Dosya/kayıt adı çakışması (3 satır) — en tehlikelisi
```
birlik-urge-hasat.ps1:87    $sorgu.q  -replace '[^a-zA-Z]',''
cikmis-soru-karnesi.ps1:50  $don      -replace '[^0-9A-Za-z]','_'
cikmis-soru-yut.ps1:47      $don      -replace '[^0-9A-Za-z]','_'
```
Türkçe sorgu/dönem adındaki `I` "harf değil" sayılıp siliniyor ya da `_`
oluyor. **İki farklı girdi aynı dosya adına düşebilir** — biri diğerini ezer
ve kimse fark etmez. Kayıp sessizdir, kütükte iz bırakmaz.

### 2. Satır sınıflandırması bozuluyor (1 satır)
```
cagri-hasat.ps1:124   if($s -notmatch '[a-zçğıöşü]{3}\s+[a-zçğıöşü]{3}'){ continue }
```
Satırın kendi yorumu: *"BASLIK KUTUSU (Her Kelime Buyuk)"* — yani büyük harfli
başlık satırlarını atlamak için var. IgnoreCase yüzünden `I` küçük harf
sayılıyor, **başlık satırı içerik sanılıp hasada giriyor.**

### 3. Ölçüm birimi kesiliyor (1 satır)
```
gozetim-onarici.ps1:49   'Dolar[ıi]\s*/\s*([A-Za-z]+)'
```
`I` sınıfa girmediği için "LITRE" → **"L"** olarak kesiliyor. Gözetim
tebliğinde birim yanlışsa hesap da yanlış olur.

### 4. Firma adı bozuluyor / yanlış sınıflanıyor (3 satır)
```
ihale-sonuc-ozet.ps1:36        "$x".ToUpper() -replace '[^A-ZÇĞİÖŞÜ0-9 ]',' '
ihale-firma-adi-denetimi.ps1:82  $_.ad -match '-[A-ZÇĞİÖŞÜ]'
ihale-kesik-ikn-cikar.ps1:74     $ad   -match '-[A-ZÇĞİÖŞÜ]'
```
İlki ayrıca **`ToUpper()` kültüre bağlı**: invariant kültürde `'ı'.ToUpper()`
= `'ı'` (değişmez!), sınıfta `ı` olmadığı için boşluğa çevriliyor —
**runner'da bozuk, yerelde doğru.** Diğer ikisi tire sonrası büyük harfi
"şahıs eki" sayıyor; IgnoreCase küçük `i`'yi de tuttuğu için yanlış
sınıflandırma üretiyor.

### 5. Mevzuat adı ayrıştırma (1 satır)
```
kaynak-kok.ps1:41   '^(.*?)\s+(m\.|muk\. m\.|...|k[iı]s...'
```
Kaynak adından madde/kısım ayırıyor. Türkçe mevzuat adı doğrudan girdi;
`I` ayrımı ayrıştırmayı kaydırıyor.

---

## B sınıfı — düşük risk (15 satır, düzeltilmedi)

Kalıbın işlediği veri Latin: madde eki (`m.5/a`), standart kodu (`TFRS 9`,
`BDS 200`), dosya yolu (`veri/*.json`), matematik ifadesi. Bu verilerde `I`
harfi pratikte gelmiyor.

```
aritmetik-kapisi.ps1:113,134   ·  soru-uret-v2.ps1:1165,1182,1201
butunluk-kapisi.ps1:100        ·  dayanak-nobetci.ps1:72
kesik-madde-onar.ps1:50,125    ·  standart-yut.ps1:147,439,571
baglanmamis-tara.ps1:72,73     ·  ambar-envanteri.ps1:46
```

**Neden düzeltilmedi:** düzeltmenin kendisi risk taşır (kalıp davranışı
değişir, testi yok). Kanıtlanmamış bir zarar için canlı hattı ellemek,
kazançtan çok kayıp getirir. Günlük kapı bunların **artmasını** engelliyor;
azaltmak ayrı bir karar.

## C sınıfı — zararsız (6 satır)

Kalıptan **önce** `ToLowerInvariant()` var; harf zaten normalleşmiş, sınıf
doğru harfi görüyor.

```
havuz-dogrulayici.ps1:90  ·  k15-sinav-teknigi.ps1:81  ·  kopya-ayikla.ps1:58
zorluk-kiyas-v2.ps1:46    ·  terim-taramasi.ps1:83,127
```

Tarayıcı bunları yine de işaretliyor: satırın kendisi kültüre bağlı, yalnız
**önündeki normalleştirme** kurtarıyor. O satır silinirse kusur doğar — yani
işaret yanlış değil, bağlam koruyucu.

---

## Kural

⭐ **"Koşuda sorun çıkmadı" ile "kod doğru" aynı şey değildir.** Bugün üç
kültür tuzağı çıktı, üçü de GitHub runner'ın invariant kültürü sayesinde
gizlenmişti. `ihale-sonuc-ozet.ps1:36` bunun tersi: **runner'da bozuk,
Cem'in makinesinde doğru.** İki taraf da tek başına kanıt değil.
