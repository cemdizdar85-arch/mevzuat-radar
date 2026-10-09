-- ============================================================================
-- KASA SAYACI FARKLI SORUYU SAYAR - ayni soru 24 saatte bir kez sayilir (10.10.2026)
--
-- NEDEN (Cem 10.10 "1 yap"): ilk gun alarmi (24 saatte 2.500+) odeme yapmis bir uyede caldi:
-- 2 saatte 3.335 satir. Kutuk okundu: uye 3 dersi (Muhasebe Denetimi 401, Vergi 406, Sermaye
-- Piyasasi 256 satir) 11 kez ACMIS - ders sayfasi her acilista dersin tamamini yukluyor, sayac
-- her yuklemeyi bastan sayiyordu. Farkli soru ~1.100. Ayni yolla 4.000 gun tavani durust ogrenciyi
-- birkac sayfa acilisinda kilitlerdi; Cem once uyeyi engelletti, odeme gorulunce geri alindi.
--
-- NE DEGISIR:
--   1) kasa_cekim'e iki sutun: tekil (bu cekimde, son 24 saatte bu uyeye ILK KEZ giden satir
--      sayisi) ve ids (idler cekiminde verilen soru kimlikleri). adet aynen kalir (ham kayit).
--   2) kasa_cekim_izin2(sayfa, bas, adet, ids): tekil'i hesaplar; TAVAN tekil toplamiyla sinanir.
--      Rakamlar AYNI (10 dk 1.500 · 24 sa 4.000 · 7 gun 12.000) - yalniz ne sayildigi degisti.
--      Tamamen tekrar olan cekim (tekil 0) tavanda hic durdurulmaz: yeni bir sey vermiyor.
--   3) kasa_soru_getir / kasa_soru_idler ayni imza, yeni sayaci cagirir. Eski kasa_cekim_izin dusurulur.
--   4) Eski satirlar geriye donuk tekil'le doldurulur (ayni kural); eski idler satirinda kimlik
--      yok -> tekil = adet (fazla sayar, eksik saymaz).
--   5) uye_sayim(): kasa_asiri_24s artik farkli soru (tekil) toplamiyla; +kasa_tekil_24s.
--      kasa_cekim_24s ham satir olarak kalir (kiyas icin).
--
-- BU DOSYA SUNU GORMEZ (KAPI KURMA KURALLARI m.3):
--   - Sayfa yoluyla ve idler (deneme seti) yoluyla ayni sorunun gelmesi IKI KEZ sayilir (iki yol ayri kutuk).
--   - Soru sirasi (sira) yayinda kayarsa ayni aralik baska sorulari gosterir; 24 saatlik pencerede
--     bu "tekrar" sayilir (yeni yayin gunde en cok bir kez).
--   - 24 saat sonra ayni soru yeniden sayilir; 7 gunluk tavan bu yuzden "gunluk farkli soru toplami"dir.
--   - Tavan rakamlari hala OLCULMEDI (2 hafta kutukten).
-- ============================================================================

alter table public.kasa_cekim add column if not exists tekil integer check (tekil is null or tekil >= 0);
alter table public.kasa_cekim add column if not exists ids   text[];
create index if not exists kasa_cekim_uye_sayfa_zaman on public.kasa_cekim (user_id, sayfa, zaman desc);

-- 1) SAYAC + TAVAN (farkli soru) ----------------------------------------------------
-- null = izin (kutuge yazildi); metin = engel nedeni ('10dk' | 'gun' | 'hafta' | 'oturum yok')
create or replace function public.kasa_cekim_izin2(p_sayfa text, p_bas integer, p_adet integer, p_ids text[] default null)
returns text
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid   uuid := auth.uid();
  c10   integer; c24 integer; c7 integer;
  yeni  integer;
  neden text;
  ip    text;
begin
  if uid is null then return 'oturum yok'; end if;
  if p_ids is null then
    -- aralik [bas, bas+adet): son 24 saatte ayni sayfadan zaten verilmis konumlar sayilmaz
    select count(*) into yeni
      from generate_series(p_bas, p_bas + p_adet - 1) g(i)
     where not exists (
       select 1 from public.kasa_cekim k
        where k.user_id = uid and k.sayfa = p_sayfa and k.adet > 0
          and k.zaman > now() - interval '24 hours'
          and g.i >= k.bas and g.i < k.bas + k.adet);
  else
    select count(distinct x.id) into yeni
      from unnest(p_ids) x(id)
     where not exists (
       select 1 from public.kasa_cekim k
        where k.user_id = uid and k.sayfa = p_sayfa and k.adet > 0
          and k.zaman > now() - interval '24 hours'
          and x.id = any(k.ids));
  end if;
  select coalesce(sum(coalesce(tekil, adet)),0) into c10 from public.kasa_cekim where user_id = uid and zaman > now() - interval '10 minutes';
  select coalesce(sum(coalesce(tekil, adet)),0) into c24 from public.kasa_cekim where user_id = uid and zaman > now() - interval '24 hours';
  select coalesce(sum(coalesce(tekil, adet)),0) into c7  from public.kasa_cekim where user_id = uid and zaman > now() - interval '7 days';
  neden := case
    when yeni = 0              then null
    when c10 + yeni > 1500     then '10dk'
    when c24 + yeni > 4000     then 'gun'
    when c7  + yeni > 12000    then 'hafta'
  end;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'), ''), ',', 1);
  if neden is not null then
    insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ip) values (uid, 'TAVAN:' || neden || ':' || p_sayfa, p_bas, 0, 0, nullif(trim(ip),''));
    return neden;
  end if;
  insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ids, ip) values (uid, p_sayfa, p_bas, p_adet, yeni, p_ids, nullif(trim(ip),''));
  return null;
end $fn$;
revoke all on function public.kasa_cekim_izin2(text, integer, integer, text[]) from public;
-- yalniz asagidaki fonksiyonlar cagirir (definer); anon/authenticated'a grant YOK.

-- 2) SAYFA OKUMA (ayni imza, yeni sayac) ------------------------------------------------
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
  neden := public.kasa_cekim_izin2(p_sayfa, bas, n, null);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.sira, s.veri, tpl from public.paket_soru s
    where s.sayfa = p_sayfa order by s.sira asc offset bas limit adet;
end $fn$;
revoke all on function public.kasa_soru_getir(text, integer, integer) from public;
grant execute on function public.kasa_soru_getir(text, integer, integer) to authenticated;

-- 3) ID OKUMA (ayni imza, yeni sayac; verilen kimlikler kutuge yazilir) ---------------------
create or replace function public.kasa_soru_idler(p_ids text[])
returns table (id text, veri jsonb)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ids  text[] := (coalesce(p_ids, '{}'::text[]))[1:100];
  izin text[]; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select array_agg(s.id) into izin from public.paket_soru s where s.id = any(ids) and public.paket_erisim_var(s.sinav, s.ders);
  if izin is null then return; end if;
  neden := public.kasa_cekim_izin2('idler', 0, cardinality(izin), izin);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.id, s.veri from public.paket_soru s
    where s.id = any(izin);
end $fn$;
revoke all on function public.kasa_soru_idler(text[]) from public;
grant execute on function public.kasa_soru_idler(text[]) to authenticated;

drop function if exists public.kasa_cekim_izin(text, integer, integer);

-- 4) GERIYE DONUK DOLDURMA (ayni kural; once gelen satir sayilir, sonra gelen tekrar) -------
update public.kasa_cekim r
   set tekil = case
     when r.adet = 0 then 0
     when r.sayfa = 'idler' then r.adet
     else (select count(*) from generate_series(r.bas, r.bas + r.adet - 1) g(i)
            where not exists (
              select 1 from public.kasa_cekim k
               where k.user_id = r.user_id and k.sayfa = r.sayfa and k.adet > 0
                 and k.id < r.id and k.zaman > r.zaman - interval '24 hours'
                 and g.i >= k.bas and g.i < k.bas + k.adet))
   end
 where r.tekil is null;

-- 5) ALARM SAYIMI: uye_sayim() (2026-10-09-kasa-olcer.sql tanimi uzerine; kasa alanlari tekil) ---
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
                          group by user_id having sum(coalesce(tekil, adet)) >= 2500) k),
    'kasa_cekim_24s',  (select coalesce(sum(adet),0) from public.kasa_cekim where zaman > now() - interval '24 hours'),
    'kasa_tekil_24s',  (select coalesce(sum(coalesce(tekil, adet)),0) from public.kasa_cekim where zaman > now() - interval '24 hours'),
    'olcum',           now()
  );
$fn$;
revoke all on function public.uye_sayim() from public;
revoke all on function public.uye_sayim() from anon, authenticated;
grant execute on function public.uye_sayim() to service_role;

-- 6) GOC ICI OZ-SINAV: sahte uye ile, sonunda GERI ALINIR; bir vaka tutmazsa goc tumden durur ---
do $sinav$
declare
  u uuid := '00000000-0000-4000-8000-00000000a5a5';
  s text := 'SINAV:kasa-tekil';
  t1 integer; t2 integer; t3 integer; t4 integer; t5 integer; t6 integer; t7 integer;
  n1 text; n2 text; n3 text;
  function_sonuc text;
begin
  begin
    perform set_config('request.jwt.claims', json_build_object('sub', u::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', u::text, true);
    if auth.uid() is distinct from u then raise exception 'SINAV_KURULUM: auth.uid() sahte uyeyi gormedi'; end if;
    perform public.kasa_cekim_izin2(s, 0, 40, null);    select tekil into t1 from public.kasa_cekim where user_id = u order by id desc limit 1;  -- ilk acilis 40
    perform public.kasa_cekim_izin2(s, 0, 40, null);    select tekil into t2 from public.kasa_cekim where user_id = u order by id desc limit 1;  -- ayni aralik 0
    perform public.kasa_cekim_izin2(s, 0, 100, null);   select tekil into t3 from public.kasa_cekim where user_id = u order by id desc limit 1;  -- farkli parca sinirindan 60
    perform public.kasa_cekim_izin2(s || '2', 0, 40, null); select tekil into t4 from public.kasa_cekim where user_id = u order by id desc limit 1; -- baska ders 40
    perform public.kasa_cekim_izin2('idler', 0, 2, array['a','b']);     select tekil into t5 from public.kasa_cekim where user_id = u order by id desc limit 1; -- 2
    perform public.kasa_cekim_izin2('idler', 0, 3, array['b','c','c']); select tekil into t6 from public.kasa_cekim where user_id = u order by id desc limit 1; -- yalniz c: 1
    -- tavan: yukaridaki 143 + 2 saat once 3.800 = 24 saatte 3.943 farkli soru (10 dk disinda)
    insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, zaman) values (u, s || 'eski', 0, 3800, 3800, now() - interval '2 hours');
    n1 := public.kasa_cekim_izin2(s || '3', 0, 100, null);   -- 100 yeni: 3.943+100 > 4.000 -> gun
    n2 := public.kasa_cekim_izin2(s, 0, 100, null);          -- tamamen tekrar (tekil 0): durdurulmaz
    n3 := public.kasa_cekim_izin2(s || '3', 0, 10, null);    -- 10 yeni: 3.943+10 <= 4.000 -> izin
    select tekil into t7 from public.kasa_cekim where user_id = u order by id desc limit 1;
    raise exception 'SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'SINAV_GERI_AL' then raise; end if;
  end;
  function_sonuc := format('t1=%s t2=%s t3=%s t4=%s t5=%s t6=%s n1=%s n2=%s n3=%s t7=%s', t1, t2, t3, t4, t5, t6, n1, n2, n3, t7);
  if not (t1 = 40 and t2 = 0 and t3 = 60 and t4 = 40 and t5 = 2 and t6 = 1
          and n1 = 'gun' and n2 is null and n3 is null and t7 = 10) then
    raise exception 'KASA_TEKIL_SINAV KIRMIZI: %', function_sonuc;
  end if;
  raise notice 'KASA_TEKIL_SINAV YESIL: %', function_sonuc;
end $sinav$;

-- OLCU (goc gunlugunde yalniz sayi)
select count(*) filter (where tekil is null) as tekilsiz_satir from public.kasa_cekim;   -- 0 beklenir
select (public.uye_sayim() ? 'kasa_tekil_24s') as uye_sayim_tekil_alani_var;             -- true beklenir
