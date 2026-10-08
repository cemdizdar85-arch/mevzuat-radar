-- ============================================================================
-- HESAP SİLME KÜTÜĞÜ (05.10.2026, Cem: "tümden çözsen bu yolları denemesek")
-- Olay: iPhone uygulamasında (derleme 30) "Hesabımı sil" → OK → hesap silinmedi; iki hesap da
-- duruyor (iki deneme hesabı; adresler 08.10 silindi - depo herkese açık). Aynı gün sunucu dışarıdan üç kez ölçüldü:
-- boş hesap, ogrenci_sonuc'lu hesap ve ogrenci_ilerleme + ogrenci_sonuc'lu hesap → üçü de
-- {"tamam": true} ile silindi. Yani istek telefondan ya hiç gelmiyor ya da hatayla geliyor — görmüyoruz.
--
-- Bu göç fonksiyonun DAVRANIŞINI DEĞİŞTİRMEZ (aynı iki silme, aynı dönüş), yalnız her çağrıyı
-- kütüğe yazar ve silme hatasını yutmak yerine nedenini döndürür:
--   silindi   → {"tamam": true}                                    (eskisiyle aynı)
--   giris-yok → {"tamam": false, "neden": "giris-yok"}             (eskisiyle aynı)
--   hata      → {"tamam": false, "neden": "hata", "hata": "<kod mesaj>"}  (eskiden HTTP 400/500 dönüyordu)
-- Uygulama (derleme 30) üç durumda da tamam != true görünce e-posta yoluna düşer — istemci değişmez.
--
-- KVKK: kütükte e-posta YOK, yalnız uuid (silinen hesabın kimliği zaten artık hiçbir kişiye bağlanmaz).
-- Kütük anon/authenticated'a KAPALI (RLS açık, politika yok); yalnız servis anahtarı okur.
-- auth.users'a FK YOK (14.09 DDL kesintisi dersi).
--
-- ÖLÇÜ (uygulandıktan sonra, dışarıdan):
--   anon POST rpc/hesabimi_sil            -> 401 (yetki yok, değişmedi)
--   deneme hesabı: signup → rpc/hesabimi_sil -> 200 {"tamam": true} + kütükte 'silindi' satırı
--   anon GET hesap_sil_kutuk              -> 401/42501
-- 🚫 GÖRMEZ: telefondan sunucuya HİÇ ulaşmayan istek (kütükte satır olmaması bunu gösterir).
-- ============================================================================

create table if not exists public.hesap_sil_kutuk (
  id     bigserial primary key,
  zaman  timestamptz not null default now(),
  kim    uuid,
  sonuc  text not null,
  hata   text
);

alter table public.hesap_sil_kutuk enable row level security;
revoke all on public.hesap_sil_kutuk from anon, authenticated;

create or replace function public.hesabimi_sil()
returns json
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  kim uuid := auth.uid();
  hata_metni text;
begin
  if kim is null then
    insert into public.hesap_sil_kutuk (kim, sonuc) values (null, 'giris-yok');
    return json_build_object('tamam', false, 'neden', 'giris-yok');
  end if;
  begin
    delete from public.ogrenci_ilerleme where user_id = kim;
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
