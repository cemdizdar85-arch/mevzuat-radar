#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU DÜZELTMESİ — kollektif kâr/zarar (TBK m.623) + stok bağımlılık (ticari alacak)   24.09.2026 · BEDEL 0
#
#  NEDEN (Cem 23–24.09 "1.2.3", SGS etkisi kabul edildi):
#  · "TEORI - Kollektif sirkette kar dagitimi" (edda1c43) iki yanlış kural öğretiyordu: "hüküm yoksa SERMAYE PAYI
#    oranında" ve "emek ortağı aksi kararlaştırılmadıkça ZARARA KATILMAZ". TBK m.623 (ambar 0df932f6): hüküm yoksa
#    EŞİT; emek ortağının zarardan muafiyeti ancak ANLAŞMAYLA geçerli. TTK m.126/227/229'da özel hüküm yok.
#    Bu nottan basılmış yayındaki 8 SMMM sorusunun 7'si yanlış çıktı (23.09 ELLE RET).
#  · "TEORI - Asit-test (likidite) oranlari" (c3538d88) stok bağımlılıkta genel "Alacaklar" düşüyordu; "TEORI - Stok
#    bagimlilik orani" (11aa225f) "Ticari Alacaklar". SMMM komisyon çözümleri 2016/1 + 2017/1 (son 10 yıl) ticari
#    alacağı düşüyor (2010–2014 alacaksızdı). Karar (GM, 24.09): tek formül = ticari alacak.
#  YÖNTEM (arac/teori-gun-tabani-duzelt.ps1 ile aynı): silmeden YERİNDE metin değişikliği. Eski ifade hem depo
#  kaynağında (TAM 1 kez) hem ambar satırında (TAM 1 kez) aranır; biri tutmazsa HİÇBİR ŞEY yazılmaz.
#  Ambara PATCH; eski metin _yerel-veri-kasasi/teori-yedek/ altına; yazdıktan sonra GERİ OKUNUR.
#  ETKİ: soru-dayanak nöbetçisi bu notlara dayanan soruları (SMMM + SGS + KGK) "kaynak değişti" diye inceler.
#  -Uygula yoksa KURU.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'mevzuat-degisti.ps1')
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'

$duzeltmeler = @(
  @{ dosya = 'veri\mevzuat\teori-notlari-20260728.json'; ad = 'TEORI - Kollektif sirkette kar dagitimi'
     eski = 'Sozlesmede hukum yoksa kar ve zarar ortaklar arasinda SERMAYE PAYLARI ORANINDA paylasilir.'
     yeni = 'Sozlesmede hukum yoksa her ortagin kar ve zarardaki payi, katilim payinin DEGERINE VE NITELIGINE BAKILMAKSIZIN ESITTIR (TTK m.126 yollamasiyla TBK m.623/1).' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260728.json'; ad = 'TEORI - Kollektif sirkette kar dagitimi'
     eski = 'EMEK SERMAYESI KOYAN ORTAK: sermaye olarak yalnizca EMEK koyan ortak, aksi kararlastirilmadikca ZARARA KATILMAZ ama KARDAN pay alir - kollektif sirketin en cok sorulan ozelliklerindendir.'
     yeni = 'EMEK SERMAYESI KOYAN ORTAK: bir ortagin zarara katilmayip yalnizca kazanca katilacagina iliskin ANLASMA, ancak katilim payi olarak yalnizca EMEGINI koyan ortak icin GECERLIDIR (TBK m.623/3). Yani emek ortagi da, bu yonde ACIK BIR ANLASMA YOKSA zarara ESIT olarak katilir; ''aksi kararlastirilmadikca zarara katilmaz'' ifadesi YANLISTIR. Kar-zarar paylasimina iliskin karar hakkaniyete aykiriysa mahkemece iptal edilir ve kar-zarar adi sirket hukumlerine gore paylastirilir (TTK m.227/3).' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260728-b.json'; ad = 'TEORI - Asit-test (likidite) oranlari'
     eski = '(KVYK - Hazir Degerler - Menkul Kiymetler - Alacaklar) / Stoklar seklinde kurulur.'
     yeni = '(KVYK - Hazir Degerler - Menkul Kiymetler - Ticari Alacaklar) / Stoklar seklinde kurulur (SMMM komisyon cozumleri 2016/1 ve 2017/1; ticari alacak disindaki alacaklar dusulmez).' }
)
function SayIfade([string]$metin, [string]$ifade) { $n = 0; $i = 0; while (($i = $metin.IndexOf($ifade, $i, [StringComparison]::Ordinal)) -ge 0) { $n++; $i += $ifade.Length }; return $n }
function JsonKacis([string]$s) { return $s.Replace('\', '\\').Replace('"', '\"') }

# 1) ÖN KONTROL — hepsi tutmazsa hiçbir şey yazılmaz
$plan = New-Object System.Collections.Generic.List[object]
foreach ($dz in $duzeltmeler) {
  $yol = Join-Path $depoKok $dz.dosya; $ham = [IO.File]::ReadAllText($yol, [Text.Encoding]::UTF8)
  $nDepo = SayIfade $ham (JsonKacis $dz.eski)
  $satir = @(Invoke-RestMethod -Uri "$tabloAdr`?select=id,metin&kaynak_ad=eq.$([uri]::EscapeDataString($dz.ad))" -Headers $basliklarSb -TimeoutSec 120)
  $nAmbar = $(if ($satir.Count -eq 1) { SayIfade "$($satir[0].metin)" $dz.eski } else { -1 })
  Write-Host ("  {0} | depo {1} · ambar satır {2} · ambarda ifade {3}" -f $dz.ad, $nDepo, $satir.Count, $nAmbar)
  if ($nDepo -ne 1 -or $satir.Count -ne 1 -or $nAmbar -ne 1) { throw "ÖN KONTROL TUTMADI: $($dz.ad) — hiçbir şey yazılmadı" }
  $plan.Add([pscustomobject]@{ dz = $dz; yol = $yol; id = "$($satir[0].id)" })
}
if (-not $Uygula) { "KURU: $($plan.Count) düzeltme hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — depo + ambar, yedek, geri okuma
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
foreach ($p in $plan) {
  $dz = $p.dz
  $ham = [IO.File]::ReadAllText($p.yol, [Text.Encoding]::UTF8)
  [IO.File]::WriteAllText($p.yol, $ham.Replace((JsonKacis $dz.eski), (JsonKacis $dz.yeni)), (New-Object Text.UTF8Encoding $false))
  $ambar = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  $yedekAd = ($dz.ad -replace '[^\w\-]+', '_'); [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"), $ambar, (New-Object Text.UTF8Encoding $false))
  $yeniMetin = $ambar.Replace($dz.eski, $dz.yeni)
  # 24.09: nöbetçi artık teori notlarını izliyor → değişen kısmın belirteçleri yazılır (değmeyen soru çekilmez; bkz. arac/mevzuat-degisti.ps1 MdDegisenKokEkle)
  Write-Host "  belirteç kaydı: $(MdDegisenKokEkle (Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json') "ad|$($dz.ad)" $ambar $yeniMetin (Split-Path -Leaf $PSCommandPath))"
  $govde = ConvertTo-Json -InputObject @{ metin = $yeniMetin } -Compress
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
  $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  if ((SayIfade $geri $dz.eski) -ne 0 -or (SayIfade $geri $dz.yeni) -ne 1 -or $geri.Length -ne $yeniMetin.Length) { throw "GERİ OKUMA TUTMADI: $($dz.ad)" }
  Write-Host "  YAZILDI + geri okundu: $($dz.ad)"
}
"UYGULANDI: $($plan.Count) düzeltme (depo + ambar)"
