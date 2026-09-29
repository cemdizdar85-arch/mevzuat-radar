# Meta (Instagram) reklam + dönüşüm ölçümü — kurulum

29.09.2026 · Cem: "dönüşüm kodları ve Instagram reklam işleri — ne gerekiyorsa yapalım".

## Ne hazır (ana telde, KAPALI)

| Parça | Dosya | Durum |
|---|---|---|
| Tarayıcı ölçümü + onay bandı | `donusum.js` (menu.js yükler, perdeden önce) | `PIKSEL_ID = ''` → Meta'ya **hiçbir şey gitmez, bant çıkmaz**; yalnız GoatCounter'a `donusum/<olay>/<içerik>` olayı yazar |
| Sunucu ölçümü (Conversions API) | `radar-app/edge/meta-olay.ts` | Supabase'e **yüklenmedi**; secret yoksa `meta:false` döner |
| Öz-sınav | `arac/donusum-sinavi.js` (tarayıcı, 14 madde) · `arac/meta-olay-sinavi.mjs` (8 madde) | 29.09 hepsi GEÇTİ; mutasyon ("karar yokken pikseli yükle") yakalandı |

**Ölçülen olaylar** (sayfalara dokunmadan, başarılı yanıttan sonra):

| Olay | Nerede | Meta adı |
|---|---|---|
| Perde e-postası | açılış perdesi | `Lead` · perde |
| Ön kayıt | ana sayfa | `Lead` · on-kayit |
| Seviye testi karnesi | seviye-testi | `Lead` · seviye-testi |
| Canlı deneme kaydı | canli-deneme | `Lead` · canli-deneme |
| Üyelik (e-posta / ilk Google girişi) | ogrenci vb. | `CompleteRegistration` |
| Satın alma sayfası açıldı | satin-al, radar-fiyat | `ViewContent` |
| Sipariş verildi (havale, ödeme BEKLİYOR) | satin-al, radar-fiyat | `InitiateCheckout` + tutar |
| **Para geldi** | — | `Purchase` **YOK**: kart ödemesi/onay akışı kurulunca site kolu `ttDonusum('Purchase',{value,currency:'TRY'})` koyar |

⚠ `fark.html` ve menu.js'siz 9 sayfa (iptal, pano, saglik…) ölçülmez; fark.html reklam iniş sayfası olacaksa ona da `<script src="/donusum.js" async></script>` eklenmeli.

## 🔴 Açmadan önce — Cem

1. **Meta Business hesabı** (business.facebook.com) → Instagram hesabını bağla → **Reklam hesabı** (para birimi TRY, saat dilimi İstanbul; para birimi sonradan DEĞİŞMEZ).
2. **Events Manager → Veri kaynağı bağla → Web → Pixel (veri kümesi)** → adı "Tetikte". **Pixel ID** (yalnız rakam) GM'ye yazılır — gizli değildir, sayfada herkes görür.
3. **Alan adı doğrulama:** Business Ayarları → Marka güvenliği → Alan adları → tetikte.com → **DNS TXT** kaydı (siteye dosya koymadan).
4. **Conversions API belirteci:** Events Manager → pikselin Ayarlar'ı → Conversions API → "Erişim belirteci oluştur". Belirteç **sohbete yazılmaz** → `_yerel-veri-kasasi\meta-capi-token.txt`.
5. **Hukuk (avukat, iyzico incelemesinden SONRA):** kendi KVKK sayfamız "sürekli aktarım açık rızaya dayandırılmaz" diyor (7499 sonrası m.9). Meta'ya aktarım için **standart sözleşme** (KVKK'ya 5 iş günü içinde bildirim) gerekir. Meta'nın Türkiye için hazır standart sözleşme eki olup olmadığı **ÖLÇÜLMEDİ**. Çerez için ayrıca açık rıza gerekir; bant bunu karşılıyor, yurt dışı aktarım dayanağını karşılamıyor.
6. **Açılış perdesi:** site hâlâ perde arkasında (`menu.js` PERDE-BASI). Reklam tıklayan herkes "çok yakında" perdesini görür; ölçülebilen tek dönüşüm perde e-postası olur. Reklam ya bir **bekleme listesi kampanyası** olarak (Lead = perde) ya da `gong.ps1` açılışından sonra verilir.

## Açma adımları (GM, yukarıdakiler bitince — tek commit)

1. `donusum.js` → `var PIKSEL_ID = '<rakam>';`
2. **Aynı commit'te** `gizlilik-politikasi.html` §3 ve `kvkk.html` §4 + §5 tablosu + §5 ilk cümle aşağıdaki metinle değişir (site kolu 29.09 onayladı: metin yalnız piksel açılırken değişir).
3. Supabase → Edge Functions → `meta-olay` (bu dosya, Verify JWT kapalı) · Secrets `META_PIXEL_ID`, `META_CAPI_TOKEN`, geçici `META_TEST_KODU`.
4. Events Manager → **Test events**: 7 olay tek tek tetiklenir; her birinde "Tarayıcı + Sunucu, tekilleştirildi" görülmeli. Ekran görüntüsü Cem'e. Sonra `META_TEST_KODU` silinir.
5. `node arac/donusum-sinavi.js` + `node --experimental-strip-types arac/meta-olay-sinavi.mjs` yeniden.

### Politika metni (hazır, YAYINDA DEĞİL)

**gizlilik-politikasi.html §3, ilk paragraf yerine:**
> Tetikte, siteyi çalıştırmak için çerez kullanmaz. Tek istisna **reklam ölçümüdür**: Instagram/Facebook reklamlarımızın işe yarayıp yaramadığını ölçmek için Meta pikselini **yalnız sitenin altındaki bantta "Kabul et" dersen** çalıştırırız. Kabul edersen tarayıcına Meta'nın `_fbp` (ve reklamdan geldiysen `_fbc`) çerezi konur. Hangi sayfayı açtığın, üye olduğun, seviye testi karnesi istediğin ya da sipariş verdiğin bilgisi, IP adresin, tarayıcı bilgin ve bir form doldurduysan e-posta adresinin **geri çevrilemez özeti (SHA-256)** Meta Platforms'a (İrlanda/ABD) iletilir. Açık e-posta adresin gönderilmez. "Reddet" dersen ya da hiç seçmezsen Meta'ya hiçbir şey gitmez ve site aynen çalışır. Kararını istediğin an <a href="javascript:ttReklamOnayDegistir()">buradan değiştirebilirsin</a>. Ziyaret sayımı, çerez bırakmayan ve IP adresi saklamayan bir sayaçla yapılır.

**kvkk.html §4 ilk cümle yerine:**
> Site çalışmak için çerez kullanmaz. Yalnız sitenin altındaki bantta açıkça "Kabul et" derseniz reklam ölçümü için Meta çerezi kurulur (ayrıntı: Gizlilik ve Çerez Politikası §3). Ayrıca size hizmet vermek için tarayıcınızın yerel deposunda şu bilgiler tutulur…

**kvkk.html §5 ilk cümle:** "reklam amacıyla kullanılmaz" → "satılmaz; yalnız reklam ölçümüne onay verdiyseniz aşağıdaki Meta satırındaki kadarı reklam ölçümünde kullanılır".
**kvkk.html §5 tabloya satır:** Meta Platforms Ireland · Reklam ölçümü (yalnız onayla) · ziyaret edilen sayfa, dönüşüm olayı, IP, tarayıcı bilgisi, `_fbp`/`_fbc`, e-postanın SHA-256 özeti · İrlanda / ABD.

## Reklam kuralları (her görsel/metin bunlardan geçer)

- Başa **"Reklam"** ibaresi. Yapay zekâ karakteri (SORU) varsa **"Yapay zekâ ile üretilmiştir"** ibaresi eklenir ve Meta'da "AI info" işaretlenir. Dayanak: Ticari Reklam Yön. m.18/8 (01.08.2026). Reklam Kurulu'nun 16.07.2026 toplantısında (371. toplantı), "reklam" ibaresi taşımayan YZ ders uygulaması videosuna 1.083.706 TL ceza verildi.
- **YASAK kelimeler:** kurs · eğitim · hoca · öğretmen · MEB onaylı · "Türkiye geneli" · "en çok/en iyi" · belgesiz sayı. Sayı yazılacaksa `kaydir/<sınav>/index.html`'deki sayı kullanılır (sayı iddiası kapısı yalnız site sayfalarını denetler, reklam metnini DENETLEMEZ).
- TÜRMOB/TESMER/ÖSYM adı ve logosu kullanılmaz. Canlı deneme reklamında "Tetikte'nin kendi denemesi; resmî sınavla bağlantısı yoktur" satırı yer alır.

## İlk kampanya önerisi (bütçe Cem'de)

- **Amaç:** Potansiyel müşteri → dönüşüm yeri web sitesi → olay `Lead`.
- **Kitle:** Türkiye · 22–45 yaş (kitle ölçümü 24–39 çalışan) · ilgi alanı daraltması YOK (Advantage+ kitle; soru görseli adayı kendisi süzer).
- **Yerleşim:** Instagram Reels + Hikâye (9:16).
- **Öğrenme:** Meta, reklam setinin haftada ~50 dönüşümle öğrenme aşamasından çıktığını söyler. Haftada 50 Lead'e yetmeyecek bütçe verilirse optimizasyon `ViewContent`'e (daha sık olay) düşürülür. Tahmini birim bedel ilk 3 günün ölçümünden okunur, hafızadan yazılmaz.
