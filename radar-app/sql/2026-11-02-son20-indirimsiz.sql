-- ============================================================================
--  999 TL SON 20 GÜN PAKETLERİNDE İNDİRİM KODU YOK  ·  02.11.2026
--
--  Cem 02.11: "999 TL tekliflerde hiçbir indirim kodu kullanılamasın."
--  999 TL teklifler = son20-sgs (Sadece 7 Deneme) + son20-yet (Yeterlilik Sadece Denemeler) — fiyat-motoru.js son20Sgs/son20Yet.
--
--  NE YAPAR:
--   1) elci_kodu_kontrol / ozel_kod_kontrol (sayfanın "Uygula" sorusu) bu iki pakette 0 döner → sayfa "geçersiz" der.
--      _ozel_kod_gecerli bu iki pakette null döner → siparis_teklif_damga OZEL_KOD_GECERSIZ ile reddeder.
--   2) Tetik siparis_zz_son20_indirimsiz (adı bilerek "zz": aynı anda koşan before tetikleri ad sırasıyla koşar, bu
--      elçi + teklif + özel kod damgalarından SONRA koşar): bu iki paketin siparişinde indirim_tl / ozel_kod_tl /
--      anlik_teklif_tl sıfırdan büyükse INDIRIM_YOK_SON20 ile reddeder (elci_indirim'e sonradan son20 satırı eklense de).
--      Kod alanı boş ya da indirimi 0 olan elçi kodu sipariş vermeyi engellemez (indirim yok = engel yok).
--  Sayfa tarafı: satin-al.html bu iki pakette kod kutusunu göstermez, ?elci= ile gelen kodu uygulamaz.
--  🚫 GÖRMEZ: 999 TL'ye sonradan eklenecek YENİ paket kimliği (liste elle: son20-sgs, son20-yet) · hediye/elle verilen paket
--     (sipariş yok) · yönetimin elle onayladığı sipariş tutarı (yonetim_siparis_onayla tutara dokunmaz).
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (geri alınır).
--  GERİ ALMA: drop trigger siparis_zz_son20_indirimsiz on public.siparisler; elci_kodu_kontrol + _ozel_kod_gecerli
--     için canli-sema/fonksiyonlar.sql'deki 01.11 tanımı yeniden basılır.
-- ============================================================================

create or replace function public._ozel_kod_gecerli(p_kod text, p_paket text)
 returns integer
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select case when o.indirim_paket is not null then (o.indirim_paket ->> p_paket)::int else o.indirim_tl end
    from ozel_kod o
   where o.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
     and lower(btrim(coalesce(p_paket, ''))) not in ('son20-sgs', 'son20-yet')   -- 02.11: 999 TL tekliflerde kod yok
     and o.iptal is null
     and o.son > now()
     and p_paket = any (o.paketler)
     and (o.indirim_paket is null or (o.indirim_paket ->> p_paket) is not null)
     and (o.kullanildi is null
          or not exists (select 1 from siparisler s where s.siparis_no = o.siparis_no and s.durum <> 'iptal'));
$function$;

create or replace function public.elci_kodu_kontrol(p_kod text, p_paket text)
 returns integer
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select coalesce((
    select i.indirim_tl
      from elciler e
      join elci_indirim i on i.paket = p_paket
     where e.kod = upper(regexp_replace(coalesce(p_kod, ''), '[^A-Za-z0-9]', '', 'g'))
       and e.aktif
       and lower(btrim(coalesce(p_paket, ''))) not in ('son20-sgs', 'son20-yet')   -- 02.11: 999 TL tekliflerde kod yok
  ), 0);
$function$;

create or replace function public._son20_indirimsiz()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if lower(btrim(coalesce(new.paket, ''))) in ('son20-sgs', 'son20-yet')
     and (coalesce(new.indirim_tl, 0) > 0 or coalesce(new.ozel_kod_tl, 0) > 0 or coalesce(new.anlik_teklif_tl, 0) > 0) then
    raise exception 'INDIRIM_YOK_SON20' using hint = '999 TL Son 20 Gün paketlerinde indirim kodu kullanılamaz.';
  end if;
  return new;
end
$$;
revoke all on function public._son20_indirimsiz() from public, anon, authenticated;
drop trigger if exists siparis_zz_son20_indirimsiz on public.siparisler;
create trigger siparis_zz_son20_indirimsiz
  before insert or update of paket, indirim_tl, ozel_kod_tl, anlik_teklif_tl on public.siparisler
  for each row execute function public._son20_indirimsiz();

-- ---------------------------------------------------------------------------- öz-sınav (hepsi geri alınır)
do $$
declare n int := 0; v int; ok boolean;
begin
  begin
    insert into public.elciler (kod, ad_soyad, email) values ('OLCUS20X', 'Olcu Elci', 'olcu-s20-elci@tetikte.invalid');
    insert into public.elci_indirim (paket, indirim_tl) values ('son20-sgs', 100) on conflict (paket) do update set indirim_tl = 100;
    insert into public.elci_indirim (paket, indirim_tl) values ('sgs', 150) on conflict (paket) do update set indirim_tl = 150;
    insert into public.ozel_kod (kod, indirim_tl, paketler, son, kime) values
      ('OZACDEFH', 200, array['son20-sgs','son20-yet','sgs'], now() + interval '1 day', 'olcu');   -- kod bu paketleri kapsasa bile

    -- 1) Uygula sorusu: 999 TL paketlerde 0, öteki pakette eskisi gibi
    if public.elci_kodu_kontrol('OLCUS20X', 'son20-sgs') <> 0 then raise exception 'OLCU: elci kodu son20-sgs indirim verdi'; end if;
    if public.elci_kodu_kontrol('OLCUS20X', 'sgs') <> 150 then raise exception 'OLCU: elci kodu sgs indirimi dustu'; end if;
    if public.ozel_kod_kontrol('OZACDEFH', 'son20-sgs') <> 0 then raise exception 'OLCU: ozel kod son20-sgs indirim verdi'; end if;
    if public.ozel_kod_kontrol('OZACDEFH', 'son20-yet') <> 0 then raise exception 'OLCU: ozel kod son20-yet indirim verdi'; end if;
    if public.ozel_kod_kontrol('OZACDEFH', 'sgs') <> 200 then raise exception 'OLCU: ozel kod sgs indirimi dustu'; end if;
    n := n + 5;

    -- 2) elçi kodlu 999 TL siparişi reddedilir (elci_indirim'de son20 satırı olsa bile)
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, elci_kodu) values
        ('TT-20261102-S2A1', 'son20-sgs', 899, 'Olcu Bir', 'olcu-s20-a@tetikte.invalid', 'kart', 'odeme_bekliyor', 'OLCUS20X');
    exception when others then if sqlerrm like 'INDIRIM_YOK_SON20%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: elci kodlu son20-sgs siparisi gecti'; end if;
    -- 3) özel kodlu 999 TL siparişi reddedilir
    ok := false;
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, ozel_kod) values
        ('TT-20261102-S2A2', 'son20-yet', 799, 'Olcu Iki', 'olcu-s20-b@tetikte.invalid', 'kart', 'odeme_bekliyor', 'OZACDEFH');
    exception when others then if sqlerrm like 'OZEL_KOD_GECERSIZ%' or sqlerrm like 'INDIRIM_YOK_SON20%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: ozel kodlu son20-yet siparisi gecti'; end if;
    if (select kullanildi from public.ozel_kod where kod = 'OZACDEFH') is not null then raise exception 'OLCU: reddedilen sipariste kod tuketildi'; end if;
    -- 4) sonradan indirim yazmak da reddedilir
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum) values
      ('TT-20261102-S2A3', 'son20-sgs', 999, 'Olcu Uc', 'olcu-s20-c@tetikte.invalid', 'kart', 'odeme_bekliyor');
    select indirim_tl into v from public.siparisler where siparis_no = 'TT-20261102-S2A3';
    if v <> 0 then raise exception 'OLCU: kodsuz son20 siparisi indirimli'; end if;
    ok := false;
    begin
      update public.siparisler set indirim_tl = 100 where siparis_no = 'TT-20261102-S2A3';
    exception when others then if sqlerrm like 'INDIRIM_YOK_SON20%' then ok := true; else raise; end if; end;
    if not ok then raise exception 'OLCU: sonradan indirim yazildi'; end if;
    n := n + 4;

    -- 5) öteki paket eskisi gibi: elçi kodlu sgs siparişi indirimi alır
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, elci_kodu) values
      ('TT-20261102-S2A4', 'sgs', 2838, 'Olcu Dort', 'olcu-s20-d@tetikte.invalid', 'kart', 'odeme_bekliyor', 'OLCUS20X');
    select indirim_tl into v from public.siparisler where siparis_no = 'TT-20261102-S2A4';
    if v <> 150 then raise exception 'OLCU: sgs elci indirimi % (beklenen 150)', v; end if;
    n := n + 1;
    raise exception 'OLCU_TAMAM %', n;
  exception when others then
    if sqlerrm not like 'OLCU_TAMAM %' then raise; end if;
    n := split_part(sqlerrm, ' ', 2)::int;
  end;
  if exists (select 1 from public.siparisler where siparis_no like 'TT-20261102-S2A%')
     or exists (select 1 from public.elciler where kod = 'OLCUS20X')
     or exists (select 1 from public.ozel_kod where kod = 'OZACDEFH') then raise exception 'OLCU: geri alma iz birakti'; end if;
  raise notice 'SON20 INDIRIMSIZ OZ-SINAV: % vaka TAMAM', n;
end $$;
