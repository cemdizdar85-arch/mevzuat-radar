-- _anlik_teklif_secenekler(text)
CREATE OR REPLACE FUNCTION public._anlik_teklif_secenekler(p_sinav text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object('paket', a.paket, 'indirim_tl', a.indirim_tl) order by a.indirim_tl), '[]'::jsonb)
    from anlik_teklif_ayar a where a.sinav = p_sinav and a.acik;
$function$
;

-- _kaynak_artir(date,text,text)
CREATE OR REPLACE FUNCTION public._kaynak_artir(p_gun date, p_etiket text, p_olay text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n integer;
begin
  if p_gun is null or p_etiket is null or p_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}$'
     or coalesce(p_olay,'') not in ('ziyaret','test','uye','ornek') then
    return false;
  end if;
  if not exists (select 1 from public.kaynak_sayac s where s.gun = p_gun and s.etiket = p_etiket)
     and (select count(distinct s.etiket) from public.kaynak_sayac s where s.gun = p_gun) >= 60 then
    return false;
  end if;
  insert into public.kaynak_sayac as k (gun, etiket, olay, adet) values (p_gun, p_etiket, p_olay, 1)
  on conflict (gun, etiket, olay) do update set adet = k.adet + 1 where k.adet < 50000
  returning k.adet into n;
  return n is not null;
end
$function$
;

-- _kaynak_hesap_etiketi(jsonb)
CREATE OR REPLACE FUNCTION public._kaynak_hesap_etiketi(p_meta jsonb)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  select case
    when lower(p_meta->>'kaynak_etiket') ~ '^[a-z0-9][a-z0-9_-]{0,31}$' then lower(p_meta->>'kaynak_etiket')
    when coalesce(p_meta->>'kaynak', '') like 'uygulama%' then 'uygulama'
  end
$function$
;

-- _ozel_kod_gecerli(text,text)
CREATE OR REPLACE FUNCTION public._ozel_kod_gecerli(p_kod text, p_paket text)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when o.indirim_paket is not null then (o.indirim_paket ->> p_paket)::int else o.indirim_tl end
    from ozel_kod o
   where o.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
     and o.iptal is null
     and o.son > now()
     and p_paket = any (o.paketler)
     and (o.indirim_paket is null or (o.indirim_paket ->> p_paket) is not null)
     and (o.kullanildi is null
          or not exists (select 1 from siparisler s where s.siparis_no = o.siparis_no and s.durum <> 'iptal'));
$function$
;

-- _paket_kapsar(text,text[],text,text[])
CREATE OR REPLACE FUNCTION public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[])
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare v text := lower(btrim(coalesce(p_var, ''))); s text := public._paket_sinavi(p_yeni);
begin
  if lower(btrim(coalesce(p_yeni, ''))) in ('son20-sgs', 'son20-yet') then          -- 27.10 + 28.10 Son 20 Gün ön satış
    return v in ('son20-sgs', 'son20-yet', 'tam', 'kurucu') or public._paket_sinavi(v) is not null;
  end if;
  if v in ('tam', 'kurucu') then return true; end if;
  if s is null or public._paket_sinavi(v) is distinct from s then return false; end if;
  if s = 'sgs' then return true; end if;
  if coalesce(array_length(p_var_ders, 1), 0) = 0 then return true; end if;        -- ders listesiz = tümü
  if coalesce(array_length(p_yeni_ders, 1), 0) = 0 then return false; end if;      -- tüm pakete yükseltme
  return p_yeni_ders <@ p_var_ders;                                                 -- yeni ders varsa serbest
end $function$
;

-- _paket_sinavi(text)
CREATE OR REPLACE FUNCTION public._paket_sinavi(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when lower(btrim(coalesce(p, ''))) ~ '^sgs' or lower(btrim(coalesce(p, ''))) = 'sinav-249' then 'sgs'
    when lower(btrim(coalesce(p, ''))) ~ '^yeterlilik' or lower(btrim(coalesce(p, ''))) = 'smmm' then 'yeterlilik'
    when lower(btrim(coalesce(p, ''))) ~ '^kgk' then 'kgk'
    else null end
$function$
;

-- _s20_acik(integer)
CREATE OR REPLACE FUNCTION public._s20_acik(p_no integer)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.s20_deneme d
                 where d.no = p_no and coalesce(btrim(d.kalite_onay),'') <> '' and d.acilis is not null and d.acilis <= now());
$function$
;

-- _s20_gorev_acik(uuid)
CREATE OR REPLACE FUNCTION public._s20_gorev_acik(p_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.s20_gorev g where g.user_id = p_uid and not g.tamam);
$function$
;

-- _s20_gorev_aday(uuid,text,text,text[],integer)
CREATE OR REPLACE FUNCTION public._s20_gorev_aday(p_uid uuid, p_ders text, p_konu text, p_haric text[], p_adet integer)
 RETURNS text[]
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(array(
    select ps.id from public.paket_soru ps
     where ps.sinav = 'sgs' and ps.ders = p_ders and ps.konu = p_konu
       and ps.id not like 'sgs-s20-%'
       and not (ps.id = any(coalesce(p_haric, '{}')))
       and not exists (select 1 from public.s20_soru s where s.id = ps.id)
       and not exists (select 1 from public.kasa_cevap kc where kc.user_id = p_uid and kc.soru_id = ps.id)
       and coalesce(ps.veri->>'soru','') <> '' and jsonb_typeof(ps.veri->'siklar') = 'object' and coalesce(ps.veri->>'dogru','') ~ '^[A-E]$'
     order by random() limit p_adet), '{}');
$function$
;

-- _s20_gorev_kapi(integer,text)
CREATE OR REPLACE FUNCTION public._s20_gorev_kapi(p_deneme integer, p_ders text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if public._s20_gorev_acik(auth.uid())
     and not exists (select 1 from public.s20_sonuc x where x.user_id = auth.uid() and x.deneme = p_deneme and x.ders = p_ders) then
    raise exception 'S20_GOREV' using errcode = 'P0001';
  end if;
end $function$
;

-- _s20_gorev_kur(uuid,integer)
CREATE OR REPLACE FUNCTION public._s20_gorev_kur(p_uid uuid, p_deneme integer)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- _s20_gorevler(uuid)
CREATE OR REPLACE FUNCTION public._s20_gorevler(p_uid uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object('deneme', g.deneme, 'ders', g.ders, 'konu', g.konu, 'sira', g.sira, 'tur', g.tur,
           'dogru', g.dogru, 'cevaplanan', (select count(*) from jsonb_object_keys(g.cevap)), 'tamam', g.tamam)
           order by g.deneme, g.sira), '[]'::jsonb)
    from public.s20_gorev g where g.user_id = p_uid;
$function$
;

-- _s20_kapi(integer)
CREATE OR REPLACE FUNCTION public._s20_kapi(p_no integer)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'S20_OTURUM' using errcode = '42501'; end if;
  if not public.s20_erisim() then raise exception 'S20_PAKET' using errcode = '42501'; end if;
  if not public._s20_acik(p_no) then raise exception 'S20_KAPALI' using errcode = 'P0001'; end if;
end $function$
;

-- _siparis_isle(bigint,uuid,text)
CREATE OR REPLACE FUNCTION public._siparis_isle(p_sid bigint, p_uid uuid, p_yol text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean; v_ders text[];
begin
  if p_uid is null then return 'BOS'; end if;
  select * into s from public.siparisler where id = p_sid for update;
  if not found or s.durum <> 'odendi' then return 'SIPARIS_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> p_uid then return 'BASKA_HESAPTA'; end if;
  v_bitis := coalesce(s.paket_bitis,
                      greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92));
  if v_bitis < current_date then return 'SURESI_GECMIS'; end if;
  v_ders := case when s.paket ~ '^(yeterlilik-[1-4]|kgk-[1-3])$' then s.secilen_dersler else null end;
  -- KGK modül paketinde boş seçim = kasada "hepsi"; tek konu parasına dört konu açılmasın
  if s.paket ~ '^kgk-[1-3]$' and coalesce(array_length(v_ders, 1), 0) = 0 then return 'DERS_SECIMI_YOK'; end if;
  select * into v_eski from public.paket_uyeler where user_id = p_uid;
  v_var := found;
  if not (v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis) then
    insert into public.paket_uyeler (user_id, paket, bitis, dersler)
      values (p_uid, s.paket, v_bitis, v_ders)
      on conflict (user_id) do update
        set paket = excluded.paket, dersler = excluded.dersler,
            bitis = greatest(excluded.bitis, case when paket_uyeler.paket = excluded.paket and paket_uyeler.bitis >= current_date then paket_uyeler.bitis else excluded.bitis end);
  end if;
  update public.siparisler set bagli_kullanici = p_uid, bagli_tarih = now(), bagli_yol = left(coalesce(p_yol, ''), 20)
   where id = s.id and bagli_kullanici is null;
  return case when v_var and v_eski.paket = s.paket and v_eski.bitis >= v_bitis then 'ZATEN_ACIK' else 'ACILDI' end;
end $function$
;

-- alacak_abone_mi()
CREATE OR REPLACE FUNCTION public.alacak_abone_mi()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.abonelikler a
    where a.user_id = auth.uid()
      and a.durum = 'aktif'
      and (a.bitis is null or a.bitis >= current_date)
      and (a.paket = 'tam' or 'alacak' = any(a.radarlar))
  )
$function$
;

-- alacak_ara(text)
CREATE OR REPLACE FUNCTION public.alacak_ara(p_sorgu text)
 RETURNS TABLE(ilan_no text, baslik text, kurum text, il text, ilce text, tarih_str text, tur text, url text, borclu text, vkn text, tip text, esas_no text, mahkeme text, muhlet_tip text, muhlet_ay integer, muhlet_baslangic date, muhlet_bitis date, komiser text, itiraz_gun integer, borclular jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
             i.borclu, i.vkn, 'vkn'::text,
             i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
             i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun,
             public.alacak_borclu_maskele(i.borclular)
      from public.alacak_ilan i
      where (i.vkn is not null and (i.vkn = say or i.vkn like say||'%' or say like i.vkn||'%'))
         or (i.vknler is not null and say = any(i.vknler))
         or (i.tckn is not null and length(say) = 11 and i.tckn = say)
         or (i.tcknler is not null and length(say) = 11 and say = any(i.tcknler))
      order by i.tarih desc nulls last
      limit 25;
  elsif length(ad) >= 8 or array_length(regexp_split_to_array(ad, ' '), 1) >= 2 then
    if length(ad) < 5 then
      raise exception 'KISA_SORGU' using hint = 'En az 5 harf ya da iki kelime yaz.';
    end if;
    return query
      select i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih_str, i.tur, i.url,
             i.borclu, i.vkn, 'ad'::text,
             i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
             i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun,
             public.alacak_borclu_maskele(i.borclular)
      from public.alacak_ilan i
      where i.borclu_norm is not null and i.borclu_norm like '%'||ad||'%'
      order by i.tarih desc nulls last
      limit 25;
  else
    raise exception 'KISA_SORGU'
      using hint = 'Tam VKN/TCKN ya da en az iki kelimelik unvan yaz (tek kelime yanlis firma getirir).';
  end if;
end;
$function$
;

-- alacak_borclu_maskele(jsonb)
CREATE OR REPLACE FUNCTION public.alacak_borclu_maskele(p jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p is null or jsonb_typeof(p) <> 'array' then null else (
    select jsonb_agg(
      case when b ? 'tckn'
        then jsonb_build_object('ad', b->>'ad', 'tckn_var', true)
        else b - 'tckn'
      end)
    from jsonb_array_elements(p) as b
    where jsonb_typeof(b) = 'object'
  ) end;
$function$
;

-- alacak_sayi()
CREATE OR REPLACE FUNCTION public.alacak_sayi()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'adet',        (select count(*) from public.alacak_ilan),
    'borclulu',    (select count(*) from public.alacak_ilan where borclu is not null),
    'kimlikli',    (select count(*) from public.alacak_ilan where vkn is not null or tckn is not null),
    'guncelleme',  (select max(guncelleme) from public.alacak_ilan)
  )
$function$
;

-- alacak_toplu(text[])
CREATE OR REPLACE FUNCTION public.alacak_toplu(p_liste text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
           i.tur, i.url, i.borclu, i.vkn, 'vkn'::text as tip,
           i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
           i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun, i.borclular
    from q
    join public.alacak_ilan i
      on length(q.say) >= 7
     and ( (i.vkn is not null and (i.vkn = q.say or i.vkn like q.say||'%' or q.say like i.vkn||'%'))
        -- 20.08: grup konkordatosunda 2./3. borclunun VKN'si burada
        or (i.vknler is not null and q.say = any(i.vknler))
        or (i.tckn is not null and length(q.say) = 11 and i.tckn = q.say)
        or (i.tcknler is not null and length(q.say) = 11 and q.say = any(i.tcknler)) )
    union all
    select q.ham, i.ilan_no, i.baslik, i.kurum, i.il, i.ilce, i.tarih, i.tarih_str,
           i.tur, i.url, i.borclu, i.vkn, 'ad'::text,
           i.esas_no, i.mahkeme, i.muhlet_tip, i.muhlet_ay,
           i.muhlet_baslangic, i.muhlet_bitis, i.komiser, i.itiraz_gun, i.borclular
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
           ham, ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url, borclu, vkn, tip,
           esas_no, mahkeme, muhlet_tip, muhlet_ay, muhlet_baslangic, muhlet_bitis,
           komiser, itiraz_gun, borclular
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
    'eslesenSorgu', (select count(distinct ham) from t),
    'kayitlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'sorgu',  case when t.sira <= acik then t.ham else null end,
        'gizli',  (t.sira > acik),
        'tip',    t.tip,
        'tur',    t.tur,
        'tarih',  case when t.sira <= acik then t.tarih_str else null end,
        'baslik', case when t.sira <= acik then t.baslik else null end,
        'borclu', case when t.sira <= acik then t.borclu
                       else left(coalesce(t.borclu,'—'),1) || repeat('•', 9) end,
        'vkn',    case when t.sira <= acik then t.vkn else null end,
        'kurum',  case when t.sira <= acik then t.kurum else null end,
        'il',     case when t.sira <= acik then t.il else null end,
        'url',    case when t.sira <= acik then t.url else null end,
        -- 20.08 YENI ALANLAR — kilitli kayitta hepsi null (bkz. basliktaki not)
        'esas_no',          case when t.sira <= acik then t.esas_no end,
        'mahkeme',          case when t.sira <= acik then t.mahkeme end,
        'muhlet_tip',       case when t.sira <= acik then t.muhlet_tip end,
        'muhlet_ay',        case when t.sira <= acik then t.muhlet_ay end,
        'muhlet_baslangic', case when t.sira <= acik then t.muhlet_baslangic end,
        'muhlet_bitis',     case when t.sira <= acik then t.muhlet_bitis end,
        'komiser',          case when t.sira <= acik then t.komiser end,
        'itiraz_gun',       case when t.sira <= acik then t.itiraz_gun end,
        'borclular',        case when t.sira <= acik
                                 then public.alacak_borclu_maskele(t.borclular) end
      ) order by t.sira)
      from t
    ), '[]'::jsonb)
  ) into sonuc;

  return sonuc;
end;
$function$
;

-- alacak_vitrin(text,text)
CREATE OR REPLACE FUNCTION public.alacak_vitrin(p_durum text DEFAULT NULL::text, p_tur text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'adet',    (select count(*) from public.alacak_ilan),
    'son30',   (select count(*) from public.alacak_ilan where tarih >= current_date - 30),
    'son30Konkordato', (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='konkordato'),
    'son30Iflas',      (select count(*) from public.alacak_ilan where tarih >= current_date - 30 and tur='iflas'),
    'enYeniTarih', (select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan),
    'enYeniIso',   (select to_char(max(tarih),'YYYY-MM-DD') from public.alacak_ilan),
    'turSayilari', coalesce((
      select jsonb_object_agg(t.k, t.n)
      from (
        select coalesce(nullif(tur,''),'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'durumlar', coalesce((
      select jsonb_object_agg(d.k, d.n)
      from (
        select coalesce(karar_durumu,'diger') as k, count(*) as n
        from public.alacak_ilan
        where tarih >= current_date - 365
          and (p_tur is null or coalesce(nullif(tur,''),'diger') = p_tur)
        group by 1
      ) d
    ), '{}'::jsonb),
    'secilenAdet', (
      select count(*) from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    -- YENI: secili suzgecin OLCULMUS kapsami
    'secilenIlk', (
      select to_char(min(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenSon', (
      select to_char(max(tarih),'DD.MM.YYYY') from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    'secilenGun', (
      select (max(tarih) - min(tarih))::int from public.alacak_ilan
      where tarih >= current_date - 365
        and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
    ),
    -- YENI: tur basina ilk tarih + gun (varsayilan ekrandaki serh icin)
    'turIlk', coalesce((
      select jsonb_object_agg(t.k, t.ilk)
      from (
        select coalesce(nullif(tur,''),'diger')  as k,
               to_char(min(tarih),'DD.MM.YYYY')  as ilk
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'turGun', coalesce((
      select jsonb_object_agg(t.k, t.gun)
      from (
        select coalesce(nullif(tur,''),'diger') as k,
               (max(tarih) - min(tarih))::int   as gun
        from public.alacak_ilan
        where tarih >= current_date - 365
        group by 1
      ) t
    ), '{}'::jsonb),
    'illerSuzgecli', true,
    'iller', coalesce((
      select jsonb_agg(jsonb_build_object('il', g.il_ad, 't', g.t, 'k', g.k, 'i', g.i)
                       order by g.t desc)
      from (
        select coalesce(nullif(il,''),'Belirtilmemiş') as il_ad,
               count(*)                                as t,
               count(*) filter (where tur='konkordato') as k,
               count(*) filter (where tur='iflas')      as i
        from public.alacak_ilan
        where tarih >= current_date - 365
          and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
          and (p_durum is null or coalesce(karar_durumu,'diger')   = p_durum)
        group by 1
        order by 2 desc
        limit 12
      ) g
    ), '[]'::jsonb),
    'ilanlar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'ilanNo', ilan_no, 'baslik', baslik, 'kurum', kurum, 'il', il,
        'tarih', tarih_str, 'tur', tur, 'url', url, 'borclu', borclu, 'vkn', vkn,
        'karar', karar_durumu, 'muhletBitis', muhlet_bitis
      ) order by tarih desc nulls last)
      from (
        select * from public.alacak_ilan
        where (p_durum is null or coalesce(karar_durumu,'diger') = p_durum)
          and (p_tur   is null or coalesce(nullif(tur,''),'diger') = p_tur)
        order by tarih desc nulls last limit 60
      ) v
    ), '[]'::jsonb)
  )
$function$
;

-- alacak_yaz(jsonb)
CREATE OR REPLACE FUNCTION public.alacak_yaz(p_kayitlar jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      nullif(regexp_replace(coalesce(k->>'tckn',''),'\D','','g'),'') as tckn,
      nullif(btrim(coalesce(k->>'metin','')),'')     as metin,
      nullif(btrim(coalesce(k->>'esas_no','')),'')   as esas_no,
      nullif(btrim(coalesce(k->>'sicil_no','')),'')  as sicil_no,
      nullif(btrim(coalesce(k->>'mahkeme','')),'')   as mahkeme,
      nullif(btrim(coalesce(k->>'muhlet_tip','')),'') as muhlet_tip,
      nullif(k->>'muhlet_ay','')::int                as muhlet_ay,
      nullif(k->>'muhlet_baslangic','')::date        as muhlet_baslangic,
      nullif(k->>'muhlet_bitis','')::date            as muhlet_bitis,
      nullif(btrim(coalesce(k->>'komiser','')),'')   as komiser,
      nullif(k->>'itiraz_gun','')::int               as itiraz_gun,
      -- 07.09 SIGORTA: yalniz NESNE ogeler sayilir; [null] ve [] -> NULL
      case when jsonb_typeof(k->'borclular') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'borclular') e where jsonb_typeof(e) = 'object')
           then (select jsonb_agg(e) from jsonb_array_elements(k->'borclular') e where jsonb_typeof(e) = 'object')
      end                                            as borclular,
      case when jsonb_typeof(k->'vknler') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'vknler') e where jsonb_typeof(e) = 'string')
           then array(select e #>> '{}' from jsonb_array_elements(k->'vknler') e where jsonb_typeof(e) = 'string')
      end                                            as vknler,
      case when jsonb_typeof(k->'tcknler') = 'array'
            and exists (select 1 from jsonb_array_elements(k->'tcknler') e where jsonb_typeof(e) = 'string')
           then array(select e #>> '{}' from jsonb_array_elements(k->'tcknler') e where jsonb_typeof(e) = 'string')
      end                                            as tcknler
    from jsonb_array_elements(p_kayitlar) as k
    where coalesce(k->>'ilanNo','') <> ''
  ),
  y as (
    insert into public.alacak_ilan
      (ilan_no, baslik, kurum, il, ilce, tarih, tarih_str, tur, url,
       borclu, borclu_norm, vkn, tckn, metin, esas_no, sicil_no, mahkeme,
       muhlet_tip, muhlet_ay, muhlet_baslangic, muhlet_bitis, komiser, itiraz_gun,
       borclular, vknler, tcknler, guncelleme)
    select g.ilan_no, g.baslik, g.kurum, g.il, g.ilce, g.tarih, g.tarih_str, g.tur, g.url,
           g.borclu, public.tr_fold(g.borclu), g.vkn, g.tckn, g.metin, g.esas_no, g.sicil_no,
           g.mahkeme, g.muhlet_tip, g.muhlet_ay, g.muhlet_baslangic, g.muhlet_bitis,
           g.komiser, g.itiraz_gun, g.borclular, g.vknler, g.tcknler, now()
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
      borclu      = coalesce(excluded.borclu,  alacak_ilan.borclu),
      borclu_norm = coalesce(excluded.borclu_norm, alacak_ilan.borclu_norm),
      vkn         = coalesce(excluded.vkn,     alacak_ilan.vkn),
      tckn        = coalesce(excluded.tckn,    alacak_ilan.tckn),
      metin       = coalesce(excluded.metin,   alacak_ilan.metin),
      esas_no     = coalesce(excluded.esas_no, alacak_ilan.esas_no),
      sicil_no    = coalesce(excluded.sicil_no, alacak_ilan.sicil_no),
      mahkeme     = coalesce(excluded.mahkeme, alacak_ilan.mahkeme),
      muhlet_tip  = coalesce(excluded.muhlet_tip, alacak_ilan.muhlet_tip),
      muhlet_ay   = coalesce(excluded.muhlet_ay,  alacak_ilan.muhlet_ay),
      muhlet_baslangic = coalesce(excluded.muhlet_baslangic, alacak_ilan.muhlet_baslangic),
      muhlet_bitis     = coalesce(excluded.muhlet_bitis,     alacak_ilan.muhlet_bitis),
      komiser     = coalesce(excluded.komiser, alacak_ilan.komiser),
      itiraz_gun  = coalesce(excluded.itiraz_gun, alacak_ilan.itiraz_gun),
      borclular   = coalesce(excluded.borclular, alacak_ilan.borclular),
      vknler      = coalesce(excluded.vknler,  alacak_ilan.vknler),
      tcknler     = coalesce(excluded.tcknler, alacak_ilan.tcknler),
      guncelleme  = now()
    returning 1
  )
  select count(*) into n from y;
  return n;
end;
$function$
;

-- anlik_teklif_al(text,text,text)
CREATE OR REPLACE FUNCTION public.anlik_teklif_al(p_sonuc text, p_kaynak text, p_ders text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid   uuid := auth.uid();
  v_ayar  anlik_teklif_ayar%rowtype;
  v_b     text;
begin
  if v_uid is null then return null; end if;
  if coalesce(p_kaynak, '') not in ('seviye', 'prova') then return null; end if;
  if coalesce(p_sonuc, '') !~ '^[A-Za-z0-9:._-]{4,80}$' then return null; end if;
  if p_ders is null or not (p_ders = any (array['Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi',
       'Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Hukuk','Sermaye Piyasası Mevzuatı','Meslek Hukuku'])) then
    return null;
  end if;
  select * into v_ayar from anlik_teklif_ayar where paket = 'yeterlilik-1' and acik;
  if not found then return null; end if;
  if exists (select 1 from anlik_teklif where user_id = v_uid and sonuc = p_sonuc) then return null; end if;
  if exists (select 1 from anlik_teklif where user_id = v_uid and ders = p_ders and kullanildi is not null) then return null; end if;
  if (select count(*) from anlik_teklif where user_id = v_uid and olusturma > now() - interval '24 hours') >= 10 then return null; end if;
  if exists (select 1 from paket_uyeler p where p.user_id = v_uid and p.bitis >= current_date
               and (p.paket in ('yeterlilik-tum', 'yeterlilik-kgk', 'tam')
                    or (p.paket ~ '^yeterlilik-[1-4]$' and p_ders = any (coalesce(p.dersler, array[]::text[]))))) then
    return null;
  end if;
  v_b := replace(gen_random_uuid()::text, '-', '');
  insert into anlik_teklif (belirtec, user_id, sonuc, kaynak, paket, ders, indirim_tl, son)
  values (v_b, v_uid, p_sonuc, p_kaynak, v_ayar.paket, p_ders, v_ayar.indirim_tl, now() + make_interval(hours => v_ayar.gecerlilik_saat))
  on conflict (user_id, sonuc) do nothing;
  if not found then return null; end if;
  return jsonb_build_object('belirtec', v_b, 'paket', v_ayar.paket, 'ders', p_ders, 'indirim_tl', v_ayar.indirim_tl,
                            'secenekler', _anlik_teklif_secenekler('yeterlilik'));
end $function$
;

-- anlik_teklif_kontrol(text)
CREATE OR REPLACE FUNCTION public.anlik_teklif_kontrol(p_belirtec text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object('belirtec', t.belirtec, 'paket', t.paket, 'ders', t.ders, 'indirim_tl', t.indirim_tl,
                            'secenekler', _anlik_teklif_secenekler('yeterlilik'))
    from anlik_teklif t
   where t.belirtec = lower(coalesce(p_belirtec, ''))
     and auth.uid() is not null and t.user_id = auth.uid()
     and t.kullanildi is null and t.son > now()
     and not exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null);
$function$
;

-- bedel_kaydi_damga()
CREATE OR REPLACE FUNCTION public.bedel_kaydi_damga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.ay := to_char(new.zaman at time zone 'UTC','YYYY-MM');
  return new;
end $function$
;

-- cevap_kaydet(uuid,uuid,text,text)
CREATE OR REPLACE FUNCTION public.cevap_kaydet(p_token uuid, p_soru_id uuid, p_cevap text, p_dosya text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update public.sorular s set cevap=coalesce(nullif(p_cevap,''),s.cevap), dosya_url=coalesce(nullif(p_dosya,''),s.dosya_url), durum='ok', cevap_tarihi=now() where s.id=p_soru_id and s.istek_id=(select id from public.istekler where token=p_token);
  get diagnostics n = row_count; return n > 0;
end; $function$
;

-- cihaz_cikar(text)
CREATE OR REPLACE FUNCTION public.cihaz_cikar(p_hedef text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_cikan int;
  v_ilk timestamptz;
begin
  if v_uid is null then return jsonb_build_object('durum', 'oturum_yok'); end if;
  select count(*), min(zaman) into v_cikan, v_ilk from public.uye_cihaz_olay
   where user_id = v_uid and olay = 'cikarildi' and zaman > now() - interval '30 days';
  if v_cikan >= 2 then
    return jsonb_build_object('durum', 'aylik_sinir', 'yeniden', v_ilk + interval '30 days');
  end if;
  delete from public.uye_cihazlar where user_id = v_uid and cihaz_id = p_hedef;
  if not found then return jsonb_build_object('durum', 'bulunamadi'); end if;
  delete from public.uye_ekran where user_id = v_uid and cihaz_id = p_hedef;
  insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_hedef, 'cikarildi');
  return jsonb_build_object('durum', 'tamam');
end;
$function$
;

-- cihaz_kontrol(text,text,boolean)
CREATE OR REPLACE FUNCTION public.cihaz_kontrol(p_cihaz text, p_etiket text DEFAULT ''::text, p_devral boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid    uuid := auth.uid();
  v_var    boolean;
  v_sayi   int;
  v_ekran  record;
  v_etiket text := left(coalesce(p_etiket, ''), 60);
begin
  if v_uid is null then
    return jsonb_build_object('durum', 'oturum_yok');
  end if;
  if p_cihaz is null or char_length(p_cihaz) not between 8 and 64 then
    return jsonb_build_object('durum', 'gecersiz');
  end if;

  select exists(select 1 from public.uye_cihazlar where user_id = v_uid and cihaz_id = p_cihaz) into v_var;
  if v_var then
    update public.uye_cihazlar set son_gorulme = now(), etiket = v_etiket
     where user_id = v_uid and cihaz_id = p_cihaz;
  else
    select count(*) into v_sayi from public.uye_cihazlar where user_id = v_uid;
    if v_sayi >= 3 then
      insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'sinir');
      return jsonb_build_object(
        'durum', 'cihaz_siniri', 'sinir', 3,
        'cihazlar', coalesce((select jsonb_agg(jsonb_build_object('etiket', etiket, 'son_gorulme', son_gorulme) order by son_gorulme desc)
                              from public.uye_cihazlar where user_id = v_uid), '[]'::jsonb));
    end if;
    insert into public.uye_cihazlar (user_id, cihaz_id, etiket) values (v_uid, p_cihaz, v_etiket);
    insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'eklendi');
  end if;

  select e.cihaz_id, e.devralma, c.etiket into v_ekran
    from public.uye_ekran e
    left join public.uye_cihazlar c on c.user_id = e.user_id and c.cihaz_id = e.cihaz_id
   where e.user_id = v_uid;

  if not found then
    insert into public.uye_ekran (user_id, cihaz_id) values (v_uid, p_cihaz);
    return jsonb_build_object('durum', 'tamam');
  end if;
  if v_ekran.cihaz_id = p_cihaz then
    return jsonb_build_object('durum', 'tamam');
  end if;
  if p_devral then
    update public.uye_ekran set cihaz_id = p_cihaz, devralma = now() where user_id = v_uid;
    insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'devraldi');
    return jsonb_build_object('durum', 'tamam');
  end if;
  return jsonb_build_object('durum', 'baska_ekran', 'aktif_etiket', coalesce(v_ekran.etiket, 'baska bir cihaz'));
end;
$function$
;

-- cihazlarim(text)
CREATE OR REPLACE FUNCTION public.cihazlarim(p_cihaz text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'sinir', 3,
    'cikarma_hakki', greatest(0, 2 - (select count(*) from public.uye_cihaz_olay
                                       where user_id = auth.uid() and olay = 'cikarildi'
                                         and zaman > now() - interval '30 days')),
    'cihazlar', coalesce((select jsonb_agg(jsonb_build_object(
                    'cihaz_id', c.cihaz_id, 'etiket', c.etiket,
                    'ilk_gorulme', c.ilk_gorulme, 'son_gorulme', c.son_gorulme,
                    'bu_cihaz', c.cihaz_id = coalesce(p_cihaz, ''),
                    'aktif_ekran', exists(select 1 from public.uye_ekran e where e.user_id = c.user_id and e.cihaz_id = c.cihaz_id)
                  ) order by c.son_gorulme desc)
                  from public.uye_cihazlar c where c.user_id = auth.uid()), '[]'::jsonb)
  );
$function$
;

-- cizim_ses_erisim(text)
CREATE OR REPLACE FUNCTION public.cizim_ses_erisim(p_id text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select auth.uid() is not null and exists (
    select 1 from public.paket_soru s
    where s.id = p_id and public.paket_erisim_var(s.sinav, s.ders)
  );
$function$
;

-- davet_kodu_ata()
CREATE OR REPLACE FUNCTION public.davet_kodu_ata()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.davet_kodu is null then
    new.davet_kodu := public.davet_kodu_uret();
  end if;
  return new;
end;
$function$
;

-- davet_kodu_uret()
CREATE OR REPLACE FUNCTION public.davet_kodu_uret()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
  havuz text := 'ACDEFHJKLMNPRTUVXYZ2345679';
  kod   text;
  i     int;
begin
  for deneme in 1..50 loop
    kod := 'TT';
    for i in 1..4 loop
      kod := kod || substr(havuz, 1 + floor(random() * length(havuz))::int, 1);
    end loop;
    if not exists (select 1 from public.paket_uyeler where davet_kodu = kod) then
      return kod;
    end if;
  end loop;
  raise exception 'davet_kodu_uret: 50 denemede bos kod bulunamadi';
end;
$function$
;

-- davet_uygula(uuid,text)
CREATE OR REPLACE FUNCTION public.davet_uygula(p_alan_id uuid, p_kod text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_kod      text := upper(trim(coalesce(p_kod, '')));
  v_veren_id uuid;
  v_kullanim int;
  TAVAN      constant int := 3;
begin
  if v_kod = '' then return 'kod yok - bir sey yapilmadi'; end if;
  if v_kod !~ '^TT[ACDEFHJKLMNPRTUVXYZ2345679]{4}$' then
    return 'kod bicimi gecersiz: ' || v_kod; end if;

  select user_id into v_veren_id from paket_uyeler where davet_kodu = v_kod;
  if v_veren_id is null then return 'boyle bir kod yok: ' || v_kod; end if;
  if v_veren_id = p_alan_id then return 'kendi kodunu kullanamaz'; end if;
  if not exists (select 1 from paket_uyeler where user_id = p_alan_id) then
    return 'daveti kullanacak uyenin paket satiri yok - once erisimi ac'; end if;
  if exists (select 1 from davet_kullanim where alan_id = p_alan_id) then
    return 'bu uye zaten bir davet kullanmis'; end if;

  select count(*) into v_kullanim from davet_kullanim where kod = v_kod;
  if v_kullanim >= TAVAN then
    return 'kod tavani dolmus (' || TAVAN || ' kullanim): ' || v_kod; end if;

  update paket_uyeler
     set bitis = greatest(bitis, current_date) + interval '30 days'
   where user_id in (v_veren_id, p_alan_id);

  insert into davet_kullanim (kod, veren_id, alan_id) values (v_kod, v_veren_id, p_alan_id);

  return 'uygulandi: ikisine de +1 ay (kod ' || v_kod || ', kullanim '
         || (v_kullanim + 1) || '/' || TAVAN || ')';
end;
$function$
;

-- destek_takip_iptal(uuid)
CREATE OR REPLACE FUNCTION public.destek_takip_iptal(p_token uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update public.destek_takip set aktif = false where token = p_token and aktif = true;
  get diagnostics n = row_count;
  if n > 0 then return 'iptal'; end if;
  if exists (select 1 from public.destek_takip where token = p_token) then return 'zaten'; end if;
  return 'bulunamadi';
end $function$
;

-- ekibe_cevap_goruldu()
CREATE OR REPLACE FUNCTION public.ekibe_cevap_goruldu()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n integer;
begin
  if auth.uid() is null then return 0; end if;
  update public.ekibe_soru set cevap_goruldu = now()
   where user_id = auth.uid() and durum = 'cevaplandi' and cevap_goruldu is null;
  get diagnostics n = row_count;
  return n;
end $function$
;

-- ekibe_soru_eposta_yaz()
CREATE OR REPLACE FUNCTION public.ekibe_soru_eposta_yaz()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  new.eposta := (select u.email from auth.users u where u.id = new.user_id);
  return new;
end $function$
;

-- elci_bagla(text)
CREATE OR REPLACE FUNCTION public.elci_bagla(p_kod text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- elci_erisim_ver()
CREATE OR REPLACE FUNCTION public.elci_erisim_ver()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_ep    text;
  v_bitis date := (current_date + interval '3 months')::date;
  v_eski  public.paket_uyeler%rowtype;
  v_var   boolean;
begin
  if new.user_id is null or not new.aktif then return new; end if;
  if tg_op = 'UPDATE' and old.user_id is not distinct from new.user_id then return new; end if;
  if exists (select 1 from public.paket_hediye h
              where h.elci_kodu = new.kod and h.iptal is null and h.neden like 'Elçi sözleşmesi Madde 10%') then
    return new;
  end if;
  select * into v_eski from public.paket_uyeler where user_id = new.user_id;
  v_var := found;
  if v_var and v_eski.bitis >= current_date then return new; end if;
  select lower(u.email) into v_ep from auth.users u where u.id = new.user_id;
  v_ep := coalesce(v_ep, lower(new.email), 'bilinmiyor@tetikte.com');
  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (new.user_id, 'tam', v_bitis, null)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = null;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren)
    values (new.user_id, v_ep, 'tam', v_bitis, 'Elçi sözleşmesi Madde 10 - 3 ay ücretsiz tam erişim (otomatik)', new.kod, 'otomatik');
  return new;
end $function$
;

-- elci_google_bagla()
CREATE OR REPLACE FUNCTION public.elci_google_bagla()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_uid uuid := auth.uid(); v_kod text; v_ep text; v_meta jsonb;
begin
  if v_uid is null then return null; end if;
  select kod into v_kod from public.elciler where user_id = v_uid;
  if v_kod is not null then return v_kod; end if;
  select lower(u.email), coalesce(u.raw_app_meta_data, '{}'::jsonb) into v_ep, v_meta from auth.users u where u.id = v_uid;
  if v_ep is null then return null; end if;
  if not (coalesce(v_meta->'providers', '[]'::jsonb) ? 'google' or v_meta->>'provider' = 'google') then return null; end if;
  -- aynı e-posta eski kayıtlarda iki kodda yazılı olabilir: en yeni açık kod seçilir, yalnız o bağlanır
  select kod into v_kod from public.elciler
   where lower(email) = v_ep and user_id is null and aktif
   order by olusturma desc limit 1;
  if v_kod is null then return null; end if;
  update public.elciler set user_id = v_uid, bag_kodu_ozet = null, bag_kodu_son = null where kod = v_kod and user_id is null;
  return v_kod;
end $function$
;

-- elci_kodu_kontrol(text,text)
CREATE OR REPLACE FUNCTION public.elci_kodu_kontrol(p_kod text, p_paket text)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((
    select i.indirim_tl
      from elciler e
      join elci_indirim i on i.paket = p_paket
     where e.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
       and e.aktif
  ), 0);
$function$
;

-- elci_komisyon(integer,smallint)
CREATE OR REPLACE FUNCTION public.elci_komisyon(n integer, bk smallint)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when coalesce(n, 0) <= 0 then 0
    when bk >= 3 then n * 1250
    when bk = 2  then least(n, 49) * 1000 + greatest(0, n - 49) * 1250
    else least(n, 9) * 750
       + greatest(0, least(n, 49) - 9) * 1000
       + greatest(0, n - 49) * 1250
  end;
$function$
;

-- elci_panelim()
CREATE OR REPLACE FUNCTION public.elci_panelim()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_e      elciler%rowtype;
  v_d      sinav_donemleri%rowtype;
  v_kesin  int := 0;
  v_bek    int := 0;
  v_iade   int := 0;
  v_obek   int := 0;
  v_dkesin int := 0;
  v_dbek   int := 0;
  v_dkom_k int := 0;
  v_dkom_b int := 0;
  v_once   int := 0;
  v_n      int;
  v_k      smallint;
  v_esik   int;
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

  select count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         count(*) filter (where s.durum = 'iade'),
         count(*) filter (where s.durum = 'odeme_bekliyor'),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()),
         count(*) filter (where s.olusturma >= v_e.ilk_onay and s.elci_sabit_komisyon_tl is not null and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.olusturma >= v_e.ilk_onay and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' <= now()), 0),
         coalesce(sum(s.elci_sabit_komisyon_tl) filter (where s.olusturma >= v_e.ilk_onay and s.durum = 'odendi' and s.odendi_tarihi + interval '7 days' >  now()), 0),
         count(*) filter (where s.durum = 'odendi' and (v_e.ilk_onay is null or s.olusturma < v_e.ilk_onay))
    into v_kesin, v_bek, v_iade, v_obek, v_dkesin, v_dbek, v_dkom_k, v_dkom_b, v_once
    from siparisler s
   where s.elci_kodu = v_e.kod
     and s.olusturma::date between v_d.baslangic and v_d.bitis;

  v_n := coalesce(v_kesin, 0) + coalesce(v_bek, 0);
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
    'ilk_onay',          v_e.ilk_onay,
    'onay_oncesi_satis', coalesce(v_once, 0),
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
    'ders_kesin_satis',      coalesce(v_dkesin, 0),
    'ders_bekleyen_satis',   coalesce(v_dbek, 0),
    'ders_komisyon_kesin',   coalesce(v_dkom_k, 0),
    'ders_komisyon_tahmini', coalesce(v_dkom_k, 0) + coalesce(v_dkom_b, 0),
    'indirimler',        (select coalesce(jsonb_object_agg(paket, indirim_tl), '{}'::jsonb) from elci_indirim where indirim_tl > 0),
    'ders_komisyonlari', (select coalesce(jsonb_object_agg(paket, sabit_komisyon_tl), '{}'::jsonb) from elci_indirim where sabit_komisyon_tl is not null),
    'odemeler',          (select coalesce(jsonb_agg(jsonb_build_object('donem', o.donem, 'tutar_tl', o.tutar_tl,
                                                   'odeme_tarihi', o.odeme_tarihi) order by o.odeme_tarihi desc), '[]'::jsonb)
                            from elci_odemeler o where o.kod = v_e.kod)
  );
end $function$
;

-- elci_sozlesme_onayla(text)
CREATE OR REPLACE FUNCTION public.elci_sozlesme_onayla(p_surum text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null or coalesce(p_surum, '') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
    return false;
  end if;
  update elciler set sozlesme_onay = now(), sozlesme_surum = p_surum, ilk_onay = coalesce(ilk_onay, now())
   where user_id = auth.uid();
  return found;
end $function$
;

-- hatirlatma_ret(text)
CREATE OR REPLACE FUNCTION public.hatirlatma_ret(p_jeton text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_jeton is null or p_jeton !~ '^[0-9a-f]{64}$' then
    return false;
  end if;
  insert into public.hatirlatma_ret (jeton) values (p_jeton) on conflict (jeton) do nothing;
  return true;
end;
$function$
;

-- hesabimi_sil()
CREATE OR REPLACE FUNCTION public.hesabimi_sil()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  kim uuid := auth.uid();
  posta text;
  hata_metni text;
begin
  if kim is null then
    insert into public.hesap_sil_kutuk (kim, sonuc) values (null, 'giris-yok');
    return json_build_object('tamam', false, 'neden', 'giris-yok');
  end if;
  begin
    select lower(email) into posta from auth.users where id = kim;
    delete from public.nobetci_soru where user_id = kim;
    delete from public.ekibe_soru where user_id = kim or (posta is not null and lower(eposta) = posta);
    delete from public.uye_cihazlar where user_id = kim;
    delete from public.ogrenci_ilerleme where user_id = kim;
    delete from public.prova_sonuc_mail where uye_id = kim;
    delete from public.deneme_ilerleme where user_id = kim;
    delete from auth.users where id = kim;
  exception when others then
    hata_metni := sqlstate || ' ' || sqlerrm;
    insert into public.hesap_sil_kutuk (kim, sonuc, hata) values (kim, 'hata', hata_metni);
    return json_build_object('tamam', false, 'neden', 'hata', 'hata', hata_metni);
  end;
  insert into public.hesap_sil_kutuk (kim, sonuc) values (kim, 'silindi');
  return json_build_object('tamam', true);
end;
$function$
;

-- ihale_dokum(integer,integer)
CREATE OR REPLACE FUNCTION public.ihale_dokum(p_offset integer DEFAULT 0, p_limit integer DEFAULT 5000)
 RETURNS SETOF ihale_sonuc_v
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role okuyabilir';
  end if;
  return query
    select * from public.ihale_sonuc_v
    order by ikn, sozlesme_tarih, anahtar
    offset greatest(p_offset,0)
    limit least(greatest(p_limit,1), 10000);
end;
$function$
;

-- ihale_eksik_gun(date,date,text[])
CREATE OR REPLACE FUNCTION public.ihale_eksik_gun(p_bas date, p_bit date, p_turler text[] DEFAULT ARRAY['Mal'::text, 'Yapim'::text, 'Hizmet'::text, 'Danismanlik'::text])
 RETURNS TABLE(gun date, tur text, sebep text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select g::date as gun, t as tur,
         case when k.gun is null then 'hic cekilmedi'
              else 'eksik indi' end as sebep
  from generate_series(p_bas, p_bit, interval '1 day') g
  cross join unnest(p_turler) t
  left join public.ihale_kutuk k on k.gun = g::date and k.tur = t
  where extract(isodow from g) < 6
    and (k.gun is null or k.tam = false)
  order by g desc, t;
$function$
;

-- ihale_kutuk_denetim()
CREATE OR REPLACE FUNCTION public.ihale_kutuk_denetim()
 RETURNS TABLE(gun date, tur text, kutuk_diyor integer, tabloda_duran bigint, fark bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select k.gun, k.tur, k.kayit,
         coalesce(s.n, 0) as tabloda_duran,
         coalesce(s.n, 0) - k.kayit as fark
  from public.ihale_kutuk k
  left join (
    select bulten_tarih, tur, count(*) as n
    from public.ihale_sonuc
    where bulten_tarih is not null
    group by bulten_tarih, tur
  ) s on s.bulten_tarih = k.gun and s.tur = k.tur
  where coalesce(s.n,0) <> k.kayit
  order by k.gun desc, k.tur;
$function$
;

-- ihale_kutuk_yaz(date,text,integer,integer,integer,integer,text[],text)
CREATE OR REPLACE FUNCTION public.ihale_kutuk_yaz(p_gun date, p_tur text, p_bulten_sayi integer, p_kayit integer, p_beklenen integer DEFAULT NULL::integer, p_bulunan integer DEFAULT NULL::integer, p_eksik_ikn text[] DEFAULT NULL::text[], p_bos_sebep text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role yazabilir';
  end if;
  insert into public.ihale_kutuk (gun, tur, bulten_sayi, beklenen, bulunan,
                                  kayit, tam, eksik_ikn, bos_sebep, cekildi)
  values (p_gun, p_tur, p_bulten_sayi, p_beklenen, p_bulunan,
          coalesce(p_kayit,0),
          (p_beklenen is not null and p_bulunan is not null and p_beklenen = p_bulunan),
          p_eksik_ikn, p_bos_sebep, now())
  on conflict (gun, tur) do update set
    bulten_sayi = coalesce(excluded.bulten_sayi, ihale_kutuk.bulten_sayi),
    beklenen    = excluded.beklenen,
    bulunan     = excluded.bulunan,
    kayit       = excluded.kayit,
    tam         = excluded.tam,
    eksik_ikn   = excluded.eksik_ikn,
    bos_sebep   = excluded.bos_sebep,
    cekildi     = now();
end;
$function$
;

-- ihale_sayi()
CREATE OR REPLACE FUNCTION public.ihale_sayi()
 RETURNS TABLE(kayit bigint, tekil_ikn bigint, olculen bigint, kisimli bigint, damgasiz bigint, ilk_bulten date, son_bulten date)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role';
  end if;
  return query
    select count(*)::bigint,
           count(distinct ikn)::bigint,
           count(*) filter (where kirim_yuzde is not null)::bigint,
           count(*) filter (where kisimli_mi)::bigint,
           count(*) filter (where bulten_tarih is null)::bigint,
           min(bulten_tarih),
           max(bulten_tarih)
    from public.ihale_sonuc_v;
end;
$function$
;

-- ihale_yaz(jsonb)
CREATE OR REPLACE FUNCTION public.ihale_yaz(p_kayitlar jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  if auth.role() <> 'service_role' then
    raise exception 'yalniz service_role yazabilir';
  end if;

  insert into public.ihale_sonuc (
    anahtar, ikn, tur, is_adi, idare, ihale_tarih, ihale_turu, usul,
    yaklasik_maliyet, ym_birim, sb_birim, dokuman_indiren, teklif_sayisi,
    gecerli_teklif, yerli_avantaj, sozlesme_tarih, sozlesme_bedeli, yuklenici,
    kisim_kaniti, bulten_tarih, bulten_sayi, guncellendi
  )
  select
    x.anahtar, x.ikn, x.tur, x.is_adi, x.idare, x.ihale_tarih, x.ihale_turu, x.usul,
    x.yaklasik_maliyet, x.ym_birim, x.sb_birim, x.dokuman_indiren, x.teklif_sayisi,
    x.gecerli_teklif, x.yerli_avantaj, x.sozlesme_tarih, x.sozlesme_bedeli, x.yuklenici,
    coalesce(x.kisim_kaniti,false), x.bulten_tarih, x.bulten_sayi, now()
  from jsonb_to_recordset(p_kayitlar) as x(
    anahtar text, ikn text, tur text, is_adi text, idare text, ihale_tarih text,
    ihale_turu text, usul text, yaklasik_maliyet numeric, ym_birim text, sb_birim text,
    dokuman_indiren int, teklif_sayisi int, gecerli_teklif int, yerli_avantaj text,
    sozlesme_tarih text, sozlesme_bedeli numeric, yuklenici text, kisim_kaniti boolean,
    bulten_tarih date, bulten_sayi int
  )
  where x.anahtar is not null and x.ikn is not null
  on conflict (anahtar) do update set
    tur = excluded.tur, is_adi = excluded.is_adi, idare = excluded.idare,
    ihale_tarih = excluded.ihale_tarih, ihale_turu = excluded.ihale_turu, usul = excluded.usul,
    yaklasik_maliyet = excluded.yaklasik_maliyet, ym_birim = excluded.ym_birim,
    sb_birim = excluded.sb_birim, dokuman_indiren = excluded.dokuman_indiren,
    teklif_sayisi = excluded.teklif_sayisi, gecerli_teklif = excluded.gecerli_teklif,
    yerli_avantaj = excluded.yerli_avantaj, sozlesme_tarih = excluded.sozlesme_tarih,
    sozlesme_bedeli = excluded.sozlesme_bedeli, yuklenici = excluded.yuklenici,
    kisim_kaniti = excluded.kisim_kaniti,
    bulten_tarih = coalesce(excluded.bulten_tarih, ihale_sonuc.bulten_tarih),
    bulten_sayi  = coalesce(excluded.bulten_sayi,  ihale_sonuc.bulten_sayi),
    guncellendi = now();

  get diagnostics n = row_count;
  return n;
end;
$function$
;

-- istek_getir(uuid)
CREATE OR REPLACE FUNCTION public.istek_getir(p_token uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v public.istekler; v_mukellef text; v_sorular json;
begin
  select * into v from public.istekler where token = p_token;
  if not found then return null; end if;
  select ad into v_mukellef from public.mukellefler where id = v.mukellef_id;
  select coalesce(json_agg(json_build_object('id',s.id,'tip',s.tip,'metin',s.metin,'cevap',s.cevap,'dosya_url',s.dosya_url,'durum',s.durum) order by s.sira,s.metin),'[]'::json) into v_sorular from public.sorular s where s.istek_id = v.id;
  return json_build_object('baslik',v.baslik,'mukellef',v_mukellef,'sorular',v_sorular);
end; $function$
;

-- kalip_parti_damga()
CREATE OR REPLACE FUNCTION public.kalip_parti_damga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.guncelleme := now();
  -- soru_sayisi icerikten TURETILIR; cagiranin yanlis sayi yazmasi engellenir
  new.soru_sayisi := (
    select count(*) from jsonb_each(new.icerik) e
    where e.value ? 'soru' and length(coalesce(e.value->>'soru','')) > 0
  );
  return new;
end $function$
;

-- kart_siparis_odendi(text,text)
CREATE OR REPLACE FUNCTION public.kart_siparis_odendi(p_no text, p_payment_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid; v_bitis date; v_sonuc text;
begin
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum = 'odendi' then return jsonb_build_object('siparis', 'ZATEN_ODENDI'); end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;

  v_bitis := greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92);
  update public.siparisler set durum = 'odendi', odeme = 'kart', paket_bitis = v_bitis where id = s.id;   -- odendi_tarihi tetikleyicide

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'BEKLIYOR', 'not', 'hesap yok; üye olunca kendiliğinden açılır', 'odeme', p_payment_id);
  end if;
  v_sonuc := public.siparis_paket_bagla(v_uid, s.email);
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', v_bitis, 'sonuc', v_sonuc, 'odeme', p_payment_id);
end $function$
;

-- kasa_cekim_izin2(text,integer,integer,text[])
CREATE OR REPLACE FUNCTION public.kasa_cekim_izin2(p_sayfa text, p_bas integer, p_adet integer, p_ids text[] DEFAULT NULL::text[])
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  uid   uuid := auth.uid();
  c10   integer; c24 integer; c7 integer;
  yeni  integer;
  neden text;
  ip    text;
begin
  if uid is null then return 'oturum yok'; end if;
  if p_ids is null then
    select count(*) into yeni
      from generate_series(p_bas, p_bas + p_adet - 1) g(i)
     where not exists (
       select 1 from public.kasa_cekim k
        where k.user_id = uid and k.sayfa = p_sayfa and k.adet > 0
          and k.zaman > now() - interval '24 hours'
          and g.i >= k.bas and g.i < k.bas + k.adet);
  else
    select count(distinct x.id) into yeni
      from unnest(p_ids) x(id)
     where not exists (
       select 1 from public.kasa_cekim k
        where k.user_id = uid and k.sayfa = p_sayfa and k.adet > 0
          and k.zaman > now() - interval '24 hours'
          and x.id = any(k.ids));
  end if;
  select coalesce(sum(coalesce(tekil, adet)),0) into c10 from public.kasa_cekim where user_id = uid and zaman > now() - interval '10 minutes';
  select coalesce(sum(coalesce(tekil, adet)),0) into c24 from public.kasa_cekim where user_id = uid and zaman > now() - interval '24 hours';
  select coalesce(sum(coalesce(tekil, adet)),0) into c7  from public.kasa_cekim where user_id = uid and zaman > now() - interval '7 days';
  neden := case
    when yeni = 0              then null
    when c10 + yeni > 4000     then '10dk'
    when c24 + yeni > 10000    then 'gun'
    when c7  + yeni > 25000    then 'hafta'
  end;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'), ''), ',', 1);
  if neden is not null then
    insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ip) values (uid, 'TAVAN:' || neden || ':' || p_sayfa, p_bas, 0, 0, nullif(trim(ip),''));
    return neden;
  end if;
  insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ids, ip) values (uid, p_sayfa, p_bas, p_adet, yeni, p_ids, nullif(trim(ip),''));
  return null;
end $function$
;

-- kasa_cevap_yaz(text,text,text)
CREATE OR REPLACE FUNCTION public.kasa_cevap_yaz(p_sayfa text, p_id text, p_secim text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  uid uuid := auth.uid(); v_dogru text; sec text := upper(left(coalesce(p_secim,''),1));
begin
  if uid is null or sec !~ '^[A-E?]$' then return; end if;
  select s.veri->>'dogru' into v_dogru from public.paket_soru s where s.id = p_id and s.sayfa = p_sayfa;
  if v_dogru is null then return; end if;                                  -- bilinmeyen soru yazilmaz
  if exists (select 1 from public.kasa_cevap c where c.user_id = uid and c.soru_id = p_id
             and c.zaman > now() - interval '10 seconds') then return; end if;
  insert into public.kasa_cevap (user_id, sayfa, soru_id, secim, dogru)
  values (uid, left(p_sayfa, 200), p_id, sec, case when sec = '?' then false else sec = upper(v_dogru) end);
end $function$
;

-- kasa_ders_fihrist(text)
CREATE OR REPLACE FUNCTION public.kasa_ders_fihrist(p_sayfa text)
 RETURNS TABLE(id text, sira integer, ders text, konu text, donem text, zorluk text, toplam bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_sinav text; v_ders text; tpl bigint;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;   -- 0 satir = "paketinde yok"
  select count(*) into tpl from public.paket_soru s where s.sayfa = p_sayfa;
  return query
    select s.id, s.sira, s.ders, coalesce(s.konu, s.veri->>'konu'), s.veri->>'donem', s.veri->>'zorluk', tpl
    from public.paket_soru s where s.sayfa = p_sayfa order by s.sira asc;
end $function$
;

-- kasa_dizin(text)
CREATE OR REPLACE FUNCTION public.kasa_dizin(p_sinav text)
 RETURNS TABLE(id text, ders text, sayfa text, donem text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select s.id, s.ders, s.sayfa, s.veri->>'donem'
  from public.paket_soru s
  where s.sinav = p_sinav and auth.uid() is not null and public.paket_erisim_var(s.sinav, s.ders)
  order by s.id;
$function$
;

-- kasa_soru_getir(text,integer,integer)
CREATE OR REPLACE FUNCTION public.kasa_soru_getir(p_sayfa text, p_bas integer DEFAULT 0, p_adet integer DEFAULT 100)
 RETURNS TABLE(sira integer, veri jsonb, toplam bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  adet    integer := least(greatest(coalesce(p_adet, 100), 1), 100);
  bas     integer := greatest(coalesce(p_bas, 0), 0);
  v_sinav text; v_ders text;
  tpl     bigint; n integer; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;   -- 0 satir = "paketinde yok"
  select count(*) into tpl from public.paket_soru s where s.sayfa = p_sayfa;
  n := greatest(least(tpl - bas, adet), 0);
  if n = 0 then return; end if;
  neden := public.kasa_cekim_izin2(p_sayfa, bas, n, null);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.sira, s.veri, tpl from public.paket_soru s
    where s.sayfa = p_sayfa order by s.sira asc offset bas limit adet;
end $function$
;

-- kasa_soru_idler(text[])
CREATE OR REPLACE FUNCTION public.kasa_soru_idler(p_ids text[])
 RETURNS TABLE(id text, veri jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ids  text[] := (coalesce(p_ids, '{}'::text[]))[1:100];
  izin text[]; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select array_agg(s.id) into izin from public.paket_soru s where s.id = any(ids) and public.paket_erisim_var(s.sinav, s.ders);
  if izin is null then return; end if;
  neden := public.kasa_cekim_izin2('idler', 0, cardinality(izin), izin);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.id, s.veri from public.paket_soru s
    where s.id = any(izin);
end $function$
;

-- kasa_soru_parca(text,text[])
CREATE OR REPLACE FUNCTION public.kasa_soru_parca(p_sayfa text, p_ids text[])
 RETURNS TABLE(id text, sira integer, veri jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ids   text[] := (coalesce(p_ids, '{}'::text[]))[1:40];
  izin  text[]; v_sinav text; v_ders text; neden text;
begin
  if auth.uid() is null then raise exception 'KASA_OTURUM' using errcode = '42501'; end if;
  select s.sinav, s.ders into v_sinav, v_ders from public.paket_soru s where s.sayfa = p_sayfa limit 1;
  if v_sinav is null or not public.paket_erisim_var(v_sinav, v_ders) then return; end if;
  select array_agg(s.id) into izin from public.paket_soru s where s.sayfa = p_sayfa and s.id = any(ids);
  if izin is null then return; end if;
  -- bas -100000: kimlikli satirin konum araligi gercek konumlarla (eski yol kasa_soru_getir) cakismasin;
  -- tekil sayim burada kimlikten yapilir (kasa_cekim_izin2 p_ids dali).
  neden := public.kasa_cekim_izin2(p_sayfa, -100000, cardinality(izin), izin);
  if neden is not null then raise exception 'KASA_TAVAN:%', neden using errcode = 'P0001'; end if;
  return query
    select s.id, s.sira, s.veri from public.paket_soru s where s.id = any(izin);
end $function$
;

-- kasa_tavan_bildir(text,text)
CREATE OR REPLACE FUNCTION public.kasa_tavan_bildir(p_sayfa text, p_pencere text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  uid uuid := auth.uid();
  ip  text;
begin
  if uid is null then return; end if;
  if p_pencere is null or p_pencere not in ('10dk','gun','hafta') then return; end if;
  if exists (select 1 from public.kasa_cekim where user_id = uid and sayfa like 'TAVAN:%' and zaman > now() - interval '1 minute') then return; end if;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'), ''), ',', 1);
  insert into public.kasa_cekim (user_id, sayfa, bas, adet, tekil, ip)
  values (uid, 'TAVAN:' || p_pencere || ':' || left(coalesce(p_sayfa,'?'), 200), 0, 0, 0, nullif(trim(ip),''));
end $function$
;

-- kasa_uye_olcum(integer)
CREATE OR REPLACE FUNCTION public.kasa_uye_olcum(p_saat integer DEFAULT 24)
 RETURNS TABLE(user_id uuid, acti bigint, cozdu bigint, sayfa_sayisi bigint, tavan bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with k as (
    select c.user_id,
           sum(coalesce(c.tekil, c.adet)) filter (where c.sayfa not like 'TAVAN:%') as acti,
           count(distinct c.sayfa) filter (where c.sayfa not like 'TAVAN:%' and c.adet > 0) as sayfa_sayisi,
           count(*) filter (where c.sayfa like 'TAVAN:%') as tavan
    from public.kasa_cekim c
    where c.zaman > now() - make_interval(hours => greatest(1, least(coalesce(p_saat,24), 24*14)))
    group by c.user_id),
  v as (
    select a.user_id, count(distinct a.soru_id) as cozdu
    from public.kasa_cevap a
    where a.zaman > now() - make_interval(hours => greatest(1, least(coalesce(p_saat,24), 24*14)))
    group by a.user_id)
  select coalesce(k.user_id, v.user_id), coalesce(k.acti,0), coalesce(v.cozdu,0), coalesce(k.sayfa_sayisi,0), coalesce(k.tavan,0)
  from k full join v on v.user_id = k.user_id
  order by 2 desc;
$function$
;

-- kaynak_say(text,text)
CREATE OR REPLACE FUNCTION public.kaynak_say(p_etiket text, p_olay text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if coalesce(p_olay,'') not in ('ziyaret','test','ornek') then return false; end if;
  return public._kaynak_artir((now() at time zone 'Europe/Istanbul')::date, lower(btrim(p_etiket)), p_olay);
end
$function$
;

-- kaynak_uye(text)
CREATE OR REPLACE FUNCTION public.kaynak_uye(p_etiket text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  kim  uuid := auth.uid();
  olus timestamptz;
  e    text := lower(btrim(p_etiket));
  g    date;
begin
  if kim is null or e is null or e !~ '^[a-z0-9][a-z0-9_-]{0,31}$' then return false; end if;
  select u.created_at into olus from auth.users u where u.id = kim;
  if olus is null or olus < now() - interval '2 days' then return false; end if;
  g := (olus at time zone 'Europe/Istanbul')::date;
  if exists (select 1 from public.kaynak_uye_sayildi x where x.user_id = kim) then return false; end if;
  if not public._kaynak_artir(g, e, 'uye') then return false; end if;
  insert into public.kaynak_uye_sayildi (user_id) values (kim) on conflict do nothing;
  if not found then
    -- yarış: aynı hesap iki sekmeden aynı anda geldi → ikinci artışı geri al
    update public.kaynak_sayac set adet = adet - 1 where gun = g and etiket = e and olay = 'uye' and adet > 0;
    return false;
  end if;
  return true;
end
$function$
;

-- kurucu_sayac()
CREATE OR REPLACE FUNCTION public.kurucu_sayac()
 RETURNS TABLE(sinav text, satilan integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with odenen as (
    select paket from public.siparisler where durum = 'odendi'
    union all
    select paket from public.magaza_siparis where durum in ('verildi','tuketildi') and paket is not null
  ), eslenen as (
    select case
             when paket = 'sgs' then 'sgs'
             when paket like 'yeterlilik-%' and paket <> 'yeterlilik-kgk' then 'yeterlilik'
             when paket like 'kgk%' or paket = 'yeterlilik-kgk' then 'kgk'
           end as sinav
      from odenen
  )
  select s.sinav, coalesce((select count(*)::int from eslenen e where e.sinav = s.sinav), 0)
    from (values ('sgs'), ('yeterlilik'), ('kgk')) as s(sinav);
$function$
;

-- madde_ara(text,integer)
CREATE OR REPLACE FUNCTION public.madde_ara(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
AS $function$
with tok as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
-- belge frekansi: 'cikmis%' disi ambarda kac belge bu jetonu iceriyor
df as (
  select t.w,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.w || ':*')) as adet_df
  from tok t
),
agir as (
  select w,
         to_tsquery('simple', w || ':*') as tq,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
-- (1) DAR HAVUZ: yalniz ayirt edici jetonlar aday uretir
secili as (
  select w from df where adet_df <= 1500 order by adet_df asc limit 4
),
secili2 as (
  select w from secili
  union all
  select w from (select w from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from secili2
),
qtum as (
  select to_tsquery('simple', string_agg(w || ':*', ' | ')) as orq from tok
),
aday as (
  select d.ctid as rid, d.arama_fold as af, d.tur as tur,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by r desc
  limit 300
),
puan as (
  select a.rid, a.r,
         (select coalesce(sum(g.agirlik),0) from agir g where a.af @@ g.tq) as s,
         (select count(*) from agir g where a.af @@ g.tq) as kapsanan,
         case a.tur
           when 'teori-notu'    then 0.55
           when 'standart-madde' then 0.85   -- (2) v7'de 'standart' yaziyordu: OLU DAL
           else 1.0
         end as turw
  from aday a
)
select d.* from dokumanlar d
join puan p on d.ctid = p.rid
order by (p.s * p.turw * (1 + 0.35 * greatest(p.kapsanan - 1, 0))) desc, p.r desc
limit greatest(coalesce(adet,6),1)
$function$
;

-- madde_ara_deneme(text,integer)
CREATE OR REPLACE FUNCTION public.madde_ara_deneme(sorgu text, adet integer DEFAULT 6)
 RETURNS SETOF dokumanlar
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
select d.*
from public.madde_ara_deneme_puan(sorgu, adet, '{"adw":0,"tebw":0.75}'::jsonb) p
join dokumanlar d on d.id = p.id
order by p.puan desc, p.r desc
$function$
;

-- madde_ara_deneme_puan(text,integer,jsonb)
CREATE OR REPLACE FUNCTION public.madde_ara_deneme_puan(sorgu text, adet integer DEFAULT 6, ayar jsonb DEFAULT '{}'::jsonb)
 RETURNS TABLE(id uuid, kaynak_ad text, tur text, puan double precision, gs double precision, kapsanan integer, adkap integer, turw double precision, r real)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
with prm as (
  select coalesce((ayar->>'es')::boolean, true)   as es,
         coalesce((ayar->>'acilim')::boolean, true) as acil,
         coalesce((ayar->>'adw')::float8, 0.6)     as adw,
         coalesce((ayar->>'adaday')::int, 60)      as adaday,
         coalesce((ayar->>'tebw')::float8, 0.75)   as tebw,
         coalesce((ayar->>'yonw')::float8, 1.0)    as yonw,
         coalesce((ayar->>'stdw')::float8, 0.85)   as stdw,
         coalesce((ayar->>'teow')::float8, 0.55)   as teow,
         coalesce((ayar->>'kapw')::float8, 0.35)   as kapw
),
ham as (
  select distinct left(regexp_replace(w, '[^a-z0-9]', '', 'g'), 15) as w
  from regexp_split_to_table(lower(coalesce(sorgu,'')), '\s+') as w
  where length(regexp_replace(w, '[^a-z0-9]', '', 'g')) >= 3
  limit 8
),
-- es anlam: grup -> tsquery ifadesi (grup TEK kavram sayilir, ad eslesmesine girmez)
es_tablo(g, tqs) as (
  values ('tufe','tuketici <-> fiyat <-> endeks:*'),
         ('ufe','uretici <-> fiyat <-> endeks:*'),
         ('apartman','anagayrimenkul:*')
),
-- YASA ADI SOZLUGU: jeton (istemcinin ek soyulmus hali) -> kaynak_ad oneki (aday uretir)
ad_sozluk(w, desen) as (
  values ('anayas','Anayasa (%'), ('anayasa','Anayasa (%'),
         ('vuk','VUK (%'), ('gvk','GVK (%'), ('kvk','KVK (%'), ('kdvk','KDVK (%'),
         ('tbk','TBK (%'), ('tmk','TMK (%'), ('ttk','TTK (%'), ('tck','TCK (%'),
         ('cmk','CMK (%'), ('hmk','HMK (%'), ('iik','İİK (%'), ('iyuk','İYUK (%'),
         ('aatuhk','AATUHK (%'), ('kvkk','KVKK (%'), ('tkhk','TKHK (%'),
         ('fsek','FSEK (%'), ('smk','SMK (%'), ('kik','KİK (%'), ('mohuk','MÖHUK (%')
),
-- AD ACILIMI: kaynak_ad oneki -> kullanicinin yazdigi tam ad (yalniz puan)
ad_acilim(desen, ek) as (
  values ('TTK (%','turk ticaret'), ('TMK (%','turk medeni'), ('TBK (%','borclar'),
         ('VUK (%','vergi usul'), ('İİK (%','icra iflas'), ('HMK (%','hukuk muhakemeleri'),
         ('CMK (%','ceza muhakemesi'), ('TCK (%','turk ceza'), ('GVK (%','gelir vergisi'),
         ('KVK (%','kurumlar vergisi'), ('KDVK (%','katma deger vergisi'), ('SMK (%','sinai mulkiyet'),
         ('KİK (%','kamu ihale'), ('AATUHK (%','amme alacaklarinin tahsil'),
         ('TKHK (%','tuketicinin korunmasi'), ('FSEK (%','fikir sanat eserleri'),
         ('İYUK (%','idari yargilama usulu'), ('ÖTV K.%','ozel tuketim vergisi'),
         ('MÖHUK (%','milletlerarasi ozel hukuk'), ('KVKK (%','kisisel verilerin korunmasi'),
         ('MTV K.%','motorlu tasitlar vergisi'), ('TPKK (%','turk parasi kiymetini koruma'),
         ('Emlak V.K.%','emlak vergisi'), ('Damga V.K.%','damga vergisi')
),
tok as (
  select h.w as g, h.w as w, h.w || ':*' as tqs, true as adlik from ham h
  union
  select e.g, e.g, e.tqs, false from es_tablo e join ham h on h.w = e.g, prm where prm.es
),
df as (
  select t.g, t.w, t.adlik, t.tqs, to_tsquery('simple', t.tqs) as tq,
         (select count(*) from dokumanlar dd
           where coalesce(dd.tur,'') not like 'cikmis%'
             and dd.arama_fold @@ to_tsquery('simple', t.tqs)) as adet_df
  from tok t
),
agir as (
  select g, w, tq, adlik,
         ln( ((select count(*) from dokumanlar where coalesce(tur,'') not like 'cikmis%') + 1)::numeric
             / (adet_df + 1) ) + 0.3 as agirlik
  from df
),
secili as ( select tqs from df where adet_df <= 1500 order by adet_df asc limit 4 ),
secili2 as (
  select tqs from secili
  union all
  select tqs from (select tqs from df order by adet_df asc limit 2) y
  where not exists (select 1 from secili)
),
qdar as ( select to_tsquery('simple', string_agg('(' || tqs || ')', ' | ')) as orq from secili2 ),
qtum as ( select to_tsquery('simple', string_agg('(' || tqs || ')', ' | ')) as orq from tok ),
metin_aday as (
  select d.ctid as rid
  from dokumanlar d, qdar
  where qdar.orq is not null
    and coalesce(d.tur,'') not like 'cikmis%'
    and d.arama_fold @@ qdar.orq
  order by ts_rank(d.arama_fold, (select orq from qtum)) desc
  limit 300
),
ad_aday as (
  select d.ctid as rid
  from dokumanlar d
  join ad_sozluk s on d.kaynak_ad like s.desen
  join ham h on h.w = s.w
  where coalesce(d.tur,'') not like 'cikmis%'
  order by ts_rank(d.arama_fold, (select orq from qtum)) desc
  limit (select adaday from prm)
),
aday as (
  select rid from metin_aday
  union
  select rid from ad_aday
),
ozellik as (
  select d.ctid as rid, d.id, d.kaynak_ad, d.tur, d.arama_fold as af,
         ' ' || lower(translate(coalesce(d.kaynak_ad,''),
                'İIıŞşĞğÜüÖöÇçÂâÎîÛû().,-/[]:;',
                'iiissgguuooccaaiiuu          ')) || ' ' as adf,
         case when (select acil from prm) then
           coalesce((select ' ' || string_agg(x.ek, ' ') || ' ' from ad_acilim x
                     where d.kaynak_ad like x.desen), '')
         else '' end as acilim,
         ts_rank(d.arama_fold, (select orq from qtum)) as r
  from dokumanlar d join aday a on d.ctid = a.rid
),
grup as (
  select o.rid, g.g,
         max(case when o.af @@ g.tq then g.agirlik else 0 end) as mw,
         max(case when g.adlik and (o.adf || o.acilim) like '% ' || g.w || '%'
                  then g.agirlik else 0 end) as aw
  from ozellik o cross join agir g
  group by o.rid, g.g
),
toplam as (
  select gr.rid,
         sum(gr.mw + prm.adw * gr.aw) as gs,
         count(*) filter (where gr.mw > 0 or gr.aw > 0)::int as kapsanan,
         count(*) filter (where gr.aw > 0)::int as adkap
  from grup gr, prm
  group by gr.rid
),
puan as (
  select o.id, o.kaynak_ad, o.tur, o.r, t.gs, t.kapsanan, t.adkap,
         case
           when o.tur = 'teori-notu'     then prm.teow
           when o.tur = 'standart-madde' then prm.stdw
           when o.adf !~ ' s k ' and o.adf ~ ' (tebli|gut |gt |genelge|sirkuler)' then prm.tebw
           when o.adf !~ ' s k ' and o.adf ~ ' (yonetmeli|yon )' then prm.yonw
           else 1.0
         end as turw,
         prm.kapw
  from ozellik o join toplam t on t.rid = o.rid, prm
)
select p.id, p.kaynak_ad, p.tur,
       p.gs * p.turw * (1 + p.kapw * greatest(p.kapsanan - 1, 0)) as puan,
       p.gs, p.kapsanan, p.adkap, p.turw, p.r
from puan p
order by 4 desc, p.r desc
limit greatest(coalesce(adet,6),1)
$function$
;

-- marka_ayna_durum()
CREATE OR REPLACE FUNCTION public.marka_ayna_durum()
 RETURNS TABLE(kayit bigint, detayli bigint, dilim_bitti bigint, dilim_toplam bigint, son_guncelleme timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select (select count(*) from public.marka_ayna),
         (select count(*) from public.marka_ayna where detay),
         (select count(*) from public.marka_ayna_dilim where durum='bitti'),
         (select count(*) from public.marka_ayna_dilim),
         (select max(guncelleme) from public.marka_ayna);
$function$
;

-- marka_ayna_sahip(text,integer)
CREATE OR REPLACE FUNCTION public.marka_ayna_sahip(p_unvan text, p_tavan integer DEFAULT 2000)
 RETURNS TABLE(st13 text, no text, ad text, basvuru date, tescil date, bitis date, durum text, sinif text, sahip text, vekil text, yenileme integer, son_yenileme date, detay boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_n text;
begin
  if p_unvan is null or length(btrim(p_unvan)) < 3 then
    raise exception 'Unvan en az 3 karakter olmali';
  end if;
  -- Sadeleştirme SQL tarafında da yapılır ki istemci ile robot AYNI kuralı kullansın.
  v_n := lower(btrim(p_unvan));
  v_n := translate(v_n, 'çğıöşüâîû', 'cgiosuaiu');
  v_n := regexp_replace(v_n, '[^a-z0-9]', '', 'g');
  if length(v_n) < 3 then raise exception 'Unvan en az 3 harf icermeli'; end if;

  return query
    select m.st13, m.no, m.ad, m.basvuru, m.tescil, m.bitis, m.durum, m.sinif,
           m.sahip, m.vekil, m.yenileme, m.son_yenileme, m.detay
    from public.marka_ayna m
    where m.sahip_norm like v_n || '%'
    order by m.bitis nulls last, m.basvuru desc
    limit least(greatest(p_tavan, 1), 5000);
end;
$function$
;

-- marka_bulten_durum()
CREATE OR REPLACE FUNCTION public.marka_bulten_durum()
 RETURNS TABLE(kayit bigint, bulten bigint, ilk_yayin date, son_yayin date, acik_itiraz bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(sum(k.kayit), 0)::bigint,
         count(*)::bigint,
         min(k.yayin_tarihi),
         max(k.yayin_tarihi),
         coalesce(sum(k.kayit) filter (
           where k.yayin_tarihi + interval '2 months' >= current_date), 0)::bigint
    from public.marka_bulten_kutuk k
   where k.durum = 'bitti';
$function$
;

-- marka_bulten_itiraz(text,integer[],integer,real,integer,boolean)
CREATE OR REPLACE FUNCTION public.marka_bulten_itiraz(p_ad text, p_sinif integer[] DEFAULT NULL::integer[], p_gun integer DEFAULT 60, p_esik real DEFAULT 0.32, p_tavan integer DEFAULT 100, p_yalniz_acik boolean DEFAULT true)
 RETURNS TABLE(basvuru_no text, bulten_no integer, yayin_tarihi date, itiraz_son date, kalan_gun integer, ad text, sahip text, sinif integer[], benzerlik real, ayni_sinif boolean)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
  with h as (select public.marka_norm(p_ad) as n)
  select b.basvuru_no, b.bulten_no, b.yayin_tarihi, b.itiraz_son,
         (b.itiraz_son - current_date)::int as kalan_gun,
         b.ad, b.sahip, b.sinif,
         similarity(b.ad_norm, h.n) as benzerlik,
         (p_sinif is not null and b.sinif && p_sinif) as ayni_sinif
    from public.marka_bulten b, h
   where h.n <> ''
     and b.yayin_tarihi >= current_date - greatest(p_gun,1)
     and (b.ad_norm % h.n or b.ad_norm like '%' || h.n || '%')
     and similarity(b.ad_norm, h.n) >= p_esik
     and (p_sinif is null or b.sinif && p_sinif)
     and (not p_yalniz_acik or b.itiraz_son >= current_date)
   order by (p_sinif is not null and b.sinif && p_sinif) desc,
            similarity(b.ad_norm, h.n) desc,
            b.itiraz_son asc
   limit least(greatest(p_tavan,1), 300);
$function$
;

-- marka_bulten_mutabakat()
CREATE OR REPLACE FUNCTION public.marka_bulten_mutabakat()
 RETURNS TABLE(bulten_no integer, yayin_tarihi date, kutuk integer, tablo bigint, fark bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select k.bulten_no, k.yayin_tarihi, k.kayit, s.n, s.n - k.kayit
    from public.marka_bulten_kutuk k
    cross join lateral (
      select count(*) as n from public.marka_bulten b where b.bulten_no = k.bulten_no
    ) s
   where k.durum = 'bitti'
   order by abs(s.n - k.kayit) desc, k.bulten_no desc;
$function$
;

-- marka_bulten_sahip(text,integer)
CREATE OR REPLACE FUNCTION public.marka_bulten_sahip(p_unvan text, p_tavan integer DEFAULT 200)
 RETURNS TABLE(basvuru_no text, yayin_tarihi date, basvuru_tarihi date, ad text, sinif integer[], itiraz_son date, sahip text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
  with h as (select public.marka_norm(p_unvan) as n,
                    public.marka_norm_sozcuk(p_unvan) as s)
  select b.basvuru_no, b.yayin_tarihi, b.basvuru_tarihi, b.ad, b.sinif, b.itiraz_son,
         regexp_replace(split_part(coalesce(b.sahip,''), ' (', 1), '^\s*\d+\s*-\s*', '') as sahip
    from public.marka_bulten b, h
   where h.n <> ''
     and length(h.n) >= 3
     and b.sahip_norm like '%' || h.n || '%'
     and (' ' || public.marka_norm_sozcuk(split_part(coalesce(b.sahip,''), ' (', 1)) || ' ')
         like '% ' || h.s || '%'
   order by b.yayin_tarihi desc, b.basvuru_no desc
   limit least(greatest(p_tavan,1), 500);
$function$
;

-- marka_kademe_hesap(text,text)
CREATE OR REPLACE FUNCTION public.marka_kademe_hesap(p_marka text, p_aday text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'extensions'
AS $function$
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
$function$
;

-- marka_kademe_sinav()
CREATE OR REPLACE FUNCTION public.marka_kademe_sinav()
 RETURNS TABLE(marka text, aday text, beklenen text, cikan text, sonuc text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
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
$function$
;

-- marka_norm(text)
CREATE OR REPLACE FUNCTION public.marka_norm(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select coalesce(
    regexp_replace(
      translate(lower(coalesce(p,'')),
                'çğıîöşüâûİI',
                'cgiiosuau' || 'i' || 'i'),
      '[^a-z0-9]', '', 'g'),
    '');
$function$
;

-- marka_norm_bosluklu(text)
CREATE OR REPLACE FUNCTION public.marka_norm_bosluklu(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select trim(regexp_replace(
           regexp_replace(
             translate(lower(coalesce(p,'')), 'çğıîöşüâûİI', 'cgiiosuau' || 'i' || 'i'),
             '[^a-z0-9 ]', ' ', 'g'),
           ' +', ' ', 'g'));
$function$
;

-- marka_norm_sozcuk(text)
CREATE OR REPLACE FUNCTION public.marka_norm_sozcuk(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select trim(regexp_replace(
           lower(translate(coalesce(p,''),
                 'ÇĞIİÖŞÜÂÎÛçğıöşüâîû',
                 'CGIIOSUAIUcgiosuaiu')),
           '[^a-z0-9]+', ' ', 'g'));
$function$
;

-- marka_takip_ac(text,integer[],text)
CREATE OR REPLACE FUNCTION public.marka_takip_ac(p_ad text, p_sinif integer[], p_eposta text)
 RETURNS TABLE(jeton text, ad text, sinif integer[])
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
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
$function$
;

-- marka_takip_ac2(text,integer[],text)
CREATE OR REPLACE FUNCTION public.marka_takip_ac2(p_ad text, p_sinif integer[], p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare v_n text; v_e text; r public.marka_takip; v_oj text;
begin
  v_n := public.marka_norm(p_ad);
  v_e := lower(btrim(coalesce(p_eposta, '')));
  if v_n = '' or length(btrim(coalesce(p_ad, ''))) < 2 or length(p_ad) > 120 then return jsonb_build_object('durum', 'AD_GECERSIZ'); end if;
  if v_e !~ '^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$' or length(v_e) > 254 then return jsonb_build_object('durum', 'EPOSTA_GECERSIZ'); end if;
  if (select count(*) from public.marka_takip t where lower(t.eposta) = v_e and t.aktif) >= 25 then
    return jsonb_build_object('durum', 'TAVAN'); end if;

  select * into r from public.marka_takip t where t.ad_norm = v_n and lower(t.eposta) = v_e limit 1;
  if found and r.aktif and r.onaylandi is not null then
    return jsonb_build_object('durum', 'ZATEN_ACIK', 'ad', r.ad); end if;
  if found and r.onay_gonderim > now() - interval '10 minutes' then
    return jsonb_build_object('durum', 'BEKLE', 'ad', r.ad); end if;

  v_oj := encode(extensions.gen_random_bytes(24), 'hex');
  if not found then
    insert into public.marka_takip (ad, ad_norm, sinif, eposta, jeton, aktif, onaylandi, onay_jeton, onay_son, onay_gonderim)
    values (btrim(p_ad), v_n, coalesce(p_sinif, '{}'), v_e, encode(extensions.gen_random_bytes(24), 'hex'),
            false, null, v_oj, now() + interval '48 hours', now())
    returning * into r;
  else
    update public.marka_takip t
       set sinif = coalesce(p_sinif, t.sinif), aktif = false, onaylandi = null,
           onay_jeton = v_oj, onay_son = now() + interval '48 hours', onay_gonderim = now()
     where t.id = r.id returning * into r;
  end if;
  return jsonb_build_object('durum', 'ONAY_GONDER', 'ad', r.ad, 'sinif', r.sinif, 'onay', v_oj);
end; $function$
;

-- marka_takip_bekleyen(integer)
CREATE OR REPLACE FUNCTION public.marka_takip_bekleyen(p_tavan integer DEFAULT 500)
 RETURNS TABLE(takip_id uuid, eposta text, jeton text, takip_ad text, takip_sinif integer[], basvuru_no text, bulten_no integer, ad text, sahip text, sinif integer[], yayin_tarihi date, itiraz_son date, kalan_gun integer, benzerlik real, ayni_sinif boolean, kademe text, sebep text, tur text, hatirlatma integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
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
           g.basvuru_no is null
           or (g.hatirlatma < 1 and (x.itiraz_son - current_date) <= 20)
           or (g.hatirlatma < 2 and (x.itiraz_son - current_date) <= 7)
         )
       order by (cardinality(t.sinif) > 0 and x.sinif && t.sinif) desc,
                x.itiraz_son asc
       limit 200
    ) b
   where t.aktif
     and t.onaylandi is not null
     and b.kademe <> 'ZAYIF'
   order by t.id, (b.kademe = 'YUKSEK') desc, b.itiraz_son asc
   limit least(greatest(p_tavan, 1), 5000);
$function$
;

-- marka_takip_gor(text)
CREATE OR REPLACE FUNCTION public.marka_takip_gor(p_jeton text)
 RETURNS TABLE(ad text, sinif integer[], aktif boolean, olusma timestamp with time zone, son_uyari timestamp with time zone, uyari_sayisi bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select t.ad, t.sinif, t.aktif, t.olusma, t.son_uyari,
         (select count(*) from public.marka_takip_gonderim g where g.takip_id = t.id)
    from public.marka_takip t
   where t.jeton = p_jeton and length(p_jeton) = 48;
$function$
;

-- marka_takip_isaretle(uuid,jsonb)
CREATE OR REPLACE FUNCTION public.marka_takip_isaretle(p_takip_id uuid, p_kayitlar jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

-- marka_takip_kapat(text)
CREATE OR REPLACE FUNCTION public.marka_takip_kapat(p_jeton text)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with u as (
    update public.marka_takip set aktif = false
     where jeton = p_jeton and length(p_jeton) = 48
    returning 1)
  select exists (select 1 from u);
$function$
;

-- marka_takip_onayla(text)
CREATE OR REPLACE FUNCTION public.marka_takip_onayla(p_onay text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.marka_takip;
begin
  if p_onay is null or p_onay !~ '^[0-9a-f]{48}$' then return jsonb_build_object('durum', 'GECERSIZ'); end if;
  select * into r from public.marka_takip t where t.onay_jeton = p_onay for update;
  if not found then return jsonb_build_object('durum', 'GECERSIZ'); end if;
  if r.onay_son < now() then
    update public.marka_takip set onay_jeton = null where id = r.id;
    return jsonb_build_object('durum', 'SURESI_DOLDU', 'ad', r.ad); end if;
  update public.marka_takip set aktif = true, onaylandi = now(), onay_jeton = null where id = r.id;
  return jsonb_build_object('durum', 'ONAYLANDI', 'ad', r.ad, 'sinif', r.sinif, 'jeton', r.jeton);
end; $function$
;

-- marka_takip_sayac()
CREATE OR REPLACE FUNCTION public.marka_takip_sayac()
 RETURNS TABLE(aktif_nobet bigint, uyarilan bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select (select count(*) from public.marka_takip where aktif),
         (select count(*) from public.marka_takip_gonderim);
$function$
;

-- marka_talep_ac(text,text,text)
CREATE OR REPLACE FUNCTION public.marka_talep_ac(p_unvan text, p_email text DEFAULT NULL::text, p_kaynak text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_jeton text; v_gunluk int;
begin
  if p_unvan is null or length(btrim(p_unvan)) < 3 or length(p_unvan) > 160 then
    raise exception 'Unvan 3-160 karakter olmali'; end if;
  select count(*) into v_gunluk from public.marka_talep where created_at > now() - interval '1 day';
  if v_gunluk > 3000 then raise exception 'Gunluk sorgu tavani doldu, yarin tekrar dene'; end if;
  v_jeton := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
  insert into public.marka_talep(jeton, unvan, email, user_id, kaynak)
  values (v_jeton, btrim(p_unvan), nullif(btrim(coalesce(p_email,'')),''), auth.uid(),
          left(nullif(btrim(coalesce(p_kaynak,'')),''),40));
  return v_jeton;
end; $function$
;

-- marka_talep_sonuc(text)
CREATE OR REPLACE FUNCTION public.marka_talep_sonuc(p_jeton text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare v record; begin select durum, unvan, sonuc, hata into v from public.marka_talep where jeton = p_jeton; if not found then return jsonb_build_object('durum','yok'); end if; return jsonb_build_object('durum', v.durum, 'unvan', v.unvan, 'sonuc', v.sonuc, 'hata', v.hata); end; $function$
;

-- mukellef_pano(uuid)
CREATE OR REPLACE FUNCTION public.mukellef_pano(p_token uuid)
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select json_build_object(
    'mukellef', m.ad,
    'belgeler', coalesce((
      select json_agg(json_build_object('dosya_adi',b.dosya_adi,'tur',b.tur,'donem',b.donem,'url',b.url,'ts',b.ts) order by b.ts desc)
      from belgeler b where b.mukellef_id = m.id), '[]'::json)
  ) from mukellefler m where m.pano_token = p_token;
$function$
;

-- nobetci_durum(uuid)
CREATE OR REPLACE FUNCTION public.nobetci_durum(p_uid uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'bugun', (select count(*) from public.nobetci_soru where user_id = p_uid and durum = 'cevaplandi'
                and tarih >= date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_usd', (select coalesce(sum(bedel_usd), 0) from public.nobetci_soru
                where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'));
$function$
;

-- olay_say(text,text)
CREATE OR REPLACE FUNCTION public.olay_say(p_olay text, p_platform text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_olay not in ('ilk_acilis', 'soru_1', 'soru_3', 'kapi', 'uye_ol', 'giris', 'soru_10', 'soru_30',
                    'ara_karne', 'tam_paket_bak', 'paket_ekrani', 'satin_al_bas', 'satin_aldi', 'hesap_sil',
                    'karma_kisa', 'karma_cok') then
    return;
  end if;
  if p_platform not in ('android', 'ios', 'web') then
    return;
  end if;
  insert into public.uygulama_olay (olay, platform, sayi) values (p_olay, p_platform, 1)
  on conflict (gun, olay, platform) do update set sayi = public.uygulama_olay.sayi + 1;
end;
$function$
;

-- ozel_kod_kontrol(text,text)
CREATE OR REPLACE FUNCTION public.ozel_kod_kontrol(p_kod text, p_paket text)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(public._ozel_kod_gecerli(p_kod, p_paket), 0);
$function$
;

-- paket_erisim_var(text,text)
CREATE OR REPLACE FUNCTION public.paket_erisim_var(p_sinav text, p_ders text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.paket_uyeler pu
    where pu.user_id = auth.uid()
      and (pu.bitis is null or pu.bitis >= current_date)
      and (
        coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu')
        or (p_sinav = 'sgs'  and (lower(trim(pu.paket)) = 'sgs' or lower(trim(pu.paket)) like 'sgs-%'
                                   or lower(trim(pu.paket)) = 'sinav-249'))
        or (p_sinav = 'smmm' and (lower(trim(pu.paket)) in ('yeterlilik','smmm','yeterlilik-kgk')
                                   or lower(trim(pu.paket)) like 'yeterlilik-%'))
        or (p_sinav = 'kgk'  and (lower(trim(pu.paket)) in ('kgk','yeterlilik-kgk')
                                   or lower(trim(pu.paket)) like 'kgk-%'))
      )
      and (pu.dersler is null or p_ders = any(pu.dersler))
  );
$function$
;

-- paket_secim_sayac()
CREATE OR REPLACE FUNCTION public.paket_secim_sayac()
 RETURNS TABLE(paket text, satilan integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with odenen as (
    select s.paket from public.siparisler s where s.durum = 'odendi'
    union all
    select case when m.urun ~ '^(sgs|yeterlilik_[1-4]|yeterlilik_tum)$' then replace(m.urun, '_', '-') else m.paket end
      from public.magaza_siparis m where m.durum in ('verildi','tuketildi')
  )
  select o.paket, count(*)::int
    from odenen o
   where o.paket is not null
   group by o.paket;
$function$
;

-- paketimi_bagla(text,text)
CREATE OR REPLACE FUNCTION public.paketimi_bagla(p_no text, p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_uid uuid := auth.uid(); s public.siparisler%rowtype; p public.paket_uyeler%rowtype; v_sonuc text;
begin
  if v_uid is null then raise exception 'GIRIS_YOK' using errcode = '42501'; end if;
  if not public.rate_limit_check('pbag:' || v_uid::text, 5, 600) then return jsonb_build_object('hata', 'COK_DENEME'); end if;
  select * into s from public.siparisler
   where upper(siparis_no) = upper(trim(coalesce(p_no, ''))) and lower(email) = lower(trim(coalesce(p_eposta, '')));
  if not found or s.durum not in ('odendi', 'odeme_bekliyor') then return jsonb_build_object('hata', 'ESLESMEDI'); end if;
  if s.durum = 'odeme_bekliyor' then return jsonb_build_object('hata', 'ODEME_BEKLIYOR'); end if;
  if s.bagli_kullanici = v_uid then return jsonb_build_object('hata', 'ZATEN_ACIK'); end if;
  if s.bagli_kullanici is not null then return jsonb_build_object('hata', 'BASKA_HESAPTA'); end if;
  if exists (select 1 from auth.users u where lower(u.email) = lower(s.email) and u.id <> v_uid) then return jsonb_build_object('hata', 'EPOSTA_HESABI_VAR'); end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  if found and p.bitis >= current_date and p.paket <> s.paket then return jsonb_build_object('hata', 'PAKET_VAR'); end if;
  v_sonuc := public._siparis_isle(s.id, v_uid, 'uye-siparis-no');
  if v_sonuc not in ('ACILDI', 'ZATEN_ACIK') then return jsonb_build_object('hata', v_sonuc); end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  return jsonb_build_object('paket', p.paket, 'bitis', p.bitis, 'sonuc', v_sonuc);
end $function$
;

-- prova_cizim(text,jsonb)
CREATE OR REPLACE FUNCTION public.prova_cizim(p_oturum text, p_idler jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ip     text;
  izin   text[];
  acilis timestamptz;
  e      jsonb;
  sid    text;
  v      jsonb;
  sonuc  jsonb := '{}'::jsonb;
  n      int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('prova-cizim:' || trim(ip), 30, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if p_oturum = 'YET-2410' then
    acilis := timestamptz '2026-10-24 09:30:00+00';
    izin := array[
      'smmm-w9-1-fmuh-cokzor/kp-08','smmm-gm3-3-fmuh-zor/kp-02','smmm-4k-a-fmuh-cokzor-r2/kp-01','smmm-4k-a-fmuh-kolay-r2-2/kp-01',
      'smmm-4k-a-fmuh-zor-r4/kp-12','smmm-w6-fmuh-zor/kp-34','smmm-w1-fmuh-zor/kp-05','smmm-w4-fmuh-cokzor/kp-10',
      'smmm-w5-fmuh-kolay/kp-16','smmm-w11-1-fmuh-cokzor/kp-02','smmm-w4-fmuh-cokzor/kp-09','smmm-4k-a-fmuh-zor-r3-2/kp-02',
      'smmm-gm5-28-fmuh-zor/kp-04','smmm-w10-4-fmuh-kolay/kp-01','smmm-gm5-10-fmuh-zor/kp-07','smmm-w5-fmuh-kolay/kp-15',
      'smmm-4k-a-maliyet-zor-r3/kp-20','smmm-4k-a-maliyet-kolay-r3/kp-02','smmm-gm4-5-maliyet-kolay/kp-02','smmm-w9-2-maliyet-kolay/kp-01',
      'smmm-4k-a-maliyet-kolay-r4-2/kp-03','smmm-4k-a-maliyet-zor-r3/kp-04','smmm-4k-a-maliyet-zor-r9/kp-03','smmm-4k-a-maliyet-kolay-r3/kp-20',
      'smmm-w7-2-maliyet-kolay/kp-01','smmm-gm5-2-maliyet-zor/kp-01','smmm-4k-a-maliyet-zor-r1/kp-23','smmm-w1-maliyet-zor/kp-14',
      'smmm-4k-a-maliyet-zor-r9/kp-02','smmm-gm-p2-maliyet/kp-03','smmm-gm5-1-maliyet-zor/kp-02','smmm-gm-p2-maliyet/kp-01',
      'smmm-4k-a-maliyet-zor-r7/kp-17','smmm-4k-a-maliyet-zor-r2/kp-01','smmm-w6-yhukuk-kolay/kp-01','smmm-4k-a-yhukuk-zor-r7/kp-05',
      'smmm-gm4-6-yspk-zor/kp-01','smmm-w14-11-yspk-cokzor/kp-01','smmm-w14-13-yspk-cokzor/kp-01'];
  else
    return jsonb_build_object('acik', false, 'sorular', '{}'::jsonb);
  end if;
  if not public.prova_cizim_acik(p_oturum, now()) then
    return jsonb_build_object('acik', false, 'acilis', acilis, 'sorular', '{}'::jsonb);
  end if;
  if jsonb_typeof(p_idler) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for e in select * from jsonb_array_elements(p_idler) loop
    n := n + 1; exit when n > 80;
    sid := left(coalesce(e #>> '{}', ''), 120);
    continue when not (sid = any(izin));
    select veri into v from public.paket_soru p where p.id = sid;
    continue when v is null;
    sonuc := sonuc || jsonb_build_object(sid, jsonb_build_object(
      'id', sid,
      'soru', v->'soru',
      'siklar', v->'siklar',
      'dogru', v->'dogru',
      'adimlar', (select jsonb_agg(jsonb_build_object('formul', a->'formul', 'anlatim', a->'anlatim', 'verilenAdim', a->'verilenAdim',
                                                      'sik', a->'sik', 'kisi', a->'kisi', 'giris', a->'giris') order by o)
                  from jsonb_array_elements(case when jsonb_typeof(v->'adimlar') = 'array' then v->'adimlar' else '[]'::jsonb end) with ordinality as x(a, o)),
      'celdiriciYol', v->'celdiriciYol',
      'teshis', (select jsonb_object_agg(k, jsonb_build_object('yanilgi', t->'yanilgi'))
                 from jsonb_each(case when jsonb_typeof(v->'teshis') = 'object' then v->'teshis' else '{}'::jsonb end) as y(k, t))
    ));
  end loop;
  return jsonb_build_object('acik', true, 'acilis', acilis, 'sorular', sonuc);
end;
$function$
;

-- prova_cizim_acik(text,timestamp with time zone)
CREATE OR REPLACE FUNCTION public.prova_cizim_acik(p_oturum text, p_an timestamp with time zone)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select coalesce((select p_an >= o.kapanis
                   from (values ('YET-2410'::text, timestamptz '2026-10-24 09:30:00+00')) as o(kod, kapanis)
                   where o.kod = p_oturum), false)
$function$
;

-- rate_limit_check(text,integer,integer)
CREATE OR REPLACE FUNCTION public.rate_limit_check(p_ip text, p_limit integer, p_pencere_sn integer DEFAULT 60)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

-- rls_auto_enable()
CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

-- s20_deneme_yukle(jsonb)
CREATE OR REPLACE FUNCTION public.s20_deneme_yukle(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- s20_erisim()
CREATE OR REPLACE FUNCTION public.s20_erisim()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.paket_uyeler pu
    where pu.user_id = auth.uid()
      and (pu.bitis is null or pu.bitis >= current_date)
      and (coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu','son20-sgs','sgs','sinav-249')
           or lower(trim(pu.paket)) like 'sgs-%')
  );
$function$
;

-- s20_gorev_cevap(integer,text,text,text,text)
CREATE OR REPLACE FUNCTION public.s20_gorev_cevap(p_deneme integer, p_ders text, p_konu text, p_id text, p_secim text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- s20_gorev_getir(integer,text,text)
CREATE OR REPLACE FUNCTION public.s20_gorev_getir(p_deneme integer, p_ders text, p_konu text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- s20_liste()
CREATE OR REPLACE FUNCTION public.s20_liste()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- s20_test_bitir(integer,text,jsonb,integer)
CREATE OR REPLACE FUNCTION public.s20_test_bitir(p_deneme integer, p_ders text, p_cevap jsonb, p_sure_sn integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- s20_test_getir(integer,text)
CREATE OR REPLACE FUNCTION public.s20_test_getir(p_deneme integer, p_ders text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

-- seviye_aciklama(jsonb)
CREATE OR REPLACE FUNCTION public.seviye_aciklama(p_cevaplar jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ip    text;
  c     jsonb;
  sid   text;
  sec   text;
  v     jsonb;
  dogru text;
  sade  text;
  tmetin text;
  day   text;
  sonuc jsonb := '[]'::jsonb;
  n     int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye-aciklama:' || trim(ip), 15, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if jsonb_typeof(p_cevaplar) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for c in select * from jsonb_array_elements(p_cevaplar) loop
    exit when n >= 3;
    sid := left(coalesce(c->>'id',''), 120);
    sec := upper(left(coalesce(c->>'secim',''), 1));
    select veri into v from public.paket_soru p
      where p.id = sid and p.ucretsiz
        and not exists (select 1 from public.vitrin_aciklama_dislanan d where d.id = p.id);
    continue when v is null;
    dogru := upper(coalesce(v->>'dogru',''));
    continue when sec = dogru;
    sade := case when jsonb_typeof(v->'sade') = 'object' then v->'sade'->>'dogru' else v->>'sade' end;
    continue when coalesce(sade,'') = '';
    tmetin := case when sec = '' then null else v->'tuzak'->sec->>'metin' end;
    continue when sec <> '' and coalesce(tmetin,'') = '';
    day := v->>'dayanak';
    if day ~* '\m(sayili|isletme|odeme|isci|isveren|sirket|yonetmelik|yonetmeligi|teblig|tebligi|ozel|gorev|ucret|degisik|gecici|kurulus|sozlesme|hukum|sira|tekduzen|plani|duzenleme|islem|islemleri|mukellef|degerleme|yukumlu)\M'
       or day ~* '(mevzuat maddesi yok|\(kaynak metni?\)|kaynak metne göre|\mkural *[0-9]|\[[0-9]/[0-9]\]|\mambar\M|kaynak paket|teori *par[cç]as|uygulama *: *[a-e]? *ş[ıi]kk|sınav tuzağı *\([0-9]|ders notu.{0,40}madde *[0-9])' then
      day := null;
    end if;
    sonuc := sonuc || jsonb_build_array(jsonb_build_object(
      'id', sid, 'secim', nullif(sec,''), 'dogru', dogru,
      'secim_metin', case when sec = '' then null else v->'siklar'->>sec end, 'dogru_metin', v->'siklar'->>dogru,
      'tuzak_ad', case when sec = '' then null else v->'tuzak'->sec->>'ad' end, 'tuzak_metin', tmetin,
      'aciklama', sade, 'kural', v->>'kural', 'dayanak', day));
    n := n + 1;
  end loop;
  return jsonb_build_object('liste', sonuc);
end $function$
;

-- seviye_cizim(jsonb)
CREATE OR REPLACE FUNCTION public.seviye_cizim(p_idler jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ip    text;
  izin  text[] := array[
    'smmm-4k-a-fmuh-zor-r5/kp-03',
    'sgs-k11-ticaret-zor/kp-01', 'sgs-d3-mta-cokzor-r3/kp-01', 'sgs-d3-maliyet-cokzor-r1/kp-02', 'sgs-c2-fmuh-kolay-r1/kp-02',
    'sgs-t1-fmuh-kolay/kp-11', 'sgs-d5-vergi-cokzor-r2/kp-02', 'sgs-d3-fmuh-kolay-r1/kp-16', 'sgs-d3-fmuh-kolay-r1/kp-21',
    'sgs-d2-fmuh-kolay-r1/kp-03', 'sgs-k11-mat-kolay/kp-03', 'sgs-c2-fmuh-kolay-r1/kp-03', 'sgs-d2-fmuh-zor-r1/kp-01',
    'sgs-d2-fmuh-kolay-r2/kp-04', 'sgs-c2-fmuh-zor-r3/kp-02', 'sgs-c2-denetim-kolay-r2/kp-05', 'sgs-c2-mta-kolay-r1/kp-01',
    'sgs-k5-fmuh-zor/kp-17', 'sgs-p-ekonomi-kolay-r1-a/kp-04', 'sgs-t1-mta-zor/kp-01', 'sgs-t1-maliyet-kolay/kp-07'];
  e     jsonb;
  sid   text;
  v     jsonb;
  n     int := 0;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye-cizim:' || trim(ip), 20, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  if jsonb_typeof(p_idler) <> 'array' then return jsonb_build_object('hata','dizi degil'); end if;
  for e in select * from jsonb_array_elements(p_idler) loop
    n := n + 1; exit when n > 40;
    sid := left(coalesce(e #>> '{}', ''), 120);
    continue when not (sid = any(izin));
    select veri into v from public.paket_soru p where p.id = sid and p.ucretsiz;
    continue when v is null;
    return jsonb_build_object('soru', jsonb_build_object(
      'id', sid,
      'soru', v->'soru',
      'siklar', v->'siklar',
      'dogru', v->'dogru',
      'adimlar', (select jsonb_agg(jsonb_build_object('formul', a->'formul', 'anlatim', a->'anlatim', 'verilenAdim', a->'verilenAdim',
                                                      'sik', a->'sik', 'kisi', a->'kisi', 'giris', a->'giris') order by o)
                  from jsonb_array_elements(case when jsonb_typeof(v->'adimlar') = 'array' then v->'adimlar' else '[]'::jsonb end) with ordinality as x(a, o)),
      'celdiriciYol', v->'celdiriciYol',
      'teshis', (select jsonb_object_agg(k, jsonb_build_object('yanilgi', t->'yanilgi'))
                 from jsonb_each(case when jsonb_typeof(v->'teshis') = 'object' then v->'teshis' else '{}'::jsonb end) as y(k, t))
    ));
  end loop;
  return jsonb_build_object('soru', null);
end;
$function$
;

-- seviye_kiyas(text,integer)
CREATE OR REPLACE FUNCTION public.seviye_kiyas(p_sinav text, p_dogru integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_n integer; v_alt integer; v_esik constant integer := 100;
begin
  if p_sinav is null or p_sinav not in ('sgs', 'smmm') or p_dogru is null or p_dogru < 0 or p_dogru > 40 then
    return jsonb_build_object('acik', false);
  end if;
  with t as (
    select oturum, sum(case when dogru_mu then 1 else 0 end) as d
    from public.cevap_kayit
    where kaynak = 'seviye-testi' and oturum is not null
      and soru_id like (case when p_sinav = 'smmm' then 'smmm-%' else 'sgs-%' end)
    group by oturum
    having count(*) between 30 and 40
  )
  select count(*), count(*) filter (where d < p_dogru) into v_n, v_alt from t;
  if v_n < v_esik then
    return jsonb_build_object('acik', false, 'n', v_n, 'esik', v_esik);
  end if;
  return jsonb_build_object('acik', true, 'n', v_n, 'altinda', round(100.0 * v_alt / v_n));
end;
$function$
;

-- seviye_kontrol(text,text)
CREATE OR REPLACE FUNCTION public.seviye_kontrol(p_id text, p_secim text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  d  text;
  ip text;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye:' || trim(ip), 40, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  select veri->>'dogru' into d from public.paket_soru where id = p_id and ucretsiz;
  if d is null then return jsonb_build_object('hata','soru yok'); end if;
  return jsonb_build_object('dogru_mu', upper(coalesce(p_secim,'')) = upper(d), 'dogru', d);
end $function$
;

-- sik_yuzdesi(text)
CREATE OR REPLACE FUNCTION public.sik_yuzdesi(p_soru_id text)
 RETURNS TABLE(secim text, n bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select secim, count(*)::bigint as n
  from public.cevap_kayit
  where soru_id = p_soru_id and length(p_soru_id) between 3 and 120
    and coalesce(oturum, '') not in (
      'pj0d61czmuy98c1i',     -- 08.10 site oturumunun canlı denetimi (ornek-sgs, 5 satır)
      'os-muytfbpt-r64a4y'    -- 08.10 site oturumunun yerel denemesi (eski ornek-sorular.html, 1 satır)
    )
  group by secim;
$function$
;

-- siparis_cift_kapi()
CREATE OR REPLACE FUNCTION public.siparis_cift_kapi()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v text;
begin
  v := public.siparis_cift_sebep(new.email, auth.uid(), new.paket, new.secilen_dersler, null);
  if v is not null then
    raise exception '%', v using hint = 'Bu paket hesabında zaten açık; ikinci kez ödeme alınmaz.';
  end if;
  if exists (
    select 1 from public.siparisler s
     where lower(s.email) = lower(btrim(coalesce(new.email, ''))) and s.durum = 'odeme_bekliyor'
       and s.paket = new.paket and s.tutar = new.tutar
       and coalesce(s.secilen_dersler, array[]::text[]) @> coalesce(new.secilen_dersler, array[]::text[])
       and coalesce(s.secilen_dersler, array[]::text[]) <@ coalesce(new.secilen_dersler, array[]::text[])
       and s.olusturma > now() - interval '24 hours'
  ) then
    raise exception 'BEKLEYEN_SIPARIS' using hint = 'Bu paket için ödeme bekleyen siparişin var; onu öde.';
  end if;
  return new;
end $function$
;

-- siparis_cift_sebep(text,uuid,text,text[],text)
CREATE OR REPLACE FUNCTION public.siparis_cift_sebep(p_eposta text, p_uid uuid, p_paket text, p_dersler text[], p_haric_no text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_ep text := lower(btrim(coalesce(p_eposta, '')));
begin
  if exists (
    select 1 from public.paket_uyeler p
     where p.bitis >= current_date
       and public._paket_kapsar(p.paket, p.dersler, p_paket, p_dersler)
       and (p.user_id = p_uid
            or p.user_id in (select u.id from auth.users u where v_ep <> '' and lower(u.email) = v_ep))
  ) then return 'PAKET_ZATEN_ACIK'; end if;
  if v_ep <> '' and exists (
    select 1 from public.siparisler s
     where lower(s.email) = v_ep and s.durum = 'odendi' and s.bagli_kullanici is null
       and coalesce(s.paket_bitis, current_date) >= current_date
       and s.siparis_no is distinct from p_haric_no
       and public._paket_kapsar(s.paket, s.secilen_dersler, p_paket, p_dersler)
  ) then return 'PAKET_ZATEN_ACIK'; end if;
  return null;
end $function$
;

-- siparis_elci_damga()
CREATE OR REPLACE FUNCTION public.siparis_elci_damga()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_kod     text;
  v_indirim integer;
  v_sabit   integer;
  v_email   text;
  v_user    uuid;
begin
  new.indirim_tl := 0;
  new.elci_sabit_komisyon_tl := null;
  v_kod := nullif(upper(regexp_replace(coalesce(new.elci_kodu, ''), '[^A-Za-z0-9]', '', 'g')), '');
  if v_kod is null then
    new.elci_kodu := null;
    return new;
  end if;

  select i.indirim_tl, i.sabit_komisyon_tl, e.email, e.user_id into v_indirim, v_sabit, v_email, v_user
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

  new.elci_kodu              := v_kod;
  new.indirim_tl             := v_indirim;
  new.elci_sabit_komisyon_tl := v_sabit;
  return new;
end $function$
;

-- siparis_gads_tiklama_suz()
CREATE OR REPLACE FUNCTION public.siparis_gads_tiklama_suz()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  new.gads_tiklama := nullif(btrim(coalesce(new.gads_tiklama, '')), '');
  if new.gads_tiklama is not null and new.gads_tiklama !~ '^[A-Za-z0-9_-]{10,200}$' then new.gads_tiklama := null; end if;
  if new.gads_tiklama is null then
    new.gads_tiklama_zaman := null;
  elsif new.gads_tiklama_zaman > now() + interval '5 minutes' or new.gads_tiklama_zaman < now() - interval '90 days' then
    new.gads_tiklama_zaman := null;
  end if;
  return new;
end $function$
;

-- siparis_odeme_kontrol(text)
CREATE OR REPLACE FUNCTION public.siparis_odeme_kontrol(p_no text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid;
begin
  select * into s from public.siparisler where siparis_no = p_no;
  if not found then return 'SIPARIS_YOK'; end if;
  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  return coalesce(public.siparis_cift_sebep(s.email, v_uid, s.paket, s.secilen_dersler, s.siparis_no), 'TAMAM');
end $function$
;

-- siparis_odendi_damga()
CREATE OR REPLACE FUNCTION public.siparis_odendi_damga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.durum = 'odendi' and coalesce(old.durum, '') <> 'odendi' and new.odendi_tarihi is null then
    new.odendi_tarihi := now();
  end if;
  return new;
end $function$
;

-- siparis_paket_bagla(uuid,text)
CREATE OR REPLACE FUNCTION public.siparis_paket_bagla(p_uid uuid, p_eposta text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_sid bigint;
begin
  if p_uid is null or coalesce(p_eposta, '') = '' then return 'BOS'; end if;
  select id into v_sid from public.siparisler
   where lower(email) = lower(p_eposta) and durum = 'odendi'
     and (bagli_kullanici is null or bagli_kullanici = p_uid)
   order by odendi_tarihi desc nulls last, olusturma desc limit 1;
  if v_sid is null then return 'SIPARIS_YOK'; end if;
  return public._siparis_isle(v_sid, p_uid, 'eposta');
end $function$
;

-- siparis_teklif_damga()
CREATE OR REPLACE FUNCTION public.siparis_teklif_damga()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  t      anlik_teklif%rowtype;
  v_ind  integer;
  v_t    integer := 0;
  v_o    integer := 0;
  v_e    integer;
begin
  new.anlik_teklif_tl := 0;
  new.ozel_kod_tl := 0;
  new.kaynak_etiket := nullif(lower(btrim(coalesce(new.kaynak_etiket, ''))), '');
  if new.kaynak_etiket is not null and new.kaynak_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}$' then new.kaynak_etiket := null; end if;
  new.teklif_belirtec := nullif(lower(btrim(coalesce(new.teklif_belirtec, ''))), '');
  new.ozel_kod := nullif(upper(regexp_replace(coalesce(new.ozel_kod, ''), '[^A-Za-z0-9]', '', 'g')), '');
  v_e := coalesce(new.indirim_tl, 0);

  -- anlık teklif adayı (kurallar 12.10 ile aynı)
  if new.teklif_belirtec is not null then
    select * into t from anlik_teklif where belirtec = new.teklif_belirtec for update;
    select a.indirim_tl into v_ind from anlik_teklif_ayar a
     where a.paket = new.paket and a.acik and a.sinav = 'yeterlilik';
    if t.belirtec is null
       or auth.uid() is null or t.user_id <> auth.uid()
       or t.kullanildi is not null
       or t.son <= now()
       or v_ind is null
       or (new.paket = 'yeterlilik-1' and not (t.ders = any (coalesce(new.secilen_dersler, array[]::text[]))))
       or exists (select 1 from anlik_teklif u where u.user_id = t.user_id and u.ders = t.ders and u.kullanildi is not null) then
      raise exception 'TEKLIF_GECERSIZ' using hint = 'Anlık teklif bu hesapta geçerli değil ya da kullanıldı.';
    end if;
    v_t := v_ind;
  end if;

  -- özel kod adayı: önce satırı kilitle (aynı anda iki sipariş aynı kodu alamasın), sonra yeniden sına
  if new.ozel_kod is not null then
    perform 1 from ozel_kod where kod = new.ozel_kod for update;
    v_o := public._ozel_kod_gecerli(new.ozel_kod, new.paket);
    if v_o is null then
      raise exception 'OZEL_KOD_GECERSIZ' using hint = 'Özel indirim kodu bu pakette geçerli değil, süresi geçmiş ya da kullanılmış.';
    end if;
  end if;

  if v_t > v_e and v_t > v_o then
    update anlik_teklif set kullanildi = now(), siparis_no = new.siparis_no, kullanilan_paket = new.paket
     where belirtec = t.belirtec;
    new.anlik_teklif_tl := v_t;
    new.ozel_kod := null;
    new.elci_kodu := null;
    new.indirim_tl := 0;
    new.elci_sabit_komisyon_tl := null;
  elsif v_o > v_e then
    update ozel_kod set kullanildi = now(), siparis_no = new.siparis_no where kod = new.ozel_kod;
    new.ozel_kod_tl := v_o;
    new.teklif_belirtec := null;
    new.elci_kodu := null;
    new.indirim_tl := 0;
    new.elci_sabit_komisyon_tl := null;
  else
    -- elçi indirimi müşteri lehine (ya da eşit) ya da hiç indirim yok: teklif ve kod TÜKETİLMEZ
    new.teklif_belirtec := null;
    new.ozel_kod := null;
  end if;

  new.indirim_kaynak := case when new.anlik_teklif_tl > 0 then 'anlik-teklif'
                             when new.ozel_kod_tl > 0 then 'ozel:' || new.ozel_kod
                             when new.elci_kodu is not null then 'elci:' || new.elci_kodu
                             else 'yok' end;
  return new;
end $function$
;

-- tr_fold(text)
CREATE OR REPLACE FUNCTION public.tr_fold(t text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- LIKE joker karakterleri (% _ \) SILINIR: kullanici '%' yazip tum arsivi
  -- tarayamasin (joker enjeksiyonu). Turkce unvanlarda bu karakterler gecmez.
  select regexp_replace(
           regexp_replace(
             upper(translate(coalesce(t,''),
                   'ıİğĞüÜşŞöÖçÇâÂîÎûÛ',
                   'iIgGuUsSoOcCaAiIuU')),
             '[%_\\]', '', 'g'),
           '\s+', ' ', 'g')
$function$
;

-- uyari_teyit(uuid)
CREATE OR REPLACE FUNCTION public.uyari_teyit(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r record;
  onceden boolean;
begin
  select id, baslik, tur, url, teyit_at
    into r
    from public.firma_uyarilari
   where teyit_token = p_token;

  if not found then
    return jsonb_build_object('ok', false, 'sebep', 'BULUNAMADI');
  end if;

  onceden := (r.teyit_at is not null);

  if not onceden then
    update public.firma_uyarilari
       set teyit_at = now(), teyit_kanal = 'link', okundu = true
     where id = r.id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'baslik', r.baslik,
    'tur', r.tur,
    'url', r.url,
    'zatenTeyitli', onceden
  );
end;
$function$
;

-- uyari_teyit_durum(uuid)
CREATE OR REPLACE FUNCTION public.uyari_teyit_durum(p_token uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((
    select jsonb_build_object(
      'ok', true,
      'baslik', baslik,
      'tur', tur,
      'url', url,
      'zatenTeyitli', (teyit_at is not null),
      'bildirimSayisi', bildirim_sayisi
    )
    from public.firma_uyarilari
    where teyit_token = p_token
  ), jsonb_build_object('ok', false, 'sebep', 'BULUNAMADI'))
$function$
;

-- uye_calisma_ozetim()
CREATE OR REPLACE FUNCTION public.uye_calisma_ozetim()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with c as (
    select a.soru_id, a.dogru, a.zaman, s.sinav, s.ders,
           coalesce(nullif(trim(coalesce(s.konu, s.veri->>'konu')), ''), 'Konusu işaretlenmemiş') as konu
    from public.kasa_cevap a
    join public.paket_soru s on s.id = a.soru_id
    where a.user_id = auth.uid()
  ),
  d as (
    select sinav, ders,
           count(distinct soru_id)                                                                   as cozulen,
           count(*)                                                                                  as cevap,
           count(*) filter (where dogru)                                                             as dogru,
           count(*) filter (where zaman > now() - interval '7 days')                                 as h_cevap,
           count(*) filter (where dogru and zaman > now() - interval '7 days')                       as h_dogru,
           count(*) filter (where zaman <= now() - interval '7 days' and zaman > now() - interval '14 days')            as o_cevap,
           count(*) filter (where dogru and zaman <= now() - interval '7 days' and zaman > now() - interval '14 days')  as o_dogru,
           max(zaman)                                                                                as son
    from c
    group by sinav, ders
  ),
  k as (
    select sinav, ders, konu,
           count(distinct soru_id)                                             as cozulen,
           count(*)                                                            as cevap,
           count(*) filter (where dogru)                                       as dogru,
           count(*) filter (where zaman > now() - interval '7 days')           as h_cevap,
           count(*) filter (where dogru and zaman > now() - interval '7 days') as h_dogru,
           max(zaman)                                                          as son
    from c
    group by sinav, ders, konu
    order by count(*) desc
    limit 2000
  )
  select jsonb_build_object(
    'dersler', coalesce((select jsonb_agg(to_jsonb(d) order by d.sinav, d.cevap desc) from d), '[]'::jsonb),
    'konular', coalesce((select jsonb_agg(to_jsonb(k)) from k), '[]'::jsonb),
    'olcum',   now()
  );
$function$
;

-- uye_cozdugum_sorular()
CREATE OR REPLACE FUNCTION public.uye_cozdugum_sorular()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object('i', t.soru_id, 'd', t.ders, 'o', t.dogru)), '[]'::jsonb)
  from (
    select distinct on (a.soru_id) a.soru_id, s.ders, a.dogru
    from public.kasa_cevap a
    left join public.paket_soru s on s.id = a.soru_id
    where a.user_id = auth.uid()
    order by a.soru_id, a.zaman desc
    limit 30000
  ) t;
$function$
;

-- uye_sayim()
CREATE OR REPLACE FUNCTION public.uye_sayim()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'toplam',          (select count(*) from auth.users),
    'son_1_saat',      (select count(*) from auth.users where created_at > now() - interval '1 hour'),
    'son_24_saat',     (select count(*) from auth.users where created_at > now() - interval '24 hours'),
    'en_yogun_dakika', coalesce((select max(d.n) from (
                          select count(*) as n
                          from auth.users
                          where created_at > now() - interval '1 hour'
                          group by date_trunc('minute', created_at)
                        ) d), 0),
    'paylasim_supheli', (select count(*) from (
                          select user_id from public.uye_cihaz_olay
                          where olay = 'devraldi' and zaman > now() - interval '24 hours'
                          group by user_id having count(*) >= 8) p),
    'cihaz_siniri_24s', (select count(distinct user_id) from public.uye_cihaz_olay
                          where olay = 'sinir' and zaman > now() - interval '24 hours'),
    'kasa_tavan_24s',  (select count(distinct user_id) from public.kasa_cekim
                          where sayfa like 'TAVAN:%' and zaman > now() - interval '24 hours'),
    'kasa_asiri_24s',  (select count(*) from (
                          select user_id from public.kasa_cekim
                          where zaman > now() - interval '24 hours'
                          group by user_id having sum(coalesce(tekil, adet)) >= 2500) k),
    'kasa_cekim_24s',  (select coalesce(sum(adet),0) from public.kasa_cekim where zaman > now() - interval '24 hours'),
    'kasa_tekil_24s',  (select coalesce(sum(coalesce(tekil, adet)),0) from public.kasa_cekim where zaman > now() - interval '24 hours'),
    'olcum',           now()
  );
$function$
;

-- yeni_uye_paket_bagla()
CREATE OR REPLACE FUNCTION public.yeni_uye_paket_bagla()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  begin
    perform public.siparis_paket_bagla(new.id, new.email);
  exception when others then
    raise warning 'yeni_uye_paket_bagla: % (kayit engellenmedi)', sqlerrm;
  end;
  return new;
end $function$
;

-- yonetici_mi()
CREATE OR REPLACE FUNCTION public.yonetici_mi()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select auth.uid() is not null and exists (select 1 from public.yoneticiler where user_id = auth.uid());
$function$
;

-- yonetim_bagsiz_siparisler()
CREATE OR REPLACE FUNCTION public.yonetim_bagsiz_siparisler()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'no', s.siparis_no, 'odendi', s.odendi_tarihi, 'ad', s.ad_soyad, 'eposta', s.email, 'paket', s.paket,
             'paket_ad', s.paket_ad, 'tutar', s.tutar, 'odeme', s.odeme, 'bitis', s.paket_bitis,
             'hesap_var', exists (select 1 from auth.users u where lower(u.email) = lower(s.email)))
           order by s.odendi_tarihi desc nulls last)
      from public.siparisler s
     where s.durum = 'odendi' and s.bagli_kullanici is null
       and coalesce(s.paket_bitis, current_date) >= current_date
  ), '[]'::jsonb);
end $function$
;

-- yonetim_ders_hediye(text,text[],date,text,text,boolean)
CREATE OR REPLACE FUNCTION public.yonetim_ders_hediye(p_eposta text, p_dersler text[], p_bitis date, p_neden text, p_elci text DEFAULT NULL::text, p_zorla boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  tum_dersler constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi',
    'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  v_uid uuid; v_eski public.paket_uyeler%rowtype; v_var boolean; v_acik boolean; v_hediye boolean;
  v_yeni text[]; v_birlesik text[]; v_paket text; v_dersler text[]; v_bitis date; v_ucretli boolean := false; d text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_dersler is null or coalesce(array_length(p_dersler, 1), 0) = 0 then raise exception 'DERS_SEC'; end if;
  foreach d in array p_dersler loop
    if d is null or not (d = any (tum_dersler)) then raise exception 'DERS_GECERSIZ'; end if;
  end loop;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  if coalesce(length(trim(p_neden)), 0) < 2 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;

  -- tekilleştir, sitedeki ders sırasıyla
  select array_agg(x order by array_position(tum_dersler, x)) into v_yeni from (select distinct unnest(p_dersler) x) t;

  select * into v_eski from public.paket_uyeler where user_id = v_uid for update;
  v_var := found;   -- FOUND bir sonraki sorguda değişmesin diye hemen alınır
  v_acik := v_var and v_eski.bitis >= current_date;
  v_hediye := exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null);
  v_birlesik := v_yeni; v_bitis := p_bitis;

  if v_acik then
    if v_eski.paket in ('tam', 'yeterlilik-tum') then raise exception 'ZATEN_ACIK'; end if;
    if v_eski.paket !~ '^yeterlilik-[1-4]$' then raise exception 'BASKA_SINAV'; end if;   -- sgs, kgk-*
    v_ucretli := not v_hediye;
    if v_ucretli and not p_zorla then raise exception 'UCRETLI_DERS_VAR'; end if;
    select array_agg(x order by array_position(tum_dersler, x)) into v_birlesik
      from (select distinct unnest(coalesce(v_eski.dersler, array[]::text[]) || v_yeni) x) t;
    v_bitis := greatest(v_eski.bitis, p_bitis);
  end if;

  if array_length(v_birlesik, 1) >= 5 then
    v_paket := 'yeterlilik-tum'; v_dersler := null;
  else
    v_paket := 'yeterlilik-' || array_length(v_birlesik, 1); v_dersler := v_birlesik;
  end if;

  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (v_uid, v_paket, v_bitis, v_dersler)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = excluded.dersler;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren, dersler)
    values (v_uid, lower(trim(p_eposta)), v_paket, v_bitis, left(p_neden, 200),
            nullif(upper(trim(coalesce(p_elci, ''))), ''), 'yonetim', v_yeni);
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'paket', v_paket, 'bitis', v_bitis,
                            'verilen', to_jsonb(v_yeni), 'acik_dersler', to_jsonb(coalesce(v_dersler, tum_dersler)),
                            'ucretli_vardi', v_ucretli);
end $function$
;

-- yonetim_ekip_cevapla(bigint,text)
CREATE OR REPLACE FUNCTION public.yonetim_ekip_cevapla(p_id bigint, p_cevap text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if coalesce(length(trim(p_cevap)), 0) < 3 then raise exception 'CEVAP_KISA'; end if;
  update public.ekibe_soru set cevap = left(trim(p_cevap), 4000), durum = 'cevaplandi', cevap_tarih = now() where id = p_id;
  if not found then raise exception 'SORU_YOK'; end if;
  return jsonb_build_object('id', p_id, 'durum', 'cevaplandi');
end $function$
;

-- yonetim_ekip_hakli(bigint,boolean,text)
CREATE OR REPLACE FUNCTION public.yonetim_ekip_hakli(p_id bigint, p_hakli boolean, p_not text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.ekibe_soru
     set itiraz_hakli = p_hakli,
         itiraz_not = case when p_hakli then nullif(left(trim(coalesce(p_not, '')), 300), '') else null end
   where id = p_id;
  if not found then raise exception 'SORU_YOK'; end if;
  return jsonb_build_object('id', p_id, 'itiraz_hakli', p_hakli);
end $function$
;

-- yonetim_ekip_sorulari()
CREATE OR REPLACE FUNCTION public.yonetim_ekip_sorulari()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'eposta', eposta, 'soru_id', soru_id, 'soru_kisa', soru_kisa,
            'mesaj', mesaj, 'nobetci_cevap', nobetci_cevap, 'durum', durum, 'cevap', cevap, 'tarih', tarih, 'cevap_tarih', cevap_tarih,
            'cevap_mail', cevap_mail, 'cevap_goruldu', cevap_goruldu, 'itiraz_hakli', itiraz_hakli, 'itiraz_not', itiraz_not,
            'ret_aktarim', ret_aktarim, 'tesekkur_mail', tesekkur_mail)
            order by (durum = 'bekliyor') desc, tarih desc)
          from (select * from public.ekibe_soru order by tarih desc limit 300) x), '[]'::jsonb);
end $function$
;

-- yonetim_elci_bagi_coz(text)
CREATE OR REPLACE FUNCTION public.yonetim_elci_bagi_coz(p_kod text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.elciler set user_id = null where kod = upper(trim(coalesce(p_kod, '')));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'bagli', false);
end $function$
;

-- yonetim_elci_durum(text,boolean)
CREATE OR REPLACE FUNCTION public.yonetim_elci_durum(p_kod text, p_aktif boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.elciler set aktif = p_aktif where kod = upper(trim(p_kod));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'aktif', p_aktif);
end $function$
;

-- yonetim_elci_ekle(text,text,text,text,text)
CREATE OR REPLACE FUNCTION public.yonetim_elci_ekle(p_kod text, p_ad text, p_eposta text DEFAULT NULL::text, p_instagram text DEFAULT NULL::text, p_not text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_kod text := upper(trim(p_kod));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if v_kod !~ '^[A-Z0-9]{6,12}$' then raise exception 'KOD_GECERSIZ'; end if;   -- 04.10 Cem: 6 haneli
  if exists (select 1 from public.elciler where kod = v_kod) then raise exception 'KOD_VAR'; end if;
  insert into public.elciler (kod, ad_soyad, email, instagram, not_)
    values (v_kod, trim(p_ad), nullif(trim(coalesce(p_eposta, '')), ''), nullif(trim(coalesce(p_instagram, '')), ''), nullif(trim(coalesce(p_not, '')), ''));
  return jsonb_build_object('kod', v_kod);
end $function$
;

-- yonetim_elci_eposta_yaz(text,text)
CREATE OR REPLACE FUNCTION public.yonetim_elci_eposta_yaz(p_kod text, p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_ep text := nullif(lower(trim(coalesce(p_eposta, ''))), '');
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if v_ep is not null and v_ep !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'EPOSTA_GECERSIZ'; end if;
  if v_ep is not null and exists (select 1 from public.elciler where lower(email) = v_ep and kod <> upper(trim(p_kod))) then
    raise exception 'EPOSTA_BASKA_KODDA';
  end if;
  update public.elciler set email = v_ep where kod = upper(trim(coalesce(p_kod, '')));
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', upper(trim(p_kod)), 'eposta', v_ep);
end $function$
;

-- yonetim_elci_hesaba_bagla(text,text)
CREATE OR REPLACE FUNCTION public.yonetim_elci_hesaba_bagla(p_kod text, p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_kod text := upper(trim(coalesce(p_kod, ''))); v_uid uuid; v_baska text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if not exists (select 1 from public.elciler where kod = v_kod) then raise exception 'KOD_YOK'; end if;
  select u.id into v_uid from auth.users u where lower(u.email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  select kod into v_baska from public.elciler where user_id = v_uid and kod <> v_kod;
  if v_baska is not null then raise exception 'HESAP_BASKA_KODDA:%', v_baska; end if;
  update public.elciler
     set user_id = v_uid, bag_kodu_ozet = null, bag_kodu_son = null
   where kod = v_kod;
  return jsonb_build_object('kod', v_kod, 'eposta', lower(trim(p_eposta)));
end $function$
;

-- yonetim_elci_hesap_bul(text)
CREATE OR REPLACE FUNCTION public.yonetim_elci_hesap_bul(p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_id uuid; v_kayit timestamptz; v_son timestamptz; v_meta jsonb; v_kod text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select u.id, u.created_at, u.last_sign_in_at, coalesce(u.raw_app_meta_data, '{}'::jsonb)
    into v_id, v_kayit, v_son, v_meta
    from auth.users u
   where lower(u.email) = lower(trim(coalesce(p_eposta, '')))
   limit 1;
  if v_id is null then
    return jsonb_build_object('var', false);
  end if;
  select kod into v_kod from public.elciler where user_id = v_id;
  return jsonb_build_object(
    'var',        true,
    'saglayici',  coalesce(v_meta->'providers', jsonb_build_array(coalesce(v_meta->>'provider', 'email'))),
    'kayit',      v_kayit,
    'son_giris',  v_son,
    'bagli_kod',  v_kod
  );
end $function$
;

-- yonetim_elci_hesaplar()
CREATE OR REPLACE FUNCTION public.yonetim_elci_hesaplar()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kod', e.kod,
             'bagli', e.user_id is not null,
             'eposta', (select u.email from auth.users u where u.id = e.user_id),
             'kayitli_eposta', e.email,
             'instagram', e.instagram,
             'sozlesme', e.sozlesme_onay is not null,
             'sozlesme_surum', e.sozlesme_surum,
             'sozlesme_onay', e.sozlesme_onay,
             'ilk_onay', e.ilk_onay,
             'erisim_paket', p.paket,
             'erisim_bitis', p.bitis))
      from public.elciler e
      left join public.paket_uyeler p on p.user_id = e.user_id
  ), '[]'::jsonb);
end $function$
;

-- yonetim_eposta_onayla(text)
CREATE OR REPLACE FUNCTION public.yonetim_eposta_onayla(p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_uid uuid; v_onay timestamptz;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id, email_confirmed_at into v_uid, v_onay from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if v_onay is not null then
    return jsonb_build_object('eposta', lower(trim(p_eposta)), 'zaten', true, 'onay', v_onay);
  end if;
  update auth.users set email_confirmed_at = now(), updated_at = now() where id = v_uid;
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'zaten', false, 'onay', now());
end $function$
;

-- yonetim_hesap_bul(text)
CREATE OR REPLACE FUNCTION public.yonetim_hesap_bul(p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare u auth.users%rowtype; p public.paket_uyeler%rowtype;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into u from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if not found then return jsonb_build_object('var', false); end if;
  select * into p from public.paket_uyeler where user_id = u.id;
  return jsonb_build_object(
    'var', true, 'eposta', u.email,
    'saglayici', coalesce(u.raw_app_meta_data->'providers', jsonb_build_array(coalesce(u.raw_app_meta_data->>'provider', 'email'))),
    'ad', coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'ad', ''),
    'kayit', u.created_at, 'son_giris', u.last_sign_in_at, 'onayli', u.email_confirmed_at is not null,
    'paket', p.paket, 'bitis', p.bitis);
end $function$
;

-- yonetim_kaynak(integer)
CREATE OR REPLACE FUNCTION public.yonetim_kaynak(p_gun integer DEFAULT 60)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare bas date;
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;
  bas := (now() at time zone 'Europe/Istanbul')::date - least(greatest(coalesce(p_gun, 60), 1), 400);
  return coalesce((
    select jsonb_agg(jsonb_build_object('gun', t.gun, 'etiket', t.etiket, 'ziyaret', t.ziyaret, 'ornek', t.ornek, 'test', t.test, 'uye', t.uye)
                     order by t.gun desc, t.sira, t.ziyaret desc, t.etiket)
      from (
        select coalesce(s.gun, m.gun) as gun, coalesce(s.etiket, m.etiket) as etiket, 0 as sira,
               coalesce(s.ziyaret, 0) as ziyaret, coalesce(s.ornek, 0) as ornek, coalesce(s.test, 0) as test,
               coalesce(s.uye, 0) + coalesce(m.n, 0) as uye
          from (select s.gun, s.etiket,
                       coalesce(sum(s.adet) filter (where s.olay = 'ziyaret'), 0)::int as ziyaret,
                       coalesce(sum(s.adet) filter (where s.olay = 'ornek'), 0)::int   as ornek,
                       coalesce(sum(s.adet) filter (where s.olay = 'test'), 0)::int    as test,
                       coalesce(sum(s.adet) filter (where s.olay = 'uye'), 0)::int     as uye
                  from public.kaynak_sayac s
                 where s.gun >= bas
                 group by s.gun, s.etiket) s
          full outer join
               (select (u.created_at at time zone 'Europe/Istanbul')::date as gun,
                       public._kaynak_hesap_etiketi(u.raw_user_meta_data) as etiket, count(*)::int as n
                  from auth.users u
                 where u.created_at >= bas
                   and public._kaynak_hesap_etiketi(u.raw_user_meta_data) is not null
                   and not exists (select 1 from public.kaynak_uye_sayildi k where k.user_id = u.id)
                 group by 1, 2) m
            on m.gun = s.gun and m.etiket = s.etiket
        union all
        select (u.created_at at time zone 'Europe/Istanbul')::date, '(tüm yeni hesaplar)', 1, 0, 0, 0, count(*)::int
          from auth.users u
         where u.created_at >= bas
         group by 1
      ) t
  ), '[]'::jsonb);
end
$function$
;

-- yonetim_nobetci_ozet()
CREATE OR REPLACE FUNCTION public.yonetim_nobetci_ozet()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return jsonb_build_object(
    'bugun_soru', (select count(*) from public.nobetci_soru where tarih >= date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_soru',    (select count(*) from public.nobetci_soru where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_usd',     (select coalesce(sum(bedel_usd), 0) from public.nobetci_soru where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ort_usd',    (select coalesce(avg(bedel_usd), 0) from public.nobetci_soru where durum = 'cevaplandi'),
    'kisi',       (select count(distinct user_id) from public.nobetci_soru where tarih >= now() - interval '30 days'),
    'ekip_bekleyen', (select count(*) from public.ekibe_soru where durum = 'bekliyor'),
    'ekip_gec',      (select count(*) from public.ekibe_soru where durum = 'bekliyor' and tarih < now() - interval '24 hours'),
    'ekip_hakli',    (select count(*) from public.ekibe_soru where itiraz_hakli is true),
    'ekip_haksiz',   (select count(*) from public.ekibe_soru where itiraz_hakli is false),
    'ekip_toplam',   (select count(*) from public.ekibe_soru));
end $function$
;

-- yonetim_ozel_kod_iptal(text)
CREATE OR REPLACE FUNCTION public.yonetim_ozel_kod_iptal(p_kod text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_kod text := upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'));
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update ozel_kod set iptal = now() where kod = v_kod and iptal is null;
  if not found then raise exception 'KOD_YOK'; end if;
  return jsonb_build_object('kod', v_kod);
end $function$
;

-- yonetim_ozel_kod_uret(text,integer,integer)
CREATE OR REPLACE FUNCTION public.yonetim_ozel_kod_uret(p_kime text, p_gun integer, p_indirim integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  abc constant text := 'ACDEFHJKLMNPRTUVXYZ2345679';
  v_kod text; v_b bytea; i int; n int := 0; v_son timestamptz;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if length(btrim(coalesce(p_kime, ''))) not between 2 and 120 then raise exception 'KIME_GEREKLI'; end if;
  if coalesce(p_gun, 0) not between 1 and 90 then raise exception 'GUN_GECERSIZ'; end if;
  if coalesce(p_indirim, 0) not between 1 and 1000 then raise exception 'INDIRIM_GECERSIZ'; end if;
  loop
    n := n + 1;
    if n > 20 then raise exception 'KOD_URETILEMEDI'; end if;
    v_b := decode(replace(gen_random_uuid()::text, '-', ''), 'hex');
    v_kod := 'OZ';
    for i in 0..5 loop
      v_kod := v_kod || substr(abc, (get_byte(v_b, i) % length(abc)) + 1, 1);
    end loop;
    exit when not exists (select 1 from ozel_kod where kod = v_kod)
          and not exists (select 1 from elciler where kod = v_kod);
  end loop;
  v_son := date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'
           + make_interval(days => p_gun + 1) - interval '1 second';   -- son günün 23:59:59'u (TR)
  insert into ozel_kod (kod, indirim_tl, paketler, son, kime, olusturan)
  values (v_kod, p_indirim, array['sgs', 'yeterlilik-tum'], v_son, btrim(p_kime), auth.uid());
  return jsonb_build_object('kod', v_kod, 'indirim_tl', p_indirim, 'paketler', array['sgs', 'yeterlilik-tum'], 'son', v_son, 'kime', btrim(p_kime));
end $function$
;

-- yonetim_ozel_kod_uret2(text,integer,jsonb,text)
CREATE OR REPLACE FUNCTION public.yonetim_ozel_kod_uret2(p_kime text, p_gun integer, p_indirim jsonb, p_aciklama text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  abc constant text := 'ACDEFHJKLMNPRTUVXYZ2345679';
  izinli constant text[] := array['sgs', 'yeterlilik-tum', 'yeterlilik-1', 'yeterlilik-2', 'yeterlilik-3', 'yeterlilik-4'];
  v_kod text; v_b bytea; i int; n int := 0; v_son timestamptz;
  v_paketler text[]; v_en integer := 0; k text; v text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if length(btrim(coalesce(p_kime, ''))) not between 2 and 120 then raise exception 'KIME_GEREKLI'; end if;
  if coalesce(p_gun, 0) not between 1 and 90 then raise exception 'GUN_GECERSIZ'; end if;
  if p_indirim is null or jsonb_typeof(p_indirim) <> 'object' or p_indirim = '{}'::jsonb then raise exception 'PAKET_GECERSIZ'; end if;
  for k, v in select key, value::text from jsonb_each(p_indirim) loop
    if not (k = any (izinli)) then raise exception 'PAKET_GECERSIZ'; end if;
    if v !~ '^[0-9]{1,4}$' then raise exception 'INDIRIM_GECERSIZ'; end if;   -- önce biçim: '"12.5"'::int hata fırlatmasın
    if v::int not between 1 and 5000 then raise exception 'INDIRIM_GECERSIZ'; end if;
    v_paketler := array_append(v_paketler, k);
    v_en := greatest(v_en, v::int);
  end loop;
  loop
    n := n + 1;
    if n > 20 then raise exception 'KOD_URETILEMEDI'; end if;
    v_b := decode(replace(gen_random_uuid()::text, '-', ''), 'hex');
    v_kod := 'OZ';
    for i in 0..5 loop
      v_kod := v_kod || substr(abc, (get_byte(v_b, i) % length(abc)) + 1, 1);
    end loop;
    exit when not exists (select 1 from ozel_kod where kod = v_kod)
          and not exists (select 1 from elciler where kod = v_kod);
  end loop;
  v_son := date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'
           + make_interval(days => p_gun + 1) - interval '1 second';   -- son günün 23:59:59'u (TR)
  insert into ozel_kod (kod, indirim_tl, paketler, son, kime, olusturan, indirim_paket, aciklama)
  values (v_kod, v_en, v_paketler, v_son, btrim(p_kime), auth.uid(), p_indirim, nullif(left(btrim(coalesce(p_aciklama, '')), 40), ''));
  return jsonb_build_object('kod', v_kod, 'indirim_paket', p_indirim, 'son', v_son, 'kime', btrim(p_kime),
                            'aciklama', nullif(left(btrim(coalesce(p_aciklama, '')), 40), ''));
end $function$
;

-- yonetim_ozel_kodlar()
CREATE OR REPLACE FUNCTION public.yonetim_ozel_kodlar()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'kod', o.kod, 'kime', o.kime, 'indirim_tl', o.indirim_tl, 'paketler', o.paketler, 'son', o.son,
             'indirim_paket', coalesce(o.indirim_paket, (select jsonb_object_agg(p, o.indirim_tl) from unnest(o.paketler) p)),
             'aciklama', o.aciklama,
             'olusturma', o.olusturma, 'kullanildi', o.kullanildi, 'siparis_no', o.siparis_no, 'iptal', o.iptal,
             'siparis_durum', (select s.durum from siparisler s where s.siparis_no = o.siparis_no),
             'siparis_paket', (select s.paket from siparisler s where s.siparis_no = o.siparis_no),
             'gecerli', public._ozel_kod_gecerli(o.kod, o.paketler[1]) is not null
           ) order by o.olusturma desc)
      from ozel_kod o
     where o.olusturma > now() - interval '180 days'
  ), '[]'::jsonb);
end $function$
;

-- yonetim_ozet()
CREATE OR REPLACE FUNCTION public.yonetim_ozet()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
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
        'elci', s.elci_kodu, 'indirim', s.indirim_tl, 'anlik_teklif', s.anlik_teklif_tl,
        'ozel_kod', s.ozel_kod, 'ozel_kod_tl', s.ozel_kod_tl,
        'indirim_kaynak', s.indirim_kaynak, 'kaynak_etiket', s.kaynak_etiket,
        'ad', s.ad_soyad, 'eposta', s.email,
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
$function$
;

-- yonetim_paket_kapat(text,text,boolean)
CREATE OR REPLACE FUNCTION public.yonetim_paket_kapat(p_eposta text, p_neden text, p_zorla boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_uid uuid;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if not exists (select 1 from public.paket_uyeler where user_id = v_uid) then raise exception 'PAKET_YOK'; end if;
  if not exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null) and not p_zorla then
    raise exception 'HEDIYE_DEGIL';   -- parayla alınmış olabilir; bilerek kapatmak için p_zorla
  end if;
  update public.paket_uyeler set bitis = current_date - 1 where user_id = v_uid;
  update public.paket_hediye set iptal = now(), neden = left('İPTAL: ' || coalesce(p_neden, ''), 200)
   where user_id = v_uid and iptal is null;
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'kapandi', current_date - 1);
end $function$
;

-- yonetim_paket_ver(text,text,date,text,text,boolean)
CREATE OR REPLACE FUNCTION public.yonetim_paket_ver(p_eposta text, p_paket text, p_bitis date, p_neden text, p_elci text DEFAULT NULL::text, p_zorla boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare v_uid uuid; v_eski public.paket_uyeler%rowtype; v_hediye boolean; v_var boolean;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_paket not in ('tam', 'sgs', 'yeterlilik-tum') then raise exception 'PAKET_GECERSIZ'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  if coalesce(length(trim(p_neden)), 0) < 2 then raise exception 'NEDEN_GEREKLI'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_eposta)) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  select * into v_eski from public.paket_uyeler where user_id = v_uid;
  v_var := found;   -- FOUND bir sonraki sorguda değişmesin diye hemen alınır
  v_hediye := exists (select 1 from public.paket_hediye where user_id = v_uid and iptal is null);
  if v_var and v_eski.bitis >= current_date and not v_hediye and not p_zorla then raise exception 'AKTIF_PAKET_VAR'; end if;
  insert into public.paket_uyeler (user_id, paket, bitis, dersler) values (v_uid, p_paket, p_bitis, null)
    on conflict (user_id) do update set paket = excluded.paket, bitis = excluded.bitis, dersler = null;
  insert into public.paket_hediye (user_id, eposta, paket, bitis, neden, elci_kodu, veren)
    values (v_uid, lower(trim(p_eposta)), p_paket, p_bitis, left(p_neden, 200), nullif(upper(trim(coalesce(p_elci, ''))), ''), 'yonetim');
  return jsonb_build_object('eposta', lower(trim(p_eposta)), 'paket', p_paket, 'bitis', p_bitis);
end $function$
;

-- yonetim_siparis_hesaba_bagla(text,text)
CREATE OR REPLACE FUNCTION public.yonetim_siparis_hesaba_bagla(p_no text, p_eposta text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid; v_ep text; p public.paket_uyeler%rowtype; v_sonuc text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = trim(coalesce(p_no, ''));
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odendi' then raise exception 'DURUM_%', upper(s.durum); end if;
  select id, email into v_uid, v_ep from auth.users where lower(email) = lower(trim(coalesce(p_eposta, ''))) limit 1;
  if v_uid is null then raise exception 'HESAP_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> v_uid then raise exception 'BASKA_HESAPTA'; end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  if found and p.bitis >= current_date and p.paket <> s.paket then raise exception 'AKTIF_PAKET_VAR'; end if;
  v_sonuc := public._siparis_isle(s.id, v_uid, 'yonetim');
  if v_sonuc not in ('ACILDI', 'ZATEN_ACIK') then raise exception '%', v_sonuc; end if;
  select * into p from public.paket_uyeler where user_id = v_uid;
  return jsonb_build_object('no', s.siparis_no, 'eposta', v_ep, 'paket', p.paket, 'bitis', p.bitis, 'sonuc', v_sonuc);
end $function$
;

-- yonetim_siparis_iade(text,text)
CREATE OR REPLACE FUNCTION public.yonetim_siparis_iade(p_no text, p_neden text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid; v_kapandi boolean := false;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odendi' then raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'iade' where id = s.id;

  v_uid := s.bagli_kullanici;
  if v_uid is null then select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1; end if;
  if v_uid is not null then
    update public.paket_uyeler set bitis = current_date - 1
     where user_id = v_uid and paket = s.paket and bitis >= current_date;
    v_kapandi := found;
  end if;
  return jsonb_build_object('siparis', 'iade', 'eposta', s.email, 'odeme', s.odeme, 'elci', s.elci_kodu,
                            'paket_kapandi', v_kapandi, 'neden', left(coalesce(p_neden, ''), 200));
end $function$
;

-- yonetim_siparis_iptal(text,text)
CREATE OR REPLACE FUNCTION public.yonetim_siparis_iptal(p_no text, p_neden text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.siparisler%rowtype;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;
  update public.siparisler set durum = 'iptal' where id = s.id;
  return jsonb_build_object('siparis', 'iptal');
end $function$
;

-- yonetim_siparis_onayla(text,date)
CREATE OR REPLACE FUNCTION public.yonetim_siparis_onayla(p_no text, p_bitis date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid; v_sonuc text;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  if s.durum <> 'odeme_bekliyor' then raise exception 'DURUM_%', upper(s.durum); end if;

  update public.siparisler set durum = 'odendi', paket_bitis = p_bitis where id = s.id;   -- odendi_tarihi tetikleyicide

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'BEKLIYOR', 'eposta', s.email,
      'not', s.email || ' henüz üye değil. Bu e-postayla üye olduğu anda paketi KENDİLİĞİNDEN açılır.');
  end if;
  v_sonuc := public.siparis_paket_bagla(v_uid, s.email);
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', p_bitis, 'eposta', s.email, 'sonuc', v_sonuc);
end $function$
;

-- yonetim_soru_getir(text)
CREATE OR REPLACE FUNCTION public.yonetim_soru_getir(p_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v jsonb;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select jsonb_build_object('id', id, 'sinav', sinav, 'ders', ders, 'konu', konu, 'sayfa', sayfa,
           'soru', veri->'soru', 'siklar', veri->'siklar', 'dogru', veri->'dogru', 'sade', veri->'sade',
           'teshis', veri->'teshis', 'dayanak', veri->'dayanak')
    into v from public.paket_soru where id = p_id;
  return v;   -- kasada yoksa null (soru yayından kalkmış ya da kimlik eski)
end $function$
;

