# ============================================================================
#  REBRAND MOTORU — MR / Mevzuat Radarı -> TETİKTE (görev #56)
#  KULLANIM:
#    .\motor\rebrand.ps1            -> DENEME (dry-run): ne değişecek, dosya dosya sayar, DOKUNMAZ
#    .\motor\rebrand.ps1 -Uygula    -> gerçekten değiştirir
#  KAPSAM: kök *.html + menu.js + motor/*.ps1 (kart robot şablonları)
#  DOKUNULMAYANLAR:
#    - tetikte-marka.html (marka tarihçesi — "Mevzuat Radarı" bilinçli geçer, elle bakılır)
#    - arsiv/ (tarihî kart arşivi — geçmiş değiştirilmez)
#    - veri/ (marka geçmiyor, 23.07 taramasıyla teyitli)
#    - GitHub repo adı/URL'leri (cemdizdar85-arch/mevzuat-radar KALIR — kod deposu adı, marka değil)
#  ENVANTER (23.07 taraması): 'Mevzuat Radarı' x104 + ASCII 'Mevzuat Radari' x19;
#  ÇEKİMLİ HAL YOK (Radarı'nın vb. sıfır) -> düz değiştirme güvenli.
#  ENCODING: html/js UTF-8 BOM'suz; ps1 UTF-8 BOM'LU (PS5.1 Türkçe yol dersi).
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $kok

$HARIC = @('tetikte-marka.html','rebrand.ps1')   # kendisi de hariç: içindeki kurallar bozulmasın

# SIRALI kurallar: uzun desen önce (kısa desen uzunun parçasını bozmasın)
$kurallar = @(
  @{ eski="Mevzuat Radarı"; yeni="Tetikte" },
  @{ eski="Mevzuat Radari"; yeni="Tetikte" },
  @{ eski='class="logo">MR<'; yeni='class="logo">T<' }   # üst bar rozeti: MR -> T (Radar-i logosu favicon'da yaşıyor)
)

$dosyalar = @(Get-ChildItem (Join-Path $kok '*.html')) + @(Get-Item (Join-Path $kok 'menu.js')) + @(Get-ChildItem (Join-Path $kok 'motor\*.ps1'))
$dosyalar = $dosyalar | Where-Object { $HARIC -notcontains $_.Name }

$toplamDegisen = 0; $toplamDosya = 0
foreach($f in $dosyalar){
  $t = Get-Content $f.FullName -Raw -Encoding UTF8
  $yeniT = $t; $sayilar = @()
  foreach($k in $kurallar){
    $n = ([regex]::Matches($yeniT, [regex]::Escape($k.eski))).Count
    if($n -gt 0){ $sayilar += "'$($k.eski)' x$n"; $yeniT = $yeniT.Replace($k.eski, $k.yeni) }
  }
  if($yeniT -ne $t){
    $toplamDosya++; $toplamDegisen += ($sayilar | ForEach-Object { [int]($_ -replace '.*x','') } | Measure-Object -Sum).Sum
    Write-Host ("{0}: {1}" -f $f.Name, ($sayilar -join ', '))
    if($Uygula){
      # ps1 dosyaları BOM'LU yazılır (PS5.1 Türkçe karakter dersi); html/js BOM'suz
      $bom = $f.Extension -eq '.ps1'
      [IO.File]::WriteAllText($f.FullName, $yeniT, (New-Object System.Text.UTF8Encoding($bom)))
    }
  }
}
Write-Host ""
Write-Host ("{0}: {1} dosyada {2} değişiklik" -f $(if($Uygula){"UYGULANDI"}else{"DENEME (dokunulmadı)"}), $toplamDosya, $toplamDegisen)

# Kalıntı taraması: değiştirme sonrası hâlâ 'Mevzuat Radar' geçen yer var mı?
if($Uygula){
  Write-Host ""
  Write-Host "== KALINTI TARAMASI (elle bakılacaklar):"
  foreach($f in $dosyalar){
    $n = (Select-String -Path $f.FullName -Pattern 'Mevzuat Radar' -Encoding UTF8 | Measure-Object).Count
    if($n -gt 0){ Write-Host ("  {0}: {1} kalıntı" -f $f.Name, $n) }
  }
  Write-Host "  (tetikte-marka.html bilinçli hariç — elle gözden geçir)"
  Write-Host ""
  Write-Host "SONRAKİ ADIMLAR: (1) index.html başlık/hero elle oku; (2) yerel önizleme ile 5-6 sayfa gez;"
  Write-Host "(3) title etiketleri anlamlı mı kontrol; (4) commit + push; (5) kartlar robotunun ilk yeni üretimini dogrula."
}
exit 0
