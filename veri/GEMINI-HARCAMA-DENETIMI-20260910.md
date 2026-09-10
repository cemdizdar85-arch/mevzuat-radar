# Gemini API harcama denetimi — musluk nerede?

*10.09.2026 · kaynak: Google AI Studio → Spend + Billing, Google Cloud Console → Billing*
*Hesap: My Billing Account · ID 0164F4-11A39B-C34906 · Proje: Default Gemini Project (tek proje)*

## Sonuç tek cümlede

**₺920,78'in ₺870,29'u (%94,5) VİDEO ÜRETİMİDİR** — Veo 3 Fast + Veo 3 Lite.
Soru üretimi, gömme ve mevzuat işi bu paranın içinde **görünmüyor bile**.

## Rakamlar

| Kalem | Tutar | Pay |
|---|---:|---:|
| **Veo 3 Fast Generate** (video) | **₺831,78** | **%90,3** |
| **Veo 3 Lite Generate** (video) | **₺38,51** | **%4,2** |
| Veo 3 Generate | ₺0,00 | — |
| Nano Banana Pro (görsel) | ₺0,00 | — |
| Gemini Embedding 1 (RAG motoru) | ₺0,00 * | — |
| Ölçülmeyen diğer modeller | ₺50,49 | %5,5 |
| **TOPLAM (14.08 – 10.09)** | **₺920,78** | %100 |

\* Bugünkü 637 vektörlük gömme koşusu henüz faturaya yansımadı (Google 24 saate
kadar gecikme bildiriyor). Liste fiyatından hesabı: 637 parça × ~600 jeton ≈
380 bin jeton ≈ **₺2–3**. Ölçüldüğünde bu satır tazelenecek.

## Zaman: paranın tamamı EYLÜL'DE gitti

- 14–31 Ağustos: **₺0,00**
- 1–10 Eylül: **₺920,78**

Yani "geçmişten sızan bir musluk" yok. Para bu ayın ilk on gününde, video
denemelerinde yandı. Bu, hafızadaki iki kayıtla birebir örtüşüyor:
09.09'da `uret.ps1` sınama amacıyla çalıştırılınca gerçek üretim başlamış ve
5,75 USD gitmişti; "ucuz prova" kuralı da o gün doğmuştu.

## 🔴 EN ÖNEMLİ BULGU — ₺3.000/AY TAVAN AÇIK

AI Studio → Spend sayfasında:

```
Monthly spend cap:  TRY 921,98 / TRY 3.000,00
```

Ayrıca hesap düzeyinde ayrı bir tavan daha var:
**TRY 12.033,80 Billing Account Tier Cap.**

Bugünkü harcama tavanın **%30,7'si**. Yani aynı hızda devam eden bir video
denemesi, hiçbir uyarı çıkmadan bu ay **₺3.000'e kadar** gidebilir. Musluk
kapalı değil, sadece henüz sonuna gelinmemiş.

## Yanlış hipotezin kapanışı

Dün "robotlar Gemini kredisini yakıyor" diye bir hipotez kurulmuştu. **Yanlıştı**
ve Usage grafiği onu çürütmüştü: 28 günde birkaç yüz istek, ~780'i zaten 404.
Bugünkü Spend ölçümü aynı sonucu ikinci kez doğruluyor: metin/gömme modellerinin
faturadaki payı ölçülebilir düzeyde bile değil. **Suçlu robotlar değil, video.**

## Google Cloud tarafı temiz

Cloud Console → Billing → Reports (Eylül 1–9, servis bazında): **₺0,00**.
Uyarı bandı: *"You are now incurring charges in your billing account as of
September 7, 2026."* Gemini API prepay harcaması Cloud maliyet raporlarında
görünmez; bu yüzden orada bakan biri "hiç para harcanmamış" sanır. Doğru yer
**AI Studio → Spend**'dir.

## Öneriler

1. **Tavanı işin gerçek büyüklüğüne indir.** ₺3.000 bir kaza tavanı. Video işi
   fiilen durduğu sürece ₺500 fazlasıyla yeter; video basılacağı gün Cem'in
   kararıyla yükseltilir. Tek ekrandan yapılıyor: Spend → *Edit spend cap*.
2. **Video anahtarını mevzuat anahtarından ayır.** Spend sayfası API anahtarı
   bazında da süzebiliyor. Ayrı anahtar = ayrı ölçüm = "hangi iş ne yaktı"
   sorusunun tahminsiz cevabı.
3. **Prova kuralını mekanik kapıya çevir.** "Önce 8 sn 480p prova" bugün yazılı
   bir kural; `uret.ps1` bunu kendi kontrol etmiyor. Kural yazmak işin yarısı,
   mekanik kapı diğer yarısı.
