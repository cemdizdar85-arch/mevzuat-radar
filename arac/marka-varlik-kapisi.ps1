# ============================================================================
#  MARKA VARLIK KAPISI — türetilmiş varlıklar kaynaktan geri kalmasın
#
#  NEDEN VAR (30.08.2026): marka varlıkları (favicon, ikonlar, paylaşım
#  kartları) favicon.svg + logo.svg'den TÜRETİLİYOR. Logo değişip varlıklar
#  yeniden basılmazsa sonuç sessiz ve utandırıcı olur: sekmede eski logo,
#  paylaşımda yeni logo, iPhone ana ekranında bir üçüncüsü. Hiçbir test bunu
#  yakalamaz çünkü sayfalar açılır, konsol temizdir, kontrast doğrudur.
#
#  NEDEN BYTE KARŞILAŞTIRMASI YOK — ölçüldü ve çalışmıyor:
#  Chrome aynı SVG'den her koşuda birebir aynı PNG üretmiyor (anti-aliasing,
#  sürüm ve platform farkı). 30.08'de aynı kaynaktan iki koşu 11,5 KB ve
#  10,8 KB verdi. Byte kıyaslayan bir kapı SÜREKLI KIRMIZI olurdu - ve
#  sürekli kırmızı kapı kapı değildir.
#
#  ÖLÇÜT: KAYNAK PARMAK İZİ. Üretici, bastığı anda kaynak SVG'lerin SHA-256
#  özetini veri/marka-varlik-kunyesi.json'a yazar. Kapı bugünkü özeti künyeyle
#  kıyaslar: farklıysa kaynak değişmiş ama varlıklar yeniden basılmamıştır.
#
#  NEDEN GIT KÜTÜĞÜ DEĞİL — ölçüldü: dogrula.yml `fetch-depth: 2` ile SIĞ klon
#  yapıyor (diff bekçisi HEAD~1 istiyor). Sığ klonda `git log -1 -- dosya`
#  son iki commit'te değişmemiş dosyalar için BOŞ döner; kapı "ölçemedim"
#  deyip sessizce işlevsiz kalırdı. Parmak izi git'ten bağımsızdır.
#
#  Ayrıca: beklenen varlıklar duruyor mu + HTML'lerin gösterdiği marka
#  varlıkları gerçekten var mı (kırık referans) + manifest'in gösterdikleri.
#
#  Bayat çıkarsa çözüm tek satır:
#      powershell -NoProfile -File arac/marka-varlik-uret.ps1
# ============================================================================
$ErrorActionPreference = 'Continue'
$KOK = Split-Path $PSScriptRoot -Parent

# türetilmiş varlık -> hangi kaynaktan üretiliyor
$TURETILEN = @{
  'apple-touch-icon.png'   = 'favicon.svg'
  'icon-192.png'           = 'favicon.svg'
  'icon-512.png'           = 'favicon.svg'
  'icon-maskable-512.png'  = 'favicon.svg'
  'og-kapak.png'           = 'logo.svg'
  'og-kahraman.png'        = 'logo.svg'
}
$ELLE = @('favicon.svg','logo.svg','logo-acik.svg','manifest.webmanifest')

function Ozet([string]$yol){
  $tam = Join-Path $KOK $yol
  if(-not (Test-Path $tam)){ return $null }
  $s = [System.Security.Cryptography.SHA256]::Create()
  try {
    # Satır sonu farkı (CRLF/LF) özeti değiştirmesin - depo iki platformda
    # da klonlanıyor. Metin dosyaları normalize edilir.
    $ham = [System.IO.File]::ReadAllText($tam) -replace "`r`n", "`n"
    return [BitConverter]::ToString($s.ComputeHash([Text.Encoding]::UTF8.GetBytes($ham))).Replace('-','').ToLowerInvariant()
  } finally { $s.Dispose() }
}

$kusur = @(); $uyari = @()

# --- 1) dosyalar duruyor mu -----------------------------------------------
foreach($d in ($TURETILEN.Keys + $ELLE)){
  if(-not (Test-Path (Join-Path $KOK $d))){ $kusur += "EKSIK DOSYA: $d" }
}

# --- 2) kaynak parmak izi: varlıklar kaynaktan geri kalmış mı? -------------
$kunyeYol = Join-Path $KOK 'veri\marka-varlik-kunyesi.json'
$kaynaklar = @($TURETILEN.Values | Sort-Object -Unique)
if(-not (Test-Path $kunyeYol)){
  $uyari += "KUNYE YOK (veri/marka-varlik-kunyesi.json) - uretici bir kez kosturulmali"
} else {
  try {
    $kunye = Get-Content $kunyeYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($k in $kaynaklar){
      $simdi = Ozet $k
      if($null -eq $simdi){ continue }   # eksik dosya zaten yukarida raporlandi
      $kayitli = $kunye.kaynaklar.$k
      if(-not $kayitli){ $uyari += "KUNYEDE YOK: $k"; continue }
      if($kayitli -ne $simdi){
        $etkilenen = @($TURETILEN.Keys | Where-Object { $TURETILEN[$_] -eq $k }) -join ', '
        $kusur += ("BAYAT: {0} degismis ama ondan turetilen varliklar yeniden basilmamis -> {1}" -f $k, $etkilenen)
      }
    }
  } catch { $kusur += "KUNYE okunamadi (bozuk JSON?)" }
}

# --- 3) HTML'lerin gosterdigi marka varliklari gercekten var mi? -----------
# Kirik favicon/ikon referansi sessizdir: sekmede varsayilan ikon cikar,
# kimse fark etmez. Yalniz marka varliklarina bakilir (genel link denetimi
# link-nobetcisi.ps1'in isi).
$markaDesen = '(favicon\.svg|apple-touch-icon\.png|icon-\d+\.png|icon-maskable-\d+\.png|og-[a-z]+\.png|logo(-acik)?\.svg|manifest\.webmanifest)'
$kirik = @{}
foreach($f in (Get-ChildItem (Join-Path $KOK '*.html') -File)){
  $ic = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  foreach($m in [regex]::Matches($ic, $markaDesen)){
    $ad = $m.Value
    if(-not (Test-Path (Join-Path $KOK $ad))){
      if(-not $kirik.ContainsKey($ad)){ $kirik[$ad] = @() }
      if($kirik[$ad] -notcontains $f.Name){ $kirik[$ad] += $f.Name }
    }
  }
}
foreach($ad in $kirik.Keys){
  $kusur += ("KIRIK REFERANS: {0} yok ama {1} sayfada gosteriliyor ({2})" -f $ad, $kirik[$ad].Count, ($kirik[$ad] | Select-Object -First 3) -join ', ')
}

# --- 4) manifest ikonlari var mi ------------------------------------------
$mf = Join-Path $KOK 'manifest.webmanifest'
if(Test-Path $mf){
  try{
    $mj = Get-Content $mf -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($i in @($mj.icons)){
      $ad = ($i.src -replace '^/','')
      if(-not (Test-Path (Join-Path $KOK $ad))){ $kusur += "MANIFEST: $ad yok ama manifest gosteriyor" }
    }
  } catch { $kusur += "MANIFEST okunamadi (bozuk JSON?)" }
}

# --- rapor ----------------------------------------------------------------
Write-Host ("MARKA VARLIK KAPISI: {0} turetilmis + {1} elle varlik denetlendi." -f $TURETILEN.Count, $ELLE.Count)
if($uyari.Count){ $uyari | ForEach-Object { Write-Host ("  ? {0}" -f $_) -ForegroundColor DarkGray } }
if($kusur.Count -eq 0){
  Write-Host "  Temiz - turetilmis varliklar kaynakla ayni yasta, kirik referans yok." -ForegroundColor Green
  exit 0
}
Write-Host ""
Write-Host "  KIRMIZI:" -ForegroundColor Red
$kusur | ForEach-Object { Write-Host ("    $_") -ForegroundColor Red }
Write-Host ""
Write-Host "  Cozum: powershell -NoProfile -File arac/marka-varlik-uret.ps1" -ForegroundColor Yellow
Write-Host "         (sonra uretilen varliklari commit'le)" -ForegroundColor Yellow
exit 1
