# ============================================================================
#  KAMU IHALE BULTENI HASADI - iptal ve duzeltme ilanlari
#  Cem 13.08 onayi. Neden: ilan.gov.tr'de gunde 1-2 iptal ilani dusuyor,
#  bultende TEK GUNDE 29 (yalniz Mal turunde). Bulten 4734 m.13'un resmi yayin
#  yeri; KIK kendi sayfasinda "farklilik olursa PDF esastir" diyor.
#
#  Cikti: veri/ihale-bulten-durum.json  { iptal:[...], duzeltme:[...] }
#  UI: ihale-radari.html yurt ici kartlarina damga.
#
#  KIMLIK NOTU: bulten IKN (2026/1254015) kullanir, ilan.gov.tr ILN (ILN02529303).
#  Ikisi FARKLI kimlik. Bu yuzden eslestirme uydurulmaz - IKN kendi basina
#  gosterilir, kullanici kendi IKN'siyle arar. Baslik benzerligiyle eslestirme
#  DENENMEDI: yanlis eslesme "ihalen iptal" demek olur, en kotu hata odur.
# ============================================================================
param(
  [string[]]$Turler = @('Mal','Yapim','Hizmet','Danismanlik'),
  [switch]$Yaz,
  # Ayristiriciyi gelistirirken bulteni her seferinde yeniden indirmemek icin:
  # scratchpad'deki mevcut .txt kullanilir. KIK sunucusuna bosuna yuk bindirmez.
  [switch]$YerelMetin,
  [string]$Klasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\94aa3424-c78a-4612-b9eb-65883203c30d\scratchpad"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not (Test-Path $Klasor)){ New-Item -ItemType Directory -Force $Klasor | Out-Null }

$adres = "https://ekap.kik.gov.tr/ekap/ilan/bultenindirme.aspx"
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-BultenHasat/1.0"

function GizliAl([string]$html, [string]$ad){
  $m = [regex]::Match($html, 'id="' + [regex]::Escape($ad) + '"[^>]*value="([^"]*)"')
  if($m.Success){ return $m.Groups[1].Value }
  $m2 = [regex]::Match($html, 'name="' + [regex]::Escape($ad) + '"[^>]*value="([^"]*)"')
  if($m2.Success){ return $m2.Groups[1].Value }
  return ""
}

# --- Tek turun bultenini indir, metne cevir ---------------------------------
function BultenMetni([string]$tur){
  $hazir = Join-Path $Klasor ("bulten-{0}.txt" -f $tur.ToLower())
  if($YerelMetin){
    if(Test-Path $hazir){ Write-Host "   (yerel metin kullanildi)"; return (Get-Content $hazir -Raw -Encoding UTF8) }
    Write-Host "   (yerel metin yok - indiriliyor)"
  }
  $oturum = $null
  $s1 = Invoke-WebRequest -Uri $adres -Headers @{ "User-Agent"=$ua } -SessionVariable oturum -TimeoutSec 90 -UseBasicParsing
  $html = $s1.Content
  $govde = @{
    '__EVENTTARGET'   = "ctl00`$ContentPlaceHolder1`$lnkBtn$tur"
    '__EVENTARGUMENT' = ''
    '__VIEWSTATE'     = (GizliAl $html '__VIEWSTATE')
    '__PIT'           = (GizliAl $html '__PIT')
    '__PITC'          = (GizliAl $html '__PITC')
    '__SCROLLPOSITIONX' = (GizliAl $html '__SCROLLPOSITIONX')
    '__SCROLLPOSITIONY' = (GizliAl $html '__SCROLLPOSITIONY')
    '__EVENTVALIDATION' = (GizliAl $html '__EVENTVALIDATION')
    'ctl00$Menu1$hdnAktIKN' = (GizliAl $html 'ctl00_Menu1_hdnAktIKN')
    'ctl00$ContentPlaceHolder1$ddlstBxIhaleTur' = '0'
    'ctl00$ContentPlaceHolder1$etBultenTarihi$EkapTakvimTextBox_etBultenTarihi' = ''
  }
  $ham = Join-Path $Klasor ("bulten-{0}.ham" -f $tur.ToLower())
  # TUZAK: IWR .Content ikili veriyi bozar - -OutFile sart (13.08 olculdu)
  Invoke-WebRequest -Uri $adres -Method Post -Body $govde -WebSession $oturum `
    -Headers @{ "User-Agent"=$ua; "Referer"=$adres } -TimeoutSec 300 -UseBasicParsing -OutFile $ham
  if((Get-Item $ham).Length -lt 100000){ return $null }
  $pdf = Join-Path $Klasor ("bulten-{0}.pdf" -f $tur.ToLower())
  $ilk = [byte[]](Get-Content $ham -Encoding Byte -TotalCount 2)
  if($ilk[0] -eq 0x50 -and $ilk[1] -eq 0x4B){
    $zip = Join-Path $Klasor ("bulten-{0}.zip" -f $tur.ToLower())
    Copy-Item $ham $zip -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ar = [IO.Compression.ZipFile]::OpenRead($zip)
    $g = @($ar.Entries | Where-Object { $_.Name -match '\.pdf$' })[0]
    if(-not $g){ $ar.Dispose(); return $null }
    [IO.Compression.ZipFileExtensions]::ExtractToFile($g, $pdf, $true)
    $ar.Dispose()
  } else { Copy-Item $ham $pdf -Force }
  $txt = Join-Path $Klasor ("bulten-{0}.txt" -f $tur.ToLower())
  & pdftotext -enc UTF-8 -layout $pdf $txt   # -enc UTF-8 olmadan Turkce harfler duser
  if(-not (Test-Path $txt)){ return $null }
  return (Get-Content $txt -Raw -Encoding UTF8)
}

# --- Bir ilan blogunu ayristir ----------------------------------------------
# BULTEN DUZENI TUZAGI (13.08 olculdu): PDF'te tablo hucresi DIKEY ORTALI, yani
# uzun bir deger etiket satirinin hem USTUNE hem ALTINA tasiyor:
#     <bosluk*51> İzmir Büyükşehir Belediyesi Tarımsal Hizmetler Dairesi
#     1.1. Adı   :
#     <bosluk*51> Başkanlığı Tarımsal Üretim Şube Müdürlüğü
# Sadece etiket satirini okuyan ayristirici idarenin adini YARIM aliyordu
# ("Başkanlığı Tarımsal Üretim Şube Müdürlüğü" - basi kayip).
# Cozum: etiketsiz "sag sutun" satirlari, en yakin etikete baglanir.
function BlokAlanlari([string]$blok){
  $satirlar = $blok -split "`r?`n"
  $etiketler = @()   # @{ i; ad; deger }
  $serbest   = @()   # @{ i; metin }
  for($i=0; $i -lt $satirlar.Count; $i++){
    $s = $satirlar[$i]
    if(-not $s.Trim()){ continue }
    $m = [regex]::Match($s, '^\s*((?:\d+\.\d+\.|\d+-)\s*[^:]{2,60}?)\s*:\s*(.*)$')
    if($m.Success){
      $etiketler += [pscustomobject]@{ i=$i; ad=($m.Groups[1].Value.Trim() -replace '\s{2,}',' '); deger=$m.Groups[2].Value.Trim() }
    } else {
      # Serbest satir SAG SUTUN degeri mi, yoksa bolum basligi mi?
      # Degerler sagda durur (girinti ~50); "1- İdarenin", "2-İptal edilen ihaleye
      # ait ilanın yayımlandığı" gibi basliklar SOLDA baslar. Girinti olcutu
      # olmadan bu basliklar idare adinin sonuna yapisiyordu (olculdu).
      $girinti = $s.Length - $s.TrimStart().Length
      if($girinti -ge 25 -and $s.Trim() -notmatch '^\d+\s*-'){
        $serbest += [pscustomobject]@{ i=$i; metin=($s.Trim() -replace '\s{2,}',' ') }
      }
    }
  }
  # Etiketsiz satirlari en yakin etikete bagla. ESITLIKTE SONRAKI ETIKET secilir:
  # bultende hucre dikey ortali oldugu icin bir degerin ilk satiri kendi etiketinin
  # USTUNDE durur. "Onceki" secilirse adres, bir ustteki idare adina yapisiyordu
  # (Yakutiye Belediyesi vakasinda olculdu).
  foreach($sb in $serbest){
    if(-not $etiketler.Count){ continue }
    $en = $null; $enFark = 9999
    foreach($e in $etiketler){
      $f = [math]::Abs($e.i - $sb.i)
      if($f -lt $enFark -or ($f -eq $enFark -and $e.i -gt $sb.i)){ $enFark=$f; $en=$e }
    }
    # 2 satirdan uzak serbest metin baska bir seydir (baslik, sayfa alt bilgisi) - alinmaz
    if($en -and $enFark -le 1){ $en.deger = ($en.deger + ' ' + $sb.metin).Trim() }
  }
  return $etiketler
}
function AlanBul($etiketler, [string]$desen){
  foreach($e in $etiketler){ if($e.ad -match $desen){ return ($e.deger -replace '\s{2,}',' ').Trim() } }
  return ""
}
function IlanlariCoz([string]$metin, [string]$bolumBasi, [string]$bolumSonu, [string]$tur){
  $i = $metin.IndexOf($bolumBasi, 20000)   # icindekiler tablosunu atla
  if($i -lt 0){ return @() }
  $j = if($bolumSonu){ $metin.IndexOf($bolumSonu, $i + 100) } else { -1 }
  if($j -lt 0){ $j = $metin.Length }
  $bolum = $metin.Substring($i, $j - $i)
  $sonuc = @()
  # Her ilan bir baslikla baslar. OLCULDU: iptal basligi "İHALE İPTAL İLANI",
  # duzeltme basligi ise yalnizca "DÜZELTME İLANI" - "İHALE" oneki YOK. Onek
  # zorunlu tutulunca butun duzeltme ilanlari kaciyordu (14 iptal, 0 duzeltme).
  $basliklar = [regex]::Matches($bolum, '(?m)^\s*(?:İHALE\s+)?(İPTAL|DÜZELTME)\s+İLANI\s*$')
  for($n=0; $n -lt $basliklar.Count; $n++){
    $bas = $basliklar[$n].Index
    $son = if($n+1 -lt $basliklar.Count){ $basliklar[$n+1].Index } else { $bolum.Length }
    $blok = $bolum.Substring($bas, $son - $bas)
    $ikn = ""
    $mi = [regex]::Match($blok, 'İhale Kayıt Numarası\s*\(İKN\)\s*:\s*(\d{4}/\d+)')
    if(-not $mi.Success){ $mi = [regex]::Match($blok, '(\d{4}/\d{5,})') }
    if($mi.Success){ $ikn = $mi.Groups[1].Value }
    if(-not $ikn){ continue }
    $isAdi = ""
    # TUZAK: is adi iki satira yayiliyor ("... SATIN / ALINACAKTIR"). Bitisi
    # "$" ile aramak COK SATIRLI modda SATIR sonuna denk gelir ve adi kesiyordu;
    # metin sonu icin \z kullanilir.
    $ma = [regex]::Match($blok, '(?m)^\s*\d+\.\s+' + [regex]::Escape($ikn) + '\s+(.+?)(?:\r?\n\s*\r?\n|\z)', 'Singleline')
    if($ma.Success){ $isAdi = ($ma.Groups[1].Value -replace '\s+',' ').Trim() }
    # PS 5.1'de inline if IFADE degildir - once degiskene alinir
    $durumAdi = 'duzeltme'
    if($basliklar[$n].Groups[1].Value -eq 'İPTAL'){ $durumAdi = 'iptal' }
    $alanlar = BlokAlanlari $blok
    # Iptal sebebi: "<is adi> İhalesi, <SEBEP> Nedeniyle İptal Edilmiştir."
    # Yakalanamazsa BOS birakilir - sebep UYDURULMAZ.
    # OLCULDU (39 kayit elden gecirildi): sebep cumlesinin UC ayri bitisi var ve
    # idareler buyuk/kucuk harfi karisik yaziyor. Ilk desen 8 iptalde bos birakti:
    #  a) "...Nedeniyle İptal Edilmiştir."
    #  b) "...Uygun Bulunmamıştır. İptal edilmiştir."   (kucuk e)
    #  c) "...İhalenin İptal Edilmesine Karar Verilmiştir."
    # Bu yuzden desen (?i) ve uzunluk 400. Yine yakalanamazsa BOS kalir - UYDURULMAZ.
    $sebep = ""
    $ms = [regex]::Match($blok, '(?is)İhalesi[,;]\s*(.{3,400}?)\s*(?:nedeniyle\s+iptal\s+edilmiştir|iptal\s+edilmesine\s+karar\s+verilmiştir|iptal\s+edilmiştir)')
    if($ms.Success){ $sebep = ($ms.Groups[1].Value -replace '\s+',' ').Trim() }
    $sonuc += [ordered]@{
      ikn      = $ikn
      tur      = $tur
      durum    = $durumAdi
      isAdi    = $isAdi
      idare    = (AlanBul $alanlar 'Adı$')
      sehir    = (AlanBul $alanlar 'Adresi$')
      sebep    = $sebep
      asilIlan = (AlanBul $alanlar 'Kamu İhale Bülteninin tarih')
      tarih    = (AlanBul $alanlar 'İptal Tarihi')
    }
  }
  return $sonuc
}

$hepsi = @()
foreach($t in $Turler){
  Write-Host ("--- {0} bulteni ---" -f $t)
  $metin = $null
  try { $metin = BultenMetni $t } catch { Write-Host ("   HATA: {0}" -f $_.Exception.Message) }
  if(-not $metin){ Write-Host "   alinamadi, atlandi"; continue }
  Write-Host ("   metin: {0:N0} karakter" -f $metin.Length)
  $ip = @(IlanlariCoz $metin '3. İHALE DÜZELTME İLANLARI' '5. ÇERÇEVE ANLAŞMA' $t)
  Write-Host ("   duzeltme+iptal bolumunden cikan: {0} ilan" -f $ip.Count)
  $hepsi += $ip
}

$iptal    = @($hepsi | Where-Object { $_.durum -eq 'iptal' })
$duzeltme = @($hepsi | Where-Object { $_.durum -eq 'duzeltme' })
Write-Host ("`n=== TOPLAM: {0} iptal · {1} duzeltme ===" -f $iptal.Count, $duzeltme.Count)
foreach($x in ($hepsi | Select-Object -First 5)){
  Write-Host ("  [{0}] {1} · {2}" -f $x.durum, $x.ikn, ("$($x.isAdi)".Substring(0,[math]::Min(60,"$($x.isAdi)".Length))))
  Write-Host ("       idare: {0}" -f ("$($x.idare)".Substring(0,[math]::Min(70,"$($x.idare)".Length))))
  Write-Host ("       sebep: {0}" -f ("$($x.sebep)".Substring(0,[math]::Min(80,"$($x.sebep)".Length))))
  Write-Host ("       asil ilan: {0} · iptal tarihi: {1}" -f $x.asilIlan, $x.tarih)
}

if($Yaz){
  $yol = Join-Path $kok "veri\ihale-bulten-durum.json"
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni (KİK) — 4734 s.K. m.13. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    kaynak = "ekap.kik.gov.tr/ekap/ilan/bultenindirme.aspx"
    iptal = $iptal
    duzeltme = $duzeltme
  }
  ($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
  Write-Host ("`n-> {0}" -f $yol)
  # YAZ -> GERI OKU -> KARSILASTIR
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("   geri okuma: {0} iptal · {1} duzeltme" -f @($geri.iptal).Count, @($geri.duzeltme).Count)
} else {
  Write-Host "`n(olcum modu - dosya YAZILMADI. Yazmak icin -Yaz)"
}
