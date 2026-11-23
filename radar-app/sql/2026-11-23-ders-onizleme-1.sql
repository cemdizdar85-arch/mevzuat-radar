-- ============================================================================
--  DERS ÖNİZLEMESİ 3 → 1 SORU  ·  23.11.2026 (aynı gün, site kolu)
--  Cem 23.11 (69 açık soru sorusuna): "Dersi başına 1 soru" → 23 derste toplam 23 soru. Fonksiyonun geri kalanı
--  2026-11-23-ders-onizleme.sql ile AYNEN (yol süzgeci, KGK kapalı, IP 3.000/10 dk, kasa ölçerine yazmaz).
-- ============================================================================
create or replace function public.kasa_onizleme(p_sayfa text)
returns table(id text, sira integer, veri jsonb)
language plpgsql
security definer
set search_path = public
as $fn$
declare ip text;
begin
  if p_sayfa is null or p_sayfa !~ '^kaydir/(sgs|smmm)/[a-z0-9-]+\.html$' then return; end if;
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('onizleme:' || trim(ip), 3000, 600) then
    raise exception 'ONIZLEME_SINIR' using errcode = 'P0001';
  end if;
  return query
    select s.id, s.sira, s.veri from public.paket_soru s
     where s.sayfa = p_sayfa
     order by s.sira asc
     limit 1;
end $fn$;
revoke all on function public.kasa_onizleme(text) from public, anon, authenticated;
grant execute on function public.kasa_onizleme(text) to anon, authenticated;

do $t$
declare n int;
begin
  select count(*) into n from public.kasa_onizleme('kaydir/sgs/turkce.html');
  if n <> 1 then raise exception 'OLCU: sgs turkce onizleme % satir (beklenen 1)', n; end if;
  select count(*) into n from public.kasa_onizleme('kaydir/smmm/hukuk.html');
  if n <> 1 then raise exception 'OLCU: smmm hukuk onizleme % satir (beklenen 1)', n; end if;
  select count(*) into n from public.kasa_onizleme('kaydir/kgk/bankacilik.html');
  if n <> 0 then raise exception 'OLCU: kgk acildi'; end if;
  if not has_function_privilege('anon', 'public.kasa_onizleme(text)', 'execute') then raise exception 'OLCU: anon kapali'; end if;
  raise notice 'DERS ONIZLEME 1 SORU OZ-SINAV: 4 vaka TAMAM';
end $t$;
