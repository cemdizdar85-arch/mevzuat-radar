# ============================================================================
#  İHALE FİRMA ADI DENETİMİ — "özel adı kayıp yüklenici" avı
#
#  NEDEN VAR (30.08.2026): veri/ihale-firma-ozet.json'da EN BÜYÜK kayıt bir
#  firma değil: "Ticaret Limited Şirketi" — 295 ihale, 2,97 MİLYAR TL.
#  Firma adının ÖZEL AD kısmı (marka) kayıp; geriye yalnız şirket eki kalmış.
#  Sonuç: birbiriyle ilgisiz onlarca firma tek kayıtta toplanıyor ve Firma
#  Analizi aracı "bu firma 295 ihale kazandı" diyor. Alacaklıya/kullanıcıya
#  TERS bilgi.
#
#  ÖLÇÜLDÜ: 93 kayıt jenerik bir kelimeyle başlıyor — 1.284 ihale,
#  7,34 milyar TL. (14.416 firmanın 2.716'sı 30 karakterden kısa ama
#  çoğu ŞAHIS firması: "Mehmet ...", "Ahmet ..." — onlar normaldir,
#  kısalık tek başına kusur değildir. Kusur ölçütü ŞİRKET EKİYLE BAŞLAMAK.)
#
#  KAYNAK (daraltıldı, kesinleşmedi): motor/ihale-sonuc-ayristir.ps1 satır
#  ~197'deki yüklenici deseni. Betiğin kendi yorumunda yazan tuzak:
#  "PDF tablo hücresi DİKEY ORTALI olduğu için uzun firma adı etiketin HEM
#  ÖNÜNE HEM ARDINA taşıyor". Desen ham metinde denendi ve o vakalarda
#  fazla alıyor, kesmiyor — yani kesme PDF dizgisinin kendisinden geliyor
#  olabilir. Kesin senaryo ham bülten PDF'i olmadan kanıtlanamadı.
#
#  BU BETİK CANLIYA DOKUNMAZ. Yalnız ölçer ve onarım için malzeme çıkarır:
#  her kusurlu kaydın IKN listesi — o ihalelerin sonuç ilanı yeniden
#  okunursa gerçek yüklenici adı çıkar.
# ============================================================================
param([switch]$Ayrinti, [switch]$Tazele)

$ErrorActionPreference = 'Continue'
$KOK = Split-Path $PSScriptRoot -Parent
$OZET = Join-Path $KOK 'veri\ihale-firma-ozet.json'

# Şirket adı jenerik bir sıfat/ekle BAŞLAMAZ. Bu liste "adın başında olursa
# özel ad kayıptır" diyen kelimelerdir; adın İÇİNDE geçmeleri normaldir.
$JENERIK = @(
  'Ticaret','Sanayi','İhracat','İthalat','Ithalat','Limited','Anonim',
  'Turizm','İnşaat','Insaat','Nakliyat','Gıda','Tıbbi','Medikal','Otomotiv',
  'Elektrik','Temizlik','Danışmanlık','Mühendislik','Teknoloji','Bilgisayar',
  'Enerji','Tarım','Orman','Maden','Tekstil','Kimya','Metal','Makine',
  'Taahhüt','Hizmetleri','Pazarlama','Dağıtım','Lojistik','Yapı'
)
$desen = '^(' + (($JENERIK | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\b'

# --- ÖZ-SINAV (93 kapı kuralı) --------------------------------------------
$SINAV = @(
  @{ ad='Ticaret Limited Şirketi';                              b=$true  },  # gerçek kusur
  @{ ad='Sanayi ve Ticaret Anonim Şirketi';                     b=$true  },
  @{ ad='Mühendislik Mimarlık Müşavirlik';                      b=$true  },
  @{ ad='Avcan Taşımacılık Sanayi ve Ticaret Limited Şirketi';  b=$false },  # sağlam
  @{ ad='Mehmet Yılmaz';                                        b=$false },  # şahıs firması
  @{ ad='Öz Demir İnşaat Taahhüt Anonim Şirketi';               b=$false }
)
$kotu = @($SINAV | Where-Object { ($_.ad -match $desen) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - olcut bozuk, olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  beklenen={0}  ad: {1}" -f $_.b, $_.ad) -ForegroundColor Red }
  exit 2
}

if(-not (Test-Path $OZET)){ Write-Host "Ozet yok: $OZET" -ForegroundColor Red; exit 1 }
$j = Get-Content $OZET -Raw -Encoding UTF8 | ConvertFrom-Json
$hepsi = @($j.firmalar)
$kusurlu = @($hepsi | Where-Object { "$($_.ad)" -match $desen })

$toplamIhale = ($kusurlu | Measure-Object ihaleSayisi -Sum).Sum
$toplamBedel = ($kusurlu | Measure-Object toplamBedel -Sum).Sum

Write-Host ("IHALE FIRMA ADI DENETIMI: {0} firma kaydi tarandi." -f $hepsi.Count)
Write-Host ("  Ozel adi KAYIP (jenerik kelimeyle basliyor): {0}" -f $kusurlu.Count) -ForegroundColor $(if($kusurlu.Count){'Red'}else{'Green'})
if($kusurlu.Count){
  Write-Host ("  Etkilenen ihale : {0}" -f $toplamIhale) -ForegroundColor Red
  Write-Host ("  Etkilenen bedel : {0:N0} TL" -f $toplamBedel) -ForegroundColor Red
  Write-Host ""
  Write-Host "  EN BUYUK 8:" -ForegroundColor Cyan
  $kusurlu | Sort-Object { [double]$_.toplamBedel } -Descending | Select-Object -First 8 | ForEach-Object {
    Write-Host ("    {0,-36} {1,4} ihale · {2,18:N0} TL" -f $_.ad.Substring(0,[Math]::Min(34,$_.ad.Length)), $_.ihaleSayisi, $_.toplamBedel)
  }
}
if($Ayrinti){
  Write-Host ""
  Write-Host "  AYRINTI (IKN listeleriyle):" -ForegroundColor Cyan
  $kusurlu | Sort-Object { [double]$_.toplamBedel } -Descending | ForEach-Object {
    $ikn = @($_.ihaleler | ForEach-Object { $_.ikn }) -join ', '
    Write-Host ("    {0}" -f $_.ad)
    Write-Host ("      IKN: {0}" -f $(if($ikn.Length -gt 100){ $ikn.Substring(0,100)+'...' }else{ $ikn }))
  }
}

$cikti = [pscustomobject]@{
  olcum = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  aciklama = "Ozel adi kayip yuklenici kayitlari. Olcut: firma adi JENERIK bir sirket ekiyle BASLIYOR (Ticaret/Sanayi/Limited...). Kisalik tek basina kusur DEGILDIR - sahis firmalari ('Mehmet ...') normaldir. Onarim: her kaydin IKN'lerinin sonuc ilani yeniden okunmali."
  kaynak = "veri/ihale-firma-ozet.json"
  taranan = $hepsi.Count
  kusurlu = $kusurlu.Count
  etkilenen_ihale = $toplamIhale
  etkilenen_bedel = $toplamBedel
  kayitlar = @($kusurlu | Sort-Object { [double]$_.toplamBedel } -Descending | ForEach-Object {
    [pscustomobject]@{
      ad = $_.ad; ihaleSayisi = $_.ihaleSayisi; toplamBedel = $_.toplamBedel
      ikn = @($_.ihaleler | ForEach-Object { $_.ikn })
    }
  })
}
$hedef = Join-Path $KOK 'veri\ihale-kesik-firma-adi.json'
($cikti | ConvertTo-Json -Depth 6) | Set-Content $hedef -Encoding UTF8
Write-Host ""
Write-Host "  yazildi: veri/ihale-kesik-firma-adi.json" -ForegroundColor Green

# --- CIRCIR: mevcut borc taban, ARTIS kirmizi -----------------------------
# 115 kayit BUGUN duruyor. Kapiyi "kusur varsa kirmizi" yaparsak surekli
# kirmizi olur ve kapi olmaktan cikar (kalici sigorta dersi). Olculen sey
# ARTIS: yeni kosuda kesik ad sayisi artarsa ayristirici bozulmus demektir.
$TABAN = Join-Path $KOK 'veri\ihale-firma-adi-taban.json'
if($Tazele){
  ([pscustomobject]@{
    aciklama = "Kesik (ozel adi kayip) yuklenici kaydi tabani. ARTIS kirmizidir; azalirsa -Tazele ile indirilir. Onarim malzemesi: veri/ihale-kesik-firma-adi.json (IKN listeleri)."
    olcum = (Get-Date).ToString('dd.MM.yyyy HH:mm')
    kusurlu = $kusurlu.Count
    etkilenen_ihale = $toplamIhale
  } | ConvertTo-Json -Depth 3) | Set-Content $TABAN -Encoding UTF8
  Write-Host ("  taban tazelendi: {0} kusurlu kayit" -f $kusurlu.Count) -ForegroundColor Green
  exit 0
}
if(-not (Test-Path $TABAN)){
  Write-Host "  TABAN YOK - once bir kez tazele: ... -Tazele" -ForegroundColor Yellow
  exit 0
}
$t = Get-Content $TABAN -Raw -Encoding UTF8 | ConvertFrom-Json
$eski = [int]$t.kusurlu
if($kusurlu.Count -gt $eski){
  Write-Host ""
  Write-Host ("  KIRMIZI - kesik firma adi ARTMIS: {0} -> {1}" -f $eski, $kusurlu.Count) -ForegroundColor Red
  Write-Host "  Ayristirici bozulmus olabilir: motor/ihale-sonuc-ayristir.ps1 yuklenici deseni." -ForegroundColor Yellow
  exit 1
}
if($kusurlu.Count -lt $eski){
  Write-Host ("  Borc azalmis ({0} -> {1}) - tabani indir: ... -Tazele" -f $eski, $kusurlu.Count) -ForegroundColor Green
}
Write-Host ("  Taban {0} - artis yok." -f $eski) -ForegroundColor Green
exit 0
