-- ============================================================================
-- YÖNETİM İŞLEMLERİ — günlük işler DÜĞMEYLE, SQL'siz (04.10.2026, Cem: "her gün SQL basamam ... Amazon / Trendyol
-- nasıl yapıyorsa sitemi ona göre kur")
--
-- Bu dosya .github/workflows/sql-uygula.yml ile OTOMATİK uygulanır (tek işlem, ilk hatada durur, _goc_kutugu'na yazılır).
-- Düğmeler yonetim.html'de. Her fonksiyon: security definer + önce yonetici_mi() (yoneticiler tablosu) - değilse
-- 'YETKI_YOK'. anon EXECUTE yok. Hiçbiri satır SİLMEZ: iptal/kapatma durum ya da bitiş tarihiyle yapılır (iz kalır).
--
--   yonetici_mi()                                  -> Hesabım'daki "Yönetim" bağlantısı için hafif kontrol
--   yonetim_siparis_onayla(no, bitis)              -> havale geldi: sipariş 'odendi' + üyenin paketi açılır
--   yonetim_siparis_iptal(no, neden)               -> ödeme gelmedi: 'iptal' (yalnız ödeme bekleyen)
--   yonetim_paket_ver(eposta, paket, bitis, neden, elci, zorla) -> hediye paket + kütük (arac/paket-hediye.js ile aynı kural)
--   yonetim_paket_kapat(eposta, neden, zorla)      -> paket bitişi dün + kütükte iptal
--   yonetim_elci_ekle(kod, ad, eposta, instagram, not) / yonetim_elci_durum(kod, aktif)
-- ============================================================================

create or replace function public.yonetici_mi()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and exists (select 1 from public.yoneticiler where user_id = auth.uid());
$$;
revoke all on function public.yonetici_mi() from public, anon;
grant execute on function public.yonetici_mi() to authenticated;

-- ---------------------------------------------------------------------------- sipariş onayı
create or replace function public.yonetim_siparis_onayla(p_no text, p_bitis date)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_eski public.paket_uyeler%rowtype; v_ders text[];
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'odendi' where id = s.id;   -- odendi_tarihi tetikleyicide damgalanır

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'ACILAMADI', 'neden', 'HESAP_YOK',
      'not', s.email || ' adresiyle hesap yok. Kişi bu e-postayla üye olunca Paket ver ile açılır.');
  end if;

  v_ders := case when s.paket ~ '^yeterlilik-[1-4]$' then s.secilen_dersler else null end;
  select * into v_eski from public.paket_uyeler where user_id = v_uid;
  if found then
    update public.paket_uyeler
       set paket = s.paket, dersler = v_ders,
           bitis = greatest(p_bitis, case when v_eski.bitis >= current_date and v_eski.paket = s.paket then v_eski.bitis else p_bitis end)
     where user_id = v_uid;
  else
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (v_uid, s.paket, p_bitis, v_ders);
  end if;
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', p_bitis, 'eposta', s.email);
end $$;

create or replace function public.yonetim_siparis_iptal(p_no text, p_neden text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare s public.siparisler%rowtype;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;
  update public.siparisler set durum = 'iptal' where id = s.id;
  return jsonb_build_object('siparis', 'iptal');
end $$;

-- ---------------------------------------------------------------------------- hediye paket
create or replace function public.yonetim_paket_ver(p_eposta text, p_paket text, p_bitis date, p_neden text,
                                                    p_elci text default null, p_zorla boolean default false)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_uid uuid; v_eski public.paket_uyeler%rowtype; v_hediye boolean; v_var boolean;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_paket not in ('tam', 'sgs', 'yeterlilik-tum') then raise exception 'PAKET_GECERSIZ'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  if coalesce(length(trim(p_neden)), 0) < 2 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  select * into v_eski from public.paket_uyeler where user_id = v_uid;
  v_var := found;   -- FOUND bir sonraki sorguda değişmesin diye hemen alınır
  v_hediye := exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null);
  if v_var and v_eski.bitis >= current_date and not v_hediye and not p_zorla then raise exception 'AKTIF_PAKET_VAR'; end if;
  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (v_uid, p_paket, p_bitis, null)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = null;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren)
    values (v_uid, lower(trim(p_eposta)), p_paket, p_bitis, left(p_neden, 200), nullif(upper(trim(coalesce(p_elci, ''))), ''), 'yonetim');
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'paket', p_paket, 'bitis', p_bitis);
end $$;

create or replace function public.yonetim_paket_kapat(p_eposta text, p_neden text, p_zorla boolean default false)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare v_uid uuid;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if not exists (select 1 from public.paket_uyeler where user_id = v_uid) then raise exception 'PAKET_YOK'; end if;
  if not exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null) and not p_zorla then
    raise exception 'HEDIYE_DEGIL';   -- parayla alınmış olabilir; bilerek kapatmak için p_zorla
  end if;
  update public.paket_uyeler set bitis = current_date - 1 where user_id = v_uid;
  update public.paket_hediye set iptal = now(), neden = left('İPTAL: ' || coalesce(p_neden, ''), 200)
   where user_id = v_uid and iptal is null;
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'kapandi', current_date - 1);
end $$;

-- ---------------------------------------------------------------------------- elçi kodu
create or replace function public.yonetim_elci_ekle(p_kod text, p_ad text, p_eposta text default null,
                                                    p_instagram text default null, p_not text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_kod text := upper(trim(p_kod));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if v_kod !~ '^[A-Z0-9]{6,12}$' then raise exception 'KOD_GECERSIZ'; end if;   -- 04.10 Cem: 6 haneli
  if exists (select 1 from public.elciler where kod = v_kod) then raise exception 'KOD_VAR'; end if;
  insert into public.elciler (kod, ad_soyad, email, instagram, not_)
    values (v_kod, trim(p_ad), nullif(trim(coalesce(p_eposta, '')), ''), nullif(trim(coalesce(p_instagram, '')), ''), nullif(trim(coalesce(p_not, '')), ''));
  return jsonb_build_object('kod', v_kod);
end $$;

create or replace function public.yonetim_elci_durum(p_kod text, p_aktif boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.elciler set aktif = p_aktif where kod = upper(trim(p_kod));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'aktif', p_aktif);
end $$;

revoke all on function public.yonetim_siparis_onayla(text, date) from public, anon;
revoke all on function public.yonetim_siparis_iptal(text, text) from public, anon;
revoke all on function public.yonetim_paket_ver(text, text, date, text, text, boolean) from public, anon;
revoke all on function public.yonetim_paket_kapat(text, text, boolean) from public, anon;
revoke all on function public.yonetim_elci_ekle(text, text, text, text, text) from public, anon;
revoke all on function public.yonetim_elci_durum(text, boolean) from public, anon;
grant execute on function public.yonetim_siparis_onayla(text, date) to authenticated;
grant execute on function public.yonetim_siparis_iptal(text, text) to authenticated;
grant execute on function public.yonetim_paket_ver(text, text, date, text, text, boolean) to authenticated;
grant execute on function public.yonetim_paket_kapat(text, text, boolean) to authenticated;
grant execute on function public.yonetim_elci_ekle(text, text, text, text, text) to authenticated;
grant execute on function public.yonetim_elci_durum(text, boolean) to authenticated;
