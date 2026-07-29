-- ============================================================================
--  PERFORMANS KARNESI + YANLIS TEKRARI — 29.07.2026
--
--  NIYE: Aday nereye calisacagini bilmiyor. Sattigimiz sey soru sayisi degil,
--  YON. "Bu konuda %40'tasin, adaylarin ortalamasi %68" cumlesi, 5.000 sorudan
--  daha degerli. Amerikan hazirlik sirketlerinin en guclu tarafi bu ve bizde
--  hic yoktu.
--
--  KVKK: Kisisel veri YAZILMIYOR. Uye ise auth kimligi, degilse tarayicida
--  uretilen rastgele bir oturum kimligi tutulur. Ad, e-posta, IP YOK.
--
--  Supabase -> SQL Editor -> yapistir -> Run.
-- ============================================================================

create table if not exists public.cevap_kaydi (
  id          bigserial primary key,
  uye         uuid references auth.users(id) on delete set null,
  oturum      text,                       -- uye degilse tarayici kimligi (rastgele)
  soru_id     text not null,
  ders        text,
  konu        text,
  dogru       boolean not null,
  sure_ms     integer,
  tarih       timestamptz not null default now()
);

create index if not exists cevap_kaydi_konu_ix  on public.cevap_kaydi (ders, konu);
create index if not exists cevap_kaydi_uye_ix   on public.cevap_kaydi (uye);
create index if not exists cevap_kaydi_oturum_ix on public.cevap_kaydi (oturum);
create index if not exists cevap_kaydi_soru_ix  on public.cevap_kaydi (soru_id);

alter table public.cevap_kaydi enable row level security;

-- YAZMA: herkes kendi cevabini yazabilir (uye olmayan da - ornek oturum var).
drop policy if exists cevap_yaz on public.cevap_kaydi;
create policy cevap_yaz on public.cevap_kaydi
  for insert to anon, authenticated with check (true);

-- OKUMA: HAM SATIR KIMSEYE ACIK DEGIL. Baskasinin cevap gecmisini kimse goremez.
-- Akran ortalamasi asagidaki OZET gorunumunden okunur; orada kimlik yoktur.
-- (select politikasi bilerek YAZILMADI = kimse ham satir okuyamaz.)

-- ---------------------------------------------------------------- KONU OZETI
-- Akran ortalamasi. Kimlik icermez, yalniz konu bazinda toplam.
-- 20 cozumun altindaki konular DISARIDA: uc kisinin cozdugu konuda "ortalama"
-- demek yaniltir. Az veriyle rakam vermek, rakam vermemekten kotudur.
create or replace view public.konu_ortalama as
  select ders, konu,
         count(*)::int as cozum,
         round(100.0 * sum(case when dogru then 1 else 0 end) / count(*))::int as dogru_oran
  from public.cevap_kaydi
  where konu is not null and konu <> ''
  group by ders, konu
  having count(*) >= 20;

grant select on public.konu_ortalama to anon, authenticated;

-- ---------------------------------------------------------------- SORU OZETI
-- BOZUK SORU AVCISI'nin girdisi. Iki uc bize hakemin goremedigini soyler:
--   dogru_oran cok YUKSEK  -> soru ogretmiyor, yer kapliyor
--   dogru_oran cok DUSUK   -> soru muhtemelen BOZUK (hakemden gecmis olsa bile)
-- Bu iki uc hakemin onune geri gider; kalite dongusu boyle kapanir.
create or replace view public.soru_istatistik as
  select soru_id,
         count(*)::int as cozum,
         round(100.0 * sum(case when dogru then 1 else 0 end) / count(*))::int as dogru_oran
  from public.cevap_kaydi
  group by soru_id
  having count(*) >= 15;

grant select on public.soru_istatistik to anon, authenticated;
