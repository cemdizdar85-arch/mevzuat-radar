-- ============================================================================
--  SON 20 GÜN DENEMELERİ — KASA + ERİŞİM + SONUÇ  ·  28.10.2026 (site kolu)
--
--  CEM 28.10: "Son 20 Gün deneme sayfası planını onaylıyorum: s20 deneme kaydı + kasa erişimi (7 Deneme, Tam Paket,
--  kurucu) + son-20-gun.html ders ders test + karne + söz sayacı. 1 Kasım'da D5–D7, D1–D4 kalite onayımla."
--
--  NEDEN AYRI KASA: (1) son20-sgs (999 TL) paket_erisim_var'a bilerek takılmaz → bütün SGS bankası açılmasın.
--  (2) sgs-s20-* soruları 27.10'dan beri paket_soru'ya girmez (havuz-kur KAPI-S20). (3) Site deponun TAMAMINI yayınlıyor
--  (28.10 ölçüldü: /CLAUDE.md, /radar-app/sql/... 200) → deneme soru listesi depoya YAZILMAZ; liste yalnız burada durur.
--
--  NE YAPAR:
--   s20_deneme  deneme başına ad, süre, açılış anı, kalite onayı. AÇIK = kalite_onay dolu + acilis <= now().
--   s20_soru    denemenin soruları (veri TAM: doğru + açıklama). anon/authenticated OKUYAMAZ.
--   s20_sonuc   ders testi başına İLK çözüm (söz "ilk çözüm sayılır"). Sonraki çözümler yazılmaz.
--   s20_erisim()             son20-sgs · sgs · sgs-* · sinav-249 · tam · kurucu (boş paket = tam), süresi bitmemiş.
--   s20_liste()              denemeler + ders sayıları + bu kişinin ilk-çözüm sonuçları (anon da çağırır: sonuçsuz).
--   s20_test_getir(no,ders)  sorular DOĞRUSUZ ve AÇIKLAMASIZ (yalnız soru + şıklar); sayılır + tavanlı (kasa_cekim_izin2).
--   s20_test_bitir(no,ders,cevap,sure)  puanı SUNUCU hesaplar (söz istemcide değiştirilemez), ilk çözümü yazar,
--                                       doğru şıkları + tam veriyi (açıklama) döndürür.
--   s20_deneme_yukle(jsonb)  YALNIZ servis anahtarı. Soru verisi paket_soru'dan sunucu içinde kopyalanır; paket_soru'da
--                            olmayan (s20) soru öğenin kendi "veri" alanıyla gelir. Çözülmüş denemenin soruları "zorla"sız değişmez.
--  🚫 GÖRMEZ: kalite raporunun içeriği (kalite_onay yalnız metin; yükleyici betik doldurur) · ikinci dalga (çizim, yeniden çöz,
--     konu karnesi, görevler) · istemci sayacının dürüstlüğü (süre bilgi amaçlı, puanı etkilemez).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (bütün satırlar geri alınır).
-- ============================================================================

create table if not exists public.s20_deneme (
  no          integer primary key check (no between 1 and 20),
  ad          text not null,
  sure_dk     integer not null default 165 check (sure_dk between 1 and 400),
  acilis      timestamptz,
  kalite_onay text,
  yuklenme    timestamptz not null default now()
);
create table if not exists public.s20_soru (
  deneme  integer not null references public.s20_deneme(no) on delete cascade,
  id      text not null,
  ders    text not null,
  sira    integer not null,
  konu    text,
  veri    jsonb not null,
  primary key (deneme, id)
);
create index if not exists s20_soru_ders on public.s20_soru (deneme, ders, sira);
create table if not exists public.s20_sonuc (
  user_id uuid not null references auth.users(id) on delete cascade,
  deneme  integer not null,
  ders    text not null,
  dogru   integer not null,
  yanlis  integer not null,
  bos     integer not null,
  toplam  integer not null,
  cevap   jsonb not null,
  sure_sn integer,
  zaman   timestamptz not null default now(),
  primary key (user_id, deneme, ders)
);
alter table public.s20_deneme enable row level security;
alter table public.s20_soru   enable row level security;
alter table public.s20_sonuc  enable row level security;
revoke all on public.s20_deneme, public.s20_soru, public.s20_sonuc from anon, authenticated;

create or replace function public.s20_erisim()
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (
    select 1 from public.paket_uyeler pu
    where pu.user_id = auth.uid()
      and (pu.bitis is null or pu.bitis >= current_date)
      and (coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu','son20-sgs','sgs','sinav-249')
           or lower(trim(pu.paket)) like 'sgs-%')
  );
$fn$;

create or replace function public._s20_acik(p_no integer)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (select 1 from public.s20_deneme d
                 where d.no = p_no and coalesce(btrim(d.kalite_onay),'') <> '' and d.acilis is not null and d.acilis <= now());
$fn$;

create or replace function public.s20_liste()
returns jsonb language plpgsql stable security definer set search_path = public as $fn$
declare u uuid := auth.uid();
begin
  return jsonb_build_object(
    'oturum', u is not null,
    'erisim', public.s20_erisim(),
    'simdi', now(),
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

create or replace function public._s20_kapi(p_no integer)
returns void language plpgsql stable security definer set search_path = public as $fn$
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20_erisim() then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  if not public._s20_acik(p_no) then raise exception 'S20_KAPALI' using errcode = 'P0001'; end if;
end $fn$;

create or replace function public.s20_test_getir(p_deneme integer, p_ders text)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare ids text[]; neden text;
begin
  perform public._s20_kapi(p_deneme);
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
declare n_d int := 0; n_y int := 0; n_b int := 0; n_t int := 0; c text; r record; temiz jsonb := '{}'::jsonb; ilk boolean;
begin
  perform public._s20_kapi(p_deneme);
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
  return jsonb_build_object(
    'dogru', n_d, 'yanlis', n_y, 'bos', n_b, 'toplam', n_t, 'ilk', ilk,
    'kayitli', (select jsonb_build_object('dogru', x.dogru, 'yanlis', x.yanlis, 'bos', x.bos, 'toplam', x.toplam)
                  from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders),
    'sorular', (select jsonb_agg(jsonb_build_object('id', s.id, 'konu', s.konu, 'veri', s.veri) order by s.sira)
                  from public.s20_soru s where s.deneme = p_deneme and s.ders = p_ders));
end $fn$;

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
  select n, e->>'id', coalesce(e->>'ders', ps.ders), coalesce((e->>'sira')::int, o::int), coalesce(e->>'konu', ps.konu),
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

revoke all on function public.s20_erisim(), public._s20_acik(integer), public._s20_kapi(integer), public.s20_liste(),
  public.s20_test_getir(integer, text), public.s20_test_bitir(integer, text, jsonb, integer), public.s20_deneme_yukle(jsonb) from public;
grant execute on function public.s20_liste() to anon, authenticated;
grant execute on function public.s20_erisim(), public.s20_test_getir(integer, text), public.s20_test_bitir(integer, text, jsonb, integer) to authenticated;
grant execute on function public.s20_deneme_yukle(jsonb) to service_role;

-- GÖÇ İÇİ ÖZ-SINAV (bütün satırlar geri alınır)
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e2801';
  n int := 0; j jsonb; v text;
  q jsonb := '{"soru":"Olcu sorusu?","siklar":{"A":"a","B":"b","C":"c","D":"d","E":"e"},"dogru":"B","aciklama":"gizli"}';
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20d@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values (a, 'son20-sgs', current_date + 30);
    perform public.s20_deneme_yukle(jsonb_build_object('no', 19, 'ad', 'Olcu acik', 'acilis', now() - interval '1 minute', 'kalite_onay', 'olcu',
      'sorular', jsonb_build_array(jsonb_build_object('id','olcu/1','ders','Olcu Ders','sira',1,'veri',q),
                                   jsonb_build_object('id','olcu/2','ders','Olcu Ders','sira',2,'veri',q))));
    perform public.s20_deneme_yukle(jsonb_build_object('no', 20, 'ad', 'Olcu onaysiz', 'acilis', now() - interval '1 minute',
      'sorular', jsonb_build_array(jsonb_build_object('id','olcu/3','ders','Olcu Ders','sira',1,'veri',q))));
    begin
      perform public.s20_deneme_yukle(jsonb_build_object('no', 18, 'ad', 'x', 'sorular', jsonb_build_array(jsonb_build_object('id','yok/olmayan-kimlik'))));
      raise exception 'OLCU: eksik soru yuklendi';
    exception when others then if sqlerrm not like 'S20_EKSIK%' then raise; end if; end;
    n := n + 1;
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    if auth.uid() is distinct from a then raise exception 'OLCU: auth.uid ayarlanamadi'; end if;

    -- 7 Deneme üyesi: s20 açık, banka KAPALI
    if not public.s20_erisim() then raise exception 'OLCU: son20-sgs s20 erisimi yok'; end if;
    if public.paket_erisim_var('sgs', 'Finansal Muhasebe') then raise exception 'OLCU: son20-sgs SGS bankasini aciyor'; end if;
    n := n + 2;
    j := public.s20_test_getir(19, 'Olcu Ders');
    if jsonb_array_length(j->'sorular') <> 2 then raise exception 'OLCU: soru sayisi %', jsonb_array_length(j->'sorular'); end if;
    if (j->'sorular'->0) ? 'dogru' or (j->'sorular'->0) ? 'veri' or position('gizli' in j::text) > 0 or position('dogru' in j::text) > 0 then
      raise exception 'OLCU: test getirirken cevap/aciklama sizdi'; end if;
    n := n + 2;
    begin perform public.s20_test_getir(20, 'Olcu Ders'); raise exception 'OLCU: onaysiz deneme acildi';
    exception when others then if sqlerrm <> 'S20_KAPALI' then raise; end if; end;
    n := n + 1;
    j := public.s20_test_bitir(19, 'Olcu Ders', '{"olcu/1":"B","olcu/2":"a"}'::jsonb, 120);
    if (j->>'dogru')::int <> 1 or (j->>'yanlis')::int <> 1 or (j->>'bos')::int <> 0 or not (j->>'ilk')::boolean then raise exception 'OLCU: puan yanlis %', j; end if;
    if j->'sorular'->0->'veri'->>'aciklama' <> 'gizli' then raise exception 'OLCU: bitiste aciklama donmedi'; end if;
    j := public.s20_test_bitir(19, 'Olcu Ders', '{"olcu/1":"B","olcu/2":"B"}'::jsonb, 60);
    if (j->>'ilk')::boolean or (j->'kayitli'->>'dogru')::int <> 1 or (j->>'dogru')::int <> 2 then raise exception 'OLCU: ilk cozum korunmadi %', j; end if;
    n := n + 3;
    j := public.s20_liste();
    if not (j->>'erisim')::boolean or (select count(*) from jsonb_array_elements(j->'denemeler') e where (e->>'no')::int = 19 and (e->>'acik')::boolean
         and (e->'dersler'->0->'sonuc'->>'dogru')::int = 1) <> 1 then raise exception 'OLCU: liste yanlis'; end if;
    n := n + 1;
    -- Tam Paket (sgs) ve kurucu açar; Yeterlilik açmaz; süresi biten açmaz
    update public.paket_uyeler set paket = 'sgs' where user_id = a;            if not public.s20_erisim() then raise exception 'OLCU: sgs acmiyor'; end if;
    update public.paket_uyeler set paket = 'kurucu' where user_id = a;         if not public.s20_erisim() then raise exception 'OLCU: kurucu acmiyor'; end if;
    update public.paket_uyeler set paket = 'yeterlilik-tum' where user_id = a; if public.s20_erisim() then raise exception 'OLCU: yeterlilik aciyor'; end if;
    begin perform public.s20_test_getir(19, 'Olcu Ders'); raise exception 'OLCU: paketsiz soru geldi';
    exception when others then if sqlerrm <> 'S20_PAKET' then raise; end if; end;
    update public.paket_uyeler set paket = 'son20-sgs', bitis = current_date - 1 where user_id = a;
    if public.s20_erisim() then raise exception 'OLCU: suresi biten aciyor'; end if;
    n := n + 5;
    -- çözülmüş deneme zorla'sız değişmez
    perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
    begin
      perform public.s20_deneme_yukle(jsonb_build_object('no', 19, 'ad', 'Olcu acik', 'kalite_onay', 'olcu',
        'sorular', jsonb_build_array(jsonb_build_object('id','olcu/9','ders','Olcu Ders','sira',1,'veri',q))));
      raise exception 'OLCU: cozulmus deneme degisti';
    exception when others then if sqlerrm not like 'S20_COZULMUS%' then raise; end if; end;
    j := public.s20_liste();
    if (j->>'oturum')::boolean or (j->>'erisim')::boolean then raise exception 'OLCU: oturumsuz liste erisim gosteriyor'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  perform set_config('request.jwt.claims', '', true); perform set_config('request.jwt.claim.sub', '', true);
  if exists (select 1 from auth.users where email = 'olcu-s20d@tetikte.invalid') or exists (select 1 from public.s20_deneme where no in (18,19,20)) then
    raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'S20 DENEME OZ-SINAV: % vaka TAMAM', n;
end $$;
