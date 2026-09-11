#requires -Version 5.1
<#
================================================================================
  KOPRU SENKRON — konu koprusu yerel <-> ambar  (11.09.2026)
  Cem: "bulut hattini simdi kuralim, bagimsiz denetim ve SPK da var"

  NIYE: veri/fabrika/konu-koprusu.json (6,7 MB · 21.333 kayit) .gitignore'da ve
  YALNIZ Cem'in dizustunde. Uretici KONU SECIMINI bundan yapiyor. Bulutta yoksa
  "kopru disi sentez" yoluna duser; o yolda dayanak BOS kalir, kaynak paketi
  zayiflar ve KAYNAK-EKSIK reti artar. 11.09'da butun gun o kusuru kapatmakla
  ugrasildi (777 ret = tum retlerin %54'u); bulut onu geri getirirdi.

    -Yukle : yerel koprunun TAMAMINI ambara yazar (upsert, sinav+konu anahtari)
    -Indir : ambardaki kayitlari yerel dosyaya yazar
    -Ozet  : iki tarafi sinav sinav SAYAR, yan yana gosterir

  ⚠ TEK SATIR DEGIL, KAYIT KAYIT. 6,7 MB'lik tek jsonb her is basinda
    indirilmek zorunda kalirdi; sinav bazli cekilebilsin diye satirlanmis
    (011_kalip_parti.sql bolum 3 ile ayni karar).

  ⚠ -Sinav ile daraltilabilir. Bulut isi yalnizca kostugu sinavi indirir;
    SGS icin KGK'nin 8 bin satirini cekmek bosa zaman.

  ⛔ KOPRUYU URETMEZ. Uretici ayri (konu-koprusu-kur.ps1); bu betik sadece
     tasir. Boylece kosan turlar bozulmaz.

  BEDEL 0 — yalniz ambar okuma/yazma, model cagrisi YOK.
================================================================================
#>
param(
  [switch]$Indir,
  [switch]$Yukle,
  [switch]$Ozet,
  [ValidateSet('','SGS','SMMM','KGK','SPK')][string]$Sinav = '',
  [switch]$Yaz
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

if(-not ($Indir -or $Yukle -or $Ozet)){ throw 'Yon belirt: -Yukle · -Indir · -Ozet' }
if($Indir -and $Yukle){ throw 'Tek yon sec: -Indir YA DA -Yukle' }

$ANAHTAR_SB="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $ANAHTAR_SB){ $ANAHTAR_SB="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $ANAHTAR_SB){ throw 'SUPABASE_SERVICE_KEY yok.' }
# ⛔ Ad UZUN secildi. Kisa $ANAHTAR yazilsaydi asagidaki bir $anahtar onu ezerdi
#    (PS harf AYIRMAZ) - bu tuzaga 11.09'da ALTI kez dusuldu. Bkz CLAUDE.md.
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/konu_koprusu'
$BASLIKLAR=@{ apikey=$ANAHTAR_SB; Authorization="Bearer $ANAHTAR_SB"; 'Content-Type'='application/json'
              Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$dosya=Join-Path $depoKok 'veri\fabrika\konu-koprusu.json'

function YerelKayitlar{
  if(-not (Test-Path $dosya)){ return @() }
  # ⛔ PS 5.1 TUZAGI: @(Get-Content x | ConvertFrom-Json) diziyi TEK ogeye sarar.  # nobetci:gec (tuzagi ANLATAN yorum)
  #    Once degiskene alinir, sonra @() ile sarilir. (arac/olcum-kapilari.ps1)
  $ham=Get-Content $dosya -Raw -Encoding UTF8|ConvertFrom-Json
  $t=@($ham)
  if($Sinav){ $t=@($t|Where-Object{ "$($_.sinav)" -eq $Sinav }) }
  return $t
}
function AmbarKayitlar{
  $l=New-Object System.Collections.Generic.List[object]
  $off=0
  while($true){
    # ⚠ order= ZORUNLU: sirasiz sayfalama PostgREST'te KARARSIZ, ayni satir iki
    #   sayfada cikabilir ya da hic cikmaz (veri/AMBAR-OLCUM-TUZAKLARI).
    $u=$TABAN+'?select=sinav,konu,bizim_ders,arsiv_ders,cikmis,donem,durum,dayanak,cikmis_dayanak,guc&order=sinav.asc,konu.asc&limit=1000&offset='+$off
    if($Sinav){ $u=$u+'&sinav=eq.'+[uri]::EscapeDataString($Sinav) }
    $r=$null
    try{ $r=Invoke-RestMethod -Uri $u -Headers $BASLIKLAR -TimeoutSec 120 }
    catch{ throw ("ambar okunamadi: " + $_.Exception.Message + " — rag-motor/sql/011_kalip_parti.sql BASILDI MI? (radar-app/sql/UYGULANDI.md)") }
    $s=@($r); foreach($x in $s){ $l.Add($x) }
    if($s.Count -lt 1000){ break }
    $off+=1000
  }
  return $l
}

$yerel=@(YerelKayitlar)
Write-Host ("YEREL : {0,6:N0} kayit{1}" -f $yerel.Count,$(if($Sinav){" (sinav=$Sinav)"}else{''})) -ForegroundColor Cyan
$ambar=Dizi (AmbarKayitlar)
Write-Host ("AMBAR : {0,6:N0} kayit" -f $ambar.Count) -ForegroundColor Cyan

if($Ozet){
  Write-Host "`n  sinav        yerel    ambar   fark" -ForegroundColor DarkGray
  $sy=@{}; foreach($x in $yerel){ $k="$($x.sinav)"; $sy[$k]=1+[int]$sy[$k] }
  $sa=@{}; foreach($x in $ambar){ $k="$($x.sinav)"; $sa[$k]=1+[int]$sa[$k] }
  $tum=@(@($sy.Keys)+@($sa.Keys)|Select-Object -Unique|Sort-Object)
  foreach($k in $tum){
    $f=[int]$sy[$k]-[int]$sa[$k]
    $renk=if($f -eq 0){'Green'}else{'Yellow'}
    Write-Host ("  {0,-10} {1,6:N0}  {2,6:N0}  {3,5}" -f $k,[int]$sy[$k],[int]$sa[$k],$f) -ForegroundColor $renk
  }
  return
}

if($Yukle){
  if(-not $yerel.Count){ throw "yerel kopru bos ya da yok: $dosya" }
  Write-Host ("`nGONDERILECEK: {0:N0} kayit (upsert, anahtar sinav+konu)" -f $yerel.Count) -ForegroundColor Green
  if(-not $Yaz){ Write-Host "KURU KOSU - ambara yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
  $n=0; $hata=0
  $paket=New-Object System.Collections.Generic.List[object]
  # 500'luk paket: 21.333 kayit tek istekte gonderilirse govde ~7 MB olur ve
  # 57014 timeout'a girer (08.09'da marka hattinda birebir yasandi).
  foreach($x in $yerel){
    $paket.Add([ordered]@{
      sinav="$($x.sinav)"; konu="$($x.konu)"
      bizim_ders="$($x.bizim_ders)"; arsiv_ders="$($x.arsiv_ders)"
      cikmis=[int]$x.cikmis; donem=[int]$x.donem
      durum="$($x.durum)"; dayanak="$($x.dayanak)"
      cikmis_dayanak="$($x.cikmis_dayanak)"; guc="$($x.guc)" })
    if($paket.Count -ge 500){
      $g=$paket.ToArray(); $paket=New-Object System.Collections.Generic.List[object]
      try{
        $b=[Text.Encoding]::UTF8.GetBytes(($g|ConvertTo-Json -Depth 4))
        [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'?on_conflict=sinav,konu') -Headers ($BASLIKLAR+@{Prefer='resolution=merge-duplicates,return=minimal'}) -Body $b -TimeoutSec 300)
        $n+=$g.Count
        Write-Host ("  ... {0:N0}/{1:N0}" -f $n,$yerel.Count) -ForegroundColor DarkGray
      }catch{ Write-Host ("  ! paket yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$g.Count }
    }
  }
  if($paket.Count){
    $g=$paket.ToArray()
    try{
      $b=[Text.Encoding]::UTF8.GetBytes(($g|ConvertTo-Json -Depth 4))
      [void](Invoke-RestMethod -Method Post -Uri ($TABAN+'?on_conflict=sinav,konu') -Headers ($BASLIKLAR+@{Prefer='resolution=merge-duplicates,return=minimal'}) -Body $b -TimeoutSec 300)
      $n+=$g.Count
    }catch{ Write-Host ("  ! son paket yazilamadi: " + $_.Exception.Message) -ForegroundColor Red; $hata+=$g.Count }
  }
  Write-Host ("`nYUKLENDI: {0:N0} kayit · hata {1}" -f $n,$hata) -ForegroundColor $(if($hata){'Yellow'}else{'Green'})
  # Yaz -> geri oku -> karsilastir (Cem'in degismez kurali)
  $tekrar=Dizi (AmbarKayitlar)
  Write-Host ("GERI OKUMA: ambarda {0:N0} kayit" -f $tekrar.Count) -ForegroundColor Cyan
  if($tekrar.Count -lt $yerel.Count){ Write-Host ("  ⚠ EKSIK: {0:N0} kayit ambara ulasmadi" -f ($yerel.Count-$tekrar.Count)) -ForegroundColor Yellow }
  else{ Write-Host "  ✓ yerel kadar (ya da fazla) kayit ambarda" -ForegroundColor Green }
  return
}

# --- INDIR: ambar -> yerel ----------------------------------------------------
if(-not $ambar.Count){ throw 'ambarda kayit yok - once -Yukle' }
Write-Host ("`nYEREL DOSYAYA YAZILACAK: {0:N0} kayit" -f $ambar.Count) -ForegroundColor Green
if(-not $Yaz){ Write-Host "KURU KOSU - dosya yazilmadi. Yazmak icin: -Yaz" -ForegroundColor Yellow; return }
# ⚠ -Sinav ile daraltilmis indirme, dosyanin TAMAMINI ezmemeli: yerelde duran
#   diger sinavlarin kayitlari korunur. (Kismi kosunun tam raporu ezmesi bugun
#   ret-kutugu'nde IKI KEZ yasandi; ayni hata burada tekrarlanmaz.)
$son=New-Object System.Collections.Generic.List[object]
if($Sinav -and (Test-Path $dosya)){
  $ham=Get-Content $dosya -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($x in @($ham)){ if("$($x.sinav)" -ne $Sinav){ $son.Add($x) } }
  Write-Host ("  korunan (diger sinavlar): {0:N0} kayit" -f $son.Count) -ForegroundColor DarkGray
}
foreach($x in $ambar){ $son.Add($x) }
[IO.File]::WriteAllText($dosya,((Dizi $son)|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
Write-Host ("YAZILDI: {0} · {1:N0} kayit" -f (Split-Path $dosya -Leaf),$son.Count) -ForegroundColor Green
