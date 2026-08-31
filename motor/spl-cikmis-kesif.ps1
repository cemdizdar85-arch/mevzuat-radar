# ============================================================================
#  SPL CIKMIS SINAV ARSIVI - KESIF (31.08.2026)
#
#  Cem: "SPK cikmis sinav arsivi indirelim yutalim ... hepsini yuttugumuza
#  emin olalim, yarim yutmayalim."
#
#  OLCULEN GERCEK (31.08.2026, bu makineden):
#   - SPL'nin cikmis soru arsivi sayfasi CANLI SITEDE YOK:
#       https://spl.com.tr/gecmis-donem-lisanslama-sinavlari/   -> 404
#       https://spl.com.tr/icerik/gecmis-donem-lisanslama-sinavlari -> 404
#     Ayni CMS'te eski yol /icerik/sinav-calisma-notlari 302 ile yeni sayfaya
#     gidiyor (kod 200). Yani yonlendirme haritasi CALISIYOR; bu sayfa icin
#     BILEREK yonlendirme yok -> sayfa kaldirilmis.
#   - wp-sitemap'te de yok, ana menude de yok, site aramasinda da yok.
#   - SPL kurali: 19-20 Aralik 2014 ve SONRASI kagit sinavlarin sorulari
#     YAYIMLANMIYOR; ONCESI yayimlanmisti. Yani arsivin kapsami ~2010-2014.
#
#  BU YUZDEN AYNA KULLANILIYOR - ve NEDEN kural disi degil:
#  Ev kurali "ucuncu taraf ayna kullanilmaz" (bkz motor/spl-resmi-indir.ps1).
#  Burada ayna ICERIK KAYNAGI olarak degil, YALNIZ ADRES DIZINI olarak
#  kullanilir: arsivden dosyanin ORIJINAL spl.com.tr adresi ogrenilir, dosya
#  MUMKUNSE YINE spl.com.tr'den indirilir. Ayna kopyasi ancak resmi adres
#  olmediginde ve "kaynak=ayna" damgasiyla alinir - hangisinin nereden geldigi
#  envanterde tek tek yazilidir.
#
#  BU BETIK YALNIZ OLCER. Indirmez, yutmaz, ambara dokunmaz.
#  Ciktisi: veri/spl-cikmis-envanteri.json + veri/SPL-CIKMIS-KESIF.md
#
#  NEREDE KOSAR: web.archive.org bu makineden ERISILMEZ (DNS cozuluyor
#  207.241.237.3, TCP 443 acilmiyor - TR ag engeli). Bu yuzden GitHub
#  Actions runner'inda kosar: .github/workflows/spl-cikmis-kesif.yml
#
#  KULLANIM:
#    pwsh -File motor/spl-cikmis-kesif.ps1
#    pwsh -File motor/spl-cikmis-kesif.ps1 -Sessiz
# ============================================================================
param([switch]$Sessiz, [int]$SnapshotSayisi = 90)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$UA  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$CDX = 'https://web.archive.org/cdx/search/cdx'

# curl: Windows'ta curl.exe, Linux runner'da curl. Ag katmani bilerek curl'de
# (spl-resmi-indir.ps1 dersi: Invoke-WebRequest bu siteye TLS el sikismasinda
# dusuyor ve ikili icerigi bozuyor).
$curl = (Get-Command curl.exe -ErrorAction SilentlyContinue)
if(-not $curl){ $curl = Get-Command curl -ErrorAction SilentlyContinue }
if(-not $curl){ throw 'curl bulunamadi' }
$curl = $curl.Source

function Yaz($m, $renk='Gray'){ if(-not $Sessiz){ Write-Host $m -ForegroundColor $renk } }

# --- HTTP: metin cek, 3 deneme (Wayback oran siniri uyguluyor: 429) ---------
function Cek([string]$url, [int]$sure = 120){
  for($d = 1; $d -le 4; $d++){
    $tmp = [IO.Path]::GetTempFileName()
    try {
      $kod = (& $curl -sS -m $sure -A $UA -L --compressed -o $tmp -w '%{http_code}' $url 2>$null)
      $kod = "$kod".Trim()
      if($kod -eq '200'){ return [IO.File]::ReadAllText($tmp, [Text.Encoding]::UTF8) }
      # 429/503 = oran siniri, sabirla tekrar dene. 404 = gercekten yok, birak.
      if($kod -eq '404'){ return $null }
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds (5 * $d)
  }
  return $null
}

# --- CDX sorgusu -> satir dizisi --------------------------------------------
# DIKKAT (PS 5.1 dizi tuzagi, oturum-devir notu): once ata, SONRA @() ile sar.
function CdxSorgu([string]$sorgu){
  $ham = Cek ("{0}?{1}" -f $CDX, $sorgu)
  if(-not $ham){ return @() }
  $satirlar = $ham -split "`n" | Where-Object { $_.Trim() -ne '' }
  $satirlar = @($satirlar)
  $cikti = New-Object System.Collections.ArrayList
  foreach($s in $satirlar){
    $p = $s -split '\s+'
    if($p.Count -lt 3){ continue }
    [void]$cikti.Add([pscustomobject]@{
      damga    = $p[0]
      url      = $p[1]
      kod      = $p[2]
      tip      = if($p.Count -ge 4){ $p[3] } else { '' }
    })
  }
  return @($cikti)
}

$rapor = [ordered]@{
  olcum        = (Get-Date).ToString('s')
  kosum_yeri   = if($env:GITHUB_ACTIONS){ 'github-actions' } else { 'yerel' }
  canli_sayfa  = [ordered]@{}
  snapshotlar  = @()
  sayfadan_pdf = @()
  domain_pdf   = @()
  hukum        = 'OLCULEMEDI'
  not          = ''
}

# ============================================================================
#  1) CANLI SITE: sayfa gercekten yok mu? (her kosuda yeniden olculur -
#     "sayfa kaldirilmis" bir HUKUM, ve hukumler eskir.)
# ============================================================================
Yaz "`n=== 1/4 - CANLI SITE OLCUMU ===" 'Cyan'
$canliAdresler = @(
  'https://spl.com.tr/gecmis-donem-lisanslama-sinavlari/'
  'https://spl.com.tr/icerik/gecmis-donem-lisanslama-sinavlari'
  'https://spl.com.tr/sinav-calisma-notlari/'   # kontrol: bu 200 donmeli
)
$BOSLUK = if($IsLinux -or $IsMacOS){ '/dev/null' } else { 'NUL' }
foreach($a in $canliAdresler){
  $kod = "$(& $curl -sS -m 60 -A $UA -L -o $BOSLUK -w '%{http_code}' $a 2>$null)".Trim()
  $rapor.canli_sayfa[$a] = $kod
  Yaz ("  {0,-60} {1}" -f $a, $kod) $(if($kod -eq '200'){'Green'}else{'Yellow'})
}

# ============================================================================
#  2) ARSIVDE SAYFANIN ANLIK GORUNTULERI
# ============================================================================
Yaz "`n=== 2/4 - ARSIV ANLIK GORUNTULERI ===" 'Cyan'
# 31.08 KUSUR (ilk kosuda olculdu, 0 anlik goruntu dondu): matchType=prefix ile
# adresin sonuna '*' KONULMAZ - yildiz kacis karakteri degil, adresin PARCASI
# sayilir ve hicbir sey eslesmez. Yildiz yalniz matchType'i kendisi belirleten
# "url=...*" YAZIMINDA gecerlidir, ikisi birlikte kullanilmaz.
$sayfaUrlleri = @(
  'spl.com.tr/gecmis-donem-lisanslama-sinavlari'
  'spl.com.tr/icerik/gecmis-donem-lisanslama-sinavlari'
  'www.spl.com.tr/icerik/gecmis-donem-lisanslama-sinavlari'
)
$snapshot = New-Object System.Collections.ArrayList
foreach($su in $sayfaUrlleri){
  $q = "url=$([uri]::EscapeDataString($su))&matchType=prefix&output=text&fl=timestamp,original,statuscode,mimetype&filter=statuscode:200&collapse=digest&limit=200"
  $r = CdxSorgu $q
  Yaz ("  {0,-58} anlik goruntu: {1}" -f $su, @($r).Count)
  foreach($x in @($r)){ [void]$snapshot.Add($x) }
}

# EMNIYET AGI-1: adres tahmin etmeyi birak, ARSIVE SOR. spl.com.tr altinda
# adresinde sinav/gecmis/lisanslama/soru gecen TUM HTML sayfalari aday listeye
# girer. Boylece 2010-2014 arasindaki ESKI CMS'in bilmedigimiz yollari da
# (ornek: /Sayfa/..., /Sinavlar/...) kendiliginden yakalanir.
$aramaQ = "url=spl.com.tr&matchType=domain&output=text&fl=timestamp,original,statuscode,mimetype" +
          "&filter=statuscode:200&filter=mimetype:text/html" +
          "&filter=original:.*[Ss][Ii1I][Nn][Aa][Vv].*|.*[Gg]ecmis.*|.*[Ll]isanslama.*|.*[Ss]oru.*" +
          "&collapse=urlkey&limit=800"
$adaySayfa = CdxSorgu $aramaQ
Yaz ("  arsivden aday HTML sayfasi: {0}" -f @($adaySayfa).Count)
foreach($x in @($adaySayfa)){ [void]$snapshot.Add($x) }

# Ayni adresin birden fazla kaydi olabilir; adres basina EN YENI kayit tutulur,
# sonra yeniden eskiye siralanir.
$enYeni = @{}
foreach($s in @($snapshot)){
  $a = $s.url.ToLower()
  if(-not $enYeni.ContainsKey($a) -or $s.damga -gt $enYeni[$a].damga){ $enYeni[$a] = $s }
}
$snapshot = @($enYeni.Values | Sort-Object damga -Descending)
$rapor.snapshotlar = @($snapshot | ForEach-Object { [ordered]@{ damga=$_.damga; url=$_.url } })

if($snapshot.Count -eq 0){
  $rapor.hukum = 'KOR'
  $rapor.not   = 'Arsivde sayfanin tek anlik goruntusu bulunamadi (ya da web.archive.org bu kosuda erisilemedi). Adres listesi CIKARILAMADI.'
  Yaz "  KOR: arsivde anlik goruntu yok / arsive erisilemedi." 'Yellow'
}

# ============================================================================
#  3) HER ANLIK GORUNTUDEN PDF ADRESLERI + BAGLANTI METNI
#     Birden fazla anlik goruntu okunur: sayfa yillar icinde BUYUDUGU icin tek
#     goruntu eksik liste verir. Hepsi BIRLESTIRILIR (union), boylece "yarim
#     liste" riski kapanir.
# ============================================================================
Yaz "`n=== 3/4 - ANLIK GORUNTULERDEN ADRES CIKARIMI ===" 'Cyan'
$pdfler = @{}
$okunan = 0
foreach($s in $snapshot){
  if($okunan -ge $SnapshotSayisi){ break }
  # id_ = arsivin kendi basligi/js'i eklenmemis HAM kopya
  $ham = Cek ("https://web.archive.org/web/{0}id_/{1}" -f $s.damga, $s.url)
  if(-not $ham){ Yaz ("  [{0}] okunamadi" -f $s.damga) 'Yellow'; continue }
  $okunan++

  $bulunan = 0
  $eslesme = [regex]::Matches($ham, '(?is)<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>')
  foreach($m in $eslesme){
    $h = $m.Groups[1].Value
    if($h -notmatch '(?i)\.(pdf|zip|rar|doc|docx)(\?|$)'){ continue }

    # Arsiv sarmalini soy: /web/20140101010101/http://... -> http://...
    $temiz = $h
    if($temiz -match '(?i)/web/\d{8,17}[a-z_]*/(https?://.+)$'){ $temiz = $Matches[1] }
    if($temiz -notmatch '^https?://'){
      try { $temiz = ([uri]::new([uri]("http://" + $s.url), $temiz)).AbsoluteUri } catch { continue }
    }
    if($temiz -notmatch '(?i)spl\.com\.tr'){ continue }

    $metin = [regex]::Replace($m.Groups[2].Value, '<[^>]+>', ' ')
    $metin = [Net.WebUtility]::HtmlDecode($metin) -replace '\s+', ' '
    $metin = $metin.Trim()

    # 31.08 BULGU: SPL'nin yeni CMS'i sinav kitapciklarini GUID adiyla
    # (docs/other/fa0b822b-40b0-45.pdf) sunuyor. Yani DOSYA ADINDA "sinav"
    # ya da "soru" GECMIYOR - ada bakan bir suzgec 334 kitapcigin HEPSINI
    # sessizce eler. Anlam TAMAMEN sayfadaki baglamda:
    #   baslik = donem ("31 Mayis - 1 Haziran 2014 ...")
    #   satir  = ders ("Temel Duzey", "Ileri Duzey", ...)
    #   link   = "A KITAPCIGI" / "B KITAPCIGI" / "A-B KITAPCIGI"
    # Bu yuzden her baglantinin ONUNDEKI metin de saklanir; siniflandirma
    # dosya adiyla degil BU BAGLAMLA yapilir.
    $onceki = ''
    $bas = [Math]::Max(0, $m.Index - 700)
    $onceki = $ham.Substring($bas, $m.Index - $bas)
    $onceki = [regex]::Replace($onceki, '(?is)<(script|style).*?</\1>', ' ')
    $onceki = [regex]::Replace($onceki, '<[^>]+>', ' ')
    $onceki = ([Net.WebUtility]::HtmlDecode($onceki) -replace '\s+', ' ').Trim()
    if($onceki.Length -gt 260){ $onceki = $onceki.Substring($onceki.Length - 260) }

    $anahtar = $temiz.ToLower()
    if(-not $pdfler.ContainsKey($anahtar)){
      $pdfler[$anahtar] = [ordered]@{ url=$temiz; etiket=$metin; onceki_metin=$onceki; ilk_goruldu=$s.damga; goruldu=@() }
    }
    if($metin -and -not $pdfler[$anahtar].etiket){ $pdfler[$anahtar].etiket = $metin }
    if($onceki -and -not $pdfler[$anahtar].onceki_metin){ $pdfler[$anahtar].onceki_metin = $onceki }
    $pdfler[$anahtar].goruldu += $s.damga
    $bulunan++
  }
  Yaz ("  [{0}] {1} baglanti · birikmis tekil: {2}" -f $s.damga, $bulunan, $pdfler.Count)
}
$rapor.sayfadan_pdf = @($pdfler.Values | ForEach-Object { [ordered]@{ url=$_.url; etiket=$_.etiket; onceki_metin=$_.onceki_metin; ilk_goruldu=$_.ilk_goruldu } })

# ============================================================================
#  4) EMNIYET AGI - DOMAIN GENELI PDF TARAMASI
#     Sayfa okumasi bir seyi kacirirsa diye arsivin spl.com.tr altinda gordugu
#     TUM PDF'ler ayrica listelenir. Burada SUZME YAPILMAZ; ne varsa yazilir.
#     "Sinav sorusu mu?" karari sonraki adimda, insan gozuyle verilir.
# ============================================================================
Yaz "`n=== 4/4 - DOMAIN GENELI PDF TARAMASI (emniyet agi) ===" 'Cyan'
# Iki ayri suzgecle sorulur ve BIRLESTIRILIR - tek suzgece guvenilmez:
#  (a) mimetype: arsivin kaydettigi tip; bazi PDF'ler octet-stream damgali.
#  (b) adres uzantisi: tip yanlis damgali olsa da adres .pdf ile bitiyor.
#  (c) adi soru/cevap/sinav gecen HER dosya - uzantisi ne olursa olsun.
$sorgular = @(
  "url=spl.com.tr&matchType=domain&output=text&fl=timestamp,original,statuscode,mimetype&collapse=urlkey&filter=statuscode:200&filter=mimetype:application/pdf&limit=8000"
  "url=spl.com.tr&matchType=domain&output=text&fl=timestamp,original,statuscode,mimetype&collapse=urlkey&filter=statuscode:200&filter=original:.*%5C.[Pp][Dd][Ff]$&limit=8000"
  "url=spl.com.tr&matchType=domain&output=text&fl=timestamp,original,statuscode,mimetype&collapse=urlkey&filter=statuscode:200&filter=original:.*[Ss]oru.*|.*[Cc]evap.*|.*[Ss][Ii1I][Nn][Aa][Vv].*|.*[Aa]nahtar.*&limit=8000"
)
# EMNIYET AGI-2 (31.08, ilk kosunun bulgusu uzerine): 1715 dosyalik domain
# taramasinda 2013 ve 2014 sinavlarinin YALNIZ CEVAP ANAHTARLARI cikti, soru
# kitapciklari cikmadi. Sebep muhtemelen su: o donemin dosyalari oep.spl.com.tr
# gibi AYRI SUNUCULARDA ve arsiv oralari daha az taramis. Bu yuzden bilinen
# TUM yukleme koklerine AYRI AYRI ve SUZGECSIZ prefix sorgusu atilir - "adinda
# sinav gecmiyor" diye elenen dosya kalmasin.
foreach($kokYol in @('oep.spl.com.tr/pdf/','spl.com.tr/Images/Uploads/','www.spl.com.tr/Images/Uploads/',
                     'spl.com.tr/PDF/','www.spl.com.tr/PDF/','spl.com.tr/Docs/','www.spl.com.tr/Docs/',
                     'spl.com.tr/Content/','www.spl.com.tr/Content/','spl.com.tr/Upload/','www.spl.com.tr/Upload/',
                     'basvuru.spl.com.tr/','www.spl.com.tr/spl/','spl.com.tr/spl/')){
  $sorgular += "url=$([uri]::EscapeDataString($kokYol))&matchType=prefix&output=text&fl=timestamp,original,statuscode,mimetype&collapse=urlkey&limit=5000"
}

$tumPdfHash = @{}
foreach($sq in $sorgular){
  $r = CdxSorgu $sq
  Yaz ("  sorgu -> {0} satir" -f @($r).Count)
  foreach($x in @($r)){ if(-not $tumPdfHash.ContainsKey($x.url.ToLower())){ $tumPdfHash[$x.url.ToLower()] = $x } }
}
$tumPdf = @($tumPdfHash.Values | Sort-Object url)
Yaz ("  arsivde spl.com.tr altinda tekil dosya: {0}" -f @($tumPdf).Count)
$rapor.domain_pdf = @($tumPdf | ForEach-Object { [ordered]@{ damga=$_.damga; url=$_.url; tip=$_.tip } })

# --- HUKUM ------------------------------------------------------------------
if(@($pdfler.Keys).Count -gt 0){
  $rapor.hukum = 'YESIL'
  $rapor.not   = 'Adres listesi cikarildi. Sonraki adim: indirme (once canli spl.com.tr, olmazsa arsiv kopyasi) - motor/spl-cikmis-indir.ps1'
} elseif(@($tumPdf).Count -gt 0){
  $rapor.hukum = 'SARI'
  $rapor.not   = 'Sayfa okumasindan adres cikmadi ama domain geneli tarama PDF buldu; liste elle suzulmeli.'
} else {
  $rapor.hukum = 'KOR'
  if(-not $rapor.not){ $rapor.not = 'Ne sayfa okumasi ne domain taramasi adres verdi.' }
}

$rapor.sayfadan_pdf_sayisi = @($rapor.sayfadan_pdf).Count
$rapor.domain_pdf_sayisi   = @($rapor.domain_pdf).Count

# --- YAZ --------------------------------------------------------------------
$jsonYol = Join-Path $kok 'veri/spl-cikmis-envanteri.json'
[IO.File]::WriteAllText($jsonYol, (ConvertTo-Json -InputObject $rapor -Depth 6), [Text.UTF8Encoding]::new($false))

$md = New-Object System.Collections.ArrayList
[void]$md.Add('# SPL CIKMIS SINAV ARSIVI - KESIF')
[void]$md.Add('')
[void]$md.Add(('> Olcum: **{0}** · kosum yeri: **{1}** · hukum: **{2}**' -f $rapor.olcum, $rapor.kosum_yeri, $rapor.hukum))
[void]$md.Add('>')
[void]$md.Add('> Bu sayfa MAKINE CIKTISIDIR (motor/spl-cikmis-kesif.ps1) - elle duzenlenmez.')
[void]$md.Add('')
[void]$md.Add('## Canli site')
[void]$md.Add('')
[void]$md.Add('| Adres | HTTP |')
[void]$md.Add('|---|---|')
foreach($k in $rapor.canli_sayfa.Keys){ [void]$md.Add(('| `{0}` | {1} |' -f $k, $rapor.canli_sayfa[$k])) }
[void]$md.Add('')
[void]$md.Add(('## Arsiv anlik goruntusu: {0} · sayfadan cikan tekil dosya: {1} · domain geneli PDF: {2}' -f @($rapor.snapshotlar).Count, $rapor.sayfadan_pdf_sayisi, $rapor.domain_pdf_sayisi))
[void]$md.Add('')
[void]$md.Add($rapor.not)
[void]$md.Add('')
[void]$md.Add('## Sayfadan cikan dosyalar')
[void]$md.Add('')
[void]$md.Add('| # | Etiket (baglanti metni) | Adres |')
[void]$md.Add('|---:|---|---|')
$i = 0
foreach($p in $rapor.sayfadan_pdf){ $i++; [void]$md.Add(('| {0} | {1} | `{2}` |' -f $i, $p.etiket, $p.url)) }
[IO.File]::WriteAllText((Join-Path $kok 'veri/SPL-CIKMIS-KESIF.md'), (($md -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))

Yaz ''
Yaz ("HUKUM: {0} · sayfadan {1} dosya · domain geneli {2} PDF" -f $rapor.hukum, $rapor.sayfadan_pdf_sayisi, $rapor.domain_pdf_sayisi) `
    $(if($rapor.hukum -eq 'YESIL'){'Green'}elseif($rapor.hukum -eq 'KOR'){'Red'}else{'Yellow'})
Yaz '  -> veri/spl-cikmis-envanteri.json · veri/SPL-CIKMIS-KESIF.md'

if($rapor.hukum -eq 'KOR'){ exit 1 }
exit 0
