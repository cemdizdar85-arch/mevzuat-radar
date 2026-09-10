-- ============================================================================
--  TETIKTE RAG MOTORU — 006_gvk_kartlari.sql
--  GVK KONU KARTLARI + desen tuzagini kokten kapatan madde_kok()
--
--  IDEMPOTENT. ONKOSUL: 005_vektorsuz_arama basili, GVK-193 yutulmus olmali.
--  🔴 CEM ONAYI BEKLIYOR - onaysiz BASILMAZ.
--
--  ============================================================================
--  1) DESEN TUZAGI (10.09 farkedildi, basilmadan once)
--  ============================================================================
--  Kartlar madde_no'ya ILIKE deseniyle bagli. VUK kartlarinda desen '%m.261%'
--  biciminde. Bu desen GVK'da PATLAR:
--     '%m.70%'  -> m.70 ama ayni zamanda m.700, m.170, gec. m.70, muk. m.70
--     '%m.10%'  -> m.10 ama ayni zamanda m.100 ... m.109
--  GVK m.103 (gelir vergisi tarifesi) varken '%m.10%' deseni yanlis maddeyi
--  getirebilirdi. Wildcard ile madde secmek YANLIS YONTEM.
--
--  KOK COZUM: madde numarasi dilimlenirken sonuna " [1/3]" ekleniyor. Bu eki
--  soyan bir IMMUTABLE fonksiyon yazilir, eslesme KOK uzerinden yapilir.
--  Boylece desen wildcard'siz ve TAM olur: 'm.70' yalniz m.70'i tutar.
--  Eski '%...%' desenli VUK kartlari da calismaya devam eder (ilike korunuyor).
-- ============================================================================

create or replace function rag.madde_kok(p_madde text)
returns text
language sql
immutable
parallel safe
as $$
  select regexp_replace(coalesce(p_madde, ''), '\s*\[\d+/\d+\]\s*$', '')
$$;

comment on function rag.madde_kok is
  'Dilim ekini soyar: "m.70 [1/2]" -> "m.70". Kart eslesmesi bu kok uzerinden yapilir ki desen wildcard istemesin.';

-- ============================================================================
--  2) rag.konu_dayanak v3 — eslesme MADDE KOKU uzerinden
-- ============================================================================
create or replace function rag.konu_dayanak(
  p_ders text,
  p_konu text,
  p_adet int default 3
)
returns table (
  parca_id   bigint,
  kaynak_ad  text,
  madde_no   text,
  metin      text,
  oncelik    int,
  dogrulandi boolean
)
language sql
stable
as $$
  select p.id, k.ad, p.madde_no, p.metin, km.oncelik, km.dogrulandi
  from rag.konu_madde km
  join rag.kaynak k
    on (km.kaynak_kod is null or k.kod = km.kaynak_kod)
  join rag.parca p
    on p.kaynak_id = k.id
   and rag.madde_kok(p.madde_no) ilike km.madde_deseni
  where rag.katla(km.ders) = rag.katla(p_ders)
    and rag.katla(km.konu) = rag.katla(p_konu)
  order by km.oncelik, p.karakter_sayisi desc, p.sira
  limit greatest(coalesce(p_adet,3),1)
$$;

-- ============================================================================
--  3) GVK KONU KARTLARI — 17 konu
--
--  YONTEM: kelime aramasi ile KURULMADI. Ev kurali (10.08, uc kez olculdu):
--  "konu adindan kanuna kelime arayarak gidilmez - konu adi ogretim basligidir,
--  kanunun cumlesi degil." Her madde ambardan OKUNDU, icerigi konuyla
--  karsilastirildi, sonra kart yazildi.
--
--  dogrulandi = false ile girer. Cem okuyup onaylayana kadar kart "aday"dir;
--  SoruUretici kartin dogrulandi bayragini kutuge yazar, boylece onaysiz
--  karttan uretilen soru GORUNUR olur.
-- ============================================================================

insert into rag.konu_madde (ders, konu, kaynak_kod, madde_deseni, oncelik, not_, dogrulandi)
values
  -- --- Mukellefiyet ---------------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'gelirin tanimi ve unsurlari',
   'GVK-193', 'm.1', 1, 'Gelir = bir takvim yilinda elde edilen kazanc ve irat safi tutari.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'gelirin tanimi ve unsurlari',
   'GVK-193', 'm.2', 2, 'Yedi gelir unsuru sayimi.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'tam mukellefiyet',
   'GVK-193', 'm.3', 1, 'Turkiye icinde ve disinda elde edilen gelirin tamami.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'turkiyede yerlesme',
   'GVK-193', 'm.4', 1, 'Ikametgah + bir takvim yilinda alti aydan fazla oturma.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'dar mukellefiyet',
   'GVK-193', 'm.6', 1, 'Yerlesmis olmayanlar yalniz Turkiyede elde ettikleri kazanc uzerinden.', false),

  -- --- Ticari kazanc --------------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'ticari kazancin tanimi',
   'GVK-193', 'm.37', 1, 'Ticari/sinai faaliyetten dogan kazanc + sayilan yedi hal.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'bilanco esasinda ticari kazanc',
   'GVK-193', 'm.38', 1, 'Oz sermaye kiyaslamasi; isletmeye ilave ve cekilenlerin duzeltmesi.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'indirilecek giderler',
   'GVK-193', 'm.40', 1, 'Safi kazancin tespitinde indirilecek giderler.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'gider kabul edilmeyen odemeler',
   'GVK-193', 'm.41', 1, 'Kanunen kabul edilmeyen giderler (KKEG).', false),
  ('Vergi Mevzuatı ve Uygulaması', 'basit usulde ticari kazanc',
   'GVK-193', 'm.46', 1, 'Basit usulde kazanc tespiti; m.47-48 sartlarina baglidir.', false),

  -- --- Ucret ----------------------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'ucretin tanimi',
   'GVK-193', 'm.61', 1, 'Isverene tabi, belirli isyerine bagli calisma karsiligi.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'ucretin gercek safi degeri',
   'GVK-193', 'm.63', 1, 'Ucretten indirilecek unsurlar.', false),

  -- --- Serbest meslek -------------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'serbest meslek kazancinin tanimi',
   'GVK-193', 'm.65', 1, 'Sermayeden ziyade sahsi mesaiye dayanan faaliyet.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'serbest meslek kazancinda giderler',
   'GVK-193', 'm.68', 1, 'Serbest meslek kazancinin tespitinde indirilecek giderler.', false),

  -- --- Gayrimenkul sermaye iradi -------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'gayrimenkul sermaye iradi',
   'GVK-193', 'm.70', 1, 'Mal ve haklarin kiralanmasindan elde edilen irat.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'gayrimenkul sermaye iradinda giderler',
   'GVK-193', 'm.74', 1, 'Safi iradin bulunmasi: gercek gider / goturu gider.', false),

  -- --- Menkul sermaye iradi -------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'menkul sermaye iradi',
   'GVK-193', 'm.75', 1, 'Nakdi sermaye veya para ile temsil edilen degerlerden elde edilen irat.', false),

  -- --- Beyan ve tarh --------------------------------------------------------
  ('Vergi Mevzuatı ve Uygulaması', 'gelirin toplanmasi ve beyan',
   'GVK-193', 'm.85', 1, 'Mukellefler m.2deki kaynaklardan gelirlerini yillik beyannamede toplar.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'beyanname verilmeyecek haller',
   'GVK-193', 'm.86', 1, 'Yillik beyanname verilmeyen ve beyannameye dahil edilmeyen gelirler.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'diger indirimler',
   'GVK-193', 'm.89', 1, 'Matrahin tespitinde beyanname uzerinde yapilacak indirimler.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'vergi tevkifati',
   'GVK-193', 'm.94', 1, 'Stopaj yapmak zorunda olanlar ve tevkifata tabi odemeler.', false),
  ('Vergi Mevzuatı ve Uygulaması', 'gelir vergisi tarifesi',
   'GVK-193', 'm.103', 1, 'Artan oranli tarife. DIKKAT: tutarlar her yil degisir, soruya YAZILMAZ.', false)
on conflict (ders, konu, madde_deseni) do update
  set kaynak_kod = excluded.kaynak_kod,
      oncelik    = excluded.oncelik,
      not_       = excluded.not_,
      guncellendi = now();

-- ============================================================================
--  4) KART SAGLIK GORUNUMU — "kart var ama tuttugu parca yok" sessiz arizasi
--
--  004'un dersi: kart sessizce bos donebiliyordu ve fark edilmiyordu, cunku
--  arama yine de bir cevap uretiyordu. Sessiz basarisizligin panzehiri
--  gorunurluktur - bu gorunum her kartin KAC PARCA tuttugunu yazar.
-- ============================================================================
create or replace view rag.kart_sagligi as
select km.ders, km.konu, km.kaynak_kod, km.madde_deseni, km.oncelik, km.dogrulandi,
       count(p.id) as tuttugu_parca,
       coalesce(sum(length(p.metin)), 0) as toplam_krk,
       count(pv.parca_id) as vektorlu_parca
from rag.konu_madde km
left join rag.kaynak k on (km.kaynak_kod is null or k.kod = km.kaynak_kod)
left join rag.parca p
       on p.kaynak_id = k.id
      and rag.madde_kok(p.madde_no) ilike km.madde_deseni
left join rag.parca_vektor pv on pv.parca_id = p.id
group by km.ders, km.konu, km.kaynak_kod, km.madde_deseni, km.oncelik, km.dogrulandi
order by count(p.id), km.konu;

comment on view rag.kart_sagligi is
  'Her kartin kac parca tuttugu. tuttugu_parca = 0 olan kart OLU karttir - sessizce bos doner.';

create or replace function rag.surum()
returns text language sql immutable as $$
  select '006_gvk_kartlari / rag.ara v3 / konu_dayanak v3 (madde_kok ile eslesme) / GVK+VUK kartlari / vector(768) cosine HNSW(m=16,ef_c=64)'
$$;

insert into rag.schema_migrations (surum, aciklama)
values ('006_gvk_kartlari', 'madde_kok() + konu_dayanak v3 (wildcard desen tuzagi kapandi) + 22 GVK kart adayi (dogrulandi=false) + kart_sagligi gorunumu')
on conflict (surum) do nothing;
