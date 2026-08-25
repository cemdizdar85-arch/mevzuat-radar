# ============================================================================
#  TEBLİĞ DAMGASI — gözetim tebliğleri değişti mi?   (PARA HARCAMAZ)
#
#  Cem (29.07): "bunu zaten biz sistemde yok mu, Resmî Gazete her gün iniyor,
#  indirebildiklerimizi indirip kontrol sağlayabiliriz."
#  Haklıydı — mekanizma zaten vardı, EKSİK OLAN KAPSAMDI. `mevzuat-yut.ps1`
#  her gün mevzuat.gov.tr'den konsolide PDF indirip hash'liyor; ama listesinde
#  yalnız KANUNLAR var. GTİP aracının kalbi olan 43 gözetim TEBLİĞİ o listeye
#  hiç girmemişti — bu yüzden 11.07'den beri değişip değişmediklerini kimse
#  bilmiyordu.
#
#  İKİ İŞİ AYIRIYORUM (önemli):
#    TESPİT   — tebliğ değişti mi?  → hash, BEDAVA, bu betik
#    AYRIŞTIRMA — tablodaki GTİP/kıymet → API gerekir (tablo-hasat.ps1)
#  Tespit her gün koşar; ayrıştırma yalnız değişiklik varsa ve API açıkken.
#  Böylece "veri eskidi ama kimse bilmiyor" hâli biter.
#
#  TEBLİĞ LİSTESİ UYDURULMUYOR: veri/gtip-durum.json'un kendi kayıtlarındaki
#  kaynak adreslerinden (MevzuatNo=NNNNN) okunur. Yani izlenen küme, aracın
#  fiilen dayandığı kümeyle BİREBİR aynı — biri diğerinden sapamaz.
#
#  Çıktı: veri/teblig-damga.json (hash tablosu) + değişen varsa exit 1
#  NOT: mevzuat.gov.tr çıplak curl'e 403 veriyor, tarayıcı User-Agent şart.
#
#  ---------------------------------------------------------------------------
#  25.08.2026 — ÖLÇÜM KAPISI EKLENDİ. 38 GÜNLÜK YALAN KIRMIZI BURADAN ÇIKTI.
#
#  Bulgu: mevzuat.yml 18.07'den beri 164 koşu üst üste kırmızı bitti. Düşen
#  adım hep bu betiğin kapısıydı: "76 tebliğ değişti". Ölçüm:
#    - 76'nın 75'inde eski_boyut = yeni_boyut = 60.487 bayt. Birbirinden
#      farklı 75 tebliğin aynı bayta düşmesi imkânsız.
#    - URL Cem'in makinesinden (TR IP) çekildi: HTTP 200 ama
#      Content-Type: text/html, gövde "Mevzuat Bilgi Sistemi" ANA SAYFASI.
#      Yani IP engeli değil — bu URL kalıbı ÖLMÜŞ (yumuşak 404).
#    - Aynı URL arka arkaya iki kez çekildi: aynı 60.487 bayt, FARKLI hash
#      (79C5AE0B… / 59193566…). Sayfa her çekilişte değişen jeton taşıyor.
#  Sonuç: betik her koşuda "75 tebliğ değişti" diyordu. Kapı sonsuz kırmızı.
#
#  Asıl bedel "kırmızı koşu" değil: kapı kurt masalı anlatıyordu. GERÇEK bir
#  gözetim tebliği değişse 75 hayaletin içinde görünmezdi.
#
#  Tek kapı `$bayt.Length -lt 2000` idi; 60 KB'lık HTML oradan rahat geçiyordu.
#  Artık İÇERİĞE bakılıyor: gövde PDF değilse o kayıt "ÖLÇÜLEMEDİ" sayılır —
#  "DEĞİŞTİ" SAYILMAZ. Ölçemediğine kusur deme.
#
#  ÜÇ DAVRANIŞ AYRI:
#    değişti      -> exit 1  KIRMIZI (gerçek sinyal; gtip-durum.json eskidi)
#    ölçülemedi   -> exit 3  KÖR     (veri eskimiş olabilir de olmayabilir de;
#                                     kırmızı DEĞİL ama sessiz de değil)
#    temiz        -> exit 0
#  Ölçülemeyenin eski damgası KORUNUR — kayıt izlemeden düşmesin, URL onarılınca
#  karşılaştırma kaldığı yerden devam etsin.
# ============================================================================
param(
  # Yalnız deneme için: ilk N tebliği ölç (172 isteklik yağmuru başlatmadan
  # kapının çalıştığını görmek için). 0 = hepsi.
  [int]$Sinir = 0
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/teblig-damga-log.txt') -Force | Out-Null } catch {}

$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
$durumYol = Join-Path $kok 'veri/gtip-durum.json'
$damgaYol = Join-Path $kok 'veri/teblig-damga.json'

if(-not (Test-Path $durumYol)){ Write-Host "gtip-durum.json yok - atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

# --- izlenecek teblig kumesi: ARACIN KENDI VERISINDEN
$ham = [IO.File]::ReadAllText($durumYol, [Text.Encoding]::UTF8)
$noSet = @{}
foreach($m in [regex]::Matches($ham, 'MevzuatNo=(\d+)')){ $noSet[$m.Groups[1].Value] = 1 }
# TÜR/TERTİP DE VERİDEN OKUNUR, KODA GÖMÜLMEZ (25.08). Eski hâl "9.5." önekini
# sabit yazıyordu; bugün 172 kaydın hepsi 9/5 ama yarın bir kayıt farklı türle
# gelirse sabit önek onu sessizce ölçemez hâle sokardı.
$turHarita = @{}
foreach($m in [regex]::Matches($ham, 'MevzuatNo=(\d+)\\u0026MevzuatTur=(\d+)\\u0026MevzuatTertip=(\d+)')){
  $turHarita[$m.Groups[1].Value] = @{ tur=$m.Groups[2].Value; tertip=$m.Groups[3].Value }
}
$tebSet = @{}
foreach($m in [regex]::Matches($ham, '"teblig":\s*"([^"]+)"')){ $tebSet[$m.Groups[1].Value] = 1 }
$nolar = @($noSet.Keys | Sort-Object { [int]$_ })
Write-Host ("Izlenecek teblig: {0} mevzuatNo  ({1} teblig no)" -f $nolar.Count, $tebSet.Count)
if($nolar.Count -eq 0){ Write-Host "Kaynak adresi bulunamadi - atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

$eski = @{}
$ilkKurulum = -not (Test-Path $damgaYol)
if(-not $ilkKurulum){
  try {
    $e = Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($p in $e.tebligler.PSObject.Properties){ $eski[$p.Name] = $p.Value }
  } catch { $ilkKurulum = $true }
}

function Damga([byte[]]$b){
  $sha = [Security.Cryptography.SHA256]::Create()
  return (($sha.ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0,16)
}

# ÖLÇÜM KAPISI: elimizdeki gövde gerçekten PDF mi?
# mevzuat.gov.tr ölü adreslere HTTP 200 + ana sayfa HTML'i döndürüyor (yumuşak
# 404). O sayfa her çekilişte değişen jeton taşıdığı için hash'i her koşuda
# farklı çıkar ve "tebliğ değişti" sanılır. İki bağımsız işaret aranır:
# içerik türü ve dosyanın kendi imzası (%PDF). İkisinden biri bile HTML derse
# bu bir ÖLÇÜM DEĞİLDİR.
function PdfMi([byte[]]$b, [string]$ctype){
  if($ctype -match 'html'){ return $false }
  if($b.Length -lt 5){ return $false }
  # %PDF = 0x25 0x50 0x44 0x46
  return ($b[0] -eq 0x25 -and $b[1] -eq 0x50 -and $b[2] -eq 0x44 -and $b[3] -eq 0x46)
}

# ---------------------------------------------------------------------------
# 25.08 — PARMAK İZİ ARTIK BAYTTAN DEĞİL, METİNDEN ALINIYOR.
#
# Kör kalan 76 tebliğin doğru ucu bulundu: File/GeneratePdf. Ama o uç PDF'i
# İSTEK ANINDA üretiyor ve içine üretim saatini gömüyor:
#     /CreationDate (D:20260825124656+03'00')
# Ölçtüm — aynı URL, üç ardışık çekim:
#     BAYT hash : DACA104D… / 31B59688… / 74CEB613…   (üçü de farklı!)
#     METİN hash: F37E83C5… / F37E83C5… / F37E83C5…   (üçü de aynı, 7.167 bayt)
# Yani sadece URL'i düzeltseydik, az önce kapattığımız yalan kırmızı YENİ
# KILIKTA geri gelirdi — bu kez 172 kaydın hepsinde. Baytı değil METNİ
# damgalıyoruz; zaten sorumuz da "tebliğin METNİ değişti mi?".
#
# pdftotext yoksa bu bir ölçüm değildir -> KÖR sayılır, "değişti" sayılmaz.
# (İş akışında poppler-utils 3. adımda kuruluyor, bu betik 8. adımda koşuyor.)
# ---------------------------------------------------------------------------
$script:pdftotextVar = [bool](Get-Command pdftotext -ErrorAction SilentlyContinue)
function MetniCikar([byte[]]$b){
  if(-not $script:pdftotextVar){ return $null }
  $ge = [IO.Path]::GetTempFileName()
  $pdf = "$ge.pdf"; $txt = "$ge.txt"
  try {
    [IO.File]::WriteAllBytes($pdf, $b)
    & pdftotext -enc UTF-8 -q $pdf $txt 2>$null
    if(-not (Test-Path $txt)){ return $null }
    $t = [IO.File]::ReadAllBytes($txt)
    # Boş/çöp çıktı da ölçüm değildir (taranmış görüntü PDF'i böyle davranır).
    if($t.Length -lt 200){ return $null }
    return $t
  } catch { return $null }
  finally { foreach($f in @($ge,$pdf,$txt)){ if(Test-Path $f){ Remove-Item $f -Force -ErrorAction SilentlyContinue } } }
}

$yeniTablo = [ordered]@{}
$degisen = New-Object System.Collections.Generic.List[object]
$inemeyen = New-Object System.Collections.Generic.List[string]
$olculemeyen = New-Object System.Collections.Generic.List[object]
if($Sinir -gt 0 -and $Sinir -lt $nolar.Count){
  Write-Host ("DENEME MODU: yalniz ilk {0} teblig olculuyor (dosya YAZILMAZ)." -f $Sinir)
  $nolar = @($nolar | Select-Object -First $Sinir)
}
$sayac = 0
foreach($no in $nolar){
  $sayac++
  $tur    = if($turHarita.ContainsKey($no)){ $turHarita[$no].tur }    else { '9' }
  $tertip = if($turHarita.ContainsKey($no)){ $turHarita[$no].tertip } else { '5' }
  $url = "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$no&mevzuatTur=$tur&mevzuatTertip=$tertip"
  # Sunucuya seri yagmuru yagdirma (03.08 dersi: mevzuat.gov.tr seri istegi kesiyor).
  if($sayac -gt 1){ Start-Sleep -Milliseconds 700 }
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri $url -UserAgent $UA -TimeoutSec 60
    $bayt = if($r.Content -is [byte[]]){ $r.Content } else { [Text.Encoding]::UTF8.GetBytes("$($r.Content)") }
    $ctype = "$($r.Headers['Content-Type'])"
    if($bayt.Length -lt 2000){ $inemeyen.Add("$no (govde cok kucuk: $($bayt.Length) bayt)"); continue }
    # --- ÖLÇÜM KAPISI 1: gelen sey PDF mi? ---
    if(-not (PdfMi $bayt $ctype)){
      $bas = ''
      try { $bas = ([Text.Encoding]::ASCII.GetString($bayt[0..([Math]::Min(40,$bayt.Length-1))]) -replace '[\r\n]',' ').Trim() } catch {}
      $olculemeyen.Add([ordered]@{ mevzuatNo=$no; sebep='PDF gelmedi'; ctype=$ctype; boyut=$bayt.Length; bas=$bas; url=$url })
      if($eski.ContainsKey($no)){ $yeniTablo[$no] = $eski[$no] }
      continue
    }
    # --- ÖLÇÜM KAPISI 2: metni cikarabildik mi? ---
    $metin = MetniCikar $bayt
    if($null -eq $metin){
      $sebep = if($script:pdftotextVar){ 'metin cikarilamadi (taranmis goruntu olabilir)' } else { 'pdftotext yok' }
      $olculemeyen.Add([ordered]@{ mevzuatNo=$no; sebep=$sebep; ctype=$ctype; boyut=$bayt.Length; bas='%PDF'; url=$url })
      # Eski damgayı KORU: kayıt izlemeden düşmesin, URL onarılınca karşılaştırma
      # SON GERÇEK ölçümden devam etsin. Yeni damga YAZILMAZ - çünkü ölçüm yok.
      if($eski.ContainsKey($no)){ $yeniTablo[$no] = $eski[$no] }
      continue
    }
    # DAMGA METİNDEN alınır (bayttan DEĞİL) - GeneratePdf her çekilişte farklı
    # bayt üretiyor, metin ise sabit. Boyut da metin boyutudur.
    $d = Damga $metin
    $yeniTablo[$no] = [ordered]@{ damga=$d; boyut=$metin.Length; pdf_boyut=$bayt.Length
                                  kontrol=(Get-Date -Format 'dd.MM.yyyy HH:mm'); olcum='metin' }
    # GEÇİŞ TUZAĞI KAPATILDI (25.08): karşılaştırma yalnız eski kayıt da AYNI
    # YÖNTEMLE (metin damgası) alınmışsa yapılır. Depodaki eski damgalar iki
    # ayrı gürültü kuşağından geliyor: (a) 18.07-25.08 arası HTML ana sayfanın
    # hash'i, (b) bayt-hash dönemi. İkisiyle de kıyaslamak ilk düzgün koşuda
    # 172 kaydın hepsini "değişti" diye yakardı. Yöntem bayrağı taşımayan
    # kayıt SESSİZCE yeniden temellenir; karşılaştırma ikinci koşudan başlar.
    # Bir gün geç, ama yalan değil.
    $eskiGercek = ($eski.ContainsKey($no) -and "$($eski[$no].olcum)" -eq 'metin')
    if(-not $ilkKurulum -and $eskiGercek -and "$($eski[$no].damga)" -ne $d){
      $degisen.Add([ordered]@{ mevzuatNo=$no; eski="$($eski[$no].damga)"; yeni=$d
                               eski_boyut=[int]"$($eski[$no].boyut)"; yeni_boyut=$bayt.Length; url=$url })
    }
  } catch {
    $inemeyen.Add("$no ($($_.Exception.Message))")
  }
  if($sayac % 10 -eq 0){ Write-Host ("  ...{0}/{1}" -f $sayac, $nolar.Count) }
}

$olculen = $nolar.Count - $olculemeyen.Count - $inemeyen.Count
Write-Host ("  gercekten olculen (PDF geldi) : {0}" -f $olculen)
Write-Host ("  OLCULEMEDI (PDF gelmedi)      : {0}" -f $olculemeyen.Count)
Write-Host ("  inemeyen (istek dustu)        : {0}" -f $inemeyen.Count)
foreach($x in ($olculemeyen | Select-Object -First 5)){
  Write-Host ("     {0}  ctype={1}  {2} bayt  bas='{3}'" -f $x.mevzuatNo, $x.ctype, $x.boyut, $x.bas)
}
foreach($x in ($inemeyen | Select-Object -First 5)){ Write-Host ("     {0}" -f $x) }

if($Sinir -gt 0){
  Write-Host ""
  Write-Host "DENEME MODU: damga dosyasi YAZILMADI, kapi karari verilmedi."
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

$cikti = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Gozetim tebliglerinin konsolide PDF parmak izi. Degisen teblig = veri/gtip-durum.json ESKIMIS demektir; tablo-hasat.ps1 yeniden kosmali (API gerekir)."
  ilk_kurulum = $ilkKurulum
  izlenen = $yeniTablo.Count
  # 25.08: 'olculen' = govdesi gercekten PDF gelip hash'lenen sayi.
  # 'olculemeyen' = HTTP 200 geldi ama PDF degil (yumusak 404 / HTML).
  # Bu ikisi AYRI tutulur; olculemeyen ASLA 'degisen' sayilmaz.
  olculen = $olculen
  olculemeyen = $olculemeyen
  inemeyen = $inemeyen
  degisen = $degisen
  tebligler = $yeniTablo
}
[IO.File]::WriteAllText($damgaYol, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> veri/teblig-damga.json" )

if($ilkKurulum){
  Write-Host ""
  Write-Host ("ILK KURULUM: {0} teblig damgalandi. Karsilastirma bir sonraki kosudan itibaren." -f $yeniTablo.Count)
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}
if($degisen.Count -eq 0){
  Write-Host ""
  if($olculemeyen.Count -gt 0){
    # KÖR HÂL. "Değişen yok" demek YETMEZ - çünkü bakamadığımız kayıtlar var.
    # Bu kırmızı DEĞİL (veri eskimiş olabilir de olmayabilir de; bilmiyoruz),
    # ama sessiz de değil: yeşil koşu "her sey yolunda" diye okunur.
    Write-Host "======================================================================"
    Write-Host ("  KOR: {0}/{1} teblig OLCULEMEDI - govde PDF degil (yumusak 404)." -f $olculemeyen.Count, $nolar.Count)
    Write-Host "======================================================================"
    Write-Host ("  Gercekten olculen ve degismeyen: {0}" -f $olculen)
    Write-Host ""
    Write-Host "  Bu kayitlar icin 'degismedi' DENEMEZ - bakilamadi. Kok sebep"
    Write-Host "  URL kalibidir; MevzuatMetin/yonetmelik/9.5.<no>.pdf ucu ana sayfa"
    Write-Host "  donduruyor. Dogru uc bulunana kadar gozetim verisi DENETIMSIZ."
    Write-Host "  Ayrinti: veri/teblig-damga.json -> olculemeyen"
    try{Stop-Transcript|Out-Null}catch{}
    exit 3
  }
  Write-Host ("TEMIZ: olculen {0} tebligin hicbiri degismemis - gtip-durum.json guncel." -f $olculen)
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

Write-Host ""
Write-Host "======================================================================"
Write-Host ("  {0} GOZETIM TEBLIGI DEGISTI - veri/gtip-durum.json ESKIDI" -f $degisen.Count)
Write-Host "======================================================================"
foreach($d in $degisen){
  Write-Host ("  mevzuatNo {0}  ({1} -> {2} bayt)" -f $d.mevzuatNo, $d.eski_boyut, $d.yeni_boyut)
  Write-Host ("     {0}" -f $d.url)
}
Write-Host ""
Write-Host "  YAPILACAK: tablo-hasat.ps1 yeniden kosmali (API gerekir - tablolari"
Write-Host "  modele okutuyor). O kosana kadar GTIP aracindaki gozetim verisi"
Write-Host "  ESKIDIR; arac zaten hasat tarihini ekranda gosteriyor."
Write-Host "  KOSU BILEREK KIRMIZI: sessiz rapor okunmaz."
try{Stop-Transcript|Out-Null}catch{}
exit 1
