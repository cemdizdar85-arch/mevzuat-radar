#requires -Version 5.1
<#
================================================================================
  DAMGA DEĞİŞİM TÜRÜ — ÖZ-SINAV   (23.09.2026) · bedel 0

  NİYE VAR: soru-dayanak nöbetçisi "damga farklı"yı "metin değişti" sayıyordu. 22.09'da 12 maddeye
  "değişti" dedi, 414 soru yayından çekildi; 7'sinde yalnız parça DİZİLİŞİ kaymıştı. Yeni ayrım
  (arac/mevzuat-degisti.ps1 MdDamgaDegisimi) dizilişi ve AYRI kayıt eklenmesini değişiklik saymaz.
  Bu ayrım yanlış kurulursa GERÇEK bir kanun değişikliği sessizce geçer — sınav ikisini de ölçer:
  yakalaması gereken (metin değişti, madde uzadı, iz yok) + yanlış alarm vermemesi gereken (diziliş, ayrı kayıt).

  ⛔ REPLİKA YOK: gerçek arac/mevzuat-degisti.ps1 dot-source edilir.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'mevzuat-degisti.ps1')

function G([string]$damga, [string[]]$izler) { [pscustomobject]@{ damga = $damga; parca_izleri = $izler } }
$A = 'k1:aaaa'; $B = 'k1:bbbb'; $C = 'k2:cccc'; $B2 = 'k1:b222'

$vaka = @(
  # --- YAKALAMASI GEREKENLER (gerçek değişiklik kaçmamalı) ---
  @{ ad = 'bir parçanın metni değişti'; e = (G 'd1' @($A, $B)); y = (G 'd2' @($A, $B2)); bek = 'degisti' }
  @{ ad = 'madde uzadı: AYNI kaydın devam parçası eklendi ([3/3])'; e = (G 'd1' @($A, $B)); y = (G 'd2' @($A, $B, 'k1:yeni')); bek = 'degisti' }
  @{ ad = 'eski taban parça izi taşımıyor → ölçülemez, temkinli'; e = (G 'd1' @()); y = (G 'd2' @($A, $B)); bek = 'degisti' }
  @{ ad = 'yeni damga parça izi taşımıyor → temkinli'; e = (G 'd1' @($A, $B)); y = (G 'd2' @()); bek = 'degisti' }
  @{ ad = 'çok-küme: eskide aynı parça iki kez, yenide bir kez'; e = (G 'd1' @($A, $A)); y = (G 'd2' @($A)); bek = 'degisti' }
  @{ ad = 'bir parça düştü'; e = (G 'd1' @($A, $B, $C)); y = (G 'd2' @($A, $B)); bek = 'degisti' }
  @{ ad = 'anahtar yok'; e = (G 'd1' @($A)); y = $null; bek = 'silindi' }
  # --- YANLIŞ ALARM VERMEMESİ GEREKENLER ---
  @{ ad = 'damga aynı'; e = (G 'd1' @($A, $B)); y = (G 'd1' @($A, $B)); bek = 'ayni' }
  @{ ad = 'yalnız diziliş kaydı (22.09 vakası)'; e = (G 'd1' @($A, $B)); y = (G 'd2' @($B, $A)); bek = 'sira' }
  @{ ad = 'aynı anahtara AYRI kayıt eklendi (mük. m.121 vakası)'; e = (G 'd1' @($A, $B)); y = (G 'd2' @($A, $C, $B)); bek = 'ekleme' }
  @{ ad = 'sözlük (madde-damga bellek tablosu) ile JSON nesnesi karışık'; e = (G 'd1' @($A, $B)); y = ([ordered]@{ damga = 'd2'; parca_izleri = @($B, $A) }); bek = 'sira' }
)
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
foreach ($v in $vaka) {
  $c = MdDamgaDegisimi $v.e $v.y
  if ($c -eq $v.bek) { $gecti++; if (-not $Sessiz) { Write-Host "  geçti $($v.ad) → $c" } } else { $dustu.Add("$($v.ad): çıktı '$c', beklenen '$($v.bek)'") }
}
# ad kökü
foreach ($k in @(@('GVK (193 s.K.) muk. m.121 [2/4]', 'GVK (193 s.K.) muk. m.121'), @('VUK (213 s.K.) m.370 - İzaha davet [1/2]', 'VUK (213 s.K.) m.370 - İzaha davet'), @('X m.5 (2)', 'X m.5'), @('X m.5', 'X m.5'))) {
  if ((MdAdKoku $k[0]) -eq $k[1]) { $gecti++ } else { $dustu.Add("MdAdKoku '$($k[0])' → '$(MdAdKoku $k[0])' (beklenen '$($k[1])')") }
}
$top = $vaka.Count + 4
Write-Host "DAMGA DEĞİŞİM ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
