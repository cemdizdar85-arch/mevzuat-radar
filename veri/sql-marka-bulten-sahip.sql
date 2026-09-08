-- ============================================================================
--  MARKA BÜLTENİ — UNVANLA ARAMA (SAHİP) İNDEKSİ + FONKSİYON v3   (08.09.2026)
--
--  Cem: "1.2.3 üçünü de yap" → 3 = marka_bulten_sahip() ekrana bağlansın.
--  08.09 06:30: Cem "sen basabilirsin" → GM Cem'in Chrome'undaki SQL Editor'den
--  bastı (v2), canlı ölçtü, v3'e çıkardı (aşağıda).
--
--  ÖLÇÜLEN KUSUR 1 (08.09, 799.146 kayıt / 105 bülten):
--    marka_bulten_sahip('EGE SERAMİK')  → 57014 statement timeout (3,5 sn)
--    marka_bulten_sahip('ARÇELİK')      → 57014
--  Sebep: fonksiyon `sahip_norm like '%…%'` yapıyor; mevcut ix_mb_sahip DÜZ
--  btree ve ortadan eşleşmeye yaramıyor → her arama tam tablo taraması.
--  → trigram GIN indeksi (ix_mb_sahipnorm). v2 basıldıktan sonra: EGE SERAMİK
--    0,7 sn, ARÇELİK 0,6 sn, DİZDAR DENETİM 0,17 sn.
--
--  ÖLÇÜLEN KUSUR 2: (731) alanı sahip + ADRES. "EGE" araması adresi "EGE MAH."
--  olan herkesi getiriyordu. Sahip alanı "8010422-MEF SERAMİK … (TR) adres"
--  biçiminde: kişi no + '-' + AD + ' (ÜLKE) ' + adres → süzgeç yalnız ADA bakar.
--
--  ÖLÇÜLEN KUSUR 3 (v2 basıldıktan sonra): boşluksuz normalizasyonda
--  "ARÇELİK" → "hezarCELİKkapı" içinde geçti: HEZAR ÇELİK KAPI geldi; "EGE" →
--  "DEĞER" (d-e-g-e-r) içinde geçti. Alt dize eşleşmesi unvanda YANLIŞ.
--  → v3: SÖZCÜK BAŞI eşleşme. marka_norm_sozcuk() boşlukları korur
--    ("ege seramik sanayi"), eşleşme " ege seramik" ile yapılır: "hezar celik"
--    ✗, "arcelik anonim" ✓, "ege vitrifiye" ✗, "ege seramik san ve tic" ✓.
--    İndeks daraltması hâlâ boşluksuz trigram ile (hızlı), doğruluk sözcükle.
--
--  İ TUZAĞI: lower('İ') bazı yerelde 'i'+U+0307 verir; boşluklu sürümde o
--  işaret boşluğa dönüşür ve "d i zdar" olur. Bu yüzden translate lower'dan
--  ÖNCE koşar (büyük harfler de haritada).
--
--  GÜVENLİK: değişmedi — tablo dışarı kapalı, SECURITY DEFINER, tavan 500.
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

-- Boşluklu normalizasyon: harf haritası ÖNCE (İ tuzağı), sonra lower, sonra
-- harf/rakam dışı her şey tek boşluk.
create or replace function public.marka_norm_sozcuk(p text)
returns text language sql immutable as $$
  select trim(regexp_replace(
           lower(translate(coalesce(p,''),
                 'ÇĞIİÖŞÜÂÎÛçğıöşüâîû',
                 'CGIIOSUAIUcgiosuaiu')),
           '[^a-z0-9]+', ' ', 'g'));
$$;

drop function if exists public.marka_bulten_sahip(text, int);

create or replace function public.marka_bulten_sahip(p_unvan text, p_tavan int default 200)
returns table (basvuru_no text, yayin_tarihi date, basvuru_tarihi date,
               ad text, sinif int[], itiraz_son date, sahip text)
language sql security definer set search_path = public, extensions as $$
  with h as (select public.marka_norm(p_unvan) as n,
                    public.marka_norm_sozcuk(p_unvan) as s)
  select b.basvuru_no, b.yayin_tarihi, b.basvuru_tarihi, b.ad, b.sinif, b.itiraz_son,
         -- "8010422-AD SOYAD (TR) adres" -> "AD SOYAD"
         regexp_replace(split_part(coalesce(b.sahip,''), ' (', 1), '^\s*\d+\s*-\s*', '') as sahip
    from public.marka_bulten b, h
   where h.n <> ''
     and length(h.n) >= 3
     and b.sahip_norm like '%' || h.n || '%'                       -- trigram GIN ile daraltma
     and (' ' || public.marka_norm_sozcuk(split_part(coalesce(b.sahip,''), ' (', 1)) || ' ')
         like '% ' || h.s || '%'                                    -- yalniz AD, SOZCUK BASI
   order by b.yayin_tarihi desc, b.basvuru_no desc
   limit least(greatest(p_tavan,1), 500);
$$;

revoke all on function public.marka_bulten_sahip(text,int) from public;
grant execute on function public.marka_bulten_sahip(text,int) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- TEYİT (aynı pencerede):
--   select sahip from public.marka_bulten_sahip('ARÇELİK', 500) where sahip ilike '%hezar%';  -- 0 satır
--   select count(*) from public.marka_bulten_sahip('EGE SERAMİK', 500);                      -- < 1 sn
-- Canlı uçtan (servis anahtarı gerekmez):
--   curl -X POST https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/rpc/marka_bulten_sahip \
--     -H "apikey: <acik anahtar>" -H "Content-Type: application/json" \
--     -d '{"p_unvan":"ARÇELİK","p_tavan":5}'
--   Beklenen: 200 + satırlarda "sahip" alanı var, HEZAR yok. 57014 → indeks basılmamış.
-- ---------------------------------------------------------------------------
