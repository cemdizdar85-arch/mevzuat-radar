-- ============================================================================
-- PAKET ÖLÇÜMÜ 2 (03.11.2026, site kolu). ŞEMA DEĞİŞTİRMEZ, YAZMAZ. Günlüğe kişi verisi basılmaz (yalnız paket kodu + sayı).
-- 2026-11-03-paket-olcum.sql "ders eksik" 1 sipariş buldu; 2026-11-03-paket-koruma.sql onarımı (yalnız yeterlilik-[1-4]
-- siparişi + yeterlilik-[1-7] paketi) onu görmedi (0/0/0). Bu ölçüm o kaydın türünü yazar: sipariş paketi · hesap paketi ·
-- seçilen ders sayısı · eksik ders sayısı · eksik ders adları KGK/Yeterlilik ders listesinde mi · hesapta hediye kaydı var mı ·
-- e-postaya ödenmiş sipariş sayısı · sipariş hesaba bağlı mı.
-- ============================================================================
do $$
declare x record;
begin
  for x in
    with sip as (
      select s.id, s.paket, s.secilen_dersler, s.bagli_kullanici is not null as bagli, lower(s.email) as ep,
             coalesce(s.bagli_kullanici, (select u.id from auth.users u where lower(u.email) = lower(s.email) limit 1)) as uid
        from public.siparisler s
       where s.durum = 'odendi' and coalesce(s.paket_bitis, current_date) >= current_date
         and coalesce(array_length(s.secilen_dersler, 1), 0) > 0 )
    select sip.paket as spaket, p.paket as upaket, array_length(sip.secilen_dersler, 1) as secilen,
           (select count(*) from unnest(sip.secilen_dersler) d where not (d = any (p.dersler))) as eksik,
           array_length(p.dersler, 1) as hesap_ders,
           (select count(*) from public.paket_hediye h where h.user_id = sip.uid) as hediye,
           (select count(*) from public.siparisler s2 where lower(s2.email) = sip.ep and s2.durum = 'odendi') as odenmis,
           sip.bagli
      from sip join public.paket_uyeler p on p.user_id = sip.uid
     where p.bitis >= current_date and p.dersler is not null and not (sip.secilen_dersler <@ p.dersler)
  loop
    raise notice 'OLCU2 ders-eksik: siparis % · hesap % · secilen % · eksik % · hesapta ders % · hediye kaydi % · odenmis siparis % · bagli %',
      x.spaket, x.upaket, x.secilen, x.eksik, x.hesap_ders, x.hediye, x.odenmis, x.bagli;
  end loop;
end $$;
