# SGS ACILIS KOSUCUSU (sgs-a6) - ANLIK MOD (10.09.2026 Cem: kuyruk 3 saat tikandi, "daha hizli").
#
# Kullanim (fabrika sohbeti):
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/sgs-a6-kos.ps1 -Grup "Finansal Muhasebe,Muhasebe" -ButceTavan 150
#   -Grup   : plan-sgs-a6.json'daki dersAd degerleri (virgulle). Her sohbet KENDI grubunu kosar, baskasinin grubuna GIRMEZ.
#   -ButceTavan : bu grubun USD tavani; bedel-kayit.jsonl'den sgs-a6-* toplami okunur, asilirsa durur.
#   -Toplu  : verilirse toplu mod (varsayilan ANLIK).
# Her etiket icin uretici yeniden okunur; parti dosyasi varsa uretici kendi cache'inden devam eder.
# 10.09 Cem: "ilk once hep ucuz olan yerden dene, toplu olmazsa pahali yere" -> varsayilan TOPLU, faz 20 dk'da
# donmezse uretici kendi anliga duser (motor satir 45, MEVZUAT_TOPLU_BEKLE_DK). -Anlik verilirse dogrudan anlik.
# -TurMin/-TurMax: dalga secimi. 1. dalga tur 1-6 (05:02'de basladi); 2. dalga tur 7+ (tur tavaninin kestigi
# en onemli konular: ortak maliyet dagitimi, dikey yuzde, denetim kaniti...). Cem 10.09: "en onemliler Maliyet, FMuh".
# -ButceTavan: bu GRUBUN etiketlerinin toplami (ilk surumde butun sgs-a6 toplamina bakiyordu -> kucuk grup erken dururdu, 10.09 duzeltildi)
# -GlobalTavan: butun sgs-a6* (fabrika + elle) toplami; Cem 10.09: 1.200 USD.
param([Parameter(Mandatory)][string]$Grup, [double]$ButceTavan = 150.0, [double]$GlobalTavan = 1200.0, [switch]$Anlik, [int]$TopluBekleDk = 20, [int]$Bekle = 0, [int]$TurMin = 1, [int]$TurMax = 6)
$Toplu = -not $Anlik
$ErrorActionPreference = 'Continue'
$kok = Split-Path $PSScriptRoot -Parent
Set-Location $kok
$uretici = Join-Path $kok 'motor\kalip-parti-uret.ps1'
$tok = $null; $err = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($uretici, [ref]$tok, [ref]$err)
if ($err.Count) { "URETICI PARSE HATA: $($err[0].Message)"; exit 1 }

$gruplar = @($Grup -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$tum = @((ConvertFrom-Json -InputObject (Get-Content (Join-Path $kok 'veri\sinav\plan-sgs-a6.json') -Raw -Encoding UTF8)) | ForEach-Object { $_ })
$grupEtiketler = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($p in ($tum | Where-Object { $gruplar -contains "$($_.dersAd)" })) { [void]$grupEtiketler.Add("$($_.etiket)") }
function A6Bedel([switch]$Global) {
  $toplam = 0.0
  foreach ($r in (Get-Content (Join-Path $kok 'veri\fabrika\bedel-kayit.jsonl') -Encoding UTF8 -ErrorAction SilentlyContinue | ForEach-Object { try { $_ | ConvertFrom-Json }catch {} })) {
    $e = "$($r.etiket)"
    if ($Global) { if ($e -like 'sgs-a6*') { $toplam += [double]$r.toplamUsd } }
    elseif ($grupEtiketler.Contains($e)) { $toplam += [double]$r.toplamUsd }
  }
  [math]::Round($toplam, 2)
}
$sevSira = @{ 'kolay' = 0; 'zor' = 1; 'cokzor' = 2 }   # alfabetik degil, kolaydan zora
$plan = @($tum | Where-Object { $gruplar -contains "$($_.dersAd)" -and [int]$_.tur -ge $TurMin -and [int]$_.tur -le $TurMax } | Sort-Object tur, { $sevSira["$($_.zorluk)"] })
"GRUP [$($gruplar -join ', ')] · tur $TurMin-$TurMax · etiket $($plan.Count) · soru $(($plan | Measure-Object adet -Sum).Sum) · mod $(if($Toplu){'TOPLU'}else{'ANLIK'}) · tavan $ButceTavan USD (sgs-a6 toplam)"
"harcanan: bu grup $(A6Bedel) USD · sgs-a6 toplam $(A6Bedel -Global) USD (genel tavan $GlobalTavan)"

if ($Toplu) { $env:MEVZUAT_TOPLU = '1'; $env:MEVZUAT_TOPLU_BEKLE_DK = "$TopluBekleDk"; $env:MEVZUAT_TOPLU_PARCA = '30' } else { $env:MEVZUAT_TOPLU = '0' }
$env:MEVZUAT_CLAIM = '0'
New-Item -ItemType Directory -Force (Join-Path $kok 'veri\fabrika\kosucu-log') | Out-Null

$toplamKayit = 0; $toplamYayin = 0
foreach ($p in $plan) {
  $harcanan = A6Bedel; $genel = A6Bedel -Global
  if ($harcanan -ge $ButceTavan) { "!! GRUP TAVANI ($ButceTavan USD) ASILDI: $harcanan USD - DURDU"; break }
  if ($genel -ge $GlobalTavan) { "!! GENEL TAVAN ($GlobalTavan USD) ASILDI: sgs-a6 toplam $genel USD - DURDU"; break }
  # ayni etiket baska surecte kosuyorsa (onceki kosucunun bitmemis cocugu) atla - cift basim/cift bedel olmasin
  if (@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match ('-Etiket\s+' + [regex]::Escape($p.etiket) + '(\s|$)') -and $_.ProcessId -ne $PID }).Count) { "  $($p.etiket): baska surecte kosuyor, atlandi"; continue }
  # bitmis etiket: uretici kendi bitis damgasina bakip atlar (motor satir 59); burada da html damgasi varsa hic cagirmayalim
  if (Test-Path -LiteralPath (Join-Path $kok ("veri\fabrika\kalip-parti-{0}.html" -f $p.etiket))) { "  $($p.etiket): bitmis (html damgasi), atlandi"; continue }
  $kd = Join-Path $kok ($p.konuDosya -replace '/', '\')
  if (-not (Test-Path -LiteralPath $kd)) { "  $($p.etiket): konu dosyasi yok, atlandi"; continue }
  $liste = @((ConvertFrom-Json -InputObject (Get-Content -LiteralPath $kd -Raw -Encoding UTF8)) | ForEach-Object { $_ })
  if ($liste.Count -eq 0) { "  $($p.etiket): konu yok, atlandi"; continue }
  $log = Join-Path $kok ("veri\fabrika\kosucu-log\a6-{0}.log" -f $p.etiket)
  $arg = @('-Sinav', 'SGS', '-DersRegex', $p.ders, '-Adet', "$($liste.Count)", '-Etiket', $p.etiket,
    '-UzunlukTavan', "$($p.tavan)", '-Verilenler', '-KonuGiris', '-Simulasyon', '-SimModel', 'claude-sonnet-5',
    '-DonemPencere', '7', '-Zorluk', $p.zorluk, '-KonuDosya', $p.konuDosya)
  if ($Toplu) { $arg += '-Toplu' }
  "  [$(Get-Date -Format 'HH:mm')] $($p.etiket) · $($liste.Count) konu · harcanan $harcanan USD"
  & powershell -NoProfile -ExecutionPolicy Bypass -File motor/kalip-parti-uret.ps1 @arg *> $log
  $pf = Join-Path $kok ("veri\fabrika\kalip-parti-{0}.json" -f $p.etiket)
  $yay = 0; $n = 0
  if (Test-Path -LiteralPath $pf) {
    $j = ConvertFrom-Json -InputObject (Get-Content -LiteralPath $pf -Raw -Encoding UTF8)
    foreach ($pr in $j.PSObject.Properties) {
      if ($pr.Name -notmatch '^kp-\d+$') { continue }
      $v = $pr.Value; if (-not $v.soru) { continue }
      $n++
      if ("$($v.hakem.karar)" -eq 'EVET' -and ($v.kor_cozum -and [bool]$v.kor_cozum.dogru_mu) -and "$($v.hakem2.karar)" -eq 'EVET' -and -not ($v.simulasyon_sonnet -and -not [bool]$v.simulasyon_sonnet.dogru_mu)) { $yay++ }
    }
  }
  $toplamKayit += $n; $toplamYayin += $yay
  "     -> kayit $n · yayinlanabilir $yay"
  if ($Bekle -gt 0) { Start-Sleep -Seconds $Bekle }
}
"########## GRUP [$($gruplar -join ', ')] tur $TurMin-$TurMax BITTI · kayit $toplamKayit · yayinlanabilir $toplamYayin · grup bedel $(A6Bedel) USD · sgs-a6 toplam $(A6Bedel -Global) USD ##########"
