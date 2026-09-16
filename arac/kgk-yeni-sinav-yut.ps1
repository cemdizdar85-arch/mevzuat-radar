# ============================================================================
#  KGK YENİ SINAV ZİNCİRİ — nöbetçi "YENİ kitapçık" dediği gün koşulur   16.09.2026
#  Cem "1.2.3 ÜÇÜNÜDE YAP" (GM 3): Kasım 2026 kitapçığı yayımlanınca aynı gün indir → ayrıştır → ambara yut.
#
#  ADIMLAR (1–5 PARASIZ; 6 PARALI, bu betik KOŞTURMAZ):
#   1. Sınav sayfası: -Kod verilirse veri/kgk-sinav-nobeti.json'daki (yeni ya da sayfadaki) tam adres, yoksa -Adres.
#      Kod verilmezse nöbetçi raporundaki bütün YENİ girdiler işlenir.
#   2. Sayfadaki "Sınav" PDF'leri veri/kgk-arsiv/pdf-links.tsv'ye eklenir (varsa eklenmez).
#   3. motor/kgk-arsiv-indir.ps1 — eksik PDF'ler iner, metne döner (var olanı atlar).
#   4. motor/cikmis-soru-ayristir.ps1 -klasor veri/kgk-arsiv/pdf -sinavAdi KGK -desen "<kod>_*.pdf" — soru blokları ambara
#      (tur=cikmis-soru; ambarda olanı atlar). Ayrı cevap anahtarı dosyası varsa arac/kgk-cevap-anahtari-yut.ps1.
#   5. Ölçümler: motor/kgk-sinav-nobeti.ps1 (YENİ düşmeli) · arac/kgk-cikmis-tamlik.ps1 · motor/sinav-arsiv-karnesi.ps1.
#   6. KONU ETİKETLEME (veri/kgk-arsiv/etiket/<kod>.json → veri/kgk-analiz.json) MODEL İSTER, PARALIDIR — Cem'e bedeliyle
#      sorulur; bu betik yalnız hatırlatır. kgk-analiz.json'u motor/kgk-siklik-derle.ps1 ÜRETMEZ (eski biçim, korumalı).
#  Varsayılan KURU PROVA: yalnız ne yapılacağını yazar (tsv'ye, ambara, diske yazmaz). Yazmak için -Yaz.
#  Kullanım: powershell -NoProfile -File arac/kgk-yeni-sinav-yut.ps1 [-Kod 12345] [-Adres <tam adres>] [-Yaz]
# ============================================================================
param([string]$Kod = '', [string]$Adres = '', [switch]$Yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
Set-Location $depoKok
$arsiv = Join-Path (Join-Path $depoKok 'veri') 'kgk-arsiv'
$tsvYolu = Join-Path $arsiv 'pdf-links.tsv'
$nobetYolu = Join-Path (Join-Path $depoKok 'veri') 'kgk-sinav-nobeti.json'
$kabuk = if(Get-Command powershell -ErrorAction SilentlyContinue){ 'powershell' } else { 'pwsh' }

# --- 1) işlenecek sınavlar
$isler = New-Object System.Collections.Generic.List[object]
$nobet = if(Test-Path $nobetYolu){ Get-Content $nobetYolu -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
if($Kod){
  $adresBul = $Adres
  if(-not $adresBul -and $nobet){ foreach($g in @($nobet.yeni) + @($nobet.sayfadakiler)){ if("$($g.kod)" -eq $Kod -and "$($g.adres)" -match '/\d+/'){ $adresBul = "$($g.adres)"; break } } }
  if(-not $adresBul){ Write-Host "Adres bulunamadı: -Adres ile tam sayfa adresini (başlık kısmıyla) ver ya da önce motor/kgk-sinav-nobeti.ps1 koş."; exit 1 }
  $isler.Add([pscustomobject]@{ kod=$Kod; adres=$adresBul })
} elseif($nobet -and @($nobet.yeni).Count){
  foreach($g in $nobet.yeni){ $isler.Add([pscustomobject]@{ kod="$($g.kod)"; adres="$($g.adres)" }) }
} else { Write-Host 'Nöbetçi raporunda YENİ sınav yok. (Belirli bir sınav için -Kod.)'; exit 0 }

$tsvSatirlari = @(); if(Test-Path $tsvYolu){ $tsvSatirlari = @(Get-Content $tsvYolu -Encoding UTF8) }
$tsvAdresleri = New-Object System.Collections.Generic.HashSet[string]
foreach($satir in $tsvSatirlari){ $p = $satir -split "`t"; if($p.Count -ge 3){ [void]$tsvAdresleri.Add([uri]::UnescapeDataString($p[2].Trim())) } }

$eklenecek = New-Object System.Collections.Generic.List[string]
foreach($is in $isler){
  Write-Host "== $($is.kod) · $($is.adres)"
  $icerik = "$((Invoke-WebRequest -UseBasicParsing -Uri $is.adres -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -TimeoutSec 60).Content)"
  if($icerik -match 'class="error"'){ Write-Host '  !! KGK hata sayfası döndü (adres başlık kısmı eksik olabilir).'; exit 1 }
  $pdfler = @([regex]::Matches($icerik,'(?i)(?:href|data-href)=[''"]([^''"]+\.pdf)[''"]') | ForEach-Object { $_.Groups[1].Value } | Where-Object { [uri]::UnescapeDataString($_) -match '(?i)S[ıi]nav' } | Select-Object -Unique)
  # KGK sayfası bağlantıyı 'href:Portalv2Uploads/…' biçiminde yazar (16.09 ölçüldü) → önek atılıp site köküne bağlanır
  $pdfler = @($pdfler | ForEach-Object { $ham = ($_ -replace '^href:','').TrimStart('/'); if($ham -match '^https?://'){ $ham } else { 'https://kgk.gov.tr/' + $ham } })
  Write-Host "  sayfadaki sınav PDF'i: $($pdfler.Count)"
  if(-not $pdfler.Count){ Write-Host '  !! PDF bulunamadı — sayfa düzeni değişmiş olabilir; elle bakılmalı.'; exit 1 }
  foreach($pdf in $pdfler){
    $cozulmus = [uri]::UnescapeDataString($pdf)
    if($tsvAdresleri.Contains($cozulmus)){ Write-Host "  listede: $(($cozulmus -split '/')[-1])"; continue }
    Write-Host "  EKLENECEK: $(($cozulmus -split '/')[-1])"
    $eklenecek.Add("$($is.kod)`tYeni sınav ($(Get-Date -Format 'dd.MM.yyyy'))`t$pdf")
  }
}

if(-not $Yaz){
  Write-Host ''
  Write-Host "KURU PROVA — yapılacaklar: pdf-links.tsv'ye $($eklenecek.Count) satır · kgk-arsiv-indir · cikmis-soru-ayristir (KGK, $(($isler | ForEach-Object { $_.kod }) -join ',')) · cevap anahtarı · ölçümler."
  Write-Host 'Yazmak için -Yaz. Konu etiketleme (adım 6) PARALIDIR — Cem onayı ister.'
  # ayrıştırıcı kuru koşuda raporu artık yazmaz (16.09 kuralı); yine de kuru provada çağrılmaz — prova yalnız listeler

  exit 0
}

# --- 2) tsv
if($eklenecek.Count){ [IO.File]::AppendAllText($tsvYolu, (($eklenecek -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false))); Write-Host "pdf-links.tsv: +$($eklenecek.Count) satır" }
# --- 3) indir
& $kabuk -NoProfile -File (Join-Path (Join-Path $depoKok 'motor') 'kgk-arsiv-indir.ps1') 2>&1 | Select-Object -Last 3 | ForEach-Object { "  [indir] $_" }
# --- 4) ayrıştır + yut
# veri/cikmis-soru-ayrisma.json 'son koşu raporu'dur ve SPL karnesi onu okur → KGK koşusu onu ezmesin: önce yedek, sonra geri
$ayrismaRaporu = Join-Path (Join-Path $depoKok 'veri') 'cikmis-soru-ayrisma.json'
$ayrismaYedek = if(Test-Path $ayrismaRaporu){ [IO.File]::ReadAllBytes($ayrismaRaporu) } else { $null }
foreach($is in $isler){
  & $kabuk -NoProfile -File (Join-Path (Join-Path $depoKok 'motor') 'cikmis-soru-ayristir.ps1') -klasor (Join-Path $arsiv 'pdf') -sinavAdi 'KGK' -desen "$($is.kod)_*.pdf" -yaz 2>&1 | Select-Object -Last 5 | ForEach-Object { "  [ayrıştır] $_" }
}
if(Test-Path $ayrismaRaporu){ Copy-Item $ayrismaRaporu (Join-Path (Join-Path $depoKok 'veri') 'kgk-yeni-sinav-ayrisma.json') -Force }
if($null -ne $ayrismaYedek){ [IO.File]::WriteAllBytes($ayrismaRaporu,$ayrismaYedek) }
& $kabuk -NoProfile -File (Join-Path $PSScriptRoot 'kgk-cevap-anahtari-yut.ps1') -Yaz 2>&1 | Select-Object -Last 2 | ForEach-Object { "  [cevap] $_" }
# --- 5) ölçümler
& $kabuk -NoProfile -File (Join-Path (Join-Path $depoKok 'motor') 'kgk-sinav-nobeti.ps1') 2>&1 | Select-Object -Last 2 | ForEach-Object { "  [nöbet] $_" }
& $kabuk -NoProfile -File (Join-Path $PSScriptRoot 'kgk-cikmis-tamlik.ps1') 2>&1 | Select-Object -Last 1 | ForEach-Object { "  [tamlık] $_" }
& $kabuk -NoProfile -File (Join-Path (Join-Path $depoKok 'motor') 'sinav-arsiv-karnesi.ps1') 2>&1 | Select-String 'KGK' | ForEach-Object { "  [karne] $($_.Line)" }
Write-Host ''
Write-Host 'SIRADAKİ (PARALI, Cem onayı): yeni kitapçıkların konu etiketlemesi → veri/kgk-arsiv/etiket/<kod>.json → veri/kgk-analiz.json dönem kaydı.'
Write-Host 'Değişen dosyalar commit edilmeli: veri/kgk-arsiv/pdf-links.tsv (git dışıysa yerelde kalır) · veri/kgk-sinav-nobeti.json · veri/kgk-cikmis-tamlik.json · veri/cikmis-soru-karnesi.json'
exit 0
