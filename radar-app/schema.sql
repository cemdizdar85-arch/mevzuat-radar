-- ============================================================================
--  RADAR-APP ŞEMASI  —  Supabase SQL Editor'de çalıştır (bjrleanjpyujtajmazxn)
--  Firma profili = tüm radarların beslendiği tek kaynak. Bir kullanıcı N firma
--  ekleyebilir (işletme sahibi=1, mali müşavir=çok). RLS: herkes yalnız kendi firmaları.
-- ============================================================================

create table if not exists public.firmalar (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  email         text,            -- uyarı maili için (kayıt anında dolar)
  firma_adi     text not null,
  rol           text,            -- ithalatci / ihracatci / uretici / tuccar / musavir-musterisi
  il            text,
  sektor        text,
  gtip_kodlari  text[] default '{}',   -- {'8471.30','6907.21'}
  markalar      text[] default '{}',   -- {'ABC — 2016/12345'}
  borclu_vkn    text[] default '{}',   -- alacak radarı için izlenecek borçlu VKN'leri
  kanal         text default 'mail',   -- mail / sms / whatsapp
  telefon       text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.firmalar enable row level security;

-- Herkes yalnız kendi firmalarını görür/yazar/günceller/siler
create policy "firmalar_select_own" on public.firmalar for select using (auth.uid() = user_id);
create policy "firmalar_insert_own" on public.firmalar for insert with check (auth.uid() = user_id);
create policy "firmalar_update_own" on public.firmalar for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "firmalar_delete_own" on public.firmalar for delete using (auth.uid() = user_id);

create index if not exists firmalar_user_idx on public.firmalar(user_id);

-- ============================================================================
--  BİLGİ AMBARI (Kademe B) — konsolide mevzuat + seçmeli özelge, tam-metin arama.
--  Omurga: mevzuat.gov.tr konsolide metinleri (devlet güncel tutar, robot tazeler).
--  Özelge: yalnız seçmeli + tarih damgalı (bayat özelge riskine karşı).
-- ============================================================================
create table if not exists public.dokumanlar (
  id          uuid primary key default gen_random_uuid(),
  tur         text not null,           -- kanun / teblig / ozelge
  kaynak_ad   text not null,           -- ör. 'VUK m.371' / 'KDVGUT IV/A' / 'GİB özelge 2024/...'
  baslik      text,
  metin       text not null,           -- madde/bölüm metni (parça)
  kaynak_url  text,
  belge_tarihi date,                   -- özelgede verildiği tarih (bayatlık uyarısı için)
  yuklenme    timestamptz default now(),
  arama       tsvector generated always as (to_tsvector('simple', coalesce(baslik,'') || ' ' || metin)) stored
);
create index if not exists dokuman_arama_idx on public.dokumanlar using gin(arama);
alter table public.dokumanlar enable row level security;
-- herkes OKUYABİLİR (kamu mevzuatı); yazma yalnız service role (robot)
create policy "dokuman_public_read" on public.dokumanlar for select using (true);

-- (İLERİDE) uyarı kayıtları — robot cron buraya yazacak, panoda gösterilecek
create table if not exists public.firma_uyarilari (
  id         uuid primary key default gen_random_uuid(),
  firma_id   uuid not null references public.firmalar(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  tur        text,        -- ihale / alacak / marka / sure / rg
  baslik     text,
  detay      text,
  url        text,
  onem       text default 'orta',   -- yuksek / orta / bilgi
  okundu     boolean default false,
  created_at timestamptz default now()
);
alter table public.firma_uyarilari enable row level security;
create policy "uyari_select_own" on public.firma_uyarilari for select using (auth.uid() = user_id);
create policy "uyari_update_own" on public.firma_uyarilari for update using (auth.uid() = user_id);
create index if not exists uyari_user_idx on public.firma_uyarilari(user_id, okundu);
