-- ============================================================================
--  ÖDENMEYEN SİPARİŞ OTOMATİK İPTAL + GEÇ HAVALE AÇILIR  ·  29.10.2026 (site kolu)
--
--  CEM 29.10: "büyük firmalar ne yapıyorsa onu yap, ödeme sorunu / bekleyen istemiyorum" → seçim "Robot mail + otomatik
--  iptal". Ölçüm (29.10): ödeme bekleyen 25 havale siparişi, en eskisi 07.10; süresiz "ödeme bekliyor"da kalıyorlardı.
--  NE YAPAR:
--    1) siparisler +iptal_neden ('otomatik' | null = elle) +iptal_zaman.
--    2) siparis_otomatik_iptal(p_nolar) — YALNIZ servis (motor/siparis-son-hatirlatma.mjs): listedeki siparişlerden
--       hâlâ 'odeme_bekliyor' olanları 'iptal' + iptal_neden 'otomatik' yapar, kaç tane yaptığını döner. Hangi siparişin
--       iptal edileceğine betik karar verir (72 saat + son hatırlatmadan 24 saat sonra; öz-sınavı orada).
--    3) yonetim_siparis_onayla: 'iptal' + iptal_neden 'otomatik' siparişi de "Ödendi, paketi aç" yapar (iptalden sonra
--       gelen havale kaybolmasın). Elle iptal edilen sipariş eskisi gibi DURUM_IPTAL. Gövdenin geri kalanı
--       2026-10-05-otomatik-paket.sql AYNEN.
--    4) yonetim_ozet: 2026-10-19-ozel-indirim-kodu.sql AYNEN + siparişte 'iptal_neden' (panel düğmesi için).
--  🚫 GÖRMEZ: kartla ödeme (iyzico ?islem=baslat) otomatik iptal edilmiş siparişte başlamaz — kişi yeniden sipariş verir ·
--     iptalden sonra gelen havaleyi panelde birinin görüp "Ödendi" demesi gerekir (havale eşleşmesi zaten elle).
--  GERİ ALMA: 2026-10-05-otomatik-paket.sql yonetim_siparis_onayla + 2026-10-19-ozel-indirim-kodu.sql yonetim_ozet yeniden
--     çalıştırılır; drop function public.siparis_otomatik_iptal(text[]); kolonlar kalabilir (boş).
-- ============================================================================

alter table public.siparisler add column if not exists iptal_neden text;
alter table public.siparisler add column if not exists iptal_zaman timestamptz;

create or replace function public.siparis_otomatik_iptal(p_nolar text[])
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update public.siparisler set durum = 'iptal', iptal_neden = 'otomatik', iptal_zaman = now()
   where siparis_no = any(coalesce(p_nolar, '{}')) and durum = 'odeme_bekliyor';
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.siparis_otomatik_iptal(text[]) from public, anon, authenticated;
grant execute on function public.siparis_otomatik_iptal(text[]) to service_role;

-- yonetim_siparis_onayla: 2026-10-05-otomatik-paket.sql AYNEN + otomatik iptal edilmiş sipariş de açılır
create or replace function public.yonetim_siparis_onayla(p_no text, p_bitis date)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_sonuc text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' and not (s.durum = 'iptal' and s.iptal_neden = 'otomatik') then
    raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'odendi', paket_bitis = p_bitis where id = s.id;   -- odendi_tarihi tetikleyicide

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'BEKLIYOR', 'eposta', s.email,
      'not', s.email || ' henüz üye değil. Bu e-postayla üye olduğu anda paketi KENDİLİĞİNDEN açılır.');
  end if;
  v_sonuc := public.siparis_paket_bagla(v_uid, s.email);
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', p_bitis, 'eposta', s.email, 'sonuc', v_sonuc);
end $$;
revoke all on function public.yonetim_siparis_onayla(text, date) from public, anon;
grant execute on function public.yonetim_siparis_onayla(text, date) to authenticated;

-- YÖNETİM ÖZETİ — 2026-10-19-ozel-indirim-kodu.sql AYNEN + siparişte 'iptal_neden'
create or replace function public.yonetim_ozet()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare sonuc jsonb;
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'olcum', now(),
    'uyeler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'eposta', u.email,
        'kayit', u.created_at,
        'son_giris', u.last_sign_in_at,
        'yol', coalesce(u.raw_user_meta_data->>'kaynak', 'site'),
        'kayit_elci', nullif(u.raw_user_meta_data->>'elci_kodu', ''),
        'paket', p.paket,
        'bitis', p.bitis,
        'dersler', p.dersler,
        'hediye', exists (select 1 from public.paket_hediye h where h.user_id = u.id and h.iptal is null),
        'siparis_elci', (select s.elci_kodu from public.siparisler s
                          where lower(s.email) = lower(u.email) and s.elci_kodu is not null
                          order by s.olusturma desc limit 1),
        'siparis_paket', (select s.paket from public.siparisler s
                           where lower(s.email) = lower(u.email) order by s.olusturma desc limit 1),
        'cozdugu', (select string_agg(distinct o.sinav, ',') from public.ogrenci_sonuc o where o.user_id = u.id)
      ) order by u.created_at desc)
      from auth.users u
      left join public.paket_uyeler p on p.user_id = u.id
    ), '[]'::jsonb),
    'siparisler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'no', s.siparis_no, 'paket', s.paket, 'tutar', s.tutar, 'durum', s.durum,
        'elci', s.elci_kodu, 'indirim', s.indirim_tl, 'anlik_teklif', s.anlik_teklif_tl,
        'ozel_kod', s.ozel_kod, 'ozel_kod_tl', s.ozel_kod_tl,
        'indirim_kaynak', s.indirim_kaynak, 'kaynak_etiket', s.kaynak_etiket,
        'ad', s.ad_soyad, 'eposta', s.email,
        'tarih', s.olusturma, 'odendi', s.odendi_tarihi,
        'iptal_neden', s.iptal_neden
      ) order by s.olusturma desc)
      from public.siparisler s
    ), '[]'::jsonb),
    'elciler', coalesce((
      select jsonb_agg(jsonb_build_object('kod', e.kod, 'ad', e.ad_soyad, 'aktif', e.aktif) order by e.olusturma)
      from public.elciler e
    ), '[]'::jsonb)
  ) into sonuc;
  return sonuc;
end
$$;
revoke all on function public.yonetim_ozet() from public, anon;
grant execute on function public.yonetim_ozet() to authenticated;

-- ÖZ-SINAV: uçtan uca, sonunda her şey geri alınır (OLCU_TAMAM ile bilerek düşülür)
do $$
declare n int := 0; y uuid; v jsonb; k int;
begin
  select user_id into y from public.yoneticiler limit 1;
  if y is null then raise exception 'OLCU: yonetici yok, onay sinanamaz'; end if;
  begin
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261029-K201', 'sgs', 2388, 'Olcu Bir', 'olcu-oi-a@tetikte.invalid', 'havale', 'odeme_bekliyor'),
      ('TT-20261029-K202', 'sgs', 2388, 'Olcu Iki', 'olcu-oi-b@tetikte.invalid', 'havale', 'odeme_bekliyor'),
      ('TT-20261029-K203', 'sgs', 2388, 'Olcu Uc',  'olcu-oi-c@tetikte.invalid', 'havale', 'odeme_bekliyor');
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261029-K203';

    -- 1) yalnız listedeki ve hâlâ bekleyen iptal olur
    k := public.siparis_otomatik_iptal(array['TT-20261029-K201', 'TT-20261029-K203', 'TT-20261029-YOKK']);
    if k <> 1 then raise exception 'OLCU: iptal sayisi 1 degil (%)', k; end if;
    if (select durum || '/' || coalesce(iptal_neden, '-') from public.siparisler where siparis_no = 'TT-20261029-K201') <> 'iptal/otomatik'
      then raise exception 'OLCU: Q201 otomatik iptal olmadi'; end if;
    if (select iptal_zaman from public.siparisler where siparis_no = 'TT-20261029-K201') is null then raise exception 'OLCU: iptal_zaman bos'; end if;
    if (select durum from public.siparisler where siparis_no = 'TT-20261029-K202') <> 'odeme_bekliyor' then raise exception 'OLCU: listede olmayan iptal oldu'; end if;
    if (select durum from public.siparisler where siparis_no = 'TT-20261029-K203') <> 'odendi' then raise exception 'OLCU: odenmis siparis iptal oldu'; end if;
    if public.siparis_otomatik_iptal(null) <> 0 then raise exception 'OLCU: bos liste iptal etti'; end if;
    n := n + 6;

    -- 2) panel: otomatik iptal edilen açılır, elle iptal edilen açılmaz
    perform set_config('request.jwt.claims', json_build_object('sub', y::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);
    v := public.yonetim_siparis_onayla('TT-20261029-K201', current_date + 30);
    if v->>'siparis' <> 'odendi' or v->>'paket' <> 'BEKLIYOR' then raise exception 'OLCU: otomatik iptal acilmadi %', v; end if;
    if (select durum from public.siparisler where siparis_no = 'TT-20261029-K201') <> 'odendi' then raise exception 'OLCU: Q201 odendi olmadi'; end if;
    update public.siparisler set durum = 'iptal' where siparis_no = 'TT-20261029-K202';   -- elle iptal (neden yok)
    begin
      perform public.yonetim_siparis_onayla('TT-20261029-K202', current_date + 30);
      raise exception 'OLCU: elle iptal edilen acildi';
    exception when others then if sqlerrm not like 'DURUM_IPTAL%' then raise; end if; end;
    begin
      perform public.yonetim_siparis_onayla('TT-20261029-K203', current_date + 30);
      raise exception 'OLCU: odenmis siparis ikinci kez onaylandi';
    exception when others then if sqlerrm not like 'DURUM_ODENDI%' then raise; end if; end;
    n := n + 4;

    -- 3) panel özeti iptal_neden taşır
    v := public.yonetim_ozet();
    if not exists (select 1 from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261029-K202' and e ? 'iptal_neden')
      then raise exception 'OLCU: yonetim_ozet iptal_neden tasimiyor'; end if;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261029-K20%') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'OTOMATIK IPTAL OZ-SINAV: % vaka TAMAM', n;
end $$;
