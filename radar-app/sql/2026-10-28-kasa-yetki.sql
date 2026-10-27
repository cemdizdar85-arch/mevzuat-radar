-- ============================================================================
--  KASA İÇ FONKSİYON YETKİSİ  ·  28.10.2026 (altyapı kolu)
--
--  OLAY (ölçüldü 28.10): anonim istek kasa_cekim_izin2'yi ÇALIŞTIRDI (yanıt "oturum yok", 401 değil). Sebep
--  s20-yetki.sql ile aynı: Supabase public şemada yeni fonksiyonlara anon + authenticated'a AÇIK grant veriyor;
--  2026-10-10-kasa-tekil-sayim.sql'deki "revoke all ... from public" bunları kaldırmadı. Girişli üye bu fonksiyonu
--  doğrudan çağırıp kendi kasa_cekim sayacına sahte satır yazabilir (tavanı kendine erken kapatır / ölçümü bozar).
--
--  KAPSAM (28.10 envanteri: 138 RPC anon anahtarla salt-okunur GET ile yoklandı → 55 anon'a açık; depoda çağıranı
--  çıkarıldı). Yalnız İÇ fonksiyon kapatılır = sayfa/uygulama/edge çağırmıyor, çağıranların HEPSİ security definer:
--    · kasa_cekim_izin2  ← kasa_soru_getir · kasa_soru_idler · kasa_soru_parca · s20_test_getir (hepsi SD)
--    · alacak_abone_mi   ← alacak_toplu (SD)
--  BİLEREK DOKUNULMAYAN:
--    · rate_limit_check: edge'ler (net-cevap, beyanname-oku, form-al, karne-gonder, meta-olay) ANON anahtarla
--      çağırıyor; kapatılırsa net-cevap + beyanname-oku herkesi engeller. Önce edge'ler servis anahtarına geçmeli.
--    · paket_erisim_var: depolama okuma politikası (authenticated) içinde çağrılıyor; anon'a açık ama oturumsuz false.
--  🚫 GÖRMEZ: depoda tanımı olmayan (panelden kurulmuş) fonksiyonlar — aşağıdaki envanter NOTICE'ı onları da listeler.
-- ============================================================================

revoke execute on function public.kasa_cekim_izin2(text, integer, integer, text[]) from public, anon, authenticated;
revoke execute on function public.alacak_abone_mi()                                from public, anon, authenticated;

do $$
declare n int := 0; r record; liste text := '';
begin
  for r in select * from (values
      ('anon',          'public.kasa_cekim_izin2(text, integer, integer, text[])', false),
      ('authenticated', 'public.kasa_cekim_izin2(text, integer, integer, text[])', false),
      ('anon',          'public.alacak_abone_mi()', false),
      ('authenticated', 'public.alacak_abone_mi()', false),
      -- çağıranlar kapanmamalı (sayfaların kullandığı RPC)
      ('authenticated', 'public.kasa_soru_getir(text, integer, integer)', true),
      ('authenticated', 'public.s20_test_getir(integer, text)', true),
      ('anon',          'public.alacak_toplu(text[])', true)) as t(rol, fn, beklenen) loop
    if to_regprocedure(r.fn) is null then raise exception 'OLCU: % bulunamadi (imza degismis)', r.fn; end if;
    if has_function_privilege(r.rol, r.fn, 'execute') <> r.beklenen then
      raise exception 'OLCU: % % execute=% olmali', r.rol, r.fn, r.beklenen; end if;
    n := n + 1;
  end loop;
  -- çağıranlar security definer ve sahibi iç fonksiyonu çalıştırabiliyor mu (kapatma onları kırmamalı)
  for r in select p.oid::regprocedure as fn, p.prosecdef, pg_get_userbyid(p.proowner) as sahip from pg_proc p
           where p.pronamespace = 'public'::regnamespace
             and p.proname in ('kasa_soru_getir','kasa_soru_idler','kasa_soru_parca','s20_test_getir','alacak_toplu') loop
    if not r.prosecdef then raise exception 'OLCU: % security definer degil, ic fonksiyonu cagiramaz', r.fn; end if;
    if not has_function_privilege(r.sahip, 'public.kasa_cekim_izin2(text, integer, integer, text[])', 'execute')
       or not has_function_privilege(r.sahip, 'public.alacak_abone_mi()', 'execute') then
      raise exception 'OLCU: % sahibi % ic fonksiyonu calistiramiyor', r.fn, r.sahip; end if;
    n := n + 1;
  end loop;
  raise notice 'KASA YETKI OZ-SINAV: % vaka TAMAM', n;

  -- ENVANTER (bilgi, durdurmaz): public'te anon ya da authenticated'ın çalıştırabildiği security definer fonksiyonlar
  for r in select p.proname, has_function_privilege('anon', p.oid, 'execute') as a,
                  has_function_privilege('authenticated', p.oid, 'execute') as u
           from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prosecdef
             and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))
           order by 1 loop
    liste := liste || r.proname || case when r.a then '[A]' else '[U]' end || ' ';
  end loop;
  raise notice 'SD ENVANTER (A=anon+uye, U=yalniz uye): %', liste;
end $$;
