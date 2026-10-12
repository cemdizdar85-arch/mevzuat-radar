-- ============================================================================
-- ÖDENMİŞ SİPARİŞ ↔ HESAP BAĞI (12.10.2026, Cem "1.2.3 üçünü de yap")
--
-- OLAY (ölçüldü 12.10): bir alıcı kartla X@hotmail adresiyle ödedi (TT-20261012-ARH3), 3 dk sonra siteye Google ile
-- BAŞKA adresle (Y@gmail) girdi → paket e-postaya bağlandığı için görünmedi ("ödedim, açılmıyor"). Elle bağlandı.
-- Aynı gün başka bir alıcı 4 ayrı hesap + 3 sipariş açmıştı. Kök: sipariş yalnız E-POSTAYLA hesaba bağlanıyor.
--
-- ÇÖZÜM:
--   1) siparisler +bagli_kullanici +bagli_tarih +bagli_yol ('eposta' | 'yonetim' | 'uye-siparis-no'): sipariş hangi
--      hesaba açıldı. Bağlı sipariş başka hesaba İKİNCİ KEZ açılmaz (bir satış = bir hesap).
--   2) _siparis_isle(sipariş, hesap, yol): paketi açan TEK iç yol (siparis_paket_bagla 2026-10-05 gövdesiyle aynı
--      bitiş/upsert kuralı + bağ damgası). Dışarıya kapalı.
--   3) siparis_paket_bagla(uid, eposta) yeniden: aynı dönüş kodları; başka hesaba bağlanmış siparişi atlar.
--      (Çağıranlar: yeni üye tetikleyicisi, yonetim_siparis_onayla, kart ödemesi — imza aynı.)
--   4) yonetim_bagsiz_siparisler(): ödenmiş, süresi geçmemiş, hiçbir hesapta açılmamış siparişler (panel listesi).
--      yonetim_hesap_bul(eposta): bağlamadan önce hesabı gösterir. yonetim_siparis_hesaba_bagla(no, eposta).
--   5) paketimi_bagla(no, eposta): GİRİŞLİ üye, sipariş no + siparişte yazdığı e-postayla kendi hesabına bağlar.
--      Şartlar: ikisi birden tutar · sipariş ödenmiş · başka hesaba bağlı değil · siparişin e-postasıyla AÇILMIŞ hesap
--      yok (varsa "o e-postayla gir" — paket ikinci hesaba gitmesin) · üyede başka aktif paket yok · 10 dk'da 5 deneme.
--   6) yonetim_siparis_iade yeniden: paketi bağlı hesapta kapatır (yoksa eskisi gibi e-postanın hesabında).
--      Eskitir: 2026-10-05-siparis-iade.sql tanımı · 2026-10-05-otomatik-paket.sql siparis_paket_bagla tanımı.
--   7) Geri doldurma: ödenmiş ve e-postasıyla açılmış hesapta paketi olan siparişler → bagli_yol 'eposta'.
--
-- 🚫 GÖRMEZ: sipariş no + e-postayı bilen BAŞKASI (ör. iletilmiş mail), alıcı hesap açmadan önce paketi kendi hesabına
--    alabilir → alıcı destek@'e yazar, panelde bagli_yol 'uye-siparis-no' görünür, yönetici yeniden bağlar ·
--    adı/kimliği karşılaştırmaz · hesap silinince bagli_kullanici boşa düşmez (FK yok, iz kalır).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- ============================================================================
alter table public.siparisler add column if not exists bagli_kullanici uuid;
alter table public.siparisler add column if not exists bagli_tarih     timestamptz;
alter table public.siparisler add column if not exists bagli_yol       text;

-- 2) tek iç yol
create or replace function public._siparis_isle(p_sid bigint, p_uid uuid, p_yol text)
returns text language plpgsql security definer set search_path = public as $$
declare s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean;
begin
  if p_uid is null then return 'BOS'; end if;
  select * into s from public.siparisler where id = p_sid for update;
  if not found or s.durum <> 'odendi' then return 'SIPARIS_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> p_uid then return 'BASKA_HESAPTA'; end if;
  v_bitis := coalesce(s.paket_bitis,
                      greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92));
  if v_bitis < current_date then return 'SURESI_GECMIS'; end if;
  select * into v_eski from public.paket_uyeler where user_id = p_uid;
  v_var := found;
  if not (v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis) then
    insert into public.paket_uyeler (user_id, paket, bitis, dersler)
      values (p_uid, s.paket, v_bitis, case when s.paket ~ '^yeterlilik-[1-4]$' then s.secilen_dersler else null end)
      on conflict (user_id) do update
        set paket = excluded.paket, dersler = excluded.dersler,
            bitis = greatest(excluded.bitis, case when paket_uyeler.paket = excluded.paket and paket_uyeler.bitis >= current_date then paket_uyeler.bitis else excluded.bitis end);
  end if;
  update public.siparisler set bagli_kullanici = p_uid, bagli_tarih = now(), bagli_yol = left(coalesce(p_yol, ''), 20)
   where id = s.id and bagli_kullanici is null;
  return case when v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis then 'ZATEN_ACIK' else 'ACILDI' end;
end $$;
revoke all on function public._siparis_isle(bigint, uuid, text) from public, anon, authenticated;

-- 3) e-postayla bağlama (imza ve dönüş kodları aynı)
create or replace function public.siparis_paket_bagla(p_uid uuid, p_eposta text)
returns text language plpgsql security definer set search_path = public as $$
declare v_sid bigint;
begin
  if p_uid is null or coalesce(p_eposta, '') = '' then return 'BOS'; end if;
  select id into v_sid from public.siparisler
   where lower(email) = lower(p_eposta) and durum = 'odendi'
     and (bagli_kullanici is null or bagli_kullanici = p_uid)
   order by odendi_tarihi desc nulls last, olusturma desc limit 1;
  if v_sid is null then return 'SIPARIS_YOK'; end if;
  return public._siparis_isle(v_sid, p_uid, 'eposta');
end $$;
revoke all on function public.siparis_paket_bagla(uuid, text) from public, anon, authenticated;

-- 4a) panel: hiçbir hesapta açılmamış ödenmiş siparişler
create or replace function public.yonetim_bagsiz_siparisler()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'no', s.siparis_no, 'odendi', s.odendi_tarihi, 'ad', s.ad_soyad, 'eposta', s.email, 'paket', s.paket,
             'paket_ad', s.paket_ad, 'tutar', s.tutar, 'odeme', s.odeme, 'bitis', s.paket_bitis,
             'hesap_var', exists (select 1 from auth.users u where lower(u.email) = lower(s.email)))
           order by s.odendi_tarihi desc nulls last)
      from public.siparisler s
     where s.durum = 'odendi' and s.bagli_kullanici is null
       and coalesce(s.paket_bitis, current_date) >= current_date
  ), '[]'::jsonb);
end $$;

-- 4b) panel: bağlamadan önce hesabı göster
create or replace function public.yonetim_hesap_bul(p_eposta text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare u auth.users%rowtype; p public.paket_uyeler%rowtype;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into u from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if not found then return jsonb_build_object('var', false); end if;
  select * into p from public.paket_uyeler where user_id = u.id;
  return jsonb_build_object(
    'var', true, 'eposta', u.email,
    'saglayici', coalesce(u.raw_app_meta_data->'providers', jsonb_build_array(coalesce(u.raw_app_meta_data->>'provider', 'email'))),
    'ad', coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'ad', ''),
    'kayit', u.created_at, 'son_giris', u.last_sign_in_at, 'onayli', u.email_confirmed_at is not null,
    'paket', p.paket, 'bitis', p.bitis);
end $$;

-- 4c) panel: siparişi seçilen hesaba bağla
create or replace function public.yonetim_siparis_hesaba_bagla(p_no text, p_eposta text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_ep text; p public.paket_uyeler%rowtype; v_sonuc text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = trim(coalesce(p_no, ''));
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odendi' then raise exception 'DURUM_%', upper(s.durum); end if;
  select id, email into v_uid, v_ep from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> v_uid then raise exception 'BASKA_HESAPTA'; end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  if found and p.bitis >= current_date and p.paket <> s.paket then raise exception 'AKTIF_PAKET_VAR'; end if;
  v_sonuc := public._siparis_isle(s.id, v_uid, 'yonetim');
  if v_sonuc not in ('ACILDI', 'ZATEN_ACIK') then raise exception '%', v_sonuc; end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  return jsonb_build_object('no', s.siparis_no, 'eposta', v_ep, 'paket', p.paket, 'bitis', p.bitis, 'sonuc', v_sonuc);
end $$;

-- 5) üye: "Paketim görünmüyor" — sipariş no + siparişteki e-posta.
--    Ret HATA FIRLATMAZ, {"hata": KOD} döner: fırlatsaydı rate_limit_check'in deneme kaydı da işlemle geri alınır,
--    fren yalnız başarılı denemeyi sayardı. Kodlar: COK_DENEME · ESLESMEDI · ODEME_BEKLIYOR · ZATEN_ACIK ·
--    BASKA_HESAPTA · EPOSTA_HESABI_VAR · PAKET_VAR · SURESI_GECMIS. Girişsiz çağrı 42501 fırlatır (sayılacak hesap yok).
create or replace function public.paketimi_bagla(p_no text, p_eposta text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_uid uuid := auth.uid(); s public.siparisler%rowtype; p public.paket_uyeler%rowtype; v_sonuc text;
begin
  if v_uid is null then raise exception 'GIRIS_YOK' using errcode = '42501'; end if;
  if not public.rate_limit_check('pbag:' || v_uid::text, 5, 600) then return jsonb_build_object('hata', 'COK_DENEME'); end if;
  select * into s from public.siparisler
   where upper(siparis_no) = upper(trim(coalesce(p_no, ''))) and lower(email) = lower(trim(coalesce(p_eposta, '')));
  if not found or s.durum not in ('odendi', 'odeme_bekliyor') then return jsonb_build_object('hata', 'ESLESMEDI'); end if;
  if s.durum = 'odeme_bekliyor' then return jsonb_build_object('hata', 'ODEME_BEKLIYOR'); end if;
  if s.bagli_kullanici = v_uid then return jsonb_build_object('hata', 'ZATEN_ACIK'); end if;
  if s.bagli_kullanici is not null then return jsonb_build_object('hata', 'BASKA_HESAPTA'); end if;
  if exists (select 1 from auth.users u where lower(u.email) = lower(s.email) and u.id <> v_uid) then return jsonb_build_object('hata', 'EPOSTA_HESABI_VAR'); end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  if found and p.bitis >= current_date and p.paket <> s.paket then return jsonb_build_object('hata', 'PAKET_VAR'); end if;
  v_sonuc := public._siparis_isle(s.id, v_uid, 'uye-siparis-no');
  if v_sonuc not in ('ACILDI', 'ZATEN_ACIK') then return jsonb_build_object('hata', v_sonuc); end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  return jsonb_build_object('paket', p.paket, 'bitis', p.bitis, 'sonuc', v_sonuc);
end $$;

-- 6) iade: bağlı hesapta kapat
create or replace function public.yonetim_siparis_iade(p_no text, p_neden text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_kapandi boolean := false;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odendi' then raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'iade' where id = s.id;

  v_uid := s.bagli_kullanici;
  if v_uid is null then select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1; end if;
  if v_uid is not null then
    update public.paket_uyeler set bitis = current_date - 1
     where user_id = v_uid and paket = s.paket and bitis >= current_date;
    v_kapandi := found;
  end if;
  return jsonb_build_object('siparis', 'iade', 'eposta', s.email, 'odeme', s.odeme, 'elci', s.elci_kodu,
                            'paket_kapandi', v_kapandi, 'neden', left(coalesce(p_neden, ''), 200));
end $$;

revoke all on function public.yonetim_bagsiz_siparisler()                 from public, anon;
revoke all on function public.yonetim_hesap_bul(text)                      from public, anon;
revoke all on function public.yonetim_siparis_hesaba_bagla(text, text)     from public, anon;
revoke all on function public.paketimi_bagla(text, text)                   from public, anon;
revoke all on function public.yonetim_siparis_iade(text, text)             from public, anon;
grant execute on function public.yonetim_bagsiz_siparisler()               to authenticated;
grant execute on function public.yonetim_hesap_bul(text)                   to authenticated;
grant execute on function public.yonetim_siparis_hesaba_bagla(text, text)  to authenticated;
grant execute on function public.paketimi_bagla(text, text)                to authenticated;
grant execute on function public.yonetim_siparis_iade(text, text)          to authenticated;

-- 7) geri doldurma: e-postasıyla açılmış hesapta paketi olan ödenmiş siparişler
update public.siparisler s
   set bagli_kullanici = u.id, bagli_tarih = coalesce(s.odendi_tarihi, now()), bagli_yol = 'eposta'
  from auth.users u
 where s.durum = 'odendi' and s.bagli_kullanici is null and lower(u.email) = lower(s.email)
   and exists (select 1 from public.paket_uyeler p where p.user_id = u.id and p.paket = s.paket);

-- ÖZ-SINAV (alt işlemde, sonunda 'OLCU_TAMAM' ile GERİ ALINIR; bir vaka tutmazsa göç KIRMIZI, hiçbir şey uygulanmaz):
--   üye doğru no+e-postayla bağlar · yanlış e-posta / yanlış no ESLESMEDI · ödeme bekleyen ODEME_BEKLIYOR · bağlanan
--   sipariş ikinci üyeye BASKA_HESAPTA · siparişin e-postasıyla hesap varsa EPOSTA_HESABI_VAR · girişsiz GIRIS_YOK ·
--   e-postayla yeni üye olan, başka hesaba bağlı siparişi ALMAZ · eski e-posta yolu ACILDI/ZATEN_ACIK + damga ·
--   10 dk'da 6. çağrıda COK_DENEME · yönetici olmayan yonetim_* çağıramaz.
--   🚫 SINANMAZ: yönetici yolu (yonetici_mi taklit edilemiyor) ve iadenin bağlı hesabı kapatması → canlıda elle ölçülür.
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-00000000c0a1';
  b constant uuid := '00000000-0000-4000-8000-00000000c0b2';
  c constant uuid := '00000000-0000-4000-8000-00000000c0c3';
  v jsonb; n int;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-a@tetikte.invalid', now(), now()),
           (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-b@tetikte.invalid', now(), now());
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, paket_bitis)
    values ('TT-20261012-QQ01', 'sgs', 2988, 'Olcu Bir', 'olcu-siparis@tetikte.invalid', 'kart', 'odeme_bekliyor', current_date + 90),
           ('TT-20261012-QQ02', 'sgs', 2988, 'Olcu Iki', 'olcu-a@tetikte.invalid', 'kart', 'odeme_bekliyor', current_date + 90),
           ('TT-20261012-QQ03', 'sgs', 2988, 'Olcu Uc', 'olcu-iade@tetikte.invalid', 'kart', 'odeme_bekliyor', current_date + 90);

    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    if auth.uid() <> a then raise exception 'OLCU: auth.uid taklidi tutmadi'; end if;

    -- ödeme bekleyen bağlanmaz
    v := public.paketimi_bagla('TT-20261012-QQ01', 'olcu-siparis@tetikte.invalid');
    if coalesce(v->>'hata', '') <> 'ODEME_BEKLIYOR' then raise exception 'OLCU: odeme bekleyen %', v; end if;

    update public.siparisler set durum = 'odendi' where siparis_no like 'TT-20261012-QQ%';

    -- yanlış e-posta / yanlış no
    v := public.paketimi_bagla('TT-20261012-QQ01', 'baska@tetikte.invalid');
    if coalesce(v->>'hata', '') <> 'ESLESMEDI' then raise exception 'OLCU: yanlis e-posta %', v; end if;
    v := public.paketimi_bagla('TT-20261012-QQ99', 'olcu-siparis@tetikte.invalid');
    if coalesce(v->>'hata', '') <> 'ESLESMEDI' then raise exception 'OLCU: yanlis no %', v; end if;
    if exists (select 1 from public.siparisler where siparis_no like 'TT-20261012-QQ%' and bagli_kullanici is not null) then raise exception 'OLCU: ret yolunda bag yazildi'; end if;

    -- siparişin e-postasıyla hesap varsa başka üye alamaz (QQ02 e-postası = a; b dener)
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b::text, true);
    v := public.paketimi_bagla('TT-20261012-QQ02', 'olcu-a@tetikte.invalid');
    if coalesce(v->>'hata', '') <> 'EPOSTA_HESABI_VAR' then raise exception 'OLCU: e-posta hesabi varken %', v; end if;

    -- doğru bağlama (b, QQ01; büyük/küçük harf ve boşluk tolere)
    v := public.paketimi_bagla(' tt-20261012-qq01 ', 'OLCU-Siparis@tetikte.invalid');
    if v->>'paket' <> 'sgs' or v->>'sonuc' <> 'ACILDI' then raise exception 'OLCU: baglama sonucu %', v; end if;
    if not exists (select 1 from public.paket_uyeler where user_id = b and paket = 'sgs' and bitis >= current_date) then raise exception 'OLCU: paket yazilmadi'; end if;
    if (select bagli_kullanici from public.siparisler where siparis_no = 'TT-20261012-QQ01') <> b
       or (select bagli_yol from public.siparisler where siparis_no = 'TT-20261012-QQ01') <> 'uye-siparis-no' then raise exception 'OLCU: bag damgasi yok'; end if;

    -- aynı sipariş ikinci üyeye gitmez (a dener)
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    v := public.paketimi_bagla('TT-20261012-QQ01', 'olcu-siparis@tetikte.invalid');
    if coalesce(v->>'hata', '') <> 'BASKA_HESAPTA' then raise exception 'OLCU: ikinci hesap %', v; end if;
    if exists (select 1 from public.paket_uyeler where user_id = a) then raise exception 'OLCU: ikinci hesaba paket yazildi'; end if;

    -- siparişin e-postasıyla SONRADAN üye olan, başka hesaba bağlanmış siparişi almaz (tetikleyici yolu)
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-siparis@tetikte.invalid', now(), now());
    if exists (select 1 from public.paket_uyeler where user_id = c) then raise exception 'OLCU: tetikleyici bagli siparisi ikinci hesaba acti'; end if;
    -- e-postayla bağlama (eski yol) hâlâ çalışır: a'nın kendi siparişi QQ02
    if public.siparis_paket_bagla(a, 'olcu-a@tetikte.invalid') <> 'ACILDI' then raise exception 'OLCU: e-posta yolu bozuldu'; end if;
    if (select bagli_yol from public.siparisler where siparis_no = 'TT-20261012-QQ02') <> 'eposta' then raise exception 'OLCU: e-posta yolu damgasiz'; end if;
    if public.siparis_paket_bagla(a, 'olcu-a@tetikte.invalid') <> 'ZATEN_ACIK' then raise exception 'OLCU: ikinci cagri ZATEN_ACIK degil'; end if;

    -- yönetici olmayan yonetim_* çağıramaz
    begin perform public.yonetim_siparis_hesaba_bagla('TT-20261012-QQ03', 'olcu-a@tetikte.invalid'); raise exception 'OLCU: yonetici olmayan bagladi';
    exception when others then if sqlerrm <> 'YETKI_YOK' then raise; end if; end;
    begin perform public.yonetim_bagsiz_siparisler(); raise exception 'OLCU: yonetici olmayan liste okudu';
    exception when others then if sqlerrm <> 'YETKI_YOK' then raise; end if; end;

    -- girişsiz bağlayamaz
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    begin perform public.paketimi_bagla('TT-20261012-QQ03', 'olcu-iade@tetikte.invalid'); raise exception 'OLCU: girissiz baglandi';
    exception when others then if sqlerrm <> 'GIRIS_YOK' then raise; end if; end;

    -- deneme freni: 10 dk'da 5 çağrı, 6.'da COK_DENEME. b şimdiye dek 2 çağrı yaptı (EPOSTA_HESABI_VAR + bağlama)
    -- → döngüde 3 ESLESMEDI, 4. turda COK_DENEME
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b::text, true);
    n := 0;
    for i in 1..6 loop
      v := public.paketimi_bagla('TT-20261012-QQ98', 'yok@tetikte.invalid');
      if v->>'hata' = 'COK_DENEME' then n := i; exit; end if;
      if coalesce(v->>'hata', '') <> 'ESLESMEDI' then raise exception 'OLCU: fren dongusu %', v; end if;
    end loop;
    if n <> 4 then raise exception 'OLCU: deneme freni % . turda (beklenen 4)', n; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261012-QQ%')
     or exists (select 1 from auth.users where email like 'olcu-%@tetikte.invalid')
     or exists (select 1 from public.rate_log where ip like 'pbag:00000000-%') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'SIPARIS-HESAP BAG OZ-SINAV: 14 vaka TAMAM (geri alindi)';
end $$;

-- ÖLÇÜ (uygulama sonrası):
--   select count(*) filter (where bagli_kullanici is not null), count(*) filter (where durum='odendi') from siparisler;
--   anon POST /rest/v1/rpc/paketimi_bagla → 401/42501 · yönetici olmayan üye yonetim_bagsiz_siparisler → YETKI_YOK
