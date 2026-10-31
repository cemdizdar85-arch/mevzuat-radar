-- ============================================================================
--  SON 20 GÜN — ÖNCEKİ DENEME BİTMEDEN SONRAKİ AÇILMAZ  ·  31.10.2026 (sgs kolu)
--
--  CEM 31.10 ("riskleri kapatalım şimdi"): açık şuydu — görev ancak bir denemenin BÜTÜN ders testleri bitince kuruluyor;
--  denemeyi yarıda bırakan üye sonraki denemelere geçip görevi hiç görmüyordu. Kampanya koşulları "Görevler tamamlanınca
--  sonraki deneme açılır" diyor.
--  YENİ KURAL (_s20_gorev_kapi, s20_test_getir + s20_test_bitir ikisi de çağırır):
--   · Üyenin daha önce çözdüğü test her zaman açılır (yeniden çözüm).
--   · Açık görev varken çözülmemiş test açılmaz (S20_GOREV) — aynen.
--   · Açılmış (_s20_acik) bir ÖNCEKİ denemede üyenin bitirmediği ders testi varsa çözülmemiş test açılmaz (S20_ONCEKI).
--     Açılmamış önceki deneme kilitlemez (kimse takılmasın).
--  Sayfa (son-20-gun.html) aynı kuralı s20_liste'den çizer: kilitli denemede "Önce Deneme N: kalan dersler …".
--  🚫 GÖRMEZ: Yeterlilik (ayrı kayıt, 8 Kasım). Push ile otomatik (sql-uygula.yml). Sonunda öz-sınav (gerçek D1–D2, geri alınır).
-- ============================================================================

create or replace function public._s20_gorev_kapi(p_deneme integer, p_ders text)
returns void language plpgsql stable security definer set search_path = public as $fn$
begin
  if exists (select 1 from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders) then return; end if;
  if public._s20_gorev_acik(auth.uid()) then raise exception 'S20_GOREV' using errcode = 'P0001'; end if;
  if exists (select 1 from public.s20_soru s
              where s.deneme < p_deneme and public._s20_acik(s.deneme)
                and not exists (select 1 from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = s.deneme and x.ders = s.ders)) then
    raise exception 'S20_ONCEKI' using errcode = 'P0001';
  end if;
end $fn$;

revoke all on function public._s20_gorev_kapi(integer, text) from public, anon, authenticated;

-- GÖÇ İÇİ ÖZ-SINAV (gerçek Deneme 1–2; bütün satırlar geri alınır)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e3121';
  r record; cvp jsonb; d1ilk text; d2ilk text; ac0 jsonb; adim int := 0;
begin
  select jsonb_object_agg(no::text, acilis) into ac0 from public.s20_deneme where no between 1 and 7;
  begin
    if has_function_privilege('authenticated', 'public._s20_gorev_kapi(integer, text)', 'execute') then raise exception 'OLCU: kapi uyeye acik'; end if;
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
      values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20k@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-sgs', current_date + 30);
    update public.s20_deneme set acilis = now() - interval '1 minute' where no between 1 and 7;
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    select ders into d1ilk from public.s20_soru where deneme = 1 order by sira limit 1;
    select ders into d2ilk from public.s20_soru where deneme = 2 order by sira limit 1;

    -- 1. hiçbir şey çözülmemiş: D1 açık, D2 kilitli
    perform public.s20_test_getir(1, d1ilk);
    begin perform public.s20_test_getir(2, d2ilk); raise exception 'OLCU: D1 bitmeden D2 acildi';
    exception when others then if sqlerrm <> 'S20_ONCEKI' then raise; end if; end;
    adim := adim + 2;
    -- 2. D1'in bir dersi bitti, öbürleri yok: D2 hâlâ kilitli, teslim de kilitli
    select jsonb_object_agg(s.id, s.veri->>'dogru') into cvp from public.s20_soru s where s.deneme = 1 and s.ders = d1ilk;
    perform public.s20_test_bitir(1, d1ilk, cvp, 60);
    begin perform public.s20_test_getir(2, d2ilk); raise exception 'OLCU: D1 yarimken D2 acildi';
    exception when others then if sqlerrm <> 'S20_ONCEKI' then raise; end if; end;
    begin perform public.s20_test_bitir(2, d2ilk, '{}'::jsonb, 1); raise exception 'OLCU: D1 yarimken D2 teslim edildi';
    exception when others then if sqlerrm <> 'S20_ONCEKI' then raise; end if; end;
    -- 3. bitirilen test yeniden açılır
    perform public.s20_test_getir(1, d1ilk);
    adim := adim + 3;
    -- 4. D1'in kalan dersleri hep doğru → görev yok → D2 açılır; D3 D2 bitmeden kilitli
    for r in select distinct ders from public.s20_soru where deneme = 1 and ders <> d1ilk loop
      select jsonb_object_agg(s.id, s.veri->>'dogru') into cvp from public.s20_soru s where s.deneme = 1 and s.ders = r.ders;
      perform public.s20_test_bitir(1, r.ders, cvp, 60);
    end loop;
    if public._s20_gorev_acik(a) then raise exception 'OLCU: hepsi dogruya gorev'; end if;
    perform public.s20_test_getir(2, d2ilk);
    begin perform public.s20_test_getir(3, (select ders from public.s20_soru where deneme = 3 order by sira limit 1)); raise exception 'OLCU: D2 bitmeden D3 acildi';
    exception when others then if sqlerrm <> 'S20_ONCEKI' then raise; end if; end;
    adim := adim + 3;
    -- 5. açılmamış önceki deneme kilitlemez: D1 kapalıyken D2 (D1 bitmemiş üye için) — b yerine a'nın D1 sonuçlarını silerek
    delete from public.s20_sonuc where user_id = a and deneme = 1;
    update public.s20_deneme set acilis = now() + interval '1 day' where no = 1;
    perform public.s20_test_getir(2, d2ilk);
    adim := adim + 1;
    raise exception 'OLCU_TAMAM|%', adim;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM|%' then raise; end if;
    raise notice 'S20 ONCEKI KILIT OZ-SINAV: % vaka TAMAM (D1 bitmeden D2 kilitli · yarimken getir+teslim kilitli · cozulen yeniden acilir · D1 bitince D2 acik, D3 kilitli · acilmamis onceki kilitlemez)', split_part(sqlerrm, '|', 2);
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where id = a) or exists (select 1 from public.s20_sonuc where user_id = a)
     or (select jsonb_object_agg(no::text, acilis) from public.s20_deneme where no between 1 and 7) is distinct from ac0 then
    raise exception 'OLCU: geri alma iz birakti'; end if;
end $$;
