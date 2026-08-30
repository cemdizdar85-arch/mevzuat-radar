# IP ÖLÇÜMÜ — kaynak siteler runner'dan iniyor mu?

> Koşu: 2026-08-30 01:51 UTC · runner çıkış IP'si: `52.173.162.33`
> Soru: günlük indirme Cem'in dizüstünden çıkabilir mi?
> Ölçüt: HTTP 200 YETMEZ — içerik tipi ve gerçek imza da doğrulanır.

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ İNMEDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ İNMEDİ |
| 3 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 4 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 5 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 8 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |

## Nasıl okunur
- **Hepsi ✅** → indirme işi runner'a taşınabilir; laptop bağımlılığı biter.
- **mevzuat.gov.tr ❌, diğerleri ✅** → yalnız o site için TR-IP çözümü gerekir; gerisi CI'ya taşınır.
- **Hepsi ❌** → 05.08 bulgusu duruyor; TR-IP'li sunucu şart.

*Not: bu ölçüm tek koşudur. Bir site geçici engel/oran sınırı uyguluyor olabilir;
karar vermeden önce farklı saatlerde iki koşu daha görmek doğru olur.*
