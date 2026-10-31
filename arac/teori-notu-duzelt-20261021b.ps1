#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU DÜZELTMESİ — DET tanımına borsa şartı   21.10.2026 · BEDEL 0
#
#  NEDEN: KGK Finansal Yönetim "Tahvil turleri ve kara istirakli tahvil" notunda DET tanımı
#    "payları borsalarda işlem gören" şartını düşürüyordu; soru yazarı bu nottan beslendiği için
#    t7 dalgasında DET soruları eksik tanım yüzünden çıkarıldı.
#  RESMÎ KAYNAK (ambarda birebir okundu, "Borclanma Araclari Tebligi (VII-128.8) m.3 [1/2]"):
#    m.3/1-d "Değiştirilebilir tahvil (DET): İhraççı tarafından çıkarılan ve payları borsalarda işlem gören
#    diğer ortaklıklara ait paylarla değiştirme hakkı veren borçlanma aracını,"
#  DEĞİŞİKLİK: yalnız kaynağın sözcükleri ("payları borsalarda işlem gören") eklenir; notun geri kalanı aynen kalır.
#    Nottaki öteki sapmalar (PDT'nin daraltılması, "portföyünde bulunan" eki, tahvilde 365 gün vade, m.3/1-c listesi)
#    yalnız raporlandı, DOKUNULMADI.
#  YÖNTEM: teori-notu-duzelt-20261021.ps1 ile aynı (depo + ambar TAM 1 kez, yedek, geri okuma, değişen-kök belirteci). -Uygula yoksa KURU.
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
  @{ dosya = 'veri\mevzuat\teori-notlari-20260819-kgk3.json'; ad = 'TEORI - Tahvil turleri ve kara istirakli tahvil'
     eski = '(5) DEĞİŞTİRİLEBİLİR TAHVİL (DET) — ihraççının portföyünde bulunan BAŞKA bir ortaklığa ait paylarla değiştirilebilen tahvil;'
     yeni = '(5) DEĞİŞTİRİLEBİLİR TAHVİL (DET) — ihraççının portföyünde bulunan, payları borsalarda işlem gören BAŞKA bir ortaklığa ait paylarla değiştirilebilen tahvil;' }
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
  if ($satir.Count -eq 1 -and (SayIfade $ham (JsonKacis $dz.yeni)) -eq 1 -and (SayIfade "$($satir[0].metin)" $dz.yeni) -eq 1) { Write-Host "    zaten yazılı (depo + ambar) — atlandı"; continue }
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
  # nöbetçi teori notlarını izliyor → değişen kısmın belirteçleri yazılır (bkz. arac/mevzuat-degisti.ps1 MdDegisenKokEkle)
  Write-Host "  belirteç kaydı: $(MdDegisenKokEkle (Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json') "ad|$($dz.ad)" $ambar $yeniMetin (Split-Path -Leaf $PSCommandPath))"
  $govde = ConvertTo-Json -InputObject @{ metin = $yeniMetin } -Compress
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
  $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  $beklenenEski = $(if ($dz.yeni.Contains($dz.eski)) { 1 } else { 0 }); if ((SayIfade $geri $dz.eski) -ne $beklenenEski -or (SayIfade $geri $dz.yeni) -ne 1 -or $geri.Length -ne $yeniMetin.Length) { throw "GERİ OKUMA TUTMADI: $($dz.ad)" }
  Write-Host "  YAZILDI + geri okundu: $($dz.ad)"
}
"UYGULANDI: $($plan.Count) düzeltme (depo + ambar)"
