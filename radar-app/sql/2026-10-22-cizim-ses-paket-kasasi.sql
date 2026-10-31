-- KGK SESLİ ÇİZİM — SES PAKET KAPISININ ARKASINDA (22.10.2026, Cem: "KGK'nın bu 10 sorusunda çizime bağla, ses paket kapısı arkasında kalsın")
--
-- Örnek soruların sesi (ses/cizim/**, eebe63cd) herkese açık site dosyasıdır; o sorular zaten ücretsiz. KGK sorusu paketlidir:
-- sesi de soru metni gibi yalnız paketi olan üyeye gitmeli. Düzen:
--   1) storage kovası 'cizim-ses-paket' PUBLIC DEĞİL (doğrudan adresle inmez), yalnız audio/mpeg, dosya başı ≤ 2 MB.
--   2) Okuma politikası: yalnız authenticated + public.cizim_ses_erisim(<soru id>) = true. Kimlik klasör adından: '<id / yerine __>/r<n>.mp3' (depolama ~ kabul etmiyor, ölçüldü)
--      (ör. kgk-t2-ky-g4-cokzor__kp-03/r1.mp3). Erişim kuralı kasa_soru_getir ile AYNI: public.paket_erisim_var(sinav, ders).
--   3) Yazma/silme politikası YOK: yalnız servis anahtarı yükler (yerel yükleyici; anahtar depoda değil).
--   4) Tarayıcı (cizerek-coz.js SES_KASA) üyenin oturumuyla createSignedUrls (30 dk) ister; alamazsa çizim SESSİZ sürer.
-- 🚫 GÖRMEZ: imzalı adres 30 dk boyunca adresi bilen herkese açıktır (paketli üye adresi başkasına verirse) · ses çekimi kasa
--   sayacına (kasa_cekim) YAZILMAZ — tavan yalnız soru okumada · paketi bitmiş üyenin elindeki imzalı adres süresi dolana dek çalışır.

-- 1) KOVA ------------------------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cizim-ses-paket', 'cizim-ses-paket', false, 2097152, array['audio/mpeg'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- 2) ERİŞİM İŞLEVİ (paket_soru üyeye doğrudan kapalı; politika bu işlevle sorar) ---------------------------
create or replace function public.cizim_ses_erisim(p_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select auth.uid() is not null and exists (
    select 1 from public.paket_soru s
    where s.id = p_id and public.paket_erisim_var(s.sinav, s.ders)
  );
$fn$;
revoke all on function public.cizim_ses_erisim(text) from public;
revoke all on function public.cizim_ses_erisim(text) from anon;   -- Supabase varsayılan izni anon'a da verir; "from public" onu KALDIRMAZ (22.10 ilk koşu bu öz-sınavla düştü)
grant execute on function public.cizim_ses_erisim(text) to authenticated;

-- 3) OKUMA POLİTİKASI (yalnız authenticated; anon için politika YOK) ------------------------------------
drop policy if exists cizim_ses_paket_oku on storage.objects;
create policy cizim_ses_paket_oku on storage.objects
  for select to authenticated
  using (bucket_id = 'cizim-ses-paket'
         and public.cizim_ses_erisim(replace((storage.foldername(name))[1], '__', '/')));

-- 4) GÖÇ İÇİ ÖZ-SINAV (biri tutmazsa göç GERİ ALINIR) ---------------------------------------------------
do $$
declare v_kgk uuid; v_ok boolean; v_soru text := 'kgk-t2-ky-g4-cokzor/kp-03';
begin
  if (select public from storage.buckets where id = 'cizim-ses-paket') then raise exception 'SES_KASA: kova herkese açık'; end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'cizim_ses_paket_oku')
    then raise exception 'SES_KASA: okuma politikası yok'; end if;
  if exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'cizim_ses_paket_oku'
             and ('anon' = any(roles) or 'public' = any(roles))) then raise exception 'SES_KASA: politika anon/public okutuyor'; end if;
  if exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and cmd in ('INSERT','UPDATE','DELETE','ALL')
             and coalesce(qual, '') || coalesce(with_check, '') like '%cizim-ses-paket%') then raise exception 'SES_KASA: yazma politikası var'; end if;
  if has_function_privilege('anon', 'public.cizim_ses_erisim(text)', 'execute') then raise exception 'SES_KASA: anon işlevi çağırabiliyor'; end if;
  if not exists (select 1 from public.paket_soru where id = v_soru) then raise exception 'SES_KASA: sınav sorusu % kasada yok', v_soru; end if;
  -- (a) oturumsuz: hayır
  perform set_config('request.jwt.claims', '', true);
  if public.cizim_ses_erisim(v_soru) then raise exception 'SES_KASA: oturumsuz erişim EVET döndü'; end if;
  -- (b) paketsiz (uydurma kimlik): hayır
  perform set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000c1a0","role":"authenticated"}', true);
  if public.cizim_ses_erisim(v_soru) then raise exception 'SES_KASA: paketsiz kimlik EVET aldı'; end if;
  -- (c) KGK paketli gerçek üye (varsa): evet — kural kasa_soru_getir ile aynı mı
  select pu.user_id into v_kgk from public.paket_uyeler pu, public.paket_soru s
   where s.id = v_soru and (pu.bitis is null or pu.bitis >= current_date)
     and (pu.dersler is null or s.ders = any(pu.dersler))
     and lower(trim(coalesce(pu.paket, ''))) in ('kgk', 'yeterlilik-kgk', 'tam', 'kurucu') limit 1;
  if v_kgk is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', v_kgk, 'role', 'authenticated')::text, true);
    v_ok := public.cizim_ses_erisim(v_soru);
    if not v_ok then raise exception 'SES_KASA: KGK paketli üye HAYIR aldı'; end if;
    if v_ok is distinct from (select public.paket_erisim_var(s.sinav, s.ders) from public.paket_soru s where s.id = v_soru)
      then raise exception 'SES_KASA: kural kasa ile ayrıştı'; end if;
    raise notice 'SES_KASA öz-sınav: oturumsuz HAYIR · paketsiz HAYIR · KGK paketli EVET';
  else
    raise notice 'SES_KASA öz-sınav: oturumsuz HAYIR · paketsiz HAYIR · KGK paketli üye YOK (EVET yönü ÖLÇÜLMEDİ)';
  end if;
  perform set_config('request.jwt.claims', '', true);
end $$;
