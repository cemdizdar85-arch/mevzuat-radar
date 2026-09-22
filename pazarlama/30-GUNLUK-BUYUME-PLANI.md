# 30 GÜNLÜK BÜYÜME PLANI — pazarlama direktörü kararı

Hazırlayan: GM (pazarlama direktörü rolü, Cem 22.09.2026 verdi) · Tarih: 22.09.2026
Kapsam: @dizdardenetim + @tetiktecom + tetikte.com satış hunisi

---

## 0 · ÖNCE TEŞHİS — "onların gördüğü" değil, bizim bakmadığımız

Cem'in sorusu: *"bir günde binlerce takipçi kazananlar var, onların gördüğü bizim görmediğimiz
ne?"* Cevap üç maddede, üçü de bizde ve üçü de ölçüldü.

### 0.1 🔴 KASA KAPALI — bugün kimseye tek lira satamayız

`satin-al.html` satır 254:

```js
var BANKA = { ad: '[BANKA ADI]', iban: '[IBAN BEKLENIYOR]' };
var KURULUM_TAMAM = BANKA.iban.indexOf('[') === -1;   // → false
```

Sonuç: sayfanın tepesinde kırmızı "KURULUM EKSİK" uyarısı çıkıyor ve **sipariş düğmesi kapalı.**
Kart ödeme de yok (`iyzico/paytr/stripe` araması: satış sayfalarında yok; ödeme yöntemi
yalnız havale/EFT — o da IBAN'sız).

**Yani bugün Instagram'dan 10.000 kişi gelse cirosu 0 TL.** Büyüme planının birinci maddesi
reklam değil, bu. 29–30.08 fiyat kararından beri bekliyor (≈24 gün).

### 0.2 🔴 DOKUZ GÜNDÜR HİÇ GÖNDERİ YOK, AMA ELİMİZDE BİTMİŞ İÇERİK VAR

Masaüstünde yayınlanmamış duran: 2 film (56,6 + 52,9 sn, 1080×1920, 13.09), 7 kare (bugün),
2.079 katmanlı soru, 35 dönemlik sıklık künyesi. @tetiktecom'da 0 gönderi.

**Dağıtım algoritması basılmayanı dağıtamaz.** Patlayan hesapların gördüğü sır bu:
onlar her gün basıyor, biz ayda bir kez "hangi format olsun" tartışıyoruz.

### 0.3 🔴 FORMAT SABİTLİĞİ YOK — 12 günde 5 format, hiçbiri iki kez basılmadı

07–13.09 arasında denenip bırakılanlar: sayaç reklamı · kinetik yazı · ham ekran kaydı ·
patlatılmış görünüm · statik kart. Her biri bir kez basıldı, beğenilmedi, bırakıldı.

Patlayan hesap **tek formatı 50 kez** basar. İzleyici formatı tanıyınca durmaya başlar;
her seferinde yeni format = her seferinde sıfırdan tanınma.

### 0.4 Ve bilinmesi gereken tek teknik gerçek

**Takipçi sayısı dağıtımı belirlemiyor.** Instagram reels'i öneri akışında dağıtıyor;
3 takipçili hesabın videosu da önerilere düşebiliyor. "Takipçimiz az" bir engel değil,
bir **sonuç**. Engel, ortada dağıtılacak video olmaması.

"Bir günde binlerce takipçi" pratikte üçünden biridir: **(a) ödemeli reklam · (b) çekiliş/hediye ·
(c) tek videonun önerilere düşmesi.** (a) ve (b) parayla alınır, (c) hacimle yakalanır.
Bizde (c)'nin yakıtı fazlasıyla var — basılmıyor.

### 0.5 ⚠ ÖLÇEMEDİĞİM ŞEY — Cem'in açması gereken tek panel

@dizdardenetim 07.09'da 51 takipçiydi, bugün **3.007**. Bu 15 günde ne olduğunu bilmiyorum:
reklam mı verildi, hangi gönderi getirdi, organik mi. **Bu firmanın elindeki en değerli
pazarlama verisi** ve okunmamış duruyor.

Cem'in Instagram uygulamasından (Profesyonel Panel → İçerik) **6 Eylül gönderisi için** okuyacağı
altı sayı: *izlenme · beğeni · yorum · paylaşma · kaydetme · profil ziyareti* + her birinin
**"Tanıtıldı/Boosted" etiketi var mı**. Bu tablo gelmeden reklam bütçesi konuşulmaz —
çünkü kazananın hangisi olduğunu zaten hesap söylüyor.

---

## 1 · KARAR — plan üç fazlı, 30 gün

### FAZ 0 · KASAYI AÇ (bu hafta, her şeyden önce)

| # | İş | Kimde | Süre |
|---|---|---|---|
| 1 | `satin-al.html` içindeki `BANKA` satırına banka adı + IBAN | **Cem** | 5 dk |
| 2 | Kart ödeme başvurusu (iyzico ya da PayTR) | **Cem** | başvuru 1 gün, onay birkaç gün |
| 3 | 6 Eylül gönderisinin Insights tablosu | **Cem** | 10 dk |

> **Kart neden pazarlık konusu değil:** kitle 22–30 yaş sınav adayı. Havale/EFT onlar için
> "sonra yaparım" demektir ve geri dönmezler. Kart yokken her reklam lirası bu kapıda ölür.
> Komisyon oranı ne olursa olsun, sıfır satıştan ucuzdur.

**Faz 0 bitmeden reklam parası harcanmaz.** (Organik yayın Faz 1'de başlar, o bedava.)

### ⭐ FAZ 0.5 · CUMA AÇILIŞI — "site açıldı" duyurusu DEĞİL, bir OLAY

**22.09 Cem: *"siteyi cuma günü açacağız, hiç mi yeni bir şey yapmayalım, nasıl dikkat çekeriz?"***

**Cevap: yeni bir şey icat etmeye gerek yok — takvimde zaten duruyor ve unutulmuş.**

`veri/canli-deneme.json` (Cem onayı 06.08.2026):

| Oturum | Sınav | Tarih | Saat |
|---|---|---|---|
| **Başvuru Denemesi** | **SGS** | **27.09.2026 Pazar** | **10:00** |

Not alanında yazan: *"SGS başvuru penceresi ortası (21 Eyl – 9 Eki): 'başvurayım mı?'
kararına gerçek yüzdelik cevap."* Katılım **bedelsiz** (Cem kararı), sınav sitede çözülür,
kilitli-set mimarisi 5.000 eşzamanlıya dayanıklı, veritabanı yükü sıfır.

**Yani Cuma açılıştan İKİ GÜN sonra, Türkiye geneli ücretsiz bir SGS denemesi var.**

#### Neden açılış hamlesi bu olmalı

1. **"Site açıldı" haber değildir.** Kimse bir sitenin açılışını takip etmez. **"Pazar 10:00'da
   Türkiye geneli deneme"** bir olaydır: tarihi var, saati var, kaçırılır.
2. **Zamanlama tesadüf değil.** SGS başvuru penceresi **şu an açık** (21 Eylül – 9 Ekim).
   Aday tam bu hafta *"başvurayım mı, hazır mıyım?"* diye düşünüyor. Denemenin cevapladığı
   soru bu. Bir hafta sonra bu pencere kapanır ve aynı duyurunun gücü kalmaz.
3. **Paylaşılır.** "Ben de gireceğim" doğal olarak arkadaş etiketlenir; sınav grupları
   (WhatsApp/Telegram) tarih paylaşır, reklam paylaşmaz.
4. **Kasa kapalıyken bile çalışır.** Katılım bedelsiz → IBAN kusuru bu hamleyi engellemiyor.
   (Ama deneme sonrası satın alma gelecek, o yüzden IBAN yine Cuma'dan önce girilmeli.)
5. **İkinci dalga içeriği kendisi üretir.** Deneme bittiğinde elimizde **ölçülmüş** sosyal
   kanıt olur: kaç kişi girdi, hangi soruda kaç kişi düştü. Bugün uyduramadığımız her rakam
   Pazar akşamı gerçek olur.
6. **Elçilere paylaşacak somut şey verir** — komisyon değil, tarih.

#### İkinci yeni parça: "35 DÖNEM RAPORU" (lead magnet, 0 TL)

`veri/siklik-kunyesi.json` — **35 dönem, 3.248 tekil konu**, her konunun kaç dönemde ve kaç
soruda çıktığı ölçülmüş (19.09 üretimi). Türkiye'de bu veriyi kimse yayınlamıyor, çünkü
kimse 35 dönemi ayrıştırmadı.

Ücretsiz yayınlanır: *"Staja Başlama'da son 35 dönemde hangi konudan kaç soru çıktı."*
Ders ders liste. Bu, sınav gruplarında **elden ele dolaşan** türden bir belgedir.

İkisi birbirini besler:
**Rapor** "şu konulara çalış" der → **Deneme** "bakalım çalışmış mısın" der →
**Sonuç** "işte yanlışların, ve her birinin adı var" der → ürün kendini anlatmış olur.

#### Cuma–Pazar takvimi

| Gün | Hamle | Kimde |
|---|---|---|
| **Çarşamba (bugün/yarın)** | IBAN gir · Bölüm 1 filmini yayınla · geri sayım başlasın | Cem |
| **Perşembe** | 35 Dönem Raporu yayında (site + gönderi) | GM üretir, Cem yükler |
| **Cuma** | Açılış: duyuru gönderisi + hikâye + "Pazar 10:00" kartı | Cem yükler |
| **Cumartesi** | Hatırlatma hikâyesi + geri sayım çıkartması | Cem |
| **Pazar 10:00** | Deneme · canlı hikâye akışı | Cem |
| **Pazar akşamı** | Sonuç gönderisi — gerçek rakamlarla | GM üretir |

#### 🔴 TEK BAĞIMLILIK — ölçmedim, sınav kolunda

Canlı Sınav **Faz 4** (zamanlı oturum + dağıtım + skor) hafızada "AKTİF İŞ" olarak duruyor;
Pazar'a yetişip yetişmediğini **ölçmedim** ve ölçemem: `sinav` kolu şu an başka bir oturumda
canlı (`opus-sinav`, iş: "benzerlik kapisi kasaya baksin"). Sayfa ve takvim bağlı
(`canli-deneme.html`, menüde ve ana sayfada görünüyor, e-posta kaydı çalışıyor),
ama oturumun kendisi hazır mı — **o kola sorulmalı.**

Faz 4 Pazar'a yetişmiyorsa hamle ölmez, **kayıt kampanyasına döner**: "Pazar 10:00" yerine
"ilk Türkiye geneli deneme — kaydını bırak, tarihi ilk sen duy" (sayfada bu akış zaten var).
Ama tarihli olan tarihsizden kat kat güçlüdür; önce Faz 4 teyit edilmeli.

### FAZ 1 · HACİM (gün 1–30) — tek kural: HER GÜN BİR GÖNDERİ, TEK FORMAT

30 gün boyunca format **değişmez**. Beğenmediğimiz çıkarsa bile 30 gün basarız; karar
30. günde ölçüyle verilir. Sebep: format değiştirmek sayaçları sıfırlıyor.

| Sıklık | Format | Bedel | Yakıt (elimizde) |
|---|---|---|---|
| Haftada 1 | **"Bir Hevesle Alınanlar"** film bölümü | ≈15 USD/bölüm | Bölüm 1 ve 2 BASILI |
| Her gün | **"Ne sanıyorsun"** — tek tuzak, telefon içinde gerçek ürün | **0 TL** | 2.079 katmanlı soru |
| Haftada 1 | **"35 dönem sayımı"** kartı/animasyonu | **0 TL** | `veri/siklik-kunyesi.json` |

Günlük formatın hattı kurulu: `araclar/kayit/kaydet-nobetci.js` (gerçek ürün kaydı) +
`scratchpad/patlat/arka.html` & `cerceve.html` (masa + telefon çerçevesi) + `kur-telefon.ps1`.
Ekranda **cisim** var (masa, telefon, ışık) — Cem'in "slayt gibi" itirazının çözümü buydu.

**Üretim GM'de, yükleme Cem'de.** Haftada bir kez 7 günlük paket teslim edilir; Cem her sabah
birini yükler. Günde 2 dakikalık iş.

**İki hesap, aynı içerik:** Tetikte içeriği @tetiktecom'a; @dizdardenetim'e haftada yalnız
bir kez (film) + kendi Paranın Günlüğü serisi devam.

### FAZ 2 · ELÇİ (gün 8'den sonra, film yayında ve seri anlaşılınca)

Elçi çağrısı §4'teki metinlerle yayınlanır. Teklife dördüncü ayak eklendi:
**elçiye paylaşacağı film de verilir.** Hiçbir sınav platformu elçisine hazır film vermiyor.
DM 30 kişilik seçilmiş pilota; 500'e değil.

### FAZ 3 · REKLAM (gün 15+, yalnız Faz 0 bittiyse)

**Kural: hiç denenmemiş içeriğe reklam verilmez.** 14 günlük organik yayının en iyi üç videosu
seçilir, reklam onlara konur. Kazananı organik seçer, biz değil. Bütçe kararı Cem'in;
GM tavsiyesi: önce en küçük bütçeyle tek video, dönüşüm maliyeti ölçülür, sonra büyütülür.

---

## 2 · ÖLÇÜM KAPILARI — neye bakıp ne karar vereceğiz

| Kapı | Ne ölçülür | Karar |
|---|---|---|
| **48 saat** (her gönderi) | izlenme · **kaydetme** · **paylaşma** · profil ziyareti | Paylaşma en güçlü sinyal. En çok paylaşılan konu ertesi hafta iki kez basılır. |
| **7 gün** | takipçi artışı · site tıklaması · üyelik | Tıklama var ama üyelik yoksa kusur sitede, içerikte değil. |
| **30 gün** | satış adedi · satış başına maliyet | Format devam mı, değişir mi — burada karar verilir, önce değil. |

**Hedef rakamı bilerek yazılmadı.** Bugün elimizde tek bir gönderinin bile ölçümü yok
(@tetiktecom 0 gönderi). Tabansız hedef uydurmaktır. İlk 7 gün tabanı kurar, hedefi
8. gün yazarız.

---

## 3 · BU PLANIN DAYANDIĞI ÖLÇÜMLER

| İddia | Kaynak | Tarih |
|---|---|---|
| @dizdardenetim 3.007 takipçi, doğrulanmış, 12 gönderi | canlı Instagram | 22.09.2026 |
| @tetiktecom 3 takipçi, 0 gönderi | canlı Instagram | 22.09.2026 |
| Mart'taki 7 statik gönderi 1–3 beğeni aldı | 07.09 ölçümü | 07.09.2026 |
| Sipariş düğmesi kapalı, IBAN girilmemiş | `satin-al.html:254` | 22.09.2026 |
| Kart ödeme yok | satış sayfalarında sağlayıcı araması | 22.09.2026 |
| 2 film yayınlanmamış (56,6 + 52,9 sn) | `Firmalar Reklam/Tetikte/` + ffprobe | 22.09.2026 |
| 2.079 katmanlı soru | `kaydir/sgs/*.html` | 12.09.2026 |
| 35 dönem, 3.248 tekil konu | `veri/siklik-kunyesi.json` | 22.09.2026 |
| Satılabilir tek paket SGS | `fiyat-motoru.js` → `ICERIK_HAZIR` | 22.09.2026 |

**Ölçülmedi:** 3.007 takipçinin kaynağı (reklam mı organik mi) · gönderi başına izlenme ·
site trafiği. Üçü de Cem'in panellerinde.
