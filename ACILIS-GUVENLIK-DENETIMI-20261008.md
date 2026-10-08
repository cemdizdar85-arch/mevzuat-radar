# AÇILIŞ ÖNCESİ TAM DENETİM — 08.10.2026

> Cem: "site açılışı öncesi yapmadığımız güvenlik kontrolü yok de; ... baştan tek tek en ince ayrıntıya kadar."
> Altı bağımsız denetim (ücretli soru sızıntısı · üye verisi izolasyonu · silinme/ele geçirme · uygulama katmanı/XSS/bot ·
> yük/kapasite · kalan her şey), hepsi salt okuma + canlı ölçüm (anon anahtar, yazma yok). Kod: origin/main d8122aa0.
> Kural: ölçülmeyene "güvenli" denmez; her satırda kanıt ya da "ölçülmedi".
> Yan etki: form ucu `{}` gövdeyle yoklanırken 1 boş "Site formu" kaydı + Cem'e 1 boş mail gitti (bulgu B8).

## 0 · Bugün YAPILAN düzeltmeler (canlıda doğrulandı, 0 USD)

| Ne | Önce | Sonra |
|---|---|---|
| `soru_havuzu_arsiv_v1` görünümü | anon GET 206 (30.569) · PATCH/DELETE 204 — tek istekle silinebilirdi | 401 (`2026-10-08-gorunum-yazma-kapat.sql`, tüm görünümlerde anon yazma kapalı) |
| `net-cevap?tani=1` | ücretli YZ çağrısı hız sınırından ÖNCE | sınırın arkasında (imza a80d670972927e54) |
| `siparis-bildirim` 'alindi' maili | sınırsız; sahte siparişle mail yağdırılabilirdi | alıcı 3/24 sa + IP 5/10 dk (imza 6b41edbdd24f4ba5) |
| Gizli sayfalar + arama motoru | 37 gizli sayfada noindex yok; açılış robots'u yalnız `Allow: /` | 37 sayfaya noindex; `arac/robots-yaz.ps1` tek kaynak (iç klasörler, *.md, GIZLI sayfalar Disallow; öz-sınav + mutasyon 5/5) |
| 404 "Fiyatlar" → satin-al | | → fiyat.html |
| fiyat.html rakip adı yorumu, "Türkiye'nin tek" | | silindi |
| Onay maili şablonu (Supabase Confirm signup) | İngilizce varsayılan | Türkçe kurumsal şablon panelde kayıtlı (`radar-app/auth-mail/confirmation.html`) |
| site-nöbeti fiyat imzası | 'Kurucu fiyatı' → 3/3 yanlış kırmızı + her koşuda alarm maili | 'Açılış fiyatı' |
| Açılış listesi | yalnız gong | 3.1 `acilis-seo -Ac` eklendi (noindex kalkar) |

## 1 · AÇILIŞI DURDURUR — yarından önce

| # | Bulgu | Kanıt | Düzeltme | Kim |
|---|---|---|---|---|
| 1.1 | **Kart ödemesi canlıda AÇIK ama hiç doğrulanmadı.** `KART_ACIK=true`, iyzico canlı uç; 08.10 08:03 commit notu: 5 TL denemesi "9000 işleminizi gerçekleştiremiyoruz" döndü; sonucu hiçbir yerde yok | `fiyat-motoru.js:239`, `iyzico-odeme.ts:21,116-118` | 5 TL deneme (liste 0.1–0.4) → tutuyorsa yaz; tutmuyorsa `KART_ACIK=false` (metinler kendiliğinden havaleye döner) | **Cem** (kart) + Claude |
| 1.2 | **GitHub hesabı tek anahtar.** Tek yazar; `main` korumasız (force push/silme serbest); 20 secret içinde `SUPABASE_DB_URL` (postgres, tam yetki): depoya .sql itmek = veritabanını silmek. 2FA ölçülemedi. Bu makinede git kimliği düz metin (`credential.helper=store`) | `gh api .../branches/main/protection` 404; `.../collaborators` 1; secrets 20 | (a) GitHub 2FA; (b) Settings → Rules → Rulesets → main: *Restrict deletions* + *Block force pushes* (PR şartı EKLEME, robotlar kırılır); (c) `SUPABASE_DB_URL`/`ACCESS_TOKEN` → onaylı *Environment* (Cem kararı: otomasyon mu kapı mı); (d) makinede `credential.helper manager` | **Cem** 15 dk |
| 1.3 | **Alan adı GitHub'da doğrulanmamış** → Pages kapanırsa/depo silinirse `tetikte.com` başka bir hesabın sitesini gösterebilir | `pages.protected_domain_state: null`; `_github-pages-challenge-…` TXT yok | GitHub hesap Settings → Pages → Add domain `tetikte.com` + `www` → TXT'yi Turhost DNS'e → Verify | **Cem** 5 dk |
| 1.4 | **Mail kotası günde 100** (Resend Free; 29/100, ay 714/3.000). Onay, şifre, sipariş, karne, alarm aynı kotadan; kota dolunca sipariş maili düşer, yeniden deneme yok | Resend panel 08.10 | Resend Pro (~20 USD/ay) → sonra 1.5 | **Cem** |
| 1.5 | **E-posta onayı kapalı** → ödenmiş paket o e-postayla İLK hesap açana geçer; Google girişinde hesap ele geçirme | `/auth/v1/settings mailer_autoconfirm:true`; `2026-10-05-otomatik-paket.sql:46-60` | 1.4 sonrası: Rate limit 30→200 + Confirm email AÇ (şablon hazır) → dış ölçüm | Cem panel + Claude ölçüm |
| 1.6 | Perde `menu.js`'te duruyor (normal) — gong + `acilis-seo -Ac` sırası listede | `ACILIS-GUNU-LISTESI.md` 3.1–3.3 | Cem "AÇ" deyince iki komut | Claude |

## 2 · AÇILIŞTAN SONRAKİ İLK GÜNLER (17.10 denemeden ÖNCE)

| # | Bulgu | Kanıt | Düzeltme | Kim |
|---|---|---|---|---|
| 2.1 | **Depo geçmişinde ücretli sorular cevaplı.** `raw.githubusercontent.com/.../b0177366/kaydir/sgs/vergi-hukuku.html` 200, 430 soru + doğru + açıklama; 10 deneme seti 130'ar cevap; seviye havuzu 675 cevap. Canlı sitede ve veritabanında sızıntı YOK (ölçüldü) | `ADIM2-PAKET-KASASI-PLANI.md` 8. adım yapılmamış | Geçmiş temizliği (çıplak klon, blob silme, `--force-with-lease`) + GitHub Support önbellek; robotlar durdurulup tek pencerede; **1.2(b) ruleset'ten ÖNCE ya da bypass ile** | Claude hazırlar, **Cem "bas" der** |
| 2.2 | Deponun TAMAMI tetikte.com'da yayında (`/CLAUDE.md`, `/motor/*.ps1`, SQL → 200) | `gh api .../pages build_type legacy, path /` | Pages → Source: GitHub Actions + `site-yayin.yml` (hazır, eşdeğerlik 490/490). Açılış GÜNÜ değil, ertesi gün | oturum "yalnız site dosyalarını yayınla" + Cem tık |
| 2.3 | **17.10 anahtar yayını** zamanlanmış Claude görevi: hiç prova edilmedi, Cem'in bilgisayarının açık olmasına bağlı; gelmezse bütün salon bekler | görev `sgs-1010-anahtar-yayini` lastRunAt yok | Kuru prova (sahte oturum kodu) + GitHub Actions cron yedeği | Claude |
| 2.4 | `canli_sonuc.cevaplar` SQL'i basılmamış → her sonuç 2× POST | `UYGULANDI.md` "BEKLİYOR" | Yeni tarihli dosyayla göç (otomatik) | Claude |
| 2.5 | `kurulus_nobet` anon yazma + postacı robot = Tetikte adından başkasına oltalama maili; `marka_talep` mail HTML kaçışsız | `2026-09-08-kurulus-nobet.sql:37`, `kurulus-nobet-postacisi.ps1:56`, `marka-portfoy-hasat.ps1:790-815` | Ürünler gizli: robotları durdur ya da anon insert kaldır + çift onay + HtmlEncode | Claude |
| 2.6 | Anon yazılabilir tablolarda uzunluk/biçim CHECK yok (`cevap_kayit.secim`, `kagit_kayit.metin`, `soru_bildirim.not_metni`, `canli_sonuc`); spend cap KAPALI → şişirme faturaya | SQL dosyaları | CHECK'ler + hız sınırlı RPC; `soru_bildirim` robot eşiği 1 (satılan kasayı etkilemiyor — kasa yayını `yayin` kolonunu okumuyor, grep 0) | Claude |
| 2.7 | `rate_limit_check` anon'a açık, IP'yi çağıran seçer; `rate_log` RLS yok (200 */0) | `2026-07-17-rate-limit.sql` | Edge'ler servis anahtarıyla çağırsın → anon EXECUTE kaldır + RLS. ⚠ sırayla: önce edge, sonra SQL (ters sıra = tüm uçlar 429) | Claude |
| 2.8 | Storage `fisler`: anon tüm kovayı listeleyebilir/indirebilir, anon yükleyebilir (kova boş görünüyor) · `destek_uyari` okuma e-posta eşleşmeli · `ekibe_soru.eposta` serbest · `marka_takip_ac` mevcut jetonu döndürüyor | sql dosyaları | politikaları düşür / user_id'ye geç | Claude |
| 2.9 | Günlük soru çözme yükü: ders sayfası açılışında dersin TAMAMI iner (2–15 MB), önbellek yok, `paket_soru.sayfa` indekssiz → birkaç yüz eşzamanlı paketli üyede yavaşlama; 1.000'de ~720 GB/ay (+~68 USD). 17.10 canlı deneme yolu bundan bağımsız, 1.008 tarayıcıyla ölçülmüş: rahat | `kasa-yukle.js`, `2026-09-16-paket-soru.sql:32` | `sayfa` indeksi + sayfalı yükleme + IndexedDB önbelleği | Claude |
| 2.10 | Yasal: `teslimat-iade.html` satıcı kimliği yok; `mesafeli-satis.html` telefon/tarih yok; görünür hiçbir sayfada "TÜRMOB/TESMER/ÖSYM ile bağı yoktur" yok; "e-arşiv faturan gönderilir" sözü var, fatura süreci yazılı değil | grep | metin ekleri (Claude) · fatura süreci (Cem: kim, hangi gün, hangi portal) | Claude + Cem |
| 2.11 | Captcha kapalı: sahte hesap, `/recover` ile başkasına şifre maili yağdırma (Supabase saat tavanı dolunca gerçek kullanıcı mail alamaz) | `/auth/v1/recover {}` validasyon döndü | Turnstile panel (önce mobil derleme) | Cem |

## 3 · İLK HAFTA

- Veritabanı yedeği: günlük şifreli yedek + B2 kilitli kova ✅ (08.10 koşusu TAM); eksik: `auth.users` şifre özetleri (Yol B), Storage, PITR (ölçülmedi, bedel sor). Yedek özel anahtarı şifresiz PEM, çevrimdışı kopya yok → parolalı USB.
- Depo aynası yok → `git bundle` → B2 ya da ikinci barındırıcı (ayrı 2FA).
- DNS: DMARC `p=quarantine` → `reject`; CAA yok; DNSSEC yok; Turhost 2FA/otomatik yenileme ölçülmedi (bitiş 22.07.2027).
- Actions: `allowed_actions: all`, SHA sabitleme yok (etiketle 194 action); fork PR ile sır çalma yolu YOK (pull_request_target 0).
- Silen robot betikleri (5) için "oran > %20 ya da filtre boş → DUR" kapısı.
- `dogrula.yml` 16 iş kalıcı kırmızı (gürültü); dış uptime monitörü yok (site-nöbeti cron 15 dk yazıyor, GitHub ~6 saatte koşturuyor).
- `nobetci-sor` günlük 10 sayaç yarış durumuyla aşılır; LLM uçlarına gövde/USD tavanı; CSP `unsafe-inline`; SRI yok (2 gizli sayfa).
- Hesap silme: form/abonelik e-posta kayıtları (`soru_bildirim`, `kurulus_nobet`, `form_kayit`, `destek_uyari`) silinmiyor; KVKK metni "verilerinizi silmek" diyor.
- `kaydir/vitrin/smmm.html` 1 soru ücretsiz kümede değil ama cevaplı gömülü → vitrin basımına "⊆ ucretsiz_soru" kapısı.
- Canlı deneme anahtarı sınav saatinde herkese açık → 130 ücretli soru üye olmayana da iner (bilinçli karar mı? Cem).
- Anthropic bakiye (15.09: 145 USD, auto-reload KAPALI) bugün ölçülmedi.

## 4 · SAĞLAM BULUNANLAR (ölçüldü)

- **Ücretli soru:** `paket_soru` anon 401; paketsiz üye politika metninden 0 satır; `ucretsiz_soru` 774 satırın tamamı indirildi: doğru/açıklama/tuzak alanı 0; `seviye_kontrol`/`seviye_aciklama` paketli id'ye boş döner; 29 ders kabuğunda gömülü soru 0; `.enc.json` AES-256, anahtar depo dışı; tarayıcı kapıları aşılsa da sunucu vermiyor.
- **Üye verisi:** kişi verisi taşıyan tüm tablolarda politika `auth.uid()`'e bağlı ya da revoke (siparisler 401, ogrenci_* 401, nobetci/ekibe 401); `yonetici_mi()` user_id ile; tüm `yonetim_*` anon 401; `canli_sonuc`'ta ad/e-posta yok, liderlik tablosu yok; `hesabimi_sil` yalnız kendi hesabı.
- **XSS:** saldırganın yazabildiği hiçbir alan kaçışsız DOM'a basılmıyor (yönetim paneli dahil, satır satır); URL parametreleri süzgeçli; postMessage origin kontrollü.
- **Ödeme:** kart verisi iyzico sayfasında; tutar sunucuda yeniden hesaplanıyor (`iyzico-odeme.ts:172-179`); sipariş durumu kullanıcıca değiştirilemez; iyzico dönüşü `detail` API'den doğrulanıyor; fiyatlar 7 yerde birebir (KDV %20, "+KDV" yanında dahil toplam).
- **Sır:** git geçmişinin tamamı (36.602 metin blob, 14 desen) → 0 sır; GitHub secret scanning + push protection açık; eski JWT anon anahtar depoya hiç girmemiş.
- **Yük (canlı deneme yolu):** 1.008 gerçek tarayıcı 24.09: kayıt 1.008/1.008, sonuç 986/986, 5xx 0; bugün 20 paralel p50 0,30 s.
- Mail DNS: SPF `-all`, DKIM, DMARC quarantine; http→https, www→apex; service worker yok (gong sonrası eski perde kalıcı olmaz); robotların hiçbiri menu.js yazmıyor.

## 5 · ÖLÇÜLEMEYENLER
Giriş yapmış paketsiz üye ile canlı ölçüm (hesap açmak yasak; politika metninden çıkarıldı) · GitHub/Supabase/Turhost 2FA · Supabase PITR · Google kimlik bağlama davranışı · `x-forwarded-for` sahteliği · 5 TL kart denemesi sonucu · Anthropic bakiye · mobil taşma 14 sayfa listesi · canlı deneme görev listesi.
