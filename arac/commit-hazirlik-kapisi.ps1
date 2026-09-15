# ============================================================================
#  COMMIT HAZIRLIK KAPISI — Claude Code PreToolUse hook   15.09.2026
#
#  NEDEN VAR (Cem 15.09 "1.2.3 üçünü de yap", GM önerisi 3): aynı depoda iki Claude oturumu çalışırken biri
#  `git add X` ile dosya hazırlayıp commit'i sonraki çağrıya bırakınca, araya giren öteki oturumun yolsuz
#  `git commit -F mesaj` çağrısı hazırlık alanındaki HER ŞEYİ kendi commit'ine kattı. 14.09'da İKİ KEZ ölçüldü:
#   · bitirme harita + üretici satırı + SPK planı "Mat r16 konu dosyası" commit'ine (acd3e225) girdi,
#   · ilk oturumun commit'i "On branch main / nothing to commit" deyip boş döndü.
#  Kayıp yok ama commit mesajı (neden/ölçüm/eşdeğerlik kaydı) yok oldu; yanlış dosya ters yöne de gidebilir.
#
#  NE YAPAR: `git commit` çağrısı açık yol listesi (`-- <dosyalar>`) VERMİYORSA hazırlık alanındaki dosyalara
#  bakar; bu çağrının METNİNDE anılmayan hazırlanmış dosya varsa çağrıyı ENGELLER (çıkış 2) ve listeyi söyler.
#  Anılmış sayılır: yol aynen geçiyor · anılan bir klasörün altında · `git add -A/--all/.` ya da `commit -a` var.
#  NE YAPMAZ: `-- <dosyalar>` ile yollu commit, hazırlık alanı boşken, git dışı komut — hepsi serbest.
#  Robotlar (GitHub Actions) Claude hook'undan geçmez; etkilenmez.
#  ÖZ-SINAV: powershell -NoProfile -File arac/commit-hazirlik-kapisi.ps1 -Sinav
# ============================================================================
param([switch]$Sinav)
$ErrorActionPreference = 'Stop'

function HazirlikKarari([string]$komut, [string[]]$hazir) {
  if ($komut -notmatch 'git\s+(-C\s+("[^"]+"|''[^'']+''|\S+)\s+)?commit\b') { return @() }
  if ($komut -match 'git\s+(-C\s+("[^"]+"|''[^'']+''|\S+)\s+)?commit\b[^;\r\n|&]*\s--\s+\S') { return @() }   # yollu commit: yalnız o dosyalar gider
  if ($komut -match 'git\s+(-C\s+\S+\s+)?add\s+(-A\b|--all\b|\.(\s|;|$))' -or $komut -match 'commit\b[^;\r\n]*\s-(a|am)\b') { return @() }
  $jetonlar = @([regex]::Split(($komut -replace '\\', '/'), '[\s"''`;|&()]+') | Where-Object { $_ })
  $eksik = New-Object System.Collections.Generic.List[string]
  foreach ($h in $hazir) {
    $hn = "$h" -replace '\\', '/'; if (-not $hn) { continue }
    $anildi = $false
    foreach ($j in $jetonlar) { $jn = $j.TrimEnd('/'); if ($jn.Length -lt 2) { continue }; if ($hn -eq $jn -or $hn.EndsWith('/' + $jn) -or $hn.StartsWith($jn + '/') -or $hn -like "*/$jn/*") { $anildi = $true; break } }
    if (-not $anildi) { $eksik.Add($hn) }
  }
  return $eksik.ToArray()
}

if ($Sinav) {
  $vakalar = @(
    @{ ad = 'git commit degil'; k = 'git status'; h = @('a/b.ps1'); b = 0 },
    @{ ad = 'hazirlik bos'; k = 'git commit -F m.txt'; h = @(); b = 0 },
    @{ ad = 'ayni cagrida add + commit'; k = "git add motor/x.ps1 veri/y.json`ngit commit -F m.txt"; h = @('motor/x.ps1', 'veri/y.json'); b = 0 },
    @{ ad = '14.09 vakasi: baskasinin dosyasi'; k = "git add veri/sinav/konu/sgs-gm5-mat-r16.json; git commit -F m.txt"; h = @('veri/sinav/konu/sgs-gm5-mat-r16.json', 'veri/sinav/smmm-konu-dayanak.json', 'motor/kalip-parti-uret.ps1'); b = 2 },
    @{ ad = 'yollu commit (--)'; k = 'git commit -F m.txt -- motor/kalip-parti-uret.ps1'; h = @('motor/kalip-parti-uret.ps1', 'veri/baska.json'); b = 0 },
    @{ ad = 'klasor anildi'; k = 'git add veri/sinav/konu; git commit -m "konu"'; h = @('veri/sinav/konu/a.json', 'veri/sinav/konu/b.json'); b = 0 },
    @{ ad = 'add -A'; k = 'git add -A; git commit -m "hepsi"'; h = @('x/y.json'); b = 0 },
    @{ ad = 'ters bolu + -C'; k = 'git -C "C:\d\mevzuat-radar" commit -F m.txt motor\kalip-kosucu.ps1'; h = @('motor/kalip-kosucu.ps1'); b = 0 },
    @{ ad = 'yolsuz commit, onceden hazirlanmis'; k = 'git commit -q -F C:/t/m.txt'; h = @('arac/smmm-onay.ps1'); b = 1 }
  )
  $kotu = 0
  foreach ($v in $vakalar) { $e = @(HazirlikKarari $v.k $v.h).Count; $ok = ($e -eq $v.b); if (-not $ok) { $kotu++ }; Write-Host ("  {0,-40} engellenen={1} beklenen={2} {3}" -f $v.ad, $e, $v.b, $(if ($ok) { 'OK' } else { 'HATA' })) }
  if ($kotu) { Write-Host "  $kotu vaka DUSTU - kapi bozuk" -ForegroundColor Red; exit 2 }
  Write-Host ("  {0}/{0} GECTI" -f $vakalar.Count) -ForegroundColor Green; exit 0
}

try { $ham = [Console]::In.ReadToEnd(); if (-not $ham) { exit 0 }; $veri = $ham | ConvertFrom-Json } catch { exit 0 }
$komut = ''; try { $komut = "$($veri.tool_input.command)" } catch { }
if ($komut -notmatch 'git\s+(-C\s+\S+\s+)?commit\b') { exit 0 }
# depo: -C verilmişse o, yoksa hook'un çalışma dizini
$depo = ''; $mC = [regex]::Match($komut, 'git\s+-C\s+("([^"]+)"|''([^'']+)''|(\S+))\s+commit'); if ($mC.Success) { $depo = @($mC.Groups[2].Value, $mC.Groups[3].Value, $mC.Groups[4].Value) | Where-Object { $_ } | Select-Object -First 1 }
if (-not $depo) { try { $depo = "$($veri.cwd)" } catch { } }
if (-not $depo) { $depo = (Get-Location).Path }
$hazir = @()
# K6: PS 5.1'de yerel komut + stderr yönlendirmesi + EAP=Stop başarılı çağrıyı da düşürür → kapı sessizce açılırdı. Yönlendirme yok, EAP bu satırda Continue.
$ErrorActionPreference = 'Continue'; $hazir = @(& git -C $depo diff --cached --name-only | Where-Object { $_ }); if ($LASTEXITCODE -ne 0) { exit 0 }
if (-not $hazir.Count) { exit 0 }
$eksik = @(HazirlikKarari $komut $hazir)
if (-not $eksik.Count) { exit 0 }
$liste = ($eksik | Select-Object -First 15 | ForEach-Object { "    $_" }) -join "`n"
[Console]::Error.WriteLine(@"
COMMIT HAZIRLIK KAPISI — bu cagri ENGELLENDI.

Hazirlik alaninda bu cagrida ANILMAYAN $($eksik.Count) dosya var (baska bir oturum hazirlamis olabilir):
$liste

Yolsuz "git commit" bunlari da senin commit'ine katar (14.09'da iki kez oldu: bitirme dosyalari "Mat r16" commit'ine girdi).
DOGRUSU - yalniz kendi dosyalarini yolla ver:
    git commit -F <mesaj-dosyasi> -- <dosya1> <dosya2>
Hepsi gercekten senin ise ayni cagrida "git add <dosyalar>" ile an ya da "git add -A" kullan.
"@)
exit 2
