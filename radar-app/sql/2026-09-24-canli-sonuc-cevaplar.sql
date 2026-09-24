-- CANLI DENEME: soru soru cevap dizisi (24.09.2026, Cem "1 yap")
-- Cem: Supabase SQL Editor'de TEK SEFERDE Run. 4 Ekim'den ONCE basilmali (sinav gunu SQL basilmaz).
--
-- NE: canli_sonuc'a 'cevaplar' sutunu. Paket sirasiyla her soruya bir harf (A-E), bos '-'.
--     Ornek (93 soru): 'AB-DCEA...'. Adsiz; kisiye/uye kimligine BAGLANMAZ.
-- NIYE: su an sunucuya yalniz dogru/yanlis/bos sayisi gidiyor; hangi soruda hangi sikkin
--       (hangi tuzagin) secildigi hic kaydedilmiyor.
-- YUK: istek sayisi DEGISMEZ (kisi basi 1 INSERT, ~100 bayt fazla).
-- SIRA SERBEST: canli-deneme.html bu sutun yokken 400 alirsa ozeti sutunsuz yeniden gonderir;
--       yani sayfa once de yayina cikabilir, SQL sonra da basilabilir.
-- auth.users'a FK YOK (14.09 dersi: FK'li tablo basarken PostgREST 2-3 dk 503 verdi).

alter table public.canli_sonuc
  add column if not exists cevaplar text;

alter table public.canli_sonuc
  drop constraint if exists canli_sonuc_cevaplar_bicim;
alter table public.canli_sonuc
  add constraint canli_sonuc_cevaplar_bicim
  check (cevaplar is null or (char_length(cevaplar) between 1 and 200 and cevaplar ~ '^[A-E-]+$'));

-- RLS/politika degismez: anon ve authenticated yalniz INSERT eder, kimse SELECT edemez.

-- NE GORECEKSIN: "Success. No rows returned".
-- DOGRULAMA (basildiktan sonra, GM disaridan olcer): anon INSERT {..., "cevaplar":"AB-"} -> 201;
--   "cevaplar":"XYZ" -> 400 (kisit); anon SELECT -> 0 satir. Test satiri servis anahtariyla silinir.
