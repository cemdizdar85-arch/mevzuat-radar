-- ============================================================================
-- UYGULAMA ÜYELİK KAPISI: HESAP SİLME + ADIM SAYACI (26.09.2026, Cem "kur")
--
-- Kurgu (Cem 26.09): uygulamada 3 soru hesapsız → ücretsiz üyelik kapısı → 30 soru → her 10 soruda ara karne
-- → paket. Uygulamaya "Üye ol" geldi (mobil/uygulama/uygulama.js signUp, ogrenci.html ile aynı meta alanları).
--
-- 1) hesabimi_sil(): APPLE KURALI 5.1.1(v) — uygulamada hesap açılabiliyorsa silme de uygulamadan başlatılabilmeli.
--    Oturumdaki kişi YALNIZ KENDİ hesabını siler. auth.users satırı silinince ON DELETE CASCADE'li tablolar
--    (paket_uyeler, ogrenci_sonuc, abonelikler …) kendiliğinden gider; FK'sız ogrenci_ilerleme elle silinir.
--    magaza_siparis (FK yok) KALIR: ödeme kaydı muhasebe/iade için saklanır (kişi kimliği yalnız uuid).
--    Uygulama sonra oturumu kapatır. Tablo/işlev basılmamışsa uygulama eski yola (destek@tetikte.com e-postası) düşer.
--
-- 2) uygulama_olay + olay_say(): huninin hangi adımında kaç kişi kaldığını ölçer — "tahmin etmeyelim, ölçelim".
--    KİŞİSEL VERİ YOK: yalnız (gün, olay adı, platform, sayı). Kimlik, IP, cihaz kimliği TUTULMAZ.
--    Cihaz başına "tek sefer" sayımı istemcide yapılır (localStorage). Olay adları sabit listede; başkası reddedilir.
--    Körlük (yazılı): anonim çağrı açık olduğu için kötü niyetli biri sayıları şişirebilir; bu yüzden sayılar
--    KARAR İÇİN yön gösterir, muhasebe değildir. Satın alma sayısının doğrusu magaza_siparis'tedir.
--
-- auth.users'a YENİ FK YOK (14.09 DDL kesintisi dersi: ddl-postgrest-kesinti). Yine de düşük trafik saatinde bas.
-- ÖNCE ÖLÇÜLDÜ (26.09): hesabimi_sil / olay_say / uygulama_olay depoda yok (grep); canlıda yok varsayılır,
-- "create or replace" / "if not exists" iki kez basılsa da zararsız.
-- ============================================================================

-- ---------- 1) hesap silme ----------
create or replace function public.hesabimi_sil()
returns json
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  kim uuid := auth.uid();
begin
  if kim is null then
    return json_build_object('tamam', false, 'neden', 'giris-yok');
  end if;
  delete from public.ogrenci_ilerleme where user_id = kim;
  delete from auth.users where id = kim;
  return json_build_object('tamam', true);
end;
$$;

revoke all on function public.hesabimi_sil() from public;
revoke all on function public.hesabimi_sil() from anon;
grant execute on function public.hesabimi_sil() to authenticated;

-- ---------- 2) adım sayacı ----------
create table if not exists public.uygulama_olay (
  gun       date not null default (now() at time zone 'Europe/Istanbul')::date,
  olay      text not null,
  platform  text not null,
  sayi      integer not null default 0,
  primary key (gun, olay, platform)
);

alter table public.uygulama_olay enable row level security;
revoke all on public.uygulama_olay from anon;
revoke all on public.uygulama_olay from authenticated;
-- okuma yalnız servis anahtarıyla / SQL Editor'den (politika yok = kimse okuyamaz)

create or replace function public.olay_say(p_olay text, p_platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_olay not in ('ilk_acilis', 'soru_1', 'soru_3', 'kapi', 'uye_ol', 'giris', 'soru_10', 'soru_30',
                    'ara_karne', 'tam_paket_bak', 'paket_ekrani', 'satin_al_bas', 'satin_aldi', 'hesap_sil') then
    return;
  end if;
  if p_platform not in ('android', 'ios', 'web') then
    return;
  end if;
  insert into public.uygulama_olay (olay, platform, sayi) values (p_olay, p_platform, 1)
  on conflict (gun, olay, platform) do update set sayi = public.uygulama_olay.sayi + 1;
end;
$$;

revoke all on function public.olay_say(text, text) from public;
grant execute on function public.olay_say(text, text) to anon, authenticated;

-- ÖLÇÜM (basıldıktan sonra):
--   SQL Editor:  select proname from pg_proc where proname in ('hesabimi_sil','olay_say');   -- 2 satır
--   Dış:  anon POST rpc/olay_say {"p_olay":"ilk_acilis","p_platform":"web"} -> 204
--         anon POST rpc/hesabimi_sil -> 401/42501 (anon yetkisi yok)
--         anon GET  uygulama_olay -> 401/42501
-- HUNİ OKUMA (SQL Editor):
--   select olay, platform, sum(sayi) from public.uygulama_olay where gun >= current_date - 7
--   group by 1,2 order by 2, array_position(array['ilk_acilis','soru_1','soru_3','kapi','uye_ol','giris','soru_10',
--   'ara_karne','soru_30','tam_paket_bak','paket_ekrani','satin_al_bas','satin_aldi','hesap_sil'], olay);
