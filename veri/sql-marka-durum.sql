-- ============================================================================
--  MARKA_DURUM tablosu (15.08.2026) - Portfoy oto-durum robotu anlik tablosu.
--  marka-portfoy-durum.ps1 her markanin son durumunu buraya yazar; degisimi
--  bir sonraki kosuda bununla karsilastirip uyari uretir.
--  Supabase SQL Editor'de bir kez calistir.
-- ============================================================================
create table if not exists public.marka_durum (
  user_id     uuid not null references auth.users(id) on delete cascade,
  marka       text not null,
  no          text,
  durum       text,        -- Filed / Published / Registered / Ended ...
  st13        text,
  sinif       text,
  guncelleme  date default now(),
  primary key (user_id, marka)
);

alter table public.marka_durum enable row level security;

drop policy if exists marka_durum_select_own on public.marka_durum;
create policy marka_durum_select_own on public.marka_durum
  for select using (auth.uid() = user_id);
-- Yazma yalniz service_role (robot); RLS bypass eder.
