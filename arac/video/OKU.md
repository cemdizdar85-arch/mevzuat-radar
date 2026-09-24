# arac/video — Tetikte video hattı (tek kaynak)

24.09.2026'da depoya taşındı (Cem: *"video betiklerini depoya taşı"*). Önceden `video/sorunun-gunlugu/`
(git dışı) ve `~/.claude/araclar/kayit/` altındaydı; OneDrive sessizce eski sürüme döndürebiliyordu.
Eski yerlerde yalnız **yönlendirici** kaldı. Büyük dosyalar (mp4, sahne json, harcama defteri) hâlâ
`video/sorunun-gunlugu/` altında, git dışı.

## Sıra — atlanmaz

| # | adım | araç | bedel |
|---|---|---|---|
| 1 | Ses üret (kilitli ses kimliği) | `ses-uret.ps1 -MetinDosya <metin.json> -Etiket X` | 0 (abonelik) |
| 2 | **Ses denetimi** — her cümle tek tek, KIRMIZI'da alış çöpe | `ses-uret.ps1` içinde otomatik (`klip-denetim.js`) | 0 |
| 3 | Cem sesi dinler (mp3 değil **video** olarak gönderilir) | — | 0 |
| 4 | Klip bas | `uret.ps1 -Sahne X -Tur final` | ≈3,71 USD / 16 sn 720p |
| 5 | **Klip denetimi** — KIRMIZI'da `exit 2`, kurguya geçilmez | `uret.ps1` içinde otomatik | 0 |
| 6 | Dudak kareleri gözle (`<klip>.denetim.png`: yeşil çerçeve ağız açık, kırmızı kapalı) | — | 0 |
| 7 | Kurgu (katmanlar `kart-bas.js ... saydam`, ses rengi `eq-esle.js`) | kurgu betiği | 0 |
| 8 | **Bitmiş filme denetim** (klip + kart + kapanış cümleleri) | `node klip-denetim.js <film> <json>` | 0 |

## Kapılar (uret.ps1)

- **720p varsayılan** — sahne 1080p derse durur; `-Cozunurluk 1080p` açıkça istenir (yalnız klipte okunacak yazı varsa).
- **Pazarlama soru kapısı** — sahnede `soru_id` varsa `arac/pazarlama-soru-kapisi.ps1` (VUK/TMS çatalı) önce koşar.
- **Beklenen replikler** — sahnede `beklenen_replikler` yoksa **para harcanmadan** durur (`-DenetimYok "<gerekçe>"` ile bilerek geçilir, defterde kalır).

## klip-denetim.js

- KIRMIZI: düşen/eksik cümle · kelime tekrarı (ada dökümü) · 2+ fazladan kelime. SARI: yakın eşleme (kulakla bak).
- Öz-sınav: `node klip-denetim.js --sinav` — vakalar **kasada** (`_yerel-veri-kasasi/instagram-ilk-gonderi/denetim-sinav/vakalar.json`;
  depo public, video metni commit'lenmez). Mutasyon: `KD_MUTASYON=dusen|tekrar|yapisik` → sınav DÜŞMELİ.
- **GÖRMEZ:** dudak senkronu (yalnız kare tabakası) · telaffuz inceliği (yalnız yakın eşleme) · yerel araç (whisper bu makinede),
  CI'da (`dogrula.yml`) koşmaz · whisper <1 sn parçada/kayıt sonunda kelime düşürebilir.

## Tuzaklar (yaşandı)

- ffmpeg arka planda stdin bekleyip **0 CPU'da dondu** → her çağrıda `-nostdin`.
- `node ... | head` boruyu kapatıp çizimi yarıda kesti → çıktıyı dosyaya al, sonra oku.
- Dinamik `loudnorm` sessiz sayacı yükseltti (tık −3 dB'ye çıktı) → **sabit kazanç** + `alimiter`.
- Whisper iki kelimeyi yapıştırabilir → denetleyici beklenen çiftlere göre ayırır (`yapisigiAyir`).
