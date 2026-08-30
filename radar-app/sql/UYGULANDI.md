# GÖÇ KÜTÜĞÜ — hangi SQL Supabase'de basılı?

**Kuruluş sebebi (29.08.2026, Cem "1.2 yap"):** 28.08'de `alacak-radari.html`
kasadan `secilenGun` / `turIlk` / `turGun` okuyordu ama o alanları üreten göç
basılmamıştı. Sayfa çökmedi — **sustu**. Kapsam şerhi hiç görünmedi. Kusuru
bulmanın tek yolu canlı uca istek atmaktı; klasöre bakarak anlaşılmıyordu,
çünkü **dosyanın depoda durması basıldığı anlamına gelmiyor.**

Üstüne: `alacak_vitrin` fonksiyonunu **beş ayrı dosya** yeniden yazıyor ve dosya
adından hangisinin geçerli olduğu anlaşılmıyor. 22:04'te yazılan bir göç,
21 dakika sonra yazılanın alanlarını siliyor. Yanlış sırayla basmak canlı
sayfadan alan düşürür.

Bu kütük o iki soruyu cevaplar: **hangisi geçerli** ve **basılı mı**.

## Kurallar

1. **Aynı fonksiyonu yeniden yazan göç, eskittiği dosyayı adıyla yazar.**
   Aşağıdaki "Eskitir" sütunu boş kalmaz.
2. **Basılı mı sorusuna yalnız ÖLÇÜMLE cevap verilir.** Ölçülmemiş hücreye
   "basılı" yazılmaz — `ÖLÇÜLMEDİ` yazılır ve ölçüm komutu yanına konur.
   (Bkz. `olcemedigine-kusur-deme` kuralı.)
3. **Yeni göç yazan, aynı commit'te bu kütüğe satırını ekler.**
4. Sayfaların okuduğu alanlar `goc-manifesto.json`'a yazılır; `motor/goc-nobetcisi.ps1`
   her gün canlı uçtan doğrular (CI: `.github/workflows/goc-nobeti.yml`).

## Ölçüm nasıl yapılır

Tarayıcı konsolundan ya da `curl` ile — **servis anahtarı gerekmez**, sayfaların
zaten taşıdığı açık anahtar yeter:

```bash
curl -s -X POST 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/alacak_vitrin' -H 'apikey: sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' -H 'Content-Type: application/json' -d '{}'
```

Okuma sözlüğü: `PGRST202` = **fonksiyon kasada yok** (göç basılmamış) ·
`PGRST205` = tablo yok · `401/42501` = var ama dışarı kapalı (gizli kasa) ·
`200` = var. Tabloda `200` tek başına "herkese açık" **demek değildir**: RLS
varken satır dönmeden de 200 gelir — satır sayısına bakılır.

---

## alacak_vitrin zinciri (BEŞ dosya, sırası önemli)

| # | Dosya | Ne ekler | Eskitir | Durum |
|---|---|---|---|---|
| 1 | `2026-08-19-alacak-gizli-arsiv.sql` | Fonksiyonun ilk hâli + `alacak_ara` + maskeleme | — | ✅ BASILI (ölçüldü 29.08: `alacak_ara` 200) |
| 2 | `2026-08-20-alacak-karar-durumu.sql` | `durumlar` sayaçları | #1 | ✅ BASILI (`durumlar` geliyor) |
| 3 | `2026-08-27-alacak-vitrin-tur-suzgeci.sql` | `p_tur`, tür sayaçları, bayatlık | #2 | ⬆️ **ESKİDİ** — #5 kapsıyor |
| 4 | `2026-08-28-alacak-makro-suzgec.sql` | `iller` bloğu süzgece duyarlı, `illerSuzgecli` | #3 | ⬆️ **ESKİDİ** — #5 kapsıyor |
| 5 | **`2026-08-28-alacak-kapsam-serhi.sql`** | `secilenIlk/Son/Gun`, `turIlk`, `turGun` | #4 | ✅ **GEÇERLİ SÜRÜM, BASILI** (ölçüldü 29.08) |

> ⚠️ #4 (22:04) ile #5 (22:25) **birikimli değil**: #4, #5'in kapsam alanlarını
> içermez. #5'ten sonra #4 basılırsa `secilenGun` ve `turIlk` **kaybolur** ve
> sayfanın kapsam şerhi yeniden susar. Sıra bozulursa yalnız #5 tekrar basılır.

**29.08 ölçümü:** `alacak_vitrin` 17 anahtar döndürüyor — `adet · son30 ·
son30Konkordato · son30Iflas · enYeniTarih · enYeniIso · turSayilari · durumlar ·
secilenAdet · secilenIlk · secilenSon · secilenGun · turIlk · turGun ·
illerSuzgecli · iller · ilanlar`. Arşiv 5.917 ilan; konkordato 5.435 / iflas 415.

**Bulgu — ölü alan:** `son30Konkordato` ve `son30Iflas` kasadan geliyor ama
**hiçbir sayfa okumuyor** (ölçüldü: depoda 0 geçiş). Zarar vermiyor; bir sonraki
`alacak_vitrin` göçünde çıkarılabilir.

## Alacak — karar durumu göçleri

| Dosya | Ne yapar | Durum |
|---|---|---|
| `2026-08-28-alacak-ret-iflas-durumu.sql` | "Konkordato reddi → İFLAS" ayrı durum | ✅ BASILI (`durumlar.ret_iflas` = 65) |
| `2026-08-28-alacak-ret-iflas-onarim.sql` | Önceki göçün damga onarımı | ✅ BASILI **ve ölçüldü** (29.08 canlı: `ret_iflas` 65 · `ret_kaldirma` 650 · toplam 715 korunmuş · 60 ilanlık örnekte kirli kayıt 0) |
| ~~`2026-08-29-alacak-ret-iflas-metinden.sql`~~ | `ret_iflas` damgasını başlıktan metne taşıyacaktı | 🚫 **GEÇERSİZ — BASMA.** Deseni kirli: *"iflasına karar **verilmesine yer olmadığına**"* gibi TERS anlamlı cümleleri yakalıyor, `292` tek başına çok geniş. Ölçüldü: bu desen **169** aday buluyor, düzeltilmiş desen aynı veride **46** → **123 yanlış pozitif**. Dosya kusur kaydı olarak duruyor |
| `motor/alacak-damga-olcum.ps1` (SQL değil, betik) | Aynı işi **bağlam kontrollü** yapar: kesin kalıp + eşleşmenin ±90 karakter komşuluğunda olumsuzlama araması. Tek SQL regex'ine sığmadığı için damgalama da buradan yapılır | 📏 ÖLÇTÜ (run 33235435953): çıkacak **38/63** (Bursa 17) · girecek **46/633** (İstanbul 13 · Ankara 11 · Konya 10) · beklenen `ret_iflas` = **71** |
| `2026-08-28-alacak-iflas-kaldirma-durumu.sql` | İİK m.182 "İflas kaldırıldı" ayrı durum | ✅ BASILI (`durumlar.iflas_kaldirma` = 6) |
| `2026-08-20-alacak-metin-alanlari.sql` | İlan metni + yapılandırılmış alanlar | ✅ BASILI (vitrin `borclu · vkn · karar · muhletBitis` alanlarını döndürüyor) |
| `2026-08-20-alacak-toplu-alanlar.sql` | Toplu taramadan ayrıştırılan alanlar | ✅ BASILI (aynı ölçüm) |

> Not: alanlar **var** ama ilk kayıtta `borclu`, `vkn`, `muhletBitis` **boş**
> geliyor. Bu göç değil **veri** sorunudur (ayrıştırma o ilanda tutmamış) —
> ayrı iş; göç kütüğünün konusu değil, buraya kayıt olarak düşüldü.

## Diğer canlı uçlar

| Dosya / şema | Uç | Durum (29.08 ölçümü) |
|---|---|---|
| `2026-08-27-teslim-teyidi.sql` | `uyari_teyit_durum` | ✅ BASILI — sıfır jetonda `{"ok":false,"sebep":"BULUNAMADI"}` |
| `2026-08-20-ihale-gizli-arsiv.sql` | `ihale_sayi`, `ihale_dokum` | ⬆️ **ESKİDİ** — `2026-08-30-ihale-bulten-kutugu.sql` görünümü + `ihale_yaz`/`ihale_dokum`/`ihale_sayi`'yı yeniden yazar. Tablo/kasa kuralları aynen korunur. |
| `2026-08-30-ihale-bulten-kutugu.sql` | `ihale_kutuk`, `ihale_kutuk_yaz`, `ihale_eksik_gun`, `ihale_kutuk_denetim`, `ihale_sayi` (v2) | ✅ **BASILDI** (30.08 canlıda ölçüldü: `ihale_sayi()` `damgasiz` sütununu döndürüyor, değer 23.415. Dosya "basılmamış" diyordu — yanlıştı, 30.08 düzeltildi). Eskitir: `2026-08-20-ihale-gizli-arsiv.sql`. **Ölçüm komutu:** `./motor/ihale-kapsama-raporu.ps1` → "damgasız alanı yok" derse basılmamıştır. Basılmadan `motor/ihale-supabase-yukle.ps1` **kendini durdurur** (göç kapısı) — bilerek: damgasız yutulan kayıt hangi bültenden geldiğini söylemez, 36 aylık yutma baştan tekrar edilir. |
| `veri/sql-marka-portfoy.sql` | `marka_talep_sonuc` | ✅ BASILI — 200 |
| `evrak-app/schema.sql` | `istek_getir` | ✅ BASILI — 200 (`p_token` ile) |
| `veri/sql-destek-takip.sql` | `destek_takip` tablosu | ✅ BASILI — tablo var, anon'a 0 satır (RLS tutuyor) |
| `2026-08-07-canli-deneme.sql` | `canli_sonuc` tablosu | ✅ BASILI — tablo var, anon'a 0 satır |
| `veri/sql-soru-bildirim.sql` | `soru_bildirim` tablosu | ✅ BASILI — tablo var, anon'a 0 satır |
| `veri/sql-marka-uyari.sql` | `marka_uyari` tablosu | ✅ BASILI — tablo var, anon'a 0 satır |
| `veri/sql-marka-rakip.sql` | `marka_rakip` tablosu | ✅ BASILI — 29.08 ölçüldü: tablo var, anon'a 0 satır (RLS tutuyor) |
| `veri/sql-marka-durum.sql` | `marka_durum` tablosu | ✅ BASILI — 29.08 ölçüldü: tablo var, anon'a 0 satır |
| `veri/sql-marka-kaynak.sql` | `marka_talep_ac(p_unvan,p_email,**p_kaynak**)` | ✅ **BASILI — 30.08.2026 Cem bastı, canlı uçtan ölçüldü.** 3 parametreli çağrı fonksiyonun GÖVDESİNE ulaşıyor (`P0001 "Unvan 3-160 karakter olmali"`), yani imza kasada var; 29.08'deki `PGRST202` gitti. 2 parametreli çağrı da **belirsizlik hatası vermeden** aynı gövdeye düşüyor → eski imza düşmüş, tek imza kalmış (varsayılan parametreler çalışıyor). Ölçüm zararsız: unvan kısa verildi, kayıt açılmadı. **Bu satır ölüyken Instagram/kampanya kaynak etiketi (`?k=`) hiçbir yere yazılmıyordu — reklam ölçümünün ayağı artık canlı.** Son hücre de ölçüldü: `marka_talep.kaynak` kolonu VAR (30.08, panel) — yani fonksiyon `insert` satırına ulaştığında yazacağı yer mevcut. |
| `veri/sql-karne.sql` | `karne` tablosu | ❌ **TABLO YOK** (`PGRST205`) — basılmamış ya da adı farklı |
| `veri/sql-siparis.sql` | `siparisler` tablosu | ✅ **BASILI — 30.08.2026 Cem bastı, panelden ölçüldü.** 18 kolonun 18'i yerinde (eksik-kolon sorgusu 0 satır), tabloda 0 satır. ⚠️ **DERS: 29.08'de bu satır "TABLO YOK" diyordu ve dosya `create table if not exists` ile başlıyordu — tablo o sırada BAŞKA BİR YERDEN kurulmuş olsaydı yeni kolonlar SESSİZCE eklenmeyecekti.** Basmadan önce `information_schema.columns` sorgusu çalıştırıldı, tablonun zaten var olduğu görüldü ve `create` yerine **ALTER'lı sürüm** basıldı. Kural: *"basılı mı"yı ölçmeden `create table if not exists` basma — çalışır görünüp eksik şema bırakır.* Politika da yenilendi: yeni dört kolon (`liste_fiyat`, `dersler`, `secilen_dersler`, `davet_kodu`) biçim kilidine dahil; dışarıdan gelen sipariş zorunlu `odeme_bekliyor` doğuyor. |
| `veri/sql-davet-kodu.sql` | `paket_uyeler` +4 kolon · `davet_kullanim` tablosu · `davet_kodu_uret()` `davet_kodu_ata()` `davet_uygula()` | ✅ **BASILI — 30.08.2026 Cem bastı, panelden ölçüldü.** yeni_kolon 4/4 · kutuk_tablosu 1 · fonksiyon 3/3 · örnek kod `TTY7JJ` (biçim doğru) · mevcut 1 üyenin kodu üretilmiş. **Neden kuruldu:** `fiyat.html` 02.08'den beri "3 davet kodu veriyoruz" diyordu, depoda `davet_kod` diye bir şey YOKTU — arkasında kod olmayan yazılı söz. `davet_uygula()` yetkisi anon+authenticated'tan **alındı**: yalnız service_role çağırır, yoksa üye kendi kodunu ikinci hesabına yazardı. |
| `veri/sql-guvenlik-kapisi.sql` | `leadler` anon yazma izni | ✅ **BASILI — 30.08.2026 Cem bastı, canlı uçtan ölçüldü.** `POST leadler {}` → **`401 / 42501 "permission denied for table leadler"`**. 29.08'de aynı istek `23502` dönüyordu: RLS yazmayı hiç engellemiyordu, yalnız NOT NULL durduruyordu — yani anonim biri sınırsız satır basabilirdi. Açık kapandı. Maliyeti sıfırdı: `leadler`'e yazan site kodu yok, formlar web3forms'a gidiyor. |
| `2026-07-17-rate-limit.sql` | `rate_log` tablosu + `rate_limit_check()` | ✅ **BASILI** — 29.08 ölçüldü: tablo 200/`[]`, RPC `true` döndü. ⚠️ Kütükteki eski satır `rate_limit` adlı bir tablo arıyordu ve "merkezî istek sınırı yok" diyordu — **yanlıştı**: SQL `rate_log` kuruyor, o da yerinde. Hız sınırı altyapısı **hazır ve anon'a açık**; kullananlar `radar-app/edge/net-cevap.ts` + `beyanname-oku.ts`. NOT: IP'yi çağıran taraf verdiği için tarayıcıdan gelen doğrudan çağrılarda güvenilmez — gerçek koruma Edge Function ya da captcha ister. |

## madde_ara zinciri (Net Cevap aramasının kalbi)

Sekiz sürüm, hepsi aynı fonksiyonu yeniden yazıyor. **Geçerli sürüm: v8.**

`v2 (16.07) → v3 (16.07) → v4 (16.07) → v5 (17.07) → v5-tur-agirligi (30.07) →
v6 (19.08) → v7 (23.08) → v8 (25.08)`

| Dosya | Durum |
|---|---|
| `2026-08-25-madde-ara-v8.sql` | ⚠️ **ŞÜPHELİ** — fonksiyon var ama v8'in çözmek için yazıldığı 57014 timeout'u **hâlâ oluyor** |

**29.08 ölçümü (canlı):**

| Sorgu | Süre | Sonuç |
|---|---|---|
| `konkordato` (1 sonuç) | 3.261 ms | ❌ 500 · `57014` statement timeout |
| `reeskont` (3 sonuç) | 3.316 ms | ❌ 500 · `57014` |
| `amortisman oranlari` (6 sonuç) | 2.363 ms | ✅ 200 |

Yani **tek kelimelik sorgular cevapsız kalıyor** — kullanıcıların en çok yazdığı
biçim bu. v8 dosyasının başlığı birebir bu kusuru anlatıyor ("57014 TIMEOUT'UN
KÖKÜ"). İki ihtimalden hangisi olduğu **ölçülmedi**: (a) v8 hiç basılmadı,
(b) basıldı ama yetmedi. Ayırt etmek için Supabase'de:

```sql
select prosrc from pg_proc where proname = 'madde_ara';
```

Çıkan gövde v8 dosyasıyla karşılaştırılır. Bu, `net-cevap-motoru` hafızasındaki
"madde_ara 500" açığının kök ölçümüdür.

## Ölçülmedi (servis anahtarı ya da oturum ister)

Aşağıdakiler tablo/fonksiyon ucu üzerinden dışarıdan görünmüyor. "Basılı değil"
**denmiyor** — ölçülmedi deniyor.

`2026-07-16-dedupe-ve-madde-ara-v2` (çift kayıt temizliği) ·
`2026-07-16-genel-dedupe-ve-madde-ara-v4` · `2026-07-17-fisler-bucket-private-kvkk`
(kova özel mi — Storage ucu ayrı ölçüm) · `2026-07-23-soru-havuzu` (kilitli havuz) ·
`2026-07-24-hayalet` · `2026-07-24-tablo` (exhibit) · `2026-07-27-paket-ayrimi` ·
`2026-08-07-soru-nitelik` · `2026-08-25-konu-semasi` · `veri/sql-cila-v3-kolonlar` ·
`veri/sql-destek-takip-panel` · `veri/sql-yayin-kapisi` · `sql-yerel/2026-07-30-gm-onay-tasima`

> 29.08: `veri/sql-marka-durum`, `veri/sql-marka-kaynak` ve `veri/sql-marka-rakip`
> bu listeden ÇIKTI — üçü de dışarıdan ölçülebildi, sonuçları yukarıdaki tabloda.

Ölçüm reçetesi (servis anahtarıyla, Supabase SQL Editor):

```sql
select column_name from information_schema.columns where table_name = '<tablo>';
select proname from pg_proc where proname = '<fonksiyon>';
```

## Göç dosyaları nerede duruyor (üç ayrı yer)

Bu da kütüğün kurulma sebeplerinden: göçler tek klasörde değil.

- `radar-app/sql/*.sql` — 29 dosya (radar + alacak + arama + teslim teyidi)
- `veri/sql-*.sql` — 12 dosya (marka, destek, karne, sipariş, bildirim, cila)
- `radar-app/schema.sql` · `evrak-app/schema.sql` — kuruluş şemaları
- `sql-yerel/*.sql` — yerel/tek seferlik

## Açık not — `dokumanlar` herkese okunabilir

`radar-app/schema.sql:53`'te bilinçli konmuş bir politika var:
`create policy "dokuman_public_read" on public.dokumanlar for select using (true)`
— gerekçesi "kamu mevzuatı". **29.08 ölçümü: anon anahtarla 39.237 satırın
tamamı sayfalanarak indirilebiliyor.**

İçerik kamuya açık mevzuat, yani sızan bir sır değil; ama **ayıklanmış,
parçalanmış, temizlenmiş hâli** ambarın kendisidir ve tek istekle toplu
çekilebilir. Ayrıca hiçbir sayfa bu tabloyu doğrudan okumuyor (ölçüldü: depoda
0 çağrı) — hepsi `madde_ara` üzerinden geçiyor.

⚠️ **Kapatmadan önce:** `madde_ara` `security definer` **değil** (`language sql
stable`), yani çağıranın yetkisiyle çalışıyor. Üstelik Net Cevap motoru da
servis anahtarı kullanmıyor: `radar-app/edge/net-cevap.ts:28` açık anahtarla
çağırıyor ve satırın kendi yorumu "dokumanlar public-read" diyor. Yani politika
bugün **yük taşıyor** — kaldırılırsa hem anon arama hem Net Cevap ölür.

Doğru sıra: (1) `madde_ara`'yı `security definer` yap, (2) canlıda aramanın
çalıştığını ölç, (3) `dokuman_public_read` politikasını daralt, (4) tekrar ölç.
Karar Cem'de.
