-- ============================================================================
--  KAYNAK SAYACI — mobil uygulama hesapları "uygulama" etiketiyle (16.10.2026, site kolu; Cem "2 ve 3 yap")
--
--  Neden (16.10 ölçüldü, auth admin, yalnız sayım): 13–16.10 açılan 23 hesabın 6'sı mobil uygulamadan
--  (user_metadata.kaynak = 'uygulama' / 'uygulama-google'); uygulamada ?k= olmadığı için tabloda "etiketsiz"
--  görünüyorlardı. Etiketi olmayan hesapta kaynak 'uygulama%' ise 'uygulama' etiketi sayılır.
--  Değişen: yalnız yonetim_kaynak'ın hesap alt sorgusu (etiket ifadesi). Gövdenin geri kalanı 2026-10-13 ile AYNI.
--  Eskitir: 2026-10-13-kaynak-uye-hesap.sql'deki yonetim_kaynak tanımı (_kaynak_artir aynen kalır).
--  🚫 GÖRMEZ: uygulamayı hangi reklamın indirttiği (mağaza kaynağı) · bu göçten önce etiketsiz açılmış web hesabı.
--  GERİ ALMA: 2026-10-13-kaynak-uye-hesap.sql'deki yonetim_kaynak tanımı yeniden basılır (veri silinmez).
-- ============================================================================

create or replace function public._kaynak_hesap_etiketi(p_meta jsonb)
returns text
language sql
immutable
set search_path = public
as $$
  select case
    when lower(p_meta->>'kaynak_etiket') ~ '^[a-z0-9][a-z0-9_-]{0,31}$' then lower(p_meta->>'kaynak_etiket')
    when coalesce(p_meta->>'kaynak', '') like 'uygulama%' then 'uygulama'
  end
$$;
revoke all on function public._kaynak_hesap_etiketi(jsonb) from public, anon, authenticated;

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
                       public._kaynak_hesap_etiketi(u.raw_user_meta_data) as etiket, count(*)::int as n
                  from auth.users u
                 where u.created_at >= bas
                   and public._kaynak_hesap_etiketi(u.raw_user_meta_data) is not null
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
--  ÖZ-SINAV (göç işleminin içinde; veri yazmaz). Bir vaka düşerse göç UYGULANMAZ.
-- ============================================================================
do $$
declare hata text := '';
begin
  -- yakalaması gerekenler
  if public._kaynak_hesap_etiketi('{"kaynak_etiket":"gads"}') is distinct from 'gads' then hata := hata || ' [etiket]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak_etiket":"GADS"}') is distinct from 'gads' then hata := hata || ' [buyuk-harf]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak":"uygulama"}') is distinct from 'uygulama' then hata := hata || ' [uygulama]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak":"uygulama-google"}') is distinct from 'uygulama' then hata := hata || ' [uygulama-google]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak_etiket":"ig","kaynak":"uygulama"}') is distinct from 'ig' then hata := hata || ' [etiket-once]'; end if;
  -- yanlış alarm / sayılmaması gerekenler
  if public._kaynak_hesap_etiketi('{"kaynak":"site-google"}') is not null then hata := hata || ' [site-google-sayildi]'; end if;
  if public._kaynak_hesap_etiketi('{}') is not null then hata := hata || ' [bos-sayildi]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak_etiket":"<script>"}') is not null then hata := hata || ' [bozuk-etiket]'; end if;
  if public._kaynak_hesap_etiketi('{"kaynak_etiket":"<x>","kaynak":"uygulama"}') is distinct from 'uygulama' then hata := hata || ' [bozuk-etiket-uygulama]'; end if;
  if has_function_privilege('anon', 'public.yonetim_kaynak(integer)', 'execute') then hata := hata || ' [anon-yonetim-yetkili]'; end if;
  if has_function_privilege('anon', 'public._kaynak_hesap_etiketi(jsonb)', 'execute') then hata := hata || ' [anon-etiket-yetkili]'; end if;
  begin
    perform public.yonetim_kaynak(60);
    hata := hata || ' [yonetim-girissiz-acik]';
  exception when insufficient_privilege then null;
  end;
  if hata <> '' then
    raise exception 'KAYNAK UYGULAMA OZ-SINAV KIRMIZI:%', hata;
  end if;
  raise notice 'KAYNAK UYGULAMA OZ-SINAV YESIL (11 vaka)';
end
$$;
