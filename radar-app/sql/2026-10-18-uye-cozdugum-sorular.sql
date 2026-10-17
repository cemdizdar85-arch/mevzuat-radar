-- ============================================================================
-- 2026-10-18 · ÜYENİN ÇÖZDÜĞÜ SORU KİMLİKLERİ (Hesabım "sık çıkıp hiç dokunmadığın konular")
-- Cem 18.10 "1.2.3 üçünü de yap" — madde 1: liste yalnız bu cihazdaki son 500 cevaba (kc_kayit) bakıyordu; telefonda çözülen
-- konu bilgisayarda "dokunmadın" görünüyordu. Bu fonksiyon giriş yapmış kişinin sunucudaki BÜTÜN cevaplarından
-- (kasa_cevap) tekil soru kimliğini ve dersini döndürür; calisma-ozet.js dokunulmamis() bunları kc_kayit ile birleştirir.
-- Kimlik biçimi kc_kayit.id ile aynı ("<etiket>/kp-NN"; kasa-yukle.js kasa_cevap_yaz'a aynı id'yi yolluyor).
-- Yalnız auth.uid() satırları; soru metni/şık/doğru cevap DÖNMEZ.
-- DÖNEN: jsonb [{i: soru_id, d: ders}]  (en çok 30.000)
-- 🚫 GÖRMEZ: ücretsiz örnek/vitrin cevapları (kasa_cevap'a yazılmıyor) · 11.10 öncesi cevaplar.
-- ÖLÇÜ: anon istek 42501 beklenir · PGRST202 = basılmamış.
-- ============================================================================

create or replace function public.uye_cozdugum_sorular()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce(jsonb_agg(jsonb_build_object('i', t.soru_id, 'd', t.ders)), '[]'::jsonb)
  from (
    select distinct on (a.soru_id) a.soru_id, s.ders
    from public.kasa_cevap a
    left join public.paket_soru s on s.id = a.soru_id
    where a.user_id = auth.uid()
    order by a.soru_id
    limit 30000
  ) t;
$fn$;

revoke all on function public.uye_cozdugum_sorular() from public, anon;
grant execute on function public.uye_cozdugum_sorular() to authenticated;
