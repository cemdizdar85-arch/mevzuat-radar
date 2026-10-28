-- ============================================================================
--  YETERLİLİK SON 20 GÜN ÖN SATIŞ (son20-yet, 999 TL KDV dahil)  ·  28.10.2026 (site kolu)
--
--  CEM 28.10: "Yeterlilik Son 20 Gün paketini de SGS'deki 999 TL gibi şimdiden ön satışa açalım" · "BUNA SATIN AL
--  DİYECEĞİZ KAÇINDA AÇACAKSAN 20 GÜN KALA O GÜN AÇILACAK DİYE YAZ" → denemeler 8 Kasım'da (28 Kasım sınavına 20 gün).
--
--  NE YAPAR (son20-sgs düzeninin aynısı, 2026-10-27-gecene-kadar-tetikte.sql):
--   1) Kimlik bilerek 'yeterlilik' ile BAŞLAMAZ: paket_erisim_var ('yeterlilik-%') ve _paket_sinavi (^yeterlilik) bütün
--      Yeterlilik bankasını açardı. elci_indirim satırı YOK → erken kayıt / elçi kodu bu pakete işlemez. Kartla tutar:
--      iyzico-odeme.ts paketFiyat.
--   2) _paket_kapsar: son20-yet siparişi açık başka paketi olan hesapta PAKET_ZATEN_ACIK ile durur (Tam Paket'i ya da
--      SGS 7 Deneme'yi silmesin — paket_uyeler kişi başına tek satır). Aynı kural son20-sgs dalına da eklendi: 7 Deneme
--      siparişi son20-yet üyeliğini silmez. Tersi serbest: son20-yet → yeterlilik-tum yükseltmesi üstüne yazar.
--  🚫 GÖRMEZ: denemelerin son20-yet üyesine açılması (s20_erisim yalnız SGS; 8 Kasım'dan önce ayrı iş, FU-ONSATIS
--     o tarihten sonra KIRMIZI) · iki Son 20 Gün paketini birlikte almak isteyen (ikincisi "zaten açık" der) ·
--     yükseltmede ödenen 999'un düşülmesi (elle).
--  Push ile otomatik (sql-uygula.yml). Öz-sınavın sipariş/üye satırları geri alınır.
--  GERİ ALMA: _paket_kapsar 2026-10-27-gecene-kadar-tetikte.sql gövdesiyle yeniden.
-- ============================================================================

create or replace function public._paket_kapsar(p_var text, p_var_ders text[], p_yeni text, p_yeni_ders text[])
returns boolean language plpgsql immutable as $$
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
end $$;

-- GÖÇ İÇİ ÖZ-SINAV
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000e2801';
  n int := 0; v text; k text;
begin
  -- 1) kod indirimi yok
  foreach k in array array['ERKENYET600','ERKEN600','ERKEN400'] loop
    if public.elci_kodu_kontrol(k, 'son20-yet') <> 0 then raise exception 'OLCU: % son20-yet paketine indirim veriyor', k; end if;
    n := n + 1;
  end loop;
  if public._paket_sinavi('son20-yet') is not null then raise exception 'OLCU: son20-yet bir sinava eslendi (banka acilir)'; end if;
  n := n + 1;

  -- 2) kapsama tablosu
  if not public._paket_kapsar('yeterlilik-tum', null, 'son20-yet', null) then raise exception 'OLCU: yeterlilik uyesi son20-yet alabiliyor'; end if;
  if not public._paket_kapsar('yeterlilik-2', array['Denetim','Vergi'], 'son20-yet', null) then raise exception 'OLCU: ders uyeligi son20-yet ile silinir'; end if;
  if not public._paket_kapsar('sgs', null, 'son20-yet', null) then raise exception 'OLCU: sgs uyeligi son20-yet ile silinir'; end if;
  if not public._paket_kapsar('tam', null, 'son20-yet', null) then raise exception 'OLCU: tam uyesi son20-yet alabiliyor'; end if;
  if not public._paket_kapsar('son20-yet', null, 'son20-yet', null) then raise exception 'OLCU: son20-yet iki kez alinabiliyor'; end if;
  if not public._paket_kapsar('son20-sgs', null, 'son20-yet', null) then raise exception 'OLCU: son20-sgs uyeligi son20-yet ile silinir'; end if;
  if not public._paket_kapsar('son20-yet', null, 'son20-sgs', null) then raise exception 'OLCU: son20-yet uyeligi son20-sgs ile silinir'; end if;
  if public._paket_kapsar('son20-yet', null, 'yeterlilik-tum', null) then raise exception 'OLCU: son20-yet uyesi Tum Derslere yukselemiyor'; end if;
  if public._paket_kapsar('son20-yet', null, 'sgs', null) then raise exception 'OLCU: son20-yet sgs kapsiyor'; end if;
  -- gerileme: son20-sgs eski kuralları
  if not public._paket_kapsar('sgs', null, 'son20-sgs', null) then raise exception 'OLCU: sgs uyesi 7 Deneme alabiliyor'; end if;
  if public._paket_kapsar('son20-sgs', null, 'sgs', null) then raise exception 'OLCU: 7 Deneme uyesi Tam Pakete yukselemiyor'; end if;
  if not public._paket_kapsar('sgs', null, 'sgs', null) then raise exception 'OLCU: sgs-sgs gerileme'; end if;
  if public._paket_kapsar('yeterlilik-2', array['Denetim'], 'yeterlilik-3', array['Denetim','Vergi','Hukuk']) then raise exception 'OLCU: ders yukseltme gerileme'; end if;
  n := n + 13;

  -- 3) uçtan uca: sipariş bağlanır, kod düşer; yeterlilik-tum yükseltmesi yazılır; sonra son20-yet siparişi durur
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at)
    values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-s20y-a@tetikte.invalid', now(), now());
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, elci_kodu)
      values ('TT-20261028-Y201', 'son20-yet', 999, 'Olcu Bir', 'olcu-s20y-a@tetikte.invalid', 'havale', 'odeme_bekliyor', 'ERKENYET600');
    if (select indirim_tl from public.siparisler where siparis_no = 'TT-20261028-Y201') <> 0
       or (select elci_kodu from public.siparisler where siparis_no = 'TT-20261028-Y201') is not null then
      raise exception 'OLCU: son20-yet siparisine kod islendi'; end if;
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261028-Y201';
    v := public._siparis_isle((select id from public.siparisler where siparis_no = 'TT-20261028-Y201'), a, 'olcu');
    if v <> 'ACILDI' then raise exception 'OLCU: son20-yet paketi acilmadi (%)', v; end if;
    if (select paket from public.paket_uyeler where user_id = a) <> 'son20-yet' then raise exception 'OLCU: paket_uyeler son20-yet degil'; end if;
    n := n + 3;
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
      values ('TT-20261028-Y202', 'yeterlilik-tum', 3468, 'Olcu Bir', 'olcu-s20y-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
    update public.siparisler set durum = 'odendi' where siparis_no = 'TT-20261028-Y202';
    v := public._siparis_isle((select id from public.siparisler where siparis_no = 'TT-20261028-Y202'), a, 'olcu');
    if (select paket from public.paket_uyeler where user_id = a) <> 'yeterlilik-tum' then raise exception 'OLCU: yukseltme yazilmadi (%)', v; end if;
    n := n + 1;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
        values ('TT-20261028-Y203', 'son20-yet', 999, 'Olcu Bir', 'olcu-s20y-a@tetikte.invalid', 'havale', 'odeme_bekliyor');
      raise exception 'OLCU: yeterlilik uyesine son20-yet siparisi yazildi';
    exception when others then if sqlerrm not like '%PAKET_ZATEN_ACIK%' then raise; end if; end;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from auth.users where email like 'olcu-s20y-%@tetikte.invalid')
     or exists (select 1 from public.siparisler where siparis_no like 'TT-20261028-Y20%') then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
  raise notice 'SON20-YET OZ-SINAV: % vaka TAMAM', n;
end $$;
