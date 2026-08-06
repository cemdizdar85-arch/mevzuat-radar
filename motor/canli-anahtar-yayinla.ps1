# ============================================================================
#  CANLI DENEME ANAHTAR YAYINCISI — 07.08.2026
#  Oturum saatinde kosar (elle ya da zamanlanmis gorev): repo DISINDA duran
#  anahtari IKI kanaldan yayinlar:
#   1) Supabase public 'canli' kovasi  -> ANLIK (Pages gecikmesi yok)
#   2) veri/canli/anahtar-<oturum>.json + git push -> yedek kanal (CDN)
#  Istemci once kovayi yoklar, olmazsa repodan alir.
#  Ornek zamanlanmis gorev (Cem'e sorulmadan kurulmaz; elle de basilabilir):
#    .\motor\canli-anahtar-yayinla.ps1 -oturum SGS-2308
# ============================================================================
param([Parameter(Mandatory=$true)][string]$oturum)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
Set-Location -LiteralPath $kok
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$keyYol = Join-Path (Split-Path -Parent $kok) "canli-anahtarlar\$oturum.key"
if(-not (Test-Path $keyYol)){ throw "anahtar dosyasi yok: $keyYol (once canli-paketle kos)" }
$anahtar = (Get-Content $keyYol -Raw).Trim()
$govde = ConvertTo-Json -Compress -InputObject ([ordered]@{ oturum=$oturum; anahtar=$anahtar; yayin=(Get-Date -Format 'dd.MM.yyyy HH:mm:ss') })

# 1) Supabase public kova (anlik kanal)
$STOR='https://bjrleanjpyujtajmazxn.supabase.co/storage/v1'
$SB=@{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
try {
  try { Invoke-RestMethod -Uri "$STOR/bucket/canli" -Headers $SB -TimeoutSec 30 | Out-Null }
  catch {
    $kg = ConvertTo-Json -Compress -InputObject @{ id='canli'; name='canli'; public=$true }
    Invoke-RestMethod -Uri "$STOR/bucket" -Method Post -Headers ($SB+@{'Content-Type'='application/json'}) -Body ([Text.Encoding]::UTF8.GetBytes($kg)) -TimeoutSec 30 | Out-Null
  }
  Invoke-RestMethod -Uri "$STOR/object/canli/anahtar-$oturum.json" -Method Post -Headers ($SB+@{'Content-Type'='application/json';'x-upsert'='true'}) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 30 | Out-Null
  Write-Host 'kova kanali: YAYINDA (anlik)'
} catch { Write-Host ("kova kanali HATA: " + $_.Exception.Message) }

# 2) repo kanali (yedek)
[IO.File]::WriteAllText((Join-Path $kok "veri\canli\anahtar-$oturum.json"), $govde, (New-Object Text.UTF8Encoding($false)))
git add "veri/canli/anahtar-$oturum.json"
git commit -m "CANLI DENEME anahtari yayinda: $oturum" | Out-Null
git pull --rebase origin main 2>$null | Out-Null
git push origin HEAD:main 2>$null | Out-Null
Write-Host 'repo kanali: push edildi (Pages 1-2 dk icinde)'
Write-Host ("ANAHTAR YAYINDA: $oturum")
