-- ============================================================================
--  MARKA SORGUSU KİŞİ BAŞI GÜNLÜK SINIR  ·  28.10.2026 (marka kolu; site oturumu onayı "IP başına günde 20")
--
--  NEDEN: marka_talep_ac'ta yalnız GENEL günlük tavan vardı (3.000): tek kişi doldurursa o gün kimse sorgulayamaz.
--  ÖLÇÜM (28.10, marka_talep tamamı): toplam 24 sorgu (20.08–08.09), en yoğun gün 14, hepsi girişsiz (büyük ihtimalle
--  bizim denemelerimiz). Sınır 20/IP/gün: portföy taraması yapan bir kullanıcıya yeter; 3.000'i doldurmak 150 IP ister.
--  IP: PostgREST istek başlığından (x-forwarded-for ilk adres; alacak_ara ile aynı kalıp). Hız sayacı (rate_log) 10 dk'dan
--  uzun pencere tutmadığı için IP marka_talep satırına yazılır ve son 24 saat sayılır.
--  KİŞİSEL VERİ: IP 7 gün sonra silinir (ip = null) — hem her sorguda hem günlük robotla (marka_talep_ip_temizle,
--  .github/workflows/marka-bulten.yml). Satırın kendisi (unvan/sonuç) eskisi gibi kalır.
--  🚫 GÖRMEZ: IP değiştiren (mobil ağ, VPN) aynı kişi · aynı IP'yi paylaşan bir ofis (20'yi birlikte kullanır).
-- ============================================================================

alter table public.marka_talep add column if not exists ip text;
create index if not exists ix_marka_talep_ip_zaman on public.marka_talep (ip, created_at) where ip is not null;

create or replace function public.marka_talep_ac(p_unvan text, p_email text default null::text, p_kaynak text default null::text)
returns text
language plpgsql security definer set search_path to 'public' as $function$
declare v_jeton text; v_gunluk int; v_ip text;
begin
  if p_unvan is null or length(btrim(p_unvan)) < 3 or length(p_unvan) > 160 then
    raise exception 'Unvan 3-160 karakter olmali'; end if;
  v_ip := nullif(btrim(split_part(coalesce(current_setting('request.headers', true)::json->>'x-forwarded-for', ''), ',', 1)), '');
  if v_ip is not null and (select count(*) from public.marka_talep
                            where ip = v_ip and created_at > now() - interval '1 day') >= 20 then
    raise exception 'Bugunluk sorgu hakkin doldu (gunde 20). Yarin tekrar dene.'; end if;
  select count(*) into v_gunluk from public.marka_talep where created_at > now() - interval '1 day';
  if v_gunluk > 3000 then raise exception 'Gunluk sorgu tavani doldu, yarin tekrar dene'; end if;
  update public.marka_talep set ip = null where ip is not null and created_at < now() - interval '7 days';
  v_jeton := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  insert into public.marka_talep(jeton, unvan, email, user_id, kaynak, ip)
  values (v_jeton, btrim(p_unvan), nullif(btrim(coalesce(p_email,'')),''), auth.uid(),
          left(nullif(btrim(coalesce(p_kaynak,'')),''),40), v_ip);
  return v_jeton;
end; $function$;

-- Günlük robot temizliği (servis): 7 günden eski IP'ler silinir. Dönen = silinen IP sayısı.
create or replace function public.marka_talep_ip_temizle()
returns integer
language plpgsql security definer set search_path to 'public' as $function$
declare n int;
begin
  update public.marka_talep set ip = null where ip is not null and created_at < now() - interval '7 days';
  get diagnostics n = row_count; return n;
end; $function$;
revoke execute on function public.marka_talep_ip_temizle() from public, anon, authenticated;
grant  execute on function public.marka_talep_ip_temizle() to service_role;

-- ÖZ-SINAV (ölçü satırları silinir; IP istek başlığı set_config ile taklit edilir)
do $$
declare n int := 0; i int; j text; ok boolean; e constant text := 'OLCU-SINIR-ZQ';
begin
  delete from public.marka_talep where unvan like e || '%';
  perform set_config('request.headers', '{"x-forwarded-for":"203.0.113.77, 10.0.0.1"}', true);
  for i in 1..20 loop j := public.marka_talep_ac(e || ' ' || i, null, 'olcu'); end loop;
  if (select count(*) from public.marka_talep where unvan like e || '%' and ip = '203.0.113.77') <> 20 then raise exception 'OLCU1: IP yazilmadi'; end if;
  n := n + 1;
  ok := false; begin perform public.marka_talep_ac(e || ' 21', null, 'olcu'); exception when others then ok := sqlerrm like 'Bugunluk sorgu hakkin doldu%'; end;
  if not ok then raise exception 'OLCU2: 21. sorgu durmadi'; end if;
  n := n + 1;
  perform set_config('request.headers', '{"x-forwarded-for":"203.0.113.78"}', true);
  perform public.marka_talep_ac(e || ' baska', null, 'olcu');
  n := n + 1;   -- başka IP etkilenmez
  perform set_config('request.headers', '{}', true);
  perform public.marka_talep_ac(e || ' ipsiz', null, 'olcu');
  n := n + 1;   -- IP okunamazsa (servis/robot) sınır uygulanmaz, genel tavan geçerli
  update public.marka_talep set created_at = now() - interval '8 days' where unvan = e || ' 1';
  -- ayrı iki ifade: aynı ifadedeki alt sorgu, fonksiyonun güncellemesini görmez (tek anlık görüntü; ilk koşu bu yüzden düştü)
  i := public.marka_talep_ip_temizle();
  if i < 1 then raise exception 'OLCU5a: temizlik % satir', i; end if;
  if (select ip from public.marka_talep where unvan = e || ' 1') is not null then raise exception 'OLCU5b: 8 gunluk IP silinmedi'; end if;
  if (select count(*) from public.marka_talep where unvan like e || '%' and ip is not null) <> 20 then raise exception 'OLCU5c: taze IP de silindi'; end if;
  n := n + 1;
  if has_function_privilege('anon', 'public.marka_talep_ip_temizle()', 'execute') then raise exception 'OLCU6: temizlik anon acik'; end if;
  if not has_function_privilege('anon', 'public.marka_talep_ac(text, text, text)', 'execute') then raise exception 'OLCU7: sayfa fonksiyonu kapandi'; end if;
  n := n + 2;
  delete from public.marka_talep where unvan like e || '%';
  perform set_config('request.headers', '', true);
  raise notice 'MARKA TALEP SINIR OZ-SINAV: % vaka TAMAM', n;
end $$;
