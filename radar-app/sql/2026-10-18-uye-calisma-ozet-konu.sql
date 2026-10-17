-- ============================================================================
-- 2026-10-18 · ÜYE ÇALIŞMA ÖZETİ — KONU KONU (Hesabım ders detayı)
-- Cem 18.10: "ders ders ve konu konu başarısını ölçsün, finansal muhasebe tıklayayım nelerde eksiği var görsün hesabımda"
-- + "bunu her derse yapacaksın, ona göre yap".
--
-- NEDEN: 2026-10-18-uye-calisma-ozet.sql konuları yalnız EN AZ 5 cevaplıysa döndürüyordu (artılar/eksiler için).
-- Ders tıklanınca o dersin BÜTÜN konuları (1 cevaplı dahil) gerekir. Aynı fonksiyon yeniden tanımlanır (eski göç dosyası
-- değiştirilmez): konu satırına son 7 gün ve son cevap tarihi eklenir, eşik 1, tavan 2.000. Eşik 5 artık istemcide uygulanır
-- (ogrenci.html artılar/eksiler). dersler alanı AYNEN.
-- Yalnız giriş yapmış kişinin KENDİ cevapları (auth.uid()); soru metni/şık/doğru cevap DÖNMEZ.
-- 🚫 GÖRMEZ: konusu boş soru ('Konusu işaretlenmemiş' diye tek satırda toplanır) · ücretsiz örnek cevapları · 11.10 öncesi.
-- ÖLÇÜ: anon istek 42501 beklenir · PGRST202 = basılmamış.
-- ============================================================================

create or replace function public.uye_calisma_ozetim()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  with c as (
    select a.soru_id, a.dogru, a.zaman, s.sinav, s.ders,
           coalesce(nullif(trim(coalesce(s.konu, s.veri->>'konu')), ''), 'Konusu işaretlenmemiş') as konu
    from public.kasa_cevap a
    join public.paket_soru s on s.id = a.soru_id
    where a.user_id = auth.uid()
  ),
  d as (
    select sinav, ders,
           count(distinct soru_id)                                                                   as cozulen,
           count(*)                                                                                  as cevap,
           count(*) filter (where dogru)                                                             as dogru,
           count(*) filter (where zaman > now() - interval '7 days')                                 as h_cevap,
           count(*) filter (where dogru and zaman > now() - interval '7 days')                       as h_dogru,
           count(*) filter (where zaman <= now() - interval '7 days' and zaman > now() - interval '14 days')            as o_cevap,
           count(*) filter (where dogru and zaman <= now() - interval '7 days' and zaman > now() - interval '14 days')  as o_dogru,
           max(zaman)                                                                                as son
    from c
    group by sinav, ders
  ),
  k as (
    select sinav, ders, konu,
           count(distinct soru_id)                                             as cozulen,
           count(*)                                                            as cevap,
           count(*) filter (where dogru)                                       as dogru,
           count(*) filter (where zaman > now() - interval '7 days')           as h_cevap,
           count(*) filter (where dogru and zaman > now() - interval '7 days') as h_dogru,
           max(zaman)                                                          as son
    from c
    group by sinav, ders, konu
    order by count(*) desc
    limit 2000
  )
  select jsonb_build_object(
    'dersler', coalesce((select jsonb_agg(to_jsonb(d) order by d.sinav, d.cevap desc) from d), '[]'::jsonb),
    'konular', coalesce((select jsonb_agg(to_jsonb(k)) from k), '[]'::jsonb),
    'olcum',   now()
  );
$fn$;

revoke all on function public.uye_calisma_ozetim() from public, anon;
grant execute on function public.uye_calisma_ozetim() to authenticated;
