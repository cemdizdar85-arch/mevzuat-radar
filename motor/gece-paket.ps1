# ============================================================================
#  GECE PAKET ACILISI (31.07 Cem: "bu gece 00'dan sonra API acilacak,
#  planlarin icine alalim; Yeterlilik VE Staja Giris planlandigi kadar").
#  Gorevi: 1 Agustos emirlerini (uretim #16 SGS, #19 SMMM, #17 hap;
#  profesor #18 karantina) ACMAK, push'lamak (push, soru-uret-v2 ve
#  profesor-v2'yi paths tetigiyle ateisler) ve hap hattini dispatch etmek.
#  IDEMPOTENT: emir zaten acik/uygulanmissa dokunmaz; hatlarin kendi emir
#  kapilari ikinci kosuda "acik emir yok - 0 USD" der. 02:05 yedek cronu
#  ilk kosu API-kapali dusmusse hatlari YENIDEN tetikler (para kapisi yine
#  emirde). ENV: GH_TOKEN (actions:write).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$REPO = "cemdizdar85-arch/mevzuat-radar"
$BASLIK = @{ "User-Agent"="tetikte-gece-paket"; "Accept"="application/vnd.github+json" }
if($env:GH_TOKEN){ $BASLIK["Authorization"] = "Bearer $($env:GH_TOKEN)" }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function Ac([string]$yol, [int[]]$nolar){
  $tam = Join-Path $kok $yol
  $j = Get-Content $tam -Raw -Encoding UTF8 | ConvertFrom-Json
  $degisti = $false
  $acikBekleyen = $false
  foreach($e in $j.emirler){
    if($nolar -notcontains [int]$e.no){ continue }
    if(-not [string]::IsNullOrWhiteSpace("$($e.uygulandi)")){ continue }
    if($e.onay -eq $true){ $acikBekleyen = $true; continue }
    $e.onay = $true
    $e | Add-Member -NotePropertyName onay_acan -NotePropertyValue ("gece-paket robotu " + (Get-Date).ToUniversalTime().ToString("dd.MM.yyyy HH:mm") + " UTC — Cem gece plani onayi 31.07") -Force
    $degisti = $true; $acikBekleyen = $true
    Write-Host "ACILDI: $yol emir #$($e.no) ($($e.emir))"
  }
  if($degisti){ $j | ConvertTo-Json -Depth 6 | Set-Content $tam -Encoding UTF8 }
  return @($degisti, $acikBekleyen)
}

$u = Ac 'veri/uretim-emir.json'  @(16,17,19,20)
$p = Ac 'veri/profesor-emir.json' @(18)
$degisti      = $u[0] -or $p[0]
$uretimAcik   = $u[1]
$profesorAcik = $p[1]

if($degisti){
  git config user.name  "mevzuat-radar-bot"
  git config user.email "bot@users.noreply.github.com"
  git add veri/uretim-emir.json
  git add veri/profesor-emir.json
  git commit -m "GECE PAKETI: 1 Agustos emirleri acildi (Cem onayi 31.07) [veri-operasyonu]"
  git pull --rebase; if($LASTEXITCODE -ne 0){ git rebase --abort 2>$null }
  $n=0; while($true){ git push; if($LASTEXITCODE -eq 0){ break }; $n++; if($n -ge 4){ Write-Host "PUSH BASARISIZ"; exit 1 }; Start-Sleep 5; git pull --rebase }
  Write-Host "Push tamam - soru-uret-v2 ve profesor-v2 paths tetigiyle atesle(n)di."
} else {
  Write-Host "Emirlerde degisiklik yok."
}

function Tetikle([string]$dosya){
  foreach($st in @("queued","in_progress")){
    try { $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/actions/workflows/$dosya/runs?status=$st&per_page=1" -Headers $BASLIK -TimeoutSec 60
          if(@($r.workflow_runs).Count -gt 0){ Write-Host "$dosya zaten kosuyor/kuyrukta - tetiklenmedi."; return } } catch {}
  }
  try { Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$REPO/actions/workflows/$dosya/dispatches" -Headers $BASLIK -Body '{"ref":"main"}' -ContentType "application/json" -TimeoutSec 60 | Out-Null
        Write-Host "TETIKLENDI: $dosya" } catch { Write-Host "DISPATCH HATA ($dosya): $($_.Exception.Message)" }
}

# 02:05 yedegi icin: acik-uygulanmamis emri olan hatlar (push olmasa da) tetiklenir.
if($uretimAcik){ Tetikle "soru-uret-v2.yml"; Tetikle "hap-zengin.yml" }
if($profesorAcik){ Tetikle "profesor-v2.yml" }
if(-not ($uretimAcik -or $profesorAcik)){ Write-Host "GECE PAKETI TAMAM: acik/bekleyen emir kalmadi - 0 is." }
