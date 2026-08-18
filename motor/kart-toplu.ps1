# ============================================================================
#  KART TOPLU v0.2 - Hap Bilgi Motoru
#  Yenilikler: kod bazinda yapilandirilmis kiymet + Sonnet hakem (anlasmazlikta)
#  + kalici kiymet hafizasi (kiyas: "onceki kayit X -> yeni Y") + gunluk arsiv.
#  Kullanim: powershell -ExecutionPolicy Bypass -File kart-toplu.ps1 -Gun 11-07-2026
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Gun,
  [string]$Model = "claude-haiku-4-5",
  [string]$HakemModel = "claude-sonnet-5",
  # 16.08: teblig islemeden yalniz vitrini birikmis havuzdan yeniden uretir.
  # API'ye HIC gitmez, gun damgasi/besleme yazmaz - sayfa tazeleme aleti.
  [switch]$YalnizVitrin
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# pwsh 7 / .NET Core: windows-1254 icin kod sayfasi saglayicisini kaydet (PS5.1'de zaten var)
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok = Split-Path -Parent $here
# Anahtar (yalniz hata mesaji redaksiyonu icin; cagri artik Invoke-ClaudeMesaj uzerinden gider)
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ try { $key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim() } catch {} }
# 16.08 uc hat: birincil Anthropic/AWS, LIMIT dolunca OTOMATIK OpenRouter yedegi (api-hedef.ps1)
. (Join-Path $here 'api-hedef.ps1')
# 17.08 - DETERMINISTIK TEBLIG YAPISI. Ibare degisikligi, yururluk, eklenen/
# kaldirilan madde ve teblig numarasi METINDEN cikar; modele sorulmaz.
# Sebep: 01.08 kartinda eski_yeni BOS kaldi cunku iki LLM okumasi anlasamadi -
# oysa tebligde "31/7/2026 ibaresi 31/1/2027 seklinde degistirilmistir" yaziyordu.
# Kesin bilgiyi zar atmaya cevirmistik.
. (Join-Path $here 'teblig-yapi.ps1')
$hatAd = ''
try { $hatAd = (Get-ApiHedef).ad } catch {}
if(-not $hatAd -and (Read-ApiEnv 'OPENROUTER_KEY')){ $hatAd = 'openrouter' }
if(-not $hatAd){ throw 'Hicbir Claude hatti yok (ANTHROPIC_API_KEY / AWS uclusu / OPENROUTER_KEY).' }
Write-Host ("Claude birincil hat: " + $hatAd + " (limit dolarsa OpenRouter yedegine gecer)")
$arsivTeblig = Join-Path $here ("arsiv\" + $Gun)
$parcalar = $Gun.Split("-")
$tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($parcalar[2])/$($parcalar[1])/"
$TarihNokta = "$($parcalar[0]).$($parcalar[1]).$($parcalar[2])"

function NormD([string]$s){ if(-not $s){ return "" }; return (($s -replace "\s+"," ").Trim().ToLowerInvariant()) }

# ============================================================================
#  GORSEL BICIMI (17.08.2026 - OLCULDU, kart uretimini kiran seydi)
#
#  Eski kural: ".png ise image/png, DEGILSE image/jpeg". Oysa RG tebliglerinin
#  gorselleri .gif ve .wmz (Windows metafile) olabiliyor. Ikisi de "image/jpeg"
#  diye etiketlenip gonderiliyordu; API bozuk veri gorup 400 (Bad Request)
#  veriyor ve O TEBLIGIN TAMAMI cope gidiyordu.
#  Olcum: 14.08 kosusunda gorseli OLMAYAN teblig islendi (kart cikti), gorseli
#  OLAN iki teblig 400 aldi. Gozetim tebligi tablolarinin GORUNTU olmasi
#  yuzunden kiymet cikmamasinin sebebi de buydu.
#
#  Kural: uzantiya gore DOGRU tur; model okuyamayacagi vektor/metafile
#  bicimleri (wmz/wmf/emf) HIC GONDERILMEZ - cagriyi bastan cope atmaktansa
#  o gorseli atlayip metinle devam etmek yegdir. Atlanan gorsel LOGLANIR
#  (sessizce kaybolmasin - tablo o gorselde olabilir).
# ============================================================================
function GorselTuru([string]$src){
  $u = "$src".ToLowerInvariant()
  if($u -match '\.png(\?|$)'){  return 'image/png' }
  if($u -match '\.gif(\?|$)'){  return 'image/gif' }
  if($u -match '\.webp(\?|$)'){ return 'image/webp' }
  if($u -match '\.jpe?g(\?|$)'){ return 'image/jpeg' }
  return $null   # wmz/wmf/emf/bilinmeyen -> gonderilmez
}

# ============================================================================
#  YANLIS-NEGATIF DUZELTMESI (16.08.2026 - Cem: "hap halinde veriyor muyuz?")
#
#  Cift okuma uzlasmasi ham metni HARFI HARFINE kiyasliyordu. Iki okuma ayni
#  sayiyi bulup FARKLI YAZDIGINDA (1,25 USD/kg <-> 1,25 ABD Dolari/Kg)
#  "ihtilafli" sayilip deger DUSUYORDU. Sonuc: vitrindeki 12 kartin 5'inde
#  hic rakam yok, 6'sinda yururluk yerine "kaynak tebligdeki maddeye bakin".
#  Bu bir kalite kapisi degil OLCUM KUSURUDUR - cubugu indirmeden duzeltilir.
#  Kural degismedi: SAYI ya da BIRIM gercekten farkliysa deger yine DUSER.
# ============================================================================
function KiymetNorm([string]$s){
  if(-not $s){ return "" }
  $t = $s.ToLowerInvariant()
  $t = $t -replace 'abd\s*dolar[^\s\/]*|amerikan\s*dolar[^\s\/]*|usd|\$','usd'
  $t = $t -replace 'kilogram|\bkg\b','kg'
  $t = $t -replace '\badet\b|\bad\b','adet'
  $t = $t -replace 'metrekare|\bm2\b','m2'
  $t = $t -replace '\blitre\b|\blt\b','lt'
  $m = [regex]::Match($t, '\d[\d\.\,]*')
  $sayi = ''
  if($m.Success){
    $ham = $m.Value
    if($ham -match ',\d{1,3}$'){ $ham = ($ham -replace '\.','') -replace ',','.' }
    else { $ham = $ham -replace ',','' }
    $d = 0.0
    if([double]::TryParse($ham, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){
      $sayi = $d.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
    }
  }
  $birimler = @()
  foreach($b in @('usd','kg','adet','m2','lt')){ if($t -match $b){ $birimler += $b } }
  return ($sayi + '|' + (($birimler | Sort-Object) -join '/'))
}

# "yayimini takip eden otuzuncu gun" ile "yayimini takip eden 30. gun" AYNIDIR.
function YururlukNorm([string]$s){
  if(-not $s){ return "" }
  $t = (NormD $s)
  $t = $t -replace ([string][char]0x0131),'i' -replace ([string][char]0x011F),'g' -replace ([string][char]0x015F),'s' -replace ([string][char]0x00FC),'u' -replace ([string][char]0x00F6),'o' -replace ([string][char]0x00E7),'c'
  $yazi = [ordered]@{ 'birinci'='1';'ikinci'='2';'ucuncu'='3';'dorduncu'='4';'besinci'='5';'onuncu'='10';'onbesinci'='15';'yirminci'='20';'otuzuncu'='30';'kirkinci'='40';'altmisinci'='60';'doksaninci'='90' }
  foreach($k in $yazi.Keys){ $t = $t -replace $k, $yazi[$k] }
  if($t -match '(\d{2})[\.\/](\d{2})[\.\/](\d{4})'){ return ('tarih:' + $Matches[1] + '.' + $Matches[2] + '.' + $Matches[3]) }
  if($t -match 'takip eden\D*(\d+)'){ return ('takip:' + $Matches[1]) }
  if($t -match 'yayim\w*\s*tarihinde|yayimlandigi tarihte'){ return 'yayim' }
  if($t -match 'belirtilmemis|bakin'){ return '' }
  return $t
}

# ---- DEFTER KAPISI: anahtar ve deger bicim denetimi ------------------------
# Ayni kural arac/kiymet-defteri-onar.ps1 ve index.html'de de gecerli - defter,
# onarici ve ekran AYNI olcute bakmali, yoksa biri "gecerli" digeri "cop" der.
$KIYMET_BIRIM = '(?<s>-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:,\d+)?)\s*(?<b>%|ABD|USD|Dolar|Avro|Euro|EUR|TL|[kK][gG]|ton|adet)'
function KiymetKodGecerli([string]$kod){
  # GTIP: 4 haneli fasil + en fazla 4 nokta grubu (0713.20 · 3009.40.00.00.12)
  return ("$kod".Trim() -match '^\d{4}(\.\d{2}){0,4}$')
}
function KiymetSayi([string]$s){
  if("$s" -match '[()]'){ return $null }        # "(II/C/6.3.)" gibi atiflar nicelik degil
  $m = [regex]::Match("$s", $KIYMET_BIRIM)
  if(-not $m.Success){ return $null }
  $ham = ($m.Groups['s'].Value -replace '\.','') -replace ',','.'
  $v = 0.0
  if([double]::TryParse($ham,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }
  return $null
}
function KiymetBirim([string]$s){
  $m = [regex]::Match("$s", $KIYMET_BIRIM)
  if(-not $m.Success){ return $null }
  return $m.Groups['b'].Value.ToLowerInvariant()
}
function KiymetDegerGecerli([string]$deger){
  $d = "$deger".Trim()
  if(-not $d){ return $false }
  if($d.Length -gt 60){ return $false }                       # tanim metni sizmis
  if($d -match '(?i)belirtilmemis|belirtilmemiş|bilinmiyor'){ return $false }
  return ($d -match $KIYMET_BIRIM)
}

# kesin_kiymetler tur olarak IKI SEKILDE gelebilir: uretim sirasinda hashtable,
# havuza JSON yazilip geri okununca PSCustomObject. Ikisinde .Count farkli
# davranir (hashtable'da eleman sayisi, PSCustomObject'te guvenilmez), o yuzden
# "bos mu" sorusu tur uzerinden DEGIL, DOLU ALAN SAYISI uzerinden sorulur.
# Bos donerse cagiran taraf basligi hic basmaz.
function DoluKiymetler($nesne){
  if($null -eq $nesne){ return @() }
  $cikti = New-Object System.Collections.Generic.List[object]
  if($nesne -is [System.Collections.IDictionary]){
    foreach($anahtar in $nesne.Keys){
      $d = "$($nesne[$anahtar])".Trim()
      if($d){ $cikti.Add([pscustomobject]@{ kod=$anahtar; deger=$d }) }
    }
  } else {
    foreach($p in @($nesne.PSObject.Properties)){
      $d = "$($p.Value)".Trim()
      if($d){ $cikti.Add([pscustomobject]@{ kod=$p.Name; deger=$d }) }
    }
  }
  return $cikti.ToArray()   # @(List) PS 5.1'de ArgumentException verir
}

# ============================================================================
#  SERIT AYIKLAMA (17.08.2026 - Cem ornekleri gorunce: "eski yeni
#  karsilastirmasi iyi degil")
#
#  Deterministik cikarim metne SADIK ama AYIKLAMASIZDI: metindeki her ibare
#  degisikligini ayni agirlikta gosteriyordu. Olculdu: 50 kartta 157 satir,
#  mukerrer ayiklaninca 137 (20 satir gereksiz), 5 kart 9+ satirli, en uzunu
#  17 satir. Gercek ornekler:
#    - Sigorta karti: "Musteslarliga -> Kuruma" 17 KEZ (tek kurum adi
#      degisikligi, tebligde 17 yerde geciyor)
#    - Kurumlar Vergisi: "Örnek: -> Örnek 4:"  (bilgi degil, numaralandirma)
#  Seridin isi HER degisikligi listelemek degil, KARARI DEGISTIRENI one
#  cikarmak. Kurum adi duzeltmesiyle on yillik sure uzatimi yan yana duramaz.
#
#  AYIKLAMA BASIM ANINDA yapilir - depodaki eski_yeni TAM kalir. Politika
#  degisirse veriyi yeniden uretmek gerekmez.
# ============================================================================
$SERIT_UST_SINIR = 5

# Rakam/tarih/tutar/oran tasiyan satir KARAR DEGISTIRIR -> one alinir.
$SERIT_ONEMLI = '(\d{1,2}[./]\d{1,2}[./]\d{2,4})|(%\s*\d)|(\d)'

# Biçimsel mi: iki taraftan RAKAM ve NOKTALAMA atilinca ayni ve BOS OLMAYAN
# metne dusuyorsa evet.
#   "Örnek:" / "Örnek 4:"  -> ikisi de "örnek"  -> BICIMSEL, gosterilmez
#   "5" / "1"              -> ikisi de ""       -> bos, bicimsel DEGIL (kalir)
#   "beş" / "dört"         -> farkli            -> kalir
function SeritBicimselMi([string]$eski, [string]$yeni){
  $ce = ((NormD $eski) -replace '[\d]','' -replace '[^\p{L}]',' ' -replace '\s+',' ').Trim()
  $cy = ((NormD $yeni) -replace '[\d]','' -replace '[^\p{L}]',' ' -replace '\s+',' ').Trim()
  if(-not $ce -and -not $cy){ return $false }   # iki taraf da salt rakam -> gercek degisiklik
  return ($ce -eq $cy)
}

# Girdi: ham eski_yeni satirlari. Cikti: @{ satirlar=[...]; gizli=N }
# satirlar[].tekrar -> ayni cift kac yerde geciyor (1 ise yazilmaz)
function SeritHazirla($ham){
  $gecerli = @($ham | Where-Object { $_ -and "$($_.eski)".Trim() -and "$($_.yeni)".Trim() })
  if(-not $gecerli.Count){ return @{ satirlar=@(); gizli=0 } }

  # (a) bicimsel olanlari dusur
  $suzulmus = @($gecerli | Where-Object { -not (SeritBicimselMi $_.eski $_.yeni) })

  # (b) ayni (eski->yeni) ciftini BIRLESTIR, kac yerde gectigini say
  $harita = [ordered]@{}
  $sira = 0
  foreach($r in $suzulmus){
    $a = (NormD $r.eski) + '>' + (NormD $r.yeni)
    if($harita.Contains($a)){ $harita[$a].tekrar++ ; continue }
    $harita[$a] = [pscustomobject]@{
      konu=$r.konu; eski=$r.eski; yeni=$r.yeni; kaynak=$r.kaynak; tekrar=1
      onem = if(("$($r.eski)$($r.yeni)") -match $SERIT_ONEMLI){ 1 } else { 0 }
      sira = $sira
    }
    $sira++
  }
  $benzersiz = @($harita.Values)

  # (b2) AYNI DEGISIKLIGIN CEKIMLI HALLERINI birlestir.
  # Sigorta kartinda "Müsteşarlığa->Kuruma", "Müsteşarlığın->Kurumun",
  # "Müsteşarlıkça->Kurumca" ayri satirlardi; ucu de TEK kurum adi
  # degisikligi ve 5 satirlik yerin 3'unu yiyip gercek bilgiyi disari
  # itiyordu. Iki tarafin da ORTAK ONEKI yeterince uzunsa ayni degisiklik
  # sayilir; en kisa hali gosterilir, tekrarlar toplanir.
  # YALNIZ kelime satirlarinda (onem=0) calisir - rakam/tarih satirlari
  # ASLA birlestirilmez (20.000->26.000 ile 20.500->26.500 ayri kalir).
  $ortakOnek = {
    param($a,$b)
    $n = [math]::Min($a.Length,$b.Length); $i = 0
    while($i -lt $n -and $a[$i] -eq $b[$i]){ $i++ }
    return $i
  }
  $birlesik = New-Object System.Collections.Generic.List[object]
  foreach($r in $benzersiz){
    $es = $null
    if($r.onem -eq 0){
      foreach($v in $birlesik){
        if($v.onem -ne 0){ continue }
        $pe = & $ortakOnek (NormD $v.eski) (NormD $r.eski)
        $py = & $ortakOnek (NormD $v.yeni) (NormD $r.yeni)
        if($pe -ge 6 -and $py -ge 5){ $es = $v; break }
      }
    }
    if($es){
      $es.tekrar += $r.tekrar
      # en KISA hali goster (cekimsiz koke en yakin olan)
      if($r.eski.Length -lt $es.eski.Length){ $es.eski = $r.eski; $es.yeni = $r.yeni }
    } else { $birlesik.Add($r) }
  }
  $benzersiz = $birlesik.ToArray()   # @(List) PS 5.1'de ArgumentException verir

  # (c) onemliyi one al. Sort-Object -Stable PS 5.1'de YOK (PS7'de geldi) -
  # kararli sirayi ikinci anahtarla saglariz: onem azalan, sonra ilk gorulme.
  $sirali = @($benzersiz | Sort-Object -Property @{Expression='onem';Descending=$true}, @{Expression='sira';Descending=$false})

  $gost = @($sirali | Select-Object -First $SERIT_UST_SINIR)
  return @{ satirlar=$gost; gizli=([math]::Max(0, $sirali.Count - $gost.Count)) }
}

# ---- kalici kiymet hafizasi -------------------------------------------------
$hafizaDir = Join-Path $here "hafiza"
New-Item -ItemType Directory -Force $hafizaDir | Out-Null
$hafizaYol = Join-Path $hafizaDir "kiymetler.json"
$hafiza = @{}
if(Test-Path $hafizaYol){
  $j = Get-Content $hafizaYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $j.PSObject.Properties){ $hafiza[$p.Name] = @($p.Value) }
}

# ---- gozetim teblig zinciri (motor/rg-gozetim-cikar.ps1 uretir) -------------
# 17.08 - Cem: "eski hali buymus yeni hali bu oldu". Olculdu: 189 arsiv kartinin
# 130'u hangi tebligi degistirdigini SOYLUYOR ama 3'unde eski deger var. Sebep
# Turk mevzuat yazim usulu: "... asagidaki sekilde degistirilmistir" denip yalniz
# YENI metin yaziliyor, eski hal belgede GECMIYOR. Yani eski deger uydurulamaz,
# ONCEKI BELGEDEN okunmali.
# Bu zincir o onceki belgeyi verir - ama YALNIZ ithalat gozetim/korunma
# tebligleri icin (130 kartin 22'si). Genel Teblig (13) ve digerleri (95) icin
# kaynak mevzuat.gov.tr konsolide metni; o hat HENUZ KURULMADI.
# Kart yalnizca "onceki belge suymus" LINKINI tasir - deger UYDURULMAZ.
$zincirYol = Join-Path $kok "veri\gozetim-teblig-zinciri.json"
$gozetimZincir = $null
if(Test-Path $zincirYol){
  try { $gozetimZincir = (Get-Content $zincirYol -Raw -Encoding UTF8 | ConvertFrom-Json).zincir } catch { $gozetimZincir = $null }
}
function OncekiBelge([string]$degistirilen, [datetime]$kartTarihi){
  if(-not $gozetimZincir -or -not $degistirilen){ return $null }
  $m = [regex]::Match($degistirilen, '(?<![\d/])(\d{4}\s*/\s*\d+)(?![\d/])')
  if(-not $m.Success){ return $null }
  $no = ($m.Groups[1].Value -replace '\s','')
  $liste = $gozetimZincir.$no
  if(-not $liste){ return $null }
  # 18.08: TryParseExact YASAK. CI'nin pwsh'inde (yeni .NET) Span'li asiri
  # yuklemeler cikti ve 5-argumanli cagri "Cannot find an overload" ile patladi;
  # 4 kosu ust uste kirmizi bitti, 18.08 kartlari uretilip COPE gitti. Ayni
  # dosyanin cagiran workflow'unda ParseExact($s,$fmt,$null) deseni CI'da
  # kanitli calisiyor - ayni desene cevrildi.
  $onceki = @($liste | Where-Object {
    $t = $null
    try { $t = [datetime]::ParseExact("$($_.tarih)",'dd.MM.yyyy',$null) } catch {}
    if($t){ $t -lt $kartTarihi } else { $false }
  })
  if($onceki.Count -eq 0){ return $null }
  $s = $onceki[-1]
  return [ordered]@{ teblig_no=$no; tarih=$s.tarih; url=$s.url; tur=$s.tur }
}

$istemSablon = @"
Sen, buyuk bir denetim firmasinda 20 yilini doldurmus, kalemi kuvvetli bir vergi ortagisín. Asagida bir Resmi Gazete tebligi metni (ve varsa tablo goruntuleri) var. Gorevin: musterine gonderecegin, 30 saniyede okunan bir 'hap bilgi karti' verisi cikarmak.

ALTIN KURALLAR (dogruluk):
1) Rakam, tarih, oran, GTIP kodu SADECE verilen metinden/goruntuden alinir. Emin olamadigin her sey icin "kaynakta belirtilmemis" yaz. ASLA tahmin etme.
2) Sade Turkce ama HUKUKEN DOGRU terim: gozetim uygulamasi VERGI DEGILDIR - "vergi zammi" gibi yorumlar YASAK. Tebligin yaptigi islemi olgusal soyle. Baslikta yorum/abartma yok.
3) SADECE gecerli JSON dondur.
4) "yururluk" alani SADECE su kaliplardan biri: "yayimi tarihinde" | "yayimini takip eden N. gun" | "GG.AA.YYYY" | "kaynakta belirtilmemis".
5) "birim_kiymetler" YAPILANDIRILMIS olacak: tabloda degeri NET okudugun her kod icin bir satir. Okuyamadigin kodu LISTEYE KOYMA (guven_notu'na yaz).
6) "eski_yeni": bu teblig mevcut bir duzenlemeyi DEGISTIRIYORSA ve eski hal metinde/goruntude ACIKCA gorunuyorsa ("...ibaresi ...seklinde degistirilmistir", "yururlukten kaldirilmistir" gibi) her degisen kalem icin bir satir. ESKI DEGERI ASLA UYDURMA - eski hal kaynakta yoksa o satiri HIC KOYMA; "eski":"kaynakta belirtilmemis" yazilmis bir satir KURAL IHLALIDIR. Degisiklik tebligi degilse bos dizi.
10) JSON string'lerinin ICINDE cift tirnak (") KULLANMA - alinti gerekirse tek tirnak kullan (JSON bozulur).
7) "degistirilen_teblig": degistirilen ana tebligin no/adi (kaynaktan); yoksa bos string.
8) "etki": is etkisi YORUMU (tek yorum alani budur, olgu alanlarina yorum sizdirma). "yon" SADECE: "ithalatci aleyhine" | "ithalatci lehine" | "karisik" | "notr" | "belirsiz". Dayanagi olmayan yon verme - emin degilsen "belirsiz". "aciklama": 1-2 cumleyle NEDEN (or: "gozetim kiymeti yukseldi; bu bedelin altindaki beyanlar ek belge/denetim yuku getirir, ithal maliyeti planlamasi guncellenmeli").
9) "eski_rg": degisiklik tebligiyse, metinde degistirilen ANA tebligin ilk yayimlandigi RG'ye atif vardir ("GG/AA/YYYY tarihli ve NNNNN sayili Resmi Gazete'de yayimlanan..."). O tarihi "GG.AA.YYYY" bicimiyle ver; atif yoksa bos string.

USLUP KURALLARI (buyuk denetim firmalarinin bultenlerinden DAHA IYI yazacaksin; yapay zeka yazdigi ASLA belli olmayacak):
A) Ton: deneyimli ortagin musterisine yazdigi kisa not. Net, kendinden emin, sicak ama laubali degil. Musteriyle konusur gibi, kursu anlatir gibi degil.
B) YASAKLI kaliplar (yapay zeka kokusu): "unutmayin", "unutulmamalidir", "onemlidir", "dikkat edilmelidir", "bu baglamda", "soz konusu", "adim atmak", "surec baslatmak", "genel olarak", "ozetle", ust uste ayni yapiyla baslayan cumleler, gereksiz sifat yiginlari, "!" unlem.
C) Cumleler kisa ve ritmi degisken olsun. Etken cati: "Bakanlik esigi yukseltti", "denetim sikilasti" - "yukseltilmis bulunmaktadir" DEGIL. "-mistir/-mektedir" kuru resmi bitislerinden kacin; "-di/-du/-iyor" dogal bitisleri kullan.
D) Turkce imla KUSURSUZ ve TAM DIAKRITIKLI: ciktinin HER kelimesi Turkce karakterleriyle yazilir (ğ, ü, ş, ı, ö, ç, İ). "gozetim" degil "gözetim", "yururluk" degil "yürürlük", "tebligi" degil "tebliği". BU ISTEM TEKNIK SEBEPLE ASCII YAZILDI - SEN TAKLIT ETME; ASCII'ye dusmus tek kelime bile karti coper. Yarim ceviri kelime YASAK: Ingilizce terimin Turkcesi kullanilir ("clutch/klatch" degil "debriyaj").
E) baslik_sade: iyi bir ekonomi muhabirinin atacagi baslik. Olgusal, 8-14 kelime, urun grubunu soyler.
F) ne_yapmali: genel gecer tavsiye degil, SOMUT is: "Subat sevkiyatlarinin proforma bedellerini yeni esikle karsilastir" gibi. Emir kipi SEN kipiyle ve dogal: "kontrol et", "hazirla", "karsilastir". Site standardi SEN kipidir - "kontrol edin/hazirlayin" (siz) YASAK. Garanti dili de YASAK: "kesinlikle", "mutlaka ...ecektir" yerine kaynaga yaslan ("Teblig uyarinca eklenmesi zorunlu").
G) kimi_ilgilendirir: sektoru/rolu isimlendir ("seramik ithal eden insaat malzemecileri" gibi), "ilgili firmalar" deme.

JSON semasi:
{"baslik_sade":"tek cumle, olgusal","ne_oldu":"1-2 cumle","degistirilen_teblig":"degistirilen ana teblig no/adi veya bos","eski_rg":"GG.AA.YYYY veya bos","eski_yeni":[{"konu":"degisen kalem","eski":"kaynaktan eski hal","yeni":"kaynaktan yeni hal"}],"gtip_kodlari":["tum kodlar"],"urun_tanimi":"esya grubu","kimi_ilgilendirir":"kim","ne_yapmali":"somut adim","yururluk":"kalipli","birim_kiymetler":[{"gtip":"kod","deger":"or: 1.000 ABD Dolari/Ton"}],"etki":{"yon":"kalipli","aciklama":"1-2 cumle yorum"},"guven_notu":"emin olamadiklarin"}

TEBLIG METNI:
"@

function ApiCagri([string]$model, [array]$icerik, [int]$maxTok){
  # 16.08: cagri api-hedef.ps1 uzerinden - Anthropic birincil, limit dolunca OpenRouter yedegi.
  # Bicim cevirisi (OpenAI<->Anthropic) + Turkce Latin-1 duzeltmesi Invoke-ClaudeMesaj icinde.
  $r = Invoke-ClaudeMesaj -Model $model -Icerik $icerik -MaxTok $maxTok
  # 17.08: onbellek sayaclari da tasinir. 'girdi' artik GERCEK toplam girdiyi
  # tasir (ham + onbellege yazilan + onbellekten okunan) - cache_control
  # eklendikten sonra ham input_tokens yalniz sinirdan sonrasini sayardi ve
  # maliyet raporu sessizce eksik cikardi.
  $gt = if($null -ne $r.girdiToplam){ [int]$r.girdiToplam } else { [int]$r.girdi }
  $script:onbYaz += [int]$r.onbellekYazma
  $script:onbOku += [int]$r.onbellekOkuma
  return @{ metin = $r.metin; girdi = $gt; cikti = $r.cikti;
            onbellekYazma = [int]$r.onbellekYazma; onbellekOkuma = [int]$r.onbellekOkuma }
}
# Kosu boyu onbellek toplami - kosu sonunda raporlanir. Onbellek CALISIYORSA
# onbOku > 0 olmalidir; sifir kalirsa isaret bir yere OTURMAMIS demektir
# (en sik sebep: on ek modelin minimum onbellek esiginin altinda).
$script:onbYaz = 0
$script:onbOku = 0

function JsonAyikla([string]$c){
  if($c -match "(?s)\{.*\}"){ return ($Matches[0] | ConvertFrom-Json) }
  throw "JSON bulunamadi"
}

# ---- ESKI METIN BULUCU: degisiklik tebliginin atif verdigi tarihli RG'den ana tebligi ceker ----
#  Cem kurali: "elimizde yok" mazeret degil - RG arsivi acik, eski metni sistemden cek, karsilastir.
#  Onbellek: motor/arsiv-eski/ (her eski teblig bir kez indirilir; CI'da commit'lenir).
$eskiDir = Join-Path $here "arsiv-eski"
New-Item -ItemType Directory -Force $eskiDir | Out-Null
function EskiMetinBul([string]$rgTarih, [string]$tebligNo){
  # rgTarih: GG.AA.YYYY ; tebligNo: or 2018/5
  $guvenliAd = ($rgTarih -replace '\.','-') + "_" + ($tebligNo -replace '/','-') + ".htm"
  $cachYol = Join-Path $eskiDir $guvenliAd
  $eskiUrl = $null
  if(-not (Test-Path $cachYol)){
    try {
      $fih = (Invoke-WebRequest -Uri ("https://www.resmigazete.gov.tr/" + $rgTarih) -UserAgent "Mozilla/5.0 (MevzuatRadar-KartMotoru)" -TimeoutSec 60 -UseBasicParsing).Content
    } catch { return $null }
    $rxE = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/\d{8}-\d+\.htm)"[^>]*>(?<t>.*?)</a>'
    foreach($m in $rxE.Matches($fih)){
      $t = ($m.Groups["t"].Value -replace "<[^>]+>"," " -replace "\s+"," ")
      # eslesme anahtari: teblig numarasi (or "2018/5") - basliklarda hep gecer
      if($t -match [regex]::Escape($tebligNo)){
        $u = $m.Groups["u"].Value
        if($u -notmatch "^https?:"){ $u = "https://www.resmigazete.gov.tr" + $(if($u.StartsWith("/")){""}else{"/"}) + $u }
        try {
          $wcE = New-Object System.Net.WebClient
          $wcE.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-KartMotoru)")
          [System.IO.File]::WriteAllBytes($cachYol, $wcE.DownloadData($u))
          $eskiUrl = $u
        } catch { return $null }
        break
      }
    }
    if(-not (Test-Path $cachYol)){ return $null }
  }
  # metin + gorseller (eski tablolar da goruntude olabilir)
  $hamE = [System.IO.File]::ReadAllBytes($cachYol)
  $htmlE = [System.Text.Encoding]::GetEncoding(1254).GetString($hamE)
  $metinE = ($htmlE -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
  $metinE = [System.Net.WebUtility]::HtmlDecode($metinE)
  if($metinE.Length -gt 9000){ $metinE = $metinE.Substring(0,9000) }
  $gorsellerE = @()
  $pE = $rgTarih.Split("."); $tabanE = "https://www.resmigazete.gov.tr/eskiler/$($pE[2])/$($pE[1])/"
  $imgE = [regex]::Matches($htmlE,'(?i)<img[^>]+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 2
  foreach($srcE in $imgE){
    $iu = if($srcE -match "^https?:"){ $srcE } else { $tabanE + ($srcE -replace "^\./","") }
    try {
      $wcI = New-Object System.Net.WebClient
      $wcI.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-KartMotoru)")
      $mi = GorselTuru $srcE
      if(-not $mi){ Write-Host ("  gorsel ATLANDI (desteklenmeyen bicim): " + $srcE); continue }
      $bi = $wcI.DownloadData($iu)
      $gorsellerE += @{ type="image"; source=@{ type="base64"; media_type=$mi; data=[Convert]::ToBase64String($bi) } }
    } catch {}
  }
  return @{ metin = $metinE; gorseller = $gorsellerE; url = $eskiUrl }
}

# Arsiv klasoru yoksa bu HATA DEGILDIR: o gun ilgilendiren teblig inmemistir.
# (Eskiden Get-ChildItem patliyor, betik hic calismiyordu - vitrini havuzdan
#  tazelemek bile mumkun degildi.)
$dosyalar = @()
if($YalnizVitrin){
  "YALNIZ VITRIN modu: teblig islenmeyecek, sayfa birikmis havuzdan yeniden uretilecek. (API cagrisi YOK)"
} elseif(Test-Path $arsivTeblig){
  $dosyalar = @(Get-ChildItem $arsivTeblig -Filter "*.htm" | Sort-Object Name)
} else {
  "Arsiv klasoru yok ($Gun) - islenecek teblig bulunmadi."
}
"Toplam teblig: $($dosyalar.Count) | Model: $Model | Hakem: $HakemModel"
$kartlar = @(); $topGirdi = 0; $topCikti = 0; $hakemGirdi = 0; $hakemCikti = 0; $hatali = 0; $hakemSayisi = 0

foreach($d in $dosyalar){
  try {
    $ham = [System.IO.File]::ReadAllBytes($d.FullName)
    $html = [System.Text.Encoding]::GetEncoding(1254).GetString($ham)
    $metin = ($html -replace "(?is)<script.*?</script>","" -replace "(?is)<style.*?</style>","" -replace "<[^>]+>"," " -replace "&nbsp;"," " -replace "\s+"," ").Trim()
    $metin = [System.Net.WebUtility]::HtmlDecode($metin)
    if($metin.Length -gt 12000){ $metin = $metin.Substring(0,12000) }

    $gorseller = @()
    $imgler = [regex]::Matches($html,'(?i)<img[^>]+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique -First 3
    foreach($src in $imgler){
      $imgUrl = if($src -match "^https?:"){ $src } else { $tabanUrl + ($src -replace "^\./","") }
      try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (MevzuatRadar-v0)")
        $mime = GorselTuru $src
        if(-not $mime){ Write-Host ("  gorsel ATLANDI (desteklenmeyen bicim): " + $src); continue }
        $b = $wc.DownloadData($imgUrl)
        $gorseller += @{ type="image"; source=@{ type="base64"; media_type=$mime; data=[Convert]::ToBase64String($b) } }
      } catch {}
    }
    # 17.08 PROMPT ONBELLEGI. Asagidaki cift gecis AYNI istemi 2 kez (JSON bozulursa
    # 3-4 kez) gonderiyor. Son bloga cache_control konunca 1. cagri onbellege YAZAR,
    # 2./3./4. cagri tamamini OKUR - okuma taban girdi fiyatinin %10'u.
    #   2 cagri : 1,25 + 0,10 = 1,35  (yerine 2,00)  -> %32 tasarruf
    #   4 cagri : 1,25 + 0,30 = 1,55  (yerine 4,00)  -> %61 tasarruf
    #
    # NEDEN SON BLOK, sablonun kendisi DEGIL: onbellek ON-EK eslesmesidir ve
    # minimum onbelleklenebilir on ek MODELE GORE degisir - Haiku 4.5'te 4.096
    # JETON. Sablon tek basina 4.557 KARAKTER (~1.500-1.800 jeton) yani esigin
    # ALTINDA: ona isaret koymak sessizce hic onbelleklemez. Tam istem (sablon +
    # 12.000 karakterlik teblig metni + 3 gorsele kadar) esigi rahat gecer.
    # Olculdu 17.08; jeton sayma ucu de harcama tavanina takili oldugu icin
    # karakterden yuruldu - 4.557 karakterin 4.096 jetona cikmasi 1,11 krk/jeton
    # gerektirir, hicbir metinde mumkun degil.
    #
    # Yedek hatta (OpenRouter) cache_control TASINMAZ: api-hedef.ps1 onu ayiklar
    # ve kosu basina bir kez uyarir. Sonuc ayni, girdi maliyeti tam odenir.
    $icerikTam = @() + $gorseller + @(@{ type="text"; text=($istemSablon + $metin); cache_control=@{ type="ephemeral" } })

    # --- cift gecis (uzun tablolar icin genis token; JSON bozuksa o gecis 1 kez tekrarlanir) ---
    $g1 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g1.girdi; $topCikti += $g1.cikti
    $g2 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g2.girdi; $topCikti += $g2.cikti
    try { $k1 = JsonAyikla $g1.metin } catch { $g1 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g1.girdi; $topCikti += $g1.cikti; $k1 = JsonAyikla $g1.metin }
    try { $k2 = JsonAyikla $g2.metin } catch { $g2 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g2.girdi; $topCikti += $g2.cikti; $k2 = JsonAyikla $g2.metin }

    $notlar = @()

    # ================= DETERMINISTIK YAPI (modelden ONCE) ===================
    # Metinden dogrudan okunanlar modele SORULMAZ ve model onlari EZEMEZ.
    # Cokerse kart uretimi durmaz; yalnizca bu zenginlestirme atlanir.
    $yapi = $null
    try { $yapi = TebligYapiCikar $d.FullName }
    catch { $notlar += ("Yapi cikarimi yapilamadi: " + $_.Exception.Message) }

    # GTIP karsilastirma
    $gtip1 = @($k1.gtip_kodlari) -join ","; $gtip2 = @($k2.gtip_kodlari) -join ","
    $gtipFinal = if($gtip1 -eq $gtip2){ @($k1.gtip_kodlari) } else {
      $notlar += "GTIP listesi iki okumada farkli - kesisim alindi"
      @($k1.gtip_kodlari) | Where-Object { @($k2.gtip_kodlari) -contains $_ }
    }

    # ---- YURURLUK -----------------------------------------------------------
    # 17.08 (Cem, 01.08 karti): kartta "Kaynak tebliğdeki yürürlük maddesine
    # bakın" yaziyordu. Tebligin MADDE 8'i ise sunu diyordu:
    #     a) 6'nci maddesi yayimi tarihinde, b) diger hukumleri 1/10/2026'da.
    # Yani tebligin IKI AYRI yururluk tarihi vardi ve kartin en karar-degistirici
    # bilgisi buydu. Cevabi bilip soylememek, nobetci olan bir urunun yapabilecegi
    # en kotu sey. Yeni sira:
    #   1) DETERMINISTIK cikarim (yururluge girer maddesi) - modeli EZER
    #   2) iki okumanin uzlastigi/tek somut olani
    #   3) hicbiri yoksa BOS - alan hic basilmaz. Yer tutucu ARTIK YOK.
    $yurBentler = @()
    if($yapi -and @($yapi.yururluk).Count){
      $yurBentler = @($yapi.yururluk | Where-Object { $_.tarih })
    }
    $yurFinal = $null
    if($yurBentler.Count -eq 1 -and -not $yurBentler[0].bent){
      $yurFinal = $yurBentler[0].tarih
    } elseif($yurBentler.Count -ge 1){
      # bolunmus yururluk: her bent ayri yazilir
      $yurFinal = (($yurBentler | ForEach-Object { "$($_.kapsam): $($_.tarih)" }) -join ' · ')
    } else {
      $yn1 = YururlukNorm $k1.yururluk
      $yn2 = YururlukNorm $k2.yururluk
      $yurFinal = if($yn1 -and $yn1 -eq $yn2){ $k1.yururluk }
                  elseif($yn1 -and -not $yn2){ $k1.yururluk }
                  elseif($yn2 -and -not $yn1){ $k2.yururluk }
                  else { $null }
    }
    # KAPI: yer tutucu cevaplar reddedilir. Istemde kural vardi (satir ~189)
    # ama ZORLAMASI yoktu; model kurali cignedi ve hicbir sey yakalamadi.
    # Olculdu: 6 kartta bu yer tutucu var.
    if($yurFinal -and (NormD $yurFinal) -match 'kaynak teblig|bakin|bakiniz|ilgili madde|maddesine bak'){
      $notlar += "Yururluk yer tutucu geldi ('$yurFinal') - REDDEDILDI, alan bos birakildi"
      $yurFinal = $null
    }

    # etki yonu: iki okuma anlasamiyorsa YORUM yayinlanmaz ("belirsiz") - yorumda tek okumaya guvenilmez
    $etkiFinal = $null
    if($k1.etki -and $k1.etki.yon){
      $y1 = NormD $k1.etki.yon; $y2 = if($k2.etki){ NormD $k2.etki.yon } else { "" }
      if($y1 -eq $y2 -and $y1 -ne "belirsiz"){ $etkiFinal = @{ yon = $k1.etki.yon; aciklama = $k1.etki.aciklama } }
      elseif($y1 -ne $y2){ $notlar += "Etki yorumu iki okumada farkli cikti - yayinlanmadi" }
    }

    # eski->yeni: sadece iki okumanin da ayni KONUYU gordugu satirlar (uydurmaya karsi ikinci kilit)
    # + script-tarafi filtre: 'eski' bos/"belirtilmemis" olan satir YAYINLANMAZ (model kurali ihlal etse bile)
    $ey1 = @($k1.eski_yeni) | Where-Object { $_.eski -and (NormD $_.eski) -notmatch "belirtilmemis|belirtilmemiş|yer almiyor" }
    $ey2 = @($k2.eski_yeni) | Where-Object { $_.eski -and (NormD $_.eski) -notmatch "belirtilmemis|belirtilmemiş|yer almiyor" }
    $eskiYeniFinal = @()

    # (A) DETERMINISTIK SATIRLAR — BIRINCIL KAYNAK, cift okuma kapisina TABI DEGIL.
    # "X ibaresi Y seklinde degistirilmistir" Turk mevzuatinin standart kalibidir;
    # duz metin eslemesiyle hatasiz cikar. Bunu iki LLM okumasinin anlasmasina
    # baglamak 01.08 kartinda dogru cifti (31/7/2026 -> 31/1/2027) COPE ATMISTI.
    # Model gorusu degil metnin kendisi oldugu icin uzlasma aranmaz.
    $ibareAnahtar = @{}
    if($yapi){
      foreach($ib in @($yapi.ibare)){
        $satir = [pscustomobject]@{ konu = $ib.konu; eski = $ib.eski; yeni = $ib.yeni }
        $eskiYeniFinal += $satir
        $ibareAnahtar[(NormD $ib.eski) + '>' + (NormD $ib.yeni)] = $true
      }
    }

    # (B) MODELIN BULDUKLARI — yalnizca EK. Burada cift okuma sarti AYNEN durur
    # (uydurmaya karsi kilit), ayrica deterministik listede zaten varsa tekrarlanmaz.
    foreach($r in $ey1){
      if(-not $r.konu){ continue }
      $es = $ey2 | Where-Object { (NormD $_.konu) -eq (NormD $r.konu) } | Select-Object -First 1
      if(-not ($es -and (NormD $es.yeni) -eq (NormD $r.yeni))){ continue }
      if($ibareAnahtar.ContainsKey((NormD $r.eski) + '>' + (NormD $r.yeni))){ continue }
      $eskiYeniFinal += $r
    }
    if($ey1.Count -and -not $eskiYeniFinal.Count){ $notlar += "Eski-yeni karsilastirmasi iki okumada uyusmadi - yayinlanmadi" }

    # --- ESKI RG METNIYLE GERCEK KARSILASTIRMA (Cem: elimizde yoksa sistemden CEK) ---
    # Degisiklik tebligi eski hukmu yazmasa bile: atif verdigi tarihli RG'den ana tebligi indir,
    # eski+yeni metni (ve tablolarin goruntulerini) yan yana ver -> gercek eskiden->simdi.
    $eskiKarUrl = $null
    $tebNoM = [regex]::Match("$($k1.degistirilen_teblig)", '\d{4}/\d+')
    $eskiRg1 = "$($k1.eski_rg)"
    if($tebNoM.Success -and $eskiRg1 -match '^\d{2}\.\d{2}\.\d{4}$' -and $eskiRg1 -eq "$($k2.eski_rg)"){
      $eskiVeri = EskiMetinBul $eskiRg1 $tebNoM.Value
      if($eskiVeri){
        try {
          $kIstem = @"
Ayni tebligin iki hali asagida. ESKI = $eskiRg1 tarihli RG'deki ana teblig. YENI = bugunku degisiklik tebligi. Ilk goruntuler (varsa) ESKI teblige, sonrakiler YENI teblige aittir.
Gorevin: DEGISEN kalemleri cikarmak. SADECE iki kaynakta da ACIKCA gordugun degerleri yaz; okuyamadigini/emin olamadigini HIC yazma, tahmin YASAK.
SADECE JSON: {"baslik_sade":"iki metne dayali, yonu DOGRU tek cumle baslik (8-14 kelime)","kalemler":[{"konu":"or GTIP 6907.30 birim kiymeti","eski":"or 1.200 ABD Dolari/Ton","yeni":"or 1.500 ABD Dolari/Ton"}],"ne_oldu":"iki metne dayanarak 1-2 cumleyle NE DEGISTI (yon dahil: siklasti mi gevsedi mi - metinden)","etki":{"yon":"ithalatci aleyhine|ithalatci lehine|karisik|notr|belirsiz","aciklama":"1-2 cumle"}}

ESKI METIN:
$($eskiVeri.metin)

YENI (DEGISIKLIK) METNI:
$metin
"@
          $kIcerik = @() + @($eskiVeri.gorseller) + $gorseller + @(@{ type="text"; text=$kIstem })
          $gk = ApiCagri $Model $kIcerik 2200; $topGirdi += $gk.girdi; $topCikti += $gk.cikti
          $kj = JsonAyikla $gk.metin
          $kal = @($kj.kalemler | Where-Object { $_.konu -and $_.eski -and $_.yeni })
          if($kal.Count){
            $eskiYeniFinal = $kal
            $eskiKarUrl = $eskiRg1
            # iki metne dayali duzyazi, tek-okuma duzyazisini EZER (yon hatasi kacagi onlenir) - BASLIK DAHIL
            if($kj.ne_oldu){ $k1.ne_oldu = $kj.ne_oldu }
            if($kj.baslik_sade){ $k1.baslik_sade = $kj.baslik_sade }
            if($kj.etki -and (NormD $kj.etki.yon) -ne "belirsiz"){
              $etkiFinal = @{ yon = $kj.etki.yon; aciklama = $kj.etki.aciklama }
              # cift-okuma asamasinin 'yorum yayinlanmadi' kalintisini temizle (celiski olmasin)
              $notlar = @($notlar | Where-Object { $_ -notmatch "Etki yorumu iki okumada" })
              $notlar += "Yorum, eski-yeni metin karsilastirmasina dayanir"
            }
            $notlar += "Karsilastirma $eskiRg1 tarihli RG'deki ana teblig metniyle yapildi (arada baska degisiklik olduysa zinciri kaynaktan kontrol edin)"
          }
        } catch { $notlar += "Eski metinle karsilastirma gecisi basarisiz" }
      } else { $notlar += "Ana tebligin eski metni RG arsivinde bulunamadi ($eskiRg1)" }
    }

    # --- KOD BAZINDA kiymet karsilastirma ---
    $m1 = @{}; foreach($x in @($k1.birim_kiymetler)){ if($x.gtip){ $m1[$x.gtip] = $x.deger } }
    $m2 = @{}; foreach($x in @($k2.birim_kiymetler)){ if($x.gtip){ $m2[$x.gtip] = $x.deger } }
    $tumKodlar = @($m1.Keys) + @($m2.Keys) | Select-Object -Unique
    $kesin = [ordered]@{}; $ihtilafli = @()
    foreach($kod in $tumKodlar){
      # SAYI + BIRIM kiyaslanir, yazim bicimi degil. Gercek fark varsa kod
      # yine IHTILAFLI kalir ve hakeme gider - kural gevsemedi.
      $n1 = if($m1.ContainsKey($kod)){ KiymetNorm $m1[$kod] } else { '' }
      $n2 = if($m2.ContainsKey($kod)){ KiymetNorm $m2[$kod] } else { '' }
      if($n1 -and $n1 -eq $n2){ $kesin[$kod] = $m1[$kod] }
      else { $ihtilafli += $kod }
    }

    # --- Sonnet HAKEM (sadece ihtilafli kodlar) ---
    if($ihtilafli.Count -gt 0){
      $hakemSayisi++
      try {
        $hIstem = "Tablo goruntusunden SADECE su GTIP kodlarinin birim kiymet degerini oku: " + ($ihtilafli -join ", ") + ". SADECE JSON dizisi dondur: [{`"gtip`":`"kod`",`"deger`":`"deger birimiyle`"}]. Bir kodu net okuyamiyorsan deger alanina `"okunamadi`" yaz. Tahmin YASAK."
        $hIcerik = @() + $gorseller + @(@{ type="text"; text=$hIstem })
        $gh = $null
        foreach($deneme in 1..2){
          try { $gh = ApiCagri $HakemModel $hIcerik 700; break }
          catch { if($deneme -eq 2){ throw }; Start-Sleep -Seconds 3 }
        }
        $hakemGirdi += $gh.girdi; $hakemCikti += $gh.cikti
        $hj = if($gh.metin -match "(?s)\[.*\]"){ $Matches[0] | ConvertFrom-Json } else { @() }
        foreach($hx in @($hj)){
          $kod = $hx.gtip; $hd = $hx.deger
          if(-not $kod -or $ihtilafli -notcontains $kod){ continue }
          if((NormD $hd) -eq "okunamadi" -or -not $hd){ continue }
          # 2/3 oy: hakem, iki okumadan biriyle uyusuyorsa kabul
          if(($m1.ContainsKey($kod) -and (KiymetNorm $m1[$kod]) -eq (KiymetNorm $hd)) -or ($m2.ContainsKey($kod) -and (KiymetNorm $m2[$kod]) -eq (KiymetNorm $hd))){
            $kesin[$kod] = $hd
            $ihtilafli = @($ihtilafli | Where-Object { $_ -ne $kod })
          }
        }
      } catch { $notlar += "Hakem gecisi basarisiz oldu" }
    }
    if($ihtilafli.Count -gt 0){ $notlar += ("Su kodlarin kiymeti guvenle okunamadi: " + ($ihtilafli -join ", ")) }

    # --- HAFIZA: kiyas + kayit ---
    $kiyaslar = @()
    foreach($kod in $kesin.Keys){
      $yeni = $kesin[$kod]
      # 17.08 DEFTER KAPISI. Olculdu: kiymetler.json'daki 313 kaydin 200'u
      # NICELIK DEGIL METINDI - "0713.20 -> Istanbul Tekstil ve Konfeksiyon
      # Ihracatci Birligi", "3211.00.00.00.00 -> mustahzar kurutucu maddeler",
      # "3215.90.70.00.12 -> kaynakta belirtilmemis". 15 anahtar da GTIP
      # bicimine uymuyordu (biri 160 karakter, biri "336"). Bu defter
      # "eski -> yeni" seridinin TEMELI; ici cop olursa serit yalan soyler.
      # Iki kapi: anahtar GTIP biciminde olacak, deger TANINAN BIR BIRIM
      # tasiyacak. Gecemeyen kayit deftere GIRMEZ (kart yine basilir).
      if(-not (KiymetKodGecerli $kod)){   continue }
      if(-not (KiymetDegerGecerli $yeni)){ continue }
      if(-not $hafiza.ContainsKey($kod)){ $hafiza[$kod] = @() }
      $sonKayit = if($hafiza[$kod].Count){ $hafiza[$kod][-1] } else { $null }
      # kiyas SADECE onceki kayit baska bir gundense (ayni gun tekrar calistirma gurultusu kiyas sayilmaz)
      if($sonKayit -and $sonKayit.tarih -ne $TarihNokta -and (NormD $sonKayit.deger) -ne (NormD $yeni)){
        $kiyaslar += ("{0}: onceki kaydimiz {1} ({2}) -> yeni {3}" -f $kod, $sonKayit.deger, $sonKayit.tarih, $yeni)
      }
      if($sonKayit -and $sonKayit.tarih -eq $TarihNokta){
        # ayni gunun kaydini guncelle (kopya olusturma)
        $hafiza[$kod][-1] = [pscustomobject]@{ tarih=$TarihNokta; deger=$yeni; teblig=$d.Name }
      } elseif(-not $sonKayit -or (NormD $sonKayit.deger) -ne (NormD $yeni)){
        $hafiza[$kod] = @($hafiza[$kod]) + @([pscustomobject]@{ tarih=$TarihNokta; deger=$yeni; teblig=$d.Name })
      }
    }

    # --- SONNET CILA: duzyazi alanlarinda imla+uslup parlatma. SAYI KORUMASI: metindeki
    #     rakam kumesi degisirse cila REDDEDILIR (orijinal kalir) - cila asla veri bozamaz.
    $duzyazi = [ordered]@{ baslik_sade=$k1.baslik_sade; ne_oldu=$k1.ne_oldu; urun_tanimi=$k1.urun_tanimi; kimi_ilgilendirir=$k1.kimi_ilgilendirir; ne_yapmali=$k1.ne_yapmali }
    if($etkiFinal){ $duzyazi["etki_aciklama"] = $etkiFinal.aciklama }
    try {
      $cIstem = "Asagidaki JSON'daki Turkce metinleri AYNI anlamla parlat: kusursuz imla, dogal-profesyonel uslup (deneyimli vergi ortaginin notu), yapay kaliplar yok. RAKAM/TARIH/GTIP/ORAN ASLA degistirme-ekleme-cikarma. Ayni anahtarlarla SADECE JSON dondur.`n" + (($duzyazi | ConvertTo-Json -Depth 3))
      $gc = ApiCagri $HakemModel @(@{type="text";text=$cIstem}) 1200
      $hakemGirdi += $gc.girdi; $hakemCikti += $gc.cikti
      $cj = JsonAyikla $gc.metin
      # SAYI KUMESI: iki taraf da ayni kanonik bicime (JSON) cevrilir - OrderedDictionary/PSObject farki tuzagina dusme
      $sayiCek = { param($o) (([regex]::Matches(($o | ConvertTo-Json -Depth 3), '\d[\d\.,/]*').Value | Sort-Object) -join "|") }
      if((& $sayiCek $duzyazi) -eq (& $sayiCek $cj)){
        if($cj.baslik_sade){ $k1.baslik_sade=$cj.baslik_sade }; if($cj.ne_oldu){ $k1.ne_oldu=$cj.ne_oldu }
        if($cj.urun_tanimi){ $k1.urun_tanimi=$cj.urun_tanimi }; if($cj.kimi_ilgilendirir){ $k1.kimi_ilgilendirir=$cj.kimi_ilgilendirir }
        if($cj.ne_yapmali){ $k1.ne_yapmali=$cj.ne_yapmali }
        if($etkiFinal -and $cj.etki_aciklama){ $etkiFinal.aciklama = $cj.etki_aciklama }
      } else { $notlar += "Cila gecisi rakam degistirdi - reddedildi, orijinal metin kullanildi" }
    } catch { }

    $final = [ordered]@{
      dosya = $d.Name; kaynak = ($tabanUrl + $d.Name)
      baslik_sade = $k1.baslik_sade; ne_oldu = $k1.ne_oldu
      # 17.08: teblig KENDI numarasini soylemiyordu. 01.08 karti "2023/5'i
      # degistirdi" diyordu ama okuyan hangi tebligi arayacagini bilmiyordu;
      # aradigi numara 2026/11'di. Basliktan deterministik cikar.
      teblig_no = $(if($yapi){ $yapi.teblig_no })
      # Hangi maddeler eklendi/kaldirildi/bastan yazildi. Kart "yeni maddelerle
      # agir yaptirimlar getirildi" gibi genel konusuyordu; oysa numaralar
      # metinde acikca duruyor (4/A yaptirim, 6/A inceleme, 6/B usul).
      degisen_maddeler = $(if($yapi){
        @(
          @($yapi.eklenen    | ForEach-Object { "$($_.madde) eklendi" }) +
          @($yapi.kaldirilan | ForEach-Object { "$($_.madde) yürürlükten kaldırıldı" }) +
          @($yapi.degisen    | ForEach-Object { "$($_.madde) baştan yazıldı" })
        ) | Where-Object { $_ }
      } else { @() })
      degistirilen_teblig = $(if($yapi -and $yapi.degistirilen_teblig){ $yapi.degistirilen_teblig } else { $k1.degistirilen_teblig })
      onceki_belge = (OncekiBelge $k1.degistirilen_teblig ([datetime]::ParseExact($Gun,'dd-MM-yyyy',$null)))
      eski_yeni = $eskiYeniFinal
      eski_karsilastirma = $eskiKarUrl
      gtip_kodlari = $gtipFinal; urun_tanimi = $k1.urun_tanimi
      kimi_ilgilendirir = $k1.kimi_ilgilendirir; ne_yapmali = $k1.ne_yapmali
      yururluk = $yurFinal
      kesin_kiymetler = $kesin
      kiyaslar = $kiyaslar
      etki = $etkiFinal
      guven_notu = (@($k1.guven_notu) + $notlar | Where-Object { $_ }) -join " | "
    }
    $kartlar += $final
    Write-Host ("{0} | kesin kiymet: {1} | ihtilafli: {2} | kiyas: {3}" -f $d.Name, $kesin.Count, $ihtilafli.Count, $kiyaslar.Count)
  } catch {
    # tek yeniden deneme (JSON hatasi gecici olabilir)
    $hatali++
    $hmsg = $_.Exception.Message
    if($key){ $hmsg = $hmsg -replace [regex]::Escape($key),"***" }
    Write-Host ("HATA {0}: {1}" -f $d.Name, $hmsg) -ForegroundColor Yellow
  }
}

# hafizayi kaydet
$hafizaObj = [ordered]@{}
foreach($kod in ($hafiza.Keys | Sort-Object)){ $hafizaObj[$kod] = $hafiza[$kod] }
($hafizaObj | ConvertTo-Json -Depth 6) | Out-File $hafizaYol -Encoding utf8

# ============================================================================
#  KOR KALMA FRENI (16.08.2026 - Cem: "burasi calismiyor")
#
#  NE OLDU: 12 ve 14 Agustos'ta RG'den ilgili teblig INDI, uretim API tavani
#  yuzunden her tebligde patladi, $kartlar BOS kaldi. Bos dizinin
#  ConvertTo-Json ciktisi BOSTUR -> diske 0 BAYTLIK kartlar.json yazildi.
#  O dosya kartlar.yml icin "bu gun islendi" damgasi sayildigi icin iki gun
#  bir daha HIC denenmedi; ustelik vitrin "0 duzenleme"ye ezildi ve 05.08'den
#  beri duran kartlar sayfadan silindi. Commit mesaji da "RG sakin" dedi -
#  teblig vardi, uretim colmustu. Uc kati kor kalma.
#
#  KURAL: teblig islenmis ama HATA yuzunden kart cikmamissa bu gun
#  ISLENMIS SAYILMAZ. Damga yazilmaz, vitrin ezilmez, kosu KIRMIZI biter.
# ============================================================================
if($kartlar.Count -eq 0 -and $hatali -gt 0){
  Write-Host ""
  Write-Host ("KIRMIZI: {0} gununde {1} teblig islendi, HEPSI HATA verdi, kart uretilemedi." -f $Gun, $hatali) -ForegroundColor Red
  Write-Host "Bu gun ISLENMIS SAYILMIYOR - damga yazilmadi, vitrin korundu, sonraki kosu yeniden deneyecek."
  Write-Host "(Sebep genellikle API hattidir: Anthropic tavani dolduysa OpenRouter yedegi devrede mi bak.)"
  exit 1
}

# kart verisini kaydet (YalnizVitrin modunda YAZILMAZ - sahte "islendi" izi birakmasin)
if(-not $YalnizVitrin){
  $gunKartDir = Join-Path $here ("kartlar\" + $Gun)
  New-Item -ItemType Directory -Force $gunKartDir | Out-Null
  # DIKKAT: bos dizinin ConvertTo-Json ciktisi BOS STRING'dir (0 baytlik dosya).
  # Gecerli JSON yaz - yoksa dosya hem okunamaz hem "islendi" yalani soyler.
  $kartJson = if($kartlar.Count -eq 0){ '[]' } else { $kartlar | ConvertTo-Json -Depth 8 }
  $kartJson | Out-File (Join-Path $gunKartDir "kartlar.json") -Encoding utf8
}

# ============================================================================
#  VITRIN HAVUZU (16.08.2026 - Cem: "burda veri gelmiyor mu?")
#
#  ESKI DAVRANIS: vitrin YALNIZ o gunun kartlarini basiyordu. RG'nin sakin
#  gectigi her donemde sayfa "0 duzenleme" ile bombos kaliyordu - oysa
#  arsivde 85 dolu gunde 182 kart birikmisti. Veri vardi, sayfa gostermiyordu.
#
#  YENI: vitrin BIRIKMIS HAVUZUN en yeni N kartini gosterir. Gunluk arsiv
#  sayfasi (arsiv/kartlar-<gun>.html) degismez - o hala o gunun kaydidir.
# ============================================================================
$VITRIN_ADET = 12
$havuz = New-Object System.Collections.Generic.List[object]
foreach($gd in (Get-ChildItem (Join-Path $here 'kartlar') -Directory -ErrorAction SilentlyContinue)){
  $jy = Join-Path $gd.FullName 'kartlar.json'
  if(-not (Test-Path $jy)){ continue }
  $ham = (Get-Content $jy -Raw -Encoding UTF8)
  if([string]::IsNullOrWhiteSpace($ham)){ continue }
  $obj = $null
  try { $obj = $ham | ConvertFrom-Json } catch { continue }
  $tarih = [datetime]'1900-01-01'
  try { $tarih = [datetime]::ParseExact($gd.Name,'dd-MM-yyyy',$null) } catch { continue }
  foreach($kk in @($obj)){
    if($null -eq $kk -or -not $kk.baslik_sade){ continue }
    Add-Member -InputObject $kk -NotePropertyName '_gun' -NotePropertyValue ($gd.Name -replace '-','.') -Force
    Add-Member -InputObject $kk -NotePropertyName '_tarih' -NotePropertyValue $tarih -Force
    [void]$havuz.Add($kk)
  }
}
$vitrin = @($havuz | Sort-Object -Property _tarih -Descending | Select-Object -First $VITRIN_ADET)
Write-Host ("Vitrin havuzu: {0} kart birikmis, en yeni {1} tanesi sayfaya konacak." -f $havuz.Count, $vitrin.Count)

# radar-app panosunun GTIP eslesmesi icin sabit "guncel kartlar" (yalniz GTIP'li kartlar, trim)
# FIRSAT ROZETI (#63, 30.07): yapilandirma/af kaliplari karti FIRSAT yapar -
# kartlar.html'de kehribar rozet, beslemede firsat alani (panel/vitrin okur).
$firsatKaliplari = @('yeniden yapıland','yapılandırılması','matrah artırım','vergi aff','prim aff','borç aff','taksitlendir','alacakların yapıland')
function KartFirsatMi($kk){
  $m = ("$($kk.baslik_sade) $($kk.ne_oldu)").ToLowerInvariant()
  foreach($fk in $firsatKaliplari){ if($m.Contains($fk)){ return $true } }
  return $false
}
# 02.08 DUZELTME (Cem: "son hap kart 11.07 gorunuyor"): besleme YALNIZ GTIP'li
# kartlari aliyordu. Site artik yalniz gumruk sitesi degil - VUK tebligi, SGK,
# muhasebe kartlari GTIP tasimaz ve besleme onlari gormuyordu. Sonuc: 22 gundur
# kart uretildigi halde ana sayfa 11.07'de takili kaldi. Artik TUM kartlar
# besleniyor; GTIP'liler basa aliniyor (radar-app eslemesi onlari kullanir,
# gtip alani bos olani kendisi eler).
# 17.08 - Cem: "eski hali kanun buymus yeni hali bu oldu gibi guzel bir
# aciklama yapmamiz lazim." Olculdu: motor eski_yeni / kesin_kiymetler /
# degistirilen_teblig alanlarini ZATEN uretiyordu ama BU SATIR onlari
# dusuruyordu - siteye 6 alan gidiyor, gerisi cope. Yani "eski -> yeni"
# verisi vardi, ana sayfa hic gormemisti. Alanlar artik besleniyor.
# Bos alan TASINMAZ: eski_yeni yoksa anahtar hic yazilmaz (on yuzler
# "alan var ama bos" ile "alan yok"u ayirt etmek zorunda kalmasin).
$guncelKartlar = @(@($kartlar | ForEach-Object {
  $o = [ordered]@{ baslik=$_.baslik_sade; ne_oldu=$_.ne_oldu; gtip=@($_.gtip_kodlari); url=$_.kaynak; etki=($_.etki.yon); firsat=(KartFirsatMi $_) }
  # Besleme de AYNI ayiklamayi kullanir - ana sayfa ile kart sayfasi ayni seyi
  # gostersin diye. Gizlenen sayisi da tasinir (on yuz "+N daha" yazabilsin).
  $sr = SeritHazirla $_.eski_yeni
  if(@($sr.satirlar).Count){
    $o["eski_yeni"] = @($sr.satirlar)
    if($sr.gizli -gt 0){ $o["eski_yeni_gizli"] = $sr.gizli }
  }
  if($_.degistirilen_teblig){ $o["degistirilen_teblig"] = $_.degistirilen_teblig }
  # 17.08 - deterministik yapidan gelen ucu de siteye tasinir
  if($_.teblig_no){ $o["teblig_no"] = $_.teblig_no }
  $dm = @($_.degisen_maddeler | Where-Object { "$_".Trim() })
  if($dm.Count){ $o["degisen_maddeler"] = $dm }
  if("$($_.yururluk)".Trim()){ $o["yururluk"] = $_.yururluk }
  if($_.onceki_belge){ $o["onceki_belge"] = $_.onceki_belge }
  if($_.eski_karsilastirma){ $o["eski_karsilastirma"] = $_.eski_karsilastirma }
  $kymt = @(DoluKiymetler $_.kesin_kiymetler)
  if($kymt.Count){ $o["kiymetler"] = $_.kesin_kiymetler }
  if($_.ne_yapmali){ $o["ne_yapmali"] = $_.ne_yapmali }
  $o
} | Sort-Object -Property @{ Expression = { @($_.gtip).Count -gt 0 }; Descending = $true }))
$guncelObj = [ordered]@{ gun=$Gun; guncelleme=("Günün hap kartları — " + $TarihNokta); kartlar=$guncelKartlar }
$guncelYol = Join-Path $kok "veri\kartlar-guncel.json"
# 30.07 SIFIR-KART FRENI: 0 kartlik kosu (sakin RG gunu YA DA API dususu -
# ikisi ayirt edilemez) mevcut beslemeyi EZMEZ. Bugun 429 altindaki telafi
# kosusu 24 kartlik panel beslemesini bos kabukla silmisti; panel/uyari
# eslesmeleri sessizce koreldi. Eski besleme taze kart gelene kadar yasar.
# 01.08 ESKI-GUN FRENI: telafi kosusu eski bir gunu islerken (or. Mart)
# guncel beslemeyi o gune GERILETIYORDU - ana sayfa "gunun karti" Mart'a dondu.
# Mevcut beslemenin gunu islenen gunden YENIyse dosyaya dokunulmaz.
$eskiGun = $null
if(Test-Path $guncelYol){
  try { $eskiGun = [datetime]::ParseExact((Get-Content $guncelYol -Raw -Encoding UTF8 | ConvertFrom-Json).gun, 'dd-MM-yyyy', $null) } catch { $eskiGun = $null }
}
$buGun = $null; try { $buGun = [datetime]::ParseExact($Gun, 'dd-MM-yyyy', $null) } catch {}
if(@($guncelKartlar).Count -eq 0 -and (Test-Path $guncelYol)){
  Write-Host "0 kart uretildi - veri/kartlar-guncel.json KORUNDU (onceki besleme ezilmedi)." -ForegroundColor Yellow
} elseif($eskiGun -and $buGun -and $buGun -lt $eskiGun){
  Write-Host ("Telafi eski gun ({0}) isledi - guncel besleme {1} gununde KORUNDU (geriletilmedi)." -f $Gun, $eskiGun.ToString('dd-MM-yyyy')) -ForegroundColor Yellow
} else {
  [System.IO.File]::WriteAllText($guncelYol, ($guncelObj | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($true)))
}

# ---- kartlar.html + gunluk arsiv kopyasi ------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Günün Hap Kartları - $TarihNokta | Tetikte</title>")
[void]$s.AppendLine('<meta name="description" content="Bugünün Resmî Gazete değişiklikleri hap bilgi kartları hâlinde: ne oldu, kimi ilgilendiriyor, ne yapmalı.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#ffc24b;--grad:linear-gradient(135deg,#f5a524 0%,#ffc24b 100%);--red:#ff6b5e;--amber:#ffc24b;--green:#3ddc97}')
[void]$s.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}')
[void]$s.AppendLine('a{color:var(--accent2)}.wrap{max-width:840px;margin:0 auto;padding:24px 18px 70px}')
[void]$s.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim);flex-wrap:wrap}.top a{color:var(--muted);text-decoration:none;font-weight:600}.top a:hover{color:var(--ink)}')
[void]$s.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$s.AppendLine('h1{font-size:clamp(24px,4.5vw,32px);letter-spacing:-.9px;margin:4px 0 4px;font-weight:800}')
[void]$s.AppendLine('.alt{color:var(--muted);font-size:13.5px;margin-bottom:8px}')
[void]$s.AppendLine('.uyari{font-size:12px;color:var(--dim);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px 13px;margin:14px 0 24px}')
[void]$s.AppendLine('.kart{background:var(--panel);border:1px solid var(--line);border-left:5px solid var(--red);border-radius:14px;padding:18px 20px;margin-bottom:14px}')
[void]$s.AppendLine('.kart .etiket{font-size:10.5px;font-weight:800;letter-spacing:1px;color:var(--red)}')
[void]$s.AppendLine('.kart h3{margin:6px 0 8px;font-size:16.5px;letter-spacing:-.3px}')
[void]$s.AppendLine('.kart p{margin:6px 0;font-size:13.5px;color:var(--muted)}.kart p b{color:var(--ink)}')
[void]$s.AppendLine('.gtip{display:inline-block;background:rgba(255,194,75,.12);color:var(--accent2);border-radius:7px;padding:2px 8px;font-size:11.5px;margin:2px 4px 2px 0;font-variant-numeric:tabular-nums}')
[void]$s.AppendLine('.kiymet{font-size:12.5px;color:var(--muted);margin:2px 0;font-variant-numeric:tabular-nums}.kiymet b{color:var(--ink)}')
[void]$s.AppendLine('.kiyas{background:rgba(61,220,151,.09);border:1px solid rgba(61,220,151,.3);color:var(--green);border-radius:9px;padding:8px 12px;font-size:12.5px;margin:8px 0}')
[void]$s.AppendLine('.meta{font-size:11px;color:var(--dim);margin-top:10px}.meta a{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(245,165,36,.16),rgba(255,194,75,.07)),var(--panel);border:1px solid rgba(255,194,75,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(245,165,36,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">T</span><a href="index.html">Tetikte</a> · <a href="gtip.html">GTİP Kontrolü</a> · <a href="destekler.html">Destek Radarı</a> · <a href="radar.html">Bugün RG''de</a> · Günün Kartları · <a href="arsiv/index.html">Arşiv</a></div>')
[void]$s.AppendLine("<h1>Günün Hap Kartları</h1>")
$enYeniGun = if($vitrin.Count){ $vitrin[0]._gun } else { $TarihNokta }
# 18.08: BASLIK ISLENEN GUNE GORE YAZILMAZ. Telafi kosusunda gunler yeniden
# eskiye islenir ve EN SON islenen eski gun basliga "Bugün (01.05.2026) 1 yeni
# düzenleme" diye sizdi (canlida goruldu; kart listesi dogruydu, yalniz baslik
# yalan soyluyordu). Baslik artik GERCEK bugune (TR saati) ve havuza gore
# kurulur - islenme sirasi ne olursa olsun ayni cikar. CI Linux'ta tz kimligi
# 'Europe/Istanbul', Windows'ta 'Turkey Standard Time'; ikisi de denenir.
$tzTR = $null
foreach($tzAd in @('Europe/Istanbul','Turkey Standard Time')){ try { $tzTR = [TimeZoneInfo]::FindSystemTimeZoneById($tzAd); break } catch {} }
$gercekBugun = if($tzTR){ [TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow,$tzTR).ToString('dd.MM.yyyy') } else { (Get-Date).ToString('dd.MM.yyyy') }
$bugunkuSayi = @($vitrin | Where-Object { $_._gun -eq $gercekBugun }).Count
$bugunMetni = if($bugunkuSayi -gt 0){ "Bugün ($gercekBugun) $bugunkuSayi yeni düzenleme." } else { "Bugün ($gercekBugun) kart gerektiren yeni düzenleme çıkmadı." }
$vitrinUst = "<div class='alt'>$bugunMetni Aşağıda son <b>$($vitrin.Count)</b> kart — en yenisi $enYeniGun tarihli, 30 saniyede okunur.</div>"
$arsivUst  = "<div class='alt'>$TarihNokta tarihli Resmî Gazete'de $($kartlar.Count) düzenleme — o günün kaydı.</div>"
[void]$s.AppendLine($vitrinUst)
# nobet damgasi: robot her gun tarar; kart cikmasa da "son tarama" tarihi canli gorunur (veri/kart-durum.json'u kartlar.yml yazar)
[void]$s.AppendLine('<div id="nobet" style="display:none;font-size:12.5px;color:var(--green,#3ddc97);background:rgba(61,220,151,.08);border:1px solid rgba(61,220,151,.3);border-radius:10px;padding:9px 13px;margin:10px 0 0"></div>')
# 17.08 SESSIZ GUN DURUSTLUGU (Cem: "en son 14.08 var bugun 17.08").
# Eskiden sakin gunde sayfa hicbir sey soylemiyordu; ziyaretci gunler oncesine
# ait karti gorup "bu site durmus" saniyordu. Oysa robot her gun kosuyordu ve
# o gunlerde RG'de gercekten ilgili duzenleme yoktu. Nobetin GORUNMESI de
# nobetin kendisi kadar onemli: artik o gun RG'de KAC duzenleme vardi ve NEDEN
# kart cikmadigi yaziliyor (rg-gun-durum.json, rg-indir.ps1 yazar).
[void]$s.AppendLine('<script>fetch("veri/kart-durum.json?"+Date.now()).then(r=>r.json()).then(function(d){var e=document.getElementById("nobet");e.style.display="block";e.innerHTML="🟢 Nöbet sürüyor — Resmî Gazete son tarama: <b>"+d.sonTarama+"</b>. Kart gerektiren yeni düzenleme çıkmadığı günlerde liste değişmez.";return fetch("veri/rg-gun-durum.json?"+Date.now()).then(function(r){return r.json()}).then(function(g){if(g&&g.sebep){e.innerHTML+="<br><span style=\"color:var(--dim)\">"+g.gun+" — "+g.sebep+"</span>";}}).catch(function(){});}).catch(function(){});</script>')
[void]$s.AppendLine('<div class="uyari">Kartlar, ekibimizin geliştirdiği çift kontrollü okuma sistemiyle doğrudan Resmî Gazete metninden üretilir; her değer <b>iki bağımsız okuma + anlaşmazlıkta üçüncü kontrol</b> ile doğrulanır. Güvenle doğrulanamayan değer karta yazılmaz. Bilgilendirme amaçlıdır — işlem öncesi kaynak tebliği açın.</div>')
# ============================================================================
#  KART BLOGU URETICISI (16.08 - iki sayfa ayrildi)
#  Vitrin (kartlar.html) BIRIKMIS HAVUZU gosterir; gunluk arsiv sayfasi ise
#  YALNIZ O GUNUN kartlarini. Ikisi ayni cizimi kullandigi icin kart uretimi
#  fonksiyona alindi - yoksa arsiv de havuzu basiyordu (16.08'de bir kez oldu).
# ============================================================================
function KartBloguHtml($liste){
  $b = New-Object System.Text.StringBuilder
  foreach($k in @($liste)){
  $s = $b   # kart govdesi $s'e yazar - yerel StringBuilder'a yonlendir
  [void]$s.AppendLine('<div class="kart">')
  # Havuzdan gelen kart hangi gune ait - okuyucu tarihi gormeden guvenemez
  $gunEtiketi = if($k._gun){ " <span style='color:var(--dim);font-weight:400'>· $($k._gun)</span>" } else { "" }
  if(KartFirsatMi $k){
    [void]$s.AppendLine("<div class='etiket' style='color:var(--amber)'>★ FIRSAT PENCERESİ — süreyi kaçırma$gunEtiketi</div>")
  } else {
    [void]$s.AppendLine("<div class='etiket'>■ MEVZUAT DEĞİŞİKLİĞİ$gunEtiketi</div>")
  }
  [void]$s.AppendLine("<h3>$($k.baslik_sade)</h3>")
  [void]$s.AppendLine("<p><b>Ne oldu:</b> $($k.ne_oldu)</p>")
  # 17.08: eskiden yalnizca "Neyi degistiriyor: 2023/5" yaziyordu ve tebligin
  # KENDI numarasi (2026/11) hicbir yerde gecmiyordu - okuyan hangi belgeyi
  # arayacagini bilmiyordu. Ikisi birlikte yazilir.
  if($k.degistirilen_teblig -or $k.teblig_no){
    $nd = if($k.teblig_no -and $k.degistirilen_teblig){
            "<b>$($k.teblig_no)</b> sayılı Tebliğ, <b>$($k.degistirilen_teblig)</b> sayılı Tebliği değiştiriyor"
          } elseif($k.teblig_no){ "<b>$($k.teblig_no)</b> sayılı Tebliğ" }
          else { "$($k.degistirilen_teblig) sayılı Tebliği değiştiriyor" }
    [void]$s.AppendLine("<p><b>Hangi tebliğ:</b> $nd</p>")
  }
  # Hangi maddeler eklendi/kaldirildi/bastan yazildi - "yeni maddelerle" gibi
  # genel ifadenin yerine numaralar.
  $degMad = @($k.degisen_maddeler | Where-Object { "$_".Trim() })
  if($degMad.Count){
    [void]$s.AppendLine("<p><b>Neler değişti:</b></p>")
    foreach($dm in $degMad){ [void]$s.AppendLine("<div class='kiymet'>• $dm</div>") }
  }
  # 17.08: ham liste degil AYIKLANMIS liste basilir (bicimsel satirlar duser,
  # mukerrer cift birlesir, onemli one gelir, en fazla 5 satir). Ayiklamadan
  # sonra hicbir sey kalmadiysa baslik da basilmaz.
  $serit = SeritHazirla $k.eski_yeni
  if(@($serit.satirlar).Count){
    # ETIKET DOGRU OLMALI: deterministik satirlar cift okumadan GECMEDI, tebligin
    # kendi cumlesinden ("X ibaresi Y seklinde degistirilmistir") birebir alindi.
    # Onlara "cift okumayla dogrulanmis" demek kendi arayuzumuzde yanlis beyandir.
    $metinSatir = @($k.eski_yeni | Where-Object { $_.kaynak -eq 'metin' }).Count
    $tumSatir   = @($k.eski_yeni | Where-Object { $_ -and $_.eski -and $_.yeni }).Count
    $eyEtiket = if($k.eski_karsilastirma){ "($($k.eski_karsilastirma) tarihli RG'deki eski metinle karşılaştırıldı)" }
                elseif($metinSatir -and $metinSatir -eq $tumSatir){ "(tebliğ metninden birebir alındı)" }
                elseif($metinSatir){ "(tebliğ metninden; bir kısmı çift okumayla doğrulandı)" }
                else { "(tebliğ metninden, çift okumayla doğrulanmış)" }
    [void]$s.AppendLine("<p><b>Eskiden → Şimdi</b> <span style='font-size:11px;color:var(--dim)'>$eyEtiket</span></p>")
    foreach($ey in @($serit.satirlar)){
      # YUZDE BURADA HESAPLANIR, MODELE SORULMAZ. Iki taraf da taninan bir
      # BIRIM tasimiyorsa (or. "(II/C/6.3.) bolumu" gibi atif) yuzde YAZILMAZ -
      # satir yine gosterilir. Birim degisiyorsa da yazilmaz (5 TL vs 5 USD
      # karsilastirmasi anlamsizdir).
      $oran = ''
      $ea = KiymetSayi $ey.eski; $yb = KiymetSayi $ey.yeni
      if($null -ne $ea -and $null -ne $yb -and $ea -ne 0 -and (KiymetBirim $ey.eski) -eq (KiymetBirim $ey.yeni)){
        $o = [math]::Round((($yb - $ea) / [math]::Abs($ea)) * 100)
        if($o -ne 0){
          $ok = if($o -gt 0){ '▲' } else { '▼' }
          $renk = if($o -gt 0){ 'var(--red)' } else { 'var(--green)' }
          $oran = " <b style='color:$renk'>$ok%$([math]::Abs($o))</b>"
        }
      }
      # Ayni cift metinde birden cok yerde geciyorsa TEK satir + kac yerde.
      # (Sigorta kartinda "Müsteşarlığa -> Kuruma" 17 satir basiliyordu.)
      $tekrarNot = if($ey.tekrar -gt 1){ " <span style='color:var(--dim);font-size:11px'>(metinde $($ey.tekrar) yerde)</span>" } else { "" }
      [void]$s.AppendLine("<div class='kiymet'>• $($ey.konu): <span style='color:var(--dim);text-decoration:line-through'>$($ey.eski)</span> → <b>$($ey.yeni)</b>$oran$tekrarNot</div>")
    }
    # Gizlenen satir SESSIZCE dusurulmez - kac tane oldugu yazilir.
    if($serit.gizli -gt 0){
      [void]$s.AppendLine("<div class='kiymet' style='color:var(--dim)'>+$($serit.gizli) değişiklik daha (kelime/atıf düzeltmesi) — tamamı için kaynak tebliğe bakın</div>")
    }
  }
  # Eski deger metinde yoksa UYDURULMAZ - onceki resmi belgenin linki verilir.
  if($k.onceki_belge){
    [void]$s.AppendLine("<div class='kiymet' style='color:var(--dim)'>Bu tebliğin bir önceki hâli: <a href='$($k.onceki_belge.url)' target='_blank' rel='noopener'>$($k.onceki_belge.tarih) tarihli Resmî Gazete</a> (Tebliğ $($k.onceki_belge.teblig_no))</div>")
  }
  if($k.urun_tanimi){ [void]$s.AppendLine("<p><b>Ürün:</b> $($k.urun_tanimi)</p>") }
  # 17.08 BOS BASLIK KUSURU: eskiden kosul "@($k.gtip_kodlari).Count" idi ve
  # PowerShell'de @($null).Count = 1 dondurur (null'i saran @() TEK ELEMANLI
  # dizi yapar). Kosul dogru saniliyor, dongu bir kez donuyor ve $_ null oldugu
  # icin BOS bir cip basiliyordu:  <p><b>GTİP:</b><br><span class='gtip'></span></p>
  # kartlar.html'de uc kartta birden vardi (GTIP'i olmayan teblig kartlari).
  # Cem 17.08: kart yarim gorunuyor. Cozum: SAYMADAN ONCE SUZ.
  $gtipDolu = @($k.gtip_kodlari | Where-Object { "$_".Trim() })
  if($gtipDolu.Count){
    $chips = ($gtipDolu | ForEach-Object { "<span class='gtip'>$_</span>" }) -join ""
    [void]$s.AppendLine("<p><b>GTİP:</b><br>$chips</p>")
  }
  # kesin_kiymetler havuzdan hashtable OLARAK DA PSCustomObject OLARAK DA
  # gelebiliyor (JSON'a yazilip geri okununca tur degisiyor); .Count ikisinde
  # ayni davranmaz. Degeri DOLU alanlar sayilir - bos nesne baslik bastirmaz.
  $kiymetCift = @(DoluKiymetler $k.kesin_kiymetler)
  if($kiymetCift.Count){
    [void]$s.AppendLine("<p><b>Birim kıymetler (çapraz doğrulanmış):</b></p>")
    foreach($c in $kiymetCift){ [void]$s.AppendLine("<div class='kiymet'>$($c.kod) → <b>$($c.deger)</b></div>") }
  }
  foreach($ky in @($k.kiyaslar)){ [void]$s.AppendLine("<div class='kiyas'>📊 Eskiden → Şimdi (kayıt defterimizden) — $ky</div>") }
  [void]$s.AppendLine("<p><b>Kimi ilgilendirir:</b> $($k.kimi_ilgilendirir)</p>")
  [void]$s.AppendLine("<p><b>Ne yapmalısın:</b> $($k.ne_yapmali)</p>")
  # Yururluk BOS ise alan hic basilmaz. Eskiden bos kalinca yerine
  # "Kaynak tebliğdeki yürürlük maddesine bakın" yaziliyordu - okuyucuyu geri
  # gondermek, nobet tutmanin tam tersi. Bilmiyorsak susariz.
  if("$($k.yururluk)".Trim()){ [void]$s.AppendLine("<p><b>Yürürlük:</b> $($k.yururluk)</p>") }
  if($k.etki){
    $renk = switch(($k.etki.yon -replace "İ","i").ToLowerInvariant()){
      "ithalatci aleyhine" { "var(--amber)" }
      "ithalatci lehine"   { "var(--green)" }
      default              { "var(--dim)" }
    }
    [void]$s.AppendLine("<div style='border:1px solid $renk;border-radius:10px;padding:10px 13px;margin:9px 0;font-size:12.5px;color:var(--muted)'><b style='color:$renk'>Ne anlama geliyor (yorum · $($k.etki.yon)):</b> $($k.etki.aciklama)</div>")
  }
  [void]$s.AppendLine("<div class='meta'><a href='$($k.kaynak)' target='_blank' rel='noopener'>Kaynak tebliğ →</a></div>")
  [void]$s.AppendLine('</div>')
  }
  return $b.ToString()
}
# Vitrin: havuzun en yenileri. Arsiv sayfasi asagida GUNUN kartlariyla uretilir.
$vitrinBlok = KartBloguHtml $vitrin
[void]$s.AppendLine($vitrinBlok)
[void]$s.AppendLine('<div class="cta"><h3>Bu kartlardan hangisi SENİN kodlarına dokunuyor?</h3>')
[void]$s.AppendLine('<p>Yakında: GTİP kodlarını kaydet, sadece seni etkileyen kart cebine gelsin. Şimdilik: firmanın tüm yükümlülüklerini 3 dakikada gör.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Tetikte hap bilgi motoru · Çift geçiş + hakem model çapraz kontrolü · Bilgilendirme amaçlıdır, kaynak tebliğ esastır.</div>")
[void]$s.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script><script src="menu.js" defer></script></div></body></html>')
$kartlarHtml = Join-Path $kok "kartlar.html"
# ============================================================================
#  VITRIN KORUMASI (16.08.2026)
#  Sayfadaki nobet rozeti aynen soyle diyor: "Kart gerektiren yeni duzenleme
#  cikmadigi gunlerde LISTE DEGISMEZ." Kod bu sozu tutmuyordu: sakin gunde
#  0 kartlik sayfa yazilip 05.08'den beri duran kartlar vitrinden siliniyordu.
#  Kullanicinin gordugu "0 duzenleme + bombos sayfa" bundandi.
#  Artik SIFIR kart varsa vitrin YENIDEN YAZILMAZ; son iyi hal durur, tarih
#  bilgisini rozet (veri/kart-durum.json) tasir. Gunluk arsiv kopyasi yine
#  yazilir - o gunun "sakin gecti" kaydi tarihsel olarak dogrudur.
# ============================================================================
#  16.08 GUNCELLEME: olcut artik gunun kart sayisi DEGIL, vitrin havuzudur.
#  Sakin gunde de sayfa yazilir (havuzdaki son 12 kart durur, tarih satiri
#  tazelenir); yalniz havuz TAMAMEN bossa dokunulmaz.
if($vitrin.Count -eq 0){
  Write-Host "VITRIN KORUNDU: havuzda hic kart yok - kartlar.html'e dokunulmadi (son iyi hal duruyor)."
} else {
  [System.IO.File]::WriteAllText($kartlarHtml, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))
}

# gunluk arsiv kopyasi (goreli linkler icin <base> eklenir)
$arsivDirSite = Join-Path $kok "arsiv"
New-Item -ItemType Directory -Force $arsivDirSite | Out-Null
# ARSIV SAYFASI = O GUNUN KAYDI (vitrin havuzu DEGIL).
# Vitrin blogu gunun bloguyla, vitrin ust yazisi gun yazisiyla degistirilir.
# Kart cikmayan gune arsiv sayfasi ACILMAZ - bos kayit arsivi kirletir.
if($kartlar.Count -gt 0 -and -not $YalnizVitrin){
  $arsivHtml = $s.ToString().Replace($vitrinBlok, (KartBloguHtml $kartlar)).Replace($vitrinUst, $arsivUst).Replace('<head>','<head><base href="../">')
  [System.IO.File]::WriteAllText((Join-Path $arsivDirSite ("kartlar-" + $Gun + ".html")), $arsivHtml, (New-Object System.Text.UTF8Encoding($false)))
} else {
  Write-Host ("Arsiv sayfasi yazilmadi ({0}) - o gun kart yok ya da yalniz-vitrin modu." -f $Gun)
}

# arsiv index'ini yeniden kur
$gunler = Get-ChildItem $arsivDirSite -Filter "kartlar-*.html" | ForEach-Object {
  $g = $_.BaseName -replace "^kartlar-",""
  $pp = $g.Split("-")
  [pscustomobject]@{ dosya=$_.Name; gun=$g; sirala=("{0}{1}{2}" -f $pp[2],$pp[1],$pp[0]); goster=("{0}.{1}.{2}" -f $pp[0],$pp[1],$pp[2]) }
} | Sort-Object sirala -Descending
$a = New-Object System.Text.StringBuilder
[void]$a.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><base href="../">')
[void]$a.AppendLine('<title>Kart Arşivi | Tetikte</title><link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$a.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#ffc24b;--grad:linear-gradient(135deg,#f5a524 0%,#ffc24b 100%)}')
[void]$a.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.7}')
[void]$a.AppendLine('a{color:var(--accent2)}.wrap{max-width:720px;margin:0 auto;padding:24px 18px 70px}')
[void]$a.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}')
[void]$a.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$a.AppendLine('h1{font-size:26px;letter-spacing:-.8px;font-weight:800}')
[void]$a.AppendLine('.g{display:block;background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px 18px;margin-bottom:10px;color:var(--ink);text-decoration:none;font-weight:600}.g:hover{border-color:rgba(255,194,75,.4)}')
[void]$a.AppendLine('.g span{color:var(--dim);font-weight:400;font-size:12.5px}')
[void]$a.AppendLine('</style></head><body><div class="wrap">')
[void]$a.AppendLine('<div class="top"><span class="logo">T</span><a href="index.html">Tetikte</a> · <a href="kartlar.html">Günün Kartları</a> · Arşiv</div>')
[void]$a.AppendLine('<h1>Hap Kart Arşivi</h1><p style="color:var(--muted);font-size:14px">Gün gün, Resmî Gazete değişikliklerinin hap kartları.</p>')
foreach($g in $gunler){ [void]$a.AppendLine("<a class='g' href='arsiv/$($g.dosya)'>$($g.goster) <span>— günün kartları</span></a>") }
[void]$a.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script><script src="menu.js" defer></script></div></body></html>')
[System.IO.File]::WriteAllText((Join-Path $arsivDirSite "index.html"), $a.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# 17.08 ONBELLEKLI MALIYET. Onbellekten OKUNAN jeton taban girdi fiyatinin
# %10'una, onbellege YAZILAN %125'ine faturalanir. Eski hesap her girdi jetonunu
# tam fiyattan sayiyordu; cift gecis ayni istemi 2-4 kez gonderdigi icin bu artik
# maliyeti FAZLA gosterirdi. Ucu ayri ayri fiyatlanir.
$tamGirdi = $topGirdi - $script:onbYaz - $script:onbOku
if($tamGirdi -lt 0){ $tamGirdi = 0 }
$maliyet = ($tamGirdi/1000000.0)*1.0 + ($script:onbYaz/1000000.0)*1.25 + ($script:onbOku/1000000.0)*0.10 `
         + ($topCikti/1000000.0)*5.0 + ($hakemGirdi/1000000.0)*3.0 + ($hakemCikti/1000000.0)*15.0
""
"TOPLU URETIM BITTI (v0.2)"
"Kart: $($kartlar.Count) | Hatali: $hatali | Hakem devreye girdi: $hakemSayisi kart"
"Ana model token: $topGirdi/$topCikti | Hakem token: $hakemGirdi/$hakemCikti"
# DOGRULAMA: onbellek isabet ettiyse okuma > 0 olur. Sifir kalirsa isaret bir
# yere oturmamistir - en sik sebep on ekin modelin minimum esiginin altinda
# kalmasi (Haiku 4.5'te 4.096 jeton).
if($script:onbOku -gt 0 -or $script:onbYaz -gt 0){
  $oran = if(($script:onbOku + $tamGirdi) -gt 0){ [math]::Round(100.0*$script:onbOku/($script:onbOku + $tamGirdi + $script:onbYaz),1) } else { 0 }
  "Onbellek: yazilan $($script:onbYaz) | OKUNAN $($script:onbOku) jeton (girdinin %$oran'i) - CALISIYOR"
} else {
  "Onbellek: 0 - ISABET YOK. On ek modelin minimum esiginin altinda olabilir (Haiku 4.5: 4.096 jeton) ya da yedek hatta (OpenRouter) kosuldu."
}
("Toplam maliyet: ~{0:N3} USD" -f $maliyet)
"Hafizadaki kod sayisi: $($hafiza.Keys.Count)"
"Sayfalar: kartlar.html + arsiv/kartlar-$Gun.html + arsiv/index.html"

# 17.08: ACIK CIKIS KODU. Betik basariyla bittiginde $LASTEXITCODE, icerde
# cagrilan DIS komutlardan (curl/qpdf) devralinmis eski bir deger tasiyabiliyor;
# kartlar.yml bunu "bu gun patladi" sanip 14.08'i basarisiz listesine yazdi -
# oysa o gun 1 kart URETILMISTI. Basari acikca bildirilir.
exit 0