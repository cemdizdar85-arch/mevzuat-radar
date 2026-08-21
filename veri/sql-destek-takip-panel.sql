-- ============================================================================
--  DESTEK TAKİBİ, PANEL YÜZÜ — 21.08.2026. Cem: "buraya taşısak, bununla aynı
--  işi yapacağız sonuçta".
--
--  KARAR: taşındı ama vitrin kapatılmadı. TEK tablo (destek_takip), İKİ yüz:
--    1) destekler.html  -> girişsiz kayıt (user_id NULL kalır) - huninin ağzı
--    2) radar-app.html  -> üye kendi profilini görür/değiştirir/kapatır
--  Robot DEĞİŞMEZ: yine tek tablodan okur.
--
--  sql-destek-takip.sql ÇALIŞTIRILDIKTAN SONRA bir kez çalıştırılacak.
-- ============================================================================

alter table public.destek_takip
  add column if not exists user_id uuid references auth.users(id) on delete cascade;

create index if not exists destek_takip_user_idx on public.destek_takip (user_id, olusturma desc);

-- ---------------------------------------------------------------- INSERT sıkı
-- Eski politika "with check (true)" idi: giriş yapmış biri BAŞKASININ user_id'si
-- ile satır yazabilirdi (kurbanın panelinde kendi kurmadığı bir takip görünürdü).
-- Artık: anonim kayıt serbest (user_id NULL), üye YALNIZ kendi adına yazar.
drop policy if exists destek_takip_ekle on public.destek_takip;
create policy destek_takip_ekle
  on public.destek_takip for insert
  to anon, authenticated
  with check (user_id is null or auth.uid() = user_id);

-- ------------------------------------------------------- üye kendi kaydı
-- Anonim satırlar (user_id NULL) HİÇ KİMSEYE görünmez - yalnız robot okur.
drop policy if exists destek_takip_kendi_oku on public.destek_takip;
create policy destek_takip_kendi_oku
  on public.destek_takip for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists destek_takip_kendi_guncelle on public.destek_takip;
create policy destek_takip_kendi_guncelle
  on public.destek_takip for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- --------------------------------------------- panelde "giden çağrılar" listesi
-- Üye yalnız KENDİ e-postasına gönderilen satırları görür. Yazma yok: gönderim
-- kaydını yalnız robot (service_role) yazar.
drop policy if exists destek_uyari_kendi_oku on public.destek_uyari;
create policy destek_uyari_kendi_oku
  on public.destek_uyari for select
  to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));
