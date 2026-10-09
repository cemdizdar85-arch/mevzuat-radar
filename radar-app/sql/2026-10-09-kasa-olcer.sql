-- ============================================================================
-- KASA OLCER - paket sorulari yalniz sayilan, tavanli fonksiyonlardan verilir (09.10.2026)
--
-- NEDEN (Cem 09.10: "sitede soruyu gorun, bilgisayara indiremesin; bu isi en iyi yapan
-- nasil yapiyorsa onun aynisini yap"): olcum 09.10 - paketli uye tarayici konsolundan ya da
-- ayni anahtarla dogrudan /rest/v1/paket_soru adresinden paketindeki BUTUN dersleri sinirsiz
-- cekebiliyordu; kim kac soru cekti kutugu YOKTU. UWorld sozlesmesi (terms_conditions.aspx,
-- 09.10 okundu) "reasonable use": kisa surede cok test acma ve aboneligin tamaminin 2,5 katindan
-- fazla kullanim -> askiya alma. Bu dosya o olcme katmaninin veritabani ayagi.
--
-- NE DEGISIR:
--   1) paket_soru tablosundan authenticated'in DOGRUDAN okuma hakki GERI ALINIR (RLS politikasi
--      durur, zararsiz). ucretsiz_soru gorunumu tablo sahibiyle okur (security_invoker kapali,
--      2026-09-16) -> etkilenmez. seviye_kontrol / seviye_aciklama* security definer -> etkilenmez.
--   2) Okuma yalniz uc fonksiyondan: kasa_soru_getir (sayfa, parca <=100), kasa_soru_idler
--      (id listesi <=100), kasa_dizin (yalniz kimlik/ders/sayfa/donem, icerik yok, sayilmaz).
--      Paket kurali paket_erisim_var() icinde, 2026-09-16 politikasiyla BIREBIR.
--   3) Her icerik cekimi kasa_cekim kutugune yazilir (uye, sayfa, bas, adet, IP, zaman).
--   4) TAVAN (uye basina, satir): 10 dakikada 1.500 (en buyuk ders Finansal Muhasebe 1.100
--      satir tek acilista iner) - 24 saatte 4.000 - 7 gunde 12.000. Asimda fonksiyon
--      'KASA_TAVAN:<pencere>' hatasi verir, kutuge 'TAVAN:' satiri duser (adet 0, sayilmaz).
--   5) uye_sayim() iki alan daha doner: kasa_tavan_24s (tavana takilan uye) ve kasa_asiri_24s
--      (24 saatte 2.500+ satir ceken uye). motor/uye-alarmi.ps1 bunlari SARI sayar.
--
-- KISI VERISI: kutukte user_id + IP var, yalnizca veritabaninda; anon/authenticated OKUYAMAZ,
-- robot yalnizca SAYI alir (uye_sayim). Sozlesme m.5 (sistematik kopyalama yasak) dayanak.
--
-- DDL NOTU: auth.users'a FK YOK (14.09 PostgREST 503 dersi). Tabloya RLS acik + politika yok.
-- Revoke sonrasi PostgREST sema onbellegi kendiliginden yenilenir.
--
-- BU DOSYA SUNU GORMEZ (KAPI KURMA KURALLARI m.3):
--   - Tavanin altinda sabirla ceken (gunde 3.999 satir) kisi - kutukte gorunur, durdurulmaz.
--   - Ekran goruntusu, kamera, elle not alma.
--   - Tavan degerleri OLCULMEDI; ilk 2 haftada kutukten gercek dagilima gore ayarlanir.
-- ============================================================================

-- 0) KUTUK ----------------------------------------------------------------------
create table if not exists public.kasa_cekim (
  id       bigint generated always as identity primary key,
  user_id  uuid not null,
  sayfa    text not null,
  bas      integer not null default 0,
  adet     integer not null default 0 check (adet >= 0),
  ip       text,
  zaman    timestamptz not null default now()
);
alter table public.kasa_cekim enable row level security;
revoke all on public.kasa_cekim from anon, authenticated;
create index if not exists kasa_cekim_uye_zaman on public.kasa_cekim (user_id, zaman desc);
create index if not exists kasa_cekim_zaman     on public.kasa_cekim (zaman desc);
create index if not exists paket_soru_sayfa_sira on public.paket_soru (sayfa, sira);

-- 1) PAKET KURALI (2026-09-16-paket-soru.sql politikasiyla BIREBIR) -----------------
create or replace function public.paket_erisim_var(p_sinav text, p_ders text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from public.paket_uyeler pu
    where pu.user_id = auth.uid()
      and (pu.bitis is null or pu.bitis >= current_date)
      and (
        coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu')
        or (p_sinav = 'sgs'  and (lower(trim(pu.paket)) = 'sgs' or lower(trim(pu.paket)) like 'sgs-%'
                                   or lower(trim(pu.paket)) = 'sinav-249'))
        or (p_sinav = 'smmm' and (lower(trim(pu.paket)) in ('yeterlilik','smmm','yeterlilik-kgk')
                                   or lower(trim(pu.paket)) like 'yeterlilik-%'))
        or (p_sinav = 'kgk'  and (lower(trim(pu.paket)) in ('kgk','yeterlilik-kgk')
                                   or lower(trim(pu.paket)) like 'kgk-%'))
      )
      and (pu.dersler is null or p_ders = any(pu.dersler))
  );
$fn$;
revoke all on function public.paket_erisim_var(text, text) from public;
grant execute on function public.paket_erisim_var(text, text) to authenticated;

-- 2) SAYAC + TAVAN -----------------------------------------------------------------
-- null = izin (kutuge yazildi); metin = engel nedeni ('10dk' | 'gun' | 'hafta' | 'oturum yok')
create or replace function public.kasa_cekim_izin(p_sayfa text, p_bas integer, p_adet integer)
returns text
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid   uuid := auth.uid();
  c10   integer; c24 integer; c7 integer;
  neden text;
  ip    text;
begin
  if uid is null then return 'oturum yok'; end if;
  select coalesce(sum(adet),0) into c10 from public.kasa_cekim where user_id = uid and zaman > now() - interval '10 minutes';
  select coalesce(sum(adet),0) into c24 from public.kasa_cekim where user_id = uid and zaman > now() - interval '24 hours';
  select coalesce(sum(adet),0) into c7  from public.kasa_cekim where user_id = uid and zaman > now() - interval '7 days';
  neden := case
    when c10 + p_adet > 1500  then '10dk'
    when c24 + p_adet > 4000  then 'gun'
    when c7  + p_adet > 12000 then 'hafta'
  end;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'), ''), ',', 1);
  if neden is not null then
    insert into public.kasa_cekim (user_id, sayfa, bas, adet, ip) values (uid, 'TAVAN:' || neden || ':' || p_sayfa, p_bas, 0, nullif(trim(ip),''));
    return neden;
  end if;
  insert into public.kasa_cekim (user_id, sayfa, bas, adet, ip) values (uid, p_sayfa, p_bas, p_adet, nullif(trim(ip),''));
  return null;
end $fn$;
revoke all on function public.kasa_cekim_izin(text, integer, integer) from public;
-- yalniz asagidaki fonksiyonlar cagirir (definer); anon/authenticated'a grant YOK.

-- 3) SAYFA OKUMA: bir dersin satirlari, sirayla, parca <= 100 --------------------------
-- toplam: o sayfanin paketli uyeye gorunen satir sayisi (istemci kalan parcalari buna gore ister).
create or replace function public.kasa_soru_getir(p_sayfa text, p_bas integer default 0, p_adet integer default 100)
returns table (sira integer, veri jsonb, toplam bigint)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  adet    integer := least(greatest(coalesce(p_adet, 100), 1), 100);
  bas     integer := greatest(coalesce(p_bas, 0), 0);
  v_sinav text; v_ders text;
  tpl     bigint; n integer; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;   -- 0 satir = "paketinde yok"
  select count(*) into tpl from public.paket_soru s where s.sayfa = p_sayfa;
  n := greatest(least(tpl - bas, adet), 0);
  if n = 0 then return; end if;
  neden := public.kasa_cekim_izin(p_sayfa, bas, n);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.sira, s.veri, tpl from public.paket_soru s
    where s.sayfa = p_sayfa order by s.sira asc offset bas limit adet;
end $fn$;
revoke all on function public.kasa_soru_getir(text, integer, integer) from public;
grant execute on function public.kasa_soru_getir(text, integer, integer) to authenticated;

-- 4) ID OKUMA: deneme seti / karma sinav (sinav-gibi.html, uygulama-karma.js), <= 100 id -----
create or replace function public.kasa_soru_idler(p_ids text[])
returns table (id text, veri jsonb)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ids text[] := (coalesce(p_ids, '{}'::text[]))[1:100];
  n integer; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select count(*) into n from public.paket_soru s where s.id = any(ids) and public.paket_erisim_var(s.sinav, s.ders);
  if n = 0 then return; end if;
  neden := public.kasa_cekim_izin('idler', 0, n);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.id, s.veri from public.paket_soru s
    where s.id = any(ids) and public.paket_erisim_var(s.sinav, s.ders);
end $fn$;
revoke all on function public.kasa_soru_idler(text[]) from public;
grant execute on function public.kasa_soru_idler(text[]) to authenticated;

-- 5) DIZIN: icerik YOK (id, ders, sayfa, donem) - karma sinav secimi icin; sayilmaz --------
create or replace function public.kasa_dizin(p_sinav text)
returns table (id text, ders text, sayfa text, donem text)
language sql
stable
security definer
set search_path = public
as $fn$
  select s.id, s.ders, s.sayfa, s.veri->>'donem'
  from public.paket_soru s
  where s.sinav = p_sinav and auth.uid() is not null and public.paket_erisim_var(s.sinav, s.ders)
  order by s.id;
$fn$;
revoke all on function public.kasa_dizin(text) from public;
grant execute on function public.kasa_dizin(text) to authenticated;

-- 6) DOGRUDAN OKUMA KAPANIR ------------------------------------------------------------
revoke select on public.paket_soru from authenticated;

-- 7) ALARM SAYIMI: uye_sayim() + kasa alanlari (2026-09-23-hesap-paylasim-korumasi.sql tanimi uzerine)
create or replace function public.uye_sayim()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $fn$
  select jsonb_build_object(
    'toplam',          (select count(*) from auth.users),
    'son_1_saat',      (select count(*) from auth.users where created_at > now() - interval '1 hour'),
    'son_24_saat',     (select count(*) from auth.users where created_at > now() - interval '24 hours'),
    'en_yogun_dakika', coalesce((select max(d.n) from (
                          select count(*) as n
                          from auth.users
                          where created_at > now() - interval '1 hour'
                          group by date_trunc('minute', created_at)
                        ) d), 0),
    'paylasim_supheli', (select count(*) from (
                          select user_id from public.uye_cihaz_olay
                          where olay = 'devraldi' and zaman > now() - interval '24 hours'
                          group by user_id having count(*) >= 8) p),
    'cihaz_siniri_24s', (select count(distinct user_id) from public.uye_cihaz_olay
                          where olay = 'sinir' and zaman > now() - interval '24 hours'),
    'kasa_tavan_24s',  (select count(distinct user_id) from public.kasa_cekim
                          where sayfa like 'TAVAN:%' and zaman > now() - interval '24 hours'),
    'kasa_asiri_24s',  (select count(*) from (
                          select user_id from public.kasa_cekim
                          where zaman > now() - interval '24 hours'
                          group by user_id having sum(adet) >= 2500) k),
    'kasa_cekim_24s',  (select coalesce(sum(adet),0) from public.kasa_cekim where zaman > now() - interval '24 hours'),
    'olcum',           now()
  );
$fn$;
revoke all on function public.uye_sayim() from public;
revoke all on function public.uye_sayim() from anon, authenticated;
grant execute on function public.uye_sayim() to service_role;

-- OLCU (goc gunlugunde yalniz sayi): dogrudan hak kalmadi mi?
select has_table_privilege('authenticated', 'public.paket_soru', 'select') as authenticated_dogrudan_okur_mu;   -- false beklenir
select (public.uye_sayim() ? 'kasa_tavan_24s') as uye_sayim_kasa_alani_var;                                   -- true beklenir

-- ============================================================================
-- DOGRULAMA (canli, basimdan sonra, UYGULANDI.md'ye yazilir):
--   anon:            GET /rest/v1/paket_soru?select=id&limit=1          -> 401
--   paketli uye:     GET /rest/v1/paket_soru?select=id&limit=1          -> 401 / 42501 (dogrudan okuma kapali)
--   paketli uye:     POST /rest/v1/rpc/kasa_soru_getir {p_sayfa, 0, 40} -> 40 satir, her satirda toplam
--   paketli uye:     16. parca ustune 10 dk icinde 1.500 asinca          -> {"message":"KASA_TAVAN:10dk"}
--   paketsiz uye:    rpc/kasa_soru_getir                                 -> 0 satir
--   robot:           rpc/uye_sayim                                       -> kasa_tavan_24s, kasa_asiri_24s, kasa_cekim_24s
-- ============================================================================
