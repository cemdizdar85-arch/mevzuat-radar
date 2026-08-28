-- ============================================================================
--  ret_iflas DAMGASI ONARIMI (28.08.2026) - ONCEKI GOÇÜN DUZELTMESI
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--  ONCE 2026-08-28-alacak-ret-iflas-durumu.sql basilmis olmali (basildi, 73 satir).
--
--  KUSUR (canli olcumle YAKALANDI, ayni gun): onceki gocun kurali
--  "ret kalibi + iflas kelimesi" idi ve KIRLI cikti. 60 ilanlik canli ornekte:
--     53  "Konkordato talebinin reddi ve iflasa iliskin karar"   -> DOGRU
--      6  "Iflasin kaldirilmasi kararinin ilanen tebligi"        -> ANLAMI TERS
--      1  "Terekenin iflas hukumlerine gore tasfiyesi kararinin
--          kaldirilmasi"                                          -> ALAKASIZ
--
--  6 tanesi IIK m.182: borclu iflastan CIKIYOR (borclar odendi / alacaklilar
--  talebini geri aldi / konkordato tasdik edildi). Bunlari "firma BATTI" diye
--  kirmizi damgalamak, alacakliya TERS bilgi vermektir - kaciracagi bir kusur
--  degil, YANLIS HUKUMDUR. 1 tanesi m.180 tereke tasfiyesi, konkordatoyla
--  ilgisi yok.
--
--  DERS: kelime eslesmesi anlam tasimaz. "kaldirilmasi + iflas" iki ZIT olayi
--  birden esliyor; ayiran sey KONKORDATO kelimesinin varligi.
--
--  COZUM: ret_iflas damgasi yalnizca basliginda KONKORDATO da gecen ilanlarda
--  kalir; digerleri ret_kaldirma'ya geri doner. Siniflandirici da daraltildi
--  (motor/alacak-metin-ayristir.js) - sonraki hasatlar temiz damgalar.
-- ============================================================================

-- 1) ONCE SAY (degistirmeden gor - kac ilan geri alinacak):
select count(*) as geri_alinacak
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and baslik not like '%onkordato%';   -- K/k farkini atlar, tek kalip yeter

-- ...ve NE OLDUKLARINI gor (gozunle bak, hepsi konkordato DISI olmali):
select tarih, il, left(baslik, 75) as baslik
from public.alacak_ilan
where karar_durumu = 'ret_iflas' and baslik not like '%onkordato%'
order by tarih desc;

-- 2) GERI AL
update public.alacak_ilan
set karar_durumu = 'ret_kaldirma'
where karar_durumu = 'ret_iflas'
  and baslik not like '%onkordato%';

-- 3) TEYIT: sayilar ve saglama
select karar_durumu, count(*) as adet
from public.alacak_ilan
where karar_durumu in ('ret_iflas','ret_kaldirma','tasdik')
  and tarih >= current_date - 365
group by 1 order by 2 desc;

-- SAGLAMA A: ret_iflas damgali her ilanda konkordato + ret + iflas GECMELI (0 donmeli)
select count(*) as olmamasi_gereken
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and (baslik not like '%onkordato%'
    or (baslik not like '%iflas%' and baslik not like '%İflas%'
        and baslik not like '%IFLAS%' and baslik not like '%İFLAS%'
        and baslik not like '%Iflas%'));

-- SAGLAMA B: aritmetik korunuyor mu? ret_iflas + ret_kaldirma = 715 olmali
-- (goc oncesi ret_kaldirma sayisi; tasdik 42 hic degismemeli).
select (select count(*) from public.alacak_ilan
        where karar_durumu in ('ret_iflas','ret_kaldirma') and tarih >= current_date - 365) as toplam_ret,
       (select count(*) from public.alacak_ilan
        where karar_durumu = 'tasdik' and tarih >= current_date - 365) as tasdik;

-- SAGLAMA C: geri alinanlarin dagilimi - "iflasin kaldirilmasi" ilanlari artik
-- ret_kaldirma'da olmali (bunlar m.182, borclu iflastan CIKIYOR).
select count(*) as iflasin_kaldirilmasi_ret_kaldirmada
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and baslik not like '%onkordato%'
  and (baslik like '%flas%kaldır%' or baslik like '%flas%kaldir%');
