-- ============================================================================
--  YÖNETİM: ÜYE AYRINTISI + KULLANIM + İŞLEM KAYDI  ·  30.10.2026
--
--  Cem 30.10: "2 ve 3 yap · öğrenciler kullanıyor mu siteyi, kim nerede soru çözüyor, çözüyor mu".
--  (2 = üye satırında sipariş/hediye geçmişi, 3 = panelde yapılan işlemlerin kaydı.)
--
--  NE YAPAR (hepsi yalnız yönetici, security definer, salt OKUR, anon EXECUTE yok):
--    yonetim_kullanim()            → üye başına çözülen soru (toplam / son 7 gün / doğru / son çözüm / en çok ders),
--                                     set-deneme-seviye sonucu sayısı; son 30 gün günlük seri; ders (sayfa) dağılımı;
--                                     özet (son 24 sa / 7 gün / 30 gün çözen kişi, paketi açık ama hiç çözmeyen).
--    yonetim_uye_ayrinti(eposta)   → tek üyenin kartı: hesap, paket, siparişler (e-posta ya da hesaba bağlı),
--                                     hediyeler, ders ders çözüm, son 30 gün, set/deneme sonuçları, Son 20 Gün, işlemler.
--    yonetim_islem_kaydi(gun)      → panel/ödeme olayları tek akışta: üyelik iptali/engel, hediye ver/kapat,
--                                     sipariş ödendi/iptal/hesaba bağlandı, özel kod, elçi kodu.
--
--  🚫 GÖRMEZ: üye olmadan ya da paketsiz çözülen sorular (cevap_kayit kişiye bağlı değil; yalnız toplam sayı verilir) ·
--     11.10.2026'dan ÖNCE paketli üyenin çözdüğü sorular (kasa_cevap o gün başladı) · sipariş "iade" zamanı (kolon yok;
--     30.10 sonrası iadeler uye_islem_kutugu'nda) · havale onayını hangi yöneticinin bastığı (kolon yok).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop function public.yonetim_kullanim(), public.yonetim_uye_ayrinti(text), public.yonetim_islem_kaydi(int);
-- ============================================================================

create or replace function public.yonetim_kullanim()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare v jsonb;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  with c as (
    select k.user_id, k.sayfa, k.dogru, k.zaman from public.kasa_cevap k
  ), u as (
    select c.user_id, count(*) n, count(*) filter (where c.zaman > now() - interval '7 days') n7,
           count(*) filter (where c.dogru) d, max(c.zaman) son, min(c.zaman) ilk
      from c group by c.user_id
  ), ud as (
    select distinct on (user_id) user_id, sayfa from (select user_id, sayfa, count(*) n from c group by 1, 2) x
     order by user_id, n desc
  ), os as (
    select user_id, count(*) filter (where tur = 'set') sets, count(*) filter (where tur = 'deneme') deneme,
           count(*) filter (where tur = 'seviye') seviye, max(olusturma) son
      from public.ogrenci_sonuc group by user_id
  )
  select jsonb_build_object(
    'olcum', now(),
    'uye', coalesce((
      select jsonb_agg(jsonb_build_object('eposta', lower(au.email), 'cevap', coalesce(u.n, 0), 'cevap7', coalesce(u.n7, 0),
               'dogru', coalesce(u.d, 0), 'son', greatest(u.son, os.son), 'ilk', u.ilk, 'ders', ud.sayfa,
               'set', coalesce(os.sets, 0), 'deneme', coalesce(os.deneme, 0), 'seviye', coalesce(os.seviye, 0)))
        from auth.users au
        left join u on u.user_id = au.id left join ud on ud.user_id = au.id left join os on os.user_id = au.id
       where u.user_id is not null or os.user_id is not null), '[]'::jsonb),
    'gunluk', coalesce((
      select jsonb_agg(jsonb_build_object('gun', g.gun::date, 'cevap', coalesce(x.n, 0), 'kisi', coalesce(x.k, 0)) order by g.gun)
        from generate_series((now() at time zone 'Europe/Istanbul')::date - 29, (now() at time zone 'Europe/Istanbul')::date, interval '1 day') g(gun)
        left join (select (zaman at time zone 'Europe/Istanbul')::date gun, count(*) n, count(distinct user_id) k
                     from c where zaman > now() - interval '31 days' group by 1) x on x.gun = g.gun::date), '[]'::jsonb),
    'ders', coalesce((
      select jsonb_agg(jsonb_build_object('sayfa', sayfa, 'cevap', n, 'cevap7', n7, 'kisi', k, 'kisi7', k7, 'dogru', d) order by n7 desc, n desc)
        from (select sayfa, count(*) n, count(*) filter (where zaman > now() - interval '7 days') n7,
                     count(distinct user_id) k, count(distinct user_id) filter (where zaman > now() - interval '7 days') k7,
                     count(*) filter (where dogru) d
                from c group by sayfa) y), '[]'::jsonb),
    'ozet', jsonb_build_object(
      'kisi24', (select count(distinct user_id) from c where zaman > now() - interval '24 hours'),
      'kisi7',  (select count(distinct user_id) from c where zaman > now() - interval '7 days'),
      'kisi30', (select count(distinct user_id) from c where zaman > now() - interval '30 days'),
      'cevap7', (select count(*) from c where zaman > now() - interval '7 days'),
      'paketli', (select count(*) from public.paket_uyeler where bitis >= current_date),
      'paketli_hic', (select count(*) from public.paket_uyeler p where p.bitis >= current_date
                        and not exists (select 1 from c where c.user_id = p.user_id)),
      'paketli_7g_yok', (select count(*) from public.paket_uyeler p where p.bitis >= current_date
                        and not exists (select 1 from c where c.user_id = p.user_id and c.zaman > now() - interval '7 days')),
      'anonim7', (select count(*) from public.cevap_kayit where olusturma > now() - interval '7 days'),
      'anonim_oturum7', (select count(distinct oturum) from public.cevap_kayit where olusturma > now() - interval '7 days'),
      'kayit_baslangic', (select min(zaman) from c))
  ) into v;
  return v;
end $$;
revoke all on function public.yonetim_kullanim() from public, anon;
grant execute on function public.yonetim_kullanim() to authenticated;

create or replace function public.yonetim_uye_ayrinti(p_eposta text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare v_ep text := lower(trim(coalesce(p_eposta, ''))); au auth.users%rowtype; v jsonb;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into au from auth.users where lower(email) = v_ep limit 1;
  if au.id is null then raise exception 'HESAP_YOK'; end if;
  select jsonb_build_object(
    'hesap', jsonb_build_object('eposta', lower(au.email), 'kayit', au.created_at, 'son_giris', au.last_sign_in_at,
       'onayli', au.email_confirmed_at is not null, 'saglayici', au.raw_app_meta_data->'providers',
       'engel_bitis', case when au.banned_until > now() then au.banned_until end,
       'kaynak', au.raw_user_meta_data->>'kaynak', 'elci', nullif(au.raw_user_meta_data->>'elci_kodu', ''),
       'yonetici', exists (select 1 from public.yoneticiler y where y.user_id = au.id)),
    'paket', (select jsonb_build_object('paket', p.paket, 'bitis', p.bitis, 'dersler', p.dersler, 'eklenme', p.eklenme)
                from public.paket_uyeler p where p.user_id = au.id),
    'siparisler', coalesce((select jsonb_agg(jsonb_build_object('no', s.siparis_no, 'paket', s.paket, 'tutar', s.tutar,
                    'durum', s.durum, 'odeme', s.odeme, 'ad', s.ad_soyad, 'eposta', s.email, 'tarih', s.olusturma,
                    'odendi', s.odendi_tarihi, 'iptal_neden', s.iptal_neden, 'elci', s.elci_kodu, 'ozel_kod', s.ozel_kod,
                    'bagli', s.bagli_kullanici = au.id) order by s.olusturma desc)
                  from public.siparisler s where lower(s.email) = v_ep or s.bagli_kullanici = au.id), '[]'::jsonb),
    'hediyeler', coalesce((select jsonb_agg(jsonb_build_object('paket', h.paket, 'dersler', h.dersler, 'bitis', h.bitis,
                    'neden', h.neden, 'veren', h.veren, 'elci', h.elci_kodu, 'tarih', h.tarih, 'iptal', h.iptal) order by h.tarih desc)
                  from public.paket_hediye h where h.user_id = au.id), '[]'::jsonb),
    'cevap', (select jsonb_build_object('toplam', count(*), 'dogru', count(*) filter (where k.dogru),
                    'cevap7', count(*) filter (where k.zaman > now() - interval '7 days'), 'ilk', min(k.zaman), 'son', max(k.zaman))
                from public.kasa_cevap k where k.user_id = au.id),
    'dersler', coalesce((select jsonb_agg(jsonb_build_object('sayfa', sayfa, 'cevap', n, 'dogru', d, 'son', son) order by son desc)
                  from (select sayfa, count(*) n, count(*) filter (where dogru) d, max(zaman) son
                          from public.kasa_cevap where user_id = au.id group by sayfa) x), '[]'::jsonb),
    'gunluk', coalesce((select jsonb_agg(jsonb_build_object('gun', gun, 'cevap', n) order by gun)
                  from (select (zaman at time zone 'Europe/Istanbul')::date gun, count(*) n from public.kasa_cevap
                         where user_id = au.id and zaman > now() - interval '30 days' group by 1) x), '[]'::jsonb),
    'sonuclar', coalesce((select jsonb_agg(jsonb_build_object('tur', o.tur, 'sinav', o.sinav, 'anahtar', o.anahtar, 'tarih', o.olusturma) order by o.olusturma desc)
                  from (select * from public.ogrenci_sonuc where user_id = au.id order by olusturma desc limit 40) o), '[]'::jsonb),
    's20', coalesce((select jsonb_agg(jsonb_build_object('deneme', s.deneme, 'ders', s.ders, 'dogru', s.dogru, 'yanlis', s.yanlis,
                    'bos', s.bos, 'toplam', s.toplam, 'zaman', s.zaman) order by s.zaman desc)
                  from public.s20_sonuc s where s.user_id = au.id), '[]'::jsonb),
    'islemler', coalesce((select jsonb_agg(jsonb_build_object('islem', x.islem, 'neden', x.neden, 'engel', x.engel,
                    'paket_kapanan', x.paket_kapanan, 'iade', x.iade_siparis, 'zaman', x.zaman,
                    'yapan', (select lower(email) from auth.users where id = x.yapan)) order by x.zaman desc)
                  from public.uye_islem_kutugu x where x.user_id = au.id), '[]'::jsonb)
  ) into v;
  return v;
end $$;
revoke all on function public.yonetim_uye_ayrinti(text) from public, anon;
grant execute on function public.yonetim_uye_ayrinti(text) to authenticated;

create or replace function public.yonetim_islem_kaydi(p_gun int default 30)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare v_bas timestamptz := now() - make_interval(days => least(greatest(coalesce(p_gun, 30), 1), 365));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(e order by z desc) from (
    select x.zaman z, jsonb_build_object('zaman', x.zaman, 'tur', case x.islem when 'iptal' then 'Üyelik iptal' else 'Giriş engeli kaldırıldı' end,
             'eposta', x.eposta, 'ayrinti', concat_ws(' · ', nullif(x.neden, ''), case when x.engel then 'girişi engellendi' end,
               case when x.paket_kapanan > 0 then x.paket_kapanan || ' paket kapandı' end,
               case when coalesce(array_length(x.iade_siparis, 1), 0) > 0 then array_to_string(x.iade_siparis, ', ') || ' iade' end),
             'yapan', (select lower(email) from auth.users where id = x.yapan))
      from public.uye_islem_kutugu x where x.zaman > v_bas
    union all
    select h.tarih z, jsonb_build_object('zaman', h.tarih, 'tur', 'Hediye paket verildi', 'eposta', h.eposta,
             'ayrinti', concat_ws(' · ', h.paket || coalesce(' (' || array_to_string(h.dersler, ', ') || ')', ''),
               to_char(h.bitis, 'DD.MM.YYYY') || '''e kadar', nullif(h.neden, ''), 'elçi ' || h.elci_kodu), 'yapan', h.veren)
      from public.paket_hediye h where h.tarih > v_bas
    union all
    select h.iptal z, jsonb_build_object('zaman', h.iptal, 'tur', 'Hediye paket kapatıldı', 'eposta', h.eposta, 'ayrinti', h.paket, 'yapan', h.veren)
      from public.paket_hediye h where h.iptal > v_bas
    union all
    select s.odendi_tarihi z, jsonb_build_object('zaman', s.odendi_tarihi, 'tur', 'Sipariş ödendi', 'eposta', s.email,
             'ayrinti', concat_ws(' · ', s.siparis_no, s.paket, s.tutar || ' TL',
               case s.odeme when 'kart' then 'kart (iyzico, otomatik)' when 'havale' then 'havale (panelden onay)' else s.odeme end,
               s.ad_soyad, case when s.durum = 'iade' then 'SONRADAN İADE' end), 'yapan', null)
      from public.siparisler s where s.odendi_tarihi > v_bas
    union all
    select s.iptal_zaman z, jsonb_build_object('zaman', s.iptal_zaman, 'tur', 'Sipariş iptal', 'eposta', s.email,
             'ayrinti', concat_ws(' · ', s.siparis_no, s.paket, s.tutar || ' TL',
               case when s.iptal_neden = 'otomatik' then 'otomatik (ödeme gelmedi)' else s.iptal_neden end), 'yapan', null)
      from public.siparisler s where s.iptal_zaman > v_bas
    union all
    select s.bagli_tarih z, jsonb_build_object('zaman', s.bagli_tarih, 'tur', 'Sipariş hesaba bağlandı', 'eposta', s.email,
             'ayrinti', concat_ws(' · ', s.siparis_no, '→ ' || (select lower(email) from auth.users where id = s.bagli_kullanici), nullif(s.bagli_yol, '')), 'yapan', null)
      from public.siparisler s where s.bagli_tarih > v_bas
    union all
    select o.olusturma z, jsonb_build_object('zaman', o.olusturma, 'tur', 'Özel indirim kodu üretildi', 'eposta', null,
             'ayrinti', concat_ws(' · ', o.kod, o.kime, coalesce(o.aciklama, o.indirim_tl || ' TL'), 'son gün ' || to_char(o.son, 'DD.MM.YYYY')),
             'yapan', (select lower(email) from auth.users where id = o.olusturan))
      from public.ozel_kod o where o.olusturma > v_bas
    union all
    select o.iptal z, jsonb_build_object('zaman', o.iptal, 'tur', 'Özel indirim kodu iptal', 'eposta', null, 'ayrinti', concat_ws(' · ', o.kod, o.kime), 'yapan', null)
      from public.ozel_kod o where o.iptal > v_bas
    union all
    select e.olusturma z, jsonb_build_object('zaman', e.olusturma, 'tur', 'Elçi kodu oluşturuldu', 'eposta', null, 'ayrinti', concat_ws(' · ', e.kod, e.ad_soyad), 'yapan', null)
      from public.elciler e where e.olusturma > v_bas
    order by 1 desc limit 400
  ) t(z, e)), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_islem_kaydi(int) from public, anon;
grant execute on function public.yonetim_islem_kaydi(int) to authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (geri alınır)
do $$
declare
  y constant uuid := '00000000-0000-4000-8000-0000000e2a01';
  a constant uuid := '00000000-0000-4000-8000-0000000e2a0a';
  r jsonb; n int := 0;
begin
  begin
    insert into public.yoneticiler (user_id) values (y) on conflict do nothing;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-ayrinti-a@tetikte.invalid', now(), now()),
      (y, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-ayrinti-y@tetikte.invalid', now(), now());
    insert into public.kasa_cevap (user_id, sayfa, soru_id, secim, dogru, zaman) values
      (a, 'kaydir/sgs/olcu-ders.html', 'olcu/kp-01', 'A', true,  now()),
      (a, 'kaydir/sgs/olcu-ders.html', 'olcu/kp-02', 'B', false, now()),
      (a, 'kaydir/smmm/olcu-ders.html', 'olcu/kp-03', 'C', true, now() - interval '10 days');
    insert into public.uye_islem_kutugu (user_id, eposta, islem, neden, engel, yapan) values (a, 'olcu-ayrinti-a@tetikte.invalid', 'iptal', 'olcu neden', true, y);

    -- 1) yönetici olmayan üçünü de çağıramaz
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    begin perform public.yonetim_kullanim(); raise exception 'OLCU: kullanim acik';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    begin perform public.yonetim_uye_ayrinti('olcu-ayrinti-a@tetikte.invalid'); raise exception 'OLCU: ayrinti acik';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    begin perform public.yonetim_islem_kaydi(30); raise exception 'OLCU: islem kaydi acik';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    n := n + 3;

    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);

    -- 2) kullanım: üye satırı 3 cevap / 7 günde 2 / doğru 2; ders listesinde ölçü sayfası; özet sayılar dolu
    r := public.yonetim_kullanim();
    if not exists (select 1 from jsonb_array_elements(r->'uye') e where e->>'eposta' = 'olcu-ayrinti-a@tetikte.invalid'
                     and (e->>'cevap')::int = 3 and (e->>'cevap7')::int = 2 and (e->>'dogru')::int = 2 and e->>'ders' = 'kaydir/sgs/olcu-ders.html')
      then raise exception 'OLCU: kullanim uye satiri yanlis %', r->'uye'; end if;
    if not exists (select 1 from jsonb_array_elements(r->'ders') e where e->>'sayfa' = 'kaydir/sgs/olcu-ders.html' and (e->>'cevap')::int = 2 and (e->>'kisi')::int = 1)
      then raise exception 'OLCU: ders dagilimi yanlis'; end if;
    if jsonb_array_length(r->'gunluk') <> 30 then raise exception 'OLCU: gunluk 30 gun degil (%)', jsonb_array_length(r->'gunluk'); end if;
    if (r->'ozet'->>'kisi24')::int < 1 then raise exception 'OLCU: ozet kisi24 saymadi'; end if;
    n := n + 4;

    -- 3) ayrıntı: hesap yok · cevap/ders/işlem dolu, engel yok (banned_until boş)
    begin perform public.yonetim_uye_ayrinti('olcu-ayrinti-yok@tetikte.invalid'); raise exception 'OLCU: hesapsiz kabul';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    r := public.yonetim_uye_ayrinti(' OLCU-AYRINTI-A@tetikte.invalid ');
    if (r->'cevap'->>'toplam')::int <> 3 or jsonb_array_length(r->'dersler') <> 2 or jsonb_array_length(r->'islemler') <> 1
       or r->'islemler'->0->>'yapan' <> 'olcu-ayrinti-y@tetikte.invalid' or r->'hesap'->>'engel_bitis' is not null
      then raise exception 'OLCU: ayrinti yanlis %', r; end if;
    n := n + 2;

    -- 4) işlem kaydı: kütükteki iptal akışta, süzgeç dışı (gün=1) da çalışır
    r := public.yonetim_islem_kaydi(30);
    if not exists (select 1 from jsonb_array_elements(r) e where e->>'tur' = 'Üyelik iptal' and e->>'eposta' = 'olcu-ayrinti-a@tetikte.invalid'
                     and e->>'ayrinti' like 'olcu neden%girişi engellendi%' and e->>'yapan' = 'olcu-ayrinti-y@tetikte.invalid')
      then raise exception 'OLCU: islem kaydinda iptal yok'; end if;
    if jsonb_typeof(public.yonetim_islem_kaydi(1)) <> 'array' or jsonb_typeof(public.yonetim_islem_kaydi(null)) <> 'array' then raise exception 'OLCU: gun suzgeci'; end if;
    n := n + 2;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-ayrinti-%@tetikte.invalid')
     or exists (select 1 from public.kasa_cevap where soru_id like 'olcu/kp-%')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000e2a01') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'UYE AYRINTI OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
