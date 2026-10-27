-- ============================================================================
--  GEÇENE KADAR TETİKTE — GERİ AL  ·  27.10.2026
--
--  CEM 27.10 akşam: "gece 12'den sonra canlıya alacağız dedik ... kaldır kampanyayı". 224eb3af kampanyayı vaktinden
--  önce canlıya çıkardı; site dosyaları aynı commit'te geri alındı. Bu göç veritabanı tarafını eski hâline döndürür:
--   1) elci_indirim sgs 600 → 400 (fb2c5b78 erken kayıt tutarı; ERKEN400/INSTA400/GOOGLE400/TELEGRAM400 yine 400 verir)
--   2) ERKEN600 · INSTA600 · GOOGLE600 · TELEGRAM600 kapalı (satır silinmez, aktif = false)
--  _paket_kapsar son20-sgs dalı BIRAKILDI: yalnız son20-sgs siparişini durdurur, site o paketi artık satmıyor.
-- ============================================================================

update public.elci_indirim set indirim_tl = 400 where paket = 'sgs';
update public.elciler set aktif = false where kod in ('ERKEN600', 'INSTA600', 'GOOGLE600', 'TELEGRAM600');

do $$
declare k text;
begin
  foreach k in array array['ERKEN400','INSTA400','GOOGLE400','TELEGRAM400'] loop
    if public.elci_kodu_kontrol(k, 'sgs') <> 400 then raise exception 'OLCU: % sgs 400 vermiyor (%)', k, public.elci_kodu_kontrol(k, 'sgs'); end if;
  end loop;
  foreach k in array array['ERKEN600','INSTA600','GOOGLE600','TELEGRAM600'] loop
    if public.elci_kodu_kontrol(k, 'sgs') <> 0 then raise exception 'OLCU: % hala indirim veriyor', k; end if;
  end loop;
  raise notice 'GECENE KADAR TETIKTE GERI AL OZ-SINAV: 8 vaka TAMAM';
end $$;
