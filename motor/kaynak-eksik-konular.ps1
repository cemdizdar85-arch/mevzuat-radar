# ============================================================================
#  KAYNAK EKSIK KONULAR — "maddesiz kaldigi icin ATLANAN konu" is emri
#
#  NEDEN VAR (10.09.2026 olcumu): uretim raporlarinin `hazirlik.planSatir` ve
#  `hazirlik.maddesiz` alanlari toplandiginda cikan sayi:
#      15.058 plan satiri  ->  4.425'i MADDESIZ  =  %29,4
#  Yani plana giren her uc konudan biri, konusu zor oldugu icin degil, ARAMA
#  MADDEYI BULAMADIGI icin dusuyor. soru-uret-v2.ps1 o satiri atliyor ve
#  raporun `maddesiz_konular` alanina yaziyor - ama oradan HICBIR YERE
#  gitmiyor. Bir sonraki kosu ayni konuyu yeniden atliyor. Kayit var, IS EMRI
#  yok.
#
#  Bu betik o kaydi is emrine cevirir: butun uretim raporlarini tarar,
#  {ders, konu} ciftlerini toplar, KAC KEZ atlandigini sayar ve
#  veri/kaynak-eksik-konular.json'a yazar. Cok atlanan konu = en cok kaybettiren
#  arama kusuru; siralamayi o belirler.
#
#  ONEMLI: bu dosya "bu konularin kaynagi ambarda YOK" demez. "ARAMA
#  BULAMADI" der. Ikisi ayni sey degil - 03.09 dayanak ad koprusu olcumu
#  "bulunmayan"larin cogunun ad farki oldugunu gostermisti. Hangisi oldugunu
#  arac/konu-getirme-karnesi.ps1 olcer.
#
#  CIKTI: veri/kaynak-eksik-konular.json
#  KOSMA: powershell -NoProfile -File motor/kaynak-eksik-konular.ps1
# ============================================================================
param(
  [int]$EnAz = 1   # bu kadar ve daha cok atlanan konular yazilir
)
$ErrorActionPreference = 'Stop'

$kok = Split-Path -Parent $PSScriptRoot
$veri = Join-Path $kok 'veri'
$hedef = Join-Path $veri 'kaynak-eksik-konular.json'
. (Join-Path $kok 'arac\rapor-yaz.ps1')

$raporlar = @(Get-ChildItem (Join-Path $veri 'uretim-rapor-*.json') -ErrorAction SilentlyContinue)
if($raporlar.Count -eq 0){ Write-Host 'KOR: veri/uretim-rapor-*.json bulunamadi.'; exit 3 }

# --- 1) Toplama ------------------------------------------------------------
# Iki ayri sayi tutulur ve KARISTIRILMAZ:
#   planToplam/maddesizToplam : butun raporlarin sayaclari (kapsam olcusu)
#   $kayit                    : konu ADI yazilmis raporlardan gelen liste
# Sebebi: raporlarin bir kismi sayaci yaziyor ama ADI yazmiyor. Ad yazilmayan
# rapordaki atlamalar listede GORUNMEZ - bunu "yok" sanmamak icin ayri sayilir.
$kayit = @{}
$planToplam = 0; $maddesizToplam = 0; $adliRapor = 0; $adsizRapor = 0

foreach($r in $raporlar){
  try { $j = Get-Content $r.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if($j.hazirlik){
    $planToplam     += [int]$j.hazirlik.planSatir
    $maddesizToplam += [int]$j.hazirlik.maddesiz
  }
  $liste = @($j.maddesiz_konular)
  if($liste.Count -eq 0){
    if($j.hazirlik -and [int]$j.hazirlik.maddesiz -gt 0){ $adsizRapor++ }
    continue
  }
  $adliRapor++
  foreach($k in $liste){
    $ders = "$($k.ders)".Trim()
    $konu = "$($k.konu)".Trim()
    if($konu -eq ''){ continue }
    $anahtar = ($ders + '|' + $konu).ToLower([System.Globalization.CultureInfo]::GetCultureInfo('tr-TR'))
    if(-not $kayit.ContainsKey($anahtar)){
      $kayit[$anahtar] = [pscustomobject]@{ ders=$ders; konu=$konu; kez=0; raporlar=New-Object System.Collections.ArrayList }
    }
    $kayit[$anahtar].kez++
    [void]$kayit[$anahtar].raporlar.Add($r.Name)
  }
}

# --- 2) Siralama -----------------------------------------------------------
# En cok atlanan once: her atlama, o konuda uretilmemis soru demek.
$konular = @($kayit.Values | Where-Object { $_.kez -ge $EnAz } | Sort-Object -Property @{Expression='kez';Descending=$true}, @{Expression='ders'}, @{Expression='konu'} |
  ForEach-Object { [pscustomobject]@{ ders=$_.ders; konu=$_.konu; kez=$_.kez; raporlar=@($_.raporlar | Select-Object -Unique) } })

$derse = @($konular | Group-Object ders | Sort-Object Count -Descending |
  ForEach-Object { [pscustomobject]@{ ders=$_.Name; tekil_konu=$_.Count; toplam_atlama=(($_.Group | Measure-Object kez -Sum).Sum) } })

$cikti = [ordered]@{
  olcum        = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama     = 'MADDESIZ kaldigi icin plandan ATLANAN konular. "kaynak ambarda yok" DEMEK DEGILDIR - "arama maddeyi bulamadi" demektir. Hangisi oldugunu arac/konu-getirme-karnesi.ps1 olcer.'
  kapsam       = [ordered]@{
    rapor_sayisi        = $raporlar.Count
    plan_satiri_toplam  = $planToplam
    maddesiz_toplam     = $maddesizToplam
    maddesiz_orani_yuzde= $(if($planToplam -gt 0){ [math]::Round(100*$maddesizToplam/$planToplam,1) } else { 0 })
    konu_adi_yazan_rapor= $adliRapor
    konu_adi_YAZMAYAN_rapor = $adsizRapor
    uyari               = $(if($adsizRapor -gt 0){ "$adsizRapor raporda maddesiz sayaci dolu ama konu ADI yazilmamis - o atlamalar asagidaki listede GORUNMUYOR. Liste alt sinirdir." } else { '' })
  }
  tekil_konu   = $konular.Count
  derse_gore   = $derse
  konular      = $konular
}

$yazildi = RaporYaz -Hedef $hedef -Nesne $cikti -ZamanAlanlari @('olcum')
Write-Host ("KAYNAK EKSIK KONULAR: {0} tekil konu / {1} rapor" -f $konular.Count, $raporlar.Count)
Write-Host ("  plan satiri {0:N0} -> maddesiz {1:N0} (%{2})" -f $planToplam, $maddesizToplam, $cikti.kapsam.maddesiz_orani_yuzde)
if($adsizRapor -gt 0){ Write-Host ("  UYARI: {0} raporda konu adi yok - liste ALT SINIRDIR" -f $adsizRapor) -ForegroundColor Yellow }
if($yazildi){ Write-Host "  -> veri/kaynak-eksik-konular.json yazildi" } else { Write-Host "  -> icerik ayni, dosyaya dokunulmadi" }
