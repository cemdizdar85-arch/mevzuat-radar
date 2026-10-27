-- ============================================================================
--  GEÇENE KADAR TETİKTE — YENİDEN CANLI  ·  28.10.2026 00:00 TR (site kolu)
--
--  CEM 27.10: "gece 12'den sonra canlıya alacağız". 2026-10-27-gecene-kadar-tetikte.sql kampanyayı kurdu,
--  2026-10-27-gecene-kadar-tetikte-geri-al.sql vaktinden önce çıktığı için kapattı. Göç kütüğü dosya adına baktığı
--  için ikisi yeniden koşmaz; bu dosya veritabanını kampanya hâline geri getirir:
--   1) elci_indirim sgs 400 → 600 (1 Kasım 2026 23:59 TR'de erken-kayit-kapat.yml 400'e geri yazar)
--   2) ERKEN600 · INSTA600 · GOOGLE600 · TELEGRAM600 yeniden açık (satırlar 27.10'da kuruldu, aktif = false idi)
--  _paket_kapsar son20-sgs dalı geri almada BIRAKILMIŞTI → dokunulmaz, öz-sınavda ölçülür.
--  GERİ ALMA: 2026-10-27-gecene-kadar-tetikte-geri-al.sql gövdesi.
-- ============================================================================

update public.elci_indirim set indirim_tl = 600 where paket = 'sgs';
update public.elciler set aktif = true where kod in ('ERKEN600', 'INSTA600', 'GOOGLE600', 'TELEGRAM600');

do $$
declare k text; n int := 0;
begin
  if (select count(*) from public.elciler where kod in ('ERKEN600','INSTA600','GOOGLE600','TELEGRAM600') and aktif) <> 4 then
    raise exception 'OLCU: dort kanal kodundan biri yok ya da kapali'; end if;
  foreach k in array array['ERKEN400','INSTA400','GOOGLE400','TELEGRAM400','ERKEN600','INSTA600','GOOGLE600','TELEGRAM600'] loop
    if public.elci_kodu_kontrol(k, 'sgs') <> 600 then raise exception 'OLCU: % sgs 600 vermiyor (%)', k, public.elci_kodu_kontrol(k, 'sgs'); end if;
    if public.elci_kodu_kontrol(k, 'son20-sgs') <> 0 then raise exception 'OLCU: % 7 Deneme paketine indirim veriyor', k; end if;
    n := n + 2;
  end loop;
  if public.elci_kodu_kontrol('YOKBOYLEKOD', 'sgs') <> 0 then raise exception 'OLCU: sahte kod indirim aldi'; end if;
  if not public._paket_kapsar('sgs', null, 'son20-sgs', null) then raise exception 'OLCU: sgs uyesi 7 Deneme alabiliyor'; end if;
  if public._paket_kapsar('son20-sgs', null, 'sgs', null) then raise exception 'OLCU: 7 Deneme uyesi Tam Pakete yukselemiyor'; end if;
  if public._paket_sinavi('son20-sgs') is not null then raise exception 'OLCU: son20-sgs bir sinava eslendi (banka acilir)'; end if;
  n := n + 5;
  raise notice 'GECENE KADAR TETIKTE YENIDEN OZ-SINAV: % vaka TAMAM', n;
end $$;
