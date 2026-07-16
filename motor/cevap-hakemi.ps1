# ============================================================================
#  CEVAP HAKEMI — gunluk uctan-uca kalite orneklemi (guven katmani C-2)
#  Altin setten gunun 8 vakasini secer (gun-of-year rotasyonu: her gun farkli
#  dilim), canli net-cevap'a sorar, Haiku hakeme puanlatir (0-10):
#   - cevap yalniz verilen alintilara mi dayaniyor (uydurma rakam/sure var mi?)
#   - beklenen kaynak kullanildi mi?
#  Ortalama < 7 veya tek vaka <= 3 -> exit 1 (CI kirmizi).
#  ANTHROPIC_API_KEY yoksa nazikce atlar (exit 0) — retrieval kapisi ayri
#  (ambar-testi.ps1) zaten kosuyor.
# ============================================================================
$ErrorActionPreference = 'Stop'
$AK = "$env:ANTHROPIC_API_KEY".Trim()
if (-not $AK) { Write-Host 'ATLANDI: ANTHROPIC_API_KEY tanimli degil (retrieval kapisi yine de kostu).'; exit 0 }

$EDGE = 'https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/net-cevap'
$KEY  = if ($env:SB_PUBLISHABLE) { $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }

$kok = Split-Path -Parent $PSScriptRoot
$set = Get-Content -Raw -Encoding UTF8 (Join-Path $kok 'veri/ambar-altin-test.json') | ConvertFrom-Json
$n = $set.vakalar.Count
$ORNEK = 8
$bas = ((Get-Date).DayOfYear * $ORNEK) % $n
$secim = 0..($ORNEK-1) | ForEach-Object { $set.vakalar[($bas + $_) % $n] }

function HakemPuani($soru, $beklenen, $cevapJson) {
  $istem = @"
Sen bir mevzuat cevap denetcisisin. Asagida bir kullanici sorusu, cevap servisinin JSON ciktisi (cevap + dayandigi ham kaynak alintilari) ve cevabin dayanmasi gereken kaynak adi parcasi var.
PUANLAMA (0-10):
- 10-8: cevap yalniz alintilardaki bilgiye dayaniyor, uydurma rakam/sure yok, beklenen kaynak kullanilmis.
- 7-5: cevap dogru kaynaga dayaniyor ama alintida olmayan kucuk detay eklemis.
- 4-1: cevapta alintilarla desteklenmeyen rakam/sure/oran var (UYDURMA supheli) veya kaynak alakasiz.
- 0: kapsamda=false donmus (cevap verilememis).
SADECE gecerli JSON dondur: {"puan": <0-10>, "gerekce": "<tek cumle>"}

SORU: $soru
BEKLENEN KAYNAK PARCASI: $($beklenen -join ' | ')
SERVIS CIKTISI:
$cevapJson
"@
  $govde = @{ model = 'claude-haiku-4-5-20251001'; max_tokens = 200; messages = @(@{ role = 'user'; content = $istem }) } | ConvertTo-Json -Depth 6
  $r = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $AK; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  $mt = [regex]::Match($r.content[0].text, '\{[\s\S]*\}')
  if (-not $mt.Success) { return $null }
  return ($mt.Value | ConvertFrom-Json)
}

$puanlar = @(); $dusuk = 0
foreach ($v in $secim) {
  $cevap = '{"kapsamda":false,"hata":"istek atilamadi"}'
  try {
    $g = @{ soru = $v.soru } | ConvertTo-Json -Compress
    $c = Invoke-RestMethod -Method Post -Uri $EDGE -Headers @{ apikey = $KEY; Authorization = "Bearer $KEY" } -ContentType 'application/json' -Body $g
    $cevap = $c | ConvertTo-Json -Depth 6 -Compress
  } catch { }
  $h = $null
  try { $h = HakemPuani $v.soru $v.beklenen $cevap } catch { Write-Host "HAKEM HATASI: $($v.soru) -> $_" }
  if ($null -eq $h) { Write-Host "PUANSIZ: $($v.soru)"; $dusuk++; continue }
  $puanlar += [double]$h.puan
  $isaret = if ($h.puan -le 3) { 'DUSUK' } elseif ($h.puan -lt 7) { 'ORTA ' } else { 'IYI  ' }
  if ($h.puan -le 3) { $dusuk++ }
  Write-Host "$isaret [$($h.puan)/10] $($v.soru) — $($h.gerekce)"
}
$ort = if ($puanlar.Count) { [math]::Round(($puanlar | Measure-Object -Average).Average, 2) } else { 0 }
Write-Host "----------------------------------------------"
Write-Host "HAKEM: ortalama $ort/10, dusuk(<=3) vaka: $dusuk / $($secim.Count)"
if ($ort -lt 7 -or $dusuk -gt 0) { exit 1 }
