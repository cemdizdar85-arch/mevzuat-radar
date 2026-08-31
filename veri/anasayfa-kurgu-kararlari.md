# ANA SAYFA KURGUSU — ölçümler ve kararlar (30–31.08.2026)

> **Bu dosya "neden böyle yaptık" sorusunun tek cevabıdır.** Aşağıdaki
> rakamların hepsi ölçüldü; ölçülemeyenler açıkça "ÖLÇÜLEMEDİ" yazıyor.
> Ölçüm aracı: tarayıcıda 1440×900 görünüm, her sitede aynı betik.

---

## 1. RAKİP ANA SAYFA ÖLÇÜMÜ (31.08.2026)

| Site | İş | H1 kelime | İlk ekranda eylem | İlk ekranda **büyük görsel** | Sayfada **toplam görsel** | Boy (ekran) |
|---|---|---:|---:|---|---:|---:|
| Stripe | ödeme altyapısı | 22* | 2 | 3 (canvas + tam genişlik) | 282 | 16,8 |
| Avalara | vergi uyum (ABD) | 15 | 7 | 2 (VİDEO 748×421) | 341 | 16,7 |
| Ramp | harcama yönetimi | 5 | 3 | 2 (canvas + VİDEO 1296×578) | 103 | 14,5 |
| Linear | ürün geliştirme | 21* | 13* | 1 (ürün ekranı 1440×804) | 257 | 11,1 |
| Fonoa | dolaylı vergi (AB) | 6 | 7 | 1 (canvas 1280×570) | 223 | 9,7 |
| Wolters Kluwer | hukuk/vergi | 4 | 3 | **1 (VİDEO 1440×739)** | 34 | 6,8 |
| Thomson Reuters | hukuk/vergi portalı | 10 | 10 | stok fotoğraf | 76 | 5,4 |
| Becker | CPA sınav hazırlık | **H1 YOK** | 5 | 0 | 25 | 5,1 |
| Sovos Türkiye | e-dönüşüm (TR) | 6 | 5 | 0 | 38 | 3,8 |
| **TETİKTE (30.08)** | biz | 3 | 5 | **0** | **0** | 8,2 |

<small>*Stripe/Linear'da H1 alt başlığı da içeriyor, eylem sayısı ürün görselindeki bağlantılarla şişmiş — o hücreler gürültülü.</small>

🔴 **ÖLÇÜM HATASI VE DÜZELTMESİ:** ilk turda Wolters Kluwer için "ilk
ekranda görsel yok" yazılmıştı. Yanlıştı — otomatik sayaç `<header>`
içindeki videoyu eliyordu. Ekran görüntüsü yakaladı. **Ders: yerleşim
iddiası ekran görüntüsüyle çapraz doğrulanmadan yazılmaz.**

### Bulgular
1. **Dokuz sitenin sekizinde görsel var; sıfır olan tek site bizdik.**
   En zayıfta bile 25 (Becker), en ağırda 341 (Avalara).
2. İlk ekranda büyük görseli olan beşi (Stripe · Avalara · Ramp · Linear ·
   Fonoa) ciddi ve uzun; olmayan üçü katalog gibi ve kısa. Ölçüye göre
   biz ikinci gruptaydık.
3. **Ciddi siteler UZUN** (9,7–16,8 ekran); zayıflar 3,8–5,4. "Kısaltalım"
   refleksi bizi zayıf gruba yaklaştırıyordu.
4. Başlığımız (3 kelime) zaten güçlü aralıkta. Sorun başlıkta değildi.
5. Beğenilen üçünde de başlık **sola dayalı ve büyük**: WK 102 px,
   Ramp ~64, Fonoa ~56. Bizimki 52 px ve **ortalıydı**; ilk ekranın
   **%84'ü boştu**.

### Cem'in yargısı (31.08, ekran görüntüleriyle bakarak)
- 👍 **Wolters Kluwer** ("giriş iyiymiş") · 👍 **Ramp** · 👍 **Fonoa**
- ❌ **Thomson Reuters**
- Ayrım: beğendiklerinde görsel ya markanın kendi hareketi ya **ürünün
  gerçek ekranı**; beğenmediğinde **stok fotoğraf**. Yani ölçüt
  "görsel var mı" değil, **"gerçek mi"**.

---

## 2. PAZAR ÖLÇÜMÜ (31.08.2026)

| Ne | Rakam | Kaynak |
|---|---|---|
| Kayıtlı meslek mensubu | **136.685** (SMMM 126.251 · SM 5.349 · YMM 5.085) | TÜRMOB, Ocak 2026 |
| **Aktif serbest çalışan** | **63.033** (SM+SMMM 59.958 · YMM 3.075) | aynı |
| **SPK lisanslama sınavı adayı** | **26.720 aday / 132.390 başvuru (2025)** — aday başına ~5 sınav | SPL 2025 Faaliyet Raporu |
| SMMM staja giriş / yeterlilik aday sayısı | **ÖLÇÜLEMEDİ** — TÜRMOB yayımlamıyor, faaliyet raporu flipbook | — |

**Sonuç:** "sınav pazarı daha büyük" iddiası **doğrulanamadı**. Buna karşılık
radar pazarı ölçüldü ve küçük değil. Kritik fark:
**sınav bir AKIŞ** (aday geçer gider, tasarım gereği %100 churn),
**radar bir STOK** (63.033 kişi her yıl orada, her yıl yeniden satılabilir).

---

## 3. KARARLAR

### (B) ANA SAYFA SINAVI ÖNE ALIR — Cem kararı 31.08
Cem'in gerekçesi "aday çok + şirketin güven süresi uzun".
**Doğrulanan gerekçe farklı ve kayda o geçmeli:** sınav **HIZ** için
seçildi, pazar büyüklüğü için değil.
- Ürün bitmiş (30.569 soru · 16.284 hakem denetimi), radarın kişiye özel
  uyarısı yok.
- Kasım'da tarih var: aciliyet bedava.
- Kanıt 30 saniyede; radarın kanıtı haftalar sürer.
- 29.08'de kilitlenen "kahraman ekran" kararıyla tutarlı.

🔴 **Yanlış gerekçeye inanırsak 2027'de de sınava yatırım yapıp radarı
aç bırakırız. Sınav hızlı nakit, radar kalıcı gelir.**

### ÜÇ KAPI → İKİ KAPI — Cem kararı 31.08
"Mali Müşavirim" + "Şirket sahibiyim" → **"İş başındayım"**
(«Sınava hazırlanıyorum»un tam karşıtı: hazırlanan / çalışan).
Hedef `karne.html` — girişsiz çalışıyor. Eski 02 kapısı `radar-app.html`'e
gidip girişsiz kullanıcıyı duvara çarpıyordu (30.07'de Cem yakalamıştı).

### HERO = NÖBET DEFTERİ — 31.08
Reddedilen dört kurgu ve **ölçülebilir** sebepleri:

| Kurgu | Neden reddedildi |
|---|---|
| İki panel (sınav + mevzuat yan yana) | uzlaşma; iki panel farklı dil konuşunca gürültü |
| Ekran görüntüsü | motorun **fotoğrafı**, motorun kendisi değil |
| Canlı soru kutusu | ziyaretçiyi **kapıda sınava sokuyor**; 20 yıllık müşavire meydan okuma |
| Açıklama paneli | **sorusu olmayan cevap** — soruyu görmemiş için anlamsız |

**Kabul edilen:** `veri/uyari-ozet.json`'u robot her sabah 07:03'te yazıyor
(`motor/uyari-robotu.ps1` + `.github/workflows/uyari.yml`) ve **hiçbir
sayfada okunmuyordu**. Nöbet defteri onu ilk kez vitrine çıkardı.
Sınav bloğu en üstte (Cem: "yukarıya sınavla ilgili de bir şey eklersek
süper olur").

🔴 **Dört turluk asıl ders: her seferinde YENİ bir şey icat etmeye
çalıştım; cevap depoda hazır duruyordu. İlk soru "elimizde ne var?"
olmalı.**

---

## 4. AÇIK KALANLAR

- **Nöbet defterinde marka ve alacak satırı yok.** `uyari-ozet.json`'da
  günlük toplam yok (`izlenen_borclu`/`alacak_eslesme` kişiye özel, ikisi
  de 0 çünkü izlenen firma yok). `uyari-robotu.ps1`'e eklenmeli.
- **Nöbet damgası kaldırıldı** çünkü `kart-durum.json` (30.08) ile
  `uyari-ozet.json` (31.08) aynı ekranda çelişiyordu. Geri istenirse
  **önce iki kaynak birleştirilmeli**, yoksa çelişki geri gelir.
- **Mühürlü örnek sorularda `sinav`/`ders` alanı YOK** (`feda-ornek-1..4`).
  Ölçümle çıkarıldı: feda-1 Maliyet Muhasebesi → SGS kotasında 202,
  KGK'da 0. feda-4 (TMS 37) → KGK. **Yeterlilik için mühürlü kısa-cevaplı
  soru yok.** Sınav anahtarı ancak her sınav için kısa-cevaplı mühürlü
  soru olunca kurulabilir.
- **`kartlar-guncel.json` 29.08 tarihli, bugün 31.08.** Nöbet iddiası kuran
  sayfada bu sessiz kalmamalı — panele bayat-veri nöbetçisi kondu.
- **GoatCounter olaylarının hesaba düştüğü panelden teyit edilmedi.**

---

## 5. STİL KATMANI SIRASI — 🔴 KIRILGAN

`stil.css` → satır içi `<style>` → **`stil-sade.css`** → `komut.css` →
`stil-acik.css` → **`stil-odak.css` (EN SON)**

- `stil-sade.css` yerleşimi `!important` ile eziyor: **index.html'in kendi
  `<style>` bloğundaki yerleşim kuralları büyük ölçüde ÖLÜDÜR.**
  Somut vaka: `.mini-pencereler` index'te `repeat(4,1fr)` yazıyor, canlıda
  `repeat(2,1fr) !important` çalışıyor.
- `stil-odak.css` **en son** yüklenmek zorunda; araya yeni stylesheet
  girerse hero düzeni **sessizce** kaybolur. Yeni katman bunun ALTINA.
- **Kural: yerleşim iddiası `getComputedStyle` ile ölçülür, kaynaktaki
  kural okunarak değil.**
