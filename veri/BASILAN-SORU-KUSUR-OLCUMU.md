# BASILAN SORU KUSUR ÖLÇÜMÜ — 12.09.2026

> Cem: *"bugüne kadar bastığımız sorularda yanlışımız neydi, nasıl hata yaptık, o hataları kapatabildik mi?"*
> Ölçüm tabanı: `veri/sinav/kaydir-secim/sgs-650-secim.json` — **yayına seçilmiş 1.805 soru**
> (3'ünün parti kaydı bulunamadı → ölçülen **1.802**). Kaynak: parti önbelleği `veri/fabrika/kalip-parti-*.json`.
> Bu dosya ELLE yazıldı (ölçüm raporu). Bedel 0.

## 1 · KAPANMIŞ KUSURLAR — ölçüldü, hepsi SIFIR

Bunların hepsi geçmişte gerçekten yaşandı; bugün basılı 1.802 soruda **tek örneği kalmadı**.

| Kusur | Bugün | Geçmişte ne olmuştu |
|---|---:|---|
| hakem `karar` ≠ EVET | **0** | — |
| hakem `ders_uyum` = DERS-DIŞI | **0** | — |
| hakem `konu_uyum` = KONU-DIŞI | **0** | 11.09: 648 basılan soruda **12** KONU-DIŞI yayına gitti. Seçim yolu hakemin yalnız `karar` alanını okuyordu; diğer üç hükmü (ders/konu/tek anlam) görmüyordu. Üretici ve otomatik aday yolu zaten eliyordu — eksik olan **yalnız seçim yoluydu**. Üç yol artık aynı şartı uyguluyor. |
| hakem `tek_anlam` = ÇİFT-ANLAM | **0** | — |
| kör çözüm yok ya da yanlış | **0** | — |
| hakem2 ≠ EVET | **0** | — |
| `sade` nesnesi yok | **0** | 1.835 sorunun **1.811'inde** `sade` yoktu: FAZ S argüman listesine hiç eklenmemişti, 198 parti o faz çalışmadan üretti. Kaydır-Çöz panelinin 2. ve 5. parçası boştu. Tam panel taşıyan soru 12/1835'ti. |
| `sade.doğru` / `sade.sınav` / `sade.şıklar` yok | **0** | aynı arıza |
| açıklama yok | **0** | — |
| açıklamada "Doğrusu:" yok | **0** | 27.415 soruda eksikti (eski havuz) |

## 2 · KAPANMAMIŞ — EN CİDDİ KUSUR: sayısal şıklarda harf ipucu

Doğru cevap harfi dağılımı, 5 şıklı 1.799 soru (beklenti her harf %20):

| harf | adet | pay |
|---|---:|---:|
| A | 398 | %22,1 |
| B | 393 | %21,8 |
| C | 457 | %25,4 |
| D | 326 | %18,1 |
| E | 225 | **%12,5** |

χ² = **87,1** (sd 4) · kritik değer p=0,001 → 18,47 ⇒ **dağılım tesadüfi değil.**

Sebebi bulundu — soruları **dengeleyicinin dokunduğu / dokunmadığı** diye ayırınca:

| küme | n | χ² | A | B | C | D | E |
|---|---:|---:|---:|---:|---:|---:|---:|
| cümleli şık (dengeleyici **dokunuyor**) | 1.248 | 44,1 | %27,0 | %18,3 | %20,7 | %16,5 | %17,5 |
| sayısal şık (dengeleyici **dokunmuyor**) | 554 | **215,4** | %11,4 | %29,8 | **%35,9** | %21,7 | **%1,3** |

**Mekanizma (ölçüldü):** 554 sayısal şıklı sorunun **537'sinde şıklar artan sıralı** (azalan 0, karışık 17).
Sıralı olanlarda doğru cevabın büyüklük sırası:

| sıra | pay |
|---|---:|
| 1. en küçük | %11,7 |
| 2. | %30,0 |
| 3. | %35,8 |
| 4. | %21,2 |
| 5. en büyük | **%1,3** |

Yani: çeldiriciler doğru değerin altına ve üstüne serpildiği için doğru değer **doğal olarak ortada** kalıyor;
şıklar artan sıralandığı için bu *büyüklük kümelenmesi* doğrudan **harf ipucuna** dönüşüyor.

**Öğrenci ne kazanır:** sayısal soruda "E'yi hiç işaretleme" kuralı %98,7 doğru. "B ya da C" demek %65,7 isabet.

## 3 · NİYE HİÇBİR KAPI GÖRMEDİ — ölçütün gediği

Kapı var: `motor/kalip-parti-uret.ps1` **ŞIK DENGESİ** (satır ~2899-2918).
Ölçütü: *"hiçbir harf parti içinde %40'ı geçmesin"* (`$enCok.Value -le floor(0,40*$cumleli.Count)`).

Bu ölçüt üç şeyi kaçırıyor:

1. **Bir harfin AZ kullanılmasını hiç görmez.** E %1,3 olabilir, kapı sessizdir — çünkü kapı yalnız tavana bakıyor.
2. **Sayısal şıklı sorular kümeye hiç girmiyor.** `$cumleli` listesi `SayiSikli` olanları dışlıyor (satır 2900). Dengeleyici 554 sorunun hiçbirine dokunmadı.
3. **Ölçüm parti içi.** Parti başına %40 altı kalmak, banka genelinde %25/%12 sapmasını engellemiyor.

> Bu, "bu ölçüt neyi kaçırır?" sınavının soru tarafındaki ilk bulgusu.

## 4 · KÜÇÜK AÇIKLAR

| Bulgu | Adet | Pay | Not |
|---|---:|---:|---|
| `sade.kavramlar` yok | 66 | %3,7 | panelin "anahtar kavramlar" parçası boş |
| `sade.kavramlar` tek kavram | 194 | %10,8 | tek kavramlı panel zayıf |
| yer tutucu unvan (ABC / XYZ) | 4 | %0,2 | `smmm-denetim-30/kp-21`, `sgs-fmuh-ek15/kp-01`, `sgs-fmuh-ek15/kp-10`, `sgs-maliyet-15/kp-05` |
| 5 şık değil (6 şık) | 3 | %0,2 | `sgs-t1-ticaret-cokzor/kp-43`, `sgs-t2-ticaret-cokzor/kp-25`, `sgs-t2-ticaret-zor/kp-16` |
| parti kaydı bulunamadı | 3 | %0,2 | seçimde var, önbellekte yok |

## 5 · KUSUR OLMADIĞI ÖLÇÜLEN — kurt masalı okumamak için

**"En uzun şık doğru" = 327/1.802 = %18,1.** 5 şıkta rastgele beklenti %20'dir; yani **sapma yok**, hatta
beklentinin biraz altında. Bu bir kusur değil ve öyle sunulmamalı.

## 6 · HEDEF DAĞILIM — ÖLÇÜLDÜ (12.09, Cem "2 yap")

Doğru ölçüt "bizim dağılım düzgün mü" değil, **"gerçek sınava benziyor mu"**dur.

### 6.1 · SGS'nin gerçek cevap anahtarı ELDE EDİLEMİYOR — dört yol denendi

| Yol | Sonuç |
|---|---|
| Arşivdeki 575 kitapçık metni, **harf duyarlı** `CEVAP ANAHTAR` araması | **0 dosya** |
| Kitapçık PDF'lerinin sonu (anahtar son sayfada olabilir) | tek başına "numara harf" satırı **0**; kuyrukta yalnız sınav yönergesi |
| TESMER `soru_cevaplar` dizininde 8 aday dosya adı | **8'i de yok**; kontrol olarak gerçek kitapçık VAR döndü (2.318.491 bayt) |
| tesmer.org.tr duyuru arşivi (WP REST), "cevap anahtarı" | 3 sonuç, **üçü de sınav kuralları sayfası** — anahtar yayını yok |

⚠ **TUZAK (kayda geçiyor):** tesmer sunucusu **olmayan dosyaya da HTTP 200 dönüyor**, ama
`Content-Type: text/html` ile. Yalnız kodu okuyan bir ölçüm "8 anahtar dosyası VAR" derdi.
`motor/sinav-arsiv-kesif.ps1`'in `PdfMi` fonksiyonu bu yüzden içerik tipi + 20 KB alt sınırı birlikte
bakıyor; aynı koruma burada da kullanıldı.

⚠ İlk turda "535 dosyada anahtar izi var" ölçtüm, **yanlıştı**: `-match` harf ayırmıyor ve
"tatminkâr **cevaplar** almamış" gibi SORU METİNLERİ eşleşiyordu. Harf duyarlı ölçüm 0 dedi.

### 6.2 · Elimizdeki tek GERÇEK anahtar: KGK — ve dengeli

`veri/kgk-arsiv` içinde gerçek KGK cevap anahtarları var (2 tekil kitapçık, **240 cevap**):

| harf | adet | pay |
|---|---:|---:|
| A | 100 | %20,8 |
| B | 90 | %18,8 |
| C | 88 | %18,3 |
| D | 90 | %18,8 |
| E | 112 | %23,3 |

χ² = **4,3** (sd 4) ⇒ **gerçek sınav DENGELİ** (kritik değer p=0,05 → 9,49; sapma bile yok).

### 6.3 · HÜKÜM

| | χ² |
|---|---:|
| gerçek KGK sınavı | **4,3** — dengeli |
| bizim banka (5 şıklı 1.799 soru) | **87,1** |
| bizim sayısal alt küme (554 soru) | **215,4** · E %1,3 |

KGK, üç sınavımızdan biri ve resmî bir kurulun kitapçığı. SGS'nin kendi anahtarı elde edilemedi,
ama gerçek bir resmî sınavın ölçülen dağılımı **düzgün**. Dolayısıyla hedef **düzgün dağılım**dır
ve bizim sapmamız sadakat değil **kusur**.

> SGS anahtarı ileride ele geçerse bu bölüm tazelenir; hedef o zaman SGS'nin kendi dağılımı olur.
