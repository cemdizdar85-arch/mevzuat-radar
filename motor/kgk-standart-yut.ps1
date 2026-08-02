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
     url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/Mevzuat/S%C3%BCrekli%20E%C4%9Fitim%20Tebli%C4%9Fi/S%C3%BCrekliEgitimTebligi.pdf' },
  # ---- 02.08 EKSIK SAYIMI (Cem: "basla hepsini yut") --------------------------
  # BOBI FRS: TFRS uygulamayan, denetime tabi sirketlerin TAMAMI bunu kullanir -
  # Turkiye uygulamasinin belkemigi ve ambarda hic yoktu.
  @{ slug='bobi-frs'; ad='BOBI FRS (Buyuk ve Orta Boy Isletmeler Icin FRS, 2021 surumu)'; kisa='BOBI FRS';
     url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BOB%C4%B0_FRS/EK%202.pdf' },
  @{ slug='kumi-frs'; ad='KUMI FRS (Kucuk ve Mikro Isletmeler Icin FRS) - Kurum duyuru metni'; kisa='KUMI FRS';
     url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/KUMI/KUMI_FRS_Kurum_Sitesi_Duyuru_Metni.pdf' }
)

# Eksik TMS/TFRS standartlari (2023 Mavi Kitap seti - HEAD ile teyit edildi).
foreach($n in @(20,26,32,33,34)){
  $hedefler += @{ slug=("tms$n"); ad=("TMS $n"); kisa=("TMS $n");
    url=("https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2023/Mavi_Kitap/TMS/TMS%20$n.pdf") }
}
foreach($n in @(1,2,6,11,12,14,17)){
  $hedefler += @{ slug=("tfrs$n"); ad=("TFRS $n"); kisa=("TFRS $n");
    url=("https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2023/Mavi_Kitap/TFRS/TFRS%20$n.pdf") }
}

# Parcalama: once MADDE deseni (teblig/yonetmelik), yoksa PARAGRAF deseni
# (R110.1 / 110.1 A1 / A25 / 25T), o da yoksa sabit boy dilim.
# Uzun metni CUMLE SINIRINDAN dilimler - kesmez, kaybetmez.
function Dilimle([string]$govde, [int]$boy){
  $liste = New-Object System.Collections.Generic.List[string]
  $kalan = $govde
  while($kalan.Length -gt $boy){
    $kes = $kalan.Substring(0, $boy)
    $kir = $kes.LastIndexOf('. ')
    if($kir -lt [int]($boy/2)){ $kir = $kes.LastIndexOf(' ') }
    if($kir -lt [int]($boy/2)){ $kir = $boy - 1 }
    $liste.Add($kalan.Substring(0, $kir+1).Trim())
    $kalan = $kalan.Substring($kir+1).Trim()
  }
  if($kalan.Length -gt 0){ $liste.Add($kalan) }
  return $liste
}

function Parcala([string]$metin, [string]$kisa){
  $duz = ($metin -replace "`r", "") -replace "[ \t]+", " "
  $parcalar = New-Object System.Collections.Generic.List[object]

  $rxMadde = [regex]'(?m)^\s*(?<tur>MADDE|Madde|GEÇİCİ MADDE|Geçici MADDE|EK MADDE)\s+(?<no>\d+)\s*[–—-]'
  $m = $rxMadde.Matches($duz)
  if($m.Count -ge 3){
    # ilk maddeden onceki bas kisim (amac/kapsam basligi, RG kunyesi) da girer
    if($m[0].Index -gt 0){
      $on = $duz.Substring(0, $m[0].Index).Trim()
      if($on.Length -gt 0){ $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} - on bolum" -f $kisa); baslik=("{0} on bolum" -f $kisa); metin=$on }) }
    }
    for($i=0; $i -lt $m.Count; $i++){
      $bas = $m[$i].Index
      $son = if($i -lt $m.Count-1){ $m[$i+1].Index } else { $duz.Length }
      $govde = $duz.Substring($bas, $son-$bas).Trim()
      if($govde.Length -eq 0){ continue }
      $no = $m[$i].Groups['no'].Value
      # 02.08: madde yolunda BOY SINIRI YOKTU - BOBI FRS 526 bin karakteri 9
      # devasa parcaya sigdirdi. Kapsama %100 gorunuyordu ama boyle bir parca
      # aramada/retrieval'da ise yaramaz (soru-cevap koca blok dondurur).
      # Kesmiyoruz, DILIMLIYORUZ: 1.800 karakter, cumle sinirindan.
      if($govde.Length -le 1800){
        $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} m.{1}" -f $kisa, $no)
                                  baslik=("{0} madde {1}" -f $kisa, $no); metin=$govde })
      } else {
        $dilimler = Dilimle $govde 1800
        for($d=0; $d -lt $dilimler.Count; $d++){
          $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} m.{1} [{2}/{3}]" -f $kisa, $no, ($d+1), $dilimler.Count)
                                    baslik=("{0} madde {1}" -f $kisa, $no); metin=$dilimler[$d] })
        }
      }
    }
    return $parcalar
  }

  $rxPar = [regex]'(?m)^\s*(?<no>(?:R)?\d{1,3}(?:\.\d{1,3}){0,2}\s?A?\d{0,3}|A\d{1,3}|\d{1,3}T)\s+(?=[A-ZÇĞİÖŞÜ(])'
  $p = $rxPar.Matches($duz)
  if($p.Count -ge 10){
    # 02.08 CEM DENETIMI: ilk surumde "80 karakterden kisayi atla" ve "6.000'den
    # uzunu KES" vardi. Olcum: KYS 1'in %27,6'si kaybolmus. Metnin tek satiri
    # bile atilmaz - kisa parca ONCEKINE eklenir, uzun parca DILIMLENIR.
    # Bastaki basliksiz on-metin (kapak/icindekiler) de artik ambara girer.
    if($p[0].Index -gt 0){
      $on = $duz.Substring(0, $p[0].Index).Trim()
      if($on.Length -gt 0){ $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} - on bolum" -f $kisa); baslik=("{0} on bolum" -f $kisa); metin=$on }) }
    }
    for($i=0; $i -lt $p.Count; $i++){
      $bas = $p[$i].Index
      $son = if($i -lt $p.Count-1){ $p[$i+1].Index } else { $duz.Length }
      $govde = $duz.Substring($bas, $son-$bas).Trim()
      if($govde.Length -eq 0){ continue }
      $no = ($p[$i].Groups['no'].Value -replace '\s','')
      if($govde.Length -lt 60 -and $parcalar.Count -gt 0){
        # sayfa numarasi / icindekiler kirintisi: ONCEKI parcaya eklenir, ATILMAZ
        $parcalar[$parcalar.Count-1].metin = $parcalar[$parcalar.Count-1].metin + " " + $govde
        continue
      }
      if($govde.Length -le 2500){
        $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} p.{1}" -f $kisa, $no)
                                  baslik=("{0} paragraf {1}" -f $kisa, $no); metin=$govde })
      } else {
        $dilimler = Dilimle $govde 2500
        for($d=0; $d -lt $dilimler.Count; $d++){
          $parcalar.Add([ordered]@{ tur='standart-madde'; kaynak_ad=("{0} p.{1} [{2}/{3}]" -f $kisa, $no, ($d+1), $dilimler.Count)
                                    baslik=("{0} paragraf {1}" -f $kisa, $no); metin=$dilimler[$d] })
        }
      }
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
    # KAPSAMA KAPISI (02.08 Cem: "ustunkoru degil, tek tek oku"): kaynaktaki
    # karakterlerin yuzde kaci ambara girdi? %98'in altinda ise KIRMIZI - metnin
    # bir kismi kaybolmus demektir, sessizce gecilmez.
    $hamOlcu = ($metin -replace '\s+',' ').Length
    $ambarOlcu = ((($parcalar | ForEach-Object { $_.metin }) -join ' ') -replace '\s+',' ').Length
    $kapsama = if($hamOlcu -gt 0){ [math]::Round(100*$ambarOlcu/$hamOlcu,1) } else { 0 }
    [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject ([ordered]@{ belgeler = [object[]]$parcalar }) -Depth 5), $enc)
    # 02.08 IKINCI KAPI: kapsama %100 olsa bile parca DEVASA ise retrieval'da
    # ise yaramaz (BOBI FRS 526 bin karakteri 9 parcaya sigdirmisti). Ortalama
    # parca 4.000 karakteri asarsa KIRMIZI.
    $ortBoy = if($parcalar.Count){ [math]::Round($ambarOlcu/$parcalar.Count) } else { 0 }
    $isaret = if($kapsama -ge 98 -and $ortBoy -le 4000){ 'TAM' } elseif($kapsama -lt 98){ 'EKSIK METIN' } else { 'PARCA COK BUYUK' }
    Write-Host ("{0}: {1} KB -> {2} parca | kapsama %{3} | ort parca {4} kr [{5}]" -f $h.ad, $kb, $parcalar.Count, $kapsama, $ortBoy, $isaret)
    $rapor += [ordered]@{ slug=$h.slug; ad=$h.ad; kb=$kb; parca=$parcalar.Count; kapsama_yuzde=$kapsama; ortalama_parca=$ortBoy; durum=$isaret }
  } catch {
    Write-Host ("{0}: DUSTU - {1}" -f $h.ad, $_.Exception.Message)
    $rapor += [ordered]@{ slug=$h.slug; ad=$h.ad; durum='DUSTU'; hata="$($_.Exception.Message)" }
  }
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/kgk-yut-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); sonuc=[object[]]$rapor }) -Depth 5), $enc)
Write-Host "-> veri/kgk-yut-raporu.json"
