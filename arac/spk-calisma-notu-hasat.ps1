#requires -Version 5.1
<#
================================================================================
  SPK ÇALIŞMA NOTLARI HASADI (10.09.2026)

  NE YAPAR: SPL'nin yayımladığı lisanslama sınavı çalışma notlarını (modül
  1001-1023, "Klasik Format" PDF'leri) indirir, metne çevirir ve RAG motorunun
  `yutdizin` komutunun okuduğu JSON biçiminde yerel kasaya yazar.

  NEDEN GEREKLİ: SPK'da çıkmış sınav sorusu YOK (ölçüldü 10.09 — SPL geçmiş
  soruları yayımlamıyor). Elimizdeki tek resmî içerik kaynağı bu notlar +
  SPK mevzuatı. Notlar müfredatın kendisidir; konu kartlarının dayanağı burada.

  ⚠️ İKİ TÜR AYRI YAZILIR:
     tur = "spk-calisma-notu"   -> DAYANAK olabilir (müfredat içeriği)
     tur = "sinav-calisma-sorusu" -> DAYANAK OLAMAZ (soru metni; sözleşme A1)

  ⚠️ "Görsel Format" İNDİRİLMEZ: klasik formatla AYNI içeriğin görsel olarak
  yeniden düzenlenmiş hâli (SPL'nin kendi ifadesi: "yalnızca görsel düzenleme
  yapılmış olup içerikte herhangi bir farklılık bulunmamaktadır"). İkisini de
  yutmak ambarı MÜKERRER doldurur ve aramada aynı içerik iki kez çıkar.

  ⚠️ ÇIKTI GİT'E GİRMEZ: `_yerel-veri-kasasi/spk-notlari/` (depo kuralı — ham
  PDF ve büyük metin depoya konmaz).

  ÖNKOŞUL: pdftotext (Git Bash ile geliyor: /mingw64/bin/pdftotext)

  KULLANIM
    powershell -NoProfile -File arac/spk-calisma-notu-hasat.ps1
    powershell -NoProfile -File arac/spk-calisma-notu-hasat.ps1 -YalnizListe
================================================================================
#>
param(
  [switch]$YalnizListe,
  [string]$Adres = 'https://spl.com.tr/sinav-calisma-notlari/'
)

$ErrorActionPreference = 'Stop'
try   { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12,Tls13' }
catch { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$kasa    = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\spk-notlari'
$hamDizin = Join-Path $kasa '_pdf'
foreach ($d in @($kasa, $hamDizin)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null } }

# pdftotext: Git Bash ile geliyor. Yoksa is BASLAMAZ - yarim hasat yapmaktansa
# duruyoruz (yarim veri, olmayan veriden daha tehlikelidir: "yuttuk" sanilir).
$pdftotext = @(
  'C:\Program Files\Git\mingw64\bin\pdftotext.exe',
  'C:\Program Files (x86)\Git\mingw64\bin\pdftotext.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $pdftotext) { $pdftotext = (Get-Command pdftotext -ErrorAction SilentlyContinue).Source }
if (-not $pdftotext) { throw 'pdftotext bulunamadi (Git Bash ile gelir: mingw64\bin\pdftotext.exe). Hasat BASLATILMADI.' }

Write-Host "== SPL calisma notlari listesi cekiliyor ==" -ForegroundColor Cyan
$r = Invoke-WebRequest -Uri $Adres -UseBasicParsing -TimeoutSec 120 `
        -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) mevzuat-radar/1.0' }

# Baglantilar: <a href="...pdf">Klasik Format</a> / <a ...>Calisma Sorulari</a>
$es = [regex]::Matches($r.Content, '(?is)<a[^>]*href="([^"]+\.pdf)"[^>]*>(.*?)</a>')
$adaylar = New-Object System.Collections.Generic.List[object]
foreach ($m in $es) {
  $url = $m.Groups[1].Value
  $etiket = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
  if ($url -notmatch '^https?://') { $url = 'https://spl.com.tr' + $url }

  $tip = if ($etiket -match 'Klasik Format')    { 'not' }
         elseif ($etiket -match 'Çalışma Soru') { 'soru' }
         else { $null }          # Gorsel Format ve digerleri ATLANIR
  if (-not $tip) { continue }

  $modul = if ($url -match '/(\d{4})[_-]') { $Matches[1] } else { 'x' }
  $yeni  = $url -match 'YENI'
  $adaylar.Add([pscustomobject]@{ modul=$modul; tip=$tip; yeni=$yeni; url=$url; etiket=$etiket }) | Out-Null
}

# Ayni modulde birden cok surum varsa YENI olani kazanir (SPL "YENI" damgasi
# mufredat degisikligini isaret ediyor - eskisi gecis takviminde kaliyor).
$secili = $adaylar | Group-Object modul, tip | ForEach-Object {
  $g = $_.Group
  ($g | Sort-Object -Property @{e='yeni';Descending=$true} | Select-Object -First 1)
}

Write-Host ("  aday {0} · secilen {1} (Gorsel Format ATLANDI)" -f $adaylar.Count, @($secili).Count)
$secili | Sort-Object modul, tip | ForEach-Object { Write-Host ("    {0} {1,-5} {2}" -f $_.modul, $_.tip, ($_.url -replace '.*/','')) }
if ($YalnizListe) { return }

Write-Host ""
Write-Host "== Indiriliyor ve metne cevriliyor ==" -ForegroundColor Cyan
$ok = 0; $hata = 0; $toplamKrk = 0
foreach ($a in ($secili | Sort-Object modul, tip)) {
  $pdfYol = Join-Path $hamDizin ("SPK-{0}-{1}.pdf" -f $a.modul, $a.tip)
  $txtYol = Join-Path $hamDizin ("SPK-{0}-{1}.txt" -f $a.modul, $a.tip)
  try {
    if (-not (Test-Path $pdfYol)) {
      Invoke-WebRequest -Uri $a.url -OutFile $pdfYol -UseBasicParsing -TimeoutSec 300 `
        -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) mevzuat-radar/1.0' }
    }
    # -layout YOK: sutunlu duzen metni bozuyor. -enc UTF-8 sart, yoksa Turkce coker.
    & $pdftotext -enc UTF-8 -nopgbrk $pdfYol $txtYol 2>$null | Out-Null
    if (-not (Test-Path $txtYol)) { throw 'pdftotext cikti uretmedi' }

    $metin = Get-Content $txtYol -Raw -Encoding UTF8
    if (-not $metin -or $metin.Length -lt 2000) { throw "metin cok kisa ($($metin.Length) krk) - PDF taranmis goruntu olabilir" }

    # Modul adi: ilk sayfada, "SERMAYE PIYASASI..." gibi buyuk baslik.
    $ilk = ($metin.Substring(0, [Math]::Min(1200, $metin.Length)) -split "`n" |
            ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 12 -and $_ -notmatch '^\d' })
    $ad = if ($ilk) { ($ilk | Select-Object -First 1) } else { "SPK Modul $($a.modul)" }
    if ($ad.Length -gt 90) { $ad = $ad.Substring(0,90) }

    $tur = if ($a.tip -eq 'not') { 'spk-calisma-notu' } else { 'sinav-calisma-sorusu' }
    $nesne = [ordered]@{
      belgeler = @(
        [ordered]@{
          tur        = $tur
          kaynak_ad  = ("SPK {0} - {1}" -f $a.modul, $ad)
          baslik     = $ad
          metin      = $metin
          kaynak_url = $a.url
        }
      )
    }
    $jsonYol = Join-Path $kasa ("SPK-{0}-{1}.json" -f $a.modul, $a.tip)
    $nesne | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonYol -Encoding UTF8

    $ok++; $toplamKrk += $metin.Length
    Write-Host ("  OK  {0} {1,-5} {2,8:N0} krk · {3}" -f $a.modul, $a.tip, $metin.Length, $ad)
  }
  catch {
    $hata++
    Write-Host ("  !!  {0} {1,-5} DUSTU: {2}" -f $a.modul, $a.tip, $_.Exception.Message) -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host ("HASAT: {0} basarili · {1} dusen · {2:N0} karakter" -f $ok, $hata, $toplamKrk) -ForegroundColor Green
Write-Host ("Kasa: {0}" -f $kasa)
Write-Host ""
Write-Host "SIRADAKI:" -ForegroundColor Cyan
Write-Host "  powershell -NoProfile -File rag-motor/motor.ps1 yutdizin `"$kasa`""
