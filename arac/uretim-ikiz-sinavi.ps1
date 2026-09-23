#requires -Version 5.1
<#
================================================================================
  ÜRETİM İKİZ KAPISI — ÖZ-SINAV (KAPI-B)   24.09.2026 · bedel 0
  NİYE: motor/kalip-parti-uret.ps1 para harcayan hattır; ÇALIŞTIRILARAK denetlenmez (CLAUDE.md). Bu sınav betiği
  ÇALIŞTIRMAZ: gerçek BenzerlikKusur ve yardımcılarını AST ile çıkarıp, sahte parti/havuz/ambar paketiyle çağırır.
  ⛔ REPLİKA YOK: fonksiyon gövdeleri üretim dosyasından okunur; ikiz cetveli arac/ikiz-olcusu.ps1 dot-source edilir.
  Vakalar: anlamca ikiz (havuzda / aynı partide) DÜŞER · kaynak kaydı yoksa ambar paketi ($amb.adlar) kullanılır ·
  konu farklı / tutar farklı / sayısal kısa cevap → GEÇER · klasik ikiz eskisi gibi düşer.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'ikiz-olcusu.ps1'); . (Join-Path $buDizin 'smmm-ders-adi.ps1')
$uretYol = Join-Path $kok 'motor\kalip-parti-uret.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($uretYol, [ref]$null, [ref]$null)
# Üretim dosyasındaki BÜTÜN üst düzey fonksiyon TANIMLARI yüklenir (tanım yüklemek kod çalıştırmaz); sınav yardımcıları
# aşağıda tanımlandığı için aynı adlıları (BenzerHavuz) ezer.
$fonk = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and -not ($n.Parent.Parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) }, $true))
if (-not @($fonk | Where-Object { $_.Name -eq 'BenzerlikKusur' }).Count) { throw 'üretim dosyasında BenzerlikKusur yok' }
foreach ($f in $fonk) { . ([scriptblock]::Create($f.Extent.Text)) }
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function Q([string]$konu, [string]$soru, [string]$dogru, $kaynak) { $o = [pscustomobject]@{ konu = $konu; soru = $soru; dogru = 'A'; siklar = [pscustomobject]@{ A = $dogru; B = 'b'; C = 'c'; D = 'd'; E = 'e' } }; if ($null -ne $kaynak) { $o | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($kaynak) }; return $o }
function HavuzKaydi($et, $id, $q) { [pscustomobject]@{ etiket = $et; id = $id; konu = "$($q.konu)"; kume = (KelimeKume "$($q.soru)"); sikKume = (SikKume $q); madde = (KokMaddeNo "$($q.soru)"); ders = (SmmmDersAdi $et $q); soruMetin = "$($q.soru)"; dogruMetin = (IkizDogruMetin $q); parmak = $null; kaynak = @($q.kaynak_adlar); ai = $null } }
# betik kapsamı değişkenleri (üretimdeki adlarla)
$Sinav = 'SMMM'; $Etiket = 'smmm-w11-1-yhukuk-zor'; $CAPA = @{}; $script:GK_DERS = $false
$kay = 'TBK (6098 s.K.) m.49'
$hv = Q 'haksiz fiil unsurlari' '6098 sayili Turk Borclar Kanunu m.49da duzenlenen haksiz fiil sorumlulugunun kural ve istisnasi bakimindan asagidaki ifadelerden hangisi dogrudur?' 'Zarar verici fiili yasaklayan bir hukuk kurali bulunmasa bile, ahlaka aykiri bir fiille baskasina kasten zarar veren de bu zarari gidermekle yukumludur.' @($kay)
$yeni = Q 'haksiz fiil unsurlari' 'Turk Borclar Kanununun haksiz fiil sorumluluguna iliskin hukumlerine gore asagidakilerden hangisi dogrudur?' 'Zarar verici fiili yasaklayan bir hukuk kurali olmasa bile, ahlaka aykiri bir fiille kasten zarar veren kisi de bu zarari gidermekle yukumludur.' $null
function Kur($havuzListe, $donTablo, $ambAdlar) { $script:BENZER_HAVUZ = New-Object System.Collections.Generic.List[object]; foreach ($x in $havuzListe) { $script:BENZER_HAVUZ.Add($x) }; $script:don = $donTablo; $script:amb = @{ adlar = @($ambAdlar) } }
function BenzerHavuz { return $script:BENZER_HAVUZ }
# 1) havuzda anlamca ikiz, yeni kayıtta kaynak_adlar YOK → ambar paketi kullanılır → DÜŞER
Kur @(HavuzKaydi 'smmm-w5-yhukuk-zor' 'kp-03' $hv) @{} @($kay)
$don = $script:don; $amb = $script:amb
$k1 = @(BenzerlikKusur $yeni 'kp-01')
T 'havuzda anlamca ikiz (kaynak ambar paketinden) → KAPI-B düşer' ($k1.Count -eq 1 -and "$($k1[0])" -match 'ANLAMCA ikiz')
# 2) aynı ama ambar paketi başka kaynak → grup farklı → GEÇER
Kur @(HavuzKaydi 'smmm-w5-yhukuk-zor' 'kp-03' $hv) @{} @('TBK (6098 s.K.) m.58'); $don = $script:don; $amb = $script:amb
T 'ilk kaynak farklı (grup ayrı) → geçer' (@(BenzerlikKusur $yeni 'kp-01').Count -eq 0)
# 3) konu etiketi farklı → GEÇER
$yeniK = Q 'kusursuz sorumluluk halleri' $yeni.soru "$($yeni.siklar.A)" @($kay)
Kur @(HavuzKaydi 'smmm-w5-yhukuk-zor' 'kp-03' $hv) @{} @($kay); $don = $script:don; $amb = $script:amb
T 'konu farklı → geçer' (@(BenzerlikKusur $yeniK 'kp-01').Count -eq 0)
# 4) aynı PARTİDE anlamca ikiz → DÜŞER
Kur @() @{ 'kp-02' = $hv } @($kay); $don = $script:don; $amb = $script:amb
$k4 = @(BenzerlikKusur $yeni 'kp-01')
T 'aynı partide anlamca ikiz → düşer' ($k4.Count -eq 1 -and "$($k4[0])" -match 'partideki kp-02 ile ANLAMCA')
# 5) tutar farklı yevmiye (rakam şartı) → GEÇER
$kA = Q 'kambiyo kari kaydi' 'Isletme, yabanci para cinsinden olan ticari alacaginin donem sonu degerlemesinde olusan kur farkini kayda alacaktir. Buna gore donem sonu degerleme kaydi asagidakilerden hangisidir?' '120 ALICILAR hesabi 30.000 TL borclandirilir, 646 KAMBIYO KARLARI hesabi 30.000 TL alacaklandirilir.' @('THP 646')
$kB = Q 'kambiyo kari kaydi' 'Isletmenin dovizli ticari alacaginin donem sonu degerlemesi sonucunda kur farki olusmustur. Yapilacak degerleme kaydi asagidakilerden hangisidir?' '120 ALICILAR hesabi 20.000 TL borclandirilir, 646 KAMBIYO KARLARI hesabi 20.000 TL alacaklandirilir.' @('THP 646')
$Etiket = 'smmm-w11-1-fmuh-zor'; Kur @(HavuzKaydi 'smmm-w5-fmuh-zor' 'kp-09' $kA) @{} @('THP 646'); $don = $script:don; $amb = $script:amb
$k5 = @(BenzerlikKusur $kB 'kp-01'); if ($k5.Count) { Write-Host "  (5) kusur: $($k5 -join ' | ')" }
T 'tutar farklı yevmiye kaydı → geçer' ($k5.Count -eq 0)
$kC = Q 'kambiyo kari kaydi' $kB.soru "$($kA.siklar.A)" @('THP 646')
$k5b = @(BenzerlikKusur $kC 'kp-01')
T 'kontrol: aynı metinler AYNI tutarla → ANLAMCA ikiz düşer (5. vakayı rakam şartı geçiriyor)' ($k5b.Count -eq 1 -and "$($k5b[0])" -match 'ANLAMCA')
# 6) klasik ikiz (neredeyse aynı metin) eskisi gibi düşer
$Etiket = 'smmm-w11-1-yhukuk-zor'; Kur @(HavuzKaydi 'smmm-w5-yhukuk-zor' 'kp-03' $hv) @{} @($kay); $don = $script:don; $amb = $script:amb
T 'klasik ikiz (aynı metin) yine düşer' (@(BenzerlikKusur $hv 'kp-01').Count -ge 1)
$top = $gecti + $dustu.Count
Write-Host "ÜRETİM İKİZ ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
