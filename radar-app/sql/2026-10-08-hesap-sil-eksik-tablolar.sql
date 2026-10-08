-- =============================================================================
-- "HESABIMI SİL" EKSİK TABLOLAR (08.10.2026)
-- Yasal tarama (Cem "mevzuat süreleri + kodu düzelt"): nobetci_soru, ekibe_soru ve uye_cihazlar tablolarının
-- auth.users'a yabancı anahtarı (on delete cascade) YOK; hesabimi_sil() yalnız ogrenci_ilerleme + auth.users
-- siliyordu -> hesabı silinen üyenin Nöbetçi mesajları, Ekibe sor kayıtları (e-posta dahil) ve cihaz kayıtları kalıyordu.
-- Bu dosya fonksiyonu AYNI İMZA ve aynı kütükle yeniden tanımlar; üç tablo da silinir.
-- siparisler BİLEREK silinmez: fatura/sipariş kaydı yasal saklama (TTK m.82, VUK m.253) - motor/saklama-robotu.js 10 yılda siler.
-- Önceki tanım (yedek): radar-app/sql/2026-10-05-hesap-sil-kutuk.sql (uygulanmış, değiştirilmez).
-- Uygulanma: sql-uygula.yml (push ile otomatik).
-- =============================================================================

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
