#requires -Version 5.1
<#
================================================================================
  KÖR KAPISI — ÖZ-SINAV  (23.09.2026)  bedel 0

  NİYE VAR: kapı PARA harcayan üreticinin ortasında duruyor. Yanlış karar verirse iki
  yönde de zarar eder: gevşerse "yanlış olduğu belli" soruya yine para öder (23.09
  ölçümü: kör ✗ 262 soruya sonradan ödendi, 0 yayın); sıkılaşırsa sağlam soruyu
  anlatımsız bırakır. Sınav hem durdurması gerekeni hem DURDURMAMASI gerekeni ölçer.

  ⛔ REPLİKA YASAK: motor/kalip-parti-uret.ps1 içindeki GERÇEK `SmmmKorKapisi`
     AST ile çıkarılıp koşulur; yardımcılar gerçek arac/smmm-yayin-sarti.ps1'den gelir.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1')   # SmmmParmakIzi · SmmmKorIstisna · SmmmOnayHarita (gerçek)
$uretici = Join-Path $kok 'motor\kalip-parti-uret.ps1'
$t = $null; $h = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($uretici, [ref]$t, [ref]$h)
if ($h -and $h.Count) { throw "üretici ayrıştırılamadı: $($h[0].Message)" }
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'SmmmKorKapisi' }, $true)
if (-not @($fn).Count) { throw 'SmmmKorKapisi üretici içinde BULUNAMADI' }
. ([scriptblock]::Create(@($fn)[0].Extent.Text))

$Etiket = 'smmm-sinav-x'
function Soru([string]$metin, [string]$dogru) {
  return [pscustomobject]@{ soru = $metin; dogru = $dogru; siklar = [pscustomobject]@{ A = 'bir'; B = 'iki'; C = 'üç'; D = 'dört'; E = 'beş' } }
}
function Kor($s, [bool]$dogruMu, [string]$cevap) { $s | Add-Member -NotePropertyName kor_cozum -NotePropertyValue ([pscustomobject]@{ dogru_mu = $dogruMu; cevap = $cevap }) -Force; return $s }
function Kaynakli($s, [bool]$dogruMu, [switch]$Bayat) {
  $pi = $(if ($Bayat) { 'eski-parmak-izi' } else { SmmmParmakIzi $s })
  $s | Add-Member -NotePropertyName kor_cozum_kaynakli -NotePropertyValue ([pscustomobject]@{ dogru_mu = $dogruMu; cevap = $(if ($dogruMu) { "$($s.dogru)" } else { 'E' }); kor_cevap = "$($s.kor_cozum.cevap)"; parmak_izi = $pi }) -Force
  return $s
}

$gecen = 0; $kalan = New-Object System.Collections.Generic.List[string]; $toplam = 0
function Vaka([string]$ad, [string]$cikan, [string]$bek) {
  $script:toplam++
  if ($cikan -eq $bek) { $script:gecen++; if (-not $Sessiz) { "  OK    [{0,-14}] {1}" -f $cikan, $ad } }
  else { $script:kalan.Add("$ad -> beklenen $bek, çıkan $cikan"); if (-not $Sessiz) { "  DÜŞTÜ [{0,-14}] {1} (beklenen {2})" -f $cikan, $ad, $bek } }
}

# --- DURDURMAMASI gerekenler ---
$Sinav = 'SGS'; $script:SMMM_ONAY_HARITA = @{}
Vaka 'SGS: kör yanlış bile olsa bu kapı SGS''ye DOKUNMAZ' (SmmmKorKapisi 'kp-01' (Kor (Soru 's1' 'B') $false 'C')) 'GECER'
$Sinav = 'SMMM'
Vaka 'SMMM: kör hiç koşmamış → karar yok, engel yok' (SmmmKorKapisi 'kp-02' (Soru 's2' 'B')) 'GECER'
Vaka 'SMMM: kör doğru' (SmmmKorKapisi 'kp-03' (Kor (Soru 's3' 'B') $true 'B')) 'GECER'
$s7 = Kaynakli (Kor (Soru 's7' 'B') $false 'C') $true
$script:SMMM_ONAY_HARITA = @{ "$Etiket/kp-07" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s7); tarih = '2026-09-23' } }
Vaka 'SMMM: kör ✗ + kaynaklı ✓ + CEM ONAYI (parmak izi tutuyor) → açılır' (SmmmKorKapisi 'kp-07' $s7) 'GECER'

# --- DURDURMASI gerekenler ---
$script:SMMM_ONAY_HARITA = @{}
Vaka 'SMMM: kör ✗, kaynaklı çözüm HİÇ yok' (SmmmKorKapisi 'kp-04' (Kor (Soru 's4' 'B') $false 'C')) 'KAYNAKLI-YOK'
Vaka 'SMMM: kör ✗ + kaynaklı ✗ → iki çözücü de yanlış' (SmmmKorKapisi 'kp-05' (Kaynakli (Kor (Soru 's5' 'B') $false 'C') $false)) 'IKISI-YANLIS'
Vaka 'SMMM: kör ✗ + kaynaklı ✓, onay YOK → anlatım onaydan sonra' (SmmmKorKapisi 'kp-06' (Kaynakli (Kor (Soru 's6' 'B') $false 'C') $true)) 'ONAY-BEKLIYOR'
Vaka 'SMMM: kaynaklı ✓ ama ESKİ soru metnine ait (bayat) → geçerli sayılmaz' (SmmmKorKapisi 'kp-08' (Kaynakli (Kor (Soru 's8' 'B') $false 'C') $true -Bayat)) 'KAYNAKLI-YOK'
$s9 = Kaynakli (Kor (Soru 's9' 'B') $false 'C') $true
$script:SMMM_ONAY_HARITA = @{ "$Etiket/kp-09" = [pscustomobject]@{ karar = 'RED'; parmak_izi = (SmmmParmakIzi $s9); tarih = '2026-09-23' } }
Vaka 'SMMM: Cem RED dedi → açılmaz' (SmmmKorKapisi 'kp-09' $s9) 'ONAY-BEKLIYOR'
$s10 = Kaynakli (Kor (Soru 's10' 'B') $false 'C') $true
$script:SMMM_ONAY_HARITA = @{ "$Etiket/kp-10" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = 'onaydan-sonra-soru-degisti'; tarih = '2026-09-23' } }
Vaka 'SMMM: onay verildi ama sonra soru değişti (parmak izi tutmuyor) → açılmaz' (SmmmKorKapisi 'kp-10' $s10) 'ONAY-BEKLIYOR'
$s11 = Kaynakli (Kor (Soru 's11' 'B') $false 'C') $true
# onay kaydı BU sorunun parmak iziyle ama BAŞKA kimlikle (kp-99) — kimlik tutmadığı için açmamalı
$script:SMMM_ONAY_HARITA = @{ "$Etiket/kp-99" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s11); tarih = '2026-09-23' } }
Vaka 'SMMM: BAŞKA kimliğe verilmiş onay bu soruyu açmaz' (SmmmKorKapisi 'kp-11' $s11) 'ONAY-BEKLIYOR'

''
"KÖR KAPISI ÖZ-SINAVI: $gecen/$toplam geçti"
if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
Write-Host 'YEŞİL' -ForegroundColor Green
exit 0
