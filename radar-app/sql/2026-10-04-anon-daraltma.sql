-- ============================================================================
--  ANON DARALTMA (04.10.2026, Cem "1.2.3 üçünü de yap" — V2 madde 42 + güvenlik testi bulgu 4)
--
--  Ölçüm (04.10, dışarıdan, açık anahtar): firmalar / markalar / mukellefler anon GET → 200 [] .
--  Yani SELECT hakkı anon rolüne VERİLMİŞ; satırları yalnız RLS politikası 0'a indiriyor (tek duvar).
--  Bu üç tabloyu okuyan/yazan sayfalar (radar-app.html, marka-app.html) yalnız GİRİŞTEN SONRA çağırıyor
--  (getSession / onAuthStateChange -> app()); anonim kullanım yok -> anon hakkını kaldırmak işlev bozmaz.
--  Sonuç: anon GET 200 [] yerine 401 olur; politika bir gün yanlış yazılsa da ikinci duvar durur.
--
--  ⛔ BİLEREK YOK: rate_limit_check(text,int,int) anon EXECUTE hakkı. Güvenlik testi kaldırılmasını önerdi
--  ama beş edge fonksiyonu (net-cevap, beyanname-oku, form-al, karne-gonder, meta-olay) hız sınırını ANON
--  anahtarla çağırıyor (04.10 kod okundu). Hak kaldırılırsa net-cevap fail-closed olduğu için TAMAMEN kapanır,
--  form-al fail-open olduğu için sınırsız kalır. Önce edge'ler servis anahtarına geçip deploy edilmeli (ayrı iş).
--
--  Geri alma: grant select on public.<tablo> to anon;  (önceki hâl yalnız SELECT idi; insert/update/delete ölçülmedi)
-- ============================================================================

revoke all on public.firmalar    from anon;
revoke all on public.markalar    from anon;
revoke all on public.mukellefler from anon;

-- Doğrulama (SQL Editor'de aynı çalıştırmada): anon'un bu üç tabloda hakkı kalmamalı -> 0 satır
select table_name, privilege_type
from information_schema.role_table_grants
where grantee = 'anon' and table_schema = 'public'
  and table_name in ('firmalar', 'markalar', 'mukellefler');

-- Politika metinleri (güvenlik testinin "ölçülmedi" maddesi): her biri auth.uid() ile sınırlı olmalı
select tablename, policyname, roles, cmd, qual
from pg_policies
where schemaname = 'public'
  and tablename in ('firmalar', 'markalar', 'mukellefler', 'marka_portfoy', 'destek_takip');
