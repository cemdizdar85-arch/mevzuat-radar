-- ============================================================================
--  ÖZEL İNDİRİM KODU 2 — paket başına tutar (TL ya da oran) + paket seçimi  ·  19.10.2026
--
--  KARAR (Cem 19.10, ilk göçten sonra): "sadece 600 TL değil, istediğim kadar verebileyim, oranı ben belirleyeyim,
--  tek ders olabilir tam alımda olabilir, kod üretsin oradan".
--
--  TASARIM:
--    - Kod artık PAKET BAŞINA tutar taşır: ozel_kod.indirim_paket = {"sgs": 598, "yeterlilik-1": 238, ...} (TL, KDV dahil).
--      Oranlı kodda yüzdeyi TL'ye panel çevirir (yonetim.html, fiyat-motoru.js'teki o günkü fiyattan) ve TL yazılır:
--      sunucuda fiyat tablosu yok (fiyat tek kaynak fiyat-motoru.js); damga ve iyzico denetimi yine TL ile çalışır,
--      iyzico-odeme.ts DEĞİŞMEZ. Üretici yöneticidir; panelin hesabına güvenmek elçi/teklif ilkesini bozmaz
--      (alıcının tarayıcısından hiçbir şey güvenlik değildir, yöneticinin paneli kendi yetkisidir).
--      ozel_kod.aciklama panelde ne seçildiğini yazar ("%20" / "600 TL").
--    - Seçilebilen paketler: Staja Giriş, Yeterlilik tüm dersler, Yeterlilik 1/2/3/4 ders (kartla satılan paketlerin hepsi).
--    - İlk göçün kodları (indirim_paket boş) aynen çalışır: paketler + indirim_tl.
--    - Tavan paket başına 5.000 TL (siparisler.ozel_kod_tl ile aynı); "fiyattan küçük" şartını panel sınar.
--
--  🚫 GÖRMEZ: oranlı kodda fiyat sonradan değişirse tutar ÜRETİM GÜNÜNÜN fiyatından kalır (kod kısa ömürlü, panel son günü yazar) ·
--     panelin yanlış fiyattan çevirmesi (yönetici gördüğü tabloyu onaylar).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: 2026-10-19-ozel-indirim-kodu.sql'deki _ozel_kod_gecerli + yonetim_ozel_kodlar yeniden basılır;
--             drop function yonetim_ozel_kod_uret2 (kolonlar kayıt olarak kalır).
-- ============================================================================

-- 1) KOLONLAR + tavan
alter table public.ozel_kod add column if not exists indirim_paket jsonb;
alter table public.ozel_kod add column if not exists aciklama text check (aciklama is null or length(aciklama) <= 40);
do $$
declare c text;
begin
  for c in select conname from pg_constraint
            where conrelid = 'public.ozel_kod'::regclass and contype = 'c'
              and pg_get_constraintdef(oid) like '%indirim_tl%' loop
    execute format('alter table public.ozel_kod drop constraint %I', c);
  end loop;
  alter table public.ozel_kod add constraint ozel_kod_indirim_tl_aralik check (indirim_tl between 1 and 5000);
end $$;

-- 2) GEÇERLİLİK — paket başına tutar varsa o, yoksa (ilk göçün kodu) indirim_tl
create or replace function public._ozel_kod_gecerli(p_kod text, p_paket text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select case when o.indirim_paket is not null then (o.indirim_paket ->> p_paket)::int else o.indirim_tl end
    from ozel_kod o
   where o.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
     and o.iptal is null
     and o.son > now()
     and p_paket = any (o.paketler)
     and (o.indirim_paket is null or (o.indirim_paket ->> p_paket) is not null)
     and (o.kullanildi is null
          or not exists (select 1 from siparisler s where s.siparis_no = o.siparis_no and s.durum <> 'iptal'));
$$;
revoke all on function public._ozel_kod_gecerli(text, text) from public, anon, authenticated;

-- 3) ÜRET — paket başına TL
create or replace function public.yonetim_ozel_kod_uret2(p_kime text, p_gun integer, p_indirim jsonb, p_aciklama text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
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
end $$;
revoke all on function public.yonetim_ozel_kod_uret2(text, integer, jsonb, text) from public, anon;
grant execute on function public.yonetim_ozel_kod_uret2(text, integer, jsonb, text) to authenticated;

-- 4) LİSTE — + indirim_paket, aciklama
create or replace function public.yonetim_ozel_kodlar()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
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
end $$;
revoke all on function public.yonetim_ozel_kodlar() from public, anon;
grant execute on function public.yonetim_ozel_kodlar() to authenticated;

-- 5) GÖÇ İÇİ ÖZ-SINAV (geri alınır). Y = deneme yöneticisi, A = alıcı, B = deneme elçisi.
do $$
declare
  a constant text := '00000000-0000-4000-8000-0000000000a1';
  y constant text := '00000000-0000-4000-8000-0000000000c3';
  b constant text := '00000000-0000-4000-8000-0000000000b2';
  kim text := 'ZZOZK2';
  k1 jsonb; k2 jsonb; r record; l jsonb; n int := 0;
  kod1 text; kod2 text;
begin
  begin
    insert into public.yoneticiler (user_id) values (y::uuid) on conflict do nothing;
    insert into public.elciler (kod, ad_soyad, aktif, ilk_onay, user_id) values (kim, 'DENEME Elci', false, now() - interval '10 days', b::uuid);
    update public.elciler set aktif = true where kod = kim;

    -- 1) yönetici olmayan üretemez
    perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a, true);
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 7, '{"sgs":598}', '%20'); raise exception 'OLCU4: yonetici olmayan uretti';
    exception when others then if sqlerrm not like '%YETKI_YOK%' then raise; end if; end;
    n := n + 1;

    -- 2) paket başına tutarla üret (oranlı kodun panel çıktısı gibi): SGS 598 · tek ders 238
    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y, true);
    k1 := public.yonetim_ozel_kod_uret2('DENEME Oran', 5, '{"sgs":598,"yeterlilik-1":238}', '%20');
    kod1 := k1->>'kod';
    if kod1 !~ '^OZ[ACDEFHJKLMNPRTUVXYZ2345679]{6}$' or k1->>'aciklama' <> '%20' then raise exception 'OLCU4: uretim yanlis %', k1; end if;
    -- yanlış girişler
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 5, '{"kgk-1":100}', null); raise exception 'OLCU4: izinsiz paket kabul edildi';
    exception when others then if sqlerrm not like '%PAKET_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 5, '{}', null); raise exception 'OLCU4: bos paket kabul edildi';
    exception when others then if sqlerrm not like '%PAKET_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 5, '{"sgs":0}', null); raise exception 'OLCU4: 0 TL kabul edildi';
    exception when others then if sqlerrm not like '%INDIRIM_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 5, '{"sgs":5001}', null); raise exception 'OLCU4: tavan asildi';
    exception when others then if sqlerrm not like '%INDIRIM_GECERSIZ%' then raise; end if; end;
    begin perform public.yonetim_ozel_kod_uret2('DENEME', 5, '{"sgs":"12.5"}', null); raise exception 'OLCU4: kesirli kabul edildi';
    exception when others then if sqlerrm not like '%INDIRIM_GECERSIZ%' then raise; end if; end;
    n := n + 6;

    -- 3) kontrol paket başına: sgs 598, tek ders 238, seçilmeyen paket 0
    if public.ozel_kod_kontrol(kod1, 'sgs') <> 598 or public.ozel_kod_kontrol(kod1, 'yeterlilik-1') <> 238 then raise exception 'OLCU4: paket basina tutar donmedi'; end if;
    if public.ozel_kod_kontrol(kod1, 'yeterlilik-tum') <> 0 or public.ozel_kod_kontrol(kod1, 'yeterlilik-2') <> 0 then raise exception 'OLCU4: secilmeyen pakette gecti'; end if;
    n := n + 2;

    -- 4) tek ders siparişi + elçi kodu (50 TL): özel 238 kazanır
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    insert into public.siparisler (siparis_no, paket, tutar, secilen_dersler, ad_soyad, email, elci_kodu, ozel_kod)
    values ('TT-20261019-ZMAA', 'yeterlilik-1', 950, array['Hukuk'], 'DENEME', 'deneme@tetikte.invalid', kim, kod1);
    select * into r from public.siparisler where siparis_no = 'TT-20261019-ZMAA';
    if r.ozel_kod_tl <> 238 or r.elci_kodu is not null or r.indirim_tl <> 0 or r.indirim_kaynak <> 'ozel:' || kod1 then
      raise exception 'OLCU4: tek ders damgasi yanlis ozel=% elci=% ind=%', r.ozel_kod_tl, r.elci_kodu, r.indirim_tl;
    end if;
    -- tek kullanım: aynı kod SGS'de de artık geçmez
    if public.ozel_kod_kontrol(kod1, 'sgs') <> 0 then raise exception 'OLCU4: kullanilan kod baska pakette gecti'; end if;
    n := n + 2;

    -- 5) ilk göçün kodu (indirim_paket boş) aynen çalışır
    perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', y, true);
    k2 := public.yonetim_ozel_kod_uret('DENEME Eski', 7, 600);
    kod2 := k2->>'kod';
    if public.ozel_kod_kontrol(kod2, 'sgs') <> 600 or public.ozel_kod_kontrol(kod2, 'yeterlilik-tum') <> 600 or public.ozel_kod_kontrol(kod2, 'yeterlilik-1') <> 0 then
      raise exception 'OLCU4: eski kod bozuldu';
    end if;
    n := n + 1;

    -- 6) liste: paket başına tutar + açıklama; eski kod için tutar tablodan türetilir
    l := public.yonetim_ozel_kodlar();
    if not (l @> jsonb_build_array(jsonb_build_object('kod', kod1, 'aciklama', '%20', 'indirim_paket', '{"sgs":598,"yeterlilik-1":238}'::jsonb, 'siparis_no', 'TT-20261019-ZMAA'))) then
      raise exception 'OLCU4: liste oranli kodu tasimiyor';
    end if;
    if not (l @> jsonb_build_array(jsonb_build_object('kod', kod2, 'indirim_paket', '{"sgs":600,"yeterlilik-tum":600}'::jsonb, 'gecerli', true))) then
      raise exception 'OLCU4: liste eski kodu tasimiyor';
    end if;
    n := n + 2;

    raise exception 'OLCU4_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU4_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261019-ZM%')
     or exists (select 1 from public.ozel_kod where kod in (kod1, kod2))
     or exists (select 1 from public.elciler where kod = 'ZZOZK2')
     or exists (select 1 from public.yoneticiler where user_id = '00000000-0000-4000-8000-0000000000c3') then
    raise exception 'OLCU4: geri alma iz birakti';
  end if;
  raise notice 'OZEL KOD 2 OZ-SINAV: % vaka TAMAM (geri alindi)', n;
end $$;
