# arac/soru-kalite-kapisi.ps1 — KAPI-AS + KAPI-EK için PowerShell köprüsü (30.09.2026, Cem "1.2.3 yap ve kural koy")
# Mantık Node'da (arac/soru-kalite-kapisi.js → aciklama-sayi-kapisi.js + eski-kural-kapisi.js); burada kopya YOK.
# SoruKaliteKapisi $nesne  → @("KAPI-AS: ...","KAPI-EK: ...")   (bulgu yoksa boş dizi)
# SoruKaliteParti $dosya   → hashtable kp → @(satırlar)           (yalnız bulgulu kp'ler)
# KÖR: node yoksa / betik düşerse $script:SORU_KALITE_KOR dolar; çağıran günlüğe "KAPI-KALITE KÖR" yazar. Kapı o durumda AÇIK kalır
# (fail-open): node eksikliği bütün üretimi düşürmesin diye — körlük sessiz değil, günlükte görünür.
$script:SORU_KALITE_KOR = $null
$script:SORU_KALITE_JS = Join-Path (Split-Path -Parent $PSCommandPath) 'soru-kalite-kapisi.js'
if (-not $PSCommandPath) { $script:SORU_KALITE_JS = Join-Path $PSScriptRoot 'soru-kalite-kapisi.js' }

function SoruKaliteKapisi($nesne) {
  $gecici = $null
  try {
    $gecici = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($gecici, (ConvertTo-Json -InputObject $nesne -Depth 14 -Compress), [Text.UTF8Encoding]::new($false))
    $cikti = @(& node $script:SORU_KALITE_JS --tek $gecici)
    if ($LASTEXITCODE -ne 0) { $script:SORU_KALITE_KOR = "node çıkış ${LASTEXITCODE}: $(@($cikti) -join ' ')"; return @() }
    return @($cikti | Where-Object { "$_" -match '^KAPI-(AS2|EK|HK|BP):' })   # NOT-AS1 / NOT-HK durdurmaz (30.09 ölçümü: AS1 alarmlarının %54–76'sı yanlış). HK 30.09 eklendi (SMMM oturumu bildirdi: tek-soru yolu süzüyordu)
  } catch {
    $script:SORU_KALITE_KOR = "çağrılamadı: $($_.Exception.Message)"
    return @()
  } finally {
    if ($gecici -and (Test-Path $gecici)) { Remove-Item $gecici -Force -ErrorAction SilentlyContinue }
  }
}

function SoruKaliteParti([string]$dosya) {
  $h = @{}
  try {
    $cikti = (& node $script:SORU_KALITE_JS --parti $dosya) -join ''
    if ($LASTEXITCODE -ne 0) { $script:SORU_KALITE_KOR = "node çıkış ${LASTEXITCODE}: $cikti"; return $h }
    $j = ConvertFrom-Json -InputObject $cikti
    foreach ($p in $j.PSObject.Properties) { $h[$p.Name] = @($p.Value) }
  } catch { $script:SORU_KALITE_KOR = "çağrılamadı: $($_.Exception.Message)" }
  return $h
}
