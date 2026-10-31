#requires -Version 5.1
<#
================================================================================
  YIL TEBLİĞİ EKİ — hakemin kaynak paketine SORUNUN YILININ resmî tutar düzenlemesi
  23.10.2026 · Cem: "hakem kaynak paketine 2025 yıl tebliğlerini bağlama işini kur ve bedelini söyle"

  NİYE VAR (ölçüldü 22–23.10): CLAUDE.md "SORU YILI = SINAVIN SORDUĞU YIL" kuralıyla vergi beyanı soruları
  2025 yılında yazılıyor; ama hakemin paketindeki kanun metni EN GÜNCEL tutarı taşıyor (GVK m.86/1-d
  "(22.000 TL)" = 2026). Bitirme 22.10 rehakeminde smmm-w4-yvergi-zor/kp-06 bu yüzden HAYIR aldı:
  "kaynakta m.86/1-d 22.000 TL iken soru 18.000 ₺ belirtmiştir" — oysa 18.000 GVGT Seri 329'daki 2025 tutarı.

  NE YAPAR: soru kökünde "2025 yılı/yılında…" gibi bir yıl geçiyorsa, veri/sinav/yillik-tutarlar.json
  kütüğündeki kalemlerden kelime grupları soruda geçenlerin O YILA ait değerini ve değerin alındığı resmî
  düzenleme maddesini (veri/mevzuat/<kaynak>.json, depoda) paketin başına koyar. Ambar çağrısı yok, bedel 0;
  hakemin girdisi soru başına birkaç bin karakter büyür.

  🚫 GÖRMEZ: kökte yıl yazmayan soru (yıl çözümde/şıkta geçiyorsa eklenmez) · kütükte olmayan kalem/yıl
  (kütüğün "olculmedi" listesi: 2025 asgari ücret, VUK m.370 haddi, SGK tavanı, MTV, harç) · kalemin kelime
  grubu soruda başka sözcükle anılmışsa (kütüğün kelime listesi kadar görür).

  Kullanım: . arac/yil-tebligi-eki.ps1 ; YilTebligiEki $soruMetni $depoKok   → @{ metin; adlar; yil }
            powershell -NoProfile -File arac/yil-tebligi-eki.ps1 -Sinav [-Mutasyon]
================================================================================
#>
# ⛔ 24.10: parametre ADLARI üreticideki değişkenlerle ÇAKIŞMAZ. Bu dosya motor/kalip-parti-uret.ps1'e dot-source ediliyor; eski
#   [switch]$Sinav üreticinin $Sinav='SGS' parametresini ezdi → 23.10 13:10'dan beri her bulut partisi satır 1541'de
#   ($Sinav.ToLowerInvariant) 0 USD'de düştü (sgs-s20-fmuh-a/b 6/6). Komut satırı aynı kalsın diye eski adlar Alias.
param([Alias('Sinav')][switch]$YteSinav, [Alias('Mutasyon')][switch]$YteMutasyon)

$script:YTE_KUTUK = $null
$script:YTE_BELGE = @{}

function YteKucuk([string]$s) { return $s.Replace([char]0x0130, 'i').Replace('I', 'ı').ToLowerInvariant() }
function YteBosluk([string]$s) { return (($s -replace '\s+', ' ').Trim()) }

function YilTebligiEki([string]$metin, [string]$kok) {
  $bos = @{ metin = ''; adlar = @(); yil = @() }
  if (-not $metin) { return $bos }
  $mut = "$env:YTE_MUTASYON"
  if (-not $script:YTE_KUTUK) {
    $kp = [IO.Path]::Combine($kok, 'veri', 'sinav', 'yillik-tutarlar.json')   # dogrula.yml Linux pwsh'te koşar: ters bölü yol .NET'te kırılır
    if (-not (Test-Path $kp)) { return $bos }
    $script:YTE_KUTUK = [IO.File]::ReadAllText($kp, [Text.Encoding]::UTF8) | ConvertFrom-Json
  }
  # Yıl: kökte "2025 yılı / yılında / yılına / yılının / takvim yılı / hesap dönemi"
  $yillar = @([regex]::Matches($metin, '(?<!\d)(20\d\d)\s*(?:yıl|takvim yıl|hesap dönem)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  if ($mut -eq 'yil-yok') { $yillar = @() }
  if (-not $yillar.Count) { return $bos }
  $kucuk = YteKucuk $metin
  $satir = New-Object System.Collections.Generic.List[string]
  $belgeler = New-Object System.Collections.Generic.List[string]
  $adlar = New-Object System.Collections.Generic.List[string]
  $bulunanYil = New-Object System.Collections.Generic.List[string]
  foreach ($p in $script:YTE_KUTUK.kalemler.PSObject.Properties) {
    $k = $p.Value
    $gruplar = @($k.kelime | ForEach-Object { , @($_) })
    $tut = if ($mut -eq 'kelime-tek') { @($gruplar | Where-Object { @($_ | Where-Object { $kucuk.Contains((YteKucuk "$_")) }).Count }).Count -gt 0 }
           else { @($gruplar | Where-Object { -not @($_ | Where-Object { $kucuk.Contains((YteKucuk "$_")) }).Count }).Count -eq 0 }
    if (-not $tut) { continue }
    foreach ($d in $k.degerler.PSObject.Properties) {
      $dy = ($d.Name -split '-')[0]
      if ($mut -ne 'yil-hepsi' -and $yillar -notcontains $dy) { continue }
      $v = $d.Value
      $kaynakAd = "$($v.kaynak)"
      $slug = $kaynakAd -replace '^(ambar|hazir):', ''
      $belgeAd = ''
      if ($mut -ne 'belge-yok' -and $slug) {
        if (-not $script:YTE_BELGE.ContainsKey($slug)) {
          $bp = [IO.Path]::Combine($kok, 'veri', 'mevzuat', "$slug.json")
          $script:YTE_BELGE[$slug] = if (Test-Path $bp) { @(([IO.File]::ReadAllText($bp, [Text.Encoding]::UTF8) | ConvertFrom-Json).belgeler) } else { @() }
        }
        $al = YteBosluk "$($v.alinti)"
        foreach ($b in $script:YTE_BELGE[$slug]) {
          if ($al -and (YteBosluk "$($b.metin)").Contains($al)) {
            $belgeAd = "$($b.kaynak_ad)"
            if (-not $adlar.Contains($belgeAd)) { $adlar.Add($belgeAd); $belgeler.Add("[$belgeAd] $($b.metin)") }
            break
          }
        }
      }
      $donem = if ($d.Name -match '-') { " ($($d.Name) dönemi)" } else { '' }
      $satir.Add("- $($k.ad) · $dy$donem : $($v.deger) TL  [kaynak: $(if ($belgeAd) { $belgeAd } else { $kaynakAd })]")
      if (-not $bulunanYil.Contains($dy)) { $bulunanYil.Add($dy) }
    }
  }
  if (-not $satir.Count) { return $bos }
  $yilYazi = ($bulunanYil -join ', ')
  $m = "=== SORUNUN YILI ($yilYazi) ICIN RESMI YILLIK TUTARLAR ===`n" +
       "NOT: Kanun maddelerinde parantez icinde gosterilen tutarlar EN GUNCEL yilin tutaridir. Soru $yilYazi yili icin yazildiysa gecerli tutar asagidaki $yilYazi duzenlemesidir; kanun metnindeki guncel tutarla farkli olmasi tek basina 'kaynakta yok' sebebi DEGILDIR.`n" +
       ($satir -join "`n")
  if ($belgeler.Count) { $m += "`n---`n" + ($belgeler -join "`n---`n") }
  return @{ metin = $m; adlar = @($adlar); yil = @($bulunanYil) }
}

if ($YteSinav) {
  $kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
  $vakalar = @(
    @{ ad = 'beyan siniri 2025 (w4/kp-06 deseni)'; metin = '(A) Bey 2025 yılında mevduat faizi ve kira geliri elde etmiştir. GVK m.86/1-d beyan sınırı dikkate alınarak beyan edilecek tutar nedir?'; ister = '18.000'; belge = 'SERİ NO: 329'; istemez = '22.000' }
    @{ ad = 'mesken 2026'; metin = 'Konut olarak kiraya verilen dairenin 2026 yılı kira geliri için mesken istisnası uygulanacaktır.'; ister = '58.000'; belge = 'SERİ NO:332'; istemez = '47.000' }
    @{ ad = 'kidem 2025 iki donem'; metin = 'İşçinin 2025 yılında işten ayrılması üzerine kıdem tazminatı tavanı esas alınır.'; ister = '46.655,43'; belge = ''; istemez = '64.948,77'; ister2 = '53.919,68' }
    @{ ad = 'yil yok'; metin = 'Konut kira gelirinde mesken istisnası nasıl uygulanır?'; bos = $true }
    @{ ad = 'kutukte olmayan yil'; metin = '2024 yılında konut kira geliri için mesken istisnası uygulanır.'; bos = $true }
    @{ ad = 'yanlis alarm: kelime yok'; metin = 'İşletme 2025 yılında bir makine satın almış ve amortisman ayırmıştır.'; bos = $true }
  )
  $hata = 0
  foreach ($v in $vakalar) {
    $r = YilTebligiEki $v.metin $kok
    $ok = $true
    if ($v.bos) { if ($r.metin) { $ok = $false } }
    else {
      if (-not $r.metin.Contains($v.ister)) { $ok = $false }
      if ($v.ister2 -and -not $r.metin.Contains($v.ister2)) { $ok = $false }
      # yanlış yılın değeri TUTAR SATIRLARINDA olmamalı (resmî belge metni birden çok yılı taşıyabilir: kıdem genelgesi 2025+2026)
      if ($v.istemez -and ($r.metin -split "`n---`n")[0].Contains($v.istemez)) { $ok = $false }
      if ($v.belge -and -not (@($r.adlar) -join '|').Contains($v.belge)) { $ok = $false }
    }
    if (-not $ok) { $hata++ }
    if (-not $YteMutasyon) { Write-Host ("  {0} {1}" -f $(if ($ok) { 'GECTI' } else { 'DUSTU' }), $v.ad) }
  }
  if ($YteMutasyon) { return $hata }
  if ($hata) { Write-Host "YIL TEBLIGI EKI SINAVI: $hata/$($vakalar.Count) DUSTU" -ForegroundColor Red; exit 1 }
  Write-Host "YIL TEBLIGI EKI SINAVI: $($vakalar.Count)/$($vakalar.Count) GECTI"
  # Mutasyon: her kilit kosul bozulunca sinav KIRMIZI olmali
  $kirmizi = 0; $mutlar = @('yil-yok', 'kelime-tek', 'belge-yok', 'yil-hepsi')
  foreach ($mu in $mutlar) {
    $env:YTE_MUTASYON = $mu; $script:YTE_KUTUK = $null; $script:YTE_BELGE = @{}
    $h = & $MyInvocation.MyCommand.Path -Sinav -Mutasyon
    if ([int]$h -gt 0) { $kirmizi++; Write-Host "  mutasyon $mu -> KIRMIZI ($h)" } else { Write-Host "  mutasyon $mu -> YESIL KALDI (sinav kor)" -ForegroundColor Red }
  }
  $env:YTE_MUTASYON = ''
  Write-Host "MUTASYON: $kirmizi/$($mutlar.Count) KIRMIZI"
  if ($kirmizi -ne $mutlar.Count) { exit 1 }
}
