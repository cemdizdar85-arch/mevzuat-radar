-- 10.10.2026 — "Ekibe sor" e-postası boş kalıyordu (ilk soru #1: cevap kaydedildi, öğrenciye mail GİTMEDİ).
-- Kök: ekibe_soru.eposta yalnız edge 'ekip_haber' isteğinde yazılıyordu; istemci o isteği ateşle-unut atıyor, gitmeyince
-- adres hiç yazılmıyor, 'ekip_cevap' 409 dönüyordu. Panelde de "—" görünüyordu.
-- 1) Ekleme anında adres hesaptan yazılır (tetikleyici, security definer; istemcinin yazdığı değer yok sayılır).
-- 2) Boş kalmış eski kayıtlar doldurulur.
-- 3) yonetim_ekip_sorulari() +cevap_mail (panel "e-postayı yeniden gönder" düğmesi için); imza aynı.
-- Edge ekip_cevap da boş adreste hesaptan okur (radar-app/edge/nobetci-sor.ts).

create or replace function public.ekibe_soru_eposta_yaz()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.eposta := (select u.email from auth.users u where u.id = new.user_id);
  return new;
end $$;
revoke all on function public.ekibe_soru_eposta_yaz() from public, anon, authenticated;

drop trigger if exists ekibe_soru_eposta on public.ekibe_soru;
create trigger ekibe_soru_eposta before insert on public.ekibe_soru
  for each row execute function public.ekibe_soru_eposta_yaz();

update public.ekibe_soru e set eposta = u.email
  from auth.users u where u.id = e.user_id and (e.eposta is null or e.eposta = '');

create or replace function public.yonetim_ekip_sorulari()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'eposta', eposta, 'soru_id', soru_id, 'soru_kisa', soru_kisa,
            'mesaj', mesaj, 'nobetci_cevap', nobetci_cevap, 'durum', durum, 'cevap', cevap, 'tarih', tarih, 'cevap_tarih', cevap_tarih,
            'cevap_mail', cevap_mail)
            order by (durum = 'bekliyor') desc, tarih desc)
          from (select * from public.ekibe_soru order by tarih desc limit 300) x), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_ekip_sorulari() from public, anon;
grant execute on function public.yonetim_ekip_sorulari() to authenticated;
