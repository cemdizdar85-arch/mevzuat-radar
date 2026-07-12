# ============================================================================
#  TARIM HASAT - Ithalat Rejimi tarim listeleri (I Sayili, II 04-24, III islenmis)
#  Bu listelerde her ulke AYRI SUTUN ve rate'ler gercekten ulke bazli farkli.
#  Sanayi gibi sabit 7-grup DEGIL - bu yuzden BASLIK OKUYARAK dinamik eslestirir.
#  Cikti: veri\gtip-vergi-tarim.json = { kod: { "Ulke Adi": oran, ... } }
#  NOT: III'teki Tarim Payi EMY (EURO/100kg, kolon14+) BILEREK atlanir - farkli
#       birim + "T2" gibi kod degerleri var, ayri katman.
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

# kisaltma -> tam ulke/grup adi (Ithalat Rejimi Karari Kisaltmalar bolumunden)
function UlkeAdi($k){
  $k = ($k -as [string]).Trim() -replace '\s+',' '
  $map = @{
    "AB, BK"="AB / İngiltere"; "AB,BK"="AB / İngiltere"
    "AB, BK, B-HER, EFTA, F.ADA"="AB / İngiltere / Bosna-Hersek / EFTA / Faroe Ad."
    "AB, EFTA, F.ADA., B-HER."="AB / EFTA / Faroe Ad. / Bosna-Hersek"
    "AB, EFTA, F. ADA, B-HER"="AB / EFTA / Faroe Ad. / Bosna-Hersek"
    "GÜR"="Gürcistan"; "B-HER"="Bosna-Hersek"; "B–HER"="Bosna-Hersek"
    "G.KORE"="Güney Kore"; "G. KORE"="Güney Kore"
    "MLZ"="Malezya"; "MLZY."="Malezya"; "SNG"="Singapur"; "SİNG."="Singapur"
    "KOS"="Kosova"; "KOS."="Kosova"; "VNZ"="Venezuela"; "BAE"="BAE"
    "İRAN"="İran"; "TPS-OIC"="İslam Konferansı (TPS-OIC) ülkeleri"; "D-8"="D-8 ülkeleri"
    "EAGÜ"="En Az Gelişmiş Ülkeler"; "ÖTDÜ"="Özel Teşvik Düzenlemesi ülkeleri"; "GYÜ"="Gelişme Yolundaki Ülkeler"
    "GTS ÜLKELERİ"="GTS ülkeleri"; "G.T.S. ÜLKELERİ"="GTS ülkeleri"
    "DÜ"="Diğer Ülkeler (Çin, ABD, Japonya, Rusya…)"
  }
  if($map.ContainsKey($k)){ return $map[$k] }
  return $k  # tanimadigimiz basligi oldugu gibi birak (uydurmaktan iyi)
}

function TarimOku($xlsx){
  $sonuc = @{}
  try { $zip = [System.IO.Compression.ZipFile]::OpenRead($xlsx) } catch { return $sonuc }
  function OkuE($z,$ad){ $e = $z.Entries | Where-Object { $_.FullName -eq $ad } | Select-Object -First 1; if(-not $e){ return $null }; $sr = New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
  $ssXml = OkuE $zip "xl/sharedStrings.xml"
  $ss = @()
  if($ssXml){ foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({ $_.Groups[1].Value }))) } }
  $rowRx = [regex]'(?s)<row[^>]*>(.*?)</row>'
  $cellRx = [regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
  foreach($sh in ($zip.Entries | Where-Object { $_.FullName -match "xl/worksheets/sheet\d+\.xml$" })){
    $sr = New-Object System.IO.StreamReader($sh.Open(),[System.Text.Encoding]::UTF8); $shXml = $sr.ReadToEnd(); $sr.Close()
    $satirlar = @()
    foreach($rm in $rowRx.Matches($shXml)){
      $h = @{}
      foreach($cm in $cellRx.Matches($rm.Groups[1].Value)){
        $idx = KolIdx $cm.Groups[1].Value
        if($cm.Groups[2].Value -eq "s" -and $cm.Groups[3].Value -ne ""){ $h[$idx] = $ss[[int]$cm.Groups[3].Value] }
        elseif($cm.Groups[4].Value -ne ""){ $h[$idx] = [System.Net.WebUtility]::HtmlDecode($cm.Groups[4].Value) }
        else { $h[$idx] = $cm.Groups[3].Value }
      }
      $satirlar += ,$h
    }
    # --- ILK VERI SATIRININ INDEKSINI BUL (baslik bolgesi bunun ONCESI) ---
    $ilkVeri = $satirlar.Count
    for($i=0;$i -lt $satirlar.Count;$i++){
      $c0=($satirlar[$i][0] -as [string]).Trim() -replace '\.',''
      if($c0 -match '^\d{11,12}$'){ $ilkVeri = $i; break }
    }
    # --- BASLIK ESLESTIRME: SADECE ilk veri satirindan ONCEKI basliklarda ara ---
    # (alt/dip footnote'lardaki 'EK MALI' text'i emyKol'u sasirtmasin)
    $emyKol = 999
    for($i=0;$i -lt $ilkVeri;$i++){
      foreach($k in $satirlar[$i].Keys){
        if($k -lt 3){ continue }  # EMY her zaman sag tarafta, kol0-2'de olamaz
        if(($satirlar[$i][$k] -as [string]) -match "TARIM PAYI|EK MALİ YÜKÜMLÜLÜK"){ if($k -lt $emyKol){ $emyKol = $k } }
      }
    }
    # ulke etiket haritasi: SADECE baslik bolgesinden (kolon>=2, EMY oncesi)
    $kolAd = @{}
    for($i=0;$i -lt $ilkVeri;$i++){
      foreach($k in $satirlar[$i].Keys){
        if($k -lt 2 -or $k -ge $emyKol){ continue }
        $t = ($satirlar[$i][$k] -as [string]).Trim()
        if($t -eq "" -or $t -match "GÜMRÜK VERGİSİ ORANI"){ continue }
        $kolAd[$k] = $t  # alt satir (EAGU/OTDU/GYU) parent'i ezsin
      }
    }
    if($kolAd.Count -eq 0){ continue }
    # --- VERI SATIRLARI ---
    foreach($h in $satirlar){
      $kod0 = ($h[0] -as [string]).Trim() -replace '\.',''
      if($kod0 -match '^\d{11}$'){ $kod0 = "0" + $kod0 }  # leading zero dusmus (Excel sayi)
      if($kod0 -notmatch '^\d{12}$'){ continue }
      $kodN = Noktali $kod0
      $oranlar = [ordered]@{}
      foreach($k in ($kolAd.Keys | Sort-Object)){
        if(-not $h.ContainsKey($k)){ continue }
        $v = ($h[$k] -as [string]).Trim()
        if($v -match '^\d+([.,]\d+)?$'){ $oranlar[(UlkeAdi $kolAd[$k])] = [math]::Round([double]($v -replace ',','.'),2) }
      }
      if($oranlar.Count){ $sonuc[$kodN] = $oranlar }
    }
  }
  $zip.Dispose()
  return $sonuc
}

$tarimDosyalar = @()
$hepsi = Get-ChildItem $RejimKlasor -Filter "*.xlsx"
foreach($d in $hepsi){ if($d.Name -match "04-24" -or $d.Name -match "^III " -or $d.Name -match "^I "){ $tarimDosyalar += $d } }

$tarim = @{}
foreach($d in $tarimDosyalar){
  $o = TarimOku $d.FullName
  foreach($k in $o.Keys){ if(-not $tarim.ContainsKey($k)){ $tarim[$k] = $o[$k] } }
  Write-Host ("{0}: +{1} kod (toplam {2})" -f $d.Name, $o.Count, $tarim.Count)
}

$cikti = [ordered]@{}
foreach($kod in ($tarim.Keys | Sort-Object)){ $cikti[$kod] = $tarim[$kod] }
$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($cikti | ConvertTo-Json -Depth 4 -Compress) | Out-File (Join-Path $veriDir "gtip-vergi-tarim.json") -Encoding utf8

""
"TARIM HASAT BITTI. $($cikti.Count) kod"
"veri\gtip-vergi-tarim.json ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-vergi-tarim.json')).Length/1KB)) KB)"
"--- DOGRULAMA: I Sayili 0102.91.00.00.00 (canli hayvan) ---"
$tk = "0102.91.00.00.00"
if($cikti.Contains($tk)){ foreach($u in $cikti[$tk].Keys){ "  $u => %$($cikti[$tk][$u])" } }
"--- ornek islenmis tarim 0403.20.49.00.00 ---"
$tk2 = "0403.20.49.00.00"
if($cikti.Contains($tk2)){ foreach($u in $cikti[$tk2].Keys){ "  $u => %$($cikti[$tk2][$u])" } }
