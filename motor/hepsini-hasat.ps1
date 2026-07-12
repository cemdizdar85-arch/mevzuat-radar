# ============================================================================
#  HEPSINI HASAT - orkestrator: tum deterministik (zip/xml) harvest'leri
#  sirayla calistirir. TEK KOMUT ile veri/*.json yeniden uretilir.
#  Excel COM GEREKTIRMEZ -> GitHub Actions (ubuntu + pwsh) uzerinde de kosar.
#  (Istisna: tanim-hasat.ps1 Excel COM ister, orkestrasyona dahil DEGIL.)
#
#  Kullanim:
#    pwsh motor/hepsini-hasat.ps1 -RejimKlasor <rejim2026 yolu> -IgvKlasor <igv2026 yolu>
#  Klasorler verilmezse betiklerin kendi varsayilan (yerel) yollari kullanilir.
# ============================================================================
param(
  [string]$RejimKlasor = "",
  [string]$IgvKlasor = ""
)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# her harvest: ad + betik + parametreler
$isler = @(
  @{ ad="Gümrük Vergisi (sanayi, ülke)"; b="vergi-hasat-ulke.ps1"; p=@{ RejimKlasor=$RejimKlasor } },
  @{ ad="İGV (sanayi, ülke)";            b="igv-hasat-ulke.ps1";   p=@{ IgvKlasor=$IgvKlasor } },
  @{ ad="Gümrük Vergisi (tarım)";        b="tarim-hasat.ps1";      p=@{ RejimKlasor=$RejimKlasor } },
  @{ ad="Tarım Payı / EMY";              b="emy-hasat.ps1";        p=@{ RejimKlasor=$RejimKlasor } },
  @{ ad="Balık / su ürünleri (IV)";      b="balik-hasat.ps1";      p=@{ RejimKlasor=$RejimKlasor } },
  @{ ad="GV askıya alma (V)";            b="askiya-hasat.ps1";     p=@{ RejimKlasor=$RejimKlasor } },
  @{ ad="Nihai kullanım (VI/VII)";       b="nihai-hasat.ps1";      p=@{ RejimKlasor=$RejimKlasor } }
)

$basari = 0; $hata = 0; $ozet = @()
foreach($is in $isler){
  $yol = Join-Path $here $is.b
  if(-not (Test-Path $yol)){ Write-Host "ATLA: $($is.b) yok"; continue }
  # bos parametreleri ele (betik kendi varsayilanini kullansin)
  $args = @{}
  foreach($k in $is.p.Keys){ if($is.p[$k] -ne ""){ $args[$k] = $is.p[$k] } }
  Write-Host ("=== {0} ===" -f $is.ad)
  try {
    & $yol @args
    $basari++; $ozet += "OK  - $($is.ad)"
  } catch {
    $hata++; $ozet += "HATA- $($is.ad): $($_.Exception.Message)"
    Write-Host ("  HATA: {0}" -f $_.Exception.Message)
  }
}
""
"================ HEPSINI HASAT BITTI ================"
"  basarili: $basari | hatali: $hata"
$ozet | ForEach-Object { "  $_" }
if($hata -gt 0){ exit 1 }
