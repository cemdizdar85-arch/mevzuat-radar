-- ============================================================================
-- NÖBETÇİYE SOR + EKİBE SOR (04.10.2026, Cem: "nöbetçi sor diye düğme olacak, bu önemli" + "GM önerilerini yap":
-- Opus 5.5, kişi başı günde 10 soru, aylık 100 USD tavan; yapay zekâ olduğu AÇIK yazılır; yetmezse "Ekibe sor" insan cevabı)
--
-- nobetci_soru : her Nöbetçi çağrısının kaydı (bedel, token, cevap). Yazan YALNIZ edge fonksiyonu (servis anahtarı).
--               Üye kendi satırlarını okur (geçmiş). Günlük sınır + aylık tavan bu tablodan hesaplanır.
-- ekibe_soru   : "Ekibe sor" - üye kendi sorusunu ekler (günde en çok 5), kendi sorularını okur; cevabı yönetim yazar.
-- nobetci_durum(uid) : edge için (servis) - bugün kaç soru, bu ay kaç USD.
-- yonetim_ekip_sorulari() / yonetim_ekip_cevapla(id, cevap) / yonetim_nobetci_ozet() : yonetim.html (yalnız yönetici).
-- auth.users'a yabancı anahtar YOK. anon hiçbir şeye erişemez. Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create table if not exists public.nobetci_soru (
  id            bigint generated always as identity primary key,
  user_id       uuid not null,
  soru_id       text not null check (length(soru_id) between 3 and 120),
  mesaj         text not null check (length(mesaj) between 1 and 1000),
  cevap         text,
  durum         text not null default 'cevaplandi' check (durum in ('cevaplandi', 'hata', 'reddedildi')),
  model         text,
  girdi_token   integer not null default 0,
  cikti_token   integer not null default 0,
  bedel_usd     numeric(10,5) not null default 0,
  tarih         timestamptz not null default now()
);
create index if not exists nobetci_soru_kisi_tarih on public.nobetci_soru (user_id, tarih desc);
create index if not exists nobetci_soru_tarih on public.nobetci_soru (tarih);
alter table public.nobetci_soru enable row level security;
revoke all on public.nobetci_soru from anon, authenticated;
grant select on public.nobetci_soru to authenticated;
drop policy if exists nobetci_soru_oku on public.nobetci_soru;
create policy nobetci_soru_oku on public.nobetci_soru for select to authenticated using (user_id = auth.uid());

create table if not exists public.ekibe_soru (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid(),
  eposta        text,
  soru_id       text not null check (length(soru_id) between 3 and 120),
  soru_kisa     text check (soru_kisa is null or length(soru_kisa) <= 600),
  mesaj         text not null check (length(mesaj) between 3 and 2000),
  nobetci_cevap text check (nobetci_cevap is null or length(nobetci_cevap) <= 4000),
  durum         text not null default 'bekliyor' check (durum in ('bekliyor', 'cevaplandi')),
  cevap         text check (cevap is null or length(cevap) <= 4000),
  cevap_tarih   timestamptz,
  haber_mail    timestamptz,
  cevap_mail    timestamptz,
  tarih         timestamptz not null default now()
);
create index if not exists ekibe_soru_durum on public.ekibe_soru (durum, tarih desc);
alter table public.ekibe_soru enable row level security;
revoke all on public.ekibe_soru from anon, authenticated;
grant select, insert on public.ekibe_soru to authenticated;
drop policy if exists ekibe_soru_oku on public.ekibe_soru;
drop policy if exists ekibe_soru_ekle on public.ekibe_soru;
create policy ekibe_soru_oku on public.ekibe_soru for select to authenticated using (user_id = auth.uid());
-- ekleme: yalnız kendi adına, bekliyor durumunda, cevapsız ve son 24 saatte en çok 5
create policy ekibe_soru_ekle on public.ekibe_soru for insert to authenticated
  with check (user_id = auth.uid() and durum = 'bekliyor' and cevap is null and cevap_tarih is null
              and haber_mail is null and cevap_mail is null
              and (select count(*) from public.ekibe_soru e where e.user_id = auth.uid() and e.tarih > now() - interval '1 day') < 5);

create or replace function public.nobetci_durum(p_uid uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'bugun', (select count(*) from public.nobetci_soru where user_id = p_uid and durum = 'cevaplandi'
                and tarih >= date_trunc('day', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),
    'ay_usd', (select coalesce(sum(bedel_usd), 0) from public.nobetci_soru
                where tarih >= date_trunc('month', now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'));
$$;
revoke all on function public.nobetci_durum(uuid) from public, anon, authenticated;

create or replace function public.yonetim_ekip_sorulari()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'eposta', eposta, 'soru_id', soru_id, 'soru_kisa', soru_kisa,
            'mesaj', mesaj, 'nobetci_cevap', nobetci_cevap, 'durum', durum, 'cevap', cevap, 'tarih', tarih, 'cevap_tarih', cevap_tarih)
            order by (durum = 'bekliyor') desc, tarih desc)
          from (select * from public.ekibe_soru order by tarih desc limit 300) x), '[]'::jsonb);
end $$;

create or replace function public.yonetim_ekip_cevapla(p_id bigint, p_cevap text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.yonetici_mi() then raise exception 'YETKI_YOK' using errcode = '42501'; end if;
  if coalesce(length(trim(p_cevap)), 0) < 3 then raise exception 'CEVAP_KISA'; end if;
  update public.ekibe_soru set cevap = left(trim(p_cevap), 4000), durum = 'cevaplandi', cevap_tarih = now() where id = p_id;
  if not found then raise exception 'SORU_YOK'; end if;
  return jsonb_build_object('id', p_id, 'durum', 'cevaplandi');
end $$;

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
    'ekip_bekleyen', (select count(*) from public.ekibe_soru where durum = 'bekliyor'));
end $$;

revoke all on function public.yonetim_ekip_sorulari() from public, anon;
revoke all on function public.yonetim_ekip_cevapla(bigint, text) from public, anon;
revoke all on function public.yonetim_nobetci_ozet() from public, anon;
grant execute on function public.yonetim_ekip_sorulari() to authenticated;
grant execute on function public.yonetim_ekip_cevapla(bigint, text) to authenticated;
grant execute on function public.yonetim_nobetci_ozet() to authenticated;
