# KONU KAPSAMA TABLOSU (10.09.2026, Cem: "ders, o dersin konusu, sınavda çıkmış soru sayısı ve
# yanına bizim şu an oluşturduğumuz soru") — 0 USD, hiçbir model çağrısı yok, ağ çağrısı yok.
#
# Sütunlar:
#   1) SINAVDA CIKAN SORU : konunun pencerede kaç SORU olarak çıktığı (veri/sgs-analiz.json → donemler[].konuSayim)
#   2) CIKTIGI DONEM      : kaç ayrı sınavda çıktığı
#   3) YAZDIGIMIZ SORU    : havuzda o konuya yazılmış soru (huni etiketKasaSay, kök eşleşmeli)
#   4) KAPI-TEMIZ         : bunların kaç tanesi kapılardan temiz çıkmış (huni etiketTemizSay)
#   5) KAT                : yazdığımız soru / sınavda çıkan soru — aşırı basımı gösterir
#
# 10.09 DÜZELTME (Cem: "sınavda kaç kere çıktığını istemiştim"): ilk sürüm yalnız DÖNEM sayısını
# yazıyordu. Gerçek soru sayısı sgs-analiz.json'da duruyordu; huni onu okuyup ATIYOR, yalnız
# dönem sayısını saklıyordu. Bu betik ham sayımı doğrudan analiz dosyasından toplar.
#
# 10.09 BULGU (Cem: "niye böyle saçma sapan şeyler var, biz her konuda basacağımız soruyu
# hesaplamıştık"): pencerede 1 soru çıkmış 'preposition kullanimi' konusuna 237, 'ilgi zamiri
# whose' konusuna 124 soru basılmış. KAT sütunu bu israfı görünür kılmak için eklendi.
#
# Kullanım:
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1 -DonemPencere 10
#
# Çıktı: veri/fabrika/konu-kapsama.csv + ekrana ders özeti ve en aşırı basılan konular.

param([int]$DonemPencere=7, [string]$Ders='', [switch]$Sessiz)
$ErrorActionPreference='Stop'
$kok = Split-Path $PSScriptRoot -Parent

# --- huni ile AYNI katlama ve kök çıkarma (motor/eski-sgs-huni.ps1'den birebir) ---
function Katla2([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
function KokOnek([string]$s){
  $t=(Katla2 $s) -replace '[^a-z0-9 ]',' '
  $es=@{ 'evre'='safha'; 'gug'='genel'; 'ilk'='ilk'; 'dimm'='ilk'; 'esdeger'='esdeger' }
  @(($t -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|ile|veya|icin|bir|olan|sistemi|yontemi|sistem|yontem|hesaplama|hesabi|kaydi|kayit|analizi|analiz|orani|oran|tablosu|tablo|muhasebesi|muhasebe)$' } | ForEach-Object { $w=$_; if($es.ContainsKey($w)){ $w=$es[$w] }; if($w.Length -gt 5){ $w.Substring(0,5) } else { $w } } | Select-Object -Unique)
}

# --- 1) sinav analizi: donem donem konu -> SORU SAYISI ---
$anYol = Join-Path $kok 'veri\sgs-analiz.json'
if(-not (Test-Path $anYol)){ Write-Host "veri/sgs-analiz.json yok - olculemez." -ForegroundColor Red; exit 1 }
$an = ConvertFrom-Json -InputObject (Get-Content $anYol -Raw -Encoding UTF8)
$dList = New-Object System.Collections.Generic.List[object]
$an.donemler | ForEach-Object { $dList.Add($_) }
$sonD = @($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $DonemPencere)

$etiket = @{}   # kok anahtari -> @{ ad; bolum; donemler=@{}; soru=int }
foreach($dn in $sonD){
  foreach($p in @($dn.konuSayim.PSObject.Properties)){
    $bol = ($p.Name -split '\|')[0]
    $lab = ($p.Name -replace '^[^|]*\|','')
    $kk  = (KokOnek $lab) -join ' '
    if(-not $kk){ continue }
    if(-not $etiket.ContainsKey($kk)){ $etiket[$kk]=@{ ad=$lab; bolum=$bol; donemler=@{}; soru=0 } }
    $etiket[$kk].donemler["$($dn.donem)"] = 1
    $etiket[$kk].soru += [int]$p.Value
  }
}
$pencereAd = (@($sonD | ForEach-Object { $_.donem }) -join ' ')
if(-not $Sessiz){ Write-Host ("analiz: sgs-analiz.json | pencere ({0} donem): {1} | konu: {2}" -f $DonemPencere, $pencereAd, $etiket.Count) }

# --- 2) huni: ayni konuya bizim kac soru yazdigimiz ---
$huniYol = (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
if(-not $huniYol){ Write-Host "huni dosyasi yok." -ForegroundColor Red; exit 1 }
$h = ConvertFrom-Json -InputObject (Get-Content $huniYol.FullName -Raw -Encoding UTF8)
if(-not $Sessiz){ Write-Host ("huni: {0}" -f $huniYol.Name) }

# --- 3) birlestir ---
$satirlar = New-Object System.Collections.Generic.List[object]
foreach($kk in $etiket.Keys){
  $ad = $etiket[$kk].ad
  $ka = Katla2 $ad
  $ders = "$($h.etiketDers.$ka)" -replace '\*$',''
  if(-not $ders){ $ders = "[$($etiket[$kk].bolum)]" }
  if($Ders -and $ders -notmatch $Ders){ continue }
  $bizim  = $(if($h.etiketKasaSay.PSObject.Properties[$ka]){ [int]$h.etiketKasaSay.$ka } else { 0 })
  $temiz  = $(if($h.etiketTemizSay.PSObject.Properties[$ka]){ [int]$h.etiketTemizSay.$ka } else { 0 })
  $cikan  = [int]$etiket[$kk].soru
  $satirlar.Add([pscustomobject]@{
    ders            = $ders
    konu            = $ad
    sinavda_cikan   = $cikan
    ciktigi_donem   = $etiket[$kk].donemler.Count
    yazdigimiz_soru = $bizim
    kapi_temiz      = $temiz
    kat             = $(if($cikan -gt 0){ [math]::Round($bizim / $cikan, 1) } else { '' })
  })
}
$sirali = @($satirlar | Sort-Object ders, @{Expression='sinavda_cikan'; Descending=$true}, konu)

$csv = Join-Path $kok 'veri\fabrika\konu-kapsama.csv'
$sirali | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("CSV yazildi: {0} ({1} satir)" -f $csv, $sirali.Count) -ForegroundColor Green

# --- 4) ders ozeti ---
Write-Host ""
Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,6}" -f 'DERS','konu','cikan','yazdik','temiz','kat')
Write-Host ("-" * 74)
foreach($g in ($sirali | Group-Object ders | Sort-Object { -($_.Group | Measure-Object -Property yazdigimiz_soru -Sum).Sum })){
  $ck = ($g.Group | Measure-Object -Property sinavda_cikan   -Sum).Sum
  $yz = ($g.Group | Measure-Object -Property yazdigimiz_soru -Sum).Sum
  $tm = ($g.Group | Measure-Object -Property kapi_temiz      -Sum).Sum
  $kt = $(if($ck -gt 0){ [math]::Round($yz/$ck,1) } else { 0 })
  Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,6}" -f $g.Name, $g.Count, $ck, $yz, $tm, $kt)
}
Write-Host ("-" * 74)
$tCk = ($sirali | Measure-Object -Property sinavda_cikan   -Sum).Sum
$tYz = ($sirali | Measure-Object -Property yazdigimiz_soru -Sum).Sum
$tTm = ($sirali | Measure-Object -Property kapi_temiz      -Sum).Sum
Write-Host ("{0,-32} {1,5} {2,8} {3,8} {4,8} {5,6}" -f 'TOPLAM', $sirali.Count, $tCk, $tYz, $tTm, $([math]::Round($tYz/[Math]::Max($tCk,1),1)))

# --- NAMUS SATIRI: kok eslesmesi bir soruyu birden cok konuya sayar ---
Write-Host ""
Write-Host "UYARI - 'yazdik' sutunu KOK eslesmelidir: bir soru birden cok konuya sayilabilir." -ForegroundColor Yellow
Write-Host ("  Bu yuzden konu toplami ({0}) havuzdaki gercek SGS soru sayisindan buyuk cikar." -f $tYz) -ForegroundColor Yellow
$havuzYol = Join-Path $kok 'veri\fabrika\eski-sgs-dump-20260907.json'
if(Test-Path $havuzYol){
  $hv = @(ConvertFrom-Json -InputObject (Get-Content $havuzYol -Raw -Encoding UTF8))
  if($hv.Count -eq 1 -and $hv[0].PSObject.Properties['SyncRoot']){ $hv=@($hv[0].SyncRoot) }
  Write-Host ("  Cift saymayan gercek sayi: havuzda {0} SGS sorusu, sinavda {1} soru cikmis -> {2} kat." -f $hv.Count, $tCk, [math]::Round($hv.Count/[Math]::Max($tCk,1),1)) -ForegroundColor Yellow
}

# --- 5) en asiri basilan konular ---
Write-Host ""
Write-Host "EN ASIRI BASILAN 15 KONU (yazdigimiz / sinavda cikan):"
foreach($x in (@($sirali | Where-Object { $_.sinavda_cikan -gt 0 }) | Sort-Object { -[double]$_.kat } | Select-Object -First 15)){
  Write-Host ("  {0,-28} {1,-34} cikan {2,2} -> yazdik {3,4} ({4} kat)" -f $x.ders, $x.konu, $x.sinavda_cikan, $x.yazdigimiz_soru, $x.kat)
}
