# RAKİP ↔ KAYDIR-ÇÖZ KALIBI — soru/cevap deneyimi karşılaştırması (06.09.2026)

> Cem: "yurt dışındaki büyük rakipler ne yapıyor, öner, uygula." 26.08 raporu (`sql-yerel/RAKIP-ANALIZI-20260826.md`) ürün
> düzeyindeydi; bu dosya yalnız **soru-cevap-anlatım ekranını** kıyaslar. Kaynaklar: UWorld ürün turu ve inceleme sayfaları
> (accounting.uworld.com product-tour, atlascpaindex, katalystprep, crushthecpaexam), Becker/Gleim/Surgent kıyasları
> (cpaexamguide, maxwellcpareview, big4accountingfirms). Ölçülmemiş iddia yok; "bilinmiyor" yazılanlar sayfada görülmedi.

## 1. Onlarda var, bizde var mı?

| Özellik | UWorld | Becker | Gleim/Surgent | Bizde (06.09) |
|---|---|---|---|---|
| Her yanlış şık için ayrı gerekçe | ✅ | ✅ | ✅ | ✅ tuzak adı + neden + sade neden |
| Açıklamada görsel (tablo/akış/illüstrasyon) | ✅ "vivid illustration" her soruda | kısmen | kısmen | ✅ çözüm tablosu + formül tahtası + yevmiye/T-hesabı; illüstrasyon YOK |
| Adım adım çözüm, animasyon | ❌ statik | SkillBuilder VİDEO | ❌ | ✅ hücre hücre dolan tablo, uçan sonuç (video yerine) |
| Eğitim hedefi cümlesi (educational objective) | ✅ sonda tek cümle | ❌ | ❌ | ✅ "hap" (kural ile örtüşürse gizli) |
| Konu girişi / kavram kartı | ✅ SmartPath konu bağlantısı | ✅ konsept videosu | ✅ | ✅ 06.09: 0. adım (nedir / sınavda / yöntemler / örnek) |
| Öğrenciye soru sorma, deneme aldırma | ❌ (okur) | ❌ | ❌ | ✅ 06.09: "önce sen dene" tahmin kapısı, teoride "kuralı sen söyle" |
| Kendi hatasına özel geri bildirim | kısmen (seçtiğin şık gerekçesi) | kısmen | kısmen | ✅ tek hata adımı + kâğıt eşlemesi (hangi katman atlandı) |
| Tutor mode / timed mode | ✅ ikisi | ✅ | ✅ | ⚠ yalnız tutor; **süre 06.09 eklendi** (soru başına ⏱), timed deneme `deneme.html`'de |
| Şık eleme (strikeout) | bilinmiyor (sayfada görülmedi) | ✅ (gerçek sınav arayüzü taklidi) | ✅ | ✅ 06.09: ✕ ile eleme, cevap satırında "elediğin" |
| Hesap makinesi / not / vurgulama | ✅ (sınav arayüzü) | ✅ | ✅ | ⚠ hesap kâğıdı var (TESMER hesap makinesi yasak → doğru), vurgulama YOK |
| Kartlara çevirme (flashcards, SRS) | ✅ ReadyDecks + kendi kartın | ✅ | ✅ | ⚠ hap kartı var; "kartıma ekle" düğmesi YOK (26.08 katman 3) |
| Akran yüzdesi (bu şıkkı seçenlerin %) | ✅ | ✅ | ✅ | ⚠ kodda var (`deneme.html`), Kaydır-Çöz'de YOK |
| Hazırlık skoru / geçme tahmini | ✅ SmartPath | ✅ | ✅ ReadySCORE | ✅ Hazırlık skoru (sınav DNA ağırlıklı) |
| Konu bazlı performans | ✅ | ✅ | ✅ | ✅ ders bazlı bar; konu bazlı YOK |
| AI asistan ("anlamadım, açıkla") | ✅ UAsk | ✅ Newt | ❌ | ⚠ Net Cevap motoru var, ekrana bağlı değil |
| Çıkmış-sınav künyesi ("N dönemde çıktı") | ❌ | ❌ | ❌ | ✅ tekel koz |
| Canlı mevzuat bağı, kaynak metni tek tık | ❌ | ❌ | ❌ | ✅ tekel koz (Maliyet'te gizli, kaynak deseni açık) |
| Sen çöz (ikiz soru, tablo doldurma / sürükleme) | ❌ | ❌ | ❌ | ✅ tekel koz |
| Öğrenci simülasyonu ile "öğretiyor mu" ölçümü | ❌ | ❌ | ❌ | ✅ 06.09 FAZ Ö (Sonnet öğrenci) |

## 2. 06.09'da uygulananlar (bu dosyayla birlikte)
- **Şık eleme** ✕ (Becker/Gleim sınav arayüzü alışkanlığı; sınavda kâğıtta yapılan eleme burada da yapılır, cevap anında kayda geçer).
- **Soru süresi** ⏱ (karta gelince başlar, cevapta durur; cevap satırında görünür). Sınav ortalaması bilinmediği için kıyas yazılmaz;
  ölçüm birikince ders bazlı "sen / diğerleri" gelir.
- **Konu girişine somut örnek** (Becker konsept videosunun metin karşılığı) — hesapsız, olay anlatır (Haiku aritmetiği güvenilmez, ölçüldü).
- **Teori kalıbı ayrıldı**: kural kartı (formül tahtası yerine), "kuralı sen söyle" (sayı tahmini yerine), "Ne soruluyor" satırı = soru kökü.

## 3. Sıradaki (öneri, karar Cem'de)
| # | Özellik | Neden | Bedel |
|---|---|---|---|
| R1 | **Akran yüzdesi** Kaydır-Çöz'e (şık başına "%N bunu seçti") | UWorld'ün en çok övdüğü özellik, bizde kodda var; kasa (`kagit_kayit`/cevap kaydı) basılınca sayı gelir | 0 + SQL |
| R2 | **"Kartıma ekle"** (hap / kavram / kural kartı → SRS destesi) | Üyelik kancası; UWorld ReadyDecks | 1 gün, 0 |
| R3 | **Vurgulama** (soru metninde işaretleme, kalem gibi) | Sınav arayüzü standardı; kâğıt eşlemesiyle birleşir | 0,5 gün |
| R4 | **"Anlamadım" düğmesi** → Net Cevap motoru (soru + adım bağlamıyla) | Becker Newt / UWorld UAsk; motor hazır, OPENROUTER_KEY Cem'de | 0 + anahtar |
| R5 | **Timed mode** Kaydır-Çöz içinde (süre çubuğu, sınav ritmi) | Tutor/timed ikilisi standart | 0,5 gün |
| R6 | **Konu bazlı performans** (ders altında konu barı) | Hepsinde var; verimiz konu etiketli | 0,5 gün |
| R7 | **İllüstrasyon** (her soruya bir görsel) | UWorld farkı; bizde tablo/animasyon var, resim yok; SVG üretimi bedel ister | ölçülmedi |

## 4. Bizde olup onlarda olmayan, vitrinde bağırılacak
Çıkmış künye · canlı mevzuat bağı · Sen çöz · "önce sen dene" · kâğıt eşlemesi · öğrenci simülasyonu · Türkçe + üç sınav + fiyat.
