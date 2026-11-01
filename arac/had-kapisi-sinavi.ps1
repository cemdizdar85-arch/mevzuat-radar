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

# ============================================================================
#  01.11.2026 SMMM D7 YOLU (HadYayinNeden 'smmm-…'): had = veri/sinav/had-d7.json (2025 resmî listesi), madde = dayanak + kök,
#  ibare maddeyi adıyla anıyorsa yalnız o madde. Ajan 38'in ölçtüğü iki YANLIŞ DÜŞEN soru meşru vaka (kısaltılmış metin):
#  smmm-w4-yvergi-kolay/kp-03 (GT 577 EK m.153/A 990.000 / 14.000.000) · smmm-4k-a-yvergi-kolay-r10/kp-06 (GT 577 EK m.370 700.000).
#  İHLAL: aynı sorular 2026 tutarıyla (GT 588: 1.200.000 · 870.000) DÜŞMELİ. KGK yolu (kgk-…) DEĞİŞMEMELİ.
#  Vakalar gerçek had-kapisi.ps1 metniyle koşar; MUTASYON: metin tek tek bozulur, her bozmada en az bir vaka KIRMIZI olmalı.
# ============================================================================
$kokDepo = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'mevzuat-degisti.ps1')   # MdAnahtar (KGK yolu kaynak_adlar'ı bununla okur)
$kapiMetin = [IO.File]::ReadAllText((Join-Path $buDizin 'had-kapisi.ps1'), [Text.Encoding]::UTF8)
$D7_VAKALAR = @'
param($kokDepo)
function SQ([string]$soru, [string]$dayanak, [string[]]$ka) { [pscustomobject]@{ soru = $soru; dayanak = $dayanak; kaynak_adlar = $ka; siklar = [pscustomobject]@{ A = 'a'; B = 'b'; C = 'c'; D = 'd'; E = 'e' }; aciklama = '' } }
function V([string]$ad, [bool]$k) { [pscustomobject]@{ ad = $ad; tamam = $k } }
$KA03 = @('VUK (213 s.K.) m.153/A - Teminat uygulaması [1/7]', 'VUK (213 s.K.) m.370 [1/3]', 'VUK (213 s.K.) m.160/A [3/3]', 'GVK (193 s.K.) m.75 - Menkul Sermaye İradı [3/6]', 'VUK GT 577 EK (1.1.2025 had ve tutarlari listesi) m.153/A')
$DY03 = 'VUK m.153/A f.1; 2025 alt ve üst sınır VUK GT 577 EK m.153/A (990.000 ₺ / 14.000.000 ₺)'
$Q03 = { param($alt, $ust) SQ "Münhasıran sahte belge düzenlemek amacıyla mükellefiyet tesis ettirdiği tespit edilen kişi 2025 yılında yeniden işe başlamıştır. 2025 yılı için münhasıran sahte belge düzenleyenlerin yeniden mükellefiyet tesisinde aranan teminatın alt sınırı $alt ₺, üst sınırı $ust ₺'dir. Düzenlediği sahte belgelerde yer alan toplam tutar 6.500.000 ₺'dir. Teminat kaç ₺'dir?" $DY03 $KA03 }
$KA06 = @('VUK (213 s.K.) m.370 [2/3]', 'VUK (213 s.K.) m.160/A [3/3]', 'GVK (193 s.K.) m.9 [5/7]', 'GVK (193 s.K.) gec. m.46')
$DY06 = 'VUK (213 s.K.) m.370/b, 2. ve son cümle; had güncellemesi VUK Genel Tebliği Sıra No: 577'
$Q06 = { param($had) SQ "2025 yılında sahte belge kullanma fiili nedeniyle ön tespit yapılmıştır. Kullanılan sahte belgelerin toplam tutarı 600.000 ₺'dir. 2025 yılı için Vergi Usul Kanunu m.370/b'de belirtilen tutar haddi $had ₺'dir. İzaha davet uygulanabilir mi?" $DY06 $KA06 }
# hakem paketinde ilgisiz madde (GVK m.21) — dayanak GVK m.89 (D7 listesinde yok): kaynak_adlar'ın tamamı alınırsa "gelir" kökü m.21'e bağlanır
$Q89 = SQ "Mükellefin beyan edilen gelirinin %5'i olarak hesaplanan bağış indirim sınırı 50.000 ₺'dir. İndirilebilecek tutar kaç ₺'dir?" 'GVK m.89/1-4' @('GVK (193 s.K.) m.89 [1/4]', 'GVK (193 s.K.) m.21 - Mesken kira istisnası')
$d7 = HadD7HaritaOku $kokDepo
$hg = HadHaritaOku $kokDepo
@(
  V 'D7 listesi: 213|153 = 990.000 + 14.000.000 (GT 577)' ((@($d7['213|153'] | ForEach-Object { $_.tutar }) -join ',') -eq '990000,14000000')
  V 'D7 listesi: 213|370 = 700.000 (2026 tutarı 870.000 YOK)' ((@($d7['213|370'] | ForEach-Object { $_.tutar }) -join ',') -eq '700000')
  V 'D7 listesi: 193|86 beyan sınırı 18.000 (GT 329)' (@($d7['193|86'] | ForEach-Object { $_.tutar }) -contains 18000)
  V 'anahtar kp-03: yalnız 213|153 (kaynak_adlar''daki m.370/160/A/GVK alınmaz)' ((@(HadSmmmAnahtarlar (& $Q03 '990.000' '14.000.000')) -join ',') -eq '213|153')
  V 'anahtar kp-06: yalnız 213|370 (kök "Vergi Usul Kanunu m.370/b" + dayanak)' ((@(HadSmmmAnahtarlar (& $Q06 '700.000')) -join ',') -eq '213|370')
  V 'anahtar: madde yanlış kanuna yazılmaz ("KVK m.32 ve VUK m.370")' ((@(HadMaddeAnahtarlari 'KVK m.32 ve VUK m.370') -join ',') -eq '5520|32,213|370')
  V 'anahtar: tebliğ maddesi kanunun sayılmaz ("GVK GT 329 m.3")' (@(HadMaddeAnahtarlari 'GVK GT 329 m.3').Count -eq 0)
  V 'anahtar: "213 sayılı … 153/A maddesi" + "VUK ek m.1"' ((@(HadMaddeAnahtarlari "213 sayılı Vergi Usul Kanunu'nun 153/A maddesi ile VUK ek m.1") -join ',') -eq '213|153,213|ek1')
  V 'MEŞRU kp-03: 2025 alt/üst sınır 990.000 / 14.000.000 → GEÇER' (-not (HadYayinNeden 'smmm-w4-yvergi-kolay/kp-03' (& $Q03 '990.000' '14.000.000') $kokDepo))
  V 'MEŞRU kp-06: 2025 m.370 haddi 700.000 → GEÇER' (-not (HadYayinNeden 'smmm-4k-a-yvergi-kolay-r10/kp-06' (& $Q06 '700.000') $kokDepo))
  V 'MEŞRU: hakem paketindeki ilgisiz GVK m.21 bağlamaz (dayanak m.89)' (-not (HadYayinNeden 'smmm-x-yvergi/kp-01' $Q89 $kokDepo))
  V 'İHLAL: kp-03 2026 alt sınırı 1.200.000 (GT 588) → DÜŞER' ([bool](HadYayinNeden 'smmm-w4-yvergi-kolay/kp-03' (& $Q03 '1.200.000' '14.000.000') $kokDepo))
  V 'İHLAL: kp-06 2026 m.370 haddi 870.000 (GT 588) → DÜŞER' ([bool](HadYayinNeden 'smmm-4k-a-yvergi-kolay-r10/kp-06' (& $Q06 '870.000') $kokDepo))
  # ibare maddeyi adıyla anıyor → yalnız o madde (sentetik harita: m.153/A ile m.370 aynı soruda)
  $hs = @{ '213|153' = @([pscustomobject]@{ tutar = 990000; baglam = @('temin') }); '213|370' = @([pscustomobject]@{ tutar = 700000; baglam = @('sahte', 'belge') }) }
  V 'madde adı: "VUK m.153/A … sahte belge … sınırı 200.000" m.370 (700.000) ile kıyaslanmaz' (-not (HadIddiasi (SQ "VUK m.153/A uyarınca sahte belge düzenleyenden istenecek teminatın sınırı 200.000 ₺'dir." '' @()) $hs @('213|153', '213|370') -MaddeAdiBaglar))
  V 'madde adı: "VUK m.153/A … alt sınırı 1.300.000" m.153/A ile kıyaslanır → DÜŞER' ([bool](HadIddiasi (SQ "VUK m.153/A uyarınca sahte belge düzenleyenden istenecek teminatın alt sınırı 1.300.000 ₺'dir." '' @()) $hs @('213|153', '213|370') -MaddeAdiBaglar))
  # KGK yolu BİREBİR eski: had-guncel (2026 şerhi) + kaynak_adlar
  V 'KGK yolu değişmedi: kgk- anahtarında 700.000 eski yoldan (had-guncel 870.000) alarm verir' ([bool](HadYayinNeden 'kgk-t1-vergi/kp-01' (& $Q06 '700.000') $kokDepo))
  V 'KGK yolu = eski çağrı (HadIddiasi + had-guncel + kaynak_adlar), kp-03 metni' ((HadYayinNeden 'kgk-t1-vergi/kp-02' (& $Q03 '990.000' '14.000.000') $kokDepo) -eq (HadIddiasi (& $Q03 '990.000' '14.000.000') $hg @($KA03 | ForEach-Object { MdAnahtar "$_" })))
)
'@
function D7Kos([string]$kaynak) { $sb = [scriptblock]::Create($kaynak + "`n" + $D7_VAKALAR.Replace('param($kokDepo)', '')); return @(& { param($kokDepo) . $sb } $kokDepo 3>$null) }
$d7Sonuc = @(D7Kos $kapiMetin)
foreach ($r in $d7Sonuc) { T "D7 $($r.ad)" ([bool]$r.tamam) }
$MUTASYON = @(
  @{ ad = 'SMMM yolu D7 yerine had-guncel (2026) okur'; eski = '$script:HAD_D7 = HadD7HaritaOku $depoKokYolu'; yeni = '$script:HAD_D7 = HadHaritaOku $depoKokYolu' }
  @{ ad = 'SMMM madde anahtarı yine kaynak_adlar''ın tamamı'; eski = '@(HadSmmmAnahtarlar $v) -MaddeAdiBaglar'; yeni = '@(@($v.kaynak_adlar) | ForEach-Object { MdAnahtar "$_" }) -MaddeAdiBaglar' }
  @{ ad = 'madde adı bağı kapalı'; eski = 'if ($MaddeAdiBaglar) {'; yeni = 'if ($false) {' }
  @{ ad = 'SMMM yolu hiç açılmaz (herkes eski yol)'; eski = 'if ("$anahtar".StartsWith(''smmm-'')) {'; yeni = 'if ($false) {' }
  @{ ad = 'KGK da D7 yoluna girer'; eski = 'if ("$anahtar".StartsWith(''smmm-'')) {'; yeni = 'if ($true) {' }
  @{ ad = 'tebliğ anı süzgeci kapalı'; eski = 'if (-not $once.Count -or -not $once[0].no) { continue }'; yeni = 'if (-not $once.Count) { continue }' }
)
foreach ($m in $MUTASYON) {
  if (-not $kapiMetin.Contains($m.eski)) { $dustu.Add("mutasyon kurulamadı (kapı metni değişmiş): $($m.ad)"); continue }
  $kir = @(D7Kos ($kapiMetin.Replace($m.eski, $m.yeni)) | Where-Object { -not $_.tamam }).Count
  T "mutasyon '$($m.ad)' → $kir vaka KIRMIZI" ($kir -ge 1)
}
$top = $gecti + $dustu.Count
Write-Host "KAPI-HAD ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
