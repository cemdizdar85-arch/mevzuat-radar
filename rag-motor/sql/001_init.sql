-- ============================================================================
--  TETIKTE RAG MOTORU — 001_init.sql
--  PostgreSQL 16+ / pgvector 0.8+
--
--  TEK SEFERDE calisir, IDEMPOTENT'tir (ikinci kez basmak zarar vermez).
--
--  MIMARI KARARLAR (Bas Yazilim Mimari, 10.09.2026):
--
--  1) GOC KUTUGU ZORUNLU. Bu depoda 10.09'da olculdu: canlidaki `madde_ara`
--     fonksiyonu depodaki v2..v8 zincirinin HICBIRIYLE uyusmuyordu; sonucta
--     bir gun boyunca KOSMAYAN bir fonksiyon ayarlandi. Yeni motorda bu bir
--     daha olmasin diye her gocun damgasi `rag.schema_migrations`a yazilir ve
--     her fonksiyon kendi surumunu `rag.surum()` ile SOYLER.
--
--  2) HIBRIT ARAMA (vektor + tam metin), RRF ile birlestirilir. Saf vektor
--     mevzuatta zayiftir: "VUK m.359" gibi tam eslesmeleri kacirir. Saf metin
--     ise es anlamliyi kacirir. 10.09 olcumu bunun bedelini gosterdi: tek bir
--     belge 278 konunun 110'una cevap oluyordu (miknatis). RRF, iki siralamayi
--     PUANLARINI TOPLAMADAN birlestirir - olcek farki miknatis yaratmaz.
--
--  3) COSINE. Embedding'ler L2-normalize edilerek yazilir; cosine mesafesi
--     (<=>) kullanilir. HNSW indeksi vector_cosine_ops ile kurulur.
--
--  4) TURKCE KATLAMA. Postgres'te 'turkish' FTS yapilandirmasi yok; 'simple'
--     + katlanmis metin kullanilir (c,g,i,o,s,u). Katlama IMMUTABLE bir
--     fonksiyondur ki generated column'da kullanilabilsin.
--     UYARI: sorgu tarafi da AYNI fonksiyondan gecmelidir. 10.09'da eski
--     sistemde tam bu senkron kirilmisti: sorgu tarafi Turkce harfi SILIYOR
--     ([^a-z0-9] ile), ambar tarafi KATLIYORDU; "tüfe" -> "tfe" olup hicbir
--     seye eslesmiyordu. Burada tek fonksiyon iki tarafta da kullanilir.
-- ============================================================================

create extension if not exists vector;
create extension if not exists pg_trgm;

create schema if not exists rag;

-- --------------------------------------------------------------------------
-- Goc kutugu: "hangi SQL basili?" sorusunun TEK cevabi
-- --------------------------------------------------------------------------
create table if not exists rag.schema_migrations (
  surum       text primary key,
  basildi     timestamptz not null default now(),
  aciklama    text not null
);

-- --------------------------------------------------------------------------
-- Turkce katlama — IMMUTABLE olmak ZORUNDA (generated column kullaniyor)
-- --------------------------------------------------------------------------
create or replace function rag.katla(t text)
returns text
language sql
immutable
parallel safe
returns null on null input
as $$
  select lower(
    translate(
      t,
      'ÇĞİIÖŞÜçğıiöşüÂÎÛâîû',
      'cgiiosucgiiosuaiuaiu'
    )
  )
$$;

comment on function rag.katla(text) is
  'Turkce harf katlama. SORGU ve AMBAR ayni fonksiyondan gecer - senkron kirilirsa arama sessizce boşa duser.';

-- --------------------------------------------------------------------------
-- KAYNAK: bir kanun / teblig / standart belgesi
-- --------------------------------------------------------------------------
create table if not exists rag.kaynak (
  id            bigint generated always as identity primary key,
  kod           text not null unique,          -- 'VUK-213', 'TMS-2' gibi kararli kimlik
  ad            text not null,                 -- insan okunur tam ad
  tur           text not null,                 -- kanun | teblig | standart | yonetmelik | teori
  url           text,
  belge_tarihi  date,
  olusturuldu   timestamptz not null default now(),
  guncellendi   timestamptz not null default now()
);

create index if not exists ix_kaynak_tur on rag.kaynak (tur);

-- --------------------------------------------------------------------------
-- PARCA (chunk): aramanin ve soru uretiminin BIRIMI
--
--  DEV PARCA YASAGI: `karakter_sayisi` uzerinde CHECK var. 10.09 olcumunde
--  bolunmemis dev satirlarin aramada miknatis gibi calistigi gorulmustu -
--  cok kelime icerdikleri icin alakasiz sorgularda one ciciyorlar. Veritabani
--  bunu artik KABUL ETMIYOR: 8.000 karakteri asan parca yazilamaz.
-- --------------------------------------------------------------------------
create table if not exists rag.parca (
  id                bigint generated always as identity primary key,
  kaynak_id         bigint not null references rag.kaynak(id) on delete cascade,
  madde_no          text,                      -- 'm.359', 'gec. m.3', 'p.A95', null
  baslik            text,
  metin             text not null,
  karakter_sayisi   int  not null generated always as (length(metin)) stored,
  sira              int  not null,             -- belge icindeki sira
  icerik_ozeti      text not null,             -- sha256(metin) - mukerrer freni
  olusturuldu       timestamptz not null default now(),

  constraint ck_parca_boy check (length(metin) between 40 and 8000),
  constraint uq_parca_ozet unique (kaynak_id, icerik_ozeti)
);

create index if not exists ix_parca_kaynak on rag.parca (kaynak_id, sira);

-- Tam metin arama vektoru: katlanmis metin uzerinde 'simple'
alter table rag.parca
  add column if not exists arama tsvector
  generated always as (
    setweight(to_tsvector('simple', rag.katla(coalesce(baslik, ''))), 'A') ||
    setweight(to_tsvector('simple', rag.katla(metin)), 'B')
  ) stored;

create index if not exists ix_parca_arama on rag.parca using gin (arama);
create index if not exists ix_parca_trgm  on rag.parca using gin (rag.katla(metin) gin_trgm_ops);

-- --------------------------------------------------------------------------
-- EMBEDDING: parcadan AYRI tablo
--  Sebep: model degistiginde (boyut degisince) parcalar yeniden yutulmaz,
--  yalniz vektorler yeniden uretilir. `model` + `boyut` satirda tutulur ki
--  iki farkli modelin vektoru asla karistirilmasin.
-- --------------------------------------------------------------------------
create table if not exists rag.parca_vektor (
  parca_id    bigint      not null references rag.parca(id) on delete cascade,
  model       text        not null,
  boyut       int         not null,
  vektor      vector(768) not null,
  olusturuldu timestamptz not null default now(),
  primary key (parca_id, model)
);

-- HNSW: yaklasik ama hizli. m/ef_construction degerleri 44 bin satir olcegi
-- icin pgvector'un onerdigi taban degerlerdir; ambar 10 kati buyurse
-- ef_construction yukseltilir (yeniden index gerekir, veri gerekmez).
create index if not exists ix_parca_vektor_hnsw
  on rag.parca_vektor using hnsw (vektor vector_cosine_ops)
  with (m = 16, ef_construction = 64);

create index if not exists ix_parca_vektor_model on rag.parca_vektor (model);

-- --------------------------------------------------------------------------
-- IS KUYRUGU: worker'lar buradan besleniyor
--  `FOR UPDATE SKIP LOCKED` deseni - ayni isi iki worker almaz.
-- --------------------------------------------------------------------------
create table if not exists rag.is_kuyrugu (
  id           bigint generated always as identity primary key,
  tur          text not null check (tur in ('gomme','soru')),
  yuk          jsonb not null,
  durum        text not null default 'bekliyor'
               check (durum in ('bekliyor','isleniyor','bitti','hata')),
  deneme       int  not null default 0,
  son_hata     text,
  alindi       timestamptz,
  olusturuldu  timestamptz not null default now()
);

create index if not exists ix_kuyruk_alinacak
  on rag.is_kuyrugu (tur, durum, id)
  where durum = 'bekliyor';

-- --------------------------------------------------------------------------
-- URETILEN SORU
-- --------------------------------------------------------------------------
create table if not exists rag.soru (
  id            bigint generated always as identity primary key,
  parca_id      bigint not null references rag.parca(id) on delete restrict,
  ders          text not null,
  konu          text not null,
  zorluk        text not null check (zorluk in ('kolay','zor','cokzor')),
  govde         jsonb not null,       -- {soru, siklar{A..E}, dogru, aciklama{A..E}}
  model         text not null,
  giris_jeton   int  not null default 0,
  cikis_jeton   int  not null default 0,
  yayin         boolean not null default false,
  olusturuldu   timestamptz not null default now()
);

create index if not exists ix_soru_konu  on rag.soru (ders, konu);
create index if not exists ix_soru_parca on rag.soru (parca_id);

-- MADDE TAVANI: ayni parcadan sinirsiz soru uretilmesin (cesitlilik kapisi)
create or replace function rag.parca_soru_sayisi(p_parca_id bigint)
returns int language sql stable as $$
  select count(*)::int from rag.soru where parca_id = p_parca_id
$$;

-- ============================================================================
--  HIBRIT ARAMA — RRF (Reciprocal Rank Fusion)
--
--  NEDEN RRF, "puanlari topla" DEGIL: cosine mesafesi [0,2], ts_rank ise
--  sinirsiz ve belge uzunluguna duyarli. Ikisini toplamak, uzun belgeye
--  yapay avantaj verir - 10.09'da olculen miknatis tam olarak bu tur bir
--  puan karisiminda dogmustu. RRF yalniz SIRAYA bakar (1/(k+rank)), olcege
--  bakmaz; boylece hicbir kanal digerini ezemez.
--
--  k = 60: RRF'in literaturdeki taban degeri (Cormack ve ark.). Degistirmeden
--  once olc - bu bir ayar dugmesi degil, taban.
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
with sorgu as (
  select plainto_tsquery('simple', rag.katla(p_sorgu)) as tsq
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
  where p.arama @@ s.tsq
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
select b.parca_id,
       k.ad,
       k.kod,
       p.madde_no,
       p.baslik,
       p.metin,
       b.rrf,
       b.v_sira::int,
       b.m_sira::int
from birlesik b
join rag.parca  p on p.id = b.parca_id
join rag.kaynak k on k.id = p.kaynak_id
order by b.rrf desc, p.karakter_sayisi asc   -- esitlikte KISA parca kazanir (miknatis freni)
limit p_adet
$$;

comment on function rag.ara is
  'Hibrit arama: pgvector cosine + FTS, RRF(k=60) ile birlesik. Esitlikte kisa parca kazanir.';

-- ============================================================================
--  SURUM BEYANI — "canlida ne kosuyor?" sorusu bir daha tahminle cevaplanmaz
-- ============================================================================
create or replace function rag.surum()
returns text language sql immutable as $$ select '001_init / rag.ara v1 / RRF k=60 / vector(768) cosine' $$;

insert into rag.schema_migrations (surum, aciklama)
values ('001_init', 'Sema, hibrit arama (RRF), is kuyrugu, soru tablosu. Parca boyu 8000 krk ile SINIRLI.')
on conflict (surum) do nothing;
