# ============================================================================
#  IGV HASAT - ULKE BAZLI (SANAYI, IGV Karari Ek-1)
#  Ilave Gumruk Vergisi Karari Ek-1 (sanayi urunleri) Excel'ini ulke grubu
#  bazinda ayristirir. Kolon semasi Gumruk Vergisi II Sayili Liste ile AYNI:
#    kolon2=AB/EFTA/STA | kolon3=Katar | kolon4=BAE | kolon5=EAGU
#    kolon6=OTDU | kolon7=GYU | kolon8=DU (Diger Ulkeler)
#  NOT: Ek-2/Ek-3 FARKLI (granuler, ulke ulke) sema kullanir - bilerek DISLANDI.
#  Cikti: veri\gtip-igv-ulke.json
# ============================================================================
param(
  [string]$IgvKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\igv2026"
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

function XlsxUlkeOran($xlsx){
  $sonuc = @{}
  try { $zip = [System.IO.Compression.ZipFile]::OpenRead($xlsx) } catch { return $sonuc }
  function OkuE($z,$ad){ $e = $z.Entries | Where-Object { $_.FullName -eq $ad } | Select-Object -First 1; if(-not $e){ return $null }; $sr = New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
  $ssXml = OkuE $zip "xl/sharedStrings.xml"
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
      $aHam = if($h.ContainsKey(0)){ ($h[0] -as [string]).Trim() } else { "" }
      $aDuz = $aHam -replace '\.',''
      if($aDuz -notmatch '^\d{12}$'){ continue }
      $satir = @()
      for($k=2;$k -le 8;$k++){
        if($h.ContainsKey($k)){
          $v=($h[$k] -as [string]).Trim()
          if($v -match '^\d+([.,]\d+)?$'){ $satir += [double]($v -replace ',','.') }
          else { $satir += $null }
        } else { $satir += $null }
      }
      $sonuc[(Noktali $aDuz)] = $satir
    }
  }
  $zip.Dispose()
  return $sonuc
}

# --- SADECE Ek-1 (sanayi, 7-grup sema) ---
$ek1 = Get-ChildItem $IgvKlasor -Filter "Ek-1.xlsx" | Select-Object -First 1
if(-not $ek1){ Write-Host "Ek-1.xlsx bulunamadi!"; exit 1 }
$igv = XlsxUlkeOran $ek1.FullName
Write-Host ("{0}: {1} kod" -f $ek1.Name, $igv.Count)

$cikti = [ordered]@{}
foreach($kod in ($igv.Keys | Sort-Object)){ $cikti[$kod] = $igv[$kod] }
$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($cikti | ConvertTo-Json -Depth 3 -Compress) | Out-File (Join-Path $veriDir "gtip-igv-ulke.json") -Encoding utf8

""
"IGV ULKE HASAT BITTI. Sanayi (Ek-1): $($cikti.Count) kod"
"veri\gtip-igv-ulke.json yazildi ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-igv-ulke.json')).Length/1KB)) KB)"
"--- ornek 2515.11.00.00.00 (mermer) ---"
if($cikti.Contains("2515.11.00.00.00")){ "  abSta,katar,bae,eagu,otdu,gyu,du = " + ($cikti["2515.11.00.00.00"] -join ", ") }
$farkli = 0
foreach($k in $cikti.Keys){ $v=$cikti[$k]; if($v[0] -ne $null -and $v[6] -ne $null -and $v[0] -ne $v[6]){ $farkli++ } }
"  $farkli / $($cikti.Count) kodda AB-STA ile Diger Ulkeler IGV orani FARKLI"
