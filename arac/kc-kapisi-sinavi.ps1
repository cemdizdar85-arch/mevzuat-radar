#requires -Version 5.1
<#
================================================================================
  KAPI-KC (Kaydır-Çöz eksiksizlik) — ÖZ-SINAV   24.09.2026 · bedel 0
  Kapı bitirme yayın şartında soru DÜŞÜRÜR. Yanlış kurulursa ya eksik soru siteye girer (Nöbetçi boş kart gösterir) ya da
  sağlam sorular düşer. Eşdeğerlik (24.09, bütün SMMM taslakları): kapı yalnız sitede taranıp eksik bulunan 11 soruyu düşürdü.
  ⛔ REPLİKA YOK: gerçek arac/smmm-yayin-sarti.ps1 dot-source edilir (SmmmKcEksik).
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1')
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function Tam {
  $ac = [pscustomobject]@{ A = 'A Tuzağı: …'; B = 'B Tuzağı: …'; C = 'Ne soruluyor … Kural: …'; D = 'D Tuzağı: …'; E = 'E Tuzağı: …' }
  $te = [pscustomobject]@{ A = [pscustomobject]@{ ayirt = 'x' }; B = [pscustomobject]@{ ayirt = 'x' }; D = [pscustomobject]@{ ayirt = 'x' }; E = [pscustomobject]@{ ayirt = 'x' } }
  return [pscustomobject]@{ soru = 's'; dogru = 'C'; siklar = [pscustomobject]@{ A = 'a'; B = 'b'; C = 'c'; D = 'd'; E = 'e' }; aciklama = $ac; teshis = $te
    sade = [pscustomobject]@{ dogru = 'sade anlatım' }; adimlar = @('adım 1', 'adım 2'); dayanak = 'VUK m.313' }
}
function Eksik($v) { return @(SmmmKcEksik $v) }
# K3: yayın şartındaki çağrının BİREBİR biçimi (atama + @()); sarmalayıcı işlev dönüşü açtığı için K3'ü gizler.
$kcEksik = @(SmmmKcEksik (Tam))
T 'eksiksiz soru → 0 eksik (K3 gerilemesi: ", dizi" dönüşü burada 1 derdi)' ($kcEksik.Count -eq 0)
$v = Tam; $v.aciklama = $null
T 'açıklama alanı HİÇ yok (kp-07 vakası) → 5 şık eksik' ((Eksik $v).Count -eq 5)
$v = Tam; $v.aciklama.D = ''
T 'yalnız bir YANLIŞ şıkkın açıklaması boş (w6/kp-17 vakası) → eksik' ((Eksik $v) -contains 'açıklama D')
$v = Tam; $v.teshis.PSObject.Properties.Remove('B')
T 'bir yanlış şıkkın teşhisi yok → eksik' ((Eksik $v) -contains 'teşhis B')
$v = Tam
T 'doğru şıkkın teşhisi olmaması eksik SAYILMAZ' (-not ((Eksik $v) -contains 'teşhis C'))
$v = Tam; $v.dayanak = ' '
T 'dayanak boş → eksik' ((Eksik $v) -contains 'dayanak')
$v = Tam; $v.sade = [pscustomobject]@{ dogru = '' }
T 'sade anlatım boş → eksik' ((Eksik $v) -contains 'sade anlatım')
$v = Tam; $v.adimlar = @()
T 'adımlar yok → eksik' ((Eksik $v) -contains 'adımlar')
$v = Tam; $v.aciklama.A = [pscustomobject]@{ tuzak = 'Yapılı Tuzağı: …'; dogrusu = '' }
T 'yapılı (nesne) açıklama, alanı dolu → eksik değil' (-not ((Eksik $v) -contains 'açıklama A'))
$top = $gecti + $dustu.Count
Write-Host "KAPI-KC ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
