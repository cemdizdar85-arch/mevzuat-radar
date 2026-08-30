# ============================================================================
#  SPK MEVZUAT SISTEMI INDIRICI (30.08.2026 — Cem: "burdaki resmi kaynaklarin
#  hepsini indirelim yutalim")
#
#  KAYNAK: https://mevzuat.spk.gov.tr  — SERMAYE PIYASASI KURULU'nun KENDI
#  mevzuat sistemi. SPK bir KAMU KURUMUDUR; bu, ihdas eden merciin birincil
#  kaynagidir. Ucuncu taraf ayna KULLANILMAZ.
#
#  NEDEN AYRI BIR HAT — mevzuat.gov.tr bunu KARSILAMIYOR:
#  Portalda 389 belge var ve bunlarin 258'i ILKE KARARI / KURUL KARARI.
#  mevzuat.gov.tr kurul kararlarini TUTMAZ (bu depoda daha once olculdu ve
#  kurul-karari-hasat.ps1 tam bu bosluk icin RG fihristini tarayarak yazildi).
#  Yani bu hat, ambardaki bilinen bir DELIGI birincil kaynaktan kapatir.
#
#  UCLAR (tarayicida gercek ag istekleri okunarak bulundu, tahmin edilmedi):
#    GET /api/Search/All            -> 389 kayit, tam metadata (tur, RG, kisim)
#    GET /api/mevzuat/List          -> 121 kayit + 'mulga' bayragi
#    GET /api/rehber/List           ->  10 kayit
#    GET /api/mevzuat/File/{id}     -> application/pdf
#    GET /api/ilkekarari/File/{id}  -> application/pdf
#    GET /api/rehber/File/{id}      -> application/pdf
#  NOT: bilinmeyen /api/ yollari HTTP 200 + SPA kabugu (2.8 KB HTML) doner.
#  Bu yuzden "200 geldi" YETMEZ; content-type ve %PDF imzasi sarttir.
#
#  DORT KAPI (spl-resmi-indir.ps1 ile ayni doktrin):
#   (1) beklenen liste koda GOMULMEZ, her kosuda API'den taze okunur
#   (2) YARIM INME: sunucunun Content-Length'i ile diskteki bayt karsilastirilir
#   (3) %PDF imzasi (SPA kabugu de 200 doner - en sinsi tuzak burada)
#   (4) pdftotext ile metin cikiyor mu; cikmiyorsa gorsel-tabanli mi diye
#       bakilir (gorselse dosya TAM sayilir, durum OLCULEMEDI olur)
#
#  GUNCELLIK: "eski degil" DENMEZ, OLCULUR. API'nin kendi 'mulga' bayragi ve
#  resmiGazeteTarih alani envantere yazilir; hangi belge yururlukte, hangisi
#  mulga, en yeni RG tarihi ne - hepsi veri/spk-mevzuat-envanteri.json'da.
#
#  PDF'ler DEPOYA GIRMEZ (depo PUBLIC; VERI-HARITASI: ham kaynak yalniz disk).
# ============================================================================
param([switch]$zorla, [switch]$sessiz, [string]$hedef = '')

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $hedef){ $hedef = Join-Path $kok '_kaynak\spk-mevzuat' }
if(-not (Test-Path $hedef)){ New-Item -ItemType Directory -Path $hedef -Force | Out-Null }
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$KOK_URL = 'https://mevzuat.spk.gov.tr'
$ASGARI_BAYT = 3000

# Ag isleri curl.exe ile (PS 5.1 IWR bazi TLS yapilandirmalarinda baglanamiyor;
# ayrica IWR ikili icerigi bozabiliyor - dis-kaynak cekme dersi).
$curl = "$env:SystemRoot\System32\curl.exe"
if(-not (Test-Path $curl)){ $c = Get-Command curl.exe -ErrorAction SilentlyContinue; if($c){ $curl = $c.Source } else { throw 'curl.exe bulunamadi' } }
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue

function Json([string]$yol){
  $t = [IO.Path]::GetTempFileName()
  & $curl -sS -m 120 -A $UA -H 'Accept: application/json' -L "$KOK_URL$yol" -o $t | Out-Null
  $ham = Get-Content $t -Raw -Encoding UTF8
  Remove-Item $t -Force -ErrorAction SilentlyContinue
  if("$ham".TrimStart().StartsWith('<')){ throw "API JSON yerine HTML dondu: $yol" }
  return ($ham | ConvertFrom-Json)
}

# --- 1) BEKLENEN LISTE: resmi API'den, her kosuda taze ----------------------
if(-not $sessiz){ Write-Host "Resmi API okunuyor: $KOK_URL/api/Search/All" }
$tumu   = @(Json '/api/Search/All')
$mevzuat= @(Json '/api/mevzuat/List')
$rehber = @(Json '/api/rehber/List')
if($tumu.Count -eq 0){ Write-Host 'KOR: Search/All bos dondu - API degismis olabilir. Indirme YAPILMADI.' -ForegroundColor Yellow; exit 2 }

# mulga bayragi yalniz mevzuat listesinde var; contentID uzerinden eslestir
$mulgaHar = @{}
foreach($m in $mevzuat){ $mulgaHar["$($m.id)"] = [bool]$m.mulga }

$plan = @()
foreach($x in $tumu){
  $uc = switch("$($x.contentSource)"){
    'Mevzuat'    { "/api/mevzuat/File/$($x.contentID)" }
    'IlkeKarari' { "/api/ilkekarari/File/$($x.contentID)" }
    'Rehber'     { "/api/rehber/File/$($x.contentID)" }
    default      { $null }
  }
  if(-not $uc){ continue }
  $plan += [pscustomobject]@{
    kaynak=$x.contentSource; id=$x.contentID; tur=$x.tur; baslik=$x.title
    sayi=$x.sayi; rg=$x.resmiGazeteTarih; rgSayi=$x.resmiGazeteSayi
    kisim=$x.kisim; bolum=$x.bolum
    mulga = if($x.contentSource -eq 'Mevzuat' -and $mulgaHar.ContainsKey("$($x.contentID)")){ $mulgaHar["$($x.contentID)"] } else { $null }
    uc=$uc; dosya=("{0}-{1}.pdf" -f $x.contentSource, $x.contentID)
  }
}
if(-not $sessiz){ Write-Host ("Beklenen belge: {0} (mevzuat {1} · rehber {2} · ilke/kurul karari {3})" -f $plan.Count, @($plan|?{$_.kaynak -eq 'Mevzuat'}).Count, @($plan|?{$_.kaynak -eq 'Rehber'}).Count, @($plan|?{$_.kaynak -eq 'IlkeKarari'}).Count) }

# --- 2) INDIR + DORT KAPI ---------------------------------------------------
$kayit = @(); $i = 0
foreach($p in $plan){
  $i++
  $yol = Join-Path $hedef $p.dosya
  $s = [ordered]@{ dosya=$p.dosya; tur=$p.tur; sayi=$p.sayi; baslik=$p.baslik; rg=$p.rg; mulga=$p.mulga
                   uc=$p.uc; durum='KIRMIZI'; sebep=''; bayt=0; beklenen_bayt=$null; metin_krk=0 }
  try {
    $bek = $null
    try {
      $bas = & $curl -sSI -m 60 -A $UA -L "$KOK_URL$($p.uc)" 2>$null
      $cl = @($bas | Where-Object { $_ -match '(?i)^content-length:' }) | Select-Object -Last 1
      if($cl){ $bek = [int64](("$cl" -replace '(?i)^content-length:\s*','').Trim() -replace '\D','') }
      if($bek -eq 0){ $bek = $null }
    } catch {}
    $s.beklenen_bayt = $bek

    $indir = $true
    if((Test-Path $yol) -and -not $zorla -and $bek -and (Get-Item $yol).Length -eq $bek){ $indir = $false }
    if($indir){
      $ok=$false; $kodC=''
      for($d=1; $d -le 3 -and -not $ok; $d++){
        $kodC = (& $curl -sS -m 180 -A $UA -L "$KOK_URL$($p.uc)" -o $yol -w "%{http_code}" 2>$null)
        if("$kodC".Trim() -eq '200'){ $ok=$true } else { Start-Sleep -Seconds (2*$d) }
      }
      if(-not $ok){ $s.sebep = "HTTP $kodC (3 deneme)"; $kayit += [pscustomobject]$s; continue }
    }
    if(-not (Test-Path $yol)){ $s.sebep='dosya olusmadi'; $kayit += [pscustomobject]$s; continue }
    $s.bayt = (Get-Item $yol).Length

    if($bek -and $s.bayt -ne $bek){ $s.sebep = "YARIM INDI: $($s.bayt)/$bek bayt"; $kayit += [pscustomobject]$s; continue }
    if($s.bayt -lt $ASGARI_BAYT){ $s.sebep = "COK KUCUK: $($s.bayt) bayt"; $kayit += [pscustomobject]$s; continue }
    $b4 = [IO.File]::ReadAllBytes($yol)[0..3]
    if(-not ($b4[0] -eq 0x25 -and $b4[1] -eq 0x50 -and $b4[2] -eq 0x44 -and $b4[3] -eq 0x46)){
      $s.sebep = 'PDF DEGIL (SPA kabugu gelmis olabilir)'; $kayit += [pscustomobject]$s; continue
    }
    if($pdftotext){
      $t = [IO.Path]::GetTempFileName()
      try { & pdftotext -enc UTF-8 -q $yol $t 2>$null; $metin = if(Test-Path $t){ Get-Content $t -Raw -Encoding UTF8 } else { '' }; $s.metin_krk = "$metin".Trim().Length } finally { Remove-Item $t -Force -ErrorAction SilentlyContinue }
      # 30.08 ESIK DUZELTMESI (olculdu, IlkeKarari-185 vakasi): esik 300'du ve
      # GERCEK bir belgeyi "bozuk" saydi. O dosya tek sayfalik, 220 karakterlik
      # bir ilke karari: "...i-SPK.128.7 ile yururlukten kaldirilmistir." Yani
      # icerigi gercekten o kadar. Kurul kararlari cok kisa olabilir; esik
      # 60 karaktere indirildi. 60 altinda + gorsel de yoksa gercekten bozuktur.
      if($s.metin_krk -lt 60){
        $gorsel=$false
        try { $gorsel = @(& pdfimages -list $yol 2>$null | Where-Object { $_ -match '\bimage\b|\bsmask\b' }).Count -gt 0 } catch {}
        if($gorsel){ $s.durum='KOR'; $s.sebep="GORSEL-TABANLI PDF ($($s.metin_krk) krk) - dosya TAM, OCR ister" }
        else { $s.sebep="METIN YOK ve GORSEL YOK ($($s.metin_krk) krk) - bozuk olabilir" }
        $kayit += [pscustomobject]$s; continue
      }
    } else { $s.durum='KOR'; $s.sebep='pdftotext yok - metin kapisi OLCULEMEDI'; $kayit += [pscustomobject]$s; continue }

    $s.durum='YESIL'; $kayit += [pscustomobject]$s
  } catch { $s.sebep = "HATA: $($_.Exception.Message)"; $kayit += [pscustomobject]$s }

  if(-not $sessiz -and ($i % 25 -eq 0 -or $kayit[-1].durum -ne 'YESIL')){
    $son=$kayit[-1]; $renk = switch($son.durum){ 'YESIL'{'Green'} 'KIRMIZI'{'Red'} default{'Yellow'} }
    Write-Host ("  [{0}/{1}] [{2}] {3} {4}" -f $i,$plan.Count,$son.durum,$son.dosya,$(if($son.sebep){"· $($son.sebep)"}else{''})) -ForegroundColor $renk
  }
}

# --- 3) HUKUM + ENVANTER ----------------------------------------------------
$yesil=@($kayit|?{$_.durum -eq 'YESIL'}); $kirmizi=@($kayit|?{$_.durum -eq 'KIRMIZI'}); $kor=@($kayit|?{$_.durum -eq 'KOR'})
$hukum = if($kirmizi.Count){'KIRMIZI'} elseif($kor.Count){'KOR'} else {'YESIL'}
# 30.08 KUSUR (olculdu): RG tarihleri "31.12.2020" gibi gg.aa.yyyy METIN olarak
# geliyordu ve duz Sort-Object bunlari ALFABETIK siraliyordu. Sonuc: "31.12.2020"
# harf sirasinda "01.08.2026"dan buyuk gorunuyor ve envanter EN YENI BELGEYI
# 2020 diye yaziyordu - yani "guncel mi?" sorusuna YANLIS cevap veriyordu.
# Artik gercek tarihe cevrilip oyle siralanir. Ders: tarihi metin gibi sirala,
# yalan soyler.
$rgler = @($kayit | Where-Object { $_.rg } | ForEach-Object {
  $d = $null
  foreach($kalip in @('dd.MM.yyyy','yyyy-MM-ddTHH:mm:ss','yyyy-MM-dd')){
    try { $d = [datetime]::ParseExact("$($_.rg)", $kalip, [Globalization.CultureInfo]::InvariantCulture); break } catch {}
  }
  if(-not $d){ try { $d = [datetime]"$($_.rg)" } catch {} }
  if($d){ $d }
} | Sort-Object) | ForEach-Object { $_.ToString('yyyy-MM-dd') }
$env2 = [ordered]@{
  olcum=(Get-Date).ToString('s'); kaynak=$KOK_URL
  kaynak_turu='RESMI - Sermaye Piyasasi Kurulu (kamu kurumu) kendi mevzuat sistemi; ucuncu taraf ayna kullanilmadi'
  beklenen=$plan.Count; tam=$yesil.Count; eksik=$kirmizi.Count; olculemeyen=$kor.Count; hukum=$hukum
  tur_dagilimi = ($kayit | Group-Object tur | ForEach-Object { @{ tur=$_.Name; adet=$_.Count } })
  mulga_sayisi = @($kayit | Where-Object { $_.mulga -eq $true }).Count
  yururlukte_sayisi = @($kayit | Where-Object { $_.mulga -eq $false }).Count
  mulga_bilinmiyor = @($kayit | Where-Object { $null -eq $_.mulga }).Count
  en_eski_rg = if($rgler.Count){ $rgler[0] } else { $null }
  en_yeni_rg = if($rgler.Count){ $rgler[-1] } else { $null }
  indirme_yeri=$hedef
  not='mulga/RG alanlari API''nin KENDI alanlaridir - "guncel" iddiasi tahminle degil buradan kurulur. Ilke/Kurul Karari icin mulga bayragi API''de YOK: o satirlar mulga_bilinmiyor sayilir.'
  dosyalar=$kayit
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\spk-mevzuat-envanteri.json'), (ConvertTo-Json -InputObject $env2 -Depth 6), [Text.UTF8Encoding]::new($false))

if(-not $sessiz){
  Write-Host ''
  Write-Host ("BEKLENEN {0} · TAM {1} · EKSIK {2} · OLCULEMEYEN {3}" -f $plan.Count,$yesil.Count,$kirmizi.Count,$kor.Count)
  foreach($k in $kirmizi){ Write-Host ("  EKSIK: {0} · {1}" -f $k.dosya,$k.sebep) -ForegroundColor Red }
  foreach($k in ($kor | Select-Object -First 10)){ Write-Host ("  OLCULEMEDI: {0} · {1}" -f $k.dosya,$k.sebep) -ForegroundColor Yellow }
  Write-Host ("GUNCELLIK (API alanlarindan): yururlukte {0} · mulga {1} · bilinmiyor {2} · en yeni RG {3}" -f $env2.yururlukte_sayisi,$env2.mulga_sayisi,$env2.mulga_bilinmiyor,$env2.en_yeni_rg)
  Write-Host ("HUKUM: {0}" -f $hukum) -ForegroundColor $(if($hukum -eq 'YESIL'){'Green'}elseif($hukum -eq 'KIRMIZI'){'Red'}else{'Yellow'})
  Write-Host ("  -> veri/spk-mevzuat-envanteri.json · PDF'ler: {0}" -f $hedef)
}
if($hukum -eq 'KIRMIZI'){ exit 1 }
exit 0
