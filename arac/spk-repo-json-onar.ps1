# ============================================================================
#  SPK REPO JSON ONARICI — veri/mevzuat/spk-portal-*.json'u AMBARDAN yeniden kurar
#
#  NEDEN VAR (10.09.2026, ayni gun yasandi). motor/spk-mevzuat-yut.ps1 repo
#  JSON'unu yalnizca O KOSUDA uretilen belgelerle yaziyordu. Tam yutmadan sonra
#  3 belge 500 hatasiyla dustu; eksigi tamamlamak icin betik ikinci kez kosuldu
#  ve spk-portal-mevzuat.json 3.239 parcadan 93 PARCAYA DUSTU.
#
#  BU NEDEN TEHLIKELI: motor/mevzuat-yukle.ps1 ("Mevzuat Tam Yukleme") ambari
#  veri/mevzuat/*.json'dan SIL-YAZ yapar. Repo JSON'unda olmayan her sey ucar.
#  Yani eksik JSON, bir sonraki tam yuklemede 3.146 parcayi silecekti.
#  27.08'deki "robot kiyimi"nin birebir aynisi.
#
#  Betigin kendisi artik BIRLESTIRIYOR (ezmiyor). Bu arac ise IKINCI SIGORTA:
#  repo JSON'u ne olursa olsun AMBARDAKI GERCEKLE hizalar. Dogru kaynak her
#  zaman ambardir; repo JSON onun yedegidir, tersi degil.
#
#  SINIF ESLEMESI: parca hangi dosyaya gidecek? Envanterdeki dosya adinin
#  onekinden (IlkeKarari- / Mevzuat- / Rehber-) turer. Ayni kokAd hesabi
#  spk-mevzuat-yut.ps1'deki ile BIREBIR AYNI olmali - ayrisirsa parcalar
#  yanlis dosyaya duser ve tam yukleme onlari kaybeder.
#
#  KOSMA: powershell -NoProfile -File arac/spk-repo-json-onar.ps1
#         powershell -NoProfile -File arac/spk-repo-json-onar.ps1 -Yaz
#  (varsayilan PROVA: olcer, yazmaz. -Yaz ile dosyalari gunceller.)
# ============================================================================
param([switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY = if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$H   = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

$envYol = Join-Path $kok 'veri\spk-mevzuat-envanteri.json'
if(-not (Test-Path $envYol)){ throw "envanter yok: $envYol" }
$envanter = Get-Content $envYol -Raw -Encoding UTF8 | ConvertFrom-Json

# --- kokAd hesabi: spk-mevzuat-yut.ps1 ile BIREBIR AYNI --------------------
function Temiz([string]$s){ (("$s" -replace '\s+',' ').Trim()) }
function KisaBaslik([string]$s,[int]$n=70){ $t = Temiz $s; if($t.Length -gt $n){ $t.Substring(0,$n).TrimEnd() } else { $t } }

$sinifDosya = @{ 'IlkeKarari'='spk-portal-karar'; 'Mevzuat'='spk-portal-mevzuat'; 'Rehber'='spk-portal-rehber' }
$kokSinif = @{}
foreach($d in $envanter.dosyalar){
  $sinif = ($d.dosya -split '-')[0]
  $bas2  = KisaBaslik $d.baslik 70
  $kokAd = switch($sinif){
    'IlkeKarari' { "SPK Karari - $bas2" }
    'Rehber'     { "SPK Rehber - $bas2" }
    default      { if($d.sayi){ "SPK $($d.tur) ($($d.sayi)) - $bas2" } else { "SPK $($d.tur) - $bas2" } }
  }
  $kokSinif[(Temiz $kokAd)] = $sinif
}
Write-Host ("Envanterden {0} kok ad cikarildi" -f $kokSinif.Count)

# --- ambardaki SPK satirlari (imlecli sayfalama; offset KARARSIZ) ----------
Write-Host 'Ambardan SPK satirlari cekiliyor...'
$satirlar = New-Object System.Collections.ArrayList
$sonId = ''
while($true){
  $u = "$SB/rest/v1/dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&kaynak_ad=ilike." +
       [uri]::EscapeDataString('SPK%') + "&order=id&limit=200"
  if($sonId){ $u += "&id=gt.$sonId" }
  $r = $null
  foreach($d in 1..4){
    try { $r = Invoke-WebRequest -Uri $u -Headers $H -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180; break }
    catch { if($d -eq 4){ throw }; Start-Sleep -Seconds (2*$d) }
  }
  # PS 5.1 tuzagi: Invoke-RestMethod + @() sayfa basina TEK satir dondurebiliyor.
  # Bu yuzden Invoke-WebRequest + ConvertFrom-Json + duzlestirme kullaniliyor.
  $s = @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json | ForEach-Object { $_ })
  if($s.Count -eq 0){ break }
  foreach($x in $s){ [void]$satirlar.Add($x) }
  $sonId = "$($s[$s.Count-1].id)"
  Start-Sleep -Milliseconds 200
}
Write-Host ("  {0:N0} SPK satiri" -f $satirlar.Count)

# --- her satiri sinifina ata: EN UZUN kokAd oneki kazanir ------------------
# Kisa onek yanlis dosyaya dusurur ("SPK Teblig - X" ile "SPK Teblig - X Y"
# ayni satiri tutabilir), o yuzden en uzun eslesme secilir.
$koklar = @($kokSinif.Keys | Sort-Object -Property Length -Descending)
$gruplar = @{}; $sahipsiz = New-Object System.Collections.ArrayList
foreach($x in $satirlar){
  $ad = "$($x.kaynak_ad)"
  $bulunan = $null
  foreach($k in $koklar){ if($ad.StartsWith($k, [StringComparison]::Ordinal)){ $bulunan = $k; break } }
  if(-not $bulunan){ [void]$sahipsiz.Add($ad); continue }
  $s = $kokSinif[$bulunan]
  if(-not $gruplar.ContainsKey($s)){ $gruplar[$s] = New-Object System.Collections.ArrayList }
  [void]$gruplar[$s].Add([ordered]@{
    tur          = "$($x.tur)"
    kaynak_ad    = $ad
    baslik       = "$($x.baslik)"
    metin        = "$($x.metin)"
    kaynak_url   = "$($x.kaynak_url)"
    belge_tarihi = "$($x.belge_tarihi)"
  })
}

Write-Host ''
foreach($s in $sinifDosya.Keys){
  $n = if($gruplar.ContainsKey($s)){ $gruplar[$s].Count } else { 0 }
  $yol = Join-Path $kok ('veri\mevzuat\' + $sinifDosya[$s] + '.json')
  $mevcut = 0
  if(Test-Path $yol){ try { $mevcut = @((Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler).Count } catch {} }
  Write-Host ("  {0,-22} dosyada {1,6:N0}  ->  ambarda {2,6:N0}" -f $sinifDosya[$s], $mevcut, $n)
}
if($sahipsiz.Count -gt 0){
  Write-Host ("  UYARI: {0} satir hicbir envanter kok adina oturmadi - DOSYAYA YAZILMAZ" -f $sahipsiz.Count) -ForegroundColor Yellow
  $sahipsiz | Select-Object -Unique | Select-Object -First 5 | ForEach-Object { Write-Host ("     {0}" -f $_) }
}

if(-not $Yaz){
  Write-Host ''
  Write-Host 'PROVA - dosyalara dokunulmadi. Yazmak icin: -Yaz' -ForegroundColor Yellow
  exit 0
}

foreach($s in $sinifDosya.Keys){
  if(-not $gruplar.ContainsKey($s)){ continue }
  $yol = Join-Path $kok ('veri\mevzuat\' + $sinifDosya[$s] + '.json')
  $govde = @{ belgeler = @($gruplar[$s]) }
  [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $govde -Depth 6), [Text.UTF8Encoding]::new($false))
  Write-Host ("  YAZILDI: veri/mevzuat/{0}.json ({1:N0} parca)" -f $sinifDosya[$s], $gruplar[$s].Count)
}
Write-Host '  -> bu dosyalar COMMIT EDILMELI.'
