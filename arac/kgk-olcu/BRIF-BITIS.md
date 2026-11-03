# KGK BİTİŞ DALGASI (t9) — yazar brifi · 29.10.2026 (Cem: "gm önerilerini yap ve bağımsız denetimi bitirelim artık hadi")

`<IS>` = `C:\TETIKTE-CALISMA\kgk-is` · depo kökü `C:\TETIKTE-CALISMA\kgk-cizim` (veri\fabrika ana klasörle aynı).
**Önce `<IS>\BRIF-T8.md`'yi baştan sona oku — bağlayıcıdır** (kaynak kuralları, K14/K15/K16, t5–t8 okuma dersleri, modül desenleri,
madde 4 ÇİZİM KAPISI = talimat K17 CZ1–CZ6). O dosyada `<T8>` geçen her yer `<IS>` demektir: ambar `node "<IS>\ambar-oku.js" "<desen>"`,
konu `<IS>\konu\<grup>.json`, harf planı `<IS>\konu\harf-<grup>.txt`. Bu brif onun üstüne ekler; çelişkide BU brif kazanır.

## ⛔⭐ 1. SINAV PROFİLİ HEDEFİ (Cem 27.10 "sınava benzemiyor" kuralı — KGK'da ölçüldü 29.10)
Çıkmış KGK soruları ↔ t8'de yazdıklarımız (`<IS>\profil-olc.js`, aynı ölçü):

| Modül | Kök medyanı (krk) | Olumsuz kök | Öncüllü | Şık medyanı (krk) |
|---|---|---|---|---|
| SPK | gerçek **174** · biz 460 | gerçek **%48** · biz %11 | gerçek **%11** · biz %27 | gerçek **33** · biz 59 |
| Bankacılık | **192** · 489 | **%34** · %8 | **%12** · %23 | **20** · 26 |
| Sigortacılık | **200** · 495 | **%36** · %8 | **%10** · %17 | **29** · 52 |
| TSRS | **426** · 476 | **%35** · %4 | **%21** · %22 | **82** · 84 |

**HEDEF (tavan değil):** grubunun 21 sorusunda kök medyanı gerçeğin ±%30'u; olumsuz kök ("hangisi yanlıştır / değildir / söylenemez /
… yer almaz") gerçeğe yakın (SPK 9–10, Banka/Sigorta 7, TSRS 7 soru / 21); öncüllü en çok 3 (TSRS 5); şıklar kısa.
- Talimattaki "olumlu kök tercih edilir" (madde 4) ve "olumsuz kök gerçek payı aşmaz" bu modüllerde **gerçek payı HEDEF alır** demektir.
- K15 (şart kökte olgu) GEÇERLİ ama kısa yaz: senaryo yerine çoğu soru doğrudan kural sorusu ("6362 sayılı Kanun'a göre aşağıdakilerden
  hangisi … değildir?"). Şartı olay olarak anlatman gerekmiyorsa anlatma; gerekiyorsa tek cümle.
- Çok zor = uzun kök değil; ince ayrım (iki benzer düzenleme, istisnanın istisnası) ya da öncüllü/olumsuz kök.
- Ölçüm: `node "<IS>\profil-olc.js" C:\TETIKTE-CALISMA\kgk-cizim\veri\fabrika "^hazir-kgk-t9-<grup>-"` → B_ sütunları hedefe yakın olmalı.
- Olumsuz kök çizim kapısıyla uyumludur: öncülsüz olumsuz kökte (SIK) doğru şık yanlış ifadedir; `teshis.<doğru>.gercek` o ifadenin
  NEDEN yanlış olduğunu söyler; her doğru ifadeli (yanlış) şıkkın tuzak metni "Bu ifade doğrudur; …" diye BAŞLAMASIN (SZ-CELISKI) —
  "… m.N gereği … yapılır." diye kuralı söylesin.

## ⛔⭐ 1b. KONU KONU PROFİL (Cem 30.10 "evet, koy") — §1'in ÜSTÜNE, çelişkide BU kazanır
Ders ortalaması yetmiyor: gerçek sınav AYNI KONUYU KARIŞIK sorar, biz konu başına TEK KALIP yazmışız (30.10 ölçüm: TMS 10 gerçek
13 sorunun 0'ı hesap ↔ bizim 3/3 hesap · "net işletme sermayesi tanımı" gerçek 59 krk sözel ↔ bizim 3/3 hesap · YK komiteleri gerçek
14 sorunun 5'i olumsuz ↔ bizim 0).
- Yazmadan ÖNCE grubunun hedefini aç: `<IS>\konu\profil-<grup>.txt` (yoksa `node "<IS>\konu-profil.js" hedef <grup> --yaz`).
  Her konunun soruları oradaki karışımı tutar: kaç hesap / kaç sözel, kaç "yanlıştır/değildir", kaç öncüllü, kök ≈ gerçek medyan.
  "HEPSİ SÖZEL" yazan konuya hesap sorusu YAZMA. Satırdaki "bak:" dönem+soru no'larını `cikmis-ara.js` ile oku (kalıp — kopyalama).
- Çıkmışta 3'ten az sorulmuş konu → modülün gerçek profili (kapı modül yedeğiyle ölçer).
- Zorluk ≠ uzunluk ≠ hesap: çok zor soru sözel olabilir (ince ayrım, istisnanın istisnası, olumsuz/öncüllü kök).
- Adet kuralı DEĞİŞMEDİ: konu başına soru sayısı son 10 yılda çıkan soruya orantılı (KGK-KAPSAMA); bu bölüm yalnız BİÇİMİ belirler.
- Teslimden önce: `node "<IS>\konu-profil.js" denetle C:\TETIKTE-CALISMA\kgk-cizim\veri\fabrika "^hazir-kgk-t9-" <grup>` → "✓ temiz".
  plan-kur.js bunu ZORUNLU kapı 3 olarak koşar; KUSUR'lu grup için plan YAZILMAZ.
- Son mesaja ekle: konu-profil özet satırı (kök ↔ gerçek · olumsuz · hesap).

## ⛔⭐ 1d. KONU İÇİ KALIP KARIŞIMI (sözleşme B30; Cem 03.11 "Evet, kur") — gerçek sınav aynı konuyu FARKLI soru cümlesiyle sorar
`<IS>\konu\profil-<grup>.txt` her konuda bir **KALIP** satırı verir: gerçekte hangi kalıplarla soruldu · sitede hangileri var ·
**ÖNCE YAZ** (gerçekte var, sitede yok) · **EKLEME** (sitede zaten yığılmış kalıp). Kalıp harfleri dosyanın sonunda.
- Konunun 3 sorusu mümkünse 3 FARKLI kalıpla ve önce "ÖNCE YAZ" kalıplarından yazılır. Sitede ≥%60 tek kalıba yığılmış konuya aynı
  kalıpla soru eklemek kapıdan DÖNER. Modülün gerçek sınavında hiç görülmemiş kalıp yazılmaz.
- Gerçek veri: 3.893 çıkmış KGK sorusu (2016+) elle kalıp etiketli — `veri/sinav/kgk-kalip-elle-3905.json`; tablo
  `veri/sinav/kgk-duzeltme/konu-konu-kalip.md`.
- ⚠ 03.11 düzeltme: kitapçık metni ↔ konu bağı önceden sıra kuralıyla kuruluyordu ve %18–35 kayıyordu; profiller içerikle yeniden
  kuruldu. Gerçek kök medyanları KISALDI (ör. Sermaye Piyasası konu medyanı ≈142 krk) — hedefe göre yaz, eski alışkanlığa göre değil.
- Teslimden önce ölçü satırı: `node "<IS>\olcu-satiri.js" C:\TETIKTE-CALISMA\kgk-cizim\veri\fabrika t9 <grup>` → her soru GEÇER.

## ⛔ 1c. GİZLİ İZLER (30.10 ölçüldü: çıkmış 2018+ 2.665 cevap anahtarlı soru ↔ sitedeki 1.815) — BRIF-T8 satır 66'nın YERİNE
| İz | Gerçek | Biz | Kural |
|---|---|---|---|
| Şirket adı "(K) A.Ş." | %0 | %53 | Tek harf parantezli ad YAZMA. Gerçek biçim: "A işletmesi", "XYZ AŞ", "ABC Denetim Şirketi", son sınavlarda kısa kurgusal ad ("Doğal Tat Gıda AŞ"). |
| Kökte açık yıl (20xx) | %9 | %66 | Yıl yalnız kural yıla bağlıysa (eşik, yürürlük, geçiş hükmü). Standart sorusunda "cari dönem / önceki dönem / dönem sonu" yaz. |
| Şık boyu en uzun/en kısa | 2,1 | 1,3 | Şıkları yapay olarak eşit boya getirme; doğal uzunlukta yaz. |
| Doğru şık en uzun | %18 | %9 | Doğru şıkkı bilerek kısaltma; uzunluk ipucu iki yönde de iz bırakır. |
| Sayı şıklı soru | %7 | %28 | §1b konu karışımı ile azalır. |
Harf dağılımı, mutlak söz ("her zaman/hiçbir"), "hepsi/hiçbiri" şıkkı ve sayı şık sırası gerçeğe yakın — değiştirme.

## ⛔ 2. t8 OKUMA DERSLERİ (29.10 üst oturum + bu oturum)
- Kuralın uygulanma şartı kökte olgu (m.18 pay devrinde karşı tarafın eşik durumu, KRA elde tutma süresi, yeni SPK Rehberi'nin 13.08.2026
  sonrası başvuruya uygulanması).
- Kökteki oranlar mevzuatla tutarlı (Karşılıklar Yön. m.15: %100/80/60/40/20). m.49/2 risk grubu: "nitelikli pay yoksa %25" denmez.
- 2027'de yürürlüğe girecek düzenlemeye dayanılmaz (Sigortacılık Tekdüzen Hesap Planı Tebliği).
- Ön denetim çeldiricide "= %3,03" biçimini okuyamıyor → "x 100 = 3,03".
- **"… Tuzağı Tuzağı:" YAZMA** (t8'de 5 dosyada; ad bir kez "Tuzağı" ile biter).
- **`sade.kavramlar[].kaynak`'taki her kayıt `kaynak_adlar`'da** (t8 spk-g7'de bu yüzden bir soru son okumada çıktı).
- Kökte yıl tutarlılığı: kanunun yürürlüğünden önceki yıla o kanunun suçunu/hükmünü yazma (t8 spk-g9: 6362 öncesi 2008).
- Kısa alan (hap, sinav_taktigi, sade.*, notlandirici, teshis.*) kuralın ŞARTINI taşır — t8'de çıkan 8 sorunun 3'ü bu.
- ⛔ **ÖNCÜLLÜ SORUDA HER YANLIŞ ŞIK DOĞRU KÜMEDEN TEK ÖNCÜLLE AYRILIR** (G2; 29.10 banka dalgasında okumada çıkan 4 sorunun 4'ü bu).
  Doğru küme "I ve III" ise yanlış şıklar ör. "Yalnız I", "I, II ve III", "I, III ve IV", "Yalnız III" — her biri TEK öncülü ekler ya da
  çıkarır ve o tek öncülün yanılgısı açıklamada yazılıdır. "II ve IV" (iki öncül farklı) gibi şık YAZILMAZ.

## ⛔ 3. KAYNAK BOŞLUKLARI — bu konulara dayanma (ambarda yok; son mesajda "KAYNAK YOK: <konu>")
Sigorta Sözleşmelerinde Bilgilendirme Yönetmeliği · Finansal Raporlama (sunum) Tebliği · 2022/8 Matematik Karşılıklar Genelgesi · SPK Kâr
Payı Rehberi · SPK Sürdürülebilirlik İlkeleri Uyum Çerçevesi · BM SKA metni · Bankacılık Yıllık Faaliyet Raporu Yönetmeliği (RG 1/11/2006).
TSRS kapsam sorularında 22.10'da ambara alınan dört kurul kararı (PYŞ kapsam dışı, 2024 ihtiyari raporlama, Usul Esaslar, 2025 uzatma).

## 4. Çıkmış örnek (KALIP — KOPYALAMA)
`node "<IS>\cikmis-ara.js" "<anahtar kelime>" ["<ikinci>"] --n 3` (çıkmış KGK kitapçıkları, 2016+). Kök uzunluğu, olumsuz kip, şık biçimi için bak.

## 5. Teslim (0 KUSUR olana kadar; plan kurucu artık KUSURLU dosyayla plan YAZMAZ)
depo kökünden: `powershell -NoProfile -ExecutionPolicy Bypass -File arac/hazir-soru-denetle.ps1 -Dosya veri/fabrika/hazir-kgk-t9-<grup>-<zorluk>.json -IkizEtiket kgk-t9-<grup>-<zorluk> -Tavan 784`
+ `node arac/kgk-ek-kapi.js --dosya <dosya>` (KGK-CZ satırı yok) + profil ölçümü (yukarıda).
Dosya adı `hazir-kgk-t9-<grup>-<zorluk>.json` (t8 yarım grupları için `hazir-kgk-t8-...`).

## Son mesajın (EN ÇOK 6 satır)
grup · dosya başına soru + denetim (0 KUSUR) + KGK-CZ · profil (kök medyanı, olumsuz/öncüllü sayısı) · KAYNAK YOK · emin olmadığın hüküm (kaynak adıyla). Soru metni yazma.
