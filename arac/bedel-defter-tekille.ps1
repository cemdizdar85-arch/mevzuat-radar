#requires -Version 5.1
<#
================================================================================
  BEDEL DEFTERİ TEKİLLEŞTİRME — veri/fabrika/bedel-kayit.jsonl   19.09.2026
  Bedel 0. Hiçbir harcama silinmez; yalnız BİREBİR AYNI satırın kopyaları düşer.

  NİYE (ölçüldü 19.09): eylül defteri 22.644 satır / 26.111,82 USD gösteriyordu;
  tekil (zaman + etiket + tutar) 3.399 satır / 2.833,84 USD — defter 9,2 KAT
  şişmişti. Ambarda aynı satırın 31 kopyası vardı (hepsi yazan='yerel-GK').
  Kök neden arac/bedel-senkron.ps1'de saat dilimi karşılaştırmasıydı; orada
  onarıldı. Bu betik ŞİŞMİŞ DOSYAYI temizler (kural: kapı eklendiyse veri tazelenir).

  ⚠ NİYE GÜVENLİ: aynı dakikada, aynı etikete, aynı tutarın iki kez yazılması
  üretim hattında mümkün değil (bkz. arac/bedel-senkron.ps1 tekillik kuralı:
  "aynı saniyede aynı partiye aynı tutar iki kez yazılmaz"). Farklı tutar ya da
  farklı dakika taşıyan her satır AYNEN kalır — iki kez koşan parti iki satırdır.

  ⚠ AMBAR TEMİZLİĞİ AYRI İŞTİR: bu betik yalnız yerel dosyaya dokunur. Ambardaki
  (public.bedel_kaydi) kopyaları silmek geri alınamaz; Cem'in onayıyla yapılır.

  KULLANIM
    powershell -NoProfile -File arac/bedel-defter-tekille.ps1          # ölç (kuru)
    powershell -NoProfile -File arac/bedel-defter-tekille.ps1 -Yaz     # yedekle + temizle
================================================================================
#>
param([switch]$Yaz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$defter = Join-Path $depoKok 'veri\fabrika\bedel-kayit.jsonl'
if (-not (Test-Path $defter)) { throw "defter yok: $defter" }

function Anh([string]$s) {
  $z = [regex]::Match($s, '"zaman"\s*:\s*"([^"]*)"')
  $e = [regex]::Match($s, '"etiket"\s*:\s*"([^"]*)"')
  $u = [regex]::Match($s, '"toplamUsd"\s*:\s*(-?[\d.]+(?:[eE][-+]?\d+)?)')
  if (-not ($z.Success -and $u.Success)) { return $null }
  $t = [double]::Parse($u.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
  return ($z.Groups[1].Value + '|' + $(if ($e.Success) { $e.Groups[1].Value }else { '' }) + '|' + $t.ToString('F6', [Globalization.CultureInfo]::InvariantCulture))
}
$gor = @{}
$tut = New-Object System.Collections.Generic.List[string]
$hamN = 0; $hamUsd = 0.0; $tekUsd = 0.0; $ayrisamayan = 0
foreach ($s in [IO.File]::ReadLines($defter, [Text.Encoding]::UTF8)) {
  if (-not $s.Trim()) { continue }
  $hamN++
  $a = Anh $s
  $u = [regex]::Match($s, '"toplamUsd"\s*:\s*(-?[\d.]+(?:[eE][-+]?\d+)?)')
  if ($u.Success) { $hamUsd += [double]::Parse($u.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture) }
  if (-not $a) { $ayrisamayan++; $tut.Add($s); continue }   # ayrıştırılamayan satır ATILMAZ
  if ($gor.ContainsKey($a)) { continue }
  $gor[$a] = 1; $tut.Add($s)
  if ($u.Success) { $tekUsd += [double]::Parse($u.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture) }
}
"ham   : {0,7:N0} satir · {1,10:N2} USD" -f $hamN, $hamUsd
"tekil : {0,7:N0} satir · {1,10:N2} USD   (ayristirilamayan {2}, aynen korundu)" -f $tut.Count, $tekUsd, $ayrisamayan
"dusen : {0,7:N0} mukerrer satir · {1,10:N2} USD hayali harcama" -f ($hamN - $tut.Count), ($hamUsd - $tekUsd)
if (-not $Yaz) { "`nKURU KOSU - dosya YAZILMADI. Yazmak icin: -Yaz"; return }
$yedek = "$defter.yedek-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $defter $yedek
$mx = New-Object System.Threading.Mutex($false, 'Global\tetikte-bedel-kayit'); $al = $false
try { $al = $mx.WaitOne(20000) }catch { $al = $true }
try { [IO.File]::WriteAllLines($defter, $tut.ToArray(), (New-Object Text.UTF8Encoding $false)) }
finally { if ($al) { try { $mx.ReleaseMutex() }catch {} }; $mx.Dispose() }
"yazildi: {0} satir · yedek: {1}" -f $tut.Count, (Split-Path $yedek -Leaf)
