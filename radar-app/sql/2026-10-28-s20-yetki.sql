-- ============================================================================
--  SON 20 GÜN — YETKİ ONARIMI  ·  28.10.2026 (site kolu)
--
--  OLAY (ölçüldü 28.10, 2026-10-28-s20-deneme.sql canlıya çıktıktan hemen sonra): anonim istek s20_deneme_yukle'yi
--  ÇALIŞTIRDI (yanıt "S20_YUKLE_BICIM", 401 değil). Sebep: Supabase public şemada yeni fonksiyonlara anon + authenticated'a
--  AÇIK GRANT veriyor (varsayılan yetki); "revoke ... from public" bu açık grant'ları kaldırmaz. Tablolar boştu, yazım olmadı.
--  Bu göç yetkileri ROL ROL kapatır ve göç içinde has_function_privilege ile ölçer.
--  🚫 GÖRMEZ: eski fonksiyonlarda aynı desen (ör. kasa_cekim_izin2 anonim çağrıda "oturum yok" dönüyor = çalışıyor) — ayrı iş.
-- ============================================================================

revoke execute on function public.s20_deneme_yukle(jsonb) from public, anon, authenticated;
revoke execute on function public._s20_acik(integer)       from public, anon, authenticated;
revoke execute on function public._s20_kapi(integer)       from public, anon, authenticated;
revoke execute on function public.s20_erisim()             from public, anon;
revoke execute on function public.s20_test_getir(integer, text)                  from public, anon;
revoke execute on function public.s20_test_bitir(integer, text, jsonb, integer)  from public, anon;
grant  execute on function public.s20_deneme_yukle(jsonb) to service_role;
grant  execute on function public.s20_liste() to anon, authenticated;
grant  execute on function public.s20_erisim(), public.s20_test_getir(integer, text), public.s20_test_bitir(integer, text, jsonb, integer) to authenticated;

do $$
declare n int := 0; r record;
begin
  for r in select * from (values
      ('anon',          'public.s20_deneme_yukle(jsonb)', false),
      ('authenticated', 'public.s20_deneme_yukle(jsonb)', false),
      ('service_role',  'public.s20_deneme_yukle(jsonb)', true),
      ('anon',          'public._s20_acik(integer)', false),
      ('authenticated', 'public._s20_acik(integer)', false),
      ('anon',          'public._s20_kapi(integer)', false),
      ('authenticated', 'public._s20_kapi(integer)', false),
      ('anon',          'public.s20_test_getir(integer, text)', false),
      ('authenticated', 'public.s20_test_getir(integer, text)', true),
      ('anon',          'public.s20_test_bitir(integer, text, jsonb, integer)', false),
      ('authenticated', 'public.s20_test_bitir(integer, text, jsonb, integer)', true),
      ('anon',          'public.s20_liste()', true),
      ('anon',          'public.s20_erisim()', false)) as t(rol, fn, beklenen) loop
    if has_function_privilege(r.rol, r.fn, 'execute') <> r.beklenen then
      raise exception 'OLCU: % % execute=% olmali', r.rol, r.fn, r.beklenen; end if;
    n := n + 1;
  end loop;
  for r in select * from (values ('anon','public.s20_soru'),('authenticated','public.s20_soru'),('anon','public.s20_sonuc'),
                                 ('authenticated','public.s20_sonuc'),('anon','public.s20_deneme'),('authenticated','public.s20_deneme')) as t(rol, tb) loop
    if has_table_privilege(r.rol, r.tb, 'select') or has_table_privilege(r.rol, r.tb, 'insert') then
      raise exception 'OLCU: % % tabloya erisiyor', r.rol, r.tb; end if;
    n := n + 1;
  end loop;
  raise notice 'S20 YETKI OZ-SINAV: % vaka TAMAM', n;
end $$;
