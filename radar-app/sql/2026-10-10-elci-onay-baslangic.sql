-- ============================================================================
-- 2026-10-10-elci-onay-baslangic.sql — KOMİSYON SÖZLEŞME ONAYINDAN SONRAKİ SATIŞLARDAN BAŞLAR
--
-- NEDEN (Cem 10.10 "onaydan sonra başlayacak diyoruz ya" → "1.2.3 üçünü de yap"):
--   Sözleşme Madde 4.2 "Sözleşme, Elçinin Panelde bu metni onayladığı anda ... kurulur." Panel ve dönem raporu ise
--   satışları dönem başından sayıyordu, onay tarihine bakmıyordu. Ayrıca elci_sozlesme_onayla her yeni sürüm
--   onayında sozlesme_onay'ı ŞİMDİ'ye çekiyor: sözleşmenin İLK kurulduğu an kayboluyordu (10.10 ölçümü: AELK4P
--   ilk onay 2026-10-07 23:50:37 UTC, 13.10 sürüm onayıyla 2026-10-10 09:50'ye ezildi).
--
-- NE YAPAR:
--   1) elciler.ilk_onay (sözleşmenin ilk kurulduğu an; sonraki sürüm onayları DEĞİŞTİRMEZ).
--      Geri doldurma: AELK4P = 2026-10-07 23:50:37.588063+00 (10.10 sabah servis anahtarıyla okunan değer,
--      Sözleşme gönderimi oturumu); diğerleri = mevcut sozlesme_onay (onayı olmayan null kalır).
--   2) elci_sozlesme_onayla: ilk_onay = coalesce(ilk_onay, now()).
--   3) elci_panelim + elci_donem_raporu: kademe, ders ve komisyon sayımına YALNIZ s.olusturma >= ilk_onay olan
--      sipariş girer. Önceki ödenmiş satışlar ayrı alanda: onay_oncesi_satis (komisyona girmez, gösterilir).
--      Panel ayrıca ilk_onay döner. Rapora sona 'onay_oncesi_satis' + 'ilk_onay' sütunları eklenir.
--   4) yonetim_elci_hesaplar: + ilk_onay + sozlesme_onay (son sürüm onay anı).
--
-- GÖRMEZ: onaydan önce verilip onaydan SONRA ödenen sipariş onay öncesi sayılır (ölçüt sipariş anı) ·
--   iade sayısı onay ayrımı yapmaz (bilgi amaçlı). Push ile otomatik (sql-uygula.yml). Göç içi öz-sınav, geri alınır.
-- ============================================================================

alter table public.elciler add column if not exists ilk_onay timestamptz;
update public.elciler set ilk_onay = '2026-10-07 23:50:37.588063+00' where kod = 'AELK4P' and ilk_onay is null;
update public.elciler set ilk_onay = sozlesme_onay where ilk_onay is null and sozlesme_onay is not null;

create or replace function public.elci_sozlesme_onayla(p_surum text)
returns boolean language plpgsql volatile security definer set search_path = public as $$
begin
  if auth.uid() is null or coalesce(p_surum, '') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    return false;
  end if;
  update elciler set sozlesme_onay = now(), sozlesme_surum = p_surum, ilk_onay = coalesce(ilk_onay, now())
   where user_id = auth.uid();
  return found;
end $$;
revoke all on function public.elci_sozlesme_onayla(text) from public;
grant execute on function public.elci_sozlesme_onayla(text) to authenticated;
revoke execute on function public.elci_sozlesme_onayla(text) from anon;

-- DÖNEM RAPORU (ödeme bu rapordan yapılır): sayım yalnız ilk onaydan sonraki siparişler. Sona iki sütun.
create or replace view public.elci_donem_raporu as
with sayim as (
  select d.ad as donem, d.baslangic, d.bitis, e.kod, e.ad_soyad, e.instagram, e.baslangic_kademe, e.ilk_onay,
         count(*) filter (where s.olusturma >= e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now())::int as kesin_satis,
         count(*) filter (where s.olusturma >= e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now())::int as bekleyen_satis,
         count(*) filter (where s.durum = 'iade')::int                                                    as iade,
         count(*) filter (where s.durum = 'odeme_bekliyor')::int                                          as odeme_bekleyen,
         count(*) filter (where s.olusturma >= e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now())::int as ders_kesin_satis,
         count(*) filter (where s.olusturma >= e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now())::int as ders_bekleyen_satis,
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.olusturma >= e.ilk_onay and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()), 0)::int as ders_komisyon_tl,
         count(*) filter (where s.durum = 'odendi' and (e.ilk_onay is null or s.olusturma < e.ilk_onay))::int as onay_oncesi_satis
    from sinav_donemleri d
    cross join elciler e
    left join siparisler s
           on s.elci_kodu = e.kod
          and s.olusturma::date between d.baslangic and d.bitis
   group by d.ad, d.baslangic, d.bitis, e.kod, e.ad_soyad, e.instagram, e.baslangic_kademe, e.ilk_onay
)
select donem, kod, ad_soyad, instagram, baslangic_kademe,
       kesin_satis, bekleyen_satis, iade, odeme_bekleyen,
       elci_komisyon(kesin_satis, baslangic_kademe) as komisyon_tl,
       case when kesin_satis >= 50 then 3 when kesin_satis >= 10 then 2 else 1 end as ulasilan_kademe,
       greatest(case when kesin_satis >= 50 then 3 when kesin_satis >= 10 then 2 else 1 end,
                baslangic_kademe) as sonraki_baslangic,
       case when kesin_satis >= 100 then 'OZEL' else '' end as ozel_isbirligi,
       ders_kesin_satis, ders_bekleyen_satis, ders_komisyon_tl,
       elci_komisyon(kesin_satis, baslangic_kademe) + ders_komisyon_tl as toplam_komisyon_tl,
       onay_oncesi_satis, ilk_onay
  from sayim;
revoke all on public.elci_donem_raporu from anon, authenticated;

-- ELÇİ PANELİ (2026-10-01 sürümü + ilk onay süzgeci + ilk_onay / onay_oncesi_satis alanları)
create or replace function public.elci_panelim()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_e      elciler%rowtype;
  v_d      sinav_donemleri%rowtype;
  v_kesin  int := 0;
  v_bek    int := 0;
  v_iade   int := 0;
  v_obek   int := 0;
  v_dkesin int := 0;
  v_dbek   int := 0;
  v_dkom_k int := 0;
  v_dkom_b int := 0;
  v_once   int := 0;
  v_n      int;
  v_k      smallint;
  v_esik   int;
begin
  if auth.uid() is null then
    return null;
  end if;
  select * into v_e from elciler where user_id = auth.uid();
  if not found then
    return null;
  end if;

  select * into v_d from sinav_donemleri
   where current_date between baslangic and bitis
   order by baslangic desc limit 1;
  if not found then
    select * into v_d from sinav_donemleri order by bitis desc limit 1;
  end if;

  select count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         count(*) filter (where s.durum = 'iade'),
         count(*) filter (where s.durum = 'odeme_bekliyor'),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.olusturma >= v_e.ilk_onay and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()), 0),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.olusturma >= v_e.ilk_onay and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()), 0),
         count(*) filter (where s.durum = 'odendi' and (v_e.ilk_onay is null or s.olusturma < v_e.ilk_onay))
    into v_kesin, v_bek, v_iade, v_obek, v_dkesin, v_dbek, v_dkom_k, v_dkom_b, v_once
    from siparisler s
   where s.elci_kodu = v_e.kod
     and s.olusturma::date between v_d.baslangic and v_d.bitis;

  v_n := coalesce(v_kesin, 0) + coalesce(v_bek, 0);
  v_k := v_e.baslangic_kademe;
  v_esik := case when v_k <= 1 and v_n < 9  then 10
                 when v_k <= 2 and v_n < 49 then 50
                 when v_n < 99               then 100
                 else null end;

  return jsonb_build_object(
    'kod',               v_e.kod,
    'ad',                v_e.ad_soyad,
    'aktif',             v_e.aktif,
    'sozlesme_onay',     v_e.sozlesme_onay,
    'sozlesme_surum',    v_e.sozlesme_surum,
    'ilk_onay',          v_e.ilk_onay,
    'onay_oncesi_satis', coalesce(v_once, 0),
    'odeme_bilgisi',     v_e.odeme_bilgisi,
    'baslangic_kademe',  v_k,
    'donem',             case when v_d.ad is null then null else
                           jsonb_build_object('ad', v_d.ad, 'baslangic', v_d.baslangic, 'bitis', v_d.bitis) end,
    'kesin_satis',       coalesce(v_kesin, 0),
    'bekleyen_satis',    coalesce(v_bek, 0),
    'iade',              coalesce(v_iade, 0),
    'odeme_bekleyen',    coalesce(v_obek, 0),
    'komisyon_kesin',    elci_komisyon(coalesce(v_kesin, 0), v_k),
    'komisyon_tahmini',  elci_komisyon(v_n, v_k),
    'siradaki_birim',    elci_komisyon(v_n + 1, v_k) - elci_komisyon(v_n, v_k),
    'sonraki_esik',      v_esik,
    'sonraki_esik_kalan', case when v_esik is null then null else v_esik - v_n end,
    'sonraki_esik_birim', case v_esik when 10 then 1000 when 50 then 1250 else null end,
    'ozel_isbirligi',    v_n >= 100,
    'ders_kesin_satis',      coalesce(v_dkesin, 0),
    'ders_bekleyen_satis',   coalesce(v_dbek, 0),
    'ders_komisyon_kesin',   coalesce(v_dkom_k, 0),
    'ders_komisyon_tahmini', coalesce(v_dkom_k, 0) + coalesce(v_dkom_b, 0),
    'indirimler',        (select coalesce(jsonb_object_agg(paket, indirim_tl), '{}'::jsonb) from elci_indirim where indirim_tl > 0),
    'ders_komisyonlari', (select coalesce(jsonb_object_agg(paket, sabit_komisyon_tl), '{}'::jsonb) from elci_indirim where sabit_komisyon_tl is not null),
    'odemeler',          (select coalesce(jsonb_agg(jsonb_build_object('donem', o.donem, 'tutar_tl', o.tutar_tl,
                                                   'odeme_tarihi', o.odeme_tarihi) order by o.odeme_tarihi desc), '[]'::jsonb)
                            from elci_odemeler o where o.kod = v_e.kod)
  );
end $$;
revoke all on function public.elci_panelim() from public;
grant execute on function public.elci_panelim() to authenticated;
revoke execute on function public.elci_panelim() from anon;

-- YÖNETİM: + ilk_onay + sozlesme_onay (2026-10-10-elci-erisim-otomatik sürümü + iki alan)
create or replace function public.yonetim_elci_hesaplar()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kod', e.kod,
             'bagli', e.user_id is not null,
             'eposta', (select u.email from auth.users u where u.id = e.user_id),
             'kayitli_eposta', e.email,
             'instagram', e.instagram,
             'sozlesme', e.sozlesme_onay is not null,
             'sozlesme_surum', e.sozlesme_surum,
             'sozlesme_onay', e.sozlesme_onay,
             'ilk_onay', e.ilk_onay,
             'erisim_paket', p.paket,
             'erisim_bitis', p.bitis))
      from public.elciler e
      left join public.paket_uyeler p on p.user_id = e.user_id
  ), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_elci_hesaplar() from public, anon;
grant execute on function public.yonetim_elci_hesaplar() to authenticated;

-- GÖÇ İÇİ ÖZ-SINAV: sahte elçi + siparişler (dönem içinde), sonunda GERİ ALINIR ---
do $sinav$
declare
  v_d  sinav_donemleri%rowtype;
  t0   timestamptz;
  a1 int; a2 int; a3 int; a4 int; a5 int;
  sonuc text;
begin
  select * into v_d from sinav_donemleri where current_date between baslangic and bitis order by baslangic desc limit 1;
  if not found then raise notice 'ELCI_ONAY_SINAV ATLANDI: bugünü kapsayan dönem yok'; return; end if;
  begin
    t0 := now() - interval '20 days';
    insert into public.elciler (kod, ad_soyad, aktif, ilk_onay) values ('ZZONY1', 'Sinav Onay', true, now() - interval '10 days');
    -- onaydan önce 2 ödenmiş satış (kesinleşmiş), sonra 3 ödenmiş kademeli + 1 ödenmiş ders satışı (kesinleşmiş)
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, ad_soyad, email, odeme, durum, kvkk_onay, olusturma, elci_kodu, odendi_tarihi, elci_sabit_komisyon_tl)
    select 'ZZ-SNV-' || g, 'sgs', 'SGS', 2588, 'Sinav Alici', 'sinav@ornek.invalid', 'havale', 'odendi', t0, greatest(v_d.baslangic::timestamptz, now() - interval '15 days'), 'ZZONY1', now() - interval '9 days', null
      from generate_series(1, 2) g;
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, ad_soyad, email, odeme, durum, kvkk_onay, olusturma, elci_kodu, odendi_tarihi, elci_sabit_komisyon_tl)
    select 'ZZ-SNV-B' || g, 'sgs', 'SGS', 2588, 'Sinav Alici', 'sinav@ornek.invalid', 'havale', 'odendi', t0, now() - interval '9 days', 'ZZONY1', now() - interval '8 days', null
      from generate_series(1, 3) g;
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, ad_soyad, email, odeme, durum, kvkk_onay, olusturma, elci_kodu, odendi_tarihi, elci_sabit_komisyon_tl)
    values ('ZZ-SNV-D1', 'yeterlilik-1', 'Yeterlilik 1', 1138, 'Sinav Alici', 'sinav@ornek.invalid', 'havale', 'odendi', t0, now() - interval '9 days', 'ZZONY1', now() - interval '8 days', 150);
    select kesin_satis, ders_kesin_satis, ders_komisyon_tl, onay_oncesi_satis into a1, a2, a3, a4
      from public.elci_donem_raporu where kod = 'ZZONY1' and donem = v_d.ad;
    -- ilk_onay yokken hiçbir satış sayılmaz
    update public.elciler set ilk_onay = null where kod = 'ZZONY1';
    select kesin_satis into a5 from public.elci_donem_raporu where kod = 'ZZONY1' and donem = v_d.ad;
    raise exception 'SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'SINAV_GERI_AL' then raise; end if;
  end;
  sonuc := format('kesin=%s ders=%s ders_kom=%s once=%s onaysiz_kesin=%s', a1, a2, a3, a4, a5);
  if not (a1 = 3 and a2 = 1 and a3 = 150 and a4 = 2 and a5 = 0) then
    raise exception 'ELCI_ONAY_SINAV KIRMIZI: %', sonuc;
  end if;
  raise notice 'ELCI_ONAY_SINAV YESIL: %', sonuc;
end $sinav$;

-- ÖLÇÜ (göç günlüğünde yalnız sayı): onaylı elçilerde ilk_onay dolu mu, onay öncesi ödenmiş satış kaç
select count(*) filter (where sozlesme_onay is not null and ilk_onay is null) as ilk_onaysiz_onayli,
       count(*) filter (where kod = 'AELK4P' and ilk_onay = '2026-10-07 23:50:37.588063+00') as aelk4p_geri_dolu
  from public.elciler;
