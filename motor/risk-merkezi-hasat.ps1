# ============================================================================
#  RISK MERKEZI HASAT (15.08.2026) - TBB Risk Merkezi Aylık Bülteni izleme.
#
#  Cem "risk merkezi bültenleri hasat et". Protesto edilen senet + karşılıksız
#  çek makro verisi EVDS'te DEĞİL (taşınmış), TBB Risk Merkezi'nde public PDF
#  bülten olarak. Kaynak metin çıkarılabilir AMA rakamlar infografik düzende;
#  sayı-birim eşlemesi metin sırasında bozuluyor -> TAM OTOMATİK parser KIRILGAN
#  (yanlış rakam riski, rakam disiplinine aykırı).
#
#  DESEN (GTİP-RG sinyali gibi): robot yeni bülteni YAKALAR, indirir, aday
#  rakamları çıkarır ve Cem'e "yeni bülten çıktı, teyit et" MAİLİ atar. Rakamı
#  veri/risk-merkezi.json'a OTOMATİK BASMAZ; elle teyitten sonra güncellenir.
#  Böylece siteye yalnız teyitli resmî rakam gider.
# ============================================================================
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = "Mozilla/5.0 (MevzuatRadar-RiskMerkezi)"
$veriYol = Join-Path $kok "veri\risk-merkezi.json"

# 1) rapor listesinden en yeni aylık bülten sayfasını bul
try { $ana = (Invoke-WebRequest -Uri "https://www.riskmerkezi.org/tr" -UserAgent $UA -TimeoutSec 60 -UseBasicParsing).Content }
catch { Write-Host "Risk Merkezi sitesine ulaşılamadı, çıkılıyor."; exit 0 }

$AYLAR = "ocak","subat","mart","nisan","mayis","haziran","temmuz","agustos","eylul","ekim","kasim","aralik"
$m = [regex]::Matches($ana, '/istatistiki-raporlar/(\d{4})-([a-z]+)-risk-merkezi-aylik-bulteni')
$adaylar = @()
foreach($x in $m){
  $yil = [int]$x.Groups[1].Value; $ay = $x.Groups[2].Value
  $ai = [array]::IndexOf($AYLAR, $ay)
  if($ai -ge 0){ $adaylar += [pscustomobject]@{ url = "https://www.riskmerkezi.org"+$x.Value; yil=$yil; ayNo=$ai+1; ay=$ay; sira=$yil*100+$ai+1 } }
}
if(-not $adaylar.Count){ Write-Host "Bülten linki bulunamadı (site yapısı değişmiş olabilir)."; exit 0 }
$enYeni = $adaylar | Sort-Object sira -Descending | Select-Object -First 1
$enYeniAd = ("{0} {1}" -f ($enYeni.ay.Substring(0,1).ToUpper()+$enYeni.ay.Substring(1)), $enYeni.yil)
Write-Host ("En yeni bülten: {0} · {1}" -f $enYeniAd, $enYeni.url)

# 2) elimizdeki ile karşılaştır
$mevcut = if(Test-Path $veriYol){ (Get-Content $veriYol -Raw -Encoding UTF8 | ConvertFrom-Json).bultenAyi } else { "" }
if($mevcut -eq $enYeniAd){ Write-Host "Zaten güncel ($mevcut). Yeni bülten yok, çıkılıyor."; exit 0 }

Write-Host ("YENİ BÜLTEN: {0} (elimizdeki: {1})" -f $enYeniAd, $mevcut)

# 3) PDF indirme linkini bülten sayfasından bul (/download/node/.../field_raporlar_ekler/...)
$pdfUrl = ""
try {
  $sayfa = (Invoke-WebRequest -Uri $enYeni.url -UserAgent $UA -TimeoutSec 60 -UseBasicParsing).Content
  $dl = [regex]::Match($sayfa, '/download/node/\d+/field_raporlar_ekler/\d+')
  if($dl.Success){ $pdfUrl = "https://www.riskmerkezi.org" + $dl.Value }
} catch {}

# 4) Cem'e teyit maili at (rakamı OTOMATİK basmıyoruz - infografik parser kırılgan)
$mesaj = "TBB Risk Merkezi'nde YENİ aylık bülten yayımlandı: $enYeniAd.`n`nSayfa: $($enYeni.url)`nPDF: $pdfUrl`n`nYapılacak (2 dk): PDF'i aç, şu 3 manşet rakamı oku ve veri/risk-merkezi.json'u güncelle:`n- Protesto edilen senet tutarı (Milyar TL)`n- Karşılıksız işlemi yapılan çek tutarı (Milyar TL)`n- Bankalara ibraz edilen çek tutarı (Milyar TL)`n`nNot: Rakamlar bültende infografik olduğu için otomatik çekilmiyor; yanlış rakam riskine karşı elle teyit ediyoruz. Teyit sonrası site kendini günceller."
$mb = @{
  access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
  subject    = "TETIKTE - Risk Merkezi yeni bulten: $enYeniAd (protesto/cek rakamlarini teyit et)"
  from_name  = "Tetikte Risk Merkezi Nobetcisi"
  email      = "cemdizdar85@hotmail.com"
  message    = $mesaj
} | ConvertTo-Json -Depth 3
try { Invoke-RestMethod -Uri "https://api.web3forms.com/submit" -Method Post -ContentType "application/json" -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -TimeoutSec 30 | Out-Null; Write-Host "Teyit maili gönderildi." }
catch { Write-Host ("Mail gitmedi: " + $_.Exception.Message) }
exit 0
