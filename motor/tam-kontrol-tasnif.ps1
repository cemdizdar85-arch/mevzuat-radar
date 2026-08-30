# ============================================================================
#  TAM KONTROL — KUSUR TASNIFI  (25.08.2026)
#
#  NEDEN VAR: ilk kosuda 20 sorunun 20'si de "KUSURLU" cikti. Bu haliyle
#  KARAR VERILEMEZ bir sonuctur - "her sey bozuk" demek "hicbir sey bilmiyoruz"
#  demektir. Kusurlarin hepsi ayni agirlikta degil:
#
#    OLDURUCU  : soru YANLIS BILGI ogretiyor. Yayina GIREMEZ, onarilamazsa silinir.
#                (cevap yanlis · cift dogru · mevzuat eskimis · uydurma rakam ·
#                 aciklama maddeyle celiskili)
#    ONARILIR  : bilgi dogru ama sunum/etiket bozuk. Yayina girmeden ONARILIR.
#                (sik-aciklama karisik · hap uzun · YZ kokusu · kaynak-konu
#                 uyumsuz · mukerrer · Turkce bozuk · fikra atfi)
#    SUS       : okumayi/olcumu zorlastirir ama soruyu yanlis yapmaz.
#                (mutlak terim · dogru sik en uzun · dort parca eksik)
#
#  Bu betik API'ye DOKUNMAZ, para harcamaz - var olan kosu ciktisini okur.
#  Boylece esik tartismasi icin kosuyu YENIDEN ODEMEK gerekmez.
# ============================================================================
param([string]$dosya = '')
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $dosya){
  $dosya = (Get-ChildItem (Join-Path $kok 'veri/fabrika') -Filter 'tam-kontrol-2*.json' |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
if(-not $dosya -or -not (Test-Path $dosya)){ Write-Host 'Kosu ciktisi bulunamadi.'; exit 1 }
Write-Host ("Okunan: {0}" -f (Split-Path $dosya -Leaf))
$j = Get-Content $dosya -Raw -Encoding UTF8 | ConvertFrom-Json

# kusur kodu -> agirlik
$OLDURUCU = @('M1','M2','M3','M8','M9','Y2','Y3')
$ONARILIR = @('M4','M5','M6','M7','D1','D2','D7','D9','Y1','Y4','Y5')
$SUS      = @('D3','D4','D5','D6','D8','D10')

function Agirlik([string]$b){
  $k = ("$b" -split ' ')[0]
  if($OLDURUCU -contains $k){ return 'OLDURUCU' }
  if($ONARILIR -contains $k){ return 'ONARILIR' }
  if($SUS      -contains $k){ return 'SUS' }
  return 'BILINMEYEN'
}

$say = [ordered]@{ TEMIZ=0; SUSLU=0; ONARILIR=0; OLDURUCU=0; OLCULEMEDI=0 }
$sinifSay = @{}
$oldurucuListe = New-Object System.Collections.Generic.List[object]
$onarilirListe = New-Object System.Collections.Generic.List[object]

foreach($x in $j){
  if("$($x.hukum)" -eq 'olculemedi'){ $say.OLCULEMEDI++; continue }
  $bulgular = @(); foreach($b in (@($x.deterministik) + @($x.icerik))){ if($b){ $bulgular += "$b" } }
  $enAgir = 'TEMIZ'; $oldurucular = @(); $onarilirlar = @()
  foreach($b in $bulgular){
    $a = Agirlik $b
    $k = ("$b" -split ' ')[0]
    if($sinifSay.ContainsKey($k)){ $sinifSay[$k]++ } else { $sinifSay[$k]=1 }
    if($a -eq 'OLDURUCU'){ $enAgir='OLDURUCU'; $oldurucular += $b }
    elseif($a -eq 'ONARILIR'){ if($enAgir -ne 'OLDURUCU'){ $enAgir='ONARILIR' }; $onarilirlar += $b }
    elseif($a -eq 'SUS'){ if($enAgir -eq 'TEMIZ'){ $enAgir='SUSLU' } }
  }
  switch($enAgir){
    'OLDURUCU' { $say.OLDURUCU++; $oldurucuListe.Add([ordered]@{ id=$x.id; ders=$x.ders; konu=$x.konu; kusur=$oldurucular; gerekce=$x.gerekce }) }
    'ONARILIR' { $say.ONARILIR++; $onarilirListe.Add([ordered]@{ id=$x.id; ders=$x.ders; kusur=$onarilirlar }) }
    'SUSLU'    { $say.SUSLU++ }
    default    { $say.TEMIZ++ }
  }
}
$topl = [math]::Max($j.Count,1)

Write-Host ''
Write-Host '================ KUSUR TASNIFI ================'
Write-Host ("  TEMIZ                : {0,4}  (%{1:N1})  hicbir bulgu yok" -f $say.TEMIZ,(100*$say.TEMIZ/$topl))
Write-Host ("  SUSLU                : {0,4}  (%{1:N1})  yalniz bicim susu - YAYINA GIREBILIR" -f $say.SUSLU,(100*$say.SUSLU/$topl))
Write-Host ("  ONARILIR             : {0,4}  (%{1:N1})  bilgi dogru, sunum bozuk" -f $say.ONARILIR,(100*$say.ONARILIR/$topl))
Write-Host ("  OLDURUCU             : {0,4}  (%{1:N1})  YANLIS BILGI - yayina GIREMEZ" -f $say.OLDURUCU,(100*$say.OLDURUCU/$topl))
Write-Host ("  OLCULEMEDI           : {0,4}  (%{1:N1})" -f $say.OLCULEMEDI,(100*$say.OLCULEMEDI/$topl))
Write-Host ''
Write-Host ("  >>> BUGUN YAYINA GIREBILECEK : {0} / {1}  (%{2:N1})" -f ($say.TEMIZ+$say.SUSLU),$topl,(100*($say.TEMIZ+$say.SUSLU)/$topl))
Write-Host ("  >>> ONARILINCA GIREBILECEK   : {0}  (+%{1:N1})" -f $say.ONARILIR,(100*$say.ONARILIR/$topl))
Write-Host ("  >>> ASLA GIREMEZ (onarilmazsa): {0}" -f $say.OLDURUCU)
Write-Host ''
Write-Host '---- kusur kodu dagilimi ----'
foreach($k in ($sinifSay.GetEnumerator() | Sort-Object Value -Descending)){
  Write-Host ("  {0,-5} {1,4}   [{2}]" -f $k.Key,$k.Value,(Agirlik $k.Key))
}
if($oldurucuListe.Count){
  Write-Host ''
  Write-Host '---- OLDURUCU KUSURLAR (tek tek okunacak) ----'
  foreach($o in $oldurucuListe){
    Write-Host ("  {0} | {1} / {2}" -f $o.id.Substring(0,8),$o.ders,$o.konu)
    foreach($kk in $o.kusur){ Write-Host ("      - {0}" -f $kk) }
    if($o.gerekce){ Write-Host ("      gerekce: {0}" -f $o.gerekce) }
  }
}
# PS 5.1: [ordered] icine Generic.List konunca ConvertTo-Json "Bagimsiz degisken
# turleri eslesmiyor" diyor. Listeleri ONCE diziye cevir, sonra sar.
$oldD = @(); foreach($o in $oldurucuListe){ $oldD += ,$o }
$onaD = @(); foreach($o in ($onarilirListe | Select-Object -First 20)){ $onaD += ,$o }
$sayD = [ordered]@{}; foreach($p in $say.GetEnumerator()){ $sayD[$p.Key] = [int]$p.Value }
$sinD = [ordered]@{}; foreach($p in ($sinifSay.GetEnumerator() | Sort-Object Value -Descending)){ $sinD[$p.Key] = [int]$p.Value }

$cikti = Join-Path $kok 'veri/tam-kontrol-tasnif.json'
$paket = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynak=(Split-Path $dosya -Leaf); toplam=[int]$j.Count
  sayim=$sayD; kusur_kodlari=$sinD
  oldurucu=$oldD; onarilir_ornek=$onaD
  agirlik_tablosu=[ordered]@{ oldurucu=($OLDURUCU -join ','); onarilir=($ONARILIR -join ','); sus=($SUS -join ',') }
}
try { [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $paket -Depth 8), (New-Object Text.UTF8Encoding($false))) }
catch { Write-Host ("Rapor yazilamadi: {0}" -f $_.Exception.Message) }
Write-Host ''
Write-Host "-> veri/tam-kontrol-tasnif.json"
