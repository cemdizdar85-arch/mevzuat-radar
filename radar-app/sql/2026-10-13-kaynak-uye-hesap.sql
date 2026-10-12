-- ============================================================================
--  KAYNAK SAYACI — üye sayımı hesaptan + satır tavanı (13.10.2026, site kolu; Cem "1.2.3.4 yap")
--
--  Neden (13.10 ölçüldü, auth admin + kaynak_sayac): 08–13.10 arası 44 yeni hesap açıldı, yönetim tablosu "Üye oldu"
--  sütununda 2 gösterdi. ttKaynak.uye() etiketi aynı tarayıcının localStorage'ında arıyor; Instagram iç tarayıcısında
--  gelip onay mailini başka tarayıcıda açan sayılmıyor. Ayrıca ig 11.10 ziyareti 3.000 SATIR TAVANINA dayandı
--  (o günün gerçek sayısı bilinmiyor).
--
--  Değişen:
--   · Etiket artık hesap açılırken user_metadata.kaynak_etiket olarak hesaba yazılır (ogrenci.html signUp +
--     google-giris.js ilk giriş). yonetim_kaynak 'uye' = sayaç + (kaynak_etiket'li AMA kaynak_uye_sayildi'de olmayan
--     hesap) → aynı hesap iki kez sayılmaz.
--   · yonetim_kaynak her güne '(tüm yeni hesaplar)' satırı ekler (etiketsiz dahil bütün yeni hesaplar) — tablo
--     "kimse üye olmuyor" dedirtmesin; gerçek toplam yanında dursun.
--   · _kaynak_artir satır tavanı 3.000 → 50.000 (tablo CHECK 100.000; satır sayısı değişmez, yalnız adet büyür).
--  Eskitir: 2026-10-11-kaynak-ornek.sql'deki _kaynak_artir ve yonetim_kaynak tanımları (kaynak_say aynen kalır).
--  🚫 GÖRMEZ: bu göçten ÖNCE açılmış hesabın etiketi (metadata'da yok) · etiketsiz gelen · bir cihazda linki açıp
--    başka cihazda üye olan · Google hesabı başka sekmede dönen (google-giris.js onay anı yoksa hiç yazmaz).
--  GERİ ALMA: 2026-10-11-kaynak-ornek.sql'deki iki tanım yeniden basılır (veri silinmez).
-- ============================================================================

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
     or coalesce(p_olay,'') not in ('ziyaret','test','uye','ornek') then
    return false;
  end if;
  if not exists (select 1 from public.kaynak_sayac s where s.gun = p_gun and s.etiket = p_etiket)
     and (select count(distinct s.etiket) from public.kaynak_sayac s where s.gun = p_gun) >= 60 then
    return false;
  end if;
  insert into public.kaynak_sayac as k (gun, etiket, olay, adet) values (p_gun, p_etiket, p_olay, 1)
  on conflict (gun, etiket, olay) do update set adet = k.adet + 1 where k.adet < 50000
  returning k.adet into n;
  return n is not null;
end
$$;
revoke all on function public._kaynak_artir(date, text, text) from public, anon, authenticated;

create or replace function public.yonetim_kaynak(p_gun integer default 60)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare bas date;
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;
  bas := (now() at time zone 'Europe/Istanbul')::date - least(greatest(coalesce(p_gun, 60), 1), 400);
  return coalesce((
    select jsonb_agg(jsonb_build_object('gun', t.gun, 'etiket', t.etiket, 'ziyaret', t.ziyaret, 'ornek', t.ornek, 'test', t.test, 'uye', t.uye)
                     order by t.gun desc, t.sira, t.ziyaret desc, t.etiket)
      from (
        select coalesce(s.gun, m.gun) as gun, coalesce(s.etiket, m.etiket) as etiket, 0 as sira,
               coalesce(s.ziyaret, 0) as ziyaret, coalesce(s.ornek, 0) as ornek, coalesce(s.test, 0) as test,
               coalesce(s.uye, 0) + coalesce(m.n, 0) as uye
          from (select s.gun, s.etiket,
                       coalesce(sum(s.adet) filter (where s.olay = 'ziyaret'), 0)::int as ziyaret,
                       coalesce(sum(s.adet) filter (where s.olay = 'ornek'), 0)::int   as ornek,
                       coalesce(sum(s.adet) filter (where s.olay = 'test'), 0)::int    as test,
                       coalesce(sum(s.adet) filter (where s.olay = 'uye'), 0)::int     as uye
                  from public.kaynak_sayac s
                 where s.gun >= bas
                 group by s.gun, s.etiket) s
          full outer join
               (select (u.created_at at time zone 'Europe/Istanbul')::date as gun,
                       lower(u.raw_user_meta_data->>'kaynak_etiket') as etiket, count(*)::int as n
                  from auth.users u
                 where u.created_at >= bas
                   and lower(u.raw_user_meta_data->>'kaynak_etiket') ~ '^[a-z0-9][a-z0-9_-]{0,31}$'
                   and not exists (select 1 from public.kaynak_uye_sayildi k where k.user_id = u.id)
                 group by 1, 2) m
            on m.gun = s.gun and m.etiket = s.etiket
        union all
        select (u.created_at at time zone 'Europe/Istanbul')::date, '(tüm yeni hesaplar)', 1, 0, 0, 0, count(*)::int
          from auth.users u
         where u.created_at >= bas
         group by 1
      ) t
  ), '[]'::jsonb);
end
$$;
revoke all on function public.yonetim_kaynak(integer) from public, anon;
grant execute on function public.yonetim_kaynak(integer) to authenticated;

-- ============================================================================
--  ÖZ-SINAV (göç işleminin içinde; kendi satırlarını geri alır). Bir vaka düşerse göç UYGULANMAZ.
-- ============================================================================
do $$
declare
  hata text := '';
  bugun date := (now() at time zone 'Europe/Istanbul')::date;
begin
  begin
    -- yakalaması gerekenler: eski 3.000 tavanı artık sayıyı kesmiyor, yeni tavan kesiyor
    if public.kaynak_say('zz-oz-tavan', 'ziyaret') is not true then hata := hata || ' [ziyaret-reddedildi]'; end if;
    update public.kaynak_sayac set adet = 3000 where gun = bugun and etiket = 'zz-oz-tavan' and olay = 'ziyaret';
    if public.kaynak_say('zz-oz-tavan', 'ziyaret') is not true then hata := hata || ' [3000-hala-tavan]'; end if;
    update public.kaynak_sayac set adet = 50000 where gun = bugun and etiket = 'zz-oz-tavan' and olay = 'ziyaret';
    if public.kaynak_say('zz-oz-tavan', 'ziyaret') is not false then hata := hata || ' [50000-tavan-asildi]'; end if;
    -- yanlış alarm / açılmaması gerekenler
    if public.kaynak_say('zz-oz-tavan', 'uye') is not false then hata := hata || ' [anon-uye-sayildi]'; end if;
    if public.kaynak_say('<script>', 'ziyaret') is not false then hata := hata || ' [bozuk-etiket-sayildi]'; end if;
    if has_function_privilege('anon', 'public._kaynak_artir(date,text,text)', 'execute') then hata := hata || ' [anon-artir-yetkili]'; end if;
    if has_function_privilege('anon', 'public.yonetim_kaynak(integer)', 'execute') then hata := hata || ' [anon-yonetim-yetkili]'; end if;
    begin
      perform public.yonetim_kaynak(60);
      hata := hata || ' [yonetim-girissiz-acik]';
    exception when insufficient_privilege then null;
    end;
    raise exception 'KAYNAK_UYE_OZ_SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'KAYNAK_UYE_OZ_SINAV_GERI_AL' then raise; end if;
  end;
  if hata <> '' then
    raise exception 'KAYNAK UYE OZ-SINAV KIRMIZI:%', hata;
  end if;
  raise notice 'KAYNAK UYE OZ-SINAV YESIL';
end
$$;
