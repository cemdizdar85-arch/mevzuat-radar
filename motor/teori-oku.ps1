# ============================================================================
#  TEORI OKUMA ROBOTU — korumali/taranmis birincil metinleri Claude'un GORSEL
#  PDF okumasiyla metne doker ve ambar JSON'una yazar (standart-madde).
#  Hedefler: BDS 700, BDS 705 (KGK korumali PDF) + MSUGT Sira No:1 (RG 21447
#  taramasi — 1992). GUVEN KURALI: yalniz belgede YAZANI cikar, yorum yok.
#  Cikti: veri/mevzuat/bds700.json, bds705.json, msugt1.json + veri/teori-rapor.json
#
#  23.07 DERSLERI (ilk iki kosu "success" bitti ama HICBIR cikti uretmedi):
#   1) MSUGT PDF'i 226 sayfa — Claude API'nin PDF siniri 100 sayfa; cagri hata
#      veriyordu, catch yutuyordu. COZUM: qpdf ile <=100 sayfalik parcalara bol.
#   2) BDS'nin TUM paragraflarini tek cevaba sigdirmak cikti-token sinirini
#      asiyor; kesik cevapta kapanis ']' olmadigindan JSON bulunamiyordu.
#      COZUM: paragraf araliklarina bolunmus kucuk cagrilar + kesik JSON'dan
#      tekil nesneleri kurtaran ayristirici.
#   3) Sessiz kosu YASAK: her kosuda veri/teori-rapor.json yazilir ve commit
#      edilir — ne oldu, kacar belge cikti, neden yazilmadi hep gorunur.
#  ENV: ANTHROPIC_API_KEY zorunlu.
#  23.07: teori-notu genislemesi (5 yeni kurasyon) icin yukleme kosusu — tum okuma hedefleri atlanir. (tetik-3: capraz/gelir esnekligi + muavin notlari yukleme)
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL = "claude-sonnet-5"
$key = $env:ANTHROPIC_API_KEY
$enc = New-Object System.Text.UTF8Encoding $false
$rapor = @()   # her hedef icin sonuc satiri — kosu sonunda DOSYAYA yazilir

function RaporYaz(){
  $cikti = [ordered]@{ calisti = (Get-Date).ToUniversalTime().ToString('dd.MM.yyyy HH:mm') + ' UTC'; sonuc = $script:rapor }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/teori-rapor.json'), ($cikti | ConvertTo-Json -Depth 4), $enc)
}
if(-not $key){
  $rapor += 'ANTHROPIC_API_KEY yok - hicbir okuma yapilamadi'
  RaporYaz; Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0
}

function ClaudePdf($b64, $istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=@(
    @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$b64 } },
    @{ type="text"; text=$istem }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 900
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}

# KESIK-JSON SIGORTASI: once tam diziyi dene; olmazsa (cevap token sinirinda
# kesildiyse kapanis ']' yoktur) tamamlanmis tekil nesneleri tek tek kurtar.
function JsonYakala($t){
  $liste = @()
  $m = [regex]::Match($t, '(?s)\[.*\]')
  if($m.Success){
    try { return @(($m.Value | ConvertFrom-Json)) } catch {}
  }
  foreach($om in [regex]::Matches($t, '(?s)\{[^{}]*\}')){
    try { $liste += ($om.Value | ConvertFrom-Json) } catch {}
  }
  return $liste
}
function Indir($url, $hedef){
  Invoke-WebRequest -Uri $url -OutFile $hedef -UseBasicParsing -TimeoutSec 240 -UserAgent 'Mozilla/5.0'
  return [math]::Round((Get-Item $hedef).Length/1KB)
}
function KaydetBelgeler($belgeler, $dosyaAdi){
  $cikti = [ordered]@{ belgeler = $belgeler }
  $hedef = Join-Path $kok ("veri/mevzuat/" + $dosyaAdi)
  [IO.File]::WriteAllText($hedef, ($cikti | ConvertTo-Json -Depth 4), $enc)
  Write-Host ("{0}: {1} belge yazildi" -f $dosyaAdi, @($belgeler).Count)
}

$tmp = [IO.Path]::GetTempPath()

# ---------- 1) BDS 700 + 705: paragraf araliklarina bolunmus okuma ----------
$bdsler = @(
  @{ no='700'; ad='Finansal Tablolara İlişkin Görüş Oluşturma ve Raporlama'; url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/BDS_700_KG.pdf'; dosya='bds700.json' },
  @{ no='705'; ad='Bağımsız Denetçi Raporunda Olumlu Görüş Dışında Bir Görüş Verilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_705.pdf'; dosya='bds705.json' },
  @{ no='706'; ad='Bağımsız Denetçi Raporunda Yer Alan Dikkat Çekilen Hususlar ve Diğer Hususlar Paragrafları'; url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/BDS_706_KG.pdf'; dosya='bds706.json' },   # 23.07 eklendi (HEAD 200 teyitli)
  # 23.07 fabrika talep sinyali: uretici bu standartlara atif yapip RET yiyordu.
  # NOT: TDS/..._KG.pdf kopyalari 1 KB bos yonlendirme cikti - BDSyeni yolu gercek.
  @{ no='320'; ad='Bağımsız Denetimin Planlanması ve Yürütülmesinde Önemlilik'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_320.pdf'; dosya='bds320.json' },
  @{ no='450'; ad='Bağımsız Denetimin Yürütülmesi Sırasında Belirlenen Yanlışlıkların Değerlendirilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_450.pdf'; dosya='bds450.json' },
  @{ no='530'; ad='Bağımsız Denetimde Örnekleme'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_530.pdf'; dosya='bds530.json' },
  # 23.07 kaynak-tamamlama turu (Cem: "once okumadiklarimizi tamamlayalim"): denetim dersinin bel kemigi 6 standart (hepsi HEAD 200 teyitli)
  @{ no='200'; ad='Bağımsız Denetçinin Genel Amaçları ve Bağımsız Denetimin BDS''lere Uygun Olarak Yürütülmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_200.pdf'; dosya='bds200.json' },
  @{ no='240'; ad='Finansal Tabloların Bağımsız Denetiminde Denetçinin Hileye İlişkin Sorumlulukları'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_240.pdf'; dosya='bds240.json' },
  @{ no='300'; ad='Finansal Tabloların Bağımsız Denetiminin Planlanması'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_300.pdf'; dosya='bds300.json' },
  @{ no='315'; ad='İşletme ve Çevresini Tanımak Suretiyle Önemli Yanlışlık Risklerinin Belirlenmesi ve Değerlendirilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_315.pdf'; dosya='bds315.json' },
  @{ no='500'; ad='Bağımsız Denetim Kanıtları'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_500.pdf'; dosya='bds500.json' },
  @{ no='570'; ad='İşletmenin Sürekliliği'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_570.pdf'; dosya='bds570.json' },
  @{ no='230'; ad='Bağımsız Denetimin Belgelendirilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_230.pdf'; dosya='bds230.json' },   # 23.07 harita: 2x agirlikli konu blokluydu
  # 24.07 Cem onayi: dalga-1'de bu standartlara atifli sorular ambar-yoklugundan yandi (talep kaniti)
  @{ no='501'; ad='Belirli Kalemlere İlişkin Denetim Kanıtları Hakkında Dikkate Alınacak Hususlar'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_501.pdf'; dosya='bds501.json' },
  @{ no='505'; ad='Dış Teyitler'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_505.pdf'; dosya='bds505.json' },
  @{ no='520'; ad='Analitik Prosedürler'; esik=5; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_520.pdf'; dosya='bds520.json' },   # 24.07: 520 KISA standart (ana metin ~8 paragraf) - genel esik 10 hakli 7 paragrafi curutuyordu
  # TMS de ayni motorla okunur (tip alani); 2024/2025 Mavi Kitap linkleri 1KB bos yonlendirme, 2023 gercek (329KB HEAD teyitli)
  @{ no='2'; tip='TMS'; ad='Stoklar'; url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2023/Mavi_Kitap/TMS/TMS%202.pdf'; dosya='tms2.json' }
)
# 23.07 HARITA BULGUSU (Cem: "uretemedigimiz en cok cikanlar olmasin"): 'onemlilik
# kiyaslama noktasi' (3x) ve 'orneklem buyuklugu faktorleri' (2x) sorulari BDS'lerin
# EK'lerine dayaniyor - ana-metin okumasi ekleri bilerek atliyordu. Ekler ayri hedef:
$bdsEkleri = @(
  # 24.07 duzeltme: BDS 320'de "Ek" bolumu YOK (yerel pdftotext ile teyit edildi) -
  # kiyaslama noktasi icerigi Uygulama bolumunun A-paragraflarinda; hedef oraya cevrildi.
  @{ no='320'; tur='aparagraf'; ekAd='Kıyaslama Noktalarının Belirlenmesine İlişkin Açıklamalar'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_320.pdf'; dosya='bds320-ek.json' },
  @{ no='530'; ekAd='Ek-2 ve Ek-3 (Örneklem Büyüklüğünü Etkileyen Faktörler)'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_530.pdf'; dosya='bds530-ek.json' }
)
$araliklar = @('1 ile 20 arasindaki (1 ve 20 dahil)', '21 ile 45 arasindaki (21 ve 45 dahil)', '46 ve sonrasindaki (son numarali ana metin paragrafina kadar; A ile baslayan uygulama paragraflarini ALMA)')
foreach($b in $bdsler){
  $tip = if($b.tip){ $b.tip } else { 'BDS' }
  try {
    # TASARRUF: cikti zaten depodaysa yeniden okuma (her kosuda BDS'ye para yakiliyordu).
    # Yeniden okutmak istersen veri/mevzuat/bds7xx.json dosyasini sil, kosu kendini tamamlar.
    if(Test-Path (Join-Path $kok ("veri/mevzuat/" + $b.dosya))){
      Write-Host ("{0} {1}: zaten mevcut - atlandi" -f $tip, $b.no)
      $rapor += ("{0} {1}: ATLANDI - cikti zaten depoda" -f $tip, $b.no)
      continue
    }
    $pdf = Join-Path $tmp ($tip.ToLower() + $b.no + ".pdf")
    $kb = Indir $b.url $pdf
    Write-Host ("{0} {1} indirildi ({2} KB), parcali okunuyor..." -f $tip, $b.no, $kb)
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pdf))
    $par = @()
    foreach($ar in $araliklar){
      $istem = "Bu belge KGK'nin $tip $($b.no) ($($b.ad)) standardidir. GOREV: standardin ana metnindeki YALNIZ $ar numarali paragraflari belgede YAZDIGI GIBI cikar. Yorum ekleme, ozetleme, atlama yapma; uzun paragraflari oldugu gibi ver. Bu aralikta paragraf yoksa bos dizi [] dondur.`nSADECE su JSON dizisini dondur:`n[{`"p`":`"1`",`"bolum`":`"Giris`",`"metin`":`"...`"}]"
      try {
        $par += JsonYakala (ClaudePdf $b64 $istem 16000)
      } catch { Write-Host ("{0} {1} aralik '{2}' HATA: {3}" -f $tip, $b.no, $ar, $_.Exception.Message) }
    }
    # ayni paragraf iki araliktan gelirse tekille
    $gorulen = @{}; $belgeler = @()
    foreach($x in @($par)){
      if(-not $x.p -or -not $x.metin -or "$($x.metin)".Length -lt 30){ continue }
      $pk = "$($x.p)".Trim(); if($gorulen[$pk]){ continue }; $gorulen[$pk] = 1
      $belgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "$tip $($b.no) p.$pk" + $(if($x.bolum){" - $($x.bolum)"}else{""})
        baslik = "$($x.bolum)"
        metin = ("$tip $($b.no) ($($b.ad)) paragraf ${pk}: " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = $b.url
        belge_tarihi = $null
      }
    }
    $esikB = if($b.esik){ [int]$b.esik } else { 10 }
    if(@($belgeler).Count -ge $esikB){
      KaydetBelgeler $belgeler $b.dosya
      $rapor += ("{0} {1}: OK - {2} paragraf yazildi" -f $tip, $b.no, @($belgeler).Count)
    } else {
      $rapor += ("{0} {1}: YAZILMADI - yalniz {2} paragraf cikti (esik {3})" -f $tip, $b.no, @($belgeler).Count, $esikB)
      Write-Host ("{0} {1}: yalniz {2} paragraf cikti - SUPHELI, yazilmadi" -f $tip, $b.no, @($belgeler).Count)
    }
  } catch {
    $rapor += ("BDS {0}: HATA - {1}" -f $b.no, $_.Exception.Message)
    Write-Host ("BDS {0} HATA: {1}" -f $b.no, $_.Exception.Message)
  }
}

# ---------- 1b) BDS EK OKUMALARI (harita-agirlikli ekler) ----------
foreach($e in $bdsEkleri){
  try {
    if(Test-Path (Join-Path $kok ("veri/mevzuat/" + $e.dosya))){
      $rapor += ("BDS {0} ekleri: ATLANDI - depoda" -f $e.no); continue
    }
    $pdfE = Join-Path $tmp ("bdsek" + $e.no + ".pdf")
    $kbE = Indir $e.url $pdfE
    Write-Host ("BDS {0} ekleri indirildi ({1} KB), okunuyor..." -f $e.no, $kbE)
    $istemE = if($e.tur -eq 'aparagraf'){
      "Bu belge KGK'nin BDS $($e.no) standardidir. GOREV: 'Uygulama ve Diger Aciklayici Hukumler' bolumunde $($e.ekAd) kapsamindaki A ile numaralanmis paragraflari (A1, A2, A3... hangileri bu konuyla ilgiliyse) belgede YAZDIGI GIBI cikar. Rakamla numarali ana metin paragraflarini ALMA. Yorum yok.`nSADECE JSON dizisi: [{`"ek`":`"A3`",`"sira`":`"`",`"baslik`":`"...`",`"metin`":`"...`"}]"
    } else {
      "Bu belge KGK'nin BDS $($e.no) standardidir. GOREV: belgenin SONUNDAKI $($e.ekAd) bolumundeki maddeleri/faktorleri/aciklamalari belgede YAZDIGI GIBI cikar. Ana metin paragraflarini ALMA, yalniz EK bolumunu cikar. Yorum yok.`nSADECE JSON dizisi: [{`"ek`":`"Ek-2`",`"sira`":`"1`",`"baslik`":`"...`",`"metin`":`"...`"}]"
    }
    $ekPar = JsonYakala (ClaudePdf ([Convert]::ToBase64String([IO.File]::ReadAllBytes($pdfE))) $istemE 16000)
    $ekBelgeler = @(); $gorulenEk = @{}
    foreach($x in @($ekPar)){
      if(-not $x.metin -or "$($x.metin)".Length -lt 40){ continue }
      $ekEtiket = ("$($x.ek)" -replace '\s+',''); if(-not $ekEtiket){ $ekEtiket = 'Ek' }
      $ik = "$ekEtiket|$($x.sira)"; if($gorulenEk[$ik]){ continue }; $gorulenEk[$ik] = 1
      # A-paragrafi hedefinde kaynak_ad "BDS 320 p.A5" bicimindedir (teyitci bu bicimi arar)
      $adParca = if($e.tur -eq 'aparagraf'){ "p.$ekEtiket" } else { "$ekEtiket $($x.sira)".Trim() }
      $ekBelgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "BDS $($e.no) $adParca" + $(if($x.baslik){" - $($x.baslik)"}else{""})
        baslik = "$($x.baslik)"
        metin = ("BDS $($e.no) $adParca" + ": " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = $e.url
        belge_tarihi = $null
      }
    }
    if(@($ekBelgeler).Count -ge 4){
      KaydetBelgeler $ekBelgeler $e.dosya
      $rapor += ("BDS {0} ekleri: OK - {1} madde" -f $e.no, @($ekBelgeler).Count)
    } else {
      $rapor += ("BDS {0} ekleri: YAZILMADI - yalniz {1} madde (esik 4)" -f $e.no, @($ekBelgeler).Count)
    }
  } catch {
    $rapor += ("BDS {0} ekleri: HATA - {1}" -f $e.no, $_.Exception.Message)
  }
}

# ---------- 2) MSUGT Sira No:1 (RG 21447): qpdf ile parcala, COK HEDEFLI ----------
# 23.07: hedefler coklandi (fabrika talep sinyali). Her hedefin kendi dosyasi ve
# atla-sigortasi var; HEPSI mevcutsa indirme/parcalama hic yapilmaz.
$msugtVar1 = Test-Path (Join-Path $kok "veri/mevzuat/msugt1.json")          # kavramlar + ilk 20 THP
$msugtVarI = Test-Path (Join-Path $kok "veri/mevzuat/msugt-ilkeler.json")   # mali tablolar ilkeleri
$msugtVar2 = Test-Path (Join-Path $kok "veri/mevzuat/msugt-thp2.json")      # ek hesaplar (305/308/63x/66x/7A)
try {
  if($msugtVar1 -and $msugtVarI -and $msugtVar2){
    Write-Host "MSUGT: tum hedefler zaten mevcut - atlandi"
    $rapor += "MSUGT: ATLANDI - tum hedef dosyalar depoda"
    throw [System.Exception]::new("__MSUGT_ATLA__")
  }
  $pdf = Join-Path $tmp "msugt1.pdf"
  # 23.07 #4 dersi: GitHub runner'dan resmigazete.gov.tr zaman asimi verdi (muhtemel
  # yurt disi IP engeli). Yedek: ayni RG taramasi repoda (kaynak-pdf/) — resmi mevzuat
  # metni, telif engeli yok. Once canli URL denenir, olmazsa yedek kullanilir.
  $yedek = Join-Path $kok "kaynak-pdf/msugt1.pdf"
  try {
    $kb = Indir 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf' $pdf
    Write-Host ("MSUGT indirildi ({0} KB), parcalaniyor..." -f $kb)
  } catch {
    if(Test-Path $yedek){
      Copy-Item $yedek $pdf -Force
      $kb = [math]::Round((Get-Item $pdf).Length/1KB)
      Write-Host ("RG'ye erisilemedi ({0}) - repo yedegi kullanildi ({1} KB)" -f $_.Exception.Message, $kb)
    } else { throw }
  }

  # API PDF siniri 100 sayfa; taramayi qpdf ile bindirmeli bol (85-90 bindirme:
  # bolum siniri sayfa ortasina denk gelirse kayip olmasin).
  # 23.07 #5 dersi: sabit "85-175" araligi patladi - regex'le saydigimiz "226 sayfa"
  # kabaymis. Parcalar artik GERCEK sayfa sayisindan (qpdf --show-npages) kurulur,
  # uretilemeyen parca aninda yakalanir.
  $qpdf = Get-Command qpdf -ErrorAction SilentlyContinue
  if(-not $qpdf){ throw "qpdf bulunamadi - workflow'da 'sudo apt-get install -y qpdf' adimi gerekli (API siniri 100 sayfa)" }
  $sayfa = [int]((& qpdf --show-npages $pdf) | Select-Object -First 1)
  Write-Host ("MSUGT gercek sayfa sayisi: {0}" -f $sayfa)
  if($sayfa -lt 1){ throw "qpdf sayfa sayamadi - PDF bozuk olabilir" }
  $parcalar = @(@{ ad="A (s.1-$([Math]::Min(90,$sayfa)))"; dosya=(Join-Path $tmp 'msugt_a.pdf'); aralik=("1-"+[Math]::Min(90,$sayfa)) })
  if($sayfa -gt 90){  $parcalar += @{ ad="B (s.85-$([Math]::Min(175,$sayfa)))"; dosya=(Join-Path $tmp 'msugt_b.pdf'); aralik=("85-"+[Math]::Min(175,$sayfa)) } }
  if($sayfa -gt 175){ $parcalar += @{ ad="C (s.170-son)"; dosya=(Join-Path $tmp 'msugt_c.pdf'); aralik='170-z' } }
  foreach($p in $parcalar){
    & qpdf $pdf --pages . $p.aralik -- $p.dosya
    if(-not (Test-Path $p.dosya)){ throw ("qpdf parca uretemedi: " + $p.aralik + " (sayfa=" + $sayfa + ")") }
  }
  $b64Cache = @{}
  function ParcaB64($yol){ if(-not $script:b64Cache.ContainsKey($yol)){ $script:b64Cache[$yol] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($yol)) }; return $script:b64Cache[$yol] }

  if($msugtVar1){ $rapor += "MSUGT-1 (kavram+THP): ATLANDI - depoda" }
  else {
  $belgeler = @()

  # 2a: Muhasebenin Temel Kavramlari (12 kavram) — Teblig'in basinda, parca A yeter
  $b64a = ParcaB64 $parcalar[0].dosya
  $istem1 = @"
Bu belge 26.12.1992 tarihli Resmi Gazete'de yayimlanan 1 Sira No.lu Muhasebe Sistemi Uygulama Genel Tebligi'nin ilk bolumudur (taranmis goruntu olabilir, dikkatle oku).
GOREV: 'Muhasebenin Temel Kavramlari' bolumundeki KAVRAMLARIN HER BIRININ tam tanimini belgede YAZDIGI GIBI cikar (Sosyal Sorumluluk, Kisilik, Isletmenin Surekliligi, Donemsellik, Parayla Olculme, Maliyet Esasi, Tarafsizlik ve Belgelendirme, Tutarlilik, Tam Aciklama, Ihtiyatlilik, Onemlilik, Ozun Onceligi). Yorum yok, ozet yok.
SADECE JSON dizisi: [{"kavram":"Donemsellik","metin":"..."}]
"@
  try {
    $kv = JsonYakala (ClaudePdf $b64a $istem1 16000)
    foreach($x in @($kv)){
      if(-not $x.kavram -or "$($x.metin)".Length -lt 40){ continue }
      $belgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "MSUGT 1 kavram - $($x.kavram)"
        baslik = 'Muhasebenin Temel Kavramlari'
        metin = ("MSUGT Sira No:1 (RG 26.12.1992/21447 muk.) - Muhasebenin Temel Kavramlarindan '$($x.kavram)': " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf'
        belge_tarihi = '26.12.1992'
      }
    }
    Write-Host ("MSUGT kavramlar: {0} belge" -f @($belgeler).Count)
  } catch { Write-Host ("MSUGT kavram okumasi HATA: " + $_.Exception.Message) }

  # 2b: Tekduzen Hesap Plani aciklamalari — hangi parcada oldugu bilinmiyor, UCUNE de sor
  $hesaplar = '100 Kasa','102 Bankalar','120 Alicilar','121 Alacak Senetleri','128 Supheli Ticari Alacaklar','153 Ticari Mallar','180 Gelecek Aylara Ait Giderler','257 Birikmis Amortismanlar','320 Saticilar','380 Gelecek Aylara Ait Gelirler','600 Yurtici Satislar','610 Satistan Iadeler','621 Satilan Ticari Mallar Maliyeti','642 Faiz Gelirleri','653 Komisyon Giderleri','659 Diger Olagan Gider ve Zararlar','680 Calismayan Kisim Gider ve Zararlari','689 Diger Olagandisi Gider ve Zararlar','770 Genel Yonetim Giderleri','780 Finansman Giderleri'
  $gorulenKod = @{}
  foreach($p in $parcalar){
    $b64p = ParcaB64 $p.dosya
    $istem2 = @"
Bu belge 1 Sira No.lu Muhasebe Sistemi Uygulama Genel Tebligi'nin bir parcasidir ($($p.ad)). 'Tekduzen Hesap Cercevesi, Hesap Plani ve Hesap Plani Aciklamalari' bolumu bu parcaya denk geliyorsa, SU HESAPLARIN isleyis aciklamalarini belgede YAZDIGI GIBI cikar: $($hesaplar -join '; ').
Her hesap icin: kod, ad ve aciklamanin tam metni (hesabin niteligi + borc/alacak isleyisi). Bu parcada bulamadigin hesabi listeye koyma; uydurma. Hicbiri yoksa bos dizi [] dondur.
SADECE JSON dizisi: [{"kod":"780","ad":"Finansman Giderleri","metin":"..."}]
"@
    try {
      $hs = JsonYakala (ClaudePdf $b64p $istem2 16000)
      $eklenen = 0
      foreach($x in @($hs)){
        if(-not $x.kod -or "$($x.metin)".Length -lt 40){ continue }
        $kk = "$($x.kod)".Trim(); if($gorulenKod[$kk]){ continue }; $gorulenKod[$kk] = 1
        $belgeler += [ordered]@{
          tur='standart-madde'
          kaynak_ad = "THP $kk - $($x.ad)"
          baslik = 'Tekduzen Hesap Plani Aciklamalari'
          metin = ("MSUGT Sira No:1 Tekduzen Hesap Plani - $kk $($x.ad): " + ("$($x.metin)" -replace '\s+',' ').Trim())
          kaynak_url = 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf'
          belge_tarihi = '26.12.1992'
        }
        $eklenen++
      }
      Write-Host ("THP parca {0}: {1} hesap" -f $p.ad, $eklenen)
    } catch { Write-Host ("THP parca {0} HATA: {1}" -f $p.ad, $_.Exception.Message) }
  }

  if(@($belgeler).Count -ge 8){
    KaydetBelgeler $belgeler 'msugt1.json'
    $rapor += ("MSUGT-1: OK - {0} belge yazildi (kavram + THP)" -f @($belgeler).Count)
  } else {
    $rapor += ("MSUGT-1: YAZILMADI - yalniz {0} belge cikti (esik 8)" -f @($belgeler).Count)
    Write-Host ("MSUGT-1: yalniz {0} belge cikti - SUPHELI, yazilmadi" -f @($belgeler).Count)
  }
  }  # msugt1 else sonu

  # 2c: MALI TABLOLAR ILKELERI (bilanco + gelir tablosu ilkeleri) — fabrika talep sinyali
  if($msugtVarI){ $rapor += "MSUGT-ilkeler: ATLANDI - depoda" }
  else {
    $ilkeBelgeleri = @(); $gorulenIlke = @{}
    foreach($p in @($parcalar | Select-Object -First 2)){   # ilkeler bolumu tebligin on yarisinda
      $istemI = @"
Bu belge 1 Sira No.lu Muhasebe Sistemi Uygulama Genel Tebligi'nin bir parcasidir ($($p.ad)). 'MALI TABLOLAR ILKELERI' bolumu (bilanco ilkeleri ve gelir tablosu ilkeleri) bu parcaya denk geliyorsa, HER ILKEYI belgede YAZDIGI GIBI cikar. Yorum yok, ozet yok. Bu parcada bolum yoksa bos dizi [] dondur.
SADECE JSON dizisi: [{"bolum":"Gelir Tablosu Ilkeleri","sira":"1","metin":"..."}] (bolum: 'Bilanco Ilkeleri' ya da 'Gelir Tablosu Ilkeleri'; alt basliklar - varliklara/kaynaklara iliskin - metnin basina yazilabilir)
"@
      try {
        $il = JsonYakala (ClaudePdf (ParcaB64 $p.dosya) $istemI 16000)
        foreach($x in @($il)){
          if(-not $x.bolum -or "$($x.metin)".Length -lt 40){ continue }
          $ik = (("$($x.bolum)" + "|" + "$($x.sira)")); if($gorulenIlke[$ik]){ continue }; $gorulenIlke[$ik] = 1
          $ilkeBelgeleri += [ordered]@{
            tur='standart-madde'
            kaynak_ad = "MSUGT 1 ilke - $($x.bolum) $($x.sira)"
            baslik = "Mali Tablolar Ilkeleri - $($x.bolum)"
            metin = ("MSUGT Sira No:1 Mali Tablolar Ilkeleri, $($x.bolum) $($x.sira): " + ("$($x.metin)" -replace '\s+',' ').Trim())
            kaynak_url = 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf'
            belge_tarihi = '26.12.1992'
          }
        }
        Write-Host ("Ilkeler parca {0}: toplam {1}" -f $p.ad, @($ilkeBelgeleri).Count)
      } catch { Write-Host ("Ilkeler parca {0} HATA: {1}" -f $p.ad, $_.Exception.Message) }
    }
    if(@($ilkeBelgeleri).Count -ge 8){
      KaydetBelgeler $ilkeBelgeleri 'msugt-ilkeler.json'
      $rapor += ("MSUGT-ilkeler: OK - {0} ilke yazildi" -f @($ilkeBelgeleri).Count)
    } else {
      $rapor += ("MSUGT-ilkeler: YAZILMADI - yalniz {0} ilke cikti (esik 8)" -f @($ilkeBelgeleri).Count)
    }
  }

  # 2d: EK THP HESAPLARI (fabrika talep sinyali: bono/ihrac farki, 63x fonksiyon, 66x, 7/A)
  if($msugtVar2){ $rapor += "MSUGT-thp2: ATLANDI - depoda" }
  else {
    $hesaplar2 = '305 Cikarilmis Bonolar ve Senetler','308 Menkul Kiymetler Ihrac Farki','630 Arastirma ve Gelistirme Giderleri','631 Pazarlama Satis ve Dagitim Giderleri','632 Genel Yonetim Giderleri','660 Kisa Vadeli Borclanma Giderleri','661 Uzun Vadeli Borclanma Giderleri','710 Direkt Ilk Madde ve Malzeme Giderleri','720 Direkt Iscilik Giderleri','730 Genel Uretim Giderleri','731 Genel Uretim Giderleri Yansitma Hesabi'
    $ekBelgeler = @(); $gorulenKod2 = @{}
    foreach($p in $parcalar){
      $istemE = @"
Bu belge 1 Sira No.lu Muhasebe Sistemi Uygulama Genel Tebligi'nin bir parcasidir ($($p.ad)). 'Tekduzen Hesap Plani Aciklamalari' bolumu bu parcaya denk geliyorsa, SU HESAPLARIN isleyis aciklamalarini belgede YAZDIGI GIBI cikar: $($hesaplar2 -join '; ').
Her hesap icin: kod, belgede yazan RESMI adi ve aciklamanin tam metni. Bu parcada bulamadigin hesabi listeye koyma; uydurma. Hicbiri yoksa bos dizi [] dondur.
SADECE JSON dizisi: [{"kod":"305","ad":"...","metin":"..."}]
"@
      try {
        $hs2 = JsonYakala (ClaudePdf (ParcaB64 $p.dosya) $istemE 16000)
        $eklenen2 = 0
        foreach($x in @($hs2)){
          if(-not $x.kod -or "$($x.metin)".Length -lt 40){ continue }
          $kk2 = "$($x.kod)".Trim(); if($gorulenKod2[$kk2]){ continue }; $gorulenKod2[$kk2] = 1
          $ekBelgeler += [ordered]@{
            tur='standart-madde'
            kaynak_ad = "THP $kk2 - $($x.ad)"
            baslik = 'Tekduzen Hesap Plani Aciklamalari'
            metin = ("MSUGT Sira No:1 Tekduzen Hesap Plani - $kk2 $($x.ad): " + ("$($x.metin)" -replace '\s+',' ').Trim())
            kaynak_url = 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf'
            belge_tarihi = '26.12.1992'
          }
          $eklenen2++
        }
        Write-Host ("THP-ek parca {0}: {1} hesap" -f $p.ad, $eklenen2)
      } catch { Write-Host ("THP-ek parca {0} HATA: {1}" -f $p.ad, $_.Exception.Message) }
    }
    if(@($ekBelgeler).Count -ge 6){
      KaydetBelgeler $ekBelgeler 'msugt-thp2.json'
      $rapor += ("MSUGT-thp2: OK - {0} hesap yazildi" -f @($ekBelgeler).Count)
    } else {
      $rapor += ("MSUGT-thp2: YAZILMADI - yalniz {0} hesap cikti (esik 6)" -f @($ekBelgeler).Count)
    }
  }
} catch {
  if($_.Exception.Message -ne "__MSUGT_ATLA__"){
    $rapor += ("MSUGT: HATA - " + $_.Exception.Message)
    Write-Host ("MSUGT HATA: " + $_.Exception.Message)
  }
}

RaporYaz
Write-Host "TEORI OKUMA BITTI"
$rapor | ForEach-Object { Write-Host (" RAPOR: " + $_) }
exit 0
