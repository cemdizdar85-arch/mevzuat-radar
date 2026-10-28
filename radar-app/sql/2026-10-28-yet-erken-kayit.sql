-- ============================================================================
--  YETERLİLİK ERKEN KAYIT 600 TL  ·  28.10.2026 (site kolu)
--
--  CEM 28.10: "Yeterlilik'e şimdilik yalnız erken kayıt indirimi aç: Tüm dersler 3.468 yerine 2.868 TL, kodsuz, 7 Kasım 23:59'a
--  kadar, SGS'deki gibi her yerde aynı rakam. Söz ve Son 20 Gün paketi içerik netleşince."
--
--  NE YAPAR (SGS erken kaydıyla aynı düzen, 2026-10-27-gecene-kadar-tetikte.sql):
--   1) elci_indirim yeterlilik-tum 400 → 600 (7 Kasım 2026 23:59 TR'de .github/workflows/erken-kayit-yet-kapat.yml 400'e geri yazar).
--   2) Kanal kodu ERKENYET600 (ERKEN400 satırının kopyası, hesap bağı yok). Satın almada Yeterlilik tüm dersler seçilip kod
--      kutusu boşsa site bu kodu KENDİLİĞİNDEN uygular (otoKod; ekranda kod adı görünmez). Tutarı sunucu doğrular.
--   Ders ders paketleri (yeterlilik-1..4) değişmez.
--  🚫 GÖRMEZ: ERKENYET600 kodunu elle yazan biri SGS'de de o günkü sgs elçi indirimini alır (1 Kasım'a kadar 600, sonra 400 —
--     elçi kodlarının verdiği tutar; kod ekranda hiç gösterilmez) · kampanya metni (Yeterlilik'e söz/Son 20 Gün yok).
--  GERİ ALMA: update elci_indirim set indirim_tl = 400 where paket = 'yeterlilik-tum'; update elciler set aktif = false where kod = 'ERKENYET600';
-- ============================================================================

update public.elci_indirim set indirim_tl = 600 where paket = 'yeterlilik-tum';

insert into public.elciler (kod, ad_soyad, instagram, email, aktif, baslangic_kademe, ozel_anlasma, not_)
select 'ERKENYET600', e.ad_soyad, e.instagram, e.email, true, e.baslangic_kademe, e.ozel_anlasma,
       'Yeterlilik erken kayıt (28.10.2026, kodsuz otomatik; 7 Kasım 23:59 TR kapanır)'
  from public.elciler e where e.kod = 'ERKEN400'
on conflict (kod) do update set aktif = true;

do $$
declare n int := 0; k text;
begin
  if public.elci_kodu_kontrol('ERKENYET600', 'yeterlilik-tum') <> 600 then
    raise exception 'OLCU: ERKENYET600 yeterlilik-tum 600 vermiyor (%)', public.elci_kodu_kontrol('ERKENYET600', 'yeterlilik-tum'); end if;
  n := n + 1;
  if public.elci_kodu_kontrol('ERKENYET600', 'son20-sgs') <> 0 then raise exception 'OLCU: 7 Deneme paketine indirim'; end if;
  n := n + 1;
  foreach k in array array['yeterlilik-1','yeterlilik-2','yeterlilik-3','yeterlilik-4'] loop
    if public.elci_kodu_kontrol('ERKENYET600', k) is distinct from public.elci_kodu_kontrol('ERKEN400', k) then
      raise exception 'OLCU: % ders paketi indirimi beklenenden farkli', k; end if;
    n := n + 1;
  end loop;
  if (select indirim_tl from public.elci_indirim where paket = 'sgs') <> 600 then raise exception 'OLCU: sgs erken kaydi bozuldu'; end if;
  if public.elci_kodu_kontrol('YOKBOYLEKOD', 'yeterlilik-tum') <> 0 then raise exception 'OLCU: sahte kod indirim aldi'; end if;
  n := n + 2;
  raise notice 'YETERLILIK ERKEN KAYIT OZ-SINAV: % vaka TAMAM', n;
end $$;
