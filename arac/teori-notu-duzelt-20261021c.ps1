#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU DÜZELTMESİ — tahvil türleri notu VII-128.8 m.3'e uyduruldu   21.10.2026 · BEDEL 0
#
#  NEDEN: 20261021b (DET borsa şartı) sonrası aynı notta m.3 ile karşılaştırmada 5 sapma raporlandı;
#    kural "kaynak bozuksa önce kaynak onarılır" → hepsi düzeltilir (koordinatör kararı 21.10).
#    (1) DET: m.3'te olmayan "ihraççının portföyünde bulunan" kalkar; "değiştirme hakkı veren" (m.3/1-d).
#    (2) PDT: m.3/1-l'nin iki seçeneği (sermaye artırımı + izahname/ihraç belgesiyle temin edilen ihraççı payları),
#        "dönüştürme hakkı veren"; m.3'te olmayan "vade sonunda ya da belirlenen dönemlerde" kalkar.
#    (3) Tahvil: m.3/1-m tanımı (365 gün veya daha uzun vade, geri ödeme taahhüdü) eklenir.
#    (4) Borçlanma araçları listesi m.3/1-c'ye göre açık liste: m.34 kapsamında Kurulca kabul edilecek araçlar eklenir.
#    (5) Finansman bonosu (m.3/1-b) ve kıymetli maden bonosu (m.3/1-ı) tanımları birebir eklenir.
#  RESMÎ KAYNAK: ambarda "Borclanma Araclari Tebligi (VII-128.8) m.3 [1/2]" ve "[2/2]" birebir okundu.
#    Kaynağın "...aracını" (ifade eder) kipi not cümlesine "...aracı/aracıdır" olarak çekildi; sözcükler korunur.
#  Soru dosyalarında bu cümleleri birebir alıntılayan dayanak bulunmadı (git grep, 21.10).
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

$notAdi = 'TEORI - Tahvil turleri ve kara istirakli tahvil'
$notDosya = 'veri\mevzuat\teori-notlari-20260819-kgk3.json'
$duzeltmeler = @(
  # (1) DET — m.3/1-d
  @{ dosya = $notDosya; ad = $notAdi
     eski = '(5) DEĞİŞTİRİLEBİLİR TAHVİL (DET) — ihraççının portföyünde bulunan, payları borsalarda işlem gören BAŞKA bir ortaklığa ait paylarla değiştirilebilen tahvil;'
     yeni = '(5) DEĞİŞTİRİLEBİLİR TAHVİL (DET) — ihraççı tarafından çıkarılan ve payları borsalarda işlem gören DİĞER ortaklıklara ait paylarla değiştirme hakkı veren borçlanma aracı;' }
  # (2) PDT — m.3/1-l
  @{ dosya = $notDosya; ad = $notAdi
     eski = '(4) PAYA DÖNÜŞTÜRÜLEBİLİR TAHVİL (PDT) — vade sonunda ya da belirlenen dönemlerde ihraççının SERMAYE ARTIRIMI yoluyla çıkarılacak paylarıyla değiştirilebilen tahvil;'
     yeni = '(4) PAYA DÖNÜŞTÜRÜLEBİLİR TAHVİL (PDT) — ihraççı ortaklığın SERMAYE ARTIRIMI suretiyle çıkaracağı paylara veya izahnamede veya ihraç belgesinde belirtilen esaslar çerçevesinde temin edilen ihraççı paylarına dönüştürme hakkı veren borçlanma aracı;' }
  # (3) Tahvil — m.3/1-m (cümle eklenir, eski cümle korunur)
  @{ dosya = $notDosya; ad = $notAdi
     eski = 'zarar etse dahi ihraççı ödeme yükümlülüğünü sürdürür. BAŞLICA TÜRLERİ:'
     yeni = 'zarar etse dahi ihraççı ödeme yükümlülüğünü sürdürür. Borçlanma Araçları Tebliği (VII-128.8) m.3/1-m''ye göre tahvil, ihraççıların bu Tebliğ hükümlerine göre borçlu sıfatıyla düzenleyip sattığı ve nominal değerinin vade tarihinde veya vade tarihine kadar taksitler halinde yatırımcıya geri ödenmesi taahhüdünü içeren, vadesi 365 gün veya daha uzun olan borçlanma aracıdır. BAŞLICA TÜRLERİ:' }
  # (4) açık liste — m.3/1-c  +  (5) finansman bonosu m.3/1-b, kıymetli maden bonosu m.3/1-ı
  @{ dosya = $notDosya; ad = $notAdi
     eski = 'Yürürlükteki Borçlanma Araçları Tebliği (VII-128.8) borçlanma araçlarını tahvil, paya dönüştürülebilir tahvil, değiştirilebilir tahvil, finansman bonosu ve kıymetli maden bonosu olarak sayar; kâra iştirakli tahvil'
     yeni = 'Yürürlükteki Borçlanma Araçları Tebliği (VII-128.8) m.3/1-c borçlanma araçlarını tahvil, paya dönüştürülebilir tahvil, değiştirilebilir tahvil, finansman bonosu, kıymetli maden bonosu ve bu Tebliğin 34 üncü maddesi çerçevesinde niteliği itibari ile borçlanma aracı olduğu Kurulca kabul edilecek sermaye piyasası araçları olarak sayar; liste bu son kalem nedeniyle kapalı değildir. Finansman bonosu (m.3/1-b), ihraççıların bu Tebliğ hükümlerine göre borçlu sıfatıyla düzenleyip sattığı ve nominal değerinin vade tarihinde veya vade tarihine kadar taksitler halinde yatırımcıya geri ödenmesi taahhüdünü içeren, vadesi 30 günden az 364 günden fazla olmayan borçlanma aracıdır. Kıymetli maden bonoları (m.3/1-ı), kıymetli madenin işlem gördüğü borsalara üye olan kıymetli maden aracı kurumlarının belli miktarda kıymetli maden cinsinden ihraç ettikleri ve nominal değerinin vade tarihinde yatırımcıya geri ödenmesi taahhüdünü içeren, vadesi 30 günden az 364 günden fazla olmayan borçlanma aracıdır. Kâra iştirakli tahvil' }
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
  Write-Host ("  {0} | depo {1} · ambar satır {2} · ambarda ifade {3}" -f $dz.eski.Substring(0, 40), $nDepo, $satir.Count, $nAmbar)
  if ($satir.Count -eq 1 -and (SayIfade $ham (JsonKacis $dz.yeni)) -eq 1 -and (SayIfade "$($satir[0].metin)" $dz.yeni) -eq 1) { Write-Host "    zaten yazılı (depo + ambar) — atlandı"; continue }
  if ($nDepo -ne 1 -or $satir.Count -ne 1 -or $nAmbar -ne 1) { throw "ÖN KONTROL TUTMADI: $($dz.ad) — hiçbir şey yazılmadı" }
  $plan.Add([pscustomobject]@{ dz = $dz; yol = $yol; id = "$($satir[0].id)" })
}
if (-not $Uygula) { "KURU: $($plan.Count) düzeltme hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — depo + ambar, yedek, geri okuma (aynı nota sırayla; her adım ambarı yeniden okur)
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
foreach ($p in $plan) {
  $dz = $p.dz
  $ham = [IO.File]::ReadAllText($p.yol, [Text.Encoding]::UTF8)
  [IO.File]::WriteAllText($p.yol, $ham.Replace((JsonKacis $dz.eski), (JsonKacis $dz.yeni)), (New-Object Text.UTF8Encoding $false))
  $ambar = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  $yedekAd = ($dz.ad -replace '[^\w\-]+', '_'); [IO.File]::WriteAllText((Join-Path $yedekKlasor "$yedekAd.metin.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').txt"), $ambar, (New-Object Text.UTF8Encoding $false))
  $yeniMetin = $ambar.Replace($dz.eski, $dz.yeni)
  # nöbetçi teori notlarını izliyor → değişen kısmın belirteçleri yazılır (bkz. arac/mevzuat-degisti.ps1 MdDegisenKokEkle)
  Write-Host "  belirteç kaydı: $(MdDegisenKokEkle (Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json') "ad|$($dz.ad)" $ambar $yeniMetin (Split-Path -Leaf $PSCommandPath))"
  $govde = ConvertTo-Json -InputObject @{ metin = $yeniMetin } -Compress
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
  $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  $beklenenEski = $(if ($dz.yeni.Contains($dz.eski)) { 1 } else { 0 }); if ((SayIfade $geri $dz.eski) -ne $beklenenEski -or (SayIfade $geri $dz.yeni) -ne 1 -or $geri.Length -ne $yeniMetin.Length) { throw "GERİ OKUMA TUTMADI: $($dz.eski.Substring(0, 40))" }
  Write-Host "  YAZILDI + geri okundu: $($dz.eski.Substring(0, 40))"
}
"UYGULANDI: $($plan.Count) düzeltme (depo + ambar)"
