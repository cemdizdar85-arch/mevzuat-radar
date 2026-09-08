-- ============================================================================
--  MARKA BÜLTENİ — UNVANLA ARAMA (SAHİP) İNDEKSİ + FONKSİYON v2   (08.09.2026)
--
--  Cem: "1.2.3 üçünü de yap" → 3 = marka_bulten_sahip() ekrana bağlansın.
--
--  ÖLÇÜLEN KUSUR (08.09, 799.146 kayıt / 105 bülten):
--    marka_bulten_sahip('EGE SERAMİK')  → 57014 statement timeout (3,5 sn)
--    marka_bulten_sahip('ARÇELİK')      → 57014
--    marka_bulten_sahip('DİZDAR DENETİM') → 57014
--    marka_bulten_sahip('EGE')          → 200, 500 kayıt (tavan hemen dolduğu
--                                          için tarama erken bitiyor; şans)
--  Sebep: fonksiyon `sahip_norm like '%…%'` yapıyor; mevcut ix_mb_sahip DÜZ
--  btree ve ortadan eşleşmeye yaramıyor → her arama tam tablo taraması.
--  ad_norm için 30.08'de trigram (pg_trgm GIN) kuruldu, sahip_norm için
--  unutulmuştu. Ambar 2 milyona giderken bu fonksiyon HİÇ dönmeyecekti.
--
--  İKİNCİ KUSUR: (731) alanı sahip + ADRES. "EGE" araması adresi "EGE MAH."
--  olan herkesi getiriyordu ("sola mahjong" → sahibi Ege ile ilgisiz).
--  Sahip alanı "8010422-MEF SERAMİK … LİMİTED ŞİRKETİ (TR) AKDENİZ MAH. …"
--  biçiminde: kişi no + '-' + AD + ' (ÜLKE) ' + adres. Ad, ' (' işaretine
--  kadar olan kısımdır; süzgeç artık ADA bakar, adres eşleşmesi elenir.
--
--  NE YAPAR:
--   1) sahip_norm üzerine trigram GIN indeksi (ad_norm'dakinin eşi)
--   2) marka_bulten_sahip() v2: indeksle daraltır, sonra yalnız AD kısmında
--      eşleşenleri bırakır; sahibin adını da döndürür (ekranda gösterilir).
--      Dönüş tipi değiştiği için önce DROP (create or replace tip değiştiremez).
--
--  GÜVENLİK: değişmedi — tablo dışarı kapalı, SECURITY DEFINER, tavan 500.
--  BASILMADAN: sayfa "ambar zaman aşımı" der, "başvuru yok" DEMEZ (kör kalma).
-- ============================================================================

do $ix$
declare s text;
begin
  select n.nspname into s
    from pg_extension e join pg_namespace n on n.oid = e.extnamespace
   where e.extname = 'pg_trgm';
  if s is null then raise exception 'pg_trgm kurulu degil - sql-marka-bulten.sql 0. adim basilmamis.'; end if;
  execute format(
    'create index if not exists ix_mb_sahipnorm on public.marka_bulten using gin (sahip_norm %I.gin_trgm_ops)', s);
  raise notice 'pg_trgm semasi: %', s;
end $ix$;

drop function if exists public.marka_bulten_sahip(text, int);

create or replace function public.marka_bulten_sahip(p_unvan text, p_tavan int default 200)
returns table (basvuru_no text, yayin_tarihi date, basvuru_tarihi date,
               ad text, sinif int[], itiraz_son date, sahip text)
language sql security definer set search_path = public, extensions as $$
  with h as (select public.marka_norm(p_unvan) as n)
  select b.basvuru_no, b.yayin_tarihi, b.basvuru_tarihi, b.ad, b.sinif, b.itiraz_son,
         -- "8010422-AD SOYAD (TR) adres" -> "AD SOYAD"
         regexp_replace(split_part(coalesce(b.sahip,''), ' (', 1), '^\s*\d+\s*-\s*', '') as sahip
    from public.marka_bulten b, h
   where h.n <> ''
     and length(h.n) >= 3
     and b.sahip_norm like '%' || h.n || '%'                       -- trigram GIN ile daraltma
     and public.marka_norm(regexp_replace(split_part(coalesce(b.sahip,''), ' (', 1), '^\s*\d+\s*-\s*', ''))
         like '%' || h.n || '%'                                     -- yalniz AD kisminda esleşme
   order by b.yayin_tarihi desc, b.basvuru_no desc
   limit least(greatest(p_tavan,1), 500);
$$;

revoke all on function public.marka_bulten_sahip(text,int) from public;
grant execute on function public.marka_bulten_sahip(text,int) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- TEYİT (aynı pencerede):
--   select count(*) from public.marka_bulten_sahip('EGE SERAMİK', 500);   -- < 1 sn dönmeli
--   select sahip, ad from public.marka_bulten_sahip('EGE', 20);           -- adreste EGE olanlar GELMEMELİ
-- Canlı uçtan (servis anahtarı gerekmez):
--   curl -X POST https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/marka_bulten_sahip \
--     -H "apikey: <acik anahtar>" -H "Content-Type: application/json" \
--     -d '{"p_unvan":"ARÇELİK","p_tavan":5}'
--   Beklenen: 200 + satırlarda "sahip" alanı var. 57014 → indeks basılmamış.
-- ---------------------------------------------------------------------------
