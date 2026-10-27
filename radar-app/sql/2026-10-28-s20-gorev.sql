-- ============================================================================
--  SON 20 GÜN — ÇALIŞMA GÖREVLERİ + SONRAKİ DENEME KİLİDİ  ·  28.10.2026 (site kolu)
--
--  CEM 28.10: "Çalışma görevlerini kur: %60'ın altında kalınan denemeden sonra en çok 5 konu × 4 yeni soru, 3'ü doğru olunca
--  konu tamam, görevler bitince sonraki deneme açılır. Sorular sonraki denemelerden seçilmesin."
--  Kampanya koşulları §1 (kampanya-son-20-gun.html) bunu söz verdi; söz şartı (§2) görevlerin tamamlanmasına bağlı.
--
--  KURAL:
--   · Görev, bir denemenin BÜTÜN ders testleri ilk kez bitince ve doğru oranı < %60 ise kurulur (s20_test_bitir içinde, bir kez).
--   · Konu: o denemede yanlış/boş bırakılan sorulardan (ders + konu); yanlış sayısı çok olan önce. En az 4 YENİ sorusu olan
--     konular alınır, en çok 5.
--   · Yeni soru: SGS bankası (paket_soru sinav='sgs', aynı ders + aynı konu); HİÇBİR denemede olmayan (s20_soru), sgs-s20-*
--     olmayan, üyenin ders sayfalarında çözmediği (kasa_cevap) ve bu görevde daha önce verilmemiş soru.
--   · Tur: 4 soru; 3'ü doğruysa konu tamam. Değilse aynı konudan yeni tur (yeni soru yetmezse önceki turların yanlışları).
--   · Kilit: tamamlanmamış görev varken, üyenin henüz çözmediği bir deneme testi AÇILMAZ ve teslim edilmez (S20_GOREV);
--     çözülmüş testler yeniden çözülebilir.
--   · s20_deneme_yukle: konu adı artık önce bankanın kendisinden (paket_soru.konu), yoksa öğeden — görev eşlemesi banka adıyla.
--  🚫 GÖRMEZ: konunun "yakın" konuları (eşleme yalnız birebir ad) · görev sorusunun açıklama kalitesi (banka kapıları).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (bütün satırlar geri alınır).
-- ============================================================================

create table if not exists public.s20_gorev (
  user_id   uuid not null references auth.users(id) on delete cascade,
  deneme    integer not null,
  ders      text not null,
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
  primary key (user_id, deneme, ders, konu)
);
alter table public.s20_gorev enable row level security;
revoke all on public.s20_gorev from anon, authenticated;

-- bankadan en çok p_adet yeni görev sorusu
create or replace function public._s20_gorev_aday(p_uid uuid, p_ders text, p_konu text, p_haric text[], p_adet integer)
returns text[] language sql volatile security definer set search_path = public as $fn$
  select coalesce(array(
    select ps.id from public.paket_soru ps
     where ps.sinav = 'sgs' and ps.ders = p_ders and ps.konu = p_konu
       and ps.id not like 'sgs-s20-%'
       and not (ps.id = any(coalesce(p_haric, '{}')))
       and not exists (select 1 from public.s20_soru s where s.id = ps.id)
       and not exists (select 1 from public.kasa_cevap kc where kc.user_id = p_uid and kc.soru_id = ps.id)
       and coalesce(ps.veri->>'soru','') <> '' and jsonb_typeof(ps.veri->'siklar') = 'object' and coalesce(ps.veri->>'dogru','') ~ '^[A-E]$'
     order by random() limit p_adet), '{}');
$fn$;

create or replace function public._s20_gorev_acik(p_uid uuid)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (select 1 from public.s20_gorev g where g.user_id = p_uid and not g.tamam);
$fn$;

-- deneme ilk kez tamamlandıysa ve oran < %60 ise görevleri kurar; kurulan konu sayısını döner
create or replace function public._s20_gorev_kur(p_uid uuid, p_deneme integer)
returns integer language plpgsql volatile security definer set search_path = public as $fn$
declare n int := 0; dersSay int; sonucSay int; dog int; top int; r record; ids text[];
begin
  if exists (select 1 from public.s20_gorev g where g.user_id = p_uid and g.deneme = p_deneme) then return 0; end if;
  select count(distinct s.ders) into dersSay from public.s20_soru s where s.deneme = p_deneme;
  select count(*), coalesce(sum(x.dogru),0), coalesce(sum(x.toplam),0) into sonucSay, dog, top
    from public.s20_sonuc x where x.user_id = p_uid and x.deneme = p_deneme;
  if dersSay = 0 or sonucSay < dersSay or top = 0 or dog * 100 >= top * 60 then return 0; end if;
  for r in
    select s.ders, s.konu, count(*) as k
      from public.s20_soru s join public.s20_sonuc x on x.user_id = p_uid and x.deneme = s.deneme and x.ders = s.ders
     where s.deneme = p_deneme and coalesce(btrim(s.konu),'') <> ''
       and coalesce(x.cevap->>s.id, '') is distinct from (s.veri->>'dogru')
     group by s.ders, s.konu order by count(*) desc, s.ders, s.konu
  loop
    ids := public._s20_gorev_aday(p_uid, r.ders, r.konu, '{}', 4);
    if cardinality(ids) = 4 then
      n := n + 1;
      insert into public.s20_gorev (user_id, deneme, ders, konu, sira, yanlis, sorular, gorulen)
      values (p_uid, p_deneme, r.ders, r.konu, n, r.k, ids, ids);
      exit when n >= 5;
    end if;
  end loop;
  return n;
end $fn$;

-- kilit: açık görev varken çözülmemiş deneme testi yok
create or replace function public._s20_gorev_kapi(p_deneme integer, p_ders text)
returns void language plpgsql stable security definer set search_path = public as $fn$
begin
  if public._s20_gorev_acik(auth.uid())
     and not exists (select 1 from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders) then
    raise exception 'S20_GOREV' using errcode = 'P0001';
  end if;
end $fn$;

create or replace function public.s20_test_getir(p_deneme integer, p_ders text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare ids text[]; neden text;
begin
  perform public._s20_kapi(p_deneme);
  perform public._s20_gorev_kapi(p_deneme, p_ders);
  select array_agg(s.id order by s.sira) into ids from public.s20_soru s where s.deneme = p_deneme and s.ders = p_ders;
  if ids is null then raise exception 'S20_DERS_YOK' using errcode = 'P0001'; end if;
  neden := public.kasa_cekim_izin2('s20-' || p_deneme, 0, cardinality(ids), ids);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return jsonb_build_object(
    'sure_dk', (select d.sure_dk from public.s20_deneme d where d.no = p_deneme),
    'adet_deneme', (select count(*) from public.s20_soru s where s.deneme = p_deneme),
    'onceki', (select jsonb_build_object('dogru', r.dogru, 'yanlis', r.yanlis, 'bos', r.bos, 'toplam', r.toplam)
                 from public.s20_sonuc r where r.user_id = auth.uid() and r.deneme = p_deneme and r.ders = p_ders),
    'sorular', (select jsonb_agg(jsonb_build_object('id', s.id, 'soru', s.veri->'soru', 'siklar', s.veri->'siklar') order by s.sira)
                  from public.s20_soru s where s.deneme = p_deneme and s.ders = p_ders));
end $fn$;

create or replace function public.s20_test_bitir(p_deneme integer, p_ders text, p_cevap jsonb, p_sure_sn integer default null)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare n_d int := 0; n_y int := 0; n_b int := 0; n_t int := 0; c text; r record; temiz jsonb := '{}'::jsonb; ilk boolean; gorev int := 0;
begin
  perform public._s20_kapi(p_deneme);
  perform public._s20_gorev_kapi(p_deneme, p_ders);
  for r in select s.id, s.veri->>'dogru' as dogru from public.s20_soru s where s.deneme = p_deneme and s.ders = p_ders loop
    n_t := n_t + 1;
    c := upper(btrim(coalesce(p_cevap->>r.id, '')));
    if c !~ '^[A-E]$' then n_b := n_b + 1;
    else temiz := temiz || jsonb_build_object(r.id, c); if c = r.dogru then n_d := n_d + 1; else n_y := n_y + 1; end if; end if;
  end loop;
  if n_t = 0 then raise exception 'S20_DERS_YOK' using errcode = 'P0001'; end if;
  insert into public.s20_sonuc (user_id, deneme, ders, dogru, yanlis, bos, toplam, cevap, sure_sn)
  values (auth.uid(), p_deneme, p_ders, n_d, n_y, n_b, n_t, temiz, case when p_sure_sn between 0 and 86400 then p_sure_sn end)
  on conflict (user_id, deneme, ders) do nothing;
  ilk := found;
  if ilk then gorev := public._s20_gorev_kur(auth.uid(), p_deneme); end if;
  return jsonb_build_object(
    'dogru', n_d, 'yanlis', n_y, 'bos', n_b, 'toplam', n_t, 'ilk', ilk, 'gorev', gorev,
    'kayitli', (select jsonb_build_object('dogru', x.dogru, 'yanlis', x.yanlis, 'bos', x.bos, 'toplam', x.toplam)
                  from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders),
    'sorular', (select jsonb_agg(jsonb_build_object('id', s.id, 'konu', s.konu, 'veri', s.veri) order by s.sira)
                  from public.s20_soru s where s.deneme = p_deneme and s.ders = p_ders));
end $fn$;

create or replace function public._s20_gorevler(p_uid uuid)
returns jsonb language sql stable security definer set search_path = public as $fn$
  select coalesce(jsonb_agg(jsonb_build_object('deneme', g.deneme, 'ders', g.ders, 'konu', g.konu, 'sira', g.sira, 'tur', g.tur,
           'dogru', g.dogru, 'cevaplanan', (select count(*) from jsonb_object_keys(g.cevap)), 'tamam', g.tamam)
           order by g.deneme, g.sira), '[]'::jsonb)
    from public.s20_gorev g where g.user_id = p_uid;
$fn$;

create or replace function public.s20_liste()
returns jsonb language plpgsql stable security definer set search_path = public as $fn$
declare u uuid := auth.uid();
begin
  return jsonb_build_object(
    'oturum', u is not null,
    'erisim', public.s20_erisim(),
    'simdi', now(),
    'gorevler', case when u is null then '[]'::jsonb else public._s20_gorevler(u) end,
    'denemeler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'no', d.no, 'ad', d.ad, 'sure_dk', d.sure_dk, 'acilis', d.acilis, 'acik', public._s20_acik(d.no),
        'toplam', (select count(*) from public.s20_soru s where s.deneme = d.no),
        'dersler', coalesce((
          select jsonb_agg(jsonb_build_object(
            'ders', x.ders, 'adet', x.adet,
            'sonuc', (select jsonb_build_object('dogru', r.dogru, 'yanlis', r.yanlis, 'bos', r.bos, 'toplam', r.toplam, 'zaman', r.zaman)
                        from public.s20_sonuc r where r.user_id = u and r.deneme = d.no and r.ders = x.ders))
            order by x.ilk)
          from (select s.ders, count(*) as adet, min(s.sira) as ilk from public.s20_soru s where s.deneme = d.no group by s.ders) x
        ), '[]'::jsonb)
      ) order by d.no)
      from public.s20_deneme d
    ), '[]'::jsonb));
end $fn$;

-- açık turun soruları (doğrusuz) + bu turda verilen cevaplar (açıklamalarıyla)
create or replace function public.s20_gorev_getir(p_deneme integer, p_ders text, p_konu text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare g public.s20_gorev; neden text;
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20_erisim() then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  select * into g from public.s20_gorev x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders and x.konu = p_konu;
  if not found then raise exception 'S20_GOREV_YOK' using errcode = 'P0001'; end if;
  neden := public.kasa_cekim_izin2('s20-gorev', 0, cardinality(g.sorular), g.sorular);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return jsonb_build_object('deneme', g.deneme, 'ders', g.ders, 'konu', g.konu, 'tur', g.tur, 'dogru', g.dogru, 'tamam', g.tamam,
    'sorular', (select jsonb_agg(jsonb_build_object('id', ps.id, 'soru', ps.veri->'soru', 'siklar', ps.veri->'siklar',
                      'cevap', g.cevap->>ps.id,
                      'veri', case when g.cevap ? ps.id then ps.veri end) order by array_position(g.sorular, ps.id))
                  from public.paket_soru ps where ps.id = any(g.sorular)));
end $fn$;

-- tek soru cevabı: doğruluk + açıklama hemen; 4 cevapta tur kapanır (3 doğru = konu tamam, değilse yeni tur)
create or replace function public.s20_gorev_cevap(p_deneme integer, p_ders text, p_konu text, p_id text, p_secim text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare g public.s20_gorev; sec text := upper(btrim(coalesce(p_secim,''))); v jsonb; dogruMu boolean; yeni text[]; ek text[]; turKapandi boolean := false;
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20_erisim() then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  if sec !~ '^[A-E]$' then raise exception 'S20_SECIM' using errcode = 'P0001'; end if;
  select * into g from public.s20_gorev x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders and x.konu = p_konu for update;
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
      yeni := public._s20_gorev_aday(auth.uid(), g.ders, g.konu, g.gorulen, 4);
      if cardinality(yeni) < 4 then   -- yeni soru yetmedi: önceki turların yanlışları, sonra görülenler
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
  update public.s20_gorev x set tur = g.tur, sorular = g.sorular, gorulen = g.gorulen, yanlislar = g.yanlislar, cevap = g.cevap,
         dogru = g.dogru, tamam = g.tamam, bitis = g.bitis
   where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders and x.konu = p_konu;
  return jsonb_build_object('dogru_mu', dogruMu, 'dogru_sik', v->>'dogru', 'veri', v,
    'tur_kapandi', turKapandi, 'tamam', g.tamam, 'tur', g.tur, 'tur_dogru', g.dogru,
    'acik_gorev', public._s20_gorev_acik(auth.uid()));
end $fn$;

-- yükleyici: konu önce bankadan
create or replace function public.s20_deneme_yukle(p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare n int := (p->>'no')::int; eksik text[]; ayni boolean; adet int;
begin
  if n is null or coalesce(btrim(p->>'ad'),'') = '' or jsonb_typeof(p->'sorular') <> 'array' or jsonb_array_length(p->'sorular') = 0 then
    raise exception 'S20_YUKLE_BICIM'; end if;
  if (select count(distinct e->>'id') from jsonb_array_elements(p->'sorular') e) <> jsonb_array_length(p->'sorular') then
    raise exception 'S20_YUKLE_TEKRAR'; end if;
  select array_agg(e->>'id') into eksik from jsonb_array_elements(p->'sorular') e
   where jsonb_typeof(e->'veri') is distinct from 'object'
     and not exists (select 1 from public.paket_soru ps where ps.id = e->>'id');
  if eksik is not null then raise exception 'S20_EKSIK:% soru: %', cardinality(eksik), array_to_string(eksik[1:5], ', '); end if;
  select coalesce((select array_agg(s.id order by s.id) from public.s20_soru s where s.deneme = n), '{}')
         = (select array_agg(e->>'id' order by e->>'id') from jsonb_array_elements(p->'sorular') e) into ayni;
  if not ayni and exists (select 1 from public.s20_sonuc r where r.deneme = n) and coalesce(p->>'zorla','') <> 'evet' then
    raise exception 'S20_COZULMUS: deneme % cozulmus, sorulari zorla olmadan degismez', n; end if;
  insert into public.s20_deneme (no, ad, sure_dk, acilis, kalite_onay, yuklenme)
  values (n, p->>'ad', coalesce((p->>'sure_dk')::int, 165), nullif(p->>'acilis','')::timestamptz, nullif(btrim(p->>'kalite_onay'),''), now())
  on conflict (no) do update set ad = excluded.ad, sure_dk = excluded.sure_dk, acilis = excluded.acilis,
                                 kalite_onay = excluded.kalite_onay, yuklenme = now();
  delete from public.s20_soru where deneme = n;
  insert into public.s20_soru (deneme, id, ders, sira, konu, veri)
  select n, e->>'id', coalesce(e->>'ders', ps.ders), coalesce((e->>'sira')::int, o::int), coalesce(ps.konu, e->>'konu'),
         case when jsonb_typeof(e->'veri') = 'object' then e->'veri' else ps.veri end
    from jsonb_array_elements(p->'sorular') with ordinality as t(e, o)
    left join public.paket_soru ps on ps.id = e->>'id';
  if exists (select 1 from public.s20_soru s where s.deneme = n
              and (coalesce(s.veri->>'soru','') = '' or jsonb_typeof(s.veri->'siklar') <> 'object' or coalesce(s.veri->>'dogru','') !~ '^[A-E]$')) then
    raise exception 'S20_VERI_BOZUK: deneme % icinde soru/siklar/dogru eksik soru var', n; end if;
  select count(*) into adet from public.s20_soru where deneme = n;
  return jsonb_build_object('no', n, 'adet', adet, 'acik', public._s20_acik(n),
    'dersler', (select jsonb_object_agg(ders, k) from (select ders, count(*) k from public.s20_soru where deneme = n group by ders) z));
end $fn$;

-- YETKİ (Supabase yeni fonksiyona anon/authenticated'a açık grant veriyor: rol rol kapat — 2026-10-28-s20-yetki.sql dersi)
revoke execute on function public._s20_gorev_aday(uuid, text, text, text[], integer), public._s20_gorev_acik(uuid),
  public._s20_gorev_kur(uuid, integer), public._s20_gorev_kapi(integer, text), public._s20_gorevler(uuid),
  public.s20_deneme_yukle(jsonb) from public, anon, authenticated;
revoke execute on function public.s20_test_getir(integer, text), public.s20_test_bitir(integer, text, jsonb, integer),
  public.s20_gorev_getir(integer, text, text), public.s20_gorev_cevap(integer, text, text, text, text) from public, anon;
grant execute on function public.s20_test_getir(integer, text), public.s20_test_bitir(integer, text, jsonb, integer),
  public.s20_gorev_getir(integer, text, text), public.s20_gorev_cevap(integer, text, text, text, text) to authenticated;
grant execute on function public.s20_liste() to anon, authenticated;
grant execute on function public.s20_deneme_yukle(jsonb) to service_role;

-- GÖÇ İÇİ ÖZ-SINAV (bütün satırlar geri alınır)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e2802';
  n int := 0; j jsonb; k text; ids text[]; i int; r record;
  q jsonb := '{"soru":"Olcu?","siklar":{"A":"a","B":"b","C":"c","D":"d","E":"e"},"dogru":"B","aciklama":{"B":"gizli"}}';
begin
  -- yetki ölçümü
  for r in select * from (values ('anon','public._s20_gorev_kur(uuid, integer)',false),('authenticated','public._s20_gorev_kur(uuid, integer)',false),
      ('authenticated','public._s20_gorev_aday(uuid, text, text, text[], integer)',false),('anon','public.s20_gorev_cevap(integer, text, text, text, text)',false),
      ('authenticated','public.s20_gorev_cevap(integer, text, text, text, text)',true),('authenticated','public.s20_gorev_getir(integer, text, text)',true),
      ('anon','public.s20_deneme_yukle(jsonb)',false),('authenticated','public.s20_deneme_yukle(jsonb)',false),('anon','public.s20_liste()',true)) as t(rol, fn, b) loop
    if has_function_privilege(r.rol, r.fn, 'execute') <> r.b then raise exception 'OLCU: % % execute=% olmali', r.rol, r.fn, r.b; end if;
    n := n + 1;
  end loop;
  if has_table_privilege('authenticated', 'public.s20_gorev', 'select') or has_table_privilege('anon', 'public.s20_gorev', 'select') then
    raise exception 'OLCU: s20_gorev tablosu okunuyor'; end if;
  n := n + 1;
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20g@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-sgs', current_date + 30);
    -- bankada görev adayı: "olcu konu" 6 soru, "az konu" 2 soru (4'ten az → görev olmaz)
    for i in 1..6 loop
      insert into public.paket_soru (id, sinav, ders, konu, sayfa, sira, ucretsiz, veri)
      values ('olcu-gorev/kp-0' || i, 'sgs', 'Olcu Ders', 'olcu konu', 'olcu.html', 900 + i, false, q);
    end loop;
    for i in 1..2 loop
      insert into public.paket_soru (id, sinav, ders, konu, sayfa, sira, ucretsiz, veri)
      values ('olcu-az/kp-0' || i, 'sgs', 'Olcu Ders', 'az konu', 'olcu.html', 950 + i, false, q);
    end loop;
    perform public.s20_deneme_yukle(jsonb_build_object('no', 19, 'ad', 'Olcu 19', 'acilis', now() - interval '1 minute', 'kalite_onay', 'olcu',
      'sorular', jsonb_build_array(
        jsonb_build_object('id','olcu-d/1','ders','Olcu Ders','sira',1,'konu','olcu konu','veri',q),
        jsonb_build_object('id','olcu-d/2','ders','Olcu Ders','sira',2,'konu','olcu konu','veri',q),
        jsonb_build_object('id','olcu-d/3','ders','Olcu Ders','sira',3,'konu','az konu','veri',q))));
    perform public.s20_deneme_yukle(jsonb_build_object('no', 20, 'ad', 'Olcu 20', 'acilis', now() - interval '1 minute', 'kalite_onay', 'olcu',
      'sorular', jsonb_build_array(jsonb_build_object('id','olcu-e/1','ders','Olcu Ders','sira',1,'konu','olcu konu','veri',q))));
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    -- deneme 19: hepsi yanlış (%0) → görev: yalnız "olcu konu" (az konu'da 4 yeni soru yok)
    j := public.s20_test_bitir(19, 'Olcu Ders', '{"olcu-d/1":"A","olcu-d/2":"A"}'::jsonb, 60);
    if (j->>'gorev')::int <> 1 then raise exception 'OLCU: gorev sayisi % (1 olmali)', j->>'gorev'; end if;
    if (select count(*) from public.s20_gorev where user_id = a) <> 1 or not exists (select 1 from public.s20_gorev where user_id = a and konu = 'olcu konu') then
      raise exception 'OLCU: gorev konusu yanlis'; end if;
    if exists (select 1 from public.s20_gorev g, unnest(g.sorular) x where g.user_id = a and (x like 'olcu-d/%' or x like 'olcu-e/%')) then
      raise exception 'OLCU: gorev sorusu bir denemeden secildi'; end if;
    n := n + 3;
    -- kilit: deneme 20 açılmaz, deneme 19 yeniden çözülür
    begin perform public.s20_test_getir(20, 'Olcu Ders'); raise exception 'OLCU: gorev varken sonraki deneme acildi';
    exception when others then if sqlerrm <> 'S20_GOREV' then raise; end if; end;
    begin perform public.s20_test_bitir(20, 'Olcu Ders', '{}'::jsonb, 1); raise exception 'OLCU: gorev varken sonraki deneme teslim edildi';
    exception when others then if sqlerrm <> 'S20_GOREV' then raise; end if; end;
    perform public.s20_test_getir(19, 'Olcu Ders');
    n := n + 3;
    -- tur 1: 2 doğru 2 yanlış → yeni tur
    j := public.s20_gorev_getir(19, 'Olcu Ders', 'olcu konu');
    if jsonb_array_length(j->'sorular') <> 4 or position('gizli' in j::text) > 0 or (j->'sorular'->0) ? 'dogru' then raise exception 'OLCU: gorev getir % / sizinti', j; end if;
    select array_agg(x->>'id') into ids from jsonb_array_elements(j->'sorular') x;
    j := public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[1], 'B');
    if not (j->>'dogru_mu')::boolean or j->'veri'->'aciklama'->>'B' <> 'gizli' then raise exception 'OLCU: cevap/aciklama %', j; end if;
    begin perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[1], 'B'); raise exception 'OLCU: ayni soru iki kez';
    exception when others then if sqlerrm <> 'S20_GOREV_CEVAPLI' then raise; end if; end;
    perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[2], 'B');
    perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[3], 'A');
    j := public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[4], 'A');
    if not (j->>'tur_kapandi')::boolean or (j->>'tamam')::boolean or (j->>'tur')::int <> 2 then raise exception 'OLCU: tur 1 kapanisi %', j; end if;
    n := n + 4;
    -- tur 2: 2 yeni + önceki yanlışlardan; 3 doğru → tamam, kilit kalkar
    j := public.s20_gorev_getir(19, 'Olcu Ders', 'olcu konu');
    select array_agg(x->>'id') into ids from jsonb_array_elements(j->'sorular') x;
    if cardinality(ids) <> 4 then raise exception 'OLCU: tur 2 soru sayisi %', cardinality(ids); end if;
    perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[1], 'B');
    perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[2], 'B');
    perform public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[3], 'A');
    j := public.s20_gorev_cevap(19, 'Olcu Ders', 'olcu konu', ids[4], 'B');
    if not (j->>'tamam')::boolean or (j->>'acik_gorev')::boolean then raise exception 'OLCU: tur 2 tamam olmadi %', j; end if;
    perform public.s20_test_getir(20, 'Olcu Ders');
    j := public.s20_liste();
    if jsonb_array_length(j->'gorevler') <> 1 or not (j->'gorevler'->0->>'tamam')::boolean then raise exception 'OLCU: liste gorevleri %', j->'gorevler'; end if;
    n := n + 4;
    -- deneme 20: %100 → görev yok
    j := public.s20_test_bitir(20, 'Olcu Ders', '{"olcu-e/1":"B"}'::jsonb, 10);
    if (j->>'gorev')::int <> 0 or exists (select 1 from public.s20_gorev where user_id = a and deneme = 20) then raise exception 'OLCU: %60 ustunde gorev kuruldu'; end if;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where email = 'olcu-s20g@tetikte.invalid') or exists (select 1 from public.paket_soru where id like 'olcu-gorev/%')
     or exists (select 1 from public.s20_deneme where no in (19,20)) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'S20 GOREV OZ-SINAV: % vaka TAMAM', n;
end $$;
