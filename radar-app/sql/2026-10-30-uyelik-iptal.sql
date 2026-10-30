-- ============================================================================
--  YÖNETİM: ÜYELİK İPTALİ + GİRİŞ ENGELİ  ·  30.10.2026
--
--  OLAY: 29.10'da kartla Yeterlilik tüm dersler alan bir üye iade istedi. Cem 30.10: "üyeliği iade etti, nasıl
--  kapatacağım, siteye girmesin bir daha · üyeleri göreyim iptal edebileyim". Panelde yalnız HEDİYE paketi kapatan
--  düğme vardı; parayla alınmış paketi kapatan ve hesabın girişini durduran yol yoktu (SQL gerekiyordu).
--
--  NE YAPAR (hepsi yalnız yönetici, security definer, anon EXECUTE yok; satır SİLMEZ — oturumlar hariç):
--    yonetim_uyelik_iptal(eposta, neden, engelle, iade)
--      · hesabın açık bütün paketleri dün tarihiyle kapanır (paket_uyeler.bitis)
--      · iade=true: bu e-postanın 'odendi' siparişleri 'iade' olur (elçi komisyonuna/kurucu sayacına girmez,
--        yonetim_siparis_iade ile aynı anlam). PARA GERİ GÖNDERİMİ BURADA YOK — iyzico panelinden yapılır.
--      · engelle=true: auth.users.banned_until = şimdi + 100 yıl → Supabase Auth girişi (şifre, Google, Apple) ve
--        oturum tazelemeyi reddeder; açık oturumlar (auth.sessions + auth.refresh_tokens) silinir.
--      · yönetici hesabı kapatılamaz (YONETICI_KAPATILAMAZ) — panelden kendini kilitleme yok.
--    yonetim_uye_engel_kaldir(eposta, neden) → banned_until boşalır (paket geri AÇILMAZ; gerekirse Paket ver)
--    yonetim_engelliler() → engelli hesaplar + son kayıt (panel Üyeler sekmesi)
--    Her işlem public.uye_islem_kutugu'ne yazılır (kim, ne zaman, neden, kaç paket/sipariş).
--
--  🚫 GÖRMEZ / YAPMAZ: engellenen kişinin BAŞKA bir e-postayla yeni hesap açması (engel hesaba bağlı) · zaten
--     verilmiş erişim jetonu süresi dolana kadar (en çok 1 saat) geçerlidir; paket o anda kapandığı için kasa açmaz ·
--     iyzico'da paranın gerçekten geri gönderildiği.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop function public.yonetim_uyelik_iptal(text,text,boolean,boolean), public.yonetim_uye_engel_kaldir(text,text),
--             public.yonetim_engelliler(); drop table public.uye_islem_kutugu;
-- ============================================================================

create table if not exists public.uye_islem_kutugu (
  id             bigserial primary key,
  user_id        uuid not null,
  eposta         text not null,
  islem          text not null check (islem in ('iptal', 'engel_kaldir')),
  neden          text,
  engel          boolean not null default false,
  paket_kapanan  int not null default 0,
  iade_siparis   text[],
  yapan          uuid,
  zaman          timestamptz not null default now()
);
alter table public.uye_islem_kutugu enable row level security;
revoke all on public.uye_islem_kutugu from anon, authenticated;

create or replace function public.yonetim_uyelik_iptal(p_eposta text, p_neden text, p_engelle boolean, p_iade boolean)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_ep text := lower(trim(coalesce(p_eposta, ''))); v_uid uuid; v_paket int := 0; v_iade text[] := '{}';
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if length(trim(coalesce(p_neden, ''))) < 3 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = v_ep limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if exists (select 1 from public.yoneticiler where user_id = v_uid) then raise exception 'YONETICI_KAPATILAMAZ'; end if;

  update public.paket_uyeler set bitis = current_date - 1 where user_id = v_uid and bitis >= current_date;
  get diagnostics v_paket = row_count;

  if coalesce(p_iade, false) then
    with g as (
      update public.siparisler set durum = 'iade' where lower(email) = v_ep and durum = 'odendi' returning siparis_no
    ) select coalesce(array_agg(siparis_no), '{}') into v_iade from g;
  end if;

  if coalesce(p_engelle, false) then
    update auth.users set banned_until = now() + interval '100 years', updated_at = now() where id = v_uid;
    delete from auth.refresh_tokens where user_id = v_uid::text;
    delete from auth.sessions where user_id = v_uid;
  end if;

  insert into public.uye_islem_kutugu (user_id, eposta, islem, neden, engel, paket_kapanan, iade_siparis, yapan)
  values (v_uid, v_ep, 'iptal', left(trim(p_neden), 300), coalesce(p_engelle, false), v_paket, v_iade, auth.uid());

  return jsonb_build_object('eposta', v_ep, 'paket_kapanan', v_paket, 'iade', to_jsonb(v_iade), 'engel', coalesce(p_engelle, false));
end $$;
revoke all on function public.yonetim_uyelik_iptal(text, text, boolean, boolean) from public, anon;
grant execute on function public.yonetim_uyelik_iptal(text, text, boolean, boolean) to authenticated;

create or replace function public.yonetim_uye_engel_kaldir(p_eposta text, p_neden text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_ep text := lower(trim(coalesce(p_eposta, ''))); v_uid uuid;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id into v_uid from auth.users where lower(email) = v_ep limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  update auth.users set banned_until = null, updated_at = now() where id = v_uid;
  insert into public.uye_islem_kutugu (user_id, eposta, islem, neden, yapan)
  values (v_uid, v_ep, 'engel_kaldir', left(trim(coalesce(p_neden, '')), 300), auth.uid());
  return jsonb_build_object('eposta', v_ep, 'engel', false);
end $$;
revoke all on function public.yonetim_uye_engel_kaldir(text, text) from public, anon;
grant execute on function public.yonetim_uye_engel_kaldir(text, text) to authenticated;

create or replace function public.yonetim_engelliler()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('eposta', lower(u.email), 'engel_bitis', u.banned_until,
             'neden', k.neden, 'zaman', k.zaman) order by k.zaman desc nulls last)
    from auth.users u
    left join lateral (select neden, zaman from public.uye_islem_kutugu x
                        where x.user_id = u.id and x.islem = 'iptal' order by x.zaman desc limit 1) k on true
    where u.banned_until > now()
  ), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_engelliler() from public, anon;
grant execute on function public.yonetim_engelliler() to authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (geri alınır)
do $$
declare
  y constant uuid := '00000000-0000-4000-8000-0000000e1a01';
  a constant uuid := '00000000-0000-4000-8000-0000000e1a0a';
  r jsonb; n int := 0;
begin
  begin
    insert into public.yoneticiler (user_id) values (y) on conflict do nothing;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-iptal-a@tetikte.invalid', now(), now()),
      (y, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-iptal-y@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'yeterlilik-tum', current_date + 90);
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261030-U301', 'yeterlilik-tum', 2868, 'Olcu Iptal', 'olcu-iptal-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261030-U301';
    insert into auth.sessions (id, user_id, created_at, updated_at) values (gen_random_uuid(), a, now(), now());

    -- 1) yönetici olmayan çağıramaz
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    begin perform public.yonetim_uyelik_iptal('olcu-iptal-a@tetikte.invalid', 'deneme', true, true); raise exception 'OLCU: yonetici olmayan iptal etti';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    begin perform public.yonetim_engelliler(); raise exception 'OLCU: yonetici olmayan engelli listesini okudu';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    if (select bitis from public.paket_uyeler where user_id = a) < current_date then raise exception 'OLCU: yetkisiz cagri paketi kapatti'; end if;
    n := n + 3;

    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);

    -- 2) neden zorunlu · hesap yok · yönetici kapatılamaz
    begin perform public.yonetim_uyelik_iptal('olcu-iptal-a@tetikte.invalid', ' ', true, true); raise exception 'OLCU: nedensiz kabul';
    exception when others then if sqlerrm not like '%NEDEN_GEREKLI%' then raise; end if; end;
    begin perform public.yonetim_uyelik_iptal('olcu-iptal-yok@tetikte.invalid', 'deneme', true, true); raise exception 'OLCU: hesapsiz kabul';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    begin perform public.yonetim_uyelik_iptal('olcu-iptal-y@tetikte.invalid', 'deneme', true, false); raise exception 'OLCU: yonetici kapatildi';
    exception when others then if sqlerrm not like '%YONETICI_KAPATILAMAZ%' then raise; end if; end;
    if (select banned_until from auth.users where id = y) is not null then raise exception 'OLCU: yonetici engellendi'; end if;
    n := n + 4;

    -- 3) iptal: paket kapanır, sipariş iade, giriş engeli, oturum silinir, kütük yazılır (büyük harf/boşluk farkı)
    r := public.yonetim_uyelik_iptal('  OLCU-IPTAL-A@tetikte.invalid ', 'iade istedi', true, true);
    if (r->>'paket_kapanan')::int <> 1 then raise exception 'OLCU: paket kapanmadi %', r; end if;
    if (select bitis from public.paket_uyeler where user_id = a) >= current_date then raise exception 'OLCU: paket hala acik'; end if;
    if (select durum from public.siparisler where siparis_no = 'TT-20261030-U301') <> 'iade' then raise exception 'OLCU: siparis iade olmadi'; end if;
    if coalesce((select banned_until from auth.users where id = a), now()) <= now() + interval '50 years' then raise exception 'OLCU: engel konmadi'; end if;
    if exists (select 1 from auth.sessions where user_id = a) then raise exception 'OLCU: oturum silinmedi'; end if;
    if not exists (select 1 from public.uye_islem_kutugu where user_id = a and islem = 'iptal' and engel and paket_kapanan = 1) then raise exception 'OLCU: kutuk yazilmadi'; end if;
    if not exists (select 1 from jsonb_array_elements(public.yonetim_engelliler()) e where e->>'eposta' = 'olcu-iptal-a@tetikte.invalid' and e->>'neden' = 'iade istedi')
      then raise exception 'OLCU: engelli listesinde yok'; end if;
    n := n + 7;

    -- 4) engel kaldır: giriş açılır, paket KAPALI kalır, listeden düşer
    r := public.yonetim_uye_engel_kaldir('olcu-iptal-a@tetikte.invalid', 'yanlislik');
    if (select banned_until from auth.users where id = a) is not null then raise exception 'OLCU: engel kalkmadi'; end if;
    if (select bitis from public.paket_uyeler where user_id = a) >= current_date then raise exception 'OLCU: engel kaldirma paketi acti'; end if;
    if exists (select 1 from jsonb_array_elements(public.yonetim_engelliler()) e where e->>'eposta' = 'olcu-iptal-a@tetikte.invalid') then raise exception 'OLCU: listeden dusmedi'; end if;
    n := n + 3;

    -- 5) engelsiz iptal: yalnız paket (ikinci çağrıda kapanacak paket yok → 0), giriş açık kalır
    r := public.yonetim_uyelik_iptal('olcu-iptal-a@tetikte.invalid', 'yalniz paket', false, false);
    if (r->>'paket_kapanan')::int <> 0 or (select banned_until from auth.users where id = a) is not null then raise exception 'OLCU: engelsiz iptal yanlis %', r; end if;
    n := n + 1;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-iptal-%@tetikte.invalid')
     or exists (select 1 from public.siparisler where siparis_no = 'TT-20261030-U301')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000e1a01') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'UYELIK IPTAL OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
