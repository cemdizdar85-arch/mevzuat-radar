-- =============================================================================
-- SINAV PROVASI SONUÇ MAİLİ KAYDI (11.10.2026, Cem: "sonucu sonra mail ile atmak mantıklı")
--
-- NE: canli_sonuc ADSIZ kalır (yüzdelik robotu yalnız onu okur). Üye olan katılımcının sayfası
--     teslimde AYRICA bu tabloya tek satır bırakır: üye kimliği + doğru/yanlış/boş + ders ders özet.
--     Prova kapanıp yüzdelik açıklanınca prova-sonuc-mail uç fonksiyonu bu tablodan okur, üyenin
--     e-postasını auth.users'tan SUNUCUDA bulur, kurumsal kabuklu sonuç maili yollar, gonderim damgalar.
-- GÜVENLİK: anon/authenticated YALNIZ INSERT (gonderim boş olmak şartıyla); kimse SELECT/UPDATE/DELETE
--     edemez. Okuma yalnız servis anahtarlı uç fonksiyonda. E-posta adresi bu tabloda TUTULMAZ.
--     uye_id tarayıcıdan gelir (cihazdaki oturum kaydı; sınav bitiminde Auth'a istek atılmaz - 5k yük
--     kuralı). Başkası adına satır yazmak o üyenin uuid'sini bilmeyi gerektirir; olmayan uuid'e mail gitmez.
--     (uye_id, oturum) tekil: aynı üyeye aynı prova için tek satır, tek mail.
-- auth.users'a FK YOK (14.09 dersi: FK'li tablo basarken PostgREST 2-3 dk 503). Hesap silinince satır
--     hesabimi_sil() içinde silinir (aşağıda, 2026-10-08 tanımı + bu tablo).
-- Uygulanma: sql-uygula.yml (push ile otomatik).
-- =============================================================================

create table if not exists public.prova_sonuc_mail (
  id        bigserial primary key,
  olusturma timestamptz not null default now(),
  oturum    text not null check (oturum ~ '^(SGS|YET)-[0-9]{4}$'),
  uye_id    uuid not null,
  dogru     int not null check (dogru between 0 and 200),
  yanlis    int not null check (yanlis between 0 and 200),
  bos       int not null check (bos between 0 and 200),
  ders      jsonb check (ders is null or (jsonb_typeof(ders) = 'array' and octet_length(ders::text) <= 3000)),
  gonderim  timestamptz,
  unique (uye_id, oturum)
);

alter table public.prova_sonuc_mail enable row level security;

revoke all on public.prova_sonuc_mail from anon;
revoke all on public.prova_sonuc_mail from authenticated;
grant insert on public.prova_sonuc_mail to anon, authenticated;
grant usage on sequence public.prova_sonuc_mail_id_seq to anon, authenticated;

drop policy if exists prova_sonuc_mail_ekle on public.prova_sonuc_mail;
create policy prova_sonuc_mail_ekle on public.prova_sonuc_mail
  for insert to anon, authenticated with check (gonderim is null);

-- hesabimi_sil(): 2026-10-08-hesap-sil-eksik-tablolar.sql ile AYNI gövde + prova_sonuc_mail satırı.
create or replace function public.hesabimi_sil()
returns json
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  kim uuid := auth.uid();
  posta text;
  hata_metni text;
begin
  if kim is null then
    insert into public.hesap_sil_kutuk (kim, sonuc) values (null, 'giris-yok');
    return json_build_object('tamam', false, 'neden', 'giris-yok');
  end if;
  begin
    select lower(email) into posta from auth.users where id = kim;
    delete from public.nobetci_soru where user_id = kim;
    delete from public.ekibe_soru where user_id = kim or (posta is not null and lower(eposta) = posta);
    delete from public.uye_cihazlar where user_id = kim;
    delete from public.ogrenci_ilerleme where user_id = kim;
    delete from public.prova_sonuc_mail where uye_id = kim;
    delete from auth.users where id = kim;
  exception when others then
    hata_metni := sqlstate || ' ' || sqlerrm;
    insert into public.hesap_sil_kutuk (kim, sonuc, hata) values (kim, 'hata', hata_metni);
    return json_build_object('tamam', false, 'neden', 'hata', 'hata', hata_metni);
  end;
  insert into public.hesap_sil_kutuk (kim, sonuc) values (kim, 'silindi');
  return json_build_object('tamam', true);
end;
$$;

revoke all on function public.hesabimi_sil() from public;
revoke all on function public.hesabimi_sil() from anon;
grant execute on function public.hesabimi_sil() to authenticated;
