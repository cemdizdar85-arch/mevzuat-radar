-- ============================================================================
--  AMBAR INDEKSLERI — madde arama ve kaynak filtresi 500 vermesin (30.08.2026)
--
--  CEM (30.08): "madde goruntuleyici sayfa — ambardaki 43.440 parcayi ilk kez
--  kullaniciya acar."  Sayfa yazilmadan ONCE altyapi olculdu ve TIKALI cikti.
--
--  OLCUM (anon anahtarla, canli uctan):
--    GET /dokumanlar?select=id&limit=1                        -> 200  (hizli)
--    GET /dokumanlar?tur=eq.kanun-madde&limit=3               -> 200  (hizli)
--    GET /dokumanlar?kaynak_ad=eq.<5973 s. Karar>&limit=3     -> 500  57014
--    GET /dokumanlar?tur=eq.kanun-madde&kaynak_ad=eq.<...>    -> 500  4.4 sn
--    POST /rpc/madde_ara {"sorgu":"ihracat & destek"}         -> 500  8.1 sn
--  Yani: 'tur' filtresi calisiyor, 'kaynak_ad' iceren HER sorgu ve tam metin
--  aramasinin TAMAMI zaman asimina dusuyor. Hafizadaki "madde_ara 500" kusuru
--  budur ve sebebi olculdu: bu iki sutunda indeks yok, 43.440 satir tam
--  taraniyor.
--
--  madde_ara v4'un kendi yorumu (16.07) "13 bin satirin tamamini puanlamak
--  zaman asimi verdi" diyor ve iki asamali hale getirilmisti. Ambar o gunden
--  bugune 13 bin -> 43.440 buyudu; v4'un ts_rank adaylama adimi da artik
--  indekssiz calisamiyor.
--
--  BU GOC UC INDEKS BASAR (tablo yapisi DEGISMEZ, veri DEGISMEZ):
--    1) arama_fold GIN   -> madde_ara'nin @@ operatoru ve IDF alt sorgulari
--    2) kaynak_ad        -> "bu kaynagin maddelerini getir" (madde goruntuleyici,
--                           Destek Radari dayanak bagi)
--    3) tur + kaynak_ad  -> ikisiyle birlikte daraltan sorgular
--
--  CONCURRENTLY: canli tabloyu KILITLEMEZ. Supabase SQL editorunde her satiri
--  TEK TEK calistir - concurrently transaction blogu icinde calismaz, hepsini
--  birden yapistirirsan "CREATE INDEX CONCURRENTLY cannot run inside a
--  transaction block" hatasi alirsin.
--
--  BASILDIKTAN SONRA OLCUM (kabul kriteri): asagidaki dogrulama bolumu.
--  Ucu de 200 donmeden madde goruntuleyici sayfa YAZILMAZ - test edilemeyen
--  sayfa yayinlanmaz.
-- ============================================================================

-- 1) Tam metin arama (madde_ara). En kritik olan bu: fonksiyon her token icin
--    tum tabloda @@ sayimi yapiyor, indekssiz her cagri tam tarama demek.
create index concurrently if not exists dokumanlar_arama_fold_gin
  on public.dokumanlar using gin (arama_fold);

-- 2) Kaynak bazli okuma: "5973 s. Karar'in maddeleri" gibi sorgular.
create index concurrently if not exists dokumanlar_kaynak_ad_idx
  on public.dokumanlar (kaynak_ad);

-- 3) Tur + kaynak birlikte daraltma (envanter ve goruntuleyici bu ikisini
--    birlikte kullaniyor).
create index concurrently if not exists dokumanlar_tur_kaynak_idx
  on public.dokumanlar (tur, kaynak_ad);

-- (istege bagli, indeksler basildiktan sonra) planlayiciya taze istatistik:
-- analyze public.dokumanlar;

-- ============================================================================
--  DOGRULAMA — bu ucu de HATASIZ ve HIZLI donmeli
-- ============================================================================
-- (a) kaynak bazli okuma
select count(*) as madde_sayisi
from public.dokumanlar
where kaynak_ad = 'Ihracat Destekleri Hakkinda Karar (5973 s. CB Karari)';
-- beklenen: 59 (30.08 envanter olcumu)

-- (b) tam metin arama
select kaynak_ad from public.madde_ara('ihracat destegi', 3);
-- beklenen: 3 satir, hata yok

-- (c) indeksler yerinde mi
select indexname from pg_indexes
where schemaname = 'public' and tablename = 'dokumanlar'
order by indexname;
-- beklenen: dokumanlar_arama_fold_gin · dokumanlar_kaynak_ad_idx ·
--           dokumanlar_tur_kaynak_idx (+ mevcut olanlar)
