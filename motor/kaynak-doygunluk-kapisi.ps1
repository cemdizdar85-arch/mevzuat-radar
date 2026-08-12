# ============================================================================
#  KAYNAK DOYGUNLUK KAPISI            (11.08.2026, 0 USD, API YOK)
#
#  NEDEN: Cem 11.08 - "tekrar desenlerini yok etmeliyiz nasil yapariz".
#  Olculdu: kasa 2.674 maddenin yalniz 63'unun ustune kurulmus. Model elindeki
#  maddelerin %2,4'unu kullanip onlari tekrar tekrar sormus:
#    VUK m.275 -> 201 soru (madde 660 karakter, 5 bent, kapasite 5)  FAZLA +196
#    TBK m.82  ->  85 soru (madde 547 karakter, TEK fikra, kapasite 2) FAZLA +83
#    TTK m.367 ->  73 soru (kapasite 4)                                FAZLA +69
#  TBK m.82 tek fikralik bir maddedir; ondan 85 AYRI soru cikmasi fiziken
#  mumkun degildir - 83'u ayni seyin kopyasidir.
#
#  BU KAPI NE YAPAR: uretim istemi hazirlanirken her kaynagin DOYGUNLUGUNU
#  olcer. Doymus kaynaga yeni soru yazdirmaz; yerine BOS madde onerir.
#  Bozulma kapisi gibi, parayi harcamadan ONCE devreye girer.
#
#  KAPASITE OLCUTU (kendi kuralimiz, olculmus bir yasa DEGIL):
#    kapasite = min( fikra_veya_bent_sayisi x 2 , madde_karakteri / 150 )
#  Gerekce: her fikra en fazla iki soru tasir (olumlu kurgu + olumsuz kurgu);
#  cok kisa maddede fikra cok olsa bile ayri soru cikmaz, uzunluk tavan koyar.
#
#  Kullanim:
#    -kaynak 'VUK m.275'          -> tek kaynagin durumu
#    -liste veri\istek.csv        -> istek listesini suzer (kaynak kolonu)
#    -bos -kanun TTK -adet 30     -> doldurulacak BOS madde onerir
#
#  Girdi: veri\kaynak-kapasite.csv (2.845 madde) - kapasite-olcum.ps1 uretir
#         veri\bos-madde-oncelik.csv - cikmis sinav eslesmesine gore sirali
# ============================================================================
param(
  [string]$kaynak = '',
  [string]$liste  = '',
  [switch]$bos,
  [string]$kanun  = '',
  [int]$adet      = 25,
  [switch]$ozet
)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent
$kapDosya = Join-Path $kok 'veri\kaynak-kapasite.csv'
$oncDosya = Join-Path $kok 'veri\bos-madde-oncelik.csv'

if(-not (Test-Path $kapDosya)){ Write-Error "kapasite tablosu yok: $kapDosya"; exit 1 }
$kap = @(Import-Csv $kapDosya -Encoding UTF8)
# STANDARTLAR (11.08 eklendi): BDS/TMS/TFRS kapasitesi paragraf sayisindan.
# DIKKAT: kapasite AMBARDAKI kadar metne dayanir. Ambar standardin yalniz bir
# bolumunu yuttuysa kapasite OLDUGUNDAN DUSUK cikar (BDS 330: ambarda 6
# paragraf var; standardin asli daha uzundur). Yani FAZLA rakami ihtiyatli
# ust sinirdir - gercek fazlalik bundan kucuk olabilir, buyuk olamaz denemez.
$stdDosya = Join-Path $kok 'veri\standart-kapasite.csv'
if(Test-Path $stdDosya){
  foreach($r in @(Import-Csv $stdDosya -Encoding UTF8)){
    $kap += [pscustomobject]@{ kaynak=$r.kaynak; kanun=$r.tur; karakter=$r.karakter; parca=$r.dosyaSayisi; birim=$r.paragraf; kapasite=$r.kapasite; mevcutSoru=$r.mevcutSoru; bosluk=$r.bosluk; mulga=$false }
  }
}
$H = @{}
foreach($r in $kap){ $H[$r.kaynak] = $r }

function Durum($r){
  $s = [int]$r.mevcutSoru; $k = [int]$r.kapasite
  if($s -ge $k){ return 'DOYMUS' }
  if($s -ge [Math]::Ceiling($k*0.75)){ return 'DOLUYOR' }
  return 'YER VAR'
}

# ---------- TEK KAYNAK ----------
if($kaynak -ne ''){
  if(-not $H.ContainsKey($kaynak)){
    Write-Output "$kaynak : TABLODA YOK (standart ya da olculemeyen kaynak) - OLCULEMEDI"
    exit 0
  }
  $r = $H[$kaynak]
  $d = Durum $r
  Write-Output ("{0} : {1}" -f $kaynak, $d)
  Write-Output ("  madde {0} karakter, {1} fikra/bent -> kapasite {2}" -f $r.karakter,$r.birim,$r.kapasite)
  Write-Output ("  mevcut soru {0} | bosluk {1}" -f $r.mevcutSoru,$r.bosluk)
  if($d -eq 'DOYMUS'){
    Write-Output "  KARAR: bu kaynaga YENI SORU YAZDIRILMAZ. Fazlalik $([Math]::Abs([int]$r.bosluk)) soru."
  }
  exit 0
}

# ---------- ISTEK LISTESI SUZME ----------
if($liste -ne ''){
  if(-not (Test-Path $liste)){ Write-Error "liste yok: $liste"; exit 1 }
  $istek = @(Import-Csv $liste -Encoding UTF8)
  $gecen = New-Object System.Collections.ArrayList
  $red   = New-Object System.Collections.ArrayList
  $olcumsuz = 0
  foreach($i in $istek){
    $k = "$($i.kaynak)"
    if(-not $H.ContainsKey($k)){ $olcumsuz++; [void]$gecen.Add($i); continue }   # olculemeyen GECER, damgalanir
    if((Durum $H[$k]) -eq 'DOYMUS'){ [void]$red.Add([pscustomobject]@{ kaynak=$k; mevcut=$H[$k].mevcutSoru; kapasite=$H[$k].kapasite }) }
    else { [void]$gecen.Add($i) }
  }
  Write-Output "istek           : $($istek.Count)"
  Write-Output "GECEN           : $($gecen.Count)"
  Write-Output "KAPIDA RED      : $($red.Count)  (doymus kaynak)"
  Write-Output "OLCULEMEDI      : $olcumsuz  (kapasite tablosunda yok - gecirildi, damgali)"
  if($red.Count -gt 0){
    Write-Output ""
    Write-Output "--- REDDEDILEN KAYNAKLAR ---"
    $red | Group-Object kaynak | Sort-Object Count -Descending | Select-Object -First 20 | ForEach-Object {
      $x = $H[$_.Name]
      Write-Output ("  {0,-14} istekte {1,3} kez | kasada {2,3} soru, kapasite {3}" -f $_.Name,$_.Count,$x.mevcutSoru,$x.kapasite)
    }
  }
  $cikti = Join-Path $kok 'veri\doygunluk-suzulmus-istek.csv'
  $gecen | Export-Csv $cikti -NoTypeInformation -Encoding UTF8
  Write-Output ""
  Write-Output "suzulmus istek: $cikti"
  exit 0
}

# ---------- BOS MADDE ONERISI ----------
if($bos){
  if(-not (Test-Path $oncDosya)){ Write-Error "oncelik tablosu yok: $oncDosya"; exit 1 }
  $o = @(Import-Csv $oncDosya -Encoding UTF8)
  if($kanun -ne ''){ $o = @($o | Where-Object { $_.kanun -eq $kanun }) }
  # once cikmis sinavda eslesenler, sonra kapasitesi buyuk olanlar
  $sirali = @($o | Sort-Object @{E={[int]$_.sinavEslesme};D=$true}, @{E={[int]$_.kapasite};D=$true})
  $sec = @($sirali | Select-Object -First $adet)
  Write-Output ("BOS MADDE ONERISI{0} - {1} kayit" -f $(if($kanun){" ($kanun)"}else{''}),$sec.Count)
  Write-Output ("toplam kontenjan: {0} soru" -f (($sec | Measure-Object -Property kapasite -Sum).Sum))
  Write-Output ""
  foreach($r in $sec){
    Write-Output ("  {0,-13} kapasite {1,2} | sinav eslesme {2,2} | {3}" -f $r.kaynak,$r.kapasite,$r.sinavEslesme,$r.kelimeler)
  }
  Write-Output ""
  Write-Output "NOT: 'sinav eslesme' = maddenin ayirt edici uc kelimesinin AYNI cikmis"
  Write-Output "     soruda birlikte gecme sayisi. Cikmis sinavlar madde NUMARASI"
  Write-Output "     vermedigi icin (8.409 soruda yalniz 1 atif) metin uzerinden"
  Write-Output "     olculdu. Yuksek isabet, DUSUK kapsama: eslesmesi 0 olan madde"
  Write-Output "     'sinavda cikmaz' DEMEK DEGILDIR - olculemedi demektir."
  exit 0
}

# ---------- OZET ----------
$doymus  = @($kap | Where-Object { (Durum $_) -eq 'DOYMUS' })
$doluyor = @($kap | Where-Object { (Durum $_) -eq 'DOLUYOR' })
$yerVar  = @($kap | Where-Object { (Durum $_) -eq 'YER VAR' })
$fazla   = [Math]::Abs((@($kap | Where-Object { [int]$_.bosluk -lt 0 }) | Measure-Object -Property bosluk -Sum).Sum)
$kontenjan = (@($kap | Where-Object { [int]$_.bosluk -gt 0 }) | Measure-Object -Property bosluk -Sum).Sum
Write-Output "=== KAYNAK DOYGUNLUK OZETI ==="
Write-Output "olculen madde   : $($kap.Count)"
Write-Output "  DOYMUS        : $($doymus.Count)"
Write-Output "  DOLUYOR       : $($doluyor.Count)"
Write-Output "  YER VAR       : $($yerVar.Count)"
Write-Output ""
Write-Output "toplam FAZLALIK : $fazla soru   (doymus kaynaklardaki kopya)"
Write-Output "bos KONTENJAN   : $kontenjan soru"
Write-Output ""
Write-Output "--- EN COK ASILAN 10 KAYNAK ---"
@($kap | Where-Object { [int]$_.bosluk -lt 0 } | Sort-Object { [int]$_.bosluk }) | Select-Object -First 10 | ForEach-Object {
  Write-Output ("  {0,-14} {1,4} soru / kapasite {2,2} -> fazla {3}" -f $_.kaynak,$_.mevcutSoru,$_.kapasite,[Math]::Abs([int]$_.bosluk))
}
Write-Output ""
Write-Output "NOT: standartlar (BDS/TMS/TFRS) 11.08 itibariyla DAHIL - kapasite,"
Write-Output "ambardaki paragraf sayisindan. Ambar standardin bir bolumunu yuttuysa"
Write-Output "kapasite oldugundan dusuk cikar; FAZLA rakami ihtiyatli ust sinirdir."
