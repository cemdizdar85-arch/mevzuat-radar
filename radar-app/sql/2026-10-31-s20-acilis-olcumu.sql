-- ============================================================================
--  SON 20 GÜN — AÇILIŞ ÖLÇÜMÜ (GERÇEK D1–D7 VERİSİYLE, HİÇBİR SATIR KALMAZ)  ·  31.10.2026 (sgs kolu)
--
--  CEM 31.10: "Paketli bir üyenin 00:00'dan sonra bir denemeyi açıp çözebildiği ve karnesinin göründüğü ... sen dene bunu".
--  Bu dosya şema DEĞİŞTİRMEZ. Tek alt işlem içinde: geçici paketli üye (son20-sgs) kurulur, kasadaki GERÇEK 7 deneme
--  "açılış geldi" diye öne çekilir ve üyenin gözünden uçtan uca yürünür; sonunda her şey geri alınır.
--   1. 00:00 öncesi: 7 denemenin her dersi S20_KAPALI (kapı bugün kapalı) · 7 denemede açılış = 01.11 00:00 (+03) ve kalite onayı dolu.
--   2. Açılış sonrası (alt işlemde acilis = now()-1 dk): D1'in 15 dersi getir → soru sayısı = s20_soru, doğru şık/açıklama SIZMIYOR.
--   3. D1'in 15 dersi hep yanlış teslim → puan doğru (0 doğru), açıklama dönüyor, karne (s20_liste) her derste sonuç gösteriyor.
--   4. Oran < %60 → çalışma görevi kurulur (1–5 konu) · görev varken D2 testi AÇILMAZ (S20_GOREV).
--   5. Görevlerin hepsi doğru cevaplanır → görev tamam → D2 testi açılır.
--   6. İkinci üye: D2–D7'nin 90 ders testi getirilir (sayı + sızıntı).
--  Sonuç GitHub günlüğünde "S20 ACILIS OLCUMU: ..." notunda. Geri alma ölçülür (üye, sonuç, görev, açılış değişmemiş).
--  🚫 GÖRMEZ: tarayıcı ekranı (son-20-gun.html çizimi), uygulama içi görünüm, gerçek giriş (parola/Google) akışı.
-- ============================================================================
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e3101';
  b constant uuid := '00000000-0000-4000-8000-0000000e3102';
  r record; g record; q record; j jsonb; cvp jsonb; n_ders int := 0; n_soru int := 0; n_test int := 0; gorev int := 0;
  rap text := ''; acilis0 jsonb;
begin
  select jsonb_object_agg(no::text, acilis) into acilis0 from public.s20_deneme where no between 1 and 7;
  begin
    -- 1. bugünkü durum
    if (select count(*) from public.s20_deneme where no between 1 and 7 and acilis = timestamptz '2026-11-01 00:00:00+03'
          and coalesce(btrim(kalite_onay),'') <> '') <> 7 then raise exception 'OLCU: 7 denemenin acilis/kalite kaydi eksik'; end if;
    if (select count(*) from public.s20_soru where deneme between 1 and 7) <> 910 then
      raise exception 'OLCU: soru sayisi %', (select count(*) from public.s20_soru where deneme between 1 and 7); end if;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20a@tetikte.invalid', now(), now()),
      (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20b@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-sgs', current_date + 30), (b, 'son20-sgs', current_date + 30);
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    if auth.uid() is distinct from a then raise exception 'OLCU: auth.uid ayarlanamadi'; end if;
    if not public.s20_erisim() then raise exception 'OLCU: 7 Deneme paketi erisim vermiyor'; end if;
    for r in select distinct deneme, ders from public.s20_soru where deneme between 1 and 7 loop
      begin perform public.s20_test_getir(r.deneme, r.ders); raise exception 'OLCU: D% % acilistan once acildi', r.deneme, r.ders;
      exception when others then if sqlerrm <> 'S20_KAPALI' then raise; end if; end;
      n_test := n_test + 1;
    end loop;
    rap := rap || format('kapali-once %s/105 · ', n_test);

    -- 2–3. açılış geldi: D1 uçtan uca
    update public.s20_deneme set acilis = now() - interval '1 minute' where no between 1 and 7;
    j := public.s20_liste();
    if (select count(*) from jsonb_array_elements(j->'denemeler') e where (e->>'acik')::boolean and (e->>'toplam')::int = 130) <> 7 then
      raise exception 'OLCU: liste 7 acik deneme gostermiyor %', j->'denemeler'; end if;
    for r in select ders, min(sira) ilk from public.s20_soru where deneme = 1 group by ders order by 2 loop
      j := public.s20_test_getir(1, r.ders);
      if jsonb_array_length(j->'sorular') <> (select count(*) from public.s20_soru where deneme = 1 and ders = r.ders) then
        raise exception 'OLCU: D1 % soru sayisi', r.ders; end if;
      if position('"dogru"' in (j->'sorular')::text) > 0 or position('"aciklama"' in (j->'sorular')::text) > 0 then
        raise exception 'OLCU: D1 % getirirken cevap/aciklama sizdi', r.ders; end if;
      select jsonb_object_agg(s.id, case s.veri->>'dogru' when 'A' then 'B' else 'A' end) into cvp from public.s20_soru s where s.deneme = 1 and s.ders = r.ders;
      j := public.s20_test_bitir(1, r.ders, cvp, 600);
      if (j->>'dogru')::int <> 0 or (j->>'yanlis')::int <> (j->>'toplam')::int or not (j->>'ilk')::boolean then raise exception 'OLCU: D1 % puan %', r.ders, j - 'sorular'; end if;
      if jsonb_array_length(j->'sorular') = 0 or (j->'sorular'->0->'veri'->>'dogru') !~ '^[A-E]$' then raise exception 'OLCU: D1 % bitiste cevap donmedi', r.ders; end if;
      gorev := greatest(gorev, coalesce((j->>'gorev')::int, 0));
      n_ders := n_ders + 1; n_soru := n_soru + (j->>'toplam')::int;
    end loop;
    j := public.s20_liste();
    if (select count(*) from jsonb_array_elements(j->'denemeler') e, jsonb_array_elements(e->'dersler') d
         where (e->>'no')::int = 1 and d->'sonuc' is not null and d->'sonuc' <> 'null'::jsonb) <> n_ders then raise exception 'OLCU: karne her dersi gostermiyor'; end if;
    rap := rap || format('D1 %s ders %s soru teslim, karne %s ders · ', n_ders, n_soru, n_ders);

    -- 4. görev + kilit
    if gorev < 1 or gorev > 5 then raise exception 'OLCU: gorev sayisi %', gorev; end if;
    if jsonb_array_length(j->'gorevler') <> gorev then raise exception 'OLCU: listede gorev %', jsonb_array_length(j->'gorevler'); end if;
    begin perform public.s20_test_getir(2, (select ders from public.s20_soru where deneme = 2 order by sira limit 1)); raise exception 'OLCU: gorev varken D2 acildi';
    exception when others then if sqlerrm <> 'S20_GOREV' then raise; end if; end;
    rap := rap || format('gorev %s konu (%s), D2 kilitli · ', gorev,
      (select string_agg(ders || ': ' || konu, ' / ' order by sira) from public.s20_gorev where user_id = a));

    -- 5. görevleri doğru bitir → D2 açılır
    for g in select deneme, ders, konu from public.s20_gorev where user_id = a order by sira loop
      j := public.s20_gorev_getir(g.deneme, g.ders, g.konu);
      if position('"dogru"' in (select jsonb_agg(x - 'cevap') from jsonb_array_elements(j->'sorular') x)::text) > 0 then raise exception 'OLCU: gorev sorusu cevap sizdirdi'; end if;
      for q in select ps.id, ps.veri->>'dogru' d from public.paket_soru ps, public.s20_gorev x
                where x.user_id = a and x.deneme = g.deneme and x.ders = g.ders and x.konu = g.konu and ps.id = any(x.sorular) loop
        j := public.s20_gorev_cevap(g.deneme, g.ders, g.konu, q.id, q.d);
      end loop;
      if not (j->>'tamam')::boolean then raise exception 'OLCU: % gorevi tamamlanmadi %', g.konu, j - 'veri'; end if;
    end loop;
    if public._s20_gorev_acik(a) then raise exception 'OLCU: gorev hala acik'; end if;
    j := public.s20_test_getir(2, (select ders from public.s20_soru where deneme = 2 order by sira limit 1));
    rap := rap || 'gorevler bitti, D2 acildi · ';

    -- 6. ikinci üye: D2–D7 bütün testler
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b::text, true);
    n_test := 0; n_soru := 0;
    for r in select deneme, ders, count(*) k from public.s20_soru where deneme between 2 and 7 group by deneme, ders loop
      j := public.s20_test_getir(r.deneme, r.ders);
      if jsonb_array_length(j->'sorular') <> r.k then raise exception 'OLCU: D% % sayi', r.deneme, r.ders; end if;
      if position('"dogru"' in (j->'sorular')::text) > 0 or position('"aciklama"' in (j->'sorular')::text) > 0 then
        raise exception 'OLCU: D% % sizinti', r.deneme, r.ders; end if;
      if exists (select 1 from jsonb_array_elements(j->'sorular') x where coalesce(x->>'soru','') = '' or jsonb_typeof(x->'siklar') <> 'object') then
        raise exception 'OLCU: D% % bos soru/sik', r.deneme, r.ders; end if;
      n_test := n_test + 1; n_soru := n_soru + r.k;
    end loop;
    rap := rap || format('D2-D7 %s test %s soru acildi', n_test, n_soru);
    raise exception 'OLCU_TAMAM|%', rap;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM|%' then raise; end if;
    rap := split_part(sqlerrm, '|', 2);
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where id in (a, b)) or exists (select 1 from public.s20_sonuc where user_id in (a, b))
     or exists (select 1 from public.s20_gorev where user_id in (a, b))
     or (select jsonb_object_agg(no::text, acilis) from public.s20_deneme where no between 1 and 7) is distinct from acilis0 then
    raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'S20 ACILIS OLCUMU: %', rap;
end $$;
