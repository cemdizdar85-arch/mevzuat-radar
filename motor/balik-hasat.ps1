# ============================================================================
#  BALIK HASAT - Ithalat Rejimi IV Sayili Liste (Balikcilik ve su urunleri)
#  Fasil 2,3,15,16,23. Sabit sutun semasi (baslik okundu, dogrulandi):
#    kol3-13 (0-tabanli 2-12) = GUMRUK VERGISI (%), 11 ulke grubu
#    kol14-24 (0-tabanli 13-23) = EK MALI YUKUMLULUK (%), 11 ulke grubu
#      (balikta bu yukumluluk Toplu Konut Fonu islevi gorur - CIF %'si)
#  Ulke sirasi GV: EFTA/B-HER/F.ADA, AB/BK, G.KORE, MLZ, SNG, KOS, VNZ, BAE, TPS-OIC, D-8, DU
#  Ulke sirasi EMY: EFTA/F.ADA, AB/BK, G.KORE, MLZ, SNG, KOS, VNZ, BAE, TPS-OIC, D-8, DU
#  Cikti: veri\gtip-balik.json
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$inv  = [System.Globalization.CultureInfo]::InvariantCulture

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }
function Noktali($k12){ if($k12.Length -ne 12){ return $k12 }; return $k12.Substring(0,4)+"."+$k12.Substring(4,2)+"."+$k12.Substring(6,2)+"."+$k12.Substring(8,2)+"."+$k12.Substring(10,2) }
function Say($v){ $v=($v -as [string]).Trim(); if($v -match '^\d+([.,]\d+)?$'){ return [math]::Round([double]($v -replace ',','.'),2) } else { return $null } }

$dosya = (Get-ChildItem $RejimKlasor -Filter "*.xlsx" | Where-Object { $_.Name -match "^IV " } | Select-Object -First 1)
if(-not $dosya){ Write-Host "IV Sayili Liste bulunamadi!"; exit 1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($dosya.FullName)
$e = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
$ss=@(); if($e){ $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $ssXml=$sr.ReadToEnd(); $sr.Close(); foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) } }
$cikti = [ordered]@{}
$cellRx=[regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
foreach($sh in ($zip.Entries | Where-Object { $_.FullName -match "xl/worksheets/sheet\d+\.xml$" })){
  $sr2=New-Object System.IO.StreamReader($sh.Open(),[System.Text.Encoding]::UTF8); $shXml=$sr2.ReadToEnd(); $sr2.Close()
  foreach($rm in ([regex]'(?s)<row[^>]*>(.*?)</row>').Matches($shXml)){
    $h=@{}
    foreach($cm in $cellRx.Matches($rm.Groups[1].Value)){
      $idx=KolIdx $cm.Groups[1].Value
      if($cm.Groups[2].Value -eq "s" -and $cm.Groups[3].Value -ne ""){ $h[$idx]=$ss[[int]$cm.Groups[3].Value] }
      elseif($cm.Groups[4].Value -ne ""){ $h[$idx]=[System.Net.WebUtility]::HtmlDecode($cm.Groups[4].Value) }
      else { $h[$idx]=$cm.Groups[3].Value }
    }
    $kod0 = ($h[0] -as [string]).Trim() -replace '[^\d]',''
    if($kod0.Length -eq 11){ $kod0 = "0"+$kod0 }
    if($kod0 -notmatch '^\d{12}$'){ continue }
    $gv=@(); for($k=2;$k -le 12;$k++){ $gv += (Say $h[$k]) }
    $emy=@(); for($k=13;$k -le 23;$k++){ $emy += (Say $h[$k]) }
    # en az bir GV degeri okunduysa kaydet
    $varGv = $false; foreach($x in $gv){ if($x -ne $null){ $varGv=$true; break } }
    if(-not $varGv){ continue }
    $cikti[(Noktali $kod0)] = @{ gv=$gv; emy=$emy }
  }
}
$zip.Dispose()

$out = [ordered]@{
  aciklama = "İthalat Rejimi Kararı IV Sayılı Liste — balıkçılık ve su ürünleri (fasıl 2,3,15,16,23). GV = Gümrük Vergisi %; EMY = Ek Mali Yükümlülük % (balıkta Toplu Konut Fonu işlevi, CIF üzerinden)."
  gvUlke  = @("EFTA / Bosna-Hersek / Faroe Ad.","AB / İngiltere","Güney Kore","Malezya","Singapur","Kosova","Venezuela","BAE","İslam Konferansı (TPS-OIC)","D-8 ülkeleri","Diğer Ülkeler (Çin, ABD, Japonya…)")
  emyUlke = @("EFTA / Faroe Ad.","AB / İngiltere","Güney Kore","Malezya","Singapur","Kosova","Venezuela","BAE","İslam Konferansı (TPS-OIC)","D-8 ülkeleri","Diğer Ülkeler (Çin, ABD, Japonya…)")
  kodlar  = $cikti
}
$veriDir = Join-Path $kok "veri"
$hedef = Join-Path $veriDir "gtip-balik.json"
($out | ConvertTo-Json -Depth 5 -Compress) | Out-File $hedef -Encoding utf8
""
"BALIK HASAT BITTI. $($cikti.Count) kod"
"veri\gtip-balik.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
"--- ornek 0302.11 (alabalik) veya ilk kod ---"
$ilk = @($cikti.Keys)[0]
"  $ilk : GV=$(($cikti[$ilk].gv) -join ',') | EMY=$(($cikti[$ilk].emy) -join ',')"
$hamsi = @($cikti.Keys | Where-Object { $_ -match "^0303" }) | Select-Object -First 1
if($hamsi){ "  $hamsi : GV=$(($cikti[$hamsi].gv) -join ',') | EMY=$(($cikti[$hamsi].emy) -join ',')" }
