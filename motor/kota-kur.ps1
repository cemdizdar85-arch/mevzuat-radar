# ============================================================================
#  KOTA KURUCU — 29.07.2026   (PARA HARCAMAZ)
#
#  12 donemlik gercek TESMER verisinden URETIM RECETESI cikarir.
#  Cikti: veri/uretim-kotasi.json  — uretici bunu okuyup soru yazar.
#
#  UC OLCU, UCU DE OLCULDU:
#   1) DERS   : Yeterlilikte 8 ders ESIT. Her ders ayri kapi - birinden 50
#               alamayan geciyor degil. Agirliklandirmak matematiksel olarak
#               yanlis olurdu.
#   2) KONU   : 883 tekil konu. Agirlik = konunun KAC DONEMDE gorundugu.
#               Bu olcu formattan bagimsizdir (yazili bir soru genis konu
#               kapsar, test sorusu dar; ham sayi yaniltir).
#   3) KURGU  : 480 gercek test sorusundan olculdu ve SURPRIZ CIKTI -
#               Yeterlilik %71 DUZ BILGI soruyor, vaka degil. Ustelik ders
#               ders bambaska: Hukuk neredeyse tamamen bilgi, Finansal
#               Tablolar hesap agirlikli, Finansal Muhasebe kayit agirlikli.
#               Dogru konudan YANLIS KURGUDA soru yazmak cocugu hazirliksiz
#               birakir - Cem'in en basta uyardigi sey buydu.
#
#  KAPSAMA vs SIKLIK: 883 konunun yalnizca 41'i birden fazla donemde cikmis.
#  TESMER her donem farkli konu soruyor. Dar bir "sik cikan" listesine yiginmak
#  hata olur; kota uc katmanli:
#     A) 2+ donemde cikan konular      -> %50   (omurga)
#     B) 1 donemde cikan konular       -> %35   (kapsama)
#     C) mufredatta var, hic cikmamis  -> %15   (surpriz sigortasi)
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$TOPLAM = if($env:KOTA_TOPLAM){ [int]$env:KOTA_TOPLAM } else { 5000 }
$a = Get-Content (Join-Path $kok "veri/smmm-analiz.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# --- konu -> hangi donemlerde gorundu ; ders -> konu listesi
$konuDon=@{}; $dersKonu=@{}; $dersTip=@{}; $dersUzun=@{}
foreach($d in $a.donemler){
  $ders="$($d.ders)"; $don="$($d.donem)"
  if(-not $dersKonu.ContainsKey($ders)){ $dersKonu[$ders]=@{} }
  foreach($p in $d.konuSayim.PSObject.Properties){
    $k=$p.Name
    $dersKonu[$ders][$k]=1
    if(-not $konuDon.ContainsKey($k)){ $konuDon[$k]=@{} }
    $konuDon[$k][$don]=1
  }
  if($d.PSObject.Properties['tipSayim']){
    if(-not $dersTip.ContainsKey($ders)){ $dersTip[$ders]=@{} }
    foreach($p in $d.tipSayim.PSObject.Properties){ $dersTip[$ders][$p.Name] = [int]$dersTip[$ders][$p.Name] + [int]$p.Value }
  }
  if($d.PSObject.Properties['uzunSayim']){
    if(-not $dersUzun.ContainsKey($ders)){ $dersUzun[$ders]=@{} }
    foreach($p in $d.uzunSayim.PSObject.Properties){ $dersUzun[$ders][$p.Name] = [int]$dersUzun[$ders][$p.Name] + [int]$p.Value }
  }
}

$dersler = @($dersKonu.Keys | Sort-Object)
$dersKota = [math]::Floor($TOPLAM / $dersler.Count)
Write-Host ("DERS: {0}   ders basina kota: {1}" -f $dersler.Count, $dersKota)

$plan = New-Object System.Collections.Generic.List[object]
$ozet = New-Object System.Collections.Generic.List[object]

foreach($ders in $dersler){
  $konular = @($dersKonu[$ders].Keys)
  $omurga  = @($konular | Where-Object { $konuDon[$_].Count -ge 2 })
  $kapsama = @($konular | Where-Object { $konuDon[$_].Count -eq 1 })

  # KURGU DAGILIMI: o dersin GERCEK dagilimi. Veri yoksa genel dagilima duser
  # ve bu rapora YAZILIR - sessizce varsayilan kullanmak, olculmus gibi
  # gostermek olur.
  $tipD = if($dersTip.ContainsKey($ders) -and $dersTip[$ders].Count){ $dersTip[$ders] } else { $null }
  $tipKaynak = if($tipD){ 'olculdu' } else { 'VERI YOK - genel dagilim' }
  if(-not $tipD){ $tipD = @{ bilgi=71; hesap=16; vaka=7; kayit=5; karsilastir=1 } }
  $tipTop = ($tipD.Values | Measure-Object -Sum).Sum

  $uzunD = if($dersUzun.ContainsKey($ders) -and $dersUzun[$ders].Count){ $dersUzun[$ders] } else { @{ orta=47; kisa=35; uzun=18 } }
  $uzunTop = ($uzunD.Values | Measure-Object -Sum).Sum

  # A katmani %50, B %35, C %15
  $aKota = [math]::Floor($dersKota * 0.50)
  $bKota = [math]::Floor($dersKota * 0.35)
  $cKota = $dersKota - $aKota - $bKota

  # A: omurga konulari, DONEM SAYISIYLA ORANTILI (7 donemde cikan, 2 donemde
  # cikandan fazla soru alir)
  $aAgirlik = 0; foreach($k in $omurga){ $aAgirlik += $konuDon[$k].Count }
  foreach($k in $omurga){
    $pay = if($aAgirlik -gt 0){ [math]::Round($aKota * ($konuDon[$k].Count / [double]$aAgirlik)) } else { 0 }
    if($pay -lt 1){ $pay = 1 }
    $plan.Add([pscustomobject]@{ ders=$ders; konu=($k -split '\|')[1]; katman='A-omurga'; donem=$konuDon[$k].Count; adet=$pay })
  }
  # B: bir kez cikanlar, esit dagilim
  if($kapsama.Count){
    $her = [math]::Max(1, [math]::Floor($bKota / $kapsama.Count))
    foreach($k in $kapsama){ $plan.Add([pscustomobject]@{ ders=$ders; konu=($k -split '\|')[1]; katman='B-kapsama'; donem=1; adet=$her }) }
  }

  $ozet.Add([pscustomobject]@{
    ders=$ders; toplam_kota=$dersKota
    omurga_konu=$omurga.Count; kapsama_konu=$kapsama.Count
    a_kota=$aKota; b_kota=$bKota; c_kota_mufredat=$cKota
    kurgu_kaynak=$tipKaynak
    kurgu=($tipD.GetEnumerator() | Sort-Object {-$_.Value} | ForEach-Object { "{0} %{1}" -f $_.Key, [math]::Round(100.0*$_.Value/$tipTop) }) -join ' · '
    uzunluk=($uzunD.GetEnumerator() | Sort-Object {-$_.Value} | ForEach-Object { "{0} %{1}" -f $_.Key, [math]::Round(100.0*$_.Value/$uzunTop) }) -join ' · '
  })
}

Write-Host ""
Write-Host "======== URETIM KOTASI ========"
foreach($o in $ozet){
  Write-Host ("  {0}" -f $o.ders)
  Write-Host ("     omurga {0} konu / kapsama {1} konu   A:{2} B:{3} C:{4}" -f $o.omurga_konu, $o.kapsama_konu, $o.a_kota, $o.b_kota, $o.c_kota_mufredat)
  Write-Host ("     kurgu ({0}): {1}" -f $o.kurgu_kaynak, $o.kurgu)
}
$planToplam = ($plan | Measure-Object adet -Sum).Sum
Write-Host ""
Write-Host ("PLAN SATIRI: {0}   toplam soru: {1}  (hedef {2}, C katmani mufredattan doldurulacak)" -f $plan.Count, $planToplam, $TOPLAM)

[IO.File]::WriteAllText((Join-Path $kok "veri/uretim-kotasi.json"), ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); hedef=$TOPLAM; ders_kotasi=$dersKota
  kaynak='12 donem TESMER Yeterlilik kitapcigi (2023/1-2026/3), 883 tekil konu, 480 test sorusundan kurgu'
  ozet=$ozet; plan=$plan
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/uretim-kotasi.json"
exit 0
