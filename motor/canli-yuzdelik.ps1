# ============================================================================
#  CANLI DENEME YUZDELIK ROBOTU — 07.08.2026
#  Oturum kapandiktan sonra kosar: canli_sonuc'tan skorlari ceker,
#  katilim >= 50 ise YUZDELIK esik tablosu, altindaysa SEVIYE raporu uretir
#  (RAKAM DISIPLINI - 06.08 karari: az katilimda yuzdelik ACIKLANMAZ,
#  yaniltici olur; ortalama/medyan verilir). Cikti: veri/canli/sonuc-<kod>.json
#  + commit. Istemci kendi skorunu bu tabloya oturtur.
#  KULLANIM: .\motor\canli-yuzdelik.ps1 -oturum SGS-2308
# ============================================================================
param([Parameter(Mandatory=$true)][string]$oturum)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
Set-Location -LiteralPath $kok
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/canli_sonuc'
$H = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

$skorlar = New-Object System.Collections.Generic.List[int]
$bas=0
while($true){
  $r = @(Invoke-RestMethod -Uri "$U`?select=dogru&oturum=eq.$oturum&order=olusturma&limit=1000&offset=$bas" -Headers $H -TimeoutSec 120 -UserAgent 'mevzuat-radar-robot/1.0' | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $skorlar.Add([int]$x.dogru) } }
  if($r.Count -lt 1000){ break }
  $bas += 1000
}
$n = $skorlar.Count
Write-Host ("katilim: {0}" -f $n)
if($n -eq 0){ Write-Host 'sonuc yok - dosya uretilmedi'; exit 0 }
$sirali = @($skorlar | Sort-Object)
$ort = [math]::Round(($skorlar | Measure-Object -Average).Average, 1)
$med = $sirali[[int][math]::Floor(($n-1)/2)]

if($n -ge 50){
  # yuzdelik esikleri: "X dogru ve ustu -> katilimcilarin %Y'sinin onunde"
  $esikler = @()
  $maxD = ($sirali | Select-Object -Last 1)
  for($d=0; $d -le $maxD; $d++){
    $altinda = @($sirali | Where-Object { $_ -lt $d }).Count
    $esikler += [pscustomobject]@{ dogru=$d; yuzde=[math]::Round(100.0*$altinda/$n) }
  }
  $cikti = [ordered]@{ oturum=$oturum; tur='yuzdelik'; katilim=$n; ortalama=$ort; medyan=$med; esikler=$esikler; uretim=(Get-Date -Format 'dd.MM.yyyy HH:mm') }
} else {
  $cikti = [ordered]@{ oturum=$oturum; tur='seviye'; katilim=$n; ortalama=$ort; medyan=$med
    not_='Katılım yüzdelik açıklamak için henüz düşük; seviye raporu sunuldu (rakam disiplini: yanıltıcı yüzdelik yayınlamayız).'
    uretim=(Get-Date -Format 'dd.MM.yyyy HH:mm') }
}
$yol = Join-Path $kok "veri\canli\sonuc-$oturum.json"
[IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $cikti -Depth 4), (New-Object Text.UTF8Encoding($false)))
git add "veri/canli/sonuc-$oturum.json"
git commit -m "Canli deneme sonucu yayinda: $oturum (katilim $n)" | Out-Null
git pull --rebase origin main 2>$null | Out-Null
git push origin HEAD:main 2>$null | Out-Null
Write-Host ("SONUC YAYINDA: sonuc-$oturum.json (tur: {0})" -f $cikti.tur)
