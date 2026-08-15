# ============================================================================
#  MARKA IZLEME HASADI (15.08.2026, v2 birikimli) - Cem "1.2.3.4 kur".
#
#  KAYNAK: TMview (EUIPO/TMDN) genel API - TURKPATENT (TR) yapisal JSON, CAPTCHA'siz.
#    POST https://www.tmdn.org/tmview/api/search/results?translate=true
#  TMview 10.000 SERT TAVAN (ES max_result_window) => tek sorgu ~15 gun verir.
#
#  #1 KAPSAM: BIRIKIMLI. Mevcut ambari yukle, en yeniyi cek, no ile birlestir.
#     Ilk kosu ~15 gun; robot her gun tazeledikce pencere dolar. Retensiyon:
#     applicationDate -RetensiyonGun'den eski VE itiraz penceresi kapali kayit duser.
#  #2 BOYUT: kompakt DIZI formati [ad,no,tarih,sinifCSV,sahip,durum,st13,yayim]
#     (obje yerine) ~%40 kucuk. Istemci "kolon" sirasina gore okur.
#  #3 ITIRAZ TARIHI: "Filed"da sahip gizli. Robot bir marka icin sahip GIZLIDEN
#     GERCEK isme donunce = YAYIM ANI yakalanir, o gun 'yayim' damgasi basilir;
#     istemci yayim+2 ay itiraz son gununu hesaplar (SMK m.18).
#
#  CIKTI: veri/marka-yeni-basvurular.json {guncelleme,not,pencereGun,kolon,sayi,basvurular:[[...]]}
# ============================================================================
param([switch]$Yaz, [int]$PageSize = 100, [int]$BeklemeMs = 300, [int]$RetensiyonGun = 45, [string]$Bugun = "")
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$yol  = Join-Path $kok "veri\marka-yeni-basvurular.json"
$uc   = "https://www.tmdn.org/tmview/api/search/results?translate=true"
$h = @{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Content-Type"="application/json"; "Accept"="application/json" }
$alanlar = @("ST13","tmName","applicationNumber","applicationDate","tradeMarkStatus","niceClass","applicantName")
$gizli = "Legally Restricted"
$TAVAN = 10000
$simdi = if($Bugun){ [datetime]::ParseExact($Bugun,"dd.MM.yyyy",$null) } else { (Get-Date).Date }
$bugunStr = $simdi.ToString("dd.MM.yyyy")
function DdmmToDate($s){ try{ return [datetime]::ParseExact($s,"dd.MM.yyyy",$null) }catch{ return $null } }

# KOLON sirasi (istemci ayni sirada okur): 0 ad,1 no,2 tarih,3 sinifCSV,4 sahip,5 durum,6 st13,7 yayim
$KOLON = @("ad","no","tarih","sinif","sahip","durum","st13","yayim")

# --- mevcut ambari yukle (no -> dizi) --------------------------------------
$ambar = @{}
if(Test-Path $yol){
  try{
    $eski = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($eski.basvurular)){
      if($b -is [Array]){ $ambar["$($b[1])"] = @($b) }   # zaten kompakt
    }
  }catch{}
}
$basAmbar = $ambar.Count

# --- TMview'den en yeniyi cek ----------------------------------------------
$sayfa = 1; $ardHata = 0; $cekildi = 0; $yeniYayim = 0
while($true){
  if(($sayfa * $PageSize) -gt $TAVAN){ Write-Host ("  (TMview 10.000 tavani - sayfa {0})" -f $sayfa); break }
  $govde = @{ page="$sayfa"; pageSize="$PageSize"; criteria="C"; basicSearch=""; fOffices=@("TR"); sortColumn="applicationDate"; desc=$true; fields=$alanlar } | ConvertTo-Json -Compress
  try{
    $resp = Invoke-WebRequest -Uri $uc -Method Post -Headers $h -Body $govde -TimeoutSec 40 -UseBasicParsing
    $json = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    $r = $json | ConvertFrom-Json
    $ardHata = 0
  }
  catch{ $ardHata++; if($ardHata -ge 3){ Write-Host ("  (ardisik hata - sayfa {0})" -f $sayfa); break }; Start-Sleep -Milliseconds 800; $sayfa++; continue }
  $kayitlar = @($r.tradeMarks)
  if($kayitlar.Count -eq 0){ break }
  foreach($k in $kayitlar){
    $no = "$($k.applicationNumber)"; if(-not $no){ continue }
    $sahipHam = (@($k.applicantName) -join ", ")
    $sahip = if($sahipHam -and $sahipHam -notmatch $gizli){ $sahipHam } else { "" }
    $tarih = try{ ([datetime]$k.applicationDate).ToString("dd.MM.yyyy") }catch{ "" }
    $sinifCSV = (@($k.niceClass) -join ",")
    $durum = "$($k.tradeMarkStatus)"
    $st13 = "$($k.ST13)"
    if($ambar.ContainsKey($no)){
      $mevcut = $ambar[$no]
      # YAYIM YAKALA (#3): sahip gizliden gercege dondu ve daha once yayim damgasi yoksa
      $eskiSahip = "$($mevcut[4])"; $eskiYayim = "$($mevcut[7])"
      $yayim = $eskiYayim
      if((-not $eskiSahip) -and $sahip -and (-not $eskiYayim)){ $yayim = $bugunStr; $yeniYayim++ }
      $ambar[$no] = @($k.tmName, $no, $tarih, $sinifCSV, $sahip, $durum, $st13, $yayim)
    } else {
      $ambar[$no] = @("$($k.tmName)", $no, $tarih, $sinifCSV, $sahip, $durum, $st13, "")
    }
    $cekildi++
  }
  if(($sayfa % 10) -eq 0){ Write-Host ("  sayfa {0} - ambar {1}" -f $sayfa, $ambar.Count) }
  $sayfa++
  Start-Sleep -Milliseconds $BeklemeMs
}

# --- retensiyon: eski VE itiraz penceresi kapali kayitlari dus -------------
$kesim = $simdi.AddDays(-$RetensiyonGun)
$kalan = @{}
foreach($no in $ambar.Keys){
  $b = $ambar[$no]
  $bt = DdmmToDate "$($b[2])"
  $tazeMi = ($bt -ne $null -and $bt -ge $kesim)
  $itirazAcik = $false
  $yd = DdmmToDate "$($b[7])"
  if($yd -ne $null){ $itirazAcik = ($yd.AddMonths(2) -ge $simdi) }
  if($tazeMi -or $itirazAcik){ $kalan[$no] = $b }
}
$dusenR = $ambar.Count - $kalan.Count

# tarihe gore azalan sirala (arrays'i pipe'a sokmadan - {value,Count} tuzagi)
$pairler = foreach($no in $kalan.Keys){ $r=$kalan[$no]; $d=DdmmToDate "$($r[2])"; [pscustomobject]@{ r=$r; k=$(if($d){$d}else{[datetime]::MinValue}) } }
$sirali = @($pairler | Sort-Object -Property k -Descending)
Write-Host ("`nTMview TR birikimli - ambar {0} -> {1} (retensiyon {2}g dusen {3}) - cekilen {4} - yeni yayim {5}" -f $basAmbar, $sirali.Count, $RetensiyonGun, $dusenR, $cekildi, $yeniYayim)

if($Yaz){
  # PS 5.1 ConvertTo-Json ic dizileri {value,Count} sariyor -> basvurular'i ELLE kur.
  function JStr($s){ if($null -eq $s){ return '""' }; return (ConvertTo-Json ([string]$s) -Compress) }
  $satirlar = foreach($p in $sirali){ '['+((@($p.r) | ForEach-Object { JStr $_ }) -join ',')+']' }
  $basStr = '['+($satirlar -join ',')+']'
  $bas = [ordered]@{
    guncelleme = ("Kaynak: TMview (EUIPO/TMDN), TURKPATENT (TR). Son cekim: " + $simdi.ToString("dd.MM.yyyy") + " " + (Get-Date -Format "HH:mm") + ".")
    not = ("Son gunlerde TURKPATENT'e dusen marka basvurulari (TMview, ~gun gecikmeli). Robot her gun tazeler, pencere birikir. Yayimlanmamis kayitta sahip gizlidir; sahip gorununce yayim yakalanir ve SMK m.18 2 aylik itiraz suresi baslar.")
    pencereGun = $RetensiyonGun
    kolon = $KOLON
    sayi = $sirali.Count
  }
  $basJson = ($bas | ConvertTo-Json -Compress)
  $tam = $basJson.Substring(0,$basJson.Length-1) + ',"basvurular":' + $basStr + '}'
  $tam | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $boy = (Get-Item $yol).Length
  $moji = @($geri.basvurular | Where-Object { "$($_[0])" -match ([char]0x00C3) }).Count
  Write-Host ("-> {0}" -f $yol)
  Write-Host ("   yazildi: {0} basvuru - {1:N0} KB - geri okuma {2} - mojibake {3}" -f $geri.sayi, ($boy/1KB), @($geri.basvurular).Count, $moji)
} else { Write-Host "(olcum modu - yazmak icin -Yaz)" }
