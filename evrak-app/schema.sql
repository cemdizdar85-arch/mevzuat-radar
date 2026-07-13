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


-- ============================================================================
--  MARKA RADARI — izlenen markalar + kullanım delili kasası + uyarı kaydı
--  Aynı Supabase projesi. Sahip = giriş yapan kullanıcı. Muhasebeci, mükellefi
--  adına marka izleyebilir (mukellef_id opsiyonel). Delil kasası PRIVATE (hukuki).
--  Dayanak: SMK 6769 — m.23 (yenileme 10 yıl), m.9/m.26 (kullan-ya-kaybet),
--  m.19/2 (kullanmama def'i), m.6/m.18 (benzerlik/itiraz 2 ay).
-- ============================================================================

-- 1) İZLENEN MARKALAR
create table if not exists public.markalar (
  id uuid primary key default gen_random_uuid(),
  sahip uuid not null references auth.users(id) on delete cascade default auth.uid(),
  mukellef_id uuid references public.mukellefler(id) on delete set null,  -- SMMM mükellefi adına izliyorsa
  marka_adi text not null,
  tescil_no text,                        -- ör. 2016/12345 (benzersiz kimlik)
  siniflar int[] default '{}',           -- Nice sınıfları
  basvuru_tarihi date,                   -- koruma başlangıcı (+10 yıl = bitiş)
  marka_tipi text default 'kelime',      -- kelime | logo | karma
  kullaniliyor boolean default true,     -- m.9 / m.19 için
  kullanim_baslangic date,
  taninmis boolean default false,        -- m.6/4-5 geniş koruma
  iletisim_email text, iletisim_tel text,
  notlar text,
  created_at timestamptz default now()
);
create index if not exists idx_marka_sahip on public.markalar(sahip);
create index if not exists idx_marka_basvuru on public.markalar(basvuru_tarihi);

-- 2) KULLANIM DELİLİ KASASI (m.9 "kullan ya da kaybet" — tarihli belgeler)
create table if not exists public.kullanim_delilleri (
  id uuid primary key default gen_random_uuid(),
  marka_id uuid not null references public.markalar(id) on delete cascade,
  tip text not null default 'fatura',    -- fatura | reklam | ambalaj | katalog | fuar | web | diger
  aciklama text,
  dosya_url text,                        -- Storage bucket 'marka-delil' (PRIVATE)
  belge_tarihi date,                     -- delilin ait olduğu tarih (5 yıl ispatı için kritik)
  created_at timestamptz default now()
);
create index if not exists idx_delil_marka on public.kullanim_delilleri(marka_id);

-- 3) UYARI KAYDI (robot/cron yazar, uygulama gösterir)
create table if not exists public.marka_uyarilari (
  id uuid primary key default gen_random_uuid(),
  marka_id uuid not null references public.markalar(id) on delete cascade,
  tur text not null,                     -- yenileme | itiraz | kullanim-hatirlatma | iptal-firsati
  mesaj text not null,
  son_tarih date,                        -- deadline (yenileme penceresi / itiraz 2 ay)
  durum text default 'bekliyor',         -- bekliyor | gonderildi | kapandi
  created_at timestamptz default now()
);
create index if not exists idx_uyari_marka on public.marka_uyarilari(marka_id);

-- RLS: her şey sahibine ait
alter table public.markalar          enable row level security;
alter table public.kullanim_delilleri enable row level security;
alter table public.marka_uyarilari    enable row level security;

drop policy if exists m_marka on public.markalar;
create policy m_marka on public.markalar
  for all using (sahip = auth.uid()) with check (sahip = auth.uid());

drop policy if exists m_delil on public.kullanim_delilleri;
create policy m_delil on public.kullanim_delilleri
  for all using (marka_id in (select id from public.markalar where sahip = auth.uid()))
  with check (marka_id in (select id from public.markalar where sahip = auth.uid()));

drop policy if exists m_uyari on public.marka_uyarilari;
create policy m_uyari on public.marka_uyarilari
  for all using (marka_id in (select id from public.markalar where sahip = auth.uid()))
  with check (marka_id in (select id from public.markalar where sahip = auth.uid()));

-- 4) DELİL DOSYA DEPOSU — PRIVATE (kullanım delili hassastır, yalnız sahibi erişir)
insert into storage.buckets (id, name, public) values ('marka-delil','marka-delil', false)
  on conflict (id) do nothing;

drop policy if exists delil_yaz on storage.objects;
create policy delil_yaz on storage.objects
  for insert to authenticated with check (bucket_id = 'marka-delil' and owner = auth.uid());
drop policy if exists delil_oku on storage.objects;
create policy delil_oku on storage.objects
  for select to authenticated using (bucket_id = 'marka-delil' and owner = auth.uid());
drop policy if exists delil_sil on storage.objects;
create policy delil_sil on storage.objects
  for delete to authenticated using (bucket_id = 'marka-delil' and owner = auth.uid());

-- 5) YENİLEME TAKVİMİ görünümü (koruma bitişi + yenileme penceresi hazır gelir)
--    security_invoker: RLS uygulanır, başkasının markası görünmez.
create or replace view public.marka_takvim with (security_invoker = true) as
  select m.*,
         (m.basvuru_tarihi + interval '10 years')::date               as koruma_bitisi,
         (m.basvuru_tarihi + interval '10 years' - interval '6 months')::date as yenileme_acilis,
         (m.basvuru_tarihi + interval '10 years' + interval '6 months')::date as ek_sure_sonu
  from public.markalar m;

-- BİTTİ (Marka Radarı). Delil bucket'ı PRIVATE (evrak fişinden farklı — hukuki delil).
-- Robot (cron): markalar tablosunu tarar → yaklaşan yenileme/kullanım/itiraz için marka_uyarilari yazar → mail/SMS.
