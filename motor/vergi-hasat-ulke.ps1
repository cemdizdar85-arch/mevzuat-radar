# ============================================================================
#  VERGI HASAT - ULKE BAZLI (SANAYI URUNLERI, fasil 25-97)
#  Ithalat Rejimi Karari II Sayili Liste (Sanayi) Excel'lerini ulke grubu
#  bazinda ayristirir (LLM YOK, kesin - dogrudan Excel hucre okuma).
#  Kolon semasi TUM sanayi dosyalarinda dogrulanmis olarak ayni:
#    kolon2=AB/EFTA/STA orta ulkeleri | kolon3=Katar | kolon4=BAE
#    kolon5=EAGU (En Az Gelismis) | kolon6=OTDU (Ozel Tesvik) | kolon7=GYU (Gelisme Yolunda)
#    kolon8=DU (Diger Ulkeler - Cin/ABD/Japonya/Hindistan vb. dahil normal oran)
#  NOT: 04-24. Fasillar (tarim) FARKLI sema kullanir, bilerek DISLANMISTIR.
#  Cikti: veri\gtip-vergi-ulke.json
# ============================================================================
param(
  [string]$RejimKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\rejim2026"
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

# Bir sanayi xlsx'ini oku -> @{ kod = @(kolon2,kolon3,kolon4,kolon5,kolon6,kolon7,kolon8) }
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
      $a = $aDuz
      $satir = @()
      $gecerli = $true
      for($k=2;$k -le 8;$k++){
        if($h.ContainsKey($k)){
          $v=($h[$k] -as [string]).Trim()
          if($v -match '^\d+([.,]\d+)?$'){ $satir += [double]($v -replace ',','.') }
          else { $satir += $null }
        } else { $satir += $null }
      }
      $sonuc[(Noktali $a)] = $satir
    }
  }
  $zip.Dispose()
  return $sonuc
}

# --- Sanayi dosyalari (04-24.Fasillar TARIM oldugu icin BILEREK haric) ---
$sanayiDosyalar = Get-ChildItem $RejimKlasor -Filter "II*.xlsx" | Where-Object { $_.Name -notmatch "04-24" }
$ulke = @{}
$GRUP = @("abSta","katar","bae","eagu","otdu","gyu","du")
foreach($d in $sanayiDosyalar){
  $o = XlsxUlkeOran $d.FullName
  foreach($k in $o.Keys){ if(-not $ulke.ContainsKey($k)){ $ulke[$k] = $o[$k] } }
  Write-Host ("{0}: +{1} kod (toplam {2})" -f $d.Name, $o.Count, $ulke.Count)
}

# --- kompakt JSON: kod => [abSta,katar,bae,eagu,otdu,gyu,du] ---
$cikti = [ordered]@{}
foreach($kod in ($ulke.Keys | Sort-Object)){ $cikti[$kod] = $ulke[$kod] }
$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($cikti | ConvertTo-Json -Depth 3 -Compress) | Out-File (Join-Path $veriDir "gtip-vergi-ulke.json") -Encoding utf8

# grup etiketlerini de ayri kucuk dosyaya yaz (UI icin)
$etiketler = [ordered]@{
  "abSta"="AB / EFTA / STA ortağı ülke (İngiltere, İsrail, G.Kore, Sırbistan, Arnavutluk, Şili, Kuzey Makedonya, Bosna-Hersek, Fas, Tunus, Mısır, Gürcistan, Moldova, Karadağ, Kosova, Malezya, Singapur, Filistin, Faroe Adaları, Venezuela)"
  "katar"="Katar"
  "bae"="Birleşik Arap Emirlikleri"
  "eagu"="En Az Gelişmiş Ülke"
  "otdu"="Özel Teşvik Düzenlemesi kapsamındaki ülke"
  "gyu"="Gelişme Yolundaki Ülke (GTS listesi)"
  "du"="Diğer ülkeler (Çin, ABD, Japonya, Hindistan, Rusya vb. — çoğu ülke)"
}
($etiketler | ConvertTo-Json -Depth 2) | Out-File (Join-Path $veriDir "gtip-ulke-gruplari.json") -Encoding utf8

""
"HASAT BITTI. Sanayi urunleri (fasil 25-97), ulke bazli: $($cikti.Count) kod"
"veri\gtip-vergi-ulke.json yazildi ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-vergi-ulke.json')).Length/1KB)) KB)"
"--- ornek: 8601.10.00.00.00 (lokomotif) ---"
if($cikti.Contains("8601.10.00.00.00")){ "  abSta,katar,bae,eagu,otdu,gyu,du = " + ($cikti["8601.10.00.00.00"] -join ", ") }
"--- kac kodda DU (diger ulke) esik ile AB-STA esigi farkli (gercek fark var mi kontrolu) ---"
$farkli = 0
foreach($k in $cikti.Keys){ $v=$cikti[$k]; if($v[0] -ne $null -and $v[6] -ne $null -and $v[0] -ne $v[6]){ $farkli++ } }
"  $farkli / $($cikti.Count) kodda AB-STA ile Diger Ulkeler orani FARKLI"
