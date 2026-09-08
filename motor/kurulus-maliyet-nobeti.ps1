# ============================================================================
#  KURULUS MALIYET NOBETCISI - veri/kurulus-maliyet.json'un kaynaklari degisti mi?
#
#  NEDEN VAR (08.09.2026): kurulus-nobeti.html "kaca mal olur" sorusuna 2026
#  tarifeleriyle cevap verir. Tarifeler yilbasinda (yeniden degerleme) ve
#  bazen yil ortasinda degisir. Bu nobetci kaynak dosyalarini kollar:
#    - PDF kaynaklar (ITO tarifesi, TURMOB tarifesi): SHA256 karsilastirmasi
#    - HTML kaynaklar (TOBB ilan tarifesi, alomaliye harc tablosu): sayfada
#      BEKLENEN RAKAMLAR hala var mi? ("kaynak degisti" != "deger degisti":
#      HTML her kosuda degisir, o yuzden hash degil deger kollanir.)
#  Sonuc: YESIL (hepsi ayni) / KIRMIZI (deger veya PDF degisti -> Cem'e mail,
#  veri/kurulus-maliyet.json elle guncellenir) / KOR (kaynak inmedi).
#  Rapor: veri/kurulus-maliyet-nobeti.json (RaporYaz: icerik ayniysa dokunmaz).
#  API maliyeti SIFIR.
# ============================================================================
param([switch]$Taban)   # -Taban: PDF hash'lerini yeniden temel al (tarife guncellendikten sonra)

$ErrorActionPreference = 'Stop'
$depoKok = (git rev-parse --show-toplevel).Trim()
Set-Location $depoKok
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')

$hedef = Join-Path $depoKok 'veri\kurulus-maliyet-nobeti.json'
$eski = $null
if (Test-Path $hedef) { try { $eski = Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $eski = $null } }

# Beklenen degerler veri/kurulus-maliyet.json'dan turetilir; oradaki rakam
# degisince buradaki beklenti de kendiliginden degisir (tek kaynak).
$M = Get-Content (Join-Path $depoKok 'veri\kurulus-maliyet.json') -Raw -Encoding UTF8 | ConvertFrom-Json
function TrPara([double]$n){ return $n.ToString('N2', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }

$kaynaklar = @(
  @{ ad='ITO 2026 sicil tarifesi (PDF)'; url='https://www.ito.org.tr/documents/Ticaret-Sicil/onemli_bilgiler_ve_duyurular/harc.pdf'; tur='pdf' },
  @{ ad='TURMOB 2026 ucret tarifesi (PDF)'; url='https://www.turmob.org.tr/arsiv/mbs/resmigazete/33110-2026-SMMMUCRET-TARIFESI.pdf'; tur='pdf' },
  # 08.09 olculdu: TOBB'un kendi sayfasi (tobb.org.tr/.../ilanucretleri.html) ESKI tabloyu
  # (0,30 TL) gosteriyor; 2026 tarifesi ("Yururluk 01.01.2026") ALTSO'nun sayfasinda.
  @{ ad='TTSG ilan tarifesi 2026 (ALTSO aynasi)'; url='https://www.altso.org.tr/hizmetlerimiz/sicil-islemleri/tahmini-harc-oda-islem-ve-ilan-ucretleri/turkiye-ticaret-sicili-gazetesi-ilan-ucret-tarifesi/'; tur='html';
     bekle=@( (TrPara $M.ttsgIlan.sirketKurulusKelime), (TrPara $M.ttsgIlan.sirketIlanKelime), (TrPara $M.ttsgIlan.gercekKisiTicareteBaslamaMaktu) ) },
  @{ ad='2026 ticaret sicili harclari (alomaliye)'; url='https://www.alomaliye.com/2026/01/01/2026-yili-ticaret-sicili-harclari/'; tur='html';
     bekle=@( (TrPara $M.sicilHarclari.sahisKurulus), (TrPara $M.sicilHarclari.sahisSicilTasdiknamesi) ) }
)

$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) TetikteNobet/1.0'
$sonuc = @(); $kirmizi = 0; $kor = 0
foreach ($k in $kaynaklar) {
  $satir = [ordered]@{ ad=$k.ad; url=$k.url; tur=$k.tur; durum='?'; not='' }
  try {
    $r = Invoke-WebRequest -Uri $k.url -UserAgent $ua -TimeoutSec 60 -UseBasicParsing
    if ($k.tur -eq 'pdf') {
      $bytes = $r.Content
      if ($bytes -is [string]) { $bytes = [Text.Encoding]::GetEncoding(28591).GetBytes($bytes) }   # 28591 = Latin1; PS 5.1'de [Encoding]::Latin1 yok
      $imza = [Text.Encoding]::ASCII.GetString($bytes[0..3])
      if ($imza -ne '%PDF') { throw "PDF imzasi yok (ilk baytlar: $imza)" }
      $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
      $satir.sha256 = $sha; $satir.boyut = $bytes.Length
      $onceki = $null
      if ($eski -and $eski.kaynaklar) { $onceki = ($eski.kaynaklar | Where-Object { $_.url -eq $k.url } | Select-Object -First 1) }
      if ($Taban -or -not $onceki -or -not $onceki.sha256) { $satir.durum = 'YESIL'; $satir.not = 'temel alindi' }
      elseif ($onceki.sha256 -eq $sha) { $satir.durum = 'YESIL'; $satir.not = 'PDF ayni' }
      else { $satir.durum = 'KIRMIZI'; $satir.not = "PDF degisti (onceki $($onceki.sha256.Substring(0,12))...) - tarifeyi oku, veri/kurulus-maliyet.json'u guncelle, sonra -Taban ile kos"; $kirmizi++ }
    } else {
      $metin = [string]$r.Content
      $eksik = @($k.bekle | Where-Object { $metin -notlike ('*' + $_ + '*') })
      $satir.beklenen = $k.bekle
      if ($eksik.Count -eq 0) { $satir.durum = 'YESIL'; $satir.not = 'beklenen rakamlar sayfada' }
      else { $satir.durum = 'KIRMIZI'; $satir.eksik = $eksik; $satir.not = 'sayfada bulunamayan rakam: ' + ($eksik -join ', ') + ' - tarife degismis olabilir'; $kirmizi++ }
    }
  } catch {
    $satir.durum = 'KOR'; $satir.not = ('inmedi: ' + $_.Exception.Message); $kor++
  }
  Write-Host ("  {0,-8} {1}  {2}" -f $satir.durum, $k.ad, $satir.not)
  $sonuc += [pscustomobject]$satir
}

$genel = if ($kirmizi) { 'KIRMIZI' } elseif ($kor) { 'KOR' } else { 'YESIL' }
$cikti = [pscustomobject]@{
  olcum = (Get-Date).ToString('dd.MM.yyyy HH:mm')
  durum = $genel
  sabitDosyasi = 'veri/kurulus-maliyet.json'
  sabitGuncelleme = $M.guncelleme
  kaynaklar = $sonuc
  not = 'KIRMIZI = kaynaktaki deger ya da PDF degisti; tarife okunur, kurulus-maliyet.json elle guncellenir, PDF icin -Taban ile temel tazelenir. KOR = kaynak inmedi, hukum verilmez.'
}
RaporYaz -Hedef $hedef -Nesne $cikti | Out-Null
Write-Host "KURULUS MALIYET NOBETI: $genel"
if ($genel -eq 'KIRMIZI') { exit 1 }
if ($genel -eq 'KOR') { exit 2 }
exit 0
