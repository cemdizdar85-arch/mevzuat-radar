-- 10.10.2026 (Cem "1.2.3"): (1) haklı itiraza otomatik teşekkür maili · (2) panelde sorunun kendisi (doğru şık + açıklama) yan yana.
-- tesekkur_mail: edge nobetci-sor 'ekip_nobet' (robot ekibe-sor-nobeti.yml) teşekkür mailini gönderdiği an. Bir kez gider.
-- yonetim_soru_getir(id): yalnız yönetici; kasadan (paket_soru) sorunun metni, şıkları, doğru şık, sade açıklama, teşhis, dayanak.
--   Kasa ölçeri (kasa_cekim tavanı) üyeler içindir; bu yol yalnız yöneticiye açık, tek soru döner.

alter table public.ekibe_soru add column if not exists tesekkur_mail timestamptz;

create or replace function public.yonetim_soru_getir(p_id text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v jsonb;
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  select jsonb_build_object('id', id, 'sinav', sinav, 'ders', ders, 'konu', konu, 'sayfa', sayfa,
           'soru', veri->'soru', 'siklar', veri->'siklar', 'dogru', veri->'dogru', 'sade', veri->'sade',
           'teshis', veri->'teshis', 'dayanak', veri->'dayanak')
    into v from public.paket_soru where id = p_id;
  return v;   -- kasada yoksa null (soru yayından kalkmış ya da kimlik eski)
end $$;
revoke all on function public.yonetim_soru_getir(text) from public, anon;
grant execute on function public.yonetim_soru_getir(text) to authenticated;

create or replace function public.yonetim_ekip_sorulari()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'eposta', eposta, 'soru_id', soru_id, 'soru_kisa', soru_kisa,
            'mesaj', mesaj, 'nobetci_cevap', nobetci_cevap, 'durum', durum, 'cevap', cevap, 'tarih', tarih, 'cevap_tarih', cevap_tarih,
            'cevap_mail', cevap_mail, 'cevap_goruldu', cevap_goruldu, 'itiraz_hakli', itiraz_hakli, 'itiraz_not', itiraz_not,
            'ret_aktarim', ret_aktarim, 'tesekkur_mail', tesekkur_mail)
            order by (durum = 'bekliyor') desc, tarih desc)
          from (select * from public.ekibe_soru order by tarih desc limit 300) x), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_ekip_sorulari() from public, anon;
grant execute on function public.yonetim_ekip_sorulari() to authenticated;
