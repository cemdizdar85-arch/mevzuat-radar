-- ============================================================================
--  MARKA PORTFOY (20.08.2026) - "Firma unvanindan tum markalari" hatti.
--
--  NEDEN: TURKPATENT/TMview'de VERGI NO ile arama YOK; aranabilen alan SAHIP
--  ADI (unvan). Olculdu (20.08): TMview `fAName` filtresi + autocomplete ile
--  bir firmanin tum TR markalari cekilebiliyor (ARCELIK ANONIM SIRKETI = 1.120).
--  TMview CORS'a KAPALI (olculdu: tetikte.com origin'inden fetch = Failed) ->
--  tarayici dogrudan soramaz; robot (motor/marka-portfoy-hasat.ps1) sorar,
--  sonucu buraya yazar, sayfa buradan okur.
--
--  IKI TABLO:
--   1) marka_portfoy  - UYE firmalarinin portfoyu (panel + gunluk tazeleme)
--   2) marka_talep    - VITRIN (uyeliksiz) sorgu kuyrugu; robot doldurur
--
--  GUVENLIK (alacak kasasi dersi): tablolar RLS acik, disari POLICY YOK.
--  Vitrin ne yazar ne okur - yalnizca iki SECURITY DEFINER fonksiyon uzerinden:
--    marka_talep_ac(unvan, email)  -> jeton   (gunluk tavanli)
--    marka_talep_sonuc(jeton)      -> o talebin durumu + sonucu
--  Supabase SQL Editor'de bir kez calistir (HER KOMUT TEK SATIR olsun - Monaco
--  editorune yapistirirken satir sonu dusebiliyor, 18.08 dersi).
-- ============================================================================

create table if not exists public.marka_portfoy ( user_id uuid not null references auth.users(id) on delete cascade, unvan text not null, varyantlar text[], marka_sayisi int default 0, tescilli int default 0, yenileme_yakin int default 0, ek_surede int default 0, dusmus int default 0, markalar jsonb, guncelleme timestamptz default now(), primary key (user_id, unvan) );

alter table public.marka_portfoy enable row level security;

drop policy if exists marka_portfoy_select_own on public.marka_portfoy;
create policy marka_portfoy_select_own on public.marka_portfoy for select using (auth.uid() = user_id);
-- Yazma yalniz service_role (robot); RLS'i bypass eder, policy gerekmez.

create table if not exists public.marka_talep ( id bigint generated always as identity primary key, jeton text not null unique, unvan text not null, email text, user_id uuid references auth.users(id) on delete set null, durum text not null default 'bekliyor', sonuc jsonb, hata text, created_at timestamptz default now(), islendi_at timestamptz );

alter table public.marka_talep enable row level security;
-- POLICY YOK: anon ne okur ne yazar. Giris yalniz asagidaki iki fonksiyon.

create index if not exists marka_talep_bekleyen_idx on public.marka_talep(durum, created_at);

-- ---------------------------------------------------------------------------
-- 1) Talep ac: vitrin cagirir. Gunluk tavan (kotu niyetli toplu dokum olmasin).
-- ---------------------------------------------------------------------------
create or replace function public.marka_talep_ac(p_unvan text, p_email text default null) returns text language plpgsql security definer set search_path = public as $fn$ declare v_jeton text; v_gunluk int; begin if p_unvan is null or length(btrim(p_unvan)) < 3 or length(p_unvan) > 160 then raise exception 'Unvan 3-160 karakter olmali'; end if; select count(*) into v_gunluk from public.marka_talep where created_at > now() - interval '1 day'; if v_gunluk > 3000 then raise exception 'Gunluk sorgu tavani doldu, yarin tekrar dene'; end if; v_jeton := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-',''); insert into public.marka_talep(jeton, unvan, email, user_id) values (v_jeton, btrim(p_unvan), nullif(btrim(coalesce(p_email,'')),''), auth.uid()); return v_jeton; end; $fn$;

revoke all on function public.marka_talep_ac(text, text) from public;
grant execute on function public.marka_talep_ac(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2) Sonuc oku: yalniz jetonu bilen, yalniz kendi talebini gorur (e-posta gizli).
-- ---------------------------------------------------------------------------
create or replace function public.marka_talep_sonuc(p_jeton text) returns jsonb language plpgsql security definer set search_path = public as $fn$ declare v record; begin select durum, unvan, sonuc, hata into v from public.marka_talep where jeton = p_jeton; if not found then return jsonb_build_object('durum','yok'); end if; return jsonb_build_object('durum', v.durum, 'unvan', v.unvan, 'sonuc', v.sonuc, 'hata', v.hata); end; $fn$;

revoke all on function public.marka_talep_sonuc(text) from public;
grant execute on function public.marka_talep_sonuc(text) to anon, authenticated;
