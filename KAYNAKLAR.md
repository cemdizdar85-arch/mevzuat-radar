# VERİ KAYNAKLARI — hangi veri nereden (dürüst döküm)

*Cem'in kuralı: "başka listelerden değil, resmî yerlerden alalım." Bu dosya her veri setinin
GERÇEK kaynağını gösterir. BİRİNCİL = resmî kurumun kendi yayını. AYNA = resmî metni birebir
kopyalayan üçüncü site (içerik aynı ama kaynak resmî değil — sırası gelince birincilden teyit edilir).*

| Veri (veri/*.json) | Kaynak | Tür |
|---|---|---|
| gtip-vergi-ulke, igv-ulke, vergi-tarim, balik, emy-tarim, askiya, nihai | **Ticaret Bakanlığı** İthalat Rejimi Kararı + İGV Kararı resmî **Excel** setleri | 🟢 BİRİNCİL |
| gtip-tanim (eşya tanımları) | **Ticaret Bakanlığı** TGTC resmî Excel (Karar 10781, RG 30.12.2025) | 🟢 BİRİNCİL |
| gtip-durum (gözetim), gtip-damping | **Resmî Gazete** gözetim/damping tebliğleri | 🟢 BİRİNCİL |
| gtip-kdv (KDV oran listeleri) | **GİB** güncel konsolide KDV metni (cdn.gib.gov.tr) | 🟢 BİRİNCİL |
| gtip-otv (ÖTV kapsam) | **4760 sayılı Kanun** (mevzuat.gov.tr resmî PDF) | 🟢 BİRİNCİL |
| gtip-ihracat-kisit → yasak/ön izinli | **Ticaret Bakanlığı** resmî .doc (96/31) | 🟢 BİRİNCİL |
| ÖTV, KKDF, TEV, Damga, TRT, Tütün, Sübvansiyon, Savunma, GEKAP dayanakları | ilgili Kanun/Karar (mevzuat.gov.tr) | 🟢 BİRİNCİL |
| vergi-sabitleri: GV dilimleri, KV, kâr payı stopajı, TF, VUK hadleri | **GİB** tarife + **mevzuat.gov.tr** Kanun/Kararlar | 🟢 BİRİNCİL |
| gtip-ekvergi → DFİF metni | gumruk.com.tr (88/13384 **AYNASI**) | 🟡 AYNA → mevzuat.gov.tr'den teyit edilecek |
| gtip-ihracat-kisit → kayda bağlı liste | gumruk.com.tr (2006/7 **AYNASI**) | 🟡 AYNA → mevzuat.gov.tr'den teyit edilecek |
| vergi-sabitleri: 2026 asgari ücret, kıdem tavanı | TURMOB/GİB (resmî **Komisyon kararı / memur katsayısı**na dayanır) | 🟡 AYNA → resmî Komisyon kararı/genelge ile teyit |

## KURAL
- Yeni veri **önce resmî kurumun kendi yayınından** (Resmî Gazete, Ticaret Bakanlığı, GİB, mevzuat.gov.tr) alınır.
- Ayna (gumruk.com.tr vb.) yalnız resmî PDF teknik nedenle açılamazsa geçici kullanılır; içerik **birincil metinle karşılaştırılıp** işaretlenir.
- 🟡 satırlar açık iştir: birincil kaynaktan bire bir teyit edilecek.
