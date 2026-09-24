#requires -Version 5.1
<#
================================================================================
  SMMM DALGA DÖNGÜSÜ — tablo · Excel · plan · KONU DENETİMİ   23.09.2026 · bedel 0

  Cem 23.09: "bittikçe kontrol edip tekrar tekrar basalım" + "excel güncellenecek ve
  yanlış konu basmayacağız — deme" (söz değil, kanıt).

  Her yeni dalgadan ÖNCE sırayla:
    1) bitmiş partiler ambardan iner
    2) kapsama tablosu tazelenir (son 10 yıl, hedef 4.000)
    3) EXCEL yeniden yazılır (Masaüstü SMMM-Bitirme-Konu-Basim-Plani*.xlsx)
    4) plan kurulur — koşan dalgaların konuları REZERV edilir
    5) KONU DENETİMİ: yeni dalganın HER konusu tablodan tek tek kontrol edilir:
         · son 10 yılda sorulmuş mu (yenilik = YENI)      · açığı var mı
         · engelli mi (kısır / kaynak borcu)               · ders adı kanonik mi
         · konu dosyası yerinde mi
         · (koşan dalgalar + bu dalga) toplamı konunun açığını aşıyor mu
       TEK BİR ihlal varsa plan dosyaları SİLİNİR ve betik 1 ile çıkar → dalga AÇILMAZ.
  Çıktının son satırı "DENETİM:" ile başlar; o satır her turda Cem'e aynen gösterilir.

  🚫 BU DÖNGÜ ŞUNU GÖRMEZ: konu adının farklı yazımlarını (aynı konu iki satır olabilir,
    tablo körlüğü) · paralel iki dalganın birbirinin YENİ sorusunu (ikizi yayın kapısı yakalar).
  Bulut tetikleme bu betikte YOK: denetim geçtikten sonra GM commit eder ve tetikler.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/smmm-dalga-dongu.ps1 -Etiket w10 -Rezerve 'w9,w8'
================================================================================
#>
param(
  [Parameter(Mandatory)][string]$Etiket,
  [string]$Rezerve = '',
  [int]$PlanSayisi = 4, [int]$PlanBasinaSoru = 45, [int]$CikmisEsik = 2, [string]$YalnizDers = '', [switch]$HicYokOnce, [string]$HaricDers = '', [switch]$YalnizHicYok,   # 24.09 plan-kur'a geçer
  [switch]$IndirmeYok, [switch]$ExcelYok,
  # Var olan (koşan/bitmiş) bir dalgayı yalnız DENETLER: plan kurmaz, Excel yazmaz, ihlalde dosya SİLMEZ.
  [switch]$SadeceDenetim,
  # YALNIZ ÖZ-SINAV İÇİN (arac/smmm-dalga-dongu-sinavi.ps1): adım 1-4 atlanır, KONU DENETİMİ bu kökteki
  # veri/fabrika/smmm-kapsama.csv + veri/sinav/plan-smmm-*.json + veri/sinav/konu/*.json üzerinde koşar.
  # İhlalde silme davranışı gerçek koşuyla AYNIDIR (sınav onu da ölçer).
  [string]$DenetimKok = ''
  # Yollar '/' ile yazılır: denetim bölümü dogrula.yml'de ubuntu+pwsh üzerinde de koşar.
)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-ders-adi.ps1')
$sinavKosusu = [bool]$DenetimKok
if ($sinavKosusu) { $kok = $DenetimKok; $IndirmeYok = $true; $ExcelYok = $true }
function Nrm([string]$s) {
  # Önce İ/ı katlanır, SONRA küçültülür: Linux'ta (ICU) 'İ'.ToLowerInvariant() = 'i'+U+0307 olur ve 'İŞLEMLERİ'
  # tablodaki 'işlemleri' ile eşleşmez (23.09 dogrula.yml'de öz-sınav yakaladı; Windows'ta görünmüyordu).
  $t = "$s".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant() -replace 'ı', 'i' -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}
function Adim([string]$ad, [scriptblock]$is) {
  Write-Host "== $ad" -ForegroundColor Cyan
  & $is
  if ($LASTEXITCODE) { throw "$ad düştü (çıkış $LASTEXITCODE) — dalga AÇILMADI" }
}
if (-not $SadeceDenetim -and -not $sinavKosusu -and (Get-ChildItem (Join-Path $kok 'veri/sinav') -Filter "plan-smmm-$Etiket-*.json" -ErrorAction SilentlyContinue)) { throw "'$Etiket' etiketli plan zaten var — aynı etiketle ikinci dalga kurulmaz" }
if ($SadeceDenetim) { $IndirmeYok = $true; $ExcelYok = $true }
if (-not $SadeceDenetim -and -not $IndirmeYok) { Adim '1) partiler ambardan iniyor' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'parti-senkron.ps1') -Indir -Yaz -Sinav SMMM -OnEk 'smmm-' *> $null } }
if (-not $SadeceDenetim -and -not $sinavKosusu) { Adim '2) kapsama tablosu (son 10 yıl, hedef 4.000)' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'smmm-kapsama-tablosu.ps1') -Sessiz *> $null } }
if (-not $ExcelYok) {
  Adim '3) Excel' { $o = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'smmm-basim-excel.ps1') 2>&1; $script:excelSatir = @($o | Where-Object { "$_" -match '^EXCEL:' }) | Select-Object -Last 1 }
}
# 24.09 (Cem "1.2.3" madde 2): YAKLAŞAN YETERLİLİK DENEME PAKETİ kasanın güncel hâliyle yeniden üretilir (yeni sorular girer,
#   anahtar yenilenir). Yalnız: oturum tarihi en az 1 gün ileride + paketi zaten var + anahtarı YAYINLANMAMIŞ
#   (veri/canli/anahtar-<kod>.json yok). Tarihi geçmiş / yayınlanmış pakete DOKUNULMAZ. Hata dalgayı durdurmaz (uyarı).
if (-not $SadeceDenetim -and -not $sinavKosusu) {
  try {
    $cd = Get-Content (Join-Path $kok 'veri/canli-deneme.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($o in @($cd.oturumlar | Where-Object { "$($_.sinav)" -eq 'Yeterlilik' })) {
      $tar = [datetime]::ParseExact("$($o.tarih)", 'dd.MM.yyyy', $null); $kod = 'YET-' + $tar.ToString('ddMM')
      if ($tar -lt (Get-Date).Date.AddDays(1)) { continue }
      if (-not (Test-Path (Join-Path $kok "veri/canli/$kod.enc.json"))) { continue }
      if (Test-Path (Join-Path $kok "veri/canli/anahtar-$kod.json")) { continue }
      Write-Host "== deneme paketi tazeleniyor: $kod ($($o.tarih))" -ForegroundColor Cyan
      $po = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kok 'motor/canli-paketle.ps1') -oturum $kod 2>&1
      Write-Host "   $(@($po | Where-Object { "$_" -match 'PAKET HAZIR|URETILMEDI' }) -join ' ')"
    }
  } catch { Write-Host "  ⚠ deneme paketi tazelenemedi (dalga sürer): $($_.Exception.Message)" -ForegroundColor Yellow }
}$plArg = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $buDizin 'smmm-plan-kur.ps1'), '-PlanSayisi', "$PlanSayisi", '-PlanBasinaSoru', "$PlanBasinaSoru", '-Etiket', $Etiket, '-CikmisEsik', "$CikmisEsik")
if ($Rezerve) { $plArg += @('-RezerveEtiket', $Rezerve) }; if ($YalnizDers) { $plArg += @('-YalnizDers', $YalnizDers) }; if ($HicYokOnce) { $plArg += '-HicYokOnce' }; if ($HaricDers) { $plArg += @('-HaricDers', $HaricDers) }; if ($YalnizHicYok) { $plArg += '-YalnizHicYok' }
if (-not $SadeceDenetim -and -not $sinavKosusu) { Adim "4) plan kuruluyor ($Etiket, rezerv: $(if($Rezerve){$Rezerve}else{'yok'}))" { & powershell @plArg *> "$env:TEMP\plan-$Etiket.txt" } }

# --- 5) KONU DENETİMİ ---
Write-Host '== 5) konu denetimi' -ForegroundColor Cyan
$tablo = @{}
foreach ($r in @(Import-Csv (Join-Path $kok 'veri/fabrika/smmm-kapsama.csv') -Encoding UTF8)) { $tablo[(Nrm $r.konu)] = $r }
# koşan dalgaların planlanmış soruları (rezerv) + bu dalga
$planli = @{}
foreach ($rz in @(@($Rezerve -split ',') + $Etiket | ForEach-Object { "$_".Trim() } | Where-Object { $_ })) {
  foreach ($f in (Get-ChildItem (Join-Path $kok 'veri/sinav/konu') -Filter "smmm-$rz-*.json" -ErrorAction SilentlyContinue)) {
    foreach ($k in @((Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) { $n = Nrm "$k"; $planli[$n] = 1 + [int]$planli[$n] }
  }
}
$ihlal = New-Object System.Collections.Generic.List[string]
$konuSay = @{}; $soru = 0; $yeni = 0; $eski = 0; $olcmedi = 0; $engelli = 0; $aciksiz = 0; $dersHata = 0; $dosyaYok = 0; $asan = 0
foreach ($pf in (Get-ChildItem (Join-Path $kok 'veri/sinav') -Filter "plan-smmm-$Etiket-*.json")) {
  foreach ($s in @((Get-Content $pf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) {
    if ((SmmmDersAdi "$($s.etiket)" $null) -ne "$($s.ders)") { $dersHata++; $ihlal.Add("ders adı kanonik değil: $($s.etiket) → '$($s.ders)'") }
    $kd = Join-Path $kok "$($s.konuDosya)"
    if (-not (Test-Path $kd)) { $dosyaYok++; $ihlal.Add("konu dosyası yok: $($s.konuDosya)"); continue }
    foreach ($k in @((Get-Content $kd -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) {
      $soru++; $n = Nrm "$k"; $konuSay[$n] = 1
      $r = $tablo[$n]
      if (-not $r) { $olcmedi++; $ihlal.Add("tabloda yok: $k"); continue }
      $y = "$($r.yenilik)"
      if ($y -eq 'YENI') { $yeni++ } elseif ($y -like 'ESKI*') { $eski++; $ihlal.Add("10+ yıldır sorulmuyor: $k ($y)") } else { $olcmedi++; $ihlal.Add("yenilik ölçülemedi: $k") }
      if ("$($r.engel)") { $engelli++; $ihlal.Add("engelli konu: $k ($($r.engel))") }
      if ([int]$r.acik -le 0) { $aciksiz++; $ihlal.Add("açığı yok (hedef dolu): $k") }
    }
  }
}
foreach ($n in $konuSay.Keys) { $r = $tablo[$n]; if ($r -and [int]$planli[$n] -gt [int]$r.acik) { $asan++; $ihlal.Add("koşan+yeni dalga açığı aşıyor: $($r.konu) (planlı $($planli[$n]) > açık $($r.acik))") } }

$ozet = "DENETİM: $Etiket · $($konuSay.Count) konu · $soru soru · son 10 yıl $yeni · 10+ yıl eski $eski · ölçülemeyen $olcmedi · engelli $engelli · açığı dolu $aciksiz · açığı aşan $asan · ders hatası $dersHata · dosya eksik $dosyaYok"
if ($ihlal.Count -or $soru -eq 0) {
  foreach ($i in ($ihlal | Select-Object -First 15)) { Write-Host "  İHLAL: $i" -ForegroundColor Red }
  if ($SadeceDenetim) { Write-Host "$ozet → KIRMIZI (yalnız denetim — dosyalara dokunulmadı)" -ForegroundColor Red; exit 1 }
  Get-ChildItem (Join-Path $kok 'veri/sinav') -Filter "plan-smmm-$Etiket-*.json" | Remove-Item -Force
  Get-ChildItem (Join-Path $kok 'veri/sinav/konu') -Filter "smmm-$Etiket-*.json" | Remove-Item -Force
  Write-Host "$ozet → KIRMIZI, plan dosyaları SİLİNDİ, dalga AÇILMAZ" -ForegroundColor Red
  exit 1
}
if ($script:excelSatir) { $script:excelSatir }
Write-Host "$ozet → YEŞİL" -ForegroundColor Green
exit 0
