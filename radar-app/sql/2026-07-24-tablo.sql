-- 24.07.2026 — Exhibit tablosu (Cem/UWorld fikri):
-- analiz sorularinda mini gelir tablosu/bilanco gorseli "tablo" alaninda tasinir.
-- Supabase SQL Editor'de calistir:
alter table soru_havuzu add column if not exists tablo jsonb;
