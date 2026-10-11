-- ============================================================================
-- madde_ara_deneme v2 (11.10.2026) — HIZ ONARIMI
--
-- OLCULDU (2026-10-11-madde-ara-deneme.sql, ayni gun): siralama dogru yone
-- gitti (Anayasa, KMK m.20, Ticaret Sicili Yon., GVK one geldi) ama SURE
-- canli v8'in ~40 kati: v8 32-87 ms, deneme 1,7-3,0 sn; 'kira artis fazla
-- olabilir tufe' adet=30'da 3 sn statement_timeout'a takildi.
-- Sebep: kaynak_ad her cagrida 50.133 satirda katlanip (translate+lower) her
-- jetonla LIKE'laniyordu.
--
-- v2: tam tarama YOK.
--   (a) kaynak adi PUANI yalniz aday satirlarinda (<= ~400) hesaplanir.
--   (b) adindan ADAY uretmek yalniz kucuk bir YASA ADI SOZLUGU ile: sorgu
--       jetonu sozlukteyse kaynak_ad ONEK eslesmesi (LIKE 'Anayasa (%'),
--       ts_rank'e gore en fazla 'adaday' belge. Sozluk: anayasa + kullanicinin
--       yazdigi kanun kisaltmalari. 'kdv' BILEREK yok: "kdv iadesi" gibi
--       sorgularda dogru kaynak KDV GUT'tur, KDVK'yi one itmek zarar.
--   Es anlam grubu ve teblig agirligi v1 ile ayni. Ayar anahtarlari ayni
--   (addf artik kullanilmaz).
-- Canli madde_ara'ya DOKUNMAZ. Tablo/indeks/DDL yok.
-- ============================================================================

create or replace function public.madde_ara_deneme_puan(sorgu text, adet integer default 6, ayar jsonb default '{}'::jsonb)
returns table (id uuid, kaynak_ad text, tur text, puan double precision, gs double precision,
               kapsanan integer, adkap integer, turw double precision, r real)
language sql stable
set search_path = public
as $fn$
with prm as (
  select coalesce((ayar->>'es')::boolean, true)   as es,
         coalesce((ayar->>'adw')::float8, 0.6)     as adw,
         coalesce((ayar->>'adaday')::int, 60)      as adaday,
         coalesce((ayar->>'tebw')::float8, 0.75)   as tebw,
         coalesce((ayar->>'yonw')::float8, 1.0)    as yonw,
         coalesce((ayar->>'stdw')::float8, 0.85)   as stdw,
         coalesce((ayar->>'teow')::float8, 0.55)   as teow,
         coalesce((ayar->>'kapw')::float8, 0.35)   as kapw
),
ham as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
es_tablo(g, w) as (
  values ('tufe','tuketici'), ('tufe','endeks'),
         ('ufe','uretici'),   ('ufe','endeks'),
         ('apartman','anagayrimenkul')
),
-- YASA ADI SOZLUGU: jeton (istemcinin ek soyulmus hali) -> kaynak_ad oneki
ad_sozluk(w, desen) as (
  values ('anayas','Anayasa (%'), ('anayasa','Anayasa (%'),
         ('vuk','VUK (%'), ('gvk','GVK (%'), ('kvk','KVK (%'), ('kdvk','KDVK (%'),
         ('tbk','TBK (%'), ('tmk','TMK (%'), ('ttk','TTK (%'), ('tck','TCK (%'),
         ('cmk','CMK (%'), ('hmk','HMK (%'), ('iik','İİK (%'), ('iyuk','İYUK (%'),
         ('aatuhk','AATUHK (%'), ('kvkk','KVKK (%'), ('tkhk','TKHK (%'),
         ('fsek','FSEK (%'), ('smk','SMK (%'), ('kik','KİK (%'), ('mohuk','MÖHUK (%')
),
tok as (
  select h.w as g, h.w as w from ham h
  union
  select e.g, e.w from es_tablo e join ham h on h.w = e.g, prm where prm.es
),
df as (
  select t.g, t.w, to_tsquery('simple', t.w || ':*') as tq,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select g, w, tq,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
secili as ( select w from df where adet_df <= 1500 order by adet_df asc limit 4 ),
secili2 as (
  select w from secili
  union all
  select w from (select w from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as ( select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from secili2 ),
qtum as ( select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok ),
metin_aday as (
  select d.ctid as rid
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by ts_rank(d.arama_fold, (select orq from qtum)) desc
  limit 300
),
ad_aday as (
  select d.ctid as rid
  from dokumanlar d
  join ad_sozluk s on d.kaynak_ad like s.desen
  join ham h on h.w = s.w
  where coalesce(d.tur,'') not like 'cikmis%'
  order by ts_rank(d.arama_fold, (select orq from qtum)) desc
  limit (select adaday from prm)
),
aday as (
  select rid from metin_aday
  union
  select rid from ad_aday
),
ozellik as (
  select d.ctid as rid, d.id, d.kaynak_ad, d.tur, d.arama_fold as af,
         ' ' || lower(translate(coalesce(d.kaynak_ad,''),
                'İIıŞşĞğÜüÖöÇçÂâÎîÛû().,-/[]:;',
                'iiissgguuooccaaiiuu          ')) || ' ' as adf,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d join aday a on d.ctid = a.rid
),
grup as (
  select o.rid, g.g,
         max(case when o.af @@ g.tq then g.agirlik else 0 end) as mw,
         max(case when o.adf like '% ' || g.w || '%' then g.agirlik else 0 end) as aw
  from ozellik o cross join agir g
  group by o.rid, g.g
),
toplam as (
  select gr.rid,
         sum(gr.mw + prm.adw * gr.aw) as gs,
         count(*) filter (where gr.mw > 0 or gr.aw > 0)::int as kapsanan,
         count(*) filter (where gr.aw > 0)::int as adkap
  from grup gr, prm
  group by gr.rid
),
puan as (
  select o.id, o.kaynak_ad, o.tur, o.r, t.gs, t.kapsanan, t.adkap,
         case
           when o.tur = 'teori-notu'     then prm.teow
           when o.tur = 'standart-madde' then prm.stdw
           when o.adf ~ ' (tebli|gut |gt |genelge|sirkuler)' then prm.tebw
           when o.adf ~ ' (yonetmeli|yon )' then prm.yonw
           else 1.0
         end as turw,
         prm.kapw
  from ozellik o join toplam t on t.rid = o.rid, prm
)
select p.id, p.kaynak_ad, p.tur,
       p.gs * p.turw * (1 + p.kapw * greatest(p.kapsanan - 1, 0)) as puan,
       p.gs, p.kapsanan, p.adkap, p.turw, p.r
from puan p
order by 4 desc, p.r desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- madde_ara_deneme (setof dokumanlar) v1 tanimi aynen gecerli; yeniden yazilmaz.

do $olcu$
declare n int;
begin
  select count(*) into n
  from public.madde_ara_deneme('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m
  where coalesce(m.tur,'') like 'cikmis%';
  if n > 0 then raise exception 'madde_ara_deneme cikmis%% sizdiriyor: %', n; end if;
end
$olcu$;
