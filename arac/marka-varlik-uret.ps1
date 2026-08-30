# ============================================================================
#  MARKA VARLIK ÜRETİCİSİ — favicon.svg / logo.svg'den tüm ikon ve kartlar
#
#  NEDEN VAR (30.08.2026): varlıklar bir kez elle üretilseydi, logo değişince
#  kimse hangi dosyaların yeniden basılacağını hatırlamazdı — ve sekmede eski,
#  paylaşımda yeni logo görünürdü. Tek kaynak ilkesi varlıklara da uygulanır:
#  KAYNAK favicon.svg + logo.svg, geri kalan HEPSİ buradan türetilir.
#
#  ÜRETİLENLER:
#    apple-touch-icon.png     180  iOS ana ekran (iOS SVG KABUL ETMEZ)
#    icon-192.png             192  PWA / Android
#    icon-512.png             512  PWA / mağaza
#    icon-maskable-512.png    512  Android ikonu KIRPAR - güvenli alan %72
#    og-kapak.png            1200x630  genel paylaşım kartı
#    og-kahraman.png         1200x630  fark.html kartı (kilitli cümle)
#
#  Chrome headless ile basılır (bağımlılık yok, API maliyeti sıfır).
#  Kullanım:  powershell -NoProfile -File arac/marka-varlik-uret.ps1
# ============================================================================
param([switch]$YalnizIkon, [switch]$YalnizKart)

# Chrome basari mesajini bile stderr'e yazar; Stop kullanilirsa betik onda duser.
$ErrorActionPreference = 'Continue'
$KOK = Split-Path $PSScriptRoot -Parent
$GEC = Join-Path $env:TEMP ("marka-varlik-" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Force -Path $GEC | Out-Null

function ChromeBul {
  $adaylar = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    '/usr/bin/google-chrome', '/usr/bin/chromium'
  )
  foreach($a in $adaylar){ if($a -and (Test-Path $a)){ return $a } }
  throw "Chrome/Edge bulunamadi - varliklar uretilemez."
}
$CHROME = ChromeBul

function Bas($htmlIcerik, $ad, $en, $boy){
  $h = Join-Path $GEC "$ad.html"
  [System.IO.File]::WriteAllText($h, $htmlIcerik, (New-Object System.Text.UTF8Encoding($false)))
  $cikti = Join-Path $KOK $ad
  & $CHROME --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 `
            --window-size=$en,$boy --screenshot="$cikti" ("file:///" + ($h -replace '\\','/')) 2>$null | Out-Null
  Start-Sleep -Seconds 2
  if(Test-Path $cikti){ "  {0,-26} {1,6} KB" -f $ad, [math]::Round((Get-Item $cikti).Length/1KB,1) }
  else { Write-Host ("  {0,-26} URETILEMEDI" -f $ad) -ForegroundColor Red }
}

$fav  = [System.IO.File]::ReadAllText((Join-Path $KOK 'favicon.svg'), (New-Object System.Text.UTF8Encoding($false)))
$logo = [System.IO.File]::ReadAllText((Join-Path $KOK 'logo.svg'),    (New-Object System.Text.UTF8Encoding($false)))
$logoIc = $logo -replace '<rect[^>]*/>',''      # kart zemini zaten koyu, rect gereksiz

if(-not $YalnizKart){
  Write-Host "IKONLAR (kaynak: favicon.svg)" -ForegroundColor Cyan
  foreach($b in @(@('apple-touch-icon.png',180), @('icon-192.png',192), @('icon-512.png',512))){
    $ad = $b[0]; $o = $b[1]
    Bas "<!doctype html><html><head><meta charset='utf-8'><style>*{margin:0;padding:0}html,body{width:${o}px;height:${o}px;overflow:hidden}svg{width:${o}px;height:${o}px;display:block}</style></head><body>$fav</body></html>" $ad $o $o
  }
  # Maskable: Android ikonu daireye kirpar. Isaret %72'ye kucultulup ortalanir,
  # zemin kenara kadar dolar (kose yuvarlatmasi YOK - platform kendi kirpar).
  $favMask = $fav -replace '<rect width="64" height="64" rx="14"','<rect width="64" height="64" rx="0"'
  Bas "<!doctype html><html><head><meta charset='utf-8'><style>*{margin:0;padding:0}html,body{width:512px;height:512px;overflow:hidden;background:#1b1a18}.k{width:512px;height:512px;display:grid;place-items:center;background:#1b1a18}svg{width:369px;height:369px;display:block}</style></head><body><div class='k'>$favMask</div></body></html>" 'icon-maskable-512.png' 512 512
}

if(-not $YalnizIkon){
  Write-Host "PAYLASIM KARTLARI (kaynak: logo.svg)" -ForegroundColor Cyan
  $ortak = @"
*{margin:0;padding:0;box-sizing:border-box}
body{width:1200px;height:630px;background:#1b1a18;display:flex;flex-direction:column;justify-content:center;padding:0 96px;
     font-family:"Segoe UI",Inter,system-ui,-apple-system,Arial,sans-serif;color:#fff}
.logo{width:420px;margin-bottom:52px}
h1{font-size:66px;font-weight:800;letter-spacing:-2px;line-height:1.1}
h1 b{color:#ffc24b}
p{margin-top:26px;font-size:29px;color:#b9b2a6;font-weight:500;line-height:1.45;max-width:900px}
.alt{position:absolute;left:96px;bottom:56px;font-size:24px;color:#8a8377;letter-spacing:.3px}
"@
  Bas "<!doctype html><html lang='tr'><head><meta charset='utf-8'><style>$ortak body{background-image:radial-gradient(circle at 12% 42%, rgba(245,165,36,.16), transparent 45%)}</style></head><body><div class='logo'>$logoIc</div><h1>Tetikte olan <b>kaçırmaz.</b></h1><p>Mevzuat değişikliği, ihale ilanı, marka itirazı, sınav sorusu —<br>hepsini senin yerine izleyen sistem.</p><div class='alt'>tetikte.com</div></body></html>" 'og-kapak.png' 1200 630

  $kahramanEk = @"
.logo{width:330px;margin-bottom:46px}
h1{font-size:76px;letter-spacing:-2.4px;line-height:1.05}
.satir{margin-top:30px;display:flex;gap:14px;flex-wrap:wrap}
.et{font-size:24px;font-weight:700;padding:10px 20px;border-radius:999px;
    border:1px solid rgba(245,165,36,.42);color:#ffc24b;background:rgba(245,165,36,.09)}
p{font-size:27px}
"@
  Bas "<!doctype html><html lang='tr'><head><meta charset='utf-8'><style>$ortak $kahramanEk body{background-image:radial-gradient(circle at 88% 22%, rgba(245,165,36,.14), transparent 48%)}</style></head><body><div class='logo'>$logoIc</div><h1>Yanlışını böyle öğrenirsin.</h1><div class='satir'><span class='et'>Tuzağın adı</span><span class='et'>Doğrusu</span><span class='et'>Adım adım çözüm</span><span class='et'>Şimdi sen dene</span></div><p>Cevabı vermekle bitmiyor — fark, ondan sonra başlıyor.</p><div class='alt'>tetikte.com</div></body></html>" 'og-kahraman.png' 1200 630
}

Remove-Item $GEC -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Bitti. Degisen varliklar commit'lenmeli." -ForegroundColor Green
