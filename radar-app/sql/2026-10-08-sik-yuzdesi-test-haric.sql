-- ============================================================================
--  AKRAN YÜZDESİNDEN TEST OTURUMLARI HARİÇ (08.10.2026)
--
--  NEDEN: 5 örnek soru sayfası (kaydir/vitrin/ornek-*.html) canlıda denetlenirken site oturumu 5 soruyu çözdü (hepsinde ilk şık):
--  cevap_kayit'e kaynak='ornek-soru', oturum='pj0d61czmuy98c1i' ile 5 yanlış satır düştü. Akran yüzdesi ("N adayın %X'i senin
--  gibi ... dedi") 5 cevaptan sonra görünür -> bu satırlar ilk gerçek ziyaretçiye sahte bir dağılım gösterirdi.
--  KARAR: satır SİLİNMEZ (geri alınamaz iş; 26.09 temizliği Cem onayıyla yedekliydi). Yalnız sik_yuzdesi bu oturumları SAYMAZ.
--  DDL yok, tablo yok, FK yok: yalnız fonksiyon yeniden yazılır (14.09 PostgREST kesinti tipi değil).
--  Eskitir: 2026-09-06-cevap-kayit.sql içindeki sik_yuzdesi tanımı (tablo ve politika aynen kalır).
--  Yeni test oturumu çıkarsa: YENİ göç dosyasıyla listeye eklenir (uygulanmış göç dosyası değiştirilmez - sql-uygula.yml).
-- ============================================================================
create or replace function public.sik_yuzdesi(p_soru_id text)
returns table(secim text, n bigint)
language sql stable security definer set search_path = public
as $$
  select secim, count(*)::bigint as n
  from public.cevap_kayit
  where soru_id = p_soru_id and length(p_soru_id) between 3 and 120
    and coalesce(oturum, '') not in (
      'pj0d61czmuy98c1i'   -- 08.10 site oturumunun canlı denetimi (ornek-sgs, 5 satır)
    )
  group by secim;
$$;
revoke all on function public.sik_yuzdesi(text) from public;
grant execute on function public.sik_yuzdesi(text) to anon, authenticated;

-- ÖLÇÜ (basınca):
--  a) select count(*) from public.cevap_kayit where oturum = 'pj0d61czmuy98c1i';           -- 5 (satırlar duruyor)
--  b) anon: POST /rest/v1/rpc/sik_yuzdesi {"p_soru_id":"sgs-k11-ticaret-zor/kp-01"}       -- o oturumdan başka cevap yoksa []
