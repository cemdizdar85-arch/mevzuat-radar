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

-- anonim ve authenticated için yazma politikası YOK = yazamazlar.
-- (service role RLS'ye tabi değildir; robotlar onunla yazar)

-- ============================================================================
--  EK 23.07 (üye modu): AYNI Supabase projesinde Evrak Radarı kullanıcıları da
--  "authenticated" — "giriş yapan herkes okur" politikası kasayı onlara da
--  açardı. Okuma, paket_uyeler tablosunda AKTİF kaydı olan üyeye daraltıldı.
--  Ayrıca muhasebe kayıt sorularının görsel yevmiye verisi için kolon eklendi.
--  Paket açma (Cem/GM, ödeme alınınca):
--    insert into paket_uyeler (user_id, bitis)
--    values ('<auth.users id>', '2026-11-21');
-- ============================================================================

alter table soru_havuzu add column if not exists yevmiye jsonb;

create table if not exists paket_uyeler (
  user_id uuid primary key references auth.users(id) on delete cascade,
  paket   text not null default 'sinav-249',
  bitis   date not null,               -- paketin son günü (SGS 2026/3: 21.11.2026)
  eklenme timestamptz default now()
);
alter table paket_uyeler enable row level security;

drop policy if exists "kendini gorur" on paket_uyeler;
create policy "kendini gorur" on paket_uyeler
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "uye okur" on soru_havuzu;
drop policy if exists "paketli uye okur" on soru_havuzu;
create policy "paketli uye okur" on soru_havuzu
  for select to authenticated
  using (exists (
    select 1 from paket_uyeler p
    where p.user_id = auth.uid() and p.bitis >= current_date
  ));
