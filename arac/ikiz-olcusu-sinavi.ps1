#requires -Version 5.1
<#
  IKIZ OLCUSU — OZ-SINAV  (22.09.2026)  bedel 0
  Niye: bu cetvel artik HEM uretimde HEM yayinda kullaniliyor. Bozulursa iki yerde birden
  yalan soyler: uretimde kopya sorulara para oder, yayinda saglam soruyu eler.
  Sinav hem YAKALAMASI gerekeni hem YANLIS ALARM vermemesi gerekeni olcer.
  Ayrica GERCEK VAKA: 22.09'da olculen, uretim cetvelinin kacirdigi bir cift buraya yazildi.
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
. (Join-Path $buDizin 'ikiz-olcusu.ps1')

function P([string]$s, [string]$d) { return (IkizParmak $s $d) }

$gecen = 0; $kalan = New-Object System.Collections.Generic.List[string]
function Vaka([string]$ad, [bool]$cikan, [bool]$beklenen) {
  if ($cikan -eq $beklenen) { $script:gecen++; if (-not $script:Sessiz) { "  OK    [{0,-7}] {1}" -f $(if ($cikan) { 'IKIZ' }else { 'AYRI' }), $ad } }
  else { $script:kalan.Add(("{0} -> beklenen {1}, cikan {2}" -f $ad, $beklenen, $cikan)); if (-not $script:Sessiz) { "  DUSTU [{0,-7}] {1}" -f $(if ($cikan) { 'IKIZ' }else { 'AYRI' }), $ad } }
}
$Sessiz = $Sessiz.IsPresent

# --- YAKALAMASI GEREKENLER ---
$a1 = P 'Isletme 2026 yilinda 100.000 TL tutarinda ticari mal satin almis ve bedelini cekle odemistir. Bu islemin yevmiye kaydi asagidakilerden hangisidir?' '153 Ticari Mallar hesabi borclu, 103 Verilen Cekler hesabi alacakli'
$b1 = P 'Isletme 2026 yilinda 100.000 TL tutarinda ticari mal satin alarak bedelini cek ile odemistir. Buna gore yapilacak yevmiye kaydi asagidakilerden hangisidir?' '153 Ticari Mallar hesabi borclu, 103 Verilen Cekler hesabi alacakli'
Vaka 'ayni soru, kelimeler biraz degismis -> IKIZ' (IkizMi $a1 $b1) $true

# ⭐ GERCEK VAKA (22.09 olcumu): uretim cetveli 0,44 dedi ve gecirdi, yayin cetveli 0,62 deyip eledi.
#   Cetvel artik tek oldugu icin ikisi de IKIZ demeli.
# Olculdu: uclu 0,73 (>=0,60 -> IKIZ) · kelime 0,43 (<0,60 -> eski cetvel KACIRIRDI).
# Fark Turkce ekten geliyor: "tutari/tutarinin", "malin/mallarin", "maliyeti/maliyetinin"
# ayri KELIME sayilir ama harf ucluleri buyuk olcude ayni kalir.
$a2 = P 'Isletmenin donem sonu stok tutari 250.000 TL ve satilan ticari malin maliyeti 1.600.000 TL olduguna gore ticari mal devir hizi kac defadir?' '8 defa'
$b2 = P 'Isletmenin donem sonu stok tutarinin 250.000 TL ve satilan ticari mallarin maliyetinin 1.600.000 TL olduguna gore ticari mal devir hizinin kac defa oldugunu bulunuz.' '8 defa'
Vaka 'GERCEK VAKA SINIFI: kelime cetveli kacirirdi (0,43), uclu cetvel yakalar (0,73) -> IKIZ' (IkizMi $a2 $b2) $true

# --- YANLIS ALARM VERMEMESI GEREKENLER ---
$a3 = P 'Bir isletmenin donem sonu stok tutari 250.000 TL, satilan ticari malin maliyeti 1.600.000 TL ise ticari mal devir hizi kac defadir?' '8 defa'
$b3 = P 'Bir isletmenin donem sonu stok tutari 250.000 TL, satilan ticari malin maliyeti 1.600.000 TL ise ticari mal devir hizi kac defadir?' '6,4 defa'
Vaka 'soru ayni ama DOGRU SIK farkli -> AYRI (iki olcut sarti)' (IkizMi $a3 $b3) $false

$a4 = P 'Asagidakilerden hangisi 6102 sayili Turk Ticaret Kanunu uyarinca anonim sirket genel kurulunun devredilemez gorev ve yetkilerinden biri degildir?' 'Sirketin gunluk isleyisine iliskin kararlarin alinmasi'
$b4 = P 'Asagidakilerden hangisi 6102 sayili Turk Ticaret Kanunu uyarinca anonim sirkette yonetim kurulunun devredilemez gorevlerinden biridir?' 'Muhasebe ve finans denetiminin duzeninin kurulmasi'
Vaka 'ayni kanun, ayni kalip, BASKA organ ve baska cevap -> AYRI' (IkizMi $a4 $b4) $false

$a5 = P 'Kisa vadeli yabancı kaynaklari 400.000 TL, donen varliklari 800.000 TL ve stoklari 300.000 TL olan isletmenin asit-test orani kactir?' '1,25'
$b5 = P 'Toplam aktifi 1.500.000 TL ve net satislari 3.000.000 TL olan isletmenin varlik devir hizi kac defadir?' '2 defa'
Vaka 'ayni ders, bambaska konu -> AYRI' (IkizMi $a5 $b5) $false

# --- SINIR VAKALARI ---
Vaka 'bos metin -> AYRI (cokmeden)' (IkizMi (P '' '') (P '' '')) $false
Vaka 'null parmak -> AYRI (cokmeden)' (IkizMi $null $a1) $false
Vaka 'kendisiyle -> IKIZ' (IkizMi $a1 $a1) $true

# --- ON SUZGEC ESIGI: gercek ikizin altina dusmemeli ---
if ($script:IKIZ_ON_ESIK -le 0.33) { $gecen++; if (-not $Sessiz) { "  OK    on suzgec esigi {0} <= olculen en dusuk ikiz 0,33" -f $script:IKIZ_ON_ESIK } }
else { $kalan.Add("on suzgec esigi $($script:IKIZ_ON_ESIK) cok yuksek: 22.09'da gercek ikizlerin en dususu 0,33 idi, ustundeki esik KACIRMA uretir") }

# --- dogru sik metni cikarma ---
$nes = [pscustomobject]@{ dogru = 'c'; siklar = [pscustomobject]@{ A = 'bir'; B = 'iki'; C = 'uc'; D = 'dort'; E = 'bes' } }
if ((IkizDogruMetin $nes) -eq 'uc') { $gecen++; if (-not $Sessiz) { '  OK    dogru sik metni kucuk harfli kimlikten cikarilir' } }
else { $kalan.Add("IkizDogruMetin yanlis: '$(IkizDogruMetin $nes)'") }
if ((IkizDogruMetin ([pscustomobject]@{ dogru = ''; siklar = $null })) -eq '') { $gecen++; if (-not $Sessiz) { '  OK    siklar yoksa bos doner (cokmez)' } }
else { $kalan.Add('IkizDogruMetin bos nesnede cokuyor/yanlis') }

''
"IKIZ OLCUSU OZ-SINAVI: {0}/11 gecti" -f $gecen
if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
Write-Host 'YESIL' -ForegroundColor Green
exit 0
