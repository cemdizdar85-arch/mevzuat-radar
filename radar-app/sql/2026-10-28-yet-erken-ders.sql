-- ============================================================================
--  YETERLİLİK ERKEN KAYIT — DERS DERS 120 TL  ·  28.10.2026 (site kolu)
--
--  CEM 28.10: "DERS DERS TAM FİYATIN ALTINDA KALDI ÖRNEK 4 DERS BUNLARI AYARLAYALIM" → seçim "Ders başı 120 TL indir".
--  Erken kayıtta tüm dersler 2.868 TL iken 4 ders 2.988 TL'ydi (8 dersten pahalı). 7 Kasım 23:59'a kadar KDV dahil:
--    1 ders 1.188 → 1.068 · 2 ders 1.908 → 1.668 · 3 ders 2.508 → 2.148 · 4 ders 2.988 → 2.508 · tüm 2.868.
--  NE YAPAR: elci_indirim yeterlilik-1..4 = 120/240/360/480 (önce 50/100/150/200). Site ERKENYET600'ü bu paketlerde de
--  kendiliğinden uygular (fiyat-motoru.js erkenKod). Kapanış: .github/workflows/erken-kayit-yet-kapat.yml 50/100/150/200'e
--  geri yazar.
--  🚫 GÖRMEZ: bu sürede elçilerin kendi kodları da aynı tutarı verir (elci_indirim paket başına; SGS 600'de de böyleydi) ·
--     elçi ders komisyonu değişmez.
--  GERİ ALMA: update elci_indirim set indirim_tl = 50 * substring(paket from 12)::int where paket ~ '^yeterlilik-[1-4]$';
-- ============================================================================

update public.elci_indirim set indirim_tl = 120 * substring(paket from 12)::int where paket ~ '^yeterlilik-[1-4]$';

do $$
declare n int := 0; i int;
begin
  for i in 1..4 loop
    if public.elci_kodu_kontrol('ERKENYET600', 'yeterlilik-' || i) <> 120 * i then
      raise exception 'OLCU: ERKENYET600 yeterlilik-% beklenen % degil (%)', i, 120 * i, public.elci_kodu_kontrol('ERKENYET600', 'yeterlilik-' || i); end if;
    n := n + 1;
  end loop;
  if (select count(*) from public.elci_indirim where paket ~ '^yeterlilik-[1-4]$') <> 4 then raise exception 'OLCU: ders satiri eksik'; end if;
  if public.elci_kodu_kontrol('ERKENYET600', 'yeterlilik-tum') <> 600 then raise exception 'OLCU: tum dersler 600 bozuldu'; end if;
  if (select indirim_tl from public.elci_indirim where paket = 'sgs') <> 600 then raise exception 'OLCU: sgs erken kaydi bozuldu'; end if;
  if public.elci_kodu_kontrol('ERKENYET600', 'son20-sgs') <> 0 then raise exception 'OLCU: 7 Deneme paketine indirim'; end if;
  n := n + 4;
  raise notice 'YETERLILIK ERKEN DERS OZ-SINAV: % vaka TAMAM', n;
end $$;
