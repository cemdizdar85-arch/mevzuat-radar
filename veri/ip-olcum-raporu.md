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

## Koşu 2026-11-24 16:05 UTC · çıkış IP `20.102.223.145`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200556 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200556 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37475 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 554333 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 554333 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63216 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-24 03:25 UTC · çıkış IP `4.227.166.247`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200556 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200556 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37475 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 556806 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63216 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-23 16:18 UTC · çıkış IP `172.182.209.60`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199821 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199821 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 556806 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63215 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-22 22:40 UTC · çıkış IP `52.159.244.82`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199729 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199729 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63215 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-22 13:29 UTC · çıkış IP `20.65.227.166`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199263 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199263 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63211 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-21 22:15 UTC · çıkış IP `20.161.77.161`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199267 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199696 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63211 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-21 13:38 UTC · çıkış IP `20.168.103.49`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 202164 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 202164 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63215 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-20 23:15 UTC · çıkış IP `20.246.54.182`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 202172 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 202172 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 550490 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63215 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202172 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202172 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-20 14:14 UTC · çıkış IP `3.42.157.161`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199729 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199729 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374951 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 473431 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 550490 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63210 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202172 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202172 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 202164 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199267 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199263 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199729 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199821 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200556 | HTML | ✅ İNDİ |

## Koşu 2026-11-19 23:41 UTC · çıkış IP `52.157.32.194`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
