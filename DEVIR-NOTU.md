# DEVİR NOTU — 03.08.2026 gece · yeni sohbet buradan devam etsin

## Durum tek cümle
Onarım motoru **26 kuralla** donatıldı, **10 yayın kapısı + 8 hakem maddesi + 7 robot**
kuruldu; paralı tam parti hâlâ **Cem'in "bas"ını bekliyor.** Kasaya hiçbir şey yazılmadı,
site kapalı, bugün harcanan ~8 USD (pilot koşuları) + ikinci pilot GitHub'da kuyrukta.

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
doğru**. Kasaya/Supabase'e dokunulmadı, 0 USD. Bu commit'le birlikte ikinci bir 200'lük
PILOT (`onarim-pilot.txt` → BAS) GitHub Actions'a tetiklendi — düzeltmenin gerçek veride de
tuttuğunu doğrulamak için. Sonucu (yeni `hesap_kodu_duzeltilen/supheli/yanlis`) kontrol et.

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

## TABLO FORMATI: HESAP HAREKETİ BORÇ/ALACAK OLARAK AYRILSIN
Cem pilotta (1650) "690 Dönem Karı..." gibi tabloları gördü: tek "Tutar (TL) +
İşaret (Alacak+/Borç-)" sütunu yerine gerçek muhasebe kaydı gibi **Hesap | Borç
| Alacak** üç sütun istedi, Kalem adı da kısa olsun. **İSTEM düzeltildi**
([onarim-motoru.ps1:603-621](motor/onarim-motoru.ps1:603)) — ama bu yalnız
BUNDAN SONRAKİ üretimlere yansır. Cem: "27 bin sorumuz var, onlarda da
değiştireceğiz" — yani KASADAKİ eski format tablolar da hedefte. İlk adım
**ölçmek**: `motor/tablo-format-tarama.ps1` kuruldu (0 USD, kasaya yazmaz,
yalnız sayar + "İşaret" sütunundaki değerler saf Alacak(+)/Borç(-) kalıbındaysa
**deterministik (AI'siz, 0 USD) dönüştürülebilir** mi diye işaretler). Sonucu
`veri/tablo-format-taramasi-raporu.json`'da — bir sonraki iş: o rapora bak,
ilk 10 örneği gözle oku (Cem'in kuralı), sonra dönüştürme scripti yazılır.

## SIRADAKİ İŞLER
1. ~~Son pilotun `hesap_kodu_duzeltilen` / `hesap_kodu_supheli` sayaçlarına bak~~ TAMAM —
   0/57/61 çıktı, kültür hatası bulundu ve düzeltildi (yukarıya bak). İkinci pilotun
   sonucunu kontrol et.
2. İkinci pilot düzeltmeyi doğrularsa **kasadaki ~3.075 soruya** uygula (0 USD, Cem "bas" der)
3. Cem'in okumasından çıkan yeni kusurları işle
4. Hakem son okuması — kuru koşuyla maliyet ölç, sonra Cem onayıyla
5. Sonra **TEK PARTİ TEK FATURA** (~330 USD ölçüldü; ucuzlatma yolu: THP listesini
   yalnız hesap kodu gereken sorulara koymak — ölçülmedi)

## BUGÜNÜN EN PAHALI DERSİ
Sekiz kez rakam verdim, sekizinde de örneklere bakınca **sahte alarm** çıktı:
TL birimi · "hesabına" · "paragraf" · Türkçe ekler · eksik THP listesi · yanlış dosya
gruplama · yayında 0 soru · dayanakta olmayan THP kodları.
**Kural: yeni bir ölçüm kurulunca önce ilk on örneği gözle oku; oran akla yatkın görünse bile.**
Ve: **"kaynak eksik" demeden önce kaynağın tamamını okuduğunu doğrula.**

## TASARRUF KURALI (Cem 2 saatte 225 USD yaktı)
Maliyet pilot koşularından değil **sohbetin uzamasından** gelir: her mesajda tüm geçmiş
yeniden faturalanır. Bu yüzden: sohbet uzayınca **yeni sohbet aç** ve bu notla devam et ·
rutin iş **Sonnet**, Opus yalnız zor kararda · **yoklama döngüsü kurma** ·
cevaplar kısa, tablo şişirme yok.
