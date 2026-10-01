-- ============================================================================
--  ELÇİ SÖZLEŞME KAYDI — onay kopyasının e-postayla gönderildiği iz  ·  01.10.2026
--
--  NEDEN (Cem "hepsini yap"): sözleşme 4.2 "onaylanan sürümün PDF kopyası onay anında Elçinin e-postasına
--  gönderilir". Edge fonksiyonu radar-app/edge/elci-sozlesme.ts bu kolonlara yazar:
--    sozlesme_eposta       : kopyanın gönderildiği an
--    sozlesme_eposta_surum : hangi sürüm gönderildi (aynı sürüm ikinci kez gitmez — spam kapısı)
--    sozlesme_ozet         : gönderilen PDF'in SHA-256 özeti (delil: elçiye giden metin hangisi)
--  Tablo zaten anonim/authenticated'a kapalı (2026-09-15-elci-programi.sql bölüm 2); yalnız servis anahtarı yazar.
--  ESKİTİR: — (yalnız kolon ekler). SUPABASE SQL EDITOR'DE BİR KEZ; tekrar basılması güvenli.
-- ============================================================================

alter table public.elciler add column if not exists sozlesme_eposta       timestamptz;
alter table public.elciler add column if not exists sozlesme_eposta_surum text;
alter table public.elciler add column if not exists sozlesme_ozet         text;

-- DOĞRULAMA:
--   select column_name from information_schema.columns
--    where table_name = 'elciler' and column_name like 'sozlesme_%' order by 1;
--   -- sozlesme_eposta · sozlesme_eposta_surum · sozlesme_onay · sozlesme_ozet · sozlesme_surum
