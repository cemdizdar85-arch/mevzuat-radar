-- ============================================================================
--  "IFLAS KALDIRILDI" AYRI DURUM (28.08.2026) - IIK m.182
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--  ONCE 2026-08-28-alacak-ret-iflas-onarim.sql basilmis olmali (basildi).
--
--  KUSUR: "Iflasin kaldirilmasinin ilanen tebligi" ilanlari 'ret_kaldirma'
--  kovasinda duruyor. Bu ilan IIK m.182'dir: borclu iflastan CIKIYOR - borclar
--  odendi, alacaklilar talebini geri aldi ya da konkordato tasdik edildi.
--  Alacakli icin bu IYI HABERDIR ama notr/kotu bir etiketin altinda duruyor.
--  Bugun iki ayri olcumde karsimiza cikti: once ret_iflas damgasini kirletti
--  (6 ilan, anlami TAM TERS), sonra metin taramasinda yine cikti.
--
--  COZUM: kendi durumu -> 'iflas_kaldirma', sayfada YESIL.
--  Siniflandirici da guncellendi (motor/alacak-metin-ayristir.js); yeni kural
--  ret_kaldirma'dan ONCE gelir, yoksa "kaldirilmas" kalibi onu yutar.
--
--  NOT: konkordatolu olanlar ('Konkordato muhletinin kaldirilmasi ve iflas
--  karari') bu kovaya GIRMEZ - onlar zaten ret_iflas'ta. Asagidaki kosul
--  "iflasin kaldirilma" kalibini arar; "iflas hukumlerine gore tasfiye" ya da
--  "muhletin kaldirilmasi" bu kalibi tutturmaz.
-- ============================================================================

-- 1) ONCE SAY + GOZUNLE GOR (degistirmeden). Bugunun dersi: damga degistiren
--    her goç, once orneklerini gostermeli.
select count(*) as etkilenecek
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and (baslik like '%flasın kaldırılma%' or baslik like '%FLASIN KALDIRILMA%'
    or baslik like '%flasin kaldirilma%');

select tarih, il, tur, left(baslik, 70) as baslik
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and (baslik like '%flasın kaldırılma%' or baslik like '%FLASIN KALDIRILMA%'
    or baslik like '%flasin kaldirilma%')
order by tarih desc limit 15;
-- ^ Hepsinde "iflasin kaldirilmasi" gecmeli ve HICBIRINDE konkordato olmamali.

-- 2) DAMGALA
update public.alacak_ilan
set karar_durumu = 'iflas_kaldirma'
where karar_durumu = 'ret_kaldirma'
  and (baslik like '%flasın kaldırılma%' or baslik like '%FLASIN KALDIRILMA%'
    or baslik like '%flasin kaldirilma%');

-- 3) TEYIT + SAGLAMA
select karar_durumu, count(*) as adet
from public.alacak_ilan
where karar_durumu in ('iflas_kaldirma','ret_iflas','ret_kaldirma','tasdik')
  and tarih >= current_date - 365
group by 1 order by 2 desc;

-- SAGLAMA A: iflas_kaldirma damgali hicbir ilanda KONKORDATO gecmemeli (0 donmeli)
select count(*) as olmamasi_gereken
from public.alacak_ilan
where karar_durumu = 'iflas_kaldirma' and baslik like '%onkordato%';

-- SAGLAMA B: aritmetik korunumu. Uc kovanin toplami 715 KALMALI
-- (iflas_kaldirma + ret_iflas + ret_kaldirma), tasdik yine 42.
select (select count(*) from public.alacak_ilan
        where karar_durumu in ('iflas_kaldirma','ret_iflas','ret_kaldirma')
          and tarih >= current_date - 365) as uc_kova_toplami,
       (select count(*) from public.alacak_ilan
        where karar_durumu = 'tasdik' and tarih >= current_date - 365) as tasdik;
