-- ============================================================================
-- ÖDENMİŞ SİPARİŞ -> SONRADAN ÜYE OLANA PAKET OTOMATİK AÇILIR (04.10.2026, Cem: "üye olanlar, ücret ödeyenlerin hepsi
-- Amazon / Trendyol gibi otomatik olsun")
--
-- BOŞLUK (04.10 ölçüldü): satin-al.html hesap şartı koymuyor; sipariş e-postayla bağlanıyor. yonetim_siparis_onayla
-- ödeme onayında o e-postayla hesap yoksa siparişi 'odendi' yapıp paketi AÇAMIYORDU ("HESAP_YOK"); kişi sonra üye
-- olsa da paket kendiliğinden açılmıyordu (elle açmak gerekiyordu).
--
-- ÇÖZÜM:
--   1) siparisler.paket_bitis: onay anında hesaplanan bitiş siparişe yazılır (hesap olsun olmasın).
--   2) siparis_paket_bagla(uid, eposta): o e-postanın ÖDENMİŞ ve paketi açılmamış en son siparişini paket_uyeler'e işler.
--   3) auth.users AFTER INSERT tetikleyicisi 2'yi çağırır. ⛔ Tetikleyici hata verse bile ÜYE KAYDI ENGELLENMEZ
--      (exception yakalanır, yalnız uyarı). Kayıt yolu her şeyden önemli.
--   4) yonetim_siparis_onayla yeniden: bitişi siparişe yazar; hesap varsa aynı fonksiyonla paketi açar.
-- Ayrıca müşteri maili için iki damga kolonu (siparis-bildirim edge fonksiyonu kullanır, mail iki kez gitmesin).
-- Bu dosya .github/workflows/sql-uygula.yml ile otomatik uygulanır.
-- ============================================================================
alter table public.siparisler add column if not exists paket_bitis    date;
alter table public.siparisler add column if not exists alindi_mail    timestamptz;
alter table public.siparisler add column if not exists acildi_mail    timestamptz;

create or replace function public.siparis_paket_bagla(p_uid uuid, p_eposta text)
returns text language plpgsql security definer set search_path = public as $$
declare s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean;
begin
  if p_uid is null or coalesce(p_eposta, '') = '' then return 'BOS'; end if;
  select * into s from public.siparisler
   where lower(email) = lower(p_eposta) and durum = 'odendi'
   order by odendi_tarihi desc nulls last, olusturma desc limit 1;
  if not found then return 'SIPARIS_YOK'; end if;
  v_bitis := coalesce(s.paket_bitis,
                      greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92));
  if v_bitis < current_date then return 'SURESI_GECMIS'; end if;
  select * into v_eski from public.paket_uyeler where user_id = p_uid;
  v_var := found;
  if v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis then return 'ZATEN_ACIK'; end if;
  insert into public.paket_uyeler (user_id, paket, bitis, dersler)
    values (p_uid, s.paket, v_bitis, case when s.paket ~ '^yeterlilik-[1-4]$' then s.secilen_dersler else null end)
    on conflict (user_id) do update
      set paket = excluded.paket, dersler = excluded.dersler,
          bitis = greatest(excluded.bitis, case when paket_uyeler.paket = excluded.paket and paket_uyeler.bitis >= current_date then paket_uyeler.bitis else excluded.bitis end);
  return 'ACILDI';
end $$;
revoke all on function public.siparis_paket_bagla(uuid, text) from public, anon, authenticated;

create or replace function public.yeni_uye_paket_bagla()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  begin
    perform public.siparis_paket_bagla(new.id, new.email);
  exception when others then
    raise warning 'yeni_uye_paket_bagla: % (kayit engellenmedi)', sqlerrm;
  end;
  return new;
end $$;

drop trigger if exists yeni_uye_paket_bagla on auth.users;
create trigger yeni_uye_paket_bagla
  after insert on auth.users
  for each row execute function public.yeni_uye_paket_bagla();

-- yonetim_siparis_onayla: bitiş siparişe yazılır, paket tek yoldan (siparis_paket_bagla) açılır
create or replace function public.yonetim_siparis_onayla(p_no text, p_bitis date)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_sonuc text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;

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
