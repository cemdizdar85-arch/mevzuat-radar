# Rakip Üyelik ve Giriş Akışları — Karşılaştırma Raporu

**Tarih:** 02.10.2026 · **Amaç:** tetikte.com üyelik ekranının yeniden tasarımına girdi
**Yöntem:** Yalnız herkese açık sayfalar okundu (kayıt/giriş sayfası, yardım/SSS makalesi). Hiçbir sitede hesap açılmadı, form gönderilmedi, e-posta/şifre girilmedi.

**Kanıt işaretleri (her hücrede geçerli):**
- **[D]** = sayfanın kendisi doğrudan okundu.
- **[Y]** = sayfa açılamadı (403 / JavaScript), bilgi sitenin kendi yardım makalesinin arama özetinden alındı. Ekrandaki birebir metin görülmedi.
- **[3]** = üçüncü taraf kaynak (inceleme blogu vb.). Zayıf kanıt.
- **"görülemedi"** = bu madde için hiçbir kaynak bulunamadı. Tahmin yazılmadı.

> ⚠ Hiçbir sitede "tekrar gönder" düğmesinin bekleme süresi (kaç saniye) ölçülemedi, çünkü bunu görmek için form göndermek gerekir. Şifre sıfırlama sonrası ekran mesajı yalnız Brilliant'ta birebir görüldü.

---

## 1. Karşılaştırma tablosu

Sütunlar: **(1)** Kayıt ile giriş ayrı mı · **(2)** Kayıt alanları · **(3)** Sosyal giriş (sırasıyla) · **(4)** Şifresiz giriş · **(5)** E-posta doğrulaması · **(6)** Şifremi unuttum · **(7)** Sözleşme/KVKK onayı · **(8)** Kayıttan sonra nereye · **(9)** Hesapsız deneme

### 1a. Yabancı mesleki sınav (CPA / ACCA)

| Site | (1) | (2) | (3) | (4) | (5) | (6) | (7) | (8) | (9) |
|---|---|---|---|---|---|---|---|---|---|
| **Becker (CPA)** | Ayrı sayfa; "Already have an account? Sign in" [D] | E-posta, şifre (9–15 kr., büyük/küçük/rakam/özel), ad, soyad, cep tel., ülke, adres, "ilgi alanı" [D] | Yok [D] | Görülemedi | Görülemedi | Ayrı sayfa; kullanıcı adı ile; ayrıca "kullanıcı adımı unuttum" [Y] | Metin: "hesap oluşturarak … kabul edersiniz"; SMS izni ayrı kutucuk [D] | Ücretsiz deneme formu: ad, e-posta, tel., posta kodu, ülke, çalışma süresi, okul durumu; "kurulum 30 dakikayı bulabilir", giriş talimatı e-postayla gelir [Y] | Hayır; 14 gün deneme hesap/form ister, kart istemez [Y] |
| **UWorld (Roger + Wiley CPAexcel + Surgent CPA artık burada)** | Görülemedi (deneme düğmesi sepet sayfasına gidiyor) [D] | Görülemedi | Görülemedi | Görülemedi | Görülemedi | E-postaya talimat; "spam'e bak"; bazen güvenlik sorusu [Y] | Görülemedi | 7 gün deneme, 6 bölüme erişim; ilerleme satın alınca korunur [D] | Hayır; ama "kart gerekmez" [D] |
| **Surgent (CPA dışı ürünler)** | Görülemedi | Ürün seçimi, ad-soyad, e-posta, telefon, CAPTCHA [D] | Görülemedi | Görülemedi | Görülemedi | Görülemedi | Metin: "formu doldurarak gizlilik politikasını kabul edersiniz" [D] | Deneme bağlantısı e-postayla gönderiliyor [D] | Hayır |
| **Gleim (CPA)** | Ayrı sayfa; "Already have an account? Log in here" [D] | Ad, soyad, e-posta, **e-posta tekrar**, telefon, ülke, posta kodu (şifre alanı görülmedi) [D] | Yok [D] | Görülemedi | E-posta iki kez yazdırılıyor (yazım hatasına karşı) [D] | Görülemedi | Sayfada onay metni görülmedi [D] | 7 gün deneme [Y] | Hayır |
| **ACCA (myACCA)** | Ayrı: "Sign in" → "Create account" [Y] | E-posta → **kod** → şifre → ad, soyad [D] | Yok (görülmedi) | Görülemedi | **Hesaptan ÖNCE**: e-postaya kod, 20 dk geçerli, "Verify code" [D] | **Kod** (20 dk); 10 dk içinde gelmezse spam'e bak; sonra destek e-postası [Y] | **Kutucuk**: "gizlilik bildirimini okudum" [D] | Öğrenci kaydı ayrı süreç (belge yükleme, 5–10 iş günü) [3] | — (deneme ürünü yok) |
| **Kaplan (MyKaplan, ACCA/CFA)** | Hesap satın alınca e-postayla kayıt daveti gelir [Y] | Görülemedi | Görülemedi | Görülemedi | Kayıt e-postası satın almadan sonra [Y] | **Geçici şifre** e-postayla gelir [Y] | Görülemedi | Görülemedi | Hayır (satın alma önce) |

### 1b. Genel öğrenme / sınav

| Site | (1) | (2) | (3) | (4) | (5) | (6) | (7) | (8) | (9) |
|---|---|---|---|---|---|---|---|---|---|
| **Magoosh** | Ayrı sayfa; girişte "New to Magoosh? Sign up here!" [D] | **Yalnız 3 alan**: e-posta, şifre, **şifre tekrar** [D] | Kayıt sayfasında yok; girişte Facebook → Google → Apple ("Continue with …") [D] | Görülemedi | Görülemedi | E-postaya talimat; giriş sayfasında "I forgot my password" [D][Y] | Metin: "'Sign Up'a tıklayarak … kabul edersiniz" [D] | Hesap açılınca 2 e-posta: erişim bilgisi + şifre oluşturma bağlantısı [Y] | Hayır; ama 1 hafta deneme, kart yok [D] |
| **Khan Academy** | Ayrı; önce rol seçimi (Öğrenci/Öğretmen/Veli) [Y] | Doğum tarihi, sonra sosyal ya da e-posta+şifre; 13 yaş altına veli e-postası [Y] | Google, Facebook, Apple, **Microsoft**, e-posta [Y] | Görülemedi | Görülemedi | Bağlantı e-postayla; "gelmezse spam'e bak"; **"Google ile kaydolduysan şifren Google şifrendir"** uyarısı [Y] | Görülemedi | Sınıf seviyesi sorusu → en fazla 9 kurs seçimi → isteğe bağlı sınıf kodu [3] | Kısmen (içerik açık; ilerleme için hesap) — doğrulanamadı |
| **Quizlet** | Görülemedi (sayfa 403) | Doğum günü, e-posta, şifre; Google'da kullanıcı adı otomatik [Y] | E-posta, Apple, Google, Facebook [Y] | "Sihirli bağlantı ile giriş" seçeneği **arama özetinde geçiyor, sayfa açılamadı — doğrulanamadı** | Kayıttan **sonra** onay e-postası; "24 saate kadar sürebilir"; ayrı "onay mesajını yeniden gönder" yardım sayfası var [Y] | Bağlantı e-postayla; spam'e bak [Y] | Görülemedi | Görülemedi | Görülemedi |
| **Duolingo** | Görülemedi (sayfa JS) | Yaş, ad, e-posta, şifre [3] | Google, Facebook, Apple [3] | Görülemedi | Kayıttan sonra onay bağlantısı [3] | "Forgot password?" → e-posta; gelmezse spam/promosyon, destek formu [3] | Görülemedi | Hedef/seviye soruları | **Evet**: hesapsız ders başlar, ilerlemeyi saklamak için ara ara "profil oluştur" istenir [3] |
| **Coursera** | Ayrı mod: "Log In" / "Join for Free" [D] | Görülemedi | Google, Facebook, Apple + e-posta [Y] | Görülemedi | Kayıttan **sonra**; **doğrulanmamış hesap şifre sıfırlayamaz** [Y] | Tek alan "Email" + "Send Password Reset" düğmesi [D]; gelmezse spam [Y] | Görülemedi | Görülemedi | Görülemedi |
| **Brilliant** | Aynı sayfada **iki ayrı form** (kayıt ve giriş ayrı kutular) [D] | E-posta, şifre, ad, soyad, **yaş** — her alanın yanında "neden soruyoruz" açıklaması [D] | Google, Facebook (e-postadan önce) [D] | Yok [D] | Görülemedi | Bağlantı; ekran: "birkaç dakikada gelmezse support@… yazın" [D]; "Google/Apple ile kaydolduysan o düğmeyi kullan" [Y] | Metin: "Sign up'a tıklayarak … kabul ediyorum" (kutucuk mu metin mi net değil) [D] | Kayıttan **önce** ilgi/seviye soruları, sonra kişisel yol [3] | Sorular hesapsız; içerik için hesap [3] |

### 1c. Türk siteler

| Site | (1) | (2) | (3) | (4) | (5) | (6) | (7) | (8) | (9) |
|---|---|---|---|---|---|---|---|---|---|
| **Müşavirler Kulübü** (doğrudan rakip, SMMM) | Ayrı sayfa; "Zaten hesabın var mı? Giriş Yap" [D] | Unvan, ad soyad, e-posta, şifre (en az 8), **şifre tekrar**, profil fotoğrafı seçimi [D] | **Apple → Google** ("… ile Kayıt Ol") [D] | Görülemedi | Görülemedi | Görülemedi | **Kutucuk**: "Kullanım Koşulları'nı ve Gizlilik Politikası'nı okudum ve kabul ediyorum" [D] | Görülemedi | Mevzuat/araçlar hesapsız açık; soru bankası için kayıt istendiği yazıyor [D] |
| **Fuat Hoca** (SMMM/staj) | Ayrı (/Login, /Register) [D] | Ad, soyad, e-posta, telefon, **T.C. Kimlik No**, şifre (büyük/küçük/rakam/özel), şifre tekrar [D] | Yok [D] | Yok | Görülemedi | Görülemedi | **3 kutucuk**: kampanya izni (isteğe bağlı), hizmet sözleşmesi, KVKK aydınlatma [D] | Kartla ödemede otomatik açılış; havalede yönetici onayı [D] | "Ücretsiz Dene" bağlantısı var, ama aynı kayıt formu [D] |
| **Aktif Online** (SMMM kurs) | Ayrı; giriş sayfasında "Ücretli/Ücretsiz Üyelik" bağlantıları [D] | Görülemedi (uzaktan eğitim formu ayrı) | Yok [D] | Yok | Görülemedi | "Şifre mi unuttum" ayrı sayfa [D] | Görülemedi | Görülemedi | Görülemedi |
| **Pegem (pegem.net)** | **Aynı ekranda sekme**: "Giriş Yap" / "Üye Ol" [D] | Ad, soyad, e-posta, telefon (+90), şifre, **şifre tekrar**, cinsiyet (isteğe bağlı), **CAPTCHA** [D] | Facebook → Google (iki sekmede de) [D] | Yok | **SMS aktivasyon kodu** ile kayıt tamamlanır [D] | Güvenlik doğrulaması + **bağlantı** e-postayla [D] | **2 zorunlu kutucuk** (sözleşme + KVKK bilgilendirme) + 2 isteğe bağlı (e-posta/SMS izni) [D] | Görülemedi | Görülemedi |
| **Tonguç Akademi** | Aynı sayfada sekme: "Üye Girişi" / "Yeni Kayıt" [D] | E-posta (kod gönderilir), sınıf seçimi, şifre (göster/gizle düğmeli) [D] | Yok [D] | Yok | **Kayıtta e-postaya doğrulama kodu** [D] | "Şifrenizi mi unuttunuz?" bağlantısı [D] | Kutucuklar: sözleşme, açık rıza, pazarlama + e-posta/arama/SMS ayrı ayrı [D] | Görülemedi | Görülemedi |
| **Doping Hafıza** | Kayıt sayfası bulunamadı (404) [D] | — | Görülemedi | Yok | — | "Şifremi Unuttum"; gelmezse telefon + canlı destek (ekran paylaşımı) [D] | Görülemedi | Kullanıcı adı ve şifre **satın aldıktan sonra SMS+e-postayla** gelir [D] | Hayır |
| **Kunduz** | Sitede kendi kendine kayıt görülmedi; "Danışmana Bağlan" (WhatsApp) [D] | — | — | — | — | — | — | — | — |

---

## 2. En sık görülen 5 desen

1. **Kayıt ve giriş birbirinden ayrı (ayrı sayfa, ayrı sekme ya da ayrı kutu).** Görüldüğü siteler: Becker, Gleim, ACCA, Magoosh, Khan, Coursera, Brilliant, Müşavirler Kulübü, Fuat Hoca, Aktif Online, Pegem, Tonguç — **12 site**. **Kayıt ile girişi tek formda birleştiren tek bir site bile bulunamadı.** Hepsinde karşı ekrana giden bir cümle var ("Zaten hesabın var mı? Giriş yap").
2. **Şifre sıfırlama e-postayla gelen bağlantıyla yapılıyor, ekranda "spam klasörüne bak" yazıyor.** Bağlantı: Brilliant, Coursera, Quizlet, Khan, UWorld, Pegem, Magoosh — **7 site**. Kod kullanan tek site ACCA (20 dakika geçerli), geçici şifre gönderen Kaplan. Spam uyarısı: Brilliant, Coursera, Quizlet, Khan, UWorld, ACCA, Duolingo — **7 site**. E-posta gelmezse ekranda başka bir yol gösteren tek site Brilliant (destek adresi). Doping Hafıza yardım sayfasında telefon ve canlı destek veriyor.
3. **Google ile giriş.** Khan, Quizlet, Duolingo, Coursera, Brilliant, Magoosh, Pegem, Müşavirler Kulübü — **8 site**. Facebook 7, Apple 6 sitede var, Microsoft yalnız Khan'da. **Muhasebe sınavı sitelerinde (Becker, Gleim, ACCA) sosyal giriş hiç yok.** Türk muhasebe rakibi Müşavirler Kulübü'nde ise Apple ve Google var.
4. **Kayıtta şifre iki kez yazdırılıyor.** Magoosh, Müşavirler Kulübü, Fuat Hoca, Pegem — **4 site**. Gleim de e-postayı iki kez yazdırıyor. Her biri yeni hesap açıldığını belli eden, girişte hiç olmayan bir alan.
5. **Sözleşme onayı: Türk sitelerinde kutucuk, yabancılarda "devam ederek kabul edersiniz" cümlesi.** Kutucuk kullananlar: Müşavirler Kulübü, Fuat Hoca, Pegem, Tonguç, ACCA — **5 site**; Türklerin hepsi pazarlama iznini (e-posta/SMS) **ayrı ve isteğe bağlı** soruyor. Cümle kullananlar: Becker, Magoosh, Surgent, Brilliant — **4 site**.

**Ek gözlemler:**
- E-postayı **hesap açılmadan önce** kodla doğrulayan 3 site var: ACCA (e-posta kodu), Tonguç (e-posta kodu), Pegem (SMS kodu).
- Coursera'da e-postası doğrulanmamış hesap şifresini sıfırlayamıyor.
- Kart istemeden ücretsiz deneme sunanlar: UWorld, Magoosh, Becker, Wiley (UWorld'e geçti) — **4 site**. Hiç hesap açmadan başlatanlar yalnız Duolingo ve (soru kısmında) Brilliant.

---

## 3. Bizim için öneri (tetikte.com üyelik/giriş akışı)

Okuyucu için kısa not: Aşağıdaki maddeler çözdükleri soruna göre işaretlendi. **(a)** = tarayıcı eski şifreyi doldurup kullanıcının farkında olmadan hesap açması, **(b)** = sıfırlama e-postası gelmeyince kullanıcının çaresiz kalması, **(c)** = düğmelerin ne yaptığının anlaşılmaması.

1. **Giriş ve kayıt iki ayrı ekran ve iki ayrı adres olsun (`/giris` ve `/kayit`).** Her ekranda tek bir ana düğme olsun. Altta karşı ekrana giden tek bir cümle bulunsun: "Hesabın yok mu? Ücretsiz hesap oluştur" / "Zaten hesabın var mı? Giriş yap". — *Dayanak: incelenen 12 sitenin 12'si böyle; tek formu birleştiren hiçbir rakip yok (Becker, Gleim, Magoosh, Müşavirler Kulübü, Pegem…).* **(a)(c)**
2. **Tarayıcıya hangi kutunun ne olduğu kodda açıkça söylensin.** Giriş şifre kutusu "mevcut şifre" (`autocomplete="current-password"`), kayıt şifre kutusu "yeni şifre" (`autocomplete="new-password"`) olarak işaretlensin. Böylece tarayıcı kayıt ekranına eski şifreyi doldurmaz, onun yerine yeni ve güçlü bir şifre önerir. Şifre kutusunun yanına "göster" düğmesi konsun; kullanıcı ne yazdığını görsün. — *Dayanak: Tonguç'ta göster/gizle düğmesi var. Autocomplete işaretleri bir web standardıdır; rakiplerin kodunda ölçülmedi.* **(a)**
3. **Kayıtta "Şifre tekrar" alanı olsun.** Tarayıcı bir kutuyu doldurursa ikincisi boş kalır ve kullanıcı yeni hesap açtığını fark eder. — *Dayanak: Magoosh, Müşavirler Kulübü, Fuat Hoca, Pegem.* **(a)**
4. **Bu e-postayla zaten hesap varsa kayıt formu durup şunu desin:** "Bu e-postayla bir hesabın var. Giriş yap / Şifremi unuttum." — *Dayanak: Gleim kayıt formunda bunu yapıyor.* **(a)(c)**
5. **E-posta, hesap açılmadan önce 6 haneli kodla doğrulansın.** Kullanıcı e-postasını yazar, kod gelir, kodu girer, sonra şifresini belirler. Yanlış yazılmış ya da ulaşmayan bir adres daha kayıt sırasında yakalanır; sonradan sıfırlama e-postası boşluğa gitmez. — *Dayanak: ACCA (20 dk geçerli kod), Tonguç (e-posta kodu), Pegem (SMS kodu). Coursera'da doğrulanmamış hesap şifre sıfırlayamıyor; bu sorun kökten önlenmiş olur.* **(b)**
6. **"Şifremi unuttum" ekranı kullanıcıyı yalnız bırakmasın.** Gönderimden sonra ekranda şunlar yazsın:
   - Gönderilen adres açıkça: "**c\*\*\*@hotmail.com** adresine gönderdik."
   - "Gelen kutusunda yoksa **Spam / Gereksiz** ve **Promosyonlar** klasörüne bak. 5 dakikaya kadar sürebilir."
   - Geri sayımlı bir **"Tekrar gönder"** düğmesi (ör. 60 sn).
   - **"Hâlâ gelmedi mi?"** bölümünde iki çıkış: (i) "Google ile kaydolduysan şifren yok, Google ile devam et"; (ii) WhatsApp/e-posta destek bağlantısı.
   - *Dayanak:* Spam uyarısı 7 sitede var (Brilliant, Coursera, Quizlet, Khan, UWorld, ACCA, Duolingo). Ekranda destek adresi veren: Brilliant. "Google ile kaydolduysan" uyarısı: Khan, Brilliant. Telefon ve canlı destek: Doping Hafıza. Geri sayım süresi hiçbir rakipte ölçülemedi; 60 sn bizim önerimiz. **(b)(c)**
7. **Şifre sıfırlamada bağlantının yanında 6 haneli kod da gönderilsin; kod e-postayı açtığı yerden bağımsız olarak siteye girilebilsin.** Kullanıcı e-postayı telefonda açıp bilgisayarda devam edebilir; e-posta programının bağlantıyı bozması da sorun olmaz. — *Dayanak: ACCA kodla sıfırlıyor (20 dk); diğer 7 site yalnız bağlantı kullanıyor.* **(b)**
8. **"Google ile devam et" en üstte ve iki ekranda da aynı yerde olsun; ardından "veya e-postayla" ayırıcısı gelsin.** Apple ikinci sırada olabilir. Microsoft şart değil. Google'la gelen kullanıcı için şifre sorunu hiç doğmaz. — *Dayanak: Google 8 sitede; doğrudan rakip Müşavirler Kulübü'nde Apple + Google var. Yabancı muhasebe sitelerinde (Becker, Gleim, ACCA) sosyal giriş yok, bu da bize bir fark yaratma fırsatı.* **(b)(c)**
9. **Düğmeler ne yaptığını söylesin, tek kelimelik belirsiz düğme olmasın.** Önerilen metinler: "Giriş yap", "Ücretsiz hesap oluştur", "Google ile devam et", "Kodu gönder", "Şifreyi sıfırla". Ekran başlığı da düğmeyle aynı fiili kullansın ("Giriş yap" ekranında "Giriş yap" düğmesi). — *Dayanak: Coursera "Send Password Reset", Magoosh "Continue with …", Tonguç "Üyeliği Tamamla", Müşavirler Kulübü "Google ile Kayıt Ol".* **(c)**
10. **Kayıt formu kısa tutulsun: e-posta, (kod), şifre, şifre tekrar ve iki kutucuk.** Kutucuklardan biri zorunlu olsun: "Üyelik sözleşmesini ve KVKK aydınlatma metnini okudum". Diğeri isteğe bağlı olsun: "Kampanya/duyuru e-postası almak istiyorum". Sınav seçimi (SGS / Yeterlilik), sınav dönemi ve ad, kayıttan **sonraki** ilk ekranda sorulsun; telefon ve T.C. kimlik no istenmesin. Bu ekrandan doğrudan ilk deneme sınavına geçilsin. — *Dayanak: Magoosh yalnız 3 alan soruyor. Türk rakiplerin hepsi kutucuk kullanıyor ve pazarlama iznini ayrı soruyor (Pegem, Tonguç, Fuat Hoca). Seçimler kayıttan sonra soruluyor (Khan: seviye + kurs; Brilliant: ilgi/seviye). Fuat Hoca'nın TC ve telefon istemesi en ağır form.* ⚠ Kutucuk metinlerinin hukuki uygunluğu bu raporun kapsamında değil; hukuk onayı Cem'de. **(c)**
11. *(İsteğe bağlı)* **Hesapsız birkaç soru, sonucu saklamak için hesap.** Ziyaretçi 5–10 soru çözsün; sonuç ekranında "Sonucunu kaydetmek için ücretsiz hesap oluştur" çıksın. — *Dayanak: Duolingo, Brilliant. Muhasebe rakipleri (UWorld, Magoosh, Becker) hesap istiyor ama kart istemiyor.*

---

## 4. Ölçülemeyen / görülemeyen siteler ve maddeler

| Site | Ne oldu | Sonuç |
|---|---|---|
| Quizlet | Kayıt, giriş ve yardım sayfaları **403 (erişim engeli)** | Bilgi yalnız yardım makalesi arama özetinden geldi; "sihirli bağlantı" iddiası **doğrulanamadı** |
| Khan Academy | Kayıt ve şifre sıfırlama sayfaları JavaScript ile çiziliyor (boş geldi); yardım merkezi 403 | Arama özeti ve 3. taraf kaynak; ekran metni görülmedi |
| Duolingo | Kayıt sayfası JavaScript (boş geldi); resmî yardım sayfası bulunamadı | Yalnız 3. taraf kaynak — **zayıf kanıt** |
| Coursera | Kayıt penceresi JavaScript; yardım merkezi "CSS Error" verdi | Yalnız sıfırlama sayfası doğrudan okundu |
| Becker | Giriş sayfası (cpa.becker.com) "Loading…" | Kayıt sayfası doğrudan okundu, giriş sayfası okunamadı |
| UWorld (Roger/Wiley) | Deneme düğmesi sepet sayfasına gidiyor; o sayfa okunmadı | Kayıt alanları görülemedi |
| Kaplan | Şifre sıfırlama yardım sayfası boş geldi | Bilgi arama özetinden |
| Doping Hafıza | `/uye-ol` **404**; kayıt satın alma sonrası | Kayıt formu yok |
| Kunduz | Sitede kendi kendine kayıt görülmedi; danışman/WhatsApp yönlendirmesi var | Ölçülemedi |
| Wiley CPAexcel, Roger CPA | Markalar UWorld'e geçmiş | Ayrı akış yok, UWorld satırına bakın |
| TESMER (TEOS) | Sınav başvuru sistemi; hazırlık sitesi değil, giriş sayfası okunmadı | Kapsam dışı bırakıldı |

**Hiçbir sitede ölçülemeyenler:** "tekrar gönder" bekleme süresi; şifre sıfırlama bağlantısının geçerlilik süresi (yalnız ACCA kodu: 20 dk); kayıttan sonra doğrulama yapılmadan içeri alınıp alınmadığı (yalnız Coursera'da dolaylı bilgi var). Bunları görmek için form göndermek gerekiyordu; kural gereği gönderilmedi.

---

## 5. Kaynaklar

**Yabancı mesleki**
- Becker kayıt: https://www.becker.com/user/register
- Becker deneme formu: https://www.becker.com/cpa-free-demo-form · https://www.becker.com/cpa-review/course-demos
- Becker şifre: https://www.becker.com/cpa-review/forgot-password.html (arama özeti)
- UWorld deneme: https://accounting.uworld.com/cpa-review/cpa-courses/free-trial/
- UWorld yardım: https://helpdesk.uworld.com/ (arama özeti)
- Surgent deneme: https://www.surgent.com/free-trial/
- Gleim kayıt: https://www.gleim.com/account/register.php · deneme: https://www.gleim.com/cpa-review/demo/
- ACCA hesap açma: https://www.accaglobal.com/gb/en/student/getting-started/update-your-contact-details.html
- ACCA şifre sıfırlama: https://accaportal.accaglobal.com/article/KA-01290/en-us (arama özeti)
- Kaplan: https://kaplan-learning.com/help/how-do-i-reset-my-password · https://kaplan-learning.com/help/how-do-i-access-my-learning-and-testing-materials (arama özeti)
- Wiley → UWorld geçişi: https://finance.uworld.com/wiley-to-uworld-transition/

**Genel öğrenme**
- Magoosh kayıt: https://gre.magoosh.com/register/1-week · giriş: https://gre.magoosh.com/login · şifre: https://magoosh.zendesk.com/hc/en-us/articles/203445839-How-do-I-change-reset-my-password · onboarding: https://schools.magoosh.com/getting-started-with-magoosh-student-onboarding
- Khan Academy: https://support.khanacademy.org/hc/en-us/articles/202487450-How-do-I-set-up-a-new-user-account · https://support.khanacademy.org/hc/en-us/articles/202487480-How-do-I-reset-my-password · https://support.khanacademy.org/hc/en-us/community/posts/360074504511-How-to-sign-up-as-an-adult-learner
- Quizlet: https://help.quizlet.com/hc/en-us/articles/360030555532-Signing-up-for-a-free-account · https://help.quizlet.com/hc/en-us/articles/360031572331-Forgotten-username-or-password · https://help.quizlet.com/hc/en-us/articles/360029190271-Resending-a-confirmation-message
- Duolingo (3. taraf): https://goodux.appcues.com/blog/duolingo-user-onboarding · https://duolingoguides.com/duolingo-sign-up/ · https://duolingoguides.com/duolingo-password-reset-not-working/
- Coursera: https://www.coursera.org/?authMode=signup · https://www.coursera.org/reset · https://www.coursera.support/s/article/209818493-Set-up-your-Coursera-account (arama özeti)
- Brilliant kayıt: https://brilliant.org/account/signup/ · sıfırlama ekranı: https://brilliant.org/account/password/reset/done/ · yardım: https://brilliant.org/help/account-management/how-can-i-reset-my-login-password/ · onboarding (3. taraf): https://e-student.org/brilliant-org-review/

**Türk siteler**
- Müşavirler Kulübü: https://musavirlerkulubu.com.tr/kayit-ol · https://musavirlerkulubu.com.tr/ · https://musavirlerkulubu.com.tr/sinav-hazirlik/rehber
- Fuat Hoca: https://www.fuathoca.net/Register?ref=demo · https://www.fuathoca.net/Sss
- Aktif Online: https://aktifonline.net/sinav/login.asp · https://www.aktifonline.net/smmmstajbaslamakurslari.asp
- Pegem: https://pegem.net/uye-girisi · https://pegem.net/sayfa/Uyelik-ve-Hesap-10
- Tonguç: https://www.tongucakademi.com/uye-ol · https://www.tongucakademi.com/login
- Doping Hafıza: https://www.dopinghafiza.com/ogrenci-ve-veli-sorulari/sorular/doping-hafiza-nasil-giris-yapilir
- Kunduz: https://kunduz.com/tr/
