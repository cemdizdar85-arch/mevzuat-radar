#requires -Version 5.1
<#
================================================================================
  GÖZETİM ONARICI — ÖZ-SINAV + MUTASYON  (12.10.2026)  bedel 0 (model çağrısı YOK)

  NİYE VAR (ölçüldü 12.10): mevzuat.yml "GOZETIM ONARICI" adımı 03.10–11.10 arasındaki her tetiklemede
  "Cannot bind argument to parameter 'Path' because it is null." yazıp veri değiştirmeden bitti
  (ör. run 38115672995). Kök: koşucu ubuntu, orada $env:TEMP yok → motor/gozetim-onarici.ps1
  `Join-Path $env:TEMP …`. Hata catch'te yalnız mesajla basıldığı için satır görünmüyordu.
  Düzeltme: [IO.Path]::GetTempPath() + betik başında satır numaralı trap + -KuruKosu (B/mail/yazım yok).

  Vakalar (gerçek motor/gozetim-onarici.ps1 koşar; TEMP/TMP/TMPDIR ve API/mail anahtarları SÜREÇTEN silinir):
   V1 TEMP yokken PDF yolu çözülür (null-Path hatası yok)                       — ağsız
   V2 hata olunca satır numarası basılır ve doğru satırı gösterir                — ağsız
   V3 gerçek tebliğ PDF'i (2026/36, mevzuatNo 44987): A okur, B ÇAĞRILMAZ        — ağ + pdftotext; yoksa KÖR
   V5 bozuk PDF: pdftotext stderr uyarısı betiği öldürmez (PS 5.1 EAP=Stop, K6 deseni) — pdftotext yoksa KÖR
   V6 gerçek PDF'ten sonra bozuk PDF: önceki koşunun .layout.txt'si okunmaz      — ağ + pdftotext; yoksa KÖR
   V4 birinci fren kapalıyken ikinci fren (OkuyucuB içi) B'yi durdurur           — kopya, api-hedef nötr
  -Mutasyon: M1 GetTempPath→$env:TEMP · M2 KuruKosu bloğu kapalı · M3 trap yok · M4 ikinci fren yok ·
  M6 bayat .layout.txt silinmiyor · her bozma KENDİ vakasından düşmeli (M1→V1 … M6→V6), başka vakadan düşmek sayılmaz ·
  M5 pdftotext EAP sarması yok (yalnız PS 5.1'de görünür; pwsh 7'de yerel stderr fırlatmaz → orada KÖR değil YEŞİL kalabilir).
  Her bozmada sınav KIRMIZI düşmeli. Mutant kopyalarda api-hedef yüklemesi ve Invoke-RestMethod
  `throw` ile değiştirilir → bozuk kopya da ağa/modele çıkamaz.
  🚫 GÖRMEZ: Okuyucu B'nin (model) gerçek okuması · mutabakat/hakem mantığı · -Uygula yazımı ·
     -Damgadan eşlemesi · mail gönderimi · mevzuat.yml adımının kendisi (yalnız betik).
================================================================================
#>
param([switch]$Mutasyon, [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$motor = Join-Path $depoKok 'motor'
$gercek = Join-Path $motor 'gozetim-onarici.ps1'
$gercekMetin = [IO.File]::ReadAllText($gercek, [Text.Encoding]::UTF8)
$gecici = Join-Path $motor '_sinav-gozetim-onarici.tmp.ps1'
$isDizin = Join-Path ([IO.Path]::GetTempPath()) ('onarici-sinav-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $isDizin -Force | Out-Null
$sahte = Join-Path $isDizin 'sahte.pdf'
[IO.File]::WriteAllText($sahte, 'bu bir pdf degil')
$gercekPdf = Join-Path $isDizin 'gercek.pdf'
$silinecek = @('USERPROFILE', 'TEMP', 'TMP', 'TMPDIR', 'ANTHROPIC_API_KEY', 'OPENROUTER_KEY', 'ANTHROPIC_AWS_API_KEY', 'AWS_REGION', 'ANTHROPIC_AWS_WORKSPACE_ID', 'RESEND_KEY')

# gerçek PDF bir kez indirilir (V3/V4); inmezse ya da pdftotext yoksa o vakalar KÖR
$korNeden = $null
if (-not (Get-Command pdftotext -ErrorAction SilentlyContinue)) { $korNeden = 'pdftotext yok' }
else {
  try {
    Invoke-WebRequest -Uri 'https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.44987.pdf' -OutFile $gercekPdf -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0' -Headers @{Referer = 'https://www.mevzuat.gov.tr/' } -TimeoutSec 90 -UseBasicParsing
    $bas = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($gercekPdf), 0, 4)
    if ($bas -ne '%PDF') { $korNeden = "indirilen dosya PDF degil ($bas)" }
  } catch { $korNeden = "mevzuat.gov.tr inmedi: $($_.Exception.Message)" }
}

function Kos([string]$yol, [hashtable]$arg) {
  $eski = @{}; foreach ($a in $silinecek) { $eski[$a] = [Environment]::GetEnvironmentVariable($a, 'Process'); [Environment]::SetEnvironmentVariable($a, $null, 'Process') }
  [Environment]::SetEnvironmentVariable('USERPROFILE', $isDizin, 'Process')   # Windows GetTempPath son durağı; ev dizini kirlenmesin
  try {
    $buf = New-Object System.Collections.Generic.List[string]
    try { & $yol @arg *>&1 | ForEach-Object { $buf.Add([string]$_) } } catch { $buf.Add("YAKALANDI: $($_.Exception.Message)") }
    return ($buf -join "`n")
  } finally { foreach ($a in $silinecek) { [Environment]::SetEnvironmentVariable($a, $eski[$a], 'Process') } }
}
function Notr([string]$metin) {
  # kopyalar ağa/modele çıkamaz
  $m = $metin.Replace(". (Join-Path `$here 'api-hedef.ps1')", "throw 'NOTR: api-hedef yuklenecekti'")
  $m = $m.Replace('Invoke-RestMethod -Uri', "throw 'NOTR: Invoke-RestMethod'; Invoke-RestMethod -Uri")
  if ($m -eq $metin) { throw 'Notr: api-hedef/Invoke-RestMethod deseni bulunamadi (betik degisti, sinavi tazele)' }
  return $m
}
function KopyaYaz([string]$metin) { [IO.File]::WriteAllText($gecici, $metin, (New-Object Text.UTF8Encoding($true))) }
function Degistir([string]$metin, [string]$eski, [string]$yeni) {
  if (-not $metin.Contains($eski)) { throw "Degistir: '$eski' bulunamadi (betik degisti, sinavi tazele)" }
  return $metin.Replace($eski, $yeni)
}
$fren1 = "  if(`$KuruKosu){`r`n    `$y = YururlukCoz"
if (-not $gercekMetin.Contains($fren1)) { $fren1 = $fren1.Replace("`r`n", "`n") }
$fren2 = "if(`$KuruKosu){ throw 'KURU KOSU: OkuyucuB"

function SinavKos([string]$betik, [string]$v4Metin) {
  $sonuc = New-Object System.Collections.Generic.List[string]
  function V([string]$ad, $ok, [string]$ek) {
    if ($ok -is [string] -and $ok -eq 'KOR') { if (-not $Sessiz) { Write-Host "  KÖR   $ad ($ek)" }; return }
    if ($ok) { if (-not $Sessiz) { Write-Host "  OK    $ad" } } else { $sonuc.Add("$ad ($ek)"); if (-not $Sessiz) { Write-Host "  DÜŞTÜ $ad ($ek)" } }
  }
  $arg = @{ TebligNo = '2026/36'; MevzuatNo = 44987; KuruKosu = $true }

  $c = Kos $betik ($arg + @{ PdfKaynak = $sahte })
  V 'V1 TEMP/TMP yokken PDF yolu cozuldu, null-Path yok' (($c -match 'PDF yolu: \S') -and ($c -notmatch "because it is null")) ($c.Trim() -replace '\s+', ' ')
  if (Get-Command pdftotext -ErrorAction SilentlyContinue) {
    V 'V5 bozuk PDF: aracin stderr uyarisi betigi oldurmez, olcu Test-Path (pdftotext uretmedi)' (($c -match 'pdftotext uretmedi') -and ($c -notmatch 'HATA satir \d+: Syntax')) ($c.Trim() -replace '\s+', ' ')
  } else { V 'V5 bozuk PDF stderr' 'KOR' 'pdftotext yok' }

  $yok = Join-Path $isDizin 'olmayan.pdf'
  $c = Kos $betik ($arg + @{ PdfKaynak = $yok })
  $hedefSatir = 0; $s = 0; foreach ($L in ([IO.File]::ReadAllText($betik, [Text.Encoding]::UTF8) -split "`n")) { $s++; if ($L -match 'Copy-Item -LiteralPath \$PdfKaynak') { $hedefSatir = $s; break } }
  V 'V2 hata satiri basildi ve Copy-Item satirini gosteriyor' ($c -match "onarici HATA satir $hedefSatir\b") "beklenen satir $hedefSatir | $($c.Trim() -replace '\s+', ' ')"

  if ($korNeden) { V 'V3 gercek PDF: A okur, B cagrilmaz' 'KOR' $korNeden; V 'V6 bayat layout.txt' 'KOR' $korNeden; V 'V4 ikinci fren' 'KOR' $korNeden }
  else {
    $c = Kos $betik ($arg + @{ PdfKaynak = $gercekPdf })
    V 'V3 gercek PDF: A kesin, B CAGRILMADI, kuru satiri var' (($c -match 'A: kesin=True satir=[1-9]') -and ($c -match 'KURU: B atlandi') -and ($c -notmatch 'B: satir|B kosamadi|NOTR:')) ($c.Trim() -replace '\s+', ' ')
    $c = Kos $betik ($arg + @{ PdfKaynak = $sahte })   # V3'un .layout.txt'si diskte duruyor
    V 'V6 gercek PDF sonrasi bozuk PDF: bayat layout.txt OKUNMADI' (($c -match 'pdftotext uretmedi') -and ($c -notmatch 'kesin=True')) ($c.Trim() -replace '\s+', ' ')
    KopyaYaz $v4Metin
    $c = Kos $gecici ($arg + @{ PdfKaynak = $gercekPdf })
    V 'V4 birinci fren kapaliyken ikinci fren B yi durdurdu' (($c -match 'OkuyucuB cagrilmamaliydi') -and ($c -notmatch 'NOTR:') -and ($c -notmatch 'B: satir')) ($c.Trim() -replace '\s+', ' ')
  }
  return , $sonuc
}

$v4Taban = Notr (Degistir $gercekMetin $fren1 ($fren1.Replace('if($KuruKosu){', 'if($false){')))
$cikis = 0
try {
  if (-not $Mutasyon) {
    if (-not $Sessiz) { Write-Host "GOZETIM ONARICI OZ-SINAV" }
    $d = SinavKos $gercek $v4Taban
    if ($d.Count) { Write-Host "KIRMIZI: $($d.Count) vaka dustu"; $cikis = 1 } else { Write-Host ("YESIL" + $(if ($korNeden) { " (V3/V4 KÖR: $korNeden)" } else { '' })) }
  } else {
    if ($korNeden) { Write-Host "MUTASYON KÖR: $korNeden (M2/M4 olculemez)" }
    $mut = [ordered]@{
      'M1 GetTempPath -> $env:TEMP' = { param($m) Degistir $m 'Join-Path ([IO.Path]::GetTempPath())' 'Join-Path $env:TEMP' }
      'M2 KuruKosu blogu kapali'    = { param($m) Degistir $m $fren1 ($fren1.Replace('if($KuruKosu){', 'if($false){')) }
      'M3 trap yok'                 = { param($m) Degistir $m 'trap { Write-Host ("onarici HATA satir' '$null = { Write-Host ("onarici HATA satir' }
      'M5 pdftotext EAP sarmasi yok' = { param($m) Degistir $m 'try { & pdftotext -layout -enc UTF-8 $pdfYol $txt 2>$null } finally { $ErrorActionPreference = $eapEski }' '$ErrorActionPreference = $eapEski; & pdftotext -layout -enc UTF-8 $pdfYol $txt 2>$null' }
      'M4 ikinci fren yok'          = { param($m) Degistir $m $fren2 "if(`$false){ throw 'KURU KOSU: OkuyucuB" }
      'M6 bayat layout.txt silinmiyor' = { param($m) Degistir $m 'if(Test-Path -LiteralPath $txt){ Remove-Item -LiteralPath $txt -Force }' '$null = 0' }
    }
    # her bozma KENDI vakasindan dusmeli; baska vakadan dusmek "dogru gerekceyle kirmizi" sayilmaz
    $bekVaka = @{ 'M1' = 'V1'; 'M2' = 'V3'; 'M3' = 'V2'; 'M4' = 'V4'; 'M5' = 'V5'; 'M6' = 'V6' }
    $Sessiz = $true; $dusen = 0; $olculen = 0
    foreach ($k in $mut.Keys) {
      $mm = Notr (& $mut[$k] $gercekMetin)
      if ($k -like 'M2*') { $v4 = $mm }   # M2'de birinci fren zaten kapalı
      else { $v4 = Notr (Degistir (& $mut[$k] $gercekMetin) $fren1 ($fren1.Replace('if($KuruKosu){', 'if($false){'))) }
      Get-ChildItem -LiteralPath $isDizin -Filter 'onarici-*' | ForEach-Object { [IO.File]::Delete($_.FullName) }   # temiz is dizini
      KopyaYaz $mm
      $d = SinavKos $gecici $v4
      if ($korNeden -and ($k -like 'M2*' -or $k -like 'M4*' -or $k -like 'M6*')) { Write-Host "  KÖR    $k"; continue }
      if ($k -like 'M5*' -and ($PSVersionTable.PSVersion.Major -ge 7 -or -not (Get-Command pdftotext -ErrorAction SilentlyContinue))) { Write-Host "  KÖR    $k (pwsh 7 yerel stderr'i firlatmaz / pdftotext yok)"; continue }
      $olculen++
      $bv = $bekVaka[$k.Substring(0, 2)]
      $kendi = @($d | Where-Object { $_ -like "$bv *" })
      if ($kendi.Count) { $dusen++; Write-Host ("  KIRMIZI $k  <- $bv" + $(if ($d.Count -gt 1) { " (+$($d.Count - 1) baska vaka)" } else { '' })) }
      elseif ($d.Count) { Write-Host "  YANLIS GEREKCE $k  ($bv dusmedi; dusen: $(($d | ForEach-Object { $_.Substring(0, 2) }) -join ','))" }
      else { Write-Host "  YESIL!  $k  (sinav bozmayi GORMEDI)" }
    }
    Write-Host "MUTASYON: $dusen/$olculen bozma KIRMIZI"
    if ($dusen -ne $olculen) { $cikis = 1 }
  }
} finally {
  Remove-Item -LiteralPath $gecici -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $isDizin -Recurse -Force -ErrorAction SilentlyContinue
}
exit $cikis
