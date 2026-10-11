-- ============================================================================
-- madde_ara_deneme v4 (11.10.2026) — OLCULEN AYAR VARSAYILAN YAPILIR
--
-- Ayar taramasi (motor/ambar-testi.ps1, MADDE_ARA_RPC=madde_ara_deneme_puan,
-- 48 vaka; v8 bugun 42/48, madde 2/8):
--   {}                       47 · madde 1    (adw 0.6)
--   adw 0 / 0.3 / 1.0        47 · madde 2/1/1 -> ad PUANI kaynak kazandirmiyor,
--                                             madde duzeyini 1 dusuruyor
--   adw 0, es kapali         45  (kira, apartman duser)  -> es anlam +2
--   adw 0, tebw 1.0          45  (GVK, Tic. Sicili duser) -> teblig agirligi +2
--   adw 0, adaday 0          47  (Anayasa havuz sinirinda sansla giriyor;
--                                 sozluk onu KESIN havuza sokar - nötr ama saglam)
--   adw 0, tebw 0.9 / 0.75   47 · madde 2
--   adw 0, tebw 0.6          47 · madde 3  (MTV m.9 de bulunur)  <-- SECILEN
--   adw 0, tebw 0.5          46  (e-fatura / VUK 509 GT duser: ucurum 0.5'te)
-- Hep dusen tek vaka: 'kacakcilik sucu hapis cezasi defter' (VUK m.359) -
-- Kacakcilikla Muc. K. / CMK / TCK maddeleri sorgunun dort jetonunu da tasiyor.
--
-- Yalniz madde_ara_deneme'nin ayari degisir; canli madde_ara AYNEN.
-- ============================================================================

create or replace function public.madde_ara_deneme(sorgu text, adet integer default 6)
returns setof dokumanlar
language sql stable
set search_path = public
as $fn$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{"adw":0,"tebw":0.6}'::jsonb) p
join dokumanlar d on d.id = p.id
order by p.puan desc, p.r desc
$fn$;

do $olcu$
declare n int;
begin
  select count(*) into n
  from public.madde_ara_deneme('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m
  where coalesce(m.tur,'') like 'cikmis%';
  if n > 0 then raise exception 'madde_ara_deneme cikmis%% sizdiriyor: %', n; end if;
end
$olcu$;
