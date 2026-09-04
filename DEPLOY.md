# Canlıya Alma Kılavuzu — Yükümlülük Karnesi

Hedef: karneyi bedava, `https://KULLANICI.github.io/mevzuat-radar/` adresinde yayınlamak
ve e-posta toplamak. Programcı bilgisi gerekmez — hepsi tarayıcıdan yapılır.

Toplam süre: ~20 dakika. İki hesap açman gerekecek (ikisi de ücretsiz): **GitHub** ve **Formspree**.

---

## ADIM 1 — E-posta formunu bağla (~10 dk, Supabase paneli)

> **04.09.2026 — Web3Forms/Formspree seçenekleri KALDIRILDI.** Cem'in kararı:
> müşteri verisi tanımadığımız aracıdan geçmez. Formlar artık kendi uç
> fonksiyonumuza gider: `radar-app/edge/form-al.ts` → Supabase `form_kayit`
> tablosu (Frankfurt) + Resend ile bize mail. Sayfalardaki `EPOSTA_ENDPOINT`
> zaten `…/functions/v1/form-al`; anahtar gerekmez.

Kurulum üç panel adımı (kod girilmez), ayrıntısı `form-al.ts` başlığında:

1. Supabase → Edge Functions → **New function** → adı `form-al` → dosyayı yapıştır →
   Deploy → ayarda **Verify JWT: KAPALI**.
2. Settings → Edge Functions → Secrets: `RESEND_KEY`, `RESEND_FROM` (GitHub
   Actions'takiyle aynı değerler) ve `FORM_ALICI` (form maillerinin düşeceği adres).
3. SQL Editor → `veri/sql-form-kasasi.sql` bas (kasaya kayıt için; basılmadan da
   mail gider).

Doğrulama: `…/functions/v1/form-al?tani=1` → dört secret `true` dönmeli.

---

## ADIM 2 — GitHub'a yükle (~10 dk)

Programcı yolu (git) gerekmiyor; tarayıcıdan sürükle-bırak yeterli.

1. https://github.com → **Sign up** (ücretsiz). Kullanıcı adını seç — bu, site adresinde
   görünecek (ör. `dizdar` seçersen adres `dizdar.github.io/...` olur).
2. Giriş yaptıktan sonra sağ üstte **+** ▸ **New repository**.
   - Repository name: **mevzuat-radar**
   - **Public** seçili olsun (Pages ücretsiz planda public ister).
   - **Create repository**.
3. Açılan boş repo sayfasında **uploading an existing file** bağlantısına tıkla
   (ya da **Add file ▸ Upload files**).
4. Bu klasördeki **`index.html`**, **`kvkk.html`** dosyalarını **ve `sayfalar` klasörünü**
   birlikte sürükleyip bırak (SEO hesaplayıcılar o klasörde; karnedeki "Eşik rehberi"
   ve "Aydınlatma metni" linkleri bunlara gider). `bulten/` klasörü siteye yüklenmez —
   o e-posta malzemesidir. README.md ve DEPLOY.md şart değil.
5. Altta **Commit changes** de.

---

## ADIM 3 — Pages'i aç (~2 dk)

1. Repo sayfasında üstten **Settings** ▸ sol menüden **Pages**.
2. **Build and deployment** altında **Source: Deploy from a branch**.
3. **Branch: main** seç, klasör **/(root)** kalsın → **Save**.
4. 1-2 dakika sonra sayfanın üstünde yeşil kutuda adres çıkar:
   **`https://KULLANICI.github.io/mevzuat-radar/`**
5. Adrese gir — karne canlıda. Telefonda da açılır.

---

## Yayından sonra

- **Test et:** Kendi e-postanla "Haber ver"e bas → Formspree kutuna/mailine düştü mü bak.
- **Güncelleme:** `index.html`'i değiştirdiğinde GitHub'da aynı dosyayı tekrar yükle
  (Add file ▸ Upload) → 1 dk sonra site güncellenir.
- **Kendi alan adın** (ör. mevzuatradar.com.tr) olduğunda: Pages ▸ Custom domain'e yaz.
- **Reklama başlamadan önce** (planın kuralı): eşik değerlerini son kez teyit et,
  KVKK aydınlatma metnini ekle.

## Sorun giderme
- Adres "404" veriyor → Pages'in yeşil adresi çıkması 1-2 dk sürer; dosya adının
  tam olarak `index.html` olduğundan emin ol.
- E-posta gelmiyor → `EPOSTA_ENDPOINT` doğru yapıştırıldı mı, Formspree onay mailini
  tıkladın mı kontrol et.
