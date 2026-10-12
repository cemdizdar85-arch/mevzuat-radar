-- ============================================================================
--  ANLIK TEKLİF — sonuç ekranında tek ders, kişiye özel, tek kullanımlık indirim  ·  12.10.2026
--
--  KARAR (Cem 12.10): "tek ders için 200 TL" · "süre olmasın, anlık gibi olsun". Yeterlilik seviye testi ve
--  Sınav Provası (YET-*) bitince EN ZAYIF derse tek ders teklifi; teklif o sonuç için bir kez gösterilir.
--  Staja Giriş'e bu turda YOK (Cem yalnız Yeterlilik tek ders için karar verdi); ayar tablosuna satır
--  eklenerek açılır, kod sınava bağlı değildir.
--
--  TASARIM (elçi kodundaki ilke: istemcideki hiçbir şey güvenlik değildir):
--    - Belirteç SUNUCUDA üretilir (anlik_teklif_al) ve HESABA bağlıdır (user_id = auth.uid()).
--      Bağlantıyı başkası açsa sipariş damgası 'TEKLIF_GECERSIZ' ile durur (başka hesap / girişsiz).
--    - (user_id, sonuc) tekil: aynı sonuç için ikinci çağrı NULL döner → teklif hesapta da "gösterildi".
--    - Sipariş yazılırken siparis_teklif_damga: belirteç bu hesabın mı, kullanılmamış mı, süresi geçmemiş mi,
--      paket ve ders tutuyor mu → anlik_teklif_tl'yi KENDİSİ damgalar, belirteci kullanıldı işaretler.
--      İkinci kullanım / sahte belirteç → 'TEKLIF_GECERSIZ' (sessizce indirimsiz yazılmaz: ekranda 988 görüp
--      1.188 borçlanmasın; satin-al.html hatayı görünce teklifi düşürür, tutarı yeniden gösterir).
--    - Bir hesap bir dersten anlık teklifi YALNIZ BİR KEZ kullanır (abartı çağrıya fren: sonuç kimliğini sunucu
--      doğrulayamaz; bkz. GÖRMEZ).
--    - Elçi indirimiyle ÜST ÜSTE BİNMEZ: teklif geçerliyse elçi kodu ve elçi indirimi bu siparişten düşer
--      (satin-al.html teklif varken kod kutusunu gizler; sunucu yine de zorlar).
--    - İndirim siparişte AYRI kolonda: siparisler.anlik_teklif_tl (elçinin indirim_tl'si değişmez) +
--      teklif_belirtec. Kurucu sayacı / paket_secim_sayac yalnız sipariş SAYAR → etkilenmez. iyzico-odeme.ts
--      beklenen tutara bu kolonu da düşer.
--    - Sunucu geçerliliği 24 saat (sızan bağlantı sonsuza dek açık kalmasın). Ekranda süre/sayaç YAZILMAZ;
--      teklif ekranı tek gösterimlik olduğu için "sayfadan çıkınca kalkar" cümlesi doğrudur (sonuç sayfası
--      yenilenince/geri gelince bir daha çizilmez — cihaz işareti + bu tablonun tekil anahtarı).
--
--  🚫 GÖRMEZ: teklifi isteyen kişinin testi gerçekten çözüp çözmediği (sonuç kimliği istemciden gelir) ·
--     aynı kişinin ikinci hesap açması. Fren: hesap başına ders başına 1 kullanım + 24 saatte en çok 10 teklif.
--  ⚠ Ders adları fiyat-motoru.js DERSLER.yeterlilik ile BİREBİR (paket_uyeler.dersler de aynı adları taşır).
--  ⚠ İndirim tutarı fiyat-motoru.js ANLIK_TEKLIF.indirim ile AYNI olmalı (ekran gösterimi oradan).
--  Push ile otomatik uygulanır (sql-uygula.yml). Tekrar basımı güvenli (if not exists / create or replace).
--  GERİ ALMA: drop trigger siparis_teklif_damga on siparisler; drop function anlik_teklif_al, anlik_teklif_kontrol;
--             (kolonlar ve tablo kayıt olarak kalır).
-- ============================================================================

-- 1) SİPARİŞTE AYRI ALAN
alter table public.siparisler add column if not exists anlik_teklif_tl integer not null default 0;
alter table public.siparisler add column if not exists teklif_belirtec text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_anlik_teklif_aralik') then
    alter table public.siparisler add constraint siparisler_anlik_teklif_aralik check (anlik_teklif_tl between 0 and 5000);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'siparisler_teklif_belirtec_bicim') then
    alter table public.siparisler add constraint siparisler_teklif_belirtec_bicim check (teklif_belirtec is null or teklif_belirtec ~ '^[0-9a-f]{32}$');
  end if;
end $$;

-- 2) AYAR — hangi pakette kaç TL (tek yer). Yeni sınav/paket = yeni satır.
create table if not exists public.anlik_teklif_ayar (
  paket            text primary key check (length(paket) <= 40),
  sinav            text not null check (sinav in ('sgs', 'yeterlilik', 'kgk')),
  indirim_tl       integer not null check (indirim_tl between 1 and 2000),
  gecerlilik_saat  integer not null default 24 check (gecerlilik_saat between 1 and 72),
  acik             boolean not null default true
);
alter table public.anlik_teklif_ayar enable row level security;
revoke all on public.anlik_teklif_ayar from anon, authenticated;
insert into public.anlik_teklif_ayar (paket, sinav, indirim_tl, gecerlilik_saat, acik)
values ('yeterlilik-1', 'yeterlilik', 200, 24, true)          -- Cem 12.10: tek ders 1.188 → 988, KDV dahil
on conflict (paket) do update set sinav = excluded.sinav, indirim_tl = excluded.indirim_tl,
  gecerlilik_saat = excluded.gecerlilik_saat, acik = excluded.acik;

-- 3) TEKLİFLER — kim, hangi sonuç, hangi ders; kullanılınca sipariş no
create table if not exists public.anlik_teklif (
  belirtec    text primary key check (belirtec ~ '^[0-9a-f]{32}$'),
  user_id     uuid not null,                                   -- auth.users'a FK YOK (14.09 PostgREST kesintisi)
  sonuc       text not null check (sonuc ~ '^[A-Za-z0-9:._-]{4,80}$'),
  kaynak      text not null check (kaynak in ('seviye', 'prova')),
  paket       text not null check (length(paket) <= 40),
  ders        text not null check (length(ders) <= 80),
  indirim_tl  integer not null check (indirim_tl between 1 and 2000),
  olusturma   timestamptz not null default now(),
  son         timestamptz not null,
  kullanildi  timestamptz,
  siparis_no  text
);
create unique index if not exists anlik_teklif_kisi_sonuc on public.anlik_teklif (user_id, sonuc);
create index if not exists anlik_teklif_kisi_ders on public.anlik_teklif (user_id, ders) where kullanildi is not null;
alter table public.anlik_teklif enable row level security;
revoke all on public.anlik_teklif from anon, authenticated;

-- 4) TEKLİF AL — sonuç ekranı (girişliyse) ya da satin-al.html (girişten sonra) çağırır.
--    Dönen: {belirtec, paket, ders, indirim_tl} · NULL = gösterme (girişsiz / bu sonuç için zaten verildi /
--    o dersi kapsayan paketi var / o dersten teklifi daha önce kullandı / ayar kapalı / fren).
create or replace function public.anlik_teklif_al(p_sonuc text, p_kaynak text, p_ders text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_ayar  anlik_teklif_ayar%rowtype;
  v_b     text;
  v_son   timestamptz;
begin
  if v_uid is null then return null; end if;
  if coalesce(p_kaynak, '') not in ('seviye', 'prova') then return null; end if;
  if coalesce(p_sonuc, '') !~ '^[A-Za-z0-9:._-]{4,80}$' then return null; end if;
  -- bu turda yalnız Yeterlilik tek ders (ders adları fiyat-motoru.js DERSLER.yeterlilik)
  if p_ders is null or not (p_ders = any (array['Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi',
       'Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Hukuk','Sermaye Piyasası Mevzuatı','Meslek Hukuku'])) then
    return null;
  end if;
  select * into v_ayar from anlik_teklif_ayar where paket = 'yeterlilik-1' and acik;
  if not found then return null; end if;

  if exists (select 1 from anlik_teklif where user_id = v_uid and sonuc = p_sonuc) then return null; end if;
  if exists (select 1 from anlik_teklif where user_id = v_uid and ders = p_ders and kullanildi is not null) then return null; end if;
  if (select count(*) from anlik_teklif where user_id = v_uid and olusturma > now() - interval '24 hours') >= 10 then return null; end if;
  -- o dersi zaten kapsayan açık paketi varsa teklif anlamsız
  if exists (select 1 from paket_uyeler p where p.user_id = v_uid and p.bitis >= current_date
               and (p.paket in ('yeterlilik-tum', 'yeterlilik-kgk', 'tam')
                    or (p.paket ~ '^yeterlilik-[1-4]$' and p_ders = any (coalesce(p.dersler, array[]::text[]))))) then
    return null;
  end if;

  v_b   := replace(gen_random_uuid()::text, '-', '');
  v_son := now() + make_interval(hours => v_ayar.gecerlilik_saat);
  insert into anlik_teklif (belirtec, user_id, sonuc, kaynak, paket, ders, indirim_tl, son)
  values (v_b, v_uid, p_sonuc, p_kaynak, v_ayar.paket, p_ders, v_ayar.indirim_tl, v_son)
  on conflict (user_id, sonuc) do nothing;
  if not found then return null; end if;                          -- yarış: aynı anda iki çağrı
  return jsonb_build_object('belirtec', v_b, 'paket', v_ayar.paket, 'ders', p_ders, 'indirim_tl', v_ayar.indirim_tl);
end $$;
revoke all on function public.anlik_teklif_al(text, text, text) from public;
revoke execute on function public.anlik_teklif_al(text, text, text) from anon;
grant execute on function public.anlik_teklif_al(text, text, text) to authenticated;

-- 5) TEKLİF KONTROL — satin-al.html "bu belirteç BENİM için geçerli mi?" diye sorar (kişisel veri dönmez).
create or replace function public.anlik_teklif_kontrol(p_belirtec text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object('belirtec', t.belirtec, 'paket', t.paket, 'ders', t.ders, 'indirim_tl', t.indirim_tl)
    from anlik_teklif t
   where t.belirtec = lower(coalesce(p_belirtec, ''))
     and auth.uid() is not null and t.user_id = auth.uid()
     and t.kullanildi is null and t.son > now()
     and not exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null);
$$;
revoke all on function public.anlik_teklif_kontrol(text) from public;
revoke execute on function public.anlik_teklif_kontrol(text) from anon;
grant execute on function public.anlik_teklif_kontrol(text) to authenticated;

-- 6) SİPARİŞ DAMGASI — tetikleyici adı 'siparis_teklif_damga' > 'siparis_elci_damga' (alfabetik sıra): elçi
--    damgasından SONRA koşar, üst üste binmeyi burada keser. Tarayıcının yolladığı anlik_teklif_tl her durumda EZİLİR.
create or replace function public.siparis_teklif_damga()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  t anlik_teklif%rowtype;
begin
  new.anlik_teklif_tl := 0;
  new.teklif_belirtec := nullif(lower(btrim(coalesce(new.teklif_belirtec, ''))), '');
  if new.teklif_belirtec is null then
    return new;
  end if;

  select * into t from anlik_teklif where belirtec = new.teklif_belirtec for update;
  if not found
     or auth.uid() is null or t.user_id <> auth.uid()
     or t.kullanildi is not null
     or t.son <= now()
     or t.paket <> new.paket
     or not (t.ders = any (coalesce(new.secilen_dersler, array[]::text[])))
     or exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null) then
    raise exception 'TEKLIF_GECERSIZ' using hint = 'Anlık teklif bu hesapta geçerli değil ya da kullanıldı.';
  end if;

  update anlik_teklif set kullanildi = now(), siparis_no = new.siparis_no where belirtec = t.belirtec;
  new.anlik_teklif_tl := t.indirim_tl;
  -- elçi indirimiyle üst üste binmez
  new.elci_kodu := null;
  new.indirim_tl := 0;
  new.elci_sabit_komisyon_tl := null;
  return new;
end $$;

drop trigger if exists siparis_teklif_damga on public.siparisler;
create trigger siparis_teklif_damga
  before insert on public.siparisler
  for each row execute function public.siparis_teklif_damga();

-- 7) YÖNETİM ÖZETİ — 2026-10-04-yonetim-ozet.sql AYNEN + siparişte 'anlik_teklif' (yonetim.html "Anlık teklif" diye yazar)
create or replace function public.yonetim_ozet()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare sonuc jsonb;
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'olcum', now(),
    'uyeler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'eposta', u.email,
        'kayit', u.created_at,
        'son_giris', u.last_sign_in_at,
        'yol', coalesce(u.raw_user_meta_data->>'kaynak', 'site'),
        'kayit_elci', nullif(u.raw_user_meta_data->>'elci_kodu', ''),
        'paket', p.paket,
        'bitis', p.bitis,
        'dersler', p.dersler,
        'hediye', exists (select 1 from public.paket_hediye h where h.user_id = u.id and h.iptal is null),
        'siparis_elci', (select s.elci_kodu from public.siparisler s
                          where lower(s.email) = lower(u.email) and s.elci_kodu is not null
                          order by s.olusturma desc limit 1),
        'siparis_paket', (select s.paket from public.siparisler s
                           where lower(s.email) = lower(u.email) order by s.olusturma desc limit 1),
        'cozdugu', (select string_agg(distinct o.sinav, ',') from public.ogrenci_sonuc o where o.user_id = u.id)
      ) order by u.created_at desc)
      from auth.users u
      left join public.paket_uyeler p on p.user_id = u.id
    ), '[]'::jsonb),
    'siparisler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'no', s.siparis_no, 'paket', s.paket, 'tutar', s.tutar, 'durum', s.durum,
        'elci', s.elci_kodu, 'indirim', s.indirim_tl, 'anlik_teklif', s.anlik_teklif_tl, 'ad', s.ad_soyad, 'eposta', s.email,
        'tarih', s.olusturma, 'odendi', s.odendi_tarihi
      ) order by s.olusturma desc)
      from public.siparisler s
    ), '[]'::jsonb),
    'elciler', coalesce((
      select jsonb_agg(jsonb_build_object('kod', e.kod, 'ad', e.ad_soyad, 'aktif', e.aktif) order by e.olusturma)
      from public.elciler e
    ), '[]'::jsonb)
  ) into sonuc;
  return sonuc;
end
$$;
revoke all on function public.yonetim_ozet() from public, anon;
grant execute on function public.yonetim_ozet() to authenticated;

-- 8) GÖÇ İÇİ ÖZ-SINAV — gerçek tablolar ve tetikleyicilerle, iki sahte hesap kimliğiyle (auth.users'ta yoklar; FK yok).
--    Hepsi alt işlemde koşar ve sonunda 'OLCU_TAMAM' fırlatılarak GERİ ALINIR: tabloda iz kalmaz (pg_net kuyruğu da
--    işlemle geri alınır). Bir vaka tutmazsa göç KIRMIZI düşer, hiçbir şey uygulanmaz (sql-uygula.yml -1).
--    Vakalar: teklif üretilir · aynı sonuç ikinci teklif vermez · sipariş 200 TL damgalanır + elçi indirimi düşer ·
--    aynı belirteç ikinci siparişte reddedilir · kullanılan dersten yeni teklif çıkmaz · başka hesap belirteci kullanamaz ·
--    girişsiz kullanamaz · paket/ders tutmazsa reddedilir · tarayıcının yazdığı anlik_teklif_tl ezilir.
do $$
declare
  a constant text := '00000000-0000-4000-8000-0000000000a1';
  b constant text := '00000000-0000-4000-8000-0000000000b2';
  v jsonb; v2 jsonb; n int; e int;

begin
  begin
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a, true);
    if auth.uid()::text <> a then raise exception 'OLCU: auth.uid taklidi tutmadi'; end if;

    v := public.anlik_teklif_al('olcu-svy-1', 'seviye', 'Hukuk');
    if v is null or (v->>'indirim_tl')::int <> 200 or v->>'paket' <> 'yeterlilik-1' then raise exception 'OLCU: teklif uretilmedi %', v; end if;
    if public.anlik_teklif_al('olcu-svy-1', 'seviye', 'Hukuk') is not null then raise exception 'OLCU: ayni sonuc ikinci teklif verdi'; end if;
    if public.anlik_teklif_al('olcu-x', 'seviye', 'Uydurma Ders') is not null then raise exception 'OLCU: listede olmayan ders kabul edildi'; end if;
    if public.anlik_teklif_kontrol(v->>'belirtec') is null then raise exception 'OLCU: kontrol gecerli belirteci tanimadi'; end if;

    -- 1. sipariş: 988'e kilit + elçi düşer + tarayıcının yolladığı anlik_teklif_tl ezilir
    insert into public.siparisler (siparis_no, paket, paket_ad, tutar, secilen_dersler, ad_soyad, email, odeme, durum, teklif_belirtec, anlik_teklif_tl, indirim_tl)
    values ('TT-20261012-AAAA', 'yeterlilik-1', 'Yeterlilik — 1 ders', 988, array['Hukuk'], 'Olcu Deneme', 'olcu@tetikte.invalid', 'havale', 'odeme_bekliyor', v->>'belirtec', 999, 77);
    select anlik_teklif_tl, indirim_tl into n, e from public.siparisler where siparis_no = 'TT-20261012-AAAA';
    if n <> 200 or e <> 0 then raise exception 'OLCU: damga yanlis anlik=% elci=%', n, e; end if;
    if (select siparis_no from public.anlik_teklif where belirtec = v->>'belirtec') <> 'TT-20261012-AAAA' then raise exception 'OLCU: belirtec kullanildi isaretlenmedi'; end if;
    if public.anlik_teklif_kontrol(v->>'belirtec') is not null then raise exception 'OLCU: kullanilmis belirtec kontrolde gecerli'; end if;

    -- 2. kullanım reddedilir
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-AAAC', 'yeterlilik-1', 988, array['Hukuk'], 'Olcu Deneme', 'olcu@tetikte.invalid', v->>'belirtec');
      raise exception 'OLCU: ikinci kullanim kabul edildi';
    exception when others then
      if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if;
    end;
    -- kullanılmış dersten yeni teklif çıkmaz
    if public.anlik_teklif_al('olcu-prova-1', 'prova', 'Hukuk') is not null then raise exception 'OLCU: kullanilan dersten yeni teklif cikti'; end if;

    -- başka ders, yanlış ders seçimi reddedilir
    v2 := public.anlik_teklif_al('olcu-prova-2', 'prova', 'Meslek Hukuku');
    if v2 is null then raise exception 'OLCU: ikinci ders teklifi uretilmedi'; end if;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-AAAD', 'yeterlilik-1', 988, array['Hukuk'], 'Olcu Deneme', 'olcu@tetikte.invalid', v2->>'belirtec');
      raise exception 'OLCU: ders tutmayan siparis kabul edildi';
    exception when others then
      if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if;
    end;

    -- başka hesap aynı belirteci kullanamaz
    perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', b, true);
    if public.anlik_teklif_kontrol(v2->>'belirtec') is not null then raise exception 'OLCU: baska hesap kontrolde gecerli gordu'; end if;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-AAAE', 'yeterlilik-1', 988, array['Meslek Hukuku'], 'Baska Kisi', 'baska@tetikte.invalid', v2->>'belirtec');
      raise exception 'OLCU: baska hesap belirteci kullandi';
    exception when others then
      if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if;
    end;

    -- girişsiz kullanamaz
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    begin
      insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, teklif_belirtec)
      values ('TT-20261012-AAAF', 'yeterlilik-1', 988, array['Meslek Hukuku'], 'Girissiz', 'anon@tetikte.invalid', v2->>'belirtec');
      raise exception 'OLCU: girissiz belirtec kullandi';
    exception when others then
      if sqlerrm not like '%TEKLIF_GECERSIZ%' then raise; end if;
    end;
    if public.anlik_teklif_al('olcu-anon', 'seviye', 'Hukuk') is not null then raise exception 'OLCU: girissize teklif verildi'; end if;

    -- belirteçsiz sipariş: tarayıcının yazdığı anlik_teklif_tl ezilir
    insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, anlik_teklif_tl)
    values ('TT-20261012-AAAH', 'yeterlilik-1', 1188, array['Hukuk'], 'Teklifsiz', 'yok@tetikte.invalid', 500);
    if (select anlik_teklif_tl from public.siparisler where siparis_no = 'TT-20261012-AAAH') <> 0 then raise exception 'OLCU: belirtecsiz indirim ezilmedi'; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261012-AA%') or exists (select 1 from public.anlik_teklif where sonuc like 'olcu-%') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'ANLIK TEKLIF OZ-SINAV: 15 vaka TAMAM (geri alindi)';
end $$;

-- ÖLÇÜ (uygulama sonrası):
--   select column_name from information_schema.columns where table_name='siparisler' and column_name in ('anlik_teklif_tl','teklif_belirtec');  -- 2
--   select * from anlik_teklif_ayar;                                         -- yeterlilik-1 | yeterlilik | 200 | 24 | t
--   select tgname from pg_trigger where tgrelid='public.siparisler'::regclass and not tgisinternal order by tgname;  -- ... siparis_elci_damga, ..., siparis_teklif_damga
--   anon: POST /rest/v1/rpc/anlik_teklif_al → 401/404 (yalnız authenticated)
