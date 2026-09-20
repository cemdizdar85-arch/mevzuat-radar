#requires -Version 5.1
<#
  2026 MEVZUAT DEĞİŞİKLİĞİ SÜZGECİ — sınav derslerine göre
  20.09.2026, Cem: "2026'da yeni çıkan ... hangi kanun değişiyorsa hemen sisteme giriyor mu,
  böyle bilgi veren 10'a yakın video yapıp paylaşalım" → önce MALZEME SÜZÜLÜR.

  Ne yapar: veri/mevzuat-hazir altındaki resmî metinlerde 2026 tarihli değişiklik ibarelerini
  ("Değişik:12/2/2026-7574/3 md.", "Ek fıkra:...", "Mülga:...") bulur, her birini en yakın
  ÜSTTEKİ madde başlığıyla eşler ve dosyayı sınav dersine bağlar.

  Çıktı: ders → kanun → madde → hangi torba kanunla değiştiği. Video sırası buradan seçilir.

  Kullanım:
    powershell -NoProfile -File arac\mevzuat-degisiklik-suzgeci.ps1
    powershell -NoProfile -File arac\mevzuat-degisiklik-suzgeci.ps1 -Yil 2026 -EnCok 40
    powershell -NoProfile -File arac\mevzuat-degisiklik-suzgeci.ps1 -Sinav
#>
param(
  [int]$Yil = 2026,
  [int]$EnCok = 0,
  [switch]$Sinav
)
$ErrorActionPreference = 'Stop'

# dosya adi parcasi -> sinav dersi. Sinav = hangi sinavlarda sorulur.
$DERSLER = @(
  @{ ders = 'Vergi Hukuku';                sinavlar = 'SGS + Yeterlilik'; anahtar = @('vuk','gvk','kvk','kdvk','damga','aatuhk','otv','harclar','emlak','mtv','veraset','vergi') },
  @{ ders = 'Ticaret Hukuku';              sinavlar = 'SGS + Yeterlilik'; anahtar = @('ttk','ticaret','sermayepiyasa','spk','rekabet','marka','sinai','cek','kooperatif') },
  @{ ders = 'Borclar Hukuku';              sinavlar = 'SGS';              anahtar = @('borclar','tbk') },
  @{ ders = 'Is ve Sosyal Guvenlik';       sinavlar = 'SGS + Yeterlilik'; anahtar = @('isk','4857','5510','issizlik','sendika','isg','6331','sosyalguvenlik') },
  @{ ders = 'Meslek Hukuku';               sinavlar = 'SGS + Yeterlilik + KGK'; anahtar = @('3568','smmm','tesmer','turmob','meslek') },
  @{ ders = 'Icra Iflas';                  sinavlar = 'Yeterlilik';       anahtar = @('iik','icra','konkordato') },
  @{ ders = 'Muhasebe / Denetim';          sinavlar = 'SGS + Yeterlilik + KGK'; anahtar = @('tms','tfrs','bobi','kgk','bagimsizdenetim','bds','muhasebe','denetimstandart') ; dislama = @('yapidenetim','ickontrol') },
  @{ ders = 'Maliye / Ekonomi';            sinavlar = 'SGS';              anahtar = @('butce','kamumali','borcyonetimi','faiz','tesvik','arge') }
)

function Get-Ders {
  param([string]$DosyaAdi)
  $ad = $DosyaAdi.ToLower()
  foreach ($d in $DERSLER) {
    foreach ($a in $d.anahtar) { if ($ad -like ("*" + $a + "*")) { return $d } }
  }
  return $null
}

# ---------------- OZ-SINAV ----------------
if ($Sinav) {
  $basarisiz = 0
  $t1 = Get-Ders -DosyaAdi 'vuk.txt'
  if (-not $t1 -or $t1.ders -ne 'Vergi Hukuku') { Write-Host "SINAV 1 DUSTU (vuk -> Vergi Hukuku)" -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 1 GECTI (vuk -> Vergi Hukuku)" -ForegroundColor Green }
  $t2 = Get-Ders -DosyaAdi 'cmk.txt'
  if ($t2) { Write-Host ("SINAV 2 DUSTU (cmk sinav disi olmali, gelen: " + $t2.ders + ")") -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 2 GECTI (cmk -> sinav disi)" -ForegroundColor Green }
  $t3 = Get-Ders -DosyaAdi '3568.txt'
  if (-not $t3 -or $t3.ders -ne 'Meslek Hukuku') { Write-Host "SINAV 3 DUSTU (3568 -> Meslek Hukuku)" -ForegroundColor Red; $basarisiz++ }
  else { Write-Host "SINAV 3 GECTI (3568 -> Meslek Hukuku)" -ForegroundColor Green }
  if ($basarisiz -gt 0) { Write-Host ("OZ-SINAV DUSTU: " + $basarisiz) -ForegroundColor Red; exit 1 }
  Write-Host "OZ-SINAV TEMIZ (3/3)" -ForegroundColor Green
  exit 0
}

# ---------------- TARAMA ----------------
$kok = Split-Path -Parent $PSScriptRoot
$klasor = Join-Path $kok 'veri\mevzuat-hazir'
if (-not (Test-Path $klasor)) { throw ("mevzuat klasoru yok: " + $klasor) }

$desen = ('(Değişik|Ek fıkra|Ek madde|Ek bent|Mülga|Değişik ibare)[^)]{0,40}?:\s*(\d{1,2}/\d{1,2}/' + $Yil + ')-(\d{3,4})')
$maddeDeseni = '^\s*(Madde|MADDE|Ek Madde|EK MADDE|Geçici Madde)\s*([0-9]+[A-Za-z/]*)'

$bulgular = New-Object System.Collections.ArrayList
$dosyalar = Get-ChildItem $klasor -Filter *.txt
foreach ($dosya in $dosyalar) {
  $satirlar = [IO.File]::ReadAllLines($dosya.FullName, [Text.Encoding]::UTF8)
  for ($i = 0; $i -lt $satirlar.Length; $i++) {
    $es = [regex]::Match($satirlar[$i], $desen)
    if (-not $es.Success) { continue }
    # en yakin ustteki madde basligi
    $madde = '(madde bulunamadi)'
    for ($j = $i; $j -ge [Math]::Max(0, $i - 120); $j--) {
      $m2 = [regex]::Match($satirlar[$j], $maddeDeseni)
      if ($m2.Success) { $madde = ($m2.Groups[1].Value + ' ' + $m2.Groups[2].Value); break }
    }
    $dersKaydi = Get-Ders -DosyaAdi $dosya.Name
    [void]$bulgular.Add([pscustomobject]@{
      Ders     = if ($dersKaydi) { $dersKaydi.ders } else { 'SINAV DISI' }
      Sinavlar = if ($dersKaydi) { $dersKaydi.sinavlar } else { '-' }
      Kanun    = $dosya.BaseName
      Madde    = $madde
      Tur      = $es.Groups[1].Value
      Tarih    = $es.Groups[2].Value
      Torba    = $es.Groups[3].Value
      Satir    = $i + 1
    })
  }
}

Write-Host ("taranan dosya: " + $dosyalar.Count + " | " + $Yil + " degisikligi: " + $bulgular.Count)
Write-Host ""

$sinavIci = @($bulgular | Where-Object { $_.Ders -ne 'SINAV DISI' })
$sinavDisi = @($bulgular | Where-Object { $_.Ders -eq 'SINAV DISI' })

Write-Host ("SINAVI ETKILEYEN: " + $sinavIci.Count + "   |   SINAV DISI: " + $sinavDisi.Count) -ForegroundColor Cyan
Write-Host ""
Write-Host "=== DERS DERS SAYIM ===" -ForegroundColor Cyan
$sinavIci | Group-Object Ders | Sort-Object Count -Descending | ForEach-Object {
  $ilk = $_.Group[0]
  Write-Host ("  " + $_.Count.ToString().PadLeft(3) + "  " + $_.Name + "   (" + $ilk.Sinavlar + ")")
}
Write-Host ""
Write-Host "=== TORBA KANUNLAR (sinavi etkileyen kisim) ===" -ForegroundColor Cyan
$sinavIci | Group-Object Torba | Sort-Object Count -Descending | ForEach-Object {
  $t = $_.Group[0].Tarih
  Write-Host ("  " + $_.Count.ToString().PadLeft(3) + "  " + $_.Name + " sayili  (" + $t + ")")
}
Write-Host ""
Write-Host "=== VIDEO ADAYLARI (ders agirligina gore) ===" -ForegroundColor Cyan
$sirali = $sinavIci | Sort-Object Ders, Kanun, Satir
$gosterilecek = if ($EnCok -gt 0) { $sirali | Select-Object -First $EnCok } else { $sirali }
$oncekiDers = ''
foreach ($b in $gosterilecek) {
  if ($b.Ders -ne $oncekiDers) { Write-Host ""; Write-Host ("### " + $b.Ders + "  [" + $b.Sinavlar + "]") -ForegroundColor Yellow; $oncekiDers = $b.Ders }
  Write-Host ("   " + $b.Kanun.PadRight(16) + " " + $b.Madde.PadRight(18) + " " + $b.Tur.PadRight(14) + " " + $b.Torba + " sayili (" + $b.Tarih + ")  satir " + $b.Satir)
}
