-- ============================================================================
--  TETIKTE RAG MOTORU — 008_telif_kapisi.sql
--  SINAV KULLIYATI DAYANAK OLAMAZ (sert kapi) + TELIF BENZERLIK ARAMASI
--
--  IDEMPOTENT. ONKOSUL: 007 basili.
--
--  ============================================================================
--  KENDI IDDIAMDAKI ACIK (10.09.2026)
--  ============================================================================
--  "Cikmis sinav kulliyati dayanak aramasindan MIMARI OLARAK dislaniyor" diye
--  yazdim. DOGRU DEGILDI: rag.ara'nin p_kaynak_tur suzgeci var ama SoruUretici
--  ona NULL geciyordu - yani hicbir sey dislanmiyordu. Sozlesme A1'i koruyan
--  sey bir NIYET'ti, bir KAPI degil.
--
--  Suzgeci cagirana birakmak da yanlis tasarim: cagiran unutabilir, yeni bir
--  cagiran hic bilmeyebilir. Telif korumasi ISTEGE BAGLI OLAMAZ.
--
--  v4: dislama rag.ara'nin ICINDE, kosulsuz. Cagiran ne gecerse gecsin sinav
--  metni dayanak olarak DONMEZ. p_kaynak_tur artik yalnizca DARALTMA icin
--  (ornegin "sadece kanun") - genisletmek icin kullanilamaz.
-- ============================================================================

create or replace function rag.dayanak_olabilir(p_tur text)
returns boolean
language sql
immutable
parallel safe
as $$
  select coalesce(p_tur, '') not in ('cikmis-sinav', 'sinav-calisma-sorusu')
$$;

comment on function rag.dayanak_olabilir is
  'Bu turdeki icerik SORU DAYANAGI olabilir mi? Sinav metinleri OLAMAZ (sozlesme A1: cikmis soru birebir alinamaz).';

-- ============================================================================
--  rag.ara v4 — sinav metni ASLA dayanak olarak donmez
-- ============================================================================
create or replace function rag.ara(
  p_sorgu       text,
  p_vektor      vector(768),
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
  select pv.parca_id,
         row_number() over (order by pv.vektor <=> p_vektor) as sira
  from rag.parca_vektor pv
  join rag.parca p on p.id = pv.parca_id
  join rag.kaynak k on k.id = p.kaynak_id
  where p_vektor is not null
    and pv.model = p_model
    and rag.dayanak_olabilir(k.tur)                       -- ⛔ TELIF KAPISI
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
    and rag.dayanak_olabilir(k.tur)                       -- ⛔ TELIF KAPISI
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
  'Hibrit arama v4: RRF k=60. Sinav metinleri (cikmis-sinav, sinav-calisma-sorusu) KOSULSUZ dislanir - telif kapisi cagirana birakilmaz.';

-- ============================================================================
--  TELIF BENZERLIK ARAMASI — A1'in eksik mekanik kapisi
--
--  Uretilen bir sorunun cikmis sinav kulliyatindaki EN YAKIN komsusunu bulur.
--  rag.ara'nin TERSI: yalniz sinav metinlerine bakar.
--
--  Kullanim: uretilen soru gomulur, bu fonksiyona verilir, donen en yuksek
--  benzerlik esigi asiyorsa soru REDDEDILIR.
--
--  benzerlik = 1 - kosinus uzakligi (1 = birebir ayni yon, 0 = ilgisiz)
--  Esik AMPIRIK olarak belirlenecek: once bir parti uretilip dagilim olculur,
--  sonra esik konur. Olcmeden esik koymak ya masum soruyu reddeder ya kopyayi
--  gecirir - ikisi de kabul edilemez.
-- ============================================================================
create or replace function rag.telif_komsusu(
  p_vektor vector(768),
  p_model  text,
  p_adet   int default 3
)
returns table (
  parca_id  bigint,
  kaynak_ad text,
  benzerlik double precision,
  ornek     text
)
language sql
stable
as $$
  select p.id, k.ad,
         (1 - (pv.vektor <=> p_vektor))::double precision,
         left(p.metin, 300)
  from rag.parca_vektor pv
  join rag.parca  p on p.id = pv.parca_id
  join rag.kaynak k on k.id = p.kaynak_id
  where pv.model = p_model
    and not rag.dayanak_olabilir(k.tur)     -- YALNIZ sinav metinleri
  order by pv.vektor <=> p_vektor
  limit greatest(coalesce(p_adet,3),1)
$$;

comment on function rag.telif_komsusu is
  'Uretilen sorunun cikmis sinav kulliyatindaki en yakin komsusu. Sozlesme A1 mekanik kapisi. Esik AMPIRIK belirlenir - olcmeden esik konmaz.';

-- Dayanak havuzunun gercekten daraldigini gorunur kilan sayac.
create or replace view rag.dayanak_havuzu as
select k.tur,
       rag.dayanak_olabilir(k.tur) as dayanak_olabilir,
       count(distinct k.id) as kaynak,
       count(p.id)          as parca,
       count(pv.parca_id)   as vektorlu
from rag.kaynak k
left join rag.parca p on p.kaynak_id = k.id
left join rag.parca_vektor pv on pv.parca_id = p.id
group by k.tur
order by rag.dayanak_olabilir(k.tur) desc, count(p.id) desc;

create or replace function rag.surum()
returns text language sql immutable as $$
  select '008_telif_kapisi / rag.ara v4 (sinav metni KOSULSUZ dislanir) / telif_komsusu / konu_dayanak v3 / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('008_telif_kapisi', 'rag.ara v4: sinav metinleri dayanak aramasindan KOSULSUZ dislanir (suzgec cagirana birakilmiyordu, SoruUretici NULL geciyordu). + rag.telif_komsusu (A1 mekanik kapisi) + rag.dayanak_havuzu gorunumu.')
on conflict (surum) do nothing;
