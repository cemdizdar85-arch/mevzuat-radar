# ============================================================================
#  EIB UR-GE PILOTU - Ege Ihracatci Birlikleri'nin UR-GE proje ve ticaret/alim
#  heyeti duyurularini ceker. (19.08 Cem: "UR-GE icin EIB pilotu baglayin".)
#  Cikti: veri/eib-urge.json - destekler.html "UR-GE / heyet (EIB pilotu)" grubu.
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
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\eib-urge.json"
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
      tarih = $tarihIso
      ozet = (("$($madde.snippet)" -replace '\s+',' ').Trim())
      url = $bag
    }
  }
  Start-Sleep -Milliseconds 300
}

if($okunanSorgu -eq 0){
  Write-Host "HATA: EIB arama ucunun hicbir sorgusu okunamadi - dosyaya DOKUNULMADI"
  exit 1
}

$kayitlar = @($kayitlar | Sort-Object { $_.tarih } -Descending)

$cikti = [ordered]@{
  guncelleme = "Kaynak: Ege Ihracatci Birlikleri duyuru servisi (eib.org.tr arama ucu). Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = "https://www.eib.org.tr/Duyurular.Asp"
  not = "PILOT: yalniz Ege Ihracatci Birlikleri (Izmir). UR-GE ve heyet destekleri 5973 s. Karar kapsamindadir; basvuru uyesi oldugun birlik ve DYS uzerinden yurur. Son 120 gunun duyurulari listelenir."
  kayitlar = $kayitlar
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("EIB UR-GE: {0} duyuru ({1}/{2} sorgu okundu) -> veri/eib-urge.json [geri okuma: {3}]" -f @($kayitlar).Count, $okunanSorgu, $sorgular.Count, @($geriOkuma.kayitlar).Count)
if(@($geriOkuma.kayitlar).Count -ne @($kayitlar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
