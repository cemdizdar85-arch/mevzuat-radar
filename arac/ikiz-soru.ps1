#requires -Version 5.1
<#
================================================================================
  IKIZ SORU KAPISI (KAPI-IK)  — 11.09.2026
  Cem: "konu basina 4 tur tekrar uretti mi olc"

  NIYE VAR: 11.09'da uretim plani ayni konudan 4 TURA kadar soru istiyor
  (cikmis arsivde 10 kez gorulmus konudan 12 soru hedefleniyor). Uretici her
  turda ayni konu adini ve COGU ZAMAN AYNI kaynak paketini goruyor - tekrar
  riski buradan dogar.

  OLCULDU (11.09, 3.701 soru · ayni konudan >=2 soru uretilmis 769 konu):
    kiyaslanan cift 6.652 · ortalama benzerlik %17,2
    benzerlik >=%60 olan cift        62  (%0,93)
    BIREBIR AYNI soru metni grubu     9  (9 fazladan kopya)
    yayindaki havuzda iki kopyasi da olan grup: 0
  Yani bugun tekrar SEYREK ve hicbiri havuza girmemis. Ama 4 turlu uretimde
  ayni konu 4 kez sorulacak; kapi ONLEYICI olarak kuruluyor.

  ⛔ URETICIDE BENZERLIK KAPISI YOK (olculdu: KAPI-B diye bir sey aranmis,
     yalniz KAPI-BAKIYE cikmis). Bu dosya o bosluğu doldurur.

  NE YAPAR: fabrikadaki TUM sorulari konu konu kiyaslar, esigi asan ciftleri
  raporlar ve YAYIN DISI birakilacak id listesi uretir.
  ⛔ SORU SILMEZ. Uretilen soru odendi; atmak ikinci kayiptir. Kapi yalnizca
     "ikisinden BIRI yayina girsin" der - hangisi? Daha once yayinda olan,
     yoksa daha uzun/ayrintili olan kalir.

  BEDEL 0 — yalniz yerel dosya okur.
================================================================================
#>
param(
  [double]$Esik = 0.60,          # soru metni benzerlik esigi
  [double]$SikEsik = 0.60,       # DOGRU SIK metni benzerlik esigi (ikinci olcut)
  [switch]$Ayrinti              # eslesen ciftlerin metnini de bas
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$kusur=Test-OlcumKapilari -Sessiz
if((Dizi $kusur).Count){
  Write-Host '⛔ OLCUM KAPILARI KIRMIZI - bu olcume guvenilmez, duzeltilmeden kosma:' -ForegroundColor Red
  foreach($h in (Dizi $kusur)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'olcum kapilari oz-sinavi dustu'
}

function Katla([string]$s){
  $x="$s".ToLowerInvariant()
  foreach($c in @(@('ç','c'),@('ğ','g'),@('ı','i'),@('İ','i'),@('ö','o'),@('ş','s'),@('ü','u'))){ $x=$x.Replace($c[0],$c[1]) }
  # ⛔ RAKAMLAR KORUNUR. Ilk surumde 4+ harfli KELIME kumesi kiyasliyordum;
  #    matematik sorusunda formul silinince geriye "fonksiyonu icin kactir"
  #    kaliyor ve BIRBIRINDEN TAMAMEN FARKLI iki soru %100 cikiyordu
  #    (f(x)=3x³-2x²+5x-4 · f′(2)  vs  f(x)=(2x²-3)³·(x+1)² · f′(1)).
  #    Ustel isaretler de rakama cevrilir ki 2x² ile 2x3 ayrilsin.
  $x=$x.Replace('²','2').Replace('³','3').Replace('¹','1')
  return ((($x -replace '[^a-z0-9]',' ') -replace '\s+',' ').Trim())
}
# UCLU-HARF (trigram) Jaccard: yakin-kopya tespitinin standart olcusu.
# Kelime kumesinden ustun, cunku rakam/formul farkini GORUR ve ek/cekim
# farkindan etkilenmez ("sozlesmenin" ile "sozlesmesi" buyuk olcude ortak).
function Ucluler([string]$t){
  $k=($t -replace ' ','')
  $h=New-Object 'System.Collections.Generic.HashSet[string]'
  if($k.Length -lt 3){ return $h }
  for($i=0;$i -le $k.Length-3;$i++){ [void]$h.Add($k.Substring($i,3)) }
  return $h
}
function Benzerlik($ax,$bx){
  if($ax.Count -eq 0 -or $bx.Count -eq 0){ return 0.0 }
  $kesisim=0
  foreach($u in $ax){ if($bx.Contains($u)){ $kesisim++ } }
  $birlesim=$ax.Count + $bx.Count - $kesisim
  if($birlesim -le 0){ return 0.0 }
  return $kesisim/[double]$birlesim
}

# --- KAPININ OZ-SINAVI: bilinen cevapli ciftler -------------------------------
# Kapi kurulurken IKI kez yanildim; ikisi de burada sabitlendi.
$sinavHata=New-Object System.Collections.Generic.List[string]
$ayni1='f(x) = ax + b fonksiyonunda f(2) = 7 ve f(-1) = 1 olduguna gore, f(4) kactir?'
$ayni2='f(x) = ax + b fonksiyonunda f(2) = 7 ve f(-1) = 1 olduguna gore f(4) kactir?'
$fark1='f(x) = 3x3 - 2x2 + 5x - 4 fonksiyonu icin f(2) kactir?'
$fark2='f(x) = (2x2-3)3 (x+1)2 fonksiyonu icin f(1) kactir?'
$sAyni=Benzerlik (Ucluler (Katla $ayni1)) (Ucluler (Katla $ayni2))
$sFark=Benzerlik (Ucluler (Katla $fark1)) (Ucluler (Katla $fark2))
if($sAyni -lt 0.90){ $sinavHata.Add(("neredeyse AYNI iki soru %{0:N0} cikti (>=%90 olmali)" -f (100*$sAyni))) }
if($sFark -ge 0.60){ $sinavHata.Add(("FARKLI iki matematik sorusu %{0:N0} cikti (<%60 olmali)" -f (100*$sFark))) }
# 3) Ayni konudan FARKLI soru: metin yakin ama DOGRU SIK farkli -> IKIZ DEGIL
$sk1='Genel kurulun devredilemez yetkileri ortaklarin oy hakki'
$sk2='Her ortak en az bir oy hakkina sahiptir'
$sSik=Benzerlik (Ucluler (Katla $sk1)) (Ucluler (Katla $sk2))
if($sSik -ge $SikEsik){ $sinavHata.Add(("farkli dogru siklar %{0:N0} cikti (<%{1:N0} olmali)" -f (100*$sSik),(100*$SikEsik))) }
if((Dizi $sinavHata).Count){
  Write-Host '⛔ IKIZ KAPISI OZ-SINAVI KIRMIZI:' -ForegroundColor Red
  foreach($h in (Dizi $sinavHata)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'ikiz kapisi oz-sinavi dustu - olcuye guvenilmez'
}
Write-Host ("IKIZ KAPISI OZ-SINAVI YESIL (ayni %{0:N0} · farkli %{1:N0})" -f (100*$sAyni),(100*$sFark)) -ForegroundColor Green
# --- YAYINDAKI HAVUZ ----------------------------------------------------------
$havuz=@{}
$secYol=Join-Path $depoKok 'veri\sinav\kaydir-secim\sgs-650-secim.json'
if(Test-Path $secYol){ foreach($r in (JsonDizi $secYol)){ $havuz["$($r.etiket)|$($r.id)"]=$true } }

# --- TOPLA --------------------------------------------------------------------
$konuSoru=@{}
$toplam=0
foreach($x in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json')){
  $c=$null; try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  $et=($x.BaseName -replace '^kalip-parti-','')
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    $toplam++
    $k=Katla "$($v.konu)"; if(-not $k){ continue }
    if(-not $konuSoru.ContainsKey($k)){ $konuSoru[$k]=New-Object System.Collections.Generic.List[object] }
    $konuSoru[$k].Add([pscustomobject]@{
      et=$et; id=$p.Name; anahtar="$et|$($p.Name)"
      yayinda=$havuz.ContainsKey("$et|$($p.Name)")
      uc=(Ucluler (Katla "$($v.soru)")); ham="$($v.soru)"; boy="$($v.soru)".Length
      # ⛔ IKI OLCUT SART. Tek olcut (soru metni) KURT MASALI okuyor: 11.09'da
      #    14 "canli ikiz" bildirdi, elle bakinca 3'u gercekti. Digerleri AYNI
      #    KONUDAN FARKLI SORU - 4 turlu uretimden zaten istedigimiz sey
      #    ("limited sirket ozellikleri" %78 benzer ama dogru siklari %32,
      #    biri D biri E; iki ayri soru). Gercek ikiz = soru metni YAKIN **VE**
      #    DOGRU SIK METNI de yakin.
      ucDogru=(Ucluler (Katla "$($v.siklar.$($v.dogru))")); dogruHam="$($v.siklar.$($v.dogru))"
    })
  }
}
Write-Host ("taranan soru: {0:N0} · konu: {1:N0}" -f $toplam,$konuSoru.Count) -ForegroundColor Cyan

# --- KIYASLA ------------------------------------------------------------------
$cift=0; $benzerToplam=0.0
$ikizler=New-Object System.Collections.Generic.List[object]
foreach($k in $konuSoru.Keys){
  $l=Dizi $konuSoru[$k]
  if($l.Count -lt 2){ continue }
  for($i=0;$i -lt $l.Count-1;$i++){
    for($j=$i+1;$j -lt $l.Count;$j++){
      $s=Benzerlik $l[$i].uc $l[$j].uc
      $cift++; $benzerToplam+=$s
      if($s -lt $Esik){ continue }
      $sd=Benzerlik $l[$i].ucDogru $l[$j].ucDogru
      if($sd -ge $SikEsik){
        # Hangisi KALIR: yayinda olan; ikisi de/hicbiri degilse UZUN olan
        $a=$l[$i]; $b=$l[$j]
        $kalan=$a; $duşen=$b
        if($b.yayinda -and -not $a.yayinda){ $kalan=$b; $duşen=$a }
        elseif($a.yayinda -eq $b.yayinda -and $b.boy -gt $a.boy){ $kalan=$b; $duşen=$a }
        $ikizler.Add([pscustomobject]@{
          konu=$k; skor=[math]::Round($s,3); sikSkor=[math]::Round($sd,3)
          kalan=$kalan.anahtar; dusen=$duşen.anahtar
          kalanYayinda=$kalan.yayinda; dusenYayinda=$duşen.yayinda
          metin1=$a.ham; metin2=$b.ham
        })
      }
    }
  }
}
$ik=Dizi $ikizler
$ort=if($cift){ 100*$benzerToplam/[double]$cift } else { 0 }
Write-Host ("kiyaslanan cift: {0:N0} · ortalama benzerlik %{1:N1}" -f $cift,$ort)
Write-Host ("IKIZ (soru>=%{0:N0} VE dogru sik>=%{3:N0}): {1:N0} cift  (%{2:N2})" -f (100*$Esik),$ik.Count,$(if($cift){100*$ik.Count/[double]$cift}else{0}),(100*$SikEsik)) -ForegroundColor $(if($ik.Count){'Yellow'}else{'Green'})

# Yayina girmemesi gereken id'ler (ikisi de yayindaysa KIRMIZI - elle bakilmali)
$yayinDisi=@{}; $ikisiDeYayinda=New-Object System.Collections.Generic.List[object]
foreach($z in $ik){
  # 11.09: once "ikisi de yayindaysa DOKUNMA, elle bak" diyordu. Iki olcutlu
  # kapi kurulduktan sonra 14 aday 3'e indi ve UCU DE elle dogrulandi (gercek
  # ikiz). Artik onlar da yayin disi listesine girer - ama AYRICA raporlanir,
  # cunku canli havuzdan soru dusurmek gorulmeden gecmemeli.
  $yayinDisi[$z.dusen]=$z.skor
  if($z.kalanYayinda -and $z.dusenYayinda){ $ikisiDeYayinda.Add($z) }
}
Write-Host ("yayin disi birakilacak id: {0:N0}" -f $yayinDisi.Count)
if((Dizi $ikisiDeYayinda).Count){
  Write-Host ("🔴 IKISI DE YAYINDA olan ikiz: {0} - biri havuzdan CIKARILACAK" -f (Dizi $ikisiDeYayinda).Count) -ForegroundColor Red
  foreach($z in (Dizi $ikisiDeYayinda)){ Write-Host ("   %{0:N0} [{1}] {2} = {3}" -f (100*$z.skor),$z.konu,$z.kalan,$z.dusen) -ForegroundColor Red }
}

if($Ayrinti -and $ik.Count){
  Write-Host "`nEN BENZER 5:" -ForegroundColor Yellow
  foreach($z in ($ik|Sort-Object skor -Descending|Select-Object -First 5)){
    Write-Host ("  %{0:N0} · {1}" -f (100*$z.skor),$z.konu)
    Write-Host ("     1) " + $z.metin1.Substring(0,[Math]::Min(120,$z.metin1.Length)))
    Write-Host ("     2) " + $z.metin2.Substring(0,[Math]::Min(120,$z.metin2.Length)))
  }
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\ikiz-soru.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kural='IKI OLCUT: soru metni VE dogru sik metni birlikte esigi asmali. Tek olcut kurt masali okuyor (11.09: 14 bildirdi, 3 gercekti). Esigi asan ciftte BIRI yayin disi birakilir; SORU SILINMEZ.'
  esik=$Esik; sik_esik=$SikEsik; taranan=$toplam; kiyaslanan_cift=$cift
  ortalama_benzerlik_yuzde=[math]::Round($ort,1)
  ikiz_cift=$ik.Count; yayin_disi=$yayinDisi.Count
  ikisi_de_yayinda=(Dizi $ikisiDeYayinda).Count
  yayin_disi_idler=@($yayinDisi.Keys | Sort-Object)
  ciftler=@($ik | Select-Object konu,skor,sikSkor,kalan,dusen,kalanYayinda,dusenYayinda)
})
Write-Host "`n-> veri/ikiz-soru.json" -ForegroundColor Green
