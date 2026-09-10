-- ============================================================================
--  TETIKTE RAG MOTORU — 002_konu_madde.sql
--  KONU -> MADDE KALICI ESLESME KATMANI  (Cem karari, 10.09.2026)
--
--  IDEMPOTENT: ikinci kez basmak zarar vermez.
--  ONKOSUL: 001_init.sql basili olmali.
--
--  ============================================================================
--  NEDEN VAR — OLCULEN GEREKCE
--  ============================================================================
--  Arama KARARSIZ oldugu icin soru fabrikasi onun insafina birakilamaz.
--  10.09.2026'da ayni gun olculen uc olay:
--
--    1) 'VUK degerleme olculeri' sorgusu bir kosuda VUK m.261'i (dogru),
--       bir sonraki kosuda VUK m.49'u (Uygulama suresi - alakasiz) getirdi.
--       Sorgu ayni, ambar ayni, sonuc farkli.
--
--    2) 'vergi ziyai cezasi' sorgusu israrla m.370'i (Izaha davet) getirdi.
--       Oysa DOGRU maddeler ambarda duruyordu: m.341 (Vergi ziyai) ve m.344.
--       Yani kaynak eksik degildi, arama bulamiyordu.
--
--    3) Ayni sabah olculen genel rakam: uretim plan satirlarinin %29,4'u
--       (4.425 / 15.058) "maddesiz" sayilip ATLANMISTI - konular zor oldugu
--       icin degil, arama maddeyi bulamadigi icin.
--
--  Bu katman o baglantiyi VERIYE yazar. Bir konunun hangi maddeye dayandigi
--  bir arama sonucu degil, bir KAYITTIR. Arama yardimci kalir; karar burada.
--
--  ============================================================================
--  HNSW HAKKINDA — bir yanlis anlamayi duzeltmek icin
--  ============================================================================
--  HNSW indeksi 001_init.sql ile ZATEN KURULDU:
--      create index ix_parca_vektor_hnsw
--        on rag.parca_vektor using hnsw (vektor vector_cosine_ops)
--        with (m = 16, ef_construction = 64);
--
--  Ancak olculen 3.368 ms'lik yavaslik BU indeksin isi DEGILDIR. O sure
--  eski public.madde_ara fonksiyonuna aittir; o fonksiyon tam metin (tsvector)
--  arar, vektor kullanmaz. HNSW tam metin aramasini hizlandirmaz - farkli
--  fonksiyon, farkli indeks, farkli sorun. Eski hattin yavasligi ayri bir
--  onarim konusudur (aday havuzu 300 + ts_rank maliyeti).
--
--  Parca boyunun HNSW hizina etkisi de yok denecek kadar azdir: HNSW gecikmesi
--  vektor SAYISI ile ve ef_search ile belirlenir, parcanin kac karakter
--  oldugu ile degil. Parca boyu ISABETI etkiler (kucuk parca daha keskin
--  eslesme), HIZI degil. Ambarin tamami 1.800 karakterde birlestirildi.
--
--  ef_search bir INDEKS OZELLIGI DEGIL, oturum ayaridir; asagida fonksiyon
--  icinde ayarlanmaz cunku `stable` fonksiyonda SET calismaz. Uygulama
--  tarafinda baglanti acilirken verilir:  SET hnsw.ef_search = 80;
--  (varsayilan 40; buyutmek isabeti artirir, hizi dusurur.)
-- ============================================================================

-- --------------------------------------------------------------------------
-- KONU KARTI: bir dersin bir konusu hangi mevzuat hukmune dayanir?
--
--  · Bir konunun BIRDEN COK maddesi olabilir (oncelik ile siralanir).
--  · madde_deseni ILIKE desenidir ('VUK (213 s.K.) m.323%') cunku ayni madde
--    dilimlenmis olabilir ("... m.323 [1/2]") ve hepsi ayni hukmun parcasidir.
--  · kaynak_kod, rag.kaynak tablosuna baglanir; eski ambardan beslenen
--    kurulumlarda NULL birakilabilir ve yalniz desen kullanilir.
-- --------------------------------------------------------------------------
create table if not exists rag.konu_madde (
  id            bigint generated always as identity primary key,
  ders          text    not null,
  konu          text    not null,
  kaynak_kod    text    references rag.kaynak(kod) on delete set null,
  madde_deseni  text    not null,
  oncelik       int     not null default 1,
  not_          text,
  dogrulandi    boolean not null default false,   -- insan gozuyle teyit edildi mi
  olusturuldu   timestamptz not null default now(),
  guncellendi   timestamptz not null default now(),

  constraint uq_konu_madde unique (ders, konu, madde_deseni)
);

create index if not exists ix_konu_madde_arama
  on rag.konu_madde (rag.katla(ders), rag.katla(konu), oncelik);

comment on table rag.konu_madde is
  'Konu -> madde kalici eslesmesi. Arama kararsiz oldugu icin dayanak KAYITTAN okunur; arama yalniz yardimcidir.';
comment on column rag.konu_madde.dogrulandi is
  'true = bir insan bu eslesmeyi teyit etti. false = otomatik onerildi, HENUZ GUVENILMEZ.';

-- --------------------------------------------------------------------------
-- KONU KARTINDAN DAYANAK GETIR
--  Once kart aranir; kart yoksa bos doner ve cagiran taraf aramaya duser.
--  Bilincli: bu fonksiyon ARAMA YAPMAZ. Karti olan konu kesin cevap alir,
--  olmayan konu belirsizlige dusmez - ARADAKI FARK GORULUR.
-- --------------------------------------------------------------------------
create or replace function rag.konu_dayanak(
  p_ders text,
  p_konu text,
  p_adet int default 3
)
returns table (
  parca_id   bigint,
  kaynak_ad  text,
  madde_no   text,
  metin      text,
  oncelik    int,
  dogrulandi boolean
)
language sql
stable
as $$
  select p.id, k.ad, p.madde_no, p.metin, km.oncelik, km.dogrulandi
  from rag.konu_madde km
  join rag.kaynak k on (km.kaynak_kod is null or k.kod = km.kaynak_kod)
  join rag.parca  p on p.kaynak_id = k.id
  where rag.katla(km.ders) = rag.katla(p_ders)
    and rag.katla(km.konu) = rag.katla(p_konu)
    and (k.ad || ' ' || coalesce(p.madde_no,'')) ilike km.madde_deseni
  order by km.oncelik, p.sira
  limit greatest(coalesce(p_adet,3),1)
$$;

comment on function rag.konu_dayanak is
  'Konu kartindan dayanak getirir. ARAMA YAPMAZ - karti olmayan konu bos doner, cagiran taraf aramaya duser.';

-- --------------------------------------------------------------------------
-- KARTSIZ KONULAR — is emri gorunumu
--  Uretilmis sorulari olup karti OLMAYAN konular. Bunlar aramanin insafinda
--  demektir; kart yazilana kadar dayanaklari kararsizdir.
-- --------------------------------------------------------------------------
create or replace view rag.kartsiz_konular as
  select s.ders, s.konu, count(*) as soru_sayisi, min(s.olusturuldu) as ilk, max(s.olusturuldu) as son
  from rag.soru s
  where not exists (
    select 1 from rag.konu_madde km
     where rag.katla(km.ders) = rag.katla(s.ders)
       and rag.katla(km.konu) = rag.katla(s.konu))
  group by s.ders, s.konu
  order by count(*) desc;

comment on view rag.kartsiz_konular is
  'Sorusu uretilmis ama konu karti olmayan konular. Bunlarin dayanagi aramanin insafindadir - is emri.';

-- --------------------------------------------------------------------------
-- ILK BES KART: 10.09.2026'da UCTAN UCA DOGRULANDI
--  Bu bes konu icin soru uretildi, dayanak insan gozuyle okundu ve dogru
--  bulundu. dogrulandi = true YALNIZ bunun icin isaretlidir.
--  Not: 'vergi ziyai cezasi' ve 'degerleme olculeri' kartlari OLMASAYDI
--  arama yanlis madde getiriyordu (m.370 ve m.49) - kartin bedeli olculmustur.
-- --------------------------------------------------------------------------
insert into rag.konu_madde (ders, konu, madde_deseni, oncelik, dogrulandi, not_) values
  ('Vergi Mevzuatı ve Uygulaması','degerleme olculeri ve maliyet bedeli','%VUK (213 s.K.) m.261%',1,true,'Arama m.49 getiriyordu; kart duzeltti.'),
  ('Vergi Mevzuatı ve Uygulaması','amortisman ayirma sartlari',          '%VUK (213 s.K.) m.313%',1,true,'Amortisman mevzuu.'),
  ('Vergi Mevzuatı ve Uygulaması','supheli alacak karsiligi',            '%VUK (213 s.K.) m.323%',1,true,'Arama da buluyordu; kart kararliligi garanti eder.'),
  ('Vergi Mevzuatı ve Uygulaması','vergi ziyai cezasi',                  '%VUK (213 s.K.) m.344%',1,true,'Arama m.370 (Izaha davet) getiriyordu; kart duzeltti.'),
  ('Vergi Mevzuatı ve Uygulaması','vergi ziyai cezasi',                  '%VUK (213 s.K.) m.341%',2,true,'Vergi ziyai tanimi - ikincil dayanak.'),
  ('Vergi Mevzuatı ve Uygulaması','fatura duzenleme suresi',             '%VUK (213 s.K.) m.231%',1,true,'Fatura nizami.')
on conflict (ders, konu, madde_deseni) do nothing;

-- --------------------------------------------------------------------------
-- SURUM BEYANI
-- --------------------------------------------------------------------------
create or replace function rag.surum()
returns text language sql immutable as $$
  select '002_konu_madde / rag.ara v1 (RRF k=60) / konu_madde + konu_dayanak / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('002_konu_madde', 'Konu -> madde kalici eslesme katmani, konu_dayanak(), kartsiz_konular gorunumu, ilk 5 dogrulanmis kart.')
on conflict (surum) do nothing;
