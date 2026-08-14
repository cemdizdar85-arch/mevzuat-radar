# ============================================================================
#  KAMU IHALE BULTENI - ILAN METNI AYRISTIRICI (14.08.2026)
#
#  Cem: "EKAP çeksek... kimler katılabilir, başlangıç bedeli, ne istiyorlar,
#        hap olarak görsünler. EN İYİSİ OLMALIYIZ."
#
#  EKAP'IN ARAMA API'SI KORUMALI (401 - "İstek doğrulanamadı"); o kapiyi
#  zorlamiyoruz. Ama ARADIGIMIZ HER SEY zaten Kamu Ihale Bulteni'nde var ve
#  bulteni KIK indirilmek uzere yayimliyor (4734 m.13). Bulten ilan metni
#  STANDART yapida: 3.2'de MIKTAR, 4.x'te YETERLIK, 11'de TEMINAT orani.
#
#  CIKARILAN ALANLAR (hepsi ilan metninde YAZAN seyler - uydurma yok):
#    ikn, isAdi, idare, ihaleTarih, miktar, teslimYer, sure,
#    teminatOran, isDeneyimiOran, yerliMali, sinirDegerN, usulMadde,
#    ekonomikYeterlik, teknikYeterlik, benzerIs
#
#  + YAKLASIK MALIYET TAVANI (cikarim, kaynakli):
#    4734 m.13 ilan suresini yaklasik maliyet dilimine baglar; 2026/1 sayili
#    Kamu Ihale Tebligi guncel tutarlari verir. Sureler "EN AZ" oldugu icin
#    cikarilabilen sey TAVANDIR (kisa sure buyuk maliyeti disar), TABAN degil.
#    24 gun ve ustunde kisaltma hukumleri devreye girdigi icin OLCULEMEDI denir.
#    Gerekcenin tamami MaliyetTavan() icinde, ambar atiflariyla yazili.
#
#  OLCUM betigi - -Yaz verilmedikce dosya yazmaz.
# ============================================================================
param([switch]$Yaz, [switch]$YerelMetin, [int]$Ornek = 0)
$ErrorActionPreference = "Continue"
if($PSVersionTable.PSVersion.Major -lt 6){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kls  = Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten"

# --- 2026/1 tebligi tutarlari (AMBARDAN okunarak yazildi, hafizadan degil) ---
#   m.13/b(1) mal-hizmet ust : 2.043.844   · yapim ust :  4.087.898
#   m.13/b(2) mal-hizmet ust : 4.087.898   · yapim ust : 34.067.732
#   m.8 esik  genel butce    : 18.734.124  · diger     : 31.223.628 · yapim: 686.924.429
$ESIK = @{
  malHizmet1 = 2043844; malHizmet2 = 4087898
  yapim1     = 4087898; yapim2     = 34067732
  esikGenel  = 18734124; esikDiger = 31223628; esikYapim = 686924429
}
function MaliyetTavan([int]$gun, [string]$tur){
  # ==== ILK KURDUGUM MANTIK TERSTI - AMBARDAN OKUYUNCA DUZELTILDI ============
  # Once "uzun ilan suresi -> yuksek maliyet ALT siniri" diye kurmustum. 4734
  # m.13 ambardan birebir okununca yanlis oldugu gorüldü: sureler "EN AZ"dir,
  # idare istedigi kadar UZUN ilan verebilir ("yeterli süre tanımak suretiyle").
  # Yani uzun sure yuksek maliyeti KANITLAMAZ.
  # Tersi ise kesindir: idare yasal asgari sureyi ihlal edemeyecegine gore,
  # KISA sure yuksek maliyeti DISLAR. Cikarilabilen sey TAVANDIR, taban degil.
  #
  # m.13 birebir gun sinirlari (ambar: kik.json m.13 [1/4] ve [2/4]):
  #   b-1: en az  7 gun · b-2: en az 14 gun · b-3: en az 21 gun · a-1: en az 40 gun
  # 2026/1 tebligi tutarlari (ambar: kik-esik-teblig.json m.3):
  #   b-1 ust: 2.043.844 mal/hizmet · 4.087.898 yapim
  #   b-2 ust: 4.087.898 mal/hizmet · 34.067.732 yapim
  #   b-3 ust: esik deger (m.8: 18.734.124 / 31.223.628 / 686.924.429)
  #
  # 24 GUN VE USTU'NDE CIKARIM YAPILMAZ: a-1'in 40 gunluk suresi elektronik
  # hazirlamayla 7, EKAP erisimiyle 5, on ilanla 24 gune kadar kisaltilabiliyor
  # (m.13 dorduncu/besinci fikra). Bu yuzden 24+ gun hem esik ustu hem de comert
  # ilan verilmis kucuk bir alim olabilir - ayirt edilemez, "OLCULEMEDI" denir.
  $yapimMi = ($tur -match 'yapım|yapim')
  # esik deger idarenin butce statusune bagli (m.8/a-b); ilanda yazmadigi icin
  # TAVAN olarak YUKSEK olani alinir - tavani asagi cekip yaniltmamak icin.
  if($gun -ge 24){ return $null }
  if($gun -ge 21){ return @{ tavan = $(if($yapimMi){$ESIK.esikYapim}else{$ESIK.esikDiger}); dayanak='m.13/b-3'; sure=21 } }
  if($gun -ge 14){ return @{ tavan = $(if($yapimMi){$ESIK.yapim2}else{$ESIK.malHizmet2}); dayanak='m.13/b-2'; sure=14 } }
  if($gun -ge 7) { return @{ tavan = $(if($yapimMi){$ESIK.yapim1}else{$ESIK.malHizmet1}); dayanak='m.13/b-1'; sure=7 } }
  return $null
}

# --- bulten metnini al ------------------------------------------------------
function BultenMetni([string]$tur){
  $txt = Join-Path $kls "bulten-$($tur.ToLower()).txt"
  if(Test-Path $txt){ return [IO.File]::ReadAllText($txt,[Text.Encoding]::UTF8) }
  Write-Host ("   {0}: yerel metin yok - once motor/ihale-bulten-hasat.ps1 kosulmali" -f $tur)
  return $null
}
function Alan([string]$blok, [string]$desen){
  $m = [regex]::Match($blok, $desen)
  if($m.Success){ return ($m.Groups[1].Value -replace '\s+',' ').Trim() }
  return ""
}
# CEM 14.08 (ekran goruntusu): "burda EKAP yonlendiriyor urun ile ilgili bilgileri"
# 3.2 alaninin sonunda ilanlarin buyuk cogunlugunda su kalip var:
#   "Ayrıntılı bilgiye EKAP'ta yer alan ihale dokümanı içinde bulunan idari
#    şartnameden ulaşılabilir."
# Bu cumle URUN BILGISI DEGIL, yonlendirmedir. Miktar alaninda birakilirsa kart
# doluymus gibi gorunur ama Cem'in sordugu ("kac tane, hangi ozellikte") cevapsiz
# kalir. Ayiklanir; kartta ayri bir "ayrinti nerede" satirina cevrilir.
function Boilerplate([string]$s){
  if(-not $s){ return "" }
  $t = $s -replace 'Ayrıntılı bilgi(y|si)?e?\s+EKAP.{0,120}?(ulaşılabilir|ulasilabilir)\.?',''
  $t = $t -replace '\s+',' '
  return $t.Trim(' ', '.', ',', '-', ':')
}
function IlanlariCoz([string]$metin, [string]$tur){
  # ilan bolumu: "2. İHALE İLANLARI" ile "3. İHALE DÜZELTME İLANLARI" arasi
  #
  # SESSIZ KAYIP TUZAGI (14.08 olculdu): burada "20000. karakterden sonra ara"
  # yaziyordu; amac icindekiler tablosunu atlamakti. Ama bulten boyutu gune gore
  # degisiyor - 14.08 hizmet bulteni 460 KB'a dustu, icindekiler kisaldi ve
  # govde basligi 20000'in ALTINDA kaldi. IndexOf -1 donunce fonksiyon bos dizi
  # verdi ve 77 hizmet ilani SESSIZCE sifirlandi. Havuz birikimli oldugu icin
  # dosyada eski kayitlar duruyordu, yani kimse fark etmezdi.
  # DOGRUSU sabit ofset degil, YAPISAL olcut: ilk "İhale Kayıt Numarası"ndan
  # ONCEKI son bolum basligi. Icindekilerde IKN gecmez, govdede gecer.
  $ilkIkn = $metin.IndexOf("İhale Kayıt Numarası")
  $b = -1
  foreach($m in [regex]::Matches($metin, '2\.\s*İHALE İLANLARI')){
    if($ilkIkn -lt 0 -or $m.Index -lt $ilkIkn){ $b = $m.Index } else { break }
  }
  if($b -lt 0){ return @() }
  $s = $metin.IndexOf("3. İHALE DÜZELTME İLANLARI", $b + 100)
  if($s -lt 0){ $s = $metin.Length }
  $bolum = $metin.Substring($b, $s - $b)
  $duz = $bolum -replace '\s+',' '
  # TUZAK (kartta gorundu): PDF sayfa altbilgisi ilan metninin ORTASINA giriyor
  # ("...Benzer İş Olarak Kabul Edilecektir. Kamu İhale Kurumu - www.kik.gov.tr 19
  #  KAMU İHALE BÜLTENİ 13 AĞUSTOS 2026 - Sayı 5676 MAL ALIMI İHALELERİ BÜLTENİ").
  # Tek tek alanlarda temizlemek yerine KAYNAKTA silinir - yoksa hem karta sizar
  # hem araya girdigi yerde desenleri bozar.
  # OLCULDU: altbilginin parcalari PDF metnine AYRI AYRI dusuyor - tek kalip
  # yetmiyor (87 kayitta "MAL ALIMI İHALELERİ BÜLTENİ" tek basina sizmisti).
  # Dordu de ayri silinir. Hicbiri gercek ilan metninde gecmez, guvenli.
  foreach($kalip in @(
    'Kamu İhale Kurumu\s*[–—-]\s*www\.kik\.gov\.tr\s*\d{0,4}',
    'KAMU İHALE BÜLTENİ',
    '\d{1,2}\s+(?:OCAK|ŞUBAT|MART|NİSAN|MAYIS|HAZİRAN|TEMMUZ|AĞUSTOS|EYLÜL|EKİM|KASIM|ARALIK)\s+\d{4}\s*[–—-]\s*Sayı\s*\d+',
    '(?:MAL ALIMI|YAPIM İŞLERİ|HİZMET ALIMI|DANIŞMANLIK HİZMET ALIMI)\s+İHALELERİ BÜLTENİ'
  )){ $duz = $duz -replace $kalip, ' ' }
  $duz = $duz -replace '\s+',' '
  # her ilan "İhale Kayıt Numarası (İKN) : yyyy/nnnn" ile baslar
  $bas = [regex]::Matches($duz, 'İhale Kayıt Numarası \(İKN\)\s*:\s*(\d{4}/\d+)')
  $sonuc = @()
  for($i=0; $i -lt $bas.Count; $i++){
    # TUZAK (olculdu): usul cumlesi ("4734 ... 19 uncu maddesine göre açık ihale
    # usulü") ve ilan basligi IKN satirindan ONCE geciyor -> usulMadde %1 doluluk.
    # ILK COZUM YANLISTI: blogu 500 karakter geriden baslatip 500 erken bitirmek,
    # ilanin KUYRUGUNU bir sonraki bloga kaydiriyordu (sinirN %35 -> %24 dustu ve
    # onceki ilanin degeri sonrakine yazilma riski dogdu). Dogrusu: blok IKN'den
    # IKN'ye bolunur (kayipsiz), oncesi AYRI bir "onek" olarak okunur.
    $bit = if($i+1 -lt $bas.Count){ $bas[$i+1].Index } else { $duz.Length }
    $bl  = $duz.Substring($bas[$i].Index, $bit - $bas[$i].Index)
    $oBas = [math]::Max(0, $bas[$i].Index - 500)
    if($i -gt 0){ $oBas = [math]::Max($oBas, $bas[$i-1].Index) }
    $onek = $duz.Substring($oBas, $bas[$i].Index - $oBas)
    $ikn = $bas[$i].Groups[1].Value
    $ihTarih = Alan $bl '2\.1\.\s*Tarih ve Saati\s*:\s*([\d.]+\s*-\s*[\d:]+)'
    $usulMd  = Alan $onek '(\d+)\s*[iıuü]nc[iıuü] maddesine göre'
    $usulAd  = Alan $onek 'maddesine göre\s+(.{3,60}?)\s+(?:usul[üu] ile|ile)\s+ihale'
    # ilan basligi: onekte, IKN'nin hemen oncesindeki BUYUK HARFLI cumle
    $basIlan = Alan $onek '\d{4}/\d+\s+([A-ZÇĞİÖŞÜ0-9][A-ZÇĞİÖŞÜ0-9 ,./()\-]{12,110}?)\s+[A-ZÇĞİÖŞÜ]?[a-zçğıöşü]'
    $rec = [ordered]@{
      ikn        = $ikn
      tur        = $tur
      isAdi      = $($a = (Alan $bl '3\.1\.?\s*Adı\s*:\s*(.{3,200}?)\s*3\.2'); if($a){$a}else{$basIlan})
      usulAdi    = $usulAd
      idare      = (Alan $bl '1\.1\.?\s*Adı\s*:\s*(.{3,200}?)\s*1\.2')
      ihaleTarih = $ihTarih
      # ---- CEM'IN SORDUGU: "kac tane, hangi ozellikte" ----
      miktar     = (Boilerplate (Alan $bl '3\.2\.?\s*Niteliği, türü ve miktarı\s*:\s*(.{3,700}?)\s*3\.3'))
      # urun ayrintisi ilanda mi, yoksa EKAP dokumaninda mi? (Cem'in sordugu)
      ayrintiNerede = $(if($bl -match 'Ayrıntılı bilgi.{0,40}EKAP'){'İhale dokümanı (EKAP)'}else{''})
      # OLCULDU (13.08 bulteni, 92 ilan): ilanlarda dokuman bedeli/ucretsizlik
      # cumlesi GECMIYOR; gecen tek cumle "EKAP hesabına giriş yaparak ihale
      # dokümanını indirmeleri zorunludur". Onu yaziyoruz, fazlasini uydurmuyoruz.
      dokumanErisim = $(if($bl -match 'EKAP hesabına giriş yaparak ihale dokümanını indirmeleri zorunludur'){'EKAP hesabıyla indirilir (zorunlu)'}elseif($bl -match 'e-imza kullanarak EKAP üzerinden ücretsiz'){'EKAP üzerinden ücretsiz (e-imza gerekli)'}else{''})
      teslimYer  = (Boilerplate (Alan $bl '3\.3\.?\s*Yapılacağı/teslim edileceği yer\s*:\s*(.{3,300}?)\s*3\.4'))
      sure       = (Alan $bl '3\.4\.?\s*Süresi/teslim tarihi\s*:\s*(.{3,700}?)\s*(?:3\.5|4\s*[-–.]|4\.1)')
      # ---- CEM'IN SORDUGU: "kimler katilabilir, ne istiyorlar" ----
      # TUZAK (olculdu): gercek baslik "4.2. Ekonomik ve mali yeterliğe ilişkin bilgi
      # ve belgeler ile bunların taşıması gereken kriterler:" = 90 karakterden UZUN,
      # eski [^:]{0,90} hicbir ilanda tutmadi (%0 doluluk). Sinir 160'a cikarildi.
      ekonomik   = (Alan $bl '4\.2\.[^:]{0,160}:\s*(.{3,220}?)\s*4\.3\.')
      # TUZAK (olculdu): yapim ilanlarinda 4.3 govdesi (is deneyimi anlatisi +
      # 4.3.1.1 tuzel kisi fikrasi) 260 karakteri cok asiyor; bitis isareti
      # pencereye girmedigi icin 85/92 yapim ilaninda hic tutmuyordu. Pencere 900,
      # bitis "5 - Ekonomik acidan..." bolum basligina daraltildi (metin icindeki
      # "5." rakamlarina takilmasin diye).
      teknik     = (Alan $bl '4\.3\.[^:]{0,160}:\s*(.{3,1700}?)\s*(?:4\.4\.|5\s*[-–.]\s*Ekonomik|Ekonomik açıdan en avantajlı)')
      # TUZAK (kartta gorundu): gercek metin "...işler: 4.4.1. Kamu veya Özel
      # Sektöre Yapılan ... 5- Ekonomik açıdan...". Eski desenin bitisi "4\." idi,
      # lazy eslesme hemen "4.4.1"in ilk "4."inde duruyor ve karta "Benzer iş: 4."
      # diye BOZUK deger basiyordu. Onek atlanir, bitis "5- Ekonomik"e baglanir.
      benzerIs   = (Alan $bl 'benzer iş olarak kabul edilecek işler:\s*(?:4\.4\.1\.?\s*)?(.{5,300}?)\s*(?:5\s*[-–.]\s*Ekonomik|Ekonomik açıdan en avantajlı)')
      isDeneyimi = (Alan $bl 'teklif edilen bedelin\s*%\s*(\d+)\s*oranından az olmamak')
      teminat    = (Alan $bl 'teklif ettikleri bedelin\s*%\s*(\d+)')
      yerliMali  = $(if($bl -match 'sadece yerli istekliler katılabilecektir'){'Yalnız yerli istekliler'}elseif($bl -match 'yerli malı teklif eden.{0,60}fiyat avantajı'){'Yerli malına fiyat avantajı var'}elseif($bl -match 'yerli ve yabancı tüm isteklilere açıktır'){'Yerli ve yabancı herkese açık'}else{''})
      # OLCULDU: ayni bultende ayni alan "1" (54), "1,20" (11), "1,2" (11),
      # "1,00" (9), "1,0" (7) diye yaziliyor. Bunlar AYNI sayinin farkli
      # yazimlari - PDF kaybi degil (ayni bultende 1,20 dogru cikiyor).
      # Yalniz BICIM birlestirilir, deger degistirilmez.
      sinirN     = $(
        $sd = (Alan $bl 'Sınır Değer Katsayısı \((?:N|R)\)\s*:\s*(?:[^:0-9]{0,40}/)?\s*([\d,]+)')
        if($sd){ $d = 0.0; if([double]::TryParse(($sd -replace ',','.'), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){ $d.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture) -replace '\.', ',' } else { $sd } } else { '' })
      usulMadde  = $usulMd
      gecerlilik = (Alan $bl 'geçerlilik süresi, ihale tarihinden itibaren\s*(\d+)')
    }
    $sonuc += $rec
  }
  return $sonuc
}

$AYLAR = @{ 'OCAK'=1;'ŞUBAT'=2;'MART'=3;'NİSAN'=4;'MAYIS'=5;'HAZİRAN'=6;'TEMMUZ'=7;'AĞUSTOS'=8;'EYLÜL'=9;'EKİM'=10;'KASIM'=11;'ARALIK'=12 }
function BultenTarihi([string]$metin){
  # bulten ilk satiri: "13 AĞUSTOS 2026 – Sayı 5676"
  $m = [regex]::Match($metin.Substring(0,[math]::Min(300,$metin.Length)), '(\d{1,2})\s+([A-ZÇĞİÖŞÜ]+)\s+(\d{4}).{0,20}?Sayı\s*(\d+)')
  if(-not $m.Success){ return $null }
  $ay = $AYLAR["$($m.Groups[2].Value)"]
  if(-not $ay){ return $null }
  return @{ tarih = (Get-Date -Year ([int]$m.Groups[3].Value) -Month $ay -Day ([int]$m.Groups[1].Value) -Hour 0 -Minute 0 -Second 0); sayi = $m.Groups[4].Value }
}

$hepsi = @()
$bultenBilgi = $null
$bosTur = @()
foreach($t in @('Mal','Yapim','Hizmet')){
  $m = BultenMetni $t
  if(-not $m){ continue }
  if(-not $bultenBilgi){ $bultenBilgi = BultenTarihi $m }
  $c = @(IlanlariCoz $m $t)
  Write-Host ("{0,-8}: {1} ilan ayristirildi" -f $t, $c.Count)
  # SIGORTA: metin geldigi halde hic ilan cikmadiysa bu bir AYRISTIRICI kusurudur
  # (14.08'de tam bu oldu: hizmet bulteni 460 KB indi ama sabit ofset yuzunden
  # bolum bulunamadi, 77 ilan sessizce sifirlandi). Sessiz gecilmez.
  if($m.Length -gt 50000 -and $c.Count -eq 0){
    Write-Host ("   !! UYARI: {0} bulteni {1:N0} karakter geldi ama HIC ilan cikmadi - ayristirici kusuru olabilir" -f $t, $m.Length)
    $script:bosTur += $t
  }
  $hepsi += $c
}
if(-not $hepsi.Count){
  # SIGORTA: sessiz basarisizlik yasagi. Daha once bulten adimi "alinamadi,
  # atlandi" deyip exit 0 dondugu icin Actions YESIL gorunmus, kirmizi-nobetci
  # maili hic atesLENMEMISTI. -Yaz modunda veri yoksa kosu DUSER.
  Write-Host "Hic ilan cikmadi (bulten metni yok ya da yapisi degisti)."
  if($Yaz){ exit 1 }
  return
}

# --- YAKLASIK MALIYET TAVANI (4734 m.13 + 2026/1 tebligi) -------------------
#  Yaklasik maliyet ilanda ACIKLANMAZ. Cikarilabilen tek sey TAVAN: idare yasal
#  asgari ilan suresini ihlal edemeyecegine gore, kisa ilan suresi buyuk
#  maliyeti disar. Gerekce ve gun sinirlari MaliyetTavan() icinde yazili.
#  HATA YONU (bilerek guvenli tarafta): ilan daha once de yayimlandiysa gercek
#  ilk ilan tarihi daha eskidir -> gercek gun farki daha BUYUK -> gercek tavan
#  daha YUKSEK olur. Yani buradaki tavan gercekten dusuk cikabilir; bu yuzden
#  kartta "en fazla" degil "bu ilana gore en fazla" diye yazilir.
$hesaplanan = 0; $olculemedi = 0
if($bultenBilgi){
  Write-Host ("`nBulten: {0} · Sayi {1}" -f $bultenBilgi.tarih.ToString('dd.MM.yyyy'), $bultenBilgi.sayi)
  foreach($x in $hepsi){
    $x['ilanTarih'] = $bultenBilgi.tarih.ToString('dd.MM.yyyy')
    $x['bultenSayi'] = $bultenBilgi.sayi
    $x['maliyetTavan'] = $null; $x['maliyetDayanak'] = ''; $x['maliyetGun'] = $null
    $md = [regex]::Match("$($x.ihaleTarih)", '^(\d{2})\.(\d{2})\.(\d{4})')
    if(-not $md.Success){ $olculemedi++; continue }
    try { $ih = Get-Date -Year ([int]$md.Groups[3].Value) -Month ([int]$md.Groups[2].Value) -Day ([int]$md.Groups[1].Value) -Hour 0 -Minute 0 -Second 0 } catch { $olculemedi++; continue }
    $gun = [int]($ih - $bultenBilgi.tarih).TotalDays
    if($gun -lt 0 -or $gun -gt 200){ $olculemedi++; continue }
    $x['maliyetGun'] = $gun
    $s = MaliyetTavan $gun $x.tur
    if($s){ $x['maliyetTavan'] = $s.tavan; $x['maliyetDayanak'] = $s.dayanak; $hesaplanan++ } else { $olculemedi++ }
  }
  Write-Host ("Maliyet TAVANI cikarilan: {0}/{1} · olculemedi (24+ gun / tarihsiz): {2}" -f $hesaplanan, $hepsi.Count, $olculemedi)
} else {
  Write-Host "`nUYARI: bulten tarihi okunamadi - maliyet tavani OLCULEMEDI (uydurulmadi)."
}

# --- doluluk olcumu ---------------------------------------------------------
Write-Host ("`n=== ALAN DOLULUK ({0} ilan) ===" -f $hepsi.Count)
foreach($a in @('isAdi','usulAdi','idare','ihaleTarih','miktar','teslimYer','sure','ekonomik','teknik','benzerIs','isDeneyimi','teminat','yerliMali','sinirN','usulMadde','gecerlilik')){
  $n = @($hepsi | Where-Object { "$($_.$a)".Trim() }).Count
  $y = [math]::Round(100.0*$n/$hepsi.Count)
  Write-Host ("  {0,-12} {1,3}/{2}  %{3}" -f $a, $n, $hepsi.Count, $y)
}

# --- tur bazli doluluk (kacirma mi, gercek yokluk mu ayirmak icin) ----------
Write-Host "`n=== TUR BAZLI DOLULUK ==="
$alanlar = @('isAdi','miktar','teslimYer','sure','ekonomik','teknik','benzerIs','isDeneyimi','teminat','yerliMali','sinirN')
Write-Host ("{0,-12} {1,8} {2,8} {3,8}" -f 'ALAN','Mal','Yapim','Hizmet')
foreach($a in $alanlar){
  $satir = "{0,-12}" -f $a
  foreach($t in @('Mal','Yapim','Hizmet')){
    $grup = @($hepsi | Where-Object { $_.tur -eq $t })
    $n = @($grup | Where-Object { "$($_.$a)".Trim() }).Count
    $satir += ("{0,8}" -f ("%{0}" -f [math]::Round(100.0*$n/[math]::Max(1,$grup.Count))))
  }
  Write-Host $satir
}
if($Ornek -gt 0){
  foreach($x in ($hepsi | Select-Object -First $Ornek)){
    Write-Host ("`n--- {0} · {1} ---" -f $x.ikn, $x.tur)
    $x.GetEnumerator() | ForEach-Object { if("$($_.Value)".Trim() -and $_.Key -notin @('ikn','tur')){ Write-Host ("   {0,-11}: {1}" -f $_.Key, ("$($_.Value)".Substring(0,[math]::Min(120,"$($_.Value)".Length)))) } }
  }
}
if($Yaz){
  $yol = Join-Path $kok "veri\ihale-bulten-ilan.json"
  # --- BIRIKIMLI HAVUZ ------------------------------------------------------
  # OLCULDU (14.08): tek gunluk bulten, ilan.gov.tr havuzundaki 250 ilanin
  # yalniz 11'iyle eslesiyor. Sebep basit - ihaleler 7-40 gun onceden ilan
  # ediliyor, yani bugun acik olan ihalelerin ilani gecmis gunlerin bulteninde.
  # Bu yuzden gunluk bulten UZERINE YAZILMAZ, havuza EKLENIR. Ayni IKN tekrar
  # gelirse YENI kayit eskisini ezer (duzeltme ilani olabilir).
  # Ihale tarihi 3 gunden fazla gecmis kayitlar dusurulur (havuz sismesin).
  $eski = @()
  if(Test-Path $yol){
    try { $eski = @((Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar) } catch { $eski = @() }
  }
  $havuz = [ordered]@{}
  foreach($x in $eski){ if($x.ikn){ $havuz["$($x.ikn)"] = $x } }
  $yeniSay = 0; $guncelSay = 0
  foreach($x in $hepsi){
    if(-not $x.ikn){ continue }
    if($havuz.Contains("$($x.ikn)")){ $guncelSay++ } else { $yeniSay++ }
    $havuz["$($x.ikn)"] = $x
  }
  # suresi gecenleri dus
  $bugun = Get-Date -Hour 0 -Minute 0 -Second 0
  $tut = New-Object Collections.ArrayList
  $dusen = 0
  foreach($k in $havuz.Keys){
    $x = $havuz[$k]
    $md = [regex]::Match("$($x.ihaleTarih)", '^(\d{2})\.(\d{2})\.(\d{4})')
    if($md.Success){
      try {
        $ih = Get-Date -Year ([int]$md.Groups[3].Value) -Month ([int]$md.Groups[2].Value) -Day ([int]$md.Groups[1].Value) -Hour 0 -Minute 0 -Second 0
        if(($bugun - $ih).TotalDays -gt 3){ $dusen++; continue }
      } catch {}
    }
    [void]$tut.Add($x)
  }
  Write-Host ("`nHAVUZ: {0} eski + {1} yeni + {2} guncellenen - {3} suresi gecen = {4}" -f $eski.Count, $yeniSay, $guncelSay, $dusen, $tut.Count)
  $hepsi = @($tut)
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni (KİK) — 4734 s.K. m.13. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    # NOT DUZELTILDI: eskiden "ALT SINIRDIR" yaziyordu. Mantik ambardan m.13
    # okununca TAVANA cevrildi (sureler "en az" oldugu icin uzun sure yuksek
    # maliyeti kanitlamaz, kisa sure yuksegi DISLAR) ama bu satir guncellenmemisti.
    not = "Yaklaşık maliyet ilanla açıklanmaz (4734). Kartta gösterilen tutar, m.13 ilan süresinden çıkarılan TAVANDIR; süreler 'en az' olduğu için alt sınır çıkarılamaz. 24 gün ve üstünde kısaltma hükümleri devrede olduğundan hiç tavan yazılmaz."
    ilanlar = $hepsi
  }
  ($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("`n-> {0} · geri okuma: {1} ilan" -f $yol, @($geri.ilanlar).Count)

  # ===== SITEYE GIDEN INCE DOSYA (14.08 - olculerek karar verildi) ===========
  # Yukaridaki AMBAR dosyasi 469 kayitla 1,3 MB ve havuz birikimli oldugu icin
  # ~20 gunluk dolulukta ~20 MB'a cikiyor. Sayfa bunu HER acilista indiriyordu.
  # Olcum: 469 kaydin yalnizca 26'si kartta gorunuyor (%5,5) - kart ancak
  # ilan.gov.tr havuzundaki IKN'lerle eslesen kaydi cizebiliyor. Ayrica 25 alanin
  # 10'u kartta hic okunmuyor (130 KB) ve teknik alani tek basina 432 KB tutuyor
  # (ort. 921 bayt) ama kartta 230 karakteri gosteriliyor.
  # KARAR: ham veri AMBARDA tam kalir (ileride "bu idare ne almis" sorgusu icin),
  # siteye ayri bir INCE dosya uretilir. Ayni desen ihale-sonuc.json (ambar) ->
  # ihale-sonuc-ozet.json (site) ikilisinde de kullanildi.
  $siteYol = Join-Path $kok "veri\ihale-bulten-ilan-site.json"
  $yiYol = Join-Path $kok "veri\ihale-yurtici.json"
  $gerekli = @{}
  if(Test-Path $yiYol){
    try {
      foreach($e in @((Get-Content $yiYol -Raw -Encoding UTF8 | ConvertFrom-Json).ilanlar)){
        if($e.detay -and $e.detay.ikn){ $gerekli["$($e.detay.ikn)".Trim()] = 1 }
      }
    } catch {}
  }
  # kartin OKUDUGU 15 alan; digerleri yazilmaz (cogu zaten ihale-yurtici.json
  # icindeki detay alaninda var - mukerrer tasiniyordu)
  $siteAlan = @('ikn','isAdi','miktar','ayrintiNerede','dokumanErisim','ekonomik',
                'teknik','benzerIs','isDeneyimi','yerliMali','maliyetTavan',
                'maliyetGun','maliyetDayanak','ilanTarih','bultenSayi')
  # TEKNIK ALANI SADELESTIRME (14.08 Cem "kozmetik kusuru duzelt"):
  # "Ne istiyorlar" satiri teknik yeterlikte ISTENEN OZEL BELGEYI gostermeli
  # ("Tıbbi Cihaz Satış Merkezi Yetki Belgesi" gibi). Ama teknik alani her ilanda
  # AYNI olan standart is-deneyimi fikralariyla dolu; onlar zaten "iş deneyimi %X"
  # olarak ayri gosteriliyor. Onceden bunlari KART (JS) ayikliyordu, ama site
  # dosyasi teknik'i 260'a KIRPINCA jenerik cumle ORTADAN kesiliyor ("...iş
  # deneyimini g") ve JS onu taniyamayip GOSTERIYORDU. Cozum: ayiklamayi KIRPMADAN
  # ONCE, burada yap - kart JS'inin yaptigi ayiklamanin ayni mantigi.
  $stdKalip = @(
    'bedel içeren bir sözleşme kapsamında',
    'Tüzel kişi tarafından iş deneyimini',
    'yurt dışında gerçekleştirilen işlerden elde edilen',
    'iş deneyimini gösteren belgeler',
    'iş ortaklığında pilot ortağın'
  )
  function TeknikSade([string]$t){
    if(-not $t){ return '' }
    if($t -match 'belirtilmemiştir'){ return $t }   # "aranmiyor" bilgisini koru
    $t = $t -replace '4\.3\.\d+(\.\d+)*\.?\s*', '|'
    $parcalar = $t -split '\|+|(?<=\.)\s+(?=\p{Lu})'
    $tut = @()
    foreach($p in $parcalar){
      $p = $p.Trim()
      if($p.Length -lt 13){ continue }
      $std = $false
      foreach($k in $stdKalip){ if($p -match [regex]::Escape($k)){ $std = $true; break } }
      if(-not $std){ $tut += $p }
    }
    return (($tut -join ' · ') -replace '\s+',' ').Trim()
  }

  # uzun alanlar kartta gosterilen sinira kirpilir - gorunum DEGISMEZ
  $kirp = @{ teknik = 260; miktar = 500; benzerIs = 200; ekonomik = 120 }
  $siteKayit = New-Object Collections.ArrayList
  foreach($x in $hepsi){
    if(-not $x.ikn){ continue }
    if($gerekli.Count -and -not $gerekli.ContainsKey("$($x.ikn)".Trim())){ continue }
    $r = [ordered]@{}
    foreach($a in $siteAlan){
      $v = $x.$a
      if($a -eq 'teknik'){ $v = TeknikSade "$v" }   # ONCE sadele
      if($kirp.ContainsKey($a) -and "$v".Length -gt $kirp[$a]){ $v = "$v".Substring(0, $kirp[$a]) }
      if($null -ne $v -and "$v" -ne ''){ $r[$a] = $v }
    }
    [void]$siteKayit.Add($r)
  }
  $siteCikti = [ordered]@{
    guncelleme = $cikti.guncelleme
    not = $cikti.not
    kapsam = "Bu dosya SITE icindir: yalnizca ilan.gov.tr listesinde karsiligi olan ilanlar ve kartta gosterilen alanlar tasinir. Tam veri veri/ihale-bulten-ilan.json'dadir."
    ilanlar = @($siteKayit)
  }
  ($siteCikti | ConvertTo-Json -Depth 5) | Out-File $siteYol -Encoding utf8
  $sgeri = Get-Content $siteYol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("-> {0}" -f $siteYol)
  Write-Host ("   {0} ilan (ambarda {1}) · {2:N0} KB (ambar {3:N0} KB) · geri okuma: {4}" -f `
    @($siteCikti.ilanlar).Count, $hepsi.Count, ((Get-Item $siteYol).Length/1KB), ((Get-Item $yol).Length/1KB), @($sgeri.ilanlar).Count)
} else { Write-Host "`n(olcum modu - yazmak icin -Yaz)" }







