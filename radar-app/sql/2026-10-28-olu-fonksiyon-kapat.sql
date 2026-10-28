-- ============================================================================
--  ÖLÜ FONKSİYONLARI KAPAT  ·  28.10.2026 (altyapı kolu, Cem "YAP ÖNERİNİ")
--
--  Anon + üyeye açık ama hiçbir yayındaki sayfanın, edge'in ya da başka fonksiyonun çağırmadığı 4 SECURITY DEFINER
--  fonksiyon (28.10 ölçümü: radar-app/canli-sema/fonksiyonlar.sql içinde çağrı 0; depoda tek çağıran yayında OLMAYAN
--  _kapali-araclar/evrak-app.html):
--    · istek_getir(uuid)            eski Evrak Radarı: belge isteği + mükellef adı döndürür (müşteri verisi)
--    · mukellef_pano(uuid)          eski Evrak Radarı: mükellefin belge listesi + bağlantıları (müşteri verisi)
--    · cevap_kaydet(uuid,uuid,text,text)  eski Evrak Radarı: isteğe cevap/dosya YAZAR
--    · yonetim_ozel_kod_uret(text,integer,integer)  eski sürüm; panel yonetim_ozel_kod_uret2 kullanıyor
--      (içinde yonetici_mi() denetimi var; ölü kod, denetim kazara silinirse herkes indirim kodu üretirdi)
--  İlk üçü jeton (uuid) istiyor; tahmin edilemez ama sızmış eski bir jetonla hâlâ çalışırdı.
--  SİLİNMEZ, yalnız kapatılır: geri açmak = "grant execute on function ... to anon, authenticated".
-- ============================================================================

revoke execute on function public.istek_getir(uuid)                              from public, anon, authenticated;
revoke execute on function public.mukellef_pano(uuid)                            from public, anon, authenticated;
revoke execute on function public.cevap_kaydet(uuid, uuid, text, text)           from public, anon, authenticated;
revoke execute on function public.yonetim_ozel_kod_uret(text, integer, integer)  from public, anon, authenticated;

do $$
declare n int := 0; f text; rol text;
begin
  foreach f in array array['public.istek_getir(uuid)', 'public.mukellef_pano(uuid)',
                           'public.cevap_kaydet(uuid, uuid, text, text)', 'public.yonetim_ozel_kod_uret(text, integer, integer)'] loop
    foreach rol in array array['anon', 'authenticated'] loop
      if has_function_privilege(rol, f, 'execute') then raise exception 'OLCU: % % hala calistiriyor', rol, f; end if;
      n := n + 1;
    end loop;
  end loop;
  -- yeni sürüm kapanmamalı (yönetim paneli)
  if not has_function_privilege('authenticated', 'public.yonetim_ozel_kod_uret2(text, integer, jsonb, text)', 'execute') then
    raise exception 'OLCU: yonetim_ozel_kod_uret2 uyeye kapandi (panel kirilir)'; end if;
  n := n + 1;
  raise notice 'OLU FONKSIYON KAPAT OZ-SINAV: % vaka TAMAM', n;
end $$;
