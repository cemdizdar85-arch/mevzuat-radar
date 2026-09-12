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

## 6 · ÖLÇÜLEMEYEN — dürüst boşluk

Doğru ölçüt "bizim dağılım düzgün mü" değil, **"gerçek sınavın dağılımına benziyor mu"**dur.
Gerçek SGS kitapçıklarının **cevap anahtarı yerel olarak yapılandırılmış hâlde YOK**: arşiv (253 belge /
20.851 soru) `dokumanlar` tablosunda ham metin olarak duruyor, şık + doğru cevap alanı ayrıştırılmamış.
Dolayısıyla "gerçek sınavda da doğru cevap ortada mı kümeleniyor?" sorusu **ölçülmedi** — tahmin yazılmadı.
Bu kıyas yapılana kadar hedef, hiç değilse uçları (E %1,3) düzeltmek olabilir.