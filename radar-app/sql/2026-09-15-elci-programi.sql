-- ============================================================================
--  ELÇİ PROGRAMI — KOD İNDİRİMİ + KOMİSYON RAPORU  ·  15.09.2026
--
--  NEDEN: 15.09'da elçi davetinde iki söz verildi, ikisinin de arkasında sistem
--  YOKTU (15.09 taramasında ölçüldü):
--    1) "Takipçiniz size özel kodla 400 TL indirimli alır (2.590 → 2.190)."
--       Mevcut davet kodu (Çalışma Arkadaşım, veri/sql-davet-kodu.sql) indirim
--       yapmıyor, iki tarafa +1 ay veriyor. Yani takipçi kodu girse de 2.590 görürdü.
--    2) "Satış başına 750 / 1.000 / 1.250 TL, yalnız eşik üstü, kademe taşınır."
--       Kim kaç satış yaptı, hangi kademede, ne hak etti — hesaplayan yapı yoktu.
--
--  KARARLAR (Cem, 15.09): SGS 2.590 / 2.990 · elçi kodu 400 TL · komisyon
--  1–9. satış 750 · 10–49. satış 1.000 · 50–99. satış 1.250 · 100+ özel ·
--  yalnız eşik üstü · kazanılan kademe sonraki döneme taşınır, tutturulamazsa
--  bir kademe iner · komisyon 7 günlük iade süresi dolunca kesinleşir ·
--  kendi koduyla alım yok.
--
--  TASARIM İLKESİ (davet kodundaki gibi): istemcideki hiçbir şey güvenlik değildir.
--    - Tarayıcı kodu yalnız TAŞIR. İndirimin geçerli olup olmadığına SUNUCU karar
--      verir: siparis_elci_damga() tetikleyicisi sipariş yazılırken kodu sınar,
--      indirim_tl'yi KENDİSİ damgalar. Tarayıcının yolladığı indirim_tl yok sayılır.
--    - Elçi listesi (ad, e-posta) anonim kullanıcıya KAPALI. Tarayıcı yalnız
--      elci_kodu_kontrol() ile "bu kod bu pakette kaç TL indirir" sorusunu sorar;
--      cevap bir sayıdır, kişisel veri dönmez.
--    - Tutar hâlâ tarayıcıdan gelir (sql-siparis.sql'deki uyarı geçerli): tahsilat
--      banka hesabından teyit edilir. indirim_tl, havalede "doğru tutar mı?"
--      eşleştirmesini kolaylaştırır.
--
--  ⚠️ BASMA ZAMANI: auth.users'a yabancı anahtar YOK (14.09 PostgREST kesintisinin
--  sebebi o tip tablo idi). Yine de DDL — düşük trafikte bas, bastıktan sonra
--  satin-al.html'in açıldığını kontrol et.
--
--  SUPABASE SQL EDITOR'DE BİR KEZ ÇALIŞTIRILACAK. Tekrar basılması güvenlidir
--  (if not exists / create or replace / on conflict).
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1) SİPARİŞLERE ÜÇ KOLON
-- ---------------------------------------------------------------------------
alter table public.siparisler add column if not exists elci_kodu     text;
alter table public.siparisler add column if not exists indirim_tl    integer not null default 0;
alter table public.siparisler add column if not exists odendi_tarihi timestamptz;

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_indirim_tl_aralik') then
    alter table public.siparisler add constraint siparisler_indirim_tl_aralik check (indirim_tl between 0 and 5000);
  end if;
end $$;

create index if not exists siparisler_elci_idx on public.siparisler (elci_kodu, durum, odendi_tarihi);


-- ---------------------------------------------------------------------------
-- 2) ELÇİLER — kod · kişi · başlangıç kademesi
--    kod: büyük harf/rakam, 3–12 karakter (ör. AYSE, KPSSHOCA). Davet kodundan
--    (TT + 4) biçim olarak ayrı, karışmaz.
--    baslangic_kademe: bu dönem hangi komisyonla başlıyor (1=750, 2=1.000, 3=1.250).
--    Dönem sonunda elci_donem_raporu'ndaki "sonraki_baslangic" buraya yazılır.
-- ---------------------------------------------------------------------------
create table if not exists public.elciler (
  kod               text primary key check (kod ~ '^[A-Z0-9]{3,12}$'),
  ad_soyad          text not null check (length(ad_soyad) between 3 and 100),
  instagram         text check (instagram is null or length(instagram) <= 60),
  email             text check (email is null or length(email) <= 160),
  aktif             boolean not null default true,
  baslangic_kademe  smallint not null default 1 check (baslangic_kademe between 1 and 3),
  ozel_anlasma      text,                                -- 100+ satış özel iş birliği notu
  not_              text,
  olusturma         timestamptz not null default now()
);
alter table public.elciler enable row level security;
revoke all on public.elciler from anon, authenticated;


-- ---------------------------------------------------------------------------
-- 3) HANGİ PAKETTE KAÇ TL İNDİRİM — tek yer
--    Karar: yalnız SGS, 400 TL. Yeni paket eklenecekse buraya satır eklenir.
--    ⚠️ fiyat-motoru.js'teki ELCI.indirim ile AYNI olmalı (tarayıcı gösterimi oradan).
-- ---------------------------------------------------------------------------
create table if not exists public.elci_indirim (
  paket       text primary key check (length(paket) <= 40),
  indirim_tl  integer not null check (indirim_tl between 0 and 5000)
);
alter table public.elci_indirim enable row level security;
revoke all on public.elci_indirim from anon, authenticated;
insert into public.elci_indirim (paket, indirim_tl) values ('sgs', 400)
on conflict (paket) do update set indirim_tl = excluded.indirim_tl;


-- ---------------------------------------------------------------------------
-- 4) SINAV DÖNEMLERİ — kademe sayacı dönem içinde işler
--    İlk dönem: davetlerin başladığı günden 21 Kasım 2026 SGS'ye kadar.
--    Yeni dönem açılırken satır eklenir (tarih TÜRMOB takviminden elle teyitle).
-- ---------------------------------------------------------------------------
create table if not exists public.sinav_donemleri (
  ad          text primary key,
  baslangic   date not null,
  bitis       date not null check (bitis > baslangic)
);
alter table public.sinav_donemleri enable row level security;
revoke all on public.sinav_donemleri from anon, authenticated;
insert into public.sinav_donemleri (ad, baslangic, bitis) values ('SGS 2026-3', date '2026-09-15', date '2026-11-21')
on conflict (ad) do nothing;


-- ---------------------------------------------------------------------------
-- 5) TARAYICININ SORABİLECEĞİ TEK SORU: "bu kod bu pakette kaç TL indirir?"
--    Geçersiz / pasif kod ya da indirimsiz paket → 0. Kişisel veri dönmez.
-- ---------------------------------------------------------------------------
create or replace function public.elci_kodu_kontrol(p_kod text, p_paket text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select i.indirim_tl
      from elciler e
      join elci_indirim i on i.paket = p_paket
     where e.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
       and e.aktif
  ), 0);
$$;
revoke all on function public.elci_kodu_kontrol(text, text) from public;
grant execute on function public.elci_kodu_kontrol(text, text) to anon, authenticated;


-- ---------------------------------------------------------------------------
-- 6) SİPARİŞ YAZILIRKEN SUNUCU DAMGASI
--    - Kodu normalize eder; geçersiz / pasif / indirimsiz pakette kod ve indirim düşer.
--    - Elçinin kendi e-postasıyla verilen siparişte kod düşer (kendi koduyla alım yok).
--    - Tarayıcının yolladığı indirim_tl her durumda EZİLİR.
--    - Sipariş reddedilmez: kod yüzünden satış kaybetmeyiz, kod sessizce düşer.
-- ---------------------------------------------------------------------------
create or replace function public.siparis_elci_damga()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kod     text;
  v_indirim integer;
  v_email   text;
begin
  new.indirim_tl := 0;
  v_kod := nullif(upper(regexp_replace(coalesce(new.elci_kodu, ''), '[^A-Za-z0-9]', '', 'g')), '');
  if v_kod is null then
    new.elci_kodu := null;
    return new;
  end if;

  select i.indirim_tl, e.email into v_indirim, v_email
    from elciler e
    join elci_indirim i on i.paket = new.paket
   where e.kod = v_kod and e.aktif;

  if v_indirim is null or (v_email is not null and lower(v_email) = lower(new.email)) then
    new.elci_kodu := null;
    return new;
  end if;

  new.elci_kodu  := v_kod;
  new.indirim_tl := v_indirim;
  return new;
end $$;

drop trigger if exists siparis_elci_damga on public.siparisler;
create trigger siparis_elci_damga
  before insert on public.siparisler
  for each row execute function public.siparis_elci_damga();


-- ---------------------------------------------------------------------------
-- 7) ÖDENDİ DAMGASI — 7 günlük iade süresi bu tarihten sayılır
--    Panelden durum 'odendi' yapıldığı an tarih kendiliğinden yazılır.
-- ---------------------------------------------------------------------------
create or replace function public.siparis_odendi_damga()
returns trigger
language plpgsql
as $$
begin
  if new.durum = 'odendi' and coalesce(old.durum, '') <> 'odendi' and new.odendi_tarihi is null then
    new.odendi_tarihi := now();
  end if;
  return new;
end $$;

drop trigger if exists siparis_odendi_damga on public.siparisler;
create trigger siparis_odendi_damga
  before update on public.siparisler
  for each row execute function public.siparis_odendi_damga();


-- ---------------------------------------------------------------------------
-- 8) SİPARİŞ POLİTİKASI — sql-siparis.sql'deki kilit AYNEN + elçi kodu biçimi
--    (Politika yeniden yazılmazsa yeni kolon biçim kilidinin DIŞINDA kalırdı.)
-- ---------------------------------------------------------------------------
drop policy if exists siparisler_ekle on public.siparisler;
create policy siparisler_ekle
  on public.siparisler for insert
  to anon, authenticated
  with check (
        durum = 'odeme_bekliyor'
    and odeme = 'havale'
    and siparis_no ~ '^TT-[0-9]{8}-[ACDEFHJKLMNPRTUVXYZ2345679]{4}$'
    and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    and length(ad_soyad) between 3 and 100
    and length(email)    <= 160
    and length(coalesce(telefon, '')) <= 30
    and length(coalesce(adres, ''))   between 0 and 500
    and length(coalesce(paket_ad, '')) <= 120
    and length(paket) <= 40
    and pg_column_size(coalesce(fatura, '{}'::jsonb)) <= 2000
    and (secilen_dersler is null
         or (array_length(secilen_dersler, 1) between 1 and 8
             and pg_column_size(secilen_dersler) <= 1000))
    and (davet_kodu is null
         or davet_kodu ~ '^TT[ACDEFHJKLMNPRTUVXYZ2345679]{4}$')
    -- YENİ: elçi kodu biçimi (tetikleyici damgaladıktan sonra sınanır)
    and (elci_kodu is null or elci_kodu ~ '^[A-Z0-9]{3,12}$')
    and odendi_tarihi is null
  );
revoke select, update, delete on public.siparisler from anon, authenticated;


-- ---------------------------------------------------------------------------
-- 9) KOMİSYON HESABI — yalnız eşik üstü, başlangıç kademesi taşınır
--    n = dönemde kesinleşmiş satış adedi, bk = başlangıç kademesi (1/2/3)
--    Kademe 1: 1–9 → 750 · 10–49 → 1.000 · 50–99 → 1.250
--    Kademe 2: 1–49 → 1.000 · 50–99 → 1.250
--    Kademe 3: 1–99 → 1.250
--    100. satıştan sonrası: 1.250 ile hesaplanır ve raporda "OZEL" diye işaretlenir.
-- ---------------------------------------------------------------------------
create or replace function public.elci_komisyon(n integer, bk smallint)
returns integer
language sql
immutable
as $$
  select case
    when coalesce(n, 0) <= 0 then 0
    when bk >= 3 then n * 1250
    when bk = 2  then least(n, 49) * 1000 + greatest(0, n - 49) * 1250
    else least(n, 9) * 750
       + greatest(0, least(n, 49) - 9) * 1000
       + greatest(0, n - 49) * 1250
  end;
$$;


-- ---------------------------------------------------------------------------
-- 10) DÖNEM RAPORU — Cem SQL editörden okur:
--       select * from elci_donem_raporu order by donem, kesin_satis desc;
--     kesin_satis     : ödendi + 7 gün iade süresi dolmuş
--     bekleyen_satis  : ödendi ama iade süresi henüz dolmamış (komisyona girmez)
--     iade            : durum 'iade'
--     komisyon_tl     : kesin_satis üzerinden, yalnız eşik üstü
--     ulasilan_kademe : bu dönem ulaşılan (10+ → 2, 50+ → 3)
--     sonraki_baslangic: kademe koruma kuralı — max(ulaşılan, başlangıç − 1)
-- ---------------------------------------------------------------------------
create or replace view public.elci_donem_raporu as
with sayim as (
  select d.ad as donem, d.baslangic, d.bitis, e.kod, e.ad_soyad, e.instagram, e.baslangic_kademe,
         count(*) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now())::int as kesin_satis,
         count(*) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now())::int as bekleyen_satis,
         count(*) filter (where s.durum = 'iade')::int                                                    as iade,
         count(*) filter (where s.durum = 'odeme_bekliyor')::int                                          as odeme_bekleyen
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
                baslangic_kademe - 1) as sonraki_baslangic,
       case when kesin_satis >= 100 then 'OZEL' else '' end as ozel_isbirligi
  from sayim;

revoke all on public.elci_donem_raporu from anon, authenticated;


-- ---------------------------------------------------------------------------
--  DOĞRULAMA — bastıktan sonra SQL editörde:
--   a) select column_name from information_schema.columns
--       where table_name='siparisler' and column_name in ('elci_kodu','indirim_tl','odendi_tarihi');   -- 3 satır
--   b) select * from elci_indirim;                                   -- sgs | 400
--   c) insert into elciler (kod, ad_soyad, email) values ('DENEME', 'Deneme Elçi', 'deneme@ornek.com');
--      select elci_kodu_kontrol('deneme', 'sgs');                    -- 400
--      select elci_kodu_kontrol('deneme', 'yeterlilik-tum');         -- 0
--      select elci_kodu_kontrol('YOKKOD', 'sgs');                    -- 0
--      select elci_komisyon(30, 1::smallint);                        -- 27750  (9×750 + 21×1000)
--      select elci_komisyon(30, 2::smallint);                        -- 30000
--      delete from elciler where kod = 'DENEME';
--   d) Terminalden anon anahtarla elciler okunamamalı (boş dizi ya da 401):
--      curl -s "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/elciler?select=*" -H "apikey: <anon>"
--  Sonra fiyat-motoru.js'te ELCI.acik = true yapılır → satin-al.html'de kod alanı görünür.
-- ---------------------------------------------------------------------------
