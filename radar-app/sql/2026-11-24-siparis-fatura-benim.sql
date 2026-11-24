-- ============================================================================
--  SON SİPARİŞİN FATURA BİLGİSİ (24.11.2026, site kolu; Cem "alımı çok kolay olsun", denetim: telefon + adres
--  her alımda elle ve zorunlu, geri gelen üyede dolmuyor)
--
--  NE YAPAR: siparis_fatura_benim() girişli üyeye KENDİ son siparişindeki telefon, fatura adresi ve fatura tipini
--  (kurumsalsa unvan / VKN / vergi dairesi) döner; satin-al.html boş alanları bununla doldurur. Cihaza hiçbir şey
--  yazılmaz (satin-al.html "ad, adres, telefon cihaza yazılmaz" kararı aynen).
--
--  HANGİ SİPARİŞ "KENDİ" SAYILIR:
--    a) bu hesaba bağlanmış sipariş (bagli_kullanici = üye), ya da
--    b) hesabın e-postasıyla, HESAP AÇILDIKTAN SONRA verilmiş sipariş.
--  (b)'deki tarih şartı bilerek var: e-posta doğrulaması kapalı; biri başkasının e-postasıyla sonradan hesap açarsa
--  o e-postayla ESKİDEN verilmiş siparişin telefon/adresini okuyamaz.
--  T.C. kimlik no DÖNMEZ (isteğe bağlı alan; her seferinde üye kendisi yazar).
--
--  🚫 GÖRMEZ: hesabı açıldıktan sonra o e-postayı siparişe BAŞKASI yazdıysa (01.11'den beri sipariş girişle veriliyor,
--     e-posta alanı kilitli; önceki dönemin siparişi için ölçülmedi) · üyenin sonradan değişen adresi (en yeni sipariş
--     ne diyorsa o) · adresi boş siparişler (atlanır).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır). Mutasyon sınaması YAPILMADI.
-- ============================================================================
create or replace function public.siparis_fatura_benim()
 returns table (telefon text, adres text, fatura_tip text, unvan text, vkn text, vd text)
 language sql
 stable
 security definer
 set search_path to 'public', 'auth'
as $function$
  select s.telefon::text, s.adres::text,
         coalesce(s.fatura ->> 'tip', 'bireysel'),
         s.fatura ->> 'unvan', s.fatura ->> 'vkn', s.fatura ->> 'vd'
    from public.siparisler s
    join auth.users u on u.id = auth.uid()
   where (s.bagli_kullanici = u.id
          or (lower(s.email) = lower(btrim(u.email)) and s.olusturma >= u.created_at))
     and coalesce(btrim(s.adres), '') <> ''
   order by s.olusturma desc
   limit 1
$function$;
revoke execute on function public.siparis_fatura_benim() from public, anon, authenticated;
grant execute on function public.siparis_fatura_benim() to authenticated;

-- ÖZ-SINAV (alt işlemde, OLCU_TAMAM ile GERİ ALINIR):
--   a) sahibi telefon + adres + tipi görür · b) başka üye görmez · c) girişsiz görmez ·
--   d) hesaptan ESKİ, bağlanmamış sipariş görünmez · e) aynı sipariş hesaba bağlanınca görünür
do $$
declare
  ua constant uuid := '00000000-0000-4000-8000-0000000f5b01';
  ub constant uuid := '00000000-0000-4000-8000-0000000f5b02';
  t text; a text; tip text; n int := 0;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x.ep, now(), now()
      from (values (ua, 'olcu-ftr-a@tetikte.invalid'), (ub, 'olcu-ftr-b@tetikte.invalid')) x(id, ep);
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, liste_fiyat, ad_soyad, email, telefon, adres, fatura, odeme, durum)
    values ('TT-20261124-F7A1', 'sgs-2027', 'SGS 2027 paketi', 3585.60, 8985.60, 'Olcu Fatura', 'OLCU-ftr-a@tetikte.invalid',
            '05550000000', 'Olcu Mah. Deneme Sok. No:1 Konak / Izmir', '{"tip":"bireysel","tckn":"11111111110"}'::jsonb,
            'havale', 'odeme_bekliyor');

    perform set_config('request.jwt.claims', json_build_object('sub', ua::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ua::text, true);
    select y.telefon, y.adres, y.fatura_tip into t, a, tip from public.siparis_fatura_benim() y;
    if t is distinct from '05550000000' or a not like 'Olcu Mah.%' or tip is distinct from 'bireysel' then raise exception 'OLCU: a % % %', t, a, tip; end if;
    n := n + 1;

    perform set_config('request.jwt.claims', json_build_object('sub', ub::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ub::text, true);
    t := null; select y.telefon into t from public.siparis_fatura_benim() y;
    if t is not null then raise exception 'OLCU: b %', t; end if;
    n := n + 1;

    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    t := null; select y.telefon into t from public.siparis_fatura_benim() y;
    if t is not null then raise exception 'OLCU: c %', t; end if;
    n := n + 1;

    perform set_config('request.jwt.claims', json_build_object('sub', ua::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', ua::text, true);
    update public.siparisler set olusturma = now() - interval '1 day' where siparis_no = 'TT-20261124-F7A1';
    t := null; select y.telefon into t from public.siparis_fatura_benim() y;
    if t is not null then raise exception 'OLCU: d %', t; end if;
    n := n + 1;

    update public.siparisler set bagli_kullanici = ua where siparis_no = 'TT-20261124-F7A1';
    t := null; select y.telefon into t from public.siparis_fatura_benim() y;
    if t is distinct from '05550000000' then raise exception 'OLCU: e %', t; end if;
    n := n + 1;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261124-F7A%')
     or exists (select 1 from auth.users where email like 'olcu-ftr-%@tetikte.invalid') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'SIPARIS FATURA BENIM OZ-SINAV: % vaka TAMAM', n;
end $$;
