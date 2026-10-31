-- ============================================================================
-- 2026-10-28 · ÜYENİN ÇÖZDÜĞÜ SORULAR + SON CEVABIN DOĞRULUĞU (Hesabım "Konu hedeflerin")
-- Cem 28.10 "Konu başına hedef çubuğu (SmartPath gibi): bunu yapalım". 2026-10-18 fonksiyonu yalnız {i, d} dönüyordu;
-- konu başına doğru oranı için soru başına SON cevabın doğruluğu ('o') eklenir. Biçim geriye uyumlu (eski okuyucu 'o'yu görmez).
-- calisma-ozet.js dokunulmamis() → konu başına coz / olc / dog; ogrenci.html hedefKonuCiz().
-- Yalnız auth.uid() satırları; soru metni/şık/doğru cevap DÖNMEZ (yalnız kendi cevabının doğru/yanlış olduğu).
-- DÖNEN: jsonb [{i: soru_id, d: ders, o: son cevap doğru mu}]  (en çok 30.000)
-- YETKİ: 28.10 s20-yetki dersi — Supabase varsayılanı yeni fonksiyona anon'a da açık grant verir; "revoke from public" yetmez,
--   anon rolden AÇIKÇA geri alınır. Öz-sınav aşağıda: anon yetkisi kalırsa göç DÜŞER.
-- 🚫 GÖRMEZ: ücretsiz örnek/vitrin cevapları (kasa_cevap'a yazılmıyor) · 11.10 öncesi cevaplar.
-- ============================================================================

create or replace function public.uye_cozdugum_sorular()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce(jsonb_agg(jsonb_build_object('i', t.soru_id, 'd', t.ders, 'o', t.dogru)), '[]'::jsonb)
  from (
    select distinct on (a.soru_id) a.soru_id, s.ders, a.dogru
    from public.kasa_cevap a
    left join public.paket_soru s on s.id = a.soru_id
    where a.user_id = auth.uid()
    order by a.soru_id, a.zaman desc
    limit 30000
  ) t;
$fn$;

revoke all on function public.uye_cozdugum_sorular() from public;
revoke all on function public.uye_cozdugum_sorular() from anon;
grant execute on function public.uye_cozdugum_sorular() to authenticated;

do $oz$
begin
  if has_function_privilege('anon', 'public.uye_cozdugum_sorular()', 'execute') then
    raise exception 'OZ-SINAV: anon uye_cozdugum_sorular() cagirabiliyor';
  end if;
  if not has_function_privilege('authenticated', 'public.uye_cozdugum_sorular()', 'execute') then
    raise exception 'OZ-SINAV: authenticated uye_cozdugum_sorular() cagiramiyor';
  end if;
end
$oz$;
