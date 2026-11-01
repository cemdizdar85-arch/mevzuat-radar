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
  🚫 GÖRMEZ: kartın kendisinin yanlışlığı (eşleme tek okuyucu; 30 okumada 1 sınırda) · konular[0] dışındaki kart
    (çok kartlı soruda ilk kart; motor/smmm-ders-sira.js "en sık kart"ı kullanır, başlık onu kullanmaz) · eşlemesi olmayan
    sorunun ASCII ambar konusu (kaydir-coz TurkceOnar'a kalır).
  ÇAĞIRAN: arac/smmm-kasa-yayin.ps1 · ÖZ-SINAV: arac/smmm-konu-baslik-sinavi.ps1 (dogrula.yml)
================================================================================
#>
$script:SMMM_KONU_KART = $null     # kimlik -> @{ ders; kart }   (ders düzeltmesi, durum='uygula')
$script:SMMM_KONU_ESLEME = $null   # kimlik -> @{ ders; kart }   (banka eşlemesi, konular[0])
$script:SMMM_KONU_SINAV = $(if ($PSScriptRoot) { Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'veri') 'sinav' } else { '' })   # metinden yüklenince (öz-sınav) çağıran verir
function SmmmKonuKaynakOku() {
  if ($null -ne $script:SMMM_KONU_ESLEME) { return }
  $kartH = @{}; $esH = @{}
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
  }
  $script:SMMM_KONU_KART = $kartH
  $script:SMMM_KONU_ESLEME = $esH
}
# Dönüş: @{ konu = ekran başlığı; kaynak = 'kart' | 'esleme' | 'ambar' }
function SmmmKonuBaslik([string]$etiket, [string]$id, [string]$yayinDersi, [string]$ambarKonu) {
  SmmmKonuKaynakOku
  $an = "$etiket/$id"
  $kd = $script:SMMM_KONU_KART[$an]
  if ($kd -and $kd.ders -eq $yayinDersi) { return @{ konu = $kd.kart; kaynak = 'kart' } }
  $es = $script:SMMM_KONU_ESLEME[$an]
  if ($es -and $es.ders -eq $yayinDersi) { return @{ konu = $es.kart; kaynak = 'esleme' } }
  return @{ konu = $ambarKonu; kaynak = 'ambar' }
}
