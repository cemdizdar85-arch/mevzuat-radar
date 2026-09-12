#requires -Version 5.1
<#
================================================================================
  YIL ANALIZI — "hangi konu HALA soruluyor?"  (12.09.2026)
  Cem: "yil yil yaparmisin ... cok eskiden sorulup suan sorulmayan cok ders
  cikarmak yerine yeni en cok cikani cikaralim"

  KAYNAK: veri/sgs-analiz.json — 35 donem, 2015/1 .. 2026/2, donem basina
  konuSayim (ders|konu -> adet). Bedel 0, yalniz yerel dosya okur.

  ⛔ ONCE OLCULEN, SONRA PLAN: ilk bakista "son 3 yilda 931 konu var" diye
     plan kurulacakti. Olctum - konu etiketleri COK INCE: 3.263 konunun
     %83,5'i 12 YILDA YALNIZ BIR KEZ gecmis. Bir kez gecen konuya soru basmak
     piyango bileti almaktir; tekrar eden konu ise sinavin omurgasidir.

  DORT KUME (olcut: kac FARKLI YILDA gecti + son 3 yilda var mi):
    CEKIRDEK      >=2 yil VE 2024+  -> omurga. ONCE BUNLAR basilir.
    SONEN         >=2 yil AMA 2024+ YOK -> eskiden sorulurdu, birakildi. BASILMAZ.
    TEK-YENI      1 yil, 2024+      -> gunceldir ama tekrar kaniti yok. IKINCI sira.
    TEK-ESKI      1 yil, 2024 oncesi-> ne tekrar var ne guncellik. BASILMAZ.

  ⚠ DERS ADLARI SINAV TARAFINDANDIR (Muhasebe, Hukuk, Genel Kultur...), bizim
    11 dersimiz degil. "Muhasebe" = Finansal + Maliyet + MTA + Denetim;
    "Hukuk" = Ticaret + Borclar + Vergi + Meslek + Is-SGK. Esleme
    veri/fabrika/konu-koprusu.json'da.

  KULLANIM
    powershell -NoProfile -File arac/yil-analizi.ps1              # rapor
    powershell -NoProfile -File arac/yil-analizi.ps1 -Pencere 4   # son 4 yil
    powershell -NoProfile -File arac/yil-analizi.ps1 -Yaz         # veri/YIL-ANALIZI.md
================================================================================
#>
param(
  [ValidateRange(1,12)][int]$Pencere = 3,     # "guncel" sayilan son kac yil
  [int]$EnAz = 2,                             # kac farkli yilda gecerse "tekrar eden"
  [switch]$Yaz
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$kapi=Test-OlcumKapilari -Sessiz
if((Dizi $kapi).Count){ foreach($h in (Dizi $kapi)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

$analizYol=Join-Path $depoKok 'veri\sgs-analiz.json'
if(-not (Test-Path $analizYol)){ throw "arsiv analizi yok: $analizYol" }
# ⛔ once degiskene al, sonra @() ile sar (PS 5.1 dizi sarma tuzagi)
$ham=Get-Content $analizYol -Raw -Encoding UTF8|ConvertFrom-Json
$donemler=@($ham.donemler)

$konuYil=@{}      # konu -> { yil -> $true }
$konuTop=@{}      # konu -> toplam soru (tum yillar)
$konuGuncel=@{}   # konu -> pencere icindeki soru
$yilSoru=@{}
$sonYil=0
foreach($d in $donemler){
  if("$($d.donem)" -notmatch '^(\d{4})/(\d)$'){ continue }
  $yil=[int]$Matches[1]
  if($yil -gt $sonYil){ $sonYil=$yil }
  $yilSoru["$yil"]=[int]$yilSoru["$yil"]+[int]$d.toplamSoru
  foreach($p in $d.konuSayim.PSObject.Properties){
    $a="$($p.Name)"
    if(-not $konuYil.ContainsKey($a)){ $konuYil[$a]=@{} }
    $konuYil[$a]["$yil"]=$true
    $konuTop[$a]=[int]$konuTop[$a]+[int]$p.Value
  }
}
$esik=$sonYil-$Pencere+1
foreach($d in $donemler){
  if("$($d.donem)" -notmatch '^(\d{4})/(\d)$'){ continue }
  $yil=[int]$Matches[1]
  if($yil -lt $esik){ continue }
  foreach($p in $d.konuSayim.PSObject.Properties){ $konuGuncel["$($p.Name)"]=[int]$konuGuncel["$($p.Name)"]+[int]$p.Value }
}

$kume=@{ CEKIRDEK=(New-Object System.Collections.Generic.List[string])
         SONEN=(New-Object System.Collections.Generic.List[string])
         'TEK-YENI'=(New-Object System.Collections.Generic.List[string])
         'TEK-ESKI'=(New-Object System.Collections.Generic.List[string]) }
foreach($k in $konuYil.Keys){
  $cokYil = $konuYil[$k].Count -ge $EnAz
  $guncel = $konuGuncel.ContainsKey($k)
  if($cokYil -and $guncel){ $kume['CEKIRDEK'].Add($k) }
  elseif($cokYil){ $kume['SONEN'].Add($k) }
  elseif($guncel){ $kume['TEK-YENI'].Add($k) }
  else{ $kume['TEK-ESKI'].Add($k) }
}
function GuncelSoru($liste){ $t=0; foreach($k in $liste){ $t+=[int]$konuGuncel[$k] }; return $t }
function TumSoru($liste){ $t=0; foreach($k in $liste){ $t+=[int]$konuTop[$k] }; return $t }

$satirlar=New-Object System.Text.StringBuilder
function Yaz2([string]$s){ Write-Host $s; [void]$satirlar.AppendLine($s) }

Yaz2 ("YIL ANALIZI · pencere son {0} yil ({1}-{2}) · tekrar esigi {3} yil" -f $Pencere,$esik,$sonYil,$EnAz)
Yaz2 ("kaynak: veri/sgs-analiz.json · {0} donem · guncelleme {1}" -f $donemler.Count,$ham.guncelleme)
Yaz2 ""
Yaz2 "YIL YIL SORU"
foreach($y in ($yilSoru.Keys|Sort-Object{[int]$_})){ Yaz2 ("  {0}  {1,5:N0} soru" -f $y,$yilSoru[$y]) }
Yaz2 ""
Yaz2 ("{0,-14} {1,7} {2,9} {3,10}" -f 'KUME','konu','toplam','pencerede')
foreach($ad in @('CEKIRDEK','SONEN','TEK-YENI','TEK-ESKI')){
  $l=$kume[$ad].ToArray()
  Yaz2 ("{0,-14} {1,7:N0} {2,9:N0} {3,10:N0}" -f $ad,$l.Count,(TumSoru $l),(GuncelSoru $l))
}
Yaz2 ""
Yaz2 "⛔ SORU BASILACAK KUME: CEKIRDEK (tekrar eden VE guncel). SONEN ve TEK-ESKI basilmaz."
Yaz2 ""
Yaz2 "CEKIRDEK · DERS DERS"
$dersKume=@{}
foreach($k in $kume['CEKIRDEK'].ToArray()){
  $ders=($k -split '\|')[0]
  if(-not $dersKume.ContainsKey($ders)){ $dersKume[$ders]=@{konu=0;soru=0} }
  $dersKume[$ders].konu++; $dersKume[$ders].soru+=[int]$konuGuncel[$k]
}
foreach($g in ($dersKume.GetEnumerator()|Sort-Object{ $_.Value.soru } -Descending)){
  Yaz2 ("  {0,-30} {1,4} konu · pencerede {2,4} soru" -f $g.Key,$g.Value.konu,$g.Value.soru)
}
Yaz2 ""
Yaz2 "CEKIRDEK · EN COK TEKRAR EDEN 30"
$sirali=@($kume['CEKIRDEK'].ToArray()|Sort-Object @{e={$konuYil[$_].Count};Descending=$true},@{e={$konuGuncel[$_]};Descending=$true}|Select-Object -First 30)
foreach($k in $sirali){
  $yillar=@($konuYil[$k].Keys|Sort-Object{[int]$_})
  Yaz2 ("  {0,2} yil · pencerede {1,2} soru · {2,-50} son: {3}" -f $konuYil[$k].Count,[int]$konuGuncel[$k],$k.Substring(0,[Math]::Min(50,$k.Length)),(($yillar|Select-Object -Last 3) -join ','))
}

if($Yaz){
  $hedef=Join-Path $depoKok 'veri\YIL-ANALIZI.md'
  $md="# SGS YIL ANALİZİ`r`n`r`n_Ölçüm $(Get-Date -Format 'dd.MM.yyyy HH:mm') · üretici ``arac/yil-analizi.ps1`` · bedel 0_`r`n`r`n``````" + "`r`n" + $satirlar.ToString() + "``````" + "`r`n"
  [IO.File]::WriteAllText($hedef,$md,(New-Object Text.UTF8Encoding $false))
  Write-Host "`nyazildi: veri/YIL-ANALIZI.md" -ForegroundColor Green
}
