# ============================================================================
#  FUAR DESTEK HASAT - Ticaret Bakanligi "destek kapsamina alinan yurt disi
#  fuarlar" xlsx listelerini ceker. (19.08 Cem: "ticaret bakanligi ihracat
#  desteklerini ekleyelim" - 5973 destekleri KURAL tabanli oldugundan cagri
#  radarina degil, TARIHLI tek parcasi olan FUAR LISTESI bu hasata baglandi.)
#  Cikti: veri/fuar-destek.json - destekler.html "Fuar Destegi" grubu okur
#  (aramali; kullanici kendi fuarini arar).
#
#  Kaynak kesfi 19.08 OLCULDU:
#   - Liste sayfasi xlsx ekli (2026_milli.xlsx 268 + 2026_bireysel.xlsx 1.773 fuar).
#   - Sayfa URL'si yila gore DEGISIR ("2025-2026-yillarinda-...") -> fuarlar
#     ana sayfasindan 'destek-kapsamina-alinan' linki KESFEDILIR, sabitlenmez.
#   - xlsx = zip + XML; sharedStrings + inlineStr ikisi de var (bireysel dosyada
#     zengin-metin hucreler); kolonlar r="A1" haritasiyla okunur, sira varsayilmaz.
#   - Tarihler Excel seri no (1899-12-30 tabani).
#   - TUTAR KOLONLARI BILEREK ALINMAZ: birim dosyada yazmiyor, uydurulmaz;
#     kullanici tutar icin resmi listeye yonlendirilir (rakam disiplini).
#
#  Sure kurali (5973 Genelge m.7): destek basvurusu fuarin BITISINDEN itibaren
#  3 ay icinde DYS'den yapilir -> bitisi 100 gunden eski fuarlar listeden duser
#  (basvuru penceresi kapali), gelecektekiler + penceresi acik olanlar kalir.
#
#  Kor kalma: hic fuar cikarsa dosyaya DOKUNULMAZ, betik 1 ile cikar (alarm).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\fuar-destek.json"
$bugun = (Get-Date).Date
$pencereSiniri = $bugun.AddDays(-100)   # bitis + 3 ay basvuru penceresi (pay birakildi)
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }

function Normalize([string]$metin){
  $t = $metin.ToLowerInvariant()
  $t = $t -replace [string][char]0x0307,''
  $t = $t -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u'
  return $t
}
function DugumMetni($dugum){
  # <t> duz dize gelebilir; xml:space gibi nitelik tasiyorsa XmlElement olur ve
  # "$dugum" 'System.Xml.XmlElement' basar (19.08 olculdu - ULKE basligi boyle
  # kaybolup 'Hedef Ulke...Tutar' kolonu ulke sanilmisti). #text ile okunur.
  if($null -eq $dugum){ return "" }
  if($dugum -is [string]){ return $dugum }
  if($dugum.'#text'){ return "$($dugum.'#text')" }
  return ""
}
function HucreMetni($c, $ss){
  # t='s' -> sharedStrings indeksi; inlineStr/is -> ic <t>'ler; digerleri v
  if($c.t -eq 's' -and "$($c.v)" -ne ''){ return $ss[[int]$c.v] }
  if($c.is){
    $p = @()
    $p += (DugumMetni $c.is.t)
    foreach($r in @($c.is.r)){ $p += (DugumMetni $r.t) }
    return (($p | Where-Object { $_ }) -join '')
  }
  return "$($c.v)"
}
function SeriTarih([string]$v){
  # ust sinir 50000 (~2036): fuar listesinde daha ilerisi imkansiz; tutar
  # kolonlarindaki 5-haneli sayilarin tarih sanilmasini keser (2055 vakasi)
  $n = 0
  if([int]::TryParse($v, [ref]$n) -and $n -gt 40000 -and $n -lt 50000){
    return ([datetime]'1899-12-30').AddDays($n).ToString('yyyy-MM-dd')
  }
  return ""
}
function KolonHarfi([string]$ref){ return ($ref -replace '\d','') }

function XlsxFuarlari([string]$dosya, [string]$tur){
  $zip = [IO.Compression.ZipFile]::OpenRead($dosya)
  try {
    $ss = @()
    $g = $zip.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
    if($g){
      $r = New-Object IO.StreamReader($g.Open()); $x = [xml]$r.ReadToEnd(); $r.Close()
      $ss = @($x.sst.si | ForEach-Object {
        $duz = DugumMetni $_.t
        if($duz){ $duz } else { @($_.r | ForEach-Object { DugumMetni $_.t } | Where-Object { $_ }) -join '' }
      })
    }
    $s1 = $zip.Entries | Where-Object { $_.FullName -eq 'xl/worksheets/sheet1.xml' }
    $r = New-Object IO.StreamReader($s1.Open()); $sx = [xml]$r.ReadToEnd(); $r.Close()
    $rows = @($sx.worksheet.sheetData.row)
    if(-not $rows.Count){ return @() }
    # BASLIK SATIRI ARANIR, ilk satir varsayilmaz: yurt ici dosyasinda ilk 4 satir
    # prestijli fuar aciklamasi, basliklar 5. satirda (19.08 olculdu).
    $basliklar = @{}; $baslikIndeks = -1
    for($ri=0; $ri -lt [Math]::Min(15, $rows.Count); $ri++){
      $aday = @{}
      foreach($c in @($rows[$ri].c)){
        $ad = Normalize (HucreMetni $c $ss)
        if($ad){ $aday[(KolonHarfi $c.r)] = $ad }
      }
      $adlar = @($aday.Values)
      $fuarVar = @($adlar | Where-Object { $_ -match '^fuar(in)? adi' }).Count
      $tarihVar = @($adlar | Where-Object { $_ -match '^basla' -or $_ -match '^bitis' }).Count
      if($fuarVar -and $tarihVar){ $basliklar = $aday; $baslikIndeks = $ri; break }
    }
    if($baslikIndeks -lt 0){ return @() }
    # CAPALI eslesme: 'Hedef Ulke/... Tutar' gibi bilesik basliklar yanlis
    # kolona oturmasin diye baslik BASINDAN eslestirilir (19.08 vakasi).
    # '^basla' HEM 'baslangic' (yurt disi) HEM 'baslama' (yurt ici) yakalar.
    $kolon = @{}
    foreach($harf in $basliklar.Keys){
      $ad = $basliklar[$harf]
      if($ad -match '^fuar(in)? adi' -and -not $kolon['ad']){ $kolon['ad'] = $harf }
      elseif($ad -match '^basla' -and -not $kolon['baslangic']){ $kolon['baslangic'] = $harf }
      elseif($ad -match '^bitis' -and -not $kolon['bitis']){ $kolon['bitis'] = $harf }
      elseif($ad -match '^konu' -and -not $kolon['konu']){ $kolon['konu'] = $harf }
      elseif($ad -match '^sehir' -and -not $kolon['sehir']){ $kolon['sehir'] = $harf }
      elseif($ad -match '^ulke' -and -not $kolon['ulke']){ $kolon['ulke'] = $harf }
    }
    # baslangic basligi yine de okunamazsa: bitisin BIR SOLU baslangictir
    # (dizilis olculdu; [string] cast sart - char anahtar hashtable'da tutmaz)
    if(-not $kolon['baslangic'] -and $kolon['bitis'] -and "$($kolon['bitis'])".Length -eq 1){
      $kolon['baslangic'] = [string][char]([int][char]"$($kolon['bitis'])" - 1)
    }
    $fuarlar = @()
    foreach($row in ($rows | Select-Object -Skip ($baslikIndeks + 1))){
      $h = @{}
      foreach($c in @($row.c)){ $h[(KolonHarfi $c.r)] = HucreMetni $c $ss }
      $ad = "$($h[$kolon['ad']])".Trim()
      if(-not $ad){ continue }
      # yurt ici listede ULKE kolonu yok - fuar Turkiye'de
      $ulkeDegeri = if($kolon['ulke']){ "$($h[$kolon['ulke']])".Trim() } else { "" }
      if(-not $ulkeDegeri -and $tur -eq 'yurt-ici'){ $ulkeDegeri = 'TÜRKİYE' }
      $fuarlar += [ordered]@{
        fuar = $ad
        tur = $tur
        baslangic = (SeriTarih "$($h[$kolon['baslangic']])")
        bitis = (SeriTarih "$($h[$kolon['bitis']])")
        konu = "$($h[$kolon['konu']])".Trim()
        sehir = "$($h[$kolon['sehir']])".Trim()
        ulke = $ulkeDegeri
      }
    }
    return $fuarlar
  } finally { $zip.Dispose() }
}

# --- 1) liste sayfalarini KESFET (yurt disi + yurt ici, EN GUNCEL YIL) -------
# 19.08 capraz kontrol: /ihracat/fuarlar sayfasinda DORT aday var; eskisi ilk
# eslesmeyi aliyordu ve sayfada 2003-2024 GECMIS listesi de duruyor (sansa dogru
# sayfaya dusuyorduk). Artik tum adaylar toplanir, tur (yurtdisi/yurt-ici) ve
# URL'deki EN BUYUK YIL'a gore her tur icin en guncel sayfa secilir; 2027 listesi
# yayimlaninca kendiliginden gecer.
Write-Host "Fuar listesi sayfalari kesfediliyor..."
$anaDosya = Join-Path ([IO.Path]::GetTempPath()) "tb-fuarlar-ana.html"
& $curlKomut -sSL -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $anaDosya "https://ticaret.gov.tr/ihracat/fuarlar"
$anaHtml = if(Test-Path $anaDosya){ Get-Content $anaDosya -Raw -Encoding UTF8 } else { "" }

$adaylar = @()
foreach($m in [regex]::Matches($anaHtml, 'href="([^"]*destek-kapsamina-alinan[^"]*)"')){
  $yol = $m.Groups[1].Value
  $tip = if($yol -match 'yurt-ici|yurtici'){ 'yurt-ici' } else { 'yurtdisi' }
  # URL'deki en buyuk yil = listenin guncelligi (2003-2024 vs 2025-2026 vs 2026)
  $enBuyukYil = 0
  foreach($y in [regex]::Matches($yol, '(20\d{2})')){ $sayi = [int]$y.Groups[1].Value; if($sayi -gt $enBuyukYil){ $enBuyukYil = $sayi } }
  $adaylar += [pscustomobject]@{ yol=$yol; tip=$tip; yil=$enBuyukYil }
}
$listeSayfalari = @()
foreach($tip in @('yurtdisi','yurt-ici')){
  $sec = @($adaylar | Where-Object { $_.tip -eq $tip } | Sort-Object yil -Descending | Select-Object -First 1)
  if($sec.Count){ $listeSayfalari += $sec[0] }
}
if(-not $listeSayfalari.Count){
  # ana sayfa yapisi degistiyse bilinen adres denenir (yedek)
  $listeSayfalari += [pscustomobject]@{ yol="https://ticaret.gov.tr/ihracat/fuarlar/2025-2026-yillarinda-destek-kapsamina-alinan-yurtdisi-fuarlar"; tip='yurtdisi'; yil=2026 }
  Write-Host "  kesif linki bulunamadi, bilinen adres denenecek"
}
foreach($s in $listeSayfalari){
  if($s.yol -notmatch '^https?://'){ $s.yol = "https://ticaret.gov.tr" + $s.yol }
  Write-Host ("  liste sayfasi [{0}, {1}]: {2}" -f $s.tip, $s.yil, $s.yol)
}

$xlsxler = @()
$sayac = 0
foreach($s in $listeSayfalari){
  $sayac++
  $listeDosya = Join-Path ([IO.Path]::GetTempPath()) ("tb-fuarlar-liste-$sayac.html")
  & $curlKomut -sSL -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $listeDosya $s.yol
  $listeHtml = if(Test-Path $listeDosya){ Get-Content $listeDosya -Raw -Encoding UTF8 } else { "" }
  foreach($x in ([regex]::Matches($listeHtml, 'href="(https?://[^"]*\.xlsx)"') | ForEach-Object { $_.Groups[1].Value })){
    # yurt disi: milli/bireysel dosyalari; yurt ici: tek "YURT ICI FUAR" dosyasi
    $uygun = if($s.tip -eq 'yurt-ici'){ $x -match '(?i)yurt' } else { $x -match '(?i)(milli|bireysel)' }
    if($uygun){ $xlsxler += [pscustomobject]@{ url=$x; tip=$s.tip } }
  }
}
$xlsxler = @($xlsxler | Sort-Object url -Unique)
Write-Host ("  bulunan xlsx: {0}" -f (@($xlsxler).Count))

# --- 2) xlsx'leri indir + ayristir + pencere suzgeci -------------------------
$tumFuarlar = @()
foreach($xk in $xlsxler){
  # dosya adinda bosluk/Turkce harf olabiliyor (2026 YURT ICI FUAR.xlsx) -> URL encode
  $x = [uri]::EscapeUriString($xk.url)
  $tur = if($xk.tip -eq 'yurt-ici'){ 'yurt-ici' } elseif($x -match '(?i)milli'){ 'milli' } else { 'bireysel' }
  # dosya adinda bosluk/Turkce harf olabiliyor (2026 YURT ICI FUAR.xlsx) -> sabit yerel ad
  $yerel = Join-Path ([IO.Path]::GetTempPath()) ("tb-fuar-" + $tur + "-" + ([Math]::Abs($x.GetHashCode())) + ".xlsx")
  & $curlKomut -sSL -m 90 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $yerel $x
  if(-not (Test-Path $yerel)){ Write-Host "  indirilemedi: $x"; continue }
  try {
    $parti = XlsxFuarlari $yerel $tur
    Write-Host ("  [{0}] {1} satir okundu" -f $tur, @($parti).Count)
    $tumFuarlar += $parti
  } catch {
    $kisa = "$($_.Exception.Message)"; if($kisa.Length -gt 200){ $kisa = $kisa.Substring(0,200) }
    Write-Host ("  ayristirma hatasi ({0}): {1}" -f $tur, $kisa)
  }
}

# basvuru penceresi: bitisi 100 gunden eski fuar listeden duser
$acikFuarlar = @($tumFuarlar | Where-Object {
  $_.bitis -and ([datetime]::ParseExact($_.bitis,'yyyy-MM-dd',$null) -ge $pencereSiniri)
})
# mukerrer ayikla (ayni fuar milli+bireysel listede olabilir - ikisi de kalir, tur farkli)
$turSayim = (@($acikFuarlar | Group-Object { $_.tur } | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join " ")
Write-Host ("toplam {0} satir, penceresi acik {1} [{2}]" -f @($tumFuarlar).Count, @($acikFuarlar).Count, $turSayim)

if(-not $acikFuarlar.Count){
  Write-Host "HATA: hic acik-pencereli fuar bulunamadi - dosyaya DOKUNULMADI (yapi degismis olabilir)"
  exit 1
}

$cikti = [ordered]@{
  guncelleme = "Kaynak: Ticaret Bakanligi destek kapsamina alinan yurt disi fuar listeleri (xlsx, robotla). Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = ($listeSayfalari | ForEach-Object { $_.yol }) -join " · "
  kural = "5973 s. Karar destegi; basvuru fuarin BITISINDEN itibaren 3 ay icinde DYS uzerinden (Genelge m.7). Tutar ve oranlar icin resmi listeye bak. Yurt ici prestijli fuar destegi bir takvim yilinda EN FAZLA 2 fuar icindir (liste dosyasinin kendi notu)."
  fuarlar = $acikFuarlar
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("FUAR DESTEK: {0} fuar yazildi -> veri/fuar-destek.json [geri okuma: {1}]" -f @($acikFuarlar).Count, @($geriOkuma.fuarlar).Count)
if(@($geriOkuma.fuarlar).Count -ne @($acikFuarlar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
