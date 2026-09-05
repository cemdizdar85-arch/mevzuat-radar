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

## Koşu 2026-09-05 19:15 UTC · çıkış IP `4.236.159.229`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37459 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64469 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-05 09:12 UTC · çıkış IP `74.235.102.245`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37459 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 508018 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64469 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-04 19:47 UTC · çıkış IP `128.85.45.71`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37459 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 508018 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64464 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-04 09:49 UTC · çıkış IP `128.24.163.40`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37459 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64464 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-03 20:01 UTC · çıkış IP `130.131.237.128`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64474 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-03 09:59 UTC · çıkış IP `20.55.15.4`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507842 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64474 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-02 19:59 UTC · çıkış IP `172.215.239.217`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507842 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64479 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-02 09:48 UTC · çıkış IP `172.182.226.195`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64479 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200020 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200020 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-01 20:02 UTC · çıkış IP `52.242.242.150`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 000 |  | 0000 | bilinmiyor (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 3 | resmigazete.gov.tr ana sayfa | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 000 |  | 0000 | bilinmiyor (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37455 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 366305 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507849 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64479 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 200 | text/html | 21058 | HTML (beklenen HTML) | ✅ İNDİ |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199765 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199765 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200020 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200020 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200016 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200275 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200058 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200066 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 209041 | HTML | ✅ İNDİ |

## Koşu 2026-09-01 10:18 UTC · çıkış IP `4.242.29.37`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
