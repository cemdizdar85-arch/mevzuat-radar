-- ============================================================================
-- madde_ara v8 (25.08.2026) — 57014 TIMEOUT'UN KOKU: KAYBOLMUS BIR ONARIM
--
-- BULGU. madde_ara araliksiz 500 donuyordu. Hata govdesi yakalandi:
--     Proxy-Status: PostgREST; error=57014
--     {"code":"57014","message":"canceling statement due to statement timeout"}
--     x-envoy-upstream-service-time: 3362
-- Yani sorgu ~3 sn'lik statement_timeout'a takiliyor.
--
-- MEKANIZMA (olculdu, x-envoy-upstream-service-time uzerinden, her biri 5 kez):
--     'mahremiyet'                        ort   19 ms
--     'mahremiyet kimleri'                ort   24 ms
--     'mahremiyet kimleri baglar'         ort   39 ms
--     'vergi mahremiyet kimleri baglar'   ort  522 ms   max 2248 ms  <-- patlama
--     'vergi' (tek basina)                ort   65 ms
-- Yani maliyeti sisiren sey jeton SAYISI degil, iclerindeki YAYGIN kelime:
-- 'vergi' df=8700 (ambar 33.813). Aday havuzu TUM jetonlarin OR'undan
-- kuruldugu icin 8700+ belge ts_rank'lenip siralaniyor.
--
-- ASIL KOK SEBEP: BU ONARIM 17.07.2026'DA ZATEN YAPILMISTI, SONRA KAYBOLDU.
-- radar-app/sql/2026-07-17-madde-ara-v5.sql basligi birebir soyle diyor:
--   "v4'un zaafi — 'vergi' gibi binlerce belgede gecen kelime sorguya girince
--    aday taramasi 3 sn'lik statement_timeout'a takiliyordu (57014). v5: ADAY
--    HAVUZU yalniz AYIRT EDICI kelimelerden kurulur (df<=1500...). Yaygin
--    kelimeler adayliktan cikar ama PUANLAMADA kalir."
-- O dosyada `secili`/`secili2`/`qdar` CTE'leri vardir. 30.07 tarihli — ve YINE
-- "v5" adiyla kaydedilmis — dosyada bu CTE'ler YOK; aday yeniden tum jetonlarin
-- OR'undan kuruluyor. v6 (19.08) ve v7 (23.08) bu regresyonu devraldi.
-- Yani timeout onarimi bir yeniden yazimda sessizce dusmus, 5 hafta sonra ayni
-- hata koduyla geri gelmis.
--
-- ⚠️ ADLANDIRMA TUZAGI: depoda IKI AYRI dosya "v5" adini tasiyor ve ALGORITMALARI
-- FARKLI. "v5 canli" demek belirsizdir. Bu yuzden surum numarasi artik yalniz
-- dosya adiyla degil, ICERIKTEKI ayirt edici CTE ile anilir.
--
-- CANLI SURUM TESHISI (bugun olculdu): 'cikmis%' belgeleri sonuclarda YOK
-- (30 sonucun 0'i) -> canli olan v6/v7 ailesi, yani df suzgecsiz genis havuz.
-- Ikinci kanit: 17.07-v5'in KENDI kabul sorgusu bugun DUSUYOR —
--     madde_ara('anayasaya gore vergi odevi nedir', 6) -> Anayasa m.73 YOK.
-- O sorgu 17.07'de bu fonksiyonun gecme sarti olarak yazilmisti.
--
-- v8 = v7 AYNEN + 17.07-v5'in dar aday havuzu geri + olu dal duzeltmesi.
--   (1) DAR ADAY HAVUZU: aday yalniz df<=1500 olan (en ayirt edici, en fazla 4)
--       jetondan kurulur; hicbiri esigi gecmezse en nadir 2 jeton kullanilir.
--       Yaygin kelime adayliktan cikar ama PUANLAMADA kalir (agirlik + ts_rank),
--       yani "vergi" kelimesi cevabi hala etkiler, sadece 8700 belgeyi taratmaz.
--   (2) OLU DAL: v7'de `when 'standart' then 0.85` vardi; ambarda tur='standart'
--       diye SIFIR kayit var, gercek deger 'standart-madde'. Dal hic eslesmiyordu.
--       (Olculdu: tur yalniz 3 deger aliyor - kanun-madde, standart-madde,
--        teori-notu. Teblig parcalari da 'kanun-madde' etiketli.)
--
-- ⚠️ BU BIR SIRALAMA DEGISIKLIGIDIR - kalite ikiye de gidebilir. O yuzden:
--    KOSTUKTAN HEMEN SONRA  pwsh motor/ambar-testi.ps1  CALISTIRILACAK.
--    Bugunku taban: 45 gecti / 3 dustu / 0 olculemedi / 48.
--    45'in ALTINA duserse GERI DON: radar-app/sql/2026-08-23-madde-ara-v7.sql
--    (Altin test bedava ve LLM'siz; 1-2 dakika surer.)
--
-- CALISTIRMA: Supabase SQL Editor'de tek blok, sonra asagidaki dogrulamalar.
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
-- belge frekansi: 'cikmis%' disi ambarda kac belge bu jetonu iceriyor
df as (
  select t.w,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select w,
         to_tsquery('simple', w || ':*') as tq,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
-- (1) DAR HAVUZ: yalniz ayirt edici jetonlar aday uretir
secili as (
  select w from df where adet_df <= 1500 order by adet_df asc limit 4
),
secili2 as (
  select w from secili
  union all
  select w from (select w from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from secili2
),
qtum as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
),
aday as (
  select d.ctid as rid, d.arama_fold as af, d.tur as tur,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by r desc
  limit 300
),
puan as (
  select a.rid, a.r,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s,
         (select count(*) from agir g where a.af @@ g.tq) as kapsanan,
         case a.tur
           when 'teori-notu'    then 0.55
           when 'standart-madde' then 0.85   -- (2) v7'de 'standart' yaziyordu: OLU DAL
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
-- (a) 17.07-v5'in KENDI kabul sorgusu: Anayasa m.73 ilk 6'da GORUNMELI
select kaynak_ad from madde_ara('anayasaya gore vergi odevi nedir', 6);

-- (b) timeout'u tetikleyen sorgu artik hizli donmeli (yaygin 'vergi' + 3 jeton)
select kaynak_ad from madde_ara('vergi mahremiyet kimleri baglar', 6);

-- (c) cikmis% sizintisi olmamali -> beklenen 0
select count(*) as sizinti
from madde_ara('yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider', 30) m
where coalesce(m.tur,'') like 'cikmis%';

-- (d) SONRA MUTLAKA:  pwsh motor/ambar-testi.ps1
--     Beklenen >= 45 gecti / 3 dustu / 0 olculemedi. Altina duserse v7'ye don.
