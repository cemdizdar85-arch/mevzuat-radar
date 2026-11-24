-- ============================================================================
--  ÖZEL İNDİRİM KODU SGS 2027'DE DE GEÇER (24.11.2026, site kolu; Cem "bunları yapalım hem sgs hem de bitirme ile ilgili")
--
--  NE YAPAR: yonetim_ozel_kod_uret2 izinli paket listesine 'sgs-2027' eklenir. Gövdenin geri kalanı canlı tanımla
--  (radar-app/canli-sema/fonksiyonlar.sql) AYNI. Yeterlilik paketleri (yeterlilik-1..4, yeterlilik-tum) listede zaten vardı.
--  Kodun siparişe işlenmesi (siparis_teklif_damga -> _ozel_kod_gecerli) ve ödeme tutarı (iyzico-odeme.ts: taban - ozel_kod_tl)
--  paket adından bağımsız; onlara dokunulmadı.
--  ELÇİ KODU DEĞİŞMEDİ: SGS 2027'de elçi indirimi yok (Cem 23.11); bu göç yalnız yöneticinin ürettiği özel kodu açar.
--  YETKİ: create or replace mevcut yetkileri korur (yalnız authenticated; içeride yonetici_mi()). acik-rpc.txt satırı var.
--  GÖRMEZ: kodun gerçek kartla ödemede uçtan uca çalışması (öz-sınav yalnız geçerlilik fonksiyonunu ölçer).
-- ============================================================================
CREATE OR REPLACE FUNCTION public.yonetim_ozel_kod_uret2(p_kime text, p_gun integer, p_indirim jsonb, p_aciklama text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  abc constant text := 'ACDEFHJKLMNPRTUVXYZ2345679';
  izinli constant text[] := array['sgs', 'sgs-2027', 'yeterlilik-tum', 'yeterlilik-1', 'yeterlilik-2', 'yeterlilik-3', 'yeterlilik-4'];
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
end $function$;

-- ÖZ-SINAV (iz bırakmaz): (a) tanımda sgs-2027 var · (b) sgs-2027'ye açılmış kod sgs-2027'de tutarını döner ·
-- (c) aynı kod listesinde olmayan pakette (yeterlilik-tum) null · (d) son20-sgs'de null (02.11 kuralı)
do $olcu$
declare n int := 0; v int; y uuid;
begin
  if position('''sgs-2027''' in pg_get_functiondef('public.yonetim_ozel_kod_uret2(text,integer,jsonb,text)'::regprocedure)) = 0 then
    raise exception 'OLCU: a tanimda sgs-2027 yok';
  end if;
  n := n + 1;
  select user_id into y from public.yoneticiler limit 1;
  begin
    insert into public.ozel_kod (kod, indirim_tl, paketler, son, kime, olusturan, indirim_paket, aciklama)
    values ('OZACDEFH', 300, array['sgs-2027'], now() + interval '1 day', 'OLCU', y, jsonb_build_object('sgs-2027', 300), 'olcu');
    v := public._ozel_kod_gecerli('OZACDEFH', 'sgs-2027');
    if v is distinct from 300 then raise exception 'OLCU: b %', v; end if;
    n := n + 1;
    v := public._ozel_kod_gecerli('OZACDEFH', 'yeterlilik-tum');
    if v is not null then raise exception 'OLCU: c %', v; end if;
    n := n + 1;
    v := public._ozel_kod_gecerli('OZACDEFH', 'son20-sgs');
    if v is not null then raise exception 'OLCU: d %', v; end if;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.ozel_kod where kod = 'OZACDEFH') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'OZEL KOD SGS2027 OZ-SINAV: % vaka TAMAM', n;
end $olcu$;
