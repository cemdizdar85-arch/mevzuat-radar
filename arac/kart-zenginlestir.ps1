# ============================================================================
#  KART ZENGINLESTIRME  (17.08.2026 — Cem: "RG'yi ayrintisina kadar okuyup
#  'bak bu' demiyoruz; eski yeni karsilastirmasi iyi degil")
#
#  NE YAPAR: motor/kartlar/<gun>/kartlar.json icindeki ESKI kartlari, arsivdeki
#  RG metninden DETERMINISTIK olarak cikarilan yapiyla zenginlestirir.
#    - teblig_no          (kartlar tebligin kendi numarasini hic soylemiyordu)
#    - degisen_maddeler   ("yeni maddelerle" yerine 4/A, 6/A, 6/B...)
#    - yururluk           yer tutucu ("kaynak tebligdeki maddeye bakin") yerine
#                         gercek tarih; bolunmus yururluk bent bent
#    - eski_yeni          "X ibaresi Y seklinde degistirilmistir" ciftleri
#
#  NEDEN 0 USD: bilginin tamami zaten indirilmis RG metninde. Model cagrilmaz.
#  Kartlari yeniden URETMEK (API) ayri bir karar; bu betik ONU YAPMAZ.
#
#  KURAL: varsayilan OLCUM. Yazmak icin -Uygula. Yazmadan once yedek alinir,
#  yazdiktan sonra GERI OKUNUP karsilastirilir (yaz -> geri oku -> karsilastir).
#
#  Kullanim:
#    .\arac\kart-zenginlestir.ps1              # olcum
#    .\arac\kart-zenginlestir.ps1 -Uygula      # yaz
#    .\arac\kart-zenginlestir.ps1 -Gun 01-08-2026 -Uygula
# ============================================================================
param([switch]$Uygula, [string]$Gun)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
. (Join-Path $kok 'motor\teblig-yapi.ps1')

function YerTutucuMu([string]$s){
  if(-not "$s".Trim()){ return $true }
  $n = "$s".ToLowerInvariant()
  return ($n -match 'kaynak teblig|kaynak tebliğ|bakın|bakin|bakınız|bakiniz|ilgili madde|maddesine bak|belirtilmemis|belirtilmemiş')
}

$kartDir = Join-Path $kok 'motor\kartlar'
$arsivDir = Join-Path $kok 'motor\arsiv'
if(-not (Test-Path $kartDir)){ Write-Host "Kart klasoru yok."; exit 0 }

$gunler = @(Get-ChildItem $kartDir -Directory | Sort-Object Name)
if($Gun){ $gunler = @($gunler | Where-Object { $_.Name -eq $Gun }) }

$sayac = [ordered]@{
  gun=0; kart=0; dokunulan=0
  teblig_no=0; degisen_maddeler=0; yururluk_duzeltilen=0; yururluk_bolunmus=0; eski_yeni=0
  kaynak_yok=0; yapi_bos=0
}
$ornekler = New-Object System.Collections.Generic.List[string]

foreach($g in $gunler){
  $jy = Join-Path $g.FullName 'kartlar.json'
  if(-not (Test-Path $jy)){ continue }
  $ham = Get-Content $jy -Raw -Encoding UTF8
  if([string]::IsNullOrWhiteSpace($ham)){ continue }
  # PS 5.1 TUZAGI: @($ham | ConvertFrom-Json) diziyi TEK ELEMAN sayar
  # (boru hattindan cikan dizi @() icinde tek oge olur) -> $k bir kart degil
  # kart DIZISI olur ve $k.dosya Object[] doner. Once ATA, sonra SAR.
  $cozulen = $null
  try { $cozulen = $ham | ConvertFrom-Json } catch { Write-Host ("  {0}: JSON okunamadi - atlandi" -f $g.Name) -ForegroundColor Yellow; continue }
  $kartlar = @($cozulen)
  if(-not $kartlar.Count){ continue }
  $sayac.gun++
  $gunDegisti = $false

  foreach($k in $kartlar){
    $sayac.kart++
    if(-not $k.dosya){ $sayac.kaynak_yok++; continue }
    $htm = Join-Path (Join-Path $arsivDir $g.Name) $k.dosya
    if(-not (Test-Path $htm)){ $sayac.kaynak_yok++; continue }

    $yapi = $null
    try { $yapi = TebligYapiCikar $htm } catch { $sayac.yapi_bos++; continue }
    if(-not $yapi){ $sayac.yapi_bos++; continue }

    $kartDegisti = $false

    # --- teblig no ---
    if($yapi.teblig_no -and -not $k.teblig_no){
      Add-Member -InputObject $k -NotePropertyName 'teblig_no' -NotePropertyValue $yapi.teblig_no -Force
      $sayac.teblig_no++; $kartDegisti = $true
    }

    # --- degisen maddeler ---
    $dm = @(
      @($yapi.eklenen    | ForEach-Object { "$($_.madde) eklendi" }) +
      @($yapi.kaldirilan | ForEach-Object { "$($_.madde) yürürlükten kaldırıldı" }) +
      @($yapi.degisen    | ForEach-Object { "$($_.madde) baştan yazıldı" })
    ) | Where-Object { "$_".Trim() }
    # @($k.degisen_maddeler).Count alan YOKKEN 1 doner (@($null) tek elemanli
    # dizidir) -> "zaten var" sanilip hicbir kart zenginlesmiyordu. SUZ, sonra say.
    $mevcutDm = @($k.degisen_maddeler | Where-Object { "$_".Trim() })
    if($dm.Count -and -not $mevcutDm.Count){
      Add-Member -InputObject $k -NotePropertyName 'degisen_maddeler' -NotePropertyValue @($dm) -Force
      $sayac.degisen_maddeler++; $kartDegisti = $true
    }

    # --- yururluk (yalnizca YER TUTUCU/BOS ise dokunulur; dolu ve saglam
    #     olani EZMEYIZ - insan gozuyle onaylanmis olabilir) ---
    $bentler = @($yapi.yururluk | Where-Object { $_.tarih })
    if($bentler.Count -and (YerTutucuMu $k.yururluk)){
      $yeni = if($bentler.Count -eq 1 -and -not $bentler[0].bent){ $bentler[0].tarih }
              else { (($bentler | ForEach-Object { "$($_.kapsam): $($_.tarih)" }) -join ' · ') }
      $eski = "$($k.yururluk)"
      $k.yururluk = $yeni
      $sayac.yururluk_duzeltilen++; $kartDegisti = $true
      if($bentler.Count -gt 1){ $sayac.yururluk_bolunmus++ }
      if($ornekler.Count -lt 8){ $ornekler.Add(("[{0}] YURURLUK: '{1}'  ->  '{2}'" -f $g.Name, $eski, $yeni)) }
    }

    # --- eski -> yeni (deterministik satirlar basa) ---
    if(@($yapi.ibare).Count){
      $mevcut = @($k.eski_yeni | Where-Object { $_ -and $_.eski -and $_.yeni })
      $anahtar = @{}
      foreach($m in $mevcut){ $anahtar[("$($m.eski)>$($m.yeni)").ToLowerInvariant()] = $m }
      # Onceki kosuda eklenmis ama 'kaynak' isareti tasimayan satirlari damgala:
      # etiket ("metinden birebir" mi "cift okumayla" mi) buna bakiyor.
      $metinAnahtar = @{}
      foreach($ib in @($yapi.ibare)){ $metinAnahtar[("$($ib.eski)>$($ib.yeni)").ToLowerInvariant()] = $true }
      foreach($m in $mevcut){
        $a = ("$($m.eski)>$($m.yeni)").ToLowerInvariant()
        if($metinAnahtar.ContainsKey($a) -and -not $m.kaynak){
          Add-Member -InputObject $m -NotePropertyName 'kaynak' -NotePropertyValue 'metin' -Force
          $kartDegisti = $true
        }
      }
      $ekle = @()
      foreach($ib in @($yapi.ibare)){
        $a = ("$($ib.eski)>$($ib.yeni)").ToLowerInvariant()
        if($anahtar.ContainsKey($a)){ continue }
        # kaynak='metin': kart etiketi "cift okumayla dogrulanmis" DEMESIN diye
        $ekle += [pscustomobject]@{ konu=$ib.konu; eski=$ib.eski; yeni=$ib.yeni; kaynak='metin' }
      }
      if($ekle.Count){
        $k.eski_yeni = @($ekle) + @($mevcut)
        $sayac.eski_yeni += $ekle.Count; $kartDegisti = $true
        if($ornekler.Count -lt 8){ foreach($e in $ekle){ if($ornekler.Count -lt 8){ $ornekler.Add(("[{0}] ESKI->YENI: {1}  ->  {2}" -f $g.Name, $e.eski, $e.yeni)) } } }
      }
    }

    if($kartDegisti){ $sayac.dokunulan++; $gunDegisti = $true }
  }

  if($gunDegisti -and $Uygula){
    $yedek = $jy + '.yedek-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item $jy $yedek
    $cikti = if($kartlar.Count -eq 1){ ConvertTo-Json $kartlar[0] -Depth 12 } else { ConvertTo-Json @($kartlar) -Depth 12 }
    [IO.File]::WriteAllText($jy, $cikti, (New-Object Text.UTF8Encoding($false)))
    # YAZ -> GERI OKU -> KARSILASTIR
    # Burada da ONCE ATA SONRA SAR: @(... | ConvertFrom-Json) coklu kartli gunu
    # TEK eleman sayiyordu, sayim tutmuyordu ve dogru yazilmis 43 gun bosuna
    # geri alindi. (Ag calisti, veri bozulmadi - ama kapinin kendisi hataliydi.)
    $geriHam = $null
    try { $geriHam = (Get-Content $jy -Raw -Encoding UTF8) | ConvertFrom-Json } catch {}
    $geri = @($geriHam)
    if(-not $geri.Count -or $geri.Count -ne $kartlar.Count){
      Write-Host ("  {0}: GERI OKUMA TUTMADI - yedekten geri alindi" -f $g.Name) -ForegroundColor Red
      Copy-Item $yedek $jy -Force
    }
  }
}

Write-Host "======== KART ZENGINLESTIRME ========" -ForegroundColor Cyan
Write-Host ("  taranan gun / kart          : {0} / {1}" -f $sayac.gun, $sayac.kart)
Write-Host ("  dokunulan kart              : {0}" -f $sayac.dokunulan)
Write-Host ""
Write-Host ("  teblig no eklendi           : {0}" -f $sayac.teblig_no)
Write-Host ("  degisen madde listesi       : {0}" -f $sayac.degisen_maddeler)
Write-Host ("  YURURLUK yer tutucu -> tarih: {0}   (bunlarin {1} tanesi BOLUNMUS yururluk)" -f $sayac.yururluk_duzeltilen, $sayac.yururluk_bolunmus)
Write-Host ("  ESKI->YENI satiri eklendi   : {0}" -f $sayac.eski_yeni)
Write-Host ""
Write-Host ("  kaynak htm bulunamadi       : {0}" -f $sayac.kaynak_yok)
Write-Host ("  yapi cikarilamadi           : {0}" -f $sayac.yapi_bos)
if($ornekler.Count){
  Write-Host ""
  Write-Host "  --- ornekler ---" -ForegroundColor Green
  foreach($o in $ornekler){ Write-Host "     $o" }
}
Write-Host ""
if($Uygula){ Write-Host "  YAZILDI (yedekler kartlar.json.yedek-* olarak duruyor)." -ForegroundColor Green }
else { Write-Host "  OLCUM MODU - hicbir sey yazilmadi. Yazmak icin: -Uygula" -ForegroundColor Yellow }
