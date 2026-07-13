# MADDE-KAPSAM HARİTALARI — ANA İNDEKS

**Amaç (Cem):** "Hiç açıklamadığımız maddeyi nasıl bulacağız?" → yukarıdan-aşağı kapsam denetimi. Her kanunun TAM madde listesi birincilden (mevzuat.gov.tr PDF → pdftotext) çıkarılır, madde madde işaretlenir (✅ değindik / 🔴 değinmedik-önemli / ➖ konu-dışı). 🔴'lar araca eklenir. Madde sonlu → **bitiş İSPATLANIR.**

## Taranan kanunlar (5/5 madde madde tamam)
| Kanun | Araç | Dosya | Eklenen kritik "hiç değinmediğimiz" |
|---|---|---|---|
| **4734 Kamu İhale** | ihale-radari.html | [4734](4734-madde-kapsam.md) | m.5 eşit muamele, m.39 iptal, m.44 imzalamama→teminat, m.65 tebligat, +21 |
| **213 VUK (ceza)** | ceza-asistani.html | [vuk-ceza](vuk-ceza-madde-kapsam.md) | m.369 yanılma, m.374 zamanaşımı 5/2 yıl, m.339 tekerrür, m.372 ölüm, m.333 temsilci |
| **2004 İİK (konkordato)** | alacak-radari.html | [iik-konkordato](iik-konkordato-madde-kapsam.md) | m.294 takip durur, m.303 KEFİLE başvuru, m.302 nisap, m.308 iflas |
| **6769 SMK (marka)** | marka-radari.html | [smk-marka](smk-marka-madde-kapsam.md) | m.30 taklit cezası 1-3 yıl (tescil şartı), m.29 tecavüz, m.25 sessiz kalma 5 yıl, m.5 mutlak ret |
| **4458 Gümrük (ceza)** | ceza-asistani.html | [gumruk-4458](gumruk-4458-madde-kapsam.md) | m.234 fark %5→3 kat, m.235 yasak eşya 4 kat, m.241 usulsüzlük, m.243 2. tahlil |

## Liste-tipi (madde değil, harvester+denetçi korur)
- 2007/13033 KDV · 4760 ÖTV · İthalat Rejimi → GTİP araçları: bunlar KOD LİSTESİ; yapısal denetçi + nokta-kontrol + robot koruyor (Katman 1-3).

## Yöntem notları
- URL: mevzuat.gov.tr/mevzuatmetin/1.<tertip>.<no>.pdf (VUK=1.4.213, İİK=1.3.2004, 4734=1.5.4734, SMK=1.5.6769, Gümrük=1.5.4458). Tertip yanlışsa 404 → ara.
- pdftotext -layout: FlateDecode sıkıştırmayı açar (WebFetch açamaz). Taranmış görüntü PDF'i (bazı RG/CB Kararı) açılmaz → GİB/mevzuat metin sürümünden oku.
- Kenar başlığı: ":" ile biten satır, "Madde N-"den hemen önce.

**SONUÇ:** Tüm karar-araçlarının dayandığı 5 kanun madde madde tarandı; "atladığımız madde var mı" korkusu artık madde madde ispatlı kapandı. İki yön birlikte: nüans denetimi (var olanın hatası) + kapsam haritası (hiç olmayanı).
