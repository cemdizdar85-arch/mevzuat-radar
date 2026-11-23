-- ============================================================================
--  SİPARİŞ TUTARI KURUŞLU  ·  23.11.2026  (site kolu, SGS 2027 paketi)
--
--  Ölçüldü 23.11 (canlı, anon REST, satır yazılmadı): sgs-2027 siparişi tutar 3585.6 ile
--  'invalid input syntax for type integer: "3585.6"' döndü → siparisler.tutar TAM SAYI. SGS 2027 fiyatı KDV dahil
--  3.585,60 / 8.985,60 (Cem 23.11): bu sütunla sipariş HİÇ alınamazdı. liste_fiyat da aynı (sayfa 8985.6 yazar).
--  kart_odemeleri.tutar zaten numeric(10,2) (2026-10-05-kart-odeme.sql); iyzico-odeme.ts tutarı kuruş farkıyla kıyaslar.
--
--  NE YAPAR: siparisler.tutar ve liste_fiyat → numeric(10,2) (eski tam sayılar aynen korunur). İndirim sütunları
--  (indirim_tl, ozel_kod_tl, anlik_teklif_tl) tam sayı kalır — indirimler tam TL.
--  Bağımlı görünüm (elci_donem_raporu) bu iki sütunu kullanmıyor; kullanan görünüm olsaydı ALTER düşer, tek işlem geri alınır.
--  🚫 GÖRMEZ: tutarı tam sayı değişkene okuyan sayfa/robot (ekranda 3585.6 → yuvarlama) · canlıda depoda olmayan görünüm.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
-- ============================================================================

alter table public.siparisler alter column tutar type numeric(10,2) using tutar::numeric(10,2);
alter table public.siparisler alter column liste_fiyat type numeric(10,2) using liste_fiyat::numeric(10,2);

do $$
declare v numeric; l numeric; n int := 0;
begin
  begin
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, liste_fiyat, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-K7A1', 'sgs-2027', 'SGS 2027 paketi', 3585.60, 8985.60, 'Olcu Kurus', 'olcu-kurus@tetikte.invalid', 'havale', 'odeme_bekliyor', '2027-temmuz');
    select tutar, liste_fiyat into v, l from public.siparisler where siparis_no = 'TT-20261123-K7A1';
    if v <> 3585.60 or l <> 8985.60 then raise exception 'OLCU: kurus kayboldu % %', v, l; end if;
    n := n + 1;
    -- bekleyen sipariş kapısı kuruşlu tutarı da tanır (aynı paket + aynı tutar 24 saat)
    begin
      insert into public.siparisler (siparis_no, paket, paket_ad, tutar, liste_fiyat, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-K7A2', 'sgs-2027', 'SGS 2027 paketi', 3585.60, 8985.60, 'Olcu Kurus', 'olcu-kurus@tetikte.invalid', 'havale', 'odeme_bekliyor', '2027-temmuz');
      raise exception 'OLCU: ikinci bekleyen siparis gecti';
    exception when others then if sqlerrm not like 'BEKLEYEN_SIPARIS%' then raise; end if; end;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-K7A%') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SIPARIS KURUS OZ-SINAV: % vaka TAMAM', n;
end $$;
