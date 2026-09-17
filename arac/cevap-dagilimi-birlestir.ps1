# arac/cevap-dagilimi-birlestir.ps1 — ÇIRÇIR ÖLÇÜM DOSYASI ÇAKIŞMASINI ÖLÇEREK ÇÖZER
#
# NİYE VAR (17.09.2026, koşu 35256080527 bu yüzden KIRMIZI bitti):
#   İki yayın turu üst üste koştu. İkinci tur depoyu 17:59'da çekti, birinci tur 18:16'da
#   itti; ikinci tur 18:48'de iterken `veri/cevap-dagilimi.json` ÇAKIŞTI. Sayfalar
#   (kaydir/*/*.html) ve seçim dosyaları `merge=tetikte-robot` ile sorunsuz birleşti,
#   yalnız bu dosya kaldı — çünkü `.gitattributes` onu BİLEREK dışarıda bırakıyor:
#   dosya çırçır TABANLARINI tutar, yani DURUM taşır; körlemesine "yereli al" taban
#   geçmişini bozabilir. O gerekçe doğru, bu yüzden kural değişmiyor.
#
#   Ama çakışmanın kendisi anlamsız: ölçüm fotoğrafı her koşuda sıfırdan üretiliyor,
#   taban ise `arac/cevap-dagilimi-olc.ps1` satır 185'te ZATEN `min(eski,şimdi)` ile
#   yazılıyor — yani taban yalnız AŞAĞI çekilir, asla yükselmez. İki sürümün doğru
#   birleşimi de bu: ölçüm = yeni koşunun fotoğrafı, taban = iki tarafın KÜÇÜĞÜ.
#   Bu betik tam onu yapar; kural (taban geri yükselmez) korunur.
#
# KULLANIM
#   ./arac/cevap-dagilimi-birlestir.ps1 -Bizim <yol> -Onlarin <yol> [-Cikti <yol>] [-Prova]
#   -Prova: hiçbir şey yazmaz, ne yapacağını satır satır söyler.
#   Çıkış kodu 0 = birleşti · 2 = girdi okunamadı (çağıran akış DURMALI).
param(
    [Parameter(Mandatory=$true)][string]$Bizim,      # bu koşunun taze ölçümü (çalışma kopyası)
    [Parameter(Mandatory=$true)][string]$Onlarin,    # ana teldeki sürüm (origin/main)
    [string]$Cikti = '',
    [switch]$Prova
)
$ErrorActionPreference = 'Stop'

function JsonOku([string]$yol){
    if(-not (Test-Path $yol)){ Write-Host "OKUNAMADI: $yol" -ForegroundColor Red; exit 2 }
    $ham = Get-Content $yol -Raw -Encoding UTF8
    if(-not "$ham".Trim()){ Write-Host "BOS DOSYA: $yol" -ForegroundColor Red; exit 2 }
    if($ham -match '^(<<<<<<<|=======|>>>>>>>)' -or $ham -match "`n<<<<<<< "){
        Write-Host "CAKISMA ISARETI VAR: $yol - birlestirici ham dosya ister, isaretli dosya degil" -ForegroundColor Red; exit 2
    }
    try { return ($ham | ConvertFrom-Json) } catch { Write-Host "GECERSIZ JSON: $yol - $($_.Exception.Message)" -ForegroundColor Red; exit 2 }
}

$bizimNesne   = JsonOku $Bizim
$onlarinNesne = JsonOku $Onlarin
if(-not $bizimNesne.PSObject.Properties['dersler']){ Write-Host "BIZIM SURUMDE 'dersler' YOK" -ForegroundColor Red; exit 2 }

$onlarinTaban = @{}
if($onlarinNesne.PSObject.Properties['dersler']){
    foreach($ozellik in $onlarinNesne.dersler.PSObject.Properties){
        if($ozellik.Value -and $ozellik.Value.PSObject.Properties['taban']){ $onlarinTaban[$ozellik.Name] = [double]$ozellik.Value.taban }
    }
}

$indirilen = New-Object System.Collections.Generic.List[string]
$eklenen   = New-Object System.Collections.Generic.List[string]
foreach($ozellik in $bizimNesne.dersler.PSObject.Properties){
    $dersAd = $ozellik.Name
    $ders   = $ozellik.Value
    if(-not $onlarinTaban.ContainsKey($dersAd)){ continue }
    $karsiTaban = $onlarinTaban[$dersAd]
    if(-not $ders.PSObject.Properties['taban']){
        # bizde taban yok (ilk koşu), onlarda var → onların tabanı korunur
        $ders | Add-Member -NotePropertyName 'taban' -NotePropertyValue ([Math]::Round($karsiTaban,1)) -Force
        $eklenen.Add(("{0}: taban ana telden alindi ({1:N1})" -f $dersAd,$karsiTaban)); continue
    }
    $bizimTaban = [double]$ders.taban
    if($karsiTaban -lt $bizimTaban){
        $ders.taban = [Math]::Round($karsiTaban,1)
        $indirilen.Add(("{0}: taban {1:N1} -> {2:N1} (ana tel daha iyi)" -f $dersAd,$bizimTaban,$karsiTaban))
    }
}

# ana telde olup bizde hiç olmayan ders (bekletme/silme) — tabanı kaybetmemek için taşınır
$tasinan = New-Object System.Collections.Generic.List[string]
if($onlarinNesne.PSObject.Properties['dersler']){
    foreach($ozellik in $onlarinNesne.dersler.PSObject.Properties){
        if(-not $bizimNesne.dersler.PSObject.Properties[$ozellik.Name]){
            $bizimNesne.dersler | Add-Member -NotePropertyName $ozellik.Name -NotePropertyValue $ozellik.Value -Force
            $tasinan.Add($ozellik.Name)
        }
    }
}

Write-Host "CIRCIR BIRLESTIRME"
Write-Host ("  olcum  : bizim = {0} · ana tel = {1} -> bizim (taze fotograf) korunur" -f $bizimNesne.olcum,$onlarinNesne.olcum)
Write-Host ("  taban  : indirilen {0} · ana telden alinan {1} · tasinan ders {2}" -f $indirilen.Count,$eklenen.Count,$tasinan.Count)
foreach($satir in $indirilen){ Write-Host "    $satir" }
foreach($satir in $eklenen){   Write-Host "    $satir" }
foreach($satir in $tasinan){   Write-Host "    $satir : ders ana telden tasindi (bizde yok)" }

if($Prova){ Write-Host "PROVA - hicbir sey yazilmadi" -ForegroundColor Yellow; exit 0 }

$hedef = $(if($Cikti){ $Cikti } else { $Bizim })
$metin = ($bizimNesne | ConvertTo-Json -Depth 10)
[IO.File]::WriteAllText($hedef,$metin,(New-Object System.Text.UTF8Encoding($false)))
# yaz → geri oku → karşılaştır (depo kuralı)
$geri = JsonOku $hedef
if(-not $geri.PSObject.Properties['dersler']){ Write-Host "GERI OKUMA BASARISIZ" -ForegroundColor Red; exit 2 }
$geriSayi = @($geri.dersler.PSObject.Properties).Count
$bizimSayi = @($bizimNesne.dersler.PSObject.Properties).Count
if($geriSayi -ne $bizimSayi){ Write-Host "GERI OKUMA UYUSMADI: $geriSayi != $bizimSayi" -ForegroundColor Red; exit 2 }
foreach($ozellik in $geri.dersler.PSObject.Properties){
    $karsi = $onlarinTaban[$ozellik.Name]
    if($null -ne $karsi -and $ozellik.Value.PSObject.Properties['taban'] -and [double]$ozellik.Value.taban -gt $karsi){
        Write-Host ("TABAN YUKSELDI: {0} {1} > {2} - yazma geri alinmali" -f $ozellik.Name,$ozellik.Value.taban,$karsi) -ForegroundColor Red; exit 2
    }
}
Write-Host "  yazildi ve geri okundu: $hedef ($geriSayi ders, taban yukselmedi)" -ForegroundColor Green
exit 0
