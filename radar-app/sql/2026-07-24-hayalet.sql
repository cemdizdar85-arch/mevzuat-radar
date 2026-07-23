-- 24.07.2026 — Hayalet Kayit (Cem'in 'hologram' fikri):
-- yanlis sikki secenin kendi cevabinin defterdeki hali soluk gosterilir.
-- Supabase SQL Editor'de calistir:
alter table soru_havuzu add column if not exists yanlis_kayitlar jsonb;
