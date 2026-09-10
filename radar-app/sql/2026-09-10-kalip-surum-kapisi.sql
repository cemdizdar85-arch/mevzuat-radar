-- ============================================================================
--  KALIP SÜRÜM KAPISI — v1 asla siteye sızamaz
--  10.09.2026 · Cem onayı: "sürüm damgası aktarım yapılmadan önce konulmalı"
--
--  IDEMPOTENT — iki kez basılsa da zarar vermez.
--  NEREDE KOŞULUR: Supabase → SQL Editor (bu dosyanın tamamı tek seferde).
--
--  ============================================================================
--  ÖLÇÜM (10.09.2026, bu göç yazılmadan önce)
--  ============================================================================
--  soru_havuzu toplam ................ 30.569
--  yayin = true ......................      0   ← sitede TEK soru yok
--  cozum_tablo dolu (v2 alanı) .......      0   ← havuzun tamamı v1
--  akis · cila · sinav_taktigi ·
--  notlandirici · dayanak · konu_karti_id   0   ← v2 alanlarının hiçbiri dolu değil
--  onay dolu .........................  7.699   ← insan emeği geçmiş, SİLİNMEZ
--  son eklenme ....................... 24.07.2026
--
--  Yani havuz %100 v1; son üç günün 6.223 sorusu fabrika dosyalarında duruyor
--  ve havuza HİÇ aktarılmamış. Karışma henüz OLMADI — bu göç, olmadan önce
--  ayrımı kuruyor. Sonra kurulsaydı 30.569 satırı geriye dönük tahminle
--  etiketlemek gerekirdi ve o iş hatalı olurdu.
-- ============================================================================


-- ---------------------------------------------------------------- 1) SÜTUN
-- PostgreSQL 11+ : DEFAULT'lu ADD COLUMN mevcut satırları da doldurur, tabloyu
-- yeniden yazmaz. 30.569 satır tek işlemde 'v1' olur.
alter table public.soru_havuzu
  add column if not exists kalip_surum text not null default 'v1';

-- Yeni bir sürüm adı uydurulmasın: yalnız bilinen iki değer.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'ck_soru_havuzu_kalip_surum'
  ) then
    alter table public.soru_havuzu
      add constraint ck_soru_havuzu_kalip_surum
      check (kalip_surum in ('v1','v2'));
  end if;
end $$;

comment on column public.soru_havuzu.kalip_surum is
  'Cevap kalıbı sürümü. v1 = eski kalıp (24.07.2026 öncesi üretim, arşiv). v2 = Kaydır-Çöz kalıbı (STANDART-CEVAP-KALIBI.md). Yayın kapısı bu sütuna bakar.';


-- ------------------------------------------------------------- 2) YAYIN KAPISI
-- ⛔ ASIL KURAL: v1 bir daha yayına çıkamaz.
--
-- Neden CHECK, neden uygulama katmanı DEĞİL: uygulama kuralı unutulabilir,
-- yeni bir yazıcı hiç bilmeyebilir. Bu depoda ölçüldü — telif süzgeci de
-- "çağırana bırakılmıştı" ve çağıran NULL geçiyordu, yani kural hiç
-- çalışmıyordu. Yayın kararı veritabanının kendisinde durur.
--
-- 'yayin is not true' yazılır ('not yayin' DEĞİL): yayin NULL olursa
-- 'not null' = NULL döner ve CHECK NULL'ı GEÇİRİR. Bugün NULL yok ama
-- sütun nullable olduğu sürece yarın olabilir.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'ck_soru_havuzu_yayin_yalniz_v2'
  ) then
    alter table public.soru_havuzu
      add constraint ck_soru_havuzu_yayin_yalniz_v2
      check (yayin is not true or kalip_surum = 'v2');
  end if;
end $$;


-- ------------------------------------------------------------------ 3) ARŞİV
-- v1 SİLİNMEZ. 7.699 satırda insan onayı var; silmek o emeği yakar.
-- Etiket zaten karantinadır: v1 sorgulanabilir, okunabilir, ileride kalıp
-- dönüştürücü yazılırsa kaynak olur — ama yayına ÇIKAMAZ.
create index if not exists ix_soru_havuzu_kalip_surum
  on public.soru_havuzu (kalip_surum, yayin);

create or replace view public.soru_havuzu_arsiv_v1 as
select id, sinav, ders, konu, zorluk, onay, eklenme, uretim
from public.soru_havuzu
where kalip_surum = 'v1';

comment on view public.soru_havuzu_arsiv_v1 is
  'v1 kalıbındaki arşiv. Yayına çıkamaz (ck_soru_havuzu_yayin_yalniz_v2). Silinmez: 7.699 satırda insan onayı var.';


-- ------------------------------------------------------------------ NABIZ
-- Basıldıktan sonra bu tablo ekranda görünür. Beklenen: v1 30.569 · v2 0.
select kalip_surum,
       count(*)                                  as soru,
       count(*) filter (where yayin is true)     as yayinda,
       count(*) filter (where onay is not null)  as onayli
from public.soru_havuzu
group by kalip_surum
order by kalip_surum;
