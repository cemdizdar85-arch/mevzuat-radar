-- v4 (16.07.2026) — UC IS BIRDEN:
-- (1) GENEL cift-temizligi: eski partilerden kalan birebir ayni kayitlar
--     (ornek: 'Is K. - Fesih ve tazminatlar' 2 satir) — tum tabloda.
-- (2) madde_ara v4: v3'un IDF agirligi DOGRUYDU ama 13 bin satirin tamamini
--     puanlamak zaman asimi (500) verdi. v4 iki asamali: once ts_rank ile
--     en iyi 300 aday, sonra YALNIZ o 300'u IDF ile yeniden sirala. Hizli + isabetli.
-- (3) dogrulama sorgusu.
delete from dokumanlar a
using dokumanlar b
where a.ctid < b.ctid
  and a.kaynak_ad = b.kaynak_ad
  and a.baslik is not distinct from b.baslik
  and a.metin = b.metin;

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
),
aday as (
  select d.ctid as rid, d.arama_fold as af, ts_rank(d.arama_fold, q.orq) as r
  from dokumanlar d, q
  where q.orq is not null and d.arama_fold @@ q.orq
  order by r desc
  limit 300
),
puan as (
  select a.rid, a.r,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s
  from aday a
)
select d.* from dokumanlar d
join puan p on d.ctid = p.rid
order by p.s desc, p.r desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- dogrulama: ilk satirda 'Veraset ve Intikal' bekleniyor
select kaynak_ad from madde_ara('veraset beyannamesi verme zamani', 3);
