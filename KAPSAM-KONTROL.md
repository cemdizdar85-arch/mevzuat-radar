# KAPSAM KONTROL — "kaçırmayı sistemle önle"

## 0) ALAN HARİTASI — "olmayanı nasıl buluruz"
*Eksik iki türdür: (1) kapsadığımız alanın içindeki delik → resmî listeye çentik yakalar (bölüm 1+).
(2) hiç dokunmadığımız KOMPLE alan → tehlikeli olan onu kapsıyormuş gibi göstermek. Bu harita her
alanı GÖRÜNÜR yapar; kırmızı satır = bilerek kapsamıyoruz (sürpriz değil). Yöntem: listeyi biz icat
etmeyiz — uzmanın (gümrük müşaviri / SMMM) zaten yaptığı sayımı ANKOR alırız.*

### A. DIŞ TİCARET
| Alan | Ankor | Durum |
|---|---|---|
| İthalat vergi/fonları | Gümrük beyannamesi vergi kodları | ✅ |
| İthalat Rejimi listeleri I–VII | Ticaret Bak. Excel seti | ✅ (VI/VII niş açık) |
| İthalatta denetim (TAREKS/ÜGD) | 2026 ÜGD tebliğleri | ✅ rehber |
| İhracat (KDV istisna/kayda bağlı/yasak/DFİF/DİİB) | İhracat Yönetmeliği ekleri | ✅ (kayda bağlı/yasak liste robotu açık) |
| Menşe/dolaşım belgeleri (A.TR, EUR.1, menşe şah.) | Gümrük Yönetmeliği | ✅ bilgi.html#hap-mense-belgeleri + GTİP notu |
| Gümrük rejimleri (antrepo, geçici ithalat, hariçte işleme) | Gümrük Kanunu | ✅ bilgi.html#hap-gumruk-rejimleri |

### B. ŞİRKET / VERGİ
| Alan | Ankor | Durum |
|---|---|---|
| Şirket kuruluşu / tür seçimi | TTK + sihirbaz | ✅ |
| KV/GV oranları + imalatçı/ihracatçı indirimi | KVK m.32 / GİB tarife | ✅ |
| Defter-belge (e-fatura/e-defter/e-irsaliye) | VUK 509 | ✅ |
| Bağımsız denetim eşiği · Transfer fiyatlandırması | CB Kararı / KVK m.13 | ✅ |
| Vergi takvimi (hangi beyanname ne zaman) | GİB Vergi Takvimi | ✅ bilgi.html#hap-vergi-takvimi |
| Kıdem/ihbar tazminatı tavanı | İş K. / yıllık tavan | ✅ bilgi.html#hap-kidem-ihbar (2026) |

### C. İSTİHDAM / SGK
| Alan | Ankor | Durum |
|---|---|---|
| İSG (uzman/kurul/temsilci) · engelli · emzirme · toplu çıkarma | 6331 / 4857 | ✅ eşik sayfaları |
| Asgari ücret / SGK prim taban-tavan / teşvikler | SGK yıllık | ✅ bilgi.html#hap-asgari-ucret (2026) |

### D. SEKTÖREL / DİĞER
| Alan | Ankor | Durum |
|---|---|---|
| KVKK/VERBİS · KEP/e-tebligat · TTK 1524 | ilgili kanun | ✅ |
| Destekler (KOSGEB/Ticaret Bak./Eximbank) | Destek mevzuatı | ✅ Destek Radarı |
| Sektörel lisanslar (gıda/turizm/sağlık/çevre…) | ilgili bakanlık | ✅ bilgi.html#hap-sektorel-lisans |

**KURAL:** Bir alanı resmî ankora çentikleyip "tam" demeden, sitede o alanı KAPSIYORMUŞ gibi gösterme.
❌ satırlar = bilinen açık; site dilinde asla "her şey burada" denmez. Açıklar sırayla, birer ANKORLA kapanır.

---


*Kural (Cem, 12.07.2026): İkimizin hafızasına güvenmeyiz. Her modülü RESMÎ, EKSİKSİZ bir sayım
listesine bağlar, tek tek çentikleriz. Eksik = "aklımıza gelmeyen" = patlama riski; bu belge onu
"listede işaretlenmemiş kalem"e çevirir. Yeni bir vergi/yükümlülük eklenince önce buraya, sonra siteye.*

---

## 1) İTHALAT VERGİ/FON KODLARI
**Resmî sayım listesi:** Ticaret Bakanlığı → Gümrük İşlemleri → Dijital Gümrük → EDI/XML → **Güncel Vergi Kodları**
(https://ticaret.gov.tr/gumruk-islemleri/dijital-gumruk-uygulamalari/edi-xml-referans-mesajlari/guncel-vergi-kodlari — 25.06.2026)

| Kod | Vergi | Kapsıyor muyuz? |
|---|---|---|
| 10 | Gümrük Vergisi | ✅ GV ülke bazlı |
| 20 | Dampinge Karşı Vergi | ✅ damping |
| 21 | **Sübvansiyona Karşı Vergi** (telafi edici/countervailing) | ✅ EKLENDİ — KKDF kartında not (3577 s.) |
| 29 | Çevre katkı payı / GEKAP | ✅ EKLENDİ — GEKAP kartı (lastik/pil/akü/yağ/ilaç + ambalaj/EEE notu, 2872 s.) |
| 34-39 | Ek Mali Yükümlülük (EMY) | ✅ tarım EMV (Tarım Payı) + balık EMY/TKF · ⚠ tarım-dışı EMY kontrol |
| 40 | KDV | ✅ KDV liste hükümleri |
| 50/51/52/93 | ÖTV liste II/III/IV/I | ✅ ÖTV kapsam bayrağı |
| 59 | İlave Gümrük Vergisi (İGV) | ✅ İGV ülke bazlı |
| 60/75 | TRT Bandrol (ticari/genel) | ✅ TRT notu (fasıl 85) |
| 61 | **Telafi Edici Vergi (TEV)** | ✅ EKLENDİ — ihracat/DİİB kartında not |
| 69/70 | **Toplu Konut Fonu (TKF)** | ✅ EKLENDİ — balık (IV liste) EMY sütunu + işlenmiş tarım (III) EMV |
| 72 | **Tütün Fonu** | ✅ EKLENDİ — fasıl 24 notu (yaprak tütün 2018'de sıfırlandı, rakam uydurulmadı) |
| 89 | **Damga Vergisi** | ✅ EKLENDİ — KKDF kartında maktu not |
| 991 | KKDF | ✅ eklendi (bu turda) |
| 12,16,19,46,49,58 | teminat/nihai kullanım varyantları | ℹ ana verginin türevi — ayrı katman gerekmez |
| 22,23,24,78,79,91 | gecikme/faiz/katsayı/mesai | ℹ operasyonel, ürün vergisi değil |
| 950-995 | antrepo/depo/liman/banka-sigorta ücret ve fonları | ℹ tesis/işletme ücreti, ürün vergisi değil |

**BU TURDA SİSTEMATİK BULUNAN EKSİKLER:** 21 Sübvansiyona Karşı Vergi · 61 TEV · 69/70 TKF · 72 Tütün Fonu · 89 Damga · (29 Çevre katkı payı kontrol). → sırayla kapatılacak.

---

## 1b) İTHALAT REJİMİ KARARI EKLİ LİSTELER
**Resmî sayım:** İthalat Rejimi Kararı I–VII Sayılı Listeler (Ticaret Bak. Excel seti).
| Liste | İçerik | Kapsıyor muyuz? |
|---|---|---|
| I | Tarım ürünleri (GV ülke bazlı) | ✅ gtip-vergi-tarim |
| II | Sanayi ürünleri (GV+İGV) | ✅ gtip-vergi-ulke / igv-ulke |
| III | İşlenmiş tarım (Tarım Payı/EMV) | ✅ gtip-emy-tarim · ⚠ Toplu Konut Fonu sütunu kontrol |
| IV | **Balıkçılık ve su ürünleri (GV + EMY/Toplu Konut Fonu)** | ❌→✅ EKLENDİ (2.226 kod, bu turda) — balık kör noktası kapandı |
| V | **GV askıya alınan sanayi ürünleri (GV=0)** | ✅ EKLENDİ (606 pozisyon) — askıyaKart, şartlı %0 notu |
| VI | Sivil hava taşıtı nihai kullanım (indirimli GV) | ✅ nihaiKart (VI+VII, 106 kod, şartlı) |
| VII | Nihai kullanım tarım ürünleri (indirimli GV) | ✅ nihaiKart |

**→ Çentik yöntemi Toplu Konut Fonu'nu kovalarken 4 eksik liste buldu (IV balık en büyüğü). Kanıt: yöntem çalışıyor.**
**→ İTHALAT ÇENTİĞİ %100: I–VII listeler + tüm vergi/fon kodları kapsandı. GEKAP (Cem'in yakaladığı) eklendi. KDV menşe-farkı netleştirildi (oran değişmez, tutar değişir). Kod kapsamı: 15.717 tarife kodunun tamamı sorgulanabilir, hepsinde GV var.**

## 2) SIRADAKİ ANKORLAR (aynı yöntem, diğer alanlar)
- ~~**İhracat:** İhracı Kayda Bağlı (2006/7) + Yasak/Ön İzinli (96/31)~~ ✅ EKLENDİ: gtip-ihracat-kisit.json (60 kod + isim bazlı), GTİP aracı + bilgi.html#hap-ihracat-kisit. Robot nöbetçisine değişiklik izleme eklendi.
- **Şirket yükümlülükleri:** kapsamlı "mükellef yükümlülük takvimi" / eşik envanteri — her eşik sayfası bir satır.
- **İhracat destekleri:** 5973 + 5986 Karar ekli destek listesi — her destek bir satır.

## 3) SPK / SPL DÜZEY 1 ÇEKİRDEĞİ (yeni sınav adayı — 29-30.08.2026)

*Ölçüm 29.08, yutma turu 30.08. Bu bölüm bir PAZAR KARARI DEĞİL, KAPSAMA ÖLÇÜMÜDÜR: "girelim mi"nin
değil, "girersek ne kadarı elimizde"nin cevabı. Yutma kaydı YUTMA-LISTESI.md tepesinde.*

**Resmî sayım listesi (ankor):** SPL "Sınav Konuları ve Alt Konu Başlıkları" + her dersin resmî çalışma
notu PDF'inin "SINAV ALT KONU BAŞLIKLARI" sayfası (mevzuat kesim 30.06.2026 basımları; PDF metni okundu).

**Neden bu dört ders:** SPL 2025 Faaliyet Raporu s.15 Tablo 7 → 2025'te 26.720 aday / 132.390 başvuru.
Bu dört konu tek başına **67.062 başvuru = toplamın %50,7'si** (Düzey 1 çekirdeği).
1001 Dar Kapsamlı 17.445 · 1003 SP Araçları 1 17.395 · 1005 Yatırım Kuruluşları 17.186 · 1012 Takas-Saklama 15.036.

### 1001 — Dar Kapsamlı SP Mevzuatı ve Meslek Kuralları (17.445)
| Resmî alt konu | Çentik | Madde |
|---|---|---:|
| Sermaye Piyasası Kanunu (6362) | ✅ | 269 (`DELİK-İNCELE par:4` — onarılmalı) |
| Özel Durumlar Tebliği II-15.1 | ✅ | 45 |
| Kurumsal Yönetim Tebliği II-17.1 | ✅ | 47 |
| Yatırım Fonları Tebliği III-52.1 | ✅ | 66 |
| TSPB Üyelerinin Uyacakları Meslek Kuralları | 🆕 ✅ | 34 madde (37 parça) |
| SP Çalışanları Etik İlkeleri ve Davranış Kuralları | 🆕 ✅ | 79 parça, kapsama %100 ⚠️ ambardaki "Etik Kurallar" (567 parça) **KGK etiğidir, bu değildir** |

**6/6** — *30.08: iki kalem de TSPB'nin RESMİ sitesinden alındı. TSPB, SPKn 6362 **m.74** uyarınca "tüzel kişiliği haiz **kamu kurumu niteliğinde** bir meslek kuruluşu"dur (ambardaki 6362 metninden doğrulandı) — kendi düzenlemesi birincil kaynaktır. mevzuat.gov.tr bu iki belgeyi tutmuyor.*

### 1003 — Sermaye Piyasası Araçları 1 (17.395)
| Resmî alt konu | Çentik | Madde |
|---|---|---:|
| Pay Tebliği VII-128.1 | ✅ | 106 |
| Borçlanma Araçları Tebliği VII-128.8 | ✅ | 49 |
| Borçlanma Aracı Sahipleri Kurulu Tebliği II-31/A.1 | 🆕 ✅ | 11 |
| Yatırım Fonları Tebliği III-52.1 | ✅ | 66 (1001 ile ortak) |
| Türev Araçlar · Kamu Borçlanma Araçları | ⚠ | **Kavramsal bölüm** — mevzuat çapası yok, teori notu ister |

**Mevzuat kalemlerinde 4/4** (+2 kavramsal bölüm açık)

### 1005 — Yatırım Kuruluşları (17.186)
| Resmî alt konu | Çentik | Madde |
|---|---|---:|
| Yatırım Hizmetleri Tebliği III-37.1 | ✅ | 125 |
| Yatırım Kuruluşlarının Kuruluş ve Faaliyet Esasları III-39.1 | 🆕 ✅ | 76 |
| Belge ve Kayıt Düzeni Tebliği III-45.1 | 🆕 ✅ | 33 (ilk yutmada TEK BLOB çıktı — aşağıya bak) |
| Kredili Alım / Açığa Satış / Ödünç Seri:V No:65 | ✅ | 39 |
| Kitle Fonlaması Tebliği III-35/A.2 | 🆕 ✅ | 33 |
| Uzaktan Kimlik Tespiti Tebliği III-42.1 | 🆕 ✅ | 16 — konsolide metin **III-42.1.a** (RG 28.02.2026) değişikliğini içerir; SPL kesimi 30.06.2026 olduğu için **kapsam içi** |

**6/6**

### 1012 — Takas, Saklama ve Operasyon İşlemleri (15.036)
| Resmî alt konu | Çentik | Madde |
|---|---|---:|
| MKK Kuruluş/Faaliyet/Çalışma/Denetim Yönetmeliği | 🆕 ✅ | 38 |
| Kaydileştirme Tebliği II-13.1 | ✅ | 48 |
| Merkezi Takas Kuruluşları Genel Yönetmeliği (4-5-6. bölüm) | 🆕 ✅ | 64 |
| Takasbank Merkezi Takas Yönetmeliği | 🆕 ✅ | 64 |
| Takasbank Merkezi Karşı Taraf Yönetmeliği | 🆕 ✅ | 49 |
| Portföy Saklama Tebliği III-56.1 | 🆕 ✅ | 14 |
| BİST'te pay/borçlanma aracı transfer-takas-temerrüt · türevde uzlaşma-fiziki teslim · Takasbank teminat yönetimi | ❌ | 🔴 **mevzuat.gov.tr'DE DEĞİL** — BİST/Takasbank uygulama prosedürleri, ayrı hasat hattı gerekir |

**Mevzuat kalemlerinde 6/6 — ama modülün 5 uygulama bölümü hâlâ kaynaksız. 1012 bu hâliyle AÇILAMAZ.**

### Sonuç
| Ölçü | 29.08 | 30.08 (yutma sonrası) |
|---|---:|---:|
| Tekil mevzuat belgesi | 21 | 21 |
| Ambarda VAR | 9 | **21** |
| Ambarda YOK | 12 | **0** |
| Belge kapsaması | %42,9 | **%100** |
| Elimizdeki madde | 794 | **1.226** |

*30.08 akşamı TSPB'nin iki dokümanı da resmî sitesinden alındı → 21/21.*
🔴 **AMA "çekirdeği kapsıyoruz" HÂLÂ DENMEZ:** 1012'nin beş uygulama bölümü
(BİST'te transfer-takas-temerrüt · türevde uzlaşma-fiziki teslim · Takasbank
teminat yönetimi) mevzuat.gov.tr'de de SPK portalında da YOK. O modül
15.036 başvuruluk ve kaynak hattı kurulmadan açılamaz.

Yutulan: 10 kaynak · 584 parça · 398 madde. mevzuatNo'lar tahmin edilmedi — 13 aday indirilip PDF
başlığıyla karşılaştırıldı, **3 aday yanlış çıkıp elendi**. Geri okuma yapıldı: **açıklanamayan eksik
madde yok** (atlananların hepsi metinde `(Mülga:` işaretli).

**Kalan iki açık:** (1) TSPB'nin iki dokümanı — "yok" değil **ölçülmedi**. (2) 1012'nin BİST/Takasbank
uygulama bölümleri. Bu ikisi kapanmadan site dilinde "Düzey 1 çekirdeğini kapsıyoruz" **denmez**.

### 🔴 Bu turda çıkan parçalayıcı kusuru (ambarın geri kalanını da ilgilendirir)
III-45.1 %83,2 kapsama uyarısı verdi; geri okuma sebebi buldu: **33 maddenin tamamı tek `m.5/A` blobu**
olarak yutulmuştu. Kök sebep: `mevzuat-yut.ps1` ayırıcı sınıfı yalnız `-` (U+002D) · `–` (U+2013) ·
`—` (U+2014) tanıyordu; bazı mevzuat.gov.tr PDF'lerinde ayırıcı **`‒` (U+2012)** veya **`−` (U+2212)**.
Gözle ayırt edilemez, regex için başka karakter.

**Kapsama kapısı yakalayamaz** — metin kaybı yok, kaybolan SINIRLAR. **Ders: "kapsama %" madde SAYISINI ölçmez.**

Yayılım ölçüldü (706 `_txt`): U+2012 76 kez/4 dosya · U+2212 8 kez. Sınıf genişletildi, 5 kaynak onarıldı:
**KGK Kuruluş KHK 660: 1 parça/1 madde → 50/35** (kaynakla birebir) · III-45.1 23/1 → 46/33 ·
MASAK 5549 34/30 → 35/27 · SSİY 332 → 338 · DİİB Tebliği 140 → 141.

🔴 **KGK 660 en ağırı:** zaten sattığımız bağımsız denetim sınavının KURUCU mevzuatı ambarda tek parça
duruyordu — envanterde satır VARDI, içerik YOKTU. **Açık: bu kaynağa dayanan mevcut sorular
yeniden-doğrulama kuyruğuna alınmalı.**

### 🔴 MİMARİ ÖN KOŞUL — MEVZUAT KESİM TARİHİ
SPL sınavları **donmuş mevzuata** göre sorulur: 16 Ocak–30 Haziran 2026 dönemi → **31.12.2025** mevzuatı;
16 Temmuz–31 Aralık 2026 → **30.06.2026**. "Kesim tarihinden sonraki mevzuat değişiklikleri sınavda sorulmaz."
Tüm hattımız "her zaman güncel" üzerine kurulu; SPK'da kesimden sonra değişen maddeden üretilen soru
**mevzuat olarak doğru, sınav olarak yanlış** olur. Soru kasasına `mevzuat_kesim` alanı gerekir.
**Bu bir özellik değil ön koşuldur — alan olmadan tek SPK sorusu üretilmez.**

## İŞLEYİŞ
1. Bir modül eklerken önce resmî sayım listesini bul (kanun eki, beyanname kod listesi, yönetmelik eki).
2. Her kalemi ✅/⚠/❌ çentikle. ❌'ler kapanana kadar modül "tam" sayılmaz.
3. Her yeni kalem birincil kaynaktan doğrulanır (rakam disiplini), sonra siteye + YUTMA-LISTESI'ne.
