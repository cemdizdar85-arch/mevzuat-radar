# IP ÖLÇÜMÜ — kaynak siteler runner'dan iniyor mu?

> **Bu dosya BİRİKİMLİDİR** — her koşu en üste eklenir, eskiler silinmez.
> Soru: günlük indirme Cem'in dizüstünden çıkabilir mi?
> Ölçüt: HTTP 200 YETMEZ — içerik tipi ve gerçek imza da doğrulanır
> (bu depoda ölçüldü: ölü adres 200+HTML, bilinmeyen API yolu 200+SPA kabuğu döner).

**Nasıl okunur:** hepsi ✅ → indirme CI'ya taşınır, laptop bağımlılığı biter ·
yalnız mevzuat.gov.tr ❌ → sadece o site için TR-IP çözümü gerekir ·
hepsi ❌ → TR-IP'li sunucu şart.

> ⚠️ **BİR SATIRA "ENGEL" DEMEDEN ÖNCE ÜRETİM ARACI SATIRINA BAK.**
> 30.08'de ölçüldü: `ilan.gov.tr` curl ile üç koşuda da `000` (ENGEL) dedi —
> POST'a çevrilince de, süre 120 sn'ye çıkarılınca da, üretimin User-Agent'ıyla da.
> **Aynı koşuda, aynı runner'dan, PowerShell/.NET ile 200 ve 81 kayıt indi.**
> Yani "engel" hükmü sitenin değil, ÖLÇÜM ARACININ sonucuydu (TLS parmak izi).
> Tabloda `üretim aracı (pwsh/.NET)` satırları bu yüzden var: curl satırıyla
> çelişirlerse **doğru olan üretim aracı satırıdır** — üretim hattı onu kullanıyor.
>
> Aynı sınav mevzuat.gov.tr'ye de uygulandı: o **iki araçla da inmedi**.
> Yani TR-IP ihtiyacı gerçek, ama **tek kaynağa** iniyor.

## Koşu 2026-08-30 06:53 UTC · çıkış IP `52.241.147.99`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:48 UTC · çıkış IP `64.236.135.9`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:31 UTC · çıkış IP `20.55.87.181`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 5 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 6 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 8 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 11 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 13 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 14 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:25 UTC · çıkış IP `20.98.141.172`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 5 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 6 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 8 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 11 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 13 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 14 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:22 UTC · çıkış IP `48.217.115.146`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 5 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 6 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 8 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 11 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 13 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 14 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:15 UTC · çıkış IP `20.83.159.2`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 5 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 6 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 8 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 11 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 13 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 14 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 06:11 UTC · çıkış IP `20.15.229.151`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 5 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 6 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 8 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 11 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 13 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 14 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 05:46 UTC · çıkış IP `20.169.77.229`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | ilan.gov.tr ana sayfa (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | ilan.gov.tr AdDetail API | 000 |  | 0000 | bilinmiyor (beklenen JSON) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

## Koşu 2026-08-30 03:55 UTC · çıkış IP `52.159.247.228`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ İNMEDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ İNMEDİ |
| 3 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 363057 | JSON (beklenen JSON) | ✅ İNDİ |
| 4 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 5 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 7 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 8 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 9 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 10 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 197233 | HTML | ✅ İNDİ |

