# ============================================================================
#  OTOMASYON DENETIMI OZ-SINAVI (+ MUTASYON) - 0 USD, ag YOK
#
#  NEDEN VAR (21.10.2026): arac/otomasyon-denetimi.ps1'e uc yeni detektor
#  eklendi (tek satirda `= switch` coklu hedef; Node motoru yazma kaniti
#  j1/j2/j3; workflow'da GERCEK `node X.js` cagrisi). Kapi 08.09'dan beri
#  kirmiziydi; 6 dosyanin 6'si gercekte robotla yaziliyordu ama kapi Node'u ve
#  switch satirini goremiyordu. Detektor eklemek kapiyi GEVSETEBILIR - bu sinav
#  iki yonu de kollar:
#    YAKALAMALI : switch iki hedef (a+b) · j1 · j2 · j3  -> otomatik sayilir
#    YAKALAMAMALI: yalniz OKUYAN Node betigi (z) · yalniz `paths:` listesinde
#                  gecen Node betigi (p) · hic yazani olmayan dosya (n)
#                  -> KIRMIZI kalmali
#  Sonra MUTASYON: her detektor tek tek kapatilir (ya da gevsetilir), sinav
#  KIRMIZI olmali; mutasyonsuz kopya (kontrol) YESIL olmali.
#
#  Linux pwsh 7 + Windows PowerShell 5.1: yol [IO.Path]::GetTempPath(),
#  ileri bolu; kapi ayni surecte cagrilir (exit yalniz betigi bitirir).
# ============================================================================
$ErrorActionPreference = 'Stop'
$KAPI = Join-Path $PSScriptRoot 'otomasyon-denetimi.ps1'
$UTF8BOM = New-Object Text.UTF8Encoding($true)
$UTF8 = New-Object Text.UTF8Encoding($false)

$kokSinav = Join-Path ([IO.Path]::GetTempPath()) ('otomasyon-sinav-' + [guid]::NewGuid().ToString('N').Substring(0,8))
function Yaz([string]$goreli, [string]$metin){
  $yol = Join-Path $kokSinav $goreli
  $kl = Split-Path -Parent $yol
  if(-not (Test-Path $kl)){ New-Item -ItemType Directory -Path $kl -Force | Out-Null }
  [IO.File]::WriteAllText($yol, $metin, $UTF8)
}

# --- sentetik depo ---------------------------------------------------------
Yaz 'index.html' @'
<html><body><script>
fetch('veri/a.json'); fetch('veri/b.json'); fetch('veri/x.json'); fetch('veri/y.json');
fetch('veri/w.json'); fetch('veri/z.json'); fetch('veri/p.json'); fetch('veri/n.json');
</script></body></html>
'@
# switch: (a) ac gozlu desen yalniz SON adi (b) baglar; a'yi (a2) bulmali
Yaz 'motor/coklu.ps1' @'
param([string]$S = 'A')
$c = switch($S){ 'A' { 'veri/a.json' } 'B' { 'veri/b.json' } }
Set-Content -LiteralPath $c -Value '{}'
'@
Yaz 'motor/j1.js' @'
const fs = require('fs'); const path = require('path'); const KOK = path.join(__dirname, '..');
fs.writeFileSync(path.join(KOK, 'veri', 'x.json'), '{}');
'@
Yaz 'motor/j2.js' @'
const fs = require('fs'); const path = require('path'); const KOK = path.join(__dirname, '..');
const V = path.join(KOK, 'veri', 'y.json');
fs.writeFileSync(V, '{}');
'@
Yaz 'motor/j3.js' @'
const fs = require('fs'); const path = require('path'); const KOK = path.join(__dirname, '..');
const HEDEF = path.join(KOK, 'veri', 'w.json');
for (const [hedef, nesne] of [[HEDEF, {}]]) {
  fs.writeFileSync(hedef, JSON.stringify(nesne));
}
'@
# yalniz OKUR (baska bir dosya yazar) - z.json'un ureticisi SAYILMAMALI
Yaz 'motor/okur.js' @'
const fs = require('fs'); const path = require('path'); const KOK = path.join(__dirname, '..');
const Z = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'z.json'), 'utf8'));
fs.writeFileSync(path.join(KOK, 'cikti.txt'), String(Z));
'@
# p.json'u yaziyor ama workflow onu yalniz `paths:` tetiginde ANIYOR, cagirmiyor
Yaz 'motor/sadece-paths.js' @'
const fs = require('fs');
fs.writeFileSync('veri/p.json', '{}');
'@
Yaz '.github/workflows/sinav.yml' @'
name: sinav
on:
  push:
    paths:
      - 'motor/sadece-paths.js'
jobs:
  is:
    runs-on: ubuntu-latest
    steps:
      - run: pwsh ./motor/coklu.ps1
      - run: node motor/j1.js
      - run: node ./motor/j2.js
      - run: |
          node motor/j3.js
          node motor/okur.js
'@
Yaz 'arac/.bos' ''

$BEKLENEN = @('n.json','p.json','z.json')   # KIRMIZI kalmasi gerekenler (tam kume)

function Kostur([string]$kapiYolu){
  $cikti = (& $kapiYolu -DepoKok $kokSinav *>&1 | Out-String)
  $kod = $LASTEXITCODE
  $kirmizi = @()
  $bolum = $false
  foreach($s in ($cikti -split "\r?\n")){
    if($s -match '^KIRMIZI - su dosyalar'){ $bolum = $true; continue }
    if($bolum -and $s -match '^\s{3}([A-Za-z0-9._-]+\.json)\s'){ $kirmizi += $Matches[1] }
  }
  return [pscustomobject]@{ Kod = $kod; Kirmizi = @($kirmizi | Sort-Object); Cikti = $cikti }
}
function Dogru($r){
  return ($r.Kod -eq 1) -and ((@($r.Kirmizi) -join ',') -eq ($BEKLENEN -join ','))
}

$hata = 0
try {
  # --- 1) kontrol: asil kapi ------------------------------------------------
  $r = Kostur $KAPI
  if(Dogru $r){
    Write-Host ("OZ-SINAV YESIL: kirmizi = {0} (beklenen {1}); a,b,x,y,w otomatik." -f ($r.Kirmizi -join ','), ($BEKLENEN -join ','))
  } else {
    Write-Host ("OZ-SINAV DUSTU: cikis={0} kirmizi=[{1}] beklenen=[{2}]" -f $r.Kod, ($r.Kirmizi -join ','), ($BEKLENEN -join ',')) -ForegroundColor Red
    Write-Host $r.Cikti
    $hata++
  }

  # --- 2) mutasyon: her detektor kapatilir / gevsetilir -> sinav DUSMELI ----
  $asil = [IO.File]::ReadAllText($KAPI)
  $MUTASYON = @(
    @{ ad = 'a2 switch coklu hedef KAPALI';  eski = 'if($coklu.ContainsKey($kv.Key)){';                 yeni = 'if($false){' },
    @{ ad = 'j1 writeFileSync(icinde ad) KAPALI'; eski = '"writeFileSync\([^\r\n]*?$JSAD"';            yeni = '"KAPALI_MUTASYON\([^\r\n]*?$JSAD"' },
    @{ ad = 'j2 const V + writeFileSync(V KAPALI'; eski = 'if($icerik -cmatch "writeFileSync\(\s*$v\b"){'; yeni = 'if($false){' },
    @{ ad = 'j3 for-of demet KAPALI';         eski = 'if($icerik -cmatch "writeFileSync\(\s*$h\b"){';  yeni = 'if($false){' },
    @{ ad = 'node X.js cagrisi KAPALI';       eski = "'\bnode\s+(?:\./)?(?:[A-Za-z0-9._-]+/)*([A-Za-z0-9._-]+\.js)\b'"; yeni = "'KAPALI_MUTASYON([A-Za-z0-9._-]+\.js)'" },
    @{ ad = 'GEVSEK: paths: adi da cagri';    eski = "'\bnode\s+(?:\./)?(?:[A-Za-z0-9._-]+/)*([A-Za-z0-9._-]+\.js)\b'"; yeni = "'([A-Za-z0-9._-]+\.js)'" },
    @{ ad = 'GEVSEK: j2 yazma kaniti aranmaz'; eski = 'if($icerik -cmatch "writeFileSync\(\s*$v\b"){'; yeni = 'if($true){' }
  )
  $mDosya = Join-Path $kokSinav 'mutant-otomasyon-denetimi.ps1'
  # kontrol kopyasi: mutasyonsuz kopya da YESIL olmali (kopyalama yolu bozuk degil)
  [IO.File]::WriteAllText($mDosya, $asil, $UTF8BOM)
  $k = Kostur $mDosya
  if(Dogru $k){ Write-Host "  kontrol (mutasyonsuz kopya) : YESIL" }
  else { Write-Host "  kontrol (mutasyonsuz kopya) : DUSTU - mutasyon olcumu gecersiz" -ForegroundColor Red; $hata++ }

  foreach($mu in $MUTASYON){
    if(-not $asil.Contains($mu.eski)){
      Write-Host ("  MUTASYON KURULAMADI ({0}): kapida beklenen satir yok - sinavi kapiyla esitle" -f $mu.ad) -ForegroundColor Red
      $hata++; continue
    }
    [IO.File]::WriteAllText($mDosya, $asil.Replace($mu.eski, $mu.yeni), $UTF8BOM)
    $m = Kostur $mDosya
    if(Dogru $m){
      Write-Host ("  MUTASYON YASADI ({0}): detektor bozuldu ama sinav fark etmedi" -f $mu.ad) -ForegroundColor Red
      $hata++
    } else {
      Write-Host ("  mutasyon olduruldu: {0,-36} kirmizi=[{1}]" -f $mu.ad, ($m.Kirmizi -join ','))
    }
  }
}
finally {
  Remove-Item -LiteralPath $kokSinav -Recurse -Force -ErrorAction SilentlyContinue
}

if($hata){ Write-Host ("OTOMASYON DENETIMI OZ-SINAVI KIRMIZI: {0} hata" -f $hata) -ForegroundColor Red; exit 1 }
Write-Host "OTOMASYON DENETIMI OZ-SINAVI YESIL (kontrol + 7 mutasyon)"
exit 0
