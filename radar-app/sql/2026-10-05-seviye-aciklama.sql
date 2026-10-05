-- ============================================================================
-- SEVİYE TESTİ → NÖBETÇİ YANLIŞINI ANLATIYOR (05.10.2026, Cem: "30 soruyu çözdükten sonra bizim anlatımımızı göremeyecek,
-- en iyi olduğumuz yeri görmeyecekler" → "1.2.3 üçünü de yapalım")
--
-- Test bitince sonuç ekranı öğrencinin İLK 3 yanlışının anlatımını gösterir: seçtiği şıkkın tuzağı (ad + metin), doğru cevabın
-- nedeni (sade.dogru), kural, dayanak. YALNIZ ücretsiz sorular (paket_soru.ucretsiz). Paketli sorunun anlatımı yine kilitli.
-- Kalite: vitrin_aciklama_dislanan tablosundaki soru (kalite kapısı bulgulu; arac/vitrin-aciklama-kalite.js yazar) DÖNMEZ;
-- doğru açıklaması ya da seçilen şıkkın tuzak metni boşsa DÖNMEZ; dayanak Türkçe harfsiz yazılmışsa dayanak alanı boş döner.
-- Bilinen sınır: bir IP 10 dakikada 15 çağrı × 3 soru = 45 ücretsiz sorunun anlatımını alabilir. Bu sorular zaten ücretsiz
-- katmanda; bilinçli bedel (seviye_kontrol'deki harf sınırıyla aynı mantık).
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create table if not exists public.vitrin_aciklama_dislanan (
  id     text primary key,
  neden  text not null,
  olcum  timestamptz not null default now()
);
alter table public.vitrin_aciklama_dislanan enable row level security;
revoke all on public.vitrin_aciklama_dislanan from anon, authenticated;
-- politika YOK: yalnız servis anahtarı yazar/okur.

create or replace function public.seviye_aciklama(p_cevaplar jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ip    text;
  c     jsonb;
  sid   text;
  sec   text;
  v     jsonb;
  dogru text;
  sade  text;
  tmetin text;
  day   text;
  sonuc jsonb := '[]'::jsonb;
  n     int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye-aciklama:' || trim(ip), 15, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if jsonb_typeof(p_cevaplar) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for c in select * from jsonb_array_elements(p_cevaplar) loop
    exit when n >= 3;
    sid := left(coalesce(c->>'id',''), 120);
    sec := upper(left(coalesce(c->>'secim',''), 1));
    select veri into v from public.paket_soru p
      where p.id = sid and p.ucretsiz
        and not exists (select 1 from public.vitrin_aciklama_dislanan d where d.id = p.id);
    continue when v is null;
    dogru := upper(coalesce(v->>'dogru',''));
    continue when sec = '' or sec = dogru;
    sade := case when jsonb_typeof(v->'sade') = 'object' then v->'sade'->>'dogru' else v->>'sade' end;
    tmetin := v->'tuzak'->sec->>'metin';
    continue when coalesce(sade,'') = '' or coalesce(tmetin,'') = '';
    day := v->>'dayanak';
    if day ~* '\m(sayili|isletme|odeme|isci|isveren|sirket|yonetmelik|teblig|ozel|gorev|ucret|degisik|gecici|kurulus|sozlesme|hukum)\M' then
      day := null;
    end if;
    sonuc := sonuc || jsonb_build_array(jsonb_build_object(
      'id', sid, 'secim', sec, 'dogru', dogru,
      'secim_metin', v->'siklar'->>sec, 'dogru_metin', v->'siklar'->>dogru,
      'tuzak_ad', v->'tuzak'->sec->>'ad', 'tuzak_metin', tmetin,
      'aciklama', sade, 'kural', v->>'kural', 'dayanak', day));
    n := n + 1;
  end loop;
  return jsonb_build_object('liste', sonuc);
end $fn$;
revoke all on function public.seviye_aciklama(jsonb) from public;
grant execute on function public.seviye_aciklama(jsonb) to anon, authenticated;

-- DOĞRULAMA (UYGULANDI.md'ye yazılır):
--   anonim: vitrin_aciklama_dislanan                         -> 401/0 satır
--   anonim: rpc/seviye_aciklama [{"id":<ücretsiz id>,"secim":<yanlış harf>}] -> liste 1 öğe
--   anonim: rpc/seviye_aciklama [{"id":<paketli id>,"secim":"A"}]           -> liste boş
--   anonim: doğru harfle çağrı                                -> liste boş
