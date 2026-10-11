-- =============================================================================
-- YARIM DENEME HESAPTA (11.10.2026, Cem: "sitede soru çözen çözdüğü yerde kalıyordu … tekrar ordan başlıyordu"
--   → GM önerisi 1 "yarım denemeyi hesaba da yazmak" → "1 ve 2 yap")
--
-- NE: sinav-gibi.html deneme durumunu (cevaplar, kaldığı soru, kalan süre, açılan setin kimlikleri) yalnız tarayıcıda
--     tutuyordu (sg_* anahtarları) → telefonda başlayan bilgisayarda devam edemiyordu. Bu tablo aynı kaydı hesapta tutar:
--     anahtar = tarayıcıdaki anahtarın aynısı (ör. sg_smmm_ders_19_08f427a978, sg_smmm_oz-…), veri = o kayıt.
--     Sana özel deneme setinin tanımı da (yalnız kimlik) 'sg_ozel_set_<no>' anahtarıyla buraya yazılır.
--     Birleştirme sayfada: kayıttaki t (ms) büyük olan kazanır.
-- NEDEN ogrenci_ilerleme DEĞİL: o kaydı uygulama (mobil/uygulama/ilerleme.js) bildiği alanlarla yeniden yazıyor;
--     bilmediği alan sessizce düşerdi.
-- GÜVENLİK: anon HİÇ erişemez; authenticated yalnız kendi satırları (user_id = auth.uid()). Soru metni/cevap anahtarı
--     YOK (yalnız öğrencinin seçtiği harfler ve soru kimlikleri). Satır boyu ≤ 24 KB, kişi başına üst sınır sayfada (60).
-- auth.users'a FK YOK (14.09 dersi: FK'li tablo basarken PostgREST 2-3 dk 503). Hesap silinince satırlar
--     hesabimi_sil() içinde silinir: aşağıdaki tanım = 2026-10-11-prova-sonuc-mail.sql gövdesi + deneme_ilerleme.
-- Uygulanma: sql-uygula.yml (push ile otomatik).
-- =============================================================================

create table if not exists public.deneme_ilerleme (
  user_id    uuid not null default auth.uid(),
  anahtar    text not null check (anahtar ~ '^sg_[a-z0-9_-]{1,80}$'),
  veri       jsonb not null check (octet_length(veri::text) <= 24000),
  guncelleme timestamptz not null default now(),
  primary key (user_id, anahtar)
);

alter table public.deneme_ilerleme enable row level security;

revoke all on public.deneme_ilerleme from anon;
revoke all on public.deneme_ilerleme from authenticated;
grant select, insert, update, delete on public.deneme_ilerleme to authenticated;

drop policy if exists deneme_ilerleme_oku on public.deneme_ilerleme;
drop policy if exists deneme_ilerleme_ekle on public.deneme_ilerleme;
drop policy if exists deneme_ilerleme_guncelle on public.deneme_ilerleme;
drop policy if exists deneme_ilerleme_sil on public.deneme_ilerleme;
create policy deneme_ilerleme_oku on public.deneme_ilerleme for select to authenticated using (user_id = auth.uid());
create policy deneme_ilerleme_ekle on public.deneme_ilerleme for insert to authenticated with check (user_id = auth.uid());
create policy deneme_ilerleme_guncelle on public.deneme_ilerleme for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy deneme_ilerleme_sil on public.deneme_ilerleme for delete to authenticated using (user_id = auth.uid());

-- hesabimi_sil(): 2026-10-11-prova-sonuc-mail.sql ile AYNI gövde + deneme_ilerleme satırı.
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
    delete from public.deneme_ilerleme where user_id = kim;
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

-- ÖLÇÜ (basıldıktan sonra):
--   select polname from pg_policy where polrelid='public.deneme_ilerleme'::regclass;   -- 4 satır
--   anon:  GET /rest/v1/deneme_ilerleme?select=anahtar  -> 401/42501 (erişim yok)
--   select prosrc ~ 'deneme_ilerleme' from pg_proc where proname='hesabimi_sil';      -- true
