-- ============================================================================
-- 2026-10-18 · ÜYE ÇALIŞMA ÖZETİ (Hesabım panosu)
-- Cem 18.10: "sınavlara üye oldukları sınavları çok iyi görsünler, çözdükleri soruları, aldıkları puanları, eksilerini
-- artılarını profesyonel şekilde görmeleri lazım" → "Hesabım'ı bu taslaktaki gibi gerçek veriyle kur, ders ders çözülen
-- soru için gereken sunucu okuma fonksiyonunu da ekle".
--
-- NEDEN: kasa_cevap (2026-10-11-kasa-set-cevap.sql) her cevabı sunucuda tutuyor ama dışarıya kapalı (politika yok);
-- Hesabım "çözülen / doğru %" rakamını yalnız o CİHAZDAKİ kayıttan (kc_kayit) gösteriyordu → telefon ve bilgisayar farklı.
-- Bu fonksiyon giriş yapmış kişinin YALNIZ KENDİ cevaplarını ders ve konu düzeyinde özetler. Başkasının satırı okunmaz
-- (where user_id = auth.uid()); soru metni, şık, doğru cevap DÖNMEZ - yalnız sayılar ve ders/konu adı.
--
-- DÖNEN (jsonb):
--   dersler: [{sinav, ders, cozulen (tekil soru), cevap, dogru, h_cevap, h_dogru (son 7 gün), o_cevap, o_dogru (önceki 7 gün), son}]
--   konular: [{sinav, ders, konu, cevap, dogru}]  (en az 5 cevaplı konular; en çok 400)
--   olcum:   now()
-- Bilmiyorum ('?') cevabı yanlış sayılır (kasa_cevap_yaz ile aynı: dogru=false).
-- 🚫 GÖRMEZ: ücretsiz örnek/vitrin sayfalarındaki cevaplar (kasa_cevap'a yazılmıyor; cihazdaki kc_kayit'te) ·
--    kasa_cevap öncesi (11.10 öncesi) cevaplar · seviye testi / deneme (onlar ogrenci_sonuc'ta, ayrı okunur).
--
-- ÖLÇÜ (göç sonrası, açık anahtarla - girişsiz istek boş dizi döner, hata değil):
--   curl -s -X POST 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/uye_calisma_ozetim' \
--     -H 'apikey: sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' -H 'Content-Type: application/json' -d '{}'
--   beklenen: 401/42501 (anon'a kapalı)  ·  PGRST202 = göç basılmamış
-- ============================================================================

create or replace function public.uye_calisma_ozetim()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  with c as (
    select a.soru_id, a.dogru, a.zaman, s.sinav, s.ders, nullif(trim(coalesce(s.konu, s.veri->>'konu')), '') as konu
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
    select sinav, ders, konu, count(*) as cevap, count(*) filter (where dogru) as dogru
    from c
    where konu is not null
    group by sinav, ders, konu
    having count(*) >= 5
    order by count(*) desc
    limit 400
  )
  select jsonb_build_object(
    'dersler', coalesce((select jsonb_agg(to_jsonb(d) order by d.sinav, d.cevap desc) from d), '[]'::jsonb),
    'konular', coalesce((select jsonb_agg(to_jsonb(k)) from k), '[]'::jsonb),
    'olcum',   now()
  );
$fn$;

revoke all on function public.uye_calisma_ozetim() from public, anon;
grant execute on function public.uye_calisma_ozetim() to authenticated;
