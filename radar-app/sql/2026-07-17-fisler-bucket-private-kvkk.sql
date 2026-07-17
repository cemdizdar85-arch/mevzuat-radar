-- KVKK (17.07.2026): mükellef belgeleri 'fisler' bucket'ı PUBLIC idi — linki bilen
-- herkes indirebiliyordu. PRIVATE yapılır; erişim yalnız süreli imzalı link ile.
-- Client kodu zaten güncellendi (dosya YOLU saklanır, açarken createSignedUrl).
update storage.buckets set public = false where id = 'fisler';

-- Okuma politikası imzalı-link üretimi için gerekli (anon mükellef + authenticated
-- muhasebeci). Public URL kapalı olduğundan koruma, tahmin edilemez yola dayanır.
drop policy if exists fis_read on storage.objects;
create policy fis_read on storage.objects
  for select to anon, authenticated using (bucket_id = 'fisler');

-- doğrulama: public=false görmelisin
select id, public from storage.buckets where id = 'fisler';
