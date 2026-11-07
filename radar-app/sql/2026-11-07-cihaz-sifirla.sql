-- ============================================================================
--  YÖNETİM: ÜYE KARTINDA CİHAZLAR + "CİHAZLARI SIFIRLA"  ·  07.11.2026
--
--  OLAY: 07.11'de paketli bir üye 3 kayıtlı cihazı doluyken 4. cihazdan girmek istedi, 30 günde 2 olan çıkarma
--  hakkını da bitirmişti. Perdeyi kendisi geçemiyordu; hak 02.12'de açılacaktı, SGS sınavı 21.11. Tek yol servis
--  anahtarıyla kasadan satır silmekti. Ölçüm (son 30 gün): 11 üye sınıra takıldı, 6'sının çıkarma hakkı bitti.
--  Cem 07.11: "Evet, ekle".
--
--  NE YAPAR (yalnız yönetici, security definer, anon EXECUTE yok):
--    yonetim_uye_cihazlar(eposta)        → kayıtlı cihazlar, kalan çıkarma hakkı, son 7 gün sınır sayısı (yalnız okur)
--    yonetim_cihaz_sifirla(eposta, neden)→ üyenin uye_cihazlar + uye_ekran satırları silinir, işlem kütüğe yazılır
--    yonetim_islem_kaydi                 → yeni işlem türü doğru adla görünür (eski CASE "else" ile "Giriş engeli kaldırıldı" yazardı)
--
--  BİLEREK: uye_cihaz_olay'a 'cikarildi' YAZILMAZ; panelden sıfırlama üyenin aylık çıkarma hakkını yemez.
--           Sıfırlama sonrası üyenin açtığı cihazlar cihaz_kontrol ile kendiliğinden yeniden kaydolur.
--  🚫 GÖRMEZ: sıfırlanan hesabın gerçekten tek kişide olup olmadığı (cihaz kimliği tarayıcı hafızasıdır, kişi değil) ·
--     açık sekmeyi kapatmaz (o cihaz bir sonraki yoklamada yeniden kaydolur) · üyenin aynı nedenle yine sınıra takılması.
--  Push ile otomatik (sql-uygula.yml), tek işlemde: öz-sınav düşerse göç hiç uygulanmaz.
--  GERİ ALMA: drop function public.yonetim_uye_cihazlar(text), public.yonetim_cihaz_sifirla(text,text);
--             2026-10-30-uye-ayrinti.sql içindeki yonetim_islem_kaydi tanımı yeniden basılır; check kısıtı eski listeye döner
--             (önce islem='cihaz_sifirla' satırları kaldırılmalı). Silinen cihaz satırları geri gelmez, üye yeniden kaydolur.
-- ============================================================================

alter table public.uye_islem_kutugu drop constraint if exists uye_islem_kutugu_islem_check;
alter table public.uye_islem_kutugu add constraint uye_islem_kutugu_islem_check
  check (islem in ('iptal', 'engel_kaldir', 'cihaz_sifirla'));

create or replace function public.yonetim_uye_cihazlar(p_eposta text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare v_ep text := lower(trim(coalesce(p_eposta, ''))); v_uid uuid; v_cikan int; v_ilk timestamptz;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id into v_uid from auth.users where lower(email) = v_ep limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  select count(*), min(zaman) into v_cikan, v_ilk from public.uye_cihaz_olay
   where user_id = v_uid and olay = 'cikarildi' and zaman > now() - interval '30 days';
  return jsonb_build_object(
    'sinir', 3,
    'cikarma_hakki', greatest(0, 2 - v_cikan),
    'hak_acilis', case when v_cikan >= 2 then v_ilk + interval '30 days' end,
    'sinir_7g', (select count(*) from public.uye_cihaz_olay
                  where user_id = v_uid and olay = 'sinir' and zaman > now() - interval '7 days'),
    'son_sinir', (select max(zaman) from public.uye_cihaz_olay where user_id = v_uid and olay = 'sinir'),
    'cihazlar', coalesce((select jsonb_agg(jsonb_build_object('etiket', c.etiket, 'ilk_gorulme', c.ilk_gorulme,
                    'son_gorulme', c.son_gorulme) order by c.son_gorulme desc)
                  from public.uye_cihazlar c where c.user_id = v_uid), '[]'::jsonb));
end $$;
revoke all on function public.yonetim_uye_cihazlar(text) from public, anon;
grant execute on function public.yonetim_uye_cihazlar(text) to authenticated;

create or replace function public.yonetim_cihaz_sifirla(p_eposta text, p_neden text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_ep text := lower(trim(coalesce(p_eposta, ''))); v_uid uuid; v_silinen int := 0;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if length(trim(coalesce(p_neden, ''))) < 3 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = v_ep limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  delete from public.uye_cihazlar where user_id = v_uid;
  get diagnostics v_silinen = row_count;
  delete from public.uye_ekran where user_id = v_uid;
  if v_silinen = 0 then raise exception 'CIHAZ_YOK'; end if;
  insert into public.uye_islem_kutugu (user_id, eposta, islem, neden, yapan)
  values (v_uid, v_ep, 'cihaz_sifirla', left(trim(p_neden), 280) || ' · ' || v_silinen || ' cihaz', auth.uid());
  return jsonb_build_object('eposta', v_ep, 'silinen', v_silinen);
end $$;
revoke all on function public.yonetim_cihaz_sifirla(text, text) from public, anon;
grant execute on function public.yonetim_cihaz_sifirla(text, text) to authenticated;

create or replace function public.yonetim_islem_kaydi(p_gun int default 30)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare v_bas timestamptz := now() - make_interval(days => least(greatest(coalesce(p_gun, 30), 1), 365));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(e order by z desc) from (
    select x.zaman z, jsonb_build_object('zaman', x.zaman, 'tur', case x.islem when 'iptal' then 'Üyelik iptal' when 'cihaz_sifirla' then 'Cihazlar sıfırlandı' else 'Giriş engeli kaldırıldı' end,
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
  y constant uuid := '00000000-0000-4000-8000-0000000e1b01';
  a constant uuid := '00000000-0000-4000-8000-0000000e1b0a';
  b constant uuid := '00000000-0000-4000-8000-0000000e1b0b';
  r jsonb; n int := 0;
begin
  begin
    insert into public.yoneticiler (user_id) values (y) on conflict do nothing;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-cihaz-a@tetikte.invalid', now(), now()),
      (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-cihaz-b@tetikte.invalid', now(), now()),
      (y, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-cihaz-y@tetikte.invalid', now(), now());
    insert into public.uye_cihazlar (user_id, cihaz_id, etiket) values
      (a, 'olcu-cihaz-1', 'Windows · Chrome'), (a, 'olcu-cihaz-2', 'iPhone · Safari'), (a, 'olcu-cihaz-3', 'Android · Chrome'),
      (b, 'olcu-cihaz-b1', 'Windows · Chrome');
    insert into public.uye_ekran (user_id, cihaz_id) values (a, 'olcu-cihaz-1'), (b, 'olcu-cihaz-b1');
    insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values
      (a, 'olcu-eski-1', 'cikarildi'), (a, 'olcu-eski-2', 'cikarildi'), (a, 'olcu-cihaz-4', 'sinir');

    -- 1) yönetici olmayan ne okur ne sıfırlar, satırlar yerinde kalır
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    begin perform public.yonetim_uye_cihazlar('olcu-cihaz-a@tetikte.invalid'); raise exception 'OLCU: yonetici olmayan cihaz okudu';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    begin perform public.yonetim_cihaz_sifirla('olcu-cihaz-a@tetikte.invalid', 'deneme'); raise exception 'OLCU: yonetici olmayan sifirladi';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    if (select count(*) from public.uye_cihazlar where user_id = a) <> 3 then raise exception 'OLCU: yetkisiz cagri satir sildi'; end if;
    n := n + 3;

    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);

    -- 2) neden zorunlu · hesap yok
    begin perform public.yonetim_cihaz_sifirla('olcu-cihaz-a@tetikte.invalid', ' '); raise exception 'OLCU: nedensiz kabul';
    exception when others then if sqlerrm not like '%NEDEN_GEREKLI%' then raise; end if; end;
    begin perform public.yonetim_cihaz_sifirla('olcu-cihaz-yok@tetikte.invalid', 'deneme'); raise exception 'OLCU: hesapsiz kabul';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    begin perform public.yonetim_uye_cihazlar('olcu-cihaz-yok@tetikte.invalid'); raise exception 'OLCU: hesapsiz okuma';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    n := n + 3;

    -- 3) okuma: 3 cihaz, hak 0, açılış tarihi var, sınır sayısı 1, en yeni başta (büyük harf/boşluk farkı)
    r := public.yonetim_uye_cihazlar('  OLCU-CIHAZ-A@tetikte.invalid ');
    if jsonb_array_length(r->'cihazlar') <> 3 then raise exception 'OLCU: cihaz sayisi yanlis %', r; end if;
    if (r->>'cikarma_hakki')::int <> 0 or r->>'hak_acilis' is null then raise exception 'OLCU: hak yanlis %', r; end if;
    if (r->>'sinir_7g')::int <> 1 or r->>'son_sinir' is null then raise exception 'OLCU: sinir sayisi yanlis %', r; end if;
    n := n + 3;

    -- 4) sıfırla: yalnız bu üye, ekran da silinir, kütük yazılır, çıkarma hakkı yenmez, olay geçmişi durur
    r := public.yonetim_cihaz_sifirla('olcu-cihaz-a@tetikte.invalid', 'uye giremiyor');
    if (r->>'silinen')::int <> 3 then raise exception 'OLCU: silinen yanlis %', r; end if;
    if exists (select 1 from public.uye_cihazlar where user_id = a) then raise exception 'OLCU: cihaz kaldi'; end if;
    if exists (select 1 from public.uye_ekran where user_id = a) then raise exception 'OLCU: ekran kaldi'; end if;
    if (select count(*) from public.uye_cihazlar where user_id = b) <> 1 or not exists (select 1 from public.uye_ekran where user_id = b)
      then raise exception 'OLCU: baska uyenin cihazi silindi'; end if;
    if not exists (select 1 from public.uye_islem_kutugu where user_id = a and islem = 'cihaz_sifirla' and yapan = y and neden like 'uye giremiyor%3 cihaz')
      then raise exception 'OLCU: kutuk yazilmadi'; end if;
    if (select count(*) from public.uye_cihaz_olay where user_id = a and olay = 'cikarildi') <> 2 then raise exception 'OLCU: cikarma sayisi degisti'; end if;
    if (select count(*) from public.uye_cihaz_olay where user_id = a and olay = 'sinir') <> 1 then raise exception 'OLCU: olay gecmisi silindi'; end if;
    n := n + 6;

    -- 5) ikinci sıfırlama CIHAZ_YOK der, kütüğe ikinci satır düşmez
    begin perform public.yonetim_cihaz_sifirla('olcu-cihaz-a@tetikte.invalid', 'deneme'); raise exception 'OLCU: bos sifirlama kabul';
    exception when others then if sqlerrm not like '%CIHAZ_YOK%' then raise; end if; end;
    if (select count(*) from public.uye_islem_kutugu where user_id = a) <> 1 then raise exception 'OLCU: bos sifirlama kutuge yazdi'; end if;
    n := n + 2;

    -- 6) işlem kaydı doğru adla gösterir (eski CASE "Giriş engeli kaldırıldı" yazıyordu)
    if not exists (select 1 from jsonb_array_elements(public.yonetim_islem_kaydi(1)) e
                    where e->>'eposta' = 'olcu-cihaz-a@tetikte.invalid' and e->>'tur' = 'Cihazlar sıfırlandı')
      then raise exception 'OLCU: islem kaydinda yanlis ad'; end if;
    n := n + 1;

    -- 7) sıfırlanan üye cihaz_kontrol'den yeniden kaydolur, ekranı alır (perde kalkar)
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    r := public.cihaz_kontrol('olcu-cihaz-4', 'Windows · Chrome', true);
    if r->>'durum' <> 'tamam' then raise exception 'OLCU: yeni cihaz acilmadi %', r; end if;
    if not exists (select 1 from public.uye_cihazlar where user_id = a and cihaz_id = 'olcu-cihaz-4') then raise exception 'OLCU: yeni cihaz kaydolmadi'; end if;
    n := n + 2;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-cihaz-%@tetikte.invalid')
     or exists (select 1 from public.uye_cihazlar where cihaz_id like 'olcu-cihaz-%')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000e1b01') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'CIHAZ SIFIRLA OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
