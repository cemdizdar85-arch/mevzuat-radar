-- ============================================================================
--  MARKA NÖBETİ E-POSTA ONAYI  ·  28.10.2026 (marka kolu; Cem → site oturumu "1 ve 2'yi yap")
--
--  NEDEN (28.10 okundu, veri/sql-marka-takip.sql + canlı tanım):
--   1) Çift onay YOKTU: herkes başkasının e-postasına nöbet açıp robotun uyarı maillerini o adrese yağdırabiliyordu
--      (adres başına 25 tavanı vardı) → alan adının mail itibarı da yanardı.
--   2) Aynı marka + aynı e-postayla yeniden kayıt, mevcut nöbetin YÖNETİM JETONUNU sayfaya geri veriyordu → adresi
--      bilen, başkasının nöbetini kapatabiliyordu.
--  YENİ DÜZEN:
--   · Nöbet açma yalnız edge 'marka-nobet' üzerinden (servis anahtarı): marka_takip_ac2 → onay jetonu üretir, edge
--     kurumsal kabuklu onay maili yollar. Yönetim jetonu sayfaya DÖNMEZ.
--   · Onay bağlantısı TEK KULLANIMLIK + 48 SAAT: marka_takip_onayla(p_onay) — kullanılınca onay_jeton silinir.
--   · Robot (marka_takip_bekleyen) yalnız ONAYLI nöbete uyarı üretir.
--   · Aynı adrese 10 dakikada en çok 1 onay maili (BEKLE); onaylı açık nöbet yeniden istenirse mail YOK (ZATEN_ACIK).
--   · Kapatılmış nöbet yeniden açılırsa yeniden onay ister.
--   · Bugün AÇIK nöbetler onaylı sayılır (onaylandi = olusma) — kimse nöbetini kaybetmez. Sayısı NOTICE'ta.
--  ESKİ marka_takip_ac: anon/üyeye kapatılır (silinmez; geri dönüş = grant). Sayfa aynı commit'te edge'e geçer.
--  🚫 GÖRMEZ: onay mailinin kutuya varması (Resend/teslim ölçümü ayrı) · aynı kişinin farklı adreslerle açtığı nöbetler.
-- ============================================================================

alter table public.marka_takip add column if not exists onaylandi     timestamptz;
alter table public.marka_takip add column if not exists onay_jeton    text;
alter table public.marka_takip add column if not exists onay_son      timestamptz;
alter table public.marka_takip add column if not exists onay_gonderim timestamptz;
create unique index if not exists ux_mt_onay_jeton on public.marka_takip (onay_jeton) where onay_jeton is not null;

do $$
declare n int;
begin
  update public.marka_takip set onaylandi = coalesce(olusma, now()) where aktif and onaylandi is null;
  get diagnostics n = row_count;
  raise notice 'MARKA NOBET ONAY: bugun acik % nobet onayli sayildi (toplam satir %, aktif olmayan %)', n,
    (select count(*) from public.marka_takip), (select count(*) from public.marka_takip where not aktif);
end $$;

-- (a) Nöbet aç / tazele — YALNIZ servis (edge marka-nobet). Döner: durum + (gerekirse) onay jetonu. Yönetim jetonu DÖNMEZ.
create or replace function public.marka_takip_ac2(p_ad text, p_sinif int[], p_eposta text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
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
end; $$;

-- (b) Onay bağlantısı: tek kullanımlık, 48 saat. Anon çağırır (48 haneli jeton olmadan hiçbir şey yapmaz).
create or replace function public.marka_takip_onayla(p_onay text)
returns jsonb
language plpgsql security definer set search_path = public as $$
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
end; $$;

-- (c) Robot: yalnız ONAYLI nöbet. Tanım canlıdan (radar-app/canli-sema/fonksiyonlar.sql 28.10), tek fark "and t.onaylandi is not null".
create or replace function public.marka_takip_bekleyen(p_tavan integer default 500)
 returns table(takip_id uuid, eposta text, jeton text, takip_ad text, takip_sinif integer[], basvuru_no text, bulten_no integer, ad text, sahip text, sinif integer[], yayin_tarihi date, itiraz_son date, kalan_gun integer, benzerlik real, ayni_sinif boolean, kademe text, sebep text, tur text, hatirlatma integer)
 language sql security definer set search_path to 'public', 'extensions'
as $function$
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
$function$;

revoke execute on function public.marka_takip_ac(text, integer[], text) from public, anon, authenticated;
revoke execute on function public.marka_takip_ac2(text, integer[], text) from public, anon, authenticated;
grant  execute on function public.marka_takip_ac2(text, integer[], text) to service_role;
revoke execute on function public.marka_takip_onayla(text) from public;
grant  execute on function public.marka_takip_onayla(text) to anon, authenticated, service_role;
revoke execute on function public.marka_takip_bekleyen(integer) from public, anon, authenticated;
grant  execute on function public.marka_takip_bekleyen(integer) to service_role;

-- ÖZ-SINAV (ölçü satırları sonda silinir)
do $$
declare n int := 0; j jsonb; oj text; mj text; e constant text := 'olcu-marka-onay@tetikte.invalid'; v_id uuid;
begin
  delete from public.marka_takip where eposta = e;
  -- yetkiler
  if has_function_privilege('anon', 'public.marka_takip_ac(text, integer[], text)', 'execute') then raise exception 'OLCU: eski marka_takip_ac anon acik'; end if;
  if has_function_privilege('anon', 'public.marka_takip_ac2(text, integer[], text)', 'execute') then raise exception 'OLCU: ac2 anon acik'; end if;
  if not has_function_privilege('anon', 'public.marka_takip_onayla(text)', 'execute') then raise exception 'OLCU: onayla anon kapali (bag calismaz)'; end if;
  if has_function_privilege('anon', 'public.marka_takip_bekleyen(integer)', 'execute') then raise exception 'OLCU: bekleyen anon acik (e-posta listesi)'; end if;
  n := 4;
  -- 1 yeni kayıt: onay jetonu döner, nöbet KAPALI + onaysız
  j := public.marka_takip_ac2('Olcu Markasi Zq', '{9}', e);
  if j->>'durum' <> 'ONAY_GONDER' or length(j->>'onay') <> 48 or j ? 'jeton' then raise exception 'OLCU1: %', j; end if;
  oj := j->>'onay';
  select id into v_id from public.marka_takip where eposta = e;
  if (select aktif or onaylandi is not null from public.marka_takip where id = v_id) then raise exception 'OLCU1b: onaysiz nobet acik'; end if;
  n := n + 2;
  -- 2 robot onaysız nöbeti görmez (tanımda şart var mı)
  if position('t.onaylandi is not null' in pg_get_functiondef('public.marka_takip_bekleyen(integer)'::regprocedure)) = 0 then raise exception 'OLCU2: robot onay sarti yok'; end if;
  n := n + 1;
  -- 3 10 dakika içinde ikinci istek: BEKLE (mail yok)
  j := public.marka_takip_ac2('Olcu Markasi Zq', '{9}', e);
  if j->>'durum' <> 'BEKLE' then raise exception 'OLCU3: %', j; end if;
  n := n + 1;
  -- 4 bozuk / yanlış jeton
  if public.marka_takip_onayla('xyz')->>'durum' <> 'GECERSIZ' then raise exception 'OLCU4a'; end if;
  if public.marka_takip_onayla(repeat('0', 48))->>'durum' <> 'GECERSIZ' then raise exception 'OLCU4b'; end if;
  n := n + 2;
  -- 5 doğru jeton: ONAYLANDI + yönetim jetonu döner + nöbet açık
  j := public.marka_takip_onayla(oj);
  if j->>'durum' <> 'ONAYLANDI' or length(j->>'jeton') <> 48 then raise exception 'OLCU5: %', j; end if;
  if not (select aktif and onaylandi is not null from public.marka_takip where id = v_id) then raise exception 'OLCU5b: onayli nobet acik degil'; end if;
  n := n + 2;
  -- 6 tek kullanımlık
  if public.marka_takip_onayla(oj)->>'durum' <> 'GECERSIZ' then raise exception 'OLCU6: jeton ikinci kez calisti'; end if;
  n := n + 1;
  -- 7 onaylı açık nöbet yeniden istenir: ZATEN_ACIK, mail yok, jeton yok
  j := public.marka_takip_ac2('OLCU markası zq', '{9}', upper(e));
  if j->>'durum' <> 'ZATEN_ACIK' or j ? 'onay' or j ? 'jeton' then raise exception 'OLCU7: %', j; end if;
  n := n + 1;
  -- 8 süresi dolmuş jeton
  update public.marka_takip set aktif = false, onaylandi = null, onay_gonderim = now() - interval '1 hour' where id = v_id;
  j := public.marka_takip_ac2('Olcu Markasi Zq', '{9}', e);
  if j->>'durum' <> 'ONAY_GONDER' then raise exception 'OLCU8a (kapali nobet yeniden onay istemeli): %', j; end if;
  update public.marka_takip set onay_son = now() - interval '1 minute' where id = v_id;
  if public.marka_takip_onayla(j->>'onay')->>'durum' <> 'SURESI_DOLDU' then raise exception 'OLCU8b'; end if;
  if (select aktif from public.marka_takip where id = v_id) then raise exception 'OLCU8c: suresi dolan jeton nobeti acti'; end if;
  n := n + 3;
  -- 9 geçersiz girdiler
  if public.marka_takip_ac2('x', null, e)->>'durum' <> 'AD_GECERSIZ' then raise exception 'OLCU9a'; end if;
  if public.marka_takip_ac2('Olcu', null, 'bozuk')->>'durum' <> 'EPOSTA_GECERSIZ' then raise exception 'OLCU9b'; end if;
  n := n + 2;
  delete from public.marka_takip where eposta = e;
  raise notice 'MARKA NOBET ONAY OZ-SINAV: % vaka TAMAM', n;
end $$;
