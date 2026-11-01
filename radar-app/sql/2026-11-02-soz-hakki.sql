-- ============================================================================
--  SÖZ HAKKI İŞARETİ ("Geçene Kadar Tetikte")  ·  02.11.2026
--
--  Cem 02.11: "Sözü 1 Kasım 23:59'a kadar alan üyelerin listesini kasadan çıkaralım ... bundan önce
--  alanlar buna dahil ... bunları ayrıca işaretleyelim, ben yönetimde göreyim; onları açılıştan sonra
--  hep açıkta tutacağız."
--
--  Dayanak: kampanya-son-20-gun.html "Yönetim Kurulu Kararı (29 Ekim 2026)" — 1 Kasım 23:59'a kadar paket
--  alan SGS ve Yeterlilik üyesine şartsız söz. Söz 02.11 00:04:59 TR'de siteden kalktı (Cem "5 dk geciktir").
--
--  NE YAPAR:
--   1) siparisler.soz_hakki (boolean, varsayılan false).
--   2) 2026-11-01 21:04:59 UTC (= 02.11 00:04:59 TR) ve öncesinde OLUŞTURULMUŞ, SGS / Yeterlilik / Son 20 Gün
--      paketli siparişler true. Durum ne olursa olsun işaretlenir; panel yalnız ÖDENMİŞ siparişte "söz" gösterir
--      (o saatten önce verilip havalesi sonra gelen sipariş, ödenince söz sahibi görünür; iptal/iade görünmez).
--   3) Tetik: o saatten sonra oluşturulan siparişte soz_hakki her zaman false (dışarıdan true yazılamaz).
--   4) yonetim_ozet = 2026-10-30-siparis-paket-durumu.sql AYNEN + siparişte 'soz', üyede 'soz' (bu e-postayla ya da
--      bu hesaba bağlı ÖDENMİŞ söz siparişi var) ve 'soz_paket' (o siparişlerin paketleri).
--
--  02.11 00:20 ölçümü (servis anahtarı, yalnız sayı): 144 siparişin 95'i ödendi, 95'i de o saatten önce;
--  sgs 54 · yeterlilik-tum 21 · yeterlilik-1 9 · yeterlilik-2 8 · yeterlilik-3 2 · yeterlilik-4 1; bağlı değil 0.
--  🚫 GÖRMEZ: hediye/elle verilmiş paketler (sipariş yok → söz yok; Cem ayrıca karar verir) · sözün şartları
--     (karar şartsız) · sınav sonucu (paket_uyeler.sinav_sonucu ayrı).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: yonetim_ozet için 2026-10-30-siparis-paket-durumu.sql tanımını yeniden bas; tetik + sütun düşürülür.
-- ============================================================================

alter table public.siparisler add column if not exists soz_hakki boolean not null default false;

update public.siparisler set soz_hakki = true
 where olusturma <= timestamptz '2026-11-01 21:04:59+00'
   and (paket in ('sgs','son20-sgs','son20-yet') or paket like 'yeterlilik-%')
   and soz_hakki = false;

create or replace function public._soz_hakki_kapi()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- söz 02.11 00:04:59 TR'de bitti: sonradan oluşan siparişe söz yazılamaz; eski siparişin işareti değiştirilemez
  if tg_op = 'INSERT' then
    if coalesce(new.olusturma, now()) > timestamptz '2026-11-01 21:04:59+00' then new.soz_hakki := false; end if;
  elsif new.soz_hakki is distinct from old.soz_hakki then
    new.soz_hakki := old.soz_hakki;
  end if;
  return new;
end
$$;
revoke all on function public._soz_hakki_kapi() from public, anon, authenticated;
drop trigger if exists soz_hakki_kapi on public.siparisler;
create trigger soz_hakki_kapi before insert or update of soz_hakki on public.siparisler
  for each row execute function public._soz_hakki_kapi();

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
        'cozdugu', (select string_agg(distinct o.sinav, ',') from public.ogrenci_sonuc o where o.user_id = u.id),
        'soz', exists (select 1 from public.siparisler s where s.soz_hakki and s.durum = 'odendi'
                        and (s.bagli_kullanici = u.id or lower(s.email) = lower(u.email))),
        'soz_paket', (select string_agg(distinct s.paket, ',') from public.siparisler s where s.soz_hakki and s.durum = 'odendi'
                        and (s.bagli_kullanici = u.id or lower(s.email) = lower(u.email)))
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
        'paket_hesap', pu.paket,
        'soz', s.soz_hakki
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
declare n int := 0; y uuid; v jsonb; b boolean; sayi int;
begin
  select user_id into y from public.yoneticiler limit 1;
  if y is null then raise exception 'OLCU: yonetici yok'; end if;

  -- 0) doldurma: o saatten önce ödenmiş SGS/Yeterlilik siparişlerinin hepsi işaretli, sonrası hiç değil
  select count(*) into sayi from public.siparisler
   where durum = 'odendi' and olusturma <= timestamptz '2026-11-01 21:04:59+00'
     and (paket in ('sgs','son20-sgs','son20-yet') or paket like 'yeterlilik-%') and not soz_hakki;
  if sayi > 0 then raise exception 'OLCU: % eski odenmis siparis isaretsiz', sayi; end if;
  if exists (select 1 from public.siparisler where soz_hakki and olusturma > timestamptz '2026-11-01 21:04:59+00')
    then raise exception 'OLCU: kesimden sonraki siparis isaretli'; end if;
  n := n + 2;

  begin
    -- 1) yeni sipariş true ile yazılsa da false olur
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, soz_hakki) values
      ('TT-20261102-SZ01', 'sgs', 2988, 'Olcu Bir', 'olcu-sz-a@tetikte.invalid', 'kart', 'odendi', true);
    select soz_hakki into b from public.siparisler where siparis_no = 'TT-20261102-SZ01';
    if b then raise exception 'OLCU: yeni siparise soz yazildi'; end if;
    -- 2) eski tarihli sipariş işaretlenir, işaret sonradan değiştirilemez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, olusturma) values
      ('TT-20261102-SZ02', 'yeterlilik-tum', 2868, 'Olcu Iki', 'olcu-sz-b@tetikte.invalid', 'kart', 'odendi', timestamptz '2026-10-31 10:00:00+00');
    update public.siparisler set soz_hakki = true where siparis_no = 'TT-20261102-SZ02';   -- tetik eski değeri korur
    select soz_hakki into b from public.siparisler where siparis_no = 'TT-20261102-SZ02';
    if b then raise exception 'OLCU: isaret sonradan degisti'; end if;
    update public.siparisler set soz_hakki = false where siparis_no = 'TT-20261102-SZ01';
    n := n + 2;

    -- 3) yonetim_ozet: siparişte soz alanı, üyede soz + soz_paket
    perform set_config('request.jwt.claims', json_build_object('sub', y::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y::text, true);
    v := public.yonetim_ozet();
    if not exists (select 1 from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261102-SZ01' and e ? 'soz' and (e->>'soz')::boolean = false)
      then raise exception 'OLCU: siparis soz alani yok/yanlis'; end if;
    select count(*) into sayi from jsonb_array_elements(v->'siparisler') e where (e->>'soz')::boolean and e->>'durum' = 'odendi';
    if sayi < 95 then raise exception 'OLCU: panelde soz siparisi % < 95', sayi; end if;
    select count(*) into sayi from jsonb_array_elements(v->'uyeler') e where (e->>'soz')::boolean;
    if sayi = 0 then raise exception 'OLCU: panelde soz uyesi yok'; end if;
    if not exists (select 1 from jsonb_array_elements(v->'uyeler') e where (e->>'soz')::boolean and coalesce(e->>'soz_paket','') <> '')
      then raise exception 'OLCU: soz_paket bos'; end if;
    if not exists (select 1 from jsonb_array_elements(v->'siparisler') e where e->>'no' = 'TT-20261102-SZ01' and e ? 'paket_durum' and e ? 'iptal_neden')
      then raise exception 'OLCU: eski alan (paket_durum) dustu'; end if;
    n := n + 4;

    -- 4) yönetici olmayan çağıramaz
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
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261102-SZ0%') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SOZ HAKKI OZ-SINAV: % vaka TAMAM', n;
end $$;
