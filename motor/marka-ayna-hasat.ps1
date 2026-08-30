# ============================================================================
#  MARKA AYNASI — HASAT  (29.08.2026)
#  Cem: "kendi aynamiz kuralim bir yere bagimli olmayalim... gunluk
#  guncellememizi yaparsak bundan sonra hep dogru gitmis oluruz."
#
#  NE YAPAR: TURKPATENT sicilini (TMview uzerinden) KENDI veritabanimiza
#  kopyalar. Bittiginde unvan aramasi TMview'e gitmez, ANLIK SQL olur:
#  kuyruk yok, bekleme yok, CORS yok, kaynak duserse urun durmaz.
#
#  ── 29.08 OLCULEN GERCEKLER (tasarimin tamami bunlara dayaniyor) ──────────
#  · toplam TR kaydi ......... 2.820.840   (tescilli 573.303)
#  · pageSize TAVANI ......... 100         (200/300/500 -> HTTP 400)
#  · page*pageSize <= 10.000 . sayfa 101 BOS doner (ES max_result_window)
#  · siralama parametresi .... `desc`  (`sortDesc` SESSIZCE yok sayilir)
#  · TARIH DILIMI ............ fADateRanges: ["2026-01-01..2026-06-30"]
#      DIZI + "baslangic..bitis" METNI. Baska hicbir bicim kabul edilmiyor:
#      duz metin, {from,to}, {startDate,endDate}, epoch, gg.aa.yyyy -> HEPSI 400.
#      Bu tek satir aynanin mumkun olmasini sagliyor; 10.000 tavani ancak
#      tarihle dilimlenerek asilir.
#  · olculen yogunluk ........ bir ay ~10.787 (tavana deger), bir gun ~652
#
#  ── OZYINELEMELI DILIMLEME ────────────────────────────────────────────────
#  Sabit "aylik dilim" YETMEZ (Agustos 2026 = 10.787 > 10.000). Bu yuzden
#  dilim ADAPTIF: bir aralik $Esik'i asiyorsa IKIYE BOLUNUR, altina inene
#  kadar. Boylece yogun donemde gune, seyrek donemde yila kadar acilir ve
#  hicbir dilim tavana carpmaz. Yogunluk yillara gore 8 kat degisiyor
#  (1900-1994: 114 bin · 2020-2024: 894 bin) - sabit dilim ya kayip verir
#  ya bos istek yakar.
#
#  ── KALDIGI YERDEN DEVAM ──────────────────────────────────────────────────
#  2,8 milyon kayit ~28.200 istek demek; tek kosuda bitmez. Her dilim
#  marka_ayna_dilim tablosuna yazilir (bekliyor/bitti/hata). Robot her gece
#  bekleyen dilimlerden $DilimBasi kadarini alir. Kesinti veri kaybettirmez.
#
#  ── GUNLUK GUNCELLEME ─────────────────────────────────────────────────────
#  -Gunluk modu: yalniz son $GunlukGun gunun basvurularini tazeler. Backfill
#  bittikten sonra aynayi ayakta tutan sey budur.
#
#  MALIYET 0 USD: kimlik yok, CAPTCHA yok, API ucreti yok.
#  ENV: SUPABASE_SERVICE_KEY (yazma icin zorunlu)
#
#  Kullanim:
#    ./motor/marka-ayna-hasat.ps1 -Plan                 (dilim planini kur, veri cekme)
#    ./motor/marka-ayna-hasat.ps1 -DilimBasi 40         (bekleyen dilimleri isle)
#    ./motor/marka-ayna-hasat.ps1 -Gunluk               (son gunleri tazele)
#    ./motor/marka-ayna-hasat.ps1 -Kuru -Bas 2026-08-01 -Son 2026-08-31   (sinav)
# ============================================================================
param(
  [switch]$Plan,                  # dilim planini kur/tazele
  [switch]$Gunluk,                # gunluk tazeleme modu
  [switch]$Kuru,                  # Supabase'e YAZMA, yalniz olc
  [string]$Bas = '',              # kuru sinav icin aralik
  [string]$Son = '',
  [int]$DilimBasi = 25,           # bir kosuda islenecek dilim sayisi
  [int]$Esik = 9000,              # dilim bu sayiyi asarsa IKIYE bolunur (tavan 10.000)
  [int]$GunlukGun = 10,
  [int]$BeklemeMs = 1200,      # 30.08: 300 ms bot korumasini tetikledi
  [int]$YazmaParti = 500,
  [int]$IstekTavan = 3000        # bir kosuda TMview e en fazla kac istek
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/marka-ayna-raporu.json'
$TMV = 'https://www.tmdn.org/tmview/api/search/results?translate=true'
$TH  = @{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36'
          'Referer'='https://www.tmdn.org/tmview/'; 'Accept'='application/json' }
$ALANLAR = @('tmName','applicationNumber','applicationDate','registrationDate','tradeMarkStatus','niceClass','applicantName','ST13')
$SB_URL = if($env:SUPABASE_URL){ $env:SUPABASE_URL } else { 'https://bjrleanjpyujtajmazxn.supabase.co' }
$SB_KEY = "$env:SUPABASE_SERVICE_KEY"
$API = "$SB_URL/rest/v1"
$SB = @{ apikey=$SB_KEY; Authorization=("Bearer " + $SB_KEY); 'Content-Type'='application/json' }

# --- ortak yardimcilar ------------------------------------------------------
# Turkce harf katlama: hashtable KULLANILMAZ - PowerShell hash anahtarlari
# buyuk/kucuk harf ayirmadigi icin 'Ç' ile 'ç' cakisiyor ve betik parse
# edilmiyor. Iki paralel dizi + IndexOf ORDINAL calisir, kulture bagli degildir.
$script:HARF_K = 'ÇçĞğİIıiÖöŞşÜüÂâÎîÛû'
$script:HARF_H = 'ccggiiiioossuuaaiiuu'
function JsonMu($t){ $s = "$t".TrimStart(); return ($s.StartsWith('{') -or $s.StartsWith('[')) }
function Norm([string]$s){
  # 30.08 - CI'da OZ-SINAV bu islevi DUSURDU: "arcelkanonmsrket" (butun i'ler
  # kayip). Sebep .NET globalizasyon farki: Windows'ta 'İ'.ToLower() = 'i',
  # Linux/ICU'da 'i' + U+0307 (ayri birlesen nokta). Eski surum bu ikinci
  # bicimi karsilayamiyordu ve harfi komple siliyordu.
  # Duzeltilmeseydi ayna 2,8 milyon sahip adini YANLIS normalize edecek,
  # unvan aramasi hicbir zaman tutmayacakti - hem de sessizce.
  # Artik kulture HIC guvenilmiyor: harfler elle esleniyor, gerisi ASCII
  # kucultmeden geciyor, kalan her sey (birlesen isaretler dahil) atiliyor.
  # SQL tarafiyla ayni sonucu verir (lower + translate + [^a-z0-9] temizligi).
  if([string]::IsNullOrEmpty($s)){ return '' }
  $sb = New-Object Text.StringBuilder
  foreach($ch in $s.ToCharArray()){
    $i = $script:HARF_K.IndexOf($ch)
    if($i -ge 0){ [void]$sb.Append($script:HARF_H[$i]); continue }
    $c = [char]::ToLowerInvariant($ch)
    if(($c -ge 'a' -and $c -le 'z') -or ($c -ge '0' -and $c -le '9')){ [void]$sb.Append($c) }
  }
  return $sb.ToString()
}
function IsoGun($s){
  if([string]::IsNullOrWhiteSpace("$s")){ return $null }
  try{ return ([datetime]::Parse("$s",[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AdjustToUniversal)).ToString('yyyy-MM-dd') }catch{ return $null }
}
function JStr([string]$s){
  if($null -eq $s){ return 'null' }
  $t = $s -replace '\\','\\\\' -replace '"','\"' -replace "`r",'' -replace "`n",' ' -replace "`t",' '
  return '"' + $t + '"'
}
function JVal($s){ if([string]::IsNullOrWhiteSpace("$s")){ return 'null' } return (JStr "$s") }

# --- TMview cagrisi: bot korumasi freni -------------------------------------
# 30.08'de YASANDI (tahmin degil): cok istekten sonra HTTP 200 donup govdede
# engel SAYFASI geldi - hem GitHub sunucusundan hem Cem'in tarayicisindan.
# Sessizce yutulursa "bu dilimde marka yok" diye YANLIS cevap uretir ve ayna
# EKSIK dolup "bitti" diye isaretlenir. Govde JSON mu diye BAKILIR.
#
# O gun neyi yanlis yaptik: istekler arasi 300 ms + daraltilmamis detay
# zenginlestirmesi (30+ dakika ard arda istek). Uc fren birden kondu:
#   (a) istekler arasi 1,2 sn        -> $BeklemeMs
#   (b) kosu basi istek TAVANI       -> $IstekTavan
#   (c) engel gorulunce ERKEN DUR    -> inatla denemek engeli UZATIR
$script:Istek = 0
$script:Engel = $false
function TmvSorgu($govde){
  if($script:Engel){ throw 'KAYNAK ENGELI surdugu icin kosu durduruldu - bu kosuda tekrar denenmeyecek. Kaldigi yerden devam eder.' }
  if($script:Istek -ge $IstekTavan){ throw ("Kosu basi istek tavanina ulasildi (" + $IstekTavan + ") - kaynagi yormamak icin duruldu. Kaldigi yerden devam eder.") }
  $b = [Text.Encoding]::UTF8.GetBytes($govde)
  for($d=1; $d -le 3; $d++){
    try{
      $script:Istek++
      $w = Invoke-WebRequest -Uri $TMV -Method Post -Headers $TH -ContentType 'application/json' -Body $b -TimeoutSec 90 -UseBasicParsing
      $t = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
      if(-not (JsonMu $t)){
        $script:Engel = $true
        throw 'KAYNAK ENGELI: HTTP 200 geldi ama govde JSON degil (engel sayfasi). Kosu durduruluyor.'
      }
      return ($t | ConvertFrom-Json)
    }catch{
      if($script:Engel){ throw $_ }                       # engelde bekleyip tekrar deneme
      if($d -eq 3){ throw ("TMview yanit vermedi: " + $_.Exception.Message) }
      Start-Sleep -Seconds (15 * $d)
    }
  }
}
function DilimGovde($bas,$son,$sayfa,$boy){
  # DIKKAT: fADateRanges DIZI ve "bas..son" METNI olmali. Baska bicim -> 400.
  $alan = ($ALANLAR | ForEach-Object { JStr $_ }) -join ','
  return '{"page":' + $sayfa + ',"pageSize":' + $boy + ',"criteria":"C","basicSearch":"","fOffices":["TR"]' +
         ',"fADateRanges":["' + $bas + '..' + $son + '"]' +
         ',"sortColumn":"applicationDate","desc":false,"fields":[' + $alan + ']}'
}
function DilimSay($bas,$son){
  $j = TmvSorgu (DilimGovde $bas $son 1 1)
  return [int]$j.totalResults
}

# --- OZ-SINAV: karar veren betigin kendi sinavi ------------------------------
# Dilim mantigi yanlissa ayna SESSIZCE eksik dolar - en tehlikeli kusur budur.
function OzSinav(){
  $b1 = [datetime]::ParseExact('2026-01-01','yyyy-MM-dd',$null)
  $s1 = [datetime]::ParseExact('2026-01-31','yyyy-MM-dd',$null)
  $orta = $b1.AddDays([math]::Floor((($s1-$b1).TotalDays)/2))
  if($orta -lt $b1 -or $orta -ge $s1){ throw 'OZ-SINAV: ikiye bolme ortasi araligin disinda' }
  # Bolunmus iki parca, bosluk ve ortusme OLMADAN araligi kapatmali
  if($orta.AddDays(1) -gt $s1){ throw 'OZ-SINAV: ikinci parca bos kaldi' }
  if((Norm 'ARÇELİK ANONİM ŞİRKETİ') -ne 'arcelikanonimsirketi'){ throw ('OZ-SINAV: Norm yanlis -> ' + (Norm 'ARÇELİK ANONİM ŞİRKETİ')) }
  if((Norm 'Öz-Şahin & Co.') -ne 'ozsahinco'){ throw ('OZ-SINAV: Norm noktalama -> ' + (Norm 'Öz-Şahin & Co.')) }
  # 30.08: ASIL TUZAK BUYDU. Linux/ICU'da 'İ'.ToLower() tek harf DEGIL,
  # 'i' + U+0307 (birlesen nokta) uretiyor. Windows'ta uretmiyor - bu yuzden
  # kusur yerelde gorunmeyip CI'da patladi. Sinav artik AYRISIK bicimi de
  # dogruluyor, yani Windows'ta kosulan sinav Linux davranisini da kapsiyor.
  $ayrisik = 'i' + [char]0x0307 + 'stanbul'
  if((Norm $ayrisik) -ne 'istanbul'){ throw ('OZ-SINAV: ayrisik (Linux) bicim -> ' + (Norm $ayrisik)) }
  if((Norm 'ARÇELİK') -ne (Norm 'arçelik')){ throw 'OZ-SINAV: buyuk/kucuk harf ayni sonucu vermiyor' }
  if((IsoGun '2026-06-27T12:00:00.000Z') -ne '2026-06-27'){ throw 'OZ-SINAV: IsoGun yanlis' }
  return $true
}

# --- Supabase ---------------------------------------------------------------
function SbYaz($yol,$govde,$prefer){
  if($Kuru){ return }
  if(-not $SB_KEY){ throw 'SUPABASE_SERVICE_KEY yok - yazma yapilamaz (kuru kosu icin -Kuru kullan).' }
  $bsl = $SB.Clone(); if($prefer){ $bsl['Prefer'] = $prefer }
  $b = [Text.Encoding]::UTF8.GetBytes($govde)
  Invoke-WebRequest -Uri "$API/$yol" -Method Post -Headers $bsl -Body $b -UseBasicParsing -TimeoutSec 120 | Out-Null
}
function SbOku($yol){
  if(-not $SB_KEY){ return @() }
  try{
    $w = Invoke-WebRequest -Uri "$API/$yol" -Headers $SB -UseBasicParsing -TimeoutSec 90
    $t = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
    if(-not (JsonMu $t)){ return @() }
    return @($t | ConvertFrom-Json)
  }catch{
    # Kapi neden dustugunu SOYLEMELI: 404/PGRST205 = tablo yok, yani goc
    # basilmamis. Ham "404 Bulunamadi" hatasi kimseye bir sey anlatmiyor.
    $k = 0; try{ $k = [int]$_.Exception.Response.StatusCode }catch{}
    if($k -eq 404){
      throw "Ayna tablolari yok. veri/sql-marka-ayna.sql Supabase SQL Editor'de bir kez calistirilmali (marka_ayna + marka_ayna_dilim). Teyit: select * from public.marka_ayna_durum();"
    }
    throw ("Supabase okunamadi (HTTP {0}): {1}" -f $k, $_.Exception.Message)
  }
}

# --- kayitlari yaz (parti parti, upsert) ------------------------------------
function KayitYaz($liste){
  if(@($liste).Count -eq 0){ return 0 }
  $yazilan = 0
  for($i=0; $i -lt @($liste).Count; $i += $YazmaParti){
    $parca = @($liste)[$i..([math]::Min($i+$YazmaParti-1, @($liste).Count-1))]
    # PS 5.1 ConvertTo-Json ic dizileri {value,Count} icine sarar -> govde ELLE kurulur.
    $satirlar = foreach($r in $parca){
      '{"st13":' + (JStr $r.st13) + ',"no":' + (JVal $r.no) + ',"ad":' + (JVal $r.ad) +
      ',"ad_norm":' + (JVal $r.ad_norm) + ',"basvuru":' + (JVal $r.basvuru) + ',"tescil":' + (JVal $r.tescil) +
      ',"durum":' + (JVal $r.durum) + ',"sinif":' + (JVal $r.sinif) + ',"sahip":' + (JVal $r.sahip) +
      ',"sahip_norm":' + (JVal $r.sahip_norm) + ',"guncelleme":"' + (Get-Date).ToUniversalTime().ToString('o') + '"}'
    }
    SbYaz 'marka_ayna?on_conflict=st13' ('[' + ($satirlar -join ',') + ']') 'resolution=merge-duplicates,return=minimal'
    $yazilan += @($parca).Count
  }
  return $yazilan
}

# --- bir dilimi cek ---------------------------------------------------------
function DilimCek($bas,$son){
  $liste = New-Object System.Collections.Generic.List[object]
  $sayfa = 1
  while($sayfa -le 100){
    $j = TmvSorgu (DilimGovde $bas $son $sayfa 100)
    $m = @($j.tradeMarks)
    if($m.Count -eq 0){ break }
    foreach($k in $m){
      $ad = "$($k.tmName)"
      $sh = ((@($k.applicantName) | Where-Object { $_ }) -join ' · ')
      $liste.Add([pscustomobject]@{
        st13    = "$($k.ST13)"
        no      = "$($k.applicationNumber)"
        ad      = $ad
        ad_norm = (Norm $ad)
        basvuru = (IsoGun $k.applicationDate)
        tescil  = (IsoGun $k.registrationDate)
        durum   = "$($k.tradeMarkStatus)"
        sinif   = ((@($k.niceClass) | Where-Object { $null -ne $_ }) -join ',')
        sahip   = $sh
        sahip_norm = (Norm $sh)
      })
    }
    if($m.Count -lt 100){ break }
    $sayfa++
    Start-Sleep -Milliseconds $BeklemeMs
  }
  return $liste
}

# --- dilim planini kur (ozyinelemeli bolme) ---------------------------------
$script:PlanListe = New-Object System.Collections.Generic.List[object]
function PlanKur([datetime]$bas, [datetime]$son, [int]$derinlik){
  $bs = $bas.ToString('yyyy-MM-dd'); $ss = $son.ToString('yyyy-MM-dd')
  $adet = DilimSay $bs $ss
  Start-Sleep -Milliseconds $BeklemeMs
  if($adet -eq 0){ return }
  if($adet -le $Esik -or $bas -eq $son -or $derinlik -ge 12){
    if($adet -gt $Esik){
      # Tek GUN bile tavani asiyorsa o gunun bir kismi ALINAMAZ - sessiz gecme.
      Write-Host ("  UYARI: {0} tek dilimde {1} kayit (tavan 10.000) - bu dilimde kayip olabilir." -f $bs, $adet)
    }
    $script:PlanListe.Add([pscustomobject]@{ dilim = ($bs + '..' + $ss); adet = $adet })
    return
  }
  $ortaGun = [math]::Floor((($son - $bas).TotalDays) / 2)
  if($ortaGun -lt 1){ $script:PlanListe.Add([pscustomobject]@{ dilim = ($bs + '..' + $ss); adet = $adet }); return }
  $orta = $bas.AddDays($ortaGun)
  PlanKur $bas $orta ($derinlik+1)
  PlanKur $orta.AddDays(1) $son ($derinlik+1)
}

# ============================================================================
#  AKIS
# ============================================================================
OzSinav | Out-Null
Write-Host 'Oz-sinav gecti (dilim bolme + Norm + tarih).'

if($Kuru -and $Bas -and $Son){
  Write-Host ("KURU SINAV: {0}..{1}" -f $Bas, $Son)
  $adet = DilimSay $Bas $Son
  Write-Host ("  kaynak {0} kayit diyor" -f $adet)
  $l = DilimCek $Bas $Son
  Write-Host ("  cekilen {0} kayit" -f $l.Count)
  if($l.Count){
    $o = $l[0]
    Write-Host ("  ornek: {0} | {1} | basvuru {2} | durum {3} | sahip {4}" -f $o.ad,$o.no,$o.basvuru,$o.durum,$o.sahip)
    Write-Host ("  ad_norm '{0}'  sahip_norm '{1}'" -f $o.ad_norm,$o.sahip_norm)
    $bosSt13 = @($l | Where-Object { -not $_.st13 }).Count
    $bosTar  = @($l | Where-Object { -not $_.basvuru }).Count
    Write-Host ("  st13 bos: {0} · basvuru tarihi bos: {1}" -f $bosSt13,$bosTar)
    if($adet -gt 0 -and $l.Count -lt [math]::Min($adet,10000)){ Write-Host ("  DIKKAT: kaynak {0} dedi, {1} cekildi - eksik var." -f $adet,$l.Count) }
  }
  return
}

if($Plan){
  Write-Host 'DILIM PLANI kuruluyor (ozyinelemeli bolme)...'
  PlanKur ([datetime]::ParseExact('1900-01-01','yyyy-MM-dd',$null)) ([datetime]::Today) 0
  $t = ($script:PlanListe | Measure-Object -Property adet -Sum).Sum
  Write-Host ("  {0} dilim · toplam {1} kayit" -f $script:PlanListe.Count, $t)
  if(-not $Kuru){
    $satirlar = foreach($d in $script:PlanListe){ '{"dilim":' + (JStr $d.dilim) + ',"adet":' + $d.adet + ',"durum":"bekliyor"}' }
    for($i=0; $i -lt $satirlar.Count; $i += $YazmaParti){
      $p = $satirlar[$i..([math]::Min($i+$YazmaParti-1,$satirlar.Count-1))]
      SbYaz 'marka_ayna_dilim?on_conflict=dilim' ('[' + ($p -join ',') + ']') 'resolution=ignore-duplicates,return=minimal'
    }
    Write-Host '  plan yazildi.'
  }
  $rapor = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='plan'; dilim=$script:PlanListe.Count; toplam_kayit=$t }
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $rapor -Depth 4), (New-Object Text.UTF8Encoding($false)))
  return
}

if($Gunluk){
  $b = (Get-Date).Date.AddDays(-$GunlukGun).ToString('yyyy-MM-dd')
  $s = (Get-Date).Date.ToString('yyyy-MM-dd')
  Write-Host ("GUNLUK TAZELEME: {0}..{1}" -f $b,$s)
  $l = DilimCek $b $s
  $y = KayitYaz $l
  Write-Host ("  cekilen {0} · yazilan {1}" -f $l.Count, $y)
  $rapor = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='gunluk'; aralik=($b+'..'+$s); cekilen=$l.Count; yazilan=$y }
  [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $rapor -Depth 4), (New-Object Text.UTF8Encoding($false)))
  return
}

# --- varsayilan: bekleyen dilimleri isle ------------------------------------
$bekleyen = SbOku ('marka_ayna_dilim?durum=eq.bekliyor&order=dilim.asc&limit=' + $DilimBasi)
if(@($bekleyen).Count -eq 0){
  Write-Host 'Bekleyen dilim yok. (Plan kurulmadiysa: -Plan ile kur.)'
  return
}
Write-Host ("{0} dilim islenecek." -f @($bekleyen).Count)
$topCekilen = 0; $topYazilan = 0; $hatali = 0
$islenen  = 0
$durduran = $null
foreach($d in $bekleyen){
  # DIKKAT: .Split('..') .NET'te KARAKTER dizisi olarak yorumlanir (nokta nokta
  # degil, "nokta"lar). Regex bolme kullaniliyor ki dilim metni her zaman
  # dogru ikiye ayrilsin.
  $p = [regex]::Split("$($d.dilim)", '\.\.') | Where-Object { $_ }
  if(@($p).Count -lt 2){ Write-Host ("  {0}: dilim metni okunamadi, atlandi." -f $d.dilim); continue }
  $bas = $p[0]; $son = $p[1]
  try{
    $l = DilimCek $bas $son
    $y = KayitYaz $l
    $topCekilen += $l.Count; $topYazilan += $y
    if(-not $Kuru){
      SbYaz 'marka_ayna_dilim?on_conflict=dilim' ('[{"dilim":' + (JStr $d.dilim) + ',"adet":' + [int]$d.adet + ',"cekilen":' + $l.Count + ',"durum":"bitti","guncelleme":"' + (Get-Date).ToUniversalTime().ToString('o') + '"}]') 'resolution=merge-duplicates,return=minimal'
    }
    Write-Host ("  {0}: {1} kayit" -f $d.dilim, $l.Count)
  }catch{
    # KAYNAK ENGELI / ISTEK TAVANI DILIMIN SUCU DEGIL. "hata" diye damgalarsak
    # dilim denemesini bosuna yakar, tekrar tekrar denenirse listeden dusebilir.
    # Bu iki durumda dilim BEKLIYOR kalir ve kosu SESSIZCE degil, ACIKCA durur.
    if($script:Engel -or $script:Istek -ge $IstekTavan){
      $durduran = $_.Exception.Message
      Write-Host ("  DURDURULDU: {0}" -f $durduran)
      Write-Host ("  {0} dilim islendi, kalanlar 'bekliyor' olarak DURUYOR - veri kaybi yok." -f $islenen)
      break
    }
    $hatali++
    Write-Host ("  {0}: HATA - {1}" -f $d.dilim, $_.Exception.Message)
    if(-not $Kuru){
      SbYaz 'marka_ayna_dilim?on_conflict=dilim' ('[{"dilim":' + (JStr $d.dilim) + ',"durum":"hata","deneme":' + ([int]$d.deneme + 1) + ',"guncelleme":"' + (Get-Date).ToUniversalTime().ToString('o') + '"}]') 'resolution=merge-duplicates,return=minimal'
    }
  }
  $islenen++
  Start-Sleep -Milliseconds $BeklemeMs
}
$rapor = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='dilim'; islenen=$islenen; cekilen=$topCekilen; yazilan=$topYazilan; hatali=$hatali; istek=$script:Istek; durduran=$durduran }
[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $rapor -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("BITTI: {0}/{1} dilim · {2} kayit cekildi · {3} yazildi · {4} hata · {5} istek" -f $islenen, @($bekleyen).Count, $topCekilen, $topYazilan, $hatali, $script:Istek)
if($durduran){ Write-Host ("DURDURAN SEBEP: " + $durduran) }
