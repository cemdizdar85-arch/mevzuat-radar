#requires -Version 5.1
<#
================================================================================
  BİTİRME KART ÜSTÜ KONU BAŞLIĞI — ÖZ-SINAV  (01.11.2026)  ağ yok, para yok

  NİYE VAR: kasa yayınında ekrana giden başlık ambardaki eski plan konusundan geliyordu (Ajan 30: 3.584 eşlemeli
    sorunun 1.054'ünde kartla uyumsuz). arac/smmm-konu-baslik.ps1 başlığı karttan türetir; sınav öncelik sırasını,
    ders şartını, prova anahtarını ve İKİZ KAPISININ AMBAR KONUSUYLA KALDIĞINI ölçer.
  ⛔ REPLİKA YASAK: gerçek arac/smmm-konu-baslik.ps1 metni yüklenir; arac/smmm-kasa-yayin.ps1 AST ile okunur.
    Veri dosyaları sahte (geçici klasör) — mantık sınanır; ayrıca GERÇEK veri dosyalarıyla iki duman vakası.
  VAKALAR: kart var · kart var ama durum≠uygula · kart var ama soru hedef derste değil (ders düzeltmesi kapalı) ·
    eşleme var (konular[0]) · eşleme başka derste · eşleme konular boş · ikisi de yok · prova anahtarı KAPALI ·
    kasa yayını: ikiz grubu (IkizAnlamGrup) ambar konusu, seçim dosyası başlık, SmmmKonuBaslik ambar konusuyla çağrılır.
  -Mutasyon: 8 bozma, her biri sınavı KIRMIZI düşürmeli.
  🚫 GÖRMEZ: kartın doğruluğu (okuma işi) · kaydir-coz'un başlığa uyguladığı TurkceOnar (arac/turkce-onar-sinavi.ps1) ·
    ambarın tamamında eşdeğerlik (ayrı prova: -SadeceSecim + SMMM_SECIM_KONU_CIKTI / SMMM_IKIZ_CIKTI).
  KULLANIM: powershell -NoProfile -File arac/smmm-konu-baslik-sinavi.ps1 [-Mutasyon] [-Sessiz]
================================================================================
#>
param([switch]$Mutasyon, [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$baslikYol = Join-Path $buDizin 'smmm-konu-baslik.ps1'
$yayinYol = Join-Path $buDizin 'smmm-kasa-yayin.ps1'
$baslikMetin = [IO.File]::ReadAllText($baslikYol, [Text.Encoding]::UTF8)
$yayinMetin = [IO.File]::ReadAllText($yayinYol, [Text.Encoding]::UTF8)

# --- sahte veri (geçici klasör) ---
$gecici = Join-Path ([IO.Path]::GetTempPath()) ("konu-baslik-sinavi-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $gecici | Out-Null
$u8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $gecici 'smmm-ders-duzelt.json'), (@{ duzelt = [ordered]@{
      'smmm-x-fmuh/kp-01' = @{ ders = 'Finansal Muhasebe'; eski = 'Muhasebe Denetimi'; kart = 'Şüpheli ve değersiz alacaklar'; durum = 'uygula' }
      'smmm-x-fmuh/kp-02' = @{ ders = 'Finansal Muhasebe'; kart = 'Amortisman'; durum = 'bekle' }
      'smmm-x-fmuh/kp-03' = @{ ders = 'Meslek Hukuku'; kart = 'Disiplin cezaları ve gerektiren haller'; durum = 'uygula' }
      'smmm-x-fmuh/kp-09' = @{ ders = 'Finansal Muhasebe'; kart = '  '; durum = 'uygula' }
    } } | ConvertTo-Json -Depth 5), $u8)
[IO.File]::WriteAllText((Join-Path $gecici 'smmm-banka-esleme.json'), (@{ sorular = [ordered]@{
      'smmm-x-fmuh/kp-01' = @{ ders = 'Finansal Muhasebe'; konular = @('Çek ve senet işlemleri') }
      'smmm-x-fmuh/kp-02' = @{ ders = 'Finansal Muhasebe'; konular = @('Malzeme ve diğer stoklar', 'Amortisman') }
      'smmm-x-fmuh/kp-03' = @{ ders = 'Finansal Muhasebe'; konular = @('Çek ve senet işlemleri') }
      'smmm-x-fmuh/kp-04' = @{ ders = 'Finansal Muhasebe'; konular = @('Safha (evre) maliyet sistemi') }
      'smmm-x-fmuh/kp-05' = @{ ders = 'Maliyet Muhasebesi'; konular = @('Safha (evre) maliyet sistemi') }
      'smmm-x-fmuh/kp-06' = @{ ders = 'Finansal Muhasebe'; konular = @() }
      'smmm-x-fmuh/kp-09' = @{ ders = 'Finansal Muhasebe'; konular = @('Hile ve hata') }
    } } | ConvertTo-Json -Depth 5), $u8)

# metinden kurulan işlevde $PSScriptRoot boş → veri dizini burada verilir, önbellek sıfırlanır.
# (işlev metni çağıranın kapsamında dot-source edilir: bir işlevin İÇİNDE dot-source edilen tanım o işlevden çıkınca kaybolur)
function Sifirla([string]$sinavDizini) { $script:SMMM_KONU_SINAV = $sinavDizini; $script:SMMM_KONU_ESLEME = $null; $script:SMMM_KONU_KART = $null }
function YayinKomutArg([string]$metin, [string]$komut, [int]$sira) {
  $tk = $null; $hata = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($metin, [ref]$tk, [ref]$hata)
  if ($hata -and $hata.Count) { return "AYRIŞTIRILAMADI: $($hata[0].Message)" }
  $c = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and "$($n.GetCommandName())" -eq $komut }, $true))
  if ($c.Count -ne 1) { return "$komut çağrısı $($c.Count) kez (1 beklenir)" }
  $el = @($c[0].CommandElements)
  if ($el.Count -le $sira) { return "$komut argüman $sira yok" }
  return $el[$sira].Extent.Text
}
function SecimKonuDegeri([string]$metin) {
  # seçim dosyasına yazılan [ordered]@{ … konu = <değer> … } (secim-<slug>.json, kaydir-coz konuSecim)
  $tk = $null; $hata = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($metin, [ref]$tk, [ref]$hata)
  $h = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.HashtableAst] -and @($n.KeyValuePairs | Where-Object { "$($_.Item1.Extent.Text)" -eq 'etiket' }).Count -and @($n.KeyValuePairs | Where-Object { "$($_.Item1.Extent.Text)" -eq 'donem' }).Count -and @($n.KeyValuePairs | Where-Object { "$($_.Item1.Extent.Text)" -eq 'konu' }).Count -and "$($n.Parent.Extent.Text)" -like '`[ordered`]*' }, $true))
  if ($h.Count -ne 1) { return "seçim satırı $($h.Count) kez (1 beklenir)" }
  return "$((@($h[0].KeyValuePairs | Where-Object { "$($_.Item1.Extent.Text)" -eq 'konu' })[0]).Item2.Extent.Text)"
}

function SinavKos([string]$bMetin, [string]$yMetin) {
  $kalan = New-Object System.Collections.Generic.List[string]
  function V([string]$ad, [bool]$kosul, [string]$ek) { if ($kosul) { $script:okSay++; if (-not $Sessiz -and -not $Mutasyon) { "  OK    $ad" | Write-Host } } else { $kalan.Add("$ad ($ek)"); if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  DÜŞTÜ $ad ($ek)" -ForegroundColor Red } } }
  $script:okSay = 0
  $eskiKapali = $env:SMMM_KONU_KART_KAPALI; $env:SMMM_KONU_KART_KAPALI = ''
  try {
    . ([scriptblock]::Create($bMetin)); Sifirla $gecici
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-01' 'Finansal Muhasebe' 'donem ici yevmiye kayitlari'
    V 'kart var → ders düzeltmesi kartı (eşlemeden önce)' ($r.konu -eq 'Şüpheli ve değersiz alacaklar' -and $r.kaynak -eq 'kart') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-02' 'Finansal Muhasebe' 'kirtasiye tuketim gideri'
    V 'kart durum≠uygula → eşleme konular[0]' ($r.konu -eq 'Malzeme ve diğer stoklar' -and $r.kaynak -eq 'esleme') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-03' 'Finansal Muhasebe' 'borc senedi'
    V 'kart başka derse (soru taşınmamış) → eşleme' ($r.konu -eq 'Çek ve senet işlemleri' -and $r.kaynak -eq 'esleme') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-03' 'Meslek Hukuku' 'borc senedi'
    V 'kart hedef dersinde → kart' ($r.konu -eq 'Disiplin cezaları ve gerektiren haller' -and $r.kaynak -eq 'kart') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-09' 'Finansal Muhasebe' 'hile'
    V 'boş kart → eşleme' ($r.konu -eq 'Hile ve hata' -and $r.kaynak -eq 'esleme') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-04' 'Finansal Muhasebe' 'esdeger urun miktari'
    V 'eşleme var → konular[0]' ($r.konu -eq 'Safha (evre) maliyet sistemi' -and $r.kaynak -eq 'esleme') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-05' 'Finansal Muhasebe' 'esdeger urun miktari'
    V 'eşleme başka derste → ambar konusu' ($r.konu -eq 'esdeger urun miktari' -and $r.kaynak -eq 'ambar') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-06' 'Finansal Muhasebe' 'tutar saglamasi'
    V 'eşleme konular boş → ambar konusu' ($r.konu -eq 'tutar saglamasi' -and $r.kaynak -eq 'ambar') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-07' 'Finansal Muhasebe' 'genel yönetim gideri'
    V 'ikisi de yok → ambar konusu AYNEN' ($r.konu -eq 'genel yönetim gideri' -and $r.kaynak -eq 'ambar') "$($r.konu) | $($r.kaynak)"
    $r = SmmmKonuBaslik 'smmm-y-fmuh' 'kp-01' 'Finansal Muhasebe' 'x'
    V 'kimlik etiket+id ile eşlenir (başka etiketin kp-01i değil)' ($r.kaynak -eq 'ambar') "$($r.konu) | $($r.kaynak)"
    # prova anahtarı
    $env:SMMM_KONU_KART_KAPALI = '1'; Sifirla $gecici
    $r = SmmmKonuBaslik 'smmm-x-fmuh' 'kp-01' 'Finansal Muhasebe' 'donem ici yevmiye kayitlari'
    V 'SMMM_KONU_KART_KAPALI=1 → ambar konusu (eski davranış)' ($r.konu -eq 'donem ici yevmiye kayitlari' -and $r.kaynak -eq 'ambar') "$($r.konu) | $($r.kaynak)"
    $env:SMMM_KONU_KART_KAPALI = ''
    # gerçek veri dosyalarıyla duman (yalnız biçim: dosyalar okunur, bilinen bir kayıt kartını verir)
    Sifirla (Join-Path (Join-Path $depoKok 'veri') 'sinav')
    $gDz = (Get-Content (Join-Path (Join-Path (Join-Path $depoKok 'veri') 'sinav') 'smmm-ders-duzelt.json') -Raw -Encoding UTF8 | ConvertFrom-Json).duzelt.PSObject.Properties | Where-Object { "$($_.Value.durum)" -eq 'uygula' -and "$($_.Value.kart)".Trim() } | Select-Object -First 1
    $gEt, $gId = "$($gDz.Name)" -split '/', 2
    $r = SmmmKonuBaslik $gEt $gId "$($gDz.Value.ders)" 'ambar'
    V 'GERÇEK ders düzeltmesi dosyası: ilk uygula kaydı kartını verir' ($r.konu -eq "$($gDz.Value.kart)".Trim() -and $r.kaynak -eq 'kart') "$($gDz.Name): $($r.konu) | $($r.kaynak)"
    $gEs = (Get-Content (Join-Path (Join-Path (Join-Path $depoKok 'veri') 'sinav') 'smmm-banka-esleme.json') -Raw -Encoding UTF8 | ConvertFrom-Json).sorular.PSObject.Properties | Where-Object { @($_.Value.konular).Count -and -not $script:SMMM_KONU_KART.ContainsKey("$($_.Name)") } | Select-Object -First 1
    $gEt, $gId = "$($gEs.Name)" -split '/', 2
    $r = SmmmKonuBaslik $gEt $gId "$($gEs.Value.ders)" 'ambar'
    V 'GERÇEK banka eşlemesi: ilk kaydı konular[0]' ($r.konu -eq "$(@($gEs.Value.konular)[0])".Trim() -and $r.kaynak -eq 'esleme') "$($gEs.Name): $($r.konu) | $($r.kaynak)"
    # kasa yayını bağı (AST): ikiz grubu ambar konusuyla, seçim dosyası başlıkla, başlık işlevi ambar konusuyla çağrılır
    $a = YayinKomutArg $yMetin 'IkizAnlamGrup' 2
    V 'kasa yayını: IkizAnlamGrup ambar konusunu alır ("$($v.konu)")' ($a -eq '"$($v.konu)"') $a
    $a = YayinKomutArg $yMetin 'SmmmKonuBaslik' 4
    V 'kasa yayını: SmmmKonuBaslik yedek olarak ambar konusunu alır' ($a -eq '"$($v.konu)"') $a
    $a = YayinKomutArg $yMetin 'SmmmKonuBaslik' 3
    V 'kasa yayını: SmmmKonuBaslik yayın dersini alır ($ders)' ($a -eq '$ders') $a
    $a = SecimKonuDegeri $yMetin
    V 'kasa yayını: seçim dosyasının konu alanı başlık ($_.baslik)' ($a -eq '$_.baslik') $a
    V 'kasa yayını: aday satırında konu = ambar konusu kalır' ($yMetin -match 'konu = "\$\(\$v\.konu\)"; baslik = "\$\(\$baslik\.konu\)"') 'aday satırı bulunamadı'
  } finally { $env:SMMM_KONU_KART_KAPALI = $eskiKapali }
  $script:vakaSay = $script:okSay + $kalan.Count
  return , $kalan
}

$MUTASYONLAR = @(
  @{ ad = 'M1 öncelik: eşleme karttan önce'; d = 'b'; eski = 'if ($kd -and $kd.ders -eq $yayinDersi)'; yeni = 'if ($false)' }
  @{ ad = 'M2 kart ders şartı yok'; d = 'b'; eski = 'if ($kd -and $kd.ders -eq $yayinDersi)'; yeni = 'if ($kd)' }
  @{ ad = 'M3 eşleme ders şartı yok'; d = 'b'; eski = 'if ($es -and $es.ders -eq $yayinDersi)'; yeni = 'if ($es)' }
  @{ ad = 'M4 durum=uygula süzgeci yok'; d = 'b'; eski = '"$($k.Value.durum)" -ne ''uygula'' -or '; yeni = '' }
  @{ ad = 'M5 prova anahtarı okunmuyor'; d = 'b'; eski = 'if ("$env:SMMM_KONU_KART_KAPALI" -ne ''1'')'; yeni = 'if ($true)' }
  @{ ad = 'M6 yedek ambar konusu yerine boş'; d = 'b'; eski = "return @{ konu = `$ambarKonu; kaynak = 'ambar' }"; yeni = "return @{ konu = ''; kaynak = 'ambar' }" }
  @{ ad = 'M7 yayın: ikiz grubu başlıkla kuruluyor'; d = 'y'; eski = '(IkizAnlamGrup $ders "$($v.konu)" $v.kaynak_adlar)'; yeni = '(IkizAnlamGrup $ders "$($baslik.konu)" $v.kaynak_adlar)' }
  @{ ad = 'M8 yayın: seçim dosyası ambar konusunu yazıyor'; d = 'y'; eski = 'konu = $_.baslik; donem = $_.donem'; yeni = 'konu = $_.konu; donem = $_.donem' }
)
try {
  if (-not $Mutasyon) {
    $kalan = SinavKos $baslikMetin $yayinMetin
    ''
    "KONU BAŞLIĞI ÖZ-SINAVI: $($script:vakaSay - $kalan.Count)/$($script:vakaSay) geçti"
    if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
    Write-Host 'YEŞİL' -ForegroundColor Green
    exit 0
  }
  $kirmizi = 0
  foreach ($m in $MUTASYONLAR) {
    $bM = $baslikMetin; $yM = $yayinMetin
    if ($m.d -eq 'b') { if (-not $bM.Contains($m.eski)) { throw "mutasyon hedefi yok: $($m.ad)" }; $bM = $bM.Replace($m.eski, $m.yeni) }
    else { if (-not $yM.Contains($m.eski)) { throw "mutasyon hedefi yok: $($m.ad)" }; $yM = $yM.Replace($m.eski, $m.yeni) }
    $k = SinavKos $bM $yM
    if ($k.Count) { $kirmizi++; "  KIRMIZI (beklenen) $($m.ad) → $($k.Count) vaka düştü: $($k[0])" } else { Write-Host "  YEŞİL KALDI (SINAV EKSİK) $($m.ad)" -ForegroundColor Red }
  }
  "MUTASYON: $kirmizi/$($MUTASYONLAR.Count) bozma KIRMIZI düşürdü"
  if ($kirmizi -ne $MUTASYONLAR.Count) { exit 1 }
  exit 0
} finally { if (Test-Path $gecici) { Remove-Item -LiteralPath $gecici -Recurse -Force } }
