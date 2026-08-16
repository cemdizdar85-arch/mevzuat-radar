# ============================================================================
#  YAYINDAN CEKME (31.07 Cem: "cekebilirsin - yayina ~15 gun sonra girecegiz,
#  hazirlik asamasindayiz; korkmadan en dogrusunu yap").
#  Hakem yargisi destek != 'evet' olan (hayir/yetersiz/kismen) YAYINDAKI
#  sorulari yayin=false yapar -> GM/hakem dongusune doner. PATCH kullanilir
#  (27.07 dersi: kismi-kolon upsert NOT NULL duvarina carpar). 100'luk
#  partilerle id=in.(...) — URL siniri asilmaz. Rapor: veri/yayindan-cekme-
#  raporu.json (kor kalma). ENV: SUPABASE_SERVICE_KEY.
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

$hh = Get-Content 'veri/hakem-hasadi.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$yarg = @{}
foreach($p in $hh.yargilar.PSObject.Properties){ $yarg[$p.Name] = $p.Value }

# yayindaki id'leri cek, destek != evet olanlari isaretle
$cekilecek = New-Object System.Collections.Generic.List[string]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.true&limit=1000&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $liste = @($ham | ConvertFrom-Json)
  if($liste.Count -eq 0){ break }
  foreach($s in $liste){
    $j = $yarg["$($s.id)"]
    if($j -and "$($j.destek)" -ne 'evet'){ $cekilecek.Add("$($s.id)") }
  }
  if($liste.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host "Cekilecek (yayinda + hakem destek!=evet): $($cekilecek.Count)"

$cekilen = 0; $hata = 0
for($i = 0; $i -lt $cekilecek.Count; $i += 100){
  $parti = $cekilecek[$i..([math]::Min($i+99, $cekilecek.Count-1))]
  $inListe = ($parti -join ',')
  try {
    Invoke-RestMethod -Method Patch -Uri "${U}?id=in.($inListe)" `
      -Headers ($SB + @{ Prefer = "return=minimal" }) -ContentType "application/json" `
      -Body '{"yayin":false}' -TimeoutSec 120 | Out-Null
    $cekilen += $parti.Count
    Write-Host ("parti {0}: {1} cekildi (toplam {2})" -f ([int]($i/100)+1), $parti.Count, $cekilen)
  } catch {
    $hata += $parti.Count
    Write-Host "PARTI HATASI: $($_.Exception.Message)"
    if($_.ErrorDetails -and $_.ErrorDetails.Message){ Write-Host "  sunucu: $($_.ErrorDetails.Message)" }
  }
}

# dogrulama sayimi
$wd = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.true&limit=1" -Headers ($SB + @{ Prefer = "count=exact" }) -UseBasicParsing -Method Head -TimeoutSec 60
$kalan = ($wd.Headers['Content-Range'] -split '/')[-1]

$rapor = [ordered]@{
  tarih = (Get-Date).ToUniversalTime().AddHours(3).ToString("dd.MM.yyyy HH:mm")
  gerekce = "Cem 31.07: hakem destek!=evet yayindakiler cekildi (hazirlik donemi, acilis ~14 Agustos)"
  cekilecek = $cekilecek.Count
  cekilen = $cekilen
  hata = $hata
  yayinda_kalan = "$kalan"
}
$rapor | ConvertTo-Json | Set-Content 'veri/yayindan-cekme-raporu.json' -Encoding UTF8
Write-Host "TAMAM: $cekilen cekildi, $hata hata, yayinda kalan: $kalan"
if($hata -gt 0){ exit 1 }
