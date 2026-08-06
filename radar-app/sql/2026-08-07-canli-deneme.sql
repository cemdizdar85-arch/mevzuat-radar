-- CANLI DENEME SONUC TABLOSU (07.08.2026 - kilitli-set mimarisi)
-- Cem: Supabase SQL Editor'de TEK SEFERDE Run.
-- Tasarim: anonim istemci YALNIZ INSERT edebilir (kendi sonucunu birakir);
-- kimse SELECT edemez (kisisel skorlar disari sizmaz) - okuma yalniz
-- service-key'li yuzdelik robotunda. Tablo kucuk: oturum basina ~5k satir.

create table if not exists public.canli_sonuc (
  id uuid primary key default gen_random_uuid(),
  olusturma timestamptz not null default now(),
  oturum text not null,              -- 'SGS-2308' gibi
  dogru int not null check (dogru >= 0 and dogru <= 200),
  yanlis int not null check (yanlis >= 0 and yanlis <= 200),
  bos int not null check (bos >= 0 and bos <= 200),
  sure_sn int,                       -- toplam sure (saniye)
  cihaz text                         -- 'mobil'/'masaustu' (istatistik)
);

alter table public.canli_sonuc enable row level security;

-- anonim yalniz ekleyebilir; okuyamaz/degistiremez/silemez
drop policy if exists canli_sonuc_insert on public.canli_sonuc;
create policy canli_sonuc_insert on public.canli_sonuc
  for insert to anon, authenticated with check (true);

-- ayni cihazdan sel gibi kayit atilmasin diye dakikada ~1 kayit beklenir;
-- kotuye kullanim gorulurse rate-limit RPC'si eklenir (acilis sonrasi).
