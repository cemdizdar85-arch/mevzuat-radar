# ============================================================================
#  DAMPING SORUSTURMA HASAT (30.08.2026)
#  Ticaret Bak. "Yurutulen Sorusturmalar" xlsx -> veri/damping-sorusturma.json
#
#  NEDEN VAR: gtip-damping.json YURURLUKTEKI onlemi soyler ("bu koddan alirsan
#  su kadar EK vergi odersin"). Ama ithalatci icin bir soru daha var ve cevabi
#  hicbir yerde yok: "bu kodda ACIK SORUSTURMA var mi?" 30.08 olcumu: 148 GTIP
#  kodunda acik sorusturma var, bunlarin 101'inde BUGUN hicbir onlem YOK.
#  Yani o 101 kodda mal bugun vergisiz giriyor ama sorusturma sonuclanirsa
#  gecici/kesin vergi gelebilir - siparis ve akreditif karari bunu bilmeli.
#  (Yonetmelik m.30: sorusturma 1 yilda biter, Kurulca 6 ay uzatilabilir.)
#
#  KAYIT SEMASI (site okur):
#    k  = GTIP kodlari (noktasiz, bosluklu)   u  = ulke
#    m  = madde ismi                          st = sorusturma turu (DS / NGGS / ...)
#    tb = teblig no                           ta = acilis RG tarihi (yyyy-MM-dd)
#    go = gecici onlem orani/miktari (varsa)  gt = gecici onlem RG tarihi (varsa)
#    s  = kaynak sayfa (damping / subvansiyon)
#  Tarih olmayan hucre BOS birakilir - UYDURULMAZ.
#
#  Sutunlar sabit indisle DEGIL BASLIK METNIYLE bulunur; paylasilan metin
#  okuyucusunda (?s) VARDIR (30.08 dersi: yoksa cok satirli GTIP hucreleri
#  bos okunur ve satirlarin yarisi sessizce duser).
#
#  Kullanim: ./motor/damping-sorusturma-hasat.ps1 -Xlsx <yurutulen.xlsx>
#  Dogrulama: node motor/damping-kiyas.js  (devam_eden_sorusturma_satir ile karsilastir)
# ============================================================================
param(
  [string]$Xlsx,
  [switch]$ZorlaAzalt
)
$ErrorActionPreference = "Stop"
try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch {}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $Xlsx -or -not (Test-Path $Xlsx)){ throw "KIRMIZI: -Xlsx verilmedi ya da dosya yok: $Xlsx" }

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)
function OkuE($ad){ $e=$zip.Entries|Where-Object{$_.FullName -eq $ad}|Select-Object -First 1; if(-not $e){return $null}; $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }

$ss=@()
$ssXml=OkuE "xl/sharedStrings.xml"
if($ssXml){ foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'(?s)<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({$_.Groups[1].Value}))) } }

$rowRx=[regex]'(?s)<row[^>]*r="(\d+)"[^>]*>(.*?)</row>'
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
function Al($h,$i){ if($null -eq $i){ return "" }; if($h.ContainsKey($i)){ return (($h[$i] -as [string]).Trim()) } return "" }

function SayfaHaritasi(){
  $wb = OkuE "xl/workbook.xml"; $rel = OkuE "xl/_rels/workbook.xml.rels"
  if(-not $wb -or -not $rel){ return @{} }
  $rmap=@{}
  foreach($m in ([regex]'Id="([^"]+)"[^>]*Target="([^"]+)"').Matches($rel)){ $rmap[$m.Groups[1].Value] = ($m.Groups[2].Value -replace '^/?xl/','') }
  $out=@{}
  foreach($m in ([regex]'<sheet[^>]*name="([^"]+)"[^>]*r:id="([^"]+)"').Matches($wb)){
    $ad=[System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value); $rid=$m.Groups[2].Value
    if($rmap.ContainsKey($rid)){ $out[$ad] = "xl/" + $rmap[$rid] }
  }
  return $out
}

# Bu dosyada baslik iki satirdir (TR ustte, EN altta) ve TR satirinda GTIP gecer.
function SutunEsle($rows){
  $ust = [math]::Min($rows.Count, 30)
  for($i=0; $i -lt $ust; $i++){
    $r = $rows[$i]
    $baslikMi = $false
    foreach($k in $r.Keys){ if("$($r[$k])" -match 'G\.?T\.?İ\.?P'){ $baslikMi = $true; break } }
    if(-not $baslikMi){ continue }
    $map=@{}
    foreach($k in ($r.Keys | Sort-Object)){                 # soldan saga, ilk eslesen kazanir
      $b = (("$($r[$k])") -replace '\s+',' ').Trim()        # basliklarda satir kirigi var
      if(-not $map.ContainsKey('gtip')   -and $b -match 'G\.?T\.?İ\.?P'){ $map['gtip']=$k;   continue }
      if(-not $map.ContainsKey('urun')   -and $b -match 'MADDE İSMİ'   ){ $map['urun']=$k;   continue }
      if(-not $map.ContainsKey('ulke')   -and $b -match '^ÜLKE'        ){ $map['ulke']=$k;   continue }
      if(-not $map.ContainsKey('gtb')    -and $b -match 'GEÇİCİ ÖNLEM TEBLİĞ'){ $map['gtb']=$k; continue }
      if(-not $map.ContainsKey('gtar')   -and $b -match 'GEÇİCİ ÖNLEM RG TARİHİ'){ $map['gtar']=$k; continue }
      if(-not $map.ContainsKey('teblig') -and $b -match 'TEBLİĞ NO'    ){ $map['teblig']=$k; continue }
      if(-not $map.ContainsKey('tarih')  -and $b -match 'RG TARİH'     ){ $map['tarih']=$k;  continue }
      if(-not $map.ContainsKey('tur')    -and $b -match 'SORUŞTURMA TÜRÜ'){ $map['tur']=$k;  continue }
      if(-not $map.ContainsKey('oran')   -and $b -match 'ÖNLEM ORANI'  ){ $map['oran']=$k;   continue }
    }
    $map['_baslik']=$i
    return $map
  }
  return $null
}

function SeriTarih($ham){
  $n = 0.0
  if([double]::TryParse($ham, [ref]$n) -and $n -gt 20000 -and $n -lt 90000){
    return ([datetime]'1899-12-30').AddDays([math]::Floor($n)).ToString('yyyy-MM-dd')
  }
  return ""
}

$kayitlar=@()
$harita = SayfaHaritasi
if(-not $harita.Count){ throw "KIRMIZI: calisma kitabinin sayfa haritasi okunamadi." }
$okunanSayfa = 0
foreach($ad in ($harita.Keys | Sort-Object)){
  $sinif = $null
  if($ad -match 'Damping|Dumping'){ $sinif='damping' } elseif($ad -match 'Subvansiyon|Sübvansiyon|Subsidy'){ $sinif='subvansiyon' }
  if(-not $sinif){ continue }
  $rows = SheetOku $harita[$ad]
  $map  = SutunEsle $rows
  if(-not $map -or -not $map.ContainsKey('gtip') -or -not $map.ContainsKey('ulke')){
    Write-Host "  UYARI: '$ad' sayfasinda baslik/GTIP-ULKE sutunu bulunamadi, atlandi."
    continue
  }
  $okunanSayfa++
  foreach($h in $rows){
    $gtipHam = Al $h $map['gtip']
    $ulke    = Al $h $map['ulke']
    if(-not $gtipHam -or -not $ulke){ continue }
    if($gtipHam -match 'G\.?T\.?İ\.?P|CN CODE' -or $ulke -match '^ÜLKE|^COUNTRY'){ continue }
    $kodlar = @()
    foreach($tok in ($gtipHam -split '\s+')){
      $t2 = ($tok -replace '[^\d.]','').Trim('.')
      if($t2 -match '^\d{2,4}(\.\d{2}){0,4}$'){ $kodlar += ($t2 -replace '\.','') }
    }
    if(-not $kodlar.Count){ continue }
    $kayitlar += [ordered]@{
      k  = ($kodlar -join " ")
      u  = $ulke
      m  = (Al $h $map['urun'])
      st = (Al $h $map['tur'])
      tb = (Al $h $map['teblig'])
      ta = (SeriTarih (Al $h $map['tarih']))
      go = (Al $h $map['oran'])
      gt = (SeriTarih (Al $h $map['gtar']))
      s  = $sinif
    }
  }
}
$zip.Dispose()
if($okunanSayfa -eq 0){ throw "KIRMIZI: dosyada damping/subvansiyon sayfasi bulunamadi - Bakanlik bicimi degismis olabilir." }

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
$ciktiYol = Join-Path $veriDir "damping-sorusturma.json"

# AZALMA KAPISI: sorusturma listesi damping listesinden daha oynaktir (sorusturma
# biter, kayit duser) - bu yuzden esik %40. Ama SIFIRA dusmek her zaman kusurdur.
$eskiN = 0
if(Test-Path $ciktiYol){ try { $eskiN = @((Get-Content $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json)).Count } catch { $eskiN = 0 } }
if($kayitlar.Count -eq 0){ throw "KIRMIZI: hic kayit cikmadi - dosyaya DOKUNULMADI." }
if($eskiN -gt 0 -and -not $ZorlaAzalt -and ($eskiN - $kayitlar.Count) -gt [math]::Ceiling($eskiN*0.40)){
  throw "KIRMIZI (azalma kapisi): $eskiN -> $($kayitlar.Count). Dosyaya DOKUNULMADI. Gercekten toplu kapanma olduysa: -ZorlaAzalt"
}

($kayitlar | ConvertTo-Json -Depth 3 -Compress) | Out-File $ciktiYol -Encoding utf8
$acik = @($kayitlar | Where-Object { $_.ta }).Count
"BITTI. Devam eden sorusturma: $($kayitlar.Count) kayit -> veri\damping-sorusturma.json ($([math]::Round((Get-Item $ciktiYol).Length/1KB)) KB)"
$turSay=@{}; foreach($x in $kayitlar){ $ad = if($x.st){ $x.st } else { '(bos)' }; $turSay[$ad] = 1 + $(if($turSay.ContainsKey($ad)){ $turSay[$ad] } else { 0 }) }
"  acilis tarihi okunan: $acik/$($kayitlar.Count) | urun: $(($kayitlar | ForEach-Object { $_.m } | Sort-Object -Unique).Count) | tur: $(($turSay.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' ')"
$kayitlar | Select-Object -First 3 | ForEach-Object { "  {0} | {1} | {2} | {3} | acilis {4}" -f $_.st, $_.m, $_.u, $_.tb, $_.ta }
