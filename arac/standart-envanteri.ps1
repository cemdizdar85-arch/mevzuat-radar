#requires -Version 5.1
<#
================================================================================
  STANDART ENVANTERI  (11.09.2026, Cem "ne gerekiyorsa yap")

  NIYE: Kategori 1 (Muhasebe ve Denetim) sorularinin %40'i hesap kodu DEGIL
  STANDART NUMARASI aniyor (BDS 530, TMS 16, TFRS 15). Olculdu: 449 sorunun
  201'i THP hesap kodu, 181'i standart numarasi, 147'si hicbiri.
  Hesap kodu icin KAPI-H (kod-ad cifti) ve KAPI-HS (beyaz liste) var;
  standart numarasi icin DENGI YOKTU.

  NE URETIR: veri/standart-envanteri.json - ambardaki TUM standart numaralari.
  KAPI-SS bu dosyayi okur; soruda anilan standart listede yoksa kusur yazar.

  ⚠ SAYFALAMA SART: ilk olcumde limit=1000 ile cektim ve BDS'te 7 numara
  gorundu; gercek sayi 37. Kesilen liste "BDS 705 ambarda yok" gibi 33 SAHTE
  bulgu uretmisti. 1000'lik sayfalarla ve `order=kaynak_ad.asc` ile cekilir -
  order'siz sayfalama KARARSIZDIR (ambar olcum tuzaklari notu).

  OLCULEN (11.09): BDS 37 · TMS 24 · TFRS 17 · TSRS 2 numara.
  Basili 636 soruda anilan 50 benzersiz standardin AMBARDA OLMAYANI: 0.
  Yani bu sinifta bugun hata yok; kapi ONLEYICI olarak kuruluyor.

  BEDEL 0 - yalniz ambar sorgusu.
================================================================================
#>
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$KEY="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim()
if(-not $KEY){ $KEY="$($env:SUPABASE_SERVICE_KEY)".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$SBH=@{apikey=$KEY;Authorization="Bearer $KEY";Accept='application/json';'User-Agent'='mevzuat-radar-robot/1.0'}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

$ONEKLER=@('BDS','TMS','TFRS','TSRS','KKS')
$envanter=[ordered]@{}
foreach($on in $ONEKLER){
  $no=New-Object System.Collections.Generic.List[string]; $off=0; $belge=0
  while($true){
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&kaynak_ad=ilike.'+
       [uri]::EscapeDataString("$on %")+"&order=kaynak_ad.asc&limit=1000&offset=$off"
    $r=$null
    try{ $r=Invoke-RestMethod -Uri $u -Headers $SBH -TimeoutSec 90 }
    catch{ Write-Host ("  AMBAR HATASI ({0} offset {1}): {2}" -f $on,$off,$_.Exception.Message) -ForegroundColor Red; break }
    $s=@($r); $belge+=$s.Count
    foreach($x in $s){
      $mm=[regex]::Match("$($x.kaynak_ad)","^$on\s+(\d+)")
      if($mm.Success -and $no -notcontains $mm.Groups[1].Value){ $no.Add($mm.Groups[1].Value) }
    }
    if($s.Count -lt 1000){ break }
    $off+=1000
    if($off -gt 30000){ Write-Host "  UYARI: $on 30.000 satiri asti, kesildi" -ForegroundColor Yellow; break }
  }
  $envanter[$on]=@($no | Sort-Object { [int]$_ })
  Write-Host ("{0,-6} belge {1,5} · benzersiz numara {2,3}" -f $on,$belge,$envanter[$on].Count) -ForegroundColor Cyan
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\standart-envanteri.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak='rag ambari (dokumanlar.kaynak_ad)'
  kural='Soruda anilan standart numarasi bu envanterde YOKSA kusurdur (KAPI-SS). Envanter ambardan uretilir, elle yazilmaz.'
  uyari='Sayfalama SART: limit=1000 tek sayfa BDS''te 7 numara gosterip 33 sahte "ambarda yok" bulgusu uretmisti. order=kaynak_ad.asc + offset ile cekilir.'
  onekler=@($ONEKLER)
  numaralar=$envanter
})
$t=0; foreach($k in $envanter.Keys){ $t+=$envanter[$k].Count }
Write-Host ("`nTOPLAM benzersiz standart numarasi: {0}" -f $t) -ForegroundColor Green
Write-Host "-> veri/standart-envanteri.json"
