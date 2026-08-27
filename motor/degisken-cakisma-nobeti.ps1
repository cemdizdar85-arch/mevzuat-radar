# ============================================================================
#  DEĞİŞKEN ÇAKIŞMASI NÖBETÇİSİ — 25.08.2026
#
#  NEDEN VAR: PowerShell degisken adlarinda BUYUK/KUCUK HARF AYIRMAZ.
#  $KOK ile $kok AYNI degiskendir. Bu tuzak bu depoda 25.08'de TEK GUNDE
#  DORT KEZ vurdu ve dordunde de SESSIZCE YANLIS SONUC uretti:
#
#    1) madde-coz.ps1'in $H (kimlik basligi) ile foreach($h in $HARFLER)
#       -> ambar sorgulari kimliksiz gitti, 401 dondu, cozucu her maddeye
#          "ambarda yok" dedi. 20 sorunun 18'i yargilanamadi.
#    2) uyum2.ps1'de ayni tuzak -> sik-aciklama kapisi 1.302 kusuru
#          "0" diye raporladi.
#    3) konu-karti.ps1'de $ISTEM (sablon) ile $istem (kurulan istem)
#       -> istem kendi uzerine katlandi; bes kartin dordu YANLIS KONUDA
#          yazildi ve giris jetonu IKI KAT odendi.
#    4) kart-kontrol.ps1'de ayni sey -> kart kapi sonuclari kirlendi,
#          verilen butun bulgular gecersizdi.
#
#  Ayrica tarama 7 betikte daha ayni deseni buldu; ikisi FIILEN BOZUKTU
#  ($kok depo klasoru, $KOK Supabase adresi -> dosya yolu adres oldu).
#
#  HICBIRI HATA VERMEDI. Hepsi "makul gorunen yanlis cikti" uretti.
#  Bu yuzden bu nobetci var: kod incelemesi degil, MAKINE denetimi.
#
#  KURAL: bir betikte hem $ADI hem $adi ATANIYORSA kirmizidir.
#  Dongu degiskeni ($h, $i, $k) ile sabit ($H, $I, $K) en sik carpisan cift.
#
#  Cikti: veri/degisken-cakisma-raporu.json   ·   0 USD, model yok
#  Kirmizi varsa CIKIS KODU 1 (CI'da hattı durdurur).
# ============================================================================
param([string]$klasor = '', [switch]$sessiz)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $klasor){ $klasor = $here }

# ---------------------------------------------------------------- KAPSAM
# 25.08 IKINCI DERS: ilk surum METIN DESENIYLE ariyordu ve FONKSIYON ICINI de
# sayiyordu. Oysa fonksiyon icindeki degisken YERELDIR, disaridakini EZMEZ.
# profesor-v2.ps1 boyle YALANCI BAYRAK aldi: $H fonksiyon icinde, $h baska
# fonksiyon icinde - hicbiri otekini ezmiyor. 25 bulgunun cogu bu sinifti.
# Cozum: PowerShell'in KENDI cozumleyicisini kullan, yalniz BETIK KAPSAMINDAKI
# atamalari say. Desen tahmin eder; cozumleyici BILIR.
function BetikKapsamiAtamalari([string]$yol){
  $hataList = $null
  $agac = [Management.Automation.Language.Parser]::ParseFile($yol, [ref]$null, [ref]$hataList)
  if($null -eq $agac){ return @{} }
  $sonuc = @{}   # tamYazim -> @(satir)
  # Fonksiyon govdeleri HARIC: onlarin ici yerel kapsamdir
  $fonksiyonlar = $agac.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $true)
  function IcindeMi($nokta,$fonlar){
    foreach($f in $fonlar){
      if($nokta -ge $f.Extent.StartOffset -and $nokta -lt $f.Extent.EndOffset){ return $true }
    }
    return $false
  }
  # 1) atamalar:  $ad = ...
  foreach($a in $agac.FindAll({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] }, $true)){
    $sol = $a.Left
    if($sol -isnot [Management.Automation.Language.VariableExpressionAst]){ continue }
    if(IcindeMi $a.Extent.StartOffset $fonksiyonlar){ continue }
    $ad = $sol.VariablePath.UserPath
    if($ad -match '[:.]'){ continue }                       # $script:x, $env:x atlanir
    if(-not $sonuc.ContainsKey($ad)){ $sonuc[$ad]=@() }
    $sonuc[$ad] += $a.Extent.StartLineNumber
  }
  # 2) foreach dongu degiskeni de atamadir
  foreach($a in $agac.FindAll({ param($n) $n -is [Management.Automation.Language.ForEachStatementAst] }, $true)){
    if(IcindeMi $a.Extent.StartOffset $fonksiyonlar){ continue }
    $ad = $a.Variable.VariablePath.UserPath
    if($ad -match '[:.]'){ continue }
    if(-not $sonuc.ContainsKey($ad)){ $sonuc[$ad]=@() }
    $sonuc[$ad] += $a.Extent.StartLineNumber
  }
  return $sonuc
}

$bulgular = New-Object System.Collections.Generic.List[object]
$tarananDosya = 0

# ---------------------------------------------------------------- KUTUPHANE
# 25.08 DERSI: ilk surum YALNIZ DOSYA ICI cakismaya bakiyordu ve bugunku bes
# vakanin UCUNU KACIRACAKTI. Cunku en tehlikeli cakisma DOSYALAR ARASI:
# madde-coz.ps1 kimlik basligini $H adli GLOBAL'de tutuyor; onu nokta ile
# yukleyen her betikte `foreach($h in ...)` yazmak o kimligi SILIYOR ve
# ambar sorgulari 401 dondurmeye basliyor. Hicbir hata cikmiyor - cozucu
# sadece "bu madde ambarda yok" demeye basliyor.
# Bu yuzden nobetci once KUTUPHANELERIN global adlarini toplar, sonra o
# kutuphaneyi yukleyen her betikte ayni adin baska yazimini arar.
$RX_NOKTA = [regex]'(?m)^\s*\.\s+\(?\s*Join-Path\s+\$\w+\s+''([^'']+)''|(?m)^\s*\.\s+"?\$here\\([\w\-]+\.ps1)'
$kutuphaneGlobal = @{}   # dosyaAdi -> @(global adlar)
$kapsamOnbellek = @{}
foreach($f in (Get-ChildItem $klasor -Filter *.ps1 -File)){
  $kap = BetikKapsamiAtamalari $f.FullName
  $kapsamOnbellek[$f.Name] = $kap
  $adlar = @()
  foreach($ad in $kap.Keys){
    if($ad -cmatch '^[A-Z][A-Z0-9_]*$' -and $adlar -notcontains $ad){ $adlar += $ad }
  }
  if($adlar.Count){ $kutuphaneGlobal[$f.Name] = $adlar }
}

foreach($f in (Get-ChildItem $klasor -Filter *.ps1 -File | Sort-Object Name)){
  $tarananDosya++
  $metin = [IO.File]::ReadAllText($f.FullName,[Text.Encoding]::UTF8)
  # ad -> o adin gorulen TAM YAZIMLARI + satir numaralari
  $kap = $kapsamOnbellek[$f.Name]
  $yazimlar = @{}
  foreach($ad in $kap.Keys){
    $anahtar = $ad.ToLowerInvariant()
    if(-not $yazimlar.ContainsKey($anahtar)){ $yazimlar[$anahtar] = @{} }
    $yazimlar[$anahtar][$ad] = @($kap[$ad])
  }
  foreach($e in $yazimlar.GetEnumerator()){
    if($e.Value.Keys.Count -lt 2){ continue }   # tek yazim -> sorun yok
    $detay = @()
    foreach($y in ($e.Value.GetEnumerator() | Sort-Object Name)){
      $detay += ("`${0} (satir {1})" -f $y.Key, (($y.Value | Select-Object -First 3) -join ','))
    }
    $bulgular.Add([ordered]@{
      dosya = $f.Name
      tur   = 'dosya-ici'
      ad    = $e.Key
      yazimlar = ($detay -join '  <->  ')
    })
  }

  # --- DOSYALAR ARASI: bu betik hangi kutuphaneleri nokta ile yukluyor?
  foreach($ky in $kutuphaneGlobal.Keys){
    if($f.Name -eq $ky){ continue }
    $ad0 = [IO.Path]::GetFileNameWithoutExtension($ky)
    if($metin -notmatch ('(?m)^\s*\.\s+.{0,80}' + [regex]::Escape($ad0))){ continue }
    foreach($g in $kutuphaneGlobal[$ky]){
      # bu betikte AYNI adin FARKLI yazimla ATANDIGI yer var mi?
      foreach($yerel in $kap.Keys){
          if($yerel -ceq $g){ continue }                     # ayni yazim - kasitli
          if($yerel.ToLowerInvariant() -ne $g.ToLowerInvariant()){ continue }
          $satir = @($kap[$yerel])[0]
          $bulgular.Add([ordered]@{
            dosya = $f.Name
            tur   = 'DOSYALAR-ARASI'
            ad    = $g
            yazimlar = ("`${0} ({1} kutuphanesinin globali)  <->  `${2} (satir {3})" -f $g,$ky,$yerel,$satir)
          })
      }
    }
  }
}

if(-not $sessiz){
  Write-Host ("Taranan betik: {0}" -f $tarananDosya)
  Write-Host ''
  if($bulgular.Count){
    Write-Host ("KIRMIZI — {0} cakisma bulundu:" -f $bulgular.Count)
    foreach($b in $bulgular){ Write-Host ("  {0,-30} {1}" -f $b.dosya,$b.yazimlar) }
    Write-Host ''
    Write-Host 'PowerShell buyuk/kucuk harf ayirmaz: bunlar AYNI degiskendir.'
    Write-Host 'Sabitlere acik ad verin ($KOK degil $API_ADRES), dongu degiskenini kisa birakin.'
  } else {
    Write-Host 'TEMIZ — hicbir betikte buyuk/kucuk harf cakismasi yok.'
  }
}

$duz=@(); foreach($b in $bulgular){ $duz += ,([pscustomobject]$b) }
[IO.File]::WriteAllText((Join-Path $kok 'veri/degisken-cakisma-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); klasor=$klasor
    taranan=$tarananDosya; cakisma=$duz.Count; bulgular=$duz
  }) -Depth 6), (New-Object Text.UTF8Encoding($false)))
if(-not $sessiz){ Write-Host '-> veri/degisken-cakisma-raporu.json' }
if($bulgular.Count){ exit 1 } else { exit 0 }
