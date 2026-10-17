-- ============================================================================
-- 2026-10-18 · ogrenci_sonuc'a 'set' türü (ders sayfası 20 soruluk SET RAPORU hesaba)
-- Cem 18.10 "1.2.3 üçünü de yap" — madde 2: set raporu yalnız cihazda (kc_set_rapor) duruyordu; hesaba yazılınca telefon ve
-- bilgisayar aynı raporu görür, Hesabım "set gelişimi"ni hesaptan okur.
-- Değişen yalnız tür denetimi: ('seviye','deneme') -> ('seviye','deneme','set'). Tablo, RLS politikaları, veri boyu tavanı
-- (4000 bayt) ve tekil anahtar (user_id, tur, anahtar) AYNEN. Denetimin adı 2026-09-13'te verilmedi (Postgres kendisi adlandırdı)
-- -> tur sütunundaki check denetimi adından bağımsız bulunup düşürülür.
-- Yazan: motor/kaydir-coz.ps1 şablonu (ders sayfası setOzet) · Okuyan: ogrenci.html Derslerim ders detayı.
-- 🚫 GÖRMEZ: 2026-10-04 yönetim özeti 'cozdugu' alanı sınavı tür ayırmadan sayar ('set' satırı da o sınavı "çözdü" sayar - doğru).
-- ============================================================================

do $$
declare c record;
begin
  for c in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace ns on ns.oid = rel.relnamespace
    where ns.nspname = 'public' and rel.relname = 'ogrenci_sonuc' and con.contype = 'c'
      and pg_get_constraintdef(con.oid) ilike '%tur%' and pg_get_constraintdef(con.oid) ilike '%seviye%'
  loop
    execute format('alter table public.ogrenci_sonuc drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.ogrenci_sonuc
  add constraint ogrenci_sonuc_tur_check check (tur in ('seviye','deneme','set'));
