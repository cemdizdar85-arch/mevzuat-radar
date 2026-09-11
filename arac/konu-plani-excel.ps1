#requires -Version 5.1
<#
================================================================================
  KONU PLANI -> EXCEL  (11.09.2026, Cem "bana calismayi excel olarak at")

  GIRDI : veri/konu-plani-sgs.json + veri/fabrika/konu-koprusu.json
  CIKTI : sql-yerel/KONU-PLANI-SGS.xlsx

  ⚠ Bu makinede Python YOK; Excel COM ile yazilir (10.09'da olculdu).
  ⚠ FORMUL SIRASI: 11.09'da SORU-DENETIM-LISTESI.xlsx'te COUNTIF #VALUE! verdi,
    cunku formul BASVURDUGU SAYFA henuz yokken yazilmisti. Once TUM sayfalar
    olusturulur, formuller EN SON yazilir.
================================================================================
#>
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$cikti=Join-Path $depoKok 'sql-yerel\KONU-PLANI-SGS.xlsx'
New-Item -ItemType Directory -Force (Split-Path $cikti) | Out-Null
if(Test-Path $cikti){ Remove-Item $cikti -Force }

$j=Get-Content (Join-Path $depoKok 'veri\konu-plani-sgs.json') -Raw -Encoding UTF8|ConvertFrom-Json
$sat=@($j.satirlar)
if(-not $sat.Count){ throw 'konu-plani-sgs.json bos.' }
Write-Host ("plan satiri: {0:N0}" -f $sat.Count)

$BEDEL_TL=13.12; $BEDEL_TOPLU=6.56

$xl=New-Object -ComObject Excel.Application
$xl.Visible=$false; $xl.DisplayAlerts=$false
try{
  $wb=$xl.Workbooks.Add()
  while($wb.Sheets.Count -gt 1){ $wb.Sheets.Item($wb.Sheets.Count).Delete() }

  function YeniSayfa([string]$ad,[int]$sira){
    if($sira -eq 1){ $sh=$wb.Sheets.Item(1) } else { $sh=$wb.Sheets.Add([System.Reflection.Missing]::Value,$wb.Sheets.Item($wb.Sheets.Count)) }
    $sh.Name=$ad; return $sh
  }
  function Baslik($sh,[string[]]$bas){
    for($i=0;$i -lt $bas.Count;$i++){ $sh.Cells.Item(1,$i+1).Value2=$bas[$i] }
    $r=$sh.Range($sh.Cells.Item(1,1),$sh.Cells.Item(1,$bas.Count))
    $r.Font.Bold=$true; $r.Interior.Color=15773696; $r.Font.Color=16777215
    $sh.Rows.Item(1).RowHeight=22; $sh.Application.ActiveWindow.SplitRow=1; $sh.Application.ActiveWindow.FreezePanes=$true
  }
  # ⛔ 11.09 TUZAK: Turkce yerelde `-f` ondaligi VIRGULLE yazar ("13,12") ve
  #    Excel .Formula bunu "=D2*13" + ikinci arguman "12" sanip 0x800A03EC atar.
  #    Formul metni HER ZAMAN InvariantCulture ile kurulur.
  function Frm([string]$kalip,[object[]]$arg){ return [string]::Format([cultureinfo]::InvariantCulture,$kalip,$arg) }
  # Diziyi tek seferde yaz (hucre hucre yazmak 6.600 satirda dakikalar suruyor)
  function BlokYaz($sh,[object[,]]$veri,[int]$satir,[int]$sutun,[int]$n,[int]$s){
    $sh.Range($sh.Cells.Item($satir,$sutun),$sh.Cells.Item($satir+$n-1,$sutun+$s-1)).Value2=$veri
  }

  # ---- 1) OZET -------------------------------------------------------------
  $sh1=YeniSayfa '1-OZET' 1
  $sh1.Cells.Item(1,1).Value2='TETİKTE · SGS KONU PLANI'
  $sh1.Cells.Item(1,1).Font.Size=16; $sh1.Cells.Item(1,1).Font.Bold=$true
  $sh1.Cells.Item(2,1).Value2=("Üretim: {0} · motor/konu-plani.ps1 (bedel 0, elle düzenlenmez)" -f $j.olcum)
  $sh1.Cells.Item(3,1).Value2=$j.kural
  $sh1.Cells.Item(5,1).Value2='SORU'; $sh1.Cells.Item(5,2).Value2='CEVAP'
  $sh1.Range('A5:B5').Font.Bold=$true; $sh1.Range('A5:B5').Interior.Color=15773696; $sh1.Range('A5:B5').Font.Color=16777215
  # ⚠ PS 5.1: @(@('a',1),@('b',2)) ic dizileri DUZLESTIRIR -> $o[1] patlar.
  #   Acik nesneyle yazilir (11.09'da yasandi: "Int32 -> String atilamadi").
  $ozet=@(
    [pscustomobject]@{ s='Çıkmış SGS arşivinde görülen konu';    c=[int]$j.cikmis_konu }
    [pscustomobject]@{ s='Bu konularda elimizdeki sağlam soru';  c=[int]$j.bizde_soru }
    [pscustomobject]@{ s='Soru yetersiz olan konu';              c=[int]$j.acik_konu }
    [pscustomobject]@{ s='Basılacak toplam soru';                c=[int]$j.acik_soru }
    [pscustomobject]@{ s='Birim maliyet (sıralı) TL';            c=$BEDEL_TL }
    [pscustomobject]@{ s='Birim maliyet (toplu istek) TL';       c=$BEDEL_TOPLU }
  )
  # Tek tek Cells.Item(...).Value2 atamasi bu betikte "Int32 -> String atilamadi"
  # veriyordu (izole denemede ayni cagri calisiyor; COM baglama farki). Blok
  # yazma hem bu sorunu atlar hem 2.818 satirda kat kat hizlidir.
  $ob=New-Object 'object[,]' $ozet.Count,2
  for($i=0;$i -lt $ozet.Count;$i++){ $ob[$i,0]=[string]$ozet[$i].s; $ob[$i,1]=$ozet[$i].c }
  BlokYaz $sh1 $ob 6 1 $ozet.Count 2
  $sh1.Columns.Item(1).ColumnWidth=42; $sh1.Columns.Item(2).ColumnWidth=16

  # ---- 2) ONCELIK ----------------------------------------------------------
  $sh2=YeniSayfa '2-ONCELIK' 2
  Baslik $sh2 @('Öncelik','Kural','Konu','Soru','Bedel sıralı (TL)','Bedel toplu (TL)')
  $tier=@(
    [pscustomobject]@{ ad='1 · çok kritik'; esik=10 }
    [pscustomobject]@{ ad='2 · kritik';     esik=5  }
    [pscustomobject]@{ ad='3 · önemli';     esik=3  }
    [pscustomobject]@{ ad='4 · orta';       esik=2  }
    [pscustomobject]@{ ad='5 · tamamı';     esik=1  }
  )
  $r=2
  foreach($t in $tier){
    $alt=@($sat|Where-Object{ [int]$_.cikmis -ge [int]$t.esik })
    $s=0; foreach($z in $alt){ $s+=[int]$z.acik }
    # Tek satirlik dizi yazimi sessizce BOS birakiyordu (11.09: 2-ONCELIK bos cikti).
    # Hucre hucre yazilir; sayilar [double]'a ACIK cevrilir (COM baglama tuzagi).
    $sh2.Cells.Item($r,1).Value2=[string]$t.ad
    $sh2.Cells.Item($r,2).Value2=[string]("çıkmış >= {0}" -f $t.esik)
    $sh2.Cells.Item($r,3).Value2=[double]$alt.Count
    $sh2.Cells.Item($r,4).Value2=[double]$s
    $sh2.Cells.Item($r,5).Formula=(Frm "=D{0}*{1}" @($r,$BEDEL_TL))
    $sh2.Cells.Item($r,6).Formula=(Frm "=D{0}*{1}" @($r,$BEDEL_TOPLU))
    $r++
  }
  $sh2.Range("E2:F$($r-1)").NumberFormatLocal='#.##0 "TL"'
  $sh2.Range("C2:D$($r-1)").NumberFormatLocal='#.##0'
  $sh2.Cells.Item($r+1,1).Value2='ÖNERİ: önce "çıkmış >= 3" kuşağını bas — sınavda TEKRAR EDEN konular bunlar.'
  $sh2.Cells.Item($r+1,1).Font.Bold=$true
  $sh2.Cells.Item($r+2,1).Value2='Uzun kuyruk tek dönemlik konulardan oluşuyor (3.246 konunun 2.668''i TEK dönemlik — sınav anatomisi ölçümü).'
  $sh2.Columns.Item(1).ColumnWidth=18; $sh2.Columns.Item(2).ColumnWidth=16
  for($c=3;$c -le 6;$c++){ $sh2.Columns.Item($c).ColumnWidth=18 }

  # ---- 3) DERS OZETI -------------------------------------------------------
  $sh3=YeniSayfa '3-DERS' 3
  Baslik $sh3 @('Ders','Açık konu','Açık soru','Bedel toplu (TL)')
  $grp=@($sat|Group-Object ders|Sort-Object { $s=0; foreach($z in $_.Group){ $s+=[int]$z.acik }; -$s })
  $r=2
  foreach($g in $grp){
    $s=0; foreach($z in $g.Group){ $s+=[int]$z.acik }
    $sh3.Cells.Item($r,1).Value2=[string]$g.Name
    $sh3.Cells.Item($r,2).Value2=[double]$g.Count
    $sh3.Cells.Item($r,3).Value2=[double]$s
    $sh3.Cells.Item($r,4).Formula=(Frm "=C{0}*{1}" @($r,$BEDEL_TOPLU))
    $r++
  }
  $sh3.Range("B2:C$($r-1)").NumberFormatLocal='#.##0'
  $sh3.Range("D2:D$($r-1)").NumberFormatLocal='#.##0 "TL"'
  $sh3.Columns.Item(1).ColumnWidth=40; for($c=2;$c -le 4;$c++){ $sh3.Columns.Item($c).ColumnWidth=16 }

  # ---- 4) KONU KONU (tam liste) -------------------------------------------
  $sh4=YeniSayfa '4-KONU' 4
  Baslik $sh4 @('Ders','Konu','Çıkmış','Dönem','Yayında','Rafta','Bizde','Hedef','BASILACAK','Öncelik')
  $n=$sat.Count
  $blok=New-Object 'object[,]' $n,10
  $sirali=@($sat|Sort-Object @{e={[int]$_.cikmis};Descending=$true},@{e={[int]$_.acik};Descending=$true})
  for($i=0;$i -lt $n;$i++){
    $z=$sirali[$i]; $c=[int]$z.cikmis
    $blok[$i,0]="$($z.ders)"; $blok[$i,1]="$($z.konu)"; $blok[$i,2]=$c; $blok[$i,3]=[int]$z.donem
    $blok[$i,4]=[int]$z.yayinda; $blok[$i,5]=[int]$z.rafta; $blok[$i,6]=[int]$z.bizde
    $blok[$i,7]=[int]$z.hedef; $blok[$i,8]=[int]$z.acik
    $blok[$i,9]=$(if($c -ge 10){'1 · çok kritik'}elseif($c -ge 5){'2 · kritik'}elseif($c -ge 3){'3 · önemli'}elseif($c -ge 2){'4 · orta'}else{'5 · uzun kuyruk'})
  }
  BlokYaz $sh4 $blok 2 1 $n 10
  $sh4.Columns.Item(1).ColumnWidth=34; $sh4.Columns.Item(2).ColumnWidth=52
  for($c=3;$c -le 9;$c++){ $sh4.Columns.Item($c).ColumnWidth=11 }
  $sh4.Columns.Item(10).ColumnWidth=16
  $sh4.Range($sh4.Cells.Item(1,1),$sh4.Cells.Item($n+1,10)).AutoFilter() | Out-Null
  # BASILACAK sutununa renk olcegi: cok basilacak konu goze carpsin
  $rngI=$sh4.Range("I2:I$($n+1)")
  $fc=$rngI.FormatConditions.AddColorScale(2)
  $fc.ColorScaleCriteria.Item(1).FormatColor.Color=16777215
  $fc.ColorScaleCriteria.Item(2).FormatColor.Color=255

  $sh1.Activate()
  $wb.SaveAs($cikti,51)
  Write-Host ("-> {0}" -f $cikti) -ForegroundColor Green
}
finally{
  if($wb){ $wb.Close($false) }
  $xl.Quit()
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
  [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
