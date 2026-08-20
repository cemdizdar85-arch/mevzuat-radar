-- ============================================================================
--  ALACAK ILAN — METIN VE YAPILANDIRILMIS ALANLAR   (20.08.2026)
--
--  Cem: "ilan aciklamasi bu kadar mi, neden batti vs bulamiyor muyuz"
--
--  OLCULEN KUSUR: ilan.gov.tr detay metni cekiliyor ama saklanmiyordu; ambarda
--  yalniz kunye vardi. Canli havuzda 400 kaydin 147'sinde borclu adi bostu —
--  Cem'in gonderdigi EFESAH ilani dahil (unvan metinde apacik yaziliyken
--  kayitta borclu=null).
--
--  BU BETIK NE YAPAR: metni + ilanin KENDISINDE yazan alanlari saklar.
--  "Neden batti" hicbir resmi ilanda yazmaz (IIK m.288 ilani hukuki bildirimdir,
--  gerekce degil). Saklanabilecek olan, borclunun SURECTEKI YERIdir:
--  hangi mahkeme/dosya, muhlet ne zaman basladi, ne zaman doluyor, komiser kim,
--  itiraz suresi kac gun.
--
--  *** GIZLILIK KARARI (19.08 dersinin devami: "cevabin kendisi de maskelenmeli")
--  Ham ilan metni TCKN icerir. metin kolonu DISARIYA HIC DONMEZ — alacak_ara
--  yalniz ayristirilmis alanlari dondurur, borclular listesi de ad+VKN'e
--  indirgenerek doner (tckn alani sunucuda silinir). Metin ambarda yalniz
--  arama/ayristirma icin durur.
--
--  KOSMA: Supabase SQL editorunde bir kez. Once bu, sonra
--         $env:HEDEF='veri\alacak-ilan-canli.json'; ./motor/alacak-supabase-yukle.ps1
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 1/5
--  YENI KOLONLAR (hepsi nullable: eski satirlar bozulmaz)
alter table public.alacak_ilan add column if not exists metin            text;
alter table public.alacak_ilan add column if not exists esas_no          text;
alter table public.alacak_ilan add column if not exists sicil_no         text;
alter table public.alacak_ilan add column if not exists mahkeme          text;
alter table public.alacak_ilan add column if not exists muhlet_tip       text;   -- gecici / kesin / uzatma
alter table public.alacak_ilan add column if not exists muhlet_ay        int;
alter table public.alacak_ilan add column if not exists muhlet_baslangic date;
alter table public.alacak_ilan add column if not exists muhlet_bitis     date;
alter table public.alacak_ilan add column if not exists komiser          text;
alter table public.alacak_ilan add column if not exists itiraz_gun       int;
-- Grup konkordatosunda tek ilanda birden cok borclu olur (olculdu: Istanbul
-- 2. ATM ilani 3 borclu, Kastamonu ilani 6 borclu). Eski "tek VKN varsa yaz"
-- kurali bunlarin hepsini eliyordu.
alter table public.alacak_ilan add column if not exists borclular        jsonb;  -- [{ad,vkn}|{ad,tckn}]
alter table public.alacak_ilan add column if not exists vknler           text[];
alter table public.alacak_ilan add column if not exists tcknler          text[]; -- DISARIYA HIC DONMEZ

-- Ikinci/ucuncu borclunun VKN'si de aranabilsin diye dizi indeksi
create index if not exists alacak_vknler_idx on public.alacak_ilan using gin (vknler);
create index if not exists alacak_muhlet_idx on public.alacak_ilan (muhlet_bitis) where muhlet_bitis is not null;

-- ---------------------------------------------------------------- BOLUM 2/5
--  YAZMA UCU: yeni alanlar + ZENGINLESTIRME KORUMASI (bos gelen eskisini silmez)
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
      -- ZENGINLESTIRME KORUMASI: bos gelen alan eskisini SILMEZ
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

-- ---------------------------------------------------------------- BOLUM 3/5 (once tanimlanir: BOLUM 4 bunu cagirir)
--  MASKELEME: borclular listesi disariya ad+VKN olarak cikar; TCKN sunucuda
--  silinir, sahis borclu "tckn_var: true" ile isaretlenir (ekranda maskeli
--  gosterilsin diye). 19.08 dersi: cevabin kendisi de maskelenmeli.
create or replace function public.alacak_borclu_maskele(p jsonb)
returns jsonb
language sql
immutable
as $fn$
  select case when p is null then null else (
    select coalesce(jsonb_agg(
      case when b ? 'tckn'
        then jsonb_build_object('ad', b->>'ad', 'tckn_var', true)
        else b - 'tckn'
      end), '[]'::jsonb)
    from jsonb_array_elements(p) as b
  ) end;
$fn$;
grant execute on function public.alacak_borclu_maskele(jsonb) to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 4/5
--  ARAMA: yeni alanlari dondurur + grup konkordatosunda IKINCI/UCUNCU borclunun
--  VKN'siyle de bulur. Donus tipi degistigi icin once dusurulur.
drop function if exists public.alacak_ara(text);
create or replace function public.alacak_ara(p_sorgu text)
returns table (
  ilan_no text, baslik text, kurum text, il text, ilce text,
  tarih_str text, tur text, url text, borclu text, vkn text, tip text,
  esas_no text, mahkeme text, muhlet_tip text, muhlet_ay int,
  muhlet_baslangic date, muhlet_bitis date, komiser text, itiraz_gun int,
  borclular jsonb
)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  s     text := btrim(coalesce(p_sorgu,''));
  say   text := regexp_replace(s, '\D', '', 'g');
  ad    text := btrim(public.tr_fold(s));
  ip    text := coalesce(
                  split_part(current_setting('request.headers', true)::json->>'x-forwarded-for', ',', 1),
                  '');
begin
  if ip <> '' and not public.rate_limit_check('alacak:'||ip, 20, 60) then
    raise exception 'COK_HIZLI' using hint = 'Dakikada en fazla 20 sorgu.';
  end if;

  if length(say) >= 7 then
    return query
      select i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih_str, i.tur, i.url,
             i.borclu, i.vkn, 'vkn'::text,
             i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
             i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun,
             public.alacak_borclu_maskele(i.borclular)
      from public.alacak_ilan i
      where (i.vkn is not null and (i.vkn = say or i.vkn like say||'%' or say like i.vkn||'%'))
         or (i.vknler is not null and say = any(i.vknler))
         or (i.tckn is not null and length(say) = 11 and i.tckn = say)
         or (i.tcknler is not null and length(say) = 11 and say = any(i.tcknler))
      order by i.tarih desc nulls last
      limit 25;
  elsif length(ad) >= 8 or array_length(regexp_split_to_array(ad, ' '), 1) >= 2 then
    if length(ad) < 5 then
      raise exception 'KISA_SORGU' using hint = 'En az 5 harf ya da iki kelime yaz.';
    end if;
    return query
      select i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih_str, i.tur, i.url,
             i.borclu, i.vkn, 'ad'::text,
             i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
             i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun,
             public.alacak_borclu_maskele(i.borclular)
      from public.alacak_ilan i
      where i.borclu_norm is not null and i.borclu_norm like '%'||ad||'%'
      order by i.tarih desc nulls last
      limit 25;
  else
    raise exception 'KISA_SORGU'
      using hint = 'Tam VKN/TCKN ya da en az iki kelimelik unvan yaz (tek kelime yanlis firma getirir).';
  end if;
end;
$fn$;
grant execute on function public.alacak_ara(text) to anon, authenticated;
