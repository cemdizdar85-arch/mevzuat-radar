#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU DÜZELTMESİ — Türkçe pekiştirmelerin yazımı   25.09.2026 · BEDEL 0
#
#  NEDEN (Cem 25.09 "gm önerilerini yap" / "devam et"): "TEORI - Turkce: buyuk harflerin ve yazimin kurallari" notu
#    "PEKISTIRME ve IKILEMELER ayri yazilir" diyordu; TDK'ya göre ikilemeler ayrı, PEKİŞTİRMELER BİTİŞİK (masmavi, yemyeşil).
#    K4 Türkçe yazarı ölçtü (aynı ambarın öteki notu "bitişik" diyor, iki not çelişiyordu). Notu anan kasada 7 SGS sorusu var;
#    "pekiştirme" geçen tek soru (sgs-d4-turkce-kolay-r2/kp-01) başka nedenle (iki doğru cevap) elle ret listesinde.
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
  @{ dosya = 'veri\mevzuat\teori-notlari-20260728-e-genelkultur.json'; ad = 'TEORI - Turkce: buyuk harflerin ve yazimin kurallari'
     eski = 'PEKISTIRME ve IKILEMELER ayri yazilir.'
     yeni = 'IKILEMELER ayri yazilir (yavas yavas, ic ice); PEKISTIRMELER ise BITISIK yazilir (masmavi, yemyesil, apacik, bembeyaz) - TDK Yazim Kilavuzu.' }
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
