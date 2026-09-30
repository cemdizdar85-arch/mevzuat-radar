#requires -Version 5.1
<#
================================================================================
  YEDEKTEN GERİ YAZMA PROVASI  (30.09.2026, Cem "3 yap")

  NİYE: 30.09 yedek ölçümünde bulut yedeği indirildi + çözüldü + künyeyle ve
  canlıyla sayıca tuttu; ama yedeğin VERİTABANINA geri yazılabildiği ve bunun
  KAÇ DAKİKA sürdüğü hiç ölçülmemişti. "Yedek var" ile "geri dönebiliriz" aynı
  şey değildir.

  NE YAPAR: çözülmüş NDJSON dökümünü (soru-ambar-yedek-coz.ps1 çıktısı) canlı
  tabloya DEĞİL, önceden açılmış bir PROVA tablosuna yazar (varsayılan
  prova_geri_yukle; SQL: radar-app/sql/2026-09-30-yedek-geri-yazma-provasi.sql).
  Sonra prova tablosunun satır sayısını ve birincil anahtar kümesini dökümle
  kıyaslar. Süreyi ölçer.

  ⛔ Hedef adı 'prova_' ile başlamıyorsa DURUR - canlı tabloya yazmaz.
  ⛔ Satırlar yeniden ayrıştırılmaz: NDJSON satırı olduğu gibi gönderilir
     (ConvertFrom/To-Json tur atışı tipleri değiştirebilir - geri yazma bunu
     ölçmek için yapılıyor, bozmak için değil).
  BEDEL 0 (Supabase okuma/yazma).

  KULLANIM
    powershell -NoProfile -File motor\yedek-geri-yazma-provasi.ps1 -Dokum <..._cozuldu\soru-ambar-...-soru_havuzu.ndjson>
================================================================================
#>
param(
  [Parameter(Mandatory=$true)][string]$Dokum,
  [string]$Hedef = 'prova_geri_yukle',
  [string]$Anahtar = 'id',
  [int]$PartiMB = 4
)
$ErrorActionPreference = 'Stop'
if($Hedef -notlike 'prova_*'){ throw "Hedef '$Hedef' prova_ ile baslamiyor - canli tabloya yazilmaz." }
if(-not (Test-Path $Dokum)){ throw "dokum yok: $Dokum" }

$PROVA_ANAHTAR = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $PROVA_ANAHTAR){ $PROVA_ANAHTAR = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $PROVA_ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok.' }
$PROVA_TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
# ⚠ PS 5.1 varsayılan User-Agent "Mozilla" → sb_secret anahtar 401 "Forbidden use of secret API key in browser" (30.09 ölçüldü).
$PROVA_BASLIK = @{ apikey=$PROVA_ANAHTAR; Authorization="Bearer $PROVA_ANAHTAR"; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function ProvaSay {
  $b = $PROVA_BASLIK.Clone(); $b['Prefer'] = 'count=exact'
  $y = Invoke-WebRequest -UseBasicParsing -Uri "$PROVA_TABAN/${Hedef}?select=$Anahtar&limit=1" -Headers $b -TimeoutSec 120
  return [int](("$($y.Headers['Content-Range'])") -split '/')[-1]
}

$onceki = ProvaSay
if($onceki -ne 0){ throw "prova tablosu bos degil ($onceki satir) - once bosalt ya da yeniden ac." }

$utf8 = New-Object Text.UTF8Encoding $false
$okuyucu = New-Object IO.StreamReader($Dokum, $utf8)
$gonderilen = 0; $parti = 0; $sinir = $PartiMB * 1MB
$tampon = New-Object Text.StringBuilder
$saat = [Diagnostics.Stopwatch]::StartNew()

function PartiGonder([Text.StringBuilder]$sb, [int]$adet){
  if($adet -eq 0){ return }
  $govde = $utf8.GetBytes('[' + $sb.ToString() + ']')
  $b = $PROVA_BASLIK.Clone(); $b['Prefer'] = 'return=minimal'; $b['Content-Type'] = 'application/json'
  foreach($deneme in 1..4){
    try { Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$PROVA_TABAN/$Hedef" -Headers $b -Body $govde -TimeoutSec 300 | Out-Null; return }
    catch { if($deneme -eq 4){ throw "parti yazilamadi: $($_.Exception.Message) $($_.ErrorDetails.Message)" }; Start-Sleep -Seconds (3*$deneme) }
  }
}

try {
  $adet = 0
  while(($satir = $okuyucu.ReadLine()) -ne $null){
    if(-not $satir.Trim()){ continue }
    if($adet -gt 0 -and ($tampon.Length + $satir.Length) -gt $sinir){
      PartiGonder $tampon $adet; $gonderilen += $adet; $parti++
      if($parti % 5 -eq 0){ Write-Host ("   ... {0:N0} satir · {1:N0} sn" -f $gonderilen, $saat.Elapsed.TotalSeconds) -ForegroundColor DarkGray }
      [void]$tampon.Clear(); $adet = 0
    }
    if($adet -gt 0){ [void]$tampon.Append(',') }
    [void]$tampon.Append($satir); $adet++
  }
  PartiGonder $tampon $adet; $gonderilen += $adet; $parti++
} finally { $okuyucu.Dispose() }
$saat.Stop()
$yazmaSn = [math]::Round($saat.Elapsed.TotalSeconds)

# ⛔ YAZ → GERİ OKU → KIYASLA. Sayı + anahtar kümesi.
$sonra = ProvaSay
$dokumAnahtar = New-Object 'System.Collections.Generic.HashSet[string]'
$okuyucu = New-Object IO.StreamReader($Dokum, $utf8)
try { while(($satir = $okuyucu.ReadLine()) -ne $null){ if($satir.Trim()){ [void]$dokumAnahtar.Add("$(($satir | ConvertFrom-Json).$Anahtar)") } } } finally { $okuyucu.Dispose() }
$provaAnahtar = New-Object 'System.Collections.Generic.HashSet[string]'
$imlec = $null
while($true){
  $adres = "$PROVA_TABAN/${Hedef}?select=$Anahtar&order=$Anahtar.asc&limit=1000"
  if($imlec -ne $null){ $adres += "&$Anahtar=gt." + [uri]::EscapeDataString("$imlec") }
  $s = @(Invoke-RestMethod -Uri $adres -Headers $PROVA_BASLIK -TimeoutSec 120)
  if(-not $s.Count){ break }
  foreach($r in $s){ [void]$provaAnahtar.Add("$($r.$Anahtar)") }
  $imlec = $s[-1].$Anahtar
  if($s.Count -lt 1000){ break }
}
$eksik = @($dokumAnahtar | Where-Object { -not $provaAnahtar.Contains($_) }).Count
$fazla = @($provaAnahtar | Where-Object { -not $dokumAnahtar.Contains($_) }).Count

Write-Host ""
Write-Host ("DOKUM {0:N0} satir · GONDERILEN {1:N0} ({2} parti) · PROVA TABLOSU {3:N0}" -f $dokumAnahtar.Count, $gonderilen, $parti, $sonra)
Write-Host ("ANAHTAR: eksik {0} · fazla {1} · yazma suresi {2} sn ({3:N1} dk)" -f $eksik, $fazla, $yazmaSn, ($yazmaSn/60))
if($eksik -or $fazla -or $sonra -ne $dokumAnahtar.Count){ throw "GERI YAZMA PROVASI DUSTU: sayi/anahtar tutmuyor." }
Write-Host "✓ geri yazma TAM. Prova tablosunu SQL dosyasindaki DROP satiriyla kaldir." -ForegroundColor Green
