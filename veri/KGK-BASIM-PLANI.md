# KGK BASIM PLANI — 16.09.2026 (dalga 1 planı hazır · basım artık BULUTTA · başlatma Cem onayında)

Kaynak ölçümü: [KGK-KAYNAK-OLCUMU.md](KGK-KAYNAK-OLCUMU.md) · dağılım ve paylar: masaüstü `KGK-Sinav-Kaynak-Basim-Plani.xlsx` (8 sayfa, üreten: `arac/kgk-basim-excel.ps1`).

## 1 · Neden Denetim modülüyle başlıyoruz

| Modül | Kaynak eşleşmesi | Şimdi basılabilir | Önce onarım | Basılamaz |
|---|---:|---:|---:|---:|
| **b) Türkiye Denetim Standartları** | %100 | **403** | 33 | 0 |
| a) Muhasebe Standartları | %100 | 395 | 37 | 15 |
| ç) Sermaye Piyasası | %100 | 418 | 27 | 0 |
| d) Bankacılık | %100 | 303 | 96 | 0 |
| e) Sigortacılık | %100 | 326 | 80 | 0 |
| f/g) Sürdürülebilirlik | %100 | 392 | 7 | 0 |
| c) Kurumsal Yönetim + Finansal Yönetim | %100 | 98 | 0 | 304 |

**Toplam (7 modül, 16.09 11:50 tazeleme): şimdi basılabilir 2.335 · önce onarım 280 · basılamaz 319.**

Denetim modülünün üstünlüğü: **34 BDS'nin 33'ü resmî metinle TAM** (16.09 hakikat ölçümü); BDS 720'de 9 paragraf ayrı parça değil (metni komşu parçada, soru yazılabilir ama paket hassasiyeti düşük). Ek paragrafları (A-serisi) etiketli, dayanak ad köprüsü kurulu. Kurumsal Yönetim en sona kalır: 304 soruluk Finansal Yönetim kısmı resmî metinsiz (SPL kararı bekliyor).

## 2 · Dalga yapısı (önerilen)

**Dalga 1 — pilot, 5 kaynak / ≈107 soru.** En çok çıkan ve hepsi TAM olan beşi: BDS 315 (26) · BDS 200 (22) · BDS 330 (21) · BDS 530 (20) · BDS 240 (18).
Amaç: ret oranını ve soru başına gerçek bedeli ÖLÇMEK. Dalga 2'ye ancak bu ölçüm görüldükten sonra geçilir.

**Dalga 2 — kalan kaynaklar, ≈256 soru** (BDS 720 hariç hepsi TAM). BDS 500/505/540/570/600/700/705/720, BDS 210/230/250/260/265/300/320/402/450/501/510/520/550/560/580/610/620/701/706/710, GDS 3000/3400/3402, İHS 4400, BDY, 660 KHK.

**Dalga 3 — ≈40 soru, ONARIM BİTTİ (16.09 11:30).** ETİK Kurallar (23) ve KYS 1 (17) artık resmî metinle TAM (hakikat ölçümü). Ayrıntı: [KGK-KAYNAK-OLCUMU.md](KGK-KAYNAK-OLCUMU.md) 16.09 ~12:00 bölümü. Kalan tek onarım: BDS 720 (9 paragraf etiketsiz).

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

## 5a · Dalga 1 — hazır, başlatılmadı (16.09 12:00)

Cem onayı geldi ("1.2.3 üçünüde yap"). Plan ve konu dosyaları depoda:
- Plan: `veri/sinav/plan-kgk-a1-denetim.json` (5 satır, ders "Türkiye Denetim Standartları", toplu, KAPI-AİLE açık)
- Konu: `veri/sinav/konu/kgk-a1-bds315|200|330|530|240.json` — köprüdeki (`veri/fabrika/konu-koprusu.json`) o standarda ait TÜM KGK konuları (35/26/28/27/36), dönem sayısına göre sıralı; üretici son 7 dönem penceresiyle ilk `adet` konuyu seçer.
- Kasada `kgk-a1*` etiketi yok (çakışma 0). Sınav kolunu tutan oturum (92) eşzamanlı koşuya izin verdi.

**16.09 öğleden sonra değişti:** toplu basım artık YALNIZ BULUTTA (CLAUDE.md kuralı, 92 bulut hattı: 320 dk'da kendini yeniden tetikler, toplu parti kaydı ambarda, çift ödeme kapısı açık). C: diski engeli kalktı. Bulut bedeli yerel defterde görünmez → koşu sonrası Anthropic konsolundan ayrıca ölçülür.

Başlatma (Cem onayıyla). 17.09 kuralı (CLAUDE.md "PARA HARCAYAN SORU BASIMI KURALI"): bu dalga KGK'nın **ölçüm koşusudur**, bütçe
zorunlu ve en çok 25 USD. Eski "≈18 USD" tahmini üretilen soru başınaydı; bitirmenin 16.09 ölçümüyle (yayına giren soru başı ≈0,25 USD)
107 soru ≈25–30 USD tutabilir → 25 USD tavanında plan yarıda kırmızı durabilir (ölçüm için yeterli; temiz bitmesi istenirse plan ~80 soruya
indirilir — karar Cem'de).
```bash
gh workflow run bulut-uretim.yml -f plan=veri/sinav/plan-kgk-a1-denetim.json -f paralel=5 -f butce_usd=25
```
Bitince: `arac/ret-kutugu.ps1` + ret oranı + soru başına gerçek bedel bu belgeye.

## 6 · Cem'den istenen karar

1. ~~Denetim modülü Dalga 1 başlatılsın mı?~~ **Onaylandı 16.09** — koşu yeri buluta taşındı; başlatma için son "bas" bekleniyor (bkz. 5a).
2. **Koşu yerel mi bulutta mı?** (bulutta bedel görünmez, ayrı ölçüm gerekir)
3. Kredi 145 USD; dalga 1+2 sonrası kalan ≈85 USD.

Hiçbir üretim başlatılmadı (16.09 12:00).
