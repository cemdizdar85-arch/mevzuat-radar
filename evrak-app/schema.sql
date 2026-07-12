-- ============================================================================
--  EVRAK RADARI — Supabase şeması (bir kez çalıştır: SQL Editor'e yapıştır → Run)
--  Muhasebeci = giriş yapan kullanıcı (auth). Mükellef = girişsiz, TOKEN linkiyle.
--  Güvenlik: muhasebeci yalnız KENDİ verisini görür (RLS); mükellef yalnız kendi
--  token'ına ait isteği görür/cevaplar (security-definer RPC — tablolar anon'a kapalı).
-- ============================================================================

-- 1) TABLOLAR ----------------------------------------------------------------
create table if not exists public.mukellefler (
  id uuid primary key default gen_random_uuid(),
  muhasebeci uuid not null references auth.users(id) on delete cascade default auth.uid(),
  ad text not null,
  telefon text,
  created_at timestamptz default now()
);

create table if not exists public.istekler (
  id uuid primary key default gen_random_uuid(),
  muhasebeci uuid not null references auth.users(id) on delete cascade default auth.uid(),
  mukellef_id uuid not null references public.mukellefler(id) on delete cascade,
  baslik text not null,
  token uuid not null unique default gen_random_uuid(),   -- mükellefin erişim linki
  kanal text,
  created_at timestamptz default now()
);

create table if not exists public.sorular (
  id uuid primary key default gen_random_uuid(),
  istek_id uuid not null references public.istekler(id) on delete cascade,
  tip text not null default 'soru',        -- 'soru' | 'belge'
  metin text not null,
  cevap text,
  dosya_url text,
  durum text not null default 'bek',       -- 'bek' | 'ok'
  sira int default 0,
  cevap_tarihi timestamptz
);

create index if not exists idx_istek_mukellef on public.istekler(mukellef_id);
create index if not exists idx_soru_istek on public.sorular(istek_id);

-- 2) RLS: MUHASEBECİ yalnız KENDİ verisi ------------------------------------
alter table public.mukellefler enable row level security;
alter table public.istekler   enable row level security;
alter table public.sorular    enable row level security;

drop policy if exists muh_mukellef on public.mukellefler;
create policy muh_mukellef on public.mukellefler
  for all using (muhasebeci = auth.uid()) with check (muhasebeci = auth.uid());

drop policy if exists muh_istek on public.istekler;
create policy muh_istek on public.istekler
  for all using (muhasebeci = auth.uid()) with check (muhasebeci = auth.uid());

drop policy if exists muh_soru on public.sorular;
create policy muh_soru on public.sorular
  for all using (istek_id in (select id from public.istekler where muhasebeci = auth.uid()))
  with check (istek_id in (select id from public.istekler where muhasebeci = auth.uid()));

-- 3) MÜKELLEF ERİŞİMİ (girişsiz) — yalnız security-definer RPC ile -----------
--    Tablolar anon role'e AÇILMAZ; mükellef sadece bu iki fonksiyonu çağırır.

create or replace function public.istek_getir(p_token uuid)
returns json language plpgsql security definer set search_path = public as $$
declare v public.istekler; v_mukellef text; v_sorular json;
begin
  select * into v from public.istekler where token = p_token;
  if not found then return null; end if;
  select ad into v_mukellef from public.mukellefler where id = v.mukellef_id;
  select coalesce(json_agg(json_build_object(
           'id', s.id, 'tip', s.tip, 'metin', s.metin,
           'cevap', s.cevap, 'dosya_url', s.dosya_url, 'durum', s.durum
         ) order by s.sira, s.metin), '[]'::json)
    into v_sorular from public.sorular s where s.istek_id = v.id;
  return json_build_object('baslik', v.baslik, 'mukellef', v_mukellef, 'sorular', v_sorular);
end; $$;

create or replace function public.cevap_kaydet(p_token uuid, p_soru_id uuid, p_cevap text, p_dosya text)
returns boolean language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update public.sorular s
     set cevap = coalesce(nullif(p_cevap,''), s.cevap),
         dosya_url = coalesce(nullif(p_dosya,''), s.dosya_url),
         durum = 'ok', cevap_tarihi = now()
   where s.id = p_soru_id
     and s.istek_id = (select id from public.istekler where token = p_token);
  get diagnostics n = row_count;
  return n > 0;
end; $$;

grant execute on function public.istek_getir(uuid)              to anon, authenticated;
grant execute on function public.cevap_kaydet(uuid,uuid,text,text) to anon, authenticated;

-- 4) DOSYA DEPOSU (fiş fotoğrafları) ----------------------------------------
insert into storage.buckets (id, name, public)
  values ('fisler','fisler', true)
  on conflict (id) do nothing;

drop policy if exists fis_upload on storage.objects;
create policy fis_upload on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'fisler');

drop policy if exists fis_read on storage.objects;
create policy fis_read on storage.objects
  for select using (bucket_id = 'fisler');

-- BİTTİ. Not: fiş dosyaları public-okunur (tahmin edilemez rastgele isimle);
-- MVP için yeterli, ileride imzalı-URL'e sıkılaştırılabilir.
