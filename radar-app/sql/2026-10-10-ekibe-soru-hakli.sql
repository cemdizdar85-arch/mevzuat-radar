-- 10.10.2026 (Cem "1.2.3": panelde 24 saat uyarısı + haklı itiraz sayacı, haklı olan onarım listesine düşsün)
-- itiraz_hakli: null = işaretlenmedi · true = soru gerçekten hatalı · false = soru doğru (öğrenci yanılmış)
-- itiraz_not  : yöneticinin kısa hata notu (≤300). AÇIK DEPOYA gider (elle ret gerekçesi) — öğrenci verisi yazılmaz.
-- ret_aktarim : robot (ekibe-sor-nobeti.yml, arac/ekip-hakli-aktar.js) soruyu <sinav>-elle-ret.json'a yazdığı an.
-- Yalnız yönetici yazar (yonetici_mi); üye bu alanları okuyabilir (kendi satırı) ama değiştiremez.

alter table public.ekibe_soru add column if not exists itiraz_hakli boolean;
alter table public.ekibe_soru add column if not exists itiraz_not text;
alter table public.ekibe_soru add column if not exists ret_aktarim timestamptz;
do $$ begin
  alter table public.ekibe_soru add constraint ekibe_soru_itiraz_not_boy check (itiraz_not is null or length(itiraz_not) <= 300);
exception when duplicate_object then null; end $$;

create or replace function public.yonetim_ekip_hakli(p_id bigint, p_hakli boolean, p_not text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  update public.ekibe_soru
     set itiraz_hakli = p_hakli,
         itiraz_not = case when p_hakli then nullif(left(trim(coalesce(p_not, '')), 300), '') else null end
   where id = p_id;
  if not found then raise exception 'SORU_YOK'; end if;
  return jsonb_build_object('id', p_id, 'itiraz_hakli', p_hakli);
end $$;
revoke all on function public.yonetim_ekip_hakli(bigint, boolean, text) from public, anon;
grant execute on function public.yonetim_ekip_hakli(bigint, boolean, text) to authenticated;

create or replace function public.yonetim_ekip_sorulari()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'eposta', eposta, 'soru_id', soru_id, 'soru_kisa', soru_kisa,
            'mesaj', mesaj, 'nobetci_cevap', nobetci_cevap, 'durum', durum, 'cevap', cevap, 'tarih', tarih, 'cevap_tarih', cevap_tarih,
            'cevap_mail', cevap_mail, 'cevap_goruldu', cevap_goruldu, 'itiraz_hakli', itiraz_hakli, 'itiraz_not', itiraz_not,
            'ret_aktarim', ret_aktarim)
            order by (durum = 'bekliyor') desc, tarih desc)
          from (select * from public.ekibe_soru order by tarih desc limit 300) x), '[]'::jsonb);
end $$;
revoke all on function public.yonetim_ekip_sorulari() from public, anon;
grant execute on function public.yonetim_ekip_sorulari() to authenticated;

create or replace function public.yonetim_nobetci_ozet()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return jsonb_build_object(
    'bugun_soru', (select count(*) from public.nobetci_soru where tarih >= date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_soru',    (select count(*) from public.nobetci_soru where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_usd',     (select coalesce(sum(bedel_usd), 0) from public.nobetci_soru where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ort_usd',    (select coalesce(avg(bedel_usd), 0) from public.nobetci_soru where durum = 'cevaplandi'),
    'kisi',       (select count(distinct user_id) from public.nobetci_soru where tarih >= now() - interval '30 days'),
    'ekip_bekleyen', (select count(*) from public.ekibe_soru where durum = 'bekliyor'),
    'ekip_gec',      (select count(*) from public.ekibe_soru where durum = 'bekliyor' and tarih < now() - interval '24 hours'),
    'ekip_hakli',    (select count(*) from public.ekibe_soru where itiraz_hakli is true),
    'ekip_haksiz',   (select count(*) from public.ekibe_soru where itiraz_hakli is false),
    'ekip_toplam',   (select count(*) from public.ekibe_soru));
end $$;
revoke all on function public.yonetim_nobetci_ozet() from public, anon;
grant execute on function public.yonetim_nobetci_ozet() to authenticated;
