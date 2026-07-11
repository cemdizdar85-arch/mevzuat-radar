# ============================================================================
#  DAMPING HASAT - Ticaret Bak. "Yururlukteki Onlemler" xlsx -> gtip-damping.json
#  Kesin (sheet2) + Gecici (sheet3) onlemler. LLM YOK, birebir.
# ============================================================================
param(
  [string]$Xlsx = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\damping.xlsx"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)
function OkuE($ad){ $e=$zip.Entries|Where-Object{$_.FullName -eq $ad}|Select-Object -First 1; if(-not $e){return $null}; $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
$ss=@()
$ssXml=OkuE "xl/sharedStrings.xml"
if($ssXml){ foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({$_.Groups[1].Value}))) } }

$rowRx=[regex]'(?s)<row[^>]*r="(\d+)"[^>]*>(.*?)</row>'
# her hucre: ref + attribut blogu + (formul atlanir) + <v> degeri
$cellRx=[regex]'(?s)<c r="([A-Z]+)\d+"([^>]*?)/?>(?:<f[^>]*?>.*?</f>|<f[^>]*/>)?(?:<v>(.*?)</v>|<is>.*?<t[^>]*>(.*?)</t>.*?</is>)?(?:</c>)?'

function SheetOku($ad){
  $xml=OkuE $ad; if(-not $xml){ return @() }
  $out=@()
  foreach($rm in $rowRx.Matches($xml)){
    $h=@{}
    foreach($cm in $cellRx.Matches($rm.Groups[2].Value)){
      $idx=KolIdx $cm.Groups[1].Value
      $attr=$cm.Groups[2].Value; $v=$cm.Groups[3].Value; $inl=$cm.Groups[4].Value
      if($inl -ne ""){ $h[$idx]=[System.Net.WebUtility]::HtmlDecode($inl) }
      elseif($attr -match 't="s"'){ if($v -ne ""){ $h[$idx]=$ss[[int]$v] } }
      elseif($v -ne ""){ $h[$idx]=$v }
    }
    $out += ,$h
  }
  return $out
}

function Al($h,$i){ if($h.ContainsKey($i)){ return (($h[$i] -as [string]).Trim()) } return "" }

$onlemler=@()
foreach($sh in @(@{s="xl/worksheets/sheet2.xml";t="Kesin"}, @{s="xl/worksheets/sheet3.xml";t="Gecici"})){
  foreach($h in (SheetOku $sh.s)){
    $gtipHam = Al $h 4
    $ulke = Al $h 5
    $urun = Al $h 2
    $oran = Al $h 10
    $tur  = Al $h 11
    $teb  = Al $h 7
    # baslik/bos satirlari ele
    if($gtipHam -match "G\.T\.İ\.P" -or $urun -eq "MADDE İSMİ"){ continue }
    # GTIP kodlarini ayikla (noktali kalibi olanlar)
    $kodlar = @()
    foreach($tok in ($gtipHam -split '\s+')){
      $t2 = ($tok -replace '[^\d.]','').Trim('.')
      if($t2 -match '^\d{4}(\.\d{2}){0,4}$'){ $kodlar += ($t2 -replace '\.','') }  # noktasiz sakla
    }
    # anlamli kayit: en az kod+ulke olmali (oran bos olabilir - onlem VARLIGI bile uyaridir)
    if(-not $kodlar.Count -or -not $ulke){ continue }
    $onlemler += [ordered]@{
      k = ($kodlar -join " ")
      u = $ulke; m = $urun; o = $oran; t = $tur; tb = $teb; tur = $sh.t
    }
  }
}
$zip.Dispose()

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($onlemler | ConvertTo-Json -Depth 3 -Compress) | Out-File (Join-Path $veriDir "gtip-damping.json") -Encoding utf8

"BITTI. Damping onlemi: $($onlemler.Count) kayit -> veri\gtip-damping.json ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-damping.json')).Length/1KB)) KB)"
"--- kodlu ornek 4 ---"
$onlemler | Where-Object { $_.k } | Select-Object -First 4 | ForEach-Object { "  {0} | {1} | {2} | {3}" -f $_.k, $_.u, $_.m, $_.o }