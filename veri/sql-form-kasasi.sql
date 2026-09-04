-- ============================================================================
--  FORM KASASI — sitedeki formların düştüğü tablo (04.09.2026)
--
--  NEDEN: Cem "kurumsal firma olacağız, müşterinin gireceği bilgiler güvenli
--  yerde olsun" dedi. Formlar üçüncü aracıdan (web3forms) çıkarıldı; artık
--  radar-app/edge/form-al.ts bu tabloya yazıp Resend ile mail atıyor.
--
--  Tablo adı YENİ (form_kayit) — leadler'in şeması repoda hiç yoktu
--  (bkz. veri/sql-guvenlik-kapisi.sql), üstüne bina kurmadık.
--  Basılmadan önce ölçüldü mü? form-al?tani=1 kayit:false döner; basıldıktan
--  sonra ilk gönderide kayit:true görülmeli.
--
--  ERİŞİM MODELİ: anon ve authenticated için politika YOK ve GRANT YOK →
--  dışarıdan ne okunur ne yazılır. Yalnız service_role (uç fonksiyon) yazar,
--  Cem panelden okur. Yani müşteri verisi tarayıcıdan hiç görünmez.
-- ============================================================================

create table if not exists public.form_kayit (
  id            uuid primary key default gen_random_uuid(),
  olusturma     timestamptz not null default now(),
  konu          text not null,
  gonderen      text,
  eposta        text,
  sayfa         text,
  koken         text,
  alanlar       jsonb not null default '{}'::jsonb,
  durum         text not null default 'yeni',        -- yeni · okundu · cevaplandi · spam
  posta_gitti   boolean not null default false
);

comment on table public.form_kayit is 'Site formlari (teklif, takip, siparis bildirimi). Yazan: form-al edge fonksiyonu (service_role). Anon/authenticated erisimi yok.';

alter table public.form_kayit enable row level security;
revoke all on public.form_kayit from anon, authenticated;

create index if not exists form_kayit_olusturma_ix on public.form_kayit (olusturma desc);
create index if not exists form_kayit_durum_ix on public.form_kayit (durum) where durum = 'yeni';

-- ---------------------------------------------------------------------------
--  DOĞRULAMA (basıldıktan sonra üçü de hatasız dönmeli)
-- ---------------------------------------------------------------------------
-- 1) kolonlar 10/10
select count(*) as kolon_sayisi from information_schema.columns
 where table_schema = 'public' and table_name = 'form_kayit';
-- 2) RLS açık, politika 0 (anon kapalı demek)
select relrowsecurity from pg_class where oid = 'public.form_kayit'::regclass;
select count(*) as politika from pg_policy where polrelid = 'public.form_kayit'::regclass;
-- 3) anon'un hakkı yok
select grantee, privilege_type from information_schema.role_table_grants
 where table_schema = 'public' and table_name = 'form_kayit' and grantee in ('anon','authenticated');
