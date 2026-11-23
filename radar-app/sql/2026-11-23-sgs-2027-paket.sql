-- ============================================================================
--  SGS 2027 PAKETİ  ·  23.11.2026  (site kolu)
--
--  Cem 23.11: SGS satışı "SGS 2027 paketi"ne döner. 31.12.2026 23:59'a kadar 2.988 TL + KDV (KDV dahil 3.585,60),
--  1 Ocak 2027'den 7.488 TL + KDV (KDV dahil 8.985,60) — fiyatı fiyat-motoru.js FIYAT.sgs2027 + iyzico-odeme.ts doğrular.
--  Öğrenci satın alırken gireceği 2027 SGS'sini (Nisan / Temmuz / Kasım) seçer; erişim o sınavdan 3 GÜN SONRA biter.
--  2026 SGS paketi ('sgs') ve Son 20 Gün ('son20-sgs') satıştan kalkar; eski alıcının erişimine / sonuçlarına dokunulmaz.
--
--  NE YAPAR:
--   1) public.sgs_donem_tarih (donem · ad · sinav_tarihi · gecici_bitis): 2027 TÜRMOB takvimi 23.11'de YAYIMLANMADI →
--      sinav_tarihi boş. Boşken bitiş = gecici_bitis (dönemin üst sınırı: Nisan → 30.06.2027, Temmuz → 30.09.2027,
--      Kasım → 31.12.2027). Tarih girilince bitiş = sinav_tarihi + 3 gün.
--   2) siparisler.sgs_donem: sgs-2027 siparişinde ZORUNLU ve tablodaki dönemlerden biri (SGS_DONEM_GEREKLI).
--   3) Tetik siparis_zz_sgs2027_kapi (damgalardan sonra koşar): yeni 'sgs' / 'son20-sgs' siparişi PAKET_SATISTA_DEGIL ·
--      sgs-2027'de indirim (elçi / özel kod / anlık teklif) INDIRIM_YOK_SGS2027 (Cem: reklam fiyatı tek: 3 × 1.195,20).
--   4) Bitiş: kart_siparis_odendi + yonetim_siparis_onayla + _siparis_isle sgs-2027'de _sgs_donem_bitis(sgs_donem) yazar
--      (yönetimin elle verdiği bitiş sgs-2027'de yok sayılır — dönem esastır).
--   5) _paket_kapsar: süren 2026 'sgs' paketi sgs-2027'yi KAPSAMAZ (kalan aday yeni yılı alabilsin; ödenince paket_uyeler
--      satırı sgs-2027 olur, bitiş büyük olan). tam/kurucu yine kapsar.
--   6) yonetim_sgs_donem_tarih(donem, tarih) (U, yönetici): TEK YER — tarihi yazar, o dönemin bütün ödenmiş sgs-2027
--      siparişlerinin paket_bitis'ini ve bağlı hesapların paket_uyeler.bitis'ini sinav + 3 güne çeker (hesapta birden çok
--      dönem varsa en geç olanı). sgs_donem_tarihleri() (A): sayfanın göstereceği dönem/tarih listesi (kişi verisi yok).
--  🚫 GÖRMEZ: mobil mağaza (Play/App Store) ürünleri · hediye/elle verilen paket (sipariş yok) · iki sınav tek hesapta (eski
--     kısıt: süren Yeterlilik paketi varken SGS 2027 BASKA_SINAV_ACIK) · paket_uyeler bitiş güncellemesi gerçek üyeyle ÖLÇÜLMEDİ
--     (öz-sınav sipariş satırında ölçer).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop trigger siparis_zz_sgs2027_kapi on public.siparisler; dört fonksiyon için canli-sema/fonksiyonlar.sql'deki
--     22.11 tanımı yeniden basılır; sütun/tablo kalabilir (zararsız).
-- ============================================================================

create table if not exists public.sgs_donem_tarih (
  donem         text primary key check (donem ~ '^20[0-9]{2}-(nisan|temmuz|kasim)$'),
  ad            text not null,
  sinav_tarihi  date,
  gecici_bitis  date not null,
  guncelleme    timestamptz not null default now()
);
alter table public.sgs_donem_tarih enable row level security;
revoke all on public.sgs_donem_tarih from anon, authenticated;
insert into public.sgs_donem_tarih (donem, ad, gecici_bitis) values
  ('2027-nisan',  'Nisan 2027 SGS',  date '2027-06-30'),
  ('2027-temmuz', 'Temmuz 2027 SGS', date '2027-09-30'),
  ('2027-kasim',  'Kasım 2027 SGS',  date '2027-12-31')
on conflict (donem) do nothing;

alter table public.siparisler add column if not exists sgs_donem text;

create or replace function public._sgs_donem_bitis(p_donem text)
 returns date
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d where d.donem = p_donem;
$function$;
revoke all on function public._sgs_donem_bitis(text) from public, anon, authenticated;

create or replace function public._sgs2027_kapi()
returns trigger
language plpgsql
security definer   -- anon siparişinde de dönem tablosunu okuyabilsin (tablo RLS kapalı politikasız)
set search_path = public
as $$
declare p text := lower(btrim(coalesce(new.paket, '')));
begin
  if tg_op = 'INSERT' and p in ('sgs', 'son20-sgs') then
    raise exception 'PAKET_SATISTA_DEGIL' using hint = 'Bu paket satıştan kalktı; SGS 2027 paketini seç.';
  end if;
  if p = 'sgs-2027' then
    if new.sgs_donem is null or not exists (select 1 from public.sgs_donem_tarih d where d.donem = new.sgs_donem) then
      raise exception 'SGS_DONEM_GEREKLI' using hint = 'Gireceğin 2027 SGS dönemini seç (Nisan, Temmuz ya da Kasım).';
    end if;
    if coalesce(new.indirim_tl, 0) > 0 or coalesce(new.ozel_kod_tl, 0) > 0 or coalesce(new.anlik_teklif_tl, 0) > 0 then
      raise exception 'INDIRIM_YOK_SGS2027' using hint = 'SGS 2027 paketinde indirim kodu kullanılamaz.';
    end if;
  end if;
  return new;
end
$$;
revoke all on function public._sgs2027_kapi() from public, anon, authenticated;
drop trigger if exists siparis_zz_sgs2027_kapi on public.siparisler;
create trigger siparis_zz_sgs2027_kapi
  before insert or update of paket, sgs_donem, indirim_tl, ozel_kod_tl, anlik_teklif_tl on public.siparisler
  for each row execute function public._sgs2027_kapi();

-- ---------------------------------------------------------------------------- 23.11 değişen canlı tanımlar
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
  -- 23.11 SGS 2027: 2026 SGS paketi (süren 92 günlük erişim) yeni yılın paketini KAPSAMAZ; kalan aday 2027'yi alabilsin
  if lower(btrim(coalesce(p_yeni, ''))) = 'sgs-2027' then return v in ('sgs-2027', 'tam', 'kurucu'); end if;
  if v in ('tam', 'kurucu') then return true; end if;
  if s is null or public._paket_sinavi(v) is distinct from s then return false; end if;
  if s = 'sgs' then return true; end if;
  if coalesce(array_length(p_var_ders, 1), 0) = 0 then return true; end if;        -- ders listesiz = tümü
  if coalesce(array_length(p_yeni_ders, 1), 0) = 0 then return false; end if;      -- tüm pakete yükseltme
  return p_yeni_ders <@ p_var_ders;                                                 -- yeni ders varsa serbest
end $function$
;

CREATE OR REPLACE FUNCTION public._siparis_isle(p_sid bigint, p_uid uuid, p_yol text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  tum_dersler constant text[] := array['Finansal Muhasebe', 'Maliyet Muhasebesi', 'Finansal Tablolar ve Analizi',
    'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Sermaye Piyasası Mevzuatı', 'Meslek Hukuku'];
  s public.siparisler%rowtype; v_bitis date; v_eski public.paket_uyeler%rowtype; v_var boolean; v_ders text[];
  v_birlesik text[]; v_paket text;
begin
  if p_uid is null then return 'BOS'; end if;
  select * into s from public.siparisler where id = p_sid for update;
  if not found or s.durum <> 'odendi' then return 'SIPARIS_YOK'; end if;
  if s.bagli_kullanici is not null and s.bagli_kullanici <> p_uid then return 'BASKA_HESAPTA'; end if;
  v_bitis := coalesce(s.paket_bitis,
                      case when s.paket = 'sgs-2027' then public._sgs_donem_bitis(s.sgs_donem)   -- 23.11 SGS 2027: seçilen dönem + 3 gün
                           else greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92) end);
  if v_bitis < current_date then return 'SURESI_GECMIS'; end if;
  v_ders := case when s.paket ~ '^(yeterlilik-[1-4]|kgk-[1-3])

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

  v_bitis := case when s.paket = 'sgs-2027' then public._sgs_donem_bitis(s.sgs_donem)   -- 23.11 SGS 2027: seçilen dönem + 3 gün
                  else greatest(case when s.paket ~ '^sgs' then date '2026-11-21' else date '2026-11-28' end, current_date + 92) end;
  update public.siparisler set durum = 'odendi', odeme = 'kart', paket_bitis = v_bitis where id = s.id;   -- odendi_tarihi tetikleyicide

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'BEKLIYOR', 'not', 'hesap yok; üye olunca kendiliğinden açılır', 'odeme', p_payment_id);
  end if;
  v_sonuc := public.siparis_paket_bagla(v_uid, s.email);
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', v_bitis, 'sonuc', v_sonuc, 'odeme', p_payment_id);
end $function$
;

CREATE OR REPLACE FUNCTION public.yonetim_siparis_onayla(p_no text, p_bitis date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare s public.siparisler%rowtype; v_uid uuid; v_sonuc text; v_bitis date := p_bitis;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if p_bitis is null or p_bitis <= current_date then raise exception 'BITIS_GECERSIZ'; end if;
  select * into s from public.siparisler where siparis_no = p_no for update;
  if not found then raise exception 'SIPARIS_YOK'; end if;
  -- coalesce ŞART: iptal_neden null iken "not (… and null)" null olur, if çalışmaz ve elle iptal de açılırdı (ilk koşuda öz-sınav yakaladı)
  if s.durum <> 'odeme_bekliyor' and not (s.durum = 'iptal' and coalesce(s.iptal_neden, '') = 'otomatik') then
    raise exception 'DURUM_%', upper(s.durum); end if;

  -- 23.11 SGS 2027: bitişi yönetici değil siparişteki dönem belirler (seçilen 2027 SGS'si + 3 gün)
  if s.paket = 'sgs-2027' then v_bitis := public._sgs_donem_bitis(s.sgs_donem); end if;
  update public.siparisler set durum = 'odendi', paket_bitis = v_bitis where id = s.id;   -- odendi_tarihi tetikleyicide

  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  if v_uid is null then
    return jsonb_build_object('siparis', 'odendi', 'paket', 'BEKLIYOR', 'eposta', s.email,
      'not', s.email || ' henüz üye değil. Bu e-postayla üye olduğu anda paketi KENDİLİĞİNDEN açılır.');
  end if;
  v_sonuc := public.siparis_paket_bagla(v_uid, s.email);
  return jsonb_build_object('siparis', 'odendi', 'paket', s.paket, 'bitis', v_bitis, 'eposta', s.email, 'sonuc', v_sonuc);
end $function$
;

-- ---------------------------------------------------------------------------- TEK YER: sınav tarihi girilir
create or replace function public._sgs_donem_tarih_uygula(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare v_s int; v_u int;
begin
  if not exists (select 1 from public.sgs_donem_tarih where donem = p_donem) then raise exception 'DONEM_YOK'; end if;
  if p_tarih is not null and (p_tarih < date '2027-01-01' or p_tarih > date '2027-12-31') then raise exception 'TARIH_GECERSIZ'; end if;
  update public.sgs_donem_tarih set sinav_tarihi = p_tarih, guncelleme = now() where donem = p_donem;
  update public.siparisler set paket_bitis = public._sgs_donem_bitis(p_donem)
   where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi';
  get diagnostics v_s = row_count;
  update public.paket_uyeler pu set bitis = m.b
    from (select s.bagli_kullanici u, max(public._sgs_donem_bitis(s.sgs_donem)) b
            from public.siparisler s
           where s.paket = 'sgs-2027' and s.durum = 'odendi' and s.bagli_kullanici is not null
           group by s.bagli_kullanici) m
   where pu.user_id = m.u and pu.paket = 'sgs-2027' and pu.bitis is distinct from m.b
     and m.u in (select bagli_kullanici from public.siparisler where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi');
  get diagnostics v_u = row_count;
  return jsonb_build_object('donem', p_donem, 'sinav_tarihi', p_tarih, 'bitis', public._sgs_donem_bitis(p_donem),
                            'siparis', v_s, 'hesap', v_u);
end $function$;
revoke all on function public._sgs_donem_tarih_uygula(text, date) from public, anon, authenticated;

create or replace function public.yonetim_sgs_donem_tarih(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return public._sgs_donem_tarih_uygula(p_donem, p_tarih);
end $function$;
revoke all on function public.yonetim_sgs_donem_tarih(text, date) from public, anon;
grant execute on function public.yonetim_sgs_donem_tarih(text, date) to authenticated;

create or replace function public.sgs_donem_tarihleri()
 returns table(donem text, ad text, sinav_tarihi date, bitis date)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select d.donem, d.ad, d.sinav_tarihi, coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d order by d.gecici_bitis;
$function$;
revoke all on function public.sgs_donem_tarihleri() from public;
grant execute on function public.sgs_donem_tarihleri() to anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; ok boolean; v date; j jsonb;
begin
  begin
    -- 1) eski paketler satıştan kalktı
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A1', 'sgs', 2988, 'Olcu Bir', 'olcu-s27-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs siparisi gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A2', 'son20-sgs', 999, 'Olcu Iki', 'olcu-s27-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs siparisi gecti'; end if;
    n := n + 2;
    -- 2) dönemsiz / bilinmeyen dönemli sgs-2027 reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-s27-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: donemsiz sgs-2027 gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-S7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-s27-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    n := n + 2;
    -- 3) dönemli sipariş geçer; kartla ödenince bitiş = geçici bitiş (tarih yok)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A5', 'sgs-2027', 3585.60, 'Olcu Bes', 'olcu-s27-e@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-nisan');
    j := public.kart_siparis_odendi('TT-20261123-S7A5', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: gecici bitis % (beklenen 2027-06-30)', v; end if;
    n := n + 1;
    -- 4) indirim yazılamaz
    ok := false;
    begin
      update public.siparisler set indirim_tl = 400 where siparis_no = 'TT-20261123-S7A5';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SGS2027%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs-2027 indirim yazildi'; end if;
    n := n + 1;
    -- 5) tarih girilince bitiş sınav + 3 güne iner; başka dönem etkilenmez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A6', 'sgs-2027', 3585.60, 'Olcu Alti', 'olcu-s27-f@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    j := public.kart_siparis_odendi('TT-20261123-S7A6', 'olcu');
    j := public._sgs_donem_tarih_uygula('2027-nisan', date '2027-04-25');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-04-28' then raise exception 'OLCU: tarihli bitis % (beklenen 2027-04-28)', v; end if;
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A6';
    if v is distinct from date '2027-12-31' then raise exception 'OLCU: baska donem degisti %', v; end if;
    if (j->>'siparis')::int < 1 then raise exception 'OLCU: tarih uygula siparis saymadi %', j; end if;
    if public._sgs_donem_bitis('2027-nisan') is distinct from date '2027-04-28' then raise exception 'OLCU: _sgs_donem_bitis'; end if;
    -- tarih geri silinince geçici bitişe döner
    j := public._sgs_donem_tarih_uygula('2027-nisan', null);
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: tarih silinince % (beklenen 2027-06-30)', v; end if;
    n := n + 4;
    -- 6) kapsama: 2026 sgs, 2027'yi kapsamaz; 2027 ve tam kapsar; eski davranış aynı
    if public._paket_kapsar('sgs', null, 'sgs-2027', null) then raise exception 'OLCU: sgs 2027yi kapsadi'; end if;
    if not public._paket_kapsar('sgs-2027', null, 'sgs-2027', null) then raise exception 'OLCU: sgs-2027 kendini kapsamadi'; end if;
    if not public._paket_kapsar('tam', null, 'sgs-2027', null) then raise exception 'OLCU: tam kapsamadi'; end if;
    if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: eski sgs davranisi bozuldu'; end if;
    if public._paket_kapsar('yeterlilik-1', array['Hukuk'], 'yeterlilik-2', array['Hukuk','Meslek Hukuku']) then raise exception 'OLCU: yeterlilik davranisi bozuldu'; end if;
    n := n + 5;
    -- 7) dönem listesi anon fonksiyonundan okunur, yetkisiz yönetim çağrısı reddedilir
    if (select count(*) from public.sgs_donem_tarihleri()) <> 3 then raise exception 'OLCU: donem listesi'; end if;
    ok := false;
    begin perform public.yonetim_sgs_donem_tarih('2027-nisan', date '2027-04-25');
    exception when others then if sqlerrm like 'YETKI_YOK%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: yetkisiz tarih girildi'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-S7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 PAKET OZ-SINAV: % vaka TAMAM', n;
end $$;
 then s.secilen_dersler else null end;
  -- KGK modül paketinde boş seçim = kasada "hepsi"; tek konu parasına dört konu açılmasın
  if s.paket ~ '^kgk-[1-3]

@@KART@@

@@ONAY@@

-- ---------------------------------------------------------------------------- TEK YER: sınav tarihi girilir
create or replace function public._sgs_donem_tarih_uygula(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare v_s int; v_u int;
begin
  if not exists (select 1 from public.sgs_donem_tarih where donem = p_donem) then raise exception 'DONEM_YOK'; end if;
  if p_tarih is not null and (p_tarih < date '2027-01-01' or p_tarih > date '2027-12-31') then raise exception 'TARIH_GECERSIZ'; end if;
  update public.sgs_donem_tarih set sinav_tarihi = p_tarih, guncelleme = now() where donem = p_donem;
  update public.siparisler set paket_bitis = public._sgs_donem_bitis(p_donem)
   where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi';
  get diagnostics v_s = row_count;
  update public.paket_uyeler pu set bitis = m.b
    from (select s.bagli_kullanici u, max(public._sgs_donem_bitis(s.sgs_donem)) b
            from public.siparisler s
           where s.paket = 'sgs-2027' and s.durum = 'odendi' and s.bagli_kullanici is not null
           group by s.bagli_kullanici) m
   where pu.user_id = m.u and pu.paket = 'sgs-2027' and pu.bitis is distinct from m.b
     and m.u in (select bagli_kullanici from public.siparisler where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi');
  get diagnostics v_u = row_count;
  return jsonb_build_object('donem', p_donem, 'sinav_tarihi', p_tarih, 'bitis', public._sgs_donem_bitis(p_donem),
                            'siparis', v_s, 'hesap', v_u);
end $function$;
revoke all on function public._sgs_donem_tarih_uygula(text, date) from public, anon, authenticated;

create or replace function public.yonetim_sgs_donem_tarih(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return public._sgs_donem_tarih_uygula(p_donem, p_tarih);
end $function$;
revoke all on function public.yonetim_sgs_donem_tarih(text, date) from public, anon;
grant execute on function public.yonetim_sgs_donem_tarih(text, date) to authenticated;

create or replace function public.sgs_donem_tarihleri()
 returns table(donem text, ad text, sinav_tarihi date, bitis date)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select d.donem, d.ad, d.sinav_tarihi, coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d order by d.gecici_bitis;
$function$;
revoke all on function public.sgs_donem_tarihleri() from public;
grant execute on function public.sgs_donem_tarihleri() to anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; ok boolean; v date; j jsonb;
begin
  begin
    -- 1) eski paketler satıştan kalktı
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A1', 'sgs', 2988, 'Olcu Bir', 'olcu-s27-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs siparisi gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A2', 'son20-sgs', 999, 'Olcu Iki', 'olcu-s27-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs siparisi gecti'; end if;
    n := n + 2;
    -- 2) dönemsiz / bilinmeyen dönemli sgs-2027 reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-s27-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: donemsiz sgs-2027 gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-S7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-s27-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    n := n + 2;
    -- 3) dönemli sipariş geçer; kartla ödenince bitiş = geçici bitiş (tarih yok)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A5', 'sgs-2027', 3585.60, 'Olcu Bes', 'olcu-s27-e@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-nisan');
    j := public.kart_siparis_odendi('TT-20261123-S7A5', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: gecici bitis % (beklenen 2027-06-30)', v; end if;
    n := n + 1;
    -- 4) indirim yazılamaz
    ok := false;
    begin
      update public.siparisler set indirim_tl = 400 where siparis_no = 'TT-20261123-S7A5';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SGS2027%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs-2027 indirim yazildi'; end if;
    n := n + 1;
    -- 5) tarih girilince bitiş sınav + 3 güne iner; başka dönem etkilenmez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A6', 'sgs-2027', 3585.60, 'Olcu Alti', 'olcu-s27-f@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    j := public.kart_siparis_odendi('TT-20261123-S7A6', 'olcu');
    j := public._sgs_donem_tarih_uygula('2027-nisan', date '2027-04-25');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-04-28' then raise exception 'OLCU: tarihli bitis % (beklenen 2027-04-28)', v; end if;
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A6';
    if v is distinct from date '2027-12-31' then raise exception 'OLCU: baska donem degisti %', v; end if;
    if (j->>'siparis')::int < 1 then raise exception 'OLCU: tarih uygula siparis saymadi %', j; end if;
    if public._sgs_donem_bitis('2027-nisan') is distinct from date '2027-04-28' then raise exception 'OLCU: _sgs_donem_bitis'; end if;
    -- tarih geri silinince geçici bitişe döner
    j := public._sgs_donem_tarih_uygula('2027-nisan', null);
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: tarih silinince % (beklenen 2027-06-30)', v; end if;
    n := n + 4;
    -- 6) kapsama: 2026 sgs, 2027'yi kapsamaz; 2027 ve tam kapsar; eski davranış aynı
    if public._paket_kapsar('sgs', null, 'sgs-2027', null) then raise exception 'OLCU: sgs 2027yi kapsadi'; end if;
    if not public._paket_kapsar('sgs-2027', null, 'sgs-2027', null) then raise exception 'OLCU: sgs-2027 kendini kapsamadi'; end if;
    if not public._paket_kapsar('tam', null, 'sgs-2027', null) then raise exception 'OLCU: tam kapsamadi'; end if;
    if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: eski sgs davranisi bozuldu'; end if;
    if public._paket_kapsar('yeterlilik-1', array['Hukuk'], 'yeterlilik-2', array['Hukuk','Meslek Hukuku']) then raise exception 'OLCU: yeterlilik davranisi bozuldu'; end if;
    n := n + 5;
    -- 7) dönem listesi anon fonksiyonundan okunur, yetkisiz yönetim çağrısı reddedilir
    if (select count(*) from public.sgs_donem_tarihleri()) <> 3 then raise exception 'OLCU: donem listesi'; end if;
    ok := false;
    begin perform public.yonetim_sgs_donem_tarih('2027-nisan', date '2027-04-25');
    exception when others then if sqlerrm like 'YETKI_YOK%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: yetkisiz tarih girildi'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-S7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 PAKET OZ-SINAV: % vaka TAMAM', n;
end $$;
 and coalesce(array_length(v_ders, 1), 0) = 0 then return 'DERS_SECIMI_YOK'; end if;
  select * into v_eski from public.paket_uyeler where user_id = p_uid for update;
  v_var := found;

  -- 03.11 (paket-koruma): başka sınavın süren paketi silinmez
  if v_var and v_eski.bitis >= current_date and lower(v_eski.paket) not in ('tam', 'kurucu', 'yeterlilik-kgk')
     and public._paket_sinavi(v_eski.paket) is not null and public._paket_sinavi(s.paket) is not null
     and public._paket_sinavi(v_eski.paket) <> public._paket_sinavi(s.paket) then
    return 'BASKA_SINAV_ACIK';
  end if;

  -- 03.11: açık ders paketine yeni ders → birleştir (eski ders kapanmaz, yeni ders açılır)
  if v_var and s.paket ~ '^yeterlilik-[1-4]

@@KART@@

@@ONAY@@

-- ---------------------------------------------------------------------------- TEK YER: sınav tarihi girilir
create or replace function public._sgs_donem_tarih_uygula(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare v_s int; v_u int;
begin
  if not exists (select 1 from public.sgs_donem_tarih where donem = p_donem) then raise exception 'DONEM_YOK'; end if;
  if p_tarih is not null and (p_tarih < date '2027-01-01' or p_tarih > date '2027-12-31') then raise exception 'TARIH_GECERSIZ'; end if;
  update public.sgs_donem_tarih set sinav_tarihi = p_tarih, guncelleme = now() where donem = p_donem;
  update public.siparisler set paket_bitis = public._sgs_donem_bitis(p_donem)
   where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi';
  get diagnostics v_s = row_count;
  update public.paket_uyeler pu set bitis = m.b
    from (select s.bagli_kullanici u, max(public._sgs_donem_bitis(s.sgs_donem)) b
            from public.siparisler s
           where s.paket = 'sgs-2027' and s.durum = 'odendi' and s.bagli_kullanici is not null
           group by s.bagli_kullanici) m
   where pu.user_id = m.u and pu.paket = 'sgs-2027' and pu.bitis is distinct from m.b
     and m.u in (select bagli_kullanici from public.siparisler where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi');
  get diagnostics v_u = row_count;
  return jsonb_build_object('donem', p_donem, 'sinav_tarihi', p_tarih, 'bitis', public._sgs_donem_bitis(p_donem),
                            'siparis', v_s, 'hesap', v_u);
end $function$;
revoke all on function public._sgs_donem_tarih_uygula(text, date) from public, anon, authenticated;

create or replace function public.yonetim_sgs_donem_tarih(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return public._sgs_donem_tarih_uygula(p_donem, p_tarih);
end $function$;
revoke all on function public.yonetim_sgs_donem_tarih(text, date) from public, anon;
grant execute on function public.yonetim_sgs_donem_tarih(text, date) to authenticated;

create or replace function public.sgs_donem_tarihleri()
 returns table(donem text, ad text, sinav_tarihi date, bitis date)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select d.donem, d.ad, d.sinav_tarihi, coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d order by d.gecici_bitis;
$function$;
revoke all on function public.sgs_donem_tarihleri() from public;
grant execute on function public.sgs_donem_tarihleri() to anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; ok boolean; v date; j jsonb;
begin
  begin
    -- 1) eski paketler satıştan kalktı
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A1', 'sgs', 2988, 'Olcu Bir', 'olcu-s27-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs siparisi gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A2', 'son20-sgs', 999, 'Olcu Iki', 'olcu-s27-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs siparisi gecti'; end if;
    n := n + 2;
    -- 2) dönemsiz / bilinmeyen dönemli sgs-2027 reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-s27-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: donemsiz sgs-2027 gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-S7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-s27-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    n := n + 2;
    -- 3) dönemli sipariş geçer; kartla ödenince bitiş = geçici bitiş (tarih yok)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A5', 'sgs-2027', 3585.60, 'Olcu Bes', 'olcu-s27-e@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-nisan');
    j := public.kart_siparis_odendi('TT-20261123-S7A5', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: gecici bitis % (beklenen 2027-06-30)', v; end if;
    n := n + 1;
    -- 4) indirim yazılamaz
    ok := false;
    begin
      update public.siparisler set indirim_tl = 400 where siparis_no = 'TT-20261123-S7A5';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SGS2027%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs-2027 indirim yazildi'; end if;
    n := n + 1;
    -- 5) tarih girilince bitiş sınav + 3 güne iner; başka dönem etkilenmez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A6', 'sgs-2027', 3585.60, 'Olcu Alti', 'olcu-s27-f@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    j := public.kart_siparis_odendi('TT-20261123-S7A6', 'olcu');
    j := public._sgs_donem_tarih_uygula('2027-nisan', date '2027-04-25');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-04-28' then raise exception 'OLCU: tarihli bitis % (beklenen 2027-04-28)', v; end if;
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A6';
    if v is distinct from date '2027-12-31' then raise exception 'OLCU: baska donem degisti %', v; end if;
    if (j->>'siparis')::int < 1 then raise exception 'OLCU: tarih uygula siparis saymadi %', j; end if;
    if public._sgs_donem_bitis('2027-nisan') is distinct from date '2027-04-28' then raise exception 'OLCU: _sgs_donem_bitis'; end if;
    -- tarih geri silinince geçici bitişe döner
    j := public._sgs_donem_tarih_uygula('2027-nisan', null);
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: tarih silinince % (beklenen 2027-06-30)', v; end if;
    n := n + 4;
    -- 6) kapsama: 2026 sgs, 2027'yi kapsamaz; 2027 ve tam kapsar; eski davranış aynı
    if public._paket_kapsar('sgs', null, 'sgs-2027', null) then raise exception 'OLCU: sgs 2027yi kapsadi'; end if;
    if not public._paket_kapsar('sgs-2027', null, 'sgs-2027', null) then raise exception 'OLCU: sgs-2027 kendini kapsamadi'; end if;
    if not public._paket_kapsar('tam', null, 'sgs-2027', null) then raise exception 'OLCU: tam kapsamadi'; end if;
    if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: eski sgs davranisi bozuldu'; end if;
    if public._paket_kapsar('yeterlilik-1', array['Hukuk'], 'yeterlilik-2', array['Hukuk','Meslek Hukuku']) then raise exception 'OLCU: yeterlilik davranisi bozuldu'; end if;
    n := n + 5;
    -- 7) dönem listesi anon fonksiyonundan okunur, yetkisiz yönetim çağrısı reddedilir
    if (select count(*) from public.sgs_donem_tarihleri()) <> 3 then raise exception 'OLCU: donem listesi'; end if;
    ok := false;
    begin perform public.yonetim_sgs_donem_tarih('2027-nisan', date '2027-04-25');
    exception when others then if sqlerrm like 'YETKI_YOK%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: yetkisiz tarih girildi'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-S7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 PAKET OZ-SINAV: % vaka TAMAM', n;
end $$;
 and coalesce(array_length(v_ders, 1), 0) > 0
     and v_eski.paket ~ '^yeterlilik-[1-7]

@@KART@@

@@ONAY@@

-- ---------------------------------------------------------------------------- TEK YER: sınav tarihi girilir
create or replace function public._sgs_donem_tarih_uygula(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare v_s int; v_u int;
begin
  if not exists (select 1 from public.sgs_donem_tarih where donem = p_donem) then raise exception 'DONEM_YOK'; end if;
  if p_tarih is not null and (p_tarih < date '2027-01-01' or p_tarih > date '2027-12-31') then raise exception 'TARIH_GECERSIZ'; end if;
  update public.sgs_donem_tarih set sinav_tarihi = p_tarih, guncelleme = now() where donem = p_donem;
  update public.siparisler set paket_bitis = public._sgs_donem_bitis(p_donem)
   where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi';
  get diagnostics v_s = row_count;
  update public.paket_uyeler pu set bitis = m.b
    from (select s.bagli_kullanici u, max(public._sgs_donem_bitis(s.sgs_donem)) b
            from public.siparisler s
           where s.paket = 'sgs-2027' and s.durum = 'odendi' and s.bagli_kullanici is not null
           group by s.bagli_kullanici) m
   where pu.user_id = m.u and pu.paket = 'sgs-2027' and pu.bitis is distinct from m.b
     and m.u in (select bagli_kullanici from public.siparisler where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi');
  get diagnostics v_u = row_count;
  return jsonb_build_object('donem', p_donem, 'sinav_tarihi', p_tarih, 'bitis', public._sgs_donem_bitis(p_donem),
                            'siparis', v_s, 'hesap', v_u);
end $function$;
revoke all on function public._sgs_donem_tarih_uygula(text, date) from public, anon, authenticated;

create or replace function public.yonetim_sgs_donem_tarih(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return public._sgs_donem_tarih_uygula(p_donem, p_tarih);
end $function$;
revoke all on function public.yonetim_sgs_donem_tarih(text, date) from public, anon;
grant execute on function public.yonetim_sgs_donem_tarih(text, date) to authenticated;

create or replace function public.sgs_donem_tarihleri()
 returns table(donem text, ad text, sinav_tarihi date, bitis date)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select d.donem, d.ad, d.sinav_tarihi, coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d order by d.gecici_bitis;
$function$;
revoke all on function public.sgs_donem_tarihleri() from public;
grant execute on function public.sgs_donem_tarihleri() to anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; ok boolean; v date; j jsonb;
begin
  begin
    -- 1) eski paketler satıştan kalktı
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A1', 'sgs', 2988, 'Olcu Bir', 'olcu-s27-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs siparisi gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A2', 'son20-sgs', 999, 'Olcu Iki', 'olcu-s27-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs siparisi gecti'; end if;
    n := n + 2;
    -- 2) dönemsiz / bilinmeyen dönemli sgs-2027 reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-s27-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: donemsiz sgs-2027 gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-S7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-s27-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    n := n + 2;
    -- 3) dönemli sipariş geçer; kartla ödenince bitiş = geçici bitiş (tarih yok)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A5', 'sgs-2027', 3585.60, 'Olcu Bes', 'olcu-s27-e@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-nisan');
    j := public.kart_siparis_odendi('TT-20261123-S7A5', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: gecici bitis % (beklenen 2027-06-30)', v; end if;
    n := n + 1;
    -- 4) indirim yazılamaz
    ok := false;
    begin
      update public.siparisler set indirim_tl = 400 where siparis_no = 'TT-20261123-S7A5';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SGS2027%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs-2027 indirim yazildi'; end if;
    n := n + 1;
    -- 5) tarih girilince bitiş sınav + 3 güne iner; başka dönem etkilenmez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A6', 'sgs-2027', 3585.60, 'Olcu Alti', 'olcu-s27-f@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    j := public.kart_siparis_odendi('TT-20261123-S7A6', 'olcu');
    j := public._sgs_donem_tarih_uygula('2027-nisan', date '2027-04-25');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-04-28' then raise exception 'OLCU: tarihli bitis % (beklenen 2027-04-28)', v; end if;
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A6';
    if v is distinct from date '2027-12-31' then raise exception 'OLCU: baska donem degisti %', v; end if;
    if (j->>'siparis')::int < 1 then raise exception 'OLCU: tarih uygula siparis saymadi %', j; end if;
    if public._sgs_donem_bitis('2027-nisan') is distinct from date '2027-04-28' then raise exception 'OLCU: _sgs_donem_bitis'; end if;
    -- tarih geri silinince geçici bitişe döner
    j := public._sgs_donem_tarih_uygula('2027-nisan', null);
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: tarih silinince % (beklenen 2027-06-30)', v; end if;
    n := n + 4;
    -- 6) kapsama: 2026 sgs, 2027'yi kapsamaz; 2027 ve tam kapsar; eski davranış aynı
    if public._paket_kapsar('sgs', null, 'sgs-2027', null) then raise exception 'OLCU: sgs 2027yi kapsadi'; end if;
    if not public._paket_kapsar('sgs-2027', null, 'sgs-2027', null) then raise exception 'OLCU: sgs-2027 kendini kapsamadi'; end if;
    if not public._paket_kapsar('tam', null, 'sgs-2027', null) then raise exception 'OLCU: tam kapsamadi'; end if;
    if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: eski sgs davranisi bozuldu'; end if;
    if public._paket_kapsar('yeterlilik-1', array['Hukuk'], 'yeterlilik-2', array['Hukuk','Meslek Hukuku']) then raise exception 'OLCU: yeterlilik davranisi bozuldu'; end if;
    n := n + 5;
    -- 7) dönem listesi anon fonksiyonundan okunur, yetkisiz yönetim çağrısı reddedilir
    if (select count(*) from public.sgs_donem_tarihleri()) <> 3 then raise exception 'OLCU: donem listesi'; end if;
    ok := false;
    begin perform public.yonetim_sgs_donem_tarih('2027-nisan', date '2027-04-25');
    exception when others then if sqlerrm like 'YETKI_YOK%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: yetkisiz tarih girildi'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-S7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 PAKET OZ-SINAV: % vaka TAMAM', n;
end $$;
 and coalesce(array_length(v_eski.dersler, 1), 0) > 0
     and v_eski.bitis >= current_date then
    select array_agg(x order by coalesce(array_position(tum_dersler, x), 99), x) into v_birlesik
      from (select distinct unnest(v_eski.dersler || v_ders) x) t;
    if v_birlesik @> tum_dersler then v_paket := 'yeterlilik-tum'; v_birlesik := null;
    else v_paket := 'yeterlilik-' || array_length(v_birlesik, 1); end if;
    update public.paket_uyeler
       set paket = v_paket, dersler = v_birlesik, bitis = greatest(v_eski.bitis, v_bitis)
     where user_id = p_uid;
    update public.siparisler set bagli_kullanici = p_uid, bagli_tarih = now(), bagli_yol = left(coalesce(p_yol, ''), 20)
     where id = s.id and bagli_kullanici is null;
    return case when v_ders <@ v_eski.dersler and v_eski.bitis >= v_bitis then 'ZATEN_ACIK' else 'ACILDI' end;
  end if;

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

@@KART@@

@@ONAY@@

-- ---------------------------------------------------------------------------- TEK YER: sınav tarihi girilir
create or replace function public._sgs_donem_tarih_uygula(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare v_s int; v_u int;
begin
  if not exists (select 1 from public.sgs_donem_tarih where donem = p_donem) then raise exception 'DONEM_YOK'; end if;
  if p_tarih is not null and (p_tarih < date '2027-01-01' or p_tarih > date '2027-12-31') then raise exception 'TARIH_GECERSIZ'; end if;
  update public.sgs_donem_tarih set sinav_tarihi = p_tarih, guncelleme = now() where donem = p_donem;
  update public.siparisler set paket_bitis = public._sgs_donem_bitis(p_donem)
   where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi';
  get diagnostics v_s = row_count;
  update public.paket_uyeler pu set bitis = m.b
    from (select s.bagli_kullanici u, max(public._sgs_donem_bitis(s.sgs_donem)) b
            from public.siparisler s
           where s.paket = 'sgs-2027' and s.durum = 'odendi' and s.bagli_kullanici is not null
           group by s.bagli_kullanici) m
   where pu.user_id = m.u and pu.paket = 'sgs-2027' and pu.bitis is distinct from m.b
     and m.u in (select bagli_kullanici from public.siparisler where paket = 'sgs-2027' and sgs_donem = p_donem and durum = 'odendi');
  get diagnostics v_u = row_count;
  return jsonb_build_object('donem', p_donem, 'sinav_tarihi', p_tarih, 'bitis', public._sgs_donem_bitis(p_donem),
                            'siparis', v_s, 'hesap', v_u);
end $function$;
revoke all on function public._sgs_donem_tarih_uygula(text, date) from public, anon, authenticated;

create or replace function public.yonetim_sgs_donem_tarih(p_donem text, p_tarih date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return public._sgs_donem_tarih_uygula(p_donem, p_tarih);
end $function$;
revoke all on function public.yonetim_sgs_donem_tarih(text, date) from public, anon;
grant execute on function public.yonetim_sgs_donem_tarih(text, date) to authenticated;

create or replace function public.sgs_donem_tarihleri()
 returns table(donem text, ad text, sinav_tarihi date, bitis date)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select d.donem, d.ad, d.sinav_tarihi, coalesce(d.sinav_tarihi + 3, d.gecici_bitis) from public.sgs_donem_tarih d order by d.gecici_bitis;
$function$;
revoke all on function public.sgs_donem_tarihleri() from public;
grant execute on function public.sgs_donem_tarihleri() to anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; ok boolean; v date; j jsonb;
begin
  begin
    -- 1) eski paketler satıştan kalktı
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A1', 'sgs', 2988, 'Olcu Bir', 'olcu-s27-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs siparisi gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A2', 'son20-sgs', 999, 'Olcu Iki', 'olcu-s27-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs siparisi gecti'; end if;
    n := n + 2;
    -- 2) dönemsiz / bilinmeyen dönemli sgs-2027 reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-S7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-s27-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: donemsiz sgs-2027 gecti'; end if;
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-S7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-s27-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    n := n + 2;
    -- 3) dönemli sipariş geçer; kartla ödenince bitiş = geçici bitiş (tarih yok)
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A5', 'sgs-2027', 3585.60, 'Olcu Bes', 'olcu-s27-e@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-nisan');
    j := public.kart_siparis_odendi('TT-20261123-S7A5', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: gecici bitis % (beklenen 2027-06-30)', v; end if;
    n := n + 1;
    -- 4) indirim yazılamaz
    ok := false;
    begin
      update public.siparisler set indirim_tl = 400 where siparis_no = 'TT-20261123-S7A5';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SGS2027%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sgs-2027 indirim yazildi'; end if;
    n := n + 1;
    -- 5) tarih girilince bitiş sınav + 3 güne iner; başka dönem etkilenmez
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-S7A6', 'sgs-2027', 3585.60, 'Olcu Alti', 'olcu-s27-f@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    j := public.kart_siparis_odendi('TT-20261123-S7A6', 'olcu');
    j := public._sgs_donem_tarih_uygula('2027-nisan', date '2027-04-25');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-04-28' then raise exception 'OLCU: tarihli bitis % (beklenen 2027-04-28)', v; end if;
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A6';
    if v is distinct from date '2027-12-31' then raise exception 'OLCU: baska donem degisti %', v; end if;
    if (j->>'siparis')::int < 1 then raise exception 'OLCU: tarih uygula siparis saymadi %', j; end if;
    if public._sgs_donem_bitis('2027-nisan') is distinct from date '2027-04-28' then raise exception 'OLCU: _sgs_donem_bitis'; end if;
    -- tarih geri silinince geçici bitişe döner
    j := public._sgs_donem_tarih_uygula('2027-nisan', null);
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-S7A5';
    if v is distinct from date '2027-06-30' then raise exception 'OLCU: tarih silinince % (beklenen 2027-06-30)', v; end if;
    n := n + 4;
    -- 6) kapsama: 2026 sgs, 2027'yi kapsamaz; 2027 ve tam kapsar; eski davranış aynı
    if public._paket_kapsar('sgs', null, 'sgs-2027', null) then raise exception 'OLCU: sgs 2027yi kapsadi'; end if;
    if not public._paket_kapsar('sgs-2027', null, 'sgs-2027', null) then raise exception 'OLCU: sgs-2027 kendini kapsamadi'; end if;
    if not public._paket_kapsar('tam', null, 'sgs-2027', null) then raise exception 'OLCU: tam kapsamadi'; end if;
    if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: eski sgs davranisi bozuldu'; end if;
    if public._paket_kapsar('yeterlilik-1', array['Hukuk'], 'yeterlilik-2', array['Hukuk','Meslek Hukuku']) then raise exception 'OLCU: yeterlilik davranisi bozuldu'; end if;
    n := n + 5;
    -- 7) dönem listesi anon fonksiyonundan okunur, yetkisiz yönetim çağrısı reddedilir
    if (select count(*) from public.sgs_donem_tarihleri()) <> 3 then raise exception 'OLCU: donem listesi'; end if;
    ok := false;
    begin perform public.yonetim_sgs_donem_tarih('2027-nisan', date '2027-04-25');
    exception when others then if sqlerrm like 'YETKI_YOK%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: yetkisiz tarih girildi'; end if;
    n := n + 2;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-S7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 PAKET OZ-SINAV: % vaka TAMAM', n;
end $$;
