-- ============================================================================
-- PROVA SONUCU "ÇİZEREK ÇÖZ" (15.10.2026, Cem "1.2.3" madde 1; kapsam onayı video oturumu: hedef YET-2410)
-- Yeni iki fonksiyon; hiçbir göçü eskitmez. Tablo/DDL yok.
--
-- prova_cizim_acik(oturum, an): oturum KAPANDIKTAN sonra true. Kapanış = başlangıç + süre + geç giriş (canli-deneme.html
--   GIRIS_DK=30; veri/canli-deneme.json). YET-2410: 24.10.2026 09:00 TR + 180 + 30 dk = 12:30 TR = 09:30 UTC.
--   Listede olmayan oturum (SGS-1710 dahil) HER ZAMAN false: 17.10 provasında çizim verisi hiç dönmez.
-- prova_cizim(p_oturum, p_idler): oturum kapalıysa {acik:false, acilis} döner, SORU DÖNMEZ. Açıksa o oturumun izin
--   listesindeki kimliklerin çizim alanlarını döner (soru, şıklar, doğru, adım formül/anlatım, çeldirici yolu, teşhis yanılgısı).
--   İzin listesi: YET-2410 paketinin 80 sorusundan KAPI-CZ'yi geçen 43'ün gözle kontrolde kalan 39'u (cizerek-coz.js PROVA).
--   IP 30 / 10 dk.
-- 🚫 GÖRMEZ: oturum kapandıktan sonra listedeki 39 sorunun çözümünü testsiz isteyen herkes alır (paket anahtarı da o saatte
--   yayımlanıyor, açıklamalar zaten pakette). Saat sunucunun now()'ıdır; takvim değişirse bu dosya YENİ göçle güncellenir.
-- ÖZ-SINAV + BOZMA SINAVI: aşağıdaki DO bloğu göç anında koşar (sql-uygula tek işlem: düşerse hiçbir şey basılmaz).
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create or replace function public.prova_cizim_acik(p_oturum text, p_an timestamptz)
returns boolean
language sql
immutable
as $fn$
  select coalesce((select p_an >= o.kapanis
                   from (values ('YET-2410'::text, timestamptz '2026-10-24 09:30:00+00')) as o(kod, kapanis)
                   where o.kod = p_oturum), false)
$fn$;
revoke all on function public.prova_cizim_acik(text, timestamptz) from public;

create or replace function public.prova_cizim(p_oturum text, p_idler jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ip     text;
  izin   text[];
  acilis timestamptz;
  e      jsonb;
  sid    text;
  v      jsonb;
  sonuc  jsonb := '{}'::jsonb;
  n      int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('prova-cizim:' || trim(ip), 30, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if p_oturum = 'YET-2410' then
    acilis := timestamptz '2026-10-24 09:30:00+00';
    izin := array[
      'smmm-w9-1-fmuh-cokzor/kp-08','smmm-gm3-3-fmuh-zor/kp-02','smmm-4k-a-fmuh-cokzor-r2/kp-01','smmm-4k-a-fmuh-kolay-r2-2/kp-01',
      'smmm-4k-a-fmuh-zor-r4/kp-12','smmm-w6-fmuh-zor/kp-34','smmm-w1-fmuh-zor/kp-05','smmm-w4-fmuh-cokzor/kp-10',
      'smmm-w5-fmuh-kolay/kp-16','smmm-w11-1-fmuh-cokzor/kp-02','smmm-w4-fmuh-cokzor/kp-09','smmm-4k-a-fmuh-zor-r3-2/kp-02',
      'smmm-gm5-28-fmuh-zor/kp-04','smmm-w10-4-fmuh-kolay/kp-01','smmm-gm5-10-fmuh-zor/kp-07','smmm-w5-fmuh-kolay/kp-15',
      'smmm-4k-a-maliyet-zor-r3/kp-20','smmm-4k-a-maliyet-kolay-r3/kp-02','smmm-gm4-5-maliyet-kolay/kp-02','smmm-w9-2-maliyet-kolay/kp-01',
      'smmm-4k-a-maliyet-kolay-r4-2/kp-03','smmm-4k-a-maliyet-zor-r3/kp-04','smmm-4k-a-maliyet-zor-r9/kp-03','smmm-4k-a-maliyet-kolay-r3/kp-20',
      'smmm-w7-2-maliyet-kolay/kp-01','smmm-gm5-2-maliyet-zor/kp-01','smmm-4k-a-maliyet-zor-r1/kp-23','smmm-w1-maliyet-zor/kp-14',
      'smmm-4k-a-maliyet-zor-r9/kp-02','smmm-gm-p2-maliyet/kp-03','smmm-gm5-1-maliyet-zor/kp-02','smmm-gm-p2-maliyet/kp-01',
      'smmm-4k-a-maliyet-zor-r7/kp-17','smmm-4k-a-maliyet-zor-r2/kp-01','smmm-w6-yhukuk-kolay/kp-01','smmm-4k-a-yhukuk-zor-r7/kp-05',
      'smmm-gm4-6-yspk-zor/kp-01','smmm-w14-11-yspk-cokzor/kp-01','smmm-w14-13-yspk-cokzor/kp-01'];
  else
    return jsonb_build_object('acik', false, 'sorular', '{}'::jsonb);
  end if;
  if not public.prova_cizim_acik(p_oturum, now()) then
    return jsonb_build_object('acik', false, 'acilis', acilis, 'sorular', '{}'::jsonb);
  end if;
  if jsonb_typeof(p_idler) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for e in select * from jsonb_array_elements(p_idler) loop
    n := n + 1; exit when n > 80;
    sid := left(coalesce(e #>> '{}', ''), 120);
    continue when not (sid = any(izin));
    select veri into v from public.paket_soru p where p.id = sid;
    continue when v is null;
    sonuc := sonuc || jsonb_build_object(sid, jsonb_build_object(
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
  return jsonb_build_object('acik', true, 'acilis', acilis, 'sorular', sonuc);
end;
$fn$;
revoke all on function public.prova_cizim(text, jsonb) from public;
grant execute on function public.prova_cizim(text, jsonb) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- ÖZ-SINAV (8 vaka) + BOZMA SINAVI (4 bozma): kapı fonksiyonunun kaynağı pg_proc'tan okunur, her bozma pg_temp'te
-- ayrı bir kopya olarak kurulur; aynı 8 vakadan EN AZ BİRİ düşmezse göç durur (sınav o bozmayı görmüyor demektir).
-- ---------------------------------------------------------------------------
do $sinav$
declare
  vaka   jsonb := '[
    {"o":"YET-2410","t":"2026-10-24 06:00:00+00","b":false,"ad":"prova başlarken"},
    {"o":"YET-2410","t":"2026-10-24 09:00:00+00","b":false,"ad":"prova sürerken (12:00 TR)"},
    {"o":"YET-2410","t":"2026-10-24 09:29:59+00","b":false,"ad":"kapanıştan 1 sn önce"},
    {"o":"YET-2410","t":"2026-10-24 09:30:00+00","b":true,"ad":"kapanış anı"},
    {"o":"YET-2410","t":"2026-10-25 08:00:00+00","b":true,"ad":"ertesi gün"},
    {"o":"SGS-1710","t":"2026-10-20 08:00:00+00","b":false,"ad":"SGS-1710 bittikten sonra bile kapalı"},
    {"o":"yet-2410","t":"2026-10-25 08:00:00+00","b":false,"ad":"yanlış oturum kimliği (küçük harf)"},
    {"o":"YET-1710","t":"2026-10-25 08:00:00+00","b":false,"ad":"başka oturum kimliği"}
  ]'::jsonb;
  kaynak text;
  bozma  text[][] := array[
    array['>=', '<='],                                        -- saat yönü ters
    array['where o.kod = p_oturum', 'where true'],            -- oturum kimliği denetimi kalktı
    array['09:30:00+00', '05:30:00+00'],                      -- kapanış prova başlamadan önceye çekildi
    array['), false)', '), true)']                            -- bilinmeyen oturum açık sayıldı
  ];
  i int; v jsonb; sonuc boolean; dusen int;
begin
  -- 1) öz-sınav: gerçek fonksiyon
  for v in select * from jsonb_array_elements(vaka) loop
    sonuc := public.prova_cizim_acik(v->>'o', (v->>'t')::timestamptz);
    if sonuc is distinct from (v->>'b')::boolean then
      raise exception 'PROVA-CIZIM ÖZ-SINAV DÜŞTÜ: % (beklenen %, gelen %)', v->>'ad', v->>'b', sonuc;
    end if;
  end loop;
  -- boş oturum / boş saat
  if public.prova_cizim_acik(null, now()) or public.prova_cizim_acik('YET-2410', null) then
    raise exception 'PROVA-CIZIM ÖZ-SINAV DÜŞTÜ: boş girdi açık sayıldı';
  end if;
  -- 2) bozma sınavı
  select prosrc into kaynak from pg_proc where proname = 'prova_cizim_acik' and pronamespace = 'public'::regnamespace;
  for i in 1 .. array_length(bozma, 1) loop
    if position(bozma[i][1] in kaynak) = 0 then
      raise exception 'PROVA-CIZIM BOZMA %: aranan parça kaynakta yok (%)', i, bozma[i][1];
    end if;
    execute format('create or replace function pg_temp.cz_bozuk(p_oturum text, p_an timestamptz) returns boolean language sql as %L',
                   replace(kaynak, bozma[i][1], bozma[i][2]));
    dusen := 0;
    for v in select * from jsonb_array_elements(vaka) loop
      execute 'select pg_temp.cz_bozuk($1, $2)' into sonuc using v->>'o', (v->>'t')::timestamptz;
      if sonuc is distinct from (v->>'b')::boolean then dusen := dusen + 1; end if;
    end loop;
    if dusen = 0 then
      raise exception 'PROVA-CIZIM BOZMA % YAKALANMADI (% -> %): sınav eksik', i, bozma[i][1], bozma[i][2];
    end if;
    raise notice 'PROVA-CIZIM bozma % (% -> %): % vaka KIRMIZI', i, bozma[i][1], bozma[i][2], dusen;
  end loop;
  drop function if exists pg_temp.cz_bozuk(text, timestamptz);
  raise notice 'PROVA-CIZIM ÖZ-SINAV TEMİZ: 10 vaka · bozma 4/4 KIRMIZI';
end
$sinav$;

-- ÖLÇÜ (anon): POST /rest/v1/rpc/prova_cizim {"p_oturum":"YET-2410","p_idler":["smmm-w9-1-fmuh-cokzor/kp-08"]}
--   24.10 12:30 TR öncesi -> {"acik":false,"acilis":"2026-10-24T09:30:00+00:00","sorular":{}}
--   sonrası -> {"acik":true,...,"sorular":{"smmm-w9-1-fmuh-cokzor/kp-08":{...}}}
--   {"p_oturum":"SGS-1710",...} -> her zaman {"acik":false,"sorular":{}}
