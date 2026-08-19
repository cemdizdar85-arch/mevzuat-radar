-- ============================================================================
-- madde_ara v6 (19.08.2026) — CIKMIS SINAV KITAPCIKLARI ARAMADAN DISLANDI
--
-- NEDEN: Karne calismasi cikmis sinav kitapciklarini ambara yuttu
-- (tur='cikmis-soru', kaynak_ad 'CIKMIS SINAV - ...'). Bunlar karne/analiz
-- icin dogru veri ama Net Cevap'in kaynak onerisinde YANLIS: musavirin
-- sorusuna kanun maddesi yerine sinav kitapcigi donuyor. Olculdu (19.08):
--   "isci ihbar onel sureleri" -> ilk 20 sonucun 19'u sinav kitapcigi,
--   tek gercek kaynak (Is K. m.17-25) 13. sirada boguluyordu; dislama
--   simulasyonunda 1. siraya cikti. Altin test bu yuzden 18/48 dusuyordu.
--
-- KARAR: dusuk agirlik DEGIL tam dislama - sinav kitapcigi musavir cevabina
-- HICBIR durumda kaynak gosterilmez (v5'teki teori-notu 0.55 karari icerik
-- yine kaynakti; kitapcik kaynak degildir). Kayitlar tabloda DURUR; karne
-- araclari dokumanlar'i dogrudan filtreyle okudugu icin etkilenmez.
--
-- v6 = v5 AYNEN + uc yerde tur <> 'cikmis-soru' suzgeci:
--   (a) aday kumesi, (b) toplam belge sayisi (IDF payi),
--   (c) kelime gecis sayisi (IDF paydasi) - IDF sinav sisiginden arinir.
--
-- CALISTIRMA: Supabase SQL Editor'de tek blok. Ardindan dogrulama
-- sorgulari; sonra herhangi bir push Gunluk Kanun Aynasi'ni tetikler,
-- altin test yesillenmeli. GERI DONUS: 2026-07-30-madde-ara-v5.sql.
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
         ln( ((select count(*) from dokumanlar where tur is distinct from 'cikmis-soru') + 1)::numeric
           / ((select count(*) from dokumanlar dd
                where dd.tur is distinct from 'cikmis-soru'
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
    and d.tur is distinct from 'cikmis-soru'
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

-- ---- DOGRULAMA (19.08'de dusen vakalardan; beklenen ilk 6'da gorunmeli,
--      hicbir sonucta 'CIKMIS SINAV' gecmemeli) ----
select kaynak_ad, tur from madde_ara('isci ihbar onel sureleri', 6);
-- beklenen: Is K. (4857) listede, CIKMIS SINAV yok

select kaynak_ad, tur from madde_ara('veraset beyannamesi verme zamani', 6);
-- beklenen: Veraset ve Intikal V.K. (7338) listede

select kaynak_ad, tur from madde_ara('emeklilik icin yas ve prim gun sarti', 6);
-- beklenen: 5510 s. SGK listede

-- eski bekciler bozulmasin (v5'in dogrulamasi):
select kaynak_ad from madde_ara('kira artisi en fazla ne kadar olabilir tufe', 6);
-- beklenen: TBK (6098 s.K.) m.344 listede
select kaynak_ad from madde_ara('kacakcilik sucu hapis cezasi defter', 6);
-- beklenen: VUK (213 s.K.) m.359 listede
