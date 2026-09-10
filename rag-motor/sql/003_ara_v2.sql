-- ============================================================================
--  TETIKTE RAG MOTORU — 003_ara_v2.sql
--  rag.ara v2: TAM METIN KANALI "VE" DEGIL "VEYA" ARAR
--
--  IDEMPOTENT. ONKOSUL: 001_init + 002_konu_madde basili olmali.
--
--  ============================================================================
--  NEDEN — MOTORUN ILK GERCEK KOSUSUNDA OLCULDU (10.09.2026)
--  ============================================================================
--  VUK yeni semaya yutuldu (642 parca cikti, 637 yazildi) ve bes konu motorun
--  kendi hattindan soruldu. BESI DE "dayanak bulunamadi" dondu.
--
--  Sebep v1'in tek satirinda:
--      plainto_tsquery('simple', rag.katla(p_sorgu))
--  plainto_tsquery butun kelimeleri VE ile baglar. Sorgu
--      "Vergi Mevzuatı ve Uygulaması degerleme olculeri ve maliyet bedeli"
--  oldugunda, bu ONBIR kelimenin HEPSINI ayni parcada arar. Boyle bir madde
--  yoktur - olamaz da. Kanal her sorguda BOS dondu, RRF de bos vektor kanaliyla
--  birlesince sonuc sifir cikti.
--
--  Eski motor (public.madde_ara) bunu OR ile yapiyordu; v1'i yazarken o
--  ayrintiyi tasimamisim. Bu, mimarinin degil TEK SATIRIN kusuru.
--
--  v2: jetonlara ayir, uc harften kisa olanlari at, ONEK ESLESMELI (':*')
--  VEYA sorgusu kur. Turkce eklerin bol oldugu bir dilde onek eslesmesi
--  "amortisman" ile "amortismana" yi ayni sayar - gerekli.
--
--  DURAK KELIME: 'simple' yapilandirmasinin durak listesi yok, o yuzden "ve",
--  "ile", "icin" gibi kelimeler sorguya girip her seyi eslestirebilir. Uzunluk
--  esigi (>=3) bunlarin cogunu eler; kalanini ts_rank_cd siralamasi bastirir.
--  Ayrica RRF yalniz SIRAYA baktigi icin tek kanalin gurultusu sonucu ezemez.
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
  -- Turkce katlama SORGU tarafinda da uygulanir; ambar tarafi ayni fonksiyondan
  -- geciyor (rag.parca.arama generated column). Iki taraf ayrisirsa arama
  -- sessizce boşa duser - eski hattin en pahali kusuru buydu.
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
  where pv.model = p_model
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
order by b.rrf desc, p.karakter_sayisi asc   -- esitlikte KISA parca kazanir
limit p_adet
$$;

comment on function rag.ara is
  'Hibrit arama v2: pgvector cosine + FTS(VEYA, onek eslesmeli), RRF(k=60). v1 plainto_tsquery ile VE ariyordu ve her sorguda bos donuyordu.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '003_ara_v2 / rag.ara v2 (RRF k=60, FTS VEYA + onek) / konu_madde + konu_dayanak / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('003_ara_v2', 'rag.ara v2: tam metin kanali plainto_tsquery(VE) yerine to_tsquery(VEYA, onek). v1 her sorguda bos donuyordu.')
on conflict (surum) do nothing;
