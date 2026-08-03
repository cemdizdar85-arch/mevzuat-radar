# DEVİR NOTU — 03.08.2026 · yeni sohbet buradan devam etsin

## Durum tek cümle
Onarım motoru hazır ve 17 kuralla donatıldı; **paralı tam parti Cem'in "bas"ını bekliyor.**
Kasaya hiçbir şey yazılmadı, site kapalı, bugüne kadar harcanan ~3 USD (4 pilot).

## Cem'in okuduğu dosya
Supabase Storage → özel kova `onarim-taslak` → **`pilot-0308-0833.html`** (200 soru).
Okuma sürüyor; bulduğu kusurların numarasını verecek.

## Cem'in bugün bulduğu ve KURALA GİRENLER (hepsi ölçülüyor)
- **D10** her yanlış şıkka ayrı düzeltme (aynı cümle yasak)
- **D11** iyi olanı bozma — istenmeyen alan atılır
- **D12** anne testi + kanun kopyası/yapay zekâ kalıbı yasağı
- **D13** hesaplı soruda yanlış rakamı tersine çöz
- **D14** hesap kodu dayanakta yoksa yazılamaz
- **D15** "Kural" parçası sınırı çizer (neler girer/girmez/ihtiyari)
- **D16** üretilen alanın birincil kaynağı istemde olacak → THP listesi istemlere eklendi
- **D17** tekdüzelik yasağı — şıklar aynı kalıpla açılamaz *(en son eklendi)*

## Ölçülmüş hata envanteri (kasa 27.478)
| Ne | Kaç |
|---|---|
| Hesap kodu kod-ad uyuşmuyor | **865 soru** |
| THP'de olmayan kod | 3.771 soru *(ayrı ölçülecek, bir kısmı meşru 7/A-7/B olabilir)* |
| "Doğrusu" eksik | 26.505 |
| Dört parça eksik | 1.248 |
| Dayanak çözülemeyen | 973 |
| Yayında olan soru | **0** — hiçbir hata öğrenciye açık değil |

## Kurulu kontroller
- `motor/yayin-kapisi.ps1` + yml — yayındaki soruda 6 kapı, DURDU ise iş kırmızı, günlük nöbet
- `motor/hesap-kodu-denetimi.ps1` + yml — THP'ye karşı denetim, haftalık nöbet
- `motor/onarim-motoru.ps1` — 9 sayaç; tetik dosyasında **`BAS`** yoksa para harcamaz
- `motor/taslak-goster.ps1` — taslak JSON + kasa → okunur HTML (0 USD)
- Belgeler: `KALITE-KAPILARI.md` (dürüst kapı envanteri) · `MUKERRER-BULGUSU.md` · `ONARIM-FIYAT-KARTI.md`

## SIRADAKİ İŞLER (yeni sohbette buradan başla)
1. Cem'in `0833` okumasından çıkan kusurları isteme işle
2. **Hakem son okuması** — istemine ekle: *"soru kökünde işlem yönü çelişkisi
   (ödeme/tahsil, borç/alacak, alış/satış) → KUSURLU"* (Cem'in Denizli Mermer bulgusu)
3. 865 yanlış kodlu soruyu Cem'e göster → onayıyla yayından çek
4. `kod_yok` 3.771'i ayrı ölç (meşru mu uydurma mı)
5. Sonra **TEK PARTİ TEK FATURA** (~115-150 USD, Cem'in "bas"ı şart)

## TASARRUF KURALI (03.08 — Cem 2 saatte 225 USD yaktı)
Maliyet pilot koşularından değil, **sohbetin uzamasından** geliyor: her mesajda tüm
geçmiş yeniden faturalanıyor. Bu yüzden:
- Sohbet uzayınca **yeni sohbet aç**, bu notla devam et
- Rutin iş (kod, ölçüm, denetim) **Sonnet**; Opus yalnız zor kararda
- **Yoklama döngüsü kurma** — "bitti mi" diye bekleme, Cem dönünce tek komutla bak
- Cevaplar kısa; tablo ve açıklama şişirme
