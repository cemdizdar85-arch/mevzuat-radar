-- ============================================================================
--  ALACAK VITRINI - MAKRO SINYAL SUZGECI (28.08.2026)
--  Supabase SQL Editor'de calistir (bjrleanjpyujtajmazxn). Tek seferlik.
--
--  KUSUR (Cem 28.08, ekran goruntusuyle): "Tumu basiyorum, Konkordato basiyorum,
--  Iflas basiyorum - MAKRO SINYAL - SON 1 YIL blogu HIC degismiyor."
--
--  KOK SEBEP - IKI AYAK:
--   (1) SUNUCU (bu dosya): 27.08 goçünde p_tur/p_durum suzgeci 'durumlar',
--       'secilenAdet' ve 'ilanlar' bloklarina eklendi ama 'iller' blogu
--       DOKUNULMADAN kaldi. Yani hangi tur secilirse secilsin kasa ayni
--       arsiv-geneli il dagilimini donduruyordu.
--   (2) ISTEMCI (alacak-radari.html): aiMakro() yalniz ILK yuklemede
--       cagriliyordu, AI_ILLER de yalniz ilk yanittan okunuyordu. Sunucu dogru
--       veri donse bile ekrandaki blok tazelenmiyordu. O ayak duzeltildi.
--
--  IKINCI KUSUR (ayni blokta, olcum sirasinda yakalandi): baslik
--  "Arsivdeki 5.917 ilanda ... SON 1 YIL" diyordu. 5.917 'adet' alanindan gelir
--  ve TUM TABLOYU sayar (tarih suzgeci YOK); alttaki il dagilimi ise son 365
--  gunden (5.850) hesaplanir. Yani basliktaki rakam ile altindaki cubuklar farkli
--  evrenden geliyordu - 67'lik sessiz celiski. Sayfa artik basliga 'secilenAdet'i
--  basar (365 gun + ayni suzgec), rakam ile cubuk ayni evrenden gelir.
--
--  COZUM: 'iller' de p_tur/p_durum'dan gecer + yanita 'illerSuzgecli' bayragi
--  eklenir. Bayrak yoksa (bu goç basilmamissa) sayfa basligi "bu dagilim ARSIV
--  GENELIDIR, sectigin suzgece gore daralmamistir" serhini basar - suzgeclimis
--  gibi gosterip yanlis hukum kurmaz (kor kalma kurali).
--
--  NOT: 'turSayilari' KASITLI olarak suzgecten BAGIMSIZ kalir - tur dugmelerinin
--  kendi rakamlaridir (Konkordato'ya basinca Iflas dugmesinin sayisi kaybolmaz).
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
    -- 27.08 BAYATLIK NOBETI: en yeni ilanin tarihi disari verilir; sayfa 3 gunden
    -- eskiyse iddiayi yumusatip uyari basar.
    'enYeniTarih', (select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan),
    'enYeniIso',   (select to_char(max(tarih),'YYYY-MM-DD') from public.alacak_ilan),
    -- TUR sayaclari: suzgecten BAGIMSIZ (tur dugmelerinin kendi rakami).
    'turSayilari', coalesce((
      select jsonb_object_agg(t.k, t.n)
      from (
        select coalesce(nullif(tur,''),'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    -- Karar durumu sayaclari: SECILI TURE gore (27.08).
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
    -- Secili tur+durum icin arsivdeki TOPLAM (liste 60 tavanli oldugu icin sayac
    -- bunu kullanir). Sayfa makro blogunun basligini da BUNDAN basar.
    'secilenAdet', (
      select count(*) from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    -- 28.08 DUZELTME: il dagilimi da AYNI suzgecten gecer.
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
-- KOSTUKTAN SONRA TEYIT (ayni editorde calistir, GOZUNLE KARSILASTIR):
--
--   select public.alacak_vitrin(null,'iflas')  -> 'iller'
--   select public.alacak_vitrin(null,'konkordato') -> 'iller'
--   select public.alacak_vitrin(null,null)     -> 'iller'
--
-- UCU DE FARKLI SAYILAR DONMELI. Ayni donuyorsa goç basilmamistir.
-- Ayrica iflas ciktisinda her ilin 'k' degeri 0, konkordato ciktisinda her ilin
-- 'i' degeri 0 olmalidir (suzgecin gercekten islediginin kanit).
--
-- SAGLAMA (il toplamlari <= secilenAdet olmali; iller top-12 ile tavanli):
--   select (select sum((x->>'t')::int) from jsonb_array_elements(
--             public.alacak_vitrin(null,'iflas')->'iller') x) as il_toplam_top12,
--          public.alacak_vitrin(null,'iflas')->>'secilenAdet' as secilen;
-- ---------------------------------------------------------------------------
