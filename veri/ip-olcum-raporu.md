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

## Koşu 2026-11-07 21:01 UTC · çıkış IP `20.98.142.224`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199852 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199852 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468906 | HTML (beklenen HTML) | ✅ İNDİ |
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
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-07 11:51 UTC · çıkış IP `20.72.213.152`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200763 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200763 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 469083 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63215 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 000 |  | 0000 | HTML (beklenen HTML) | ❌ ENGEL — bağlantı kurulamadı |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-06 22:15 UTC · çıkış IP `172.132.46.108`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200763 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200763 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 469083 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 552423 | HTML (beklenen HTML) | ✅ İNDİ |
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
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-06 13:07 UTC · çıkış IP `13.71.234.160`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200696 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200696 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468906 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 551552 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63210 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-05 22:45 UTC · çıkış IP `4.155.134.55`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200688 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200688 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 469084 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 551711 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 551711 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63210 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-05 13:23 UTC · çıkış IP `20.186.239.246`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199764 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199764 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468907 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 551711 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 551711 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63220 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-04 22:45 UTC · çıkış IP `130.131.239.70`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196072 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 199764 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 199764 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468907 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 550552 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63220 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-04 13:10 UTC · çıkış IP `134.33.77.40`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200921 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200921 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468907 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32689 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 550552 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 550552 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63225 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200921 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200921 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-03 22:27 UTC · çıkış IP `52.241.149.16`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
| 1 | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) | 200 | application/pdf | 196727 | PDF (beklenen PDF) | ✅ İNDİ |
| 2 | mevzuat.gov.tr MevzuatMetin (SPKn 6362) | 200 | application/pdf | 1482842 | PDF (beklenen PDF) | ✅ İNDİ |
| 3 | resmigazete.gov.tr ana sayfa | 200 | text/html | 200917 | HTML (beklenen HTML) | ✅ İNDİ |
| 4 | resmigazete.gov.tr fihrist (gunluk tarama kaynagi) | 200 | text/html | 200917 | HTML (beklenen HTML) | ✅ İNDİ |
| 5 | ekap.kik.gov.tr bulten indirme (IHALE kaynagi) | 200 | text/html | 37471 | HTML (beklenen HTML) | ✅ İNDİ |
| 6 | api.ted.europa.eu arama (yurtdisi ihale) | 405 | application/json | 64 | JSON (beklenen JSON) | ⚠️ ERİŞİM VAR — kod 405, imza JSON (istek düzeltilmeli) |
| 7 | mevzuat.spk.gov.tr API (Search/All) | 200 | application/json | 374031 | JSON (beklenen JSON) | ✅ İNDİ |
| 8 | mevzuat.spk.gov.tr belge (Teblig III-52.1) | 200 | application/pdf | 240744 | PDF (beklenen PDF) | ✅ İNDİ |
| 9 | spl.com.tr calisma notu sayfasi | 200 | text/html | 468919 | HTML (beklenen HTML) | ✅ İNDİ |
| 10 | spl.com.tr calisma notu PDF (1001) | 200 | application/pdf | 3248913 | PDF (beklenen PDF) | ✅ İNDİ |
| 11 | tspb.org.tr Meslek Kurallari PDF | 200 | application/pdf | 55746 | PDF (beklenen PDF) | ✅ İNDİ |
| 12 | spk.gov.tr dosya arama | 200 | text/html | 32765 | HTML (beklenen HTML) | ✅ İNDİ |
| 13 | kgk.gov.tr standart PDF (TFRS 10, Kirmizi Kitap) | 200 | application/pdf | 538837 | PDF (beklenen PDF) | ✅ İNDİ |
| 14 | kgk.gov.tr denetim standardi (BDS 200) | 200 | application/pdf | 1258943 | PDF (beklenen PDF) | ✅ İNDİ |
| 15 | mevzuat.gov.tr ana sayfa (domainin TAMAMI mi engelli) | 200 | text/html | 558178 | HTML (beklenen HTML) | ✅ İNDİ |
| 16 | mevzuat.gov.tr TLS'siz (http) | 200 | text/html | 549140 | HTML (beklenen HTML) | ✅ İNDİ |
| 17 | TBMM kanun metni (OZGUN hal - konsolide DEGIL) | 200 | text/html | 63225 | HTML (beklenen HTML) | ✅ İNDİ |
| 18 | resmigazete arsiv sayfasi (ozgun yayim) | 200 | text/html | 791106 | HTML (beklenen HTML) | ✅ İNDİ |
| 19 | gib.gov.tr mevzuat (vergi tarafi) | 404 | text/html | 37072 | HTML (beklenen HTML) | ⚠️ ERİŞİM VAR — kod 404, imza HTML (istek düzeltilmeli) |
| 20 | mevzuat.adalet.gov.tr | 200 | text/html | 1235 | HTML (beklenen HTML) | ✅ İNDİ |
| 21 | ilan.gov.tr AdsByFilter (ALACAK+IHALE kaynagi) | 000 |  | 0000 | bilinmiyor (POST) | ❌ ENGEL — bağlantı kurulamadı |
| 22 | api.ted.europa.eu arama (yurtdisi ihale) | 200 | application/json | 4468 | JSON (POST) | ✅ İNDİ (POST) |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200917 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200917 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200921 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200921 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199764 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200688 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196727 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200696 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 200763 | HTML | ✅ İNDİ |
| — | ilan.gov.tr AdsByFilter — **üretim aracı (pwsh/.NET)** | — | — | — | — | ❌ İNMEDİ (Response status code does not indicate success: 403 (Forbidden).) |
| — | mevzuat.gov.tr GeneratePdf (Teblig III-39.1) — **üretim aracı (pwsh/.NET)** | 200 | — | 196072 | PDF | ✅ İNDİ |
| — | mevzuat.gov.tr MevzuatMetin (SPKn 6362) — **üretim aracı (pwsh/.NET)** | 200 | — | 1482842 | PDF | ✅ İNDİ |
| — | resmigazete.gov.tr ana sayfa — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |
| — | resmigazete.gov.tr fihrist (gunluk taramanin kaynagi) — **üretim aracı (pwsh/.NET)** | 200 | — | 199852 | HTML | ✅ İNDİ |

## Koşu 2026-11-03 12:55 UTC · çıkış IP `172.210.5.225`

| # | Hedef | HTTP | İçerik tipi | Bayt | İmza | Sonuç |
|---|---|---|---|---:|---|---|
