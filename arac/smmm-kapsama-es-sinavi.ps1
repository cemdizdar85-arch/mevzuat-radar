#requires -Version 5.1
<#
================================================================================
  ÖZ-SINAV: arac/smmm-kapsama-tablosu.ps1 · EsCoz (eşleme sözlüğü döngü/zincir çözümü)
  26.09.2026 · bedel 0 (ağ yok, model yok)

  NİYE: veri/sinav/smmm-konu-es.json'da iki yönlü döngüler vardı (A→B ve B→A). Eşleme tek adım
  uygulandığı için konunun yayınlanabilir soruları bir satıra, hedefi öbür satıra düşüyor; tablo
  dolu konuyu "açık" gösteriyor, plan ona yeniden soru yazdırıyordu (ölçüldü: 26 konu, 67 sahte açık).

  YÖNTEM: işlev GERÇEK betikten AST ile alınır (kopya değil); vakalarla koşturulur.
  🚫 GÖRMEZ: tablonun geri kalanını (hedef dağıtımı, yayın şartı) — onlar ayrı sınanır.
  KULLANIM: powershell -NoProfile -ExecutionPolicy Bypass -File arac/smmm-kapsama-es-sinavi.ps1
================================================================================
#>
param([string]$Betik = '')
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
if (-not $Betik) { $Betik = Join-Path $PSScriptRoot 'smmm-kapsama-tablosu.ps1' }
$hata = $null; $ast = [System.Management.Automation.Language.Parser]::ParseFile($Betik, [ref]$null, [ref]$hata)
if ($hata.Count) { throw "betik ayrıştırılamadı: $($hata[0].Message)" }
$fn = @($ast.FindAll({ param($d) $d -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $d.Name -eq 'EsCoz' }, $true))
if ($fn.Count -ne 1) { Write-Host "KIRMIZI: EsCoz işlevi betikte bulunamadı ($($fn.Count))" -ForegroundColor Red; exit 1 }
. ([scriptblock]::Create($fn[0].Extent.Text))
$cagri = @($ast.FindAll({ param($d) $d -is [System.Management.Automation.Language.AssignmentStatementAst] -and $d.Extent.Text -match '^\$es\s*=\s*EsCoz\b' }, $true))

$vakalar = @(
  @{ ad = 'iki yönlü döngü: çıkmışı büyük olan kanon'; es = @{ 'a' = 'b'; 'b' = 'a' }; c = @{ 'a' = 5; 'b' = 1 }; bek = @{ 'b' = 'a' } },
  @{ ad = 'iki yönlü döngü: öbür yönde çıkmış büyük'; es = @{ 'a' = 'b'; 'b' = 'a' }; c = @{ 'a' = 1; 'b' = 9 }; bek = @{ 'a' = 'b' } },
  @{ ad = 'döngüde eşitlik: sıralı ilk kanon'; es = @{ 'y' = 'x'; 'x' = 'y' }; c = @{}; bek = @{ 'y' = 'x' } },
  @{ ad = 'zincir sona kadar izlenir'; es = @{ 'x' = 'y'; 'y' = 'z' }; c = @{}; bek = @{ 'x' = 'z'; 'y' = 'z' } },
  @{ ad = 'üçlü döngü takılmaz, tek kanon'; es = @{ 'p' = 'q'; 'q' = 'r'; 'r' = 'p' }; c = @{ 'q' = 3 }; bek = @{ 'p' = 'q'; 'r' = 'q' } },
  @{ ad = 'döngüye akan zincir kanona gider'; es = @{ 'k' = 'a'; 'a' = 'b'; 'b' = 'a' }; c = @{ 'b' = 4 }; bek = @{ 'k' = 'b'; 'a' = 'b' } },
  @{ ad = 'YANLIŞ ALARM: düz eşleme değişmez'; es = @{ 'm' = 'n'; 'o' = 'n' }; c = @{ 'm' = 7 }; bek = @{ 'm' = 'n'; 'o' = 'n' } },
  @{ ad = 'YANLIŞ ALARM: kendine eşleme düşer, başkası kalır'; es = @{ 's' = 's'; 't' = 'u' }; c = @{}; bek = @{ 't' = 'u' } },
  @{ ad = 'GERÇEK VAKA 26.09: iş sözleşmesi döngüsü'; es = @{ 'is sozlesmesi tanimi ve unsurlari' = 'is sozlesmesi tanimi unsurlari'; 'is sozlesmesi tanimi unsurlari' = 'is sozlesmesi tanimi ve unsurlari'; 'is sozlesmesi tanimi' = 'is sozlesmesi tanimi ve unsurlari' }; c = @{ 'is sozlesmesi tanimi ve unsurlari' = 4; 'is sozlesmesi tanimi unsurlari' = 1 };
     bek = @{ 'is sozlesmesi tanimi unsurlari' = 'is sozlesmesi tanimi ve unsurlari'; 'is sozlesmesi tanimi' = 'is sozlesmesi tanimi ve unsurlari' } }
)
$kirmizi = 0
foreach ($v in $vakalar) {
  $s = EsCoz $v.es $v.c
  $ok = ($s.Count -eq $v.bek.Count)
  foreach ($k in $v.bek.Keys) { if (-not $s.ContainsKey($k) -or $s[$k] -ne $v.bek[$k]) { $ok = $false } }
  if ($ok) { "  YEŞİL  $($v.ad)" } else { $kirmizi++; Write-Host ("  KIRMIZI $($v.ad) · beklenen {0} · çıkan {1}" -f (($v.bek.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)→$($_.Value)" }) -join ','), (($s.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)→$($_.Value)" }) -join ',')) -ForegroundColor Red }
}
if ($cagri.Count -ne 1) { $kirmizi++; Write-Host "  KIRMIZI betik EsCoz'u sözlüğe uygulamıyor ('`$es = EsCoz …' satırı $($cagri.Count) kez)" -ForegroundColor Red } else { '  YEŞİL  betik sözlüğü EsCoz ile çözüyor' }
if ($kirmizi) { Write-Host "SMMM KAPSAMA ES ÖZ-SINAVI KIRMIZI ($kirmizi / $($vakalar.Count + 1))" -ForegroundColor Red; exit 1 }
"SMMM KAPSAMA ES ÖZ-SINAVI YEŞİL ($($vakalar.Count + 1) vaka)"
