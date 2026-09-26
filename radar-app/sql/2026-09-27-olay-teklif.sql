-- ============================================================================
-- UYGULAMA SAYACI: TEKLİF OLAYLARI (27.09.2026, mobil 1.5.5 — Cem "paralı üyeliğe hiç yönlendirmiyoruz")
--
-- NEDEN: 1.5.5 iki yeni olay gönderiyor: teklif_kart (Ücretsiz ekranındaki paket kartına dokunma),
-- teklif_hosgeldin (üye olunca bir kez gösterilen teklif). olay_say izin listesinde yoksa SESSİZCE atlar.
-- DEĞİŞEN: yalnız izin listesine iki ad eklendi; tablo, yetki, gövde aynı (2026-09-26-uyelik-kapisi.sql).
-- ÖLÇÜM (bastıktan sonra): select olay, sum(sayi) from uygulama_olay group by 1 order by 1;
-- ============================================================================

create or replace function public.olay_say(p_olay text, p_platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_olay not in ('ilk_acilis', 'soru_1', 'soru_3', 'kapi', 'uye_ol', 'giris', 'soru_10', 'soru_30',
                    'ara_karne', 'tam_paket_bak', 'paket_ekrani', 'satin_al_bas', 'satin_aldi', 'hesap_sil',
                    'karma_kisa', 'karma_cok', 'teklif_kart', 'teklif_hosgeldin') then
    return;
  end if;
  if p_platform not in ('android', 'ios', 'web') then
    return;
  end if;
  insert into public.uygulama_olay (olay, platform, sayi) values (p_olay, p_platform, 1)
  on conflict (gun, olay, platform) do update set sayi = public.uygulama_olay.sayi + 1;
end;
$$;

revoke all on function public.olay_say(text, text) from public;
grant execute on function public.olay_say(text, text) to anon, authenticated;
