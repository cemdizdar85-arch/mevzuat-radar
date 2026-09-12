#requires -Version 5.1
<#
================================================================================
  SIKLIK PLANI — carpan SIKLIGA baglanir, sessizlige DEGIL  (12.09.2026)
  Cem: "yeni olcutle plani kuralim ... ayni sorulari basmayalim, eksik bekleyen
  konu varsa atlamayalim"

  ⛔ ONCEKI OLCUTUM YANLISTI. "Son 3 yildir cikmayan konu olmustur" demistim.
     Cem Excel'e bakip "3 yil sonra pat diye soruyorlar" dedi; olctum, HAKLIYDI:
       tekrar cikislarin %39,4'u 3 YIL VE DAHA UZUN sessizlikten sonra geliyor
       son cikistan beri  1 yil -> %10,3    3 yil -> %4,0    7 yil -> %3,2
     Yani 3. yilda ucurum YOK; sessizlik neredeyse bilgi tasimiyor.
     Asil sinyal SIKLIK (2019-2026 uzerinden olculdu):
       gecmiste 1 kez cikmis -> %2,6    2 kez -> %9,4    3-4 kez -> %15,1
       5-6 kez -> %21,6                 7+ kez -> %63,2
     Sessizlikte fark 4,0 ↔ 3,2 (yok sayilir); siklikta 2,6 ↔ 63,2 (24 KAT).
     O yuzden carpan SIKLIGA baglandi; guncellik yalniz SIRALAMADA kullanilir.

  UC SART (Cem, 12.09):
    1) Carpan siklik uzerine        -> kat: donem>=5 ise 5, 3-4 ise 4, 2 ise 3
    2) AYNI SORUYU BASMA            -> hedeften HAVUZDAKI mevcut DUSULUR
    3) EKSIK BEKLEYENI ATLAMA       -> bizim_ders'i BOS olan tekrar eden konular
                                       sessizce dusurulmez; ayri is emri olarak
                                       raporlanir (KAPI-DR gercek ders adi ister)

  ⛔ TEK DONEMLIK KONU PLANA GIRMEZ: 9.241 konu (SGS'in %94'u) bir kez cikmis,
     olculen olasilik %2,6. Piyango bileti alinmaz.

  KULLANIM
    powershell -NoProfile -File arac/siklik-plani.ps1                 # olc + rapor
    powershell -NoProfile -File arac/siklik-plani.ps1 -Yaz            # plan dosyasi
    powershell -NoProfile -File arac/siklik-plani.ps1 -Sozel          # sozel hatti da al
  BEDEL 0 - yalniz yerel dosya okur.
================================================================================
#>
param(
  [switch]$Yaz,
  [switch]$Sozel,                      # varsayilan: sozel hat BEKLIYOR (Cem karari)
  [int]$Taban = 2,                     # konu basina en az hedef
  [string]$Hedef = 'veri\sinav\plan-siklik.json'
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$kapi=Test-OlcumKapilari -Sessiz
if((Dizi $kapi).Count){ foreach($h in (Dizi $kapi)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

function Katla4([string]$s){
  $x="$s".ToLowerInvariant()
  foreach($c in @(@('ç','c'),@('ğ','g'),@('ı','i'),@('İ','i'),@('ö','o'),@('ş','s'),@('ü','u'))){ $x=$x.Replace($c[0],$c[1]) }
  return (($x -replace '[^a-z0-9 ]',' ') -replace '\s+',' ').Trim()
}
# Cem 11.09: sozel hat BEKLESIN. Karar degisirse -Sozel ile alinir.
$SOZEL_DERS=@('Turkce','Yabanci Dil','Matematik','Ataturk Ilke ve Inkilap Tarihi','Ataturk Ilkeleri ve Inkilap Tarihi')

# --- 1) KOPRU: tekrar eden konular -------------------------------------------
# ⛔ once degiskene al, sonra @() ile sar (PS 5.1 dizi sarma tuzagi)
$hamK=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8|ConvertFrom-Json
$sgs=@(@($hamK)|Where-Object{ "$($_.sinav)" -eq 'SGS' })
$tekrar=@($sgs|Where-Object{ [int]$_.donem -ge 2 })
Write-Host ("kopru: {0:N0} SGS konu · tekrar eden (donem>=2): {1:N0}" -f $sgs.Count,$tekrar.Count) -ForegroundColor Cyan

# --- 2) HAVUZ: zaten neyimiz var ---------------------------------------------
$hamH=Get-Content (Join-Path $depoKok 'veri\sinav\kaydir-secim\sgs-650-secim.json') -Raw -Encoding UTF8|ConvertFrom-Json
$havuz=@($hamH)
$havuzKok=@{}
foreach($h in $havuz){ $kk=Katla4 "$($h.konu)"; $havuzKok[$kk]=1+[int]$havuzKok[$kk] }
Write-Host ("havuz: {0:N0} soru · {1:N0} benzersiz konu" -f $havuz.Count,$havuzKok.Count) -ForegroundColor Cyan

# --- 3) PLAN ------------------------------------------------------------------
# --- 2b) DERS AYRISTIRICI: koprude bizim_ders BOS olanlari kurtar --------------
# ⛔ Cem 12.09: "eksik bekleyen konu varsa atlamayalim". Koprude 244 tekrar eden
#    konunun bizim_ders'i BOS - ve iclerinde BIZIM hattan olanlar var
#    (tms 18 hasilat, denetim riski...). Bunlari sessizce dusurmek, en sik
#    cikan konulari kaybetmek olurdu.
#    arac/ders-ayristir.ps1 bu esleme icin YAZILDI ve GERI SINANDI: 789 bilinen
#    konuda %91,8 isabet. Cozemedigini '(ayristirilamadi)' birakir - yanlis
#    derse atamak, atamamaktan kotudur (o ders adina soru basariz, sinavda
#    o dersten cikmaz).
$ayristirma=@{}
$ayrYol=Join-Path $depoKok 'veri\ders-ayristirma-sgs.json'
if(Test-Path $ayrYol){
  $hamAyr=Get-Content $ayrYol -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($k in @($hamAyr.kayitlar)){
    $d="$($k.ders)".Trim()
    if($d -and $d -ne '(ayristirilamadi)'){ $ayristirma[(Katla4 "$($k.konu)")]=$d }
  }
  Write-Host ("ders ayristirma: {0:N0} konu cozulmus (geri sinama %{1})" -f $ayristirma.Count,$hamAyr.geri_sinama.isabet_yuzde) -ForegroundColor Cyan
} else { Write-Host "⚠ ders-ayristirma-sgs.json YOK - dersi bos konular kurtarilamaz" -ForegroundColor Yellow }

# --- 2c) CEM'IN ELLE ATAMALARI (en yuksek oncelik) ----------------------------
# 12.09: ayristiricinin cozemedigi 11 konu Cem'e soruldu, onayladi. Bunlar
# kopru ve ayristiricidan ONCE okunur - insan karari makineyi ezer.
$elle=@{}
$elleYol=Join-Path $depoKok 'veri\ders-elle-atama.json'
if(Test-Path $elleYol){
  $hamElle=Get-Content $elleYol -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($a in @($hamElle.atamalar)){ $elle[(Katla4 "$($a.konu)")]="$($a.ders)".Trim() }
  Write-Host ("elle atama: {0} konu (Cem onayli)" -f $elle.Count) -ForegroundColor Cyan
}

$plan=New-Object System.Collections.Generic.List[object]
$dersiYok=New-Object System.Collections.Generic.List[object]
$kurtarilan=0
$elleKullanilan=0
$sozelBekleyen=New-Object System.Collections.Generic.List[object]
$doygun=0
foreach($x in $tekrar){
  $donem=[int]$x.donem
  $kat = if($donem -ge 5){ 5 } elseif($donem -ge 3){ 4 } else { 3 }
  $cikmis=[int]$x.cikmis
  $hedefSoru=[Math]::Max($Taban,[int]($cikmis*$kat/3))   # cikmis DONEM bazli; yila cevir (3 donem/yil)
  $kok=Katla4 "$($x.konu)"
  $mevcut=[int]$havuzKok[$kok]
  $eksik=[Math]::Max(0,$hedefSoru-$mevcut)
  $ders="$($x.bizim_ders)".Trim()
  $kaynak='kopru'
  # ⛔ SIRA: elle atama > kopru > ayristirici. Cem'in karari makineyi ezer.
  if($elle.ContainsKey($kok)){ $ders=$elle[$kok]; $kaynak='elle'; $elleKullanilan++ }
  elseif(-not $ders -and $ayristirma.ContainsKey($kok)){ $ders=$ayristirma[$kok]; $kaynak='ayristirici'; $kurtarilan++ }
  $kayit=[pscustomobject]@{ ders=$ders; konu="$($x.konu)"; donem=$donem; cikmis=$cikmis
                            kat=$kat; hedef=$hedefSoru; mevcut=$mevcut; eksik=$eksik; ders_kaynagi=$kaynak }
  if(-not $ders){ $dersiYok.Add($kayit); continue }                 # ⛔ ATLANMAZ, is emri olur
  if(-not $Sozel -and ($SOZEL_DERS -contains $ders)){ $sozelBekleyen.Add($kayit); continue }
  if($eksik -le 0){ $doygun++; continue }                            # ⛔ AYNI SORUYU BASMA
  $plan.Add($kayit)
}
$p=$plan.ToArray()
$toplamEksik=0; foreach($x in $p){ $toplamEksik+=[int]$x.eksik }

Write-Host "`n=== PLAN ===" -ForegroundColor Cyan
Write-Host ("  basilacak konu : {0,5:N0}" -f $p.Count)
Write-Host ("  basilacak soru : {0,5:N0}" -f $toplamEksik)
Write-Host ("  ~bedel         : {0,5:N0} USD  (olculen 0,48 USD/yayinlanabilir soru)" -f ($toplamEksik*0.48))
Write-Host ""
Write-Host ("  zaten DOYGUN (hedefi karsilanmis, basilmayacak) : {0,5:N0} konu" -f $doygun) -ForegroundColor Green
Write-Host ("  SOZEL hat (Cem karariyla bekliyor)              : {0,5:N0} konu" -f $sozelBekleyen.Count) -ForegroundColor DarkGray
Write-Host ("  ayristiriciyla KURTARILAN (koprude ders bostu)  : {0,5:N0} konu" -f $kurtarilan) -ForegroundColor Green
Write-Host ("  ⚠ DERSI HALA ATANMAMIS (uretilemez, is emri)    : {0,5:N0} konu" -f $dersiYok.Count) -ForegroundColor Yellow

Write-Host "`n=== DERS DERS ===" -ForegroundColor Cyan
foreach($g in (@($p|Group-Object ders)|Sort-Object{ ($_.Group|Measure-Object eksik -Sum).Sum } -Descending)){
  Write-Host ("  {0,-32} {1,4} konu · {2,4} soru" -f $g.Name,$g.Count,[int]($g.Group|Measure-Object eksik -Sum).Sum)
}
Write-Host "`n=== KAT DAGILIMI ===" -ForegroundColor Cyan
foreach($g in (@($p|Group-Object kat)|Sort-Object Name -Descending)){
  Write-Host ("  Kat {0} (donem {1}) · {2,4} konu · {3,4} soru" -f $g.Name,$(switch([int]$g.Name){5{'5+'}4{'3-4'}default{'2'}}),$g.Count,[int]($g.Group|Measure-Object eksik -Sum).Sum)
}

if($dersiYok.Count){
  Write-Host "`n⚠ DERSI ATANMAMIS EN SIK 10 (bunlar ATLANMADI - is emri):" -ForegroundColor Yellow
  foreach($x in (@($dersiYok.ToArray()|Sort-Object donem -Descending|Select-Object -First 10))){
    Write-Host ("   donem {0,2} · cikmis {1,3} · {2}" -f $x.donem,$x.cikmis,$x.konu) -ForegroundColor DarkYellow
  }
}

if($Yaz){
  $yol=Join-Path $depoKok $Hedef
  New-Item -ItemType Directory -Force (Split-Path $yol -Parent) | Out-Null
  [IO.File]::WriteAllText($yol,($p|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))
  Write-Host ("`nyazildi: {0}" -f $Hedef) -ForegroundColor Green

  # ⛔ KOSUCU BICIMI: parti bolme, zorluk dagitimi ve konu dosyasi yazma isini
  #    motor/plandan-parti-kur.ps1 ZATEN yapiyor ve 11.09'da sinandi. Onu
  #    yeniden yazmak yerine, plan onun BEKLEDIGI bicimde de yazilir:
  #      hat · ders · konu · cikmis · donem · yayinda · rafta · bizde · hedef · acik
  #    Boylece zincir tek: siklik-plani -> plandan-parti-kur -> kalip-kosucu.
  #    'hat' alani SIMDI/BEKLESIN ayrimini tasir (sozel BEKLESIN).
  $kosucuSatir=New-Object System.Collections.Generic.List[object]
  foreach($x in $p){
    $kosucuSatir.Add([ordered]@{ hat='SIMDI'; ders=$x.ders; konu=$x.konu; cikmis=[int]$x.cikmis
      donem=[int]$x.donem; yayinda=[int]$x.mevcut; rafta=0; bizde=[int]$x.mevcut
      hedef=[int]$x.hedef; acik=[int]$x.eksik; kat=[int]$x.kat })
  }
  foreach($x in $sozelBekleyen.ToArray()){
    $kosucuSatir.Add([ordered]@{ hat='BEKLESIN'; ders=$x.ders; konu=$x.konu; cikmis=[int]$x.cikmis
      donem=[int]$x.donem; yayinda=[int]$x.mevcut; rafta=0; bizde=[int]$x.mevcut
      hedef=[int]$x.hedef; acik=[int]$x.eksik; kat=[int]$x.kat })
  }
  $kosucuPlan=[ordered]@{
    olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
    kural='SIKLIK PLANI. Carpan SIKLIGA bagli (donem>=5 Kat 5, 3-4 Kat 4, 2 Kat 3); tek donemlik konu ALINMAZ (olculen olasilik %2,6). Hedeften havuzdaki mevcut DUSULMUS - ayni soru iki kez basilmaz. Ders sirasi: Cem elle atama > kopru > ayristirici.'
    cikmis_konu=$sgs.Count; bizde_soru=$havuz.Count
    acik_soru=$toplamEksik; acik_konu=$p.Count
    satirlar=@($kosucuSatir.ToArray())
  }
  $kosucuYol=Join-Path $depoKok 'veri\konu-plani-siklik.json'
  [IO.File]::WriteAllText($kosucuYol,($kosucuPlan|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
  Write-Host ("yazildi: veri/konu-plani-siklik.json (kosucu bicimi · {0} satir)" -f $kosucuSatir.Count) -ForegroundColor Green
  $isEmri=Join-Path $depoKok 'veri\dersi-atanmamis-konular.json'
  [IO.File]::WriteAllText($isEmri,(($dersiYok.ToArray())|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))
  Write-Host ("yazildi: veri/dersi-atanmamis-konular.json ({0} konu)" -f $dersiYok.Count) -ForegroundColor Yellow
}
