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
  [switch]$duzen,           # pdftotext -layout: iki sutunlu sayfalarda sutunlari korur
  [string]$PlanYaz = ''     # 14.09: kuru provada ESKI ve YENI parca adlarini bu JSON'a yazar (soru-kaynak bagi etkisi olcumu icin; ambara yazmaz)
)

$ErrorActionPreference = 'Stop'
# 30.08.2026 KUSUR (CI'dan DELILLE bulundu): asagidaki satir eskiden
#   $here = Split-Path -Parent $MyInvocation.MyCommand.Path
# idi. Bu betik BASKA BIR BETIGIN ICINDEN "&" ile cagrildiginda (surum-tazeligi
# tam bunu yapar) PowerShell 7 / Linux'ta $MyInvocation.MyCommand.Path NULL
# gelir ve Split-Path patlar:
#   "standart-yut.ps1: Cannot bind argument to parameter 'Path' because it is null."
# Betik daha ILK KURULUM SATIRINDA olur; hicbir sey yazmaz.
# GORUNEN SONUC baska yere isaret ediyordu: surum karnesinde 31 standardin
# 29'u "OLCULEMEDI · ambar 0p -> yeni 0p" cikiyordu; sanki Supabase ya da
# pdftotext sorunu varmis gibi. Ikisi de saglamdi (CI teshisi: pdftotext
# /usr/bin/pdftotext · anahtar 219 karakter · pwsh 7.6.5 Ubuntu 24.04).
# $PSScriptRoot bu baglamda DOGRU deger verir; eski yol yedek olarak kalir.
$here = if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $here 'hat-onkontrol.ps1')
$buBetik = if($PSCommandPath){ $PSCommandPath } else { Join-Path $here 'standart-yut.ps1' }
HatOnKontrol $buBetik
$depoKok = Split-Path -Parent $here
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function SY_PdfAraci {
  # ⚠ 14.09.2026 DERSI — GIT'IN ICINDEKI XPDF 4.06 ONCELIKLIYDI, POPPLER DEGIL.
  # Git'le gelen pdftotext (xpdf 4.06) TMS/TFRS PDF'lerinde paragraf numarasini
  # metinle AYNI satira yapistiriyor ("29A Bazi isletmeler ..."); TMS kipi
  # numarayi goremiyor. TMS 16 p.31-40 (yeniden degerleme modeli) boyle sahte
  # "p.5" govdesine gomuldu; TMS 12/19/36/37/40/41 · TFRS 17 delikleri ayni
  # sinif. GitHub Actions poppler kullaniyor (ambar-kapilari.yml) - yerel ve
  # bulut FARKLI metin uretiyordu. Olculdu: ayni TMS 16 PDF'i poppler 25.07 ile
  # 102 parca (p.31-40 ayri), xpdf 4.06 ile 84 parca (p.31-40 yok).
  # KURAL: poppler varsa HER ZAMAN o; xpdf yalniz baska arac yoksa.
  $adaylar = New-Object System.Collections.Generic.List[string]
  foreach($c in @(Get-Command pdftotext -All -ErrorAction SilentlyContinue)){ if($c.Source){ $adaylar.Add($c.Source) } }
  foreach($a in @('C:\Program Files\Git\mingw64\bin\pdftotext.exe','C:\Program Files (x86)\Git\mingw64\bin\pdftotext.exe')){ if(Test-Path $a){ $adaylar.Add($a) } }
  foreach($a in $adaylar){
    # surum stderr'e yazilir; PS 5.1'de Stop tercihi stderr'i hataya cevirir -> yerelde gevset.
    # (cmd /c KULLANMA: Linux runner'da cmd yok.)
    $oncekiTercih = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $surum = (@(& $a -v 2>&1) | ForEach-Object { "$_" }) -join ' ' } catch { $surum = '' } finally { $ErrorActionPreference = $oncekiTercih }
    if($surum -notmatch 'xpdfreader'){ return $a }
  }
  if($adaylar.Count -gt 0){ return $adaylar[0] }
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
  # ⚠⚠ UCUNCU DUZEN (01.09, BOBI/KUMI FRS olculdu): paragraf numarasi ONDALIKLI
  # ve NOKTASIZ, satir basinda metinle birlikte ("10.5 Bir varlik ...").
  # Ne TMS kipi (tek basina sayi = burada SAYFA no) ne BDS kipi ("N." noktali)
  # yakaliyordu -> BOBI 350 parcanin 339'u tek "m.7" yiginina akmisti (%97).
  # Icindekiler satirlari ("1.1 Kapsam ..... 5") ayni desene benzer - dolgu
  # freni ('....' iceren govde paragraf sayilmaz) onlari eler.
  # Iki alt-duzen var (01.09 olculdu): KUMI numara+metin AYNI satirda
  # ("1.1 Bu bolum..."), BOBI ise numara KENDI SATIRINDA tek ("1.3" bir satir,
  # govde sonraki satirlarda; 746 adet olculdu). Ikisi de kilavuz kipidir.
  $kilavuzSay = @($satirlar | Where-Object { $_.Trim() -match '^\d{1,2}(\.\d{1,2}){1,3}\s+\S' -and $_ -notmatch '\.{5,}' }).Count
  $kilavuzTek = @($satirlar | Where-Object { $_.Trim() -match '^\d{1,2}(\.\d{1,2}){1,3}$' }).Count
  $kilavuzToplam = $kilavuzSay + $kilavuzTek
  $kilavuzKip = ($kilavuzToplam -gt $tekBasina) -and ($kilavuzToplam -gt $satirBasi)
  $satirBasiKip = (-not $kilavuzKip) -and ($satirBasi -gt $tekBasina)
  # 16.09: DÖRDÜNCÜ DÜZEN — numara sol sütunda, metin sağda (TSRS). Kip ADA bağlı açılır (metne göre değil) ki
  # başka standartların bölünmesi kazara değişmesin; TSRS dışında $sutunKip hep $false'tur.
  $sutunKip = ($std -match '^TSRS\s') -and (@($satirlar | Where-Object { $_ -match '^\s{0,12}[A-E]?\d{1,3}[A-Z]?\s{2,}\S' }).Count -ge 3)   # 16.09: ad zaten TSRS ile sinirli; sayi esigi yalnizca bos/bozuk metni eler
  $parcalar = New-Object System.Collections.Generic.List[object]
  $baslik = ''
  $suAn = $null
  $sozlukModu = $false          # Ek A: numarasiz terim-tanim sozlugu
  # ⚠ 14.09.2026 DERSI — SAYFA NUMARASI + KOSU BASLIGI PARAGRAF SANILIYORDU.
  # TMS/TFRS kipinde tek basina duran HER sayi paragraf aciyordu. Sayfa sonu
  # "5" + bos satir + bir sonraki sayfanin ust basligi "TMS 16" geldiginde
  # sahte "p.5" acildi; gercek 31-40 (yeniden degerleme modeli) onun GOVDESINE
  # gomuldu, ambarda "TMS 16 p.5 - Maliyet modeli" adiyla durdu. Hakem "p.31
  # kaynakta yok" dedi (KGK ret kutugu KAYNAK-EKSIK). Kural: tek basina sayinin
  # ardindaki ilk dolu satir standardin KOSU BASLIGIYSA ("TMS 16") o sayi
  # SAYFA NUMARASIDIR; baslik satiri da govdeye girmez.
  $kosuBasligi = [regex]::Escape($std.Trim())
  $sayfaSatiri = New-Object System.Collections.Generic.HashSet[int]
  for($si=0; $si -lt $satirlar.Count; $si++){
    $siTrim = $satirlar[$si].Trim()
    if($siTrim -match '^\d{1,3}$'){
      for($sj=$si+1; $sj -lt [Math]::Min($satirlar.Count,$si+4); $sj++){
        $sjTrim = $satirlar[$sj].Trim()
        if($sjTrim.Length -eq 0){ continue }
        if($sjTrim -match "^$kosuBasligi$"){ [void]$sayfaSatiri.Add($si); [void]$sayfaSatiri.Add($sj) }
        break
      }
    }
  }
  $satirSirasi = -1
  # ⚠ 15.09.2026 DERSI — BDS/GDS RAKAMLI EKLERI ANA METNIN NUMARALARIYLA CAKISIYORDU.
  # BDS'lerde ekler "Ek 1", "Ek 2" (GDS 3000'de yalniz "Ek") basligiyla TEK SATIRDA durur ve
  # numaralandirma 1'den yeniden baslar. Kural yalniz harfli ekleri (Ek A/B/C) taniyordu;
  # BDS 530 Ek 2 tablosu "BDS 530 p.1 - ETKİSİ" adiyla ana metnin "p.1 - Kapsam"iyla cakisti
  # (BDS 315/540/600/210, GDS 3000 ayni sinif). Kural: yalniz TEK BASINA duran "Ek N"/"Ek"
  # satiri eki acar; sonraki parcalar "<STD> Ek N p.<no>" adini alir. Icindekiler satiri
  # ("Ek 1: Baslik") ve metin ici atif ("Ek 2'de ...") bu bicime uymaz, eki acmaz.
  $ekEtiketi = ''
  foreach($ham in $satirlar){
    $satirSirasi++
    $s = $ham.Trim()
    if($suAn -and -not $suAn.Contains('ek')){ $suAn['ek'] = $ekEtiketi }   # parca, acildigi andaki eke aittir
    if($sayfaSatiri.Contains($satirSirasi)){ continue }

    if($s -cmatch '^Ek(?:\s*[-–]?\s*(\d{1,2}))?$'){   # -cmatch: GDS 3410'da satir sonuna dusen kucuk harfli "ek" sozcugu eki aciyordu
      if($suAn){ $parcalar.Add($suAn); $suAn=$null }
      $sozlukModu = $false
      $ekEtiketi = if($Matches[1]){ "Ek $($Matches[1])" } else { 'Ek' }
      $baslik = ''
      continue
    }

    # --- EK basliklari: kip degistirir
    # 16.09 (TSRS): metnin İÇİNDEKİ "Ek A'da tanımlanan terimler, … italik yazılmıştır." cümlesi de bu desene uyuyor ve
    # sözlük kipini ana metnin ORTASINDA açıyordu → TSRS 1'in 1–86 paragrafı Ek A yığınına akmıştı (5 paragraf kaldı).
    # Sütun kipinde (yalnız TSRS) başlığın TEK BAŞINA durması şartı konur; öteki standartlarda desen aynen korunur.
    if($s -match '^Ek\s+A\b' -and (-not $sutunKip -or $s -match '^Ek\s+A\s*$')){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$true; $baslik='Ek A - Tanımlanan terimler'; continue }
    if($s -match '^Ek\s+([B-Z])\b' -and (-not $sutunKip -or $s -match '^Ek\s+[B-Z]\s*$')){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$false; $baslik=$s; continue }

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

    # --- SUTUN KIPI (16.09, YALNIZ TSRS): numara SOL SUTUNDA, metin SAGDA -----
    # TSRS 1/2 (KGK sürdürülebilirlik standartları) -layout çıkarımında paragraf şöyle görünür:
    #   "1           TSRS 1 Sürdürülebilirlikle ..."   ·   "B7    İşletme, gelecekteki ..."   ·   "E1  İşletme bu Standardı ..."
    # Numara ne kendi satırındadır (TMS kipi) ne de noktalıdır (BDS kipi) → üç kipin hiçbiri tutmuyordu:
    # 16.09 ölçümü (arac/kgk-hakikat-olcumu.ps1): TSRS 1 resmî 187 numaranın 78'i, TSRS 2 113'ün 32'si ambarda etiketliydi;
    # ek paragrafları (B/D/E serileri) hiç ayrılmamıştı. Bu kip YALNIZ "$std -match '^TSRS '" olduğunda açılır;
    # başka hiçbir standardın bölünmesi değişmez (eşdeğerlik provası: 86 standart, TSRS dışında fark 0).
    if($sutunKip -and $s -match '^([A-E]?)(\d{1,3})([A-Z]?)\s{2,}(\S.{3,})$' -and -not ($Matches[4] -cmatch '^[a-zçğıöşü]')){
      $tOnek=$Matches[1]; $tNo=[int]$Matches[2]; $tSonek=$Matches[3]; $tGovde=$Matches[4]
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu=$false
      $suAn = [ordered]@{ onek=$tOnek; no=$tNo; sonek=$tSonek; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($tGovde)
      continue
    }
    # sütun kipinde tek başına duran sayı = SAYFA numarası
    if($sutunKip -and $s -match '^\d{1,3}$'){ continue }

    # --- KILAVUZ KIPI (01.09): ondalikli noktasiz numara ("10.5 Metin ...") --
    if($kilavuzKip -and $s -match '^(\d{1,2}(?:\.\d{1,2}){1,3})\s+(\S.{3,})$' -and -not ($Matches[2] -cmatch '^[a-zçğıöşü]') -and $s -notmatch '\.{5,}'){
      $gNoStr=$Matches[1]; $gGovde=$Matches[2]
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu=$false
      $suAn = [ordered]@{ onek=''; no=$gNoStr; sonek=''; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($gGovde)
      continue
    }
    # kilavuz kipi, ondalikli numara KENDI SATIRINDA ("1.3" tek) - BOBI duzeni
    if($kilavuzKip -and $s -match '^(\d{1,2}(?:\.\d{1,2}){1,3})$'){
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu=$false
      $suAn = [ordered]@{ onek=''; no=$Matches[1]; sonek=''; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      continue
    }
    # kilavuz kipinde tek basina duran sayi = SAYFA numarasi
    if($kilavuzKip -and $s -match '^\d{1,3}$'){ continue }
    # kilavuz kipinde dolgu satiri = ICINDEKILER navigasyonu, metin degil
    if($kilavuzKip -and $s -match '\.{5,}'){ continue }

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
    if((-not $satirBasiKip) -and (-not $kilavuzKip) -and $s -match '^([A-D]?)(\d{1,3})([A-Z]?)$'){
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
    # ⚠ 01.09 KILAVUZ dersi (BOBI olculdu): 60-70 krlik YARIM CUMLELER
    # ("Raporlama doneminden sonraki on iki ay icinde paraya cevrilmesinin")
    # sonu noktasiz + buyuk harfle baslayinca baslik saniliyor ve govdeden
    # dusuyordu (60 sondadan 3 kayip). Kilavuz kipinde gercek bolum basliklari
    # kisadir - esik 70 -> 45.
    $baslikEsik = if($kilavuzKip){ 45 } else { 70 }
    if($s.Length -le $baslikEsik -and $s -notmatch '[.:;]$' -and $s -notmatch '[.!?][0-9]{1,3}$' -and $s -cmatch '^[A-ZÇĞİÖŞÜ]' -and ($null -eq $suAn -or $suAn.govde.Count -gt 0)){
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
      if($ekEtiketi){
        # 15.09: ek basligindan sonra ilk numarali paragraftan onceki metin (atif satiri, ek aciklamasi) ekin GIRIS parcasidir, kunye degil
        $suAn = [ordered]@{ onek=''; no=0; sonek=''; baslik=$(if($baslik){ $baslik } else { 'Giriş' }); ek=$ekEtiketi; govde=New-Object System.Collections.Generic.List[string] }
      } else {
        $suAn = [ordered]@{ onek=''; no=0; sonek=''; kunye=$true; baslik='Künye ve yürürlük'; govde=New-Object System.Collections.Generic.List[string] }
      }
    }
    $suAn.govde.Add($s)
  }
  if($suAn){ if(-not $suAn.Contains('ek')){ $suAn['ek'] = $ekEtiketi }; $parcalar.Add($suAn) }
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
      $ekOnEki = if($p.Contains('ek') -and $p.ek){ "$($p.ek) " } else { '' }
      $ad = "$std $ekOnEki$etiket" + $(if($p.baslik){ " - $($p.baslik)" } else { '' })
      # 15.09: layout tablolarindan gelen basliklar ad icine hizalama boslugu/sekme tasiyordu ("FAKTÖR                    ETKİSİ");
      # olculdu: ambarda 13 boyle ad, bagli soru 0 -> tek bosluga indirmek hicbir bagi koparmaz
      $ad = ($ad -replace '\s+',' ').Trim()
    }
    if($ad.Length -gt 160){ $ad = $ad.Substring(0,160) }
    $kayitlar.Add([pscustomobject]@{ kaynak_ad=$ad; metin=$govde })
  }
  # ⚠ "return ,$kayitlar" YAZMA. Virgul listeyi SARMALAR ve cagirandaki @()
  # onu ACMAZ -> tek elemanli dizi doner. Bu tuzak 25.08'de UC KEZ vurdu
  # (kart-kontrol · kesik-metin-nobeti · burada). ToArray() net cozum.
  return $kayitlar.ToArray()
}

function SY_TmsLayoutDuzle([string]$layoutMetin, [string]$std){
  # ⚠ 15.09.2026 DERSI — POPPLER DUZ CIKARIMDA NUMARA SUTUNU AYRILIYOR.
  # TMS/TFRS PDF'lerinde paragraf numarasi sol sutunda durur. pdftotext duz kipte
  # ard arda gelen numaralari ALT ALTA basiyor ("16", "17", sonra iki paragrafin
  # metni) -> bolucu p.16'yi bos sayip metnini p.17'nin altina koyuyordu
  # (TMS 16 p.11/16/23/73-76, TMS 12/36/40 ayni sinif). -layout kipinde numara
  # kendi paragrafinin satirinda: "16   Bir maddi duran varlik ...".
  # Bu islev layout metnini SY_Bol'un TMS kipinin anladigi bicime cevirir:
  # sutun 0'da "numara + en az 2 bosluk + metin" -> "numara" satiri + "metin" satiri;
  # girintiler atilir; sayfa numarasi + kosu basligi satirlari atlanir.
  $kosu = [regex]::Escape($std.Trim())
  $cikti = New-Object System.Text.StringBuilder
  $satirlar = @($layoutMetin -split "`r?`n")
  for($satirNo = 0; $satirNo -lt $satirlar.Count; $satirNo++){
    $hamSatir = $satirlar[$satirNo]
    $kirpik = $hamSatir.Trim()
    if($kirpik -match "^$kosu$"){ continue }
    if($kirpik -match '^\d{1,3}$' -and $hamSatir -match '^\s{8,}'){ continue }   # ortalanmis sayfa numarasi
    if($kirpik -match '^\d{1,3}$'){
      # ⚠ 15.09 DERSI — TMS 40 p.32A "Isletme," sayfa sonunda bitiyor; sol sutundaki sayfa numarasi "4"
      # + kosu basligi geliyor. Baslik yukarida atildigi icin "4" PARAGRAF sanildi: 32A kayboldu,
      # (a)/(b) bentleri sahte "p.4"e gitti. Sayfa numarasi = oncesinde ya da sonrasinda (bos satirlar
      # atlanarak) kosu basligi olan tek basina sayi.
      $komsuBaslik = $false
      foreach($yon in -1,1){
        $bakilan = $satirNo + $yon
        while($bakilan -ge 0 -and $bakilan -lt $satirlar.Count -and -not $satirlar[$bakilan].Trim()){ $bakilan += $yon }
        if($bakilan -ge 0 -and $bakilan -lt $satirlar.Count -and $satirlar[$bakilan].Trim() -match "^$kosu$"){ $komsuBaslik = $true }
      }
      if($komsuBaslik){ continue }
      # DIPNOT: layout kipinde gercek paragraf numarasi metniyle AYNI satirdadir ("58    Bu Standart ...").
      # Tek basina sayi + sonraki dolu satir girintili = dipnot isareti (TMS 41 "1 / Mayis 2025'te TFRS 18..."
      # sahte "p.1 - Yururluk tarihi" uretiyordu; TMS 8, TFRS 5 ayni sinif). Isaret atlanir, dipnot metni onceki paragrafta kalir.
      $sonraki = $satirNo + 1
      while($sonraki -lt $satirlar.Count -and -not $satirlar[$sonraki].Trim()){ $sonraki++ }
      if($sonraki -lt $satirlar.Count -and $satirlar[$sonraki] -match '^\s{3,}\S'){ continue }
    }
    $numaraEsi = [regex]::Match($hamSatir,'^([A-D]?\d{1,3}[A-Z]?(?:[–-]\d{1,3}[A-Z]?)?)\s{2,}(\S.*)$')
    if($numaraEsi.Success){
      [void]$cikti.AppendLine($numaraEsi.Groups[1].Value)
      [void]$cikti.AppendLine('')
      [void]$cikti.AppendLine(($numaraEsi.Groups[2].Value.Trim() -replace '\s{2,}',' '))
      continue
    }
    [void]$cikti.AppendLine(($kirpik -replace '\s{2,}',' '))   # layout hizalama bosluklari metne sizmasin: "(a)       Indirimler" -> "(a) Indirimler"
  }
  return $cikti.ToString()
}

function SY_LayoutHakikat([string]$layoutMetin){
  # ⚠ 15.09 DERSI — "NUMARA DELIGI" SECIM OLCUTU YANLIS CEZA KESIYORDU. TMS 32 p.1 ve p.5-7 resmi metinde
  # [Silinmistir]/dipnot; dogru bolme bu numaralari uretmedigi icin "delik" sayildi, sahte p.5-7 ureten
  # duz bolme kazandi. Hakikat = layout metninde sutun 0'da METNIYLE AYNI SATIRDA duran numara;
  # "[Silinmistir]" satirlari hakikatten cikar (bolme onlari uretmemeli).
  $gercek = New-Object System.Collections.Generic.HashSet[string]; $silinen = New-Object System.Collections.Generic.HashSet[string]
  foreach($satir in ($layoutMetin -split "`r?`n")){
    $es = [regex]::Match($satir,'^([A-Z]{0,2}\d{1,3}[A-Z]{0,2})\s{2,}(\S.*)$')
    if(-not $es.Success){ continue }
    if($es.Groups[2].Value -match '^\[Silinmi'){ [void]$silinen.Add($es.Groups[1].Value) } else { [void]$gercek.Add($es.Groups[1].Value) }
  }
  Write-Output -NoEnumerate $gercek   # HashSet acilmasin: tek elemanda string'e donup .Contains alt-dize arardi
}

function SY_HakikatSapmasi($parcalar, $gercek){
  # eksik (hakikatte var, bolmede yok) + fazla (bolmede var, hakikatte yok; p.0 kunye haric) + cift (ayni numara birden cok parcada, [k/n] haric)
  $sayac = @{}
  foreach($parca in $parcalar){
    $ad = "$($parca.kaynak_ad)"; $parcaliMi = $ad -match '\s\[\d+/\d+\]'
    $es = [regex]::Match(($ad -replace '\s\[\d+/\d+\]',''),'\sp\.([A-Z]{0,2}\d{1,3}[A-Z]{0,2})(?:\s|$)')
    if(-not $es.Success){ continue }
    $no = $es.Groups[1].Value
    if($parcaliMi){ if(-not $sayac.ContainsKey($no)){ $sayac[$no] = 1 } } else { $sayac[$no] = 1 + [int]$sayac[$no] }
  }
  $eksik = @($gercek | Where-Object { -not $sayac.ContainsKey($_) }).Count
  $fazla = @($sayac.Keys | Where-Object { $_ -ne '0' -and -not $gercek.Contains($_) }).Count
  $cift  = @($sayac.Keys | Where-Object { $sayac[$_] -gt 1 -and $_ -ne '0' }).Count
  return ($eksik + $fazla + $cift)
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
  # 15.09: İHS (İlgili Hizmet Standardı, ör. İHS 4400) BDS düzeninde yayımlanır (numara satır başında metinle) -> BDS kipi
  if($std -notmatch '^(BDS|GDS|SBDS|SGDS|İHS)\s'){ return $false }
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
  # --- 14.09: sayfa numarasi + kosu basligi (TMS 16 p.31-40 "p.5" icine gomulmustu)
  $sayfaOrnek = "Maliyet modeli`n30`n`nBir kalem maliyetinden birikmis amortisman indirilerek gosterilir.`n`n5`n`nTEST 5`n`nYeniden degerleme modeli`n31`n`nGercege uygun degeri guvenilir olarak olculebilen kalem yeniden degerlenmis tutari uzerinden gosterilir."
  $sy = @(SY_Bol $sayfaOrnek 'TEST 5')
  $syAdlar = @($sy | ForEach-Object { $_.kaynak_ad })
  if(@($sy | Where-Object { $_.kaynak_ad -match 'p\.5\b' }).Count -gt 0){ $dusen += "SAYFA NUMARASI PARAGRAF SANILDI: $($syAdlar -join ' | ')" }
  if(@($sy | Where-Object { $_.kaynak_ad -match 'p\.31 - Yeniden degerleme modeli' }).Count -ne 1){ $dusen += "SAYFA SONRASI PARAGRAF KAYBOLDU: $($syAdlar -join ' | ')" }
  if((($sy | ForEach-Object { $_.metin }) -join ' ') -match '(^| )TEST 5( |$)'){ $dusen += 'KOSU BASLIGI GOVDEYE SIZDI' }

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
  # --- KILAVUZ KIPI (01.09: BOBI/KUMI FRS "10.5 Metin" duzeni) ---
  # Icindekiler dolgu satiri paragraf sayilmamali; sayfa numarasi atlanmali.
  $kilOrnek = @"
BOLUM 1 KAVRAMLAR

1.1 Kapsam ................ 5

1.2 Tanimlar ................ 7

Kapsam

1.1 Bu bolum, finansal tablolarin hazirlanmasina iliskin temel ilkeleri duzenlemektedir.

12

1.2 Finansal tablolar, isletmenin finansal durumu hakkinda bilgi sunar ve yilda bir hazirlanir.

10.5 Bir varlik ancak gelecekte ekonomik fayda saglamasi muhtemel oldugunda finansal tablolara alinir.
"@
  $kv = @(SY_Bol $kilOrnek 'TEST K')
  $kAdlar = @($kv | ForEach-Object { $_.kaynak_ad })
  if(@($kv | Where-Object { $_.kaynak_ad -match 'p\.1\.1\b' }).Count -ne 1){ $dusen += "KILAVUZ p.1.1 bulunamadi: $($kAdlar -join ' | ')" }
  if(@($kv | Where-Object { $_.kaynak_ad -match 'p\.10\.5\b' }).Count -ne 1){ $dusen += "KILAVUZ p.10.5 bulunamadi" }
  $tumMetin = ($kv | ForEach-Object { $_.metin }) -join ' '
  if($tumMetin -match 'Kapsam \.{3,}'){ $dusen += 'KILAVUZ: icindekiler dolgu satiri paragraf govdesine girdi' }
  if($tumMetin -match '(^| )12( |$)' -and $tumMetin -notmatch 'yilda bir'){ $dusen += 'KILAVUZ: sayfa numarasi metne sizdi' }
  # BOBI alt-duzeni: ondalikli numara KENDI SATIRINDA, govde sonraki satirda
  $kilOrnek2 = @"
Kapsam

2.1

Bu standart buyuk ve orta boy isletmelerin finansal raporlamasina uygulanir.

47

2.2

Isletme siniflari her yil Kurum tarafindan ilan edilen olcutlere gore belirlenir.
"@
  $kv2 = @(SY_Bol $kilOrnek2 'TEST K2')
  if(@($kv2 | Where-Object { $_.kaynak_ad -match 'p\.2\.1\b' }).Count -ne 1){ $dusen += "KILAVUZ-TEK p.2.1 bulunamadi: $((@($kv2|ForEach-Object kaynak_ad)) -join ' | ')" }
  if(@($kv2 | Where-Object { $_.kaynak_ad -match 'p\.2\.2\b' }).Count -ne 1){ $dusen += 'KILAVUZ-TEK p.2.2 bulunamadi' }
  if((($kv2 | ForEach-Object metin) -join ' ') -match '(^| )47( |$)'){ $dusen += 'KILAVUZ-TEK: sayfa numarasi metne sizdi' }
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

  # --- 15.09 BDS RAKAMLI EK: "Ek 2" tek satir eki acar; icindekiler ("Ek 1: ...") ve atif ("Ek 1'de ...") acmaz
  $ekOrnek = "Ek 1: Gruplandirma ve Deger Agirlikli Secim`nKapsam`n1. Bu BDS denetcinin orneklem kullanimini duzenleyen hukumleri icerir ve ilgili`nek`nprosedurleri uygulamasini ister.`n2. Ek 1'de gruplandirmaya iliskin ilave aciklamalar yer almaktadir ve bunlar dikkate alinir.`nA1. Orneklem buyuklugu denetcinin risk degerlendirmesine gore belirlenir ve belgelenir.`n`nEk 1`n(Bakiniz: A8 paragrafi)`nGruplandirma Yontemi`n1. Denetci anakitleyi belirli ozelliklere sahip alt gruplara ayirarak etkinligi artirabilir.`n2. Detay testlerinde anakitle genellikle parasal degerler esas alinarak gruplandirilir."
  $ep = @(SY_Bol $ekOrnek 'TEST 7')
  $eAd = @($ep | ForEach-Object { $_.kaynak_ad })
  if(@($ep | Where-Object { $_.kaynak_ad -match '^TEST 7 p\.1(\s|$)' }).Count -ne 1){ $dusen += "BDS EK: ana metin p.1 tek olmali: $($eAd -join ' | ')" }
  if(@($ep | Where-Object { $_.kaynak_ad -match '^TEST 7 Ek 1 p\.1(\s|$)' }).Count -ne 1){ $dusen += "BDS EK: ek paragrafi 'Ek 1 p.1' adini almadi: $($eAd -join ' | ')" }
  if(@($ep | Where-Object { $_.kaynak_ad -match '^TEST 7 Ek 1 p\.(2|A1)(\s|$)' -and $_.metin -match 'ilave aciklamalar|risk degerlendirmesine' }).Count){ $dusen += "BDS EK: icindekiler/atif satiri eki erken acti: $($eAd -join ' | ')" }
  if(@($ep | Where-Object { $_.kaynak_ad -match '^TEST 7 p\.2(\s|$)' }).Count -ne 1){ $dusen += "BDS EK: ana metin p.2 kayboldu: $($eAd -join ' | ')" }
  if(@($ep | Where-Object { $_.kaynak_ad -cmatch '^TEST 7 Ek p\.' }).Count){ $dusen += "BDS EK: kucuk harfli 'ek' satiri eki acti: $($eAd -join ' | ')" }
  if(@($ep | Where-Object { $_.kaynak_ad -match 'Künye' -and $_.kaynak_ad -match ' Ek ' }).Count){ $dusen += "BDS EK: ek giris metni 'Künye' adini aldi: $($eAd -join ' | ')" }

  # --- 15.09 TMS LAYOUT DUZELTICI: sayfa sonu bolunen paragraf (TMS 40 p.32A) + dipnot isareti (TMS 41) + [Silinmistir]
  # BILINEN SINIR (TMS 36 p.140G): dipnot metni onceki paragrafa eklenir; onceki paragraf [Silinmistir] ise govde uzar ve parca olur. Dipnot resmi metin oldugu icin atilmaz.
  $lay = "31       Isletme gercege uygun deger yontemini veya maliyet yontemini secer ve tum gayrimenkullere uygular.`n32A      Isletme,`n`n`n`n                                   TEST 9`n`n4`nsecimini asagidaki gruplar icin ayri yapar:`n        (a)     birinci grup icin gercege uygun deger yontemini`n        secebilir.`n33       Gercege uygun deger yontemi uygulayan isletme tum gayrimenkulleri bu yontemle olcer ve raporlar.`n`n1`n       Mayis 2025'te bu Standardin adi degistirilmistir ve yeni ad kullanilir.`n34       [Silinmistir]`n35       Kazanc veya kayip olustugu donemde kar veya zarara yansitilir ve ayrica aciklanir gerekirse."
  $lp = @(SY_Bol (SY_TmsLayoutDuzle $lay 'TEST 9') 'TEST 9')
  $lAd = @($lp | ForEach-Object { $_.kaynak_ad })
  if(@($lp | Where-Object { $_.kaynak_ad -match 'p\.(4|1|34)(\s|$)' }).Count){ $dusen += "LAYOUT: SAYFA NO / DIPNOT PARAGRAF SANILDI: $($lAd -join ' | ')" }
  $p32a = @($lp | Where-Object { $_.kaynak_ad -match 'p\.32A(\s|$)' })
  if($p32a.Count -ne 1 -or $p32a[0].metin -notmatch 'birinci grup'){ $dusen += "LAYOUT: SAYFA SONU BOLUNEN PARAGRAF KAYBOLDU (32A + bentler): $($lAd -join ' | ')" }
  if(@($lp | Where-Object { $_.kaynak_ad -match 'p\.35(\s|$)' }).Count -ne 1){ $dusen += "LAYOUT: DIPNOTTAN SONRAKI PARAGRAF KAYBOLDU: $($lAd -join ' | ')" }
  $hk = SY_LayoutHakikat $lay
  if(-not $hk.Contains('32A') -or $hk.Contains('34') -or $hk.Contains('4')){ $dusen += "HAKIKAT: numara kumesi yanlis ($(@($hk) -join ','))" }
  if((SY_HakikatSapmasi $lp $hk) -ne 0){ $dusen += "HAKIKAT SAPMASI: dogru bolmede 0 beklenirken $(SY_HakikatSapmasi $lp $hk)" }

  # --- 16.09 SUTUN KIPI (TSRS): numara sol sutunda, metin sagda; Ek A basligi YALNIZ tek basinayken sozluk acar
  $tsrs = @"
Ek A'da tanimlanan terimler, Standartta ilk kez gectikleri yerde italik yazilmistir.

1           Bu Standardin amaci, isletmenin surdurulebilirlikle ilgili risk ve firsatlarini aciklamasidir.

2           Isletme, genel amacli finansal raporlarinda bu bilgileri sunar.

Ek B

B7    Isletme, gelecekteki finansal yeterliligini etkilemesi beklenen riskleri belirler.

Ek A

kisa vade    Isletmenin raporlama donemini izleyen bir yillik donemdir.
"@
  $tp = @(SY_Bol $tsrs 'TSRS 1')
  $tAd = @($tp | ForEach-Object { $_.kaynak_ad })
  # ana metin 1-2 ve ek paragrafi B7 AYRI parca olmali; "Ek A'da tanimlanan" cumlesi sozluk ACMAMALI
  foreach($bek in 'p.1','p.2','p.B7'){ if(-not @($tAd | Where-Object { $_ -match ([regex]::Escape("TSRS 1 $bek") + '(\s|$)') }).Count){ $dusen += "SUTUN KIPI: $bek parcasi yok ($($tAd -join ' | '))" } }
  if(@($tAd | Where-Object { $_ -match 'Ek A' }).Count -lt 1){ $dusen += "SUTUN KIPI: gercek 'Ek A' basligi sozluk acmadi ($($tAd -join ' | '))" }
  $p1 = @($tp | Where-Object { $_.kaynak_ad -match 'TSRS 1 p\.1(\s|$)' })
  if($p1.Count -eq 1 -and "$($p1[0].metin)" -notmatch 'amaci'){ $dusen += "SUTUN KIPI: p.1 govdesi yanlis ($("$($p1[0].metin)".Substring(0,[Math]::Min(40,"$($p1[0].metin)".Length))))" }
  # sutun kipi BASKA standartta acilmamali (ad sarti)
  $bdsK = @(SY_Bol "5. BDS'ler, denetimin genel amaclarini belirler.`n`nA3. Ornek uygulama rehberi paragrafidir." 'BDS 200')
  if(@($bdsK).Count -lt 2){ $dusen += "SUTUN KIPI SIZDI: BDS bolmesi bozuldu ($(@($bdsK | ForEach-Object { $_.kaynak_ad }) -join ' | '))" }
  return $dusen
}

$sinav = @(SY_OzSinav)
if($sinav.Count){
  Write-Host '!! STANDART YUTUCU KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $sinav){ Write-Host "   $d" }
  exit 1
}
Write-Host 'Oz-sinav gecti (TMS kipi 11 · BDS kipi 5 · KILAVUZ kipi 4 [01.09 BOBI/KUMI duzeni] · kip secimi 2 · layout karari 3 · uzun baslik/sahte atif 2 · sarkan atif/dipnot 3 · sayfa no + kosu basligi 3 [14.09])'
Write-Host '  SINANMAYAN DALLAR: PDF indirme · pdftotext · ambar yazimi · geri okuma'
Write-Host ''

# --- 1) PDF
$arac = SY_PdfAraci
if(-not $arac){ Write-Host 'pdftotext bulunamadi.'; exit 1 }
# 02.09.2026 UCUNCU SEBEP (CI teshisi veri/surum-teshis-ci.md, kosu 20): 30.08'de
# $env:TEMP kusuru hat-onkontrol.ps1'de yamanmisti ama AYNISI burada da duruyordu.
# Linux runner'da $env:TEMP yok -> "Cannot bind argument to parameter 'Path'
# because it is null." -> surum kapisi 24/26 OLCULEMEDI -> KUCULME FRENI envanteri
# 30.08'den beri commit'lemedi (BOBI FRS canli 561, envanter 348 diyordu).
# DERS: ayni kusur icin BUTUN motoru tara, yalniz dusen dosyayi yamama.
$tmpKok = if($env:TEMP){ $env:TEMP } elseif($env:TMPDIR){ $env:TMPDIR } else { [IO.Path]::GetTempPath() }
$gecici = Join-Path $tmpKok ('sy-' + ($standart -replace '[^A-Za-z0-9]','') )
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
  } elseif($standart -match '^(BDS|GDS|SBDS|SGDS|İHS)\s'){
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
if((-not $duzen) -and ($standart -match '^(BDS|GDS|SBDS|SGDS|İHS)\s')){
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
  # 14.09 OLCULDU (81 standart kuru prova): poppler 34 BDS/GDS'nin 26'sinda xpdf'ten FAZLA paragraf veriyor
  # (BDS 300 13->38 · BDS 500 35->79 · BDS 570 26->62 parca), ama 8'inde (BDS 510/705/706/710/720/800/805/810)
  # satir basi numaralari sayfa numaralarindan az kaliyor. O 8'de xpdf duzgun cikiyordu. Kural: bozuksa
  # durmadan once IKINCI ARACLA (xpdf) ayni iki cikarim (duz + layout) denenir; o da bozuksa durulur.
  if(SY_LayoutGerekli $tamMetin $standart){
    $ikinciArac = @('C:\Program Files\Git\mingw64\bin\pdftotext.exe','C:\Program Files (x86)\Git\mingw64\bin\pdftotext.exe') | Where-Object { (Test-Path $_) -and $_ -ne $arac } | Select-Object -First 1
    if($ikinciArac){
      Write-Host "  cikarim bozuk ($arac) -> ikinci arac deneniyor: $ikinciArac" -ForegroundColor Yellow
      $ikinciDuz = Join-Path $gecici 'kaynak-2.txt'; $ikinciLay = Join-Path $gecici 'kaynak-2-layout.txt'
      & $ikinciArac -enc UTF-8 -nopgbrk $pdfYolu $ikinciDuz 2>$null | Out-Null
      & $ikinciArac -enc UTF-8 -nopgbrk -layout $pdfYolu $ikinciLay 2>$null | Out-Null
      # eski (xpdf) yolla BIREBIR: duz ve layout'tan satir basi numarasi COK olan secilir, sonra bozukluk sinanir
      $adayMetinler = @()
      foreach($adayYol in @($ikinciDuz,$ikinciLay)){
        if(-not (Test-Path $adayYol)){ continue }
        $adayMetin = [IO.File]::ReadAllText($adayYol,[Text.Encoding]::UTF8)
        $adaySayi = @(($adayMetin -split "`r?`n") | Where-Object { $_.Trim() -match '^A?\d{1,3}\.\s+\S' }).Count
        $adayMetinler += [pscustomobject]@{ metin=$adayMetin; sayi=$adaySayi }
      }
      $enIyiAday = $adayMetinler | Sort-Object sayi -Descending | Select-Object -First 1
      if($enIyiAday -and -not (SY_LayoutGerekli $enIyiAday.metin $standart)){ $tamMetin = $enIyiAday.metin; $arac = $ikinciArac; Write-Host ("  -> ikinci arac cikarimi secildi ({0:N0} karakter, satir basi numara {1})" -f $tamMetin.Length,$enIyiAday.sayi) }
    }
  }
  if(SY_LayoutGerekli $tamMetin $standart){
    Write-Host '!! CIKARIM BOZUK: satir basi numaralar sayfa numaralarindan az. Elle incele.' -ForegroundColor Red
    exit 1
  }
}

# --- 2) BOL
$yeni = @(SY_Bol $tamMetin $standart)
# 15.09: TMS/TFRS icin layout adayi. YALNIZ resmi metnin paragraf numaralarindan SAPMA (eksik+fazla+cift)
# AZALIYOR ve metin kaybi %2'yi gecmiyorsa secilir; esitlikte eski yol kalir (esdegerlik). Secim ekrana yazilir.
# ("delik" etiketi prova betiklerinin okudugu bicim; deger = hakikat sapmasi)
if((-not $duzen) -and ($standart -match '^(TMS|TFRS)\s')){
  $tmsLayoutYolu = Join-Path $gecici 'kaynak-tms-layout.txt'
  & $arac -enc UTF-8 -nopgbrk -layout $pdfYolu $tmsLayoutYolu 2>$null | Out-Null
  if(Test-Path $tmsLayoutYolu){
    $tmsLayoutMetni = [IO.File]::ReadAllText($tmsLayoutYolu,[Text.Encoding]::UTF8)
    $layoutAday = @(SY_Bol (SY_TmsLayoutDuzle $tmsLayoutMetni $standart) $standart)
    $tmsHakikat = SY_LayoutHakikat $tmsLayoutMetni
    $duzDelik = SY_HakikatSapmasi $yeni $tmsHakikat; $layDelik = SY_HakikatSapmasi $layoutAday $tmsHakikat
    $duzKr = ($yeni | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum
    $layKr = ($layoutAday | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum
    Write-Host ("  TMS layout adayi: delik duz {0} · layout {1} · karakter duz {2:N0} · layout {3:N0}" -f $duzDelik,$layDelik,$duzKr,$layKr)
    if($layoutAday.Count -gt 0 -and $layDelik -lt $duzDelik -and $layKr -ge ($duzKr * 0.98)){ $yeni = $layoutAday; Write-Host '  -> LAYOUT bolmesi secildi (resmi numaralardan sapma azaldi)' }
  }
}
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
if($PlanYaz){
  $planNesnesi = [ordered]@{ standart=$standart; url=$url; eski_adlar=@($eski | ForEach-Object { "$($_.kaynak_ad)" }); yeni_adlar=@($yeni | ForEach-Object { "$($_.kaynak_ad)" }); eski_karakter=$eskiKarakter; yeni_karakter=$yeniKarakter }
  [IO.File]::WriteAllText($PlanYaz,(ConvertTo-Json -InputObject $planNesnesi -Depth 4),(New-Object Text.UTF8Encoding($false)))
}

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
# ⚠ 30.08 KUSUR — TUR MIRASI YANLIS ETIKET YAYIYORDU.
# Eski hali: $turDegeri = $eski[0].tur (varsa), yoksa 'standart-madde'.
# Yani yeni kayitlarin turu, AMBARDAKI ILK ESKI KAYDIN turundan miras
# aliniyordu. Bir standardin kayitlari arasinda yanlislikla tek bir
# 'kanun-madde' varsa ve o ilk sirada geldiyse, standardin TAMAMI
# 'kanun-madde' olarak yeniden yaziliyordu.
# OLCULEN ZARAR (30.08 toplu onarim): GDS 3410'un 214 parcasi ve TMS 28'in
# 58 parcasi 'kanun-madde' olarak yazildi. Yutucu kendi geri okumasinda
# "DOGRULANDI" dedi - cunku o, TUR'e degil kaynak_ad'e bakiyor. Kayitlar
# standart olcumlerinde GORUNMEZ oldu (ambar 0 parca).
# IKINCI VE DAHA AGIR ETKI: 'kanun-madde' mevzuat-yukle.ps1'in SILME
# kapsamindadir, 'standart-madde' degildir. Yanlis etiketlenen bir standart,
# bir sonraki tam yuklemede SILINIR ve repo json'unda karsiligi olmadigi
# icin GERI GELMEZ. Yani bu kusur, sessizce kalici veri kaybi uretir.
# DOGRUSU: bu betik standart yutar; yazdigi tur her zaman 'standart-madde'
# olmalidir. Miras yalnizca BASKA BIR STANDART turu icinse kabul edilir.
$STANDART_TURLERI = @('standart-madde')
$mirasTur  = if($eski.Count){ "$($eski[0].tur)" } else { '' }
$turDegeri = if($mirasTur -and ($STANDART_TURLERI -contains $mirasTur)){ $mirasTur } else { 'standart-madde' }
if($mirasTur -and $mirasTur -ne $turDegeri){
  Write-Host ("  ! TUR DUZELTILDI: ambardaki eski kayitlar '{0}' turundeydi - yenisi '{1}' yaziliyor." -f $mirasTur,$turDegeri) -ForegroundColor Yellow
}
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
$geriHam = SY_Cek "$ambarUcu`?select=id,metin,tur&$suzgec&limit=2000"
$geri = @($geriHam)
$geriKarakter = 0; foreach($g in $geri){ $geriKarakter += "$($g.metin)".Length }

# 30.08 DERSI: bu sigorta parca sayisi + karakter topluyordu ama TUR'e HIC
# BAKMIYORDU. GDS 3410 ve TMS 28 yanlis turle ('kanun-madde') yazildi, sigorta
# "DOGRULANDI" dedi ve 272 kayit standart olcumlerinde GORUNMEZ oldu.
# Sayi tutuyor olmasi, kaydin DOGRU YERDE oldugu anlamina gelmez.
$yanlisTur = @($geri | Where-Object { "$($_.tur)" -ne $turDegeri })
if($yanlisTur.Count -gt 0){
  Write-Host ("!! TUR TUTMUYOR — {0} kayit '{1}' yerine baska turde: {2}" -f `
    $yanlisTur.Count, $turDegeri, (($yanlisTur | ForEach-Object { "$($_.tur)" } | Sort-Object -Unique) -join ', ')) -ForegroundColor Red
  Write-Host ("   Yedek duruyor: {0}" -f (Split-Path $yedekYolu -Leaf)) -ForegroundColor Red
  exit 1
}
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