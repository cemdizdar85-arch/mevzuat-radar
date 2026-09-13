#requires -Version 5.1
<#
============================================================================
  FABRIKA YEDEGI  (11.09.2026, Cem: "fabrika ciktisini yedege baglayalim")

  NIYE: veri/fabrika/kalip-parti-*.json uretilmis sorularin TEK kopyasidir.
  Olculdu (11.09): 213 dosya · 96,0 MB · 3.690 soru. Bu klasor .gitignore'da
  oldugu icin depoda YOK; Actions'ta da YOK. Diski kaybedersek soru, adim,
  ikiz, hakem karari, kor cozum ve sade - hepsi gider. 10-11.09'da yalnizca
  `sade` tamamlamasi icin 6,52 USD odendi; toplam fabrika bedeli bunun cok
  ustunde.

  NEDEN DEPOYA COMMIT EDILMIYOR: 96 MB. Depo 30.08'de bilerek 1.055 MB'dan
  80 MB'a indirildi ve CLAUDE.md buyuk dosya commit'ini yasakliyor.

  NE YAPAR
    1) kalip-parti-*.json dosyalarini TEK zip'e alir (JSON cok iyi sikisir)
    2) YAZ -> GERI OKU -> KARSILASTIR: zip icindeki girdi sayisi kaynak dosya
       sayisina esit mi, ve ORNEKLEM dosyanin icerigi bayt bayt ayni mi.
       Esit degilse zip .HATALI uzantisiyla birakilir ve betik 1 ile cikar -
       eksik yedek "yedek var" sanilmasin (alacak yedekcisinin dersi).
    3) -Sifrele verilirse AES-256-CBC + RSA-4096 zarfi uretir (alacak kasasiyla
       AYNI bicim, ayni anahtar cifti). Sifreli kopya makine disina cikarilabilir.
    4) eski yedekleri seyreltir: son 8 + her ayin ilki kalir

  NEREYE: C:\TETIKTE-YEDEK\fabrika  (OneDrive DISI - OneDrive duzenlemeleri
  sessizce geri alabiliyor, 30.08'de yasandi). $env:YEDEK_KOK ile degisir.

  ⚠ BU YEREL BIR YEDEKTIR. Ayni diskte durdugu surece disk arizasina karsi
  korumaz. Makine disina cikarmanin iki yolu var, ikisi de Cem'in karari:
    a) `gh auth login` yapilir, sifreli kopya GitHub artifact'ina yuklenir
       (alacak kasasindaki hat; su an gh girisi YAPILMAMIS)
    b) ikinci fiziksel disk / harici disk
  Bu betik (a) ve (b) icin hazir dosyayi uretir, gondermez.

  ANAHTAR: motor\anahtar\alacak-yedek.pub (acik, depoda).
  OZEL anahtar C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key + OneDrive
  _yerel-veri-kasasi\anahtar - Claude'un eline HIC gecmez.

  KULLANIM
    powershell -NoProfile -File motor\fabrika-yedek.ps1
    powershell -NoProfile -File motor\fabrika-yedek.ps1 -Sifrele
    powershell -NoProfile -File motor\fabrika-yedek.ps1 -Coz "C:\...\fabrika-20260911-0300"
============================================================================
#>
param(
  [switch]$Sifrele,
  [string]$Coz = '',                                    # sifreli yedegi geri ac
  [string]$OzelAnahtar = 'C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key',
  [string]$OpenSsl = ''
)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent

function OpenSslBul([string]$verilen){
  if($verilen -and (Test-Path $verilen)){ return $verilen }
  foreach($aday in @("$env:ProgramFiles\Git\mingw64\bin\openssl.exe","$env:ProgramFiles\Git\usr\bin\openssl.exe")){
    if(Test-Path $aday){ return $aday }
  }
  $c = Get-Command openssl -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return ''
}

# ---------------------------------------------------------------- COZME YOLU
if($Coz){
  $ossl = OpenSslBul $OpenSsl
  if(-not $ossl){ throw 'openssl bulunamadi - Git for Windows kur ya da -OpenSsl ile yol ver.' }
  if(-not (Test-Path $OzelAnahtar)){ throw "Ozel anahtar yok: $OzelAnahtar" }
  $sif = Get-ChildItem $Coz -Filter 'fabrika-*.zip.enc' | Sort-Object Name -Descending | Select-Object -First 1
  if(-not $sif){ throw "Klasorde fabrika-*.zip.enc yok: $Coz" }
  $zarf = Join-Path $Coz ($sif.Name -replace '\.zip\.enc$','.zip.k.enc')
  if(-not (Test-Path $zarf)){ throw "Anahtar zarfi yok: $zarf" }
  $hedefZip = Join-Path $Coz ($sif.Name -replace '\.enc$','')
  $gecici = Join-Path $Coz '_k.tmp'
  & $ossl pkeyutl -decrypt -inkey $OzelAnahtar -in $zarf -out $gecici
  if($LASTEXITCODE -ne 0){ throw 'Zarf acilamadi - ozel anahtar bu yedegin acik anahtariyla eslesmiyor olabilir.' }
  & $ossl enc -d -aes-256-cbc -pbkdf2 -in $sif.FullName -out $hedefZip -pass "file:$gecici"
  $kodC = $LASTEXITCODE
  [IO.File]::Delete($gecici)
  if($kodC -ne 0){ throw 'Dosya cozulemedi.' }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $z = [IO.Compression.ZipFile]::OpenRead($hedefZip)
  $n = $z.Entries.Count; $z.Dispose()
  Write-Host ("COZULDU: {0} · {1} dosya" -f (Split-Path $hedefZip -Leaf), $n) -ForegroundColor Green
  return
}

# ---------------------------------------------------------------- YEDEK YOLU
$kaynakDir = Join-Path $kok 'veri\fabrika'
$dosyalar = @(Get-ChildItem $kaynakDir -Filter 'kalip-parti-*.json' -File)
if(-not $dosyalar.Count){ throw "Yedeklenecek dosya yok: $kaynakDir\kalip-parti-*.json" }
# ⛔⭐ 13.09.2026 — GEDIK KAPANDI: GM'IN ELLE YAZDIGI SORULAR YEDEGE GIRMIYORDU.
#   Bu betik yalniz kalip-parti-*.json aliyordu. Ama `hazir-*.json` dosyalari GM'in
#   oturumda ELLE yazdigi sorularin KAYNAK kopyasidir ve onlar da .gitignore'da:
#   depoda YOK, ambarda YOK, bu yedekte de YOKTU. Olculdu 13.09: 143 dosya, 11,1 MB,
#   birlestirilmis dosyalarda 766 soru - hepsi TEK kopya halinde bu diskteydi.
#   Ayni gece t2b-meslek partisinin ISLENMIS hali ambarda bulunamadi (10.09'da kostugu
#   denetim sayfasindan belli). Kaynak dosyalar sagdi ama yedek olmasaydi o da giderdi.
#   hazir-dusen-* ALINMAZ: onlar kod kapisinda dusen sorularin kutugu, kaynak degil.
$dosyalar += @(Get-ChildItem $kaynakDir -Filter 'hazir-*.json' -File | Where-Object { $_.Name -notlike 'hazir-dusen-*' })

$yedekKok = if("$($env:YEDEK_KOK)".Trim()){ $env:YEDEK_KOK } else { 'C:\TETIKTE-YEDEK\fabrika' }
if(-not (Test-Path $yedekKok)){ New-Item -ItemType Directory -Force $yedekKok | Out-Null }
$log = Join-Path $yedekKok 'yedek-log.txt'
trap { try{ Add-Content $log ("{0}  !! HATA: {1}" -f (Get-Date).ToString('dd.MM.yyyy HH:mm'), $_.Exception.Message) }catch{}; break }

$damga = (Get-Date).ToString('yyyyMMdd-HHmm')
$zipYol = Join-Path $yedekKok "fabrika-$damga.zip"
$hamMB = ($dosyalar | Measure-Object Length -Sum).Sum/1MB
Write-Host ("KAYNAK: {0} dosya · {1:N1} MB" -f $dosyalar.Count, $hamMB) -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
if(Test-Path $zipYol){ Remove-Item $zipYol -Force }
$zip = [IO.Compression.ZipFile]::Open($zipYol,'Create')
try{
  foreach($d in $dosyalar){
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$d.FullName,$d.Name,[IO.Compression.CompressionLevel]::Optimal)
  }
} finally { $zip.Dispose() }

# --- YAZ -> GERI OKU -> KARSILASTIR ------------------------------------------
# Sayi esitligi yetmez: zip "tamam" gorunup icerigi bozuk olabilir. O yuzden
# rastgele 3 dosyanin icerigi zip'ten geri okunup bayt bayt kiyaslanir.
$okZip = [IO.Compression.ZipFile]::OpenRead($zipYol)
$zipSayi = $okZip.Entries.Count
$ornekOk = 0; $ornekHata = @()
foreach($d in ($dosyalar | Get-Random -Count ([Math]::Min(3,$dosyalar.Count)))){
  $e = $okZip.Entries | Where-Object { $_.Name -eq $d.Name } | Select-Object -First 1
  if(-not $e){ $ornekHata += "$($d.Name): zip'te yok"; continue }
  $sr = New-Object IO.StreamReader($e.Open(),[Text.UTF8Encoding]::new($false))
  $icZip = $sr.ReadToEnd(); $sr.Close()
  $icDisk = [IO.File]::ReadAllText($d.FullName,[Text.UTF8Encoding]::new($false))
  if($icZip -ceq $icDisk){ $ornekOk++ } else { $ornekHata += "$($d.Name): icerik farkli ($($icZip.Length) vs $($icDisk.Length) karakter)" }
}
$okZip.Dispose()
$zipMB = (Get-Item $zipYol).Length/1MB

if($zipSayi -ne $dosyalar.Count -or $ornekHata.Count){
  $hatali = $zipYol + '.HATALI'
  Move-Item $zipYol $hatali -Force
  $sebep = if($zipSayi -ne $dosyalar.Count){ "zip $zipSayi != kaynak $($dosyalar.Count)" } else { ($ornekHata -join ' | ') }
  Add-Content $log ("{0}  !! EKSIK/BOZUK YEDEK: {1}" -f (Get-Date).ToString('dd.MM.yyyy HH:mm'), $sebep)
  throw "YEDEK GECERSIZ ($sebep). Dosya $hatali olarak birakildi."
}

$satir = ("{0}  dosya={1}  ham={2:N1} MB  zip={3:N1} MB  orneklem={4}/3 OK  {5}" -f (Get-Date).ToString('dd.MM.yyyy HH:mm'), $zipSayi, $hamMB, $zipMB, $ornekOk, (Split-Path $zipYol -Leaf))
Add-Content $log $satir
Write-Host ("YEDEK TAMAM: {0} dosya · {1:N1} MB -> {2:N1} MB (%{3:N0} sikisma) · orneklem {4}/3 bayt bayt ayni" -f $zipSayi,$hamMB,$zipMB,(100-100*$zipMB/$hamMB),$ornekOk) -ForegroundColor Green
Write-Host ("  -> {0}" -f $zipYol)

# --- SIFRELEME (istege bagli) --------------------------------------------------
if($Sifrele){
  $ossl = OpenSslBul $OpenSsl
  $pub = Join-Path $kok 'motor\anahtar\alacak-yedek.pub'
  if(-not $ossl){ Write-Host 'SIFRELEME ATLANDI: openssl bulunamadi.' -ForegroundColor Yellow }
  elseif(-not (Test-Path $pub)){ Write-Host "SIFRELEME ATLANDI: acik anahtar yok ($pub)" -ForegroundColor Yellow }
  else{
    # AES anahtari 32 rastgele bayt; Claude'un contextine GIRMEZ (dosyaya yazilir,
    # RSA ile zarflanir, ham hali hemen silinir).
    $kYol = Join-Path $yedekKok '_aes.tmp'
    $bayt = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bayt)
    [IO.File]::WriteAllText($kYol,[Convert]::ToBase64String($bayt),[Text.UTF8Encoding]::new($false))
    & $ossl enc -aes-256-cbc -pbkdf2 -salt -in $zipYol -out "$zipYol.enc" -pass "file:$kYol"
    $k1=$LASTEXITCODE
    & $ossl pkeyutl -encrypt -pubin -inkey $pub -in $kYol -out "$zipYol.k.enc"
    $k2=$LASTEXITCODE
    [IO.File]::Delete($kYol)
    if($k1 -ne 0 -or $k2 -ne 0){ throw "Sifreleme dustu (enc=$k1 zarf=$k2)" }
    Write-Host ("SIFRELENDI: {0}.enc ({1:N1} MB) + {0}.k.enc" -f (Split-Path $zipYol -Leaf),((Get-Item "$zipYol.enc").Length/1MB)) -ForegroundColor Green
    Write-Host "  Bu iki dosya makine disina cikarilabilir. Geri acma: -Coz <klasor>"
  }
}

# --- ESKI YEDEKLERI SEYRELT: son 8 + her ayin ilki --------------------------
$hepsi = Get-ChildItem $yedekKok -Filter 'fabrika-*.zip' | Sort-Object Name -Descending
$tut=@{}; $i=0
foreach($d in $hepsi){
  $i++
  $ay = $d.Name.Substring(8,6)   # fabrika-yyyyMM...
  if($i -le 8){ $tut[$d.FullName]=1; continue }
  if(-not $tut.ContainsKey("ay:$ay")){ $tut["ay:$ay"]=1; $tut[$d.FullName]=1; continue }
  foreach($ek in @('','.enc','.k.enc')){ $y="$($d.FullName)$ek"; if(Test-Path $y){ Remove-Item $y -Force } }
  Write-Host ("  eski yedek silindi: {0}" -f $d.Name)
}
