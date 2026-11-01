-- ============================================================================
--  SÖZ HAKKI LİSTESİ DONDURULDU: YALNIZ ÖDEYENLER  ·  02.11.2026
--
--  Cem 02.11: "şu an sadece alanlar bu liste olsun; hediye verdiklerimiz hediye olarak görünsün, onlar ayrı".
--  2026-11-02-soz-hakki.sql o saatten önce verilmiş BÜTÜN siparişleri işaretlemişti (ödenmemiş havaleler
--  ödenirse söz görünecekti). Artık liste = bu göç anında ÖDENMİŞ olanlar (02.11 00:20 ölçümü: 95 sipariş).
--  Ödeme bekleyen / iptal / iade siparişlerin işareti kalkar; sonradan ödense de söz almaz.
--  Hediye/elle verilmiş paketler zaten listede değil (siparişleri yok); panelde "Hediye" olarak ayrı sayılır.
--
--  _soz_hakki_kapi tetiği işareti değiştirmeye izin vermez → bu göçte bilerek kapatılır, iş bitince açılır.
--  Push ile otomatik (sql-uygula.yml), tek işlem. Sonunda öz-sınav.
--  GERİ ALMA: tetiği kapat; 2026-11-01 21:04:59 UTC öncesi SGS/Yeterlilik siparişlerini yeniden true yap; tetiği aç.
-- ============================================================================

alter table public.siparisler disable trigger soz_hakki_kapi;
update public.siparisler set soz_hakki = false where soz_hakki and durum <> 'odendi';
alter table public.siparisler enable trigger soz_hakki_kapi;

do $$
declare a int; b int;
begin
  select count(*) into a from public.siparisler where soz_hakki and durum <> 'odendi';
  if a > 0 then raise exception 'OLCU: odenmemis % siparis hala isaretli', a; end if;
  select count(*) into b from public.siparisler where soz_hakki and durum = 'odendi';
  if b < 95 then raise exception 'OLCU: odenmis soz siparisi % < 95', b; end if;
  if not exists (select 1 from pg_trigger t join pg_class c on c.oid = t.tgrelid
                 where c.relname = 'siparisler' and t.tgname = 'soz_hakki_kapi' and t.tgenabled <> 'D')
    then raise exception 'OLCU: tetik acilmadi'; end if;
  raise notice 'SOZ HAKKI DONDUR: odenmis % siparis isaretli, odenmemis 0, tetik acik', b;
end $$;
