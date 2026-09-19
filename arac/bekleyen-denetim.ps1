# arac/bekleyen-denetim.ps1 — HASAT EDİLMEMİŞ TOPLU PARTİLERDE NE VAR? (bedel 0)
#
# NİYE VAR (17-19.09.2026, Cem "1 yap" = "önce hasat, sonra kural"): `veri/bekleyen-partiler.json`
# 532 kaydı "hasat edilmedi" diye tutuyor (SGS 247 · SMMM 285). Bu kayıtlar ÖDENMİŞ iş demek olabilir
# — ama olmayabilir de: parti sonradan başka halkada tamamlanmış ve yalnız defter satırı bayat kalmış
# olabilir. Hangisi olduğunu TAHMİNLE söylemek yasak; bu betik Anthropic toplu uçlarından durumu OKUR
# (ücretsiz: yalnız durum sorgusu, sonuç indirilmez) ve kaç istek gerçekten alınmayı beklediğini sayar.
#
# ⛔ PARA HARCAMAZ: yalnız GET /v1/messages/batches/<id> çağrılır. Sonuç gövdesi indirilmez, istek
#    gönderilmez, hiçbir parti dosyası yazılmaz. Çıktı: sayım + CSV.
# ⛔ GÜNLÜĞE SORU METNİ BASILMAZ (bulut güvenlik kuralı 2): yalnız id, etiket, durum, adet yazılır.
#
# KULLANIM
#   powershell -NoProfile -File arac/bekleyen-denetim.ps1 [-Sinav sgs|smmm|hepsi] [-Cikti <csv yolu>]
# ÇIKIŞ KODU: 0 = ölçüldü · 2 = anahtar/dosya yok (çağıran akış DURMALI)
param(
    [string]$Sinav = 'hepsi',
    [string]$Cikti = '',
    [int]$Tavan = 0                 # 0 = hepsi; sınamak için küçük bir sayı verilebilir
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$burasi = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $burasi

function OrtamOku([string]$ad){
    $deger = [Environment]::GetEnvironmentVariable($ad,'User')
    if(-not $deger){ $deger = [Environment]::GetEnvironmentVariable($ad,'Process') }
    if(-not $deger){ $deger = [Environment]::GetEnvironmentVariable($ad,'Machine') }
    return $deger
}
$anahtar = OrtamOku 'ANTHROPIC_API_KEY'
if(-not $anahtar){ Write-Host 'ANTHROPIC_API_KEY yok - durum sorgusu yapilamaz' -ForegroundColor Red; exit 2 }
$basliklar = @{ 'x-api-key' = $anahtar; 'anthropic-version' = '2023-06-01' }

$defterYol = Join-Path $depoKok 'veri\bekleyen-partiler.json'
if(-not (Test-Path $defterYol)){ Write-Host "bekleyen defteri yok: $defterYol" -ForegroundColor Red; exit 2 }
# ⛔ K2: @(ifade | ConvertFrom-Json) PS 5.1'de diziyi TEK ögeye sarar - once degiskene, sonra @(( )) ile
$defterHam = Get-Content $defterYol -Raw -Encoding UTF8
$kayitlar = @(($defterHam | ConvertFrom-Json))
$bekleyen = @($kayitlar | Where-Object { "$($_.durum)" -notmatch '^hasat edildi' -and "$($_.durum)" -notmatch '^iptal' })
if($Sinav -ne 'hepsi'){ $bekleyen = @($bekleyen | Where-Object { "$($_.etiket)" -like "$Sinav-*" }) }
if($Tavan -gt 0 -and $bekleyen.Count -gt $Tavan){ $bekleyen = @($bekleyen | Select-Object -First $Tavan) }
Write-Host "hasat edilmemis kayit: $($bekleyen.Count) (defterde toplam $($kayitlar.Count))"
if(-not $bekleyen.Count){ Write-Host 'olculecek kayit yok'; exit 0 }

$satirlar = New-Object System.Collections.Generic.List[object]
$sira = 0
foreach($kayit in $bekleyen){
    $sira++
    if($sira % 25 -eq 0){ Write-Host "  ...$sira/$($bekleyen.Count)" -ForegroundColor DarkGray }
    $partiId = "$($kayit.id)"
    $durum = ''; $bitti = 0; $hata = 0; $iptal = 0; $sure = 0; $islenen = 0; $sonucVar = $false; $notu = ''
    try{
        $cevap = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$partiId" -Headers $basliklar -TimeoutSec 60
        $durum = "$($cevap.processing_status)"
        if($cevap.request_counts){
            $bitti = [int]$cevap.request_counts.succeeded
            $hata  = [int]$cevap.request_counts.errored
            $iptal = [int]$cevap.request_counts.canceled
            $sure  = [int]$cevap.request_counts.expired
            $islenen = [int]$cevap.request_counts.processing
        }
        $sonucVar = [bool]"$($cevap.results_url)"
    }catch{
        $durum = 'SORGU DUSTU'
        $notu = "$($_.Exception.Message)"
        if($notu -match '404'){ $durum = 'YOK (404 - parti silinmis/suresi gecmis)' }
    }
    $satirlar.Add([pscustomobject]@{
        id = $partiId; etiket = "$($kayit.etiket)"; defter_durum = "$($kayit.durum)"; zaman = "$($kayit.zaman)"
        parti_durum = $durum; basarili = $bitti; hatali = $hata; iptal = $iptal; suresi_gecmis = $sure; islenen = $islenen
        sonuc_alinabilir = $sonucVar; not = $notu
    })
    Start-Sleep -Milliseconds 120   # uca nazik davran
}

$cikisYol = $(if($Cikti){ $Cikti } else { Join-Path $env:TEMP ("bekleyen-denetim-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".csv") })
$satirlar | Export-Csv -Path $cikisYol -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host 'PARTI DURUMU (adet)'
foreach($oberk in ($satirlar | Group-Object parti_durum | Sort-Object Count -Descending)){
    Write-Host ("  {0,-42} {1}" -f $oberk.Name, $oberk.Count)
}
$hasatlik = @($satirlar | Where-Object { $_.parti_durum -eq 'ended' -and $_.sonuc_alinabilir -and [int]$_.basarili -gt 0 })
$istekTop = 0; foreach($satir in $hasatlik){ $istekTop += [int]$satir.basarili }
Write-Host ''
Write-Host ("HASAT EDILEBILIR: {0} parti · {1} basarili istek (odenmis, sonucu duruyor)" -f $hasatlik.Count, $istekTop) -ForegroundColor Green
Write-Host 'SINAV KIRILIMI'
foreach($oberk in ($hasatlik | Group-Object -Property { ("$($_.etiket)" -split '-')[0] } | Sort-Object Count -Descending)){
    $altTop = 0; foreach($satir in $oberk.Group){ $altTop += [int]$satir.basarili }
    Write-Host ("  {0,-8} {1,4} parti · {2,5} istek" -f $oberk.Name, $oberk.Count, $altTop)
}
Write-Host ''
Write-Host "CSV: $cikisYol"
exit 0
