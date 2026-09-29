#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU ÖZEL MALİYET İTFA DÜZELTMESİ   27.09.2026  (BEDEL 0: model çağrısı yok)
#
#  NEDEN (Cem "1.2.3 üçünü de yap"; SGS oturumu bildirdi): 'TEORI - Bakım-onarım giderlerinin maliyet niteliği…'
#  notu "Özel maliyetler kira süresinde, kira süresi beş yıldan uzunsa beş yılda eşit tutarlarla itfa edilir" diyordu.
#  VUK m.327 (ambardan okundu 27.09; "Değişik: 3/7/2005-5398/24 md."): özel maliyet bedelleri "kira veya işletme hakkı
#  süresine göre eşit yüzdelerle itfa edilir" — beş yıl sınırı yok. Not üreticinin kaynak paketine girer; eski kural
#  yerel kasada SGS'de 11, SMMM'de 15 soruda görüldü (KAPI-OM ölçümü, arac/ozel-maliyet-kapisi.ps1). Kaçının bu nottan,
#  kaçının THP 264 metninden geldiği ÖLÇÜLMEDİ.
#  'THP 264 - ÖZEL MALİYETLER' (MSUGT metni) DEĞİŞTİRİLMEZ: resmî tebliğin kendi cümlesidir; onu üretimde KAPI-OM tutar.
#
#  YÖNTEM: arac/teori-gun-tabani-duzelt.ps1 ile aynı — silmeden, YERİNDE metin değişikliği; eski ifade repo kaynağında
#  TAM 1 kez ve ambar satırında aranır, biri tutmazsa ATLANIR. Ambara PATCH, yedek _yerel-veri-kasasi/teori-yedek/,
#  yazdıktan sonra GERİ OKUNUR. -Uygula yoksa KURU.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\ozel-maliyet-kapisi.ps1')
. (Join-Path $depoKok 'arac\mevzuat-degisti.ps1')   # MdDegisenKokEkle: nöbetçi yalnız belirtece değen soruyu çeker
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$yedekKlasor = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\teori-yedek'

$DOSYA = 'teori-notlari-20260909-sgs-maliyet-kayit.json'
$ESKI = 'Özel maliyetler kira süresinde, kira süresi beş yıldan uzunsa beş yılda eşit tutarlarla itfa edilir;'
# Yeni cümle, dayanak nöbetçisinin ayırt edici belirteçleri AZ olsun diye eski cümleye yakın tutuldu. ÖLÇÜLDÜ 27.09 (bu nota dayanan
#   131 soru, yerel kasa): "VUK m.327'ye göre … işletme hakkı … 5398 … 2005" yazımı 15 belirteç üretip 131'in 131'ini yayından
#   çektirecekti ('işletme', 'yapılır'); bu yazım tek belirteç ('dahi') üretir, çekilen 0. Eski kuralı anlatan sorular KAPI-OM'da düşer.
$YENI = 'Özel maliyetler kira süresinde, kira süresi beş yıldan uzunsa dahi kira süresinde eşit tutarlarla itfa edilir;'
if ($YENI -match '["\\]') { throw 'yeni metinde JSON kaçış karakteri var' }

function SayIfade([string]$metin, [string]$ifade) { return ([regex]::Matches($metin, [regex]::Escape($ifade))).Count }

$yolDosya = Join-Path $depoKok "veri\mevzuat\$DOSYA"
$bayt = [IO.File]::ReadAllBytes($yolDosya)
$bomVar = ($bayt.Length -ge 3 -and $bayt[0] -eq 0xEF -and $bayt[1] -eq 0xBB -and $bayt[2] -eq 0xBF)
$hamMetin = [Text.Encoding]::UTF8.GetString($bayt, $(if ($bomVar) { 3 } else { 0 }), $bayt.Length - $(if ($bomVar) { 3 } else { 0 }))
$belge = @((ConvertFrom-Json $hamMetin).belgeler) | Where-Object { "$($_.metin)".Contains($ESKI) }
if (@($belge).Count -ne 1) { throw "repo dosyasında eski cümleyi taşıyan belge $(@($belge).Count) (1 olmalı)" }
$ad = "$($belge[0].kaynak_ad)"
$repoEski = SayIfade $hamMetin $ESKI

$satirlar = @(foreach ($o in (Invoke-RestMethod -Uri ("$tabloAdr`?select=id,kaynak_ad,metin&kaynak_ad=eq." + [uri]::EscapeDataString($ad)) -Headers $basliklarSb -TimeoutSec 120)) { $o })
$ambarMetin = $(if ($satirlar.Count -eq 1) { "$($satirlar[0].metin)" } else { '' })
$ambarEski = SayIfade $ambarMetin $ESKI

if ($satirlar.Count -ne 1) { Write-Host "ATLANDI: ambarda $($satirlar.Count) satır"; exit 1 }
if ($repoEski -eq 0 -and $ambarEski -eq 0) { Write-Host 'ZATEN DÜZELTİLMİŞ'; exit 0 }
if ($repoEski -ne 1 -or $ambarEski -ne 1) { Write-Host "ATLANDI: repo eski $repoEski · ambar eski $ambarEski (ikisi de 1 olmalı)"; exit 1 }
$yeniAmbar = $ambarMetin.Replace($ESKI, $YENI)
$omKalan = @(OzelMaliyetKapisi ([pscustomobject]@{ hap = $yeniAmbar })).Count
Write-Host "repo eski $repoEski · ambar eski $ambarEski · düzeltme sonrası KAPI-OM kalan cümle $omKalan"
if ($omKalan) { throw 'düzeltilmiş notta KAPI-OM hâlâ eski kural görüyor — yazılmadı' }
if (-not $Uygula) { Write-Host "`nKURU KOŞU - hiçbir şey yazılmadı. Uygulamak için: -Uygula" -ForegroundColor Yellow; exit 0 }

New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
[IO.File]::WriteAllText((Join-Path $yedekKlasor "ozel-maliyet-teori.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"), $ambarMetin, [Text.UTF8Encoding]::new($false))
Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($satirlar[0].id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ metin = $yeniAmbar } -Compress))) -TimeoutSec 120 | Out-Null
$geri = "$(@(foreach ($o in (Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($satirlar[0].id)" -Headers $basliklarSb -TimeoutSec 120)) { $o })[0].metin)"
if ((SayIfade $geri $ESKI) -ne 0 -or (SayIfade $geri $YENI) -ne 1 -or $geri.Length -ne $yeniAmbar.Length) { throw "GERİ OKUMA TUTMADI — yedek: $yedekKlasor" }
$baytYeni = [Text.Encoding]::UTF8.GetBytes($hamMetin.Replace($ESKI, $YENI))
if ($bomVar) { $baytYeni = [byte[]](@(0xEF, 0xBB, 0xBF) + $baytYeni) }
[IO.File]::WriteAllBytes($yolDosya, $baytYeni)
Write-Host "  belirteç kaydı: $(MdDegisenKokEkle (Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json') "ad|$ad" $ambarMetin $yeniAmbar (Split-Path -Leaf $PSCommandPath))"
Write-Host 'DÜZELTİLDİ (ambar geri okundu + repo kaynağı)'
