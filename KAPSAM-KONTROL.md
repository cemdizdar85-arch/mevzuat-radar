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

## İŞLEYİŞ
1. Bir modül eklerken önce resmî sayım listesini bul (kanun eki, beyanname kod listesi, yönetmelik eki).
2. Her kalemi ✅/⚠/❌ çentikle. ❌'ler kapanana kadar modül "tam" sayılmaz.
3. Her yeni kalem birincil kaynaktan doğrulanır (rakam disiplini), sonra siteye + YUTMA-LISTESI'ne.
