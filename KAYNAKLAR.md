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
| gtip-ekvergi → DFİF metni | **mevzuat.gov.tr** 88/13384 ile içerik doğrulandı (zeytinyağı 20 cent/kg vb. teyitli; mülga kalemler ayıklandı) | 🟢 BİRİNCİL (teyitli) |
| gtip-ihracat-kisit → kayda bağlı liste | **mevzuat.gov.tr** resmî .doc (9.5.10371) — yeniden hasat, kodlar temizlendi | 🟢 BİRİNCİL |
| vergi-sabitleri: 2026 asgari ücret | **Asgari Ücret Tespit Komisyonu Kararı 2025/1, RG 26.12.2025/33119** | 🟢 BİRİNCİL (teyitli) |
| vergi-sabitleri: kıdem tavanı | Hazine ve Maliye Bakanlığı memur katsayısı genelgesi (6 aylık) | 🟢 BİRİNCİL |

## GÜNCELLİK DENETİMİ — her katman EN SON hangi resmî tarihte? (12.07.2026 teyidi)

*Cem'in kuralı: "tek kaynak Resmî Gazete / yayımlayan kurumun kendi metni, ve HER ZAMAN en son yayımlanan sürüm." Ayna (TURMOB vb.) asla birincil değil — 8543'te TURMOB bayat çıktı, GİB 24.10.2025 ile düzeltildi.*

| Katman | Dayandığı EN SON resmî sürüm | Durum |
|---|---|---|
| KDV (2007/13033) | GİB güncel konsolide, **9126 s. CK — yürürlük 15/11/2024** (GİB'in canlı güncel PDF'i de burada bitiyor; 2025'te KDV oran değişikliği YOK) | 🟢 GÜNCEL |
| ÖTV (IV) | **GİB resmî 24.10.2025** IV liste (cdn.gib.gov.tr) — kod kod teyitli | 🟢 GÜNCEL |
| ÖTV (III) | **10799 s. CB Kararı — 31.12.2025** (GİB resmî PDF) | 🟢 GÜNCEL |
| Gümrük Vergisi + İGV | **İthalat Rejimi 2026 + İGV 2026** Excel (Ticaret Bak.) — robot GÜNLÜK izliyor | 🟢 GÜNCEL (oto) |
| GEKAP tutar/kapsam | **RG 28.12.2024** (2025 tutarları) + AEEE Yön. Ek-2/A | 🟢 GÜNCEL |
| Tarife Cetveli / eşya tanımı | **TGTC 2025** (Karar 10781, RG 30.12.2025) | 🟢 GÜNCEL |
| **Damping / sübvansiyon** | Ticaret Bak. **"Yürürlükteki Önlemler" konsolide Excel — 29.06.2026** (tüm yürürlükteki önlemler tek dosyada) | 🟢 GÜNCEL + **OTOMATİK** (robot izliyor, değişince oto-hasat) |
| **Gözetim** | RG gözetim tebliğleri — **SÜREKLİ değişen**, konsolide dosya YOK | 🟡 ANLIK GÖRÜNTÜ — robot "gözetim" alert'i verir, elle yenilenir |

**Sonuç:** Oran/kapsam katmanları (KDV, ÖTV, gümrük vergisi, GEKAP, tarife) EN SON resmî sürümde — 8543 türü bayatlık yok. **Damping artık otomatik** (konsolide Excel bulundu, robota bağlandı). Tek elle-izlenen kalem **gözetim** — konsolide dosyası olmadığı için robot alert verir, elle güncellenir.

## OTOMASYON (kaynaktan siteye)
1. **RG nöbetçisi** (`arac/rg-tarama.ps1`, günlük): Resmî Gazete fihristini tarar; sabit/tebliğ değişikliği yakalarsa Cem'e mail.
2. **Kaynak nöbetçisi** (`arac/kaynak-nobetcisi.ps1`, GÜNLÜK — .github/workflows/kaynak.yml):
   - **DETERMINISTIK (İthalat Rejimi + İGV Excel):** Ticaret Bak. sayfasından güncel Excel zip linkini bulur, indirir, hash'ini karşılaştırır. Değiştiyse **OTOMATIK** çıkarır + `hepsini-hasat.ps1` çalıştırır + veri/*.json'u yeniden üretir → CI commit'ler → Cem'e "değiştirdim, kontrol et" maili. Yapay zekâ YOK, uydurma imkânsız. **Test edildi: canlı zip indirilip hasat edildi, çıktı yerel veriyle birebir (deterministik).**
   - **DETERMINISTIK (Damping "Yürürlükteki Önlemler" Excel):** Ticaret Bak. Damping ve Sübvansiyon sayfasından güncel "Yürürlükteki Önlemler …xlsx" linkini bulur, indirir, hash'ler. Değiştiyse **OTOMATIK** `motor/damping-hasat.ps1` çalıştırır → `veri/gtip-damping.json` yeniden üretir → CI commit'ler → Cem'e "değiştirdim, kontrol et" maili. (İthalat Rejimi ile aynı desen; nokta-kontrol testi commit öncesi çalışır.)
   - **NÜANSLI (GİB KDV PDF, vergi kodları, İthalat Rejimi değişiklik):** hash izler, değişince "elle bak" maili — robot YAZMAZ (KDV hükmü gibi nüanslı veriyi AI'yla yazmak eski hataları geri getirir; bilerek elle bırakıldı).
- İş bölümü: deterministik veriyi robot GÜNLÜK otomatik değiştirir + Cem kontrol eder; nüanslı veriyi robot haber verir, elle-birincil-okumayla güncellenir. Hata olursa robot alert'e düşer, asla yanlış veri yayınlamaz.

## KURAL
- **TEK KAYNAK: Resmî Gazete / yayımlayan kurumun kendi metni — ve HER ZAMAN EN SON yayımlanan (tarihli) sürüm.** Bir veriyi güncellemeden önce "bunun en son resmî yayını hangisi?" diye sor; eski sürüme veya aynaya güvenme.
- Yeni veri **önce resmî kurumun kendi yayınından** (Resmî Gazete, Ticaret Bakanlığı, GİB, mevzuat.gov.tr) alınır.
- Ayna (gumruk.com.tr vb.) yalnız resmî PDF teknik nedenle açılamazsa geçici kullanılır; içerik **birincil metinle karşılaştırılıp** işaretlenir ve sırası gelince birincilden yeniden alınır.
- **Tüm satırlar 🟢 — açık (sarı) kalem kalmadı.** DFİF ve kayda bağlı, aynadan birincile taşındı (kayda bağlı yeniden hasat edilince gumruk.com.tr aynasının düzensiz boşlukları yüzünden oluşan parçalı kodlar da temizlendi).
