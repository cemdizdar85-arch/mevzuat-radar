# DEVİR NOTU — 03.08.2026 akşamı · yeni sohbet buradan devam etsin

## Durum tek cümle
Onarım motoru **26 kuralla** donatıldı, **10 yayın kapısı + 8 hakem maddesi + 7 robot**
kuruldu; paralı tam parti hâlâ **Cem'in "bas"ını bekliyor.** Kasaya hiçbir şey yazılmadı,
site kapalı, bugün harcanan ~8 USD (pilot koşuları).

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

## SIRADAKİ İŞLER
1. Son pilotun `hesap_kodu_duzeltilen` / `hesap_kodu_supheli` sayaçlarına bak
2. Otomatik kod düzeltmesi taslakta çalıştıysa **kasadaki ~3.075 soruya** uygula (0 USD, Cem "bas" der)
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
