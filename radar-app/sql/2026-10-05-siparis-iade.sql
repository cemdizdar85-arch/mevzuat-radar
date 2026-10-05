-- ============================================================================
--  SİPARİŞ İADESİ — 05.10.2026 (Cem: "iade geldiğinde sistem görüyor mu, elçinin hesabından düşecek mi bakalım")
--  sql-uygula.yml OTOMATİK uygular. Tek işlem.
--
--  Neden: iade iyzico panelinden (ya da havale geri gönderilerek) yapılır; bizim sistem bunu KENDİLİĞİNDEN bilmez.
--  Ödenmiş bir siparişi 'iade'ye geçiren yol yoktu (yonetim_siparis_iptal yalnız ödeme bekleyende çalışır) →
--  iade edilen satış elçi raporunda "satış" sayılmaya, paket açık kalmaya devam ederdi.
--  yonetim_siparis_iade(no, neden): yalnız YÖNETİCİ; yalnız 'odendi' sipariş → 'iade'.
--    · Elçi raporu (elci_donem_raporu / elci_panelim) 'iade'yi ayrı sayar, komisyona KATMAZ (2026-09-15-elci-programi.sql).
--    · Alıcının hesabı varsa ve açık paketi BU siparişin paketiyse paket dün tarihiyle KAPANIR.
--    · Kurucu sayacı (kurucu_sayac) yalnız 'odendi' saydığı için iade sayaçtan düşer.
--  Satır SİLMEZ. anon EXECUTE yok.
-- ============================================================================

create or replace function public.yonetim_siparis_iade(p_no text, p_neden text)
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid; v_kapandi boolean := false;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odendi' then raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'iade' where id = s.id;

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is not null then
    update public.paket_uyeler set bitis = current_date - 1
     where user_id = v_uid and paket = s.paket and bitis >= current_date;
    v_kapandi := found;
  end if;
  return jsonb_build_object('siparis', 'iade', 'eposta', s.email, 'odeme', s.odeme, 'elci', s.elci_kodu,
                            'paket_kapandi', v_kapandi, 'neden', left(coalesce(p_neden, ''), 200));
end $$;
revoke all on function public.yonetim_siparis_iade(text, text) from public, anon;
grant execute on function public.yonetim_siparis_iade(text, text) to authenticated;

-- DOĞRULAMA: anon ile POST /rest/v1/rpc/yonetim_siparis_iade → 401/42501 · yönetici olmayan üye → YETKI_YOK
