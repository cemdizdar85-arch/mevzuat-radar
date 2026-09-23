#requires -Version 5.1
<#
================================================================================
  KONU ÖRNEKLEM KAPISI — ÖZ-SINAV   (23.09.2026) · bedel 0
  Kapı bozulursa model "HAYIR" dediği her soru elle bakılmadan yeniden etiketlenir (kısmi karnede doğru etiketlilerin
  %17'sine HAYIR demişti). Vakalar: örneklem yok / damga farklı / okunmamış kayıt / yanlış oranı eşiği / YANLIŞ dışlanır /
  belirlenimli seçim / asgari 5.
  ⛔ REPLİKA YOK: gerçek arac/konu-orneklem-kapisi.ps1 dot-source edilir.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'konu-orneklem-kapisi.ps1')
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function Orn([string]$damga, [string[]]$dogruAn, [string[]]$yanlisAn) {
  $k = @(); foreach ($a in $dogruAn) { $k += [pscustomobject]@{ an = $a; karar = 'DOĞRU' } }; foreach ($a in $yanlisAn) { $k += [pscustomobject]@{ an = $a; karar = 'YANLIŞ' } }
  [pscustomobject]@{ damga = $damga; kayitlar = $k }
}
$ad20 = @(1..20 | ForEach-Object { "p/kp-{0:D2}" -f $_ }); $ad60 = @(1..60 | ForEach-Object { "q/kp-{0:D2}" -f $_ })
$s20 = @(OrneklemSec $ad20 'D1'); $s60 = @(OrneklemSec $ad60 'D1')
T 'asgari 5: 20 adayda örneklem 5' ($s20.Count -eq 5)
T '%10 yukarı yuvarlanır: 60 adayda 6' ($s60.Count -eq 6)
T 'belirlenimli: aynı damga → aynı örneklem' ((@(OrneklemSec $ad20 'D1') -join ',') -eq ($s20 -join ','))
T 'damga değişince örneklem değişir' ((@(OrneklemSec $ad20 'D2') -join ',') -ne ($s20 -join ','))
T 'aday < 5 → hepsi' ((@(OrneklemSec @('a', 'b', 'c') 'D1')).Count -eq 3)
$kYok = OrneklemKapisi $ad20 $null 'D1'
T 'örneklem yok → İZİN YOK ve sebep "örneklem yok" (ne yapılacağını söyler)' ((-not $kYok.izin) -and "$($kYok.sebep)" -like 'örneklem yok*')
T 'damga farklı (model yeniden koştu) → İZİN YOK' (-not (OrneklemKapisi $ad20 (Orn 'ESKI' $s20 @()) 'D1').izin)
T 'bir kayıt okunmamış → İZİN YOK' (-not (OrneklemKapisi $ad20 (Orn 'D1' @($s20 | Select-Object -First 4) @()) 'D1').izin)
T 'örneklem dışı kimlik okunmuş sayılmaz → İZİN YOK' (-not (OrneklemKapisi $ad20 (Orn 'D1' @(@($s20 | Select-Object -First 4) + @($ad20 | Where-Object { $s20 -notcontains $_ } | Select-Object -First 1)) @()) 'D1').izin)
T 'hepsi DOĞRU → İZİN' ((OrneklemKapisi $ad20 (Orn 'D1' $s20 @()) 'D1').izin)
T '1/5 YANLIŞ (%20 > %10) → İZİN YOK' (-not (OrneklemKapisi $ad20 (Orn 'D1' @($s20 | Select-Object -First 4) @($s20[4])) 'D1').izin)
$k60 = OrneklemKapisi $ad60 (Orn 'D1' @($s60 | Select-Object -First 5) @($s60[5])) 'D1'
T '1/6 YANLIŞ (%16,7 > %10) → İZİN YOK' (-not $k60.izin)
$ad100 = @(1..100 | ForEach-Object { "r/kp-{0:D3}" -f $_ }); $s100 = @(OrneklemSec $ad100 'D1')
$k100 = OrneklemKapisi $ad100 (Orn 'D1' @($s100 | Select-Object -First 9) @($s100[9])) 'D1'
T '1/10 YANLIŞ (%10, eşik dahil) → İZİN, YANLIŞ olan dışlanır' ($k100.izin -and (@($k100.disla) -contains $s100[9]) -and @($k100.disla).Count -eq 1)
T 'aday yok → izin (yazılacak bir şey yok)' ((OrneklemKapisi @() $null 'D1').izin)
# TAM OKUMA: hepsi okunduysa oran aranmaz, YANLIŞ'lar dışlanır
$yarim = @($ad20 | Select-Object -First 10); $obur = @($ad20 | Select-Object -Skip 10)
$kTam = OrneklemKapisi $ad20 (Orn 'D1' $yarim $obur) 'D1'
T 'tam okuma: 20 adayın hepsi okundu, %50 YANLIŞ → İZİN, 10 YANLIŞ dışlanır' ($kTam.izin -and @($kTam.disla).Count -eq 10 -and -not (@($kTam.disla) | Where-Object { $yarim -contains $_ }))
$disari = @($ad20 | Where-Object { $s20 -notcontains $_ }); $okunmayan = $disari[0]
$dogruK = @($ad20 | Where-Object { $_ -ne $okunmayan -and $_ -ne $s20[0] })
T 'tam okuma eksik (19/20, örneklem dışı 1 okunmamış) → örneklem kuralı: 1/5 YANLIŞ → İZİN YOK' (-not (OrneklemKapisi $ad20 (Orn 'D1' $dogruK @($s20[0])) 'D1').izin)
T 'tam okuma da damga ister' (-not (OrneklemKapisi $ad20 (Orn 'ESKI' $yarim $obur) 'D1').izin)
$top = $gecti + $dustu.Count
Write-Host "KONU ÖRNEKLEM KAPISI ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
