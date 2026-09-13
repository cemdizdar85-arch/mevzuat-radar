-- ============================================================================
-- ÖĞRENCİ SONUÇ KASASI (13.09.2026, Cem: "Öğrenciler için üyelik kapısı yok. yapalım")
-- ogrenci.html (öğrenci paneli) seviye testi ve "sınav gibi" deneme sonuçlarını
-- ÜYENİN KENDİ HESABINA yazar; her üye YALNIZ KENDİ satırlarını görür.
--
-- ÖNCE ÖLÇÜLDÜ (13.09): tablo YOK (PostgREST PGRST205 "Could not find the table
-- 'public.ogrenci_sonuc'"). "create table if not exists" bu yüzden gerçekten oluşturur.
--
-- GÜVENLİK: anon HİÇ erişemez. authenticated yalnız user_id = auth.uid() satırlarını
-- okur / ekler / siler. UPDATE yok (sonuç sonradan değiştirilmez).
-- Aynı sonuç iki kez aktarılmasın: (user_id, tur, anahtar) tekil.
-- ============================================================================

create table if not exists public.ogrenci_sonuc (
  id          bigserial primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  tur         text not null check (tur in ('seviye','deneme')),
  sinav       text not null default 'sgs' check (sinav in ('sgs','smmm','kgk')),
  anahtar     text not null check (char_length(anahtar) between 1 and 80),
  veri        jsonb not null check (octet_length(veri::text) <= 4000),
  olusturma   timestamptz not null default now(),
  unique (user_id, tur, anahtar)
);

create index if not exists ogrenci_sonuc_kullanici on public.ogrenci_sonuc (user_id, tur, olusturma desc);

alter table public.ogrenci_sonuc enable row level security;

revoke all on public.ogrenci_sonuc from anon;
revoke all on public.ogrenci_sonuc from authenticated;
grant select, insert, delete on public.ogrenci_sonuc to authenticated;
grant usage, select on sequence public.ogrenci_sonuc_id_seq to authenticated;

drop policy if exists ogrenci_sonuc_oku  on public.ogrenci_sonuc;
drop policy if exists ogrenci_sonuc_ekle on public.ogrenci_sonuc;
drop policy if exists ogrenci_sonuc_sil  on public.ogrenci_sonuc;

create policy ogrenci_sonuc_oku  on public.ogrenci_sonuc for select to authenticated using (user_id = auth.uid());
create policy ogrenci_sonuc_ekle on public.ogrenci_sonuc for insert to authenticated with check (user_id = auth.uid());
create policy ogrenci_sonuc_sil  on public.ogrenci_sonuc for delete to authenticated using (user_id = auth.uid());

-- ÖLÇÜM (basıldıktan sonra, SQL Editor):
--   select relrowsecurity from pg_class where relname='ogrenci_sonuc';            -- true
--   select polname from pg_policy where polrelid='public.ogrenci_sonuc'::regclass; -- 3 satır
-- Dış ölçüm: anon SELECT -> 401/izin yok · anon INSERT -> 401/42501
