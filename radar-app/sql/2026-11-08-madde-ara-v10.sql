-- ============================================================================
-- madde_ara v10 (08.11.2026, A-11 GM onerisi 1, Cem onayi "gm onerilerini yap") — ESITLIK BOZUCU ONARIMI
--
-- KUSUR (olculdu 08.11): v9 'order by p.puan desc, p.r desc' diyor ama r HIC DEVREYE GIRMIYOR. Esit sayilan puanlar
--   son bitlerde farkli (float toplama gurultusu; PostgREST 15 haneyle dondugu icin disaridan esit gorunur). Sira bu
--   gurultuyle belirleniyor ve gurultu her robot yazmasinda (belge sayisi/df) degisiyor. Ustelik deneme_puan icindeki
--   'limit adet' de ayni gurultuyle kesiyor. Sonuc: altin test ambara dokunulmadan 47 -> 46 -> 47 gidip geldi
--   (07.11 gece mevzuat.yml 3 kosu kirmizi).
-- ONARIM: deneme_puan TUM aday havuzunu dondurur (metin_aday 300 + ad_aday 60 = en cok 360 < 400); sira
--   round(puan,6) desc, r desc, id asc. r (ts_rank) corpus'tan BAGIMSIZ -> robot yazmalari sirayi oynatmaz; id son
--   bozucu -> tam deterministik. Puan formulu, ayar, aday uretimi, imza, donus, invoker AYNI. deneme_puan DEGISMEZ.
-- KURU KOSU (08.11, canli ambar, salt okuma, istemci benzetimi birebir bu siralama; scratchpad olc-v10.ps1):
--   altin 48: kaynak 47 -> 47, madde 2/8 -> 2/8, degisen vaka 0 · test disi 16: 14 -> 14, degisen 0.
--   KIRILGANLIK (esit grup ici 20 tohumla karistirma): v9 kaynak 2 + madde 2 vaka (idari para cezasi/Kabahatler,
--   tebligat adresi; vergi mahremiyeti, konkordato) -> v10 0 + 0; test disi v10 0.
-- GERI DONUS: v9 govdesi AYNEN madde_ara_v9 olarak korunur (anon/uye yetkisi yok); geri almak icin yeni goc:
--   create or replace function public.madde_ara(sorgu text, adet integer default 6) returns setof dokumanlar
--   language sql stable set search_path to 'public' as $$ select * from public.madde_ara_v9(sorgu, adet) $$;
-- BU GOC SUNU GORMEZ: 48 + 16 sorgu disindaki sorgularin sirasi (yalniz esit puanli satirlarin ici degisir).
-- ============================================================================

-- 1) v9 yedegi (birebir 2026-11-07-madde-ara-v9.sql govdesi)
CREATE OR REPLACE FUNCTION public.madde_ara_v9(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{"adw":0,"tebw":0.75}'::jsonb) p
join dokumanlar d on d.id = p.id
order by p.puan desc, p.r desc
$function$;
revoke execute on function public.madde_ara_v9(text, integer) from public, anon, authenticated;

-- 2) canli madde_ara v10 (imza, donus, invoker AYNI)
CREATE OR REPLACE FUNCTION public.madde_ara(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
select d.*
from (
  select p.id, round(p.puan::numeric, 6) as py, p.r
  from public.madde_ara_deneme_puan(sorgu, 400, '{"adw":0,"tebw":0.75}'::jsonb) p
  order by 2 desc, p.r desc, p.id
  limit greatest(coalesce(adet,6),1)
) p
join dokumanlar d on d.id = p.id
order by p.py desc, p.r desc, p.id
$function$;

-- 3) goc ici olcu: tutmazsa butun goc geri alinir
do $$
declare a text; b text;
begin
  if not exists (select 1 from public.madde_ara('anayasaya gore vergi odevi', 6) where kaynak_ad like 'Anayasa (2709)%') then
    raise exception 'madde_ara v10 olcusu tutmadi: Anayasa ilk 6da yok';
  end if;
  if not exists (select 1 from public.madde_ara_v9('anayasaya gore vergi odevi', 6)) then raise exception 'madde_ara_v9 yedegi bos'; end if;
  -- esitlik bozucu canli mi: ayni sorgu iki kez -> ayni id dizisi; ilk 30'da round(puan) esitlerinde r azalan
  select string_agg(id::text, ',') into a from public.madde_ara('idari para cezasina basvur yolu', 30);
  select string_agg(id::text, ',') into b from public.madde_ara('idari para cezasina basvur yolu', 30);
  if a is distinct from b then raise exception 'madde_ara v10 deterministik degil'; end if;
  if (select count(*) from public.madde_ara('idari para cezasina basvur yolu', 30)) <> 30 then raise exception 'madde_ara v10 30 satir donmedi'; end if;
  if exists (select 1 from public.madde_ara('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m where coalesce(m.tur,'') like 'cikmis%') then
    raise exception 'madde_ara v10 cikmis%% sizdiriyor';
  end if;
end $$;
