# CANLI DENEME — 5.000 KİŞİ YÜK ÖLÇÜMÜ

Ölçüm: **23.09.2026** · Ölçen: GM (site kolu) · Yöntem: gerçek üretim uçlarına istek
Betikler: scratchpad `yuk-testi.js` (INSERT) · `yuk-get.js` (anahtar okuma)

> **Kural gereği:** bu sayfa "dayanır" demez, **ölçülen vakayı** yazar.
> Ölçülmeyen her şey aşağıda "ÖLÇÜLMEDİ" başlığı altındadır.

---

## 1 · MİMARİ — yükün nereye bindiği

| Aşama | Nereden | Sunucu yükü |
|---|---|---|
| Soru paketi (şifreli, 328 KB) | GitHub Pages / Fastly | CDN · kişi başına 1 indirme, 30 dk'ya yayılı |
| **Sınavın kendisi (120 dk)** | tarayıcı | **SIFIR istek** |
| Anahtar | Supabase Storage (yedek: Pages) | küçük dosya, yoklama |
| Sonuç | Supabase PostgREST | kişi başına **tek** INSERT |

Sınav süresince sunucuya hiçbir istek gitmiyor. Yük yalnız **iki anda** var:
kapı açılışı (anahtar) ve teslim (sonuç).

---

## 2 · ÖLÇÜLENLER

### 2.1 Sonuç yazma — `POST /rest/v1/canli_sonuc` (anon, RLS yalnız INSERT)

| Koşu | İstek | Eşzamanlı | Gerçekleşen | Başarılı | Hata | p50 | p95 | p99 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 50 | 10 | 30,6/sn | 50/50 | 0 | 240 ms | 739 ms | 872 ms |
| B | 500 | 100 | **205,8/sn** | 500/500 | 0 | 169 ms | 1.319 ms | 1.404 ms |
| C | 1.000 | 200 | **255,0/sn** | 1.000/1.000 | 0 | 355 ms | 2.222 ms | 2.275 ms |

Üç koşuda da HTTP **201**, tek hata yok, 429/5xx yok. **Tavan görülmedi** —
sınırlayan büyük olasılıkla ölçümü yapan makine ve ev bağlantısıydı, sunucu değil.

Test satırları (1.550 adet, `oturum='YUK-TESTI-2309'`) servis anahtarıyla **silindi**;
silme sonrası tabloda **0 satır** kaldı (yani öncesinde gerçek sonuç da yoktu).

### 2.2 Anahtar okuma — Supabase Storage public nesne

| İstek | Eşzamanlı | Gerçekleşen | Başarılı | Hata | p50 | p95 |
|---:|---:|---:|---:|---:|---:|---:|
| 600 | 150 | **169,0/sn** | 600/600 | 0 | 322 ms | 1.711 ms |

### 2.3 Paket indirme — GitHub Pages

`tetikte.com/veri/canli/SGS-2308.enc.json` → **200 · 327.702 bayt · 0,84 sn** ·
`Server: GitHub.com` · Fastly (`X-Served-By`) · `Cache-Control: max-age=600`.
5.000 kişilik toplam ≈ **1,6 GB** — GitHub Pages için sorun değil.

### 2.4 ⚠ Supabase Storage CDN'lenmiyor (bugün öğrenildi)

Public nesne yanıtı `Cache-Control: no-cache` döndürüyor ve bu, yükleme sırasında
`cache-control: max-age=5` başlığı verilse bile **değişmiyor** (CF-Cache-Status
MISS → REVALIDATED). Yani anahtar yoklaması Cloudflare'da durdurulamıyor,
her yoklama Supabase'e ulaşıyor. Kazanç yalnız GitHub Pages yedeğinde.

---

## 3 · YAPILAN DÜZELTMELER (`canli-deneme.html`)

| # | Önce | Sonra | Etki (5.000 kişi) |
|---|---|---|---|
| 1 | Sonuç gönderimi 0,5–15,5 sn'ye yayılı | **0,5–150 sn** | tepe ≈333/sn → **≈33/sn** |
| 2 | Başarısız gönderim tekrarı sabit 9 sn | **20–60 sn rastgele** | düşen istekler aynı ana yığılmıyor |
| 3 | Anahtar yoklaması 8–15 sn | **10–25 sn** | ≈435/sn → **≈286/sn** |
| 4 | Cache-buster `?<ms>` (benzersiz) | **10 sn kova** (anahtar) / **60 sn kova** (paket) | Pages tarafında CDN devreye girdi |
| 5 | Supabase `canli` kovası **yoktu** | **oluşturuldu (public)**, uçtan uca prova yapıldı, prova dosyası silindi | 10:00'da denenmemiş yol kalmadı |

Ölçülen tepe kapasite (255/sn) ile düzeltme sonrası beklenen tepe (33/sn)
arasında yaklaşık **8 kat** pay var.

---

## 4 · ÖLÇÜLMEDİ (bu sayfanın körlükleri)

- **5.000 gerçek tarayıcı** hiç denenmedi; ölçüm tek makineden yapıldı.
  Gerçek dünyada mobil ağlar, yavaş cihazlar ve 5.000 ayrı IP devreye girer.
- **Anahtarın geç yayınlanması** senaryosu denenmedi. Kısa tepe sorun değil;
  anahtar 10 dakika gecikirse yoklama yükü 10 dakika **sürekli** olur.
- **Tarayıcıda 120 dakikalık oturum** (sekme arka plana alınınca sayaç, uyku
  modu, sayfa yenileme) denenmedi.
- **Paket indirme** 5.000 eşzamanlı denenmedi, tek istek ölçüldü.
- Supabase Pro planının ilan edilmiş bir istek/sn tavanı yok; buradaki sayılar
  **o gün, o uçtan** ölçülmüştür, garanti değildir.

---

## 5 · SINAV GÜNÜ KURALLARI

1. **Anahtar saatinde basılır** (`motor/canli-anahtar-yayinla.ps1 -oturum <kod>`).
   Gecikme, ölçülen tek gerçek risktir.
2. **O gün SQL basılmaz** — 14.09 ölçümü: auth.users FK'lı tablo basarken
   PostgREST 2–3 dk **503** veriyor.
3. Sonuç gönderilemezse skor kaybolmaz: `localStorage`'a yazılıyor ve kullanıcıya
   söyleniyor.
4. Servis anahtarıyla istek atarken **tarayıcı User-Agent'ı kullanılamaz** —
   Supabase "Forbidden use of secret API key in browser" ile reddediyor
   (PowerShell'in varsayılan UA'sı "Mozilla" içerdiği için düşüyor; `-UserAgent`
   ile düz bir ad verilmeli). 23.09'da bu tuzağa düşüldü.
