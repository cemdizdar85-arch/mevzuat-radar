-- ============================================================================
--  TESLIM TEYIDI (27.08.2026)  —  Supabase SQL Editor'de calistir. Tek seferlik.
--
--  NEDEN: 27.08 rakip turunda olculdu — konkordata.com ve konkordatoilanlari.com
--  ZATEN e-posta + SMS (+ telefon/WhatsApp) diyor. Yani "kanal" farklilasma
--  DEGIL. Hicbirinde OLMAYAN sey: bildirimin ULASTIGINI teyit etmek ve teyit
--  gelene kadar kanal yukselterek tekrar etmek. Alacakli icin fark buradadir:
--  IIK m.299'da sure ILAN TARIHINDEN isler (15 gun), m.219'da 1 ay — mail spam
--  kutusuna dustuyse "gonderdik" demenin hicbir kiymeti yoktur.
--
--  BU DOSYA YALNIZ ALTYAPIDIR. Merdiveni motor/teslim-teyidi.ps1 yurutur.
--  Site metnine tek kelime yazilmadan once hat calisir hale gelir (yapmadigimiz
--  isi satmama kurali).
--
--  KAPSAM KARARI: merdiven YALNIZ tur='alacak' uyarilarina uygulanir. Ihale/RG/
--  firsat uyarisi icin ustuste bildirim atmak kanali yakar ve kullaniciyi
--  kaciririr; onlarda tek ozet mail yeterlidir (mevcut davranis korunur).
-- ============================================================================

-- ---------------------------------------------------------------- BOLUM 1/3
--  ALANLAR
alter table public.firma_uyarilari
  add column if not exists teyit_token     uuid not null default gen_random_uuid(),
  add column if not exists teyit_at        timestamptz,
  add column if not exists teyit_kanal     text,
  add column if not exists son_bildirim_at timestamptz,
  add column if not exists bildirim_sayisi int not null default 0,
  -- kanal_gecmisi: [{"n":1,"kanal":"mail","at":"2026-08-27T09:00:00Z","sonuc":"ok"}]
  add column if not exists kanal_gecmisi   jsonb not null default '[]'::jsonb;

create unique index if not exists firma_uyarilari_teyit_token_idx
  on public.firma_uyarilari(teyit_token);

-- Merdiven sorgusu: teyit edilmemis alacak uyarilari, en eskiden yeniye.
create index if not exists firma_uyarilari_merdiven_idx
  on public.firma_uyarilari(tur, teyit_at, bildirim_sayisi);

-- ---------------------------------------------------------------- BOLUM 2/3
--  TEYIT UCU (anon cagirabilir — jetonu olan kisi teyit eder)
--
--  🔴 TASARIM KARARI, SESSIZ GECILMESIN: bu uc SAYFA ACILISINDA CAGRILMAZ,
--  yalnizca kullanici dugmeye BASINCA cagrilir. Sebep: Outlook Safe Links,
--  Gmail ve kurumsal antivirusler maildeki her baglantiyi kendiliginden
--  ACAR. Acilista teyit alsaydik, robotun taradigi link uyariyi "okundu"
--  isaretler ve merdiven daha ilk basamakta susardi — yani ozelligin
--  tamami sessizce ise yaramaz hale gelirdi.
--
--  Jeton uuid v4'tur (tahmin edilemez) ve YALNIZ o uyarinin kendi basligini
--  geri dondurur; baska hicbir veri sizmaz (gizli kasa kurali).
create or replace function public.uyari_teyit(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  r record;
  onceden boolean;
begin
  select id, baslik, tur, url, teyit_at
    into r
    from public.firma_uyarilari
   where teyit_token = p_token;

  if not found then
    return jsonb_build_object('ok', false, 'sebep', 'BULUNAMADI');
  end if;

  onceden := (r.teyit_at is not null);

  if not onceden then
    update public.firma_uyarilari
       set teyit_at = now(), teyit_kanal = 'link', okundu = true
     where id = r.id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'baslik', r.baslik,
    'tur', r.tur,
    'url', r.url,
    'zatenTeyitli', onceden
  );
end;
$fn$;

revoke all on function public.uyari_teyit(uuid) from public;
grant execute on function public.uyari_teyit(uuid) to anon, authenticated;

-- ---------------------------------------------------------------- BOLUM 3/3
--  DURUM UCU (yalniz okur, teyit ETMEZ) — sayfa acilista bunu cagirir, boylece
--  "zaten teyit etmissin" bilgisini dugmeye basmadan gosterebiliriz.
create or replace function public.uyari_teyit_durum(p_token uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce((
    select jsonb_build_object(
      'ok', true,
      'baslik', baslik,
      'tur', tur,
      'url', url,
      'zatenTeyitli', (teyit_at is not null),
      'bildirimSayisi', bildirim_sayisi
    )
    from public.firma_uyarilari
    where teyit_token = p_token
  ), jsonb_build_object('ok', false, 'sebep', 'BULUNAMADI'))
$fn$;

revoke all on function public.uyari_teyit_durum(uuid) from public;
grant execute on function public.uyari_teyit_durum(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- KOSTUKTAN SONRA TEYIT (ayni editorde):
--   select column_name from information_schema.columns
--    where table_name='firma_uyarilari' and column_name like 'teyit%';
--   -> teyit_token, teyit_at, teyit_kanal donmelidir.
--   select public.uyari_teyit_durum('00000000-0000-0000-0000-000000000000');
--   -> {"ok": false, "sebep": "BULUNAMADI"} donmelidir.
-- ---------------------------------------------------------------------------
