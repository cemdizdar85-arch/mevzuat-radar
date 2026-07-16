-- TEK KOSUDA IKI IS (16.07.2026):
-- (1) VUK 509 GT cift-yukleme temizligi: iki es-zamanli robot kosusu ayni
--     tebligi ikiser yukledi (364 = 2x182). Ayni kaynak_ad+metin ciftlerinden
--     biri silinir. (2) madde_ara v2 siralama duzeltmesi.
delete from dokumanlar a
using dokumanlar b
where a.ctid < b.ctid
  and a.kaynak_ad = b.kaynak_ad
  and a.kaynak_ad like 'VUK 509 GT%'
  and b.kaynak_ad like 'VUK 509 GT%'
  and a.baslik is not distinct from b.baslik
  and a.metin = b.metin;

-- madde_ara v2: ESKI SORUN — ts_rank nadir kelimeyi one cikarmiyordu
-- ('dolandiricilik cezasi' TCK m.157'yi getirmiyordu). YENI: (1) eslesen FARKLI
-- sorgu kelimesi sayisi cok olan madde one, (2) esitlikte ts_rank, (3) :* oneki.
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
q as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
)
select d.*
from dokumanlar d, q
where q.orq is not null
  and d.arama_fold @@ q.orq
order by
  (select count(*) from tok t
     where d.arama_fold @@ to_tsquery('simple', t.w || ':*')) desc,
  ts_rank(d.arama_fold, q.orq) desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- dogrulama: 182 gormelisin (364 degil)
select count(*) as vuk509_kalan from dokumanlar where kaynak_ad like 'VUK 509 GT%';