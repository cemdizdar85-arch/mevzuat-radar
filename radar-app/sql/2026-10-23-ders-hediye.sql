-- ============================================================================
--  DERS DERS HEDİYE — Yeterlilik'te tek tek ders hediye etmek  ·  23.10.2026
--
--  KARAR (Cem 23.10): "bizde tek tek hediye vermek istiyoruz ... tüm derslerde nasıl hediye veririz" → "sgs değil de
--  yeterlilikte verir misin". Panelin "Ücretsiz paket ver"i yalnız tam / sgs / yeterlilik-tum veriyordu.
--
--  TASARIM (satın almanın kullandığı yol, yeni erişim kuralı YOK):
--    - Seçilen dersler paket_uyeler.dersler'e yazılır; paket = 'yeterlilik-N' (N = toplam ders, 1-4). Toplam 5+ ders
--      olursa 'yeterlilik-tum' (5-7 derslik paket yok; tüm dersler aynı erişimi verir), dersler boş.
--    - EKLEYEREK: kişinin açık hediye/ders paketi varsa yeni dersler ÜSTÜNE EKLENİR (Vergi bugün + Hukuk yarın = ikisi).
--      Bitiş: eski ile yeni bitişin geç olanı.
--    - Parayla alınmış açık tek ders paketi varsa: dersler yine eklenir (yalnız ekler, hiçbir ders düşmez) ama p_zorla
--      ister, çünkü panelin "Kapat" düğmesi satırın tamamını kapatır → parayla alınan ders de kapanır. Panel bunu sorar.
--    - Açık 'tam' / 'yeterlilik-tum' varsa ZATEN_ACIK; açık 'sgs' ya da 'kgk-*' varsa BASKA_SINAV (üye başına tek satır:
--      SGS + tek ders aynı anda tutulamaz → "tam paket" ver).
--    - Kütük: paket_hediye'ye 'dersler' kolonu; satıra YALNIZ bu seferde hediye edilen dersler yazılır.
--    - Ders adları fiyat-motoru.js DERSLER.yeterlilik ile birebir (arac/ders-adi-kapisi.js bu dosyayı da okur).
--
--  🚫 GÖRMEZ: hediye sonrası kişi kendi parasıyla tek ders alırsa sipariş onayı (_siparis_isle) satırı EZER, hediye dersi
--     düşer (yalnız paket_hediye kütüğünde kalır) · KGK modül hediyesi (KGK sitesi kapalı, ayrı iş) · yönetici olmayanın
--     çağrısı göç içi sınanır, panelin kendisi sınanmaz.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop function public.yonetim_ders_hediye(text, text[], date, text, text, boolean);
--             paket_hediye.dersler kolonu ve genişleyen paket listesi kayıt olarak kalır.
-- ============================================================================

-- 1) KÜTÜK: ders kolonu + tek ders paketleri
alter table public.paket_hediye add column if not exists dersler text[];
do $$
declare c text;
begin
  for c in select conname from pg_constraint
            where conrelid = 'public.paket_hediye'::regclass and contype = 'c'
              and pg_get_constraintdef(oid) like '%paket%' and pg_get_constraintdef(oid) not like '%dersler%' loop
    execute format('alter table public.paket_hediye drop constraint %I', c);
  end loop;
  alter table public.paket_hediye add constraint paket_hediye_paket_gecerli
    check (paket in ('tam', 'sgs', 'yeterlilik-tum', 'yeterlilik-1', 'yeterlilik-2', 'yeterlilik-3', 'yeterlilik-4'));
  alter table public.paket_hediye drop constraint if exists paket_hediye_dersler_boy;
  alter table public.paket_hediye add constraint paket_hediye_dersler_boy
    check (dersler is null or (array_length(dersler, 1) between 1 and 8 and pg_column_size(dersler) <= 1000));
end $$;

-- 2) VER
create or replace function public.yonetim_ders_hediye(p_eposta text, p_dersler text[], p_bitis date, p_neden text,
                                                      p_elci text default null, p_zorla boolean default false)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare
  tum_dersler constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi',
    'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  v_uid uuid; v_eski public.paket_uyeler%rowtype; v_var boolean; v_acik boolean; v_hediye boolean;
  v_yeni text[]; v_birlesik text[]; v_paket text; v_dersler text[]; v_bitis date; v_ucretli boolean := false; d text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_dersler is null or coalesce(array_length(p_dersler, 1), 0) = 0 then raise exception 'DERS_SEC'; end if;
  foreach d in array p_dersler loop
    if d is null or not (d = any (tum_dersler)) then raise exception 'DERS_GECERSIZ'; end if;
  end loop;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  if coalesce(length(trim(p_neden)), 0) < 2 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;

  -- tekilleştir, sitedeki ders sırasıyla
  select array_agg(x order by array_position(tum_dersler, x)) into v_yeni from (select distinct unnest(p_dersler) x) t;

  select * into v_eski from public.paket_uyeler where user_id = v_uid for update;
  v_var := found;   -- FOUND bir sonraki sorguda değişmesin diye hemen alınır
  v_acik := v_var and v_eski.bitis >= current_date;
  v_hediye := exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null);
  v_birlesik := v_yeni; v_bitis := p_bitis;

  if v_acik then
    if v_eski.paket in ('tam', 'yeterlilik-tum') then raise exception 'ZATEN_ACIK'; end if;
    if v_eski.paket !~ '^yeterlilik-[1-4]$' then raise exception 'BASKA_SINAV'; end if;   -- sgs, kgk-*
    v_ucretli := not v_hediye;
    if v_ucretli and not p_zorla then raise exception 'UCRETLI_DERS_VAR'; end if;
    select array_agg(x order by array_position(tum_dersler, x)) into v_birlesik
      from (select distinct unnest(coalesce(v_eski.dersler, array[]::text[]) || v_yeni) x) t;
    v_bitis := greatest(v_eski.bitis, p_bitis);
  end if;

  if array_length(v_birlesik, 1) >= 5 then
    v_paket := 'yeterlilik-tum'; v_dersler := null;
  else
    v_paket := 'yeterlilik-' || array_length(v_birlesik, 1); v_dersler := v_birlesik;
  end if;

  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (v_uid, v_paket, v_bitis, v_dersler)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = excluded.dersler;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren, dersler)
    values (v_uid, lower(trim(p_eposta)), v_paket, v_bitis, left(p_neden, 200),
            nullif(upper(trim(coalesce(p_elci, ''))), ''), 'yonetim', v_yeni);
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'paket', v_paket, 'bitis', v_bitis,
                            'verilen', to_jsonb(v_yeni), 'acik_dersler', to_jsonb(coalesce(v_dersler, tum_dersler)),
                            'ucretli_vardi', v_ucretli);
end $$;
revoke all on function public.yonetim_ders_hediye(text, text[], date, text, text, boolean) from public, anon;
grant execute on function public.yonetim_ders_hediye(text, text[], date, text, text, boolean) to authenticated;

-- 3) GÖÇ İÇİ ÖZ-SINAV (geri alınır). Y = deneme yöneticisi, A/B/C/D = deneme üyeleri.
do $$
declare
  y constant uuid := '00000000-0000-4000-8000-0000000d4e01';
  a constant uuid := '00000000-0000-4000-8000-0000000d4e0a';
  b constant uuid := '00000000-0000-4000-8000-0000000d4e0b';
  c constant uuid := '00000000-0000-4000-8000-0000000d4e0c';
  e constant uuid := '00000000-0000-4000-8000-0000000d4e0e';
  r jsonb; p public.paket_uyeler%rowtype; n int := 0; v_bit date := current_date + 30;
begin
  begin
    insert into public.yoneticiler (user_id) values (y) on conflict do nothing;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-dh-a@tetikte.invalid', now(), now()),
           (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-dh-b@tetikte.invalid', now(), now()),
           (c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-dh-c@tetikte.invalid', now(), now()),
           (e, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-dh-e@tetikte.invalid', now(), now());

    -- 1) yönetici olmayan veremez
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: yonetici olmayan verdi';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    n := n + 1;

    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);

    -- 2) yanlış girişler
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array[]::text[], v_bit, 'DENEME'); raise exception 'OLCU: bos ders kabul edildi';
    exception when others then if sqlerrm not like '%DERS_SEC%' then raise; end if; end;
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Temel Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: yanlis ders adi kabul edildi';
    exception when others then if sqlerrm not like '%DERS_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Hukuk'], current_date, 'DENEME'); raise exception 'OLCU: bugun bitis kabul edildi';
    exception when others then if sqlerrm not like '%BITIS_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Hukuk'], v_bit, ''); raise exception 'OLCU: nedensiz kabul edildi';
    exception when others then if sqlerrm not like '%NEDEN_GEREKLI%' then raise; end if; end;
    begin perform public.yonetim_ders_hediye('olcu-dh-yok@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: hesapsiz kabul edildi';
    exception when others then if sqlerrm not like '%HESAP_YOK%' then raise; end if; end;
    n := n + 5;

    -- 3) tek ders: yeterlilik-1 + dersler = {Hukuk}; kütükte ders yazılı
    r := public.yonetim_ders_hediye('OLCU-DH-A@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME tek ders');
    select * into p from public.paket_uyeler where user_id = a;
    if p.paket <> 'yeterlilik-1' or p.dersler <> array['Hukuk'] or p.bitis <> v_bit then raise exception 'OLCU: tek ders yanlis % %', p.paket, p.dersler; end if;
    if not exists (select 1 from public.paket_hediye where user_id = a and paket = 'yeterlilik-1' and dersler = array['Hukuk'] and veren = 'yonetim') then
      raise exception 'OLCU: kutuk ders tasimiyor';
    end if;
    n := n + 2;

    -- 4) ekleyerek: Vergi + Hukuk (tekrar) → yeterlilik-2, sıra sitedeki gibi, bitiş geç olan
    r := public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Vergi Mevzuatı ve Uygulaması', 'Hukuk'], current_date + 10, 'DENEME ikinci');
    select * into p from public.paket_uyeler where user_id = a;
    if p.paket <> 'yeterlilik-2' or p.dersler <> array['Vergi Mevzuatı ve Uygulaması', 'Hukuk'] or p.bitis <> v_bit then
      raise exception 'OLCU: ekleme yanlis % % %', p.paket, p.dersler, p.bitis;
    end if;
    if (r->>'ucretli_vardi')::boolean then raise exception 'OLCU: hediye ucretli sanildi'; end if;
    n := n + 2;

    -- 5) 5. derste tüm dersler: yeterlilik-tum, dersler boş; sonra ZATEN_ACIK
    r := public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Meslek Hukuku'], v_bit, 'DENEME bes');
    select * into p from public.paket_uyeler where user_id = a;
    if p.paket <> 'yeterlilik-tum' or p.dersler is not null then raise exception 'OLCU: 5 ders tum olmadi % %', p.paket, p.dersler; end if;
    begin perform public.yonetim_ders_hediye('olcu-dh-a@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: tum ustune verildi';
    exception when others then if sqlerrm not like '%ZATEN_ACIK%' then raise; end if; end;
    n := n + 2;

    -- 6) parayla alınmış tek ders (hediye kaydı yok): zorlasız durur, zorlayla yalnız ekler
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (b, 'yeterlilik-1', current_date + 60, array['Muhasebe Denetimi']);
    begin perform public.yonetim_ders_hediye('olcu-dh-b@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: ucretli zorlasiz eklendi';
    exception when others then if sqlerrm not like '%UCRETLI_DERS_VAR%' then raise; end if; end;
    r := public.yonetim_ders_hediye('olcu-dh-b@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME', null, true);
    select * into p from public.paket_uyeler where user_id = b;
    if p.paket <> 'yeterlilik-2' or p.dersler <> array['Muhasebe Denetimi', 'Hukuk'] or p.bitis <> current_date + 60 or not (r->>'ucretli_vardi')::boolean then
      raise exception 'OLCU: ucretli ekleme yanlis % % %', p.paket, p.dersler, p.bitis;
    end if;
    n := n + 2;

    -- 7) açık SGS: BASKA_SINAV
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (c, 'sgs', current_date + 60, null);
    begin perform public.yonetim_ders_hediye('olcu-dh-c@tetikte.invalid', array['Hukuk'], v_bit, 'DENEME'); raise exception 'OLCU: sgs ustune ders verildi';
    exception when others then if sqlerrm not like '%BASKA_SINAV%' then raise; end if; end;
    n := n + 1;

    -- 8) süresi bitmiş eski paket: sıfırdan başlar (eski dersler geri gelmez)
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (e, 'yeterlilik-2', current_date - 5, array['Hukuk', 'Meslek Hukuku']);
    r := public.yonetim_ders_hediye('olcu-dh-e@tetikte.invalid', array['Finansal Muhasebe'], v_bit, 'DENEME');
    select * into p from public.paket_uyeler where user_id = e;
    if p.paket <> 'yeterlilik-1' or p.dersler <> array['Finansal Muhasebe'] or p.bitis <> v_bit then raise exception 'OLCU: bitmis paket birlesti % %', p.paket, p.dersler; end if;
    n := n + 1;

    -- 9) eski "paket ver" işlevi değişmedi (tam paket)
    perform public.yonetim_paket_ver('olcu-dh-c@tetikte.invalid', 'tam', v_bit, 'DENEME', null, true);
    if (select paket from public.paket_uyeler where user_id = c) <> 'tam' then raise exception 'OLCU: eski paket_ver bozuldu'; end if;
    n := n + 1;

    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-dh-%@tetikte.invalid')
     or exists (select 1 from public.paket_hediye where eposta like 'olcu-dh-%@tetikte.invalid')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000d4e01') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'DERS HEDIYE OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
