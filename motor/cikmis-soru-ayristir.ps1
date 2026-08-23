# ============================================================================
#  CIKMIS SINAV KITAPCIGI -> SORU SORU AYRISTIRICI - 08.08.2026
#
#  CEM: "ayristiriciyi duzelt ve hepsini yut"
#
#  ONCEKI KUSUR: siklar SATIR BASINDA aranıyordu. Olcum gosterdi ki kitapciklarda
#  siklar cogu zaman TEK SATIRDA yan yana yaziliyor: "A) I  B) II  C) III  D) IV
#  E) V". Bu yuzden A) bulunuyor (108/130) ama B) 77, E) 64'te kaliyordu ve
#  "en az 4 sik" sarti tutmadigi icin soru ATILIYORDU. Kitapcik basina 130
#  sorunun ancak ~58'i cikiyordu.
#
#  ONARIM: sik ayirici artik SATIR ICI calisir - metindeki "(A-E))" isaretlerini
#  SIRAYLA bulur ve aralarini boler. Hem satir basi hem yan yana yazimi tanir.
#
#  SUTUN: kitapciklar iki sutun; Xpdf pdftotext'in -marginl/-marginr secenekleri
#  ile her sutun ayri cikarilir (okuma sirasi bozulmasin diye).
#
#  Cikti: veri/cikmis-soru-ayrisma.json (sayim) + -yaz ile ambara tur='cikmis-soru'
#  BEDAVA.
# ============================================================================
param([switch]$yaz, [int]$tavan = 0, [string]$klasor = '', [string]$sinavAdi = '', [string]$desen = '*.pdf')
$ErrorActionPreference='Continue'
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
if($klasor -eq ''){ $klasor = Join-Path $env:TEMP 'cikmis-soru' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not (Test-Path $klasor)){ Write-Host "Klasor yok: $klasor"; exit 1 }

# --- SIK AYIRICI: satir ici VE satir basi ---
function SiklariAyir([string]$blok){
  $sonuc = [ordered]@{}
  $isaretler = @([regex]::Matches($blok, '(?<![A-Za-z0-9])([A-E])\)\s'))
  # NOT: burada "4'ten az isaret varsa cik" diye erken donus VARDI; asagidaki
  # OCR kurtarma yolunu tamamen olu birakiyordu (olculdu: kurtarilabilecek 25
  # soru hic denenmeden dusuyordu). Karar $ilkGecis sayildiktan sonra verilir.
  # 08.08 IKINCI ONARIM: ARTAN SIRA DAYATMASI KALDIRILDI.
  # Olcum: SGS 2026/2'de 130 sorunun 18'i dusuyordu ve sebep buydu - iki sutunlu
  # dizgide siklar metne SIRASIZ dokuluyor. Ornek soru 24:
  #     "A) politely  B) rapidly  D) silently  C) ..."
  # Eski kod A,B'yi alip C bekliyordu; D gorunce zincir kiriliyor, soru
  # "4 sik yok" diye ATILIYORDU. Oysa dort sik da oradaydi.
  # Yeni kural: her harfin ILK gecisi alinir, KONUMA gore siralanir. Sira
  # dayatilmaz; dilimleme yine konuma gore yapildigi icin her sikkin metni
  # dogru esler.
  $ilkGecis = @{}
  foreach($m in $isaretler){
    $h = $m.Groups[1].Value
    if(-not $ilkGecis.ContainsKey($h)){ $ilkGecis[$h] = $m }
  }

  # 23.08 UCUNCU ONARIM - OCR SIK ISARETI KURTARMA:
  # Taranmis kitapciklarda tesseract sik harfini bozuyor. Olculen bozulmalar
  # (6551, 15 Mayis 2016): "B)4" (bosluk yok), "©)" , "&)" , "8)" , "GC)" ,
  # "Dj)" , "g6". Siki desen bunlari gormeyince soru "4 sik yok" diye
  # ATILIYORDU: 143 sorunun 53'u dusuyordu (%51 kapsama).
  #
  # GLIFTEN HARFE ESLEME YAPILMAZ - guvenilmez. Olcum: ayni "©" isareti bir
  # soruda C, oteki soruda D yerine geciyor. Guvenilir olan KONUM: siklar
  # metinde her zaman A,B,C,D,E sirasiyla dokulur. Bu yuzden gevsek desenle
  # bulunan isaretler konuma gore A..E diye etiketlenir.
  #
  # Bu yol YALNIZ siki desen 4 sik bulamayinca devreye girer; saglam metinde
  # hicbir sey degismez (olculdu: 6558 72->72, SGS 2019 65->65, 6551 90->113).
  if($ilkGecis.Count -lt 4){
    $gevsek = @([regex]::Matches($blok, '(?<![A-Za-z0-9])([A-E©&Gg8])\s?\)\s*'))
    # 4-5 disi sayi = gurultu (metin icindeki parantezler). Uydurma yapma, birak.
    if($gevsek.Count -lt 4 -or $gevsek.Count -gt 5){ return $sonuc }
    $harfler = @('A','B','C','D','E')
    for($i=0; $i -lt $gevsek.Count; $i++){
      $bas = $gevsek[$i].Index + $gevsek[$i].Length
      $son = if($i -lt $gevsek.Count-1){ $gevsek[$i+1].Index } else { $blok.Length }
      $v = $blok.Substring($bas, [Math]::Max(0,$son-$bas))
      $sonuc[$harfler[$i]] = ($v -replace '\s+',' ').Trim()
    }
    return $sonuc
  }

  $sirali = New-Object System.Collections.Generic.List[object]
  foreach($m in ($ilkGecis.Values | Sort-Object { $_.Index })){ $sirali.Add($m) }
  for($i=0; $i -lt $sirali.Count; $i++){
    $bas = $sirali[$i].Index + $sirali[$i].Length
    $son = if($i -lt $sirali.Count-1){ $sirali[$i+1].Index } else { $blok.Length }
    $v = $blok.Substring($bas, [Math]::Max(0,$son-$bas))
    $sonuc[$sirali[$i].Groups[1].Value] = ($v -replace '\s+',' ').Trim()
  }
  return $sonuc
}

function SorulariCikar([string]$metin, [string]$stil = '.'){
  $liste = New-Object System.Collections.Generic.List[object]
  # NUMARALANDIRMA STILI (23.08.2026): iki bicim yasiyor ve karistirilamaz.
  #   "1. Asagidakilerden..."  -> eski KGK, SGS, TESMER
  #   "1) BOBI FRS'ye gore..." -> 2019 sonrasi KGK kitapciklari
  # Ayristirici yalnizca noktali bicimi taniyordu; 2019+ KGK kitapciklarinda
  # 40 soru yerine 1-2 soru cikariyordu. Iki stil AYRI ayri denenir (cagiran
  # taraf en cok soru vereni secer), cunku ayni metinde ikisini birden aramak
  # soru govdesindeki "1) ... 2) ..." madde listelerinde soruyu ortadan boler.
  $ayrac = if($stil -eq ')'){ '\)' } else { '\.' }
  #
  # MODUL INDEKSI: KGK kitapciklari modullu ve her modul 1'den basliyor
  # ("Muhasebe Standartlari 1-40", sonra "Denetim 1-40"...). SGS ise tek dizi
  # (1-130). Tekillestirme yalniz numaraya bakinca KGK'da 160 sorunun 120'si
  # eziliyordu. Cozum: numaranin GERILEDIGI yerde modul sayacini artir.
  #   SGS  -> modul hep 0, numara benzersiz  -> ust sinir 130
  #   KGK  -> modul 0,1,2,3 ; her birinde 1-40
  $modul = 0; $onceki = 0
  foreach($p in [regex]::Split($metin, ('(?m)^(?=\s{0,4}\d{1,3}' + $ayrac + '\s)'))){
    if($p.Trim().Length -lt 40){ continue }
    $no = [regex]::Match($p, ('^\s*(\d{1,3})' + $ayrac))
    if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value
    if($n -lt 1 -or $n -gt 130){ continue }
    $sk = SiklariAyir $p
    if($sk.Count -lt 4){ continue }
    # kok: ilk sik isaretine kadar
    $ilk = [regex]::Match($p, '(?<![A-Za-z0-9])A\)\s')
    $kk = if($ilk.Success){ $p.Substring(0, $ilk.Index) } else { $p }
    $kk = ($kk -replace ('^\s*\d{1,3}' + $ayrac + '\s*'),'') -replace '\s+',' '
    $kk = $kk.Trim()
    if($kk.Length -lt 15){ continue }
    if($n -le $onceki){ $modul++ }
    $onceki = $n
    $liste.Add([pscustomobject]@{ no=$n; modul=$modul; kok=$kk; siklar=$sk })
  }
  return $liste
}
# --- DOGRU pdftotext'i SEC (23.08.2026 tuzagi) ---
# Makinede IKI pdftotext var ve DAVRANISLARI FARKLI:
#   poppler  (...WinGet\Packages\...Poppler...\bin) -> -marginl/-marginr YOK, kod 99
#   xpdf 4.x (C:\Program Files\Git\mingw64\bin)     -> margin secenekleri VAR
# PowerShell PATH'inde poppler once geliyor, Git Bash'te xpdf. Bu yuzden ayni
# komut kabuga gore ya calisiyor ya sessizce cokuyor: sutun kirpmalari
# uretilemiyor, ayristirici tek-sutun metne dusuyor ve SGS 2019'da 130 yerine
# 114 soru cikariyordu. Kirpma destekleyen ikiliyi ACIKCA sec.
$PDFTOTEXT = 'pdftotext'
$KIRPMA_VAR = $false
$adaylar = @('C:\Program Files\Git\mingw64\bin\pdftotext.exe','C:\Program Files\Xpdf\bin64\pdftotext.exe')
foreach($c in @(Get-Command pdftotext -All -ErrorAction SilentlyContinue)){ $adaylar += $c.Source }
foreach($a in $adaylar){
  if(-not (Test-Path $a)){ continue }
  $y = & $a -h 2>&1 | Out-String
  if($y -match '-marginr'){ $PDFTOTEXT = $a; $KIRPMA_VAR = $true; break }
  if($PDFTOTEXT -eq 'pdftotext'){ $PDFTOTEXT = $a }
}
Write-Host ("pdftotext: {0}  (sutun kirpma: {1})" -f $PDFTOTEXT, $(if($KIRPMA_VAR){'VAR'}else{'YOK'}))
$pdfler = @(Get-ChildItem (Join-Path $klasor $desen) | Where-Object { $_.Extension -ieq ".pdf" } | Sort-Object Name)
if($tavan -gt 0){ $pdfler = @($pdfler | Select-Object -First $tavan) }
Write-Host ("Kitapcik: {0}" -f $pdfler.Count)

$AMBAR = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
if($yaz){
  if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
  Add-Type -AssemblyName System.Net.Http
  $hc=New-Object System.Net.Http.HttpClient
  $hc.Timeout=[TimeSpan]::FromSeconds(120)
  $hc.DefaultRequestHeaders.Add('apikey',$env:SUPABASE_SERVICE_KEY)
  $hc.DefaultRequestHeaders.Add('Authorization',('Bearer '+$env:SUPABASE_SERVICE_KEY))
  # 23.08.2026 MUKERRER KILIDI + TAZELEME:
  # kaynak_ad uzerinde benzersizlik kisiti YOK; betik her kosuda kosulsuz POST
  # atiyordu, ikinci kosu 149 belgeyi ikizlerdi. Ayrica modul-siniri kusuru
  # yuzunden ambardaki KGK belgeleri 40'ar soruyla eksik kaldi. Bu yuzden
  # sozluk kaynak_ad -> MEVCUT SORU SAYISI tutar:
  #   yok            -> POST
  #   var, yenisi cok -> PATCH (tazele)
  #   var, yenisi az  -> ATLA (gerileme yasak)
  $VAROLAN = @{}
  try {
    $m = Invoke-RestMethod -Uri ($AMBAR + '?select=kaynak_ad,baslik&tur=like.cikmis-soru*&limit=5000') `
         -Headers @{apikey=$env:SUPABASE_SERVICE_KEY; Authorization=('Bearer '+$env:SUPABASE_SERVICE_KEY)} `
         -UserAgent 'mevzuat-radar-robot/1.0'
    foreach($x in @($m)){
      $mm = [regex]::Match("$($x.baslik)", '-\s*(\d+)\s*soru\s*$')
      $VAROLAN["$($x.kaynak_ad)"] = if($mm.Success){ [int]$mm.Groups[1].Value } else { 0 }
    }
    Write-Host ("Ambarda zaten olan cikmis-soru belgesi: {0}" -f $VAROLAN.Count)
  } catch { Write-Host ('UYARI: mevcut liste cekilemedi, MUKERRER RISKI - ' + $_.Exception.Message); exit 1 }
}

  # Tekillestirme anahtari SADECE soru numarasiydi ($tekil[$s.no]). Bu iki
  # yonlu yanlisti:
  #   KGK  kitapciklari MODULLU, her modul 1'den basliyor -> 160 sorunun 120'si
  #        ustune yaziliyor, ambara 40 soru giriyordu (98 belgenin HEPSI eksikti).
  #   SGS  tek dizi (1-130); burada numara zaten benzersiz, sorun yok.
  # Cozum SorulariCikar icinde: numara GERILEDIGINDE modul sayaci artiyor.
  # Anahtar = modul + numara. Ayni sorunun farkli cikarimlari (sol/sag/duz/
  # layout) ayni anahtari verir -> sismez; farkli modulun ayni numarali sorusu
  # ayri anahtar alir -> kaybolmaz.
  function Anahtar($s){ return ('' + $s.modul + '#' + $s.no) }
function Boy([string]$p){ if(Test-Path $p){ (Get-Item $p).Length } else { 0 } }
$rapor = New-Object System.Collections.Generic.List[object]
$topSoru=0; $yazilan=0; $yazHata=0; $isle=0; $zatenVar=0; $tazelenen=0
foreach($f in $pdfler){
  $isle++
  # --- SINAV/DONEM COZUCU ---
  # Iki adlandirma yasiyor:
  #   eski hasat : "SGS-2015_1-16"        (tire ayrik, sonda sira no)
  #   yeni hasat : "sgs_2015_1_lisans_a"  (motor/sinav-kitapcik-indir.ps1)
  # Yeni adda tire yok; eski cozucu tum adi sinav adi sanip donemi BOS birakiyordu.
  $sv = ''; $don = ''
  $mm = [regex]::Match($f.BaseName, '^(sgs|smmm)_(\d{4})_(\d)(?:_|$)', 'IgnoreCase')
  if($mm.Success){
    $sv  = $mm.Groups[1].Value.ToUpperInvariant()
    $don = ('{0}/{1}' -f $mm.Groups[2].Value, $mm.Groups[3].Value)
  } else {
    $parca = $f.BaseName -split '-'
    $sv = $parca[0]
    if($parca.Count -gt 1){ $don = $parca[1] -replace '_','/' }
  }
  if($sinavAdi -ne ''){ $sv = $sinavAdi }
  # --- METIN KAYNAGI SECIMI (23.08.2026 onarimi) ---
  # Eskiden yalniz iki-sutun kirpmasi (.sol/.sag) okunuyordu. Olcum: uc kitapcik
  # ailesinde bu YOK hukmunde donuyor ve kitapcik sessizce dusuyordu:
  #   8166 (11 Kasim 2018)  Xerox tarama, metin katmani HIC YOK  -> pdftotext 34 bayt
  #   6551 (15 Mayis 2016)  CorelDRAW goruntu PDF                -> 31 bayt
  #   6557_SABAH (16 Mart 2014) metin var ama gomulu font bozuk  -> harf yiyor
  #
  # KURAL:
  #  (a) OCR ciktisi varsa YALNIZ o kullanilir. Cunku OCR'i zaten metin katmani
  #      bozuk oldugu icin cektik; bozuk katmani karistirmak coplu soru uretir.
  #  (b) OCR yoksa ELDEKI TUM cikarimlar birlestirilir: sutun kirpmalari,
  #      tek-sutun tam metin ve indiricinin urettigi -layout metni.
  #      Olcum (SGS 2005/1, 100 soruluk kitapcik): yalniz .duz -> 66 soru,
  #      -layout metni eklenince kapsama belirgin artiyor. Tekillestirme
  #      anahtari harf-rakam normalize oldugu icin ayni sorunun iki farkli
  #      cikarimi (tireli satir sonu dahil) ayni anahtari uretir, sismez.
  $ocr = Join-Path $klasor ($f.BaseName + '.ocr.txt')
  $duz = Join-Path $klasor ($f.BaseName + '.duz.txt')
  $sol = Join-Path $klasor ($f.BaseName + '.sol.txt')
  $sag = Join-Path $klasor ($f.BaseName + '.sag.txt')
  # indirici kardes klasore yaziyor: <arsiv>/pdf/x.pdf -> <arsiv>/txt/x.txt
  $kardes = Join-Path (Join-Path (Split-Path -Parent $klasor) 'txt') ($f.BaseName + '.txt')

  # --- ADAY CIKARIMLAR ---
  # Ayni PDF'ten dort ayri metin cikabilir ve hangisinin daha iyi oldugu
  # kitapcigin dizgisine gore degisiyor (olcum 23.08):
  #   SGS 2019  sutun 130/130,  layout 114
  #   SGS 2005  sutun  97/100
  #   KGK 6557_OGLE sutun 66,  layout daha iyi olabiliyor
  # AILELERI KARISTIRMA: modul sayaci "numara gerileyince yeni modul" der;
  # bu yalniz okuma sirasi dogru olan akista gecerli. Farkli aileleri
  # birlestirince indeksler kayip SGS'de 130 soru 199'a sismisti.
  # Bu yuzden her aile AYRI ayristirilir, EN COK soru vereni secilir.
  if($KIRPMA_VAR -and -not (Test-Path $sol)){ try { & $PDFTOTEXT -q -enc UTF-8 -marginr 300 $f.FullName $sol 2>&1 | Out-Null } catch {} }
  if($KIRPMA_VAR -and -not (Test-Path $sag)){ try { & $PDFTOTEXT -q -enc UTF-8 -marginl 295 $f.FullName $sag 2>&1 | Out-Null } catch {} }
  if((Boy $duz) -lt 1000){ try { & $PDFTOTEXT -q -enc UTF-8 $f.FullName $duz 2>&1 | Out-Null } catch {} }

  # OCR de OTEKILERLE YARISIR (23.08 duzeltmesi). Once "OCR varsa dogrudan
  # kazanir" kurali vardi; gerekcesi "bozuk metin katmani cop uretir" idi.
  # OLCULDU, gerekce yanlis cikti:
  #   6557_SABAH_A (gomulu font bozuk) metin katmaniyla 0 soru veriyor - bozuk
  #     metin yarisi zaten kaybediyor, korumaya gerek yok.
  #   10270 sabah A (metin katmani SAGLAM ama eksik) OCR ile 100, metinle 123.
  #     Kosulsuz OCR onceligi bu kitapcigi 123'ten 100'e DUSURUYORDU.
  # Kural: hepsini dene, en cok soru vereni al.
  $aileler = @()
  if((Boy $ocr)    -gt 3000){ $aileler += ,@('ocr',    @($ocr)) }
  if((Boy $sol) -gt 1000 -and (Boy $sag) -gt 1000){ $aileler += ,@('sutun', @($sol,$sag)) }
  if((Boy $kardes) -gt 1000){ $aileler += ,@('layout', @($kardes)) }
  if((Boy $duz)    -gt 1000){ $aileler += ,@('duz',    @($duz)) }

  # Her (cikarim ailesi x numaralandirma stili) ciftini AYRI dene, en cok
  # soru vereni sec. Iki boyut da olculdu (23.08): dizgiye gore kazanan
  # degisiyor ve yanlis secim kitapcigi sessizce olduruyor.
  $tekil = [ordered]@{}; $okumaTuru = 'OLCULEMEDI'
  foreach($aile in $aileler){
    foreach($stil in @('.', ')')){
      $t2 = [ordered]@{}
      $akis = 0
      foreach($t in @($aile[1])){
        $akis++
        if(-not (Test-Path $t)){ continue }
        foreach($s in (SorulariCikar (Get-Content $t -Raw -Encoding UTF8) $stil)){
          # ANAHTARA AKIS NUMARASI EKLENIR (23.08 dorduncu onarim):
          # sol ve sag sutun AYRI akislardir ve her biri kendi modul sayacini
          # tutar. Sayaclar senkron kalmaz - modul siniri iki sutunda ayni
          # yerde dusmez. Ortak anahtar kullanilinca FARKLI sorular carpisip
          # birbirini eziyordu. Olcum (6558_SABAH_A): sol 72 + sag 73 = 145 ham
          # soru, ortak anahtarla 124'e dusuyordu - 21 gercek soru kayip.
          # Sutunlar birbirini TAMAMLAR (ayni soru iki sutunda olmaz), o yuzden
          # akislari ayirmak mukerrer uretmez. Kirpma bindirmesinden dogabilecek
          # yarim kopyalari asagidaki guvenlik gecisi temizler.
          $a = "$akis|" + (Anahtar $s)
          if(-not $t2.Contains($a)){ $t2[$a] = $s }
          elseif($s.kok.Length -gt $t2[$a].kok.Length){ $t2[$a] = $s }
        }
      }
      if($t2.Count -gt $tekil.Count){
        $tekil = $t2
        $okumaTuru = $aile[0] + $(if($stil -eq ')'){ '/parantez' } else { '' })
      }
    }
  }
  # GUVENLIK GECISI: sutun kirpmasi sinirdaki bir soruyu IKI KEZ, biri YARIM
  # olacak sekilde yakalayabilir. Ayni numaraya sahip kayitlardan kok metni
  # digerinin ICINDE gecenleri (yarim yakalama / eksik bas) at.
  $numaraGrup = @{}
  foreach($a in @($tekil.Keys)){ $n2 = $tekil[$a].no; if(-not $numaraGrup.ContainsKey($n2)){ $numaraGrup[$n2] = New-Object System.Collections.Generic.List[string] }; $numaraGrup[$n2].Add($a) }
  foreach($n2 in $numaraGrup.Keys){
    $grup = @($numaraGrup[$n2])
    if($grup.Count -lt 2){ continue }
    $normal = @{}
    foreach($a in $grup){ $normal[$a] = ($tekil[$a].kok -replace '[^\p{L}\p{Nd}]','').ToLowerInvariant() }
    foreach($a in $grup){
      foreach($b in $grup){
        if($a -eq $b){ continue }
        if(-not $tekil.Contains($a) -or -not $tekil.Contains($b)){ continue }
        if($normal[$b].Length -gt $normal[$a].Length -and $normal[$b].Contains($normal[$a])){ $tekil.Remove($a); break }
      }
    }
  }
  $adet = $tekil.Count
  $topSoru += $adet
  $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; sinav=$sv; donem=$don; soru=$adet; okuma=$okumaTuru })
  if($yaz -and $adet -ge 20){
    $kad = 'CIKMIS SINAV - ' + $sv + ' ' + $don + ' (' + $f.BaseName + ')'
    $eski = -1
    if($VAROLAN.ContainsKey($kad)){ $eski = [int]$VAROLAN[$kad] }
    if($eski -ge $adet){ $zatenVar++; continue }   # var ve daha iyi/esit -> dokunma
    # kitapcigin TUM sorularini TEK belge olarak yaz (soru soru yazmak 130x193 kayit eder)
    $sb = New-Object Text.StringBuilder
    # Sira: kaynak metindeki gorulme sirasi korunur (ordered sozluk). Numaraya
    # gore siralamak modulleri birbirine karistirirdi (dort kez 1..40).
    foreach($a in $tekil.Keys){
      $s = $tekil[$a]
      [void]$sb.AppendLine(("SORU " + $s.no + ": " + $s.kok))
      foreach($h in $s.siklar.Keys){ [void]$sb.AppendLine(("  " + $h + ") " + $s.siklar[$h])) }
      [void]$sb.AppendLine('')
    }
    $tazele = ($eski -ge 0)
    $govde=[ordered]@{
      kaynak_ad=$kad
      baslik=('Cikmis sinav sorulari - ' + $sv + ' ' + $don + ' - ' + $adet + ' soru')
      tur='cikmis-soru'
      metin=$sb.ToString()
    }
    if(-not $tazele){ $govde.Insert(0,'id',([guid]::NewGuid().ToString())) }
    $j = ConvertTo-Json -InputObject $govde -Depth 4 -Compress
    if($tazele){
      # PATCH: kaynak_ad'i URL'de suzeriz. Turkce/parantezli ad oldugu icin kacisla.
      $u = $AMBAR + '?kaynak_ad=eq.' + [uri]::EscapeDataString($kad)
      $i2 = New-Object System.Net.Http.HttpRequestMessage (New-Object System.Net.Http.HttpMethod 'PATCH'),$u
    } else {
      $i2 = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post),$AMBAR
    }
    $i2.Content = New-Object System.Net.Http.StringContent ($j,[Text.Encoding]::UTF8,'application/json')
    $i2.Headers.Add('Prefer','return=minimal')
    $c = $hc.SendAsync($i2).GetAwaiter().GetResult()
    $kod = [int]$c.StatusCode
    if($kod -eq 201 -or $kod -eq 204){
      if($tazele){ $tazelenen++; Write-Host ("  TAZELE {0}: {1} -> {2} soru" -f $f.BaseName,$eski,$adet) } else { $yazilan++ }
    } else {
      $yazHata++; if($yazHata -le 3){ Write-Host ('  YAZMA HATASI kod ' + $kod + ' - ' + $c.Content.ReadAsStringAsync().GetAwaiter().GetResult()) }
    }
    $c.Dispose(); $i2.Dispose()
  }
  if($isle % 25 -eq 0){ Write-Host ("  ... {0}/{1}" -f $isle,$pdfler.Count) }
}
Write-Host "`n--- SINAV BAZINDA ---"
Write-Host ("{0,-8} {1,9} {2,9} {3,10}" -f 'SINAV','KITAPCIK','SORU','SORU/KIT')
foreach($sv in ($rapor.sinav | Sort-Object -Unique)){
  $g = @($rapor | Where-Object { $_.sinav -eq $sv })
  $s = ($g | Measure-Object -Property soru -Sum).Sum
  Write-Host ("{0,-8} {1,9} {2,9} {3,10}" -f $sv,$g.Count,$s,[math]::Round($s/[math]::Max($g.Count,1),1))
}
Write-Host "`n--- OKUMA TURU ---"
foreach($ot in ($rapor.okuma | Sort-Object -Unique)){ Write-Host ("  {0,-12} {1} kitapcik" -f $ot, @($rapor | Where-Object { $_.okuma -eq $ot }).Count) }
Write-Host ("`nTOPLAM AYRISAN SORU: {0}" -f $topSoru)
if($yaz){ Write-Host ("AMBARA YENI YAZILAN: {0} | TAZELENEN: {1} | DOKUNULMAYAN: {2} | HATA: {3}" -f $yazilan,$tazelenen,$zatenVar,$yazHata) }
[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-soru-ayrisma.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); toplamSoru=$topSoru; yazilan=$yazilan; kitapciklar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host "Rapor: veri/cikmis-soru-ayrisma.json"
