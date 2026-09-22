#requires -Version 5.1
<#
================================================================================
  AMBAR DİPNOT ONARIMI — yapışık dipnot numarasını yerinde ayırır (22.09.2026)
  Cem "1 ve 2 yap"

  NEDEN AYRI ARAÇ: kusur yutucuda düzeltildi (arac/dipnot-ayir.ps1 · motor/standart-yut.ps1 ·
  motor/kgk-standart-yut.ps1), ama ambardaki ESKİ kayıtlar bozuk kalıyor. Kural gereği
  (KAPI EKLENDİYSE VERİ TAZELENİR) veri de tazelenmeli. Tazelemenin iki yolu vardı:
    (a) 89 standardı yeniden yutmak — PDF'leri yeniden indirir, kayıt sınırlarını yeniden
        çizer, bağlı soru paketlerini bayatlatır (16.09 dersi). Bu düzeltme için ORANTISIZ.
    (b) YALNIZ METNİ yerinde düzeltmek — kayıt eklenmez/silinmez, sınırlar değişmez.
  Bu araç (b) yolunu uygular: aynı ayırıcıyı çalıştırır, DEĞİŞEN kayıtların yalnız `metin`
  alanını PATCH eder ve birebir geri okur.

  FREN: değişecek kayıt oranı -OranTavani'nı (varsayılan %10) aşarsa araç YAZMADAN durur —
  ayırıcı bozulmuş olabilir. Ayrıca her yazımdan sonra geri okuma yapılır, tutmazsa sayılır.

  BU ARAÇ ŞUNU GÖRMEZ: kesik bent, komşu paragraf başlığı, mükerrer kayıt, iki sütunlu tablo
  karışması (hepsi arac/ambar-metin-kusuru.ps1'de ölçülür, hiçbiri burada onarılmaz).

  KULLANIM
    powershell -NoProfile -File arac/ambar-dipnot-onar.ps1                    # kuru prova
    powershell -NoProfile -File arac/ambar-dipnot-onar.ps1 -Yaz               # standart-madde
    powershell -NoProfile -File arac/ambar-dipnot-onar.ps1 -Tur kanun-madde -Yaz
================================================================================
#>
param(
  [string]$Tur = 'standart-madde',
  [switch]$Yaz,
  [double]$OranTavani = 10.0
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'dipnot-ayir.ps1')

$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $anahtar){ $anahtar = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $anahtar){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$H = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# BULUT KAPISI (CLAUDE.md: bulutta koşan partiye ambardan yazılmaz)
if($Yaz){
  $kosan = (& 'C:\Program Files\GitHub CLI\gh.exe' run list --repo cemdizdar85-arch/mevzuat-radar --workflow=bulut-uretim.yml --limit 20 --json status) -join ''
  if($kosan -match 'in_progress|queued|waiting|requested'){ Write-Host 'BULUT KAPISI: bulut üretimi koşuyor - ambara YAZILMAZ, sonra tekrar deneyin.' -ForegroundColor Red; exit 1 }
  Write-Host 'bulut kapısı: koşan üretim yok'
}

$adim = 500; $ofs = 0; $toplam = 0
$degisenler = New-Object System.Collections.Generic.List[object]
while($true){
  $sayfa = @(); foreach($x in (Invoke-RestMethod -Uri "$SB`?select=id,kaynak_ad,metin&tur=eq.$Tur&order=id&limit=$adim&offset=$ofs" -Headers $H -TimeoutSec 180)){ $sayfa += $x }
  if(-not $sayfa.Count){ break }
  foreach($r in $sayfa){
    $toplam++
    $eski = "$($r.metin)"; $yeni = DipnotAyir $eski
    if($yeni -cne $eski){ $degisenler.Add([pscustomobject]@{ id=$r.id; ad="$($r.kaynak_ad)"; yeni=$yeni }) }
  }
  $ofs += $adim
  if($sayfa.Count -lt $adim){ break }
}
$oran = if($toplam){ [Math]::Round(100*$degisenler.Count/$toplam,2) } else { 0 }
Write-Host ("tur={0} · okunan {1} · DEĞİŞECEK {2} (%{3})" -f $Tur,$toplam,$degisenler.Count,$oran)
foreach($d in ($degisenler | Select-Object -First 5)){ Write-Host ("   {0}" -f $d.ad) }
if(-not $degisenler.Count){ exit 0 }
if($oran -gt $OranTavani){ Write-Host ("FREN: değişim oranı %{0} > tavan %{1} — ayırıcı bozulmuş olabilir, YAZILMADI." -f $oran,$OranTavani) -ForegroundColor Red; exit 1 }
if(-not $Yaz){ Write-Host "`nKURU PROVA — yazmak için -Yaz"; exit 0 }

$yazilan = 0; $hata = 0
foreach($d in $degisenler){
  $govde = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject ([ordered]@{ metin=$d.yeni }) -Compress))
  try {
    $null = Invoke-RestMethod -Method Patch -Uri "$SB`?id=eq.$($d.id)" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body $govde -TimeoutSec 120
    $geri = @(); foreach($x in (Invoke-RestMethod -Uri "$SB`?select=metin&id=eq.$($d.id)" -Headers $H -TimeoutSec 120)){ $geri += $x }
    if($geri.Count -eq 1 -and "$($geri[0].metin)" -ceq $d.yeni){ $yazilan++ } else { $hata++; Write-Host ("  GERİ OKUMA TUTMADI: {0}" -f $d.ad) -ForegroundColor Red }
  } catch { $hata++; Write-Host ("  YAZILAMADI: {0} - {1}" -f $d.ad,$_.Exception.Message) -ForegroundColor Red }
}
Write-Host ("YAZILDI: {0} · hata {1}" -f $yazilan,$hata)
if($hata){ exit 1 }
