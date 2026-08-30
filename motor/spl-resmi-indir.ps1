# ============================================================================
#  SPL RESMI INDIRICI (30.08.2026 — Cem: "yarim kalmasin, eksik inmemesi icin
#  ne gerekiyorsa yap")
#
#  KAYNAK: yalniz RESMI adres — https://spl.com.tr/sinav-calisma-notlari/
#  Ucuncu taraf ayna (web.archive.org vb.) KULLANILMAZ. Ev kurali: her veri
#  resmi/birincil kaynaktan cekilir.
#
#  NEDEN BOYLE YAZILDI — "indirdim" demek yetmez, dort ayri sekilde yarim kalir:
#   (1) BEKLENEN LISTE ESKIR -> liste koda GOMULMEZ, her kosuda resmi sayfadan
#       yeniden okunur. Sayfaya yeni not eklenirse kendiliginden yakalanir.
#   (2) DOSYA YARIM INER     -> sunucunun Content-Length'i ile diskteki bayt
#       KARSILASTIRILIR. En sinsi kusur budur: HTTP 200 doner, dosya yarimdir.
#   (3) DOSYA PDF DEGILDIR   -> 404/hata sayfasi da 200 ile gelebilir; ilk 4
#       bayt '%PDF' degilse REDDEDILIR (dis-kaynak tuzagi dersi).
#   (4) PDF ACILMAZ/BOSTUR   -> pdftotext ile METIN CIKIYOR MU olculur; sayfa
#       sayisi 0 ya da metin bos ise dosya SAYILMAZ.
#  Ucu de gecen dosya "TAM" sayilir; biri bile gecmezse kapi KIRMIZI olur ve
#  EKSIK OLANLARIN ADINI yazar (sessiz eksik yok).
#
#  NEREYE INER: PDF'ler DEPOYA GIRMEZ. Depo PUBLIC ve bu notlar SPL'nin telifli
#  materyalidir (VERI-HARITASI kurali: buyuk ham kaynak -> yalniz disk).
#  Depoya yalniz ENVANTER (veri/spl-not-envanteri.json) girer.
#
#  KULLANIM:
#    powershell -File motor\spl-resmi-indir.ps1            # olc + indir + dogrula
#    powershell -File motor\spl-resmi-indir.ps1 -zorla     # hash ayni olsa da yeniden indir
# ============================================================================
param([switch]$zorla, [switch]$sessiz, [string]$hedef = '')

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $hedef){ $hedef = Join-Path $kok '_kaynak\spl' }
if(-not (Test-Path $hedef)){ New-Item -ItemType Directory -Path $hedef -Force | Out-Null }
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$SAYFA = 'https://spl.com.tr/sinav-calisma-notlari/'
$ASGARI_BAYT = 20000     # 20 KB alti bir calisma notu olamaz; hata sayfasi olabilir

$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue

# 30.08 KUSUR (olculdu): Invoke-WebRequest bu siteye baglanamiyor -
# "SSL/TLS guvenli kanali olusturulamadi" (PS 5.1 / .NET Framework el sikismasi).
# Ayni adres curl.exe ile 200 donuyor. Ag katmani curl.exe'ye alindi; boylece
# hem TLS sorunu biter hem de IWR'nin ikili icerigi bozma tuzagi (dis-kaynak
# cekme dersi) hic yasanmaz - dosya dogrudan diske yazilir.
$curl = "$env:SystemRoot\System32\curl.exe"
if(-not (Test-Path $curl)){ $c = Get-Command curl.exe -ErrorAction SilentlyContinue; if($c){ $curl = $c.Source } else { throw 'curl.exe bulunamadi' } }

# --- 1) BEKLENEN LISTE: resmi sayfadan, her kosuda taze ---------------------
if(-not $sessiz){ Write-Host "Resmi sayfa okunuyor: $SAYFA" }
$sayfaTmp = [IO.Path]::GetTempFileName()
& $curl -sS -m 90 -A $UA -L $SAYFA -o $sayfaTmp | Out-Null
$html = Get-Content $sayfaTmp -Raw -Encoding UTF8
Remove-Item $sayfaTmp -Force -ErrorAction SilentlyContinue
$beklenen = @([regex]::Matches($html, 'href="([^"]*\.pdf)"') | ForEach-Object { $_.Groups[1].Value } |
             ForEach-Object { if($_ -match '^https?://'){ $_ } else { ([uri]::new([uri]$SAYFA, $_)).AbsoluteUri } } |
             Select-Object -Unique)
if($beklenen.Count -eq 0){
  Write-Host "KOR: resmi sayfada TEK PDF baglantisi bulunamadi - sayfa yapisi degismis olabilir." -ForegroundColor Yellow
  Write-Host "     Indirme YAPILMADI. Once ayristirici guncellenmeli." -ForegroundColor Yellow
  exit 2
}
if(-not $sessiz){ Write-Host ("Beklenen dosya (resmi sayfadan): {0}" -f $beklenen.Count) }

# --- 2) INDIR + DORT KAPIDAN GECIR ------------------------------------------
function Sha([string]$yol){ (Get-FileHash -Path $yol -Algorithm SHA256).Hash.Substring(0,16) }

$kayit = @()
$i = 0
foreach($u in $beklenen){
  $i++
  $ad  = [uri]::UnescapeDataString(($u -split '/')[-1])
  $yol = Join-Path $hedef $ad
  $s = [ordered]@{ dosya=$ad; url=$u; durum='KIRMIZI'; sebep=''; bayt=0; beklenen_bayt=$null; sayfa=0; metin_krk=0; hash=$null }

  try {
    # 2a) sunucunun bildirdigi boyut (yarim inme kapisinin olcusu)
    $bek = $null
    try {
      $bas2 = & $curl -sSI -m 60 -A $UA -L $u 2>$null
      $cl = @($bas2 | Where-Object { $_ -match '(?i)^content-length:' }) | Select-Object -Last 1
      if($cl){ $bek = [int64](("$cl" -replace '(?i)^content-length:\s*','').Trim() -replace '\D','') }
      if($bek -eq 0){ $bek = $null }
    } catch {}
    $s.beklenen_bayt = $bek

    $indir = $true
    if((Test-Path $yol) -and -not $zorla -and $bek -and (Get-Item $yol).Length -eq $bek){ $indir = $false }

    if($indir){
      $ok = $false
      for($deneme=1; $deneme -le 3 -and -not $ok; $deneme++){
        $kodC = (& $curl -sS -m 240 -A $UA -L $u -o $yol -w "%{http_code}" 2>$null)
        if("$kodC".Trim() -eq '200'){ $ok = $true } else { Start-Sleep -Seconds (3 * $deneme) }
      }
      if(-not $ok){ $s.sebep = ("HTTP {0} (3 deneme)" -f "$kodC".Trim()); $kayit += [pscustomobject]$s; continue }
    }

    if(-not (Test-Path $yol)){ $s.sebep = 'dosya olusmadi'; $kayit += [pscustomobject]$s; continue }
    $s.bayt = (Get-Item $yol).Length

    # KAPI 1 — yarim inme
    if($bek -and $s.bayt -ne $bek){ $s.sebep = ("YARIM INDI: {0} / {1} bayt" -f $s.bayt, $bek); $kayit += [pscustomobject]$s; continue }
    # KAPI 2 — asgari boyut
    if($s.bayt -lt $ASGARI_BAYT){ $s.sebep = ("COK KUCUK: {0} bayt (hata sayfasi olabilir)" -f $s.bayt); $kayit += [pscustomobject]$s; continue }
    # KAPI 3 — gercekten PDF mi
    $bas = [IO.File]::ReadAllBytes($yol)[0..3]
    if(-not ($bas[0] -eq 0x25 -and $bas[1] -eq 0x50 -and $bas[2] -eq 0x44 -and $bas[3] -eq 0x46)){
      $s.sebep = 'PDF DEGIL (ilk 4 bayt %PDF degil)'; $kayit += [pscustomobject]$s; continue
    }
    # KAPI 4 — acilip metin cikiyor mu
    if($pdftotext){
      $tmp = [IO.Path]::GetTempFileName()
      try {
        & pdftotext -enc UTF-8 -q $yol $tmp 2>$null
        $metin = if(Test-Path $tmp){ Get-Content $tmp -Raw -Encoding UTF8 } else { '' }
        $s.metin_krk = "$metin".Trim().Length
        $s.sayfa = ([regex]::Matches("$metin", "`f")).Count + 1
      } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
      if($s.metin_krk -lt 500){
        # 30.08 KUSUR (olculdu, ozetveri.pdf vakasi): "metin cikmadi" iki AYRI
        # sey demek olabilir ve ikisi ayni sonuc DEGILDIR:
        #   (a) dosya bozuk/yarim indi              -> KIRMIZI (gercek eksik)
        #   (b) PDF gorsel-tabanli, metin katmani yok -> OLCULEMEDI (dosya TAM)
        # ozetveri.pdf PowerPoint ciktisi: 4,3 MB, gomulu font YOK, sayfalar
        # tamamen JPEG. Content-Length birebir tutuyor, %PDF imzasi dogru -
        # yani indirme KUSURSUZ. "Eksik" demek yalan olurdu.
        # Ev kurali: olcemedigine kusur deme; ucuncu sonuc OLCULEMEDI'dir.
        $gorselVar = $false
        try { $gorselVar = @(& pdfimages -list $yol 2>$null | Where-Object { $_ -match '\bimage\b|\bsmask\b' }).Count -gt 0 } catch {}
        if($gorselVar){
          $s.durum = 'KOR'
          $s.sebep = ("GORSEL-TABANLI PDF: metin katmani yok ({0} krk) - dosya TAM, okunmasi OCR ister" -f $s.metin_krk)
          $s.hash = Sha $yol
        } else {
          $s.sebep = ("METIN YOK ve GORSEL YOK: {0} karakter - dosya bozuk olabilir" -f $s.metin_krk)
        }
        $kayit += [pscustomobject]$s; continue
      }
    } else {
      $s.sebep = 'pdftotext yok - metin kapisi OLCULEMEDI'
      $s.durum = 'KOR'; $s.hash = Sha $yol; $kayit += [pscustomobject]$s; continue
    }

    $s.hash = Sha $yol
    $s.durum = 'YESIL'
    $kayit += [pscustomobject]$s
  } catch {
    $s.sebep = "HATA: $($_.Exception.Message)"
    $kayit += [pscustomobject]$s
  }
  if(-not $sessiz){
    $son = $kayit[-1]
    $renk = switch($son.durum){ 'YESIL'{'Green'} 'KIRMIZI'{'Red'} default{'Yellow'} }
    Write-Host ("  [{0}/{1}] [{2}] {3} ({4} bayt{5})" -f $i,$beklenen.Count,$son.durum,$son.dosya,$son.bayt,$(if($son.sebep){" · $($son.sebep)"}else{''})) -ForegroundColor $renk
  }
}

# --- 3) HUKUM + ENVANTER ----------------------------------------------------
$yesil   = @($kayit | Where-Object { $_.durum -eq 'YESIL' })
$kirmizi = @($kayit | Where-Object { $_.durum -eq 'KIRMIZI' })
$kor     = @($kayit | Where-Object { $_.durum -eq 'KOR' })
$hukum = if($kirmizi.Count){ 'KIRMIZI' } elseif($kor.Count){ 'KOR' } else { 'YESIL' }

$env2 = [ordered]@{
  olcum   = (Get-Date).ToString('s')
  kaynak  = $SAYFA
  kaynak_turu = 'RESMI (spl.com.tr) - ucuncu taraf ayna kullanilmadi'
  beklenen = $beklenen.Count
  tam      = $yesil.Count
  eksik    = $kirmizi.Count
  olculemeyen = $kor.Count
  hukum    = $hukum
  indirme_yeri = $hedef
  not = 'PDF depoya girmez (public depo + telifli materyal); yalniz bu envanter girer. Dort kapi: yarim-inme (Content-Length) · asgari boyut · %PDF imzasi · metin cikiyor mu.'
  dosyalar = $kayit
}
$envYol = Join-Path $kok 'veri\spl-not-envanteri.json'
[IO.File]::WriteAllText($envYol, (ConvertTo-Json -InputObject $env2 -Depth 5), [Text.UTF8Encoding]::new($false))

if(-not $sessiz){
  Write-Host ''
  Write-Host ("BEKLENEN {0} · TAM {1} · EKSIK {2} · OLCULEMEYEN {3}" -f $beklenen.Count,$yesil.Count,$kirmizi.Count,$kor.Count)
  foreach($k in $kirmizi){ Write-Host ("  EKSIK: {0} · {1}" -f $k.dosya, $k.sebep) -ForegroundColor Red }
  foreach($k in $kor){ Write-Host ("  OLCULEMEDI: {0} · {1}" -f $k.dosya, $k.sebep) -ForegroundColor Yellow }
  Write-Host ("HUKUM: {0}" -f $hukum) -ForegroundColor $(if($hukum -eq 'YESIL'){'Green'}elseif($hukum -eq 'KIRMIZI'){'Red'}else{'Yellow'})
  Write-Host ("  -> veri/spl-not-envanteri.json  ·  PDF'ler: {0}" -f $hedef)
}

if($hukum -eq 'KIRMIZI'){ exit 1 }
exit 0
