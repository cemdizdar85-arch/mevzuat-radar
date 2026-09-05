# TETİKTE — CEVAP KALIBI ŞARTNAMESİ (kilitli)

**Karar tarihi:** 05.09.2026 · **Karar veren:** Cem Dizdar ("1 yap" = kilitle) · **Uygulayan:** GM
**Kalıp adı:** Kaydır-Çöz · **Sürüm:** v28 (03.09–05.09 arası 28 turda Cem'le birlikte kuruldu)

Bu belge **son karardır.** Soru üreten, açıklama yazan ve ekran çizen her betik buna uyar.
Değişmesi gerekirse bu dosya değişir ve sebebi buraya tarihle yazılır.
29.07 tarihli `STANDART-ACIKLAMA.md`'nin 5. (değişmeyenler) ve 6. (rakam kapısı) bölümleri
aynen geçerlidir; 1–4. bölümleri bu belgede genişletilmiş hâliyle yaşar.

**Hedef:** Konuyu hiç bilmeyen biri soruyu çözdükten sonra konuyu anlamış olsun.
Kitap ezberleterek değil soru çözdürerek. Emsal UWorld düzeni; hedef ondan iyisi.
**Pazarlama cümlesi (29.08 kilidi):** "Yanlışını böyle öğrenirsin."

---

## 1. Ekran düzeni

| Öğe | Karar |
|---|---|
| Masaüstü | İKİ KOLON: sol soru+şıklar sabit, sağ cevap paneli (Cem 04.09: "şık tıklayınca çok aşağıda") |
| Telefon | Alt panel, tek ekran (üç satır + çipler, %51 yükseklik) |
| Akış | Tam ekran kart, yukarı kaydır = sonraki; klavye ↓/↑; üstte nokta sırası |
| Ana düğme | TEK: yanlışta **🎬 Nöbetçi anlatsın**, doğruda **⚖️ Sen çöz** (+ Sonraki) |
| "⋯ Daha fazla" | 📘 Hesapları tanı · Kural · 🧠 Sen anlat · 📒 T-hesabı · 📈 Sınavda · Diğer şıklar · 📜 Kaynağı göster · 🚩 Hata bildir |
| Yol haritası | TEK SATIR numaralı yuvarlaklar (geçilen yeşil, buradasın dolu, hedef 🏁), tıklanır, kartın altına yaslı |
| Üst çipler | 🎯 Hazırlık % · 📥 Yanlış kutusu |
| Adlandırma | "Öğretmen/hoca" **YASAK** → **Nöbetçi**. "Sürükle" kelimesi arayüzde geçmez. |

## 2. Cevap panelinin parçaları (bu sırayla)

1. **Tek satır tuzak** — yanlış şıkta tuzağın ADI + tek cümle ("Bu şık A ile B'yi karıştırıyor").
   Tuzak adı üreticinin `aciklama.<şık>.tuzak` alanından; "[…] Tuzağı" köşeli parantezi atılır.
2. **Sade Doğrusu** — herkesin anlayacağı dil (`sade.dogru`), yanında "sınav dili" düğmesi (`sade.sinav`).
   Sade kapısı: kısaltma yok, madde no yok, "sayılı" yok, ≤60 kelime.
3. **Hesaplama + kayıt TEK TABLO** (`cozum_tablo` ya da yevmiye `sema`). Soruda verilmeyen hücre "?" ile
   gizli, adımında açılır. Hücrelerde çıplak hesap kodu yok: "680 Çalışmayan Kısım Gider ve Zararları hesabı".
4. **Kural / Bu olayda / Hap** — hap, kural veya doğrusu ile ≥%60 örtüşüyorsa gizlenir (ezber cümlesi değilse gereksiz).
5. **📘 Kavramlar** (`sade.kavramlar`) — tanım yalnız KAYNAK METNİNDEN; kaynakta yoksa kavram düşer, uydurulmaz.
6. **📈 Sınavda** — dönem listesi `veri/sgs-analiz.json` konuSayim'dan; o kitapçıklardan soru gövdesi alıntısı.
   Köprü kaydında yıl listesi yok, sayım var; gevşek eşleşme 50 dönem gösterdi → gövde + "?" ile eşleşme.
7. **📜 Kaynağı göster** — ambardaki gerçek madde metni, kaynak adı UZUN adla ("Vergi Usul Kanunu 275. madde",
   "Tekdüzen Hesap Planı 381"); hakemin dayandığı cümle sarı. **Maliyet Muhasebesi'nde GİZLİ** (05.09): kaynak VUK m.275 +
   teori notu çıkıyor, tekniğin kaynağı değil, güven zedeler; MSUGT Sıra No 2 deseni bağlanınca açılır. Metin yoksa da gizli.
   Teori notu metni Türkçe onarımdan geçer.
6b. **📈 Sınavda**: "Alıntılar gerçek kitapçık metninden" cümlesi yalnız alıntı VARSA yazılır; boş vaat yok.
6c. **🎯 Hazırlık skoru**: 5 cevaptan önce yüzde gösterilmez ("—"); ilk yanlıştan sonra "%4" caydırıcıdır.
8. **🚩 Hata bildir** — prototipte localStorage `kc_hata`; üründe kasaya itiraz kaydı.

## 3. Nöbetçi anlatımı (adım adım)

- **ADIM 1 = sorunun kendi metni**, verilen rakamlar mavi işaretli; anlatımda yalnız "Dikkat/anahtar" cümlesi.
  Hesaplı soruda formül "Verilen: …" listesi; teori sorusunda "Soruda ne var: olay; istenen; ayırt edici kelime".
- **Formül yazımı (kural 7):** tek zincir `Ad = genel = sayılı = sonuç`; işleçlerin iki yanı boşluk; `; Etiket:`
  ile çoklu hesap; parantez kimlik sayının hemen ardında ("2.000 (soruda verilen)"); formülde cümle yok.
  Ekranda **matematik gibi**: toplama/çıkarma alt alta sütun, bölme kesir, çarpma satır içi, sonuç kalın altın.
- **Renk dili:** formüldeki rakam tabloda aranır → KAYNAK hücre MAVİ, bu adımda BULUNAN ALTIN; "N. adımda" atfı
  o adımın hücrelerini de mavi yapar; altta lejant. Eşleme yalnız AÇIK hücrelerde (tesadüf 40=40 yanmasın).
- **Hareket:** sonuç formülden tablodaki hücreye UÇAR (600 ms); adımda birden çok formül varsa SIRAYLA belirir
  (900 ms), hücre o ana dek boş; İleri basılırsa bekleyen uçuşlar iptal. "Soruda verilen: 0,20 · 0,48" satırı
  formülde etiketli ama tabloda olmayan değerleri gösterir.
- **Öğretici zorunluluklar (kural 6):** her hesap için "X nedir?", neden bu taraf; kalıp tekrarı yasak;
  **son adım "En sık hata" ZORUNLU** ("Yanlış yol: … (HATALI) → doğrusu …").
- **Denklem soruları (kural 8, karşılıklı dağıtım vb.):** ilişkiyi oku → sözlü denklem → yerine koyma İKİ alt
  adım → **SAĞLAMA adımı zorunlu**; cebir dili (x, y) yasak, adlar kullanılır ("Yemekhane'nin %98'i").
- **Oran yazımı:** her yerde YÜZDE (%20); "0,20" yazılmaz. Ölçüm 05.09: 33 SGS kitapçığında "%20" 169 geçiş /
  "0,20" 28 geçiş. Builder `oranYuzde` çarpım/bölümdeki 0,xx'i çevirir; katsayılara (beta, kaldıraç) ve TL/kg
  tutarlara dokunmaz.
- Adım yoksa (eski cache): builder adımları kural + kayıttan sentezler (model çağrısı yok).
- **Kişisel son adım (05.09 ürün incelemesi):** öğrenci yanlış şık seçtiyse Nöbetçi'nin SON adımı o şıkkın tuzağıdır
  ("Senin seçimin A: 40 TL/kg (HATALI) → doğrusu D: 120 TL/kg" + tuzak adı ve nedeni). Üreticinin "en sık hata" adımı
  zaten o şıkkı anlatıyorsa eklenmez. Sebep: öğrenci A'yı seçmişken son adım 80'i anlatıyordu, kendi hatasını bulamıyordu.

## 4. "Sen çöz" oyunu

| Soru tipi | Oyun |
|---|---|
| Kayıt (yevmiye) | İkiz soruyla (`ikiz` + `ikiz_sema`), yoksa AYNI OLAY ×2 tutarla; tutarı sola = BORÇ, sağa = ALACAK. Yanlış tarafta "Neden borç/alacak?" = hesap sınıfı kuralı + Tekdüzen işleyişi. |
| Tablolu (hesaplama) | İKİZ TABLO DOLDURMA (`ikiz.tablo/verilen/bosluk`): boşluk = ikiz metninde geçmeyen rakam; kalem adındaki formül ipucu SİLİNİR (hesap adı parantezi kalır); her boş hücrede "?" ipucu düğmesi; "Kontrol et" hücre hücre (±0,5); "Doğruları göster" hücreleri 350 ms arayla sırayla yazar. |
| Teori | Oyun yok → 🧠 Sen anlat (Feynman; ücretsiz sürüm anahtar kavram isabeti, modelli sürüm bedelli). |

Verilen hücre = ikiz metninde geçen rakam **VE** üreticinin `ikiz.verilen` listesinde olan hücre (kesişim, 05.09).
Yalnız rakam eşleşmesi sızdırıyordu: hesaplanan hücre metindeki başka bir rakamla çakışınca dolu geliyordu.
İkiz adları harf değil (A/B/C yasak, kural 4c ikiz istemine de girdi). Kontrol et mesajı "d doğru · y yanlış · b boş".
Seri kilidi: tamamlanınca girişler kilit, seri bir kez; "Doğruları göster" ve ipucu sonrası seri sayılmaz.
Kırmızı kalan hücrede 🎬 "Nöbetçi'ye sor" → o hücreyi dolduran adım açılır (`doldur` eşleşmesi, yoksa satır sırası).

## 5. Yanlış Kutusu + Hazırlık Skoru

- Yanlış → kutuya (2 gün sonra döner); 2. doğru → 7 gün; 3. doğru → çıkar.
- Ustalık: 1 / 0,6 / 0,3 / 0. Ağırlık = konunun çıkmış dönem sayısı (sınav DNA'sı). Ders bazında bar.
- Sen çöz: ipuçsuz tam +0,25, ipuçlu +0,12, doğruları göster 0; Yanlış Kutusu'na girmez.
- Prototipte localStorage (`kc_kayit/kc_kutu/kc_ileri/kc_oyun`); **üründe kasa + kullanıcı katmanı** (açık iş).

## 6. Dil ve terim (üreticide kapı, builder'da onarım)

- **Sınav dili sözlüğü** (03.09, 1.042 belge): kanunlar UZUN AD + "sayılı"; KDV/TMS/TFRS/BDS/TL kısaltması
  serbest; **THP kısaltması YASAK** (çıkmış metinlerde 0 kez), hesaplar KOD + AD ("100 KASA").
- **Terim çiftleri ölçümden** (`veri/terim-ciftleri.json`, robot günlük 08:10): "genel yönetim gideri" (230) /
  "genel idare" (0), "genel üretim gideri" / "genel imal(at)", olumlu/olumsuz (lehte/aleyhte değil). Kural:
  bire bir VE sınav ≥5× kanun → kapı; tırnak içi kanun alıntısına dokunulmaz.
- **İstem, üründe görmek istediğin yazımla yazılır** (ASCII istem → ASCII çıktı; 02.09'da 26/30 soru bozuktu).
- Builder Türkçe onarımı: cache'lerdeki doğru metinlerden sözlük + sabit yedek; tr-TR büyük harf.
- Cümle ≤20 kelime ortalama, tek cümle ≤30; etken çatı (29.07 kuralı sürüyor).

## 7. Soru tarafı (kilitli üretici kuralları)

- **Şık kalıbı** dersin çıkmış ölçümünden (`veri/celdirici-kalibi-sgs.json`, KGK modül eşlemesi `$KGK_TAKMA`):
  sayı şıkları hepsi farklı, artan sıra, birim yalnız doğruda değil; cümle şıkları doğru en uzun kayırılmaz
  (anahtarlı ölçüm: doğru en uzun payı %0–24, rastgele düzeyinde).
- **KAPI-Ş şık dengesi:** sapma sorularında 2 tutar × 2 yön + 1; yön kelimesi olumlu/olumsuz.
- **KAPI-E tek anlam:** kök tek anlamlı, tablo SAYISAL, harf değil AD (denklem soruları 4c).
- **KAPI-D konu uyumu** + hakem `konu_uyum`; **kara listedeki dayanak** teyitli görünse de dayanaksız.
- Uzunluk: 350 karakter tavan (sınav anatomisi 02.09); Maliyet için ilk tavan 20k token.
- Şıkka gerekçe yazılmaz; sızıntı 4c; tavan/parametre kaynaksız kullanılmaz (çıkmış-örnek kuralı 27.08).
- **Zor ayarı (`-Zorluk zor`, 05.09 Cem "en çok çıkan konu, zor ve katmanlı"):** ≥4 bağlı ara hesap, sınavın birleştirdiği
  katmanlar, her çeldirici atlanan katmandan türetilir, tablo her katmanı ayrı satır, adım 6-10. **Gövde sınav gibi:** ölçüldü
  (13 dönemin ortak maliyet soruları), sınav yöntemi ve politikayı işletme cümlesiyle SÖYLER ("…yan mamullerin net
  gerçekleşebilir değerini ortak maliyetten çıkararak hesaplama yapmaktadır"), çözüm sırasını anlatmaz; veri tablo cümlesiyle;
  kök "Buna göre, … kaç TL'dir?". Zorluk kaynakları sınavdan: yan ürün NGD, ek maliyet + nihai satış değeri, birim kâr, ters soru,
  "dağıtsaydı" karşılaştırması. Biçim çapası konunun GERÇEK çıkmış sorusundan (`-OrnekDosya`), sabit Finansal örneği değil.
- **Ölçülen, karar bekleyen:** sınav 2018'den beri "₺" yazıyor (13 dönemde 12), biz "TL"; sınav mamulleri "A, B, C mamulü" diye
  harfle anıyor (4c harf yasağı bizim adım anlatımı içindi).

## 8. Veri sözleşmesi (fabrika cache alanları — builder bunları okur)

`soru · siklar{A..E} · dogru · aciklama{<şık>: string | {ne_soruluyor,kural,tuzak,hesap,dogrusu}} · hap ·
sinav_taktigi · notlandirici · adimlar[{formul, anlatim, doldur[[satır,sütun]…]}] · cozum_tablo{basliklar,satirlar} ·
verilen[[satır,sütun]…] · sema / ikiz_sema {tur:'yevmiye', kayitlar[{baslik, ogeler{borc[],alacak[]}}]} ·
ikiz{ikiz_soru, hedef_cumle, tablo, verilen, bosluk} · sade{dogru, sinav, siklar, kavramlar[{ad,tanim,kaynak}]} ·
dayanak · kaynak_adlar · hakem{karar, konu_uyum, tek_anlam} · konu · donem`

Yeni alan eklenirse önce buraya yazılır, sonra üretici + builder birlikte değişir.

## 9. Araçlar

| Betik | İş | Bedel |
|---|---|---|
| `motor/kalip-parti-uret.ps1` | Soru + hakem üretimi (FAZ A) | API |
| `motor/son10-uret.ps1` | Adım (`-AdimYenile`), sade (`-Sade/-SadeYenile`, Haiku), ikiz, hakem istemleri | API |
| `motor/kaydir-coz.ps1` | **Bu kalıbın çizicisi.** Cache → HTML. `-SecimDosya <ad>.json` (`veri/sinav/kaydir-secim/`), `-SadeceId etiket/kp-NN`, `-Cikti <ad>.html` → `sql-yerel/` + `C:\TETIKTE-YEDEK\kaydir-coz-<tarih>\` | 0 |

Builder önbellekleri `veri/fabrika/kaydir-onbellek/` (gitignore): ambar 14 gün, Türkçe sözlük cache'lerden
yeniyse, sınavda damgası = kitapçık sayısı|en yeni kitapçık|analiz tarihi. Basım: ilk 46 sn, sonra 2 sn.

```powershell
powershell -NoProfile -File motor/kaydir-coz.ps1 -SecimDosya malfm-secim.json -Cikti KAYDIR-COZ-MALFM.html
```

Ölçülen üretim bedelleri (04.09): adım yazımı ≈0,06–0,08 USD/soru (Sonnet), sade ≈0,009 USD/soru (Haiku),
tam soru (soru+adım+sade+ikiz+hakem) ≈0,15 USD. Her parti önce bedeliyle sorulur.

## 10. Değişmeyenler ve kapılar (29.07'den devam)

**ASLA değişmez:** `soru`, `siklar`, `dogru`, `kaynak`. Açıklamayı zenginleştirmek için soruya dokunmak yeni sorudur.
**Rakam kapısı:** açıklamadaki her sayı kaynakta (madde metni + soru + şıklar) geçer ya da kaynak sayılarından
aritmetikle türer; geçmiyorsa yenileme çöpe, eski kalır.

## 11. Kilit DIŞINDA kalan açık işler (Cem kararı)

1. Üründe kasa + kullanıcı katmanı (Yanlış Kutusu, skor, hata bildirimi localStorage'dan kasaya).
2. `kalip-parti-uret.ps1` çizim bölümü bu düzene çevrilmedi; teslim sayfaları `kaydir-coz.ps1` ile basılıyor.
3. Maliyet muhasebesi TEKNİĞİ kaynağı (MSUGT Sıra No 2) `OZEL_DESEN`'e bağlanmadan hakem bu tipi reddediyor.
4. Cache anahtarı sıraya bağlı; konu adına bağlanmalı (köprü değişince israf).
5. Üç önbellek dosyası ürüne taşınırken repo dışı veri klasörüne alınır.
