# Tetikte mağaza uygulaması (Google Play + App Store)

> 25.09.2026 · Cem "1.2.3 üçünü de yap" · altyapi kolu.
> Kısa cevap: **sınavlar mağazaya yüklenmez.** Mağazaya bir kez uygulama kabuğu yüklenir;
> sorular çalışma anında kilitli kasadan (`paket_soru`, RLS) gelir. Yeni soru, düzeltme,
> yeni ders → mağaza incelemesi YOK.

## Ne var, ne yapıyor

| Parça | Görev |
|---|---|
| `uygulama/` | Uygulamanın ana ekranı: giriş · Sınavlarım · Ücretsiz dene · günlük hatırlatıcı · hesap |
| `uygulama/uygulama-kapisi.js` | Sitedeki `paket-kapisi.js`'in uygulama karşılığı: aynı paket kuralı, **satış düğmesi yok** |
| `uygulama/ortak.js` | Supabase istemcisi + çevrimdışı önbellek (IndexedDB) + paket kuralı |
| `hazirla.js` | `www/`'yi derler + **3 kapı** (aşağıda). Bulutta her derlemede koşar |
| `hazirla-sinavi.js` | Kapıların öz-sınavı (`dogrula.yml`, her push) + `--mutasyon` |
| `ikon-uret.js` | favicon şekillerinden ikon + açılış ekranı (bulutta) |
| `.github/workflows/mobil-android.yml` | İmzalı AAB → Play (servis hesabı varsa) ya da şifreli artifact |
| `.github/workflows/mobil-ios.yml` | Bulut Mac'te derle → otomatik imza → TestFlight |
| `anahtar-kur.ps1` · `aab-indir.ps1` | Cem'in bilgisayarında bir kez / her elle yüklemede |

Kimlik: **`com.tetikte.app`** (Android + iOS aynı; değişmez, mağazada kalıcıdır). Ad: **Tetikte**.

## Üç kapı: uygulamaya ne girer

1. **KAPI-KASA:** yalnız `arac/kasa-modu.json`'daki sorusuz kabuklar girer. Bugün **9 sayfa**
   (SGS Türkçe + bitirmenin 8 dersi). Kasaya taşınmamış **14 SGS dersi** uygulamaya girmez,
   "Hazırlanıyor" listesinde yalnız adı görünür. Site kolu bir dersi kasa moduna aldığında bir
   sonraki derlemede kendiliğinden uygulamaya girer.
2. **KAPI-SIZINTI:** vitrin dışında hiçbir dosyada `"dogru":` ya da gömülü `SORULAR=[` yok.
   Mağaza paketi herkesin indirebildiği bir dosya; içine giren soru açık depodaki gibi dağılır.
3. **KAPI-SATIS:** satış sayfasına bağ (`satin-al`/`fiyat`/`radar-fiyat`/`mesafeli-satis`)
   ve satış düğmesi metni yok. `kasa-yukle.js`'teki "paketini güncelle" düğmesi derlemede sökülür.

Ücretsiz vitrin (SGS + SMMM örnekleri, 420 cevaplı soru, 25.09 ölçümü) **bilerek açık**. Sitede de açık.
**Kapıların göremediği:** kasa RLS'i (sunucuda), cihazda çalışma, bağlantısız satış cümlesi.

## Cem'in adımları

### 1 · Android yükleme anahtarı (bir kez, 1 dk)
```powershell
powershell -NoProfile -File mobil/anahtar-kur.ps1
```
Anahtar `C:\TETIKTE-YEDEK\mobil\` altına üretilir. Şifre ekrana basılmaz, iki GitHub sırrı yazılır.
**Bu klasörü ayrıca yedekle.** Kaybolursa Play'den sıfırlama istenir, birkaç gün sürer.

### 2 · İlk Android paketi (elle, bir kez)
```powershell
gh workflow run mobil-android.yml
```
Koşu bitince (~15 dk):
```powershell
powershell -NoProfile -File mobil/aab-indir.ps1
```
Sonra Play Console'da sırasıyla: **Uygulama oluştur** (ad: Tetikte · uygulama · ücretsiz) →
**Test ve yayınla → Dahili test → Yeni sürüm** → `C:\TETIKTE-YEDEK\mobil\aab\tetikte-N.aab` yüklenir →
test kullanıcısı olarak kendi e-postan eklenir.
Google yeni bir uygulamanın **ilk paketini API'den kabul etmiyor**, bu yüzden ilk yükleme elle.

**Sonraki sürümler otomatik (isteğe bağlı):** Play Console → Kurulum → API erişimi → servis hesabı
(Google Cloud) → JSON anahtarı → GitHub sırrı `MOBIL_PLAY_SERVIS_JSON`. Bundan sonra
`gh workflow run mobil-android.yml` paketi doğrudan dahili teste koyar.

### 3 · iOS (TestFlight)
1. **App Store Connect → Uygulamalar → +** · ad **Tetikte** · paket kimliği **com.tetikte.app**
   (listede yoksa ilk derleme kaydeder; o zaman bir kez daha bak) · SKU `tetikte-ios`.
2. **Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API → +** · rol **Admin**
   (bulutta imza sertifikası üretebilsin diye) · `.p8` indirilir. **Tek sefer iner**, kaybetme.
3. GitHub → Settings → Secrets → Actions, dört sır: `MOBIL_ASC_ANAHTAR_ID` (Key ID) ·
   `MOBIL_ASC_YAYINCI_ID` (Issuer ID) · `MOBIL_ASC_ANAHTAR_P8` (.p8 dosyasının metni) ·
   `MOBIL_APPLE_TAKIM_ID` (developer.apple.com → Membership → Team ID).
4. `gh workflow run mobil-ios.yml` → 10–30 dk sonra TestFlight'ta görünür → iPhone'a TestFlight.

## 🔴 Mağazaya ÇIKMADAN önceki kararlar

- **Apple 3.1.1 · uygulama içi satın alma:** Apple, dijital içeriğin **uygulamada açılmasını**
  genelde uygulama içi satın almaya (IAP) bağlıyor. "Başka yerde alınanı aç" izni (3.1.3(b)) aynı
  içeriğin **IAP olarak da sunulması** şartıyla geçerli. 3.1.3(a) "okuyucu uygulama" istisnası
  dergi/kitap/müzik/video içindir; sınav hazırlığı sayılması ölçülmedi.
  **Sonuç:** TestFlight'a şimdi çıkılır. **App Store yayını** için ya IAP eklenir (Apple %15 alır,
  sunucuda makbuz doğrulaması gerekir) ya da ret riskiyle "yalnız giriş" denenir. **Karar Cem'de.**
- **Google Play:** uygulamada satış ve dışarı yönlendirme olmadıkça, başka yerde alınan içeriğe
  giriş kabul ediliyor. Bu uygulama o durumda (KAPI-SATIS).
- **İnceleme hesabı:** her iki mağaza da giriş isteyen uygulama için **paketli bir deneme hesabı**
  ister (e-posta + şifre inceleme formuna yazılır). Kurucu hesabı verilmez. Ayrı bir hesap açılıp
  paketi tanımlanır.
- **Hesap silme:** Play "Veri güvenliği" formu bir silme adresi ister. Bugünkü kanal kvkk.html'deki
  `info@dizdardenetim.com`. Uygulamadaki "Hesabımı sil" de oraya e-posta açar.
  ⚠ Hafızadaki kayda göre (23.08) bu kutuya erişilemiyor. Silme talebi okunmazsa KVKK riski oluşur.
- **SGS içeriği:** uygulamada bugün SGS'den yalnız **Türkçe** var (kasa pilotu). SGS paketi satan
  bir uygulama tek dersle mağazaya çıkmamalı. Önce site kolu Adım 2'yi 14 derse yaymalı
  (`ADIM2-PAKET-KASASI-PLANI.md` §6.4 madde 7).
- **Bot koruması (captcha):** Supabase'de Turnstile açılırsa (`captcha.js`) uygulama girişi
  token'sız kalır ve **giriş düşer**. Açmadan önce Turnstile'a `localhost` alan adı eklenmeli, ve
  uygulamaya token akışı bağlanmalı (bugün yok).
- **Hukuk (5580):** mağaza sayfası ürünü herkese görünür kılar. Avukat okuması bekleyen iş.

## Geliştirici notu

- Yerel önizleme: `node mobil/hazirla.js` → `mobil/www/` herhangi bir statik sunucuyla açılır
  (Capacitor yokken hatırlatıcı gizlenir).
- `android/`, `ios/`, `www/` depoya girmez; bulutta her koşuda `npx cap add` ile üretilir.
- Paket kuralı (`kapsar`) ve kasa sorgusu **iki yerde** yaşar (site + uygulama). Kayarsa
  `hazirla-sinavi.js` KIRMIZI düşer. Site tarafı değişince `uygulama/ortak.js` ve `uygulama.js`
  aynı commit'te güncellenir.
- Sürüm: `mobil/package.json` `version` (kullanıcının gördüğü) + koşu numarası (derleme no).
