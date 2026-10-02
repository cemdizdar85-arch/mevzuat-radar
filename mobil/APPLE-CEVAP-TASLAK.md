# Apple App Review — Guideline 2.1 cevap taslağı (02.10.2026)

> Cem: aşağıdaki İngilizce metin hem App Review mesajına cevap olarak, hem de
> App Store Connect → sürüm sayfası → **App Review Information → Notes** alanına yapıştırılır.
> Şifre bu dosyaya YAZILMAZ — Sign-in Information alanında zaten duruyor; orada güncel mi bak.
> [KÖŞELİ] yerler karar/kontrol bekliyor.

---

Hello,

Thank you for your review. Please find the requested information below. The screen recording is attached.

**1. Screen recording**
Attached: recorded on a physical iPhone running [iOS sürümü], starting from app launch. It shows: account registration, login (email, Sign in with Apple), solving practice questions, the score card, and in-app account deletion (Account → Delete my account).

**2. Purpose and target audience**
Tetikte is an exam preparation app for candidates of the Turkish professional accountancy exams: the SMMM internship entrance exam (SGS) and the SMMM qualification exam. Users solve multiple-choice practice questions, each with a step-by-step explanation and a reference to the relevant law or accounting standard, and track their progress by topic. The problem it solves: candidates prepare from scattered PDFs and outdated question sets; Tetikte gives them up-to-date questions organised by topic, on mobile, including offline use. Audience: adults (18+) in Turkey preparing for these exams.

**3. How to access the main features**
- Open the app → "Ücretsiz dene" (Try free) lets you solve 3 questions without an account.
- To see all features, sign in with the demo account in the Sign-in Information section ([destek@tetikte.com hesabı — şifre alanında güncel mi]).
- After login: "Sınavlarım" (My exams) → choose an exam → choose a subject → solve questions. Each answer shows an explanation; every 10 questions a score card is shown.
- Account deletion: Account (Hesap) → "Hesabımı sil" (Delete my account) → confirm. The account and its data are deleted immediately from our server.
- The app is in Turkish only.

**4. External services used**
- Supabase (database and user authentication; hosts the question content)
- Sign in with Apple, Google Sign-In (optional login methods)
- Cloudflare Turnstile (bot protection on sign-up/login)
- [AI cümlesi — aşağıdaki karara göre]
No payment processor is used in the iOS app; the iOS app contains no purchase screen.

**5. Regional differences**
The app is distributed only in Turkey and works the same for all users.

**6. Regulated industry / third-party material**
The app is not a financial or legal service; it is an educational practice tool. It is not affiliated with TÜRMOB, TESMER or any exam authority, and does not use official exam papers. Questions are original, written by our company (Dizdar Denetim Danışmanlık ve Yazılım A.Ş.) with reference to publicly available Turkish legislation and published accounting/auditing standards.

[3.1.1 paragrafı — aşağıdaki karara göre]

Best regards,
Cem Dizdar
Dizdar Denetim Danışmanlık ve Yazılım A.Ş.

---

## Karar bekleyen iki satır

**A) Yapay zekâ cümlesi (madde 4).** Apple "AI services" diye açıkça soruyor. Uygulama çalışırken yapay zekâ ÇAĞIRMIYOR,
ama sorular hazırlanırken yapay zekâ destekli üretim + kontrol kullanılıyor. Doğru olan bunu söylemek:
> "Practice questions are prepared by our team using AI-assisted drafting and automated checks before publication. The app itself does not call any AI service at runtime."

**B) Ücretli içerik — 3.1.1.** Web'den paket alan kişinin paketi iPhone'da açılıyorsa Apple bunu "uygulama içi satın alma
olmadan ücretli içerik" sayar (3.1.3(b): web'de alınan, uygulamada da IAP ile satılmalı). İki yol:
- **B1 (önerilen, hızlı):** iOS'ta yalnız ücretsiz içerik + hesap. Cümle: "All content in the iOS app is free; there is no paid content or purchase in the iOS app." — bunun DOĞRU olması için iOS derlemesinde web paketinin açılmaması gerekir (kod değişikliği + yeni derleme).
- **B2:** Apple IAP kurulur (banka + vergi + 6 ürün + makbuz doğrulama) → en az bir hafta.
