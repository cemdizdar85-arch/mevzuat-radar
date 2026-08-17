# ============================================================================
#  TEBLIG YAPI CIKARICI  (17.08.2026 — Cem: "RG'yi ayrintisina kadar okuyup
#  'bak bu' demiyoruz; eski yeni karsilastirmasi iyi degil")
#
#  NEDEN VAR: 01.08.2026 doviz donusum destegi karti eski_yeni alani BOS
#  cikmisti. Guven notu sebebini yaziyordu: "Eski-yeni karsilastirmasi iki
#  okumada uyusmadi - yayinlanmadi." Oysa tebligde ders kitabi orneği vardi:
#      gecici 1 inci maddedeki "31/7/2026" ibaresi "31/1/2027" seklinde
#      degistirilmistir
#  Bu cumle MODEL ISI DEGIL. Turk mevzuatinin standart kalibidir; duz metin
#  eslemesiyle hatasiz cikar. Iki LLM okumasinin ANLASMASINA baglamak, kesin
#  bilgiyi zar atmaya cevirmekti. Artik: deterministik cikarim BIRINCIL kaynak,
#  modelin bulduklari yalnizca EK.
#
#  CIKARDIKLARI (hepsi metinden, hicbiri yorum):
#    teblig_no            tebligin KENDI numarasi        (SAYI: 2026/11)
#    degistirilen_teblig  degistirdigi teblig            (Sayi: 2023/5)
#    ibare[]              eski -> yeni ciftleri          31/7/2026 -> 31/1/2027
#    kaldirilan[]         yururlukten kaldirilan madde   6 nci madde
#    eklenen[]            eklenen madde numaralari       4/A, 6/A, 6/B
#    degisen[]            tumuyle degistirilen madde     4 uncu madde
#    yururluk[]           BENT BENT yururluk             6 nci madde: yayimi
#                                                        digerleri: 01.10.2026
#
#  PS 5.1 TUZAKLARI (ucu de daha once kanadi):
#   - Dosya BOM'lu UTF-8 kaydedilir; BOM'suzda non-ASCII regex bozuk okunur.
#   - Turkce harf literal KARAKTER SINIFINA konmaz ([a-zçğı] gibi) - invariant
#     kulturde eslesmez. Kelimeler duz literal olarak yazilir.
#   - @(Generic.List) ArgumentException verir -> .ToArray() kullanilir.
#
#  Kullanim:  .\teblig-yapi.ps1 -Dosya motor\arsiv\01-08-2026\20260801-4.htm
#  Dot-source edilince: TebligYapiCikar <htm yolu>  -> hashtable
# ============================================================================
param([string]$Dosya, [switch]$Json)

# RG dosyalari Windows-1254; UTF-8 okunursa Turkce harfler bozulur.
function TebligMetni([string]$yol){
  $ham = [IO.File]::ReadAllText($yol, [Text.Encoding]::GetEncoding(1254))
  $t = $ham -replace '(?s)<(script|style)[^>]*>.*?</\1>',' '
  $t = $t -replace '(?s)<!--.*?-->',' '
  $t = $t -replace '<[^>]+>',' '
  $t = [Net.WebUtility]::HtmlDecode($t)
  # Bosluk normallestirme SART: RG metninde kelimeler satir sonuyla bolunuyor
  # ("6\nmaddesi"), ayrica &nbsp; (U+00A0) var. Desenler tek bosluga gore yazilir.
  $t = $t -replace "[  -​]", ' '
  $t = $t -replace '\s+', ' '
  return $t.Trim()
}

# Tipografik tirnak (U+201C/201D) ve duz tirnak birlikte kabul edilir.
$TIRNAK_AC  = '[“”"]'
$TIRNAK_KAP = '[“”"]'
$TIRNAKSIZ  = '[^“”"]'

function TebligYapiCikar([string]$yol){
  $metin = TebligMetni $yol
  $sonuc = [ordered]@{
    teblig_no = $null; degistirilen_teblig = $null
    ibare = @(); kaldirilan = @(); eklenen = @(); degisen = @(); yururluk = @()
    madde_sayisi = 0
  }
  if(-not $metin){ return $sonuc }

  # --- tebligi KENDI maddelerine bol ---------------------------------------
  # "MADDE 4/A-" ve "GECICI MADDE 2-" tirnak icindeki EKLENEN maddelerdir,
  # tebligin kendi numaralandirmasi degil. Ikisini de disarida birakiyoruz:
  #   - \d{1,2}- kalibi "4/A-" ile eslesmez (4'ten sonra '/' geliyor)
  #   - "GECICI MADDE 2-" icin geriye bakis
  $bolucu = [regex]'(?<!GEÇİCİ )(?<!Geçici )MADDE\s+(\d{1,2})\s*-'
  $eslesme = @($bolucu.Matches($metin))
  $sonuc.madde_sayisi = $eslesme.Count
  $bloklar = @()
  for($i=0; $i -lt $eslesme.Count; $i++){
    $bas = $eslesme[$i].Index
    $son = if($i+1 -lt $eslesme.Count){ $eslesme[$i+1].Index } else { $metin.Length }
    $bloklar += [pscustomobject]@{
      no    = $eslesme[$i].Groups[1].Value
      metin = $metin.Substring($bas, $son-$bas)
    }
  }
  if(-not $bloklar.Count){ $bloklar = @([pscustomobject]@{ no='?'; metin=$metin }) }

  # --- teblig numaralari: YALNIZ BASLIK BOLGESINDEN ------------------------
  # Basligin sabit kalibi:
  #   "...HAKKINDA TEBLİĞ (SAYI: 2023/5)'DE DEĞİŞİKLİK YAPILMASINA DAİR
  #    TEBLİĞ (SAYI: 2026/11)"
  # yani ilki DEGISTIRILEN, sonuncusu TEBLIGIN KENDISI.
  # DIKKAT: arama tum metinde yapilamaz - MADDE 1 de eski tebligi anar
  # ("...Teblig (Sayi: 2023/5)'in 3 uncu maddesinin..."), o yuzden "son gecen"
  # kurali tum metinde 2023/5 dondururdu (17.08'de bu hatayi verdi).
  $baslikSonu = if($eslesme.Count){ $eslesme[0].Index } else { [math]::Min(600, $metin.Length) }
  $baslik = $metin.Substring(0, $baslikSonu)
  $sayilar = @([regex]::Matches($baslik, '(?i)\(\s*SAY[Iİ]\s*:\s*(\d{4}/\d{1,3})\s*\)') | ForEach-Object { $_.Groups[1].Value })
  if($sayilar.Count -ge 2){
    $sonuc.degistirilen_teblig = $sayilar[0]
    $sonuc.teblig_no           = $sayilar[$sayilar.Count-1]
  } elseif($sayilar.Count -eq 1){
    # Degisiklik tebligi degil, kendi basina teblig
    $sonuc.teblig_no = $sayilar[0]
  }

  $ibareler   = New-Object System.Collections.Generic.List[object]
  $kaldirilan = New-Object System.Collections.Generic.List[object]
  $eklenen    = New-Object System.Collections.Generic.List[object]
  $degisen    = New-Object System.Collections.Generic.List[object]

  foreach($b in $bloklar){
    $bm = $b.metin

    # (1) IBARE DEGISIKLIGI - en degerli desen, tam belirleyici.
    #     "X" ibaresi/ibareleri "Y" seklinde/olarak degistirilmistir
    $rx = [regex]("(?s)" + $TIRNAK_AC + "(" + $TIRNAKSIZ + "{1,160})" + $TIRNAK_KAP +
                  "\s*ibare(?:si|leri)\s*,?\s*" +
                  $TIRNAK_AC + "(" + $TIRNAKSIZ + "{1,160})" + $TIRNAK_KAP +
                  "\s*(?:şeklinde|olarak)\s*değiştiril")
    foreach($x in $rx.Matches($bm)){
      $eski = $x.Groups[1].Value.Trim()
      $yeni = $x.Groups[2].Value.Trim()
      if(-not $eski -or -not $yeni -or $eski -eq $yeni){ continue }
      # Hangi maddeye ait: eslesmeden ONCEKI metinden "... maddesi" ifadesi
      $once = $bm.Substring(0, [math]::Min($x.Index, $bm.Length))
      $konu = 'Değişen ibare'
      $km = [regex]::Match($once, '(?i)(geçici\s+\d+\s*[İi]?nci|geçici\s+\d+\s*[üu]nc[üu]|\d+\s*[İiı]nci|\d+\s*[üu]nc[üu]|\d+\s*[İiı]nc[İiı])\s*madde')
      if($km.Success){ $konu = ($km.Groups[1].Value.Trim() + ' madde') }
      # kaynak='metin' -> bu satir MODEL GORUSU DEGIL, tebligin kendi cumlesi.
      # Kart etiketi buna gore yazilir; "cift okumayla dogrulanmis" demek
      # yanlis olurdu (cift okuma hic devreye girmedi).
      $ibareler.Add([pscustomobject]@{ konu=$konu; eski=$eski; yeni=$yeni; teblig_maddesi=$b.no; kaynak='metin' })
    }

    # (2) YURURLUKTEN KALDIRMA
    if($bm -match '(?i)yürürlükten\s+kaldırılmıştır'){
      $km = [regex]::Match($bm, '(?i)Aynı\s+Tebliğin\s+(.{1,40}?)\s*yürürlükten\s+kaldırılmıştır')
      $hangi = if($km.Success){ $km.Groups[1].Value.Trim() } else { 'bir madde' }
      $kaldirilan.Add([pscustomobject]@{ madde=$hangi; teblig_maddesi=$b.no })
    }

    # (3) MADDE EKLEME - eklenen maddenin numarasi tirnak icindeki basliktan
    if($bm -match '(?i)madde(?:ler)?\s+eklenmiştir'){
      foreach($x in [regex]::Matches($bm, '(?i)(GEÇİCİ\s+MADDE|MADDE)\s+(\d{1,2}(?:/[A-ZÇĞİÖŞÜ])?)\s*-')){
        $ad = ($x.Groups[1].Value + ' ' + $x.Groups[2].Value).Trim()
        # tebligin KENDI madde basligini eklenen sanma
        if($x.Groups[1].Value -notmatch '(?i)geçici' -and $x.Groups[2].Value -eq $b.no){ continue }
        if($eklenen | Where-Object { $_.madde -eq $ad }){ continue }
        $eklenen.Add([pscustomobject]@{ madde=$ad; teblig_maddesi=$b.no })
      }
    }

    # (4) TUMUYLE DEGISTIRME - eski metin tebligde YOK, cift uretilmez;
    #     yalnizca "su madde bastan yazildi" bilgisi verilir.
    if($bm -match '(?i)aşağıdaki\s+şekilde\s+değiştirilmiştir'){
      $km = [regex]::Match($bm, '(?i)Aynı\s+Tebliğin\s+(.{1,40}?)\s*aşağıdaki\s+şekilde\s+değiştirilmiştir')
      if($km.Success){ $degisen.Add([pscustomobject]@{ madde=$km.Groups[1].Value.Trim(); teblig_maddesi=$b.no }) }
    }

    # (5) YURURLUK - "yürürlüğe girer" gecen blok
    if($bm -match '(?i)yürürlüğe\s+gir'){
      $sonuc.yururluk = @(YururlukCoz $bm)
    }
  }

  $sonuc.ibare      = $ibareler.ToArray()
  $sonuc.kaldirilan = $kaldirilan.ToArray()
  $sonuc.eklenen    = $eklenen.ToArray()
  $sonuc.degisen    = $degisen.ToArray()
  return $sonuc
}

# Yururluk maddesi TEK tarih olmak zorunda degil. 01.08.2026 tebliginde:
#   a) 6 maddesi yayimi tarihinde,
#   b) Diger hukumleri 1/10/2026 tarihinde, yururluge girer.
# Kartin en karar-degistirici bilgisi bu; "kaynak tebligdeki maddeye bakin"
# demek cevabi bilip soylememektir.
function YururlukCoz([string]$blok){
  $cikti = New-Object System.Collections.Generic.List[object]
  # bentli mi (a) ... b) ...)
  $bentler = @([regex]::Matches($blok, '(?s)\b([a-fA-F])\)\s*(.{3,200}?)(?=\b[a-fA-F]\)|yürürlüğe\s+gir)'))
  if($bentler.Count -ge 2){
    foreach($x in $bentler){
      $govde = $x.Groups[2].Value.Trim().TrimEnd(',','.',' ')
      $cikti.Add([pscustomobject]@{ bent=$x.Groups[1].Value; kapsam=(YururlukKapsam $govde); tarih=(YururlukTarih $govde) })
    }
    return $cikti.ToArray()
  }
  # tek tarih
  $g = $blok -replace '(?i)^\s*MADDE\s+\d+\s*-\s*',''
  $cikti.Add([pscustomobject]@{ bent=$null; kapsam='tamamı'; tarih=(YururlukTarih $g) })
  return $cikti.ToArray()
}

function YururlukTarih([string]$s){
  if($s -match '(?i)yayımı\s+tarihinde'){ return 'yayımı tarihinde' }
  $m = [regex]::Match($s, '(\d{1,2})[./](\d{1,2})[./](\d{4})')
  if($m.Success){ return ('{0:00}.{1:00}.{2}' -f [int]$m.Groups[1].Value, [int]$m.Groups[2].Value, $m.Groups[3].Value) }
  $m2 = [regex]::Match($s, '(?i)yayımını\s+takip\s+eden\s+(\d+)\s*[İiı]?nc[İiı]?\s*gün')
  if($m2.Success){ return ('yayımını takip eden {0}. gün' -f $m2.Groups[1].Value) }
  return $null
}

# "6 maddesi" / "Diger hukumleri" gibi kapsam ifadesini sadelestir
function YururlukKapsam([string]$s){
  $k = $s -replace '(?i)\s*tarihinde\s*$','' -replace '(?i)\s*yayımı\s*$',''
  $k = $k -replace '(\d{1,2})[./](\d{1,2})[./](\d{4})','' -replace '(?i)yayımı\s+tarihinde',''
  $k = ($k -replace '\s+',' ').Trim().TrimEnd(',','.',' ')
  if(-not $k){ return 'tamamı' }
  return $k
}

# --- dogrudan cagrildiginda ------------------------------------------------
if($Dosya){
  if(-not (Test-Path $Dosya)){ Write-Host "Dosya yok: $Dosya" -ForegroundColor Red; exit 1 }
  $y = TebligYapiCikar $Dosya
  if($Json){ $y | ConvertTo-Json -Depth 6; exit 0 }
  Write-Host "======== TEBLIG YAPISI ========" -ForegroundColor Cyan
  Write-Host ("  tebligin kendi no      : {0}" -f $(if($y.teblig_no){$y.teblig_no}else{'-'}))
  Write-Host ("  degistirdigi teblig    : {0}" -f $(if($y.degistirilen_teblig){$y.degistirilen_teblig}else{'-'}))
  Write-Host ("  kendi madde sayisi     : {0}" -f $y.madde_sayisi)
  Write-Host ""
  Write-Host ("  ESKI -> YENI ({0} satir)" -f @($y.ibare).Count) -ForegroundColor Green
  foreach($i in @($y.ibare)){ Write-Host ("     [{0}] {1}: {2}  ->  {3}" -f $i.teblig_maddesi, $i.konu, $i.eski, $i.yeni) }
  if(-not @($y.ibare).Count){ Write-Host "     (ibare degisikligi yok)" }
  Write-Host ""
  # PARANTEZ SART: "-f" ile "-join" yan yana yazilinca -f once calisir ve {0}
  # dizinin YALNIZ ILK elemanini alir. 17.08'de bu yuzden bes eklenen maddeden
  # yalniz biri gorundu ve cikarim bozuk saniLdi - veri dogruydu, YAZDIRMA yanlisti.
  Write-Host ("  EKLENEN madde   : {0}" -f ((@($y.eklenen)    | ForEach-Object { $_.madde }) -join ', '))
  Write-Host ("  KALDIRILAN      : {0}" -f ((@($y.kaldirilan) | ForEach-Object { $_.madde }) -join ', '))
  Write-Host ("  BASTAN YAZILAN  : {0}" -f ((@($y.degisen)    | ForEach-Object { $_.madde }) -join ', '))
  Write-Host ""
  Write-Host "  YURURLUK" -ForegroundColor Yellow
  foreach($v in @($y.yururluk)){
    $b = if($v.bent){ "$($v.bent)) " } else { "" }
    Write-Host ("     {0}{1} -> {2}" -f $b, $v.kapsam, $(if($v.tarih){$v.tarih}else{'OKUNAMADI'}))
  }
  if(-not @($y.yururluk).Count){ Write-Host "     (yururluk maddesi bulunamadi)" -ForegroundColor Red }
}
