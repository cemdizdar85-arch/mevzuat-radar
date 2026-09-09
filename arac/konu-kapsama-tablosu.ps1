# KONU KAPSAMA TABLOSU (10.09.2026) — 0 USD, model çağrısı yok, ağ çağrısı yok.
#
# Cem 10.09: "ders, o dersin konusu, sınavda çıkmış soru sayısı ve yanına bizim şu an
# oluşturduğumuz soru" · "sınavda kaç kere çıktığını istemiştim" · "o soruları dikkate alma,
# daha önce bastığımız değil, bizim en son yazdıklarımızı dikkate alarak bak".
#
# Sütunlar:
#   1) SINAVDA CIKAN SORU : konunun pencerede kaç SORU olarak çıktığı
#                           (veri/sgs-analiz.json → donemler[].konuSayim; gerçek sayım)
#   2) CIKTIGI DONEM      : kaç ayrı sınavda çıktığı
#   3) YAZDIK             : parti dosyalarında o konuya yazılmış soru (veri/fabrika/kalip-parti-*.json)
#   4) YAYINLANABILIR     : bunların kaçı dört kapıdan geçti (hakem ∧ kör ∧ hakem2 ∧ sim)
#   5) DURUM              : YETER / EKSIK / FAZLA — yayınlanabilir sayısı hedefe göre
#
# HEDEF: konu başına sınavda çıkan soru sayısının 3 katı (plan formülü A: her konu 3 × kez).
#
# İKİ ÖNEMLİ NOT
#   - Eski havuz (Temmuz-Ağustos kota-v2 basımı, 15.827 soru) bu tabloya GİRMEZ. Cem'in kararı:
#     "o soruları dikkate alma". Sayılan tek şey parti dosyalarındaki kendi yazdıklarımızdır.
#   - Eşleşme konu adının birebir kendisiyle yapılır (Türkçe katlanmış hâliyle). Kök eşleşmesi
#     kullanılmaz, çünkü bir soruyu birden çok konuya sayıp tabloyu şişiriyordu.
#
# TUZAK KAYDI: PS 5.1'de @(ConvertFrom-Json ...) çok elemanlı diziyi 1 sayar.
#              Doğrusu: @((ConvertFrom-Json -InputObject $m) | ForEach-Object { $_ })
#
# Kullanım:
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kapsama-tablosu.ps1 -DonemPencere 10
#
# Çıktı: veri/fabrika/konu-kapsama.csv + ekrana ders özeti ve en büyük eksikler.

param([int]$DonemPencere=7, [string]$Ders='', [int]$HedefKat=3, [switch]$Sessiz)
$ErrorActionPreference='Stop'
$kok = Split-Path $PSScriptRoot -Parent

function Katla2([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
function KokOnek([string]$s){
  $t=(Katla2 $s) -replace '[^a-z0-9 ]',' '
  $es=@{ 'evre'='safha'; 'gug'='genel'; 'ilk'='ilk'; 'dimm'='ilk'; 'esdeger'='esdeger' }
  @(($t -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|ile|veya|icin|bir|olan|sistemi|yontemi|sistem|yontem|hesaplama|hesabi|kaydi|kayit|analizi|analiz|orani|oran|tablosu|tablo|muhasebesi|muhasebe)$' } | ForEach-Object { $w=$_; if($es.ContainsKey($w)){ $w=$es[$w] }; if($w.Length -gt 5){ $w.Substring(0,5) } else { $w } } | Select-Object -Unique)
}

# --- 1) sinavda kac soru cikti (donem donem gercek sayim) ---
$anYol = Join-Path $kok 'veri\sgs-analiz.json'
if(-not (Test-Path $anYol)){ Write-Host "veri/sgs-analiz.json yok - olculemez." -ForegroundColor Red; exit 1 }
$an = ConvertFrom-Json -InputObject (Get-Content $anYol -Raw -Encoding UTF8)
$dList = New-Object System.Collections.Generic.List[object]
$an.donemler | ForEach-Object { $dList.Add($_) }
$sonD = @($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $DonemPencere)

$etiket = @{}
foreach($dn in $sonD){
  foreach($p in @($dn.konuSayim.PSObject.Properties)){
    $bol = ($p.Name -split '\|')[0]
    $lab = ($p.Name -replace '^[^|]*\|','')
    $kk  = (KokOnek $lab) -join ' '
    if(-not $kk){ continue }
    if(-not $etiket.ContainsKey($kk)){ $etiket[$kk]=@{ ad=$lab; bolum=$bol; donemler=@{}; soru=0; adlar=@{} } }
    $etiket[$kk].donemler["$($dn.donem)"] = 1
    $etiket[$kk].soru += [int]$p.Value
    $etiket[$kk].adlar[(Katla2 $lab)] = 1
  }
}
$pencereAd = (@($sonD | ForEach-Object { $_.donem }) -join ' ')
if(-not $Sessiz){ Write-Host ("sinav analizi: pencere ({0} donem) {1} | konu {2}" -f $DonemPencere, $pencereAd, $etiket.Count) }

# --- 2) BIZIM YAZDIKLARIMIZ: parti dosyalari ---
$yazdik = @{}; $yayin = @{}
$partiler = @(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-*.json' -ErrorAction SilentlyContinue)
$okunan = 0; $toplamSoru = 0; $toplamYayin = 0
foreach($f in $partiler){
  try { $j = ConvertFrom-Json -InputObject (Get-Content $f.FullName -Raw -Encoding UTF8) } catch { continue }
  $okunan++
  foreach($pr in $j.PSObject.Properties){
    if($pr.Name -notmatch '^kp-\d+$'){ continue }
    $v = $pr.Value
    if(-not $v.soru -or -not $v.konu){ continue }
    $ka = Katla2 "$($v.konu)"
    if(-not $yazdik.ContainsKey($ka)){ $yazdik[$ka]=0; $yayin[$ka]=0 }
    $yazdik[$ka]++; $toplamSoru++
    $h = "$($v.hakem.karar)"
    $kor = ($v.kor_cozum -and [bool]$v.kor_cozum.dogru_mu)
    $h2 = "$($v.hakem2.karar)"
    $simOk = -not ($v.simulasyon_sonnet -and -not [bool]$v.simulasyon_sonnet.dogru_mu)
    if($h -eq 'EVET' -and $kor -and $h2 -eq 'EVET' -and $simOk){ $yayin[$ka]++; $toplamYayin++ }
  }
}
if(-not $Sessiz){ Write-Host ("parti dosyasi: {0} okundu | bizim yazdigimiz {1} soru, yayinlanabilir {2}" -f $okunan, $toplamSoru, $toplamYayin) }

# --- 3) ders adi: huninin etiketDers haritasindan (yalniz ETIKET icin, sayim icin degil) ---
# Analiz dosyasindaki 'bolum' arsiv basligidir (Muhasebe, Hukuk...). Cem'in tablosunda gercek
# ders adi lazim (Finansal Muhasebe, Maliyet Muhasebesi...). Huni bu esleme icin okunur.
$dersAd = @{}
$huniYol = (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
if($huniYol){
  $h = ConvertFrom-Json -InputObject (Get-Content $huniYol.FullName -Raw -Encoding UTF8)
  foreach($p in $h.etiketDers.PSObject.Properties){ $dersAd[$p.Name] = ("$($p.Value)" -replace '\*$','') }
}

# --- 4) birlestir ---
$satirlar = New-Object System.Collections.Generic.List[object]
foreach($kk in $etiket.Keys){
  $ad = $etiket[$kk].ad
  $ders = ''
  foreach($a in $etiket[$kk].adlar.Keys){ if($dersAd.ContainsKey($a) -and $dersAd[$a]){ $ders = $dersAd[$a]; break } }
  if(-not $ders){ $ders = "[$($etiket[$kk].bolum)]" }
  if($Ders -and $ders -notmatch $Ders){ continue }
  $y = 0; $yy = 0
  foreach($a in $etiket[$kk].adlar.Keys){
    if($yazdik.ContainsKey($a)){ $y += $yazdik[$a]; $yy += $yayin[$a] }
  }
  $cikan = [int]$etiket[$kk].soru
  $hedef = $cikan * $HedefKat
  $durum = $(if($yy -ge $hedef){ 'YETER' } elseif($yy -eq 0){ 'HIC YOK' } else { 'EKSIK' })
  $satirlar.Add([pscustomobject]@{
    ders          = $ders
    konu          = $ad
    sinavda_cikan = $cikan
    ciktigi_donem = $etiket[$kk].donemler.Count
    hedef         = $hedef
    yazdik        = $y
    yayinlanabilir= $yy
    durum         = $durum
  })
}
$sirali = @($satirlar | Sort-Object @{Expression='sinavda_cikan'; Descending=$true}, ders, konu)

$csv = Join-Path $kok 'veri\fabrika\konu-kapsama.csv'
$sirali | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("CSV yazildi: {0} ({1} satir)" -f $csv, $sirali.Count) -ForegroundColor Green

# --- 4) ders ozeti ---
Write-Host ""
Write-Host ("{0,-26} {1,5} {2,7} {3,7} {4,7} {5,7} {6,7}" -f 'DERS','konu','cikan','hedef','yazdik','yayin','hicyok')
Write-Host ("-" * 74)
foreach($g in ($sirali | Group-Object ders | Sort-Object { -($_.Group | Measure-Object -Property sinavda_cikan -Sum).Sum })){
  $ck = ($g.Group | Measure-Object -Property sinavda_cikan  -Sum).Sum
  $hd = ($g.Group | Measure-Object -Property hedef          -Sum).Sum
  $yz = ($g.Group | Measure-Object -Property yazdik         -Sum).Sum
  $yy = ($g.Group | Measure-Object -Property yayinlanabilir -Sum).Sum
  $hy = @($g.Group | Where-Object { $_.yayinlanabilir -eq 0 }).Count
  Write-Host ("{0,-26} {1,5} {2,7} {3,7} {4,7} {5,7} {6,7}" -f $g.Name, $g.Count, $ck, $hd, $yz, $yy, $hy)
}
Write-Host ("-" * 74)
Write-Host ("{0,-26} {1,5} {2,7} {3,7} {4,7} {5,7} {6,7}" -f 'TOPLAM', $sirali.Count,
  ($sirali | Measure-Object -Property sinavda_cikan  -Sum).Sum,
  ($sirali | Measure-Object -Property hedef          -Sum).Sum,
  ($sirali | Measure-Object -Property yazdik         -Sum).Sum,
  ($sirali | Measure-Object -Property yayinlanabilir -Sum).Sum,
  @($sirali | Where-Object { $_.yayinlanabilir -eq 0 }).Count)

# --- 5) en buyuk eksikler ---
Write-Host ""
Write-Host ("EN BUYUK EKSIKLER (cok cikip yayinlanabilir sorusu az olan 20 konu):")
foreach($x in (@($sirali | Where-Object { $_.yayinlanabilir -lt $_.hedef }) | Sort-Object @{Expression='sinavda_cikan'; Descending=$true} | Select-Object -First 20)){
  Write-Host ("  {0,-22} {1,-36} cikan {2,2} · hedef {3,2} · yayin {4,3}" -f $x.ders, $x.konu, $x.sinavda_cikan, $x.hedef, $x.yayinlanabilir)
}
