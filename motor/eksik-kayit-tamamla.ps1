# ============================================================================
#  EKSIK KAYIT TAMAMLAMA — 25.08.2026
#  Yedekte olup ambarda OLMAYAN kayitlari geri koyar. Wholesale degistirmez -
#  yalnizca EKSIGI tamamlar, mevcuda dokunmaz. Toplu yutma sonrasi kayip
#  tarama icin.
#  NEDEN VAR: 25.08 toplu kosusunda onek suzgeci ("TMS 28*") kardes belgeleri
#  de kapsadi ve "TMS 28 Degisiklikleri (RG 31.07.2026)" gibi AYRI belgeler
#  silindi. Onlar yeni PDF'te YOK - cunku ayri bir yayin. Wholesale geri
#  yukleme yeni kazanci silerdi; dogru hamle EKSIGI TAMAMLAMAK.
# ============================================================================
param([Parameter(Mandatory=$true)][string]$yedekDosya, [switch]$uygula, [switch]$hepsiniGeriKoy)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$yol = if(Test-Path $yedekDosya){ $yedekDosya } else { Join-Path $depoKok "veri/fabrika/$yedekDosya" }
if(-not (Test-Path $yol)){ Write-Host "Yedek yok: $yol"; exit 1 }
$coz=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($yol,[Text.Encoding]::UTF8))
$yedek=@($coz)
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$a=''+$env:SUPABASE_SERVICE_KEY
$H=@{ apikey=$a; Authorization="Bearer $a"; 'User-Agent'='mevzuat-radar-robot' }
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# ambardaki adlari topla (yedekteki adlarin onekleriyle sinirli)
$mevcutAd=New-Object 'System.Collections.Generic.HashSet[string]'
$onekler=@($yedek | ForEach-Object { (("$($_.kaynak_ad)") -split ' p\.| Ek | bolum ')[0] } | Select-Object -Unique)
foreach($o in $onekler){
  $q="$U`?select=kaynak_ad&or=(kaynak_ad.eq." + [uri]::EscapeDataString($o) + ",kaynak_ad.like." + [uri]::EscapeDataString("$o *") + ")&limit=3000"
  try{
    $w=Invoke-WebRequest -UseBasicParsing -Uri $q -Headers $H -TimeoutSec 240
    $tmp=ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()))
    foreach($x in @($tmp)){ [void]$mevcutAd.Add("$($x.kaynak_ad)") }
  } catch { Write-Host "  ! onek sorgusu dustu: $o" }
}
# ⚠⚠ 25.08 GECE DERSI — ARTIK FRENI. Bu betik yalniz ADA bakiyordu. Yutucu bir
# standardi DAHA IYI bolerek yeniden yazinca eski bolmenin adlari ("BDS 230
# p.10 - Paragraf", "GDS 3400 bolum 3", "BDS 810 - on bolum"...) ambarda
# artik yoktur - AMA ICERIKLERI yeni parcalarin icinde durur. Bu betik onlari
# "eksik ayri yayin" sanip GERI BASTI: bir gecede +2.207 cop kayit, kesik
# belge 18 -> 137. KURAL: ambarda taze bolmesi (p.* kayitlari) OLAN bir
# standardin onekiyle baslayan yedek kaydi ARTIKTIR - geri konmaz. Istisna:
# ayri yayinlar (Degisiklik / RG / Kurul Karari gecen adlar) her zaman geri
# konur; supheye dusersen -hepsiniGeriKoy ile eski davranisa don.
$tazeOnek=New-Object 'System.Collections.Generic.HashSet[string]'
foreach($ad in $mevcutAd){
  $m=[regex]::Match($ad,'^(.+?)\s+p\.')
  if($m.Success){ [void]$tazeOnek.Add($m.Groups[1].Value) }
}
$ayriYayinDeseni='Değişiklik|Degisiklik|DEĞİŞİKLİK|\(RG|Kurul Karar'
$adaylar=@($yedek | Where-Object { -not $mevcutAd.Contains("$($_.kaynak_ad)") })
$artik=@(); $eksik=@()
foreach($aday in $adaylar){
  $ad="$($aday.kaynak_ad)"
  $debris=$false
  if(-not $hepsiniGeriKoy -and $ad -notmatch $ayriYayinDeseni){
    foreach($p in $tazeOnek){ if($ad.StartsWith("$p ")){ $debris=$true; break } }
  }
  if($debris){ $artik += $aday } else { $eksik += $aday }
}
if($artik.Count){
  Write-Host ("  ARTIK FRENI: {0} kayit eski bolme artigi sayildi, GERI KONMAYACAK (taze bolme ambarda)." -f $artik.Count)
  foreach($a in ($artik | Select-Object -First 5)){ Write-Host ("     x {0}" -f "$($a.kaynak_ad)".Substring(0,[Math]::Min(70,"$($a.kaynak_ad)".Length))) }
  if($artik.Count -gt 5){ Write-Host ("     ... ve {0} kayit daha (-hepsiniGeriKoy ile hepsi geri konur)" -f ($artik.Count-5)) }
}
$eksikKrk=0; foreach($x in $eksik){ $eksikKrk += "$($x.metin)".Length }
Write-Host ("Yedek: {0} kayit · Ambarda bulunan ad: {1} · EKSIK: {2} kayit / {3:N0} karakter" -f $yedek.Count,$mevcutAd.Count,$eksik.Count,$eksikKrk)
if($eksik.Count -eq 0){ Write-Host 'Eksik yok.'; exit 0 }
foreach($e in ($eksik | Select-Object -First 12)){ Write-Host ("   + {0}" -f "$($e.kaynak_ad)".Substring(0,[Math]::Min(76,"$($e.kaynak_ad)".Length))) }
if($eksik.Count -gt 12){ Write-Host ("   ... ve {0} kayit daha" -f ($eksik.Count-12)) }
if(-not $uygula){ Write-Host ''; Write-Host 'KURU PROVA — -uygula ile yaz.'; exit 0 }
$yaz=0
for($i=0;$i -lt $eksik.Count;$i+=50){
  $d=@($eksik[$i..([Math]::Min($i+49,$eksik.Count-1))])
  $g=@(); foreach($p in $d){ $g += ,([ordered]@{ kaynak_ad="$($p.kaynak_ad)"; metin="$($p.metin)"; tur="$($p.tur)"; kaynak_url="$($p.kaynak_url)" }) }
  $j=ConvertTo-Json -InputObject $g -Depth 6
  if($d.Count -eq 1){ $j="[$j]" }
  $null=Invoke-RestMethod -Method Post -Uri $U -Headers ($H+@{Prefer='return=minimal'}) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($j)) -TimeoutSec 240
  $yaz+=$d.Count
}
Write-Host ("TAMAMLANDI: {0} kayit geri kondu." -f $yaz)