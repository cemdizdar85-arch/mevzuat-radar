# ============================================================================
#  TEK SEFERLIK OLCUM (31.07): kasadaki yayindaki sorularin SINAV dagilimi.
#  Cem: "SGS ile Yeterlilik ayni gorunuyor" - hipotez: cok soruda sinav BOS,
#  sinavUyar bos-sinavi iki sinava da sayiyor. Tahmin degil olcum.
#  Cikti yalniz SAYI (soru metni yok). ENV: SUPABASE_SERVICE_KEY.
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$BASLIK = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)"; Prefer = "count=exact" }

$dagilim = @{}
$dersDagilim = @{}
$b0 = 0
while($true){
  $BASLIK2 = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
  # pwsh7 tuzagi 1: "$U?..." icindeki ? degisken adina yapisir - ${U} sart.
  # tuzak 2: .NET, PostgREST'in "0-999" Range basligini reddediyor - limit/offset kullan.
  $w = Invoke-WebRequest -Uri "${U}?select=sinav,ders&yayin=eq.true&limit=1000&offset=$b0" -Headers $BASLIK2 -UseBasicParsing -TimeoutSec 120
  # kasa-sayim deseni: govdeyi ham byte'tan UTF-8 olarak coz (mojibake yasagi)
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $liste = @($ham | ConvertFrom-Json)   # assign-then-wrap: @(IRM) tuzagi degil
  if($liste.Count -eq 0){ break }
  foreach($s in $liste){
    $k = if([string]::IsNullOrWhiteSpace($s.sinav)){ "(BOS)" } else { "$($s.sinav)" }
    if(-not $dagilim.ContainsKey($k)){ $dagilim[$k] = 0 }
    $dagilim[$k]++
    $dk = "$k | $($s.ders)"
    if(-not $dersDagilim.ContainsKey($dk)){ $dersDagilim[$dk] = 0 }
    $dersDagilim[$dk]++
  }
  if($liste.Count -lt 1000){ break }
  $b0 += 1000
}

# ---- YAYIN-DURUM ENVANTERI (31.07 Cem: 'okunmayi bekleyen soru yok deme') ----
$yd = @{}
$b2 = 0
$kolon = "yayin,durum"
$dene = $null
try { $dene = Invoke-WebRequest -Uri "${U}?select=$kolon&limit=1" -Headers @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" } -UseBasicParsing -TimeoutSec 60 } catch { $kolon = "yayin" }
while($true){
  # DIKKAT: sayac $b2 ile ayni ada dusen $B2 YASAK (PS harf ayirmaz - $h/$H dersi)
  $BSLK2 = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
  $w2 = Invoke-WebRequest -Uri "${U}?select=$kolon&limit=1000&offset=$b2" -Headers $BSLK2 -UseBasicParsing -TimeoutSec 120
  $h2 = if($w2.RawContentStream){ [Text.Encoding]::UTF8.GetString($w2.RawContentStream.ToArray()) } else { $w2.Content }
  $l2 = @($h2 | ConvertFrom-Json)
  if($l2.Count -eq 0){ break }
  foreach($s in $l2){
    $y = if($s.yayin -eq $true){"YAYINDA"}else{"BEKLIYOR(yayin=false)"}
    $d = if($s.PSObject.Properties['durum'] -and $s.durum){ "$($s.durum)" } else { "-" }
    $k2 = "$y | $d"
    if(-not $yd.ContainsKey($k2)){ $yd[$k2]=0 }
    $yd[$k2]++
  }
  if($l2.Count -lt 1000){ break }
  $b2 += 1000
}
# ---- HAKEM KESISIMI (31.07 Cem: 'bekleyenlerin hakem yargisina bakalim') ----
$hh = $null
try { $hh = Get-Content 'veri/hakem-hasadi.json' -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}   # CI cwd = repo koku
if($hh -and $hh.yargilar){
  $yarg = @{}
  foreach($p in $hh.yargilar.PSObject.Properties){ $yarg[$p.Name] = $p.Value }
  $kes = @{}
  $b3 = 0
  while($true){
    $BSLK3 = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
    $w3 = Invoke-WebRequest -Uri "${U}?select=id,yayin&limit=1000&offset=$b3&order=id" -Headers $BSLK3 -UseBasicParsing -TimeoutSec 120
    $h3 = if($w3.RawContentStream){ [Text.Encoding]::UTF8.GetString($w3.RawContentStream.ToArray()) } else { $w3.Content }
    $l3 = @($h3 | ConvertFrom-Json)
    if($l3.Count -eq 0){ break }
    foreach($s in $l3){
      $grp = if($s.yayin -eq $true){"YAYINDA"}else{"BEKLIYOR"}
      $j = $yarg["$($s.id)"]
      $kat = if($j){
        $c = if($j.celiski -eq $true){" +celiski"}else{""}
        "$grp | yargili destek=$($j.destek)$c"
      } else { "$grp | YARGISIZ (hakem gormemis)" }
      if(-not $kes.ContainsKey($kat)){ $kes[$kat]=0 }
      $kes[$kat]++
    }
    if($l3.Count -lt 1000){ break }
    $b3 += 1000
  }
  "===== HAKEM KESISIMI (yayin durumu x hakem yargisi) ====="
  $kes.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0,-52} {1,6}" -f $_.Key, $_.Value }
  ""
}
"===== YAYIN-DURUM ENVANTERI (kasadaki TUM sorular) ====="
$yd.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "{0,-40} {1,6}" -f $_.Key, $_.Value }
""
"===== SINAV DAGILIMI (yayindaki sorular) ====="
$dagilim.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "{0,-12} {1,6}" -f $_.Key, $_.Value }
""
"===== SINAV+DERS DAGILIMI ====="
$dersDagilim.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0,-45} {1,6}" -f $_.Key, $_.Value }
