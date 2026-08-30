# BİRLEŞTİRME HARİTASI — 30.08.2026

> `kurtarma-30-08` dalı ile `origin/main` arasındaki farkın **ölçülmüş** haritası.
> Kuru merge denemesiyle çıkarıldı (`git merge --no-commit`, sonra `--abort`).
> Yedek: `C:\TETIKTE-YEDEK\20260830-0900\` (bundle + yama + takipsiz kopya).

## Fotoğraf

| Ölçüm | Değer |
|---|---|
| Ayrılma anı | 27.08.2026 15:04 (`ba6cd704`) |
| Yerel `main` ileri | 66 commit |
| `origin/main` ileri | 878 commit |
| Kurtarma commit'i | `310e5be7` (114 izlenen + 131 takipsiz dosya) |
| Gerçek çakışma | **89 dosya** |

## Çakışmanın dağılımı — teşhis burada

| Kova | Sayı | Karar |
|---|---:|---|
| `veri/` altı, **uzak daha büyük/eşit** | 59 | ✅ Uzağı al — robot çıktısı, en yenisi doğru |
| `veri/` altı, **uzak daha KÜÇÜK** | 21 | ⛔ ELLE BAK — küçülme veri kaybı olabilir |
| `veri/` dışı, **gerçek insan işi** | 9 | 👤 Elle birleştir |

**Çakışmanın %90'ı robot çıktısının kaynak deposunda tutulmasından geliyor.**
Üretilen çıktı kaynak deposunda tutulmaz — kalıcı çözüm bu kuralda.

## ⛔ Kova 2 — uzak sürüm küçülüyor (21 dosya, elle bakılacak)

Silme freni kuralı (27.08 robot kıyımı dersi): robot canlıyı küçültemez.
Küçülme her zaman kayıp değildir (JSON girintisi kaldırılmış olabilir) —
ama **ölçülmeden** karar verilmez.

| Dosya (`veri/` altı) | Yerel bayt | Uzak bayt | Fark |
|---|---:|---:|---:|
| konu-kaynak-karnesi.json | 1.132.000 | 655.752 | **−476.248** |
| yetki-devri-riskleri.json | 687.830 | 484.072 | −203.758 |
| yeniden-dogrula.json | 357.578 | 225.879 | −131.699 |
| mevzuat/kvkgut.json | 1.092.107 | 1.013.969 | −78.138 |
| mevzuat/_durum.json | 190.244 | 121.202 | −69.042 |
| mevzuat/kik-genel-teblig.json | 705.400 | 646.598 | −58.802 |
| teblig-damga.json | 40.840 | 28.578 | −12.262 |
| yayin-kapisi.json | 18.205 | 10.960 | −7.245 |
| tazelik-damgasi.json | 11.504 | 4.666 | −6.838 |
| mevzuat/yerli-mali-teblig.json | 54.318 | 48.905 | −5.413 |
| mevzuat/seddk-cbk47.json | 37.904 | 32.958 | −4.946 |
| veri-tazelik-raporu.json | 10.261 | 5.633 | −4.628 |
| kirik-linkler.json | 6.302 | 1.807 | −4.495 |
| parti-listesi.json | 136.116 | 131.738 | −4.378 |
| ihale-yurtici.json | 330.519 | 328.090 | −2.429 |
| goc-nobeti-raporu.json | 3.483 | 1.850 | −1.633 |
| mevzuat/kik-esik-teblig.json | 8.792 | 7.542 | −1.250 |
| teblig-damga-log.txt | 2.033 | 1.182 | −851 |
| birlik-urge.json | 7.726 | 6.982 | −744 |
| gorev-nabzi.json | 2.861 | 2.399 | −462 |
| yanveri-damga.json | 1.711 | 1.424 | −287 |

**Öncelik:** `mevzuat/` altındaki 4 dosya (kvkgut, kik-genel-teblig,
yerli-mali-teblig, seddk-cbk47) yutulmuş mevzuat metnidir — kayıp olursa
soru üretimi bozulur. Önce bunlar açılıp madde sayısı karşılaştırılmalı.

## 👤 Kova 3 — gerçek insan işi (9 dosya)

| Dosya | Not |
|---|---|
| `radar-app/sql/UYGULANDI.md` | 🔴 **GÖÇ KÜTÜĞÜ** — "hangi SQL basılı?" sorusunun tek cevabı. Yanlış birleşme canlıdan alan düşürür. İlk bu bakılır. |
| `YUTMA-LISTESI.md` | Yutma kaydı — iki taraf da satır eklemiş olabilir, ikisi de korunur |
| `kartlar.html` | Konu kartı katmanı |
| `ihale-radari.html` | İhale Radarı yüzü |
| `radar.html` | Ana radar sayfası |
| `arsiv/index.html` | Arşiv |
| `motor/soru-uret-v2.ps1` | Soru üretim motoru |
| `motor/son10-uret.ps1` | Son 10 üretimi |
| `pazarlama/linkedin-postlar.md` | İçerik — iki taraf da eklemiş olabilir |

## Sıra

1. `radar-app/sql/UYGULANDI.md` — göç kütüğü, birikimli birleştir
2. `veri/mevzuat/` altındaki 4 dosya — madde sayısı kıyaslanır
3. Kalan 17 küçülen dosya
4. 8 insan işi dosyası
5. 59 güvenli dosya toplu alınır
