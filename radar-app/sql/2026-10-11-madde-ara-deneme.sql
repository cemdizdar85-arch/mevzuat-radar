-- ============================================================================
-- madde_ara_deneme (11.10.2026) — CANLIYA DOKUNMADAN SIRALAMA DENEMESI
--
-- NEDEN. Altin test (motor/ambar-testi.ps1) 08.10'dan beri 42/48, taban 45.
-- Gunluk Kanun Aynasi (mevzuat.yml) bu yuzden kirmizi. Dusen 6 vaka uc sinif:
--   (i)  halk dili / es anlam: 'tufe' (TBK m.344 "tuketici fiyat endeksi"),
--        'apartman ortak gider' (KMK m.20 "anagayrimenkul... genel giderlerine")
--   (ii) yasa adi aranabilir metinde yok: "anayasa" yalniz kaynak_ad'da
--   (iii) teblig kalabaligi: GVK m.103 (GVK teblig. onde), Ticaret Sicili Yon.
--        (SPK tebligleri onde), VUK m.359 (TCK/Kacakcilik K. onde)
-- madde_ara hem testi hem canli Net Cevap'i besliyor; siralama degisikligi
-- canliya yazilmadan ONCE bu ayri fonksiyonda olculur.
--
-- NE DEGISMEZ: madde_ara (v8) AYNEN kalir. Tablo/indeks/DDL YOK (14.09
-- PostgREST kesintisi dersi): yalniz iki fonksiyon tanimi.
--
-- v8'E GORE FARK (hepsi ayar ile acilip kapanir, varsayilan = onerilen):
--   (1) ES ANLAM GRUBU (sunucuda): 'tufe' -> tuketici|endeks; 'ufe' ->
--       uretici|endeks; 'apartman' -> anagayrimenkul. Grup TEK kavram sayilir
--       (en agir uyesi), yani kapsama carpanini sisirmez. Istemci (edge +
--       ambar-testi) degismez -> senkron riski yok.
--   (2) KAYNAK ADI ESLESMESI: kaynak_ad katlanip kelime-basi aranir.
--       (a) puana adw x agirlik eklenir, (b) adi eslesen belgeler ayrica
--       aday havuzuna girer (en fazla adaday; yalniz adinda 'addf'den az
--       belgede gecen jetonlar aday uretir). "Anayasa (2709) m.73" ve
--       "Kat Mulkiyeti K. ... genel giderlerine katilma" boyle bulunur.
--   (3) TUR AGIRLIGI: teblig/GUT/GT/genelge/sirkuler tebw, yonetmelik yonw,
--       standart stdw (v8 0.85), teori-notu teow (v8 0.55).
--
-- AYAR (jsonb, hepsi istege bagli): es, adw, adaday, addf, tebw, yonw, stdw,
--   teow, kapw. Ornek:
--   select * from madde_ara_deneme_puan('anayasa gore vergi odevi', 6, '{"adw":0}');
--
-- OLCUM: MADDE_ARA_RPC=madde_ara_deneme powershell -File motor/ambar-testi.ps1
-- CANLIYA GECIS CEM KARARI; bu dosya canliyi DEGISTIRMEZ.
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
         coalesce((ayar->>'adaday')::int, 150)     as adaday,
         coalesce((ayar->>'addf')::int, 3000)      as addf,
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
tok as (
  select h.w as g, h.w as w from ham h
  union
  select e.g, e.w from es_tablo e join ham h on h.w = e.g, prm where prm.es
),
nbelge as (
  select count(*)::numeric as n from dokumanlar where coalesce(tur,'') not like 'cikmis%'
),
df as (
  select t.g, t.w, to_tsquery('simple', t.w || ':*') as tq,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select g, w, tq, adet_df,
         ln( ((select n from nbelge) + 1) / (adet_df + 1) ) + 0.3 as agirlik
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
-- (2) kaynak adi katlanir: Turkce harf -> ascii, noktalama -> bosluk
adlar as (
  select d.ctid as rid,
         ' ' || lower(translate(coalesce(d.kaynak_ad,''),
                'İIıŞşĞğÜüÖöÇçÂâÎîÛû().,-/[]:;',
                'iiissgguuooccaaiiuu          ')) || ' ' as adf
  from dokumanlar d
  where coalesce(d.tur,'') not like 'cikmis%'
),
ad_es as (
  select a.rid, g.w from adlar a join agir g on a.adf like '% ' || g.w || '%'
),
ad_df as ( select w, count(*) as n from ad_es group by w ),
ad_aday as (
  select e.rid
  from ad_es e join ad_df f on f.w = e.w join agir g on g.w = e.w, prm
  where f.n <= prm.addf
  group by e.rid
  order by sum(g.agirlik) desc
  limit (select adaday from prm)
),
metin_aday as (
  select d.ctid as rid
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by ts_rank(d.arama_fold, (select orq from qtum)) desc
  limit 300
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

-- Altin testin ve Net Cevap'in bekledigi bicim (setof dokumanlar), varsayilan ayarla.
create or replace function public.madde_ara_deneme(sorgu text, adet integer default 6)
returns setof dokumanlar
language sql stable
set search_path = public
as $fn$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{}'::jsonb) p
join dokumanlar d on d.id = p.id
order by p.puan desc, p.r desc
$fn$;

-- ---- OLCU (gocun icinde; hata verirse goc geri alinir) ----
-- Iki fonksiyon da cagrilabilmeli ve cikmis% sizdirmamali.
do $olcu$
declare n int;
begin
  select count(*) into n
  from public.madde_ara_deneme('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m
  where coalesce(m.tur,'') like 'cikmis%';
  if n > 0 then raise exception 'madde_ara_deneme cikmis%% sizdiriyor: %', n; end if;
end
$olcu$;
