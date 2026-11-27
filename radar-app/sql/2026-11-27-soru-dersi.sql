-- 2026-11-27-soru-dersi.sql — SORU DERSİ (sesli Nöbetçi dersi) VERİSİ, PAKET KAPISININ ARKASINDA
-- Cem 27.11: "provayı başlat, hazır soruları siteye al". Üye soru sayfasında (kaydir/smmm/<ders>.html) dersi yazılmış
-- soruya "Nöbetçi sesli anlatsın" düğmesi gelir; ders verisi (zamanlar, kâğıt satırları, altyazı) paralı içeriktir,
-- depoda durmaz. Ses dosyaları mevcut cizim-ses-paket kovasında (2026-10-22-cizim-ses-paket-kasasi.sql), klasör = soru kimliği.
-- Yazma: yalnız servis anahtarı (kasa betiği konu-dersi/cozum/_is/ders-yayin.js). Okuma: yalnız aşağıdaki iki işlev.
-- Eskitir: yok (yeni tablo, yeni işlevler).

create table if not exists public.soru_dersi (
  id text primary key,
  veri jsonb not null,
  guncelleme timestamptz not null default now()
);
alter table public.soru_dersi enable row level security;   -- politika YOK: üye doğrudan okuyamaz
revoke all on public.soru_dersi from public, anon, authenticated;

create or replace function public.soru_dersi_getir(p_id text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select d.veri
  from public.soru_dersi d
  join public.paket_soru s on s.id = d.id
  where d.id = p_id and auth.uid() is not null and public.paket_erisim_var(s.sinav, s.ders);
$fn$;
revoke all on function public.soru_dersi_getir(text) from public, anon, authenticated;
grant execute on function public.soru_dersi_getir(text) to authenticated;

create or replace function public.soru_dersi_liste(p_sayfa text)
returns text[]
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce(array_agg(d.id), '{}'::text[])
  from public.soru_dersi d
  join public.paket_soru s on s.id = d.id
  where s.sayfa = p_sayfa and auth.uid() is not null and public.paket_erisim_var(s.sinav, s.ders);
$fn$;
revoke all on function public.soru_dersi_liste(text) from public, anon, authenticated;
grant execute on function public.soru_dersi_liste(text) to authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (tutmazsa göç geri alınır): anon ve authenticated tabloyu okuyamaz; anon işlevleri çağıramaz.
do $$
begin
  if has_table_privilege('anon', 'public.soru_dersi', 'select') or has_table_privilege('authenticated', 'public.soru_dersi', 'select') then
    raise exception 'soru_dersi tablosu üyeye/ziyaretçiye açık kaldı';
  end if;
  if has_function_privilege('anon', 'public.soru_dersi_getir(text)', 'execute') or has_function_privilege('anon', 'public.soru_dersi_liste(text)', 'execute') then
    raise exception 'soru_dersi işlevi ziyaretçiye açık kaldı';
  end if;
  if not has_function_privilege('authenticated', 'public.soru_dersi_getir(text)', 'execute') then
    raise exception 'soru_dersi_getir üyeye kapalı kaldı';
  end if;
end $$;
