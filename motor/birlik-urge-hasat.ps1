# ============================================================================
#  BIRLIK UR-GE/HEYET HASADI - ihracatci birliklerinin UR-GE proje cagrilari ve
#  ticaret/alim heyeti duyurulari. (19.08 Cem: once "EIB pilotu", ardindan
#  "13 birligi genisle".) Cikti: veri/birlik-urge.json - destekler.html grubu.
#  19.08 GENISLEME OLCUMU (Cem: "13 birligi genisle"): 13 birligin TAMAMI
#  tarandi (ana sayfa + JS uclari + statik heyet/duyuru sayfalari). SONUC:
#  EIB = JSON ucu (Arama_JSON.Asp), UIB = statik /tr/heyetler listesi.
#  Kalan 11 birlik (AKIB, BAIB, DENIB, DAIB, DKIB, GAIB, IIB, IMMIB, ITKIB,
#  KIB, OAIB) duyurularini JS ile ciziyor, HTML statik liste vermiyor ->
#  makinece okunamiyor. Yilda bir yeniden olculmeli (site yenilenebilir).
#
#  NEDEN PILOT: ihracatci birlikleri YENI bir destek kaynagi degil - 5973'un
#  basvuru mercii (fuar/marka/e-ihracat katalogda zaten var). Birliklerde bizde
#  OLMAYAN tek sey UR-GE proje katilimci cagrilari + ticaret/alim heyeti
#  takvimi. 13 birlik ayri site oldugu icin once TEK birlikle (EIB, Izmir -
#  Cem'in bolgesi) denenir; tutarsa digerleri ayni desenle eklenir.
#
#  Kaynak kesfi 19.08 OLCULDU: eib.org.tr klasik ASP, duyuru listesi HTML'de
#  YOK - sayfanin kendi /assets/api.js dosyasinda uclar yaziyor (eximbank ve
#  ka.gov.tr'de ise yarayan ayni ders):
#    ANNOUNCE_ENDPOINT = /Duyurular_JSON.Asp   (10.022 duyuru, sayfali)
#    SEARCH_ENDPOINT   = /Arama_JSON.Asp?q=... (duyurular + bultenler ayri)
#  Arama ucu kullanilir: "UR-GE" -> 36 duyuru, "ticaret heyeti" -> ayri kume.
#
#  Rakam disiplini: duyuru basligi ve tarihi oldugu gibi tasinir; destek orani
#  ya da butce YAZILMAZ (duyuruda yok, 5973 Karar'da).
#  Kor kalma: ucun hicbir sorgusu okunamazsa dosyaya DOKUNULMAZ, exit 1.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Web
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\birlik-urge.json"
$bugun = (Get-Date).Date
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }

# duyuru tazelik siniri: 120 gun (UR-GE katilim cagrilari ve heyet takvimi
# genelde 1-3 ay onceden duyurulur; daha eskisi bilgi degeri tasimaz)
$tazelikSiniri = $bugun.AddDays(-120)

# aranan konular: UR-GE proje cagrilari + ticaret/alim heyetleri
$sorgular = @(
  @{ q = "UR-GE";          etiket = "UR-GE projesi" },
  @{ q = "ticaret heyeti"; etiket = "Ticaret heyeti" },
  @{ q = "alım heyeti";    etiket = "Alım heyeti" },
  @{ q = "heyet";          etiket = "Heyet / iş konseyi" }
)

# --- yardimcilar (cagri-hasat.ps1 ile ayni davranis) --------------------------
function Normalize([string]$metin){
  $t = $metin.ToLowerInvariant()
  $t = $t -replace [string][char]0x0307,''
  $t = $t -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u'
  return $t
}
function EntityCoz([string]$metin){
  # UIB basliklarinda sayisal HTML entity var (&#214; = O umlaut). PS 5.1'de
  # -replace scriptblock DESTEKLEMEZ (denendi, duz metin yaziyor) -> MatchEvaluator.
  if(-not $metin){ return "" }
  $cozucu = [System.Text.RegularExpressions.MatchEvaluator]{ param($e) [string][char][int]$e.Groups[1].Value }
  $t = [regex]::Replace($metin, '&#(\d+);', $cozucu)
  return ($t -replace '&amp;','&' -replace '&quot;','"' -replace '&#39;',"'")
}
function TrTarihCoz([string]$ham){
  # "19 Aralik 2026" / "19.12.2026" -> yyyy-MM-dd; cozulemezse bos
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
$kayitlar = @()
$gorulen = @{}
$okunanSorgu = 0

foreach($sorgu in $sorgular){
  $gecici = Join-Path ([IO.Path]::GetTempPath()) ("eib-ara-" + ($sorgu.q -replace '[^a-zA-Z]','') + ".json")
  Remove-Item $gecici -ErrorAction SilentlyContinue
  $adres = "https://www.eib.org.tr/Arama_JSON.Asp?q=" + [uri]::EscapeDataString($sorgu.q)
  # Cloudflare ara sira 525 veriyor (olculdu 19.08) - iki deneme
  $veri = $null
  foreach($deneme in 1,2){
    Remove-Item $gecici -ErrorAction SilentlyContinue
    & $curlKomut -sSL -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -H "Accept: application/json" -o $gecici $adres
    if(-not (Test-Path $gecici)){ Start-Sleep -Seconds 2; continue }
    try { $veri = Get-Content $gecici -Raw -Encoding UTF8 | ConvertFrom-Json; break }
    catch { Write-Host ("  deneme {0}: JSON okunamadi ({1})" -f $deneme, $sorgu.q); Start-Sleep -Seconds 2 }
  }
  if(-not $veri){ Write-Host ("  atlandi: {0}" -f $sorgu.q); continue }
  if(-not $veri.duyurular){ Write-Host ("  duyuru bolumu yok: {0}" -f $sorgu.q); continue }
  $okunanSorgu++
  foreach($madde in @($veri.duyurular.items)){
    $baslik = "$($madde.baslik)".Trim()
    if(-not $baslik){ continue }
    # tarih: dd.MM.yyyy -> yyyy-MM-dd; cozulemeyen kayit ALINMAZ (tazelik olculemez)
    $tarihIso = ""
    if("$($madde.tarih)" -match '^(\d{2})\.(\d{2})\.(\d{4})$'){
      try { $tarihIso = ([datetime]::ParseExact($madde.tarih,"dd.MM.yyyy",$null)).ToString("yyyy-MM-dd") } catch {}
    }
    if(-not $tarihIso){ continue }
    try { if([datetime]::ParseExact($tarihIso,"yyyy-MM-dd",$null) -lt $tazelikSiniri){ continue } } catch { continue }
    $bag = "$($madde.link)"
    if($bag -and $bag -notmatch '^https?://'){ $bag = "https://www.eib.org.tr" + ($bag -replace '^/','/') }
    if(-not $bag){ $bag = "https://www.eib.org.tr/Duyurular.Asp" }
    if($gorulen.ContainsKey($bag)){ continue }
    $gorulen[$bag] = 1
    $kayitlar += [ordered]@{
      baslik = $baslik
      konu = $sorgu.etiket
      birlik = "EİB (Ege)"
      tarih = $tarihIso
      ozet = (("$($madde.snippet)" -replace '\s+',' ').Trim())
      url = $bag
    }
  }
  Start-Sleep -Milliseconds 300
}


# --- UIB (Uludag Ihracatci Birlikleri) - 2. BIRLIK ---------------------------
# 19.08 Cem: "13 birligi genisle". 13 birligin TAMAMI olculdu (bkz asagidaki
# not): yalniz EIB'de JSON ucu, yalniz UIB'de STATIK heyet listesi var; kalan
# 11 birlik duyurularini JS ile ciziyor ve makinece okunamiyor - o yuzden
# genisleme 2 birlikte kaldi, gerekcesi hafizada.
# UIB yapisi: /tr/heyetler statik liste (baslik + goreli link), tarih DETAY
# sayfasinda metin icinde ("13-19 Aralik 2026 tarihleri arasinda").
Write-Host "UIB heyet listesi okunuyor..."
$uibKok = "https://www.uib.org.tr"
$uibHtml = ""
try {
  $uibHtml = (Invoke-WebRequest -Uri "$uibKok/tr/heyetler" -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 45 -UseBasicParsing).Content
} catch { Write-Host ("  UIB cekilemedi: {0}" -f $_.Exception.Message) }
if($uibHtml){
  $okunanSorgu++   # birlik okunabildi (kor kalma sayaci)
  $uibBaglar = [regex]::Matches($uibHtml, '<a href="([a-z0-9-]+)"[^>]*class="event-name"[^>]*>([^<]{10,120})') |
    ForEach-Object { [pscustomobject]@{ yol=$_.Groups[1].Value; baslik=(($_.Groups[2].Value -replace '\s+',' ').Trim()) } } |
    Sort-Object yol -Unique
  foreach($bag in @($uibBaglar | Select-Object -First 12)){
    $normB = Normalize $bag.baslik
    # katilim kosullari / rehber gibi bilgi sayfalari degil, ETKINLIK olanlar
    if($normB -notmatch 'heyet' -or $normB -match 'kosullari|rehber|kilavuz'){ continue }
    $detay = ""
    try { $detay = (Invoke-WebRequest -Uri ("$uibKok/tr/" + $bag.yol) -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 45 -UseBasicParsing).Content } catch {}
    if(-not $detay){ continue }
    $duzDetay = ((($detay -replace '(?s)<script.*?</script>',' ') -replace '<[^>]*>',' ') -replace '&nbsp;',' ') -replace '\s+',' '
    # "13-19 Aralik 2026 tarihleri arasinda" -> bitis 19 Aralik 2026
    $tarihIso = ""
    $m1 = [regex]::Match($duzDetay, '(\d{1,2})\s*[-/]\s*(\d{1,2})\s+([A-Za-zÀ-ɏ]+)\s+(\d{4})')
    if($m1.Success){ $tarihIso = TrTarihCoz ("{0} {1} {2}" -f $m1.Groups[2].Value, $m1.Groups[3].Value, $m1.Groups[4].Value) }
    if(-not $tarihIso){
      $m2 = [regex]::Match($duzDetay, '(\d{1,2})\s+([A-Za-zÀ-ɏ]+)\s+(\d{4})\s+tarih')
      if($m2.Success){ $tarihIso = TrTarihCoz ("{0} {1} {2}" -f $m2.Groups[1].Value, $m2.Groups[2].Value, $m2.Groups[3].Value) }
    }
    # tarihi cozulemeyen ya da GECMIS etkinlik listeye girmez (kapanmisi gosterme kurali)
    if(-not $tarihIso){ continue }
    try { if([datetime]::ParseExact($tarihIso,"yyyy-MM-dd",$null) -lt $bugun){ continue } } catch { continue }
    $bagAdres = "$uibKok/tr/" + $bag.yol
    if($gorulen.ContainsKey($bagAdres)){ continue }
    $gorulen[$bagAdres] = 1
    $kayitlar += [ordered]@{
      baslik = (EntityCoz $bag.baslik)
      konu = "Ticaret heyeti"
      birlik = "UİB (Uludağ)"
      tarih = $tarihIso
      ozet = ""
      url = $bagAdres
    }
    Start-Sleep -Milliseconds 250
  }
}
# --- KALAN 11 BIRLIK: GUNLUK YOKLAMA ----------------------------------------
# 19.08 Cem: "yilda bir cok, her gun dene 1 kere". 11 birlik bugun JS ile
# ciziyor (olculdu) ama site yenilenirse okunabilir hale gelebilir. Her gun
# BIR kez yoklanir: aday yollar denenir, sayfada HEM heyet/UR-GE basligi HEM
# tarih varsa "okunabilir" sayilir ve kayitlar genel desenle cikarilir.
# Maliyet: birlik basina 1-3 istek, gunde bir. Sonuc her kosuda json'a yazilir
# (birlikDurum) - bir birlik acilirsa ayni gun gorulur, kimse elle bakmaz.
$digerBirlikler = @(
  @{ ad = "AKİB (Akdeniz)";        kok = "https://www.akib.org.tr";   yollar = @("/tr/heyetler","/tr/duyurular","/tr/etkinlikler") },
  @{ ad = "BAİB (Batı Akdeniz)";   kok = "https://www.baib.gov.tr";   yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "DENİB (Denizli)";       kok = "https://www.denib.gov.tr";  yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "DAİB (Doğu Anadolu)";   kok = "https://www.daib.org.tr";   yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "DKİB (Doğu Karadeniz)"; kok = "https://www.dkib.org.tr";   yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "GAİB (Güneydoğu)";      kok = "https://www.gaib.org.tr";   yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "İİB (İstanbul)";        kok = "https://www.iib.org.tr";    yollar = @("/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "İMMİB (Maden-Metal)";   kok = "https://www.immib.org.tr";  yollar = @("/tr/heyetler","/tr/duyurular","/tr/etkinlikler") },
  @{ ad = "İTKİB (Tekstil)";       kok = "https://www.itkib.org.tr";  yollar = @("/tr/heyetler","/tr/duyurular","/duyurular") },
  @{ ad = "KİB (Karadeniz)";       kok = "https://www.kib.org.tr";    yollar = @("/tr/heyetler","/duyurular","/tr/duyurular") },
  @{ ad = "OAİB (Orta Anadolu)";   kok = "https://oaib.org.tr";       yollar = @("/heyetler","/duyurular","/etkinlikler") }
)
$birlikDurum = @()
$yeniAcilan = @()
foreach($birlik in $digerBirlikler){
  $durum = "okunamıyor (JS ile çiziliyor)"
  $bulunanKayit = 0
  foreach($yol in $birlik.yollar){
    $sayfa = ""
    try { $sayfa = (Invoke-WebRequest -Uri ($birlik.kok + $yol) -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 25 -UseBasicParsing).Content } catch { continue }
    if(-not $sayfa -or $sayfa.Length -lt 5000){ continue }
    # OKUNABILIRLIK OLCUTU: heyet/UR-GE basligi TASIYAN link + sayfada tarih deseni
    $adaylar = [regex]::Matches($sayfa, '<a[^>]*href="([^"#]{3,160})"[^>]*>([^<]{12,140})</a>')
    $konulu = @()
    foreach($a in $adaylar){
      $bas = (EntityCoz ((($a.Groups[2].Value -replace '\s+',' ').Trim())))
      $nb = Normalize $bas
      if($nb -match 'heyet|ur-ge|urge' -and $nb -notmatch 'kosullari|rehber|kilavuz|katilim kosul'){
        $konulu += [pscustomobject]@{ baslik=$bas; href=$a.Groups[1].Value }
      }
    }
    if(@($konulu).Count -lt 2){ continue }
    $tarihVar = [regex]::IsMatch($sayfa, '\d{1,2}[./]\d{1,2}[./]\d{4}|\d{1,2}\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+\d{4}')
    if(-not $tarihVar){ continue }
    # okunabilir! genel desenle kayit cikar (tarihi cozulen ve GELECEK olanlar)
    foreach($k in @($konulu | Select-Object -First 10)){
      $adres = $k.href
      if($adres -notmatch '^https?://'){ $adres = $birlik.kok + $(if($adres.StartsWith('/')){ $adres } else { "$yol/$adres" -replace '//','/' }) }
      if($gorulen.ContainsKey($adres)){ continue }
      $detay = ""
      try { $detay = (Invoke-WebRequest -Uri $adres -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 25 -UseBasicParsing).Content } catch { continue }
      $duz = ((($detay -replace '(?s)<script.*?</script>',' ') -replace '<[^>]*>',' ') -replace '&nbsp;',' ') -replace '\s+',' '
      $tIso = ""
      $mm = [regex]::Match($duz, '(\d{1,2})\s*[-/]\s*(\d{1,2})\s+([A-Za-zÀ-ɏ]+)\s+(\d{4})')
      if($mm.Success){ $tIso = TrTarihCoz ("{0} {1} {2}" -f $mm.Groups[2].Value, $mm.Groups[3].Value, $mm.Groups[4].Value) }
      if(-not $tIso){
        $mm2 = [regex]::Match($duz, '(\d{1,2})\s+([A-Za-zÀ-ɏ]+)\s+(\d{4})\s+tarih')
        if($mm2.Success){ $tIso = TrTarihCoz ("{0} {1} {2}" -f $mm2.Groups[1].Value, $mm2.Groups[2].Value, $mm2.Groups[3].Value) }
      }
      if(-not $tIso){ continue }
      try { if([datetime]::ParseExact($tIso,"yyyy-MM-dd",$null) -lt $bugun){ continue } } catch { continue }
      $gorulen[$adres] = 1
      $kayitlar += [ordered]@{
        baslik = $k.baslik; konu = "Ticaret heyeti"; birlik = $birlik.ad
        tarih = $tIso; ozet = ""; url = $adres
      }
      $bulunanKayit++
      Start-Sleep -Milliseconds 200
    }
    $durum = "OKUNABİLİR ($yol, $bulunanKayit kayıt)"
    $yeniAcilan += ("{0} -> {1}" -f $birlik.ad, $yol)
    break
  }
  $birlikDurum += [ordered]@{ birlik = $birlik.ad; durum = $durum }
  Start-Sleep -Milliseconds 200
}
if(@($yeniAcilan).Count){
  Write-Host ("*** YENI OKUNABILIR BIRLIK: {0}" -f ($yeniAcilan -join " | "))
} else {
  Write-Host ("11 birlik yoklandi: hepsi hala JS ile ciziyor (bugun yeni acilan yok)")
}

if($okunanSorgu -eq 0){
  Write-Host "HATA: EIB arama ucunun hicbir sorgusu okunamadi - dosyaya DOKUNULMADI"
  exit 1
}

$kayitlar = @($kayitlar | Sort-Object { $_.tarih } -Descending)

$cikti = [ordered]@{
  guncelleme = "Kaynak: ihracatci birliklerinin kendi duyuru kanallari. Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = "https://www.eib.org.tr/Duyurular.Asp"
  not = "UR-GE ve heyet destekleri 5973 s. Karar kapsamindadir; basvuru uyesi oldugun birlik ve DYS uzerinden yurur. EIB ve UIB makinece okunuyor; kalan 11 birlik HER GUN yoklanir (asagidaki birlikDurum), acilan olursa ayni gun listeye girer."
  birlikDurum = $birlikDurum
  kayitlar = $kayitlar
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("BIRLIK UR-GE/HEYET: {0} kayit ({1} kanal okundu, hedef {2}) -> veri/birlik-urge.json [geri okuma: {3}]" -f @($kayitlar).Count, $okunanSorgu, $sorgular.Count, @($geriOkuma.kayitlar).Count)
if(@($geriOkuma.kayitlar).Count -ne @($kayitlar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
