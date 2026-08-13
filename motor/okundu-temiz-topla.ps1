# ============================================================================
#  OKUNDU-TEMIZ TOPLAYICI (13.08.2026) — 0 USD
#  GM okuyucu hukum dosyalarini (veri/gm-okuyucu/hukum-*.json) tarar;
#  hukum='uygun' olan id'leri veri/gm-okuyucu/okundu-temiz.json'a derler,
#  hukum='kusurlu' olanlari kusurlu-idler.json ile BIRLESTIRIR (kaybolmaz).
#  yayina-al.ps1'in VANA KURALI bu iki dosyayi okur:
#  yayin = kapi-temiz VE okundu-temiz VE kusurlu-degil.
#  Idempotent: her okuyucu partisinden sonra yeniden kosulur.
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$dizin = Join-Path $kok 'veri\gm-okuyucu'
$temizYol   = Join-Path $dizin 'okundu-temiz.json'
$kusurluYol = Join-Path $dizin 'kusurlu-idler.json'

$uygun = New-Object 'System.Collections.Generic.HashSet[string]'
$kusur = New-Object 'System.Collections.Generic.HashSet[string]'
$dosyaSay = 0; $kayitSay = 0
foreach($f in Get-ChildItem $dizin -Filter 'hukum-*.json' | Where-Object { $_.Name -notmatch 'taslak' }){
  $dosyaSay++
  $d = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($r in @($d.kayitlar)){
    $kayitSay++
    if("$($r.hukum)" -eq 'uygun'){ [void]$uygun.Add("$($r.id)") }
    elseif("$($r.hukum)" -eq 'kusurlu'){ [void]$kusur.Add("$($r.id)") }
  }
}
# onceki kusurlu listesiyle birlestir (silinmez — onarim kapatinca elle cikarilir)
if(Test-Path $kusurluYol){
  foreach($k in @((Get-Content $kusurluYol -Raw -Encoding UTF8 | ConvertFrom-Json).idler)){ [void]$kusur.Add("$k") }
}
# guvenlik: ayni id hem uygun hem kusurlu ise KUSURLU kazanir
foreach($k in $kusur){ [void]$uygun.Remove($k) }

$bugun = (Get-Date).ToString('dd.MM.yyyy HH:mm')
$tj = [ordered]@{ tarih=$bugun; kaynak='GM okuyucu hukumleri (GM-OKUYUCU-SARTNAME.md)'; hukum_dosyasi=$dosyaSay; okunan_kayit=$kayitSay
  not='yayina-al.ps1 VANA KURALI: yalniz bu listedeki id yayina girebilir (kapi-temiz kesisimiyle). Ayni id kusurluysa kusurlu kazanir.'
  idler=@($uygun) }
[IO.File]::WriteAllText($temizYol, (ConvertTo-Json $tj -Depth 4), (New-Object Text.UTF8Encoding($false)))
$kj = [ordered]@{ tarih=$bugun; kaynak='GM okuyucu hukumleri (birlesik)'; not='yayina-al surecinde DISLANIR; onarim kapaninca id elle cikarilir.'; idler=@($kusur) }
[IO.File]::WriteAllText($kusurluYol, (ConvertTo-Json $kj -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("OKUNDU-TEMIZ: {0} uygun id ({1} dosya, {2} kayit) -> {3}" -f $uygun.Count, $dosyaSay, $kayitSay, $temizYol)
Write-Host ("KUSURLU (birlesik): {0} id -> {1}" -f $kusur.Count, $kusurluYol)
