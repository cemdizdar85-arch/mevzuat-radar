# ============================================================================
#  HAT ÖN KONTROLÜ — 25.08.2026
#  Cem: "1-2-3 yap" (GM onerisi 1: nobetciyi hattin onune civatala)
#
#  NEDEN VAR: 25.08'de buyuk/kucuk harf cakismasi TEK GUNDE BES kez vurdu ve
#  besinde de SESSIZCE YANLIS SONUC uretti (1.302 kusur "0" diye raporlandi,
#  20 sorunun 18'i yargilanamadi, bes kartin dordu yanlis konuda yazildi).
#  Nobetci yazildi ama ELLE kosuyordu. Hafizadaki ders acikti:
#      "Ders metne yazilirsa korumaz, ORTAK FONKSIYONA yazilirsa korur."
#  Bu dosya o ortak fonksiyondur. Uretim betikleri basinda cagirir; cakisma
#  varsa betik HIC BASLAMAZ. Kirli olcum uretmektense hic olcmemek yeglenir.
#
#  ⚠ BU KUTUPHANE NEDEN AYRI: degisken-cakisma-nobeti.ps1'i dogrudan nokta ile
#  yuklemek TAM DA DUZELTTIGIMIZ HATAYI yapardi - onun $kok/$here/$bulgular
#  degiskenleri cagiran betigin ayni adli degiskenlerini EZERDI. Bu yuzden bu
#  dosyada BETIK KAPSAMINDA HICBIR DEGISKEN YOKTUR; her sey fonksiyon icinde.
#  Nokta ile yuklemek guvenlidir.
#
#  KULLANIM (uretim betiginin en basina, param blogundan hemen sonra):
#      . (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'hat-onkontrol.ps1')
#      HatOnKontrol $MyInvocation.MyCommand.Path
#
#  0 USD, model yok, ~1 saniye (yalniz cagiran betik + yukledigi kutuphaneler).
# ============================================================================

function OnK_KapsamAtamalari {
  # Bir betikteki BETIK KAPSAMINDAKI atamalari dondurur: ad -> @(satir).
  # Fonksiyon govdeleri HARIC tutulur: onlarin ici YEREL kapsamdir ve
  # disaridaki ayni adli degiskeni EZMEZ. (25.08 dersi: desen tabanli ilk
  # surum bunu bilmedigi icin 25 bulgunun 21'i YALANCI cikti; profesor-v2.ps1
  # bosuna kirmizi aldi. Desen tahmin eder, COZUMLEYICI BILIR.)
  param([string]$yol)
  $agac = [Management.Automation.Language.Parser]::ParseFile($yol, [ref]$null, [ref]$null)
  if($null -eq $agac){ return @{} }
  $cikan = @{}
  $fonlar = $agac.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $true)
  $icinde = {
    param($nokta)
    foreach($fn in $fonlar){
      if($nokta -ge $fn.Extent.StartOffset -and $nokta -lt $fn.Extent.EndOffset){ return $true }
    }
    return $false
  }
  foreach($at in $agac.FindAll({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] }, $true)){
    if($at.Left -isnot [Management.Automation.Language.VariableExpressionAst]){ continue }
    if((& $icinde $at.Extent.StartOffset)){ continue }
    $ad = $at.Left.VariablePath.UserPath
    if($ad -match '[:.]'){ continue }
    if(-not $cikan.ContainsKey($ad)){ $cikan[$ad] = @() }
    $cikan[$ad] += $at.Extent.StartLineNumber
  }
  foreach($dn in $agac.FindAll({ param($n) $n -is [Management.Automation.Language.ForEachStatementAst] }, $true)){
    if((& $icinde $dn.Extent.StartOffset)){ continue }
    $ad = $dn.Variable.VariablePath.UserPath
    if($ad -match '[:.]'){ continue }
    if(-not $cikan.ContainsKey($ad)){ $cikan[$ad] = @() }
    $cikan[$ad] += $dn.Extent.StartLineNumber
  }
  return $cikan
}

function OnK_YuklenenKutuphaneler {
  # Betigin NOKTA ile yukledigi yerel .ps1 dosyalarini bulur.
  # Bunlar en tehlikeli sinifitir: kutuphanenin globali ($H kimlik basligi)
  # cagirandaki dongu degiskeni ($h) tarafindan silinir, ambar 401 doner,
  # cozucu "bu madde ambarda yok" demeye baslar ve HICBIR HATA CIKMAZ.
  param([string]$yol)
  $klasor = Split-Path -Parent $yol
  $metin  = [IO.File]::ReadAllText($yol,[Text.Encoding]::UTF8)
  $bulunan = @()
  foreach($es in [regex]::Matches($metin,'(?m)^\s*\.\s+.{0,120}?([\w\-]+\.ps1)')){
    $ad = $es.Groups[1].Value
    $tam = Join-Path $klasor $ad
    if((Test-Path $tam) -and ($bulunan -notcontains $tam)){ $bulunan += $tam }
  }
  return $bulunan
}

function OnK_Cakismalar {
  # Verilen betik + yukledigi kutuphaneler icin cakisma listesi dondurur.
  param([string]$yol)
  $bulgu = @()
  $kap = OnK_KapsamAtamalari $yol

  # (a) DOSYA ICI: ayni ad iki farkli yazimla ATANIYOR mu?
  $gruplar = @{}
  foreach($ad in $kap.Keys){
    $anahtar = $ad.ToLowerInvariant()
    if(-not $gruplar.ContainsKey($anahtar)){ $gruplar[$anahtar] = @() }
    $gruplar[$anahtar] += $ad
  }
  foreach($g in $gruplar.GetEnumerator()){
    if(@($g.Value).Count -lt 2){ continue }
    $bulgu += ("dosya-ici: " + (($g.Value | Sort-Object | ForEach-Object { "`$$_" }) -join ' <-> '))
  }

  # (b) DOSYALAR ARASI: yuklenen kutuphanenin globalini bu betik eziyor mu?
  foreach($kut in (OnK_YuklenenKutuphaneler $yol)){
    $kutKap = OnK_KapsamAtamalari $kut
    foreach($g in $kutKap.Keys){
      if($g -cnotmatch '^[A-Z][A-Z0-9_]*$'){ continue }   # yalniz SABIT gorunumlu globaller
      foreach($yerel in $kap.Keys){
        if($yerel -ceq $g){ continue }                                    # ayni yazim: kasitli
        if($yerel.ToLowerInvariant() -ne $g.ToLowerInvariant()){ continue }
        $bulgu += ("kutuphane: `$$g ({0}) <-> `$$yerel (satir {1})" -f (Split-Path -Leaf $kut), (@($kap[$yerel])[0]))
      }
    }
  }
  return $bulgu
}

function OnK_OzSinav {
  # KAPI KENDI SINAVINI GECMELI. Bu fonksiyon iki vaka uretir - biri BOZUK,
  # biri TEMIZ - ve denetleyicinin ikisini de dogru gordugunu kanitlar.
  # 25.08 dersi: ilk nobetci surumunun regex'i 2+ karakter istiyordu, yani
  # aradigi tek harfli $H/$h'yi YAPISAL OLARAK goremiyordu. Kendi sinavi
  # olmasa "motor temiz" derdi ve YALAN olurdu.
  $gecici = Join-Path $env:TEMP ("onk-" + [Guid]::NewGuid().ToString('N').Substring(0,8))
  $null = New-Item -ItemType Directory -Force $gecici
  try {
    $bom = New-Object Text.UTF8Encoding($true)
    [IO.File]::WriteAllText((Join-Path $gecici 'onk-kutuphane.ps1'), "`$H = @{ apikey = 'x' }`r`n", $bom)
    [IO.File]::WriteAllText((Join-Path $gecici 'onk-bozuk.ps1'),
      ". `$PSScriptRoot\onk-kutuphane.ps1`r`nforeach(`$h in @('A','B')){ `$null = `$h }`r`n", $bom)
    [IO.File]::WriteAllText((Join-Path $gecici 'onk-temiz.ps1'),
      ". `$PSScriptRoot\onk-kutuphane.ps1`r`nforeach(`$harf in @('A','B')){ `$null = `$harf }`r`n", $bom)
    $bozuk = @(OnK_Cakismalar (Join-Path $gecici 'onk-bozuk.ps1'))
    $temiz = @(OnK_Cakismalar (Join-Path $gecici 'onk-temiz.ps1'))
    if($bozuk.Count -lt 1){ return "OZ-SINAV DUSTU: bilinen-bozuk vaka YAKALANMADI" }
    if($temiz.Count -gt 0){ return "OZ-SINAV DUSTU: bilinen-temiz vaka YANLIS isaretlendi -> $($temiz -join '; ')" }
    return ''
  } finally { Remove-Item $gecici -Recurse -Force -ErrorAction SilentlyContinue }
}

function HatOnKontrol {
  # Uretim betiginin basinda cagrilir. Cakisma varsa betik HIC BASLAMAZ.
  # -uyar ile yalniz uyarir (eski betikleri kirmadan devreye almak icin).
  param([string]$betikYolu, [switch]$uyar)
  if(-not $betikYolu -or -not (Test-Path $betikYolu)){ return }

  $sinav = OnK_OzSinav
  if($sinav){
    Write-Host ''
    Write-Host "  !! HAT ON KONTROLU KENDI SINAVINDAN DUSTU: $sinav" -ForegroundColor Red
    Write-Host '     Goremedigi seyi ariyor - bu denetim GUVENILMEZ, kosu durduruldu.'
    exit 1
  }

  $cakisma = @(OnK_Cakismalar $betikYolu)
  if($cakisma.Count -eq 0){ return }

  Write-Host ''
  Write-Host ("  !! DEGISKEN CAKISMASI — {0}" -f (Split-Path -Leaf $betikYolu)) -ForegroundColor Red
  foreach($c in $cakisma){ Write-Host "     $c" }
  Write-Host '     PowerShell buyuk/kucuk harf ayirmaz: bunlar AYNI degiskendir.'
  Write-Host '     Bu sinif hata HATA VERMEZ - sessizce yanlis sonuc uretir.'
  if($uyar){ Write-Host '     (-uyar acik: kosu devam ediyor, ama ciktiya GUVENME.)'; return }
  Write-Host '     Kosu durduruldu. Kirli olcum uretmektense hic olcmemek yeglenir.'
  exit 1
}