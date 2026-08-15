-- ============================================================================
--  MARKA_UYARI tablosu (15.08.2026) - Marka Watch (#4 per-user otomatik izleme)
--  marka-watch-kullanici.ps1 buraya yazar; panel (radar-app.html) buradan okur.
--  Supabase SQL Editor'de bir kez calistir.
-- ============================================================================
create table if not exists public.marka_uyari (
  id              bigint generated always as identity primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  marka           text not null,          -- kullanicinin izledigi marka
  basvuru_no      text not null,          -- benzer bulunan TR basvuru no
  benzer_ad       text,                   -- benzer basvurunun marka adi
  risk            int,                    -- 0-100
  sinif_cakisiyor boolean default false,
  basvuru_tarih   text,
  durum           text,                   -- Filed / Registered ...
  goruldu         boolean default false,  -- kullanici gordu mu (panel)
  created_at      timestamptz default now(),
  unique (user_id, marka, basvuru_no)     -- ayni uyari iki kez yazilmaz
);

alter table public.marka_uyari enable row level security;

-- Kullanici YALNIZ kendi uyarilarini gorur
drop policy if exists marka_uyari_select_own on public.marka_uyari;
create policy marka_uyari_select_own on public.marka_uyari
  for select using (auth.uid() = user_id);

-- Kullanici kendi uyarisini "goruldu" isaretleyebilir
drop policy if exists marka_uyari_update_own on public.marka_uyari;
create policy marka_uyari_update_own on public.marka_uyari
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Yazma yalniz service_role (robot) ile; anon/authenticated INSERT edemez.
-- (service_role RLS'i bypass eder, ek policy gerekmez.)

create index if not exists marka_uyari_user_idx on public.marka_uyari(user_id, created_at desc);
