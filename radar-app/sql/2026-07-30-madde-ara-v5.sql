-- ============================================================================
-- madde_ara v5 (30.07.2026) — TUR AGIRLIGI + KAPSAMA BONUSU
--
-- NEDEN: Ambar 18.866 kayda buyuyunce (teori notlari + hukuk dalgasi) altin
-- test 2 vakada dustu ve Gunluk Kanun Aynasi 28.07'den beri KIRMIZI:
--   1) "kira artisi ... tufe" -> top-6'yi TUFE geciren TEORI notlari doldurdu,
--      TBK (6098) m.344 dusdu. (teori notu kanun maddesiyle ayni kefedeydi)
--   2) "kacakcilik sucu hapis cezasi defter" -> 5607 + CMK maddeleri VUK
--      (213) m.359'u itti. (VUK m.359 sorgunun DAHA COK kelimesini karsiliyor
--      ama v4 buna bonus vermiyordu)
-- Hedef kayitlarin ikisi de ambarda VAR (test edildi) - sorun siralama.
--
-- v5 = v4'un iki asamali IDF cekirdegi AYNEN + iki ek:
--   A) TUR AGIRLIGI: kanun-madde/teblig tam puan; standart 0.85; teori-notu
--      0.55. Teori notu hala bulunur (baska esleseni olmayan soruda cikar)
--      ama kanun maddesini ARTIK GOLGELEYEMEZ. Net Cevap'in dogasi geregi
--      birincil kaynak onceliklidir.
--   B) KAPSAMA BONUSU: sorgudaki FARKLI kelimelerden kacini karsiladigina
--      gore carpan (1 + 0.35*(eslesen-1)). 5 kelimenin 5'ini karsilayan
--      VUK m.359, 4'unu karsilayan 5607'nin onune gecer.
--
-- CALISTIRMA: Supabase SQL Editor'de tek blok. Ardindan dogrulama
-- sorgularini kos; iki beklenen de ilk 6'da gorunmeli. Sonra herhangi bir
-- push Gunluk Kanun Aynasi'ni tetikler, altin test yesillenmeli.
-- GERI DONUS: 2026-07-16-genel-dedupe-ve-madde-ara-v4.sql yeniden kosulur.
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
         ln( ((select count(*) from dokumanlar) + 1)::numeric
           / ((select count(*) from dokumanlar dd
                where dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) + 1) ) + 0.3 as agirlik
  from tok t
),
q as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
),
aday as (
  select d.ctid as rid, d.arama_fold as af, d.tur as tur,
         ts_rank(d.arama_fold, q.orq) as r
  from dokumanlar d, q
  where q.orq is not null and d.arama_fold @@ q.orq
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

-- ---- DOGRULAMA (ikisi de ilk 6 icinde beklenen kaynagi gostermeli) ----
select kaynak_ad from madde_ara('kira artisi en fazla ne kadar olabilir tufe', 6);
-- beklenen: TBK (6098 s.K.) m.344 listede

select kaynak_ad from madde_ara('kacakcilik sucu hapis cezasi defter', 6);
-- beklenen: VUK (213 s.K.) m.359 listede

-- eski bekciler bozulmasin (v4'un dogrulamasi):
select kaynak_ad from madde_ara('veraset beyannamesi verme zamani', 3);
-- beklenen: Veraset ve Intikal ilk siralarda
