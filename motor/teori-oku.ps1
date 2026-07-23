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
  @{ no='705'; ad='Bağımsız Denetçi Raporunda Olumlu Görüş Dışında Bir Görüş Verilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_705.pdf'; dosya='bds705.json' }
)
$araliklar = @('1 ile 20 arasindaki (1 ve 20 dahil)', '21 ile 45 arasindaki (21 ve 45 dahil)', '46 ve sonrasindaki (son numarali ana metin paragrafina kadar; A ile baslayan uygulama paragraflarini ALMA)')
foreach($b in $bdsler){
  try {
    $pdf = Join-Path $tmp ("bds" + $b.no + ".pdf")
    $kb = Indir $b.url $pdf
    Write-Host ("BDS {0} indirildi ({1} KB), parcali okunuyor..." -f $b.no, $kb)
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pdf))
    $par = @()
    foreach($ar in $araliklar){
      $istem = "Bu belge KGK'nin BDS $($b.no) ($($b.ad)) standardidir. GOREV: standardin ana metnindeki YALNIZ $ar numarali paragraflari belgede YAZDIGI GIBI cikar. Yorum ekleme, ozetleme, atlama yapma; uzun paragraflari oldugu gibi ver. Bu aralikta paragraf yoksa bos dizi [] dondur.`nSADECE su JSON dizisini dondur:`n[{`"p`":`"1`",`"bolum`":`"Giris`",`"metin`":`"...`"}]"
      try {
        $par += JsonYakala (ClaudePdf $b64 $istem 16000)
      } catch { Write-Host ("BDS {0} aralik '{1}' HATA: {2}" -f $b.no, $ar, $_.Exception.Message) }
    }
    # ayni paragraf iki araliktan gelirse tekille
    $gorulen = @{}; $belgeler = @()
    foreach($x in @($par)){
      if(-not $x.p -or -not $x.metin -or "$($x.metin)".Length -lt 30){ continue }
      $pk = "$($x.p)".Trim(); if($gorulen[$pk]){ continue }; $gorulen[$pk] = 1
      $belgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "BDS $($b.no) p.$pk" + $(if($x.bolum){" - $($x.bolum)"}else{""})
        baslik = "$($x.bolum)"
        metin = ("BDS $($b.no) ($($b.ad)) paragraf ${pk}: " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = $b.url
        belge_tarihi = $null
      }
    }
    if(@($belgeler).Count -ge 10){
      KaydetBelgeler $belgeler $b.dosya
      $rapor += ("BDS {0}: OK - {1} paragraf yazildi" -f $b.no, @($belgeler).Count)
    } else {
      $rapor += ("BDS {0}: YAZILMADI - yalniz {1} paragraf cikti (esik 10)" -f $b.no, @($belgeler).Count)
      Write-Host ("BDS {0}: yalniz {1} paragraf cikti - SUPHELI, yazilmadi" -f $b.no, @($belgeler).Count)
    }
  } catch {
    $rapor += ("BDS {0}: HATA - {1}" -f $b.no, $_.Exception.Message)
    Write-Host ("BDS {0} HATA: {1}" -f $b.no, $_.Exception.Message)
  }
}

# ---------- 2) MSUGT Sira No:1 (RG 21447, 226 sayfa): qpdf ile parcala ----------
try {
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

  # API PDF siniri 100 sayfa; 226 sayfalik taramayi qpdf ile bindirmeli bol
  # (85-90 arasi bindirme: bolum siniri sayfa ortasina denk gelirse kayip olmasin)
  $qpdf = Get-Command qpdf -ErrorAction SilentlyContinue
  if(-not $qpdf){ throw "qpdf bulunamadi - workflow'da 'sudo apt-get install -y qpdf' adimi gerekli (226 sayfa API sinirini asar)" }
  $parcalar = @(
    @{ ad='A (s.1-90)';    dosya=(Join-Path $tmp 'msugt_a.pdf'); aralik='1-90' },
    @{ ad='B (s.85-175)';  dosya=(Join-Path $tmp 'msugt_b.pdf'); aralik='85-175' },
    @{ ad='C (s.170-son)'; dosya=(Join-Path $tmp 'msugt_c.pdf'); aralik='170-z' }
  )
  foreach($p in $parcalar){ & qpdf $pdf --pages . $p.aralik -- $p.dosya }
  $belgeler = @()

  # 2a: Muhasebenin Temel Kavramlari (12 kavram) — Teblig'in basinda, parca A yeter
  $b64a = [Convert]::ToBase64String([IO.File]::ReadAllBytes($parcalar[0].dosya))
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
    $b64p = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p.dosya))
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
    $rapor += ("MSUGT: OK - {0} belge yazildi (kavram + THP)" -f @($belgeler).Count)
  } else {
    $rapor += ("MSUGT: YAZILMADI - yalniz {0} belge cikti (esik 8)" -f @($belgeler).Count)
    Write-Host ("MSUGT: yalniz {0} belge cikti - SUPHELI, yazilmadi" -f @($belgeler).Count)
  }
} catch {
  $rapor += ("MSUGT: HATA - " + $_.Exception.Message)
  Write-Host ("MSUGT HATA: " + $_.Exception.Message)
}

RaporYaz
Write-Host "TEORI OKUMA BITTI"
$rapor | ForEach-Object { Write-Host (" RAPOR: " + $_) }
exit 0
