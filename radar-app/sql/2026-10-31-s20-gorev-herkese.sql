-- ============================================================================
--  SON 20 GÜN — ÇALIŞMA GÖREVİ HER DENEMEDEN SONRA  ·  31.10.2026 (sgs kolu)
--
--  CEM 31.10: "her ders test test ... sınav sonucunda öğrenmediği konuları öğreteceğiz, öğrendikten sonra diğer sınavı
--  açtıracağız" → soru "Görev kime açılsın?" → "Herkese". Önceki kural (2026-10-28-s20-gorev.sql): görev yalnız doğru oranı
--  %60'ın ALTINDA kalan denemeden sonra. Yeni kural: deneme ilk kez tamamlanınca, oran ne olursa olsun yanlış/boş bırakılan
--  konulardan en çok 5 konu (bankada en az 4 yeni sorusu olan) görev olur; görev bitmeden çözülmemiş deneme testi açılmaz.
--  Hiç yanlışı yoksa ya da yanlış konuları için bankada soru yoksa görev çıkmaz. Yalnız eşik kalktı; konu seçimi, tur,
--  kilit aynen. Söz ölçütü (%60) DEĞİŞMEZ — o sitede sayılır.
--  🚫 GÖRMEZ: konu adı bankayla eşleşmeyen sorular (açılış sonrası iş: deneme sorularının ≈%50'si).
--  Push ile otomatik (sql-uygula.yml). Sonunda öz-sınav: gerçek D1 ile, bütün satırlar geri alınır.
-- ============================================================================

create or replace function public._s20_gorev_kur(p_uid uuid, p_deneme integer)
returns integer language plpgsql volatile security definer set search_path = public as $fn$
declare n int := 0; dersSay int; sonucSay int; r record; ids text[];
begin
  if exists (select 1 from public.s20_gorev g where g.user_id = p_uid and g.deneme = p_deneme) then return 0; end if;
  select count(distinct s.ders) into dersSay from public.s20_soru s where s.deneme = p_deneme;
  select count(*) into sonucSay from public.s20_sonuc x where x.user_id = p_uid and x.deneme = p_deneme;
  if dersSay = 0 or sonucSay < dersSay then return 0; end if;
  for r in
    select s.ders, s.konu, count(*) as k
      from public.s20_soru s join public.s20_sonuc x on x.user_id = p_uid and x.deneme = s.deneme and x.ders = s.ders
     where s.deneme = p_deneme and coalesce(btrim(s.konu),'') <> ''
       and coalesce(x.cevap->>s.id, '') is distinct from (s.veri->>'dogru')
     group by s.ders, s.konu order by count(*) desc, s.ders, s.konu
  loop
    ids := public._s20_gorev_aday(p_uid, r.ders, r.konu, '{}', 4);
    if cardinality(ids) = 4 then
      n := n + 1;
      insert into public.s20_gorev (user_id, deneme, ders, konu, sira, yanlis, sorular, gorulen)
      values (p_uid, p_deneme, r.ders, r.konu, n, r.k, ids, ids);
      exit when n >= 5;
    end if;
  end loop;
  return n;
end $fn$;

revoke all on function public._s20_gorev_kur(uuid, integer) from public, anon, authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (gerçek Deneme 1; bütün satırlar geri alınır)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e3111';
  b constant uuid := '00000000-0000-4000-8000-0000000e3112';
  r record; j jsonb; cvp jsonb; g_a int := 0; g_b int := 0; dog int; top int; ac0 timestamptz;
begin
  select acilis into ac0 from public.s20_deneme where no = 1;
  begin
    if has_function_privilege('anon', 'public._s20_gorev_kur(uuid, integer)', 'execute')
       or has_function_privilege('authenticated', 'public._s20_gorev_kur(uuid, integer)', 'execute') then
      raise exception 'OLCU: _s20_gorev_kur uyeye acik'; end if;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20g1@tetikte.invalid', now(), now()),
      (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20g2@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-sgs', current_date + 30), (b, 'son20-sgs', current_date + 30);
    update public.s20_deneme set acilis = now() - interval '1 minute' where no in (1, 2);

    -- a: yüzde 60'ın ÜSTÜNDE (bankayla eşleşen konulardaki soruların yarısı yanlış, kalanı doğru) → görev çıkmalı, D2 kilitli
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    for r in select distinct ders from public.s20_soru where deneme = 1 loop
      select jsonb_object_agg(s.id, case when s.sira % 4 = 0 and exists (select 1 from public.paket_soru ps where ps.sinav = 'sgs' and ps.ders = s.ders and ps.konu = s.konu and ps.id not like 'sgs-s20-%')
                                         then (case s.veri->>'dogru' when 'A' then 'B' else 'A' end) else s.veri->>'dogru' end)
        into cvp from public.s20_soru s where s.deneme = 1 and s.ders = r.ders;
      j := public.s20_test_bitir(1, r.ders, cvp, 60);
      g_a := greatest(g_a, coalesce((j->>'gorev')::int, 0));
    end loop;
    select sum(dogru), sum(toplam) into dog, top from public.s20_sonuc where user_id = a and deneme = 1;
    if dog * 100 < top * 60 then raise exception 'OLCU: a yuzde 60 ustu kurulamadi (%/%)', dog, top; end if;
    if g_a < 1 then raise exception 'OLCU: yuzde 60 ustu (%/%) gorev cikmadi', dog, top; end if;
    begin perform public.s20_test_getir(2, (select ders from public.s20_soru where deneme = 2 order by sira limit 1)); raise exception 'OLCU: gorev varken D2 acildi';
    exception when others then if sqlerrm <> 'S20_GOREV' then raise; end if; end;

    -- b: hepsi doğru → görev yok, D2 açık
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b::text, true);
    for r in select distinct ders from public.s20_soru where deneme = 1 loop
      select jsonb_object_agg(s.id, s.veri->>'dogru') into cvp from public.s20_soru s where s.deneme = 1 and s.ders = r.ders;
      j := public.s20_test_bitir(1, r.ders, cvp, 60);
      g_b := greatest(g_b, coalesce((j->>'gorev')::int, 0));
    end loop;
    if g_b <> 0 then raise exception 'OLCU: hepsi dogruya gorev cikti'; end if;
    perform public.s20_test_getir(2, (select ders from public.s20_soru where deneme = 2 order by sira limit 1));
    raise exception 'OLCU_TAMAM|a %/% dogru -> % konu gorev, D2 kilitli · b hepsi dogru -> gorev 0, D2 acik', dog, top, g_a;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM|%' then raise; end if;
    raise notice 'S20 GOREV HERKESE OZ-SINAV: %', split_part(sqlerrm, '|', 2);
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where id in (a, b)) or exists (select 1 from public.s20_gorev where user_id in (a, b))
     or (select acilis from public.s20_deneme where no = 1) is distinct from ac0 then raise exception 'OLCU: geri alma iz birakti'; end if;
end $$;
