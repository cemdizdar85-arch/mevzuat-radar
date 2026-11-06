-- BEKLEYEN SİPARİŞ ÇIKMAZI (06.11.2026, Cem "Evet, düzelt"): başka cihazdan gelen alıcı siparis_cift_kapi'dan BEKLEYEN_SIPARIS
-- alınca tarayıcıda sipariş numarası yoktu; sayfa 29.10'dan beri gitmeyen "Siparişin alındı" mailine yönlendiriyordu.
-- Bu fonksiyon girişli üyeye YALNIZ KENDİ e-postasındaki bekleyen siparişin numarasını verir; sayfa ?ode= ekranına gider.
-- Kapının koşullarıyla birebir aynı: e-posta + paket + tutar + aynı dersler + 24 saat.
-- 🚫 GÖRMEZ: girişsiz alıcı (satin-al.html 01.11'den beri girişsiz sipariş almıyor; eski yol NULL döner, sayfa WhatsApp'a yönlendirir).
create or replace function public.siparis_bekleyen_no(p_paket text, p_tutar numeric, p_dersler text[] default null)
 returns text
 language sql
 stable
 security definer
 set search_path to 'public', 'auth'
as $function$
  select s.siparis_no
    from public.siparisler s
    join auth.users u on u.id = auth.uid()
   where lower(s.email) = lower(btrim(u.email)) and s.durum = 'odeme_bekliyor'
     and s.paket = p_paket and s.tutar = p_tutar
     and coalesce(s.secilen_dersler, array[]::text[]) @> coalesce(p_dersler, array[]::text[])
     and coalesce(s.secilen_dersler, array[]::text[]) <@ coalesce(p_dersler, array[]::text[])
     and s.olusturma > now() - interval '24 hours'
   order by s.olusturma desc
   limit 1
$function$;
revoke execute on function public.siparis_bekleyen_no(text, numeric, text[]) from public, anon, authenticated;
grant execute on function public.siparis_bekleyen_no(text, numeric, text[]) to authenticated;

-- ÖZ-SINAV (alt işlemde, OLCU_TAMAM ile GERİ ALINIR):
--   a) sahibi numarasını alır · b) başka üye NULL · c) farklı tutar NULL · d) farklı ders NULL · e) girişsiz NULL
do $$
declare
  ua constant uuid := '00000000-0000-4000-8000-0000000b5a01';
  ub constant uuid := '00000000-0000-4000-8000-0000000b5a02';
  v text;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x.ep, now(), now()
      from (values (ua, 'olcu-bsn-a@tetikte.invalid'), (ub, 'olcu-bsn-b@tetikte.invalid')) x(id, ep);
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261106-BSA', 'yeterlilik-1', 2988, 'Olcu A', 'OLCU-bsn-a@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Hukuk']);

    perform set_config('request.jwt.claims', json_build_object('sub', ua::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ua::text, true);
    v := public.siparis_bekleyen_no('yeterlilik-1', 2988, array['Hukuk']);
    if v is distinct from 'TT-20261106-BSA' then raise exception 'OLCU: a %', v; end if;
    v := public.siparis_bekleyen_no('yeterlilik-1', 1999, array['Hukuk']);
    if v is not null then raise exception 'OLCU: c %', v; end if;
    v := public.siparis_bekleyen_no('yeterlilik-1', 2988, array['Finansal Muhasebe']);
    if v is not null then raise exception 'OLCU: d %', v; end if;

    perform set_config('request.jwt.claims', json_build_object('sub', ub::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ub::text, true);
    v := public.siparis_bekleyen_no('yeterlilik-1', 2988, array['Hukuk']);
    if v is not null then raise exception 'OLCU: b %', v; end if;

    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    v := public.siparis_bekleyen_no('yeterlilik-1', 2988, array['Hukuk']);
    if v is not null then raise exception 'OLCU: e %', v; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no = 'TT-20261106-BSA')
     or exists (select 1 from auth.users where email like 'olcu-bsn-%@tetikte.invalid') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'BEKLEYEN SIPARIS NO OZ-SINAV: 5 vaka TAMAM (geri alindi)';
end $$;
