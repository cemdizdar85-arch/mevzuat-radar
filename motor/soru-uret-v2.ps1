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
  [ValidateSet('SMMM','SGS','KGK')]   # 02.08: KGK hatti eklendi (kota dosyasi vardi, kapi kapaliydi)
  [string]$sinav = 'SMMM',
  # Uretilen sorunun hangi EMIRDEN (dolayisiyla hangi receteden) ciktigi
  # kasaya yazilir. Pilot-1 ile Pilot-2 ayni gun kostu ve damgalari ayniydi;
  # sonucta "onarim tuttu mu" sorusu olculemedi cunku ornekler ayrilamadi.
  [string]$emirNo = '0',
  # 05.08 (Cem: "bos+eksik konulara uretim"): virgullu KONU listesi verilirse
  # plan yalniz o konulara filtrelenir; bos ise davranis eskisiyle BIREBIR ayni.
  # Karsilastirma Turkce-bagimsiz sadelestirmeyle yapilir (bu haftanin bes
  # I/i tuzagi dersinden sonra kulturlu karsilastirma YASAK).
  [string]$konular = '',
  # 29.07 KURTARMA MODU: virgullu batch kimligi listesi (parti sirasiyla:
  # ilk kimlik = u0, ikinci = u1...). Verilirse YENI BATCH GONDERILMEZ -
  # bu kimliklerin SONUCLARI cekilir (GET ucretsizdir, ucret parti islenirken
  # odenmistir) ve normal yedi kapidan gecirilip kasaya yazilir.
  # Neden var: emir #14'te 9 parti (1.782 sonuc, ~35 USD) gonderildi, islendi
  # ve betik kasaya yazamadan aylik tavana (429) carpti. Sonuclar Anthropic'te
  # 29 gun duruyor - yeniden uretmek ayni parayi IKINCI kez odemek olurdu.
  # HIZA RISKI ve SIGORTASI: isler listesi ayni kota+kasa'dan yeniden kurulur;
  # kurulum kayarsa custom_id -> isler eslesmesi bozulur. Bunu rakam kapisi
  # yakalar (metin-sayi karsilastirmasi isler[gi].metin'e karsi calisir) -
  # kurtarmada rakamRed orani %20'yi asarsa hasat KIRMIZI kesilir, kasaya
  # tek satir yazilmaz.
  [string]$kurtarPartiler = ''
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# ============================================================================
#  THP LISTESI — 03.08, Cem'in "253 personel avansi" bulgusunun kok ilaci.
#
#  Uretici dayanak olarak KANUN maddesini veriyordu; kanun metninde hesap kodu
#  YOKTUR. Yevmiye istenince model kodu tek bulabildigi yerden yazdi: kendi
#  hafizasi. "Metinde olmayan rakami yazma" kurali, metinde HIC olmayan bir
#  boyutu koruyamadi. Olcum: kasada 1.009 soruda kod-ad uyusmazligi.
#
#  Cozum: resmi kod->ad listesi HER isteme dayanagin yanina eklenir (kisa:
#  ~199 satir "kod AD" cifti, ~6 KB). Artik hesap kodunun da birincil kaynagi
#  istemin icinde ve kural ona baglanabiliyor.
# ============================================================================
$script:THP_LISTE = ''
# 03.08 - TUM msugt dosyalari. Tek dosya (msugt-thp-tam) 199 hesap tasiyor ve
# 100 KASA / 102 BANKALAR / 600 YURTICI SATISLAR / 730 GENEL URETIM GIDERLERI
# ICERMIYOR. Uretici EKSIK liste ile calisirsa, kullanmasi gereken kod listede
# olmadigi icin model yine hafizadan yazar - onlemek istedigimiz seyin ta kendisi.
$gorulenKod = @{}
$ciftler = New-Object System.Collections.Generic.List[string]
foreach($tf in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $thpVeri = Get-Content $tf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($thpVeri.belgeler)){
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $gorulenKod.ContainsKey($m.Groups[1].Value)){
        $gorulenKod[$m.Groups[1].Value] = 1
        $ciftler.Add(($m.Groups[1].Value + ' ' + $m.Groups[2].Value.Trim()))
      }
    }
  } catch { Write-Host ("THP dosyasi okunamadi: {0}" -f $tf.Name) }
}
if($ciftler.Count -ge 50){ $script:THP_LISTE = ($ciftler | Sort-Object) -join "`n" }
Write-Host ("THP listesi: {0} hesap kodu isteme eklenecek (tum msugt dosyalari)." -f $ciftler.Count)
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
$kotaDosya = if($sinav -eq 'SGS'){ "veri/sgs-uretim-kotasi.json" }
             elseif($sinav -eq 'KGK'){ "veri/kgk-uretim-kotasi.json" }   # 01.08 Cem onayi: KGK temel alan hatti
             else { "veri/uretim-kotasi.json" }
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
  # 29.07 aksam: STD ve THP burada DISLANIYORDU. Sonucu SGS pilotunda gorundu -
  # "TMS 40" hic aday olamadigi icin o konu VUK m.275'e (imal edilen emtia)
  # baglandi. Artik disarida degiller; KaynakBul zaten once dogrudan standart
  # ve hesap plani yollarini deniyor, bu harita da onlari aday olarak tutuyor.
  foreach($w in (Kel "$($k.konu)")){
    if(-not $kelMadde.ContainsKey($w)){ $kelMadde[$w]=@{} }
    $anahtar = "$($k.kanun_no)|$($k.madde_no)"
    $kelMadde[$w][$anahtar] = 1 + [int]$kelMadde[$w][$anahtar]
  }
}
Write-Host ("  konu-kelime indeksi: {0} kelime" -f $kelMadde.Count)

# ============================================================================
#  MADDE TAVANI — Cem onayi 02.08.2026 (%2)
#
#  40 soruluk insan denetiminde cikan bulgu: 40 sorunun 23'u YALNIZ 4 maddeden
#  yazilmisti (VUK m.275: 12, Is K. m.11: 4, TTK m.720: 4, TTK m.516: 3). Konu
#  tavani (12) vardi ama MADDE tavani yoktu; ucu ayri gorunen konu ("bilanco
#  pasif degisimi", "trend analizi", "basit dagitim yontemi") ayni maddeye
#  baglaniyor ve ayni kural kilik degistirerek tekrar ediyordu.
#
#  KURAL: tek madde, hedef havuzun %2'sinden fazlasini yazamaz.
#  Agirlik KONUDA kalir (Cem karari degismedi) - tavan yalniz kaynaga konur.
#  Tavana takilan satir SESSIZCE ATILMAZ: rapora dokulur, cunku o konu ya baska
#  bir maddeye baglanmali ya da o madde artik yeni soru vermemeli.
# ============================================================================
$MADDE_TAVAN_YUZDE = 2.0
$hedefHavuz = 0
foreach($alan in @('hedef','hedef_havuz','hedef_soru')){
  if($kota.PSObject.Properties[$alan] -and [int]$kota.$alan -gt 0){ $hedefHavuz = [int]$kota.$alan; break }
}
if($hedefHavuz -le 0){ $hedefHavuz = $kasa.Count }
$maddeTavani = [math]::Max(10, [math]::Ceiling($hedefHavuz * $MADDE_TAVAN_YUZDE / 100))
$maddeMevcut = @{}
foreach($k in $kasa){
  if(-not $k.kanun_no -or -not $k.madde_no){ continue }
  $a = "$($k.kanun_no)|$($k.madde_no)"
  $maddeMevcut[$a] = 1 + [int]$maddeMevcut[$a]
}
$doluMadde = @($maddeMevcut.GetEnumerator() | Where-Object { [int]$_.Value -ge $maddeTavani })
Write-Host ("  MADDE TAVANI: hedef havuz {0} x %{1} = {2} soru/madde | tavani dolmus madde: {3}" -f $hedefHavuz, $MADDE_TAVAN_YUZDE, $maddeTavani, $doluMadde.Count)
foreach($d in ($doluMadde | Sort-Object Value -Descending | Select-Object -First 5)){
  Write-Host ("    dolu: {0} -> {1} soru" -f $d.Key, $d.Value)
}

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

# ============================================================================
#  29.07 AKSAM - SGS PILOTUNUN BULGUSU (asil kusur burasiydi)
#
#  40 pilot sorusunun TAMAMI yalnizca BES maddeye atif yapiyordu ve cogu
#  konuyla ilgisizdi:
#    "tms 40 yatirim amacli gayrimenkul"   -> VUK m.275 (imal edilen emtia)
#    "tms 36 deger dusuklugu kapsami"      -> VUK m.275
#    "satis iskontosu kaydi"               -> TTK m.720 (cek hukumleri)
#    "kademeli dagitim yontemi"            -> VUK m.275
#    "finansal raporlama degerlendirmesi"  -> 5018 Kamu Mali Yonetimi K. m.3
#
#  SEBEP: konu->kaynak haritasi kasadaki sorularin kanun_no/madde_no
#  alanlarindan kuruluyor ve yukaridaki dongu STD ile THP'yi ACIKCA disliyordu.
#  Yani "TMS 40" ya da "THP 611" hicbir zaman ADAY olamiyordu; model de elindeki
#  en yakin KANUN maddesine tutunuyordu.
#
#  BU SADECE "yanlis kaynak yazisi" DEGIL: dayanak metni alakasiz olunca model
#  soruyu fiilen HAFIZASINDAN yaziyor. Bu gece tesbit edilen en tehlikeli hata
#  turu tam buydu - soru kaynakli GORUNUR ama kaynaksizdir, bicim kapilarinin
#  hepsinden gecer. Pilotta okudugum iki sorudan birinde cevap yanlisti.
#
#  AMBARDA HEPSI ZATEN VAR: tms40.json, tms36.json, msugt-thp-tam.json
#  (199 hesap), 30 BDS standardi. madde-coz.ps1 bunlari okuyabiliyor
#  (StandartMetni / HesapPlaniMetni). Eksik olan tek sey ADAY URETIMIYDI.
# ============================================================================

# --- THP hesap adi indeksi (bir kez cekilir; 199 kayit, ucuz)
$thpAd = @{}
try {
  $tr = Invoke-RestMethod -Uri ("$SB_URL/rest/v1/dokumanlar?select=kaynak_ad&kaynak_ad=imatch." + [uri]::EscapeDataString('^THP\s\d') + "&limit=400") -Headers $H -TimeoutSec 60
  foreach($t in @($tr)){
    if("$($t.kaynak_ad)" -match '^THP\s+(\d{2,3})\s*-?\s*(.*)$'){
      $kod = $Matches[1]; $ad = $Matches[2]
      foreach($w in (Kel $ad)){
        if(-not $thpAd.ContainsKey($w)){ $thpAd[$w] = @{} }
        $thpAd[$w][$kod] = 1 + [int]$thpAd[$w][$kod]
      }
    }
  }
  Write-Host ("  THP hesap indeksi: {0} kelime, {1} kayit" -f $thpAd.Count, @($tr).Count)
} catch { Write-Host ("  THP indeksi kurulamadi: {0}" -f $_.Exception.Message) }

# Konuyu SIRAYLA uc kaynak turunde arar; ilk kesin bulunani dondurur.
# Sira onemli: standart adi konuda ACIKCA yaziyorsa tahmine gerek yok.
function KaynakBul([string]$konu, [string]$ders){
  # 1) DOGRUDAN STANDART - konu "tms 40", "tfrs 15", "bds 500" iceriyor
  if($konu -match '(?i)\b(TMS|TFRS|BDS)\s*(\d{1,3})\b'){
    $s = StandartMetni ("{0} {1}" -f $Matches[1].ToUpperInvariant(), $Matches[2])
    if($s -and $s.metin){ return [pscustomobject]@{ kanun='STD'; madde=$s.standart; ad=$s.ad; metin=$s.metin; tur='standart' } }
  }
  # 2) TEKDUZEN HESAP PLANI - konu bir hesap adini isaret ediyor mu
  #    Olcut kanun tarafiyla ayni: TEK kelimenin tutturmasi eslesme sayilmaz
  #    ("gider" onlarca hesapta gecer).
  if($thpAd.Count -gt 0){
    $sk=@{}; $skKel=@{}
    foreach($w in (Kel $konu)){
      if(-not $thpAd.ContainsKey($w)){ continue }
      foreach($p in $thpAd[$w].GetEnumerator()){
        $sk[$p.Key] = [int]$sk[$p.Key] + $p.Value
        if(-not $skKel.ContainsKey($p.Key)){ $skKel[$p.Key]=@{} }
        $skKel[$p.Key][$w] = 1
      }
    }
    if($sk.Count -gt 0){
      $enh = ($sk.GetEnumerator() | Sort-Object {-$_.Value} | Select-Object -First 1)
      if($skKel[$enh.Key].Count -ge 2){
        $h = HesapPlaniMetni ("MSUGT Tekduzen Hesap Plani - {0}" -f $enh.Key)
        if($h -and $h.metin){ return [pscustomobject]@{ kanun='THP'; madde=$enh.Key; ad=$h.ad; metin=$h.metin; tur='hesap-plani' } }
      }
    }
  }
  # 3) KANUN MADDESI - eski yol
  $anahtar = MaddeBul $konu
  if(-not $anahtar){ return $null }
  $par = $anahtar -split '\|'
  $seri=''; $mn="$($par[1])"
  if($mn -match '^(gec|ek|muk)(\d+)$'){ $seri=$Matches[1]; $mn=$Matches[2] }
  $m = MaddeMetni "$($par[0])" $mn $seri
  if(-not $m -or -not $m.metin){ return $null }
  return [pscustomobject]@{ kanun=$par[0]; madde=$par[1]; ad=$m.ad; metin=$m.metin; tur='kanun' }
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
$(if($script:THP_LISTE -ne ''){ @"

=== TEKDUZEN HESAP PLANI (resmi kod listesi) ===
$($script:THP_LISTE)
=== HESAP PLANI BITTI ===
HESAP KODU KURALI (03.08 - Cem'in 253 bulgusu): yevmiye, hesap adi veya hesap
kodu yazacaksan YALNIZCA yukaridaki resmi listeden yaz. Listede olmayan kod
KULLANMA. Kod ile adin eslesmesi listeyle birebir ayni olacak - "253 Personel
Avanslari" gibi bir eslesme yazmak (253 listede TESIS, MAKINE VE CIHAZLAR'dir)
soruyu COPE atar. Emin degilsen kodu yazma, yalniz hesap adini yaz.
"@ })
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
- KURU KALIP SENARYO. Vaka/hesap sorularinda olay GERCEK HAYATTAN alinmis gibi
  hissettirsin - okuyani soruya BAGLASIN: "Kayseri'de mobilyaci Ramazan Usta,
  oglunun dugunu icin kasadan cektigi 38.500 TL'yi gider yazdi" gibi. Meslegin
  gunluk halleri (geciken tahsilat, unutulan beyanname, ortak kavgasi, yanlis
  kesilen fatura) somut ve canli anlatilsin - ama SORU GOVDESINDE SAKA/ESPRI
  YOK: gercek sinav sorusu kurudur, bizimki de sinav sesinde kalir (ABD kurali:
  UWorld/Becker soruda ciddi, ogretirken renkli). GULUMSETEN dokunusun yeri
  ACIKLAMANIN "Akilda kalsin" kismidir: hafiza kancasi, kisa canli benzetme,
  hafif espri orada serbest (her soruda degil - dogal geldiginde).
Hedef: TESMER kitapciginda bu sorunun yanina bir gercek cikmis soru konsa,
hangisinin bizim oldugu ANLASILMASIN.

MUTLAK KURALLAR:
1. Soru YALNIZCA yukaridaki dayanak metne dayanacak. Metinde YAZMAYAN hicbir rakam, oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin degilsen sayi verme.
2. BES sik (A-E), TAM OLARAK BIRI dogru. Digerleri makul ama acikca yanlis olmali - "neredeyse dogru" sik yazma.
3. Cikmis sinav sorusu KOPYALAMA. Ozgun yaz.
4. Istenen KURGUYA sadik kal. "bilgi" istendiyse hesap sorusu yazma.
5. HESAP/KAYIT DENGESI (500-okumasi dersi: 1.597 vs 1.629,61 vakasi): hesap
   sorusunda dogru sikkin rakami, dogru sik aciklamasindaki formulden ADIM ADIM
   birebir cikacak - once formulu yaz, sonra sikka o sonucu koy. Yevmiye
   yazarsan BORC TOPLAMI = ALACAK TOPLAMI olacak; dengesiz yevmiye COPTUR.
   Her YANLIS sikkin rakami da TANIMLI TEK BIR hatadan uretilecek (orn.
   "tesvik dusulmemis", "KDV matraha katilmis", "kist ay atlanmis") ve o hata
   sikkin aciklamasinda adlandirilacak. Hicbir formule oturmayan "rastgele"
   rakamli celdirici YASAK.
6. ZAMANSIZ TASARIM (yil-esik vakalari: 2019 tarifesiyle 2024 sorusu):
   yila bagli oran/esik/tarife kullanacaksan degeri SORU GOVDESINDE acikca ver
   ("ilgili yil icin esik 25.000 TL'dir" gibi) YA DA senaryo yilini dayanak
   metnindeki degerin yiliyla ayni yap. Mevzuat guncellenince eskiyecek soru
   kurma.
   SENARYO YILI YAKIN OLACAK (03.08, Cem: "eski yil sanki sorular eskiden
   kalmis hissi veriyor"): senaryo tarihi ICINDE BULUNULAN YIL ya da BIR ONCEKI
   YIL olsun; gelecek tarih ASLA. Ama tarihi yenilemek TEK BASINA yetmez -
   TARIH ILE RAKAM BIRBIRINI TUTACAK. Senaryoda kur, had, asgari ucret, tarife
   gibi yila bagli bir deger geciyorsa o deger senaryo yiliyla uyumlu olmali.
   Uyumlu bir deger bilmiyorsan IKI SECENEK var: (a) degeri soru govdesinde
   "verilmis veri" olarak sun ve senaryoyu ona gore kur, (b) yila bagli deger
   gerektirmeyen bir senaryo yaz. UYDURMA DEGER YAZMA.
   (Vaka: "18 Aralik 2024" tarihli senaryoda kur 28,70 TL/EUR verilmisti - o
   tarihe ait gorunmuyor; dikkatli aday takilir.)
6b. SENARYO ADLARI TEKRARLAMAYACAK (04.08 olcumu, Cem'in bulgusu).
   OLCUM: kasada 88 farkli kisi adi var AMA "Mehmet" 2.061 soruda (%7,5);
   973 farkli sirket adi var AMA "Yildirim" 2.195 soruda (%8). Yani her 12
   sorudan birinde "Yildirim" geciyor - 50 soruluk deneme cozen aday onu
   DORT KEZ gorur. Bu, hatadan cok ele veren MAKINE IZIDIR.
   KURAL: asagidaki adlari KULLANMA (asiri kullanilmis):
     Kisi   : Mehmet, Fatma, Hatice, Ayse, Ahmet
     Sirket : Yildirim, Yilmaz, Yildiz, Karadeniz, Demir, Demirhan
   Bunlarin yerine Turkiye'de yaygin AMA bu listede olmayan adlardan sec ve
   HER SORUDA FARKLI bir ad kullan. Sirket unvanini da cesitlendir: sektor
   (Mermer, Ambalaj, Lojistik, Seracilik...), sehir (Denizli, Corum, Manisa...)
   ve tur (Ltd. Sti., A.S., Koll. Sti.) birlesimlerini degistir.
   "ABC/XYZ Ticaret" gibi PLACEHOLDER unvan zaten yasak (yapisal kapi tutuyor).
7. KAYNAK ETIKETI ASIL PARAGRAF OLACAK (Q498 dersi): sorunun dayandigi kaynagi
   yazarken "p.1 - Amac" gibi GENEL bir etiket KULLANMA; kuralin gectigi ASIL
   madde/paragraf numarasini yaz (orn. "TMS 8 p.32-38" ya da "TMS 16 p.61").
   Genel etiket, hakemin yanlis metne bakmasina ve hatanin ONAYLANMASINA yol
   acti - bu yuzden genel etiketli soru supheli sayilir.

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

DOGRUSU CUMLESI - ZORUNLU (02.08.2026, Cem karari: "yanlis siklara da 'dogrusu
budur' ekle"): Her YANLIS sik aciklamasi, tuzagi adlandirdiktan sonra
"Dogrusu: ..." ile BITECEK. Bu cumle, o sikki isaretleyen adaya DOGRU KURALI
tek cumlede verir - cunku ogretilmesi gereken asil kisi yanlis yapandir.
Kalibi: "TUZAK: ... Dogrusu: <dayanak metne dayali tek cumle>."
Ornek: "TUZAK: alacakli cagrisi sirketin kar-zarar durumuna baglaniyor.
Dogrusu: cagri genel kuraldir; yalnizca zarari kapatmak icin yapilan
azaltimda cagridan vazgecilebilir."
"Dogrusu:" cumlesi de YALNIZCA dayanak metne dayanacak; metinde olmayan
rakam/oran/sure verilmeyecek. Toplam 150-320 karakter.

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
# 01.08 Cem: "yutmadigimiz konuda soru cikarsa sikinti yasamayalim" - kaynaksiz
# atlanan konular artik GORUNUR: dokum rapora yazilir, yutma listesi buradan beslenir.
$maddesizListe = New-Object System.Collections.Generic.List[object]
# tavana takilan satirlar GORUNUR olsun (sessiz atlama yasak)
$tavanListe = New-Object System.Collections.Generic.List[object]
$ist.tavanDolu = 0
# --- 05.08 KONU FILTRESI (Turkce-bagimsiz anahtar; bkz. param aciklamasi) ---
$HARF_KF = @{ [char]0x0130='I';[char]0x0131='I';[char]'i'='I';[char]'I'='I'; [char]0x015E='S';[char]0x015F='S'
              [char]0x011E='G';[char]0x011F='G'; [char]0x00DC='U';[char]0x00FC='U'; [char]0x00D6='O';[char]0x00F6='O'
              [char]0x00C7='C';[char]0x00E7='C' }
function KonuAnahtar([string]$t){
  if($null -eq $t){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($c in $t.ToCharArray()){
    if($HARF_KF.ContainsKey($c)){ [void]$sb.Append($HARF_KF[$c]); continue }
    $u = [char]::ToUpperInvariant($c)
    if(($u -ge 'A' -and $u -le 'Z') -or ($u -ge '0' -and $u -le '9')){ [void]$sb.Append($u) } else { [void]$sb.Append(' ') }
  }
  return (($sb.ToString()) -replace '\s+',' ').Trim()
}
$konuFiltre = @{}
if("$konular".Trim() -ne ''){
  foreach($k in ("$konular" -split ',')){ $kk = KonuAnahtar $k; if($kk -ne ''){ $konuFiltre[$kk] = 1 } }
  Write-Host ("KONU FILTRESI: {0} konu" -f $konuFiltre.Count)
}

foreach($p in $plan){
  if($isler.Count -ge $sinir){ break }
  if($konuFiltre.Count -gt 0 -and -not $konuFiltre.ContainsKey((KonuAnahtar "$($p.konu)"))){ continue }
  $ist.planSatir++
  $kay = KaynakBul "$($p.konu)" "$($p.ders)"
  if(-not $kay){ $ist.maddesiz++; if($maddesizListe.Count -lt 120){ $maddesizListe.Add([pscustomobject]@{ ders="$($p.ders)"; konu="$($p.konu)" }) }; continue }
  if(-not $kay.metin){ $ist.metinsiz++; continue }
  $ist["kaynak_$($kay.tur)"] = 1 + [int]$ist["kaynak_$($kay.tur)"]
  $par = @("$($kay.kanun)", "$($kay.madde)")
  $m = $kay
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

  # --- MADDE TAVANI (Cem onayi %2): bu maddeden kac soru daha yazilabilir?
  #     Kasadaki mevcut + bu kosuda planlanan birlikte sayilir; yoksa tek kosu
  #     icinde ayni madde tavani asar. Hic yer yoksa satir ATLANIR ve rapora
  #     dusulur - o konu ya baska bir kaynaga baglanmali ya da kaynagi yutulmali.
  $tavanAnahtar = "$($par[0])|$($par[1])"
  $kullanilan = [int]$maddeMevcut[$tavanAnahtar]
  $yer = $maddeTavani - $kullanilan
  if($yer -le 0){
    $ist.tavanDolu++
    if($tavanListe.Count -lt 200){
      $tavanListe.Add([pscustomobject]@{ ders="$($p.ders)"; konu="$($p.konu)"; madde=$tavanAnahtar; mevcut=$kullanilan; tavan=$maddeTavani })
    }
    continue
  }
  if($adet -gt $yer){
    if($tavanListe.Count -lt 200){
      $tavanListe.Add([pscustomobject]@{ ders="$($p.ders)"; konu="$($p.konu)"; madde=$tavanAnahtar; mevcut=$kullanilan; tavan=$maddeTavani; kisildi=($adet - $yer) })
    }
    $adet = $yer
  }
  $maddeMevcut[$tavanAnahtar] = $kullanilan + $adet

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
if(-not $calistir){
  # 05.08: olcum yalniz ekrana basiliyordu; Actions logu kilitli oldugu icin
  # rapor dosyasina da yazilir (kor kalma). Ders dagilimi da eklenir.
  $dersDag = @{}
  foreach($i in $isler){ if(-not $dersDag.ContainsKey($i.ders)){ $dersDag[$i.ders]=0 }; $dersDag[$i.ders]++ }
  $dagListe = New-Object System.Collections.Generic.List[object]
  foreach($d in ($dersDag.Keys | Sort-Object)){ $dagListe.Add([ordered]@{ ders=$d; soru=$dersDag[$d] }) }
  Set-Content -LiteralPath (Join-Path $kok 'veri/uretim-olcum-raporu.json') -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 5 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='OLCUM (0 USD)'; sinav=$sinav; model=$model
    konu_filtresi=$konuFiltre.Count; hazirlanan_is=$isler.Count
    istem_karakter_toplam=$gk
    maliyet_tahmini_usd=[Math]::Round($tahmin,2)
    fiyat_notu='Sonnet 4.5 Batch %50: giris 3 USD/M (karakter/3 token), cikis 15 USD/M (soru basi ~1400 token varsayimi)'
    ders_dagilimi=$dagListe.ToArray()
    kaynaksiz_atlanan=$ist.maddesiz
    tavan_dolu=$ist.tavanDolu
  }))
  Write-Host "OLCUM MODU - 0 USD. Rapor: veri/uretim-olcum-raporu.json"; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }
if($isler.Count -eq 0){ Write-Host "KIRMIZI: uretilecek is yok."; exit 1 }
# PARA HARCAMADAN ONCE: yazma yolu saglam mi?
if(-not (YazmaDenemesi)){ try{Stop-Transcript|Out-Null}catch{}; exit 1 }

# --- batch
$sonuc=@{}; $gG=0; $gC=0
$PARTI=200
# KURTARMA: yeni gonderim yok; verilen kimliklerin sonuclari cekilir.
# Kimlik sirasi = parti sirasi (ilk = u0). custom_id'ler zaten u{p}_{ix}
# damgali oldugu icin $sonuc dogrudan onlarla dolar - gate dongusu ayni.
if($kurtarPartiler){
  $kListe = @($kurtarPartiler -split ',' | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
  Write-Host ("KURTARMA MODU: {0} parti kimligi - YENI GONDERIM YOK, yalniz sonuc cekme (0 USD)." -f $kListe.Count)
  $ki = 0
  foreach($kid in $kListe){
    $ki++
    Write-Host ("  parti {0}/{1}: {2}" -f $ki, $kListe.Count, $kid)
    try {
      $cev = Invoke-WebRequest -UseBasicParsing -Uri "https://api.anthropic.com/v1/messages/batches/$kid/results" -Headers $HDR -TimeoutSec 300
      $mt2 = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
      $sat0 = 0
      foreach($sat in ($mt2 -split "`r?`n")){
        if("$sat".Trim().Length -eq 0){ continue }
        try { $r = $sat | ConvertFrom-Json } catch { continue }
        if("$($r.result.type)" -ne 'succeeded'){ continue }
        $gG += [int]"$($r.result.message.usage.input_tokens)"; $gC += [int]"$($r.result.message.usage.output_tokens)"
        $jm=[regex]::Match("$($r.result.message.content[0].text)", '\{[\s\S]*\}')
        if(-not $jm.Success){ continue }
        try { $sonuc["$($r.custom_id)"] = ($jm.Value | ConvertFrom-Json); $sat0++ } catch {}
      }
      Write-Host ("    {0} sonuc alindi" -f $sat0)
    } catch {
      Write-Host ("    CEKILEMEDI: {0}" -f $_.Exception.Message)
    }
  }
  Write-Host ("KURTARMA TOPLAM: {0} sonuc" -f $sonuc.Count)
}
for($p2=0; (-not $kurtarPartiler) -and $p2 -lt [math]::Ceiling($isler.Count/$PARTI); $p2++){
  $dilim=@($isler[($p2*$PARTI)..([math]::Min(($p2+1)*$PARTI-1,$isler.Count-1))])
  $req=@(); $ix=0
  foreach($i in $dilim){ $req += @{ custom_id=("u{0}_{1}" -f $p2,$ix); params=@{ model=$model; max_tokens=2500; messages=@(@{role='user';content=$i.istem}) } }; $ix++ }
  $govde=@{requests=$req}|ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}: {1} soru" -f ($p2+1), $dilim.Count)
  $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  # ══════════════════════════════════════════════════════════════════════
  # 29.07 - ODEDIGIN ISIN KIMLIGINI KAYDET. Bu ders bu gece HAKEM hattinda
  # ~18 USD'ye ogrenildi ve profesor-v2.ps1'e uygulandi - AMA BURAYA
  # UYGULANMADI. Bedeli ayni gece odendi: emir #14'te on parti gonderildi,
  # islendi, sonuclari cekildi ve betik kasaya YAZMADAN once aylik harcama
  # tavanina (429) carpip oldu. Bellekteki sonuclar gitti ve parti
  # kimlikleri hicbir yere yazilmadigi icin BEDAVA KURTARILAMADI.
  # ~2.000 sorunun ucreti odenmis, karsiligi alinamamisti.
  # Kimlik ARTIK gonderilir gonderilmez hem loga hem dosyaya yaziliyor;
  # dosya her partide GUNCELLENIR ki kosu ortada olurse bile liste kalsin.
  # ══════════════════════════════════════════════════════════════════════
  Write-Host ("  parti kimligi: {0}" -f $b.id)
  try {
    $bpYol = Join-Path $kok 'veri/bekleyen-partiler.json'
    $bpListe = @()
    if(Test-Path $bpYol){ try { $bpListe = @(Get-Content $bpYol -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { $bpListe = @() } }
    $bpListe += [ordered]@{ id="$($b.id)"; kaynak='soru-uret-v2'; emir=$script:emirNo; sinav=$script:sinav
                            parti=($p2+1); soru=$dilim.Count; gonderildi=(Get-Date -Format 'dd.MM.yyyy HH:mm') }
    [IO.File]::WriteAllText($bpYol, (ConvertTo-Json -InputObject ([object[]]$bpListe) -Depth 5), (New-Object Text.UTF8Encoding($false)))
  } catch { Write-Host ("  UYARI: parti kimligi dosyaya yazilamadi: {0}" -f $_.Exception.Message) }
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
$ozet=[ordered]@{ uretilen=0; rakamRed=0; dilRed=0; sikRed=0; sablonRed=0; tuzakRed=0; dogrusuRed=0; atifRed=0; kokuRed=0; benzerRed=0; cevapsiz=0; yazmaHatasi=0 }
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
    # ---- DOGRUSU KAPISI (02.08, Cem karari: "yanlis siklara da 'dogrusu budur' ekle")
    # Ogretilmesi gereken asil kisi YANLIS YAPANDIR. Tuzagi adlandirmak yetmez;
    # o sikki isaretleyen aday DOGRU KURALI da ayni ekranda gormeli. Kapi
    # olmayan standart temennidir - bu yuzden makineyle denetleniyor.
    $dogrusuOlan = 0
    foreach($h in $yanlisSik){
      if("$($y.aciklama.$h)" -match '(?i)do[ğg]rusu\s*:'){ $dogrusuOlan++ }
    }
    if($dogrusuOlan -lt 3){
      $ozet.dogrusuRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='dogrusu-cumlesi-yok'; deger=("4 yanlis siktan {0}'inde 'Dogrusu:' var" -f $dogrusuOlan) }); continue
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
      # 29.07 aksam: damgaya EMIR NUMARASI eklendi. Pilot-1 ile Pilot-2'nin
      # damgasi ayniydi ("kota-v2 29.07.2026") ve ikisi de ayni gun kosunca
      # hangi sorunun hangi kosudan geldigi AYIRT EDILEMEDI - onarimin ise
      # yarayip yaramadigini olcmek icin ornekleri ayirmam gerekiyordu,
      # ayiramadim. Odenmis her sorunun hangi recete ile uretildigi kayitli
      # olmali; yoksa "duzeltme tuttu mu" sorusu bir daha cevaplanamaz.
      hap="$($y.hap)"; kaynak=$i.maddeAd
      uretim=("kota-v2 #" + $script:emirNo + " " + $script:sinav + " " + (Get-Date -Format 'dd.MM.yyyy'))
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

# KURTARMA HIZA SIGORTASI: isler listesi yeniden kuruldu ve sonuclar eski
# kosunun custom_id'leriyle eslesti. Kurulum KAYDIYSA (hashtable enumeration
# farki vb.) sorular yanlis konu/madde metadatasiyla eslesir - bunu rakam
# kapisi ele verir, cunku modelin beyan ettigi sayilar ARTIK BASKA maddenin
# metniyle karsilastiriliyor olur ve red orani firlar. Normal kosuda bu oran
# %7 civari; %20 esigi asilirsa hiza BOZUK demektir ve kasaya TEK SATIR
# yazilmaz. Yanlis metadata ile yazmak, hic yazmamaktan kotudur.
if($kurtarPartiler -and $sonuc.Count -gt 0){
  $rOran = 100.0 * $ozet.rakamRed / [Math]::Max(1, $sonuc.Count)
  Write-Host ("KURTARMA HIZA KONTROLU: rakamRed {0}/{1} = %{2:N1}  (esik %20)" -f $ozet.rakamRed, $sonuc.Count, $rOran)
  if($rOran -gt 20){
    Write-Host "KIRMIZI: hiza bozuk gorunuyor - isler listesi eski kosuyla ayni kurulmamis olabilir."
    Write-Host "Kasaya HICBIR SEY yazilmadi. Sonuclar Anthropic'te durmaya devam ediyor (29 gun)."
    try{Stop-Transcript|Out-Null}catch{}
    exit 1
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
# 02.08 KAYIP TUZAGI: ConvertTo-Json bazen TEK string yerine string DIZISI
# dondurur; WriteAllText o zaman "Argument types do not match" der ve kosu
# EN SONDA duser. KGK partisinde tam bu oldu: 1.510 soru uretilip kasaya
# yazildi (para harcandi), rapor yazilamadi ve emir DAMGALANMADI - bir sonraki
# kosu ayni parayi ikinci kez harcayacakti. Cikti tek string'e zorlanir.
$raporJson = ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; hazirlik=$ist; ozet=$ozet
  fatura=[ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($gercek,2) }
  redler=@($red | Select-Object -First 60)
  maddesiz_konular=$maddesizListe.ToArray()   # 01.08: yutma listesinin besleme kaynagi - hangi konu kaynaksiz kaldi
  madde_tavani=$maddeTavani                   # 02.08 Cem onayi: hedef havuzun %2'si
  tavana_takilan=$ist.tavanDolu               # tavan doldugu icin uretilmeyen plan satiri
  tavan_listesi=$tavanListe.ToArray()         # hangi konu hangi maddede tavana carpti (yeni kaynak yutma sirasi)

} | ConvertTo-Json -Depth 6)
if($raporJson -isnot [string]){ $raporJson = ($raporJson -join "`n") }
[IO.File]::WriteAllText($yol, [string]$raporJson, (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try{Stop-Transcript|Out-Null}catch{}
exit 0
