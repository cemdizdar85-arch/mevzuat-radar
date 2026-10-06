-- 2026-10-06 · HATIRLATMA ÇIKIŞI (Cem "1 yap" — seviye testi hatırlatma dizisi)
-- Neden: ogrenci.html rıza kutusu "her e-postada çıkış bağlantısı olur" diyor; otomatik hatırlatma maili tek tıkla
-- durdurulabilmeli. Bağlantıda e-posta YOK: t = HMAC-SHA256(anahtar, 'ret:' + küçük harf e-posta), 64 hex.
-- Gönderen betik (motor/hatirlatma-dizisi.mjs) aynı jetonu hesaplar, tabloda varsa göndermez. Tablo e-posta tutmaz.
-- Erişim: tablo yalnız servis (RLS açık, politika yok); anon/authenticated yalnız hatirlatma_ret(t) çağırabilir
-- (yalnız ekler; okuyamaz, silemez). Jeton tahmin edilemez (anahtar sunucuda), kötü niyetli ekleme en çok
-- başkası adına "çık" olur ki bu da jetonu bilmeyi gerektirir.

create table if not exists public.hatirlatma_ret (
  jeton  text primary key check (jeton ~ '^[0-9a-f]{64}$'),
  zaman  timestamptz not null default now()
);
alter table public.hatirlatma_ret enable row level security;
revoke all on public.hatirlatma_ret from anon, authenticated;

create or replace function public.hatirlatma_ret(p_jeton text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_jeton is null or p_jeton !~ '^[0-9a-f]{64}$' then
    return false;
  end if;
  insert into public.hatirlatma_ret (jeton) values (p_jeton) on conflict (jeton) do nothing;
  return true;
end;
$$;
revoke all on function public.hatirlatma_ret(text) from public;
grant execute on function public.hatirlatma_ret(text) to anon, authenticated;
