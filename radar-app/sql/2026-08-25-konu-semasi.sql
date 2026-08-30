-- ============================================================================
--  KONU ŞEMASI — 25.08.2026
--
--  CEM: "kesinlikle şemayı yapalım · her soruda tablo olmaz katılıyorum ama
--        şema ile konuyu daha iyi öğretiriz dersen onu yapalım"
--
--  NEDEN SORUYA DEĞİL KONUYA BAĞLI:
--  Ölçüm (25.08): kasada 2.263 tekil ders+konu var ve yığılma lehimize —
--  en çok soru içeren 300 konu kasanın %55'ini kapsıyor. Tek konu şeması
--  o konudaki BÜTÜN sorularda görünür. 30.569 şema yerine ~300 şema.
--  Örnek: "is sozlesmesi feshi" konusunda 1.389 soru var, tek şema besler.
--
--  NEDEN SVG DEĞİL JSON:
--  `yapi` alanı çizimin KENDİSİNİ değil TARİFİNİ tutar (kutular + bağlar).
--  SVG'yi tarayıcıda sema.js deterministik çizer. Üç sebep:
--   (1) Tasarım değişirse 300 şemayı yeniden ÜRETMEYİZ, tek dosyayı değiştiririz.
--   (2) Üç tema (açık/sepya/koyu) CSS değişkenleriyle kendiliğinden çalışır;
--       gömülü SVG rengi karanlık temada okunmaz.
--   (3) MODEL SVG YAZMAZ. Model yalnız yapıyı üretir; koordinat/taşma/kutudan
--       metin çıkması gibi kusurlar bu sayede imkânsız hale gelir ve 300 şema
--       birbirinin aynısı görünür.
--
--  DAMGA: soru_havuzu ile AYNI mantık — şema da mevzuata dayanır, mevzuat
--  değişince şema da bayatlar. `madde_damga` + `son_kontrol` bu yüzden var;
--  soru-dayanak-nöbetçisi bu tabloyu da tarayabilsin diye alan adları birebir.
--
--  GİZLİLİK: şema paralı içeriktir. RLS AÇIK, okuma yalnız paketli üyeye —
--  soru_havuzu'nun 27.07 politikasının birebir aynısı (paket ↔ sınav eşlemesi).
-- ============================================================================

create table if not exists public.konu_semasi (
  id           uuid primary key default gen_random_uuid(),
  sinav        text,                       -- SGS | SMMM | KGK | null (hepsi)
  ders         text not null,
  konu         text not null,
  tip          text not null,              -- akis | formul | zincir
  baslik       text not null,
  yapi         jsonb not null,             -- ÇİZİM TARİFİ (SVG DEĞİL) - sema.js okur
  dayanak      text,                       -- "İş K. (4857 s.K.) m.11"
  kanun_no     text,
  madde_no     text,
  madde_damga  text,                       -- ambardaki madde metninin damgası
  son_kontrol  timestamptz,
  yayin        boolean not null default false,
  uretim       text,                       -- 'deterministik' | model kimliği
  eklenme      timestamptz not null default now(),
  constraint konu_semasi_tip_ck check (tip in ('akis','formul','zincir'))
);

-- Bir ders+konu çiftinin TEK şeması olur. Aynı konuya ikinci şema yazılırsa
-- hangisinin doğru olduğu sorusu doğar - VERI-HARITASI'nın "iki otoriter kopya
-- olamaz" kuralı burada da geçerli.
create unique index if not exists konu_semasi_ders_konu_uk
  on public.konu_semasi (ders, konu);

-- deneme.html soruyu gösterirken ders+konu ile arar; yayın süzgeci ilk sırada.
create index if not exists konu_semasi_yayin_idx on public.konu_semasi (yayin);
create index if not exists konu_semasi_kanun_idx on public.konu_semasi (kanun_no, madde_no);

alter table public.konu_semasi enable row level security;

drop policy if exists "paketli uye semayi okur" on public.konu_semasi;
create policy "paketli uye semayi okur" on public.konu_semasi
  for select using (
    yayin = true
    and exists (
      select 1 from paket_uyeler pu
      where pu.user_id = auth.uid()
        and pu.bitis >= current_date
        and (
          pu.paket is null or lower(pu.paket) = 'tam'
          or (lower(pu.paket) = 'sgs'        and (konu_semasi.sinav is null or konu_semasi.sinav = 'SGS'))
          or (lower(pu.paket) = 'yeterlilik' and (konu_semasi.sinav is null or konu_semasi.sinav = 'SMMM'))
        )
    )
  );

-- Yazma yalnız robot (service_role) işidir; INSERT/UPDATE politikası bilerek YOK.


-- ============================================================================
--  ŞIK → ŞEMA DÜĞÜMÜ EŞLEMESİ  (soru_havuzu'na tek kolon)
--
--  CEM: "şema konu yada verdiği cevabı anlatacak, anlamadım"
--  Cevap: İKİSİ BİRDEN. Şema KONUYU anlatır (bir konu = bir şema), ama
--  öğrencinin İŞARETLEDİĞİ ŞIKKA göre üzerinde vurgulanır.
--
--  Bu kolon o köprüdür: hangi şık şemada hangi düğüme düşüyor.
--    {"A":"yok","B":"n4","C":"n4","D":"n4","E":"n5"}
--  "yok" = şıkkın iddiasının şemada KARŞILIĞI YOK (kanunda öyle bir dal
--  bulunmuyor) -> ekranda "bu dal kanunda yok" kutusu çıkar. Bu, öğrencinin
--  en çok öğrendiği an: yanlış şıkkın nerede DURDUĞUNU değil, hiç OLMADIĞINI
--  görür.
--
--  UCUZ OLAN TARAF BU: şema konu başına bir kez üretilir (~300 adet), eşleme
--  ise soru başına birkaç bayttır ve mevcut onarım partileriyle AYNI çağrıda
--  üretilebilir - ayrı parti, ayrı para gerekmez.
-- ============================================================================

alter table public.soru_havuzu
  add column if not exists sik_yolu jsonb;

comment on column public.soru_havuzu.sik_yolu is
  'Sik harfi -> konu_semasi.yapi icindeki dugum id. "yok" = semada karsiligi olmayan iddia.';


-- ============================================================================
--  KONU KARTI  (25.08.2026 — Cem: "TTK anlatacaksın, taciri anlatacaksın,
--  ilk önce onu anlat")
--
--  NEDEN VAR: urunun vaadi "konu okumadan, soru cozerek ogrenmek". Ama soru
--  "tacir" derken adayin tacirin ne oldugunu bildigini VARSAYIYORDU. Okunan
--  vaka (ALTIN-09): bes sik da TTK m.12'nin ayri bir dalina dokunuyor, ama
--  aday m.12'nin kac dali oldugunu, tacirligin ne getirdigini, esnaftan farkini
--  HIC ogrenmiyor. Soruyu cozuyor, konuyu ogrenmiyor.
--
--  KART, SORUDAN ONCE OKUNUR ve dort bolumu vardir:
--    1) ZEMIN     - konunun dayandigi temel kavram (tacir icin: ticari isletme)
--    2) KARISIR   - en cok karistirildigi komsu kavram (tacir <-> esnaf)
--    3) DALLAR    - konunun kac yolu/hali var (tacir olmanin 3 yolu)
--    4) SONUCLAR  - konu ne ise yarar, ne getirir (m.18 yukumlulukleri)
--
--  KART KONUYA BAGLIDIR, SORUYA DEGIL. Tek "Tacir" karti, tacir sifati +
--  tacir olmanin sonuclari + esnaf ayrimi konularindaki BUTUN sorulari besler.
--  Maliyet bir kez odenir (~0,02 USD/kart), soru sayisi arttikca amorti olur.
--
--  ⚠ KART YANLISSA HATA TEK SORUYA DEGIL O KONUDAKI BUTUN SORULARA DAGILIR.
--  Bu yuzden kart da soru ile AYNI 27 kapidan gecer ve birden fazla maddenin
--  TAM METNI okunmadan yazilmaz (tacir karti icin m.11+m.12+m.15+m.18).
-- ============================================================================

create table if not exists public.konu_karti (
  id            uuid primary key default gen_random_uuid(),
  sinav         text,
  ders          text not null,
  konu          text not null,
  baslik        text not null,              -- "Tacir"
  zemin         jsonb not null,             -- {baslik, metin, maddeler:[]}
  karisir       jsonb,                      -- {komsu, olcutler:[{olcut,komsu,konu}]}
  dallar        jsonb not null,             -- [{ad, madde, metin, tuzak}]
  sonuclar      jsonb,                      -- [{metin, madde}]
  akilda_kalsin text,
  dayanaklar    text[],                     -- okunan maddelerin TAMAMI
  madde_damga   text,
  son_kontrol   timestamptz,
  yayin         boolean not null default false,
  uretim        text,
  eklenme       timestamptz not null default now()
);

create unique index if not exists konu_karti_ders_konu_uk on public.konu_karti (ders, konu);
create index if not exists konu_karti_yayin_idx on public.konu_karti (yayin);

alter table public.konu_karti enable row level security;

drop policy if exists "paketli uye karti okur" on public.konu_karti;
create policy "paketli uye karti okur" on public.konu_karti
  for select using (
    yayin = true
    and exists (
      select 1 from paket_uyeler pu
      where pu.user_id = auth.uid()
        and pu.bitis >= current_date
        and (
          pu.paket is null or lower(pu.paket) = 'tam'
          or (lower(pu.paket) = 'sgs'        and (konu_karti.sinav is null or konu_karti.sinav = 'SGS'))
          or (lower(pu.paket) = 'yeterlilik' and (konu_karti.sinav is null or konu_karti.sinav = 'SMMM'))
        )
    )
  );

-- Soru hangi karta baglaniyor. Bos ise soru KARTSIZ demektir ve yayina GIREMEZ
-- (kart, urunun "konu ogretme" vaadinin tasiyicisidir).
alter table public.soru_havuzu
  add column if not exists konu_karti_id uuid references public.konu_karti(id);
