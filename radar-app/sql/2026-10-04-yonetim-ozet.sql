-- ============================================================================
-- YÖNETİM ÖZETİ (04.10.2026, Cem: "ben kendi üyemde ne kadar üye geldiğini, ne kadarı elçi ile geldiğini, hangi
-- staja başlama ile bitirme ile kimin geldiğini bakabileceğim yer olmalı ... bunu ben göreceğim sadece")
--
-- NE YAPAR: yonetim.html'in tek veri kaynağı. Üye listesi (e-posta, kayıt, paket, kaynak, elçi, sınav) + sipariş
-- listesi + elçi listesi tek JSON döner. Özet sayılar sayfada bu listeden hesaplanır.
--
-- ⛔ YETKİ SUNUCUDA (admin-panel şartnamesi: "gizli adres ya da JS'te if(admin) KESİNLİKLE YETERSİZ"):
--    fonksiyon çağıranın yoneticiler tablosunda olup olmadığına bakar, değilse 'YETKI_YOK' hatası verir.
--    yoneticiler tablosu RLS açık + politika yok: kimse okuyamaz/yazamaz, yalnız SQL Editor'den eklenir.
--    anon EXECUTE yok. Sayfanın adresini bilen giriş yapmış başka üye çağırsa da hata alır.
-- ⚠ Yönetici satırı BU DOSYADA DEĞİL (depo herkese açık, e-posta yazılmaz): Cem'e ayrı verilen tek satırla eklenir.
-- GERİ ALMA: drop function public.yonetim_ozet(); drop table public.yoneticiler;
-- ============================================================================
create table if not exists public.yoneticiler (
  user_id  uuid primary key,
  eklenme  timestamptz not null default now()
);
alter table public.yoneticiler enable row level security;
revoke all on public.yoneticiler from anon, authenticated;

create or replace function public.yonetim_ozet()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare sonuc jsonb;
begin
  if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then
    raise exception 'YETKI_YOK' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'olcum', now(),
    'uyeler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'eposta', u.email,
        'kayit', u.created_at,
        'son_giris', u.last_sign_in_at,
        'yol', coalesce(u.raw_user_meta_data->>'kaynak', 'site'),
        'kayit_elci', nullif(u.raw_user_meta_data->>'elci_kodu', ''),
        'paket', p.paket,
        'bitis', p.bitis,
        'dersler', p.dersler,
        'hediye', exists (select 1 from public.paket_hediye h where h.user_id = u.id and h.iptal is null),
        'siparis_elci', (select s.elci_kodu from public.siparisler s
                          where lower(s.email) = lower(u.email) and s.elci_kodu is not null
                          order by s.olusturma desc limit 1),
        'siparis_paket', (select s.paket from public.siparisler s
                           where lower(s.email) = lower(u.email) order by s.olusturma desc limit 1),
        'cozdugu', (select string_agg(distinct o.sinav, ',') from public.ogrenci_sonuc o where o.user_id = u.id)
      ) order by u.created_at desc)
      from auth.users u
      left join public.paket_uyeler p on p.user_id = u.id
    ), '[]'::jsonb),
    'siparisler', coalesce((
      select jsonb_agg(jsonb_build_object(
        'no', s.siparis_no, 'paket', s.paket, 'tutar', s.tutar, 'durum', s.durum,
        'elci', s.elci_kodu, 'indirim', s.indirim_tl, 'ad', s.ad_soyad, 'eposta', s.email,
        'tarih', s.olusturma, 'odendi', s.odendi_tarihi
      ) order by s.olusturma desc)
      from public.siparisler s
    ), '[]'::jsonb),
    'elciler', coalesce((
      select jsonb_agg(jsonb_build_object('kod', e.kod, 'ad', e.ad_soyad, 'aktif', e.aktif) order by e.olusturma)
      from public.elciler e
    ), '[]'::jsonb)
  ) into sonuc;
  return sonuc;
end
$$;

revoke all on function public.yonetim_ozet() from public, anon;
grant execute on function public.yonetim_ozet() to authenticated;

-- Basıldı mı ölçüsü (Success sonrası):
--   select proname, prosecdef from pg_proc where proname = 'yonetim_ozet';   -- 1 satır, prosecdef = true
--   select relrowsecurity from pg_class where relname = 'yoneticiler';      -- true
