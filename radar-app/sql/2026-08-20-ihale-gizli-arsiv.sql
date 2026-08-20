-- ============================================================================
--  IHALE SONUC ARSIVI — GIZLI KASA  (20.08.2026)
--
--  Cem: "site veriler cok onemli bizden baska kimse gormesin"
--
--  SORUN (olculdu): veri/ihale-sonuc.json public depoda duruyordu. 19.08'de
--  20 is gunu backfill yapilinca 6,8 MB -> 28,2 MB'a cikti; icinde 24.043 sonuc
--  ilani, 6.844 firma, 3.681 idare ve kirim gecmisi var - yani "bu is gercekte
--  kaca yapiliyor" kartinin TAMAMI. Depo public oldugu icin rakip tek istekle
--  indirip ayni karti kurabilirdi. Ayrica dosya buyumesi GitHub'in 100 MiB
--  sinirina 3-4 ayda dayaniyordu; her gunluk commit dosyanin tamamini yeniden
--  yaziyor, depo gecmisi gunde ~28 MB sisiyordu.
--
--  COZUM: alacak arsivinde kurulan desenin AYNISI (2026-08-19-alacak-gizli-arsiv.sql).
--  Ham kayit tabloya tasinir; tabloya disaridan HIC KIMSE erisemez (RLS acik,
--  POLICY YOK). Siteye giden 251 KB'lik OZET dosyasi public kalir - o zaten
--  toplulastirilmis, kopyalanacak bir sey degil.
--
--  KISIMLILIK ARTIK BURADA HESAPLANIR - EN ONEMLI KISIM:
--  Ayristirici kisimliligi "o gunun bulteninde IKN kac kez geciyor" diye
--  olcuyordu. Kisimli ihalenin kisimlari FARKLI GUNLERIN bulteninde sonuclanir;
--  tek gune bakinca kayit "tek sozlesmeli" gorunur ve 1,6 milyonluk ihalenin
--  25 bin TL'lik bir KALEMI icin "%98 kirim" yazilir. 20 gun eklendiginde
--  havuzda IKN'i tekrarlayan 1.133 YANLIS olculmus kayit ortaya cikti.
--  Burada kisim sayimi HER ZAMAN tum havuz uzerinden yapilir (window function);
--  yani tuzak yapisal olarak geri gelemez. Kirim de saklanmaz, TURETILIR.
--
--  Calistirma: Supabase SQL Editor (proje bjrleanjpyujtajmazxn) -> BOLUM BOLUM.
--  (memory dersi: uzun blok kopyalanirken kesilebiliyor.)
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 1/5
--  KASA: ham sonuc ilani tablosu. RLS ACIK, POLICY YOK => anon ve authenticated
--  rollerin tabloya dogrudan erisimi kapali. Yalniz service_role (yukleyici) ve
--  security definer fonksiyonlar okuyabilir.
-- ---------------------------------------------------------------------------
create table if not exists public.ihale_sonuc (
  anahtar          text primary key,           -- ikn|sozlesmeTarih|bedel|yuklenici
  ikn              text not null,
  tur              text,                        -- Mal | Yapim | Hizmet
  is_adi           text,
  idare            text,
  ihale_tarih      text,
  ihale_turu       text,
  usul             text,
  yaklasik_maliyet numeric,
  ym_birim         text,
  sb_birim         text,
  dokuman_indiren  int,
  teklif_sayisi    int,
  gecerli_teklif   int,
  yerli_avantaj    text,
  sozlesme_tarih   text,
  sozlesme_bedeli  numeric,
  yuklenici        text,
  kisim_kaniti     boolean default false,       -- "Sozlesmeye Esas Kisimlarinin" satiri var mi
  guncellendi      timestamptz not null default now()
);

alter table public.ihale_sonuc enable row level security;
-- POLICY YOK. Bilerek. Tabloya disaridan erisim yok.

create index if not exists ihale_sonuc_ikn   on public.ihale_sonuc (ikn);
create index if not exists ihale_sonuc_tur   on public.ihale_sonuc (tur);
create index if not exists ihale_sonuc_idare on public.ihale_sonuc (idare);

-- kirim_yuzde KOLONU YOK: saklanan bir sayi degil, havuzdan TURETILEN bir sonuc.
-- Kolon olsaydi eski (yanlis) degerler tabloda kalir, yeni kisim geldiginde
-- kendiliginden duzelmezdi.


-- ---------------------------------------------------------------- BOLUM 2/5
--  TURETIM: kisimlilik + kirim orani, HER ZAMAN tum havuz uzerinden.
--
--  kirim yalnizca su kayitlarda hesaplanir:
--    - ihale kisimli DEGIL (ayni IKN havuzda tek kayit VE metin kaniti yok)
--    - iki tutar da yazili, para birimleri ayni, yaklasik maliyet > 0
--    - sonuc (-100, +100) araliginda (akil siniri: bedel negatif olamaz, iki
--      katindan fazla asim ayristirma hatasidir - 8,29 MILYAR bedel okunmus tek
--      kayit ortalamayi -%135'e cekmisti)
--  Bunlarin disinda kirim NULL'dur; "olculemedi" demek uydurmaktan iyidir.
-- ---------------------------------------------------------------------------
create or replace view public.ihale_sonuc_v as
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


-- ---------------------------------------------------------------- BOLUM 3/5
--  YAZMA UCU: yalniz service_role. Parti parti (400'luk) cagrilir.
--  coalesce YOK - burada bos alan eskisini silmez degil, kayit ANAHTARIYLA
--  tektir (ikn+sozlesme+bedel+yuklenici); ayni kayit tekrar gelirse ustune
--  yazilir. Bu, ayristiricinin havuz birlestirme kuralinin aynisidir.
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
    kisim_kaniti, guncellendi
  )
  select
    x.anahtar, x.ikn, x.tur, x.is_adi, x.idare, x.ihale_tarih, x.ihale_turu, x.usul,
    x.yaklasik_maliyet, x.ym_birim, x.sb_birim, x.dokuman_indiren, x.teklif_sayisi,
    x.gecerli_teklif, x.yerli_avantaj, x.sozlesme_tarih, x.sozlesme_bedeli, x.yuklenici,
    coalesce(x.kisim_kaniti,false), now()
  from jsonb_to_recordset(p_kayitlar) as x(
    anahtar text, ikn text, tur text, is_adi text, idare text, ihale_tarih text,
    ihale_turu text, usul text, yaklasik_maliyet numeric, ym_birim text, sb_birim text,
    dokuman_indiren int, teklif_sayisi int, gecerli_teklif int, yerli_avantaj text,
    sozlesme_tarih text, sozlesme_bedeli numeric, yuklenici text, kisim_kaniti boolean
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
    kisim_kaniti = excluded.kisim_kaniti, guncellendi = now();

  get diagnostics n = row_count;
  return n;
end;
$fn$;

revoke all on function public.ihale_yaz(jsonb) from public, anon, authenticated;


-- ---------------------------------------------------------------- BOLUM 4/5
--  OKUMA UCU (yalniz service_role): ozet uretimi icin ham doküm.
--  Siteye giden ozet dosyasini ureten betik bunu cagirir; kart bu ucu GORMEZ.
--  Sayfalama var - tek istekte tum havuzu cekmek zaman asimina girer.
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


-- ---------------------------------------------------------------- BOLUM 5/5
--  SAYIM: yukleme dogrulamasi icin (satir dondurmez, yalniz adet).
--  "yesil kosu = tam veri degildir" kurali - yazdiktan sonra SAYARIZ.
-- ---------------------------------------------------------------------------
create or replace function public.ihale_sayi()
returns table(kayit bigint, tekil_ikn bigint, olculen bigint, kisimli bigint)
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
           count(*) filter (where kisimli_mi)::bigint
    from public.ihale_sonuc_v;
end;
$fn$;

revoke all on function public.ihale_sayi() from public, anon, authenticated;

-- ============================================================================
--  BITTI. Dogrulama (SQL Editor'de calistir, service_role oldugun icin doner):
--    select * from public.ihale_sayi();
--  Yukleme sonrasi beklenen: kayit 24.043 · olculen ~5.993 · kisimli ~17.863
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 6/6
--  GORUNUM SIZINTISI (20.08.2026 - olculdu, tahmin degil)
--
--  Tablo kilitliydi (RLS acik, policy yok) ama GORUNUM aciktu: Postgres'te bir
--  view, SAHIBININ yetkisiyle calisir; alttaki tablonun RLS'i devreye girmez.
--  Anon anahtarla /rest/v1/ihale_sonuc_v?select=ikn,kirim_yuzde&limit=5
--  cagrildiginda 5 GERCEK KAYIT dondu - yani kasanin arka kapisi acik kalmis.
--
--  DERS (alacak kasasindan tanidik): "tabloyu kilitledim" yetmez, o tabloyu
--  gosteren HER YOL olculur. Bos tabloda test etmek de yanilticidir - bos ile
--  kilitli ayni gorunur; olcum VERI YUKLENDIKTEN SONRA tekrarlanmali.
--
--  Iki kapi birden kapatilir:
--    security_invoker = on  -> gorunum artik CAGIRANIN yetkisiyle calisir,
--                              yani alttaki tablonun RLS'i uygulanir
--    revoke                 -> PostgREST'in gorunumu hic servis etmemesi icin
-- ---------------------------------------------------------------------------
alter view public.ihale_sonuc_v set (security_invoker = on);
revoke all on public.ihale_sonuc_v from anon, authenticated;
revoke all on public.ihale_sonuc   from anon, authenticated;
