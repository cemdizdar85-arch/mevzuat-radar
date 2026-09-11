# SORU İŞİ — YAZARKEN · CEVAP YAZARKEN · KONTROL EDERKEN

> **11.09.2026, Cem:** *"sen soru çözerken soru kontrol ederken hangi kurallara bakıyorsun
> tümden yazar mısın… soru yazarken cevap yazarken olabilir soru kontrol ederken kalıp
> kontrollerimiz sen nasıl yapıyorsun şimdi yeni aldığımız kararlar da dahil"*

Bu dosya **çalışma listesidir**: elimde bir soru varken, yazarken ve kontrol ederken
hangi soruları sorduğum. Şartnameler ayrı ve bu dosya onların yerine geçmez:

| Dosya | Ne cevaplar |
|---|---|
| `SORU-URETIM-SOZLESMESI.md` | **Kural nedir** — Cem'in 5 kuralı + 22 yürürlükteki kural |
| `SORU-BASMA-KURALLARI.md` | **Yayına çıkabilir mi** — kapı zinciri + m.8 yayın şartı |
| `STANDART-CEVAP-KALIBI.md` | **Ekran nasıl görünür** — Kaydır-Çöz paneli (kilitli) |
| **bu dosya** | **Ben nasıl çalışıyorum** — üç aşamanın kontrol listesi |

**Her satırda üç şey var:** ne bakılır · nasıl ölçülür · **kodda hangi kapı zorluyor**.
Kapı sütunu ⚠ ise o kontrol **otomatik değildir** — insan bakmazsa kaçar.
Bu ayrımı yazmamın sebebi bugünkü ders: **kapı var sanmak, kapı olması değildir.**

---
---

# BÖLÜM 1 · SORU YAZARKEN

## 1.1 · Yazmadan önce (tek satır kural: kaynak okunmadan soru yazılmaz)

| Sıra | Ne yapılır | Neden |
|---|---|---|
| 1 | **Konu kartı** okunur — konu neyi ölçer, dayanağı hangi madde | Soru konudan değil, konu kartından türer |
| 2 | **Kaynak ambardan çekilir**, okunur | Madde/hesap kodu hafızadan **yazılmaz** |
| 3 | **Biçim çapası** seçilir — o konunun GERÇEK çıkmış sorusu | Kalıp taklit edilir, metin değil (telif) |
| 4 | **Ders tavanı** bakılır — p75/p90, `veri/sinav-anatomisi-sgs.json` | Tek 350 değil; ders bazlı (FMuh 421, Ticaret 490, Borçlar 630) |
| 5 | **Tip kotası** bakılır | Ölçülmüş gerçek dağılım (FMuh: kayıt %41 · hesaplama %29 · teori %16) |
| 6 | **Şık kalıbı** bakılır | FMuh 383 soruda: cümle 267 · sayı 61 · hesap 54 |

> ⛔ **Kaynak yüzünden düşen konu plana girmez** — `kaynak-eksik-konular.json`'a iş
> emri yazılır. "Kaynağı yok ama yazayım" yoktur.

## 1.2 · Soruyu yazarken

| Ne | Kural | Kapı |
|---|---|---|
| **Telif** | Çıkmış soru **birebir alınamaz**; yalnız anatomi/mantık referansı | `rag.dayanak_olabilir()` — SQL düzeyinde, iki arama kanalında da koşulsuz |
| **Uzunluk** | Ders tavanını aşmaz | uzunluk kapısı |
| **Tip** | Çapa hesaplama ise teori sorusu yazılamaz | **KAPI-T** |
| **Tek anlam** | Kök tek büyüklük ister; iki okuma iki şıkka çıkmaz | **KAPI-E** |
| **Yıl** | Senaryolar 2026 | **KAPI-Y** |
| **Yasal parametre** | Asgari ücret, kıdem tavanı, KDV/SGK/damga oranı **kaynaksız yazılamaz** | **KAPI-P** |
| **Mülga** | 6762, 818, 5422, 506, 2499, TMS 17/18/39, TFRS 4, SSK, TMSK anılmaz | **KAPI-M** |
| **Süre** | Geçmiş son tarih, eski yıl haddi kullanılmaz | **KAPI-S** |
| **Hesap kodu–ad** | "120 Alıcılar" çifti ambardaki THP adıyla uyuşur | **KAPI-H** |
| **Türkçe harf** | İstem, **üründe görmek istediğin yazımla** (Türkçe harfli) yazılır | **KAPI-D2** |
| **Benzerlik** | Havuzdaki başka soruya çok benzemez | **KAPI-B** |
| **Koku** | Klişe kalıp, yer tutucu unvan ("ABC A.Ş."), anlatıcı ses yok | **KAPI-O** + ikinci hakem |

## 1.3 · Şıkları ve çeldiricileri yazarken

| Ne | Kural | Kapı |
|---|---|---|
| Her yanlış şık **bir yanlış yolun sonucu** olmalı | Üretici o yolun formülünü yazar; rastgele sayı çeldirici değildir | **KAPI-Ç** |
| Şıkta gerekçe olmaz | "…çünkü" şıkkın içine yazılmaz | ⚠ istem düzeyinde |
| Doğru şık tek harfe yığılmaz | Parti içi A–E dağılımı ölçülür, gerekirse taşınır | şık dengesi taşıması |
| Tuzak adı tekdüze olmaz | Aynı ad partide en fazla **2** kez | tuzak tekdüze kontrolü |
| Biçim sınav kalıbına uyar | 7 çıkmış SGS sorusunda ölçülen tutar/uzunluk kalıbı | **KAPI-Ş** |

---
---

# BÖLÜM 2 · CEVAP ve ANLATIM YAZARKEN

Cevap kalıbı **kilitli** (`STANDART-CEVAP-KALIBI.md`). Panelin sırası değişmez.

## 2.1 · Açıklama metni — dört parçalı, sırası sabit

Her şıkkın açıklaması şu kalıpla yazılır (ölçüldü, üretimde bu biçimde):

```
Ne soruluyor: <tek cümle — öğrencinin aradığı büyüklük>
Kural:        <dayanak + hüküm; kaynaktan çıkar>
Hesap:        <sayılarla tek zincir>
Doğrusu:      <sonuç cümlesi>
```

Yanlış şıklarda buna **tuzağın ADI** eklenir: *"Bu şık A ile B'yi karıştırıyor."*

## 2.2 · Panelin parçaları (bu sırayla — kilitli)

| # | Parça | Yazarken kural | Kapı |
|---|---|---|---|
| 1 | **Tuzak satırı** | Tuzağın adı + tek cümle | ⚠ istem |
| 2 | **Sade Doğrusu** | Kısaltma yok (TMS/VUK/TTK/THP/m./p.), madde no yok, hesap kodu yok, "sayılı" yok, ≤45-60 kelime, olayın diliyle | **FAZ S + `SadeKapi`** (2 tur, düşerse sebebiyle loga) |
| 3 | **Hesaplama + kayıt TEK tablo** | Soruda verilmeyen hücre "?" ile gizli; çıplak hesap kodu yok, tam ad yazılır | `cozum_tablo` / `sema` |
| 4 | **Kural / Bu olayda / HAP** | HAP, kural ya da doğrusu ile ≥%60 örtüşüyorsa **gizlenir** (ezber cümlesi değilse gereksiz) | builder |
| 5 | **Kavramlar** | Tanım **yalnız kaynak metninden**; 5+ harfli kelimelerin ≥%35'i kaynakta geçmeli, yoksa kavram **düşer, uydurulmaz** | **KAVRAM kapısı** |
| 6 | **Sınavda** | Dönem listesi `veri/sgs-analiz.json`; alıntı yoksa "gerçek kitapçık metninden" cümlesi **yazılmaz** (boş vaat yok) | builder |
| 7 | **Kaynağı göster** | Ambardaki gerçek madde metni, UZUN adla; hakemin dayandığı cümle sarı. Maliyet'te **gizli** (kaynak tekniğin kaynağı değil) | builder |
| 8 | **Hata bildir** | — | — |

## 2.3 · Nöbetçi anlatımı (adım adım)

| Ne | Kural |
|---|---|
| **ADIM 1** | Sorunun **kendi metni**; verilen rakamlar mavi. Anlatımda yalnız "dikkat" cümlesi |
| Formül yazımı | Tek zincir: `Ad = genel = sayılı = sonuç`; işleçlerin iki yanı boşluk |
| Her adımdan önce | **"Önce sen dene"** — öğrenci tahminini yazar, sonra tahta açılır |
| Konu girişi (FAZ G) | Nedir · sınavda nasıl sorulur · yöntemler, hangisi ne zaman |
| Verilenler (FAZ V) | Sorudaki her sayı: ad + değer + anlam |
| Hata adımı | Öğrencinin **seçtiği şıkkın** tuzağı gösterilir |
| İkiz (Sen çöz) | Aynı yöntem, yeni rakamlar |
| Simülasyon (FAZ Ö) | Hiç bilmeyen rolündeki model adımları okuyup ikizi çözer — **çözemiyorsa anlatım eksiktir** |

> **Birebir ders ilkesi:** hoca sorar, öğrenci dener, hoca düzeltir.
> **Öğrenci hiçbir adımda yalnız okumaz.**

---
---

# BÖLÜM 3 · KONTROL EDERKEN

## 3.0 · Sıralama — neden bu sırayla

Ucuz ve kesin olan önce koşar; model çağıran kapılar en sonda. Bugün ölçüldü:
hakem çağrısı **0,01 USD**, sade **0,009 USD**, konu denetimi **0,0014 USD**, kod kapıları **0**.

`yazım onarımı → uzunluk → şık/biçim → hesap kodu → kavram → tip → çeldirici → yıl →
koku → benzerlik → Türkçe harf → yevmiye dengesi → yasal parametre → mülga → süre →
tek anlam → aritmetik → kör çözüm → hakem → ikinci hakem → simülasyon → karne → Cem örneklemi`

## 3.1 · Cevap doğru mu

| Ne bakılır | Nasıl | Kapı |
|---|---|---|
| İşaretli şık gerçekten doğru mu | Anlatımı **görmeden** bağımsız model çözer, karşılaştırılır | **kör çözüm** (Opus) |
| Doğru şık **şıklar arasında var mı** | Beşinin hiçbiri doğru değilse soru bütünüyle bozuktur | ⚠ **YOK** — `kp-80` bu yüzden geçti |
| Aritmetik tutuyor mu | Her işlem yeniden hesaplanır | aritmetik kapısı |
| Yevmiye denk mi | Her kayıtta borç = alacak | **KAPI-YD** |
| Kök tek anlamlı mı | İki okuma iki şıkka çıkıyorsa ÇİFT-ANLAM | **KAPI-E** |

> ⚠ **"Kör çözüm bağımsızdır" sanılmasın.** `kp-80`'de kör çözüm de yanlış şıkkı seçti;
> çünkü o da **kaynağa değil ezberine** baktı. Kör çözüm üreticiden farklı bir *model*dir,
> farklı bir *bilgi kaynağı* değil. **Kaynak paketi eksikse üç kapı tek kapıya iner.**

## 3.2 · Kaynak — dayanağı var mı, gerçekten var mı

| Ne bakılır | Nasıl | Kapı |
|---|---|---|
| Doğru şıkkın kuralı kaynaktan **çıkıyor** mu | Hakem soruyu + paketi görür; kural yoksa HAYIR | **KAPI-B (dayanak hakemi)** |
| Kaynak konuyla alakalı mı | Konu kartı ↔ belge eşleşmesi | **KAPI-A** |
| Pencere dışı kavram sızmış mı | Dönem sözlüğü dışı kök taşıyan teori notu pakete girmez | **KAPI-K** |
| Madde numarası başlıkla uyuşuyor mu | Dayanaktaki maddeler ambardan çekilip paketin başına konur | **atıf genişletme** + hakem m.6 |
| Madde ambarda yok ise | `atif_ambarda_yok` + hakeme TEYİTSİZ uyarısı | ✅ var |
| **Hakem gördüğü kaynağı mı gösteriyor** | Gerekçede anılan kaynak pakette var mı | ⚠ **YOK** — bkz. 5.2 |

## 3.3 · Hesap kodu

| Ne bakılır | Nasıl | Kapı |
|---|---|---|
| "Kod + ad" çifti doğru mu | Ambardaki THP adıyla karşılaştırılır (269 belgelik sözlük, bedel 0) | **KAPI-H** |
| **Seçilen hesap doğru hesap mı** | Anılan her kodun **tüm grubu** çekilip hakeme verilir; kardeş hesabın tanımı olayı daha birebir karşılıyorsa HESAP-YANLIŞ | ⭐ **KAPI-HG** |

> ⭐ **KAPI-H ≠ KAPI-HG — bugünün asıl dersi.**
> `kp-80`'de "529 Diğer Sermaye Yedekleri" **geçerli bir kod-ad çiftiydi**, KAPI-H'den
> sorunsuz geçti. Kapı *adın* doğruluğuna bakıyor, *hesabın seçimine* değil.
> Doğru hesap 521 Hisse Senedi İptal Kârları'ydı ve 521 pakete hiç girmemişti.
> Ölçüldü: hesap kodunu adıyla anan **92 sorunun 66'sında (%72)** o hesabın tanımı
> pakette yok. KAPI-HG grubu getirir; canlı sınandı — aynı hakem, aynı soru, tek fark
> paket: **EVET → HAYIR**.

## 3.4 · Ders ve konu

| Ne bakılır | Nasıl | Kapı |
|---|---|---|
| Ders kapsamında mı | Hakem, ders tarifi + komşu dersler | **KAPI-C** (`ders_uyum`) |
| Bu konuyu mu ölçüyor | Konu adı geçse bile ölçülen kural başkaysa KONU-DIŞI | **KAPI-D** (`konu_uyum`) |
| **Hakemin dört hükmü de soruluyor mu** | `karar` + `ders_uyum` + `konu_uyum` + `tek_anlam` **hepsi** | ⭐ **m.8.1-a** |
| Etiket adı isabetli mi | Ayrı ikinci görüş turu | ⚠ **turla** — üretim hakemi güvenilir değil |
| Ders adı doğru yazılıyor mu | Eşleşme katlanmış `anahtar`, ekrana `ekran_ad` | `veri/ders-sozlugu.json` |

> ⚠ **Üretim hakeminin `konu_uyum`'una tek başına güvenme.** 636 soruda ayrı tur
> **71 yanlış etiket** buldu ve **71'inde de üretim hakemi "EVET" demişti**.
> Vergi %25 · Mali Tablolar %20 · FM %16 · Meslek %12 · Denetim %8 · Ticaret %8 ·
> Borçlar %5 · Maliyet %2 · İş-SGK %0.

## 3.5 · Telif

| Ne bakılır | Kapı |
|---|---|
| Çıkmış soru dayanak olarak kullanılmış mı | **`rag.dayanak_olabilir()`** — SQL kapısı, iki kanalda da koşulsuz |
| Çıkmış soruya aşırı yakın mı | `rag.telif_komsusu()` — ⚠ eşik **ölçülmedi**, bağlı değil |

> Kural uygulama katmanında değil **veritabanı kapısında** durur — uygulama katmanı unutulabilir.

---
---

# BÖLÜM 4 · KALIP KONTROLÜ

Soru doğru olsa bile **kalıbı eksikse yayın yok.**

## 4.1 · Panel bütünlüğü

`arac/panel-butunluk.ps1` her soruda şunları arar:

| Alan | Kimde zorunlu |
|---|---|
| `sade` (Sade Doğrusu + sınav dili + kavramlar) | **hepsinde** |
| `sema` | sözel/kayıt sorularında |
| `cozum_tablo` · `verilenler` · `adimlar` | hesaplı sorularda |
| `konu_giris` · `ikiz` · `simulasyon` | anlatım fazları |

> 10.09 ölçümü: gate'ten geçen 1.835 sorunun yalnız **12'sinde** tam panel vardı;
> 1.811'inde `sade` yoktu. Kök neden: `kalip-kosucu.ps1`in argüman listesinde `-Sade`
> **yoktu** — üretici bozuk değildi, **çağrılmayan bir faz** vardı.
> 11.09: 636 sorunun **635'inde** sade var (%99,8).

## 4.2 · Kalıp sürümü ve yayın kapısı

| Ne | Kural |
|---|---|
| `kalip_surum` | `v1` (eski) / `v2` (Kaydır-Çöz) |
| Yayın | **v1 asla siteye çıkamaz** |
| Nasıl zorlanıyor | PostgreSQL CHECK: `yayin is not true or kalip_surum = 'v2'` |
| Neden `is not true` | `not yayin` yazılsaydı NULL kapıdan sızardı |
| Sınandı mı | ✅ canlı: v1 satıra `{"yayin":true}` PATCH → **HTTP 400**, kısıt adıyla reddedildi |

## 4.3 · Seçim kapısı (yayına hangi soru girer)

`motor/kalip-kosucu.ps1`:

```
hakem.karar = EVET
  ∧ hakem.ders_uyum ≠ DERS-DISI      ← 11.09'da eklendi
  ∧ hakem.konu_uyum ≠ KONU-DISI      ← 11.09'da eklendi
  ∧ hakem.tek_anlam ≠ CIFT-ANLAM     ← 11.09'da eklendi
  ∧ simülasyon ✓ ∧ kör çözüm ✓ ∧ hakem2 = EVET
```

`arac/sgs-650-bas.ps1` aynı kapıyı **ikinci savunma hattı** olarak tekrar sorar ve
düşen soruyu **sebebiyle** yazar.

## 4.4 · Cem örneklemi — son kapı

Madde 8.2: **örneklemde bir gerçek hata = o dersin partisi bütünüyle geri**, sebep
kütüğe, kapı eklenir. 11.09'da işletildi: Cem `kp-80`'i buldu → kök neden ölçüldü →
KAPI-HG kuruldu → kütüğe `Ö-11.09` yazıldı.

---
---

# BÖLÜM 5 · 11.09.2026'DA ALINAN KARARLAR

Hepsi Cem'in tek bir sorusundan doğdu: *"hakem olmadan soru basmıyorduk, niye bastık?"*

## 5.1 · Eklenen dört kontrol

| # | Kontrol | Ne yakalar | Ölçülen etki |
|---|---|---|---|
| 1 | **m.8.1-a** — hakemin dört hükmü de sorulur | Hakemin KONU-DIŞI damgaladığı ama kapının sormadığı sorular | 648 → 636 (12 soru) |
| 2 | **KAPI-HG** — hesap grubu genişletmesi | Kod-ad çifti geçerli ama **yanlış hesap** seçilmiş sorular | `kp-80` EVET → **HAYIR** |
| 3 | **Konu ikinci görüş turu** | Üretim hakeminin "EVET" dediği yanlış etiketler | 636'da **71 yanlış** (%11,2), ₺36 |
| 4 | **Sessiz kapı yasağı** | Gerekçesini yalnız HTML'e yazıp log'a yazmayan fazlar | FAZ S artık sebebini basıyor |

**m.8.1-a'nın kuralı, tek cümle:** *bir hakem birden çok hüküm veriyorsa, kapı hepsini sorar.*

## 5.2 · Açıkta kalan üç kontrol — ⚠ henüz kapısı yok

1. **"Doğru şık şıklar arasında var mı?"** `kp-80`'de beşinin hiçbiri doğru değildi.
   Hakem "bu şık yanlış" diyebiliyor ama **"doğrusu hiçbiri"** diyecek alanı yok.
2. **"Hakem gördüğü kaynağı mı gösteriyor?"** `kp-80`'de hakem, pakette **olmayan**
   bir tanımı dayanak yazdı. Gerekçede anılan kaynağın pakette bulunup bulunmadığı
   makineyle denetlenebilir — **bedel 0**, henüz yapılmadı.
3. **"Kör çözüm gerçekten bağımsız mı?"** Kör çözüme kaynak paketi verilmiyor;
   ezberden çözüyor. Üreticiyle aynı bilgi tabanını paylaştığı için bağımsız göz değil.

---

# BÖLÜM 6 · ÖLÇÜM ARACININ KENDİSİNİ SINA

11.09'da üç ölçümümü kendim düzelttim; üçü de ilk hâliyle **yanlış karar verdirirdi**:

| İlk sonuç | Düzeltilmiş | Sebep |
|---|---|---|
| "çizim ≈2 saat israf" | **24 dk** | hiç ölçmemiştim, tahmindi |
| hesap kodu eksikliği **%41,6** | **%72** | 3 haneli her sayıyı hesap kodu saymış, "BDS 240"ı da yakalamıştı |
| etiket şüphelisi **182** | gerçek yanlış **71** | sözcük ölçümü anlamı görmez, ~2× abartır |

**Kural:** bir ölçüm sayı üretiyorsa, o sayıyla karar vermeden önce **elle 3-4 vaka
okunur**. Yanlış pozitif üretip üretmediği ancak böyle görünür.
**Sözcük düzeyi ölçümler triyaj içindir, hüküm için değil.**
