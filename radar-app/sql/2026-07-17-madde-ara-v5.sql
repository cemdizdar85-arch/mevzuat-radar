-- madde_ara v5 (17.07.2026): v4'un zaafi — 'vergi' gibi binlerce belgede gecen
-- kelime sorguya girince aday taramasi 3 sn'lik statement_timeout'a takiliyordu
-- (57014). v5: ADAY HAVUZU yalniz AYIRT EDICI kelimelerden kurulur (df<=1500;
-- hic yoksa en nadir 2). Yaygin kelimeler adayliktan cikar ama PUANLAMADA kalir
-- (IDF agirligi + ts_rank). Boylece 'anayasaya gore vergi odevi' m.73'u bulur,
-- 'vergi' tek basina gelse bile sorgu 3 sn'yi asamaz (aday limiti 3000).
create or replace function public.madde_ara(sorgu text, adet integer default 6)
returns setof dokumanlar
language sql stable
as $fn$
with tok as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
df as (
  select t.w,
         (select count(*) from dokumanlar dd
           where dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select w,
         to_tsquery('simple', w || ':*') as tq,
         ln( ((select count(*) from dokumanlar) + 1)::numeric / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
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
  select d.ctid as rid, d.arama_fold as af
  from dokumanlar d, qdar
  where qdar.orq is not null
    and d.arama_fold @@ qdar.orq
  limit 3000
),
puan as (
  select a.rid,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s,
         ts_rank(a.af, (select orq from qtum)) as r
  from aday a
)
select d.* from dokumanlar d
join puan p on d.ctid = p.rid
order by p.s desc, p.r desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- dogrulama 1: ilk 3'te 'Anayasa (2709) m.73' bekleniyor
select kaynak_ad from madde_ara('anayasaya gore vergi odevi nedir', 3);
