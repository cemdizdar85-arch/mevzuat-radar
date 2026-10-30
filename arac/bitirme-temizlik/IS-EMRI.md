# BİTİRME TEMİZLİK + DÜZELTME + EKSİK TAMAMLAMA — 4 BULUT OTURUMU İŞ EMRİ (Cem 30.10.2026)

> Cem: *"kurallarımızdan çıkmasın; insanlar sorumuzu beğenmiyor, çok utandırıcı."* Bu iş emrindeki HER adım
> `BITIRME-SORU-STANDARDI.md`'ye (D1–D7 · K1–K7 · Ş1–Ş10 · Ö1–Ö5 · Y1–Y5) ve `BITIRME-KONU-KARTLARI.md`'ye bağlıdır. Standartla
> çelişen kestirme YOK. Kuşkuda soru YAYINA GİRMEZ / İNER.

## Ortak kurallar (4 oturum)
- Önce oku: `CLAUDE.md`, `BITIRME-SORU-STANDARDI.md`, `BITIRME-KONU-KARTLARI.md`, bu dosya.
- Soru metni, şık, cevap, açıklama **DEPOYA GİRMEZ** (depo herkese açık). Çalışma dosyaları `veri/fabrika/temizlik/` (gitignore).
  Depoya yalnız: `veri/sinav/smmm-elle-ret.json` (kimlik + gerekçe) ve sayım raporları (soru metni yok).
- Ortam: `SUPABASE_SERVICE_KEY` gerekli (ambar okuma, paket_soru okuma). Yoksa DUR, Cem'e yaz.
- Commit'e `Co-Authored-By` YAZMA. Commit + `git push origin HEAD:main` aynı adımda; reddedilirse fetch + merge + push.
- Aynı dosyaya iki oturum yazmasın: `smmm-elle-ret.json`'a YALNIZ Oturum 1 yazar; öteki oturumlar indirme önerisini
  `veri/fabrika/temizlik/ret-oneri-<oturum>.json`'a koyar, Oturum 1 doğrular ve uygular.
- Para: kör çözüm/doğrulama/yazım bedava (abonelik). Bulut hakem (`bulut-uretim.yml`) ücretli ve **ACİL FRENDE**; hakeme göndermeden
  soru sayısı × birim bedel Cem'e yazılır, fren yalnız Cem "aç" deyince kalkar.
- Rapor: her parti sonunda üç sayı ayrı — kontrol edilen · inen · düzeltilip geri giren. "Düzeldi" demeden sitede ölç.

## ⚠ K8 — KONU İÇİ KARIŞIM (2–4. işlerin hepsi)
Kartın `kalip` alanı görülen örnektir, tek tip emri değil. Aynı konudan yazdığın sorular dersin gerçek kalıp kümesine yayılır; ≥5 sorulu
konuda tek kalıp %60'ı geçmez (FTA'da hesap %80). Sitede tek tip konu oranı: FTA %97 · Maliyet %90 · FM %59 · Vergi %58 — Oturum 4'ün
açık tablosunda konu başına "kalıp karışımı açığı" da yer alır (araç: kalip-ayirici.js ayir()).

## Oturum 1 — KONTROL (bankanın tamamı, öğrencinin ilk gördüğünden başla)
`node arac/bitirme-temizlik/temizlik.js indir 120 tur3` (ilk 80 kontrol edildi; kontrol-edilen.json'daki 682 atlanır) → `kor-tur3/` ders dosyalarını
**iki ayrı** kör çözücü turuna ver (`COZUCU-TALIMAT.md`; A ve B turunda dersleri farklı eşle) → `temizlik.js karsilastir tur3` → `temizlik.js ozet tur3`
→ `DOGRULAYICI-TALIMAT.md` ile karar → INDIR'leri uygula, sitede ölç. Sonra 160, 200 … sayfa sonuna kadar.
Öteki oturumların `ret-oneri-*.json`'larını da doğrula ve uygula. YIL_VERGI çıkanları Oturum 2'ye bırak (`yil-vergi-<etiket>.json`).

## Oturum 2 — VERGİ YIL KURALI (D7)
Liste: `veri/sinav/bitirme-duzeltme/vergi-2025.json` (149, alt sınır) + Oturum 1'in `yil-vergi-*.json`'ları. Her soru 2025 takvim yılı/hesap dönemine ve
2025'in RESMÎ tutarlarına (ambardan) çevrilerek YENİ soru olarak yazılır; kalıp/kart korunur; cevap ve çeldiriciler yeniden hesaplanır.
Eski soru, yenisi yayına girene kadar YERİNDE KALIR (Cem 30.10). İlk 20'yi Cem okur.

## Oturum 3 — KALIP DIŞI (K4)
Liste: `veri/sinav/bitirme-duzeltme/kalip-disi.json` (424: Meslek 115, SPK 105, Hukuk 71, FM 48, Vergi 48, Denetim 26, FTA 11).
Konu kartındaki gerçek kalıpla YENİ soru yaz (Meslek/SPK'da "doğrudur" yok; Hukuk'ta hesap yok). Eski soru yenisi girince iner. İlk 20'yi Cem okur.

## Oturum 4 — EKSİK TAMAMLAMA (ders ders, konu konu — K1/K2)
1) Konu konu açığı ölç: her kartın konusu için sitede kaç soru var (`paket_soru.konu` + `veri/sinav/smmm-banka-esleme.json` köprüsü), kartın ağırlığı
   (dönem sayısı) ile hedef; açık = hedef − sitede. Kalıp açığı: `BITIRME-SORU-KALIBI-OLCUM.md` "EKSİK KALIP BASIM PLANI" (188 alt sınır).
   **KONU KONU KALIP AÇIĞI (ölçüldü 30.10):** `veri/sinav/bitirme-duzeltme/konu-konu-kalip.md` — 185 test konusunun her biri için gerçek sınavın
   kalıpları ↔ sitedeki dağılım, "eksik kalıp" ve "tek tip" sütunları (98 konuda gerçek kalıp sitede hiç yok; 50 konu tek tip). Yeni sorular ÖNCE
   bu eksik kalıplara yazılır (ör. Maliyet GÜG yükleme: gerçek 3× "sırasıyla", sitede 85 hesap 0 sırasıyla). Yeniden ölç: `node arac/bitirme-temizlik/konu-konu-karisim.js <çıktı.md>`.
2) Açığı en büyük konulardan, kartın kalıbı/beceri/kök hedefi/şık türüyle YENİ soru yaz. Dayanağı "AMBARDA YOK" kartlara YAZMA (K1b).
   2026/2 yeni hesap kodları (245/551/624/647) için kaynak: ambardaki "KGK FİNANSAL RAPORLAMA STANDARTLARINA UYGUN HESAP PLANI".
3) Her soru: kanıt cümlesi ambarda (D2) → iki kör çözücü (D3) → ilk 20'yi Cem okur (D4) → hakem (FREN: Cem onayı) → yayın.

## Yazılan HER yeni soru için (Oturum 2–4)
kart → yazım (kalıp + kök hedefi ±%25 + şık türü + Ş1–Ş10 + yıl 2025) → kanıt cümlesi ambarda → iki KÖR çözücü (yalnız kök+şık) → açıklama
(her şık neden doğru/yanlış, kaynak cümlesi, hap) → Cem okuması (ilk 20) → hazır soru yolu (`arac/GM-HAZIR-SORU-TALIMATI.md`, standardın altında)
→ hakem (fren) → yayın → eski kimlik aynı commit'te elle rete → sitede ölç.
