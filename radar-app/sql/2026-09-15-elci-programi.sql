-- ============================================================================
--  ELÇİ PROGRAMI — KOD İNDİRİMİ + KOMİSYON RAPORU  ·  15.09.2026
--
--  NEDEN: 15.09'da elçi davetinde iki söz verildi, ikisinin de arkasında sistem
--  YOKTU (15.09 taramasında ölçüldü):
--    1) "Takipçiniz size özel kodla 400 TL indirimli alır (2.995 → 2.595; 27.09 kurucu fiyat kararı, KDV dahil)."
--       Mevcut davet kodu (Çalışma Arkadaşım, veri/sql-davet-kodu.sql) indirim
--       yapmıyor, iki tarafa +1 ay veriyor. Yani takipçi kodu girse de 2.590 görürdü.
--    2) "Satış başına 750 / 1.000 / 1.250 TL, yalnız eşik üstü, kademe taşınır."
--       Kim kaç satış yaptı, hangi kademede, ne hak etti — hesaplayan yapı yoktu.
--
--  KARARLAR (Cem, 15.09): SGS 2.590 / 2.990 (25.09: 3.108 / 3.588 · 27.09: kurucu 2.995 ilk 1.000 / liste 5.990, KDV dahil) · elçi kodu 400 TL · komisyon
--  1–9. satış 750 · 10–49. satış 1.000 · 50–99. satış 1.250 · 100+ özel ·
--  yalnız eşik üstü · kazanılan kademe sonraki döneme taşınır · komisyon ödendikten
--  7 gün sonra kesinleşir (itiraz/ters ibraz payı) · kendi koduyla alım yok.
--
--  29.09.2026 EKLERİ (Cem: "elçiler için özel platform, hepsi kendi platformuna girmeli"):
--    - Yeterlilik: elçi kodu 400 TL YALNIZ "tüm dersler" paketinde (3.490 → 3.090).
--      1–4 ders merdiveni indirimsiz (1 derste 1.190 − 400 − 750 komisyon = zarar). GM varsayımı,
--      Cem'e soruldu; değişirse aşağıdaki elci_indirim'e satır eklenir + fiyat-motoru.js ELCI.indirim.
--    - Kademe İNMEZ: "kazanılan kademe sonraki döneme taşınır" (Cem 15.09 + 27.09). 15.09 taslağındaki
--      "tutturulamazsa bir kademe iner" Cem onayı almamıştı, kaldırıldı.
--    - ELÇİ PANELİ (elci.html): elçi sitenin normal üyeliğiyle girer. Hesap e-postayla DEĞİL, tek
--      kullanımlık BAĞLAMA KODUYLA eşleşir — Supabase e-posta onayı 23.09'dan beri kapalı, e-postaya
--      güvenilse biri elçinin e-postasıyla üye olup paneline girebilirdi. Panel yalnız elci_panelim()
--      fonksiyonundan okur; alıcının adı/e-postası/telefonu hiçbir yoldan dönmez (KVKK), yalnız adet/tutar.
--    - Kendi koduyla alım artık sessizce düşmez, sipariş NET HATAYLA durur (ELCI_KENDI_KODU):
--      elçinin e-postası ya da elçinin bağlı hesabıyla verilen sipariş.
--    - Elçi ekleme/kapatma/ödeme işareti: arac/elci.ps1 (servis anahtarıyla, yerelde). Elçi kişi
--      verisi (ad, e-posta) DEPOYA YAZILMAZ — depo public.
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
--    kod: büyük harf/rakam, 3–12 karakter. 29.09 BİÇİM: baş harfler + 2 rakam (2–9), ör. CH48, IGM85
--    (arac/elci.ps1 KodOner üretir; ad linkte açık durmaz, 0/1 yok). Davet kodundan
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
  olusturma         timestamptz not null default now(),
  -- 29.09 ELÇİ PANELİ: bağlı hesap. auth.users'a YABANCI ANAHTAR YOK (14.09 PostgREST kesintisi).
  user_id           uuid unique,
  bag_kodu_ozet     text,                                -- bağlama kodunun sha256'sı; kodun kendisi hiçbir yerde tutulmaz
  bag_kodu_son      timestamptz,                         -- bağlama kodu bu ana kadar geçerli
  sozlesme_onay     timestamptz,                         -- elçi program koşullarını panelde onayladığı an
  sozlesme_surum    text,
  odeme_bilgisi     boolean not null default false       -- IBAN/fatura bilgisi Cem'e e-postayla ulaştı mı (IBAN burada TUTULMAZ)
);
-- Tablo daha önce eski biçimde kurulduysa (tekrar basım güvenliği)
alter table public.elciler add column if not exists user_id        uuid;
alter table public.elciler add column if not exists bag_kodu_ozet  text;
alter table public.elciler add column if not exists bag_kodu_son   timestamptz;
alter table public.elciler add column if not exists sozlesme_onay  timestamptz;
alter table public.elciler add column if not exists sozlesme_surum text;
alter table public.elciler add column if not exists odeme_bilgisi  boolean not null default false;
create unique index if not exists elciler_user_id_tekil on public.elciler (user_id) where user_id is not null;
alter table public.elciler enable row level security;
revoke all on public.elciler from anon, authenticated;


-- ---------------------------------------------------------------------------
-- 3) HANGİ PAKETTE KAÇ TL İNDİRİM — tek yer
--    Karar: SGS + Yeterlilik tüm dersler, 400 TL KDV dahil (27.09 Cem; SGS 25.09-27.09 arası 480'di).
--    Yeni paket eklenecekse buraya satır eklenir.
--    ⚠️ fiyat-motoru.js'teki ELCI.indirim ile AYNI olmalı (tarayıcı gösterimi oradan).
-- ---------------------------------------------------------------------------
create table if not exists public.elci_indirim (
  paket       text primary key check (length(paket) <= 40),
  indirim_tl  integer not null check (indirim_tl between 0 and 5000)
);
alter table public.elci_indirim enable row level security;
revoke all on public.elci_indirim from anon, authenticated;
insert into public.elci_indirim (paket, indirim_tl) values
  ('sgs',            400),   -- 27.09 Cem: 2.995 → 2.595, KDV dahil
  ('yeterlilik-tum', 400)    -- 27.09 Cem: 3.490 → 3.090, KDV dahil (1–4 ders merdiveni indirimsiz, üstteki not)
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
--    - Kodu normalize eder; geçersiz / pasif / indirimsiz pakette kod ve indirim düşer
--      (tarayıcı bunu elci_kodu_kontrol ile önceden söyler; burada satış kaybetmeyiz).
--    - KENDİ KODUYLA ALIM (29.09): elçinin e-postası ya da elçinin bağlı hesabı → sipariş
--      'ELCI_KENDI_KODU' hatasıyla DURUR. satin-al.html bu hatayı görünce e-posta yedeğini
--      GÖNDERMEZ, alıcıya "kendi kodunla alamazsın" der.
--    - Tarayıcının yolladığı indirim_tl her durumda EZİLİR.
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
  v_user    uuid;
begin
  new.indirim_tl := 0;
  v_kod := nullif(upper(regexp_replace(coalesce(new.elci_kodu, ''), '[^A-Za-z0-9]', '', 'g')), '');
  if v_kod is null then
    new.elci_kodu := null;
    return new;
  end if;

  select i.indirim_tl, e.email, e.user_id into v_indirim, v_email, v_user
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
--     sonraki_baslangic: kazanılan kademe taşınır, İNMEZ — max(ulaşılan, başlangıç) (29.09)
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
                baslangic_kademe) as sonraki_baslangic,
       case when kesin_satis >= 100 then 'OZEL' else '' end as ozel_isbirligi
  from sayim;

revoke all on public.elci_donem_raporu from anon, authenticated;


-- ---------------------------------------------------------------------------
-- 11) ELÇİ ÖDEMELERİ — Cem ödemeyi yapınca arac/elci.ps1 -Odeme ile satır düşer.
--     Panel elçiye kendi ödemelerini gösterir. IBAN burada TUTULMAZ.
-- ---------------------------------------------------------------------------
create table if not exists public.elci_odemeler (
  id            bigserial primary key,
  kod           text not null references public.elciler(kod),
  donem         text not null check (length(donem) <= 40),
  tutar_tl      integer not null check (tutar_tl between 0 and 10000000),
  odeme_tarihi  date not null default current_date,
  not_          text,
  olusturma     timestamptz not null default now()
);
alter table public.elci_odemeler enable row level security;
revoke all on public.elci_odemeler from anon, authenticated;


-- ---------------------------------------------------------------------------
-- 12) ELÇİ PANELİ — üç fonksiyon, yalnız GİRİŞ YAPMIŞ kullanıcıya.
--     Elçi tablolarına doğrudan okuma YOK; panel yalnız bunları çağırır.
-- ---------------------------------------------------------------------------

-- 12a) Hesabı elçi kaydına bağla: tek kullanımlık kod (arac/elci.ps1 üretir, 14 gün geçerli).
--      Dönüş: bağlanan elçi kodu · null = kod yanlış / süresi dolmuş / kullanılmış.
create or replace function public.elci_bagla(p_kod text)
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_kod  text;
  v_ozet text;
begin
  if auth.uid() is null then
    return null;
  end if;
  select kod into v_kod from elciler where user_id = auth.uid();
  if v_kod is not null then
    return v_kod;                                  -- zaten bağlı
  end if;
  v_ozet := encode(sha256(convert_to(upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g')), 'UTF8')), 'hex');
  update elciler
     set user_id = auth.uid(), bag_kodu_ozet = null, bag_kodu_son = null
   where bag_kodu_ozet = v_ozet
     and bag_kodu_son > now()
     and user_id is null
     and aktif
  returning kod into v_kod;
  return v_kod;
end $$;
revoke all on function public.elci_bagla(text) from public;
grant execute on function public.elci_bagla(text) to authenticated;

-- 12b) Program koşullarını onayla (sürüm = elci.html'deki KOSUL_SURUM).
create or replace function public.elci_sozlesme_onayla(p_surum text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or coalesce(p_surum, '') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    return false;
  end if;
  update elciler set sozlesme_onay = now(), sozlesme_surum = p_surum where user_id = auth.uid();
  return found;
end $$;
revoke all on function public.elci_sozlesme_onayla(text) from public;
grant execute on function public.elci_sozlesme_onayla(text) to authenticated;

-- 12c) Panelin tek kaynağı. Bağlı elçi değilse null.
--      Dönen: kod, ad, aktif, koşul onayı, içinde bulunulan dönem, adetler, komisyon,
--      sonraki eşik, indirimler, ödemeler. ALICI BİLGİSİ YOK — yalnız sayı.
create or replace function public.elci_panelim()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_e     elciler%rowtype;
  v_d     sinav_donemleri%rowtype;
  v_kesin int := 0;
  v_bek   int := 0;
  v_iade  int := 0;
  v_obek  int := 0;
  v_n     int;
  v_k     smallint;
  v_esik  int;
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

  select count(*) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         count(*) filter (where s.durum = 'iade'),
         count(*) filter (where s.durum = 'odeme_bekliyor')
    into v_kesin, v_bek, v_iade, v_obek
    from siparisler s
   where s.elci_kodu = v_e.kod
     and s.olusturma::date between v_d.baslangic and v_d.bitis;

  v_n := coalesce(v_kesin, 0) + coalesce(v_bek, 0);   -- ödenmiş satış (kesin + iade payı bekleyen)
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
    'indirimler',        (select coalesce(jsonb_object_agg(paket, indirim_tl), '{}'::jsonb) from elci_indirim),
    'odemeler',          (select coalesce(jsonb_agg(jsonb_build_object('donem', o.donem, 'tutar_tl', o.tutar_tl,
                                                   'odeme_tarihi', o.odeme_tarihi) order by o.odeme_tarihi desc), '[]'::jsonb)
                            from elci_odemeler o where o.kod = v_e.kod)
  );
end $$;
revoke all on function public.elci_panelim() from public;
grant execute on function public.elci_panelim() to authenticated;

-- 12d) Supabase public şemadaki yeni fonksiyona anon'a EXECUTE'u varsayılan yetkiyle AYRICA verir;
--      "from public" onu kaldırmaz (29.09 ölçüldü: anon elci_panelim → 200 null). Veri sızmıyordu
--      (auth.uid() null → null/false), yine de kapı kapalı olsun:
revoke execute on function public.elci_panelim()             from anon;
revoke execute on function public.elci_bagla(text)           from anon;
revoke execute on function public.elci_sozlesme_onayla(text) from anon;


-- ---------------------------------------------------------------------------
--  ⚠️ BASMADAN ÖNCE (29.09): bu dosya siparisler_ekle politikasını YENİDEN yazar (bölüm 8).
--   Canlıdaki politika panelden elle değiştirildiyse o değişiklik ezilir. Önce bak:
--     select with_check from pg_policies where tablename = 'siparisler' and policyname = 'siparisler_ekle';
--   Çıkan metin veri/sql-siparis.sql bölümündeki kilitten FARKLIYSA basma, önce Claude'a göster.
--
--  DOĞRULAMA — bastıktan sonra SQL editörde:
--   a) select column_name from information_schema.columns
--       where table_name='siparisler' and column_name in ('elci_kodu','indirim_tl','odendi_tarihi');   -- 3 satır
--   b) select * from elci_indirim;                                   -- sgs | 400 · yeterlilik-tum | 400
--   c) insert into elciler (kod, ad_soyad, email) values ('DENEME', 'Deneme Elçi', 'deneme@ornek.com');
--      select elci_kodu_kontrol('deneme', 'sgs');                    -- 400
--      select elci_kodu_kontrol('deneme', 'yeterlilik-tum');         -- 400
--      select elci_kodu_kontrol('deneme', 'yeterlilik-1');           -- 0
--      select elci_kodu_kontrol('YOKKOD', 'sgs');                    -- 0
--      select elci_komisyon(30, 1::smallint);                        -- 27750  (9×750 + 21×1000)
--      select elci_komisyon(30, 2::smallint);                        -- 30000
--      delete from elciler where kod = 'DENEME';
--   d) Terminalden anon anahtarla elciler okunamamalı (boş dizi ya da 401):
--      curl -s "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/elciler?select=*" -H "apikey: <anon>"
--   e) Panel fonksiyonları anonime KAPALI olmalı (401/404; giriş yapmış elçiye açık):
--      curl -s -X POST ".../rest/v1/rpc/elci_panelim" -H "apikey: <anon>" -H "Content-Type: application/json" -d "{}"
--   (a–e'yi Claude anonim uçtan da koşar: powershell -NoProfile -File arac/elci.ps1 -Dogrula)
--  Sonra fiyat-motoru.js'te ELCI.acik = true yapılır → satin-al.html'de kod alanı görünür.
-- ---------------------------------------------------------------------------
