-- ============================================================================
--  MARKA BÜLTENİ AMBARI  (30.08.2026)
--
--  Cem: "yeni marka başvurularını görmek istiyorum... müşterimizin markası ile
--  başka yerden yeni başvuru geldiğinde nasıl görürüz."
--
--  NEDEN BÜLTEN (30.08'de ölçüldü, tahmin değil):
--   · TMview aynası: 3 koşu, 3 başarısız, 0 kayıt - kaynak bizi bot korumasına
--     aldı (HTTP 200 + engel sayfası, hem bizim IP'den hem GitHub'dan).
--   · Resmî Marka Bülteni: 477 MB PDF, 5 dk 17 sn'de indi, 3.520 sayfadan
--     7.860 kayıt çıktı, DÖRT ALANIN DÖRDÜ DE %100 dolu. Engel yok, üyelik yok.
--   · Hukuken ASIL olan budur: itiraz süresi (SMK m.18, 2 ay) bültenin YAYIM
--     tarihinden işler. TMview bunun ikinci elden kopyasıdır.
--
--  SINIR - KARIŞTIRMA: Bülten yalnız YENİ BAŞVURULARI verir. "Bu marka düşmüş
--  mü / yenilenmiş mi" sorusuna CEVAP VERMEZ; o geçmiş sicil işidir (ayrı).
--
--  GÜVENLİK: kasa deseni - RLS AÇIK, POLİTİKA YOK. Yani anon/authenticated
--  tabloyu doğrudan HİÇ okuyamaz; yalnız aşağıdaki SECURITY DEFINER
--  fonksiyonlar üzerinden, tavanlı ve süzülmüş veri çıkar. 7.860 kayıtlık
--  ambarın toptan çekilmesini bu engeller.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0) pg_trgm - ŞEMASI VARSAYILMAZ, BULUNUR
--    30.08 CANLI HATA: "extensions.gin_trgm_ops does not exist for access
--    method gin". Sebep: pg_trgm'in HANGİ şemada kurulu olduğunu varsaymıştım.
--    Supabase kurulumdan kuruluma değişiyor (extensions / public). Artık
--    eklenti nereye kuruluysa oradan okunuyor; tahmin yok.
-- ---------------------------------------------------------------------------
do $ext$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_trgm') then
    begin
      execute 'create extension pg_trgm with schema extensions';
    exception when others then
      execute 'create extension pg_trgm';        -- extensions şeması yoksa
    end;
  end if;
end $ext$;

-- ---------------------------------------------------------------------------
-- 1) NORMALİZASYON - tek doğru yer burası
--    PowerShell/JS tarafındaki Norm() ile AYNI sonucu vermek ZORUNDA.
--    (29.08 dersi: .NET'te 'İ'.ToLower() Windows'ta 'i', Linux'ta 'i'+U+0307
--    veriyordu ve bütün i'ler kayboluyordu. Burada kültür yok, harf harf
--    çeviri var - makineye göre değişmez.)
-- ---------------------------------------------------------------------------
create or replace function public.marka_norm(p text)
returns text language sql immutable as $$
  select coalesce(
    regexp_replace(
      translate(lower(coalesce(p,'')),
                'çğıîöşüâûİI',
                'cgiiosuau' || 'i' || 'i'),
      '[^a-z0-9]', '', 'g'),
    '');
$$;

-- ---------------------------------------------------------------------------
-- 2) AMBAR
--    Anahtar (basvuru_no, bulten_no): aynı başvuru birden fazla bültende
--    yayımlanabilir (düzeltme/yeniden ilan). Tek anahtar yapsaydık ikincisi
--    birincisini ezerdi ve İLK yayım tarihini - yani itiraz süresinin
--    başlangıcını - kaybederdik.
-- ---------------------------------------------------------------------------
create table if not exists public.marka_bulten (
  basvuru_no     text        not null,
  bulten_no      int         not null,
  yayin_tarihi   date        not null,
  basvuru_tarihi date,
  ad             text        not null,
  ad_norm        text        not null,
  sahip          text,
  sahip_norm     text,
  vekil          text,
  sinif          int[]       not null default '{}',
  mal_hizmet     text,
  itiraz_son     date        not null,   -- yayin_tarihi + 2 ay (SMK m.18)
  eklendi        timestamptz not null default now(),
  primary key (basvuru_no, bulten_no)
);

-- Trigram indeksi: operatör sınıfı pg_trgm'in GERÇEK şemasından alınır.
do $ix$
declare s text;
begin
  select n.nspname into s
    from pg_extension e join pg_namespace n on n.oid = e.extnamespace
   where e.extname = 'pg_trgm';
  if s is null then raise exception 'pg_trgm kurulu degil - 0. adim dusmus.'; end if;
  execute format(
    'create index if not exists ix_mb_adnorm on public.marka_bulten using gin (ad_norm %I.gin_trgm_ops)', s);
  raise notice 'pg_trgm semasi: %', s;
end $ix$;

create index if not exists ix_mb_sinif   on public.marka_bulten using gin (sinif);
create index if not exists ix_mb_yayin   on public.marka_bulten (yayin_tarihi desc);
create index if not exists ix_mb_itiraz  on public.marka_bulten (itiraz_son);
create index if not exists ix_mb_sahip   on public.marka_bulten (sahip_norm);

alter table public.marka_bulten enable row level security;
-- POLİTİKA BİLEREK YOK: doğrudan okuma kapalı.

-- Hangi bülten yutuldu - "eksik var mı?" sorusunun TEK cevabı burasıdır.
create table if not exists public.marka_bulten_kutuk (
  bulten_no    int primary key,
  yayin_tarihi date not null,
  kayit        int  not null default 0,
  boyut_bayt   bigint,
  durum        text not null default 'bekliyor',   -- bekliyor | bitti | hata
  not_         text,
  guncelleme   timestamptz not null default now()
);
alter table public.marka_bulten_kutuk enable row level security;

-- ---------------------------------------------------------------------------
-- 3) KASA KAPILARI (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

-- (a) İTİRAZ TARAMASI - ürünün para kazanan sorusu.
--     "Benim markama benzer, YENİ yayımlanmış, AYNI SINIFTA başvuru var mı?"
--     SMK m.6/1: karıştırılma ihtimali işaret + sınıf birlikteliğiyle doğar.
--     Bu yüzden sınıf kesişimi burada, sunucuda süzülür.
--     🔴 30.08 CANLI KUSUR: p_gun "son N günde YAYIMLANAN" demek; süresi
--     DOLMUŞ kayıtlar da dönüyordu (kalan_gun -18 gibi). Rakam doğruydu ama
--     müşteri ekranda görüp "itiraz edebilirim" sanardı - doğru veriyle yanlış
--     vaat. p_yalniz_acik VARSAYILAN TRUE: süresi geçmiş kayıt ancak bilerek
--     istenirse döner.
drop function if exists public.marka_bulten_itiraz(text, int[], int, real, int);
create or replace function public.marka_bulten_itiraz(
  p_ad          text,
  p_sinif       int[]   default null,
  p_gun         int     default 60,
  p_esik        real    default 0.32,
  p_tavan       int     default 100,
  p_yalniz_acik boolean default true)
returns table (
  basvuru_no text, bulten_no int, yayin_tarihi date, itiraz_son date,
  kalan_gun int, ad text, sahip text, sinif int[], benzerlik real, ayni_sinif boolean)
language sql security definer set search_path = public, extensions as $$
  with h as (select public.marka_norm(p_ad) as n)
  select b.basvuru_no, b.bulten_no, b.yayin_tarihi, b.itiraz_son,
         (b.itiraz_son - current_date)::int as kalan_gun,
         b.ad, b.sahip, b.sinif,
         similarity(b.ad_norm, h.n) as benzerlik,
         (p_sinif is not null and b.sinif && p_sinif) as ayni_sinif
    from public.marka_bulten b, h
   where h.n <> ''
     and b.yayin_tarihi >= current_date - greatest(p_gun,1)
     and (b.ad_norm % h.n or b.ad_norm like '%' || h.n || '%')
     and similarity(b.ad_norm, h.n) >= p_esik
     and (p_sinif is null or b.sinif && p_sinif)
     and (not p_yalniz_acik or b.itiraz_son >= current_date)
   order by (p_sinif is not null and b.sinif && p_sinif) desc,
            similarity(b.ad_norm, h.n) desc,
            b.itiraz_son asc
   limit least(greatest(p_tavan,1), 300);
$$;

-- (b) Bir firmanın bültendeki başvuruları (unvanla)
create or replace function public.marka_bulten_sahip(p_unvan text, p_tavan int default 200)
returns table (basvuru_no text, yayin_tarihi date, basvuru_tarihi date,
               ad text, sinif int[], itiraz_son date)
language sql security definer set search_path = public, extensions as $$
  select b.basvuru_no, b.yayin_tarihi, b.basvuru_tarihi, b.ad, b.sinif, b.itiraz_son
    from public.marka_bulten b
   where public.marka_norm(p_unvan) <> ''
     and b.sahip_norm like '%' || public.marka_norm(p_unvan) || '%'
   order by b.yayin_tarihi desc
   limit least(greatest(p_tavan,1), 500);
$$;

-- (c) Ambarın durumu - "ne var elimizde" sorusunun ölçülmüş cevabı.
create or replace function public.marka_bulten_durum()
returns table (kayit bigint, bulten bigint, ilk_yayin date, son_yayin date,
               acik_itiraz bigint)
language sql security definer set search_path = public as $$
  select (select count(*) from public.marka_bulten),
         (select count(*) from public.marka_bulten_kutuk where durum='bitti'),
         (select min(yayin_tarihi) from public.marka_bulten),
         (select max(yayin_tarihi) from public.marka_bulten),
         (select count(*) from public.marka_bulten where itiraz_son >= current_date);
$$;

revoke all on function public.marka_bulten_itiraz(text,int[],int,real,int,boolean) from public;
revoke all on function public.marka_bulten_sahip(text,int)                 from public;
revoke all on function public.marka_bulten_durum()                         from public;
grant execute on function public.marka_bulten_itiraz(text,int[],int,real,int,boolean) to anon, authenticated;
grant execute on function public.marka_bulten_sahip(text,int)                 to anon, authenticated;
grant execute on function public.marka_bulten_durum()                         to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4) TEYİT (aynı pencerede çalıştır)
--      select * from public.marka_bulten_durum();
--      select * from public.marka_bulten_itiraz('tetikte', array[9,42], 90);
--    Beklenen ilk koşuda: kayit=0. Robot bülteni yutunca dolar.
-- ---------------------------------------------------------------------------
