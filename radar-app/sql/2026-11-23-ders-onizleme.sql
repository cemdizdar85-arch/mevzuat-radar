-- ============================================================================
--  DERS SAYFASI ÖNİZLEMESİ — ZİYARETÇİYE İLK 3 SORU  ·  23.11.2026  (site kolu)
--
--  Cem 23.11 ("Ders sayfasında ziyaretçiye önizleme: kilit yerine ilk 3 soru açık olsun … bunları yapalım"):
--  ders rafından ve aramadan gelen paketsiz kişi tam ekran kilit görüyordu (denetim C23). Artık o dersin İLK 3 sorusu
--  (paket_soru.sira en küçük 3 satır, HERKESE AYNI 3) açılır, sonra "devamı pakette" kartı.
--
--  NE YAPAR: kasa_onizleme(p_sayfa) (A) — sayfa kaydir/sgs/… ya da kaydir/smmm/… ise (KGK açılmadı, dışarıda) o sayfanın ilk 3
--  sorusunu (id, sira, veri) döner. IP başına 3.000 / 10 dk (kanit_sorusu ile aynı: reklam trafiği operatör ortak IP'sinden gelir;
--  içerik zaten sabit 3 soru, sınır yalnız veritabanını korur). Kasa ölçerine (kasa_cekim) yazmaz: üye tavanına sayılmaz.
--  🚫 GÖRMEZ: soruların hangisinin "iyi vitrin" olduğu (sıra = basım sırası) · ders başına 3 × ~23 ders ≈ 70 soru herkese açık olur
--     (Cem kararı; banka 8.600+ soru) · bilerek sayfa sayfa toplayan kişi bu 70 soruyu alır.
--  Push ile otomatik (sql-uygula.yml). Sonunda göç içi öz-sınav (yalnız okur).
-- ============================================================================

create or replace function public.kasa_onizleme(p_sayfa text)
returns table(id text, sira integer, veri jsonb)
language plpgsql
-- volatile: rate_limit_check yazar (stable olamaz)
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
     limit 3;
end $fn$;
revoke all on function public.kasa_onizleme(text) from public, anon, authenticated;
grant execute on function public.kasa_onizleme(text) to anon, authenticated;

do $t$
declare n int; m int; ilk text; ilk2 text;
begin
  select count(*) into n from public.kasa_onizleme('kaydir/sgs/turkce.html');
  if n <> 3 then raise exception 'OLCU: sgs turkce onizleme % satir (beklenen 3)', n; end if;
  select count(*) into n from public.kasa_onizleme('kaydir/smmm/hukuk.html');
  if n <> 3 then raise exception 'OLCU: smmm hukuk onizleme % satir (beklenen 3)', n; end if;
  select count(*) into n from public.kasa_onizleme('kaydir/kgk/bankacilik.html');
  if n <> 0 then raise exception 'OLCU: kgk acildi'; end if;
  select count(*) into n from public.kasa_onizleme('kaydir/sgs/../smmm/hukuk.html');
  if n <> 0 then raise exception 'OLCU: yol kacamagi acildi'; end if;
  select count(*) into m from public.paket_soru where sayfa = 'kaydir/sgs/turkce.html';
  if m < 4 then raise exception 'OLCU: turkce bankasi 4 den az, sinav anlamsiz'; end if;
  select o.id into ilk from public.kasa_onizleme('kaydir/sgs/turkce.html') o order by o.sira limit 1;
  select s.id into ilk2 from public.paket_soru s where s.sayfa = 'kaydir/sgs/turkce.html' order by s.sira limit 1;
  if ilk is distinct from ilk2 then raise exception 'OLCU: ilk soru sirasi tutmadi'; end if;
  if not has_function_privilege('anon', 'public.kasa_onizleme(text)', 'execute') then raise exception 'OLCU: anon kapali'; end if;
  raise notice 'DERS ONIZLEME OZ-SINAV: 7 vaka TAMAM';
end $t$;
