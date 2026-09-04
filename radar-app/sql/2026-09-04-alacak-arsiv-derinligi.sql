-- ============================================================================
--  ALACAK VITRINI - ARSIV DERINLIGI (04.09.2026) · 6. goç, kapsam-serhi'nden SONRA
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--
--  NIYE (Cem 04.09: "5 binden fazla YILA ulasmak istiyorum"):
--    Kaynak (ilan.gov.tr) TAM 365 gun tutuyor; 1 yildan eskisi hicbir acik
--    kaynaktan alinamiyor (04.09 olcumu: canli API eski id'ye null, Wayback
--    sayfalari bos kabuk, Wayback API JSON'larinin ~%2'si bizim kategori).
--    Arsiv YALNIZ ZAMANLA derinlesir: kaynaktan dusen ilani kasa tutar
--    (alacak_yaz silmez). 04.09'da kasa 6.011 / son-365 5.870 -> 141 eski kayit
--    birikmis. Ama vitrin HER sayaci 'tarih >= current_date - 365' ile kesiyordu;
--    arsiv buyudukce ekran onu HIC gostermeyecekti ve "son 1 yil" ibaresi
--    yanlislasacakti.
--
--  COZUM: sayaclar (turSayilari / durumlar / secilenAdet / secilenIlk-Son-Gun /
--    turIlk / turGun / iller) 365 gun suzgecinden CIKAR, arsivin tamamini sayar.
--    Yeni alanlar: arsivIlk / arsivSon / arsivGun (arsivin olculmus penceresi)
--    + arsivDerinligi:true bayragi. Sayfa bayragi gorunce "son 1 yil" demeyi
--    birakir, "<arsivIlk>'ten bu yana" der; bayrak yoksa eski cumle kalir
--    (kor kalma kurali: goc basilmadan sayfa yanlis hukum kurmaz).
--    son30 sayaclari ve 60'lik liste DEGISMEDI.
--
--  KAPSAM SERHI ARTIK GORECELI: "eksik" = secimin gun sayisi arsiv gununden
--    60+ gun kisa (sayfa hesaplar). Iflas 06.04.2026'dan basladigi icin
--    serh onda kalir; konkordato arsivle birlikte buyur.
--
--  ONCE 2026-08-28-alacak-kapsam-serhi.sql basilmis olmali.
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
    -- 04.09 YENI: arsivin OLCULMUS penceresi. Sayfa "son 1 yil" yerine bunu basar.
    'arsivDerinligi', true,
    'arsivIlk', (select to_char(min(tarih),'DD.MM.YYYY') from public.alacak_ilan where tarih is not null),
    'arsivSon', (select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan where tarih is not null),
    'arsivGun', (select (max(tarih) - min(tarih))::int from public.alacak_ilan where tarih is not null),
    'tarihsiz', (select count(*) from public.alacak_ilan where tarih is null),
    'turSayilari', coalesce((
      select jsonb_object_agg(t.k, t.n)
      from (
        select coalesce(nullif(tur,''),'diger') as k, count(*) as n
        from public.alacak_ilan
        group by 1
      ) t
    ), '{}'::jsonb),
    'durumlar', coalesce((
      select jsonb_object_agg(d.k, d.n)
      from (
        select coalesce(karar_durumu,'diger') as k, count(*) as n
        from public.alacak_ilan
        where (p_tur is null or coalesce(nullif(tur,''),'diger') = p_tur)
        group by 1
      ) d
    ), '{}'::jsonb),
    'secilenAdet', (
      select count(*) from public.alacak_ilan
      where (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenIlk', (
      select to_char(min(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenSon', (
      select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenGun', (
      select (max(tarih) - min(tarih))::int from public.alacak_ilan
      where (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'turIlk', coalesce((
      select jsonb_object_agg(t.k, t.ilk)
      from (
        select coalesce(nullif(tur,''),'diger')  as k,
               to_char(min(tarih),'DD.MM.YYYY')  as ilk
        from public.alacak_ilan
        group by 1
      ) t
    ), '{}'::jsonb),
    'turGun', coalesce((
      select jsonb_object_agg(t.k, t.gun)
      from (
        select coalesce(nullif(tur,''),'diger') as k,
               (max(tarih) - min(tarih))::int   as gun
        from public.alacak_ilan
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
        where (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
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
--   select v->>'adet' as adet, v->>'arsivIlk' as ilk, v->>'arsivGun' as gun,
--          (select sum(x::int) from jsonb_each_text(v->'turSayilari') t(k,x)) as tur_toplam
--   from public.alacak_vitrin() v;
--   -> tur_toplam = adet - tarihsiz olmali (365 suzgeci kalkti, sayaclar arsivi sayar)
--   -> arsivIlk 04.09.2026'da 19-20.08.2025 civari; her gun ayni kalir, arsiv buyur.
-- ---------------------------------------------------------------------------
