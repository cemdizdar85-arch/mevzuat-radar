# Kanun değişikliği taraması 2021–2026 — SGS + Yeterlilik bankası (10.10.2026, sinav kolu)

İstek: GVK m.22/4 (7491) ve VUK m.320/3 (7338) bulgularından sonra, `arac/eski-kurallar.json` listesinde olmayan eskimiş kuralları
sistematik bulmak. Yöntem `veri/sinav/GVK-22-4-TARAMA-20261010.md` ile aynı. **Soru metni bu dosyada YOK** (depo public); yalnız kimlik + madde.

## Yöntem
1. **Değişiklik listesi** (resmî kaynak = ambardaki mevzuat.gov.tr kopyaları `veri/mevzuat/*.json`, belge_tarihi 2026-10-08 / tebliğler 2026-08-14…16):
   26 kanun metninde satır içi "(Değişik/Ek/Mülga: gg/aa/yyyy-sayı md.)" notları + dipnot biçimi ("… tarihli ve N sayılı Kanunun/CBK … değiştirilmiştir")
   → 2021–2026 tarihli **667 not / 389 madde**. Ayrıca yıllık tutar tebliğleri: GV GT 332 (2026 tarifesi ve hadler), DV GT 71, VİVK GT 57,
   MTV GT 58, VUK GT 588 (2026 hadleri), 2026 asgari ücret kararı; Cumhurbaşkanı Kararıyla değişen oran/tutarlar (6183 m.51 gecikme zammı
   CBK 10556, TTK m.332/580 asgari sermaye CBK 7887, 6183 m.48 tecil sınırı).
   Her değişiklik okundu: madde metni + değişiklik notu + dipnot. **Okunmayan madde listeye girmedi**; eski metni ambarda olmayanlarda
   eski kural değişiklik notundan yazıldı ve tabloda/ölçülmedi satırında belirtildi.
2. **Banka:** yerel ambar kopyası `veri/fabrika/kalip-parti-(sgs|smmm)-*.json` — **2.458 parti · 14.489 soru (SGS 7.660 · Yeterlilik 6.829)**,
   öğrenciye görünen alanlar (kök, şıklar, açıklama, sade, teşhis, adımlar, hap, ikiz, konu girişi; model alanları hariç).
   Ön ayıklama: değişen her maddeye bankada kaç sorunun atıf yaptığı sayıldı (373 maddenin 89'una atıf var) — atıf 0 olan maddeler de
   konu kelimesiyle ayrıca arandı.
3. **Tarama:** her ilgili değişiklik için eski kuralın izini taşıyan 1–3 desen **bankanın tamamında** koştu; çıkan adaylar okundu
   (7 kanun grubu paralel okundu). 4 grupta aday çok olunca iki aşama yapıldı (geniş desen → bağlam ayıklama → tam okuma); iki aşama
   sayıları tabloda (Aday ≠ Okunan) ve "ölçülmedi" satırlarında. Sınıflar: anahtar yanlış · iki cevaplı · cevap doğru açıklama eski · doğru · kapsam dışı.
4. **Doğrulama:** okuyucuların anahtar yanlış/iki cevaplı dediği her konunun resmî metni ayrıca yeniden okundu (KDVK m.29/1-ç, geç. m.30;
   GV GT 332 tarifesi; GVK m.21/2; 5510 m.41; 6183 m.51 dipnotu; DVK tablo IV-34 (7349); Çek K. geç. m.3/5; TTK m.4/2; VUK ek m.1 ve m.328;
   Odalar Yön. m.16/b-2) ve örnek sorular okunarak hesap yeniden yapıldı.

## Sonuç (üç sayı ayrı)

| | Sayı |
|---|---|
| Okunan değişiklik satırı (tablo) | **165** (140 ilgili · 25 kapsam dışı) |
| Desen adayı / okunan | 5.902 / 5.241 (aynı soru birden çok desende sayılabilir; 661'i bağlamdan ayıklandı, tam okunmadı — aşağıda) |
| **Bulgulu tekil soru** | **123** — anahtar yanlış **40** · iki cevaplı **5** · cevap doğru açıklama eski **78** (SGS 39 · Yeterlilik 84) |
| Elle ret listesinde (yayın dışı, onarılana kadar) | **45** (anahtar yanlış + iki cevaplı; SGS 11 yeni · Yeterlilik 31 yeni + 3 zaten listedeydi) |
| Onarılan (ambara yazıldı + geri okundu) | **0** — onarım taslakları sonraki adım (aşağıda) |
| Sitede hâlâ | yeni elle ret kayıtları bir sonraki kasa/site yayınında düşer; **yayındaki kümeyle kesişim ÖLÇÜLMEDİ** |

En sık kök: **kök "2026" diyor ama 2023–2025 tutarını "varsayım" demeden gerçek tutar gibi yazıyor** (GV tarifesi, mesken istisnası,
binek kira sınırı, VUK m.177 hadleri, gecikme zammı %2,5, damga azami tutarı). İkinci kök: **süresi bitmiş/mülga hüküm güncel gibi**
(KDVK geç. m.30, asgari geçim indirimi, nispi aidat, eski m.41 %32 borçlanma oranı). Üçüncüsü: **eklenen seçenek/istisna yok sayılmış**
(KDVK m.29/1-ç sorumlu KDV indirimi, VUK m.320/3 gün esası, ek m.1 %50 artırımlı indirim, m.328/4-b kalan fon, 9. değerleme ölçüsü).

Banka kendi içinde çelişen üç konu (aynı olayda iki zıt cevap): KDVK m.29/1-ç (kp-29 ↔ olc2-a/kp-70, olc2-b/kp-60) · Çek erken ibraz
(t5-ticaret/kp-11 ↔ k2-ticaret/kp-02) · 5510 m.41 oranı (p-borclar-r1/kp-04 güncel okuma, öbür 8 soru eski).

⚠ **5510 m.41 çekincesi:** güncel metin "(a) bendinde bulunanlar için %32'si diğerleri için %45'i" diyor ((a) = doğum borçlanması). 7566'nın
madde metni ve m.41 dipnotları ambarda kesik; yürürlük (1/1/2026) yürürlük tablosundan. 8 soru bu okumaya göre "anahtar yanlış" sayıldı.

## Kapı (KAPI-EK) — EK24–EK43
`arac/eski-kurallar.json` 20 yeni kural (kaynak + bulan yazılı, hepsi `sikHaric`), `arac/eski-kural-kapisi.js --sinav` her kurala
1 yakalama + 1 meşru vaka (+ EK35 ikinci sıra vakası). **Öz-sınav 119/119 YEŞİL · mutasyon 3/3 KIRMIZI** (haric-yok · model-dahil · sik-haric-yok).
Okuyucu önerilerinden 38 desen bankada sınandı; bulunan soruyu yakalamayan / yanlış alarmı yüksek olanlar alınmadı (aşağıda).

Banka koşusu (14.489 soru, yeni kurallar): işaretli soruların okunması 11 ek bulgu verdi (1 anahtar yanlış: smmm-dog1-vergi/kp-51;
10 açıklama eski) — tabloda "kapı banka koşusu" satırı. Yanlış alarm olarak okunanlar: EK37 sgs-d3-vergi-kolay-r1/kp-01 (tutar "soruda verilen" 2025 değeri),
EK38 sgs-a6-fmuh-cokzor-r1/kp-03 (ikramiye, zaten elle rette), EK32 smmm-olc2-b-vergi/kp-01 ("varsayılmıştır" 120 karakter penceresinin dışında).

| Kod | Kural | Bankada işaretli soru | Bulgulu (tabloda) | Bulgusuz → okundu, yanlış alarm |
|---|---|---|---|---|
| EK24 | VUK: "kıst/ay kesri yalnız binek otomobilde, diğerlerinde tam yıl" mutlak iddiası (m.320/3 | 8 | 8 | 0 |
| EK25 | VUK m.261 "sekiz değerleme ölçüsü" (7338 ile 9. ölçü eklendi) | 5 | 5 | 0 |
| EK26 | VUK m.328: yenileme yapıldığı hâlde süre sonunda fonda kalan bakiyenin kâra eklendiği iddi | 1 | 1 | 0 |
| EK27 | VUK m.262/c: kıymetin envantere alındığı dönem sonuna kadarki kredi faizinin maliyete ekle | 1 | 1 | 0 |
| EK28 | 2025–2027 hesap döneminde VUK enflasyon düzeltmesi yapılıyor gibi anlatım (VUK geç. m.37:  | 2 | 2 | 0 |
| EK29 | VUK ek m.1: uzlaşmada vergi aslının da uzlaşma konusu olduğu (7524 ile yalnız cezalar) | 1 | 1 | 0 |
| EK30 | Asgari geçim indirimi güncel kurum gibi (GVK m.32, 7349 ile 1/1/2022'den mülga) | 5 | 5 | 0 |
| EK31 | 2026 tarifesi diye eski yıl dilim tutarı (GV GT 332: 190.000 / 400.000 / 1.000.000 (ücret  | 9 | 9 | 0 |
| EK32 | 2026 mesken kira istisnası eski tutar (GV GT 332: 58.000) | 4 | 3 | 1 (smmm-olc2-b-vergi/kp-01) |
| EK33 | 2026 binek otomobil aylık kira sınırı eski tutar (GV GT 332: 46.000) | 1 | 1 | 0 |
| EK34 | Basit usul kazancının beyan edildiği iddiası (GVK mük. m.20/A: 2021'den istisna) | 2 | 2 | 0 |
| EK35 | KDVK geç. m.30 büyük yatırım inşaat KDV iadesinin 2024+ yılına uygulanması (madde 31/12/20 | 2 | 2 | 0 |
| EK36 | 6183 m.51 gecikme zammı eski oran (CBK 10556, 13/11/2025: aylık %3,7) | 2 | 2 | 0 |
| EK37 | Damga vergisi azami tutarının eski yıl değeri yılsız kullanılıyor (2026: 29.115.961,10 TL, | 3 | 2 | 1 (sgs-d3-vergi-kolay-r1/kp-01) |
| EK38 | Ücret damga vergisinin asgari ücret istisnası olmadan brütün tamamından hesaplanması (DVK  | 4 | 3 | 1 (sgs-a6-fmuh-cokzor-r1/kp-03) |
| EK39 | VUK m.177 defter tutma haddi diye gerçek dışı tutar (2026: alım 2.500.000 / satış 3.500.00 | 3 | 3 | 0 |
| EK40 | TTK m.4/2 basit yargılama sınırı sabit 1.000.000 TL (7445: yıllık yeniden değerleme ile ar | 7 | 7 | 0 |
| EK41 | İleri tarihli çekin erken ibrazında "ibraz günü ödenir" (Çek K. geç. m.3/5: 31/12/2028'e k | 4 | 4 | 0 |
| EK42 | Askerlik (er/erbaş) borçlanmasına %39 oranı (5510 m.41: %39 yalnız GSS primi ödenmiş kısmi | 8 | 8 | 0 |
| EK43 | SMMM odası nispi aidatı (%1 mesleki kazanç) güncel gibi (Odalar Yön. m.16/b-2 Danıştay 8.  | 8 | 8 | 0 |

Not: EK30'un 5. işareti smmm-dog1-vergi/kp-51 yalnız konu etiketinden ("asgari gecim indirimi"); soru KDVK geç. m.30 yüzünden anahtar yanlış (tabloda).

🚫 **GÖRMEZ (ölçüldü 10.10):** 5510 m.41 %32 uygulayan 8 sorunun hiçbirini (oranı sayıyla uygulayıp "%32" yazmayan hesap) ·
KDVK m.29/1-ç (kp-29: "indirim zincirine girmez" — öneri deseni 0/1 yakaladı, alınmadı) · EK35 yıl ile "inşaat" ayrı cümledeyse (dog1-vergi/kp-13) ·
GVK m.21/2 yorum hatası (ticari kazanç beyan edene mesken istisnası) · TTK m.580 asgari sermaye (öneri deseni 10 işaretin 9'u yanlış alarm, alınmadı) ·
sayıyı değil ifadeyi yazan eski kural · kökte yıl yazmadan eski tutar kullanan soru (EK31–EK33 "2026" arar).
Alınmayan öneriler (bankada 0 isabet ya da vakası tutmadı): hizmet ihracatı %50, taşınmaz istisnası %75/%50, üretim %12,5 erken yıl,
sorumlu KDV indirilmez, GİO son üç ay, SGK 5 puan genel, MYÖ %20, PEK tavan 7,5, analık 16 hafta, işsizlik Devlet payı, asgari ücret 2025,
ruhsat kullandırma hafif ceza, disiplin karar tarihi, tekerrür ikinci kez, kripto SPK dışı, YTM gelir kaydı, TTK asgari sermaye eski tutar.

## Onarım ve hakem (Cem'e)
- **45 kök/anahtar onarımı** (40 anahtar yanlış + 5 iki cevaplı): resmî kaynaktan elle onarım → `arac/onarim-hatti.js uygula` (fark denetimi) →
  `teslim`. Kök/anahtar değişeceği için model alanları silinir, soru **yeniden hakeme kadar elle rette kalır**.
  **Yeniden hakem bedeli (tahmin, emsal 0,1 USD/soru — GVK 22/4 planı):** 45 × 0,1 ≈ **4,5 USD**. **Onay bekliyor; bulut sırasına KONMADI.**
- **78 açıklama onarımı:** anahtar/kök değişmez → model alanları korunur, yeniden hakem gerekmez, bedel 0; onarılınca bir sonraki yayında düzelir.
- Onarım taslakları bu commit'te YOK (sonraki adım).

## Ölçülmeyenler (toplu)
- Bağlamdan ayıklanıp tam okunmayan 661 aday (VUK kıst 159, enflasyon düzeltmesi 364, komisyon 102; GVK kâr payı stopajı 15, m.22/4 yeniden okuma 20;
  iş/SGK sendika 101 — 6356'da 2021–2026 değişiklik notu yok).
- Eski madde metinleri ambarda yok: VUK m.112, m.273, ek m.7, ek m.11 kaldırılan cümleler; GVK m.117, m.17, m.69 (kesik), m.74 (7566);
  KVK m.32/8 (7582 öncesi), 32/C ilk yılı; KDVK m.17/4-r eski metni, m.36 AYM iptal cümlesi; 6183 m.58 ve m.28/1 AYM iptalleri;
  TTK m.580 dipnot 83–84 metni (Ltd. tutarı elle-yutmalar dosyasındaki 7887 CBK metninden okundu); 3568 m.50 2023 iptali (dipnot 26 yok).
- TTK m.4/2 2026 basit yargılama tutarının resmî ilanı ambarda yok (bulgular sınırın 1.000.000'i geçmiş olmasına dayanıyor).
- Kıdem tazminatı tavanı TL tutarı ambarda yok (2026 tavanı veren 4 soru doğrulanamadı).
- Geçici vergi (7338 ve 1/1/2025 değişikliği) içeriği ambardan çıkarılamadı; "dördüncü geçici vergi" diyen 5 muhasebe sorusu sınıflanmadı.
- 3628 Mal Bildirimi Kanunu ambarda yok (bankada konusu da yok).
- KVK geç. 14/15/19 (KKM, varlık barışı) banka taraması koşulmadı; `kvkgut.json` / `kdvgut.json` okunmadı.
- Danıştay nispi aidat kararının kesinleşmesi ambarda yazmıyor (mevzuat.gov.tr metnindeki "iptal alt bent" ibaresine dayanıldı).
- KGK bankası bu taramanın kapsamı dışında (görev SGS + Yeterlilik) — **"sınav = üçü" kuralına göre KGK ölçülmedi.**

## Değişiklik × aday × bulgu tablosu

### VUK

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| VUK ek m.1 (ikinci fıkra ek cümle) + m.376/1-1 | 14/10/2021-7338/44 md. | Fiil bazında toplam tutarı 5.000 TL'yi (2026: 40.000 TL ve altı) aşmayan usulsüzlük ve özel usulsüzlük cezaları uzlaşmaya konu edilemez; bun | ilgili | 7 | 7 | 2 | 0 | 0 |
| VUK m.376/1-2 (bent mülga) | 28/7/2024-7524/14 md. | m.376'da yalnız (1) numaralı bent kaldı: 30 gün içinde başvurup vadesinde/teminatla 3 ayda ödeme taahhüdünde kesilen cezanın yarısı indirili | ilgili | 62 | 62 | 0 | 0 | 0 |
| VUK ek m.1, ek m.7, ek m.8, ek m.11 (uzlaşmada vergi aslı çıkarıldı) | 28/7/2024-7524/14 md. | Uzlaşma yalnız ikmalen/re'sen/idarece tarh edilen vergilere ilişkin vergi ziyaı cezaları ile eşik üstü usulsüzlük/özel usulsüzlük cezalarını | ilgili | 63 | 63 | 0 | 0 | 1 |
| VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle | 14/10/2021-7338/34 (m.320), 7338/33 (m.318) | Dileyen mükellef aktife yeni kaydedilen kıymetlerde (binek hariç) kullanıma hazır olduğu tarihten başlayarak gün esasına göre amortisman ayı | ilgili | 247 | 247 | 1 | 0 | 10 |
| VUK m.328 dördüncü-beşinci fıkra (satış kârı / yenileme) ve m.329 (sigorta tazminatı) | 14/10/2021-7338/36 (m.328), 7338/37 (m.329) | Bilanço esasında satış kârı, satışı takip eden üçüncü takvim yılı sonuna kadar pasifte geçici hesapta tutulabilir; bu sürede yenileme gerçek | ilgili | 120 | 120 | 2 | 0 | 0 |
| VUK m.323 beşinci fıkra (işletme hesabında şüpheli alacak) | 14/10/2021-7338/35 md. | İşletme hesabı esasında defter tutanlar şüpheli alacaklarını defterin gider kısmına, sonradan tahsil edilenleri tahsil dönemi gelir kısmına  | ilgili | 30 | 30 | 0 | 0 | 0 |
| VUK m.270 (mülga), m.262 ek fıkralar, m.268/A (alış bedeli), m.273 ikinci cümle mülga | 14/10/2021-7338/27-30 md. | m.262: gümrük, nakliye, montaj, harç, noter, tapu, danışmanlık, komisyon vb. maliyete dahil; kredi faizi/kur farkının emtiada stoka girişe,  | ilgili | 0 | 0 | 0 | 0 | 0 |
| VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı) | 14/10/2021-7338/27 md. | Finansman faizi ve kur farkının emtiada stoka girişe, diğer kıymetlerde envantere alındığı hesap dönemi sonuna kadarki kısmı maliyete ZORUNL | ilgili | 125 | 23 | 0 | 1 | 5 |
| VUK m.261/9 (dokuzuncu değerleme ölçüsü: alış bedeli) + m.268/A | 14/10/2021-7338/26, 7338/28 md. | m.261 dokuz değerleme ölçüsü sayar; 9. ölçü alış bedelidir (m.268/A: satın alma bedeli, diğer giderler dahil değil). | ilgili | 46 | 46 | 0 | 0 | 1 |
| VUK gec. m.37 (2025-2027 enflasyon düzeltmesi yapılmaz) + gec. m.33 ek fıkra/cümleler + mük. m.298/A-10 | 24/12/2025-7571/34 (gec. 37); 27/12/2023-7491/17 ve 24/10/20 | 2025 hesap dönemi ile geçici vergi dönemleri dahil 2026 ve 2027 hesap dönemlerinde şartlara bakılmaksızın mali tablolar enflasyon düzeltmesi | ilgili | 460 | 96 | 0 | 0 | 2 |
| VUK m.339 (tekerrür) | 14/10/2021-7338/38 md. | Cezası kesinleşenlere VZC'de kesinleşmeyi izleyen günden itibaren 5. yılın, usulsüzlükte 2. yılın isabet ettiği takvim yılı sonuna kadar tek | ilgili | 73 | 73 | 0 | 0 | 0 |
| VUK m.344 ek fıkra (kayıt dışı faaliyette VZC %50 artırımlı) | 28/7/2024-7524/9 md. | Mükellefiyet tesis ettirmeden vergi dairesinin ıttılaı dışında faaliyetle vergi ziyaına sebebiyet verilirse 1., 2., 3. fıkraya göre VZC %50  | ilgili | 29 | 29 | 0 | 0 | 0 |
| VUK m.359 (ç),(d) bentleri ve etkin pişmanlık/zincirleme ek fıkraları; m.367 ek fıkralar | 29/4/2021-7318/4-5; 8/4/2022-7394/4-5; 30/11/2022-7423/1 md. | Metindeki güncel hâl (m.359 [3/5]-[5/5]). | ilgili | 7 | 7 | 0 | 0 | 0 |
| VUK m.153/A (teminat: 60 gün, %10 tutarında, üst sınır; mülga cümleler) | 28/7/2024-7524/5 md. | Keyfiyetin ıttılaa girmesini müteakiben yazıyla, 75.000 TL'den az ve 10 milyon TL'den fazla olmamak üzere sahte belge toplamının %10'u tutar | ilgili | 29 | 29 | 0 | 0 | 0 |
| VUK m.231/5 ek cümle (Bakanlık süreyi kısaltabilir) ve m.234 (gider pusulası 7 gün; banka belgesi yerine geçer) | 29/4/2021-7318/1 (m.231); 14/10/2021-7338/23 (m.234) | Fatura azami 7 gün (Bakanlık kısaltabilir/anında düzenleme getirebilir); gider pusulası azami 7 gün, süresinde düzenlenmeyen hiç düzenlenmem | ilgili | 31 | 31 | 0 | 0 | 0 |
| VUK m.353 (özel usulsüzlük: ilk tespit/2 sayılı cetvel, 5 iş günü bildirim, kat uygulamaları) ve mük. m.355 ek fıkralar (başkasının hesabı, başkasının POS'u 3 kat, tek fiile en ağır ceza) | 28/7/2024-7524/11, 7524/13 md.; 14/10/2021-7338/40; 1/7/2022 | Metindeki güncel hâl (m.353 [1/8]-[8/8], mük. m.355 [4/9]-[9/9], m.416 2 sayılı cetvel). | ilgili | 21 | 21 | 0 | 0 | 0 |
| VUK m.274/A (kıymetli madenler borsa rayici) + m.263 | 28/7/2024-7524/7-8 md. | Altın, gümüş, platin, paladyum borsa rayici ile; rayiç yoksa/muvazaalıysa maliyet bedeli; kıymetli maden cinsinden alacak-borç, mevduat ve k | ilgili | 70 | 70 | 0 | 0 | 0 |
| VUK m.15 üçüncü fıkra (mücbir sebep ilanı: 3. ay sonu biter, 18 aya kadar uzatma) | 25/12/2024-7537/8 md. | Bakanlık bölge/afete maruz kalanlar itibarıyla mücbir sebep ilan eder; ilan edilen yerlerde mücbir sebep vuku ayını izleyen 3. ayın son günü | ilgili | 28 | 28 | 0 | 0 | 0 |
| VUK m.107/A (elektronik tebligat, yeniden düzenleme) + gec. m.38 | 24/6/2026-7587/9, 7587/11 | Zorunlu: KV mükellefleri, gerçek usulde ticari/zirai/mesleki kazanç GV mükellefleri, kollektif ve adi komandit şirketler, ÖTV (II) ilk iktis | ilgili | 10 | 10 | 0 | 0 | 0 |
| VUK mük. m.227 ek cümle (YMM tasdik raporu: 60 günlük mühlet) + m.353/11 | 14/10/2021-7338/22, 7338/40 | Tasdik raporu zamanında ibraz edilmezse tebliğ şartıyla 60 gün mühlet; bu sürede de verilmezse haktan yararlanılamaz; süresinde ibraz edilme | ilgili | 34 | 34 | 0 | 0 | 0 |
| VUK m.112 (7524 ile bir cümle mülga) | 28/7/2024-7524/14 md. | Gecikme faizi 6183'e göre gecikme zammı oranında; ay kesirleri nazara alınmaz (m.112 [2/3]). | ilgili | 71 | 12 | 0 | 0 | 0 |
| Kapsam dışı / bankada konusu bulunmayan değişiklikler: m.4, m.5 (hizmet alımı mahremiyeti), m.97, m.104, m.120, m.131 (7555), m.140, m.170/A, m.226/A, mük. m.242, mük. m.257 (7318/7417/7421/7524), m.318, m.329 dördüncü fıkra, ek m.13, ek m.14-18 (karşılıklı anlaşma), mük. m.413 (7491), gec. m.30-32, 34-36, 38, m.416 cetvel başlığı | 7318, 7338, 7394, 7417, 7421, 7491, 7524, 7537, 7555, 7587 | Güncel metinler vuk.json'da. | kapsam dışı | 80 | 80 | 0 | 0 | 0 |

Ölçülmedi (VUK): Değişikliklerin ESKİ metinleri ambarda yok (vuk.json yalnız güncel metin + bazı dipnotlar). Eski kurallar değişiklik notundan yazıldı; m.112'de 7524 ile kaldırılan cümlenin, m.273'te 7338 ile kaldırılan ikinci cümlenin,  · m.328 için 'üç yıl' kalıbının 7338 öncesi kural olup olmadığı ambardan doğrulanamadı; 'üç yıl süreyle bekletilir' diyen 4 açıklama (sgs-t1-fmuh-cokzor/kp-83, smmm-w4-fmuh-zor/kp-21, smmm-w5-fmuh-cokzor/kp-23, smmm-w5-fmu · Kıst amortisman taramasında geniş desen 197 aday verdi; VUK/vergi/binek/320 bağlamlı 38 soru tam okundu, kalan 159'un eşleşen cümlesi tek tek gözden geçirildi (TMS 16/38, faiz tahakkuku, kıdem, kıst dönem beyanı = KAPSAM · Enflasyon düzeltmesi: 460 adayın 364'ü bağlamdan (TMS 29 / hesap terimi / VUK dışı) ayıklandı, tam okunmadı. · Menkul kıymet komisyonu (m.268/A alış bedeli): 106 aday; yalnız VUK/279/268 geçen 4'ü okundu, kalanlar THP kayıt soruları (komisyon 653'e) — tam okunmadı. · Yeniden değerleme oranı / had tutarları (parantez içi 2026 tutarları, 588 Sıra No.lu Tebliğ) kanun değişikliği olmadığı için bu grupta taranmadı; bankada 323 had tutarı 25.000 TL olarak tutarlı görüldü. · atif.json'da m.371 (21 atıf) değişikliği yalnız Bakanlık yetki fıkrası (7338/42) — pişmanlık zammı/şartları değişmediği için ayrıca taranmadı. · Scratchpad ortak kullanılıyor: d4.js/d5.js gibi desen dosyaları başka grup tarafından üzerine yazıldı; sayımlar o anki çalıştırmalardan alındı (vara-son.json güvenilir değil). Tekil birleşik aday sayısı bu nedenle ÖLÇÜLM

### GVK + GV GT 332

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| GVK m.32 (asgari geçim indirimi) | 22/12/2021-7349/3 md. (Mülga) | m.32 mülga; yerine m.23/1-18 asgari ücret istisnası | ilgili | 5 | 5 | 0 | 1 | 3 |
| GVK m.23/1-18 (asgari ücret istisnası) | 22/12/2021-7349/2 md. (Ek) | Asgari ücretin SGK+işsizlik primi düşülmüş tutarına isabet eden ücret istisna; vergi istisnaya isabet eden kısım düşülerek hesaplanır; birde | ilgili | 6 | 6 | 0 | 0 | 0 |
| GVK m.64, 110, 118, 122 (diğer ücret) ile m.106/1-2, m.108/1-3, m.109/1-2 ve 2.-3. fıkra | 22/12/2021-7349/3 md. | Diğer ücret usulü kaldırıldı; yalnız gerçek ücret | ilgili | 2 | 2 | 0 | 0 | 0 |
| GVK m.103 tarife (2026 dilimleri) | GV Genel Tebliği Seri No:332 m.3/3 (mük.m.123 uyarınca yıllı | 2026: 190.000 %15; 400.000 %20; 1.000.000 (ücret 1.500.000) %27; 5.300.000 %35; üstü %40 | ilgili | 93 | 93 | 1 | 0 | 4 |
| GVK mük.m.20 (genç girişimci istisnası tutarı) | gec.m.5 cetvelinde 12/3/2023 yayım tarihli kanun (cetvel sat | Kazancın m.103 tarifesinin ikinci diliminde yer alan tutara kadar olan kısmı istisna → 2026: 400.000 TL (GT 332 m.3/3); istisna haddinin alt | ilgili | 15 | 15 | 6 | 0 | 1 |
| GVK m.21 (mesken kira istisnası tutarı) | GV Genel Tebliği Seri No:332 m.3/2-b | 2026: 58.000 TL; istisna sınırı (m.21/2) tarifenin 3. diliminde ücret için yazılı tutar = 1.500.000 | ilgili | 48 | 48 | 3 | 0 | 1 |
| GVK m.21/2 yorum hatası (değişiklik DEĞİL — okuma sırasında görüldü) | — (hüküm 31/5/2012-6322/5 md.; 2021-2026 değişikliği değil) | m.21/2: "Ticari, zirai veya mesleki kazancının yıllık beyanname ile bildirmek mecburiyetinde olanlar ile istisna haddinin üzerinde hasılat e | kapsam dışı | 48 | 48 | 1 | 0 | 1 |
| GVK m.86/1-c ve 1-d (beyan sınırları) | GT 332 m.3/2-i (1-d: 22.000) ve m.3/3 (1-c: ikinci dilim 400 | 1-d 22.000; 1-c 400.000; 1-b tek işveren 5.300.000, ikinci+ işveren 400.000 | ilgili | 64 | 64 | 1 | 0 | 2 |
| GVK m.40/1, 40/7, 68/4-5 (binek otomobil tutarları) | GT 332 m.3/2-e, ğ | 2026: kira 46.000; ÖTV+KDV 1.200.000; amortisman 1.380.000 (ikinci el/vergiler maliyete eklenmişse 2.600.000); gider kısıtı %70 (7194, 2020  | ilgili | 76 | 76 | 1 | 0 | 1 |
| GVK m.31 (engellilik indirimi tutarları) | GT 332 m.3/2-d | 2026: 12.000/7.000/3.000 | ilgili | 5 | 5 | 0 | 0 | 0 |
| GVK m.23/1-8 ve 23/1-10 (yemek ve ulaşım istisnası) | 3/11/2022-7420 (m.23/8 nakit yemek bedeli istisna kapsamına  | İşyerinde yemek verilmeyen durumlarda nakit yemek bedeli de günlük 300 TL'ye kadar istisna; ulaşım 158 TL (kart/bilet şartı) | ilgili | 19 | 19 | 0 | 0 | 0 |
| GVK mük.m.80/3 ve m.82 (değer artışı / arızi kazanç istisnaları) | GT 332 m.3/2-h, ı | 2026: 150.000 / 350.000 | ilgili | 22 | 22 | 0 | 0 | 0 |
| GVK m.47/48 ve m.9/10 (basit usul hadleri, e-ticaret esnaf muaflığı hasılatı) | GT 332 m.3/2-a, f, g | 2026: 99.000/60.000; 1.200.000-1.900.000/600.000/1.200.000; m.9/10 1.900.000 | ilgili | 17 | 17 | 0 | 0 | 0 |
| GVK mük.m.121 (vergiye uyumlu mükellef indirimi) | 14/10/2021-7338/10 md. (2. bent değişik: kesinleşmiş tarhiya | Kesinleşen tarhiyat indirim tutar sınırının %1'ini aşmıyorsa şart bozulmaz; 2026 tavan 12.000.000 | ilgili | 8 | 8 | 0 | 0 | 0 |
| GVK mük.m.20/A (basit usul kazanç istisnası), m.46/1 3. cümle mülga, m.89/1-15 mülga | 14/10/2021-7338/1, 4, 5 md. | Basit usulde tespit edilen kazanç gelir vergisinden müstesna; bu kazanç için beyanname verilmez, diğer gelirler için verilen beyannameye dah | ilgili | 31 | 31 | 0 | 0 | 2 |
| GVK mük.m.20/B (sosyal içerik üreticisi / uygulama geliştirici istisnası) | 14/10/2021-7338/2 (Ek); 27/12/2023-7491/7 (Değişik) | Banka hesabı şartı, %15 tevkifat, 4. dilim sınırı | ilgili | 6 | 6 | 0 | 0 | 0 |
| GVK mük.m.20/C ve m.94/1-11-d (tarımsal destekleme ödemeleri) | 14/10/2021-7338/3 (Ek) ve 7338/7 (m.94/11-d mülga); gec.m.92 | Tarımsal destekleme ödemeleri gelir vergisinden müstesna | ilgili | 2 | 2 | 0 | 0 | 0 |
| GVK mük.m.20/D (yurt dışı kazanç istisnası, 20 yıl) | 21/5/2026-7582/4 md. (Ek) + GT 333 | Önceki son 3 yıl ikametgâh ve mükellefiyeti olmayanların yurt dışı kazanç ve iratları 20 yıl istisna; beyannameye girmez | ilgili | 11 | 11 | 0 | 0 | 0 |
| GVK m.23/1-19 ve 23/1-20 | 3/11/2022-7420/2 (19); 21/5/2026-7582/5 (20) + GT 322, GT 33 | Yurt dışı inşaat-onarım-montaj-teknik hizmet ücretleri istisna; nitelikli hizmet merkezi personel ücretinin brüt asgari ücretin 3 (İFM/bölge | ilgili | 5 | 5 | 0 | 0 | 0 |
| GVK m.22/4 (yurt dışı kâr payı yarı istisnası) | 27/12/2023-7491/8 md. | — | ilgili | 20 | 0 | 0 | 0 | 0 |
| GVK m.94 kâr payı stopajı oranı (BKK 2009/14592 m.1/6-a) | CK 4936 (22/12/2021) ve CK 9286 (22/12/2024) — cetvelde m.94 | %15 | ilgili | 43 | 28 | 0 | 0 | 0 |
| GVK m.89/1-13 (hizmet ihracatı indirimi) | 27/12/2023-7491/10 md. | Beyanname tarihine kadar tamamı Türkiye'ye transfer şartıyla %80 | ilgili | 3 | 3 | 0 | 0 | 0 |
| GVK m.41/1-11 ve 41/1-12 | 8/4/2022-7394/1 (11: 5651 ek 4 reklam yasağı olanlara verile | Bu giderler kanunen kabul edilmez | ilgili | 5 | 5 | 0 | 0 | 0 |
| GVK m.66/6 (hekimler serbest meslek erbabı sayılır) | 8/4/2022-7394/2 md. | 5510 ek 10 kapsamında 4/1-b sigortalı sayılan hekimler ve uzman hekimler bu işleri nedeniyle serbest meslek erbabı | ilgili | 13 | 13 | 0 | 0 | 0 |
| GVK m.94/1-19, 1-20 ve 7491/7524 yetki paragrafları | 28/7/2024-7524/4 (19-20); 27/12/2023-7491/11 | E-ticaret aracı hizmet sağlayıcı ödemelerinden ve CB'nin belirlediği sektör alımlarından tevkifat (%25 üst sınırlı) | ilgili | 8 | 8 | 0 | 0 | 0 |
| GVK m.113 (taksi hasılat esaslı kazanç) ve gec.m.94 (ticari plaka) | 24/6/2026-7587/5, 6 md. | Taksi mali cihazla tespit edenler de talep ederse %10 hasılat esaslı (en fazla 3 yıl); ticari plaka elden çıkarma kazancı istisnası | ilgili | 125 | 125 | 0 | 0 | 0 |
| GVK mük.m.120 (geçici vergi) ve m.117 (taksit) | 14/10/2021-7338/8, 9 md.; cetvelde ayrıca "74, Mükerrer Madd | Ambar metni: üçer aylık dönem, izleyen ikinci ayın 14'ü beyan/17'si ödeme; yıllık GV Mart ve Temmuz iki taksit | ilgili | 7 | 7 | 0 | 0 | 0 |
| GVK gec.m.67, 68, 72, 76, 78, 82, 92, 93; m.40/10 ve m.89/6 (Darülaceze ibaresi); m.41/1 (7578) | 7338, 7420, 7491, 7566, 7578, AYM 12/2/2026 (gec.m.75) | — | kapsam dışı | 0 | 0 | 0 | 0 | 0 |

Ölçülmedi (GVK + GV GT 332): mük.m.20 tutar değişikliğini yapan kanunun numarası: gec.m.5 cetvelinde satır/sütunlar karışık; yayım 12/3/2023 ve 1/1/2023 yürürlük okunuyor, kanun no (7440?) kesin okunamadı. · mük.m.120 geçici vergi: 7338 ve cetveldeki 1/1/2025 değişikliğinin içeriği ambar metninden çıkarılamadı (dipnotlar başka kayda düşmüş, "altışar→üçer" notu çelişkili). 4. dönem geçici vergi beyannamesinden söz eden 5 fmuh · m.117 (7338) eski metni ambarda yok; ne değiştiği yazılamadı (bankada taksit iddiası taşıyan aday 0). · m.17 (7524, pay senedi ile sağlanan menfaat istisnası) ve m.69 (7524) metinleri ambar kaydında yok/kesik (yalnız başlık var); desen kurulmadı, pay senedi ifadesiyle arama 0 aday. · m.64, 110, 118, 122 metinleri ambarda yok; mülga oldukları GT 319 m.2/2'den alındı. · Cetvelde 7566 ile "74" (m.74) değişikliği görünüyor; m.74 kaydında not yok — içerik ölçülmedi. · GVK m.22/4: 10.10 taraması mevcut olduğundan yeniden okunmadı (20 aday listelendi, gvk-sonuc1.json gvk22_kar_payi_yurtdisi). · Kâr payı stopajı: 43 adayın yalnız tarih/oran iddiası taşıyan 28'i okundu; hepsi %15 ve 22.12.2024 ile tutarlı. · m.21/2 yorum hatası değişiklikle ilgisiz; bankanın tamamında ayrıca taranmadı, yalnız m.21 adayları (48) içinde görüldü.

### KVK · KDVK · ÖTV

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| KVK m.5/1-e (taşınmaz satış kazancı istisnası) + geç. m.16 | 14/7/2023-7456/19 ve 22 md. | 15/7/2023'ten sonra iktisap edilen taşınmazlar için istisna yok; öncesinde aktifte olanların 15/7/2023 sonrası satışında oran %25 (geç. m.16 | ilgili | 46 | 46 | 0 | 0 | 2 |
| KVK m.32/1 (genel oran %25, banka/finans %30) + geç. m.13 | 15/4/2021-7316 (geç.13: 2021 %25, 2022 %23); 8/4/2022-7394/2 | Genel %25; bankalar, 6361 şirketleri, ödeme/e-para, sigorta/emeklilik, YİD/KÖİ şirketleri %30 | ilgili | 37 | 37 | 0 | 0 | 0 |
| KVK m.32/7 (ihracat indirimi) ve m.32/8 (üretim kazancı) | 19/1/2022-7351/15 (ekleme); 14/7/2023-7456/21 (7. fıkra '1 p | İhracat kazancı 5 puan indirimli (aracılı ihracat dahil). Üretim kazancına %12,5 — ancak 2027 ve sonrası kazançlara. | ilgili | 7 | 7 | 0 | 0 | 2 |
| KVK m.32/C yurt içi asgari kurumlar vergisi (%10) ve ek m.1-13 küresel asgari vergi (%15) | 28/7/2024-7524/36-49 md.; 21/5/2026-7582/9 (32/C-2-d IFM ind | KV, indirim/istisna öncesi kazancın %10'undan az olamaz; düşülebilecekler 32/C-2'de sayılı (5/1-a,ç,i,j,k; taşınmaz kazancı hariç d; 10/1-g, | ilgili | 84 | 84 | 0 | 0 | 0 |
| KVK m.5/1-b yurt dışı iştirak kazancı (%50 pay → %50 istisna) | 27/12/2023-7491/58 (ek paragraf) | Ayrıca: ≥%50 pay + beyan süresine kadar transfer şartıyla diğer şartlar aranmaksızın %50 istisna | ilgili | 22 | 22 | 0 | 0 | 1 |
| KVK m.5/1-a (fon katılma payları: 7394 ekleme, 7456 mülga/değişik son cümle, 7524 ek) ve m.5/1-d (GYO/GYF %50 dağıtım şartı, 7524) | 8/4/2022-7394/22; 14/7/2023-7456/19; 28/7/2024-7524/32 | Yatırım ortaklığı/fon kâr payları, (d) istisnasından yararlanamayan fon/ortaklıklardan elde edilenler hariç, istisnadan yararlanamaz; GYO/GY | ilgili | 79 | 79 | 0 | 0 | 0 |
| KVK m.5/3 (istisna kazanca ilişkin gider/zarar; iştirak finansman gideri) | 9/3/2023-7440/20 md. | İstisna kazanç giderleri/istisna faaliyet zararları indirilemez; iştirak hissesi alım finansman giderleri (devir sonrası dahil) indirilebili | ilgili | 2 | 2 | 0 | 0 | 0 |
| KVK m.6/3 (TTK 376 sermaye tamamlama tutarları) | 8/4/2022-7394/23 | TTK 376 uyarınca zararı kapatacak miktarda ortaklarca aktarılan tutar kurum kazancında dikkate alınmaz. | ilgili | 23 | 23 | 0 | 0 | 0 |
| KVK m.10/1-ı (nakdi sermaye artışı faiz indirimi), 10/1-ğ (hizmet ihracatı %50→%80), 10/1-i (yurt dışı alım-satım %95, 7421/7582), 10/1-j (nitelikli hizmet merkezi, 7582), 10/1-f (Darülaceze, 7578) | 14/10/2021-7338/59; 1/7/2022-7417/49; 16/11/2022-7421/20; 27 | 10/1-ğ: transfer şartıyla %80; 10/1-ı: yurt dışından nakitte %75, karar dönemi + izleyen 4 dönem; 10/1-i/j: %95 (IFM/endüstri bölgesi %100); | ilgili | 80 | 80 | 0 | 0 | 0 |
| KVK m.11/1-j ve k (KKEG: reklam yasağı olanlara reklam; şans/bahis reklamı) | 8/4/2022-7394/24; 2/4/2026-7577/11 | Bu reklam giderleri indirilemez. | ilgili | 215 | 215 | 0 | 0 | 0 |
| KVK m.15/1-h,ı ve m.30/1-e,f (e-ticaret aracı ödemeleri ve CB'nin belirlediği mal/hizmet alımlarında kesinti); m.15/4, m.30/8 yetki | 28/7/2024-7524/33-34; 27/12/2023-7491/60-61 | Kesinti kapsamına girdi (oran CB). | ilgili | 9 | 9 | 0 | 0 | 0 |
| KVK m.32/A indirimli kurumlar vergisi (%60, en fazla 10 dönem) ve 32/A-8 diğer vergilerden terkin | 14/10/2021-7338/60; 20/7/2025-7555/18 | Yeni belgelerde KV oranı %60 indirimli, ilk dönem dahil en fazla 10 dönem; kazanç varken kullanılmayan katkı tutarı sonra dikkate alınmaz | ilgili | 10 | 10 | 0 | 0 | 0 |
| KVK m.32/B sermaye azaltımında vergileme | 3/11/2022-7420/22 | 5 tam yıl kuralı ve I/II/III sınıf sıralaması. | ilgili | 21 | 21 | 0 | 0 | 0 |
| KVK m.4/1-p muafiyet (İhracatçı kefalet kurumları + Katılım Finans Kefalet A.Ş.) | 4/11/2021-7341/12; 7491/57 | Bu kefalet kurumları KV'den muaf. | kapsam dışı | 1 | 1 | 0 | 0 | 0 |
| KVK geçici m.14, 15, 17, 18, 19, 20 (KKM, varlık barışı 2022 ve 2026, küresel vergi geçiş, UEFA, nükleer örtülü sermaye) | 7352, 7407, 7417, 7524, 7566, 7582, 7590 | Geçici teşvik/yapılandırma/af hükümleri | kapsam dışı | 0 | 0 | 0 | 0 | 0 |
| KDVK m.17/4-r (kurumların taşınmaz satış istisnası) + geç. m.43 | 14/7/2023-7456/8 (m.17/4-r'den taşınmaz çıkarıldı; geç.43) | Yalnız iştirak hisseleri istisna; 15/7/2023 öncesi aktifte olan taşınmazlara eski hüküm (geç.43) | ilgili | 2 | 2 | 0 | 0 | 0 |
| KDVK m.29/1-ç (sorumlu sıfatıyla beyan edilip ödenen KDV indirimi) | 27/12/2023-7491/30 md. | Vergi kesintisi yapmakla sorumlu tutulanların sorumlu sıfatıyla beyan edip ödediği KDV indirilebilir vergiler arasında sayıldı. | ilgili | 8 | 8 | 1 | 0 | 0 |
| KDVK m.41/1 ve m.46/1 (sorumluların beyan 21., ödeme 23. gün) | 27/12/2023-7491/32 (dipnot 99) ve m.46 değişikliği | Mükellef: 24. gün beyan, 26. gün ödeme; sorumlu: 21. gün beyan, 23. gün ödeme (kanun metni) | ilgili | 2 | 2 | 0 | 0 | 0 |
| KDVK m.13/i (yurt dışında yaşayanlara konut/işyeri teslimi: elden çıkarma süresi) | 8/4/2022-7394/10 ('bir yıl'→'üç yıl') | Üç yıl | ilgili | 6 | 6 | 0 | 0 | 0 |
| KDVK diğer: m.13/b (yat/tekne hariç, 7524), m.13/f (kurum adları, 7349/7394), m.13/o (savunma taşıtları, 7555), m.17/2-a,b (7577/7578), m.17/4-a (geç.94, 7587), m.17/4-c (VUK zamanaşımı bağımsız inceleme, 7524), m.17/4-ğ (kamulaştırma, 7577), m.21/ç (7555), m.29/3 (boru hattı ithali, 7440), m.36 (iade-inceleme raporu, 7524; AYM iptali 9/9/2026), m.30 (2030), geç. m.33/32 süre uzatımları | 7349, 7394, 7440, 7491, 7524, 7555, 7577, 7578, 7587 | Bkz. metin | ilgili | 25 | 25 | 0 | 0 | 0 |
| KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi | Süre sonu: madde metni '31/12/2023 tarihine kadar uygulanmak | 2024 ve sonrası için uygulanmaz (metinde süre 31/12/2023) | ilgili | 3 | 3 | 3 | 0 | 1 |
| ÖTV m.7/2 (engelli araç istisnası: yerli katkı, on yılda bir, bedel sınırı yeniden düzenleme) | 25/12/2024-7537/12 (yerli katkı %20; 'beş'→'on'); AYM 22/4/2 | On yılda bir; yerli katkı en az %20 (CBK 9321 ile %40); 2-c'de bedeli 2.873.900 TL'yi aşanlar hariç | ilgili | 85 | 85 | 0 | 0 | 0 |
| ÖTV m.12 (yetki/maktu tutarlar: (I) liste ÜFE güncellemesi 7456; 87.03 yetkileri 7338/7555/7590; tütün %20 ibaresi 7524), m.3 (III liste komisyoncu/konsinye, 7316), m.13 (makaron, 7423) | 7316, 7338, 7423, 7456, 7524, 7555, 7590 | Bkz. metin | ilgili | 98 | 98 | 0 | 0 | 0 |
| Bilinen ve kapıda olanlar: KDV %18 (EK1), KV %20 (EK7), KDV 291 bekletme (EK21), zayi ATİK KDV (EK14) | — | — | kapsam dışı | 2 | 2 | 0 | 0 | 0 |

Ölçülmedi (KVK · KDVK · ÖTV): KVK m.32/8'in 7582 öncesi metni ambarda yok: 2026 kazançlarına uygulanacak üretim indirimi rakamı ambardan doğrulanamadı (yalnız %12,5'in 2027+ olduğu yürürlük tablosundan kesin). · KVK m.32/C'nin ilk uygulama yılı: yürürlük tablosunda satır '32, 32/B 2025 yılı ve izleyen' biçiminde; 32/C açıkça yazmıyor. · KDVK geç. m.30'un 31/12/2023 süresini koyan değişikliğin tarihi/kanunu ambarda görünmüyor (yalnız mevcut metin). · KDVK m.17/4-r'den çıkarılan eski metin (dipnot 60-62) ambara düşmemiş. · KDVK m.36 AYM iptali (22/7/2025, yürürlük 9/9/2026) hangi cümleye ilişkin — ambarda iptal metni yok. · Muhasebe kapanış (fmuh) sorularında asgari kurumlar vergisi her soru için ayrıca yeniden hesaplanmadı; kökler okundu, bağlayıcı görünen yok. · KVK geçici 14/15/19 (KKM, varlık barışı) için banka taraması bu turda koşulmadı. · kvkgut.json / kdvgut.json okunmadı (kanun metni yeterli görüldü).

### 6183 · DVK · Harç · VİVK · Emlak · MTV · yıllık hadler

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| AATUHK m.51 (gecikme zammı oranı) | 10556 sayılı Cumhurbaşkanı Kararı (RG 13/11/2025, 33076); ön | m.51 metni "%4 (%3,7)": 10556 sayılı CK ile her ay için ayrı ayrı %3,7 (dipnot 26, m.53 kaydına düşmüş). | ilgili | 91 | 91 | 2 | 0 | 3 |
| AATUHK m.48/1 (tecil süresi) ve m.48/2 (teminatsız tecil sınırı) | 21/5/2026-7582/1 md.; 11414 sayılı CK (RG 13/6/2026, 33279) | Tecil süresi 72 ayı geçemez; sınır kanunda bir milyon TL, CK 11414 ile on milyon TL uygulanıyor (dipnot 21). Sınırı aşan kısmın yarısı temin | ilgili | 59 | 59 | 1 | 0 | 0 |
| AATUHK m.10/2 (teminat türleri) | 1/7/2022-7417/24 md. | Bankaların süresiz ve şartsız teminat mektupları ile sigorta şirketlerinin süresiz ve şartsız kefalet senetleri. | ilgili | 21 | 21 | 0 | 0 | 0 |
| AATUHK m.85/2, m.86, m.90, m.97, m.97/A (elektronik satış, menkulde %5 teminat, ihaleden vazgeçme) | 15/4/2021-7316/1-5 md. | Menkul ve gayrimenkul elektronik ortamda açık artırmayla satılabilir; menkulde biçilen değerin %5 i teminat alınır; malı almaktan vazgeçen a | ilgili | 54 | 54 | 0 | 0 | 0 |
| AATUHK m.78 (elektronik haciz zaptı) | 27/12/2023-7491/4 md. (ek cümle) | Haciz zaptı elektronik ortamda düzenlenebilir; usul ve esasları HMB belirler. | ilgili | 5 | 5 | 0 | 0 | 0 |
| AATUHK m.22/A/1 (borcu yoktur yazısı / kesinti; mahkeme ve icra ödemeleri dahil) | 28/7/2024-7524/1 md. | "her türlü ödemelerde (mahkeme kararları ve icra dairelerinin ödeme veya icra emirleri üzerine yapılacak ödemeler dâhil)" | ilgili | 11 | 11 | 0 | 0 | 0 |
| AATUHK m.28/1 (bağışlama sayılan tasarruf, bent 1) | AYM 22/6/2023, E.2022/134 K.2023/116 (bent iptali) | Bent 1 iptal edildi; bent 2 (pek aşağı fiyat) ve bent 3 (kaydı hayat şartıyla irat/intifa) yürürlükte. | ilgili | 18 | 18 | 0 | 0 | 0 |
| AATUHK m.58 (ödeme emrine itiraz, iptal edilen fıkra) | AYM 21/4/2022, E.2021/119 K.2022/48 (fıkra iptali) | Metinde "(İptal fıkra ...)" notu var; 15 gün itiraz süresi, 7 gün karar süresi, kararların kesinliği ve ret sonrası 15 gün mal bildirimi kur | ilgili | 32 | 32 | 0 | 0 | 0 |
| AATUHK m.118 / işlenemeyen gec. m.8 (31/12/2028) | 27/12/2023-7491/5 md. | "31/12/2028" | kapsam dışı | 0 | 0 | 0 | 0 | 0 |
| DVK m.14/1 azami tutar (yıllık) | Damga Vergisi GT 71 (RG 31/12/2025, 33124 5. Mük.) | 2026: 29.115.961,10 TL (GT71 m.3/4) | ilgili | 15 | 15 | 0 | 0 | 2 |
| DVK (2) sayılı tablo IV-34 — ücretlerde damga istisnası (aylık brüt asgari ücrete isabet eden kısım) | 22/12/2021-7349/4 md. | GVK 23/18 kapsamındaki ücretlerde damga istisnası aylık brüt asgari ücrete isabet eden kısım için uygulanır; damga yalnız aşan kısma binde 7 | ilgili | 35 | 35 | 3 | 0 | 0 |
| DVK (2) sayılı tablo — diğer 2021+ istisna eklemeleri (IV-36 teminat yöneticisi, IV-55 kamu idarelerine bağış kâğıtları, IV-56 nükleer santral kâğıtları) ve DVK m.11'e düşen 'yatırım izleme ve koordinasyon başkanlıkları' eklemesi; ek m.2 (7491); gec. m.4/m.5 (TOKİ) | 14/10/2021-7338/53-54 md.; 27/12/2023-7491/20 md.; 9/3/2023- | Kamu idarelerine yapılan bağışlara ilişkin kâğıtlar, nükleer santral yatırımı kâğıtları ve teminat yöneticisinin taraf olduğu teminat kâğıtl | kapsam dışı | 8 | 8 | 0 | 0 | 0 |
| DVK (1) sayılı tablo I-B-2 ihale kararları (AYM iptal cümlesi) ve iptal hâlinde ret/iade (7491/21) | AYM 13/12/2022, E.2022/125 K.2022/162 (cümle iptali); 27/12/ | Şikâyet ya da yargı kararıyla ihale iptal edilirse ihale kararı ve ihaleye ilişkin sözleşmenin yararlanılmayan kısmına isabet eden damga ver | ilgili | 0 | 0 | 0 | 0 | 0 |
| Harçlar K. (4) sayılı tarife I-20/a tapu harcı matrahı | 4/12/2025-7566/8 md. | 'emlak vergisi değerinden az olmamak üzere beyan edilen devir ve iktisap bedeli' üzerinden, devir eden ve devir alan için ayrı ayrı binde 20 | ilgili | 208 | 208 | 0 | 0 | 0 |
| Harçlar K. diğer 2021+ değişiklikleri (m.13/m.59 nüfus düzeltmesi 7491; m.29/A ve m.36 AYM iptalleri; m.132 ek fıkra 7327; 1 sayılı tarife 7343 (İİK 134); gemi/sörvey 7334-7491; 7 ve 8 sayılı tarife 7491-7496-7566 'her yıl için' ve yeni ruhsat harçları; 2026 maktu tutarları GT 98) | 7327 (9/6/2021), 7334 (18/7/2021), 7343 (24/11/2021), 7440 ( | Tarifeler metne 1/1/2026 tutarlarıyla işlenmiş (GT 98). | kapsam dışı | 5 | 5 | 0 | 0 | 0 |
| VİVK m.16 tarife dilimleri ve m.4 istisna tutarları (yıllık) | VİVK GT 57 (RG 31/12/2025, 33124 5. Mük.) | 2026: istisna 2.907.136 TL; eş (çocuk yoksa) 5.817.845 TL; ivazsız ve yarışma 66.935 TL. Dilimler 3.000.000 / 7.000.000 / 15.000.000 / 30.00 | ilgili | 33 | 33 | 0 | 0 | 0 |
| VİVK m.16 yeni fıkra — GVK mük. 20/D kapsamındakilerin veraset intikalinde %1 oran | 21/5/2026-7582/2 md. | GVK mük. 20/D istisnasından yararlananların istisna süresi içinde veraset yoluyla mal intikalinde vergi oranı %1. | ilgili | 5 | 5 | 0 | 0 | 0 |
| Emlak V.K. m.29 (vergi değerinin yıllık artışı) ve m.30/8 (tapu devrinde emlak vergisi borcu sorgusu), gec. m.23, gec. m.25 | 4/12/2025-7566/10-11 md.; 9/6/2021-7327/14-15 md. | Vergi değeri her yıl 'yeniden değerleme oranında' artırılır; CB yalnız sıfıra kadar indirebilir. Emlak vergisi borcu olan bina ve arazinin d | ilgili | 87 | 87 | 0 | 0 | 0 |
| MTV K. m.4/a (istisna listesine yatırım izleme ve koordinasyon başkanlıkları) ve 2026 tarifeleri (CK 10783, GT 58) | 4/12/2025-7566/4 md.; CK 10783 (RG 31/12/2025) | YİKOB adına kayıtlı taşıtlar istisna; tarifeler 2026 için güncellendi. | kapsam dışı | 30 | 30 | 0 | 0 | 0 |
| VUK m.177 bilanço esası defter tutma hadleri (yıllık) | VUK GT 588 (2026) | 2026 (GT588 eki): yıllık alış 2.500.000 · satış 3.500.000 · gayrisafi iş hasılatı 1.200.000 · iş hasılatının beş katı + satış toplamı 2.500. | ilgili | 108 | 108 | 1 | 0 | 3 |
| VUK m.313 doğrudan gider yazma haddi (yıllık) | VUK GT 588 | 2026: 12.000 TL (GT588 eki) | ilgili | 117 | 117 | 0 | 0 | 1 |
| VUK m.232 fatura düzenleme sınırı (yıllık) | VUK GT 588 | 2026: 12.000 TL (GT588 eki) | ilgili | 7 | 7 | 0 | 0 | 0 |
| VUK m.323 şüpheli alacak haddi (yıllık) | VUK GT 588 | 2026: 25.000 TL (GT588 eki) | ilgili | 51 | 51 | 0 | 0 | 1 |

Ölçülmedi (6183 · DVK · Harç · VİVK · Emlak · MTV · yıllık hadler): AATUHK m.51: gecikme zammının önceki CK oranları (CK 7782, 8484 ve 2019 öncesi) ambarda oran metni olarak yok; yalnız cetvelde numara ve tarih var. Bankadaki %2,5 / %3,5 / %4,5 izlerinin hangi döneme ait olduğu kaynaktan · AATUHK m.58: AYM 21/4/2022 kararıyla iptal edilen fıkranın içeriği ambarda yok; bu içeriğe göre yazılmış soru taranamadı ('haksız çık/%10 zam' araması 0 ilgili sonuç verdi, ama içerik doğrulanmadı). · AATUHK m.28/1: iptal edilen bendin metni ambarda yok; 'akraba/eş/usul-füru' araması yapıldı, ilgili soru çıkmadı. · DVK (1) sayılı tablo: AYM 13/12/2022 kararıyla iptal edilen cümlenin içeriği ambarda yok. Ayrıca damgagt66-70 eklerindeki maktu tarife tutarları (bilanço, beyanname vb.) ambarda yok; yalnız 2026 tutarları kanun metnine i · DVK 2023 azami tutarı GT66-67 dışında; 2021 (GT65?) azami tutarı ambar dosyalarında okunmadı. · VUK GT 544 (2023 hadleri) ek listesi ayrıştırılamadı; 2023 değerleri (177/232/313/323) eski değer taramasında kullanılmadı. · Bordro soruları (sgs-t2-fmuh-zor/kp-57, sgs-t2-fmuh-cokzor/kp-62, smmm-w4-fmuh-zor/kp-11): asgari ücret gelir vergisi istisnası (GVK 23/18) da uygulanmamış; bu GVK grubunun konusu. 2026 brüt asgari ücret tutarı bu grubun · Harçlar: 208 adayda yalnız desen geçen alanlar okundu; maktu harç tablolarının eski yıl tutarları ambarda yok (yalnız 2026 tutarları işlenmiş). · EK8 (teminatsız tecil 10.000.000) kapısının sgs-t2-vergi-cokzor/kp-15'i yakalayıp yakalamadığı ölçülmedi (kapı kodu okunmadı; brif salt okuma).

### TTK · TBK · TMK · İİK · Çek · TCK · Tüketici · Kabahat

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| TTK m.332/1 (A.Ş. en az esas sermaye + kayıtlı sermayeli halka açık olmayan A.Ş. başlangıç sermayesi) | 24/11/2023 tarihli 7887 sayılı Cumhurbaşkanı Kararı (RG 25/1 | 7887 s. CBK (ttk.json m.334 kaydındaki 42 no.lu dipnot + elle-yutmalar CBK metni): A.Ş. en az esas sermaye 250.000 TL; kayıtlı sermayeli hal | ilgili | 75 | 75 | 0 | 0 | 1 |
| TTK m.580 (Ltd. en az esas sermaye) | 7887 sayılı CB Kararı md.1/2 (TTK m.580/2 yetkisi) | 7887 s. CBK md.1/2: Ltd. en az esas sermaye 50.000 TL. | ilgili | 4 | 4 | 0 | 0 | 0 |
| TTK gec. m.15 (asgari sermayeye uyum: 31/12/2026) | 23/5/2024-7511/17 md. (Ek) | Sermayesi en az tutarın altındaki A.Ş./Ltd. 31/12/2026'ya kadar m.332/m.580 tutarlarına yükseltmezse infisah etmiş sayılır; çıkarılmış serma | ilgili | 12 | 12 | 0 | 0 | 0 |
| TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı) | 28/3/2023-7445/30 md. (Ek cümle) | m.4/2: 'miktar veya değeri bir milyon Türk lirasını geçmeyen ticari davalarda basit yargılama usulü uygulanır' + ek cümle: 'Bu fıkrada belir | ilgili | 20 | 20 | 1 | 0 | 7 |
| TTK m.375/1-d (YK devredilemez görev: müdür atama) | 23/5/2024-7511/14 md. (Değişik bent) | d) Şube müdürleri hariç olmak üzere müdürlerin ve aynı işleve sahip kişilerin atanmaları ve görevden alınmaları. | ilgili | 25 | 25 | 0 | 0 | 0 |
| TTK m.392/7 (YK'nın toplantıya çağrılması) | 23/5/2024-7511/15 md. (Ek cümleler) | Çağrıyı başkan yapar; üyelerin çoğunluğunun yazılı istemi üzerine başkan en geç otuz gün içinde toplantıya çağırmak zorunda; çağrılmazsa/ula | ilgili | 13 | 13 | 0 | 0 | 0 |
| TTK m.82/7 (zıyaa uğrayan defter/belge için mahkemeden belge isteme süresi) | 1/7/2022-7417/55 md. | Afet/hırsızlık sebebiyle saklama süresi içinde zıyaa uğrayan defter ve belgeler için tacir zıyaı öğrendiği tarihten itibaren otuz gün içinde | ilgili | 4 | 4 | 0 | 0 | 0 |
| TTK m.40/2 (imzaların sicile kaydı) | 28/1/2021-7263/22 md. | İmzaya yetkili kişilerin imzaları kamu veri tabanlarından elektronik ortamda temin edilip sicil dosyasına kaydedilir; kayıt yoksa imza beyan | ilgili | 9 | 9 | 0 | 0 | 0 |
| TTK m.373/3 (kamu kurumları sicil kaydı dışında belge isteyemez) | 28/1/2021-7263/23 md. (Ek) | Kamu kurumları temsile yetkili kişiler için sicil kayıtlarını esas alır; sicil belgeleri ve TTSG ilanı dışında belge isteyemez. | ilgili | 3 | 3 | 0 | 0 | 0 |
| TTK m.88/6 (KGK'nın TSRS yetkisi) | 2/6/2022-7408/9 md. (Ek) | KGK, belirlediği işletmeler için Türkiye Sürdürülebilirlik Raporlama Standartlarını belirlemeye ve yayımlamaya yetkili. | ilgili | 24 | 24 | 0 | 0 | 0 |
| TTK m.397/6 (kooperatifler ibaresi çıkarıldı) | 21/10/2021-7339/23 md. | Beşinci fıkra kapsamında denetime tabi olduğu hâlde denetim yaptırmayanların finansal tabloları ve faaliyet raporu düzenlenmemiş hükmündedir | ilgili | 1 | 1 | 0 | 0 | 0 |
| TTK idari para cezaları (m.33/2, m.38, m.51/2, m.562) 2026 tutarları | 17/12/2025 tarihli Ticaret Bakanlığı Tebliği (RG 33110) — 20 | 2026: m.33/2 22.194 TL; m.38/1 ve m.51/2 44.443 TL; m.562/1-2 88.997 TL; m.562/13-a 173.801 TL. | ilgili | 9 | 9 | 0 | 0 | 0 |
| TTK gec. m.7/15 (ihya; 7511 ek cümle + AYM iptali) | 23/5/2024-7511/16 md. (Ek cümle) — AYM 10/9/2025, E.2025/31  | 15. fıkrada iptal edilen cümleler yerine boşluk; ihya davası hükmü kalan cümlelerle duruyor. | ilgili | 2 | 2 | 0 | 0 | 0 |
| TTK m.1000, m.1259, m.1352 (deniz ticareti: ilan internet haber sitesi, zorunlu sigorta sınırı) | 13/10/2022-7418/28; 4/7/2024-7519/20 | ilanlara internet haber sitesi eklendi; yolcu taşıyan zorunlu sigorta sınırı değişti | kapsam dışı | 0 | 0 | 0 | 0 | 0 |
| TTK gec. m.14 (hamiline pay senetlerinin bildirimi, 31/12/2021) | 7262/34 (2020) — süre 31/12/2021 | Hamiline yazılı pay senedi sahipleri 31/12/2021'e kadar MKK'ya bildirilmek üzere şirkete başvurur. | kapsam dışı | 1 | 1 | 0 | 0 | 0 |
| TBK m.55 (2 ek fıkra: kanuni faizin başlangıcı; ifa amaçlı ödemelerin oransal mahsubu) | 16/7/2026-7589/18 md. | Çalışma gücü kaybı ve destekten yoksun kalmada: kazancın bilindiği döneme ilişkin tazminata haksız fiil/olay tarihinden, bilinemediği döneme | ilgili | 46 | 46 | 0 | 0 | 0 |
| TBK gec. m.1 ve gec. m.2 (konut kirası artışında %25 sınırı) | 8/6/2022-7409/4; 14/7/2023-7456/23 | Belirtilen dönemlerde yenilenen konut kiralarında artış %25 ile sınırlı (TÜFE ortalaması daha düşükse o). Sürelerin ikisi de 1/7/2024'te bit | kapsam dışı | 4 | 4 | 0 | 0 | 0 |
| 5941 Çek K. gec. m.3/5 (düzenleme tarihinden önce ibraz geçersiz — TTK m.795/2'nin askıda kalması) | Süre uzatmaları: 7341 (yür. 6/11/2021), 7491 (yür. 28/12/202 | Çek K. gec. m.3/5: 31/12/2028 tarihine kadar, üzerinde yazılı düzenleme tarihinden önce çekin ödenmek için muhatap bankaya ibrazı geçersizdi | ilgili | 30 | 30 | 1 | 1 | 2 |
| 5941 Çek K. gec. m.5 (30/4/2021'e kadar işlenen karşılıksız çek suçlarında infazın durdurulması, taksitle ödeme) | 18/7/2021-7333/17 md. | 30/4/2021'e kadar işlenen suçta infaz durdurulur; 30/6/2022'ye kadar ödenmeyen kısmın onda biri, kalanı ikişer ay arayla on beş eşit taksit. | kapsam dışı | 49 | 49 | 0 | 0 | 0 |
| Bağımsız denetime tabi olma eşikleri (CB Kararı 6434, 3/1-b-3 ve 3/1-b-2) | 16/3/2026 tarihli 11066 s. CBK (RG 17/3/2026-33199) — (b)(3) | Genel (diğer) şirketler: aktif 500 milyon TL, net satış 1 milyar TL, çalışan 150 — üç ölçütten ikisini art arda iki hesap döneminde aşan; (I | ilgili | 7 | 7 | 0 | 0 | 0 |
| TMK aile/vesayet değişiklikleri: m.27/2 (ad değişikliği ilanı — 7532), m.166/4 (red kararından sonra boşanma — 7532), m.182/2 ve m.324/3 (kişisel ilişki — 7343), m.286 ve m.291 (soybağının reddi; ana da dava açabilir — 7531), m.314 (evlat edinme nüfus kaydı — 7531), m.407/409/436/471 (hapis nedeniyle kısıtlama: 'toplam beş yıl' — 7499), m.440 (vesayette elektronik satış portalı — 7589, yür. 31/10/2026), m.187 (AYM iptali — kadının soyadı) | 7343 (24/11/2021), 7499 (2/3/2024), 7531 (7/11/2024), 7532 ( | Okunan güncel metinler: m.27/2 BİK ilan portalında ilan; m.166/4 red kararının kesinleşmesinden itibaren bir yıl ortak hayat kurulamazsa boş | kapsam dışı | 41 | 41 | 0 | 0 | 0 |
| TMK m.733 ve m.734 (önalım: Devlet İhale K. satışlarında kullanılamaz; rayiç bedelin hâkimce belirlenmesi ve depo) + gec. m.1 | 24/12/2025-7571/35-37 md. | m.733/1: 2886 s. Devlet İhale K. kapsamındaki satışlar ve cebrî artırmada önalım kullanılamaz; hak, bildirimden itibaren üç ay ve her hâlde  | ilgili | 2 | 2 | 0 | 0 | 0 |
| İİK m.278 (ivazsız tasarrufların iptali: aciz belgesi/iflastan önceki bir yıl; bağışlama sayılan işlemler) | 24/12/2025-7571/2 md. (madde baştan değişik) | Alışılmış hediyeler dışında, geçici/kesin aciz belgesi veya aciz niteliğindeki haciz tutanağı ya da iflasın açılmasından önceki BİR YIL için | ilgili | 6 | 6 | 0 | 0 | 0 |
| İİK kanun yolu/süre değişiklikleri: 'on gün' → 'iki hafta' (m.166, 183, 294, 308, 323 vd.), m.353 ve m.364 'yedi/on gün' → 'iki hafta'; m.19 (hafta süreleri) | 2/3/2024-7499/1, 3 ve 37 md. | İcra mahkemesi kararlarına karşı kanun yolu süreleri iki hafta; m.19: hafta olarak belirlenen süre son haftada başladığı güne karşılık gelen | ilgili | 40 | 40 | 0 | 0 | 0 |
| İİK diğer 2021–2026 değişiklikleri (m.1, 3/a, 6, 15, 36, 38, 79/a konutta haciz, 82/3 ev eşyası, 83, 85, 87, 88, 88/a, 97, 110, 111, 111/a rızai satış, 111/b elektronik satış, 114, 115, 124, 125, 128, 129, 133, 134 ihalenin feshi, 135, 138, 143, 168, 223, 241, 242, 249, 295–298, 308, 309, 341, ek m.1–2, gec. m.17–20) | 7327 (9/6/2021), 7343 (24/11/2021), 7418 (13/10/2022), 7445  | Okunan örnekler: m.79/a konutta haciz icra mahkemesi onayına bağlı; m.82/1-3 ev eşyasının tamamı haczedilemez; m.111/b haczedilen mal elektr | kapsam dışı | 105 | 105 | 0 | 0 | 0 |
| Kabahatler K. m.17/6 (ödeme süresi bir ay, peşin ödemede %25 indirim; ödeme kanun yolunu etkilemez) | 1/7/2022-7417/46 md. | Kanunlarında ödeme süresi düzenlenmemiş idari para cezaları tebliğden itibaren bir ay içinde ödenir; süresinde ödemede %25 indirim; ödeme ka | ilgili | 6 | 6 | 0 | 0 | 0 |
| Kabahatler K. m.43/C (amaç dışı bıçak taşıma — yeni), m.42/A (7547), m.43/A (AYM iptali), m.28–29 (7499) | 8/8/2026-7593/8; 8/5/2025-7547/13; AYM 18/1/2024; 2/3/2024-7 | Yeni kabahat tipleri / usul. | kapsam dışı | 4 | 4 | 0 | 0 | 0 |
| TCK değişiklikleri (m.31/4, 57, 62, 73, 75, 82, 86, 87, 94, 106, 113, 123/A, 151, 155/3, 158/4, 170, 191, 217/A, 220, 233, 238, 314) | 7331, 7332 (2021); 7406, 7413, 7418 (2022); 7445 (2023); 749 | Okunan: m.155/3 (7571) — güveni kötüye kullanmada konu motorlu kara/deniz/hava taşıtı ise ceza bir kat artırılır; m.155/1-2 cezaları değişme | kapsam dışı | 55 | 55 | 0 | 0 | 0 |
| 6502 Tüketici K. değişiklikleri (m.24, 29, 44, 47/A, 48, 50, 57/A, 58, 59, 63, 66, 68, 70, 77, 77/A, 78, gec. m.3) | 7392 (24/3/2022), 7511 (23/5/2024), 7529 (24/10/2024), 7587  | (tek tek okunmadı — bankada konu yok) | kapsam dışı | 8 | 8 | 0 | 0 | 0 |

Ölçülmedi (TTK · TBK · TMK · İİK · Çek · TCK · Tüketici · Kabahat): TTK m.580'in 83 ve 84 no.lu dipnot metinleri ttk.json'da YOK (m.581–m.587 ve tüm dosya tarandı; yalnız 85/86 m.585'te). Ltd. tutarı (50.000 TL) elle-yutmalar-20260827.json'daki 7887 s. CBK metninden okundu. · TTK m.4/2: 45 no.lu dipnot metni ambarda yok → 'bir milyon' tutarının 7445 ile mi konduğu ÖLÇÜLMEDİ; 2024–2026 güncel parasal sınırın resmî ilanı ambarda yok. Ambardaki yeniden değerleme oranlarıyla hesap ≈2.859.000 TL ( · TTK gec. m.15/3: Ticaret Bakanlığının 31/12/2026 süresini uzatıp uzatmadığı ambarda yok — ÖLÇÜLMEDİ (uzatılırsa '31/12/2026' yazan ~12 soru güncellenmeli). · Çek K. gec. m.3/5'in önceki bitiş tarihleri (dipnot 12–15) ambarda yok; eski tarih izi ('31/12/202x' + çek + ibraz) bankada 0 aday. · TTK gec. m.7/15'te AYM'nin 10/9/2025 tarihli kararıyla iptal edilen cümlelerin metni ambarda yok — ihya süresine dair soru içeriği karşılaştırılamadı (2 aday DOGRU sayıldı). · Bağımsız denetim eşiklerinin 11066 ve 9774 öncesi değerleri ambarda yok (bdkarar6434 yalnız işlenmiş güncel metin). · TMK, İİK, Tüketici, TCK değişikliklerinde eski fıkra metinleri ambarda yok; bankada konu bulunmadığından madde madde eski/yeni karşılaştırması yapılmadı (yalnız bankada geçen maddeler okundu). · Tüketici K. değişiklik maddeleri tek tek okunmadı (bankada konu 0) — kapsam dışı satırı arama sayısına dayanıyor.

### 5510 · 4857 · 4447 · 6331 · 6356 · asgari ücret

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| 5510 m.41/1 son cumle - hizmet borclanmasi prim orani | 4/12/2025-7566 (yururluk tablosu: 7566 -> m.41, 1/1/2026) | Gunluk kazancin '(a) bendinde bulunanlar icin %32'si, digerleri icin %45'i'; (i) bendi (kismi sureli) icin GSS primi odenmisse %39. Metinde  | ilgili | 20 | 20 | 8 | 0 | 3 |
| 5510 m.17/1 - odeneklere esas gunluk kazanc | 25/12/2024-7537/25 md. (Degisik birinci fikra) | Odeneklerde gunluk kazanc: olay/is goremezlik tarihinden onceki ON IKI aydaki prime esas kazanclar toplami / bu kazanclara esas prim gun say | ilgili | 1 | 1 | 1 | 0 | 0 |
| 5510 m.81/1-(ı) - Hazinece karsilanan isveren hissesi indirimi + gec. m.108 (imalat) | 9/1/2025-7538/17 md. (gec. m.108; yururluk tablosu: 7538 ->  | Ozel sektor isverenine MYO isveren hissesinin IKI puani Hazinece karsilanir; imalat sektorunde gec. m.108 ile BES puan, 31/12/2026'ya kadar  | ilgili | 34 | 34 | 0 | 0 | 1 |
| 5510 m.81/1-a MYO prim orani (+ m.52, ek m.5, ek m.6, ek m.9 toplam oranlari) | 4/12/2025-7566 (yururluk tablosu: 7566 -> m.52, 81, ek m.5,  | MYO %21 (sigortali %9, isveren %12); kisa vade %2,25 isveren; GSS %12,5 (5/7,5). Isteğe bagli %33 (21+12); ek m.5 %35,5; ek m.6 ve ek m.9 %3 | ilgili | 74 | 74 | 0 | 0 | 0 |
| 5510 m.82/1 - prime esas kazanc ust siniri | 4/12/2025-7566/24 md. (asgariucret2026.json notu; yururluk t | 16 yasindan buyukler icin alt sinirin 9 kati (2026: aylik taban 33.030 TL, tavan 297.270 TL). | ilgili | 28 | 28 | 0 | 0 | 0 |
| 5510 m.15/2, m.18/1-c; 4857 m.74, ek m.2 - analik suresi ve es dogumu izni | 22/4/2026-7578/15, 18 md. (yururluk tablolari: 5510 m.15, 18 | Analik: dogumdan once 8 + sonra 16 = 24 hafta (cogul gebelikte dogum oncesine +2 hafta; ucretsiz izin 24/26 haftadan sonra 6 aya kadar). Esi | ilgili | 95 | 95 | 0 | 0 | 0 |
| 4447 m.49 - issizlik sigortasi Devlet payi | 2/4/2026-7577/5 md. (CB'ye yarisina kadar artirma/indirme ye | Devlet payi %0,5 (11258 sayili CBK). Sigortali %1, isveren %2 degismedi. | ilgili | 31 | 31 | 0 | 0 | 0 |
| 5510 gec. m.95 - 8/9/1999 oncesi sigortalilarda yas sarti kaldirildi (EYT) | 1/3/2023-7438/1 md. (ikinci fikra 28/7/2024-7524/30 ile mulg | Bu kapsamdakiler yas disindaki sartlari tasirsa yaslilik/emekli ayligina hak kazanir; geriye donuk odeme yok. | ilgili | 74 | 74 | 0 | 0 | 0 |
| Asgari ucret 2026 (4857 m.39 / ATK karari 2025/1) | Asgari Ucret Tespit Komisyonu karari, RG 26/12/2025-33119 | Gunluk 1.101 TL, aylik brut 33.030 TL (1/1-31/12/2026). | ilgili | 44 | 44 | 0 | 0 | 0 |
| 1475 m.14 kidem tazminati tavani | 2021-2026 arasi kanun degisikligi yok (1475 yururluk listesi | Tavan = en yuksek Devlet memuruna 5434'e gore bir hizmet yili icin odenecek emeklilik ikramiyesi; TL tutari ambarda yok. | kapsam dışı | 9 | 9 | 0 | 0 | 0 |
| 4857 m.46/1 - turizm konaklama tesislerinde hafta tatili 4 gun icinde kullandirma | 10/7/2025-7553/9 md. (ek cumleler) | Turizm isletmesi belgeli konaklama tesislerinde iscinin yazili talep/onayiyla hak kazanilan gunu izleyen 4 gun icinde kullandirilabilir; o g | ilgili | 17 | 17 | 0 | 0 | 0 |
| 4857 m.109 - yazili veya elektronik (KEP) bildirim | 20/7/2025-7555/23 md. (basligi ile birlikte degisik) | Bildirimler yazili ve imza karsiliginda veya iscinin yazili kabulu sartiyla KEP ile; fesih sonucu doguran bildirimler her halde yazili; KEP  | ilgili | 25 | 25 | 0 | 0 | 0 |
| 4857 m.108 - idari para cezasini verecek makam | 10/7/2025-7553/10 md. (degisik) | Cezalar gerekceli olarak Calisma ve Is Kurumu il mudurunce; birden fazla ilde isyeri olanlara 101 ve 106 icin merkezin bulundugu il mudurunc | ilgili | 6 | 6 | 0 | 0 | 0 |
| 4447 ek m.2 - kisa calisma odenegi sartlari ve mahsup | 25/1/2024-7495/1 md. (degisik ve ek cumleler) | Son 120 gun hizmet akdi + son 3 yilda en az 450 gun prim; odeme her ayin 5'inde; odenen sureler 3 yil icindeki fesihlerde issizlik odenegi s | ilgili | 5 | 5 | 0 | 0 | 0 |
| 6331 m.3 (tanimlar), m.6/1-a ve (5), m.24/2 mulga, m.24/A, ek m.1 (Konsey) | 9/1/2025-7538/18-19; 25/1/2024-7495/8-9; 18/6/2025-7551/19 ( | Tanimlara CASMER ve ekipman muayene kurulusu eklendi, egitim kurumu ve diger saglik personeli tanimi degisti; isveren ISG hizmetini OSGB vey | ilgili | 5 | 5 | 0 | 0 | 0 |
| 5510 m.80/1-b - prime esas kazanca tabi olmayan odemeler (BES/OSS %30, yemek bedeli 300 TL) | 2/4/2026-7577/10 md. (degisik (b) bendi) | 9 kalem istisna; isverenin OSS/BES odemesi aylik toplam asgari ucretin %30'una kadar; yemek verilmeyen hallerde calisilan gun basina 300 TL' | ilgili | 0 | 0 | 0 | 0 | 0 |
| 5510 m.89 gecikme cezasi orani | 12/3/2024 tarihli 8256 sayili CBK (dipnot 170) | Ilk uc ay icin her ay %3 (kanuni oran). | ilgili | 4 | 4 | 0 | 0 | 0 |
| 5510 m.60/7 ve son fikra, m.63/1-g, m.67/1-d, m.68/2 (GSS: yabanci ogrenciler, klinik arastirma, ogrenci GSS primi, katilim payi tutar artisi) | 9/1/2025-7538/6-9 md.; 18/2/2021-7281/37 (m.63 bildirim); 10 | Yabanci ogrenci GSS egitim ogretim yili basindan; burslu uluslararasi ogrenciler GSS'li (prim alt sinirin %4'u); ogrenci GSS primleri tescil | kapsam dışı | 40 | 40 | 0 | 0 | 0 |
| 5510 ek m.18, ek m.19 (bayram ikramiyesi 4.000 TL, en dusuk aylik 23.552 TL) | Yillik kanunlar; ek m.19 icin 10/7/2025-7553/13 ('14.469' -> | En dusuk aylik 23.552 TL; bayram ikramiyesi 4.000'er TL. | kapsam dışı | 6 | 6 | 0 | 0 | 0 |
| Kapsam disi toplu satir: 5510 m.43, m.46 (%45 borclanma), m.99 (yurt disi basvuru), ek m.7, ek m.17, ek m.20 (AYM iptali), ek m.21-23, ek m.24 (%25 kesinti), gec. m.2, 4, 6, 10, gec. m.84-112 (yillik asgari ucret destekleri, yapilandirma, terkin, deprem); 4447 gec. m.10 (sure uzatimi), gec. m.22-36; 4857 gec. m.12; 6356 (2021-2026 degisikligi yok) | 2021-2026 cesitli (7281...7590) | Ust duzey kamu gorevlisi aylik/prim hukumleri, 5434 gecis hukumleri, gecici tesvik/destek/yapilandirma maddeleri. | kapsam dışı | 101 | 0 | 0 | 0 | 0 |

Ölçülmedi (5510 · 4857 · 4447 · 6331 · 6356 · asgari ücret): 5510 m.41: 7566 madde metni ve m.41 dipnot 65-67 ambarda kesik; '(a) bendinde bulunanlar' ibaresinin m.41/1-(a) mi 4/1-(a) mi oldugu ve er/erbas icin ozel oran olup olmadigi metin disi kaynakla (7566 gerekcesi / SGK gene · 5510 m.81/1-a %20 -> %21 gecisi ve m.81/1-(ı) bes -> dort gecisi: dipnot 141 ve 'bes->dort' dipnotu kesik; yalniz yururluk tablosu ile guncel metin okundu. · 5510 m.82 7,5 -> 9 kat: 5510 dipnot 156 kesik; dayanak asgariucret2026.json notu + yururluk tablosu. · Kidem tazminati tavani TL tutari ambarda yok: 2026 tarihli 'gecerli tavan 42.000 / 43.700 / 41.830 / 48.190 TL' diyen sorular (sgs-p-fmuh-cokzor-r3/kp-09, smmm-w7-1-fmuh-zor/kp-08, smmm-w3-fmuh-zor/kp-14, sgs-d2-fmuh-cok · 2025 asgari ucret tutari (26.005,50 / 22.104,67) ambarda yok; bankadaki kullanim varsayim ibareli oldugu icin siniflamayi etkilemedi. · 4857 m.74, ek m.2, m.108, m.109; 4447 ek m.2; 6331 m.3/m.6/m.24 eski metinleri ambarda yok (dipnotlar kesik). · 4447 ve 6331 yururluk tablolari okunmadi (yururluk tarihleri ÖLÇÜLMEDİ). · Kapsam disi toplu satirdaki 101 sendika/TIS adayi tek tek okunmadi (6356'da 2021-2026 degisikligi bulunmadigi icin).

### 3568 + yönetmelikler · 6362 · MÖHUK

| Madde | Değiştiren | Eski → yeni (kısa) | İlgi | Aday | Okunan | Yanlış | İki cevap | Açıklama eski |
|---|---|---|---|---|---|---|---|---|
| 3568 m.48 (ek fıkra: ruhsat kullandırma / başka meslek mensubunun ad-unvanıyla beyanname → meslekten çıkarma) | 27/3/2025-7546/4 md. | Meslek ruhsatnamesini başkasına bedelli/bedelsiz kullandıran ile başka meslek mensubunun ad ve unvanıyla beyanname düzenleyen/imzalayan/gönd | ilgili | 70 | 70 | 0 | 0 | 0 |
| 3568 m.48 son fıkra (disiplin cezasının uygulanma anı) | 27/3/2025-7546/4 md. (Değişik fıkra) | Disiplin cezaları, cezanın kesinleştiğinin meslek mensubuna bildirilmesinden sonra uygulanır. (Disiplin Yön. m.12, RG-7/10/2023: tebliğ tari | ilgili | 45 | 45 | 0 | 0 | 0 |
| 3568 m.20/4 (Oda genel kurulu ilanı) | 27/3/2025-7546/2 md. (Değişik dördüncü fıkra); Odalar Yön. m | Toplantı yeri/günü/saati/gündemi ve ikinci toplantı bilgisi, ilk toplantıdan en az 10 gün öncesinden toplantı tarihine kadar yayımda kalacak | ilgili | 40 | 40 | 0 | 0 | 0 |
| 3568 m.34/3 (Birlik genel kurulu ilanı) | 27/3/2025-7546/3 md. (Değişik üçüncü fıkra) | İlk toplantıdan en az yirmi gün önce tirajı yüzbinin üzerinde bir gazetede ilan ve toplantı tarihine kadar Birlik resmi internet sitesinde d | ilgili | 0 | 0 | 0 | 0 | 0 |
| 3568 m.10 ('Maliye Bakanlığının uygun görüşü alınmak suretiyle' ibaresi — YMM sınav yönetmeliği) ve m.50 (yönetmeliklerin Bakanlık uygun görüşüyle yayımı) | AYM 12/2/2026 E.2026/25 K.2026/25 (m.10, yürürlük 23/6/2026) | İlgili ibareler iptal (m.10 dipnot 8; m.50 dipnot 27 gec. m.2 kaydına düşmüş). m.50 için 2023 iptalinin tam kapsamı (dipnot 26) ambarda YOK. | ilgili | 26 | 26 | 0 | 0 | 0 |
| Disiplin Yön. m.6/a ve m.7/a (tekerrür: 'üçüncü kez' ibaresi) | RG-7/10/2023-32332 (Ek ibare) | Üç yıllık dönem içinde ÜÇÜNCÜ KEZ uyarma gerektiren eylem → kınama; üçüncü kez kınama gerektiren → geçici alıkoyma (m.11: ilk iki ceza kesin | ilgili | 26 | 26 | 0 | 0 | 0 |
| Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i) | Danıştay 8. Daire 11/2/2022 E.2018/4865 K.2022/792 (iptal al | Alt bent (2) iptal; m.16/b'de yalnız 'Yıllık üye aidatları maktu ve nispi olarak iki şekilde tespit olunur' cümlesi ve maktu aidat (200–400  | ilgili | 17 | 17 | 0 | 2 | 6 |
| SMMM Staj Yön. m.9/d (yabancı dil 3 ay, tezli YL 1 yıl, tezsiz/uzaktan YL 6 ay, doktora 18 ay; bir arada yararlanma yasağı) | RG-24/2/2025-32823 (Değişik alt bent 1-2, mülga ibare) | Birlik akrediteli yabancı dil programının 3 ayı; ilgili alanlarda tezli yüksek lisansın 1 yılı, tezsiz/uzaktan yüksek lisansın 6 ayı (bu hak | ilgili | 51 | 51 | 0 | 0 | 0 |
| SMMM Staj Yön. m.5/d (tezkiye 80 altı dönem staj geçersiz), m.27 (tezkiye süresi ≥3 ay, 1 ayda teslim, olumsuz tezkiye raporu), m.7 (SGS: ilk sınav ilanından 3 yıl tüm sınavlar), m.18 (TESMER yedi üye), m.19 (staja ilk on günde başlama), m.17, m.28 | RG-24/2/2025-32823 | m.5/d: tezkiye notu 80 altı dönem stajı geçersiz, eksik süre tamamlatılır; m.27: tezkiye üç aydan az olmamak üzere yönergedeki süre için, dö | ilgili | 18 | 18 | 0 | 0 | 0 |
| YMM ve SMMM Sınav Yön. m.9 (staj değerlendirme notu en az 80), m.20 (itiraz 7 gün, elektronik, 30 günde karar), m.21 (SMMM sınavı: ilk sınavdan 2 yıl, yılda 3 kez; gec. m.2), m.22 (belgeler 5 yıl), m.5/c, m.11, m.12, m.15, m.17 | RG-24/2/2025-32823 | m.9: sınava girmek için staj değerlendirme notu 100 üzerinden en az 80; m.20: sonuç ilanından itibaren 7 gün içinde elektronik itiraz, 30 gü | ilgili | 17 | 17 | 0 | 0 | 0 |
| Çalışma Usul ve Esasları Yön. m.43 (Ltd müdürlüğü, AŞ YK üyeliği/başkanlığı yasak; AŞ bağımsız YK üyeliği ticari faaliyet sayılmaz) ve m.44 (hizmet akdi) | RG-14/1/2026-33137 (Değişik cümle, ek fıkra; m.44 değişik) | Meslek mensupları Ltd. şirkette müdürlük, AŞ'de YK üyeliği ve başkanlığı yapamaz; AŞ'de bağımsız YK üyeliği ticari faaliyet sayılmaz ama o ş | ilgili | 39 | 39 | 0 | 0 | 0 |
| Çalışma Usul ve Esasları Yön. m.14 (açılış/kapanış ve adres bildirimi 30 gün, irtibat bürosu yasağı, şube sorumlusu ortağın ikameti, ev-ofis/paylaşımlı ofis yetkisi), m.30/b (ortaklık bürosu yalnız aynı unvan), m.30 ek fıkralar, m.15/e, m.36, m.63/A | RG-24/2/2025-32823 ve RG-14/1/2026-33137 | m.14: işyeri açılış/kapanış ve adres değişikliği 30 gün içinde odaya; irtibat bürosu açılamaz; şube sorumlusu ortak şube ilinde ikamet eder; | ilgili | 9 | 9 | 0 | 0 | 0 |
| Disiplin Yön. diğer 2023/2026 değişiklikleri: m.7 ek fıkra (VUK 153/A iştiraki → 3 yıl alıkoyma), m.11 (bir derece ağır/hafif; uyarma hafifletilemez), m.12 (uygulama tebliği izleyen gün; RG ilanı mülga ibare 2026), m.14 (soruşturma zamanaşımı 5 yıl), m.20-21 (3 ay bildirim, 30 gün itiraz), m.28, m.30, m.34 | RG-7/10/2023-32332 ve RG-14/1/2026-33137 | Madde metinleri ambardaki güncel hal. | ilgili | 0 | 0 | 0 | 0 | 0 |
| 6362 m.3/1 (aa) cüzdan, (bb) kripto varlık, (cc) kripto varlık hizmet sağlayıcı, (çç) saklama hizmeti, (dd) platform, (ee) TÜBİTAK tanımları | 26/6/2024-7518/1 md. | Kripto varlık, cüzdan, platform, saklama hizmeti, kripto varlık hizmet sağlayıcı (platformlar + saklama kuruluşları + Kurulca belirlenen diğ | ilgili | 44 | 44 | 0 | 0 | 0 |
| 6362 m.35/B, 35/C, 99/A, 99/B, 109/A, 110/A, 110/B, 115/A, 130/5, gec. m.11 (kripto hizmet sağlayıcı izni, faaliyet esasları, tedbir/denetim, izinsiz faaliyet, zimmet, özel soruşturma, platform gelir payı) | 26/6/2024-7518/3,4,8,9,12,13,14,15,16,17 md. | Kripto varlık hizmet sağlayıcılar Kurul izniyle kurulur; kripto varlıklar m.82 yatırımcı tazmini ve 5411 m.63 sigortası dışında; m.109/A: iz | ilgili | 23 | 23 | 0 | 0 | 0 |
| 6362 m.13, m.46/7-8, m.74/1, m.99/3, m.101/3, m.103 (ek cümle, 9. fıkra) | 26/6/2024-7518/2,5,7,10,11 md. (m.74 yalnız m.151 listesinde | m.46/7-8: müşteri nakitleri bankalarda münferit hesaplarda, kuruluşun kendi nakdinden ayrı izlenir; m.74/1: kitle fonlama platformları ve kr | ilgili | 25 | 25 | 0 | 0 | 0 |
| 6362 m.83/4 (YTM'ye emaneten devir, 10 yıl; pay hakları donar) | 15/4/2021-7316/12 md. | Her türlü emanet ve alacak, en son talep/işlem/yazılı talimattan başlayarak on yıl içinde talep ve tahsil edilmezse YTM'ye emaneten devredil | ilgili | 6 | 6 | 0 | 0 | 0 |
| MÖHUK (5718) m.27/1 ve /4 (iş sözleşmelerinde hukuk seçimi) | 4/6/2025-7550/18 md. | İş sözleşmeleri, mutad işyeri hukukunun emredici hükümlerindeki asgari koruma saklı kalmak üzere tarafların seçtiği hukuka tabidir; işin yap | kapsam dışı | 3 | 3 | 0 | 0 | 0 |
| SM, SMMM ve YMM Ücretlerinin Esasları Hakkında Yönetmelik | 2021–2026 değişiklik notu YOK (ambar metninde bulunmadı) | - | kapsam dışı | 2 | 2 | 0 | 0 | 0 |

Ölçülmedi (3568 + yönetmelikler · 6362 · MÖHUK): 3628 Mal Bildirimi Kanunu: ambarda dosyası YOK — grup tanımındaki mohuk.json aslında MÖHUK (5718). 3628 değişiklikleri okunamadı. Bankada 'Mal Bildirim|3628|Rüşvet ve Yolsuzluklarla' 20 eşleşme, hepsi 6183/İİK mal bildir · 3568 m.50 AYM 16/2/2023 E.2022/142 iptalinin kapsamı (dipnot 26 metni ambarda yok) ÖLÇÜLMEDİ; bankada Bakanlık uygun görüşü desenine 3568 adayı çıkmadı. · Odalar Yön. m.16/b-2 Danıştay iptalinin kesinleşip kesinleşmediği ambarda yazmıyor (m.30 için İDDK onaması yazıyor, m.16 için yazmıyor). Nispi aidat bulguları mevzuat.gov.tr metnindeki 'iptal alt bent' ibaresine dayanır. · Yönetmelik değişikliklerinin (2023/2025/2026) eski metinleri ambarda yok; eski değerler (eski staj notu, eski sınav hakkı süresi, eski itiraz süresi vb.) yazılmadı. Tarama, güncel değerden sapan sayılar ve 'üçüncü kez' g · EK20 (6362 bankalar m.35 dışında) ve EK22 (kitle fonlama m.35/1 sayımı) kapıda olduğu için yeniden taranmadı. · Disiplin Yön. m.12 'Resmî Gazete'de (Mülga ibare: RG-14/1/2026)' — silinen ibare ambarda yok; RG ilanı deseni 6 aday verdi, hepsi güncel metinle uyumlu. · m.48 ruhsat satırının DOGRU/KAPSAM_DISI ayrımı hit penceresi üzerinden mekanik yapıldı (70 adayın hepsinin bağlamı okundu; eski kural öğreten yok).

### Kapı banka koşusunda çıkan ek bulgular (okuyucu listesinde yoktu, elle okundu)

| Madde | Yanlış | Açıklama eski |
|---|---|---|
| KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi | 1 | 0 |
| VUK m.320/3 (gün esaslı amortisman) | 0 | 3 |
| VUK m.261/9 | 0 | 4 |
| GVK m.32 (asgari geçim indirimi) | 0 | 1 |
| GVK m.103 tarife (2026 dilimleri) | 0 | 1 |
| VUK m.177 hadleri | 0 | 1 |

## Bulgulu soru kimlikleri (soru metni yok)

**Anahtar yanlış (40)**

- `sgs-p-borclar-cokzor-r1-b2/kp-03` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-p-borclar-cokzor-r2/kp-04` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-t1-issgk-cokzor/kp-07` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-t2-fmuh-cokzor/kp-62` — DVK (2) sayılı tablo IV-34 — ücretlerde damga istisnası (aylık brüt asgari ücrete isabet eden kısım)
- `sgs-t2-fmuh-zor/kp-57` — DVK (2) sayılı tablo IV-34 — ücretlerde damga istisnası (aylık brüt asgari ücrete isabet eden kısım)
- `sgs-t2-vergi-cokzor/kp-15` — AATUHK m.48/1 (tecil süresi) ve m.48/2 (teminatsız tecil sınırı)
- `sgs-t2-vergi-cokzor/kp-17` — VUK m.177 bilanço esası defter tutma hadleri (yıllık)
- `sgs-t5-ticaret-cokzor/kp-11` — 5941 Çek K. gec. m.3/5 (düzenleme tarihinden önce ibraz geçersiz — TTK m.795/2'nin askıda kalması)
- `smmm-4k-a-fmuh-zor-r2-2/kp-03` — VUK m.328 dördüncü-beşinci fıkra (satış kârı / yenileme) ve m.329 (sigorta tazminatı)
- `smmm-4k-a-yhukuk-zor-r6/kp-20` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-4k-a-yvergi-kolay-r1/kp-12` — GVK m.21 (mesken kira istisnası tutarı)
- `smmm-4k-a-yvergi-kolay-r2/kp-01` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-4k-a-yvergi-zor-r1/kp-14` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-4k-a-yvergi-zor-r5/kp-01` — GVK m.21/2 yorum hatası (değişiklik DEĞİL — okuma sırasında görüldü)
- `smmm-4k-a-yvergi-zor-r5/kp-14` — VUK ek m.1 (ikinci fıkra ek cümle) + m.376/1-1
- `smmm-4k-a-yvergi-zor-r5/kp-16` — GVK m.40/1, 40/7, 68/4-5 (binek otomobil tutarları)
- `smmm-4k-a-yvergi-zor-r8/kp-02` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-dog1-vergi/kp-12` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-dog1-vergi/kp-13` — KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi
- `smmm-dog1-vergi/kp-51` — KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi
- `smmm-gm2-1-fmuh-cokzor/kp-01` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-olc2-a-vergi/kp-01` — GVK m.21 (mesken kira istisnası tutarı)
- `smmm-olc2-b-vergi/kp-04` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-olc2-b-vergi/kp-66` — GVK m.21 (mesken kira istisnası tutarı)
- `smmm-olc2-b-vergi/kp-69` — AATUHK m.51 (gecikme zammı oranı)
- `smmm-w1-yhukuk-zor/kp-04` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `smmm-w1-yhukuk-zor/kp-14` — 5510 m.17/1 - odeneklere esas gunluk kazanc
- `smmm-w1-yvergi-zor/kp-16` — GVK m.86/1-c ve 1-d (beyan sınırları)
- `smmm-w14-6-yvergi-zor/kp-01` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-w2-yhukuk-zor/kp-04` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `smmm-w3-yhukuk-cokzor/kp-15` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `smmm-w3-yhukuk-zor/kp-15` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `smmm-w3-yvergi-cokzor/kp-05` — KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi
- `smmm-w3-yvergi-zor/kp-27` — VUK m.328 dördüncü-beşinci fıkra (satış kârı / yenileme) ve m.329 (sigorta tazminatı)
- `smmm-w3-yvergi-zor/kp-29` — KDVK m.29/1-ç (sorumlu sıfatıyla beyan edilip ödenen KDV indirimi)
- `smmm-w4-fmuh-zor/kp-11` — DVK (2) sayılı tablo IV-34 — ücretlerde damga istisnası (aylık brüt asgari ücrete isabet eden kısım)
- `smmm-w5-fmuh-zor/kp-18` — AATUHK m.51 (gecikme zammı oranı)
- `smmm-w5-yhukuk-cokzor/kp-01` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `smmm-w6-yvergi-kolay/kp-02` — GVK m.103 tarife (2026 dilimleri)
- `smmm-w6-yvergi-zor/kp-04` — VUK ek m.1 (ikinci fıkra ek cümle) + m.376/1-1

**İki cevaplı (5)**

- `sgs-d2-ticaret-zor-r2/kp-04` — 5941 Çek K. gec. m.3/5 (düzenleme tarihinden önce ibraz geçersiz — TTK m.795/2'nin askıda kalması)
- `sgs-e16d-vergi-zor/kp-01` — GVK m.32 (asgari geçim indirimi)
- `sgs-t2-fmuh-cokzor/kp-18` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
- `smmm-4k-a-ymeslek-kolay-r5/kp-05` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-zor-r7/kp-01` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)

**Cevap doğru, açıklama eski (78)**

- `sgs-bc-ticaret-zor-r3/kp-01` — 5941 Çek K. gec. m.3/5 (düzenleme tarihinden önce ibraz geçersiz — TTK m.795/2'nin askıda kalması)
- `sgs-c5-maliye-cokzor-r1/kp-09` — GVK m.103 tarife (2026 dilimleri)
- `sgs-c5-vergi-cokzor-r1/kp-07` — KDVK geç. m.30 (büyük yatırımlarda inşaat KDV iadesi) — uygulama süresi
- `sgs-d2-borclar-zor-r1/kp-06` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-d2-vergi-kolay-r3/kp-01` — DVK m.14/1 azami tutar (yıllık)
- `sgs-e16c-vergi-kolay/kp-02` — GVK m.32 (asgari geçim indirimi)
- `sgs-e16d-vergi-kolay/kp-01` — GVK m.32 (asgari geçim indirimi)
- `sgs-fmuh-k10c/kp-01` — VUK m.320/3 (gün esaslı amortisman)
- `sgs-p-borclar-cokzor-r1/kp-04` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-p-borclar-cokzor-r2-b2/kp-03` — 5510 m.41/1 son cumle - hizmet borclanmasi prim orani
- `sgs-p-fmuh-cokzor-r1/kp-23` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `sgs-p-fmuh-cokzor-r2/kp-14` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `sgs-p-fmuh-cokzor-r3/kp-22` — VUK m.320/3 (gün esaslı amortisman)
- `sgs-p-ticaret-kolay-r3-b2/kp-06` — TTK m.332/1 (A.Ş. en az esas sermaye + kayıtlı sermayeli halka açık olmayan A.Ş. başlangıç sermayesi)
- `sgs-p-vergi-cokzor-r3-a/kp-01` — VUK m.261/9
- `sgs-p-vergi-kolay-r2/kp-01` — DVK m.14/1 azami tutar (yıllık)
- `sgs-p-vergi-zor-r2-a/kp-07` — KVK m.5/1-b yurt dışı iştirak kazancı (%50 pay → %50 istisna)
- `sgs-t1-fmuh-cokzor-b/kp-151` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
- `sgs-t1-fmuh-cokzor-b/kp-158` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `sgs-t1-fmuh-cokzor/kp-65` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
- `sgs-t1-fmuh-kolay/kp-85` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `sgs-t1-ticaret-zor/kp-33` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `sgs-t2-fmuh-zor/kp-85` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
- `sgs-t2-ticaret-zor/kp-05` — 5941 Çek K. gec. m.3/5 (düzenleme tarihinden önce ibraz geçersiz — TTK m.795/2'nin askıda kalması)
- `sgs-t4-maliye-zor/kp-07` — GVK m.32 (asgari geçim indirimi)
- `sgs-t4-vergi-cokzor/kp-19` — GVK mük.m.20/A (basit usul kazanç istisnası), m.46/1 3. cümle mülga, m.89/1-15 mülga
- `sgs-t4-vergi-kolay/kp-19` — GVK mük.m.20/A (basit usul kazanç istisnası), m.46/1 3. cümle mülga, m.89/1-15 mülga
- `sgs-vergi-p30/kp-01` — KVK m.5/1-e (taşınmaz satış kazancı istisnası) + geç. m.16
- `smmm-4k-a-yhukuk-zor-r3/kp-02` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-4k-a-yhukuk-zor-r7/kp-01` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-4k-a-yhukuk-zor-r9/kp-02` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-4k-a-ymeslek-kolay-r2/kp-03` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-kolay-r3-2/kp-06` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-kolay-r6/kp-03` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-kolay-r6/kp-23` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-zor-r2/kp-10` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-ymeslek-zor-r3/kp-02` — Odalar Yön. m.16/b-2 (nispi aidat: mesleki kazancın/kurum kazancı payının %1'i)
- `smmm-4k-a-yvergi-kolay-r1/kp-09` — VUK m.261/9
- `smmm-4k-a-yvergi-kolay-r3/kp-23` — VUK m.177 hadleri
- `smmm-4k-a-yvergi-kolay-r4/kp-09` — VUK m.261/9
- `smmm-4k-a-yvergi-kolay-r9/kp-05` — VUK m.261/9 (dokuzuncu değerleme ölçüsü: alış bedeli) + m.268/A
- `smmm-4k-a-yvergi-zor-r1/kp-20` — VUK m.177 bilanço esası defter tutma hadleri (yıllık)
- `smmm-4k-a-yvergi-zor-r2/kp-06` — AATUHK m.51 (gecikme zammı oranı)
- `smmm-4k-a-yvergi-zor-r2/kp-12` — VUK m.177 bilanço esası defter tutma hadleri (yıllık)
- `smmm-4k-a-yvergi-zor-r3/kp-01` — GVK m.103 tarife (2026 dilimleri)
- `smmm-4k-a-yvergi-zor-r3/kp-16` — GVK m.40/1, 40/7, 68/4-5 (binek otomobil tutarları)
- `smmm-4k-a-yvergi-zor-r5/kp-05` — VUK m.261/9
- `smmm-4k-a-yvergi-zor-r5/kp-08` — VUK m.177 bilanço esası defter tutma hadleri (yıllık)
- `smmm-4k-a-yvergi-zor-r7/kp-11` — GVK m.86/1-c ve 1-d (beyan sınırları)
- `smmm-4k-a-yvergi-zor-r8/kp-13` — GVK m.86/1-c ve 1-d (beyan sınırları)
- `smmm-dog1-vergi/kp-61` — VUK ek m.1, ek m.7, ek m.8, ek m.11 (uzlaşmada vergi aslı çıkarıldı)
- `smmm-gm2-1-fmuh-kolay/kp-01` — VUK m.313 doğrudan gider yazma haddi (yıllık)
- `smmm-gm3-2-fmuh-kolay/kp-01` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-gm4-12-fmuh-zor/kp-05` — VUK m.320/3 (gün esaslı amortisman)
- `smmm-gm5-18-fmuh-zor/kp-05` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-gm5-25-fmuh-zor/kp-08` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-gm7-1-yvergi-zor/kp-04` — GVK m.103 tarife (2026 dilimleri)
- `smmm-olc2-a-vergi/kp-04` — GVK m.21 (mesken kira istisnası tutarı)
- `smmm-olc2-a-vergi/kp-07` — KVK m.32/7 (ihracat indirimi) ve m.32/8 (üretim kazancı)
- `smmm-olc2-a-vergi/kp-41` — GVK m.21/2 yorum hatası (değişiklik DEĞİL — okuma sırasında görüldü)
- `smmm-olc2-b-vergi/kp-07` — KVK m.32/7 (ihracat indirimi) ve m.32/8 (üretim kazancı)
- `smmm-olc2-b-vergi/kp-54` — GVK mük.m.20 (genç girişimci istisnası tutarı)
- `smmm-w10-3-yvergi-kolay/kp-01` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-w11-2-fmuh-zor/kp-06` — 5510 m.81/1-(ı) - Hazinece karsilanan isveren hissesi indirimi + gec. m.108 (imalat)
- `smmm-w11-3-fmuh-zor/kp-14` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-w12a-4-yhukuk-zor/kp-07` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-w13-1-fmuh-kolay/kp-01` — VUK m.320/3, 320/4, 320/7 (gün esaslı amortisman, süre belirleme, vazgeçilemezlik); m.315 atfı; m.318 ek cümle
- `smmm-w13-3-fmuh-cokzor/kp-14` — VUK gec. m.37 (2025-2027 enflasyon düzeltmesi yapılmaz) + gec. m.33 ek fıkra/cümleler + mük. m.298/A-10
- `smmm-w13-4-fmuh-cokzor/kp-03` — VUK m.323 şüpheli alacak haddi (yıllık)
- `smmm-w14-5-yhukuk-zor/kp-04` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-w14-6-yvergi-zor/kp-02` — AATUHK m.51 (gecikme zammı oranı)
- `smmm-w3-yhukuk-zor/kp-10` — TTK m.4/2 (ticari davalarda basit yargılama parasal sınırı)
- `smmm-w3-yvergi-cokzor/kp-16` — AATUHK m.51 (gecikme zammı oranı)
- `smmm-w3-yvergi-zor/kp-31` — KVK m.5/1-e (taşınmaz satış kazancı istisnası) + geç. m.16
- `smmm-w4-fmuh-cokzor/kp-19` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
- `smmm-w5-fmuh-zor-2/kp-09` — VUK gec. m.37 (2025-2027 enflasyon düzeltmesi yapılmaz) + gec. m.33 ek fıkra/cümleler + mük. m.298/A-10
- `smmm-w5-yvergi-cokzor/kp-04` — GVK m.103 tarife (2026 dilimleri)
- `smmm-w9-3-fmuh-cokzor/kp-11` — VUK m.262/c (kredi faizi ve kur farkının maliyete zorunlu/serbest kısmı)
