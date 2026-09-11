-- ============================================================================
--  TETIKTE RAG MOTORU — 010_hesap_kalibi.sql
--  KONU KARTINA HESAP KALIBI: dogru hesaplar · tuzak hesaplar · tuzagin nedeni
--
--  IDEMPOTENT. ONKOSUL: 002_konu_madde basili.
--  ⛔ HENUZ BASILMADI - once Cem okur. UYGULANDI.md'ye satir dusulmedi.
--
--  ============================================================================
--  NEDEN (Cem, 11.09.2026)
--  ============================================================================
--  Cem: "LLM'in halusinasyon yapmasini engellemek icin PostgreSQL'den C# tarafina
--   cekip modele verecegimiz veri paketinin sablonunu yazabiliriz. Az once
--   konustugumuz 521/520 tuzagini sisteme nasil taniyacagimizin haritasidir."
--
--  DOGUSU: 11.09'da Cem muhur ornegindeki sgs-t1-fmuh-kolay/kp-80'de gercek hata
--  buldu. Iskat edilen hisse senetlerinin nominal ustu satisindan dogan fark
--  529 Diger Sermaye Yedekleri'ne atilmisti; dogrusu 521 Hisse Senedi Iptal
--  Karlari. Kok neden olculdu: soruya giden kaynak paketinde NE 521 NE 529 vardi
--  (paket TTK m.482 + THP 333 + THP 407 + THP 433 + VUK m.5 vergi mahremiyeti
--  idi). Model hesabi EZBERINDEN yazdi, hakem de gormedigi bir tanimi dayanak
--  gosterdi.
--
--  SINIF OLCULDU (636 basili soru): hesap kodunu ADIYLA anan 92 sorunun
--  66'sinda (%71,7) o hesabin tanimi kaynak paketinde yoktu.
--
--  ============================================================================
--  BU GOC NE EKLER — ve KAPI-HG'den farki
--  ============================================================================
--  KAPI-HG (11.09, motor/kalip-parti-uret.ps1) bir DEDEKTORDUR: soru yazildiktan
--  SONRA anilan hesabin grubunu cekip hakeme verir, yanlissa yakalar. Hatanin
--  parasi odenmis olur.
--
--  BU TABLO bir ONLEYICIDIR: konu kartinda "bu konuda dogru hesaplar sunlar,
--  tuzak hesaplar sunlar, tuzagin nedeni su" yazar. Uretici soruyu YAZARKEN
--  bunu gorur; hata hic yazilmaz.
--
--  Ikisi birlikte calisir: onleyici azaltir, dedektor kacani yakalar. Dedektor
--  ayrica bu tablonun KENDI dogrulugunu sinar - tablo yanlis doldurulmussa
--  KAPI-HG onu da yakalar.
--
--  ============================================================================
--  TASARIM KARARLARI ve GEREKCELERI
--  ============================================================================
--  1) AYRI TABLO, konu_madde'ye kolon EKLENMEDI.
--     konu_madde bir konu->madde eslesmesidir ve bir konunun BIRDEN COK maddesi
--     olabilir (uq_konu_madde (ders,konu,madde_deseni)). Hesap kalibi ise konu
--     BASINA tektir. Kolon eklenseydi ayni hesap listesi her madde satirinda
--     tekrarlanir, biri guncellenip digeri unutulurdu.
--
--  2) kural_metni SERBEST METIN DEGIL, ALINTI + KAYNAK ADI.
--     Halusinasyonu onlemek icin kurulan tablo, serbest metin alaninda kendisi
--     yeni bir halusinasyon yuzeyi olurdu. `kural_kaynak_ad` ambardaki GERCEK
--     kaynak_ad'dir; ck_kural_kaynakli kisiti kural metni varsa kaynagi da
--     zorunlu kilar.
--     ⚠ 11.09 dersi: Cem taslaginda "TDHP Izahnamesi" yazmisti; ambardaki ad
--     "MSUGT Sira No:1 Tekduzen Hesap Plani". Yanlis adla arama BOS doner.
--
--  3) TUZAK HESAP TEK BASINA YETMEZ, NEDENI ZORUNLU.
--     "520 yasak" demek modele bir sey ogretmez. "520 yeni cikarilan hisse
--     senedinin primli satisi icindir; burada senet YENI cikarilmiyor, IPTAL
--     edilen senedin yerine satiliyor" demek ogretir. Ayni cumle cozum
--     blogunda ogrenciye de gider. tuzaklar jsonb: [{kod, ad, neden}].
--
--  4) HARF SABITLENMEZ.
--     Cem taslaginda "A sikkina 520'li kaydi koy" yaziyordu. Harf sabitlemek
--     sik dengesi kapisini (KAPI-S) bozar - dogru sik parti icinde A-E'ye
--     dagitiliyor. Tuzak "bir yanlis sikka" konur, hangisine oldugunu dagitim
--     belirler.
--
--  5) ZORLUK ADLARI: kolay | zor | cokzor. BASKA AD YOK.
--     09.09'da "orta" adi uydurulmustu; veritabani 23514 ile reddetti ve para
--     ODENDIKTEN SONRA reddetti. ck_zorluk bunu bastan keser.
--
--  6) konu_id STABIL ANAHTAR (Cem'in fikri, alindi).
--     Bugun eslesme (ders, konu) METNI ile yapiliyor; konu adi degisince bag
--     kopuyor. konu_id degismez bir slug'dir; konu adi degisse de kalir.
--
--  7) dogrulandi VARSAYILAN false.
--     Model doldurur, INSAN muhurler. GVK kartlarinda ayni desen kullanildi
--     (22 kart dogrulandi=false ile girdi). Muhursuz kayit uretime GIREBILIR
--     ama karnede isaretlidir.
-- ============================================================================

begin;

-- ---------------------------------------------------------------- tablo -----
create table if not exists rag.konu_hesap_kalibi (
  konu_id            text    primary key,
  ders               text    not null,
  konu               text    not null,

  -- Kural: ambardaki metinden ALINTI + o metnin gercek kaynak_ad'i
  kural_metni        text,
  kural_kaynak_ad    text,          -- ornek: 'THP 521 - HİSSE SENEDİ İPTAL KARLARI'
  dayanak_madde      text,          -- ornek: 'TTK (6102 s.K.) m.482'  (ambardaki ad)

  -- Hesaplar. Kod = 3 haneli THP kodu, metin olarak (basindaki sifir korunur).
  dogru_hesaplar     text[]  not null default '{}',
  -- [{"kod":"520","ad":"Hisse Senedi İhraç Primleri","neden":"..."}]
  tuzaklar           jsonb   not null default '[]'::jsonb,

  zorluk             text,
  not_               text,
  dolduran           text    not null default 'model',   -- 'model' | 'insan'
  dogrulandi         boolean not null default false,     -- insan muhru
  olusturuldu        timestamptz not null default now(),
  guncellendi        timestamptz not null default now(),

  constraint uq_khk_ders_konu unique (ders, konu),

  -- Zorluk adi repo standardi disinda olamaz (09.09 'orta' kazasi)
  constraint ck_khk_zorluk
    check (zorluk is null or zorluk in ('kolay','zor','cokzor')),

  -- Kural metni varsa kaynagi da yazilir; kaynaksiz kural = halusinasyon
  constraint ck_khk_kural_kaynakli
    check (kural_metni is null or coalesce(kural_kaynak_ad,'') <> ''),

  -- Tuzak listesi dizi olmali
  constraint ck_khk_tuzak_dizi
    check (jsonb_typeof(tuzaklar) = 'array')
);

comment on table rag.konu_hesap_kalibi is
  'Konu basina hesap kalibi: dogru hesaplar, tuzak hesaplar ve tuzagin NEDENI. Uretici soruyu YAZARKEN gorur (onleyici); KAPI-HG yazildiktan SONRA dogrular (dedektor).';
comment on column rag.konu_hesap_kalibi.tuzaklar is
  'jsonb dizi: [{"kod":"520","ad":"...","neden":"tek cumle - neden BU olayda yanlis"}]. neden bos olamaz: sadece "yasak" demek modele bir sey ogretmez, cozum blogunda ogrenciye de bu cumle gider.';
comment on column rag.konu_hesap_kalibi.dogrulandi is
  'Model doldurur, INSAN muhurler. false = uretimde kullanilabilir ama karnede isaretli.';

create index if not exists ix_khk_arama
  on rag.konu_hesap_kalibi (rag.katla(ders), rag.katla(konu));

-- Her tuzak kaydinin nedeni dolu mu? (jsonb ici kisit CHECK ile zor; tetik ile)
create or replace function rag.khk_tuzak_denetle() returns trigger
language plpgsql as $fn$
declare t jsonb;
begin
  for t in select * from jsonb_array_elements(new.tuzaklar) loop
    if coalesce(t->>'kod','') = '' then
      raise exception 'tuzak kaydinda kod bos: %', t;
    end if;
    if coalesce(t->>'neden','') = '' then
      raise exception 'tuzak kaydinda neden bos (kod %). Sadece "yasak" demek yetmez.', t->>'kod';
    end if;
    if t->>'kod' !~ '^[1-7][0-9]{2}$' then
      raise exception 'tuzak kodu THP bicimine uymuyor (1xx-7xx): %', t->>'kod';
    end if;
  end loop;
  -- dogru hesaplar da THP bicimine uymali
  if exists (select 1 from unnest(new.dogru_hesaplar) k where k !~ '^[1-7][0-9]{2}$') then
    raise exception 'dogru_hesaplar icinde THP bicimine uymayan kod var';
  end if;
  -- ayni kod hem dogru hem tuzak olamaz
  if exists (
    select 1 from unnest(new.dogru_hesaplar) k
    where k in (select jsonb_array_elements(new.tuzaklar)->>'kod')
  ) then
    raise exception 'ayni hesap kodu hem dogru_hesaplar hem tuzaklar icinde';
  end if;
  new.guncellendi := now();
  return new;
end
$fn$;

drop trigger if exists tr_khk_denetle on rag.konu_hesap_kalibi;
create trigger tr_khk_denetle
  before insert or update on rag.konu_hesap_kalibi
  for each row execute function rag.khk_tuzak_denetle();

-- ---------------------------------------------------- uretici icin gorunum --
-- Uretici/C# tarafi TEK sorguyla paketi alir. Kaynak metinleri de burada birlesir,
-- boylece "modele hangi metni verdik" sorusunun tek cevabi olur.
create or replace view rag.hesap_paketi as
select
  k.konu_id, k.ders, k.konu,
  k.kural_metni, k.kural_kaynak_ad, k.dayanak_madde,
  k.dogru_hesaplar, k.tuzaklar, k.zorluk, k.dogrulandi,
  -- tuzak + dogru hesaplarin TUM gruplari (520 yazmasak da 52x gelir):
  (select array_agg(distinct left(kod,2) order by left(kod,2))
     from (
       select unnest(k.dogru_hesaplar) as kod
       union all
       select jsonb_array_elements(k.tuzaklar)->>'kod'
     ) t) as hesap_gruplari
from rag.konu_hesap_kalibi k;

comment on view rag.hesap_paketi is
  'Uretici bunu TEK sorguyla ceker. hesap_gruplari: anilan kodlarin grup onekleri - kaynak paketi grup bazinda cekilir ki kardes hesaplar da gorunsun (KAPI-HG mantigi, uretim tarafinda).';

commit;

-- ============================================================================
--  ORNEK KAYIT — Cem'in kp-80 vakasi (basildiktan SONRA elle girilecek)
--  Buraya YAZILMADI cunku goc dosyasi veri tasimaz; ornegi belgede tutuyoruz:
--
--  konu_id         : FMUH-SERMAYE-ISKAT
--  ders            : Finansal Muhasebe
--  konu            : sermaye taahhudu-hisse iptali
--  dayanak_madde   : TTK (6102 s.K.) m.482
--                    (m.483 DEGIL - 483 ihtar usulu, 482/2 iskat ve satis yetkisi.
--                     11.09'da ambardan okunarak duzeltildi.)
--  kural_kaynak_ad : THP 521 - HİSSE SENEDİ İPTAL KARLARI
--  kural_metni     : "Iptal edilen hisse senetlerinin bedellerine mahsuben
--                     yapilan odemelerin, bunlarin yerine cikarilan hisse
--                     senetlerinden elde edilen hasilat noksani kapatildiktan
--                     sonra artan kismin izlendigi hesaptir."  (ALINTI)
--  dogru_hesaplar  : {102,501,521}
--  tuzaklar        : [
--    {"kod":"520","ad":"Hisse Senedi İhraç Primleri",
--     "neden":"520 YENI cikarilan hisse senedinin primli satisi icindir; burada
--              senet yeni cikarilmiyor, IPTAL edilenin yerine satiliyor."},
--    {"kod":"529","ad":"Diğer Sermaye Yedekleri",
--     "neden":"529'un kendi tanimi 'bu hesap grubu icerisinde SAYILANLARIN
--              DISINDA kalan' der; 521 sayildigi icin olay 529'a dusemez."},
--    {"kod":"649","ad":"Diğer Olağan Gelir ve Karlar",
--     "neden":"Olay bir gelir degil SERMAYE YEDEGIDIR; gelir tablosuna gitmez."}
--  ]
--  zorluk          : cokzor
-- ============================================================================
