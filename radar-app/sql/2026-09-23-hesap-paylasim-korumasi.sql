-- ============================================================================
-- HESAP PAYLASIM KORUMASI (23.09.2026, Cem "1.2.3 ucunu de yapalim, acilisi beklemeyelim")
--
-- NEDEN: paket alan birinin sifresini baskalarina vermesi. Profesyonel platformlarin
-- katmanlari: (1) tek aktif ekran, (2) en fazla 3 kayitli cihaz + ayda 2 cikarma,
-- (3) filigran (istemci), (4) anormallik alarmi. Bu dosya 1, 2 ve 4'un veritabani ayagi.
-- (Supabase "Enforce single session per user" 23.09'da ACILDI - taban katman, eski
--  cihaz en gec 1 saatte duser. Bu dosya PAKETLI icerikte ANINDA kontrol verir.)
--
-- KAPSAM: yalniz PAKETLI icerik sayfalari (paket-kapisi.js aktif paket gorunce cagirir).
-- Ucretsiz uye, canli deneme, radar/evrak/marka ETKILENMEZ.
--
-- ⚠ DURUST SINIR: soru icerigi bugun sayfa dosyasinda acik (Adim 2 kasasi gelene kadar).
-- Bu koruma olagan paylasimi durdurur; teknik bilgisi olan birini durduramaz.
--
-- DDL NOTU (14.09 dersi): auth.users'a FK YOK - FK'li tablo basarken PostgREST 2-3 dk
-- 503 vermisti. user_id duz uuid; silinen uyenin artigi zararsizdir.
-- Tablolarda RLS ACIK + politika YOK: dogrudan okuma/yazma kapali, erisim yalniz
-- asagidaki SECURITY DEFINER fonksiyonlarla ve yalniz kendi kaydina (auth.uid()).
-- ============================================================================

create table if not exists public.uye_cihazlar (
  user_id     uuid not null,
  cihaz_id    text not null check (char_length(cihaz_id) between 8 and 64),
  etiket      text not null default '' check (char_length(etiket) <= 60),
  ilk_gorulme timestamptz not null default now(),
  son_gorulme timestamptz not null default now(),
  primary key (user_id, cihaz_id)
);
alter table public.uye_cihazlar enable row level security;

create table if not exists public.uye_ekran (
  user_id  uuid primary key,
  cihaz_id text not null,
  devralma timestamptz not null default now()
);
alter table public.uye_ekran enable row level security;

create table if not exists public.uye_cihaz_olay (
  id       bigint generated always as identity primary key,
  user_id  uuid not null,
  cihaz_id text not null,
  olay     text not null check (olay in ('eklendi','cikarildi','devraldi','sinir')),
  zaman    timestamptz not null default now()
);
alter table public.uye_cihaz_olay enable row level security;
create index if not exists uye_cihaz_olay_uye_zaman on public.uye_cihaz_olay (user_id, zaman desc);
create index if not exists uye_cihaz_olay_zaman     on public.uye_cihaz_olay (zaman desc);

-- ---------------------------------------------------------------------------
-- cihaz_kontrol: tek cagri = cihaz kaydi + 3 cihaz siniri + aktif ekran
--   p_devral=true  -> sayfa acilisi: bu cihaz ekrani ALIR (en yeni cihaz kazanir)
--   p_devral=false -> periyodik yoklama: ekran baskasindaysa 'baska_ekran' doner
-- donus.durum: tamam | baska_ekran | cihaz_siniri | oturum_yok
-- ---------------------------------------------------------------------------
create or replace function public.cihaz_kontrol(p_cihaz text, p_etiket text default '', p_devral boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_uid    uuid := auth.uid();
  v_var    boolean;
  v_sayi   int;
  v_ekran  record;
  v_etiket text := left(coalesce(p_etiket, ''), 60);
begin
  if v_uid is null then
    return jsonb_build_object('durum', 'oturum_yok');
  end if;
  if p_cihaz is null or char_length(p_cihaz) not between 8 and 64 then
    return jsonb_build_object('durum', 'gecersiz');
  end if;

  select exists(select 1 from public.uye_cihazlar where user_id = v_uid and cihaz_id = p_cihaz) into v_var;
  if v_var then
    update public.uye_cihazlar set son_gorulme = now(), etiket = v_etiket
     where user_id = v_uid and cihaz_id = p_cihaz;
  else
    select count(*) into v_sayi from public.uye_cihazlar where user_id = v_uid;
    if v_sayi >= 3 then
      insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'sinir');
      return jsonb_build_object(
        'durum', 'cihaz_siniri', 'sinir', 3,
        'cihazlar', coalesce((select jsonb_agg(jsonb_build_object('etiket', etiket, 'son_gorulme', son_gorulme) order by son_gorulme desc)
                              from public.uye_cihazlar where user_id = v_uid), '[]'::jsonb));
    end if;
    insert into public.uye_cihazlar (user_id, cihaz_id, etiket) values (v_uid, p_cihaz, v_etiket);
    insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'eklendi');
  end if;

  select e.cihaz_id, e.devralma, c.etiket into v_ekran
    from public.uye_ekran e
    left join public.uye_cihazlar c on c.user_id = e.user_id and c.cihaz_id = e.cihaz_id
   where e.user_id = v_uid;

  if not found then
    insert into public.uye_ekran (user_id, cihaz_id) values (v_uid, p_cihaz);
    return jsonb_build_object('durum', 'tamam');
  end if;
  if v_ekran.cihaz_id = p_cihaz then
    return jsonb_build_object('durum', 'tamam');
  end if;
  if p_devral then
    update public.uye_ekran set cihaz_id = p_cihaz, devralma = now() where user_id = v_uid;
    insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_cihaz, 'devraldi');
    return jsonb_build_object('durum', 'tamam');
  end if;
  return jsonb_build_object('durum', 'baska_ekran', 'aktif_etiket', coalesce(v_ekran.etiket, 'baska bir cihaz'));
end;
$fn$;

-- ---------------------------------------------------------------------------
-- cihazlarim: uyenin kendi cihaz listesi + bu ayki cikarma hakki
-- ---------------------------------------------------------------------------
create or replace function public.cihazlarim(p_cihaz text default '')
returns jsonb
language sql
stable
security definer
set search_path = ''
as $fn$
  select jsonb_build_object(
    'sinir', 3,
    'cikarma_hakki', greatest(0, 2 - (select count(*) from public.uye_cihaz_olay
                                       where user_id = auth.uid() and olay = 'cikarildi'
                                         and zaman > now() - interval '30 days')),
    'cihazlar', coalesce((select jsonb_agg(jsonb_build_object(
                    'cihaz_id', c.cihaz_id, 'etiket', c.etiket,
                    'ilk_gorulme', c.ilk_gorulme, 'son_gorulme', c.son_gorulme,
                    'bu_cihaz', c.cihaz_id = coalesce(p_cihaz, ''),
                    'aktif_ekran', exists(select 1 from public.uye_ekran e where e.user_id = c.user_id and e.cihaz_id = c.cihaz_id)
                  ) order by c.son_gorulme desc)
                  from public.uye_cihazlar c where c.user_id = auth.uid()), '[]'::jsonb)
  );
$fn$;

-- ---------------------------------------------------------------------------
-- cihaz_cikar: uye kendi cihazini cikarir (30 gunde en fazla 2)
-- ---------------------------------------------------------------------------
create or replace function public.cihaz_cikar(p_hedef text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_uid uuid := auth.uid();
  v_cikan int;
  v_ilk timestamptz;
begin
  if v_uid is null then return jsonb_build_object('durum', 'oturum_yok'); end if;
  select count(*), min(zaman) into v_cikan, v_ilk from public.uye_cihaz_olay
   where user_id = v_uid and olay = 'cikarildi' and zaman > now() - interval '30 days';
  if v_cikan >= 2 then
    return jsonb_build_object('durum', 'aylik_sinir', 'yeniden', v_ilk + interval '30 days');
  end if;
  delete from public.uye_cihazlar where user_id = v_uid and cihaz_id = p_hedef;
  if not found then return jsonb_build_object('durum', 'bulunamadi'); end if;
  delete from public.uye_ekran where user_id = v_uid and cihaz_id = p_hedef;
  insert into public.uye_cihaz_olay (user_id, cihaz_id, olay) values (v_uid, p_hedef, 'cikarildi');
  return jsonb_build_object('durum', 'tamam');
end;
$fn$;

revoke all on function public.cihaz_kontrol(text, text, boolean) from public, anon;
revoke all on function public.cihazlarim(text) from public, anon;
revoke all on function public.cihaz_cikar(text) from public, anon;
grant execute on function public.cihaz_kontrol(text, text, boolean) to authenticated;
grant execute on function public.cihazlarim(text) to authenticated;
grant execute on function public.cihaz_cikar(text) to authenticated;

-- ---------------------------------------------------------------------------
-- uye_sayim (alarm) GENISLEDI: paylasim belirtileri eklendi - yine YALNIZ SAYI.
--   paylasim_supheli : son 24 saatte ekrani 8+ kez el degistiren uye sayisi
--   cihaz_siniri_24s : son 24 saatte 4. cihazla girmeye calisan uye sayisi
-- Eskitir: 2026-09-23-uye-sayim.sql icindeki uye_sayim() (alanlar korunur, yenileri eklenir).
-- ---------------------------------------------------------------------------
create or replace function public.uye_sayim()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $fn$
  select jsonb_build_object(
    'toplam',          (select count(*) from auth.users),
    'son_1_saat',      (select count(*) from auth.users where created_at > now() - interval '1 hour'),
    'son_24_saat',     (select count(*) from auth.users where created_at > now() - interval '24 hours'),
    'en_yogun_dakika', coalesce((select max(d.n) from (
                          select count(*) as n
                          from auth.users
                          where created_at > now() - interval '1 hour'
                          group by date_trunc('minute', created_at)
                        ) d), 0),
    'paylasim_supheli', (select count(*) from (
                          select user_id from public.uye_cihaz_olay
                          where olay = 'devraldi' and zaman > now() - interval '24 hours'
                          group by user_id having count(*) >= 8) p),
    'cihaz_siniri_24s', (select count(distinct user_id) from public.uye_cihaz_olay
                          where olay = 'sinir' and zaman > now() - interval '24 hours'),
    'olcum',           now()
  );
$fn$;

revoke all on function public.uye_sayim() from public;
revoke all on function public.uye_sayim() from anon, authenticated;
grant execute on function public.uye_sayim() to service_role;

select public.uye_sayim() as dogrulama;

-- ============================================================================
-- DOGRULAMA (basildiktan sonra):
--  a) son satir: uye_sayim() artik 'paylasim_supheli' ve 'cihaz_siniri_24s' de dondurur
--  b) anon anahtarla rpc/cihaz_kontrol -> YETKISIZ olmali
--  c) oturumlu uyeyle rpc/cihaz_kontrol -> {"durum":"tamam"}
--  d) tablolar anon/authenticated'a DOGRUDAN kapali (RLS, politika yok)
-- ============================================================================
