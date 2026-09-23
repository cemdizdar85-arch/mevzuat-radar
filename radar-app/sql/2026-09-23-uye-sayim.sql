-- ============================================================================
-- UYE SAYIM FONKSIYONU (23.09.2026 - saatlik uye alarmi, Cem "1 yap")
--
-- NEDEN: 23.09'da e-posta onayi kapatildi (Auth e-posta tavani saatte 30 idi,
-- canli denemede kayitlari tikayacakti). Bedeli: sahte hesap acmak kolaylasti;
-- bot korumasi (captcha) 4 Ekim sonrasina birakildi. Bu fonksiyon saatlik
-- uye alarmina (motor/uye-alarmi.ps1) YALNIZ SAYI verir.
--
-- KISI VERISI DISARI CIKMAZ: e-posta, ad, kimlik dondurulmez. Alarm GitHub
-- Actions'ta kosuyor ve depo PUBLIC; CLAUDE.md bulut guvenligi m.4 geregi
-- kisi verisi Actions'a girmez. Sayim veritabaninin icinde yapilir.
--
-- YETKI: yalniz service_role (robot). anon / authenticated CAGIRAMAZ.
-- DDL: auth.users'a FK YOK, tablo degil fonksiyon (14.09 kesinti tipi degil).
-- ============================================================================
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
    'olcum',           now()
  );
$fn$;

revoke all on function public.uye_sayim() from public;
revoke all on function public.uye_sayim() from anon, authenticated;
grant execute on function public.uye_sayim() to service_role;

-- ============================================================================
-- DOGRULAMA (basildiktan sonra):
--  a) select public.uye_sayim();   -> {"toplam":..,"son_1_saat":..,...} doner
--  b) anon anahtariyla POST /rest/v1/rpc/uye_sayim  -> YETKISIZ olmali
--  c) servis anahtariyla ayni cagri                 -> sayilar doner
-- ============================================================================
