# arac/model-izi-sinavi.ps1 — "soru verisine model adı girmez" kapısının öz-sınavı (10.10.2026). AĞ YOK, PARA YOK.
# Sınar: motor/model-kod.ps1 ModelKod (ad → nötr kod) · ModelIziNotrMetin (JSON metninde yalnız "model":"claude-…" çevrilir, başka bayt aynı) ·
#   sistem partisi ('__') çevrilmez · KAYNAK TARAMASI: motor/kalip-parti-uret.ps1 + arac/aciklama-hakemi-uretim.ps1 veriye ham ad yazmıyor ·
#   arac/parti-senkron.ps1 -Yukle ağı gövdeden ÖNCE çağırıyor.
# Mutasyon: MODEL_IZI_MUTASYON=kod-yok|ag-yok|sistem-de|tarama-yok → sınav KIRMIZI düşmeli (-Mutasyon ile dördü koşar).
# 🚫 GÖRMEZ: bu iki dosya DIŞINDAKİ yazıcılar (ağ yakalar, kaynak taraması değil) · alan adında model (simulasyon_sonnet) ·
#   düz metin içindeki ad · ambarın kendisi (ölçüm: node arac/model-izi-olc.js).
param([switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
if ($Mutasyon) {
  $psExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { 'powershell' } else { 'pwsh' }
  $tut = 0; $ler = 'kod-yok', 'ag-yok', 'sistem-de', 'tarama-yok'
  foreach ($m in $ler) { $env:MODEL_IZI_MUTASYON = $m; & $psExe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath | Out-Null; $d = $LASTEXITCODE -ne 0; if ($d) { $tut++ }; "  mutasyon $m $(if($d){'KIRMIZI (doğru)'}else{'YESIL (YANLIŞ)'})" }
  $env:MODEL_IZI_MUTASYON = $null; "MUTASYON: $tut/$($ler.Count) → KIRMIZI"; if ($tut -ne $ler.Count) { exit 1 }; exit 0
}
. (Join-Path $depoKok 'motor/model-kod.ps1')
$g = 0; $t = 0
function T($ad, $ok) { $script:t++; if ($ok) { $script:g++; "  ✓ $ad" } else { "  ✗ $ad" } }

# 1) ModelKod
T 'haiku (tarihli) → model-a' ((ModelKod 'claude-haiku-4-5-20251001') -eq 'model-a')
T 'sonnet → model-b' ((ModelKod 'claude-sonnet-5') -eq 'model-b')
T 'opus-5 → model-c' ((ModelKod 'claude-opus-5') -eq 'model-c')
T 'opus-5-5 → model-c' ((ModelKod 'claude-opus-5-5') -eq 'model-c')
T 'bilinmeyen claude-* → model-x' ((ModelKod 'claude-yeni-9') -eq 'model-x')
T 'zaten nötr kod değişmez' ((ModelKod 'model-b') -eq 'model-b')
T 'boş değer boş kalır' ((ModelKod '') -eq '')

# 2) ModelIziNotrMetin — yakalaması gereken
$ham = '{"kp-01":{"hakem2":{"karar":"EVET","model":"claude-sonnet-5"},"hakem":{"ikinci_bakis":{"model" : "claude-sonnet-5"}},"sade":{"model":"claude-haiku-4-5"},"kor_cozum":{"model":"claude-opus-5"}}}'
$bek = '{"kp-01":{"hakem2":{"karar":"EVET","model":"model-b"},"hakem":{"ikinci_bakis":{"model" : "model-b"}},"sade":{"model":"model-a"},"kor_cozum":{"model":"model-c"}}}'
$s = ModelIziNotrMetin $ham
T 'iç içe + boşluklu "model" alanları çevrildi (4)' ($s.sayi -eq 4)
T 'çıktı beklenen metne bayt bayt eşit (öteki alanlar aynı)' ($s.metin -ceq $bek)
T 'çıktı geçerli JSON' ($null -ne ($s.metin | ConvertFrom-Json))

# 3) ModelIziNotrMetin — yanlış alarm vermemesi gereken (kapı kuralı 5: liste meşru veriyle çakışabilir mi?)
$mesru = '{"__x":[{"id":"msgbatch_01QKq4EUoPUSrvy5kSPwxkqq"}],"kp-02":{"soru":"Ressam Claude Monet ve claude-sonnet-5 metinde geçer","simulasyon_sonnet":{"model":"model-b"},"model_notu":"claude-opus-5","modeller":["claude-haiku-4-5"]}}'
$m2 = ModelIziNotrMetin $mesru
T 'toplu iş kimliği (içinde "oPUS") dokunulmaz, metin içi ad dokunulmaz, başka anahtar dokunulmaz' (($m2.sayi -eq 0) -and ($m2.metin -ceq $mesru))

# 4) Sistem partisi
T "'__sistem-bekleyen-partiler' sistem partisi (çevrilmez; api-hedef gerçek adı okur)" (ModelIziSistemPartisi '__sistem-bekleyen-partiler')
T "'sgs-x' soru partisi (çevrilir)" (-not (ModelIziSistemPartisi 'sgs-x'))

# 5) Kaynak taraması — veriye ham ad yazan satır (istek gövdesi hariç: messages / max_tokens / maxTok / TopluTopla)
function HamYazanSatirlar([string[]]$satirlar) {
  if ("$env:MODEL_IZI_MUTASYON" -eq 'tarama-yok') { return @() }
  $rx = "model\s*=\s*('claude-|`"claude-|\`$(SimModel|KorModel|model)\b)"
  return @($satirlar | Where-Object { $_ -match $rx -and $_ -notmatch 'messages\s*=|max_tokens|maxTok|TopluTopla|^\s*#|\[string\]\$' })
}
T 'tarayıcı yapay ihlali yakalar (veri nesnesine ham ad)' ((HamYazanSatirlar @("  `$x=[pscustomobject]@{ karar='EVET'; model='claude-sonnet-5'; tarih=1 }")).Count -eq 1)
T 'tarayıcı istek gövdesine alarm vermez' ((HamYazanSatirlar @("  `$g=@{ model='claude-haiku-4-5'; max_tokens=1; messages=@() }")).Count -eq 0)
T 'tarayıcı ModelKod sarmalına alarm vermez' ((HamYazanSatirlar @("  `$x=@{ model=(ModelKod `$SimModel); tarih=1 }")).Count -eq 0)
foreach ($f in 'motor/kalip-parti-uret.ps1', 'arac/aciklama-hakemi-uretim.ps1') {
  $sat = [IO.File]::ReadAllLines((Join-Path $depoKok $f))
  $h = HamYazanSatirlar $sat
  T "$f veriye ham model adı yazmıyor ($($h.Count) satır)" ($h.Count -eq 0)
  T "$f model-kod.ps1'i yüklüyor" ((@($sat | Where-Object { $_ -match "model-kod\.ps1" })).Count -ge 1)
}

# 6) Ambar geçişindeki ağ: parti-senkron -Yukle, gövde kurulmadan ÖNCE ağı çağırıyor
$ps = [IO.File]::ReadAllText((Join-Path $depoKok 'arac/parti-senkron.ps1'))
$iAg = $ps.IndexOf('ModelIziNotrMetin $icerik'); $iGovde = $ps.IndexOf('$govde = ''{"etiket":''')
T 'parti-senkron ağı çağırıyor ve gövdeden önce' (($iAg -gt 0) -and ($iGovde -gt $iAg))
T "parti-senkron model-kod.ps1'i yüklüyor" ($ps -match "model-kod\.ps1")

"MODEL-IZI ÖZ-SINAV: $g/$t"
if ($g -ne $t) { exit 1 }; exit 0
