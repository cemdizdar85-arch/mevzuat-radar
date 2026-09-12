#requires -Version 5.1
<#
================================================================================
  KOSU NABZI — "bulut kosusunda kac parti bitti, ne harcandi?"  (12.09.2026)

  NIYE VAR: 12.09'da A kosusu 125 dakika kostu ve bu sorunun cevabi YOKTU.
  Ucu de OLCULDU, tahmin degil:
      gh run view <id> --log            -> bos (kutuk kosu bitince doluyor)
      gh api .../jobs/<id>/logs         -> BlobNotFound
      ambar                             -> bos (yazma adimi EN SONDA tek adim)
  Yani 350 dakikalik odenmis bir kosuyu KOR izliyorduk. Ben o bosluga bakip
  "0/32 parti bitti" diye bir sayi urettim - bilgi yoklugunu olcum sandim.
  Bir daha olmasin diye: kosucu her parti bitisinde defteri ambara yukluyor
  (motor/kalip-kosucu.ps1 > NabizYaz), bu betik de onu okuyor.

  ⛔ YENI TABLO YOK. public.bedel_kaydi zaten (zaman, etiket, ders, toplam_usd,
     yazan, ay) tasiyor; `yazan` alani bulut kosusunda "actions-<run id>" olur.
     Yerel kosuda "yerel-<makine>".

  KULLANIM
    powershell -NoProfile -File arac/kosu-nabzi.ps1                 # bugun, tum kaynaklar
    powershell -NoProfile -File arac/kosu-nabzi.ps1 -Kosu 34685108087
    powershell -NoProfile -File arac/kosu-nabzi.ps1 -Ay 2026-09 -Dokum
  BEDEL 0 — yalniz ambar okuma.
================================================================================
#>
param(
  [string]$Kosu = '',        # GitHub run id (bos = suzme yok)
  [string]$Ay   = '',        # 'YYYY-MM' (bos = bu ay)
  [int]$SonSaat = 0,         # yalniz son N saat (0 = suzme yok)
  [switch]$Dokum             # parti parti liste
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

if(-not $Ay){ $Ay=(Get-Date -Format 'yyyy-MM') }
$ANAHTAR="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $ANAHTAR){ $ANAHTAR="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok.' }
$TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$BASLIKLAR=@{ apikey=$ANAHTAR; Authorization="Bearer $ANAHTAR"; 'Content-Type'='application/json'
              Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# ⛔ order= ZORUNLU: siralamasiz sayfalama kararsizdir, ayni satir iki sayfada
#    cikabilir (bkz. CLAUDE.md > ambar olcum tuzaklari).
$KAYITLAR=New-Object System.Collections.Generic.List[object]
$KAYDIRMA=0
while($true){
  $ADRES=$TABAN+'/bedel_kaydi?select=zaman,etiket,ders,toplam_usd,yazan&ay=eq.'+[uri]::EscapeDataString($Ay)+'&order=zaman.asc&limit=1000&offset='+$KAYDIRMA
  if($Kosu){ $ADRES+='&yazan=eq.'+[uri]::EscapeDataString("actions-$Kosu") }
  $YANIT=$null
  try{ $YANIT=Invoke-RestMethod -Uri $ADRES -Headers $BASLIKLAR -TimeoutSec 90 }
  catch{ throw ("ambar okunamadi: " + $_.Exception.Message + " — rag-motor/sql/011_kalip_parti.sql BASILDI MI?") }
  # ⛔ @($x|ConvertFrom-Json) tuzagi: Invoke-RestMethod zaten nesne dondurur,
  #    ama diziyi @() ile sarmadan once DEGISKENE almak sart (K2).
  $SAYFA=@($YANIT)
  if(-not $SAYFA.Count){ break }
  foreach($K in $SAYFA){ $KAYITLAR.Add($K) }
  if($SAYFA.Count -lt 1000){ break }
  $KAYDIRMA+=1000
}
$TUM=$KAYITLAR.ToArray()
if($SonSaat -gt 0){
  $ESIK=(Get-Date).ToUniversalTime().AddHours(-1*$SonSaat)
  $TUM=@($TUM | Where-Object{ ([datetime]::Parse("$($_.zaman)")).ToUniversalTime() -ge $ESIK })
}

if(-not $TUM.Count){
  Write-Host "kayit yok (ay $Ay$(if($Kosu){" · kosu $Kosu"})$(if($SonSaat){" · son $SonSaat saat"}))" -ForegroundColor Yellow
  Write-Host "  Not: kosu daha hic parti bitirmediyse bu NORMALDIR - nabiz parti BITISINDE yazilir." -ForegroundColor DarkGray
  exit 0
}

$TUTAR=0.0; foreach($K in $TUM){ $TUTAR+=[double]$K.toplam_usd }
$ETIKETLER=@($TUM | ForEach-Object{ "$($_.etiket)" } | Select-Object -Unique)
$ILK=($TUM | Sort-Object{ [datetime]::Parse("$($_.zaman)") } | Select-Object -First 1)
$SON=($TUM | Sort-Object{ [datetime]::Parse("$($_.zaman)") } | Select-Object -Last 1)
$GECEN=([datetime]::Parse("$($SON.zaman)") - [datetime]::Parse("$($ILK.zaman)")).TotalMinutes

Write-Host ""
Write-Host ("KOSU NABZI · ay {0}{1}" -f $Ay,$(if($Kosu){" · kosu $Kosu"}else{''})) -ForegroundColor Cyan
Write-Host ("  biten parti (tekil etiket) : {0}" -f $ETIKETLER.Count)
Write-Host ("  harcama kaydi              : {0}" -f $TUM.Count)
Write-Host ("  toplam                     : {0:N2} USD" -f $TUTAR)
Write-Host ("  ilk / son kayit            : {0:HH:mm} / {1:HH:mm} UTC" -f ([datetime]::Parse("$($ILK.zaman)")).ToUniversalTime(),([datetime]::Parse("$($SON.zaman)")).ToUniversalTime())
if($ETIKETLER.Count -gt 1 -and $GECEN -gt 0){
  Write-Host ("  parti basina               : {0:N1} dk (ilk-son araligi / parti)" -f ($GECEN/($ETIKETLER.Count-1))) -ForegroundColor Green
}
if($ETIKETLER.Count -eq 1){
  Write-Host "  (tek parti - hiz olculemez)" -ForegroundColor DarkGray
}

if($Dokum){
  Write-Host ""
  foreach($G in (@($TUM | Group-Object etiket) | Sort-Object{ [datetime]::Parse("$(($_.Group | Sort-Object{ [datetime]::Parse("$($_.zaman)") } | Select-Object -Last 1).zaman)") })){
    $T=0.0; foreach($X in $G.Group){ $T+=[double]$X.toplam_usd }
    $Z=([datetime]::Parse("$(($G.Group | Sort-Object{ [datetime]::Parse("$($_.zaman)") } | Select-Object -Last 1).zaman)")).ToUniversalTime()
    Write-Host ("  {0:HH:mm}  {1,-40} {2,7:N2} USD" -f $Z,$G.Name,$T)
  }
}
Write-Host ""
