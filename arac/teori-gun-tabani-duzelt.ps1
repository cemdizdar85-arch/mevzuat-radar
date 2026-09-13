#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU GÜN TABANI DÜZELTMESİ   13.09.2026  (BEDEL 0: model çağrısı yok)
#
#  NEDEN (Cem 13.09 "1.2.3 üçünü de yap", GM incelemesi smmm-gm-p1 FTA sorusu):
#  Ambardaki teori notları süre hesabında birbirini tutmuyordu: 5 not "süre = 365 / devir
#  hızı" diye SABİT kural yazıyor, 5 not 360 diyor ya da "soru hangisini verirse" diyor.
#  Üretici bu notlarla soru yazınca taban soruda verilmeden 365 ya da 360 kullanılıyordu.
#  ÖLÇÜM (ambar çıkmışları, tur=cikmis-soru, 253 belge / 20.851 soru): tabanı açıkça
#  yazan 51 ifadenin 47'si 360 gün (SMMM 3, SGS 10, KGK 34), 4'ü 365 gün (yalnız KGK 2025).
#  KURAL: yıl gün sayısı sorudan okunur; çıkmışlarda baskın taban 360'tır.
#  Aynı kural üreticide KAPI-GT olarak kapıdır (motor/kapi-cikmis-gun.ps1).
#
#  YÖNTEM: silmeden, YERİNDE metin değişikliği. Her düzeltme için eski ifade hem repo
#  kaynağında (veri/mevzuat/*.json, ham metinde TAM 1 kez) hem ambar satırında (kaynak_ad
#  eşleşmesi) aranır; biri tutmazsa o düzeltme ATLANIR ve söylenir. Ambara PATCH (DELETE+
#  POST değil: teori-notu-uret -YalnizYukle ASCII notları "Türkçe harf yok" diye atlıyor).
#  Eski metin _yerel-veri-kasasi/teori-yedek/ altına yedeklenir; yazdıktan sonra GERİ OKUNUR.
#  -Uygula yoksa KURU. Rapor (yalnız sayılar): veri/teori-gun-tabani-duzelt-rapor.json
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'

$mtaAd = 'TEORI - Faaliyet (devir hızı) oranları: aktif devir hızı, stok devir hızı ve stokta kalma süresi, alacak devir hızı ve tahsil süresi, net çalışma sermayesi devir hızı'
$DUZELTMELER = @(
  @{ dosya = 'teori-notlari-20260909-sgs-mta-oranlar.json'; ad = $mtaAd; alan = 'metin'
     eski = 'STOKTA KALMA SÜRESİ = 365 / Stok Devir Hızı;'
     yeni = 'STOKTA KALMA SÜRESİ = Yıl gün sayısı / Stok Devir Hızı (yıl gün sayısı soruda verilir; çıkmış sınavlarda çoğunlukla 360);' },
  @{ dosya = 'teori-notlari-20260909-sgs-mta-oranlar.json'; ad = $mtaAd; alan = 'metin'
     eski = 'ALACAK TAHSİL SÜRESİ = 365 / Alacak Devir Hızı.'
     yeni = 'ALACAK TAHSİL SÜRESİ = Yıl gün sayısı / Alacak Devir Hızı (soruda verilen taban; çoğunlukla 360).' },
  @{ dosya = 'teori-notlari-20260909-sgs-mta-oranlar.json'; ad = $mtaAd; alan = 'metin'
     eski = 'stokta kalma süresi 365 / 12 = 30,4 gün.'
     yeni = 'soru yılı 360 gün kabul ediyorsa stokta kalma süresi 360 / 12 = 30 gün, 365 gün kabul ediyorsa 365 / 12 = 30,4 gün.' },
  @{ dosya = 'teori-notlari-20260909-sgs-mta-oranlar.json'; ad = $mtaAd; alan = 'metin'
     eski = '(2) Süre sorulduğunda 365 devir hızına BÖLÜNÜR, çarpılmaz.'
     yeni = '(2) Süre sorulduğunda yıl gün sayısı devir hızına BÖLÜNÜR, çarpılmaz; 360 mı 365 mi soru kökünden okunur (çıkmış ölçümü 13.09.2026: tabanı yazan 51 ifadenin 47 tanesi 360, 4 tanesi 365 gün).' },
  @{ dosya = 'teori-notlari-20260909-sgs-mta-oranlar.json'; ad = $mtaAd; alan = 'baslik'
     eski = 'süre ise 365 günün devir hızına bölünmesiyle bulunur'
     yeni = 'süre ise soruda verilen yıl gün sayısının (çoğunlukla 360) devir hızına bölünmesiyle bulunur' },
  @{ dosya = 'teori-notlari-20260728.json'; ad = 'TEORI - Stokta kalma suresi ve stok devir hizi'; alan = 'metin'
     eski = 'STOKTA KALMA SURESI (stok devir suresi) = 365 / Stok Devir Hizi. Esdeger yazilis: Stokta Kalma Suresi = (Ortalama Stok x 365) / SMM.'
     yeni = 'STOKTA KALMA SURESI (stok devir suresi) = Yil gun sayisi / Stok Devir Hizi; yil gun sayisi soruda verilir (cikmis sinavlarda cogunlukla 360, bazen 365). Esdeger yazilis: Stokta Kalma Suresi = (Ortalama Stok x Yil gun sayisi) / SMM.' },
  @{ dosya = 'teori-notlari-20260728-c.json'; ad = 'TEORI - Devir hizlari ve kaldiractan oz kaynagin bulunmasi'; alan = 'metin'
     eski = 'SURE KARSILIKLARI: 365 / ilgili devir hizi.'
     yeni = 'SURE KARSILIKLARI: Yil gun sayisi / ilgili devir hizi (yil gun sayisi soruda verilir; cikmis sinavlarda cogunlukla 360).' },
  @{ dosya = 'teori-notlari-20260728-d.json'; ad = 'TEORI - Ortalama stok ve donem ici (ceyreklik) veriyle devir hizi'; alan = 'metin'
     eski = 'yillik veri kullaniliyorsa 365 gun bolunur.'
     yeni = 'yillik veri kullaniliyorsa soruda verilen yil gun sayisi (cogunlukla 360; soru 365 derse 365) bolunur.' },
  @{ dosya = 'teori-notlari-20260801-fy.json'; ad = 'Teori Notu - finansal analiz oranlari'; alan = 'metin'
     eski = 'devir süreleri 365/devir hızıdır;'
     yeni = 'devir süreleri yıl gün sayısı/devir hızıdır (gün sayısı soruda verilir, çıkmış sınavlarda çoğunlukla 360);' }
)

function SayIfade([string]$metin, [string]$ifade) { if (-not $ifade) { return 0 }; return ([regex]::Matches($metin, [regex]::Escape($ifade))).Count }

$sonuc = New-Object System.Collections.Generic.List[object]
foreach ($dz in $DUZELTMELER) {
  if ($dz.yeni -match '["\\]') { throw "yeni metinde JSON kaçış karakteri var: $($dz.yeni)" }
  $yolDosya = Join-Path $depoKok "veri\mevzuat\$($dz.dosya)"
  $bayt = [IO.File]::ReadAllBytes($yolDosya)
  $bomVar = ($bayt.Length -ge 3 -and $bayt[0] -eq 0xEF -and $bayt[1] -eq 0xBB -and $bayt[2] -eq 0xBF)
  $hamMetin = [Text.Encoding]::UTF8.GetString($bayt, $(if ($bomVar) { 3 } else { 0 }), $bayt.Length - $(if ($bomVar) { 3 } else { 0 }))
  $repoEski = SayIfade $hamMetin $dz.eski; $repoYeni = SayIfade $hamMetin $dz.yeni

  $adrSatir = "$tabloAdr`?select=id,kaynak_ad,metin,baslik&kaynak_ad=eq." + [uri]::EscapeDataString($dz.ad)
  $hamYanit = Invoke-RestMethod -Uri $adrSatir -Headers $basliklarSb -TimeoutSec 120
  $satirlar = @(foreach ($o in $hamYanit) { $o })
  $ambarAlan = $(if ($satirlar.Count -eq 1) { "$($satirlar[0].($dz.alan))" } else { '' })
  $ambarEski = SayIfade $ambarAlan $dz.eski; $ambarYeni = SayIfade $ambarAlan $dz.yeni

  $karar = ''
  if ($satirlar.Count -ne 1) { $karar = "ATLANDI: ambarda $($satirlar.Count) satır" }
  elseif ($repoEski -eq 0 -and $ambarEski -eq 0 -and $repoYeni -ge 1 -and $ambarYeni -ge 1) { $karar = 'ZATEN DÜZELTİLMİŞ' }
  elseif ($repoEski -ne 1) { $karar = "ATLANDI: repo dosyasında eski ifade $repoEski kez (1 olmalı)" }
  elseif ($ambarEski -lt 1) { $karar = 'ATLANDI: ambar metninde eski ifade yok (repo ile ambar ayrışmış)' }
  elseif (-not $Uygula) { $karar = 'KURU: düzeltilecek' }
  else {
    New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
    $yedekAd = ($dz.ad -replace '[^\w\-]+', '_'); if ($yedekAd.Length -gt 80) { $yedekAd = $yedekAd.Substring(0, 80) }
    [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.$($dz.alan).$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"), $ambarAlan, [Text.UTF8Encoding]::new($false))
    $yeniAlan = $ambarAlan.Replace($dz.eski, $dz.yeni)
    $govde = @{}; $govde[$dz.alan] = $yeniAlan
    $adrPatch = "$tabloAdr`?id=eq.$($satirlar[0].id)"
    Invoke-RestMethod -Method Patch -Uri $adrPatch -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Compress))) -TimeoutSec 120 | Out-Null
    $geriYanit = Invoke-RestMethod -Uri "$tabloAdr`?select=metin,baslik&id=eq.$($satirlar[0].id)" -Headers $basliklarSb -TimeoutSec 120
    $geri = @(foreach ($o in $geriYanit) { $o })
    $geriAlan = "$($geri[0].($dz.alan))"
    if ((SayIfade $geriAlan $dz.eski) -ne 0 -or (SayIfade $geriAlan $dz.yeni) -lt 1 -or $geriAlan.Length -ne $yeniAlan.Length) { throw "GERİ OKUMA TUTMADI: $($dz.ad) [$($dz.alan)] — yedek: $yedekKlasor" }
    $hamYeni = $hamMetin.Replace($dz.eski, $dz.yeni)
    $baytYeni = [Text.Encoding]::UTF8.GetBytes($hamYeni)
    if ($bomVar) { $baytYeni = [byte[]](@(0xEF, 0xBB, 0xBF) + $baytYeni) }
    [IO.File]::WriteAllBytes($yolDosya, $baytYeni)
    $karar = 'DÜZELTİLDİ (ambar geri okundu + repo kaynağı)'
  }
  Write-Host ("  {0} · {1} [{2}] · repo eski {3} · ambar eski {4}" -f $karar, $dz.dosya, $dz.alan, $repoEski, $ambarEski)
  $sonuc.Add([ordered]@{ dosya = $dz.dosya; kaynak_ad = $dz.ad; alan = $dz.alan; karar = ($karar -replace '^KURU: .*', 'kuru') })
}
if ($Uygula) {
  RaporYaz -Hedef (Join-Path $depoKok 'veri\teori-gun-tabani-duzelt-rapor.json') -Nesne ([ordered]@{ olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); duzeltme = $sonuc.Count; sonuc = @($sonuc.ToArray()) })
} else { Write-Host "`nKURU KOŞU - hiçbir şey yazılmadı. Uygulamak için: -Uygula" -ForegroundColor Yellow }
