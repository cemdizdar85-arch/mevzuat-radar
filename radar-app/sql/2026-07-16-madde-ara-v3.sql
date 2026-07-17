-- madde_ara v3 (16.07.2026): v2 "eslesen kelime SAYISI" dedi; bu, nadir kelimeyi
-- ('veraset') yaygin ucluye ('beyanname verme zamani') yenik dusurdu.
-- v3: kelime basina IDF agirligi — nadir kelime agir basar. Formul, sitedeki
-- bilgi-tabani motoruyla ayni: ln((N+1)/(df+1)) + 0.3
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
agir as (
  select to_tsquery('simple', t.w || ':*') as tq,
         ln( ((select count(*) from dokumanlar) + 1)::numeric
           / ((select count(*) from dokumanlar dd
                where dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) + 1) ) + 0.3 as agirlik
  from tok t
),
q as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
)
select d.*
from dokumanlar d, q
where q.orq is not null
  and d.arama_fold @@ q.orq
order by
  (select coalesce(sum(a.agirlik), 0) from agir a where d.arama_fold @@ a.tq) desc,
  ts_rank(d.arama_fold, q.orq) desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- dogrulama: ilk satirda 'Veraset ve Intikal' gormelisin
select kaynak_ad from madde_ara('veraset beyannamesi verme zamani', 3);