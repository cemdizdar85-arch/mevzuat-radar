# ============================================================================
#  ALACAK DAMGA OLCUMU - SALT OKUMA  (29.08.2026)
#
#  NEDEN VAR: 2026-08-29-alacak-ret-iflas-metinden.sql goçünün BOYUTUNU basmadan
#  once bilmek gerekiyordu. Supabase SQL editorune erisimim yok - ama ayni olcum
#  service_role ile kasadan yapilabilir. Cem hakli olarak sordu: "iki sayim
#  sorgusunu sen kosamiyor musun?" Kosabiliyorum; SQL editoru degil, PostgREST.
#
#  BU BETIK HICBIR SEY DEGISTIRMEZ. Yalniz okur ve iki sayiyi verir:
#    A) karar_durumu='ret_iflas'   ama METINDE iflas karari YOK  -> cikacak
#    B) karar_durumu='ret_kaldirma' ama METINDE iflas karari VAR -> girecek
#  Ayrica her iki kumeden ORNEK basliklar + karar cumlesi basar ki gozle
#  bakilabilsin (damga degistiren her isin on sarti - 29.08 kurali).
#
#  TURKCE HARF TUZAGI: PowerShell/.NET regex'te /i bayragi I<->i eslemez ve
#  dosya kodlamasi bozulursa desen sessizce kayar. Bu yuzden metin ONCE saf
#  ASCII'ye indirgenir (Sadelestir), desenler de ASCII yazilir. Boylece
#  "IFLASINA" / "iflasina" / "Iflasina" hepsi ayni deseni tutturur.
#
#  Env: SUPABASE_SERVICE_KEY (sart)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

$URL = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'https://bjrleanjpyujtajmazxn.supabase.co' }
$KEY = $env:SUPABASE_SERVICE_KEY
if (-not $KEY) { Write-Host "KOR: SUPABASE_SERVICE_KEY yok - olcum YAPILAMADI (sifir sonuc degil)."; exit 0 }

$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')

function Cek([string]$durum) {
  $hepsi = @(); $ofset = 0; $adim = 500
  while ($true) {
    $u = "$URL/rest/v1/alacak_ilan?select=ilan_no,il,baslik,metin,karar_durumu,tarih" +
         "&tarih=gte.$bas&karar_durumu=eq.$durum&metin=not.is.null" +
         "&order=tarih.desc&limit=$adim&offset=$ofset"
    $ham  = Invoke-WebRequest -Method Get -Uri $u -Headers $H -TimeoutSec 120
    $rows = @($ham.Content | ConvertFrom-Json)
    if (-not $rows.Count) { break }
    $hepsi += $rows
    if ($rows.Count -lt $adim) { break }
    $ofset += $adim
  }
  return $hepsi
}

# Turkce -> ASCII (desenler ASCII yazilsin diye)
$MAP = @{ [char]0x0131='i'; [char]0x0130='i'; [char]0x015F='s'; [char]0x015E='s'
          [char]0x011F='g'; [char]0x011E='g'; [char]0x00E7='c'; [char]0x00C7='c'
          [char]0x00F6='o'; [char]0x00D6='o'; [char]0x00FC='u'; [char]0x00DC='u' }
function Sadelestir([string]$s) {
  if (-not $s) { return '' }
  $sb = New-Object Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) {
    if ($MAP.ContainsKey($ch)) { [void]$sb.Append($MAP[$ch]) } else { [void]$sb.Append($ch) }
  }
  return $sb.ToString().ToLowerInvariant()
}

# 29.08 ILK DESEN KIRLI CIKTI - GOZLE BAKINCA YAKALANDI. Eski desen 169 aday
# buluyordu ama orneklerin yarisi TERS anlamliydi:
#   "iflas sartlari olusmadigindan iflas karari VERILMESINE YER OLMADIGINA"
#   "borca batik OLMAMASI nedeniyle iflasina karar VERILMESINE YER OLMADIGINA"
# Yani mahkeme iflas karari VERMEMIS. Eski desen 'verilmesine' kismini yakalayip
# 'yer olmadigina'yi gormuyordu; ayrica '292' tek basina cok genisti
# ("IIK 292 uyarinca iflas sartlari olusmadigindan..." da tutuyordu).
# YENI KURAL: once KESIN kalip aranir, sonra eslesmenin KOMSULUGUNDA olumsuzlama
# var mi diye bakilir. Desen degil, BAGLAM karar verir.
# 29.08 IKINCI TUR - 25 destekli uyusmazlik ELLE okundu, iki eksik cikti:
#  (1) m.177/4 ve COGUL kalip kaciyordu:
#      "IIK'nun 177/4 maddesi uyarinca ayri ayri IFLASLARA, IFLASLARIN
#       07/01/2026 gunu saat 11:35 itibariyle ACILMASINA"
#      Desen 'iflasinin acilmasina' (tekil) ariyordu, 'iflaslarin' yakalanmadi.
#  (2) TASDIK hic olculmuyordu ve en buyuk kusur oradaydi: EN AZ 6 ilanin
#      konkordatosu KABUL EDILMIS ama 'ret_kaldirma' kovasinda duruyor.
#      Baslik "reddine" diyor, karar "KABULUNE" - hicbir kelime kalibi bunu
#      ayiramaz, metni okumak gerekir. Alacakli icin TAM TERS bilgi: firma
#      kurtulmus, biz "reddedildi" diyoruz.
$IFLAS_KARARI = 'itibariyle\s+iflasina|iflasina\s+karar\s+veril(di|mis|mistir|erek)|iflas(inin|larin)\s+acilmasina|177/4'
# TASDIK kalibi: mahkemenin KABUL hukmu. "tasdik talebinin reddine" TUZAKTIR -
# olumsuzlama penceresi onu eler.
# 29.08 KURU KOSU BIR FELAKETI ONLEDI: ilk tasdik deseni 24 GERCEK tasdiki
# kaciriyordu (tasdik -> ret_kaldirma). YAZ=1 kosulsaydi 24 firmanin
# "konkordatosu kabul edildi" bilgisi "reddedildi"ye donecekti - alacakliya
# TAM TERS bilgi. Rapor once metnin BASINI (kunye) basiyordu, elenme sebebi
# gorunmuyordu; anahtar kelimenin gectigi yeri basinca kalip eksigi cikti:
#   "konkordato PROJESININ TASDIKINE, 2- TASDIK EDILEN konkordato projesi..."
#   "tasdik talebinin kismen KABULU ile kismen reddine"   (kabulU, kabulUNE degil)
#   "iflas ici konkordato PROJESININ TASDIKINE"
# DERS: desen yazmak, o desenin NEYI KACIRDIGINI gormeden bitmez. Yakalananlara
# bakmak yetmiyor - KACANLARA da bakilmali.
# 3. KURU KOSU: iki kalip daha kacti.
#   IZMIR "davacilarin KONKORDATOSUNUN iik 306 uyarinca TASDIKINE" -> ek farki
#         ('konkordatoSUNUN'), desen 'konkordato(nun)?' ariyordu. \w* ile cozuldu.
#   ANKARA "konkordato TASDIK KARARINA iliskin surecin bittigi" -> tasdik edilmis
#         bir konkordatonun KAPANIS ilani; tasdik kovasinda kalmali.
$TASDIK_KARARI = 'projesinin\s+tasdikine|tasdik\s+edilen|tasdik(\s+talebinin)?\s+(kismen\s+)?kabul(u|une)|tasdik\s+(sart|kosul)lari(nin)?\s+(tamaminin\s+)?(gerceklestigi|olustugundan)|konkordato\w*\s+(\S+\s+){0,4}?tasdik(ine|inin)|konkordato\s+tasdik\s+(edildiginden|karar)|tasdikine\s+karar\s+veril(di|mis|mistir|mesine)'
# 29.08 TASARIM HATASI DUZELTILDI: tek bir $OLUMSUZ listesi hem iflas hem tasdik
# kalibi icin kullaniliyordu. 'talebinin reddine' TASDIK icin dogru bir
# olumsuzlama ('tasdik talebinin reddine' = tasdik yok) ama IFLAS icin YANLIS:
#   "...15/04/2026 saat 14:37'den itibariyle IFLASINA, [X]'in konkordato
#    TALEBININ REDDINE..."  -> burada iflas VAR, ret baska bir davaciya ait.
# Bir ilanda birden cok davaci olabilir ve her birine ayri hukum kurulur.
# Olumsuzlama artik KALIBA OZEL.
$OLUMSUZ_ORTAK  = 'yer\s+olmadig|olusmadig|gerceklesmedig|gerek\s+olmadig|verilebilec|verilmesini\s+iste|talep\s+edebilec'
$OLUMSUZ_TASDIK = $OLUMSUZ_ORTAK + '|talebinin\s+reddine|kaldirilmasina\s+karar'
$TERS_TUZAK = 'iflasin\s+kaldirilmas'

# Kalip bulunur, komsulugunda olumsuzlama YOKSA gecerli sayilir.
function TemizEslesme([string]$m, [string]$kalip, [string]$olumsuz) {
  foreach ($mm in [regex]::Matches($m, $kalip)) {
    $bas = [Math]::Max(0, $mm.Index - 90)
    $son = [Math]::Min($m.Length, $mm.Index + $mm.Length + 90)
    $pencere = $m.Substring($bas, $son - $bas)
    if ($pencere -notmatch $olumsuz) { return $pencere }
  }
  return $null
}
function IflasKarariVar([string]$metin) {
  $m = Sadelestir $metin
  if ($m -match $TERS_TUZAK) { return $false }
  return [bool](TemizEslesme $m $IFLAS_KARARI $OLUMSUZ_ORTAK)
}
function TasdikVar([string]$metin) {
  return [bool](TemizEslesme (Sadelestir $metin) $TASDIK_KARARI $OLUMSUZ_TASDIK)
}
# HEDEF DURUM - siralama mantiksal: surec BASARIYLA bittiyse tasdik, IFLASLA
# bittiyse ret_iflas, digeri ret_kaldirma. Bir ilan hem tasdik hem iflas olamaz.
function HedefDurum([string]$metin) {
  if (TasdikVar $metin)       { return 'tasdik' }
  if (IflasKarariVar $metin)  { return 'ret_iflas' }
  return 'ret_kaldirma'
}
function KararCumlesi([string]$metin) {
  $m = Sadelestir $metin
  # Yalniz OLUMSUZLANMAMIS eslesmenin cevresini basar - gozle bakan kisi
  # elenmis olani degil, KABUL EDILEN kalibi gormeli.
  foreach ($mm in [regex]::Matches($m, $IFLAS_KARARI)) {
    $bas = [Math]::Max(0, $mm.Index - 90)
    $son = [Math]::Min($m.Length, $mm.Index + $mm.Length + 90)
    $pencere = $m.Substring($bas, $son - $bas)
    if ($pencere -notmatch $OLUMSUZ_ORTAK) { return ($pencere -replace '\s+', ' ') }
  }
  return '-'
}

Write-Host "Kasadan cekiliyor (salt okuma)..."
# 29.08 IKINCI TUR: artik UC KOVA birden yeniden dagitiliyor. Ikili tasima
# (ret_iflas <-> ret_kaldirma) yetmiyordu; en buyuk kusur TASDIK'te cikti ve
# tasdik ucuncu kova. Bir ilanin hedefi METINDEN belirlenir, mevcut damgasindan
# bagimsiz.
$KOVA_ADLARI = @('ret_iflas','ret_kaldirma','tasdik')
$tum = @()
foreach ($k in $KOVA_ADLARI) {
  $c = Cek $k
  Write-Host ("  {0,-14}: {1,4} metinli ilan" -f $k, $c.Count)
  $tum += $c
}
if (-not $tum.Count) { Write-Host "KOR: 0 satir geldi, olcum guvenilmez."; exit 0 }

$degisecek = @()
foreach ($x in $tum) {
  $hedef = HedefDurum $x.metin
  if ($hedef -ne "$($x.karar_durumu)") {
    $degisecek += [pscustomobject]@{
      ilan_no = $x.ilan_no; il = $x.il; baslik = "$($x.baslik)"; metin = "$($x.metin)"
      eski = "$($x.karar_durumu)"; yeni = $hedef
    }
  }
}

Write-Host ''
Write-Host ('=' * 74)
Write-Host ("TARANAN: {0} ilan · DEGISECEK: {1}" -f $tum.Count, $degisecek.Count)
Write-Host ''
Write-Host 'GECIS TIPLERI (eski -> yeni):'
$degisecek | Group-Object { $_.eski + ' -> ' + $_.yeni } | Sort-Object Count -Descending |
  ForEach-Object { Write-Host ("  {0,4}  {1}" -f $_.Count, $_.Name) }
Write-Host ''
Write-Host 'SONRAKI KOVA BUYUKLUKLERI (beklenen):'
foreach ($k in $KOVA_ADLARI) {
  $once  = @($tum | Where-Object { "$($_.karar_durumu)" -eq $k }).Count
  $cikan = @($degisecek | Where-Object { $_.eski -eq $k }).Count
  $giren = @($degisecek | Where-Object { $_.yeni -eq $k }).Count
  Write-Host ("  {0,-14} {1,4} - {2,3} + {3,3} = {4,4}" -f $k, $once, $cikan, $giren, ($once - $cikan + $giren))
}
Write-Host ''
Write-Host 'HER GECIS TIPINDEN 4 ORNEK - GOZLE BAK (kalip mi, gercek mi?):'
$degisecek | Group-Object { $_.eski + ' -> ' + $_.yeni } | Sort-Object Count -Descending | ForEach-Object {
  Write-Host ''
  Write-Host ("--- {0}  ({1} ilan) ---" -f $_.Name, $_.Count)
  $_.Group | Select-Object -First 4 | ForEach-Object {
    Write-Host ("  [{0}] {1}" -f $_.il, $_.baslik.Substring(0, [Math]::Min(56, $_.baslik.Length)))
    $kalip = if ($_.yeni -eq 'tasdik') { $TASDIK_KARARI } elseif ($_.yeni -eq 'ret_iflas') { $IFLAS_KARARI } else { $null }
    if ($kalip) {
      $p = TemizEslesme (Sadelestir $_.metin) $kalip $(if($_.yeni -eq 'tasdik'){$OLUMSUZ_TASDIK}else{$OLUMSUZ_ORTAK})
      Write-Host ("     karar: {0}" -f $(if ($p) { ($p -replace '\s+',' ') } else { '-' }))
    } else {
      # 29.08: hedef ret_kaldirma ise METNIN BASI (kunye) hicbir sey anlatmiyor -
      # asil soru "eski damganin kalibi neden tutmadi". Eski kovanin anahtar
      # kelimesinin GECTIGI yeri basiyoruz ki desen eksigi gorulebilsin.
      $anahtar = switch ($_.eski) { 'tasdik' { 'tasdik' } 'ret_iflas' { 'iflas' } default { $null } }
      $sm = (Sadelestir $_.metin)
      $yer = if ($anahtar) { [regex]::Match($sm, '.{0,60}' + $anahtar + '.{0,110}') } else { $null }
      if ($yer -and $yer.Success) {
        Write-Host ("     '{0}' gectigi yer: {1}" -f $anahtar, ($yer.Value -replace '\s+',' '))
      } else {
        $ilk = ($sm -replace '\s+',' ')
        Write-Host ("     metin: {0}" -f $ilk.Substring(0, [Math]::Min(130, $ilk.Length)))
      }
    }
  }
}

# ============================================================================
#  YAZMA MODU  (YAZ=1)  - varsayilan KAPALI
#  Ayri bir "onarim betigi" YAZILMADI bilerek: desen mantigi TEK YERDE dursun.
#  Iki dosyada ayni regex'i tasimak, birini duzeltip digerini unutmak demektir -
#  bugun tam bunu SQL goçünde yasadik (169 vs 46).
#  Geri alinabilir: degistirilen her satirin ESKI damgasi once yedege yazilir.
# ============================================================================
if ($env:YAZ -ne '1') {
  Write-Host ''
  Write-Host 'KURU KOSU: hicbir sey degistirilmedi. Gercek onarim icin YAZ=1 ile kos.'
  exit 0
}

Write-Host ''
Write-Host ('=' * 74)
Write-Host 'YAZMA MODU ACIK - damgalar guncellenecek.'

# $degisecek yukarida UC KOVA uzerinden hesaplandi (metinden hedef durum).
if (-not $degisecek.Count) { Write-Host 'Degisecek kayit yok.'; exit 0 }

# 1) YEDEK ONCE (geri donus yolu acik olmadan yazma yapilmaz)
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$yedekYol = Join-Path $kok 'veri\alacak-damga-yedek.json'
$yedek = [ordered]@{
  olcum   = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama= 'Damga onarimindan ONCEKI degerler. Geri almak icin her ilan_no eski degerine set edilir.'
  adet    = $degisecek.Count
  kayitlar= $degisecek
}
[IO.File]::WriteAllText($yedekYol, ($yedek | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
Write-Host ("Yedek yazildi: {0} kayit -> {1}" -f $degisecek.Count, $yedekYol)

# 2) PATCH - gruplar halinde (URL uzunluk sinirina takilmamak icin)
$PH = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'Content-Type' = 'application/json'; Prefer = 'return=minimal' }
$yazilan = 0; $hata = 0
foreach ($hedefDurum in $KOVA_ADLARI) {
  $liste = @($degisecek | Where-Object { $_.yeni -eq $hedefDurum } | ForEach-Object { $_.ilan_no })
  for ($i = 0; $i -lt $liste.Count; $i += 20) {
    $parca = $liste[$i..([Math]::Min($i + 19, $liste.Count - 1))]
    $inList = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
    $u = "$URL/rest/v1/alacak_ilan?ilan_no=in.($inList)"
    $govde = @{ karar_durumu = $hedefDurum } | ConvertTo-Json -Compress
    try {
      Invoke-RestMethod -Method Patch -Uri $u -Headers $PH -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 90 | Out-Null
      $yazilan += $parca.Count
    } catch {
      $hata += $parca.Count
      Write-Host ("  PATCH hatasi ({0}, {1} kayit): {2}" -f $hedefDurum, $parca.Count, $_.Exception.Message)
    }
    Start-Sleep -Milliseconds 200
  }
}
Write-Host ("Yazilan: {0} · hata: {1}" -f $yazilan, $hata)

# 3) YAZ -> GERI OKU -> KARSILASTIR  (yukleyici-sessiz-kayip dersi)
Write-Host ''
Write-Host 'GERI OKUMA...'
$kirmizi = $false
$yeniToplam = 0
foreach ($k in $KOVA_ADLARI) {
  $y      = Cek $k
  $once   = @($tum | Where-Object { "$($_.karar_durumu)" -eq $k }).Count
  $cikan  = @($degisecek | Where-Object { $_.eski -eq $k }).Count
  $giren  = @($degisecek | Where-Object { $_.yeni -eq $k }).Count
  $bekl   = $once - $cikan + $giren
  $yeniToplam += $y.Count
  $isaret = if ($y.Count -eq $bekl) { 'OK' } else { 'TUTMADI'; }
  if ($y.Count -ne $bekl) { $kirmizi = $true }
  Write-Host ("  {0,-14} {1,4}  (beklenen {2,4})  {3}" -f $k, $y.Count, $bekl, $isaret)
  # Kova ICI temizlik: hedefi kendisi olmayan kayit kalmamali
  $kalanKirli = @($y | Where-Object { (HedefDurum $_.metin) -ne $k }).Count
  Write-Host ("     icinde hedefi baska olan: {0} (0 olmali)" -f $kalanKirli)
  if ($kalanKirli -ne 0) { $kirmizi = $true }
}
Write-Host ("  TOPLAM         {0,4}  (once {1,4})  <- KORUNMALI" -f $yeniToplam, $tum.Count)
if ($yeniToplam -ne $tum.Count) { $kirmizi = $true }
if ($kirmizi) {
  Write-Host 'KIRMIZI: geri okuma beklenenle TUTMADI. Yedek: veri/alacak-damga-yedek.json'
  exit 1
}
Write-Host 'YESIL: damga onarildi, sayilar tutuyor.'
