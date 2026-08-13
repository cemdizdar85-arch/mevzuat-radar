# MERCEK ADAYI OKUMA ŞARTNAMESİ — "robotun bulduğunu başkası okusun"
> Cem 13.08: *"ürettiği adayı başkasını okutalım."* Robot ADAY üretir, KARAR VERMEZ.
> Bu dosya, aday okuyucunun uyacağı kurallardır. Okuyucu, adayı üreten robottan
> BAĞIMSIZDIR: robotun gerekçesini doğru varsaymaz, sıfırdan yargılar.

## OKUYUCUNUN ÜÇ OLASI HÜKMÜ
- **GERÇEK KUSUR** — robot haklı; kusur somut kanıtla gösterilir (alıntı + doğrusu).
- **YANLIŞ ALARM** — robot yanılmış; NEDEN yanıldığı yazılır (kapı iyileştirmesi bundan doğar).
- **ÖLÇÜLEMEDİ** — kaynak ambarda yok / karar için uzman görüşü gerekiyor. Emin
  olunmayana kusur denmez ([[olcemedigine-kusur-deme]]).

## MERCEK A ADAYI (kanun örtüşmüyor) — okuyucu ne yapar
1. Sorunun `kanun_no` + `madde_no` alanındaki maddeyi **ambardan aç** (`veri/mevzuat/*.json`).
2. Doğru şıkkın "Kural:" bölümündeki iddiayı madde metniyle karşılaştır.
3. Hüküm ölçütü:
   - Madde metni iddiayı **içermiyorsa** → GERÇEK KUSUR ("kaynak var, söylediğini söylemiyor").
   - İddia doğru ama **başka maddede** düzenlenmişse → GERÇEK KUSUR (atıf yanlış), doğru madde yazılır.
   - İddia maddede var, robot kelime örtüşmesini kaçırmışsa → YANLIŞ ALARM (neden: eş anlamlı terim, sadeleştirme, vb.).

## MERCEK B1 ADAYI (THP kod-ad) — okuyucu ne yapar
1. `veri/mevzuat/msugt*.json` içinden o kodun **resmî adını** oku.
2. Şık/açıklama metnindeki yazımla karşılaştır.
3. Hüküm ölçütü:
   - Kod başka hesabın adıyla eşleşmişse → GERÇEK KUSUR (öğrenciyi yanlış ezberletir).
   - Kısaltma/eş yazım farkıysa ("Bankalar" ↔ "BANKALAR", "Alınan Çekler" ↔ "Alinan Cekler") → YANLIŞ ALARM.
   - Kod THP dışıysa (yardımcı defter, alt hesap) → ÖLÇÜLEMEDİ.
   **DİKKAT:** THP'de olmayan kod zaten robot tarafından atlanır; okuyucuya gelmemeli.

## MERCEK B2 ADAYI (aritmetik) — okuyucu ne yapar
1. Soru metnindeki kalemleri **kendi eliyle** topla (robotun hesabına güvenme).
2. Doğru şıkkın değeriyle karşılaştır.
3. Hüküm ölçütü:
   - Toplam yanlış VE doğru değer şıklarda yoksa → **AĞIR KUSUR** (öğrenci doğru çözse de işaretleyemez).
   - Toplam yanlış ama doğru şık yine de doğru değeri taşıyorsa → KUSUR (açıklama onarılır, cevap kalır).
   - Yuvarlama/kuruş farkıysa (≤1 TL) → YANLIŞ ALARM.

## MERCEK C ADAYI (çift doğru) — okuyucu ne yapar
1. Doğru şıkkın açıklamasını oku; şüpheli şıkkın **iddiasını** ayrı cümle olarak çıkar.
2. Soru kökünü oku: "hangisi doğrudur" mu, "en kapsamlı/en uygun hangisidir" mi?
3. Hüküm ölçütü:
   - Şüpheli şık **bağımsız olarak da doğruysa** ve kök "hangisi doğrudur" diyorsa → GERÇEK KUSUR.
   - Şüpheli şık doğru ama kök "en kapsamlı/en doğru" diyorsa → YANLIŞ ALARM (tek en iyi cevap kuralı).
   - Açıklama şıkkı yalnızca **anıyor** ama doğrulamıyorsa → YANLIŞ ALARM.

## ÇIKTI (her aday için)
`{ id, mercek, robot_gerekcesi, okuyucu_hukmu: GERÇEK KUSUR|YANLIŞ ALARM|ÖLÇÜLEMEDİ,
   kanit: "<alıntı/hesap/madde metni>", onerilen_duzeltme: "<varsa>", kapi_dersi: "<yanlış alarmsa robota ne eklenmeli>" }`

## PAZARLIKSIZ
- Kasaya YAZMA yok. Okuyucu yalnız hüküm üretir.
- Kanıtsız hüküm geçersiz — her satırda alıntı ya da hesap olacak.
- Hafızadan mevzuat verilmez; yalnız ambar metni ([[feedback-mevzuat-yut]]).
- "Yanlış alarm" hükmü **kıymetlidir**: kapının nasıl iyileştirileceğini o gösterir.
