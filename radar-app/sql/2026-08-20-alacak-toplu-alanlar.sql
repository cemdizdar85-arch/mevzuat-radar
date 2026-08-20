-- ============================================================================
--  ALACAK TOPLU TARAMA — AYRISTIRILAN ALANLAR   (20.08.2026, ikinci tur)
--
--  Cem: "kalan iki is yapalim"
--
--  KUSUR: 20.08 sabahi metin ayristirmasi kuruldu ve alacak_ara yeni alanlari
--  dondurmeye basladi, ama TOPLU tarama (Excel/CSV yukleyen musavir) hala eski
--  alanlarla donuyordu. Yani tek borclu sorgulayan muhlet/komiser/esas no
--  goruyordu, 200 musterisini yukleyen GORMUYORDU — asil abone aday orada.
--
--  AYRICA: grup konkordatosunda ikinci/ucuncu borclunun VKN'si vknler[]
--  dizisinde duruyor; alacak_ara bunu ariyordu, alacak_toplu ARAMIYORDU.
--  Excel'inde o VKN olan musavir eslesmeyi kaciriyordu.
--
--  KILIT KURALI KORUNUR: ucretsiz katmanda ilk 3 eslesme acik, gerisi kilitli.
--  Kilitli kayitta YENI ALANLAR DA null doner — yoksa "kim oldugu abonelikte"
--  derken mahkeme/dosya no/komiser sizar ve kilidin anlami kalmaz.
--
--  KOSMA: Supabase SQL editorunde bir kez. Onkosul: 2026-08-20-alacak-metin-
--  alanlari.sql kosulmus olmali (kolonlar + alacak_borclu_maskele oradan gelir).
-- ============================================================================

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
$fn$;
grant execute on function public.alacak_toplu(text[]) to anon, authenticated;
