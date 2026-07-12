# ============================================================================
#  EMY HASAT - Tarim Payi / Ek Mali Yukumluluk (III Sayili Liste, EURO/100kg)
#  Islenmis tarim urunlerinde gumruk vergisine EK olarak alinan Tarim Payi.
#  Her ulke ayri sutun. Deger ya sayi (EURO/100kg) ya da kod:
#    T1/T2 = bilesime gore "Tarim Payi Tablosu"ndan hesaplanir (tek sayi degil)
#    (i)/(ii)/(iii) = dipnota tabi
#  KURAL: T2/dipnot deger UYDURULMAZ - oldugu gibi isaretlenir, kaynaga yonlendirilir.
#  Cikti: veri\gtip-emy-tarim.json = { kod: { "Ulke": "deger", ... } }
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }
function Noktali($k12){ if($k12.Length -ne 12){ return $k12 }; return $k12.Substring(0,4)+"."+$k12.Substring(4,2)+"."+$k12.Substring(6,2)+"."+$k12.Substring(8,2)+"."+$k12.Substring(10,2) }
function UlkeAdi($k){
  $k = ($k -as [string]).Trim() -replace '\s+',' '
  $map = @{ "G.KORE"="Güney Kore"; "G. KORE"="Güney Kore"; "MLZ"="Malezya"; "SNG"="Singapur"; "KOS"="Kosova"; "İRAN"="İran"; "VNZ"="Venezuela"; "BAE"="BAE"; "DÜ"="Diğer Ülkeler (Çin, ABD, Japonya, Rusya…)" }
  if($map.ContainsKey($k)){ return $map[$k] }
  return $k
}

$III = (Get-ChildItem $RejimKlasor -Filter "*.xlsx" | Where-Object { $_.Name -match "^III " } | Select-Object -First 1)
if(-not $III){ Write-Host "III Sayili Liste bulunamadi!"; exit 1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($III.FullName)
$e = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }; $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $ssXml=$sr.ReadToEnd(); $sr.Close()
$ss=@(); foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) }
$sh = $zip.Entries | Where-Object { $_.FullName -match "sheet1\.xml$" }; $sr2=New-Object System.IO.StreamReader($sh.Open(),[System.Text.Encoding]::UTF8); $shXml=$sr2.ReadToEnd(); $sr2.Close()
$zip.Dispose()
$cellRx=[regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
$rows=([regex]'(?s)<row[^>]*>(.*?)</row>').Matches($shXml)
$satirlar=@()
foreach($rm in $rows){ $h=@{}; foreach($cm in $cellRx.Matches($rm.Groups[1].Value)){ $idx=KolIdx $cm.Groups[1].Value; if($cm.Groups[2].Value -eq "s" -and $cm.Groups[3].Value -ne ""){$h[$idx]=$ss[[int]$cm.Groups[3].Value]}elseif($cm.Groups[4].Value -ne ""){$h[$idx]=[System.Net.WebUtility]::HtmlDecode($cm.Groups[4].Value)}else{$h[$idx]=$cm.Groups[3].Value} }; $satirlar+=,$h }

# ilk veri satiri
$ilkVeri=$satirlar.Count
for($i=0;$i -lt $satirlar.Count;$i++){ $c0=($satirlar[$i][0] -as [string]).Trim() -replace '\.',''; if($c0 -match '^\d{11,12}$'){ $ilkVeri=$i; break } }
# EMY baslangic kolonu
$emyKol=999
for($i=0;$i -lt $ilkVeri;$i++){ foreach($k in $satirlar[$i].Keys){ if($k -ge 3 -and (($satirlar[$i][$k] -as [string]) -match "TARIM PAYI|EK MALİ YÜKÜMLÜLÜK")){ if($k -lt $emyKol){$emyKol=$k} } } }
if($emyKol -eq 999){ Write-Host "EMY sutunu bulunamadi"; exit 1 }
# EMY kolon etiketleri: baz kolon(emyKol) = AB/EFTA/STA grubu; digerleri baslik satirindan
$kolAd = @{}
$kolAd[$emyKol] = "AB / EFTA / STA ortağı ülke"
for($i=0;$i -lt $ilkVeri;$i++){ foreach($k in $satirlar[$i].Keys){ if($k -le $emyKol){ continue }; $t=($satirlar[$i][$k] -as [string]).Trim(); if($t -ne "" -and $t -notmatch "TARIM PAYI|EK MALİ|EURO"){ $kolAd[$k]=$t } } }

$emy=[ordered]@{}
foreach($h in $satirlar){
  $kod0=($h[0] -as [string]).Trim() -replace '\.',''
  if($kod0 -match '^\d{11}$'){ $kod0="0"+$kod0 }
  if($kod0 -notmatch '^\d{12}$'){ continue }
  $kodN = Noktali $kod0
  $degerler=[ordered]@{}
  foreach($k in ($kolAd.Keys | Sort-Object)){
    if(-not $h.ContainsKey($k)){ continue }
    $v=($h[$k] -as [string]).Trim()
    if($v -eq ""){ continue }
    # sayi -> "140.9" ; kod (T2/(ii)) -> oldugu gibi
    if($v -match '^\d+([.,]\d+)?$'){ $degerler[(UlkeAdi $kolAd[$k])] = ([math]::Round([double]($v -replace ',','.'),2)).ToString([System.Globalization.CultureInfo]::InvariantCulture) }
    else { $degerler[(UlkeAdi $kolAd[$k])] = $v }
  }
  # sadece EN AZ BIR anlamli (sifir olmayan / kodlu) deger varsa kaydet
  $anlamli = $false
  foreach($vv in $degerler.Values){ if($vv -ne "0"){ $anlamli=$true; break } }
  if($anlamli){ $emy[$kodN] = $degerler }
}

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($emy | ConvertTo-Json -Depth 4 -Compress) | Out-File (Join-Path $veriDir "gtip-emy-tarim.json") -Encoding utf8

""
"EMY HASAT BITTI. Tarim Payi olan (>0) kod: $($emy.Count)"
"veri\gtip-emy-tarim.json ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-emy-tarim.json')).Length/1KB)) KB)"
"--- ornek 0403.20.51.00.00 (sayisal EMY) ---"
if($emy.Contains("0403.20.51.00.00")){ foreach($u in $emy["0403.20.51.00.00"].Keys){ "  $u => $($emy['0403.20.51.00.00'][$u]) EURO/100kg" } }
"--- ornek 0403.20.49.00.00 (T2 - bilesime bagli) ---"
if($emy.Contains("0403.20.49.00.00")){ foreach($u in $emy["0403.20.49.00.00"].Keys){ "  $u => $($emy['0403.20.49.00.00'][$u])" } }
