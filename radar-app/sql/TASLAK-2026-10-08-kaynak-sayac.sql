-- ============================================================================
--  KAYNAK SAYACI — "hangi link kaç kişi getirdi" (08.10.2026, pazarlama oturumunun isteği, site kolu)
--
--  Amaç: gruplara/Instagram'a atılan tetikte.com/...?k=<etiket> linklerinden kaç ziyaret, kaç seviye testi
--  başlangıcı, kaç ücretsiz üyelik geldiğini görmek. Ziyaretçi tarafı menu.js (KAYNAK-ETIKETI bloğu).
--
--  KVKK: tabloda YALNIZ (gün, etiket, olay türü, adet). IP yok, e-posta yok, kullanıcı kimliği yok.
--  Üyelik çift sayılmasın diye kaynak_uye_sayildi tablosu YALNIZ user_id tutar (etiket tutmaz → hangi
--  üyenin hangi linkten geldiği bu tablolardan çıkarılamaz); hesap silinince satır kendiliğinden düşer
--  (on delete cascade).
--
--  ⚠ 08.10 açılış güvenlik denetimi 2.6: anon yazma yolu açılıyorsa CHECK + hız sınırı şart, spend cap kapalı.
--    Bu dosyadaki anon yolu (kaynak_say) şu sınırlarla açılır:
--      · tabloya doğrudan anon/authenticated yazma YOK (RLS açık + politika yok + revoke); yazma yalnız RPC'den
--      · etiket biçimi hem RPC'de hem tablo CHECK'inde: ^[a-z0-9][a-z0-9_-]{0,31}$ (en çok 32 karakter)
--      · olay: anon yalnız 'ziyaret' | 'test'; 'uye' yalnız giriş yapmış ve hesabı ≤ 2 gün önce açılmış üyeden, hesap başına 1 kez
--      · satır tavanı: bir (gün, etiket, olay) en çok 3.000'e kadar artar, sonra RPC false döner
--      · gün başına en çok 60 farklı etiket: 61. yeni etiket reddedilir (tablo büyümesi günde ≤ 180 satır)
--    🚫 BU YAPI ŞUNU GÖRMEZ / ENGELLEMEZ: betikle aynı etikete sahte ziyaret/test basılması (tavana kadar sayı
--      şişer; tablo büyümez, para yakmaz) · 60 etiketlik günlük kotanın sahte etiketlerle doldurulması (o gün
--      yeni gerçek etiket sayılmaz) · sahte hesap açıp 'uye' şişirmek (Supabase kayıt sınırı + captcha'ya bağlı;
--      captcha 05.10'dan beri KAPALI). IP'ye göre hız sınırı BİLEREK yok: IP tutmamak için.
--
--  Okuma: yonetim_kaynak() yalnız yoneticiler tablosundaki kullanıcıya (yonetim_ozet ile aynı kapı).
--  Uygulanma: sql-uygula.yml (push ile otomatik). Dosyanın sonundaki öz-sınav göç işleminin İÇİNDE koşar,
--  kendi satırlarını geri alır; bir vaka düşerse göç tümden uygulanmaz (KIRMIZI).
--  GERİ ALMA: drop function public.kaynak_say(text,text), public.kaynak_uye(text), public.yonetim_kaynak(integer);
--             drop table public.kaynak_uye_sayildi, public.kaynak_sayac;
-- ============================================================================

create table if not exists public.kaynak_sayac (
  gun     date    not null,
  etiket  text    not null constraint kaynak_sayac_etiket_bicim check (etiket ~ '^[a-z0-9][a-z0-9_-]{0,31}$'),
  olay    text    not null constraint kaynak_sayac_olay check (olay in ('ziyaret','test','uye')),
  adet    integer not null default 0 constraint kaynak_sayac_adet check (adet between 0 and 100000),
  primary key (gun, etiket, olay)
);
alter table public.kaynak_sayac enable row level security;
revoke all on public.kaynak_sayac from anon, authenticated;

create table if not exists public.kaynak_uye_sayildi (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.kaynak_uye_sayildi enable row level security;
revoke all on public.kaynak_uye_sayildi from anon, authenticated;

-- ---------------------------------------------------------------------------
--  Ortak yazıcı (dışarı açık DEĞİL): sınırları uygular, sayıldıysa true.
-- ---------------------------------------------------------------------------
create or replace function public._kaynak_artir(p_gun date, p_etiket text, p_olay text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
declare n integer;
begin
  if p_gun is null or p_etiket is null or p_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}$'
     or coalesce(p_olay,'') not in ('ziyaret','test','uye') then
    return false;
  end if;
  -- günlük farklı etiket kotası (yalnız o gün İLK kez görülen etiket için bakılır)
  if not exists (select 1 from public.kaynak_sayac s where s.gun = p_gun and s.etiket = p_etiket)
     and (select count(distinct s.etiket) from public.kaynak_sayac s where s.gun = p_gun) >= 60 then
    return false;
  end if;
  insert into public.kaynak_sayac as k (gun, etiket, olay, adet) values (p_gun, p_etiket, p_olay, 1)
  on conflict (gun, etiket, olay) do update set adet = k.adet + 1 where k.adet < 3000
  returning k.adet into n;
  return n is not null;
end
$$;
revoke all on function public._kaynak_artir(date, text, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
--  anon: ziyaret / test başladı
-- ---------------------------------------------------------------------------
create or replace function public.kaynak_say(p_etiket text, p_olay text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if coalesce(p_olay,'') not in ('ziyaret','test') then return false; end if;
  return public._kaynak_artir((now() at time zone 'Europe/Istanbul')::date, lower(btrim(p_etiket)), p_olay);
end
$$;
revoke all on function public.kaynak_say(text, text) from public;
grant execute on function public.kaynak_say(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
--  authenticated: üye oldu (hesap başına 1 kez, hesap ≤ 2 gün önce açılmışsa; gün = hesabın açıldığı gün)
-- ---------------------------------------------------------------------------
create or replace function public.kaynak_uye(p_etiket text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, auth
as $$
declare
  kim  uuid := auth.uid();
  olus timestamptz;
  e    text := lower(btrim(p_etiket));
  g    date;
begin
  if kim is null or e is null or e !~ '^[a-z0-9][a-z0-9_-]{0,31}$' then return false; end if;
  select u.created_at into olus from auth.users u where u.id = kim;
  if olus is null or olus < now() - interval '2 days' then return false; end if;
  g := (olus at time zone 'Europe/Istanbul')::date;
  if exists (select 1 from public.kaynak_uye_sayildi x where x.user_id = kim) then return false; end if;
  if not public._kaynak_artir(g, e, 'uye') then return false; end if;
  insert into public.kaynak_uye_sayildi (user_id) values (kim) on conflict do nothing;
  if not found then
    -- yarış: aynı hesap iki sekmeden aynı anda geldi → ikinci artışı geri al
    update public.kaynak_sayac set adet = adet - 1 where gun = g and etiket = e and olay = 'uye' and adet > 0;
    return false;
  end if;
  return true;
end
$$;
revoke all on function public.kaynak_uye(text) from public, anon;
grant execute on function public.kaynak_uye(text) to authenticated;

-- ---------------------------------------------------------------------------
--  yönetim: etiket × gün × (ziyaret, test, üye) — yalnız yönetici
-- ---------------------------------------------------------------------------
create or replace function public.yonetim_kaynak(p_gun integer default 60)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('gun', t.gun, 'etiket', t.etiket, 'ziyaret', t.ziyaret, 'test', t.test, 'uye', t.uye)
                     order by t.gun desc, t.ziyaret desc, t.etiket)
      from (select s.gun, s.etiket,
                   coalesce(sum(s.adet) filter (where s.olay = 'ziyaret'), 0)::int as ziyaret,
                   coalesce(sum(s.adet) filter (where s.olay = 'test'), 0)::int    as test,
                   coalesce(sum(s.adet) filter (where s.olay = 'uye'), 0)::int     as uye
              from public.kaynak_sayac s
             where s.gun >= (now() at time zone 'Europe/Istanbul')::date - least(greatest(coalesce(p_gun, 60), 1), 400)
             group by s.gun, s.etiket) t
  ), '[]'::jsonb);
end
$$;
revoke all on function public.yonetim_kaynak(integer) from public, anon;
grant execute on function public.yonetim_kaynak(integer) to authenticated;

-- ============================================================================
--  ÖZ-SINAV (göç işleminin içinde; kendi satırlarını geri alır). Bir vaka düşerse göç UYGULANMAZ.
--  Yakalaması gerekenler + yanlış alarm vermemesi gerekenler birlikte.
-- ============================================================================
do $$
declare
  hata text := '';
  bugun date := (now() at time zone 'Europe/Istanbul')::date;
  n integer;
  b boolean;
  i integer;
begin
  begin
    -- 1) geçerli etiket sayılır, ikinci çağrı 2 yapar (yanlış alarm vermemeli)
    if public.kaynak_say('zz-oz-sinav', 'ziyaret') is not true then hata := hata || ' [gecerli-ziyaret-reddedildi]'; end if;
    if public.kaynak_say('ZZ-OZ-SINAV ', 'ziyaret') is not true then hata := hata || ' [buyuk-harf-bosluk-normallesmedi]'; end if;
    select adet into n from public.kaynak_sayac where gun = bugun and etiket = 'zz-oz-sinav' and olay = 'ziyaret';
    if n is distinct from 2 then hata := hata || ' [adet-2-degil:' || coalesce(n::text,'null') || ']'; end if;
    if public.kaynak_say('zz-oz-sinav', 'test') is not true then hata := hata || ' [gecerli-test-reddedildi]'; end if;
    if public.kaynak_say('grup_whatsapp-1', 'ziyaret') is not true then hata := hata || ' [alt-cizgi-tire-reddedildi]'; end if;
    -- 2) bozuk girdiler sayılmaz
    if public.kaynak_say('zz-oz-sinav', 'uye') is not false then hata := hata || ' [anon-uye-sayildi]'; end if;
    if public.kaynak_say('zz-oz-sinav', 'sil') is not false then hata := hata || ' [bilinmeyen-olay-sayildi]'; end if;
    if public.kaynak_say('zz-oz-sinav', null) is not false then hata := hata || ' [null-olay-sayildi]'; end if;
    if public.kaynak_say(null, 'ziyaret') is not false then hata := hata || ' [null-etiket-sayildi]'; end if;
    if public.kaynak_say('', 'ziyaret') is not false then hata := hata || ' [bos-etiket-sayildi]'; end if;
    if public.kaynak_say('<script>', 'ziyaret') is not false then hata := hata || ' [html-etiket-sayildi]'; end if;
    if public.kaynak_say('öğrenci', 'ziyaret') is not false then hata := hata || ' [turkce-harf-sayildi]'; end if;
    if public.kaynak_say('-tire-basta', 'ziyaret') is not false then hata := hata || ' [tireyle-baslayan-sayildi]'; end if;
    if public.kaynak_say(repeat('a', 33), 'ziyaret') is not false then hata := hata || ' [33-karakter-sayildi]'; end if;
    if public.kaynak_say(repeat('a', 32), 'ziyaret') is not true then hata := hata || ' [32-karakter-reddedildi]'; end if;
    -- 3) üye yolu girişsizken kapalı (göçte auth.uid() boş)
    if public.kaynak_uye('zz-oz-sinav') is not false then hata := hata || ' [girissiz-uye-sayildi]'; end if;
    -- 4) satır tavanı 3000
    update public.kaynak_sayac set adet = 3000 where gun = bugun and etiket = 'zz-oz-sinav' and olay = 'ziyaret';
    if public.kaynak_say('zz-oz-sinav', 'ziyaret') is not false then hata := hata || ' [tavan-asildi]'; end if;
    select adet into n from public.kaynak_sayac where gun = bugun and etiket = 'zz-oz-sinav' and olay = 'ziyaret';
    if n is distinct from 3000 then hata := hata || ' [tavanda-adet-degisti]'; end if;
    -- 5) günlük 60 farklı etiket kotası: kota dolunca YENİ etiket reddedilir, VAR OLAN etiket sayılmaya devam eder
    select count(distinct etiket) into n from public.kaynak_sayac where gun = bugun;
    for i in 1 .. greatest(60 - n, 0) loop
      insert into public.kaynak_sayac (gun, etiket, olay, adet) values (bugun, 'zz-kota-' || i, 'ziyaret', 1) on conflict do nothing;
    end loop;
    if public.kaynak_say('zz-yeni-etiket', 'ziyaret') is not false then hata := hata || ' [etiket-kotasi-asildi]'; end if;
    if public.kaynak_say('zz-oz-sinav', 'test') is not true then hata := hata || ' [kotada-var-olan-reddedildi]'; end if;
    -- 6) tablo CHECK'i RPC'yi atlayan yazımı da durdurur
    begin
      insert into public.kaynak_sayac (gun, etiket, olay, adet) values (bugun, 'Bozuk Etiket!', 'ziyaret', 1);
      hata := hata || ' [check-bozuk-etiketi-aldi]';
    exception when check_violation then null;
    end;
    begin
      insert into public.kaynak_sayac (gun, etiket, olay, adet) values (bugun, 'zz-x', 'tikla', 1);
      hata := hata || ' [check-bozuk-olayi-aldi]';
    exception when check_violation then null;
    end;
    -- 7) yetkiler: anon üye/yönetim fonksiyonunu çağıramaz, tabloya dokunamaz
    if has_function_privilege('anon', 'public.kaynak_uye(text)', 'execute') then hata := hata || ' [anon-kaynak_uye-yetkili]'; end if;
    if has_function_privilege('anon', 'public.yonetim_kaynak(integer)', 'execute') then hata := hata || ' [anon-yonetim-yetkili]'; end if;
    if has_function_privilege('anon', 'public._kaynak_artir(date,text,text)', 'execute') then hata := hata || ' [anon-artir-yetkili]'; end if;
    if not has_function_privilege('anon', 'public.kaynak_say(text,text)', 'execute') then hata := hata || ' [anon-kaynak_say-yetkisiz]'; end if;
    if has_table_privilege('anon', 'public.kaynak_sayac', 'insert') or has_table_privilege('anon', 'public.kaynak_sayac', 'select')
       or has_table_privilege('authenticated', 'public.kaynak_sayac', 'update') then hata := hata || ' [tablo-dogrudan-acik]'; end if;
    -- 8) yönetim okuması girişsizken kapalı
    begin
      perform public.yonetim_kaynak(60);
      hata := hata || ' [yonetim-girissiz-acik]';
    exception when insufficient_privilege then null;
    end;
    raise exception 'KAYNAK_OZ_SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'KAYNAK_OZ_SINAV_GERI_AL' then raise; end if;
  end;
  if hata <> '' then
    raise exception 'KAYNAK SAYACI OZ-SINAV KIRMIZI:%', hata;
  end if;
  raise notice 'KAYNAK SAYACI OZ-SINAV YESIL';
end
$$;
