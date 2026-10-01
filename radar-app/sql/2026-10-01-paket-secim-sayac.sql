-- ============================================================================
--  PAKET SEÇİM SAYACI — "En çok seçilen" etiketi (01.10.2026, Cem "1.2.3 yap", madde 2)
--
--  Etiket TAHMİNLE konmaz (Ticari Reklam ve HTU Yön. Ek A-7: gerçeğe aykırı popülerlik
--  iddiası). Sayfa (fiyat-motoru.js enCokSecilen) bu fonksiyondan yalnız paket başına
--  ÖDENMİŞ sipariş sayısını okur; sınavda >= 30 ödeme yoksa ya da birinci tek başına
--  önde değilse etiket hiç çizilmez.
--
--  Sayılan:  siparisler      durum = 'odendi'
--            magaza_siparis  durum in ('verildi','tuketildi')
--  (kurucu_sayac ile AYNI tanım — iki sayı birbirini tutmalı.)
--
--  Dönen: yalnız (paket, satilan) — kişi verisi YOK. anon çağırabilir.
--  DDL yok, tablo yok, FK yok → PostgREST kesinti tipi değil (14.09 dersi). Cem, SQL Editor.
-- ============================================================================
create or replace function public.paket_secim_sayac()
returns table (paket text, satilan integer)
language sql
stable
security definer
set search_path = public
as $$
  with odenen as (
    select s.paket from public.siparisler s where s.durum = 'odendi'
    union all
    -- 02.10 DÜZELTME: magaza_siparis.paket SATIN ALINAN ürün değil, paket_uyeler'e yazılan BİRLEŞİK
    -- paket (magaza-dogrula.ts hakKarari: 1 dersi olan 1 ders daha alırsa 'yeterlilik-2' yazılır).
    -- Seçim sayımı alınan ürünü saymalı → urun kimliğinden eşlenir (URUNLER: yeterlilik_1 → yeterlilik-1).
    select case when m.urun ~ '^(sgs|yeterlilik_[1-4]|yeterlilik_tum)$' then replace(m.urun, '_', '-') else m.paket end
      from public.magaza_siparis m where m.durum in ('verildi','tuketildi')
  )
  select o.paket, count(*)::int
    from odenen o
   where o.paket is not null
   group by o.paket;
$$;

revoke all on function public.paket_secim_sayac() from public;
grant execute on function public.paket_secim_sayac() to anon, authenticated;

-- ----------------------------------------------------------------------------
--  DOĞRULAMA (basınca):
--   a) select * from public.paket_secim_sayac();    -- paket | satilan (0 sipariş → 0 satır)
--   b) yeterlilik-% satırlarının toplamı = kurucu_sayac() 'yeterlilik' satırı (yeterlilik-kgk hariç)
--   c) anon: curl -X POST <SB>/rest/v1/rpc/paket_secim_sayac -H "apikey: <yayın anahtarı>" → 200
-- ----------------------------------------------------------------------------
