# ============================================================================
#  KGK STANDART/TEBLIG YUTUCU (02.08.2026 — Cem: "yutmadigimiz ezberlemedigimiz
#  ne varsa ezberleyelim; soru cikmasa bile okunmasi gereken ne varsa okuyalim")
#
#  NEDEN AYRI BIR YUTUCU: Kanun Aynasi yalniz mevzuat.gov.tr'nin MADDE yapili
#  metinlerini okuyor. KGK'nin Etik Kurallari ve Kalite Yonetim Standartlari
#  ise PARAGRAF numarali (R110.1, A12, 25T gibi) ve kendi sitesinde duruyor -
#  bu yuzden ambara hic girmemislerdi. Denetim dersinin en cok atif alan iki
#  metni bunlar; hakem "yetersiz" derken bir kismi tam da bu bosluktu.
#
#  PARA HARCAMAZ: PDF indirilir, pdftotext ile metne dokulur, basliklara gore
#  parcalanir. API cagrisi YOKTUR. Cikti: veri/mevzuat/<slug>.json
#  (tur=standart-madde) -> mevzuat-yukle.ps1 ambara tasir.
#  GEREKSINIM: pdftotext (poppler-utils).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$tmp  = Join-Path ([IO.Path]::GetTempPath()) "kgkyut"
if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp -Force | Out-Null }

$hedefler = @(
  @{ slug='etik-kurallar'; ad='Bagimsiz Denetciler Icin Etik Kurallar'; kisa='Etik Kurallar';
     url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BagimsizDenetcilerIcinEtik%20Kurallar_11_08_2025.pdf' },
  @{ slug='kys1'; ad='KYS 1 - Denetim Sirketleri Icin Kalite Yonetimi'; kisa='KYS 1';
     url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/KKS/KYS%201.pdf' },
  @{ slug='kys-duyuru'; ad='Kalite Yonetim Standartlari Duyurusu (KYS 1-2, BDS 220 revize)'; kisa='KYS Duyuru';
     url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/KKS/--KAL%C4%B0TE%20Y%C3%96NET%C4%B0M%20STANDARTLARI--%20.pdf' },
  @{ slug='surekli-egitim-tebligi'; ad='Bagimsiz Denetciler Icin Surekli Egitim Tebligi'; kisa='Surekli Egitim Tebligi';
     url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/Mevzuat/S%C3%BCrekli%20E%C4%9Fitim%20Tebli%C4%9Fi/S%C3%BCrekliEgitimTebligi.pdf' }
)

# Parcalama: once MADDE deseni (teblig/yonetmelik), yoksa PARAGRAF deseni
# (R110.1 / 110.1 A1 / A25 / 25T), o da yoksa sabit boy dilim.
function Parcala([string]$metin, [string]$kisa){
  $duz = ($metin -replace "`r", "") -replace "[ \t]+", " "
  $parcalar = New-Object System.Collections.Generic.List[object]

  $rxMadde = [regex]'(?m)^\s*(?<tur>MADDE|Madde|GEÇİCİ MADDE|Geçici MADDE|EK MADDE)\s+(?<no>\d+)\s*[–—-]'
  $m = $rxMadde.Matches($duz)
  if($m.Count -ge 3){
    for($i=0; $i -lt $m.Count; $i++){
      $bas = $m[$i].Index
      $son = if($i -lt $m.Count-1){ $m[$i+1].Index } else { $duz.Length }
      $govde = $duz.Substring($bas, $son-$bas).Trim()
      if($govde.Length -lt 60){ continue }
      $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} m.{1}" -f $kisa, $m[$i].Groups['no'].Value)
                                baslik=("{0} madde {1}" -f $kisa, $m[$i].Groups['no'].Value); metin=$govde })
    }
    return $parcalar
  }

  $rxPar = [regex]'(?m)^\s*(?<no>(?:R)?\d{1,3}(?:\.\d{1,3}){0,2}\s?A?\d{0,3}|A\d{1,3}|\d{1,3}T)\s+(?=[A-ZÇĞİÖŞÜ(])'
  $p = $rxPar.Matches($duz)
  if($p.Count -ge 10){
    for($i=0; $i -lt $p.Count; $i++){
      $bas = $p[$i].Index
      $son = if($i -lt $p.Count-1){ $p[$i+1].Index } else { $duz.Length }
      $govde = $duz.Substring($bas, $son-$bas).Trim()
      if($govde.Length -lt 80){ continue }          # icindekiler satiri / sayfa no
      if($govde.Length -gt 6000){ $govde = $govde.Substring(0,6000) }
      $no = ($p[$i].Groups['no'].Value -replace '\s','')
      $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} p.{1}" -f $kisa, $no)
                                baslik=("{0} paragraf {1}" -f $kisa, $no); metin=$govde })
    }
    return $parcalar
  }

  # yedek: 3.000 karakterlik dilimler (hicbir desen tutmazsa metin yine de ambarda dursun)
  $adim = 3000; $s = 0; $n = 1
  while($s -lt $duz.Length){
    $boy = [Math]::Min($adim, $duz.Length - $s)
    $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} bolum {1}" -f $kisa, $n)
                              baslik=("{0} bolum {1}" -f $kisa, $n); metin=$duz.Substring($s,$boy).Trim() })
    $s += $adim; $n++
  }
  return $parcalar
}

$rapor = @()
foreach($h in $hedefler){
  $pdf = Join-Path $tmp ($h.slug + ".pdf")
  $txt = Join-Path $tmp ($h.slug + ".txt")
  $cikti = Join-Path $kok ("veri/mevzuat/" + $h.slug + ".json")
  try {
    Invoke-WebRequest -Uri $h.url -OutFile $pdf -UseBasicParsing -TimeoutSec 240 -UserAgent 'Mozilla/5.0' | Out-Null
    $kb = [math]::Round((Get-Item $pdf).Length/1KB)
    & pdftotext -enc UTF-8 $pdf $txt 2>$null
    if(-not (Test-Path $txt)){ throw "pdftotext cikti uretmedi" }
    $metin = Get-Content $txt -Raw -Encoding UTF8
    $parcalar = Parcala $metin $h.kisa
    if($parcalar.Count -eq 0){ throw "parcalanamadi" }
    [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject ([ordered]@{ belgeler = [object[]]$parcalar }) -Depth 5), $enc)
    Write-Host ("{0}: {1} KB -> {2} parca -> {3}" -f $h.ad, $kb, $parcalar.Count, $cikti)
    $rapor += [ordered]@{ slug=$h.slug; ad=$h.ad; kb=$kb; parca=$parcalar.Count; durum='TAMAM' }
  } catch {
    Write-Host ("{0}: DUSTU - {1}" -f $h.ad, $_.Exception.Message)
    $rapor += [ordered]@{ slug=$h.slug; ad=$h.ad; durum='DUSTU'; hata="$($_.Exception.Message)" }
  }
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/kgk-yut-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); sonuc=[object[]]$rapor }) -Depth 5), $enc)
Write-Host "-> veri/kgk-yut-raporu.json"
