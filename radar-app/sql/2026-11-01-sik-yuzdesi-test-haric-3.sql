-- ============================================================================
--  AKRAN YÜZDESİNDEN TEST OTURUMLARI HARİÇ — 3 (01.11.2026)
--  Eskitir: 2026-10-08-sik-yuzdesi-test-haric-2.sql (aynı fonksiyon, aynı imza; uygulanmış göç değiştirilmez, liste burada büyür).
--
--  NEDEN: 31.10–01.11 ekran görüntüsü testleri (Ajan 30 ve Ajan 53; bitirme kabuğu canlı kasa satırıyla, telefon 390 + bilgisayar
--  1280) şıklara tıkladı; kabuk her tıklamada cevap_kayit'e satır yazar. 28 oturum · 53 satır. Örnek: smmm-4k-a-yhukuk-kolay-r3/kp-02
--  akran yüzdesi bu göçten önce "18 aday, hepsi A" (doğru E) idi ve 18'inin 18'i testti.
--  KANIT (oturum başına): oturumun BÜTÜN satırları tek soru, betiğin sabit seçtiği şık, 1–2 satır (telefon + bilgisayar ~10–30 sn
--  arayla), zaman ekran dosyalarının yazılma saatiyle aynı; 28 oturumun tüm zamanlardaki satırı 53, başka soru cevaplayan yok.
--  Bilerek EKLENMEYEN: 53291 / oturum nfyc4eysmvxi9kb5 (01.11 07:12 UTC, ornek-soru, tek satır) - hiçbir ekran işiyle eşleşmedi.
--  KARAR (Cem 01.11): satır SİLİNMEZ. Yalnız sik_yuzdesi bu oturumları SAYMAZ. DDL/tablo yok.
-- ============================================================================
create or replace function public.sik_yuzdesi(p_soru_id text)
returns table(secim text, n bigint)
language sql stable security definer set search_path = public
as $$
  select secim, count(*)::bigint as n
  from public.cevap_kayit
  where soru_id = p_soru_id and length(p_soru_id) between 3 and 120
    and coalesce(oturum, '') not in (
      'pj0d61czmuy98c1i',     -- 08.10 site oturumunun canlı denetimi (ornek-sgs, 5 satır)
      'os-muytfbpt-r64a4y',   -- 08.10 site oturumunun yerel denemesi (eski ornek-sorular.html, 1 satır)
      -- 01.11 ekran testleri, Ajan 30 (yerel kabuk denemeleri + dbg.js), 31.10 21:31–21:46 UTC, 37 satır
      'ts9rf6ghmvwx21be', '2l0m30hvmvwx2ulq', 'u6ablfmzmvwx461b', 'o34av94emvwx63ul', '6994oef7mvwx6tud',   -- smmm-4k-a-yhukuk-kolay-r3/kp-02 A
      'jygzmmsamvwx7u61', '9u4rgv6hmvwx8919', 'nj9z12x3mvwx902l',                                          -- smmm-w14-1-fmuh-zor/kp-09 A
      '5xt77r8emvwxd0fj', '5wcch8mvmvwxddp6', 'yk8xn4xqmvwxe8qu', 'vqv94smrmvwxfhe1', 'oe3fklwnmvwxg62q',
      '5okuh62emvwxgqtj', 'oki9op4zmvwxhovv', '71v21qy9mvwxil5v',                                          -- sgs-t1-fmuh-cokzor/kp-50 E
      '4d22nw0bmvwxj0cz', '373tivukmvwxk3kv',                                                              -- smmm-4k-a-yhukuk-kolay-r3/kp-02 A
      'v5l50k0lmvwxjg2j', 'dfardw2emvwxkhjs',                                                              -- sahte-yhukuk/kp-20 A (sahte test kimliği)
      -- 01.11 ekran testleri, Ajan 30 (canlı kabuk: hukuk önce/sonra 22:02 + 23:29 UTC; taşıma 23:42–23:43 UTC), 10 satır
      'rk8hkg95mvwy59xq', 'uwy828bgmvx18p02',                                                              -- smmm-4k-a-yhukuk-kolay-r3/kp-02 A
      'xzwiojicmvx1q0hj', 'pic0nnrqmvx1qfw4', '4ffl6nwhmvx1qv66',                                          -- w3-yhukuk-kolay/kp-03, w5-yvergi-kolay/kp-04, 4k-a-ydenetim-zor-r10/kp-02 B
      -- 01.11 ekran testleri, Ajan 53 (canlı kabuk, Finansal Muhasebe), 06:55–06:56 UTC, 6 satır
      'rwji17jvmvxh6p98', 'rlcog5yomvxh7j4a', 'ztiuesjpmvxh8cvn'                                           -- smmm-gm5-24-fmuh-zor/kp-05 A
    )
  group by secim;
$$;
revoke all on function public.sik_yuzdesi(text) from public;
grant execute on function public.sik_yuzdesi(text) to anon, authenticated;

-- ÖLÇÜ (basınca; 01.11 basmadan önce ölçülen değerler):
--  a) select count(*) from public.cevap_kayit where oturum in (<yukarıdaki 28>);        -- 53 (satırlar duruyor, silinmedi)
--  b) rpc/sik_yuzdesi {"p_soru_id":"smmm-4k-a-yhukuk-kolay-r3/kp-02"}  önce A:18  -> sonra []  (gerçek aday yok; akran satırı görünmez)
--  c) rpc/sik_yuzdesi {"p_soru_id":"smmm-gm5-24-fmuh-zor/kp-05"}       önce A:8 B:1 D:2 -> sonra A:2 B:1 D:2
--  d) rpc/sik_yuzdesi {"p_soru_id":"sgs-t1-fmuh-cokzor/kp-50"}          önce E:13 -> sonra []
