# FİŞ FABRİKASI — YAPIM PLANI (v2 — Cem'in tarifiyle düzeltildi)

> **Ne:** Mali müşavir ile mükellefin ARASINDAKİ platform. Mükellef banka ekstresini,
> fişlerini, muhasebenin istediği her evrakı buraya yükler; muhasebeden çıkan
> beyanname/tahakkuklar buradan mükellefe iner; **ödeme bizim sistem üzerinden** yapılır;
> istenirse yüklenen ekstre/fişleri ücret karşılığı BİZ okuyup **Luca (ve diğer
> programların) fiş aktarım Excel'ine** çeviririz.
> **Konum:** İki firmanın aracısıyız. Üç gelir musluğu tek platformda.
> **Temel:** Evrak Radarı (evrak-app.html + Supabase Faz B) zaten uçtan uca çalışıyor —
> Fiş Fabrikası onun üstüne kurulan 3 kat.

---

## RESİM (tek bakışta)

```
MÜKELLEF                    PLATFORM (biz)                    MUHASEBE BÜROSU
─────────                   ──────────────                    ───────────────
banka ekstresi  ──────►  [KAT 1: EVRAK AKIŞI]  ──────►  eksik evrak bitti, kovalama bitti
fiş/fatura      ──────►  (Evrak Radarı - VAR)
                                   │
beyanname/tahakkuk ◄─────  [KAT 2: BEYANNAME DAĞITIM]  ◄──  büro toplu yükler,
mükellef görür/indirir     (VKN+dönem otomatik eşleşme)      robot mükellefe dağıtır
                                   │
muhasebe ücreti ──────►  [KAT 3: TAHSİLAT]  ──────►  büronun alacağı tahsil olur
                         (lisanslı ödeme kuruluşu             (komisyon bize)
                          altyapısıyla)
                                   │
ekstre/fiş      ──────►  [KAT 4: FİŞ FABRİKASI]  ──────►  Luca'ya hazır fiş Excel'i
                         (ücretli üretim servisi)             (veri girişi bitti)
```

---

## KAT 1 — EVRAK AKIŞI (mevcut, genişletilecek)
Evrak Radarı zaten kurulu: büro evrak listesi tanımlar, mükellef yükler, SMS/hatırlatma.
Eklenecek: evrak türü şablonları ("banka ekstresi - Ocak", "Z raporları", "gider fişleri"),
dönem bazlı otomatik eksik listesi, yüklenince büroya bildirim.

## KAT 2 — BEYANNAME/TAHAKKUK DAĞITIMI (yeni)
**Hedef:** "Çıkan beyannameleri portala otomatik çekmek."
**Gerçekçi ve yasal ilk sürüm (v1):** GİB/Luca'dan indirilen beyanname-tahakkuk PDF'lerinin
dosya adında VKN + dönem + tür ZATEN yazıyor (ör. `4541622626_Kdv1_202604..._TahakkukFisi.pdf`).
Büro dosyaları toplu sürükler → robot dosya adından okur → doğru mükellefin panosuna,
doğru dönem klasörüne otomatik dağıtır + mükellefe "beyannameniz hazır" SMS/e-posta.
Büro için iş: klasörü sürüklemek. Mükellef için görüntü: "her şey otomatik geliyor".
**v2 (araştırılacak):** GİB entegrasyonu/e-beyanname arşivinden doğrudan çekim — şifre
saklamayı gerektiren hiçbir yöntem KULLANILMAZ (güvenlik/yasal kırmızı çizgi).

## KAT 3 — TAHSİLAT: PARA BİZİM SİSTEMDEN (yeni)
**Hedef:** Mükellef, muhasebe ücretini (ve büronun tanımladığı diğer kalemleri) platformdan
öder; "işlemler bizim istemimiz üzerinden bitsin."
**⚠️ DİREKTÖR KARARI — yasal çerçeve:** Türkiye'de başkası adına ödeme aracılığı 6493
sayılı Kanun kapsamındadır; parayı fiilen KENDİ hesabımızda toplayamayız (TCMB lisansı
ister). Doğru kurulum: **lisanslı ödeme kuruluşu altyapısı** (iyzico / PayTR "pazaryeri /
alt üye işyeri" modeli) — mükellef platformda öder, para ödeme kuruluşunda bölüşülür:
büronun payı büroya, **komisyonumuz bize** otomatik düşer. Para "bizim sistemden geçer"
ama yasal olarak lisanslı kuruluş taşır. Aynı model Getir/Trendyol esnaf ödemeleri gibi.
Özellikler: ücret tanımı (aylık sabit/kalem bazlı), otomatik hatırlatma ("ödemeniz gecikti"),
tahsilat raporu, makbuz e-postası.

## KAT 4 — FİŞ FABRİKASI ÇEKİRDEĞİ: ÜCRETLİ FİŞ ÜRETİM SERVİSİ (yeni)
**Hedef:** Büro isterse, mükellefin yüklediği banka ekstresini/fişleri ÜCRET karşılığı biz
okur, **Luca fiş aktarım Excel'i** (ve sırayla diğer programların formatları) hâlinde teslim
ederiz. "Muhasebe bürosunun banka + fiş veri girişini biz yapacağız."
**Çıktı sözleşmesi (Cem'in gerçek Luca şablonundan birebir okundu):** sayfa "Fiş Aktarım
Şablon", 14 kolon: Fiş No | Fiş Tarihi | Fiş Açıklama | Hesap Kodu | Evrak No | Evrak
Tarihi | Detay Açıklama | Borç | Alacak | Miktar | Belge Türü | Para Birimi | Kur | Döviz Tutar.
Diğer programlar (Zirve, Mikro, ETA...) format eklenerek gelir (format = JSON harita, kod değil).
**Üretim hattı:**
- Banka ekstresi (CSV/XLS) → deterministik parse (rakam birebir, uydurma imkânsız) →
  anahtar kelime→hesap kural motoru (büro düzeltir → kural öğrenilir, bir daha sorulmaz)
- Kağıt fiş fotoğrafı → görüntü okuma + **insan onay ekranı** (onaysız fiş üretilmez)
- Her fişte ΣBorç=ΣAlacak zorunlu; KDV çapraz kontrol (matrah×oran≈KDV); dengesiz fiş çıkmaz.
**Ücret modeli:** işlem başına (ekstre satırı / fiş adedi) — büro kendi müşterisine
yansıtır ya da içerir; bize kesin gelir.

---

## GELİR MODELİ (3 musluk)
| Musluk | Kaynak | Model |
|---|---|---|
| 1. Platform aboneliği | büro başına | aylık (mükellef sayısına kademeli) |
| 2. Tahsilat komisyonu | her ödemeden | % (ödeme kuruluşu payı düşülür) |
| 3. Fiş fabrikası | işlem başına | satır/fiş adedi ücreti |

## SIRA (sprintler)
1. **KAT 2 — Beyanname dağıtım robotu** (en hızlı görünür değer; dosya adı deterministik,
   Evrak Radarı'nın üstüne direkt oturur; Cem'in kendi bürosuyla canlı pilot)
2. **KAT 4a — Banka ekstresi → Luca Excel** (Cem'in bürosunun gerçek ekstreleriyle;
   Luca'ya fiilen import edilmeden "bitti" denmez)
3. **KAT 3 — Tahsilat** (iyzico/PayTR pazaryeri başvurusu paralelde yürür — onay süreci
   haftalar alabilir, ERKEN başlanır)
4. **KAT 4b — Fiş fotoğrafı hattı** (insan-onaylı)
5. Diğer program formatları (Zirve/Mikro/ETA)

## CEM'DEN CEVAPLAR
1. Luca şablonundaki **Belge Türü** kolonunun kod listesi (dolu bir örnek şablon yeter)
2. İlk pilot: kendi büron + kaç mükellef?
3. Tahsilatta ilk kalem sadece muhasebe ücreti mi, başka kalemler var mı?
4. İlk banka(lar) hangisi (ekstre formatını ona göre haritalarız)?
