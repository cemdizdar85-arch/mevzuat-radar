# ============================================================================
#  EKSIK DOSYA KAPISI — sayfalarin cagirdigi dosya depoda YOKSA push kirmizi.
#
#  NEDEN VAR (25.08.2026)
#  Ayni tuzak AYNI GUN IKI KEZ patladi:
#    1. marka-serit.js  - diskte vardi, yerel gecmiste izlenmiyordu; yayin
#       sirasinda "silinecek" diye isaretlendi, son anda yakalandi (56 satir
#       canli kod silinmek uzereydi).
#    2. fiyat-motoru.js - diskte vardi, HIC commit edilmemisti. CANLIDA 404
#       veriyordu; fiyat.html'de sinav takvimi BOS, satin-al.html'de paket
#       listesi hic olusmuyordu. Fiyat rakamlari sayfa icinde yazili oldugu
#       icin goruntu tamamen bozuk degildi - bu yuzden fark edilmemisti.
#  Ikisini de TESADUFEN yakaladim. Ucuncusu yakalanmayabilir ve haftalarca
#  fark edilmeyebilir. Bu kapi o tesadufu ortadan kaldirir.
#
#  NE YAPAR
#  Kok dizindeki .html sayfalarinin src/href ile cagirdigi YEREL dosyalari
#  toplar, her birinin depoda durup durmadigina bakar. Bulunmayan varsa
#  1 koduyla duser.
#
#  KAPSAM DISI (bilerek)
#  - http(s):// ve // ile baslayan dis adresler (sayac betigi vb.)
#  - #capa, mailto:, tel:, data:, javascript:
#  - {sablon} icerenler (JS ile uretilen yollar - statik bakisla cozulemez)
#  API maliyeti SIFIR. Dogrulama Kapisi (dogrula.yml) icinden her push'ta kosar.
# ============================================================================
$ErrorActionPreference = "Stop"
$kok = (git rev-parse --show-toplevel).Trim()
Set-Location $kok

$sayfalar = Get-ChildItem -Path $kok -Filter "*.html" -File
if(-not $sayfalar){ Write-Host "EKSIK DOSYA KAPISI: kokte .html yok, atlandi."; exit 0 }

# src="..." ve href="..." degerlerini topla
$desen = '(?:src|href)\s*=\s*"([^"]+)"'
$eksikler = @()
$bakilan  = 0

foreach($s in $sayfalar){
  $metin = Get-Content $s.FullName -Raw -Encoding UTF8
  foreach($m in [regex]::Matches($metin, $desen)){
    $yol = $m.Groups[1].Value.Trim()

    # --- kapsam disi olanlar
    if($yol -eq "")                         { continue }
    if($yol -match '^(https?:)?//')         { continue }   # dis adres
    if($yol -match '^(#|mailto:|tel:|data:|javascript:)') { continue }
    if($yol -match '[{}$]')                 { continue }   # sablon degiskeni
    if($yol -match '^\?')                   { continue }   # yalniz sorgu

    # sorgu/capa ekini at
    $temiz = ($yol -split '[?#]')[0]
    if($temiz -eq ""){ continue }

    # yalniz gercek dosya uzantisi olanlara bak (dizin/rota degil)
    if($temiz -notmatch '\.(js|css|json|svg|png|jpg|jpeg|webp|ico|woff2?|txt|pdf|html)$'){ continue }

    $bakilan++
    $tam = Join-Path $kok $temiz.Replace('/', [IO.Path]::DirectorySeparatorChar)
    if(-not (Test-Path -LiteralPath $tam)){
      $eksikler += [pscustomobject]@{ Sayfa = $s.Name; Yol = $temiz }
    }
  }
}

Write-Host ("EKSIK DOSYA KAPISI: {0} sayfa, {1} yerel basvuru denetlendi." -f $sayfalar.Count, $bakilan)

if($eksikler.Count -gt 0){
  # ayni dosya bircok sayfadan cagriliyorsa tek satirda topla
  $grup = $eksikler | Group-Object Yol | Sort-Object Count -Descending
  Write-Host ""
  Write-Host "  KIRMIZI - sayfalarin cagirdigi su dosyalar depoda YOK:"
  foreach($g in $grup){
    $sayfaListe = ($g.Group | Select-Object -ExpandProperty Sayfa | Sort-Object -Unique) -join ", "
    Write-Host ("    {0}   <- {1}" -f $g.Name, $sayfaListe)
  }
  Write-Host ""
  Write-Host "  Dosya diskte duruyor olabilir ama COMMIT EDILMEMIS olabilir."
  Write-Host "  Kontrol: git status --porcelain | findstr /R \"^??\""
  exit 1
}

Write-Host "  Temiz - cagrilan her dosya depoda."
exit 0
