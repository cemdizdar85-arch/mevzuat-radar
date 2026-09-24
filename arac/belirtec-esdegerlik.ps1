#requires -Version 5.1
<#
================================================================================
  BELİRTEÇ EŞDEĞERLİK PROVASI — "değmeyen soru çekilmez" kuralı değişince hangi soru kararı değişir?   24.09.2026 · bedel 0
  CLAUDE.md EŞDEĞERLİK: eski/yeni mantık TAMAMINDA kıyaslanır, örneklem yok. Burada "tamamı" = kanun aynalarının git
  geçmişindeki (son -Gun gün) HER madde değişikliği × o maddeyi kaynak gösteren HER soru (yerel kalip-parti-*.json).
  Bir sürüm (-FonkYolu: arac/mevzuat-degisti.ps1'in eski ya da yeni hâli) dot-source edilir; çıktı TSV:
    commit · madde anahtarı · soru kimliği · çekilir(1/0) · belirsiz(1/0)
  İki sürümün çıktısı arac/belirtec-esdegerlik.ps1 -Kiyas eski.tsv yeni.tsv ile karşılaştırılır.
  ⛔ REPLİKA YOK: MdAnahtar / MdAyirtEdici / MdSoruDegiyor verilen sürümden gelir.
  🚫 GÖRMEZ: ilk kez eklenen dosyalar (eskisi yok); teori notları (ayrı dosya); soru ile madde eşlemesi MdAnahtar ile yapılır.
================================================================================
#>
param([string]$FonkYolu = '', [int]$Gun = 60, [string]$Cikti = '', [string[]]$Kiyas = @())
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
if ($Kiyas.Count -eq 2) {
  function Oku([string]$y) { $h = @{}; foreach ($l in [IO.File]::ReadAllLines($y, [Text.Encoding]::UTF8)) { $p = $l.Split("`t"); if ($p.Count -ge 5) { $h["$($p[0])|$($p[1])|$($p[2])"] = $p[3] } }; return $h }
  $a = Oku $Kiyas[0]; $b = Oku $Kiyas[1]
  $yeniCek = @($b.Keys | Where-Object { $b[$_] -eq '1' -and $a[$_] -ne '1' }); $artikCekmez = @($a.Keys | Where-Object { $a[$_] -eq '1' -and $b[$_] -ne '1' })
  "EŞDEĞERLİK: incelenen (değişiklik × soru) $($a.Count) · eski çeker $(@($a.Values | ? { $_ -eq '1' }).Count) · yeni çeker $(@($b.Values | ? { $_ -eq '1' }).Count)"
  "  YENİ kuralın EK çektiği (güvenli yön): $($yeniCek.Count) · YENİ kuralın ARTIK ÇEKMEDİĞİ (okunmalı): $($artikCekmez.Count)"
  $artikCekmez | Sort-Object | Select-Object -First 60 | ForEach-Object { "    - $_" }
  "  EK çekilenlerden örnek:"; $yeniCek | Sort-Object | Select-Object -First 15 | ForEach-Object { "    + $_" }
  return
}
. $FonkYolu
# soru dizini: madde anahtarı → sorular
$dizin = @{}; $nSoru = 0
foreach ($f in Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-*.json') {
  $et = $f.BaseName -replace '^kalip-parti-', ''
  try { $j = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { continue }
  foreach ($p in $j.PSObject.Properties) { $v = $p.Value; if (-not $v -or -not $v.PSObject.Properties['soru'] -or -not $v.soru) { continue }; $nSoru++
    foreach ($ka in @($v.kaynak_adlar)) { $an = MdAnahtar "$ka"; if (-not $an) { continue }; if (-not $dizin.ContainsKey($an)) { $dizin[$an] = New-Object System.Collections.Generic.List[object] }; $dizin[$an].Add([pscustomobject]@{ id = "$et/$($p.Name)"; v = $v }) } }
}
Write-Host "soru $nSoru · kaynak gösterilen madde $($dizin.Count)"
function MaddeMetin($belgeler) { $m = @{}; foreach ($d in @($belgeler)) { $a = MdAnahtar "$($d.kaynak_ad)"; if ($a) { $m[$a] = "$($m[$a]) $($d.metin)" } }; return $m }
function GitJson([string]$ref) { $ErrorActionPreference = 'Continue'; $t = (& git -C $kok show $ref) -join "`n"; if (-not $t) { return $null }; try { return ($t | ConvertFrom-Json) } catch { return $null } }
function GitVarMi([string]$ref) { $ErrorActionPreference = 'Continue'; & git -C $kok cat-file -e $ref; return ($LASTEXITCODE -eq 0) }
# PS 5.1: git'in stderr'i (eski sürüm yoksa "fatal") ErrorActionPreference=Stop altında betiği DURDURUYORDU (24.09 ilk koşu) → Continue
$ErrorActionPreference = 'Continue'
$satir = New-Object System.Collections.Generic.List[string]; $nDeg = 0
foreach ($h in @(git -C $kok log --since="$Gun.days" --format=%H -- veri/mevzuat)) {
  foreach ($f in @(git -C $kok diff-tree --no-commit-id --name-only -r $h -- veri/mevzuat)) {
    $b = Split-Path $f -Leaf; if ($b -like '_*' -or $b -like 'teori-notlari*' -or $b -notlike '*.json') { continue }
    if (-not (GitVarMi "$h^:$f")) { continue }
    $eJ = GitJson "$h^:$f"; $yJ = GitJson "$h`:$f"; if (-not $eJ -or -not $yJ -or -not $eJ.PSObject.Properties['belgeler']) { continue }
    $eM = MaddeMetin $eJ.belgeler; $yM = MaddeMetin $yJ.belgeler
    foreach ($a in $eM.Keys) {
      if (-not $yM.ContainsKey($a) -or -not $dizin.ContainsKey($a)) { continue }
      $af = MdAyirtEdici $eM[$a] $yM[$a]; if ($null -ne $af -and @($af).Count -eq 0) { continue }
      $nDeg++; $bel = ($null -eq $af)
      foreach ($q in $dizin[$a]) { $cek = $(if ($bel) { 1 } elseif (@(MdSoruDegiyor $q.v $af).Count) { 1 } else { 0 }); $satir.Add("$($h.Substring(0,8))`t$a`t$($q.id)`t$cek`t$([int]$bel)") }
    }
  }
}
[IO.File]::WriteAllLines($Cikti, $satir, (New-Object Text.UTF8Encoding $false))
"PROVA ($FonkYolu): değişen madde (soru kaynağı olan) $nDeg · satır $($satir.Count)"
