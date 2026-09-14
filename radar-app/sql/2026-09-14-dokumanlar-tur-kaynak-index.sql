-- ============================================================================
--  DOKUMANLAR — tur ve kaynak_ad indeksleri (14.09.2026)
--
--  ⭐ BU DOSYAYI KOMPLE KOPYALA, Supabase > SQL Editor'e yapistir, bir kez Run.
--
--  2026-08-30-ambar-index.sql'IN YERINE GECER. O dosya hic basilmadi; 14.09
--  08:10'da panelde pg_indexes okundu (salt okuma) ve dokumanlar'da yalniz su
--  uc indeks vardi:
--     dokuman_arama_idx          gin (arama)
--     dokumanlar_arama_fold_idx  gin (arama_fold)   <- 30.08 dosyasinin 1. maddesi ZATEN VAR, baska adla
--     dokumanlar_pkey            btree (id)
--  30.08 dosyasi basilsaydi arama_fold icin IKINCI bir GIN kurardi (disk 5,75/8 GB dolu).
--  Bu dosya yalniz EKSIK olan iki btree indeksini basar.
--
--  NEDEN SIMDI: 13.09 23:21 ve 14.09 00:04-00:30 arasinda
--    GET /dokumanlar?select=id&tur=eq.cikmis-soru&limit=1   -> 22-24 sn, 500 57014
--  tur ve kaynak_ad icin indeks olmadigindan her tur=/kaynak_ad= okumasi tabloyu
--  (334 MB) tam tariyor. Uretici kapilari (KAPI-CB, capa havuzu, KAPI-K sozlugu)
--  ve dayanak haritasi bu sorgulari her koşuda atiyor; ambar yogunken koşular
--  kaynaksiz basildi (sgs-gm5-mat-r7, r8 cope gitti).
--
--  SURE/KILIT: 44 bin satirda btree birkac saniye. concurrently'siz basilir
--  (SQL Editor transaction'a sarar, concurrently orada calismaz - 30.08 dersi).
--  Kurulum sirasinda tabloya YAZMA birkac saniye bekler, okuma surer.
--  Tablo yapisi ve veri DEGISMEZ. Geri almak: drop index <ad>;
-- ============================================================================

create index if not exists dokumanlar_tur_kaynak_idx
  on public.dokumanlar (tur, kaynak_ad);

create index if not exists dokumanlar_kaynak_ad_idx
  on public.dokumanlar (kaynak_ad);

analyze public.dokumanlar;

-- ============================================================================
--  DOGRULAMA — ayni Run'da doner. Listede 5 ad olmali:
--  dokuman_arama_idx · dokumanlar_arama_fold_idx · dokumanlar_kaynak_ad_idx ·
--  dokumanlar_pkey · dokumanlar_tur_kaynak_idx
-- ============================================================================
select indexname from pg_indexes
where schemaname = 'public' and tablename = 'dokumanlar'
order by indexname;
