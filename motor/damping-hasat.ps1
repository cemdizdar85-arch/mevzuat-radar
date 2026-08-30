# ============================================================================
#  DAMPING HASAT - Ticaret Bak. "Yururlukteki Onlemler" xlsx -> gtip-damping.json
#  Kesin + Gecici onlem sayfalari (ADINDAN bulunur). LLM YOK, birebir.
#
#  30.08.2026 ONARIMI - uc kusur kapatildi, dordu de motor/damping-kiyas.js ile
#  olculdu (Bakanlik listesi <-> ambar): once 273 satirin 141'i hasat ediliyordu.
#   K1 paylasilan metin okuyucusunda (?s) yoktu -> cok satirli hucreler BOS
#   K2 kod suzgeci pozisyon kodlarini ('55.13') reddediyordu
#   K3 sutunlar sabit indisle okunuyordu -> Bakanlik sutun ekleyince kayiyordu
#  Onarim sonrasi dogrulama: node motor/damping-kiyas.js -> EKSIK 0 olmali.
# ============================================================================
param(
  [string]$Xlsx = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\damping.xlsx",
  [switch]$ZorlaAzalt   # kayit sayisi azaldiginda kapiyi bilerek gec (gercek kalkan onlem)
)
$ErrorActionPreference = "Stop"
try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch {}  # ubuntu pwsh: Core'da zaten yuklu
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function KolIdx($ref){ $h=($ref -replace '\d','').ToUpper(); $n=0; foreach($ch in $h.ToCharArray()){ $n=$n*26+([int][char]$ch-64) }; return $n-1 }

$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)
function OkuE($ad){ $e=$zip.Entries|Where-Object{$_.FullName -eq $ad}|Select-Object -First 1; if(-not $e){return $null}; $sr=New-Object System.IO.StreamReader($e.Open(),[System.Text.Encoding]::UTF8); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
$ss=@()
$ssXml=OkuE "xl/sharedStrings.xml"
# 30.08.2026 KUSUR-1 (KANITLI): asagidaki <t> kalibinda (?s) YOKTU. .NET'te (?s)
# olmadan nokta YENI SATIRI TUTMAZ; Bakanlik coklu GTIP'i tek hucrede alt alta
# yaziyor ("8415.10.90.00.11`r`n8415.10.90.00.19...") -> o paylasilan metin BOS
# donuyordu. Sonuc: 328 satirin 185'i "GTIP alani bos" diye dustu, 273 satirlik
# resmi listeden yalnizca 141 kayit hasat edildi. Klima, agir ticari lastik,
# sicak haddelenmis yassi celik, pet film, kontrplak gibi 27 urun sitede
# "damping onlemi yok" gorunuyordu. Kanit: ss[103] bos, ss[711] dolu.
if($ssXml){ foreach($m in ([regex]'(?s)<si>(.*?)</si>').Matches($ssXml)){ $ss += [System.Net.WebUtility]::HtmlDecode((-join ([regex]'(?s)<t[^>]*>(.*?)</t>').Matches($m.Groups[1].Value).ForEach({$_.Groups[1].Value}))) } }

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

# --- SAYFA ADINDAN dosya cozumu -------------------------------------------
# "sheet2 = Kesin, sheet3 = Gecici" SABITI YASAK: dosyada 5 sayfa var ve sira
# Bakanlik'in insafinda. Ad -> dosya eslemesi workbook.xml + rels'ten okunur.
function SayfaHaritasi(){
  $wb = OkuE "xl/workbook.xml"; $rel = OkuE "xl/_rels/workbook.xml.rels"
  if(-not $wb -or -not $rel){ return @{} }
  $rmap=@{}
  foreach($m in ([regex]'Id="([^"]+)"[^>]*Target="([^"]+)"').Matches($rel)){
    $rmap[$m.Groups[1].Value] = ($m.Groups[2].Value -replace '^/?xl/','')
  }
  $out=@{}
  foreach($m in ([regex]'<sheet[^>]*name="([^"]+)"[^>]*r:id="([^"]+)"').Matches($wb)){
    $ad=[System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
    $rid=$m.Groups[2].Value
    if($rmap.ContainsKey($rid)){ $out[$ad] = "xl/" + $rmap[$rid] }
  }
  return $out
}

# --- BASLIK METNINDEN sutun esleme ----------------------------------------
# SABIT INDIS YASAK: Bakanlik 30.08 oncesi bir tarihte araya "BILGILENDIRME
# RAPORU" sutunu ekledi; sabit indisli okuyucu orani bos, onlem turunu oran
# sanarak okumustu. Sutun artik BASLIK METNIYLE bulunur (gozetim dersi).
function SutunEsle($rows){
  $ust = [math]::Min($rows.Count, 30)
  for($i=0; $i -lt $ust; $i++){
    $r = $rows[$i]
    $baslikMi = $false
    foreach($k in $r.Keys){ if("$($r[$k])" -match 'G\.?T\.?İ\.?P'){ $baslikMi = $true; break } }
    if(-not $baslikMi){ continue }
    $map=@{}
    foreach($k in ($r.Keys | Sort-Object)){          # soldan saga: ilk eslesen kazanir
      $b = ("$($r[$k])").Trim()                       # (TR ad EN addan once gelir)
      if(-not $map.ContainsKey('gtip')   -and $b -match 'G\.?T\.?İ\.?P'){ $map['gtip']=$k;   continue }
      if(-not $map.ContainsKey('urun')   -and $b -match 'MADDE İSMİ'   ){ $map['urun']=$k;   continue }
      if(-not $map.ContainsKey('ulke')   -and $b -match '^ÜLKE'        ){ $map['ulke']=$k;   continue }
      if(-not $map.ContainsKey('teblig') -and $b -match 'TEBLİĞ NO'    ){ $map['teblig']=$k; continue }
      if(-not $map.ContainsKey('oran')   -and $b -match 'ÖNLEM ORANI'  ){ $map['oran']=$k;   continue }
      if(-not $map.ContainsKey('tur')    -and $b -match 'ÖNLEM TÜRÜ'   ){ $map['tur']=$k;    continue }
    }
    $map['_baslik']=$i
    return $map
  }
  return $null
}

$onlemler=@()
$harita = SayfaHaritasi
if(-not $harita.Count){ throw "KIRMIZI: calisma kitabinin sayfa haritasi okunamadi (workbook.xml/rels)." }
foreach($ad in ($harita.Keys | Sort-Object)){
  $tip = $null
  if($ad -match 'Kesin|Definitive'){ $tip='Kesin' } elseif($ad -match 'Ge[çc]ici|Prov'){ $tip='Gecici' }
  if(-not $tip){ continue }                                   # yardimci sayfalar (kisaltmalar vb.)
  $rows = SheetOku $harita[$ad]
  $map  = SutunEsle $rows
  if(-not $map -or -not $map.ContainsKey('gtip') -or -not $map.ContainsKey('ulke')){
    throw "KIRMIZI: '$ad' sayfasinda baslik satiri ya da GTIP/ULKE sutunu bulunamadi - Bakanlik bicimi degismis olabilir. Dosyaya DOKUNULMADI."
  }
  foreach($h in $rows){
    $gtipHam = Al $h $map['gtip']
    $ulke    = Al $h $map['ulke']
    $urun    = if($map.ContainsKey('urun')){ Al $h $map['urun'] } else { "" }
    # 30.08.2026: 'o' ve 't' AYNI degeri (onlem oranini) tasir. Tuketiciler uc
    # farkli sekilde okuyor - gtip/risk "m.o || m.t", senaryo-raporu ve
    # toplu-gtip dogrudan "m.t", oran kapisi once "m.t". Alan adini duzeltmek
    # dort sayfa + bir kapi demek; oran ikisine birden yazilarak hepsi korunur.
    $oran = if($map.ContainsKey('oran')){ Al $h $map['oran'] } else { "" }
    $teb  = if($map.ContainsKey('teblig')){ Al $h $map['teblig'] } else { "" }
    # baslik/bos satirlari ele
    if($gtipHam -match "G\.T\.İ\.P" -or $urun -eq "MADDE İSMİ"){ continue }
    # GTIP kodlarini ayikla (noktali kalibi olanlar)
    # 30.08.2026 KUSUR-2: kalip '^\d{4}...' idi; tebligin POZISYON duzeyinde
    # yazdigi kodlari ("55.13", "70.06", "44.12") reddediyordu -> 308 (kod,ulke)
    # cifti sessizce dusuyordu. gtip.html zaten iki yonlu on-ek eslesmesi yapiyor
    # (k.startsWith(q) || q.startsWith(k)), yani pozisyon kaydi ekranda calisir.
    $kodlar = @()
    foreach($tok in ($gtipHam -split '\s+')){
      $t2 = ($tok -replace '[^\d.]','').Trim('.')
      if($t2 -match '^\d{2,4}(\.\d{2}){0,4}$'){ $kodlar += ($t2 -replace '\.','') }  # noktasiz sakla
    }
    # anlamli kayit: en az kod+ulke olmali (oran bos olabilir - onlem VARLIGI bile uyaridir)
    if(-not $kodlar.Count -or -not $ulke){ continue }
    $onlemler += [ordered]@{
      k = ($kodlar -join " ")
      u = $ulke; m = $urun; o = $oran; t = $oran; tb = $teb; tur = $tip
    }
  }
}
$zip.Dispose()

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
$ciktiYol = Join-Path $veriDir "gtip-damping.json"

# --- AZALMA KAPISI --------------------------------------------------------
# Bu betigin kendi sigortasi. yanveri-onarici.ps1'in K4'u %30 sapmaya bakar ve
# ELLE kosuldugunda hic devrede degildir; oysa 30.08'de ogrenildi ki bir okuma
# kusuru kayit sayisini yariya dusurebilir ve sonuc "yesil kosu" gibi gorunur.
# Kural: kayit sayisi ONCEKINDEN AZ ise dosyaya DOKUNULMAZ ve neden soylenir.
# (Gercekten onlem kalktiysa -ZorlaAzalt ile bilerek gecilir.)
$eskiN = 0
if(Test-Path $ciktiYol){
  try { $eskiN = @((Get-Content $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json)).Count } catch { $eskiN = 0 }
}
# Esik %10: onlemler 5 yillik surelerle DAGINIK doluyor, bir listede kayitlarin
# onda birinden fazlasinin birden dusmesi dogal degildir. Kucuk azalma (suresi
# dolan bir iki onlem) KIRMIZI'ya dusurulmez - surekli kirmizi kapi, kapi degildir.
if($eskiN -gt 0 -and -not $ZorlaAzalt -and ($eskiN - $onlemler.Count) -gt [math]::Ceiling($eskiN*0.10)){
  throw "KIRMIZI (azalma kapisi): yeni hasat $($onlemler.Count) kayit, mevcut dosyada $eskiN kayit - %10'dan fazla azalma = kayip suphesi. gtip-damping.json'a DOKUNULMADI. Gercekten toplu onlem kalktiysa: -ZorlaAzalt"
}
if($onlemler.Count -lt $eskiN){ "UYARI: kayit sayisi $eskiN -> $($onlemler.Count) (esik altinda, yazildi)." }
($onlemler | ConvertTo-Json -Depth 3 -Compress) | Out-File $ciktiYol -Encoding utf8

"BITTI. Damping onlemi: $($onlemler.Count) kayit -> veri\gtip-damping.json ($([math]::Round((Get-Item (Join-Path $veriDir 'gtip-damping.json')).Length/1KB)) KB)"
"--- kodlu ornek 4 ---"
$onlemler | Where-Object { $_.k } | Select-Object -First 4 | ForEach-Object { "  {0} | {1} | {2} | {3}" -f $_.k, $_.u, $_.m, $_.o }