-- ============================================================================
--  ret_iflas DAMGASI ARTIK METINDEN (29.08.2026)
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--  ONCE basili olmali: 2026-08-28-alacak-ret-iflas-durumu.sql + -onarim.sql
--  ⚠️ Bu goç TABLOYU gunceller, alacak_vitrin fonksiyonuna DOKUNMAZ -
--     goç kutugundeki "alacak_vitrin'i bes dosya yeniden yaziyor" riski YOK.
--
--  NEDEN: 29.08 okuma pilotu (746 ilan, run 33214784787) BASLIGIN IKI YONDE DE
--  YANILTTIGINI olctu:
--
--  (1) BASLIK FAZLA SOYLUYOR — Bursa kalibi.
--      'ret_iflas' uyusmazliklarinin 21'inin TAMAMI Bursa/Kutahya/Malatya.
--      Baslikta "reddi ve iflasa iliskin" yaziyor ama METINDE iflas karari YOK,
--      yalniz "tedbirlerin kaldirilmasina". Ornek alintilar:
--        "Davacilara verilen gecici muhletin sonuclarinin kendiliginden sona
--         erdiginin ve TEDBIRLERIN KALDIRILMASINA karar verildigi"
--        "KONKORDATO TALEBININ REDDINE"   (iflas yok)
--      -> 28.08'de geri cekilen "Bursa'da konkordatolar iflasla bitiyor"
--         iddiasi boylece KESINLESTI: o basliklar KALIP, olay degil.
--
--  (2) BASLIK EKSIK SOYLUYOR — Istanbul/Anadolu.
--      'ret_kaldirma' icinde 18 aday: metinde acikca iflas karari var ama
--      basliga yazilmamis. Uc tanesi KESIN:
--        AKSARAY   "davaci sirketin ... itibariyle IFLASINA karar verildiginin ILANINA"
--        SANLIURFA "Ahmet Zengin'in ... itibariyle IFLASINA"
--        ANKARA    "REDDI ile IIK nin 292/1 maddesi geregince"  (m.292 = kesin
--                   muhlet icinde iflasin acilmasi)
--      Bu firmalar bugun sitede "Ret / kaldirma" kovasinda - alacakli GOREMIYOR.
--
--  COZUM: damga basliktan degil METINDEN kurulur. Metin, mahkemenin ne karar
--  verdigini soyleyen tek kaynaktir; baslik kurumun yazim tercihidir.
--
--  DIKKAT - IKI TUZAK ELENIR (ikisi de bu sayfada daha once isirdi):
--   a) "iflasina karar VERILEBILECEGI / verilmesini isteyebilecekleri" gibi
--      UYARI cumleleri (IIK m.288 standart metni) karar DEGILDIR.
--   b) "IFLASIN KALDIRILMASI" (m.182) ters anlamlidir, disarida kalir.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) ONCE SAY + GOZUNLE GOR. Damga degistiren her goç orneklerini gosterir.
-- ---------------------------------------------------------------------------

-- 1a) Basligi "iflas" diyor AMA metni demiyor  -> ret_iflas'tan CIKACAK
select count(*) as basligi_soyluyor_metni_demiyor
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and metin is not null
  and metin !~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292)';

select il, left(baslik,55) as baslik, left(metin,180) as metin_bas
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and metin is not null
  and metin !~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292)'
order by il limit 15;
-- ^ Hepsinin ili BURSA/KUTAHYA/MALATYA agirlikli olmali ve metinlerinde
--   iflas karari GECMEMELI. Gecen bir tane gorursen DUR, bana soyle.

-- 1b) Metni "iflas" diyor AMA damgasi ret_kaldirma -> ret_iflas'a GIRECEK
select count(*) as metni_soyluyor_damgasi_demiyor
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and metin is not null
  and metin ~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292/1)'
  and metin !~* 'iflas[ıi]n\s*kald[ıi]r[ıi]lmas'
  and metin !~* 'iflas[ıi]na\s+karar\s+veril(ebilec|mesini\s+iste)';

select il, left(baslik,50) as baslik,
       substring(metin from '.{0,60}[İIiı]flas[^.]{0,90}') as karar_parcasi
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and metin is not null
  and metin ~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292/1)'
  and metin !~* 'iflas[ıi]n\s*kald[ıi]r[ıi]lmas'
  and metin !~* 'iflas[ıi]na\s+karar\s+veril(ebilec|mesini\s+iste)'
order by tarih desc limit 15;
-- ^ Her satirda mahkemenin VERDIGI iflas karari gorunmeli ("...iflasina karar
--   verildiginin ilanina" gibi). Uyari cumlesi gorursen DUR.

-- ---------------------------------------------------------------------------
-- 2) DAMGALA  (iki yon birden)
-- ---------------------------------------------------------------------------

-- 2a) Basligi soyleyip metni demeyenler geri ret_kaldirma'ya
update public.alacak_ilan
set karar_durumu = 'ret_kaldirma'
where karar_durumu = 'ret_iflas'
  and metin is not null
  and metin !~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292)';

-- 2b) Metni soyleyenler ret_iflas'a
update public.alacak_ilan
set karar_durumu = 'ret_iflas'
where karar_durumu = 'ret_kaldirma'
  and metin is not null
  and metin ~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292/1)'
  and metin !~* 'iflas[ıi]n\s*kald[ıi]r[ıi]lmas'
  and metin !~* 'iflas[ıi]na\s+karar\s+veril(ebilec|mesini\s+iste)';

-- ---------------------------------------------------------------------------
-- 3) TEYIT + SAGLAMA
-- ---------------------------------------------------------------------------
select karar_durumu, count(*) as adet
from public.alacak_ilan
where karar_durumu in ('ret_iflas','ret_kaldirma','iflas_kaldirma','tasdik')
  and tarih >= current_date - 365
group by 1 order by 2 desc;

-- SAGLAMA A: ret_iflas + ret_kaldirma toplami 715 KALMALI, tasdik 42
-- (iflas_kaldirma 6 ayri durur). Sayi kaybolmadiginin kaniti.
select (select count(*) from public.alacak_ilan
        where karar_durumu in ('ret_iflas','ret_kaldirma') and tarih >= current_date - 365) as toplam_ret,
       (select count(*) from public.alacak_ilan
        where karar_durumu = 'tasdik' and tarih >= current_date - 365) as tasdik,
       (select count(*) from public.alacak_ilan
        where karar_durumu = 'iflas_kaldirma' and tarih >= current_date - 365) as iflas_kaldirma;

-- SAGLAMA B: artik her ret_iflas ilaninin METNINDE iflas karari gecmeli (0 donmeli)
select count(*) as olmamasi_gereken
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and metin is not null
  and metin !~* '(iflas[ıi]n[ıi]n?\s+a[çc][ıi]lmas|iflas[ıi]na\s+karar\s+veril(di|mis|mesine)|itibariyle\s+iflas[ıi]na|292)';

-- SAGLAMA C: cografi dagilim DENGELENDI mi? Eski damga Bursa'da %60 yiginiyordu
-- (olay degil, yazim kalibi). Simdi Istanbul'un da gorunmesi beklenir.
select il, count(*) as ret_iflas
from public.alacak_ilan
where karar_durumu = 'ret_iflas' and tarih >= current_date - 365
group by 1 order by 2 desc limit 10;

-- NOT: metni olmayan ilanlar (metin is null) HIC DOKUNULMADAN kalir - onlarin
-- damgasi basliktan gelmeye devam eder ve bu bilincli: olcemedigimize hukum
-- kurmuyoruz.
