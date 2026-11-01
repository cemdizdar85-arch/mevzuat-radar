#requires -Version 5.1
<#
================================================================================
  BİTİRME KABUKLARINI İT — ÖZ-SINAV  (01.11.2026)  ağ yok, para yok
  Gerçek arac/kabuk-it.ps1 geçici bir çıplak depo + iki klona karşı koşar (robot klonu "a", araya giren yazar "b").
  VAKALAR: 1) araya giren başka dosya → rebase + itilir, iki değişiklik de uzakta · 2) bizim üretim dosyasında
    (veri/deneme) çakışma → bizimki kazanır, b'nin öteki değişikliği korunur · 3) desen dışı dosyada (arac/kasa-modu.json)
    çakışma → çıkış 1, uzaktaki b'nin hâli EZİLMEZ, klon rebase ortasında kalmaz · 4) değişiklik yok → çıkış 0, commit yok ·
    5) uzak her itmeyi reddeder (pre-receive) → 3 denemede çıkış 1 · 7) kirli çalışma ağacı (izlenen, commit dışı dosya) + itme reddi → itilir,
    kirli dosya commit'e girmez ve yerinde kalır · 6) STATİK: smmm-kasa-yayin.yml "Bitirme kabuklarini it"
    adımı bu betiği çağırır, çıkış kodunu geçirir, eski merge döngüsü kalmamıştır.
  -Mutasyon: 5 bozma (çakışma çözümü yok · her dosya bizim · tek deneme · değişiklik yok denetimi yok · autostash yok), her biri KIRMIZI.
  🚫 GÖRMEZ: GitHub'ın gerçek itme yarışı (yerel çıplak depo) · iş akışındaki "KABUK DEGIL" denetimi (betikten önce).
================================================================================
#>
param([switch]$Mutasyon, [switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$betikYol = Join-Path $buDizin 'kabuk-it.ps1'
$betikMetin = [IO.File]::ReadAllText($betikYol, [Text.Encoding]::UTF8)
$ymlYol = Join-Path (Join-Path (Join-Path (Split-Path -Parent $buDizin) '.github') 'workflows') 'smmm-kasa-yayin.yml'
$psExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { 'powershell' } else { 'pwsh' }
$u8 = New-Object Text.UTF8Encoding($true)

function G([string]$dizin) { $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'; try { $o = & git -C $dizin @args 2>&1; return @($o | ForEach-Object { "$_" }) } finally { $ErrorActionPreference = $eap } }
function Yaz([string]$dizin, [string]$yol, [string]$icerik) { $t = Join-Path $dizin $yol; New-Item -ItemType Directory -Force (Split-Path $t -Parent) | Out-Null; [IO.File]::WriteAllText($t, $icerik, (New-Object Text.UTF8Encoding($false))) }
function Kur([string]$kok) {
  New-Item -ItemType Directory -Force $kok | Out-Null
  $uzak = Join-Path $kok 'uzak.git'
  G $kok init -q --bare -b main $uzak | Out-Null
  foreach ($ad in 'a', 'b') {
    G $kok clone -q $uzak (Join-Path $kok $ad) | Out-Null
    $d = Join-Path $kok $ad; G $d config user.name "sinav-$ad" | Out-Null; G $d config user.email "$ad@sinav" | Out-Null; G $d config commit.gpgsign false | Out-Null
    G $d checkout -q -B main | Out-Null
  }
  $a = Join-Path $kok 'a'
  Yaz $a 'veri/deneme/set.json' "ilk`n"; Yaz $a 'kaydir/smmm/hukuk.html' "kabuk ilk`n"; Yaz $a 'arac/kasa-modu.json' "liste ilk`n"; Yaz $a 'README' "ilk`n"
  G $a add -A | Out-Null; G $a commit -q -m ilk | Out-Null; G $a push -q origin main | Out-Null
  G (Join-Path $kok 'b') pull -q origin main | Out-Null
  return $uzak
}
function UzakDosya([string]$uzak, [string]$yol) { return ((G $uzak show "main:$yol") -join "`n") }
function Kos([string]$betik, [string]$dizin) {
  $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $o = & $psExe -NoProfile -ExecutionPolicy Bypass -File $betik -Kok $dizin -Mesaj 'sinav' -BeklemeSn 0 2>&1; return @{ kod = $LASTEXITCODE; cikti = (@($o | ForEach-Object { "$_" }) -join ' | ') } }
  finally { $ErrorActionPreference = $eap }
}

function SinavKos([string]$metin) {
  $kalan = New-Object System.Collections.Generic.List[string]; $script:okSay = 0
  function V([string]$ad, [bool]$kosul, [string]$ek) { if ($kosul) { $script:okSay++; if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  OK    $ad" } } else { $kalan.Add("$ad ($ek)"); if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  DÜŞTÜ $ad ($ek)" -ForegroundColor Red } } }
  $kok = Join-Path ([IO.Path]::GetTempPath()) ("kabuk-it-sinavi-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
  try {
    New-Item -ItemType Directory -Force $kok | Out-Null
    $betik = Join-Path $kok 'kabuk-it.ps1'; [IO.File]::WriteAllText($betik, $metin, $u8)
    # 1) araya giren başka dosya
    $k1 = Join-Path $kok 'v1'; $uz = Kur $k1; $a = Join-Path $k1 'a'; $b = Join-Path $k1 'b'
    Yaz $b 'README' "b degistirdi`n"; G $b commit -q -am b | Out-Null; G $b push -q origin main | Out-Null
    Yaz $a 'veri/deneme/set.json' "a yeni`n"
    $r = Kos $betik $a
    V '1 araya giren başka dosya → rebase + itildi' ($r.kod -eq 0 -and (UzakDosya $uz 'veri/deneme/set.json') -eq 'a yeni' -and (UzakDosya $uz 'README') -eq 'b degistirdi') "$($r.kod) | $($r.cikti)"
    # 2) bizim üretim dosyasında çakışma
    $k2 = Join-Path $kok 'v2'; $uz = Kur $k2; $a = Join-Path $k2 'a'; $b = Join-Path $k2 'b'
    Yaz $b 'veri/deneme/set.json' "b set`n"; Yaz $b 'README' "b readme`n"; G $b commit -q -am b | Out-Null; G $b push -q origin main | Out-Null
    Yaz $a 'veri/deneme/set.json' "a set`n"; Yaz $a 'kaydir/smmm/hukuk.html' "kabuk a`n"
    $r = Kos $betik $a
    V '2 veri/deneme çakışması → bizimki kazanır, b''nin README''si korunur' ($r.kod -eq 0 -and (UzakDosya $uz 'veri/deneme/set.json') -eq 'a set' -and (UzakDosya $uz 'kaydir/smmm/hukuk.html') -eq 'kabuk a' -and (UzakDosya $uz 'README') -eq 'b readme') "$($r.kod) | $($r.cikti)"
    # 3) desen dışı dosyada çakışma
    $k3 = Join-Path $kok 'v3'; $uz = Kur $k3; $a = Join-Path $k3 'a'; $b = Join-Path $k3 'b'
    Yaz $b 'arac/kasa-modu.json' "liste b`n"; G $b commit -q -am b | Out-Null; G $b push -q origin main | Out-Null
    Yaz $a 'arac/kasa-modu.json' "liste a`n"
    $r = Kos $betik $a
    $rebaseOrtasi = (Test-Path (Join-Path $a '.git/rebase-merge')) -or (Test-Path (Join-Path $a '.git/rebase-apply'))
    V '3 arac/kasa-modu.json çakışması → çıkış 1, uzak ezilmez, rebase ortasında kalmaz' ($r.kod -eq 1 -and (UzakDosya $uz 'arac/kasa-modu.json') -eq 'liste b' -and -not $rebaseOrtasi) "$($r.kod) | rebase ortası $rebaseOrtasi | $($r.cikti)"
    # 4) değişiklik yok
    $k4 = Join-Path $kok 'v4'; $uz = Kur $k4; $a = Join-Path $k4 'a'
    $once = (G $a rev-parse HEAD) -join ''
    $r = Kos $betik $a
    V '4 değişiklik yok → çıkış 0, commit yok' ($r.kod -eq 0 -and ((G $a rev-parse HEAD) -join '') -eq $once -and $r.cikti -match 'degisiklik yok') "$($r.kod) | $($r.cikti)"
    # 5) uzak hep reddeder → 3 deneme
    $k5 = Join-Path $kok 'v5'; $uz = Kur $k5; $a = Join-Path $k5 'a'
    $hook = Join-Path $uz 'hooks/pre-receive'; [IO.File]::WriteAllText($hook, "#!/bin/sh`necho red >&2`nexit 1`n", (New-Object Text.UTF8Encoding($false)))
    if (Get-Command chmod -ErrorAction SilentlyContinue) { & chmod +x $hook }
    Yaz $a 'veri/deneme/set.json' "a 5`n"
    $r = Kos $betik $a
    V '5 uzak hep reddeder → 3 denemede çıkış 1' ($r.kod -eq 1 -and $r.cikti -match '3 denemede itilemedi') "$($r.kod) | $($r.cikti)"
    # 7) KİRLİ ÇALIŞMA AĞACI + itme reddi (01.11 yayın 41279967041: had-tutar-tarama izlenen dosyayı kirli bırakıyordu, rebase başlamadı)
    $k7 = Join-Path $kok 'v7'; $uz = Kur $k7; $a = Join-Path $k7 'a'; $b = Join-Path $k7 'b'
    Yaz $b 'veri/deneme/diger.json' "b diger`n"; G $b add -A | Out-Null; G $b commit -q -m b | Out-Null; G $b push -q origin main | Out-Null
    Yaz $a 'README' "a kirli`n"; Yaz $a 'veri/deneme/set.json' "a 7`n"
    $r = Kos $betik $a
    $aReadme = [IO.File]::ReadAllText((Join-Path $a 'README'))
    V '7 kirli ağaç + itme reddi → itildi, kirli dosya commit''e girmedi ve yerinde kaldı' ($r.kod -eq 0 -and (UzakDosya $uz 'veri/deneme/set.json') -eq 'a 7' -and (UzakDosya $uz 'veri/deneme/diger.json') -eq 'b diger' -and (UzakDosya $uz 'README') -eq 'ilk' -and $aReadme.Trim() -eq 'a kirli') "$($r.kod) | README uzak '$(UzakDosya $uz 'README')' yerel '$($aReadme.Trim())' | $($r.cikti)"
    # 6) STATİK: iş akışı bağı
    $yml = [IO.File]::ReadAllText($ymlYol, [Text.Encoding]::UTF8)
    $adim = [regex]::Match($yml, '(?s)- name: Bitirme kabuklarini it\r?\n(.*?)(\r?\n\s*\r?\n|\r?\n\s+- name:)').Groups[1].Value
    V '6 STATİK: iş akışı adımı kabuk-it.ps1''i çağırır, çıkışı geçirir, merge döngüsü yok' ($adim -match '\./arac/kabuk-it\.ps1' -and $adim -match 'exit \$LASTEXITCODE' -and $adim -notmatch 'git merge' -and $adim -notmatch 'git push') "adım uzunluğu $($adim.Length)"
  } finally { if (Test-Path $kok) { Remove-Item -LiteralPath $kok -Recurse -Force -ErrorAction SilentlyContinue } }
  $script:vakaSay = $script:okSay + $kalan.Count
  return , $kalan
}

$MUTASYONLAR = @(
  @{ ad = 'M1 çakışma çözümü yok (her çakışmada dur)'; eski = 'if (-not $cakisma.Count -or $yabanci.Count) {'; yeni = 'if ($true) {' }
  @{ ad = 'M2 her dosya bizim sayılıyor'; eski = 'function BizimMi([string]$yol) {'; yeni = 'function BizimMi([string]$yol) { return $true;' }
  @{ ad = 'M3 tek deneme (rebase sonrası itme yok)'; eski = 'for ($i = 1; $i -le $Deneme; $i++) {'; yeni = 'for ($i = 1; $i -le 1; $i++) {' }
  @{ ad = 'M5 autostash yok (kirli ağaçta rebase başlamaz)'; eski = 'git rebase -q --autostash origin/main'; yeni = 'git rebase -q origin/main' }
  @{ ad = 'M4 değişiklik yok denetimi yok'; eski = "if (-not `$degisen.Count) { 'kabuklarda degisiklik yok - commit ATILMADI'; exit 0 }"; yeni = '' }
)
if (-not $Mutasyon) {
  $kalan = SinavKos $betikMetin
  ''
  "KABUK İTME ÖZ-SINAVI: $($script:vakaSay - $kalan.Count)/$($script:vakaSay) geçti"
  if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
  Write-Host 'YEŞİL' -ForegroundColor Green; exit 0
}
$kirmizi = 0
foreach ($m in $MUTASYONLAR) {
  if (-not $betikMetin.Contains($m.eski)) { throw "mutasyon hedefi yok: $($m.ad)" }
  $k = SinavKos ($betikMetin.Replace($m.eski, $m.yeni))
  if ($k.Count) { $kirmizi++; "  KIRMIZI (beklenen) $($m.ad) → $($k.Count) vaka düştü: $($k[0])" } else { Write-Host "  YEŞİL KALDI (SINAV EKSİK) $($m.ad)" -ForegroundColor Red }
}
"MUTASYON: $kirmizi/$($MUTASYONLAR.Count) bozma KIRMIZI düşürdü"
if ($kirmizi -ne $MUTASYONLAR.Count) { exit 1 }
exit 0
