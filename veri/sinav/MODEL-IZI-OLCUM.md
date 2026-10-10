# Soru verisinde model adı izi — ölçüm + temizlik planı (10.10.2026)

Kural: CLAUDE.md "soru verisine model adı (`claude-…`) girmez". Ham ölçüm: [MODEL-IZI-OLCUM.json](MODEL-IZI-OLCUM.json)
(araç `node arac/model-izi-olc.js`; yalnız yol + değer + sayı basar, soru metni yok).

## 1. Ölçüm (yerel önbellek `veri/fabrika/kalip-parti-*.json`)

⚠ Önbellek ambarın **kopyasıdır**, ambarın kendisi değil: dosya tarihleri 17.09 – 10.10. Ambarda bundan yeni parti varsa
burada **ölçülmedi**.

| | |
|---|---|
| parti dosyası | 2.526 (okunamayan 0, sistem kaydı atlanan 1) |
| soru kaydı | 15.381 |
| izli kayıt | **12.912** |
| `model` alanında ad | **64.089** alan |
| metin içinde ad | ölçülmedi (alt dize araması yanlış alarm veriyor: toplu iş kimliği "…oPUS…") |
| başka anahtarda tam kimlik | 0 |
| ANAHTAR adında model | `simulasyon_sonnet` — 10.883 kayıt (çevrilmiyor, bkz. 5) |

Sınav kırılımı (izli / kayıt): SGS 6.691 / 7.662 · SMMM 5.839 / 6.829 · KGK 375 / 762 · SPL 0 / 113 · pilot 6 / 6 · devir 1 / 9.

| Alan yolu | Değer | Kayıt |
|---|---|---|
| hakem2.model | claude-sonnet-5 | 12.690 |
| kor_cozum.model | claude-opus-5 | 11.901 |
| konu_giris.model | claude-sonnet-5 | 11.016 |
| simulasyon_sonnet.model | claude-sonnet-5 | 10.883 |
| sade.model | claude-haiku-4-5 | 10.369 |
| teori_ikiz.model | claude-sonnet-5 | 5.405 |
| kor_cozum.model | claude-sonnet-5 | 852 |
| aciklama_hakem.model | claude-opus-5-5 | 444 |
| kor_cozum_kaynakli.model | claude-opus-5 | 365 |
| hakem.ikinci_bakis.model | claude-sonnet-5 | 125 |
| konu_giris.model | claude-haiku-4-5 | 33 |
| simulasyon.model | claude-haiku-4-5(-20251001) | 4 |
| uyarlama.model | claude-sonnet-5 | 2 |

## 2. Dışarıda görünüyor mu

- Ambar `kalip_parti`: RLS açık, yalnız `service_role` (rag-motor/sql/011_kalip_parti.sql). Önbellek `.gitignore`'da. → üyeye görünmüyor.
- Yayın yolu (`motor/kaydir-coz.ps1`) sade / konu_giris / teori_ikiz'i **alan listesiyle** kopyalıyor, `model` kopyalanmıyor.
  Tek sızan `olcum.sim.model` idi; 919b78da'da kaynak düzeltildi + kasadan 8.571 satır silindi (ayrı oturum).

## 3. Okuyanlar (`.model` değeri)

| Betik | Ne için | Nötr koddan etkilenir mi |
|---|---|---|
| `motor/soru-karnesi.ps1` (sim + kör hücresi) | iç karnede gösterim | yalnız yazı değişir (model-b / model-c) |
| `motor/cila-parti.ps1:95`, `motor/api-hedef.ps1` | toplu İŞ kaydı / istek gövdesi, soru verisi değil | hayır |
| mantıkla (karar/eleme) okuyan | **yok** (git grep, 10.10) | — |

`simulasyon_sonnet` ANAHTARINI ~30 betik okuyor (kapılar, yayın şartı, havuz) — ad değiştirmek ayrı iş.

## 4. Yapılan (b8c9b48c)

- Nötr kod: `motor/model-kod.ps1` — haiku→`model-a`, sonnet→`model-b`, opus→`model-c`, öteki claude-*→`model-x`.
  Silmek yerine kod: kör çözümün üreticiden **farklı model** olduğu (852 sonnet / 11.901 opus) iç analizde kalır.
- Yazan yerler: `motor/kalip-parti-uret.ps1` 11 satır + `arac/aciklama-hakemi-uretim.ps1` 1 satır → `ModelKod`.
- Ağ: `arac/parti-senkron.ps1 -Yukle` ambara giden metinde `"model":"claude-…"` değerini çevirir, `MODEL-IZI: N alan` satırı basar,
  iş durdurmaz. `__` sistem kayıtları çevrilmez (api-hedef bedel için gerçek adı okur).
- Öz-sınav `arac/model-izi-sinavi.ps1` 22/22 · mutasyon 4/4 KIRMIZI (`dogrula.yml`). Kaynak taraması düzeltme ÖNCESİ dosyalarda 12/12 satırı yakaladı.
- 🚫 GÖRMEZ: iki üretici dışındaki yazıcılar (ağ yakalar) · anahtar adındaki model · düz metin içindeki ad.

Yan etki (bilerek): bulutun bundan sonra yüklediği her partinin **eski** kayıtları da yüklemede çevrilir.

## 5. ONAY BEKLEYEN: kalan partilerin toplu temizliği (bedel 0 USD)

1. `arac/bulut-kosan-etiketler.ps1 -Kati` → koşan etiketler listesi; bunlar atlanır (bulut kendi yüklemesinde zaten çevirecek).
2. Her parti için: ambardan **taze** içerik (`parti-senkron -Indir -Yaz`; yalnız ambarda daha yeni olanı indirir) →
   çevir → **koşullu** yaz (`PATCH …?etiket=eq.X&guncelleme=eq.<okunan damga>`; arada bulut yazdıysa 0 satır döner, o parti atlanır).
3. Geri sayım: aynı araç ambardan çekilen kopyada `model_alani_toplam = 0` (koşan partiler hariç) — "temiz" o rakamla yazılır.
4. Eşdeğerlik: her partide çevrilen alan dışında JSON **0 fark** (normalize kıyas); fark varsa o parti yazılmaz.

Ölçek: ≈2.339 parti; yükleme ambara giriş (egress değil). İndirme yalnız ambarda yerelden yeni partiler için (egress, ölçülmedi).
Gerekirse önce tek sınavla (KGK, 375 kayıt) prova.
