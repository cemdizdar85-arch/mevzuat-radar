-- ============================================================================
--  KAYNAK SAYACI — 'ornek' adımı (11.10.2026, site kolu; Cem "1.2.3": ana sayfanın ilk kapısı 5 soru)
--
--  Neden: ana sayfada üye olmayanın birinci düğmesi artık 5 örnek soru (kaydir/vitrin/ornek-*.html). Instagram
--  ziyaretinin teste geçişi 08–11.10'da %2 (1.116 → 22) ölçüldü; yeni kapının etkisini kaynak başına görmek için
--  "5 soruyu açtı" adımı sayılır. Ziyaretçi tarafı paket-kapisi.js (örnek sayfası bloğu).
--
--  Değişen: olay kümesine 'ornek' eklenir (tablo CHECK + _kaynak_artir + kaynak_say anon yolu) ve yonetim_kaynak
--  çıktısına 'ornek' sütunu gelir. Öteki bütün sınırlar 2026-10-08-kaynak-sayac.sql ile AYNI (etiket biçimi, satır
--  tavanı 3.000, gün başına 60 etiket, tabloya doğrudan yazma yok, IP/e-posta/kullanıcı kimliği yok).
--  Eskitir: 2026-10-08-kaynak-sayac.sql'deki _kaynak_artir, kaynak_say, yonetim_kaynak tanımları ve kaynak_sayac_olay CHECK'i.
--  🚫 GÖRMEZ: 2026-10-08 dosyasındaki körlüklerin aynısı (betikle sahte 'ornek' basılabilir; tavana kadar şişer,
--    tablo büyümez) · 5 soruyu açıp hiç cevaplamayan da sayılır (adım = sayfa açılışı, cevap değil).
--  GERİ ALMA: 2026-10-08-kaynak-sayac.sql'deki üç fonksiyon tanımı + CHECK (olay in ('ziyaret','test','uye')),
--    önce: delete from public.kaynak_sayac where olay = 'ornek';
-- ============================================================================

alter table public.kaynak_sayac drop constraint if exists kaynak_sayac_olay;
alter table public.kaynak_sayac add constraint kaynak_sayac_olay check (olay in ('ziyaret','test','uye','ornek'));

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
  on conflict (gun, etiket, olay) do update set adet = k.adet + 1 where k.adet < 3000
  returning k.adet into n;
  return n is not null;
end
$$;
revoke all on function public._kaynak_artir(date, text, text) from public, anon, authenticated;

create or replace function public.kaynak_say(p_etiket text, p_olay text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if coalesce(p_olay,'') not in ('ziyaret','test','ornek') then return false; end if;
  return public._kaynak_artir((now() at time zone 'Europe/Istanbul')::date, lower(btrim(p_etiket)), p_olay);
end
$$;
revoke all on function public.kaynak_say(text, text) from public;
grant execute on function public.kaynak_say(text, text) to anon, authenticated;

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
    select jsonb_agg(jsonb_build_object('gun', t.gun, 'etiket', t.etiket, 'ziyaret', t.ziyaret, 'ornek', t.ornek, 'test', t.test, 'uye', t.uye)
                     order by t.gun desc, t.ziyaret desc, t.etiket)
      from (select s.gun, s.etiket,
                   coalesce(sum(s.adet) filter (where s.olay = 'ziyaret'), 0)::int as ziyaret,
                   coalesce(sum(s.adet) filter (where s.olay = 'ornek'), 0)::int   as ornek,
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
-- ============================================================================
do $$
declare
  hata text := '';
  bugun date := (now() at time zone 'Europe/Istanbul')::date;
  n integer;
begin
  begin
    -- yakalaması gerekenler: yeni adım sayılır, eskiler bozulmadı
    if public.kaynak_say('zz-oz-ornek', 'ornek') is not true then hata := hata || ' [ornek-reddedildi]'; end if;
    if public.kaynak_say('zz-oz-ornek', 'ornek') is not true then hata := hata || ' [ornek-ikinci-reddedildi]'; end if;
    select adet into n from public.kaynak_sayac where gun = bugun and etiket = 'zz-oz-ornek' and olay = 'ornek';
    if n is distinct from 2 then hata := hata || ' [ornek-adet-2-degil:' || coalesce(n::text,'null') || ']'; end if;
    if public.kaynak_say('zz-oz-ornek', 'ziyaret') is not true then hata := hata || ' [ziyaret-bozuldu]'; end if;
    if public.kaynak_say('zz-oz-ornek', 'test') is not true then hata := hata || ' [test-bozuldu]'; end if;
    -- yanlış alarm vermemesi / açılmaması gerekenler
    if public.kaynak_say('zz-oz-ornek', 'uye') is not false then hata := hata || ' [anon-uye-sayildi]'; end if;
    if public.kaynak_say('zz-oz-ornek', 'ORNEK') is not false then hata := hata || ' [buyuk-harf-olay-sayildi]'; end if;
    if public.kaynak_say('zz-oz-ornek', 'tikla') is not false then hata := hata || ' [bilinmeyen-olay-sayildi]'; end if;
    if public.kaynak_say('<script>', 'ornek') is not false then hata := hata || ' [bozuk-etiket-sayildi]'; end if;
    begin
      insert into public.kaynak_sayac (gun, etiket, olay, adet) values (bugun, 'zz-x', 'tikla', 1);
      hata := hata || ' [check-bozuk-olayi-aldi]';
    exception when check_violation then null;
    end;
    -- satır tavanı yeni adımda da geçerli
    update public.kaynak_sayac set adet = 3000 where gun = bugun and etiket = 'zz-oz-ornek' and olay = 'ornek';
    if public.kaynak_say('zz-oz-ornek', 'ornek') is not false then hata := hata || ' [ornek-tavan-asildi]'; end if;
    -- yetkiler
    if has_function_privilege('anon', 'public._kaynak_artir(date,text,text)', 'execute') then hata := hata || ' [anon-artir-yetkili]'; end if;
    if has_function_privilege('anon', 'public.yonetim_kaynak(integer)', 'execute') then hata := hata || ' [anon-yonetim-yetkili]'; end if;
    if not has_function_privilege('anon', 'public.kaynak_say(text,text)', 'execute') then hata := hata || ' [anon-kaynak_say-yetkisiz]'; end if;
    begin
      perform public.yonetim_kaynak(60);
      hata := hata || ' [yonetim-girissiz-acik]';
    exception when insufficient_privilege then null;
    end;
    raise exception 'KAYNAK_ORNEK_OZ_SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'KAYNAK_ORNEK_OZ_SINAV_GERI_AL' then raise; end if;
  end;
  if hata <> '' then
    raise exception 'KAYNAK ORNEK OZ-SINAV KIRMIZI:%', hata;
  end if;
  raise notice 'KAYNAK ORNEK OZ-SINAV YESIL';
end
$$;
