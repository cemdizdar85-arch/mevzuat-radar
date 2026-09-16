# KGK BASIM PLANI — 16.09.2026 (Cem onayı bekler, hiçbir şey başlatılmadı)

Kaynak ölçümü: [KGK-KAYNAK-OLCUMU.md](KGK-KAYNAK-OLCUMU.md) · dağılım ve paylar: masaüstü `KGK-Sinav-Kaynak-Basim-Plani.xlsx` (8 sayfa, üreten: `arac/kgk-basim-excel.ps1`).

## 1 · Neden Denetim modülüyle başlıyoruz

| Modül | Kaynak eşleşmesi | Şimdi basılabilir | Önce onarım | Basılamaz |
|---|---:|---:|---:|---:|
| **b) Türkiye Denetim Standartları** | %100 | **363** | 73 | 0 |
| a) Muhasebe Standartları | %100 | 395 | 37 | 15 |
| ç) Sermaye Piyasası | %100 | 418 | 27 | 0 |
| d) Bankacılık | %100 | 303 | 96 | 0 |
| e) Sigortacılık | %100 | 326 | 80 | 0 |
| f/g) Sürdürülebilirlik | %100 | 392 | 7 | 0 |
| c) Kurumsal Yönetim + Finansal Yönetim | %100 | 98 | 0 | 304 |

**Toplam (7 modül): şimdi basılabilir 2.295 · önce onarım 320 · basılamaz 319.**

Denetim modülünün üstünlüğü: **34 BDS'nin tamamı resmî metinle TAM** (15.09–16.09 hakikat ölçümü), ek paragrafları (A-serisi) etiketli, dayanak ad köprüsü kurulu. Kurumsal Yönetim en sona kalır: 304 soruluk Finansal Yönetim kısmı resmî metinsiz (SPL kararı bekliyor).

## 2 · Dalga yapısı (önerilen)

**Dalga 1 — pilot, 5 kaynak / ≈107 soru.** En çok çıkan ve hepsi TAM olan beşi: BDS 315 (26) · BDS 200 (22) · BDS 330 (21) · BDS 530 (20) · BDS 240 (18).
Amaç: ret oranını ve soru başına gerçek bedeli ÖLÇMEK. Dalga 2'ye ancak bu ölçüm görüldükten sonra geçilir.

**Dalga 2 — kalan TAM kaynaklar, ≈256 soru.** BDS 500/505/540/570/600/700/705/720, BDS 210/230/250/260/265/300/320/402/450/501/510/520/550/560/580/610/620/701/706/710, GDS 3000/3400/3402, İHS 4400, BDY, 660 KHK.

**Dalga 3 — onarım sonrası, ≈73 soru.** ETİK Kurallar (23) ve KYS 1 (17): ambarda resmî metin var, paragraf etiketi eksik (hakikat ölçümü "EKSİK"). Önce parasız onarım, sonra basım.

## 3 · Bedel (ölçülmüş, tahmin değil)

Yerel bedel defterinden (01.09 sonrası, **güncel resmî fiyatla** Sonnet 5 = 2/10, Opus 5 = 5/25, Haiku 4.5 = 1/5; toplu %50):
- 103 model üretimi parti · 2.792 soru · 411,79 USD
- **Soru başına: medyan 0,164 · alt çeyrek 0,099 · üst çeyrek 0,225 USD**

| | Soru | Beklenen bedel (medyan) | Aralık (çeyrekler) |
|---|---:|---:|---:|
| Dalga 1 (pilot) | 107 | **≈18 USD** | 11–24 USD |
| Dalga 2 | 256 | ≈42 USD | 25–58 USD |
| Dalga 3 (onarım sonrası) | 73 | ≈12 USD | 7–16 USD |
| **Denetim modülü toplam** | **436** | **≈72 USD** | 43–98 USD |

⚠ **Yerel defter harcamanın yalnız yaklaşık üçte birini görüyor** (bulut koşuları Anthropic konsolunda; 30 günde 750 USD github-robotlar). Basım YERELDE koşarsa yukarıdaki rakam geçerlidir; bulutta koşarsa bedel ayrıca ölçülmelidir.
⚠ **Kredi 145 USD ve otomatik yükleme kapalı.** Dalga 1 + Dalga 2 (≈60 USD) krediye sığar; modülün tamamı da sığar ama diğer modüllere yer kalmaz.

## 4 · Kalite kapıları (değişmez)

Cem 16.09: "Sitede tek bir yanlış soru olmayacak." Basımda hiçbir kapı gevşetilmez:
FAZ A kod kapıları (uzunluk, hesap kodu, klişe, çeldirici, aile, ilgisiz teori süzgeci) · hakem (Haiku) · kör çözüm (Opus, `-KorKaynak`) · hakem2 (Sonnet) · teori ikizi + simülasyon · geri okuma. Model, düşünme derinliği ve jeton tavanları aynen.

## 5 · Koşu biçimi

- Her dalga **toplu** koşar: `$env:MEVZUAT_TOPLU_BEKLE_DK='1440'`, üretici `-Toplu`.
- 16.09'da giren iki tasarruf (aynı kalite, yarı fiyat): onarım turu parmak izi tuzu · ikinci toplu dalga. Onarım koşuları `-OnarimTuru r2` ile.
- Parti bitmeden hat yeniden başlatılmaz (çift ödeme).
- Her dalga sonunda: ret oranı, soru başına gerçek bedel ve ilgisiz TEORİ payı ölçülüp bu belgeye yazılır.

## 6 · Cem'den istenen karar

1. **Denetim modülü Dalga 1 başlatılsın mı?** (107 soru, ≈18 USD, yerel koşu)
2. **Koşu yerel mi bulutta mı?** (bulutta bedel görünmez, ayrı ölçüm gerekir)
3. Kredi 145 USD; dalga 1+2 sonrası kalan ≈85 USD.

Karar gelene kadar hiçbir üretim başlatılmadı.
