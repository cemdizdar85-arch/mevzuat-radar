# ============================================================================
#  KART TOPLU v0.2 - Hap Bilgi Motoru
#  Yenilikler: kod bazinda yapilandirilmis kiymet + Sonnet hakem (anlasmazlikta)
#  + kalici kiymet hafizasi (kiyas: "onceki kayit X -> yeni Y") + gunluk arsiv.
#  Kullanim: powershell -ExecutionPolicy Bypass -File kart-toplu.ps1 -Gun 11-07-2026
# ============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Gun,
  [string]$Model = "claude-haiku-4-5",
  [string]$HakemModel = "claude-sonnet-5"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# pwsh 7 / .NET Core: windows-1254 icin kod sayfasi saglayicisini kaydet (PS5.1'de zaten var)
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok = Split-Path -Parent $here
# Anahtar: CI'da GitHub secret (env), yerelde repo disi dosya
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ $key = (Get-Content "C:\Users\cemdi\.mevzuat-radar-api" -Raw).Trim() }
$arsivTeblig = Join-Path $here ("arsiv\" + $Gun)
$parcalar = $Gun.Split("-")
$tabanUrl = "https://www.resmigazete.gov.tr/eskiler/$($parcalar[2])/$($parcalar[1])/"
$TarihNokta = "$($parcalar[0]).$($parcalar[1]).$($parcalar[2])"

function NormD([string]$s){ if(-not $s){ return "" }; return (($s -replace "\s+"," ").Trim().ToLowerInvariant()) }

# ---- kalici kiymet hafizasi -------------------------------------------------
$hafizaDir = Join-Path $here "hafiza"
New-Item -ItemType Directory -Force $hafizaDir | Out-Null
$hafizaYol = Join-Path $hafizaDir "kiymetler.json"
$hafiza = @{}
if(Test-Path $hafizaYol){
  $j = Get-Content $hafizaYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $j.PSObject.Properties){ $hafiza[$p.Name] = @($p.Value) }
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
D) Turkce imla KUSURSUZ: "kıymet", "tebliğ", "yürürlük", "güncellemiştir degil guncelledi". Yazim hatasi tek basina karti coper.
E) baslik_sade: iyi bir ekonomi muhabirinin atacagi baslik. Olgusal, 8-14 kelime, urun grubunu soyler.
F) ne_yapmali: genel gecer tavsiye degil, SOMUT is: "Subat sevkiyatlarinin proforma bedellerini yeni esikle karsilastirin" gibi. Emir kipi dogal: "kontrol edin", "hazirlayin".
G) kimi_ilgilendirir: sektoru/rolu isimlendir ("seramik ithal eden insaat malzemecileri" gibi), "ilgili firmalar" deme.

JSON semasi:
{"baslik_sade":"tek cumle, olgusal","ne_oldu":"1-2 cumle","degistirilen_teblig":"degistirilen ana teblig no/adi veya bos","eski_rg":"GG.AA.YYYY veya bos","eski_yeni":[{"konu":"degisen kalem","eski":"kaynaktan eski hal","yeni":"kaynaktan yeni hal"}],"gtip_kodlari":["tum kodlar"],"urun_tanimi":"esya grubu","kimi_ilgilendirir":"kim","ne_yapmali":"somut adim","yururluk":"kalipli","birim_kiymetler":[{"gtip":"kod","deger":"or: 1.000 ABD Dolari/Ton"}],"etki":{"yon":"kalipli","aciklama":"1-2 cumle yorum"},"guven_notu":"emin olamadiklarin"}

TEBLIG METNI:
"@

function ApiCagri([string]$model, [array]$icerik, [int]$maxTok){
  $govde = @{ model = $model; max_tokens = $maxTok; messages = @(@{ role="user"; content=$icerik }) } | ConvertTo-Json -Depth 10
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 240
  $c = $r.content[0].text.Trim()
  # SADECE PS 5.1: Invoke-RestMethod UTF-8'i Latin-1 sanar -> geri cevir. pwsh 7 dogru cozer; orada bu donusum metni BOZAR.
  if($PSVersionTable.PSVersion.Major -le 5){
    $c = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($c))
  }
  return @{ metin = $c; girdi = $r.usage.input_tokens; cikti = $r.usage.output_tokens }
}

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
      $bi = $wcI.DownloadData($iu)
      $mi = if($srcE -match "\.png$"){ "image/png" } else { "image/jpeg" }
      $gorsellerE += @{ type="image"; source=@{ type="base64"; media_type=$mi; data=[Convert]::ToBase64String($bi) } }
    } catch {}
  }
  return @{ metin = $metinE; gorseller = $gorsellerE; url = $eskiUrl }
}

$dosyalar = Get-ChildItem $arsivTeblig -Filter "*.htm" | Sort-Object Name
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
        $b = $wc.DownloadData($imgUrl)
        $mime = if($src -match "\.png$"){ "image/png" } else { "image/jpeg" }
        $gorseller += @{ type="image"; source=@{ type="base64"; media_type=$mime; data=[Convert]::ToBase64String($b) } }
      } catch {}
    }
    $icerikTam = @() + $gorseller + @(@{ type="text"; text=($istemSablon + $metin) })

    # --- cift gecis (uzun tablolar icin genis token; JSON bozuksa o gecis 1 kez tekrarlanir) ---
    $g1 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g1.girdi; $topCikti += $g1.cikti
    $g2 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g2.girdi; $topCikti += $g2.cikti
    try { $k1 = JsonAyikla $g1.metin } catch { $g1 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g1.girdi; $topCikti += $g1.cikti; $k1 = JsonAyikla $g1.metin }
    try { $k2 = JsonAyikla $g2.metin } catch { $g2 = ApiCagri $Model $icerikTam 6000; $topGirdi += $g2.girdi; $topCikti += $g2.cikti; $k2 = JsonAyikla $g2.metin }

    $notlar = @()

    # GTIP karsilastirma
    $gtip1 = @($k1.gtip_kodlari) -join ","; $gtip2 = @($k2.gtip_kodlari) -join ","
    $gtipFinal = if($gtip1 -eq $gtip2){ @($k1.gtip_kodlari) } else {
      $notlar += "GTIP listesi iki okumada farkli - kesisim alindi"
      @($k1.gtip_kodlari) | Where-Object { @($k2.gtip_kodlari) -contains $_ }
    }

    # yururluk (kalipli oldugu icin esitlik saglikli)
    $yurFinal = if((NormD $k1.yururluk) -eq (NormD $k2.yururluk)){ $k1.yururluk } else { "Kaynak tebliğdeki yürürlük maddesine bakın" }

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
    foreach($r in $ey1){
      if(-not $r.konu){ continue }
      $es = $ey2 | Where-Object { (NormD $_.konu) -eq (NormD $r.konu) } | Select-Object -First 1
      if($es -and (NormD $es.yeni) -eq (NormD $r.yeni)){ $eskiYeniFinal += $r }
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
      if($m1.ContainsKey($kod) -and $m2.ContainsKey($kod) -and ((NormD $m1[$kod]) -eq (NormD $m2[$kod]))){ $kesin[$kod] = $m1[$kod] }
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
          if(($m1.ContainsKey($kod) -and (NormD $m1[$kod]) -eq (NormD $hd)) -or ($m2.ContainsKey($kod) -and (NormD $m2[$kod]) -eq (NormD $hd))){
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
      degistirilen_teblig = $k1.degistirilen_teblig
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
    Write-Host ("HATA {0}: {1}" -f $d.Name, ($_.Exception.Message -replace [regex]::Escape($key),"***")) -ForegroundColor Yellow
  }
}

# hafizayi kaydet
$hafizaObj = [ordered]@{}
foreach($kod in ($hafiza.Keys | Sort-Object)){ $hafizaObj[$kod] = $hafiza[$kod] }
($hafizaObj | ConvertTo-Json -Depth 6) | Out-File $hafizaYol -Encoding utf8

# kart verisini kaydet
$gunKartDir = Join-Path $here ("kartlar\" + $Gun)
New-Item -ItemType Directory -Force $gunKartDir | Out-Null
$kartlar | ConvertTo-Json -Depth 8 | Out-File (Join-Path $gunKartDir "kartlar.json") -Encoding utf8

# radar-app panosunun GTIP eslesmesi icin sabit "guncel kartlar" (yalniz GTIP'li kartlar, trim)
$guncelKartlar = @($kartlar | ForEach-Object {
  [ordered]@{ baslik=$_.baslik_sade; ne_oldu=$_.ne_oldu; gtip=@($_.gtip_kodlari); url=$_.kaynak; etki=($_.etki.yon) }
} | Where-Object { @($_.gtip).Count -gt 0 })
$guncelObj = [ordered]@{ gun=$Gun; guncelleme=("Günün hap kartları (GTİP eşleşmeli) — " + $TarihNokta); kartlar=$guncelKartlar }
$guncelYol = Join-Path $kok "veri\kartlar-guncel.json"
[System.IO.File]::WriteAllText($guncelYol, ($guncelObj | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($true)))

# ---- kartlar.html + gunluk arsiv kopyasi ------------------------------------
$s = New-Object System.Text.StringBuilder
[void]$s.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">')
[void]$s.AppendLine("<title>Günün Hap Kartları - $TarihNokta | Tetikte</title>")
[void]$s.AppendLine('<meta name="description" content="Bugünün Resmî Gazete değişiklikleri hap bilgi kartları hâlinde: ne oldu, kimi ilgilendiriyor, ne yapmalı.">')
[void]$s.AppendLine('<link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$s.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%);--red:#ff6b5e;--amber:#ffc24b;--green:#3ddc97}')
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
[void]$s.AppendLine('.gtip{display:inline-block;background:rgba(62,155,255,.12);color:var(--accent2);border-radius:7px;padding:2px 8px;font-size:11.5px;margin:2px 4px 2px 0;font-variant-numeric:tabular-nums}')
[void]$s.AppendLine('.kiymet{font-size:12.5px;color:var(--muted);margin:2px 0;font-variant-numeric:tabular-nums}.kiymet b{color:var(--ink)}')
[void]$s.AppendLine('.kiyas{background:rgba(61,220,151,.09);border:1px solid rgba(61,220,151,.3);color:var(--green);border-radius:9px;padding:8px 12px;font-size:12.5px;margin:8px 0}')
[void]$s.AppendLine('.meta{font-size:11px;color:var(--dim);margin-top:10px}.meta a{color:var(--accent2)}')
[void]$s.AppendLine('.cta{background:linear-gradient(135deg,rgba(47,123,255,.16),rgba(38,208,254,.07)),var(--panel);border:1px solid rgba(62,155,255,.3);border-radius:16px;padding:24px;margin-top:30px}')
[void]$s.AppendLine('.cta h3{margin:0 0 6px;font-size:18px}.cta p{margin:0 0 15px;font-size:13.5px;color:var(--muted)}')
[void]$s.AppendLine('.btn{display:inline-block;background:var(--grad);color:#03101f;font-weight:700;font-size:14px;padding:12px 22px;border-radius:12px;text-decoration:none;box-shadow:0 6px 24px rgba(46,140,255,.35)}')
[void]$s.AppendLine('.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:14px;border-top:1px solid var(--line)}')
[void]$s.AppendLine('</style></head><body><div class="wrap">')
[void]$s.AppendLine('<div class="top"><span class="logo">T</span><a href="index.html">Tetikte</a> · <a href="gtip.html">GTİP Kontrolü</a> · <a href="destekler.html">Destek Radarı</a> · <a href="radar.html">Bugün RG''de</a> · Günün Kartları · <a href="arsiv/index.html">Arşiv</a></div>')
[void]$s.AppendLine("<h1>Günün Hap Kartları</h1>")
[void]$s.AppendLine("<div class='alt'>$TarihNokta — Resmî Gazete'deki $($kartlar.Count) düzenleme, 30 saniyede okunur kartlar hâlinde.</div>")
# nobet damgasi: robot her gun tarar; kart cikmasa da "son tarama" tarihi canli gorunur (veri/kart-durum.json'u kartlar.yml yazar)
[void]$s.AppendLine('<div id="nobet" style="display:none;font-size:12.5px;color:var(--green,#3ddc97);background:rgba(61,220,151,.08);border:1px solid rgba(61,220,151,.3);border-radius:10px;padding:9px 13px;margin:10px 0 0"></div>')
[void]$s.AppendLine('<script>fetch("veri/kart-durum.json?"+Date.now()).then(r=>r.json()).then(d=>{var e=document.getElementById("nobet");e.style.display="block";e.innerHTML="🟢 Nöbet sürüyor — Resmî Gazete son tarama: <b>"+d.sonTarama+"</b>. Kart gerektiren yeni düzenleme çıkmadığı günlerde liste değişmez.";}).catch(()=>{});</script>')
[void]$s.AppendLine('<div class="uyari">Kartlar, ekibimizin geliştirdiği çift kontrollü okuma sistemiyle doğrudan Resmî Gazete metninden üretilir; her değer <b>iki bağımsız okuma + anlaşmazlıkta üçüncü kontrol</b> ile doğrulanır. Güvenle doğrulanamayan değer karta yazılmaz. Bilgilendirme amaçlıdır — işlem öncesi kaynak tebliği açın.</div>')
foreach($k in $kartlar){
  [void]$s.AppendLine('<div class="kart">')
  [void]$s.AppendLine('<div class="etiket">■ MEVZUAT DEĞİŞİKLİĞİ</div>')
  [void]$s.AppendLine("<h3>$($k.baslik_sade)</h3>")
  [void]$s.AppendLine("<p><b>Ne oldu:</b> $($k.ne_oldu)</p>")
  if($k.degistirilen_teblig){ [void]$s.AppendLine("<p><b>Neyi değiştiriyor:</b> $($k.degistirilen_teblig)</p>") }
  if(@($k.eski_yeni).Count){
    $eyEtiket = if($k.eski_karsilastirma){ "($($k.eski_karsilastirma) tarihli RG'deki eski metinle karşılaştırıldı)" } else { "(tebliğ metninden, çift okumayla doğrulanmış)" }
    [void]$s.AppendLine("<p><b>Eskiden → Şimdi</b> <span style='font-size:11px;color:var(--dim)'>$eyEtiket</span></p>")
    foreach($ey in @($k.eski_yeni)){
      [void]$s.AppendLine("<div class='kiymet'>• $($ey.konu): <span style='color:var(--dim);text-decoration:line-through'>$($ey.eski)</span> → <b>$($ey.yeni)</b></div>")
    }
  }
  if($k.urun_tanimi){ [void]$s.AppendLine("<p><b>Ürün:</b> $($k.urun_tanimi)</p>") }
  if(@($k.gtip_kodlari).Count){
    $chips = (@($k.gtip_kodlari) | ForEach-Object { "<span class='gtip'>$_</span>" }) -join ""
    [void]$s.AppendLine("<p><b>GTİP:</b><br>$chips</p>")
  }
  if($k.kesin_kiymetler.Count){
    [void]$s.AppendLine("<p><b>Birim kıymetler (çapraz doğrulanmış):</b></p>")
    foreach($kod in $k.kesin_kiymetler.Keys){ [void]$s.AppendLine("<div class='kiymet'>$kod → <b>$($k.kesin_kiymetler[$kod])</b></div>") }
  }
  foreach($ky in @($k.kiyaslar)){ [void]$s.AppendLine("<div class='kiyas'>📊 Eskiden → Şimdi (kayıt defterimizden) — $ky</div>") }
  [void]$s.AppendLine("<p><b>Kimi ilgilendirir:</b> $($k.kimi_ilgilendirir)</p>")
  [void]$s.AppendLine("<p><b>Ne yapmalısın:</b> $($k.ne_yapmali)</p>")
  [void]$s.AppendLine("<p><b>Yürürlük:</b> $($k.yururluk)</p>")
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
[void]$s.AppendLine('<div class="cta"><h3>Bu kartlardan hangisi SENİN kodlarına dokunuyor?</h3>')
[void]$s.AppendLine('<p>Yakında: GTİP kodlarını kaydet, sadece seni etkileyen kart cebine gelsin. Şimdilik: firmanın tüm yükümlülüklerini 3 dakikada gör.</p>')
[void]$s.AppendLine('<a class="btn" href="index.html#app">Ücretsiz Yükümlülük Karnesi →</a></div>')
[void]$s.AppendLine("<div class='dip'>Tetikte hap bilgi motoru · Çift geçiş + hakem model çapraz kontrolü · Bilgilendirme amaçlıdır, kaynak tebliğ esastır.</div>")
[void]$s.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script></div></body></html>')
$kartlarHtml = Join-Path $kok "kartlar.html"
[System.IO.File]::WriteAllText($kartlarHtml, $s.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# gunluk arsiv kopyasi (goreli linkler icin <base> eklenir)
$arsivDirSite = Join-Path $kok "arsiv"
New-Item -ItemType Directory -Force $arsivDirSite | Out-Null
$arsivHtml = $s.ToString().Replace('<head>','<head><base href="../">')
[System.IO.File]::WriteAllText((Join-Path $arsivDirSite ("kartlar-" + $Gun + ".html")), $arsivHtml, (New-Object System.Text.UTF8Encoding($false)))

# arsiv index'ini yeniden kur
$gunler = Get-ChildItem $arsivDirSite -Filter "kartlar-*.html" | ForEach-Object {
  $g = $_.BaseName -replace "^kartlar-",""
  $pp = $g.Split("-")
  [pscustomobject]@{ dosya=$_.Name; gun=$g; sirala=("{0}{1}{2}" -f $pp[2],$pp[1],$pp[0]); goster=("{0}.{1}.{2}" -f $pp[0],$pp[1],$pp[2]) }
} | Sort-Object sirala -Descending
$a = New-Object System.Text.StringBuilder
[void]$a.AppendLine('<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><base href="../">')
[void]$a.AppendLine('<title>Kart Arşivi | Tetikte</title><link rel="icon" type="image/svg+xml" href="favicon.svg"><style>')
[void]$a.AppendLine(':root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.09);--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent2:#26d0fe;--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%)}')
[void]$a.AppendLine('*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.7}')
[void]$a.AppendLine('a{color:var(--accent2)}.wrap{max-width:720px;margin:0 auto;padding:24px 18px 70px}')
[void]$a.AppendLine('.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:24px;color:var(--dim)}.top a{color:var(--muted);text-decoration:none;font-weight:600}')
[void]$a.AppendLine('.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}')
[void]$a.AppendLine('h1{font-size:26px;letter-spacing:-.8px;font-weight:800}')
[void]$a.AppendLine('.g{display:block;background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px 18px;margin-bottom:10px;color:var(--ink);text-decoration:none;font-weight:600}.g:hover{border-color:rgba(62,155,255,.4)}')
[void]$a.AppendLine('.g span{color:var(--dim);font-weight:400;font-size:12.5px}')
[void]$a.AppendLine('</style></head><body><div class="wrap">')
[void]$a.AppendLine('<div class="top"><span class="logo">T</span><a href="index.html">Tetikte</a> · <a href="kartlar.html">Günün Kartları</a> · Arşiv</div>')
[void]$a.AppendLine('<h1>Hap Kart Arşivi</h1><p style="color:var(--muted);font-size:14px">Gün gün, Resmî Gazete değişikliklerinin hap kartları.</p>')
foreach($g in $gunler){ [void]$a.AppendLine("<a class='g' href='arsiv/$($g.dosya)'>$($g.goster) <span>— günün kartları</span></a>") }
[void]$a.AppendLine('<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script></div></body></html>')
[System.IO.File]::WriteAllText((Join-Path $arsivDirSite "index.html"), $a.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$maliyet = ($topGirdi/1000000.0)*1.0 + ($topCikti/1000000.0)*5.0 + ($hakemGirdi/1000000.0)*3.0 + ($hakemCikti/1000000.0)*15.0
""
"TOPLU URETIM BITTI (v0.2)"
"Kart: $($kartlar.Count) | Hatali: $hatali | Hakem devreye girdi: $hakemSayisi kart"
"Ana model token: $topGirdi/$topCikti | Hakem token: $hakemGirdi/$hakemCikti"
("Toplam maliyet: ~{0:N3} USD" -f $maliyet)
"Hafizadaki kod sayisi: $($hafiza.Keys.Count)"
"Sayfalar: kartlar.html + arsiv/kartlar-$Gun.html + arsiv/index.html"