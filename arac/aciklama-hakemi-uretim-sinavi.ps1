# arac/aciklama-hakemi-uretim-sinavi.ps1 — açıklama hakemi üretim bağlantısı öz-sınavı (30.09.2026). AĞ YOK, PARA YOK.
# Sınar: yeni/eski ayrımı · aday seçimi (dört hakem şartı, karar varsa tekrar gönderilmez) · seçim kuralı (yeni + TEMIZ değilse seçilmez) ·
#   bütçe freni (kalan bütçe en kötü durumu karşılamıyorsa GÖNDERMEZ — Invoke-ClaudeToplu'ya hiç ulaşılmaz).
# Mutasyon: AHS_MUTASYON=yeni-hep|butce-yok|karar-yok → sınav KIRMIZI düşmeli (--mutasyon ile üçü koşar).
# 🚫 GÖRMEZ: gerçek toplu gönderim/hasat (api-hedef.ps1 kendi sınavlarıyla) · karar yazımı (arac/aciklama-hakem-yaz.js --sinav).
param([switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
if ($Mutasyon) {
  $tut = 0; $ler = 'yeni-hep', 'butce-yok', 'karar-yok'
  foreach ($m in $ler) { $env:AHS_MUTASYON = $m; & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath | Out-Null; $d = $LASTEXITCODE -ne 0; if ($d) { $tut++ }; "  mutasyon $m $(if($d){'KIRMIZI (doğru)'}else{'YESIL (YANLIŞ)'})" }
  $env:AHS_MUTASYON = $null; "MUTASYON: $tut/$($ler.Count) → KIRMIZI"; if ($tut -ne $ler.Count) { exit 1 }; exit 0
}
. (Join-Path $depoKok 'arac\aciklama-hakemi-uretim.ps1')
$M = "$env:AHS_MUTASYON"
if ($M -eq 'yeni-hep') { function AhYeniMi($v) { return $true } }
if ($M -eq 'karar-yok') { function AhSecilemez($v) { return $false } }
$g = 0; $t = 0
function T($ad, $ok) { $script:t++; if ($ok) { $script:g++; "  ✓ $ad" } else { "  ✗ $ad" } }
function K([string]$tarih, $ek) { $o = [pscustomobject]@{ soru = 'x'; hakem = [pscustomobject]@{ karar = 'EVET' }; hakem2 = [pscustomobject]@{ karar = 'EVET'; tarih = $tarih }; kor_cozum = [pscustomobject]@{ dogru_mu = $true; tarih = $tarih } }; if ($ek) { foreach ($k in $ek.Keys) { $o | Add-Member -NotePropertyName $k -NotePropertyValue $ek[$k] -Force } }; return $o }
$eski = K '2026-09-12' $null; $yeni = K '2026-10-02' $null
T 'eski soru yeni sayılmaz' (-not (AhYeniMi $eski))
T 'yeni soru yeni sayılır' (AhYeniMi $yeni)
T 'eski soru aday değil (hakeme gitmez)' (-not (AhAday $eski))
T 'yeni, dört hakemden geçmiş soru aday' (AhAday $yeni)
T 'hakem2 HAYIR ise aday değil' (-not (AhAday (K '2026-10-02' @{ hakem2 = [pscustomobject]@{ karar = 'HAYIR'; tarih = '2026-10-02' } })))
T 'kararı olan yeni soru tekrar gönderilmez' (-not (AhAday (K '2026-10-02' @{ aciklama_hakem = [pscustomobject]@{ karar = 'KUSURLU' } })))
T 'eski soru seçimden düşmez (yayındaki çekilmez)' (-not (AhSecilemez $eski))
T 'kararsız yeni soru seçilmez' (AhSecilemez $yeni)
T 'KUSURLU yeni soru seçilmez' (AhSecilemez (K '2026-10-02' @{ aciklama_hakem = [pscustomobject]@{ karar = 'KUSURLU' } }))
T 'TEMIZ yeni soru seçilir' (-not (AhSecilemez (K '2026-10-02' @{ aciklama_hakem = [pscustomobject]@{ karar = 'TEMIZ' } })))
# bütçe freni: geçici fabrika, 1 aday, bütçe 0,001 USD → gönderilmez
$d = Join-Path ([IO.Path]::GetTempPath()) ("ahs-" + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory $d | Out-Null
$parti = [ordered]@{ 'kp-01' = $yeni; 'kp-02' = $eski }
[IO.File]::WriteAllText((Join-Path $d 'kalip-parti-ahs-deneme.json'), (ConvertTo-Json -InputObject $parti -Depth 6), [Text.UTF8Encoding]::new($false))
$env:MEVZUAT_BUTCE_USD = $(if ($M -eq 'butce-yok') { '999' } else { '0.001' }); $env:MEVZUAT_YALNIZ_HASAT = '1'
$r = $null; try { $r = AciklamaHakemUretim $depoKok @([pscustomobject]@{ etiket = 'ahs-deneme' }) 0 $d } catch { $r = [pscustomobject]@{ aday = -1; butce_yok = 0; gonderilen = -1; hata = $_.Exception.Message } }
$env:MEVZUAT_BUTCE_USD = $null; $env:MEVZUAT_YALNIZ_HASAT = $null
T 'bütçe freni: 1 aday, gönderilmedi' ($r.aday -eq 1 -and $r.butce_yok -eq 1 -and $r.gonderilen -eq 0)
Remove-Item $d -Recurse -Force
"AH-URETIM-SINAVI: $(if($g -eq $t){'YESIL'}else{'KIRMIZI'}) — $g/$t$(if($M){" · AHS_MUTASYON=$M"})"
if ($g -ne $t) { exit 1 }
