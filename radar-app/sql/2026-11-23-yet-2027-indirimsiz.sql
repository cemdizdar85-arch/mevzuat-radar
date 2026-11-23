-- ============================================================================
--  YETERLİLİK 2027 — ELÇİ İNDİRİMİ VE ANLIK TEKLİF KAPALI  ·  23.11.2026  (site kolu)
--
--  Cem 23.11 ("Yeterlilik 2027'de elçi indirimi ve anlık teklif indirimi eskisi gibi kalsın mı?" sorusuna):
--  "burda kaldıralım şimdilik, girersek haber veririz tekrardan".
--
--  NE YAPAR:
--   1) elci_indirim yeterlilik-1..4 + yeterlilik-tum indirim_tl = 0 (önce ders 50/100/150/200, tüm dersler 400).
--      Satır SİLİNMEZ: elçi kodu siparişe yine damgalanır, sabit_komisyon_tl (elçi ders komisyonu) DEĞİŞMEZ — Cem yalnız
--      indirimi kaldırdı, komisyon için karar vermedi. elci_kodu_kontrol bu paketlerde 0 döner → sayfa indirim göstermez;
--      elci-programi.html indirim listesi (indirim_tl > 0) Yeterlilik'i kendiliğinden düşürür.
--   2) anlik_teklif_ayar sinav='yeterlilik' acik = false → anlik_teklif_al yeni teklif vermez, _anlik_teklif_secenekler boş,
--      siparis_teklif_damga açık ayar bulamaz (verilmiş eski belirteç indirim getirmez). Sayfa: fiyat-motoru.js ANLIK_TEKLIF.acik=false.
--  🚫 GÖRMEZ: özel kod (ozel_kod, Cem'in kişiye verdiği kod) — kapsam dışı, değişmedi · elçi sözleşmesi Madde 5 tablosu (elci.html,
--     sürümlü metin) DEĞİŞMEDİ, Cem "ben söyleyeceğim" · ödenmiş eski siparişler.
--  GERİ ALMA: update elci_indirim set indirim_tl = 50 * substring(paket from 12)::int where paket ~ '^yeterlilik-[1-4]$';
--             update elci_indirim set indirim_tl = 400 where paket = 'yeterlilik-tum';
--             update anlik_teklif_ayar set acik = true where sinav = 'yeterlilik';
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (yalnız okur).
-- ============================================================================

update public.elci_indirim set indirim_tl = 0 where paket ~ '^yeterlilik-([1-4]|tum)$';
update public.anlik_teklif_ayar set acik = false where sinav = 'yeterlilik';

do $$
declare n int := 0; k text; i int;
begin
  if exists (select 1 from public.elci_indirim where paket ~ '^yeterlilik-([1-4]|tum)$' and indirim_tl <> 0) then
    raise exception 'OLCU: yeterlilik elci indirimi sifirlanmadi'; end if;
  n := n + 1;
  if (select count(*) from public.elci_indirim where paket ~ '^yeterlilik-([1-4]|tum)$') <> 5 then
    raise exception 'OLCU: yeterlilik elci satiri eksik (komisyon kaybolur)'; end if;
  n := n + 1;
  if exists (select 1 from public.anlik_teklif_ayar where sinav = 'yeterlilik' and acik) then
    raise exception 'OLCU: yeterlilik anlik teklif acik kaldi'; end if;
  n := n + 1;
  if jsonb_array_length(coalesce(public._anlik_teklif_secenekler('yeterlilik'), '[]'::jsonb)) <> 0 then
    raise exception 'OLCU: teklif secenekleri bos degil'; end if;
  n := n + 1;
  select e.kod into k from public.elciler e where e.aktif limit 1;
  if k is not null then
    foreach i in array array[1, 2, 3, 4] loop
      if public.elci_kodu_kontrol(k, 'yeterlilik-' || i) <> 0 then raise exception 'OLCU: elci kodu yeterlilik-% indirim verdi', i; end if;
    end loop;
    if public.elci_kodu_kontrol(k, 'yeterlilik-tum') <> 0 then raise exception 'OLCU: elci kodu yeterlilik-tum indirim verdi'; end if;
    n := n + 5;
  end if;
  raise notice 'YETERLILIK 2027 INDIRIMSIZ OZ-SINAV: % vaka TAMAM', n;
end $$;
