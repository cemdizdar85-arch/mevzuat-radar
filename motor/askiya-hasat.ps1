# ============================================================================
#  ASKIYA HASAT - Ithalat Rejimi V Sayili Liste
#  (GUMRUK VERGISI ASKIYA ALINAN SANAYI URUNLERI - GV %0, sartli)
#  Sutunlar: 1=GTP, 2=KAYIT NO, 3=SERI NO, 4=DIPNOT, 5=ESYA TANIMI, 6=GV(%), 7=tarih
#  Bir hucrede birden fazla GTP olabilir (alt alta). Kod pozisyon/alt-baslik
#  duzeyinde (6-10 hane) - tam 12 hane degil. Eslesme: sorgu kodu bu onekle baslarsa.
#  KURAL: GV=0 ama SARTLIDIR (nihai kullanim/dipnot). "askiya alinmis OLABILIR" denir.
#  Cikti: veri\gtip-askiya.json = { kodlar: { "onekDigits": "esya tanimi" } }
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }

$dosya = (Get-ChildItem $RejimKlasor -Filter "*.xlsx" | Where-Object { $_.Name -match "^V " } | Select-Object -First 1)
if(-not $dosya){ Write-Host "V Sayili Liste bulunamadi!"; exit 1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($dosya.FullName)
$e = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
$ss=@(); if($e){ $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $ssXml=$sr.ReadToEnd(); $sr.Close(); foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'(?s)<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) } }
$cellRx=[regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
$kodlar=[ordered]@{}
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
    $gtpHam = ($h[0] -as [string])
    if(-not $gtpHam){ continue }
    $tanim = (($h[4] -as [string]) -replace '\s+',' ').Trim()
    # hucredeki her GTP kodunu ayikla (NN.NN veya NNNN.NN.NN... formatlari)
    foreach($m in [regex]::Matches($gtpHam, '\d{2,4}(?:\.\d{2}){1,4}')){
      $digits = ($m.Value -replace '[^\d]','')
      if($digits.Length -lt 4){ continue }
      if(-not $kodlar.Contains($digits)){ $kodlar[$digits] = $tanim }
    }
  }
}
$zip.Dispose()

$out = [ordered]@{
  aciklama = "İthalat Rejimi Kararı V Sayılı Liste — gümrük vergisi ASKIYA ALINMIŞ sanayi ürünleri (GV %0). Askıya alma ŞARTLIDIR (nihai kullanım/dipnot); kod bu listede geçiyorsa GV sıfır OLABİLİR, şartları kontrol et."
  kodlar = $kodlar
}
$veriDir = Join-Path $kok "veri"
$hedef = Join-Path $veriDir "gtip-askiya.json"
($out | ConvertTo-Json -Depth 3 -Compress) | Out-File $hedef -Encoding utf8
""
"ASKIYA HASAT BITTI. $($kodlar.Count) pozisyon/kod oneki"
"veri\gtip-askiya.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
"--- ilk 3 ornek ---"
$i=0; foreach($k in $kodlar.Keys){ if($i -ge 3){break}; "  $k => $($kodlar[$k].Substring(0,[Math]::Min(70,$kodlar[$k].Length)))"; $i++ }
