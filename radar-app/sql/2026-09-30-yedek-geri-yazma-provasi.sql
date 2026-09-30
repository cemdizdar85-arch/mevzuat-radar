-- 2026-09-30 — YEDEKTEN GERİ YAZMA PROVASI (Cem "3 yap", akşam "1.2.3": aylık robota çevrildi)
-- KALICI ama BOŞ duran tablo. Canlı soru_havuzu'na DOKUNULMAZ; aylık robot
-- (.github/workflows/yedek-prova.yml → motor/yedek-geri-yazma-provasi.ps1 -Bosalt)
-- yedeği buraya yazar, kıyaslar, tabloyu yeniden BOŞALTIR. Robot tablo açıp silemez
-- (PostgREST DDL yapmaz), bu yüzden tablo kalıcıdır.
-- LIKE ... INCLUDING ALL: sütunlar, varsayılanlar, birincil anahtar ve indeksler kopyalanır;
-- yabancı anahtar KOPYALANMAZ (14.09 DDL kesintisi dersi: FK'lı DDL PostgREST'i 503'e düşürdü).
-- RLS açık + politika yok + anon/authenticated hakkı geri alınmış: dışarıdan okunamaz.
-- ⚠ soru_havuzu'na yeni sütun eklenirse bu tablo ESKİR ve robot düşer → 2) sonra 1) yeniden basılır.

-- 1) AÇ
create table if not exists public.prova_geri_yukle (like public.soru_havuzu including all);
alter table public.prova_geri_yukle enable row level security;
revoke all on public.prova_geri_yukle from anon, authenticated;
notify pgrst, 'reload schema';

-- 2) KALDIR (şema tazelemek ya da robotu emekliye ayırmak için)
-- drop table if exists public.prova_geri_yukle;
-- notify pgrst, 'reload schema';
