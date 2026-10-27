-- ============================================================================
--  GEÇENE KADAR TETİKTE  ·  27.10.2026 (site kolu)
--
--  CEM 27.10 akşam: "ful paket 600 tl indirim birde sadece soru alana 999 tl" · "%50 bitirme indirimi yalnız Tam Paket
--  alanlara olsun". Kampanya koşulları: kampanya-son-20-gun.html.
--
--  NE YAPAR:
--   1) SGS erken kayıt indirimi 400 → 600 TL (1 Kasım 2026 23:59 TR'ye kadar). İndirim elçi altyapısında paket başına
--      (elci_indirim) olduğu için ERKEN400/INSTA400/GOOGLE400/TELEGRAM400 ve elçilerin kendi kodları da 600 verir.
--      Yeni kanal kodları ERKEN600 · INSTA600 · GOOGLE600 · TELEGRAM600 (ERKEN400 satırının kopyası, hesap bağı yok).
--      1 Kasım 23:59'da .github/workflows/erken-kayit-kapat.yml sekiz kanal kodunu kapatır ve sgs indirimini 400'e
--      (elçi sözleşmesi Madde 5 tutarı) geri yazar.
--   2) YENİ PAKET son20-sgs ("Sadece 7 Deneme", 999 TL KDV dahil). Kimlik bilerek 'sgs' ile BAŞLAMAZ: kasa erişimi
--      (paket_erisim_var: 'sgs' / 'sgs-%'), _paket_sinavi (^sgs) ve sitedeki paketSinavlari ('sgs-' öneki) sgs-öneki
--      gördüğü her paketi bütün SGS bankasına açar; 999 TL'ye bütün banka açılmasın. elci_indirim satırı YOK → elçi /
--      erken kayıt kodu bu pakete işlemez (siparis_elci_damga kodu düşürür). Kartla tutar: iyzico-odeme.ts paketFiyat.
--   3) _paket_kapsar yeniden: paket_uyeler kişi başına TEK satır, _siparis_isle yeni paketi eskisinin ÜSTÜNE yazar.
--      son20-sgs siparişi, açık başka paketi olan hesapta PAKET_ZATEN_ACIK ile durur (Tam Paket'i 7 Deneme'ye düşürmesin;
--      Yeterlilik/KGK üyeliğini silmesin). Tersi serbest: son20-sgs → sgs yükseltmesi eskisi gibi üstüne yazar.
--
--  🚫 GÖRMEZ: Son 20 Gün sayfasının son20-sgs üyesine denemeleri açması (sayfa 1 Kasım'dan önce kurulur; kapı:
--     arac/fiyat-urun-kapisi.js FU-ONSATIS 1 Kasım'dan sonra eşleme yoksa KIRMIZI) · yükseltmede ödenen 999'un düşülmesi
--     (kampanya sayfasında yazılı, elle) · mobil mağaza (ürün yok) · açık Yeterlilik paketi olan kişinin 7 Deneme
--     alamaması (mesaj "zaten açık" der; ayrı iş).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (sipariş/üye satırları geri alınır).
--  GERİ ALMA: update elci_indirim set indirim_tl = 400 where paket = 'sgs'; update elciler set aktif = false where kod in
--     ('ERKEN600','INSTA600','GOOGLE600','TELEGRAM600'); _paket_kapsar 2026-10-21-cift-odeme-kapisi.sql gövdesiyle yeniden.
-- ============================================================================

-- 1) erken kayıt 600
update public.elci_indirim set indirim_tl = 600 where paket = 'sgs';

insert into public.elciler (kod, ad_soyad, instagram, email, aktif, baslangic_kademe, ozel_anlasma, not_)
select y.kod, e.ad_soyad, e.instagram, e.email, true, e.baslangic_kademe, e.ozel_anlasma,
       'Geçene Kadar Tetikte erken kayıt kanal kodu (27.10.2026, 1 Kasım 23:59 TR kapanır; ' || y.kanal || ')'
  from public.elciler e
 cross join (values ('ERKEN600', 'genel'), ('INSTA600', 'instagram'), ('GOOGLE600', 'google'), ('TELEGRAM600', 'telegram')) as y(kod, kanal)
 where e.kod = 'ERKEN400'
on conflict (kod) do update set aktif = true;

-- 3) 7 Deneme başka açık paketin üstüne yazılmaz
create or replace function public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[])
returns boolean language plpgsql immutable as $$
declare v text := lower(btrim(coalesce(p_var, ''))); s text := public._paket_sinavi(p_yeni);
begin
  if lower(btrim(coalesce(p_yeni, ''))) = 'son20-sgs' then                          -- 27.10 Geçene Kadar Tetikte
    return v = 'son20-sgs' or v in ('tam', 'kurucu') or public._paket_sinavi(v) is not null;
  end if;
  if v in ('tam', 'kurucu') then return true; end if;
  if s is null or public._paket_sinavi(v) is distinct from s then return false; end if;
  if s = 'sgs' then return true; end if;
  if coalesce(array_length(p_var_ders, 1), 0) = 0 then return true; end if;        -- ders listesiz = tümü
  if coalesce(array_length(p_yeni_ders, 1), 0) = 0 then return false; end if;      -- tüm pakete yükseltme
  return p_yeni_ders <@ p_var_ders;                                                 -- yeni ders varsa serbest
end $$;

-- GÖÇ İÇİ ÖZ-SINAV (1 ve 2 kalıcıdır, ölçülür; 3'ün sipariş/üye satırları geri alınır)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e2701';
  n int := 0; v text; k text;
begin
  -- 1) kodlar
  foreach k in array array['ERKEN400','INSTA400','GOOGLE400','TELEGRAM400','ERKEN600','INSTA600','GOOGLE600','TELEGRAM600'] loop
    if public.elci_kodu_kontrol(k, 'sgs') <> 600 then raise exception 'OLCU: % sgs 600 vermiyor (%)', k, public.elci_kodu_kontrol(k, 'sgs'); end if;
    if public.elci_kodu_kontrol(k, 'son20-sgs') <> 0 then raise exception 'OLCU: % 7 Deneme paketine indirim veriyor', k; end if;
    n := n + 2;
  end loop;
  if public.elci_kodu_kontrol('YOKBOYLEKOD', 'sgs') <> 0 then raise exception 'OLCU: sahte kod indirim aldi'; end if;
  if public.elci_kodu_kontrol('ERKEN600', 'yeterlilik-tum') <> (select indirim_tl from public.elci_indirim where paket = 'yeterlilik-tum') then
    raise exception 'OLCU: yeterlilik-tum indirimi degisti'; end if;
  n := n + 2;

  -- 2) kapsama tablosu (saf fonksiyon)
  if not public._paket_kapsar('sgs', null, 'son20-sgs', null) then raise exception 'OLCU: sgs uyesi 7 Deneme alabiliyor'; end if;
  if not public._paket_kapsar('tam', null, 'son20-sgs', null) then raise exception 'OLCU: tam uyesi 7 Deneme alabiliyor'; end if;
  if not public._paket_kapsar('yeterlilik-2', array['Denetim'], 'son20-sgs', null) then raise exception 'OLCU: yeterlilik uyeligi 7 Deneme ile silinir'; end if;
  if not public._paket_kapsar('son20-sgs', null, 'son20-sgs', null) then raise exception 'OLCU: 7 Deneme iki kez alinabiliyor'; end if;
  if public._paket_kapsar('son20-sgs', null, 'sgs', null) then raise exception 'OLCU: 7 Deneme uyesi Tam Pakete yukselemiyor'; end if;
  if public._paket_kapsar('son20-sgs', null, 'yeterlilik-tum', null) then raise exception 'OLCU: 7 Deneme yeterliligi kapsiyor'; end if;
  if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: sgs-sgs gerileme'; end if;
  if public._paket_kapsar('yeterlilik-2', array['Denetim'], 'yeterlilik-3', array['Denetim','Vergi','Hukuk']) then raise exception 'OLCU: ders yukseltme gerileme'; end if;
  if public._paket_sinavi('son20-sgs') is not null then raise exception 'OLCU: son20-sgs bir sinava eslendi (banka acilir)'; end if;
  n := n + 9;

  -- 3) uçtan uca: 7 Deneme siparişi bağlanır, kasa SGS bankasını AÇMAZ; sgs üyesine 7 Deneme siparişi yazılmaz
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20-a@tetikte.invalid', now(), now());
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, elci_kodu)
      values ('TT-20261027-S201', 'son20-sgs', 999, 'Olcu Bir', 'olcu-s20-a@tetikte.invalid', 'havale', 'odeme_bekliyor', 'ERKEN600');
    if (select indirim_tl from public.siparisler where siparis_no = 'TT-20261027-S201') <> 0
       or (select elci_kodu from public.siparisler where siparis_no = 'TT-20261027-S201') is not null then
      raise exception 'OLCU: 7 Deneme siparisine kod islendi'; end if;
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261027-S201';
    v := public._siparis_isle((select id from public.siparisler where siparis_no = 'TT-20261027-S201'), a, 'olcu');
    if v <> 'ACILDI' then raise exception 'OLCU: 7 Deneme paketi acilmadi (%)', v; end if;
    if (select paket from public.paket_uyeler where user_id = a) <> 'son20-sgs' then raise exception 'OLCU: paket_uyeler son20-sgs degil'; end if;
    n := n + 3;
    -- yükseltme: aynı kişi Tam Paket (sgs) alabilir, üstüne yazılır
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
      values ('TT-20261027-S202', 'sgs', 2988, 'Olcu Bir', 'olcu-s20-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261027-S202';
    v := public._siparis_isle((select id from public.siparisler where siparis_no = 'TT-20261027-S202'), a, 'olcu');
    if (select paket from public.paket_uyeler where user_id = a) <> 'sgs' then raise exception 'OLCU: yukseltme yazilmadi (%)', v; end if;
    n := n + 1;
    -- artık sgs üyesi: 7 Deneme siparişi yazılmaz
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
        values ('TT-20261027-S203', 'son20-sgs', 999, 'Olcu Bir', 'olcu-s20-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
      raise exception 'OLCU: sgs uyesine 7 Deneme siparisi yazildi';
    exception when others then if sqlerrm not like '%PAKET_ZATEN_ACIK%' then raise; end if; end;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-s20-%@tetikte.invalid')
     or exists (select 1 from public.siparisler where siparis_no like 'TT-20261027-S20%') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'GECENE KADAR TETIKTE OZ-SINAV: % vaka TAMAM', n;
end $$;
