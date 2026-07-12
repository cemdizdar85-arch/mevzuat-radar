# ============================================================================
#  NIHAI HASAT - Ithalat Rejimi VI + VII Sayili Liste (nihai kullanim indirimli GV)
#  VI  : sivil hava tasitlarinda kullanilacak urunler (kol3=GTP, kol5=tanim, kol6=GV)
#  VII : belirli nihai urun uretiminde kullanilacak tarim urunleri
#        (kol1=GTIP, kol2=tanim, kol3=nihai urun, kol4=GV)
#  Ikisi de SARTLIDIR (nihai kullanim izni). "indirimli GV alabilir, sartli" denir.
#  Cikti: veri\gtip-nihai.json = { kodlar: { "digits": {"ad":tanim,"tur":"VI/VII"} } }
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }

function OkuListe($dosya, $kodKol, $tanimKol){
  $sonuc = @{}
  $zip = [System.IO.Compression.ZipFile]::OpenRead($dosya)
  $e = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
  $ss=@(); if($e){ $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $x=$sr.ReadToEnd(); $sr.Close(); foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($x)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'(?s)<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) } }
  $cellRx=[regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
  foreach($sh in ($zip.Entries | Where-Object { $_.FullName -match "xl/worksheets/sheet\d+\.xml$" })){
    $sr2=New-Object System.IO.StreamReader($sh.Open(),[System.Text.Encoding]::UTF8); $shx=$sr2.ReadToEnd(); $sr2.Close()
    foreach($rm in ([regex]'(?s)<row[^>]*>(.*?)</row>').Matches($shx)){
      $h=@{}
      foreach($cm in $cellRx.Matches($rm.Groups[1].Value)){ $idx=KolIdx $cm.Groups[1].Value; if($cm.Groups[2].Value -eq "s" -and $cm.Groups[3].Value -ne ""){$h[$idx]=$ss[[int]$cm.Groups[3].Value]}elseif($cm.Groups[4].Value -ne ""){$h[$idx]=[System.Net.WebUtility]::HtmlDecode($cm.Groups[4].Value)}else{$h[$idx]=$cm.Groups[3].Value} }
      $kodHam = ([string]$h[$kodKol])
      foreach($m in [regex]::Matches($kodHam, '\d{2,4}(?:\.\d{2}){1,4}')){
        $digits = ($m.Value -replace '[^\d]','')
        if($digits.Length -lt 4){ continue }
        $tanim = (([string]$h[$tanimKol]) -replace '\s+',' ').Trim()
        if(-not $sonuc.ContainsKey($digits)){ $sonuc[$digits] = $tanim }
      }
    }
  }
  $zip.Dispose()
  return $sonuc
}

$kodlar = [ordered]@{}
$vi  = Get-ChildItem $RejimKlasor -Filter *.xlsx | Where-Object { $_.Name -match "^VI " } | Select-Object -First 1
$vii = Get-ChildItem $RejimKlasor -Filter *.xlsx | Where-Object { $_.Name -match "^VII " } | Select-Object -First 1
if($vi){  $o = OkuListe $vi.FullName  2 4; foreach($k in $o.Keys){ $kodlar[$k] = @{ ad=$o[$k]; tur="VI (sivil hava taşıtı)" } } }
if($vii){ $o = OkuListe $vii.FullName 0 1; foreach($k in $o.Keys){ if(-not $kodlar.Contains($k)){ $kodlar[$k] = @{ ad=$o[$k]; tur="VII (nihai kullanım tarım)" } } } }

$out = [ordered]@{
  aciklama = "İthalat Rejimi VI (sivil hava taşıtı) + VII (nihai kullanım tarım) Sayılı Listeler — belirli nihai kullanım şartıyla indirimli/sıfır gümrük vergisi. ŞARTLIDIR: nihai kullanım izni + ürünün birebir bu amaçla kullanılması gerekir."
  kodlar = $kodlar
}
$veriDir = Join-Path $kok "veri"
$hedef = Join-Path $veriDir "gtip-nihai.json"
($out | ConvertTo-Json -Depth 3 -Compress) | Out-File $hedef -Encoding utf8
""
"NIHAI HASAT BITTI. $($kodlar.Count) kod (VI+VII)"
"veri\gtip-nihai.json ($([math]::Round((Get-Item $hedef).Length/1KB)) KB)"
$i=0; foreach($k in $kodlar.Keys){ if($i -ge 3){break}; "  $k [$($kodlar[$k].tur)] => $($kodlar[$k].ad.Substring(0,[Math]::Min(50,$kodlar[$k].ad.Length)))"; $i++ }
