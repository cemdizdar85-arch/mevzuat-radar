# DEVİR NOTU — 03.08.2026 gece · yeni sohbet buradan devam etsin

## Durum tek cümle
Onarım motoru **26 kuralla** donatıldı, **10 yayın kapısı + 8 hakem maddesi + 10 robot**
kuruldu; paralı tam parti hâlâ **Cem'in "bas"ını bekliyor.** Kasaya hiçbir şey yazılmadı,
site kapalı, bugün harcanan ~10,4 USD (üç pilot koşusu; 4.'sü gereksiz çıkıp iptal edildi).

## ⚠ TAM PARTİDE MUTLAKA OLACAK İKİ İŞ (Cem'in kararı — ATLAMA)
Bu ikisi ayrı parti olarak koşulmayacak, **tam partinin içinde** gelecek. Tam parti
tetiklenmeden önce bu satırlar okunacak:

**1. FORMÜL (1.616 soru) — Cem: "tam partiye bekleyecek."**
Cem "Aktif Devir Hızı ve Öz Kaynak Kaldıracı" sorusunda Kural'da genel/sembolik formül
olmadığını gösterdi ("Bu olayda"daki sayısal işlem tek başına öğretmiyor; öğrenci
`Aktif Devir Hızı = Net Satışlar / Toplam Aktifler`i görmezse sonraki soruyu kaybeder).
Kök sebep: D13-ek'in yöntem-adı regex'inde **"kaldıraç" yoktu**, kural hiç tetiklenmiyordu.
Listeye eklendi: kaldıraç · cari/likidite/asit test/karşılık/kârlılık oranı · stok-alacak
devir · borç oranı · öz kaynak oranı · değişim/artış/azalış/büyüme oranı · karşılaştırmalı
tablo. **Ölçüm (0 USD) yapıldı:** 27.478 sorunun 3.511'inde yöntem adı geçiyor, **1.616'sında
Kural'da formül izi yok**. %96'sı dört muhasebe dersinde (Fin. Tablolar ve Analizi 733 ·
Mali Tablolar Analizi 402 · Finansal Muhasebe 274 · Maliyet Muhasebesi 138); kalan 69 soru
Hukuk/Türkçe/Ekonomi gibi derslerde ve **muhtemelen sahte alarm** (Vergi Hukuku'nda
"reeskont" formülsüz geçebilir) — partiye sokmadan gözle ayıkla.
Ayrı koşsaydı ~19 USD ölçülmüştü; tam parti bu sorulara zaten dokunacağı için **ikinci kez
para ödememek adına** tam partiye bırakıldı. Liste: `veri/formul-eksik-taramasi.json`.

**2. TABLO FORMATI (Hesap | Borç | Alacak).**
İstem düzeltildi; kasada eski format tablo **0 çıktı** (2.426 tablodan hiçbiri "İşaret"
sütunlu değil) — yani geriye dönük iş YOK, yalnız yeni üretimler bu formatta gelecek.

## GECE BULUNAN KÜLTÜR HATASI (hesap kodu otomatik düzeltme neden 0 çıktı)
`pilot-0308-1550` sonucu: `hesap_kodu_duzeltilen=0`, `supheli=57`, `yanlis=61` — otomatik
düzeltme HİÇ çalışmamıştı. Sebep tek harf değil, İKİ KATMANLI kültür hatası:
1. `.ToUpperInvariant()` Türkçe **'ı'yı hiç büyütmüyor** (invariant kültürde eşleşiği yok).
2. Sunucunun sistem kültürü **tr-TR**; PowerShell'in `-replace`/`-match` operatörü kültüre
   duyarlı — **düz büyük 'I' bile `[A-Z]` aralığına girmiyor** (`'I' -match '[A-Z]'` → `False`).

Sonuç: `i`/`ı` geçen HER kelime (yani neredeyse her Türkçe hesap adı) harf temizleme
satırında parçalanıyordu ("Genel Üretim Giderleri" → `GENEL|URET|DERLER`, ÜRETİM kelimesi
kayboluyordu). Bu hem `hesap_kodu_duzeltilen`i hep 0'da tutuyordu (parçalanmış kelime
kırıntıları THP'de ya 0 ya da onlarca hesapla eşleşiyor, asla net "1 eşleşme" çıkmıyordu)
hem de `hesap_kodu_yanlis`ı **şişiriyordu** (10 örnekten 2'si — İştiraklerden Alacaklar,
Verilen Depozito ve Teminatlar — DOĞRU kod-ad iken eski kodla "yanlış" işaretleniyordu).

**DÜZELTİLDİ** ([onarim-motoru.ps1:403-427](motor/onarim-motoru.ps1)): ortak `AnlamliKelimeler`
fonksiyonu — `ToUpper(tr-TR kültürü)` + `[regex]::Replace(..., CultureInvariant)`. 3 kullanım
noktasına (KoduDuzelt, ResmiKodBul, K4 kapısı) bağlandı. Gerçek `msugt*.json` verisiyle 10
örnekte yerel test: eski kod 8 yanıltıcı-doğru + 2 yanlış-alarm veriyordu, yeni kod **10/10
doğru**. Kasaya/Supabase'e dokunulmadı, 0 USD.

**AMA İKİNCİ PİLOT (1650) YİNE 0 GİBİ ÇIKTI: `duzeltilen=1, supheli=59, yanlis=63`.**
Sebebi ikinci ve daha sinsi bir bug'dı — aşağıda.

## GECE BULUNAN İKİNCİ BUG: `ResmiKodBul` unwrap (ÇÖP VERİ ÜRETİYORDU)
Kendi yeni aracımın **ilk 10 örneğini gözle okurken** yakalandı (Cem'in kuralı çalıştı):
öneriler `kod 1`, `kod 2` diyordu. Sebep: PowerShell bir fonksiyon **tek elemanlı dizi**
döndürünce onu skaler string'e "unwrap" eder; `$aday[0]` o zaman dizinin ilk elemanını
değil **string'in ilk karakterini** verir (`"159"` → `"1"`).

Bu yüzden `hesap_kodu_duzeltilen` hep ~0 çıkıyordu **VE** 1650 pilotunda çıkan o tek
"düzeltme" **çöp veriydi** (`"1 "` yazılmış olmalı). Paralı tam partide kasaya çöp
yazacaktı. Düzeltme: çağrı noktasında `@()` ile sarmak — hem yeni araçta hem de
**asıl kaynakta** ([onarim-motoru.ps1 D14-ek, satır ~980](motor/onarim-motoru.ps1:980)).
**Ders: `$x = Fonksiyon` yerine `$x = @(Fonksiyon)` — dizi bekleyen her yerde.**

## Cem'in okuduğu dosya
Supabase Storage → özel kova `onarim-taslak` → en yeni `pilot-0308-*.html`
(⋯ → Get URL). Yanındaki `.json` ham dosyadır, okunmaz.

## BUGÜN CEM'İN BULDUĞU VE KURALA GİREN 17 KUSUR
D10 her şıkka ayrı düzeltme · D11 iyi olanı bozma · D12 anne testi + YZ kokusu yasağı ·
D13 rakamı tersine çöz · **D13-ek** yöntem tanımı + formül · **D13-ek/2** formül kuralı
dört parçadan bağımsız tetiklenir · D14 hesap kodu dayanaksız yazılamaz · **D14-ek**
kod-ad eşleşmesi üretim anında denetlenir · D15 kuralın sınırını çiz · D16 üretilen
alanın kaynağı istemde · **D16-ek** kaynak yanlış koşula bağlanamaz · D17 tekdüzelik
yasağı · D18 tahdidi liste tam (olumlu sorular dahil) · D19 terimi açıkla ·
D20 "Akılda kalsın" Kural ile çelişemez · D21 çıktı kesilirse tekrar iste ·
D22 senaryo tarihi yakın ama rakamla tutarlı · D23 kardeş kaynak · D24 muğlak ifade
yasak · D25 eskimiş kurum adı yasak · D26 güncel terim önde, kanun lafzı parantezde

## HER BULGU ÜÇ YERE GİDER (Cem'in kuralı)
**1. İstem** (yeni yazımlar) · **2. Kapı** (mevcut 27.478) · **3. Hakem** (anlam işi).
Biri eksikse iş yarım kalmıştır.

## ÖLÇÜLMÜŞ ENVANTER (kasa 27.478)
| Kusur | Kaç soruda |
|---|---|
| "Doğrusu:" yok | 27.457 |
| Eski terim (genel imal gideri…) | 3.884 |
| Hesap kodu kod-ad uyuşmuyor | ~3.075 |
| Sınır sorusu ama liste eksik | 703 |
| Kanun kopyası dili | 233 |
| Yapay zekâ kalıpları | 135 |
| Muğlak ifade | 43 |
| Eskimiş kurum adı | 8 |
| Yayında olan soru | **0** — hiçbir hata öğrenciye açık değil |

## KURULU ROBOTLAR (hepsi 0 USD)
- `yayin-kapisi.ps1` — 10 kapı, **tüm kasa** taranır, karar yayındakine bakar; günlük
- `hesap-kodu-denetimi.ps1` — THP'ye karşı kod-ad denetimi; haftalık
- `kaynak-butunluk.ps1` — **parçalı kaynağın tek parçasını okuyan kod var mı**; her push
- `terim-taramasi.ps1` — eski dil adaylarını tek listede çıkarır; haftalık
- `kardes-kaynak-cikar.ps1` — konu kümelerini kasadan ölçerek çıkarır; haftalık
- `sik-istatistigi.ps1` — "adayların %38'i C'yi seçti"; günlük
- `taslak-goster.ps1` — taslak JSON + kasa → okunur HTML
- `hakem-son-okuma.ps1` — 8 anlam kusuru (PARALI, tetikte `BAS` şart)
- `tablo-format-tarama.ps1` — eski format tablo sayar (03.08: 0 çıktı, iş yok)
- `sik-hesap-kodu-oneri.ps1` — ŞIKLARDAKİ hesap kodu hataları için öneri listesi
- `formul-eksik-tarama.ps1` — yöntem adı var ama formül yok (03.08: 1.616 soru)

## THP HESAP PLANI: KAYMA BULUNDU + KALICI KAPI KURULDU
Cem #194'te "500 ORTAKLARDAN ALACAKLAR" gördü (500 = SERMAYE) ve **resmi hesap planını
kaynak göstererek** karşılaştırma istedi: ismmmo.org.tr Tekdüzen Hesap Planı PDF'i.
**Gerçek hata çıktı:** bizim veride **230/231/232 kodları kaymıştı** (biz 230=Ortaklardan
Alacaklar diyorduk, resmi planda **231**'dir) — grup başlığı "23." kodla karıştırılmış.
Düzeltildi + PDF'te olup bizde olmayan **39 kod eklendi** (124,127,190,195,224,268,295,
300-302,340,350,358,393,397,401-402,502-503,645-648,655-658,697-698,790-799).

**Cem'in sorusu: "başka yerde kayma varsa nasıl öğreneceğiz?"** — haklıydı, bir seferlik
elle karşılaştırma güvence değil. **KALICI KAPI:** PDF'ten çıkarılan 267 kodluk liste
`veri/mevzuat/thp-resmi-dogrulama.json` olarak repoda; `arac/yapisal-denetci.ps1`'e **§13
kapısı** eklendi — **her push'ta** üretim THP listesi bu referansa karşı denetlenir, kayma
varsa CI KIRMIZI, deploy durur. Yerelde koşuldu: **267 kod, 0 kayma, exit 0.**
(Bu dosya AI istemine GİTMEZ — yalnız denetim referansı.)

## TABLO FORMATI: İŞ YOK ÇIKTI (ölçüldü)
Cem "Hesap | Borç | Alacak üç sütun olsun, Kalem kısa olsun" dedi; **istem düzeltildi**
([onarim-motoru.ps1:603-621](motor/onarim-motoru.ps1:603)). "27 bin soruda da değiştirelim"
dedi → ölçtük: **kasadaki 2.426 tablodan 0'ı eski formatta** (İşaret sütunlu hiç yok; 17'si
zaten Borç/Alacak, 2.409'u oran/hesaplama tablosu). **Geriye dönük iş yok.**

## ✅ KASAYA İLK GERÇEK YAZMA YAPILDI (03.08 20:30) — 105 soru
Cem onayı ("342 bas") ile **yüksek güven sınıfı** hesap kodu düzeltmeleri kasaya uygulandı.
| Yazılan soru | 105 | Değiştirilen alan | 344 |
|---|---|---|---|
| Yazma hatası | 0 | **Geri okuma doğrulanan** | **105/105** |
| Yayındakine dokunuldu | 0 | Yedek | `yedek-sik-kod-0803-2030.json` (344 kayıt) |

**Geri alma:** özel kovadaki yedek dosyasındaki `eski_metin` değerleri geri yazılır.
**Uygulanmayan 313 öneri** duruyor (`veri/sik-hesap-kodu-onerisi.json`): çift tek alanda
geçiyor, yön belirsiz — Cem gözle örnek okumadan uygulanmayacak.

## GECE BULUNAN ÜÇÜNCÜ TÜRKÇE-İ TUZAĞI: hashtable anahtarı
PowerShell hashtable anahtar karşılaştırması **kültüre bağlı** büyük/küçük harf
duyarsızlığı kullanır: tr-TR'de `"TİCARİ" = "Ticari"`, invariant'ta **ayrı anahtar**.
Aynı betik aynı veriyle **yerelde 342, CI'da 335** sayıyordu — makineye göre değişen
sınıflandırma. Anahtar artık karakter-karakter açık eşlemeyle normalleştiriliyor
(`AnahtarSade`), her makinede aynı: 346. **Bu gece aynı tuzağın üç biçimi de kapatıldı:**
(1) `ToUpperInvariant` · (2) `-replace`/`-match` · (3) hashtable anahtarı.

## UNWRAP DÜZELTMESİ DOĞRULANDI — 0 USD (4. pilot GEREKMEDİ)
Öneri robotu (`sik-hesap-kodu-oneri.ps1`) düzeltilmiş kodla **gerçek kasada** yeniden koştu.
İlk 10 örnek gözle okundu, **10'u da doğru** — kodlar artık geçerli 3 haneli THP kodu:
`257 Verilen Sipariş Avansları→159` · `260 Hazırlık Giderleri→272` · `254 Makine Tesis
Cihazlar→253` · `380 yarı mamul→151` · `103 Kasa→100`. "1"/"2" çöpü gitti.
Sayılar: **659 deterministik öneri**, 7.208 şüpheli (dokunulmadı).
**Cem'in kararı: 4. doğrulama pilotu koşulmadı, o ~2,4 USD tam partiye saklandı.**

⚠ **AMA ÖNERİLERİN YÖNÜ TEYİT EDİLMEDİ:** araç "ad doğru, kod yanlış" varsayar. Tersi de
olabilir (soru gerçekten 380 hesabından bahsedip yanlışlıkla "yarı mamul" demiş olabilir).
Yönü doğrulamak SORU METNİNİ görmeyi gerektirir → **Cem onayı olmadan uygulanmayacak.**

## SIRADAKİ İŞLER
1. ~~Pilot sayaçlarına bak~~ TAMAM — iki bug bulundu (kültür + unwrap), ikisi de düzeltildi.
2. ~~Unwrap düzeltmesini doğrula~~ TAMAM — 0 USD'ye doğrulandı (yukarı bak), 4. pilot iptal.
3. **3. pilotun raporu geldiğinde sayaçlara bak** (koşu 03.08 ~20:0x'te tetiklendi, ~2,4 USD).
   Not: o koşu, sonradan eklenen `hesap_kodu_ornek` / `hesap_kodu_gecersiz_uretim`
   alanlarını İÇERMEZ — sadece sayaç verir. İçerik doğrulaması zaten (2)'de yapıldı.
4. `veri/sik-hesap-kodu-onerisi.json` — 659 öneri hazır; **Cem yönlerini onaylarsa**
   kasaya uygulanabilir (0 USD, AI yok).
5. Hakem son okuması — kuru koşuyla maliyet ölç, sonra Cem onayıyla
6. Sonra **TEK PARTİ TEK FATURA** (~325 USD ölçüldü) — **yukarıdaki ⚠ bölümü oku, formül
   işi (1.616 soru) bu partinin içinde gelecek.**

## BUGÜNÜN EN PAHALI DERSİ
Sekiz kez rakam verdim, sekizinde de örneklere bakınca **sahte alarm** çıktı:
TL birimi · "hesabına" · "paragraf" · Türkçe ekler · eksik THP listesi · yanlış dosya
gruplama · yayında 0 soru · dayanakta olmayan THP kodları.
**Kural: yeni bir ölçüm kurulunca önce ilk on örneği gözle oku; oran akla yatkın görünse bile.**
Ve: **"kaynak eksik" demeden önce kaynağın tamamını okuduğunu doğrula.**

**03.08 gecesi bu kural İKİ kez daha kazandırdı:** (1) unwrap bug'ı yalnız ilk 10 öneriyi
gözle okurken görüldü — rapor "659 deterministik öneri" diyordu, kulağa makul geliyordu,
ama içerik çöptü. (2) Cem'in resmi PDF'i verip "karşılaştır" demesi gerçek bir kod kayması
buldu — benim "veri tamam" varsayımım yanlıştı.

## GECE ÖĞRENİLEN PowerShell TUZAKLARI (hepsi gerçek hata olarak yaşandı)
1. **`@(List[object])` çöker** — `.NET` generic List'i `@()` ile sarmak bu ortamda
   "Argument types do not match" fırlatır. Doğrusu: `.ToArray()`.
2. **`$x = Fonksiyon` tek elemanı unwrap eder** — dizi bekleniyorsa `$x = @(Fonksiyon)`.
3. **`-replace`/`-match` kültüre duyarlı** — tr-TR'de `'I' -match '[A-Z]'` **False**.
   Doğrusu: `[regex]::Replace(..., CultureInvariant)` + `ToUpper(tr-TR)`.
4. **`git add A B` — biri yoksa İKİSİ DE eklenmez** (git önce tüm pathspec'leri doğrular);
   `|| true` bunu yutup adımı yeşil gösterir, commit sessizce olmaz. Doğrusu: ayrı satırlar.
   Aynı hata 4 robotta daha bulunup düzeltildi (terim-taramasi, kardes-kaynak,
   sik-istatistigi, kaynak).

## TASARRUF KURALI (Cem 2 saatte 225 USD yaktı)
Maliyet pilot koşularından değil **sohbetin uzamasından** gelir: her mesajda tüm geçmiş
yeniden faturalanır. Bu yüzden: sohbet uzayınca **yeni sohbet aç** ve bu notla devam et ·
rutin iş **Sonnet**, Opus yalnız zor kararda · **yoklama döngüsü kurma** ·
cevaplar kısa, tablo şişirme yok.
