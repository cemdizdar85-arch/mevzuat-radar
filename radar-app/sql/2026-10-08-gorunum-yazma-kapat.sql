-- 2026-10-08 · GÖRÜNÜMLERDEN ANONİM YAZMA KAPISINI KAPAT (site kolu, açılış öncesi güvenlik denetimi)
--
-- Ölçüldü 08.10 (anon/publishable anahtar, canlı):
--   GET  /rest/v1/soru_havuzu_arsiv_v1?select=id&limit=1  -> 206, Content-Range 0-0/30569 (RLS'i atlıyor)
--   PATCH/DELETE ?id=eq.__yok_denetim__                    -> 204 (yetki VAR; sıfır satıra denk getirildi)
-- Neden: 2026-09-10-kalip-surum-kapisi.sql görünümü security_invoker'sız kurdu ve revoke yazmadı; Supabase
-- varsayılanı yeni nesneye anon/authenticated'a TÜM hakları veriyor. Görünüm sahibi (postgres) RLS'e takılmadığı için
-- tek bir "DELETE ?id=neq.x" v1 arşivinin tamamını (7.699 insan onaylı satır dahil) silebilirdi.
-- Görünümü kullanan sayfa/robot/edge yok (git grep 08.10: yalnız SQL + UYGULANDI.md).
--
-- Kapsam: (1) bu görünüm: bütün haklar geri + security_invoker; (2) public'teki BÜTÜN görünümlerden anon ve
-- authenticated için INSERT/UPDATE/DELETE/TRUNCATE geri alınır (okuma hakkına dokunulmaz — ucretsiz_soru gibi
-- kasıtlı okunan görünümler aynen çalışır). Görünümden istemci yazması hiçbir yerde tasarlanmadı.
-- 🚫 GÖRMEZ: tablolardaki hakları (onlar RLS ile korunuyor, 08.10 ölçümü) · materialized view · public dışı şemalar.

revoke all on public.soru_havuzu_arsiv_v1 from anon, authenticated;
alter view public.soru_havuzu_arsiv_v1 set (security_invoker = true);

do $$
declare r record;
begin
  for r in select table_name from information_schema.views where table_schema = 'public' loop
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', r.table_name);
  end loop;
end $$;

-- ÖLÇÜ: bir görünümde anon/authenticated yazma hakkı kaldıysa göç TÜMDEN geri alınır (tek işlem).
do $$
declare kalan int;
begin
  select count(*) into kalan
  from information_schema.role_table_grants g
  join information_schema.views v on v.table_schema = g.table_schema and v.table_name = g.table_name
  where g.table_schema = 'public'
    and g.grantee in ('anon', 'authenticated')
    and g.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE');
  if kalan > 0 then
    raise exception 'gorunum-yazma-kapat: % yazma hakki hala acik', kalan;
  end if;
end $$;
