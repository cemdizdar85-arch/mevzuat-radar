-- ============================================================================
--  ALACAK VITRINI - KAPSAM SERHI (28.08.2026) · 2. goç, makro-suzgec'ten SONRA
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--
--  KUSUR: sayfa her yerde "SON 1 YIL" diye VARSAYIYORDU. Olculdu, dogru degil:
--    konkordato -> 19.08.2025 - 28.08.2026  (5.502 ilan, ~1 yil TAM)
--    iflas      -> 06.04.2026 - 28.08.2026  (  415 ilan, ~4,7 AY)
--  Yani "Iflas - son 1 yildaki 415 ilanda cografi yogunluk" YANLIS HUKUMDU.
--  Daha kotusu: iki turun oranlari yan yana konunca (il bazli iflas yuzdesi)
--  farkli zaman pencerelerinden gelen paydalar kiyaslaniyordu - Denizli %18,8
--  gibi tamamen gecersiz bir "bulgu" bu yuzden dogdu ve geri cekildi.
--
--  KOK SEBEP DEGIL: etiketleme dogru calisiyor. ilan.gov.tr'de iki alt kategori
--  var ve slug ikisini ayiriyor:
--    iflas-hukuku-davalari-iflas-ve-tasfiye-ilanlari-...   -> iflas
--    iflas-hukuku-davalari-konkordato-ve-muhlet-iik-288... -> konkordato
--  Gercek sebep: 'iflas-ve-tasfiye' alt kategorisi havuzda 06.04.2026 oncesi HIC
--  YOK (hasat kapsamasi ya da kaynagin kendisi). Ayri is olarak acildi.
--
--  COZUM (kalici sigorta): sayfa artik tarih penceresini VARSAYMAZ, secili
--  suzgecin OLCULMUS ilk/son tarihini ve gun sayisini kasadan okur. Kapsam bir
--  yildan belirgin kisaysa ekranda ACIKCA uyarir. Bundan sonra hangi turde ne
--  kadar veri varsa sayfa onu soyler.  Bkz [[olcemedigine-kusur-deme]]
--
--  ONCE 2026-08-28-alacak-makro-suzgec.sql basilmis olmali (iller suzgeci).
-- ============================================================================

create or replace function public.alacak_vitrin(
  p_durum text default null,
  p_tur   text default null
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select jsonb_build_object(
    'adet',    (select count(*) from public.alacak_ilan),
    'son30',   (select count(*) from public.alacak_ilan where tarih >= current_date - 30),
    'son30Konkordato', (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='konkordato'),
    'son30Iflas',      (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='iflas'),
    'enYeniTarih', (select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan),
    'enYeniIso',   (select to_char(max(tarih),'YYYY-MM-DD') from public.alacak_ilan),
    'turSayilari', coalesce((
      select jsonb_object_agg(t.k, t.n)
      from (
        select coalesce(nullif(tur,''),'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'durumlar', coalesce((
      select jsonb_object_agg(d.k, d.n)
      from (
        select coalesce(karar_durumu,'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
          and (p_tur is null or coalesce(nullif(tur,''),'diger') = p_tur)
        group by 1
      ) d
    ), '{}'::jsonb),
    'secilenAdet', (
      select count(*) from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    -- 28.08 YENI: secili suzgecin OLCULMUS kapsami. Sayfa "son 1 yil" demeyi
    -- birakir, bu ucluyu basar. secilenGun kucukse ekranda kirmizi serh cikar.
    'secilenIlk', (
      select to_char(min(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenSon', (
      select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenGun', (
      select (max(tarih) - min(tarih))::int from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    -- 28.08: TUR BASINA ilk tarih. "Tumu" ekraninda sayac "son 1 yilda 5.850
    -- ilan (5.435 konkordato · 415 iflas)" diyor; 415'in yalnizca 4,7 aylik
    -- oldugunu orada da soylemek zorundayiz, yoksa en cok gorulen ekran yanlis
    -- hukum basar. Tarih SAYFAYA GOMULMEZ, buradan okunur (rakam disiplini).
    'turIlk', coalesce((
      select jsonb_object_agg(t.k, t.ilk)
      from (
        select coalesce(nullif(tur,''),'diger')  as k,
               to_char(min(tarih),'DD.MM.YYYY')  as ilk
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'turGun', coalesce((
      select jsonb_object_agg(t.k, t.gun)
      from (
        select coalesce(nullif(tur,''),'diger') as k,
               (max(tarih) - min(tarih))::int   as gun
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'illerSuzgecli', true,
    'iller', coalesce((
      select jsonb_agg(jsonb_build_object('il', g.il_ad, 't', g.t, 'k', g.k, 'i', g.i)
                       order by g.t desc)
      from (
        select coalesce(nullif(il,''),'Belirtilmemiş') as il_ad,
               count(*)                                as t,
               count(*) filter (where tur='konkordato') as k,
               count(*) filter (where tur='iflas')      as i
        from public.alacak_ilan
        where tarih >= current_date - 365
          and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
          and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
        group by 1
        order by 2 desc
        limit 12
      ) g
    ), '[]'::jsonb),
    'ilanlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'ilanNo', ilan_no, 'baslik', baslik, 'kurum', kurum, 'il', il,
        'tarih', tarih_str, 'tur', tur, 'url', url, 'borclu', borclu, 'vkn', vkn,
        'karar', karar_durumu, 'muhletBitis', muhlet_bitis
      ) order by tarih desc nulls last)
      from (
        select * from public.alacak_ilan
        where (p_durum is null or coalesce(karar_durumu,'diger') = p_durum)
          and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        order by tarih desc nulls last limit 60
      ) v
    ), '[]'::jsonb)
  )
$fn$;

grant execute on function public.alacak_vitrin(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- KOSTUKTAN SONRA TEYIT:
--   select public.alacak_vitrin(null,'iflas')      ->> 'secilenIlk',  -- 06.04.2026
--          public.alacak_vitrin(null,'iflas')      ->> 'secilenGun';  -- ~144
--   select public.alacak_vitrin(null,'konkordato') ->> 'secilenIlk',  -- 29.08.2025
--          public.alacak_vitrin(null,'konkordato') ->> 'secilenGun';  -- ~364
-- Iki tur FARKLI kapsam gostermeli; iflasta gun sayisi 300'un ALTINDA olmali
-- (sayfa o esikte kirmizi kapsam serhini basar).
-- ---------------------------------------------------------------------------
