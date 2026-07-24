-- 24.07.2026 — Hayalet Kayit kolonu (Cem'in 'hologram' fikri)
-- Bu kolon HENUZ CALISTIRILMADI (24.07 gece tespit: kasa taseima bu yuzden tikaniyordu).
-- Taseiyeci artik kolon yoksa alani atlayip soruyu yine tasiyor (dayaniklilik);
-- bu SQL calistirilinca hayalet gorseli aktiflenir, backfill ile eski sorulara da eklenir.
-- Supabase SQL Editor'de calistir:
alter table soru_havuzu add column if not exists yanlis_kayitlar jsonb;
