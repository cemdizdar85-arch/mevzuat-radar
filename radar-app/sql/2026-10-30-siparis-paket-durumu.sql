-- ============================================================================
--  YÖNETİM: SİPARİŞ SATIRINDA PAKET AÇIK MI / KAPALI MI  ·  30.10.2026
--
--  Cem 30.10 (TT-20261030-5HXJ için): "bunun ödemesini aldık, açıldı mı, nasıl göreceğim,
--  bunu da ekle siteye, açıldı kapalı görelim". Sipariş tablosu yalnız "ödendi" yazıyordu;
--  ödenmiş siparişin paketi hesaba bağlandı mı, bugün açık mı görünmüyordu.
--
--  NE YAPAR: yonetim_ozet — 2026-10-29-otomatik-iptal.sql AYNEN + her siparişte:
--    'paket_durum' : 'acik'        → sipariş bir hesaba bağlı, o hesabın paketi bugün açık
--                    'bitti'       → hesaba bağlı, paketin bitişi geçmiş
--                    'yok'         → hesaba bağlı ama hesapta paket kaydı yok (kapatılmış/iptal)
--                    'bagli_degil' → ödendi ama hiçbir hesaba bağlanmadı (alıcı o e-postayla hesap açmadı)
--                    'odeme_yok'   → sipariş ödenmemiş / iptal / iade
--    'paket_bitis' : hesaptaki paketin bitişi (bağlıysa)
--    'paket_hesap' : hesaptaki paketin adı (siparişteki paketten farklı olabilir: yükseltme, hediye)
--
--  🚫 GÖRMEZ: hesaptaki paketin BU siparişten mi yoksa başka bir siparişten/hediyeden mi açıldığı
--     (paket_uyeler hesap başına tek satır) · ders ders paketlerde siparişteki derslerin hepsinin hesapta
--     olup olmadığı (yalnız paket kaydı var/yok + bitiş).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: 2026-10-29-otomatik-iptal.sql içindeki yonetim_ozet tanımını yeniden bas.
-- ============================================================================

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
        'iptal_neden', s.iptal_neden,
        'paket_durum', case
            when s.durum <> 'odendi' then 'odeme_yok'
            when s.bagli_kullanici is null then 'bagli_degil'
            when pu.user_id is null then 'yok'
            when pu.bitis is not null and pu.bitis < current_date then 'bitti'
            else 'acik' end,
        'paket_bitis', pu.bitis,
        'paket_hesap', pu.paket
      ) order by s.olusturma desc)
      from public.siparisler s
      left join public.paket_uyeler pu on pu.user_id = s.bagli_kullanici
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

-- ÖZ-SINAV: sonunda her şey geri alınır (OLCU_TAMAM ile bilerek düşülür)
do $$
declare n int := 0; y uuid; v jsonb; pd text; gercek text;
begin
  select user_id into y from public.yoneticiler limit 1;
  if y is null then raise exception 'OLCU: yonetici yok'; end if;
  begin
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261030-PD01', 'sgs', 2388, 'Olcu Bir', 'olcu-pd-a@tetikte.invalid', 'havale', 'odeme_bekliyor'),
      ('TT-20261030-PD02', 'sgs', 2388, 'Olcu Iki', 'olcu-pd-b@tetikte.invalid', 'kart', 'odendi');

    perform set_config('request.jwt.claims', json_build_object('sub', y::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);
    v := public.yonetim_ozet();

    -- 1) ödenmemiş → odeme_yok
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD01';
    if pd is distinct from 'odeme_yok' then raise exception 'OLCU: PD01 odeme_yok degil (%)', pd; end if;
    -- 2) ödendi, hesaba bağlı değil → bagli_degil
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD02';
    if pd is distinct from 'bagli_degil' then raise exception 'OLCU: PD02 bagli_degil degil (%)', pd; end if;
    n := n + 2;

    -- 3) ödendi + bağlı + açık paket: yöneticinin kendi hesabına bağla, paket satırını geçici kur
    delete from public.paket_uyeler where user_id = y;   -- geri alınır
    update public.siparisler set bagli_kullanici = y where siparis_no = 'TT-20261030-PD02';
    v := public.yonetim_ozet();
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD02';
    if pd is distinct from 'yok' then raise exception 'OLCU: paketsiz hesap yok degil (%)', pd; end if;
    insert into public.paket_uyeler (user_id, paket, bitis) values (y, 'sgs', current_date + 30);
    v := public.yonetim_ozet();
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD02';
    if pd is distinct from 'acik' then raise exception 'OLCU: acik degil (%)', pd; end if;
    if not exists (select 1 from jsonb_array_elements(v->'siparisler') e
                   where e->>'no' = 'TT-20261030-PD02' and (e->>'paket_bitis')::date = current_date + 30 and e->>'paket_hesap' = 'sgs')
      then raise exception 'OLCU: paket_bitis/paket_hesap tasinmiyor'; end if;
    update public.paket_uyeler set bitis = current_date - 1 where user_id = y;
    v := public.yonetim_ozet();
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD02';
    if pd is distinct from 'bitti' then raise exception 'OLCU: bitti degil (%)', pd; end if;
    n := n + 4;

    -- 4) iptal → odeme_yok; eski alanlar duruyor
    update public.siparisler set durum = 'iptal' where siparis_no = 'TT-20261030-PD02';
    v := public.yonetim_ozet();
    select e->>'paket_durum' into pd from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD02';
    if pd is distinct from 'odeme_yok' then raise exception 'OLCU: iptal odeme_yok degil (%)', pd; end if;
    if not exists (select 1 from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-PD01'
                   and e ? 'iptal_neden' and e ? 'kaynak_etiket' and e ? 'ozel_kod_tl') then raise exception 'OLCU: eski alan dustu'; end if;
    if jsonb_array_length(v->'uyeler') = 0 then raise exception 'OLCU: uyeler bos'; end if;
    n := n + 2;

    -- 5) gerçek sipariş (Cem'in sorduğu): TT-20261030-5HXJ açık olmalı
    select e->>'paket_durum' into gercek from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261030-5HXJ';
    if gercek is distinct from 'acik' then raise exception 'OLCU: 5HXJ acik degil (%)', gercek; end if;
    n := n + 1;

    -- 6) yönetici olmayan çağıramaz
    perform set_config('request.jwt.claims', json_build_object('sub', gen_random_uuid()::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', (current_setting('request.jwt.claims')::json->>'sub'), true);
    begin
      perform public.yonetim_ozet();
      raise exception 'OLCU: yonetici olmayan okudu';
    exception when others then if sqlerrm not like 'YETKI_YOK%' then raise; end if; end;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261030-PD0%') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SIPARIS PAKET DURUMU OZ-SINAV: % vaka TAMAM', n;
end $$;
