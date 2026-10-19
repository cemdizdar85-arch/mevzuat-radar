-- ============================================================================
--  ÖZEL İNDİRİM KODU — yönetimden kişiye verilen, tek kullanımlık indirim  ·  19.10.2026
--
--  KARAR (Cem 19.10): "birisine 600 TL indirim vermem lazım" → "hem yeterlilik hem SGS için bir kod yapabiliriz".
--    Seçimler: tek kişi, tek kullanım · Yeterlilik'te YALNIZ tüm dersler · süre panelde gün olarak seçilir (vars. 7).
--    Paketler: 'sgs' (Staja Giriş) + 'yeterlilik-tum'. Tutar panelde yazılır (vars. 600, KDV dahil, en çok 1.000).
--
--  TASARIM (elçi kodu + anlık teklif ilkesi: istemcideki hiçbir şey güvenlik değildir):
--    - Kod SUNUCUDA üretilir (yonetim_ozel_kod_uret, yalnız yönetici): 'OZ' + 6 karışmayan karakter (OZ7K4MPX).
--      Elçi kodlarıyla (6 karakter) ve davet kodlarıyla (TT….) çakışmaz; üretimde elciler tablosu da sınanır.
--    - Tarayıcı yalnız "bu kod bu pakette kaç TL indirir?" diye sorar (ozel_kod_kontrol, kişisel veri dönmez).
--    - Sipariş yazılırken siparis_teklif_damga (indirimin SON durağı) kodu kilitler, yeniden sınar, ozel_kod_tl'yi
--      KENDİSİ damgalar, kodu kullanıldı işaretler. Geçersiz kod → 'OZEL_KOD_GECERSIZ' (sessizce indirimsiz yazılmaz:
--      ekranda 2.868 görüp 3.468 borçlanmasın).
--    - Tek kullanım: kod bir siparişe bağlanınca biter. O sipariş İPTAL edilirse (ödeme gelmedi) kod yeniden geçerli olur
--      — alıcı ödemeden vazgeçip yeniden sipariş verince kod yanmasın. İade edilen siparişte kod geri gelmez.
--    - Elçi kodu / anlık teklifle ÜST ÜSTE BİNMEZ: müşteri lehine TEK indirim. Eşitlikte kod kalır (elçi > özel > teklif);
--      kaybeden kod ya da teklif TÜKETİLMEZ.
--    - İndirim siparişte AYRI kolonda: siparisler.ozel_kod + ozel_kod_tl; indirim_kaynak 'ozel:<KOD>'.
--      Elçi paneli / komisyon / rapor elci_kodu'ndan sayar → özel kodlu satış elçi satışı GİBİ GÖRÜNMEZ.
--      iyzico-odeme.ts beklenen tutara bu kolonu da düşer (aynı commit).
--
--  🚫 GÖRMEZ: kodu kimin kullandığı (kişiye bağlı değil; Cem "tek kişi, tek kullanım" seçti — kod başkasına geçerse yine
--     yalnız BİR sipariş indirimli olur) · aynı kişinin iki kodla iki sipariş vermesi (yönetici kaç kod ürettiğini görür).
--  ⚠ Paket listesi fiyat-motoru.js OZEL_KOD.paketler ile AYNI olmalı (ekran yazısı oradan).
--  Push ile otomatik uygulanır (sql-uygula.yml). Tekrar basımı güvenli (if not exists / create or replace).
--  GERİ ALMA: 2026-10-12-anlik-teklif-2.sql'deki siparis_teklif_damga + yonetim_ozet yeniden basılır;
--             drop function ozel_kod_kontrol, yonetim_ozel_kod_uret, yonetim_ozel_kodlar, yonetim_ozel_kod_iptal
--             (kolonlar ve tablo kayıt olarak kalır).
-- ============================================================================

-- 1) SİPARİŞTE AYRI ALAN + indirim kaynağına 'ozel:<KOD>'
alter table public.siparisler add column if not exists ozel_kod    text;
alter table public.siparisler add column if not exists ozel_kod_tl integer not null default 0;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_ozel_kod_tl_aralik') then
    alter table public.siparisler add constraint siparisler_ozel_kod_tl_aralik check (ozel_kod_tl between 0 and 5000);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'siparisler_ozel_kod_bicim') then
    alter table public.siparisler add constraint siparisler_ozel_kod_bicim
      check (ozel_kod is null or ozel_kod ~ '^OZ[ACDEFHJKLMNPRTUVXYZ2345679]{6}$');
  end if;
end $$;
alter table public.siparisler drop constraint if exists siparisler_indirim_kaynak_bicim;
alter table public.siparisler add constraint siparisler_indirim_kaynak_bicim
  check (indirim_kaynak in ('yok', 'anlik-teklif')
         or indirim_kaynak ~ '^elci:[A-Z0-9]{3,12}$'
         or indirim_kaynak ~ '^ozel:OZ[ACDEFHJKLMNPRTUVXYZ2345679]{6}$');

-- 2) KODLAR
create table if not exists public.ozel_kod (
  kod         text primary key check (kod ~ '^OZ[ACDEFHJKLMNPRTUVXYZ2345679]{6}$'),
  indirim_tl  integer not null check (indirim_tl between 1 and 1000),
  paketler    text[] not null check (array_length(paketler, 1) between 1 and 5),
  son         timestamptz not null,
  kime        text not null check (length(kime) between 2 and 120),
  olusturan   uuid,
  olusturma   timestamptz not null default now(),
  kullanildi  timestamptz,
  siparis_no  text,
  iptal       timestamptz
);
alter table public.ozel_kod enable row level security;
revoke all on public.ozel_kod from anon, authenticated;

-- 3) GEÇERLİLİK (tek yer): süre · iptal · paket · kullanılmamış ya da bağlı siparişi iptal → indirim TL, değilse NULL
create or replace function public._ozel_kod_gecerli(p_kod text, p_paket text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select o.indirim_tl
    from ozel_kod o
   where o.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
     and o.iptal is null
     and o.son > now()
     and p_paket = any (o.paketler)
     and (o.kullanildi is null
          or not exists (select 1 from siparisler s where s.siparis_no = o.siparis_no and s.durum <> 'iptal'));
$$;
revoke all on function public._ozel_kod_gecerli(text, text) from public, anon, authenticated;

-- 4) TARAYICININ SORABİLECEĞİ TEK SORU: "bu kod bu pakette kaç TL indirir?" (geçersiz → 0)
create or replace function public.ozel_kod_kontrol(p_kod text, p_paket text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public._ozel_kod_gecerli(p_kod, p_paket), 0);
$$;
revoke all on function public.ozel_kod_kontrol(text, text) from public;
grant execute on function public.ozel_kod_kontrol(text, text) to anon, authenticated;

-- 5) SİPARİŞ DAMGASI — 2026-10-12-anlik-teklif-2.sql AYNEN + özel kod. Müşteri lehine TEK indirim:
--    teklif yalnız elçiden VE özel koddan büyükse kazanır; özel kod elçiden büyükse kazanır; yoksa elçi (ya da hiç).
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
  v_t    integer := 0;
  v_o    integer := 0;
  v_e    integer;
begin
  new.anlik_teklif_tl := 0;
  new.ozel_kod_tl := 0;
  new.kaynak_etiket := nullif(lower(btrim(coalesce(new.kaynak_etiket, ''))), '');
  if new.kaynak_etiket is not null and new.kaynak_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}$' then new.kaynak_etiket := null; end if;
  new.teklif_belirtec := nullif(lower(btrim(coalesce(new.teklif_belirtec, ''))), '');
  new.ozel_kod := nullif(upper(regexp_replace(coalesce(new.ozel_kod, ''), '[^A-Za-z0-9]', '', 'g')), '');
  v_e := coalesce(new.indirim_tl, 0);

  -- anlık teklif adayı (kurallar 12.10 ile aynı)
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
    v_t := v_ind;
  end if;

  -- özel kod adayı: önce satırı kilitle (aynı anda iki sipariş aynı kodu alamasın), sonra yeniden sına
  if new.ozel_kod is not null then
    perform 1 from ozel_kod where kod = new.ozel_kod for update;
    v_o := public._ozel_kod_gecerli(new.ozel_kod, new.paket);
    if v_o is null then
      raise exception 'OZEL_KOD_GECERSIZ' using hint = 'Özel indirim kodu bu pakette geçerli değil, süresi geçmiş ya da kullanılmış.';
    end if;
  end if;

  if v_t > v_e and v_t > v_o then
    update anlik_teklif set kullanildi = now(), siparis_no = new.siparis_no, kullanilan_paket = new.paket
     where belirtec = t.belirtec;
    new.anlik_teklif_tl := v_t;
    new.ozel_kod := null;
    new.elci_kodu := null;
    new.indirim_tl := 0;
    new.elci_sabit_komisyon_tl := null;
  elsif v_o > v_e then
    update ozel_kod set kullanildi = now(), siparis_no = new.siparis_no where kod = new.ozel_kod;
    new.ozel_kod_tl := v_o;
    new.teklif_belirtec := null;
    new.elci_kodu := null;
    new.indirim_tl := 0;
    new.elci_sabit_komisyon_tl := null;
  else
    -- elçi indirimi müşteri lehine (ya da eşit) ya da hiç indirim yok: teklif ve kod TÜKETİLMEZ
    new.teklif_belirtec := null;
    new.ozel_kod := null;
  end if;

  new.indirim_kaynak := case when new.anlik_teklif_tl > 0 then 'anlik-teklif'
                             when new.ozel_kod_tl > 0 then 'ozel:' || new.ozel_kod
                             when new.elci_kodu is not null then 'elci:' || new.elci_kodu
                             else 'yok' end;
  return new;
end $$;
-- tetikleyici 2026-10-12-anlik-teklif.sql'de kurulu (aynı ad, aynı işlev)

-- 6) YÖNETİM: kod üret · listele · iptal
create or replace function public.yonetim_ozel_kod_uret(p_kime text, p_gun integer, p_indirim integer)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  abc constant text := 'ACDEFHJKLMNPRTUVXYZ2345679';
  v_kod text; v_b bytea; i int; n int := 0; v_son timestamptz;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if length(btrim(coalesce(p_kime, ''))) not between 2 and 120 then raise exception 'KIME_GEREKLI'; end if;
  if coalesce(p_gun, 0) not between 1 and 90 then raise exception 'GUN_GECERSIZ'; end if;
  if coalesce(p_indirim, 0) not between 1 and 1000 then raise exception 'INDIRIM_GECERSIZ'; end if;
  loop
    n := n + 1;
    if n > 20 then raise exception 'KOD_URETILEMEDI'; end if;
    v_b := decode(replace(gen_random_uuid()::text, '-', ''), 'hex');
    v_kod := 'OZ';
    for i in 0..5 loop
      v_kod := v_kod || substr(abc, (get_byte(v_b, i) % length(abc)) + 1, 1);
    end loop;
    exit when not exists (select 1 from ozel_kod where kod = v_kod)
          and not exists (select 1 from elciler where kod = v_kod);
  end loop;
  v_son := date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'
           + make_interval(days => p_gun + 1) - interval '1 second';   -- son günün 23:59:59'u (TR)
  insert into ozel_kod (kod, indirim_tl, paketler, son, kime, olusturan)
  values (v_kod, p_indirim, array['sgs', 'yeterlilik-tum'], v_son, btrim(p_kime), auth.uid());
  return jsonb_build_object('kod', v_kod, 'indirim_tl', p_indirim, 'paketler', array['sgs', 'yeterlilik-tum'], 'son', v_son, 'kime', btrim(p_kime));
end $$;
revoke all on function public.yonetim_ozel_kod_uret(text, integer, integer) from public, anon;
grant execute on function public.yonetim_ozel_kod_uret(text, integer, integer) to authenticated;

create or replace function public.yonetim_ozel_kodlar()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kod', o.kod, 'kime', o.kime, 'indirim_tl', o.indirim_tl, 'paketler', o.paketler, 'son', o.son,
             'olusturma', o.olusturma, 'kullanildi', o.kullanildi, 'siparis_no', o.siparis_no, 'iptal', o.iptal,
             'siparis_durum', (select s.durum from siparisler s where s.siparis_no = o.siparis_no),
             'siparis_paket', (select s.paket from siparisler s where s.siparis_no = o.siparis_no),
             'gecerli', public._ozel_kod_gecerli(o.kod, o.paketler[1]) is not null
           ) order by o.olusturma desc)
      from ozel_kod o
     where o.olusturma > now() - interval '180 days'
  ), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_ozel_kodlar() from public, anon;
grant execute on function public.yonetim_ozel_kodlar() to authenticated;

create or replace function public.yonetim_ozel_kod_iptal(p_kod text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare v_kod text := upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update ozel_kod set iptal = now() where kod = v_kod and iptal is null;
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', v_kod);
end $$;
revoke all on function public.yonetim_ozel_kod_iptal(text) from public, anon;
grant execute on function public.yonetim_ozel_kod_iptal(text) to authenticated;

-- 7) YÖNETİM ÖZETİ — 2026-10-12-anlik-teklif-2.sql AYNEN + siparişte 'ozel_kod' / 'ozel_kod_tl'
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

-- 8) GÖÇ İÇİ ÖZ-SINAV (geri alınır; ad/e-posta "DENEME", iz kalmaz). Bir vaka tutmazsa göç KIRMIZI düşer, hiçbir şey uygulanmaz.
--    A = alıcı, Y = deneme yöneticisi, B = deneme elçisinin hesabı.
do $$
declare
  a constant text := '00000000-0000-4000-8000-0000000000a1';
  y constant text := '00000000-0000-4000-8000-0000000000c3';
  b constant text := '00000000-0000-4000-8000-0000000000b2';
  kim text := 'ZZOZK1';
  k1 jsonb; k2 jsonb; k3 jsonb; v jsonb; r record; l jsonb; n int := 0;
  kod1 text; kod2 text; kod3 text;
begin
  begin
    insert into public.yoneticiler (user_id) values (y::uuid) on conflict do nothing;
    insert into public.elciler (kod, ad_soyad, aktif, ilk_onay, user_id) values (kim, 'DENEME Elci', false, now() - interval '10 days', b::uuid);
    update public.elciler set aktif = true where kod = kim;

    -- 1) yönetici olmayan kod üretemez
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a, true);
    begin
      perform public.yonetim_ozel_kod_uret('DENEME Kisi', 7, 600);
      raise exception 'OLCU3: yonetici olmayan kod uretti';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    n := n + 1;

    -- 2) yönetici üretir: biçim, tutar, paketler, son gün
    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y, true);
    k1 := public.yonetim_ozel_kod_uret('DENEME Kisi 1', 7, 600);
    k2 := public.yonetim_ozel_kod_uret('DENEME Kisi 2', 7, 600);
    k3 := public.yonetim_ozel_kod_uret('DENEME Kisi 3', 1, 600);
    kod1 := k1->>'kod'; kod2 := k2->>'kod'; kod3 := k3->>'kod';
    if kod1 !~ '^OZ[ACDEFHJKLMNPRTUVXYZ2345679]{6}$' or (k1->>'indirim_tl')::int <> 600 or kod1 = kod2 then raise exception 'OLCU3: uretim yanlis %', k1; end if;
    if (k1->>'son')::timestamptz < now() + interval '6 days' or (k1->>'son')::timestamptz > now() + interval '8 days' then raise exception 'OLCU3: son tarih yanlis %', k1->>'son'; end if;
    begin perform public.yonetim_ozel_kod_uret('', 7, 600); raise exception 'OLCU3: kimsiz kod uretildi';
    exception when others then if sqlerrm not like '%KIME_GEREKLI%' then raise; end if; end;
    begin perform public.yonetim_ozel_kod_uret('DENEME', 0, 600); raise exception 'OLCU3: 0 gunluk kod uretildi';
    exception when others then if sqlerrm not like '%GUN_GECERSIZ%' then raise; end if; end;
    n := n + 3;

    -- 3) kontrol: iki pakette 600, tek derste 0, küçük harf/tire normalize, uydurma 0
    if public.ozel_kod_kontrol(kod1, 'sgs') <> 600 or public.ozel_kod_kontrol(kod1, 'yeterlilik-tum') <> 600 then raise exception 'OLCU3: kontrol 600 donmedi'; end if;
    if public.ozel_kod_kontrol(kod1, 'yeterlilik-1') <> 0 then raise exception 'OLCU3: tek derste gecti'; end if;
    if public.ozel_kod_kontrol(lower(substr(kod1, 1, 4)) || '-' || lower(substr(kod1, 5)), 'sgs') <> 600 then raise exception 'OLCU3: normalize tutmadi'; end if;
    if public.ozel_kod_kontrol('OZZZZZZZ', 'sgs') <> 0 then raise exception 'OLCU3: uydurma kod gecti'; end if;
    n := n + 4;

    -- 4) alıcı (girişsiz de olabilir) SGS siparişi: 600 damgası, tarayıcının yazdığı tutar ezilir, kaynak 'ozel:<KOD>'
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, ozel_kod, ozel_kod_tl, indirim_kaynak)
    values ('TT-20261019-ZKAA', 'sgs', 1988, 'DENEME', 'deneme@tetikte.invalid', lower(kod1), 999, 'elci:HILE');
    select * into r from public.siparisler where siparis_no = 'TT-20261019-ZKAA';
    if r.ozel_kod_tl <> 600 or r.ozel_kod <> kod1 or r.indirim_kaynak <> 'ozel:' || kod1 or r.indirim_tl <> 0 or r.elci_kodu is not null then
      raise exception 'OLCU3: damga yanlis tl=% kod=% kaynak=%', r.ozel_kod_tl, r.ozel_kod, r.indirim_kaynak;
    end if;
    if (select siparis_no from public.ozel_kod where kod = kod1) <> 'TT-20261019-ZKAA' then raise exception 'OLCU3: kod kullanildi isaretlenmedi'; end if;
    n := n + 2;

    -- 5) ikinci kullanım reddedilir, kontrol 0 döner
    if public.ozel_kod_kontrol(kod1, 'sgs') <> 0 then raise exception 'OLCU3: kullanilmis kod kontrolde gecerli'; end if;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, ozel_kod)
      values ('TT-20261019-ZKAC', 'yeterlilik-tum', 2868, 'DENEME', 'baska@tetikte.invalid', kod1);
      raise exception 'OLCU3: ikinci kullanim kabul edildi';
    exception when others then if sqlerrm not like '%OZEL_KOD_GECERSIZ%' then raise; end if; end;
    n := n + 2;

    -- 6) bağlı sipariş iptal edilince kod geri gelir; yeni sipariş kodu alır
    update public.siparisler set durum = 'iptal' where siparis_no = 'TT-20261019-ZKAA';
    if public.ozel_kod_kontrol(kod1, 'yeterlilik-tum') <> 600 then raise exception 'OLCU3: iptal sonrasi kod geri gelmedi'; end if;
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, ozel_kod)
    values ('TT-20261019-ZKAD', 'yeterlilik-tum', 2868, 'DENEME', 'deneme@tetikte.invalid', kod1);
    if (select ozel_kod_tl from public.siparisler where siparis_no = 'TT-20261019-ZKAD') <> 600
       or (select siparis_no from public.ozel_kod where kod = kod1) <> 'TT-20261019-ZKAD' then raise exception 'OLCU3: iptal sonrasi yeniden kullanim yanlis'; end if;
    -- iade edilen siparişte kod geri GELMEZ
    update public.siparisler set durum = 'iade' where siparis_no = 'TT-20261019-ZKAD';
    if public.ozel_kod_kontrol(kod1, 'sgs') <> 0 then raise exception 'OLCU3: iade sonrasi kod geri geldi'; end if;
    n := n + 3;

    -- 7) yanlış paket reddedilir (kod2 tüketilmez)
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, ozel_kod)
      values ('TT-20261019-ZKAE', 'yeterlilik-1', 588, array['Hukuk'], 'DENEME', 'deneme@tetikte.invalid', kod2);
      raise exception 'OLCU3: tek ders paketi kabul edildi';
    exception when others then if sqlerrm not like '%OZEL_KOD_GECERSIZ%' then raise; end if; end;
    if (select kullanildi from public.ozel_kod where kod = kod2) is not null then raise exception 'OLCU3: reddedilen sipariste kod tuketildi'; end if;
    n := n + 2;

    -- 8) elçi 400 < özel 600 → özel kazanır, elçi boş (tarayıcı ikisini birden yollasa da)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, elci_kodu, ozel_kod)
    values ('TT-20261019-ZKAF', 'sgs', 1988, 'DENEME', 'deneme@tetikte.invalid', kim, kod2);
    select * into r from public.siparisler where siparis_no = 'TT-20261019-ZKAF';
    if r.ozel_kod_tl <> 600 or r.elci_kodu is not null or r.indirim_tl <> 0 or r.elci_sabit_komisyon_tl is not null or r.indirim_kaynak <> 'ozel:' || kod2 then
      raise exception 'OLCU3: elci-ozel kurali yanlis ozel=% elci=% ind=%', r.ozel_kod_tl, r.elci_kodu, r.indirim_tl;
    end if;
    n := n + 1;

    -- 9) anlık teklif 600 = özel 600 (eşit) → özel kalır, teklif TÜKETİLMEZ (teklif hesaba bağlı: A girişli)
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a, true);
    v := public.anlik_teklif_al('olcu3-svy-1', 'seviye', 'Hukuk');
    if v is null then raise exception 'OLCU3: teklif uretilmedi'; end if;
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, teklif_belirtec, ozel_kod)
    values ('TT-20261019-ZKAH', 'yeterlilik-tum', 2868, 'DENEME', 'deneme@tetikte.invalid', v->>'belirtec', kod3);
    select * into r from public.siparisler where siparis_no = 'TT-20261019-ZKAH';
    if r.ozel_kod_tl <> 600 or r.anlik_teklif_tl <> 0 or r.teklif_belirtec is not null or r.indirim_kaynak <> 'ozel:' || kod3 then
      raise exception 'OLCU3: teklif-ozel kurali yanlis ozel=% anlik=%', r.ozel_kod_tl, r.anlik_teklif_tl;
    end if;
    if (select kullanildi from public.anlik_teklif where belirtec = v->>'belirtec') is not null then raise exception 'OLCU3: kaybeden teklif tuketildi'; end if;
    n := n + 2;

    -- 10) süresi geçen ve iptal edilen kod reddedilir
    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y, true);
    k1 := public.yonetim_ozel_kod_uret('DENEME Sure', 3, 600);
    k2 := public.yonetim_ozel_kod_uret('DENEME Iptal', 3, 600);
    update public.ozel_kod set son = now() - interval '1 second' where kod = k1->>'kod';
    perform public.yonetim_ozel_kod_iptal(lower(k2->>'kod'));
    if public.ozel_kod_kontrol(k1->>'kod', 'sgs') <> 0 then raise exception 'OLCU3: suresi gecen kod gecti'; end if;
    if public.ozel_kod_kontrol(k2->>'kod', 'sgs') <> 0 then raise exception 'OLCU3: iptal edilen kod gecti'; end if;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, ozel_kod)
      values ('TT-20261019-ZKAJ', 'sgs', 1988, 'DENEME', 'deneme@tetikte.invalid', k1->>'kod');
      raise exception 'OLCU3: suresi gecen kod sipariste gecti';
    exception when others then if sqlerrm not like '%OZEL_KOD_GECERSIZ%' then raise; end if; end;
    n := n + 3;

    -- 11) kodsuz sipariş: tarayıcının yazdığı ozel_kod_tl ezilir, kaynak 'yok'
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, ozel_kod_tl)
    values ('TT-20261019-ZKAK', 'sgs', 2588, 'DENEME', 'deneme@tetikte.invalid', 600);
    select * into r from public.siparisler where siparis_no = 'TT-20261019-ZKAK';
    if r.ozel_kod_tl <> 0 or r.indirim_kaynak <> 'yok' then raise exception 'OLCU3: kodsuz indirim ezilmedi'; end if;
    n := n + 1;

    -- 12) yönetim listesi kodu, siparişini ve geçerliliğini gösterir
    l := public.yonetim_ozel_kodlar();
    if not (l @> jsonb_build_array(jsonb_build_object('kod', kod2, 'siparis_no', 'TT-20261019-ZKAF', 'siparis_durum', 'odeme_bekliyor', 'gecerli', false))) then
      raise exception 'OLCU3: yonetim listesi yanlis';
    end if;
    if not (public.yonetim_ozet()->'siparisler' @> jsonb_build_array(jsonb_build_object('no', 'TT-20261019-ZKAF', 'ozel_kod', kod2, 'ozel_kod_tl', 600))) then
      raise exception 'OLCU3: yonetim ozeti ozel kodu tasimiyor';
    end if;
    n := n + 2;

    -- 13) elçi paneli (B): özel kodlu sipariş elçi satışı sayılmaz
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b, true);
    if (public.elci_panelim()->>'odeme_bekleyen')::int <> 0 then raise exception 'OLCU3: elci paneli ozel kodu saydi'; end if;
    n := n + 1;

    raise exception 'OLCU3_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU3_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261019-ZK%')
     -- PL/pgSQL değişkenleri alt işlemle geri alınmaz: üretilen kodlar burada hâlâ bilinir
     or exists (select 1 from public.ozel_kod where kod in (kod1, kod2, kod3, k1->>'kod', k2->>'kod'))
     or exists (select 1 from public.anlik_teklif where sonuc like 'olcu3-%')
     or exists (select 1 from public.elciler where kod = 'ZZOZK1')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000000c3') then
    raise exception 'OLCU3: geri alma iz birakti';
  end if;
  raise notice 'OZEL INDIRIM KODU OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;

-- ÖLÇÜ (uygulama sonrası):
--   select column_name from information_schema.columns where table_name='siparisler' and column_name in ('ozel_kod','ozel_kod_tl');  -- 2
--   anon: POST /rest/v1/rpc/ozel_kod_kontrol {"p_kod":"OZZZZZZZ","p_paket":"sgs"} → 0
--   anon: POST /rest/v1/rpc/yonetim_ozel_kod_uret → 401/404 (yalnız authenticated + yönetici)
