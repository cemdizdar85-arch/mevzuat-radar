-- ============================================================================
-- KASA SET + ARKA PLAN CEVAP KAYDI (11.10.2026, Cem "set + arka plan kaydi bunu yapalim")
--
-- NEDEN (olculdu 10.10, kasa_cekim + ogrenci_ilerleme): ders sayfasi acilista dersin TAMAMINI indiriyordu;
-- sayac "inen" soruyu sayiyor, "gorulen"i ve "cozulen"i ayiramiyordu. Ornek: bir hesap 10.10'da 9 ders,
-- 33 sayfa acilisi, 3.567 farkli soru "cekti" ama o gun 7 soru cozdu. Bu olcuyle aski karari verilemez
-- (Cem 11.10: "askiya almadan once dogru olcuyor muyuz emin olmamiz lazim").
--
-- NE EKLER (eski fonksiyonlar AYNEN kalir: magazadaki uygulama ve eski sayfalar onlari kullanir):
--   1) kasa_ders_fihrist(sayfa): dersin ICERIKSIZ fihristi (id, sira, konu, donem, zorluk) + toplam.
--      Soru metni/sik/cevap YOK -> sayilmaz. Seviye sirasi, hazirlik skoru ve yanlis kutusu bunu kullanir.
--   2) kasa_soru_parca(sayfa, ids<=40): yalniz o sayfanin sorulari, kimlikle; kasa_cekim'e SAYFA adiyla
--      ve kimliklerle yazilir (tekil sayim kimlikten). Sayfa 20'ser ister -> sayac ~ ekranda acilan soru.
--   3) kasa_cevap tablosu + kasa_cevap_yaz(sayfa, id, secim): istemci her cevapta ARKA PLANDA cagirir
--      (ogrenci beklemez). Dogru/yanlis SUNUCUDA paket_soru.veri->>'dogru' ile hesaplanir (istemciye
--      guvenilmez). Ayni uye + ayni soru 10 sn icinde tekrar -> yazilmaz (sel yok).
--   4) kasa_uye_olcum(saat): yonetim/alarm icin uye basina ACTI (tekil cekim) · COZDU (farkli soru) ·
--      sayfa sayisi. Yalniz service_role.
--
-- BU DOSYA SUNU GORMEZ (KAPI KURMA KURALLARI m.3):
--   - Cevap kaydi istemciden gelir: eski onbellekli sayfa ya da bilerek atlayan kisi cevap yazmaz
--     -> "cozdu" EKSIK sayilabilir, FAZLA sayilmaz (sunucu soruyu bilmeden yazmaz).
--   - Ekranda gercekten durulan sure, kaydirmadan "bakilan" soru: olculmez.
--   - Eski yol (kasa_soru_getir, tum ders) acik kaldikca bilen biri yine toplu ceker; sayac onu da sayar.
--     Uygulama 1.8.2 yayina girince eski yolun daraltilmasi AYRI is.
--   - Tavan rakamlari degismedi (10.10 gevsetilmis hali); yeni olcuyle 2 hafta kutuk -> ayar.
--   - Ayni soru 24 saat icinde hem eski yoldan (konum) hem yeni yoldan (kimlik) gelirse IKI KEZ sayilir.
-- ============================================================================

-- 1) FIHRIST (icerik yok, sayilmaz) --------------------------------------------------
create or replace function public.kasa_ders_fihrist(p_sayfa text)
returns table (id text, sira integer, ders text, konu text, donem text, zorluk text, toplam bigint)
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_sinav text; v_ders text; tpl bigint;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;   -- 0 satir = "paketinde yok"
  select count(*) into tpl from public.paket_soru s where s.sayfa = p_sayfa;
  return query
    select s.id, s.sira, s.ders, coalesce(s.konu, s.veri->>'konu'), s.veri->>'donem', s.veri->>'zorluk', tpl
    from public.paket_soru s where s.sayfa = p_sayfa order by s.sira asc;
end $fn$;
revoke all on function public.kasa_ders_fihrist(text) from public;
grant execute on function public.kasa_ders_fihrist(text) to authenticated;

-- 2) PARCA (kimlikle, en cok 40, sayilir) --------------------------------------------
create or replace function public.kasa_soru_parca(p_sayfa text, p_ids text[])
returns table (id text, sira integer, veri jsonb)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ids   text[] := (coalesce(p_ids, '{}'::text[]))[1:40];
  izin  text[]; v_sinav text; v_ders text; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;
  select array_agg(s.id) into izin from public.paket_soru s where s.sayfa = p_sayfa and s.id = any(ids);
  if izin is null then return; end if;
  -- bas -100000: kimlikli satirin konum araligi gercek konumlarla (eski yol kasa_soru_getir) cakismasin;
  -- tekil sayim burada kimlikten yapilir (kasa_cekim_izin2 p_ids dali).
  neden := public.kasa_cekim_izin2(p_sayfa, -100000, cardinality(izin), izin);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.id, s.sira, s.veri from public.paket_soru s where s.id = any(izin);
end $fn$;
revoke all on function public.kasa_soru_parca(text, text[]) from public;
grant execute on function public.kasa_soru_parca(text, text[]) to authenticated;

-- 3) CEVAP KAYDI (arka plan) ----------------------------------------------------------
create table if not exists public.kasa_cevap (
  id       bigint generated always as identity primary key,
  user_id  uuid not null,
  sayfa    text not null,
  soru_id  text not null,
  secim    text not null check (secim ~ '^[A-E?]$'),     -- '?' = Bilmiyorum
  dogru    boolean,
  zaman    timestamptz not null default now()
);
alter table public.kasa_cevap enable row level security;                 -- politika YOK: yalniz fonksiyon yazar
revoke all on table public.kasa_cevap from anon, authenticated;
create index if not exists kasa_cevap_uye_zaman on public.kasa_cevap (user_id, zaman desc);

create or replace function public.kasa_cevap_yaz(p_sayfa text, p_id text, p_secim text)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid(); v_dogru text; sec text := upper(left(coalesce(p_secim,''),1));
begin
  if uid is null or sec !~ '^[A-E?]$' then return; end if;
  select s.veri->>'dogru' into v_dogru from public.paket_soru s where s.id = p_id and s.sayfa = p_sayfa;
  if v_dogru is null then return; end if;                                  -- bilinmeyen soru yazilmaz
  if exists (select 1 from public.kasa_cevap c where c.user_id = uid and c.soru_id = p_id
             and c.zaman > now() - interval '10 seconds') then return; end if;
  insert into public.kasa_cevap (user_id, sayfa, soru_id, secim, dogru)
  values (uid, left(p_sayfa, 200), p_id, sec, case when sec = '?' then false else sec = upper(v_dogru) end);
end $fn$;
revoke all on function public.kasa_cevap_yaz(text, text, text) from public;
grant execute on function public.kasa_cevap_yaz(text, text, text) to authenticated;

-- 4) UYE OLCUMU (yalniz service_role) -------------------------------------------------
create or replace function public.kasa_uye_olcum(p_saat integer default 24)
returns table (user_id uuid, acti bigint, cozdu bigint, sayfa_sayisi bigint, tavan bigint)
language sql
stable
security definer
set search_path = public
as $fn$
  with k as (
    select c.user_id,
           sum(coalesce(c.tekil, c.adet)) filter (where c.sayfa not like 'TAVAN:%') as acti,
           count(distinct c.sayfa) filter (where c.sayfa not like 'TAVAN:%' and c.adet > 0) as sayfa_sayisi,
           count(*) filter (where c.sayfa like 'TAVAN:%') as tavan
    from public.kasa_cekim c
    where c.zaman > now() - make_interval(hours => greatest(1, least(coalesce(p_saat,24), 24*14)))
    group by c.user_id),
  v as (
    select a.user_id, count(distinct a.soru_id) as cozdu
    from public.kasa_cevap a
    where a.zaman > now() - make_interval(hours => greatest(1, least(coalesce(p_saat,24), 24*14)))
    group by a.user_id)
  select coalesce(k.user_id, v.user_id), coalesce(k.acti,0), coalesce(v.cozdu,0), coalesce(k.sayfa_sayisi,0), coalesce(k.tavan,0)
  from k full join v on v.user_id = k.user_id
  order by 2 desc;
$fn$;
revoke all on function public.kasa_uye_olcum(integer) from public, anon, authenticated;
grant execute on function public.kasa_uye_olcum(integer) to service_role;

-- OLCU (goc gunlugunde yalniz sayi/mantik)
select has_function_privilege('authenticated', 'public.kasa_ders_fihrist(text)', 'execute')               as fihrist_acik;     -- true
select has_function_privilege('authenticated', 'public.kasa_soru_parca(text,text[])', 'execute')          as parca_acik;       -- true
select has_function_privilege('authenticated', 'public.kasa_cevap_yaz(text,text,text)', 'execute')        as cevap_acik;       -- true
select has_table_privilege('authenticated', 'public.kasa_cevap', 'select')                                 as cevap_okunur;     -- false
select has_function_privilege('authenticated', 'public.kasa_uye_olcum(integer)', 'execute')               as olcum_uyeye_acik; -- false
