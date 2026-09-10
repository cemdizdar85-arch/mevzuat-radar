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

## Koşu 2026-09-10 19:56 UTC · çıkış IP `57.151.137.215`

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
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 507682 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64474 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-10 09:56 UTC · çıkış IP `20.119.94.182`

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
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64474 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-09 19:57 UTC · çıkış IP `40.116.109.138`

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
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64479 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-09 09:57 UTC · çıkış IP `128.24.163.88`

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
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64479 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-08 20:05 UTC · çıkış IP `20.168.137.6`

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
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 000 |  | 0000 | PDF (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 16 | mevzuat.gov.tr TLS'siz (http) | 302 |  | 0000 | PDF (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 302, imza PDF (istek düzeltilmeli) |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64470 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-08 09:55 UTC · çıkış IP `57.154.5.167`

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
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64470 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-07 20:42 UTC · çıkış IP `172.214.102.6`

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
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-07 10:35 UTC · çıkış IP `20.169.94.181`

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
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199979 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199979 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-06 19:24 UTC · çıkış IP `52.159.244.74`

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
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64465 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200257 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200257 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199979 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199979 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199975 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202839 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200012 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200008 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199796 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | 200 | application/json | — | JSON (POST) | ✅ İNDİ (81 kayıt) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (The request was canceled due to the configured HttpClient.Timeout of 90 seconds elapsing.) |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199788 | HTML | ✅ İNDİ |

## Koşu 2026-09-06 09:34 UTC · çıkış IP `172.172.206.34`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
