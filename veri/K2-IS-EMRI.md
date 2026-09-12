# K2 İŞ EMRİ — `@(... | ConvertFrom-Json)` dizi sarma

> Ölçüm 12.09.2026. Üretici: `arac/tuzak-nobetcisi.ps1` K2-JSONDIZI.
> Bu dosya ELLE yazıldı (ölçüm raporu), robot çıktısı değildir. Kapatıldıkça tazelenir.

## Durum

| | adet |
|---|---|
| İlk ölçüm | 76 |
| Yorum satırı (kuraldan ayıklandı) | −7 |
| **`.Count` okuyanlar — KAPATILDI** (commit `2f7b8e3c`) | **−24** |
| **KALAN** | **45** |

## Tuzak GERÇEK — ölçüldü (PS 5.1.26100, bu makine)

| ifade | dizi | tek nesne | boş dizi |
|---|---|---|---|
| `@($m \| ConvertFrom-Json)` | **1** ❌ | 1 | **1** ❌ |
| `@(($m \| ConvertFrom-Json))` | 3 ✅ | 1 ✅ | 0 ✅ |
| `$h = $m \| ConvertFrom-Json; @($h)` | 3 ✅ | 1 ✅ | 0 ✅ |

Üye erişimi (`$x[0].a`) yine `1,2,3` verir — **bazı betiklerin kazara çalışmasının
sebebi budur**. Sayı ve döngü her zaman yanlıştır.

## ÇARE — fazladan bir parantez

```powershell
@($m | ConvertFrom-Json)      # BOZUK
@(($m | ConvertFrom-Json))    # DOĞRU
```

`return` ve `foreach` bağlamında da doğrulandı (3/1/0 · döngü 3, boşta 0).
Deyim yapısını hiç bozmadığı için seçildi.

⛔ **`return ,@($h)` YANLIŞTIR** — virgül yeniden sarar, çağıran yine 1 görür (ölçüldü).
⛔ **`$( $t=...; @($t) )` alt ifadesi** tek nesnede boş döner — kullanılmaz.

## Niye hepsi birden kapatılmadı

Kalan 45'in çoğu **canlı robot**. Sarma düzeltilince döngüler gerçekten N kez
dönecek — bugün 1 kez dönen bir döngü yarın 30 API çağrısı yapabilir. Kusurun
düzelmesidir ama **her betikte ayrı doğrulama ister**. Önce sayı üretenler
kapatıldı (yanlış rakam bu depoda en ağır kusur), gerisi sırayla.

**Sıra:** `return` edenler (24) → döngüler (3) → sayı okumayan atamalar (14) → diğer (4).
Her biri kendi commit'inde, öncesi/sonrası sayı ölçülerek.

## Kalan satırlar (45)

| dosya | satır | biçim | kod |
|---|---|---|---|
| `acilis-tekduzelik-olcum.ps1` | 50 | return | `return @($m \| ConvertFrom-Json)` |
| `alacak-ilan-okuyucu-pilot.ps1` | 92 | foreach | `foreach ($row in @($ham.Content \| ConvertFrom-Json)) { $ilanlar += $row }` |
| `bildirim-nobeti.ps1` | 49 | return | `return @($ham \| ConvertFrom-Json)` |
| `bosluk-dogrulama.ps1` | 46 | return | `return @($m \| ConvertFrom-Json)` |
| `cila-parti.ps1` | 170 | atama | `if(Test-Path $iy){ $mevcut=@(Get-Content $iy -Raw -Encoding UTF8 \| ConvertFrom-Json) }` |
| `ders-remap.ps1` | 124 | atama | `$g2=@(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 \| ConvertFrom-Json) …` |
| `destek-takip-nobeti.ps1` | 51 | diger | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing…` |
| `formul-eksik-tarama.ps1` | 42 | return | `return @($m \| ConvertFrom-Json)` |
| `gorsel-backfill.ps1` | 129 | atama | `$g2 = @(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 \| ConvertFrom-Json…` |
| `gozetim-onarici.ps1` | 212 | atama | `$bek = @(Get-Content $bYol -Raw -Encoding UTF8 \| ConvertFrom-Json)` |
| `hakem-son-okuma.ps1` | 55 | return | `return @($m \| ConvertFrom-Json)` |
| `hakem-son-okuma.ps1` | 208 | atama | `$geri = @($m2 \| ConvertFrom-Json \| Where-Object { $null -ne $_ }).Count` |
| `hesap-kodu-denetimi.ps1` | 51 | return | `return @($m \| ConvertFrom-Json)` |
| `iki-sinav-konu-karsilastirma.ps1` | 51 | return | `return @($m \| ConvertFrom-Json)` |
| `kapsam-maliyet-olcum.ps1` | 44 | return | `return @($m \| ConvertFrom-Json)` |
| `kardes-kaynak-cikar.ps1` | 41 | return | `return @($m \| ConvertFrom-Json)` |
| `kasa-sayim.ps1` | 295 | atama | `$py = @($gp \| ConvertFrom-Json)` |
| `konu-dagilim-olcum.ps1` | 46 | return | `return @($m \| ConvertFrom-Json)` |
| `kurulus-nobet-postacisi.ps1` | 42 | return | `return @($ham \| ConvertFrom-Json)` |
| `marka-ayna-hasat.ps1` | 198 | return | `return @($t \| ConvertFrom-Json)` |
| `marka-portfoy-durum.ps1` | 27 | diger | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing…` |
| `marka-portfoy-hasat.ps1` | 663 | return | `return @($ham \| ConvertFrom-Json)` |
| `marka-watch-kullanici.ps1` | 31 | diger | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing…` |
| `mukerrer-ele.ps1` | 46 | return | `return @($m \| ConvertFrom-Json)` |
| `olc-uslup.ps1` | 24 | diger | `$topla += @($ham \| ConvertFrom-Json)` |
| `onarim-motoru.ps1` | 81 | return | `return @($m \| ConvertFrom-Json)` |
| `onarim-motoru.ps1` | 1699 | atama | `$geriOkuma = @($mo \| ConvertFrom-Json \| Where-Object { $null -ne $_ }).Count` |
| `profesor-v2.ps1` | 140 | foreach | `foreach($x in @(Get-Content $haric -Raw -Encoding UTF8 \| ConvertFrom-Json)){ $atla["$x"] = 1 }` |
| `profesor-v2.ps1` | 156 | foreach | `foreach($x in @(Get-Content $idler -Raw -Encoding UTF8 \| ConvertFrom-Json)){ $ist["$x"] = 1 }` |
| `sik-hesap-kodu-oneri.ps1` | 57 | return | `return @($m \| ConvertFrom-Json)` |
| `sik-hesap-kodu-uygula.ps1` | 63 | return | `return @($m \| ConvertFrom-Json)` |
| `sik-istatistigi.ps1` | 41 | return | `return @($m \| ConvertFrom-Json)` |
| `sinav-ders-envanteri.ps1` | 51 | return | `return @($m \| ConvertFrom-Json)` |
| `soru-denetci-k2.ps1` | 86 | atama | `$rY = Join-Path $kok "veri/soru-denetci-rapor.json"; $gY=@(); if(Test-Path $rY){ try{ $gY=@(Get…` |
| `soru-denetci-k2.ps1` | 180 | atama | `$gecmis = @(); if(Test-Path $raporYol){ try{ $gecmis = @(Get-Content $raporYol -Raw -Encoding U…` |
| `soru-uret.ps1` | 345 | atama | `if($js){ try{ $uretilen = @($js \| ConvertFrom-Json) }catch{} }` |
| `soru-uret-v2.ps1` | 1060 | atama | `if(Test-Path $bpYol){ try { $bpListe = @(Get-Content $bpYol -Raw -Encoding UTF8 \| ConvertFrom-J…` |
| `tablo-format-tarama.ps1` | 43 | return | `return @($m \| ConvertFrom-Json)` |
| `terim-taramasi.ps1` | 46 | return | `return @($m \| ConvertFrom-Json)` |
| `terim-uygula.ps1` | 61 | return | `return @($m \| ConvertFrom-Json)` |
| `thp-liste-maliyet-olcum.ps1` | 47 | return | `return @($m \| ConvertFrom-Json)` |
| `toplu-uret.ps1` | 333 | atama | `if($js){ try{ $uretilen = @($js \| ConvertFrom-Json) }catch{} }` |
| `yayin-kapisi.ps1` | 75 | return | `return @($m \| ConvertFrom-Json)` |
| `yonetmelik-ambar-sayim.ps1` | 53 | atama | `$j = @($m \| ConvertFrom-Json)` |
| `zorluk-uret-prova.ps1` | 203 | atama | `$alarm=@(); if(Test-Path $alarmY){ $alarm=@(Get-Content $alarmY -Raw -Encoding UTF8 \| ConvertFr…` |
