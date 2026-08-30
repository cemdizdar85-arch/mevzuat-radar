# ============================================================================
#  YUTMA KAPISI — cagri kartlari SESSIZCE bosalamaz  (30.08.2026)
#
#  CEM (30.08): "yutma karnesini CI kapisina baglayalim ki kurum sayfasi
#  degisince kartlar sessizce bosalmasin."
#
#  NEDEN GEREKLI (olculen vaka):
#  motor/cagri-hasat.ps1 cagri sayfalarindan ozet/kim/tutar/asama CIKARIR.
#  Cikarma DESEN tabanlidir. Kurum sayfasini yeniden tasarlarsa desen tutmaz -
#  ama betik HATA VERMEZ: 133 cagriyi yine yazar, yalniz alanlari BOS olur.
#  Kart o zaman eskisi gibi "Cagri duyurusunda" der ve kimse fark etmez.
#  Yesil kosu != tam veri: kac kayit yazildigi degil, kac kayit BILGI TASIDIGI
#  olculmelidir.
#
#  IKI KURAL (ikisi de ONCEKI SURUMLE kiyaslanir, mutlak esik degil - mutlak
#  esik kaynak dagilimi degisince yalan soyler):
#    1) COKUS   : bir kaynakta bilgi tasiyan kayit orani onceki surume gore
#                 CIGIR_DUSUS puandan fazla dustuyse -> KIRMIZI
#    2) KORLESME: onceki surumde bilgi ureten bir kaynak artik HIC uretmiyorsa
#                 -> KIRMIZI (desen tamamen kirilmis demektir)
#  Kaynak ONCEKI surumde de yoksa kiyas yapilmaz (yeni kaynak cezalandirilmaz).
#
#  KAPI NEDEN DUSTUGUNU SOYLER (kalici sigorta 4. katman): her kosuda
#  veri/yutma-kapisi-log.txt yazilir - YESIL de olsa. "Kirmizi ama sebebi yok"
#  diye bir sey olmaz.
#
#  KULLANIM:
#    powershell -NoProfile -File arac/yutma-kapisi.ps1
#    ... -Onceki <ref>     kiyas referansi (varsayilan HEAD)
#    ... -Deneme           rapor yazar, cikis kodu her zaman 0
#
#  CIKIS: 0 gecti (ya da kiyas yapilamadi - kor kalmiyoruz, log soyler)
#         1 en az bir kaynakta cokus/korlesme var
# ============================================================================
param(
  [string]$Onceki = "HEAD",
  [switch]$Deneme,
  # 30.08: esigi GERIYE DONUK olcebilmek icin. Kapiyi gecmis surum ciftleriyle
  # kosturup "bu esik gecmiste kac kez bosuna kirmizi yanardi" sorusunu bugun
  # cevaplayabiliyoruz - bir sabah beklemeye gerek kalmiyor.
  [string]$Hedef = "",
  # Log'a yazma (geriye donuk tarama canli log'u kirletmesin)
  [switch]$LogYazma
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$hedef = if($Hedef){ $Hedef } else { Join-Path $kok "veri\cagri-radar.json" }
$logYolu = Join-Path $kok "veri\yutma-kapisi-log.txt"

# bir kaynakta bilgi tasiyan kayit orani bu kadar PUAN duserse kirmizi
$CIGIR_DUSUS = 30
# altinda kiyas yapilmayan kayit sayisi (3 kayitlik kaynakta 1 kayip %33'tur -
# gurultuyu kirmizi saymayiz; TKDK/HAMLE gibi tek ilanli kaynaklar boyle)
$EN_AZ_KAYIT = 5

$satirlar = New-Object Collections.Generic.List[string]
function Not([string]$m){ $satirlar.Add($m); Write-Host $m }

function DolulukOrani($kayitlar){
  # bir kaynakta "bilgi tasiyan" = ozet/kim/tutar'dan EN AZ BIRI dolu
  $n = @($kayitlar).Count
  if($n -eq 0){ return $null }
  $dolu = @($kayitlar | Where-Object {
    "$($_.ozet)".Trim() -or "$($_.kim)".Trim() -or "$($_.tutar)".Trim() }).Count
  return [Math]::Round(100.0 * $dolu / $n, 1)
}
function KaynakHarita($cagrilar){
  $h = @{}
  foreach($g in ($cagrilar | Group-Object kaynak)){
    $h[$g.Name] = [pscustomobject]@{ adet = @($g.Group).Count; oran = (DolulukOrani $g.Group) }
  }
  return $h
}

Not ("YUTMA KAPISI - " + (Get-Date -Format "dd.MM.yyyy HH:mm"))

if(-not (Test-Path $hedef)){
  Not "  ATLANDI: veri/cagri-radar.json yok - denetlenecek bir sey yok."
  if(-not $LogYazma){ [IO.File]::WriteAllText($logYolu, ($satirlar -join "`r`n"), [Text.UTF8Encoding]::new($false)) }
  exit 0
}

$yeni = $null
try { $yeni = (Get-Content $hedef -Raw -Encoding UTF8) | ConvertFrom-Json }
catch { Not ("  KIRMIZI: cagri-radar.json COZULEMEDI - " + $_.Exception.Message)
        if(-not $LogYazma){ [IO.File]::WriteAllText($logYolu, ($satirlar -join "`r`n"), [Text.UTF8Encoding]::new($false)) }
        exit 1 }

$yeniHarita = KaynakHarita @($yeni.cagrilar)
$genelOran  = DolulukOrani @($yeni.cagrilar)
Not ("  simdi : " + @($yeni.cagrilar).Count + " cagri, bilgi tasiyan %" + $genelOran)

# --- onceki surum -----------------------------------------------------------
$eskiHam = ""
try { $eskiHam = (git -C $kok show "${Onceki}:veri/cagri-radar.json" 2>$null) -join "`n" } catch {}
if(-not $eskiHam){
  # Kor kalma kurali: kiyas yapamadigimizi SOYLERIZ, "gecti" diye yutmayiz.
  Not "  KIYAS YAPILAMADI: onceki surum okunamadi ($Onceki). Kapi bu kosuda OLCMEDI."
  if(-not $LogYazma){ [IO.File]::WriteAllText($logYolu, ($satirlar -join "`r`n"), [Text.UTF8Encoding]::new($false)) }
  exit 0
}
$eski = $null
try { $eski = $eskiHam | ConvertFrom-Json } catch {}
if(-not $eski){
  Not "  KIYAS YAPILAMADI: onceki surum cozulemedi. Kapi bu kosuda OLCMEDI."
  if(-not $LogYazma){ [IO.File]::WriteAllText($logYolu, ($satirlar -join "`r`n"), [Text.UTF8Encoding]::new($false)) }
  exit 0
}
$eskiHarita = KaynakHarita @($eski.cagrilar)
Not ("  onceki: " + @($eski.cagrilar).Count + " cagri, bilgi tasiyan %" + (DolulukOrani @($eski.cagrilar)))

# --- kaynak kaynak kiyas ----------------------------------------------------
$kirmizi = @()
foreach($ad in ($yeniHarita.Keys | Sort-Object)){
  $y = $yeniHarita[$ad]
  if(-not $eskiHarita.ContainsKey($ad)){
    Not ("  - {0}: YENI kaynak (%{1}) - kiyas yok, gecti" -f $ad, $y.oran)
    continue
  }
  $e = $eskiHarita[$ad]
  $fark = [Math]::Round($y.oran - $e.oran, 1)
  $az = ($y.adet -lt $EN_AZ_KAYIT -and $e.adet -lt $EN_AZ_KAYIT)
  $durum = "gecti"
  if($e.oran -gt 0 -and $y.oran -eq 0){
    # KORLESME: bilgi ureten kaynak artik hic uretmiyor. Kayit sayisi az olsa
    # bile bu desen kirilmasidir - sessiz gecilmez.
    $durum = "KIRMIZI (korlesme)"
    $kirmizi += ("{0}: onceki %{1} -> simdi %0. Desen tamamen kirilmis olabilir; kurum sayfasi degismis mi bak." -f $ad, $e.oran)
  }
  elseif($fark -le (-1 * $CIGIR_DUSUS) -and -not $az){
    $durum = "KIRMIZI (cokus)"
    $kirmizi += ("{0}: %{1} -> %{2} ({3} puan dustu). Kaynak sayfasi degismis olabilir." -f $ad, $e.oran, $y.oran, $fark)
  }
  elseif($az -and $fark -le (-1 * $CIGIR_DUSUS)){
    $durum = "uyari (az kayit, kirmizi sayilmadi)"
  }
  Not ("  - {0}: %{1} -> %{2} ({3:+0.0;-0.0;0}) [{4} kayit] {5}" -f $ad, $e.oran, $y.oran, $fark, $y.adet, $durum)
}

# onceki surumde olup simdi HIC OLMAYAN kaynak: hasat tarafinin isi (kaynak
# durum damgasi soyluyor), burada yalniz not dusuyoruz.
foreach($ad in $eskiHarita.Keys){
  if(-not $yeniHarita.ContainsKey($ad)){ Not ("  - {0}: bu kosuda hic kayit uretmedi (kaynak damgasina bak)" -f $ad) }
}

if($kirmizi.Count){
  Not ""
  Not ("KIRMIZI - {0} kaynakta yutma coktu:" -f $kirmizi.Count)
  foreach($k in $kirmizi){ Not ("   * " + $k) }
  Not "Ne yapmali: motor/cagri-hasat.ps1 -YerelYut ile onbellekten yeniden yut"
  Not "(kuruma gidilmez, saniyeler surer), desen tutmuyorsa kaynak sayfasini ac."
} else {
  Not ""
  Not "YESIL - hicbir kaynakta cokus/korlesme yok."
}
if(-not $LogYazma){
  [IO.File]::WriteAllText($logYolu, ($satirlar -join "`r`n"), [Text.UTF8Encoding]::new($false))
  Write-Host ("  -> " + $logYolu)
}

if($kirmizi.Count -and -not $Deneme){ exit 1 }
exit 0
