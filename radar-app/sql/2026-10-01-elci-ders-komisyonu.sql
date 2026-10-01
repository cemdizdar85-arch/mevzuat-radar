-- ============================================================================
--  ELÇİ PROGRAMI — TEK DERS KOMİSYONU  ·  01.10.2026
--
--  KARAR (Cem 01.10 akşam, "150 tl olsun hepsini yapalım"):
--    SMMM Yeterlilik 1–4 derslik paketlerinde elçi koduyla gelen satışa
--    DERS BAŞINA 150 TL komisyon (1 ders 150 · 2 ders 300 · 3 ders 450 · 4 ders 600).
--    - Alıcıya indirim YOK (1 derste 1.190 − 400 indirim − komisyon payımızı yarıya indirirdi).
--    - Kademe sayacına SAYILMAZ: sayılsaydı 1.190'lık satışlarla 10. satışa çıkılıp SGS'de
--      1.000 TL kademesine geçilirdi. Kademe yalnız SGS + Yeterlilik tüm dersler satışlarıyla işler.
--    - Kesinleşme (7 gün), iade, mahsup, ödeme günü (izleyen ayın 8'i) aynı.
--    Sözleşme: sürüm 2026-10-02, Madde 5 + 6.8 (elci.html KOSUL_SURUM).
--
--  ÖNCEKİ DURUM (2026-09-15-elci-programi.sql): 1–4 ders paketinde elci_indirim satırı yoktu →
--  siparis_elci_damga kodu DÜŞÜRÜYORDU; elçi bu satışları hiç göremiyordu.
--
--  NASIL: elci_indirim'e sabit_komisyon_tl kolonu. Satırı olan pakette kod artık düşmez
--  (indirim 0). Sipariş yazılırken tetikleyici komisyonu siparise DAMGALAR
--  (siparisler.elci_sabit_komisyon_tl) — tablo sonradan değişse de geçmiş satış değişmez.
--  Damgalı satış kademe sayımından çıkar, ayrı toplanır.
--
--  ESKİTİR (aynı nesneleri yeniden yazar): 2026-09-15-elci-programi.sql bölüm 6
--  (siparis_elci_damga), 10 (elci_donem_raporu), 12c (elci_panelim). O dosya YENİDEN
--  BASILIRSA bu dosya da ardından yeniden basılmalı, yoksa tek ders komisyonu kaybolur.
--
--  SUPABASE SQL EDITOR'DE BİR KEZ. Tekrar basılması güvenli (if not exists / or replace / on conflict).
--  DDL: düşük trafikte bas; bastıktan sonra satin-al.html açılıyor mu bak.
-- ============================================================================


-- 1) PAKET TABLOSU: ders paketlerinin sabit komisyonu
alter table public.elci_indirim add column if not exists sabit_komisyon_tl integer;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'elci_indirim_sabit_komisyon_aralik') then
    alter table public.elci_indirim add constraint elci_indirim_sabit_komisyon_aralik
      check (sabit_komisyon_tl is null or sabit_komisyon_tl between 0 and 100000);
  end if;
end $$;

insert into public.elci_indirim (paket, indirim_tl, sabit_komisyon_tl) values
  ('yeterlilik-1', 0, 150),
  ('yeterlilik-2', 0, 300),
  ('yeterlilik-3', 0, 450),
  ('yeterlilik-4', 0, 600)
on conflict (paket) do update set indirim_tl = excluded.indirim_tl, sabit_komisyon_tl = excluded.sabit_komisyon_tl;


-- 2) SİPARİŞE DAMGA KOLONU (null = kademeli satış)
alter table public.siparisler add column if not exists elci_sabit_komisyon_tl integer;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_elci_sabit_komisyon_aralik') then
    alter table public.siparisler add constraint siparisler_elci_sabit_komisyon_aralik
      check (elci_sabit_komisyon_tl is null or elci_sabit_komisyon_tl between 0 and 100000);
  end if;
end $$;


-- 3) SİPARİŞ DAMGASI — eskisiyle aynı, + sabit komisyon damgası.
--    Tarayıcının yolladığı elci_sabit_komisyon_tl her durumda EZİLİR.
create or replace function public.siparis_elci_damga()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kod     text;
  v_indirim integer;
  v_sabit   integer;
  v_email   text;
  v_user    uuid;
begin
  new.indirim_tl := 0;
  new.elci_sabit_komisyon_tl := null;
  v_kod := nullif(upper(regexp_replace(coalesce(new.elci_kodu, ''), '[^A-Za-z0-9]', '', 'g')), '');
  if v_kod is null then
    new.elci_kodu := null;
    return new;
  end if;

  select i.indirim_tl, i.sabit_komisyon_tl, e.email, e.user_id into v_indirim, v_sabit, v_email, v_user
    from elciler e
    join elci_indirim i on i.paket = new.paket
   where e.kod = v_kod and e.aktif;

  if v_indirim is null then
    new.elci_kodu := null;
    return new;
  end if;

  if (v_email is not null and lower(v_email) = lower(new.email))
     or (v_user is not null and v_user = auth.uid()) then
    raise exception 'ELCI_KENDI_KODU' using hint = 'Elçi kendi koduyla alım yapamaz.';
  end if;

  new.elci_kodu              := v_kod;
  new.indirim_tl             := v_indirim;
  new.elci_sabit_komisyon_tl := v_sabit;
  return new;
end $$;


-- 4) DÖNEM RAPORU — kademeli sütunlar artık YALNIZ damgasız satışları sayar;
--    ders satışları sona eklenen sütunlarda (view'a yalnız sona sütun eklenebilir).
create or replace view public.elci_donem_raporu as
with sayim as (
  select d.ad as donem, d.baslangic, d.bitis, e.kod, e.ad_soyad, e.instagram, e.baslangic_kademe,
         count(*) filter (where s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now())::int as kesin_satis,
         count(*) filter (where s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now())::int as bekleyen_satis,
         count(*) filter (where s.durum = 'iade')::int                                                    as iade,
         count(*) filter (where s.durum = 'odeme_bekliyor')::int                                          as odeme_bekleyen,
         count(*) filter (where s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now())::int as ders_kesin_satis,
         count(*) filter (where s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now())::int as ders_bekleyen_satis,
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()), 0)::int        as ders_komisyon_tl
    from sinav_donemleri d
    cross join elciler e
    left join siparisler s
           on s.elci_kodu = e.kod
          and s.olusturma::date between d.baslangic and d.bitis
   group by d.ad, d.baslangic, d.bitis, e.kod, e.ad_soyad, e.instagram, e.baslangic_kademe
)
select donem, kod, ad_soyad, instagram, baslangic_kademe,
       kesin_satis, bekleyen_satis, iade, odeme_bekleyen,
       elci_komisyon(kesin_satis, baslangic_kademe) as komisyon_tl,
       case when kesin_satis >= 50 then 3 when kesin_satis >= 10 then 2 else 1 end as ulasilan_kademe,
       greatest(case when kesin_satis >= 50 then 3 when kesin_satis >= 10 then 2 else 1 end,
                baslangic_kademe) as sonraki_baslangic,
       case when kesin_satis >= 100 then 'OZEL' else '' end as ozel_isbirligi,
       ders_kesin_satis, ders_bekleyen_satis, ders_komisyon_tl,
       elci_komisyon(kesin_satis, baslangic_kademe) + ders_komisyon_tl as toplam_komisyon_tl
  from sayim;

revoke all on public.elci_donem_raporu from anon, authenticated;


-- 5) ELÇİ PANELİ — kademe sayımı damgasız satışlardan; ders satışları ayrı alanlarda.
--    'indirimler' artık yalnız indirimi > 0 olan paketler (ders paketleri 'ders_komisyonlari'nda).
create or replace function public.elci_panelim()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_e      elciler%rowtype;
  v_d      sinav_donemleri%rowtype;
  v_kesin  int := 0;
  v_bek    int := 0;
  v_iade   int := 0;
  v_obek   int := 0;
  v_dkesin int := 0;
  v_dbek   int := 0;
  v_dkom_k int := 0;
  v_dkom_b int := 0;
  v_n      int;
  v_k      smallint;
  v_esik   int;
begin
  if auth.uid() is null then
    return null;
  end if;
  select * into v_e from elciler where user_id = auth.uid();
  if not found then
    return null;
  end if;

  select * into v_d from sinav_donemleri
   where current_date between baslangic and bitis
   order by baslangic desc limit 1;
  if not found then
    select * into v_d from sinav_donemleri order by bitis desc limit 1;
  end if;

  select count(*) filter (where s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         count(*) filter (where s.durum = 'iade'),
         count(*) filter (where s.durum = 'odeme_bekliyor'),
         count(*) filter (where s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()), 0),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()), 0)
    into v_kesin, v_bek, v_iade, v_obek, v_dkesin, v_dbek, v_dkom_k, v_dkom_b
    from siparisler s
   where s.elci_kodu = v_e.kod
     and s.olusturma::date between v_d.baslangic and v_d.bitis;

  v_n := coalesce(v_kesin, 0) + coalesce(v_bek, 0);   -- ödenmiş kademeli satış (kesin + iade payı bekleyen)
  v_k := v_e.baslangic_kademe;
  v_esik := case when v_k <= 1 and v_n < 9  then 10
                 when v_k <= 2 and v_n < 49 then 50
                 when v_n < 99               then 100
                 else null end;

  return jsonb_build_object(
    'kod',               v_e.kod,
    'ad',                v_e.ad_soyad,
    'aktif',             v_e.aktif,
    'sozlesme_onay',     v_e.sozlesme_onay,
    'sozlesme_surum',    v_e.sozlesme_surum,
    'odeme_bilgisi',     v_e.odeme_bilgisi,
    'baslangic_kademe',  v_k,
    'donem',             case when v_d.ad is null then null else
                           jsonb_build_object('ad', v_d.ad, 'baslangic', v_d.baslangic, 'bitis', v_d.bitis) end,
    'kesin_satis',       coalesce(v_kesin, 0),
    'bekleyen_satis',    coalesce(v_bek, 0),
    'iade',              coalesce(v_iade, 0),
    'odeme_bekleyen',    coalesce(v_obek, 0),
    'komisyon_kesin',    elci_komisyon(coalesce(v_kesin, 0), v_k),
    'komisyon_tahmini',  elci_komisyon(v_n, v_k),
    'siradaki_birim',    elci_komisyon(v_n + 1, v_k) - elci_komisyon(v_n, v_k),
    'sonraki_esik',      v_esik,
    'sonraki_esik_kalan', case when v_esik is null then null else v_esik - v_n end,
    'sonraki_esik_birim', case v_esik when 10 then 1000 when 50 then 1250 else null end,
    'ozel_isbirligi',    v_n >= 100,
    'ders_kesin_satis',      coalesce(v_dkesin, 0),
    'ders_bekleyen_satis',   coalesce(v_dbek, 0),
    'ders_komisyon_kesin',   coalesce(v_dkom_k, 0),
    'ders_komisyon_tahmini', coalesce(v_dkom_k, 0) + coalesce(v_dkom_b, 0),
    'indirimler',        (select coalesce(jsonb_object_agg(paket, indirim_tl), '{}'::jsonb) from elci_indirim where indirim_tl > 0),
    'ders_komisyonlari', (select coalesce(jsonb_object_agg(paket, sabit_komisyon_tl), '{}'::jsonb) from elci_indirim where sabit_komisyon_tl is not null),
    'odemeler',          (select coalesce(jsonb_agg(jsonb_build_object('donem', o.donem, 'tutar_tl', o.tutar_tl,
                                                   'odeme_tarihi', o.odeme_tarihi) order by o.odeme_tarihi desc), '[]'::jsonb)
                            from elci_odemeler o where o.kod = v_e.kod)
  );
end $$;
revoke all on function public.elci_panelim() from public;
grant execute on function public.elci_panelim() to authenticated;
revoke execute on function public.elci_panelim() from anon;


-- ---------------------------------------------------------------------------
--  DOĞRULAMA — bastıktan sonra SQL editörde:
--   a) select paket, indirim_tl, sabit_komisyon_tl from elci_indirim order by paket;
--        sgs 400 null · yeterlilik-1 0 150 · -2 0 300 · -3 0 450 · -4 0 600 · yeterlilik-tum 400 null
--   b) select column_name from information_schema.columns
--       where table_name='siparisler' and column_name='elci_sabit_komisyon_tl';            -- 1 satır
--   c) select kod, kesin_satis, ders_kesin_satis, ders_komisyon_tl, toplam_komisyon_tl from elci_donem_raporu;
--   d) Anonim: elci_kodu_kontrol('AE42','yeterlilik-1') = 0 (indirim yok — DOĞRU; kod yine siparişe yazılır)
-- ---------------------------------------------------------------------------
