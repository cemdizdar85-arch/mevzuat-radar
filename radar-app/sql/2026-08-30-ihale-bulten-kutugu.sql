-- ============================================================================
--  IHALE BULTEN KUTUGU  (30.08.2026)  — ASAMA 0, tam yutmadan ONCE
--
--  Cem: "asama 0'i bitir, yutmayi bekletme."
--
--  SORUN (olculdu 30.08, tahmin degil):
--  Kasada 54.792 sonuc ilani var ama bir kaydin HANGI GUNUN bulteninden
--  geldigi HICBIR YERDE yazmiyor. ihale_sonuc tablosunda ihale_tarih ve
--  sozlesme_tarih var; ikisi de bultenin tarihi DEGIL. Yani "hangi gunler
--  kasada, hangileri eksik" sorusu bugun cevaplanamiyor.
--  Yerel kutuk (veri/ihale-backfill-gunlog.json) 4 GUN yaziyor; kasada
--  62+ gunluk veri var. Yani elimizdeki tek kutuk YALAN SOYLUYOR.
--
--  36 aylik yutmaya bu eksikle girilirse sonunda "tam mi?" sorusuna asla
--  cevap veremeyiz - 775.000 kaydin uzerine "bilmiyorum" damgasi vurulur.
--  Bu yuzden kutuk yutmadan ONCE kurulur.
--
--  BU GOC NE EKLER:
--    1. ihale_sonuc.bulten_tarih + bulten_sayi  -> kaydin KAYNAK bulteni
--    2. ihale_kutuk tablosu                     -> hangi (gun,tur) cekildi
--    3. ihale_eksik_gun()                       -> hangi is gunu EKSIK
--    4. ihale_kutuk_denetim()                   -> kutuk ile tablo tutuyor mu
--
--  BULTEN TARIHI NEREDEN GELIYOR: uydurulmuyor, KAYNAKTAN okunuyor. Bultenin
--  her sayfasinin ust bilgisinde "27 AĞUSTOS 2026 – Sayı 5686" yazili (tek
--  gunun Mal bulteninde 919 kez, hepsi ayni - olculdu). Ayristirici bu satiri
--  sayfa altbilgisi olarak SILMEDEN once okuyup damgayi vuruyor.
--
--  "CEKILDI AMA BOS" ile "HIC CEKILMEDI" AYRI SEYDIR: resmi tatilde bulten
--  cikmaz, o gun kayit 0'dir ama EKSIK DEGILDIR. ihale_kutuk her iki durumu
--  ayirir (satir var + kayit=0  vs  satir yok). Bu ayrim olmadan kutuk yine
--  yalan soyler.
--
--  Calistirma: Supabase SQL Editor (proje bjrleanjpyujtajmazxn) -> BOLUM BOLUM.
--  Eskittigi dosya: 2026-08-20-ihale-gizli-arsiv.sql (gorunum + ihale_yaz +
--  ihale_dokum yeniden yazilir; tablo/kasa kurallari AYNEN korunur).
-- ============================================================================


-- ---------------------------------------------------------------- BOLUM 1/6
--  KOLONLAR. Mevcut 54.792 satirda bu alanlar NULL kalir - dogrusu budur,
--  geriye donuk uydurulamaz. Backfill ayni gunleri yeniden yuruyunce upsert
--  o satirlari damgalar (BOLUM 3'te "on conflict ... set bulten_tarih").
-- ---------------------------------------------------------------------------
alter table public.ihale_sonuc add column if not exists bulten_tarih date;
alter table public.ihale_sonuc add column if not exists bulten_sayi  int;

create index if not exists ihale_sonuc_bulten on public.ihale_sonuc (bulten_tarih);


-- ---------------------------------------------------------------- BOLUM 2/6
--  GORUNUM YENIDEN. Postgres'te "select s.*" gorunum KURULURKEN acilir; yeni
--  kolon kendiliginden gorunume girmez. Bu yuzden gorunum drop+create edilir.
--  ihale_dokum gorunume BAGIMLI oldugu icin once o dusurulur, BOLUM 4'te geri
--  kurulur. Kisimlilik/kirim mantigi bir harf degismedi.
-- ---------------------------------------------------------------------------
drop function if exists public.ihale_dokum(int, int);
drop view     if exists public.ihale_sonuc_v;

create view public.ihale_sonuc_v as
with sayim as (
  select s.*, count(*) over (partition by s.ikn) as kisim_sayisi
  from public.ihale_sonuc s
)
select
  sayim.*,
  (sayim.kisim_sayisi > 1 or coalesce(sayim.kisim_kaniti,false)) as kisimli_mi,
  case
    when (sayim.kisim_sayisi > 1 or coalesce(sayim.kisim_kaniti,false)) then null
    when sayim.yaklasik_maliyet is null or sayim.sozlesme_bedeli is null then null
    when sayim.yaklasik_maliyet <= 0 then null
    when sayim.ym_birim is not null and sayim.sb_birim is not null
         and sayim.ym_birim <> sayim.sb_birim then null
    else (
      select case when k > -100 and k < 100 then k end
      from (select round((1 - sayim.sozlesme_bedeli / sayim.yaklasik_maliyet) * 100, 1) as k) t
    )
  end as kirim_yuzde
from sayim;

-- 20.08 dersi AYNEN gecerli: gorunum sahibinin yetkisiyle calisir, alttaki
-- RLS devreye girmez. Her yeniden kurusta bu iki satir TEKRAR yazilir.
alter view public.ihale_sonuc_v set (security_invoker = on);
revoke all on public.ihale_sonuc_v from anon, authenticated;


-- ---------------------------------------------------------------- BOLUM 3/6
--  YAZMA UCU: bulten damgasi eklendi. Eski cagrilar bu alanlari gondermezse
--  NULL yazilir (kirilmaz); yeni yukleyici gonderir.
-- ---------------------------------------------------------------------------
create or replace function public.ihale_yaz(p_kayitlar jsonb)
returns int
language plpgsql
security definer
set search_path = public
as $fn$
declare n int;
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role yazabilir';
  end if;

  insert into public.ihale_sonuc (
    anahtar, ikn, tur, is_adi, idare, ihale_tarih, ihale_turu, usul,
    yaklasik_maliyet, ym_birim, sb_birim, dokuman_indiren, teklif_sayisi,
    gecerli_teklif, yerli_avantaj, sozlesme_tarih, sozlesme_bedeli, yuklenici,
    kisim_kaniti, bulten_tarih, bulten_sayi, guncellendi
  )
  select
    x.anahtar, x.ikn, x.tur, x.is_adi, x.idare, x.ihale_tarih, x.ihale_turu, x.usul,
    x.yaklasik_maliyet, x.ym_birim, x.sb_birim, x.dokuman_indiren, x.teklif_sayisi,
    x.gecerli_teklif, x.yerli_avantaj, x.sozlesme_tarih, x.sozlesme_bedeli, x.yuklenici,
    coalesce(x.kisim_kaniti,false), x.bulten_tarih, x.bulten_sayi, now()
  from jsonb_to_recordset(p_kayitlar) as x(
    anahtar text, ikn text, tur text, is_adi text, idare text, ihale_tarih text,
    ihale_turu text, usul text, yaklasik_maliyet numeric, ym_birim text, sb_birim text,
    dokuman_indiren int, teklif_sayisi int, gecerli_teklif int, yerli_avantaj text,
    sozlesme_tarih text, sozlesme_bedeli numeric, yuklenici text, kisim_kaniti boolean,
    bulten_tarih date, bulten_sayi int
  )
  where x.anahtar is not null and x.ikn is not null
  on conflict (anahtar) do update set
    tur = excluded.tur, is_adi = excluded.is_adi, idare = excluded.idare,
    ihale_tarih = excluded.ihale_tarih, ihale_turu = excluded.ihale_turu, usul = excluded.usul,
    yaklasik_maliyet = excluded.yaklasik_maliyet, ym_birim = excluded.ym_birim,
    sb_birim = excluded.sb_birim, dokuman_indiren = excluded.dokuman_indiren,
    teklif_sayisi = excluded.teklif_sayisi, gecerli_teklif = excluded.gecerli_teklif,
    yerli_avantaj = excluded.yerli_avantaj, sozlesme_tarih = excluded.sozlesme_tarih,
    sozlesme_bedeli = excluded.sozlesme_bedeli, yuklenici = excluded.yuklenici,
    kisim_kaniti = excluded.kisim_kaniti,
    -- DAMGA GERI ALINMAZ: yeni cagri damgasiz gelirse eskisi korunur, ama
    -- damgali gelirse yazilir. Boylece 54.792 eski kayit backfill gectikce
    -- kendiliginden damgalanir, damgali olan da damgasizca EZILMEZ.
    bulten_tarih = coalesce(excluded.bulten_tarih, ihale_sonuc.bulten_tarih),
    bulten_sayi  = coalesce(excluded.bulten_sayi,  ihale_sonuc.bulten_sayi),
    guncellendi = now();

  get diagnostics n = row_count;
  return n;
end;
$fn$;

revoke all on function public.ihale_yaz(jsonb) from public, anon, authenticated;


-- ---------------------------------------------------------------- BOLUM 4/6
--  OKUMA UCU geri kuruluyor (BOLUM 2'de gorunum icin dusurulmustu).
-- ---------------------------------------------------------------------------
create or replace function public.ihale_dokum(p_offset int default 0, p_limit int default 5000)
returns setof public.ihale_sonuc_v
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role okuyabilir';
  end if;
  return query
    select * from public.ihale_sonuc_v
    order by ikn, sozlesme_tarih, anahtar
    offset greatest(p_offset,0)
    limit least(greatest(p_limit,1), 10000);
end;
$fn$;

revoke all on function public.ihale_dokum(int,int) from public, anon, authenticated;


-- ---------------------------------------------------------------- BOLUM 5/6
--  KUTUK TABLOSU. "Hangi bulten cekildi" sorusunun TEK cevabi burasi.
--
--  kayit=0 SATIRI DA YAZILIR: resmi tatilde bulten cikmaz. O gun icin satir
--  VAR ve kayit 0'dir -> "cekildi, bostu". Satir YOKSA -> "hic cekilmedi".
--  Bu ayrim olmadan kutuk "eksik gun" sorusunu cevaplayamaz.
-- ---------------------------------------------------------------------------
--  TAM INDI MI (Cem 30.08: "tam indirdigimizi, is kollarini tam indirdigimizi
--  BILELIM"): bultenin KENDI icinde capraz kontrolu var. Basindaki ICINDEKILER
--  bolumu o gunun butun IKN'lerini listeler; govde ayni IKN'leri tekrarlar.
--  27.08 Mal bulteninde olculdu: ICINDEKILER 225 tekil IKN, govde 225, fark 0.
--  Indirme kesilirse ya da PDF->metin sayfa dusurse GOVDE kucululur, ICINDEKILER
--  aynen kalir -> fark ANINDA gorunur. Bu yuzden kutuk iki sayiyi da tutar:
--    beklenen (ICINDEKILER)  vs  kayit (govdeden ayristirilan)
--  tam = (beklenen = bulunan). Tam degilse o gun "yapildi" SAYILMAZ.
create table if not exists public.ihale_kutuk (
  gun         date not null,
  tur         text not null,                 -- Mal | Yapim | Hizmet | Danismanlik
  bulten_sayi int,                           -- kaynaktan okunan bulten no (5686 gibi)
  beklenen    int,                           -- ICINDEKILER'deki tekil IKN sayisi
  bulunan     int,                           -- govdede bulunan tekil IKN sayisi
  kayit       int  not null default 0,       -- ayristirilan sonuc ilani (kisimlar dahil)
  tam         boolean not null default false,-- beklenen = bulunan mi
  eksik_ikn   text[],                        -- ICINDEKILER'de olup govdede OLMAYANLAR
  bos_sebep   text,                          -- 'bulten yok/bos' | 'indirilemedi' | 'ayristirilamadi'
  cekildi     timestamptz not null default now(),
  primary key (gun, tur)
);

alter table public.ihale_kutuk enable row level security;
-- POLICY YOK - kasanin kendisi gibi disariya kapali.
revoke all on public.ihale_kutuk from anon, authenticated;

create or replace function public.ihale_kutuk_yaz(
  p_gun date, p_tur text, p_bulten_sayi int, p_kayit int,
  p_beklenen int default null, p_bulunan int default null,
  p_eksik_ikn text[] default null, p_bos_sebep text default null)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role yazabilir';
  end if;
  insert into public.ihale_kutuk (gun, tur, bulten_sayi, beklenen, bulunan,
                                  kayit, tam, eksik_ikn, bos_sebep, cekildi)
  values (p_gun, p_tur, p_bulten_sayi, p_beklenen, p_bulunan,
          coalesce(p_kayit,0),
          -- TAM olcutu: beklenen okunabildiyse esitlik aranir. Okunamadiysa
          -- "tam" DENMEZ (olcemedigine kusur deme kuralinin tersi: olcemedigine
          -- TEMIZ de deme). Bos bulten (beklenen=0, bulunan=0) tamdir.
          (p_beklenen is not null and p_bulunan is not null and p_beklenen = p_bulunan),
          p_eksik_ikn, p_bos_sebep, now())
  on conflict (gun, tur) do update set
    bulten_sayi = coalesce(excluded.bulten_sayi, ihale_kutuk.bulten_sayi),
    beklenen    = excluded.beklenen,
    bulunan     = excluded.bulunan,
    kayit       = excluded.kayit,
    tam         = excluded.tam,
    eksik_ikn   = excluded.eksik_ikn,
    bos_sebep   = excluded.bos_sebep,
    cekildi     = now();
end;
$fn$;

revoke all on function public.ihale_kutuk_yaz(date,text,int,int,int,int,text[],text) from public, anon, authenticated;


-- ---------------------------------------------------------------- BOLUM 6/6
--  IKI SORU, IKI FONKSIYON.
--
--  ihale_eksik_gun  : "hangi is gunu hic cekilmedi" - yutmanin is listesi.
--  ihale_kutuk_denetim: "kutuk dogru mu soyluyor" - kutugun iddia ettigi kayit
--                       sayisi ile tabloda o bulten tarihinde DURAN satir
--                       sayisi karsilastirilir. Tutmuyorsa kutuk yalan
--                       soyluyordur; tam da bu goce sebep olan hastalik.
--                       (kalici-sigorta kurali: kapi neden dustugunu SOYLER)
-- ---------------------------------------------------------------------------
-- IS KOLU LISTESI DORT (Cem 30.08 sarti). KIK bulten sayfasindaki "Ihale Turu"
-- listesinden okundu, ezberden yazilmadi: Mal(1) · Yapim(2) · Hizmet(3) ·
-- Danismanlik(4). Ayristirici 30.08'e kadar UCUNU donuyordu; Danismanlik sonuc
-- ilanlari indiriliyor ama HIC islenmiyordu. Varsayilan artik dordu.
create or replace function public.ihale_eksik_gun(
  p_bas date, p_bit date,
  p_turler text[] default array['Mal','Yapim','Hizmet','Danismanlik'])
returns table(gun date, tur text, sebep text)
language sql
security definer
set search_path = public
as $fn$
  select g::date as gun, t as tur,
         case when k.gun is null then 'hic cekilmedi'
              else 'eksik indi' end as sebep
  from generate_series(p_bas, p_bit, interval '1 day') g
  cross join unnest(p_turler) t
  left join public.ihale_kutuk k on k.gun = g::date and k.tur = t
  where extract(isodow from g) < 6            -- hafta sonu bulten cikmaz
    -- IKI HAL DE EKSIKTIR: hic cekilmemis gun, VE cekilmis ama ICINDEKILER ile
    -- govdesi tutmayan gun. Ikincisini "yapildi" saymak, sessiz kayipla
    -- 36 aylik havuzu delik birakir.
    and (k.gun is null or k.tam = false)
  order by g desc, t;
$fn$;

revoke all on function public.ihale_eksik_gun(date,date,text[]) from public, anon, authenticated;

create or replace function public.ihale_kutuk_denetim()
returns table(gun date, tur text, kutuk_diyor int, tabloda_duran bigint, fark bigint)
language sql
security definer
set search_path = public
as $fn$
  select k.gun, k.tur, k.kayit,
         coalesce(s.n, 0) as tabloda_duran,
         coalesce(s.n, 0) - k.kayit as fark
  from public.ihale_kutuk k
  left join (
    select bulten_tarih, tur, count(*) as n
    from public.ihale_sonuc
    where bulten_tarih is not null
    group by bulten_tarih, tur
  ) s on s.bulten_tarih = k.gun and s.tur = k.tur
  where coalesce(s.n,0) <> k.kayit
  order by k.gun desc, k.tur;
$fn$;

revoke all on function public.ihale_kutuk_denetim() from public, anon, authenticated;

-- ihale_sayi'ya DAMGASIZ sayaci eklendi: yutma ilerledikce bu sayinin
-- 54.792'den 0'a inmesi beklenir. Inmiyorsa damga hatti calismiyordur.
create or replace function public.ihale_sayi()
returns table(kayit bigint, tekil_ikn bigint, olculen bigint, kisimli bigint,
              damgasiz bigint, ilk_bulten date, son_bulten date)
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role';
  end if;
  return query
    select count(*)::bigint,
           count(distinct ikn)::bigint,
           count(*) filter (where kirim_yuzde is not null)::bigint,
           count(*) filter (where kisimli_mi)::bigint,
           count(*) filter (where bulten_tarih is null)::bigint,
           min(bulten_tarih),
           max(bulten_tarih)
    from public.ihale_sonuc_v;
end;
$fn$;

revoke all on function public.ihale_sayi() from public, anon, authenticated;

-- ============================================================================
--  BITTI. Dogrulama (SQL Editor'de, service_role oldugun icin doner):
--    select * from public.ihale_sayi();
--      -> beklenen SIMDI: kayit 54.792 · damgasiz 54.792 · ilk/son_bulten null
--      -> beklenen YUTMA SONRASI: damgasiz 0 · ilk_bulten ~36 ay once
--    select count(*) from public.ihale_eksik_gun('2023-09-01','2026-08-29');
--      -> yutmanin is listesi uzunlugu (yaklasik 780 is gunu x 3 tur)
--    select * from public.ihale_kutuk_denetim();
--      -> BOS DONMELI. Satir donuyorsa kutuk ile tablo tutmuyor demektir.
-- ============================================================================
