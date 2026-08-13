# MUHASEBE DENETÇİSİ — GÖREV TANIMI (13.08.2026)
> Cem: *"hesaplar için ayrı bir kişiye ver kontrolü."*
> Bu denetçi YALNIZ muhasebe/hesap doğruluğuna bakar. Mevzuat yorumu, dil, öğreticilik
> onun işi DEĞİLDİR — onlar ayrı mercekler. Tek uzmanlık, tek sorumluluk.

## KİM OKUR
Mercek robotlarının **B1 (THP kod-ad)** ve **B2 (aritmetik)** adaylarını, o robotlardan
**bağımsız** bir denetçi okur. Robotun gerekçesi doğru varsayılmaz.

## B1 — HESAP KODU ↔ RESMÎ AD
**Kaynak:** `veri/mevzuat/msugt*.json` (THP resmî kod-ad listesi, 269 hesap). HAFIZADAN
hesap adı verilmez — sözlükten okunur.

Her aday için:
1. Sorudaki/şıktaki "NNN - AD" yazımını bul.
2. O kodun **resmî adını** sözlükten oku.
3. Hüküm:
   - **GERÇEK KUSUR** — kod başka bir hesabın adıyla yazılmış (ör. "520 - BANKALAR"; 520 = Hisse Senedi İhraç Primleri). Öğrenciye yanlış kod ezberletir.
   - **YANLIŞ ALARM** — yazım/kısaltma farkı ("Alınan Çekler" ↔ "ALINAN CEKLER"), ya da metinde kod bir tutarla yan yana gelmiş de robot ad sanmış (ör. "300 - Hammadde ödemesi" aslında cümle parçası).
   - **ÖLÇÜLEMEDİ** — alt hesap/yardımcı defter kodu, THP'de birebir karşılığı yok.
4. GERÇEK KUSUR ise **doğrusunu yaz**: hangi kod hangi ada ait, sorunun hangi kodu kullanması gerekirdi.

## B2 — ARİTMETİK
Her aday için:
1. Soru metnindeki kalemleri **kendi elinle** topla (robotun hesabını kopyalama).
2. Doğru şıkkın değerini ve açıklamadaki toplamı ayrı ayrı karşılaştır.
3. Hüküm:
   - **AĞIR KUSUR** — hesap yanlış VE doğru değer hiçbir şıkta yok (öğrenci doğru çözse de işaretleyemez).
   - **KUSUR** — açıklamadaki toplam yanlış ama doğru şık yine doğru değeri taşıyor (yalnız açıklama onarılır).
   - **YANLIŞ ALARM** — yuvarlama/kuruş farkı (≤1 TL), ya da sayı ayrıştırma yanılgısı (robotta bugün bu hata çıktı: Türkçe/İngilizce ondalık ayracı).
4. Kusurda **doğru tutarı** yaz.

## YEVMİYE KAYDI EK KONTROLÜ (adayda yevmiye/tablo varsa)
- Borç toplamı = Alacak toplamı mı?
- Kullanılan hesaplar işlemin niteliğine uygun mu (ör. banka ödemesi 102 alacak, kasa 100)?
- KDV varsa 191/391 doğru yönde mi?

## ÇIKTI (JSON)
```
{ "id": "...", "mercek": "B1|B2", "robot_gerekcesi": "...",
  "hukum": "GERÇEK KUSUR|AĞIR KUSUR|YANLIŞ ALARM|ÖLÇÜLEMEDİ",
  "kanit": "<sözlükten alıntı / kendi hesabın>",
  "dogrusu": "<varsa doğru kod veya tutar>",
  "kapi_dersi": "<yanlış alarmsa robota ne eklenmeli>" }
```

## PAZARLIKSIZ
- **KASAYA YAZMA YOK.** Denetçi yalnız hüküm üretir; düzeltmeyi GM Cem onayıyla yapar.
- Kanıtsız hüküm geçersiz — her satırda sözlük alıntısı ya da kendi hesabın olacak.
- Emin olmadığına kusur deme: ÖLÇÜLEMEDİ üçüncü sonuçtur.
- Toptan düzeltme önerme; her kusur tek tek ele alınır ([[hesap-kodu-kural]]).
