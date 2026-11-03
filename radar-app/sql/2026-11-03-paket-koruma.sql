-- ============================================================================
-- PAKET KORUMA: AÇIK DERS İKİNCİ KEZ SATILMAZ · BAŞKA SINAVIN PAKETİ EZİLMEZ · EKSİK DERS ONARIMI
-- (03.11.2026, site kolu; Cem "bunları yap, sonra GM önerilerini yap")
--
-- ÖLÇÜLDÜ (2026-11-03-paket-olcum.sql, canlı, 03.11): ödenmiş + süren 97 siparişin 96'sı hesapta açık; 1 siparişte seçilen
-- ders hesapta kapalı (1 hesap). İki ayrı sınav ailesinde ödenmiş süren siparişi olan hesap 0.
--
-- 1) siparis_cift_kapi (sipariş açılışı tetiği) iki yeni ret:
--    · DERS_ZATEN_ACIK: yeterlilik-[1-4] siparişinde seçilen derslerden biri hesapta zaten açıksa (eskiden yalnız HEPSİ açıksa
--      PAKET_ZATEN_ACIK idi; bir açık + bir yeni ders seçilirse açık dersin parası boşa gidiyordu).
--    · BASKA_SINAV_ACIK: hesapta başka sınavın (sgs / yeterlilik / kgk) süren paketi varken öteki sınavın paketi alınamaz —
--      paket_uyeler kişi başına TEK satır (birincil anahtar user_id), ödeme eski paketi silerdi. Mağaza yolu aynı kuralı
--      uyguluyordu (magaza-dogrula.ts "baska-sinav"). yeterlilik-kgk iki sınavı kapsar: kgk/yeterlilik siparişi PAKET_ZATEN_ACIK.
--    siparis_cift_sebep DEĞİŞMEZ (iyzico-odeme.ts + hatırlatma robotları yalnız 'PAKET_ZATEN_ACIK' dizesini tanır).
-- 2) _siparis_isle (2026-11-03-ders-ekle-birlestir.sql gövdesi + tek blok): hesapta başka sınavın süren paketi varsa YAZMAZ,
--    'BASKA_SINAV_ACIK' döner, sipariş bağlanmaz (panelde "bağlı değil" görünür, elle çözülür). Kapıdan önce verilmiş sipariş
--    ya da sipariş sonrası başka yoldan (hediye/mağaza) açılan paket için ikinci kilit.
-- 3) ONARIM (canlı veri): ödenmiş + süren yeterlilik-[1-4] siparişinin dersi, hesabın süren yeterlilik-[1-7] ders paketinde
--    yoksa ve hesapta ≥2 ödenmiş yeterlilik siparişi varsa (eski "üzerine yazma" izi) → bütün ödenmiş süren siparişlerin
--    dersleri pakete birleştirilir. Ad farkı ("Temel Hukuk" = "Hukuk", 10.10 ad değişikliği) kayıp sayılmaz. İmza tutmayan
--    kayıt ONARILMAZ, yalnız sayılır (elle bakılır). Günlüğe yalnız sayı.
--
-- 🚫 GÖRMEZ: mağaza (mobil) satın alımı (ayrı kod, zaten "baska-sinav" reddi var) · yönetimin elle paket vermesi (bilerek
--    üzerine yazar) · iki sınavı aynı hesapta TUTMAK (çok satırlı yapı ayrı iş; bugün etkilenen hesap 0).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- GERİ ALMA: siparis_cift_kapi için canli-sema/fonksiyonlar.sql 03.11 tanımı; _siparis_isle için 2026-11-03-ders-ekle-birlestir.sql.
-- ============================================================================

create or replace function public.siparis_cift_kapi()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public', 'auth'
as $function$
declare v text; v_ep text := lower(btrim(coalesce(new.email, ''))); v_aile text := public._paket_sinavi(new.paket); p record;
begin
  v := public.siparis_cift_sebep(new.email, auth.uid(), new.paket, new.secilen_dersler, null);
  if v is not null then
    raise exception '%', v using hint = 'Bu paket hesabında zaten açık; ikinci kez ödeme alınmaz.';
  end if;
  -- 03.11: hesabın süren paketi (uid ya da e-posta eşleşmesi)
  for p in
    select pu.paket, pu.dersler from public.paket_uyeler pu
     where pu.bitis >= current_date
       and (pu.user_id = auth.uid() or pu.user_id in (select u.id from auth.users u where v_ep <> '' and lower(u.email) = v_ep))
  loop
    if lower(p.paket) = 'yeterlilik-kgk' and v_aile in ('yeterlilik', 'kgk') then
      raise exception 'PAKET_ZATEN_ACIK' using hint = 'Yeterlilik + KGK paketin açık; bu sınav zaten içinde.';
    end if;
    if v_aile is not null and lower(p.paket) not in ('tam', 'kurucu', 'yeterlilik-kgk')
       and public._paket_sinavi(p.paket) is not null and public._paket_sinavi(p.paket) <> v_aile then
      raise exception 'BASKA_SINAV_ACIK' using hint = 'Bu hesapta başka bir sınavın paketi açık; aynı hesapta iki sınav paketi şu an tutulamıyor.';
    end if;
    if new.paket ~ '^yeterlilik-[1-4]$' and p.paket ~ '^yeterlilik-[1-7]$'
       and coalesce(array_length(p.dersler, 1), 0) > 0 and coalesce(new.secilen_dersler, array[]::text[]) && p.dersler then
      raise exception 'DERS_ZATEN_ACIK' using hint = 'Seçtiğin derslerden biri hesabında zaten açık.';
    end if;
  end loop;
  if exists (
    select 1 from public.siparisler s
     where lower(s.email) = lower(btrim(coalesce(new.email, ''))) and s.durum = 'odeme_bekliyor'
       and s.paket = new.paket and s.tutar = new.tutar
       and coalesce(s.secilen_dersler, array[]::text[]) @> coalesce(new.secilen_dersler, array[]::text[])
       and coalesce(s.secilen_dersler, array[]::text[]) <@ coalesce(new.secilen_dersler, array[]::text[])
       and s.olusturma > now() - interval '24 hours'
  ) then
    raise exception 'BEKLEYEN_SIPARIS' using hint = 'Bu paket için ödeme bekleyen siparişin var; onu öde.';
  end if;
  return new;
end $function$;

create or replace function public._siparis_isle(p_sid bigint, p_uid uuid, p_yol text)
 returns text
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  tum_dersler constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi',
    'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean; v_ders text[];
  v_birlesik text[]; v_paket text;
begin
  if p_uid is null then return 'BOS'; end if;
  select * into s from public.siparisler where id = p_sid for update;
  if not found or s.durum <> 'odendi' then return 'SIPARIS_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> p_uid then return 'BASKA_HESAPTA'; end if;
  v_bitis := coalesce(s.paket_bitis,
                      greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92));
  if v_bitis < current_date then return 'SURESI_GECMIS'; end if;
  v_ders := case when s.paket ~ '^(yeterlilik-[1-4]|kgk-[1-3])$' then s.secilen_dersler else null end;
  -- KGK modül paketinde boş seçim = kasada "hepsi"; tek konu parasına dört konu açılmasın
  if s.paket ~ '^kgk-[1-3]$' and coalesce(array_length(v_ders, 1), 0) = 0 then return 'DERS_SECIMI_YOK'; end if;
  select * into v_eski from public.paket_uyeler where user_id = p_uid for update;
  v_var := found;

  -- 03.11 (paket-koruma): başka sınavın süren paketi silinmez
  if v_var and v_eski.bitis >= current_date and lower(v_eski.paket) not in ('tam', 'kurucu', 'yeterlilik-kgk')
     and public._paket_sinavi(v_eski.paket) is not null and public._paket_sinavi(s.paket) is not null
     and public._paket_sinavi(v_eski.paket) <> public._paket_sinavi(s.paket) then
    return 'BASKA_SINAV_ACIK';
  end if;

  -- 03.11: açık ders paketine yeni ders → birleştir (eski ders kapanmaz, yeni ders açılır)
  if v_var and s.paket ~ '^yeterlilik-[1-4]$' and coalesce(array_length(v_ders, 1), 0) > 0
     and v_eski.paket ~ '^yeterlilik-[1-7]$' and coalesce(array_length(v_eski.dersler, 1), 0) > 0
     and v_eski.bitis >= current_date then
    select array_agg(x order by coalesce(array_position(tum_dersler, x), 99), x) into v_birlesik
      from (select distinct unnest(v_eski.dersler || v_ders) x) t;
    if v_birlesik @> tum_dersler then v_paket := 'yeterlilik-tum'; v_birlesik := null;
    else v_paket := 'yeterlilik-' || array_length(v_birlesik, 1); end if;
    update public.paket_uyeler
       set paket = v_paket, dersler = v_birlesik, bitis = greatest(v_eski.bitis, v_bitis)
     where user_id = p_uid;
    update public.siparisler set bagli_kullanici = p_uid, bagli_tarih = now(), bagli_yol = left(coalesce(p_yol, ''), 20)
     where id = s.id and bagli_kullanici is null;
    return case when v_ders <@ v_eski.dersler and v_eski.bitis >= v_bitis then 'ZATEN_ACIK' else 'ACILDI' end;
  end if;

  if not (v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis) then
    insert into public.paket_uyeler (user_id, paket, bitis, dersler)
      values (p_uid, s.paket, v_bitis, v_ders)
      on conflict (user_id) do update
        set paket = excluded.paket, dersler = excluded.dersler,
            bitis = greatest(excluded.bitis, case when paket_uyeler.paket = excluded.paket and paket_uyeler.bitis >= current_date then paket_uyeler.bitis else excluded.bitis end);
  end if;
  update public.siparisler set bagli_kullanici = p_uid, bagli_tarih = now(), bagli_yol = left(coalesce(p_yol, ''), 20)
   where id = s.id and bagli_kullanici is null;
  return case when v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis then 'ZATEN_ACIK' else 'ACILDI' end;
end $function$;
revoke all on function public._siparis_isle(bigint, uuid, text) from public, anon, authenticated;

-- ÖZ-SINAV (alt işlemde, 'OLCU_TAMAM' ile GERİ ALINIR; bir vaka tutmazsa göç KIRMIZI, hiçbir şey uygulanmaz):
--   a) yeterlilik-2 [Hukuk, Vergi] açık + sipariş yeterlilik-2 [Hukuk, FM] → DERS_ZATEN_ACIK
--   b) yeterlilik-1 [Hukuk] açık + sipariş yeterlilik-1 [FM] → kabul (ekleme yolu açık)
--   c) sgs açık + sipariş yeterlilik-1 → BASKA_SINAV_ACIK
--   d) sgs açıkken (kapıdan önce verilmiş) ödenmiş yeterlilik siparişi bağlanınca → 'BASKA_SINAV_ACIK', sgs satırı aynen, sipariş bağlanmaz
--   e) sgs süresi geçmiş + sipariş yeterlilik-1 → kabul; bağlanınca yeterlilik-1 yazılır
--   f) son20-yet açık + sipariş yeterlilik-tum → kabul (28.10 yükseltme yolu)
--   g) tam açık + sipariş sgs → PAKET_ZATEN_ACIK (eski kural aynen)
--   h) yeterlilik-kgk açık + sipariş kgk-tum → PAKET_ZATEN_ACIK
do $$
declare
  ua constant uuid := '00000000-0000-4000-8000-0000000c0a01';
  ub constant uuid := '00000000-0000-4000-8000-0000000c0a02';
  uc constant uuid := '00000000-0000-4000-8000-0000000c0a03';
  ud constant uuid := '00000000-0000-4000-8000-0000000c0a04';
  ue constant uuid := '00000000-0000-4000-8000-0000000c0a05';
  uf constant uuid := '00000000-0000-4000-8000-0000000c0a06';
  ug constant uuid := '00000000-0000-4000-8000-0000000c0a07';
  uh constant uuid := '00000000-0000-4000-8000-0000000c0a08';
  v text; r public.paket_uyeler%rowtype; hata text;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x.ep, now(), now()
      from (values (ua, 'olcu-pkk-a@tetikte.invalid'), (ub, 'olcu-pkk-b@tetikte.invalid'), (uc, 'olcu-pkk-c@tetikte.invalid'),
                   (ud, 'olcu-pkk-d@tetikte.invalid'), (ue, 'olcu-pkk-e@tetikte.invalid'), (uf, 'olcu-pkk-f@tetikte.invalid'),
                   (ug, 'olcu-pkk-g@tetikte.invalid'), (uh, 'olcu-pkk-h@tetikte.invalid')) x(id, ep);
    delete from public.paket_uyeler where user_id in (ua, ub, uc, ud, ue, uf, ug, uh);
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values
      (ua, 'yeterlilik-2', current_date + 30, array['Hukuk', 'Vergi Mevzuatı ve Uygulaması']),
      (ub, 'yeterlilik-1', current_date + 30, array['Hukuk']),
      (uc, 'sgs', current_date + 30, null),
      (ue, 'sgs', current_date - 1, null),
      (uf, 'son20-yet', current_date + 30, null),
      (ug, 'tam', current_date + 30, null),
      (uh, 'yeterlilik-kgk', current_date + 30, null);

    -- a)
    hata := null;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
      values ('TT-20261103-PKA', 'yeterlilik-2', 2988, 'Olcu A', 'olcu-pkk-a@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Hukuk', 'Finansal Muhasebe']);
    exception when others then hata := sqlerrm; end;
    if hata is distinct from 'DERS_ZATEN_ACIK' then raise exception 'OLCU: a %', coalesce(hata, 'kabul edildi'); end if;

    -- b)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261103-PKB', 'yeterlilik-1', 2988, 'Olcu B', 'olcu-pkk-b@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Finansal Muhasebe']);

    -- c)
    hata := null;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
      values ('TT-20261103-PKC', 'yeterlilik-1', 2988, 'Olcu C', 'olcu-pkk-c@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Hukuk']);
    exception when others then hata := sqlerrm; end;
    if hata is distinct from 'BASKA_SINAV_ACIK' then raise exception 'OLCU: c %', coalesce(hata, 'kabul edildi'); end if;

    -- d) sipariş paketten ÖNCE verilmiş, sonra sgs açılmış, sonra ödenmiş
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261103-PKD', 'yeterlilik-1', 2988, 'Olcu D', 'olcu-pkk-d@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Hukuk']);
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (ud, 'sgs', current_date + 30, null);
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261103-PKD';
    v := public.siparis_paket_bagla(ud, 'olcu-pkk-d@tetikte.invalid');
    select * into r from public.paket_uyeler where user_id = ud;
    if v <> 'BASKA_SINAV_ACIK' or r.paket <> 'sgs' then raise exception 'OLCU: d % %', v, r.paket; end if;
    if (select bagli_kullanici from public.siparisler where siparis_no = 'TT-20261103-PKD') is not null then raise exception 'OLCU: d siparis baglandi'; end if;

    -- e)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261103-PKE', 'yeterlilik-1', 2988, 'Olcu E', 'olcu-pkk-e@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Hukuk']);
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261103-PKE';
    v := public.siparis_paket_bagla(ue, 'olcu-pkk-e@tetikte.invalid');
    select * into r from public.paket_uyeler where user_id = ue;
    if v <> 'ACILDI' or r.paket <> 'yeterlilik-1' or r.dersler <> array['Hukuk'] then raise exception 'OLCU: e % % %', v, r.paket, r.dersler; end if;

    -- f)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261103-PKF', 'yeterlilik-tum', 2988, 'Olcu F', 'olcu-pkk-f@tetikte.invalid', 'havale', 'odeme_bekliyor', null);

    -- g)
    hata := null;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
      values ('TT-20261103-PKG', 'sgs', 2988, 'Olcu G', 'olcu-pkk-g@tetikte.invalid', 'havale', 'odeme_bekliyor', null);
    exception when others then hata := sqlerrm; end;
    if hata is distinct from 'PAKET_ZATEN_ACIK' then raise exception 'OLCU: g %', coalesce(hata, 'kabul edildi'); end if;

    -- h)
    hata := null;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
      values ('TT-20261103-PKH', 'kgk-tum', 2988, 'Olcu H', 'olcu-pkk-h@tetikte.invalid', 'havale', 'odeme_bekliyor', null);
    exception when others then hata := sqlerrm; end;
    if hata is distinct from 'PAKET_ZATEN_ACIK' then raise exception 'OLCU: h %', coalesce(hata, 'kabul edildi'); end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261103-PK_')
     or exists (select 1 from auth.users where email like 'olcu-pkk-%@tetikte.invalid')
     or exists (select 1 from public.paket_uyeler where user_id in (ua, ub, uc, ud, ue, uf, ug, uh)) then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'PAKET KORUMA OZ-SINAV: 8 vaka TAMAM (geri alindi)';
end $$;

-- 3) ONARIM (canlı veri; yalnız sayı basılır)
do $$
declare
  tum_dersler constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi',
    'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  x record; n_ad int := 0; n_onar int := 0; n_imzasiz int := 0; v_birlesik text[]; v_paket text;
begin
  for x in
    with sip as (
      select coalesce(s.bagli_kullanici, (select u.id from auth.users u where lower(u.email) = lower(s.email) limit 1)) as uid,
             array(select case when d = 'Temel Hukuk' then 'Hukuk' else d end from unnest(s.secilen_dersler) d) as ders
        from public.siparisler s
       where s.durum = 'odendi' and coalesce(s.paket_bitis, current_date) >= current_date and s.paket ~ '^yeterlilik-[1-4]$')
    select p.user_id, p.paket, p.dersler, p.bitis,
           count(*) as siparis_say,
           bool_or(not (sip.ders <@ p.dersler)) as eksik,
           bool_or(not (sip.secilen <@ p.dersler)) as ham_eksik,
           array_agg(distinct d) as tum_siparis_ders
      from (select uid, ders, ders as secilen from sip) sip
      join public.paket_uyeler p on p.user_id = sip.uid
      cross join lateral unnest(sip.ders) d
     where p.bitis >= current_date and p.paket ~ '^yeterlilik-[1-7]$' and coalesce(array_length(p.dersler, 1), 0) > 0
       and not exists (select 1 from public.uye_islem_kutugu k where k.user_id = p.user_id and k.islem = 'iptal')
     group by p.user_id, p.paket, p.dersler, p.bitis
  loop
    if not x.eksik then if x.ham_eksik then n_ad := n_ad + 1; end if; continue; end if;
    -- iz: ≥2 ödenmiş süren yeterlilik ders siparişi (eski üzerine yazma)
    if (select count(*) from public.siparisler s
         where s.durum = 'odendi' and coalesce(s.paket_bitis, current_date) >= current_date and s.paket ~ '^yeterlilik-[1-4]$'
           and (s.bagli_kullanici = x.user_id or lower(s.email) = (select lower(u.email) from auth.users u where u.id = x.user_id))) < 2 then
      n_imzasiz := n_imzasiz + 1; continue;
    end if;
    select array_agg(d order by coalesce(array_position(tum_dersler, d), 99), d) into v_birlesik
      from (select distinct d from unnest(x.dersler || x.tum_siparis_ders) d where d = any (tum_dersler)) t;
    if v_birlesik @> tum_dersler then v_paket := 'yeterlilik-tum'; v_birlesik := null;
    else v_paket := 'yeterlilik-' || array_length(v_birlesik, 1); end if;
    update public.paket_uyeler set paket = v_paket, dersler = v_birlesik where user_id = x.user_id;
    n_onar := n_onar + 1;
  end loop;
  raise notice 'ONARIM: yalniz ad farki (Temel Hukuk) % · eksik dersi olan hesap onarildi % · iz tutmadi (onarilmadi, elle bakilacak) %', n_ad, n_onar, n_imzasiz;
end $$;
