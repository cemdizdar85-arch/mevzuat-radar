# ============================================================================
#  KGK ÇIKMIŞ SINAV TAMLIK ÖLÇÜMÜ — kitapçık + cevap anahtarı + modül sayısı   16.09.2026
#  Cem "1.2.3 ÜÇÜNÜDE YAP" (GM 1 ve 2): "KGK eski çıkmış sınav soruları elimizde FUL var mı" sorusunun ölçülmemiş iki
#  parçası: (1) her sınavın cevap anahtarı elimizde mi, (2) 160/120 soruluk sınavlar eksik oturum mu, az modül mü.
#
#  NE YAPAR (bedel 0, model yok, yazma yok — yalnız rapor):
#   1. Sınav kodları: KGK Soru Arşivi sayfası + veri/kgk-arsiv/pdf-links.tsv + diskteki dosyalar.
#   2. Her sınavın KGK sayfası (DynamicContentDetail/<kod> ya da ContentAssignmentDetail/<kod>, "ca" önekli kod) okunur,
#      PDF bağlantıları kgk-arsiv-indir.ps1 ile AYNI ad kuralıyla (kod_ + çözülmüş yaprak, [^\w.-]→_) diskle eşlenir.
#      Sayfada olup diskte olmayan PDF = EKSİK. Sayfa okunamazsa "ÖLÇÜLEMEDİ" (eski kodlar sayfada olmayabilir).
#   3. Her kitapçık metninde (veri/kgk-arsiv/txt) SONDAKİ "CEVAP ANAHTARI" bölümü aranır; bölümdeki "N. X" / "N X"
#      cevap hücreleri sayılır. Modül tahmini = hücre / 40 (KGK her modülde 40 soru sorar). Adında CEVAPANAHTARI geçen
#      ayrı dosyalar anahtar dosyası sayılır.
#  Çıktı: veri/kgk-cikmis-tamlik.json (RaporYaz). Kitapçık metinleri telifli olduğu için rapora METİN girmez, yalnız sayı.
#  Kullanım: powershell -NoProfile -File arac/kgk-cikmis-tamlik.ps1   (TR-IP gerekmez; kgk.gov.tr buluttan da açılır)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'arac') 'rapor-yaz.ps1')
$arsivKlasoru = Join-Path (Join-Path $depoKok 'veri') 'kgk-arsiv'
$txtKlasoru = Join-Path $arsivKlasoru 'txt'
if(-not (Test-Path $txtKlasoru)){ Write-Host 'KÖR: veri/kgk-arsiv/txt yok (yalnız yerelde).'; exit 2 }
$tarayici = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
$script:PDFTOTEXT = @('C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe', (Get-Command pdftotext -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
$script:PDFINFO = if($script:PDFTOTEXT){ Join-Path (Split-Path $script:PDFTOTEXT) ('pdfinfo' + [IO.Path]::GetExtension($script:PDFTOTEXT)) } else { '' }

function SayfaOku([string]$adres){
  foreach($deneme in 1..2){
    try { return "$((Invoke-WebRequest -UseBasicParsing -Uri $adres -UserAgent $tarayici -TimeoutSec 60).Content)" } catch { Start-Sleep -Seconds 3 }
  }
  return $null
}
function DiskAdi([string]$kod, [string]$pdfAdresi){
  $yaprak = [uri]::UnescapeDataString(($pdfAdresi -split '/')[-1]) -replace '[^\w\.\-]','_'
  return ($kod + '_' + ($yaprak -replace '(?i)\.pdf$',''))
}

# --- 1) sınav kodları ve adları
$sinavlar = [ordered]@{}
$arsivSayfasi = SayfaOku 'https://kgk.gov.tr/DynamicContentDetail/5237/Soru-Ars%CC%A7ivi'
if($arsivSayfasi){
  foreach($es in [regex]::Matches($arsivSayfasi,"data-href='/(DynamicContent|ContentAssignment)Detail/(\w+)/[^']*'.*?link-title'>([^<]+)<", [Text.RegularExpressions.RegexOptions]::Singleline)){
    $ad = [Net.WebUtility]::HtmlDecode($es.Groups[3].Value).Trim()
    if($ad -notmatch '(?i)s[ıi]nav'){ continue }
    $kod = if($es.Groups[1].Value -eq 'ContentAssignment'){ 'ca' + $es.Groups[2].Value } else { $es.Groups[2].Value }
    if(-not $sinavlar.Contains($kod)){ $sinavlar[$kod] = [ordered]@{ kod=$kod; ad=$ad; arsiv_sayfasinda=$true; adres=('https://kgk.gov.tr/' + $es.Groups[1].Value + 'Detail/' + [regex]::Match($es.Value,"data-href='/[^']+'").Value.Split('/',3)[2].TrimEnd("'")) } }
  }
}
$diskDosyalari = @(Get-ChildItem $txtKlasoru -Filter *.txt -File | Where-Object { $_.Length -gt 800 })
foreach($dosya in $diskDosyalari){ $kod = ($dosya.BaseName -split '_')[0]; if(-not $sinavlar.Contains($kod)){ $sinavlar[$kod] = [ordered]@{ kod=$kod; ad=''; arsiv_sayfasinda=$false } } }
$tsvYolu = Join-Path $arsivKlasoru 'pdf-links.tsv'
$tsvKodlari = @{}
if(Test-Path $tsvYolu){ foreach($satir in (Get-Content $tsvYolu -Encoding UTF8)){ $kod = ($satir -split "`t")[0].Trim([char]0xFEFF).Trim(); if($kod){ $tsvKodlari[$kod] = $true; if(-not $sinavlar.Contains($kod)){ $sinavlar[$kod] = [ordered]@{ kod=$kod; ad=''; arsiv_sayfasinda=$false } } } } }

# --- 2+3) sınav sınav
$satirlar = New-Object System.Collections.Generic.List[object]
foreach($kod in @($sinavlar.Keys)){
  $s = $sinavlar[$kod]
  # 16.09: KGK sayfası adreste BAŞLIK KISMI (slug) yoksa hata sayfası döner → yalnız arşiv sayfasından gelen tam adres okunur
  $sayfa = $null
  if($s.Contains('adres') -and $s.adres){ $sayfa = SayfaOku $s.adres; if($sayfa -and $sayfa -match 'class="error"'){ $sayfa = $null } }
  $sayfaPdf = @()
  # sayfada Sınav klasörüne giden PDF bağlantıları
  if($sayfa){ $sayfaPdf = @([regex]::Matches($sayfa,'(?i)(?:href|data-href)=[''"]([^''"]+\.pdf)[''"]') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '(?i)S%C4%B1nav|Sınav|Sinav' } | Select-Object -Unique) }
  $kodDosyalari = @($diskDosyalari | Where-Object { ($_.BaseName -split '_')[0] -eq $kod })
  $diskKokleri = @($kodDosyalari | ForEach-Object { $_.BaseName })
  $eksikPdf = @($sayfaPdf | Where-Object { $diskKokleri -notcontains (DiskAdi $kod $_) } | ForEach-Object { [uri]::UnescapeDataString(($_ -split '/')[-1]) })
  $kitapciklar = New-Object System.Collections.Generic.List[object]
  foreach($dosya in $kodDosyalari){
    $metin = [IO.File]::ReadAllText($dosya.FullName,[Text.Encoding]::UTF8)
    $ayriAnahtar = $dosya.BaseName -match '(?i)CEVAP\s*_?ANAHTAR'
    # 16.09: başlık biçimi sınava göre değişir ("CEVAP ANAHTARI", "... CEVAP ANAHTARIDIR", yalnız "ANAHTAR"); son geçiş alınır
    $buyuk = $metin.ToUpperInvariant()
    $bolumBasi = if($ayriAnahtar){ 0 } else { [Math]::Max($buyuk.LastIndexOf('CEVAP ANAHTAR'), $buyuk.LastIndexOf('ANAHTARI')) }
    $hucre = 0
    if($bolumBasi -ge 0){
      $bolum = $metin.Substring($bolumBasi)
      # harf büyük/küçük olabilir (2014: "35.   d")
      $hucre = @([regex]::Matches($bolum,'(?<![\d\w])(\d{1,3})\s*[\.\-]?\s*([A-Ea-e])(?![\wçğıöşüÇĞİÖŞÜ])')).Count
    }
    # 16.09: numarasız dikey liste (2020 Kasım B: metnin sonunda alt alta tek harf) — sondaki %15'te yalnız A–E olan satırlar
    $dikeyListe = $false
    if($hucre -lt 20 -and -not $ayriAnahtar){
      $kuyruk = $metin.Substring([int]($metin.Length * 0.85))
      $tekHarf = @(($kuyruk -split "`r?`n") | Where-Object { $_.Trim() -match '^[A-Ea-e]$' }).Count
      if($tekHarf -ge 20){ $hucre = $tekHarf; $dikeyListe = $true }
    }
    # 16.09: 2020 Kasım — modül başlıkları GÖRÜNTÜ, cevaplar son sayfada alt alta; düz çıkarım yalnız bir sütunu aldı.
    #   Hâlâ <20 ise yerel PDF'in son 2 sayfası -layout ile okunur, tek harf satırları sayılır ("PDF SON SAYFA").
    $pdfSonSayfa = $false
    if($hucre -lt 20 -and -not $ayriAnahtar -and $script:PDFTOTEXT){
      $pdfYolu = Join-Path (Join-Path $arsivKlasoru 'pdf') ($dosya.BaseName + '.pdf')
      if(Test-Path -LiteralPath $pdfYolu){
        $bilgi = & $script:PDFINFO $pdfYolu 2>$null
        $sayfaSayisi = [int](("$(@($bilgi) | Where-Object { $_ -match '^Pages:' })") -replace '\D','')
        if($sayfaSayisi -gt 0){
          $gecici = [IO.Path]::GetTempFileName()
          & $script:PDFTOTEXT -enc UTF-8 -layout -f ([Math]::Max(1,$sayfaSayisi-1)) -l $sayfaSayisi $pdfYolu $gecici 2>$null
          $sonMetin = [IO.File]::ReadAllText($gecici,[Text.Encoding]::UTF8)
          [IO.File]::Delete($gecici)
          $harf = @([regex]::Matches($sonMetin,'(?m)^\s*([A-E])\s*$')).Count + @([regex]::Matches($sonMetin,'(?<![\d\w])(\d{1,3})\s*[\.\-]?\s*([A-Ea-e])(?![\wçğıöşüÇĞİÖŞÜ])')).Count
          if($harf -ge 20){ $hucre = $harf; $pdfSonSayfa = $true }
        }
      }
    }
    $kitapciklar.Add([ordered]@{ dosya=$dosya.BaseName; ayri_anahtar_dosyasi=[bool]$ayriAnahtar; cevap_bolumu=($bolumBasi -ge 0); dikey_liste=$dikeyListe; pdf_son_sayfa=$pdfSonSayfa; cevap_hucresi=$hucre; modul_tahmini=[math]::Round($hucre/40,1) })
  }
  $soruKitapciklari = @($kitapciklar | Where-Object { -not $_.ayri_anahtar_dosyasi })
  $anahtarsiz = @($soruKitapciklari | Where-Object { $_.cevap_hucresi -lt 20 })
  $ayriAnahtarVar = @($kitapciklar | Where-Object { $_.ayri_anahtar_dosyasi }).Count -gt 0
  # KISMİ: bazı kitapçıklarda cevap okunuyor, bazılarında okunmuyor (2020 Kasım: başlık+cevapların çoğu son sayfada GÖRÜNTÜ)
  $cevapDurumu = if($soruKitapciklari.Count -eq 0){ 'KİTAPÇIK YOK' } elseif(-not $anahtarsiz.Count){ 'KİTAPÇIK İÇİNDE' } elseif($ayriAnahtarVar){ 'AYRI DOSYADA' } elseif($anahtarsiz.Count -lt $soruKitapciklari.Count){ 'KISMİ (görüntü)' } else { 'YOK (taranmış/okunamadı)' }
  $toplamHucre = [int](($soruKitapciklari | ForEach-Object { $_.cevap_hucresi }) | Measure-Object -Sum).Sum
  $satirlar.Add([ordered]@{
    kod=$kod; ad=$s.ad; arsiv_sayfasinda=$s.arsiv_sayfasinda; tsv_listesinde=[bool]$tsvKodlari.ContainsKey($kod)
    sayfa=$(if($sayfa){'OKUNDU'}elseif($s.arsiv_sayfasinda){'OKUNAMADI'}else{'ARŞİV SAYFASINDA YOK'}); sayfadaki_pdf=$sayfaPdf.Count; diskte=$kodDosyalari.Count; eksik_pdf=$eksikPdf
    cevap=$cevapDurumu; kitapcik=$soruKitapciklari.Count; cevap_hucresi_toplam=$toplamHucre
    kitapciklar=$kitapciklar.ToArray()
  })
  Write-Host ("{0,-7} sayfa {1,-10} pdf {2,2} · disk {3,2} · eksik {4} · cevap {5,-16} · kitapçık {6} · hücre {7,4} · modül/kitapçık {8} · {9}" -f $kod,$(if($sayfa){'OKUNDU'}else{'ÖLÇÜLEMEDİ'}),$sayfaPdf.Count,$kodDosyalari.Count,$eksikPdf.Count,$cevapDurumu,$soruKitapciklari.Count,$toplamHucre,((@($soruKitapciklari | ForEach-Object { $_.modul_tahmini }) | Select-Object -Unique) -join '/'),$s.ad.Substring(0,[Math]::Min(45,$s.ad.Length)))
  Start-Sleep -Milliseconds 300
}
$eksikToplam = (@($satirlar | ForEach-Object { @($_.eksik_pdf).Count }) | Measure-Object -Sum).Sum
$rapor = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'EKSİK PDF = sınavın KGK sayfasında olup veri/kgk-arsiv/txt''de karşılığı olmayan dosya (kgk-arsiv-indir ad kuralı). Cevap: kitapçığın sonundaki CEVAP ANAHTARI bölümünde ≥20 "N. X" hücresi varsa KİTAPÇIK İÇİNDE. Modül tahmini = hücre/40.'
  sinav = $satirlar.Count
  arsiv_sayfasinda = @($satirlar | Where-Object { $_.arsiv_sayfasinda }).Count
  sayfasi_okunan = @($satirlar | Where-Object { $_.sayfa -eq 'OKUNDU' }).Count
  eksik_pdf = $eksikToplam
  cevap_dagilimi = [ordered]@{}
  sinavlar = $satirlar.ToArray()
}
foreach($g in ($satirlar | Group-Object { $_.cevap })){ $rapor.cevap_dagilimi[$g.Name] = $g.Count }
[void](RaporYaz -Hedef (Join-Path (Join-Path $depoKok 'veri') 'kgk-cikmis-tamlik.json') -Nesne $rapor -Sessiz)
Write-Host ("ÖZET: sınav {0} · sayfası okunan {1} · eksik PDF {2} · cevap: {3}" -f $satirlar.Count,$rapor.sayfasi_okunan,$eksikToplam,(($rapor.cevap_dagilimi.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))
exit 0
