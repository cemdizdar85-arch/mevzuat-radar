-- ============================================================================
--  MARKA RAKIP NOBETI (21.08.2026) - "rakibin yeni marka aldigi gun haber ver".
--
--  Kullanici rakibinin UNVANINI ekler; robot (motor/marka-portfoy-hasat.ps1
--  -Rakip) her gun o unvanin TR portfoyunu TMview'den ceker, onceki koşuda
--  gordugu basvuru numaralariyla karsilastirir. YENI kayit cikarsa marka_uyari'ya
--  tip='rakip-yeni' yazar (panel bandi gosterir) + RESEND acikSA mail atar.
--
--  NEDEN UNVAN: TURKPATENT/TMview'de vergi no ile arama yok; sicil sahip ADI
--  uzerinden tutuluyor (20.08 olcumu). Ayrintili not: veri/sql-marka-portfoy.sql
--
--  RLS: herkes YALNIZ kendi rakip listesini gorur/yazar. Robot service_role ile
--  girer (RLS bypass) - baskasinin listesi kimseye gorunmez.
--  Supabase SQL Editor'de bir kez calistir (her komut tek satir - 18.08 dersi).
-- ============================================================================

create table if not exists public.marka_rakip ( id bigint generated always as identity primary key, user_id uuid not null references auth.users(id) on delete cascade, unvan text not null, aktif boolean default true, son_nolar text[], son_sayi int default 0, guncelleme timestamptz, olusturma timestamptz default now(), unique (user_id, unvan) );

alter table public.marka_rakip enable row level security;

drop policy if exists marka_rakip_kendi on public.marka_rakip;
create policy marka_rakip_kendi on public.marka_rakip for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists marka_rakip_aktif_idx on public.marka_rakip(aktif, guncelleme);
