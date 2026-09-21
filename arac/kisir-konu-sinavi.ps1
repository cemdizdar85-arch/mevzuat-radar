#requires -Version 5.1
<#
================================================================================
  KISIR / KAYNAK-BORCU SECIM KURALI — OZ-SINAV   (21.09.2026)

  NIYE VAR: kapi bir LISTEYLE calisir; liste mesru veriyle cakisabilir (21.09
  kurali md. 5 — o gun KPMG'ydi). Burada cakisma riski sudur: "kaynak reddi
  almis konu" ile "calisan konu" ayni olabilir. Nitekim olculdu — yalniz
  "kaynak reddi >= 2" deseydik 120 konu duserdi ve bunlarin 215 YAYINA GIRMIS
  sorusu vardi. Kapi bu yuzden "VE yayina giren = 0" sartli kuruldu. Bu sinav
  o sartin yerinde durdugunu olcer.

  ⛔ REPLIKA YASAK: sinav kendi kopyasini yazmaz; arac/kisir-konu-olc.ps1
     icindeki GERCEK `KisirSecimi` fonksiyonu AST ile cikarilip kosulur.

  BEDEL 0.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$hedef = Join-Path $buDizin 'kisir-konu-olc.ps1'
if (-not (Test-Path $hedef)) { throw "olcum betigi bulunamadi: $hedef" }
$tok = $null; $hata = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($hedef, [ref]$tok, [ref]$hata)
if ($hata -and $hata.Count) { throw "betik ayristirilamadi: $($hata[0].Message)" }
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'KisirSecimi' }, $true)
if (-not @($fn).Count) { throw 'KisirSecimi fonksiyonu BULUNAMADI (adi degistiyse sinav da guncellenir)' }
. ([scriptblock]::Create(@($fn)[0].Extent.Text))

function K([string]$ad, [int]$d, [int]$g, [int]$ke) { [pscustomobject]@{ konu = $ad; denenen = $d; gecen = $g; ke = $ke } }

# YAKALAMASI GEREKEN + YANLIS ALARM VERMEMESI GEREKEN vakalar
$vaka = @(
  # --- dusmesi gerekenler ---
  @{ ad = 'KISIR: 5 denendi, 0 yayin'; k = (K 'a' 5 0 0); bek = 'KISIR' }
  @{ ad = 'KISIR: tam esikte (3 denendi, 0 yayin)'; k = (K 'b' 3 0 0); bek = 'KISIR' }
  @{ ad = 'KAYNAK-BORCU: 2 denendi, 2 kaynak reddi, 0 yayin'; k = (K 'c' 2 0 2); bek = 'KAYNAK-BORCU' }
  @{ ad = 'IKISI BIRDEN: 4 denendi, 3 kaynak reddi, 0 yayin'; k = (K 'd' 4 0 3); bek = 'KISIR+KAYNAK-BORCU' }
  # --- YANLIS ALARM: dusmemesi gerekenler ---
  @{ ad = 'YANLIS ALARM: 10 kaynak reddi ama 1 soru YAYINDA'; k = (K 'e' 12 1 10); bek = '' }
  @{ ad = 'YANLIS ALARM: 8 denendi ama 3 soru YAYINDA'; k = (K 'f' 8 3 0); bek = '' }
  @{ ad = 'YANLIS ALARM: 1 kaynak reddi (esigin altinda), 0 yayin'; k = (K 'g' 1 0 1); bek = '' }
  @{ ad = 'YANLIS ALARM: 2 denendi, red yok, 0 yayin (olculmedi)'; k = (K 'h' 2 0 0); bek = '' }
  @{ ad = 'YANLIS ALARM: hic denenmemis konu'; k = (K 'i' 0 0 0); bek = '' }
)

$gecen = 0; $kalan = New-Object System.Collections.Generic.List[string]
foreach ($v in $vaka) {
  $r = @(KisirSecimi @($v.k) 3 2)
  $c = $(if ($r.Count) { "$($r[0].neden)" } else { '' })
  if ($c -eq $v.bek) { $gecen++; if (-not $Sessiz) { "  OK   [{0,-18}] {1}" -f $(if ($c) { $c }else { 'DUSMEDI' }), $v.ad } }
  else { $kalan.Add(("{0} -> beklenen '{1}', cikan '{2}'" -f $v.ad, $v.bek, $c)); if (-not $Sessiz) { "  DUSTU[{0,-18}] {1}" -f $c, $v.ad } }
}

# TOPLU VAKA: kapi TUM konulari dusurmemeli (plandan-parti-kur.ps1 bu durumda throw eder)
$toplu = @((K 'x' 5 0 0), (K 'y' 1 2 0), (K 'z' 2 0 2))
$rt = @(KisirSecimi $toplu 3 2)
if ($rt.Count -eq 2) { $gecen++; if (-not $Sessiz) { '  OK   [TOPLU            ] 3 konudan 2 duser, calisan konu kalir' } }
else { $kalan.Add("TOPLU vaka: 3 konudan 2 dusmeliydi, $($rt.Count) dustu") }

# KAPATMA VAKASI: -KaynakRedEsik 0 verilince ikinci kural kapanir, eski davranis doner
$rk = @(KisirSecimi @((K 'c' 2 0 5)) 3 0)
if ($rk.Count -eq 0) { $gecen++; if (-not $Sessiz) { '  OK   [KAPALI           ] KaynakRedEsik=0 ikinci kurali kapatir (geri donus yolu)' } }
else { $kalan.Add('KaynakRedEsik=0 ikinci kurali KAPATMADI') }

''
"KISIR/KAYNAK-BORCU SECIM OZ-SINAVI: {0}/{1} gecti" -f $gecen, ($vaka.Count + 2)
if ($kalan.Count) {
  foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }
  exit 1
}
Write-Host 'YESIL' -ForegroundColor Green
exit 0
