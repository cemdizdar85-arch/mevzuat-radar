# K2 İŞ EMRİ — `@(... | ConvertFrom-Json)` dizi sarma (ölçüm 12.09.2026)

> Üretici: `arac/tuzak-nobetcisi.ps1` K2-JSONDIZI. Bu dosya ELLE yazıldı (ölçüm raporu),
> robot çıktısı değildir. Kapatıldıkça satır silinir.

## Tuzak GERÇEK — ölçüldü (PS 5.1.26100, bu makine)

| ifade | sonuç | doğrusu |
|---|---|---|
| `@('[{"a":1},{"a":2},{"a":3}]' \| ConvertFrom-Json).Count` | **1** | 3 |
| önce değişkene al, sonra `@($h).Count` | 3 | 3 |
| `foreach($r in @($json \| ConvertFrom-Json))` dönme sayısı | **1** | 3 |
| `function F{ return @($j \| ConvertFrom-Json) }` → `@(F).Count` | **1** | 3 |
| `@('[]' \| ConvertFrom-Json).Count` | **1** | 0 |

Üye numaralandırması (`$x[0].a`) yine `1,2,3` verir — **bazı betiklerin kazara
çalışmasının sebebi budur**. Sayı ve döngü her zaman yanlıştır.

## DOĞRU ÇARE (üç durumda da doğrulandı)

```powershell
$ham = <ifade> | ConvertFrom-Json     # ÖNCE DEĞİŞKENE
$d   = @($ham)                        # SONRA SAR
```
Ölçüm: dizi → 3 · tek nesne → 1 · boş dizi → 0. Hepsi doğru.

⛔ `return ,@($h)` YANLIŞTIR — virgül yeniden sarar, çağıran yine 1 görür (ölçüldü).
Kutsanmış sürüm: `arac/olcum-kapilari.ps1` > `JsonDizi`.

## NİYE TOPTAN DÜZELTİLMEDİ

69 yerin çoğu **canlı robot** (`destek-takip-nobeti`, `alacak-*`, `bildirim-nobeti`…).
Sarma düzeltilince döngüler gerçekten N kez dönecek — yani **davranış değişecek**:
bugün 1 kez dönen bir döngü yarın 30 kez dönüp 30 API çağrısı yapabilir. Bu, kusurun
düzelmesidir ama **her betikte ayrı doğrulama ister**. Tek commit'te 60 dosyaya
dokunmak, ölçülmemiş bir davranış değişikliğini toptan canlıya sürmek olurdu.

**Sıra önerisi:** önce `.Count` okuyan 24 satır (yanlış SAYI üretiyorlar — bu depoda
en kötü kusur tipi), sonra `return` edenler, en son döngüler. Her biri kendi
commit'inde, öncesi/sonrası sayı ölçülerek.

## Sınıflandırma (69 bulgu)

| biçim | adet | not |
|---|---|---|
| `$x = @(...)` | 38 | bunların **24'ü sonrasında `.Count` okuyor** → yanlış sayı üretiyor |
| `return @(...)` | 24 | çağıran `@(F).Count` = 1 görür (ölçüldü) |
| `foreach (@(...))` | 3 | döngü 1 kez döner |
| diğer | 4 | elle bakılacak |

Yorum satırları (7) kuraldan ayıklandı — tuzağı ANLATAN yorumu kusur sayıyordu.

## Satırlar

| dosya | satır | kod |
|---|---|---|
| `aciklama-sozlesme-olcum.ps1` | 57 | `$r = @($metin \| ConvertFrom-Json)` |
| `acilis-tekduzelik-olcum.ps1` | 50 | `return @($m \| ConvertFrom-Json)` |
| `alacak-damga-olcum.ps1` | 48 | `$rows = @($ham.Content \| ConvertFrom-Json)` |
| `alacak-ilan-okuyucu-pilot.ps1` | 92 | `foreach ($row in @($ham.Content \| ConvertFrom-Json)) { $ilanlar += $row }` |
| `alacak-ilan-okuyucu-pilot.ps1` | 139 | `$rows = @($ham.Content \| ConvertFrom-Json)` |
| `b7-tani.ps1` | 60 | `$liste = @($gv \| ConvertFrom-Json)` |
| `bildirim-nobeti.ps1` | 49 | `return @($ham \| ConvertFrom-Json)` |
| `bosluk-dogrulama.ps1` | 46 | `return @($m \| ConvertFrom-Json)` |
| `cila-parti.ps1` | 170 | `if(Test-Path $iy){ $mevcut=@(Get-Content $iy -Raw -Encoding UTF8 \| ConvertFrom-Json) }` |
| `denetim-500.ps1` | 126 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `ders-remap.ps1` | 124 | `$g2=@(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 \| ConvertFrom-Json) }catc…` |
| `destek-takip-nobeti.ps1` | 51 | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing -Tim…` |
| `destek-takip-nobeti.ps1` | 61 | `$parca = @($ham \| ConvertFrom-Json)` |
| `dogrusu-ekle.ps1` | 46 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `formul-eksik-tarama.ps1` | 42 | `return @($m \| ConvertFrom-Json)` |
| `gorsel-backfill.ps1` | 129 | `$g2 = @(); if(Test-Path $rp){ try{ $g2=@(Get-Content $rp -Raw -Encoding UTF8 \| ConvertFrom-Json) }ca…` |
| `gozetim-onarici.ps1` | 212 | `$bek = @(Get-Content $bYol -Raw -Encoding UTF8 \| ConvertFrom-Json)` |
| `hakem-son-okuma.ps1` | 55 | `return @($m \| ConvertFrom-Json)` |
| `hakem-son-okuma.ps1` | 208 | `$geri = @($m2 \| ConvertFrom-Json \| Where-Object { $null -ne $_ }).Count` |
| `hesap-kodu-denetimi.ps1` | 51 | `return @($m \| ConvertFrom-Json)` |
| `iki-sinav-konu-karsilastirma.ps1` | 51 | `return @($m \| ConvertFrom-Json)` |
| `kapsam-maliyet-olcum.ps1` | 44 | `return @($m \| ConvertFrom-Json)` |
| `kardes-kaynak-cikar.ps1` | 41 | `return @($m \| ConvertFrom-Json)` |
| `kasa-desen-olcum.ps1` | 47 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `kasa-sayim.ps1` | 267 | `$y = @($g2 \| ConvertFrom-Json)` |
| `kasa-sayim.ps1` | 295 | `$py = @($gp \| ConvertFrom-Json)` |
| `kasa-sayim.ps1` | 327 | `$dk = @($gkk \| ConvertFrom-Json)` |
| `kaynak-onarim.ps1` | 56 | `$liste = @($ham \| ConvertFrom-Json)` |
| `konu-dagilim-olcum.ps1` | 46 | `return @($m \| ConvertFrom-Json)` |
| `konu-eslesme.ps1` | 74 | `$r = @($mt \| ConvertFrom-Json)` |
| `kurulus-nobet-postacisi.ps1` | 42 | `return @($ham \| ConvertFrom-Json)` |
| `marka-ayna-hasat.ps1` | 198 | `return @($t \| ConvertFrom-Json)` |
| `marka-portfoy-durum.ps1` | 27 | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing -Tim…` |
| `marka-portfoy-hasat.ps1` | 663 | `return @($ham \| ConvertFrom-Json)` |
| `marka-watch-kullanici.ps1` | 31 | `function SbGet($yol){ $w=Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UseBasicParsing -Tim…` |
| `mukerrer-ele.ps1` | 46 | `return @($m \| ConvertFrom-Json)` |
| `olc-sinav-dagilim.ps1` | 27 | `$liste = @($ham \| ConvertFrom-Json)   # assign-then-wrap: @(IRM) tuzagi degil` |
| `olc-sinav-dagilim.ps1` | 52 | `$l2 = @($h2 \| ConvertFrom-Json)` |
| `olc-sinav-dagilim.ps1` | 76 | `$l3 = @($h3 \| ConvertFrom-Json)` |
| `olc-uslup.ps1` | 24 | `$topla += @($ham \| ConvertFrom-Json)` |
| `onarim-motoru.ps1` | 81 | `return @($m \| ConvertFrom-Json)` |
| `onarim-motoru.ps1` | 1699 | `$geriOkuma = @($mo \| ConvertFrom-Json \| Where-Object { $null -ne $_ }).Count` |
| `profesor-v2.ps1` | 140 | `foreach($x in @(Get-Content $haric -Raw -Encoding UTF8 \| ConvertFrom-Json)){ $atla["$x"] = 1 }` |
| `profesor-v2.ps1` | 156 | `foreach($x in @(Get-Content $idler -Raw -Encoding UTF8 \| ConvertFrom-Json)){ $ist["$x"] = 1 }` |
| `sgs-kota-kur.ps1` | 145 | `$dilim = @($govde \| ConvertFrom-Json)` |
| `sik-hesap-kodu-oneri.ps1` | 57 | `return @($m \| ConvertFrom-Json)` |
| `sik-hesap-kodu-uygula.ps1` | 63 | `return @($m \| ConvertFrom-Json)` |
| `sik-istatistigi.ps1` | 41 | `return @($m \| ConvertFrom-Json)` |
| `sinav-ders-envanteri.ps1` | 51 | `return @($m \| ConvertFrom-Json)` |
| `soru-denetci-k2.ps1` | 86 | `$rY = Join-Path $kok "veri/soru-denetci-rapor.json"; $gY=@(); if(Test-Path $rY){ try{ $gY=@(Get-Cont…` |
| `soru-denetci-k2.ps1` | 180 | `$gecmis = @(); if(Test-Path $raporYol){ try{ $gecmis = @(Get-Content $raporYol -Raw -Encoding UTF8 \|…` |
| `soru-istatistik.ps1` | 36 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `soru-uret.ps1` | 345 | `if($js){ try{ $uretilen = @($js \| ConvertFrom-Json) }catch{} }` |
| `soru-uret-v2.ps1` | 1060 | `if(Test-Path $bpYol){ try { $bpListe = @(Get-Content $bpYol -Raw -Encoding UTF8 \| ConvertFrom-Json) …` |
| `tablo-format-tarama.ps1` | 43 | `return @($m \| ConvertFrom-Json)` |
| `teori-esleme-olcum.ps1` | 73 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `terim-taramasi.ps1` | 46 | `return @($m \| ConvertFrom-Json)` |
| `terim-uygula.ps1` | 61 | `return @($m \| ConvertFrom-Json)` |
| `thp-liste-maliyet-olcum.ps1` | 47 | `return @($m \| ConvertFrom-Json)` |
| `toplu-uret.ps1` | 333 | `if($js){ try{ $uretilen = @($js \| ConvertFrom-Json) }catch{} }` |
| `vitrin-sec.ps1` | 55 | `$liste = @($ham \| ConvertFrom-Json)` |
| `yayina-ac.ps1` | 108 | `$liste = @($ham \| ConvertFrom-Json)` |
| `yayindan-cek.ps1` | 30 | `$liste = @($ham \| ConvertFrom-Json)` |
| `yayin-denetim.ps1` | 65 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `yayin-kapisi.ps1` | 75 | `return @($m \| ConvertFrom-Json)` |
| `yayin-sifirla.ps1` | 43 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `yillik-rakam-nobeti.ps1` | 59 | `$l = @($ham \| ConvertFrom-Json); if($l.Count -eq 0){ break }` |
| `yonetmelik-ambar-sayim.ps1` | 53 | `$j = @($m \| ConvertFrom-Json)` |
| `zorluk-uret-prova.ps1` | 203 | `$alarm=@(); if(Test-Path $alarmY){ $alarm=@(Get-Content $alarmY -Raw -Encoding UTF8 \| ConvertFrom-Js…` |
