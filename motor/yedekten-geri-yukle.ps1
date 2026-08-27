# ============================================================================
#  YEDEKTEN GERI YUKLE — 25.08.2026
#  NEDEN VAR: standart-yut.ps1 toplu kosusunda TMS 2 289 parca / 188.429
#  karakterden 6 parca / 17.520 karaktere DUSTU. KGK'nin o adresteki PDF'i
#  standardin TAMAMI degil, bir OZETI/eki cikti ve yutucu "yeni hali" diye
#  IYI OLANI SILDI. Geri okuma dogrulamasi "yazilan ile ambardaki tutuyor"
#  dedi - cunku YAZILANI dogruluyordu, YETERLI OLANI degil.
#  Ders: dogrulama "yazdigimi yazdim mi" degil "DAHA IYISINI mi yazdim"
#  sorusunu sormali. Bu betik hatanin donus yoludur.
# ============================================================================
param([Parameter(Mandatory=$true)][string]$yedekDosya, [switch]$uygula)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$yol = if(Test-Path $yedekDosya){ $yedekDosya } else { Join-Path $depoKok "veri/fabrika/$yedekDosya" }
if(-not (Test-Path $yol)){ Write-Host "Yedek bulunamadi: $yol"; exit 1 }
$ham=[IO.File]::ReadAllText($yol,[Text.Encoding]::UTF8)
$coz=ConvertFrom-Json -InputObject $ham
$kayitlar=@($coz)
$krk=0; foreach($x in $kayitlar){ $krk += "$($x.metin)".Length }
$onek = ($kayitlar[0].kaynak_ad -split ' p\.| Ek ')[0]
Write-Host ("Yedek : {0}" -f (Split-Path $yol -Leaf))
Write-Host ("Kayit : {0} parca · {1:N0} karakter" -f $kayitlar.Count,$krk)
Write-Host ("Onek  : {0}" -f $onek)

if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$a=''+$env:SUPABASE_SERVICE_KEY
$H=@{ apikey=$a; Authorization="Bearer $a"; 'User-Agent'='mevzuat-radar-robot' }
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$suz='kaynak_ad=like.' + [uri]::EscapeDataString("$onek*")
$w=Invoke-WebRequest -UseBasicParsing -Uri "$U`?select=id,metin&$suz&limit=2000" -Headers $H -TimeoutSec 240
$mev=@(ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())))
$mevKrk=0; foreach($x in $mev){ $mevKrk += "$($x.metin)".Length }
Write-Host ("Ambar : {0} parca · {1:N0} karakter" -f $mev.Count,$mevKrk)
if(-not $uygula){ Write-Host ''; Write-Host 'KURU PROVA — -uygula ile geri yukle.'; exit 0 }

Write-Host 'Mevcut siliniyor...'
$null=Invoke-RestMethod -Method Delete -Uri "$U`?$suz" -Headers ($H+@{Prefer='return=minimal'}) -TimeoutSec 240
Write-Host 'Yedek yaziliyor...'
$yaz=0
for($i=0;$i -lt $kayitlar.Count;$i+=50){
  $d=@($kayitlar[$i..([Math]::Min($i+49,$kayitlar.Count-1))])
  $g=@(); foreach($p in $d){ $g += ,([ordered]@{ kaynak_ad="$($p.kaynak_ad)"; metin="$($p.metin)"; tur="$($p.tur)"; kaynak_url="$($p.kaynak_url)" }) }
  $j=ConvertTo-Json -InputObject $g -Depth 6
  if($d.Count -eq 1){ $j="[$j]" }
  $null=Invoke-RestMethod -Method Post -Uri $U -Headers ($H+@{Prefer='return=minimal'}) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($j)) -TimeoutSec 240
  $yaz+=$d.Count
}
Start-Sleep -Seconds 2
$w2=Invoke-WebRequest -UseBasicParsing -Uri "$U`?select=id,metin&$suz&limit=2000" -Headers $H -TimeoutSec 240
$geri=@(ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($w2.RawContentStream.ToArray())))
$geriKrk=0; foreach($x in $geri){ $geriKrk += "$($x.metin)".Length }
Write-Host ("GERI OKUMA: {0} parca · {1:N0} karakter" -f $geri.Count,$geriKrk)
if($geri.Count -ne $kayitlar.Count){ Write-Host '!! TUTMUYOR' -ForegroundColor Red; exit 1 }
Write-Host 'GERI YUKLENDI ve dogrulandi.' -ForegroundColor Green