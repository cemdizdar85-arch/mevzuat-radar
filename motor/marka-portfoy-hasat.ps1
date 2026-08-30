# ============================================================================
#  MARKA PORTFOY HASADI (20.08.2026) - "Firma unvanindan TUM markalari".
#  Cem: "vergi numarasina gore kimin ne kadar markasi var gorebiliyor muyuz?"
#
#  OLCUM (20.08, bu betigin dayanagi):
#   * VERGI NO ile arama YOK (ne TURKPATENT ne TMview vergi no alani sunuyor).
#     Aranabilen alan SAHIP ADI (unvan) -> bu betik unvandan gider.
#   * TMview `fAName` = sahip adi filtresi (dizi = OR). ARCELIK ANONIM SIRKETI
#     -> 1.120 marka, +Registered -> 693. (Marka tarafinda `fApplicantName`
#     SESSIZCE yok sayilir - tasarim/Designs alani; yok sayilan filtre 2,8M
#     sonuc dondurur, "calisti" sanma tuzagi.)
#   * autocomplete/applicantName?text=<ad> -> ayni firmanin YAZIM VARYANTLARI
#     (Arcelik icin 15 tane). Varyantlar OR'lanmazsa portfoy EKSIK cikar.
#   * translate parametresi verilmezse durum INGILIZCE sabit gelir
#     (Filed/Registered/Ended) - robot icin dogrusu bu; Turkceye sayfa cevirir.
#   * TMview CORS'a KAPALI (tetikte.com origin'inden fetch = Failed to fetch)
#     -> tarayici dogrudan soramaz, bu yuzden robot sorar, Supabase'e yazar.
#
#  NE YAPAR:
#   1) UYE firmalari (firmalar.firma_adi) -> portfoyu cek -> marka_portfoy
#      tablosuna yaz; yenilemesine <=180 gun kalan varsa marka_uyari + mail.
#   2) VITRIN talepleri (marka_talep, durum='bekliyor') -> ayni hesabi yap ->
#      sonuc jsonb + durum='hazir'; e-posta birakildiysa raporu mail'le yolla.
#
#  HESAP (SMK m.23): koruma BASVURU tarihinden 10 yil; sonraki donem sonu =
#  basvuru + 10*n (bugunden sonraki ilk). Yenileme talebi son 6 ayda; kacarsa
#  bitisten sonra 6 ay ek sure + ek ucret (m.23/2-3). Yenilenip yenilenmedigini
#  API soylemez -> sicil durumu "Registered" ise onceki donemler yenilenmis
#  kabul edilir, metinde bu VARSAYIM oldugu yazilir (rakam disiplini).
#
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), RESEND_KEY/RESEND_FROM (opsiyonel).
#  TABLO: veri/sql-marka-portfoy.sql (bir kez Supabase SQL Editor'de kosar).
#  CIKTI: veri/marka-portfoy-raporu.json
# ============================================================================
param(
  [switch]$kuru,                 # yazma yok, yalniz olc
  [string]$Unvan = "",           # elle test: tek unvan sorgula, Supabase'e dokunma
  [int]$TalepAdet = 40,          # bir kosuda islenecek bekleyen vitrin talebi
  [int]$MaxKayit = 1500,         # unvan basina cekilecek azami marka (Arcelik 1.120 - tam kapsar)
  [int]$YenilemeGun = 180,       # kac gun kala uyari (m.23: son 6 ay)
  [int]$BeklemeMs = 200,
  [switch]$YalnizTalep,          # sik kosan kuyruk isleyici (marka-talep.yml, 10 dk)
  [switch]$YalnizUye,            # gunluk uye portfoyu tazeleme (kaynak.yml)
  [switch]$Rakip,                # rakip nobeti: marka_rakip listesini tara, YENI basvuruyu haber ver
  # 29.08 (Cem: "dusmus olabilir diyoruz ama bilmiyoruz"): detay ucu koruma
  # bitisini ve yenileme gecmisini KESIN veriyor. Marka basina 1 istek oldugu
  # icin tavanli ve varsayilan ACIK - cunku "olabilir" satilabilir bir cumle degil.
  [switch]$DetaySiz,             # detay ucunu KAPAT (hizli/nazik kosu)
  [int]$DetayTavan = 250,
  [int]$DetayBeklemeMs = 250
)
$Detay = -not $DetaySiz
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/marka-portfoy-raporu.json'
$simdi = (Get-Date).Date

# --- TMview ----------------------------------------------------------------
$TMV  = "https://www.tmdn.org/tmview/api/search/results"          # translate YOK: durumlar Ingilizce sabit
$TMAC = "https://www.tmdn.org/tmview/api/search/autocomplete/applicantName?text="
$TH = @{ "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36"; "Referer"="https://www.tmdn.org/tmview/"; "Accept"="application/json" }
$ALAN = @("ST13","tmName","applicationNumber","applicationDate","registrationDate","tradeMarkStatus","niceClass","applicantName","oppositionPeriodStart")

function Norm($s){
  $s = "$s"
  $m = @{ ([char]0x00E7)='c'; ([char]0x00C7)='c'; ([char]0x011F)='g'; ([char]0x011E)='g'; ([char]0x0131)='i'; ([char]0x0130)='i'; ([char]0x00F6)='o'; ([char]0x00D6)='o'; ([char]0x015F)='s'; ([char]0x015E)='s'; ([char]0x00FC)='u'; ([char]0x00DC)='u' }
  foreach($k in $m.Keys){ $s = $s.Replace([string]$k, $m[$k]) }
  return (($s.ToLowerInvariant()) -replace '[^a-z0-9]','')
}
# Unvan kuyruklarini at (SANAYI VE TICARET ANONIM SIRKETI vb.) - autocomplete'e
# kisa cekirdek verilir, varyantlari o getirir.
$EKLER = @('anonim sirketi','limited sirketi','sanayi ve ticaret','sanayi ticaret','ticaret limited','ticaret anonim','ithalat ihracat','a s','a.s.','ltd sti','ltd. sti.','ltd','sti','as','anonim','limited','sirketi','sanayi','ticaret','san','tic','holding','group','grup')
# Turkce harfleri ASCII'ye indirger ama BOSLUKLARI korur (kelime bazli ek ayiklama icin).
# NOT: ekler ASCII yazili; unvan "ANONIM SIRKETI" gibi Turkce harfliyse dogrudan
# eslesmez - o yuzden once burada duzlestiriyoruz (ilk surumde bu atlanmisti ve
# cekirdek "arcelik" yerine tum unvan cikip varyantlarin yarisi eleniyordu).
function DuzMetin($s){
  $s = "$s"
  $m = @{ ([char]0x00E7)='c'; ([char]0x00C7)='C'; ([char]0x011F)='g'; ([char]0x011E)='G'; ([char]0x0131)='i'; ([char]0x0130)='I'; ([char]0x00F6)='o'; ([char]0x00D6)='O'; ([char]0x015F)='s'; ([char]0x015E)='S'; ([char]0x00FC)='u'; ([char]0x00DC)='U' }
  foreach($k in $m.Keys){ $s = $s.Replace([string]$k, $m[$k]) }
  return ((($s.ToLowerInvariant()) -replace '[^a-z0-9]',' ') -replace '\s+',' ').Trim()
}
function Cekirdek($unvan){
  $t = " " + (DuzMetin $unvan) + " "
  foreach($e in $EKLER){ $t = $t -replace ("\s" + [regex]::Escape($e) + "\s"), " " }
  $t = ($t -replace '\s+',' ').Trim()
  if(-not $t){ $t = (($unvan -replace '\s+',' ').Trim()) }
  return $t
}
function Jstr($s){ if($null -eq $s){ return '""' }; return (ConvertTo-Json ([string]$s) -Compress) }

# ============================================================================
#  GIZLI SAHIPLI ADAY BASVURULAR  (29.08.2026)
#  Cem: "dizdar denetim basvurusu goremiyor muyuz yeni basvurular gibi"
#
#  OLCULDU VE KESINLESTI: TURKPATENT/TMview, bir basvuru BULTENDE YAYIMLANANA
#  KADAR SAHIBINI GIZLIYOR. Liste ucunda applicantName =
#  "Legally Restricted Until Publication Date"; detay ucu ise o kayitlar icin
#  HTTP 500 doner (yani oradan da ogrenilemiyor).
#  Sonuc: UNVAN ARAMASI yayimlanmamis basvurulari YAPISAL OLARAK BULAMAZ.
#  Kanit: fAName=["DIZDAR DENETIM ANONIM SIRKETI"] -> 0 sonuc; ayni anda
#  ad aramasi "dizdar" -> 50 kayit, tamaminin sahibi gizli.
#  Kendi basvurumuz da oyle: "tetikte" 2026-097164 (27.07.2026) GORUNUYOR
#  ama sahibi gizli - yani kendi portfoy taramamizda cikmiyordu.
#
#  YAPILABILEN: MARKA ADI gorunuyor. Unvanin cekirdek kelimesiyle (DIZDAR)
#  ad aramasi yapip SAHIBI GIZLI olanlari ayri bir baslikta gosteriyoruz.
#  BUNLAR "SENIN MARKALARIN" DEGIL - aday. "dizdar turizm" baskasinin
#  olabilir. Kart bunu acikca soyler; biz sahiplik iddia etmeyiz.
# ============================================================================
$GIZLI_SAHIP = 'Legally Restricted Until Publication'
function AdayBasvurular($cekirdek){
  $bos = New-Object System.Collections.Generic.List[object]
  if([string]::IsNullOrWhiteSpace("$cekirdek")){ return $bos }
  $kelime = (("$cekirdek" -split '\s+') | Where-Object { $_.Length -ge 3 } | Select-Object -First 1)
  if(-not $kelime){ return $bos }
  $alanDizi = '[' + ((@($ALAN) | ForEach-Object { Jstr $_ }) -join ',') + ']'
  $sayfa = 1
  while($sayfa -le 3){    # aday listesi tavanli: en yeni 300 kayit yeter
    $g = '{"page":"' + $sayfa + '","pageSize":"100","criteria":"C","basicSearch":' + (Jstr $kelime) + ',"fOffices":["TR"],"sortColumn":"applicationDate","desc":true,"fields":' + $alanDizi + '}'
    try{ $j = TmvIstek $g }catch{ break }
    $kayit = @($j.tradeMarks)
    if($kayit.Count -eq 0){ break }
    foreach($k in $kayit){
      $sh = ((@($k.applicantName) -join ', '))
      if($sh -notlike ("*" + $GIZLI_SAHIP + "*")){ continue }   # sahibi BELLI olan zaten unvan aramasinda cikar
      $bos.Add([pscustomobject]@{
        ad    = "$($k.tmName)"
        no    = "$($k.applicationNumber)"
        tarih = (DTarih $k.applicationDate)
        sinif = ((@($k.niceClass) -join ','))
        durum = "$($k.tradeMarkStatus)"
        yayim = (DTarih $k.oppositionPeriodStart)
        st13  = "$($k.ST13)"
      })
    }
    if($kayit.Count -lt 100){ break }
    $sayfa++
    Start-Sleep -Milliseconds $BeklemeMs
  }
  return $bos
}
# PS 5.1'de (try{...}catch{...}) IFADE olarak kullanilamaz (pwsh 7'de olur) -
# betik hem yerelde (5.1) hem Actions'ta (pwsh) kossun diye tarih cevirisi fonksiyonda.
function DTarih($v){ if(-not $v){ return '' }; try{ return ([datetime]$v).ToString('dd.MM.yyyy') }catch{ return '' } }
# 20.08 OLCUM: TMview cok istekten sonra BOT KORUMASI devreye sokuyor - HTTP 200
# dondurur ama govde JSON degil, JS challenge SAYFASIDIR. Bu sessizce yutulursa
# "bu firmanin markasi yok" gibi YANLIS bir cevap uretirdik. O yuzden govde JSON
# degilse HATA firlatilir; ust katman talebi 'hata' isaretler, "0 marka" demez.
function JsonMu($t){ $s = "$t".TrimStart(); return ($s.StartsWith('{') -or $s.StartsWith('[')) }
function TmvIstek($govdeJson){
  $b = [Text.Encoding]::UTF8.GetBytes($govdeJson)
  $son = $null
  for($deneme=1; $deneme -le 3; $deneme++){
    $w = Invoke-WebRequest -Uri $TMV -Method Post -Headers $TH -ContentType "application/json" -Body $b -TimeoutSec 60 -UseBasicParsing
    $t = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
    if(JsonMu $t){ return ($t | ConvertFrom-Json) }
    $son = $t
    Start-Sleep -Seconds (5 * $deneme)
  }
  throw ("TMview JSON yerine sayfa dondurdu (bot korumasi olabilir, {0} bayt) - sonuc uretilmedi." -f "$son".Length)
}
# ============================================================================
#  DETAY UCU — "olabilir" degil, KESIN  (29.08.2026, Cem: "duşmuş olabilir
#  diyor ama bilmiyoruz, biz bundan nasil para kazanacagiz")
#
#  SORUN: liste ucu (api/search/results) koruma bitisini VERMIYOR. Biz de
#  "basvuru + 10*n" ile TAHMIN edip karta "yenilenmediyse dolmus olmali,
#  kesin tarihi sicilden teyit et" yaziyorduk. Bu satilabilir bir cumle degil;
#  daha kotusu YANLIS olabiliyordu.
#
#  OLCULDU (29.08): GET /tmview/api/trademark/detail/{ST13}?translate=true
#  sicilin kendi verisini doner:
#    tradeMark.expiryDate            -> KESIN koruma bitisi
#    tradeMark.codeRegistrationDate  -> tescil tarihi
#    renewals[]                      -> YENILEME GECMISI (filingDate)
#    applicants[].fullName           -> gercek sahip
#    representatives[]               -> marka vekili
#    cancellations[] / oppositions[] / recordals -> iptal, itiraz, degisiklikler
#  GERCEK VAKA: "p 4000" (2006-31196) kartimizda "dusmus olabilir" yaziyordu;
#  detay ucu 26.06.2026'da YENILEME BASVURUSU yapildigini gosterdi. Yani
#  musteriye "markan dustu" diyecektik, oysa yenileniyordu.
#
#  MALIYET: marka basina 1 istek. Bu yuzden istege bagli (-Detay) ve tavanli.
#  Detay ALINAMAZSA eski tahmin yolu ve "tahmin" dili AYNEN kalir - kapali
#  bir kaynaktan emin gibi konusmayiz.
# ============================================================================
$TMDETAY = "https://www.tmdn.org/tmview/api/trademark/detail/"
function IsoGun($s){ if([string]::IsNullOrWhiteSpace("$s")){ return '' } try{ return ([datetime]::Parse("$s",[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AdjustToUniversal)).ToString('dd.MM.yyyy') }catch{ return '' } }
function TmvDetay($st13){
  if([string]::IsNullOrWhiteSpace("$st13")){ return $null }
  for($d=1; $d -le 3; $d++){
    try{
      $w = Invoke-WebRequest -Uri ($TMDETAY + [uri]::EscapeDataString("$st13") + "?translate=true") -Headers $TH -TimeoutSec 45 -UseBasicParsing
      $t = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
      if(-not (JsonMu $t)){ throw 'govde JSON degil' }
      $j = $t | ConvertFrom-Json
      $tm = $j.tradeMark
      if(-not $tm){ return $null }
      # DIZI YOK, hepsi SKALER: PS 5.1'in ConvertTo-Json'i ic dizileri
      # {value,Count} icine sarar (bilinen kusur) ve istemci okuyamaz.
      # Yenileme gecmisi bu yuzden METIN olarak tutulur.
      $yen = @($j.renewals | Where-Object { $_ } | ForEach-Object { IsoGun $_.filingDate } | Where-Object { $_ })
      $vek = @($j.representatives | Where-Object { $_ } | ForEach-Object { if($_.organizationName){ "$($_.organizationName)" } else { "$($_.fullName)" } } | Where-Object { $_ })
      $sah = @($j.applicants | Where-Object { $_ } | ForEach-Object { "$($_.fullName)" } | Where-Object { $_ })
      $kyt = @($j.recordals.basicRecords | Where-Object { $_ } | ForEach-Object { "$($_.kindTranslated)" } | Where-Object { $_ })
      return [pscustomobject]@{
        bitis          = IsoGun $tm.expiryDate
        tescil         = IsoGun $tm.codeRegistrationDate
        basvuru        = IsoGun $tm.applicationDate
        sicil_no       = "$($tm.registrationNumber)"
        durum_tr       = "$($tm.markCurrentStatusCodeTranslated)"
        tur            = "$($tm.markFeatureTranslated)"
        yenileme_sayisi= $yen.Count
        son_yenileme   = $(if($yen.Count){ $yen[$yen.Count-1] } else { '' })
        yenilemeler    = ($yen -join ' · ')
        sahip          = ($sah -join ' · ')
        vekil          = ($vek -join ' · ')
        kayitlar       = ($kyt -join ' · ')
        iptal_sayisi   = @($j.cancellations).Count
        itiraz_sayisi  = @($j.oppositions).Count
      }
    }catch{
      if($d -eq 3){ return $null }   # detay alinamadi: TAHMIN yoluna dus, yalan soyleme
      Start-Sleep -Milliseconds (600 * $d)
    }
  }
  return $null
}

# Sahip adi varyantlari: once tam unvan, bos donerse cekirdek, o da bossa ilk kelime
function Varyantlar($unvan){
  $sonuc = New-Object System.Collections.Generic.List[string]   # cekirdekle BASLAYANLAR (guvenli)
  $yedek = New-Object System.Collections.Generic.List[string]   # cekirdegi iceren ama basta olmayanlar
  $nUnv = Norm $unvan
  $cek  = Cekirdek $unvan
  $adaylar = @($unvan, $cek)
  $ilk = ($cek -split ' ')[0]
  if($ilk.Length -ge 4){ $adaylar += $ilk }
  foreach($sorgu in ($adaylar | Select-Object -Unique)){
    if(-not "$sorgu".Trim()){ continue }
    $liste = $null
    for($d=1; $d -le 3 -and -not $liste; $d++){
      try{
        $w = Invoke-WebRequest -Uri ($TMAC + [uri]::EscapeDataString($sorgu)) -Headers $TH -TimeoutSec 30 -UseBasicParsing
        $ham = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
        if(JsonMu $ham){ $liste = ($ham | ConvertFrom-Json); $script:AcCalisti = $true }
        else { Start-Sleep -Seconds (5 * $d) }   # bot korumasi sayfasi - bekle, tekrar dene
      }catch{ Start-Sleep -Seconds (3 * $d) }
    }
    if($null -eq $liste){ continue }
    foreach($o in @($liste)){
      $ad = "$($o.text)"; if(-not $ad){ continue }
      $nAd = Norm $ad
      # Eslesme disiplini: cekirdek adin varyantta gecmesi SART (yanlis firmayi
      # portfoye koymayalim). Ters yon de kabul (kullanici tam unvan yazdi,
      # sicilde kisa kayitli olabilir).
      $nCek = Norm $cek
      if($nCek.Length -lt 4){ continue }
      # BASLANGIC KURALI: "arcelik as" AL; "elcin arcelik" / "sennur arcelik" ALMA.
      # (Ilk surumde salt icerme vardi ve ayni soyadli KISILER portfoye giriyordu -
      #  yanlis firmanin markasini gostermek en pahali hata.)
      # 21.08 DARALTMA: ters yon ("kullanicinin unvani, sicildeki adla BASLIYOR")
      # fazla genisti - "DIZDAR DENETIM ANONIM SIRKETI" sorgusu sicildeki yabanci
      # "DIZDAR" kaydiyla eslesip 82 marka getiriyordu (baskasinin portfoyu!).
      # Artik sicildeki ad, cekirdegin TAMAMINI icermek zorunda.
      if($nAd.StartsWith($nCek)){
        if(-not $sonuc.Contains($ad)){ $sonuc.Add($ad) }
      }
      elseif($nAd.Contains($nCek)){ if(-not $yedek.Contains($ad)){ $yedek.Add($ad) } }
    }
    if($sonuc.Count -ge 25){ break }
    Start-Sleep -Milliseconds $BeklemeMs
  }
  # Hic tam baslangic eslesmesi yoksa (or. "Dizdar Denetim" -> "MEHMET DIZDAR DENETIM")
  # iceren kayitlara dus; aksi halde sonuc bos kalirdi.
  if($sonuc.Count -eq 0 -and $yedek.Count -gt 0){ return @($yedek | Select-Object -First 10) }
  return @($sonuc | Select-Object -First 25)
}
function SahipMarkalari($varyantlar){
  $cikti = New-Object System.Collections.Generic.List[object]
  if(-not $varyantlar -or @($varyantlar).Count -eq 0){ return $cikti }
  $adDizi = '[' + ((@($varyantlar) | ForEach-Object { Jstr $_ }) -join ',') + ']'
  $alanDizi = '[' + ((@($ALAN) | ForEach-Object { Jstr $_ }) -join ',') + ']'
  $sayfa = 1; $gorulen = @{}
  $script:SonToplam = 0     # TMview'in bildirdigi GERCEK toplam (tavandan bagimsiz)
  while($true){
    if(($sayfa * 100) -gt $MaxKayit + 100){ break }
    $g = '{"page":"' + $sayfa + '","pageSize":"100","criteria":"C","basicSearch":"","fAName":' + $adDizi + ',"fOffices":["TR"],"sortColumn":"applicationDate","desc":true,"fields":' + $alanDizi + '}'
    try{ $j = TmvIstek $g }catch{ break }
    if($sayfa -eq 1 -and $j.totalResults){ $script:SonToplam = [int]$j.totalResults }
    $kayit = @($j.tradeMarks)
    if($kayit.Count -eq 0){ break }
    foreach($k in $kayit){
      $no = "$($k.applicationNumber)"; if(-not $no -or $gorulen.ContainsKey($no)){ continue }
      $gorulen[$no] = 1
      $cikti.Add([pscustomobject]@{
        ad     = "$($k.tmName)"
        no     = $no
        tarih  = (DTarih $k.applicationDate)
        tescil = (DTarih $k.registrationDate)
        yayim  = (DTarih $k.oppositionPeriodStart)
        durum  = "$($k.tradeMarkStatus)"
        sinif  = ((@($k.niceClass) -join ','))
        sahip  = ((@($k.applicantName) -join ', '))
        st13   = "$($k.ST13)"
      })
      if($cikti.Count -ge $MaxKayit){ break }
    }
    if($cikti.Count -ge $MaxKayit){ break }
    $sayfa++
    Start-Sleep -Milliseconds $BeklemeMs
  }
  return $cikti
}
function DdmmToDate($s){ try{ return [datetime]::ParseExact("$s",'dd.MM.yyyy',$null) }catch{ return $null } }

# --- SMK m.23 hesabi --------------------------------------------------------
#  hal: guvende | yenileme-penceresi | ek-sure | dusmus | surecte | bilinmiyor
function Hesapla($m){
  $bt = DdmmToDate $m.tarih
  $d  = "$($m.durum)"
  $tescilliMi = ($d -match '(?i)regist')                       # Registered
  $bittiMi    = ($d -match '(?i)(ended|expir|withdraw|refus|invalid|surrender)')
  $o = [ordered]@{ hal='bilinmiyor'; donem_sonu=''; kalan_gun=$null; ek_sure_sonu=''; not=''; kullanim_son=''; kullanim_kalan=$null; kullanim_notu=''; m68_son=''; kesin=$false }
  # 29.08: KESIN BITIS. Detay ucu sicilin kendi expiryDate'ini veriyor; varsa
  # "basvuru + 10*n" TAHMINI hic kullanilmaz. kesin=$true olan kartta "olabilir /
  # teyit et" dili YAZILMAZ - cunku artik biliyoruz.
  $kesinBitis = $null
  if($m.PSObject.Properties['bitis'] -and $m.bitis){ $kesinBitis = DdmmToDate $m.bitis }
  if($kesinBitis){ $o.kesin = $true }
  # Yenileme gecmisi cumlesi: kac kez, en son ne zaman (kurumsal kunye)
  $yenCumle = ''
  if($m.PSObject.Properties['yenileme_sayisi'] -and [int]"$($m.yenileme_sayisi)" -gt 0){
    $yenCumle = ' Sicilde ' + $m.yenileme_sayisi + ' yenileme kaydı var'
    if($m.son_yenileme){ $yenCumle += ' (sonuncusu ' + $m.son_yenileme + ')' }
    $yenCumle += '.'
  }
  # NOT metinleri KULLANICIYA gider (sayfa + mail) -> duzgun Turkce yazilir;
  # betik BOM'lu UTF-8 oldugu icin hem PS 5.1 hem pwsh 7 dogru okur.
  if(-not $bt){ $o.not = 'Başvuru tarihi okunamadı.'; return $o }
  if($bittiMi){
    $o.hal='dusmus'
    # m.6/8 (ambardan birebir): "Tescilli markanin yenilenmeme sebebiyle koruma
    # suresinin sona ermesinden itibaren IKI YIL icinde yapilan, bu markayla ayni
    # veya benzer ... basvuru, onceki marka sahibinin itirazi uzerine BU IKI YILLIK
    # SURE ICINDE MARKANIN KULLANILMIS OLMASI SARTIYLA reddedilir."
    # Sona erme tarihini sicil vermiyor -> basvuru+10*n ile TAHMIN, "tahmin" denir.
    # KESIN bitis varsa tahmin YOK: sicil ne diyorsa o.
    if($kesinBitis){
      $sonaTahmin = $kesinBitis
      $nS = 2   # kesin tarih var; m.6/8 penceresi her halukarda hesaplanir
    } else {
      $nS = 1; while($bt.AddYears(10*$nS) -lt $simdi){ $nS++ }
      $sonaTahmin = $bt.AddYears(10*($nS-1))
    }
    if($nS -gt 1){
      $o.donem_sonu = $sonaTahmin.ToString('dd.MM.yyyy')
      $o.m68_son    = $sonaTahmin.AddYears(2).ToString('dd.MM.yyyy')
      $kalan68 = [int]($sonaTahmin.AddYears(2) - $simdi).TotalDays
      if($kesinBitis){
        # KURUMSAL KUNYE: kesin tarih + tescil + yenileme gecmisi + sicil durumu
        $o.not = 'Koruma ' + $o.donem_sonu + ' tarihinde sona erdi (sicil kaydı).'
        if($m.PSObject.Properties['durum_tr'] -and $m.durum_tr){ $o.not += ' Sicildeki durumu: "' + $m.durum_tr + '".' }
        if($m.tescil){ $o.not += ' Başvuru ' + $m.tarih + ', tescil ' + $m.tescil + '.' }
        $o.not += $yenCumle + ' '
        # 29.08 (Cem'in gosterdigi gercek vaka - "p 4000"): son yenileme kaydi
        # bitis tarihine cok yakinsa ya da SONRASINDAYSA, yenileme talebi
        # verilmis ama sicil durumu henuz guncellenmemis olabilir. Bunu
        # SOYLEMEZSEK musteriye "markan dustu" demis oluruz - oysa yenileniyor.
        if($m.PSObject.Properties['son_yenileme'] -and $m.son_yenileme){
          $sy = DdmmToDate $m.son_yenileme
          if($sy -and ([int]($kesinBitis - $sy).TotalDays) -le 180){
            $o.not += '⚠️ DİKKAT: son yenileme kaydı (' + $m.son_yenileme + ') koruma bitişiyle aynı döneme denk geliyor. Yenileme talebi verilmiş, sicil durumu henüz güncellenmemiş olabilir — bu markayı düşmüş saymadan önce TÜRKPATENT sicil kaydından teyit et. '
          }
        }
      } else {
        $o.not = 'Sicilde "' + $d + '" görünüyor — koruma sona ermiş (yenilenmediyse dönem ' + $o.donem_sonu + ' tarihinde dolmuş olmalı; kesin tarihi sicilden teyit et). '
      }
      if($kalan68 -gt 0){ $o.not += 'Aynı ibareyi geri almak istersen: bu marka için ' + $o.m68_son + ' tarihine kadar (2 yıl) eski sahibin, o sürede markayı kullanıyorsa yeni başvuruya itiraz edip reddettirebilir (m.6/8) — kalan ' + $kalan68 + ' gün.' }
      # DIKKAT: PowerShell akilli tirnagi (U+2019) da string sinirlayici sayar -
      # "m.6/8'in" yazimi betigi dusuruyordu; kesme isaretsiz kuruldu.
      else { $o.not += 'm.6/8 kapsamındaki 2 yıllık koruma ' + $o.m68_son + ' tarihinde dolmuş; aynı ibare için başvuru yolu bu yönden açık (mutlak/nispi diğer engeller ayrıca değerlendirilir).' }
    } else {
      $o.not = 'Sicilde "' + $d + '" görünüyor — koruma sona ermiş. Aynı ibareyi tekrar tescil ettirebilirsin; ancak marka düştükten sonraki 2 yıl içinde başkası da alabilir (SMK m.6/8).'
    }
    return $o
  }
  # sonraki 10 yillik donem sonu
  # 29.08: KESIN bitis varsa tahmin edilmez. Onceki donem sonu da kesin
  # bitisten geriye 10 yil sayilarak bulunur (m.23: donemler onar yillik).
  if($kesinBitis){
    $donemSonu  = $kesinBitis
    $oncekiSonu = $kesinBitis.AddYears(-10)
    $n = 1
  } else {
    $n = 1; while($bt.AddYears(10*$n) -lt $simdi){ $n++ }
    $donemSonu = $bt.AddYears(10*$n)
    $oncekiSonu = $bt.AddYears(10*($n-1))
  }
  $o.donem_sonu = $donemSonu.ToString('dd.MM.yyyy')
  $o.kalan_gun = [int]($donemSonu - $simdi).TotalDays
  $o.ek_sure_sonu = $donemSonu.AddMonths(6).ToString('dd.MM.yyyy')
  if(-not $tescilliMi){
    $o.hal = 'surecte'
    $o.not = 'Başvuru aşaması (sicil durumu: ' + $d + ').'
    if($m.yayim){ $ys = (DdmmToDate $m.yayim); if($ys){ $o.not += ' Bültende yayım ' + $m.yayim + '; üçüncü kişilerin itiraz süresi ' + $ys.AddMonths(2).ToString('dd.MM.yyyy') + ' tarihinde doluyor (m.18: yayımdan 2 ay).' } }
    return $o
  }
  # --- KULLAN YA DA KAYBET (m.9/1 + m.26/1-a) --------------------------------
  # m.9/1 ambardan birebir: "Tescil tarihinden itibaren bes yil icinde hakli bir
  # sebep olmadan tescil edildigi mal veya hizmetler bakimindan marka sahibi
  # tarafindan Turkiye'de ciddi bicimde kullanilmayan ya da kullanimina bes yil
  # kesintisiz ara verilen markanin iptaline karar verilir."
  # m.26/1-a: bu hal Kurumdan iptal sebebi; m.26/2: ILGILI KISILER talep edebilir
  # (yani rakip). m.26/4: bes yilin dolmasi ile talep arasinda ciddi kullanim
  # varsa talep reddedilir; ancak talepten onceki 3 aylik kullanim sayilmaz.
  $tesTarih = DdmmToDate $m.tescil
  if($tescilliMi -and $tesTarih){
    $besYil = $tesTarih.AddYears(5)
    $o.kullanim_son = $besYil.ToString('dd.MM.yyyy')
    $o.kullanim_kalan = [int]($besYil - $simdi).TotalDays
    if($o.kullanim_kalan -gt 0){
      $o.kullanim_notu = 'Kullanım ispatı eşiği ' + $o.kullanim_son + ' (' + $o.kullanim_kalan + ' gün). O tarihten sonra markayı ciddi biçimde kullanmıyorsan ilgili kişiler Kurumdan iptalini isteyebilir (m.9/1, m.26/1-a). Fatura, ambalaj, reklam gibi kullanım delillerini şimdiden biriktir.'
    } else {
      $o.kullanim_notu = 'Tescilin üzerinden 5 yıl geçti (' + $o.kullanim_son + '). Markayı tescilli olduğu mal/hizmetlerde ciddi biçimde kullanmıyorsan iptal talebine açıksın (m.9/1, m.26/1-a). İptal talebi gelirse kullanım delili istenir; talepten önceki 3 ay içinde yapılan kullanım sayılmaz (m.26/4).'
    }
  }
  # ===========================================================================
  #  KESIN YOL (29.08) — sicil bitis tarihini verdiyse TAHMIN YAPILMAZ
  #  Tahmin yolunda "onceki donem sonu"nu 10 yil geri sayarak buluyorduk ve
  #  karta "yenilediysen X, yenilemediysen Y, sicilden teyit et" yaziyorduk.
  #  expiryDate elimizdeyken bu cumleye gerek yok: bitis tarihi bellidir.
  #    bitis gelecekte -> guvende / yenileme penceresi (kalan gune gore)
  #    bitis gecmiste + sicil hala tescilli -> 6 aylik EK SURE (m.23/3)
  #  Kart kurumsal kunye yazar: basvuru, tescil, sicil no, tur, yenileme
  #  gecmisi, vekil ve varsa iptal/itiraz kaydi.
  # ===========================================================================
  if($kesinBitis){
    $kunye = ''
    if($m.tarih){ $kunye += ' Başvuru ' + $m.tarih }
    if($m.tescil){ $kunye += ', tescil ' + $m.tescil }
    if($m.PSObject.Properties['sicil_no'] -and $m.sicil_no){ $kunye += ', sicil no ' + $m.sicil_no }
    if($m.PSObject.Properties['tur'] -and $m.tur){ $kunye += ' (' + $m.tur + ' marka)' }
    if($kunye){ $kunye += '.' }
    $ek = ''
    if($m.PSObject.Properties['vekil'] -and $m.vekil){ $ek += ' Sicilde kayıtlı vekil: ' + $m.vekil + '.' }
    if($m.PSObject.Properties['iptal_sayisi'] -and [int]"$($m.iptal_sayisi)" -gt 0){ $ek += ' DİKKAT: sicilde ' + $m.iptal_sayisi + ' iptal kaydı var.' }
    if($m.PSObject.Properties['itiraz_sayisi'] -and [int]"$($m.itiraz_sayisi)" -gt 0){ $ek += ' Sicilde ' + $m.itiraz_sayisi + ' itiraz kaydı var.' }
    if($m.PSObject.Properties['kayitlar'] -and $m.kayitlar){ $ek += ' Sicil işlemleri: ' + $m.kayitlar + '.' }

    $gecen = [int]($simdi - $kesinBitis).TotalDays
    if($gecen -gt 0){
      # bitis GECMISTE ama sicil hala tescilli -> ek sure penceresi
      $o.hal = 'ek-sure'
      $o.donem_sonu   = $kesinBitis.ToString('dd.MM.yyyy')
      $o.kalan_gun    = -$gecen
      $o.ek_sure_sonu = $kesinBitis.AddMonths(6).ToString('dd.MM.yyyy')
      $ekKalan = [int]($kesinBitis.AddMonths(6) - $simdi).TotalDays
      $o.not = 'Koruma ' + $o.donem_sonu + ' tarihinde doldu (sicil kaydı); sicildeki durum hâlâ tescilli.' + $kunye + $yenCumle
      if($ekKalan -ge 0){ $o.not += ' 6 aylık ek süre ' + $o.ek_sure_sonu + ' gününde doluyor — ek ücretle yenilenebilir (m.23/3), kalan ' + $ekKalan + ' gün. Bu tarih de geçerse marka hakkı sona erer (m.28/1-a).' }
      else { $o.not += ' 6 aylık ek süre ' + $o.ek_sure_sonu + ' tarihinde doldu; yenileme yapılmadıysa marka hakkı sona ermiştir (m.28/1-a).' }
      $o.not += $ek
      return $o
    }
    $o.donem_sonu = $kesinBitis.ToString('dd.MM.yyyy')
    $o.kalan_gun  = [int]($kesinBitis - $simdi).TotalDays
    $o.ek_sure_sonu = $kesinBitis.AddMonths(6).ToString('dd.MM.yyyy')
    if($o.kalan_gun -le $YenilemeGun){
      $o.hal = 'yenileme-penceresi'
      $o.not = 'Yenileme penceresi AÇIK: koruma ' + $o.donem_sonu + ' tarihinde bitiyor, kalan ' + $o.kalan_gun + ' gün (sicil kaydı).' + $kunye + $yenCumle + ' Talep bitişten önceki 6 ay içinde verilir; kaçırırsan ' + $o.ek_sure_sonu + ' tarihine kadar ek ücretle yenilenebilir (m.23).' + $ek
    } else {
      $o.hal = 'guvende'
      $o.not = 'Koruma ' + $o.donem_sonu + ' tarihine kadar geçerli, kalan ' + $o.kalan_gun + ' gün (sicil kaydı — tahmin değil).' + $kunye + $yenCumle + ' Yenileme penceresi ' + $kesinBitis.AddMonths(-6).ToString('dd.MM.yyyy') + ' tarihinde açılır (m.23: bitişten önceki 6 ay).' + $ek
    }
    return $o
  }

  # tescilli
  if($n -gt 1 -and ([int]($simdi - $oncekiSonu).TotalDays) -le 180){
    $o.hal = 'ek-sure'
    # Ekranda/mailde gosterilecek tarih SONRAKI donem (2036) degil, DOLAN donem
    # olmali - yoksa "ek surede ama bitis 2036" gibi celiskili gorunuyordu.
    $o.donem_sonu   = $oncekiSonu.ToString('dd.MM.yyyy')
    $o.kalan_gun    = [int]($oncekiSonu - $simdi).TotalDays      # negatif: kac gun once doldu
    $o.ek_sure_sonu = $oncekiSonu.AddMonths(6).ToString('dd.MM.yyyy')
    $o.not = 'Koruma dönemi ' + $oncekiSonu.ToString('dd.MM.yyyy') + ' tarihinde doldu; sicil hâlâ tescilli gösteriyor. Yenilediysen sıradaki bitiş ' + $donemSonu.ToString('dd.MM.yyyy') + '. Yenilemediysen 6 aylık ek süren ' + $oncekiSonu.AddMonths(6).ToString('dd.MM.yyyy') + ' gününe kadar (ek ücretle, m.23/3) — sicilden teyit et, o tarih de geçerse hak sona erer (m.28/1-a).'
    return $o
  }
  if($o.kalan_gun -le $YenilemeGun){
    $o.hal = 'yenileme-penceresi'
    $o.not = 'Yenileme penceresi AÇIK: koruma ' + $o.donem_sonu + ' tarihinde bitiyor (' + $o.kalan_gun + ' gün). Talep bitişten önceki 6 ay içinde verilir; kaçırırsan ' + $o.ek_sure_sonu + ' tarihine kadar ek ücretle yenilenebilir (m.23).'
    return $o
  }
  $o.hal = 'guvende'
  $o.not = 'Sıradaki koruma bitişi ' + $o.donem_sonu + ' (' + $o.kalan_gun + ' gün). Sicil "tescilli" gösterdiği için önceki dönemler yenilenmiş kabul edildi.'
  return $o
}
function PortfoyKur($unvan){
  $script:AcCalisti = $false
  $vars = Varyantlar $unvan
  # Autocomplete hic JSON dondurmediyse (bot korumasi) sonuc URETILMEZ: "marka yok"
  # demek yanlis olurdu. Olcemedigimize kusur deme disiplini.
  if(-not $script:AcCalisti){ throw "TMview sahip-adi ucu su an yanit vermedi (bot korumasi/gecici) - tarama yapilamadi." }
  # Varyant cikmadiysa kullanicinin yazdigi unvani oldugu gibi de bir dene:
  # sicilde tam o yazimla kayitli olabilir (autocomplete bazen esitlemiyor).
  if(@($vars).Count -eq 0){ $vars = @($unvan) }
  $mrk  = SahipMarkalari $vars
  # 29.08: yayimlanmamis basvurular unvanla BULUNAMAZ (sahip gizli) - ad
  # uzerinden aday listesi cikarilir. Bunlar "senin markalarin" DEGIL.
  $adaylar = AdayBasvurular (Cekirdek $unvan)

  # --- DETAY ZENGINLESTIRME: tahmini KESIN veriyle degistir -------------------
  # Liste ucu koruma bitisini vermiyor; detay ucu veriyor. Marka basina 1 istek
  # oldugu icin tavanli. Alinamayan kayit TAHMIN yoluna duser ve karti "tahmin"
  # dilini korur - kapali kaynaktan emin gibi konusmayiz.
  $script:DetayAlinan = 0; $script:DetayDenenen = 0
  # 30.08 OLCULDU VE DARALTILDI: detay ucu marka basina 1 istek. TUM markalari
  # zenginlestirmek Ege Seramik'te (329 marka) kosuyu 16+ DAKIKAYA cikardi;
  # ARCELIK'te (1.179) ~50 dakika olurdu. Kuyruk robotu bu kadar bekleyemez -
  # kesinlik kazanirken HIZI kaybetmistim, olcmeden yapmistim.
  # Cozum: kesinlik SADECE ONEMLI OLDUGU YERDE alinir.
  #   ek-sure / yenileme-penceresi / dusmus  -> tarih yanlissa PARA/HAK kaybi
  #   donem sonuna <= 550 gun kalanlar       -> yakinda o gruba girecek
  # Gerisi TAHMIN kalir ve kart bunu zaten "TAHMIN" rozetiyle SOYLUYOR.
  # Once tahminle siniflandir, sonra yalniz adaylari zenginlestir.
  if($Detay){
    $onSiniflar = @{}
    foreach($m in $mrk){ $onSiniflar[$m.no] = (Hesapla $m) }
    $adayNo = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($m in $mrk){
      $h = $onSiniflar[$m.no]
      $onemli = ($h.hal -eq 'ek-sure' -or $h.hal -eq 'yenileme-penceresi' -or $h.hal -eq 'dusmus')
      if(-not $onemli -and $null -ne $h.kalan_gun -and [int]$h.kalan_gun -le 550){ $onemli = $true }
      if($onemli){ [void]$adayNo.Add("$($m.no)") }
    }
    Write-Host ("Detay hedefi: {0}/{1} marka (yalniz tarihi ONEMLI olanlar)." -f $adayNo.Count, @($mrk).Count)
    $sayac = 0
    foreach($m in $mrk){
      if(-not $adayNo.Contains("$($m.no)")){ continue }
      if($sayac -ge $DetayTavan){ break }
      $sayac++; $script:DetayDenenen++
      $d = TmvDetay $m.st13
      Start-Sleep -Milliseconds $DetayBeklemeMs
      if(-not $d){ continue }
      $script:DetayAlinan++
      # KESIN alanlar liste ucunu EZER (sicil ne diyorsa o)
      $m | Add-Member -NotePropertyName bitis           -NotePropertyValue $d.bitis           -Force
      $m | Add-Member -NotePropertyName yenileme_sayisi -NotePropertyValue $d.yenileme_sayisi -Force
      $m | Add-Member -NotePropertyName son_yenileme    -NotePropertyValue $d.son_yenileme    -Force
      $m | Add-Member -NotePropertyName yenilemeler     -NotePropertyValue $d.yenilemeler     -Force
      $m | Add-Member -NotePropertyName vekil           -NotePropertyValue $d.vekil           -Force
      $m | Add-Member -NotePropertyName sicil_no        -NotePropertyValue $d.sicil_no        -Force
      $m | Add-Member -NotePropertyName durum_tr        -NotePropertyValue $d.durum_tr        -Force
      $m | Add-Member -NotePropertyName tur             -NotePropertyValue $d.tur             -Force
      $m | Add-Member -NotePropertyName kayitlar        -NotePropertyValue $d.kayitlar        -Force
      $m | Add-Member -NotePropertyName iptal_sayisi    -NotePropertyValue $d.iptal_sayisi    -Force
      $m | Add-Member -NotePropertyName itiraz_sayisi   -NotePropertyValue $d.itiraz_sayisi   -Force
      if($d.tescil){ $m.tescil = $d.tescil }
      if($d.sahip){  $m.sahip  = $d.sahip }
    }
    Write-Host ("Detay: {0}/{1} kayit sicilden KESIN alindi (kalani tahmin yolunda)." -f $script:DetayAlinan, $script:DetayDenenen)
  }

  $liste = New-Object System.Collections.Generic.List[object]
  foreach($m in $mrk){
    $h = Hesapla $m
    $liste.Add([pscustomobject]@{ ad=$m.ad; no=$m.no; tarih=$m.tarih; tescil=$m.tescil; sinif=$m.sinif; durum=$m.durum; sahip=$m.sahip; yayim=$m.yayim; hal=$h.hal; donem_sonu=$h.donem_sonu; kalan_gun=$h.kalan_gun; not=$h.not; kullanim_son=$h.kullanim_son; kullanim_kalan=$h.kullanim_kalan; kullanim_notu=$h.kullanim_notu; m68_son=$h.m68_son;
      kesin=$h.kesin; sicil_no=$m.sicil_no; durum_tr=$m.durum_tr; tur=$m.tur; vekil=$m.vekil; yenileme_sayisi=$m.yenileme_sayisi; son_yenileme=$m.son_yenileme; yenilemeler=$m.yenilemeler; kayitlar=$m.kayitlar; iptal_sayisi=$m.iptal_sayisi; itiraz_sayisi=$m.itiraz_sayisi })
  }
  $sirali = @($liste | Sort-Object -Property @{Expression={ switch($_.hal){ 'ek-sure'{0} 'yenileme-penceresi'{1} 'surecte'{2} 'guvende'{3} 'dusmus'{4} default{5} } }}, @{Expression={ if($null -ne $_.kalan_gun){ $_.kalan_gun } else { 99999 } }})

  # --- SINIF HARITASI (yalniz YASAYAN markalar: dusmus olan koruma saglamaz) ---
  # Sinif = Nice sinifi. Mallar 1-34, hizmetler 35-45 (TURKPATENT Mal ve Hizmet
  # Siniflandirma Listesi, Teblig m.3/1). 35. sinif hizmetleri arasinda
  # "musterilerin mallari elverisli bicimde gorup satin alabilmeleri icin
  # mallarin bir araya getirilmesi hizmetleri" var (Teblig m.3/5) - yani
  # magazacilik/satis. Mal sinifinda korunup 35'te korunmayan firma, kendi
  # urununu satan magazayi/e-ticareti marka olarak korumuyor demektir.
  $sinifSay = @{}
  foreach($m in $sirali){
    if($m.hal -eq 'dusmus'){ continue }
    foreach($s in ("$($m.sinif)" -split ',')){
      $sn = "$s".Trim(); if(-not $sn){ continue }
      if($sinifSay.ContainsKey($sn)){ $sinifSay[$sn] = $sinifSay[$sn] + 1 } else { $sinifSay[$sn] = 1 }
    }
  }
  $sinifListe = New-Object System.Collections.Generic.List[object]
  foreach($k in ($sinifSay.Keys | Sort-Object { [int]$_ })){ $sinifListe.Add([ordered]@{ no=[int]$k; adet=$sinifSay[$k] }) }
  $malSinif  = @($sinifSay.Keys | Where-Object { [int]$_ -le 34 })
  $otuzBes   = $sinifSay.ContainsKey('35')
  $sinifAcik = ''
  if(@($malSinif).Count -gt 0 -and -not $otuzBes){
    $sinifAcik = 'Ürün sınıflarında (' + (($malSinif | Sort-Object { [int]$_ }) -join ', ') + ') korunuyorsun ama 35. sınıf açık. 35. sınıf, "müşterilerin malları görüp satın alabilmeleri için malların bir araya getirilmesi hizmetleri"ni (mağaza, e-ticaret, katalog satışı) kapsar. Kendi ürününü satıyorsan bu hizmet adı korumasız; başkası aynı ibareyi 35. sınıfta tescil ettirebilir.'
  }

  # --- KULLAN YA DA KAYBET (m.9/1) -------------------------------------------
  # AYRIM SART: "5 yili dolmus" olmak basli basina alarm DEGIL (koklu firmada
  # tescillerin nerdeyse hepsi dolmustur - 164/164 cikip gurultu oluyordu).
  # Eylem gerektiren: esige 180 gunden az kalanlar. Dolmuslar bilgi notu.
  $kullanimYakin  = @($sirali | Where-Object { $_.kullanim_kalan -ne $null -and [int]$_.kullanim_kalan -le 180 -and [int]$_.kullanim_kalan -ge 0 })
  $kullanimDolmus = @($sirali | Where-Object { $_.kullanim_kalan -ne $null -and [int]$_.kullanim_kalan -lt 0 })

  return [pscustomobject]@{
    siniflar      = $sinifListe.ToArray()   # List'i @() ile koymak hashtable'i dusuruyor (20.08 dersi)
    sinif_acigi   = $sinifAcik
    kullanim_yakin  = @($kullanimYakin).Count
    kullanim_dolmus = @($kullanimDolmus).Count
    unvan       = $unvan
    varyantlar  = @($vars)
    markalar    = $sirali
    sayi        = @($sirali).Count
    # Sicildeki GERCEK toplam (TMview totalResults). Tavan nedeniyle 'sayi' bundan
    # kucuk kalabilir - sayfa "N kayittan ilk M'si" der; uydurma sayi gostermeyiz.
    toplam      = $(if($script:SonToplam -gt 0){ [int]$script:SonToplam } else { @($sirali).Count })
    tescilli    = @($sirali | Where-Object { $_.durum -match '(?i)regist' }).Count
    yenileme    = @($sirali | Where-Object { $_.hal -eq 'yenileme-penceresi' }).Count
    ek_surede   = @($sirali | Where-Object { $_.hal -eq 'ek-sure' }).Count
    dusmus      = @($sirali | Where-Object { $_.hal -eq 'dusmus' }).Count
    surecte     = @($sirali | Where-Object { $_.hal -eq 'surecte' }).Count
    # Sahibi sicilde GIZLI olan, adi unvanin cekirdegine benzeyen basvurular.
    # Aday listesidir - sahiplik iddiasi degil.
    adaylar     = @($adaylar)
    aday_sayi   = @($adaylar).Count
  }
}

# --- ELLE TEST MODU (Supabase'e hic dokunmaz) -------------------------------
if($Unvan){
  $p = PortfoyKur $Unvan
  Write-Host ("UNVAN: {0}" -f $p.unvan)
  Write-Host ("Varyant ({0}): {1}" -f @($p.varyantlar).Count, (@($p.varyantlar) -join ' | '))
  Write-Host ("Sicildeki toplam: {0} - islenen: {1} - tescilli {2} - yenileme penceresi {3} - ek sure {4} - dusmus {5} - surecte {6}" -f $p.toplam,$p.sayi,$p.tescilli,$p.yenileme,$p.ek_surede,$p.dusmus,$p.surecte)
  Write-Host ("Siniflar: {0}" -f ((@($p.siniflar) | ForEach-Object { "$($_.no)($($_.adet))" }) -join ' '))
  if($p.sinif_acigi){ Write-Host ("SINIF ACIGI: {0}" -f $p.sinif_acigi) }
  Write-Host ("Kullanim (5 yil): yaklasan {0} - dolmus {1}" -f $p.kullanim_yakin,$p.kullanim_dolmus)
  foreach($m in (@($p.markalar) | Select-Object -First 10)){ Write-Host ("  [{0}] {1} ({2}) sinif {3} - {4} - {5}" -f $m.hal,$m.ad,$m.no,$m.sinif,$m.durum,$m.donem_sonu) }
  foreach($m in (@($p.markalar) | Where-Object { $_.kullanim_kalan -ne $null -and [int]$_.kullanim_kalan -le 180 } | Select-Object -First 3)){ Write-Host ("  5YIL> {0} ({1}) esik {2} / kalan {3}" -f $m.ad,$m.no,$m.kullanim_son,$m.kullanim_kalan) }
  foreach($m in (@($p.markalar) | Where-Object { $_.m68_son } | Select-Object -First 2)){ Write-Host ("  DUSMUS> {0} ({1}) sona ~{2} / m.6-8 sonu {3}" -f $m.ad,$m.no,$m.donem_sonu,$m.m68_son) }
  return
}

# --- Supabase ---------------------------------------------------------------
if(-not $env:SUPABASE_SERVICE_KEY){
  Write-Host "SUPABASE_SERVICE_KEY yok - cikildi (Actions'ta kosar). Elle test: -Unvan 'FIRMA ADI'"
  Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI - anahtar yok' }) -Depth 4) -Encoding UTF8 -NoNewline
  exit 0
}
$API_ADRES = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1"
$SB  = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
# NOT: -SkipHttpErrorCheck yalniz pwsh 7'de var; bu betik yerelde (PS 5.1) de
# kosabilsin diye hata yakalama try/catch ile yapiliyor. Yerelde kosabilmek
# onemli: rakip nobetini/uye hattini Actions'i beklemeden olcuyoruz.
# Ayrica gizli anahtar "browser" gorunen UA'yi reddediyor (16.08 dersi) ->
# her istekte robot UA'si gonderilir.
$UA = 'mevzuat-radar-robot/1.0'
function SbGet($yol){
  try{
    $w = Invoke-WebRequest -Uri "$API_ADRES/$yol" -Headers $SB -UserAgent $UA -UseBasicParsing -TimeoutSec 120
    $ham = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
    return @($ham | ConvertFrom-Json)
  }catch{
    $kod = 0; $govde = ''
    try{ $r=$_.Exception.Response; $kod=[int]$r.StatusCode; $sr=New-Object IO.StreamReader($r.GetResponseStream()); $govde=$sr.ReadToEnd() }catch{}
    throw ("Supabase GET {0} -> {1} {2}" -f $yol,$kod,$govde)
  }
}
function SbGonder($yol,$metot,$govde,$ekBaslik){
  $b = [Text.Encoding]::UTF8.GetBytes(($govde|ConvertTo-Json -Compress -Depth 8))
  $bsl = $SB + @{'Content-Type'='application/json'} + $ekBaslik
  try{
    $w = Invoke-WebRequest -Uri "$API_ADRES/$yol" -Method $metot -Headers $bsl -UserAgent $UA -Body $b -UseBasicParsing -TimeoutSec 90
    return [int]$w.StatusCode
  }catch{
    $kod = 0; $hata = ''
    try{ $r=$_.Exception.Response; $kod=[int]$r.StatusCode; $sr=New-Object IO.StreamReader($r.GetResponseStream()); $hata=$sr.ReadToEnd() }catch{}
    Write-Host ("  ! Supabase {0} {1}: {2} {3}" -f $metot,$yol,$kod,$hata)
    return $kod
  }
}

function MailAt($kime,$konu,$html,$duz){
  if(-not $env:RESEND_KEY -or $kuru){ return $false }
  $from = if($env:RESEND_FROM){ $env:RESEND_FROM } else { 'Tetikte <uyari@tetikte.com>' }
  $body = @{ from=$from; to=@($kime); reply_to='cem@dizdardenetim.com'; subject=$konu; html=$html; text=$duz; headers=@{ 'List-Unsubscribe'='<mailto:cem@dizdardenetim.com?subject=iptal>' } }
  try{
    $w = Invoke-WebRequest -Uri 'https://api.resend.com/emails' -Method Post -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')); 'Content-Type'='application/json' } -Body ([Text.Encoding]::UTF8.GetBytes(($body|ConvertTo-Json -Compress -Depth 6))) -UseBasicParsing -TimeoutSec 60 -SkipHttpErrorCheck
    return ([int]$w.StatusCode -lt 400)
  }catch{ return $false }
}
function SatirlarHtml($p){
  $s = ""
  foreach($m in (@($p.markalar) | Select-Object -First 40)){
    $etiket = switch($m.hal){ 'ek-sure'{'EK SÜRE'} 'yenileme-penceresi'{'YENİLEME AÇIK'} 'dusmus'{'DÜŞMÜŞ'} 'surecte'{'SÜREÇTE'} default{'güvende'} }
    $s += "<li><b>" + $m.ad + "</b> (" + $m.no + ", sınıf " + $m.sinif + ") — " + $etiket + ($(if($m.donem_sonu){ " · koruma bitişi " + $m.donem_sonu } else { "" })) + "</li>"
  }
  return $s
}

$uyeIslenen = 0; $uyeUyari = 0; $talepIslenen = 0; $mailAtilan = 0; $ornekler = New-Object System.Collections.Generic.List[object]
$rakipIslenen = 0; $rakipYeni = 0

# --- 0) RAKIP NOBETI (21.08) ------------------------------------------------
#  Kullanicinin ekledigi rakip unvanlarinin TR portfoyu her gun cekilir; onceki
#  kosuda gorulen basvuru numaralariyla karsilastirilir. YENI numara = rakip yeni
#  marka almis demektir -> uyari + mail. Ilk kosuda uyari URETILMEZ (o kosu
#  "temel" alinir), yoksa mevcut butun portfoyu "yeni" diye bildirirdik.
if($Rakip){
  $rakipler = @()
  try{ $rakipler = SbGet "marka_rakip?select=id,user_id,unvan,son_nolar,son_sayi&aktif=is.true" }catch{ Write-Host ("marka_rakip okunamadi (tablo yok olabilir): {0}" -f $_.Exception.Message) }
  # uyari maili icin kullanicinin adresini firmalar tablosundan al (ayri abone listesi acmiyoruz)
  $mailEsle = @{}
  try{ foreach($f in (SbGet "firmalar?select=user_id,email,kanal")){ if("$($f.email)" -and -not $mailEsle.ContainsKey("$($f.user_id)")){ $mailEsle["$($f.user_id)"] = [pscustomobject]@{ email="$($f.email)"; kanal="$($f.kanal)" } } } }catch{}
  foreach($r in $rakipler){
    $unv = "$($r.unvan)".Trim(); if($unv.Length -lt 3){ continue }
    try{ $p = PortfoyKur $unv }catch{ Write-Host ("  ! rakip {0}: {1}" -f $unv, $_.Exception.Message); continue }
    $rakipIslenen++
    $simdikiNolar = @(@($p.markalar) | ForEach-Object { "$($_.no)" } | Where-Object { $_ })
    # TUZAK (21.08 canli olcumde yakalandi): PowerShell'de @($null).Count = 1'dir.
    # son_nolar NULL gelen kayitta "ilk kosu" korumasi calismadi ve rakibin
    # MEVCUT butun portfoyu "yeni marka" diye uyariya donustu (Arcelik'te 1.120).
    # Bos/null elemanlar ayiklanarak sayilir.
    $eskiNolar = @(@($r.son_nolar) | Where-Object { "$_".Trim() })
    $ilkKosu = (@($eskiNolar).Count -eq 0)
    $yeniler = @()
    if(-not $ilkKosu){
      $eskiKume = @{}; foreach($n in $eskiNolar){ $eskiKume["$n"] = 1 }
      $yeniler = @(@($p.markalar) | Where-Object { -not $eskiKume.ContainsKey("$($_.no)") })
    }
    if(-not $kuru){
      SbGonder ("marka_rakip?id=eq." + [int]$r.id) "Patch" ([ordered]@{ son_nolar=$simdikiNolar; son_sayi=@($simdikiNolar).Count; guncelleme=(Get-Date).ToString('o') }) @{ Prefer='return=minimal' } | Out-Null
    }
    if(@($yeniler).Count -gt 0){
      $rakipYeni += @($yeniler).Count
      foreach($y in (@($yeniler) | Select-Object -First 20)){
        if(-not $kuru){
          SbGonder "marka_uyari" "Post" ([ordered]@{ user_id="$($r.user_id)"; marka=$unv; basvuru_no=("rakip|" + $y.no); benzer_ad=("" + $y.ad + " (sınıf " + $y.sinif + ", başvuru " + $y.tarih + ")"); risk=$null; sinif_cakisiyor=$false; basvuru_tarih=$y.tarih; durum=$y.durum; tip='rakip-yeni'; ofis='TR' }) @{ Prefer='return=minimal' } | Out-Null
        }
      }
      $alici = $mailEsle["$($r.user_id)"]
      if($alici -and "$($alici.kanal)" -eq 'mail' -and "$($alici.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){
        $satir = (@($yeniler) | Select-Object -First 20 | ForEach-Object { "<li><b>" + $_.ad + "</b> (" + $_.no + ", sınıf " + $_.sinif + ") — başvuru " + $_.tarih + ($(if($_.yayim){ "; bültende yayım " + $_.yayim } else { "" })) + "</li>" }) -join ""
        $duz   = (@($yeniler) | Select-Object -First 20 | ForEach-Object { "- " + $_.ad + " (" + $_.no + ", sinif " + $_.sinif + ") basvuru " + $_.tarih }) -join "`n"
        $html  = "<p>Merhaba,</p><p>İzlediğin <b>" + $unv + "</b> adına sicilde <b>" + @($yeniler).Count + " yeni marka kaydı</b> göründü:</p><ul>" + $satir + "</ul><p>Yayımlanan bir başvuruya itiraz süresi <b>yayımdan 2 aydır</b> (SMK m.18). Benzerlik değerlendirmesi için: https://tetikte.com/marka-itiraz.html</p><p>Tetikte</p><p style='color:#888;font-size:12px'>Bu maili rakip nöbeti kaydın için alıyorsun; kapatmak için bu maile 'iptal' yanıtı ver.</p>"
        if(MailAt $alici.email ("Rakip yeni marka aldı - " + $unv) $html ("Merhaba,`n`nIzledigin " + $unv + " adina sicilde " + @($yeniler).Count + " yeni marka kaydi gorundu:`n" + $duz + "`n`nYayimlanan basvuruya itiraz suresi yayimdan 2 aydir (SMK m.18).`nhttps://tetikte.com/marka-itiraz.html`n`nTetikte`nKapatmak icin bu maile 'iptal' yaniti ver.")){ $mailAtilan++ }
      }
    }
    if($ornekler.Count -lt 8){ $ornekler.Add([ordered]@{ rakip=$unv; marka=$p.sayi; yeni=@($yeniler).Count; ilk_kosu=$ilkKosu }) }
  }
  Write-Host ("Rakip nobeti: {0} unvan tarandi - {1} yeni kayit - {2} mail" -f $rakipIslenen,$rakipYeni,$mailAtilan)
}

# --- 1) UYE FIRMALARI -------------------------------------------------------
$firmalar = @()
if(-not $YalnizTalep -and -not $Rakip){ try{ $firmalar = SbGet "firmalar?select=id,user_id,email,firma_adi,kanal&firma_adi=not.is.null" }catch{ Write-Host ("firmalar okunamadi: {0}" -f $_.Exception.Message) }
foreach($f in $firmalar){
  $unv = "$($f.firma_adi)".Trim(); if($unv.Length -lt 3){ continue }
  try{ $p = PortfoyKur $unv }catch{ Write-Host ("  ! {0}: {1}" -f $unv, $_.Exception.Message); continue }
  $uyeIslenen++
  if($ornekler.Count -lt 8){ $ornekler.Add([ordered]@{ unvan=$unv; marka=$p.sayi; yenileme=$p.yenileme; ek_sure=$p.ek_surede; dusmus=$p.dusmus }) }
  if(-not $kuru){
    $kayit = [ordered]@{ user_id="$($f.user_id)"; unvan=$unv; varyantlar=@($p.varyantlar); marka_sayisi=$p.sayi; tescilli=$p.tescilli; yenileme_yakin=$p.yenileme; ek_surede=$p.ek_surede; dusmus=$p.dusmus; markalar=@($p.markalar); guncelleme=(Get-Date).ToString('o') }
    SbGonder "marka_portfoy?on_conflict=user_id,unvan" "Post" $kayit @{ Prefer='resolution=merge-duplicates,return=minimal' } | Out-Null
  }
  # kritik olanlar -> uyari + mail
  $kritik = @($p.markalar | Where-Object { $_.hal -eq 'yenileme-penceresi' -or $_.hal -eq 'ek-sure' })
  foreach($k in $kritik){
    $uyeUyari++
    if(-not $kuru){
      SbGonder "marka_uyari" "Post" ([ordered]@{ user_id="$($f.user_id)"; marka=$k.ad; basvuru_no=("portfoy-yenileme|" + $k.no); benzer_ad=$k.not; risk=$null; sinif_cakisiyor=$false; basvuru_tarih=$k.tarih; durum=$k.durum; tip='portfoy-yenileme'; ofis='TR' }) @{ Prefer='return=minimal' } | Out-Null
    }
  }
  if($kritik.Count -gt 0 -and "$($f.kanal)" -eq 'mail' -and "$($f.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){
    $satir = ($kritik | ForEach-Object { "<li><b>" + $_.ad + "</b> (" + $_.no + "): " + $_.not + "</li>" }) -join ""
    $duz   = ($kritik | ForEach-Object { "- " + $_.ad + " (" + $_.no + "): " + $_.not }) -join "`n"
    $html  = "<p>Merhaba,</p><p><b>" + $unv + "</b> adına sicilde görünen markalardan " + $kritik.Count + " tanesinin yenileme tarihi yaklaştı:</p><ul>" + $satir + "</ul><p>Yenileme talebi koruma bitişinden önceki 6 ay içinde verilir; kaçırılırsa 6 ay ek süre + ek ücret (SMK m.23). Panelden bak: https://tetikte.com/marka-portfoy.html</p><p>Tetikte</p><p style='color:#888;font-size:12px'>Bu maili marka radarı aboneliğin için alıyorsun; kapatmak için bu maile 'iptal' yanıtı ver.</p>"
    if(MailAt $f.email ("Marka yenileme uyarısı - " + $unv) $html ("Merhaba,`n`n" + $unv + " adına markalarında yenileme tarihi yaklaşan " + $kritik.Count + " kayıt var:`n" + $duz + "`n`nYenileme talebi bitişten önceki 6 ayda verilir; kaçarsa 6 ay ek süre + ek ücret (SMK m.23).`nPanel: https://tetikte.com/marka-portfoy.html`n`nTetikte`nKapatmak için bu maile 'iptal' yanıtı ver.")){ $mailAtilan++ }
  }
}

}   # <- if(-not $YalnizTalep)

# --- 2) VITRIN TALEPLERI ----------------------------------------------------
$talepler = @()
if(-not $YalnizUye -and -not $Rakip){
try{ $talepler = SbGet ("marka_talep?select=id,jeton,unvan,email,user_id&durum=eq.bekliyor&order=created_at.asc&limit=" + $TalepAdet) }catch{ Write-Host ("marka_talep okunamadi (tablo yok olabilir): {0}" -f $_.Exception.Message) }
foreach($t in $talepler){
  $unv = "$($t.unvan)".Trim()
  $sonucJson = $null; $hata = $null
  try{ $p = PortfoyKur $unv }catch{ $hata = $_.Exception.Message; $p = $null }
  if($p){
    $sonucJson = [ordered]@{ unvan=$p.unvan; varyantlar=@($p.varyantlar); sayi=$p.sayi; toplam=$p.toplam; tescilli=$p.tescilli; yenileme=$p.yenileme; ek_surede=$p.ek_surede; dusmus=$p.dusmus; surecte=$p.surecte; siniflar=@($p.siniflar); sinif_acigi=$p.sinif_acigi; kullanim_yakin=$p.kullanim_yakin; kullanim_dolmus=$p.kullanim_dolmus; markalar=@($p.markalar); adaylar=@($p.adaylar); aday_sayi=$p.aday_sayi }
  }
  $talepIslenen++
  # 21.08: Talep GIRIS YAPMIS bir uyeden geldiyse (RPC auth.uid() yaziyor) sonuc
  # ayni anda marka_portfoy'a da islenir -> panel bandi ertesi gunu beklemeden
  # dolar, ayrica yenileme uyarilari hemen uretilir. (Cem: "form ayni duruyor".)
  if($p -and "$($t.user_id)" -and -not $kuru){
    $kayitU = [ordered]@{ user_id="$($t.user_id)"; unvan=$unv; varyantlar=@($p.varyantlar); marka_sayisi=$p.sayi; tescilli=$p.tescilli; yenileme_yakin=$p.yenileme; ek_surede=$p.ek_surede; dusmus=$p.dusmus; markalar=@($p.markalar); guncelleme=(Get-Date).ToString('o') }
    SbGonder "marka_portfoy?on_conflict=user_id,unvan" "Post" $kayitU @{ Prefer='resolution=merge-duplicates,return=minimal' } | Out-Null
    foreach($k in @($p.markalar | Where-Object { $_.hal -eq 'yenileme-penceresi' -or $_.hal -eq 'ek-sure' })){
      SbGonder "marka_uyari" "Post" ([ordered]@{ user_id="$($t.user_id)"; marka=$k.ad; basvuru_no=("portfoy-yenileme|" + $k.no); benzer_ad=$k.not; risk=$null; sinif_cakisiyor=$false; basvuru_tarih=$k.tarih; durum=$k.durum; tip='portfoy-yenileme'; ofis='TR' }) @{ Prefer='return=minimal' } | Out-Null
    }
  }
  if(-not $kuru){
    $tDurum = 'hazir'; if($hata){ $tDurum = 'hata' }
    $govde = [ordered]@{ durum=$tDurum; sonuc=$sonucJson; hata=$hata; islendi_at=(Get-Date).ToString('o') }
    SbGonder ("marka_talep?jeton=eq." + [uri]::EscapeDataString("$($t.jeton)")) "Patch" $govde @{ Prefer='return=minimal' } | Out-Null
  }
  if($p -and "$($t.email)" -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'){
    $html = "<p>Merhaba,</p><p><b>" + $unv + "</b> için sicil taraması hazır: <b>" + $p.sayi + " marka</b> bulundu (" + $p.tescilli + " tescilli, " + $p.yenileme + " yenileme penceresi açık, " + $p.dusmus + " düşmüş).</p><ul>" + (SatirlarHtml $p) + "</ul><p>Tamamı ve tarih takvimi: https://tetikte.com/marka-portfoy.html?jeton=" + $t.jeton + "</p><p>Kaynak: TÜRKPATENT verisi (TMview). Koruma süresi başvurudan 10 yıl, yenileme son 6 ayda (SMK m.23). Sicil kaydını teyit etmeden işlem yapma.</p><p>Tetikte</p><p style='color:#888;font-size:12px'>Bu maili tetikte.com'da marka sorgusu yaptığın için alıyorsun; kapatmak için bu maile 'iptal' yanıtı ver.</p>"
    $duz  = "Merhaba,`n`n" + $unv + " icin sicil taramasi hazir: " + $p.sayi + " marka (" + $p.tescilli + " tescilli, " + $p.yenileme + " yenileme penceresi acik, " + $p.dusmus + " dusmus).`nTamami: https://tetikte.com/marka-portfoy.html?jeton=" + $t.jeton + "`n`nKaynak: TURKPATENT verisi (TMview). Koruma basvurudan 10 yil, yenileme son 6 ayda (SMK m.23).`n`nTetikte`nKapatmak icin bu maile 'iptal' yaniti ver."
    if(MailAt $t.email ("Marka taraması hazır - " + $unv) $html $duz){ $mailAtilan++ }
  }
}
}   # <- if(-not $YalnizUye)

# pwsh 7 hashtable literali icinde $(if(){}else{}) alt ifadesi "Argument types do
# not match" ile dustu (Actions kosusu #1) - degiskene alindi.
$mod = 'CANLI'; if($kuru){ $mod = 'KURU' }
$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $mod
  rakip_unvan = $rakipIslenen
  rakip_yeni_kayit = $rakipYeni
  uye_firma = $uyeIslenen
  uye_yenileme_uyarisi = $uyeUyari
  vitrin_talebi = $talepIslenen
  mail = $mailAtilan
  resend = [bool]$env:RESEND_KEY
  # DIKKAT: Generic.List'i hashtable degeri olarak @(...) ile sarmak PowerShell'de
  # "Argument types do not match" ile duser (olculdu: hem @{} hem [ordered]@{}).
  # ToArray() calisan tek bicim - Actions kosusu #2 bunun yuzunden dustu.
  ornekler = $ornekler.ToArray()
  not = "Unvan -> TMview autocomplete varyantlari -> fAName (OR) -> TR marka portfoyu. Koruma bitisi basvuru+10*n (SMK m.23); tescilli kayitta onceki donemler yenilenmis kabul edilir."
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $ozet -Depth 6) -Encoding UTF8 -NoNewline
Write-Host ("Uye firma: {0} - yenileme uyarisi: {1} - vitrin talebi: {2} - mail: {3}" -f $uyeIslenen,$uyeUyari,$talepIslenen,$mailAtilan)
