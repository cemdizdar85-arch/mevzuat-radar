-- ⛔ TASLAK - BASILMAZ: elci.html sözleşme Madde 11.1 ("Alıcıların kimlik bilgileri Elçiye verilmez") değişmeden,
--    KOSUL_SURUM yükselip PDF yeniden üretilmeden bu dosya basılırsa panel sözleşmeye aykırı veri gösterir. Cem kararı bekliyor (04.10).
-- ============================================================================
-- ELÇİYE ALICININ BAŞ HARFLERİ — YALNIZ ONAYLA (04.10.2026, Cem: "kişisel verileri KVKK nedeniyle paylaşmamanı,
-- gerekirse sadece baş harf gösterip onay kutusu eklemeyi öneriyorum, bunu yapabilirsin")
--
-- 1) siparisler.elci_ad_izni: ödeme sayfasında elçi kodu girilince çıkan İSTEĞE BAĞLI kutu. Varsayılan false.
--    Mevcut siparisler_ekle politikası sütun kısıtlamaz; yeni boolean anon INSERT'te serbest (biçim kilidi değişmez).
-- 2) elci_satislarim(): giriş yapmış elçinin KENDİ koduyla verilmiş siparişleri - tarih, paket, durum, indirim;
--    bas_harf YALNIZ elci_ad_izni = true olan siparişte ("A. Y."), değilse null. Ad, e-posta, telefon, adres, tutar
--    detayı GİTMEZ. Elçi olmayan çağırırsa boş dizi.
-- GERİ ALMA: drop function public.elci_satislarim(); alter table public.siparisler drop column elci_ad_izni;
-- ============================================================================
alter table public.siparisler add column if not exists elci_ad_izni boolean not null default false;

create or replace function public.elci_satislarim()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare v_kod text;
begin
  if auth.uid() is null then return '[]'::jsonb; end if;
  select kod into v_kod from elciler where user_id = auth.uid();
  if v_kod is null then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'tarih',   s.olusturma::date,
      'paket',   coalesce(s.paket_ad, s.paket),
      'durum',   s.durum,
      'indirim', s.indirim_tl,
      'bas_harf', case when s.elci_ad_izni then (
          select string_agg(upper(left(p.w, 1)) || '.', ' ' order by p.i)
            from (select w, i, count(*) over () as n
                    from unnest(regexp_split_to_array(trim(s.ad_soyad), '\s+')) with ordinality as t(w, i)) p
           where p.i = 1 or p.i = p.n)
        else null end
    ) order by s.olusturma desc)
    from (select * from siparisler where elci_kodu = v_kod order by olusturma desc limit 300) s
  ), '[]'::jsonb);
end
$$;
revoke all on function public.elci_satislarim() from public, anon;
grant execute on function public.elci_satislarim() to authenticated;

-- Ölçü (Success sonrası): select column_name from information_schema.columns
--   where table_name = 'siparisler' and column_name = 'elci_ad_izni';   -- 1 satır
