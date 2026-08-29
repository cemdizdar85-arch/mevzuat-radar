-- ============================================================================
-- GUVENLIK KAPISI - 29.08.2026
-- ============================================================================
-- Cem'in sorusu: "siteyi saldirilara karsi koruma altina aldik mi, bot uyeligin
-- onune gecelim". Olculdu, tek gercek acik kapi cikti: leadler tablosunda
-- anonim INSERT izni var ve BU IZNI KULLANAN HICBIR SEY YOK.
--
-- OLCUM (29.08, anon anahtarla, canli projede):
--   POST /rest/v1/leadler  {}  ->  23502 "null value in column eposta"
--       ^ RLS yazmayi ENGELLEMEDI; sadece NOT NULL kisiti durdurdu.
--         Yani gecerli bir e-posta yazan biri SINIRSIZ satir basabilir.
--   POST /rest/v1/soru_havuzu  {}  ->  42501 (RLS engelledi)   ✅ saglam
--   POST /rest/v1/paket_uyeler {}  ->  42501 (RLS engelledi)   ✅ saglam
--
-- KAPATMANIN MALIYETI SIFIR - cunku kullanan yok:
--   'leadler' deposunda sadece motor/veri-katalogu.ps1'de gecer ("site formu"
--   diye etiketli). Ama sitedeki formlarin HICBIRI oraya yazmiyor:
--   perde formu (menu.js) ve diger kayit formlari web3forms'a POST ediyor.
--   .html/.js dosyalarinda 'leadler' gecen tek satir bile yok (olculdu).
--
-- Yani bu, kimsenin girmedigi ama herkese acik duran bir kapi. Kapatiyoruz.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0) ONCE BAK - neyi degistirdigimizi gorelim (bu blok hicbir sey degistirmez)
-- ---------------------------------------------------------------------------
select 'ONCEKI POLITIKALAR' as bolum, polname as politika,
       case polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                   when 'w' then 'UPDATE' when 'd' then 'DELETE'
                   else 'ALL' end as islem,
       pg_get_expr(polqual,  polrelid) as okuma_kosulu,
       pg_get_expr(polwithcheck, polrelid) as yazma_kosulu
  from pg_policy
 where polrelid = 'public.leadler'::regclass;

select 'ONCEKI IZINLER' as bolum, grantee, privilege_type
  from information_schema.role_table_grants
 where table_schema = 'public' and table_name = 'leadler'
   and grantee in ('anon','authenticated');

-- ---------------------------------------------------------------------------
-- 1) KAPIYI KAPAT
-- ---------------------------------------------------------------------------
-- 1a) Tablo seviyesindeki izni geri al. Bunu politika adindan BAGIMSIZ yapiyoruz
--     cunku politikanin adi panelden elle verilmis olabilir (depoda kayitli
--     degil - leadler icin repoda hic .sql yok, sema takip disi kalmis).
revoke insert, update, delete on public.leadler from anon;

-- 1b) Ayrica anon'a INSERT/UPDATE/DELETE acan politikalari da dusur.
--     Isimleri bilmedigimiz icin donerek buluyoruz; SELECT politikalarina
--     DOKUNMUYORUZ (okuma zaten bos donuyor, kirmaya gerek yok).
do $$
declare p record;
begin
  for p in
    select polname
      from pg_policy
     where polrelid = 'public.leadler'::regclass
       and polcmd in ('a','w','d')                    -- INSERT / UPDATE / DELETE
       and (polroles = '{0}'::oid[]                   -- PUBLIC (herkes)
            or 'anon'::regrole::oid = any(polroles))
  loop
    execute format('drop policy if exists %I on public.leadler', p.polname);
    raise notice 'dusuruldu: %', p.polname;
  end loop;
end $$;

-- 1c) RLS acik kalsin (kapali olsaydi politikalar hic islemezdi).
alter table public.leadler enable row level security;

-- ---------------------------------------------------------------------------
-- 2) DOGRULAMA - bu sorgudan sonra anon'da INSERT gorunmemeli
-- ---------------------------------------------------------------------------
select 'SONRAKI IZINLER' as bolum, grantee, privilege_type
  from information_schema.role_table_grants
 where table_schema = 'public' and table_name = 'leadler'
   and grantee in ('anon','authenticated');

select 'SONRAKI POLITIKALAR' as bolum, polname,
       case polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                   when 'w' then 'UPDATE' when 'd' then 'DELETE'
                   else 'ALL' end as islem
  from pg_policy
 where polrelid = 'public.leadler'::regclass;

-- ---------------------------------------------------------------------------
-- 3) BASTIKTAN SONRA DISARIDAN OLC (terminalden, anon anahtarla):
--
--   curl -s -X POST \
--     "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/leadler" \
--     -H "apikey: <anon anahtar>" -H "Content-Type: application/json" \
--     -d '{}' -w " [HTTP %{http_code}]"
--
--   BEKLENEN: 42501 / "violates row-level security policy"  ya da  401.
--   HALA 23502 goruyorsan kapi kapanmamistir - bana soyle.
-- ---------------------------------------------------------------------------

-- ============================================================================
-- BILEREK YAPILMAYANLAR (sorulursa cevabi burada):
--
-- * 'lead_kaydet' RPC'si YAZILMADI. Ileride perde/kayit formunu web3forms
--   yerine kendi kasamiza baglarsak gerekecek; o gun rate_limit_check ile
--   (radar-app/sql/2026-07-17-rate-limit.sql - zaten var, anon'a acik)
--   hizi sinirlanmis bir SECURITY DEFINER fonksiyon yazilir. Bugun yazmadim
--   cunku leadler'in kolonlarini OLCEMEDIM: PostgREST sema listelemesi gizli
--   anahtar istiyor ("Secret API key required"), ben de kolon adi UYDURMAK
--   yerine bos biraktim. Formu baglama gunu once semayi okuyacagiz.
--
-- * soru_havuzu / paket_uyeler'e DOKUNULMADI. Ikisi de olculdu ve saglam:
--   yazma 42501 ile kapali; okuma ise paket_uyeler'de gecerli satir sarti
--   ariyor (radar-app/sql/2026-07-27-paket-ayrimi.sql). Yani paketsiz uye -
--   bot olsun insan olsun - soru havuzundan SIFIR satir gorur. Soru bankasi
--   JavaScript'e degil veritabanina emanet; dogru yerde duruyor.
-- ============================================================================
