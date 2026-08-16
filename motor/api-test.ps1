# ============================================================================
#  API TEST PROBU - OpenRouter yedek hattini CANLI dogrular      (16.08.2026)
#
#  AMAC: "OpenRouter'a bagladik" demek yetmez. Bu betik gercek bir cagri yapar:
#    1) Anlik JSON cikti (bicim dogru mu)
#    2) Ornek KGK sorusu (kalite + Turkce tam diakritik - Cem gozuyle okur)
#  Kanal, token, maliyet ve mojibake kontrolu ekrana basilir.
#
#  Kullanim (yerel): $env:OPENROUTER_KEY='...'; ./motor/api-test.ps1
#  CI: api-test.yml workflow_dispatch -> OPENROUTER_KEY secret'iyle kosar.
#  -Hat parametresi: 'openrouter' (varsayilan, yedegi test eder) | 'auto' (birincil)
# ============================================================================
param([ValidateSet('openrouter','auto')][string]$Hat = 'openrouter')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'api-hedef.ps1')

if($Hat -eq 'openrouter' -and -not (Read-ApiEnv 'OPENROUTER_KEY')){
  Write-Host "OPENROUTER_KEY yok - test yapilamiyor. (GitHub secret ya da yerel env)" -ForegroundColor Red
  exit 1
}
$yalniz = ($Hat -eq 'openrouter')

Write-Host "==================================================================="
Write-Host (" API TEST - hedeflenen hat: {0}" -f $Hat)
Write-Host "==================================================================="

function Cagir($model,$istem,$maxTok){
  $icerik = @(@{ type='text'; text=$istem })
  if($yalniz){ return (Invoke-ClaudeMesaj -Model $model -Icerik $icerik -MaxTok $maxTok -YalnizOpenRouter) }
  else       { return (Invoke-ClaudeMesaj -Model $model -Icerik $icerik -MaxTok $maxTok) }
}

# --- TEST 1: anlik JSON cikti (bicim + Turkce) -------------------------------
Write-Host "`n--- TEST 1: Anlik JSON + Turkce diakritik ---"
$istem1 = @"
SADECE gecerli JSON dondur (baska hicbir sey yazma). Turkce ve TAM diakritikli yaz (g,u,s,i,o,c yerine dogru harfler).
Sema: {"mesaj":"kisa bir cumle","turkce_harfler":"su kelimeleri aynen yaz: gozetim yururluk tebligi degisiklik"}
"@
$t0 = Get-Date
$r1 = Cagir 'claude-haiku-4-5' $istem1 400
$sure1 = [int]((Get-Date) - $t0).TotalMilliseconds
Write-Host ("  kanal   : {0}" -f $r1.kaynak)
Write-Host ("  token   : girdi {0} / cikti {1}   sure {2} ms" -f $r1.girdi, $r1.cikti, $sure1)
Write-Host ("  ham     : {0}" -f $r1.metin)
$json1ok = $false; $j1 = $null
if($r1.metin -match '(?s)\{.*\}'){ try { $j1 = $Matches[0] | ConvertFrom-Json; $json1ok = $true } catch {} }
Write-Host ("  JSON    : {0}" -f $(if($json1ok){'GECERLI'}else{'BOZUK'}))
# ASCII kaynak kurali: Turkce/mojibake harfleri LITERAL degil KOD NOKTASINDAN kur.
$turkKod = ([int[]]@(0x011F,0x011E,0x00FC,0x00DC,0x015F,0x015E,0x0131,0x0130,0x00F6,0x00D6,0x00E7,0x00C7) | ForEach-Object { [char]$_ })
$turkceVar = $false; foreach($ch in $turkKod){ if($r1.metin.IndexOf($ch) -ge 0){ $turkceVar = $true; break } }
$mojKod = ([int[]]@(0x00C3,0x00C2,0xFFFD) | ForEach-Object { [char]$_ })   # UTF-8 yanlis cozulunce cikan izler
$mojibake = $false; foreach($ch in $mojKod){ if($r1.metin.IndexOf($ch) -ge 0){ $mojibake = $true; break } }
Write-Host ("  Turkce  : {0}   Mojibake: {1}" -f $(if($turkceVar){'VAR (dogru)'}else{'YOK'}), $(if($mojibake){'VAR (KOTU)'}else{'yok (temiz)'}))

# --- TEST 2: ornek KGK sorusu (kalite - Cem okur) ----------------------------
Write-Host "`n--- TEST 2: Ornek KGK SMMM sorusu (kalite gozetimi) ---"
$istem2 = @"
Sen KGK SMMM sinavi icin soru yazan deneyimli bir egitmensin. Asagidaki konuda 5 secenekli (A-E) TEK bir cikmis-sinav ayarinda soru yaz.
KURALLAR: Turkce ve TAM diakritikli. Rakam/oran/sure UYDURMA - emin olmadigini yazma. Yapay zeka kokan kalip yok. SADECE JSON dondur.
Sema: {"soru":"...","secenekler":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"harf","dayanak":"kanun ve madde","aciklama":"dogru cevabin neden dogru oldugu 1-2 cumle"}
KONU: Vergi Usul Kanunu'na gore faturanin duzenlenme suresi (malin teslimi / hizmetin yapilmasindan itibaren).
"@
$t0 = Get-Date
$r2 = Cagir 'claude-sonnet-5' $istem2 1500
$sure2 = [int]((Get-Date) - $t0).TotalMilliseconds
Write-Host ("  kanal   : {0}" -f $r2.kaynak)
Write-Host ("  token   : girdi {0} / cikti {1}   sure {2} ms" -f $r2.girdi, $r2.cikti, $sure2)
$json2ok = $false; $q = $null
try { $q = ($r2.metin | Select-String -Pattern '(?s)\{.*\}').Matches[0].Value | ConvertFrom-Json; $json2ok = $true } catch {}
if($json2ok){
  Write-Host "`n  ===== URETILEN ORNEK SORU (Cem okur) ====="
  Write-Host ("  SORU: {0}" -f $q.soru)
  foreach($h in 'A','B','C','D','E'){ if($q.secenekler.$h){ Write-Host ("    {0}) {1}" -f $h, $q.secenekler.$h) } }
  Write-Host ("  DOGRU  : {0}" -f $q.dogru)
  Write-Host ("  DAYANAK: {0}" -f $q.dayanak)
  Write-Host ("  ACIKLAMA: {0}" -f $q.aciklama)
  Write-Host "  =========================================="
} else {
  Write-Host "  JSON BOZUK - ham cikti:" -ForegroundColor Yellow
  Write-Host ("  {0}" -f $r2.metin)
}

# --- MALIYET ozeti -----------------------------------------------------------
# OpenRouter fiyati Anthropic ile ayni taban (haiku 1/5, sonnet 3/15 USD/1M).
$mal = ($r1.girdi/1e6)*1.0 + ($r1.cikti/1e6)*5.0 + ($r2.girdi/1e6)*3.0 + ($r2.cikti/1e6)*15.0
Write-Host "`n==================================================================="
Write-Host (" SONUC: kanal={0}  JSON1={1}  JSON2={2}  Turkce={3}  Mojibake={4}" -f `
  $r1.kaynak, $(if($json1ok){'OK'}else{'X'}), $(if($json2ok){'OK'}else{'X'}), `
  $(if($turkceVar){'OK'}else{'X'}), $(if($mojibake){'KOTU'}else{'temiz'}))
Write-Host (" Bu testin maliyeti: ~{0:N4} USD" -f $mal)
Write-Host "==================================================================="
if(-not ($json1ok -and $json2ok -and $turkceVar -and -not $mojibake)){
  Write-Host "TEST BASARISIZ - yukaridaki bulguya bak." -ForegroundColor Red
  exit 1
}
Write-Host "TEST BASARILI - yedek hat calisiyor, kalite/Turkce temiz." -ForegroundColor Green
