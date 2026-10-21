-- ============================================================================
-- ÇİFT ÖDEME KAPISI (21.10.2026, Cem: "ödeme sayfasına çift ödeme kapısı koyalım. yok zaten böyle bir şey,
-- saçma şekilde iki kere alıyor")
--
-- OLAY (ölçüldü 21.10, siparisler + magaza_siparis + kart_odemeleri):
--   * Bir alıcı 18.10 18:51'de Google Play'den Yeterlilik tüm paketi aldı (paket 14 sn'de açıldı); ertesi sabah aynı
--     paketi sitede kartla İKİNCİ KEZ ödedi (TT-20261019-V5Y7). Sipariş sayfası hesapta açık paketi hiç sormuyordu.
--   * 7 alıcı önce bir sipariş açtı (çoğu iyzico sayfasını açıp geri döndü), sonra aynı paket için YENİ sipariş verip
--     onu ödedi: her siparişte ayrı "siparişin alındı + IBAN" maili, eskisi "ödeme bekliyor" olarak kaldı.
--
-- ÇÖZÜM:
--   1) _paket_sinavi(paket) · _paket_kapsar(var, var_ders, yeni, yeni_ders): magaza-dogrula.ts paketPlani ile AYNI
--      kural — tam/kurucu her şeyi kapsar; aynı sınavda SGS kapsar; ders listesiz (tüm) paket kapsar; ders listeli
--      paket yalnız alt kümeyi kapsar (eksik ders / tüm pakete yükseltme SERBEST). Başka sınav kapsamaz.
--   2) siparis_cift_sebep(eposta, uid, paket, dersler, haric_no): satırı reddetmek için neden (yoksa null).
--      PAKET_ZATEN_ACIK: siparişi veren hesapta (auth.uid) · siparişin e-postasıyla açılmış hesapta · bu e-postanın
--      ödenmiş ve henüz hesaba bağlanmamış siparişinde aktif ve kapsayan paket var.
--   3) Tetikleyici siparis_cift_kapi (BEFORE INSERT; ad alfabede elçi/teklif damgasından ÖNCE):
--      PAKET_ZATEN_ACIK → sipariş yazılmaz. BEKLEYEN_SIPARIS → aynı e-posta + aynı paket + aynı dersler + aynı tutar
--      ile son 24 saatte açılmış ödeme bekleyen sipariş var → yeni sipariş yazılmaz (alındı maili de gitmez);
--      sayfa eski siparişi ödetir. Sipariş no hata metnine YAZILMAZ (e-postayı bilen başkası öğrenmesin).
--   4) siparis_odeme_kontrol(no): iyzico-odeme ?islem=baslat ödeme sayfasını açmadan ÖNCE sorar (yalnız servis).
--      Bekleyen eski sipariş, bu arada başka yoldan (Play / başka sipariş) açılmış pakete ikinci kez ödenmez.
--
-- 🚫 GÖRMEZ: farklı e-postayla ve girişsiz verilen ikinci sipariş (kişiyi tanıyamıyoruz) · havale ile iki kez para
--    gönderilmesi (banka eşleştirmesi Cem'de) · iki sekmeden aynı saniyede verilen iki sipariş (yarış) · başka sınavın
--    paketi üstüne yazılması (paket_uyeler tek satır; ayrı iş) · Play tarafı (magaza-dogrula zaten "zaten-acik" der).
-- Uygulanma: sql-uygula.yml (push ile otomatik). Bu dosya değiştirilmez; düzeltme yeni dosyayla.
-- ============================================================================

create or replace function public._paket_sinavi(p text)
returns text language sql immutable as $$
  select case
    when lower(btrim(coalesce(p, ''))) ~ '^sgs' or lower(btrim(coalesce(p, ''))) = 'sinav-249' then 'sgs'
    when lower(btrim(coalesce(p, ''))) ~ '^yeterlilik' or lower(btrim(coalesce(p, ''))) = 'smmm' then 'yeterlilik'
    when lower(btrim(coalesce(p, ''))) ~ '^kgk' then 'kgk'
    else null end
$$;

create or replace function public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[])
returns boolean language plpgsql immutable as $$
declare v text := lower(btrim(coalesce(p_var, ''))); s text := public._paket_sinavi(p_yeni);
begin
  if v in ('tam', 'kurucu') then return true; end if;
  if s is null or public._paket_sinavi(v) is distinct from s then return false; end if;
  if s = 'sgs' then return true; end if;
  if coalesce(array_length(p_var_ders, 1), 0) = 0 then return true; end if;        -- ders listesiz = tümü
  if coalesce(array_length(p_yeni_ders, 1), 0) = 0 then return false; end if;      -- tüm pakete yükseltme
  return p_yeni_ders <@ p_var_ders;                                                 -- yeni ders varsa serbest
end $$;

create or replace function public.siparis_cift_sebep(p_eposta text, p_uid uuid, p_paket text, p_dersler text[], p_haric_no text)
returns text language plpgsql stable security definer set search_path = public, auth as $$
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
end $$;
revoke all on function public.siparis_cift_sebep(text, uuid, text, text[], text) from public, anon, authenticated;

create or replace function public.siparis_cift_kapi()
returns trigger language plpgsql security definer set search_path = public, auth as $$
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
end $$;

drop trigger if exists siparis_cift_kapi on public.siparisler;
create trigger siparis_cift_kapi
  before insert on public.siparisler
  for each row execute function public.siparis_cift_kapi();

-- iyzico-odeme ?islem=baslat: ödeme sayfası açılmadan önce (yalnız servis rolü)
create or replace function public.siparis_odeme_kontrol(p_no text)
returns text language plpgsql stable security definer set search_path = public, auth as $$
declare s public.siparisler%rowtype; v_uid uuid;
begin
  select * into s from public.siparisler where siparis_no = p_no;
  if not found then return 'SIPARIS_YOK'; end if;
  select id into v_uid from auth.users where lower(email) = lower(s.email) limit 1;
  return coalesce(public.siparis_cift_sebep(s.email, v_uid, s.paket, s.secilen_dersler, s.siparis_no), 'TAMAM');
end $$;
revoke all on function public.siparis_odeme_kontrol(text) from public, anon, authenticated;
grant execute on function public.siparis_odeme_kontrol(text) to service_role;

-- ÖZ-SINAV + MUTASYON. Hepsi alt işlemde; sonunda 'OLCU_TAMAM' ile GERİ ALINIR. Bir vaka tutmazsa ya da bir mutasyon
-- yakalanmazsa göç KIRMIZI düşer ve sql-uygula tek işlem (-1) olduğu için bu dosyadan HİÇBİR ŞEY uygulanmaz.
--   Kapsama: 10 vaka. Sipariş: V1 e-postanın hesabında açık paket (girişsiz) RED · V2 girişli hesabın açık paketi, başka
--   e-postayla RED · V3 başka sınav SERBEST · V4 aynı paket+tutar 24 saatte ikinci kez BEKLEYEN · V5 farklı tutar SERBEST ·
--   V6 paketsiz yeni kişi SERBEST · V7 ders listeli pakette yeni ders SERBEST, eldeki ders RED · V8 ödeme kontrolü: bağsız
--   ödenmiş sipariş kapsıyorsa PAKET_ZATEN_ACIK, kapsamıyorsa TAMAM.
--   Mutasyon (her biri vakaları KIRMIZIYA düşürmeli): M1 tetikleyici boş · M2 kapsama hep false · M3 kapsama hep true ·
--   M4 sebep hep null · M5 bekleyen sipariş denetimi yok.
do $$
declare r text; m int := 0;
begin
  if not public._paket_kapsar('tam', null, 'sgs', null) then raise exception 'OLCU: tam sgs kapsamali'; end if;
  if not public._paket_kapsar('kurucu', null, 'kgk-tum', null) then raise exception 'OLCU: kurucu'; end if;
  if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: sgs-sgs'; end if;
  if public._paket_kapsar('sgs', null, 'yeterlilik-tum', null) then raise exception 'OLCU: baska sinav kapsamamali'; end if;
  if not public._paket_kapsar('yeterlilik-tum', null, 'yeterlilik-1', array['Muhasebe']) then raise exception 'OLCU: tum ders'; end if;
  if public._paket_kapsar('yeterlilik-2', array['Muhasebe','Vergi'], 'yeterlilik-tum', null) then raise exception 'OLCU: yukseltme serbest olmali'; end if;
  if not public._paket_kapsar('yeterlilik-2', array['Muhasebe','Vergi'], 'yeterlilik-1', array['Vergi']) then raise exception 'OLCU: alt kume'; end if;
  if public._paket_kapsar('yeterlilik-1', array['Muhasebe'], 'yeterlilik-1', array['Vergi']) then raise exception 'OLCU: yeni ders serbest olmali'; end if;
  if not public._paket_kapsar('kgk-tum', null, 'kgk-1', array['TMS']) then raise exception 'OLCU: kgk tum'; end if;
  if public._paket_kapsar('yeterlilik-tum', null, 'kgk-tum', null) then raise exception 'OLCU: yet kgk kapsamamali'; end if;

  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values ('00000000-0000-4000-8000-0000000c1f01', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-cift-a@tetikte.invalid', now(), now()),
           ('00000000-0000-4000-8000-0000000c1f02', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-cift-b@tetikte.invalid', now(), now());
    insert into public.paket_uyeler (user_id, paket, bitis) values ('00000000-0000-4000-8000-0000000c1f01', 'yeterlilik-tum', current_date + 60);
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values ('00000000-0000-4000-8000-0000000c1f02', 'yeterlilik-1', current_date + 60, array['Muhasebe']);

    -- vakalar: kendi alt işleminde koşar ve kendini geri alır → mutasyonlar altında tekrar tekrar koşturulabilir.
    -- Dönüş: 'TAMAM' ya da ilk tutmayan vakanın adı.
    execute $f$
    create function pg_temp.cift_vakalar() returns text language plpgsql as $g$
    declare r text := 'TAMAM';
    begin
      begin
        perform set_config('request.jwt.claims', '', true);
        perform set_config('request.jwt.claim.sub', '', true);
        -- V1 girişsiz, e-postanın hesabında yeterlilik-tum açık (büyük harf + boşluk tolere)
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
          values ('TT-20261021-QC01', 'yeterlilik-tum', 3468, 'Olcu', ' OLCU-Cift-A@tetikte.invalid', 'havale', 'odeme_bekliyor');
          raise exception 'yazildi';
        exception when others then if sqlerrm <> 'PAKET_ZATEN_ACIK' then r := 'V1 ' || sqlerrm; raise exception 'SONUC'; end if; end;
        -- V2 girişli a, başka e-postayla aynı sınav
        perform set_config('request.jwt.claims', json_build_object('sub', '00000000-0000-4000-8000-0000000c1f01', 'role', 'authenticated')::text, true);
        perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000c1f01', true);
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
          values ('TT-20261021-QC02', 'yeterlilik-1', 1188, 'Olcu', 'baska-adres@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Vergi']);
          raise exception 'yazildi';
        exception when others then if sqlerrm <> 'PAKET_ZATEN_ACIK' then r := 'V2 ' || sqlerrm; raise exception 'SONUC'; end if; end;
        -- V3 başka sınav serbest
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
          values ('TT-20261021-QC03', 'sgs', 2988, 'Olcu', 'olcu-cift-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
        exception when others then r := 'V3 ' || sqlerrm; raise exception 'SONUC'; end;
        -- V4 aynı paket + aynı tutar ikinci kez
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
          values ('TT-20261021-QC04', 'sgs', 2988, 'Olcu', 'Olcu-Cift-A@tetikte.invalid', 'havale', 'odeme_bekliyor');
          raise exception 'yazildi';
        exception when others then if sqlerrm <> 'BEKLEYEN_SIPARIS' then r := 'V4 ' || sqlerrm; raise exception 'SONUC'; end if; end;
        -- V5 farklı tutar (indirim kodu) serbest
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
          values ('TT-20261021-QC05', 'sgs', 2588, 'Olcu', 'olcu-cift-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
        exception when others then r := 'V5 ' || sqlerrm; raise exception 'SONUC'; end;
        -- V6 paketsiz, hesapsız yeni kişi (girişsiz)
        perform set_config('request.jwt.claims', '', true);
        perform set_config('request.jwt.claim.sub', '', true);
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
          values ('TT-20261021-QC06', 'yeterlilik-1', 1188, 'Olcu', 'olcu-cift-yeni@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Muhasebe']);
        exception when others then r := 'V6 ' || sqlerrm; raise exception 'SONUC'; end;
        -- V7 b'de yeterlilik-1 [Muhasebe]: yeni ders serbest, eldeki ders RED
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
          values ('TT-20261021-QC07', 'yeterlilik-1', 1188, 'Olcu', 'olcu-cift-b@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Vergi']);
        exception when others then r := 'V7a ' || sqlerrm; raise exception 'SONUC'; end;
        begin
          insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
          values ('TT-20261021-QC08', 'yeterlilik-1', 1188, 'Olcu', 'olcu-cift-b@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Muhasebe']);
          raise exception 'yazildi';
        exception when others then if sqlerrm <> 'PAKET_ZATEN_ACIK' then r := 'V7b ' || sqlerrm; raise exception 'SONUC'; end if; end;
        -- V8 ödeme kontrolü: QC05 (sgs) ödendi ama hesaba bağlanmadı → bekleyen QC03 (sgs) ödenemez; QC06 ödenebilir
        update public.siparisler set durum = 'odendi', paket_bitis = current_date + 30 where siparis_no = 'TT-20261021-QC05';
        if public.siparis_odeme_kontrol('TT-20261021-QC03') <> 'PAKET_ZATEN_ACIK' then r := 'V8a ' || public.siparis_odeme_kontrol('TT-20261021-QC03'); raise exception 'SONUC'; end if;
        if public.siparis_odeme_kontrol('TT-20261021-QC06') <> 'TAMAM' then r := 'V8b ' || public.siparis_odeme_kontrol('TT-20261021-QC06'); raise exception 'SONUC'; end if;
        raise exception 'SONUC';
      exception when others then
        if sqlerrm = 'SONUC' then return r; end if;
        return 'HATA ' || sqlerrm;
      end;
    end $g$;
    $f$;

    r := pg_temp.cift_vakalar();
    if r <> 'TAMAM' then raise exception 'OLCU: vaka tutmadi: %', r; end if;

    -- M1 tetikleyici boş
    begin
      execute $m$create or replace function public.siparis_cift_kapi() returns trigger language plpgsql as $b$ begin return new; end $b$$m$;
      if pg_temp.cift_vakalar() = 'TAMAM' then raise exception 'OLCU: M1 yakalanmadi'; end if;
      m := m + 1; raise exception 'MUT_GERI';
    exception when others then if sqlerrm <> 'MUT_GERI' then raise; end if; end;
    -- M2 kapsama hep false
    begin
      execute $m$create or replace function public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[]) returns boolean language plpgsql immutable as $b$ begin return false; end $b$$m$;
      if pg_temp.cift_vakalar() = 'TAMAM' then raise exception 'OLCU: M2 yakalanmadi'; end if;
      m := m + 1; raise exception 'MUT_GERI';
    exception when others then if sqlerrm <> 'MUT_GERI' then raise; end if; end;
    -- M3 kapsama hep true
    begin
      execute $m$create or replace function public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[]) returns boolean language plpgsql immutable as $b$ begin return true; end $b$$m$;
      if pg_temp.cift_vakalar() = 'TAMAM' then raise exception 'OLCU: M3 yakalanmadi'; end if;
      m := m + 1; raise exception 'MUT_GERI';
    exception when others then if sqlerrm <> 'MUT_GERI' then raise; end if; end;
    -- M4 sebep hep null
    begin
      execute $m$create or replace function public.siparis_cift_sebep(p_eposta text, p_uid uuid, p_paket text, p_dersler text[], p_haric_no text) returns text language plpgsql stable as $b$ begin return null; end $b$$m$;
      if pg_temp.cift_vakalar() = 'TAMAM' then raise exception 'OLCU: M4 yakalanmadi'; end if;
      m := m + 1; raise exception 'MUT_GERI';
    exception when others then if sqlerrm <> 'MUT_GERI' then raise; end if; end;
    -- M5 bekleyen sipariş denetimi yok
    begin
      execute $m$create or replace function public.siparis_cift_kapi() returns trigger language plpgsql security definer set search_path = public, auth as $b$
        declare v text; begin v := public.siparis_cift_sebep(new.email, auth.uid(), new.paket, new.secilen_dersler, null);
        if v is not null then raise exception '%', v; end if; return new; end $b$$m$;
      if pg_temp.cift_vakalar() = 'TAMAM' then raise exception 'OLCU: M5 yakalanmadi'; end if;
      m := m + 1; raise exception 'MUT_GERI';
    exception when others then if sqlerrm <> 'MUT_GERI' then raise; end if; end;
    if m <> 5 then raise exception 'OLCU: mutasyon % / 5', m; end if;

    -- mutasyonlar geri alındı mı: vakalar yine TAMAM
    r := pg_temp.cift_vakalar();
    if r <> 'TAMAM' then raise exception 'OLCU: mutasyon sonrasi vaka %', r; end if;
    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261021-QC%')
     or exists (select 1 from auth.users where email like 'olcu-cift-%@tetikte.invalid') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'CIFT ODEME KAPISI OZ-SINAV: kapsama 10 + siparis 10 vaka TAMAM, mutasyon 5/5 KIRMIZI (geri alindi)';
end $$;

-- ÖLÇÜ (uygulama sonrası): anon POST /rest/v1/siparisler, açık paketli bir hesabın e-postasıyla → 400 PAKET_ZATEN_ACIK
--   · anon POST /rest/v1/rpc/siparis_odeme_kontrol → 401/404 (yalnız servis).

