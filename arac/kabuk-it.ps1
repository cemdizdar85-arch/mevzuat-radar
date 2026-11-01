#requires -Version 5.1
<#
================================================================================
  BİTİRME KABUKLARINI İT — REBASE + 3 DENEME  (01.11.2026)  bedel 0

  NİYE: .github/workflows/smmm-kasa-yayin.yml "Bitirme kabuklarini it" adımı itme reddinde `git merge origin/main`
    yapıyor, çakışma çıkınca "elle bakılmalı" deyip işi KIRMIZI bitiriyordu. 01.11 koşu 41260611845: kasa yazıldı
    (3.665 satır) ama veri/deneme/smmm-ders-*.json başka robotun aynı anda yazdığı dosyayla çakıştı → yayın kırmızı,
    kabuk/deneme setleri itilmedi. O dosyalar BU koşunun yazdığı kasadan üretilir; çakışmada bizimki tazedir.
  NASIL: değişen yollar (kaydir/smmm · arac/kasa-modu.json · veri/deneme) tek commit → push. Red gelirse
    fetch + `git rebase origin/main` (depodaki öteki iş akışlarının `git pull --rebase` + 3 deneme kalıbı).
    Rebase çakışırsa: çakışan HER dosya "bizim üretimimiz" desenine uyuyorsa (veri/deneme/** · kaydir/smmm/*.html)
    bizim commit'teki hâli alınır ve rebase sürer; desen DIŞI bir dosya çakışırsa (ör. arac/kasa-modu.json, insan işi)
    rebase geri alınır, iş KIRMIZI biter — üstüne yazılmaz.
  ÇIKIŞ: 0 itildi / değişiklik yok · 1 itilemedi (desen dışı çakışma ya da deneme bitti).
  ÖZ-SINAV: arac/kabuk-it-sinavi.ps1 (geçici çıplak depo + iki klon; dogrula.yml).
  🚫 GÖRMEZ: bizim desendeki dosyada ÖTEKİ yazarın daha yeni olması (bu adımda bizimki son kasadan üretildiği için kabul) ·
    kabuğun sorusuz olduğu (o denetim iş akışında, bu betikten ÖNCE).
================================================================================
#>
param([string]$Mesaj = 'Bitirme kabuklari yeni kaliple', [string]$Kok = '', [int]$Deneme = 3, [int]$BeklemeSn = 5,
  [string[]]$Yollar = @('kaydir/smmm', 'arac/kasa-modu.json', 'veri/deneme'),
  [string[]]$BizimDesen = @('^veri/deneme/', '^kaydir/smmm/[^/]+\.html$'))
$ErrorActionPreference = 'Continue'   # K6: yerel komutun stderr'i betiği öldürmesin; her adımın çıkış kodu okunur
if ($Kok) { Set-Location -LiteralPath $Kok }
function BizimMi([string]$yol) { foreach ($d in $BizimDesen) { if ($yol -match $d) { return $true } }; return $false }

git add -- @($Yollar | Where-Object { Test-Path $_ }) 2>&1 | Out-Null
$degisen = @(git diff --cached --name-only)
if (-not $degisen.Count) { 'kabuklarda degisiklik yok - commit ATILMADI'; exit 0 }
"degisen dosya: $($degisen.Count)"
git commit -q -m $Mesaj 2>&1 | Out-Null
if ($LASTEXITCODE) { '::error::commit atilamadi'; exit 1 }
$bizim = "$(git rev-parse HEAD)".Trim()

for ($i = 1; $i -le $Deneme; $i++) {
  git push -q origin HEAD:main 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { "itildi (deneme $i)"; exit 0 }
  git fetch -q origin main 2>&1 | Out-Null
  # 01.11 (yayın 41279967041): önceki adımlar izlenen dosyaları KİRLİ bırakıyor (had-tutar-tarama.ps1 -> veri/sinav/had-guncel.json,
  #   HAD-TUTAR-TARAMASI.md; her koşuda tarih değişir). Kirli ağaçta rebase HİÇ başlamıyordu. --autostash: kirli dosyalar rebase
  #   süresince saklanır, sonra geri konur; commit'e GİRMEZ (yalnız $Yollar eklendi). Git çıktısı hata satırına yazılır.
  $rbCikti = @(git rebase -q --autostash origin/main 2>&1 | ForEach-Object { "$_" })
  if ($LASTEXITCODE) {
    $cakisma = @(git diff --name-only --diff-filter=U)
    $yabanci = @($cakisma | Where-Object { -not (BizimMi $_) })
    if (-not $cakisma.Count -or $yabanci.Count) {
      git rebase --abort 2>&1 | Out-Null
      "::error::itme cakismasi (bizim uretim disi): $(@($(if ($yabanci.Count) { $yabanci } else { "(rebase dustu, cakisan dosya yok; git: $((@($rbCikti) | Select-Object -Last 3) -join ' / '))" })) -join ', ') - elle bakilmali"; exit 1
    }
    foreach ($f in $cakisma) { git checkout $bizim -- $f 2>&1 | Out-Null; git add -- $f 2>&1 | Out-Null }
    git -c core.editor=true rebase --continue 2>&1 | Out-Null
    if ($LASTEXITCODE) { git rebase --abort 2>&1 | Out-Null; "::error::rebase surdurulemedi ($($cakisma -join ', '))"; exit 1 }
    "cakisma bizim uretimle cozuldu (deneme $i): $($cakisma.Count) dosya"
  }
  if ($i -lt $Deneme -and $BeklemeSn -gt 0) { Start-Sleep -Seconds ($BeklemeSn * $i) }
}
"::error::$Deneme denemede itilemedi"; exit 1
