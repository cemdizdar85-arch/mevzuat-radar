#requires -Version 5.1
<#
================================================================================
  KAPI-HAD — ÖZ-SINAV   (23.09.2026) · bedel 0
  Kapı (arac/had-kapisi.ps1) bitirme yayın şartında SORU DÜŞÜRÜR. Yanlış alarm = sağlam soru yayından çıkar; kaçırma = yanlış
  yasal tutar yayında kalır. Vakalar 23.09'da ELLE OKUNMUŞ gerçek sorulardan kısaltıldı:
  YAKALAMALI: 862.400 (m.370, madde açıkça anılıyor) · 1.100.000 (m.177/3, bağlam "toplam") · 5.000.000 (m.177, 2 kat hata)
  ÇEKMEMELİ: m.86 beyan haddi 130.000 (m.21 58.000 ile karışmasın) · "varsayılırsa" · senaryo tutarı (sahte belge 900.000) ·
             güncel hadde eşit · had dosyası yok.
  Ölçüm: bütün SMMM (4.862 taslak) eşdeğerlik provasında kapı yalnız bilinen 2 kusuru düşürdü.
  ⛔ REPLİKA YOK: gerçek arac/had-kapisi.ps1 dot-source edilir.
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'had-kapisi.ps1')
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function S([string]$soru) { [pscustomobject]@{ soru = $soru; siklar = [pscustomobject]@{ A = 'a'; B = 'b'; C = 'c'; D = 'd'; E = 'e' }; aciklama = '' } }
# ⚠ H / R PowerShell hazır takma adıdır (Get-History / Invoke-History) — tek harfli işlev adı kullanılmaz
function HadVaka([double]$t, [string[]]$b) { [pscustomobject]@{ tutar = $t; baglam = $b } }
$harita = @{
  '213|370' = @(HadVaka 870000 @('belge', 'sahte', 'yanil', 'muhte', 'kulla'))
  '213|177' = @((HadVaka 2500000 @('hasil', 'katii', 'yilli', 'satis', 'topla', 'alimi')), (HadVaka 1200000 @('hasil', 'gayri', 'safi')), (HadVaka 3500000 @('satis', 'tutar')))
  '193|21'  = @(HadVaka 58000 @('binal', 'meske', 'kiray', 'hasil', 'elde'))
}
function D($soru, [string[]]$an) { return (HadIddiasi $soru $harita $an) }
# --- YAKALAMALI
T '862.400: "m.370/b''de öngörülen tutar" (madde açıkça anılıyor)' ([bool](D (S "Ön tespit yapılmıştır. Sahte fatura tutarı 947.350 ₺'dir. 2026 yılı için VUK m.370/b'de öngörülen tutar 862.400 ₺'dir. Kesilecek ceza kaç ₺'dir?") @('213|370')))
T '1.100.000: "toplamın … belirlenen 1.100.000 ₺ haddini" (bağlam toplam)' ([bool](D (S "Satış ile hizmet birlikte yapılırsa iş hasılatının beş katı ile satış tutarının toplamı esas alınır; bu toplamın 2026 yılı için belirlenen 1.100.000 ₺ haddini aşması halinde işletme I. sınıftır.") @('213|177')))
T '5.000.000: "Karma faaliyette toplam sınır" (2 kat hata, geniş pencere)' ([bool](D (S "Mükellefin yıllık satışı 2.000.000 TL'dir. Karma faaliyette toplam sınır 5.000.000 TL, hizmet hasılatı sınırı 2.400.000 TL'dir.") @('213|177')))
# --- ÇEKMEMELİ
T 'm.86 beyan haddi 130.000 ≠ m.21 mesken istisnası 58.000 (farklı had)' (-not (D (S "2026 yılı mesken istisna haddi 58.000 ₺, tevkifata tabi gayrimenkul sermaye iratları beyan haddi 130.000 ₺'dir.") @('193|21')))
T '"varsayılmıştır" kurgusu (yalnız varsayım kuralı durdurur: had ifadesi + madde anılıyor + pencere içinde)' (-not (D (S "Bu soruda VUK m.177/3 uyarınca sınır 3.400.000 TL olarak varsayılmıştır.") @('213|177')))
T 'aynı cümle varsayımsız → YAKALANIR (kontrol)' ([bool](D (S "Bu soruda VUK m.177/3 uyarınca sınır 3.400.000 TL olarak uygulanır.") @('213|177')))
T 'senaryo tutarı: sahte belge tutarı 900.000 TL (had 870.000 ayrıca doğru verilmiş)' (-not (D (S "Sahte belge tutarı 900.000 TL, alışlar 20.000.000 TL'dir. Yıllık had 870.000 TL'dir. İzaha davet uygulanır mı?") @('213|370')))
T 'güncel hadde eşit tutar' (-not (D (S "2026 yılı mesken istisna haddi 58.000 ₺'dir.") @('193|21')))
T 'had dosyası yok (boş harita) → kapı açık' (-not (HadIddiasi (S "öngörülen tutar 862.400 ₺") @{} @('213|370')))
T 'soru başka maddeye dayanıyor (harita dışı)' (-not (D (S "öngörülen tutar 862.400 ₺") @('6102|11')))
# --- yardımcılar
T 'HadKokler: Türkçe katlama + boş sözcükler atılır' ((@(HadKokler 'Mesken kira hasılatı yılı için tutarı') -join ',') -eq 'meske,kira,hasil')
$top = $gecti + $dustu.Count
Write-Host "KAPI-HAD ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
