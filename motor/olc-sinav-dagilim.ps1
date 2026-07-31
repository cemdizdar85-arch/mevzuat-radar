# ============================================================================
#  TEK SEFERLIK OLCUM (31.07): kasadaki yayindaki sorularin SINAV dagilimi.
#  Cem: "SGS ile Yeterlilik ayni gorunuyor" - hipotez: cok soruda sinav BOS,
#  sinavUyar bos-sinavi iki sinava da sayiyor. Tahmin degil olcum.
#  Cikti yalniz SAYI (soru metni yok). ENV: SUPABASE_SERVICE_KEY.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$BASLIK = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)"; Prefer = "count=exact" }

$dagilim = @{}
$dersDagilim = @{}
$b0 = 0
while($true){
  $BASLIK2 = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)"; Range = "$b0-$($b0+999)" }
  $w = Invoke-WebRequest -Uri "$U?select=sinav,ders&yayin=eq.true" -Headers $BASLIK2 -UseBasicParsing -TimeoutSec 120
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

"===== SINAV DAGILIMI (yayindaki sorular) ====="
$dagilim.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "{0,-12} {1,6}" -f $_.Key, $_.Value }
""
"===== SINAV+DERS DAGILIMI ====="
$dersDagilim.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0,-45} {1,6}" -f $_.Key, $_.Value }
