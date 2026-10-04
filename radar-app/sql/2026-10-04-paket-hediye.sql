-- ============================================================================
-- PAKET HEDİYE KÜTÜĞÜ (04.10.2026, Cem: "elçilere siteye giriş bedava vereceğiz ... bizim kontrol edebileceğimiz,
-- kimlere ful paket bedava verdik")
--
-- NEDEN: ücretsiz paket bugüne dek SQL Editor'de elle paket_uyeler'e yazılıyordu (ör. 2026-09-27-inceleme-hesabi.sql);
-- "kime, neden, ne zamana kadar bedava verdik" sorusunun cevabı hiçbir yerde yoktu. paket_uyeler'de hediye ile
-- parayla alınmış paket ayırt edilemez.
--
-- NE YAPAR: yalnız bir KÜTÜK tablosu. Paketi açan yine paket_uyeler satırıdır; arac/paket-hediye.ps1 ikisini birlikte
-- yazar (servis anahtarıyla). Geri almada satır SİLİNMEZ: paket_uyeler.bitis dünü gösterir, kütüğe iptal tarihi düşer.
--
-- GÜVENLİK: RLS açık, politika YOK -> anon ve üye hiç göremez (e-posta tutar). auth.users'a yabancı anahtar YOK
-- (14.09 PostgREST kesintisi dersi, bkz. UYGULANDI.md 2026-09-13-ogrenci-sonuc).
-- GERİ ALMA: drop table public.paket_hediye;   (paketleri etkilemez)
-- ============================================================================
create table if not exists public.paket_hediye (
  id         bigint generated always as identity primary key,
  user_id    uuid not null,
  eposta     text not null check (length(eposta) between 3 and 160),
  paket      text not null check (paket in ('tam', 'sgs', 'yeterlilik-tum')),
  bitis      date not null,
  neden      text check (neden is null or length(neden) <= 200),
  elci_kodu  text check (elci_kodu is null or elci_kodu ~ '^[A-Z0-9]{3,12}$'),
  veren      text not null default 'Cem' check (length(veren) <= 60),
  tarih      timestamptz not null default now(),
  iptal      timestamptz
);
alter table public.paket_hediye enable row level security;
revoke all on public.paket_hediye from anon, authenticated;

-- Basıldı mı ölçüsü (Success sonrası çalıştır; 1 satır, "rls_acik = true" görmelisin):
-- select relname, relrowsecurity as rls_acik from pg_class where relname = 'paket_hediye';
