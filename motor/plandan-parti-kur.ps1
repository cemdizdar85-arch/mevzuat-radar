#requires -Version 5.1
<#
================================================================================
  PLANDAN PARTI KUR — konu planini URETIM EMRINE cevirir  (11.09.2026)
  Cem: "konu plana gore soru basacagiz"

  NIYE VAR: 11.09'a kadar zincirin ortasinda ELLE bir adim vardi —
      konu-plani-sgs.json  ->  (ELLE)  ->  veri/sinav/konu/<etiket>.json
                           ->  kalip-kosucu.ps1
  "Plana gore bastik" iddiasi o elle adima dayaniyordu; sapma olursa kimse
  gormezdi. Bu betik o adimi kaldirir: plan dosyasindan DOGRUDAN konu
  dosyalarini ve kosucu planini uretir. Artik "plana gore bastik" OLCULEBILIR
  bir iddia: hangi konudan kac soru istendi, kac basildi, farki ne.

  NE YAPAR:
    1) veri/konu-plani-<sinav>.json okur
    2) HAT ve ONCELIK suzgecini uygular (-Hat SIMDI · -EnAzCikmis 3)
    3) Konulari DERS ve ZORLUK'a gore partilere boler
    4) veri/sinav/konu/<etiket>.json + veri/sinav/plan-<ad>.json yazar

  ZORLUK NEDEN DAGITILIR: sinav anatomisi olcumunde SGS'in zorluk dagilimi
  sabit degil; tek zorlukta basmak sinav gibi olmaz. Konular cikmis sikliga
  gore siralanir ve kolay/zor/cokzor partilerine SIRAYLA dagitilir - boylece
  cok cikan konu her zorlukta temsil edilir.

  ⛔ HICBIR SORU BASMAZ. Yalniz dosya yazar. Uretim ayri komut:
     powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan <uretilen plan>

  BEDEL 0.
================================================================================
#>
param(
  [ValidateSet('SGS','SMMM','KGK')][string]$Sinav = 'SGS',
  [ValidateSet('SIMDI','BEKLESIN','HEPSI')][string]$Hat = 'SIMDI',
  [int]$EnAzCikmis = 3,          # cikmis arsivde en az kac kez gorulmus konu
  [int]$PartiTavan = 30,         # tek partide en fazla kac KONU (=soru, uretici konu basina 1 soru yazar)
  [int]$TurTavan   = 4,          # bir konudan en fazla kac TUR (r1..rN) kosulsun
  [string]$Ad = '',              # plan adi (bos: otomatik)
  [string]$PlanDosyasi = '',     # 12.09: konu plani yolu (bos: veri\konu-plani-<sinav>.json)
  [int]$EnAzKat = 0,             # 12.09: siklik plani icin - yalniz bu Kat ve ustu
  [switch]$AyristirilamayanDahil # kaba kovada kalmis konular da girsin mi
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

# --- OLCUM KAPILARI (11.09, Cem "olcum araclarina oz-sinav ekle") -------------
# Bu betik OLCUM yapar; olcum aracinin kendisi bozuksa cikan rakam yanlis KARAR
# urettirir (11.09'da dort kez oldu). Oz-sinav kirmizi donerse HIC olcmez.
. (Join-Path $depoKok 'arac\olcum-kapilari.ps1')
$ok_kusur=Test-OlcumKapilari -Sessiz
if((Dizi $ok_kusur).Count){
  Write-Host '⛔ OLCUM KAPILARI KIRMIZI - bu olcume guvenilmez:' -ForegroundColor Red
  foreach($h in (Dizi $ok_kusur)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'olcum kapilari oz-sinavi dustu'
}

if(-not $Ad){ $Ad = ("{0}-c{1}-{2}" -f $Sinav.ToLowerInvariant(),$EnAzCikmis,(Get-Date -Format 'ddMM')) }

# ⚠ 12.09: plan yolu artik DISARIDAN verilebilir (-PlanDosyasi). Sebep: siklik
#   plani (arac/siklik-plani.ps1) ayri bir dosyaya yaziyor ve bu betigi yeniden
#   yazmak yerine ONU beslemek dogru - parti bolme, zorluk dagitimi ve konu
#   dosyasi yazma burada zaten sinanmis durumda. Verilmezse eski davranis.
$planYol=$(if($PlanDosyasi){ $(if([IO.Path]::IsPathRooted($PlanDosyasi)){ $PlanDosyasi }else{ Join-Path $depoKok $PlanDosyasi }) }
           else { Join-Path $depoKok ('veri\konu-plani-'+$Sinav.ToLowerInvariant()+'.json') })
if(-not (Test-Path $planYol)){ throw "konu plani yok: $planYol  (once motor/konu-plani.ps1 -Sinav $Sinav)" }
$pj=Get-Content $planYol -Raw -Encoding UTF8|ConvertFrom-Json
$sat=@($pj.satirlar)
Write-Host ("konu plani: {0:N0} satir (olcum {1})" -f $sat.Count,$pj.olcum) -ForegroundColor Cyan

# --- SUZGEC ------------------------------------------------------------------
$sec=@($sat | Where-Object {
  [int]$_.acik -gt 0 -and
  [int]$_.cikmis -ge $EnAzCikmis -and
  ($Hat -eq 'HEPSI' -or "$($_.hat)" -eq $Hat) -and
  ($AyristirilamayanDahil -or "$($_.ders)" -notmatch 'ayristirilamadi') -and
  # 12.09: siklik planinda her satir 'kat' tasir. -EnAzKat 5 verilirse yalniz
  # en sik cikan konular alinir (olculen olasilik: 5+ donem -> %21,6 / %63,2).
  ($EnAzKat -le 0 -or ($_.PSObject.Properties['kat'] -and [int]$_.kat -ge $EnAzKat))
})
$topSoru=0; foreach($sc in $sec){ $topSoru+=[int]$sc.acik }
Write-Host ("suzgec: hat={0} · cikmis>={1} · ayristirilamayan {2}" -f $Hat,$EnAzCikmis,$(if($AyristirilamayanDahil){'DAHIL'}else{'HARIC'}))
Write-Host ("  -> {0:N0} konu · {1:N0} soru" -f $sec.Count,$topSoru) -ForegroundColor Green
if(-not $sec.Count){ throw 'Suzgecten konu gecmedi - esikleri gevset.' }

# --- DERS BAZLI PARTILEME ----------------------------------------------------
# Etiket kisaltmalari: kosucu ve ders-cozumleyiciler bu kisa adlari taniyor.
$KISALT=@{
  'Finansal Muhasebe'='fmuh'; 'Denetim'='denetim'; 'Maliyet Muhasebesi'='maliyet'
  'Mali Tablolar Analizi'='mta'; 'Ticaret Hukuku'='ticaret'; 'Borclar Hukuku'='borclar'
  'Vergi Hukuku'='vergi'; 'Meslek Hukuku'='meslek'; 'Is ve Sosyal Guvenlik Hukuku'='issgk'
  'Ekonomi'='ekonomi'; 'Maliye'='maliye'; 'Matematik'='mat'; 'Turkce'='turkce'
  'Yabanci Dil'='yd'; 'Ataturk Ilke ve Inkilap Tarihi'='inkilap'
  'Ataturk Ilkeleri ve Inkilap Tarihi'='inkilap'
}
$ZORLUK=@('kolay','zor','cokzor')
$konuDir=Join-Path $depoKok 'veri\sinav\konu'
New-Item -ItemType Directory -Force $konuDir | Out-Null

$planSatir=New-Object System.Collections.Generic.List[object]
$yazilanKonu=0; $tanimsizDers=@{}
foreach($g in (@($sec | Group-Object ders | Sort-Object { $s=0; foreach($pg in $_.Group){ $s+=[int]$pg.acik }; -$s }))){
  $kis=$KISALT["$($g.Name)"]
  if(-not $kis){ $tanimsizDers["$($g.Name)"]=$g.Count; continue }   # etiketi bilinmeyen ders ATLANIR, sessizce degil
  # Cikmis sikliga gore sirala; zorluk kovalarina SIRAYLA dagit (cok cikan konu her zorlukta olsun)
  # ⚠ Degisken adlari BILEREK uzun: Sort-Object/Group-Object scriptblock'lari
  #   CAGIRANIN kapsaminda kosar ve kisa adlari ($z, $k, $s) disaridan ezer.
  #   11.09'da "$kova[$z]" boyle bozulup ArgumentException atti.
  $siraliKonu=@($g.Group | Sort-Object @{e={[int]$_.cikmis};Descending=$true})
  $zorlukKova=@{}
  foreach($zorAd in $ZORLUK){ $zorlukKova[$zorAd]=New-Object System.Collections.Generic.List[object] }
  $dagitimSira=0
  foreach($konuK in $siraliKonu){
    $hedefZor=$ZORLUK[$dagitimSira % $ZORLUK.Count]
    $zorlukKova[$hedefZor].Add($konuK); $dagitimSira++
  }
  foreach($zorAd in $ZORLUK){
    # ⛔ PS 5.1 TUZAGI (11.09'da BURADA yakalandi, tr-TR 5.1.26100):
    #    @($list)  -- $list bir List[object] ise -- "Bagimsiz degisken turleri
    #    eslesmiyor" (ArgumentException) atar. Sebep @() sarmalayicisinin
    #    List[object]'i object[]'e kopyalamasi. .ToArray() SORUNSUZ calisir.
    #    Bu depoda List[object] cok kullaniliyor; @() ile SARMAYIN.
    $liste=$zorlukKova[$zorAd].ToArray(); if(-not $liste.Count){ continue }
    # ⛔ 11.09 OLCULDU: URETICI KONU BASINA TAM 1 SORU yazar. Uc partide
    #    olculdu, oran 1,00 (fmuh-cokzor 111 soru/111 konu · borclar-zor 18/18 ·
    #    denetim-zor 29/29). Ilk surumde partileri SORU sayisina gore
    #    boyutlandirmistim; 43 parti 893 degil 169 soru uretecekti.
    #    Bir konudan N soru istiyorsak o konu N AYRI TURDA kosar (r1, r2, ...) -
    #    depoda zaten bu desen var (sgs-a6-denetim-cokzor-r1).
    #    Parti boyu artik KONU sayisiyla olculur.
    $enCokTur=0; foreach($k in $liste){ if([int]$k.acik -gt $enCokTur){ $enCokTur=[int]$k.acik } }
    if($enCokTur -gt $TurTavan){ $enCokTur=$TurTavan }
    for($tur=1; $tur -le $enCokTur; $tur++){
      # bu turda kosacak konular: `acik` degeri tur numarasina yetenler
      $turKonu=@($liste | Where-Object { [int]$_.acik -ge $tur })
      if(-not $turKonu.Count){ continue }
      $parca=0
      for($bas=0; $bas -lt $turKonu.Count; $bas+=$PartiTavan){
        $parca++
        $son=[Math]::Min($bas+$PartiTavan-1,$turKonu.Count-1)
        $konular=@($turKonu[$bas..$son])
        $et = "sgs-p-$kis-$zorAd-r$tur" + $(if($parca -gt 1){ "-$parca" } else { '' })
        $kd = Join-Path $konuDir "$et.json"
        $adlar=@($konular | ForEach-Object { "$($_.konu)" })
        [IO.File]::WriteAllText($kd,($adlar|ConvertTo-Json -Depth 3),(New-Object Text.UTF8Encoding $false))
        $planSatir.Add([pscustomobject][ordered]@{
          ders="$($g.Name)"; dersAd="$($g.Name)"; etiket=$et
          adet=$konular.Count           # = konu sayisi = uretilecek soru sayisi
          zorluk=$zorAd; sinav='SGS'; konuDosya=$kd; toplu=$true; disla=''; tur=$tur
        })
        $yazilanKonu+=$konular.Count
      }
    }
  }
}

$planDosya=Join-Path $depoKok "veri\sinav\plan-$Ad.json"
[IO.File]::WriteAllText($planDosya,($planSatir.ToArray()|ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))

$topPlanSoru=0; foreach($ps2 in $planSatir.ToArray()){ $topPlanSoru+=[int]$ps2.adet }
Write-Host ""
Write-Host ("PARTI PLANI: {0} parti · {1:N0} konu · {2:N0} soru" -f $planSatir.Count,$yazilanKonu,$topPlanSoru) -ForegroundColor Green
foreach($g in (@($planSatir.ToArray()|Group-Object dersAd|Sort-Object { $s=0; foreach($pg in $_.Group){ $s+=[int]$pg.adet }; -$s }))){
  $s=0; foreach($pg in $g.Group){ $s+=[int]$pg.adet }
  Write-Host ("  {0,-32} {1,2} parti · {2,4} soru" -f $g.Name,$g.Count,$s)
}
if($tanimsizDers.Count){
  Write-Host ""
  Write-Host "  ETIKET KISALTMASI OLMAYAN DERS (plana ALINMADI):" -ForegroundColor Yellow
  foreach($k in ($tanimsizDers.GetEnumerator()|Sort-Object Value -Descending)){ Write-Host ("    {0,-40} {1,4} konu" -f $k.Key,$k.Value) }
}
Write-Host ""
Write-Host "-> $planDosya" -ForegroundColor Green
Write-Host "-> veri/sinav/konu/sgs-p-*.json ($($planSatir.Count) dosya)"
Write-Host ""
Write-Host "URETIM (ayri komut, BU BETIK SORU BASMAZ):" -ForegroundColor Cyan
Write-Host "  powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-$Ad.json"
