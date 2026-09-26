-- ============================================================================
-- CEVAP KAYDI TEST TEMİZLİĞİ (26.09.2026, Cem "3 yap")
--
-- NEDEN: 26.09'da mağaza uygulamasını telefon ölçüsünde otomatik denerken (Edge, başsız) ücretsiz soru sayfalarında
-- tıklanan şıklar da cevap_kayit'a yazıldı. Soru ekranındaki "N adayın %X'i senin gibi B dedi" akran yüzdesi
-- (sik_yuzdesi) bu satırları da sayıyor → gerçek değil. Ölçüm: 6. soruda gösterim 8 → 12 → 17 adaya çıktı (hepsi test).
--
-- AYIRT EDİCİ İZ (dördü birden):
--   1) tarih: 26.09.2026 00:00 – 27.09.2026 12:00 (TR)
--   2) süre (sn) ≤ 3 — otomatik tıklama anında; insan bir soruyu 3 sn'de okuyup cevaplamaz
--   3) oturum damgası boş (deneme tarayıcısının deposu her çekimde silindi)
--   4) yalnız 60 ÜCRETSİZ vitrin sorusu (kaydir/vitrin/sgs.html + smmm.html kimlikleri)
-- Körlük (yazılı): bu dört şarta uyan GERÇEK bir cevap varsa o da gider. Site 26.09'da "yakında" perdesiyle kapalı,
-- uygulama yalnız dahili testte → gerçek kullanıcı satırı beklenmiyor; yine de önce SAYIM yapılır.
--
-- KULLANIM: ÖNCE 1. BLOĞU çalıştır, çıkan sayıyı Nöbetçi'ye söyle. Sonra 2. BLOĞU çalıştır.
-- ============================================================================

-- ---------- 1. BLOK: SAYIM (hiçbir şey silmez) ----------
select count(*) as silinecek, count(distinct soru_id) as soru, min(olusturma) as ilk, max(olusturma) as son
  from public.cevap_kayit
 where olusturma >= '2026-09-26 00:00:00+03'
   and olusturma <  '2026-09-27 12:00:00+03'
   and coalesce(sn, 0) <= 3
   and coalesce(oturum, '') = ''
   and soru_id in (
    'sgs-t2-fmuh-cokzor/kp-01',
    'sgs-t1-denetim-cokzor/kp-01',
    'sgs-a6e-yabancidil-p1b/kp-01',
    'sgs-t1-maliyet-cokzor/kp-01',
    'sgs-t1-mta-cokzor/kp-01',
    'sgs-t1-genel-mat-cokzor/kp-01',
    'sgs-t2-fmuh-zor/kp-01',
    'sgs-t3-turkce-zor/kp-01',
    'sgs-p-denetim-zor-r4/kp-01',
    'sgs-t1-meslek-kolay/kp-01',
    'sgs-t1-ticaret-kolay/kp-01',
    'sgs-d2-borclar-kolay-r2/kp-01',
    'sgs-d2-issgk-kolay-r4/kp-01',
    'sgs-t1-genel-ekonomi-zor/kp-01',
    'sgs-t2-vergi-cokzor/kp-01',
    'sgs-t4-maliye-cokzor/kp-01',
    'sgs-c2-fmuh-cokzor-r3/kp-02',
    'sgs-a6e-yabancidil-p1b/kp-02',
    'sgs-p-mta-zor-r3/kp-01',
    'sgs-p-maliyet-cokzor-r4-b2/kp-01',
    'sgs-t1-genel-mat-kolay/kp-04',
    'sgs-t3-turkce-zor/kp-02',
    'sgs-p-meslek-zor-r2/kp-01',
    'sgs-t1-issgk-cokzor/kp-01',
    'sgs-p-ticaret-cokzor-r4-bulut/kp-01',
    'sgs-p-ekonomi-zor-r1-a/kp-01',
    'sgs-p-borclar-zor-r2/kp-02',
    'sgs-d2-vergi-kolay-r2/kp-01',
    'sgs-p-maliye-kolay-r3/kp-02',
    'sgs-t1-genel-inkilap-kolay/kp-01',
    'smmm-w3-fmuh-zor/kp-01',
    'smmm-4k-a-yfta-zor-r6/kp-01',
    'smmm-4k-a-maliyet-cokzor-r9/kp-01',
    'smmm-4k-a-ydenetim-kolay-r10/kp-02',
    'smmm-4k-a-yvergi-zor-r8/kp-01',
    'smmm-4k-a-ymeslek-kolay-r4/kp-02',
    'smmm-4k-a-yspk-zor-r8/kp-01',
    'smmm-w7-1-yhukuk-zor/kp-01',
    'smmm-w7-2-fmuh-kolay/kp-01',
    'smmm-4k-a-yfta-kolay-r6/kp-01',
    'smmm-ab2-a-maliyet/kp-02',
    'smmm-olc2-a-vergi/kp-02',
    'smmm-w7-2-ymeslek-zor/kp-01',
    'smmm-w3-ydenetim-zor/kp-01',
    'smmm-4k-a-fmuh-zor-r10/kp-01',
    'smmm-4k-a-yfta-zor-r1/kp-01',
    'smmm-4k-a-maliyet-zor-r1/kp-03',
    'smmm-4k-a-yvergi-zor-r3/kp-01',
    'smmm-4k-a-ydenetim-kolay-r3/kp-01',
    'smmm-w1-ymeslek-cokzor/kp-01',
    'smmm-4k-a-fmuh-kolay-r8/kp-03',
    'smmm-w2-yfta-cokzor/kp-01',
    'smmm-ab2-a-maliyet/kp-03',
    'smmm-olc2-b-vergi/kp-03',
    'smmm-w1-ymeslek-zor/kp-03',
    'smmm-w2-ydenetim-zor/kp-04',
    'smmm-w1-yhukuk-zor/kp-03',
    'smmm-4k-a-yspk-zor-r3/kp-01',
    'smmm-w2-yhukuk-zor/kp-02',
    'smmm-gm-p1-yspk/kp-01'
  );

-- ---------- 2. BLOK: SİLME (1. bloğun sayısı makulse) ----------
delete
 from public.cevap_kayit
 where olusturma >= '2026-09-26 00:00:00+03'
   and olusturma <  '2026-09-27 12:00:00+03'
   and coalesce(sn, 0) <= 3
   and coalesce(oturum, '') = ''
   and soru_id in (
    'sgs-t2-fmuh-cokzor/kp-01',
    'sgs-t1-denetim-cokzor/kp-01',
    'sgs-a6e-yabancidil-p1b/kp-01',
    'sgs-t1-maliyet-cokzor/kp-01',
    'sgs-t1-mta-cokzor/kp-01',
    'sgs-t1-genel-mat-cokzor/kp-01',
    'sgs-t2-fmuh-zor/kp-01',
    'sgs-t3-turkce-zor/kp-01',
    'sgs-p-denetim-zor-r4/kp-01',
    'sgs-t1-meslek-kolay/kp-01',
    'sgs-t1-ticaret-kolay/kp-01',
    'sgs-d2-borclar-kolay-r2/kp-01',
    'sgs-d2-issgk-kolay-r4/kp-01',
    'sgs-t1-genel-ekonomi-zor/kp-01',
    'sgs-t2-vergi-cokzor/kp-01',
    'sgs-t4-maliye-cokzor/kp-01',
    'sgs-c2-fmuh-cokzor-r3/kp-02',
    'sgs-a6e-yabancidil-p1b/kp-02',
    'sgs-p-mta-zor-r3/kp-01',
    'sgs-p-maliyet-cokzor-r4-b2/kp-01',
    'sgs-t1-genel-mat-kolay/kp-04',
    'sgs-t3-turkce-zor/kp-02',
    'sgs-p-meslek-zor-r2/kp-01',
    'sgs-t1-issgk-cokzor/kp-01',
    'sgs-p-ticaret-cokzor-r4-bulut/kp-01',
    'sgs-p-ekonomi-zor-r1-a/kp-01',
    'sgs-p-borclar-zor-r2/kp-02',
    'sgs-d2-vergi-kolay-r2/kp-01',
    'sgs-p-maliye-kolay-r3/kp-02',
    'sgs-t1-genel-inkilap-kolay/kp-01',
    'smmm-w3-fmuh-zor/kp-01',
    'smmm-4k-a-yfta-zor-r6/kp-01',
    'smmm-4k-a-maliyet-cokzor-r9/kp-01',
    'smmm-4k-a-ydenetim-kolay-r10/kp-02',
    'smmm-4k-a-yvergi-zor-r8/kp-01',
    'smmm-4k-a-ymeslek-kolay-r4/kp-02',
    'smmm-4k-a-yspk-zor-r8/kp-01',
    'smmm-w7-1-yhukuk-zor/kp-01',
    'smmm-w7-2-fmuh-kolay/kp-01',
    'smmm-4k-a-yfta-kolay-r6/kp-01',
    'smmm-ab2-a-maliyet/kp-02',
    'smmm-olc2-a-vergi/kp-02',
    'smmm-w7-2-ymeslek-zor/kp-01',
    'smmm-w3-ydenetim-zor/kp-01',
    'smmm-4k-a-fmuh-zor-r10/kp-01',
    'smmm-4k-a-yfta-zor-r1/kp-01',
    'smmm-4k-a-maliyet-zor-r1/kp-03',
    'smmm-4k-a-yvergi-zor-r3/kp-01',
    'smmm-4k-a-ydenetim-kolay-r3/kp-01',
    'smmm-w1-ymeslek-cokzor/kp-01',
    'smmm-4k-a-fmuh-kolay-r8/kp-03',
    'smmm-w2-yfta-cokzor/kp-01',
    'smmm-ab2-a-maliyet/kp-03',
    'smmm-olc2-b-vergi/kp-03',
    'smmm-w1-ymeslek-zor/kp-03',
    'smmm-w2-ydenetim-zor/kp-04',
    'smmm-w1-yhukuk-zor/kp-03',
    'smmm-4k-a-yspk-zor-r3/kp-01',
    'smmm-w2-yhukuk-zor/kp-02',
    'smmm-gm-p1-yspk/kp-01'
  );
