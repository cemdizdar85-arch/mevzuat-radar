#requires -Version 5.1
<#
  BEDEL ARA KAYDI — ÖZ-SINAV (23.09.2026) · bedel 0 · ağ YOK
  Niye: çöken koşunun harcaması deftere girmiyordu; bütçe kapısı o planı 0 USD sayıp yeniden izin veriyordu.
  Sınav: ara kayıt anahtarı (faz eki atılır → koşu başına etiket başına TEK kayıt), gövde (SISTEM, soru metni yok),
  kapatıcı kararı (yalnız kapanmamış + eski + tutarlı kayıt deftere çevrilir; koşmakta olan koşuya dokunulmaz).
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
. ([scriptblock]::Create((FnMetin 'motor\api-hedef.ps1' @('BedelAraAnahtar', 'BedelAraGovde')) + "`n" + (FnMetin 'arac\bedel-ara-kapat.ps1' @('BedelAraKapatilmali'))))

$gecen = 0; $toplam = 0; $kalan = New-Object System.Collections.Generic.List[string]
function Vaka([string]$ad, [bool]$ok) { $script:toplam++; if ($ok) { $script:gecen++; if (-not $Sessiz) { "  OK    $ad" } } else { $script:kalan.Add($ad); if (-not $Sessiz) { "  DÜŞTÜ $ad" } } }

Vaka 'anahtar: faz eki atılır (…/A → etiket kökü)' ((BedelAraAnahtar 'smmm-w10-1-fmuh-zor/A' 'gh1-1') -eq '__bedel-ara/gh1-1/smmm-w10-1-fmuh-zor')
Vaka 'anahtar: aynı koşu+etiket, farklı faz → AYNI kayıt (birikmiş tutar tek satırda)' ((BedelAraAnahtar 'smmm-w10-1-fmuh-zor/H2' 'gh1-1') -eq (BedelAraAnahtar 'smmm-w10-1-fmuh-zor/K' 'gh1-1'))
Vaka 'anahtar: farklı koşu → farklı kayıt (zincir halkaları ayrı sayılır)' ((BedelAraAnahtar 'smmm-x/A' 'gh1-1') -ne (BedelAraAnahtar 'smmm-x/A' 'gh2-1'))
Vaka 'anahtar: boş etiket → kayıt yok' ($null -eq (BedelAraAnahtar '' 'gh1-1'))

$oz = [pscustomobject]@{ toplamUsd = 3.25; fiyatVarsayim = $true; satirlar = @([pscustomobject]@{ model = 'claude-sonnet-5|toplu'; cagri = 12 }) }
$g = BedelAraGovde 'smmm-w10-1-fmuh-zor/A' 'gh1-1' $oz $false '2026-09-23 08:00'
Vaka 'gövde: sinav SISTEM (soru/bedel sayımına girmez)' ("$($g.sinav)" -eq 'SISTEM')
Vaka 'gövde: tutar, etiket kökü, koşu, kapandı=false taşır' ([double]$g.icerik.toplamUsd -eq 3.25 -and "$($g.icerik.etiket)" -eq 'smmm-w10-1-fmuh-zor' -and "$($g.icerik.kosu)" -eq 'gh1-1' -and -not [bool]$g.icerik.kapandi)
$js = ConvertTo-Json -InputObject $g -Depth 8 -Compress
Vaka 'gövde: SORU METNİ taşımaz' (-not ($js -match '"(soru|siklar|metin|cevap)"\s*:'))

$simdi = [datetime]'2026-09-23 18:00'
function Ic([bool]$kap, [double]$usd, [string]$z) { return [pscustomobject]@{ kapandi = $kap; toplamUsd = $usd; zaman = $z } }
Vaka 'kapatıcı: AÇIK + 10 saat önce + tutar var → deftere çevrilir (çöken koşu)' (BedelAraKapatilmali (Ic $false 4.5 '2026-09-23 08:00') $simdi 400)
Vaka 'kapatıcı: KAPANMIŞ kayıt → dokunulmaz (koşu kendi satırını yazdı)' (-not (BedelAraKapatilmali (Ic $true 4.5 '2026-09-23 08:00') $simdi 400))
Vaka 'kapatıcı: YENİ kayıt (2 saat) → dokunulmaz (koşu hâlâ sürüyor olabilir)' (-not (BedelAraKapatilmali (Ic $false 4.5 '2026-09-23 16:00') $simdi 400))
Vaka 'kapatıcı: tutar 0 → dokunulmaz' (-not (BedelAraKapatilmali (Ic $false 0 '2026-09-23 08:00') $simdi 400))
Vaka 'kapatıcı: zamanı okunamayan kayıt → dokunulmaz' (-not (BedelAraKapatilmali (Ic $false 4.5 'bozuk') $simdi 400))
Vaka 'kapatıcı: tam eşikte (400 dk) → çevrilir' (BedelAraKapatilmali (Ic $false 1 '2026-09-23 11:20') $simdi 400)

''
"BEDEL ARA KAYDI ÖZ-SINAVI: $gecen/$toplam geçti"
if ($kalan.Count) { foreach ($x in $kalan) { Write-Host "  KIRMIZI: $x" -ForegroundColor Red }; exit 1 }
Write-Host 'YEŞİL' -ForegroundColor Green; exit 0
