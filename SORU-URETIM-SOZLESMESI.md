# TETİKTE — SORU ÜRETİM SÖZLEŞMESİ

> **10.09.2026 · Cem: "harfiyen uyacaksın."** Bu dosya, soru üreten HER hattın
> (RAG motoru `rag-motor/`, PowerShell hattı `motor/kalip-parti-uret.ps1`, elle
> yazım) üstünde bağlayıcıdır. Çelişki çıkarsa **bu dosya kazanır**.
>
> Kural yazmak işin yarısıdır. Her kuralın karşısında **kapısı** yazılıdır:
> `istem` = modele söylenir · `mekanik` = kod reddeder · `parti` = parti
> düzeyinde ölçülür · `insan` = Cem okur.

---

## BÖLÜM A — CEM'İN BEŞ KURALI (10.09.2026)

### A1 · TELİF VE ÖZGÜNLÜK — birebir almak **kesinlikle yasak**

Çıkmış sınav soruları (`veri/cikmis-ders-kalibi-*.json`, çıkmış sınav arşivi)
**yalnızca sınav anatomisini ve mantığını anlamak için** incelenir.

- ⛔ Çıkmış bir soru **birebir kopyalanıp sisteme konmaz** — ne kökü, ne şıkkı.
- ✅ Mantığı alınır; **tamamen özgün, yepyeni**, benzer zorlukta soru türetilir.
- ⛔ Çıkmış soru metni modele "şunu yeniden yaz" diye verilmez. Modele giden şey
  **kalıp bilgisidir** (uzunluk, tip dağılımı, negatif oranı, şık biçimi), soru
  metni değil.

> **Neden:** Bu bir üslup tercihi değil, ürünün hukuki varlık şartıdır. Kopya
> soru barındıran bir bankanın satılabilirliği yoktur.

**Kapı:** `istem` + `mekanik` (üretilen soru kökü, çıkmış arşivle n-gram
benzerliği eşiğini aşarsa reddedilir) + `parti`

### A2 · Türkçe karakter ve doğal dil

- Soru ve çözümde **ş ç ğ ö ü ı İ kusursuz**.
- Dil robotik / çeviri kokmayacak. Ölçüt: **kıdemli bir mali müşavirin ya da
  hukukçunun kaleminden çıkmış gibi** akıcı, tıkız, doğal.

> **Kök ders (02.09):** Üretici istemine ASCII yazılmıştı (`"Dogrusu:"`); model
> **taklit etti** ve kusur 30 sorunun 26'sına yayıldı. **Modele verilen istem,
> üründe görmek istediğin yazımla yazılır.** Model istemin dilini değil,
> BİÇİMİNİ de kopyalar.

**Kapı:** `istem` (Türkçe harfli yazılır) + `mekanik` (`YazimOnar`) + `insan`

### A3 · Ders–konu–madde %100 örtüşme

Soru üretilen konu ile dayanak kanun maddesi **birebir** örtüşecek. "Farklı ders
konusundan soru üretme" hatası tekrarlanmayacak.

**Kapı:** `mekanik` — dayanak **konu kartından** gelir (kayıt), aramadan değil.
Kart yoksa arama sonucu **insan onayına** düşer; onaysız üretim yapılmaz.

> **Ölçülmüş gerekçe (10.09):** Kartsız GVK'da hibrit arama 0/2 ıskaladı;
> "gayrimenkul sermaye iradı" konusuna `geç. m.90` (varlık barışı) dayanak
> geldi. Motor uydurmadı, sıfır soru üretti — ama kart olsaydı doğru maddeyi
> bulurdu. **Kart katmanı süs değil, taşıyıcıdır.**

### A4 · Şık dağılımı ve çeldirici kalitesi

- Doğru cevap sürekli aynı şıkka yığılmayacak (hep A / hep C yok).
- Çeldiriciler adayı **gerçekten düşündürecek** profesyonellikte olacak.

**Kapı:** `parti` — dağılım tek soruda görülmez, parti düzeyinde ölçülür; bir şık
partinin %30'unu aşarsa parti KIRMIZI biter.

### A5 · Sınav kalıbı ve uzunluk

> ⚠️ **DÜZELTME (Cem, 10.09): "ÖSYM" YANLIŞ.** Bu sınavları ÖSYM yapmıyor.
> Kalıp, sınavı **düzenleyen kurumun kendi kalıbıdır**:
>
> | Sınav | Düzenleyen | Bizde ölçülü mü |
> |---|---|---|
> | Staja Başlama (SGS) | **TESMER / TÜRMOB** | ✅ 129 belge, 65 dönem |
> | SMMM Yeterlilik | **TESMER / TÜRMOB** | ✅ 403 + 16 belge |
> | Bağımsız Denetçilik | **KGK** | ✅ 108 belge, 11 dönem |
> | Sermaye Piyasası lisansları | **SPK / SPL** | ❌ ölçülmedi |
>
> Her sınavın kalıbı **kendi arşivinden** okunur; biri diğerinin yerine
> geçmez. SPK hattı henüz ölçülmedi — o sınava soru basılacaksa önce arşivi
> ölçülür.

- Uzunluk ve dil, ilgili sınavın **en son yıllardaki** kalıbına uyacak.
- Kuru terimi doğrudan ezberletmek yerine, bilginin **pratikteki uygulaması**
  vaka formatına çevrilecek: *"...durumunda mükellefin yapması gereken nedir?"*

**Kapı:** `istem` + `mekanik` (uzunluk tavanı) + `parti` (tip kotası)

### A5b · SINAV DİLİ ≠ KANUN DİLİ — terim köprüsü

> **Cem, 10.09:** *"kanunda genel yönetim gideri yazmıyor ama sınavda genel
> yönetim gideri soruyor."* Haklı ve bu **ölçülmüş**: kanun dilinde 2 kez,
> sınav dilinde **369 kez** geçiyor.

Kanun metni ile sınav metni **aynı terimi kullanmıyor**. Soru, adayın sınavda
karşılaşacağı **sınav terimiyle** yazılır; kanunun kendi terimi (genel idare
gideri, genel imalat gideri…) ezberletilmez.

**Ölçülmüş köprü:** `veri/TERIM-CIFTLERI.md` + `veri/terim-ciftleri.json`
(08.09 ölçümü — SGS 65 · KGK 112 · SMMM 16 kitapçık taranmış).
**Karar kuralı:** sınav dili ≥ 5× kanun dili **ve** bire bir karşılık →
`kapi`. Aksi hâlde `dokunma`.

**9 `kapi` çifti** (üretici bunları uygular):

| kanun dili → sınav dili | oran |
|---|---|
| genel idare gideri → **genel yönetim gideri** | 369 / 2 |
| genel imal(at) gideri → **genel üretim gideri** | 490 / 2 |
| DİMM → **direkt ilk madde ve malzeme** | 409 / 11 |
| Dİ → **direkt işçilik** | 385 / 8 |
| GÜG · GİG · GUG → **genel üretim gideri** | 490 / 40 |
| lehte → **olumlu** (sapma yönü) | 760 / 0 |
| aleyhte → **olumsuz** (sapma yönü) | 564 / 2 |

⛔ **Sınırı:** kanun **alıntısına** (tırnak içi hüküm metni) dokunulmaz. Köprü
soru kökünde ve şıklarda çalışır, alıntıda değil.

🔴 **ÇATIŞMA UYARISI — B2 ile birlikte okunur.** Kanunda geçmeyen bir sınav
terimini o kanun maddesine **dayandıramazsın**. "Genel yönetim gideri" gibi bir
terim soruluyorsa dayanak **Tekdüzen Hesap Planı / tebliğ / standart** olmalı,
GVK m.40 değil. Terim köprüsü sınav diliyle yazmayı sağlar; **dayanağı
değiştirmez**.

**Kapı:** `mekanik` — 🔴 **AÇIK BORÇ: köprü yalnız eski PowerShell hattına
(`motor/kalip-parti-uret.ps1`) bağlı. Yeni RAG motoruna (`rag-motor/`)
BAĞLANMADI.** Bağlanana kadar RAG motoru sınav dilini uygulamıyor.

---

## BÖLÜM B — DAHA ÖNCE KONULMUŞ, HÂLÂ YÜRÜRLÜKTE OLAN KURALLAR

> Cem'in 10.09 listesinde yazmadığı ama önceki ölçümlerde kurulmuş ve
> **kaldırılmamış** kurallar. Bunlar A bölümünün altında değil, **yanındadır**.

| # | Kural | Nereden | Kapı |
|---|---|---|---|
| **B1** | **Kaynak okunmadan soru yazılmaz.** Madde / hesap kodu ambardan alınır, hafızadan değil. Yaz → geri oku → karşılaştır. | değişmez | mekanik |
| **B2** | **Metinde yazmayan rakam kullanılmaz** — ne soruda ne açıklamada. Emin değilsen sayı verme. | Kural 1 | istem + insan |
| **B3** | **Mevzuat tarihçesi sorulmaz.** `(Ek: 30/12/1980-2365/46 md.)` künyedir, hüküm değildir. | 10.09 · Kural 9 | istem |
| **B4** | **Sıralama / ezber sorulmaz.** "Kaçıncı ölçü", "hangi bentte", "kaç numaralı fıkra" YASAK. Uygulanış, şart, istisna, süre sorulur. | 10.09 · Kural 10 | istem + **regex** |
| **B5** | **Şıkka gerekçe yazılmaz.** Gerçek sınav şıkkı: *"A) 1.200 TL'lik ertelenen vergi varlığı"* — yalnız sonuç + kısa etiket. Gerekçe doğru cevabı ele verir. | 27.08 · 4b | istem + insan |
| **B6** | **Cevap sızıntısı 4c:** çeldiriciler "her durumda / hiçbir şekilde / yalnızca" mutlakiyetçi kalıbına yığılınca doğru şık (nüanslı-uzun olan) kendini belli eder. En az bir çeldirici de **nüanslı** kurulur; iki şık birbirinin birebir tersi olamaz. | 27.08 | istem + parti |
| **B7** | **Her şık FARKLI kavram yanılgısı** olacak. Aynı tuzak adı partide ≤2 kez. Sığ çeldirici (tutar aynı, hesap değişik) yasak. | 02.09 | istem + mekanik sayaç |
| **B8** | **Doğru şıkkın metni soru kökünde tekrarlanmaz** (sızıntı). | — | mekanik |
| **B9** | **Yapay zekâ izleri:** `ABC/XYZ Ticaret A.Ş.` placeholder unvan · bütün tutarların yuvarlak olması · "bu bağlamda / önem arz etmektedir" klişeleri · **aynı cümle kalıbının tekrarı** · cümle-içi düşünce ayracı **em-dash**. Dört parçalı açıklama iskeleti iz SAYILMAZ. | 29.07 → 08.09 | mekanik + `koku-olcer.ps1` |
| **B10** | **Tekdüzelik hatadan çok ele verir.** Dört yanlış şıkta aynı kelime tekrarı reddedilir. | 29.07 | mekanik |
| **B11** | **Parametre kontrolü:** hesap sorusunda hukuki parametre (kıdem tavanı, istisna haddi, oran) kaynağa bakılmadan kullanılmaz. Parametre kaynakta yoksa senaryo o parametreye **çarpmayacak** şekilde kurulur, ya da `kaynak_yetersiz`. | 27.08 | istem + insan |
| **B12** | **Uzunluk tavanı 350 karakter** (Cem kararı; ölçülen FMuh medyanı 317). ⚠️ Sınav uzuyor — SGS medyanı 2024/2'de 153 → 2026/2'de 215. **Tavan sabit rakam olarak bırakılamaz, her dönem yeniden ölçülür.** | 02.09 | mekanik |
| **B13** | **Tip kotası** gerçek dağılımdan gelir. FMuh: kayıt %41 / hesaplama %26 / teori %18. | 02.09 | parti |
| **B14** | **Ders dili çok farklı.** Negatif soru ("hangisi yanlıştır") Meslek Hukuku %45, Denetim %44, Ticaret %41 — FMuh'ta %7. Öncüllü (I/II/III) Ekonomi %40, FMuh %3. Ders kalıbı okunmadan parti basılmaz. | 02.09 | parti |
| **B15** | **Zorluk derse göre kalibre edilir.** Ölçülen (0–100): Maliyet 58,4 ≫ FMuh 31,9 > Mali Tablolar 30,6 > İş/SGK 24,6 > Ticaret 22 ≈ Meslek H. 22 > Denetim 19,7 > Ekonomi 19,2 > **Vergi 18,4** > Türkçe 17,4 > Maliye 15,4 > Matematik 15 > Atatürk 9,7. Her derse eşit kolay/zor/cokzor basmak gerçek sınava benzemez. | 02.09 | parti |
| **B16** | **Zorluk adları depo standardıdır, uydurulmaz:** `kolay` · `zor` · `cokzor`. SQL kısıtı da bu üçünü kabul eder. | 10.09 | mekanik |
| **B17** | **"Sınav" = her zaman ÜÇÜ:** SGS + yeterlilik + KGK. Üçünü kapsamayan ölçümle iddia kurulmaz. | değişmez | insan |
| **B18** | **Konu adından kanuna kelime arayarak gidilmez.** Konu adı öğretim başlığıdır, kanunun cümlesi değil (*"hukuka aykırılığı kaldıran haller"* ↔ *"hukuka uygunluk sebepleri"*: sıfır örtüşme). Üç kez denendi, üçü de yanlış cevap verdi. Konu **okunur**, hangi kanunun düzenlediğine **karar verilir**. | 10.08 | insan |
| **B19** | **Cevap kalıbı KİLİTLİ** — tek şartname `STANDART-CEVAP-KALIBI.md` (Kaydır-Çöz). Açıklama dört parçalıdır ve yanlış şık açıklaması ≤250 karakter / 2 cümle. | 05.09 | mekanik |
| **B20** | **Ölçmediğine "var/yok" denmez.** Ölçülmemiş = "ölçülmedi". | değişmez | insan |
| **B21** | **Aynı soru iki kez üretilmez** · **boşa para harcanmaz** · **kaliteden ödün verilmez** · **önce ölç, yut, sonra bas.** Kapı kaldırılmaz. | 09.09 | hepsi |
| **B22** | **Madde tavanı:** bir parçadan en çok 8 soru. Aynı maddeden sınırsız soru çıkarsa havuz tekrara düşer. | 10.09 | mekanik |
| **B23** | **AÇIKLAMA KUSUR LİSTESİ — her sınavda (SGS · Yeterlilik/SPK · KGK)** (Cem 02.10: *"hataların hepsini kural olarak yazalım, bir daha soru basınca aynı şeyle karşılaşmayalım"*). Kaynak: açıklama hakeminin yayındaki 1.000 soruda bulduğu 991 kusur (SGS %48, Yeterlilik %59 kusurlu; anahtar kelimeyle kaba sınıflama, elle doğrulanmadı): **kavram kaynakla çelişiyor 437** · **hesap kodu/THP adı 183** · **madde/fıkra/paragraf atfı 172** · adım atfı 65 · şık açıklaması başka şıkkın yolu 52 · işlem tutmuyor 32 · teşhis belirsiz 29 · "soruda verilen" ama kökte yok 15 · ✓/✗ ters 6. Dokuz madde üretim istemine yazıldı (`motor/kalip-parti-uret.ps1` madde 7b) ve onarım brifinin kontrol listesidir. | 02.10 | istem + açıklama hakemi (yeni soru, SGS + Yeterlilik); kapı: KAPI-HK, KAPI-BP (yalnız BDS), KAPI-ADIM, KAPI-AS2, R8 (yalnız Yeterlilik). **Kapısı YOK:** kavram, kanun fıkra atfı, "soruda verilen", teşhis belirsizliği → yalnız ücretli hakem görür. **KGK:** yayın şartı `arac/kgk-yayin-sarti.ps1` → `SmmmYayinSarti` → `SmmmKaliteNeden` yoluyla açıklama hakemini ve kalite kapılarını TAŞIYOR (02.10 gerçek soruyla ölçüldü; ilk "bağlı değil" notu yanlıştı, düzeltildi). Bağın kopmasını `arac/kgk-ders-adi-sinavi.ps1` 4 vakası + `KGK_MUTASYON=aciklama-hakemi` yakalar. |
| **B24** | **AÇIKLAMA KATMANI S1–S8 — GM dahil KİM YAZARSA YAZSIN, her sınavda (SGS · Yeterlilik · KGK · SPK)** (Cem 03.10: *"bütün çıkan hataları kural yaz, bundan sonra basılacak … ne varsa aynı hatayı istemiyorum"*). 02–03.10 elle okumada sitedeki SGS + bitirme sorularında bulundu (anahtarlar %99'dan fazla doğruydu, kusur açıklama/çözüm katmanında). GM hazır-soru talimatı (TALIMAT.md) bu satırı **aynen** taşır: **S1** "(N. adımda bulduk)" N = değerin "= sonuç" olarak yazıldığı adım; ADIM 1 "Verilen" sayılır. **S2** "Yanlış yol" adımının sonucu bir ÇELDİRİCİ şıkkın değerine birebir eşit; doğru cevaba eşit olamaz, hiçbir şıkka varmayan yanlış yol yazılmaz. **S3** Bütün metin ç ğ ı İ ö ş ü ile; "ayni / ogrenci / dusunuyorsun" yazımı soruyu döndürür. **S4** İstem cümlesi / iç etiket yazılmaz ("… sorusu tekrar edilmez", "Seçilmemiş, bu doğru şıktır", "Bu soru p.28 SINAV TUZAĞI noktasından geliyor"). **S5** Hesap kodu + adı THP'den (100 KASA ≠ 102 BANKALAR, 590 ≠ 591, 780 ≠ 660). **S6** Madde/fıkra/bent numarası kaynak metinden okunur; kaynakta yoksa numara yazılmaz (ölçülen: İş K. m.8/4 yok · 3568 m.45 fıkraları · 5510 m.28/3 yerine /5 · 55 gün 5018'de değil Anayasa m.161'de). **S7** Soruda olmayan tarih/rakam/olay uydurulmaz; "(soruda verilen)" yalnız kökte harfiyen geçen değere. **S8** Kök tek anlamlı; tartışmalı örnek (iki kurala uyan dil bilgisi örneği) seçilmez. | 03.10 | istem: `motor/kalip-parti-uret.ps1` 7b (x)–(xv) + adım istemi 9 + sade 5b (yalnız 2026-10-04'ten sonra açılan etikette — istem baytı koruması). **Kapı (yalnız YENİ2 = kör/hakem2 ≥ 2026-10-04 ya da tarihsiz üretim girdisi):** S1 KAPI-ADIM (ADIM-KAYMA) · S2 KAPI-YY · S3 KAPI-TR `arac/turkce-karakter-kapisi.js` · S4 KAPI-BOS BOS-KALIP · S5 KAPI-HK (mevcut, tarihsiz). **Kapısı YOK:** S6 · S7 · S8 → açıklama hakemi + elle okuma örneklemi. |

| **B25** | **GM HAZIR SORUDA ADIM + SADE YAZARIN İŞİDİR** (Cem 05.10 "1.2.3", GM2). Ölçüldü (Yeterlilik vergi gm6+gm7): 28 hazır soru → 12 partiye → **1 yayına** (≈1,2 USD/yayına giren); partiye girenlerin en az 6'sı adım/sade katmanında düştü — hazır soruda `adimlar` yoktu, bulut modeli yazdı (ADIM-KAYMA, YY-SIKSIZ, simülasyon, açıklama hakemi), teori sorusunda adım hiç yazılmadı. Kural: GM yazarı `adimlar` (≥2, ADIM 1 "Verilen", `doldur` koordinatlı), `verilen` ve `sade` {dogru, sinav, siklar}'ı kendisi yazar; bulut dosyadan alır. Kalıcı talimat `arac/GM-HAZIR-SORU-TALIMATI.md`. | 05.10 | mekanik: `arac/hazir-soru-denetle.ps1` ADIM YOK / SADE YOK (bitirme `smmm-` etiketinde KUSUR, öteki sınavlarda uyarı) + KAPI-KALITE `--tek` (bulut FAZ GM ile aynı kapı; gm7'nin 5 düşüşünün 5'ini yakalıyor). Öz-sınav `-AdimSinavi`. |

---

## BÖLÜM C — AÇIK BORÇLAR (kapı henüz yok)

Aşağıdakiler **kural olarak yazılı ama mekanik kapısı kurulmamış**. "İstem yumuşak
bir kapıdır" kök dersi gereği, kapısı olmayan kural yarım sayılır.

| Kural | Eksik kapı |
|---|---|
| A1 telif | çıkmış arşivle n-gram benzerlik denetimi |
| A4 şık dağılımı | parti düzeyi dağılım sayacı (%30 eşiği) |
| A5 vaka formatı | "kuru terim ezberi" tespiti |
| **A5b terim köprüsü** | **RAG motoruna bağlanmadı** — köprü yalnız PowerShell hattında |
| A5 SPK hattı | SPK/SPL arşivi hiç ölçülmedi |
| B14 ders dili | negatif ve öncüllü kalıp kotası |
| B15 zorluk ağırlığı | `sinav-anatomisi-sgs.json`'dan ders ağırlığı okuma |
| B24 S6 madde/fıkra atfı | kaynak metindeki fıkra sırasıyla karşılaştırma (BDS için KAPI-BP var; kanunlar için yok) |
| B24 S7 uydurma / "(soruda verilen)" | kökte geçmeyen sayı/tarihin açıklamada "(soruda verilen)" etiketiyle geçmesi — mekanik olarak ölçülebilir, kurulmadı |
| B24 S8 kök muğlaklığı | yok (hakem2 `tek_anlam` + elle okuma) |

---

## DEĞİŞMEZ İLKE

**İstem yumuşak bir kapıdır.** Model kuralı %100 uygulamaz — ölçüldü: Kural 9
eklendikten *sonraki* turda yasakladığı türden soru çıktı. Bu yüzden her kuralın
mekanik karşılığı aranır. Kural yazmak işin yarısı, kapı diğer yarısıdır.
