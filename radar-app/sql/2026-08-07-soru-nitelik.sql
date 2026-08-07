-- ============================================================================
-- SORU NITELIK KOLONLARI - 07.08.2026 (Cem: "iki bedava isi yapalim")
--
-- 1) benzer_grup : ayni kurali olcen sorulari isaretler. deneme.html'deki
--    benzerlik kapisi bu kolona bakiyor ama kolon YOKTU - kapi fiilen hic
--    calismiyordu (aday ayni kurali ust uste cozebiliyordu).
-- 2) zorluk      : 1 kolay / 2 orta / 3 zor. Adaptif motorun on sarti.
--
-- Iceriden HICBIR SEY silinmez, hicbir soru degismez - yalniz iki bos kolon
-- eklenir. Robot (motor/soru-nitelik.ps1 -yaz) hemen ardindan doldurur.
-- ============================================================================

alter table public.soru_havuzu
  add column if not exists benzer_grup text,
  add column if not exists zorluk      smallint;

-- Oturum kurucusunun hizli filtrelemesi icin (deneme.html secim yapiyor):
create index if not exists soru_havuzu_benzer_grup_idx on public.soru_havuzu (benzer_grup);
create index if not exists soru_havuzu_zorluk_idx      on public.soru_havuzu (zorluk);
