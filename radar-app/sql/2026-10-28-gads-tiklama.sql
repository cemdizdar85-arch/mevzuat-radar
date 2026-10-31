-- ============================================================================
-- GOOGLE ADS TIKLAMA KİMLİĞİ → SİPARİŞ (28.10.2026, Cem 27.10: "Evet, satışı Google'a bildirelim; gizlilik/KVKK
-- metnini de aynı commit'te güncelle")
--
-- OLAY (ölçüldü 27.10, pazarlama oturumu): Google Ads kampanyası (1.500 TL/gün) teklifini "en çok tıklama"ya göre
-- veriyor, dönüşüm hedefi anlamsız ("Yol tarifi alma"). menu.js ?gclid= görünce yalnız 'gads' ETİKETİNİ yazıyordu;
-- tıklama kimliği hiçbir yerde saklanmadığı için ödenen sipariş reklam tıklamasıyla eşleşmiyor, Google kimin
-- satın aldığını bilmiyordu.
--
-- ÇÖZÜM:
--   1) siparisler +gads_tiklama (text, Google tıklama kimliği = gclid) +gads_tiklama_zaman (timestamptz, tıklama anı).
--      Tarayıcı menu.js ttKaynak.tiklama() ile cihazdaki tt_gclid'i (90 gün) yollar (satin-al.html).
--   2) BEFORE INSERT siparis_gads_tiklama_suz: biçim süzülür (menu.js TK_DESEN ile AYNI desen); uymayan kimlik NULL
--      olur, sipariş DÜŞMEZ. Kimlik yoksa zaman da NULL. Gelecek tarihli / 90 günden eski zaman NULL olur (kimlik kalır).
--   3) CHECK siparisler_gads_tiklama_bicim (aynı desen; servis yolundan da bozuk değer giremesin).
--   Ödenen siparişlerden Google içe aktarma CSV'si: arac/gads-cevrimdisi-donusum.js (servis anahtarı; çıktı DEPO DIŞI
--   _yerel-veri-kasasi/). anon/authenticated'ın siparisler üzerinde select hakkı yok (2026-09-15-elci-programi.sql).
--
-- 🚫 GÖRMEZ: gbraid/wbraid (iOS) tıklamaları (ilk sürümde siparişe yazılmaz) · reklama tıklayıp başka cihazdan alan ·
--   kimliğin gerçekten Google'dan geldiği (yalnız biçim süzülür; uydurma kimliği Google içe aktarmada reddeder).
-- Eskitir: — (yeni sütun + yeni tetikleyici; siparis_teklif_damga / siparis_cift_kapi'ya dokunmaz).
-- Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav + mutasyon (geri alınır).
-- ============================================================================

alter table public.siparisler add column if not exists gads_tiklama       text;
alter table public.siparisler add column if not exists gads_tiklama_zaman timestamptz;

create or replace function public.siparis_gads_tiklama_suz() returns trigger
language plpgsql set search_path = public as $$
begin
  new.gads_tiklama := nullif(btrim(coalesce(new.gads_tiklama, '')), '');
  if new.gads_tiklama is not null and new.gads_tiklama !~ '^[A-Za-z0-9_-]{10,200}$' then new.gads_tiklama := null; end if;
  if new.gads_tiklama is null then
    new.gads_tiklama_zaman := null;
  elsif new.gads_tiklama_zaman > now() + interval '5 minutes' or new.gads_tiklama_zaman < now() - interval '90 days' then
    new.gads_tiklama_zaman := null;
  end if;
  return new;
end $$;
revoke all on function public.siparis_gads_tiklama_suz() from public, anon, authenticated;

-- geçmiş satırlar boş; kısıt eklenmeden önce süzgeç tetikleyicisi kurulur
drop trigger if exists siparis_gads_tiklama_suz on public.siparisler;
create trigger siparis_gads_tiklama_suz before insert on public.siparisler
  for each row execute function public.siparis_gads_tiklama_suz();

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'siparisler_gads_tiklama_bicim') then
    alter table public.siparisler add constraint siparisler_gads_tiklama_bicim
      check (gads_tiklama is null or gads_tiklama ~ '^[A-Za-z0-9_-]{10,200}$');
  end if;
end $$;

-- ÖZ-SINAV + MUTASYON. Hepsi alt işlemde; sonunda 'OLCU_TAMAM' ile GERİ ALINIR. Bir vaka tutmazsa ya da bir mutasyon
-- yakalanmazsa göç KIRMIZI düşer ve sql-uygula tek işlem (-1) olduğu için bu dosyadan HİÇBİR ŞEY uygulanmaz.
--   Vakalar (pg_temp.gads_vakalar, kendi alt işleminde koşar ve kendini geri alır → mutasyon altında yeniden koşar):
--   V1 geçerli kimlik + zaman yazılır · V2 HTML'li kimlik NULL, sipariş YİNE yazılır · V3 kısa kimlik NULL ·
--   V4 kimliksiz zaman NULL · V5 gelecek zaman NULL, kimlik kalır · V6 91 günlük zaman NULL · V7 boşluklu kimlik
--   kırpılır · V8 sütun hiç verilmeden (eski istemci) sipariş yazılır.
--   Mutasyon (her biri vakaları KIRMIZIYA düşürmeli): M1 süzgeç gövdesi boş (return new) · M2 desen hep geçer.
create function pg_temp.gads_vakalar() returns text language plpgsql as $f$
declare r text := 'TAMAM'; x record; e text := 'olcu-gads@tetikte.invalid'; g text := 'Cj0KCQjw' || repeat('a', 40);
begin
  begin
    begin
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, gads_tiklama, gads_tiklama_zaman) values
        ('TT-20261028-GA01', 'sgs', 2988, 'Olcu', e, 'havale', 'odeme_bekliyor', g, now() - interval '2 days'),
        ('TT-20261028-GA02', 'sgs', 2989, 'Olcu', e, 'havale', 'odeme_bekliyor', '<script>' || repeat('a', 20), now()),
        ('TT-20261028-GA03', 'sgs', 2990, 'Olcu', e, 'havale', 'odeme_bekliyor', 'kisa', now()),
        ('TT-20261028-GA04', 'sgs', 2991, 'Olcu', e, 'havale', 'odeme_bekliyor', null, now()),
        ('TT-20261028-GA05', 'sgs', 2992, 'Olcu', e, 'havale', 'odeme_bekliyor', g, now() + interval '1 day'),
        ('TT-20261028-GA06', 'sgs', 2993, 'Olcu', e, 'havale', 'odeme_bekliyor', g, now() - interval '91 days'),
        ('TT-20261028-GA07', 'sgs', 2994, 'Olcu', e, 'havale', 'odeme_bekliyor', '  ' || g || ' ', null);
      insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum)
        values ('TT-20261028-GA08', 'sgs', 2995, 'Olcu', e, 'havale', 'odeme_bekliyor');
    exception when others then r := 'EKLEME ' || sqlerrm; raise exception 'SONUC';
    end;
    for x in select siparis_no n, gads_tiklama t, gads_tiklama_zaman z from public.siparisler where siparis_no like 'TT-20261028-GA0_' order by 1 loop
      if (x.n = 'TT-20261028-GA01' and (x.t is distinct from g or x.z is null))
      or (x.n = 'TT-20261028-GA02' and (x.t is not null or x.z is not null))
      or (x.n = 'TT-20261028-GA03' and x.t is not null)
      or (x.n = 'TT-20261028-GA04' and x.z is not null)
      or (x.n = 'TT-20261028-GA05' and (x.t is distinct from g or x.z is not null))
      or (x.n = 'TT-20261028-GA06' and x.z is not null)
      or (x.n = 'TT-20261028-GA07' and x.t is distinct from g)
      or (x.n = 'TT-20261028-GA08' and (x.t is not null or x.z is not null)) then
        r := 'V' || right(x.n, 1); raise exception 'SONUC';
      end if;
    end loop;
    if (select count(*) from public.siparisler where siparis_no like 'TT-20261028-GA0_') <> 8 then r := 'SAYI'; raise exception 'SONUC'; end if;
    raise exception 'SONUC';
  exception when others then
    if sqlerrm <> 'SONUC' then r := 'BEKLENMEDIK ' || sqlerrm; end if;
  end;
  return r;
end $f$;

do $$
declare r text; asil text; m int := 0;
begin
  begin
    r := pg_temp.gads_vakalar();
    if r <> 'TAMAM' then raise exception 'GADS TIKLAMA OZ-SINAV DUSTU: %', r; end if;
    asil := pg_get_functiondef('public.siparis_gads_tiklama_suz()'::regprocedure);

    execute 'create or replace function public.siparis_gads_tiklama_suz() returns trigger language plpgsql as $b$ begin return new; end $b$';
    r := pg_temp.gads_vakalar(); if r = 'TAMAM' then raise exception 'MUTASYON M1 (suzgec bos) YAKALANMADI'; end if; m := m + 1;
    execute asil;

    execute replace(asil, '^[A-Za-z0-9_-]{10,200}$', '^.+$');
    r := pg_temp.gads_vakalar(); if r = 'TAMAM' then raise exception 'MUTASYON M2 (desen hep gecer) YAKALANMADI'; end if; m := m + 1;
    execute asil;

    if pg_temp.gads_vakalar() <> 'TAMAM' then raise exception 'GERI YUKLEME SONRASI OZ-SINAV DUSTU'; end if;
    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  raise notice 'GADS TIKLAMA OZ-SINAV: 8 vaka TAMAM, mutasyon 2/2 KIRMIZI (geri alindi)';
end $$;
drop function pg_temp.gads_vakalar();

-- ÖLÇÜ (uygulama sonrası): anon POST /rest/v1/siparisler gads_tiklama ile → 201 (select hakkı yok, okunamaz);
--   servis: select gads_tiklama, gads_tiklama_zaman from siparisler where siparis_no = '<deneme>'.
