# SİTE ARIZASI 01.11 — deneme set listesi açılmıyor (site koluna devir notu)

**EVET, ENGELLİYOR: Yeterlilik ders denemesi, Yeterlilik sık konu denemesi ve Staja Giriş sık konu denemesi sayfası çoğu açılışta set listesini hiç göstermiyor. Öğrenci set seçemiyor, deneme başlayamıyor. Yenileyince bazen açılıyor.**

Yazan: Ajan 53 (sinav kolu, 01.11). Bu not yalnız tespit ve öneri. Kod dosyasına dokunulmadı; düzeltmeyi site oturumu yapar.

## 1. Öğrenci şu an ne görüyor
- Adresler:
  - `sinav-gibi.html?tur=ders&sinav=smmm`
  - `sinav-gibi.html?tur=sik&sinav=smmm`
  - `sinav-gibi.html?tur=sik&sinav=sgs`
  - Bunlara `#set=N` ile gelen derin bağlantılar ve Nöbetçi notundaki "bu konudan 10 soru" (`&konu=`) bağlantıları da dahil.
- Sayfa başlığı ve üst menü geliyor. Set listesinin yerinde şu yazıyor: **"Setler şu an yüklenemedi. Sayfayı yenilemeyi dene."**
- Başlık altındaki rozetler yanlış kalıyor: Yeterlilik sayfasında da SGS'nin "130 soru · 165 dakika · Yanlış doğruyu götürmez" değerleri görünüyor.
- Yanlış set açılmıyor. Hiçbir set açılmıyor: set düğmesi sayısı 0.
- Etkilenmeyen sayfa: Staja Giriş 130 soruluk "sınav gibi" setleri (`sinav-gibi.html`, tür parametresi yok). Onların dizininde `deneme_ad` alanı yok.

## 2. Ölçülmüş sayılar (01.11, canlı tetikte.com)
- **Hata oranı:** 24 açılışın 22'sinde liste yüklenemedi; 2'sinde açıldı.
  - Bu 24 açılışın içinde gerçek tetikte.com sayfası var, kapısı ziyaretçi olarak ya da üye taklidiyle açılmış.
  - Telefon (390 px) ve bilgisayar (1280 px) ayrı ayrı ölçüldü.
- **Zamanlama:** Üst şerit 38–509 ms'de kalkıyor, set dizini 108–667 ms'de geliyor.
  - Bu ikisinin yarışını kaybeden açılış hata veriyor.
  - Gerçek ağda ve önbellekte oran farklı olabilir. Gerçek üye girişiyle ölçülmedi.
- **Kimler kullanıyor:** 25.10'dan beri bu üç deneme türünde `deneme_ilerleme` kaydı bırakan üye sayısı 19. Son kayıt 31.10 17:45 UTC.
  - Demek ki yarış gerçekte bazen kazanılıyor.
  - Bu, öğrencinin çoğu girişte hata görüp yenilediği anlamına geliyor.
- **Ne zamandan beri:** Hata 07.10'dan beri var (5b9098da: `deneme_ad`; menu.js 5a57d234: ortak üst şerit 04.10). Kabuk-it ya da kasa yayınıyla ilgisi yok.

## 3. Kök neden
- `sinav-gibi.html` **satır 686** (origin/main 31541e23):
  ```js
  if(d.deneme_ad){ $('sgUstAd').textContent=d.deneme_ad; document.title=...; }
  ```
- `#sgUstAd`, satır 132'deki eski iz satırının içinde duruyor: `<div class="top">…<span id="sgUstAd">`.
- `menu.js` (`ustSeritKur`, `kur()` içinde) alt sayfalardaki `.top` öğesini kaldırıp yerine ortak üst şeridi koyuyor: `top.parentNode.removeChild(top)`.
  - `menu.js` sayfa sonunda `defer` ile yükleniyor ve ayrıştırma biter bitmez koşuyor.
- Set dizini (`veri/deneme/<sinav>-<tur>-dizin.json`) `fetch(..., {cache:'no-store'})` ile ağdan geliyor. Bu yüzden çoğunlukla `menu.js`'ten **sonra** varıyor.
- O anda `$('sgUstAd')` boş (`null`) dönüyor ve `.textContent` yazmak `TypeError` atıyor ("Cannot set properties of null (setting 'textContent')").
- Hata zincirin `catch` bölümüne düşüyor. O bölüm de "Setler şu an yüklenemedi" yazıyor.
- Sonuç: `setleriCiz()`, `#set=N` açılışı ve `?konu=` özel denemesi hiç çalışmıyor.
- Satır 665'teki `$('sgUstAd')` hata vermiyor, çünkü eşzamanlı çalışıyor ve `menu.js`'ten önce koşuyor. Yine de aynı korumayı almalı.

## 4. Önerilen değişiklik (tek satır)
`sinav-gibi.html` satır 686:
```js
if(d.deneme_ad){ var ua=$('sgUstAd'); if(ua) ua.textContent=d.deneme_ad; document.title=(d.ad?d.ad+' · ':'')+d.deneme_ad+' | Tetikte'; }
```
İsteğe bağlı aynı koruma satır 665 için (`sgUstSinav` ve `sgUstAd`):
```js
var us=$('sgUstSinav'); if(us) us.href=...; var ua=$('sgUstAd'); if(ua) ua.textContent=tAd;
```
- Bu iki öğe ortak şeritte görünmüyor. Yazının yazılmaması ekranda hiçbir şeyi değiştirmez; sekme başlığı (`document.title`) yine yazılır.
- `menu.js`'e dokunmaya gerek yok. Şerit kaldırma kuralı başka sayfalarda doğru çalışıyor.
- Düzeltmenin işe yaradığını ölçtüm. Tarayıcıda `#sgUstAd` öğesini canlı tutunca yarışı kaybeden açılışta da liste 61 setle açıldı ve Set 9 başladı.
  - Görüntüler: `scratchpad\a53\ekran\uye-yamali-sik-*.png`.

## 5. Nasıl sınanacak (telefon + bilgisayar)
Ölçüm betiği:
`C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\9045aa81-5f57-4816-9087-44ca6bc518a8\scratchpad\a53\canli-uye.js`
- Canlı tetikte.com sayfasını gerçek köken ve önbellekle açıyor. Yalnız `paket-kapisi.js` yanıtını tarayıcıda taklitle değiştiriyor: kapı açık, set soruları canlı kasa satırından.
- Cevap kütüğüne, deneme ilerlemesine ve GoatCounter'a giden istekleri tarayıcıda düşürüyor; canlıya yazmıyor.
- Telefon 390×844 ve bilgisayar 1280×900 açıyor.

Yayından (GitHub Pages, ~2–5 dk) sonra **yamasız** koş:
```
node canli-uye.js "https://tetikte.com/sinav-gibi.html?tur=sik&sinav=smmm"  <onek> <stub.js> 6 9
node canli-uye.js "https://tetikte.com/sinav-gibi.html?tur=ders&sinav=smmm" <onek> <stub.js> 6 1
node canli-uye.js "https://tetikte.com/sinav-gibi.html?tur=sik&sinav=sgs"   <onek> <stub.js> 6
```
- Stub dosyası örneği: `scratchpad\a53\stub-sik09.js`. Ders seti için `kur.js set ders 1` ile yeniden üretilir.
- **Beklenen:** Her viewport'ta 6 açılışın **6'sı** için `set dugmesi:` > 0. Yeterlilik sık konuda 61, ders denemesinde 80 olmalı. `setler:` alanında "yüklenemedi" geçmemeli. `hata:[]` boş olmalı.
- Ölçüm satırındaki `zaman:{topGitti, dizin}` alanında `topGitti < dizin` olduğu açılışlar özellikle önemli: önce düşen durum bu.
- Set açılınca `harita:` = `toplam:` = 20 olmalı (Set 9 ve 12 için aşağıdaki 6. bölüme bak).
- **Ekran:** `<onek>-liste-telefon.png` ve `-bilgisayar.png` dosyalarında set listesi ile Yeterlilik rozetleri (20 soru · 45 dakika · yanlış 0,25) görünmeli. `<onek>-set-*.png` dosyalarında soru, 5 şık ve soru haritası görünmeli.
- Ayrıca Cem kendi üye hesabıyla telefonda ve bilgisayarda bir kez açmalı. Betik gerçek üye oturumunu taklit etmiyor.

## 6. Ayrıca: 2 sık konu seti 19 soru açıyor
- **Nerede:** Yeterlilik sık konu, Finansal Muhasebe **Set 9** ve **Set 12**. Listede "20 soru" yazıyor, açılınca "soru 1 / 19".
- **Neden:**
  - Bitirme kasa yayını 41279967041 (bfa8485f) kasayı 3.733 soruyla yeniden yazdı. `smmm-gm11-1-fmuh-cokzor/kp-01` (Set 9) ve `smmm-gm11-1-fmuh-kolay/kp-01` (Set 12) kasadan çıktı.
  - Aynı koşunun "Bitirme kabuklarini it" adımı düştü ("itme çakışması, rebase düştü"). Bu yüzden setler hâlâ eski seçimle kurulmuş hâlde: 2db20d14, 01.11 04:02 UTC.
  - `sinav-gibi.html` `kasaDoldur` kasada bulamadığı kimliği sessizce atlıyor ve toplamı düşürüyor.
- **Ölçüm:**
  - Canlı 80 ders setinin 1.600 kimliğinde kasada olmayan 0.
  - 61 sık konu setinin 1.220 kimliğinde kasada olmayan 2.
  - Sana özel havuzda kasada olmayan 2. Kasaya yeni girip havuza girmeyen 40 soru var.
- **Kendiliğinden düzelme yolu:**
  - Bir sonraki SMMM kasa yayını kabuk adımını geçerse `veri/deneme/**` yeni seçimle itilir ve iki set 20 soruya döner. 41281944313 01.11 06:43 UTC'de koşuyordu.
  - Kabuk adımı yine düşerse yalnız `veri/deneme/**` itmek yeter. Kabuk HTML'leri 28.10'dan (3d41c29e) beri değişmeden çıkıyor.
  - Bu düzeltme sinav (bitirme) kolunun işi, site kolunun değil.
