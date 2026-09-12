#requires -Version 5.1
<#
================================================================================
  SORU AMBARI YEDEGI — dokum betigi  (12.09.2026, Cem "1 sen yap")

  NIYE VAR: 11.09 gecesi uretimin uc yerel durumu ambara tasindi (kalip_parti,
  bedel_kaydi, konu_koprusu). O ana kadar her sey IKI yerdeydi - Cem'in
  dizustunde VE ambarda; yani yedek kendiliginden vardi. Bulut uretimine
  gecince o ikilik BITIYOR: uretim yalniz ambara yazacak, tek kopya kalacak.
  Alacak kasasinin sifreli bulut yedegi 07.09'da kurulmustu; SORU AMBARININ
  boyle bir yedegi YOKTU. Bu betik o acigi kapatir.

  NE YEDEKLENIR (olculdu 12.09 07:30):
    dokumanlar    45.741  <- TAC MUCEVHER. Yutulmus mevzuat. Kaynaklarin bir
                             kismi artik KAPALI (TMview ag duzeyinde kapali,
                             mevzuat.gov.tr yalniz TR-IP); yeniden yutmak
                             haftalar surer, bir kismi hic geri gelmez.
    soru_havuzu   30.569  <- yayin havuzu, insan onayi tasiyan satirlar var
    konu_koprusu  21.292  <- cikmis sinav arsivinden turetilmis siklik
    bedel_kaydi      423  <- harcama defteri
    kalip_parti      298  <- uretim onbellegi (soru metni + hakem kararlari)

  ⛔ SIFRELEME BURADA YAPILMAZ. Bu betik duz NDJSON yazar; sifreleme akista
     (.github/workflows/soru-ambar-yedek.yml) openssl ile yapilir - alacak
     kasasiyla AYNI desen, AYNI acik anahtar (motor/anahtar/alacak-yedek.pub).
     Depo PUBLIC oldugu icin artifact'i herkes indirebilir; sifresiz birakilan
     yedek, yedek degil SIZINTIDIR (08.09'da 7 sifresiz artifact silinmisti).

  ⛔ SAYFALAMA OFFSET ILE YAPILMAZ. Olculdu (08.09): offset 15.000'de HTTP 500,
     25.000'de 57014 timeout. Imlec (keyset) kullanilir: order=<pk>.asc +
     <pk>=gt.<son>. 45.741 satirlik dokumanlar ancak boyle iner.

  ⛔ BELLEGE TOPLANMAZ. dokumanlar ~200 MB; satirlar diske AKITILIR.

  KULLANIM
    $env:YEDEK_KOK='C:\gecici\_yedek'; powershell -NoProfile -File motor/soru-ambar-yedek.ps1
  BEDEL 0 - yalniz ambar okuma.
================================================================================
#>
param(
  [string]$Kok = '',                 # cikti klasoru (bos = $env:YEDEK_KOK ya da _yedek)
  [string[]]$Tablolar = @()          # bos = varsayilan liste
)
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok=Split-Path -Parent $buDizin

if(-not $Kok){ $Kok="$($env:YEDEK_KOK)".Trim() }
if(-not $Kok){ $Kok=Join-Path $depoKok '_yedek' }
New-Item -ItemType Directory -Force $Kok | Out-Null

$AMBAR_ANAHTAR="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $AMBAR_ANAHTAR){ $AMBAR_ANAHTAR="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $AMBAR_ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok - yedek alinamaz.' }
# ⛔ Ad UZUN. Kisa $ANAHTAR yazilsaydi asagidaki bir $anahtar onu ezerdi
#    (PS harf AYIRMAZ). Bu tuzaga 11.09'da ALTI kez dusuldu; bkz CLAUDE.md.
$AMBAR_BASLIK=@{ apikey=$AMBAR_ANAHTAR; Authorization="Bearer $AMBAR_ANAHTAR"
                 Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR_TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# tablo -> birincil anahtar (imlec alani). Sirali imlec icin TEKIL olmali.
$VARSAYILAN=[ordered]@{
  'dokumanlar'   = 'id'
  'soru_havuzu'  = 'id'
  'konu_koprusu' = 'id'
  'bedel_kaydi'  = 'id'
  'kalip_parti'  = 'etiket'
}
if($Tablolar.Count){
  $secili=[ordered]@{}
  foreach($t in $Tablolar){ if($VARSAYILAN.Contains($t)){ $secili[$t]=$VARSAYILAN[$t] } else { throw "bilinmeyen tablo: $t" } }
  $VARSAYILAN=$secili
}

function SatirSayisi([string]$tablo){
  $b=$AMBAR_BASLIK.Clone(); $b['Prefer']='count=exact'
  try{
    $y=Invoke-WebRequest -Uri ($AMBAR_TABAN+'/'+$tablo+'?select=*&limit=1') -Headers $b -TimeoutSec 120 -UseBasicParsing
    return [int](("$($y.Headers['Content-Range'])") -split '/')[-1]
  }catch{ return -1 }
}

$damga=(Get-Date -Format 'yyyyMMdd-HHmm')
$kunye=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); damga=$damga; tablolar=@() }
$toplamSatir=0; $toplamBayt=0

foreach($tablo in $VARSAYILAN.Keys){
  $imlecAlan=$VARSAYILAN[$tablo]
  $beklenen=SatirSayisi $tablo
  $hedef=Join-Path $Kok ("soru-ambar-$damga-$tablo.ndjson")
  Write-Host ("{0,-14} bekleniyor {1,7:N0} satir -> {2}" -f $tablo,$beklenen,(Split-Path $hedef -Leaf)) -ForegroundColor Cyan

  # ⚠ StreamWriter: 200 MB'lik tablo bellege TOPLANMAZ, satir satir akitilir.
  $yazici=New-Object System.IO.StreamWriter($hedef,$false,(New-Object Text.UTF8Encoding $false))
  $sayac=0; $imlec=$null; $sayfa=0
  try{
    while($true){
      $adres=$AMBAR_TABAN+'/'+$tablo+'?select=*&order='+$imlecAlan+'.asc&limit=1000'
      if($imlec -ne $null){ $adres+='&'+$imlecAlan+'=gt.'+[uri]::EscapeDataString("$imlec") }
      $cevap=$null
      foreach($deneme in 1..3){
        try{ $cevap=Invoke-RestMethod -Uri $adres -Headers $AMBAR_BASLIK -TimeoutSec 300; break }
        catch{
          if($deneme -eq 3){ throw ("$tablo sayfa $sayfa okunamadi: " + $_.Exception.Message) }
          Start-Sleep -Seconds (5*$deneme)   # 57014 gecici olabilir (AMBAR-OLCUM-TUZAKLARI)
        }
      }
      $satirlar=@($cevap)
      if(-not $satirlar.Count){ break }
      foreach($satir in $satirlar){
        $yazici.WriteLine(($satir|ConvertTo-Json -Depth 20 -Compress))
        $sayac++
      }
      $imlec=$satirlar[-1].$imlecAlan
      $sayfa++
      if($satirlar.Count -lt 1000){ break }
      if($sayfa % 10 -eq 0){ Write-Host ("   ... {0:N0}" -f $sayac) -ForegroundColor DarkGray }
    }
  } finally { $yazici.Close(); $yazici.Dispose() }

  $boy=(Get-Item $hedef).Length
  $toplamSatir+=$sayac; $toplamBayt+=$boy
  # ⛔ YAZ -> GERI OKU -> KARSILASTIR. Eksik yedek, yedek degildir.
  $tam = ($beklenen -lt 0) -or ($sayac -ge $beklenen)
  $kunye.tablolar+=[ordered]@{ tablo=$tablo; beklenen=$beklenen; yazilan=$sayac; bayt=$boy; tam=$tam }
  $renk=$(if($tam){'Green'}else{'Red'})
  Write-Host ("{0,-14} YAZILDI {1,7:N0} satir · {2,8:N1} MB · {3}" -f $tablo,$sayac,($boy/1MB),$(if($tam){'TAM'}else{'⛔ EKSIK'})) -ForegroundColor $renk
}

$kunye.toplam_satir=$toplamSatir
$kunye.toplam_bayt=$toplamBayt
$eksikler=@($kunye.tablolar|Where-Object{ -not $_.tam })
$kunye.eksik_tablo=$eksikler.Count
[IO.File]::WriteAllText((Join-Path $Kok "soru-ambar-$damga-kunye.json"),($kunye|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding $false))

Write-Host ("`nTOPLAM: {0:N0} satir · {1:N1} MB · eksik tablo {2}" -f $toplamSatir,($toplamBayt/1MB),$eksikler.Count) -ForegroundColor $(if($eksikler.Count){'Red'}else{'Green'})
# ⛔ Eksik yedekle "yedek aldik" denmez - akis burada DUSER ve artifact yazilmaz.
if($eksikler.Count){ throw ("YEDEK EKSIK: " + (($eksikler|ForEach-Object{ "$($_.tablo) $($_.yazilan)/$($_.beklenen)" }) -join ' · ')) }
Write-Host "kunye: soru-ambar-$damga-kunye.json" -ForegroundColor DarkGray
