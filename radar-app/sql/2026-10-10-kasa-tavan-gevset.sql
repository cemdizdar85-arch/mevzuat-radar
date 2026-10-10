-- ============================================================================
-- KASA TAVANI GEVSER + TAVAN KUTUGU KALICI (10.10.2026, Cem "1.2.3 ucunu de yapalim hemen")
--
-- NEDEN (olculdu 10.10, kasa_cekim kutugu): tam paketli bir uye 19:21-19:22 arasi uc ders sayfasi
-- acti (Yeterlilik Hukuk 439 + Meslek Hukuku 353 + Finansal Muhasebe 1.137) -> 10 dakikada 1.632
-- farkli soru "cekti" ve 10 dk tavanina (1.500) takildi. Ders sayfasi acilista dersin TAMAMINI
-- indiriyor; sayac cozulen degil INEN soruyu sayiyor. Tam paket SGS 4.946 + Yeterlilik 3.889 soru:
-- butun dersleri BIR KEZ acmak gun tavanini (4.000) da asar -> tavan durust ogrenciyi durduruyordu.
--
-- Ayrica: tavan asiminda kasa_soru_getir 'KASA_TAVAN' hatasi FIRLATIR; ayni islemde yazilan 'TAVAN:'
-- kutuk satiri bu hatayla GERI ALINIYORDU. 10.10 olcumu: kutukte TAVAN satiri 0, ama uye ekranda
-- tavan uyarisi gordu -> uye_sayim().kasa_tavan_24s hep 0 donuyordu (KOR).
--
-- NE DEGISIR:
--   1) kasa_cekim_izin2: rakamlar 10 dk 1.500 -> 4.000 · 24 sa 4.000 -> 10.000 · 7 gun 12.000 -> 25.000.
--      Ders acmak (tum Yeterlilik dersleri 3.889) tavani tetiklemez; toplu indirme yine durur.
--      Gecici: ders sayfasi soru soru (ilerledikce) yuklenince sayac "gorulen soru"ya iner ve tavan
--      yeniden daraltilir (site kolu isi).
--   2) kasa_tavan_bildir(sayfa, pencere): istemci tavan hatasini alinca cagirir; 'TAVAN:<pencere>:<sayfa>'
--      satiri AYRI islemde yazilir, kalici olur. Ayni uye icin dakikada en cok 1 satir (sel yok).
--      kasa_cekim_izin2 icindeki TAVAN insert'u kaldirilmadi (zararsiz, geri aliniyor).
--
-- BU DOSYA SUNU GORMEZ (KAPI KURMA KURALLARI m.3):
--   - Bildirimi istemci yapar: eski onbellekli sayfa / bilerek atlayan kisi tavana takilsa da kutuge dusmez.
--   - Yeni tavan rakamlari da OLCULMEDI (ilk 2 hafta kutukten ayarlanacak).
-- ============================================================================

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
    when c10 + yeni > 4000     then '10dk'
    when c24 + yeni > 10000    then 'gun'
    when c7  + yeni > 25000    then 'hafta'
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

-- TAVAN BILDIRIMI (ayri islem -> kalici) ----------------------------------------------
create or replace function public.kasa_tavan_bildir(p_sayfa text, p_pencere text)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid();
  ip  text;
begin
  if uid is null then return; end if;
  if p_pencere is null or p_pencere not in ('10dk','gun','hafta') then return; end if;
  if exists (select 1 from public.kasa_cekim where user_id = uid and sayfa like 'TAVAN:%' and zaman > now() - interval '1 minute') then return; end if;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'), ''), ',', 1);
  insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ip)
  values (uid, 'TAVAN:' || p_pencere || ':' || left(coalesce(p_sayfa,'?'), 200), 0, 0, 0, nullif(trim(ip),''));
end $fn$;
revoke all on function public.kasa_tavan_bildir(text, text) from public;
grant execute on function public.kasa_tavan_bildir(text, text) to authenticated;

-- OLCU (goc gunlugunde yalniz sayi)
select position('> 4000' in pg_get_functiondef('public.kasa_cekim_izin2(text,integer,integer,text[])'::regprocedure)) > 0 as yeni_10dk_tavan;   -- true beklenir
select has_function_privilege('authenticated', 'public.kasa_tavan_bildir(text,text)', 'execute') as bildir_acik;                                 -- true beklenir
