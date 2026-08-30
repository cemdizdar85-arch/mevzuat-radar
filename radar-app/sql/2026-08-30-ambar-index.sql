-- ============================================================================
--  AMBAR INDEKSLERI — madde arama ve kaynak filtresi 500 vermesin (30.08.2026)
--
--  ⭐ BU DOSYAYI KOMPLE KOPYALA, Supabase > SQL Editor'e yapistir, bir kez Run.
--     Baska bir sey yapmana gerek yok.
--
--  🔴 30.08 KUSUR VE DUZELTME: ilk surumde calisan satirlar
--     "create index CONCURRENTLY" idi. Supabase SQL Editor her calistirmayi
--     TRANSACTION'a sarar ve concurrently orada CALISMAZ - panel
--     "CREATE INDEX CONCURRENTLY cannot run inside a transaction block"
--     der ve HICBIR INDEKS BASILMAZ. Cem bastigini soyledi, olcum yine 500
--     dondu; sebep buydu. Kolay yolu YORUM icine yazmak da benim kusurumdu:
--     dosyayi yapistiran kisi yorumlari degil, calisan satirlari basar.
--     Artik calisan satirlar CONCURRENTLY'SIZ. Tablo kisa sure kilitlenir;
--     43.440 satirda GIN indeksi birkac dakika surebilir, bu NORMALDIR -
--     bitene kadar okuma sorgulari yavaslar ya da zaman asimi verebilir.
--
--  NEDEN GEREKLI - OLCUM (anon anahtarla, canli uctan):
--    GET /dokumanlar?select=id&limit=1                        -> 200  hizli
--    GET /dokumanlar?tur=eq.kanun-madde&limit=3               -> 200  hizli
--    GET /dokumanlar?kaynak_ad=eq.<5973 s. Karar>&limit=3     -> 500  57014
--    GET /dokumanlar?tur=eq...&kaynak_ad=eq.<...>             -> 500  57014
--    POST /rpc/madde_ara {"sorgu":"ihracat & destek"}         -> 500  57014
--  madde_ara HIC DEVREDE DEGILKEN tek satirlik kaynak_ad esitligi bile zaman
--  asimina dusuyor. SERVIS ANAHTARIYLA da ayni sonuc - yani RLS degil.
--  Goc kutugu "madde_ara sekiz surum yazildi, timeout hala oluyor" diyordu:
--  sorun FONKSIYONDA DEGIL, INDEKSTE. Ambar 13 binden 43.440 parcaya buyudu;
--  kaynak_ad ve arama_fold sutunlarinda indeks yok, her sorgu tam tarama.
--  tur filtresinin calismasi da bunu dogruluyor (onda indeks var).
--
--  Tablo yapisi DEGISMEZ, veri DEGISMEZ. Geri almak: drop index <ad>;
-- ============================================================================

-- 1) Tam metin arama (madde_ara'nin kalbi). Fonksiyon her token icin tum
--    tabloda @@ sayimi yapiyor; indekssiz her cagri tam tarama demek.
create index if not exists dokumanlar_arama_fold_gin
  on public.dokumanlar using gin (arama_fold);

-- 2) Kaynak bazli okuma: "5973 s. Karar'in maddeleri" gibi sorgular.
--    Madde goruntuleyici sayfa ve Destek Radari dayanak bagi bunu kullanacak.
create index if not exists dokumanlar_kaynak_ad_idx
  on public.dokumanlar (kaynak_ad);

-- 3) Tur + kaynak birlikte daraltma.
create index if not exists dokumanlar_tur_kaynak_idx
  on public.dokumanlar (tur, kaynak_ad);

-- planlayiciya taze istatistik
analyze public.dokumanlar;

-- ============================================================================
--  DOGRULAMA — Run'dan sonra bunlar da calisir; ciktilari bana soyle
-- ============================================================================

-- (a) indeksler yerinde mi? Uc yeni ad listede gorunmeli:
--     dokumanlar_arama_fold_gin · dokumanlar_kaynak_ad_idx · dokumanlar_tur_kaynak_idx
select indexname from pg_indexes
where schemaname = 'public' and tablename = 'dokumanlar'
order by indexname;

-- (b) kaynak bazli okuma (beklenen: 59 - 30.08 envanter olcumu)
select count(*) as madde_sayisi
from public.dokumanlar
where kaynak_ad = 'Ihracat Destekleri Hakkinda Karar (5973 s. CB Karari)';

-- (c) tam metin arama (beklenen: 3 satir, hata yok)
select kaynak_ad from public.madde_ara('ihracat destegi', 3);

-- ============================================================================
--  psql / Supabase CLI ile basacaklar icin (panelde DEGIL):
--    create index concurrently if not exists dokumanlar_arama_fold_gin
--      on public.dokumanlar using gin (arama_fold);
--    create index concurrently if not exists dokumanlar_kaynak_ad_idx
--      on public.dokumanlar (kaynak_ad);
--    create index concurrently if not exists dokumanlar_tur_kaynak_idx
--      on public.dokumanlar (tur, kaynak_ad);
--  concurrently tabloyu kilitlemez ama transaction disinda calistirilmalidir.
-- ============================================================================
