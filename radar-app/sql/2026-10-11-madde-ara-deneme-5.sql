-- ============================================================================
-- madde_ara_deneme v5 (11.10.2026) — VARSAYILAN tebw 0.6 -> 0.75
--
-- v4 (tebw 0.6) altin testte 47/48 · madde 3/8 verdi. Ama TEST DISI 16 sorgu
-- (scratch kiyas, v8 ile yan yana) uc kayip gosterdi: 'damga vergisi kira
-- sozlesmesi' (DVK Genel Teblig 60 ilk 6'dan cikti), 'uzlasma ile vergi cezasi
-- indirimi' (VUK GT 519 cikti), 'amortisman ayirma usulleri'. Ucunde de asil
-- uygulama ayrintisini teblig tasiyor. tebw 0.75'te ilk ikisi geri geliyor;
-- altin test yine 47/48 (madde 2/8 = taban). 0.6'nin tek ek kazanci MTV m.9
-- madde duzeyiydi - test disi uc kayba degmez. Altin teste gore ayar
-- yapip test disini bozmak = teste ezber.
-- Canli madde_ara AYNEN.
-- ============================================================================

create or replace function public.madde_ara_deneme(sorgu text, adet integer default 6)
returns setof dokumanlar
language sql stable
set search_path = public
as $fn$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{"adw":0,"tebw":0.75}'::jsonb) p
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
