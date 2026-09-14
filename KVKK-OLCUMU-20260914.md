# KVKK aydınlatma metni ölçümü — 14.09.2026

> ✅ **UYGULANDI 14.09.2026 (kvkk.html sürüm 2).** Cem: "avukata 100 bin vermeyeceğiz, büyük firmaları
> denetle ve gereğini yap". Bölüm 1 ve 2'deki bütün akışlar metne girdi (veri-amaç-hukuki sebep-saklama
> tablosu, 12 satır), alıcı listesi GoatCounter (Finlandiya/Almanya, IP saklamaz — sağlayıcının gizlilik
> sayfası) ve OpenRouter ile tamamlandı, hız sınırı sayacındaki IP (rate_log, ~10 dk) eklendi, cihazda
> tutulanlar ve başvuru usulü (Başvuru Tebliği unsurları) yazıldı, açık rıza `#riza` ile AYRI bölüm oldu.
> Ölçülerek doğrulanan sözler: soru-cevap aracı soruyu tabloya yazmıyor (net-cevap.ts); cevap/kâğıt/form
> kayıtları anon'a kapalı (401/42501).
> **KAPANMAYANLAR (metinle kapanmaz):** (11) ABD sağlayıcıları için standart sözleşme + Kurul bildirimi —
> metin "süreç yürütülmektedir, veri asgaride" diyor; (15) İYS kaydı.
> ✅ 14.09 KAPANDI: (10) unvan — D&B + MERSİS kaydıyla "Dizdar Denetim Danışmanlık ve Yazılım A.Ş.", 46 yerde
> birleştirildi; (12) saklama — `motor/saklama-robotu.js` + `saklama-robotu.yml` her gece (kuru koşu ve sıfır
> satırlık yazma provası geçti), "hesabımı sil" için `motor/hesap-sil.js`; metne 90 günlük şifreli yedek cümlesi
> eklendi. Yurt dışı aktarım yol seçimi: `KVKK-YURTDISI-AKTARIM-SECENEKLERI.md`.

> Cem 14.09: "KVKK aydınlatma metni hâlâ ölçülmedi. ölçelim."
> Yöntem: `kvkk.html` (son güncelleme 04.09.2026) cümle cümle okundu; sitenin **bugün gerçekten
> gönderdiği/sakladığı** veri koddan çıkarıldı ve karşılaştırıldı. Hukuki görüş değildir —
> metin değişiklikleri **avukat okumasından geçmeden yayına alınmamalı**. `kvkk.html`'e bu turda
> DOKUNULMADI (hukuki metin, Cem kararı).

## 1. Metinde HİÇ olmayan veri akışları (ölçüldü)

| # | Akış | Kodda ne gidiyor / nerede duruyor | Metinde |
|---|---|---|---|
| 1 | **Kaydır-Çöz cevap kaydı** (`cevap_kayit`) | soru kimliği, seçilen şık, doğru mu, süre, elenen şıklar + cihazda üretilen rastgele **oturum damgası** (`kc_oturum`) — üyelik yok, Supabase (İrlanda; 14.09 düzeltme: "Frankfurt" yanlıştı) | Yok. Metin yalnız "Deneme sınavında … üyeliğinize bağlı" diyor. |
| 2 | **Hesap kâğıdı kaydı** (`kagit_kayit`) | öğrencinin kâğıda yazdığı **serbest metin (≤4.000 karakter)**, çizim yapıp yapmadığı, oturum damgası | Yok. Serbest metin kişisel veri içerebilir. |
| 3 | **Seviye testi** (`seviye-testi.html`, 13.09) | cevaplar (1 ile aynı) · karne formu: e-posta, sonuç sayıları, onay, duyuru izni → `form_kayit` + **Resend ile öğrencinin kendi adresine** mail (`karne-gonder`) | Yok. |
| 4 | **Hata bildir** (Kaydır-Çöz, 13.09) | bildirim metni (≤1.500), soru kimliği/metni → `form_kayit` + bize mail | Genel "form" cümlesine giriyor, adı yok. |
| 5 | **Öğrenci hesabı** (`ogrenci.html`, 14.09) | e-posta, şifre (hash), seviye/deneme sonuçları → `ogrenci_sonuc` | Yok. Metin "üye olursanız … firma izleme bilgileri" diyor. |
| 6 | **Cihazda saklananlar** (localStorage) | yanlış kutusu, deneme ilerlemesi, seviye sonuçları, görülen sorular, oturum damgası | Yok. Metin yalnız "reklam/izleme çerezi yok" diyor. |
| 7 | **Ziyaret sayacı: GoatCounter** (`mevzuatradar.goatcounter.com`, `gc.zgo.at`) | sayfa görüntüleme + 30.08'den beri vitrin tıklama olayları | "Çerezsiz sayaç" deniyor, **sağlayıcı adı ve ülkesi 4. bölümde yok**. |
| 8 | **Net Cevap yedek hattı: OpenRouter** | `radar-app/edge/net-cevap.ts`: Anthropic düşerse soru **OpenRouter**'a gider | Alıcı listesinde yalnız Anthropic var. |

## 2. Metinde olup gerçekle çelişen

| # | Metin | Gerçek |
|---|---|---|
| 9 | "Hesaplama araçları tarayıcınızda çalışır ve girdiğiniz veriler bize gönderilmez" (genel giriş) | Soru çözme ekranları (1, 2, 3) cevap ve kâğıt metnini gönderiyor. Cümle istisnasız kurulmuş. |
| 10 | Veri sorumlusu: **"Dizdar Denetim ve Yazılım A.Ş."** | Ana sayfa altbilgisi, güven bölümü ve karne maili **"Dizdar Denetim A.Ş."** yazıyor. Ticaret sicilindeki unvan hangisi? — **ölçülemedi, Cem bilir.** |
| 11 | Yurt dışı aktarım: "standart sözleşme **hazırlanmaktadır**" (04.09'dan beri) | Aktarım fiilen yapılıyor (Resend, GitHub, Anthropic, OpenRouter, GoatCounter). 7499 sayılı Kanun sonrası düzende standart sözleşmenin imzalanıp Kurul'a bildirilmesi gerekiyor; "hazırlanıyor" demek güvencenin henüz olmadığını söylüyor → **en büyük hukuki risk, avukat işi.** |
| 12 | Saklama: yalnız "üyelik süresince" ve "rıza geri alınana kadar" | Form kayıtları, cevap/kâğıt kayıtları, öğrenci sonuçları için süre yazılı değil. |

## 3. Form metinleri

| # | Nerede | Sorun | Durum |
|---|---|---|---|
| 13 | `seviye-testi.html` karne onayı | "e-postamın işlenmesine **izin veriyorum**" → öğrencinin kendi talebi için **rıza** istiyordu (dayanak talep/sözleşme olmalı) | ✅ 14.09 düzeltildi: "Aydınlatma metnini okudum; karnemin bu adrese gönderilmesini istiyorum." |
| 14 | `seviye-testi.html` duyuru izni | kısa metin, açık rıza metnine bağlı değildi | ✅ 14.09: "açık rıza metnindeki kapsamda rıza veriyorum" + `kvkk.html#riza` bağlantısı. ⚠ `kvkk.html`'de `#riza` çapası YOK — metin güncellenirken bölüm 7'ye `id="riza"` konmalı. |
| 15 | Duyuru/kampanya e-postası (radar-app, ogrenci, seviye) | KVKK rızası ≠ **ticari elektronik ileti onayı** (6563 sayılı Kanun). Kampanya maili atmadan önce **İYS kaydı** ve onayların İYS'ye işlenmesi gerekir. | Bugün kampanya maili **gönderilmiyor** (onaylar yalnız kaydediliyor). Göndermeye başlamadan önce yapılacak. |

## 4. Önerilen metin ekleri (taslak — avukat okuması şart)

**Bölüm 1'e eklenecek paragraflar:**

> **Soru çözerseniz (Kaydır-Çöz, seviye testi, sınav gibi deneme):** hangi soruyu çözdüğünüz, seçtiğiniz
> şık, doğru ya da yanlış olduğu, soruya ayırdığınız süre ve hesap kâğıdına yazdıklarınız; üye değilseniz
> tarayıcınızda üretilen rastgele bir oturum numarasıyla, kimliğinizle eşleştirilmeden kaydedilir. Bu kayıt
> soruların gerçek zorluğunu ölçmek ve "bu şıkkı seçenlerin yüzdesi" gibi anonim istatistikler üretmek için
> kullanılır. Hesap kâğıdına kişisel bilgi yazmamanızı öneririz.
>
> **Seviye testi karnesi isterseniz:** e-posta adresiniz ve test sonucunuz (geçme ihtimali, doğru sayıları),
> karnenin size gönderilmesi için işlenir.
>
> **Soruda hata bildirirseniz:** yazdığınız bildirim ve ilgili soru, soruyu incelemek için kaydedilir.
>
> **Öğrenci hesabı açarsanız:** e-posta adresiniz, şifreniz (geri döndürülemez özetlenmiş olarak) ve seviye
> testi / deneme sonuçlarınız hesabınıza kaydedilir; yalnızca size hazırlık paneli sunmak için kullanılır.
>
> **Cihazınızda tutulanlar:** yanlış kutunuz, deneme ilerlemeniz, test sonuçlarınız ve oturum numarası
> tarayıcınızın yerel deposunda tutulur; tarayıcı verilerini sildiğinizde silinir.

**Giriş cümlesi düzeltmesi:** "Hesaplama araçları tarayıcınızda çalışır…" → "…yalnızca üye olduğunuzda,
bir form doldurduğunuzda, soru çözdüğünüzde ya da soru-cevap aracına soru yazdığınızda…"

**Bölüm 4 alıcı listesine:** **GoatCounter** — ziyaret sayımı; ülke: *ölçülmedi, sağlayıcıdan teyit edilmeli* ·
**OpenRouter** — soru-cevap aracında birincil sağlayıcı yanıt veremezse yedek hat; ABD.

**Bölüm 5'e:** form kayıtları, cevap/kâğıt kayıtları ve öğrenci sonuçları için saklama süresi (Cem kararı).

**Bölüm 7'ye:** `id="riza"` çapası.

## 5. Cem'in karar vereceği / başkasına ait işler

1. Veri sorumlusunun ticaret sicilindeki tam unvanı (10).
2. Yurt dışı aktarım için standart sözleşme imzası + Kurul bildirimi (11) — avukat.
3. Saklama süreleri (12).
4. Kampanya maili başlamadan İYS kaydı (15).
5. Önerilen metin eklerinin avukat okuması, sonra `kvkk.html` güncellemesi (tarih damgasıyla).
