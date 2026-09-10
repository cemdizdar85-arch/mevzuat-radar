-- ============================================================================
--  TETIKTE RAG MOTORU — 007_terim_kesfi.sql
--  SINAV DILI ↔ KANUN DILI AYRISMASINI AMBARDA OLCER
--
--  IDEMPOTENT. ONKOSUL: 006 basili · kanun VE cikmis-sinav kulliyatlari yutulmus.
--
--  ============================================================================
--  NEDEN SQL'E TASINDI — KENDI HATAMIN OLCUMU (10.09.2026)
--  ============================================================================
--  Cem: "SADECE GENEL IDARE / GENEL YONETIM GIDERI BUNU BEN GORDUGUM,
--        GORMEDIKLERIMIZI SEN OLC"
--
--  Once arac/terim-kesif.ps1 yazildi: iki kulliyati PowerShell'de tarayip
--  1-3 kelimelik obek sikliklarini karsilastiracakti. 40 DAKIKA KOSTU VE
--  HICBIR SEY URETMEDI - uretmesi de mumkun degildi.
--
--  Sebep aritmetik: 30 MB metinde 1-3 kelimelik obek saymak ~90 MILYON
--  hashtable islemi demek. PS 5.1 bunun icin yanlis alet. Yanlis aleti
--  secmenin bedeli 40 dakikaydi ve bunu bastan hesaplamak gerekirdi.
--
--  Dogru alet zaten ambardaydi: her iki kulliyat da rag.parca'da duruyor ve
--  tsvector sutunu (p.arama) ZATEN kelime kelime ayrilmis, indekslenmis
--  halde. ts_stat() tam olarak bu is icin var.
--
--  IKI ASAMALI TASARIM — neden tek asama degil:
--    ASAMA 1 (bu dosya): TEK KELIME ayrismasi, ts_stat ile. Hizli, tam
--             kulliyat. "yonetim" sinavda cok / kanunda az gibi SINYAL verir.
--    ASAMA 2 (rag.obek_say): yalniz ASAMA 1'de ayrisan kelimelerin gectigi
--             parcalarda 2-3 kelimelik obek sayilir. Yani pahali islem tum
--             kulliyata degil, SUPHELI ALANA uygulanir.
--
--  ⚠️ BU OLCUM CIFT KURMAZ, ADAY URETIR. "genel idare gideri" ile "genel
--  yonetim gideri"nin AYNI SEY oldugu karari BILGI ister, sayim degil
--  (bkz. kural B18). Karar veri/terim-ciftleri.json'a ELLE yazilir.
-- ============================================================================

-- ---------------------------------------------------------------- asama 1
create or replace function rag.terim_ayrismasi(
  p_en_az   int default 25,     -- sinav tarafinda en az kac gecis
  p_oran    numeric default 5,  -- ayrisma orani (normalize)
  p_adet    int default 200
)
returns table (
  kelime       text,
  sinav_gecis  bigint,
  kanun_gecis  bigint,
  sinav_norm   numeric,
  kanun_norm   numeric,
  oran         numeric,
  yon          text
)
language plpgsql
stable
as $$
declare
  sinav_krk numeric;
  kanun_krk numeric;
begin
  select coalesce(sum(p.karakter_sayisi),0)::numeric / 1e6
    into sinav_krk
  from rag.parca p join rag.kaynak k on k.id = p.kaynak_id
  where k.tur = 'cikmis-sinav';

  select coalesce(sum(p.karakter_sayisi),0)::numeric / 1e6
    into kanun_krk
  from rag.parca p join rag.kaynak k on k.id = p.kaynak_id
  where k.tur <> 'cikmis-sinav';

  if sinav_krk = 0 or kanun_krk = 0 then
    raise exception 'IKI KULLIYAT DA GEREKLI: sinav % Mkrk, kanun % Mkrk. Once cikmis sinav yutulmali.',
      round(sinav_krk,2), round(kanun_krk,2);
  end if;

  return query
  with s as (
    select word, nentry::bigint as n
    from ts_stat($$
      select p.arama from rag.parca p
      join rag.kaynak k on k.id = p.kaynak_id
      where k.tur = 'cikmis-sinav'
    $$)
    where length(word) >= 4
  ),
  kn as (
    select word, nentry::bigint as n
    from ts_stat($$
      select p.arama from rag.parca p
      join rag.kaynak k on k.id = p.kaynak_id
      where k.tur <> 'cikmis-sinav'
    $$)
    where length(word) >= 4
  ),
  birlesik as (
    select coalesce(s.word, kn.word) as w,
           coalesce(s.n, 0)  as sn,
           coalesce(kn.n, 0) as kln
    from s full outer join kn on kn.word = s.word
  ),
  olculu as (
    select w, sn, kln,
           round(sn  / sinav_krk, 1) as s_norm,
           round(kln / kanun_krk, 1) as k_norm
    from birlesik
  )
  select o.w, o.sn, o.kln, o.s_norm, o.k_norm,
         case when o.k_norm > 0 then round(o.s_norm / o.k_norm, 1)
              when o.s_norm > 0 then 9999 else 0 end,
         case when o.s_norm >= o.k_norm then 'SINAV DILI' else 'KANUN DILI' end
  from olculu o
  where (o.sn >= p_en_az and (o.k_norm = 0 or o.s_norm / nullif(o.k_norm,0) >= p_oran))
     or (o.kln >= p_en_az * 4 and (o.s_norm = 0 or o.k_norm / nullif(o.s_norm,0) >= p_oran))
  order by greatest(o.s_norm, o.k_norm) desc
  limit greatest(coalesce(p_adet,200),1);
end $$;

comment on function rag.terim_ayrismasi is
  'ASAMA 1: tek kelime duzeyinde sinav dili / kanun dili ayrismasi. ts_stat ile tam kulliyat. CIFT KURMAZ, ADAY URETIR.';

-- ---------------------------------------------------------------- asama 2
-- Belirli bir kelimenin GECTIGI parcalarda, o kelimeyi iceren 2-3 kelimelik
-- obekleri sayar. Pahali islem TUM kulliyata degil SUPHELI ALANA uygulanir.
create or replace function rag.obek_say(
  p_kelime text,
  p_sinav  boolean default true,
  p_adet   int default 25
)
returns table (obek text, gecis bigint)
language sql
stable
as $$
  with secili as (
    select rag.katla(p.metin) as m
    from rag.parca p
    join rag.kaynak k on k.id = p.kaynak_id
    where (case when p_sinav then k.tur = 'cikmis-sinav' else k.tur <> 'cikmis-sinav' end)
      and p.arama @@ plainto_tsquery('simple', p_kelime)
    limit 4000
  ),
  kelimeler as (
    select s.m,
           w.jeton,
           w.sira
    from secili s,
         lateral unnest(regexp_split_to_array(s.m, '[^a-z0-9]+')) with ordinality as w(jeton, sira)
    where length(w.jeton) >= 2
  ),
  ikili as (
    select k1.jeton || ' ' || k2.jeton as o
    from kelimeler k1
    join kelimeler k2 on k2.m = k1.m and k2.sira = k1.sira + 1
  ),
  uclu as (
    select k1.jeton || ' ' || k2.jeton || ' ' || k3.jeton as o
    from kelimeler k1
    join kelimeler k2 on k2.m = k1.m and k2.sira = k1.sira + 1
    join kelimeler k3 on k3.m = k1.m and k3.sira = k1.sira + 2
  ),
  hepsi as (select o from ikili union all select o from uclu)
  select o, count(*)::bigint
  from hepsi
  where o like '%' || rag.katla(p_kelime) || '%'
  group by o
  having count(*) >= 3
  order by count(*) desc
  limit greatest(coalesce(p_adet,25),1)
$$;

comment on function rag.obek_say is
  'ASAMA 2: bir kelimenin gectigi parcalarda 2-3 kelimelik obek sayimi. p_sinav=true sinav kulliyati, false kanun kulliyati.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '007_terim_kesfi / rag.ara v3 / konu_dayanak v3 / terim_ayrismasi + obek_say / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('007_terim_kesfi', 'Sinav dili / kanun dili ayrismasi ambarda olculur. Asama 1 ts_stat ile tek kelime, asama 2 supheli alanda obek. PS surumu 40 dk kosup hicbir sey uretmemisti - yanlis alet.')
on conflict (surum) do nothing;
