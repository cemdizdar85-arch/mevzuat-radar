# İŞ EMRİ — ONARIM HATTI YENİ SORUYU SESSİZCE YAYINDAN DÜŞÜRÜYOR (03.10.2026)

**Sahibi:** altyapı kolu (onarım hattı ortak araç). **Açan:** "Patron sitesi SMMM staj soruları" oturumu, Cem 03.10 "1.2.3 üçünü de yap".
**Öncelik:** yüksek — yeni üretim büyüdükçe etki büyür.

## Ne oldu (ölçüldü, 03.10)
02–03.10 gecesi sitedeki SGS + bitirme sorularında 440 tekil soru `arac/onarim-hatti.js teslim` ile onarıldı.
`onarim-hatti.js` her onarımda `aciklama_hakem` alanını SİLER (`HER_ONARIMDA_SIL`, satır ~29).
Yayın şartı (`arac/havuz-kur.ps1` → `AhSecilemez`, `arac/aciklama-hakemi-uretim.ps1:21`) YENİ soruda
(kör/hakem2 tarihi ≥ 2026-10-01) `aciklama_hakem.karar = TEMIZ` arar. Sonuç: onarılan **2 yeni soru**
(`sgs-p-fmuh-cokzor-r3/kp-22`, `sgs-t1-issgk-zor/kp-25`) ilk yayında siteden düştü; kimse uyarılmadı.
440'ın kalan 438'i eski üretim (şart uygulanmıyor). Elle kurtarma: `veri/sinav/plan-sgs-k23-onarim-hakem.json` (bulut sırası).

## İstenen
1. `onarim-hatti.js teslim`: onarılan kayıt YENİ ise (aynı tarih tanımı, `AhYeniMi` ile tek kaynak) ve anahtar/kök
   değişmediyse, teslim sonunda bu kayıtlar için **tek bir yeniden-hakem planı** (`plan-<sınav>-oNN-ah.json`, pilotId)
   yazılsın ve `motor/bulut-sira.ps1 -Ekle` ile bütçesiyle sıraya konsun — ya da en azından ekrana
   **"YAYINDAN DÜŞECEK: N yeni soru"** uyarısı + liste basılsın (sessiz düşüş biter).
2. Öz-sınav: yeni soru onarımı → plan/uyarı üretilir; eski soru onarımı → üretilmez; anahtar değişen → elle rette kalır (mevcut davranış).
   Mutasyonla ölç (`CLAUDE.md` KAPI KURMA KURALLARI 8).
3. Bütçe: plan bütçesi soru başı ≈0,08 USD (k21 ölçümü: 6 soru 0,45 USD) + açıklama hakemi payı ≈0,04. Para harcayan
   sıraya koyma Cem onayı ister → varsayılan yalnız **uyarı + plan dosyası**, sıraya koyma bayrakla (`--siraya-koy`).

## GÖRMEZ (bu iş emrinin kapsamı dışı)
Kör/hakem2 alanı hiç olmayan kayıtların "yeni mi" sayılması; SMMM yayın şartının (`SmmmKaliteNeden`) aynı açığı taşıyıp
taşımadığı **ölçülmedi** (bitirmede 03.10 onarılanların 0'ı yeni üretimdi).
