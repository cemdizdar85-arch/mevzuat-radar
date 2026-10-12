-- ============================================================================
--  ANLIK TEKLİF 2 — iki seçenek + indirim kaynağı + sipariş kaynak etiketi  ·  12.10.2026
--
--  KARAR (Cem 12.10, "evet bunları yapalım"; "biz elçi harici nasıl satış yapacağımızı takip edeceğiz"):
--    - Teklif İKİ seçenek: (1) en zayıf ders tek ders 1.188 → 988 (−200) · (2) tüm 8 ders 3.468 → 2.868 (−600, "önerilen").
--      Ara paketler (2/3/4 ders) teklife GİRMEZ. Aynı belirteç iki seçenekte de geçerli; biri kullanılınca biter.
--    - Elçi kodu ile ÜST ÜSTE BİNMEZ; ikisi birden gelirse MÜŞTERİ LEHİNE olan TEK indirim uygulanır
--      (elçi indirimi ≥ teklif ise elçi kalır, teklif TÜKETİLMEZ; değilse teklif uygulanır, elçi kodu BOŞ kalır).
--    - Sipariş kaydında indirim kaynağı ayrı alanda: 'anlik-teklif' | 'elci:<kod>' | 'yok' (sunucu yazar, tarayıcı değil).
--      Elçi paneli/komisyon/rapor elci_kodu'ndan sayar → anlık teklif siparişi elçi satışı GİBİ GÖRÜNMEZ (öz-sınavla ölçülür).
--    - Sipariş kaynak etiketi (?k= : ig / ig-dm / gads / dm …): siparisler.kaynak_etiket. Tarayıcı cihazdaki etiketi
--      (menu.js ttKaynak, 30 gün) yollar; sunucu biçimi süzer, uymayan NULL olur (sipariş düşmez).
--      🚫 GÖRMEZ: linki bir cihazda açıp başka cihazdan alan (etiket o cihazda yok) · etiketi 30 günden eski olan.
--  Önceki göç 2026-10-12-anlik-teklif.sql uygulanmış ve kütükte; bu dosya onu DEĞİŞTİRMEZ, üstüne yazar.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
-- ============================================================================

-- 1) KOLONLAR
alter table public.siparisler add column if not exists indirim_kaynak text not null default 'yok';
alter table public.siparisler add column if not exists kaynak_etiket  text;
alter table public.anlik_teklif add column if not exists kullanilan_paket text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_indirim_kaynak_bicim') then
    alter table public.siparisler add constraint siparisler_indirim_kaynak_bicim
      check (indirim_kaynak in ('yok', 'anlik-teklif') or indirim_kaynak ~ '^elci:[A-Z0-9]{3,12}$');
  end if;
  if not exists (select 1 from pg_constraint where conname = 'siparisler_kaynak_etiket_bicim') then
    alter table public.siparisler add constraint siparisler_kaynak_etiket_bicim
      check (kaynak_etiket is null or kaynak_etiket ~ '^[a-z0-9][a-z0-9_-]{0,31}$');
  end if;
end $$;
-- geçmiş siparişler: elçili olanlar 'elci:<kod>', diğerleri 'yok' (anlık teklif dünden önce yoktu)
update public.siparisler set indirim_kaynak = case when coalesce(anlik_teklif_tl, 0) > 0 then 'anlik-teklif'
                                                   when elci_kodu is not null then 'elci:' || elci_kodu else 'yok' end
 where indirim_kaynak = 'yok' and (elci_kodu is not null or coalesce(anlik_teklif_tl, 0) > 0);

-- 2) İKİNCİ SEÇENEK: tüm dersler −600 (KDV dahil; fiyat-motoru.js ANLIK_TEKLIF.indirim ile aynı)
insert into public.anlik_teklif_ayar (paket, sinav, indirim_tl, gecerlilik_saat, acik)
values ('yeterlilik-tum', 'yeterlilik', 600, 24, true)
on conflict (paket) do update set sinav = excluded.sinav, indirim_tl = excluded.indirim_tl,
  gecerlilik_saat = excluded.gecerlilik_saat, acik = excluded.acik;

-- 3) Seçenek listesi (tek yer)
create or replace function public._anlik_teklif_secenekler(p_sinav text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object('paket', a.paket, 'indirim_tl', a.indirim_tl) order by a.indirim_tl), '[]'::jsonb)
    from anlik_teklif_ayar a where a.sinav = p_sinav and a.acik;
$$;
revoke all on function public._anlik_teklif_secenekler(text) from public, anon, authenticated;

-- 4) TEKLİF AL — aynı kurallar; dönüşe 'secenekler' eklendi ('paket'/'indirim_tl' tek ders için geriye uyumlu kalır)
create or replace function public.anlik_teklif_al(p_sonuc text, p_kaynak text, p_ders text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_ayar  anlik_teklif_ayar%rowtype;
  v_b     text;
begin
  if v_uid is null then return null; end if;
  if coalesce(p_kaynak, '') not in ('seviye', 'prova') then return null; end if;
  if coalesce(p_sonuc, '') !~ '^[A-Za-z0-9:._-]{4,80}$' then return null; end if;
  if p_ders is null or not (p_ders = any (array['Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi',
       'Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Hukuk','Sermaye Piyasası Mevzuatı','Meslek Hukuku'])) then
    return null;
  end if;
  select * into v_ayar from anlik_teklif_ayar where paket = 'yeterlilik-1' and acik;
  if not found then return null; end if;
  if exists (select 1 from anlik_teklif where user_id = v_uid and sonuc = p_sonuc) then return null; end if;
  if exists (select 1 from anlik_teklif where user_id = v_uid and ders = p_ders and kullanildi is not null) then return null; end if;
  if (select count(*) from anlik_teklif where user_id = v_uid and olusturma > now() - interval '24 hours') >= 10 then return null; end if;
  if exists (select 1 from paket_uyeler p where p.user_id = v_uid and p.bitis >= current_date
               and (p.paket in ('yeterlilik-tum', 'yeterlilik-kgk', 'tam')
                    or (p.paket ~ '^yeterlilik-[1-4]$' and p_ders = any (coalesce(p.dersler, array[]::text[]))))) then
    return null;
  end if;
  v_b := replace(gen_random_uuid()::text, '-', '');
  insert into anlik_teklif (belirtec, user_id, sonuc, kaynak, paket, ders, indirim_tl, son)
  values (v_b, v_uid, p_sonuc, p_kaynak, v_ayar.paket, p_ders, v_ayar.indirim_tl, now() + make_interval(hours => v_ayar.gecerlilik_saat))
  on conflict (user_id, sonuc) do nothing;
  if not found then return null; end if;
  return jsonb_build_object('belirtec', v_b, 'paket', v_ayar.paket, 'ders', p_ders, 'indirim_tl', v_ayar.indirim_tl,
                            'secenekler', _anlik_teklif_secenekler('yeterlilik'));
end $$;
revoke all on function public.anlik_teklif_al(text, text, text) from public;
revoke execute on function public.anlik_teklif_al(text, text, text) from anon;
grant execute on function public.anlik_teklif_al(text, text, text) to authenticated;

create or replace function public.anlik_teklif_kontrol(p_belirtec text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object('belirtec', t.belirtec, 'paket', t.paket, 'ders', t.ders, 'indirim_tl', t.indirim_tl,
                            'secenekler', _anlik_teklif_secenekler('yeterlilik'))
    from anlik_teklif t
   where t.belirtec = lower(coalesce(p_belirtec, ''))
     and auth.uid() is not null and t.user_id = auth.uid()
     and t.kullanildi is null and t.son > now()
     and not exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null);
$$;
revoke all on function public.anlik_teklif_kontrol(text) from public;
revoke execute on function public.anlik_teklif_kontrol(text) from anon;
grant execute on function public.anlik_teklif_kontrol(text) to authenticated;

-- 5) SİPARİŞ DAMGASI — iki seçenek, müşteri lehine tek indirim, indirim kaynağı + kaynak etiketi.
--    'siparis_teklif_damga' elçi damgasından SONRA koşar (alfabetik): new.indirim_tl burada elçinin damgaladığı tutardır.
create or replace function public.siparis_teklif_damga()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  t      anlik_teklif%rowtype;
  v_ind  integer;
begin
  new.anlik_teklif_tl := 0;
  new.kaynak_etiket := nullif(lower(btrim(coalesce(new.kaynak_etiket, ''))), '');
  if new.kaynak_etiket is not null and new.kaynak_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}$' then new.kaynak_etiket := null; end if;
  new.teklif_belirtec := nullif(lower(btrim(coalesce(new.teklif_belirtec, ''))), '');

  if new.teklif_belirtec is not null then
    select * into t from anlik_teklif where belirtec = new.teklif_belirtec for update;
    select a.indirim_tl into v_ind from anlik_teklif_ayar a
     where a.paket = new.paket and a.acik and a.sinav = 'yeterlilik';
    if t.belirtec is null
       or auth.uid() is null or t.user_id <> auth.uid()
       or t.kullanildi is not null
       or t.son <= now()
       or v_ind is null
       or (new.paket = 'yeterlilik-1' and not (t.ders = any (coalesce(new.secilen_dersler, array[]::text[]))))
       or exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null) then
      raise exception 'TEKLIF_GECERSIZ' using hint = 'Anlık teklif bu hesapta geçerli değil ya da kullanıldı.';
    end if;
    if coalesce(new.indirim_tl, 0) >= v_ind then
      -- elçi indirimi müşteri lehine (ya da eşit): elçi kalır, teklif tüketilmez
      new.teklif_belirtec := null;
    else
      update anlik_teklif set kullanildi = now(), siparis_no = new.siparis_no, kullanilan_paket = new.paket
       where belirtec = t.belirtec;
      new.anlik_teklif_tl := v_ind;
      new.elci_kodu := null;
      new.indirim_tl := 0;
      new.elci_sabit_komisyon_tl := null;
    end if;
  end if;

  new.indirim_kaynak := case when new.anlik_teklif_tl > 0 then 'anlik-teklif'
                             when new.elci_kodu is not null then 'elci:' || new.elci_kodu
                             else 'yok' end;
  return new;
end $$;
-- tetikleyici 2026-10-12-anlik-teklif.sql'de kurulu (aynı ad, aynı işlev)

-- 6) YÖNETİM ÖZETİ — + indirim_kaynak + kaynak_etiket
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
        'indirim_kaynak', s.indirim_kaynak, 'kaynak_etiket', s.kaynak_etiket,
        'ad', s.ad_soyad, 'eposta', s.email,
        'tarih', s.olusturma, 'odendi', s.odendi_tarihi
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

-- 7) GÖÇ İÇİ ÖZ-SINAV (geri alınır; ad/e-posta "DENEME", iz kalmaz)
--    A = alıcı, B = deneme elçisinin hesabı. Vakalar: iki seçenek döner · tüm dersler 600 damgası + elçi kodu verilse de
--    elçi BOŞ + kaynak 'anlik-teklif' + etiket taşınır · elçi-only sipariş 'elci:<kod>' + bozuk etiket NULL · indirimsiz 'yok' ·
--    elçi indirimi teklifi geçerse elçi kalır, teklif TÜKETİLMEZ · ara paket (yeterlilik-2) reddedilir · tek ders ders tutmazsa
--    reddedilir · elçi paneli yalnız elçili siparişleri sayar · ikinci kullanım reddedilir.
do $$
declare
  a constant text := '00000000-0000-4000-8000-0000000000a1';
  b constant text := '00000000-0000-4000-8000-0000000000b2';
  v jsonb; v2 jsonb; v3 jsonb; r record; p jsonb; n int;
  kim text := 'ZZTKL1';
begin
  begin
    -- aktif=false ile eklenir: elci_erisim_ver tetikleyicisi (paket_uyeler FK auth.users) sahte hesapta koşmasın; sonra açılır
    insert into public.elciler (kod, ad_soyad, aktif, ilk_onay, user_id) values (kim, 'DENEME Elci', false, now() - interval '10 days', b::uuid);
    update public.elciler set aktif = true where kod = kim;
    insert into public.elci_indirim (paket, indirim_tl) values ('yeterlilik-2', 100) on conflict (paket) do nothing;

    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a, true);

    v := public.anlik_teklif_al('olcu2-svy-1', 'seviye', 'Hukuk');
    if v is null or jsonb_array_length(v->'secenekler') <> 2 then raise exception 'OLCU2: iki secenek donmedi %', v; end if;
    if not (v->'secenekler' @> '[{"paket":"yeterlilik-tum","indirim_tl":600}]' and v->'secenekler' @> '[{"paket":"yeterlilik-1","indirim_tl":200}]') then
      raise exception 'OLCU2: secenek tutarlari yanlis %', v->'secenekler';
    end if;

    -- ara paket reddedilir
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-ZZA2', 'yeterlilik-2', 1908, array['Hukuk','Meslek Hukuku'], 'DENEME', 'deneme@tetikte.invalid', v->>'belirtec');
      raise exception 'OLCU2: ara paket kabul edildi';
    exception when others then if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if; end;

    -- tüm dersler + elçi kodu birlikte: 600 > 400 → teklif, elçi boş
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, teklif_belirtec, elci_kodu, kaynak_etiket, indirim_kaynak)
    values ('TT-20261012-ZZAA', 'yeterlilik-tum', 2868, 'DENEME', 'deneme@tetikte.invalid', v->>'belirtec', kim, 'IG-DM', 'elci:HILE');
    select * into r from public.siparisler where siparis_no = 'TT-20261012-ZZAA';
    if r.anlik_teklif_tl <> 600 or r.elci_kodu is not null or r.indirim_tl <> 0 or r.indirim_kaynak <> 'anlik-teklif' or r.kaynak_etiket <> 'ig-dm' then
      raise exception 'OLCU2: tum ders damgasi yanlis anlik=% elci=% ind=% kaynak=% etiket=%', r.anlik_teklif_tl, r.elci_kodu, r.indirim_tl, r.indirim_kaynak, r.kaynak_etiket;
    end if;
    if (select kullanilan_paket from public.anlik_teklif where belirtec = v->>'belirtec') <> 'yeterlilik-tum' then raise exception 'OLCU2: kullanilan paket yazilmadi'; end if;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-ZZAC', 'yeterlilik-1', 988, array['Hukuk'], 'DENEME', 'deneme@tetikte.invalid', v->>'belirtec');
      raise exception 'OLCU2: ikinci kullanim kabul edildi';
    exception when others then if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if; end;

    -- elçi-only: kaynak 'elci:ZZTKL1', bozuk etiket NULL
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, elci_kodu, kaynak_etiket)
    values ('TT-20261012-ZZAD', 'yeterlilik-tum', 3068, 'DENEME', 'deneme@tetikte.invalid', kim, 'Bozuk Etiket!');
    select * into r from public.siparisler where siparis_no = 'TT-20261012-ZZAD';
    if r.indirim_tl <> 400 or r.elci_kodu <> kim or r.indirim_kaynak <> 'elci:' || kim or r.kaynak_etiket is not null or r.anlik_teklif_tl <> 0 then
      raise exception 'OLCU2: elci siparisi yanlis ind=% elci=% kaynak=% etiket=%', r.indirim_tl, r.elci_kodu, r.indirim_kaynak, r.kaynak_etiket;
    end if;

    -- indirimsiz: 'yok'
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, kaynak_etiket)
    values ('TT-20261012-ZZAE', 'yeterlilik-tum', 3468, 'DENEME', 'deneme@tetikte.invalid', 'gads');
    select * into r from public.siparisler where siparis_no = 'TT-20261012-ZZAE';
    if r.indirim_kaynak <> 'yok' or r.kaynak_etiket <> 'gads' then raise exception 'OLCU2: indirimsiz kaynak yanlis %', r.indirim_kaynak; end if;

    -- elçi indirimi teklifi geçerse elçi kalır, teklif tüketilmez (geçici: elçi tüm derslerde 700)
    v2 := public.anlik_teklif_al('olcu2-prova-2', 'prova', 'Meslek Hukuku');
    if v2 is null then raise exception 'OLCU2: ikinci teklif uretilmedi'; end if;
    update public.elci_indirim set indirim_tl = 700 where paket = 'yeterlilik-tum';
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, teklif_belirtec, elci_kodu)
    values ('TT-20261012-ZZAF', 'yeterlilik-tum', 2768, 'DENEME', 'deneme@tetikte.invalid', v2->>'belirtec', kim);
    select * into r from public.siparisler where siparis_no = 'TT-20261012-ZZAF';
    if r.indirim_tl <> 700 or r.elci_kodu <> kim or r.anlik_teklif_tl <> 0 or r.teklif_belirtec is not null or r.indirim_kaynak <> 'elci:' || kim then
      raise exception 'OLCU2: musteri lehine kural yanlis ind=% elci=% anlik=%', r.indirim_tl, r.elci_kodu, r.anlik_teklif_tl;
    end if;
    if (select kullanildi from public.anlik_teklif where belirtec = v2->>'belirtec') is not null then raise exception 'OLCU2: kaybeden teklif tuketildi'; end if;

    -- tek ders: ders tutmazsa reddedilir; tutarsa 200
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-ZZAH', 'yeterlilik-1', 988, array['Hukuk'], 'DENEME', 'deneme@tetikte.invalid', v2->>'belirtec');
      raise exception 'OLCU2: ders tutmayan tek ders kabul edildi';
    exception when others then if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if; end;
    insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
    values ('TT-20261012-ZZAJ', 'yeterlilik-1', 988, array['Meslek Hukuku'], 'DENEME', 'deneme@tetikte.invalid', v2->>'belirtec');
    if (select anlik_teklif_tl from public.siparisler where siparis_no = 'TT-20261012-ZZAJ') <> 200 then raise exception 'OLCU2: tek ders 200 damgalanmadi'; end if;

    -- elçi paneli (B): yalnız elçili iki sipariş (ZZAD, ZZAF) ödeme bekliyor; teklifli ZZAA sayılmaz
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b, true);
    p := public.elci_panelim();
    if p is null or (p->>'odeme_bekleyen')::int <> 2 then raise exception 'OLCU2: elci paneli yanlis sayiyor %', p->>'odeme_bekleyen'; end if;
    -- komisyon yalnız elçili: ZZAA ödenmiş sayılsa da panel komisyonu değişmez
    update public.siparisler set durum = 'odendi' where siparis_no in ('TT-20261012-ZZAA', 'TT-20261012-ZZAD');
    p := public.elci_panelim();
    if (p->>'bekleyen_satis')::int <> 1 or (p->>'komisyon_tahmini')::int <> public.elci_komisyon(1, 1::smallint) then
      raise exception 'OLCU2: komisyon anlik teklifi saydi bekleyen=% komisyon=%', p->>'bekleyen_satis', p->>'komisyon_tahmini';
    end if;
    select count(*) into n from public.siparisler where elci_kodu = kim;
    if n <> 2 then raise exception 'OLCU2: elci_kodu ile % siparis (2 beklenir)', n; end if;

    raise exception 'OLCU2_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU2_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261012-ZZ%')
     or exists (select 1 from public.anlik_teklif where sonuc like 'olcu2-%')
     or exists (select 1 from public.elciler where kod = 'ZZTKL1')
     or (select indirim_tl from public.elci_indirim where paket = 'yeterlilik-tum') <> 400 then
    raise exception 'OLCU2: geri alma iz birakti';
  end if;
  raise notice 'ANLIK TEKLIF 2 OZ-SINAV: 14 vaka TAMAM (geri alindi)';
end $$;
