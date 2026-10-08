# AÇILIŞ GÜNÜ — TEK LİSTE (site: SGS + Yeterlilik)

> 07.10.2026, Cem "1.2.3 üçünü de yap" (madde 3). Sıra atlanmaz; her adımın yanında **kim** yapar.
> Cem'in kuralı: kart açık olmadan site açılmaz. Her adımdan sonra telefon + bilgisayar görüntüsüne bakılır.

## 0 · Kart denemesi — açılıştan ÖNCE

| # | İş | Kim |
|---|---|---|
| 0.1 | Gerçek kartla alım: `https://tetikte.com/satin-al.html?paket=yeterlilik-1&kart=1&kapi=tetikte2026` | **Cem** (kart bilgisini yalnız Cem girer) |
| 0.2 | Sipariş kaydı · ödeme durumu · paketin hesaba açılması · fatura maili doğrulanır | Claude |
| 0.3 | iyzico panelinden iade | **Cem** |
| 0.4 | `yonetim.html`'de sipariş "İade edildi" | Claude |

0.2 tutmazsa açılış durur; arıza önce giderilir.

## 1 · Kartı aç — tek satır

`fiyat-motoru.js` → `var KART_ACIK = true;` (07.10'dan beri **tek yer**; satın al sayfası ve fiyat sayfası buradan okur).

Bu satırla **kendiliğinden** değişenler (07.10'da `?kart=1` ile ölçüldü):

- satın al: kartla öde düğmesi · üstteki güven satırı ("Kartla ya da havale/EFT") · sipariş düğmesi altındaki not · havale başlığı ("Ya da havale/EFT ile öde")
- fiyat sayfası: "Nasıl ödenir" kutusu (kart + havale, kart bilgisi iyzico'da)
- ön bilgilendirme / mesafeli satış / teslimat-iade: kartı zaten yazıyor (değişmez)

Sınav sayfalarında elle kalan havale metni: **yok** (07.10 taraması `[Hh]avale|EFT`: yalnız bu bayrağa bağlı yerler, sözleşmeler,
havale siparişinin kendi durumu — öğrenci sayfası "ödemen kontrol ediliyor" — ve yönetim paneli). `radar-fiyat.html` (işletme radarı,
açılışta gizli) yalnız havale yazar; o ürün açılırken ayrıca bakılır.

## 2 · Kartı açtıktan sonra bak (Claude)

Bilgisayar 1280×760 + telefon 375 genişlik, ekran görüntüsüyle:

`index.html` · `fiyat.html?sinav=sgs` · `fiyat.html?sinav=yeterlilik` · `satin-al.html?paket=sgs` ·
`satin-al.html?paket=yeterlilik-1` · `seviye-testi.html` · `seviye-testi.html?sinav=yeterlilik` · `ogrenci.html` ·
`gunun-sorusu.html` · `kaydir/vitrin/sgs.html` · `kaydir/vitrin/smmm.html`

Ayrıca: `node motor/canli-tarama.js --taban https://tetikte.com` ve `node motor/sabah-kontrol.js` (YEŞİL/SARI satırları okunur).

## 3 · Perdeyi kaldır — İKİ KOMUT, SIRAYLA (Cem "AÇ" deyince)

> 08.10 denetimi: liste yalnız gong'u yazıyordu; `seviye-testi.html` ve `sorular.html` 13.09'dan kalma `noindex` taşıyor,
> bunu yalnız `acilis-seo.ps1 -Ac` kaldırır. Gong tek başına koşsaydı iki ana sayfa Google'a kapalı kalırdı.

| # | İş | Kim |
|---|---|---|
| 3.1 | `powershell -NoProfile -File arac/acilis-seo.ps1 -Ac` → `DENETIM: YESIL` görülür → `git add seviye-testi.html sorular.html sitemap.xml robots.txt` + commit (`acilis-seo` dosyaya yazar, commit etmez) | Claude |
| 3.2 | `powershell -NoProfile -File motor/gong.ps1` — perde (menu.js) + önizleme sınırsızlığı + robots.txt (metin `arac/robots-yaz.ps1`'den: iç klasörler + gizli sayfalar Disallow). Kendisi commit + push eder. | Claude |
| 3.3 | 2 dk sonra gizli pencerede `tetikte.com` perdesiz mi · `robots.txt` Allow mu · `seviye-testi.html` kaynağında noindex yok mu; telefon + bilgisayar görüntüsü | Claude |

Pages `Cache-Control: max-age=600` → eski `menu.js` (perde) tarayıcılarda **10 dk** kalabilir; bu normaldir, 17.10 sınavı için gong en geç 09:15.
Geri dönüş: iki commit `git revert` ile geri alınır.

## 4 · Açılış sonrası ilk gün

- Captcha paneli: 05.10'da kapatıldı (uygulama token alamıyordu) — açmak Cem'in panel işi, ayrıntı hafızada.
- Sabah kontrolü SARI satırları: ana sayfa soruları (düşen soru) · Yeterlilik seviye seti ("okunmadı" soru).
- İlk gerçek siparişte 0.2'deki dört nokta yeniden doğrulanır.
