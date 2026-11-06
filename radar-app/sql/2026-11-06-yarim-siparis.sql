-- YARIM SİPARİŞ (06.11.2026, Cem "alamayan kişi bir daha böyle sıkıntıyla karşılaşmasın")
-- ÖLÇÜLDÜ (06.11, son 14 gün): kart denenen 80 siparişin 18'inde kart geçmedi; 16'sı iyzico sayfasında kaldı, 2'si reddedildi; 7'si sonra ödedi.
-- Girişli üye satın alma sayfasını açınca, hangi cihazdan gelirse gelsin, kendi yarım siparişini en üstte görür.
-- siparis_yarim_benim: üyenin e-postasındaki son 72 saatin en yeni ödeme bekleyen siparişi. Aynı ya da sonraki tarihte aynı e-postayla
-- ödenmiş sipariş varsa hiçbir şey dönmez (başka siparişle ödeyene "yarım" denmez).
-- 🚫 GÖRMEZ: başka e-postayla ödeme · paketin hediye/mağaza yoluyla açılması (ödeme başlatılırken iyzico-odeme.ts reddeder) ·
--    72 saatten eski sipariş · bu arada fiyatı değişmiş sipariş (kart başlamaz, sayfa yeniden sipariş yolunu gösterir).
create or replace function public.siparis_yarim_benim()
 returns table (siparis_no text, tutar numeric, paket_ad text)
 language sql
 stable
 security definer
 set search_path to 'public', 'auth'
as $function$
  select s.siparis_no::text, s.tutar::numeric, s.paket_ad::text
    from public.siparisler s
    join auth.users u on u.id = auth.uid()
   where lower(s.email) = lower(btrim(u.email)) and s.durum = 'odeme_bekliyor'
     and s.olusturma > now() - interval '72 hours'
     and not exists (select 1 from public.siparisler o
                      where lower(o.email) = lower(s.email) and o.durum = 'odendi' and o.olusturma >= s.olusturma)
   order by s.olusturma desc
   limit 1
$function$;
revoke execute on function public.siparis_yarim_benim() from public, anon, authenticated;
grant execute on function public.siparis_yarim_benim() to authenticated;

-- ÖZ-SINAV (alt işlemde, OLCU_TAMAM ile GERİ ALINIR):
--   a) sahibi görür · b) başka üye görmez · e) girişsiz görmez · d) 72 saatten eski görünmez · c) sonra ödenen sipariş varsa görünmez
do $$
declare
  ua constant uuid := '00000000-0000-4000-8000-0000000b5b01';
  ub constant uuid := '00000000-0000-4000-8000-0000000b5b02';
  v text;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x.ep, now(), now()
      from (values (ua, 'olcu-yrm-a@tetikte.invalid'), (ub, 'olcu-yrm-b@tetikte.invalid')) x(id, ep);
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
    values ('TT-20261106-YRA', 'sgs', 2988, 'Olcu A', 'OLCU-yrm-a@tetikte.invalid', 'havale', 'odeme_bekliyor');

    perform set_config('request.jwt.claims', json_build_object('sub', ua::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ua::text, true);
    select y.siparis_no into v from public.siparis_yarim_benim() y;
    if v is distinct from 'TT-20261106-YRA' then raise exception 'OLCU: a %', v; end if;

    perform set_config('request.jwt.claims', json_build_object('sub', ub::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ub::text, true);
    v := null; select y.siparis_no into v from public.siparis_yarim_benim() y;
    if v is not null then raise exception 'OLCU: b %', v; end if;

    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    v := null; select y.siparis_no into v from public.siparis_yarim_benim() y;
    if v is not null then raise exception 'OLCU: e %', v; end if;

    perform set_config('request.jwt.claims', json_build_object('sub', ua::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ua::text, true);
    update public.siparisler set olusturma = now() - interval '73 hours' where siparis_no = 'TT-20261106-YRA';
    v := null; select y.siparis_no into v from public.siparis_yarim_benim() y;
    if v is not null then raise exception 'OLCU: d %', v; end if;

    update public.siparisler set olusturma = now() where siparis_no = 'TT-20261106-YRA';
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
    values ('TT-20261106-YRB', 'son20-sgs', 999, 'Olcu A', 'olcu-yrm-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261106-YRB';
    v := null; select y.siparis_no into v from public.siparis_yarim_benim() y;
    if v is not null then raise exception 'OLCU: c %', v; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261106-YR_')
     or exists (select 1 from auth.users where email like 'olcu-yrm-%@tetikte.invalid') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'YARIM SIPARIS OZ-SINAV: 5 vaka TAMAM (geri alindi)';
end $$;
