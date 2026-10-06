-- ============================================================================
-- SEVİYE AÇIKLAMA: dayanak satırı temizliği (06.10.2026, Cem "1.2.3 üçünü de yap" — vitrinin tam elle okuması)
-- 2026-10-05-seviye-aciklama-bos.sql ile AYNI fonksiyon; tek fark dayanak gizleme koşulu genişledi:
--   (a) Türkçe harfsiz kelime listesi (arac/vitrin-aciklama-kalite.js KISA_ASCII ile aynı)
--   (b) üretimden kalan iç notlar: "(mevzuat maddesi yok)", "(kaynak metni)", "[1/2]", "Ambar:", "Kaynak paket",
--       "Kural 2", "teori parçası", "Uygulama: C şıkkı", "Sınav Tuzağı (4)", "ders notu … madde 5".
-- Tam elle okuma (629 kart) bunları öğrencinin göreceği dayanakta buldu; kartın kendisi sağlam olduğundan kart dışlanmaz,
-- yalnız dayanak satırı boş döner. Öteki kurallar AYNEN (ücretsiz · dışlanan yok · boş/yanlış ayrımı · en çok 3 · IP 15/10 dk).
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
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
    continue when sec = dogru;
    sade := case when jsonb_typeof(v->'sade') = 'object' then v->'sade'->>'dogru' else v->>'sade' end;
    continue when coalesce(sade,'') = '';
    tmetin := case when sec = '' then null else v->'tuzak'->sec->>'metin' end;
    continue when sec <> '' and coalesce(tmetin,'') = '';
    day := v->>'dayanak';
    if day ~* '\m(sayili|isletme|odeme|isci|isveren|sirket|yonetmelik|yonetmeligi|teblig|tebligi|ozel|gorev|ucret|degisik|gecici|kurulus|sozlesme|hukum|sira|tekduzen|plani|duzenleme|islem|islemleri|mukellef|degerleme|yukumlu)\M'
       or day ~* '(mevzuat maddesi yok|\(kaynak metni?\)|kaynak metne göre|\mkural *[0-9]|\[[0-9]/[0-9]\]|\mambar\M|kaynak paket|teori *par[cç]as|uygulama *: *[a-e]? *ş[ıi]kk|sınav tuzağı *\([0-9]|ders notu.{0,40}madde *[0-9])' then
      day := null;
    end if;
    sonuc := sonuc || jsonb_build_array(jsonb_build_object(
      'id', sid, 'secim', nullif(sec,''), 'dogru', dogru,
      'secim_metin', case when sec = '' then null else v->'siklar'->>sec end, 'dogru_metin', v->'siklar'->>dogru,
      'tuzak_ad', case when sec = '' then null else v->'tuzak'->sec->>'ad' end, 'tuzak_metin', tmetin,
      'aciklama', sade, 'kural', v->>'kural', 'dayanak', day));
    n := n + 1;
  end loop;
  return jsonb_build_object('liste', sonuc);
end $fn$;
revoke all on function public.seviye_aciklama(jsonb) from public;
grant execute on function public.seviye_aciklama(jsonb) to anon, authenticated;
