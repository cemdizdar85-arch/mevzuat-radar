#requires -Version 5.1
<#
================================================================================
  SORU AMBARI GERI YUKLEME  (12.09.2026, Cem "1.2.3 ucunu de yap")

  ⛔ YEDEK ANCAK GERI YUKLENEBILIYORSA YEDEKTIR. 12.09 sabahi sifreli bulut
     yedegi kuruldu ama geri yukleme yolu YOKTU - "yedegim var" demek, acilip
     yazilabildigi OLCULENE kadar iddiadir.

  NE YAPAR: cozulmus NDJSON dosyalarini (motor/soru-ambar-yedek-coz.ps1 ciktisi)
  ambara geri yazar.

  ⛔ IKI KIP - VARSAYILAN OLAN GUVENLI OLANI:
     -Eksikler (VARSAYILAN) : yalniz ambarda BULUNMAYAN satirlari ekler.
                              Canli veriye DOKUNMAZ. Kismi kayipta dogru kip.
     -Hepsi                 : her satiri upsert eder, ambardakini EZER.
                              Yalniz tablo tamamen kaybolduysa. Onay cumlesi ister.

  ⛔ VARSAYILAN KURU KOSU. -Yaz demeden HICBIR yazma yapilmaz. Ne yazilacagini
     once gorursun. (09.09 dersi: bir betigi "sinamak icin" calistirmak 5,75 USD
     goturdu; o gunden beri para/veri harcayan hicbir betik kendiliginden yazmaz.)

  ⛔ BEDEL 0 - model cagrisi YOK, yalniz ambar yazma.

  KULLANIM
    # 1) once oku, ne olacagini gor (kuru kosu)
    powershell -NoProfile -File motor/soru-ambar-geri-yukle.ps1 -Klasor <cozulmus klasor>
    # 2) eksikleri tamamla
    powershell -NoProfile -File motor/soru-ambar-geri-yukle.ps1 -Klasor <klasor> -Yaz
    # 3) tablo tamamen gittiyse (EZER)
    powershell -NoProfile -File motor/soru-ambar-geri-yukle.ps1 -Klasor <klasor> -Hepsi -Yaz -Onay "AMBARI EZMEYI ONAYLIYORUM"
================================================================================
#>
param(
  [Parameter(Mandatory=$true)][string]$Klasor,
  [string[]]$Tablolar = @(),        # bos = klasorde bulunan her tablo
  [switch]$Hepsi,                   # upsert (EZER). Yoksa yalniz eksikler eklenir.
  [switch]$Yaz,                     # olmadan: kuru kosu
  [string]$Onay = '',               # -Hepsi icin zorunlu onay cumlesi
  [int]$Parti = 200                 # tek istekte kac satir
)
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok=Split-Path -Parent $buDizin

if($Hepsi -and $Yaz -and $Onay -ne 'AMBARI EZMEYI ONAYLIYORUM'){
  throw '-Hepsi -Yaz icin onay cumlesi sart: -Onay "AMBARI EZMEYI ONAYLIYORUM"'
}
if(-not (Test-Path $Klasor)){ throw "klasor yok: $Klasor" }

$AMBAR_ANAHTAR="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $AMBAR_ANAHTAR){ $AMBAR_ANAHTAR="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $AMBAR_ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok.' }
# ⛔ Ad UZUN: kisa $ANAHTAR bir $anahtar tarafindan ezilirdi (PS harf AYIRMAZ).
$AMBAR_BASLIK=@{ apikey=$AMBAR_ANAHTAR; Authorization="Bearer $AMBAR_ANAHTAR"
                 'Content-Type'='application/json'; Accept='application/json'
                 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR_TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# tablo -> birincil anahtar (soru-ambar-yedek.ps1 ile AYNI tablo; kopya tutulmaz diye
# burada da acikca yazili - iki dosyada iki farkli liste olsaydi biri eskir).
$PK=[ordered]@{ 'dokumanlar'='id'; 'soru_havuzu'='id'; 'konu_koprusu'='id'
                'bedel_kaydi'='id'; 'kalip_parti'='etiket' }

function AmbardakiAnahtarlar([string]$tablo,[string]$pkAlan){
  $kume=@{}
  $imlec=$null
  while($true){
    $adres=$AMBAR_TABAN+'/'+$tablo+'?select='+$pkAlan+'&order='+$pkAlan+'.asc&limit=1000'
    if($imlec -ne $null){ $adres+='&'+$pkAlan+'=gt.'+[uri]::EscapeDataString("$imlec") }
    $cevap=$null
    try{ $cevap=Invoke-RestMethod -Uri $adres -Headers $AMBAR_BASLIK -TimeoutSec 180 }
    catch{ throw ("$tablo anahtarlari okunamadi: " + $_.Exception.Message) }
    $satirlar=@($cevap)
    if(-not $satirlar.Count){ break }
    foreach($s in $satirlar){ $kume["$($s.$pkAlan)"]=$true }
    $imlec=$satirlar[-1].$pkAlan
    if($satirlar.Count -lt 1000){ break }
  }
  return $kume
}

function PartiYaz([string]$tablo,[string]$pkAlan,$satirlar){
  $govde=((Dizi2 $satirlar)|ConvertTo-Json -Depth 20)
  if($satirlar.Count -eq 1){ $govde='['+(($satirlar[0])|ConvertTo-Json -Depth 20)+']' }
  $bayt=[Text.Encoding]::UTF8.GetBytes($govde)
  $b=$AMBAR_BASLIK.Clone()
  $b['Prefer']='resolution=merge-duplicates,return=minimal'
  [void](Invoke-RestMethod -Method Post -Uri ($AMBAR_TABAN+'/'+$tablo+'?on_conflict='+$pkAlan) -Headers $b -Body $bayt -TimeoutSec 300)
}
# List[object] -> dizi. @($list) tr-TR PS 5.1'de ArgumentException atar.
function Dizi2($x){ if($null -eq $x){ return @() }; if($x -is [System.Collections.Generic.List[object]]){ return $x.ToArray() }; return @($x) }

$dosyalar=@(Get-ChildItem $Klasor -Filter 'soru-ambar-*.ndjson'|Where-Object{ $_.Name -notmatch 'kunye' })
if(-not $dosyalar.Count){ throw "cozulmus .ndjson dosyasi yok: $Klasor (once motor/soru-ambar-yedek-coz.ps1)" }

Write-Host ("KIP: {0} · {1}" -f $(if($Hepsi){'HEPSI (EZER)'}else{'EKSIKLER (canliya dokunmaz)'}),$(if($Yaz){'YAZILACAK'}else{'KURU KOSU'})) -ForegroundColor $(if($Hepsi -and $Yaz){'Red'}else{'Cyan'})
$ozet=New-Object System.Collections.Generic.List[object]

foreach($dosya in $dosyalar){
  if($dosya.Name -notmatch 'soru-ambar-[\d\-]+-(.+)\.ndjson$'){ continue }
  $tablo=$Matches[1]
  if($Tablolar.Count -and ($Tablolar -notcontains $tablo)){ continue }
  if(-not $PK.Contains($tablo)){ Write-Host ("  {0,-14} ATLANDI (bilinmeyen tablo)" -f $tablo) -ForegroundColor Yellow; continue }
  $pkAlan=$PK[$tablo]

  $mevcut=@{}
  if(-not $Hepsi){ $mevcut=AmbardakiAnahtarlar $tablo $pkAlan }

  $okunan=0; $yazilacak=0; $yazilan=0; $hata=0
  $tampon=New-Object System.Collections.Generic.List[object]
  $okuyucu=New-Object System.IO.StreamReader($dosya.FullName,(New-Object Text.UTF8Encoding $false))
  try{
    while($true){
      $satir=$okuyucu.ReadLine()
      if($null -eq $satir){ break }
      if(-not $satir.Trim()){ continue }
      $okunan++
      $nesne=$null
      try{ $nesne=$satir|ConvertFrom-Json }catch{ $hata++; continue }
      if(-not $Hepsi -and $mevcut.ContainsKey("$($nesne.$pkAlan)")){ continue }
      $yazilacak++
      if(-not $Yaz){ continue }
      $tampon.Add($nesne)
      if($tampon.Count -ge $Parti){
        try{ PartiYaz $tablo $pkAlan (Dizi2 $tampon); $yazilan+=$tampon.Count }
        catch{ Write-Host ("    ! parti yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$tampon.Count }
        $tampon=New-Object System.Collections.Generic.List[object]
        if($yazilan % 2000 -eq 0){ Write-Host ("    ... {0:N0}" -f $yazilan) -ForegroundColor DarkGray }
      }
    }
    if($Yaz -and $tampon.Count){
      try{ PartiYaz $tablo $pkAlan (Dizi2 $tampon); $yazilan+=$tampon.Count }
      catch{ Write-Host ("    ! son parti yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$tampon.Count }
    }
  } finally{ $okuyucu.Dispose() }

  $renk=$(if($hata){'Red'}elseif($yazilacak){'Yellow'}else{'Green'})
  Write-Host ("  {0,-14} dosyada {1,7:N0} · ambarda {2,7:N0} · {3} {4,6:N0} · hata {5}" -f `
    $tablo,$okunan,$mevcut.Count,$(if($Yaz){'yazildi'}else{'yazilacak'}),$(if($Yaz){$yazilan}else{$yazilacak}),$hata) -ForegroundColor $renk
  $ozet.Add([pscustomobject]@{ tablo=$tablo; dosya=$okunan; ambarda=$mevcut.Count; islenen=$(if($Yaz){$yazilan}else{$yazilacak}); hata=$hata })
}

if(-not $Yaz){
  Write-Host "`nKURU KOSU - ambara HICBIR SEY yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow
  return
}
# ⛔ YAZ -> GERI OKU -> KARSILASTIR
Write-Host "`nGERI OKUMA (dogrulama):" -ForegroundColor Cyan
$eksik=0
foreach($o in (Dizi2 $ozet)){
  $b=$AMBAR_BASLIK.Clone(); $b['Prefer']='count=exact'
  $sayi=-1
  try{
    $y=Invoke-WebRequest -Uri ($AMBAR_TABAN+'/'+$o.tablo+'?select=*&limit=1') -Headers $b -TimeoutSec 120 -UseBasicParsing
    $sayi=[int](("$($y.Headers['Content-Range'])") -split '/')[-1]
  }catch{}
  $tam=($sayi -ge [int]$o.dosya)
  if(-not $tam){ $eksik++ }
  Write-Host ("  {0,-14} ambarda {1,7:N0} · dosyada {2,7:N0} {3}" -f $o.tablo,$sayi,[int]$o.dosya,$(if($tam){'✓'}else{'⛔ EKSIK'})) -ForegroundColor $(if($tam){'Green'}else{'Red'})
}
if($eksik){ throw "GERI YUKLEME DOGRULAMASI DUSTU: $eksik tabloda satir sayisi dosyadan az." }
Write-Host "`n✓ geri yukleme TAM - her tabloda ambar >= dosya." -ForegroundColor Green
