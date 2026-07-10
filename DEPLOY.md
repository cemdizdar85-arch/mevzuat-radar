# Canlıya Alma Kılavuzu — Yükümlülük Karnesi

Hedef: karneyi bedava, `https://KULLANICI.github.io/mevzuat-radar/` adresinde yayınlamak
ve e-posta toplamak. Programcı bilgisi gerekmez — hepsi tarayıcıdan yapılır.

Toplam süre: ~20 dakika. İki hesap açman gerekecek (ikisi de ücretsiz): **GitHub** ve **Formspree**.

---

## ADIM 1 — E-posta formunu bağla (~5 dk, İKİ SEÇENEK)

GitHub Pages "statik"tir; kendi başına e-posta gönderemez. Araya ücretsiz bir form
servisi koyuyoruz: ziyaretçi e-posta bırakınca servis **sana** mail atar.
İki seçenekten birini kullan — **A önerilir (üyelik yok).**

### Seçenek A — Web3Forms (ÜYELİK YOK, önerilen)

1. https://web3forms.com adresine gir → e-posta adresini yaz → **Create Access Key**.
2. E-postana gelen **access key**'i kopyala (hesap/şifre yok, bu kadar).
3. `index.html`'i bir metin düzenleyiciyle (Not Defteri de olur) aç, en üstteki
   şu iki satırı bul ve doldur:
   ```js
   const EPOSTA_ENDPOINT = "https://api.web3forms.com/submit";
   const EPOSTA_ANAHTAR  = "buraya-access-key";
   ```
4. Kaydet. Gönderimler e-postana düşer (ücretsiz plan ayda 250 gönderim).

### Seçenek B — Formspree (ücretsiz hesap ister)

1. https://formspree.io → **Sign up** (ücretsiz plan: ayda 50 gönderim).
2. **+ New form** → adını "Mevzuat Radarı Karne" koy → oluştur.
3. Verdiği endpoint'i (`https://formspree.io/f/abcdwxyz` gibi) `index.html`'de doldur:
   ```js
   const EPOSTA_ENDPOINT = "https://formspree.io/f/abcdwxyz";
   const EPOSTA_ANAHTAR  = "";
   ```
4. İlk gönderimde Formspree onay maili atar — bir kez onayla.

> Bu adımı sonraya da bırakabilirsin: ikisi de boşsa site yine çalışır,
> e-posta kutusu "yakında" der.

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
