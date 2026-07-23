# ============================================================================
#  TEORI OKUMA ROBOTU — korumali/taranmis birincil metinleri Claude'un GORSEL
#  PDF okumasiyla metne doker ve ambar JSON'una yazar (standart-madde).
#  Hedefler: BDS 700, BDS 705 (KGK korumali PDF) + MSUGT Sira No:1 (RG 21447
#  taramasi — 1992). GUVEN KURALI: yalniz belgede YAZANI cikar, yorum yok.
#  Cikti: veri/mevzuat/bds700.json, bds705.json, msugt1.json
#  Sonrasi: Mevzuat Tam Yukleme Run -> Supabase ambari.
#  ENV: ANTHROPIC_API_KEY zorunlu.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL = "claude-sonnet-5"
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }
$enc = New-Object System.Text.UTF8Encoding $false

function ClaudePdf($b64, $istem, $maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=@(
    @{ type="document"; source=@{ type="base64"; media_type="application/pdf"; data=$b64 } },
    @{ type="text"; text=$istem }) }) } | ConvertTo-Json -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 900
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; return $null }
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

# ---------- 1) BDS 700 + 705: paragraf paragraf ----------
$bdsler = @(
  @{ no='700'; ad='Finansal Tablolara İlişkin Görüş Oluşturma ve Raporlama'; url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/BDS_700_KG.pdf'; dosya='bds700.json' },
  @{ no='705'; ad='Bağımsız Denetçi Raporunda Olumlu Görüş Dışında Bir Görüş Verilmesi'; url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BDS/BDSyeni11092019/BDS_705.pdf'; dosya='bds705.json' }
)
foreach($b in $bdsler){
  try {
    $pdf = Join-Path $tmp ("bds" + $b.no + ".pdf")
    $kb = Indir $b.url $pdf
    Write-Host ("BDS {0} indirildi ({1} KB), okunuyor..." -f $b.no, $kb)
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pdf))
    $istem = @"
Bu belge KGK'nin BDS $($b.no) ($($b.ad)) standardidir. GOREV: standardin NUMARALI PARAGRAFLARINI (Ek'ler haric) belgede YAZDIGI GIBI cikar. Yorum ekleme, ozetleme, atlama yapma; uzun paragraflari oldugu gibi ver.
SADECE su JSON dizisini dondur:
[{"p":"1","bolum":"Giris","metin":"..."},{"p":"2","bolum":"...","metin":"..."}]
"@
    $ham = ClaudePdf $b64 $istem 30000
    $js = JsonBul $ham
    if(-not $js){ Write-Host ("BDS {0}: JSON bulunamadi, atlandi" -f $b.no); continue }
    $par = $js | ConvertFrom-Json
    $belgeler = @()
    foreach($x in @($par)){
      if(-not $x.p -or -not $x.metin -or "$($x.metin)".Length -lt 30){ continue }
      $belgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "BDS $($b.no) p.$($x.p)" + $(if($x.bolum){" - $($x.bolum)"}else{""})
        baslik = "$($x.bolum)"
        metin = ("BDS $($b.no) ($($b.ad)) paragraf $($x.p): " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = $b.url
        belge_tarihi = $null
      }
    }
    if(@($belgeler).Count -ge 10){ KaydetBelgeler $belgeler $b.dosya } else { Write-Host ("BDS {0}: yalniz {1} paragraf cikti - SUPHELI, yazilmadi" -f $b.no, @($belgeler).Count) }
  } catch { Write-Host ("BDS {0} HATA: {1}" -f $b.no, $_.Exception.Message) }
}

# ---------- 2) MSUGT Sira No:1 (RG 21447 taramasi): hedefli okuma ----------
try {
  $pdf = Join-Path $tmp "msugt1.pdf"
  $kb = Indir 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf' $pdf
  Write-Host ("MSUGT indirildi ({0} KB), hedefli okuma..." -f $kb)
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pdf))
  $belgeler = @()

  # 2a: Muhasebenin Temel Kavramlari (12 kavram, tam tanimlar)
  $istem1 = @"
Bu belge 26.12.1992 tarihli Resmi Gazete'de yayimlanan 1 Sira No.lu Muhasebe Sistemi Uygulama Genel Tebligi'dir (taranmis goruntu olabilir, dikkatle oku).
GOREV: 'Muhasebenin Temel Kavramlari' bolumundeki KAVRAMLARIN HER BIRININ tam tanimini belgede YAZDIGI GIBI cikar (Sosyal Sorumluluk, Kisilik, Isletmenin Surekliligi, Donemsellik, Parayla Olculme, Maliyet Esasi, Tarafsizlik ve Belgelendirme, Tutarlilik, Tam Aciklama, Ihtiyatlilik, Onemlilik, Ozun Onceligi). Yorum yok, ozet yok.
SADECE JSON dizisi: [{"kavram":"Donemsellik","metin":"..."}]
"@
  $ham1 = ClaudePdf $b64 $istem1 16000
  $js1 = JsonBul $ham1
  if($js1){
    foreach($x in @(($js1 | ConvertFrom-Json))){
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
  } else { Write-Host "MSUGT kavram okumasi JSON vermedi" }

  # 2b: Tekduzen Hesap Plani - sinav-kritik hesaplarin isleyis aciklamalari
  $hesaplar = '100 Kasa','102 Bankalar','120 Alicilar','121 Alacak Senetleri','128 Supheli Ticari Alacaklar','153 Ticari Mallar','180 Gelecek Aylara Ait Giderler','257 Birikmis Amortismanlar','320 Saticilar','380 Gelecek Aylara Ait Gelirler','600 Yurtici Satislar','610 Satistan Iadeler','621 Satilan Ticari Mallar Maliyeti','642 Faiz Gelirleri','653 Komisyon Giderleri','659 Diger Olagan Gider ve Zararlar','680 Calismayan Kisim Gider ve Zararlari','689 Diger Olagandisi Gider ve Zararlar','770 Genel Yonetim Giderleri','780 Finansman Giderleri'
  $istem2 = @"
Ayni Teblig'in 'Tekduzen Hesap Cercevesi, Hesap Plani ve Hesap Plani Aciklamalari' bolumunden SU HESAPLARIN isleyis aciklamalarini belgede YAZDIGI GIBI cikar: $($hesaplar -join '; ').
Her hesap icin: kod, ad ve aciklamanin tam metni (hesabin niteligi + borc/alacak isleyisi). Bulamadigin hesabi listeye koyma; uydurma.
SADECE JSON dizisi: [{"kod":"780","ad":"Finansman Giderleri","metin":"..."}]
"@
  $ham2 = ClaudePdf $b64 $istem2 24000
  $js2 = JsonBul $ham2
  if($js2){
    $oncesi = @($belgeler).Count
    foreach($x in @(($js2 | ConvertFrom-Json))){
      if(-not $x.kod -or "$($x.metin)".Length -lt 40){ continue }
      $belgeler += [ordered]@{
        tur='standart-madde'
        kaynak_ad = "THP $($x.kod) - $($x.ad)"
        baslik = 'Tekduzen Hesap Plani Aciklamalari'
        metin = ("MSUGT Sira No:1 Tekduzen Hesap Plani - $($x.kod) $($x.ad): " + ("$($x.metin)" -replace '\s+',' ').Trim())
        kaynak_url = 'https://www.resmigazete.gov.tr/arsiv/21447_1.pdf'
        belge_tarihi = '26.12.1992'
      }
    }
    Write-Host ("THP hesap aciklamalari: {0} belge" -f (@($belgeler).Count - $oncesi))
  } else { Write-Host "THP okumasi JSON vermedi" }

  if(@($belgeler).Count -ge 8){ KaydetBelgeler $belgeler 'msugt1.json' } else { Write-Host ("MSUGT: yalniz {0} belge cikti - SUPHELI, yazilmadi" -f @($belgeler).Count) }
} catch { Write-Host ("MSUGT HATA: " + $_.Exception.Message) }

Write-Host "TEORI OKUMA BITTI"
exit 0
