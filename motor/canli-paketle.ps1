# ============================================================================
#  CANLI DENEME PAKETLEYICI — 07.08.2026 (kilitli-set mimarisi, karar 06.08)
#
#  Sorular sinav SAATINDEN ONCE sifreli statik dosya olarak dagitilir
#  (veri/canli/<oturum>.enc - public repoda durabilir, icerik AES-256-CBC
#  sifreli); saat gelince YALNIZ ANAHTAR yayinlanir (canli-anahtar-yayinla).
#  5k eszamanli katilimci Supabase'e sifir yuk bindirir - dosya CDN'den iner.
#
#  ANAHTAR REPOYA GIRMEZ: OneDrive'da repo DISI klasorde durur
#  (mevzuat işi\canli-anahtarlar\<oturum>.key). Yayin ani gelmeden pakete
#  ulasan biri icerigi ACAMAZ.
#
#  Secim kurallari: yayin_notu BOS olanlardan (karantinasiz/temiz kasa),
#  benzer-gruptan tek soru, SGS'de resmi 130 bilesimi, Yeterlilik'te
#  8 ders x 10 soru (2026 test duzeni orani; oturum 120 dk onerisi).
#
#  KULLANIM: .\motor\canli-paketle.ps1 -oturum SGS-2308
#            oturum kodu veri/canli-deneme.json'daki oturumla eslesir:
#            'SGS-2308' = SGS 23.08 / 'YET-3008' = Yeterlilik 30.08 ...
# ============================================================================
#  KAPI (20.08): bilesim eksik cikarsa paket URETILMEZ. 07.08'de 93/130 soruluk
#  paket sessizce uretilip yayina hazir bekledi (uyari yalnizca ekrana yazildi).
#  Eksikle devam etmek bilincli bir karardir: -zorla bayragi ister ve paketin
#  yanina sifresiz KARNE dosyasi yazilir (soru metni YOK, yalniz ders x adet).
param([Parameter(Mandatory=$true)][string]$oturum, [switch]$zorla)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok'; exit 1 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$env:SUPABASE_SERVICE_KEY }

$sinav = if($oturum -like 'SGS*'){ 'SGS' } elseif($oturum -like 'YET*'){ 'SMMM' } else { throw "oturum kodu SGS-... ya da YET-... olmali" }

# --- bilesim
$SGS_BILESIM = @(
  @{ders='Türkçe';n=7},@{ders='Matematik';n=8},@{ders='Atatürk İlkeleri ve İnkılap Tarihi';n=5},
  @{ders='Yabancı Dil';n=10},
  @{ders='Finansal Muhasebe';n=26},@{ders='Maliyet Muhasebesi';n=8},@{ders='Mali Tablolar Analizi';n=8},
  @{ders='Denetim';n=16},@{ders='Ekonomi';n=6},@{ders='Maliye';n=6},@{ders='Meslek Hukuku';n=6},
  @{ders='İş ve Sosyal Güvenlik Hukuku';n=6},@{ders='Vergi Hukuku';n=6},@{ders='Ticaret Hukuku';n=6},
  @{ders='Borçlar Hukuku';n=6}
)
$YET_DERSLER = @('Finansal Muhasebe','Finansal Tablolar ve Analizi','Maliyet Muhasebesi','Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Hukuk','Meslek Hukuku','Sermaye Piyasası Mevzuatı')

# DIKKAT (olculdu 20.08): ToLowerInvariant() buyuk 'İ' (U+0130) harfini KUCULTMEZ.
# Eski surumde once ToLowerInvariant cagrildigi icin 'İş ve Sosyal Guvenlik Hukuku'
# -> 'İs ve sosyal guvenlik hukuku' kaliyor ve kasadaki 'Is ve...' ile ESLESMIYORDU:
# 147 temiz soruluk ders pakete hic girmedi. Kural: ONCE harf cevir, SONRA kucult.
function Dnorm([string]$t){
  $s = "$t".Replace('İ','I').Replace('ı','i').Replace('Ş','S').Replace('ş','s').
             Replace('Ğ','G').Replace('ğ','g').Replace('Ü','U').Replace('ü','u').
             Replace('Ö','O').Replace('ö','o').Replace('Ç','C').Replace('ç','c')
  return (($s.ToLowerInvariant()) -replace '\s+',' ').Trim()
}
# Kasadaki ders adi resmi bilesimdekiyle birebir olmayabilir (remap robotu kendi
# adlandirmasini kullandi). Esanlam sozlugu: bilesim adi -> kasada gecen adlar.
$DERS_ESANLAM = @{
  'ataturk ilkeleri ve inkilap tarihi' = @('ataturk ilke ve inkilap tarihi','inkilap tarihi')
  'is ve sosyal guvenlik hukuku'       = @('is ve sosyal guvenlik hukuku','is hukuku')
  'yabanci dil'                        = @('yabanci dil','ingilizce')
  'mali tablolar analizi'              = @('mali tablolar analizi','finansal tablolar ve analizi')
}
function DersEslesirMi($kasaDers, $planDers){
  $k = Dnorm $kasaDers; $p = Dnorm $planDers
  if($k -eq $p){ return $true }
  if($DERS_ESANLAM.ContainsKey($p)){ foreach($a in $DERS_ESANLAM[$p]){ if($k -eq (Dnorm $a)){ return $true } } }
  return $false
}

# --- temiz havuz (yayin_notu bos): hafif liste
Write-Host 'Temiz havuz cekiliyor...'
$havuz = New-Object System.Collections.Generic.List[object]
$bas=0
while($true){
  # kasada benzer_grup kolonu YOK (olculdu 07.08) - cesitlilik KONU TAVANIYLA saglanir
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,ders,konu&sinav=eq.$sinav&yayin_notu=is.null&order=id&limit=1000&offset=$bas" -Headers $H -TimeoutSec 180 | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($x){ $havuz.Add($x) } }
  if($r.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("temiz havuz: {0} soru" -f $havuz.Count)

# --- secim
$rnd = New-Object System.Random
function Karistir($list){ $a=@($list); for($i=$a.Count-1;$i -gt 0;$i--){ $j=$rnd.Next($i+1); $t=$a[$i]; $a[$i]=$a[$j]; $a[$j]=$t }; return $a }
$secim = New-Object System.Collections.Generic.List[object]
$eksikler = @()
$plan = if($sinav -eq 'SGS'){ $SGS_BILESIM } else { @($YET_DERSLER | ForEach-Object { @{ders=$_; n=10} }) }
foreach($p in $plan){
  $aday = Karistir ($havuz | Where-Object { DersEslesirMi $_.ders $p.ders })
  $al=@(); $konuSayac=@{}
  foreach($s in $aday){
    if($al.Count -ge $p.n){ break }
    $kn = Dnorm "$($s.konu)"
    if($konuSayac.ContainsKey($kn) -and $konuSayac[$kn] -ge 2){ continue }   # ayni konudan en fazla 2
    $konuSayac[$kn] = 1 + $(if($konuSayac.ContainsKey($kn)){ $konuSayac[$kn] } else { 0 })
    $al += $s
  }
  if($al.Count -lt $p.n){
    foreach($s in $aday){ if($al.Count -ge $p.n){ break }; if($al -notcontains $s){ $al += $s } }   # tavan doldurmazsa gevset
  }
  if($al.Count -lt $p.n){ $eksikler += ("{0}: {1}/{2}" -f $p.ders, $al.Count, $p.n) }
  foreach($x in $al){ $secim.Add($x) }
}
$hedef = ($plan | ForEach-Object { $_.n } | Measure-Object -Sum).Sum
Write-Host ("secim: {0} / hedef {1}" -f $secim.Count, $hedef)
if($eksikler.Count){
  Write-Host ''
  Write-Host '!! BILESIM EKSIK - resmi dagilim tutmuyor:'
  foreach($e in $eksikler){ Write-Host ("   - " + $e) }
  Write-Host ''
  if(-not $zorla){
    Write-Host ("PAKET URETILMEDI. Eksik dersleri temiz havuza kazandirin (yayin_notu bosaltilmis," )
    Write-Host  "GM okumasindan gecmis soru gerekir) ya da bilinerek eksik oturum icin -zorla verin."
    Write-Host  "Eksik oturum yayinlanacaksa katilimciya ILAN EDILEN soru sayisi da guncellenmelidir."
    exit 2
  }
  Write-Host '-zorla verildi: eksik bilesimle devam ediliyor (karne dosyasina islenecek).'
}

# --- tam metinleri cek
$tam = @{}
$idler = @($secim | ForEach-Object { "$($_.id)" })
for($b=0; $b -lt $idler.Count; $b+=50){
  $dilim = $idler[$b..([Math]::Min($b+49,$idler.Count-1))]
  $liste = ($dilim | ForEach-Object { '"'+$_+'"' }) -join ','
  $rr = @(Invoke-RestMethod -Uri "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye,hap,kaynak&id=in.($liste)" -Headers $H -TimeoutSec 180 | ForEach-Object { $_ })
  foreach($x in $rr){ if($x){ $tam["$($x.id)"]=$x } }
}
$paketSoru = @($idler | ForEach-Object { $tam[$_] } | Where-Object { $_ })
Write-Host ("tam metin: {0}" -f $paketSoru.Count)
if($paketSoru.Count -lt [Math]::Min(50, $secim.Count)){ throw 'tam metin cekimi yetersiz - paket uretilmedi' }

$govde = [ordered]@{
  oturum=$oturum; sinav=$sinav; uretim=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  sure_dk = $(if($sinav -eq 'SGS'){ 150 } else { 120 })
  sorular = $paketSoru
}
$duz = ConvertTo-Json -InputObject $govde -Depth 8 -Compress
$bayt = [Text.Encoding]::UTF8.GetBytes($duz)

# --- AES-256-CBC sifrele (WebCrypto uyumlu)
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize=256; $aes.Mode='CBC'; $aes.Padding='PKCS7'
$aes.GenerateKey(); $aes.GenerateIV()
$enc = $aes.CreateEncryptor().TransformFinalBlock($bayt, 0, $bayt.Length)
$paketDir = Join-Path $kok 'veri\canli'
New-Item -ItemType Directory -Force $paketDir | Out-Null
$cikJson = ConvertTo-Json -Compress -InputObject ([ordered]@{
  oturum=$oturum; iv=[Convert]::ToBase64String($aes.IV); veri=[Convert]::ToBase64String($enc)
  not='AES-256-CBC. Anahtar oturum saatinde yayinlanir; ondan once bu dosya ACILAMAZ.'
})
[IO.File]::WriteAllText((Join-Path $paketDir "$oturum.enc.json"), $cikJson, (New-Object Text.UTF8Encoding($false)))

# --- anahtar REPO DISINA
$keyDir = Join-Path (Split-Path -Parent $kok) 'canli-anahtarlar'
New-Item -ItemType Directory -Force $keyDir | Out-Null
[IO.File]::WriteAllText((Join-Path $keyDir "$oturum.key"), [Convert]::ToBase64String($aes.Key), (New-Object Text.UTF8Encoding($false)))

# --- KARNE (sifresiz kapak): paket icerigi sifreli oldugu icin disaridan
#     denetlenemiyordu. Karne yalnizca ders x adet tutar - soru metni, dogru sik
#     ya da aciklama ICERMEZ, dolayisiyla public repoda durmasi sizinti degildir.
$karne = [ordered]@{
  oturum=$oturum; sinav=$sinav; uretim=$govde.uretim; sure_dk=$govde.sure_dk
  hedef_soru=$hedef; paket_soru=$paketSoru.Count
  bilesim = @($plan | ForEach-Object {
      $pd=$_.ders
      [ordered]@{ ders=$pd; hedef=$_.n; gelen=@($paketSoru | Where-Object { DersEslesirMi $_.ders $pd }).Count } })
  eksikler = @($eksikler)
}
[IO.File]::WriteAllText((Join-Path $paketDir "$oturum-karne.json"), (ConvertTo-Json -InputObject $karne -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ("karne: veri/canli/{0}-karne.json ({1}/{2} soru)" -f $oturum, $paketSoru.Count, $hedef)

Write-Host ("PAKET HAZIR: veri/canli/{0}.enc.json ({1} KB, {2} soru) | anahtar: canli-anahtarlar\{0}.key (REPO DISI)" -f $oturum, [int]($cikJson.Length/1kb), $paketSoru.Count)
Write-Host 'Yayin ani: .\motor\canli-anahtar-yayinla.ps1 -oturum ' + $oturum
