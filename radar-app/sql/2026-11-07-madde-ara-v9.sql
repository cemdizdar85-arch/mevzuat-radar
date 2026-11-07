-- ============================================================================
-- madde_ara v9 (07.11.2026, A-11, Cem onayi "temizse canliya al") — canli madde_ara = madde_ara_deneme ayari
--   {"adw":0,"tebw":0.75} (radar-app/sql/2026-10-11-madde-ara-deneme-1..5).
-- NEDEN (olculdu 07.11): altin test kaynak duzeyi 42/48 (taban 45; 01.09'dan beri 5 vaka, 01-08.10 arasi Anayasa m.73):
--   ilk 6'yi GVK/VUK genel tebligleri, KDV GUT, SPK tebligleri, BDDK THP, TFRS/BDS parcalari dolduruyor.
-- OLCU (07.11, canli ambar, salt okuma): altin test deneme 47/48 (v8 42/48), madde 1/8 (v8 2/8; kayip IIK m.287 -> ayni
--   bolumden m.288/m.289 geliyor, m.287 adi basliksiz = A-11 artigi). Test disi 16 sorgu: v8 11/16, deneme 14/16, KAYIP 0,
--   KAZANC 3 (uzlasma ceza indirimi, OTV binek oran, vergi ziyai orani).
-- GERI DONUS: v8 govdesi AYNEN madde_ara_v8 olarak korunur (anon/uye yetkisi yok); geri almak icin yeni goc:
--   create or replace function public.madde_ara(sorgu text, adet integer default 6) returns setof dokumanlar language sql stable
--   as $$ select * from public.madde_ara_v8(sorgu, adet) $$;
-- BU GOC SUNU GORMEZ: madde_ara kullanan istemcilerin sonuc beklentisi (siralama degisir) · test disi 16 sorgu disindaki sorgular.
-- ============================================================================

-- 1) v8 yedegi (birebir)
CREATE OR REPLACE FUNCTION public.madde_ara_v8(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
AS $function$
with tok as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
-- belge frekansi: 'cikmis%' disi ambarda kac belge bu jetonu iceriyor
df as (
  select t.w,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select w,
         to_tsquery('simple', w || ':*') as tq,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
-- (1) DAR HAVUZ: yalniz ayirt edici jetonlar aday uretir
secili as (
  select w from df where adet_df <= 1500 order by adet_df asc limit 4
),
secili2 as (
  select w from secili
  union all
  select w from (select w from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from secili2
),
qtum as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
),
aday as (
  select d.ctid as rid, d.arama_fold as af, d.tur as tur,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by r desc
  limit 300
),
puan as (
  select a.rid, a.r,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s,
         (select count(*) from agir g where a.af @@ g.tq) as kapsanan,
         case a.tur
           when 'teori-notu'    then 0.55
           when 'standart-madde' then 0.85   -- (2) v7'de 'standart' yaziyordu: OLU DAL
           else 1.0
         end as turw
  from aday a
)
select d.* from dokumanlar d
join puan p on d.ctid = p.rid
order by (p.s * p.turw * (1 + 0.35 * greatest(p.kapsanan - 1, 0))) desc, p.r desc
limit greatest(coalesce(adet,6),1)
$function$;
revoke execute on function public.madde_ara_v8(text, integer) from public, anon, authenticated;

-- 2) canli madde_ara = deneme ayari (imza, donus, invoker AYNI)
CREATE OR REPLACE FUNCTION public.madde_ara(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{"adw":0,"tebw":0.75}'::jsonb) p
join dokumanlar d on d.id = p.id
order by p.puan desc, p.r desc
$function$;

-- 3) goc ici olcu: tutmazsa butun goc geri alinir
do $$ begin
  if not exists (select 1 from public.madde_ara('anayasaya gore vergi odevi', 6) where kaynak_ad like 'Anayasa (2709)%') then
    raise exception 'madde_ara v9 olcusu tutmadi: Anayasa ilk 6da yok';
  end if;
  if not exists (select 1 from public.madde_ara_v8('anayasaya gore vergi odevi', 6)) then raise exception 'madde_ara_v8 yedegi bos'; end if;
end $$;
