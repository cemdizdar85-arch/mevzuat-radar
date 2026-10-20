#requires -Version 5.1
# ============================================================================
#  TEORİ NOTU DÜZELTMESİ — FY/MTA notlarında 5 çelişki   21.10.2026 · BEDEL 0
#
#  NEDEN (Cem 20.10 "2 yap" — KGK t6 okuyucularının ambar bulguları, ölçüm 21.10 aae50059 scratchpad olcum/AMBAR-ONARIM-OLCUM.md):
#    (1) faaliyet döngüsü "üç temel süre" (yanlış; = stok + tahsil süresi; ödeme düşülünce nakit döngüsü) — alıntılayan soru 0 → CÜMLE DEĞİŞİR.
#    (2) dış iskonto matrahı nominal/vade sonu çelişkisi · (4) "Payda SATIŞ değil" (pay kısmı) · (5) reeskont "iç iskonto ile hesaplanır"
#        (VUK m.281 yöntem belirlemez) · (6) stoklar "en az likit" (GAAG hiç nakde dönmez) — bu cümleleri birebir alıntılayan
#        21 hazır + 4 kasa sorusu var → ESKİ CÜMLE KORUNUR, arkasına AÇIKLAYICI CÜMLE EKLENİR (dayanak alıntıları kırılmaz).
#    (3) adillik tanımı: resmî SPK ilke metni ambarda yok → DOKUNULMADI.
#  YÖNTEM: teori-notu-duzelt-20260925.ps1 ile aynı (depo + ambar TAM 1 kez, yedek, geri okuma, değişen-kök belirteci). -Uygula yoksa KURU.
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
  @{ dosya = 'veri\mevzuat\teori-ekler-2-20260828.json'; ad = 'Teori Notu - ortalama tahsilat ve odeme suresi formulleri'
     eski = 'döngüsü, üç temel süre üzerinden hesaplanır ve nakit yönetimi sorularının omurgasını oluşturur.'
     yeni = 'döngüsü stokta kalma süresi ile ortalama tahsilat süresinin toplamıdır; bundan ortalama ödeme süresi düşülünce nakit (dönüşüm) döngüsü bulunur. Bu süreler nakit yönetimi sorularının omurgasını oluşturur.' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260909-sgs-fmuh-kayit.json'; ad = 'TEORI - Alacak senedi iskontosu: senet iskonto ettirme kaydı (121 Alacak Senetleri, 102 Bankalar, 780 Finansman Giderleri) ve iskonto tutarı hesabı'
     eski = 'İskonto tutarı = Nominal değer × yıllık faiz oranı × vadeye kalan gün / 360 (soru 365 gün diyorsa 365).'
     yeni = 'İskonto tutarı = Nominal değer × yıllık faiz oranı × vadeye kalan gün / 360 (soru 365 gün diyorsa 365). Faizsiz senette nominal değer vade sonu değerine eşittir; faizli senette dış iskonto vade sonu değer (nominal + vadeye kadar işleyen faiz) üzerinden hesaplanır.' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260909-sgs-fmuh-kayit.json'; ad = 'TEORI - Borç senedi reeskontu ve iskontosu: 322 Borç Senetleri Reeskontu, 647 Reeskont Faiz Gelirleri, izleyen dönemde 657 ile iptal; iç iskonto formülü'
     eski = '(2) Reeskont iç iskonto ile hesaplanır; bankanın senet iskontosu (dış iskonto, 780) ayrı işlemdir.'
     yeni = '(2) Reeskont iç iskonto ile hesaplanır; bankanın senet iskontosu (dış iskonto, 780) ayrı işlemdir. VUK m.281 yalnız değerleme gününün değerine indirgemeyi ister, yöntem belirlemez; iç iskonto uygulamada yaygındır, soru hangi yöntemi istiyorsa o kullanılır.' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260909-sgs-mta-oranlar.json'; ad = 'TEORI - Faaliyet (devir hızı) oranları: aktif devir hızı, stok devir hızı ve stokta kalma süresi, alacak devir hızı ve tahsil süresi, net çalışma sermayesi devir hızı'
     eski = 'Payda SATIŞ değil SATIŞLARIN MALİYETİ kullanılır, çünkü stoklar maliyet değeriyle izlenir.'
     yeni = 'Payda SATIŞ değil SATIŞLARIN MALİYETİ kullanılır, çünkü stoklar maliyet değeriyle izlenir. (Buradaki "payda" pay kısmında demektir: SATIŞLARIN MALİYETİ kesrin payındadır, paydası ortalama stoktur.)' }
  @{ dosya = 'veri\mevzuat\teori-notlari-20260909-sgs-mta-oranlar.json'; ad = 'TEORI - Likidite oranları: cari oran, asit-test (likidite) oranı, nakit oranı, net çalışma sermayesi; hesaplanışı, standart değerleri ve yorumu'
     eski = 'en az likit kalemi olduğu için paydan çıkarılır; bazı kaynaklar gelecek aylara ait giderleri ve diğer dönen varlıkları da düşer.'
     yeni = 'en az likit kalemi olduğu için paydan çıkarılır; bazı kaynaklar gelecek aylara ait giderleri ve diğer dönen varlıkları da düşer. Stoklar nakde dönüşen dönen varlıkların en az likit olanıdır; gelecek aylara ait giderler ise hiç nakde dönüşmez, bu yüzden dar kapsamlı asit-testte onlar da düşülür.' }
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
  $ekleme = $dz.yeni.Contains($dz.eski)
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
  # 24.09: nöbetçi artık teori notlarını izliyor → değişen kısmın belirteçleri yazılır (değmeyen soru çekilmez; bkz. arac/mevzuat-degisti.ps1 MdDegisenKokEkle)
  Write-Host "  belirteç kaydı: $(MdDegisenKokEkle (Join-Path $depoKok 'veri\mevzuat\_degisen-kokler.json') "ad|$($dz.ad)" $ambar $yeniMetin (Split-Path -Leaf $PSCommandPath))"
  $govde = ConvertTo-Json -InputObject @{ metin = $yeniMetin } -Compress
  Invoke-RestMethod -Method Patch -Uri "$tabloAdr`?id=eq.$($p.id)" -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
  $geri = "$((Invoke-RestMethod -Uri "$tabloAdr`?select=metin&id=eq.$($p.id)" -Headers $basliklarSb -TimeoutSec 120)[0].metin)"
  $beklenenEski = $(if ($dz.yeni.Contains($dz.eski)) { 1 } else { 0 }); if ((SayIfade $geri $dz.eski) -ne $beklenenEski -or (SayIfade $geri $dz.yeni) -ne 1 -or $geri.Length -ne $yeniMetin.Length) { throw "GERİ OKUMA TUTMADI: $($dz.ad)" }
  Write-Host "  YAZILDI + geri okundu: $($dz.ad)"
}
"UYGULANDI: $($plan.Count) düzeltme (depo + ambar)"
