-- ============================================================================
--  KURUCU SAYACI — "Kalan kurucu yeri: N" (27.09.2026, Cem "tamam bu fiyatları uygula")
--
--  Karar: SGS ve Yeterlilik'te ilk 1.000 ÖDEYEN kurucu (sınav başına ayrı) kurucu fiyatını
--  öder (SGS 2.995 / Yeterlilik tüm 3.490, KDV dahil); sonrası liste (5.990 / 6.990).
--  Ticari Reklam ve HTU Yön. m.13/9 + m.14/1: adet sınırı açıkça yazılır; Ek A-7: sahte
--  kıtlık yasak → sayaç YALNIZ gerçek ödeme kayıtlarından sayar.
--
--  Sayılan:  siparisler      durum = 'odendi'                (havale/EFT, elle onaylanan)
--            magaza_siparis  durum in ('verildi','tuketildi') (Google Play / App Store)
--  Sayılmayan: ücretsiz üye, elçiye verilen ücretsiz erişim, iptal/iade, bekleyen sipariş.
--  Eşleme: paket 'sgs' → sgs · 'yeterlilik-%' (yeterlilik-kgk HARİÇ) → yeterlilik.
--
--  Dönen: yalnız (sinav, satilan) — kişi verisi YOK. anon çağırabilir (fiyat sayfası).
--  Sayfa (fiyat-motoru.js kurucuKalan) fonksiyon yoksa satırı HİÇ çizmez; bu dosya
--  basılmadan sitede sayaç görünmez, fiyatlar yine doğru çalışır.
--
--  DDL yok, tablo yok, FK yok → PostgREST kesinti tipi değil (14.09 dersi). Cem, SQL Editor.
-- ============================================================================
create or replace function public.kurucu_sayac()
returns table (sinav text, satilan integer)
language sql
stable
security definer
set search_path = public
as $$
  with odenen as (
    select paket from public.siparisler where durum = 'odendi'
    union all
    select paket from public.magaza_siparis where durum in ('verildi','tuketildi') and paket is not null
  ), eslenen as (
    select case
             when paket = 'sgs' then 'sgs'
             when paket like 'yeterlilik-%' and paket <> 'yeterlilik-kgk' then 'yeterlilik'
           end as sinav
      from odenen
  )
  select s.sinav, coalesce((select count(*)::int from eslenen e where e.sinav = s.sinav), 0)
    from (values ('sgs'), ('yeterlilik')) as s(sinav);
$$;

revoke all on function public.kurucu_sayac() from public;
grant execute on function public.kurucu_sayac() to anon, authenticated;

-- ----------------------------------------------------------------------------
--  DOĞRULAMA (basınca):
--   a) select * from public.kurucu_sayac();          -- 2 satır: sgs | N · yeterlilik | M
--   b) tarayıcıda tetikte.com/fiyat.html → Staja Başlama kartında "Kalan kurucu yeri: 1.000 - N"
--   c) anon: curl -X POST <SB>/rest/v1/rpc/kurucu_sayac -H "apikey: <yayın anahtarı>" → 200 + 2 satır
-- ----------------------------------------------------------------------------
