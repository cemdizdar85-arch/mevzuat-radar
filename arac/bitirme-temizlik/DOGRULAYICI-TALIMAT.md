# DOĞRULAYICI TALİMATI (bitirme temizliği · standart D1–D7)

Girdi: `W/_anahtar-gizli/dogrula-<etiket>.json` (W = veri/fabrika/temizlik) — kök, şıklar, ANAHTAR, açıklama, dayanak, iki kör çözücünün cevap+notu.
Her soru için RESMÎ METNİ ambardan okuyarak karar ver (`node arac/bitirme-temizlik/ambar-ara.js …`). Çözücü notu yanılabilir: 30.10'da notların ~1/3'ü yanlış alarmdı.

- **INDIR** — anahtar yanlış · iki şık doğru · hiçbir şık doğru değil · kökte yanlış madde/kaynak · kökte ya da açıklamada YANLIŞ HÜKÜM (öğrenciye yanlış bilgi) · kök iki okumaya açık.
- **KALSIN** — soru doğru ve tek anlamlı; not yanlış alarm.
- **KALSIN-DUZELT** — cevap doğru, tek anlamlı; yalnız küçük terim/yazım kusuru, öğrenciyi yanlış yönlendirmiyor.
Kuşkuda INDIR (Cem: "yanlış soru olmasın"). Her karara resmî metinden ≤25 kelimelik alıntı (kaynak_ad ile); ambarda yoksa "AMBARDA YOK".
Çıktı: `W/_anahtar-gizli/karar-<etiket>.json` — `{"id","karar","gerekce","kanit"}`; ayrıca INDIR'ler `W/ret-<etiket>.json` (kimlik → tek satır gerekçe, soru metni YOK).
Uygulama: `node arac/bitirme-temizlik/ret-ekle2.js veri/sinav/smmm-elle-ret.json W/ret-<etiket>.json` → commit + push → `gh workflow run smmm-kasa-yayin.yml` → bitince `node arac/bitirme-temizlik/inen-kontrol2.js W/ret-<etiket>.json` sitede 0 kalmalı.
