# ============================================================================
#  SORU URETICI v2 — 29.07.2026
#
#  Bu betik, bu gece kurulan her seyin bir araya geldigi yer:
#    KOTA      (veri/uretim-kotasi.json)  ders x konu x kurgu, 12 donem TESMER
#    BAG       kasadaki 4.101 bagli sorudan konu -> kanun maddesi haritasi
#    AMBAR     maddenin TAM METNI (madde-coz.ps1)
#    SABLON    STANDART-ACIKLAMA.md - dort parca, tuzak adlandirma, gorsel
#    KAPILAR   riskli sayi / dil / benzerlik
#
#  EN ONEMLI KARAR: uretilen soru DOGRUDAN YAYINA GIRMEZ.
#  yayin=false ile kasaya duser, profesor yargilar, GM okur, sonra acilir.
#  "Hata olsa bile yayinlanmadan yakalayalim" sarti ancak boyle karsilanir.
#  800 USD'lik ilk parti denetimsiz yayina girdigi icin bu geceyi hatalari
#  toplayarak gecirdik; ayni hatayi tekrarlamiyoruz.
#
#  KAYNAKSIZ SORU URETILMEZ: konu bir maddeye baglanamiyorsa o satir ATLANIR
#  ve rapora yazilir. Model hafizasindan soru yazmasin - bu gece bulunan uc
#  gercek hatanin ucu de "model hatirladigindan yazmis" tipiydi.
# ============================================================================
param(
  [switch]$calistir,
  [int]$sinir = 200,
  [string]$ders = '',
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = '',
  # 29.07 aksam: bu gece uretilen 3.451 sorunun HEPSI Yeterlilik'e gitti cunku
  # betik tek bir kotayi ve tek bir sinavi taniyordu. SGS (Staja Giris) kasada
  # 6.708 soruyla duruyor ama uretim hic dokunmamis. Sinav artik parametre.
  [ValidateSet('SMMM','SGS')]
  [string]$sinav = 'SMMM'
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
try { Start-Transcript -Path (Join-Path $kok 'veri/uretim-log.txt') -Force | Out-Null } catch {}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$AK = "$env:ANTHROPIC_API_KEY".Trim()
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

# 29.07: PowerShell 7'de Invoke-RestMethod hatasinda govde
# $_.Exception.Response akisinda DEGIL, $_.ErrorDetails.Message icinde durur.
# Iki kosu ust uste "400 Bad Request" deyip sebebini soylemedi cunku yanlis
# yerden okuyordum.
function HataGovde($e){
  if($e.ErrorDetails -and $e.ErrorDetails.Message){ return "$($e.ErrorDetails.Message)" }
  try { return (New-Object IO.StreamReader($e.Exception.Response.GetResponseStream())).ReadToEnd() } catch { return "" }
}

# --- KURU DENEME: yazma yolu SAGLAM MI, soru uretmeden once bak.
# Iki parti (200 + 30 soru, 2,62 USD) yalnizca "yazma bozuk" oldugunu ogrenmek
# icin harcandi. Once tek satirlik bir deneme yaz, hatayi gor, sonra uret.
function YazmaDenemesi(){
  $dId = [guid]::NewGuid().ToString()
  $dSatir = @([ordered]@{
    id=$dId; sinav=$script:sinav; ders='DENEME'; konu='yazma denemesi'
    soru='Bu bir yazma yolu denemesidir, hemen silinir.'
    siklar=@{A='a';B='b';C='c';D='d';E='e'}; dogru='A'
    aciklama=@{A='a';B='b';C='c';D='d';E='e'}; hap='deneme'
    kaynak='deneme'; uretim='kuru-deneme'; kanun_no='213'; madde_no='1'
    yayin=$false; yayin_notu='kuru deneme'
  })
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $HW -ContentType "application/json; charset=utf-8" `
      -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $dSatir -Depth 6))) -TimeoutSec 60 | Out-Null
  } catch {
    Write-Host "KURU DENEME BASARISIZ - yazma yolu bozuk, SORU URETILMEYECEK."
    Write-Host ("  hata  : {0}" -f $_.Exception.Message)
    Write-Host ("  sunucu: {0}" -f (HataGovde $_))
    return $false
  }
  try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$dId" -Headers $HW -TimeoutSec 30 | Out-Null } catch {}
  Write-Host "KURU DENEME TAMAM - yazma yolu saglam."
  return $true
}

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- kota  (sinava gore AYRI dosya - karistirilirsa yanlis sinava soru uretilir)
$kotaDosya = if($sinav -eq 'SGS'){ "veri/sgs-uretim-kotasi.json" } else { "veri/uretim-kotasi.json" }
$kotaYol = Join-Path $kok $kotaDosya
if(-not (Test-Path $kotaYol)){ Write-Host "Kota dosyasi yok: $kotaDosya"; exit 1 }
$kota = Get-Content $kotaYol -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = @($kota.plan)
if($ders){ $plan = @($plan | Where-Object { "$($_.ders)" -eq $ders }) }
Write-Host ("SINAV: {0}   kota: {1}   plan satiri: {2}" -f $sinav, $kotaDosya, $plan.Count)
if($plan.Count -eq 0){ Write-Host "Plan bos - uretilecek satir yok, cikiliyor."; exit 1 }

# --- kasadan KONU -> MADDE haritasi (4.101 bagli soru zaten var, bedava kaynak)
Write-Host "Kasa okunuyor (konu -> madde haritasi + benzerlik icin soru metinleri)..."
$kasa = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,kanun_no,madde_no&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kasa.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("  kasa: {0} soru" -f $kasa.Count)

function Kel([string]$t){
  $l=@(); foreach($w in (("$t".ToLowerInvariant() -replace '[ıİ]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c') -split '[^a-z0-9]+')){ if($w.Length -ge 4){ $l += $w } }
  return $l
}
# kelime -> (kanun,madde) adaylari
$kelMadde=@{}
foreach($k in $kasa){
  if(-not $k.kanun_no -or -not $k.madde_no){ continue }
  if("$($k.kanun_no)" -in @('STD','THP')){ continue }
  foreach($w in (Kel "$($k.konu)")){
    if(-not $kelMadde.ContainsKey($w)){ $kelMadde[$w]=@{} }
    $anahtar = "$($k.kanun_no)|$($k.madde_no)"
    $kelMadde[$w][$anahtar] = 1 + [int]$kelMadde[$w][$anahtar]
  }
}
Write-Host ("  konu-kelime indeksi: {0} kelime" -f $kelMadde.Count)

# 29.07 - TAM KOSUNUN BULGUSU. Pilotlarda (50-60 soru) rakam reddi 0-2 iken,
# 2.400'luk kosuda 556'ya firladi. Sebep sudur: pilotlar kotanin EN GUCLU
# satirlarini kullaniyordu; olcek buyuyunce konu-madde eslesmesi ZAYIF satirlara
# inildi. Model, konuyla ortusmeyen bir maddeden soru yazmaya calisiyor, kanunda
# olmayan sayi beyan ediyor, kapi da hakli olarak reddediyor.
# KAPI DOGRU CALISIYOR AMA PARA ONCE HARCANIYOR: 786 soru uretildi, ucreti
# odendi, sonra cope gitti (~6 USD).
# Cozum: zayif eslesmeyi URETMEDEN once ele. Olcut "toplam puan" degil, KAC AYRI
# KELIMENIN ayni maddeyi isaret ettigi - tek kelimenin tesadufen tutturmasi
# eslesme sayilmaz ("defter" kelimesi onlarca maddede gecer).
function MaddeBul([string]$konu){
  $sayac=@{}; $kelimeSay=@{}
  foreach($w in (Kel $konu)){
    if(-not $kelMadde.ContainsKey($w)){ continue }
    foreach($p in $kelMadde[$w].GetEnumerator()){
      $sayac[$p.Key] = [int]$sayac[$p.Key] + $p.Value
      if(-not $kelimeSay.ContainsKey($p.Key)){ $kelimeSay[$p.Key] = @{} }
      $kelimeSay[$p.Key][$w] = 1
    }
  }
  if($sayac.Count -eq 0){ return $null }
  $en = ($sayac.GetEnumerator() | Sort-Object {-$_.Value} | Select-Object -First 1)
  $ayriKelime = $kelimeSay[$en.Key].Count
  $konuKelime = @(Kel $konu).Count
  # TEK kelimeye dayanan eslesme, konu birden fazla kelimeden olusuyorsa zayiftir.
  if($ayriKelime -lt 2 -and $konuKelime -ge 2){ return $null }
  return $en.Key
}

# --- mevcut soru metinleri (benzerlik kapisi icin)
$mevcutKok=@{}
foreach($k in $kasa){ $mevcutKok[((Kel "$($k.soru)") -join ' ')] = 1 }

function IstemKur($ders,$konu,$kurgu,$uzun,$maddeAd,$maddeMetni,$kirpildi=$false){
  $gorsel = ''
  if($ders -in @('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Finansal Tablolar ve Analizi')){
    $gorsel = @"

GORSEL: soru KAYIT tipindeyse "yevmiye" alanini doldur
  [{"hesap":"100 KASA","borc":5000,"alacak":0},{"hesap":"600 YURTICI SATISLAR","borc":0,"alacak":5000}]
Soru TABLO/ANALIZ tipindeyse "tablo" alanini doldur
  {"baslik":"Gelir Tablosu (TL)","kolonlar":["Kalem","Tutar"],"satirlar":[["Brut Satislar","100.000"],["Brut Kar <-","40.000"]]}
Gerekmiyorsa bos birak. UYDURMA TABLO, TABLOSUZLUKTAN KOTUDUR.
"@
  }
  # Ayni konu iki sinavda AYNI DERINLIKTE sorulmaz: SGS adayi henuz staja
  # baslamamis bir universite mezunu, Yeterlilik adayi uc yil buro gormus bir
  # stajyer. Sinav adini degistirip seviyeyi degistirmemek, SGS'ye Yeterlilik
  # sorusu yazmak olurdu - cocuk hazirliksiz kalir.
  $sinavBasligi = if($script:sinav -eq 'SGS'){
@"
Sen TURMOB-TESMER SMMM STAJA GIRIS (SGS) sinavi icin soru yazan bir editorsun.
SEVIYE: Aday universite mezunu ama HENUZ STAJA BASLAMAMIS - buro tecrubesi yok.
130 soruluk, bes secenekli, tek oturumluk sinav. Konunun TEMELINI ve ders
kitabi duzeyindeki uygulamasini sor; uc yillik meslek pratigi gerektiren
istisna zincirlerine, nadir ozel hukumlere ve buro tecrubesi olmadan
bilinemeyecek uygulama detaylarina GIRME.
"@
  } else {
@"
Sen TURMOB-TESMER SMMM YETERLILIK sinavi icin soru yazan bir editorsun.
"@
  }
  return @"
$sinavBasligi

=== DAYANAK METIN ($maddeAd) ===
$maddeMetni
=== METIN BITTI ===
$(if($kirpildi){ "UYARI: Bu madde COK UZUN oldugu icin metin KIRPILDI. Yukarida GORDUGUN
kismin disinda kalan fikralar hakkinda soru YAZMA. Gordugun bir hukmun sonraki
fikralarda degistirilmis ya da istisna getirilmis olma ihtimali var - emin
olamadigin bir oran, sure ya da esik icin soru kurma. Kirpilmis metinden yazilan
soru, kaynakli GORUNUR ama kaynaksizdir; bu en tehlikeli hata turudur." })

YAZILACAK SORU:
  Ders   : $ders
  Konu   : $konu
  Kurgu  : $kurgu   (bilgi=duz bilgi/tanim · hesap=rakamli hesaplama · vaka=olay anlatilip hukum sorulur · kayit=yevmiye/muhasebelestirme · karsilastir=iki kavramin farki)
  Uzunluk: $uzun    (kisa=tek cumle · orta · uzun=paragraf/vaka metni)

INSAN ELINDEN CIKMIS GORUNECEK - BU BIR USLUP TERCIHI DEGIL, SARTTIR.
Ogrenci "bunlari yapay zeka yazmis" derse guven biter. Yapay zeka izleri sunlar,
hicbirini yapma:
- "ABC Ticaret A.S.", "XYZ A.S.", "X Isletmesi" gibi HARF PLACEHOLDER unvanlar.
  Gercek unvan yaz: "Ozdemir Tekstil Ltd. Sti.", "Karadeniz Gida A.S.", "Bayrak
  Ins. San. Tic. A.S." Her soruda FARKLI unvan.
- Kisi adi gerekiyorsa yaygin Turk adi kullan (Mehmet, Ayse, Hatice, Mustafa,
  Fatma, Ali) - "Deniz", "Ege", "Alp" gibi moda tarafsiz adlar yigilmasin.
- HER TUTARIN YUVARLAK olmasi. 100.000 + 8.000 + 3.500 dizisi sahte kokar.
  Gercek hayatta rakam 47.350 TL, 6.812 TL, 129.470 TLdir. En az bir tutar
  yuvarlak OLMASIN.
- Ayni cumle kaliplarinin tekrari. Yanlis sik aciklamalarinda dort kez ayni
  kalibi kurma; birinde "karistiriyor", digerinde "sanilan sey", digerinde
  "gozden kacan nokta" gibi FARKLI anlat.
- Sisirme kliseler: "onem arz etmektedir", "unutulmamalidir ki", "dikkat
  edilmelidir", "soz konusudur", "bu baglamda", "ilgili mevzuat uyarinca".
  Sade konus: "Bu durumda vergi dogar." gibi.
- Her soruyu ayni kalipla baslatma. Kimi soru olayla, kimi dogrudan soruyla,
  kimi tabloyla baslasin.
Hedef: TESMER kitapciginda bu sorunun yanina bir gercek cikmis soru konsa,
hangisinin bizim oldugu ANLASILMASIN.

MUTLAK KURALLAR:
1. Soru YALNIZCA yukaridaki dayanak metne dayanacak. Metinde YAZMAYAN hicbir rakam, oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin degilsen sayi verme.
2. BES sik (A-E), TAM OLARAK BIRI dogru. Digerleri makul ama acikca yanlis olmali - "neredeyse dogru" sik yazma.
3. Cikmis sinav sorusu KOPYALAMA. Ozgun yaz.
4. Istenen KURGUYA sadik kal. "bilgi" istendiyse hesap sorusu yazma.

ACIKLAMA SABLONU - dogru sik icin DORT PARCA, bu basliklarla:
Ne soruluyor: <tek cumle, hic muhasebe bilmeyene>
Kural: <maddeye dayali, gunluk dille>
Bu olayda: <kuralin uygulanisi, adim adim>
Akilda kalsin: <tek cumle>
400-700 karakter.

YANLIS SIK ACIKLAMASI DA MEVZUATTIR: orada da dayanak metinde YAZMAYAN kanun
numarasi, oran veya tarih kullanma. Pilot-2'de bir soru dogrusunu dogru yazdi ama
yanlis sik aciklamasinda "7566 sayili Kanunla %21'e yukseldi" diye OLMAYAN bir
duzenleme uydurdu ve kendi dogru cevabini yalanladi. Bir sikkin niye yanlis
oldugunu anlatirken "su kanun degistirdi" deme; DAYANAK METINDEKI kuralla anlat.

YANLIS SIKLARDA TEK IS: TUZAGI ADLANDIRMAK. Bu bir uslup tercihi degil, MAKINEYLE
DENETLENEN bir sarttir: dort yanlis siktan en az UCUNUN aciklamasi su kelimelerden
birini gecirmek ZORUNDA - "tuzak", "karistiriyor", "saniliyor", "zannediliyor",
"yanilgi", "atlaniyor", "unutuluyor", "gozden kaciyor". Gecmiyorsa soru COPE GIDER.
Kalibi soyle: "TUZAK: <A> ile <B> karistiriliyor. <A> sudur; <B> ise budur. Bu sik
<B>'yi kullandigi icin yanlis." 120-250 karakter.
"Bu sik yanlistir cunku dogru cevap X'tir" YASAK - ogretmiyor, tekrarliyor.
Ilk 163 soruluk partide 19 ornegin 19'u bu sarti tutmadi ve parti reddedildi.

TEK DOGRU CEVAP SARTI: Dayanak metinde bir husus IHTIYARI ise ("...maliyet bedeline
ithal etmekte veya genel giderlere kaydetmekte mukellefler serbesttir" gibi), o
hususu ya soruya HIC KOYMA ya da isletmenin hangi secimi yaptigini SORU METNINDE
acikca yaz. Ilk partide bir soru noter masrafini cevaba katti ama isletmenin bunu
sectigini soylemedi; iki farkli cevap savunulabilir hale geldi. Sinavda itiraz
edilen soru tipi budur.

CELISKI YASAGI: "Kural" parcasinda dahildir dedigin bir kalemi "Bu olayda"
parcasinda haric tutma. Ilk partide bir aciklama sigorta primini once dahil edip
sonra disladi; ogrenci hangisine inanacagini bilemez.

DIL: cumle ortalama 20 kelimeyi gecmesin, tek cumle 30'u asmasin. Teknik terimi ilk kullandiginda parantezle acikla. Edilgen degil etken yaz.
$gorsel
SADECE gecerli JSON dondur:
{"mevzuat_sayilari":["<dayanak metinden aldigin oran/sure/esik sayilari; senaryo icin kendi uydurdugun tutar ve tarihleri BURAYA YAZMA>"],"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","yevmiye":[],"tablo":null}
"@
}

# --- kurgu dagilimindan tip sec (deterministik: sirayla dagit)
$dersKurgu=@{}
foreach($o in $kota.ozet){
  $l=@()
  foreach($par in ("$($o.kurgu)" -split ' · ')){
    if($par -match '^(\S+)\s+%(\d+)$'){ for($i=0;$i -lt [int]$Matches[2];$i++){ $l += $Matches[1] } }
  }
  if($l.Count -eq 0){ $l = @('bilgi') }
  $dersKurgu["$($o.ders)"] = $l
}

# --- isler
$isler = New-Object System.Collections.Generic.List[object]
$ist=[ordered]@{ planSatir=0; maddesiz=0; metinsiz=0; hazir=0 }
$sayac=@{}
foreach($p in $plan){
  if($isler.Count -ge $sinir){ break }
  $ist.planSatir++
  $anahtar = MaddeBul "$($p.konu)"
  if(-not $anahtar){ $ist.maddesiz++; continue }
  $par = $anahtar -split '\|'
  $seri=''; $mn="$($par[1])"
  if($mn -match '^(gec|ek|muk)(\d+)$'){ $seri=$Matches[1]; $mn=$Matches[2] }
  $m = MaddeMetni "$($par[0])" $mn $seri
  if(-not $m -or -not $m.metin){ $ist.metinsiz++; continue }
  # 29.07 - HAKEM RAPORUNUN EN ONEMLI BULGUSU BURADAN CIKTI.
  # 240 soruluk denetimde: TAM maddeden yazilan sorularin %7'si desteksizken,
  # PARCALI maddeden yazilanlarin %26'si desteksizdi - 3,5 kat fark.
  # Sebep parcalanma degil, BU SATIRDI: parcalar birlestiriliyor (madde-coz
  # zaten birlestiriyor) ama sonra 6.000 karakterde kirpiliyordu. 11 parcali
  # bir madde birlesince 6.000'i cok asar; model ilk 1-2 parcayi gorur, cevabin
  # bulundugu fikra kirpilan kisimda kalir. Model de gordugu kadarindan yazar -
  # ve ortaya "kaynakli gorunen, kaynaksiz soru" cikar. En tehlikeli tur budur:
  # kaynak alani dolu oldugu icin butun bicim kapilarindan gecer.
  # 5510 m.81 tam boyle gitti: soru "%20, isveren %11" dedi; maddenin kirpilan
  # kisminda oran 7566 sayili Kanunla %21'e (isveren %12) cikmisti.
  $KIRPMA = 24000
  $metin = "$($m.metin)"
  $kirpildi = $false
  if($metin.Length -gt $KIRPMA){ $metin = $metin.Substring(0,$KIRPMA); $kirpildi = $true }

  $adet = [Math]::Min([int]$p.adet, $sinir - $isler.Count)
  $kl = $dersKurgu["$($p.ders)"]; if(-not $kl){ $kl=@('bilgi') }
  for($i=0; $i -lt $adet; $i++){
    if($isler.Count -ge $sinir){ break }
    $n = [int]$sayac["$($p.ders)"]; $sayac["$($p.ders)"] = $n + 1
    $kurgu = $kl[$n % $kl.Count]
    $uzun = @('orta','kisa','orta','uzun')[$n % 4]
    $isler.Add([pscustomobject]@{
      ders="$($p.ders)"; konu="$($p.konu)"; kurgu=$kurgu; uzun=$uzun
      kanun=$par[0]; madde=$par[1]; maddeAd="$($m.ad)"
      istem=(IstemKur "$($p.ders)" "$($p.konu)" $kurgu $uzun "$($m.ad)" $metin $kirpildi)
      metin=$metin; kirpildi=$kirpildi
    })
    $ist.hazir++
  }
}
Write-Host ""
foreach($k in $ist.Keys){ Write-Host ("  {0,-12} {1}" -f $k, $ist[$k]) }
$gk=0; foreach($i in $isler){ $gk += $i.istem.Length }
$tahmin = ((([math]::Round($gk/3))/1e6*3.0) + (($isler.Count*1400)/1e6*15.0))/2
Write-Host ("MALIYET TAHMINI (Batch %50): ~{0:N2} USD" -f $tahmin)
if(-not $calistir){ Write-Host "OLCUM MODU - 0 USD."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }
if($isler.Count -eq 0){ Write-Host "KIRMIZI: uretilecek is yok."; exit 1 }
# PARA HARCAMADAN ONCE: yazma yolu saglam mi?
if(-not (YazmaDenemesi)){ try{Stop-Transcript|Out-Null}catch{}; exit 1 }

# --- batch
$sonuc=@{}; $gG=0; $gC=0
$PARTI=200
for($p2=0; $p2 -lt [math]::Ceiling($isler.Count/$PARTI); $p2++){
  $dilim=@($isler[($p2*$PARTI)..([math]::Min(($p2+1)*$PARTI-1,$isler.Count-1))])
  $req=@(); $ix=0
  foreach($i in $dilim){ $req += @{ custom_id=("u{0}_{1}" -f $p2,$ix); params=@{ model=$model; max_tokens=2500; messages=@(@{role='user';content=$i.istem}) } }; $ix++ }
  $govde=@{requests=$req}|ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}: {1} soru" -f ($p2+1), $dilim.Count)
  $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  $tur=0
  while($true){ Start-Sleep -Seconds 20; $tur++
    $st = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" -Headers $HDR
    if($st.processing_status -eq 'ended'){ break }
    if($tur -ge 90){ Write-Host "  ZAMAN ASIMI"; break } }
  $adres = if($st.results_url){ "$($st.results_url)" } else { "https://api.anthropic.com/v1/messages/batches/$($b.id)/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 300
  $mt2 = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  foreach($sat in ($mt2 -split "`r?`n")){
    if("$sat".Trim().Length -eq 0){ continue }
    try { $r = $sat | ConvertFrom-Json } catch { continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $gG += [int]"$($r.result.message.usage.input_tokens)"; $gC += [int]"$($r.result.message.usage.output_tokens)"
    $jm=[regex]::Match("$($r.result.message.content[0].text)", '\{[\s\S]*\}')
    if(-not $jm.Success){ continue }
    try { $sonuc["$($r.custom_id)"] = ($jm.Value | ConvertFrom-Json) } catch {}
  }
}

# --- KAPILAR + yazma
function SayiListe([string]$t){ $l=@(); foreach($m in [regex]::Matches("$t",'\d[\d\.\,]*')){ $l += $m.Value.TrimEnd('.',',') }; return $l }
$YAZI=[ordered]@{ 'bir'=1;'iki'=2;'uc'=3;'üç'=3;'dort'=4;'dört'=4;'bes'=5;'beş'=5;'alti'=6;'altı'=6;'yedi'=7;'sekiz'=8;'dokuz'=9;'on'=10;'yirmi'=20;'otuz'=30;'elli'=50 }
function Riskli([string]$t){
  $l=@()
  foreach($k in $YAZI.Keys){ foreach($m in [regex]::Matches("$t","(?i)\b$k\s+(g[uü]n|ay|y[iı]l|hafta|kez|defa|kat)\b")){ $l += "$($YAZI[$k])" } }
  foreach($m in [regex]::Matches("$t",'%\s*(\d[\d\.,]*)')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t",'(\d[\d\.,]*)\s*%')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t","(?i)(\d+)\s*(g[uü]n|ay|y[iı]l|hafta)\b")){ $l += $m.Groups[1].Value }
  return $l
}
$ozet=[ordered]@{ uretilen=0; rakamRed=0; dilRed=0; sikRed=0; sablonRed=0; tuzakRed=0; atifRed=0; kokuRed=0; benzerRed=0; cevapsiz=0; yazmaHatasi=0 }
$red = New-Object System.Collections.Generic.List[object]
$yeni = New-Object System.Collections.Generic.List[object]
for($p2=0; $p2 -lt [math]::Ceiling($isler.Count/$PARTI); $p2++){
  for($ix=0; $ix -lt $PARTI; $ix++){
    $gi = $p2*$PARTI + $ix
    if($gi -ge $isler.Count){ break }
    $i = $isler[$gi]
    $y = $sonuc[("u{0}_{1}" -f $p2,$ix)]
    if(-not $y -or -not $y.soru -or -not $y.siklar){ $ozet.cevapsiz++; continue }
    # sik kapisi
    $dolu=0; foreach($h in @('A','B','C','D','E')){ if("$($y.siklar.$h)".Trim().Length -gt 2){ $dolu++ } }
    if($dolu -ne 5 -or "$($y.dogru)" -notin @('A','B','C','D','E')){ $ozet.sikRed++; continue }
    if("$($y.aciklama.$($y.dogru))".Trim().Length -lt 300){ $ozet.sikRed++; continue }

    # ---- SABLON KAPISI (29.07, 163 soruluk pilotun GM okumasindan sonra eklendi)
    # Pilot partide 19 ornegin 19'u TUZAK ADLANDIRMIYORDU ve 3'unde dort parcali
    # iskelet yoktu. STANDART-ACIKLAMA.md kilitli bir sozlesme: yanlis sik, niye
    # cazip oldugunu SOYLEYECEK. "Bu yanlistir" demek ogretmez; ogrenci ayni
    # tuzaga ikinci kez duser. Kapi olmayan standart, standart degil temennidir.
    $dt = "$($y.aciklama.$($y.dogru))"
    $eksikParca = @()
    foreach($par in @('Ne soruluyor','Kural','Bu olayda','Ak[ıi]lda kals[ıi]n')){
      if($dt -notmatch $par){ $eksikParca += $par }
    }
    if($eksikParca.Count){
      $ozet.sablonRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='sablon'; deger=("eksik parca: " + ($eksikParca -join ', ')) }); continue
    }
    $yanlisSik = @('A','B','C','D','E') | Where-Object { $_ -ne "$($y.dogru)" }
    $adlandiran = 0
    foreach($h in $yanlisSik){
      if("$($y.aciklama.$h)" -match '(?i)tuzak|kar[ıi][sş]t[ıi]r|san[ıi]l|zannedil|yan[ıi]lg|atlan|unutul|g[oö]zden ka[cç]'){ $adlandiran++ }
    }
    if($adlandiran -lt 3){
      $ozet.tuzakRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='tuzak-adlandirilmamis'; deger=("4 yanlis siktan {0}'i tuzagi soyluyor" -f $adlandiran) }); continue
    }
    # rakam kapisi
    $tumMetin = "$($y.soru)"; foreach($h in @('A','B','C','D','E')){ $tumMetin += " $($y.siklar.$h) $($y.aciklama.$h)" }

    # ---- YAPAY ZEKA KOKUSU KAPISI (29.07, Cem'in hatirlatmasi uzerine)
    # "Ogrenci bunlari yapay zeka yazmis demesin" sarti bir uslup kaprisi degil:
    # ogrenci soruyu makine isi sanirsa CEVABA DA GUVENMEZ, urun biter.
    # Ustelik bu riski BEN buyuttum - tuzak kapisini koyarken "karistiriyor"
    # kelimesini sart kostum; ayni kalibin binlerce soruda tekrarlanmasi, yapay
    # zeka kokusunun EN GUCLU kaynagidir. Tekduzelik, hatadan daha ele verir.
    $koku = @()
    if($tumMetin -match '(?i)\b(ABC|XYZ|ABCD)\s*(ticaret|gida|tekstil|a\.?s|ltd|isletme|sirket)'){ $koku += 'placeholder-unvan' }
    if($tumMetin -match '(?i)\b(X|Y|Z)\s+(A\.?S\.?|Isletmesi|Ltd)'){ $koku += 'harf-unvan' }
    # butun tutarlar yuvarlaksa sahte kokar: gercek hayatta 47.350 TL olur
    $tutar = @([regex]::Matches("$($y.soru)", '(\d{1,3}(?:\.\d{3})+)\s*(?:TL|lira)') | ForEach-Object { $_.Groups[1].Value })
    if($tutar.Count -ge 3){
      $yuvarlak = @($tutar | Where-Object { $_ -match '\.000$' }).Count
      if($yuvarlak -eq $tutar.Count){ $koku += "hepsi-yuvarlak($($tutar.Count))" }
    }
    $klise = @('onem arz et','unutulmamalidir','dikkat edilmelidir','bu baglamda','ilgili mevzuat uyarinca')
    foreach($kl in $klise){ if($tumMetin -match [regex]::Escape($kl)){ $koku += "klise:$kl" } }
    # dort yanlis sikta AYNI kalip: tekduzelik
    $kalip = @(); foreach($h in @('A','B','C','D','E')){ if($h -ne "$($y.dogru)"){ $m2=[regex]::Match("$($y.aciklama.$h)",'(?i)(kar[ıi][sş]t[ıi]r|san[ıi]l|zannedil|yan[ıi]lg|atlan|unutul|g[oö]zden ka[cç])'); if($m2.Success){ $kalip += $m2.Groups[1].Value.ToLowerInvariant() } } }
    if($kalip.Count -ge 4 -and (@($kalip | Select-Object -Unique).Count -eq 1)){ $koku += 'tekduze-tuzak-kalibi' }
    if($koku.Count){
      $ozet.kokuRed++
      $red.Add([pscustomobject]@{ konu=$i.konu; sebep='yapayzeka-kokusu'; deger=(($koku | Select-Object -Unique) -join ', ') })
      continue
    }

    # ---- UYDURMA ATIF KAPISI (29.07, pilot-2 okumasindan sonra)
    # Pilot-2'de bir soru dogrusunu dogru yazdi (5510 m.81: %20, isveren %11 /
    # sigortali %9) ama YANLIS SIK aciklamasinda "7566 sayili Kanunla %21'e
    # yukseldi, guncel oran %21" dedi. Boyle bir duzenleme dayanak metinde YOK ve
    # aciklama KENDI DOGRU CEVABINI yalanliyor - ogrenci ayni soruda hem "%20
    # dogru" hem "%20 eskidi" okuyor.
    # Rakam kapisi bunu kacirdi cunku yalniz modelin BEYAN ETTIGI sayilara
    # bakiyordu; model uydurmayi beyan etmez, yanlis sik aciklamasinin icine
    # gomer. Yanlis siklarin metni denetimsiz kaliyordu - kapinin kor noktasi.
    $atifRed = @()
    foreach($m in [regex]::Matches($tumMetin, '(\d{4})\s*say[ıi]l[ıi]')){
      $kn = $m.Groups[1].Value
      if($kn -eq "$($i.kanun)"){ continue }
      if($i.metin -match ([regex]::Escape($kn))){ continue }
      $atifRed += $kn
    }
    if($atifRed.Count){
      $ozet.atifRed++
      $red.Add([pscustomobject]@{ konu=$i.konu; sebep='uydurma-atif'; deger=(($atifRed | Select-Object -Unique) -join ', ') })
      continue
    }
    $kaynakSay=@{}; foreach($n in (SayiListe $i.metin)){ $kaynakSay[$n]=1 }
    $kaynakRisk=@{}; foreach($n in (Riskli $i.metin)){ $kaynakRisk[$n]=1 }
    # Yalniz modelin "bunu kanundan aldim" dedigi sayilar denetlenir. Senaryo
    # sayilari (isletmenin 61 gun vadeli senedi gibi) sorunun kendi kurgusudur.
    $uyd=@()
    foreach($n in @($y.mevzuat_sayilari)){
      $n2 = "$n".Trim().TrimEnd('.',',')
      if($n2.Length -eq 0 -or $n2 -notmatch '^\d'){ continue }
      if(-not $kaynakRisk.ContainsKey($n2) -and -not $kaynakSay.ContainsKey($n2)){ $uyd += $n2 }
    }
    if($uyd.Count){ $ozet.rakamRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='riskli-sayi'; deger=($uyd -join ',') }); continue }
    # dil kapisi
    $cum=@(($tumMetin -split '(?<=[.!?:])\s+') | Where-Object { $_.Trim().Length -gt 3 })
    $kel=@(); $enU=0; foreach($c in $cum){ $k2=@($c -split '\s+' | Where-Object{$_}).Count; $kel+=$k2; if($k2 -gt $enU){$enU=$k2} }
    $ort = if($kel.Count){ ($kel|Measure-Object -Average).Average } else { 0 }
    if($ort -gt 20 -or $enU -gt 38){ $ozet.dilRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='dil'; deger=("ort {0:N1} enuzun {1}" -f $ort,$enU) }); continue }
    # benzerlik kapisi
    $kokAn = ((Kel "$($y.soru)") -join ' ')
    if($mevcutKok.ContainsKey($kokAn)){ $ozet.benzerRed++; continue }
    $mevcutKok[$kokAn]=1

    $id = [guid]::NewGuid().ToString()
    $satir=[ordered]@{
      id=$id; sinav=$script:sinav; ders=$i.ders; konu=$i.konu
      soru="$($y.soru)"; siklar=$y.siklar; dogru="$($y.dogru)"; aciklama=$y.aciklama
      hap="$($y.hap)"; kaynak=$i.maddeAd; uretim=("kota-v2 " + (Get-Date -Format 'dd.MM.yyyy'))
      kanun_no=$i.kanun; madde_no=$i.madde
      yayin=$false
      yayin_notu='YENI URETIM - profesor denetimi ve GM okumasi bekliyor. Denetlenmeden yayina cikmaz.'
    }
    # 29.07 aksam - PGRST102 "All object keys must match" BURADAN CIKIYOR.
    # Eski hal: yevmiye VARSA eklenir, yoksa tablo eklenir, ikisi de yoksa
    # hicbiri eklenmezdi. Sonuc: ayni partideki satirlarin ANAHTAR SETI farkli
    # oluyordu ve PostgREST butun partiyi reddediyordu. Satir satir kurtarma
    # devreye girip veriyi kurtardi (kayip 0) ama 150 soru icin 150 ayri HTTP
    # cagrisi yapildi; 5.332 soruluk kosuda bu 5.332 cagri demek - yavas ve
    # zaman asimina acik.
    # Bu gecenin ilk 400'u "aradaki tek bozuk satir" diye tesbit edilmisti;
    # gercek sebep buymus - bozuk satir yok, ANAHTAR SETI TUTARSIZ.
    # Cozum: iki alan da HER satirda bulunur, ilgisizse $null gecer.
    $satir['yevmiye'] = if($y.yevmiye -and @($y.yevmiye).Count){ $y.yevmiye } else { $null }
    $satir['tablo']   = if($y.tablo -and $y.tablo.satirlar -and @($y.tablo.satirlar).Count){ $y.tablo } else { $null }
    $yeni.Add($satir)
  }
}

# --- kasaya yaz (150'lik partiler)
for($i2=0; $i2 -lt $yeni.Count; $i2 += 150){
  $dl = @($yeni[$i2..([Math]::Min($i2+149,$yeni.Count-1))])
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $HW -ContentType "application/json; charset=utf-8" `
      -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $dl -Depth 6))) -TimeoutSec 120 | Out-Null
    $ozet.uretilen += $dl.Count
  } catch {
    $ozet.yazmaHatasi += $dl.Count
    # 29.07: ilk parti 400 dondu ve SEBEBI GORULEMEDI - 147 soru cope gitti.
    # Sunucunun ne dedigini yakalamadan tekrar denemek, ayni parayi ikinci kez
    # yakmaktir. Artik hata GOVDESI ve ornek satir loga yaziliyor.
    $cev = ""
    $cev = HataGovde $_
    Write-Host ("YAZMA HATASI: {0}" -f $_.Exception.Message)
    if($cev){ Write-Host ("SUNUCU CEVABI: {0}" -f $cev.Substring(0,[Math]::Min(600,$cev.Length))) }
    # 29.07 ASIL SEBEP: PostgREST toplu yazimda TEK BOZUK SATIR yuzunden
    # BUTUN PARTIYI reddediyor. 5 satirlik kuru deneme gecti, 147 satirlik
    # parti gecmedi - sorun sayida degil, aradaki bir satirdaydi. 147 saglam
    # soru bir tanesi yuzunden cope gitti.
    # Artik parti dusunce SATIR SATIR yeniden denenir: saglamlar kurtulur,
    # bozuk olan ISIMLENDIRILIR.
    Write-Host "  parti dustu -> satir satir yeniden deneniyor..."
    foreach($tek in $dl){
      try {
        Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $HW -ContentType "application/json; charset=utf-8" `
          -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($tek) -Depth 6))) -TimeoutSec 60 | Out-Null
        $ozet.uretilen++; $ozet.yazmaHatasi--
      } catch {
        $g = HataGovde $_
        $red.Add([pscustomobject]@{ konu="$($tek.konu)"; sebep='yazilamadi'; deger=$g.Substring(0,[Math]::Min(200,$g.Length)) })
        Write-Host ("    BOZUK SATIR [{0}]: {1}" -f $tek.konu, $g.Substring(0,[Math]::Min(220,$g.Length)))
      }
    }
  }
}

$gercek = (($gG/1e6*3.0)+($gC/1e6*15.0))/2
Write-Host ""
Write-Host "======== URETIM ========"
foreach($k in $ozet.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ozet[$k]) }
Write-Host ("  GERCEK FATURA: ~{0:N2} USD" -f $gercek)
Write-Host "  NOT: uretilen sorularin HEPSI yayin=false. Profesor + GM onayi olmadan ogrenciye gitmez."
$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/uretim-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; hazirlik=$ist; ozet=$ozet
  fatura=[ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($gercek,2) }
  redler=@($red | Select-Object -First 60)
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try{Stop-Transcript|Out-Null}catch{}
exit 0
