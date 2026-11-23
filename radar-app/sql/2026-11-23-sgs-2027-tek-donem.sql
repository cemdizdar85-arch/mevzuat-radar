-- ============================================================================
--  SGS 2027 PAKETİ TEK DÖNEM  ·  23.11.2026  (site kolu)
--
--  Cem 23.11 ("Nisan/Temmuz/Kasım sorusunu kaldırırım" önerisine: "hayır patron biz 3 aylık paket satıyoruz şu an, nisana kadar
--  paket satacağız"): satın almada dönem SORULMAZ. Paket en yakın 2027 SGS'sini kapsar; erişim o sınavdan 3 gün sonra biter.
--  Bugün en yakın = Nisan 2027. Nisan geçtikten sonra alan (tarih girildiyse sınav + 3 gün geçince) Temmuz'u alır — süresi
--  geçmiş paket satılmaz.
--
--  NE YAPAR: _sgs2027_kapi — sgs-2027 siparişinde sgs_donem boşsa sunucu yazar: sgs_donem_tarih'te bitişi (sınav + 3 gün, tarih
--  yoksa geçici bitiş) bugünden sonra olan İLK dönem. Dönem gönderilmişse eskisi gibi doğrulanır. Kalan dönem yoksa SGS_DONEM_YOK.
--  Öteki kurallar (PAKET_SATISTA_DEGIL, INDIRIM_YOK_SGS2027) aynen.
--  🚫 GÖRMEZ: tarih girilmemiş dönemde geçici bitiş (Nisan → 30.06.2027) esas alınır; Nisan sınavı geçip tarih girilmediyse Nisan
--     seçilmeye devam eder → TÜRMOB tarihi açıklanınca yönetimden girilmeli (yonetim_sgs_donem_tarih).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
-- ============================================================================

create or replace function public._sgs2027_kapi()
returns trigger
language plpgsql
security definer   -- anon siparişinde de dönem tablosunu okuyabilsin (tablo RLS açık, politikasız)
set search_path = public
as $$
declare p text := lower(btrim(coalesce(new.paket, '')));
begin
  if tg_op = 'INSERT' and p in ('sgs', 'son20-sgs') then
    raise exception 'PAKET_SATISTA_DEGIL' using hint = 'Bu paket satıştan kalktı; SGS 2027 paketini seç.';
  end if;
  if p = 'sgs-2027' then
    if new.sgs_donem is null then
      -- 23.11 Cem: dönem sorulmaz → en yakın, süresi geçmemiş 2027 SGS'si
      select d.donem into new.sgs_donem
        from public.sgs_donem_tarih d
       where coalesce(d.sinav_tarihi + 3, d.gecici_bitis) >= current_date
       order by coalesce(d.sinav_tarihi, d.gecici_bitis)
       limit 1;
      if new.sgs_donem is null then
        raise exception 'SGS_DONEM_YOK' using hint = '2027 SGS dönemleri bitti; yeni yılın paketi henüz kurulmadı.';
      end if;
    elsif not exists (select 1 from public.sgs_donem_tarih d where d.donem = new.sgs_donem) then
      raise exception 'SGS_DONEM_GEREKLI' using hint = 'Bilinmeyen 2027 SGS dönemi.';
    end if;
    if coalesce(new.indirim_tl, 0) > 0 or coalesce(new.ozel_kod_tl, 0) > 0 or coalesce(new.anlik_teklif_tl, 0) > 0 then
      raise exception 'INDIRIM_YOK_SGS2027' using hint = 'SGS 2027 paketinde indirim kodu kullanılamaz.';
    end if;
  end if;
  return new;
end
$$;
revoke all on function public._sgs2027_kapi() from public, anon, authenticated;

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; d text; v date; ok boolean; j jsonb;
begin
  begin
    -- 1) dönemsiz sipariş → bugün en yakın Nisan
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261123-T7A1', 'sgs-2027', 3585.60, 'Olcu Bir', 'olcu-t7-a@tetikte.invalid', 'kart', 'odeme_bekliyor');
    select sgs_donem into d from public.siparisler where siparis_no = 'TT-20261123-T7A1';
    if d is distinct from '2027-nisan' then raise exception 'OLCU: donemsiz siparis % aldi (beklenen 2027-nisan)', d; end if;
    j := public.kart_siparis_odendi('TT-20261123-T7A1', 'olcu');
    select paket_bitis into v from public.siparisler where siparis_no = 'TT-20261123-T7A1';
    if v is distinct from public._sgs_donem_bitis('2027-nisan') then raise exception 'OLCU: bitis %', v; end if;
    n := n + 2;
    -- 2) Nisan sınavı geçmişse (tarih girilmiş, +3 gün geçmiş) Temmuz verilir
    update public.sgs_donem_tarih set sinav_tarihi = current_date - 10 where donem = '2027-nisan';
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261123-T7A2', 'sgs-2027', 3585.60, 'Olcu Iki', 'olcu-t7-b@tetikte.invalid', 'kart', 'odeme_bekliyor');
    select sgs_donem into d from public.siparisler where siparis_no = 'TT-20261123-T7A2';
    if d is distinct from '2027-temmuz' then raise exception 'OLCU: nisan gecince % aldi (beklenen 2027-temmuz)', d; end if;
    n := n + 1;
    -- 3) bilinmeyen dönem reddedilir; gönderilen geçerli dönem korunur
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
        ('TT-20261123-T7A3', 'sgs-2027', 3585.60, 'Olcu Uc', 'olcu-t7-c@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-mart');
    exception when others then if sqlerrm like 'SGS_DONEM_GEREKLI%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: bilinmeyen donem gecti'; end if;
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, sgs_donem) values
      ('TT-20261123-T7A4', 'sgs-2027', 3585.60, 'Olcu Dort', 'olcu-t7-d@tetikte.invalid', 'kart', 'odeme_bekliyor', '2027-kasim');
    select sgs_donem into d from public.siparisler where siparis_no = 'TT-20261123-T7A4';
    if d is distinct from '2027-kasim' then raise exception 'OLCU: gonderilen donem degisti %', d; end if;
    n := n + 2;
    -- 4) eski kurallar aynen
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
        ('TT-20261123-T7A5', 'son20-sgs', 999, 'Olcu Bes', 'olcu-t7-e@tetikte.invalid', 'kart', 'odeme_bekliyor');
    exception when others then if sqlerrm like 'PAKET_SATISTA_DEGIL%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: son20-sgs gecti'; end if;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261123-T7A%')
     or exists (select 1 from public.sgs_donem_tarih where sinav_tarihi is not null) then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SGS 2027 TEK DONEM OZ-SINAV: % vaka TAMAM', n;
end $$;
