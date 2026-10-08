-- ============================================================================
--  AKRAN YÜZDESİNDEN TEST OTURUMLARI HARİÇ — 2 (08.10.2026)
--  Eskitir: 2026-10-08-sik-yuzdesi-test-haric.sql (aynı fonksiyon; uygulanmış göç değiştirilmez, liste burada büyür).
--  Eklenen: os-muytfbpt-r64a4y — site oturumunun eski ornek-sorular.html'i (dae9659d) yerelde denemesi: Yeterlilik 1. soru
--  (smmm-4k-a-fmuh-zor-r3/kp-02) "A şıkkı, tek tık" beyanı tablodaki satırla birebir (A, 2 sn, 2026-10-08 00:45 UTC).
--  Bilerek EKLENMEYEN (gerçek ziyaretçi sayılır): os-muz3s1a8-z2id1r (C şıkkı - beyanla uyuşmaz), tgyas43emtu2fmih (site oturumu
--  "benim değil" dedi). Kanıtı olmayan cevap hariç tutulmaz. Satır SİLİNMEZ; DDL/tablo yok.
-- ============================================================================
create or replace function public.sik_yuzdesi(p_soru_id text)
returns table(secim text, n bigint)
language sql stable security definer set search_path = public
as $$
  select secim, count(*)::bigint as n
  from public.cevap_kayit
  where soru_id = p_soru_id and length(p_soru_id) between 3 and 120
    and coalesce(oturum, '') not in (
      'pj0d61czmuy98c1i',     -- 08.10 site oturumunun canlı denetimi (ornek-sgs, 5 satır)
      'os-muytfbpt-r64a4y'    -- 08.10 site oturumunun yerel denemesi (eski ornek-sorular.html, 1 satır)
    )
  group by secim;
$$;
revoke all on function public.sik_yuzdesi(text) from public;
grant execute on function public.sik_yuzdesi(text) to anon, authenticated;

-- ÖLÇÜ: anon POST /rest/v1/rpc/sik_yuzdesi {"p_soru_id":"smmm-4k-a-fmuh-zor-r3/kp-02"} -> yalnız C=1 (os-muz3s1a8)
