-- ============================================================================
-- madde_ara_deneme v3 (11.10.2026) — v2 OLCUMUNDEN CIKAN IKI KUSUR + AD ACILIMI
--
-- v2 OLCUMU (MADDE_ARA_RPC=madde_ara_deneme motor/ambar-testi.ps1): 45/48,
-- sure 80-146 ms (v8 32-87). Ama:
--   (1) 'motorlu tasitlar vergisi odeme zamani' v8'de GECIYORDU, v2'de DUSTU:
--       "MTV K. (197 s.K.) m.7 - Sona Ermesi, Tarh, Teblig ve Odeme..." madde
--       BASLIGINDAKI "Teblig" kelimesi yuzunden teblig sayilip 0.75 aldi.
--       -> teblig/yonetmelik sinifi yalniz adinda "s.K." (kanun numarasi)
--          OLMAYAN belgeye verilir.
--   (2) TUFE grubunun tek basina 'endeks' uyesi TFRS 9'u odullendiriyordu.
--       -> es anlam artik IFADE: 'tuketici <-> fiyat <-> endeks:*'.
--   (3) AD ACILIMI: kaynak_ad kisaltma tasiyor ("MTV K.", "GVK"), kullanici
--       tam adi yaziyor ("motorlu tasitlar vergisi"). Aday satirlarinda
--       kisaltmanin acilimi ad metnine eklenir (yalniz puan; aday uretmez).
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
         coalesce((ayar->>'acilim')::boolean, true) as acil,
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
-- es anlam: grup -> tsquery ifadesi (grup TEK kavram sayilir, ad eslesmesine girmez)
es_tablo(g, tqs) as (
  values ('tufe','tuketici <-> fiyat <-> endeks:*'),
         ('ufe','uretici <-> fiyat <-> endeks:*'),
         ('apartman','anagayrimenkul:*')
),
-- YASA ADI SOZLUGU: jeton (istemcinin ek soyulmus hali) -> kaynak_ad oneki (aday uretir)
ad_sozluk(w, desen) as (
  values ('anayas','Anayasa (%'), ('anayasa','Anayasa (%'),
         ('vuk','VUK (%'), ('gvk','GVK (%'), ('kvk','KVK (%'), ('kdvk','KDVK (%'),
         ('tbk','TBK (%'), ('tmk','TMK (%'), ('ttk','TTK (%'), ('tck','TCK (%'),
         ('cmk','CMK (%'), ('hmk','HMK (%'), ('iik','İİK (%'), ('iyuk','İYUK (%'),
         ('aatuhk','AATUHK (%'), ('kvkk','KVKK (%'), ('tkhk','TKHK (%'),
         ('fsek','FSEK (%'), ('smk','SMK (%'), ('kik','KİK (%'), ('mohuk','MÖHUK (%')
),
-- AD ACILIMI: kaynak_ad oneki -> kullanicinin yazdigi tam ad (yalniz puan)
ad_acilim(desen, ek) as (
  values ('TTK (%','turk ticaret'), ('TMK (%','turk medeni'), ('TBK (%','borclar'),
         ('VUK (%','vergi usul'), ('İİK (%','icra iflas'), ('HMK (%','hukuk muhakemeleri'),
         ('CMK (%','ceza muhakemesi'), ('TCK (%','turk ceza'), ('GVK (%','gelir vergisi'),
         ('KVK (%','kurumlar vergisi'), ('KDVK (%','katma deger vergisi'), ('SMK (%','sinai mulkiyet'),
         ('KİK (%','kamu ihale'), ('AATUHK (%','amme alacaklarinin tahsil'),
         ('TKHK (%','tuketicinin korunmasi'), ('FSEK (%','fikir sanat eserleri'),
         ('İYUK (%','idari yargilama usulu'), ('ÖTV K.%','ozel tuketim vergisi'),
         ('MÖHUK (%','milletlerarasi ozel hukuk'), ('KVKK (%','kisisel verilerin korunmasi'),
         ('MTV K.%','motorlu tasitlar vergisi'), ('TPKK (%','turk parasi kiymetini koruma'),
         ('Emlak V.K.%','emlak vergisi'), ('Damga V.K.%','damga vergisi')
),
tok as (
  select h.w as g, h.w as w, h.w || ':*' as tqs, true as adlik from ham h
  union
  select e.g, e.g, e.tqs, false from es_tablo e join ham h on h.w = e.g, prm where prm.es
),
df as (
  select t.g, t.w, t.adlik, t.tqs, to_tsquery('simple', t.tqs) as tq,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.tqs)) as adet_df
  from tok t
),
agir as (
  select g, w, tq, adlik,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
secili as ( select tqs from df where adet_df <= 1500 order by adet_df asc limit 4 ),
secili2 as (
  select tqs from secili
  union all
  select tqs from (select tqs from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as ( select to_tsquery('simple', string_agg('(' || tqs || ')', ' | ')) as orq from secili2 ),
qtum as ( select to_tsquery('simple', string_agg('(' || tqs || ')', ' | ')) as orq from tok ),
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
         case when (select acil from prm) then
           coalesce((select ' ' || string_agg(x.ek, ' ') || ' ' from ad_acilim x
                     where d.kaynak_ad like x.desen), '')
         else '' end as acilim,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d join aday a on d.ctid = a.rid
),
grup as (
  select o.rid, g.g,
         max(case when o.af @@ g.tq then g.agirlik else 0 end) as mw,
         max(case when g.adlik and (o.adf || o.acilim) like '% ' || g.w || '%'
                  then g.agirlik else 0 end) as aw
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
           when o.adf !~ ' s k ' and o.adf ~ ' (tebli|gut |gt |genelge|sirkuler)' then prm.tebw
           when o.adf !~ ' s k ' and o.adf ~ ' (yonetmeli|yon )' then prm.yonw
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
