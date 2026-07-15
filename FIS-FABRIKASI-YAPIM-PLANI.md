# FİŞ FABRİKASI — YAPIM PLANI

> **Ne:** Belgeyi at → muhasebe fişini al. E-fatura XML'i, banka ekstresi, GİB/SGK tahakkuk
> fişi gibi belgeleri **Luca'ya hazır fiş aktarım Excel'ine** çeviren fabrika.
> **Neden yıldız:** SMMM bürosunun en büyük zaman kaybı veri girişidir. Bu araç saatlik işi
> dakikaya indirir; sitedeki diğer her şey "bilgi" verirken bu **iş** yapar. Ücretli kapının
> ana ürünü budur.
> **Sahip:** Cem Dizdar (SMMM) — alan uzmanı + ilk kullanıcı. İlk testler Cem'in kendi
> bürosunun gerçek belgeleriyle yapılır.

---

## 0) ÇIKTI SÖZLEŞMESİ (değişmez hedef)

Cem'in gerçek Luca şablonundan birebir okundu (`fis_aktarim_sablon (3) Luca.xlsx`,
sayfa adı **"Fiş Aktarım Şablon"**, 14 kolon — sıra dahil aynen korunur):

| # | Kolon | Doldurma kuralı |
|---|---|---|
| 1 | Fiş No | Fabrika sıra verir (1'den başlar; her belge = 1 fiş) |
| 2 | Fiş Tarihi | Belge tarihinden (gg.aa.yyyy) |
| 3 | Fiş Açıklama | Otomatik: "SATIŞ FATURASI - ABC LTD - A123" gibi |
| 4 | Hesap Kodu | Eşleştirme motorundan (aşağıda §3) |
| 5 | Evrak No | Fatura/dekont numarası birebir |
| 6 | Evrak Tarihi | Belge tarihi |
| 7 | Detay Açıklama | Satır bazlı açıklama |
| 8 | Borç | Belgeden birebir (kuruş hassas) |
| 9 | Alacak | Belgeden birebir |
| 10 | Miktar | Varsa (kalem miktarı), yoksa boş |
| 11 | Belge Türü | ❓ Luca'nın kod listesi lazım — Cem'den DOLU örnek şablon istenecek (uydurulmaz) |
| 12 | Para Birimi | TRY varsayılan; dövizli belgede belge kuru |
| 13 | Kur | Dövizliyse |
| 14 | Döviz Tutar | Dövizliyse |

**Altın kural (her fişte, istisnasız):** `ΣBorç = ΣAlacak` değilse o fiş ÜRETİLMEZ,
"kontrol gerekli" kuyruğuna düşer. Dengesiz fiş asla Excel'e yazılmaz.

---

## 1) MİMARİ İLKELER (tartışması bitmiş kararlar)

1. **MVP'de hiçbir rakam yapay zekâdan gelmez.** E-fatura XML'i ve banka CSV'si YAPISAL
   veridir → rakamlar belgeden **birebir kopyalanır** (deterministik parse). Uydurma
   fiziksel olarak imkânsız. (Rakam disiplini kuralımızın fabrikadaki hâli.)
2. **Belgeler tarayıcıda işlenir, sunucuya GİTMEZ** (MVP). Mükellef verisi kimseye
   yüklenmez → KVKK derdi yok + güçlü satış cümlesi: *"Faturalarınız bilgisayarınızdan
   çıkmaz."* (Statik JS; mevcut site altyapısıyla aynı, yeni sunucu maliyeti sıfır.)
3. **AI yalnız yapısal olmayan belgede** (Sprint 4: fotoğraf/karışık PDF) ve **her zaman
   insan-onay ekranının arkasında**. AI'ın çıkardığı satır sarı işaretlenir, onaysız
   Excel'e inmez.
4. **Öğrenen eşleştirme:** kullanıcı bir carinin/ürünün hesap kodunu bir kez düzeltir,
   fabrika kuralı kaydeder (localStorage → üye olunca Supabase), bir daha sormaz.
   Kullanıldıkça hızlanan araç = terk edilmeyen araç.
5. **Denetçi kapısı:** üretilen her Excel, indirme öncesi yapısal kontrolden geçer
   (denge, KDV çapraz kontrol, tarih format, boş zorunlu alan). Sitedeki "hiç hata
   çıkmasın" kültürü aynen burada.

---

## 2) SPRINTLER

### Sprint 1 — E-FATURA/E-ARŞİV XML → LUCA (MVP, yıldızın çekirdeği)
- **Girdi:** UBL-TR XML (tek tek veya çoklu seç / zip). SMMM'ler bunları GİB portalı ve
  entegratörden toplu indirebiliyor — hammadde zaten elde.
- **Akış:** XML'den satıcı/alıcı VKN-unvan, fatura no, tarih, kalem matrahları, KDV
  oran-tutarları (birden çok oran desteklenir), toplam → yön tespiti (mükellefin VKN'si
  alıcıysa ALIŞ, satıcıysa SATIŞ) → fiş satırları:
  - **SATIŞ:** 120 (Borç, toplam) / 600 (Alacak, matrah) / 391 (Alacak, KDV — oran başına ayrı satır)
  - **ALIŞ:** 153 veya 770/740 (Borç, matrah — kural motoru seçer) / 191 (Borç, KDV) / 320 (Alacak, toplam)
  - Tevkifatlı faturada 2 No.lu KDV satırları (küratörlü kural).
- **Ekran:** sürükle-bırak → önizleme tablosu (fiş fiş) → düzelt → "Luca Excel'ini indir".
- **Test (gerçek veriyle):** Cem'in bürosundan 10 gerçek e-fatura XML'i → üretilen Excel
  Luca'ya fiilen import edilir → birebir doğruluk teyidi. **Luca'da başarılı import
  görülmeden Sprint 1 "bitti" sayılmaz.**

### Sprint 2 — BANKA EKSTRESİ → LUCA
- Girdi: bankaların CSV/XLS ekstreleri (ilk hedef: Cem'in çalıştığı bankalar; banka başına
  kolon haritası JSON'u — yeni banka eklemek = 10 satır veri).
- Her hareket → 102 karşılığı fiş; karşı hesap **kural motoru**ndan: açıklamadaki anahtar
  kelime → hesap (ör. "MAAŞ" → 335, "SGK" → 361, "VERGİ/GİB" → 360, cari isim → 120/320).
  Eşleşmeyen → kullanıcıya sor → cevabı kural olarak kaydet (öğrenme burada başlar).

### Sprint 3 — TAHAKKUK FİŞLERİ (GİB + SGK) → LUCA
- Girdi: GİB tahakkuk fişi PDF'leri (KDV/muhtasar/geçici) ve SGK tahakkuk fişi — bunlar
  **metin-PDF** (taranmış değil), deterministik metin çıkarma ile okunur.
- Çıktı: 360/368/361 tahakkuk fişleri + vade bilgisi → Hatırlatıcı Motoru'na (#44) köprü:
  fabrika fişi keserken ödeme gününü de radara yazar. (İki ürün birbirini besler.)

### Sprint 4 — FOTOĞRAF/SERBEST PDF (AI destekli, insan-onaylı)
- Yazarkasa fişi, elden fatura fotoğrafı → görüntüden alan çıkarma (Claude vision) →
  **onay ekranı zorunlu** (madde 1/3 ilkeleri). Güven skoru düşükse alan boş bırakılır,
  asla tahmin yazılmaz.

### Sprint 5 — PARA KAPISI
- Ayda **20 fiş bedava** → e-posta ile +50 → abonelikle sınırsız (leadler tablosu hazır).
- Fiyat mantığı: bir büronun aylık veri giriş saati × asgari maliyet karşılaştırması
  sayfada gösterilir ("bu araç size ayda ~X saat kazandırdı" sayacı — kullanım verisinden,
  uydurma değil).

---

## 3) HESAP EŞLEŞTİRME MOTORU (fabrikanın beyni)

Katman sırası (ilk eşleşen kazanır):
1. **Kullanıcı kuralı** (bu VKN → bu hesap; bu kelime → bu hesap) — öğrenilen.
2. **Belge kuralı** (satış/alış yönü + KDV oranı + tevkifat → standart THP şablonu).
3. **Varsayılan** (alışta 770'e "kontrol et" işaretiyle) — sessiz tahmin YOK, işaretli tahmin var.

Hesap planı: Tekdüzen (THP) varsayılan; büro kendi detay kodlarını (120.01.001 gibi)
kural olarak öğretir.

---

## 4) KALİTE KAPILARI (denetçi kültürü)

| Kapı | Kural | İhlalde |
|---|---|---|
| Denge | her fişte ΣBorç=ΣAlacak (kuruş) | fiş üretilmez, kuyruk |
| KDV çapraz | matrah × oran ≈ KDV (±0,02) | satır sarı işaret |
| Tarih | gg.aa.yyyy + dönem içi mi | uyarı |
| Mükerrer | aynı evrak no + tutar ikinci kez | uyarı "daha önce üretildi" |
| Zorunlu alan | hesap kodu/tarih/tutar boşsa | fiş üretilmez |

---

## 5) AÇIK SORULAR (Cem'e — uydurmak yerine soruyoruz)
1. **Belge Türü** kolonunun Luca kod listesi ne? (Dolu bir örnek şablon yeterli.)
2. Luca'da fiş tipleri (mahsup/tahsil/tediye) import'ta nasıl ayrışıyor — Fiş No serisiyle mi?
3. İlk banka hangisi olsun (en çok ekstre gelen)?
4. Büronun cari detay kod düzeni (120.VKN mi, 120.001 sıra mı)?

## 6) SIRA
1. ✅ Bu plan (commit)
2. Sprint 1 iskeleti: `fis-fabrikasi.html` (sürükle-bırak + UBL-TR parser + önizleme + Excel üretimi, tamamı tarayıcıda)
3. Cem'in 10 gerçek XML'i ile test → Luca'ya gerçek import → düzelt → CANLI
4. Sprint 2'ye geç
