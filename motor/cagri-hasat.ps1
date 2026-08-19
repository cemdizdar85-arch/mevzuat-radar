# ============================================================================
#  CAGRI HASAT - TUBITAK + KOSGEB + AB (Ufuk Avrupa) acik destek cagrilarini
#  ceker. (19.08 Cem onayi: "Cagri Radari'na basla" - 0 maliyet, deterministik.)
#  Cikti: veri/cagri-radar.json - destekler.html "acik cagrilar" bolumu ve
#  tesvik-sihirbazi.html "diger kapilar" kutusu okur.
#  Gerekce: 9903 tesviki KURAL tabanli (sihirbaza gomulu), TUBITAK/KOSGEB/AB
#  ise CAGRI tabanli - acilip kapanir, koda gomulmez, robotla izlenir.
#
#  Kaynak kesfi 19.08 OLCULDU:
#   - TUBITAK: ulusal-destek-programlari sayfasinda Drupal "view-id-cagrilar"
#     blogu; duyuru sayfasinda "Cagri Acilis / Son Tarih / Kapanis" tablosu.
#   - AB: SEDIA arama API'si MULTIPART FORM ister (duz JSON govde SESSIZCE
#     yok sayilir, 4,1M sonuc doner - olculdu!). curl -F ile cagrilir.
#     Metadata'da DATASOURCE/datasource cift anahtari var: ConvertFrom-Json
#     PS 5.1'de PATLAR, pwsh 7'de -AsHashtable ile okunur; biz regex ile
#     cift anahtari temizleyip iki surumde de ayni yoldan okuyoruz.
#   - KOSGEB: program sayfalarinda cagri tarihi YOK (olculdu); duyuru akisi
#     taranir, basliginda "cagri / proje teklif" gecenler alinir. 0 sonuc
#     NORMALDIR (cagri yokken bos olur) - sayfa hic link vermezse OLCULEMEDI.
#
#  Kor kalma kurali: bir kaynak olculemezse o kaynagin ESKI kayitlari korunur
#  ve kaynak durumu "OLCULEMEDI" yazilir; UC kaynak birden olculemezse dosyaya
#  DOKUNULMAZ ve betik 1 ile cikar (workflow alarmi tetiklenir).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\cagri-radar.json"
$bugun = (Get-Date).Date

# --- ortak yardimcilar -------------------------------------------------------
function Normalize([string]$metin){
  # TR harf tuzagi (imatch dersi): once tr-lower, sonra ASCII'ye indir.
  # I/i dersi: 'İ'.ToLowerInvariant() = 'i' + BIRLESIK NOKTA (U+0307) - nokta silinir.
  $t = $metin.ToLowerInvariant()
  $t = $t -replace [string][char]0x0307,''
  $t = $t -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u'
  return $t
}
function TrTarihCoz([string]$ham){
  # "20 Temmuz 2026" ya da "20.07.2026" -> yyyy-MM-dd; cozulemezse bos
  $ham = ($ham -replace '&nbsp;',' ').Trim()
  if($ham -match '^(\d{1,2})[./](\d{1,2})[./](\d{4})$'){
    try { return ([datetime]::ParseExact(("{0:d2}.{1:d2}.{2}" -f [int]$Matches[1],[int]$Matches[2],$Matches[3]),"dd.MM.yyyy",$null)).ToString("yyyy-MM-dd") } catch { return "" }
  }
  if($ham -match '^(\d{1,2})\s+(\S+)\s+(\d{4})$'){
    $aylar = @{oca=1;sub=2;mar=3;nis=4;may=5;haz=6;tem=7;agu=8;eyl=9;eki=10;kas=11;ara=12}
    $ayAd = (Normalize $Matches[2])
    foreach($anahtar in $aylar.Keys){
      if($ayAd.StartsWith($anahtar)){
        try { return (Get-Date -Year ([int]$Matches[3]) -Month $aylar[$anahtar] -Day ([int]$Matches[1])).ToString("yyyy-MM-dd") } catch { return "" }
      }
    }
  }
  return ""
}
function GuvenliCek([string]$adres){
  # IWR .Content ikili-bozma dersi burada gecerli degil (HTML metin) ama
  # UseBasicParsing + UA standart; hata firlatmaz, bos doner (olculemedi).
  try {
    $yanit = Invoke-WebRequest -Uri $adres -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 60 -UseBasicParsing
    return [string]$yanit.Content
  } catch { Write-Host ("  cekilemedi: {0} ({1})" -f $adres, $_.Exception.Message); return "" }
}

$cagrilar = @()
$kaynakDurum = [ordered]@{}

# --- 1) TUBITAK --------------------------------------------------------------
Write-Host "TUBITAK cagri blogu okunuyor..."
$tubitakKok = "https://tubitak.gov.tr"
$tubitakHtml = GuvenliCek "$tubitakKok/tr/destekler/sanayi/ulusal-destek-programlari"
$tubitakAdet = 0; $tubitakOlduMu = $false
$blokBas = $tubitakHtml.IndexOf('view-id-cagrilar')
if($blokBas -ge 0){
  $tubitakOlduMu = $true
  $blok = $tubitakHtml.Substring($blokBas)
  $bagLinkler = [regex]::Matches($blok, '<a href="(/tr/[^"]*/cagri-[^"]*)"[^>]*>([^<]+)</a>') |
    ForEach-Object { [pscustomobject]@{ href=$_.Groups[1].Value; baslik=(($_.Groups[2].Value -replace '\s+',' ').Trim()) } } |
    Sort-Object href -Unique
  foreach($bag in ($bagLinkler | Select-Object -First 12)){
    $kod = ""; if($bag.baslik -match '^\s*(\d{4})'){ $kod = $Matches[1] }
    $acilis = ""; $sonTarih = ""; $tarihler = @()
    $duyuruHtml = GuvenliCek ($tubitakKok + $bag.href)
    if($duyuruHtml){
      foreach($tablo in [regex]::Matches($duyuruHtml, '(?s)<table.*?</table>')){
        if($tablo.Value -notmatch 'Tarih'){ continue }
        # satir satir oku (iki tablo bicimi olculdu: 1501 = [etiket|tarih] satirlari,
        # 1707 = matris: baslik [_, Acilis Tarihi, Kapanis Tarihi] + donem satirlari)
        $satirlar = @()
        foreach($tr in [regex]::Matches($tablo.Value, '(?s)<tr[^>]*>(.*?)</tr>')){
          $satirlar += ,@([regex]::Matches($tr.Groups[1].Value, '(?s)<t[dh][^>]*>(.*?)</t[dh]>') |
            ForEach-Object { ((($_.Groups[1].Value -replace '<[^>]*>',' ') -replace '&nbsp;',' ') -replace '\s+',' ').Trim() })
        }
        # (a) matris modu: bir baslik satirinda hem "acilis" hem "kapanis" etiketi varsa
        $baslikSatir = $null
        foreach($satir in $satirlar){
          $normlar = @($satir | ForEach-Object { Normalize $_ })
          if(($normlar -match 'acilis').Count -and ($normlar -match 'kapanis').Count){ $baslikSatir = $satir; break }
        }
        if($baslikSatir){
          $normBaslik = @($baslikSatir | ForEach-Object { Normalize $_ })
          $iAcilis = -1; $iKapanis = -1
          for($i=0; $i -lt $normBaslik.Count; $i++){
            if($iAcilis -lt 0 -and $normBaslik[$i] -match 'acilis'){ $iAcilis = $i }
            if($iKapanis -lt 0 -and $normBaslik[$i] -match 'kapanis'){ $iKapanis = $i }
          }
          if($iAcilis -lt 0){ $iAcilis = 0 }
          foreach($satir in $satirlar){
            if($satir.Count -le [Math]::Max($iAcilis,$iKapanis)){ continue }
            $satirAcilis = TrTarihCoz $satir[$iAcilis]; $satirKapanis = TrTarihCoz $satir[$iKapanis]
            if(-not $satirKapanis){ continue }
            $donemAd = if($satir[0]){ $satir[0] } else { "Dönem" }
            $tarihler += [ordered]@{ etiket=($donemAd + " kapanış"); tarih=$satirKapanis }
            # ilk GELECEK kapanisli donem cagriyi temsil eder
            if(-not $sonTarih){
              try { if([datetime]::ParseExact($satirKapanis,"yyyy-MM-dd",$null) -ge $bugun){ $sonTarih = $satirKapanis; $acilis = $satirAcilis } } catch {}
            }
          }
        } else {
          # (b) cift-sutun modu: etiket hucresi ("...Tarihi") + tarih hucresi
          foreach($satir in $satirlar){
            for($i=0; $i -lt $satir.Count-1; $i++){
              if($satir[$i] -match 'Tarih'){
                $coz = TrTarihCoz $satir[$i+1]
                if($coz){
                  $tarihler += [ordered]@{ etiket=$satir[$i]; tarih=$coz }
                  $normEtiket = Normalize $satir[$i]
                  if($normEtiket -match 'acilis'){ $acilis = $coz }
                  if($normEtiket -match 'kapanis' -or $normEtiket -match 'son basvuru'){ $sonTarih = $coz }
                }
              }
            }
          }
        }
        if($tarihler.Count){ break }
      }
    }
    # kapanis etiketi yoksa etiketli son-tarih adaylarindan en gec olani (temkin: yalniz etiketlilerden)
    if(-not $sonTarih -and $tarihler.Count){ $sonTarih = ($tarihler | ForEach-Object { $_.tarih } | Sort-Object | Select-Object -Last 1) }
    $cagrilar += [ordered]@{
      kaynak="TÜBİTAK"; kod=$kod; baslik=$bag.baslik; durum="acik"
      acilis=$acilis; sonTarih=$sonTarih
      tarihler=$tarihler
      url=($tubitakKok + $bag.href)
    }
    $tubitakAdet++
    Start-Sleep -Milliseconds 300
  }
}
$kaynakDurum["TÜBİTAK"] = if($tubitakOlduMu){ "OK ($tubitakAdet çağrı)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("TUBITAK: {0}" -f $kaynakDurum["TÜBİTAK"])

# --- 2) KOSGEB ---------------------------------------------------------------
Write-Host "KOSGEB duyuru akisi okunuyor..."
$kosgebHtml = GuvenliCek "https://www.kosgeb.gov.tr/site/tr/genel/duyurular"
$kosgebAdet = 0; $kosgebOlduMu = $false
if($kosgebHtml){
  $duyurular = [regex]::Matches($kosgebHtml, '(?s)<a[^>]*href="(/site/tr/genel/detay/[^"]*)"[^>]*>(.{5,250}?)</a>') |
    ForEach-Object { [pscustomobject]@{ href=$_.Groups[1].Value; baslik=(((($_.Groups[2].Value -replace '<[^>]*>','') -replace '&nbsp;',' ') -replace '\s+',' ').Trim()) } } |
    Sort-Object href -Unique
  if(@($duyurular).Count -ge 3){
    $kosgebOlduMu = $true   # akis okunabildi; cagri olmamasi normal
    foreach($duyuru in $duyurular){
      $normBaslik = Normalize $duyuru.baslik
      if($normBaslik -match 'cagri' -or $normBaslik -match 'proje teklif'){
        $cagrilar += [ordered]@{
          kaynak="KOSGEB"; kod=""; baslik=$duyuru.baslik; durum="acik"
          acilis=""; sonTarih=""; tarihler=@()
          url=("https://www.kosgeb.gov.tr" + $duyuru.href)
        }
        $kosgebAdet++
      }
    }
  }
}
$kaynakDurum["KOSGEB"] = if($kosgebOlduMu){ "OK ($kosgebAdet çağrı — 0 olması normal, çağrı yokken boş)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("KOSGEB: {0}" -f $kaynakDurum["KOSGEB"])

# --- 3) AB / Ufuk Avrupa (SEDIA) --------------------------------------------
Write-Host "AB SEDIA API okunuyor..."
$abAdet = 0; $abOlduMu = $false
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }
$sediaDosya = Join-Path ([IO.Path]::GetTempPath()) "sedia-cagri.json"
# PS'in native-arg tirnak ezmesine karsi form alanlari DOSYADAN verilir (-F 'ad=<dosya')
# (duz -F "query={...}" PS 5.1'de ic tirnaklari yutuyor, API "internal error" donuyordu - olculdu)
$sorguDosya = Join-Path ([IO.Path]::GetTempPath()) "sedia-sorgu.json"
$dilDosya   = Join-Path ([IO.Path]::GetTempPath()) "sedia-dil.json"
$siraDosya  = Join-Path ([IO.Path]::GetTempPath()) "sedia-sira.json"
[IO.File]::WriteAllText($sorguDosya, '{"bool":{"must":[{"terms":{"type":["1","2"]}},{"terms":{"status":["31094502"]}},{"terms":{"frameworkProgramme":["43108390"]}}]}}')
[IO.File]::WriteAllText($dilDosya,   '["en"]')
[IO.File]::WriteAllText($siraDosya,  '{"field":"deadlineDate","order":"ASC"}')
try {
  # sunucu pageSize'i 100'e KIRPAR (olculdu: 500 istendi 100 geldi) -> sayfalama sart.
  # ASC siralamada ilk sayfalar gecmis cut-off'lu eski konular; TUM sayfalar gezilir.
  $abListe = @(); $sayfa = 1; $toplamAB = -1
  while($sayfa -le 10){
    & $curlKomut -sS -m 90 -X POST "https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA&text=***&pageSize=100&pageNumber=$sayfa" `
      -F "query=<$sorguDosya;type=application/json" `
      -F "languages=<$dilDosya;type=application/json" `
      -F "sort=<$siraDosya;type=application/json" `
      -o $sediaDosya
    if(-not (Test-Path $sediaDosya)){ break }
    $sediaHam = Get-Content $sediaDosya -Raw -Encoding UTF8
    # cift anahtar temizligi (DATASOURCE/datasource) - iki dizilis de olabilir
    $sediaHam = $sediaHam -replace ',"datasource":\[[^\]]*\]','' -replace '"datasource":\[[^\]]*\],',''
    $sedia = $sediaHam | ConvertFrom-Json
    if($sedia.totalResults -lt 1){ break }
    $toplamAB = $sedia.totalResults
    $abOlduMu = $true
    foreach($sonuc in @($sedia.results)){
      $meta = $sonuc.metadata
      $kimlik = "$($meta.identifier)"; $baslikAB = "$($meta.title)"
      if(-not $kimlik -or -not $baslikAB){ continue }
      # gelecek tarihli en yakin son tarih (cut-off) alinir; yoksa cagri atlanir.
      # DIKKAT (19.08 CI vakasi): pwsh 7 ConvertFrom-Json ISO tarih dizesini
      # KENDILIGINDEN [datetime] yapar; "$ham".Substring o zaman kultur-bicimli
      # dize verir ve ParseExact sessizce patlar (CI'da 345 konunun hepsi elendi).
      # Iki tur da ayri ele alinir.
      $gelecek = @()
      foreach($ham in @($meta.deadlineDate)){
        $t = $null
        if($ham -is [datetime]){ $t = $ham.Date }
        else { try { $t = [datetime]::ParseExact("$ham".Substring(0,10),"yyyy-MM-dd",$null) } catch {} }
        if($t -and $t -ge $bugun){ $gelecek += $t }
      }
      if(-not $gelecek.Count){ continue }
      $abListe += [ordered]@{
        kaynak="AB (Ufuk Avrupa)"; kod="$($meta.callIdentifier)"; baslik=$baslikAB; durum="acik"
        acilis=""; sonTarih=(($gelecek | Sort-Object | Select-Object -First 1).ToString("yyyy-MM-dd"))
        tarihler=@()
        url=("https://ec.europa.eu/info/funding-tenders/opportunities/portal/screen/opportunities/topic-details/" + $kimlik)
      }
    }
    if((@($sedia.results).Count) -lt 100){ break }   # son sayfa
    $sayfa++
    Start-Sleep -Milliseconds 400
  }
  # imkansiz-veri sigortasi (yapisal denetci felsefesi): portal "345 acik konu"
  # diyorsa gelecekli 0 olamaz - olcum bozuktur, OLCULEMEDI say ki eski veri korunsun.
  if($abOlduMu -and $toplamAB -ge 20 -and (@($abListe).Count) -eq 0){
    Write-Host ("  CELISKI: portal {0} acik konu diyor ama gelecekli 0 cikti - olcum bozuk sayildi" -f $toplamAB)
    $abOlduMu = $false
  }
  if($abOlduMu){
    # mukerrer kimlik ayikla (ayni konu iki sayfada gelebilir)
    $gorulen = @{}; $tekil = @()
    foreach($kayit in $abListe){ if(-not $gorulen.ContainsKey($kayit.url)){ $gorulen[$kayit.url]=1; $tekil += $kayit } }
    # siteye en yakin 60 son tarih gider (sessiz kirpma degil: sayi damgada yazar)
    $abGelecekli = @($tekil).Count
    $cagrilar += @($tekil | Sort-Object { $_.sonTarih } | Select-Object -First 60)
    $abAdet = [Math]::Min(60, $abGelecekli)
    $kaynakDurum["AB (Ufuk Avrupa)"] = "OK (portalda açık $toplamAB konu; gelecek son-tarihli $abGelecekli, en yakın $abAdet tanesi listede)"
  }
} catch { Write-Host ("  SEDIA hatasi: {0}" -f $_.Exception.Message) }
if(-not $abOlduMu){ $kaynakDurum["AB (Ufuk Avrupa)"] = "ÖLÇÜLEMEDİ" }
Write-Host ("AB: {0}" -f $kaynakDurum["AB (Ufuk Avrupa)"])

# --- kor kalma + eski veriyi koruma -----------------------------------------
$olculenler = @()
if($tubitakOlduMu){ $olculenler += "TÜBİTAK" }
if($kosgebOlduMu){ $olculenler += "KOSGEB" }
if($abOlduMu){ $olculenler += "AB (Ufuk Avrupa)" }
if(-not $olculenler.Count){
  Write-Host "HATA: uc kaynak da olculemedi - dosyaya DOKUNULMADI (eski veri korunur)"
  exit 1
}
if((Test-Path $ciktiYolu) -and ($olculenler.Count -lt 3)){
  try {
    $eski = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($eskiKayit in @($eski.cagrilar)){
      if($olculenler -notcontains "$($eskiKayit.kaynak)"){
        $cagrilar += [ordered]@{
          kaynak=$eskiKayit.kaynak; kod="$($eskiKayit.kod)"; baslik=$eskiKayit.baslik; durum=$eskiKayit.durum
          acilis="$($eskiKayit.acilis)"; sonTarih="$($eskiKayit.sonTarih)"
          tarihler=@($eskiKayit.tarihler | ForEach-Object { [ordered]@{ etiket=$_.etiket; tarih=$_.tarih } })
          url=$eskiKayit.url
        }
      }
    }
  } catch { Write-Host "NOT: eski json okunamadi, yalniz taze kaynaklar yazilir" }
}

$cikti = [ordered]@{
  guncelleme = "Kaynaklar dogrudan kurum sitelerinden robotla cekildi. Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynaklar = @(
    [ordered]@{ ad="TÜBİTAK"; url="https://tubitak.gov.tr/tr/destekler/sanayi/ulusal-destek-programlari"; durum=$kaynakDurum["TÜBİTAK"] }
    [ordered]@{ ad="KOSGEB"; url="https://www.kosgeb.gov.tr/site/tr/genel/duyurular"; durum=$kaynakDurum["KOSGEB"] }
    [ordered]@{ ad="AB (Ufuk Avrupa)"; url="https://ec.europa.eu/info/funding-tenders/opportunities/portal/screen/opportunities/calls-for-proposals"; durum=$kaynakDurum["AB (Ufuk Avrupa)"] }
  )
  cagrilar = $cagrilar
}
($cikti | ConvertTo-Json -Depth 6) | Out-File $ciktiYolu -Encoding utf8

# yazma sonrasi sayim (yesil kosu != tam veri dersi)
$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("CAGRI HASAT: {0} cagri yazildi ({1}) -> veri/cagri-radar.json [geri okuma: {2}]" -f @($cagrilar).Count, ($olculenler -join "+"), @($geriOkuma.cagrilar).Count)
if(@($geriOkuma.cagrilar).Count -ne @($cagrilar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
