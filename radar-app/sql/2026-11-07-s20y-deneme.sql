-- ============================================================================
--  YETERLİLİK SON 20 GÜN — DERS DERS DENEME  ·  07.11.2026 (site kolu)
--
--  CEM 07.11: "1. denemeyi site koluna yükleme için onaylıyor musun?" → "Evet, onaylıyorum"; göç için "Göçü bu akşam basalım evet".
--  8 Kasım'da yalnız 8 dersin 1. denemesi açılır, sonrakiler sırayla.
--
--  NEDEN AYRI TABLOLAR: SGS denemesi bir bütündür (no = deneme, içinde 15 ders). Yeterlilik'te ders başına 5 ayrı deneme var, üye yalnız
--  paketindeki dersleri görür, söz ders ders sayılır. Aynı tabloya sinav sütunu eklemek çalışan SGS fonksiyonlarını değiştirirdi; 1–21 Kasım
--  arası SGS üyeleri çözüyor. Bu göç SGS'nin hiçbir tablo ya da fonksiyonuna dokunmaz.
--
--  NE YAPAR:
--   s20y_deneme   (ders, no 1–5): ad, süre 45 dk, açılış, kalite onayı. AÇIK = kalite_onay dolu + acilis <= now().
--   s20y_soru     denemenin 20 sorusu (veri tam). anon/authenticated OKUYAMAZ. Kimlik bütün denemelerde tektir.
--   s20y_sonuc    deneme başına İLK çözüm (söz bunu sayar).
--   s20y_gorev    yalnız %60 altı denemeden sonra (kampanya koşulları §5): o dersin yanlış/boş konuları, en çok 5 konu × 4 yeni soru.
--   s20y_yarim    bitmemiş denemenin cevapları + kalan süre: cihaz değişse de kaldığı yerden sürer. Bitince silinir.
--   s20y_onizleme açılıştan önce sınama için üye listesi; yalnız servis anahtarı yazar. Boş durur.
--   s20y_erisim(ders)   son20-yet · tam · kurucu · yeterlilik* ; dersler dolu üye yalnız seçtiği dersler (paket_erisim_var ile aynı).
--   s20y_liste()        ders ders denemeler + bu kişinin ilk çözümleri + görevleri (anon da çağırır: sonuçsuz, erişimsiz).
--   s20y_test_getir     sorular DOĞRUSUZ, AÇIKLAMASIZ + kayıtlı yarım.
--   s20y_test_bitir     puanı SUNUCU hesaplar, ilk çözümü yazar, doğru + tam veriyi ancak burada döndürür.
--   s20y_yarim_yaz      cevapları süzerek yazar (yalnız bu denemenin kimlikleri, A–E).
--   s20y_gorev_getir / s20y_gorev_cevap   SGS görev akışının Yeterlilik karşılığı (banka sinav='smmm').
--   s20y_deneme_yukle   YALNIZ servis anahtarı; tam 20 soru ister, çözülmüş deneme zorla'sız değişmez.
--  KİLİT: aynı derste önceki açılmış deneme bitmeden ya da o derste açık görev varken çözülmemiş deneme açılmaz. Dersler birbirini kilitlemez.
--  🚫 GÖRMEZ: söz hakkının hukuki durumu (1 Kasım öncesi şartsız üye; siparisler.soz_hakki) · 28 Ekim öncesi 3'te 2 şartı · konu adı bankada
--     birebir eşleşmeyen konular (görev çıkmaz; D1'de 139 konunun 22'si) · istemci sayacının dürüstlüğü (süre puanı etkilemez).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (bütün satırlar geri alınır).
--  GERİ ALMA: s20y_* tablo ve fonksiyonları düşürülür; SGS etkilenmez.
-- ============================================================================

create table if not exists public.s20y_deneme (
  ders        text not null,
  no          integer not null check (no between 1 and 5),
  ad          text not null,
  sure_dk     integer not null default 45 check (sure_dk between 1 and 400),
  acilis      timestamptz,
  kalite_onay text,
  yuklenme    timestamptz not null default now(),
  primary key (ders, no)
);
create table if not exists public.s20y_soru (
  ders  text not null,
  no    integer not null,
  id    text not null unique,
  sira  integer not null,
  konu  text,
  veri  jsonb not null,
  primary key (ders, no, id),
  foreign key (ders, no) references public.s20y_deneme(ders, no) on delete cascade
);
create index if not exists s20y_soru_sira on public.s20y_soru (ders, no, sira);
create table if not exists public.s20y_sonuc (
  user_id uuid not null references auth.users(id) on delete cascade,
  ders    text not null,
  no      integer not null,
  dogru   integer not null,
  yanlis  integer not null,
  bos     integer not null,
  toplam  integer not null,
  cevap   jsonb not null,
  sure_sn integer,
  zaman   timestamptz not null default now(),
  primary key (user_id, ders, no)
);
create table if not exists public.s20y_gorev (
  user_id   uuid not null references auth.users(id) on delete cascade,
  ders      text not null,
  no        integer not null,
  konu      text not null,
  sira      integer not null,
  yanlis    integer not null,
  tur       integer not null default 1,
  sorular   text[] not null,
  gorulen   text[] not null default '{}',
  yanlislar text[] not null default '{}',
  cevap     jsonb not null default '{}'::jsonb,
  dogru     integer not null default 0,
  tamam     boolean not null default false,
  olusturma timestamptz not null default now(),
  bitis     timestamptz,
  primary key (user_id, ders, no, konu)
);
create table if not exists public.s20y_yarim (
  user_id uuid not null references auth.users(id) on delete cascade,
  ders    text not null,
  no      integer not null,
  cevap   jsonb not null default '{}'::jsonb,
  i       integer not null default 0,
  kalan   integer,
  zaman   timestamptz not null default now(),
  primary key (user_id, ders, no)
);
create table if not exists public.s20y_onizleme (
  user_id uuid primary key references auth.users(id) on delete cascade,
  neden   text not null,
  zaman   timestamptz not null default now()
);
alter table public.s20y_deneme   enable row level security;
alter table public.s20y_soru     enable row level security;
alter table public.s20y_sonuc    enable row level security;
alter table public.s20y_gorev    enable row level security;
alter table public.s20y_yarim    enable row level security;
alter table public.s20y_onizleme enable row level security;
revoke all on public.s20y_deneme, public.s20y_soru, public.s20y_sonuc, public.s20y_gorev, public.s20y_yarim, public.s20y_onizleme from anon, authenticated;

create or replace function public.s20y_erisim(p_ders text)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (
    select 1 from public.paket_uyeler pu
    where pu.user_id = auth.uid()
      and (pu.bitis is null or pu.bitis >= current_date)
      and (coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu','son20-yet','yeterlilik','smmm','yeterlilik-kgk')
           or lower(trim(pu.paket)) like 'yeterlilik-%')
      and (pu.dersler is null or p_ders = any(pu.dersler))
  );
$fn$;

create or replace function public._s20y_acik(p_ders text, p_no integer)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (select 1 from public.s20y_deneme d
                  where d.ders = p_ders and d.no = p_no and coalesce(btrim(d.kalite_onay),'') <> ''
                    and d.acilis is not null
                    and (d.acilis <= now() or exists (select 1 from public.s20y_onizleme o where o.user_id = auth.uid())));
$fn$;

create or replace function public._s20y_gorev_acik(p_uid uuid, p_ders text)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (select 1 from public.s20y_gorev g where g.user_id = p_uid and g.ders = p_ders and not g.tamam);
$fn$;

create or replace function public._s20y_kapi(p_ders text, p_no integer)
returns void language plpgsql stable security definer set search_path = public as $fn$
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20y_erisim(p_ders) then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  if not public._s20y_acik(p_ders, p_no) then raise exception 'S20_KAPALI' using errcode = 'P0001'; end if;
  if exists (select 1 from public.s20y_sonuc x where x.user_id = auth.uid() and x.ders = p_ders and x.no = p_no) then return; end if;  -- yeniden çözüm hep açık
  if public._s20y_gorev_acik(auth.uid(), p_ders) then raise exception 'S20_GOREV' using errcode = 'P0001'; end if;
  if exists (select 1 from public.s20y_deneme d
              where d.ders = p_ders and d.no < p_no and public._s20y_acik(d.ders, d.no)
                and not exists (select 1 from public.s20y_sonuc x where x.user_id = auth.uid() and x.ders = d.ders and x.no = d.no)) then
    raise exception 'S20_ONCEKI' using errcode = 'P0001';
  end if;
end $fn$;

create or replace function public._s20y_gorevler(p_uid uuid)
returns jsonb language sql stable security definer set search_path = public as $fn$
  select coalesce(jsonb_agg(jsonb_build_object('ders', g.ders, 'no', g.no, 'konu', g.konu, 'sira', g.sira, 'tur', g.tur, 'dogru', g.dogru,
           'cevaplanan', (select count(*) from jsonb_object_keys(g.cevap)), 'tamam', g.tamam) order by g.ders, g.no, g.sira), '[]'::jsonb)
    from public.s20y_gorev g where g.user_id = p_uid;
$fn$;

create or replace function public.s20y_liste()
returns jsonb language plpgsql stable security definer set search_path = public as $fn$
declare u uuid := auth.uid();
begin
  return jsonb_build_object(
    'oturum', u is not null,
    'simdi', now(),
    'gorevler', case when u is null then '[]'::jsonb else public._s20y_gorevler(u) end,
    'denemeler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'ders', d.ders, 'no', d.no, 'ad', d.ad, 'sure_dk', d.sure_dk, 'acilis', d.acilis,
        'acik', public._s20y_acik(d.ders, d.no), 'erisim', public.s20y_erisim(d.ders),
        'toplam', (select count(*) from public.s20y_soru s where s.ders = d.ders and s.no = d.no),
        'yarim', exists (select 1 from public.s20y_yarim y where y.user_id = u and y.ders = d.ders and y.no = d.no),
        'sonuc', (select jsonb_build_object('dogru', r.dogru, 'yanlis', r.yanlis, 'bos', r.bos, 'toplam', r.toplam, 'zaman', r.zaman)
                    from public.s20y_sonuc r where r.user_id = u and r.ders = d.ders and r.no = d.no)
      ) order by d.ders, d.no)
      from public.s20y_deneme d
    ), '[]'::jsonb),
    /* deneme henüz yüklenmemiş üyenin kapısı için: sekiz ders adı sayfada, burada yalnız kişinin ders listesi */
    'dersler', case when u is null then '[]'::jsonb else coalesce((
      select to_jsonb(array_agg(x.ders)) from unnest(array['Finansal Muhasebe','Finansal Tablolar ve Analizi','Maliyet Muhasebesi','Muhasebe Denetimi',
        'Vergi Mevzuatı ve Uygulaması','Hukuk','Meslek Hukuku','Sermaye Piyasası Mevzuatı']) x(ders) where public.s20y_erisim(x.ders)), '[]'::jsonb) end);
end $fn$;

create or replace function public.s20y_test_getir(p_deneme integer, p_ders text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare ids text[]; neden text;
begin
  perform public._s20y_kapi(p_ders, p_deneme);
  select array_agg(s.id order by s.sira) into ids from public.s20y_soru s where s.ders = p_ders and s.no = p_deneme;
  if ids is null then raise exception 'S20_DERS_YOK' using errcode = 'P0001'; end if;
  neden := public.kasa_cekim_izin2('s20y-' || p_deneme, 0, cardinality(ids), ids);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return jsonb_build_object(
    'sure_dk', (select d.sure_dk from public.s20y_deneme d where d.ders = p_ders and d.no = p_deneme),
    'adet_deneme', cardinality(ids),
    'onceki', (select jsonb_build_object('dogru', r.dogru, 'yanlis', r.yanlis, 'bos', r.bos, 'toplam', r.toplam)
                 from public.s20y_sonuc r where r.user_id = auth.uid() and r.ders = p_ders and r.no = p_deneme),
    'yarim', (select jsonb_build_object('cevap', y.cevap, 'i', y.i, 'kalan', y.kalan, 'zaman', y.zaman)
                from public.s20y_yarim y where y.user_id = auth.uid() and y.ders = p_ders and y.no = p_deneme),
    'sorular', (select jsonb_agg(jsonb_build_object('id', s.id, 'soru', s.veri->'soru', 'siklar', s.veri->'siklar') order by s.sira)
                  from public.s20y_soru s where s.ders = p_ders and s.no = p_deneme));
end $fn$;

create or replace function public.s20y_yarim_yaz(p_deneme integer, p_ders text, p_cevap jsonb, p_i integer default 0, p_kalan integer default null)
returns boolean language plpgsql security definer set search_path = public as $fn$
declare temiz jsonb;
begin
  perform public._s20y_kapi(p_ders, p_deneme);
  select coalesce(jsonb_object_agg(s.id, upper(p_cevap->>s.id)), '{}'::jsonb) into temiz
    from public.s20y_soru s where s.ders = p_ders and s.no = p_deneme and upper(coalesce(p_cevap->>s.id, '')) ~ '^[A-E]$';
  insert into public.s20y_yarim as y (user_id, ders, no, cevap, i, kalan, zaman)
  values (auth.uid(), p_ders, p_deneme, temiz, greatest(coalesce(p_i, 0), 0), case when p_kalan between 0 and 86400 then p_kalan end, now())
  on conflict (user_id, ders, no) do update set cevap = excluded.cevap, i = excluded.i, kalan = excluded.kalan, zaman = now();
  return true;
end $fn$;

create or replace function public._s20y_gorev_aday(p_uid uuid, p_ders text, p_konu text, p_haric text[], p_adet integer)
returns text[] language sql volatile security definer set search_path = public as $fn$
  select coalesce(array(
    select ps.id from public.paket_soru ps
     where ps.sinav = 'smmm' and ps.ders = p_ders and ps.konu = p_konu
       and ps.id not like 'smmm-s20-%'
       and not (ps.id = any(coalesce(p_haric, '{}')))
       and not exists (select 1 from public.s20y_soru s where s.id = ps.id)
       and not exists (select 1 from public.kasa_cevap kc where kc.user_id = p_uid and kc.soru_id = ps.id)
       and coalesce(ps.veri->>'soru','') <> '' and jsonb_typeof(ps.veri->'siklar') = 'object' and coalesce(ps.veri->>'dogru','') ~ '^[A-E]$'
     order by random() limit p_adet), '{}');
$fn$;

-- %60 altı ilk çözümden sonra kurulur (kampanya §5: Yeterlilik'te %60 kuralı geçerli); kurulan konu sayısını döner
create or replace function public._s20y_gorev_kur(p_uid uuid, p_ders text, p_no integer)
returns integer language plpgsql volatile security definer set search_path = public as $fn$
declare n int := 0; x public.s20y_sonuc; r record; ids text[];
begin
  if exists (select 1 from public.s20y_gorev g where g.user_id = p_uid and g.ders = p_ders and g.no = p_no) then return 0; end if;
  select * into x from public.s20y_sonuc s where s.user_id = p_uid and s.ders = p_ders and s.no = p_no;
  if not found or x.toplam = 0 or x.dogru * 100 >= x.toplam * 60 then return 0; end if;
  for r in
    select s.konu, count(*) as k from public.s20y_soru s
     where s.ders = p_ders and s.no = p_no and coalesce(btrim(s.konu),'') <> ''
       and coalesce(x.cevap->>s.id, '') is distinct from (s.veri->>'dogru')
     group by s.konu order by count(*) desc, s.konu
  loop
    ids := public._s20y_gorev_aday(p_uid, p_ders, r.konu, '{}', 4);
    if cardinality(ids) = 4 then
      n := n + 1;
      insert into public.s20y_gorev (user_id, ders, no, konu, sira, yanlis, sorular, gorulen) values (p_uid, p_ders, p_no, r.konu, n, r.k, ids, ids);
      exit when n >= 5;
    end if;
  end loop;
  return n;
end $fn$;

create or replace function public.s20y_test_bitir(p_deneme integer, p_ders text, p_cevap jsonb, p_sure_sn integer default null)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare n_d int := 0; n_y int := 0; n_b int := 0; n_t int := 0; c text; r record; temiz jsonb := '{}'::jsonb; ilk boolean; gorev int := 0;
begin
  perform public._s20y_kapi(p_ders, p_deneme);
  for r in select s.id, s.veri->>'dogru' as dogru from public.s20y_soru s where s.ders = p_ders and s.no = p_deneme loop
    n_t := n_t + 1;
    c := upper(btrim(coalesce(p_cevap->>r.id, '')));
    if c !~ '^[A-E]$' then n_b := n_b + 1;
    else temiz := temiz || jsonb_build_object(r.id, c); if c = r.dogru then n_d := n_d + 1; else n_y := n_y + 1; end if; end if;
  end loop;
  if n_t = 0 then raise exception 'S20_DERS_YOK' using errcode = 'P0001'; end if;
  insert into public.s20y_sonuc (user_id, ders, no, dogru, yanlis, bos, toplam, cevap, sure_sn)
  values (auth.uid(), p_ders, p_deneme, n_d, n_y, n_b, n_t, temiz, case when p_sure_sn between 0 and 86400 then p_sure_sn end)
  on conflict (user_id, ders, no) do nothing;
  ilk := found;
  delete from public.s20y_yarim y where y.user_id = auth.uid() and y.ders = p_ders and y.no = p_deneme;
  if ilk then gorev := public._s20y_gorev_kur(auth.uid(), p_ders, p_deneme); end if;
  return jsonb_build_object(
    'dogru', n_d, 'yanlis', n_y, 'bos', n_b, 'toplam', n_t, 'ilk', ilk, 'gorev', gorev,
    'kayitli', (select jsonb_build_object('dogru', x.dogru, 'yanlis', x.yanlis, 'bos', x.bos, 'toplam', x.toplam)
                  from public.s20y_sonuc x where x.user_id = auth.uid() and x.ders = p_ders and x.no = p_deneme),
    'sorular', (select jsonb_agg(jsonb_build_object('id', s.id, 'konu', s.konu, 'veri', s.veri) order by s.sira)
                  from public.s20y_soru s where s.ders = p_ders and s.no = p_deneme));
end $fn$;

create or replace function public.s20y_gorev_getir(p_deneme integer, p_ders text, p_konu text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare g public.s20y_gorev; neden text;
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20y_erisim(p_ders) then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  select * into g from public.s20y_gorev x where x.user_id = auth.uid() and x.ders = p_ders and x.no = p_deneme and x.konu = p_konu;
  if not found then raise exception 'S20_GOREV_YOK' using errcode = 'P0001'; end if;
  neden := public.kasa_cekim_izin2('s20y-gorev', 0, cardinality(g.sorular), g.sorular);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return jsonb_build_object('deneme', g.no, 'ders', g.ders, 'konu', g.konu, 'tur', g.tur, 'dogru', g.dogru, 'tamam', g.tamam,
    'sorular', (select jsonb_agg(jsonb_build_object('id', ps.id, 'soru', ps.veri->'soru', 'siklar', ps.veri->'siklar',
                      'cevap', g.cevap->>ps.id,
                      'veri', case when g.cevap ? ps.id then ps.veri end) order by array_position(g.sorular, ps.id))
                  from public.paket_soru ps where ps.id = any(g.sorular)));
end $fn$;

create or replace function public.s20y_gorev_cevap(p_deneme integer, p_ders text, p_konu text, p_id text, p_secim text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare g public.s20y_gorev; sec text := upper(btrim(coalesce(p_secim,''))); v jsonb; dogruMu boolean; yeni text[]; ek text[]; turKapandi boolean := false;
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20y_erisim(p_ders) then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  if sec !~ '^[A-E]$' then raise exception 'S20_SECIM' using errcode = 'P0001'; end if;
  select * into g from public.s20y_gorev x where x.user_id = auth.uid() and x.ders = p_ders and x.no = p_deneme and x.konu = p_konu for update;
  if not found then raise exception 'S20_GOREV_YOK' using errcode = 'P0001'; end if;
  if g.tamam then raise exception 'S20_GOREV_TAMAM' using errcode = 'P0001'; end if;
  if not (p_id = any(g.sorular)) then raise exception 'S20_GOREV_SORU' using errcode = 'P0001'; end if;
  if g.cevap ? p_id then raise exception 'S20_GOREV_CEVAPLI' using errcode = 'P0001'; end if;
  select ps.veri into v from public.paket_soru ps where ps.id = p_id;
  dogruMu := (sec = v->>'dogru');
  g.cevap := g.cevap || jsonb_build_object(p_id, sec);
  if dogruMu then g.dogru := g.dogru + 1; else g.yanlislar := array_append(g.yanlislar, p_id); end if;
  if (select count(*) from jsonb_object_keys(g.cevap)) >= cardinality(g.sorular) then
    turKapandi := true;
    if g.dogru >= 3 then g.tamam := true; g.bitis := now();
    else
      yeni := public._s20y_gorev_aday(auth.uid(), g.ders, g.konu, g.gorulen, 4);
      if cardinality(yeni) < 4 then
        select array(select x from unnest(g.yanlislar) x where not (x = any(yeni)) group by x order by random() limit 4 - cardinality(yeni)) into ek;
        yeni := yeni || ek;
        if cardinality(yeni) < 4 then
          select array(select x from unnest(g.gorulen) x where not (x = any(yeni)) order by random() limit 4 - cardinality(yeni)) into ek;
          yeni := yeni || ek;
        end if;
      end if;
      g.tur := g.tur + 1; g.sorular := yeni; g.cevap := '{}'::jsonb; g.dogru := 0;
      g.gorulen := (select array(select distinct x from unnest(g.gorulen || yeni) x));
    end if;
  end if;
  update public.s20y_gorev x set tur = g.tur, sorular = g.sorular, gorulen = g.gorulen, yanlislar = g.yanlislar, cevap = g.cevap,
         dogru = g.dogru, tamam = g.tamam, bitis = g.bitis
   where x.user_id = auth.uid() and x.ders = p_ders and x.no = p_deneme and x.konu = p_konu;
  return jsonb_build_object('dogru_mu', dogruMu, 'dogru_sik', v->>'dogru', 'veri', v,
    'tur_kapandi', turKapandi, 'tamam', g.tamam, 'tur', g.tur, 'tur_dogru', g.dogru,
    'acik_gorev', public._s20y_gorev_acik(auth.uid(), p_ders));
end $fn$;

create or replace function public.s20y_deneme_yukle(p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare d text := btrim(coalesce(p->>'ders','')); n int := (p->>'no')::int; ayni boolean; adet int;
begin
  if d = '' or n is null or n not between 1 and 5 or coalesce(btrim(p->>'ad'),'') = '' or jsonb_typeof(p->'sorular') is distinct from 'array' then
    raise exception 'S20_YUKLE_BICIM'; end if;
  if jsonb_array_length(p->'sorular') <> 20 then raise exception 'S20_YUKLE_ADET: %', jsonb_array_length(p->'sorular'); end if;
  if (select count(distinct e->>'id') from jsonb_array_elements(p->'sorular') e) <> 20 then raise exception 'S20_YUKLE_TEKRAR'; end if;
  if exists (select 1 from jsonb_array_elements(p->'sorular') e where jsonb_typeof(e->'veri') is distinct from 'object') then raise exception 'S20_EKSIK: veri yok'; end if;
  select coalesce((select array_agg(s.id order by s.id) from public.s20y_soru s where s.ders = d and s.no = n), '{}')
         = (select array_agg(e->>'id' order by e->>'id') from jsonb_array_elements(p->'sorular') e) into ayni;
  if not ayni and exists (select 1 from public.s20y_sonuc r where r.ders = d and r.no = n) and coalesce(p->>'zorla','') <> 'evet' then
    raise exception 'S20_COZULMUS: % deneme % cozulmus, sorulari zorla olmadan degismez', d, n; end if;
  insert into public.s20y_deneme (ders, no, ad, sure_dk, acilis, kalite_onay, yuklenme)
  values (d, n, p->>'ad', coalesce((p->>'sure_dk')::int, 45), nullif(p->>'acilis','')::timestamptz, nullif(btrim(p->>'kalite_onay'),''), now())
  on conflict (ders, no) do update set ad = excluded.ad, sure_dk = excluded.sure_dk, acilis = excluded.acilis,
                                       kalite_onay = excluded.kalite_onay, yuklenme = now();
  delete from public.s20y_soru s where s.ders = d and s.no = n;
  insert into public.s20y_soru (ders, no, id, sira, konu, veri)
  select d, n, e->>'id', coalesce((e->>'sira')::int, o::int), e->>'konu', e->'veri'
    from jsonb_array_elements(p->'sorular') with ordinality as t(e, o);
  if exists (select 1 from public.s20y_soru s where s.ders = d and s.no = n
              and (coalesce(s.veri->>'soru','') = '' or jsonb_typeof(s.veri->'siklar') <> 'object' or coalesce(s.veri->>'dogru','') !~ '^[A-E]$')) then
    raise exception 'S20_VERI_BOZUK: % deneme % icinde soru/siklar/dogru eksik soru var', d, n; end if;
  select count(*) into adet from public.s20y_soru s where s.ders = d and s.no = n;
  return jsonb_build_object('ders', d, 'no', n, 'adet', adet, 'acilis', (select x.acilis from public.s20y_deneme x where x.ders = d and x.no = n),
    'acik', exists (select 1 from public.s20y_deneme x where x.ders = d and x.no = n and coalesce(btrim(x.kalite_onay),'') <> '' and x.acilis <= now()));
end $fn$;

-- Yetki: Supabase varsayılanı yeni fonksiyonu anon + authenticated'a açar; "from public" kapatmaz (2026-10-28-s20-yetki.sql). Rol rol kapatılır.
revoke all on function public.s20y_erisim(text), public._s20y_acik(text, integer), public._s20y_gorev_acik(uuid, text), public._s20y_kapi(text, integer),
  public._s20y_gorevler(uuid), public.s20y_liste(), public.s20y_test_getir(integer, text), public.s20y_yarim_yaz(integer, text, jsonb, integer, integer),
  public._s20y_gorev_aday(uuid, text, text, text[], integer), public._s20y_gorev_kur(uuid, text, integer),
  public.s20y_test_bitir(integer, text, jsonb, integer), public.s20y_gorev_getir(integer, text, text), public.s20y_gorev_cevap(integer, text, text, text, text),
  public.s20y_deneme_yukle(jsonb) from public, anon, authenticated;
grant execute on function public.s20y_liste() to anon, authenticated;
grant execute on function public.s20y_erisim(text), public.s20y_test_getir(integer, text), public.s20y_yarim_yaz(integer, text, jsonb, integer, integer),
  public.s20y_test_bitir(integer, text, jsonb, integer), public.s20y_gorev_getir(integer, text, text), public.s20y_gorev_cevap(integer, text, text, text, text) to authenticated;
grant execute on function public.s20y_deneme_yukle(jsonb) to service_role;

-- GÖÇ İÇİ ÖZ-SINAV (bütün satırlar geri alınır; gerçek ders + banka konusu kullanılır, üye geçici)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e7101';
  n int := 0; j jsonb; d text; d2 text := 'Hukuk'; k text; sorular jsonb; cvp jsonb; yanlis jsonb; id1 text;
begin
  select ps.ders, ps.konu into d, k from public.paket_soru ps
   where ps.sinav = 'smmm' and ps.ders <> 'Hukuk' and ps.id not like 'smmm-s20-%'
   group by ps.ders, ps.konu having count(*) >= 8 order by ps.ders, ps.konu limit 1;
  if d is null then raise exception 'OLCU: bankada konu bulunamadi'; end if;

  -- yetki: iç fonksiyon ve yükleyici üyeye kapalı, tablolar okunamaz
  if has_function_privilege('anon', 'public.s20y_deneme_yukle(jsonb)', 'execute') or has_function_privilege('authenticated', 'public.s20y_deneme_yukle(jsonb)', 'execute')
     or has_function_privilege('anon', 'public.s20y_test_getir(integer, text)', 'execute') or has_function_privilege('authenticated', 'public._s20y_gorev_kur(uuid, text, integer)', 'execute')
     or has_function_privilege('authenticated', 'public._s20y_kapi(text, integer)', 'execute') then raise exception 'OLCU: yetki acik'; end if;
  if has_table_privilege('authenticated', 'public.s20y_soru', 'select') or has_table_privilege('anon', 'public.s20y_soru', 'select')
     or has_table_privilege('authenticated', 'public.s20y_onizleme', 'insert') then raise exception 'OLCU: tablo acik'; end if;
  n := n + 2;

  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20y@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-yet', current_date + 30);

    select jsonb_agg(jsonb_build_object('id', 'olcu-y1/' || g, 'sira', g, 'konu', k, 'veri', jsonb_build_object('soru', 'Olcu ' || g || '?',
             'siklar', jsonb_build_object('A','a','B','b','C','c','D','d','E','e'), 'dogru', 'B', 'kural', 'gizli'))) into sorular from generate_series(1, 20) g;
    perform public.s20y_deneme_yukle(jsonb_build_object('ders', d, 'no', 1, 'ad', 'Deneme 1', 'acilis', now() - interval '1 minute', 'kalite_onay', 'olcu', 'sorular', sorular));
    perform public.s20y_deneme_yukle(jsonb_build_object('ders', d, 'no', 2, 'ad', 'Deneme 2', 'acilis', now() - interval '1 minute', 'kalite_onay', 'olcu',
      'sorular', (select jsonb_agg(jsonb_set(e, '{id}', to_jsonb('olcu-y2/' || (e->>'sira')))) from jsonb_array_elements(sorular) e)));
    perform public.s20y_deneme_yukle(jsonb_build_object('ders', d, 'no', 3, 'ad', 'Deneme 3', 'acilis', now() - interval '1 minute',   -- onaysız
      'sorular', (select jsonb_agg(jsonb_set(e, '{id}', to_jsonb('olcu-y3/' || (e->>'sira')))) from jsonb_array_elements(sorular) e)));
    perform public.s20y_deneme_yukle(jsonb_build_object('ders', d2, 'no', 1, 'ad', 'Deneme 1', 'acilis', now() + interval '1 day', 'kalite_onay', 'olcu',   -- gelecek
      'sorular', (select jsonb_agg(jsonb_set(e, '{id}', to_jsonb('olcu-y4/' || (e->>'sira')))) from jsonb_array_elements(sorular) e)));
    begin perform public.s20y_deneme_yukle(jsonb_build_object('ders', d, 'no', 4, 'ad', 'x', 'sorular', '[]'::jsonb)); raise exception 'OLCU: 20 soruluk sart gecildi';
    exception when others then if sqlerrm not like 'S20_YUKLE_ADET%' then raise; end if; end;
    n := n + 1;

    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    if auth.uid() is distinct from a then raise exception 'OLCU: auth.uid ayarlanamadi'; end if;

    -- son20-yet: Yeterlilik denemesi açık, banka kapalı, SGS denemesi kapalı
    if not public.s20y_erisim(d) then raise exception 'OLCU: son20-yet erisimi yok'; end if;
    if public.paket_erisim_var('smmm', d) then raise exception 'OLCU: son20-yet bankayi aciyor'; end if;
    if public.s20_erisim() then raise exception 'OLCU: son20-yet SGS denemesini aciyor'; end if;
    n := n + 3;

    -- doğru/açıklama sızmaz
    j := public.s20y_test_getir(1, d);
    if jsonb_array_length(j->'sorular') <> 20 or (j->>'sure_dk')::int <> 45 then raise exception 'OLCU: getir yanlis'; end if;
    if position('gizli' in j::text) > 0 or position('"dogru"' in (j->'sorular')::text) > 0 then raise exception 'OLCU: cevap sizdi'; end if;
    n := n + 2;
    -- onaysız ve gelecek tarihli kapalı
    begin perform public.s20y_test_getir(3, d); raise exception 'OLCU: onaysiz acildi'; exception when others then if sqlerrm <> 'S20_KAPALI' then raise; end if; end;
    begin perform public.s20y_test_getir(1, d2); raise exception 'OLCU: gelecek acildi'; exception when others then if sqlerrm <> 'S20_KAPALI' then raise; end if; end;
    n := n + 2;
    -- önizleme yalnız listedeki üyeye gelecek denemeyi açar
    insert into public.s20y_onizleme (user_id, neden) values (a, 'olcu');
    perform public.s20y_test_getir(1, d2);
    delete from public.s20y_onizleme where user_id = a;
    n := n + 1;
    -- sıra: D1 bitmeden D2 kilitli; başka ders etkilenmez
    begin perform public.s20y_test_getir(2, d); raise exception 'OLCU: D1 bitmeden D2 acildi'; exception when others then if sqlerrm <> 'S20_ONCEKI' then raise; end if; end;
    n := n + 1;
    -- yarım: yazılır, süzülür, getirde döner
    id1 := 'olcu-y1/1';
    perform public.s20y_yarim_yaz(1, d, jsonb_build_object(id1, 'c', 'olcu-y1/2', 'x', 'yok/kimlik', 'A'), 3, 1200);
    j := public.s20y_test_getir(1, d);
    if j->'yarim'->'cevap'->>id1 <> 'C' or (j->'yarim'->'cevap') ? 'olcu-y1/2' or (j->'yarim'->'cevap') ? 'yok/kimlik' or (j->'yarim'->>'kalan')::int <> 1200 or (j->'yarim'->>'i')::int <> 3 then
      raise exception 'OLCU: yarim yanlis %', j->'yarim'; end if;
    n := n + 1;
    -- %60 altı: puan sunucuda, ilk çözüm yazılır, yarım silinir, görev kurulur, D2 görev bitene kadar kilitli
    select jsonb_object_agg('olcu-y1/' || g, case when g <= 11 then 'B' else 'A' end) into yanlis from generate_series(1, 18) g;   -- 11 doğru, 7 yanlış, 2 boş
    j := public.s20y_test_bitir(1, d, yanlis, 600);
    if (j->>'dogru')::int <> 11 or (j->>'yanlis')::int <> 7 or (j->>'bos')::int <> 2 or not (j->>'ilk')::boolean then raise exception 'OLCU: puan %', j; end if;
    if (j->>'gorev')::int <> 1 then raise exception 'OLCU: gorev kurulmadi %', j->>'gorev'; end if;
    if j->'sorular'->0->'veri'->>'kural' <> 'gizli' then raise exception 'OLCU: bitiste veri donmedi'; end if;
    if exists (select 1 from public.s20y_yarim where user_id = a) then raise exception 'OLCU: yarim silinmedi'; end if;
    begin perform public.s20y_test_getir(2, d); raise exception 'OLCU: gorev varken D2 acildi'; exception when others then if sqlerrm <> 'S20_GOREV' then raise; end if; end;
    n := n + 5;
    -- ilk çözüm korunur, çözülen yeniden açılır
    select jsonb_object_agg('olcu-y1/' || g, 'B') into cvp from generate_series(1, 20) g;
    perform public.s20y_test_getir(1, d);
    j := public.s20y_test_bitir(1, d, cvp, 60);
    if (j->>'ilk')::boolean or (j->'kayitli'->>'dogru')::int <> 11 or (j->>'dogru')::int <> 20 then raise exception 'OLCU: ilk cozum korunmadi %', j; end if;
    n := n + 2;
    -- görev: 4 soru, 3 doğru → tamam, D2 açılır
    j := public.s20y_gorev_getir(1, d, k);
    if jsonb_array_length(j->'sorular') <> 4 or position('"dogru"' in (j->'sorular')::text) > 0 then raise exception 'OLCU: gorev getir %', jsonb_array_length(j->'sorular'); end if;
    declare q record; v jsonb;
    begin
      for q in select ps.id, ps.veri->>'dogru' as dg from public.paket_soru ps where ps.id = any((select g.sorular from public.s20y_gorev g where g.user_id = a and g.ders = d)) loop
        v := public.s20y_gorev_cevap(1, d, k, q.id, q.dg);
      end loop;
      if not (v->>'tamam')::boolean or (v->>'acik_gorev')::boolean then raise exception 'OLCU: gorev tamamlanmadi %', v; end if;
    end;
    perform public.s20y_test_getir(2, d);
    n := n + 3;
    -- %60 ve üstü: görev çıkmaz
    select jsonb_object_agg('olcu-y2/' || g, case when g <= 12 then 'B' else 'A' end) into cvp from generate_series(1, 20) g;
    j := public.s20y_test_bitir(2, d, cvp, 60);
    if (j->>'gorev')::int <> 0 then raise exception 'OLCU: %%60 uzerine gorev'; end if;
    n := n + 1;
    -- liste
    j := public.s20y_liste();
    if not (j->>'oturum')::boolean or (select count(*) from jsonb_array_elements(j->'denemeler') e where e->>'ders' = d and (e->>'no')::int = 1
         and (e->>'acik')::boolean and (e->>'erisim')::boolean and (e->'sonuc'->>'dogru')::int = 11) <> 1 or jsonb_array_length(j->'dersler') <> 8 then raise exception 'OLCU: liste %', j->'dersler'; end if;
    n := n + 1;
    -- paketler: ders ders yalnız seçtiği ders; tüm dersler + tam + kurucu açar; sgs ve süresi biten açmaz
    update public.paket_uyeler set paket = 'yeterlilik-2', dersler = array[d] where user_id = a;
    if not public.s20y_erisim(d) or public.s20y_erisim(d2) then raise exception 'OLCU: ders ders paket yanlis'; end if;
    begin perform public.s20y_test_getir(1, d2); raise exception 'OLCU: secilmeyen ders acildi'; exception when others then if sqlerrm <> 'S20_PAKET' then raise; end if; end;
    update public.paket_uyeler set paket = 'yeterlilik-tum', dersler = null where user_id = a; if not public.s20y_erisim(d2) then raise exception 'OLCU: tum acmiyor'; end if;
    update public.paket_uyeler set paket = 'tam' where user_id = a;    if not public.s20y_erisim(d2) then raise exception 'OLCU: tam acmiyor'; end if;
    update public.paket_uyeler set paket = 'kurucu' where user_id = a; if not public.s20y_erisim(d2) then raise exception 'OLCU: kurucu acmiyor'; end if;
    update public.paket_uyeler set paket = 'sgs' where user_id = a;    if public.s20y_erisim(d2) then raise exception 'OLCU: sgs Yeterlilik aciyor'; end if;
    update public.paket_uyeler set paket = 'son20-sgs' where user_id = a; if public.s20y_erisim(d2) then raise exception 'OLCU: son20-sgs Yeterlilik aciyor'; end if;
    update public.paket_uyeler set paket = 'son20-yet', bitis = current_date - 1 where user_id = a;
    if public.s20y_erisim(d2) then raise exception 'OLCU: suresi biten aciyor'; end if;
    n := n + 8;
    -- çözülmüş deneme zorla'sız değişmez; oturumsuz liste erişim göstermez
    perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
    begin
      perform public.s20y_deneme_yukle(jsonb_build_object('ders', d, 'no', 1, 'ad', 'Deneme 1', 'kalite_onay', 'olcu',
        'sorular', (select jsonb_agg(jsonb_set(e, '{id}', to_jsonb('olcu-y9/' || (e->>'sira')))) from jsonb_array_elements(sorular) e)));
      raise exception 'OLCU: cozulmus deneme degisti';
    exception when others then if sqlerrm not like 'S20_COZULMUS%' then raise; end if; end;
    j := public.s20y_liste();
    if (j->>'oturum')::boolean or exists (select 1 from jsonb_array_elements(j->'denemeler') e where (e->>'erisim')::boolean or e->'sonuc' <> 'null'::jsonb) then raise exception 'OLCU: oturumsuz liste'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where email = 'olcu-s20y@tetikte.invalid') or exists (select 1 from public.s20y_deneme)
     or exists (select 1 from public.s20y_sonuc) or exists (select 1 from public.s20y_gorev) or exists (select 1 from public.s20y_yarim) then
    raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'S20Y DENEME OZ-SINAV: % vaka TAMAM', n;
end $$;
