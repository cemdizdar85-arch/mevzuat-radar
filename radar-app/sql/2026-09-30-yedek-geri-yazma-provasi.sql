-- 2026-09-30 — YEDEKTEN GERİ YAZMA PROVASI (Cem "3 yap")
-- Geçici tablo. Canlı soru_havuzu'na DOKUNULMAZ; yedek buraya yazılır, süre ölçülür,
-- sonra aşağıdaki DROP ile kaldırılır. Yazan: motor/yedek-geri-yazma-provasi.ps1
-- LIKE ... INCLUDING ALL: sütunlar, varsayılanlar, birincil anahtar ve indeksler kopyalanır;
-- yabancı anahtar KOPYALANMAZ (14.09 DDL kesintisi dersi: FK'lı DDL PostgREST'i 503'e düşürdü).
-- RLS açık + politika yok + anon/authenticated hakkı geri alınmış: dışarıdan okunamaz.

-- 1) AÇ
create table if not exists public.prova_geri_yukle (like public.soru_havuzu including all);
alter table public.prova_geri_yukle enable row level security;
revoke all on public.prova_geri_yukle from anon, authenticated;
notify pgrst, 'reload schema';

-- 2) KALDIR (prova bitince)
-- drop table if exists public.prova_geri_yukle;
-- notify pgrst, 'reload schema';
