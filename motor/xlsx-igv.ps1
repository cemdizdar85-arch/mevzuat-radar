# ============================================================================
#  XLSX -> IGV JSON ayristirici (LLM YOK - birebir Excel'den, kesin, bedava)
#  Ek-1.xlsx (Ilave Gumruk Vergisi oranlari) -> gtip-igv.json
# ============================================================================
param(
  [string]$Xlsx = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\igv2026\Ek-1.xlsx",
  [switch]$Onizle
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# xlsx = zip; sharedStrings + sheet1 oku
$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)
function OkuEntry($ad){
  $e = $zip.Entries | Where-Object { $_.FullName -eq $ad } | Select-Object -First 1
  if(-not $e){ return $null }
  $sr = New-Object System.IO.StreamReader($e.Open(), [System.Text.Encoding]::UTF8)
  $t = $sr.ReadToEnd(); $sr.Close(); return $t
}
$ssXml = OkuEntry "xl/sharedStrings.xml"
$shXml = OkuEntry "xl/worksheets/sheet1.xml"
$zip.Dispose()

# shared strings dizisi
$ss = @()
if($ssXml){
  $rx = [regex]'(?s)<si>(.*?)</si>'
  foreach($m in $rx.Matches($ssXml)){
    $ic = $m.Groups[1].Value
    $metin = -join ([regex]'<t[^>]*>(.*?)</t>').Matches($ic).ForEach({ $_.Groups[1].Value })
    $ss += [System.Net.WebUtility]::HtmlDecode($metin)
  }
}

# harf -> kolon indexi (A=0)
function KolIdx($ref){
  $h = ($ref -replace '\d','').ToUpper()
  $n = 0; foreach($ch in $h.ToCharArray()){ $n = $n*26 + ([int][char]$ch - 64) }
  return $n - 1
}

# satirlari cozumle
$satirlar = @()
$rowRx = [regex]'(?s)<row[^>]*r="(\d+)"[^>]*>(.*?)</row>'
$cellRx = [regex]'(?s)<c r="([A-Z]+\d+)"(?:[^>]*t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t[^>]*>(.*?)</t></is>)?</c>'
foreach($rm in $rowRx.Matches($shXml)){
  $rno = [int]$rm.Groups[1].Value
  $hucreler = @{}
  foreach($cm in $cellRx.Matches($rm.Groups[2].Value)){
    $ref = $cm.Groups[1].Value; $tip = $cm.Groups[2].Value; $val = $cm.Groups[3].Value; $inl = $cm.Groups[4].Value
    $idx = KolIdx $ref
    if($tip -eq "s" -and $val -ne ""){ $deger = $ss[[int]$val] }
    elseif($inl -ne ""){ $deger = [System.Net.WebUtility]::HtmlDecode($inl) }
    else { $deger = $val }
    $hucreler[$idx] = $deger
  }
  $satirlar += [pscustomobject]@{ r=$rno; h=$hucreler }
}

if($Onizle){
  "Toplam satir: $($satirlar.Count) | shared string: $($ss.Count)"
  "--- ilk 15 satir (kolonIndex:deger) ---"
  foreach($st in ($satirlar | Select-Object -First 15)){
    $parcalar = @()
    foreach($k in ($st.h.Keys | Sort-Object)){ $parcalar += ("{0}:{1}" -f $k, $st.h[$k]) }
    "satir $($st.r) => " + ($parcalar -join "  |  ")
  }
  return
}

# 12 haneli kodu noktali formata cevir: 251511000000 -> 2515.11.00.00.00
function Noktali($k12){
  if($k12.Length -ne 12){ return $k12 }
  return $k12.Substring(0,4)+"."+$k12.Substring(4,2)+"."+$k12.Substring(6,2)+"."+$k12.Substring(8,2)+"."+$k12.Substring(10,2)
}

$igv = [ordered]@{}
foreach($st in $satirlar){
  $a = if($st.h.ContainsKey(0)){ ($st.h[0] -as [string]).Trim() } else { "" }
  if($a -notmatch '^\d{12}$'){ continue }   # GTIP kodu satiri degil
  # oran kolonlari: index 2..8 (Sutun 1-7, mense ulke grubu)
  $oranlar = @()
  for($k=2; $k -le 8; $k++){
    if($st.h.ContainsKey($k)){
      $v = ($st.h[$k] -as [string]).Trim()
      if($v -match '^\d+([.,]\d+)?$'){ $oranlar += [double]($v -replace ',','.') }
    }
  }
  if(-not $oranlar.Count){ continue }
  $kod = Noktali $a
  $mn = ($oranlar | Measure-Object -Minimum).Minimum
  $mx = ($oranlar | Measure-Object -Maximum).Maximum
  $igv[$kod] = [ordered]@{ min=$mn; max=$mx; oranlar=$oranlar }
}

$ciktiDir = Join-Path $here "hafiza"
New-Item -ItemType Directory -Force $ciktiDir | Out-Null
($igv | ConvertTo-Json -Depth 4) | Out-File (Join-Path $ciktiDir "gtip-igv.json") -Encoding utf8
"BITTI. IGV oranli GTIP: $($igv.Count) kod -> hafiza\gtip-igv.json"
"Ornek 6 kayit:"
$igv.GetEnumerator() | Select-Object -First 6 | ForEach-Object { "  {0} => IGV %{1}-%{2} (Sutun 1-7: {3})" -f $_.Key, $_.Value.min, $_.Value.max, ($_.Value.oranlar -join ",") }
