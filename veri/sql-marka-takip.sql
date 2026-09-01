-- ⚠️ BU DOSYA CANLIDA BASILI OLANI ANLATIR (01.09.2026 itibariyla).
--    Depoda durmasi basildigi anlamina gelmez; ama depodaki metin canlidan
--    FARKLI olursa, dosyayi yeniden basmak iyi surumu bozar. 01.09'da tam bu
--    risk dogdu: Cem'e yapistirdigim son surumde kademe hesabi TEK YERE
--    (marka_kademe_hesap) tasinmisti, dosya ise kopyali surumu tutuyordu.
--    Duzeltildi. Bundan sonra: canliya basilan her degisiklik AYNI GUN bu
--    dosyaya da islenir.
-- ============================================================================
--  MARKA NÖBETİ — UYARI BACAĞI  (30.08.2026)
--
--  Cem: "müşterimizin markası ile başka yerden yeni başvuru geldiğinde nasıl
--  görürüz" → "uyarı bacağını kur".
--
--  NE YAPAR: Kullanıcı markasını BİR KEZ kaydeder. Her yeni Resmî Marka
--  Bülteni yutulduğunda robot, o markaya benzeyen ve İTİRAZ SÜRESİ AÇIK
--  başvuruları bulup e-posta atar. Kaçan süre geri gelmez (SMK m.18: iki ay).
--
--  ÜRÜNÜN PARA KAZANAN YERİ BURASI: "bakış bedava, nöbet paralı".
--
--  ── TASARIMIN ÜÇ KARARI ──────────────────────────────────────────────────
--  1) AYNI BAŞVURU İKİ KEZ UYARILMAZ. marka_takip_gonderim tablosu her
--     (takip, başvuru) çiftini bir kez kaydeder. Bu olmadan her koşu aynı
--     uyarıyı tekrar atar ve kullanıcı ürünü kapatır.
--  2) SÜRESİ DOLMUŞ BAŞVURU UYARILMAZ. Bugün canlıda yaşandı: doğru veriyle
--     yanlış vaat. itiraz_son >= current_date şartı sunucuda.
--  3) E-POSTA DIŞARI ÇIKMAZ. Eşleştirme fonksiyonu anon'a AÇILMAZ; yalnız
--     servis anahtarıyla (robot) çağrılır. Kullanıcı kendi kaydını ancak
--     elindeki jetonla görür/kapatır.
--
--  KVKK: kayıt sırasında açık rıza kutusu işaretlenir; her e-postada tek
--  tıkla çıkış bağlantısı bulunur (jetonla). Kimseye sormadan liste kurmuyoruz.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) ABONELİK
-- ---------------------------------------------------------------------------
create table if not exists public.marka_takip (
  id          uuid primary key default gen_random_uuid(),
  ad          text        not null,
  ad_norm     text        not null,
  sinif       int[]       not null default '{}',
  eposta      text        not null,
  jeton       text        not null unique,      -- kullanıcının yönetim anahtarı
  aktif       boolean     not null default true,
  esik        real        not null default 0.32,
  olusma      timestamptz not null default now(),
  son_bakis   timestamptz,                      -- robot en son ne zaman baktı
  son_uyari   timestamptz
);

create index if not exists ix_mt_aktif  on public.marka_takip (aktif) where aktif;
create index if not exists ix_mt_eposta on public.marka_takip (lower(eposta));
alter table public.marka_takip enable row level security;
-- POLİTİKA BİLEREK YOK: e-posta listesi doğrudan okunamaz.

-- Hangi başvuru için kime yazdık — "iki kez uyarma" nöbetçisi.
create table if not exists public.marka_takip_gonderim (
  takip_id    uuid not null references public.marka_takip(id) on delete cascade,
  basvuru_no  text not null,
  bulten_no   int  not null,
  gonderim    timestamptz not null default now(),
  primary key (takip_id, basvuru_no)
);
alter table public.marka_takip_gonderim enable row level security;

-- ---------------------------------------------------------------------------
-- 2) KULLANICI KAPILARI (anon çağırabilir, tavanlı)
-- ---------------------------------------------------------------------------

-- (a) Nöbet aç. Jeton döner: kullanıcı bununla kaydını görür/kapatır.
create or replace function public.marka_takip_ac(
  p_ad text, p_sinif int[], p_eposta text)
returns table (jeton text, ad text, sinif int[])
language plpgsql security definer set search_path = public, extensions as $$
declare v_j text; v_n text; v_id uuid;
begin
  v_n := public.marka_norm(p_ad);
  if v_n = '' or length(trim(p_ad)) < 2 then
    raise exception 'Marka adı en az 2 harf olmalı.';
  end if;
  if p_eposta !~ '^[^@[:space:]]+@[^@[:space:]]+\.[a-zA-Z]{2,}$' then
    raise exception 'E-posta adresi geçerli görünmüyor.';
  end if;
  -- Aynı e-posta için tavan: kötüye kullanımı ve masrafı sınırlar.
  if (select count(*) from public.marka_takip t
       where lower(t.eposta) = lower(p_eposta) and t.aktif) >= 25 then
    raise exception 'Bu e-posta için nöbet sayısı sınıra ulaştı (25).';
  end if;

  -- Aynı marka + aynı e-posta ikinci kez açılmaz, mevcut kayıt tazelenir.
  select t.id, t.jeton into v_id, v_j from public.marka_takip t
   where t.ad_norm = v_n and lower(t.eposta) = lower(p_eposta) limit 1;

  if v_id is null then
    v_j := encode(extensions.gen_random_bytes(24), 'hex');
    insert into public.marka_takip (ad, ad_norm, sinif, eposta, jeton)
    values (trim(p_ad), v_n, coalesce(p_sinif, '{}'), lower(trim(p_eposta)), v_j)
    returning id into v_id;
  else
    update public.marka_takip t
       set sinif = coalesce(p_sinif, t.sinif), aktif = true
     where t.id = v_id;
  end if;

  return query
    select t.jeton, t.ad, t.sinif from public.marka_takip t where t.id = v_id;
end;
$$;

-- (b) Nöbeti kapat (e-postadaki tek tıklık çıkış bağlantısı bunu çağırır).
create or replace function public.marka_takip_kapat(p_jeton text)
returns boolean
language sql security definer set search_path = public as $$
  with u as (
    update public.marka_takip set aktif = false
     where jeton = p_jeton and length(p_jeton) = 48
    returning 1)
  select exists (select 1 from u);
$$;

-- (c) Kendi kaydını gör (yalnız jetonu olan).
create or replace function public.marka_takip_gor(p_jeton text)
returns table (ad text, sinif int[], aktif boolean, olusma timestamptz,
               son_uyari timestamptz, uyari_sayisi bigint)
language sql security definer set search_path = public as $$
  select t.ad, t.sinif, t.aktif, t.olusma, t.son_uyari,
         (select count(*) from public.marka_takip_gonderim g where g.takip_id = t.id)
    from public.marka_takip t
   where t.jeton = p_jeton and length(p_jeton) = 48;
$$;

-- ---------------------------------------------------------------------------
-- 3) ROBOT KAPISI — anon'a AÇILMAZ (e-posta içerir)
--    Bekleyen uyarıları tek sorguda verir: hem eşleşme hem "daha önce
--    yazmadık" kontrolü burada, sunucuda yapılır.
-- ---------------------------------------------------------------------------
create or replace function public.marka_takip_bekleyen(p_tavan int default 500)
returns table (
  takip_id uuid, eposta text, jeton text, takip_ad text, takip_sinif int[],
  basvuru_no text, bulten_no int, ad text, sahip text, sinif int[],
  yayin_tarihi date, itiraz_son date, kalan_gun int,
  benzerlik real, ayni_sinif boolean)
language sql security definer set search_path = public, extensions as $$
  -- 30.08 CANLI KUSUR: duz JOIN 49.533 kayitta bile "statement timeout"
  -- verdi; planlayici trigram indeksini kullanmayip carpim uretiyordu.
  -- 1,8 milyon kayitta hic donmezdi. Cozum: ABONE BASINA LATERAL ->
  -- her abone icin ayri indeks aramasi + abone basina tavan.
  select t.id, t.eposta, t.jeton, t.ad, t.sinif,
         b.basvuru_no, b.bulten_no, b.ad, b.sahip, b.sinif,
         b.yayin_tarihi, b.itiraz_son, b.kalan_gun, b.benzerlik, b.ayni_sinif
    from public.marka_takip t
    cross join lateral (
      select x.basvuru_no, x.bulten_no, x.ad, x.sahip, x.sinif,
             x.yayin_tarihi, x.itiraz_son,
             (x.itiraz_son - current_date)::int              as kalan_gun,
             similarity(x.ad_norm, t.ad_norm)                as benzerlik,
             (cardinality(t.sinif) > 0 and x.sinif && t.sinif) as ayni_sinif
        from public.marka_bulten x
       where x.ad_norm % t.ad_norm                      -- GIN indeksi burada
         -- SÜRESİ DOLMUŞ UYARILMAZ: geç kalınmış haber, haber değildir.
         and x.itiraz_son >= current_date
         -- Sınıf verdiyse sınıf çakışması şart (SMK m.6/1).
         and (cardinality(t.sinif) = 0 or x.sinif && t.sinif)
         -- Kendi markasını kendine haber verme.
         and x.ad_norm <> t.ad_norm
         and similarity(x.ad_norm, t.ad_norm) >= t.esik
         -- AYNI BAŞVURU İKİ KEZ UYARILMAZ.
         and not exists (select 1 from public.marka_takip_gonderim g
                          where g.takip_id = t.id and g.basvuru_no = x.basvuru_no)
       order by (cardinality(t.sinif) > 0 and x.sinif && t.sinif) desc,
                x.itiraz_son asc
       limit 200                                        -- abone basina tavan
    ) b
   where t.aktif
   order by t.id, b.ayni_sinif desc, b.itiraz_son asc
   limit least(greatest(p_tavan, 1), 5000);
$$;

-- Robot yazdıktan SONRA işaretler. Yazmadan işaretlemek uyarıyı yutar.
create or replace function public.marka_takip_isaretle(
  p_takip_id uuid, p_kayitlar jsonb)
returns int
language plpgsql security definer set search_path = public as $$
declare v int;
begin
  insert into public.marka_takip_gonderim (takip_id, basvuru_no, bulten_no)
  select p_takip_id, x->>'no', (x->>'bulten')::int
    from jsonb_array_elements(p_kayitlar) x
  on conflict do nothing;
  get diagnostics v = row_count;
  update public.marka_takip set son_uyari = now(), son_bakis = now()
   where id = p_takip_id;
  return v;
end;
$$;

-- Nöbet sayacı (vitrin için; e-posta İÇERMEZ)
create or replace function public.marka_takip_sayac()
returns table (aktif_nobet bigint, uyarilan bigint)
language sql security definer set search_path = public as $$
  select (select count(*) from public.marka_takip where aktif),
         (select count(*) from public.marka_takip_gonderim);
$$;

-- ---------------------------------------------------------------------------
-- 4) YETKİLER — e-posta gören iki fonksiyon anon'a KAPALI
-- ---------------------------------------------------------------------------
revoke all on function public.marka_takip_ac(text,int[],text)        from public;
revoke all on function public.marka_takip_kapat(text)                from public;
revoke all on function public.marka_takip_gor(text)                  from public;
revoke all on function public.marka_takip_bekleyen(int)              from public;
revoke all on function public.marka_takip_isaretle(uuid,jsonb)       from public;
revoke all on function public.marka_takip_sayac()                    from public;

grant execute on function public.marka_takip_ac(text,int[],text) to anon, authenticated;
grant execute on function public.marka_takip_kapat(text)         to anon, authenticated;
grant execute on function public.marka_takip_gor(text)           to anon, authenticated;
grant execute on function public.marka_takip_sayac()             to anon, authenticated;
-- 🔴 30.08 CANLI OLCUM: "grant vermemek" YETMIYOR. bekleyen() anon anahtariyla
-- CAGRILABILDI (izin hatasi degil, zaman asimi dondu - yani calisti). Supabase'de
-- anon/authenticated rolleri, PUBLIC'ten gelen varsayilan EXECUTE hakkini
-- devraliyor; sadece "grant yazmamak" kapi degildir. ACIKCA GERI ALINIYOR.
-- Kayit sayisi azken gorunmedi; abone dolunca butun e-postalar disari sizardi.
revoke execute on function public.marka_takip_bekleyen(int)        from anon, authenticated;
revoke execute on function public.marka_takip_isaretle(uuid,jsonb) from anon, authenticated;
-- Teyit (anon anahtariyla cagir): "permission denied for function" DONMELI.
-- Bos dizi ya da zaman asimi donuyorsa kapi KAPANMAMIStir.

-- ---------------------------------------------------------------------------
-- 5) TEYİT
--    select * from public.marka_takip_sayac();
--    select * from public.marka_takip_ac('tetikte', array[9,42], 'ornek@ornek.com');
--    -- dönen jetonla:
--    select * from public.marka_takip_gor('<jeton>');
--    select public.marka_takip_kapat('<jeton>');
-- ---------------------------------------------------------------------------

-- ============================================================================
--  UYARI KADEMELERİ — "harf benzerliği tek başına yetmiyor"  (31.08.2026)
--
--  Cem, gerçek bir uyarıyı okuyup sordu: "TETRİ ismini almak istemiş, ben
--  TETİKTE — aynı değil, çok farklı değil mi? Mahkeme nasıl karar veriyor?"
--  Haklıydı. Ölçüm de onu doğruladı.
--
--  ── ÖLÇÜLEN SORUN (6 gerçek marka, canlı ambar) ─────────────────────────
--  Trigram (harf) benzerliği sinyalle gürültüyü AYIRAMIYOR:
--    "tetik yum lojistik"  %38   <- GERÇEK tehdit (markayı olduğu gibi içerir)
--    "etik"                %38   <- gürültü (alakasız kelime)
--    "bek"                 %50   <- GERÇEK tehdit (kısaltma)
--    "bedeko"              %50   <- gürültü
--  Aynı puan, zıt anlam. Eşiği yükseltmek gerçek tehdidi de atardı.
--
--  ── AYIRAN ŞEY: KELİME BÜTÜNLÜĞÜ ────────────────────────────────────────
--  Hukukun baktığı yere yakın: marka, adayın içinde BİR KELİME OLARAK geçiyor
--  mu? (SMK m.6/1 bütünsel değerlendirme; tüketici kelimenin başına daha çok
--  dikkat eder.) Bunun için boşlukları KORUYAN bir normalleştirme gerekiyor -
--  mevcut marka_norm() boşlukları siliyor ve "tuana tetik" içindeki kelime
--  sınırı kayboluyor.
--
--  ── ÜÇ KADEME ───────────────────────────────────────────────────────────
--   YUKSEK : marka, adayda kelime başında geçiyor  (tetikte, tuana tetik)
--            ya da aday markanın kısaltması        (beko -> bek)
--   ORTA   : harf benzerliği >= 0.45 ve uzunluk farkı <= 3
--   ZAYIF  : gerisi -> MAİL GİTMEZ, sitede görülebilir
--
--  Doğrulandı (ölçülen 6 markanın hepsinde): etik/tet lojistik/bedeko/
--  asçelik ZAYIF'a düşüyor; tuana tetik/tetik yum lojistik/bek/vestel güzel
--  YUKSEK'e çıkıyor.
--
--  SINIR: kısa markalarda (4-5 harf) gürültü sıfırlanmaz. Kademe azaltır.
--  Son karar her zaman insanda - biz "bak buna" deriz, "itiraz et" demeyiz.
-- ============================================================================

-- Boşlukları KORUYAN normalleştirme. marka_norm() ile aynı harf katlaması,
-- tek farkı: kelime sınırı kaybolmuyor.
create or replace function public.marka_norm_bosluklu(p text)
returns text language sql immutable as $$
  select trim(regexp_replace(
           regexp_replace(
             translate(lower(coalesce(p,'')), 'çğıîöşüâûİI', 'cgiiosuau' || 'i' || 'i'),
             '[^a-z0-9 ]', ' ', 'g'),
           ' +', ' ', 'g'));
$$;

-- 31.08 CANLI HATA: "42P13 cannot change return type of existing function".
-- Fonksiyona kademe ve sebep sutunlari eklendi; Postgres donus tipini
-- degistirmeye izin vermez, once DUSURULMESI gerekir. marka_bulten_itiraz
-- icin bu satiri yazmistim, burada unutmusum - sutun ekleyen her guncellemede
-- drop sarttir.
drop function if exists public.marka_takip_bekleyen(int);
create or replace function public.marka_takip_bekleyen(p_tavan int default 500)
returns table (
  takip_id uuid, eposta text, jeton text, takip_ad text, takip_sinif int[],
  basvuru_no text, bulten_no int, ad text, sahip text, sinif int[],
  yayin_tarihi date, itiraz_son date, kalan_gun int,
  benzerlik real, ayni_sinif boolean, kademe text, sebep text)
language sql security definer set search_path = public, extensions as $$
  select t.id, t.eposta, t.jeton, t.ad, t.sinif,
         b.basvuru_no, b.bulten_no, b.ad, b.sahip, b.sinif,
         b.yayin_tarihi, b.itiraz_son, b.kalan_gun, b.benzerlik, b.ayni_sinif,
         b.kademe, b.sebep
    from public.marka_takip t
    cross join lateral (
      select x.basvuru_no, x.bulten_no, x.ad, x.sahip, x.sinif,
             x.yayin_tarihi, x.itiraz_son,
             (x.itiraz_son - current_date)::int                as kalan_gun,
             similarity(x.ad_norm, t.ad_norm)                  as benzerlik,
             (cardinality(t.sinif) > 0 and x.sinif && t.sinif) as ayni_sinif,
             case
               when public.marka_norm_bosluklu(x.ad) ~ ('(^| )' || t.ad_norm)
                 then 'YUKSEK'
               when t.ad_norm like public.marka_norm(x.ad) || '%'
                    and length(public.marka_norm(x.ad)) >= 3
                    and length(public.marka_norm(x.ad))::real / greatest(length(t.ad_norm),1) >= 0.6
                 then 'YUKSEK'
               when similarity(x.ad_norm, t.ad_norm) >= 0.45
                    and abs(length(x.ad_norm) - length(t.ad_norm)) <= 3
                 then 'ORTA'
               else 'ZAYIF'
             end as kademe,
             case
               when public.marka_norm_bosluklu(x.ad) ~ ('(^| )' || t.ad_norm)
                 then 'markanız bu başvuruda bir kelime olarak geçiyor'
               when t.ad_norm like public.marka_norm(x.ad) || '%'
                    and length(public.marka_norm(x.ad)) >= 3
                    and length(public.marka_norm(x.ad))::real / greatest(length(t.ad_norm),1) >= 0.6
                 then 'başvuru, markanızın kısaltılmış hâline benziyor'
               when similarity(x.ad_norm, t.ad_norm) >= 0.45
                    and abs(length(x.ad_norm) - length(t.ad_norm)) <= 3
                 then 'yazılış olarak yakın, uzunluk benzer'
               else 'yalnızca harf benzerliği'
             end as sebep
        from public.marka_bulten x
       where x.ad_norm % t.ad_norm
         and x.itiraz_son >= current_date
         and (cardinality(t.sinif) = 0 or x.sinif && t.sinif)
         and x.ad_norm <> t.ad_norm
         and similarity(x.ad_norm, t.ad_norm) >= t.esik
         and not exists (select 1 from public.marka_takip_gonderim g
                          where g.takip_id = t.id and g.basvuru_no = x.basvuru_no)
       order by (cardinality(t.sinif) > 0 and x.sinif && t.sinif) desc,
                x.itiraz_son asc
       limit 200
    ) b
   where t.aktif
     -- ZAYIF olanlar MAİL LİSTESİNE GİRMEZ. Müşteriye zayıf uyarı yollamak,
     -- ya boşuna vekil masrafı ya da ürüne güvenin kaybı demektir.
     and b.kademe <> 'ZAYIF'
   order by t.id, (b.kademe = 'YUKSEK') desc, b.itiraz_son asc
   limit least(greatest(p_tavan, 1), 5000);
$$;

revoke all     on function public.marka_takip_bekleyen(int) from public;
revoke execute on function public.marka_takip_bekleyen(int) from anon, authenticated;

-- TEYİT (servis anahtarıyla): dönen her satırda kademe YUKSEK ya da ORTA
-- olmalı; ZAYIF hiç görünmemeli.

-- ============================================================================
--  KADEME ÖZ-SINAVI  (31.08.2026)
--
--  Cem: "1 yap."  (kademe mantığını kalıcı nöbetçiye çevir)
--
--  NEDEN: kademe mantığını 31.08'de ELLE sınadım — geçici nöbet açtım, sonucu
--  okudum, kaydı sildim. İşe yaradığını gördük ama o sınav hiçbir yerde
--  DURMUYOR. Mantık ileride değişirse (eşik, uzunluk kuralı, kelime sınırı)
--  bozulduğunu kimse fark etmez: uyarılar sessizce yanlışlaşır. Müşteri ya
--  boşuna vekile gider ya gerçek tehdidi kaçırır.
--
--  BU FONKSİYON: bilinen çiftleri her koşuda dener. Ambardaki gerçek veriye
--  DEĞİL, verilen isim çiftlerine bakar — yani ambar değiştikçe sonuç
--  değişmez, yalnız MANTIK değişirse değişir. Sınav böyle olmalı.
--
--  Beklenenler 31.08 ölçümünden alındı (uydurma değil, canlı ambarda görüldü):
--    tetik  ↔ tetikte              YUKSEK  (kelime olarak geçiyor)
--    tetik  ↔ tuana tetik          YUKSEK  (kelime olarak geçiyor)
--    tetik  ↔ tetik yum lojistik   YUKSEK  (kelime olarak geçiyor)
--    beko   ↔ bek                  YUKSEK  (kısaltma)
--    tetik  ↔ etik                 ZAYIF   (sadece harf benzerliği)
--    tetik  ↔ tet lojistik         ZAYIF
--    beko   ↔ bedeko               ORTA    (yazılış yakın)
--    tetikte↔ tetri                ZAYIF   ← Cem'in yakaladığı vaka
--    arcelik↔ asçelik              ORTA
-- ============================================================================

create or replace function public.marka_kademe_hesap(p_marka text, p_aday text)
-- 01.09 CANLI HATA: "42883 function extensions.similarity(text,text) does not
-- exist". pg_trgm EXTENSIONS semasinda degil, PUBLIC'te kurulu. Diger
-- fonksiyonlarda search_path kullandigim icin sorun cikmamisti; burada semayi
-- ELLE yazmisim. DERS: sema adi hicbir yerde sabit yazilmaz, search_path ile
-- cozulur - bu dosyanin basinda pg_trgm semasini BULAN bir blok bile var.
returns text language sql immutable
set search_path = public, extensions as $
  -- marka_takip_bekleyen() içindeki kademe mantığının AYNISI, tek başına
  -- sınanabilir hâlde. İkisi ayrışırsa sınav bunu yakalar.
  select case
    when public.marka_norm_bosluklu(p_aday) ~ ('(^| )' || public.marka_norm(p_marka))
      then 'YUKSEK'
    when public.marka_norm(p_marka) like public.marka_norm(p_aday) || '%'
         and length(public.marka_norm(p_aday)) >= 3
         and length(public.marka_norm(p_aday))::real
             / greatest(length(public.marka_norm(p_marka)),1) >= 0.6
      then 'YUKSEK'
    when similarity(public.marka_norm(p_aday), public.marka_norm(p_marka)) >= 0.45
         and abs(length(public.marka_norm(p_aday)) - length(public.marka_norm(p_marka))) <= 3
      then 'ORTA'
    else 'ZAYIF'
  end;
$$;

create or replace function public.marka_kademe_sinav()
returns table (marka text, aday text, beklenen text, cikan text, sonuc text)
language sql security definer set search_path = public, extensions as $$
  with sinav(marka, aday, beklenen) as (values
    ('tetik',   'tetikte',            'YUKSEK'),
    ('tetik',   'tuana tetik',        'YUKSEK'),
    ('tetik',   'tetik yum lojistik', 'YUKSEK'),
    ('beko',    'bek',                'YUKSEK'),
    ('ipek',    'ipekel',             'YUKSEK'),
    ('vestel',  'vestel güzel',       'YUKSEK'),
    ('tetik',   'etik',               'ZAYIF'),
    ('tetik',   'tet lojistik',       'ZAYIF'),
    ('tetikte', 'tetri',              'ZAYIF'),
    ('beko',    'bedeko',             'ORTA'),
    ('arcelik', 'asçelik',            'ORTA')
  )
  select s.marka, s.aday, s.beklenen,
         public.marka_kademe_hesap(s.marka, s.aday),
         case when public.marka_kademe_hesap(s.marka, s.aday) = s.beklenen
              then 'GECTI' else 'DUSTU' end
    from sinav s
   order by (public.marka_kademe_hesap(s.marka, s.aday) = s.beklenen), s.marka, s.aday;
$$;

revoke all     on function public.marka_kademe_sinav() from public;
revoke execute on function public.marka_kademe_sinav() from anon, authenticated;
revoke all     on function public.marka_kademe_hesap(text,text) from public;
revoke execute on function public.marka_kademe_hesap(text,text) from anon, authenticated;

-- TEYİT: select * from public.marka_kademe_sinav();
--        Her satırda sonuc = 'GECTI' olmalı. DUSTU varsa kademe mantığı
--        bozulmuş demektir; uyarılar sessizce yanlışlaşır.

-- ============================================================================
--  HATIRLATMA HALKASI  (31.08.2026)
--
--  Cem, ilk gerçek maili okuyup: "çok soğuk bir mesaj... göndermezler ise
--  tekrar mail geleceği... onlarla ilgilendiğimizi göstermemiz lazım."
--
--  Mail artık "cevap alamazsak size bir kez daha yazacağız" diyor.
--  BU SÖZ TUTULMAZSA MAİL YALAN SÖYLER. Bu göç, sözü gerçek yapar.
--
--  İKİ HATIRLATMA, kademeli:
--    1. hatırlatma : itiraza <= 20 gün kaldığında
--    2. hatırlatma : itiraza <=  7 gün kaldığında  (son çağrı)
--  Daha sık yazmak bunaltır, daha seyrek yazmak süreyi kaçırtır. Süre
--  yayımdan iki aydır (SMK m.18) ve UZATILAMAZ - kaçıran hakkını kaybeder.
--
--  TASARIM: gönderim kaydı silinmiyor (aynı başvuru için ilk uyarı bir kez
--  gider). Üstüne bir sayaç konuyor: kaç kez hatırlattık. Böylece "iki kez
--  uyarma" freni korunuyor ama hatırlatma mümkün oluyor.
-- ============================================================================

alter table public.marka_takip_gonderim
  add column if not exists hatirlatma int not null default 0;

drop function if exists public.marka_takip_bekleyen(int);
-- 01.09: KADEME HESABI TEK YERDE. Eskiden bu fonksiyon kademe mantığını kendi
-- içine KOPYALIYORDU; öz-sınav ise marka_kademe_hesap()'ı sınıyordu. İkisi
-- ayrışırsa sınav YEŞİL yanar ama mail YANLIŞ kademe gönderir - kusurun en
-- sinsi türü. Artık tek kaynak: sınav neyi sınıyorsa hat tam onu kullanıyor.
create or replace function public.marka_takip_bekleyen(p_tavan int default 500)
returns table (
  takip_id uuid, eposta text, jeton text, takip_ad text, takip_sinif int[],
  basvuru_no text, bulten_no int, ad text, sahip text, sinif int[],
  yayin_tarihi date, itiraz_son date, kalan_gun int,
  benzerlik real, ayni_sinif boolean, kademe text, sebep text,
  tur text, hatirlatma int)
language sql security definer set search_path = public, extensions as $$
  select t.id, t.eposta, t.jeton, t.ad, t.sinif,
         b.basvuru_no, b.bulten_no, b.ad, b.sahip, b.sinif,
         b.yayin_tarihi, b.itiraz_son, b.kalan_gun, b.benzerlik, b.ayni_sinif,
         b.kademe, b.sebep, b.tur, b.hatirlatma
    from public.marka_takip t
    cross join lateral (
      select x.basvuru_no, x.bulten_no, x.ad, x.sahip, x.sinif,
             x.yayin_tarihi, x.itiraz_son,
             (x.itiraz_son - current_date)::int                as kalan_gun,
             similarity(x.ad_norm, t.ad_norm)                  as benzerlik,
             (cardinality(t.sinif) > 0 and x.sinif && t.sinif) as ayni_sinif,
             public.marka_kademe_hesap(t.ad, x.ad)             as kademe,
             case public.marka_kademe_hesap(t.ad, x.ad)
               when 'YUKSEK' then
                 case when public.marka_norm_bosluklu(x.ad) ~ ('(^| )' || t.ad_norm)
                      then 'markanız bu başvuruda bir kelime olarak geçiyor'
                      else 'başvuru, markanızın kısaltılmış hâline benziyor' end
               when 'ORTA' then 'yazılış olarak yakın, uzunluk benzer'
               else 'yalnızca harf benzerliği'
             end as sebep,
             case when g.basvuru_no is null then 'ilk' else 'hatirlatma' end as tur,
             coalesce(g.hatirlatma, 0) as hatirlatma
        from public.marka_bulten x
        left join public.marka_takip_gonderim g
               on g.takip_id = t.id and g.basvuru_no = x.basvuru_no
       where x.ad_norm % t.ad_norm
         and x.itiraz_son >= current_date
         and (cardinality(t.sinif) = 0 or x.sinif && t.sinif)
         and x.ad_norm <> t.ad_norm
         and similarity(x.ad_norm, t.ad_norm) >= t.esik
         and (
           -- ilk uyarı: hiç yazmadıysak
           g.basvuru_no is null
           -- 1. hatırlatma: 20 gün kala
           or (g.hatirlatma < 1 and (x.itiraz_son - current_date) <= 20)
           -- 2. hatırlatma: 7 gün kala (son çağrı)
           or (g.hatirlatma < 2 and (x.itiraz_son - current_date) <= 7)
         )
       order by (cardinality(t.sinif) > 0 and x.sinif && t.sinif) desc,
                x.itiraz_son asc
       limit 200
    ) b
   where t.aktif
     -- ZAYIF olanlar MAİL LİSTESİNE GİRMEZ.
     and b.kademe <> 'ZAYIF'
   order by t.id, (b.kademe = 'YUKSEK') desc, b.itiraz_son asc
   limit least(greatest(p_tavan, 1), 5000);
$$;

-- İşaretleme: ilk gönderimde kayıt açar, hatırlatmada sayacı artırır.
create or replace function public.marka_takip_isaretle(
  p_takip_id uuid, p_kayitlar jsonb)
returns int
language plpgsql security definer set search_path = public as $$
declare v int;
begin
  insert into public.marka_takip_gonderim (takip_id, basvuru_no, bulten_no, hatirlatma)
  select p_takip_id, x->>'no', (x->>'bulten')::int, 0
    from jsonb_array_elements(p_kayitlar) x
  on conflict (takip_id, basvuru_no) do update
     set hatirlatma = public.marka_takip_gonderim.hatirlatma + 1,
         gonderim   = now();
  get diagnostics v = row_count;
  update public.marka_takip set son_uyari = now(), son_bakis = now()
   where id = p_takip_id;
  return v;
end;
$$;

revoke all     on function public.marka_takip_bekleyen(int) from public;
revoke execute on function public.marka_takip_bekleyen(int) from anon, authenticated;
revoke all     on function public.marka_takip_isaretle(uuid,jsonb) from public;
revoke execute on function public.marka_takip_isaretle(uuid,jsonb) from anon, authenticated;
