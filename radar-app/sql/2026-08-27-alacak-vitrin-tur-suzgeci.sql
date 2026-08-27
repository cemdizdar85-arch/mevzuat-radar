-- ============================================================================
--  ALACAK VITRINI - TUR SUZGECI (27.08.2026)
--  Supabase SQL Editor'de calistir (bjrleanjpyujtajmazxn). Tek seferlik.
--
--  KUSUR (Cem 27.08, ekran goruntusuyle): kullanici "Iflas" dugmesine basinca
--  karar durumu dugmeleri HALA ARSIV GENELININ sayilarini gosteriyordu -
--  "Kesin muhlet 1.354" yaziyordu ama IFLAS turunde kesin muhlet YOKTUR.
--  Kullanici o dugmeye basinca liste bos donuyor ve sayac "0 iflas ilan bu
--  aramaya uyuyor" diyordu; bu da yanlis: arsivde 404 iflas ilani VAR.
--
--  OLCULEN GERCEK (27.08.2026, son 365 gun, service_role ile sayildi):
--    konkordato: cagri 526 · gecici 1115 · kesin 1354 · uzatma 712 · tasdik 42
--                ret 709 · iflas/tasfiye 16 · durusma 507 · muhlet 92 · diger 355
--    iflas     : cagri  25 · gecici    0 · kesin    0 · uzatma   0 · tasdik  0
--                ret   6 · iflas/tasfiye 158 · durusma 17 · muhlet 0 · diger 198
--  Yani iflas turunde 6 durumun sayaci SIFIR; sayfa bunlari 1.115 / 1.354 diye
--  gosteriyordu. Sayac 0 olan durum zaten dugme olarak basilmiyor (sayfadaki
--  kural), o yuzden sayaclar TURE GORE gelince yanlis dugmeler kendiliginden
--  kaybolur.
--
--  COZUM: alacak_vitrin'e p_tur eklendi. Artik durum sayaclari, listelenen
--  ilanlar ve "secilenAdet" hepsi ayni suzgecten gecer - ekranda gorunen her
--  rakam kasada sayilmis rakamdir (rakam disiplini).
--  Ek olarak:
--    turSayilari  -> tur dugmelerinin yanina basilacak GERCEK sayilar
--    secilenAdet  -> secili tur+durum icin arsivdeki TOPLAM (liste 60 tavanli,
--                    sayac artik "0" degil "404 ilan var, en yenisi 60" der)
--  Satir tavani 60'ta kaldi: vitrin dataset degildir (19.08 gizli kasa karari).
-- ============================================================================

-- Eski tek parametreli imza dusurulmezse PostgREST iki imza arasinda kalir.
drop function if exists public.alacak_vitrin();
drop function if exists public.alacak_vitrin(text);
drop function if exists public.alacak_vitrin(text, text);

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
    -- 27.08 BAYATLIK NOBETI: sayfa "son 30 gunde N ilan" derken akisin gercekten
    -- taze oldugunu da KANITLAMALI. Hasat kirilirsa sayi sessizce kuculuyor ama
    -- sayfa hala canliymis gibi duruyordu. En yeni ilanin tarihi disari verilir;
    -- sayfa 3 gunden eskiyse iddiayi yumusatip uyari basar.
    'enYeniTarih', (select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan),
    'enYeniIso',   (select to_char(max(tarih),'YYYY-MM-DD') from public.alacak_ilan),
    -- 27.08: TUR sayaclari (suzgecten BAGIMSIZ - tur dugmelerinin kendi rakami)
    'turSayilari', coalesce((
      select jsonb_object_agg(t.k, t.n)
      from (
        select coalesce(nullif(tur,''),'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    -- 20.08: karar durumu sayaclari — filtre dugmelerinin yanindaki rakamlar
    -- BURADAN basilir; sayfaya gomulu rakam yazilmaz (rakam disiplini).
    -- 27.08: artik SECILI TURE gore sayilir (kusurun kok sebebi buydu).
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
    -- 27.08: secili tur+durum icin arsivdeki TOPLAM. Liste 60 tavanli oldugu
    -- icin sayac bunu kullanir; "0 ilan uyuyor" gibi yanlis hukum kalkti.
    'secilenAdet', (
      select count(*) from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
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
-- KOSTUKTAN SONRA TEYIT (ayni editorde calistir, gozunle gor):
--   select public.alacak_vitrin(null,'iflas') -> 'durumlar' icinde
--   kesin_muhlet/gecici_muhlet/uzatma/tasdik/muhlet ANAHTARLARI HIC OLMAMALI,
--   'secilenAdet' ~404 olmali. Konkordato icin kesin_muhlet ~1354 kalmali.
-- ---------------------------------------------------------------------------
