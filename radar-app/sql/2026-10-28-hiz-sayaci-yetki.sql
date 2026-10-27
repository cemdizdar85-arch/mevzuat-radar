-- ============================================================================
--  HIZ SAYACI YETKİSİ  ·  28.10.2026 (altyapı kolu, Cem "1.2.3")
--
--  OLAY: rate_limit_check(p_ip, p_limit, p_pencere_sn) anon + authenticated'a açıktı (2026-07-17 ve 2026-08-19 göçleri
--  bilerek "grant ... to anon, authenticated" yazmış; edge'ler anon anahtarla çağırıyordu). Biri başkasının IP'si adına
--  sayacı doldurup o kişinin formunu / net-cevap'ını kilitleyebilir, rate_log'u şişirebilirdi.
--  ÖNCE edge'ler servis anahtarına geçti (4f3878bb, edge-yukle 40605149717 canlı = depo) ve ölçüldü: net-cevap,
--  beyanname-oku, quick-task (form-al), karne-gonder ?tani=hiz → {"hiz":200}. Bu göç ondan SONRA kapatır.
--  Veritabanı içi çağıranlar (alacak_ara, alacak_toplu, seviye_kontrol, seviye_aciklama, seviye_cizim, prova_cizim,
--  paketimi_bagla) security definer: sahibin yetkisiyle çağırır, etkilenmez (aşağıda ölçülür).
--  🚫 GÖRMEZ: kodu depoda olmayan (panelden elle yüklenmiş) bir edge'in anon anahtarla çağırması. Depo taraması 28.10:
--     rate_limit_check'i çağıran edge'ler yalnız yukarıdaki 4 + siparis-bildirim (zaten servis) + meta-olay (canlıda yok);
--     site/uygulama/robot kodunda çağıran yok.
-- ============================================================================

revoke execute on function public.rate_limit_check(text, integer, integer) from public, anon, authenticated;
grant  execute on function public.rate_limit_check(text, integer, integer) to service_role;

do $$
declare n int := 0; r record; fn constant text := 'public.rate_limit_check(text, integer, integer)';
begin
  if has_function_privilege('anon', fn, 'execute') then raise exception 'OLCU: anon hala calistiriyor'; end if;
  if has_function_privilege('authenticated', fn, 'execute') then raise exception 'OLCU: authenticated hala calistiriyor'; end if;
  if not has_function_privilege('service_role', fn, 'execute') then raise exception 'OLCU: service_role calistiramiyor (edgeler kirilir)'; end if;
  n := 3;
  for r in select p.oid::regprocedure as f, p.prosecdef, pg_get_userbyid(p.proowner) as sahip from pg_proc p
           where p.pronamespace = 'public'::regnamespace
             and p.proname in ('alacak_ara','alacak_toplu','seviye_kontrol','seviye_aciklama','seviye_cizim','prova_cizim','paketimi_bagla') loop
    if not r.prosecdef then raise exception 'OLCU: % security definer degil, sayaci cagiramaz', r.f; end if;
    if not has_function_privilege(r.sahip, fn, 'execute') then raise exception 'OLCU: % sahibi % sayaci calistiramiyor', r.f, r.sahip; end if;
    n := n + 1;
  end loop;
  if n < 10 then raise exception 'OLCU: cagiranlarin % tanesi bulundu, 7 bekleniyordu', n - 3; end if;
  raise notice 'HIZ SAYACI YETKI OZ-SINAV: % vaka TAMAM', n;
end $$;
