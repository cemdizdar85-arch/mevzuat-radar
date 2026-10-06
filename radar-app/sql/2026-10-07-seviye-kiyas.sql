-- 2026-10-07 · SEVİYE TESTİ KIYASI (Cem "başka adaylarla kıyası ölçerek ekleyelim; aday geldikten sonra, bilgileri tutup")
-- Neden: rakiplerin sonuç ekranında "adayların %X'inden iyisin" var; bizde veri yokken bu cümle uydurma olurdu.
-- Veri zaten birikiyor: seviye testi her cevabı anonim yazıyor (cevap_kayit, kaynak='seviye-testi', oturum = test oturumu).
-- Bu fonksiyon yalnız İKİ SAYI döndürür: kaç test bitmiş (n) ve verilen doğru sayısının altında kalan testlerin yüzdesi.
-- Kişi, oturum, soru, cevap DÖNMEZ. Eşik: 100 biten test olmadan acik=false döner, sayfa hiçbir şey göstermez.
-- "Biten test" = aynı oturumda 30-40 cevap (aynı sayfada iki kez çözen 40'ı aşar, sayılmaz). Sınav kimlik önekinden
-- (sgs- / smmm-). GÖRMEZ: aynı kişinin farklı günlerde çözdüğü testler ayrı sayılır; bizim deneme çözümlerimiz de sayılır
-- (açılış öncesi 4 test, 07.10 ölçümü) — eşik 100 olduğu için etkisi küçük; "aday" değil "biten test" denir.
-- Erişim: anon/authenticated yalnız EXECUTE; cevap_kayit'a okuma hakkı verilmez (security definer).

create or replace function public.seviye_kiyas(p_sinav text, p_dogru integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_n integer; v_alt integer; v_esik constant integer := 100;
begin
  if p_sinav is null or p_sinav not in ('sgs', 'smmm') or p_dogru is null or p_dogru < 0 or p_dogru > 40 then
    return jsonb_build_object('acik', false);
  end if;
  with t as (
    select oturum, sum(case when dogru_mu then 1 else 0 end) as d
    from public.cevap_kayit
    where kaynak = 'seviye-testi' and oturum is not null
      and soru_id like (case when p_sinav = 'smmm' then 'smmm-%' else 'sgs-%' end)
    group by oturum
    having count(*) between 30 and 40
  )
  select count(*), count(*) filter (where d < p_dogru) into v_n, v_alt from t;
  if v_n < v_esik then
    return jsonb_build_object('acik', false, 'n', v_n, 'esik', v_esik);
  end if;
  return jsonb_build_object('acik', true, 'n', v_n, 'altinda', round(100.0 * v_alt / v_n));
end;
$$;
revoke all on function public.seviye_kiyas(text, integer) from public;
grant execute on function public.seviye_kiyas(text, integer) to anon, authenticated;
