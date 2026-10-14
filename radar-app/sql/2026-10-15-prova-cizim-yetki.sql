-- ============================================================================
-- PROVA ÇİZİM: iç kapı fonksiyonunun anon/authenticated hakkı kaldırılır (15.10.2026)
-- Ölçüldü: 2026-10-15-prova-cizim.sql "revoke ... from public" yazıyordu ama Supabase varsayılan hakları anon ve
-- authenticated'a AYRICA veriyor; anon POST rpc/prova_cizim_acik {"p_oturum":"YET-2410","p_an":"2026-10-25T00:00:00Z"} -> true.
-- Fonksiyon veri döndürmez (yalnız saat karşılaştırması), zarar yok; ama kütükte "anon hakkı yok" yazıyordu → yazılan doğru olsun.
-- prova_cizim (security definer, sahibi postgres) bu fonksiyonu çağırmaya devam eder.
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
revoke execute on function public.prova_cizim_acik(text, timestamptz) from anon, authenticated;

-- ÖLÇÜ: anon POST /rest/v1/rpc/prova_cizim_acik -> 401/404 (yetki yok) · anon rpc/prova_cizim YET-2410 -> {"acik":false,...} (değişmez)
