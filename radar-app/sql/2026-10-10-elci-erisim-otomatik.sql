-- ============================================================================
-- 2026-10-10-elci-erisim-otomatik.sql — ELÇİ HESABI BAĞLANINCA MADDE 10 ERİŞİMİ KENDİLİĞİNDEN AÇILIR
--
-- NEDEN (Cem 10.10: "hesap bağlı değil diye ücretsiz üyelik vermedik deme" → "1 yap 2 yap"):
--   Sözleşme Madde 10 "Elçiye program süresince 3 ay ücretsiz tam erişim verilir." Erişim yönetim ekranından
--   ELLE veriliyordu; 10.10 ölçümünde 4 aktif elçinin yalnız 1'inde vardı (Adile, Hamdiye, Betül'de yoktu —
--   GM elle verdi, hediye id 5/6/7). Hamdiye ve Betül hesaplarını e-posta+şifreyle açtığı için hesap da
--   kendiliğinden bağlanmamıştı (elci_google_bagla yalnız Google).
--
-- NE YAPAR:
--   1) elciler.user_id boştan doluya geçince (yönetimden "Hesaba bağla", bağlama kodu, Google ile kendiliğinden
--      bağlama — üçü de bu kolonu yazar) ve elçi AKTİFse:
--        · bu elçi koduna daha önce Madde 10 erişimi verilmişse (iptal edilmemiş) → bir daha VERİLMEZ
--          (bağ çözülüp başka hesaba bağlansa bile 3 ay bir kez);
--        · hesabın bugün AKTİF bir paketi varsa (ücretli ya da hediye) → DOKUNULMAZ (ücretli paket ezilmez);
--        · yoksa paket_uyeler 'tam', bitiş bugün + 3 ay + paket_hediye kaydı (neden "Elçi sözleşmesi Madde 10…",
--          elci_kodu, veren 'otomatik') — yönetim ekranında "Hediye" olarak görünür, oradan kapatılabilir.
--   2) yonetim_elci_hesaplar() yeniden: + sozlesme_surum (hangi sürümü onayladı) + erisim_paket + erisim_bitis
--      (yönetimde "Ücretsiz erişim" sütunu).
--
-- GÖRMEZ: aktif paketi olan elçiye sonradan 3 ay eklemez (paketi bitince de vermez) · bağlama dışı yolla
--   (SQL ile elle) user_id yazılırsa da çalışır, bu istenen davranış · elçi pasif yapılınca erişimi KAPATMAZ.
-- Push ile otomatik (sql-uygula.yml). Göç içi öz-sınav: sahte hesap + sahte elçi, sonunda GERİ ALINIR.
-- ============================================================================

create or replace function public.elci_erisim_ver()
returns trigger language plpgsql security definer set search_path = public, auth as $$
declare
  v_ep    text;
  v_bitis date := (current_date + interval '3 months')::date;
  v_eski  public.paket_uyeler%rowtype;
  v_var   boolean;
begin
  if new.user_id is null or not new.aktif then return new; end if;
  if tg_op = 'UPDATE' and old.user_id is not distinct from new.user_id then return new; end if;
  if exists (select 1 from public.paket_hediye h
              where h.elci_kodu = new.kod and h.iptal is null and h.neden like 'Elçi sözleşmesi Madde 10%') then
    return new;
  end if;
  select * into v_eski from public.paket_uyeler where user_id = new.user_id;
  v_var := found;
  if v_var and v_eski.bitis >= current_date then return new; end if;
  select lower(u.email) into v_ep from auth.users u where u.id = new.user_id;
  v_ep := coalesce(v_ep, lower(new.email), 'bilinmiyor@tetikte.com');
  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (new.user_id, 'tam', v_bitis, null)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = null;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren)
    values (new.user_id, v_ep, 'tam', v_bitis, 'Elçi sözleşmesi Madde 10 - 3 ay ücretsiz tam erişim (otomatik)', new.kod, 'otomatik');
  return new;
end $$;

revoke all on function public.elci_erisim_ver() from public, anon, authenticated;

drop trigger if exists elci_erisim_ver on public.elciler;
create trigger elci_erisim_ver
  after insert or update of user_id on public.elciler
  for each row execute function public.elci_erisim_ver();

-- 2) yönetim: sözleşme sürümü + erişim bitişi
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
             'sozlesme', e.sozlesme_onay is not null,
             'sozlesme_surum', e.sozlesme_surum,
             'erisim_paket', p.paket,
             'erisim_bitis', p.bitis))
      from public.elciler e
      left join public.paket_uyeler p on p.user_id = e.user_id
  ), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_elci_hesaplar() from public, anon;
grant execute on function public.yonetim_elci_hesaplar() to authenticated;

-- 3) GÖÇ İÇİ ÖZ-SINAV: sahte hesap + sahte elçi; sonunda GERİ ALINIR, bir vaka tutmazsa göç durur ---
do $sinav$
declare
  u1 uuid := '00000000-0000-4000-8000-0000000e1c11';
  u2 uuid := '00000000-0000-4000-8000-0000000e1c12';
  u3 uuid := '00000000-0000-4000-8000-0000000e1c13';
  a1 text; a2 integer; a3 text; a4 integer; a5 integer; a6 integer;
  sonuc text;
begin
  begin
    insert into auth.users (id, email, aud, role) values
      (u1, 'elci-sinav-1@ornek.invalid', 'authenticated', 'authenticated'),
      (u2, 'elci-sinav-2@ornek.invalid', 'authenticated', 'authenticated'),
      (u3, 'elci-sinav-3@ornek.invalid', 'authenticated', 'authenticated');
    delete from public.paket_uyeler where user_id in (u1, u2, u3);   -- başka tetikleyici paket açtıysa temizle
    -- v1: bağsız elçi bağlanınca 3 ay tam açılır
    insert into public.elciler (kod, ad_soyad, aktif) values ('ZZSNV1', 'Sinav Bir', true), ('ZZSNV2', 'Sinav Iki', true);
    update public.elciler set user_id = u1 where kod = 'ZZSNV1';
    select paket || ' ' || bitis into a1 from public.paket_uyeler where user_id = u1;
    -- v2: bağ çözülüp başka hesaba bağlanırsa ikinci kez verilmez
    update public.elciler set user_id = null where kod = 'ZZSNV1';
    update public.elciler set user_id = u3 where kod = 'ZZSNV1';
    select count(*) into a2 from public.paket_uyeler where user_id = u3;
    -- v3: aktif ücretli paketi olan hesaba dokunulmaz
    insert into public.paket_uyeler (user_id, paket, bitis) values (u2, 'sgs', current_date + 30);
    update public.elciler set user_id = u2 where kod = 'ZZSNV2';
    select paket || ' ' || bitis into a3 from public.paket_uyeler where user_id = u2;
    -- v4: hediye kaydı tam 1 tane (ZZSNV1), veren otomatik
    select count(*) into a4 from public.paket_hediye where elci_kodu in ('ZZSNV1', 'ZZSNV2') and veren = 'otomatik';
    -- v5: pasif elçi bağlanınca verilmez
    update public.elciler set aktif = false, user_id = null where kod = 'ZZSNV2';
    delete from public.paket_uyeler where user_id = u2;
    update public.elciler set user_id = u2 where kod = 'ZZSNV2';
    select count(*) into a5 from public.paket_uyeler where user_id = u2;
    -- v6: aynı hesap yeniden yazılırsa (değişmeyen user_id) iki kayıt olmaz
    update public.elciler set user_id = u3 where kod = 'ZZSNV1';
    select count(*) into a6 from public.paket_hediye where elci_kodu = 'ZZSNV1';
    raise exception 'SINAV_GERI_AL';
  exception when others then
    if sqlerrm <> 'SINAV_GERI_AL' then raise; end if;
  end;
  sonuc := format('v1=%s v2=%s v3=%s v4=%s v5=%s v6=%s', a1, a2, a3, a4, a5, a6);
  if not (a1 = 'tam ' || ((current_date + interval '3 months')::date)::text
          and a2 = 0 and a3 = 'sgs ' || (current_date + 30)::text and a4 = 1 and a5 = 0 and a6 = 1) then
    raise exception 'ELCI_ERISIM_SINAV KIRMIZI: %', sonuc;
  end if;
  raise notice 'ELCI_ERISIM_SINAV YESIL: %', sonuc;
end $sinav$;

-- ÖLÇÜ (göç günlüğünde yalnız sayı): aktif + bağlı elçilerden erişimi olmayan
select count(*) as erisimsiz_bagli_elci
  from public.elciler e left join public.paket_uyeler p on p.user_id = e.user_id
 where e.aktif and e.user_id is not null and (p.bitis is null or p.bitis < current_date);   -- 0 beklenir
