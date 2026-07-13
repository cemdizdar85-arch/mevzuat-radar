# SÜREÇ — Yeni iş eklerken ATLAMA OLMASIN (kalıcı kontrol listesi)

Bu dosya, Mevzuat Radarı'na eklenen **her kanun/mevzuat-temelli** özellik için ZORUNLU adımlardır. Amaç: ne yanlış ne eksik. Cem kuralı: "bundan sonra bu sistemi kalıcı hale getirelim ki bir şey atlamayalım."

## NE ZAMAN uygulanır
Yeni bir araç, kart, oran, süre, eşik veya karar-noktası eklenirken; mevcut birini güncellerken.

## 7 ADIM (sırayla, atlama yok)

**1 · BİRİNCİL KAYNAK.** Yalnız resmî: resmigazete.gov.tr · mevzuat.gov.tr · gib.gov.tr · kik.gov.tr · ticaret.gov.tr · sgk.gov.tr · turkpatent.gov.tr. **İkincil (KPMG, blog, muhasebe sitesi) YASAK — teyit için bile.** Metin: mevzuat PDF → `pdftotext -layout` (FlateDecode açılır). Taranmış görüntüyse GİB/mevzuat metin sürümünden oku, olmuyorsa "makine-okunamadı, teyit edilecek" damgası.

**2 · KAPSAM HARİTASI (yukarıdan-aşağı — hiç olmayanı bulur).** Kanunun/bölümün TAM madde listesini çıkar → madde madde işaretle: ✅ değindik · 🔴 değinmedik-önemli · ➖ konu-dışı. `kapsam/<kanun>-madde-kapsam.md` tablosuna yaz. 🔴'ları araca ekle → ✅ yap. Madde sonlu → bitiş ispatlanır.

**3 · NÜANS DENETİMİ (aşağıdan-yukarı — var olanın hatasını bulur).** Her karar-noktasını 4 desen için sına:
- 🔴 **Gizli eşik?** Evet/hayır sorduğun yerde TL/gün eşiği var mı? (borç 5.000 TL, izaha davet 100.000 TL gibi) → **eşik varsa RAKAM iste, evet/hayır değil.**
- 🟠 **Koşul düzleşmiş mi?** Oranı/kuralı koşulsuz mu yazdın? (KDV %1 finansal kiralama; yerli malı %15 yalnız mal alımı; m.30 ceza yalnız tescilli marka) → koşulu yaz.
- 🟡 **Süre atlanmış mı?** (hak düşürücü/başvuru süreleri)
- 🟡 **İstisna/"hariç" atlanmış mı?**

**4 · RAKAM DİSİPLİNİ.** Her sayı birincilden + kaynak damgası (madde no + RG/tebliğ tarihi). Uydurma yok. Emin değilsen yumuşat/teyit-notu koy.

**5 · OTOMATİK GÜNCELLEME.** Yıllık/dönemsel değişen değer (eşik, oran, parasal limit) koda GÖMÜLMEZ — robot nöbetine (kaynak-nöbetçisi / RG-tarama) bağla; kanuni sabiti (7,5 kat gibi) sabit yazma, not+değer tutarlılığıyla kontrol et.

**6 · DENETÇİ + TEST (CI kapısı).** `arac/yapisal-denetci.ps1` yeşil + `arac/nokta-kontrol.ps1` geçsin. Her push'ta `dogrula.yml` bunu zaten koşar. JSON geçerli, KDV∈{1,10,20}, hariç⇒kısmi/kod, damga birincil, ikincil-kaynak yok.

**7 · ÇENTİK + KAYIT.** Kapsam tablosunu ✅ yap; kapsam/00-INDEX.md güncelle; MEMORY.md + ilgili task güncelle. Bitmeden "tamam" deme.

## Mikro-checklist (her rakam/karar için 10 saniyede sor)
- [ ] Kaynağı birincil mi? (resmî alan adı)
- [ ] Bu evet/hayır aslında bir EŞİK mi? (rakam iste)
- [ ] Bu oran/kural KOŞULLU mu? (koşulu yazdım mı)
- [ ] Süre / istisna var mı, yazdım mı?
- [ ] Sayının damgası (madde+tarih) var mı?
- [ ] Yıllık değişiyorsa robot güncelliyor mu?
- [ ] Denetçi + nokta-kontrol yeşil mi?
- [ ] Kapsam tablosunda çentiği attım mı?

**KANUNLAR:** kod-temelli araçlar 5 kanuna dayanır (4734/VUK/İİK/SMK/Gümrük — [00-INDEX](00-INDEX.md)). Yeni kanun eklenirse: madde listesi çıkar → yeni kapsam dosyası → denetçi kapsam-listesine ekle.
