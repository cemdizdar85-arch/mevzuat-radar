# BEDEL ÇAPASI — "gerçek harcama ne kadar" sorusunun TEK cevabı

Bedel defteri (`veri/fabrika/bedel-kayit.jsonl`) **kendi kendini doğrulayamaz.** Tek doğrulayıcı,
Anthropic Console'un kendi rakamıdır. Bu dosya, Console okumalarını ve defterle farkını tutar.

**Console adresi:** https://console.anthropic.com/settings/limits (üstte "$X spent · Resets …")
Ayrıntılı kırılım: https://console.anthropic.com/settings/usage → **Cost** sekmesi.

## Çapa okumaları

| Tarih | Console (tüm hesap) | Defter (yalnız soru basımı) | Defter fazlası |
|---|---|---|---|
| 2026-09-20 18:58 | **2.537,09 USD** | 2.943,03 USD | **+405,94 USD** |

Defter, hesabın tamamından fazla sayıyordu — imkânsız, yani şişik.

## Neden şişmişti (20.09'da bulundu ve düzeltildi)

`motor/api-hedef.ps1:588` — bitmiş eski partiden **bedava** hasat yapılırken
`Get-ClaudeTopluSonuc`'un dördüncü parametresi (`bedelYaz`) verilmemişti; varsayılanı `$true`
olduğu için **zaten ödenmiş** partinin bedeli deftere bir kez daha yazılıyordu. Üreticideki
kardeş çağrı (`kalip-parti-uret.ps1:1723`) doğru yazılmıştı.

Hasat ne kadar çalışırsa defter o kadar şişiyordu: 19-20.09 hasat turlarında 243 + 250 cevap
bedavaya alındı, hepsi deftere ücret olarak düştü.

**Düzeltme:** `$false` eklendi; bedel yalnız partinin İLK çekiminde yazılır.

## Etkisi — okunurken dikkat

Bu tarihten ÖNCEKİ tüm "soru başı bedel" ölçümleri **olduğundan pahalıdır**:

| Ölçüm | Kayda geçen | Gerçek |
|---|---|---|
| Dalga 1 (20.09, 161 soru) | 0,293 USD/soru | **≤ 0,293** (üst sınır) |
| Doğrulama koşusu (20.09) | 0,328 USD/soru | ≤ 0,328 |
| A/B ölçümleri (19-20.09) | 0,317 · 0,381 USD | ≤ bu değerler |

Geçmiş defter satırlarında "bu satır hasattan mı geldi" bilgisi olmadığı için geriye dönük
temizlik YAPILAMAZ. Gerçek fiyat ancak Console çapasıyla ölçülür.

## Çapa protokolü (bundan sonra her ölçüm koşusunda)

1. Koşudan **önce** Console rakamı okunur, buraya satır eklenir.
2. Koşu biter, kasaya giren soru sayılır.
3. Koşudan **sonra** Console rakamı okunur.
4. **Gerçek soru başı bedel = (sonraki Console − önceki Console) ÷ kasaya giren soru.**

Bu dört adım, defter ne derse desin doğru rakamı verir. Console'u yalnız Cem görebiliyor;
o yüzden 1. ve 3. adım Cem'in okumasıdır.

⚠ Console rakamı TÜM hesabı kapsar. Ölçüm koşusu sırasında başka robot (OCR, marka, alacak)
çalışıyorsa fark onların harcamasını da içerir. Temiz ölçüm için koşu, başka ücretli iş
yokken yapılır.
