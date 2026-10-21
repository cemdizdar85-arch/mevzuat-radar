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
  [switch]$BagRaporuYok,    # 16.09: yazımdan sonra arac/kaynak-bolunme-etki.ps1 koşmasın (varsayılan: koşar)
  [string]$PlanYaz = ''     # 14.09: kuru provada ESKI ve YENI parca adlarini bu JSON'a yazar (soru-kaynak bagi etkisi olcumu icin; ambara yazmaz)
  ,[switch]$YalnizSinav     # 27.09: yalniz oz-sinavi kos, cik (dogrula.yml matrisi icin; PDF/ambar yok)
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

# 22.09: yapisik dipnot ayirma (arac/dipnot-ayir.ps1) — "BDS 50027" -> "BDS 500", "aciklamalara64" -> "aciklamalara"
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'arac\dipnot-ayir.ps1')
function SY_Bol([string]$metin, [string]$std){
  $metin = DipnotAyir $metin
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
  # 16.09 (TFRS 9): TMS/TFRS kılavuz değildir. TFRS 9'un noktalı numaraları ("3.2.1") kılavuz kipini açıyor, B serisi (B3.1.1)
  #   ve bölüm başlıkları ("3.2 Finansal Varlıkların …") yanlış bölünüyordu. TMS/TFRS noktalı numarayı TMS kipinde okur (aşağıda).
  $kilavuzKip = ($kilavuzToplam -gt $tekBasina) -and ($kilavuzToplam -gt $satirBasi) -and ($std -notmatch '^(TMS|TFRS)\s')
  $satirBasiKip = (-not $kilavuzKip) -and ($satirBasi -gt $tekBasina)
  # 16.09: DÖRDÜNCÜ DÜZEN — numara sol sütunda, metin sağda (TSRS). Kip ADA bağlı açılır (metne göre değil) ki
  # başka standartların bölünmesi kazara değişmesin; TSRS dışında $sutunKip hep $false'tur.
  $sutunKip = ($std -match '^TSRS\s') -and (@($satirlar | Where-Object { $_ -match '^\s{0,12}[A-E]?\d{1,3}[A-Z]?\s{2,}\S' }).Count -ge 3)   # 16.09: ad zaten TSRS ile sinirli; sayi esigi yalnizca bos/bozuk metni eler
  $parcalar = New-Object System.Collections.Generic.List[object]
  $baslik = ''
  # 16.09 (TFRS 9): noktalı numaralı TMS/TFRS metninde (≥20 tek başına noktalı numara) tablo hücreleri kısa satır olarak gelir ve
  #   art arda 'başlık' sanılır; yalnız sonuncusu ada girer, öncekiler KAYBOLURDU (TFRS 9 örnek tabloları ≈7.900 kr). Bu kipte
  #   yerine yenisi gelen bekleyen başlık gövdeye eklenir. Öteki standartlarda davranış aynı.
  $noktaliKip = ($std -match '^(TMS|TFRS)\s') -and (@($satirlar | Where-Object { $_.Trim() -match '^[A-Z]{0,2}\d{1,2}(\.\d{1,2}){1,3}$' }).Count -ge 20)
  $bekleyenBaslik = ''
  $oncekiBaslikMetni = ''; $oncekiBaslikSuAn = $null; $oncekiBaslikYeniKural = $false   # 27.09: kullanilmadan ezilen baslik govdeye doner (yeni kural devredeyse)
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
  # ⭐ 07.10.2026 SARAN UZUN BASLIK (KGK oturumu, Cem "ikisini de yap"; altyapi olcumu: standartlarda 610 baslik kuyrugu adayi).
  #   BDS kipinde bolum basligi yalniz <=70 kr ise baslik sayiliyordu. PDF'te iki satira saran uzun baslikta 1. satir (>70) ONCEKI
  #   paragrafin GOVDESINE yapisiyor, 2. satir (kisa) tek basina baslik oluyordu: ambarda "BDS 701 p.13" govdesi "…Denetci Raporunda
  #   Bildirilmedigi" diye bitiyor, sonraki parca "BDS 701 p.14 - Durumlar" adini aliyordu (ikinci goz 07.10: KAPI-BP yanlis alarmlarinin
  #   koku). Kural (yalniz satir basi kipi, -layout'un SY_BdsBaslikBirlestir'i yokken): numarali paragraf satirinin HEMEN USTUNDEKI baslik
  #   bicimli 1 ya da 2 satir (noktalamasiz, buyuk harfle, ';:' yok, <=25 kelime, fiille bitmez, toplam <=180 kr) TEK baslik sayilir.
  #   Mutasyon: $env:SY_SARAN_MUTASYON=kapali. GORMEZ: uc satira saran baslik · paragraf satirinin ICINE gomulu baslik (onParca yolu ayri).
  $zorBaslik = New-Object System.Collections.Generic.HashSet[int]
  if($satirBasiKip -and "$env:SY_SARAN_MUTASYON" -ne 'kapali'){
    $parRx = '^(?:\S.{0,110}?\s+)?A?\d{1,3}[A-Z]?\.\s+\S'
    $basBicim = {
      param([string]$x)
      $x = $x.Trim()
      if($x.Length -lt 3 -or $x -match '[.:;,]$' -or $x -match '[;:]' -or $x -cnotmatch '^[A-ZÇĞİÖŞÜ“"]' -or $x -match '^A?\d{1,3}[A-Z]?\.\s' -or $x -match '^\d{1,3}$'){ return $false }
      if(@($x -split '\s+').Count -gt 25){ return $false }
      $son = ([regex]::Match($x, '\p{L}+(?=\P{L}*$)')).Value.ToLowerInvariant()
      if($son -match '(dır|dir|dur|dür|tır|tir|tur|tür|maz|mez|mış|miş|muş|müş)$' -or $son -in @('ve','veya','ile','ya','da','de','için')){ return $false }
      return $true
    }
    $doluSonraki = { param([int]$k) $m = $k + 1; while($m -lt $satirlar.Count -and ($satirlar[$m].Trim().Length -eq 0 -or $sayfaSatiri.Contains($m) -or $satirlar[$m].Trim() -match '^\d{1,3}$')){ $m++ }; return $m }
    for($bi = 0; $bi -lt $satirlar.Count; $bi++){
      $b1 = $satirlar[$bi].Trim()
      if($b1.Length -le 70 -or $b1.Length -gt 180 -or -not (& $basBicim $b1)){ continue }
      $oncekiBos = ($bi -eq 0) -or $satirlar[$bi-1].Trim() -match '[.:;!?)]$' -or $satirlar[$bi-1].Trim().Length -eq 0   # onceki satir cumleyle bitmeli (govdenin ortasi degil)
      if(-not $oncekiBos){ continue }
      $bj = & $doluSonraki $bi; if($bj -ge $satirlar.Count){ continue }
      $b2 = $satirlar[$bj].Trim()
      if($b2 -match $parRx){ [void]$zorBaslik.Add($bi); continue }
      if($b2.Length -le 70 -and (& $basBicim $b2) -and ($b1.Length + 1 + $b2.Length) -le 180){
        $bk = & $doluSonraki $bj
        if($bk -lt $satirlar.Count -and $satirlar[$bk].Trim() -match $parRx){ $satirlar[$bi] = "$b1 $b2"; $satirlar[$bj] = ''; [void]$zorBaslik.Add($bi) }
      }
    }
  }
  # ⭐ 21.10.2026 BOBI FRS ONARIMI (KGK oturumu; olcum scratchpad AMBAR-ONARIM-OLCUM 20.10 + BOBI-KURU-PROVA 21.10) — YALNIZ KILAVUZ KIPI.
  #   Ambardaki 561 BOBI kaydinin 64'u sonraki paragraflari yutmus, ≈219 paragrafin kendi kaydi yok. Iki kok:
  #   (1) 01.09 cikarimi Git'in xpdf 4.06'siyla yapildi (bugunku kod + xpdf metni ambari 561/561 ad+metin BIREBIR uretiyor, 21.10 olculdu):
  #       xpdf numarayi satir ICINE gomuyor ("… sınıflandırır. Kâr veya Zarar Tablosu 1.46 Kâr …"). SY_PdfAraci 14.09'dan beri poppler'i
  #       one aliyor; ayrica asagida SY_KilavuzSatirIci kapisi bu duzendeki metni yazmadan durdurur.
  #   (2) Poppler metninde bile kilavuz kipinin dort kusuru (bugunku kodla 738 parca, olculdu):
  #     (a) HARFLI NUMARA: "1.25A", "8.1A", "27.4A" … desen [A-Z] soneki almiyordu; 35 harfli paragrafin 35'i oncekine yapisiyordu.
  #     (b) MULGA "(-)": govdesi "(-)" olan paragraf (8.4, 8.11) 20 kr altinda kaldigi icin oncekine ekleniyor, ADI KALKIYORDU.
  #     (c) BASLIK: poppler bent metnini ("b)" + "Esas olarak ticari amaçla elde tutulması,") ve iki yana yaslanmis satirin tek
  #         kelimelerini ("Hatanın", "Yapılan") ayri satira koyar; 45 kr esigi bunlari baslik sanip GOVDEDEN ATIYOR (icerik kaybi) ve
  #         sonraki paragrafin adina yaziyordu. Kural: kilavuz kipinde baslik = ardindaki ilk dolu satiri (bos + sayfa no atlanarak)
  #         paragraf numarasi ya da "EK N –" olan satir; "BÖLÜM N" / TAMAMI BUYUK bolum adi zincirle (en cok 3) baglanir.
  #         Virgulle ya da "ve/veya/ile/ya da" ile biten satir baslik olamaz. 50+ kr bitisik satirlar (saran baslik: "Finansal
  #         Tabloların … Cinsinden" + "Sunulması") TEK baslik olur — eskiden ilk yarisi onceki paragrafin govdesine dusuyordu.
  #     (d) EK: "EK 1 – MÜNFERİT FİNANSAL DURUM TABLOSU" … "EK 9 - TANIMLAR" ayri ek blogu (Ek A gibi ~1800 kr dilim, ad
  #         "<STD> Ek N - <BASLIK> [k/n]"); eskiden 9 ekin tamami son paragrafa (27.15, 39.665 kr) yapisiyor, tablo satirlari dusuyordu.
  #     (e) ALT ALTA IKI NUMARA (1.3/1.4, 6.2/6.3) ve (f) SATIRA DUSEN ATIF (9.53, 17.2): ayrinti asagida, numara dalinda.
  #   Oteki kipler (TMS/TFRS, BDS/GDS satir basi, TSRS sutun) bu bloktan ETKILENMEZ: hepsi $kilavuzKip ile kapili.
  #   Mutasyon: $env:SY_KILAVUZ_MUTASYON = harf | mulga | baslik | ek | yigin | atif | bent | bentrakam | ustbaslik | sayfasaran | eski (eski = hepsi birden kapali, 21.10 oncesi davranis)
  #             + (c)'nin alt kurallari tek tek: baglac | saran | zincir | uzun · xpdf kapisi: satirici.
  #   GORMEZ: sayfa sinirinda bolunen baslik (ust yarisi onceki sayfada) · baslik ile numara arasinda govde satiri olan duzen ·
  #   iki karisik-harfli baslik ust uste (ilki zincire girmez, onceki paragrafin govdesine gider; icerik kaybolmaz).
  $kMut = "$env:SY_KILAVUZ_MUTASYON"
  $kHarf   = $kilavuzKip -and ($kMut -notin @('harf','eski'))
  $kMulga  = $kilavuzKip -and ($kMut -notin @('mulga','eski'))
  $kBaslik = $kilavuzKip -and ($kMut -notin @('baslik','eski'))
  $kEk     = $kilavuzKip -and ($kMut -notin @('ek','eski'))
  $kYigin  = $kilavuzKip -and ($kMut -notin @('yigin','eski'))   # (e) alt alta iki numara — asagida
  $kAtif   = $kilavuzKip -and ($kMut -notin @('atif','eski'))    # (f) satira dusen atif — asagida
  # ⭐ 21.10.2026 (ikinci tur, BOBI ambar yazimindan SONRA bulundu — bag kapisi "dayanak hicbir kayitta yok" dedi):
  #   (g) BENT + NUMARA: poppler son bendin isaretini ("c)", "(ii)") yazar, ALTINA sonraki paragrafin numarasini ("19.6"), sonra bendin
  #       metnini basar. Bent metni sonraki paragrafin BASINA gidiyordu (BOBI 10 paragraf: 1.33 5.27 9.51 11.11 13.3B 14.8 18.17 19.5
  #       19.18 23.33; ör. 19.5 "… ve c)" ile bitiyor, "Yükümlülük tutarının güvenilir … olması." 19.6'da). xpdf ve -layout ikisi de dogru.
  #       Kural: govdenin son dolu satiri YALNIZ bent isaretiyse gelen numara BEKLER (yigin (e) mekanizmasi); bent metni "." + bos satir +
  #       buyuk harfli satirda biter, numara orada acilir.
  #   (h) UST BASLIK: iki seviye baslik ust uste ("Genel Finansal Raporlama İlkeleri" / "İşletmenin Sürekliliği" / "1.14"). Ust satir
  #       zincire girmiyor, ONCEKI paragrafin govdesine yapisiyordu (BOBI 1.13, 10.6, 23.11). Kural: bos satirdan sonra (onceki dolu satir
  #       cumleyle ya da sayfa no ile biter) gelen ≤60 kr baslik bicimli satir, HEMEN altindaki (bos satirsiz) baslik numaraya
  #       baglaniyorsa o da basliktir; ad alt basligi alir (BÖLÜM zinciri gibi), ust baslik govdeye girmez.
  #   (i) SAYFA SINIRINDA SARAN BASLIK: 50+ kr baslik satirlarinin arasina sayfa no girerse ("… İlişkin Kur" / "69" / "Riskine veya …
  #       Karşı" / "Korunma" / "9.53") ilk yarisi onceki paragrafin govdesine dusuyordu (BOBI 9.52). Kural: saran birlesme bos satir +
  #       sayfa no'yu atlar (yalniz arada sayfa no varsa).
  #   Mutasyon: bent | bentrakam (rakamla baslayan paragraf, 18.18) | ustbaslik | sayfasaran (eski = hepsi kapali).
  $kBent   = $kilavuzKip -and ($kMut -notin @('bent','eski'))
  $kUst    = $kilavuzKip -and ($kMut -notin @('ustbaslik','eski'))
  $kSayfaSaran = $kilavuzKip -and ($kMut -notin @('sayfasaran','eski'))
  $kYiginSonraki = $null; $kOncekiDolu = ''; $kBosGordu = $false
  $kNo = if($kHarf){ '\d{1,2}(?:\.\d{1,2}){1,3}[A-Z]?' } else { '\d{1,2}(?:\.\d{1,2}){1,3}' }
  $kEkRx = '^EK\s+(\d{1,2})\s*[-–]\s*(\S.*)$'
  $kilBaslikMetin = @{}
  $kilAtla = New-Object System.Collections.Generic.HashSet[int]
  $kilEkModu = $false
  if($kBaslik){
    $kParRx = "^$kNo(?:\s+[^a-zçğıöşü\s].{3,})?$"
    $kBicim = {   # baslik bicimi (son-satir kurallari HARIC)
      param([string]$x)
      if($x.Length -lt 2 -or $x -match '\.{5,}' -or $x -match '[.:;]$' -or $x -match '[.!?][0-9]{1,3}$'){ return $false }
      if($x -cnotmatch '^[A-ZÇĞİÖŞÜ]' -or $x -cmatch $kParRx -or $x -match '^\d{1,3}$'){ return $false }
      return $true
    }
    $kSonUygun = {   # birimin SON satiri: virgul / baglac ile bitmez
      param([string]$x)
      if($kMut -eq 'baglac'){ return $true }   # mutasyon: son-satir kurali kapali
      if($x -match ',$'){ return $false }
      $sonKelime = ([regex]::Match($x, '\p{L}+(?=\P{L}*$)')).Value.ToLowerInvariant()
      return ($sonKelime -notin @('ve','veya','ile','ya','da','de','ise','ki','yahut'))
    }
    $kDoluSonraki = { param([int]$k) $m = $k + 1; while($m -lt $satirlar.Count -and ($satirlar[$m].Trim().Length -eq 0 -or $sayfaSatiri.Contains($m) -or $satirlar[$m].Trim() -match '^\d{1,3}$')){ $m++ }; return $m }
    $kBolumMu = { param([string]$x) ($x -cmatch '^BÖLÜM\s+\d{1,2}$') -or ($x -cnotmatch '\p{Ll}' -and $x -cmatch '\p{Lu}{3}') }
    # birimler: bitisik (arada bos satir yok) baslik bicimli satirlar; onceki satir >= 50 kr ise sarma sayilir ve birlesir
    $birimBas = @{}; $birimSon = @{}; $birimMetin = @{}
    $bi = 0
    while($bi -lt $satirlar.Count){
      $t = $satirlar[$bi].Trim()
      if($sayfaSatiri.Contains($bi) -or -not (& $kBicim $t)){ $bi++; continue }
      $son = $bi; $metin = $t
      while($kMut -ne 'saran'){
        $nx = $son + 1
        if($kSayfaSaran -and $satirlar[$son].Trim().Length -ge 50){   # (i) arada bos satir + sayfa no varsa atla
          $m = $son + 1; $sayfaGecti = $false
          while($m -lt $satirlar.Count -and ($satirlar[$m].Trim().Length -eq 0 -or $satirlar[$m].Trim() -match '^\d{1,3}$')){ if($satirlar[$m].Trim() -match '^\d{1,3}$'){ $sayfaGecti = $true }; $m++ }
          if($sayfaGecti -and $m -lt $satirlar.Count){ $nx = $m }
        }
        if(-not ($nx -lt $satirlar.Count -and $satirlar[$son].Trim().Length -ge 50 -and $satirlar[$son].Trim() -cnotmatch '^BÖLÜM\s+\d' -and (& $kBicim $satirlar[$nx].Trim()) -and ($metin.Length + 1 + $satirlar[$nx].Trim().Length) -le 250)){ break }
        $son = $nx; $metin = "$metin $($satirlar[$son].Trim())"
      }
      $birimBas[$bi] = $son; $birimMetin[$bi] = $metin; $birimSon[$son] = $bi
      $bi = $son + 1
    }
    $kNitelik = $null
    $kNitelik = {
      param([int]$b, [int]$derinlik)
      $son = $birimBas[$b]; $metin = $birimMetin[$b]
      if(-not (& $kSonUygun $satirlar[$son].Trim())){ return $false }
      if($metin.Length -gt 45){
        # uzun baslik: onceki dolu satir cumleyle/numarayla/sayfa no ile bitmeli ya da baslik olmali (govde ortasi degil)
        $o = $b - 1; while($o -ge 0 -and $satirlar[$o].Trim().Length -eq 0){ $o-- }
        if($o -ge 0){ $ot = $satirlar[$o].Trim(); if(-not ($ot -match '[.:;!?)”"]$' -or $ot -match '^\d{1,3}$' -or $ot -cmatch $kParRx -or $birimSon.ContainsKey($o))){ return $false } }
      }
      $n = & $kDoluSonraki $son
      if($n -ge $satirlar.Count){ return $false }
      $nt = $satirlar[$n].Trim()
      if($nt -cmatch $kParRx -or ($nt -cmatch $kEkRx -and $nt -notmatch '\.{5,}')){ return $true }
      if($kMut -ne 'zincir' -and $derinlik -lt 3 -and (& $kBolumMu $metin) -and $birimBas.ContainsKey($n)){ return (& $kNitelik $n ($derinlik + 1)) }
      # (h) ust baslik: bos satirdan sonra gelen kisa baslik, BOS SATIRSIZ altindaki baslik numaraya baglaniyorsa
      if($kUst -and $derinlik -eq 0 -and $n -eq ($son + 1) -and $birimBas.ContainsKey($n) -and $metin.Length -le 60 -and -not (& $kBolumMu $metin) -and $b -ge 1 -and $satirlar[$b-1].Trim().Length -eq 0){
        $o = $b - 1; while($o -ge 0 -and ($satirlar[$o].Trim().Length -eq 0 -or $satirlar[$o].Trim() -match '^\d{1,3}$')){ $o-- }
        if($o -ge 0 -and $satirlar[$o].Trim() -match '[.:;!?)”"]$'){ return (& $kNitelik $n 1) }
      }
      return $false
    }
    foreach($b in @($birimBas.Keys)){
      if(& $kNitelik $b 0){
        $kilBaslikMetin[$b] = $birimMetin[$b]
        for($a = $b + 1; $a -le $birimBas[$b]; $a++){ [void]$kilAtla.Add($a) }
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
    # 21.10 (d) kilavuz kipi eki: "EK 1 – MÜNFERİT FİNANSAL DURUM TABLOSU" (icindekiler satiri dolgulu oldugu icin acmaz)
    if($kEk -and $s -cmatch $kEkRx -and $s -notmatch '\.{5,}'){
      $kEkNo = $Matches[1]; $kEkAd = $Matches[2].Trim()
      if($kYiginSonraki){ if($suAn){ $parcalar.Add($suAn) }; $suAn = $kYiginSonraki; $kYiginSonraki = $null }
      if($suAn){ $parcalar.Add($suAn) }
      $ekEtiketi = "Ek $kEkNo"; $kilEkModu = $true; $baslik = ''
      $suAn = [ordered]@{ onek=''; no=0; sonek=''; ekBlok=$true; ekAd="Ek $kEkNo - $kEkAd"; ek=$ekEtiketi; govde=New-Object System.Collections.Generic.List[string] }
      continue
    }
    if($kilEkModu){ if($s.Length -gt 0 -and $s -notmatch '^\d{1,3}$'){ $suAn.govde.Add($s) }; continue }   # ek tablosu: her satir govde, sayfa no haric
    if($kilAtla.Contains($satirSirasi)){ continue }   # 21.10 (c) saran basligin devam satiri (basliga birlesti)

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
    # 16.09 (Cem "2 ve 3 yap", KGK hakikat EKSİK'leri): aynı kusur TMS/TFRS'de de vardı — satır başına düşen "Ek A'daki finansal risk tanımı…"
    #   (TFRS 17 B8 gövdesi) ve "Ek A Bölümü'nde ve TMS 28'in … tanımlanmaktadır:" (TMS 27 p.5) sözlük kipini açıp B8–B32 / p.6–18H'yi yuttu.
    #   Başlık şartı (SY_EkBasligiMi): harfin ardından kesme işareti yok · noktalamayla bitmez · ≤120 kr.
    if($s -match '^Ek\s+A\b' -and (SY_EkBasligiMi $s) -and (-not $sutunKip -or $s -match '^Ek\s+A\s*$')){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$true; $baslik='Ek A - Tanımlanan terimler'; continue }
    if($s -match '^Ek\s+([B-Z])\b' -and (SY_EkBasligiMi $s) -and (-not $sutunKip -or $s -match '^Ek\s+[B-Z]\s*$')){ if($suAn){ $parcalar.Add($suAn); $suAn=$null }; $sozlukModu=$false; $baslik=$s; continue }
    # 16.09: Ek A her zaman sözlük DEĞİLDİR — TMS 21/33/36, TFRS 19'da numaralı uygulama rehberidir (A1, A2 …). TMS kipinde
    #   sözlükteyken TEK BAŞINA "A<n>" satırı gelirse sözlük kapanır, satır aşağıdaki numaralı paragraf dalına düşer.
    if($sozlukModu -and (-not $satirBasiKip) -and (-not $kilavuzKip) -and (-not $sutunKip) -and $s -match '^A\d{1,3}[A-Z]{0,2}$'){
      if($suAn){ $parcalar.Add($suAn); $suAn=$null }
      $sozlukModu=$false; $baslik='Ek A'
    }

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
    # 21.10 (a): $kNo harfli soneki de alir ("1.25A Metin"); -cmatch: sonek yalniz BUYUK harf
    if($kilavuzKip -and $s -cmatch "^($kNo)\s+(\S.{3,})$" -and -not ($Matches[2] -cmatch '^[a-zçğıöşü]') -and $s -notmatch '\.{5,}'){
      $gNoStr=$Matches[1]; $gGovde=$Matches[2]
      if($kYiginSonraki){ if($suAn){ $parcalar.Add($suAn) }; $suAn = $kYiginSonraki; $kYiginSonraki = $null }
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu=$false
      $suAn = [ordered]@{ onek=''; no=$gNoStr; sonek=''; baslik=$baslik; kil=$true; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($gGovde)
      continue
    }
    # kilavuz kipi, ondalikli numara KENDI SATIRINDA ("1.3" tek, "1.25A" tek) - BOBI duzeni
    if($kilavuzKip -and $s -cmatch "^($kNo)$"){
      $kTekNo = $Matches[1]
      # 21.10 (f) SATIRA DUSEN ATIF: iki yana yaslanmis satirda "bölümünün" / "9.53" / "paragrafının (a) …" — numara paragraf degil,
      #   cumlenin parcasidir (BOBI 9.53 ve 17.2 ikinci kez paragraf aciyordu: sahte cift + gercek paragrafin ortadan bolunmesi).
      #   Kural: onceki dolu satir cumle noktalamasiyla bitmiyor VE sonraki dolu satir kucuk harfli bir SOZCUKLE basliyorsa govdedir.
      if($kAtif -and $suAn){
        $kOn = $satirSirasi - 1; while($kOn -ge 0 -and $satirlar[$kOn].Trim().Length -eq 0){ $kOn-- }
        $kArd = $satirSirasi + 1; while($kArd -lt $satirlar.Count -and $satirlar[$kArd].Trim().Length -eq 0){ $kArd++ }
        if($kOn -ge 0 -and $kArd -lt $satirlar.Count -and $satirlar[$kOn].Trim() -notmatch '[.:;!?)]$' -and $satirlar[$kArd].Trim() -cmatch '^[a-zçğıöşü]{3,}'){
          $suAn.govde.Add($s); $kOncekiDolu = $s; $kBosGordu = $false; continue
        }
      }
      # 21.10 (e) ALT ALTA IKI NUMARA: poppler duz cikarimi "1.3" / "1.4" / <1.3 metni> / <1.4 metni> basiyor (BOBI 1.3-1.4, 6.2-6.3;
      #   -layout ve xpdf ikisini de dogru yerde gosteriyor). Eskiden 1.3 bos kalip ADI KALKIYOR, metni 1.4'e gidiyordu. Kural: govdesiz
      #   numaranin ardindan ikinci numara gelirse ikincisi BEKLER; ilk metin, "." ile biten satirdan ve bos satirdan sonra buyuk harfle
      #   baslayan ilk satirda (bent isareti degil) biter, ikinci numara orada acilir.
      # 21.10 (g) BENT + NUMARA: govdenin son dolu satiri yalniz bent isareti ("c)", "(ii)") ise numara bekler, bent metni bu paragrafta kalir
      if($kBent -and $suAn -and $suAn.Contains('kil') -and $suAn.govde.Count -gt 0 -and -not $kYiginSonraki -and $kOncekiDolu -cmatch '^\(?(?:[a-zçğıöşü]{1,2}|[ivx]{1,5})\)$'){
        $kYiginSonraki = [ordered]@{ onek=''; no=$kTekNo; sonek=''; baslik=$baslik; kil=$true; bentBekler=$true; govde=New-Object System.Collections.Generic.List[string] }
        continue
      }
      if($kYigin -and $suAn -and $suAn.Contains('kil') -and $suAn.govde.Count -eq 0 -and -not $kYiginSonraki){
        $kYiginSonraki = [ordered]@{ onek=''; no=$kTekNo; sonek=''; baslik=$baslik; kil=$true; govde=New-Object System.Collections.Generic.List[string] }
        continue
      }
      if($kYiginSonraki){ if($suAn){ $parcalar.Add($suAn) }; $suAn = $kYiginSonraki; $kYiginSonraki = $null }
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu=$false
      $suAn = [ordered]@{ onek=''; no=$kTekNo; sonek=''; baslik=$baslik; kil=$true; govde=New-Object System.Collections.Generic.List[string] }
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
    # 16.09: Türkiye'ye özgü sonekli paragraf (BDS 700/720 "20T.", GDS 3410 "25S.", "38M.") — sonek grubu eklendi
    if($satirBasiKip -and $s -cmatch '^(?:(.{0,110}?)\s+)?(A?)(\d{1,3})([A-Z]?)\.\s+(\S.{5,})$' -and -not ($Matches[5] -cmatch '^[a-zçğıöşü]')){
      # ⚠⚠ ONCE GRUPLARI KOPYALA. PowerShell'de HER -match/-notmatch/-cmatch
      # $Matches'i YENIDEN YAZAR. Ilk surumde asagidaki baslik kontrolu
      # ($onParca -notmatch ...) $Matches'i eziyordu ve sonraki satirdaki
      # $Matches[2..4] BASKA bir eslesmeye bakiyordu -> BDS oz-sinavi 4 yerine
      # 2 parca cikardi. Sinav olmasaydi bu, 30 BDS'de sessizce ice islerdi.
      $gOnEk   = $Matches[2]
      $gNo     = [int]$Matches[3]
      $gSonek  = $Matches[4]
      $gGovde  = $Matches[5]
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
      $suAn = [ordered]@{ onek=$gOnEk; no=$gNo; sonek=$gSonek; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $suAn.govde.Add($gGovde)
      continue
    }
    # BDS kipinde TEK BASINA duran sayi = SAYFA NUMARASI, paragraf DEGIL.
    if($satirBasiKip -and $s -match '^\d{1,3}$'){ continue }

    # --- numarali paragraf: 12 · A1 · B9 · C20D   (kendi satirinda)
    # 16.09: önek A–E ve "UR" (TMS 32 uygulama rehberi), sonek iki harfe kadar (TFRS 1 39AH, TFRS 7 44ZA, TFRS 16 C20BA)
    # 16.09: noktalı numara (TFRS 9 "3.2.1", "B5.4.17") — yalnız TMS/TFRS adında; öteki standartlarda desen eskisi gibi
    $noktaliDesen = if($std -match '^(TMS|TFRS)\s'){ '^([A-E]|UR)?(\d{1,3})((?:\.\d{1,3}){0,3})([A-Z]{0,2})$' } else { '^([A-E]|UR)?(\d{1,3})()([A-Z]{0,2})$' }
    if((-not $satirBasiKip) -and (-not $kilavuzKip) -and $s -match $noktaliDesen){
      if($suAn){ $parcalar.Add($suAn) }
      $sozlukModu = $false
      $tmsNo = if($Matches[3]){ "$($Matches[2])$($Matches[3])" } else { [int]$Matches[2] }
      $suAn = [ordered]@{ onek="$($Matches[1])"; no=$tmsNo; sonek=$Matches[4]; baslik=$baslik; govde=New-Object System.Collections.Generic.List[string] }
      $bekleyenBaslik = ''
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
    if($s.Length -eq 0){ $kBosGordu = $true; continue }   # 21.10 (e): bos satir izi yalniz kilavuz yiginda okunur

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
    # 21.10 (c): kilavuz kipinde baslik YALNIZ onceden secilen satirlardir (ardindan numara gelen); geri kalan her satir govdedir
    if($kBaslik -and $kilBaslikMetin.ContainsKey($satirSirasi)){
      if($null -eq $suAn -or $suAn.govde.Count -gt 0){ $baslik = $kilBaslikMetin[$satirSirasi]; continue }
      $suAn.govde.Add($kilBaslikMetin[$satirSirasi]); continue   # numara satirindan hemen sonra gelen baslik bicimli satir govdedir (eski kosul aynen)
    }
    $baslikEsik = if($kilavuzKip){ 45 } else { 70 }
    # 27.09 (BDS 300 p.A24 "İlk Denetimlerde Dikkate Alınacak İlâve Hususlar (Bkz.: 12 nci paragraf)" 73 kr): BDS kipinde "(Bkz.: …)" ile
    #   biten satir bolum basligidir; 70 kr esigi bu baslik ailesine 180 kr olarak uygulanir (yalniz satir basi kipi, oteki kipler aynen).
    #   Parantezden ONCEKI kisimda cumle noktalamasi olmaz (KYS 1 "Personel: … çalışanlardır. (Bkz.: A20–A21 paragrafı)" tanim satiridir, baslik degil).
    $bkzBaslik = $satirBasiKip -and $s.Length -le 180 -and $s -match '^[^.:;()]{3,}\((Bkz|Bakınız)\.?:(?:[^()]|\([^()]*\))*\)$'
    #   Tirnakla baslayan Bkz basligi da basliktir (BDS 200 "“Önemli Yanlışlık” Riski (Bkz.: 13(h) paragrafı)" govdeye dusuyor, A16 bir onceki basligi aliyordu).
    $tirnakBkz = $bkzBaslik -and $s.Length -gt 1 -and ($s[0] -eq [char]0x201C -or $s[0] -eq [char]0x22) -and ("$($s[1])" -cmatch '[A-ZÇĞİÖŞÜ]')
    $zorlu = $zorBaslik.Contains($satirSirasi)   # 07.10 saran uzun baslik (yukarida)
    if((-not $kBaslik) -and ($s.Length -le $baslikEsik -or $bkzBaslik -or $zorlu) -and $s -notmatch '[.:;]$' -and $s -notmatch '[.!?][0-9]{1,3}$' -and ($s -cmatch '^[A-ZÇĞİÖŞÜ]' -or $tirnakBkz) -and ($null -eq $suAn -or $suAn.govde.Count -gt 0)){
      if($noktaliKip -and $bekleyenBaslik -and $suAn){ $suAn.govde.Add($bekleyenBaslik) }
      # 27.09: yeni kuralla (70 kr ustu / tirnakli Bkz) taninan baslik HIC KULLANILMADAN yerine baska baslik gelirse eskisi gibi govdeye
      #   yazilir (ICERIK ATILMAZ; ust-alt iki baslik art arda: BDS 315 "İşletme ve Çevresi, … (Bkz.: A48-A49)" + "İşletme ve Çevresi ile … (Bkz.: A50-A55)").
      #   Ayni sey tersine de gecerli: eski kuralla baslik sanilan govde parcasi ("Bu tür tehditlerin … etkenler ve", KYS 2) yeni kuralli
      #   baslikla ezilirse govdeye doner. Iki baslik da eski kurallıysa davranis ESKISI GIBI kalir (esdegerlik).
      $simdikiYeniKural = -not ($s.Length -le $baslikEsik -and $s -cmatch '^[A-ZÇĞİÖŞÜ]')
      if($oncekiBaslikMetni -and $suAn -and [object]::ReferenceEquals($oncekiBaslikSuAn,$suAn) -and ($oncekiBaslikYeniKural -or $simdikiYeniKural)){ $suAn.govde.Add($oncekiBaslikMetni) }
      $oncekiBaslikMetni = $s; $oncekiBaslikSuAn = $suAn; $oncekiBaslikYeniKural = $simdikiYeniKural
      $baslik = $s
      $bekleyenBaslik = $s
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
    # 21.10 (e): bekleyen ikinci numara, ilk numaranin metni bitince (". " + bos satir + buyuk harf, bent isareti degil) acilir
    #   (g) bent bekleyisinde paragraf rakamla da baslayabilir ("18.16 paragrafının (b) …" — BOBI 18.18; yalniz buyuk harf kosulu 18.18'i 18.17'ye yapistirdi)
    if($kYiginSonraki -and $suAn.govde.Count -gt 0 -and $kBosGordu -and $kOncekiDolu -match '\.$' -and ($s -cmatch '^[A-ZÇĞİÖŞÜ“"]' -or ($kMut -ne 'bentrakam' -and $kYiginSonraki.Contains('bentBekler') -and $s -match '^\d'))){
      $parcalar.Add($suAn); $suAn = $kYiginSonraki; $kYiginSonraki = $null
    }
    $suAn.govde.Add($s)
    $kOncekiDolu = $s; $kBosGordu = $false
  }
  if($kYiginSonraki){ if($suAn){ $parcalar.Add($suAn) }; $suAn = $kYiginSonraki; $kYiginSonraki = $null }   # 21.10 (e) metin sonunda bekleyen
  if($suAn){ if(-not $suAn.Contains('ek')){ $suAn['ek'] = $ekEtiketi }; $parcalar.Add($suAn) }
  # kayda cevir
  $kayitlar = New-Object System.Collections.Generic.List[object]
  $kUzunBaslik = New-Object System.Collections.Generic.HashSet[string]   # 21.10 (c) 160 kr'yi asan kilavuz basligi bir kez govdeye
  foreach($p in $parcalar){
    $govde = (@($p.govde) -join ' ').Trim()
    # ⚠ ICERIK ATILMAZ (25.08 dersi). Ilk surum govdesi 20 karakterden kisa
    # olani "bos paragraf" sayip ATIYORDU; sozluk kipinde satir sonu kirilan
    # kisa satirlar boyle terim sanilip dusuyordu ve TOPLAM KARAKTER AZALIYORDU.
    # 210 parca / 105.905 krk, 128 parca / 106.600 krk'den AZDI - parca
    # kazanirken metin kaybediyorduk. Cozum: kisa parcayi ATMA, BIR ONCEKINE EKLE.
    # Butun mesele "yarim kalmasin" idi; kirpip parca sayisi buyutmek onu bozar.
    # 21.10 (b): kilavuz kipinde "(-)" govdeli mulga paragraf KENDI ADIYLA kalir (BOBI 8.4/8.11; once oncekine eklenip adi kalkiyordu)
    $kilMulgaMi = $kMulga -and $p.Contains('kil') -and $govde -match '^\(\s*[-–]\s*\)$'
    if($govde.Length -lt 20 -and -not $kilMulgaMi){
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
        $ekBlokAdi = if($p.Contains('ekAd')){ (($p.ekAd -replace '\s+',' ').Trim()) } else { 'Ek A - Tanımlanan terimler' }   # 21.10 (d) kilavuz eki
        $kayitlar.Add([pscustomobject]@{ kaynak_ad="$std $ekBlokAdi [$sira/$toplamDilim]"; metin=$dilim })
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
    if($ad.Length -gt 160){
      # 21.10 (c): kilavuz kipinde baslik govdeden cikar; ad 160 kr'de kesilince basligin kuyrugu HICBIR YERDE kalmiyordu
      #   (BOBI 20.24 "… Müşterek Girişimlerin Finansal Tablolarının Çevrimi" → "… Müşterek Gir"). Tam baslik, onu tasiyan ILK parcanin govdesine yazilir.
      if($kBaslik -and $kMut -ne 'uzun' -and $p.Contains('kil') -and $p.baslik -and $kUzunBaslik.Add("$($p.baslik)")){ $govde = ("$($p.baslik) $govde").Trim() }
      $ad = $ad.Substring(0,160)
    }
    $kayitlar.Add([pscustomobject]@{ kaynak_ad=$ad; metin=$govde })
  }
  # ⚠ "return ,$kayitlar" YAZMA. Virgul listeyi SARMALAR ve cagirandaki @()
  # onu ACMAZ -> tek elemanli dizi doner. Bu tuzak 25.08'de UC KEZ vurdu
  # (kart-kontrol · kesik-metin-nobeti · burada). ToArray() net cozum.
  return $kayitlar.ToArray()
}

function SY_KilavuzSatirIci([string]$metin){
  # ⭐ 21.10.2026 — XPDF DUZENI KAPISI (BOBI FRS koku 1). 01.09'da BOBI, Git'in xpdf 4.06'siyla cikarildi; xpdf ondalikli paragraf
  #   numarasini satirin ICINE gomer ("… uzun vadeli olarak sınıflandırır. Kâr veya Zarar Tablosu 1.46 Kâr veya Zarar Tablosu, …").
  #   Kilavuz kipi yalniz satir BASINDAKI numarayi gorur → 64 kayit sonraki 1-19 paragrafi yuttu, ≈219 paragraf ad almadi.
  #   Olcu: satir ICINDE (onunde dolu karakter) "N.N[A]" + bosluk + Buyuk harf ↔ satir basinda duran numara. Bozuk: ic >= 20 ve ic >= bas/5.
  #   21.10 olculdu (BOBI EK 2.pdf): xpdf satir ici 186 / satir basi 623 → BOZUK · poppler 2 ("1 $ = 2.50 TL; …") / 835 → saglam.
  #   GORMEZ: satir ici numaradan sonra kucuk harf/tirnakla baslayan paragraf · tamsayi numarali (BDS "12.") duzen · TMS/TFRS noktali numara (kapi orada uygulanmaz).
  $ic = [regex]::Matches($metin, '(?<=\S)[ \t]+\d{1,2}\.\d{1,2}[A-Z]?[ \t]+(?=[A-ZÇĞİÖŞÜ“])').Count   # [ \t]: satir sonunu ASMAZ (\s asar, poppler'da sahte 467 saydi)
  $bas = @(($metin -split "`r?`n") | Where-Object { $_.Trim() -cmatch '^\d{1,2}\.\d{1,2}[A-Z]?(\s|$)' }).Count
  $bozuk = ($ic -ge 20 -and ($ic * 5) -ge $bas) -and ("$env:SY_KILAVUZ_MUTASYON" -ne 'satirici')   # mutasyon: kapi kapali
  return [pscustomobject]@{ satirIci=$ic; satirBasi=$bas; bozuk=$bozuk }
}

function SY_EkBasligiMi([string]$satir){
  # 16.09: gerçek ek başlığı "Ek A", "EK A", "Ek A - Tanımlanan terimler", "EK A Değer kullanımını tahmin etmek için …".
  # Metin içi atıf "Ek A'daki …", "Ek A Bölümü'nde … tanımlanmaktadır:" başlık değildir.
  if($satir -match "^Ek\s+[A-Z]\s*[’'‘``´]"){ return $false }
  # 16.09 (TFRS 12 C1B): "Ek A değiştirilmiş ve 9A–9B … eklenmiştir. Söz konusu …" — harften sonra küçük harfle devam eden ya da
  #   ortasında cümle biten satır başlık değildir.
  if($satir -cmatch '^Ek\s+[A-Z]\s+[a-zçğıöşü]'){ return $false }
  if($satir -match '[.;]\s+\S'){ return $false }
  if($satir -match '[.:;,]$'){ return $false }
  if($satir.Length -gt 120){ return $false }
  return $true
}

function SY_DipnotAyikla([string]$metin){
  # ⚠ 27.09.2026 DERSI — BDS DIPNOTLARI BASLIGA VE GOVDEYE KARISIYORDU (soru yazicilari: BDS 200/210/300/315/330/520/701).
  # -layout cikariminda sayfa dibi dipnotu iki bicimde gelir:
  #   poppler : "4"  (sutun 0, tek basina)  +  "    BDS 220 (Revize), 25 inci paragraf"  (girintili metin)
  #   xpdf    : "2 BDS 200, “Bağımsız Denetçinin ...”"  (sutun 0, numara + bosluk + metin)  +  "  Olarak Yürütülmesi”"
  # BDS kipi tek basina sayiyi SAYFA NO sayip atiyordu; ardindaki KISA dipnot metni ("BDS 220 (Revize), 25 inci paragraf")
  # bolum BASLIGI sanildi ve sonraki paragraflarin ADINA girdi (BDS 300 p.10-11, BDS 520 p.A16-A21, BDS 701 p.5/A7);
  # uzun dipnot metni o sirada acik paragrafin GOVDESINE karisti. Govdedeki dipnot ISARETI de ("kontrolün 14 bulunduğu",
  # "zorundadır. 12 Dolayısıyla", "değerlendirme,2") metinde kaliyordu.
  # KURAL: (1) dipnot blogu = sutun 0'da SIRA NUMARALI (beklenen..beklenen+2) dipnot numarasi + girintili metin.
  #   (2) blok yerinden alinir, "[Dipnot N: metin]" satiri olarak ACIK PARAGRAFIN SONUNA (bir sonraki sutun-0 satirindan
  #   once) konur — ICERIK ATILMAZ (25.08 dersi), yalniz basliga/cumle ortasina girmez.
  #   (3) govdedeki isaret, ayni sayfada (onceki sayfa no satirindan sonra, bloktan once) ve onceki isaretten SONRA aranir;
  #   yalniz isaret baglaminda silinir: harfe yapisik ("dâhil8,"), noktalama ardi (", 1" · ".3" · ". 12 D"), standart
  #   numarasina yapisik ("BDS 3306’da"). Zayif baglam ("kontrolün 14 bulunduğu": harf+bosluk+N+kucuk harf) yalniz guclu
  #   aday yoksa ve ardindaki sozcuk sira/sure eki degilse ("13 üncü", "12 ay") kullanilir. Bulunamazsa DOKUNULMAZ, sayilir.
  # BU KURAL SUNU GORMEZ: duz (layout olmayan) cikarim (girinti yok -> blok taninmaz, metin aynen doner) ·
  #   sira disi numarali dipnot · (a)/(b) gibi PDF metin katmaninda HIC OLMAYAN bent harfleri (27.09 olculdu: BDS 701 p.17).
  # Donus: [pscustomobject]@{ metin; dipnot; isaret; cozulemeyen }
  $satirlar = @($metin -split "`r?`n")
  $n = $satirlar.Count
  $dolu = @($satirlar | Where-Object { $_.Trim() }).Count
  $girintili = @($satirlar | Where-Object { $_ -match '^\s{4,}\S' }).Count
  $sonuc = [pscustomobject]@{ metin=$metin; dipnot=0; isaret=0; cozulemeyen=0; iz=(New-Object System.Collections.Generic.List[string]) }
  if($dolu -eq 0 -or $girintili -lt ($dolu * 0.2)){ return $sonuc }   # layout degil: dokunma
  $sayfaDesen = '^\s{10,}(\d{1,3}|\*{3})\s*$'
  $blokSatiri = New-Object System.Collections.Generic.HashSet[int]
  $bloklar = New-Object System.Collections.Generic.List[object]
  $beklenen = 1
  for($i = 0; $i -lt $n; $i++){
    $sat = $satirlar[$i]
    $dNo = -1; $ilkMetin = ''; $govdeBas = -1
    $tek = [regex]::Match($sat,'^(\d{1,3})\s*$')
    $bitisik = [regex]::Match($sat,'^(\d{1,3}) (\S.*)$')
    if($tek.Success){
      $k = $i + 1; while($k -lt $n -and -not $satirlar[$k].Trim()){ $k++ }
      if($k -lt $n -and $k -le $i + 2 -and $satirlar[$k] -match '^\s{2,8}\S' -and $satirlar[$k] -notmatch $sayfaDesen){ $dNo = [int]$tek.Groups[1].Value; $govdeBas = $k }
    } elseif($bitisik.Success -and ($i -eq 0 -or -not $satirlar[$i-1].Trim() -or $blokSatiri.Contains($i-1)) -and $bitisik.Groups[2].Value -cnotmatch '^[a-zçğıöşü]'){
      $dNo = [int]$bitisik.Groups[1].Value; $ilkMetin = $bitisik.Groups[2].Value.Trim(); $govdeBas = $i + 1
    }
    # ek bolumlerinde (BDS 720 Ek 2 ornek raporlari) dipnot numarasi 1'den YENIDEN baslar: 1 her zaman kabul edilir
    if($dNo -lt 0 -or (($dNo -lt $beklenen -or $dNo -gt $beklenen + 2) -and $dNo -ne 1)){ continue }
    $parcaMetin = New-Object System.Collections.Generic.List[string]
    if($ilkMetin){ $parcaMetin.Add($ilkMetin) }
    [void]$blokSatiri.Add($i)
    $k = $govdeBas
    while($k -lt $n){
      $ks = $satirlar[$k]
      if(-not $ks.Trim()){ break }
      if($ks -match $sayfaDesen){ break }
      if($ks -notmatch '^\s{1,8}\S'){ break }
      $parcaMetin.Add($ks.Trim()); [void]$blokSatiri.Add($k); $k++
    }
    for($b = $i + 1; $b -lt $govdeBas; $b++){ [void]$blokSatiri.Add($b) }
    if($parcaMetin.Count -eq 0){ [void]$blokSatiri.Remove($i); continue }
    $bloklar.Add([pscustomobject]@{ no=$dNo; satir=$i; metin=(($parcaMetin -join ' ') -replace '\s{2,}',' ') })
    $beklenen = $dNo + 1
    $i = $k - 1
  }
  if($bloklar.Count -eq 0){ return $sonuc }
  # --- govdedeki isaretler
  $sira = '^(inci|ıncı|üncü|uncu|nci|ncı|ncü|ncu|ay|aylık|yıl|yıllık|gün|günlük|hafta|saat|adet|kez|defa|kat|puan|kişi|ve|veya|ile|ila|ya|yüzde)\b'
  $sonIsaretSatir = -1; $sonIsaretSutun = -1; $sonBlokSatir = -1
  foreach($blk in $bloklar){
    $bolgeBas = 0
    for($g = $blk.satir - 1; $g -ge 0; $g--){ if($satirlar[$g] -match $sayfaDesen){ $bolgeBas = $g + 1; break } }
    if($sonIsaretSatir -ge $bolgeBas){ $aramaBas = $sonIsaretSatir } else { $aramaBas = $bolgeBas }
    $nStr = [string]$blk.no
    $guclu = $null; $zayif = $null
    for($g = $aramaBas; $g -lt $blk.satir -and -not $guclu; $g++){
      if($blokSatiri.Contains($g)){ continue }
      $gs = $satirlar[$g]
      $basSutun = if($g -eq $sonIsaretSatir){ $sonIsaretSutun } else { 0 }
      $adaylar = New-Object System.Collections.Generic.List[object]
      foreach($m in [regex]::Matches($gs,'(?<=\p{L}{3})' + $nStr + '(?!\d)(?=[\s,.;:)\u201D\u2019]|$)')){ $adaylar.Add([pscustomobject]@{ bas=$m.Index; boy=$m.Length; guc=$true }) }
      foreach($m in [regex]::Matches($gs,'(?<=[^\d\s][.,;:\u201D\u2019)])( ?)' + $nStr + '(?!\d)(?=\s|$|[,;:])')){
        $sonrasi = $gs.Substring($m.Index + $m.Length).TrimStart()
        if($sonrasi -match $sira){ continue }
        if($gs.Substring(0,$m.Index) -match '(?i)\((tms|tfrs|bds|gds|kys|tsrs)\)$'){ continue }   # "Türkiye Muhasebe Standardı (TMS) 1" standart numarasidir (BDS 570, 27.09)
        $adaylar.Add([pscustomobject]@{ bas=$m.Index; boy=$m.Length; guc=$true })
      }
      foreach($m in [regex]::Matches($gs,'\b(?:BDS|GDS|İHS|IHS|KYS|SBDS)\s?(\d{3,4})' + $nStr + '(?!\d)')){
        $kok = [int]$m.Groups[1].Value
        $aile = ($m.Value -replace '[\s\d].*$','').Replace('İ','I')
        if($STD_NO.ContainsKey($aile) -and ($STD_NO[$aile] -contains $kok)){ $adaylar.Add([pscustomobject]@{ bas=($m.Index + $m.Length - $nStr.Length); boy=$nStr.Length; guc=$true }) }
      }
      # "BDS 705 6’te" (numara ile ek arasinda isaret) · "BDS 701’e15" (kesme ekine yapisik isaret)
      foreach($m in [regex]::Matches($gs,'(?<=\b(?:BDS|GDS|İHS|IHS|SBDS) ?\d{3,4}) ' + $nStr + '(?=[\u2019''])')){ $adaylar.Add([pscustomobject]@{ bas=$m.Index; boy=$m.Length; guc=$true }) }
      foreach($m in [regex]::Matches($gs,'(?<=\d[\u2019'']\p{L}{1,4})' + $nStr + '(?!\d)(?=[\s,.;:)]|$)')){ $adaylar.Add([pscustomobject]@{ bas=$m.Index; boy=$m.Length; guc=$true }) }
      # zayif: "kontrolün 14 bulunduğu" · "üzere 2, finansal" · "fonksiyonudur 3. BDS" (harf + bosluk + N)
      foreach($m in [regex]::Matches($gs,'(?<=\p{L}{2}) ' + $nStr + '(?=( [a-zçğıöşü])|([,.;:](\s|$)))')){
        $sonrasi = $gs.Substring($m.Index + $m.Length).TrimStart()
        if($sonrasi -match $sira){ continue }
        $oncesi = $gs.Substring(0,$m.Index)
        if($oncesi -match '(?i)\b(madde|maddesi|paragraf|paragrafı|fıkra|bent|ek|tablo|örnek|sayfa|no|numaralı|sayılı|yüzde|ve|veya|ile|ila|kys|bds|gds|ihs|İhs|sbds|tms|tfrs|tsrs)$'){ continue }   # "KYS 1," standart adidir (27.09 olculdu: 3 yanlis silme)
        $adaylar.Add([pscustomobject]@{ bas=$m.Index; boy=$m.Length; guc=$false })
      }
      foreach($a in @($adaylar | Where-Object { $_.bas -ge $basSutun } | Sort-Object bas)){
        if($a.guc){ if(-not $guclu){ $guclu = [pscustomobject]@{ satir=$g; bas=$a.bas; boy=$a.boy } } }
        elseif(-not $zayif){ $zayif = [pscustomobject]@{ satir=$g; bas=$a.bas; boy=$a.boy } }
      }
    }
    $sec = if($guclu){ $guclu } else { $zayif }
    if($sec){
      $gs = $satirlar[$sec.satir]
      $satirlar[$sec.satir] = $gs.Substring(0,$sec.bas) + $gs.Substring($sec.bas + $sec.boy)
      $sonIsaretSatir = $sec.satir; $sonIsaretSutun = $sec.bas
      $sonuc.isaret++; $sonuc.iz.Add(("SIL [{0}] {1} >> {2}" -f $blk.no,$gs.Trim(),$satirlar[$sec.satir].Trim()))
    } else { $sonuc.cozulemeyen++; $sonuc.iz.Add(("YOK [{0}] {1}" -f $blk.no,$blk.metin)) }
  }
  # --- bloklari tasi: acik paragrafin sonuna, bir sonraki sutun-0 satirindan once
  $bekleyen = New-Object System.Collections.Generic.List[string]
  $blokNo = @{}; foreach($blk in $bloklar){ $blokNo[$blk.satir] = $blk }
  $cikti = New-Object System.Text.StringBuilder
  for($i = 0; $i -lt $n; $i++){
    if($blokNo.ContainsKey($i)){ $bekleyen.Add("[Dipnot $($blokNo[$i].no): $($blokNo[$i].metin)]"); continue }
    if($blokSatiri.Contains($i)){ continue }
    $sat = $satirlar[$i]
    if($bekleyen.Count -and $sat -match '^\S' -and $sat -notmatch $sayfaDesen){
      foreach($d in $bekleyen){ [void]$cikti.AppendLine('     ' + $d) }
      $bekleyen.Clear()
    }
    [void]$cikti.AppendLine($sat)
  }
  foreach($d in $bekleyen){ [void]$cikti.AppendLine('     ' + $d) }
  $sonuc.metin = $cikti.ToString()
  $sonuc.dipnot = $bloklar.Count
  return $sonuc
}

function SY_BdsBaslikBirlestir([string]$metin){
  # ⚠ 27.09.2026 DERSI — IKI SATIRA SARAN BOLUM BASLIGI (BDS 315 p.19-20 adi "A50-A55 paragrafları)", BDS 300 "(Bkz.: 10 uncu" + "paragraf)").
  # -layout cikariminda BDS bolum basligi sutun 0'dadir; uzun baslik ikinci satira sarar. Bolucu satirlari tek tek okudugu icin
  # ikinci yarim ("A50-A55 paragrafları)") baslik sanildi, birinci yarim (>70 kr) GOVDEYE dustu.
  # KURAL: sutun 0'da, paragraf baslangici ("12." / "A5.") olmayan satir (a) acik parantezle bitiyorsa ya da (b) >=70 kr, noktalamasiz
  #   ve buyuk harfle basliyorsa, ardindaki sutun-0 satiriyla (o da paragraf baslangici/sayfa no/dipnot degilse) BIRLESTIRILIR (en cok 3).
  # Yalniz BDS kipi + layout metninde cagrilir. GORMEZ: girintili (sutun 0 olmayan) baslik · tek satirlik ama 180 kr'yi asan baslik.
  $satirlar = @($metin -split "`r?`n")
  $doluSay = @($satirlar | Where-Object { $_.Trim() }).Count
  if($doluSay -eq 0 -or @($satirlar | Where-Object { $_ -match '^\s{4,}\S' }).Count -lt ($doluSay * 0.2)){ return $metin }   # layout degil: dokunma
  $parDesen = '^(A?\d{1,3}[A-Z]?)\.\s'
  $cikti = New-Object System.Collections.Generic.List[string]
  $i = 0
  while($i -lt $satirlar.Count){
    $sat = $satirlar[$i]
    $birlesen = 0
    while($birlesen -lt 3 -and $i + 1 -lt $satirlar.Count){
      $kirp = $sat.TrimEnd()
      if($kirp -notmatch '^\S' -or $kirp -match $parDesen -or $kirp -match '^\d{1,3}$' -or $kirp -match '^\[Dipnot'){ break }
      if($kirp -match '\.{5,}' -or ($kirp -replace '\((Bkz|Bakınız).*$','') -match '[.:;]'){ break }   # icindekiler satiri / cumle: baslik degil (BDS 210 icindekiler birlesiyordu)
      $acik = $kirp -match '\((Bkz|Bakınız)[^()]*$'
      $uzun = $kirp.Length -ge 70 -and $kirp -notmatch '[,!?]$' -and $kirp -cmatch '^[A-ZÇĞİÖŞÜ]'
      if(-not ($acik -or $uzun)){ break }
      $sonraki = $satirlar[$i + 1]
      if($sonraki -notmatch '^\S' -or $sonraki -match $parDesen -or $sonraki.Trim() -match '^\d{1,3}$' -or $sonraki -match '^\[Dipnot'){ break }
      # (b) uzun satir yalniz ardindaki satir "(Bkz.: …)" ile biten baslik parcasiysa birlesir ("… Sistemi" + "Hakkında … (Bkz.: A48-A49 paragrafları)")
      if(-not $acik -and $sonraki.TrimEnd() -notmatch '\((Bkz|Bakınız)\.?:(?:[^()]|\([^()]*\))*\)$'){ break }
      $sat = $kirp + ' ' + $sonraki.Trim()
      $i++; $birlesen++
    }
    $cikti.Add($sat)
    $i++
  }
  return ($cikti -join "`n")
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
    # 16.09 (TFRS 9): bölüm başlığı "3.2 Finansal Varlıkların …" numara + TEK boşluk + büyük harf → numara atılır, satır başlık olur
    if($hamSatir -cmatch '^\d{1,2}(?:\.\d{1,2}){1,2} [A-ZÇĞİÖŞÜ]\S*(?: \S+){0,12}$' -and $hamSatir -notmatch '[.:;]\s*$'){ [void]$cikti.AppendLine(($hamSatir -replace '^\d{1,2}(?:\.\d{1,2}){1,2} ','')); continue }
    $numaraEsi = [regex]::Match($hamSatir,'^((?:[A-E]|UR)?\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2}(?:[–-]\d{1,3}[A-Z]{0,2})?)\s{2,}(\S.*)$')   # 16.09: E/UR öneki + iki harfli sonek + noktalı numara (SY_Bol TMS kipiyle aynı)
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
    $es = [regex]::Match($satir,'^([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})\s{2,}(\S.*)$')   # 16.09: noktalı numara (TFRS 9) hakikate girer
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
    $es = [regex]::Match(($ad -replace '\s\[\d+/\d+\]',''),'\sp\.([A-Z]{0,2}\d{1,3}(?:\.\d{1,3}){0,3}[A-Z]{0,2})(?:\s|$)')
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
  # --- 21.10 BOBI FRS ONARIMI: gercek BOBI satirlari (KGK EK 2.pdf, poppler 25.07 duz cikarim; bos satir/sayfa no duzeni aynen) ---
  #   Tek kurgu: "Özkaynak Değişim Tablosu ve" satiri gercekte "d)"den once durur; burada baglac kuralini sinamak icin numaradan hemen once kondu
  #   (BOBI'de numaradan hemen once virgul/baglacla biten satir 0 — 21.10 olculdu; kural savunma amacli).
  $bobi = @'
BÖLÜM 1
KAVRAMSAL ÇERÇEVE VE FİNANSAL TABLOLAR
1.1

Bu bölümde, işletmelerin finansal tablolarının, gerçeğe uygun sunumunu sağlamak
amacıyla finansal tabloların hazırlanmasına ve sunulmasına ilişkin esaslar
düzenlenmektedir.

1.3

1.4

Finansal tablolar asgari olarak aşağıdakilerden oluşur:
a)

Finansal Durum Tablosu,

d)

Önemli muhasebe politikalarını ve diğer açıklayıcı bilgileri içeren dipnotlar.

Finansal tablolar bu Standart hükümlerine uygun olarak, açık ve anlaşılır bir şekilde
sunulur.

1.25

Cari raporlama dönemine ait tutarların önceki raporlama dönemine ait tutarlarla
karşılaştırılabilir olmaması durumunda, bu husus gerekçeleriyle birlikte dipnotlarda
açıklanır.

5

1.25A

“Konsolide Finansal Tablolar” bölümü uyarınca tam konsolidasyon yöntemine göre
konsolide edilmesi gereken bağlı ortaklığı bulunmasına rağmen bu Standart zorunlu
kılmadığı için konsolide finansal tablolar sunmayan bir işletme olabilir.

1.41

Taşıyan varlıklar dönen varlık olarak sınıflandırılır:
a)

İşletmenin normal faaliyet döngüsü içinde paraya çevrilmesinin, satılmasının
veya tüketilmesinin beklenmesi,

b)

Esas olarak ticari amaçla elde tutulması,

c)

Raporlama döneminden sonraki on iki ay içinde paraya çevrilmesinin
beklenmesi veya
Özkaynak Değişim Tablosu ve
1.42

1.41 paragrafındaki özellikleri taşımayan diğer tüm varlıklar duran varlık olarak sınıflandırılır.

3.18

Hatanın düzeltilmesi geriye dönük düzeltme yoluyla yapılır ve aşağıdaki şekilde gerçekleştirilir:
a)

Hatanın

yapıldığı döneme veya dönemlere ait finansal tablolardaki

karşılaştırmalı tutarlar düzeltilir veya

8.3

Arama ve değerlendirme varlıkları ilk kayıtta maliyet bedeli üzerinden ölçülür.

8.4

(-)

8.5

Maden kaynaklarının geliştirilmesiyle ilgili harcamalar arama ve değerlendirme
varlıkları olarak muhasebeleştirilemez.

50

BÖLÜM 8
MADEN KAYNAKLARININ ARANMASI VE DEĞERLENDİRİLMESİ
8.6

Bu bölümde, maden, petrol, doğal gaz ve benzeri yenilenemeyen kaynaklar gibi
maden kaynaklarının aranması ve değerlendirilmesine ilişkin esaslar düzenlenmektedir.

10.20

Özkaynaklar”

bölümünün

9.53

paragrafının (a), (b) ve (c) bentleri uyarınca özkaynaklarında kaydettiği
kazanç ve kayıplardan işletmeye düşen birikimli tutarlar kâr veya zarara aktarılır.

cinsinden olan bir kredi ödemesine ilişkin borcun değerlemesinde ise satış kurunun
kullanılması gerekir.

Finansal Tabloların Ağırlıkla Kullanılan Para Birimi Dışındaki Para Birimi Cinsinden
Sunulması
20.19

Ağırlıkla kullanılan para birimi, yüksek enflasyonlu bir ekonominin para birimi
olmayan bir işletmenin finansal tablolarını farklı bir para biriminde sunabilir.

çevrilir.

Ağırlıkla Kullanılan Para Birimi, Finansal Tabloların Sunulduğu Para Biriminden Farklı
Olan Bağlı Ortaklıkların, İştiraklerin ve Müşterek Girişimlerin Finansal Tablolarının
Çevrimi
20.24

20.3 ve 20.4 paragraflarında belirtilen faktörlerin yanı sıra, yatırım yapan bir
işletmenin bağlı ortaklığının ağırlıkla kullanılan para birimi belirlenir.

27.15

Önceki finansal raporlama çerçevesi uygulanırken yapılmış olan hataların farkına
varıldığı durumda bu hatalar dipnotlarda açıklanır.

MÜNFERİT FİNANSAL TABLOLAR

226

EK 1 – MÜNFERİT FİNANSAL DURUM TABLOSU

… ŞİRKETİ … TARİHLİ BAĞIMSIZ DENETİMDEN GEÇMİŞ MÜNFERİT FİNANSAL DURUM TABLOSU
VARLIKLAR
Dönen Varlıklar
Nakit ve Nakit Benzerleri
Finansal Yatırımlar
227
EK 9 - TANIMLAR
Ağırlıkla Kullanılan
Para Birimi
İşletmenin faaliyetlerini sürdürdüğü temel ekonomik çevrenin para birimidir.
'@
  $bk = @(SY_Bol $bobi 'BOBI FRS')
  $bkAd = @($bk | ForEach-Object { $_.kaynak_ad })
  $bkBul = { param($rx) @($bk | Where-Object { $_.kaynak_ad -match $rx }) }
  $bkOz = ($bkAd -join ' | ')
  # (a) harfli numara
  $h25a = @(& $bkBul ' p\.1\.25A( |$)'); $h25 = @(& $bkBul ' p\.1\.25( |$)')
  if($h25a.Count -ne 1 -or $h25a[0].metin -notmatch '^“Konsolide Finansal Tablolar”'){ $dusen += "BOBI HARFLI NUMARA: p.1.25A ayrilmadi ($bkOz)" }
  if($h25.Count -eq 1 -and $h25[0].metin -match 'Konsolide Finansal Tablolar'){ $dusen += 'BOBI HARFLI NUMARA: 1.25A metni 1.25 icinde (yutma)' }
  # (b) mulga "(-)"
  $h84 = @(& $bkBul ' p\.8\.4( |$)')
  if($h84.Count -ne 1 -or $h84[0].metin -ne '(-)'){ $dusen += "BOBI MULGA: p.8.4 '(-)' kendi adiyla kalmadi ($bkOz)" }
  if(@(& $bkBul ' p\.8\.3( |$)' | Where-Object { $_.metin -match '\(-\)' }).Count){ $dusen += 'BOBI MULGA: "(-)" onceki paragrafa (8.3) eklendi' }
  # (c) bent metni / tek kelime / baglacla biten satir baslik DEGIL, govdede kalir; saran baslik ve BOLUM zinciri tek baslik
  $h41 = @(& $bkBul ' p\.1\.41( |$)'); $h42 = @(& $bkBul ' p\.1\.42( |$)'); $h318 = @(& $bkBul ' p\.3\.18( |$)')
  if($h41.Count -ne 1 -or $h41[0].metin -notmatch 'Esas olarak ticari amaçla elde tutulması,'){ $dusen += "BOBI BENT BASLIK SANILDI: '(b) Esas olarak ticari amaçla elde tutulması,' 1.41 govdesinde yok ($bkOz)" }
  if(@($bkAd | Where-Object { $_ -match ' - (Esas olarak|Hatanın|Özkaynak Değişim Tablosu ve)' }).Count){ $dusen += "BOBI BENT/KELIME ADA GIRDI: $bkOz" }
  if($h41.Count -eq 1 -and $h41[0].metin -notmatch 'Özkaynak Değişim Tablosu ve$'){ $dusen += 'BOBI BAGLAC: "… ve" ile biten satir numaradan once baslik sanildi (govdeden dustu)' }
  if($h318.Count -ne 1 -or $h318[0].metin -notmatch 'a\) Hatanın yapıldığı döneme'){ $dusen += 'BOBI TEK KELIME SATIR ("Hatanın") govdeden dustu' }
  if($h42.Count -ne 1){ $dusen += "BOBI p.1.42 yok ($bkOz)" }
  $h1919 = @(& $bkBul ' p\.20\.19 - Finansal Tabloların Ağırlıkla Kullanılan Para Birimi Dışındaki Para Birimi Cinsinden Sunulması$')
  if($h1919.Count -ne 1){ $dusen += "BOBI SARAN BASLIK: p.20.19 adi iki satirin birlesimi degil ($bkOz)" }
  if(@($bk | Where-Object { $_.metin -match 'Para Birimi Cinsinden$' -or $_.metin -match 'Cinsinden Sunulması' }).Count){ $dusen += 'BOBI SARAN BASLIK: ilk yarisi onceki paragrafin govdesine dustu' }
  $h86 = @(& $bkBul ' p\.8\.6 - MADEN KAYNAKLARININ ARANMASI VE DEĞERLENDİRİLMESİ$')
  if($h86.Count -ne 1 -or @($bk | Where-Object { $_.metin -cmatch 'MADEN KAYNAKLARININ|BÖLÜM 8' }).Count){ $dusen += "BOBI BOLUM ZINCIRI: 'BÖLÜM 8' + bolum adi p.8.6 basligi olmadi ($bkOz)" }
  $h2024 = @(& $bkBul ' p\.20\.24 - ')
  if($h2024.Count -ne 1 -or $h2024[0].metin -notmatch 'Finansal Tablolarının Çevrimi'){ $dusen += 'BOBI UZUN BASLIK: 160 kr ustu basligin kuyrugu hicbir yerde yok' }
  # (d) ek: ayri blok, tablo satirlari dusmez, onceki paragrafa yapismaz
  $e1 = @(& $bkBul '^BOBI FRS Ek 1 - MÜNFERİT FİNANSAL DURUM TABLOSU \[1/1\]$'); $e9 = @(& $bkBul '^BOBI FRS Ek 9 - TANIMLAR \[1/1\]$')
  if($e1.Count -ne 1 -or $e1[0].metin -notmatch 'Nakit ve Nakit Benzerleri' -or $e1[0].metin -notmatch 'Dönen Varlıklar'){ $dusen += "BOBI EK: Ek 1 ayri blok degil ya da tablo satiri dustu ($bkOz)" }
  if($e9.Count -ne 1 -or $e9[0].metin -notmatch '^Ağırlıkla Kullanılan Para Birimi'){ $dusen += "BOBI EK: Ek 9 tanim terimi dustu ($bkOz)" }
  if(@(& $bkBul ' p\.27\.15( |$)' | Where-Object { $_.metin -match 'VARLIKLAR|Nakit ve Nakit' }).Count){ $dusen += 'BOBI EK: ek tablosu son paragrafa (27.15) yapisti' }
  # (e) alt alta iki numara
  $h13 = @(& $bkBul ' p\.1\.3( |$)'); $h14 = @(& $bkBul ' p\.1\.4( |$)')
  if($h13.Count -ne 1 -or $h13[0].metin -notmatch '^Finansal tablolar asgari' -or $h13[0].metin -match 'bu Standart hükümlerine'){ $dusen += "BOBI ALT ALTA NUMARA: p.1.3 metni yanlis ($bkOz)" }
  if($h14.Count -ne 1 -or $h14[0].metin -notmatch '^Finansal tablolar bu Standart'){ $dusen += 'BOBI ALT ALTA NUMARA: p.1.4 kendi metniyle baslamiyor' }
  # (f) satira dusen atif
  if(@(& $bkBul ' p\.9\.53( |$)').Count){ $dusen += "BOBI ATIF: 'bölümünün / 9.53 / paragrafının' sahte paragraf acti ($bkOz)" }
  if(@(& $bkBul ' p\.10\.20( |$)' | Where-Object { $_.metin -match 'bölümünün 9\.53 paragrafının' }).Count -ne 1){ $dusen += 'BOBI ATIF: 9.53 atfi 10.20 govdesinde degil' }
  # sayfa no metne girmez · numara sayisi
  if((($bk | ForEach-Object { $_.metin }) -join ' ') -match '(^| )(5|50|226|227)( |$)'){ $dusen += 'BOBI: sayfa numarasi metne sizdi' }
  # xpdf duzeni kapisi (satir ici numara) — 20 gercek BOBI xpdf kalibi satiri · yanlis alarm: poppler satiri "1 $ = 2.50 TL"
  $xpSatir = 1..24 | ForEach-Object { "1.$($_) İşletme, diğer bütün yükümlülüklerini uzun vadeli olarak sınıflandırır. Kâr veya Zarar Tablosu 1.$($_ + 30) Kâr veya Zarar Tablosu, işletmenin finansal performansı" }
  $xo = SY_KilavuzSatirIci ($xpSatir -join "`n")
  if(-not $xo.bozuk){ $dusen += "XPDF KAPISI: satir ici numarali metin yakalanmadi (ic $($xo.satirIci) / bas $($xo.satirBasi))" }
  $po = SY_KilavuzSatirIci ($bobi + "`nAna ortaklık 10.000 `$ borç vermiştir. İşlem tarihinde 1 `$ = 2.50 TL; dönem sonunda ise 1 `$ = 2.60 TL’dir.")
  if($po.bozuk){ $dusen += "XPDF KAPISI YANLIS ALARM: poppler metni bozuk sayildi (ic $($po.satirIci) / bas $($po.satirBasi))" }
  # --- 21.10 (ikinci tur) BENT + NUMARA (g) · UST BASLIK (h) · SAYFA SINIRINDA SARAN BASLIK (i): gercek BOBI satirlari, kurgu YOK ---
  #   (poppler 25.07 duz cikarim, KGK EK 2.pdf satir 336-356 · 3928-3962 · 7424-7452 · 7626-7652 · 7124-7141 · 9422-9448; bos satir + sayfa no aynen)
  $bobi2 = @'
1.13

Zamanında sunum; finansal bilginin, finansal tablo kullanıcılarının kararlarını
etkileyebileceği zamanda mevcut olmasıdır.

Genel Finansal Raporlama İlkeleri
İşletmenin Sürekliliği
1.14

İşletme yönetimi finansal tabloları hazırlarken işletmenin faaliyetlerini devam
ettirebilme gücünü değerlendirir. Yönetimin, işletmeyi tasfiye etme veya ticari
faaliyetlerine son verme niyetinin ya da zorunluluğunun bulunmadığı durumlarda
finansal tablolar işletmenin sürekliliği varsayımına dayanılarak hazırlanır. Yönetim
işletmenin sürekliliği varsayımının geçerli olup olmadığını değerlendirirken
raporlama dönemi sonundan itibaren en az on iki aylık dönemi kapsayacak şekilde
gelecek hakkında elde edilebilen bütün bilgileri dikkate alır. Yönetim bu
değerlendirmeyi yaparken işletmenin faaliyetlerini devam ettirebilmesini ciddi şekilde
3

şüpheli hale getirebilecek şartlarla ilgili önemli belirsizlikleri tespit ederse bu
belirsizlikleri dipnotlarda açıklar.

9.51

9.49 paragrafında belirtilen korunma muhasebesine aşağıdaki durumlarda son verilir:
a)

Korunma aracının süresinin dolması, satılması veya feshedilmesi,

b)

Korunma işleminin 9.46 paragrafındaki korunma muhasebesi şartlarını artık
karşılamaması veya

c)
9.52

İşletmenin korunma muhasebesinden vazgeçmesi.

Korunma muhasebesine son verilmişse ve korunan kalem, itfa edilmiş değeri
üzerinden ölçülen finansal tablo dışı bırakılmamış bir varlık veya yükümlülükse,
korunan kalemin defter değerinde düzeltme olarak kayda alınmış kazanç veya
kayıplar, korunma aracının kalan ömrü boyunca etkin faiz yöntemi kullanılarak kâr
veya zararda itfa edilir.
Kayda Alınmış Finansal Araca İlişkin Değişken Faiz Oranı Riskine, Bir Kesin
Taahhüde veya Gerçekleşme İhtimali Yüksek Tahmini Bir İşleme İlişkin Kur

69

Riskine veya Emtia Fiyatı Riskine ya da Yurtdışındaki Net Yatırıma Karşı
Korunma
9.53

Korunulan riskin aşağıdakilerden biri olması durumunda, korunma aracının gerçeğe
uygun değerindeki değişimin, korunan kalemin gerçeğe uygun değerindeki veya
beklenen nakit akışlarındaki değişimleri etkin olarak karşılayan kısmı, özkaynaklarda
“Korunma Yedeği” kaleminde muhasebeleştirilir.

19.5

Karşılık, yalnızca aşağıdaki durumların varlığı halinde kayda alınır:
a)

İşletmenin raporlama dönemi sonunda geçmiş bir olaydan kaynaklanan mevcut
bir yükümlülüğünün bulunması,

b)

Yükümlülüğün yerine getirilmesi için işletmeden ekonomik fayda çıkışının
muhtemel olması (diğer bir ifadeyle gerçekleşme olasılığının, gerçekleşmeme
olasılığından daha yüksek olması) ve

c)
19.6

Yükümlülük tutarının güvenilir bir biçimde tahmin edilebilir olması.

Karşılık tutarı, Finansal Durum Tablosuna yükümlülük olarak yansıtılır ve diğer
bölümlere göre bir varlığın maliyetine dâhil edilmediği sürece karşılık tutarı kadar
gider kayda alınır.

19.7

19.5 paragrafının (a) bendinde yer alan, raporlama dönemi sonunda geçmiş bir olaydan
kaynaklanan bir yükümlülüğün bulunması şartı, işletmenin yükümlülüğünü yerine
getirmek dışında herhangi bir gerçekçi alternatifinin bulunmadığı anlamına
gelmektedir. Böyle bir durum aşağıdaki şartlardan birinin varlığı halinde ortaya çıkar:

19.18

Şarta bağlı yükümlülük aşağıdakilerden herhangi biridir;
a)

Geçmiş olaylardan kaynaklanan muhtemel bir yükümlülük olup söz konusu
yükümlülüğün mevcudiyeti tam olarak işletmenin kontrolünde bulunmayan,
gelecekteki belirsiz bir veya daha fazla olayın meydana gelip gelmemesine
bağlıdır.

b)

Geçmiş olaylardan kaynaklanan; fakat aşağıda yer alan nedenlerle kayda
alınamayan mevcut bir yükümlülüktür:
(i)

Yükümlülüğün yerine getirilmesi için işletmeden ekonomik fayda
çıkışının muhtemel olmaması veya

(ii)
19.19

Yükümlülük tutarının güvenilir bir biçimde ölçülememesi.

Bir yükümlülük için müteselsilen sorumlu olunması durumunda, söz konusu
yükümlülüğün diğer taraflarca karşılanacağı tahmin edilen kısmı, şarta bağlı
yükümlülük olarak değerlendirilir.

18.17

Kullanım değerinin hesaplanması aşağıdaki adımlardan oluşur:
a)

Varlığın kullanımı süresince ve nihai olarak elden çıkarılmasından elde edilmesi
beklenen nakit giriş ve çıkışlarının tahmini ve

b)
18.18

Söz konusu nakit akışlarına uygun iskonto oranının uygulanması.

18.16 paragrafının (b), (ç) ve (d) bentlerinde belirtilen unsurlar, gelecekteki nakit
akışlarına ilişkin bir düzeltme ya da iskonto oranına ilişkin bir düzeltme olarak
yansıtılabilir. Ayrıca iskonto oranının, genel enflasyonla ilgili fiyat artışlarının etkisini
içermesi durumunda gelecekteki nakit akışları da nominal değerleriyle tahmin edilir.


23.11

a)

Mahsup edilebilmesine ilişkin yasal bir hakkın bulunması ve

b)

Mahsup edilmiş tutar üzerinden ödeme yapılmasının amaçlanması.

Dönem vergisi Kâr veya Zarar Tablosunda “Vergi Gideri” kaleminde gösterilir.
Ancak dönem vergisinin, aynı veya farklı bir dönemde kâr veya zarara yansıtılmayan
(diğer bir ifadeyle özkaynaklarda kayda alınan) işlem veya olayların sonucu olarak
ortaya çıkması durumunda, bunlara ilişkin dönem vergisi tutarı, söz konusu işlem ve
olayların etkilerinin yansıtıldığı özkaynak kaleminde (“Yeniden Değerleme Yedeği”,
“Yabancı Para Çevrim Farkları” ve “Korunma Yedeği” kalemlerinde) gösterilir.

179

Ertelenmiş Vergi
Kayda Alma
23.12

Ertelenmiş vergi; varlıkların ve yükümlülüklerin defter değerleri üzerinden geri
kazanılması veya ödenmesi ve indirilecek geçmiş yıl zararları ile vergi indirimlerinin
ileriye taşınması sonucunda gelecek dönemlerde ödenecek veya geri kazanılacak
vergilerdir.
'@
  $b2 = @(SY_Bol $bobi2 'BOBI FRS')
  $b2Oz = (($b2 | ForEach-Object { $_.kaynak_ad }) -join ' | ')
  $b2Bul = { param($no) @($b2 | Where-Object { $_.kaynak_ad -match (' p\.' + [regex]::Escape($no) + '( |$)') }) }
  # (g) bent metni kendi paragrafinda (19.5 c · 19.18 (ii) · 9.51 c), sonraki paragraf kendi metniyle baslar
  $g195 = @(& $b2Bul '19.5'); $g196 = @(& $b2Bul '19.6')
  if($g195.Count -ne 1 -or $g195[0].metin -notmatch 'c\) Yükümlülük tutarının güvenilir bir biçimde tahmin edilebilir olması\.$'){ $dusen += "BOBI BENT+NUMARA: 19.5 son bendi (c) kendi paragrafinda degil ($b2Oz)" }
  if($g196.Count -ne 1 -or $g196[0].metin -notmatch '^Karşılık tutarı, Finansal Durum Tablosuna'){ $dusen += 'BOBI BENT+NUMARA: 19.6 bent metniyle basliyor' }
  $g1918 = @(& $b2Bul '19.18'); $g1919 = @(& $b2Bul '19.19')
  if($g1918.Count -ne 1 -or $g1918[0].metin -notmatch '\(ii\) Yükümlülük tutarının güvenilir bir biçimde ölçülememesi\.$' -or $g1919.Count -ne 1 -or $g1919[0].metin -notmatch '^Bir yükümlülük için'){ $dusen += 'BOBI BENT+NUMARA: 19.18 (ii) bendi 19.19 basina kaydi' }
  $g951 = @(& $b2Bul '9.51'); $g952 = @(& $b2Bul '9.52')
  if($g951.Count -ne 1 -or $g951[0].metin -notmatch 'c\) İşletmenin korunma muhasebesinden vazgeçmesi\.$' -or $g952.Count -ne 1 -or $g952[0].metin -notmatch '^Korunma muhasebesine son verilmişse'){ $dusen += 'BOBI BENT+NUMARA: 9.51 (c) bendi 9.52 basina kaydi' }
  $g1817 = @(& $b2Bul '18.17'); $g1818 = @(& $b2Bul '18.18')
  if($g1817.Count -ne 1 -or $g1817[0].metin -notmatch 'b\) Söz konusu nakit akışlarına uygun iskonto oranının uygulanması\.$' -or $g1818.Count -ne 1 -or $g1818[0].metin -notmatch '^18\.16 paragrafının'){ $dusen += "BOBI BENT+NUMARA: 18.18 (rakamla baslayan paragraf) 18.17'ye yapisti ya da (b) bendi kaydi ($b2Oz)" }
  # (i) sayfa sinirinda saran baslik: 9.52 govdesi "itfa edilir." ile biter, baslik 9.53'un adinda
  if($g952.Count -eq 1 -and $g952[0].metin -notmatch 'itfa edilir\.$'){ $dusen += 'BOBI SAYFA SARAN BASLIK: 9.53 basliginin ilk yarisi 9.52 govdesine dustu' }
  $g953 = @(& $b2Bul '9.53')
  if($g953.Count -ne 1 -or $g953[0].kaynak_ad -notmatch ' p\.9\.53 - Kayda Alınmış Finansal Araca İlişkin Değişken Faiz Oranı Riskine'){ $dusen += "BOBI SAYFA SARAN BASLIK: 9.53 adi tam basligin basi degil ($b2Oz)" }
  if(@($b2 | Where-Object { $_.metin -match '(^| )69( |$)' }).Count){ $dusen += 'BOBI SAYFA SARAN BASLIK: sayfa no (69) metne sizdi' }
  # (h) ust baslik: onceki paragrafin govdesine yapismaz, ad alt basligi alir
  $g113 = @(& $b2Bul '1.13'); $g114 = @(& $b2Bul '1.14'); $g2311 = @(& $b2Bul '23.11'); $g2312 = @(& $b2Bul '23.12')
  if($g113.Count -ne 1 -or $g113[0].metin -notmatch 'mevcut olmasıdır\.$'){ $dusen += 'BOBI UST BASLIK: "Genel Finansal Raporlama İlkeleri" 1.13 govdesine yapisti' }
  if($g114.Count -ne 1 -or $g114[0].kaynak_ad -notmatch ' - İşletmenin Sürekliliği$'){ $dusen += "BOBI UST BASLIK: 1.14 adi alt baslik degil ($b2Oz)" }
  if($g2311.Count -ne 1 -or $g2311[0].metin -notmatch 'kalemlerinde\) gösterilir\.$'){ $dusen += 'BOBI UST BASLIK: "Ertelenmiş Vergi" 23.11 govdesine yapisti (sayfa no arada)' }
  if($g2312.Count -ne 1 -or $g2312[0].kaynak_ad -notmatch ' - Kayda Alma$'){ $dusen += "BOBI UST BASLIK: 23.12 adi 'Kayda Alma' degil ($b2Oz)" }
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
  # --- SARAN UZUN BASLIK (07.10, BDS 701 p.13/p.14 gercek vakasi) ---------
  $saranOrnek = @"
1. Bu BDS kilit denetim konularinin bildirilmesini duzenler.
2. Denetci kilit denetim konularini belirler ve raporunda aciklar.
Kilit Denetim Konusu Olarak Belirlenen Bir Konunun Denetçi Raporunda Bildirilmediği
Durumlar
14. Denetci, mevzuat aciklamayi yasakliyorsa konuyu raporunda bildirmez.
Diger Hususlarin Bildirilmesine Iliskin Kurallar ve Bu Kurallarin Uygulanmasina Dair Bolum
15. Denetci diger hususlari ayri bir bolumde bildirir ve gerekcesini yazar.
16. Bu paragrafin ilk satiri noktalama olmadan devam eder ve ardindan gelen satir
Buyuk Harfle Baslayan Ama Govdenin Parcasi Olan Bu Uzun Satir Yetmis Karakteri Asiyor Kesinlikle
17. Son paragraf burada yeterince uzun bir cumleyle biter.
"@
  $sr = @(SY_Bol $saranOrnek 'BDS 701')
  $sr2 = @($sr | Where-Object { $_.kaynak_ad -match 'p\.2( |$)' }); $sr14 = @($sr | Where-Object { $_.kaynak_ad -match 'p\.14( |$)' })
  $sr15 = @($sr | Where-Object { $_.kaynak_ad -match 'p\.15( |$)' }); $sr16 = @($sr | Where-Object { $_.kaynak_ad -match 'p\.16( |$)' })
  if($sr2.Count -ne 1 -or $sr2[0].metin -match 'Bildirilmedi'){ $dusen += "SARAN BASLIK: p.2 govdesine baslik yapisti ('$(@($sr2 | ForEach-Object { $_.metin }) -join '|')')" }
  if($sr14.Count -ne 1 -or $sr14[0].kaynak_ad -notmatch 'p\.14 - Kilit Denetim Konusu .*Bildirilmediği Durumlar$'){ $dusen += "SARAN BASLIK: p.14 adi tam baslik degil ('$(@($sr14 | ForEach-Object { $_.kaynak_ad }) -join '|')')" }
  if($sr15.Count -ne 1 -or $sr15[0].kaynak_ad -notmatch 'p\.15 - Diger Hususlarin .*Bolum$'){ $dusen += "UZUN TEK SATIR BASLIK: p.15 adi ('$(@($sr15 | ForEach-Object { $_.kaynak_ad }) -join '|')')" }
  if($sr16.Count -ne 1 -or $sr16[0].metin -notmatch 'Kesinlikle'){ $dusen += 'SARAN BASLIK YANLIS ALARM: govde ortasindaki uzun satir baslik sanildi (p.16 govdesi eksik)' }

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
  # 16.09 (3 vaka): (a) metin içi "Ek A'daki …" sözlük AÇMAZ (TFRS 17 B8) · (b) numaralı Ek A (TMS 36) sözlükte kalmaz · (c) iki harfli sonek / UR öneki
  $ekAtif = @(SY_Bol "Amaç`n`n1`n`nBu Standart, sigorta sözleşmelerini düzenler ve ilkeleri belirler.`n`n2`n`nİşletme bu Standardı uygular ve sonuçları açıklar.`nEk A'daki finansal risk tanımı değişkenlere atıfta bulunur ve açıklanır.`nEk A değiştirilmiş ve 9A paragrafı eklenmiştir. Söz konusu değişiklik uygulanır`n`n3`n`nBu paragraf üçüncü paragraftır ve ekin dışında kalır." 'TEST 17')
  if(@($ekAtif | Where-Object { $_.kaynak_ad -match 'Ek A' }).Count -or @($ekAtif | Where-Object { $_.kaynak_ad -match ' p\.3 ' }).Count -ne 1){ $dusen += "EK ATIF SOZLUK ACTI: $(@($ekAtif | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  $ekNumarali = @(SY_Bol "Amaç`n`n1`n`nBirinci paragraf metni burada yer alır ve yeterince uzundur.`n`nEK A`n`nUygulama rehberi`n`nA1`n`nBu ek paragrafı uygulama rehberinin ilk paragrafıdır ve uzundur.`n`nA2`n`nBu ek paragrafı uygulama rehberinin ikinci paragrafıdır ve uzundur." 'TEST 36')
  if(@($ekNumarali | Where-Object { $_.kaynak_ad -match ' p\.A[12] ' }).Count -ne 2){ $dusen += "NUMARALI EK A SOZLUKTE KALDI: $(@($ekNumarali | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  $ikiHarf = @(SY_Bol "Amaç`n`n1`n`nBirinci paragraf metni burada yer alır ve yeterince uzundur.`n`n39AH`n`nİki harfli sonekli paragraf metni burada yer alır ve uzundur.`n`nUR1`n`nUygulama rehberi paragrafı metni burada yer alır ve uzundur." 'TEST 32')
  if(@($ikiHarf | Where-Object { $_.kaynak_ad -match ' p\.(39AH|UR1) ' }).Count -ne 2){ $dusen += "IKI HARFLI NUMARA AYRILMADI: $(@($ikiHarf | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  # 16.09 (2 vaka): (d) TFRS 9 noktalı numara + B serisi + başlıktaki numara atılır · (e) BDS "20T." soneki
  $tfrs9Layout = "3.2 Finansal Varlıkların Finansal Tablo Dışı Bırakılması`n`n3.2.1    Bu paragraf birinci noktalı paragraftır ve yeterince uzundur.`n3.2.2    Bu paragraf ikinci noktalı paragraftır ve yeterince uzundur.`n`nKapsam (Bölüm 2)`n`nB2.1     Bu paragraf uygulama rehberinin ilk paragrafıdır ve uzundur."
  $noktali = @(SY_Bol (SY_TmsLayoutDuzle $tfrs9Layout 'TFRS 9') 'TFRS 9')
  $noktaliAdlar = @($noktali | ForEach-Object { $_.kaynak_ad })
  if(@($noktaliAdlar | Where-Object { $_ -match ' p\.(3\.2\.1|3\.2\.2|B2\.1) ' }).Count -ne 3 -or @($noktaliAdlar | Where-Object { $_ -match ' p\.3\.2 ' }).Count){ $dusen += "NOKTALI NUMARA: $($noktaliAdlar -join ' | ')" }
  $bdsT = @(SY_Bol "Kapsam`n1. Bu BDS denetçinin sorumluluklarını düzenler ve uygulanır.`n2. Bu BDS ayrıca raporlamayı da düzenler ve uygulanır.`n20T. Türkiye'ye özgü bu paragraf ayrıca uygulanır ve açıklanır.`n3. Üçüncü paragraf burada yer alır ve uygulanır." 'BDS 720')
  if(@($bdsT | Where-Object { $_.kaynak_ad -match ' p\.20T ' }).Count -ne 1){ $dusen += "BDS T SONEKI: $(@($bdsT | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  # --- 27.09 BDS DIPNOTU + SARAN BASLIK (BDS 200/210/300/315/330/520/701 vakalari) ---------------------------------
  # (1) poppler layout: dipnot blogu basliga girmez, [Dipnot N] olarak paragraf sonuna gider; govde isareti silinir;
  #     "2 nci paragrafta" gibi GERCEK sayi silinmez; iki satira saran "(Bkz.:" basligi birlesir; 70 kr ustu Bkz basligi baslik olur.
  $dnPop = @'
Planlama Çalışmaları
9.       Denetçi denetim planını hazırlar ve kapsamını belirler.1
         Bu plan denetim ekibine duyurulur ve gerektiğinde güncellenir.
10.      Denetçi, belirtildiği gibi 2 nci paragrafta sayılan hususları dikkate alır; birkaç kontrolün 2 bulunduğu
         varsayımıyla hazırlanan programlar 13 üncü paragrafta belirtilen şekilde kullanılabilir.

1
    BDS 220 (Revize), 25 inci paragraf
2
    BDS 315, Önemli Yanlışlık Risklerinin Belirlenmesi, 12 nci paragraf


                                                  7
         Bu cümle önceki paragrafın devamıdır ve sayfa geçişinde kalır.
İlk Denetimlerde Dikkate Alınacak İlâve Hususlar ile İlgili Açıklamalar (Bkz.:
A24 paragrafı)
11.      Denetçi ilk denetime başlamadan önce gerekli prosedürleri uygular ve belgeler.
Küçük İşletmelere Özgü İlk Denetim Hususları ve Uygulamaya İlişkin Açıklamalar (Bkz.: 12 nci paragraf)
12.      Küçük işletmelerde denetim ekibi tek kişiden oluşabilir ve plan kısa tutulur.
'@
  $dnSonuc = SY_DipnotAyikla $dnPop
  $dnPar = @(SY_Bol (SY_BdsBaslikBirlestir $dnSonuc.metin) 'BDS 300')
  $dnAd = @($dnPar | ForEach-Object { $_.kaynak_ad })
  $dn9 = @($dnPar | Where-Object { $_.kaynak_ad -match ' p\.9 ' }); $dn10 = @($dnPar | Where-Object { $_.kaynak_ad -match ' p\.10 ' })
  if($dnSonuc.dipnot -ne 2){ $dusen += "DIPNOT BLOGU: 2 bekleniyordu, $($dnSonuc.dipnot) ($($dnAd -join ' | '))" }
  if(@($dnAd | Where-Object { $_ -match ' - (BDS 220|BDS 315,)' }).Count){ $dusen += "DIPNOT BASLIGA GIRDI: $($dnAd -join ' | ')" }
  if($dn9.Count -ne 1 -or $dn9[0].metin -match 'belirler\.1'){ $dusen += "GOVDE ISARETI SILINMEDI (yapisik): $(if($dn9.Count){ $dn9[0].metin })" }
  if($dn10.Count -ne 1 -or $dn10[0].metin -notmatch 'kontrolün bulunduğu' -or $dn10[0].metin -notmatch '2 nci paragrafta' -or $dn10[0].metin -notmatch '13 üncü paragrafta'){ $dusen += "GOVDE ISARETI (zayif) / GERCEK SAYI: $(if($dn10.Count){ $dn10[0].metin })" }
  if($dn10.Count -eq 1 -and ($dn10[0].metin -notmatch '\[Dipnot 1: BDS 220 \(Revize\), 25 inci paragraf\]' -or $dn10[0].metin.IndexOf('geçişinde kalır') -gt $dn10[0].metin.IndexOf('[Dipnot 1'))){ $dusen += "DIPNOT METNI PARAGRAF SONUNA GITMEDI: $($dn10[0].metin)" }
  if(@($dnAd | Where-Object { $_ -match ' p\.11 - İlk Denetimlerde .* \(Bkz\.: A24 paragrafı\)$' }).Count -ne 1){ $dusen += "SARAN BASLIK BIRLESMEDI: $($dnAd -join ' | ')" }
  if(@($dnAd | Where-Object { $_ -match ' p\.12 - Küçük İşletmelere Özgü İlk Denetim' }).Count -ne 1){ $dusen += "UZUN (Bkz.) BASLIK TANINMADI: $($dnAd -join ' | ')" }
  # (2) xpdf layout: "N metin" bicimli dipnot + standart numarasina yapisik isaret ("BDS 2001'ün")
  $dnXp = @'
2.       Bu BDS, denetçinin genel amaçları bağlamında anlaşılmalıdır ve BDS 2001'ün hükümlerine bağlıdır.
         Diğer hükümler de bu bağlamda uygulanır ve değerlendirilir.

1 BDS 200, Bağımsız Denetçinin Genel Amaçları ve Bağımsız Denetimin Bağımsız Denetim Standartlarına Uygun
  Olarak Yürütülmesi

                                                    6
3.       Diğer bilgiler finansal tablolarla tutarsız olabilir ve denetçi bunu değerlendirir.
'@
  $dxSonuc = SY_DipnotAyikla $dnXp
  if($dxSonuc.dipnot -ne 1 -or $dxSonuc.isaret -ne 1){ $dusen += "XPDF DIPNOT SAYIMI: blok $($dxSonuc.dipnot) (1) · isaret $($dxSonuc.isaret) (1, 'BDS 2001'ün' standart numarasina yapisik)" }
  $dxPar = @(SY_Bol (SY_BdsBaslikBirlestir $dxSonuc.metin) 'BDS 720')
  $dx2 = @($dxPar | Where-Object { $_.kaynak_ad -match ' p\.2$' }); $dx3 = @($dxPar | Where-Object { $_.kaynak_ad -match ' p\.3$' })
  if($dx2.Count -ne 1 -or $dx2[0].metin -notmatch "BDS 200'ün" -or $dx2[0].metin -notmatch '\[Dipnot 1: BDS 200, .* Olarak Yürütülmesi\]'){ $dusen += "XPDF DIPNOT: $(@($dxPar | ForEach-Object { $_.kaynak_ad + ' :: ' + $_.metin }) -join ' || ')" }
  if($dx3.Count -ne 1 -or $dx3[0].metin -match 'Yürütülmesi'){ $dusen += "XPDF DIPNOT SONRAKI PARAGRAFA SIZDI: $(@($dxPar | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  # (2b) ekte dipnot numarasi 1'den yeniden baslar (BDS 720 Ek 2)
  $dnYeniden = "2.       Birinci paragraf metni burada yer alır ve uygulanır.1`n         Devam eden metin burada yer alır.2`n`n1 BDS 200, Genel Amaçlar`n2 BDS 210, Denetim Sözleşmesi`n`n                                                    6`n3.       Ek örnek rapor metni burada yer alır ve uygulanır.1`n         Devam eden metin burada yer alır.`n`n1 Kilit Denetim Konuları bölümü yalnızca borsada işlem gören işletmeler için zorunludur.`n"
  $dnY = SY_DipnotAyikla $dnYeniden
  if($dnY.dipnot -ne 3){ $dusen += "DIPNOT YENIDEN NUMARALANMA: 3 blok bekleniyordu, $($dnY.dipnot)" }
  # (2c) yanlis alarm: "KYS 1," standart adi dipnot isareti sanilip silinmez (BDS 260 / SBDS 2400 / İHS 4400 vakasi)
  $dnKys = SY_DipnotAyikla "2.       KYS 1, denetim şirketlerinin kalite yönetimini düzenler ve uygulanır.`n         Devam eden metin burada yer alır ve uygulanır.`n`n1 KYS 1 Kalite Yönetimi Standardı`n"
  if($dnKys.metin -notmatch 'KYS 1, denetim'){ $dusen += 'DIPNOT ISARETI YANLIS ALARM: "KYS 1," silindi' }
  $dnTms = SY_DipnotAyikla "2.       Örneğin, Türkiye Muhasebe Standardı (TMS) 1 yönetimin değerlendirme yapmasını gerektirir.`n         Devam eden metin burada yer alır ve uygulanır.`n`n1 BDS 570, İşletmenin Sürekliliği`n"
  if($dnTms.metin -notmatch '\(TMS\) 1 yönetimin'){ $dusen += 'DIPNOT ISARETI YANLIS ALARM: "(TMS) 1" silindi' }
  # (3) yanlis alarm: layout olmayan (girintisiz) metne DOKUNULMAZ
  $dnDuz = (($dnPop -split "`r?`n" | ForEach-Object { $_.Trim() }) -join "`n") + "`n`n1 Ocak tarihinde başlayan dönemler için bu hükümler uygulanır."
  $dd = SY_DipnotAyikla $dnDuz
  if($dd.dipnot -ne 0 -or $dd.metin -ne $dnDuz -or (SY_BdsBaslikBirlestir $dnDuz) -ne $dnDuz){ $dusen += 'DIPNOT/BASLIK: layout olmayan metin degisti' }
  # (3b) tirnakla baslayan Bkz basligi (BDS 200 p.A16)
  $trn = [string][char]0x201C; $trk = [string][char]0x201D
  $tirnakPar = @(SY_Bol ("A15. Birinci ek paragraf metni burada yer alır ve yeterince uzundur.`n" + $trn + 'Önemli Yanlışlık' + $trk + " Riski (Bkz.: 13(h) paragrafı)`nA16. İkinci ek paragraf metni burada yer alır ve yeterince uzundur.") 'BDS 200')
  if(@($tirnakPar | Where-Object { $_.kaynak_ad -match ' p\.A16 - .Önemli Yanlışlık. Riski' }).Count -ne 1){ $dusen += "TIRNAKLI BKZ BASLIGI: $(@($tirnakPar | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  # (3c) art arda iki uzun Bkz basligi: ilki KAYBOLMAZ (eski davranis: govdeye)
  $ikiBas = @(SY_Bol "18. Birinci paragraf metni burada yer alır ve yeterince uzundur.`nİşletme ve Çevresi ile İç Kontrol Sistemi Hakkında Kanaat Edinilmesi Üst Başlığı (Bkz.: A48-A49 paragrafları)`nİşletme ve Çevresi ile Finansal Raporlama Çerçevesi Hakkında Kanaat Edinilmesi (Bkz.: A50-A55 paragrafları)`n19. İkinci paragraf metni burada yer alır ve yeterince uzundur." 'BDS 315')
  if(-not @($ikiBas | Where-Object { $_.metin -match 'Üst Başlığı' -or $_.kaynak_ad -match 'Üst Başlığı' }).Count -or -not @($ikiBas | Where-Object { $_.kaynak_ad -match ' p\.19 - .*A50-A55' }).Count){ $dusen += "ART ARDA BASLIK KAYBI: $(@($ikiBas | ForEach-Object { $_.kaynak_ad + ' :: ' + $_.metin }) -join ' || ')" }
  # (3d) eski kuralla baslik sanilan govde parcasi yeni kuralli baslikla ezilirse govdeye doner (KYS 2); iki eski-kural basligi ise ESKISI GIBI (ilki duser)
  $tersBas = @(SY_Bol "A15. Birinci ek paragraf metni burada yer alır ve yeterince uzundur.`nBu tür tehditlerin düzeyinin değerlendirilmesiyle ilgili etkenler ve`nKaliteyi Gözden Geçiren Kişinin Liyakatine İlişkin Mevzuat (Bkz.: 18(c) paragrafı)`nA16. İkinci ek paragraf metni burada yer alır ve yeterince uzundur." 'KYS 2')
  if(-not @($tersBas | Where-Object { $_.metin -match 'tehditlerin düzeyinin' }).Count){ $dusen += "EZILEN ESKI-KURAL BASLIGI KAYBOLDU: $(@($tersBas | ForEach-Object { $_.kaynak_ad + ' :: ' + $_.metin }) -join ' || ')" }
  $ikiEski = @(SY_Bol "1. Birinci paragraf metni burada yer alır ve yeterince uzundur.`nGiriş`nKapsam`n2. İkinci paragraf metni burada yer alır ve yeterince uzundur." 'BDS 999')
  if(@($ikiEski | Where-Object { $_.metin -match 'Giriş' }).Count -or @($ikiEski | Where-Object { $_.kaynak_ad -eq 'BDS 999 p.2 - Kapsam' }).Count -ne 1){ $dusen += "ESDEGERLIK: iki eski-kural basligi davranisi degisti: $(@($ikiEski | ForEach-Object { $_.kaynak_ad + ' :: ' + $_.metin }) -join ' || ')" }
  # (4) yanlis alarm: tanim cumlesi "(Bkz.: …)" ile bitse de baslik DEGILDIR (KYS 1) · icindekiler satirlari birlesmez (BDS 210)
  $kysT = @(SY_Bol "1. Birinci paragraf metni burada yer alır ve yeterince uzundur.`nPersonel: Denetim şirketindeki yönetici ve çalışanlardır. (Bkz.: A20-A21 paragrafı)`n2. İkinci paragraf metni burada yer alır ve yeterince uzundur." 'KYS 1')
  if(@($kysT | Where-Object { $_.kaynak_ad -match 'Personel' }).Count -or -not @($kysT | Where-Object { $_.metin -match 'çalışanlardır' }).Count){ $dusen += "BKZ BASLIK YANLIS ALARM: $(@($kysT | ForEach-Object { $_.kaynak_ad }) -join ' | ')" }
  $icindekiler = "Kapsam..................................................................................... 1`nSözleşmenin Kabulünde Dikkate Alınacak İlave Hususlar Hakkında Açıklamalar Bölümü 18-21`nAçıklayıcı Hükümler ve Uygulama`nBu ek bir cümledir. Ayrıntılar için bakınız (Bkz.: A5`nparagrafı) ve sonraki açıklamalar.`n1.       Birinci paragraf metni burada yer alır`n         ve devam eder.`n         ve devam eder.`n         ve devam eder."
  if((SY_BdsBaslikBirlestir $icindekiler) -ne ($icindekiler -replace "`r","")){ $dusen += 'BASLIK BIRLESTIRME: icindekiler/ uzun satir (Bkz. yok) birlesti' }
  return $dusen
}

$sinav = @(SY_OzSinav)
if($sinav.Count){
  Write-Host '!! STANDART YUTUCU KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $sinav){ Write-Host "   $d" }
  exit 1
}
Write-Host 'Oz-sinav gecti (TMS kipi 11 · BDS kipi 5 · KILAVUZ kipi 4 [01.09 BOBI/KUMI duzeni] · kip secimi 2 · layout karari 3 · uzun baslik/sahte atif 2 · sarkan atif/dipnot 3 · sayfa no + kosu basligi 3 [14.09] · ek atif/numarali Ek A/iki harfli numara 3 · noktali numara/BDS T soneki 2 [16.09] · BDS dipnot/saran baslik/tirnakli/art arda/ezilen baslik/ekte yeniden numara/ardisik dipnot/yanlis alarm 20 [27.09] · BOBI harfli no/mulga/bent-baslik/saran/bolum zinciri/uzun baslik/ek/alt alta numara/atif/xpdf kapisi 23 [21.10] · BOBI bent+numara/ust baslik/sayfa sinirinda saran baslik 12 [21.10 ikinci tur])'
Write-Host '  SINANMAYAN DALLAR: PDF indirme · pdftotext · ambar yazimi · geri okuma'
if($YalnizSinav){ exit 0 }
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
  # 27.09: sayfa dibi dipnotlari basliga/govdeye karismasin (SY_DipnotAyikla; secilen cikarim DEGISMEZ, yalniz dipnot yeri)
  $dipnotSonuc = SY_DipnotAyikla $tamMetin
  $tamMetin = SY_BdsBaslikBirlestir $dipnotSonuc.metin
  Write-Host ("  dipnot   : {0} blok paragraf sonuna tasindi · {1} govde isareti silindi · {2} isaret bulunamadi" -f $dipnotSonuc.dipnot,$dipnotSonuc.isaret,$dipnotSonuc.cozulemeyen)
}

# 21.10: xpdf duzeni (paragraf numarasi satir icinde) kilavuz kipini yutmaya goturur (BOBI 01.09: 64 yutan kayit). TMS/TFRS'de uygulanmaz.
if($standart -notmatch '^(TMS|TFRS)\s'){
  $kilOlcu = SY_KilavuzSatirIci $tamMetin
  if($kilOlcu.bozuk){
    Write-Host ("!! CIKARIM SATIR ICI NUMARA: {0} ondalikli paragraf numarasi satirin ICINDE (satir basinda {1}) - xpdf duzeni. Arac: {2}" -f $kilOlcu.satirIci,$kilOlcu.satirBasi,$arac) -ForegroundColor Red
    Write-Host '   Kilavuz kipi bu metni yutarak boler (BOBI 01.09). poppler pdftotext ile yeniden dene. Ambara dokunulmadi.'
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
# 16.09 — AYRI YAYIN (degisiklik metni) bu standardin parcasi DEGILDIR.
# TSRS 2 kosusunda "TSRS 2 Degisiklikleri - ... (RG 28.07.2026)" 9 parcasi onek suzgecine
# girdi: kuculme freni sahte "5.367 kr kayip" dedi, -uygula olsaydi bu 9 parca SILINIRDI
# ve yeni bolmede karsiligi olmadigi icin geri gelmezdi (elle yedekten dondu).
# Suzgec DAR tutuldu: yalniz ad "<standart> Degisiklikleri" ile BASLIYORSA disarida kalir.
# "degisiklik" gecen paragraf basliklari (TMS 8, BDS 320 p.12, TFRS 14 p.13...) ETKILENMEZ.
# Olcum 16.09: ambarda bu kalipta 9 kayit var, hepsi TSRS 2 (bkz. veri/KGK-KAYNAK-OLCUMU.md).
$suzgec += '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$standart Degisiklikleri*") + '&kaynak_ad=not.like.' + [uri]::EscapeDataString("$standart Değişiklikleri*")

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
  $planNesnesi = [ordered]@{ standart=$standart; url=$url; eski_adlar=@($eski | ForEach-Object { "$($_.kaynak_ad)" }); yeni_adlar=@($yeni | ForEach-Object { "$($_.kaynak_ad)" }); eski_karakter=$eskiKarakter; yeni_karakter=$yeniKarakter; yeni_ozet=@($yeni | ForEach-Object { $md5=[Security.Cryptography.MD5]::Create(); "$($_.kaynak_ad)|$($_.metin.Length)|" + [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($_.metin))) }); eski_ozet=@($eski | ForEach-Object { $md5=[Security.Cryptography.MD5]::Create(); "$($_.kaynak_ad)|$("$($_.metin)".Length)|" + [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("$($_.metin)"))) }) }   # 16.09: yeni_ozet = ad|uzunluk|md5 (eşdeğerlik provası için; yalnız -PlanYaz) · 21.10: eski_ozet aynı biçimde ambar tarafı (ambarla birebir mi sorusu metin düzeyinde)
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
# 16.09 (Cem "2 ve 3 yap", 92'nin isteği): yeniden bölmede adı kalkan parçalara bağlı partiler raporlanır (bedel 0).
#   Rapor: veri/fabrika/kaynak-bolunme-etki-<zaman>-<std>.csv (kopan ad yoksa yazılmaz). Bağ TAŞIMAZ; taşımak için aracı -Tasi ile çağır.
if(-not $BagRaporuYok){
  $etkiAraci = Join-Path $depoKok 'arac\kaynak-bolunme-etki.ps1'
  if(Test-Path $etkiAraci){
    $kabuk = if(Get-Command powershell -ErrorAction SilentlyContinue){ 'powershell' } else { 'pwsh' }   # Linux runner'da yalnız pwsh var
    try { & $kabuk -NoProfile -File $etkiAraci -Standart $standart -YedekDosya $yedekYolu | ForEach-Object { Write-Host "  [bağ raporu] $_" } }
    catch { Write-Host "  [bağ raporu] KOŞMADI: $($_.Exception.Message) — elle: arac\kaynak-bolunme-etki.ps1 -Standart '$standart' -YedekDosya '$yedekYolu'" -ForegroundColor Yellow }
  }
}
Write-Host 'SIRADAKI: motor\butunluk-kapisi.ps1 -yalniz "' + $standart + '" ile delik kalmadigini teyit et.'