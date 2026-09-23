#requires -Version 5.1
<#
================================================================================
  SMMM DALGA DÖNGÜSÜ — KONU DENETİMİ ÖZ-SINAVI   (23.09.2026) · bedel 0

  NİYE VAR: CLAUDE.md SINAV kuralı 7 — "yanlış konu basmıyoruz" DENMEZ, `DENETİM:`
  satırı GÖSTERİLİR. O satırı üreten denetim kendisi bozulursa sessizce "YEŞİL" der
  ve para yanlış konuya gider. 21.09 kapı kuralı md. 2: öz-sınavı olmayan kapı
  "ölçüyor" sayılmaz. Denetim 23.09'da yalnız gerçek dalgalarla ölçülmüştü
  (w9 YEŞİL · w6 KIRMIZI · w8'de 1 ihlal); bu sınav sentetik vakalarla her ihlal
  türünü TEK TEK ve yanlış alarmı ayrıca ölçer.

  ⛔ REPLİKA YASAK: sınav denetimin kopyasını yazmaz; GERÇEK arac/smmm-dalga-dongu.ps1
     `-DenetimKok <geçici klasör>` ile koşulur (adım 1-4 atlanır, denetim + silme aynen koşar).

  VAKALAR (14): yakalaması gereken 9 · yanlış alarm vermemesi gereken 4 · silme davranışı 1
  🚫 BU SINAV ŞUNU GÖRMEZ: gerçek kapsama tablosunun doğruluğunu (köprü yanlışsa hedef de
     yanlıştır) · plan kurucunun seçimini (o ayrı betik) · konu adının farklı YAZIMLARINI
     (denetimin kendi körlüğü — Türkçe harf/büyük-küçük farkı dışında).
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$betik = Join-Path $buDizin 'smmm-dalga-dongu.ps1'
if (-not (Test-Path $betik)) { throw "dalga döngü betiği bulunamadı: $betik" }

$VERGI = 'Vergi Mevzuatı ve Uygulaması'
# Sentetik kapsama tablosu — gerçek sütun adlarıyla
$TABLO = @(
  @{ konu = 'Amortisman ayırma';        yenilik = 'YENI';       acik = 5; engel = '' }
  @{ konu = 'Çek İşlemleri';            yenilik = 'YENI';       acik = 2; engel = '' }
  @{ konu = 'Şüpheli alacak karşılığı'; yenilik = 'ESKI-2014';  acik = 3; engel = '' }
  @{ konu = 'Kısır konu';               yenilik = 'YENI';       acik = 4; engel = 'KISIR' }
  @{ konu = 'Dolu konu';                yenilik = 'YENI';       acik = 0; engel = '' }
  @{ konu = 'Sınırda konu';             yenilik = 'YENI';       acik = 2; engel = '' }
  @{ konu = 'Ölçülemeyen konu';         yenilik = 'OLCULMEDI';  acik = 3; engel = '' }
)

function KokKur([hashtable]$v) {
  $k = Join-Path ([IO.Path]::GetTempPath()) ("dalga-sinav-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
  foreach ($d in @('veri/fabrika', 'veri/sinav/konu')) { New-Item -ItemType Directory -Force -Path (Join-Path $k $d) | Out-Null }
  $TABLO | ForEach-Object { [pscustomobject]@{ ders = $VERGI; konu = $_.konu; cikmis = 9; son10 = 3; son_soruldu = 2024; yenilik = $_.yenilik
      yazdik = 0; yayinlanabilir = 0; hedef = $_.acik; acik = $_.acik; durum = ''; engel = $_.engel } } |
    Export-Csv -Path (Join-Path $k 'veri/fabrika/smmm-kapsama.csv') -NoTypeInformation -Encoding UTF8
  $utf8 = New-Object Text.UTF8Encoding $false
  $satirlar = New-Object System.Collections.Generic.List[object]; $i = 0
  foreach ($s in @($v.satir)) {
    $i++; $kd = "veri/sinav/konu/smmm-w99-$i.json"
    if (-not $s.dosyaYok) { [IO.File]::WriteAllText((Join-Path $k $kd), [string](ConvertTo-Json -InputObject ([object[]]@($s.konular)) -Compress), $utf8) }
    $satirlar.Add([pscustomobject]@{ etiket = $(if ($s.etiket) { $s.etiket } else { "smmm-w99-yvergi-$i" }); ders = $(if ($s.ders) { $s.ders } else { $VERGI }); konuDosya = $kd; adet = @($s.konular).Count })
  }
  [IO.File]::WriteAllText((Join-Path $k 'veri/sinav/plan-smmm-w99-1.json'), [string](ConvertTo-Json -InputObject $satirlar.ToArray() -Depth 5), $utf8)
  # koşan dalga (rezerv) konuları
  if ($v.rezerv) { [IO.File]::WriteAllText((Join-Path $k 'veri/sinav/konu/smmm-wR-1.json'), [string](ConvertTo-Json -InputObject ([object[]]@($v.rezerv)) -Compress), $utf8) }
  return $k
}
function Kos([hashtable]$v) {
  $k = KokKur $v
  $arg = @{ Etiket = 'w99'; DenetimKok = $k }
  if ($v.rezerv) { $arg.Rezerve = 'wR' }
  if ($v.sadece) { $arg.SadeceDenetim = $true }
  $global:LASTEXITCODE = 0
  $cikti = @(& $betik @arg *>&1 | ForEach-Object { "$_" })
  $kod = $LASTEXITCODE
  $planKaldi = [bool](Get-ChildItem (Join-Path $k 'veri/sinav') -Filter 'plan-smmm-w99-*.json' -ErrorAction SilentlyContinue)
  $konuKaldi = @(Get-ChildItem (Join-Path $k 'veri/sinav/konu') -Filter 'smmm-w99-*.json' -ErrorAction SilentlyContinue).Count
  Remove-Item -Recurse -Force $k -ErrorAction SilentlyContinue
  return [pscustomobject]@{ kod = $kod; ozet = @($cikti | Where-Object { $_ -like 'DENETİM:*' }) | Select-Object -Last 1; ihlal = @($cikti | Where-Object { $_ -like '*İHLAL:*' }); planKaldi = $planKaldi; konuKaldi = $konuKaldi }
}
function S([string[]]$konular) { @{ konular = $konular } }

$vaka = @(
  # --- YANLIŞ ALARM VERMEMESİ GEREKENLER ---
  @{ ad = 'temiz dalga YEŞİL, dosyalar yerinde, sayım doğru'; satir = @((S @('Amortisman ayırma', 'Amortisman ayırma')), (S @('Çek İşlemleri')))
     bek = 0; ozetIcer = @('2 konu', '3 soru', 'son 10 yıl 3'); kalir = $true }
  @{ ad = 'Türkçe harf/büyük-küçük farkı tabloda bulunur (ÇEK İŞLEMLERİ = Çek İşlemleri)'; satir = @((S @('ÇEK İŞLEMLERİ')))
     bek = 0; kalir = $true }
  @{ ad = 'koşan + yeni dalga açığa TAM eşit → geçer (2 = 2)'; satir = @((S @('Sınırda konu'))); rezerv = @('Sınırda konu')
     bek = 0; kalir = $true }
  @{ ad = "'y' önekli etiket kanonik derse çözülür (yvergi → Vergi)"; satir = @(@{ konular = @('Amortisman ayırma'); etiket = 'smmm-w99-yvergi-7'; ders = $VERGI })
     bek = 0; kalir = $true }
  # --- YAKALAMASI GEREKENLER (hepsinde plan + konu dosyası SİLİNMELİ) ---
  @{ ad = '10+ yıldır sorulmayan konu'; satir = @((S @('Amortisman ayırma', 'Şüpheli alacak karşılığı'))); bek = 1; ihlalIcer = '10+ yıldır sorulmuyor'; kalir = $false }
  @{ ad = 'engelli (KISIR) konu'; satir = @((S @('Kısır konu'))); bek = 1; ihlalIcer = 'engelli konu'; kalir = $false }
  @{ ad = 'açığı dolu konu'; satir = @((S @('Dolu konu'))); bek = 1; ihlalIcer = 'açığı yok'; kalir = $false }
  @{ ad = 'yeniliği ölçülemeyen konu'; satir = @((S @('Ölçülemeyen konu'))); bek = 1; ihlalIcer = 'yenilik ölçülemedi'; kalir = $false }
  @{ ad = 'tabloda olmayan konu'; satir = @((S @('Uydurma konu adı'))); bek = 1; ihlalIcer = 'tabloda yok'; kalir = $false }
  @{ ad = 'ders adı kanonik değil (vergi etiketi, Hukuk dersi)'; satir = @(@{ konular = @('Amortisman ayırma'); etiket = 'smmm-w99-vergi-1'; ders = 'Hukuk' })
     bek = 1; ihlalIcer = 'ders adı kanonik değil'; kalir = $false }
  @{ ad = 'konu dosyası eksik'; satir = @(@{ konular = @('Amortisman ayırma'); dosyaYok = $true }); bek = 1; ihlalIcer = 'konu dosyası yok'; kalir = $false }
  @{ ad = 'koşan + yeni dalga açığı aşıyor (1 + 2 > 2)'; satir = @((S @('Sınırda konu', 'Sınırda konu'))); rezerv = @('Sınırda konu')
     bek = 1; ihlalIcer = 'açığı aşıyor'; kalir = $false }
  @{ ad = 'boş dalga (0 soru) açılmaz'; satir = @((S @())); bek = 1; kalir = $false }
  # --- SİLME DAVRANIŞI ---
  @{ ad = '-SadeceDenetim ihlalde KIRMIZI döner ama dosyaya DOKUNMAZ'; satir = @((S @('Dolu konu'))); sadece = $true; bek = 1; ihlalIcer = 'açığı yok'; kalir = $true }
)

$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
foreach ($v in $vaka) {
  $r = Kos $v; $neden = @()
  if ($r.kod -ne $v.bek) { $neden += "çıkış $($r.kod) (beklenen $($v.bek))" }
  if (-not $r.ozet) { $neden += 'DENETİM satırı yok' }
  foreach ($p in @($v.ozetIcer)) { if ($p -and "$($r.ozet)" -notlike "*$p*") { $neden += "özet '$p' içermiyor" } }
  if ($v.ihlalIcer -and -not @($r.ihlal | Where-Object { $_ -like "*$($v.ihlalIcer)*" }).Count) { $neden += "ihlal '$($v.ihlalIcer)' yazılmadı" }
  if ($v.bek -eq 0 -and $r.ihlal.Count) { $neden += "YANLIŞ ALARM: $($r.ihlal[0])" }
  if ($v.kalir -and -not $r.planKaldi) { $neden += 'plan dosyası silinmiş (silinmemeliydi)' }
  if (-not $v.kalir -and ($r.planKaldi -or $r.konuKaldi)) { $neden += 'plan/konu dosyası SİLİNMEDİ — dalga açılabilir' }
  if ($neden.Count) { $dustu.Add("$($v.ad): $($neden -join ' · ')") } else { $gecti++ }
  if (-not $Sessiz) { Write-Host ("  {0} {1}" -f $(if ($neden.Count) { 'DÜŞTÜ' } else { 'geçti' }), $v.ad) }
}
Write-Host "DALGA DENETİMİ ÖZ-SINAVI: $gecti/$($vaka.Count) geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
