# ============================================================================
#  YEREL INDIRICI (05.08.2026) — Cem'in makinesinde gunde bir kosar. 0 USD.
#
#  NEDEN VAR: mevzuat.gov.tr GitHub runner IP'lerini ENGELLIYOR (05.08 kaniti:
#  runner'dan 6/6 indirme basarisiz, ayni URL'ler Cem'in makinesinden 6/6
#  HTTP 200). Gunluk ayna bu yuzden olum sarmalindaydi: indirmeler timeout'a
#  takila takila 6 saat tavaninda oluyor, _durum hic commit'lenmiyordu.
#
#  COZUM MIMARISI: indirme isi TR-IP'li bu makineye tasindi. Bu betik:
#   1) repo'yu gunceller (pull --rebase)
#   2) manifest'i okur; su kaynaklari indirir:
#      - seyrek OLMAYANLAR (kanunlar + temel yonetmelikler): her gun taze
#      - seyrek olup _durum'da OLMAYANLAR (hic yutulmamis birikim): kosu
#        basina 60 tavanla, birikim gunler icinde erir
#   3) pdftotext ile metne doker, HASH degismediyse dosyaya DOKUNMAZ
#      (bos commit/sisme olmaz)
#   4) degisenleri veri/mevzuat-hazir/'a yazar, commit+push eder
#   5) nabiz dosyasi yazar (kor kalma: robot calisti mi, kac dosya?)
#  Push, mevzuat.yml'yi tetikler (hazir yolu izleniyor); ayna hazir metni
#  indirme YAPMADAN kullanir -> kosu dakikalara iner, sarmal kirilir.
#
#  ZAMANLANMIS GOREV (kurulum bir kez):
#    schtasks /Create /TN "MevzuatRadar-YerelIndirici" /SC DAILY /ST 09:30 ...
#  Elle kosturmak: powershell -File motor\yerel-indirici.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $kok
$logYol = Join-Path $kok '_yerel-indirici-log.txt'   # yerel log (repoya girmez, .gitignore'a eklendi)
function Log([string]$m){ $s = "{0} {1}" -f (Get-Date -Format 'HH:mm:ss'), $m; Write-Host $s; Add-Content -LiteralPath $logYol -Value $s -Encoding UTF8 }
Set-Content -LiteralPath $logYol -Value ("YEREL INDIRICI {0}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm')) -Encoding UTF8

$SEYREK_TAVAN = 60
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$hazirDir = Join-Path $kok 'veri/mevzuat-hazir'
if(-not (Test-Path $hazirDir)){ New-Item -ItemType Directory -Path $hazirDir | Out-Null }
$tmp = Join-Path $env:TEMP 'mevzuat-yerel-indirici'
if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp | Out-Null }

# pdftotext var mi (poppler winget'te kurulu olmali)
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
if($null -eq $pdftotext){ Log "HATA: pdftotext bulunamadi (poppler kurulu degil?)"; exit 1 }

# 30.08.2026 KUSUR (olculdu): bu satir --autostash'siz oldugu icin CALISMA AGACI
# KIRLIYSE DUSUYORDU: "error: cannot pull with rebase: You have unstaged changes".
# 29.08 kosusunun logunda aynen bu var; kosu 21 hatayla ve 0 degisiklikle bitti.
# KILITLENME: robotlar veri dosyasi yazar -> agac kirlenir -> pull duser ->
# hicbir sey commit'lenmez -> agac SUREKLI kirli kalir -> ayna hic tazelenmez.
# --autostash git'in kendi cozumu: kirli degisiklikleri gecici saklar, rebase
# eder, geri koyar. Ayrica dusme artik SESSIZ degil - loga acikca yazilir.
# PULL KALDIRILDI, YERINE FETCH. Indirme isi icin guncel bir CALISMA AGACINA
# ihtiyac yok - manifest zaten diskte, hedef mevzuat.gov.tr. Pull'un tek islevi
# push'u kolaylastirmakti; artik push gecici worktree'den yapiliyor (asagida).
# fetch calisma agacina DOKUNMAZ: ne stash, ne rebase, ne catisma.
try {
  git fetch -q origin 2>&1 | Out-Null
  if($LASTEXITCODE -eq 0){ Log 'git fetch tamam (calisma agacina dokunulmadi)' }
  else { Log "!! git fetch TUTMADI (kod $LASTEXITCODE) - indirmeye devam ediliyor" }
} catch { Log "!! git fetch HATASI: $_ - indirmeye devam ediliyor" }

$manifest = Get-Content (Join-Path $kok 'veri/mevzuat-kaynaklar.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = @{}
try {
  $dj = Get-Content (Join-Path $kok 'veri/mevzuat/_durum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $dj.PSObject.Properties){ $durum[$p.Name] = $true }
} catch {}

function UrlKur($law){
  $pid2 = "$($law.pdfId)"
  if($pid2 -like 'G7:*'){ return "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pid2.Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
  if($pid2 -like 'G9:*'){ return "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($pid2.Substring(3))&mevzuatTur=Teblig&mevzuatTertip=5" }
  return "https://www.mevzuat.gov.tr/MevzuatMetin/$pid2.pdf"
}
function Sha([string]$s){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16) }

$indirilen=0; $degisen=0; $ayni=0; $hata=0; $seyrekYeni=0; $atlanan=0
foreach($law in $manifest.kanunlar){
  $slug = "$($law.slug)"
  # HAZIR = metin depoda elle duruyor (taranmis PDF/mevzuat.gov.tr disi kaynak);
  # indirilecek PDF yok. 05.08: bdkarar11066 bu yuzden "May not be a PDF" yedi.
  if("$($law.pdfId)" -eq 'HAZIR'){ $atlanan++; continue }
  $seyrek = $false; try { $seyrek = ($law.PSObject.Properties['seyrek'] -and $law.seyrek -eq $true) } catch {}
  if($seyrek){
    if($durum.ContainsKey($slug) -and (Get-Date).DayOfWeek -ne 'Sunday'){ $atlanan++; continue }  # yutulmus seyrek: yalniz pazar tazelenir
    $seyrekYeni++
    if($seyrekYeni -gt $SEYREK_TAVAN){ $atlanan++; continue }                                      # birikim gunlere yayilir
  }
  $pdf = Join-Path $tmp "$slug.pdf"; $txt = Join-Path $tmp "$slug.txt"
  try {
    # ------------------------------------------------------------------------
    # 30.08.2026 KUSUR (olculdu): "MevzuatMetin/<tur>.<tertip>.<no>.pdf" kalibi
    # bazi kaynaklarda ARTIK PDF DONDURMUYOR - HTTP 200 + text/html (64 KB
    # site sayfasi). Deponun "yumusak 404" diye adlandirdigi tuzagin aynisi.
    # Somut zarar: yerli-mali-teblig, kik-esik-teblig, kik-genel-teblig,
    # seddk-cbk47 ... 29.08 kosusunda 21 hata / 0 degisen kaynak.
    # Eski kod PDF imzasini HIC kontrol etmiyordu; pdftotext HTML'i okuyup
    # cop uretiyor, sonra "KISA/BOS" deniyor ve kaynak SESSIZCE eskiyordu.
    #
    # IKI ONLEM:
    #  (1) %PDF IMZASI sart. HTML gelirse dosya kabul edilmez.
    #  (2) YEDEK UC: pdfId "<tur>.<tertip>.<no>" kalibindaysa ayni belge
    #      GeneratePdf ucundan istenir. Olculdu - ucu de oradan PDF geldi:
    #      42656 -> YERLI MALI TEBLIGI · 44999 -> KAMU IHALE TEBLIGI 2026/1
    #      13354 -> KAMU IHALE GENEL TEBLIGI
    # ------------------------------------------------------------------------
    function PdfMi([string]$y){
      if(-not (Test-Path $y)){ return $false }
      if((Get-Item $y).Length -lt 1000){ return $false }
      $b = [IO.File]::ReadAllBytes($y)[0..3]
      return ($b[0] -eq 0x25 -and $b[1] -eq 0x50 -and $b[2] -eq 0x44 -and $b[3] -eq 0x46)
    }
    # Yedek uc listesi IKI YONLU (ikisi de olculdu):
    #  A) "<tur>.<tertip>.<no>" kalibi PDF yerine HTML doneriyorsa -> GeneratePdf
    #  B) "G<tur>:<no>" kalibi tanimsiz bir tur tasiyorsa -> MevzuatMetin yolu
    #     Olculdu: seddk-cbk47 pdfId'si G19:47 idi; G19 hicbir dala uymadigi icin
    #     "MevzuatMetin/G19:47.pdf" gibi anlamsiz bir adres kuruluyordu.
    #     Dogrusu MevzuatMetin/19.5.47.pdf -> 233 KB, SEDDK Teskilat CBK'si.
    #     (GeneratePdf o tur icin HTTP 600 "FormValidate" doner - yani o kapi yok.)
    $adresler = @((UrlKur $law))
    $pid3 = "$($law.pdfId)"
    if($pid3 -match '^(\d+)\.(\d+)\.(\d+)$'){
      $turAd = switch($Matches[1]){ '1'{'Kanun'} '7'{'KurumVeKurulusYonetmeligi'} '9'{'Teblig'} default{$null} }
      if($turAd){ $adresler += "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$($Matches[3])&mevzuatTur=$turAd&mevzuatTertip=$($Matches[2])" }
    }
    elseif($pid3 -match '^G(\d+):(\d+)$'){
      $adresler += "https://www.mevzuat.gov.tr/MevzuatMetin/$($Matches[1]).5.$($Matches[2]).pdf"
    }
    $aldi = $false
    foreach($adr in $adresler){
      try { Invoke-WebRequest -Uri $adr -OutFile $pdf -UserAgent $UA -Headers @{ Referer='https://www.mevzuat.gov.tr/' } -TimeoutSec 90 -UseBasicParsing } catch { continue }
      if(PdfMi $pdf){ $aldi = $true; if($adr -ne $adresler[0]){ Log "YEDEK UC kullanildi: $slug" }; break }
      Start-Sleep -Milliseconds 800
    }
    if(-not $aldi){ $hata++; Log "PDF DEGIL (tum uclar denendi): $slug"; continue }
    & pdftotext -enc UTF-8 $pdf $txt 2>$null
    # 30.08.2026 KUSUR (olculdu): esik 2000 BAYT idi ve GERCEK belgeleri
    # reddediyordu. 15 VUK Genel Tebligi bu yuzden hic yutulmadi; olcum:
    #   vukgt590 1886 · vukgt585 757 · vukgt580 1885 · vukgt574 757 ...
    #   vukgt503 850   -> ONBESI DE GECERLI PDF, 757-1948 karakter.
    # Bunlar gercekten kisa tebligler (yeniden degerleme orani vb. bir sayfa).
    # Esik, PDF imza kapisi YOKKEN "HTML geldi mi?" testi gibi kullaniliyordu;
    # artik imza kapisi var, bu esigin tek isi BOS cikarimi yakalamak.
    # 250'ye indirildi; 2000 altindakiler yine de loga yazilir ki gorunur kalsin.
    if(-not (Test-Path $txt)){ $hata++; Log "METIN CIKMADI: $slug"; continue }
    $mLen = (Get-Item $txt).Length
    if($mLen -lt 250){ $hata++; Log "BOS/BOZUK: $slug ($mLen bayt)"; continue }
    if($mLen -lt 2000){ Log "KISA AMA GECERLI: $slug ($mLen bayt)" }
    $indirilen++
    $yeni = Get-Content $txt -Raw -Encoding UTF8
    $hedef = Join-Path $hazirDir "$slug.txt"
    $eskiH = if(Test-Path $hedef){ Sha ((Get-Content $hedef -Raw -Encoding UTF8) -replace '\s+',' ') } else { '' }
    $yeniH = Sha ($yeni -replace '\s+',' ')
    if($yeniH -ne $eskiH){ Set-Content -LiteralPath $hedef -Value $yeni -Encoding UTF8 -NoNewline; $degisen++; Log "DEGISTI: $slug" }
    else { $ayni++ }
  } catch { $hata++; Log "INDIRME HATASI: $slug ($($_.Exception.Message))" }
  Start-Sleep -Milliseconds 1200   # site yagmuru sevmez - kibar aralik
}
Log ("OZET: indirilen={0} degisen={1} ayni={2} hata={3} atlanan={4}" -f $indirilen,$degisen,$ayni,$hata,$atlanan)

# NABIZ (kor kalma): robot bugun calisti mi, sonucu neydi - repoya yazilir
$nabiz = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); makine=$env:COMPUTERNAME
  indirilen=$indirilen; degisen=$degisen; ayni=$ayni; hata=$hata; atlanan=$atlanan
  not='Yerel indirici (Cem makinesi, TR IP). mevzuat.gov.tr GitHub runnerlarini engelledigi icin indirme buradan beslenir.' }
Set-Content -LiteralPath (Join-Path $kok 'veri/yerel-indirici-nabiz.json') -Value (ConvertTo-Json $nabiz -Depth 3) -Encoding UTF8 -NoNewline

# ============================================================================
# 30.08.2026 — YAYIN YOLU BASTAN YAZILDI. Iki olculmus kusur vardi:
#  (1) 'git commit' YOLSUZDU: indekste bekleyen BASKASININ dosyalarini da alip
#      yayina iterdi. Bugun indekste iki sahipsiz SQL dosyasi duruyordu;
#      robotun ilk basarili kosusu onlari PUBLIC depoya basacakti.
#  (2) 'git pull --rebase' kirli agacta DUSUYORDU. 29.08 logu: "cannot pull
#      with rebase: You have unstaged changes" -> kosu 21 hata / 0 degisiklik.
#      Kilitlenme: robot veri yazar -> agac kirlenir -> pull duser -> commit
#      olmaz -> agac hep kirli kalir -> ayna HIC tazelenmez.
#
# NEDEN --autostash ILE COZULMEDI: cozerdi, ama bu agacta 108 degisik dosya
# var ve origin ayni dosyalarin bir kismini bugun degistirdi. Gozetimsiz
# 09:30 kosusunda stash-pop CAKISIRSA dosyalarda catisma isaretleri kalirdi.
# Robot, insanin calisma agacini ASLA riske atmamali.
#
# YENI DESEN (bugun elle kullanilip dogrulandi): ana calisma agacina HIC
# DOKUNMADAN, origin/main uzerinde GECICI WORKTREE acilir, uretilen dosyalar
# oraya kopyalanir, commit+push oradan yapilir, worktree silinir.
# Boylece: stash yok, rebase yok, catisma yok, sizinti yok.
# ============================================================================
$YOLLAR = @('veri/mevzuat-hazir','veri/yerel-indirici-nabiz.json')
$degisiklikVar = $false
foreach($y in $YOLLAR){
  git diff --quiet HEAD -- $y 2>$null
  if($LASTEXITCODE -ne 0){ $degisiklikVar = $true }
  git ls-files --others --exclude-standard -- $y 2>$null | ForEach-Object { $degisiklikVar = $true }
}
if($degisiklikVar){
  $wt = Join-Path $env:TEMP ("yerel-indirici-wt-" + [guid]::NewGuid().ToString('N').Substring(0,8))
  $pushOk = $false
  # 30.08.2026 KUSUR (olculdu, ilk deneme kosusunda): bu blok
  # "!! YAYIN HATASI: warning: ... LF will be replaced by CRLF" ile DUSTU.
  # O bir UYARI, hata degil. Sebep PowerShell 5.1'in yerlesik tuzagi: yerel bir
  # komutun stderr'i "2>&1" ile yakalandiginda her satir bir ErrorRecord'a
  # sarilir; dosya basindaki $ErrorActionPreference='Stop' ile bu TERMINATING
  # hataya donusur. Yani git'in zararsiz satir-sonu uyarisi yayini oldurdu.
  # Iki onlem: (1) blok boyunca EAP 'Continue', (2) "2>&1" kaldirildi.
  $eskiEAP = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    git fetch -q origin | Out-Null
    git worktree add -q --detach $wt origin/main | Out-Null
    if(-not (Test-Path $wt)){ throw 'worktree acilamadi' }
    foreach($y in $YOLLAR){
      $kaynakY = Join-Path $kok $y
      if(-not (Test-Path $kaynakY)){ continue }
      $hedefY  = Join-Path $wt $y
      if((Get-Item $kaynakY).PSIsContainer){
        if(-not (Test-Path $hedefY)){ New-Item -ItemType Directory -Path $hedefY -Force | Out-Null }
        Copy-Item (Join-Path $kaynakY '*') $hedefY -Recurse -Force
      } else {
        $ust = Split-Path -Parent $hedefY
        if(-not (Test-Path $ust)){ New-Item -ItemType Directory -Path $ust -Force | Out-Null }
        Copy-Item $kaynakY $hedefY -Force
      }
    }
    Push-Location $wt
    try {
      git add -- $YOLLAR | Out-Null
      git diff --cached --quiet -- $YOLLAR
      if($LASTEXITCODE -ne 0){
        git commit -q -m "Yerel indirici: $degisen kaynak guncellendi [veri-operasyonu]" -- $YOLLAR | Out-Null
        foreach($i in 1..3){
          git push -q origin HEAD:main | Out-Null
          if($LASTEXITCODE -eq 0){ $pushOk = $true; break }
          git fetch -q origin | Out-Null
          git rebase -q origin/main | Out-Null   # worktree TEMIZ: catisma riski yok
          Start-Sleep -Seconds 5
        }
      } else { $pushOk = $true; Log 'worktree ile uzak ayni - push gerekmedi' }
    } finally { Pop-Location }
  } catch {
    Log "!! YAYIN HATASI: $($_.Exception.Message)"
  } finally {
    try { git worktree remove --force $wt | Out-Null; git worktree prune | Out-Null } catch {}
    $ErrorActionPreference = $eskiEAP
  }
  if($pushOk){ Log "PUSH tamam ($degisen degisiklik) - ayna tetiklenecek" } else { Log '!! PUSH TUTMADI'; exit 1 }
} else { Log 'degisiklik yok - push edilmedi' }

# ---------------------------------------------------------------------------
# 13.08 YANVERI NOBETI (Cem: "yan verilerin otomatik onarimi"): damping listesi
# + Ithalat Gn.Md. duyuru sinyali. TR-IP'li bu makineden gunde bir; degisiklik
# yoksa sessiz cikar (K2), varsa 5 kapili onarim + "DEGISTIRDIM" maili.
# ---------------------------------------------------------------------------
try { & (Join-Path $kok 'motor\yanveri-onarici.ps1') -Kaynak damping -Uygula } catch { Log ("yanveri damping: " + $_.Exception.Message) }
try { & (Join-Path $kok 'motor\yanveri-onarici.ps1') -DuyuruSinyal } catch { Log ("yanveri duyuru: " + $_.Exception.Message) }

# ---------------------------------------------------------------------------
# 24.08 KURUL KARARI NOBETCISI (Cem: "nobetciyi gunluk goreve bagla"): ambar
# yalniz manifestteki kanun/yonetmelik/tebligi izliyordu; KURUL KARARLARI
# mevzuat.gov.tr fihristinde HIC yok (tur adi HTTP 600, sayisal turler 0 kayit).
# Nobetci RG fihristini tarar, gorulmemis KGK/SPK/BDDK/SEDDK/TCMB kararlarini
# veri/kurul-karari-raporu.json a yazar. KANIT: ilk kosu TSRS 2 sera gazi ve
# TMS 28 degisikliklerini yakaladi - ikisi de bir aydir gozden kacmisti.
# 7 gunluk pencere gunluk kosu icin yeterli; YUTMA ELLE (taranmis PDF olabilir).
# ---------------------------------------------------------------------------
try { & (Join-Path $kok 'motor\kurul-karari-hasat.ps1') -Gun 7 -Yaz } catch { Log ('kurul karari nobetcisi: ' + $_.Exception.Message) }
