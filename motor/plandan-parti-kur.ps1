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
  [ValidatePattern('^[a-z0-9-]{2,16}$')]
  [string]$EtiketOn = 'sgs-p',   # 12.09: etiket oneki - YENI PLAN = YENI ONEK (cakisma onlemi)
  [switch]$AyristirilamayanDahil, # kaba kovada kalmis konular da girsin mi
  [switch]$BayatGec,             # 13.09: BAYAT ONBELLEK kapisini bilerek atla (gerekce ZORUNLU)
  [string]$BayatGerekce = ''     # 13.09: -BayatGec verildiyse niye atlandigi
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

# ⛔⭐ BAYAT ONBELLEK KAPISI (13.09.2026) — "AYNI SORU IKI KEZ YOK" KURALININ MEKANIK HALI
#   OLAY: d3 dalgasini kurarken konu plani "bizdeki saglam soru 3.042" dedi. Ama o gece
#   668 soru basmistik. Sebep: uretim BULUTTA kosuyor, plan kurma YERELDE; bulutta
#   uretilen partiler ambara yaziliyor ama yerel onbellege inmiyor. Plan sessizce
#   ESKI FOTOGRAFLA calisiyordu ve gece bastigimiz konulari IKINCI KEZ bastiracakti.
#   Onbellek indirilince: 3.042 -> 3.220 saglam soru, ACIK 5.431 -> 5.253.
#   Yani bu kapi olmasaydi ~111 USD dogrudan cope gidecekti - ve KIMSE FARK ETMEYECEKTI,
#   cunku plan hata vermez, yalnizca bayat sayiyla dogru gorunen bir plan uretir.
#   ⚠ Bu kusuru yakalamam SANSA bagliydi (rakamin degismedigini fark ettim). Sans
#     kapi degildir; kapi burada.
#
#   OLCUM: ambardaki parti sayisi (metadata listesi, ucuz) vs yereldeki dosya sayisi.
#   Ambar ILERIDEYSE plan KURULMAZ. Bilerek gecmek icin -BayatGec + gerekce.
if(-not $BayatGec){
  $yerelP = @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json' -ErrorAction SilentlyContinue).Count
  $ambarP = -1
  try{
    $cikti = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $depoKok 'arac\parti-senkron.ps1') -Indir -Sinav $Sinav 2>&1
    foreach($satir in @($cikti)){ if("$satir" -match 'ambarda parti:\s*([\d\.]+)'){ $ambarP=[int](($matches[1]) -replace '\.','') } }
  }catch{ Write-Host "  bayat onbellek kapisi: ambar okunamadi ($($_.Exception.Message.Split([char]10)[0])) - kapi ATLANDI" -ForegroundColor DarkYellow }
  if($ambarP -ge 0){
    if($ambarP -gt $yerelP){
      throw ("BAYAT ONBELLEK - PLAN KURULMADI. Ambarda {0} parti var, yerelde {1}. Aradaki {2} parti BULUTTA uretilmis ve burada YOK; bu haliyle plan o konulari IKINCI KEZ bastirir (para iki kez odenir). Once sunu kos:`n  powershell -NoProfile -File arac/parti-senkron.ps1 -Indir -Yaz`nSonra konu planini tazele (motor/konu-plani.ps1) ve bu betigi yeniden kos.`nBilerek gecmek icin: -BayatGec -BayatGerekce '<neden>'" -f $ambarP,$yerelP,($ambarP-$yerelP))
    }
    Write-Host ("bayat onbellek kapisi: YESIL (ambar {0} · yerel {1})" -f $ambarP,$yerelP) -ForegroundColor DarkGreen
  }
} else {
  if(-not "$BayatGerekce".Trim()){ throw '-BayatGec verildi ama -BayatGerekce BOS. Istisna gerekcesiz yapilmaz.' }
  Write-Host "⚠ BAYAT ONBELLEK KAPISI BILEREK ATLANDI · gerekce: $BayatGerekce" -ForegroundColor Yellow
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
        # ⛔⭐ 12.09.2026 — ETIKET ONEKI PARAMETRE OLDU. Onceden sabit "sgs-p-"
        #    idi ve bu SESSIZ BIR CAKISMA FABRIKASIYDI: ayni betikle kurulan iki
        #    AYRI plan ayni etiketleri uretiyordu (sgs-p-fmuh-kolay-r1 ...).
        #    Bugun yakalandi: 73 bos cekirdek konu icin kurulan 80 partinin
        #    14'unun etiketi onbellekte ZATEN VARDI (A/B kosusundan).
        #    O plan boyle basilsa, hafizadaki TOPLU HASAT TUZAGI isleyecekti:
        #    uretici ayni etiket/faz icin onceki partinin cevaplarini bedavaya
        #    hasat eder; sorular farkli oldugu icin kor/hakem2 YANLIS eslesir
        #    (10.09'da Meslek'te 13 sahte "kor yanlis" boyle dogmustu).
        #    Kural: YENI PLAN = YENI ONEK.
        $et = "$EtiketOn-$kis-$zorAd-r$tur" + $(if($parca -gt 1){ "-$parca" } else { '' })
        $kd = Join-Path $konuDir "$et.json"
        $adlar=@($konular | ForEach-Object { "$($_.konu)" })
        [IO.File]::WriteAllText($kd,($adlar|ConvertTo-Json -Depth 3),(New-Object Text.UTF8Encoding $false))
        $planSatir.Add([pscustomobject][ordered]@{
          ders="$($g.Name)"; dersAd="$($g.Name)"; etiket=$et
          adet=$konular.Count           # = konu sayisi = uretilecek soru sayisi
          # ⛔ 12.09: konuDosya DEPOYA GORECE yazilir. Mutlak yerel yol
          #    ("C:\Users\cemdi\...") bulut runner'inda cozulmez; uretici de
          #    eskiden sessizce atliyordu -> yanlis konularla uretim.
          #    854 yol bu tarihte 37 plan dosyasinda goreceye cevrildi.
          zorluk=$zorAd; sinav='SGS'; konuDosya=("veri/sinav/konu/$et.json"); toplu=$true; disla=''; tur=$tur
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
