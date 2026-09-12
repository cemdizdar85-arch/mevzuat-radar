#requires -Version 5.1
<#
================================================================================
  YIL ANALIZI — EXCEL  (12.09.2026, Cem "excel yaparmisin")

  arac/yil-analizi.ps1 ile AYNI olcumu uc sayfalik .xlsx'e yazar:
    OZET      yil yil soru · kume tablosu · ders dagilimi · karar notu
    KONULAR   3.263 konunun TAMAMI, 2015..2026 yil sutunlariyla + kume etiketi
    CEKIRDEK  yalniz basilacak kume (tekrar eden VE guncel), oncelik sirasinda

  ⛔ EXCEL COM KULLANILMIYOR — ve bu bilerek. Ilk surum COM'la yazildi, IKI KEZ
     ayni satirda dustu:
        "Programin yurutulmesine devam etmek icin bellek yeterli degil"
        OutOfMemoryException · alti hucrelik BASLIK yazarken
     Bos bellek 543 -> 889 MB'a cikarildi, ayni yerde yine dustu; yani sorun RAM
     degil COM arayuziydi. Artik arac/xlsx-yaz.ps1 kullaniliyor: .xlsx zaten
     ZIP icinde XML, .NET'in ZipArchive'i yetiyor. Kazanc:
       - bellek darligindan etkilenmez
       - Excel KURULU OLMAYAN makinede de calisir (GitHub Actions dahil)
       - baska surec Excel'i mesgul ettiginde takilmaz

  KULLANIM
    powershell -NoProfile -File arac/yil-analizi-excel.ps1
    powershell -NoProfile -File arac/yil-analizi-excel.ps1 -Pencere 4
    powershell -NoProfile -File arac/yil-analizi-excel.ps1 -Hedef "C:\yol\x.xlsx"
  BEDEL 0.
================================================================================
#>
param(
  [ValidateRange(1,12)][int]$Pencere = 3,
  [int]$EnAz = 2,
  [string]$Hedef = ''
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$kapi=Test-OlcumKapilari -Sessiz
if((Dizi $kapi).Count){ foreach($h in (Dizi $kapi)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }
. (Join-Path $here 'xlsx-yaz.ps1')

if(-not $Hedef){ $Hedef=Join-Path ([Environment]::GetFolderPath('Desktop')) ("TETIKTE-YIL-ANALIZI-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".xlsx") }

# --- OLCUM (yil-analizi.ps1 ile AYNI mantik) ----------------------------------
# ⛔ once degiskene al, sonra @() ile sar (PS 5.1 dizi sarma tuzagi)
$ham=Get-Content (Join-Path $depoKok 'veri\sgs-analiz.json') -Raw -Encoding UTF8|ConvertFrom-Json
$donemler=@($ham.donemler)
$konuYil=@{}; $konuTop=@{}; $yilSoru=@{}; $sonYil=0
foreach($d in $donemler){
  if("$($d.donem)" -notmatch '^(\d{4})/(\d)$'){ continue }
  $yil=[int]$Matches[1]; if($yil -gt $sonYil){ $sonYil=$yil }
  $yilSoru["$yil"]=[int]$yilSoru["$yil"]+[int]$d.toplamSoru
  foreach($p in $d.konuSayim.PSObject.Properties){
    $a="$($p.Name)"
    if(-not $konuYil.ContainsKey($a)){ $konuYil[$a]=@{} }
    $konuYil[$a]["$yil"]=[int]$konuYil[$a]["$yil"]+[int]$p.Value
    $konuTop[$a]=[int]$konuTop[$a]+[int]$p.Value
  }
}
$yillar=@($yilSoru.Keys|Sort-Object{[int]$_})
$esik=$sonYil-$Pencere+1
$satirlar=New-Object System.Collections.Generic.List[object]
foreach($k in $konuYil.Keys){
  $y=$konuYil[$k]
  $guncel=0; foreach($yy in $y.Keys){ if([int]$yy -ge $esik){ $guncel+=[int]$y[$yy] } }
  $kume = if($y.Count -ge $EnAz -and $guncel -gt 0){ 'CEKIRDEK' }
          elseif($y.Count -ge $EnAz){ 'SONEN' }
          elseif($guncel -gt 0){ 'TEK-YENI' } else { 'TEK-ESKI' }
  $parca=$k -split '\|'
  $satirlar.Add([pscustomobject]@{
    ders=$parca[0]; konu=$(if($parca.Count -gt 1){ $parca[1] }else{ '' })
    kume=$kume; yilSayi=$y.Count; toplam=[int]$konuTop[$k]; guncel=$guncel; yil=$y })
}
$veri=$satirlar.ToArray()
$tekYil=@($veri|Where-Object{ $_.yilSayi -eq 1 }).Count
Write-Host ("olculdu: {0:N0} konu · {1} yil · pencere {2}-{3}" -f $veri.Count,$yillar.Count,$esik,$sonYil) -ForegroundColor Cyan

$sira=@{'CEKIRDEK'=0;'TEK-YENI'=1;'SONEN'=2;'TEK-ESKI'=3}
$sirali=@($veri|Sort-Object @{e={$sira[$_.kume]}},@{e={$_.yilSayi};Descending=$true},@{e={$_.guncel};Descending=$true},ders,konu)
$cek=@($sirali|Where-Object{ $_.kume -eq 'CEKIRDEK' })

# --- OZET sayfasi -------------------------------------------------------------
$ozet=New-Object System.Collections.Generic.List[object]
$ozet.Add(@('TETİKTE · SGS YIL ANALİZİ'))
$ozet.Add(@(("Ölçüm " + (Get-Date -Format 'dd.MM.yyyy HH:mm') + " · kaynak veri/sgs-analiz.json (" + $donemler.Count + " dönem) · pencere son " + $Pencere + " yıl (" + $esik + "-" + $sonYil + ") · tekrar eşiği " + $EnAz + " yıl")))
$ozet.Add(@(''))
$ozet.Add(@('YIL YIL SORU'))
$ozet.Add(@('Yıl','Soru'))
foreach($y in $yillar){ $ozet.Add(@([int]$y,[int]$yilSoru[$y])) }
$ozet.Add(@(''))
$ozet.Add(@('KÜME','Konu','Toplam soru',("Son $Pencere yıl"),'Karar'))
$kararlar=[ordered]@{
  'CEKIRDEK'='BASILIR — tekrar eden VE hâlâ soruluyor'
  'TEK-YENI'='İkinci sıra — güncel ama tekrar kanıtı yok'
  'SONEN'   ='BASILMAZ — eskiden sorulurdu, bırakıldı'
  'TEK-ESKI'='BASILMAZ — ne tekrar var ne güncellik'
}
foreach($ad in $kararlar.Keys){
  $l=@($veri|Where-Object{ $_.kume -eq $ad })
  $t=0; foreach($x in $l){ $t+=[int]$x.toplam }
  $g=0; foreach($x in $l){ $g+=[int]$x.guncel }
  $ozet.Add(@($ad,[int]$l.Count,[int]$t,[int]$g,$kararlar[$ad]))
}
$ozet.Add(@(''))
$ozet.Add(@('ÇEKİRDEK · DERS DERS'))
$ozet.Add(@('Sınav dersi','Konu',("Son $Pencere yıl soru")))
foreach($g in (@($cek|Group-Object ders)|Sort-Object{ ($_.Group|Measure-Object guncel -Sum).Sum } -Descending)){
  $ozet.Add(@($g.Name,[int]$g.Count,[int]($g.Group|Measure-Object guncel -Sum).Sum))
}
$ozet.Add(@(''))
$ozet.Add(@('NOT'))
$ozet.Add(@(("Konuların %" + ([math]::Round(100*$tekYil/$veri.Count,1)) + " kadarı 12 yılda YALNIZ BİR KEZ çıkmış. Bir kez çıkan konuya soru basmak piyango biletidir; tekrar eden konu sınavın omurgasıdır. Ölçüt bu yüzden İKİ şarta bağlandı: tekrar ediyor mu VE hâlâ soruluyor mu.")))
$ozet.Add(@('Ders adları SINAV tarafındandır. "Muhasebe" = Finansal Muhasebe + Maliyet + Mali Tablolar Analizi + Denetim. "Hukuk" = Ticaret + Borçlar + Vergi + Meslek + İş ve SGK.'))
$ozet.Add(@('Üretici: arac/yil-analizi-excel.ps1 · Excel KURULU OLMADAN yazar (arac/xlsx-yaz.ps1). Bedel 0, istendiğinde yeniden koşar.'))

# --- KONULAR sayfasi ----------------------------------------------------------
$konular=New-Object System.Collections.Generic.List[object]
$bas=@('Ders','Konu','Küme','Kaç yıl','Toplam soru',("Son $Pencere yıl"))
foreach($y in $yillar){ $bas+=[string]$y }
$konular.Add($bas)
foreach($x in $sirali){
  $s=@($x.ders,$x.konu,$x.kume,[int]$x.yilSayi,[int]$x.toplam,[int]$x.guncel)
  foreach($y in $yillar){ $v=[int]$x.yil["$y"]; $s+=$(if($v -gt 0){ [int]$v }else{ $null }) }
  $konular.Add($s)
}

# --- CEKIRDEK sayfasi ---------------------------------------------------------
$cekSayfa=New-Object System.Collections.Generic.List[object]
# ⛔ 12.09 — BU SUTUN YANILTIYORDU. Once "Son görüldüğü yıllar" adiyla yalniz
#    SON 3 yil yaziliyordu; Cem baktiginda Muhasebe konulari 3 yillik gorundu.
#    Ornek: "dikey yuzde analizi" gercekte 8 yilda cikmis
#    (2015,2016,2018,2019,2020,2024,2025,2026) ama hucrede "2024, 2025, 2026"
#    yaziyordu. "Kac yil" sutunu 8 diyor, yanindaki hucre 3 yil gosteriyordu -
#    iki sutun birbirini yalanliyordu. Artik TUM yillar yazilir; kirpma YOK.
$cekSayfa.Add(@('Ders','Konu','Kaç yıl',("Son $Pencere yıl soru"),'Toplam soru','Çıktığı yıllar (tamamı)'))
foreach($x in $cek){
  $gy=@($x.yil.Keys|Sort-Object{[int]$_})
  $cekSayfa.Add(@($x.ders,$x.konu,[int]$x.yilSayi,[int]$x.guncel,[int]$x.toplam,($gy -join ', ')))
}

$dosya=XlsxYaz -Hedef $Hedef -Sayfalar @(
  @{ ad='OZET';     satirlar=$ozet.ToArray() }
  @{ ad='KONULAR';  satirlar=$konular.ToArray() }
  @{ ad='CEKIRDEK'; satirlar=$cekSayfa.ToArray() }
) -DonukSatir 1

Write-Host ("`nYAZILDI: {0}" -f $dosya.FullName) -ForegroundColor Green
Write-Host ("  {0:N0} KB · OZET · KONULAR ({1:N0} satır) · CEKIRDEK ({2:N0} satır)" -f ($dosya.Length/1KB),$veri.Count,$cek.Count) -ForegroundColor Green
