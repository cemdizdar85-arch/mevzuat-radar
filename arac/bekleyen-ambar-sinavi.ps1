#requires -Version 5.1
<#
  BEKLEYEN PARTİ AMBAR KAYDI — ÖZ-SINAV (23.09.2026) · bedel 0 · ağ çağrısı YOK
  Niye: 23.09 04:04–04:12 UTC GitHub makineleri çöktü; parti kayıtları yalnız makinede olduğu için w9/w10'un
  ödenmiş sonuçları sahipsiz kaldı. Kayıt artık gönderildiği anda ambara, parti başına AYRI satıra yazılıyor.
  Sınav: satır gövdesi doğru mu (etiket, SISTEM, parmak izi taşıyor, SORU METNİ TAŞIMIYOR) ve koşu başı
  birleştirme doğru mu (yeni kayıt eskiyi günceller, durumu dolu olan kazanır, hiç kayıt kaybolmaz).
  ⛔ REPLİKA YASAK: fonksiyonlar gerçek dosyalardan AST ile çıkarılır.
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
function FnMetin([string]$dosya, [string[]]$adlar) {
  $t = $null; $h = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $kok $dosya), [ref]$t, [ref]$h)
  if ($h -and $h.Count) { throw "$dosya ayrıştırılamadı: $($h[0].Message)" }
  $o = @(); foreach ($ad in $adlar) { $f = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad }, $true); if (-not @($f).Count) { throw "$ad bulunamadı ($dosya)" }; $o += @($f)[0].Extent.Text }
  return ($o -join "`n")
}
. ([scriptblock]::Create((FnMetin 'motor\api-hedef.ps1' @('BekleyenAmbarGovde')) + "`n" + (FnMetin 'arac\bekleyen-senkron.ps1' @('DiziyeCevir', 'Birlestir'))))

$gecen = 0; $toplam = 0; $kalan = New-Object System.Collections.Generic.List[string]
function Vaka([string]$ad, [bool]$ok) { $script:toplam++; if ($ok) { $script:gecen++; if (-not $Sessiz) { "  OK    $ad" } } else { $script:kalan.Add($ad); if (-not $Sessiz) { "  DÜŞTÜ $ad" } } }

$k = [pscustomobject]@{ id = 'msgbatch_TEST1'; etiket = 'smmm-w10-1-fmuh-zor/A'; zaman = '2026-09-23 08:00'; durum = 'gonderildi'; parmak = [pscustomobject]@{ 'kp-01' = 'abc123'; 'kp-02' = 'def456' } }
$g = BekleyenAmbarGovde $k
Vaka 'gövde etiketi parti başına ayrı satır: __bekleyen/<id>' ("$($g.etiket)" -eq '__bekleyen/msgbatch_TEST1')
Vaka 'gövde sınavı SISTEM (soru sayımlarına girmez)' ("$($g.sinav)" -eq 'SISTEM')
Vaka 'gövde parti kimliğini + etiketi + parmak izini taşır' ("$($g.icerik.partiler[0].id)" -eq 'msgbatch_TEST1' -and "$($g.icerik.partiler[0].etiket)" -eq 'smmm-w10-1-fmuh-zor/A' -and "$($g.icerik.partiler[0].parmak.'kp-02')" -eq 'def456')
$js = ConvertTo-Json -InputObject $g -Depth 8 -Compress
Vaka 'gövde SORU METNİ taşımaz (soru/siklar/metin/aciklama alanı yok)' (-not ($js -match '"(soru|siklar|metin|aciklama_soru|cevap)"\s*:'))
Vaka 'kimliksiz kayıt için gövde üretilmez' ($null -eq (BekleyenAmbarGovde ([pscustomobject]@{ id = ''; etiket = 'x' })))

# birleştirme
$tekSatir = @([pscustomobject]@{ id = 'A'; etiket = 'e'; zaman = '1'; durum = 'hasat edildi' }, [pscustomobject]@{ id = 'B'; etiket = 'e'; zaman = '1'; durum = 'gonderildi' })
$partiSat = @([pscustomobject]@{ id = 'B'; etiket = 'e'; zaman = '2'; durum = 'hasat edildi' }, [pscustomobject]@{ id = 'C'; etiket = 'e'; zaman = '3'; durum = 'gonderildi' }, [pscustomobject]@{ id = 'A'; etiket = 'e'; zaman = '1'; durum = '' })
$b = @(Birlestir $partiSat $tekSatir)
$h = @{}; foreach ($x in $b) { $h["$($x.id)"] = $x }
Vaka 'birleşim: hiç kayıt kaybolmaz (A, B, C)' ($h.Count -eq 3 -and $h.ContainsKey('A') -and $h.ContainsKey('B') -and $h.ContainsKey('C'))
Vaka 'birleşim: parti satırındaki YENİ durum eski tek satırı günceller (B → hasat edildi)' ("$($h['B'].durum)" -eq 'hasat edildi')
Vaka 'birleşim: durumu BOŞ kayıt, durumu dolu olanı ezmez (A hasat edildi kalır)' ("$($h['A'].durum)" -eq 'hasat edildi')
Vaka 'birleşim: yalnız parti satırında olan kayıt gelir (C — çöken makinenin kaydı)' ("$($h['C'].durum)" -eq 'gonderildi')

''
"BEKLEYEN AMBAR ÖZ-SINAVI: $gecen/$toplam geçti"
if ($kalan.Count) { foreach ($x in $kalan) { Write-Host "  KIRMIZI: $x" -ForegroundColor Red }; exit 1 }
Write-Host 'YEŞİL' -ForegroundColor Green; exit 0
