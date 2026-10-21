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

## Koşu 2026-10-21 10:25 UTC · çıkış IP `68.220.61.0`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 201176 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 201176 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369843 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64469 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-20 20:46 UTC · çıkış IP `172.183.135.149`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 204469 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 204469 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37475 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64460 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-20 10:15 UTC · çıkış IP `4.242.195.40`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 204477 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 204477 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37475 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 738145 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 562571 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64460 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-19 21:39 UTC · çıkış IP `4.246.71.202`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 204477 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 204477 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 575301 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64460 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-19 11:02 UTC · çıkış IP `172.182.195.130`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 201235 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 201235 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 575301 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64459 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-18 19:32 UTC · çıkış IP `20.106.198.161`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199958 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199958 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 489103 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32820 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64455 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-18 09:46 UTC · çıkış IP `172.214.110.101`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199954 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199954 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 488620 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64455 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-17 19:37 UTC · çıkış IP `64.236.145.65`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 202307 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 202307 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 488620 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 000 |  | 0000 | PDF (beklenen PDF) | ❌ ENGEL — bağlantı kurulamadı |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64459 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-17 09:34 UTC · çıkış IP `172.182.226.130`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 202307 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 202307 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 369073 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 488444 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32744 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 64459 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202307 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199954 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199958 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201235 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204477 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 204469 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 201176 | HTML | ✅ İNDİ |

## Koşu 2026-10-16 20:01 UTC · çıkış IP `20.168.249.150`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
