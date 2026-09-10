#requires -Version 5.1
<#
  TETIKTE RAG MOTORU — tek giris noktasi

  NEDEN VAR: motorun sirlari (RAG__CONNECTIONSTRING, GEMINI_API_KEY,
  ANTHROPIC_API_KEY) KULLANICI kapsamli ortam degiskenlerinde durur. Zaten acik
  olan bir kabuk onlari GORMEZ - ortam degiskenleri surec baslarken okunur.
  10.09'da bu yuzden bir kosu "ConnectionString bos" diye dustu; sir aslinda
  yerindeydi.

  Bu betik her cagrida sirlari KULLANICI kapsamindan tazeleyip motoru calistirir.
  Ayrica bu makinede 'dotnet' PATH'te olmayabiliyor; tam yol burada cozulur.

  KULLANIM (depo kokunden):
    powershell -NoProfile -File rag-motor/motor.ps1 goc sql/005_vektorsuz_arama.sql
    powershell -NoProfile -File rag-motor/motor.ps1 gomme
    powershell -NoProfile -File rag-motor/motor.ps1 aramakarne "<ders>" "konu=m.323"
    powershell -NoProfile -File rag-motor/motor.ps1 soru "<ders>" "konu1" "konu2"
    powershell -NoProfile -File rag-motor/motor.ps1 rapor sorular.txt
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Argumanlar
)

$ErrorActionPreference = 'Stop'
$motorKok = $PSScriptRoot

# --- 1) Sirlari KULLANICI kapsamindan surece tasi -------------------------
$gerekli = 'RAG__CONNECTIONSTRING', 'GEMINI_API_KEY', 'ANTHROPIC_API_KEY'
$eksik = @()
foreach ($ad in $gerekli) {
    $deger = [Environment]::GetEnvironmentVariable($ad, 'User')
    if ([string]::IsNullOrWhiteSpace($deger)) { $eksik += $ad; continue }
    Set-Item -Path "Env:$ad" -Value $deger
}
if ($eksik.Count -gt 0) {
    Write-Host "EKSIK SIR: $($eksik -join ', ')" -ForegroundColor Red
    Write-Host "Kullanici kapsamli ortam degiskeni olarak tanimlanmali." -ForegroundColor Red
    exit 2
}

# --- 2) dotnet'i bul -------------------------------------------------------
$dotnet = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
if (-not $dotnet) {
    $aday = "$env:ProgramFiles\dotnet\dotnet.exe"
    if (Test-Path $aday) { $dotnet = $aday }
}
if (-not $dotnet) {
    Write-Host "dotnet bulunamadi (PATH'te de, Program Files'ta da yok)." -ForegroundColor Red
    exit 3
}

# --- 3) Kos ----------------------------------------------------------------
Push-Location $motorKok
try {
    & $dotnet run --project 'src/Tetikte.Rag.Worker' --no-build -- @Argumanlar
    exit $LASTEXITCODE
}
finally { Pop-Location }
