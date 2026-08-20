# ============================================================================
#  KGF PAKET HASAT - Kredi Garanti Fonu'nun AKTIF kefalet/destek paketlerini
#  ceker. (19.08 Cem: "kgf paketlerini ekleyebilirsin".) Paketler donemseldir,
#  acilir-kapanir; katalog karti "aktif paketleri kgf.com.tr'den teyit et" diyordu,
#  artik robot teyit ediyor.
#  Cikti: veri/kgf-paket.json - destekler.html "KGF aktif paketler" grubu okur.
#
#  Kaynak kesfi 19.08 OLCULDU:
#   - kgf.com.tr ana sayfa menusu urun agacini tasiyor ve AKTIF/GECMIS ayrimini
#     KENDISI yapiyor: /urunlerimiz/ altinda 'gecmis-programlar' segmenti gecmis,
#     kalani aktif (7 hazine + 18 ozkaynak-banka + 2 dogrudan + 5 KOSGEB destekli).
#   - "aktif-destek-paketleri-2025" segment adi yila gore degisebilir ->
#     kurala baglanmaz; kural: urunlerimiz VE NOT gecmis-programlar.
#  Basvuru yolu sabit bilgi: KGF'ye degil BANKAYA basvurulur (katalog karti anlatir).
#  Kor kalma: paket < 10 ya da hazine kategorisi bos -> dosyaya DOKUNULMAZ, exit 1.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buradir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokDizin = Split-Path -Parent $buradir
$ciktiYolu = Join-Path $kokDizin "veri\kgf-paket.json"
$curlKomut = if(Get-Command curl.exe -ErrorAction SilentlyContinue){ "curl.exe" } else { "curl" }

$anaDosya = Join-Path ([IO.Path]::GetTempPath()) "kgf-ana.html"
# 20.08 OLCULDU: kgf.com.tr'nin onundeki Sucuri Cloudproxy govdeyi ARTIK
# istenmeden gzip'liyor; --compressed olmadan curl ham gzip yaziyor, HTML
# okunamiyor ve menude 0 paket bulunuyordu (kor kalma dogru calisti: dosyaya
# dokunulmadi + alarm gitti). --compressed sunucu sikistirmasa da zararsiz.
& $curlKomut -sSL --compressed -m 60 -A "Mozilla/5.0 (TetikteRobotu; +https://tetikte.com)" -o $anaDosya "https://www.kgf.com.tr"
if(-not (Test-Path $anaDosya)){ Write-Host "HATA: kgf.com.tr cekilemedi"; exit 1 }
$anaHtml = Get-Content $anaDosya -Raw -Encoding UTF8

function KategoriAdi([string]$yol){
  if($yol -match 'hazine-destekli'){ return 'Hazine destekli' }
  if($yol -match 'kosgeb-destekli'){ return 'KOSGEB destekli' }
  if($yol -match 'dogrudan-krediler'){ return 'Doğrudan kredi' }
  return 'Özkaynak / banka kredisi'
}

$paketler = @()
$gorulen = @{}
foreach($m in [regex]::Matches($anaHtml, '<a[^>]*href="(/index\.php/tr/urunlerimiz/[^"]+)"[^>]*>\s*([^<]{3,90})')){
  $yol = $m.Groups[1].Value
  if($yol -match 'gecmis-programlar'){ continue }   # menunun kendi ayrimi
  $ad = (($m.Groups[2].Value -replace '\s+',' ').Trim())
  if(-not $ad -or $ad -match '^&gt;|^>$'){ continue }
  if($gorulen.ContainsKey($yol)){ continue }
  $gorulen[$yol] = 1
  # kategori basligi olan ara-dugum linklerini ele (urun degil bolum basligi):
  # urun linkleri en az 4 segment tasir (urunlerimiz/kategori/alt/urun)
  $derinlik = ($yol -replace '/index\.php/tr/','').Split('/').Count
  if($derinlik -lt 3){ continue }
  $paketler += [ordered]@{
    paket = $ad
    kategori = (KategoriAdi $yol)
    url = ("https://www.kgf.com.tr" + $yol)
  }
}

$hazineAdet = @($paketler | Where-Object { $_.kategori -eq 'Hazine destekli' }).Count
if(@($paketler).Count -lt 10 -or $hazineAdet -lt 1){
  Write-Host ("HATA: beklenmedik veri ({0} paket, hazine {1}) - dosyaya DOKUNULMADI (menu yapisi degismis olabilir)" -f @($paketler).Count, $hazineAdet)
  exit 1
}

$cikti = [ordered]@{
  guncelleme = "Kaynak: KGF urun menusu (kgf.com.tr, aktif/gecmis ayrimi kurumun kendi siniflamasi). Son cekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynakSayfa = "https://www.kgf.com.tr"
  not = "Basvuru KGF'ye degil calistigin BANKAYA yapilir; kefalet talebini banka iletir. Paket kosullari (limit, vade, sektor) paket sayfasinda."
  paketler = $paketler
}
($cikti | ConvertTo-Json -Depth 4) | Out-File $ciktiYolu -Encoding utf8

$geriOkuma = Get-Content $ciktiYolu -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("KGF PAKET: {0} aktif paket (hazine {1}) -> veri/kgf-paket.json [geri okuma: {2}]" -f @($paketler).Count, $hazineAdet, @($geriOkuma.paketler).Count)
if(@($geriOkuma.paketler).Count -ne @($paketler).Count){ Write-Host "HATA: geri okuma sayimi tutmadi"; exit 1 }
