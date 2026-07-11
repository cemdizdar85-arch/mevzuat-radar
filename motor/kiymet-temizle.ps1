# ============================================================================
#  KIYMET TEMIZLE - ham kiymetler.json'dan SADECE gercek deger/oran kaliplarini
#  suzer (urun tanimi/cop kayitlari atar), tarihe gore siralar, dedup yapar.
#  Cikti: veri\radar-kiymet.json (siteye - kiyas icin)
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok = Split-Path -Parent $here
$j = Get-Content (Join-Path $here "hafiza\kiymetler.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# gecerli deger kalibi: sayi + para/oran birimi (or "1.500 ABD Doları/Ton", "%25", "174 $/Kg")
$degerRx = [regex]'(?i)(^|\s)(%\s*\d|[\d.,]+\s*(%|ABD\s*Dolar|USD|\$|Euro|EUR|TL|Dolar))'
# cop isareti: cok fazla harf (urun tanimi)
function Gecerli($d){
  if(-not $d){ return $false }
  $d = ($d -as [string]).Trim()
  if($d.Length -gt 60){ return $false }              # uzun = tanim
  if(-not $degerRx.IsMatch($d)){ return $false }     # deger kalibi yok
  $harf = ([regex]::Matches($d,'[A-Za-zÇĞİÖŞÜçğıöşü]')).Count
  if($harf -gt 22){ return $false }                  # cok harfli = tanim
  return $true
}
# dedup anahtari: sayisal deger + ilk birim harfi (encoding/Turkce farklarini yutar)
function DedupKey($d){
  $s = ($d -as [string])
  $sayi = ([regex]::Match($s,'[\d.,]+')).Value -replace ',','.'
  $birim = ""
  if($s -match '(?i)ton'){ $birim='ton' } elseif($s -match '(?i)k[gı]|kilo'){ $birim='kg' } elseif($s -match '%'){ $birim='%' } elseif($s -match '(?i)adet'){ $birim='adet' }
  return "$sayi|$birim"
}

$temiz = [ordered]@{}
$toplamHam = 0; $toplamGecerli = 0
foreach($p in $j.PSObject.Properties){
  $kod = $p.Name
  $kayitlar = @($p.Value)
  $gorulen = @{}
  $liste = @()
  foreach($e in $kayitlar){
    $toplamHam++
    if(-not (Gecerli $e.deger)){ continue }
    $anahtar = ($e.tarih + "|" + (DedupKey $e.deger))
    if($gorulen[$anahtar]){ continue }
    $gorulen[$anahtar] = $true
    $liste += [pscustomobject]@{ tarih=$e.tarih; deger=(($e.deger -as [string]) -replace '\s+',' ').Trim(); teblig=$e.teblig }
    $toplamGecerli++
  }
  if($liste.Count){
    # tarihe gore sirala (GG.AA.YYYY -> sortable)
    $liste = $liste | Sort-Object { $t=$_.tarih.Split('.'); "$($t[2])$($t[1])$($t[0])" }
    $temiz[$kod] = $liste
  }
}

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
($temiz | ConvertTo-Json -Depth 5 -Compress) | Out-File (Join-Path $veriDir "radar-kiymet.json") -Encoding utf8

$cokKayit = @($temiz.Keys | Where-Object { @($temiz[$_]).Count -ge 2 })
"TEMIZLENDI. Ham kayit: $toplamHam -> Gecerli: $toplamGecerli"
"Temiz kod: $($temiz.Keys.Count) | Tarihcesi olan (>=2): $($cokKayit.Count)"
"--- ornek tarihce (>=2 kayit) ---"
$cokKayit | Select-Object -First 6 | ForEach-Object {
  $s = @($temiz[$_]) | ForEach-Object { "$($_.tarih):$($_.deger)" }
  "  $_ => $($s -join '  ->  ')"
}