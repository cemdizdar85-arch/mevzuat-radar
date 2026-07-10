# Mevzuat Radarı

Firma profiline göre mevzuatı tarayıp "hap bilgi kartı" olarak sunan abonelik platformu.
İş planının tamamı: `../Mevzuat_Radari_Is_Plani_1.xlsx`

## Şu an ne var? (v0.1)

**Yükümlülük Karnesi** — açılış üçlüsünün 1 numaralı kancası, ücretsiz parça.
Firma 4-5 soruya cevap veriyor, sistem hangi yasal yükümlülüklere tabi olduğunu
renk kodlu karne olarak çıkarıyor + e-posta yakalıyor. Kurulum gerektirmez, tek dosya.

- Dosya: `index.html`
- **Açmak için:** dosyaya çift tıkla — tarayıcıda açılır. Sunucu/kurulum gerekmez.
- Girilen veriler tarayıcıdan dışarı çıkmaz (kayıt yok). E-posta yalnızca ziyaretçi
  onay verip "Haber ver" derse gönderilir.

### Kapsadığı yükümlülükler (İş Planı sayfa 9 — Eşik Listesi)
Çalışan sayısına bağlı: engelli kotası, İSG uzmanı+hekim, İSG kurulu, çalışan temsilcisi,
VERBİS, emzirme odası/kreş, toplu işten çıkarma · Ciroya bağlı: e-Fatura/e-Arşiv/e-Defter/
e-İrsaliye, bağımsız denetim, transfer fiyatlandırması · Şirket türü/sermayeye bağlı:
sözleşmeli avukat, TTK 1524 internet sitesi, KEP/e-Tebligat, TTK 376 sermaye kaybı · Sektörel: TMGD.

## Eşik değerleri — durum

**Temmuz 2026 itibarıyla güncellendi** (web araştırması). Kritik değerlerin son hâli:

| Yükümlülük | Güncel eşik |
|---|---|
| Bağımsız denetim | aktif 500M TL / net satış 1 milyar TL / 150 çalışan — en az 2'si, 2 yıl üst üste (11066 s. Karar, 17.03.2026 RG) |
| VERBİS | 50+ çalışan **veya** 100M TL bilanço |
| Sözleşmeli avukat (AŞ) | esas sermaye 1.250.000 TL+ (TTK asgari 250K × 5) |
| e-Fatura | 3M TL genel (e-ticaret/gayrimenkul/araç: 500K) |
| e-İrsaliye | 10M TL genel (ÖTV/demir-çelik/hal: ciro şartsız) |
| Engelli kotası | 50+ işçi → %3 |

> Değerler `index.html` içindeki tek bir `ESIKLER` nesnesinde. Bir değeri değiştirmek
> istersen orayı düzenle. Nihai yayın öncesi, bir SMMM imzasıyla çıkacağı için,
> kritik değerlerin kaynak mevzuattan (RG) son kez teyidi önerilir.

## Canlıya alma + e-posta

Adım adım: **`DEPLOY.md`** dosyasına bak. Özet:
1. Ücretsiz e-posta formu bağla (Formspree) → endpoint'i `index.html`'deki `EPOSTA_ENDPOINT`'e yapıştır
2. GitHub'a ücretsiz repo aç → `index.html`'i yükle → Settings ▸ Pages ile yayınla
3. `https://KULLANICI.github.io/mevzuat-radar/` adresinden canlı

## SEO sayfaları (`sayfalar/`)

Her eşik için Google'da aranan bir soruyu mini hesaplayıcıyla cevaplayan, altında
karneye CTA veren statik sayfalar. 15 sayfa + bir hub (`sayfalar/index.html`).
Örnekler: e-fatura-zorunlulugu, bagimsiz-denetim-esigi, engelli-calistirma,
verbis-kayit, avukat-bulundurma, emzirme-odasi-kres…

- **Üreteç:** `sayfalar/olustur.ps1`. Yeni sayfa eklemek için içindeki `$pages`
  tablosuna bir kayıt ekle, sonra çalıştır:
  `powershell -ExecutionPolicy Bypass -File sayfalar/olustur.ps1`
  (Not: .ps1 dosyası Türkçe için UTF-8 **BOM'lu** kaydedilmeli — düz apostrof `'`
  kullan, kıvrık `’` kullanma; PowerShell kıvrık tırnağı sınırlayıcı sanıyor.)
- Her sayfada: mini hesaplayıcı + açıklama + FAQ (JSON-LD) + "ücretsiz karne" CTA'sı.

## Yol haritası (İş Planı — Faz 1)

Açılış üçlüsü: **[✓] Yükümlülük Karnesi (e-posta yakalamalı)** · **[✓] Eşik SEO sayfaları** · [ ] GTİP Sağlık Kontrolü · [ ] Haftalık bülten

Sonraki adımlar:
1. Canlıya al (DEPLOY.md) — index.html **+ sayfalar/ klasörü** birlikte + reklam/LinkedIn trafiği
2. GTİP Sağlık Kontrolü (gerçek tarama motoru — Node.js kurulumu gerekir)
3. Resmî Gazete gece tarayıcısı + hap kart üretim hattı + abonelik

## Teknik not
Karne bilinçli olarak **sıfır bağımlılıkla** yazıldı — sadece tarayıcı yeter.
GTİP radarı ve gece tarayıcıları için ileride Node.js kurulumu gerekecek.
