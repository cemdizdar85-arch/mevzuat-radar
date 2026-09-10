#requires -Version 5.1
<#
================================================================================
  TERİM KEŞFİ — sınav dili ↔ kanun dili AYRIŞMASINI BULUR
  (10.09.2026 — Cem: "SADECE GENEL İDARE / GENEL YÖNETİM GİDERİ BUNU BEN
  GÖRDÜĞÜM, GÖRMEDİKLERİMİZİ SEN ÖLÇ")

  NEDEN YENİ BİR ARAÇ GEREKTİ
  ---------------------------
  Elimizde zaten `veri/TERIM-CIFTLERI.md` var (08.09). Ama o araç bir
  DOĞRULAYICIDIR, keşifçi değil: `veri/terim-adaylari.json`'daki ELLE yazılmış
  24 çifti alır ve "bu çift gerçekten ayrışıyor mu" diye ölçer.

  Kimsenin aklına gelmeyen çifti bulamaz. Cem'in yakaladığı
  "genel idare gideri ↔ genel yönetim gideri" çifti listede vardı — çünkü biri
  onu düşünmüştü. Düşünülmemiş olanlar hâlâ görünmez.

  BU ARAÇ TERS YÖNDEN ÇALIŞIR: aday listesi OKUMAZ. İki külliyatı bağımsız
  tarar, terim sıklıklarını karşılaştırır ve AYRIŞANLARI listeler.

  YÖNTEM
  ------
  A) SINAV KÜLLİYATI  : Supabase `dokumanlar`, tur = cikmis-soru (+komisyon)
  B) KANUN KÜLLİYATI  : yerel `_txt/*.txt` (716 dosya, 30 MB)
  C) Her ikisinde 1-3 kelimelik öbekler sayılır (Türkçe katlanmış, sayı ve
     durak kelimeler atılır)
  D) İki kova raporlanır:
       KOVA 1 — SINAV DİLİ  : sınavda sık, kanunda yok/çok az
                              -> soruda BU terim kullanılmalı
       KOVA 2 — KANUN DİLİ  : kanunda sık, sınavda yok/çok az
                              -> soruda bu terimi kullanmak adayı yabancılaştırır

  ⚠️ BU ARAÇ ÇİFT KURMAZ, ADAY ÜRETİR.
  "genel idare gideri" ile "genel yönetim gideri"nin AYNI ŞEY olduğuna karar
  vermek bilgi ister, sayım değil (bkz. konu-kaynak-eslestirme-yasagi:
  "konudan kanuna gitmek BİLGİ ister, arama değil"). Çıktı Cem'in okuması
  içindir; karar `veri/terim-ciftleri.json`'a elle yazılır.

  KULLANIM
    powershell -NoProfile -File arac/terim-kesif.ps1
    powershell -NoProfile -File arac/terim-kesif.ps1 -Sinav KGK -EnAz 40
================================================================================
#>
param(
  [ValidateSet('HEPSI','SGS','KGK','SMMM')][string]$Sinav = 'HEPSI',
  [int]$EnAz = 25,          # sınavda en az kaç kez geçsin (aday eşiği)
  [int]$Oran = 5,           # ayrışma oranı: sınav >= Oran x kanun
  [int]$BelgeTavan = 400    # kaç çıkmış belge okunsun
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

$KEY = $env:SUPABASE_SERVICE_KEY
if (-not $KEY) { $KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if (-not $KEY) { throw 'SUPABASE_SERVICE_KEY yok.' }
$H  = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function Katla([string]$s) {
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' `
        -creplace 'Â','a' -creplace 'â','a' -creplace 'Î','i' -creplace 'î','i' `
        -creplace 'Û','u' -creplace 'û','u').ToLowerInvariant()
}

# Durak kelimeler: tek başına anlam taşımayanlar. Öbeğin BAŞINDA ya da SONUNDA
# durak varsa öbek atılır (ortada olabilir: "genel yonetim gideri" gibi).
$DURAK = @{}
@('ve','veya','ile','icin','olan','olarak','bu','bir','da','de','ki','ise','ya',
  'gore','uzere','ancak','ayrica','hangi','hangisi','asagidaki','asagidakilerden',
  'yukaridaki','soru','sorulari','kitapcik','oturum','sinav','dogru','yanlis',
  'kac','kactir','nedir','nasil','tl','yil','ay','gun','adet','birim','toplam',
  'olup','olmak','olur','eder','edilir','yapilir','tabi','iliskin','ait','dair',
  'madde','fikra','bent','sayili','kanun','kanunun','kanuna','hukmu','hukumleri'
) | ForEach-Object { $DURAK[$_] = $true }

function ObekCikar([string]$metin) {
  # Katlanmış metinden 1-3 kelimelik öbekleri üretir.
  $k = Katla $metin
  $k = $k -replace '[^a-z0-9\s]', ' '
  $kelimeler = @($k -split '\s+' | Where-Object {
      $_.Length -ge 3 -and $_ -notmatch '^\d' -and -not $DURAK.ContainsKey($_)
  })
  $out = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $kelimeler.Count; $i++) {
    $out.Add($kelimeler[$i]) | Out-Null
    if ($i + 1 -lt $kelimeler.Count) { $out.Add("$($kelimeler[$i]) $($kelimeler[$i+1])") | Out-Null }
    if ($i + 2 -lt $kelimeler.Count) { $out.Add("$($kelimeler[$i]) $($kelimeler[$i+1]) $($kelimeler[$i+2])") | Out-Null }
  }
  return ,$out
}

function SaydirmaEkle([hashtable]$sayac, [string]$metin) {
  foreach ($o in (ObekCikar $metin)) {
    if ($sayac.ContainsKey($o)) { $sayac[$o]++ } else { $sayac[$o] = 1 }
  }
}

# ============================================================================
#  A) SINAV KÜLLİYATI
# ============================================================================
Write-Host "== SINAV KULLIYATI cekiliyor ==" -ForegroundColor Cyan
$suzgec = 'tur=in.(cikmis-soru,cikmis-komisyon-cevabi)'
if ($Sinav -ne 'HEPSI') { $suzgec += "&kaynak_ad=ilike.*$Sinav*" }

$sinavSayac = @{}
$sinavBelge = 0
$sinavKrk   = 0
$adim = 25
for ($off = 0; $off -lt $BelgeTavan; $off += $adim) {
  $u = "$SB`?select=id,kaynak_ad,metin&$suzgec&order=id&limit=$adim&offset=$off"
  try { $r = Invoke-WebRequest -Uri $u -Headers $H -UseBasicParsing -TimeoutSec 180 }
  catch { Write-Host "  ! sayfa $off alinamadi: $($_.Exception.Message)" -ForegroundColor Yellow; continue }

  $satirlar = @(($r.Content | ConvertFrom-Json) | ForEach-Object { $_ })
  if ($satirlar.Count -eq 0) { break }
  foreach ($s in $satirlar) {
    if (-not $s.metin) { continue }
    SaydirmaEkle $sinavSayac $s.metin
    $sinavBelge++; $sinavKrk += $s.metin.Length
  }
  Write-Host ("  {0} belge · {1:N0} karakter" -f $sinavBelge, $sinavKrk)
}

if ($sinavBelge -eq 0) { throw 'Sinav kulliyati BOS geldi - olcum yapilamaz.' }

# ============================================================================
#  B) KANUN KÜLLİYATI  (yerel, bedava)
# ============================================================================
Write-Host "== KANUN KULLIYATI taraniyor ==" -ForegroundColor Cyan
$kanunSayac = @{}
$kanunDosya = 0
$kanunKrk   = 0
foreach ($f in (Get-ChildItem (Join-Path $depoKok '_txt\*.txt'))) {
  $m = Get-Content $f.FullName -Raw -Encoding UTF8
  if (-not $m) { continue }
  SaydirmaEkle $kanunSayac $m
  $kanunDosya++; $kanunKrk += $m.Length
  if ($kanunDosya % 100 -eq 0) { Write-Host ("  {0} dosya · {1:N0} karakter" -f $kanunDosya, $kanunKrk) }
}
Write-Host ("  TOPLAM {0} dosya · {1:N0} karakter" -f $kanunDosya, $kanunKrk)

# ============================================================================
#  C) AYRIŞMA — iki kova
#
#  Sıklıklar farklı büyüklükte külliyatlardan geliyor; ham sayı kıyaslanamaz.
#  Milyon karaktere normalize edilir, karar NORMALIZE oran üzerinden verilir.
# ============================================================================
$sinavMkrk = [math]::Max($sinavKrk / 1e6, 0.000001)
$kanunMkrk = [math]::Max($kanunKrk / 1e6, 0.000001)

$kova1 = New-Object System.Collections.Generic.List[object]   # sinav dili
foreach ($e in $sinavSayac.GetEnumerator()) {
  if ($e.Value -lt $EnAz) { continue }
  $kAdet = 0; if ($kanunSayac.ContainsKey($e.Key)) { $kAdet = $kanunSayac[$e.Key] }
  $sNorm = $e.Value / $sinavMkrk
  $kNorm = $kAdet   / $kanunMkrk
  if ($kNorm -gt 0 -and ($sNorm / $kNorm) -lt $Oran) { continue }
  $kova1.Add([pscustomobject]@{
    terim = $e.Key; sinav = $e.Value; kanun = $kAdet
    sinav_norm = [math]::Round($sNorm,1); kanun_norm = [math]::Round($kNorm,1)
    oran = if ($kNorm -gt 0) { [math]::Round($sNorm/$kNorm,1) } else { 9999 }
  }) | Out-Null
}

$kova2 = New-Object System.Collections.Generic.List[object]   # kanun dili
foreach ($e in $kanunSayac.GetEnumerator()) {
  if ($e.Value -lt ($EnAz * 4)) { continue }   # kanun kulliyati cok daha buyuk
  $sAdet = 0; if ($sinavSayac.ContainsKey($e.Key)) { $sAdet = $sinavSayac[$e.Key] }
  $kNorm = $e.Value / $kanunMkrk
  $sNorm = $sAdet   / $sinavMkrk
  if ($sNorm -gt 0 -and ($kNorm / $sNorm) -lt $Oran) { continue }
  $kova2.Add([pscustomobject]@{
    terim = $e.Key; kanun = $e.Value; sinav = $sAdet
    kanun_norm = [math]::Round($kNorm,1); sinav_norm = [math]::Round($sNorm,1)
    oran = if ($sNorm -gt 0) { [math]::Round($kNorm/$sNorm,1) } else { 9999 }
  }) | Out-Null
}

$k1 = @($kova1 | Sort-Object -Property @{e='sinav_norm';Descending=$true} | Select-Object -First 120)
$k2 = @($kova2 | Sort-Object -Property @{e='kanun_norm';Descending=$true} | Select-Object -First 120)

# ============================================================================
#  D) RAPOR
# ============================================================================
$cikti = [ordered]@{
  olcum      = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  yontem     = 'Aday listesi OKUNMAZ. Iki kulliyat bagimsiz taranir, 1-3 kelimelik obek siklıklari milyon karaktere normalize edilip karsilastirilir.'
  uyari      = 'BU LISTE CIFT KURMAZ, ADAY URETIR. Iki terimin AYNI SEY oldugu karari bilgi ister, sayim degil. Karar veri/terim-ciftleri.json a ELLE yazilir.'
  esikler    = @{ en_az_sinav_gecis = $EnAz; ayrisma_orani = $Oran }
  sinav      = @{ kapsam = $Sinav; belge = $sinavBelge; karakter = $sinavKrk }
  kanun      = @{ dosya = $kanunDosya; karakter = $kanunKrk }
  kova1_sinav_dili = $k1
  kova2_kanun_dili = $k2
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\terim-kesif.json') -Nesne $cikti

Write-Host ""
Write-Host "== KOVA 1 - SINAV DILI (sinavda sik, kanunda yok/az) ==" -ForegroundColor Green
$k1 | Select-Object -First 40 terim, sinav, kanun, oran | Format-Table -AutoSize | Out-String -Width 120
Write-Host "== KOVA 2 - KANUN DILI (kanunda sik, sinavda yok/az) ==" -ForegroundColor Yellow
$k2 | Select-Object -First 40 terim, kanun, sinav, oran | Format-Table -AutoSize | Out-String -Width 120
Write-Host ("ADAY: kova1 {0} · kova2 {1} -> veri/terim-kesif.json" -f $k1.Count, $k2.Count)
