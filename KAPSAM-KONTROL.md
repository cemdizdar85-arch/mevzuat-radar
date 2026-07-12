# KAPSAM KONTROL — "kaçırmayı sistemle önle"

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
| 29 | **Çevre katkı payı** | ⚠ KONTROL — kapsam netleştir (açık) |
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
| V | **GV askıya alınan sanayi ürünleri (GV=0)** | ❌ EKSİK (2.058 kod) — bu kodlarda GV sıfır, "iyi haber" listesi |
| VI | Sivil hava taşıtı nihai kullanım (indirimli GV) | ⚠ niş — awareness |
| VII | Nihai kullanım tarım ürünleri (indirimli GV) | ⚠ niş — awareness |

**→ Çentik yöntemi Toplu Konut Fonu'nu kovalarken 4 eksik liste buldu (IV balık en büyüğü). Kanıt: yöntem çalışıyor.**

## 2) SIRADAKİ ANKORLAR (aynı yöntem, diğer alanlar)
- **İhracat:** İhracat Yönetmeliği ekleri (Kayda Bağlı İhracat Listesi, İhracı Yasak/Ön İzinli Mallar Listesi) — tam listeye çentik.
- **Şirket yükümlülükleri:** kapsamlı "mükellef yükümlülük takvimi" / eşik envanteri — her eşik sayfası bir satır.
- **İhracat destekleri:** 5973 + 5986 Karar ekli destek listesi — her destek bir satır.

## İŞLEYİŞ
1. Bir modül eklerken önce resmî sayım listesini bul (kanun eki, beyanname kod listesi, yönetmelik eki).
2. Her kalemi ✅/⚠/❌ çentikle. ❌'ler kapanana kadar modül "tam" sayılmaz.
3. Her yeni kalem birincil kaynaktan doğrulanır (rakam disiplini), sonra siteye + YUTMA-LISTESI'ne.
