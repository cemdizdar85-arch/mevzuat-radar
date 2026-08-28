-- ============================================================================
--  ALACAK VITRINI - "KONKORDATO REDDI -> IFLAS" AYRI DURUM (28.08.2026)
--  Supabase SQL Editor (bjrleanjpyujtajmazxn). Tek seferlik.
--
--  URUN KUSURU (28.08, Cem'in sorgusu ortaya cikardi):
--    "Konkordato talebinin REDDI VE IFLASA iliskin mahkeme karari"
--    "Konkordato muhletinin kaldirilmasi VE IFLAS kararina iliskin..."
--  Bu ilanlar 'ret_kaldirma' damgasi yiyordu (siniflandiricida ret kalibi
--  iflastan once geliyor). Oysa alacakli icin arsivdeki EN KRITIK haber budur:
--  konkordato TUTMADI, firma BATTI. Notr "Ret / kaldirma" etiketinin altinda
--  gorunmez oluyordu; ustelik tur='konkordato' oldugu icin IFLAS suzgecine
--  basan kullanici bunlari HIC gormuyordu.
--
--  COZUM: yeni karar_durumu = 'ret_iflas'. Sayfada kirmizi, listenin ustunde.
--  Siniflandirici da guncellendi (motor/alacak-metin-ayristir.js) - bundan
--  sonraki hasatlar dogrudan bu damgayi basar.
--
--  NOT (tur DEGISMIYOR): bu ilanlar kaynakta konkordato kategorisinde yayimlanir
--  ve konkordato dosyasinin sonucudur. tur'u 'iflas' yapmak, 12 aylik temiz
--  konkordato serisini bozar ve 4,7 aylik iflas serisine yanlis kayit katar.
--  Ayrimi DURUM tasir, TUR degil.
-- ============================================================================

-- 1) ONCE SAY (degistirmeden gor - kac ilan etkilenecek):
select count(*) as etkilenecek_ilan,
       min(tarih) as en_eski, max(tarih) as en_yeni
from public.alacak_ilan
where karar_durumu = 'ret_kaldirma'
  and (baslik like '%iflas%' or baslik like '%İflas%'
    or baslik like '%IFLAS%' or baslik like '%İFLAS%' or baslik like '%Iflas%');

-- 2) DAMGALA
update public.alacak_ilan
set karar_durumu = 'ret_iflas'
where karar_durumu = 'ret_kaldirma'
  and (baslik like '%iflas%' or baslik like '%İflas%'
    or baslik like '%IFLAS%' or baslik like '%İFLAS%' or baslik like '%Iflas%');

-- 3) TEYIT: yeni durum sayaci + eski durumun kalani + ornek basliklar
select karar_durumu, count(*) as adet
from public.alacak_ilan
where karar_durumu in ('ret_iflas','ret_kaldirma','tasdik')
  and tarih >= current_date - 365
group by 1 order by 2 desc;

select tarih, left(baslik, 70) as baslik
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
order by tarih desc limit 8;

-- 4) SAGLAMA: 'ret_iflas' damgali hicbir ilanin basliginda iflas gecmemesi
--    IMKANSIZ olmali (0 donmeli).
select count(*) as olmamasi_gereken
from public.alacak_ilan
where karar_durumu = 'ret_iflas'
  and baslik not like '%iflas%' and baslik not like '%İflas%'
  and baslik not like '%IFLAS%' and baslik not like '%İFLAS%'
  and baslik not like '%Iflas%';
