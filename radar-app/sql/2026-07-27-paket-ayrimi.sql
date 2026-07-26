-- 27.07.2026 — PAKET AYRIMI (Cem/UWorld modeli): SGS paketi yalniz SGS sorularini,
-- Yeterlilik paketi yalniz SMMM sorularini gorur; 'tam' (veya NULL) ikisini gorur.
-- Kilit VERITABANINDA (RLS): paket-disi satirlar uyeye HIC gonderilmez.
-- Supabase SQL Editor'de TEK BLOK halinde calistir:

-- 1) uye kendi paket kaydini okuyabilsin (UI paket bilgisini cekiyor)
drop policy if exists "uye kendi paketini okur" on paket_uyeler;
create policy "uye kendi paketini okur" on paket_uyeler
  for select using (auth.uid() = user_id);

-- 2) soru_havuzu okuma politikasi paket-duyarli hale gelir
drop policy if exists "paketli uye okur" on soru_havuzu;
create policy "paketli uye okur" on soru_havuzu
  for select using (
    exists (
      select 1 from paket_uyeler pu
      where pu.user_id = auth.uid()
        and pu.bitis >= current_date
        and (
          pu.paket is null or lower(pu.paket) = 'tam'
          or (lower(pu.paket) = 'sgs'        and soru_havuzu.sinav = 'SGS')
          or (lower(pu.paket) = 'yeterlilik' and soru_havuzu.sinav = 'SMMM')
        )
    )
  );

-- 3) Cem'in hesabi TAM paket olsun (her seyi sayabilsin):
update paket_uyeler set paket = 'tam'
 where user_id = 'b158934b-8f7e-417d-96a5-4baad6b9158e';
