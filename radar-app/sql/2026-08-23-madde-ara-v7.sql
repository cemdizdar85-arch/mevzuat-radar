-- ============================================================================
-- madde_ara v7 (23.08.2026) — DISLAMA TEK BIR TURDEN TUM 'cikmis%' AILESINE
--
-- NEDEN: v6, sinav kitapciklarini `tur <> 'cikmis-soru'` diye disliyordu.
-- 23.08'de ambar buyudu ve dislama YETMEZ oldu:
--   * tur='cikmis-komisyon-cevabi' — TESMER Yeterlilik klasik donem (2008-2025)
--     sinav komisyonunun RESMI cozumleri, 402 belge. TESMER bu donemler icin
--     soru kitapcigi yayimlamiyor; yayimlanan PDF'lerin 402/402'si "SINAV
--     KOMISYONU CEVAPLARI" ile basliyor (olculdu). Degerli malzeme ama
--     musavirin hukuki sorusuna KAYNAK DEGIL.
-- Bu belgeler de tek satirda on binlerce karakter tasir; v6'nin tarif ettigi
-- "tek satir her kelimeyi icerir, FTS'i kazanir" sisligi aynen tekrarlanirdi.
--
-- v7 = v6 AYNEN + uc yerdeki suzgec `tur <> 'cikmis-soru'` yerine
--      `coalesce(tur,'') not like 'cikmis%'`.
-- Boylece bundan sonra eklenecek her 'cikmis-*' turu OTOMATIK dislanir;
-- tur adi 'cikmis' ile baslatildigi surece bu SQL bir daha elle guncellenmez.
-- (Ayni ayiklama radar-app/edge/net-cevap.ts icindeki AYIKLA setinde de var -
--  o ikinci agdir, asil kapi burasidir.)
--
-- CALISTIRMA: Supabase SQL Editor'de tek blok. Sonra asagidaki dogrulamalar.
-- GERI DONUS: 2026-08-19-madde-ara-v6.sql
-- ============================================================================

create or replace function public.madde_ara(sorgu text, adet integer default 6)
returns setof dokumanlar
language sql stable
as $fn$
with tok as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
agir as (
  select to_tsquery('simple', t.w || ':*') as tq,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
           / ((select count(*) from dokumanlar dd
                where coalesce(dd.tur,'') not like 'cikmis%'
                  and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) + 1) ) + 0.3 as agirlik
  from tok t
),
q as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
),
aday as (
  select d.ctid as rid, d.arama_fold as af, d.tur as tur,
         ts_rank(d.arama_fold, q.orq) as r
  from dokumanlar d, q
  where q.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ q.orq
  order by r desc
  limit 300
),
puan as (
  select a.rid, a.r,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s,
         (select count(*) from agir g where a.af @@ g.tq) as kapsanan,
         case a.tur
           when 'teori-notu' then 0.55
           when 'standart'   then 0.85
           else 1.0
         end as turw
  from aday a
)
select d.* from dokumanlar d
join puan p on d.ctid = p.rid
order by (p.s * p.turw * (1 + 0.35 * greatest(p.kapsanan - 1, 0))) desc, p.r desc
limit greatest(coalesce(adet,6),1)
$fn$;

-- ---- DOGRULAMA ----
-- (a) hicbir sonucta 'CIKMIS SINAV' gecmemeli
select kaynak_ad, tur from madde_ara('isci ihbar onel sureleri', 6);
select kaynak_ad, tur from madde_ara('veraset beyannamesi verme zamani', 6);
select kaynak_ad, tur from madde_ara('emeklilik icin yas ve prim gun sarti', 6);
select kaynak_ad from madde_ara('kira artisi en fazla ne kadar olabilir tufe', 6);
select kaynak_ad from madde_ara('kacakcilik sucu hapis cezasi defter', 6);

-- (b) klasik komisyon cevaplarinin siznadigini dogrudan olc:
--     bu sorgu yevmiye/matrah dili tasidigi icin v6 altinda komisyon cevabi
--     dondurmeye en yatkin olandir. Sonuc bos ise kapi calisiyor.
select count(*) as sizinti
from madde_ara('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m
where coalesce(m.tur,'') like 'cikmis%';
-- beklenen: 0

-- (c) ambardaki tur dagilimi (kac belge disaridi gorelim)
select tur, count(*) from dokumanlar group by tur order by 2 desc;
