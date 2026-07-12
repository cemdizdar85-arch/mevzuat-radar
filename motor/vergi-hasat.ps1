# ============================================================================
#  VERGI HASAT - Ithalat Rejimi (Gumruk Vergisi) + IGV Excel'lerini birebir
#  ayristirir (LLM YOK, kesin). Cikti: veri\gtip-vergi.json
#  gv  = Gumruk Vergisi (Ithalat Rejimi II/I/III... sayili listeler)
#  igv = Ilave Gumruk Vergisi (IGV Karari Ek-1/2/3)
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026",
  [string]$IgvKlasor   = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\igv2026"
)
$ErrorActionPreference = "Stop"
try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch {}  # ubuntu pwsh: Core'da zaten yuklu
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){
  $h = ($ref -replace '\d','').ToUpper()
  $n = 0; foreach($ch in $h.ToCharArray()){ $n = $n*26 + ([int][char]$ch - 64) }
  return $n - 1
}
function Noktali($k12){
  if($k12.Length -ne 12){ return $k12 }
  return $k12.Substring(0,4)+"."+$k12.Substring(4,2)+"."+$k12.Substring(6,2)+"."+$k12.Substring(8,2)+"."+$k12.Substring(10,2)
}

# Bir xlsx'i oku -> @{ kod = @(oranlar) }
function XlsxOran($xlsx){
  $sonuc = @{}
  try { $zip = [System.IO.Compression.ZipFile]::OpenRead($xlsx) } catch { return $sonuc }
  function OkuE($z,$ad){ $e = $z.Entries | Where-Object { $_.FullName -eq $ad } | Select-Object -First 1; if(-not $e){ return $null }; $sr = New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
  $ssXml = OkuE $zip "xl/sharedStrings.xml"
  # tum sheet'ler (fasillar ayri sheet olabilir)
  $sheetler = $zip.Entries | Where-Object { $_.FullName -match "xl/worksheets/sheet\d+\.xml$" }
  $ss = @()
  if($ssXml){ foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) } }
  $rowRx = [regex]'(?s)<row[^>]*>(.*?)</row>'
  $cellRx = [regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
  foreach($sh in $sheetler){
    $sr = New-Object System.IO.StreamReader($sh.Open(),[System.Text.Encoding]::UTF8); $shXml = $sr.ReadToEnd(); $sr.Close()
    foreach($rm in $rowRx.Matches($shXml)){
      $h = @{}
      foreach($cm in $cellRx.Matches($rm.Groups[1].Value)){
        $idx = KolIdx $cm.Groups[1].Value
        if($cm.Groups[2].Value -eq "s" -and $cm.Groups[3].Value -ne ""){ $h[$idx] = $ss[[int]$cm.Groups[3].Value] }
        elseif($cm.Groups[4].Value -ne ""){ $h[$idx] = [System.Net.WebUtility]::HtmlDecode($cm.Groups[4].Value) }
        else { $h[$idx] = $cm.Groups[3].Value }
      }
      $a = if($h.ContainsKey(0)){ ($h[0] -as [string]).Trim() } else { "" }
      if($a -notmatch '^\d{12}$'){ continue }
      $oranlar = @()
      for($k=2;$k -le 8;$k++){ if($h.ContainsKey($k)){ $v=($h[$k] -as [string]).Trim(); if($v -match '^\d+([.,]\d+)?$'){ $oranlar += [double]($v -replace ',','.') } } }
      if($oranlar.Count){ $sonuc[(Noktali $a)] = $oranlar }
    }
  }
  $zip.Dispose()
  return $sonuc
}

# --- GV: rejim klasorundeki TUM xlsx ---
$gv = @{}
Get-ChildItem $RejimKlasor -Filter "*.xlsx" | ForEach-Object {
  $o = XlsxOran $_.FullName
  foreach($k in $o.Keys){ if(-not $gv.ContainsKey($k)){ $gv[$k] = $o[$k] } }
  Write-Host ("GV {0}: +{1} kod (toplam {2})" -f $_.Name, $o.Count, $gv.Count)
}

# --- IGV: igv klasorundeki TUM xlsx ---
$igv = @{}
Get-ChildItem $IgvKlasor -Filter "*.xlsx" | ForEach-Object {
  $o = XlsxOran $_.FullName
  foreach($k in $o.Keys){ if(-not $igv.ContainsKey($k)){ $igv[$k] = $o[$k] } }
  Write-Host ("IGV {0}: +{1} kod (toplam {2})" -f $_.Name, $o.Count, $igv.Count)
}

# --- birlestir (KOMPAKT: kod => [gvMin,gvMax,igvMin,igvMax], yoksa null) ---
$tumKod = @($gv.Keys) + @($igv.Keys) | Select-Object -Unique
$vergi = [ordered]@{}
foreach($kod in ($tumKod | Sort-Object)){
  $gvMin=$null;$gvMax=$null;$igvMin=$null;$igvMax=$null
  if($gv.ContainsKey($kod)){ $o=$gv[$kod]; $gvMin=($o|Measure-Object -Min).Minimum; $gvMax=($o|Measure-Object -Max).Maximum }
  if($igv.ContainsKey($kod)){ $o=$igv[$kod]; $igvMin=($o|Measure-Object -Min).Minimum; $igvMax=($o|Measure-Object -Max).Maximum }
  $vergi[$kod] = @($gvMin,$gvMax,$igvMin,$igvMax)
}
$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($vergi | ConvertTo-Json -Depth 3 -Compress) | Out-File (Join-Path $veriDir "gtip-vergi.json") -Encoding utf8

""
"HASAT BITTI. GV: $($gv.Count) kod | IGV: $($igv.Count) kod | Birlesik: $($vergi.Count) kod"
"veri\gtip-vergi.json yazildi ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-vergi.json')).Length/1KB)) KB)"
"--- ornek: seramik 6910.10 ---"
if($vergi.Contains("6910.10.00.00.00")){ $vergi["6910.10.00.00.00"] | ConvertTo-Json -Compress }