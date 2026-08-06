# ============================================================================
#  ORNEKLEM KARANTINACISI — 06.08.2026 (Cem onayi #17)
#
#  Uc orneklem denetiminde (SGS 198 / SMMM 200 / KGK 150 kart) yakalanan
#  kusurlu kartlar yayindan cekilir: isaretli cevabi hesapla uyusmayan,
#  ic celiskili, THP kod/ad celiskili ve tablo-soru rakam uyusmazi kartlar.
#
#  ICERIK SIZINTISI YOK: veri/orneklem-karantina-0608.json yalniz SHA256
#  imza tasir (soru metninin bosluk-normalize halinden). Bu robot kasadaki
#  sorulari ayni yontemle imzalayip eslestirir, eslesenlere yayin=false +
#  yayin_notu yazar. KARANTINA ASLA SILINMEZ: soru kasada durur, hakem
#  yeniden yargisindan gecince yayin=true yapilir.
#
#  Varsayilan OLCUM (kac eslesme var yazar); -yaz ile gercekten ceker.
#  Kor kalma kurali: sonuc her kosuda veri/orneklem-karantina-sonuc.json'a.
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$sonucYol = Join-Path $kok 'veri/orneklem-karantina-sonuc.json'

function SonucYaz($n){
  [IO.File]::WriteAllText($sonucYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false)))
}
trap {
  SonucYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY }
if($KEY -like 'eyJ*'){ $H.Authorization = "Bearer $KEY" }

# --- hedef imzalar
$liste = (Get-Content (Join-Path $kok 'veri/orneklem-karantina-0608.json') -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar
Write-Host ("Hedef: {0} imza" -f @($liste).Count)

function Norm([string]$t){ return ("$t" -replace '\s+',' ').Trim() }
$sha=[Security.Cryptography.SHA256]::Create()
function Imza([string]$t){ return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))) -replace '-','').ToLowerInvariant() }

# --- kasa taramasi: sinav bazli, sayfali (yalniz id+soru+yayin)
$hedefSinavlar = @($liste | ForEach-Object { $_.sinav } | Select-Object -Unique)
$eslesme = New-Object System.Collections.Generic.List[object]
$imzaHarita = @{}
foreach($k in $liste){ $imzaHarita[$k.sinav + '|' + $k.imza] = $k }
foreach($sinav in $hedefSinavlar){
  $bas = 0
  while($true){
    $r = @(Invoke-RestMethod -Uri "$U`?select=id,soru,yayin,yayin_notu&sinav=eq.$sinav&order=id&limit=1000&offset=$bas" -Headers $H -TimeoutSec 180)
    if($r.Count -eq 0){ break }
    foreach($s in $r){
      if($null -eq $s){ continue }
      $k = $imzaHarita[$sinav + '|' + (Imza (Norm "$($s.soru)"))]
      if($k){ $eslesme.Add([pscustomobject]@{ id=$s.id; sinav=$sinav; kart=$k.kart; sebep=$k.sebep; yayindi=[bool]$s.yayin }) }
    }
    if($r.Count -lt 1000){ break }
    $bas += 1000
  }
}
Write-Host ("Eslesen: {0}/{1}" -f $eslesme.Count, @($liste).Count)
$bulunamayan = @($liste | Where-Object { $k=$_; -not ($eslesme | Where-Object { $_.sinav -eq $k.sinav -and $_.kart -eq $k.kart }) })

$cekilen = 0; $hataLi = @()
if($yaz){
  $HW = $H + @{ Prefer='return=minimal'; 'Content-Type'='application/json' }
  foreach($e in $eslesme){
    $not = ('orneklem denetimi 06.08.2026: ' + $e.sebep + ' (kart #' + $e.kart + ') - hakem yeniden yargisi bekliyor')
    $gov = ConvertTo-Json -InputObject @{ yayin=$false; yayin_notu=$not } -Compress
    try {
      Invoke-RestMethod -Method Patch -Uri ("$U`?id=eq." + $e.id) -Headers $HW -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -TimeoutSec 60 | Out-Null
      $cekilen++
    } catch { $hataLi += "$($e.sinav)#$($e.kart): $($_.Exception.Message)" }
  }
  # geri okuyup dogrula
  $dogrulanan = 0
  foreach($e in $eslesme){
    $g = @(Invoke-RestMethod -Uri ("$U`?select=yayin&id=eq." + $e.id) -Headers $H -TimeoutSec 60)
    if($g.Count -and (-not [bool]$g[0].yayin)){ $dogrulanan++ }
  }
  Write-Host ("Cekilen: {0}, geri-okumayla dogrulanan: {1}" -f $cekilen, $dogrulanan)
} else {
  Write-Host 'OLCUM modu - yazilmadi. Gercek cekim icin -yaz.'
}

SonucYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){'YAZILDI'}else{'OLCUM'})
  hedef=@($liste).Count; eslesen=$eslesme.Count; cekilen=$cekilen
  dogrulanan=$(if($yaz){$dogrulanan}else{$null})
  bulunamayan=@($bulunamayan | ForEach-Object { $_.sinav + ' #' + $_.kart })
  hatalar=$hataLi
})
Write-Host 'Bitti.'
