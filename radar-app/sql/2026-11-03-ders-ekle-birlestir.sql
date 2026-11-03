-- ============================================================================
-- DERS EKLEME SATIN ALIMI DERSLERİ BİRLEŞTİRİR (03.11.2026, site kolu; Cem "1 ve 2 yap")
--
-- ÖLÇÜLDÜ (03.11, canli-sema/fonksiyonlar.sql _siparis_isle): paketi açan tek iç yol, açık yeterlilik-N paketi olan
-- üyenin YENİ ders siparişini birleştirmiyordu:
--   · aynı paket adı (yeterlilik-1 [Hukuk] açıkken yeterlilik-1 [Vergi]) ve eski bitiş ≥ yeni bitiş → 'ZATEN_ACIK',
--     yeni ders HİÇ açılmıyordu (para alındı, ders kilitli);
--   · farklı ad (yeterlilik-1 açıkken yeterlilik-2) → paket_uyeler.dersler YENİ seçimle EZİLİYORDU (eski ders kapanıyordu).
-- Çift sipariş kapısı (_paket_kapsar) yeni ders içeren siparişe izin veriyor; yani bu sipariş verilebiliyordu.
-- Bugüne kadar böyle bir sipariş olup olmadığı ÖLÇÜLMEDİ (canlı veriye bu göçte bakılmaz).
--
-- ÇÖZÜM: _siparis_isle yeniden (2026-10-13-kgk-modul-paket.sql gövdesi + tek blok): sipariş yeterlilik-[1-4] ve üyenin
--   AÇIK (bitiş ≥ bugün) paketi yeterlilik-[1-7] + ders listeli ise dersler birleşir (tekil, sitedeki ders sırası):
--     birleşik 8 ders → 'yeterlilik-tum', dersler boş (= hepsi) · değilse 'yeterlilik-<adet>', dersler = birleşik.
--     bitiş = büyük olan. Yeni ders eklendiyse 'ACILDI', eklenmediyse 'ZATEN_ACIK'.
--   Fiyat politikası DEĞİŞMEZ: 5–7 ders tüm pakete yükseltilmez (yonetim_ders_hediye'nin ≥5 → tum kuralı hediyeye özgü).
--   Değişmeyen: süresi geçmiş eski paket (birleşmez, yeni seçim yazılır) · eski paket tam/kurucu/yeterlilik-tum (çift
--   kapı zaten reddeder) · sgs/kgk/son20 paketli üyenin yeterlilik siparişi (eski davranış: üzerine yazar — AYRI İŞ,
--   ölçülmedi) · kgk-N (modül paketleri satılmıyor).
--   Çağıranlar değişmez: siparis_paket_bagla, kart_siparis_odendi, yonetim_siparis_onayla, yonetim_siparis_hesaba_bagla,
--   paketimi_bagla — hepsi _siparis_isle'den geçer.
--   Eskitir: 2026-10-13-kgk-modul-paket.sql _siparis_isle tanımı.
--
-- 🚫 GÖRMEZ: sitede aynı dersi ikinci kez seçip birlikte yeni ders alan siparişi (ödenir, sahip olduğu ders boşa gider;
--    sayfa tarafında ayrı iş) · mağaza (mobil) satın alımı (magaza-dogrula.ts ayrı yol) · ders adı yazım farkı (birebir eşler).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- GERİ ALMA: 2026-10-13-kgk-modul-paket.sql'deki _siparis_isle tanımı yeniden basılır.
-- ============================================================================

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

-- ÖZ-SINAV (alt işlemde, sonunda 'OLCU_TAMAM' ile GERİ ALINIR; bir vaka tutmazsa göç KIRMIZI, hiçbir şey uygulanmaz):
--   a) yeterlilik-1 [Hukuk] açık + yeterlilik-1 [Vergi] → ACILDI, yeterlilik-2 [Vergi, Hukuk], bitiş büyük olan (eski)
--   b) yeterlilik-4 [ilk 4] açık + yeterlilik-4 [son 4] → yeterlilik-tum, dersler boş
--   c) yeterlilik-1 [Hukuk] SÜRESİ GEÇMİŞ + yeterlilik-1 [Vergi] → yalnız [Vergi] (birleşmez)
--   d) paketsiz + yeterlilik-2 [FM, Hukuk] → aynen (gerileme yok)
--   e) yeterlilik-3 [FM, Hukuk, SPK] açık + yeterlilik-2 [Hukuk, Meslek] → yeterlilik-4 (tekil, site sırası) — 5–7 tum'a çıkmaz
--   f) yeterlilik-4 [4 ders] açık + yeterlilik-1 [5. ders] → yeterlilik-5, dersler 5 (tüm pakete çıkmaz)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000de0a1';
  b constant uuid := '00000000-0000-4000-8000-0000000de0b2';
  c constant uuid := '00000000-0000-4000-8000-0000000de0c3';
  d constant uuid := '00000000-0000-4000-8000-0000000de0d4';
  e constant uuid := '00000000-0000-4000-8000-0000000de0e5';
  f constant uuid := '00000000-0000-4000-8000-0000000de0f6';
  ilk4 constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi', 'Muhasebe Denetimi'];
  son4 constant text[] := array['Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  v text; r public.paket_uyeler%rowtype;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x.ep, now(), now()
      from (values (a, 'olcu-dekle-a@tetikte.invalid'), (b, 'olcu-dekle-b@tetikte.invalid'), (c, 'olcu-dekle-c@tetikte.invalid'),
                   (d, 'olcu-dekle-d@tetikte.invalid'), (e, 'olcu-dekle-e@tetikte.invalid'), (f, 'olcu-dekle-f@tetikte.invalid')) x(id, ep);
    -- yeni üye tetikleyicisi paket bağlamış olabilir: eski paketler elle kurulur
    delete from public.paket_uyeler where user_id in (a, b, c, d, e, f);
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values
      (a, 'yeterlilik-1', current_date + 200, array['Hukuk']),
      (b, 'yeterlilik-4', current_date + 30, ilk4),
      (c, 'yeterlilik-1', current_date - 1, array['Hukuk']),
      (e, 'yeterlilik-3', current_date + 30, array['Sermaye Piyasası Mevzuatı', 'Finansal Muhasebe', 'Hukuk']),
      (f, 'yeterlilik-4', current_date + 30, ilk4);
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, paket_bitis, secilen_dersler)
    values ('TT-20261103-DE01', 'yeterlilik-1', 2988, 'Olcu Dekle A', 'olcu-dekle-a@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, array['Vergi Mevzuatı ve Uygulaması']),
           ('TT-20261103-DE02', 'yeterlilik-4', 2988, 'Olcu Dekle B', 'olcu-dekle-b@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, son4),
           ('TT-20261103-DE03', 'yeterlilik-1', 2988, 'Olcu Dekle C', 'olcu-dekle-c@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, array['Vergi Mevzuatı ve Uygulaması']),
           ('TT-20261103-DE04', 'yeterlilik-2', 2988, 'Olcu Dekle D', 'olcu-dekle-d@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, array['Finansal Muhasebe', 'Hukuk']),
           ('TT-20261103-DE05', 'yeterlilik-2', 2988, 'Olcu Dekle E', 'olcu-dekle-e@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, array['Hukuk', 'Meslek Hukuku']),
           ('TT-20261103-DE06', 'yeterlilik-1', 2988, 'Olcu Dekle F', 'olcu-dekle-f@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, array['Hukuk']);
    update public.siparisler set durum = 'odendi' where siparis_no like 'TT-20261103-DE%';

    -- a) birleşir, bitiş eski (daha geç) kalır
    v := public.siparis_paket_bagla(a, 'olcu-dekle-a@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: a sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = a;
    if r.paket <> 'yeterlilik-2' or r.dersler <> array['Vergi Mevzuatı ve Uygulaması', 'Hukuk'] then raise exception 'OLCU: a % %', r.paket, r.dersler; end if;
    if r.bitis <> current_date + 200 then raise exception 'OLCU: a bitis % (beklenen %)', r.bitis, current_date + 200; end if;
    if (select bagli_kullanici from public.siparisler where siparis_no = 'TT-20261103-DE01') is distinct from a then raise exception 'OLCU: a bag damgasi yok'; end if;

    -- b) 8 ders → tüm paket
    v := public.siparis_paket_bagla(b, 'olcu-dekle-b@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: b sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = b;
    if r.paket <> 'yeterlilik-tum' or r.dersler is not null then raise exception 'OLCU: b % %', r.paket, r.dersler; end if;
    if r.bitis <> current_date + 90 then raise exception 'OLCU: b bitis %', r.bitis; end if;

    -- c) süresi geçmiş eski paket birleşmez
    v := public.siparis_paket_bagla(c, 'olcu-dekle-c@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: c sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = c;
    if r.paket <> 'yeterlilik-1' or r.dersler <> array['Vergi Mevzuatı ve Uygulaması'] then raise exception 'OLCU: c % %', r.paket, r.dersler; end if;

    -- d) paketsiz: eskisi gibi
    v := public.siparis_paket_bagla(d, 'olcu-dekle-d@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: d sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = d;
    if r.paket <> 'yeterlilik-2' or r.dersler <> array['Finansal Muhasebe', 'Hukuk'] then raise exception 'OLCU: d % %', r.paket, r.dersler; end if;

    -- e) ortak ders tekilleşir, site sırası
    v := public.siparis_paket_bagla(e, 'olcu-dekle-e@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: e sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = e;
    if r.paket <> 'yeterlilik-4' or r.dersler <> array['Finansal Muhasebe', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'] then raise exception 'OLCU: e % %', r.paket, r.dersler; end if;

    -- f) 5 ders tüm pakete çıkmaz
    v := public.siparis_paket_bagla(f, 'olcu-dekle-f@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: f sonucu %', v; end if;
    select * into r from public.paket_uyeler where user_id = f;
    if r.paket <> 'yeterlilik-5' or array_length(r.dersler, 1) <> 5 then raise exception 'OLCU: f % %', r.paket, r.dersler; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261103-DE%')
     or exists (select 1 from auth.users where email like 'olcu-dekle-%@tetikte.invalid')
     or exists (select 1 from public.paket_uyeler where user_id in (a, b, c, d, e, f)) then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'DERS EKLE BIRLESTIR OZ-SINAV: 6 vaka TAMAM (geri alindi)';
end $$;

-- ÖLÇÜ (uygulama sonrası):
--   select prosrc ~ 'yeterlilik-\[1-7\]' from pg_proc where proname = '_siparis_isle';   -- t
