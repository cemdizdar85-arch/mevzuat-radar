-- ============================================================================
-- SEVİYE TESTİ "ÇİZEREK ÇÖZ" TADIMI (14.10.2026, Cem "1.2.3 üçünü de yap" — ücretsiz testte düğme yalnız 1 soruda)
-- Yeni fonksiyon; hiçbir göçü eskitmez. Tablo/DDL yok.
--
-- Seviye testi soruyu CEVAPSIZ görür (ucretsiz_soru). Test bitince sonuç ekranı, testteki soru kimliklerini gönderir;
-- fonksiyon izin listesindeki İLK kimliğin çizim verisini döner (en çok 1 soru): soru, şıklar, doğru, adımların
-- formül/anlatımı, çeldirici yolu, teşhis "yanılgı" cümlesi. Başka alan (sade, kaynak paketi, hakem) DÖNMEZ.
-- İzin listesi: Yeterlilik 1 sabit soru (30 soruluk set sabit, her testte var) + SGS pilotunun 20 sorusu
-- (SGS testi her adayda farklı çekilir; adayın testindeki ilk pilot sorusu tadım olur). Liste cizerek-coz.js PILOT ile
-- aynı kimliklerden; sayfa zaten en çok 1 kart çizer.
-- Hız sınırı: IP başına 20 istek / 10 dk (rate_limit_check). Yalnız ucretsiz = true satır.
-- 🚫 GÖRMEZ: testi çözmeden doğrudan çağıran kişi listedeki 21 sorunun çözümünü tek tek alabilir (bu sorular zaten
--    ücretsiz; doğru şık ve açıklama seviye_aciklama'dan da dönüyor). Kapı (rakam/aritmetik) tarayıcıda koşar.
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create or replace function public.seviye_cizim(p_idler jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ip    text;
  izin  text[] := array[
    'smmm-4k-a-fmuh-zor-r5/kp-03',
    'sgs-k11-ticaret-zor/kp-01', 'sgs-d3-mta-cokzor-r3/kp-01', 'sgs-d3-maliyet-cokzor-r1/kp-02', 'sgs-c2-fmuh-kolay-r1/kp-02',
    'sgs-t1-fmuh-kolay/kp-11', 'sgs-d5-vergi-cokzor-r2/kp-02', 'sgs-d3-fmuh-kolay-r1/kp-16', 'sgs-d3-fmuh-kolay-r1/kp-21',
    'sgs-d2-fmuh-kolay-r1/kp-03', 'sgs-k11-mat-kolay/kp-03', 'sgs-c2-fmuh-kolay-r1/kp-03', 'sgs-d2-fmuh-zor-r1/kp-01',
    'sgs-d2-fmuh-kolay-r2/kp-04', 'sgs-c2-fmuh-zor-r3/kp-02', 'sgs-c2-denetim-kolay-r2/kp-05', 'sgs-c2-mta-kolay-r1/kp-01',
    'sgs-k5-fmuh-zor/kp-17', 'sgs-p-ekonomi-kolay-r1-a/kp-04', 'sgs-t1-mta-zor/kp-01', 'sgs-t1-maliyet-kolay/kp-07'];
  e     jsonb;
  sid   text;
  v     jsonb;
  n     int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye-cizim:' || trim(ip), 20, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if jsonb_typeof(p_idler) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for e in select * from jsonb_array_elements(p_idler) loop
    n := n + 1; exit when n > 40;
    sid := left(coalesce(e #>> '{}', ''), 120);
    continue when not (sid = any(izin));
    select veri into v from public.paket_soru p where p.id = sid and p.ucretsiz;
    continue when v is null;
    return jsonb_build_object('soru', jsonb_build_object(
      'id', sid,
      'soru', v->'soru',
      'siklar', v->'siklar',
      'dogru', v->'dogru',
      'adimlar', (select jsonb_agg(jsonb_build_object('formul', a->'formul', 'anlatim', a->'anlatim', 'verilenAdim', a->'verilenAdim',
                                                      'sik', a->'sik', 'kisi', a->'kisi', 'giris', a->'giris') order by o)
                  from jsonb_array_elements(case when jsonb_typeof(v->'adimlar') = 'array' then v->'adimlar' else '[]'::jsonb end) with ordinality as x(a, o)),
      'celdiriciYol', v->'celdiriciYol',
      'teshis', (select jsonb_object_agg(k, jsonb_build_object('yanilgi', t->'yanilgi'))
                 from jsonb_each(case when jsonb_typeof(v->'teshis') = 'object' then v->'teshis' else '{}'::jsonb end) as y(k, t))
    ));
  end loop;
  return jsonb_build_object('soru', null);
end;
$fn$;
revoke all on function public.seviye_cizim(jsonb) from public;
grant execute on function public.seviye_cizim(jsonb) to anon, authenticated;

-- ÖLÇÜ: anon POST /rest/v1/rpc/seviye_cizim {"p_idler":["x/kp-01","smmm-4k-a-fmuh-zor-r5/kp-03"]} -> soru.id = smmm-4k-a-fmuh-zor-r5/kp-03
--       {"p_idler":["smmm-4k-a-fmuh-kolay-r4/kp-01"]} (izin listesinde değil) -> {"soru": null}
