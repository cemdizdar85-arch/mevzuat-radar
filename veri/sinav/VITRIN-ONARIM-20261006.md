# Vitrinden dışlanan SGS soruları — elle onarım (05–06.10.2026, oturum "SGS: vitrinden dışlanan 39 sorunun açıklamasını onar")

Kaynak liste: `public.vitrin_aciklama_dislanan` (05.10 akşam okundu: 43 kayıt = SGS 39 + SMMM 4; SMMM'ye dokunulmadı).
Yöntem: CLAUDE.md AÇIKLAMA KATMANI S1–S8 · resmî kaynak ambardan · `arac/onarim-hatti.js teslim` · bedel **0 USD**.
Soru metni bu dosyada YOK (depo public); yalnız kimlik + değişiklik türü.

## Üç sayı
| | Sayı |
|---|---|
| Listede (SGS) | 39 |
| Onarılan (ambara yazıldı + geri okundu 32/32, yayın 37428956762, tablodan düştü 32/32) | 32 |
| Hâlâ dışlanan (ilk 39'dan) | 7 — soru kusuru değil: kapı yanlış alarmı 6 + yayın dönüştürücüsü 1 |

Anahtar / kök / şık değişen soru: **0** (32'si "yalnız açıklama"; yeniden hakem gerekmedi). Elle ret listesi 35→35.
Bulutta koşan SGS partisi teslim anında yoktu (`bulut-kosan-etiketler.ps1 -Kati`).

## Onarılanlar (32)
- **sade eklendi (KART-BOS sade.dogru, 12):** sgs-c2-denetim-zor-r1/kp-09, kp-10, kp-12 · sgs-t1-genel-ekonomi-cokzor/kp-03 (+ yanlış yol A şıkkına bağlandı, konu_giris bu soruya uyarlandı, kaynaksız "p.28" kaldırıldı), kp-04 ·
  sgs-t1-genel-maliye-cokzor/kp-03, kp-15 · sgs-t1-genel-maliye-kolay/kp-03, kp-16 · sgs-t1-genel-maliye-zor/kp-03, kp-16 · sgs-t1-genel-turkce-cokzor/kp-10.
- **Dayanak Türkçe harfli + resmî ad (KART-TR, 8):** sgs-c5-fmuh-cokzor-r1-3/kp-02 (+ yevmiye/ikiz şemada komisyon 110 maliyetinden 653'e: THP 110 işleyişi "satınalma giderleri 65 grubunda") ·
  sgs-c5-vergi-kolay-r2/kp-10 · sgs-d4-yd-cokzor-r1/kp-04, kp-09 · sgs-d4-yd-cokzor-r2/kp-05 · sgs-d4-yd-cokzor-r4/kp-04 · sgs-d5-vergi-zor-r2/kp-07 · sgs-k7-mat-cokzor/kp-02.
- **Yanlış yol gerçek çeldiriciye (KAPI-YY, 7):** sgs-c5-mta-kolay-r1/kp-04 · sgs-e16-ekonomi-zor/kp-07 · sgs-e16-mat-kolay/kp-03 · sgs-e16-mat-zor/kp-05 · sgs-t1-genel-ekonomi-cokzor/kp-09 · sgs-t1-genel-maliye-kolay/kp-19 · sgs-t1-genel-maliye-zor/kp-06.
- **Adım atfı (KAPI-ADIM, 4):** sgs-c5-maliyet-cokzor-r2/kp-01 ve sgs-e16-mat-zor/kp-08 (sitede birleşen tekrar adım kayıtta da tek adıma indirildi, atıflar yeni sıraya) · sgs-t1-genel-mat-cokzor/kp-01, kp-06 (+ yanlış yol A şıkkına).
- **BDS paragraf (KAPI-BP, 1):** sgs-t1-denetim-cokzor/kp-01 — BDS 500 eski A27/A28 → güncel A31/A32 (13 alan).

## Hâlâ dışlanan 7 — neden
- KAPI-BP yanlış alarm (atıf güncel metne göre doğru): sgs-c2-denetim-cokzor-r2/kp-08 (BDS 500 p.7) · sgs-c5-denetim-cokzor-r1/kp-08 (BDS 200 p.12) · sgs-c5-denetim-zor-r1/kp-13 (BDS 550 p.5).
- KAPI-ADIM yanlış alarm (atıf elle sayıldı, doğru; kapı eksi işaret / kök / kesir paydasını sayı sanıyor): sgs-e16-ekonomi-zor/kp-09 · sgs-e16-mat-kolay/kp-04 · sgs-e16b-mat-zor/kp-01.
- KAPI-HK yayın dönüştürücüsünden: sgs-c5-ekonomi-cokzor-r2/kp-08 — `motor/kaydir-coz.ps1` satır 470 şıklardaki 102/122/152 sonuçlarını hesap kodu sanıp ekonomi sorusuna THP sözlüğü ekliyor; THP 122 ambar metni "652" atfı taşıyor. Soruda kusur yok.

## Not
06.10 10:29'dan sonra tabloya başka oturumun elle okumasından (e59690f3) 76 yeni SGS kaydı girdi (ELLE-KUSURLU, KART-ICNOT/KALINTI/BOSAD); bu işin kapsamında değildi.
06.10 ölçüm satırı: `VITRIN-KALITE: ücretsiz 750 · dışlanan 93 · vitrinde 657`.
