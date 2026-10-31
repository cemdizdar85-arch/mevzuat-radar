-- ============================================================================
--  MARKA AYNASI TOPLU OKUMA KAPISI  ·  28.10.2026 (altyapı kolu, Cem "YAP ÖNERİNİ" madde 3)
--
--  28.10 okuması (radar-app/canli-sema/fonksiyonlar.sql, 19 marka fonksiyonu): marka_ayna_sahip(p_unvan, p_tavan)
--  anon'a açık (veri/sql-marka-ayna.sql bilerek "grant ... to anon"), ama HİÇBİR sayfa/robot/edge çağırmıyor. Herkes
--  3 harfle TÜRKPATENT aynamızdan tek çağrıda 5.000 kayıt çekebiliyor = toplu kazıma kapısı. marka_ayna_durum da
--  çağıransız (yalnız sayaç; kapatmak zararsız). İkisi SİLİNMEZ, yalnız kapatılır; robot/servis anahtarı etkilenmez.
--  Dokunulmayan marka fonksiyonları: sayfaların kullandıkları (bulten_itiraz/sahip/durum, takip_ac/kapat, talep_ac/sonuc),
--  jetonlu takip_gor, sayaçlar, zaten kapalı 4 robot fonksiyonu, invoker yardımcılar (marka_norm*).
-- ============================================================================

revoke execute on function public.marka_ayna_sahip(text, integer) from public, anon, authenticated;
revoke execute on function public.marka_ayna_durum()              from public, anon, authenticated;
grant  execute on function public.marka_ayna_sahip(text, integer), public.marka_ayna_durum() to service_role;

do $$
declare n int := 0; f text; rol text;
begin
  foreach f in array array['public.marka_ayna_sahip(text, integer)', 'public.marka_ayna_durum()'] loop
    foreach rol in array array['anon', 'authenticated'] loop
      if has_function_privilege(rol, f, 'execute') then raise exception 'OLCU: % % hala calistiriyor', rol, f; end if;
      n := n + 1;
    end loop;
    if not has_function_privilege('service_role', f, 'execute') then raise exception 'OLCU: service_role % calistiramiyor', f; end if;
    n := n + 1;
  end loop;
  -- sayfaların kullandığı marka fonksiyonları açık kalmalı
  foreach f in array array['public.marka_bulten_itiraz(text, integer[], integer, real, integer, boolean)', 'public.marka_bulten_sahip(text, integer)',
                           'public.marka_takip_ac(text, integer[], text)', 'public.marka_talep_ac(text, text, text)'] loop
    if not has_function_privilege('anon', f, 'execute') then raise exception 'OLCU: sayfa fonksiyonu % kapandi', f; end if;
    n := n + 1;
  end loop;
  raise notice 'MARKA AYNA KAPAT OZ-SINAV: % vaka TAMAM', n;
end $$;
