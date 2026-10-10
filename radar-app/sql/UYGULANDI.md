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
| 5 | `2026-08-28-alacak-kapsam-serhi.sql` | `secilenIlk/Son/Gun`, `turIlk`, `turGun` | #4 | ✅ BASILI (ölçüldü 29.08) — #6 kapsıyor |
| 6 | **`2026-09-04-alacak-arsiv-derinligi.sql`** | Sayaçlar 365 gün süzgecinden çıkar, ARŞİVİN TAMAMINI sayar; `arsivIlk/Son/Gun`, `tarihsiz`, `arsivDerinligi:true` | #5 | ⏳ **BASILMADI — Cem basacak.** Basılana kadar sayfa "son 1 yıl" cümlesiyle çalışır (bayrak gelmeyince eski cümle kalır, yanlış hüküm yok) |

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
| `2026-09-07-alacak-bos-dizi-onarimi.sql` | **Eskitir:** `2026-08-20-alacak-metin-alanlari.sql` içindeki `alacak_borclu_maskele` + `alacak_yaz`. Maskeleme null öğeyi atlar; yazma `[null]`/`[]` geldiğinde eskisini korur. Sebep: 07.09 gece yükleyici `[null]` gönderip 5.643 satırın borçlu dizisini ezdi, `alacak_ara` 400 verdi (veri PATCH + 04.09 yedeğiyle onarıldı, yükleyici düzeltildi) | ✅ **BASILDI 08.09.2026 03:55** (Cem "3 yap"; Claude in Chrome ile Supabase SQL editöründen, "Success. No rows returned"). Ölçüm aynı dakika: `alacak_borclu_maskele('[null]')` → `null` 200 (öncesi 22023) · `[{ad,tckn},null]` → `[{"ad":"X","tckn_var":true}]` · `alacak_ara('7330428877')` 200, 3 kayıt. Ölçüm komutu: `curl -s -X POST .../rpc/alacak_borclu_maskele -H 'apikey: <anon>' -H 'Content-Type: application/json' -d '{"p":[null]}'` |

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
| `2026-09-24-canli-sonuc-cevaplar.sql` | `canli_sonuc.cevaplar` sütunu (A-E/'-' dizisi, adsız) + biçim kısıtı | ⏳ **BEKLİYOR — Cem basacak, 4 Ekim'den önce.** Sayfa sütun yokken özeti sütunsuz yeniden gönderir (sıra serbest). Ölçüm: anon INSERT `cevaplar:"AB-"` → 201 ise basılı; 400 + "cevaplar" ise basılmamış |
| `veri/sql-soru-bildirim.sql` | `soru_bildirim` tablosu | ✅ BASILI — tablo var, anon'a 0 satır |
| `2026-09-06-cevap-kayit.sql` | `cevap_kayit` tablosu (anon yalnız ekler) + `sik_yuzdesi(p_soru_id)` (security definer, anon çağırır, yalnız şık sayımı döner) | ✅ **BASILDI 07.09.2026 gece (Cem, SQL Editor).** İlk ölçümde anon SELECT satır döndürdü (RLS satırları yapıştırmada düşmüş) → Cem ek olarak `revoke select,update,delete … from anon, authenticated` + `enable row level security` çalıştırdı. **Dış ölçüm 07.09:** anon SELECT **401** · anon INSERT **201** · `rpc/sik_yuzdesi` **200** `[{"secim":"A","n":1}]` · politikalar yalnız INSERT · `rowsecurity=true`. Test satırları filtreli DELETE ile silindi (filtre doğrulandı: işaret satırı kaldı). Kaydır-Çöz akran yüzdesi artık canlı. |
| `2026-09-06-kagit-kayit.sql` | `kagit_kayit` tablosu (Kaydır-Çöz ✏️ hesap kâğıdı satırları, anon yalnız ekler) | ✅ **BASILDI 07.09.2026 gece (Cem).** Aynı revoke + RLS düzeltmesi. **Dış ölçüm:** anon SELECT **401** · anon INSERT **201** · `rowsecurity=true` · politika yalnız INSERT. Kâğıt satırları kasaya düşüyor; okuma yalnız servis anahtarıyla. |
| `2026-09-08-kurulus-nobet.sql` | `kurulus_nobet` tablosu (Kuruluş Nöbeti "nöbete al": e-posta + tür + tescil tarihi + olay listesi; anon yalnız ekler, `kvkk=true` şart). Okuyan robot: `motor/kurulus-nobet-postacisi.ps1` (hoş geldin + 3 gün önce hatırlatma). | ✅ **BASILDI 08.09.2026 (Cem).** **Dış ölçüm (aynı gün):** anon POST boş gövde → **400** `23502 null value in column "eposta"` (tablo var, kısıt işliyor) · anon SELECT → **200, 0 satır** (RLS tutuyor, select politikası yok). Postacı kuru koşu 08.09 01:29 UTC YEŞİL · **canlı koşu 01:45 UTC YEŞİL** (1 hoş geldin gitti, damga kasada `hosgeldin=2026-09-08T01:45`, 0 hata). İlk canlı koşu KIRMIZI idi: mail gitti ama `Write-Host` çıktısı `2>&1` ile toplanmadığı için "gitmedi" sayıldı → `*>&1` (96ff5492). Deneme satırı (id=2, Cem) 10.09 hatırlatmasından sonra silinecek. |
| `veri/sql-marka-uyari.sql` | `marka_uyari` tablosu | ✅ BASILI — tablo var, anon'a 0 satır |
| `veri/sql-marka-rakip.sql` | `marka_rakip` tablosu | ✅ BASILI — 29.08 ölçüldü: tablo var, anon'a 0 satır (RLS tutuyor) |
| `veri/sql-marka-durum.sql` | `marka_durum` tablosu | ✅ BASILI — 29.08 ölçüldü: tablo var, anon'a 0 satır |
| `veri/sql-marka-kaynak.sql` | `marka_talep_ac(p_unvan,p_email,**p_kaynak**)` | ✅ **BASILI — 30.08.2026 Cem bastı, canlı uçtan ölçüldü.** 3 parametreli çağrı fonksiyonun GÖVDESİNE ulaşıyor (`P0001 "Unvan 3-160 karakter olmali"`), yani imza kasada var; 29.08'deki `PGRST202` gitti. 2 parametreli çağrı da **belirsizlik hatası vermeden** aynı gövdeye düşüyor → eski imza düşmüş, tek imza kalmış (varsayılan parametreler çalışıyor). Ölçüm zararsız: unvan kısa verildi, kayıt açılmadı. **Bu satır ölüyken Instagram/kampanya kaynak etiketi (`?k=`) hiçbir yere yazılmıyordu — reklam ölçümünün ayağı artık canlı.** Son hücre de ölçüldü: `marka_talep.kaynak` kolonu VAR (30.08, panel) — yani fonksiyon `insert` satırına ulaştığında yazacağı yer mevcut. |
| `veri/sql-marka-bulten-sahip.sql` | `ix_mb_sahipnorm` (trigram GIN) + `marka_norm_sozcuk()` + `marka_bulten_sahip(p_unvan,p_tavan)` **v3** (dönüşe `sahip` alanı; adres eşleşmesi elenir; **sözcük başı** eşleşme) | ✅ **v2 BASILDI 08.09.2026 06:30 (GM, Cem'in Chrome'undaki SQL Editor; Cem "sen basabilirsin"), canlı ölçüldü:** `EGE SERAMİK` 3,5 sn timeout → **0,7 sn 5 kayıt**, `ARÇELİK` 0,6 sn, `DİZDAR DENETİM` 0,17 sn, `sahip` alanı geliyor. ✅ **v3 (sözcük başı) BASILDI 08.09.2026 07:45 (GM, aynı yol), canlı ölçüldü:** `ARÇELİK` 339 → **224 kayıt, HEZAR/STAR/ÇAĞLAR 0**, 0,9 sn; `EGE SERAMİK` 5 kayıt 0,2 sn; `DİZDAR DENETİM` 1 kayıt. (v2'de "ARÇELİK" → HEZAR ÇELİK KAPI, "EGE" → DEĞER geliyordu, boşluksuz alt dize.) Eskitir: `veri/sql-marka-bulten.sql` içindeki `marka_bulten_sahip` (b). **v3 ölçümü:** `rpc/marka_bulten_sahip {"p_unvan":"ARÇELİK","p_tavan":500}` → satırlarda `sahip ilike '%hezar%'` 0 = v3 basılı; HEZAR varsa v2. 3 harfli arama (`EGE`) trigram daraltması zayıf olduğu için hâlâ zaman aşımına düşebilir; sayfa "ambar cevap vermedi" der. ⚠️ **09.09 ÖLÇÜLEN YAN ETKİ — bu indeksin bir YAZMA bedeli var:** `marka_bulten` artık İKİ GIN trigram indeksi taşıyor (`ix_mb_adnorm` + bu). GIN'in bekleyen listesi dolunca flush'ı o an yazan istek üstlenir ve tek istek zaman aşımına çarpar. Gece hasadında ölçüldü: "yazma zorlandı" olayı indeksten **önce 3 gecede 0** (koşu 15/16/17), **sonraki ilk gecede 22** (koşu 19) + 1 bülten yandı (387, 11.301 kayıt). Parti küçültmek çare değil — bölme 25 satıra kadar indi, 25 satır bile düştü. Çözüm yazıcıda: `motor/marka-bulten-hasat.js` en küçük parçada bekleyip 3 kez yeniden dener (commit 09.09). Sürerse ikinci adım: `alter index ix_mb_sahipnorm set (gin_pending_list_limit = 512);` (flush'ı 8'e böler, geri alınabilir) — **ölçmeden basılmadı**, tonight/ertesi gece koşusu karar verir. |
| `veri/sql-karne.sql` | `karne` tablosu | ❌ **TABLO YOK** (`PGRST205`) — basılmamış ya da adı farklı |
| `veri/sql-siparis.sql` | `siparisler` tablosu | ✅ **BASILI — 30.08.2026 Cem bastı, panelden ölçüldü.** 18 kolonun 18'i yerinde (eksik-kolon sorgusu 0 satır), tabloda 0 satır. ⚠️ **DERS: 29.08'de bu satır "TABLO YOK" diyordu ve dosya `create table if not exists` ile başlıyordu — tablo o sırada BAŞKA BİR YERDEN kurulmuş olsaydı yeni kolonlar SESSİZCE eklenmeyecekti.** Basmadan önce `information_schema.columns` sorgusu çalıştırıldı, tablonun zaten var olduğu görüldü ve `create` yerine **ALTER'lı sürüm** basıldı. Kural: *"basılı mı"yı ölçmeden `create table if not exists` basma — çalışır görünüp eksik şema bırakır.* Politika da yenilendi: yeni dört kolon (`liste_fiyat`, `dersler`, `secilen_dersler`, `davet_kodu`) biçim kilidine dahil; dışarıdan gelen sipariş zorunlu `odeme_bekliyor` doğuyor. |
| `veri/sql-davet-kodu.sql` | `paket_uyeler` +4 kolon · `davet_kullanim` tablosu · `davet_kodu_uret()` `davet_kodu_ata()` `davet_uygula()` | ✅ **BASILI — 30.08.2026 Cem bastı, panelden ölçüldü.** yeni_kolon 4/4 · kutuk_tablosu 1 · fonksiyon 3/3 · örnek kod `TTY7JJ` (biçim doğru) · mevcut 1 üyenin kodu üretilmiş. **Neden kuruldu:** `fiyat.html` 02.08'den beri "3 davet kodu veriyoruz" diyordu, depoda `davet_kod` diye bir şey YOKTU — arkasında kod olmayan yazılı söz. `davet_uygula()` yetkisi anon+authenticated'tan **alındı**: yalnız service_role çağırır, yoksa üye kendi kodunu ikinci hesabına yazardı. |
| `2026-09-23-hesap-paylasim-korumasi.sql` | `uye_cihazlar` · `uye_ekran` · `uye_cihaz_olay` tabloları (RLS açık, politika YOK, auth.users'a FK YOK) · `cihaz_kontrol(p_cihaz,p_etiket,p_devral)` (tek ekran + 3 cihaz) · `cihazlarim(p_cihaz)` · `cihaz_cikar(p_hedef)` (30 günde 2) — üçü yalnız `authenticated` · **Eskitir:** `2026-09-23-uye-sayim.sql` içindeki `uye_sayim()` (+`paylasim_supheli`, `cihaz_siniri_24s`) | ✅ **BASILI — 23.09.2026 gece, Cem SQL Editor'de çalıştırdı.** **Doğrulandı (ölçüldü):** a) `uye_sayim()` yeni alanları döndürüyor (`paylasim_supheli`, `cihaz_siniri_24s`) · b) anon anahtarla `rpc/cihaz_kontrol` → **HTTP 401** · d) tablolarda gerçek prova verisi varken (2 cihaz · 1 ekran · 10 olay) anon **0 satır** gördü (curl ile sayıldı — PS 5.1'de `@(Invoke-RestMethod …).Count` K2 tuzağı yüzünden hep 1 der, ilk ölçüm yanıltıcıydı) · **4 cihazlı tam prova 13/13** (gerçek paketli prova üyesi, gerçek sayfa): devretme, "Burada devam et" ile geri alma, 3. cihaz girer, 4. cihaz sınır perdesine düşer, Cihazlarım 3/3 listeler, 2 çıkarma yapılır, 3. çıkarma `aylik_sinir`, yer açılınca 4. cihaz girer, filigranda üyenin e-postası. **Temizlik ölçüldü:** prova verisi 14 satır + paket satırı + hesap silindi, toplam üye yeniden 6. Öncesi (basılmadan): fail-open prova 4/4. |
| `2026-09-23-uye-sayim.sql` | `public.uye_sayim()` — YALNIZ SAYI döner (toplam · son 1 saat · son 24 saat · son 1 saatin en yoğun dakikası); e-posta/kimlik dönmez; yalnız `service_role` çağırabilir | ✅ **BASILI — 23.09.2026, Cem SQL Editor'de çalıştırdı** (GM'nin tarayıcıdan basması güvenlik sınıflayıcısınca durdurulmuştu). **Doğrulandı (ölçüldü):** a) editörde `select public.uye_sayim()` → toplam 6, son 1 saat 0 · b) herkese açık anon anahtarla `POST /rest/v1/rpc/uye_sayim` → **HTTP 401** (yetkisiz; üye sayıları dışarı açık değil) · c) servis anahtarıyla `motor/uye-alarmi.ps1 -Kuru` → **YEŞİL**, sayılar okundu · d) bulut koşusu `uye-alarmi.yml` run 35794602663 → success, YEŞİL. Tablo değil fonksiyon, auth.users'a FK yok. |
| `2026-09-15-elci-programi.sql` | `siparisler` +3 kolon (`elci_kodu`, `indirim_tl`, `odendi_tarihi`) · `elciler` (29.09: +`user_id` FK'SIZ, `bag_kodu_ozet`/`_son`, `sozlesme_onay`/`_surum`, `odeme_bilgisi`) · `elci_indirim` (**sgs=400 · yeterlilik-tum=400**; 1–4 ders merdiveni indirimsiz) · `sinav_donemleri` · `elci_odemeler` (29.09) · `elci_kodu_kontrol(p_kod,p_paket)` (anon, yalnız TL) · `siparis_elci_damga` (29.09: kendi koduyla alım `ELCI_KENDI_KODU` hatasıyla DURUR) + `siparis_odendi_damga` · `siparisler_ekle` politikası YENİDEN (elçi kodu biçimi) · `elci_komisyon(n,bk)` · `elci_donem_raporu` (29.09: kademe İNMEZ) · **elçi paneli** `elci_bagla` / `elci_sozlesme_onayla` / `elci_panelim` (yalnız authenticated) | — | ✅ **BASILI — 29.09.2026 akşam Cem bastı (SQL Editor "Success").** Basmadan önce canlı `siparisler_ekle` kilidi 17/17 koşul `veri/sql-siparis.sql` ile aynı görüldü (Cem ekran görüntüsü). **Anonim uçtan ölçüldü (29.09):** `elci_kodu_kontrol(YOKKOD,sgs)`=0 · `(…,yeterlilik-1)`=0 · `elciler`/`elci_indirim`/`elci_odemeler`/`elci_donem_raporu`/`sinav_donemleri` anon 401 (42501) · `elci_komisyon(30,1)`=27750 · ⚠ `elci_panelim`/`elci_bagla`/`elci_sozlesme_onayla` anon 200 null/false (Supabase varsayılan anon EXECUTE; veri yok) → dosyaya bölüm 12d `revoke … from anon` eklendi, Cem'e ayrıca basılması verildi. **Servis anahtarı ölçümü GEÇMEDİ:** yereldeki `SUPABASE_SERVICE_KEY` (sb_secret) her tabloda 401 → `arac/elci.ps1 -Dogrula` sunucu-motor indirim kıyasını yapamadı; anahtar yenilenene dek elçi ekleme SQL Editor'den. İlk elçi: Adile Ersoy (örnek/deneme, kod AE42). Site: `ELCI.acik` hâlâ false (açılışta). |
| `2026-10-01-elci-ders-komisyonu.sql` | Tek ders komisyonu (Cem 01.10 "150 tl olsun"): `elci_indirim` +`sabit_komisyon_tl` (yeterlilik-1..4: indirim 50/100/150/200 — Cem "50 olsun" · komisyon 150/300/450/600) · `siparisler` +`elci_sabit_komisyon_tl` (tetikleyici damgalar) · `siparis_elci_damga` YENİDEN · `elci_donem_raporu` YENİDEN (kademeli sütunlar yalnız damgasız satış; sona `ders_kesin_satis`/`ders_bekleyen_satis`/`ders_komisyon_tl`/`toplam_komisyon_tl`) · `elci_panelim` YENİDEN (+`ders_*`, `indirimler` yalnız >0, +`ders_komisyonlari`) | `2026-09-15-elci-programi.sql` bölüm 6, 10, 12c (o dosya yeniden basılırsa bu da ardından basılır) | ✅ **BASILI — 01.10.2026 akşam Cem bastı.** Anonim uçtan ölçüldü (01.10): `elci_kodu_kontrol(AE42, yeterlilik-1/2/3/4)` = 50/100/150/200 · `yeterlilik-tum`=400 · `sgs`=400 · `YOKKOD`=0 · `elci_indirim`/`elci_donem_raporu`/`elciler` anon 401 · `elci_panelim` anon 401. Siparişe 150 TL damgası henüz gerçek siparişle ÖLÇÜLMEDİ. |
| `2026-10-01-elci-sozlesme-kaydi.sql` | `elciler` +`sozlesme_eposta` / `sozlesme_eposta_surum` / `sozlesme_ozet` — edge `elci-sozlesme` (radar-app/edge/elci-sozlesme.ts) onay kopyasını elçiye e-postalayınca yazar (sözleşme 4.2) | — | ✅ **BASILI — 01.10.2026 akşam Cem bildirdi.** Kolonlar anonim uçtan ÖLÇÜLEMEZ (tablo kapalı); ilk gerçek onayda edge'in kayıt adımıyla ölçülecek (select kod, sozlesme_eposta, sozlesme_eposta_surum, sozlesme_ozet from elciler). Edge YÜKLENDİ (01.10 Cem) — canlı adı `rapid-responder` (panelin verdiği ad), `?surum=1` = c9cd201c222f09dd depoyla aynı, secret'lar tanımlı (ELCI_KOPYA yok). |
| `veri/sql-guvenlik-kapisi.sql` | `leadler` anon yazma izni | ✅ **BASILI — 30.08.2026 Cem bastı, canlı uçtan ölçüldü.** `POST leadler {}` → **`401 / 42501 "permission denied for table leadler"`**. 29.08'de aynı istek `23502` dönüyordu: RLS yazmayı hiç engellemiyordu, yalnız NOT NULL durduruyordu — yani anonim biri sınırsız satır basabilirdi. Açık kapandı. Maliyeti sıfırdı: `leadler`'e yazan site kodu yok, formlar web3forms'a gidiyor. |
| `veri/sql-form-kasasi.sql` | `form_kayit` tablosu (site formlarının kasası; anon/authenticated'a hak YOK, yalnız service_role yazar) | ✅ **BASILDI — 04.09.2026 akşam Cem SQL Editor'dan bastı, canlıdan ölçüldü:** `kolon_sayisi` 10 · anon `GET form_kayit` → **401/42501** (dışarı kapalı) · yerelden gerçek gönderi → `quick-task` **200 `{kayit:true, posta:false}`** = satır kasaya düştü, mail RESEND_KEY girilmediği için gitmedi (konu "GM TEST - kasa denemesi, silinebilir" satırı test kaydıdır). **Edge Function 04.09 akşam DEPLOY EDİLDİ — canlı adı `quick-task`** (Cem panelde isim kutusunu boş bıraktı, Supabase ad verdi; kod `radar-app/edge/form-al.ts`). "Verify JWT" AÇIK kaldı → 19 sayfa isteğe açık anahtarı `apikey`+`Authorization` başlığıyla ekler. ✅ **ZİNCİR TAMAM — 04.09.2026 16:4x:** Cem üç secret'ı girdi (RESEND_KEY · RESEND_FROM · FORM_ALICI), `quick-task?tani=1` dördü de `true`; yerelden gerçek gönderi → **200 `{kayit:true, posta:true}`** (tabloda satır + Resend mail kabul). Ölçüm adresi: `GET …/functions/v1/quick-task?tani=1` (apikey başlığı şart). Uç düşerse sayfa "iletilemedi + info@dizdardenetim.com" gösterir, sessiz kayıp yok: `mrTeklif` formları ekranda "iletilemedi + mail adresi" gösterir, diğerleri kendi hata satırını gösterir. web3forms 04.09'da tüm sayfalardan çıkarıldı (Cem: "müşteri verisi tanımadığımız aracıdan geçmez"). |
| `2026-07-17-rate-limit.sql` | `rate_log` tablosu + `rate_limit_check()` | ✅ **BASILI** — 29.08 ölçüldü: tablo 200/`[]`, RPC `true` döndü. ⚠️ Kütükteki eski satır `rate_limit` adlı bir tablo arıyordu ve "merkezî istek sınırı yok" diyordu — **yanlıştı**: SQL `rate_log` kuruyor, o da yerinde. Hız sınırı altyapısı **hazır ve anon'a açık**; kullananlar `radar-app/edge/net-cevap.ts` + `beyanname-oku.ts`. NOT: IP'yi çağıran taraf verdiği için tarayıcıdan gelen doğrudan çağrılarda güvenilmez — gerçek koruma Edge Function ya da captcha ister. |

## madde_ara zinciri (Net Cevap aramasının kalbi)

Sekiz sürüm, hepsi aynı fonksiyonu yeniden yazıyor. **Geçerli sürüm: v8.**

`v2 (16.07) → v3 (16.07) → v4 (16.07) → v5 (17.07) → v5-tur-agirligi (30.07) →
v6 (19.08) → v7 (23.08) → v8 (25.08)`

| Dosya | Durum |
|---|---|
| `2026-08-25-madde-ara-v8.sql` | ✅ **BASILI — 10.09.2026'da ölçüldü** (aşağıya bak). 57014 timeout'u hâlâ oluyor ama sebebi sürüm değil. |

**10.09.2026 — "canlıda hangi sürüm koşuyor?" ÖLÇÜLDÜ, artık tahmin değil.**
`pg_get_functiondef('public.madde_ara(text,integer)')` parmak izi:

| İşaret | Sonuç |
|---|---|
| imza sayısı | **1** (`public.madde_ara(text,integer)`) — aşırı yükleme yok |
| tanım uzunluğu | 2.316 karakter · md5 `f763bddd0e82adcf57dc419be43948f2` |
| `secili` / `qdar` (v8 dar havuzu) | **var** |
| `df <= 1500` eşiği | **var** |
| `standart-madde` tür dalı (v8 ölü dal onarımı) | **var** |
| `arama_fold` kolonu | **var** |
| `limit 300` aday havuzu | **var** |
| trigram / `similarity` | yok |

Yani **canlıdaki fonksiyon deponun v8'idir**; depo dışından bir değişiklik
girmemiş. (`union` işareti `true` çıkıyor ama bu v8'in kendi `secili2`
bloğundaki `union all`'dır — yanlış alarm.)

⚠️ **Bu satır bir günlük yanlış teşhisi kapatıyor:** 10.09'da "canlı fonksiyon
depodaki hiçbir sürümle uyuşmuyor" hükmü kuruldu. Yanlıştı. Sebebi ölçüm
hatasıydı — aynı tebliğin `[giris]` satırı ölçülüp `m.4` satırı sanıldı.
Gerçek arıza fonksiyonda değil **veride**: `SPK Tebliğ (Seri: X, No: 22) m.4`
tek satırda **146.979 karakter** duruyor ve v8'in `kapsanan` bonusu onu her
sorguda tepeye taşıyor. Onarım `motor/spk-mevzuat-yut.ps1` içinde
(dev madde artık dilimleniyor); **etkili olması için o kaynakların yeniden
yutulması gerekir.**

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

### 🔴 30.08 — kök sebep ÖLÇÜLDÜ: sorun fonksiyonda değil, İNDEKSTE

Sekiz sürüm boyunca hep **fonksiyon** yeniden yazıldı. 30.08'de fonksiyondan
bağımsız, **saf tablo sorgusu** ölçüldü (anon anahtar, canlı uç):

| İstek | Sonuç |
|---|---|
| `GET /dokumanlar?select=id&limit=1` | ✅ 200, hızlı |
| `GET /dokumanlar?tur=eq.kanun-madde&limit=3` | ✅ 200, hızlı |
| `GET /dokumanlar?kaynak_ad=eq.<5973 s. Karar>&limit=3` | ❌ **500 · 57014** |
| `GET /dokumanlar?tur=eq.kanun-madde&kaynak_ad=eq.<…>` | ❌ **500 · 57014** (4,4 sn) |
| `POST /rpc/madde_ara {"sorgu":"ihracat & destek"}` | ❌ 500 · 57014 (8,1 sn) |

**`madde_ara` hiç devrede değilken, tek satırlık `kaynak_ad` eşitliği bile
zaman aşımına düşüyor.** Fonksiyonu ne kadar iyileştirirsek iyileştirelim
düzelmemesinin sebebi bu: `dokumanlar` 13 binden 43.440 parçaya büyüdü ve
`kaynak_ad` ile `arama_fold` sütunlarında indeks yok — her sorgu tam tarama.
`tur` filtresinin çalışması da bunu doğruluyor (onda indeks var).

Göç: **`2026-08-30-ambar-index.sql`** — üç indeks basar (arama_fold GIN,
kaynak_ad, tur+kaynak_ad), tablo yapısına ve veriye dokunmaz.
⚠️ `concurrently` kullanıyor: Supabase SQL editöründe satırları **tek tek**
çalıştır, hepsini birden yapıştırma.

| Dosya | Durum |
|---|---|
| `2026-08-30-ambar-index.sql` | ⛔ **BASILMAYACAK — yerine 14.09 dosyası.** 14.09 08:10 panelde `pg_indexes` okundu: `arama_fold` GIN'i zaten var (`dokumanlar_arama_fold_idx`, başka adla); bu dosya basılsa ikinci GIN kurulurdu (disk 5,75/8 GB). `kaynak_ad` ve `tur` indeksleri YOK. |
| `2026-09-14-dokumanlar-tur-kaynak-index.sql` | ✅ **BASILDI 14.09 ~08:22 (Cem, SQL Editor)** — doğrulama sorgusu 5 ad döndü: dokuman_arama_idx · dokumanlar_arama_fold_idx · dokumanlar_kaynak_ad_idx · dokumanlar_pkey · dokumanlar_tur_kaynak_idx. Ölçüm (REST, 3 tekrar ortancası, ağ tabanı ~0,13 sn): tur=cikmis-soru 0,30→0,16 · KAPI-CB 40'lık sayfa 0,52→0,17 · tur+kaynak_ad ilike 0,24→0,14 · kaynak_ad eşitlik 0,15→0,15 sn. Önceki not: Yalnız eksik iki btree (`tur,kaynak_ad` · `kaynak_ad`) + analyze; aynı Run'da 5 indeks adı dönmeli. Neden: 13–14.09 gecesi `tur=eq.cikmis-soru` sorgusu 22–24 sn / 57014; üretici kapıları kör kaldı, iki parti çöpe gitti. |

Bu indeksler basılmadan: Net Cevap araması cevapsız kalmaya devam eder ve
Destek Radarı'ndaki "Dayanağı" satırı ambardaki maddeye **bağlanamaz**
(bağ bugün metin olarak duruyor, tıklanabilir değil).

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

---

## rag semasi (RAG motoru) — AYRI GOC KUTUGU

Bu sema kendi kutugunu tasir: `select * from rag.schema_migrations;`
"Hangi SQL basili?" sorusu orada TAHMINSIZ cevaplanir; asagisi ozet.

| Goc | Basildi | Ne kurdu |
|---|---|---|
| `001_init` | 10.09.2026 | kaynak · parca · parca_vektor · is_kuyrugu · soru · `rag.ara()` hibrit arama (RRF k=60) · HNSW indeksi · `rag.katla()` |
| `002_konu_madde` | 10.09.2026 | `rag.konu_madde` (konu->madde kalici eslesme) · `rag.konu_dayanak()` · `rag.kartsiz_konular` gorunumu · ilk 6 dogrulanmis kart |
| `003_ara_v2` | 10.09.2026 | **rag.ara v2** — tam metin kanali `plainto_tsquery`(VE) yerine `to_tsquery`(VEYA + onek). v1 her sorguda BOS donuyordu: 11 kelimelik sorgunun hepsini ayni parcada ariyordu. |
| `004_kart_hizala` | 10.09.2026 | **konu_dayanak v2** — eslesme `kaynak_kod` + `madde_no` uzerinden. v1 eski ambarin kaynak ADIYLA yaziliydi (`%VUK (213 s.K.) m.261%`), yeni semada ad `Vergi Usul Kanunu (213 s.K.)` oldugu icin HIC tutmuyordu; kartlar sessizce devre disiydi. |

**10.09.2026 dogrulama (canli):**
`002_konu_madde / rag.ara v1 (RRF k=60) / konu_madde + konu_dayanak / vector(768) cosine HNSW(m=16,ef_c=64)`
· goc 2 · konu karti 6 · tablo 7 · **RLS acik 7/7**

RLS'i Supabase'in kendi uyarisi uzerine actik. Motor `postgres` kullanicisiyla
(tablo sahibi) baglandigi icin RLS'i baypas eder - engellemez, guvenligi artirir.

⚠️ **rag semasi PostgREST'ten ERISILEMEZ** (olculdu: `PGRST106 - Only public,
graphql_public are exposed`). Yani Supabase API anahtariyla bu semaya yazilamaz;
motor Npgsql ile DOGRUDAN Postgres'e baglanmak zorundadir. Bunun icin veritabani
sifresi gerekir ve Supabase o sifreyi **kurulumdan sonra gostermiyor** - yalniz
sifirlanabiliyor. Bu depoda dogrudan Postgres kullanan BASKA bir sey yok
(hepsi PostgREST); olculdu.
---

## `2026-09-10-kalip-surum-kapisi.sql` — ✅ CANLIDA (16.09.2026 ölçüldü, kısmen doğrulandı)

> 16.09 ölçüm (PostgREST, salt okuma): `soru_havuzu.kalip_surum` sütunu VAR (v1 30.569 · v2 0 · yayin=true 0),
> `soru_havuzu_arsiv_v1` görünümü VAR (30.569 satır) → dosya basılmış. `ck_soru_havuzu_yayin_yalniz_v2` kısıtı
> PostgREST'ten okunamadığı için ayrıca DOĞRULANMADI (denemek bir v1 satırı yayına almayı gerektirir — yapılmadı).
> Teyit: SQL Editor'de `select conname from pg_constraint where conname='ck_soru_havuzu_yayin_yalniz_v2';`

**Ne yapar:** `soru_havuzu`'na `kalip_surum` sütunu (`v1` / `v2`) ekler ve
**`yayin = true` yalnız `v2` satırlara verilebilir** kısıtını kurar.

**Neden şimdi:** Ölçüldü (10.09) — havuzun tamamı v1 (30.569), sitede tek soru
yok (`yayin=true` = 0), son üç günün 6.223 sorusu fabrika dosyalarında ve havuza
**hiç aktarılmamış**. Karışma henüz olmadı. Sürüm damgası aktarımdan ÖNCE
konuluyor; sonra konsaydı 30.569 satırı geriye dönük tahminle etiketlemek
gerekirdi.

**Neden CHECK, neden uygulama katmanı değil:** uygulama kuralı unutulur. Aynı
gün ölçüldü — RAG telif süzgeci "çağırana bırakılmıştı" ve çağıran NULL
geçiyordu, yani kural hiç çalışmıyordu. Yayın kararı veritabanının kendisinde
durur.

**v1 SİLİNMEZ:** 7.699 satırda insan onayı var. Etiket zaten karantinadır.
Görünüm: `public.soru_havuzu_arsiv_v1`.

🔴 **BASILDIKTAN SONRA YAPILACAK:** fabrika→havuz aktarıcısı `kalip_surum='v2'`
yazmalı. Yazmazsa varsayılan `v1` olur ve yeni sorular da yayına çıkamaz —
kapı doğru çalışır ama iş durur.

---

## 011_kalip_parti.sql — BASILDI 11.09.2026 22:35 (GM, Cem "1) açtım")

`rag-motor/sql/011_kalip_parti.sql` · Supabase SQL editörü · **Success. No rows returned**

**Ne geldi:** `public.kalip_parti` (parti önbelleği, jsonb) · `public.bedel_kaydi`
+ `public.bedel_aylik` görünümü (harcama defteri) · `public.konu_koprusu`
(21.333 kayıtlık konu-sıklık köprüsü). Üçü de **RLS açık, politika YOK** →
yalnız `service_role`.

**Niye:** üretim hattının üç durumu (`veri/fabrika/kalip-parti-*.json`,
`bedel-kayit.jsonl`, `konu-koprusu.json`) `.gitignore`'daydı ve yalnız Cem'in
dizüstünde duruyordu. GitHub Actions'ta üretim koşarsa iş bitince önbellek
kayboluyordu. Bu üç tablo o bağı kesiyor; yerel de bulut da aynı yerden okur/yazar.

**Basarken iki hata yapıldı, ikisi de ölçümle yakalandı — kayda geçiyor:**

1. `ay text generated always as (to_char(zaman,'YYYY-MM')) stored` →
   **42P17 "generation expression is not immutable"**. `to_char(timestamptz,text)`
   STABLE'dır (sonucu oturumun TimeZone ayarına bağlı), üretilmiş kolonda
   kullanılamaz. Çözüm: normal kolon + `before insert or update` tetikleyici,
   saat dilimi açıkça `at time zone 'UTC'`. **Hiçbir şey basılmamıştı** (tek
   işlem, geri alındı).
2. Tablolar önce `rag` şemasında kuruldu → PostgREST **404 PGRST205**
   ("Could not find the table 'public.kalip_parti'"). Supabase API'si yalnız
   "exposed schemas" listesindekileri yayınlar. Depodaki betiklerin hepsi şema
   öneksiz çağırıyor; `rag`'i yayınlamak her çağrıya `Accept-Profile: rag`
   başlığı eklemek demekti. Tablolar `public`'e alındı, `rag` sürümleri
   `drop ... cascade` ile temizlendi. **Güvenlik aynı kaldı** (aşağıda ölçüldü).

**Basıldıktan sonra ÖLÇÜLDÜ (iddia değil):**

| Ölçüm | Sonuç |
|---|---|
| service_role ile 4 uç | `kalip_parti` 200 · `bedel_kaydi` 200 · `konu_koprusu` 200 · `bedel_aylik` 200 |
| yazma + tetikleyici | satır yazıldı, `ay='2026-09'` (tetikleyici doldurdu), sınav satırı silindi |
| satır sayısı | üçü de 0 (boş, senkron bekliyor) |
| **anon ile okuma** | üçünde de gövde `[]` — RLS kapatıyor (kontrol: `soru_havuzu` da `[]`) |

**Editöre yazılan metin SHA-256 ile dosyayla karşılaştırıldı** (`9bec468f…`,
10.747 karakter) — elle aktarma hatası olmadığı ölçüldü.

🔴 **SIRADAKİ:** `arac/bedel-senkron.ps1 -Yukle -Yaz` ·
`arac/kopru-senkron.ps1 -Yukle -Yaz` · `arac/parti-senkron.ps1 -Yukle -Yaz`.
Fren provası Cem kararıyla DÜŞTÜ ("tutar için uğraşma, bakiye kadar harcar") —
gerekçe ölçüldü: `motor/kalip-parti-uret.ps1` içindeki **KAPI-BAKIYE** her parti
öncesi Anthropic bakiyesini yokluyor ve bulutta da çalışıyor.

## 13.09.2026 · öğrenci paneli

| Dosya | Ne yapar | Durum |
|---|---|---|
| `radar-app/sql/2026-09-13-ogrenci-sonuc.sql` | `ogrenci_sonuc` tablosu: ogrenci.html seviye testi + sınav gibi deneme sonuçlarını üyenin hesabına yazar; RLS yalnız `user_id = auth.uid()` (oku/ekle/sil, UPDATE yok), anon hakkı YOK, `(user_id,tur,anahtar)` tekil. Önce ölçüldü: tablo YOKTU (PGRST205). | ✅ **BASILDI 14.09.2026 (GM, Cem onayıyla, Chrome eklentisi → SQL Editor).** Dosya parmak izi GitHub = yerel (sha256 37cec226…). Editör "destructive operations" uyarısı verdi (drop policy if exists / revoke — tablo YOKTU, silinen şey yok), onaylandı. **Dış ölçüm:** servis SELECT **200 []** · anon SELECT **401 / 42501** · anon INSERT **401 / 42501**. ⚠️ **KESİNTİ:** sorgu "Running" beklerken PostgREST **bütün tablolarda ~2-3 dk 503 PGRST002** ("could not query the database for the schema cache") döndü; sorgu Success olunca form_kayit 200, cevap_kayit yazma yolu sağlıklı. Muhtemel sebep: `references auth.users` kilidi + şema önbelleği yenilemesi. **Ders:** canlı tabloya/auth.users'a bağlanan DDL düşük trafik saatinde basılır ve basarken PostgREST sağlığı eşzamanlı izlenir. |

## `TASLAK-2026-09-15-paket-soru.sql` — ⏸ TASLAK, BASILMADI (Adım 2)
| Dosya | Ne yapar | Durum |
|---|---|---|
| `radar-app/sql/TASLAK-2026-09-15-paket-soru.sql` | `paket_soru` kasası (RLS: aktif paket + ders bazlı erişim), anonim `ucretsiz_soru` görünümü (doğru şık YOK), `seviye_kontrol()` sunucu cevap kontrolü (hız sınırlı) | ⛔ **ESKİDİ — `2026-09-16-paket-soru.sql` ile değişti, BU DOSYA BASILMAZ.** Yükleyici `motor/kasa-soru-yukle.js` kuru koşu 15.09: 16 sayfa, 3.727 satır (518 ücretsiz = vitrin 70 + seviye havuzu 450, 2 ortak), 49,9 MB. |

## 16.09.2026 · Adım 2 paket soru kasası (Cem "1.2.3 üçünü de yap")
| Dosya | Ne yapar | Eskitir | Durum |
|---|---|---|---|
| `radar-app/sql/2026-09-16-paket-soru.sql` | `paket_soru` kasası (RLS: aktif paket + ders bazlı erişim), anonim `ucretsiz_soru` görünümü (doğru şık YOK), `seviye_kontrol(p_id,p_secim)`: IP'yi **sunucu başlığından** okur (taslakta tarayıcı bildiriyordu, boş IP sınırı atlıyordu), 40 kontrol / 10 dk | `TASLAK-2026-09-15-paket-soru.sql` (imzası `seviye_kontrol(text,text,text)` idi — basılmadı, drop gerekmez) | ✅ **BASILDI 16.09.2026 ~17:35 (Cem, SQL Editor; açıklama satırları kısaltılmış, çalışan kod dosyayla birebir).** Eşzamanlı sağlık izlemesi KOŞMADI (Cem izleme başlamadan bastı); basım sonrası `dokumanlar` 200. **Dış ölçüm 16.09 (sayfaların açık anahtarıyla):** anonim `paket_soru` **401 / 42501** · anonim `ucretsiz_soru` **200 []** · servis `paket_soru` **200 []** · anonim `rpc/seviye_kontrol` **200 {"hata":"soru yok"}** · hız sınırı: aynı IP'den 40. çağrıda **{"hata":"cok fazla istek"}** (öncesinde 1 çağrı daha yapılmıştı → sınır 40/10 dk doğru). Ölçülmedi: paketsiz üye 0 satır, kurucu üye sayımı (tablo boş; yükleme sonrası). Not: Supabase işlemci boyu MEDIUM (plan NANO yazıyordu), disk %84 (16.09 ekran). Basım öncesi ölçüm 16.09: `paket_soru` 404 · `ucretsiz_soru` 404 · `rpc/seviye_kontrol` 404 · `rate_limit_check` true · `paket_uyeler.dersler` var. Yükleyici kuru koşu 16.09: 16 sayfa, **4.042 satır** (738 ücretsiz; seviye havuzu 675 kimlik, bulunamayan 0), 52,9 MB, kimlik tekrarı 0. |
| ↳ SGS yüklemesi + Türkçe pilot (veri, SQL değil) | `node motor/kasa-soru-yukle.js --yaz` (yalnız değişen satırı yazar) · `motor/kasa-kabuk.js --yaz` | — | ✅ **16.09.2026 ~18:05 (site oturumu 3c).** 1. yazım: **4.058 SGS satırı** (738 ücretsiz), 29 sn, kasada toplam **4.071** (+13 SMMM, bitirme oturumu); basım sırasında `dokumanlar` 200. 2. yazım: **yazılan 0 · değişmeyen 4.058** → kasadaki her satır sayfadakiyle alan alan aynı (tablonun tamamında eşdeğerlik). **Anonim dış ölçüm:** `ucretsiz_soru` 200 `0-737/738`, içerikte `dogru`/açıklama/hap/adım anahtarı **0** · `rpc/seviye_kontrol` ücretsiz kimlikle `{dogru, dogru_mu}`, bilinmeyen kimlikle `soru yok` · `paket_soru` **401**. Türkçe kabuk: 77 soru kasayla birebir, 1,21 MB → 158 KB, kabukta `dogru`/`kp-` izi 0. Ölçülmedi: paketli üye ile canlı çekim (Cem'in kurucu hesabı). |

## 25.09.2026 · Mağaza uygulaması: uygulama içi satın alma (Cem "1 ve 2 yap")
| Dosya | Ne yapar | Eskitir | Durum |
|---|---|---|---|
| `radar-app/sql/2026-09-25-magaza-siparis.sql` | `magaza_siparis` kütüğü: satın alma jetonu başına tek satır (jeton unique), durum `isleniyor/verildi/tuketildi/red/beklemede/hata`, RLS açık + politika YOK (yalnız servis anahtarı). auth.users'a FK YOK. Yazan: `radar-app/edge/magaza-dogrula.ts` | — | ✅ **BASILDI 25.09.2026 (Cem, SQL Editor; dosyadaki kodun aynısı, açıklama satırları olmadan).** **Dış ölçüm 25.09 (açık anahtar):** anon `GET magaza_siparis` → **HTTP 401 / 42501** "permission denied" (tablo var, kapalı) · kıyas: olmayan tablo 404 PGRST205 · basım sonrası `dokumanlar` 200. Ölçülmedi: servis anahtarıyla 200 `[]` (bu makinede servis anahtarı yok). |

## 26.09.2026 · Mağaza uygulaması: hesaba bağlı ilerleme (Cem "eksiklerin hepsini yapalım", B kümesi)
| Dosya | Ne yapar | Eskitir | Durum |
|---|---|---|---|
| `radar-app/sql/2026-09-26-ogrenci-ilerleme.sql` | `ogrenci_ilerleme`: üye başına tek satır (user_id PK, `veri` jsonb ≤1,5 MB) — son cevaplar, 🔖 işaretler, 📝 notlar, kaldığın yer, günlük sayaç, çalışma ayarları. RLS: authenticated yalnız kendi satırını okur/ekler/günceller; anon hiç. auth.users'a FK YOK (14.09 DDL kesintisi dersi). Yazan/okuyan: `mobil/uygulama/ilerleme.js` esitle() (birleştirir, ezmez; öz-sınav `mobil/ilerleme-sinavi.js`) | — | ✅ **BASILDI 26.09.2026 (Cem, SQL Editor; açıklama satırları olmadan, çalışan kod dosyayla birebir).** Basım öncesi ölçüm: anon GET → 404 PGRST205. **Dış ölçüm 26.09 (açık anahtar):** anon `GET ogrenci_ilerleme` → **401 / 42501** · anon `POST` → **401 / 42501** (tablo var, kapalı) · basım sonrası `dokumanlar` 200. Ölçülmedi: girişli üyenin kendi satırını yazıp okuması (uygulamada ilk eşitleme ile). |
| `radar-app/sql/2026-09-26-uyelik-kapisi.sql` | `hesabimi_sil()` (security definer; oturumdaki kişi YALNIZ kendi hesabını siler: ogrenci_ilerleme + auth.users, CASCADE'li tablolar kendiliğinden; magaza_siparis kalır) — Apple 5.1.1(v) uygulama içi hesap silme · `uygulama_olay` tablosu (gün/olay/platform/sayı; kişisel veri yok, RLS açık, politika yok) + `olay_say(p_olay,p_platform)` (sabit olay listesi; anon+authenticated çağırır). Yazan: `mobil/uygulama/uygulama.js` (hesap silme), `ilerleme.js` TTOlay (sayaç kuyruğu). auth.users'a yeni FK YOK | — | ✅ **BASILDI 26.09.2026 (Cem, SQL Editor; açıklama satırları olmadan, çalışan kod dosyayla birebir; "Success. No rows returned").** **Dış ölçüm 26.09 (açık anahtar):** anon `rpc/olay_say` geçerli olay → **204** · listede olmayan olay → **204** (sessizce yok sayılır) · anon `rpc/hesabimi_sil` → **401 / 42501** · anon `GET uygulama_olay` → **401 / 42501** · basım sonrası `dokumanlar` 200. Not: ölçüm 1 adet `ilk_acilis/web` satırı yazdı (sayaçta 1 fazla web açılışı). Ölçülmedi: girişli üyenin kendi hesabını silmesi (uygulamada ilk deneme). |
| `radar-app/sql/2026-09-26-cevap-kayit-test-temizligi.sql` | cevap_kayit açılış öncesi temizliği: TÜM satırlar kilitli yedeğe (`cevap_kayit_yedek_20260926`, RLS açık, anon/authenticated hakkı yok), asıl tablo boşaltıldı. Neden: akran yüzdesi (sik_yuzdesi) yalnız deneme cevabından oluşuyordu (07.09’dan beri günde 2–43, hepsi kaydir-coz). Dar şart denemesi 0 döndü (oturum damgası hiç boş değil) — ölçüm sırası dosyada. | — | ✅ **BASILDI 26.09.2026 (Cem, SQL Editor): yedeklenen 381 · kalan 0.** **Dış ölçüm 26.09 (açık anahtar):** anon GET yedek → **401 / 42501** · rpc sik_yuzdesi → **200 []** · anon GET cevap_kayit → 401 · dokumanlar 200. Geri alma satırı dosyada. Yedek açılıştan ~1 ay sonra silinebilir. |
| `radar-app/sql/2026-09-27-kurucu-sayac.sql` | `kurucu_sayac()` (security definer, stable; anon çağırır): sınav başına ÖDEYEN kurucu sayısı — `siparisler` odendi + `magaza_siparis` verildi/tuketildi; yalnız (sinav, satilan) döner, kişi verisi yok. `fiyat-motoru.js kurucuKalan()` okur, "Kalan kurucu yeri: N" yazar | — | ✅ **BASILDI 01.10.2026 gece (Claude, Chrome ile SQL Editor, Cem "1.2.3 yap").** İçeride: sgs 0 · yeterlilik 0. **Dış ölçüm (açık anahtar):** rpc kurucu_sayac → **200** `[{sgs,0},{yeterlilik,0}]` · anon GET siparisler → **401**. Sitede "Kalan kurucu yeri: 1.000" satırı artık çizilir. |
| `radar-app/sql/2026-10-01-paket-secim-sayac.sql` | `paket_secim_sayac()` (security definer, stable; anon çağırır): paket başına ÖDENMİŞ sipariş sayısı — kurucu_sayac ile aynı tanım; yalnız (paket, satilan), kişi verisi yok. `fiyat-motoru.js enCokSecilen()` okur; ödeme sayfasında Yeterlilik'te ≥30 ödeme + tek başına önde olan pakete "En çok seçilen" | — | ✅ **BASILDI 01.10.2026 gece (Claude, Chrome ile SQL Editor, Cem "1.2.3 yap"; kurucu_sayac ile aynı çalıştırmada).** İçeride: kurucu sgs 0 · yeterlilik 0; paket_secim_sayac 0 satır (ödenmiş sipariş yok). **Dış ölçüm (açık anahtar):** rpc paket_secim_sayac → **200 []** · anon GET siparisler → **401**. **02.10 DÜZELTME + YENİDEN BASIM:** mağaza satırı `urun`dan eşleniyor (magaza_siparis.paket birleşik paket: 1 dersliye 1 ders daha → 'yeterlilik-2'). **Geri alınan prova (DO bloğu + raise, hiçbir şey yazılmadı):** web 'odendi' yeterlilik-1 + mağaza yeterlilik_1 (paket alanı yeterlilik-2) → kurucu_sayac yeterlilik **0 → 2**, paket_secim_sayac **yeterlilik-1=2**; sonra dış ölçüm yine 0 / []. |
| `radar-app/sql/2026-09-30-yedek-geri-yazma-provasi.sql` | GEÇİCİ `prova_geri_yukle` (LIKE soru_havuzu INCLUDING ALL; FK yok, RLS açık, anon/authenticated hakkı yok) — bulut yedeğinin veritabanına geri yazılabildiğini ve süresini ölçmek için. Yazan: `motor/yedek-geri-yazma-provasi.ps1` (hedef `prova_` ile başlamıyorsa durur). Prova bitince dosyadaki DROP ile kaldırılır | — | ✅ **BASILDI ve KALDIRILDI 30.09.2026 (Claude, Chrome ile SQL Editor; "Success. No rows returned").** Dış ölçüm: anon `GET prova_geri_yukle` → **401** · anon `dokumanlar` → 200. Prova: bulut yedeği 23 (15:56) soru_havuzu 30.569 satır **29 sn**'de yazıldı; anahtar eksik 0 / fazla 0; **alan alan içerik farkı 0 / 30.569**. DROP sonrası servis anahtarıyla `prova_geri_yukle` → **404**, soru_havuzu 30.569 · dokumanlar 50.123 yerinde. **YENİDEN BASILDI 30.09.2026 akşam, KALICI + BOŞ** (Cem "1.2.3": aylık robot `.github/workflows/yedek-prova.yml` DDL yapamaz): servis → 200 `*/0` · anon → **401**. Robot her ay yazar, kıyaslar, yeniden boşaltır. |
| `radar-app/sql/2026-10-04-anon-daraltma.sql` | firmalar / markalar / mukellefler: anon rolünden TÜM haklar geri alınır (çift duvar; sayfalar yalnız girişten sonra okuyor). rate_limit_check anon hakkı BİLEREK kalır (5 edge fonksiyonu anon anahtarla çağırıyor; net-cevap fail-closed - kaldırılırsa kapanır) | — | ✅ **BASILDI 04.10.2026 (Cem, SQL Editor).** Basım öncesi dış ölçüm (açık anahtar): üç tabloda anon GET → **200 []**. **Basım sonrası dış ölçüm 04.10:** firmalar / markalar / mukellefler anon GET → **401 / 42501** · dokumanlar → **200** (site okuması etkilenmedi). Ölçülmedi: girişli kullanıcının radar-app / marka-app akışı (yalnız authenticated hakkı, değişmedi). |
| `radar-app/sql/2026-10-04-paket-hediye.sql` | `paket_hediye` kütük tablosu (kime · hangi paket · bitiş · neden · elçi kodu · iptal): RLS açık, politika YOK, anon/authenticated hakkı YOK, auth.users FK YOK. Yazan: `arac/paket-hediye.js` (servis anahtarı, yerel). Paketi açan yine `paket_uyeler`. | — | ✅ **BASILDI — 04.10.2026 akşam Cem.** Dış ölçüm 04.10: anon GET **401** · anon POST **401** · servis anahtarıyla `node arac/paket-hediye.js liste` → "Hediye kütüğü boş." (tablo var, okunuyor). Ölçülmedi: ilk gerçek hediye yazımı (ver) — ilk hediyede ölçülecek. |
| `radar-app/sql/2026-10-04-yonetim-ozet.sql` | `yoneticiler` (user_id; RLS açık, politika yok, anon/authenticated hakkı yok) · `yonetim_ozet()` security definer: çağıran `yoneticiler`de değilse `YETKI_YOK` (42501); üye listesi (auth.users + paket_uyeler + paket_hediye + siparisler + ogrenci_sonuc) + siparişler + elçiler JSON. anon EXECUTE yok. Sayfa: `yonetim.html`. Yönetici satırı dosyada DEĞİL (açık depo), Cem'e ayrı verildi. | — | ✅ **BASILDI — 04.10.2026 akşam Cem** (yönetici satırı dahil, e-posta depoda değil). Dış ölçüm 04.10: anon `rpc/yonetim_ozet` → **401 / 42501** "permission denied" · anon `yoneticiler` GET → **401**. **Girişli yönetici-olmayan üye taklidi (04.10, Cem SQL Editor, request.jwt.claims + role authenticated, rollback):** yonetim_ozet → YETKI_YOK · paket_uyeler gördüğü 0, başkasına ait 0 (tabloda ≥3 satır var) · siparisler / paket_hediye / yoneticiler / auth.users → permission denied · ogrenci_sonuc başkasına ait 0. Ölçülmedi: Cem hesabıyla dolu ekran (ekran görüntüsü bekleniyor). |
| `radar-app/sql/2026-10-05-yonetim-islemleri.sql` | Günlük işler düğmeyle (yonetim.html): `yonetici_mi()` · `yonetim_siparis_onayla(no,bitis)` (odendi + paket_uyeler) · `yonetim_siparis_iptal` · `yonetim_paket_ver` / `yonetim_paket_kapat` (paket_hediye kütüğü) · `yonetim_elci_ekle` (6–12 karakter) / `yonetim_elci_durum`. Hepsi security definer, önce yoneticiler kontrolü, anon EXECUTE yok, satır SİLMEZ. | — | ✅ **OTOMATİK UYGULANDI — 04.10.2026 akşam, sql-uygula.yml koşu 37225826792** (hattın ilk göçü; kayıt `public._goc_kutugu`). Dış ölçüm 04.10: anon ile 6 işlem fonksiyonu → **42501 permission denied** · `yonetici_mi` anon **401** · `_goc_kutugu` anon **401**. Ölçülmedi: düğmelerin Cem hesabıyla gerçek kullanımı. |
| `radar-app/sql/2026-10-05-otomatik-paket.sql` | Ödenmiş sipariş → sonradan üye olana paket OTOMATİK: `siparisler` +`paket_bitis` +`alindi_mail` +`acildi_mail` · `siparis_paket_bagla(uid,eposta)` (anon/authenticated hakkı yok) · `auth.users` AFTER INSERT tetikleyicisi `yeni_uye_paket_bagla` (hata kaydı ENGELLEMEZ, yalnız uyarı) · `yonetim_siparis_onayla` yeniden (bitiş siparişe, paket tek yoldan). | 2026-10-05-yonetim-islemleri.sql içindeki yonetim_siparis_onayla | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-05-soru-not.sql` | `soru_not` (user_id, soru_id, metin ≤1000, guncel; PK user+soru): soru kartındaki 📝 Notum hesapta. RLS: authenticated yalnız kendi satırı (oku/ekle/güncelle/sil), anon hakkı yok, auth.users FK yok. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-05-nobetci-sor.sql` | Nöbetçiye sor + Ekibe sor: `nobetci_soru` (yalnız edge yazar, üye kendi satırını okur) · `ekibe_soru` (üye kendi adına ekler, 24 saatte en çok 5, kendi satırını okur) · `nobetci_durum(uid)` (yalnız servis) · `yonetim_ekip_sorulari` / `yonetim_ekip_cevapla` / `yonetim_nobetci_ozet` (yalnız yönetici). anon erişimi yok, auth.users FK yok. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-05-kart-odeme.sql` | iyzico kart ödemesi: `kart_odemeleri` (her kart denemesi; yalnız servis, anon/authenticated hakkı yok, kart bilgisi YOK) · `kart_siparis_odendi(no, payment_id)` (yalnız servis; iyzico'dan doğrulanmış ödemeden sonra sipariş odendi+odeme=kart+paket_bitis, hesap varsa siparis_paket_bagla; ikinci çağrı ZATEN_ODENDI). Satır silmez. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-05-siparis-iade.sql` | `yonetim_siparis_iade(no, neden)`: yalnız yönetici, yalnız 'odendi' → 'iade'; alıcının o paketi dün tarihiyle kapanır; elçi raporu iadeyi komisyona katmaz; kurucu sayacından düşer. yonetim.html "İade edildi" düğmesi. Satır silmez, anon EXECUTE yok. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-05-hesap-sil-kutuk.sql` | `hesap_sil_kutuk` (zaman, kim uuid, sonuc, hata; e-posta YOK; yalnız servis) + `hesabimi_sil()` aynı silme, her çağrıyı kütüğe yazar, silme hatasını HTTP hatası yerine `{"tamam":false,"neden":"hata","hata":...}` döndürür. Neden: iPhone derleme 30'da "Hesabımı sil" hesap silmedi, sunucu dışarıdan 3 vakada siliyordu. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-06-hatirlatma-ret.sql` | Hatırlatma çıkışı: `hatirlatma_ret` (jeton = HMAC(servis anahtarı, e-posta) 64 hex + zaman; e-posta YOK; yalnız servis okur) + `hatirlatma_ret(p_jeton)` (anon/authenticated yalnız ekler). hatirlatma-ret.html tek tık çıkış; motor/hatirlatma-dizisi.mjs jetonu tabloda olana göndermez. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-07-seviye-kiyas.sql` | Seviye testi kıyası: `seviye_kiyas(p_sinav, p_dogru)` (anon/authenticated EXECUTE; security definer) cevap_kayit'tan biten testleri (aynı oturumda 30-40 cevap) sayar, yalnız n + altında kalan yüzde döndürür; 100 biten test olmadan acik=false. Kişi/oturum/soru dönmez, tabloya okuma hakkı verilmez. | — | ⏳ OTOMATİK — sql-uygula.yml (push'ta). |
| `radar-app/sql/2026-10-08-elci-hesaba-bagla.sql` | Elçiyi yönetim ekranından hesabına bağlama: `yonetim_elci_hesap_bul(eposta)` (bağlamadan önce giriş türü/kayıt/son giriş/başka koda bağlı mı), `yonetim_elci_hesaba_bagla(kod, eposta)`, `yonetim_elci_bagi_coz(kod)`, `yonetim_elci_hesaplar()` (kod · bağlı mı · bağlı e-posta · sözleşme onayı). Hepsi yalnız yönetici (yonetici_mi), anon/public hakkı yok. Bağlama kodu (elci_bagla) yedek yol olarak kalır. Push ile otomatik (sql-uygula.yml). |
| `radar-app/sql/2026-10-08-elci-eposta-google-bag.sql` | Elçi e-postası yönetimden: `yonetim_elci_eposta_yaz(kod, eposta)` (biçim + başka kodda yok denetimi) · `yonetim_elci_hesaplar()` yeniden (kayıtlı e-posta + Instagram da döner) · `elci_google_bagla()` (authenticated; YALNIZ Google sağlayıcılı hesapta, e-postası açık ve bağsız bir elçi kaydında yazılıysa en yeni kodu bağlar; e-posta+şifre hesap kendiliğinden bağlanmaz). Push ile otomatik. |
| `radar-app/sql/2026-10-08-sik-yuzdesi-test-haric.sql` | `sik_yuzdesi(p_soru_id)` aynı imza, yeniden: listedeki test oturumları sayılmaz (08.10: site oturumunun canlı denetimi `pj0d61czmuy98c1i`, ornek-sgs 5 satır). Satır SİLİNMEZ. DDL/tablo yok. Eskitir: 2026-09-06-cevap-kayit.sql'deki sik_yuzdesi tanımı. Push ile otomatik (sql-uygula.yml). |
| `radar-app/sql/2026-10-08-sik-yuzdesi-test-haric-2.sql` | `sik_yuzdesi` yeniden: listeye `os-muytfbpt-r64a4y` (site oturumunun yerel denemesi; beyan A şıkkı = satır). Kanıtsız iki oturum bilerek eklenmedi. Satır silinmez. Eskitir: 2026-10-08-sik-yuzdesi-test-haric.sql. Push ile otomatik. |
| `radar-app/sql/2026-10-08-hesap-sil-eksik-tablolar.sql` | `hesabimi_sil()` aynı imza + kütükle yeniden: nobetci_soru, ekibe_soru (user_id ya da hesabın e-postası), uye_cihazlar da silinir (auth.users'a cascade yoktu). siparisler bilerek kalır (TTK m.82/VUK m.253; saklama-robotu 10 yıl). Önceki tanım 2026-10-05-hesap-sil-kutuk.sql. Push ile otomatik. |
| `radar-app/sql/2026-10-08-gorunum-yazma-kapat.sql` | GÜVENLİK (açılış öncesi denetim 08.10): `soru_havuzu_arsiv_v1` görünümü anon ile okunuyor (30.569) ve PATCH/DELETE 204 dönüyordu (security_invoker yok, revoke yok) → bütün haklar geri + security_invoker. public şemadaki BÜTÜN görünümlerden anon/authenticated INSERT/UPDATE/DELETE/TRUNCATE geri (okuma aynen). Ölçü bloğu: kalan yazma hakkı >0 ise göç geri alınır. Push ile otomatik. |
| `radar-app/sql/2026-10-08-kaynak-sayac.sql` | Link kaynak etiketi (?k=): `kaynak_sayac` (gün, etiket, olay, adet; IP/e-posta/user_id YOK; CHECK: etiket `^[a-z0-9][a-z0-9_-]{0,31}$`, olay ziyaret/test/uye, adet 0–100000; RLS açık, politika yok, anon/authenticated revoke) · `kaynak_uye_sayildi` (yalnız user_id, auth.users cascade) · `kaynak_say(etiket, olay)` anon: yalnız ziyaret/test, satır tavanı 3.000, günde ≤ 60 farklı etiket · `kaynak_uye(etiket)` authenticated: hesap ≤ 2 gün, hesap başına 1 · `yonetim_kaynak(gun)` yalnız yönetici. Göç içi öz-sınav (geri alınır) + `arac/kaynak-sayac-sinavi.sh` (dogrula.yml, gerçek Postgres 22/22, mutasyon 10/10). Push ile otomatik. |
| `radar-app/sql/2026-10-09-kasa-olcer.sql` | KASA ÖLÇER (Cem 09.10 "indiremesin; en iyisi nasıl yapıyorsa aynısı" → UWorld "reasonable use"): `paket_soru`'dan authenticated DOĞRUDAN okuma GERİ (RLS politikası durur). Okuma yalnız `kasa_soru_getir(sayfa, bas, adet≤100)` (sayfa, sıralı, her satırda `toplam`) · `kasa_soru_idler(ids≤100)` · `kasa_dizin(sinav)` (içerik yok, sayılmaz). Paket kuralı `paket_erisim_var(sinav, ders)` = 09-16 politikası birebir. Kütük `kasa_cekim` (user_id, sayfa, bas, adet, IP, zaman; RLS açık, politika yok). TAVAN üye başına: 10 dk 1.500 · 24 sa 4.000 · 7 gün 12.000 → `KASA_TAVAN:<pencere>`; `TAVAN:` satırı adet 0. `uye_sayim()` +`kasa_tavan_24s` +`kasa_asiri_24s` (≥2.500/24 sa) +`kasa_cekim_24s` → `motor/uye-alarmi.ps1` SARI. İstemciler: `kasa-yukle.js`, `sinav-gibi.html`, `mobil/uygulama/{uygulama,uygulama-karma,ortak}.js` (çevrimdışı soru önbelleği KALDIRILDI). Tavan değerleri ÖLÇÜLMEDİ, 2 hafta kütükten ayarlanır. Push ile otomatik. |
| `radar-app/sql/2026-10-10-kasa-tekil-sayim.sql` | KASA SAYACI FARKLI SORU (Cem 10.10 "1 yap"; ilk gün ödeme yapmış üye sayfa açılışlarıyla 3.335 "satır" saydırdı, farklı soru ~1.100): `kasa_cekim` +`tekil` (son 24 saatte bu üyeye ilk kez giden satır) +`ids`. `kasa_cekim_izin2(sayfa,bas,adet,ids)` tavanı tekil toplamıyla sınar (rakamlar AYNI: 10 dk 1.500 · 24 sa 4.000 · 7 gün 12.000; tamamen tekrar çekim durdurulmaz). `kasa_soru_getir`/`kasa_soru_idler` aynı imza; eski `kasa_cekim_izin` düşer. Eski satırlar geriye dönük dolar. `uye_sayim()` `kasa_asiri_24s` tekil, +`kasa_tekil_24s`. Göç içi öz-sınav (sahte üye, geri alınır; 10 vaka). GÖRMEZ: sayfa + idler yolundan aynı soru iki kez sayılır. Push ile otomatik. |
| `radar-app/sql/2026-10-10-elci-erisim-otomatik.sql` | ELÇİ MADDE 10 OTOMATİK (Cem 10.10 "hesap bağlı değil diye ücretsiz üyelik vermedik deme" → "1 yap 2 yap"): `elciler` AFTER INSERT/UPDATE OF user_id tetikleyicisi `elci_erisim_ver()` — aktif elçi hesaba bağlanınca 3 ay `tam` (paket_uyeler + paket_hediye, veren 'otomatik'); bu koda Madde 10 daha önce verildiyse ya da hesabın aktif paketi varsa DOKUNMAZ. `yonetim_elci_hesaplar()` +sozlesme_surum +erisim_paket +erisim_bitis. Göç içi öz-sınav (sahte hesap/elçi, geri alınır; 6 vaka). GÖRMEZ: pasif yapılan elçinin erişimini kapatmaz. Push ile otomatik. |
| `radar-app/sql/2026-10-10-ekibe-soru-eposta.sql` | "Ekibe sor" e-postası boş kalıyordu (ilk soru #1: cevap kaydedildi, öğrenciye mail gitmedi; adres yalnız edge ekip_haber isteğinde yazılıyordu). `ekibe_soru` BEFORE INSERT tetikleyicisi `ekibe_soru_eposta_yaz()` adresi auth.users'tan yazar (istemci değeri yok sayılır) · boş eski kayıtlar doldurulur · `yonetim_ekip_sorulari()` aynı imza +cevap_mail (panelde "E-postayı gönder" düğmesi). Edge ekip_cevap da boş adreste hesaptan okur. Push ile otomatik. |
| `radar-app/sql/2026-10-10-ekibe-soru-goruldu.sql` | "Ekibe sor" cevabı hesapta + bildirim (Cem 10.10): `ekibe_soru` +`cevap_goruldu` · `ekibe_cevap_goruldu()` (authenticated; yalnız KENDİ cevaplanmış satırlarına damga, başka alan değişmez). ogrenci.html "Ekibe sorduğun sorular" bölümü (RLS ile kendi satırları) damgayı vurur; menu.js görülmemiş cevap varsa her sayfada bildirim + Hesabım noktası. Push ile otomatik. |
| `radar-app/sql/2026-10-10-ekibe-soru-hakli.sql` | Ekibe sor panel (Cem 10.10 "1.2.3"): `ekibe_soru` +`itiraz_hakli` (null/true/false) +`itiraz_not` (≤300, açık depoya gider) +`ret_aktarim` · `yonetim_ekip_hakli(id, hakli, not)` yalnız yönetici · `yonetim_ekip_sorulari()` +cevap_goruldu +itiraz alanları · `yonetim_nobetci_ozet()` +ekip_gec (24 saati geçen bekleyen) +ekip_hakli/haksiz/toplam. Haklı → robot ekibe-sor-nobeti.yml `arac/ekip-hakli-aktar.js` ile <sinav>-elle-ret.json + kasa yayını. Push ile otomatik. |
