-- CILA V3 KOLONLARI (26.08.2026) — 1 Eylul ana partisinin yazacagi alanlar.
-- Cem: Supabase Studio > SQL Editor'e yapistir, Run.
-- deneme.html render'i bu alanlari zaten taniyor (bos olan cizilmez).
alter table soru_havuzu add column if not exists sinav_taktigi text;
alter table soru_havuzu add column if not exists dayanak      text;
alter table soru_havuzu add column if not exists notlandirici text;
alter table soru_havuzu add column if not exists cozum_tablo  jsonb;
alter table soru_havuzu add column if not exists akis         jsonb;
-- cila damgasi: hangi parti, ne zaman (onarim izi; uretim alanina dokunmuyoruz)
alter table soru_havuzu add column if not exists cila         text;
