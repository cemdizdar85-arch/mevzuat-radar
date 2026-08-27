# ============================================================================
#  STANDART YUTUCU (TAM) — 25.08.2026
#  Cem: "yuttugumuz seyin ... bundan sonra okusan bile YARIM KALMAYACAK
#        sekile getir" · "eski yarim okunan varsa onlari tumden oku"
#
#  NEDEN VAR: 25.08'de butunluk kapisi standartlarin YARIM yutuldugunu olctu.
#  Daha kotusu: YUTMA-LISTESI.md "TFRS 16 TAM YUTULDU: 122 parca / 129.771
#  karakter" diyor ama ambarda 12 parca / 15.913 karakter var - yani KAYIT
#  YAPILDIGINI SOYLUYOR, AMBARDA YOK. Ayni sey BDS 300 (38 iddia / 13 gercek)
#  ve BDS 330'da da (96 iddia / 6 gercek) cikti.
#
#  ⚠ BU YUZDEN BU BETIK KENDI ISINI DOGRULAR: yazdiktan SONRA ambardan GERI
#  OKUR ve parca sayisi + karakter toplamini karsilastirir. Tutmuyorsa
#  KIRMIZI verir. "Yesil kosu != is yapildi" dersinin yutma hattindaki karsiligi.
#
#  YOL: PDF indir -> ilk 4 bayt %PDF mi (ASCII'lesmis ad HTML doner) ->
#       pdftotext -> paragraf numarasi kendi satirinda (^\d+$) -> boyle bol ->
#       eski kayitlari YEDEKLE -> sil -> yaz -> GERI OKU -> karsilastir.
#
#  Varsayilan KURU PROVA. Yazmak icin -uygula gerekir.
#  0 USD, model yok.
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$standart,   # ornek: 'TFRS 16'
  [string]$url = '',                                # bos ise KGK kalibindan kurulur
  [int]$yil = 2026,
  [switch]$uygula,
  [switch]$kucultmeyeOnayVer,
  [switch]$duzen            # pdftotext -layout: iki sutunlu sayfalarda sutunlari korur
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function SY_PdfAraci {
  foreach($a in @('C:\Program Files\Git\mingw64\bin\pdftotext.exe','C:\Program Files (x86)\Git\mingw64\bin\pdftotext.exe')){
    if(Test-Path $a){ return $a }
  }
  $c=Get-Command pdftotext -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return ''
}

function SY_Bol([string]$metin, [string]$std){
  # ⚠ 25.08 DERSI — ILK SURUM STANDARDIN EKLERINI TUMUYLE ATLIYORDU.
  # Paragraf numarasi kendi satirinda durur (^\d+$) ve ilk surum yalniz onu
  # ariyordu. Oysa standardin EN DEGERLI bolumu ekte olabilir:
  #   Ek A "Tanimlanan terimler" -> SOZLUK bicimi, NUMARA YOK (terim satiri +
  #        altinda tanimi). TFRS 16'da "kullanim hakki varligi" tanimi BURADA.
  #   Ek B "Uygulama rehberi"    -> B9, B33 ... bazen kendi satirinda, bazen
  #        satir basinda metinle birlikte ("C21 Bu Standart ...").
  #   Ek C "Yururluk ve gecis"   -> C1, C20D, C20E (harf sonekli olabilir).
  # Ek A yoksa uretici tanimi HAFIZADAN yazmak zorunda kalir = kural ihlali.
  # ⚠⚠ IKI AYRI DUZEN VAR — 25.08'de BDS PROVASINDA bulundu.
  #   TMS/TFRS : paragraf numarasi KENDI SATIRINDA durur ("5" tek basina)
  #   BDS/GDS  : numara SATIR BASINDA metinle BIRLIKTE ("5. BDS'ler, bir ...")
  # BDS metninde tek basina duran sayilar SAYFA NUMARALARIDIR. TMS kipini
  # BDS'ye uygulamak sayfa numaralarini paragraf sanmak, gercek paragraflari
  # ise hic gormemek demekti - yani 30 standardi birden coplemek.
  # BDS 200 provasinda olculdu: 27 adet "^N$" (hepsi sayfa no) · 24 adet
  # "^N. metin" (gercek paragraflar) · 34 adet "^AN. metin" (ek paragraflari).
  # Bu yuzden kip METINDEN SECILIR, elle verilmez: hangi desen baskinsa o.
  $satirlar = $metin -split "`r?`n"
  $tekBasina = @($satirlar | Where-Object { $_.Trim() -match '^\d{1,3}$' }).Count
  $satirBasi = @($satirlar | Where-Object { $_.Trim() -match '^A?\d{1,3}\.\s+\S' }).Count
  $satirBasiKip = ($satirBasi -gt $tekBasina)
  $parcalar = New-Object System.Collections.Generic.List[object]
  $baslik = ''
  $suAn = $null
  $sozlukModu = $false          # Ek A: numarasiz terim-tanim sozlugu
  foreach($ham in $satirlar){
    $s = $ham.Trim()

    # --- EK basliklari: kip degistirir
    if($s -match '^Ek\s+A\b'){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$true; $baslik='Ek A - Tanımlanan terimler'; continue }
    if($s -match '^Ek\s+([B-Z])\b'){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$false; $baslik=$s; continue }

    # --- SOZLUK KIPI, NUMARA KONTROLUNDEN ONCE GELMELI -------------------
    # ⚠ 25.08 DERSI (ucuncu deneme): sozluk kontrolu numara kontrolunun
    # ALTINDAYDI ve Ek A'nin ORTASINDAKI SAYFA NUMARASI (bare "17") sozluk
    # kipini KAPATIYORDU. Sonuc: Ek A'nin yalniz ilk sayfasi alindi ve tam da
    # aradigimiz "kullanim hakki varligi" tanimi disarida kaldi - yani kapi
    # gecti, is yarim kaldi. Ek A'yi YALNIZ bir sonraki "Ek X" basligi bitirir.
    if($sozlukModu){
      if($null -eq $suAn){
        $suAn = [ordered]@{ onek='A'; no=0; sonek=''; ekBlok=$true; baslik='Ek A - Tanımlanan terimler'; govde=New-Object System.Collections.Generic.List[string] }
      }
      if($s.Length -gt 0 -and $s -notmatch '^\d{1,3}$'){ $suAn.govde.Add($s) }   # sayfa numarasi metne girmez
      continue
    }

    # --- BDS/GDS KIPI: numara satir basinda metinle birlikte -------------
    # "10. Bu BDS ... yururluge girer."   ya da   "A3. Finansal tablolarin ..."
    # Bolum basligi da ayni satirda one gelebilir:
    #   "Yururluk Tarihi 10. Bu BDS, 1/1/2017 tarihinde ..."
    # ⚠ 25.08 GECE, iki ince ayar:
    #   (1) onek tavani 60 -> 110: "Ileriye Yonelik Finansal Bilgilere Iliskin
    #       Denetci Tarafindan Verilen Guvence 8. ..." gibi UZUN basliklarin
    #       arkasindaki paragraflar (GDS 3400 p.8/27, BDS 501 A9...) kacmasin.
    #   (2) kucuk harf freni: capraz atif "(Bkz.: A11. paragrafi). Onceki..."
    #       satiri sahte bir p.A11 baslatiyordu - govdesi "paragrafi)..." diye
    #       KUCUK harfle baslar. Gercek paragraf govdesi kucuk harfle baslamaz.
    if($satirBasiKip -and $s -match '^(?:(.{0,110}?)\s+)?(A?)(\d{1,3})\.\s+(\S.{5,})$' -and -not ($Matches[4] -cmatch '^[a-zçğıöşü]')){
      # ⚠⚠ ONCE GRUPLARI KOPYALA. PowerShell'de HER -match/-notmatch/-cmatch
      # $Matches'i YENIDEN YAZAR. Ilk surumde asagidaki baslik kontrolu
      # ($onParca -notmatch ...) $Matches'i eziyordu ve sonraki satirdaki
      # $Matches[2..4] BASKA bir eslesmeye bakiyordu -> BDS oz-sinavi 4 yerine
      # 2 parca cikardi. Sinav olmasaydi bu, 30 BDS'de sessizce ice islerdi.
      $gOnEk   = $Matches[2]
      $gNo     = [int]$Matches[3]
      $gGovde  = $Matches[4]
      $onParca = if($Matches[1]){ $Matches[1].Trim() } else { '' }
      if($suAn){ $parcalar.Add($suAn) }
      # Onceki paragrafin SON CUMLESI de bu yakalamaya girebilir
      # ("...zorunlu kilar. 6. Onemlilik kavrami ...") ve "zorunlu kilar."
      # baslik sanilir. Baslik NOKTALAMAYLA BITMEZ ve BUYUK harfle baslar.
      # Onun disindaki on-parca ONCEKI PARAGRAFIN GOVDESIDIR - atilmaz.
      if($onParca){
        if($onParca -notmatch '[.;:!?]$' -and $onParca -cmatch '^[A-ZÇĞİÖŞÜ]'){ $baslik = $onParca }
        elseif($parcalar.Count -gt 0){ $parcalar[$parcalar.Count-1].govde.Add($onParca) }
      }
      $suAn = [ordered]@{ onek=$gOnEk; no=$gNo; sonek=''; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($gGovde)
      continue
    }
    # BDS kipinde TEK BASINA duran sayi = SAYFA NUMARASI, paragraf DEGIL.
    if($satirBasiKip -and $s -match '^\d{1,3}$'){ continue }

    # --- numarali paragraf: 12 · A1 · B9 · C20D   (kendi satirinda)
    if((-not $satirBasiKip) -and $s -match '^([A-D]?)(\d{1,3})([A-Z]?)$'){
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu = $false
      $suAn = [ordered]@{ onek=$Matches[1]; no=[int]$Matches[2]; sonek=$Matches[3]; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      continue
    }
    # --- numara SATIR BASINDA metinle birlikte: "C21 Bu Standart ..."
    # ⚠ 25.08 gece: "A11 paragrafı)." gibi satir sonuna sarkan CAPRAZ ATIF da
    # bu dala dusuyordu (kip kontrolu yok) ve sahte p.A11 uretiyordu. Ayni
    # kucuk harf freni burada da gecerli: gercek govde kucuk harfle baslamaz.
    if($s -match '^([A-D])(\d{1,3})([A-Z]?)\s+(\S.{10,})$' -and -not ($Matches[4] -cmatch '^[a-zçğıöşü]')){
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu = $false
      $suAn = [ordered]@{ onek=$Matches[1]; no=[int]$Matches[2]; sonek=$Matches[3]; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($Matches[4])
      continue
    }
    if($s.Length -eq 0){ continue }

    # --- SOZLUK KIPI (Ek A) ---------------------------------------------
    # ⚠ 25.08 DERSI: once terim-tanim ESLESTIRMEYE calistim, YANLISTI.
    # KGK'nin Ek A'si IKI SUTUNLU bir tablodur; pdftotext duzlestirince once
    # BUTUN TERIMLER (satir basina ikiser, sutunlar birlesmis), sonra BUTUN
    # TANIMLAR geliyor. Yani terim ile tanimi metinde YAN YANA DEGIL.
    # Bu metinden eslestirme yapmak UYDURMAK olur - kaynakta olmayan bir
    # baglanti kurmak demektir (E3-f'in ihlali). Uc "tanim" cikti ve kritik
    # olan "kullanim hakki varligi" hic gelmedi; sahte yapi hem eksik hem
    # yaniltici oldu.
    # DOGRUSU: yapiyi UYDURMA, METNI TAM SAKLA. Ek A butun olarak alinir ve
    # boyuta gore parcalanir. Uretici "kullanim hakki varligi" ararken metni
    # bulur; sahte bir terim-tanim cifti gormez.
    # kisa, noktasiz, buyuk harfle baslayan satir = bolum basligi
    # ⚠ 25.08 gece: "...yurutulur.18" gibi DIPNOT NUMARASIYLA biten cumle
    # satiri noktayla bitmedigi icin baslik saniliyor ve govdeden DUSUYORDU
    # (BDS 805 p.A4'un ikinci satiri boyle kayboldu). Nokta+rakam = cumle sonu.
    if($s.Length -le 70 -and $s -notmatch '[.:;]$' -and $s -notmatch '[.!?][0-9]{1,3}$' -and $s -cmatch '^[A-ZÇĞİÖŞÜ]' -and ($null -eq $suAn -or $suAn.govde.Count -gt 0)){
      $baslik = $s
      continue
    }
    # ⚠ ILK PARAGRAF NUMARASINDAN ONCEKI METIN — 25.08'de KAYBOLUYORDU.
    # Standardin basinda "GUNCELLEMELER VE YURURLUK TARIHLERI · ... Resmi
    # Gazete'de yayimlanmistir" kunyesi durur. $suAn henuz kurulmadigi icin
    # bu satirlar hicbir parcaya girmiyordu ve dort standartta yeni cikarim
    # eskisinden AZ metin verdi (TMS 37 −4.518 · TMS 20 −1.743 · TMS 7 −859).
    # Kunye ATILACAK metin degil: RG tarihi ve degisiklik gecmisi ORADA -
    # damga ve guncellik denetiminin ihtiyaci olan bilgi. p.0 olarak saklanir.
    if($null -eq $suAn){
      $suAn = [ordered]@{ onek=''; no=0; sonek=''; kunye=$true; baslik='Künye ve yürürlük'; govde=New-Object System.Collections.Generic.List[string] }
    }
    $suAn.govde.Add($s)
  }
  if($suAn){ $parcalar.Add($suAn) }
  # kayda cevir
  $kayitlar = New-Object System.Collections.Generic.List[object]
  foreach($p in $parcalar){
    $govde = (@($p.govde) -join ' ').Trim()
    # ⚠ ICERIK ATILMAZ (25.08 dersi). Ilk surum govdesi 20 karakterden kisa
    # olani "bos paragraf" sayip ATIYORDU; sozluk kipinde satir sonu kirilan
    # kisa satirlar boyle terim sanilip dusuyordu ve TOPLAM KARAKTER AZALIYORDU.
    # 210 parca / 105.905 krk, 128 parca / 106.600 krk'den AZDI - parca
    # kazanirken metin kaybediyorduk. Cozum: kisa parcayi ATMA, BIR ONCEKINE EKLE.
    # Butun mesele "yarim kalmasin" idi; kirpip parca sayisi buyutmek onu bozar.
    if($govde.Length -lt 20){
      $ekMetin = (($(if($p.Contains('terim')){ "$($p.terim) " } else { '' }) + $govde)).Trim()
      if($ekMetin.Length -gt 0 -and $kayitlar.Count -gt 0){
        $kayitlar[$kayitlar.Count-1].metin = ($kayitlar[$kayitlar.Count-1].metin + ' ' + $ekMetin).Trim()
      }
      continue
    }
    if($p.Contains('ekBlok') -and $p.ekBlok){
      # Ek A butun blok: boyuta gore parcala (~1800 karakter), sirayi koru.
      $dilimBoyu = 1800
      $kalan = $govde
      $sira = 0
      $toplamDilim = [Math]::Max(1,[Math]::Ceiling($govde.Length / [double]$dilimBoyu))
      while($kalan.Length -gt 0){
        $sira++
        $al = [Math]::Min($dilimBoyu,$kalan.Length)
        if($al -lt $kalan.Length){
          # kelime ortasindan kesme
          $bosluk = $kalan.LastIndexOf(' ',$al-1)
          if($bosluk -gt ($dilimBoyu*0.6)){ $al = $bosluk }
        }
        $dilim = $kalan.Substring(0,$al).Trim()
        $kalan = $kalan.Substring($al).Trim()
        if($dilim.Length -eq 0){ break }
        $kayitlar.Add([pscustomobject]@{ kaynak_ad="$std Ek A - Tanımlanan terimler [$sira/$toplamDilim]"; metin=$dilim })
      }
      continue
    }
    if($false){
      $ad = ''
    } else {
      $etiket = "p." + $p.onek + $p.no + $p.sonek
      $ad = "$std $etiket" + $(if($p.baslik){ " - $($p.baslik)" } else { '' })
    }
    if($ad.Length -gt 160){ $ad = $ad.Substring(0,160) }
    $kayitlar.Add([pscustomobject]@{ kaynak_ad=$ad; metin=$govde })
  }
  # ⚠ "return ,$kayitlar" YAZMA. Virgul listeyi SARMALAR ve cagirandaki @()
  # onu ACMAZ -> tek elemanli dizi doner. Bu tuzak 25.08'de UC KEZ vurdu
  # (kart-kontrol · kesik-metin-nobeti · burada). ToArray() net cozum.
  return $kayitlar.ToArray()
}

function SY_LayoutGerekli([string]$metin, [string]$std){
  # ⚠ 25.08 GECE DERSI — 16 BDS/GDS'DE A-SERISI SESSIZCE KAYBOLDU.
  # Bu PDF'lerde varsayilan (okuma sirasi) cikarim paragraf numaralarini
  # SATIR ORTASINA gomuyor ("Giris Kapsam 1. Bu Bagimsiz..."). Kip sayaci
  # satir basindaki numarayi bulamayinca TMS kipine dusuyor ve tek basina
  # duran SAYFA numaralarini paragraf saniyordu: BDS 230 "15 parca" = 14 sayfa
  # + kunye. Parca sayisi makul, karakter toplami TAM oldugu icin kuculme
  # freni de otmedi - prova temiz gorundu, A-serisi hic yazilmadi.
  # KURAL: BDS/GDS metninde satir basi numara sayisi tek basina duran sayi
  # sayisini GECMIYORSA cikarim bozuktur -> -layout ile yeniden cikar.
  if($std -notmatch '^(BDS|GDS)\s'){ return $false }
  $sat = $metin -split "`r?`n"
  $tek = @($sat | Where-Object { $_.Trim() -match '^\d{1,3}$' }).Count
  $sb  = @($sat | Where-Object { $_.Trim() -match '^A?\d{1,3}\.\s+\S' }).Count
  return ($sb -le $tek)
}

function SY_OzSinav {
  # KAPI KENDI SINAVINI GECMELI.
  # SINANMAYAN DALLAR: PDF indirme · pdftotext cagrisi · ambar yazimi ·
  #                    geri okuma karsilastirmasi. Burada YALNIZ BOLME sinanir.
  $dusen=@()
  $ornek = @"
Amaç

1

Bu Standart, kiralamalarin finansal tablolara alinmasina iliskin ilkeleri belirler.

Bu ilkeler tum isletmeler icin gecerlidir.

2

Isletme bu Standardi uygularken sozlesmelerin hukum ve kosullarini dikkate alir.

Kapsam

3

Isletme bu Standardi tum kiralamalara uygular.

Tanımlar

A1

Kiralama, bir varligin kullanim hakkini belirli bir sure icin devreden sozlesmedir.
"@
  $c = @(SY_Bol $ornek 'TEST 1')
  if($c.Count -ne 4){ $dusen += "BOLME SAYISI YANLIS: beklenen 4, cikan $($c.Count)" ; return $dusen }
  if($c[0].kaynak_ad -ne 'TEST 1 p.1 - Amaç'){ $dusen += "1. parca adi yanlis: '$($c[0].kaynak_ad)'" }
  if($c[2].kaynak_ad -ne 'TEST 1 p.3 - Kapsam'){ $dusen += "3. parca adi yanlis: '$($c[2].kaynak_ad)'" }
  if($c[3].kaynak_ad -ne 'TEST 1 p.A1 - Tanımlar'){ $dusen += "EK parcasi yanlis: '$($c[3].kaynak_ad)'" }
  # 1. paragrafin IKI cumlesi de alinmis mi (govde birlestirme)
  if($c[0].metin -notmatch 'tum isletmeler icin gecerlidir'){ $dusen += '1. paragrafin ikinci cumlesi KAYIP - govde birlestirme bozuk' }
  # numarasi olup govdesi olmayan satir atlanmis mi
  $bos = @(SY_Bol "Baslik`n`n7`n`n`n8`n`nGercek govde burada yeterince uzun bir cumledir." 'TEST 2')
  if($bos.Count -ne 1){ $dusen += "BOS PARAGRAF ATLANMADI: $($bos.Count) parca cikti, 1 bekleniyordu" }

  # --- EK DALLARI (25.08: ilk surum EKLERI TUMUYLE ATLIYORDU) ---
  $ekOrnek = @"
1

Ana govde paragrafi burada yer alir ve yeterince uzundur.

Ek A Tanımlanan terimler

kullanım hakkı varlığı

Kiralama suresi boyunca kiracinin dayanak varligi kullanma hakkini temsil eden bir varliktir.

kira ödemeleri

Dayanak varligin kullanim hakki icin kiraci tarafindan kiraya verene yapilan odemelerdir.

Ek B Uygulama rehberi

B9

Bir sozlesmenin kiralama icerip icermedigi degerlendirilirken su unsurlar dikkate alinir.

Ek C Yürürlük tarihi ve geçiş

C21 Bu Standart asagidaki Standart ve Yorumlarin yerini alir ve gecerlidir.
"@
  $e = @(SY_Bol $ekOrnek 'TEST 3')
  # EK A: terim-tanim ESLESTIRMESI BEKLENMEZ (iki sutunlu tabloda guvenilmez).
  # Beklenen: Ek A metninin TAMAMI ambara giriyor mu - yani hicbir terim ve
  # hicbir tanim disarida kalmiyor mu. Olcut ICERIK, yapi degil.
  $ekA = @($e | Where-Object { $_.kaynak_ad -match 'Ek A' })
  if($ekA.Count -lt 1){ $dusen += 'EK A HIC ALINMADI' }
  else {
    $ekMetin = ($ekA | ForEach-Object { $_.metin }) -join ' '
    foreach($aranan in @('kullanım hakkı varlığı','kira ödemeleri','Kiralama suresi boyunca','kiraya verene yapilan odemelerdir')){
      if($ekMetin -notmatch [regex]::Escape($aranan)){ $dusen += "EK A ICERIK KAYIP: '$aranan' yok" }
    }
  }
  $ekB = @($e | Where-Object { $_.kaynak_ad -match 'p\.B9' })
  if($ekB.Count -ne 1){ $dusen += "EK B p.B9 bulunamadi ($($ekB.Count))" }
  # --- BDS/GDS DUZENI (25.08 provasinda bulundu: numara SATIR BASINDA) ---
  # Bu dal sinanmadan BDS toplu kosulursa 30 standart birden coplenir:
  # TMS kipi BDS metninde yalniz SAYFA NUMARALARINI gorur.
  $bdsOrnek = @"
Kapsam 1. Bu Bagimsiz Denetim Standardi, denetcinin genel sorumluluklarini duzenler.

2. BDS'ler bir denetcinin finansal tablolari denetlemesine yonelik hazirlanmistir.

6

Yururluk Tarihi 10. Bu BDS, 1/1/2017 tarihinde yururluge girer.

A3. Finansal tablolarin yonetim tarafindan hazirlanmasi soz konusudur.
"@
  $b = @(SY_Bol $bdsOrnek 'BDS 200')
  if($b.Count -ne 4){ $dusen += "BDS KIPI: 4 parca bekleniyordu, $($b.Count) cikti" }
  else {
    if($b[0].kaynak_ad -ne 'BDS 200 p.1 - Kapsam'){ $dusen += "BDS 1. parca adi yanlis: '$($b[0].kaynak_ad)'" }
    if($b[2].kaynak_ad -notmatch 'p\.10 - Yururluk Tarihi'){ $dusen += "BDS baslik satir icinden alinamadi: '$($b[2].kaynak_ad)'" }
    if($b[3].kaynak_ad -notmatch 'p\.A3'){ $dusen += "BDS ek paragrafi (A3) cozulemedi: '$($b[3].kaynak_ad)'" }
    if(($b | ForEach-Object { $_.metin }) -join ' ' -match '(?m)^6$'){ $dusen += 'BDS: SAYFA NUMARASI metne girdi' }
  }
  $ekC = @($e | Where-Object { $_.kaynak_ad -match 'p\.C21' })
  if($ekC.Count -ne 1){ $dusen += "SATIR BASI NUMARA ('C21 Bu Standart...') cozulemedi ($($ekC.Count))" }
  elseif($ekC[0].metin -notmatch 'yerini alir'){ $dusen += 'SATIR BASI NUMARADA govde kayip' }

  # --- UZUN BASLIK + SAHTE ATIF (25.08 gece) -----------------------------
  $uzunOrnek = @"
1. Bu GDS ileriye yonelik finansal bilgilerin incelenmesini duzenler.

2. Denetci bu GDS'yi incelemelerde uygular ve kanit toplar.

Ileriye Yonelik Finansal Bilgilere Iliskin Denetci Tarafindan Verilen Guvence Duzeyi Hakkinda 8. Ileriye yonelik finansal bilgiler gelecege iliskindir ve subjektif varsayimlara dayanir.

Karsilastirmali Finansal Tablolar (Bkz.: A11. paragrafi). Onceki Denetci Tarafindan Denetlenmis Olan Finansal Tablolar
"@
  $u = @(SY_Bol $uzunOrnek 'GDS 3400')
  $p8 = @($u | Where-Object { $_.kaynak_ad -match 'p\.8' })
  if($p8.Count -ne 1){ $dusen += "UZUN BASLIK: 60+ karakterlik baslik arkasindaki p.8 cozulemedi ($($p8.Count))" }
  if(@($u | Where-Object { $_.kaynak_ad -match 'p\.A11' }).Count -ne 0){ $dusen += 'SAHTE ATIF: "(Bkz.: A11. paragrafi)" sahte parca baslatti' }

  # --- SATIR SONUNA SARKAN ATIF + DIPNOTLA BITEN SATIR (25.08 gece) -------
  # "A11 paragrafı)." tek basina bir satira sarkinca C21-dali sahte p.A11
  # uretiyordu; "...yurutulur.18" (dipnot numarasiyla biten cumle) ise baslik
  # sanilip GOVDEDEN dusuyordu (BDS 805 p.A4).
  $sarkanOrnek = @"
1. Bu BDS tek bir finansal tablonun denetimini duzenler ve kapsami belirler.

2. Denetci bu BDS'yi uygularken kanit toplar ve degerlendirir.

A4. Tarihi finansal bilgilerin denetimi disindaki bir makul guvence denetimi, Guvence Denetimi
Standardi (GDS) 3000'e uygun olarak yurutulur.18

Karsilastirmali Bilgiler (Bkz.: A10 ve
A11 paragrafı).

A12. Mevzuat denetcinin raporunda farkli bir bicim ongorebilir.
"@
  $sk = @(SY_Bol $sarkanOrnek 'BDS 805')
  if(@($sk | Where-Object { $_.kaynak_ad -match 'p\.A11\b' }).Count -ne 0){ $dusen += 'SARKAN ATIF: "A11 paragrafı)." sahte parca baslatti' }
  $a4 = @($sk | Where-Object { $_.kaynak_ad -match 'p\.A4\b' })
  if($a4.Count -ne 1){ $dusen += "DIPNOT SATIRI: p.A4 bulunamadi ($($a4.Count))" }
  elseif($a4[0].metin -notmatch "3000'e uygun olarak yurutulur"){ $dusen += 'DIPNOT SATIRI: "...yurutulur.18" satiri baslik sanildi, govdeden dustu' }

  # --- LAYOUT GEREKLILIK KARARI (25.08 gece: 16 BDS'de A-serisi kaybi) ---
  # Bozuk cikarim: numaralar satir ortasinda, yalniz sayfa numaralari satir basinda.
  $bozuk = "Giris Kapsam 1. Bu BDS denetcinin sorumluluklarini duzenler.`n2`n`nBaslik 2. Ikinci paragraf da satir ortasinda basliyor.`n3`n`n4`n"
  if(-not (SY_LayoutGerekli $bozuk 'BDS 230')){ $dusen += 'LAYOUT KARARI: bozuk BDS cikarimi yakalanmadi (sayfa no > satir basi numara)' }
  # Saglikli cikarim: numaralar satir basinda cogunlukta.
  $saglam = "Kapsam`n1. Birinci paragraf satir basinda.`n2. Ikinci paragraf satir basinda.`nA1. Ek paragraf satir basinda.`n5`n"
  if(SY_LayoutGerekli $saglam 'BDS 230'){ $dusen += 'LAYOUT KARARI: saglikli BDS cikarimina gereksiz layout istendi' }
  # TMS'te tek basina numara MESRU paragraf numarasidir - layout istenmez.
  if(SY_LayoutGerekli $bozuk 'TMS 2'){ $dusen += 'LAYOUT KARARI: TMS icin layout istendi (tek basina numara TMS''te mesrudur)' }
  return $dusen
}

$sinav = @(SY_OzSinav)
if($sinav.Count){
  Write-Host '!! STANDART YUTUCU KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $sinav){ Write-Host "   $d" }
  exit 1
}
Write-Host 'Oz-sinav: 26/26 vaka gecti (TMS kipi 11 · BDS kipi 5 · kip secimi 2 · layout karari 3 · uzun baslik/sahte atif 2 · sarkan atif/dipnot 3)'
Write-Host '  SINANMAYAN DALLAR: PDF indirme · pdftotext · ambar yazimi · geri okuma'
Write-Host ''

# --- 1) PDF
$arac = SY_PdfAraci
if(-not $arac){ Write-Host 'pdftotext bulunamadi.'; exit 1 }
$gecici = Join-Path $env:TEMP ('sy-' + ($standart -replace '[^A-Za-z0-9]','') )
$null = New-Item -ItemType Directory -Force $gecici
$pdfYolu = Join-Path $gecici 'kaynak.pdf'
$txtYolu = Join-Path $gecici 'kaynak.txt'

if(-not $url){
  # KGK adres kaliplari (27.07 kesfi + 25.08 BDS provasi):
  #   TMS/TFRS -> TMS_TFRS_Setleri/<yil>/Kirmizi_Kitap/<tip>/<std>.pdf
  #   BDS      -> TDS/TDS_2025_Seti/BDS NNN_2025.pdf   (EN GUNCEL denetim seti)
  #   GDS      -> TDS/TDS_2025_Seti/GDS NNNN_2025.pdf
  $kokAdres = 'https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2'
  if($standart -match '^(TMS|TFRS)\s'){
    $tip = ($standart -split ' ')[0]
    $url = "$kokAdres/TMS_TFRS_Setleri/$yil/Kirmizi_Kitap/$tip/$standart.pdf"
  } elseif($standart -match '^(BDS|GDS)\s'){
    $url = "$kokAdres/TDS/TDS_2025_Seti/${standart}_2025.pdf"
  } else {
    Write-Host "URL verilmeli - '$standart' icin kalip bilinmiyor (TSRS ayri yayin)."; exit 1
  }
}
Write-Host "PDF: $url"
$yanit = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 240
$bayt = $yanit.RawContentStream.ToArray()      # .Content ikili bozar (kayitli ders)
[IO.File]::WriteAllBytes($pdfYolu,$bayt)
$ilk4 = [Text.Encoding]::ASCII.GetString($bayt,0,4)
if($ilk4 -ne '%PDF'){
  Write-Host ("!! PDF DEGIL (ilk4='{0}', {1:N0} bayt) - ASCII'lesmis ad HTML hata sayfasi indirir." -f $ilk4,$bayt.Length) -ForegroundColor Red
  exit 1
}
Write-Host ("  indirildi: {0:N0} bayt · GERCEK PDF" -f $bayt.Length)

# -layout: iki sutunlu sayfalarda sutunlari YAN YANA tutar. TFRS 16'nin Ek A'si
# iki sutunluydu ve duz cikarim terimleri tanimlardan AYIRMISTI. Dort standartta
# (TFRS 17 · TMS 37 · TMS 20 · TMS 7) yeni cikarim eskisinden AZ metin verdi;
# sebebi ayni sinif olabilir. Kuculme freni acik oldugu icin deneme risksiz.
if($duzen){ & $arac -enc UTF-8 -nopgbrk -layout $pdfYolu $txtYolu 2>$null | Out-Null }
else      { & $arac -enc UTF-8 -nopgbrk          $pdfYolu $txtYolu 2>$null | Out-Null }
if(-not (Test-Path $txtYolu)){ Write-Host 'pdftotext cikti uretmedi.'; exit 1 }
$tamMetin = [IO.File]::ReadAllText($txtYolu,[Text.Encoding]::UTF8)
Write-Host ("  metin    : {0:N0} karakter" -f $tamMetin.Length)

# ⚠ 25.08 GECE DERSI: bazi BDS/GDS PDF'lerinde varsayilan cikarim paragraf
# numaralarini satir ortasina gomer; kip sayaci TMS'e duser ve SAYFA
# numaralari paragraf sanilir (16 standartta A-serisi boyle kayboldu).
# Karar fonksiyonu oz-sinavli: SY_LayoutGerekli.
if((-not $duzen) -and ($standart -match '^(BDS|GDS)\s')){
  # ⚠ 25.08 gece EK DERSI (BDS 501): varsayilan cikarimda satir basi numara
  # sayisi sayfa numarasini GECIYORDU (15>13) ama yine de paragraflarin yarisi
  # satir ortasindaydi (p.2, p.3, p.5, A2-A4 kacti). "Bozuk mu" sorusu yerine
  # dogrudan KARSILASTIR: iki cikarimdan hangisi daha cok satir basi numara
  # veriyorsa bolucu ONU okur (BDS 501: duz 15 · layout 40 -> layout).
  $layoutYolu = Join-Path $gecici 'kaynak-layout.txt'
  & $arac -enc UTF-8 -nopgbrk -layout $pdfYolu $layoutYolu 2>$null | Out-Null
  if(Test-Path $layoutYolu){
    $layoutMetin = [IO.File]::ReadAllText($layoutYolu,[Text.Encoding]::UTF8)
    $sbDuz    = @(($tamMetin    -split "`r?`n") | Where-Object { $_.Trim() -match '^A?\d{1,3}\.\s+\S' }).Count
    $sbLayout = @(($layoutMetin -split "`r?`n") | Where-Object { $_.Trim() -match '^A?\d{1,3}\.\s+\S' }).Count
    Write-Host ("  satir basi numara: duz {0} · layout {1}" -f $sbDuz,$sbLayout)
    if($sbLayout -gt $sbDuz){
      $tamMetin = $layoutMetin
      Write-Host ("  -> LAYOUT cikarimi secildi ({0:N0} karakter)" -f $tamMetin.Length)
    }
  }
  if(SY_LayoutGerekli $tamMetin $standart){
    Write-Host '!! CIKARIM BOZUK: satir basi numaralar sayfa numaralarindan az. Elle incele.' -ForegroundColor Red
    exit 1
  }
}

# --- 2) BOL
$yeni = @(SY_Bol $tamMetin $standart)
$yeniKarakter = ($yeni | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum
Write-Host ("  bolundu  : {0} parca · {1:N0} karakter" -f $yeni.Count,$yeniKarakter)

# --- 3) AMBARDAKI HALI
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'KOR: SUPABASE_SERVICE_KEY yok.'; exit 1 }
$anahtar = '' + $env:SUPABASE_SERVICE_KEY
$basliklar = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'User-Agent'='mevzuat-radar-robot' }
$ambarUcu = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
# ⚠⚠ 25.08 EN PAHALI HATA — ONEK SUZGECI KARDES STANDARTLARI DE KAPSIYORDU.
# Ilk surum: like."$standart*"  ->  'TMS 2*' deseni TMS 20 · TMS 21 · TMS 23 ·
# TMS 24 · TMS 26 · TMS 27 · TMS 28 · TMS 29'u DA yakaladi. Yutucu once
# 289 kaydi yedekleyip SILDI, sonra yerine 6 TMS 2 parcasi yazdi. Sekiz
# standart bir anda ambardan dustu. Yedek olmasaydi geri donusu yoktu.
# DOGRUSU: standardin adi ya AYNEN esit olmali, ya da ardindan BOSLUK gelmeli.
# 'TMS 2 ' oneki TMS 20'yi tutmaz; 'TMS 2' esitligi de yalniz kendisini tutar.
$suzgec = 'or=(kaynak_ad.eq.' + [uri]::EscapeDataString($standart) + ',kaynak_ad.like.' + [uri]::EscapeDataString("$standart *") + ')'

function SY_Cek([string]$adres){
  $y=Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $basliklar -TimeoutSec 240
  $g=[Text.Encoding]::UTF8.GetString($y.RawContentStream.ToArray())
  $c=ConvertFrom-Json -InputObject $g
  # ⚠ Virgul KOYMA: "return ,@($c)" diziyi sarmalar, cagirandaki @() acmaz ve
  # 12 kayit "1 parca" gorunur. Geri okuma DOGRULAMASI bu sayiya baktigi icin
  # yanlis sayi sigortayi kor eder. Duz don, cagiran @() ile sarsin.
  return @($c)
}
$eski = @(SY_Cek "$ambarUcu`?select=id,kaynak_ad,metin,tur,kaynak_url&$suzgec&limit=2000")
$eskiKarakter = 0; foreach($e in $eski){ $eskiKarakter += "$($e.metin)".Length }
Write-Host ''
Write-Host ("AMBARDAKI HALI : {0} parca · {1:N0} karakter" -f $eski.Count,$eskiKarakter)
Write-Host ("YENI HALI      : {0} parca · {1:N0} karakter" -f $yeni.Count,$yeniKarakter)
Write-Host ("KAZANC         : +{0} parca · +{1:N0} karakter ({2:N1} kat)" -f ($yeni.Count-$eski.Count),($yeniKarakter-$eskiKarakter),$(if($eskiKarakter){$yeniKarakter/$eskiKarakter}else{0}))

# ⚠⚠ KUCULME FRENI — 25.08'in en pahali dersi.
# TMS 2 kosusunda KGK adresindeki PDF standardin TAMAMI degil bir OZETI cikti;
# yutucu "yeni hali" diye 39 parca / 188.429 karakteri 6 parca / 17.520
# karakterle DEGISTIRDI. Geri okuma dogrulamasi "tutuyor" dedi - cunku
# YAZDIGIMI YAZDIM MI sorusunu soruyordu, DAHA IYISINI mi YAZDIM sorusunu degil.
# KURAL: yeni metin eskisinden KUCUKSE bu bir iyilestirme degil GERILEMEDIR.
# Yutma durur. Gercekten kucultmek gerekiyorsa -kucultmeyeOnayVer ile acilir.
if($eskiKarakter -gt 0 -and $yeniKarakter -lt ($eskiKarakter * 0.95)){
  Write-Host ''
  Write-Host ('!! KUCULME FRENI: yeni metin eskisinden KUCUK ({0:N0} -> {1:N0} karakter, %{2:N0})' -f $eskiKarakter,$yeniKarakter,(100*$yeniKarakter/$eskiKarakter)) -ForegroundColor Red
  Write-Host '   Bu bir iyilestirme degil GERILEMEDIR. Muhtemel sebep: adresteki PDF'
  Write-Host '   standardin TAMAMI degil ozeti/eki. Yutma DURDURULDU, ambar KORUNDU.'
  Write-Host '   Gercekten kucultmek gerekiyorsa: -kucultmeyeOnayVer'
  if(-not $kucultmeyeOnayVer){ exit 1 }
  Write-Host '   (-kucultmeyeOnayVer acik: devam ediliyor)'
}

if(-not $uygula){
  Write-Host ''
  Write-Host 'KURU PROVA — ambara hicbir sey yazilmadi. Ilk 10 yeni parca:'
  foreach($p in ($yeni | Select-Object -First 10)){ Write-Host ("   {0,-52} {1,5} krk" -f $p.kaynak_ad.Substring(0,[Math]::Min(52,$p.kaynak_ad.Length)),$p.metin.Length) }
  Write-Host ''
  Write-Host '-uygula ile yaz.'
  exit 0
}

# --- 4) YEDEK (silmeden once)
$yedekYolu = Join-Path $depoKok ("veri/fabrika/yedek-" + ($standart -replace '[^A-Za-z0-9]','') + "-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".json")
$null = New-Item -ItemType Directory -Force (Split-Path $yedekYolu)
$eskiDuz=@(); foreach($e in $eski){ $eskiDuz += ,([pscustomobject]@{ kaynak_ad="$($e.kaynak_ad)"; metin="$($e.metin)"; tur="$($e.tur)"; kaynak_url="$($e.kaynak_url)" }) }
[IO.File]::WriteAllText($yedekYolu,(ConvertTo-Json -InputObject $eskiDuz -Depth 6),(New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("Yedek yazildi: {0}" -f (Split-Path $yedekYolu -Leaf))

# --- 5) SIL + YAZ
$turDegeri = if($eski.Count -and "$($eski[0].tur)"){ "$($eski[0].tur)" } else { 'standart-madde' }
$urlDegeri = $url
Write-Host 'Eski kayitlar siliniyor...'
$null = Invoke-RestMethod -Method Delete -Uri "$ambarUcu`?$suzgec" -Headers ($basliklar + @{ Prefer='return=minimal' }) -TimeoutSec 240
Write-Host 'Yeni kayitlar yaziliyor...'
$yazildi=0
for($i=0; $i -lt $yeni.Count; $i += 50){
  $dilim = @($yeni[$i..([Math]::Min($i+49,$yeni.Count-1))])
  $govde = @()
  foreach($p in $dilim){ $govde += ,([ordered]@{ kaynak_ad=$p.kaynak_ad; metin=$p.metin; tur=$turDegeri; kaynak_url=$urlDegeri }) }
  $json = ConvertTo-Json -InputObject $govde -Depth 6
  # 27.08 dersi: -InputObject tek elemanli dizide de '[' ile baslayabilir;
  # kosulsuz sarma [[{...}]] uretir -> PGRST102. Yalniz GERCEKTEN diziyse sarma.
  if($json.TrimStart()[0] -ne '['){ $json = "[$json]" }
  $null = Invoke-RestMethod -Method Post -Uri $ambarUcu -Headers ($basliklar + @{ Prefer='return=minimal' }) `
    -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 240
  $yazildi += $dilim.Count
  Write-Host ("  ...{0}/{1}" -f $yazildi,$yeni.Count)
}

# --- 6) GERI OKU VE KARSILASTIR  (asil sigorta)
# YUTMA-LISTESI.md "122 parca yutuldu" derken ambarda 12 vardi. Bir daha
# olmayacak: yazdiktan sonra GERI OKUNUR, tutmuyorsa KIRMIZI.
Start-Sleep -Seconds 2
$geriHam = SY_Cek "$ambarUcu`?select=id,metin&$suzgec&limit=2000"
$geri = @($geriHam)
$geriKarakter = 0; foreach($g in $geri){ $geriKarakter += "$($g.metin)".Length }
Write-Host ''
Write-Host ("GERI OKUMA: {0} parca · {1:N0} karakter" -f $geri.Count,$geriKarakter)
if($geri.Count -ne $yeni.Count -or [Math]::Abs($geriKarakter-$yeniKarakter) -gt 100){
  Write-Host ("!! TUTMUYOR — yazildigi soylenen {0} parca / {1:N0} krk, ambarda {2} parca / {3:N0} krk" -f $yeni.Count,$yeniKarakter,$geri.Count,$geriKarakter) -ForegroundColor Red
  Write-Host ("   Yedek duruyor: {0}" -f (Split-Path $yedekYolu -Leaf))
  exit 1
}
Write-Host 'DOGRULANDI — yazilan ile ambardaki birebir tutuyor.' -ForegroundColor Green
Write-Host ''
Write-Host 'SIRADAKI: motor\butunluk-kapisi.ps1 -yalniz "' + $standart + '" ile delik kalmadigini teyit et.'