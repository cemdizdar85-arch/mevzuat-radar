-- ============================================================================
-- KGK MODÜL PAKETLERİ (kgk-1 / kgk-2 / kgk-3) SEÇİLEN DERSLERİ AÇAR (13.10.2026, site kolu; ana oturum iş emri)
--
-- ÖLÇÜLDÜ (13.10): paketi açan tek iç yol _siparis_isle (2026-10-12-siparis-hesap-bagla.sql) paket_uyeler.dersler'e
-- seçilen dersleri YALNIZ paket ~ '^yeterlilik-[1-4]$' için yazıyordu. kgk-1 alan kişiye dersler boş (= hepsi) yazılır,
-- kasa RLS (paket_erisim_var: 'kgk-%' + dersler boş → her KGK dersi) dört konuyu da açardı — tek konu parasına dört konu.
-- Bu yüzden fiyat-motoru.js KGK_PAKET_MERDIVENI = false (modül paketleri satılmıyor). Ayrıca kurucu_sayac KGK satırı
-- dönmüyordu (fiyat-motoru.js kurucuKalan KOTA.kgk=150 ile satırı çizemiyordu).
--
-- ÇÖZÜM:
--   1) _siparis_isle yeniden (10-12 gövdesi birebir, tek fark): paket ~ '^(yeterlilik-[1-4]|kgk-[1-3])$' ise
--      siparisler.secilen_dersler → paket_uyeler.dersler. secilen_dersler, satin-al.html tarafından sitedeki DERS adlarıyla
--      (fiyat-motoru.js KGK_MODUL_DERS: modül → "Türkiye Muhasebe Standartları", "Kurumsal Yönetim", …) gönderilir;
--      RLS p_ders = any(dersler) birebir eşler (10.10 "Temel Hukuk" dersi).
--      KGK modül paketinde seçim BOŞSA paket AÇILMAZ ('DERS_SECIMI_YOK' döner, sipariş bağlanmaz): boş dizi/NULL kasada
--      "hepsi" demektir. Yeterlilik-[1-4] için davranış AYNEN (bu göç yalnız KGK'yı ekler; yeterlilik boş seçim ayrı iş).
--   2) kurucu_sayac yeniden: + 'kgk' satırı = paket 'kgk%' (kgk-1/2/3, kgk-tum) + 'yeterlilik-kgk' (fiyat-motoru.js'de
--      o paketin kotası KOTA.kgk). 'yeterlilik' satırı eskisi gibi (yeterlilik-kgk hariç). Üç satır döner: sgs · yeterlilik · kgk.
--   Çağıranlar değişmez: siparis_paket_bagla (yeni üye tetikleyicisi, yonetim_siparis_onayla 10-05 sürümü, kart ödemesi),
--   yonetim_siparis_hesaba_bagla, paketimi_bagla — hepsi _siparis_isle'den geçer.
--   Eskitir: 2026-10-12-siparis-hesap-bagla.sql _siparis_isle tanımı · 2026-09-27-kurucu-sayac.sql kurucu_sayac tanımı.
--
-- 🚫 GÖRMEZ: secilen_dersler'deki adın kasada gerçekten var olup olmadığı (kod kapısı arac/ders-adi-kapisi.js KGK kolu
--    ölçer; kasa adı ayrıca değişirse ders kilitli kalır) · magaza (mobil) yolu (magaza-dogrula.ts KGK ürünü tanımıyor) ·
--    yeterlilik-[1-4] boş seçim · yonetim_* yolu (yonetici_mi taklit edilemiyor, öz-sınavda sınanmaz).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- 13.10 ilk koşu (38432413171) öz-sınavda düştü: sahte sipariş tutarı 1 TL siparisler_tutar_check'e takıldı; tek işlem geri alındı,
-- kütüğe yazılmadı (veritabanında değişiklik yok) → tutar 2988 (10-12 öz-sınavındaki değer) yapıldı, aynı dosya yeniden koşar.
-- ============================================================================

-- 1) tek iç yol: KGK modül paketi de seçilen dersleri yazar
create or replace function public._siparis_isle(p_sid bigint, p_uid uuid, p_yol text)
returns text language plpgsql security definer set search_path = public as $$
declare s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean; v_ders text[];
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
  select * into v_eski from public.paket_uyeler where user_id = p_uid;
  v_var := found;
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
end $$;
revoke all on function public._siparis_isle(bigint, uuid, text) from public, anon, authenticated;

-- 2) kurucu sayacı: + kgk satırı
create or replace function public.kurucu_sayac()
returns table (sinav text, satilan integer)
language sql
stable
security definer
set search_path = public
as $$
  with odenen as (
    select paket from public.siparisler where durum = 'odendi'
    union all
    select paket from public.magaza_siparis where durum in ('verildi','tuketildi') and paket is not null
  ), eslenen as (
    select case
             when paket = 'sgs' then 'sgs'
             when paket like 'yeterlilik-%' and paket <> 'yeterlilik-kgk' then 'yeterlilik'
             when paket like 'kgk%' or paket = 'yeterlilik-kgk' then 'kgk'
           end as sinav
      from odenen
  )
  select s.sinav, coalesce((select count(*)::int from eslenen e where e.sinav = s.sinav), 0)
    from (values ('sgs'), ('yeterlilik'), ('kgk')) as s(sinav);
$$;
revoke all on function public.kurucu_sayac() from public;
grant execute on function public.kurucu_sayac() to anon, authenticated;

-- ÖZ-SINAV (alt işlemde, sonunda 'OLCU_TAMAM' ile GERİ ALINIR; bir vaka tutmazsa göç KIRMIZI, hiçbir şey uygulanmaz):
--   kgk-3 + 4 ders → paket_uyeler.dersler = o 4 ders (sıra dahil) · kgk-tum → dersler boş (hepsi) · kgk-2 + boş seçim →
--   DERS_SECIMI_YOK, paket yazılmaz, sipariş bağlanmaz · yeterlilik-2 + 2 ders → eskisi gibi 2 ders (gerileme yok) ·
--   kurucu_sayac 3 satır; kgk = eskisi + 4 (kgk-3, kgk-tum, kgk-2 ödenmiş, yeterlilik-kgk ödenmiş), yeterlilik = eskisi + 1,
--   sgs değişmez · yeterlilik-kgk → dersler boş.
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-00000000d0a1';
  b constant uuid := '00000000-0000-4000-8000-00000000d0b2';
  c constant uuid := '00000000-0000-4000-8000-00000000d0c3';
  d constant uuid := '00000000-0000-4000-8000-00000000d0d4';
  e constant uuid := '00000000-0000-4000-8000-00000000d0e5';
  k3 constant text[] := array['Türkiye Muhasebe Standartları', 'Kurumsal Yönetim', 'Finansal Yönetim', 'Türkiye Denetim Standartları'];
  y2 constant text[] := array['Finansal Muhasebe', 'Hukuk'];
  s_sgs int; s_yet int; s_kgk int; n int; v text; v_ders text[];
begin
  begin
    select satilan into s_sgs from public.kurucu_sayac() where sinav = 'sgs';
    select satilan into s_yet from public.kurucu_sayac() where sinav = 'yeterlilik';
    select satilan into s_kgk from public.kurucu_sayac() where sinav = 'kgk';
    if s_kgk is null then raise exception 'OLCU: kurucu_sayac kgk satiri yok'; end if;

    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-kgk-a@tetikte.invalid', now(), now()),
           (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-kgk-b@tetikte.invalid', now(), now()),
           (c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-kgk-c@tetikte.invalid', now(), now()),
           (d, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-kgk-d@tetikte.invalid', now(), now()),
           (e, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-kgk-e@tetikte.invalid', now(), now());
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, paket_bitis, secilen_dersler)
    values ('TT-20261013-KG01', 'kgk-3',          2988, 'Olcu Kgk A', 'olcu-kgk-a@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, k3),
           ('TT-20261013-KG02', 'kgk-tum',        2988, 'Olcu Kgk B', 'olcu-kgk-b@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, null),
           ('TT-20261013-KG03', 'kgk-2',          2988, 'Olcu Kgk C', 'olcu-kgk-c@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, null),
           ('TT-20261013-KG04', 'yeterlilik-2',   2988, 'Olcu Kgk D', 'olcu-kgk-d@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, y2),
           ('TT-20261013-KG05', 'yeterlilik-kgk', 2988, 'Olcu Kgk E', 'olcu-kgk-e@tetikte.invalid', 'havale', 'odeme_bekliyor', current_date + 90, null);
    update public.siparisler set durum = 'odendi' where siparis_no like 'TT-20261013-KG%';

    -- kgk-3: seçilen 4 ders aynen (sıra dahil)
    v := public.siparis_paket_bagla(a, 'olcu-kgk-a@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: kgk-3 sonucu %', v; end if;
    select dersler into v_ders from public.paket_uyeler where user_id = a;
    if v_ders is null or v_ders <> k3 then raise exception 'OLCU: kgk-3 dersler % (beklenen %)', v_ders, k3; end if;
    if (select bagli_kullanici from public.siparisler where siparis_no = 'TT-20261013-KG01') <> a then raise exception 'OLCU: kgk-3 bag damgasi yok'; end if;

    -- kgk-tum: dersler boş = hepsi
    v := public.siparis_paket_bagla(b, 'olcu-kgk-b@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: kgk-tum sonucu %', v; end if;
    select dersler into v_ders from public.paket_uyeler where user_id = b;
    if v_ders is not null then raise exception 'OLCU: kgk-tum dersler bos olmali, %', v_ders; end if;

    -- kgk-2 + boş seçim: AÇILMAZ, bağlanmaz
    v := public.siparis_paket_bagla(c, 'olcu-kgk-c@tetikte.invalid');
    if v <> 'DERS_SECIMI_YOK' then raise exception 'OLCU: kgk-2 bos secim sonucu %', v; end if;
    if exists (select 1 from public.paket_uyeler where user_id = c) then raise exception 'OLCU: kgk-2 bos secimle paket acildi'; end if;
    if (select bagli_kullanici from public.siparisler where siparis_no = 'TT-20261013-KG03') is not null then raise exception 'OLCU: kgk-2 bos secimle siparis baglandi'; end if;

    -- yeterlilik-2: gerileme yok
    v := public.siparis_paket_bagla(d, 'olcu-kgk-d@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: yeterlilik-2 sonucu %', v; end if;
    select dersler into v_ders from public.paket_uyeler where user_id = d;
    if v_ders is null or v_ders <> y2 then raise exception 'OLCU: yeterlilik-2 dersler %', v_ders; end if;

    -- yeterlilik-kgk: dersler boş
    v := public.siparis_paket_bagla(e, 'olcu-kgk-e@tetikte.invalid');
    if v <> 'ACILDI' then raise exception 'OLCU: yeterlilik-kgk sonucu %', v; end if;
    select dersler into v_ders from public.paket_uyeler where user_id = e;
    if v_ders is not null then raise exception 'OLCU: yeterlilik-kgk dersler bos olmali, %', v_ders; end if;

    -- kurucu sayacı: 3 satır; kgk +4 (kgk-3, kgk-tum, kgk-2, yeterlilik-kgk) · yeterlilik +1 · sgs aynı
    select count(*) into n from public.kurucu_sayac();
    if n <> 3 then raise exception 'OLCU: kurucu_sayac % satir (beklenen 3)', n; end if;
    if (select satilan from public.kurucu_sayac() where sinav = 'kgk') <> s_kgk + 4 then raise exception 'OLCU: kgk sayaci % (beklenen %)', (select satilan from public.kurucu_sayac() where sinav = 'kgk'), s_kgk + 4; end if;
    if (select satilan from public.kurucu_sayac() where sinav = 'yeterlilik') <> s_yet + 1 then raise exception 'OLCU: yeterlilik sayaci degisti'; end if;
    if (select satilan from public.kurucu_sayac() where sinav = 'sgs') <> s_sgs then raise exception 'OLCU: sgs sayaci degisti'; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261013-KG%')
     or exists (select 1 from auth.users where email like 'olcu-kgk-%@tetikte.invalid')
     or exists (select 1 from public.paket_uyeler where user_id in (a, b, c, d, e)) then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'KGK MODUL PAKET OZ-SINAV: 6 vaka TAMAM (geri alindi)';
end $$;

-- ÖLÇÜ (uygulama sonrası):
--   select * from public.kurucu_sayac();   -- 3 satır: sgs · yeterlilik · kgk
--   anon: curl -X POST <SB>/rest/v1/rpc/kurucu_sayac -H "apikey: <yayın anahtarı>" → 200 + 3 satır
--   select prosrc ~ 'kgk-\[1-3\]' from pg_proc where proname = '_siparis_isle';   -- t
