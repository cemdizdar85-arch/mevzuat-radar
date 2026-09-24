#requires -Version 5.1
# ============================================================================
#  KAYDIR-ÇÖZ EKSİK ALAN TAMAMLAMA — parti kaydına GM yazımı alan yaması   24.09.2026 · bedel 0
#  Cem "1.2.3" (KAPI-KC'nin 2. maddesi): KAPI-KC'nin düşürdüğü bitirme sorularının eksik Kaydır-Çöz alanları
#  (teşhis, şık açıklaması, dayanak, sade şık notu) parti kaydında tamamlanır; kasa yayını sonra yeniden koşar.
#
#  YAMA DOSYASI depoya GİRMEZ (soru içeriği taşır — depo public). Biçim:
#    { "<etiket>/<kp>": { "alanlar": { "teshis": {...}, "aciklama": {...}, "dayanak": "...", "sade.siklar.C": "..." },
#                         "anahtar_duzelt": { "aciklama": { "<bozuk anahtar>": "<doğru anahtar>" } } } }
#    Noktalı ad iç içe alanı yazar (sade.siklar.C); noktasız ad alanın tamamını değiştirir.
#
#  KURALLAR (mekanik):
#   · soru / şıklar / doğru cevap DEĞİŞEMEZ: yama öncesi ve sonrası SmmmParmakIzi aynı değilse o parti YAZILMAZ.
#   · Yamalı soru KAPI-KC'den (SmmmKcEksik) 0 eksikle geçmiyorsa o parti YAZILMAZ.
#   · Bulutta koşan partiye yazılmaz (arac/bulut-kosan-etiketler.ps1 -Kati).
#   · Satır yedeği yazımdan önce: C:\TETIKTE-YEDEK\kc-tamamla\ ; yazımdan sonra ambardan geri okunur.
#   · Ekrana yalnız kimlik + sayı basılır, içerik basılmaz.
#  GÖRMEZ: yazılan metnin DOĞRULUĞUNU (bunu yazan GM, ambardaki madde metniyle karşılaştırarak yazar).
#
#  Kullanım: powershell -NoProfile -File arac/kc-alan-tamamla.ps1 -Yama <yol.json> [-Yaz]   (-Yaz yoksa kuru koşu)
# ============================================================================
param([Parameter(Mandatory = $true)][string]$Yama, [switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'smmm-yayin-sarti.ps1')
$servisAnahtari = "$env:SUPABASE_SERVICE_KEY"; if (-not $servisAnahtari) { $servisAnahtari = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
$servisAnahtari = $servisAnahtari.Trim(); if (-not $servisAnahtari) { throw 'SUPABASE_SERVICE_KEY yok' }
$tabloUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$istekBaslik = @{ apikey = $servisAnahtari; Authorization = "Bearer $servisAnahtari"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$yedekDizin = 'C:\TETIKTE-YEDEK\kc-tamamla'

function PartiGetir([string]$etiket) {
  $cevap = Invoke-WebRequest -UseBasicParsing -Uri ("$tabloUcu" + '?select=etiket,icerik&etiket=eq.' + [uri]::EscapeDataString($etiket)) -Headers $istekBaslik -TimeoutSec 120
  $satirlar = @(([Text.Encoding]::UTF8.GetString($cevap.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
  if ($satirlar.Count -ne 1) { throw "parti bulunamadı ya da tekil değil: $etiket ($($satirlar.Count))" }
  $icerik = $satirlar[0].icerik; if ($icerik -is [string]) { $icerik = ConvertFrom-Json -InputObject $icerik }
  return $icerik
}
function AlanYaz($nesne, [string]$yol, $deger) {
  $parcalar = $yol -split '\.'; $hedef = $nesne
  for ($i = 0; $i -lt $parcalar.Count - 1; $i++) {
    $ad = $parcalar[$i]
    if (-not $hedef.PSObject.Properties[$ad] -or $null -eq $hedef.$ad) { $hedef | Add-Member -NotePropertyName $ad -NotePropertyValue ([pscustomobject]@{}) -Force }
    $hedef = $hedef.$ad
  }
  $hedef | Add-Member -NotePropertyName $parcalar[-1] -NotePropertyValue $deger -Force
}
function AnahtarDuzelt($nesne, [string]$alan, $harita) {
  $alt = $nesne.$alan; if ($null -eq $alt) { throw "anahtar düzeltme: '$alan' alanı yok" }
  $sirali = [ordered]@{}
  foreach ($ozellik in @($alt.PSObject.Properties)) {
    $yeniAd = $(if ($harita.PSObject.Properties[$ozellik.Name]) { "$($harita.($ozellik.Name))" } else { $ozellik.Name })
    if ($sirali.Contains($yeniAd)) { throw "anahtar düzeltme çakışması: '$alan' içinde '$yeniAd' zaten var" }
    $sirali[$yeniAd] = $ozellik.Value
  }
  $duzen = [ordered]@{}; foreach ($harf in 'A', 'B', 'C', 'D', 'E') { if ($sirali.Contains($harf)) { $duzen[$harf] = $sirali[$harf] } }
  foreach ($ad in $sirali.Keys) { if (-not $duzen.Contains($ad)) { $duzen[$ad] = $sirali[$ad] } }
  $nesne | Add-Member -NotePropertyName $alan -NotePropertyValue ([pscustomobject]$duzen) -Force
}

$yamaNesne = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Resolve-Path $Yama).Path, [Text.Encoding]::UTF8))
$gruplar = [ordered]@{}
foreach ($ozellik in $yamaNesne.PSObject.Properties) {
  $kimlik = $ozellik.Name; $bolu = $kimlik.LastIndexOf('/'); if ($bolu -lt 1) { throw "kimlik '<etiket>/<kp>' olmalı: $kimlik" }
  $etiket = $kimlik.Substring(0, $bolu); if (-not $gruplar.Contains($etiket)) { $gruplar[$etiket] = New-Object System.Collections.Generic.List[object] }
  $gruplar[$etiket].Add([pscustomobject]@{ kimlik = $kimlik; kp = $kimlik.Substring($bolu + 1); yama = $ozellik.Value })
}
$kosanEtiketler = @(& (Join-Path $PSScriptRoot 'bulut-kosan-etiketler.ps1') -Kati)
if ($Yaz) { New-Item -ItemType Directory -Force $yedekDizin | Out-Null }
$yazilan = 0; $atlanan = 0; $damga = (Get-Date).ToString('yyyyMMdd-HHmmss')
foreach ($etiket in $gruplar.Keys) {
  if ($kosanEtiketler -contains $etiket) { Write-Host "  ATLANDI (bulutta koşuyor): $etiket" -ForegroundColor Yellow; $atlanan++; continue }
  $icerik = PartiGetir $etiket
  $ozgun = ConvertTo-Json -InputObject $icerik -Depth 30 -Compress
  $anahtarSayisi = @($icerik.PSObject.Properties).Count
  $sorun = New-Object System.Collections.Generic.List[string]; $izler = @{}
  foreach ($kalem in $gruplar[$etiket]) {
    if (-not $icerik.PSObject.Properties[$kalem.kp]) { $sorun.Add("$($kalem.kimlik): soru partide yok"); continue }
    $soru = $icerik.($kalem.kp); $onceIz = SmmmParmakIzi $soru; $izler[$kalem.kp] = $onceIz
    if ($kalem.yama.PSObject.Properties['anahtar_duzelt']) { foreach ($alanOz in $kalem.yama.anahtar_duzelt.PSObject.Properties) { AnahtarDuzelt $soru $alanOz.Name $alanOz.Value } }
    if ($kalem.yama.PSObject.Properties['alanlar']) { foreach ($alanOz in $kalem.yama.alanlar.PSObject.Properties) {
        if ($alanOz.Name -in 'soru', 'siklar', 'dogru' -or $alanOz.Name -like 'siklar.*') { $sorun.Add("$($kalem.kimlik): '$($alanOz.Name)' yamalanamaz"); continue }
        AlanYaz $soru $alanOz.Name $alanOz.Value } }
    if ((SmmmParmakIzi $soru) -ne $onceIz) { $sorun.Add("$($kalem.kimlik): soru/şık/cevap parmak izi değişti") }
    $kalanEksik = @(SmmmKcEksik $soru); if ($kalanEksik.Count) { $sorun.Add("$($kalem.kimlik): KAPI-KC hâlâ eksik: $($kalanEksik -join ', ')") }
  }
  if ($sorun.Count) { $sorun | ForEach-Object { Write-Host "  ⛔ $_" -ForegroundColor Red }; Write-Host "  YAZILMADI: $etiket" -ForegroundColor Red; $atlanan++; continue }
  $kimlikler = ($gruplar[$etiket] | ForEach-Object { $_.kp }) -join ','
  if (-not $Yaz) { Write-Host "  kuru koşu GEÇTİ: $etiket [$kimlikler]"; continue }
  [IO.File]::WriteAllText((Join-Path $yedekDizin "$($etiket)-$damga.json"), $ozgun, (New-Object Text.UTF8Encoding $false))
  $govde = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject ([ordered]@{ icerik = $icerik }) -Depth 30 -Compress))
  $yazBaslik = $istekBaslik + @{ Prefer = 'return=minimal' }
  [void](Invoke-WebRequest -UseBasicParsing -Method Patch -Uri ("$tabloUcu" + '?etiket=eq.' + [uri]::EscapeDataString($etiket)) -Headers $yazBaslik -ContentType 'application/json; charset=utf-8' -Body $govde -TimeoutSec 120)
  $geri = PartiGetir $etiket; $geriSorun = @()
  if (@($geri.PSObject.Properties).Count -ne $anahtarSayisi) { $geriSorun += "soru sayısı $anahtarSayisi -> $(@($geri.PSObject.Properties).Count)" }
  foreach ($kalem in $gruplar[$etiket]) {
    $gs = $geri.($kalem.kp)
    if ((SmmmParmakIzi $gs) -ne $izler[$kalem.kp]) { $geriSorun += "$($kalem.kp) parmak izi" }
    if (@(SmmmKcEksik $gs).Count) { $geriSorun += "$($kalem.kp) KAPI-KC" }
  }
  if ($geriSorun.Count) { Write-Host "  ⛔ GERİ OKUMA TUTMADI: $etiket ($($geriSorun -join '; ')) — yedek: $yedekDizin" -ForegroundColor Red; exit 1 }
  Write-Host "  YAZILDI + geri okundu: $etiket [$kimlikler]"; $yazilan++
}
"KC TAMAMLAMA: $(if ($Yaz) { 'yazılan' } else { 'kuru koşu' }) $(if ($Yaz) { $yazilan } else { @($gruplar.Keys).Count - $atlanan }) parti · atlanan/durdurulan $atlanan"
if ($atlanan) { exit 1 }
