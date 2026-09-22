# CANLI DENEME — 5.000 KİŞİ YÜK ÖLÇÜMÜ

Ölçüm: **23.09.2026** · Ölçen: GM (site kolu) · Yöntem: gerçek üretim uçlarına istek
Betikler: scratchpad `yuk-testi.js` (INSERT) · `yuk-get.js` (anahtar okuma)

> **Kural gereği:** bu sayfa "dayanır" demez, **ölçülen vakayı** yazar.
> Ölçülmeyen her şey aşağıda "ÖLÇÜLMEDİ" başlığı altındadır.

---

## 1 · MİMARİ — yükün nereye bindiği

| Aşama | Nereden | Sunucu yükü |
|---|---|---|
| Soru paketi (şifreli, 328 KB) | GitHub Pages / Fastly | CDN · kişi başına 1 indirme, 30 dk'ya yayılı |
| **Sınavın kendisi (120 dk)** | tarayıcı | **SIFIR istek** |
| Anahtar | Supabase Storage (yedek: Pages) | küçük dosya, yoklama |
| Sonuç | Supabase PostgREST | kişi başına **tek** INSERT |

Sınav süresince sunucuya hiçbir istek gitmiyor. Yük yalnız **iki anda** var:
kapı açılışı (anahtar) ve teslim (sonuç).

---

## 2 · ÖLÇÜLENLER

### 2.1 Sonuç yazma — `POST /rest/v1/canli_sonuc` (anon, RLS yalnız INSERT)

| Koşu | İstek | Eşzamanlı | Gerçekleşen | Başarılı | Hata | p50 | p95 | p99 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 50 | 10 | 30,6/sn | 50/50 | 0 | 240 ms | 739 ms | 872 ms |
| B | 500 | 100 | **205,8/sn** | 500/500 | 0 | 169 ms | 1.319 ms | 1.404 ms |
| C | 1.000 | 200 | **255,0/sn** | 1.000/1.000 | 0 | 355 ms | 2.222 ms | 2.275 ms |

Üç koşuda da HTTP **201**, tek hata yok, 429/5xx yok. **Tavan görülmedi** —
sınırlayan büyük olasılıkla ölçümü yapan makine ve ev bağlantısıydı, sunucu değil.

Test satırları (1.550 adet, `oturum='YUK-TESTI-2309'`) servis anahtarıyla **silindi**;
silme sonrası tabloda **0 satır** kaldı (yani öncesinde gerçek sonuç da yoktu).

### 2.2 Anahtar okuma — Supabase Storage public nesne

| İstek | Eşzamanlı | Gerçekleşen | Başarılı | Hata | p50 | p95 |
|---:|---:|---:|---:|---:|---:|---:|
| 600 | 150 | **169,0/sn** | 600/600 | 0 | 322 ms | 1.711 ms |

### 2.3 Paket indirme — GitHub Pages

`tetikte.com/veri/canli/SGS-2308.enc.json` → **200 · 327.702 bayt · 0,84 sn** ·
`Server: GitHub.com` · Fastly (`X-Served-By`) · `Cache-Control: max-age=600`.
5.000 kişilik toplam ≈ **1,6 GB** — GitHub Pages için sorun değil.

### 2.4 ⚠ Supabase Storage CDN'lenmiyor (bugün öğrenildi)

Public nesne yanıtı `Cache-Control: no-cache` döndürüyor ve bu, yükleme sırasında
`cache-control: max-age=5` başlığı verilse bile **değişmiyor** (CF-Cache-Status
MISS → REVALIDATED). Yani anahtar yoklaması Cloudflare'da durdurulamıyor,
her yoklama Supabase'e ulaşıyor. Kazanç yalnız GitHub Pages yedeğinde.

---

## 3 · YAPILAN DÜZELTMELER (`canli-deneme.html`)

| # | Önce | Sonra | Etki (5.000 kişi) |
|---|---|---|---|
| 1 | Sonuç gönderimi 0,5–15,5 sn'ye yayılı | **0,5–150 sn** | tepe ≈333/sn → **≈33/sn** |
| 2 | Başarısız gönderim tekrarı sabit 9 sn | **20–60 sn rastgele** | düşen istekler aynı ana yığılmıyor |
| 3 | Anahtar yoklaması 8–15 sn | **10–25 sn** | ≈435/sn → **≈286/sn** |
| 4 | Cache-buster `?<ms>` (benzersiz) | **10 sn kova** (anahtar) / **60 sn kova** (paket) | Pages tarafında CDN devreye girdi |
| 5 | Supabase `canli` kovası **yoktu** | **oluşturuldu (public)**, uçtan uca prova yapıldı, prova dosyası silindi | 10:00'da denenmemiş yol kalmadı |

Ölçülen tepe kapasite (255/sn) ile düzeltme sonrası beklenen tepe (33/sn)
arasında yaklaşık **8 kat** pay var.

---

## 3b · ⭐ 24.09 — TARAYICI PROVASI: SUNUCUDAN BÜYÜK RİSK SAYFANIN İÇİNDEYDİ

Sayfa gerçek şifreli paket (`SGS-2308.enc.json`, 93 soru) + gerçek anahtarla, yerel
sunucuda, kapı saati 3 dk sonraya kurularak **uçtan uca** koşuldu. Sayfa hiç
çalıştırılmamıştı (`canli_sonuc` tablosu 0 satır — Ağustos oturumları yapılmamış);
prova **üç kusur** çıkardı, üçü de düzeltildi ve yeniden prova edildi:

| # | Kusur (düzeltmeden önce) | Etkisi | Düzeltme | Prova sonucu |
|---|---|---|---|---|
| 1 | Oturum, başlangıç **saniyesinde** "geçmiş" sayılıyordu | 10:00:01'de sayfayı **açan ya da yenileyen** sınavı **hiç görmüyordu**, bir sonraki oturumun geri sayımına düşüyordu | Geç giriş penceresi: yeni giriş **30 dk**, yarım sınavı olan **180 dk** | ✅ saatten sonra açan girdi · takvim "ŞU AN SÜRÜYOR" |
| 2 | Cevaplar yalnız bellekte | Arama gelmesi / sekmenin kapanması / yenileme → **tüm cevaplar silinir, süre 120 dk'dan yeniden başlar** | Her işaretleme ve geçişte cihaza yazılır; açılınca kaldığı yerden, **kalan** süreyle | ✅ 3 cevap + soru no geri geldi · sayaç 149:51 → 149:40 (sıfırlanmadı) |
| 3 | Sınav açılınca sayfadaki **tüm** `.kart`'lar gizleniyordu | **Soru kartı** (ve sonuç kartları) da gizlenirdi → sınav ekranı sayaçla ama **sorusuz** açılırdı | Yalnız sınav/sonuç ekranı dışındaki kartlar gizlenir | ✅ soru kartı ve 93 açıklamalı sonuç görünür |
| + | Geç gelende küçük anahtar 328 KB paketten önce inerse "Paket eksik, sayfayı yenile" döngüsü | Yavaş mobilde geç gelen giremez | Paket yoksa önce indirilir, sonra açılır | ✅ geç gelen (boş cihaz) girdi |
| + | Bitmiş sınav yenilenirse sonuç yeniden gönderilebilirdi | Aynı skor sıralamaya iki kez girer | `gonderildi` bayrağı cihaza yazılır | ✅ yenilemede ikinci istek YOK (ağ kaydı boş) |

Prova sırasında gerçek veritabanına tek satır yazılmadı (sonuç isteği sayfa içinde
taklit edildi); prova sonrası `canli_sonuc` = **0 satır** (ölçüldü).

## 3c · 🔴 ÜYELİK YOLUNUN TAVANLARI — Supabase panelinden okundu (24.09, yalnız okuma, ayar DEĞİŞTİRİLMEDİ)

| Ayar | Değer | Anlamı |
|---|---|---|
| E-posta onayı (`mailer_autoconfirm`) | **false** (onay AÇIK) — `/auth/v1/settings` ile de ölçüldü | Her kayıt bir onay e-postası gönderir; tıklanmadan giriş yok |
| Özel SMTP | **AÇIK** · gönderen `hesap@tetikte.com` "Tetikte" · kullanıcı `resend`, port 465 | Deneme posta servisi değil, Resend üzerinden gidiyor ✅ |
| **E-posta gönderim tavanı** | **saatte 30 — PROJE GENELİ** | 🔴 **Tüm site saatte en çok 30 kayıt onayı/şifre e-postası gönderebilir.** 31. kişi "email rate limit exceeded" alır |
| Kayıt + giriş tavanı | **5 dk'da 30 — IP BAŞINA** | Mobil operatörler yüzlerce telefonu tek IP'de toplar (CGNAT) → aynı operatörden aynı anda giriş yapanlar birbirini tıkayabilir |
| Oturum yenileme | 5 dk'da 150 — IP başına | Canlı deneme sayfası bunu HİÇ kullanmıyor (uyeMi ağa gitmez) |
| Resend'in kendi planı / günlük kotası | **ÖLÇÜLMEDİ** — Chrome'da Resend oturumu yok, giriş yapılmadı | Tavan yükseltilirse sıradaki sınır bu olur |

**Sonuç:** "sınav bitince 5.000 kişi aynı anda üye olsun" tasarımı bu ayarlarla **ilk saatte 30 kişide tıkanırdı**.
Bu yüzden üyelik kapısı sınavdan ÖNCEYE alındı ("Yerini ayır") ve üyelik kontrolü ağa gitmeyecek şekilde kuruldu.
Ama 12 güne yayılsa bile tek bir viral gönderi saatte 30'u aşar → ayar kararı Cem'deydi (güvenlik ayarı).

✅ **24.09 KARAR VE UYGULAMA (Cem: "kapat onayı sen yap"): e-posta onayı KAPATILDI.**
Panel → Authentication → Sign In / Providers → "Confirm email" KAPALI, "Successfully updated settings".
Doğrulama (dışarıdan, ölçüldü): `/auth/v1/settings` → `mailer_autoconfirm: true`.
Uçtan uca deneme: prova hesabıyla kayıt → **anında oturum** geldi, e-posta onaylı sayıldı, **e-posta gönderilmedi**;
prova hesabı yönetici API'siyle silindi (tekrar aranınca bulunamadı).
Sonuç: kayıt yolunda saatte-30 tavanı ARTIK YOK. Şifre sıfırlama e-postaları hâlâ bu tavana tabi (düşük hacim).
Bedeli (bilerek kabul edildi): adresler doğrulanmamış — yanlış yazılmış/uydurma adres üye olabilir;
toplu tanıtım e-postası bu listeye körlemesine atılmamalı (geri dönen posta Resend itibarını düşürür).

## 3d · ⭐ ÇOK TARAYICILI PROVA (24.09 gece, iki koşu)

25 **gerçek başsız tarayıcı** (her biri ayrı cihaz gibi, ayrı localStorage, 390×800 telefon ekranı)
+ **2.000 sanal istemci** anahtar kalabalığı. Anahtar **gerçek Supabase kovasına** kapı saatinde
basıldı (`scratchpad/prova/anahtar-yayinla.ps1`), sonuçlar **gerçek `canli_sonuc`** tablosuna gitti.
17 erken, 5 geç (kapı+10–60 sn), 3 çok geç (kapı+90–120 sn); her 4 kişiden biri sınav ortasında sayfayı yeniledi.

| Ölçüm | 1. koşu | 2. koşu |
|---|---|---|
| Anahtar kapıdan kaç sn sonra yayında | 3,14 sn | 1,91 sn |
| Sınava giren | **25/25** | **25/25** |
| Erken gelenin sınavı açılma anı (kapıdan sonra) | 11,9–15,6 sn | 6,0–24,9 sn (yoklama aralığı 10–25 sn) |
| Sınav ortasında yenileme: cevap + süre korundu | **6/6** | **6/6** |
| "Sınavı bitir" → sonuç tabloya ulaştı | 0/25 ❌ (aşağıda) | **25/25** ✅ |
| Anahtarı bulan sanal istemci | 2.000/2.000 | 2.000/2.000 |
| Üye görünümü (oturum kaydı elle kondu) | — | "Üyesin, yerin ayrıldı" · davet yok · **93 açıklama açık** ✅ |
| Üye olmayan görünüm | — | davet kutusu görünür · açıklamalar 🔒 ✅ (tarayıcıda ayrıca doğrulandı) |

**1. koşudaki 0/25 bir sayfa kusuru DEĞİL, açılış perdesiydi:** `menu.js`'teki site geneli
"Tetikte çok yakında" perdesi (`#mrPerde`, `z-index:99999`) önizleme anahtarı olmayan her yeni
ziyaretçide sayfanın tamamını kaplıyor; düğmeye dokunulamıyordu. Perde altında sınav çalışıyordu
(25/25 girdi). 2. koşuda perde kaldırılmış hâl (`mrOnizleme=1`) denendi → 25/25 ulaştı.
🔴 **Bağımlılık:** 4 Ekim'de canlı sitede perde KALKMIŞ olmalı (`motor/gong.ps1`, açılış günü).
Açılış kayarsa sınava kimse dokunamaz.

**Sanal kalabalıktaki "ağ hatası" (1.129 / 1.071):** hepsi istemci tarafında, tek makinenin aynı anda
2.000 bağlantı açamamasından; 4xx/5xx **sıfır**, hata alan istemci yeniden denedi ve **hepsi** anahtarı aldı.
Sunucu tarafında reddedilen istek görülmedi.

**Temizlik (ölçüldü):** prova sonuçları (25 satır) silindi → `canli_sonuc` **0 satır**; prova anahtarı
kovadan silindi → kova **boş**.

**Ölçüm hatası kaydı:** 2. koşuda "üye olmayan kapı 0/25" çıktı; sebep ölçüm betiğiydi — kilit metni
kapalı `<details>` içinde olduğu için `innerText` onu saymıyor. Tarayıcıda doğrudan bakıldı: davet görünür,
kilit metni HTML'de var. Kapı doğru, ölçüm yanlıştı.

## 4 · ÖLÇÜLMEDİ (bu sayfanın körlükleri)

- **5.000 gerçek tarayıcı** hiç denenmedi; ölçüm tek makineden yapıldı.
  Gerçek dünyada mobil ağlar, yavaş cihazlar ve 5.000 ayrı IP devreye girer.
- **Anahtarın geç yayınlanması** senaryosu denenmedi. Kısa tepe sorun değil;
  anahtar 10 dakika gecikirse yoklama yükü 10 dakika **sürekli** olur.
- **Tarayıcıda 120 dakikalık oturum** (sekme arka plana alınınca sayaç, uyku
  modu, sayfa yenileme) denenmedi.
- **Paket indirme** 5.000 eşzamanlı denenmedi, tek istek ölçüldü.
- Supabase Pro planının ilan edilmiş bir istek/sn tavanı yok; buradaki sayılar
  **o gün, o uçtan** ölçülmüştür, garanti değildir.

---

## 5 · SINAV GÜNÜ KURALLARI

1. **Anahtar saatinde basılır** (`motor/canli-anahtar-yayinla.ps1 -oturum <kod>`).
   Gecikme, ölçülen tek gerçek risktir.
2. **O gün SQL basılmaz** — 14.09 ölçümü: auth.users FK'lı tablo basarken
   PostgREST 2–3 dk **503** veriyor.
3. Sonuç gönderilemezse skor kaybolmaz: `localStorage`'a yazılıyor ve kullanıcıya
   söyleniyor.
4. Servis anahtarıyla istek atarken **tarayıcı User-Agent'ı kullanılamaz** —
   Supabase "Forbidden use of secret API key in browser" ile reddediyor
   (PowerShell'in varsayılan UA'sı "Mozilla" içerdiği için düşüyor; `-UserAgent`
   ile düz bir ad verilmeli). 23.09'da bu tuzağa düşüldü.
