# AMBAR YUTMA İŞ EMRİ — 30.09.2026 (SGS soru onarımında ölçüldü)

> Elle yazılmış iş emridir (robot çıktısı değil). Yazan: SGS oturumu (`sgs` kolu), Cem 30.09 "1.2.3 üçünü de yap".
> Kapanınca her satıra `KAPANDI <tarih> <commit>` yazılır; hepsi kapanınca dosya silinir.
> Bu eksikler `veri/kesik-metin-adaylari.json` ve `veri/kesik-madde-onarim-onerisi.json`'da **yok** (30.09 grep ile ölçüldü) — mevcut
> kesik metin taraması bunları görmüyor.

## ✅ 05.10 sonu: 15 (yanlış bulgu), 16, 17, 18 kapandı; 19'da m.74 yürürlüğü açık. Eski not: satır 16, 18, 19 — VAR OLAN kaydı değiştirir. Değiştirilmedi: (a) kayıt metni değişince `motor/soru-dayanak-nobetcisi.ps1` o maddeye atıf yapan soruları yayından çekebilir (02.10'da hedefli belirteçle ~58 soru) — önce etki ölçülür; (b) m.88 `kaynak_ad` değişirse soruların `kaynak_adlar` bağı kopar. 2026 tarifesi Seri 332'de (ambarda) olduğu için yazar tarifeyi tebliğden alır (`arac/GM-HAZIR-SORU-TALIMATI.md`).

## ⚠ ÖNCELİK (30.09 akşam): satır 12–13 (THP 652 mülga, 649/659 eski 1992 açıklaması) ÖNCE

Üretim bu eski ambar metninden besleniyor: kapı (KAPI-HK 652, KAPI-EK EK12/EK13) yeni soruyu durdurur ama ambar düzelmedikçe
üretim aynı hatayı basmaya devam eder (boşa para). Site Pazartesi 05.10 açılıyor. Ölçülen etki: SGS sitesinde 652 → 7 soru,
EK12 (649 + menkul/kambiyo kâr) → 3 soru; bitirme ölçümü SMMM oturumunda.

## Neden önemli

Kapılar (KAPI-HK `arac/hesap-kodu-kapisi.js`, KAPI-BP `arac/bds-atif-kapisi.js`) ve onarım ajanları doğruluğu **ambardan** okuyor.
Aşağıdaki eksikler iki yoldan zarar veriyor:
1. **Yanlış alarm:** doğru atıf "yok"/"konu uyuşmuyor" sayılıyor (kapılar şimdilik bu vakaları bilerek atlıyor — atlama geçici yamadır).
2. **Kaynaksız onarım:** THP 17 grubu ambarda olmadığı için yıllara yaygın inşaat sorularında hesap kodu resmî kaynaktan doğrulanamıyor.

## Eksikler

| # | Kaynak | Eksik | Nasıl bulundu (30.09) | Geçici yama |
|---|---|---|---|---|
| 1 | **THP 170–179** (Yıllara Yaygın İnşaat ve Onarım Maliyetleri grubu) | Ambarda `THP 17%` sorgusu **0 kayıt**. 350/358 var, 170/178/179 yok. | SMMM oturumu: `smmm-w3-maliyet-zor/kp-22` HK-YOK 170/178/179 verdi; soru MSUGT'ye atıf yapıyor | KAPI-HK: listede grubu olmayan koda hüküm verilmez (3f1ad304) |
| 2 | **BDS 500 p.11** | Ayrı kayıt değil; `BDS 500 p.10` kaydının gövdesinin içinde ("…Güvenilirliğine İlişkin 11. Bir kaynaktan…") | KAPI-BP isabet yargısı (60 bulgu) | KAPI-BP: gövdeye gömülü paragraf var sayılır (`gomulu`) |
| 3 | **BDS 250 p.5** | İlk cümlede kesiliyor; devamı "BDS 250 p.1 - Denetçinin Sorumluluğu" etiketli ayrı bir kayıtta | KAPI-BP yargısı + bp-1 onarımı (2 soru) | yok — yanlış alarm veriyor |
| 4 | **BDS 330 p.17** | (b) bendi eksik | KAPI-BP yargısı | yok |
| 5 | **BDS 580 p.11** ("İşlemlerin Tamlığı") | (b) bendi ("tüm işlemlerin kaydedildiği" beyanı) düşmüş | bp-2 onarımı (`sgs-t1-denetim-zor/kp-23`) | yok |

### Tarayıcıyla bulunanlar (30.09, `arac/kesik-paragraf-tarama.js` + 40 adayın resmî KGK Mavi Kitap metniyle yargısı)

| # | Kaynak | Eksik | Kök |
|---|---|---|---|
| 6 | **BDS 540 A39 + "p.3 - Modeller"** | A39 "…kredi zararı modeli veya" diye kopuk; devamı yanlış numarayla "p.3" kaydında | metindeki "Seviye 3" paragraf başı sanılmış |
| 7 | **TMS 1 p.122 / p.125** | p.122 "(bakınız:" diye kopuk; devamı ve 123–124 "p.125" başlığı altında | bölme hatası |
| 8 | **TFRS 8 p.25 / "p.1 - Ölçme"** | p.25 "bölüm kar veya" diye kopuk; devamı "p.1" kaydında, başına p.33'ten cümle yapışmış | bölme hatası |
| 9 | **TFRS 1 p.10** | 60 karakterlik başlık artığı (p.40'ın başlığı), yanlış numaralı çöp kayıt | bölme hatası |
| 10 | **TMS 7 p.33 / p.34** | ~~BELİRSİZ~~ **KARAR (Cem 30.09): YENİ SÜRÜM ESAS** — ambar TFRS 18 sonrası metni taşıyor (33A, 34A–34D + "Silinmiştir"); ambar DOĞRU, eski sürüme çekilmez. İş: soru bankası yeni sürüme hizalanır | KAPANDI (ambar) — soru hizalaması SGS/SMMM/KGK oturumlarında |

| 11 | **TMS 1 (158 kayıt)** | TFRS 18 p.C8 TMS 1'i yürürlükten kaldırıyor (p.C1: 1.1.2027 ve sonrası dönemler). Ambarda 158 TMS 1 kaydı künyesiz ve "yürürlükten kalkıyor" işaretsiz duruyor; öbür standartlar TFRS 18'e göre güncel. **Cem 30.09: yeni sürüm esas** → üretim/paket bu kayıtları kaynak almamalı (işaret ya da ayrı sürüm etiketi). Soru tarafında KAPI-EK EK9 TMS 1 atfını durduruyor (2fb8a761). | yutma/etiketleme altyapı/KGK kolunda |

| 12 | **THP 652 (id 8f00770e…)** | MÜLGA: MSUGT Sıra No:2 (RG 16.12.1993/21790) C/12 ile 657'ye taşındı; ambarda 1992 metniyle canlı → aynı hesap iki kodla. KAPI-HK artık 652'yi mülga sayıyor (sitede 7 soru). | kayıt silinmeli/işaretlenmeli |
| 13 | **THP 649 (a17241ea…) · THP 659 (6508bb92…)** | 1992 eski ad ve açıklama: 649'da "menkul kıymet satış kârları … izlenir", 659'da kambiyo/menkul kıymet zararları. Sıra No:2 C/21 ve C/23 ile yeniden yazıldı (bunlar 645/646, 655/656'da). Üretim eski metinden besleniyor olabilir (SMMM okuyucuları bitirmede 649'a menkul satış kârı yazan sorular buldu). | resmî metinle yeniden yutulmalı |
| 14 | **THP 645–648, 655–658** | içerik doğru ama metin "MSUGT Sira No:1" diye başlıyor; bu kodlar Sıra No:2 ve 12 ile açıldı | künye düzeltmesi |
| 15 | ~~**GVGT Seri No: 332**~~ **YANLIŞ BULGU — KAPANDI 05.10:** ambarda 11 kayıt var, adı BOŞLUKSUZ yazılmış `GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO:332) m.N`; ilk ölçüm `'SERİ NO: 332'` (boşluklu) aradı. Aşağıdaki ilk metin geçersiz: | Ambarda **0 kayıt** (`kaynak_ad ilike '%SERİ NO: 332%'`, 05.10). En güncel tarife tebliği Seri 329 (2025 gelirleri). Yerel dosya var: `veri/mevzuat-hazir/gvkgt332.txt`. Etki: 2026 ücret/geçici vergi hesabı soruları 2025 tarifesiyle üretilebilir. | sinav kolu 05.10 (Cem "1.2.3", GM3) | resmî metinle yutulmalı (madde başına kayıt) |
| 17 | **GVK m.22** — **KAPANDI 05.10** (`arac/ambar-gvk22-ekle-20261005.js`: 2 kayıt eklendi, dipnotsuz, geri okundu birebir; kaynak veri/mevzuat-hazir/gvk.txt 05.08 indirme) | Ambarda kanun maddesi kaydı YOKTU; kural yalnız bir TEORİ notunda (gm6 MSİ yazarı, 05.10). Kâr payı soruları kaynaksız kalıyor. | sinav kolu 05.10 | resmî metinle yutulmalı |
| 18 | **KAPANDI 05.10 — DEĞİŞTİRİLMEDİ:** parantezli tutar mevzuat.gov.tr'nin resmî düzeni (güncel yıl); metne yıl eklemek resmî metni değiştirmek olur. Çözüm yazarda: tutar o yılın tebliğinden (`arac/GM-HAZIR-SORU-TALIMATI.md`). Etki ölçümü: sitede m.21'i kaynak gösteren 10, m.86 3 soru. **GVK m.21 · m.86/1-d · VUK m.353** (yıla bağlı hadler) | Kanun kaydı parantez içinde TEK yılın tutarını taşıyor, yılı yazmıyor: m.21 58.000 (2026; 2025 = 47.000 Seri 329) · m.86/1-d 22.000 (Seri 329'da 2025 = 18.000) · VUK m.353/2 ilk tespit 14.000 (VUK GT 588 eki 2026 = 17.000). Yazar yanlış yılın haddini okuyabilir (gm6 yazarları 05.10). | sinav kolu 05.10 | parantezli tutara yıl etiketi ya da tebliğe köprü |
| 19 | **YARIM 05.10:** m.88 başlığı DEĞİŞTİRİLMEDİ (kaynak_ad değişirse sitedeki 1 sorunun bağı kopar; yalnız ad kusuru). m.74 7566 yürürlüğü ÖLÇÜLMEDİ — açık. **GVK m.88 kaydı başlığı · m.74 (7566 s.K. değişikliği)** | m.88 kaydının adı "EĞİŞİKLİKLER CETVELİ" parçasıyla bozuk. m.74'te 7566 (4/12/2025) "konutlar hariç" dipnotu var, yürürlük tarihi ambarda ölçülmedi. | sinav kolu 05.10 | başlık onarımı + yürürlük künyesi |
| 20 | **GVK geç. m.67/19 uzatma dipnotu yanlış kayıtta** | 10680 sayılı CBK (RG 11/12/2025-33104) ile geç. m.67 süresinin 31/12/2030'a uzatıldığı 198 numaralı dipnot, `GVK (193 s.K.) gec. m.68 [2/2]` kaydında duruyor (197–198 işaretleri m.67 [14/14]'te /19'un sonunda; m.68'in kendi dipnotu 199). Etki: m.67'yi okuyan yazar/hakem/ikinci göz "31.12.2025'te bitti, uzatma yok" sanıyor (05.10'da iki ikinci göz okuyucusu ve bu oturum böyle sandı). | sinav kolu 05.10 (onarım ajanı buldu) | dipnot m.67 [14/14]'e taşınmalı; parçalayıcının dipnot–madde eşlemesi ölçülmeli |
| 21 | **GVK m.75 [1/6] başka maddenin dipnotu karışmış** ("%25'ini ibaresi %15'ini") · **VUK m.352 kesik** ("…hükümlerine (" ile bitiyor) · **VUK m.227 başlığı "Ü KISIM"** | gm8 yazar/okuyucu bulguları 05.10 | sinav kolu 05.10 | yeniden yutma / dipnot süzgeci |
| 16 | **KAPANDI 05.10** (`arac/ambar-gvk103-duzelt-20261005.js`: aynı resmî metin satır düzenine; yeni sayı 0, 2026 tutarları 11/11 Seri 332 ile, 5 oran yerinde; m.104 taşma öneki silindi, kaynak_ad'lar DEĞİŞMEDİ; yedek `_yerel-veri-kasasi/teori-yedek/gvk103-104-20261005.json`; etki: Yeterlilik sitesinde bu maddeyi kaynak gösteren soru 0) **GVK m.103 (kayıt `GVK (193 s.K.) m.103`)** | 2019 metni + güncel tutarlar parantez içinde iç içe ("18.000 TL'ye (190.000 TL) kadar % 15 …"), son satır m.104 kaydının başlığına taşmış: `m.104 - TL) fazlası % % % % 40 oranında vergilendirilir`. Dilim oranları m.104'te "% % % %" diye boş. | sinav kolu 05.10 | m.103/m.104 sınırı düzeltilip yeniden yutulmalı; parantezli güncel tutar düzeni tek tarifeye ayrılmalı |

Kök ortak: aktarım metin içindeki bir sayıyı ("Seviye 3", dipnot numarası) paragraf başı sanıp kaydı bölüyor. Tarayıcının bu kökte isabetli
türleri K3 (çift başlık) + K4 (gömülü) — örneklemde 6/6; K1 (noktasız son) daraltma sonrası 1 gerçek / 3 yanlış; K5 (numara atlaması) 0/10.
Tam aday listesi: `veri/sinav/kesik-paragraf-adaylari.json` (301 aday; ADAY, kusur değil).

Ek not (ölçülmedi, doğrulanmalı): onarım ajanları TTK m.189 ve m.473'ü ambarda bu adla bulamadı; TTK m.189 metni kesik geldi.

## Yapılacak

1. Resmî kaynaktan (KGK BDS metinleri; MSUGT / THP hesap açıklamaları) ilgili parçaları **yeniden yut**; paragraf başına ayrı kayıt, etiket = gerçek paragraf numarası.
2. Yutma sonrası: `node arac/bds-atif-kapisi.js --tazele` ve `node arac/hesap-kodu-kapisi.js --tazele` (listeler tazelenir), ardından iki kapının
   `--banka sgs` ölçümü — yanlış alarm sayısı düşmeli. Düşmüyorsa yutma eksik.
3. KAPI-HK "grubu olmayan kod" ve KAPI-BP "gömülü paragraf" atlamaları ambar düzelince gözden geçirilir (gerekirse kaldırılır, öz-sınav vakasıyla).
4. **Kesik metin taraması kör:** bu beşini görmeyen `kesik-metin-adaylari` üreticisine "paragraf ilk cümlede bitiyor / numaralı bent eksik /
   sonraki paragraf numarası gövdede" desenleri eklenmeli (kapı kuralı: öz-sınav + mutasyon).

Kol: kaynak yutma KGK/altyapı işidir; SGS oturumu yutma yapmaz.
