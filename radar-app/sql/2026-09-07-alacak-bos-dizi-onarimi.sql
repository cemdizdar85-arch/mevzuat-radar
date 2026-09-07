-- ============================================================================
--  ALACAK KASASI: BOS/NULL DIZI SIGORTASI  (07.09.2026)
--
--  NE OLDU: alacak-supabase-yukle.ps1 dizi alani olmayan ilana PowerShell'in
--  @($null) tuzagi yuzunden "[null]" gonderiyordu. alacak_yaz bunu "uzunlugu
--  > 0 olan dizi" sayip kasadaki GERCEK borclular[]/vknler[]/tcknler[]
--  dizilerini eziyordu (07.09 olcumu: 5.643 satir; 04.09 yedeginde bile 2.320
--  satir). alacak_borclu_maskele null ogede `b - 'tckn'` yapinca PostgreSQL
--  "cannot delete from scalar" (22023) verdi -> alacak_ara HTTP 400 -> canli
--  VKN aramasi "Arsiv taramasi yapilamadi" diyordu.
--
--  VERI 07.09 gece PATCH + 04.09 yedeginden geri yazma ile ONARILDI (bkz.
--  hafiza: alacak-bos-dizi-kazasi). Yukleyici de duzeltildi (null gonderir).
--  Bu dosya kasa tarafindaki iki sigortayi kurar; yukleyici bir gun yine
--  "[null]" gonderse bile eski dizi ezilmez ve arama patlamaz.
--
--  Eskittigi tanimlar: 2026-08-20-alacak-metin-alanlari.sql icindeki
--  alacak_borclu_maskele(jsonb) ve alacak_yaz(jsonb). Tablo semasi degismez.
--
--  OLCUM (basildi mi?): asagidaki sorgu 200 ve [] donmeli, 400 DEGIL:
--    curl -s -X POST '.../rest/v1/rpc/alacak_borclu_maskele' -d '{"p":[null]}'
--  (anon anahtarla; fonksiyon anon'a acik). Basilmadiysa 22023 hatasi doner.
-- ============================================================================

-- 1) MASKELEME: null / nesne-olmayan ogeler atlanir; sonuc bosa [] yerine null.
create or replace function public.alacak_borclu_maskele(p jsonb)
returns jsonb
language sql
immutable
as $fn$
  select case when p is null or jsonb_typeof(p) <> 'array' then null else (
    select jsonb_agg(
      case when b ? 'tckn'
        then jsonb_build_object('ad', b->>'ad', 'tckn_var', true)
        else b - 'tckn'
      end)
    from jsonb_array_elements(p) as b
    where jsonb_typeof(b) = 'object'
  ) end;
$fn$;
grant execute on function public.alacak_borclu_maskele(jsonb) to anon, authenticated;

-- 2) YAZMA: dizi ancak icinde GERCEK oge varsa alinir; [null], [], "" -> NULL
--    -> coalesce kasadaki eskisini korur. Geri kalan govde 20.08 ile ayni.
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
      -- 07.09 SIGORTA: yalniz NESNE ogeler sayilir; [null] ve [] -> NULL
      case when jsonb_typeof(k->'borclular') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'borclular') e where jsonb_typeof(e) = 'object')
           then (select jsonb_agg(e) from jsonb_array_elements(k->'borclular') e where jsonb_typeof(e) = 'object')
      end                                            as borclular,
      case when jsonb_typeof(k->'vknler') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'vknler') e where jsonb_typeof(e) = 'string')
           then array(select e #>> '{}' from jsonb_array_elements(k->'vknler') e where jsonb_typeof(e) = 'string')
      end                                            as vknler,
      case when jsonb_typeof(k->'tcknler') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'tcknler') e where jsonb_typeof(e) = 'string')
           then array(select e #>> '{}' from jsonb_array_elements(k->'tcknler') e where jsonb_typeof(e) = 'string')
      end                                            as tcknler
    from jsonb_array_elements(p_kayitlar) as k
    where coalesce(k->>'ilanNo','') <> ''
  ),
  y as (
    insert into public.alacak_ilan
      (ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url,
       borclu, borclu_norm, vkn, tckn, metin, esas_no, sicil_no, mahkeme,
       muhlet_tip, muhlet_ay, muhlet_baslangic, muhlet_bitis, komiser, itiraz_gun,
       borclular, vknler, tcknler, guncelleme)
    select g.ilan_no, g.baslik, g.kurum, g.il, g.ilce, g.tarih, g.tarih_str, g.tur, g.url,
           g.borclu, public.tr_fold(g.borclu), g.vkn, g.tckn, g.metin, g.esas_no, g.sicil_no,
           g.mahkeme, g.muhlet_tip, g.muhlet_ay, g.muhlet_baslangic, g.muhlet_bitis,
           g.komiser, g.itiraz_gun, g.borclular, g.vknler, g.tcknler, now()
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

-- 3) TEYIT (basildiktan sonra SQL editorunde):
--   select public.alacak_borclu_maskele('[null]'::jsonb);            -- null donmeli
--   select public.alacak_borclu_maskele('[{"ad":"X","tckn":"1"}]');  -- [{"ad":"X","tckn_var":true}]
--   select count(*) from public.alacak_ilan where borclular = '[null]'::jsonb;  -- 0
