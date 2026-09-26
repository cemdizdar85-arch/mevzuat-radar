-- ============================================================================
-- ÖĞRENCİ İLERLEME KAYDI (26.09.2026, Cem "eksiklerin hepsini yapalım" — B kümesi: hesaba bağlı ilerleme)
-- Mağaza uygulaması (mobil/uygulama/ilerleme.js) çalışma ilerlemesini — son cevaplar, 🔖 işaretler, 📝 notlar,
-- kaldığın yer, günlük sayaç, çalışma ayarları — üyenin HESABINA yazar; telefon değişse de, site/uygulama
-- arasında geçse de ilerleme kaybolmaz. İstemci iki tarafı BİRLEŞTİRİR (soru başına en yeni kazanır),
-- ezmez. Site tarafı aynı biçimi ayrı görevle kullanacak.
--
-- ÖNCE ÖLÇÜLDÜ (26.09): tablo YOK — anon GET → 404 PGRST205 "Could not find the table
-- 'public.ogrenci_ilerleme'". "create table if not exists" bu yüzden gerçekten oluşturur.
--
-- auth.users'a FK YOK (bilerek): 14.09'da auth.users FK'lı tablo basarken PostgREST 2-3 dk 503 verdi
-- (hafıza: ddl-postgrest-kesinti). Bedeli: hesap silinince satır kendiliğinden gitmez — hesap silme
-- akışında elle silinir (Hesabımı sil talebi destek@tetikte.com'a gelir).
--
-- GÜVENLİK: anon HİÇ erişemez. authenticated yalnız user_id = auth.uid() satırını okur / ekler /
-- günceller. Silme yok (istemci boşaltmak isterse boş nesne yazar). Boyut tavanı 1,5 MB.
-- ============================================================================

create table if not exists public.ogrenci_ilerleme (
  user_id     uuid primary key default auth.uid(),
  veri        jsonb not null check (octet_length(veri::text) <= 1500000),
  degisim     bigint not null default 0,
  guncelleme  timestamptz not null default now()
);

alter table public.ogrenci_ilerleme enable row level security;

revoke all on public.ogrenci_ilerleme from anon;
revoke all on public.ogrenci_ilerleme from authenticated;
grant select, insert, update on public.ogrenci_ilerleme to authenticated;

drop policy if exists ogrenci_ilerleme_oku      on public.ogrenci_ilerleme;
drop policy if exists ogrenci_ilerleme_ekle     on public.ogrenci_ilerleme;
drop policy if exists ogrenci_ilerleme_guncelle on public.ogrenci_ilerleme;

create policy ogrenci_ilerleme_oku      on public.ogrenci_ilerleme for select to authenticated using (user_id = auth.uid());
create policy ogrenci_ilerleme_ekle     on public.ogrenci_ilerleme for insert to authenticated with check (user_id = auth.uid());
create policy ogrenci_ilerleme_guncelle on public.ogrenci_ilerleme for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ÖLÇÜM (basıldıktan sonra, SQL Editor):
--   select relrowsecurity from pg_class where relname='ogrenci_ilerleme';            -- true
--   select polname from pg_policy where polrelid='public.ogrenci_ilerleme'::regclass; -- 3 satır
-- Dış ölçüm: anon GET -> 401/42501 (tablo var, kapalı) · anon POST -> 401/42501
