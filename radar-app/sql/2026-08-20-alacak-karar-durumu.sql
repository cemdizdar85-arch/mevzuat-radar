-- ============================================================================
--  ALACAK — KARAR DURUMU FILTRESI   (20.08.2026, ucuncu tur)
--
--  Cem: "karar durumu filtresi YAP"
--
--  NIYE: rakip konkordatoilanlari.com ilanlari karar durumuna gore filtreletiyor
--  (gecici muhlet / kesin muhlet / ret), bizde yalniz tur (konkordato|iflas)
--  vardi. Alacakli icin bu ayrim ISIN OZU: gecici muhlette itiraz suresi 7 gun,
--  kesin muhlette alacak kaydi, RET halinde ise konkordato bitmis olabilir.
--
--  DEGER SETI (5.775 ilanin BASLIK dagilimi olculerek cikarildi, uydurulmadi):
--    kesin_muhlet 1361 · gecici_muhlet 1112 · uzatma 722 · ret_kaldirma 703
--    alacak_cagrisi 551 · durusma 513 · diger 505 · iflas_tasfiye 139
--    muhlet 80 (turu belirsiz) · tasdik 42
--
--  OLCULEN TUZAK (kaydedildi ki tekrarlanmasin): ilk surumde durum metinden de
--  turetiliyordu ve "ret" 1.405 ilana basmisti — cunku GECICI MUHLET ilaninin
--  standart cumlesi "…konkordato talebinin REDDINI isteyebilecekleri" (IIK
--  m.288). Yani muhlet verilmis ilan "reddedilmis" gorunuyordu. Artik ret /
--  kaldirma / tasdik / iflas YALNIZ BASLIKTAN belirlenir.
--
--  KOSMA: Supabase SQL editorunde bir kez, sonra alacak-supabase-yukle.ps1.
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 1/3
alter table public.alacak_ilan add column if not exists karar_durumu text;
create index if not exists alacak_karar_idx on public.alacak_ilan (karar_durumu, tarih desc);

-- ---------------------------------------------------------------- BOLUM 2/3
--  YAZMA UCU: karar_durumu da tasinsin (zenginlestirme korumasi ayni)
create or replace function public.alacak_yaz(p_kayitlar jsonb)
returns int
language plpgsql
security definer
set search_path = public
as $fn$
declare n int;
begin
  with g as (
    select
      k->>'ilanNo'                                   as ilan_no,
      nullif(btrim(coalesce(k->>'baslik','')),'')    as baslik,
      nullif(btrim(coalesce(k->>'kurum','')),'')     as kurum,
      nullif(btrim(coalesce(k->>'il','')),'')        as il,
      nullif(btrim(coalesce(k->>'ilce','')),'')      as ilce,
      to_date(nullif(k->>'tarih',''), 'DD.MM.YYYY')  as tarih,
      nullif(k->>'tarih','')                         as tarih_str,
      nullif(k->>'tur','')                           as tur,
      nullif(k->>'url','')                           as url,
      nullif(btrim(coalesce(k->>'borclu','')),'')    as borclu,
      nullif(regexp_replace(coalesce(k->>'vkn',''),'\D','','g'),'')  as vkn,
      nullif(regexp_replace(coalesce(k->>'tckn',''),'\D','','g'),'') as tckn,
      nullif(btrim(coalesce(k->>'metin','')),'')     as metin,
      nullif(btrim(coalesce(k->>'esas_no','')),'')   as esas_no,
      nullif(btrim(coalesce(k->>'sicil_no','')),'')  as sicil_no,
      nullif(btrim(coalesce(k->>'mahkeme','')),'')   as mahkeme,
      nullif(btrim(coalesce(k->>'muhlet_tip','')),'') as muhlet_tip,
      nullif(k->>'muhlet_ay','')::int                as muhlet_ay,
      nullif(k->>'muhlet_baslangic','')::date        as muhlet_baslangic,
      nullif(k->>'muhlet_bitis','')::date            as muhlet_bitis,
      nullif(btrim(coalesce(k->>'komiser','')),'')   as komiser,
      nullif(k->>'itiraz_gun','')::int               as itiraz_gun,
      nullif(btrim(coalesce(k->>'karar_durumu','')),'') as karar_durumu,
      case when jsonb_typeof(k->'borclular') = 'array' and jsonb_array_length(k->'borclular') > 0
           then k->'borclular' end                   as borclular,
      case when jsonb_typeof(k->'vknler') = 'array' and jsonb_array_length(k->'vknler') > 0
           then array(select jsonb_array_elements_text(k->'vknler')) end  as vknler,
      case when jsonb_typeof(k->'tcknler') = 'array' and jsonb_array_length(k->'tcknler') > 0
           then array(select jsonb_array_elements_text(k->'tcknler')) end as tcknler
    from jsonb_array_elements(p_kayitlar) as k
    where coalesce(k->>'ilanNo','') <> ''
  ),
  y as (
    insert into public.alacak_ilan
      (ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url,
       borclu, borclu_norm, vkn, tckn, metin, esas_no, sicil_no, mahkeme,
       muhlet_tip, muhlet_ay, muhlet_baslangic, muhlet_bitis, komiser, itiraz_gun,
       karar_durumu, borclular, vknler, tcknler, guncelleme)
    select g.ilan_no, g.baslik, g.kurum, g.il, g.ilce, g.tarih, g.tarih_str, g.tur, g.url,
           g.borclu, public.tr_fold(g.borclu), g.vkn, g.tckn, g.metin, g.esas_no, g.sicil_no,
           g.mahkeme, g.muhlet_tip, g.muhlet_ay, g.muhlet_baslangic, g.muhlet_bitis,
           g.komiser, g.itiraz_gun, g.karar_durumu, g.borclular, g.vknler, g.tcknler, now()
    from g
    on conflict (ilan_no) do update set
      baslik      = coalesce(excluded.baslik,  alacak_ilan.baslik),
      kurum       = coalesce(excluded.kurum,   alacak_ilan.kurum),
      il          = coalesce(excluded.il,      alacak_ilan.il),
      ilce        = coalesce(excluded.ilce,    alacak_ilan.ilce),
      tarih       = coalesce(excluded.tarih,   alacak_ilan.tarih),
      tarih_str   = coalesce(excluded.tarih_str, alacak_ilan.tarih_str),
      tur         = coalesce(excluded.tur,     alacak_ilan.tur),
      url         = coalesce(excluded.url,     alacak_ilan.url),
      borclu      = coalesce(excluded.borclu,  alacak_ilan.borclu),
      borclu_norm = coalesce(excluded.borclu_norm, alacak_ilan.borclu_norm),
      vkn         = coalesce(excluded.vkn,     alacak_ilan.vkn),
      tckn        = coalesce(excluded.tckn,    alacak_ilan.tckn),
      metin       = coalesce(excluded.metin,   alacak_ilan.metin),
      esas_no     = coalesce(excluded.esas_no, alacak_ilan.esas_no),
      sicil_no    = coalesce(excluded.sicil_no, alacak_ilan.sicil_no),
      mahkeme     = coalesce(excluded.mahkeme, alacak_ilan.mahkeme),
      muhlet_tip  = coalesce(excluded.muhlet_tip, alacak_ilan.muhlet_tip),
      muhlet_ay   = coalesce(excluded.muhlet_ay,  alacak_ilan.muhlet_ay),
      muhlet_baslangic = coalesce(excluded.muhlet_baslangic, alacak_ilan.muhlet_baslangic),
      muhlet_bitis     = coalesce(excluded.muhlet_bitis,     alacak_ilan.muhlet_bitis),
      komiser     = coalesce(excluded.komiser, alacak_ilan.komiser),
      itiraz_gun  = coalesce(excluded.itiraz_gun, alacak_ilan.itiraz_gun),
      -- karar_durumu SINIFLAMADIR: kural duzelirse yeni deger ESKIYI EZER
      -- (coalesce degil). 20.08'de "ret" kusuru boyle duzeltilebildi.
      karar_durumu = coalesce(excluded.karar_durumu, alacak_ilan.karar_durumu),
      borclular   = coalesce(excluded.borclular, alacak_ilan.borclular),
      vknler      = coalesce(excluded.vknler,  alacak_ilan.vknler),
      tcknler     = coalesce(excluded.tcknler, alacak_ilan.tcknler),
      guncelleme  = now()
    returning 1
  )
  select count(*) into n from y;
  return n;
end;
$fn$;
revoke all on function public.alacak_yaz(jsonb) from anon, authenticated, public;
grant execute on function public.alacak_yaz(jsonb) to service_role;

-- ---------------------------------------------------------------- BOLUM 3/3
--  VITRIN: karar durumu sayaclari (TUM arsiv) + istege bagli durum suzgeci.
--  Sayac tum arsivden gelir ama SATIR yine 60 tavanli — vitrin dataset degildir.
--  p_durum verilirse o durumun son 60 ilani doner (kullanici filtreye basinca).
drop function if exists public.alacak_vitrin();
create or replace function public.alacak_vitrin(p_durum text default null)
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select jsonb_build_object(
    'adet',    (select count(*) from public.alacak_ilan),
    'son30',   (select count(*) from public.alacak_ilan where tarih >= current_date - 30),
    'son30Konkordato', (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='konkordato'),
    'son30Iflas',      (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='iflas'),
    -- 20.08: karar durumu sayaclari — filtre dugmelerinin yanindaki rakamlar
    -- BURADAN basilir; sayfaya gomulu rakam yazilmaz (rakam disiplini).
    'durumlar', coalesce((
      select jsonb_object_agg(d.k, d.n)
      from (
        select coalesce(karar_durumu,'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) d
    ), '{}'::jsonb),
    'iller', coalesce((
      select jsonb_agg(jsonb_build_object('il', g.il_ad, 't', g.t, 'k', g.k, 'i', g.i)
                       order by g.t desc)
      from (
        select coalesce(nullif(il,''),'Belirtilmemiş') as il_ad,
               count(*)                                as t,
               count(*) filter (where tur='konkordato') as k,
               count(*) filter (where tur='iflas')      as i
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
        order by 2 desc
        limit 12
      ) g
    ), '[]'::jsonb),
    'ilanlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'ilanNo', ilan_no, 'baslik', baslik, 'kurum', kurum, 'il', il,
        'tarih', tarih_str, 'tur', tur, 'url', url, 'borclu', borclu, 'vkn', vkn,
        'karar', karar_durumu, 'muhletBitis', muhlet_bitis
      ) order by tarih desc nulls last)
      from (
        select * from public.alacak_ilan
        where p_durum is null or coalesce(karar_durumu,'diger') = p_durum
        order by tarih desc nulls last limit 60
      ) v
    ), '[]'::jsonb)
  )
$fn$;
grant execute on function public.alacak_vitrin(text) to anon, authenticated;
