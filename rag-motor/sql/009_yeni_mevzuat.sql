-- ============================================================================
--  TETIKTE RAG MOTORU — 009_yeni_mevzuat.sql
--  BEKLENTI SORUSU ALTYAPISI: yeni mevzuat damgasi + hakem istisnasi
--
--  IDEMPOTENT. ONKOSUL: 008_telif_kapisi basili.
--
--  ============================================================================
--  NEDEN (Cem, 10.09.2026)
--  ============================================================================
--  "Sinavda henuz hic sorulmamis ama yeni yasalasan mevzuattan kesinlikle soru
--   gelecektir. Motor sadece gecmisi taklit eden degil, yeni mevzuati okuyup
--   SGS kalibresinde 'Beklenti Sorusu' uretebilen proaktif bir yapida olsun."
--
--  BUGUNKU MOTOR GECMISE BAGLI: uretim istemine ders basina gercek cikmis
--  ornek gomuluyor (Kalip Sozlesmesi madde 6, "cikmis-bicim capasi") ve hakem
--  "bu konu sinavda cikmis mi" diye bakiyor. Yeni cikmis bir teblig icin bu
--  iki mekanizma da CALISMAZ - capa bulunamaz, hakem "benzeri yok" der.
--  Sonuc: motor en guncel mevzuatta SESSIZ kalir. Tam da sinavin soracagi yerde.
--
--  ============================================================================
--  TASARIM: "YENI" BIR TARIH DEGIL, IKI OLCUMUN BILESIMI
--  ============================================================================
--  Yalnizca "yururluk tarihi yeni" demek yetmez: 2025'te cikmis bir teblig
--  2026 sinavinda sorulmus olabilir. Asil sorulmasi gereken sey:
--
--     "Bu kaynak YENI MI  *ve*  cikmis sinavda HIC GECMEMIS MI?"
--
--  Ikincisi ambardan OLCULEBILIR - cikmis sinav kulliyati (7.463 parca)
--  zaten burada. Yani "beklenti kaynagi" tahmin degil, SAYIM.
-- ============================================================================

-- ------------------------------------------------------------------- 1) ALAN
alter table rag.kaynak
  add column if not exists yururluk date,
  add column if not exists yeni_mevzuat boolean not null default false,
  add column if not exists mevzuat_notu text;

comment on column rag.kaynak.yururluk is
  'Kaynagin yururluk/yayim tarihi. NULL = bilinmiyor (eski yutmalarda bos kalir).';
comment on column rag.kaynak.yeni_mevzuat is
  'ELLE konan damga: bu kaynak "beklenti sorusu" hattina girer. Otomatik olcum icin rag.beklenti_kaynaklari gorunumune bak.';
comment on column rag.kaynak.mevzuat_notu is
  'Neden yeni sayildi / neyi degistirdi. Insan okumasi icin.';

create index if not exists ix_kaynak_yeni_mevzuat on rag.kaynak (yeni_mevzuat, yururluk);

-- ============================================================================
--  2) BEKLENTI KAYNAKLARI — olculmus gorunum
--
--  Bir kaynak burada gorunuyorsa: yururlugu yeni VE cikmis sinav kulliyatinda
--  adina/koduna atif YOK. Yani "sinav bunu henuz sormadi ama sorabilir".
--
--  ⚠️ ATIF OLCUMU KIMLIK UZERINDEN: kanun numarasi ya da standart kodu aranir,
--  AD ARANMAZ. Ad karsilastirmasi bu depoda uc kez denendi, ucu de yanlis
--  cevap verdi (bkz. dayanak-ad-koprusu). Kimlik cikarilamayan kaynak
--  "atif olculemedi" olur - "atif yok" DEMEZ.
-- ============================================================================
create or replace function rag.kaynak_kimligi(p_kod text, p_ad text)
returns text
language sql
immutable
parallel safe
as $$
  select coalesce(
    (select m[1] from regexp_matches(coalesce(p_ad,'') || ' ' || coalesce(p_kod,''), '\m(\d{3,5})\M') as m limit 1),
    (select upper(m[1]) || ' ' || m[2]
       from regexp_matches(upper(coalesce(p_kod,'') || ' ' || coalesce(p_ad,'')), '\m(BDS|TMS|TFRS|KYS|KKS)\s*(\d{1,3})\M') as m limit 1)
  )
$$;

comment on function rag.kaynak_kimligi is
  'Kaynagin makine kimligi: kanun numarasi ya da standart kodu. Bulunamazsa NULL - "atif yok" degil "olculemedi" demektir.';

create or replace view rag.beklenti_kaynaklari as
with k as (
  select k.id, k.kod, k.ad, k.tur, k.yururluk, k.yeni_mevzuat,
         rag.kaynak_kimligi(k.kod, k.ad) as kimlik,
         (select count(*) from rag.parca p where p.kaynak_id = k.id) as parca
  from rag.kaynak k
  where rag.dayanak_olabilir(k.tur)
),
atif as (
  select k.id,
         case when k.kimlik is null then null
              else (select count(*) from rag.parca sp
                      join rag.kaynak sk on sk.id = sp.kaynak_id
                     where sk.tur = 'cikmis-sinav'
                       and sp.metin like '%' || k.kimlik || '%')
         end as sinav_atifi
  from k
)
select k.id, k.kod, k.ad, k.tur, k.yururluk, k.yeni_mevzuat, k.kimlik, k.parca,
       a.sinav_atifi,
       case
         when k.kimlik is null              then 'KIMLIK OLCULEMEDI'
         when a.sinav_atifi = 0             then 'BEKLENTI KAYNAGI'
         else 'SINAVDA GECMIS'
       end as durum
from k join atif a on a.id = k.id
where k.parca > 0
order by (a.sinav_atifi = 0) desc nulls last, k.yururluk desc nulls last, k.parca desc;

comment on view rag.beklenti_kaynaklari is
  'Cikmis sinavda hic atif almamis dayanak kaynaklari. "BEKLENTI KAYNAGI" = sinav bunu henuz sormadi ama sorabilir -> beklenti sorusu hatti.';

-- ============================================================================
--  3) HAKEM ISTISNASI — "gecmiste benzeri yok" bir RET SEBEBI DEGIL
--
--  Hakem bugun konu uyumuna ve cikmis ornege bakiyor. Yeni mevzuat icin ikisi
--  de yok. Bu fonksiyon, hakemin hangi olcutu UYGULAMAMASI gerektigini
--  soyler - karari hakem verir, istisnayi ambar bildirir.
--
--  ⚠️ ISTISNA YALNIZ "GECMISTE YOK" OLCUTUNU KALDIRIR. Guncellik, mantik,
--  dayanak metne sadakat, telif ve kalip kurallari AYNEN gecerlidir. Yeni
--  mevzuat, kalitesiz soruya gecerlilik kazandirmaz.
-- ============================================================================
create or replace function rag.hakem_istisnasi(p_parca_id bigint)
returns table (
  beklenti_sorusu boolean,
  gerekce         text,
  uygulanmayacak  text
)
language sql
stable
as $$
  select
    coalesce(b.durum = 'BEKLENTI KAYNAGI' or b.yeni_mevzuat, false),
    case
      when b.yeni_mevzuat            then 'Kaynak ELLE yeni mevzuat damgali: ' || coalesce(b.ad,'')
      when b.durum = 'BEKLENTI KAYNAGI' then 'Cikmis sinav kulliyatinda bu kaynaga ATIF YOK (olculdu) - gecmis ornek beklenemez.'
      when b.durum = 'KIMLIK OLCULEMEDI' then 'Kaynak kimligi cikarilamadi - istisna UYGULANMAZ, olculemedi.'
      else 'Kaynak sinavda gecmis (' || coalesce(b.sinav_atifi::text,'?') || ' atif) - normal hakem olcutu gecerli.'
    end,
    case
      when coalesce(b.durum = 'BEKLENTI KAYNAGI' or b.yeni_mevzuat, false)
      then 'gecmiste_benzeri_var_mi'
      else null
    end
  from rag.parca p
  join rag.beklenti_kaynaklari b on b.id = p.kaynak_id
  where p.id = p_parca_id
$$;

comment on function rag.hakem_istisnasi is
  'Bu parcadan uretilen soru "beklenti sorusu" mu? Oyleyse hakem YALNIZ "gecmiste benzeri yok" olcutunu uygulamaz; guncellik, mantik, dayanak sadakati, telif ve kalip kurallari AYNEN gecerli.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '009_yeni_mevzuat / beklenti_kaynaklari + hakem_istisnasi / rag.ara v4 (telif kapisi) / konu_dayanak v3 / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('009_yeni_mevzuat', 'Beklenti sorusu altyapisi: kaynak.yururluk + yeni_mevzuat damgasi, rag.beklenti_kaynaklari gorunumu (cikmis sinavda atif almamis kaynaklar - OLCULUR, tahmin edilmez), rag.hakem_istisnasi (yalniz "gecmiste benzeri yok" olcutunu kaldirir).')
on conflict (surum) do nothing;
