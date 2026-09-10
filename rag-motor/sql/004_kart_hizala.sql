-- ============================================================================
--  TETIKTE RAG MOTORU — 004_kart_hizala.sql
--  KONU KARTLARINI YENI SEMANIN ADLANDIRMASIYLA HIZALA
--
--  IDEMPOTENT. ONKOSUL: 003_ara_v2 basili olmali.
--
--  ============================================================================
--  NEDEN — MOTORUN IKINCI KOSUSUNDA OLCULDU (10.09.2026)
--  ============================================================================
--  003'ten sonra motor dayanak bulmaya basladi ama gunlukte BES konunun de
--  yaninda "dayanak yolu = hibrit arama" yaziyordu. Yani KONU KARTLARI HIC
--  DEVREYE GIRMEDI - oysa 002 ile alti kart basilmisti.
--
--  Sebep: kartlar ESKI ambarin adlandirmasiyla yazilmisti.
--      madde_deseni = '%VUK (213 s.K.) m.261%'
--  Yeni semada ise kaynak adi farkli:
--      rag.kaynak.ad = 'Vergi Usul Kanunu (213 s.K.)'   ·   parca.madde_no = 'm.261'
--  rag.konu_dayanak eslesmeyi (k.ad || ' ' || p.madde_no) uzerinden yaptigi
--  icin desen HIC tutmuyordu ve fonksiyon sessizce BOS donuyordu.
--
--  DERS: kart bir METIN DESENI degil, bir BAGLANTI olmali. Kaynak KODU ile
--  baglanir (kaynak_kod), madde deseni yalnizca madde numarasini secer.
--  Kaynak adi degisirse kart bozulmaz - kod degismedigi surece.
--
--  Bu ayni zamanda "kart devreye girdi mi" sorusunun neden gunluge yazildigini
--  gosteriyor: yazilmasaydi kartlarin calismadigi FARK EDILMEZDI, cunku arama
--  yine de bir cevap donduruyor. Sessiz basarisizligin panzehiri gorunurluktur.
-- ============================================================================

-- VUK kaynagi yutulmus olmali; yoksa kartlar baglanacak yer bulamaz.
do $$
begin
  if not exists (select 1 from rag.kaynak where kod = 'VUK-213') then
    raise notice 'UYARI: rag.kaynak icinde VUK-213 yok - once VUK yutulmali.';
  end if;
end $$;

-- Kartlari kaynak KODUNA bagla ve deseni yalniz madde numarasina indir.
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.261%', guncellendi = now()
  where konu = 'degerleme olculeri ve maliyet bedeli';
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.313%', guncellendi = now()
  where konu = 'amortisman ayirma sartlari';
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.323%', guncellendi = now()
  where konu = 'supheli alacak karsiligi';
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.344%', guncellendi = now()
  where konu = 'vergi ziyai cezasi' and madde_deseni like '%344%';
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.341%', guncellendi = now()
  where konu = 'vergi ziyai cezasi' and madde_deseni like '%341%';
update rag.konu_madde set kaynak_kod = 'VUK-213', madde_deseni = '%m.231%', guncellendi = now()
  where konu = 'fatura duzenleme suresi';

-- ============================================================================
--  rag.konu_dayanak v2 — eslesme MADDE NO uzerinden, kaynak KOD ile sinirli
--
--  v1 (k.ad || ' ' || madde_no) ilike deseni ile esliyordu; kaynak adi
--  degisince kart bozuluyordu. v2 kaynak_kod ile SINIRLAR, deseni yalniz
--  madde_no'ya uygular. Dilimlenmis maddeler ("m.323 [1/2]") de tutar.
-- ============================================================================
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
  join rag.kaynak k
    on (km.kaynak_kod is null or k.kod = km.kaynak_kod)
  join rag.parca p
    on p.kaynak_id = k.id
   and coalesce(p.madde_no,'') ilike km.madde_deseni
  where rag.katla(km.ders) = rag.katla(p_ders)
    and rag.katla(km.konu) = rag.katla(p_konu)
  order by km.oncelik, p.karakter_sayisi desc, p.sira
  limit greatest(coalesce(p_adet,3),1)
$$;

comment on function rag.konu_dayanak is
  'Konu kartindan dayanak. v2: eslesme kaynak_kod + madde_no uzerinden (v1 kaynak ADI kullaniyordu ve yeni semada hic tutmuyordu). ARAMA YAPMAZ.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '004_kart_hizala / rag.ara v2 (RRF k=60, FTS VEYA + onek) / konu_dayanak v2 (kaynak_kod + madde_no) / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('004_kart_hizala', 'Konu kartlari kaynak koduna baglandi; konu_dayanak v2 madde_no uzerinden esliyor. v1 eski ambarin kaynak adiyla yazildigi icin hic tutmuyordu.')
on conflict (surum) do nothing;

-- Dogrulama: kartlar artik tutuyor mu?
select km.konu, km.madde_deseni, count(p.id) as eslesen_parca
from rag.konu_madde km
left join rag.kaynak k on k.kod = km.kaynak_kod
left join rag.parca  p on p.kaynak_id = k.id and coalesce(p.madde_no,'') ilike km.madde_deseni
group by km.konu, km.madde_deseni, km.oncelik
order by km.konu, km.oncelik;
