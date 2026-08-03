-- ============================================================================
--  ONARIM TASLAK TABLOSU — 03.08.2026
--
--  NEDEN: Onarım motorunun ürettiği açıklamalar PARALI İÇERİKTİR. Public depoya
--  yazılamaz (29-30.07 kararı), GitHub artifact'ına da yazılamaz (depo public,
--  artifact'ı herkes indirir). Geçici makineye yazınca da kayboluyor — 03.08
--  pilotunda tam bu oldu: 0,78 USD ödendi, maliyet ölçüldü ama 200 çıktı gitti.
--
--  ÇÖZÜM: çıktılar Supabase'e yazılır. Burası zaten özel (RLS ölçüldü, anon
--  okuyamıyor). Cem panelden gözle okur, robot servis anahtarıyla kalite
--  kontrolü koşar, dışarı hiçbir şey sızmaz.
--
--  TASLAK KASA DEĞİLDİR: buraya yazmak siteyi değiştirmez. Öğrenciye giden
--  hiçbir şey burada olanlardan etkilenmez. Onaylanan taslak AYRI bir adımda
--  kasaya işlenir.
--
--  ÇALIŞTIRMA: Supabase paneli -> SQL Editor -> yapıştır -> RUN.
--  Tekrar çalıştırılabilir (IF NOT EXISTS), bozmaz.
-- ============================================================================

create table if not exists public.soru_onarim_taslak (
  id            uuid primary key default gen_random_uuid(),
  soru_id       uuid not null,
  parti         text not null,              -- 'pilot-200-03.08' gibi
  model         text,
  ders          text,
  konu          text,
  kaynak        text,
  mevzuatdisi   boolean default false,      -- dil/beceri sorusu mu (kanun atfı yasak)
  eksik         text[],                     -- motorun istediği alanlar
  cikti         jsonb,                      -- modelin ürettiği alanlar
  gecerli_json  boolean default false,
  giris_token   int,
  cikis_token   int,
  durum         text not null default 'bekliyor',  -- bekliyor | onay | ret | islendi
  not_          text,                       -- gözle okuyanın notu
  olusturma     timestamptz not null default now()
);

-- Aynı parti + aynı soru iki kez yazılmasın (koşu tekrarlanırsa şişmesin).
create unique index if not exists soru_onarim_taslak_parti_soru
  on public.soru_onarim_taslak (parti, soru_id);

-- Gözle okurken en çok bu üçüyle süzeceğiz.
create index if not exists soru_onarim_taslak_durum  on public.soru_onarim_taslak (durum);
create index if not exists soru_onarim_taslak_parti  on public.soru_onarim_taslak (parti);
create index if not exists soru_onarim_taslak_soruid on public.soru_onarim_taslak (soru_id);

-- ---------------------------------------------------------------------------
--  KİLİT: RLS açık ve HİÇBİR POLİTİKA YOK.
--  Sonuç: anon ve authenticated anahtarlarla bu tabloya ERİŞİLEMEZ - ne okuma
--  ne yazma. Yalnız service_role (robot) ve panel sahibi görür. Paralı içerik
--  tarayıcıya asla düşmez. Politika EKLEMEYİN; eklenirse kilit açılır.
-- ---------------------------------------------------------------------------
alter table public.soru_onarim_taslak enable row level security;

-- Teyit sorgusu: aşağıdakini çalıştırınca 0 satır dönmeli (henüz veri yok).
-- select count(*) from public.soru_onarim_taslak;
