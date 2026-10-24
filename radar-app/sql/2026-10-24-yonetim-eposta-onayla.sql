-- ============================================================================
--  YÖNETİM: E-POSTA ONAYLA  ·  24.10.2026
--
--  OLAY (ölçüldü 24.10): panelden ders hediyesi verilen hesap (e-posta + şifre, 24.10 07:26 açılmış) onay mailine
--  tıklamamıştı, hiç giriş yapmamıştı → "Confirm email" açık olduğu için kişi giremiyor, hediye görünmüyordu. Panel
--  bunu söylemiyordu. Cem 24.10: "e-postasını onayla, girebilsin. Panele de uyarı ekle."
--
--  NE YAPAR: yonetim_eposta_onayla(eposta) → auth.users.email_confirmed_at boşsa now(). Yalnız yönetici. Panel hediye
--  verirken yonetim_hesap_bul ile onay/giriş durumunu gösterir; onaysızsa bu düğmeyi önerir.
--  🚫 GÖRMEZ: e-postanın gerçekten o kişiye ait olduğu (yönetici kişiyi tanıyarak onaylar) · onay mailinin kutuya varıp
--     varmadığı.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop function public.yonetim_eposta_onayla(text);
-- ============================================================================

create or replace function public.yonetim_eposta_onayla(p_eposta text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_uid uuid; v_onay timestamptz;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id, email_confirmed_at into v_uid, v_onay from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if v_onay is not null then
    return jsonb_build_object('eposta', lower(trim(p_eposta)), 'zaten', true, 'onay', v_onay);
  end if;
  update auth.users set email_confirmed_at = now(), updated_at = now() where id = v_uid;
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'zaten', false, 'onay', now());
end $$;
revoke all on function public.yonetim_eposta_onayla(text) from public, anon;
grant execute on function public.yonetim_eposta_onayla(text) to authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (geri alınır)
do $$
declare
  y constant uuid := '00000000-0000-4000-8000-0000000e0a01';
  a constant uuid := '00000000-0000-4000-8000-0000000e0a0a';
  r jsonb; n int := 0;
begin
  begin
    insert into public.yoneticiler (user_id) values (y) on conflict do nothing;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-onay-a@tetikte.invalid', now(), now());

    -- 1) yönetici olmayan onaylayamaz (kendi hesabını bile)
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    begin perform public.yonetim_eposta_onayla('olcu-onay-a@tetikte.invalid'); raise exception 'OLCU: yonetici olmayan onayladi';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    if (select email_confirmed_at from auth.users where id = a) is not null then raise exception 'OLCU: yetkisiz cagri iz birakti'; end if;
    n := n + 2;

    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);

    -- 2) hesap yok
    begin perform public.yonetim_eposta_onayla('olcu-onay-yok@tetikte.invalid'); raise exception 'OLCU: hesapsiz kabul edildi';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    n := n + 1;

    -- 3) onaysız → onaylı (büyük harf/boşluk farkı)
    r := public.yonetim_eposta_onayla('  OLCU-ONAY-A@tetikte.invalid ');
    if (r->>'zaten')::boolean or (select email_confirmed_at from auth.users where id = a) is null then raise exception 'OLCU: onaylanmadi %', r; end if;
    n := n + 1;

    -- 4) ikinci çağrı: zaten onaylı, tarih değişmez
    r := public.yonetim_eposta_onayla('olcu-onay-a@tetikte.invalid');
    if not (r->>'zaten')::boolean then raise exception 'OLCU: ikinci cagri zaten demedi'; end if;
    n := n + 1;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-onay-%@tetikte.invalid')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000e0a01') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'EPOSTA ONAYLA OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
