-- ============================================================================
--  KİLİTLİ SORU HAVUZU — paralı sorular herkese açık depoda TUTULMAZ.
--  Yazma: yalnız service role (robotlar; RLS'yi doğal olarak aşar).
--  Okuma: yalnız giriş yapmış üyeler (authenticated). Anonim okuyamaz.
--  Ödeme sistemi gelince okuma politikası "aktif paketi olan üye"ye daraltılır.
--  UYGULAMA: Supabase Dashboard -> SQL Editor -> bu dosyayı yapıştır -> Run.
-- ============================================================================

create table if not exists soru_havuzu (
  id        text primary key,
  sinav     text not null,            -- SGS / SMMM
  ders      text not null,
  konu      text not null,
  soru      text not null,
  siklar    jsonb not null,           -- {"A":"...","B":"...",...}
  dogru     text not null,            -- A-E
  aciklama  jsonb not null,           -- her şıkkın gerekçesi
  kaynak    text,                     -- dayanak kural/madde
  hap       text,                     -- 60 saniyelik konu anlatımı
  onay      text,                     -- kim/ne zaman onayladı damgası
  uretim    text,
  eklenme   timestamptz default now()
);

alter table soru_havuzu enable row level security;

-- yalnız giriş yapmış üye okur (ödeme gelince paket kontrolüne daraltılacak)
drop policy if exists "uye okur" on soru_havuzu;
create policy "uye okur" on soru_havuzu
  for select to authenticated using (true);

-- anonim ve authenticated için yazma politikası YOK = yazamazlar.
-- (service role RLS'ye tabi değildir; robotlar onunla yazar)
