-- ============================================================================
-- SORU NOTU — "Kendi notum" hesapta (04.10.2026, Cem: "beş maddeyi yapalım"; rakip UWorld / Becker)
--
-- Soru kartındaki 📝 Notum cihazda (localStorage kc_not) tutulur; giriş yapmış üyede ayrıca buraya yazılır ki
-- telefon ile bilgisayar arasında taşınsın. Her üye YALNIZ kendi notlarını okur/yazar/siler (RLS). anon hakkı yok.
-- auth.users'a yabancı anahtar YOK (14.09 PostgREST kesintisi dersi). Not en çok 1000 karakter, soru kimliği 120.
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create table if not exists public.soru_not (
  user_id  uuid not null default auth.uid(),
  soru_id  text not null check (length(soru_id) between 3 and 120),
  metin    text not null check (length(metin) between 1 and 1000),
  guncel   timestamptz not null default now(),
  primary key (user_id, soru_id)
);
alter table public.soru_not enable row level security;
revoke all on public.soru_not from anon;
grant select, insert, update, delete on public.soru_not to authenticated;

drop policy if exists soru_not_oku on public.soru_not;
drop policy if exists soru_not_ekle on public.soru_not;
drop policy if exists soru_not_guncelle on public.soru_not;
drop policy if exists soru_not_sil on public.soru_not;
create policy soru_not_oku      on public.soru_not for select to authenticated using (user_id = auth.uid());
create policy soru_not_ekle     on public.soru_not for insert to authenticated with check (user_id = auth.uid());
create policy soru_not_guncelle on public.soru_not for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy soru_not_sil      on public.soru_not for delete to authenticated using (user_id = auth.uid());
