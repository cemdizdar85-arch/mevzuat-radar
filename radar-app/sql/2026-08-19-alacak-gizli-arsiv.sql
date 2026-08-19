-- ============================================================================
--  ALACAK ARSIVI — GIZLI KASA  (19.08.2026, Cem: "bilgiler gizli olsun kimse
--  gormesin, en onemli bu")
--
--  SORUN: veri/alacak-arsiv.json 4 MB'lik ACIK bir dosyaydi. 5.728 ilan +
--  2.083 borclu adi + 2.066 VKN + 1.657 TCKN tek tikla indirilebiliyordu.
--  Rakip de dahil herkes en degerli varligimizi kopyalayabilirdi; ustelik
--  TCKN'ler acik internette duruyordu (KVKK).
--
--  COZUM: veri tabloya tasinir, tabloya HIC KIMSE dogrudan erisemez (RLS acik,
--  policy YOK). Disariya yalnizca uc fonksiyon acilir; ucu de "toptan dokum"
--  yapamaz:
--    alacak_ara(...)    -> TEK sorgu, en fazla 25 satir, kisa sorgu reddedilir
--    alacak_toplu(...)  -> liste tarama; ABONE degilse 25 girdi + 3 acik kayit
--    alacak_sayi()      -> yalnizca adet (satir dondurmez)
--  TCKN hicbir fonksiyondan GERI DONMEZ; yalnizca esleme icin kullanilir.
--
--  Calistirma: Supabase SQL Editor (proje bjrleanjpyujtajmazxn) -> tek blok.
--  Blok uzunsa BOLUM BOLUM calistir (memory: buyuk blok kopyalarken kesiliyor).
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 1/5
--  Turkce harf katlama: istemcideki trFold() ile BIREBIR ayni sonucu verir
--  (I/İ -> I, Ğ -> G, Ü -> U, Ş -> S, Ö -> O, Ç -> C, aksanlilar sadelesir).
--  Ayni kural iki tarafta da uygulanmazsa "DIZDAR" araması "DİZDAR"i bulamaz.
-- ---------------------------------------------------------------------------
create extension if not exists pg_trgm;

create or replace function public.tr_fold(t text)
returns text
language sql
immutable
as $fn$
  -- LIKE joker karakterleri (% _ \) SILINIR: kullanici '%' yazip tum arsivi
  -- tarayamasin (joker enjeksiyonu). Turkce unvanlarda bu karakterler gecmez.
  select regexp_replace(
           regexp_replace(
             upper(translate(coalesce(t,''),
                   'ıİğĞüÜşŞöÖçÇâÂîÎûÛ',
                   'iIgGuUsSoOcCaAiIuU')),
             '[%_\\]', '', 'g'),
           '\s+', ' ', 'g')
$fn$;

-- Istek hizi freni. 2026-07-17-rate-limit.sql zaten calistiysa bu blok
-- degistirmez; calismadiysa burada kurulur (bu dosya tek basina yeterli olsun).
create table if not exists public.rate_log (
  ip text not null,
  ts timestamptz not null default now()
);
create index if not exists rate_log_ip_ts on public.rate_log (ip, ts);

create or replace function public.rate_limit_check(p_ip text, p_limit int, p_pencere_sn int default 60)
returns boolean
language plpgsql
security definer
set search_path = public
as $fn$
declare c int;
begin
  if p_ip is null or p_ip = '' then return true; end if;
  if random() < 0.05 then
    delete from rate_log where ts < now() - interval '10 minutes';
  end if;
  select count(*) into c from rate_log
    where ip = p_ip and ts > now() - make_interval(secs => p_pencere_sn);
  if c >= p_limit then return false; end if;
  insert into rate_log(ip) values (p_ip);
  return true;
end;
$fn$;
grant execute on function public.rate_limit_check(text, int, int) to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 2/5
--  Arsiv tablosu. RLS acik ve POLICY YOK => anon/authenticated icin tablo
--  gorunmez (PostgREST 0 satir doner). Yazma yalniz service_role (robot).
-- ---------------------------------------------------------------------------
create table if not exists public.alacak_ilan (
  ilan_no     text primary key,
  baslik      text,
  kurum       text,
  il          text,
  ilce        text,
  tarih       date,                 -- siralama/sure hesabi icin
  tarih_str   text,                 -- 'dd.MM.yyyy' — ekranda gosterilen bicim
  tur         text,                 -- konkordato / iflas / diger
  url         text,
  borclu      text,
  borclu_norm text,                 -- tr_fold(borclu) — yukleyici basar
  vkn         text,
  tckn        text,                 -- DISARIYA HIC DONMEZ, yalniz eslesme icin
  guncelleme  timestamptz default now()
);

alter table public.alacak_ilan enable row level security;
revoke all on public.alacak_ilan from anon, authenticated;

create index if not exists alacak_vkn_idx    on public.alacak_ilan (vkn)   where vkn  is not null;
create index if not exists alacak_tckn_idx   on public.alacak_ilan (tckn)  where tckn is not null;
create index if not exists alacak_tarih_idx  on public.alacak_ilan (tarih desc);
create index if not exists alacak_norm_idx   on public.alacak_ilan using gin (borclu_norm gin_trgm_ops);

-- ---------------------------------------------------------------- BOLUM 3/5
--  ABONELIK. Odeme su an EFT ile elden alindigi icin satirlari Cem doldurur:
--    insert into public.abonelikler(user_id,paket,radarlar,bitis)
--    values ('<auth.users.id>','tam','{alacak,marka,ihale,gumruk}', '2027-08-19');
--  paket: ucretsiz / tek / tam   —   'tam' butun radarlari acar.
-- ---------------------------------------------------------------------------
create table if not exists public.abonelikler (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  paket      text not null default 'ucretsiz',
  radarlar   text[] default '{}',
  durum      text not null default 'aktif',
  baslangic  date default current_date,
  bitis      date,
  not_       text,
  created_at timestamptz default now()
);
alter table public.abonelikler enable row level security;
-- Kullanici YALNIZ kendi aboneligini gorur; yazma yalniz service_role (Cem).
drop policy if exists "abonelik_select_own" on public.abonelikler;
create policy "abonelik_select_own" on public.abonelikler
  for select using (auth.uid() = user_id);

create or replace function public.alacak_abone_mi()
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from public.abonelikler a
    where a.user_id = auth.uid()
      and a.durum = 'aktif'
      and (a.bitis is null or a.bitis >= current_date)
      and (a.paket = 'tam' or 'alacak' = any(a.radarlar))
  )
$fn$;
grant execute on function public.alacak_abone_mi() to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 4/5
--  TEK SORGU. Anonim de calistirabilir (urunun vitrini bu). Korumalar:
--   * 7 haneden kisa rakam / 8 karakterden kisa ad reddedilir  -> tarama yapilamaz
--   * en fazla 25 satir doner                                   -> toptan dokum yok
--   * ayni IP dakikada 20 sorgu                                 -> otomat kazimasi yok
--   * tckn hicbir kolonda donmez
-- ---------------------------------------------------------------------------
create or replace function public.alacak_ara(p_sorgu text)
returns table (
  ilan_no text, baslik text, kurum text, il text, ilce text,
  tarih_str text, tur text, url text, borclu text, vkn text, tip text
)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  s     text := btrim(coalesce(p_sorgu,''));
  say   text := regexp_replace(s, '\D', '', 'g');
  ad    text := btrim(public.tr_fold(s));
  ip    text := coalesce(
                  split_part(current_setting('request.headers', true)::json->>'x-forwarded-for', ',', 1),
                  '');
begin
  if ip <> '' and not public.rate_limit_check('alacak:'||ip, 20, 60) then
    raise exception 'COK_HIZLI' using hint = 'Dakikada en fazla 20 sorgu.';
  end if;

  if length(say) >= 7 then
    return query
      select i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih_str, i.tur, i.url,
             i.borclu, i.vkn, 'vkn'::text
      from public.alacak_ilan i
      where (i.vkn is not null and (i.vkn = say or i.vkn like say||'%' or say like i.vkn||'%'))
         or (i.tckn is not null and length(say) = 11 and i.tckn = say)
      order by i.tarih desc nulls last
      limit 25;
  elsif length(ad) >= 8 or array_length(regexp_split_to_array(ad, ' '), 1) >= 2 then
    if length(ad) < 5 then
      raise exception 'KISA_SORGU' using hint = 'En az 5 harf ya da iki kelime yaz.';
    end if;
    return query
      select i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih_str, i.tur, i.url,
             i.borclu, i.vkn, 'ad'::text
      from public.alacak_ilan i
      where i.borclu_norm is not null and i.borclu_norm like '%'||ad||'%'
      order by i.tarih desc nulls last
      limit 25;
  else
    raise exception 'KISA_SORGU'
      using hint = 'Tam VKN/TCKN ya da en az iki kelimelik unvan yaz (tek kelime yanlis firma getirir).';
  end if;
end;
$fn$;
grant execute on function public.alacak_ara(text) to anon, authenticated;

-- Sayac: yalniz adet doner, satir DONDURMEZ (sayfadaki "N ilan tarandi" yazisi).
create or replace function public.alacak_sayi()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select jsonb_build_object(
    'adet',        (select count(*) from public.alacak_ilan),
    'borclulu',    (select count(*) from public.alacak_ilan where borclu is not null),
    'kimlikli',    (select count(*) from public.alacak_ilan where vkn is not null or tckn is not null),
    'guncelleme',  (select max(guncelleme) from public.alacak_ilan)
  )
$fn$;
grant execute on function public.alacak_sayi() to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 5/5
--  TOPLU TARAMA (Excel yukleme). Fiyat kapisi BURADA, tarayicida degil —
--  istemci kodu degistirilebilir, bu fonksiyon degistirilemez.
--    abone     : 5.000 girdiye kadar, kayitlarin tamami acik
--    abone degil: ilk 25 girdi taranir, en fazla 3 kayit ACIK, gerisi maskeli
--  Maskeli kayitta borclu adi yildizlanir, url/kurum bosalir; sayisi gorunur —
--  "kac riskli var" bedava, "kimler" abonelikte.
-- ---------------------------------------------------------------------------
create or replace function public.alacak_toplu(p_liste text[])
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  abone   boolean := public.alacak_abone_mi();
  tavan   int     := case when abone then 5000 else 25 end;
  acik    int     := case when abone then 1000000 else 3 end;
  liste   text[];
  toplam  int     := coalesce(array_length(p_liste,1), 0);
  sonuc   jsonb;
  ip      text := coalesce(
                    split_part(current_setting('request.headers', true)::json->>'x-forwarded-for', ',', 1),
                    '');
begin
  if toplam = 0 then
    return jsonb_build_object('abone', abone, 'taranan', 0, 'atlanan', 0,
                              'eslesme', 0, 'acik', 0, 'kayitlar', '[]'::jsonb);
  end if;
  if ip <> '' and not public.rate_limit_check('alacaktoplu:'||ip, case when abone then 60 else 6 end, 60) then
    raise exception 'COK_HIZLI' using hint = 'Toplu tarama dakikada sinirli.';
  end if;

  liste := p_liste[1:tavan];

  with q as (
    select distinct
      btrim(x)                              as ham,
      regexp_replace(x, '\D', '', 'g')      as say,
      btrim(public.tr_fold(x))              as ad
    from unnest(liste) as x
    where coalesce(btrim(x),'') <> ''
  ),
  e as (
    select q.ham, i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih, i.tarih_str,
           i.tur, i.url, i.borclu, i.vkn, 'vkn'::text as tip
    from q
    join public.alacak_ilan i
      on length(q.say) >= 7
     and ( (i.vkn is not null and (i.vkn = q.say or i.vkn like q.say||'%' or q.say like i.vkn||'%'))
        or (i.tckn is not null and length(q.say) = 11 and i.tckn = q.say) )
    union all
    select q.ham, i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih, i.tarih_str,
           i.tur, i.url, i.borclu, i.vkn, 'ad'::text
    from q
    join public.alacak_ilan i
      on length(q.say) < 7
     and length(q.ad) >= 8
     and i.borclu_norm is not null
     and i.borclu_norm like '%'||q.ad||'%'
  ),
  -- ayni (sorgu, ilan) cifti iki kez dusmesin; duserse VKN eslesmesi kazansin
  d as (
    select distinct on (ham, ilan_no)
           ham, ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url, borclu, vkn, tip
    from e
    order by ham, ilan_no, (tip = 'vkn') desc
  ),
  -- sira NUMARALANDIRMASI dedup'tan SONRA verilir (yoksa maskeleme kayar)
  t as (
    select d.*, row_number() over (order by d.tarih desc nulls last, d.ilan_no) as sira
    from d
  )
  select jsonb_build_object(
    'abone',   abone,
    'taranan', least(toplam, tavan),
    'atlanan', greatest(toplam - tavan, 0),
    'eslesme', (select count(*) from t),
    'acik',    (select count(*) from t where sira <= acik),
    'kayitlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'sorgu',  t.ham,
        'gizli',  (t.sira > acik),
        'tip',    t.tip,
        'tur',    t.tur,
        'tarih',  case when t.sira <= acik then t.tarih_str else null end,
        'baslik', case when t.sira <= acik then t.baslik else null end,
        'borclu', case when t.sira <= acik then t.borclu
                       else left(coalesce(t.borclu,'—'),1) || repeat('•', 9) end,
        'vkn',    case when t.sira <= acik then t.vkn
                       else case when t.vkn is null then null else left(t.vkn,3)||'•••••••' end end,
        'kurum',  case when t.sira <= acik then t.kurum else null end,
        'il',     case when t.sira <= acik then t.il else null end,
        'url',    case when t.sira <= acik then t.url else null end
      ) order by t.sira)
      from t
    ), '[]'::jsonb)
  ) into sonuc;

  return sonuc;
end;
$fn$;
grant execute on function public.alacak_toplu(text[]) to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 6/6
--  ROBOT YAZMA UCU. Duz PostgREST upsert'i KULLANMIYORUZ, cunku gunluk hasat
--  ilani borclu adi OLMADAN getirir; duz upsert onceki gun cikarilmis borclu/VKN
--  bilgisini NULL'lardi (zenginlestirme kaybi). coalesce ile eski deger korunur.
--  Yalniz service_role calistirabilir (robot) — anon/authenticated'a grant YOK.
-- ---------------------------------------------------------------------------
create or replace function public.alacak_yaz(p_kayitlar jsonb)
returns int
language plpgsql
security definer
set search_path = public
as $fn$
declare n int;
begin
  with g as (
    select
      k->>'ilanNo'                                   as ilan_no,
      nullif(btrim(coalesce(k->>'baslik','')),'')    as baslik,
      nullif(btrim(coalesce(k->>'kurum','')),'')     as kurum,
      nullif(btrim(coalesce(k->>'il','')),'')        as il,
      nullif(btrim(coalesce(k->>'ilce','')),'')      as ilce,
      to_date(nullif(k->>'tarih',''), 'DD.MM.YYYY')  as tarih,
      nullif(k->>'tarih','')                         as tarih_str,
      nullif(k->>'tur','')                           as tur,
      nullif(k->>'url','')                           as url,
      nullif(btrim(coalesce(k->>'borclu','')),'')    as borclu,
      nullif(regexp_replace(coalesce(k->>'vkn',''),'\D','','g'),'')  as vkn,
      nullif(regexp_replace(coalesce(k->>'tckn',''),'\D','','g'),'') as tckn
    from jsonb_array_elements(p_kayitlar) as k
    where coalesce(k->>'ilanNo','') <> ''
  ),
  y as (
    insert into public.alacak_ilan
      (ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url,
       borclu, borclu_norm, vkn, tckn, guncelleme)
    select g.ilan_no, g.baslik, g.kurum, g.il, g.ilce, g.tarih, g.tarih_str, g.tur, g.url,
           g.borclu, public.tr_fold(g.borclu), g.vkn, g.tckn, now()
    from g
    on conflict (ilan_no) do update set
      baslik      = coalesce(excluded.baslik,  alacak_ilan.baslik),
      kurum       = coalesce(excluded.kurum,   alacak_ilan.kurum),
      il          = coalesce(excluded.il,      alacak_ilan.il),
      ilce        = coalesce(excluded.ilce,    alacak_ilan.ilce),
      tarih       = coalesce(excluded.tarih,   alacak_ilan.tarih),
      tarih_str   = coalesce(excluded.tarih_str, alacak_ilan.tarih_str),
      tur         = coalesce(excluded.tur,     alacak_ilan.tur),
      url         = coalesce(excluded.url,     alacak_ilan.url),
      -- ZENGINLESTIRME KORUMASI: bos gelen borclu/VKN/TCKN eskisini SILMEZ
      borclu      = coalesce(excluded.borclu,  alacak_ilan.borclu),
      borclu_norm = coalesce(excluded.borclu_norm, alacak_ilan.borclu_norm),
      vkn         = coalesce(excluded.vkn,     alacak_ilan.vkn),
      tckn        = coalesce(excluded.tckn,    alacak_ilan.tckn),
      guncelleme  = now()
    returning 1
  )
  select count(*) into n from y;
  return n;
end;
$fn$;
revoke all on function public.alacak_yaz(jsonb) from anon, authenticated, public;
grant execute on function public.alacak_yaz(jsonb) to service_role;
grant execute on function public.alacak_sayi() to service_role;

-- Vitrin ozeti: sayfa acilisindaki "son 60 ilan + il dagilimi" bunu okur.
-- Satir dondurur ama SABIT 60 tavani var ve TCKN yok — dataset degil, vitrin.
create or replace function public.alacak_vitrin()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select jsonb_build_object(
    'adet',    (select count(*) from public.alacak_ilan),
    'son30',   (select count(*) from public.alacak_ilan where tarih >= current_date - 30),
    'son30Konkordato', (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='konkordato'),
    'son30Iflas',      (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='iflas'),
    'iller', coalesce((
      select jsonb_agg(x order by (x->>'t')::int desc) from (
        select jsonb_build_object('il', coalesce(nullif(il,''),'Belirtilmemiş'),
                                  't', count(*),
                                  'k', count(*) filter (where tur='konkordato'),
                                  'i', count(*) filter (where tur='iflas')) as x
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1 order by count(*) desc limit 12
      ) s
    ), '[]'::jsonb),
    'ilanlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'ilanNo', ilan_no, 'baslik', baslik, 'kurum', kurum, 'il', il,
        'tarih', tarih_str, 'tur', tur, 'url', url, 'borclu', borclu, 'vkn', vkn
      ) order by tarih desc nulls last)
      from (select * from public.alacak_ilan order by tarih desc nulls last limit 60) v
    ), '[]'::jsonb)
  )
$fn$;
grant execute on function public.alacak_vitrin() to anon, authenticated;

-- ============================================================================
--  DOGRULAMA — bu uc satir calistiginda beklenen:
--   (1) 0 satir  : tablo disaridan okunamiyor demektir (RLS calisiyor)  [anon ile]
--   (2) adet     : yuklenen ilan sayisi
--   (3) hata     : 'KISA_SORGU' — tek harfle tarama yapilamiyor
-- ============================================================================
-- select public.alacak_sayi();
-- select * from public.alacak_ara('1630432920');
-- select public.alacak_toplu(array['1630432920','6640819890']);
