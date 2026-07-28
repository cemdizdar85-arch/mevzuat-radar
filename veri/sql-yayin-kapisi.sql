-- ============================================================================
--  TETIKTE — YAYIN KAPISI (Katman 4) + MADDE BAGI (Katman 1 / Katman 3)
--
--  NEDEN GEREKLI:
--  Bugun kasada bir soruyu YAYINDAN CEKMENIN yolu YOK. Tek secenek silmek.
--  Yani "hata olsa bile yayinlanmadan yakalayalim" sarti su an teknik olarak
--  KARSILANAMIYOR: robot bir hata bulsa bile soruyu durduramaz.
--  Ayrica hangi sorunun hangi kanun maddesine dayandigi kasada YAZILI DEGIL;
--  yalniz serbest metin 'kaynak' alani var. Bu yuzden "su madde degisti, ona
--  dayanan sorulari cek" komutu calistirilamiyor.
--
--  BU SQL VERI SILMEZ, VERI DEGISTIRMEZ. Yalnizca kolon ve indeks ekler.
--  'yayin' varsayilani TRUE'dur - yani calistirdiginda hicbir soru yayindan
--  DUSMEZ, site aynen calismaya devam eder. Kapiyi biz bilerek kullanacagiz.
--
--  NASIL: Supabase > SQL Editor > yeni sorgu > yapistir > Run.
-- ============================================================================

alter table public.soru_havuzu
  add column if not exists yayin       boolean not null default true,
  add column if not exists yayin_notu  text,
  add column if not exists kanun_no    text,
  add column if not exists madde_no    text,
  add column if not exists madde_damga text,
  add column if not exists son_kontrol timestamptz;

comment on column public.soru_havuzu.yayin       is 'FALSE = soru yayindan cekildi (silinmedi). Sebep yayin_notu alaninda.';
comment on column public.soru_havuzu.yayin_notu  is 'Neden cekildi: hangi madde degisti, hangi denetim bayrak kaldirdi.';
comment on column public.soru_havuzu.kanun_no    is 'Sorunun dayandigi kanun numarasi (orn 213). Madde bagi - Katman 1.';
comment on column public.soru_havuzu.madde_no    is 'Madde numarasi. gec./ek seri icin onek tasir (orn gec12).';
comment on column public.soru_havuzu.madde_damga is 'Soru yazildigi andaki madde metninin parmak izi. Degisirse soru otomatik cekilir - Katman 3.';
comment on column public.soru_havuzu.son_kontrol is 'Bu sorunun kaynagi en son ne zaman dogrulandi.';

create index if not exists soru_havuzu_madde_ix on public.soru_havuzu (kanun_no, madde_no);
create index if not exists soru_havuzu_yayin_ix on public.soru_havuzu (yayin);


-- ============================================================================
--  IKINCI SORGU — SADECE OKUR, HICBIR SEY DEGISTIRMEZ.
--  Kasanin okuma politikasini gormek icin. Kapiyi politikanin ICINE koymak
--  en saglamidir (o zaman bir sorgu filtreyi unutsa bile cekilmis soru
--  sizamaz), ama mevcut politikayi GORMEDEN degistirmek siteyi kirabilir.
--  Ciktisini bana yapistir, dogru ALTER POLICY'yi ona gore yazayim.
-- ============================================================================

-- select policyname, cmd, qual::text, with_check::text
-- from pg_policies
-- where schemaname = 'public' and tablename = 'soru_havuzu';
