-- ============================================================================
--  KASA FONKSİYONLARI YALNIZ ÜYEYE  ·  28.10.2026 (altyapı kolu, Cem "YAP ÖNERİNİ" madde 2)
--
--  2026-10-09/10/11 kasa göçleri "revoke all ... from public; grant ... to authenticated" yazdı; Supabase varsayılanı
--  anon'a da açık bıraktı. İçerik vermiyorlardı (içeride auth.uid() denetimi) ama tek kilit vardı. Bu göç ikinci kilidi
--  takar: anon'dan EXECUTE kalkar, authenticated AYNEN kalır (girişli üye yolu değişmez — aşağıda ölçülür).
--  28.10 anon ölçümü (değişiklik öncesi):
--    kasa_soru_getir / kasa_soru_idler / kasa_soru_parca / kasa_ders_fihrist → 401 "KASA_OTURUM"  (sonra: 401 "permission denied";
--      hiçbir sayfa mesaja bakmıyor — git grep KASA_OTURUM site/mobil kodunda 0)
--    kasa_cevap_yaz / kasa_tavan_bildir → 204 (uid yoksa sessiz çıkış); çağıranlar hatayı yok sayar (.then(noop, noop))
--  BİLEREK DOKUNULMAYAN: kasa_dizin — mağazadaki uygulama (mobil/uygulama/uygulama-karma.js) girişsiz çağırırsa bugün []
--    alıp "soru yok" der; kapatılırsa hata fırlatır ve mağaza sürümü hemen düzeltilemez. İçerik vermez (auth.uid() is not null).
--  🚫 ÖLÇÜLMEDİ: gerçek üye hesabıyla ders sayfası (yetkisi değişmiyor; has_function_privilege ile ölçülür).
-- ============================================================================

revoke execute on function public.kasa_soru_getir(text, integer, integer) from public, anon;
revoke execute on function public.kasa_soru_idler(text[])                 from public, anon;
revoke execute on function public.kasa_soru_parca(text, text[])           from public, anon;
revoke execute on function public.kasa_ders_fihrist(text)                 from public, anon;
revoke execute on function public.kasa_cevap_yaz(text, text, text)        from public, anon;
revoke execute on function public.kasa_tavan_bildir(text, text)           from public, anon;
grant  execute on function public.kasa_soru_getir(text, integer, integer), public.kasa_soru_idler(text[]),
                           public.kasa_soru_parca(text, text[]), public.kasa_ders_fihrist(text),
                           public.kasa_cevap_yaz(text, text, text), public.kasa_tavan_bildir(text, text) to authenticated;

do $$
declare n int := 0; f text;
begin
  foreach f in array array['public.kasa_soru_getir(text, integer, integer)', 'public.kasa_soru_idler(text[])',
                           'public.kasa_soru_parca(text, text[])', 'public.kasa_ders_fihrist(text)',
                           'public.kasa_cevap_yaz(text, text, text)', 'public.kasa_tavan_bildir(text, text)'] loop
    if has_function_privilege('anon', f, 'execute') then raise exception 'OLCU: anon % hala calistiriyor', f; end if;
    if not has_function_privilege('authenticated', f, 'execute') then raise exception 'OLCU: uye % calistiramiyor (ders sayfasi kirilir)', f; end if;
    n := n + 2;
  end loop;
  if not has_function_privilege('anon', 'public.kasa_dizin(text)', 'execute') then raise exception 'OLCU: kasa_dizin anon kapandi (magaza uygulamasi)'; end if;
  n := n + 1;
  raise notice 'KASA ANON KAPAT OZ-SINAV: % vaka TAMAM', n;
end $$;
