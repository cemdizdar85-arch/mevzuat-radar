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
#   - KALKINMA AJANSLARI (19.08 Cem: "kalkinma ajansi cagrilarini da"):
#     ka.gov.tr Nuxt uygulamasi, veri api/supports ucundan JSON (sayfali, 20/sayfa).
#     DIKKAT: www.ka.gov.tr sertifikasi YANLIS PRINCIPAL verir - daima apex
#     (https://ka.gov.tr) kullanilir; cekim curl ile (SEDIA'yla ayni sebep).
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
function IsoTarih($ham){
  # pwsh 7 ConvertFrom-Json ISO tarihleri kendiliginden [datetime] yapar (19.08 CI dersi);
  # dize de gelebilir ("2026-03-02 08:58:12" / "2026-03-02T08:58:12"). yyyy-MM-dd dondurur, cozulemezse bos.
  if($ham -is [datetime]){ return $ham.ToString("yyyy-MM-dd") }
  $s = "$ham"
  if($s.Length -ge 10){
    try { return ([datetime]::ParseExact($s.Substring(0,10),"yyyy-MM-dd",$null)).ToString("yyyy-MM-dd") } catch {}
  }
  return ""
}
function GuvenliCek([string]$adres){
  # UseBasicParsing + UA standart; hata firlatmaz, bos doner (olculemedi).
  # 30.08 TURKCE HARF DERSI: sunucu Content-Type'ta charset yazmazsa PS govdeyi
  # ISO-8859-1 sayar ve "Döngüsel" -> "D ng sel" olur (KOSGEB'de OLCULDU).
  # Bu tarih okumasinda goze batmiyordu, yutulan CUMLEDE bariz. Cozum: ham
  # BAYT alinir, meta charset'e bakilmaksizin UTF-8 cozulur; cozum bozuksa
  # (replacement karakteri cok) ISO-8859-9'a dusulur.
  try {
    $yanit = Invoke-WebRequest -Uri $adres -UserAgent "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -TimeoutSec 60 -UseBasicParsing
    $bayt = $null
    try { $bayt = $yanit.RawContentStream.ToArray() } catch {}
    if($bayt -and $bayt.Length){
      $utf = [Text.Encoding]::UTF8.GetString($bayt)
      $bozuk = ([regex]::Matches($utf, [string][char]0xFFFD)).Count
      if($bozuk -gt 3){ return [Text.Encoding]::GetEncoding(28599).GetString($bayt) }
      return $utf
    }
    return [string]$yanit.Content
  } catch { Write-Host ("  cekilemedi: {0} ({1})" -f $adres, $_.Exception.Message); return "" }
}

# --- YUTMA KATMANI (30.08 Cem: "sadece bilgi vermek degil hepsini yutsak ve
#     kisaca bilgiler versek") ---------------------------------------------------
# TESHIS: 162 firsatin 133'unde "Kim basvurabilir" ve "Ne kadar" alanlari
# "Cagri duyurusunda" yaziyordu - liste %82 oraninda BOS bilgi tasiyordu.
# Cozum: robot cagrinin DETAY metnini de yutar; kim/tutar/ozet/asama alanlari
# metinden CIKARILIR.
#
# UYDURMA YASAGI (Cem'in en sert kurali): bu fonksiyonlarin hicbiri cumle
# URETMEZ - kaynak metinden BIREBIR cumle secer, yalniz kirpar. Desen tutmazsa
# BOS doner ve kart eskisi gibi "Cagri duyurusunda" der. Kor kalmak, yanlis
# rakam vermekten iyidir.
function DuzMetin([string]$html){
  if(-not $html){ return "" }
  $t = $html -replace '(?s)<script.*?</script>',' ' -replace '(?s)<style.*?</style>',' '
  $t = $t -replace '(?s)<nav.*?</nav>',' ' -replace '(?s)<header.*?</header>',' ' -replace '(?s)<footer.*?</footer>',' '
  $t = $t -replace '<(p|div|br|li|tr|h[1-6])[^>]*>',"`n" -replace '<[^>]*>',' '
  # 30.08 TURKCE HARF DERSI (ikinci vaka): KOSGEB govdesi Turkce harfleri
  # ADLANDIRILMIS entity ile yaziyor (&Ccedil;, &uuml;…). Toptan '&[a-z]+;' -> ' '
  # kurali bunlari BOSLUGA cevirip "Çağrı" -> " ağrı", "düzenlenecek" ->
  # "d zenlenecek" yapiyordu - OLCULDU. Once harfler cozulur, sonra kalan
  # entity'ler bosluga iner.
  $t = [Net.WebUtility]::HtmlDecode($t)
  $t = $t -replace '&nbsp;',' ' -replace '&[a-zA-Z]+;',' ' -replace '&#\d+;',' '
  # 30.08 OLCULDU: 25 karakter esigi menuyu GECIRIYORDU ("Erisilebilirlik
  # Ayarlarini Temizle", "Sifir Atik ve Dongusel Ekonomi" gibi menu/etiket
  # satirlari "Ne kadar" alanina dusuyordu). Govde cumlesinin menuden farki:
  # UZUN olur VE icinde cumle noktalamasi ya da bagli bir yuklem bulunur.
  $satirlar = @()
  foreach($ham in ($t -split "`n")){
    $s = ($ham -replace '\s+',' ').Trim()
    if($s.Length -lt 45){ continue }                       # menu/etiket satiri
    if($s -notmatch '[a-zçğıöşü]{3}\s+[a-zçğıöşü]{3}'){ continue }  # BASLIK KUTUSU (Her Kelime Buyuk)
    $satirlar += $s
  }
  # 30.08: satirlar BOSLUKLA birlestirilirse noktayla bitmeyen baslik satiri
  # ("… Çağrısı Açıldı") kendinden sonraki gercek cumleye YAPISIR ve 540
  # karakterlik blok olusur (olculdu) - blok da uzunluk elemesine takilip
  # bilgiyi tamamen dusuruyordu. HTML blok siniri KORUNUR; cumle bolme once
  # satira, sonra cumleye iner.
  return ($satirlar -join "`n")
}
function Cumleler([string]$metin){
  if(-not $metin){ return @() }
  # nokta+bosluk+buyuk harf (TR harfler dahil) sinirindan bol.
  # 30.08 DUZELTME: "2026 yili 2. Cagrisi" gibi SIRA SAYISINDAN sonraki nokta
  # cumle sonu degildir - basliklar orta yerinden kesiliyordu. Nokta'nin
  # oncesi tek/cift haneli sayiysa bolunmez.
  # (lookahead'de rakam da kabul edilir: "…sunulmaktadır. 1501-Sanayi…" gibi
  #  program koduyla BASLAYAN cumleler yoksa oncekine yapisiyordu - olculdu.)
  $cikan = @()
  foreach($satir in ($metin -split "`n")){
    foreach($c in [regex]::Split($satir, '(?<![\s\(]\d{1,2})(?<=[\.\!\?:])\s+(?=[A-ZÇĞİÖŞÜ]|\d{3,})')){
      $d = ($c -replace '\s+',' ').Trim()
      if($d.Length -ge 40){ $cikan += $d }
    }
  }
  return ,$cikan
}
function Kirp([string]$c, [int]$tavan){
  if(-not $c){ return "" }
  $c = $c.Trim()
  if($c.Length -le $tavan){ return $c }
  # kelime ortasindan kesme
  $kes = $c.Substring(0,$tavan)
  $bosluk = $kes.LastIndexOf(' ')
  if($bosluk -gt ($tavan*0.6)){ $kes = $kes.Substring(0,$bosluk) }
  return ($kes.TrimEnd(' ',',',';') + '…')
}
function CumleSec([string]$metin, [string]$desen, [int]$tavan, [string]$baslik, [string[]]$kacin){
  # desene UYAN ilk cumleyi BIREBIR dondurur (uydurma yok). Yoksa bos.
  # 30.08: iki oz-sinav eklendi - (1) secilen cumle BASLIGIN kopyasiysa bilgi
  # degildir, atlanir; (2) 400 karakteri asan cumle genelde birlesmis blok olur.
  $bas = ""
  if($baslik){ $bas = (($baslik -replace '[^\p{L}\p{Nd}]','')).ToLowerInvariant() }
  foreach($c in (Cumleler $metin)){
    if($c -notmatch $desen){ continue }
    if($c.Length -gt 400){ continue }
    if($bas.Length -ge 12){
      $sade = (($c -replace '[^\p{L}\p{Nd}]','')).ToLowerInvariant()
      # cumle basligi tekrarliyorsa (ya da baslik cumleyi yutuyorsa) bos bilgidir
      if($sade.StartsWith($bas.Substring(0,[Math]::Min(24,$bas.Length)))){ continue }
      if($bas.StartsWith($sade.Substring(0,[Math]::Min(24,$sade.Length)))){ continue }
    }
    # zaten baska bir alana yazilmis cumleyi TEKRAR ETME - siradakine bak
    if($kacin){
      $sadeC = (($c -replace '[^\p{L}\p{Nd}]','')).ToLowerInvariant()
      $carpisti = $false
      foreach($k in $kacin){
        if(-not $k){ continue }
        $sadeK = (($k -replace '[^\p{L}\p{Nd}]','')).ToLowerInvariant()
        $n = [Math]::Min(60, [Math]::Min($sadeC.Length, $sadeK.Length))
        if($n -ge 20 -and $sadeC.Substring(0,$n) -eq $sadeK.Substring(0,$n)){ $carpisti = $true; break }
      }
      if($carpisti){ continue }
    }
    return (Kirp $c $tavan)
  }
  return ""
}
# "Ne kadar": oran/tutar cumlesi. 30.08 SIKILASTIRILDI - eski desen bagalamsiz
# "%" ya da "firmalar" gorunce tutuyordu ve alakasiz cumle yaziyordu (olculdu:
# 1501 cagrisinda gercek oran yerine giris cumlesi secilmisti). Artik PARA
# BAGLAMI + RAKAM birlikte aranir; rakamsiz cumle "ne kadar" cevabi degildir.
$DESEN_TUTAR = '(?i)(?=.*\d)((destek oran|hibe destek|üst limit|üst sınır|azami|en fazla|en çok|toplam bütçe|bütçesi|destek tutar|geri ödemesiz|ödenek|katkı(sı)?)[^\.]{0,60}?(%\s?\d|\d[\d\.\,]{2,}|\d+\s?(bin|milyon|milyar))|(%\s?\d{1,3})[^\.]{0,40}?(destek|oran|hibe)|\d[\d\.\,]{2,}\s?(TL|₺)|\d+\s?(bin|milyon|milyar)\s?(TL|₺|Avro|Euro|€))'
# "Kim basvurabilir": uygunluk cumlesi. 30.08 SIKILASTIRILDI - tek basina
# "firmalar"/"isletmeler" her cumlede geciyordu; artik UYGUNLUK KALIBI sart.
$DESEN_KIM   = '(?i)(başvuru sahib|uygun başvuru|başvuru yapabil|kimler başvur|başvurabilecek|başvurabilir|yararlanabil|hedef kitle|ölçeğindeki (kuruluş|işletme|firma)|KOBİ (ölçeğ|niteliğ|vasfı)|küçük ve orta (büyüklük|ölçek)|(sermaye şirket|kooperatif|üretici örgüt|ticaret şirket)[^\.]{0,60}(başvur|yararlan|uygun))'
# 30.08 OLCULDU: "…uygunluk kriterleri, başvuru koşulları … rehberinde yer
# almaktadır." cumlesi KIM desenine takiliyordu ama KIMSEYI tarif etmiyor,
# okuyucuyu baska belgeye yolluyor. Yonlendirme cumlesi bilgi degildir.
$DESEN_KIM_RED = '(?i)(rehber(in|de|ine)|ilanın sonuna|aşağıda (yer al|sunul)|ayrıntılı bilgi|bakınız|belirtilmiştir\.?$)'
# 30.08 OLCULDU: KOSGEB sayfasinda "Kucuk ve Orta Olcekli Isletmeleri Gelistirme
# ve Destekleme Idaresi Baskanligi" cumlesi KIM alanina dusuyordu - bu KURUMUN
# KENDI ADI, basvuru sahibi tarifi degil. Kurum adiyla biten satir reddedilir.
$DESEN_KURUM_ADI = '(?i)(başkanlığı|bakanlığı|genel müdürlüğü|kalkınma ajansı|ajansı)\s*\.?\s*$'
# 30.08: "Kim basvurabilir" bir OZNE tarif etmelidir. Basvuru PROSEDURUNU
# anlatan cumleler ("…KAYS sistemi uzerinde olusturulan Taahhutname…") desene
# takiliyor ama kimseyi tarif etmiyordu - olculdu. Cumlede bir basvuru sahibi
# TURU gecmiyorsa alan bos birakilir.
$DESEN_OZNE = '(?i)(işletme|firma|şirket|KOBİ|kooperatif|üretici|girişimci|kuruluş|üniversite|dernek|vakıf|birlik|oda|belediye|tüzel kişi|gerçek kişi|sivil toplum|kamu kurum|araştırmacı|ihracatçı|yatırımcı|çiftçi|esnaf|sanayici)'
# Ozet: cagrinin NE OLDUGUNU soyleyen amac/kapsam cumlesi. 30.08: "programi",
# "cagri", "proje" gibi her yerde gecen kelimeler cikarildi - baslik tekrarini
# ozet diye yaziyorlardi. Amac bildiren YUKLEM aranir.
$DESEN_OZET  = '(?i)(amacıyla|amacı ile|amaçlanmakta|amacını taşı|hedeflenmekte|hedefiyle|desteklenmesi|desteklenmekte|sağlanmasına yönelik|kapsamında[^\.]{0,80}(destek|proje|başvuru)|için (hibe|destek|kaynak) (sağlan|verilecek|aktarıl))'
# Asama etiketi: BASLIK + metinden TURETILIR (kural tabanli, tek tek anahtar
# kelime). Turetilmis olduğu icin karta "aşama" olarak degil filtreye yem olarak
# girer; eslesme yoksa BOS kalir (etiket uydurulmaz).
#  AB kayitlari INGILIZCE gelir (SEDIA yalniz en yayimliyor) - Turkce desen
#  onlarda hicbir zaman tutmuyordu, 100 AB cagrisi asama suzgecinin disinda
#  kaliyordu. Her satira Ingilizce karsiliklari da eklendi.
$ASAMA_DESEN = [ordered]@{
  ihracat   = '(?i)(ihracat|dış ticaret|yurt dışı pazar|uluslararasılaş|fuar|ihracatçı|export|internationalisation|foreign market|trade fair)'
  arge      = '(?i)(ar-?ge|araştırma[ -]geliştirme|yenilik|inovasyon|prototip|teknoloji geliştirme|patent|TEYDEB|research and innovation|innovation action|R&D|prototyp|technology development|pilot demonstration)'
  istihdam  = '(?i)(istihdam|işe alım|çalışan sayısı|mesleki eğitim|staj|işbaşı eğitim|employment|workforce|skills development|vocational training|job creation)'
  donusum   = '(?i)(dijital dönüşüm|dijitalleş|yeşil dönüşüm|yeşil büyüme|enerji verimlil|sürdürülebilir|karbon|iklim|digital transition|digitalis|green transition|energy efficien|sustainab|decarbonis|climate)'
  finansman = '(?i)(kredi|faiz|kefalet|teminat|finansman|sigorta|kâr payı|kar payı|loan|guarantee scheme|financial instrument|equity|blended finance)'
  kurulus   = '(?i)(yeni kurul|girişimci|start-?up|iş kurma|kuruluş aşaması|ilk kez|genç girişim|entrepreneur|newly established|spin-?off|incubat)'
  buyume    = '(?i)(kapasite artır|yatırım|makine|teçhizat|büyüme|ölçek|modernizasyon|üretim tesisi|scale-?up|capacity build|investment|manufacturing facility|market uptake)'
}
function AsamaBul([string]$metin){
  # 30.08 OLCULDU: genis metinde YEDI etiketin ALTISI birden tutuyordu. Her
  # filtrede cikan kayit hicbir filtrede ayirt edici degildir - "tusa basinca
  # bir sey degismiyor" hissinin ikinci kaynagi buydu. Artik etiketler metinde
  # KAC KEZ gectigine gore siralanir ve EN GUCLU UCU alinir; tek kez gecen
  # yan degini etiket sayilmaz (>=2 gecis ya da ilk sirada olma sarti).
  if(-not $metin){ return ,@() }
  $skor = @()
  foreach($ad in $ASAMA_DESEN.Keys){
    $n = ([regex]::Matches($metin, $ASAMA_DESEN[$ad])).Count
    if($n -gt 0){ $skor += [pscustomobject]@{ ad=$ad; n=$n } }
  }
  if(-not $skor.Count){ return ,@() }
  $sirali = @($skor | Sort-Object -Property @{Expression='n';Descending=$true}, @{Expression='ad'})
  $enCok = $sirali[0].n
  $secilen = @($sirali | Where-Object { $_.n -ge 2 -or $_.n -eq $enCok } | Select-Object -First 3 | ForEach-Object { $_.ad })
  return ,$secilen
}
function YutSayfa([string]$metin, [string]$baslik){
  # tek cagri metninden dort alan cikarir; bulunmayan alan BOS kalir.
  if(-not $metin){ return [ordered]@{ ozet=""; kim=""; tutar=""; asama=@() } }
  # sira onemli: once KIM ve NE KADAR (kesin bilgi), sonra OZET - ozet bu
  # ikisinin cumlesini tekrarlamayan ilk amac cumlesini secer.
  $k = CumleSec $metin $DESEN_KIM   150 $baslik @()
  if($k -and ($k -match $DESEN_KIM_RED -or $k -match $DESEN_KURUM_ADI -or $k -notmatch $DESEN_OZNE)){ $k = "" }
  $t = CumleSec $metin $DESEN_TUTAR 150 $baslik @($k)
  # 30.08 oz-sinav: desen cumlenin ILERISINDEKI rakami gorup tutabiliyor, ama
  # karta yalniz KIRPILMIS hali yaziliyor - kullanici rakamsiz bir "Ne kadar"
  # okuyor (olculdu: 1831 Yesil Inovasyon). Gosterilecek metinde rakam yoksa
  # bu alan cevap vermiyordur, bos birakilir.
  if($t -and $t -notmatch '\d'){ $t = "" }
  $o = CumleSec $metin $DESEN_OZET  190 $baslik @($k,$t)
  # 30.08 oz-sinav: ayni cumle iki alanda birden yazilirsa kart kendini tekrar
  # eder (olculdu: 1831'de "kim" ve "ne kadar" ayni cumleydi; 1501'de "ozet" ve
  # "kim" ayni cumlenin iki farkli kirpimiydi - tam esitlik testi bunu KACIRDI).
  # Karsilastirma ON EK uzerinden yapilir; ayni cumleden gelen alanin zayifi
  # bosaltilir (rakam tasiyan "ne kadar", uygunluk kalibi tasiyan "kim" kalir).
  $onek = { param($x) if(-not $x){ "" } else { (($x -replace '[^\p{L}\p{Nd}]','')).ToLowerInvariant() } }
  $ayniMi = { param($a,$b)
    $x = & $onek $a; $y = & $onek $b
    if(-not $x -or -not $y){ return $false }
    $n = [Math]::Min(60, [Math]::Min($x.Length, $y.Length))
    if($n -lt 20){ return ($x -eq $y) }
    return ($x.Substring(0,$n) -eq $y.Substring(0,$n))
  }
  if((& $ayniMi $k $t)){ if($t -match '\d'){ $k = "" } else { $t = "" } }
  if((& $ayniMi $o $k)){ $o = "" }
  if((& $ayniMi $o $t)){ $o = "" }
  # 30.08: asama etiketi BASLIK + SAYFA METNI uzerinden turetilir. Once yalniz
  # yutulan uc cumleye bakiyorduk - 133 kaydin 101'i etiketsiz kaliyor ve asama
  # suzgeci yine bos donuyordu (olculdu). Gurultu riskini AsamaBul'un "en guclu
  # uc etiket" kurali karsilar; metin tavani sayfanin konu tasiyan bas kismidir.
  $asamaMetni = ($baslik + " " + $metin)
  if($asamaMetni.Length -gt 4000){ $asamaMetni = $asamaMetni.Substring(0,4000) }
  return [ordered]@{ ozet=$o; kim=$k; tutar=$t; asama=(AsamaBul $asamaMetni) }
}

$cagrilar = @()
$kaynakDurum = [ordered]@{}
$yutulanAdet = 0

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
  $bagLinkler = @($bagLinkler)
  # 19.08 CAPRAZ KONTROL: sanayi blogu DAR kaliyor - ana sayfa duyurularinda
  # blokta OLMAYAN cagrilar var (olculdu: BiGG+ Tohum Yatirim 2026/1). Sirket
  # sinyali tasiyanlar eklenir: 4 haneli program kodu YA DA sanayi/kobi/girisim/
  # bigg/ar-ge/teknoloji/patent/yatirim kelimesi. Akademik cagrilar (Kutup
  # Arastirmalari, Gokyuzu Gozlem) boylece elenir - kitlemiz SIRKET.
  $anaHtmlTb = GuvenliCek $tubitakKok
  if($anaHtmlTb){
    $mevcutBasliklar = @($bagLinkler | ForEach-Object { (Normalize $_.baslik) })
    $ekAdaylar = [regex]::Matches($anaHtmlTb, '<a[^>]*href="(/tr/duyuru/[^"]+)"[^>]*>([^<]{5,160})</a>') |
      ForEach-Object { [pscustomobject]@{ href=$_.Groups[1].Value; baslik=(($_.Groups[2].Value -replace '\s+',' ').Trim()) } } |
      Sort-Object href -Unique
    foreach($aday in $ekAdaylar){
      $normA = Normalize $aday.baslik
      if($normA -notmatch 'cagri'){ continue }
      $sirketSinyali = ($aday.baslik -match '\d{4}\s*-|\b\d{4}\b') -or ($normA -match 'sanayi|kobi|girisim|bigg|ar-ge|arge|teknoloji|patent|yatirim')
      if(-not $sirketSinyali){ continue }
      # mukerrer: ayni cagri hem blokta hem duyuruda olabilir (ilk 30 karakter)
      $kisaA = if($normA.Length -gt 30){ $normA.Substring(0,30) } else { $normA }
      if(@($mevcutBasliklar | Where-Object { $_.StartsWith($kisaA) }).Count){ continue }
      $bagLinkler += $aday
      Write-Host ("  duyuru akisindan eklendi: {0}" -f $aday.baslik)
    }
  }
  foreach($bag in ($bagLinkler | Select-Object -First 18)){
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
    # YUTMA: duyuru sayfasi ZATEN cekildi (yukarida tarih tablosu icin) - eskiden
    # metni atiyorduk. Govde region-content'ten sonra baslar; oncesi site menusu.
    $yTb = YutSayfa "" ""
    if($duyuruHtml){
      $govdeBas = $duyuruHtml.IndexOf('region-content')
      $govde = if($govdeBas -ge 0){ $duyuruHtml.Substring($govdeBas) } else { $duyuruHtml }
      $yTb = YutSayfa (DuzMetin $govde) $bag.baslik
      if($yTb.ozet -or $yTb.tutar -or $yTb.kim){ $yutulanAdet++ }
    }
    $cagrilar += [ordered]@{
      kaynak="TÜBİTAK"; kod=$kod; baslik=$bag.baslik; durum="acik"
      acilis=$acilis; sonTarih=$sonTarih
      tarihler=$tarihler
      ozet=$yTb.ozet; kim=$yTb.kim; tutar=$yTb.tutar
      asama=(&{ if(@($yTb.asama).Count){ ,@($yTb.asama) } else { AsamaBul $bag.baslik } })
      url=($tubitakKok + $bag.href)
    }
    $tubitakAdet++
    Start-Sleep -Milliseconds 300
  }
}
$kaynakDurum["TÜBİTAK"] = if($tubitakOlduMu){ "OK ($tubitakAdet çağrı)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("TUBITAK: {0}" -f $kaynakDurum["TÜBİTAK"])

# --- 2) KOSGEB ---------------------------------------------------------------
# 19.08 Cem kontrolu KUSUR YAKALADI: cagrilar duyurular sayfasinda DEGIL,
# ANA SAYFA haber akisinda ilan ediliyor (COP31 cagrisi acikken 0 sayiyorduk).
# Iki kaynak birlikte taranir; eslesen duyurunun DETAYINDAN tarih cozulur
# ("basvurular X - Y tarihleri arasinda" kalibi), bitisi gecmis olan ELENIR
# (ana sayfada kapanmis cagri da duruyor - 2026/1-2 donem ornekleri olculdu).
Write-Host "KOSGEB ana sayfa + duyuru akisi okunuyor..."
$kosgebAdet = 0; $kosgebOlduMu = $false
$kosgebHavuz = @{}
foreach($kaynakSayfasi in @("https://www.kosgeb.gov.tr","https://www.kosgeb.gov.tr/site/tr/genel/duyurular")){
  $kosgebHtml = GuvenliCek $kaynakSayfasi
  if(-not $kosgebHtml){ continue }
  $bulunan = [regex]::Matches($kosgebHtml, '(?s)<a[^>]*href="(/site/tr/genel/detay/[^"]*)"[^>]*>(.{5,250}?)</a>')
  if(@($bulunan).Count -ge 3){ $kosgebOlduMu = $true }   # en az bir kanal okunabildi
  foreach($m in $bulunan){
    $href = $m.Groups[1].Value
    $baslik = (((($m.Groups[2].Value -replace '<[^>]*>','') -replace '&nbsp;',' ') -replace '\s+',' ').Trim())
    if($baslik -and -not $kosgebHavuz.ContainsKey($href)){ $kosgebHavuz[$href] = $baslik }
  }
}
foreach($href in $kosgebHavuz.Keys){
  $baslik = $kosgebHavuz[$href]
  if($baslik -match '^devam'){ continue }   # "devamı" linkleri ayni detaya gider
  $normBaslik = Normalize $baslik
  if(-not ($normBaslik -match 'cagri' -or $normBaslik -match 'proje teklif')){ continue }
  # detaydan tarih: "basvurular[,] 20 Nisan - 8 Mayis 2026 tarihleri arasinda"
  # (ilk tarihte yil OLMAYABILIR - bitisin yili kullanilir)
  $acilisK = ""; $sonK = ""
  $detayHtml = GuvenliCek ("https://www.kosgeb.gov.tr" + $href)
  if($detayHtml){
    $cumle = [regex]::Match($detayHtml, '(?is)ba.{0,2}vurular[^<>]{0,120}?tarihleri\s+aras')
    if($cumle.Success){
      $tarihParcalari = [regex]::Matches($cumle.Value, '(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)(?:\s+(\d{4}))?|(\d{1,2}[./]\d{1,2}[./]\d{4})')
      $cozulmus = @()
      # once yilli olanlar cozulur; yilsiz ilk tarihe bitisin yili verilir
      $sonYil = ""
      foreach($p in $tarihParcalari){ if($p.Groups[3].Value){ $sonYil = $p.Groups[3].Value } }
      foreach($p in $tarihParcalari){
        $hamT = $p.Value.Trim()
        if($p.Groups[1].Value -and -not $p.Groups[3].Value -and $sonYil){ $hamT = "$hamT $sonYil" }
        $t = TrTarihCoz $hamT
        if($t){ $cozulmus += $t }
      }
      if($cozulmus.Count -ge 2){ $acilisK = ($cozulmus | Sort-Object | Select-Object -First 1); $sonK = ($cozulmus | Sort-Object | Select-Object -Last 1) }
      elseif($cozulmus.Count -eq 1){ $sonK = $cozulmus[0] }
    }
  }
  # bitisi gecmis cagri listelenmez; tarihi cozulemesyen TEMKINLE listelenir (tarih duyuruda)
  if($sonK){
    try { if([datetime]::ParseExact($sonK,"yyyy-MM-dd",$null) -lt $bugun){ continue } } catch {}
  }
  # YUTMA: detay sayfasi ZATEN cekildi (tarih cumlesi icin) - metni de okuyoruz.
  $yKo = YutSayfa (DuzMetin $detayHtml) $baslik
  if($yKo.ozet -or $yKo.tutar -or $yKo.kim){ $yutulanAdet++ }
  $cagrilar += [ordered]@{
    kaynak="KOSGEB"; kod=""; baslik=$baslik; durum="acik"
    acilis=$acilisK; sonTarih=$sonK; tarihler=@()
    ozet=$yKo.ozet; kim=$yKo.kim; tutar=$yKo.tutar
    asama=(&{ if(@($yKo.asama).Count){ ,@($yKo.asama) } else { AsamaBul $baslik } })
    url=("https://www.kosgeb.gov.tr" + $href)
  }
  $kosgebAdet++
  Start-Sleep -Milliseconds 200
}
$kaynakDurum["KOSGEB"] = if($kosgebOlduMu){ "OK ($kosgebAdet açık çağrı — ana sayfa + duyurular tarandı, 0 olması normal)" } else { "ÖLÇÜLEMEDİ" }
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
[IO.File]::WriteAllText($sorguDosya, '{"bool":{"must":[{"terms":{"type":["1","2"]}},{"terms":{"status":["31094502","31094501"]}}]}}')
[IO.File]::WriteAllText($dilDosya,   '["en"]')
[IO.File]::WriteAllText($siraDosya,  '{"field":"deadlineDate","order":"ASC"}')
try {
  # sunucu pageSize'i 100'e KIRPAR (olculdu: 500 istendi 100 geldi) -> sayfalama sart.
  # ASC siralamada ilk sayfalar gecmis cut-off'lu eski konular; TUM sayfalar gezilir.
  $abListe = @(); $sayfa = 1; $toplamAB = -1
  while($sayfa -le 20){
    # baglanti ortada kopabiliyor (19.08: sayfa 2'de Recv failure -> kesik JSON) - 2 deneme
    $sedia = $null
    foreach($deneme in 1,2){
      Remove-Item $sediaDosya -ErrorAction SilentlyContinue
      & $curlKomut -sS --connect-timeout 25 -m 90 -X POST "https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA&text=***&pageSize=100&pageNumber=$sayfa" `
        -F "query=<$sorguDosya;type=application/json" `
        -F "languages=<$dilDosya;type=application/json" `
        -F "sort=<$siraDosya;type=application/json" `
        -o $sediaDosya
      if(-not (Test-Path $sediaDosya)){ continue }
      $sediaHam = Get-Content $sediaDosya -Raw -Encoding UTF8
      # cift anahtar temizligi (DATASOURCE/datasource) - iki dizilis de olabilir
      $sediaHam = $sediaHam -replace ',"datasource":\[[^\]]*\]','' -replace '"datasource":\[[^\]]*\],',''
      try { $sedia = $sediaHam | ConvertFrom-Json; break }
      catch { Write-Host ("  sayfa {0} deneme {1}: kesik/bozuk yanit, yeniden denenecek" -f $sayfa, $deneme); Start-Sleep -Seconds 2 }
    }
    if(-not $sedia){ throw "SEDIA sayfa $sayfa iki denemede de okunamadi" }
    if($sedia.totalResults -lt 1){ break }
    $toplamAB = $sedia.totalResults
    $abOlduMu = $true
    foreach($sonuc in @($sedia.results)){
      $meta = $sonuc.metadata
      $kimlik = "$($meta.identifier)"; $baslikAB = "$($meta.title)"
      if(-not $kimlik -or -not $baslikAB){ continue }
      # 19.08 Cem karari: kapsam Ufuk Avrupa'nin OTESINE acildi (tum AB programlari)
      # + "yakinda acilacak" cagrilar da alinir. Durum status kodundan okunur:
      # 31094502 = acik, 31094501 = yakinda (forthcoming).
      $durumAB = if("$($meta.status)" -eq '31094501'){ 'yakinda' } else { 'acik' }
      # 19.08 OLCULDU: SEDIA topic kayitlarinda program ADI YOK, yalniz
      # frameworkProgramme ID'si var. Program adi KIMLIK ONEKINDEN cozulur
      # (HORIZON-..., ERASMUS-..., LIFE-...); bilinmeyen onek oldugu gibi yazilir,
      # UYDURULMAZ.
      $onek = (($kimlik -split '-')[0] -split '/')[0]
      $programSozluk = @{
        'HORIZON'='Ufuk Avrupa'; 'ERASMUS'='Erasmus+'; 'LIFE'='LIFE (çevre-iklim)';
        'DIGITAL'='Dijital Avrupa'; 'CREA'='Yaratıcı Avrupa'; 'CERV'='Yurttaşlar ve Eşitlik';
        'SMP'='Tek Pazar Programı'; 'CEF'="Avrupa'yı Bağlama"; 'EU4H'='AB Sağlık Programı';
        'ESC'='Avrupa Dayanışma Programı'; 'EDF'='Avrupa Savunma Fonu'; 'AMIF'='Göç ve Uyum Fonu';
        'ISF'='İç Güvenlik Fonu'; 'BMVI'='Sınır Yönetimi Fonu'; 'JUST'='Adalet Programı';
        'IMCAP'='Tarım Tanıtım'; 'AGRIP'='Tarım Tanıtım'; 'EMFAF'='Denizcilik ve Balıkçılık';
        'PERF'='Performans Programı'; 'RFCS'='Kömür-Çelik Araştırma'; 'UCPM'='Sivil Koruma'
      }
      $programAB = if($programSozluk.ContainsKey($onek)){ $programSozluk[$onek] } else { $onek }
      if(-not $programAB){ $programAB = "AB programı" }
      # gelecek tarihli en yakin son tarih (cut-off).
      # DIKKAT (19.08 CI vakasi): pwsh 7 ConvertFrom-Json ISO tarih dizesini
      # KENDILIGINDEN [datetime] yapar; "$ham".Substring o zaman kultur-bicimli
      # dize verir ve ParseExact sessizce patlar (CI'da 345 konunun hepsi elendi).
      $gelecek = @()
      foreach($ham in @($meta.deadlineDate)){
        $t = $null
        if($ham -is [datetime]){ $t = $ham.Date }
        else { try { $t = [datetime]::ParseExact("$ham".Substring(0,10),"yyyy-MM-dd",$null) } catch {} }
        if($t -and $t -ge $bugun){ $gelecek += $t }
      }
      # acilis tarihi (yakinda olanlarda ASIL bilgi budur)
      $acilisAB = ""
      foreach($ham in @($meta.startDate)){
        $t = $null
        if($ham -is [datetime]){ $t = $ham.Date }
        else { try { $t = [datetime]::ParseExact("$ham".Substring(0,10),"yyyy-MM-dd",$null) } catch {} }
        if($t){ $acilisAB = $t.ToString("yyyy-MM-dd"); break }
      }
      # ACIK kayitta gelecek son tarih SART (yoksa fiilen kapanmis);
      # YAKINDA kayitta son tarih ya da gelecek acilis yeter.
      $sonAB = if($gelecek.Count){ ($gelecek | Sort-Object | Select-Object -First 1).ToString("yyyy-MM-dd") } else { "" }
      if($durumAB -eq 'acik'){
        if(-not $sonAB){ continue }
      } else {
        $acilisGelecekte = $false
        if($acilisAB){ try { $acilisGelecekte = ([datetime]::ParseExact($acilisAB,"yyyy-MM-dd",$null) -ge $bugun) } catch {} }
        if(-not $sonAB -and -not $acilisGelecekte){ continue }
      }
      # --- YUTMA (AB) ---------------------------------------------------------
      # EK ISTEK YOK: SEDIA metadata'sinda zaten duruyordu, eskiden atiyorduk.
      #  * descriptionByte -> "Expected Outcome" ozeti (portal metni INGILIZCE;
      #    ceviri UYDURMA olur, oldugu gibi verilir ve kartta boyle etiketlenir)
      #  * budgetOverview  -> bu konuya ayrilan butce/hibe basina tutar (SAYI
      #    kaynaktan gelir, yalniz bicimlenir)
      #  * typesOfAction   -> hangi aksiyon tipi (kim/nasil basvurur sinyali)
      $ozetAB = ""; $tutarAB = ""; $kimAB = ""; $abTamMetin = ""
      if($meta.descriptionByte){
        # asama turetmesi TAM aciklamadan yapilir (kirpilmis 190 karakter konuyu
        # tasimiyordu - AB'nin 100 cagrisi asama suzgecine hic girmiyordu)
        $abTamMetin = (DuzMetin "$($meta.descriptionByte[0])") -replace '^\s*Expected Outcome:?\s*',''
        if($abTamMetin.Length -gt 4000){ $abTamMetin = $abTamMetin.Substring(0,4000) }
        $ozetAB = Kirp $abTamMetin 190
      }
      if($meta.typesOfAction){ $kimAB = "$($meta.typesOfAction[0])" }
      if($meta.budgetOverview){
        try {
          $bo = "$($meta.budgetOverview[0])" | ConvertFrom-Json
          foreach($grup in $bo.budgetTopicActionMap.PSObject.Properties){
            foreach($ak in @($grup.Value)){
              if("$($ak.action)" -like "$kimlik*"){
                $enAz = [double]$ak.minContribution; $enCok = [double]$ak.maxContribution
                $adet = [int]$ak.expectedGrants
                if($enCok -gt 0){
                  $bicim = { param($x) if($x -ge 1000000){ ("{0:N1} milyon €" -f ($x/1000000)) } else { ("{0:N0} €" -f $x) } }
                  $aralik = if($enAz -gt 0 -and $enAz -ne $enCok){ (& $bicim $enAz) + " – " + (& $bicim $enCok) } else { (& $bicim $enCok) }
                  $tutarAB = "Proje başına " + $aralik
                  if($adet -gt 0){ $tutarAB += ("; yaklaşık {0} proje desteklenecek" -f $adet) }
                }
                break
              }
            }
            if($tutarAB){ break }
          }
        } catch {}
      }
      if($ozetAB -or $tutarAB){ $yutulanAdet++ }
      $abListe += [ordered]@{
        kaynak="AB"; kod="$($meta.callIdentifier)"; baslik=$baslikAB; durum=$durumAB
        program=$programAB
        acilis=$acilisAB; sonTarih=$sonAB
        tarihler=@()
        ozet=$ozetAB; kim=$kimAB; tutar=$tutarAB; ozetDil="en"
        asama=(AsamaBul ($baslikAB + " " + $kimAB + " " + $abTamMetin))
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
    # Siteye: ACIK en yakin 60 + YAKINDA en yakin 40 (sessiz kirpma degil,
    # gercek toplamlar damgaya yazilir). Havuz Horizon disini da kapsadigi
    # icin sayfalama tavani 10 -> 20 yukseltildi.
    $abAcik = @($tekil | Where-Object { $_.durum -eq 'acik' })
    $abYakin = @($tekil | Where-Object { $_.durum -eq 'yakinda' })
    $secAcik = @($abAcik | Sort-Object { $_.sonTarih } | Select-Object -First 60)
    $secYakin = @($abYakin | Sort-Object { if($_.acilis){ $_.acilis } else { $_.sonTarih } } | Select-Object -First 40)
    $cagrilar += $secAcik
    $cagrilar += $secYakin
    $abGelecekli = @($tekil).Count
    $abAdet = @($secAcik).Count + @($secYakin).Count
    $kaynakDurum["AB"] = "OK (portalda $toplamAB konu tarandi; tarihi gecerli $abGelecekli — açık $(@($abAcik).Count), yakında $(@($abYakin).Count); listede en yakın $abAdet)"
  }
} catch {
  # YARIM OLCUM TAM OLCUM DEGILDIR (19.08 dersi): sayfa ortasinda kopan cekim
  # bayragi TRUE birakirsa eksik liste "OK" yazilir VE eski-veri sigortasi
  # devreye girmez. Kopunca olculemedi sayilir. Mesaj kisa kesilir (kesik JSON
  # istisna metnine tum govdeyi gomuyor - 1 MB'lik log dokmesin).
  $abOlduMu = $false
  $kisa = "$($_.Exception.Message)"; if($kisa.Length -gt 200){ $kisa = $kisa.Substring(0,200) + "..." }
  Write-Host ("  SEDIA hatasi: {0}" -f $kisa)
}
if(-not $abOlduMu){ $kaynakDurum["AB"] = "ÖLÇÜLEMEDİ" }
Write-Host ("AB: {0}" -f $kaynakDurum["AB"])

# --- 4) KALKINMA AJANSLARI (ka.gov.tr) --------------------------------------
# 26 ajansin tum guncel destekleri tek API'de: api/supports (Nuxt arka ucu).
# www degil APEX: www.ka.gov.tr sertifikasi yanlis-principal (olculdu 19.08).
Write-Host "Kalkinma Ajanslari API okunuyor..."
$kaAdet = 0; $kaOlduMu = $false
$kaDosya = Join-Path ([IO.Path]::GetTempPath()) "ka-supports.json"
try {
  $kaListe = @(); $kaSayfa = 1; $kaToplamSayfa = 1; $kaToplam = 0
  while($kaSayfa -le [Math]::Min($kaToplamSayfa, 15)){
    & $curlKomut -sS -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" `
      -o $kaDosya "https://ka.gov.tr/api/supports?filter_details=1&page=$kaSayfa"
    if(-not (Test-Path $kaDosya)){ break }
    $ka = Get-Content $kaDosya -Raw -Encoding UTF8 | ConvertFrom-Json
    if(-not $ka.state){ break }
    $kaToplamSayfa = [int]$ka.info.total_page
    $kaToplam = [int]$ka.info.total
    $kaOlduMu = $true
    foreach($destek in @($ka.data)){
      $bitis = IsoTarih $destek.support_end_date
      # basvurusu gecmis kayit listeye girmez (API "guncel" der ama tarihle de suzeriz)
      if($bitis){
        try { if([datetime]::ParseExact($bitis,"yyyy-MM-dd",$null) -lt $bugun){ continue } } catch {}
      }
      # --- YUTMA (Kalkinma Ajanslari) ----------------------------------------
      # 30.08 OLCULDU: ka.gov.tr API'si YALNIZ ad+tarih+redirect verir - butce ve
      # uygunluk YOK ("bu API'de alan yok" hukmu tahminle degil, alan dokumuyle
      # kuruldu). Bilgi ajansin KENDI ilan sayfasindadir; redirect izlenip metin
      # oradan yutulur. 26 ajans = 26 ayri HTML; bu yuzden desen tabanli, sayfa
      # tanimayan okuma yapilir, tutmazsa alan BOS kalir.
      $kaDetayDosya = Join-Path ([IO.Path]::GetTempPath()) "ka-detay.html"
      Remove-Item $kaDetayDosya -ErrorAction SilentlyContinue
      $yKa = YutSayfa "" ""
      try {
        & $curlKomut -sSL -m 45 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $kaDetayDosya "$($destek.redirect_url)" 2>$null
        if(Test-Path $kaDetayDosya){
          $yKa = YutSayfa (DuzMetin (Get-Content $kaDetayDosya -Raw -Encoding UTF8)) "$($destek.name)"
          if($yKa.ozet -or $yKa.tutar -or $yKa.kim){ $yutulanAdet++ }
        }
      } catch {}
      $kaListe += [ordered]@{
        kaynak="Kalkınma Ajansları"; kod="$($destek.agency_code)".ToUpperInvariant(); baslik="$($destek.name)"; durum="acik"
        acilis=(IsoTarih $destek.support_start_date); sonTarih=$bitis
        tarihler=@()
        ozet=$yKa.ozet; kim=$yKa.kim; tutar=$yKa.tutar
        asama=(&{ if(@($yKa.asama).Count){ ,@($yKa.asama) } else { AsamaBul "$($destek.name)" } })
        url="$($destek.redirect_url)"
      }
      Start-Sleep -Milliseconds 250
    }
    if($kaSayfa -ge $kaToplamSayfa){ break }
    $kaSayfa++
    Start-Sleep -Milliseconds 300
  }
  # imkansiz-veri sigortasi: API "N guncel destek" derken listeye 0 dustuyse olcum bozuktur
  if($kaOlduMu -and $kaToplam -ge 10 -and (@($kaListe).Count) -eq 0){
    Write-Host ("  CELISKI: ka.gov.tr {0} guncel destek diyor ama listeye 0 dustu - olcum bozuk sayildi" -f $kaToplam)
    $kaOlduMu = $false
  }
  if($kaOlduMu){
    $cagrilar += $kaListe
    $kaAdet = @($kaListe).Count
    $kaynakDurum["Kalkınma Ajansları"] = "OK (26 ajansta güncel $kaToplam destek, $kaAdet tanesi listede)"
  }
} catch {
  # ayni yarim-olcum korumasi: sayfa ortasinda kopan KA cekimi de olculemedi sayilir
  $kaOlduMu = $false
  $kisa = "$($_.Exception.Message)"; if($kisa.Length -gt 200){ $kisa = $kisa.Substring(0,200) + "..." }
  Write-Host ("  ka.gov.tr hatasi: {0}" -f $kisa)
}
if(-not $kaOlduMu){ $kaynakDurum["Kalkınma Ajansları"] = "ÖLÇÜLEMEDİ" }
Write-Host ("KALKINMA AJANSLARI: {0}" -f $kaynakDurum["Kalkınma Ajansları"])

# --- 5) TKDK / IPARD (19.08 Cem: "TKDK/IPARD ekle") -------------------------
# Basvuru cagri ilanlari /ProjeIslemleri/CagriIlanArsiv'de EN YENISI USTTE;
# tarihler yalniz ilan PDF'inde -> pdftotext (CI'da poppler kurulu; yerelde Git
# mingw64'te var). PDF'in Turkce harfleri metinde dusebilir ("Bavurular") ->
# desenler ASCII-toleransli yazildi; "son teslim tarihi" zaten saf ASCII.
Write-Host "TKDK cagri ilanlari okunuyor..."
$tkdkAdet = 0; $tkdkOlduMu = $false
$tkdkKok = "https://www.tkdk.gov.tr"
$pdf2txt = $null
$pdfAday = Get-Command pdftotext -ErrorAction SilentlyContinue
if($pdfAday){ $pdf2txt = $pdfAday.Source }
elseif(Test-Path "C:\Program Files\Git\mingw64\bin\pdftotext.exe"){ $pdf2txt = "C:\Program Files\Git\mingw64\bin\pdftotext.exe" }
if(-not $pdf2txt){
  Write-Host "  pdftotext yok - TKDK olculemedi (tarihsiz cagri 'acik' diye gosterilmez)"
} else {
  try {
    $arsivDosya = Join-Path ([IO.Path]::GetTempPath()) "tkdk-arsiv.html"
    & $curlKomut -sS -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $arsivDosya "$tkdkKok/ProjeIslemleri/CagriIlanArsiv"
    $arsivHtml = if(Test-Path $arsivDosya){ Get-Content $arsivDosya -Raw -Encoding UTF8 } else { "" }
    $ilanlar = [regex]::Matches($arsivHtml, '"(/Dokuman/ipard-[^"]*cagri-ilani-\d+)"') |
      ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 2
    if(@($ilanlar).Count){ $tkdkOlduMu = $true }   # arsiv okunabildi
    foreach($ilanYolu in $ilanlar){
      $no = ""; if($ilanYolu -match 'ipard-iii-(\d+)-'){ $no = $Matches[1] }
      $pdfDosya = Join-Path ([IO.Path]::GetTempPath()) "tkdk-ilan.pdf"
      $txtDosya = Join-Path ([IO.Path]::GetTempPath()) "tkdk-ilan.txt"
      Remove-Item $pdfDosya,$txtDosya -ErrorAction SilentlyContinue
      & $curlKomut -sSL -m 90 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $pdfDosya ($tkdkKok + $ilanYolu)
      if(-not (Test-Path $pdfDosya)){ continue }
      & $pdf2txt $pdfDosya $txtDosya 2>$null
      if(-not (Test-Path $txtDosya)){ continue }
      $metin = (Get-Content $txtDosya -Raw -Encoding UTF8) -replace '\s+',' '
      $acilisTk = ""; $sonTk = ""; $tarihlerTk = @()
      if($metin -match 'Ba.?vurular\s+(\d{2}\.\d{2}\.\d{4})\s+tarihi'){ $acilisTk = TrTarihCoz $Matches[1] }
      if($metin -match 'son teslim tarihi\s*(\d{2}\.\d{2}\.\d{4})'){ $sonTk = TrTarihCoz $Matches[1] }
      if($metin -match 'Online Proje Ba.?vuru Sistemi\s+(\d{2}\.\d{2}\.\d{4})'){
        $o = TrTarihCoz $Matches[1]; if($o){ $tarihlerTk += [ordered]@{ etiket="Online sistem kapanış"; tarih=$o } }
      }
      # yalniz son teslimi GELECEKTE olan ilan "acik"tir; tarih cozulemeyen ilan gosterilmez
      if(-not $sonTk){ continue }
      try { if([datetime]::ParseExact($sonTk,"yyyy-MM-dd",$null) -lt $bugun){ continue } } catch { continue }
      # YUTMA: ilan PDF'inin metni ZATEN cikarildi ($metin) - tedbir adlari,
      # kimin basvurabilecegi ve butce orada yazar; eskiden yalniz tarih aliniyordu.
      $yTk = YutSayfa $metin "IPARD III $no. Basvuru Cagri Ilani"
      if($yTk.ozet -or $yTk.tutar -or $yTk.kim){ $yutulanAdet++ }
      $cagrilar += [ordered]@{
        kaynak="TKDK (IPARD)"; kod=(&{ if($no){"IPARD III $no. Çağrı"} else {""} }); baslik="IPARD III $no. Başvuru Çağrı İlanı"
        durum="acik"; acilis=$acilisTk; sonTarih=$sonTk; tarihler=$tarihlerTk
        ozet=$yTk.ozet; kim=$yTk.kim; tutar=$yTk.tutar
        asama=(&{ if(@($yTk.asama).Count){ ,@($yTk.asama) } else { AsamaBul "IPARD tarım kırsal yatırım" } })
        url=($tkdkKok + $ilanYolu)
      }
      $tkdkAdet++
    }
  } catch { Write-Host ("  TKDK hatasi: {0}" -f $_.Exception.Message); $tkdkOlduMu = $false }
}
$kaynakDurum["TKDK (IPARD)"] = if($tkdkOlduMu){ "OK ($tkdkAdet açık ilan — çağrı aralarında 0 olması normal)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("TKDK: {0}" -f $kaynakDurum["TKDK (IPARD)"])

# --- 6) HAMLE - Teknoloji Odakli Sanayi Hamlesi (19.08 Cem: "teshvik almadigimiz
# yer kaldi mi" taramasi) ----------------------------------------------------
# EN VAHIM BOSLUKTU: tesvik sihirbazi 5 yerde "Teknoloji Hamlesi adayisin" diyor
# ama cagrisini izlemiyorduk. Yatirim tesvikinin en ust kademesi (TYKH: %40 YKO,
# makine destegi, m.16). Kaynak: hamle.gov.tr/Home/CagriPlani - cagri adi +
# etiketli tarih ciftleri ("On Basvuru Baslangic/Bitis Tarihi", "Kesin Basvuru
# Bitis Tarihi"). Tarih bicimi "20 Mayis 2026" (TrTarihCoz cozer).
Write-Host "HAMLE cagri plani okunuyor..."
$hamleAdet = 0; $hamleOlduMu = $false
$hamleHtml = GuvenliCek "https://www.hamle.gov.tr/Home/CagriPlani"
if($hamleHtml -and $hamleHtml.Length -gt 5000){
  $hamleOlduMu = $true
  # duz metne indir: etiket ve tarih ayri etiketlerde duruyor
  $duz = ($hamleHtml -replace '(?s)<script.*?</script>',' ') -replace '<[^>]*>',"`n"
  $duz = $duz -replace '&nbsp;',' '
  $satirlar = @($duz -split "`n" | ForEach-Object { ($_ -replace '\s+',' ').Trim() } | Where-Object { $_ })
  # cagri adi: "... Cagrisi" ile biten ilk uzun satir (duyuru basligi)
  $hamleBaslik = ""
  foreach($s in $satirlar){
    if($s.Length -ge 15 -and $s.Length -le 120 -and $s -match 'Ça.r.s.$' -and $s -notmatch 'Önceki|Plan'){ $hamleBaslik = $s; break }
  }
  # etiket -> tarih: etiket satirini takip eden ilk tarih satiri
  $hamleTarihler = @(); $hamleAcilis = ""; $hamleSon = ""
  for($i=0; $i -lt $satirlar.Count; $i++){
    if($satirlar[$i] -notmatch 'Tarihi$'){ continue }
    $etiket = $satirlar[$i]
    for($j=$i+1; $j -lt [Math]::Min($i+4, $satirlar.Count); $j++){
      $coz = TrTarihCoz $satirlar[$j]
      if($coz){
        $hamleTarihler += [ordered]@{ etiket=$etiket; tarih=$coz }
        $normE = Normalize $etiket
        if($normE -match 'baslangic' -and -not $hamleAcilis){ $hamleAcilis = $coz }
        # SON TARIH = kesin basvuru bitisi (on basvuru bitse de cagri surer)
        if($normE -match 'kesin basvuru bitis'){ $hamleSon = $coz }
        break
      }
    }
  }
  # sayfada etiketler iki kez geciyor - mukerrer tarih satirlarini ayikla
  $gorulenT = @{}; $tekilT = @()
  foreach($t in $hamleTarihler){ $ax = "$($t.etiket)|$($t.tarih)"; if(-not $gorulenT.ContainsKey($ax)){ $gorulenT[$ax]=1; $tekilT += $t } }
  $hamleTarihler = $tekilT
  if(-not $hamleSon -and $hamleTarihler.Count){ $hamleSon = ($hamleTarihler | ForEach-Object { $_.tarih } | Sort-Object | Select-Object -Last 1) }
  # yalniz son tarihi GELECEKTE olan cagri "acik"; gecmisse liste disi
  $hamleGecerli = $false
  if($hamleSon){ try { $hamleGecerli = ([datetime]::ParseExact($hamleSon,"yyyy-MM-dd",$null) -ge $bugun) } catch {} }
  if($hamleBaslik -and $hamleGecerli){
    $yHa = YutSayfa (DuzMetin $hamleHtml) $hamleBaslik
    if($yHa.ozet -or $yHa.tutar -or $yHa.kim){ $yutulanAdet++ }
    $cagrilar += [ordered]@{
      kaynak="HAMLE (Teknoloji Odaklı Sanayi Hamlesi)"; kod="TYKH"; baslik=$hamleBaslik; durum="acik"
      acilis=$hamleAcilis; sonTarih=$hamleSon; tarihler=$hamleTarihler
      ozet=$yHa.ozet; kim=$yHa.kim; tutar=$yHa.tutar
      asama=(&{ if(@($yHa.asama).Count){ ,@($yHa.asama) } else { AsamaBul ($hamleBaslik + " yatırım teknoloji") } })
      url="https://www.hamle.gov.tr/Home/CagriPlani"
    }
    $hamleAdet = 1
  }
}
$kaynakDurum["HAMLE"] = if($hamleOlduMu){ "OK ($hamleAdet açık çağrı — çağrı aralarında 0 olması normal)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("HAMLE: {0}" -f $kaynakDurum["HAMLE"])

# --- 7) KKYDP / RG destek tebligleri (19.08 Cem: "KKYDP'yi RG deseniyle
# baglayalim") ----------------------------------------------------------------
# KKYDP basvuru donemleri kurumun portalindan degil RG'de TEBLIG ile acilir
# (kirsalkalkinma.tarimorman.gov.tr 502 veriyor, bakanlik sayfasi SharePoint/JS).
# Ayri robot yerine MEVCUT RG taramasi kullanilir: arac/rg-tarama.ps1 her sabah
# fihristi zaten cekiyor; oraya eklenen desen yakaladigi tebligleri
# veri/rg-destek-cagri.json havuzuna yaziyor. Burada o havuz okunur - EK ISTEK YOK.
# Teblig yayimindan sonra 120 gun listede tutulur (basvuru penceresi tipik olarak
# birkac ay); tarih tebligin kendi metnindedir, uydurulmaz.
Write-Host "KKYDP / RG destek teblig havuzu okunuyor..."
$kkydpAdet = 0; $kkydpOlduMu = $false
$rgHavuzYolu = Join-Path $kokDizin "veri\rg-destek-cagri.json"
if(Test-Path $rgHavuzYolu){
  try {
    $rgHavuz = Get-Content $rgHavuzYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    $kkydpOlduMu = $true    # havuz okunabildi; bos olmasi NORMAL (teblig yilda birkac kez cikar)
    foreach($teblig in @($rgHavuz.tebligler)){
      if(-not $teblig.url){ continue }
      $yayimT = ""
      try { $yayimT = ([datetime]::ParseExact("$($teblig.yayim)","dd.MM.yyyy",$null)).ToString("yyyy-MM-dd") } catch {}
      # yayimdan 120 gun sonra listeden duser (basvuru penceresi kapanmis sayilir)
      if($yayimT){
        try { if([datetime]::ParseExact($yayimT,"yyyy-MM-dd",$null) -lt $bugun.AddDays(-120)){ continue } } catch {}
      }
      $cagrilar += [ordered]@{
        kaynak="KKYDP / RG tebliği"; kod="RG"; baslik=$teblig.baslik; durum="acik"
        acilis=$yayimT; sonTarih=""
        tarihler=@()
        # teblig metni havuzda tutulmuyor - kim/tutar BOS birakilir (kor kalma
        # kurali: olcemedigimiz alani doldurmayiz), asama basliktan turetilir.
        ozet=""; kim=""; tutar=""
        asama=(AsamaBul "$($teblig.baslik) tarım kırsal kalkınma yatırım")
        url=$teblig.url
      }
      $kkydpAdet++
    }
  } catch { Write-Host "  RG havuzu okunamadi" }
}
$kaynakDurum["KKYDP / RG tebliği"] = if($kkydpOlduMu){ "OK ($kkydpAdet açık tebliğ — RG taramasından; 0 olması normal, tebliğ yılda birkaç kez çıkar)" } else { "ÖLÇÜLEMEDİ" }
Write-Host ("KKYDP: {0}" -f $kaynakDurum["KKYDP / RG tebliği"])

# --- kor kalma + eski veriyi koruma -----------------------------------------
$KAYNAK_SAYISI = 7
$olculenler = @()
if($tubitakOlduMu){ $olculenler += "TÜBİTAK" }
if($kosgebOlduMu){ $olculenler += "KOSGEB" }
if($abOlduMu){ $olculenler += "AB" }
if($kaOlduMu){ $olculenler += "Kalkınma Ajansları" }
if($tkdkOlduMu){ $olculenler += "TKDK (IPARD)" }
if($hamleOlduMu){ $olculenler += "HAMLE" }
if($kkydpOlduMu){ $olculenler += "KKYDP / RG tebliği" }
if(-not $olculenler.Count){
  Write-Host "HATA: kaynaklarin hicbiri olculemedi - dosyaya DOKUNULMADI (eski veri korunur)"
  exit 1
}
if((Test-Path $ciktiYolu) -and ($olculenler.Count -lt $KAYNAK_SAYISI)){
  try {
    $eski = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($eskiKayit in @($eski.cagrilar)){
      # kaynak adi zamanla degisebilir ("AB (Ufuk Avrupa)" -> "AB"): ONEK
      # eslesmesi yapilir, yoksa ayni kaynagin eski kayitlari MUKERRER eklenir.
      $eskiAd = "$($eskiKayit.kaynak)"
      $olculdu = $false
      foreach($o in $olculenler){ if($eskiAd.StartsWith($o) -or $o.StartsWith($eskiAd)){ $olculdu = $true; break } }
      if(-not $olculdu){
        # 30.08: yutulan alanlar da TASINIR - yoksa olculemeyen kaynagin eski
        # kayitlari bilgisini kaybeder ve kart yeniden "Cagri duyurusunda" der.
        $cagrilar += [ordered]@{
          kaynak=$eskiKayit.kaynak; kod="$($eskiKayit.kod)"; baslik=$eskiKayit.baslik; durum=$eskiKayit.durum
          program="$($eskiKayit.program)"
          acilis="$($eskiKayit.acilis)"; sonTarih="$($eskiKayit.sonTarih)"
          tarihler=@($eskiKayit.tarihler | ForEach-Object { [ordered]@{ etiket=$_.etiket; tarih=$_.tarih } })
          ozet="$($eskiKayit.ozet)"; kim="$($eskiKayit.kim)"; tutar="$($eskiKayit.tutar)"
          ozetDil="$($eskiKayit.ozetDil)"
          asama=@($eskiKayit.asama)
          url=$eskiKayit.url
        }
      }
    }
  } catch { Write-Host "NOT: eski json okunamadi, yalniz taze kaynaklar yazilir" }
}

# --- kaynak saglik damgasi (19.08 KOSGEB dersi) ------------------------------
# "okunuyor + 0 sonuc = normal" varsayimi bir kez kor birakti. Her kaynagin
# BU KOSUDA urettigi kayit sayisi ve son uretim tarihi damgaya yazilir; bir
# kaynak uzun suredir 0 uretiyorsa denetimde hemen gorunur.
$eskiSaglik = @{}
if(Test-Path $ciktiYolu){
  try {
    $onceki = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($k in @($onceki.kaynaklar)){ if($k.sonUretim){ $eskiSaglik["$($k.ad)"] = "$($k.sonUretim)" } }
  } catch {}
}
function SaglikDamgasi([string]$ad){
  $adet = @($cagrilar | Where-Object { "$($_.kaynak)".StartsWith($ad) }).Count
  if($adet -gt 0){ return (Get-Date -Format "yyyy-MM-dd") }
  if($eskiSaglik.ContainsKey($ad)){ return $eskiSaglik[$ad] }
  return ""
}

$cikti = [ordered]@{
  guncelleme = "Kaynaklar dogrudan kurum sitelerinden robotla cekildi. Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynaklar = @(
    [ordered]@{ ad="TÜBİTAK"; url="https://tubitak.gov.tr/tr/destekler/sanayi/ulusal-destek-programlari"; durum=$kaynakDurum["TÜBİTAK"]; sonUretim=(SaglikDamgasi "TÜBİTAK") }
    [ordered]@{ ad="KOSGEB"; url="https://www.kosgeb.gov.tr"; durum=$kaynakDurum["KOSGEB"]; sonUretim=(SaglikDamgasi "KOSGEB") }
    [ordered]@{ ad="AB"; url="https://ec.europa.eu/info/funding-tenders/opportunities/portal/screen/opportunities/calls-for-proposals"; durum=$kaynakDurum["AB"]; sonUretim=(SaglikDamgasi "AB") }
    [ordered]@{ ad="Kalkınma Ajansları"; url="https://ka.gov.tr/destekler"; durum=$kaynakDurum["Kalkınma Ajansları"]; sonUretim=(SaglikDamgasi "Kalkınma") }
    [ordered]@{ ad="TKDK (IPARD)"; url="https://www.tkdk.gov.tr/ProjeIslemleri/CagriIlanArsiv"; durum=$kaynakDurum["TKDK (IPARD)"]; sonUretim=(SaglikDamgasi "TKDK") }
    [ordered]@{ ad="HAMLE"; url="https://www.hamle.gov.tr/Home/CagriPlani"; durum=$kaynakDurum["HAMLE"]; sonUretim=(SaglikDamgasi "HAMLE") }
    [ordered]@{ ad="KKYDP / RG tebliği"; url="https://www.resmigazete.gov.tr"; durum=$kaynakDurum["KKYDP / RG tebliği"]; sonUretim=(SaglikDamgasi "KKYDP / RG tebliği") }
  )
  cagrilar = $cagrilar
}
($cikti | ConvertTo-Json -Depth 6) | Out-File $ciktiYolu -Encoding utf8

# yazma sonrasi sayim (yesil kosu != tam veri dersi)
$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("CAGRI HASAT: {0} cagri yazildi ({1}) -> veri/cagri-radar.json [geri okuma: {2}]" -f @($cagrilar).Count, ($olculenler -join "+"), @($geriOkuma.cagrilar).Count)
if(@($geriOkuma.cagrilar).Count -ne @($cagrilar).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }

# --- YUTMA KARNESI (30.08) ---------------------------------------------------
# "kac kayit yazildi" yetmez, "kac kayit BILGI TASIYOR" olculur. Sayilar
# GERI OKUNAN dosyadan uretilir - bellekteki degiskenden degil.
$gc = @($geriOkuma.cagrilar)
$doluTutar = @($gc | Where-Object { "$($_.tutar)".Trim() }).Count
$doluKim   = @($gc | Where-Object { "$($_.kim)".Trim() }).Count
$doluOzet  = @($gc | Where-Object { "$($_.ozet)".Trim() }).Count
$doluAsama = @($gc | Where-Object { @($_.asama).Count -gt 0 }).Count
Write-Host ("YUTMA KARNESI: ozet {0}/{1} · kim {2}/{1} · tutar {3}/{1} · asama {4}/{1}" -f $doluOzet, $gc.Count, $doluKim, $doluTutar, $doluAsama)
$bosKaynak = @()
foreach($grup in ($gc | Group-Object kaynak)){
  $g = @($grup.Group | Where-Object { "$($_.ozet)".Trim() -or "$($_.tutar)".Trim() -or "$($_.kim)".Trim() }).Count
  Write-Host ("  {0}: {1}/{2} kayitta bilgi var" -f $grup.Name, $g, $grup.Count)
  if($g -eq 0 -and $grup.Count -gt 0){ $bosKaynak += $grup.Name }
}
# Kor kalma kurali: bir kaynagin HICBIR kaydinda bilgi cikmadiysa desen bozulmus
# olabilir - alarm verilir ama dosya yazildigi icin cikis 0 kalir (eski davranis
# bozulmaz); denetimde gorunur.
if($bosKaynak.Count){ Write-Host ("UYARI: su kaynaklarda hicbir kayittan bilgi cikmadi (desen bozulmus olabilir): {0}" -f ($bosKaynak -join ", ")) }
