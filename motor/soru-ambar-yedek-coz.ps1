#requires -Version 5.1
<#
================================================================================
  SORU AMBARI YEDEGI COZUCU  (12.09.2026)

  Bulut yedegi (.github/workflows/soru-ambar-yedek.yml) artifact'i sunlari tasir:
    soru-ambar-<damga>-<tablo>.ndjson.gz.enc   AES-256 ile sifreli tablo dokumu
    soru-ambar-<damga>-kunye.json.gz.enc       satir sayilari (dogrulama icin)
    zarf.k.enc                                 AES anahtarinin RSA-4096 zarfi

  Bu betik: zarfi OZEL anahtarla acar, dosyalari cozer, acar ve KUNYEYE GORE
  SATIR SAYAR. Sayi tutmuyorsa KIRMIZI biter - "cozuldu" demek yetmez, yedegin
  TAM oldugu olculur.

  KULLANIM (GitHub'dan artifact zip'ini indirip bir klasore ac):
    powershell -NoProfile -File motor\soru-ambar-yedek-coz.ps1 -Klasor "C:\indirilen\soru-ambar-yedek-3"

  Ozel anahtar: C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key (alacak kasasiyla AYNI
  anahtar - bilerek: korunacak tek sir olsun). -Anahtar ile degistirilebilir.
  openssl: Git for Windows ile gelir; -OpenSsl ile yol verilebilir.

  ⚠ Cozulen dosyalar ACIK METINDIR. Isin bitince sil ya da OneDrive DISINDA tut.
================================================================================
#>
param(
  [Parameter(Mandatory=$true)][string]$Klasor,
  [string]$Anahtar = 'C:\TETIKTE-YEDEK\anahtar\alacak-yedek.key',
  [string]$OpenSsl = '',
  [string]$Hedef   = ''          # bos = $Klasor\_cozuldu
)
$ErrorActionPreference='Stop'

if(-not $OpenSsl){
  foreach($aday in @("$env:ProgramFiles\Git\mingw64\bin\openssl.exe","$env:ProgramFiles\Git\usr\bin\openssl.exe")){
    if(Test-Path $aday){ $OpenSsl=$aday; break }
  }
  if(-not $OpenSsl){ $komut=Get-Command openssl -ErrorAction SilentlyContinue; if($komut){ $OpenSsl=$komut.Source } }
}
if(-not $OpenSsl -or -not (Test-Path $OpenSsl)){ throw 'openssl bulunamadi - Git for Windows kur ya da -OpenSsl ile yol ver.' }
if(-not (Test-Path $Anahtar)){ throw "Ozel anahtar yok: $Anahtar (ikinci kopya: OneDrive _yerel-veri-kasasi\anahtar\, ucuncu: GitHub Secret)." }
if(-not (Test-Path $Klasor)){ throw "klasor yok: $Klasor" }
if(-not $Hedef){ $Hedef=Join-Path $Klasor '_cozuldu' }
New-Item -ItemType Directory -Force $Hedef | Out-Null

$zarf=Join-Path $Klasor 'zarf.k.enc'
if(-not (Test-Path $zarf)){ throw "anahtar zarfi yok: zarf.k.enc" }

# 1) AES anahtarini RSA ozel anahtariyla ac
$gecAnahtar=Join-Path $Hedef '_aes.key'
& $OpenSsl pkeyutl -decrypt -inkey $Anahtar -in $zarf -out $gecAnahtar
if($LASTEXITCODE -ne 0){ throw 'zarf acilamadi - ozel anahtar yanlis ya da bozuk.' }

try{
  $sifreliler=@(Get-ChildItem $Klasor -Filter '*.gz.enc'|Sort-Object Name)
  if(-not $sifreliler.Count){ throw 'cozulecek *.gz.enc dosyasi yok' }
  Write-Host ("cozulecek dosya: {0}" -f $sifreliler.Count) -ForegroundColor Cyan

  foreach($dosya in $sifreliler){
    $gzAd=$dosya.Name -replace '\.enc$',''          # ...ndjson.gz
    $gzYol=Join-Path $Hedef $gzAd
    & $OpenSsl enc -d -aes-256-cbc -pbkdf2 -in $dosya.FullName -out $gzYol -pass ("file:$gecAnahtar")
    if($LASTEXITCODE -ne 0){ throw "cozulemedi: $($dosya.Name)" }
    # gzip'i .NET ile ac (Windows'ta gunzip olmayabilir)
    $duzYol=$gzYol -replace '\.gz$',''
    $girdi=[IO.File]::OpenRead($gzYol)
    try{
      $gz=New-Object System.IO.Compression.GZipStream($girdi,[IO.Compression.CompressionMode]::Decompress)
      try{
        $cikti=[IO.File]::Create($duzYol)
        try{ $gz.CopyTo($cikti) } finally{ $cikti.Dispose() }
      } finally{ $gz.Dispose() }
    } finally{ $girdi.Dispose() }
    Remove-Item $gzYol -Force
    Write-Host ("  {0,-52} {1,8:N1} MB" -f (Split-Path $duzYol -Leaf),((Get-Item $duzYol).Length/1MB))
  }
}
finally{
  # ⛔ AES anahtari diskte BIRAKILMAZ
  if(Test-Path $gecAnahtar){ Remove-Item $gecAnahtar -Force }
}

# 2) ⛔ DOGRULAMA: kunyedeki satir sayisi ile cozulen dosyanin satiri KIYASLANIR.
#    "Cozuldu" demek yetmez; 12.08 dersi: yesil kosu tam veri demek degildir.
$kunyeDosya=@(Get-ChildItem $Hedef -Filter '*-kunye.json'|Select-Object -First 1)
if(-not $kunyeDosya){ Write-Host "⚠ kunye yok - satir dogrulamasi YAPILAMADI" -ForegroundColor Yellow; return }
$ham=Get-Content $kunyeDosya[0].FullName -Raw -Encoding UTF8|ConvertFrom-Json
Write-Host ("`nKUNYE: {0} · toplam {1:N0} satir" -f $ham.olcum,$ham.toplam_satir) -ForegroundColor Cyan
$hata=0
foreach($t in @($ham.tablolar)){
  $ad="soru-ambar-$($ham.damga)-$($t.tablo).ndjson"
  $yol=Join-Path $Hedef $ad
  if(-not (Test-Path $yol)){ Write-Host ("  {0,-14} ⛔ DOSYA YOK" -f $t.tablo) -ForegroundColor Red; $hata++; continue }
  $sayac=0
  $okuyucu=New-Object System.IO.StreamReader($yol,(New-Object Text.UTF8Encoding $false))
  try{ while($okuyucu.ReadLine() -ne $null){ $sayac++ } } finally{ $okuyucu.Dispose() }
  $tam=($sayac -eq [int]$t.yazilan)
  Write-Host ("  {0,-14} {1,7:N0} satir (kunye {2:N0}) {3}" -f $t.tablo,$sayac,[int]$t.yazilan,$(if($tam){'✓'}else{'⛔ TUTMUYOR'})) -ForegroundColor $(if($tam){'Green'}else{'Red'})
  if(-not $tam){ $hata++ }
}
if($hata){ throw "YEDEK DOGRULAMASI DUSTU: $hata tabloda satir tutmuyor." }
Write-Host "`n✓ yedek TAM ve okunabilir. Acik metin: $Hedef" -ForegroundColor Green
Write-Host "  ⚠ isin bitince sil - bu klasor SIFRESIZ soru metni tasiyor." -ForegroundColor Yellow
