#requires -Version 5.1
<#
================================================================================
  BİTİRME (SMMM) KART ÜSTÜ KONU BAŞLIĞI — KARTTAN TÜRETİLİR  (01.11.2026)  bedel 0, model yok

  NİYE (Ajan 30 ölçtü, 01.11): sitedeki Yeterlilik sorusunun kartının üstündeki başlık (paket_soru veri.konu)
    ambardaki ESKİ ÜRETİM PLANI konusundan geliyordu (parti `konu` alanı). Eşlemeli 3.584 sorunun 1.054'ünde başlık
    sorunun okunmuş kartıyla kelime düzeyinde uyumsuz; 10 okumanın 4'ünde başlık gerçekten yanlış ("stopaj beyan
    ödeme" başlıklı amortisman sorusu). 288 başlık ASCII ("olculeri"). Kart doğruluğu ayrıca okundu (Ajan 35, 01.11):
    30 sorunun 0'ında kart açıkça yanlış, 1'inde sınırda; aynı 30'un başlığı 11'inde yanlış/anlamsız.
  KARAR (koordinatör, 01.11): AMBARA DOKUNULMAZ. Başlık yayında karttan türetilir; öncelik:
    1) veri/sinav/smmm-ders-duzelt.json  → `kart`   (yalnız durum='uygula' ve hedef ders = sorunun yayın dersi)
    2) veri/sinav/smmm-banka-esleme.json → `sorular[id].konular[0]`  (yalnız eşleme dersi = sorunun yayın dersi)
    3) ikisi de yoksa ambar `konu` (eski davranış)
  Ders şartı NİYE: kart o dersin konu sözlüğündendir. Ders düzeltmesi kapalıysa (SMMM_DERS_DUZELT_KAPALI=1) soru eski
    dersinde kalır; hedef dersin kartını eski ders sayfasında göstermek yanlış olur → ambar konusuna düşer.
  ⛔ YALNIZ EKRAN BAŞLIĞI: ikiz kapısı (IkizAnlamGrup) ve kaydir-coz'un "sınavda" taraması ambar `konu`sunu kullanmaya
    DEVAM EDER (arac/smmm-kasa-yayin.ps1 aday satırında `konu` = ambar, `baslik` = bu işlev).
  PROVA: $env:SMMM_KONU_KART_KAPALI = '1' → her soru ambar konusunu alır (eski davranış; eşdeğerlik provası içindir).
  01.11 EK (koordinatör onayı, GM 1-2): eşlemesi olmayan soruda 4) ambar konusu harfleri katlanınca yayın dersinin bir KART
    ADINA birebir eşitse kart adı yazılır (kaynak 'kart-adi'; ölçüldü: 151 ambar kaynaklının 86'sı, çoğu s20 partisi
    "gvk › beyanname cesitleri …"). 5) Kalan ambar konusunda TurkceOnar'ın yakalamadığı 9 ASCII kelime BURADA onarılır
    ($script:SMMM_KONU_TR; ortak TurkceOnar sözlüğüne EKLENMEDİ: motor/kaydir-coz.ps1 SGS/KGK sayfalarını da basar, bu oturum
    onlara yazmaz). Kart kaynaklı başlık (kart · esleme · kart-adi) seçim dosyasında konuHam=true taşır → kaydir-coz onu
    TurkceOnar'dan GEÇİRMEZ (kısaltma açımı "Stok maliyet yöntemleri (FIFO vb.)" → "(ilk giren ilk çıkar (FIFO) vb.)" 6 soruyu bozuyordu).
  🚫 GÖRMEZ: kartın kendisinin yanlışlığı (eşleme tek okuyucu; 30 okumada 1 sınırda) · konular[0] dışındaki kart
    (çok kartlı soruda ilk kart; motor/smmm-ders-sira.js "en sık kart"ı kullanır, başlık onu kullanmaz) · kart adına eşit
    olmayan ambar konusunun ANLAMI (yalnız yazımı onarılır) · 9 kelime dışındaki ASCII kelime (TurkceOnar'a kalır).
  ÇAĞIRAN: arac/smmm-kasa-yayin.ps1 · ÖZ-SINAV: arac/smmm-konu-baslik-sinavi.ps1 (dogrula.yml)
================================================================================
#>
$script:SMMM_KONU_KART = $null     # kimlik -> @{ ders; kart }   (ders düzeltmesi, durum='uygula')
$script:SMMM_KONU_ESLEME = $null   # kimlik -> @{ ders; kart }   (banka eşlemesi, konular[0])
$script:SMMM_KONU_KARTADI = $null  # ders -> @{ katlanmış kart adı -> kart adı }   (veri/sinav/smmm-konu-okuma.json konular)
# 01.11 ölçüldü: ambar kaynaklı başlıkta TurkceOnar'dan sonra da ASCII kalan kelimeler (korpusta ASCII biçimi 0 kez geçiyor)
$script:SMMM_KONU_TR = @{ alimi = 'alımı'; kayiplari = 'kayıpları'; cesitleri = 'çeşitleri'; hatalari = 'hataları'; degerlemesi = 'değerlemesi'
  mutabakati = 'mutabakatı'; unsurlari = 'unsurları'; kisitlamasi = 'kısıtlaması'; bolumleri = 'bölümleri' }
function SmmmKonuKatla([string]$t) {
  $k = "$t".ToLower([Globalization.CultureInfo]::GetCultureInfo('tr-TR'))
  foreach ($cift in @(@('ç', 'c'), @('ğ', 'g'), @('ı', 'i'), @('ö', 'o'), @('ş', 's'), @('ü', 'u'), @('â', 'a'), @('î', 'i'), @('û', 'u'))) { $k = $k.Replace($cift[0], $cift[1]) }
  return (($k -replace '\s+', ' ').Trim())
}
function SmmmKonuAsciiOnar([string]$t) {
  return [regex]::Replace("$t", '[A-Za-z]+', { param($m) $kucuk = $m.Value.ToLowerInvariant(); if ($m.Value -ceq $kucuk -and $script:SMMM_KONU_TR.ContainsKey($kucuk)) { $script:SMMM_KONU_TR[$kucuk] } else { $m.Value } })
}
$script:SMMM_KONU_SINAV = $(if ($PSScriptRoot) { Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'veri') 'sinav' } else { '' })   # metinden yüklenince (öz-sınav) çağıran verir
function SmmmKonuKaynakOku() {
  if ($null -ne $script:SMMM_KONU_ESLEME) { return }
  $kartH = @{}; $esH = @{}; $adH = @{}
  if ("$env:SMMM_KONU_KART_KAPALI" -ne '1') {
    $dzYol = Join-Path $script:SMMM_KONU_SINAV 'smmm-ders-duzelt.json'
    if (Test-Path $dzYol) {
      foreach ($k in @((Get-Content $dzYol -Raw -Encoding UTF8 | ConvertFrom-Json).duzelt.PSObject.Properties)) {
        if ("$($k.Value.durum)" -ne 'uygula' -or -not "$($k.Value.kart)".Trim()) { continue }
        $kartH["$($k.Name)"] = @{ ders = "$($k.Value.ders)"; kart = "$($k.Value.kart)".Trim() }
      }
    }
    $esYol = Join-Path $script:SMMM_KONU_SINAV 'smmm-banka-esleme.json'
    if (Test-Path $esYol) {
      foreach ($k in @((Get-Content $esYol -Raw -Encoding UTF8 | ConvertFrom-Json).sorular.PSObject.Properties)) {
        $ilkKart = @(@($k.Value.konular) | Where-Object { "$_".Trim() } | Select-Object -First 1)
        if ($ilkKart.Count) { $esH["$($k.Name)"] = @{ ders = "$($k.Value.ders)"; kart = "$($ilkKart[0])".Trim() } }
      }
    }
    $okYol = Join-Path $script:SMMM_KONU_SINAV 'smmm-konu-okuma.json'
    if (Test-Path $okYol) {
      foreach ($d in @((Get-Content $okYol -Raw -Encoding UTF8 | ConvertFrom-Json).konular.PSObject.Properties)) {
        $dh = @{}
        # biçim: ders -> { "<kart adı>": "<tanım>", … } (01.11 ölçüldü: nesne; dizi biçimi [[ad, tanım], …] de okunur)
        $adlar = $(if ($d.Value -is [System.Management.Automation.PSCustomObject]) { @($d.Value.PSObject.Properties | ForEach-Object { $_.Name }) } else { @($d.Value | ForEach-Object { "$(@($_)[0])" }) })
        foreach ($ad0 in $adlar) { $ad = "$ad0".Trim(); if ($ad) { $dh[(SmmmKonuKatla $ad)] = $ad } }
        $adH["$($d.Name)"] = $dh
      }
    }
  }
  $script:SMMM_KONU_KART = $kartH
  $script:SMMM_KONU_ESLEME = $esH
  $script:SMMM_KONU_KARTADI = $adH
}
# Dönüş: @{ konu = ekran başlığı; kaynak = 'kart' | 'esleme' | 'kart-adi' | 'ambar'; ham = kaydir-coz TurkceOnar'dan geçirmesin mi }
function SmmmKonuBaslik([string]$etiket, [string]$id, [string]$yayinDersi, [string]$ambarKonu) {
  SmmmKonuKaynakOku
  $an = "$etiket/$id"
  $kd = $script:SMMM_KONU_KART[$an]
  if ($kd -and $kd.ders -eq $yayinDersi) { return @{ konu = $kd.kart; kaynak = 'kart'; ham = $true } }
  $es = $script:SMMM_KONU_ESLEME[$an]
  if ($es -and $es.ders -eq $yayinDersi) { return @{ konu = $es.kart; kaynak = 'esleme'; ham = $true } }
  if ("$env:SMMM_KONU_KART_KAPALI" -eq '1') { return @{ konu = $ambarKonu; kaynak = 'ambar'; ham = $false } }   # prova: eski davranış AYNEN
  $dh = $script:SMMM_KONU_KARTADI[$yayinDersi]
  $katlanmis = SmmmKonuKatla $ambarKonu
  if ($dh -and $katlanmis -and $dh.ContainsKey($katlanmis)) { return @{ konu = $dh[$katlanmis]; kaynak = 'kart-adi'; ham = $true } }
  return @{ konu = (SmmmKonuAsciiOnar $ambarKonu); kaynak = 'ambar'; ham = $false }
}
