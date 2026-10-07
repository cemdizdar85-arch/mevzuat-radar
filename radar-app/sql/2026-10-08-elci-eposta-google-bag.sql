-- =============================================================================
-- ELÇİ E-POSTASI + GOOGLE GİRİŞİNDE KENDİLİĞİNDEN BAĞLAMA (08.10.2026)
-- Cem: "ben mailleri baştan toplayacağım, ona kod verdiğimiz yerde onu gireceğim" (Adile'ye kod verilirken yalnız
--   Instagram yazılmıştı). Yönetici elçinin e-postasını yönetim ekranında yazar; elçi o adresle GOOGLE ile girince
--   hesabı kendiliğinden elçi koduna bağlanır (elci_google_bagla, ogrenci.html + elci.html sayfa açılışında çağırır).
-- GÜVENLİK: yalnız Google sağlayıcılı hesapta (e-postayı Google doğrular). E-posta+şifre hesabı KENDİLİĞİNDEN
--   bağlanmaz (sitede e-posta onayı kapalı; biri elçinin adresiyle önce hesap açabilir) -> yönetici "Hesaba bağla"
--   (2026-10-08-elci-hesaba-bagla.sql) ile bakıp bağlar. Pasif kod bağlanmaz; zaten bağlı kod/hesap değişmez.
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez.
-- =============================================================================

-- 1) Yönetici: elçinin e-postasını yaz / düzelt (boş = sil)
create or replace function public.yonetim_elci_eposta_yaz(p_kod text, p_eposta text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_ep text := nullif(lower(trim(coalesce(p_eposta, ''))), '');
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if v_ep is not null and v_ep !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'EPOSTA_GECERSIZ'; end if;
  if v_ep is not null and exists (select 1 from public.elciler where lower(email) = v_ep and kod <> upper(trim(p_kod))) then
    raise exception 'EPOSTA_BASKA_KODDA';
  end if;
  update public.elciler set email = v_ep where kod = upper(trim(coalesce(p_kod, '')));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'eposta', v_ep);
end $$;

-- 2) Elçi tablosu: kayıtlı e-posta + Instagram da döner (önceki sürümün yerine; aynı imza)
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
             'sozlesme', e.sozlesme_onay is not null))
      from public.elciler e
  ), '[]'::jsonb);
end $$;

-- 3) Elçi: Google ile girdiyse ve e-postası bir elçi kaydında yazılıysa hesabını bağla. Sessiz: bağlanacak bir şey
--    yoksa null döner; zaten bağlıysa kodunu döner.
create or replace function public.elci_google_bagla()
returns text language plpgsql volatile security definer set search_path = public, auth as $$
declare v_uid uuid := auth.uid(); v_kod text; v_ep text; v_meta jsonb;
begin
  if v_uid is null then return null; end if;
  select kod into v_kod from public.elciler where user_id = v_uid;
  if v_kod is not null then return v_kod; end if;
  select lower(u.email), coalesce(u.raw_app_meta_data, '{}'::jsonb) into v_ep, v_meta from auth.users u where u.id = v_uid;
  if v_ep is null then return null; end if;
  if not (coalesce(v_meta->'providers', '[]'::jsonb) ? 'google' or v_meta->>'provider' = 'google') then return null; end if;
  -- aynı e-posta eski kayıtlarda iki kodda yazılı olabilir: en yeni açık kod seçilir, yalnız o bağlanır
  select kod into v_kod from public.elciler
   where lower(email) = v_ep and user_id is null and aktif
   order by olusturma desc limit 1;
  if v_kod is null then return null; end if;
  update public.elciler set user_id = v_uid, bag_kodu_ozet = null, bag_kodu_son = null where kod = v_kod and user_id is null;
  return v_kod;
end $$;

revoke all on function public.yonetim_elci_eposta_yaz(text, text) from public, anon;
revoke all on function public.yonetim_elci_hesaplar()             from public, anon;
revoke all on function public.elci_google_bagla()                 from public, anon;
grant execute on function public.yonetim_elci_eposta_yaz(text, text) to authenticated;
grant execute on function public.yonetim_elci_hesaplar()             to authenticated;
grant execute on function public.elci_google_bagla()                 to authenticated;
