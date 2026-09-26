-- ============================================================================
-- CEVAP KAYDI AÇILIŞ ÖNCESİ TEMİZLİĞİ (26.09.2026, Cem "3 yap") — BASILDI
--
-- NEDEN: soru ekranındaki akran yüzdesi ("N adayın %X'i senin gibi B dedi", rpc sik_yuzdesi) cevap_kayit'tan
-- beslenir. Site "yakında" perdesiyle kapalı, uygulama yalnız dahili testte → tablodaki her satır DENEME cevabıydı
-- (GM'nin 26.09 otomatik telefon çekimleri, Cem'in ve öteki oturumların denemeleri). Sahte kalabalık göstermek
-- hem yanıltıcı hem reklam kuralına aykırı.
--
-- ÖLÇÜM SIRASI (26.09, Cem SQL Editor):
--   1) Dar şart denemesi (tarih + sn<=3 + boş oturum + 60 vitrin sorusu) → 0 satır. Sebep: oturum damgası HİÇBİR
--      satırda boş değil; çekimler sayfa açıldıktan 3-6 sn sonra tıklıyordu. Saniyeye göre ayırmak mümkün değil.
--   2) Bugünün dağılımı (sn × oturum) → cevaplar 13:30–23:00 TR'ye yayılmış, birden çok kaynaktan.
--   3) Gün × kaynak (sgs-% / smmm-%) → 07.09'dan beri günde 2–43, hepsi 'kaydir-coz' — gerçek trafik izi yok.
--   Karar (GM, Cem onayıyla): açılış öncesi TÜM satırlar kilitli yedeğe, asıl tablo boşaltılır.
--
-- SONUÇ: yedeklenen 381 · kalan 0.
-- Dış ölçüm (26.09, açık anahtar): anon GET cevap_kayit_yedek_20260926 → 401/42501 · rpc sik_yuzdesi → 200 []
--   · anon GET cevap_kayit → 401 · dokumanlar 200.
-- GERİ ALMA (gerekirse): insert into public.cevap_kayit select * from public.cevap_kayit_yedek_20260926;
-- YEDEK: açılıştan ~1 ay sonra silinebilir (drop table public.cevap_kayit_yedek_20260926;).
-- ÖNLEM: GM'nin çekim düzeneği (scratchpad cek-magaza.js) artık cevap_kayit / olay_say isteği GÖNDERMEZ.
-- ============================================================================

begin;

create table public.cevap_kayit_yedek_20260926 as
  select * from public.cevap_kayit
   where olusturma < '2026-09-27 12:00:00+03';

alter table public.cevap_kayit_yedek_20260926 enable row level security;
revoke all on public.cevap_kayit_yedek_20260926 from anon, authenticated;

delete from public.cevap_kayit
 where olusturma < '2026-09-27 12:00:00+03';

select (select count(*) from public.cevap_kayit_yedek_20260926) as yedeklenen,
       (select count(*) from public.cevap_kayit) as kalan;

commit;
