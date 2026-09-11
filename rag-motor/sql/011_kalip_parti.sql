-- ============================================================================
--  011_kalip_parti.sql — PARTI ONBELLEGI AMBARA  (11.09.2026)
--  Cem: "bulut hattini simdi kuralim, bagimsiz denetim ve SPK da var"
--
--  NIYE: kalip uretim hattinin onbellegi (veri/fabrika/kalip-parti-*.json)
--  YALNIZ Cem'in dizustunde duruyor ve .gitignore'da. Sonuc:
--    - uretim yalnizca o makinede kosabiliyor
--    - makinenin RAM'i 10 es zamanli surecte doluyor (olculdu: 180 MB/surec,
--      736 MB bos, takas 2.385 MB) -> gece ~846 soru
--    - GitHub Actions'ta kosulsa is bitince onbellek KAYBOLUYOR
--  Bu tablo o bagi kesiyor: parti kaydi ambarda durur, yerel de bulut da
--  ayni yerden okur/yazar. RAM tavani kalkar, ucu sinav (SGS/SMMM/KGK/SPK)
--  ayni hattan gecer.
--
--  ⚠ ICERIK OLDUGU GIBI TASINIR. Parti JSON'u uretici icin TEK GERCEK kaynak;
--    burada sema DAYATILMAZ (alanlar surekli degisiyor: hakem, hesap_uyum,
--    sade, ikiz, atif_genisletme...). jsonb olarak aynen saklanir.
--
--  ⚠ BOY: olculdu - ortalama 458 KB, en buyuk 3,2 MB. Postgres jsonb bunu
--    TOAST ile sikistirarak tasir; satir basina sinir sorun degil.
--
--  ⛔ BU DOSYA KENDILIGINDEN CALISMAZ. Cem Supabase SQL editorunden basar,
--     sonra radar-app/sql/UYGULANDI.md'ye satir dusulur (goc kutugu kurali).
-- ============================================================================

-- ⛔ 11.09 22:20 — TABLOLAR ONCE `rag` SEMASINDA KURULDU, PostgREST GORMEDI.
--    Supabase API'si yalniz "exposed schemas" listesindeki semalari yayinlar;
--    `rag` listede olmadigi icin /rest/v1/kalip_parti 404 dondu:
--      PGRST205 "Could not find the table 'public.kalip_parti'"
--    Depodaki betiklerin HEPSI sema oneksiz cagiriyor (/rest/v1/<tablo>).
--    `rag`i yayinlamak her cagriya `Accept-Profile: rag` basligi eklemek
--    demekti - 480 betige dokunmak. Ucuz ve geri donusu olan yol: public.
--    ⚠ GUVENLIK AYNI KALIR: RLS acik + POLITIKA YOK => anon/authenticated
--      hicbir satir goremez; service_role RLS'i zaten atlar.
drop table if exists rag.kalip_parti  cascade;
drop table if exists rag.bedel_kaydi  cascade;
drop table if exists rag.konu_koprusu cascade;
drop view  if exists rag.bedel_aylik;

create table if not exists public.kalip_parti (
  etiket        text primary key,
  sinav         text not null default 'SGS',
  icerik        jsonb not null,              -- parti dosyasinin TAMAMI
  soru_sayisi   int  not null default 0,
  -- Ayni partiyi iki surec ayni anda yazarsa SON YAZAN kazanir; ama hangi
  -- makinenin yazdigi kayda gecer ki cakisma goruldugunde izi surulebilsin.
  yazan         text,
  guncelleme    timestamptz not null default now()
);

comment on table  public.kalip_parti is
  'Kalip uretim hattinin parti onbellegi. Yerel veri/fabrika/kalip-parti-<etiket>.json ile AYNI icerik. Yerel ve bulut (GitHub Actions) ayni yerden okur/yazar.';
comment on column public.kalip_parti.icerik is
  'Parti JSON dosyasinin TAMAMI. Sema DAYATILMAZ - uretici alan ekledikce buraya aynen yansir.';
comment on column public.kalip_parti.yazan is
  'Son yazan makine/is (ornek: "yerel-cem", "actions-12345"). Cakisma teshisi icin.';

create index if not exists kalip_parti_sinav_idx      on public.kalip_parti (sinav);
create index if not exists kalip_parti_guncelleme_idx on public.kalip_parti (guncelleme desc);

-- Guncelleme damgasi elle yazilmasin
create or replace function public.kalip_parti_damga() returns trigger as $$
begin
  new.guncelleme := now();
  -- soru_sayisi icerikten TURETILIR; cagiranin yanlis sayi yazmasi engellenir
  new.soru_sayisi := (
    select count(*) from jsonb_each(new.icerik) e
    where e.value ? 'soru' and length(coalesce(e.value->>'soru','')) > 0
  );
  return new;
end $$ language plpgsql;

drop trigger if exists kalip_parti_damga_trg on public.kalip_parti;
create trigger kalip_parti_damga_trg
  before insert or update on public.kalip_parti
  for each row execute function public.kalip_parti_damga();

-- PostgREST public semasini varsayilan olarak yayinlar - ek ayar gerekmez.
-- (public semasinda usage zaten var - Supabase varsayilani)
grant select, insert, update, delete on public.kalip_parti to service_role;

-- ⚠ RLS: bu tablo YALNIZ service_role ile yazilir (uretici ve Actions).
--   Tarayiciya acilmaz - icinde henuz denetlenmemis soru metni var.
alter table public.kalip_parti enable row level security;
-- service_role RLS'i zaten atlar; anon/authenticated icin POLITIKA YOK = erisim YOK.


-- ============================================================================
--  2) BEDEL DEFTERI — ⛔ EN KRITIK TABLO
--
--  Cem sordu: "kalitemizden olusturdugumuz kurallar, hicbirinde sikinti olmaz
--  de mi patron". OLCTUM ve CEVAP HAYIRDI. En tehlikeli bulgu bu:
--
--  kalip-kosucu.ps1 AYLIK TAVANI yerel bir dosyadan okuyor:
--      veri/fabrika/bedel-kayit.jsonl   (.gitignore'da, 130 KB)
--  Kodun kendi satiri:
--      if(-not (Test-Path $y)){ return $t }     <- dosya yoksa 0 DONDURUR
--  Actions'ta o dosya YOK -> defter BOS -> "bu ay 0 USD harcanmis" ->
--  1.700 USD durma esigi HIC TETIKLENMEZ. Fren pedali var, kablosu
--  Cem'in dizustunde kaliyor.
--
--  Bu tablo freni HER YERE tasir. Yerel kosu da buraya yazar, bulut da;
--  ikisi ayni toplami gorur.
--  ⚠ KURAL: bulut kosusu, fren PROVASI gecmeden baslatilmaz - ambara sahte
--    1.700 USD yazilip kosucunun DURDUGU gorulecek. Kapiyi olcmeden kurmak
--    bu oturumda dort kez zarar verdi.
-- ============================================================================
create table if not exists public.bedel_kaydi (
  id          bigserial primary key,
  zaman       timestamptz not null default now(),
  etiket      text not null,              -- parti etiketi
  ders        text,
  toplam_usd  numeric(10,4) not null,
  varsayim    boolean not null default true,   -- fiyat tablosu varsayimsa true
  satirlar    jsonb,                      -- model bazli jeton dokumu
  yazan       text,                       -- "yerel-<makine>" | "actions-<runid>"
  -- Ayni parti iki kez kosarsa IKI SATIR olur; bu DOGRU - iki kez odendi.
  -- Tekillestirme YAPILMAZ: defter harcamanin kaydidir, partinin degil.
  --
  -- ⛔ ILK SURUMDE BURASI SOYLEYDI:
  --      ay text generated always as (to_char(zaman,'YYYY-MM')) stored
  --    Postgres REDDETTI: 42P17 "generation expression is not immutable".
  --    Sebep: to_char(timestamptz,text) STABLE'dir - sonucu oturumun TimeZone
  --    ayarina bagli, dolayisiyla uretilmis kolonda kullanilamaz. (Ayni ifade
  --    timestamp WITHOUT time zone icin immutable olurdu.)
  --    Cozum: normal kolon + tetikleyici. Tetikleyicide oynaklik serbest ve
  --    saat dilimi ACIKCA yazilir (UTC) - "sunucunun ayari neydi" sorusu
  --    bir daha sorulmaz.
  ay          text
);
comment on table public.bedel_kaydi is
  'Harcama defteri. kalip-kosucu.ps1 aylik tavani BURADAN okur. Yerel dosya (veri/fabrika/bedel-kayit.jsonl) ile AYNI icerik; bulutta yerel dosya olmadigi icin tavan ancak bu tabloyla calisir.';
-- `ay` kolonunu cagiran DEGIL tetikleyici doldurur: yanlis ay yazilamaz.
-- UTC acikca yazilir; yerel defter Istanbul saatiyle damgaliyor, senkron
-- bunu ISO-8601 ile gonderiyor - ay siniri disinda fark uretmez.
create or replace function public.bedel_kaydi_damga() returns trigger as $$
begin
  new.ay := to_char(new.zaman at time zone 'UTC','YYYY-MM');
  return new;
end $$ language plpgsql;

drop trigger if exists bedel_kaydi_damga_trg on public.bedel_kaydi;
create trigger bedel_kaydi_damga_trg
  before insert or update on public.bedel_kaydi
  for each row execute function public.bedel_kaydi_damga();

create index if not exists bedel_kaydi_ay_idx    on public.bedel_kaydi (ay);
create index if not exists bedel_kaydi_zaman_idx on public.bedel_kaydi (zaman desc);

-- Aylik toplam: kosucunun tek sorguyla okuyacagi gorunum
create or replace view public.bedel_aylik as
  select ay, sum(toplam_usd)::numeric(12,4) as toplam_usd, count(*) as parti
  from public.bedel_kaydi group by ay;
comment on view public.bedel_aylik is
  'Ay bazli harcama toplami. AyHarcama() bunu okur: ?select=toplam_usd&ay=eq.YYYY-MM';

alter table public.bedel_kaydi enable row level security;
grant select, insert on public.bedel_kaydi to service_role;
grant usage, select on sequence public.bedel_kaydi_id_seq to service_role;
grant select on public.bedel_aylik to service_role;


-- ============================================================================
--  3) KONU KOPRUSU — cikmis sinav sikligi
--
--  veri/fabrika/konu-koprusu.json (6,7 MB · 21.333 kayit) da .gitignore'da.
--  Uretici KONU SECIMINI bundan yapiyor. Bulutta yoksa "kopru disi sentez"
--  yoluna duser; o yolda dayanak BOS kalir, kaynak paketi zayiflar ve
--  KAYNAK-EKSIK reti artar. 11.09'da butun gun o kusuru kapatmakla ugrasildi
--  (777 ret, tum retlerin %54'u); bulut onu geri getirirdi.
--
--  ⚠ TEK SATIR DEGIL, KAYIT KAYIT: 6,7 MB'lik tek jsonb her is basinda
--    indirilmek zorunda kalirdi. Sinav bazli cekilebilsin diye satirlanmis.
-- ============================================================================
create table if not exists public.konu_koprusu (
  id            bigserial primary key,
  sinav         text not null,
  konu          text not null,
  bizim_ders    text,
  arsiv_ders    text,
  cikmis        int  not null default 0,    -- cikmis arsivde KAC SORU
  donem         int  not null default 0,    -- KAC DONEMDE gorulmus
  durum         text,
  dayanak       text,
  cikmis_dayanak text,
  guc           text,
  guncelleme    timestamptz not null default now(),
  unique (sinav, konu)
);
comment on table public.konu_koprusu is
  'Cikmis sinav arsivinden turetilen konu-siklik koprusu. `cikmis` = o konudan cikmis arsivde kac soru sorulmus. Uretim plani ve konu secimi bunu okur.';
create index if not exists konu_koprusu_sinav_idx  on public.konu_koprusu (sinav);
create index if not exists konu_koprusu_cikmis_idx on public.konu_koprusu (sinav, cikmis desc);

alter table public.konu_koprusu enable row level security;
grant select, insert, update, delete on public.konu_koprusu to service_role;
grant usage, select on sequence public.konu_koprusu_id_seq to service_role;


-- ============================================================================
--  BASILDIKTAN SONRA
--    1) radar-app/sql/UYGULANDI.md'ye satir dusulur (goc kutugu kurali)
--    2) arac/parti-senkron.ps1 -Yukle -Yaz        (parti onbellegi ambara)
--    3) arac/bedel-senkron.ps1 -Yukle -Yaz        (defter ambara)
--    4) arac/kopru-senkron.ps1 -Yukle -Yaz        (kopru ambara)
--    5) ⛔ FREN PROVASI: ambara sahte 1.700 USD yazilir, kosucunun DURDUGU
--       olculur. GECMEDEN BULUT KOSUSU YOK.
-- ============================================================================