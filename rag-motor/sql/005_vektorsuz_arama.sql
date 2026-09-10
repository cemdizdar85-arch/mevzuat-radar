-- ============================================================================
--  TETIKTE RAG MOTORU — 005_vektorsuz_arama.sql
--  VEKTOR YOKSA VEKTOR KANALI HIC KATILMAZ
--
--  IDEMPOTENT. ONKOSUL: 004_kart_hizala basili olmali.
--
--  ============================================================================
--  NEDEN — KENDI OLCUMUMDE BULUNAN HAKSIZLIK (10.09.2026)
--  ============================================================================
--  "Vektor kanalinin katkisi ne?" sorusunu olcmek icin ayni bes konu iki kez
--  soruldu: bir kez gomme ACIK, bir kez KAPALI. Gomme kapaliyken motor SIFIR
--  VEKTOR gonderiyordu (zarif dusus).
--
--  Ama sifir vektor "kanal kapali" demek DEGIL: pgvector sifir vektore olan
--  uzakligi yine hesapliyor, butun satirlar birbirine esit uzaklikta cikiyor
--  ve kanal RASTGELE bir siralama donduruyor. O rastgele sira RRF'e giriyor ve
--  tam metin kanalinin dogru sonucunu asagi itiyor.
--
--  Olcum ciktisinda gorunuyordu: gomme KAPALI kosuda "v-sira 60", "v-sira 17"
--  yaziyordu - yani kapali sanilan kanal calisiyor ve gurultu uretiyordu.
--  Boyle bir olcum tam metnin HAKKINI YER; vektorun katkisini oldugundan
--  buyuk gosterir.
--
--  v3: p_vektor NULL olabilir. NULL ise vektor kanali HIC KURULMAZ, RRF tek
--  kanalla calisir. Kiyas ancak boyle durustur.
-- ============================================================================

create or replace function rag.ara(
  p_sorgu       text,
  p_vektor      vector(768),          -- NULL olabilir: vektor kanali atlanir
  p_model       text,
  p_adet        int  default 8,
  p_aday        int  default 60,
  p_kaynak_tur  text default null
)
returns table (
  parca_id   bigint,
  kaynak_ad  text,
  kaynak_kod text,
  madde_no   text,
  baslik     text,
  metin      text,
  rrf        double precision,
  vektor_sira int,
  metin_sira  int
)
language sql
stable
as $$
with jeton as (
  select w from regexp_split_to_table(rag.katla(coalesce(p_sorgu,'')), '[^a-z0-9]+') as w
  where length(w) >= 3
  limit 12
),
sorgu as (
  select case when count(*) = 0 then null
              else to_tsquery('simple', string_agg(w || ':*', ' | '))
         end as tsq
  from jeton
),
vektor_kanali as (
  -- p_vektor NULL ise bu kanal BOS doner (where false).
  select pv.parca_id,
         row_number() over (order by pv.vektor <=> p_vektor) as sira
  from rag.parca_vektor pv
  join rag.parca p on p.id = pv.parca_id
  join rag.kaynak k on k.id = p.kaynak_id
  where p_vektor is not null
    and pv.model = p_model
    and (p_kaynak_tur is null or k.tur = p_kaynak_tur)
  order by pv.vektor <=> p_vektor
  limit p_aday
),
metin_kanali as (
  select p.id as parca_id,
         row_number() over (order by ts_rank_cd(p.arama, s.tsq) desc) as sira
  from rag.parca p
  join rag.kaynak k on k.id = p.kaynak_id
  cross join sorgu s
  where s.tsq is not null
    and p.arama @@ s.tsq
    and (p_kaynak_tur is null or k.tur = p_kaynak_tur)
  order by ts_rank_cd(p.arama, s.tsq) desc
  limit p_aday
),
birlesik as (
  select coalesce(v.parca_id, m.parca_id) as parca_id,
         v.sira as v_sira,
         m.sira as m_sira,
         coalesce(1.0 / (60 + v.sira), 0.0) +
         coalesce(1.0 / (60 + m.sira), 0.0) as rrf
  from vektor_kanali v
  full outer join metin_kanali m on m.parca_id = v.parca_id
)
select b.parca_id, k.ad, k.kod, p.madde_no, p.baslik, p.metin,
       b.rrf, b.v_sira::int, b.m_sira::int
from birlesik b
join rag.parca  p on p.id = b.parca_id
join rag.kaynak k on k.id = p.kaynak_id
order by b.rrf desc, p.karakter_sayisi asc
limit p_adet
$$;

comment on function rag.ara is
  'Hibrit arama v3: p_vektor NULL ise vektor kanali HIC kurulmaz. v2 sifir vektorle rastgele siralama uretip tam metin kanalini asagi itiyordu.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '005_vektorsuz_arama / rag.ara v3 (RRF k=60, p_vektor NULL -> kanal atlanir) / konu_dayanak v2 / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('005_vektorsuz_arama', 'rag.ara v3: p_vektor NULL olabilir, o zaman vektor kanali kurulmaz. Sifir vektor kanali kapatmiyor, GURULTU uretiyordu.')
on conflict (surum) do nothing;
