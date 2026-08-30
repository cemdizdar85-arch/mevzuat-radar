# ============================================================================
#  İTİRAZ RADARI — HASAT  (29.08.2026, Cem "onay veriyorum itiraz radarını kur")
#
#  NE YAPAR: TÜRKPATENT bülteninde YAYIMLANMIŞ, itiraz süresi HÂLÂ AÇIK olan
#  markaları çeker. Kullanıcının markasına benzeyen bir başvuru yayımlandıysa
#  itiraz süresi YAYIMDAN İKİ AYDIR (SMK m.18) ve kaçan süre geri gelmez.
#
#  KAYNAK KARARI: Marka Bülteni PDF'i 576 MB ve gövdesi font-şifreli. GEREK YOK.
#  TMview'in fCOpposable süzgeci bültenin API karşılığıdır — kimliksiz,
#  CAPTCHA'sız, 0 USD.
#
#  ── 29.08 ÖLÇÜLEN GERÇEKLER (hepsi bu betiğin tasarımını belirledi) ────────
#  · uç: POST https://www.tmdn.org/tmview/api/search/results?translate=true
#  · pageSize TAVANI 100 — 200/300/500 denendi, üçü de HTTP 400.
#  · page*pageSize ≤ 10.000 — sayfa 101 BOŞ döner (ES max_result_window).
#  · sıralama parametresi `desc`, `sortDesc` DEĞİL. `sortDesc` sessizce yok
#    sayılır ve liste artan sırada gelir; ilk ölçümüm bu yüzden "en yeni"
#    sandığım şeyi EN ESKİ olarak okumuştu.
#  · toplam fCOpposable TR kaydı: 17.660 (29.08.2026).
#  · desc geçişi 100. sayfada 2026-07-27'ye iner; asc geçişi 100. sayfada
#    2026-08-12'ye çıkar → İKİ GEÇİŞ ÖRTÜŞÜR, birleşimi 17.660'ın tamamını
#    kapsar (2 × 10.000 > 17.660). Tek geçişle iki aylık pencere KAPANMAZ.
#  · bülten günleri ayın 12'si ve 27'si.
#
#  ── 🔴 KAYNAĞIN BİTİŞ TARİHİ TÜRKİYE İÇİN YANLIŞ ─────────────────────────
#  Ölçüldü: oppositionPeriodEnd − oppositionPeriodStart = TAM 92 GÜN (~3 ay).
#  SMK m.18 ise İKİ AY. Kaynağın tarihini gösterirsek, süresi ÇOKTAN DOLMUŞ
#  bir başvuru için kullanıcıya "hâlâ vaktin var" demiş oluruz — ürünün
#  vaadinin tam tersi ve hukuken sonuç doğuran bir yanlış.
#  KURAL: son_gun = oppositionPeriodStart + 2 AY. Kaynağın bitiş alanı
#  (oppositionPeriodEnd / oppositionDeadLine) HİÇ KULLANILMAZ.
#
#  ── ÇÖP AYIKLAMA (kaynakta gerçekten var) ────────────────────────────────
#  · "sf sporfashion" 2012-01614: durum "Tescilli", penceresi 9.315 GÜN.
#    Ölçüt: pencere > 100 gün ya da durum "Tescilli"/"Registered" → ELENİR.
#  · Süresi SMK'ya göre dolmuş kayıtlar kaynakta hâlâ "itiraz edilebilir"
#    görünüyor (2026-06-12 yayımlılar 29.08'de dolmuştu) → ELENİR.
#
#  ── SAHİP ADI YOK ────────────────────────────────────────────────────────
#  Ölçüldü: yayımlanmış kayıtlarda bile applicantName =
#  "Legally Restricted Until Publication Date". Yani BAŞVURU SAHİBİNİ
#  GÖSTEREMEYİZ. Kart bunu açıkça söyler, uydurmaz.
#
#  ÇIKTI: veri/marka-itiraz-acik.json — kompakt dizi (nesne dizisi 6× yer
#  kaplıyordu; marka-yeni-basvurular.json'da ölçülmüştü: 5,2 MB → 0,88 MB).
#  BİRİKİMLİ: ambar yüklenir, yeni gelenle birleşir; son_gun + 15 günden
#  eski kayıt düşer.
#
#  ÖZ-SINAV: yazmadan önce tarih matematiği bilinen vakalarla sınanır.
#  Sınav düşerse DOSYA YAZILMAZ (yanlış tarih basmaktansa eski dosya kalsın).
#
#  Kullanım:
#    ./motor/marka-itiraz-hasat.ps1                 (canlı hasat)
#    ./motor/marka-itiraz-hasat.ps1 -Numune yol.json  (ağa çıkmadan mantık sınavı)
#    ./motor/marka-itiraz-hasat.ps1 -Kuru           (çek, yazma)
# ============================================================================
param(
  [string]$Numune,
  [switch]$Kuru,
  [int]$AyPencere = 2,      # SMK m.18 - iki ay. Degistirilmesi KANUN degisikligi ister.
  [int]$Retansiyon = 15     # son gunu gecen kayit kac gun daha ambarda kalsin
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/marka-itiraz-acik.json'
$raporYol = Join-Path $kok 'veri/marka-itiraz-raporu.json'
$UC = 'https://www.tmdn.org/tmview/api/search/results?translate=true'
$ALANLAR = @('tmName','applicationNumber','applicationDate','tradeMarkStatus','niceClass','ST13','oppositionPeriodStart','oppositionPeriodEnd')

$simdi = (Get-Date).Date
$sinir = $simdi.AddMonths(-$AyPencere)   # bu tarihten once yayimlananin suresi dolmus

# --- tarih yardimcilari ------------------------------------------------------
function IsoTarih([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return $null }
  try { return ([datetime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AdjustToUniversal)).Date } catch { return $null }
}
# SMK m.18: yayimdan iki ay. AddMonths ay sonlarini dogru tasir (31 Aralik + 2 ay = 28/29 Subat).
function SonGun([datetime]$yayim){ return $yayim.AddMonths($AyPencere) }

# --- OZ-SINAV: karar veren her betigin kendi sinavi olur ---------------------
# Sinav DUSERSE dosya YAZILMAZ. Yanlis tarih basmaktansa eski dosya kalsin.
function OzSinav(){
  $vakalar = @(
    @{ yayim='2026-08-27'; bekle='2026-10-27' },   # duz ay
    @{ yayim='2026-06-12'; bekle='2026-08-12' },   # 29.08'de DOLMUS olan gercek vaka
    @{ yayim='2025-12-31'; bekle='2026-02-28' },   # ay sonu tasmasi (Subat 28)
    @{ yayim='2027-12-31'; bekle='2028-02-29' },   # arti yil
    @{ yayim='2026-01-31'; bekle='2026-03-31' }
  )
  foreach($v in $vakalar){
    $c = (SonGun ([datetime]::ParseExact($v.yayim,'yyyy-MM-dd',$null))).ToString('yyyy-MM-dd')
    if($c -ne $v.bekle){ throw "OZ-SINAV DUSTU: $($v.yayim) + $AyPencere ay = $c, beklenen $($v.bekle)" }
  }
  # Kaynagin 92 gunune ASLA guvenmedigimizin sinavi: 92 gun eklemek 2 aydan farkli olmali
  $ornek = [datetime]::ParseExact('2026-08-27','yyyy-MM-dd',$null)
  if((SonGun $ornek) -eq $ornek.AddDays(92)){ throw 'OZ-SINAV DUSTU: iki ay ile 92 gun ayni cikti - kaynagin tarihine kaymis olabiliriz' }
  return $vakalar.Count
}

# --- kaynak cagrisi: bot korumasi freni -------------------------------------
# 20.08'de yasandi: TMview cok istekten sonra HTTP 200 dondurup govdede JS
# challenge SAYFASI veriyor. Sessizce yutulursa "hicbir yeni basvuru yok"
# diye YANLIS cevap uretir. Govde JSON mu diye BAKILIR.
function Cek([int]$sayfa, [bool]$desc){
  $govde = @{ page=$sayfa; pageSize=100; criteria='C'; basicSearch=''
              fOffices=@('TR'); fCOpposable=$true
              sortColumn='oppositionPeriodStart'; desc=$desc; fields=$ALANLAR } | ConvertTo-Json -Depth 4 -Compress
  for($d=1; $d -le 3; $d++){
    try{
      $w = Invoke-WebRequest -Uri $UC -Method Post -ContentType 'application/json' `
             -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 90
      # PS 5.1 mojibake tuzagi: .Content Latin-1 varsayar, Turkce harfleri bozar.
      $metin = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
      if(-not $metin.TrimStart().StartsWith('{')){ throw 'govde JSON degil (bot korumasi olabilir)' }
      return ($metin | ConvertFrom-Json)
    }catch{
      if($d -eq 3){ throw "TMview sayfa $sayfa (desc=$desc) alinamadi: $($_.Exception.Message)" }
      Start-Sleep -Seconds (4 * $d)
    }
  }
}

# --- ayikla: cop ele, SMK penceresi disini ele ------------------------------
function Ayikla($kayitlar){
  $cikan = New-Object 'System.Collections.Generic.List[object]'
  foreach($r in $kayitlar){
    $bas = IsoTarih $r.oppositionPeriodStart
    if(-not $bas){ continue }
    $bit = IsoTarih $r.oppositionPeriodEnd
    # COP 1: pencere 100 gunden uzun (gercek vaka: 9.315 gun, 2012 tarihli)
    if($bit -and ($bit - $bas).TotalDays -gt 100){ continue }
    # COP 2: zaten TESCILLI - itiraz suresi olan sey basvurudur
    if("$($r.tradeMarkStatus)" -match '(?i)(tescil|regist)'){ continue }
    # SMK m.18 penceresi: yayim tarihi sinirin gerisindeyse sure DOLMUS
    if($bas -lt $sinir){ continue }
    $son = SonGun $bas
    if($son -lt $simdi){ continue }
    $cikan.Add([pscustomobject]@{
      ad     = "$($r.tmName)"
      no     = "$($r.applicationNumber)"
      sinif  = (@($r.niceClass) | Where-Object { $_ -ne $null }) -join ','
      yayim  = $bas.ToString('yyyy-MM-dd')
      songun = $son.ToString('yyyy-MM-dd')
      st13   = "$($r.ST13)"
    })
  }
  return $cikan
}

# --- 1) kayitlari topla ------------------------------------------------------
$ham = New-Object 'System.Collections.Generic.List[object]'
$kaynakNot = ''
if($Numune){
  $n = Get-Content -LiteralPath $Numune -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($x in @($n.tradeMarks)){ $ham.Add($x) }
  $kaynakNot = "numune: $Numune"
  Write-Host "NUMUNE MODU - aga cikilmadi. $($ham.Count) kayit okundu."
}else{
  # desc gecisi: en yeni bultenden geriye. Pencere disina cikinca DUR.
  $sayfa = 1; $descBitti = $false
  while($sayfa -le 100 -and -not $descBitti){
    $j = Cek $sayfa $true
    $m = @($j.tradeMarks)
    if($m.Count -eq 0){ break }
    foreach($x in $m){ $ham.Add($x) }
    $sonBas = IsoTarih $m[$m.Count-1].oppositionPeriodStart
    if($sonBas -and $sonBas -lt $sinir){ $descBitti = $true }
    $sayfa++
    Start-Sleep -Milliseconds 400
  }
  $descSayfa = $sayfa - 1

  # asc gecisi YALNIZCA gerekiyorsa: desc 10.000 tavanina dayandiysa
  # pencerenin eski ucu disarida kalmistir (olculdu: desc 100. sayfada
  # 2026-07-27'ye iniyor, pencere 2026-06-29'a kadar gidiyor).
  $ascSayfa = 0
  if(-not $descBitti){
    # ikili arama: basi sinirdan buyuk/esit olan ILK asc sayfasi
    $alt = 1; $ust = 100
    while($alt -lt $ust){
      $orta = [int][math]::Floor(($alt + $ust) / 2)
      $j = Cek $orta $false
      $m = @($j.tradeMarks)
      if($m.Count -eq 0){ $ust = $orta - 1; continue }
      $sonBas = IsoTarih $m[$m.Count-1].oppositionPeriodStart
      if($sonBas -and $sonBas -lt $sinir){ $alt = $orta + 1 } else { $ust = $orta }
      Start-Sleep -Milliseconds 400
    }
    for($s=$alt; $s -le 100; $s++){
      $j = Cek $s $false
      $m = @($j.tradeMarks)
      if($m.Count -eq 0){ break }
      foreach($x in $m){ $ham.Add($x) }
      $ascSayfa++
      Start-Sleep -Milliseconds 400
    }
  }
  $kaynakNot = "canli: desc $descSayfa sayfa + asc $ascSayfa sayfa"
  Write-Host "TMview: $kaynakNot -> ham $($ham.Count) kayit"
}

# --- 2) oz-sinav (yazmadan ONCE) --------------------------------------------
$sinavVaka = OzSinav
Write-Host "Oz-sinav gecti: $sinavVaka tarih vakasi + 92-gun tuzagi."

# --- 3) ayikla + tekille ----------------------------------------------------
$temiz = Ayikla $ham
$elenen = $ham.Count - $temiz.Count
$harita = @{}
foreach($r in $temiz){ if($r.no -and -not $harita.ContainsKey($r.no)){ $harita[$r.no] = $r } }

# --- 4) birikimli birlestir --------------------------------------------------
# Kaynak pencereyi geriye dogru tasimiyor; dun gordugumuz kayit bugun tavanin
# arkasinda kalabilir. Ambar korunur, yalnizca suresi gecmisler dusurulur.
$eskiSayi = 0
if(Test-Path $ciktiYol){
  try{
    $e = Get-Content -LiteralPath $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $kol = @($e.kolon)
    foreach($sat in @($e.kayitlar)){
      $o = [pscustomobject]@{ ad=$sat[0]; no=$sat[1]; sinif=$sat[2]; yayim=$sat[3]; songun=$sat[4]; st13=$sat[5] }
      $eskiSayi++
      if($harita.ContainsKey($o.no)){ continue }
      $sg = IsoTarih $o.songun
      if($sg -and $sg -ge $simdi.AddDays(-$Retansiyon)){ $harita[$o.no] = $o }
    }
  }catch{ Write-Host "  (eski ambar okunamadi, sifirdan yaziliyor: $($_.Exception.Message))" }
}

$son = @($harita.Values | Sort-Object songun, ad)

# --- 5) SON KAPI: tek bir kayit bile 2 ay kuralindan sapmissa YAZMA ---------
foreach($r in $son){
  $y = IsoTarih $r.yayim; $s = IsoTarih $r.songun
  if(-not $y -or -not $s -or (SonGun $y) -ne $s){
    throw "TARIH KAPISI DUSTU: $($r.no) yayim $($r.yayim) -> songun $($r.songun); beklenen $((SonGun $y).ToString('yyyy-MM-dd'))"
  }
}
Write-Host "Tarih kapisi: $($son.Count) kaydin hepsi yayim + $AyPencere ay kuralina uyuyor."

# --- 6) yaz (kompakt dizi) ---------------------------------------------------
# PS 5.1 ConvertTo-Json IC DIZILERI {value,Count} icine sarar (bilinen kusur,
# istemci okuyamaz). Govde ELLE kurulur.
function JStr([string]$s){
  if($null -eq $s){ return '""' }
  $t = $s -replace '\\','\\\\' -replace '"','\"' -replace "`r",'' -replace "`n",' '
  return '"' + $t + '"'
}
$acil = @($son | Where-Object { $d = (IsoTarih $_.songun); $d -and ($d - $simdi).TotalDays -le 15 }).Count
if($Kuru){
  Write-Host "KURU KOSU - yazilmadi. temiz $($son.Count) | elenen $elenen | 15 gunden az kalan $acil"
  return
}
$satirlar = foreach($r in $son){
  '[' + (JStr $r.ad) + ',' + (JStr $r.no) + ',' + (JStr $r.sinif) + ',' + (JStr $r.yayim) + ',' + (JStr $r.songun) + ',' + (JStr $r.st13) + ']'
}
$govde = '{"hazir":' + $(if($Numune){'false'}else{'true'}) + ',"guncelleme":' + (JStr (Get-Date -Format 'yyyy-MM-dd HH:mm')) +
         ',"dayanak":"SMK m.18 - yayimdan iki ay. Kaynagin 92 gunluk penceresi KULLANILMADI."' +
         ',"sahip_notu":"Basvuru sahibi TMview-de yayima kadar gizli (Legally Restricted Until Publication Date) - gosterilmez."' +
         ',"kaynak":' + (JStr $kaynakNot) +
         ',"kolon":["ad","no","sinif","yayim","songun","st13"]' +
         ',"sayi":' + $son.Count +
         ',"kayitlar":[' + ($satirlar -join ',') + ']}'
[IO.File]::WriteAllText($ciktiYol, $govde, (New-Object Text.UTF8Encoding($false)))

# geri okuma: yazdigimizi gercekten okuyabiliyor muyuz
$geri = Get-Content -LiteralPath $ciktiYol -Raw -Encoding UTF8 | ConvertFrom-Json
if(@($geri.kayitlar).Count -ne $son.Count){ throw "GERI OKUMA TUTMADI: yazilan $($son.Count), okunan $(@($geri.kayitlar).Count)" }

$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynak = $kaynakNot
  ham = $ham.Count; elenen = $elenen; temiz = $son.Count
  eski_ambar = $eskiSayi; acil_15gun = $acil
  pencere_ay = $AyPencere; retansiyon_gun = $Retansiyon
}
[IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $rapor -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host "YAZILDI: $ciktiYol"
Write-Host "  ham $($ham.Count) | elenen $elenen | acik $($son.Count) | 15 gunden az kalan $acil"
