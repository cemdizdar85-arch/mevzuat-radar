# ============================================================================
#  NABIZ NOBETCISI — "guncellenmeyen veri" sigortasi (Cem 23.07).
#  Her kritik robotun SON BASARILI kosusunun yasini olcer; esigi asan robot =
#  sessizce olmus robot = bayatlamaya baslayan veri. KIRMIZI + mail.
#  Neden dosya yasi degil kosu yasi: veri degismeyince dosya da degismez
#  (sakin RG gunu gibi) — yanlis alarm olur. Robot CALISIYORSA veri gozetimde.
#  ENV: GH_TOKEN (Actions'in kendi GITHUB_TOKEN'i yeter), RESEND_KEY/FROM.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$REPO = "cemdizdar85-arch/mevzuat-radar"
$H = @{ "User-Agent"="tetikte-nabiz" }
if($env:GH_TOKEN){ $H["Authorization"] = "Bearer $($env:GH_TOKEN)" }

# izlenen robotlar: ad -> son basarili kosu en fazla kac SAAT eski olabilir
$izlenen = [ordered]@{
  "Gece Ajani"           = 30
  "Soru Fabrikasi"       = 12    # gunde 5 vardiya; en uzun dogal bosluk gece ~10 saat
  "Sinav Analizi"        = 30
  "Günlük Kanun Aynası"  = 30
  "Hap Kartlar"          = 30
  "Link Nobetcisi"       = 30
  "Smoke Nobetcisi"      = 30
  "Takvim Nobetcisi"     = 30
}

$kirmizi = New-Object System.Collections.Generic.List[string]
$simdi = (Get-Date).ToUniversalTime()
foreach($ad in $izlenen.Keys){
  $esik = $izlenen[$ad]
  try {
    $u = "https://api.github.com/repos/$REPO/actions/runs?status=success&per_page=40"
    $r = Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 60
    $son = $r.workflow_runs | Where-Object { $_.name -eq $ad } | Select-Object -First 1
    if(-not $son){ $kirmizi.Add("$ad -> HIC basarili kosu bulunamadi (son 40 icinde)"); continue }
    $yas = ($simdi - ([datetime]$son.created_at).ToUniversalTime()).TotalHours
    if($yas -gt $esik){
      $kirmizi.Add(("{0} -> son basarili kosu {1:N1} saat once (esik {2}s)" -f $ad, $yas, $esik))
    } else {
      Write-Host ("ok: {0} ({1:N1}s once)" -f $ad, $yas)
    }
  } catch { $kirmizi.Add("$ad -> API hatasi: $($_.Exception.Message)") }
  Start-Sleep -Milliseconds 300
}

if($kirmizi.Count -eq 0){ Write-Host "NABIZ TEMIZ: tum robotlar vardiyasinda."; exit 0 }
Write-Host "NABIZ KIRMIZI:"; $kirmizi | ForEach-Object { Write-Host "  $_" }
if($env:RESEND_KEY){
  $sat = ($kirmizi | ForEach-Object { "<li>$_</li>" }) -join ""
  $html = "<h3>Nabiz Nobetcisi ALARM</h3><p>Su robotlar vardiyasini kacirdi — veri bayatlamaya baslamis olabilir:</p><ul>$sat</ul><p>Actions sekmesinden son kosularin loguna bak. Tetikte</p>"
  $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE NABIZ ALARM: $($kirmizi.Count) robot vardiyayi kacirdi"; html=$html } | ConvertTo-Json -Depth 3
  try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null } catch { Write-Host "mail hatasi: $_" }
}
exit 1
