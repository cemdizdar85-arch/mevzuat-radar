# Adım 2 — Paket soruları kilitli kasaya: plan, sıra, bedel (15.09.2026)

> Cem 14.09: "Adım 2 kart ödemesi onayıyla aynı haftaya." Bu belge o gün **bekleme olmadan** başlamak için yazıldı.
> Rakamlar 14–15.09 ölçümünden; ölçülmeyen "ölçülmedi" yazar.

## 0. Bugünkü durum (ölçüldü)
- **Açıkta paket içeriği:** 33 dosya / 5.208 soru (içerik nöbetçisi, 14.09).
  17 Kaydır-Çöz sayfası `kaydir/sgs/*.html` (toplam **53,4 MB**, soru başına ortalama ~14 KB) + 10 deneme seti + arşiv/örnek dosyaları.
- **Adım 1 kapısı** (`paket-kapisi.js`) yalnız **görüntüde** kilit: dosyayı doğrudan indiren her şeyi alır.
- **Soruların asıl kaynağı zaten kilitli:** Supabase `kalip_parti` (yalnız sunucu anahtarı okur).
- **Ücretsiz katman da cevap dağıtıyor:** seviye testi havuzu 450 soru, cevaplarıyla `veri/seviye/sgs-havuz.json`'da açık.
- **Paket kuralı eksik:** `soru_havuzu` politikası paketin **süresine** bakıyor, **hangi dersleri** aldığına (`paket_uyeler.dersler`) bakmıyor.
- **Yayındaki soruların kalitesi:** 3.809 sorudan 4'ünün ret kaydı var, dördü de Matematik, sınıf "kaynak eksik".
  Cevaplar bağımsız hesapla doğrulandı: 210 · 348 · 18 · 15, dördü doğru. **15.09 DÜZELTME:** basım adımı bu 4 soruyu zaten "hakem HAYIR" ile düşürüyor (kuru koşu); sayfa bu hükümden önce basılmış, yeniden basılmamış. Ret kütüğü kapısı ve nöbetçi satırı b48b9574 ile eklendi (madde 6 TAMAM).

## 1. Hedef mimari
```
Soru robotu ──(sunucu anahtarı)──► Supabase  paket_soru  (RLS)
                                         │
     giriş yapmış + aktif paketli üye ◄──┘  (ders ders, sayfalı çekim)
     anonim ziyaretçi ◄── yalnız ucretsiz=true satırlar (vitrin + seviye testi soruları, CEVAPSIZ)
Depo / GitHub Pages: yalnız sayfa KABUĞU (soru yok) + kimlik dosyaları (sıra, id)
```

## 2. İş sırası

| # | İş | Ayrıntı | Süre (tahmin) |
|---|---|---|---|
| 1 | 🟡 **Tablo + kurallar** (taslak hazır: `radar-app/sql/TASLAK-2026-09-15-paket-soru.sql`, basılmadı) | `paket_soru(id pk "etiket/kp-NN", sinav, ders, konu, sira, veri jsonb, ucretsiz bool, guncelleme)`. RLS: okuma = aktif paket + (paket tam **ya da** ders `paket_uyeler.dersler` içinde); `ucretsiz` satırlar anonim okunur ama `veri`'den doğru şık ve açıklama çıkarılmış görünümle. DDL düşük trafik saatinde, eşzamanlı sağlık izlemesiyle (14.09 PostgREST 503 dersi). `UYGULANDI.md`'ye satır. | 1–2 saat |
| 2 | 🟡 **Yükleyici** (hazır: `motor/kasa-soru-yukle.js`, yalnız kuru koşu; 3.727 satır / 49,9 MB) | `motor/kasa-soru-yukle.js`: Kaydır-Çöz basımındaki soru nesnelerini `paket_soru`'ya upsert eder. `yayin-bas.yml` içinde sayfa basımından hemen sonra koşar (secret zaten var). Kuru koşu + sayım kapısı: yüklenen = basılan. | yarım gün |
| 3 | **Sayfa kabuğu** | `kaydir-coz.ps1` şablonuna kasa modu: `SORULAR` gömülmez; sayfa oturumla kasadan ders sorularını 50'şerli çeker. **EŞDEĞERLİK PROVASI:** kasadan gelen 3.727 benzersiz sorunun tamamı (3.809 sayımı muhur-10/kapituru-3 tekrarlarını içeriyordu), bugünkü gömülü nesneyle alan alan aynı olmalı; fark = 0 değilse yayın yok. | 1 gün |
| 4 | **Deneme ve "sınav gibi"** | Set dosyaları yalnız kimlik ve sıra taşır; sorular kasadan kimlikle çekilir. | yarım gün |
| 5 | **Seviye testi** | Soru istemcide cevapsız gelir; doğru mu kontrolü sunucuda: `seviye_kontrol(id, secim)` fonksiyonu, IP başına hız sınırıyla. Böylece ücretsiz test cevap dağıtmaz. | yarım gün |
| 6 | ✅ **Kalite kapısı** (15.09 yapıldı, b48b9574) | Seçim adımı (`sgs-650-bas.ps1`) ret kütüğündeki kimliği seçmez. Ya da seçerse gerekçesi yazılı "kurtarma" işareti ister. İçerik nöbetçisine "yayında ret kaydı olan soru" satırı eklenir. | 2 saat |
| 7 | **Depodan çıkarma** | 17 sayfa kabukla değişir; deneme setleri kimlik dosyası olur; arşiv ve örnek soru dosyaları git dışındaki kasaya taşınır. İçerik nöbetçisinin tabanı **boşaltılır** → YEŞİL. | 1–2 saat |
| 8 | **Geçmiş temizliği** | [[gecmis-temizligi]] reçetesi: izole çıplak klon, soru dosyalarının geçmişten silinmesi, robot commit'lerinin taşınması, `--force-with-lease` ile gönderim. 20.08'de 4.095 commit ~105 dk sürdü. **Canlı klasörde yapılmaz.** GitHub önbelleği için Support'tan temizlik istenebilir. | 3–4 saat |

**Toplam:** yaklaşık 3–4 iş günü. 1–7 site kesintisiz yapılır. 8 tek pencerede, robotlar açıkken güvenli reçeteyle yapılır.

## 3. Bedel
- **Ek para: 0 TL (öngörü).** Supabase Pro zaten ödeniyor; plan 250 GB çıkış trafiği içeriyor.
  Kaba üst sınır: 1.000 aktif öğrencinin her biri bankanın tamamını bir kez indirse 1.000 × 3.809 × ~14 KB ≈ 53 GB.
  Gerçek kullanım ölçülmedi.
- **Performans riski:** veritabanı işlemcisi en küçük boyda (NANO). Sınav haftası yükü ölçülmedi.
  3. adımdan sonra 50 eşzamanlı çekimle yük provası yapılır; gerekirse o hafta işlemci yükseltilir, bedeli o gün sorulur.

## 4. Riskler ve frenler
- **Sayfa açılmazsa satış durur.** Kasa modu önce tek derste (Türkçe, 77 soru) açılır, bir gün izlenir, sonra hepsine yayılır.
  Geri dönüş: eski gömülü sayfalar git geçmişinde; tek commit'le geri alınır. Geçmiş temizliği (8) bu yüzden **en son**.
- **Oturum süresi dolan öğrenci** boş sayfa görmesin: kapı zaten "giriş yap" ekranına düşüyor (Adım 1).
- **Önceden indirilmiş kopyalar geri alınamaz.** Adım 2 bundan sonrasını kapatır.

## 5. Cem'in kararı gereken 3 şey
1. **Ders bazlı erişim:** ders paketi alan yalnız aldığı dersleri mi görsün? (Önerim: evet; satış sayfası zaten ders seçtiriyor.)
2. **Seviye testi cevap kontrolü sunucuya taşınsın mı?** (Önerim: evet; yoksa ücretsiz katman 450 soruyu cevabıyla dağıtmaya devam eder.)
3. **Geçmiş temizliği için zorla gönderim onayı** (8. adım; 20.08'deki gibi).

### ✅ KARAR (16.09.2026, Cem "1.2.3 üçünü de yap" — sınav oturumu 92 aracılığıyla yazıldı)
1. **Ders bazlı erişim: EVET.** Ders paketi alan yalnız aldığı dersleri görür (`paket_uyeler.dersler`).
2. **Seviye testi cevap kontrolü sunucuya: EVET.** `seviye_kontrol(id, secim)` + IP başına hız sınırı; istemciye cevapsız soru.
3. **Geçmiş temizliği: EVET, ama EN SON** (1–7 bitip kasa modu en az bir gün sorunsuz koştuktan sonra). Zorla gönderimden
   hemen önce Cem'e **bir kez daha** "şimdi basıyorum" diye sorulur — onay tarihi ile basım günü arasında robot/oturum durumu değişmiş olabilir.
Uygulama **site kolunun** işidir (sınav oturumu site dosyasına dokunmaz). Site oturumu açıldığında bu bölümden başlar.
Ek bilgi (16.09 ölçümü): depoyu gizli yapmak ≈300–450 USD/ay (30 günde ~49k Linux + ~3,1k Windows dakika) + Pages için ücretli plan → **önerilmedi**; açık içerik sorununu bu plan çözer.

---

## 6. 16.09.2026 — Cem "depoda soru içeriği kalmasın, 1.2.3 üçünü de yap" (site oturumu 3c)

**Kapsam genişledi:** yalnız satılan sayfalar değil, sınav çalışma dosyaları da açık depodan çıkar.
Depo ölçümü 16.09 (origin/main): Kaydır-Çöz 19 dosya / 57,6 MB · deneme + seviye 12 / 1,6 MB ·
plan + konu 2.171 / 1,9 MB · teori notu adlı 64 / 1,2 MB · çıkmış + diğer `veri/sinav` 122 / 10,5 MB · kod 2.008 / 38,3 MB.
Fork 0 · 14 günde klon 30.531 (1.458 tekil; çoğu kendi robotlarımız, ayrılamıyor) · görüntüleme 51 (6 tekil).
**Kod açık kalır** (gizlemek ≈300–450 USD/ay); içerik çıkar.

### 6.1 Yol A — satılan sorular Supabase'e (bu belgenin 1–7. adımları)
- SQL son hâli: `radar-app/sql/2026-09-16-paket-soru.sql` (taslak eskidi). ⏳ Cem onayıyla, düşük trafikte basılır.
- **Pilot:** kasa modu önce **Türkçe (77 soru)** sayfasında açılır, bir gün izlenir, sonra 15 derse yayılır.
- Vitrin (`kaydir/vitrin/sgs.html`, Cem 31.07 onaylı ücretsiz örnek) gömülü kalır — bilinçli açık.

### 6.2 Yol B — sınav çalışma dosyaları gizli depoya
- Depo kuruldu: **`cemdizdar85-arch/tetikte-kasa` (PRIVATE, 16.09)**. İçinde Actions KOŞMAZ → bedel 0.
- Taşımayı **sınav kolu** yapar (92 kabul etti, 16.09). Taşınacak: `veri/sinav/plan-*`, `veri/sinav/konu/`,
  `veri/mevzuat/teori-notlari-*.json`, çıkmış soru dosyaları, `veri/deneme/` soru gövdeleri, `veri/seviye/sgs-havuz.json` (Yol A bitince).
- **92'nin üç şartı:** (1) `motor/kalip-kosucu.ps1` plan/konu yolunu gizli depo klasöründen de çözer;
  (2) teori notunu okuyan robotlar (mevzuat-yukle) yeni yeri bilir; (3) açık depodaki kopyalar **koşan bulut işleri bittikten sonra** silinir.
- 🔴 **CEM ADIMI (oturumlar anahtar üretmez, görmez):** GitHub → Settings → Developer settings → Fine-grained tokens →
  *Generate new token* · Repository access: **Only select repositories → tetikte-kasa** · Permissions: **Contents: Read-only** · süre 1 yıl.
  Sonra mevzuat-radar → Settings → Secrets and variables → Actions → *New repository secret* · ad: **`KASA_OKUMA_TOKEN`**.
  Bulut işi `actions/checkout` ile `repository: cemdizdar85-arch/tetikte-kasa`, `token: ${{ secrets.KASA_OKUMA_TOKEN }}`, `path: _kasa` okur.
  Gizli depoya YAZAN iş gerekirse ayrı, yazma yetkili ikinci anahtar — şimdilik yok.

### 6.3 Geçmiş temizliği (8. adım)
- Yol A pilotu + 15 ders kasa modunda **en az bir gün sorunsuz** koştuktan ve Yol B taşıması bittikten sonraki bir akşam.
- Zorla gönderimden hemen önce Cem'e bir kez daha sorulur (16.09 kararı geçerli).

### 6.4 Durum 16.09 15:30 — altyapı hazır, basım bu akşam (Cem "1.2.3 yap")
Gönderildi: 1bb30037 (SQL + reçete) · 84d356c9 (kasa modu altyapısı) · icerik nöbetçisi (kabuk tanıma).
- `kasa-yukle.js` + `paket-kapisi.js` sinyali · `motor/kasa-kabuk.js` (eşdeğerlik kapılı kabuk, `--tam-mi`) ·
  `motor/kasa-soru-yukle.js` (kabuk atlar, bayat siler, tablo yoksa çıkış 3) · `yayin-bas.yml` iki adım · `arac/kasa-modu.json` **BOŞ**.
- Prova: 15 ders sayfasında kabuk ~158 KB, kabukta `"dogru"` 0. Tarayıcıda sahte kasayla Türkçe kabuğu asıl sayfayla
  **metin izi birebir** (46.140 karakter, 78 kart), tek istek, tema düğmesi ve `#s=40` kaydırma çalışıyor.
- Okuyucu taraması (26 dosya): kabuğu SESSİZCE boş sayan `arac/cevap-dagilimi-olc.ps1` (ders tabanını siler),
  `motor/soru-dizini.js`, `motor/icerik-nobetcisi.js` (düzeltildi), `vitrin-soru-sec.js`/`vitrin-kart.js` (uyarıyla geçer).
  Yayında hepsi kabuktan ÖNCE koşar; `--tam-mi` kabuk kalmışsa durdurur. ⚠ `motor/site-nobeti.ps1` meslek-hukuku için
  300 KB alt sınır tutuyor → Meslek Hukuku kasaya alınmadan ÖNCE o sınır değişmeli (yoksa 15 dk'da bir yanlış alarm).

**BU AKŞAM (22:00 sonrası, Cem "bas" deyince) sıra:**
1. `radar-app/sql/2026-09-16-paket-soru.sql` bas (SQL Editor) — eşzamanlı sağlık: `dokumanlar?select=id&limit=1` 10 sn'de bir.
2. Dış ölçüm → UYGULANDI.md: anon `paket_soru` 401/0 · anon `ucretsiz_soru` 200, `veri` içinde `dogru` yok · servis `paket_soru` 200 [].
3. `node motor/kasa-soru-yukle.js --yaz` (yerel, servis anahtarı) → kasada ≈4.043 satır (~53 MB; disk tavanı 8 GB, ölçülecek).
4. Seviye kontrolü: ücretsiz bir kimlikle `rpc/seviye_kontrol` → `dogru_mu`; 41. çağrıda `cok fazla istek`.
5. `arac/kasa-modu.json` → `["kaydir/sgs/turkce.html"]`, `node motor/kasa-kabuk.js` (kuru, eşdeğerlik) → `--yaz` →
   `node motor/icerik-nobetcisi.js --canli-yok` (KASADA 1) → turkce.html + kasa-modu.json aynı commit → push.
6. Canlıda anonim: perde çıkıyor, `kaydir/sgs/turkce.html` içinde soru yok. Paketli deneme: **Cem kurucu hesabıyla** Türkçe sayfasını açar.
7. Bir gün sorunsuz → kalan 14 ders (Meslek öncesi site-nobeti sınırı) → adım 4–5 (deneme seti, seviye testi) → Yol B → geçmiş temizliği.

---

## 7. 29.09.2026 — yeniden ölçüm + Cem "1.2.3 üçünü de yap" (oturum 99da7c)

**Ölçüm (canlı + kasa, 29.09):** Yeterlilik 8 + KGK 6 sayfa zaten kabuk (canlıda `"dogru"` 0). Açık: SGS 16 sayfa
(Türkçe hariç), `veri/deneme/sgs-set-*` (10, cevaplı), `veri/seviye/sgs-havuz.json` (675 cevap), depoda `kaydir/_arsiv/` 3 sayfa.
Kasa `paket_soru` 8.897 satır (SGS 4.917 · Yeterlilik 3.872 · KGK 108 · ücretsiz 808). Paketli üyeyle canlı çekim **hiç ölçülmedi**.

**Yapıldı — seviye testi (plandaki 5. adım):** havuz dosyası YALNIZ KİMLİK (482 KB → 60 KB, cevap izi 0); SGS kipi soru
metnini `ucretsiz_soru`'dan cevapsız alır, doğruyu `rpc/seviye_kontrol` söyler (Yeterlilik kipiyle aynı yol). Havuz her yayında
`yayin-bas.yml` içinde yeniden kurulur. Yan bulgu: eski havuz 16.09'dan beri tazelenmemişti, 675 kimliğin **281'i yayından
düşmüştü** ama ücretsiz testte gösteriliyordu. Tarayıcı provası (yerel, dış kayıt uçları kapalı): 30 soru, 30 sunucu kontrolü, sonuç ekranı doğru.

**Takvim (Cem "1.2.3" öneri 3 — "sonra" yok, tarih var):**
| Tarih | İş | Şart |
|---|---|---|
| Cem uygun olduğunda (ASAP) | **Adım 0**: kurucu hesabıyla `kaydir/sgs/turkce.html` + `kaydir/smmm/hukuk.html` açılır, ağ istekleri ölçülür | — |
| 30.09–03.10 | Okuyucu onarımı: `arac/havuz-kur.ps1` bekletme, `arac/sgs-konu-kapsama.js` (sınav/SGS kolu), `arac/sik-kaydir.ps1`, `motor/soru-dizini.js`, `motor/site-nobeti.ps1` 300 KB | Adım 0 YEŞİL |
| **05.10 sabah** (SGS canlı deneme 04.10 bittikten sonra) | 16 SGS sayfası `kasa-modu.json`'a · deneme setleri yalnız kimlik · `_arsiv`/örnek dosyalar depo dışına · içerik nöbeti tabanı BOŞ | okuyucu onarımı bitti |
| **07.10 akşam** | Git geçmişi temizliği (izole çıplak klon, `gecmis-temizligi` reçetesi) | 05.10 sonrası ≥1 gün sorunsuz + Cem'e "şimdi basıyorum" sorusu |

### 7.1 29.09 akşam — Cem ikinci "1.2.3"
- **05.10 geçişi ONAYLANDI.** Zamanlanmış görev `adim2-sgs-kasa-gecisi-0510` (05.10 09:00, Claude uygulaması açıkken):
  ön koşulları ölçer, kuru prova yapar, **itmeden önce Cem'e sorar**.
- **Okuyucu onarımı YAPILDI** (takvimde 30.09–03.10'du): `arac/havuz-kur.ps1` bekletme kabukta seçim dosyasından
  (Türkçe: seçim 169 = kasa 169 = ortak 169) · `arac/sik-kaydir.ps1` kabukta kasadan kimlik + doğru harf (ÖLÇÜLMEDİ: bekletme
  listesi boş, yol koşmadı; ayrıştırma + tuzak nöbetçisi temiz) · `motor/soru-dizini.js` kabukta seçim dosyası (kuru: SGS 15 ders,
  4.912) · `motor/site-nobeti.ps1` ders sayfası eşiği 300 KB → 50 KB (Türkçe kabuk canlı 161 KB, imza "Nöbetçi" var).
  `arac/sgs-konu-kapsama.js` zaten seçim dosyasına düşüyor (SGS oturumu teyit) — dokunulmadı; `yayin-sgs-*.json` SİLİNMEZ.
- **E-posta onayı ölçüldü:** `auth/v1/settings` → `mailer_autoconfirm: true` (onay KAPALI, 23.09'dan beri). Paket erişimi
  `auth.uid() = user_id` ile (RLS, e-posta değil) → oturum açan başkasının paketini okuyamaz. **Açık kalan tek yol:** havale
  sonrası elle paket açma (`veri/sql-siparis.sql` iş akışı madde 3) sipariş e-postasıyla hesabı eşlerse, alıcıdan ÖNCE onun
  e-postasıyla üye olan biri paketi alır. Çare: 04.10 canlı denemeden sonra onay yeniden AÇILIR (Cem, Supabase → Auth →
  Email → Confirm email) — o güne kadar elle açmada hesap sipariş e-postasıyla eşleşiyorsa aç, ama alıcıya "paketin şu e-postalı
  hesaba açıldı" iletisi gider. Mağaza içi satın alma (`magaza-dogrula`) hesabın kendi oturumuyla yazdığı için etkilenmez.
- **Adım 0 sonucu:** _(Cem denemeyi yapınca buraya yazılır: tarih · turkce.html soru geldi mi · smmm/hukuk.html soru geldi mi)_