# ============================================================================
#  YUTMA FARK RAPORU (14.08) - Cem: "bitince kac madde artti soyle".
#  Tam yenilemeden sonra hangi kanunda kac madde ARTTI / AZALDI olcer.
#  "Oncesi" degerini git'ten okur (son commit'teki hali), "sonrasi" diskteki hal.
#  Boylece koşu baslamadan sayim almaya gerek kalmaz.
#
#  ARTIS  = duzeltmenin kurtardigi madde (iyi haber).
#  AZALIS = SUPHELI - desen daraltmasi bir seyi elemis olabilir, ELLE bakilir.
# ============================================================================
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
Set-Location $kok

# git'te degisen ambar dosyalari
$degisen = @(git diff --name-only -- veri/mevzuat/ 2>$null | Where-Object { $_ -match '\.json$' -and $_ -notmatch '_durum|_madde|indirme' })
Write-Host ("Degisen ambar dosyasi: {0}`n" -f $degisen.Count)
if(-not $degisen.Count){ Write-Host "Hicbir ambar dosyasi degismedi."; return }

function BelgeSay([string]$icerik){
  if(-not $icerik){ return -1 }
  try { $j = $icerik | ConvertFrom-Json; return @($j.belgeler).Count } catch { return -1 }
}
$rapor = @()
foreach($d in $degisen){
  $eskiIcerik = (git show "HEAD:$d" 2>$null) -join "`n"
  $yeniIcerik = [IO.File]::ReadAllText((Join-Path $kok $d), [Text.Encoding]::UTF8)
  $e = BelgeSay $eskiIcerik
  $y = BelgeSay $yeniIcerik
  if($e -lt 0 -or $y -lt 0){ Write-Host ("  OKUNAMADI: {0}" -f $d); continue }
  if($e -eq $y){ continue }
  $rapor += [pscustomobject]@{ dosya=(Split-Path $d -Leaf); once=$e; sonra=$y; fark=($y-$e) }
}
$artan  = @($rapor | Where-Object { $_.fark -gt 0 } | Sort-Object fark -Descending)
$azalan = @($rapor | Where-Object { $_.fark -lt 0 } | Sort-Object fark)

Write-Host ("{0,-30} {1,7} {2,7} {3,7}" -f "DOSYA","ONCE","SONRA","FARK")
Write-Host ("-"*56)
foreach($r in $artan){  Write-Host ("{0,-30} {1,7} {2,7} {3,7}" -f $r.dosya,$r.once,$r.sonra,("+"+$r.fark)) }
foreach($r in $azalan){ Write-Host ("{0,-30} {1,7} {2,7} {3,7}  <-- ELLE BAK" -f $r.dosya,$r.once,$r.sonra,$r.fark) }

$toplamArtis = ($artan  | Measure-Object fark -Sum).Sum
$toplamAzalis = ($azalan | Measure-Object fark -Sum).Sum
Write-Host ("`n=== OZET ===")
Write-Host ("  madde sayisi ARTAN kanun : {0}  (toplam +{1} madde)" -f $artan.Count, $(if($toplamArtis){$toplamArtis}else{0}))
Write-Host ("  madde sayisi AZALAN kanun: {0}  (toplam {1} madde)" -f $azalan.Count, $(if($toplamAzalis){$toplamAzalis}else{0}))
Write-Host ("  sayisi degismeyen ama icerigi degisen: {0}" -f ($degisen.Count - $rapor.Count))
if($azalan.Count){ Write-Host "`n  UYARI: azalma = desen daraltmasi bir seyi elemis olabilir. Elle dogrulanmadan 'iyi' denmez." }
