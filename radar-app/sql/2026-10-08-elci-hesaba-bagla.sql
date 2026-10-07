-- =============================================================================
-- ELÇİYİ HESABINA YÖNETİM EKRANINDAN BAĞLA (08.10.2026)
-- Cem: "biz bunlara siteyi açacağız, o kişiler burda belli zaten, siteye girip takip etse; diğer firmalar nasıl yapıyor"
--   -> "1.2 yap". Elçi kendi hesabıyla (Google ya da e-posta) üye olur; yönetici Elçiler tablosunda "Hesaba bağla"
--   der, e-postayı yazar; kod o hesaba bağlanır. Elçi Hesabım'da "Elçi Panelim"i görür (ogrenci.html elci_panelim()).
--   Bağlama kodu (elci_bagla) YEDEK olarak kalır.
-- GÜVENLİK: sitede e-posta onayı kapalı (23.09) -> biri elçinin e-postasıyla önce hesap açabilir. Bu yüzden ÖNCE
--   yonetim_elci_hesap_bul ile hesap gösterilir (giriş sağlayıcısı: google/email, kayıt ve son giriş zamanı, başka
--   koda bağlı mı); yönetici bakıp onaylar. Fonksiyonlar yalnız yöneticiye (yonetici_mi), anon/public hakkı yok.
--   E-posta yalnız yöneticiye döner (zaten yonetim_ozet'te üye e-postalarını görüyor).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- =============================================================================

-- 1) Hesabı bul (bağlamadan önce göster)
create or replace function public.yonetim_elci_hesap_bul(p_eposta text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare
  v_id uuid; v_kayit timestamptz; v_son timestamptz; v_meta jsonb; v_kod text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select u.id, u.created_at, u.last_sign_in_at, coalesce(u.raw_app_meta_data, '{}'::jsonb)
    into v_id, v_kayit, v_son, v_meta
    from auth.users u
   where lower(u.email) = lower(trim(coalesce(p_eposta, '')))
   limit 1;
  if v_id is null then
    return jsonb_build_object('var', false);
  end if;
  select kod into v_kod from public.elciler where user_id = v_id;
  return jsonb_build_object(
    'var',        true,
    'saglayici',  coalesce(v_meta->'providers', jsonb_build_array(coalesce(v_meta->>'provider', 'email'))),
    'kayit',      v_kayit,
    'son_giris',  v_son,
    'bagli_kod',  v_kod
  );
end $$;

-- 2) Bağla
create or replace function public.yonetim_elci_hesaba_bagla(p_kod text, p_eposta text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare
  v_kod text := upper(trim(coalesce(p_kod, ''))); v_uid uuid; v_baska text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if not exists (select 1 from public.elciler where kod = v_kod) then raise exception 'KOD_YOK'; end if;
  select u.id into v_uid from auth.users u where lower(u.email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  select kod into v_baska from public.elciler where user_id = v_uid and kod <> v_kod;
  if v_baska is not null then raise exception 'HESAP_BASKA_KODDA:%', v_baska; end if;
  update public.elciler
     set user_id = v_uid, bag_kodu_ozet = null, bag_kodu_son = null
   where kod = v_kod;
  return jsonb_build_object('kod', v_kod, 'eposta', lower(trim(p_eposta)));
end $$;

-- 3) Bağı çöz (yanlış hesaba bağlandıysa)
create or replace function public.yonetim_elci_bagi_coz(p_kod text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.elciler set user_id = null where kod = upper(trim(coalesce(p_kod, '')));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'bagli', false);
end $$;

-- 4) Elçiler tablosu için: hangi kod bir hesaba bağlı, sözleşme onaylı mı (e-posta DÖNMEZ; bağlı hesabın e-postası
--    yöneticinin zaten gördüğü üye listesinden okunur)
create or replace function public.yonetim_elci_hesaplar()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kod', e.kod,
             'bagli', e.user_id is not null,
             'eposta', (select u.email from auth.users u where u.id = e.user_id),
             'sozlesme', e.sozlesme_onay is not null))
      from public.elciler e
  ), '[]'::jsonb);
end $$;

revoke all on function public.yonetim_elci_hesap_bul(text)            from public, anon;
revoke all on function public.yonetim_elci_hesaba_bagla(text, text)   from public, anon;
revoke all on function public.yonetim_elci_bagi_coz(text)             from public, anon;
revoke all on function public.yonetim_elci_hesaplar()                 from public, anon;
grant execute on function public.yonetim_elci_hesap_bul(text)          to authenticated;
grant execute on function public.yonetim_elci_hesaba_bagla(text, text) to authenticated;
grant execute on function public.yonetim_elci_bagi_coz(text)           to authenticated;
grant execute on function public.yonetim_elci_hesaplar()               to authenticated;
