# arac/sozluk-hizli-prova.ps1 — sözlük hızlandırmasının EŞDEĞERLİK PROVASI (03.10.2026)
# Eski PS yolu (kaydir-coz.ps1'deki Katla + iç döngü) ile yeni yol ([TtSozluk]::Ekle) AYNI partilerden sözlük kurar;
# sonuç sözlükleri (SOZ, ENF, IVAR) anahtar sıralı JSON olarak BAYT BAYT kıyaslanır, süreler yazılır.
#   powershell -NoProfile -File arac/sozluk-hizli-prova.ps1            # ambarın TAMAMI (kural: örneklem yasak)
#   powershell -NoProfile -File arac/sozluk-hizli-prova.ps1 -Sinir 40  # yalnız geliştirme denemesi - sonuç İDDİA EDİLMEZ
# Çıkış: 0 aynı · 1 fark var. Katla, motor/kaydir-coz.ps1'den OKUNUR (kopya değil) - kalıptaki tanım değişirse prova onu sınar.
# Mutasyon: -Mutasyon verilirse yeni yolun sonucu bilerek bozulur; prova KIRMIZI vermelidir (prova kör mü sınaması).
param([int]$Sinir = 0, [switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'sozluk-hizli.ps1')
$kalip = [IO.File]::ReadAllText((Join-Path $kok 'motor\kaydir-coz.ps1'))
$m = [regex]::Match($kalip, '(?m)^function Katla\(.*$')
if (-not $m.Success) { throw 'Katla kaydir-coz.ps1 içinde bulunamadı' }
Invoke-Expression $m.Value

$dosyalar = @(Get-ChildItem (Join-Path $kok 'veri\fabrika\kalip-parti-*.json') | Sort-Object Name)
if ($Sinir -gt 0) { $dosyalar = @($dosyalar | Select-Object -First $Sinir) }
"parti: $($dosyalar.Count)$(if($Sinir){' (DENEME - örneklem, iddia edilmez)'})"

# kaydir-coz.ps1 satır 182-189 ile aynı metin toplama (her iki yol aynı metinleri alır)
$tumMetin = New-Object System.Collections.Generic.List[string]
foreach ($cf in $dosyalar) {
  try { $c = Get-Content $cf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach ($pp in $c.PSObject.Properties) {
    $v = $pp.Value; $metinler = @("$($v.soru)", "$($v.hap)", "$($v.sinav_taktigi)", "$($v.notlandirici)", "$($v.konu)")
    if ($v.siklar) { foreach ($h in 'A', 'B', 'C', 'D', 'E') { $metinler += "$($v.siklar.$h)" } }
    if ($v.aciklama) { foreach ($h in 'A', 'B', 'C', 'D', 'E') { if ($v.aciklama.PSObject.Properties[$h] -and $v.aciklama.$h -is [string]) { $metinler += "$($v.aciklama.$h)" } } }
    foreach ($a0 in @($v.adimlar)) { if ($a0 -and $a0.PSObject.Properties['anlatim']) { $metinler += "$($a0.anlatim)" } }
    if ($v.sade) { $metinler += "$($v.sade.dogru)"; foreach ($kv0 in @($v.sade.kavramlar)) { if ($kv0) { $metinler += "$($kv0.tanim)" } } }
    foreach ($mt in $metinler) { $tumMetin.Add($mt) }
  }
}
"metin: $($tumMetin.Count)"

function Sec($SAY) {   # kaydir-coz.ps1 satır 193-199 ile aynı
  $SOZ = @{}; $ENF = @{}; $IVAR = @{}
  foreach ($k in $SAY.Keys) {
    $h = $SAY[$k]; $enIyi = $null; $enIyiN = 0; $asciiN = 0; $enSikBicim = $null; $enSikSayi = 0
    foreach ($y in $h.Keys) { if ($h[$y] -gt $enSikSayi) { $enSikBicim = $y; $enSikSayi = $h[$y] }; if ($y.StartsWith('i') -or $y.StartsWith('İ')) { $IVAR[$k] = $true }; if ($y -eq $k) { $asciiN = $h[$y] } elseif ($h[$y] -gt $enIyiN) { $enIyi = $y; $enIyiN = $h[$y] } }
    if ($enSikBicim) { $ENF[$k] = $enSikBicim }
    if ($enIyi -and $enIyiN -ge 2 -and $enIyiN -ge 3 * $asciiN) { $SOZ[$k] = $enIyi }
  }
  $dz = { param($t) ($t.Keys | Sort-Object -CaseSensitive | ForEach-Object { "$_`t$($t[$_])" }) -join "`n" }
  return (& $dz $SOZ) + "`n#ENF`n" + (& $dz $ENF) + "`n#IVAR`n" + (& $dz $IVAR)
}

$t0 = Get-Date; $SAY1 = @{}
foreach ($mt in $tumMetin) { foreach ($mm in [regex]::Matches($mt, '[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]{3,}')) { $w = $mm.Value; $lw = $w.ToLower([cultureinfo]::GetCultureInfo('tr-TR')); $k = Katla $w; if (-not $SAY1.ContainsKey($k)) { $SAY1[$k] = @{} }; if (-not $SAY1[$k].ContainsKey($lw)) { $SAY1[$k][$lw] = 0 }; $SAY1[$k][$lw]++ } }
$sEski = [int]((Get-Date) - $t0).TotalSeconds
$t1 = Get-Date; $SAY2 = @{}
foreach ($mt in $tumMetin) { [TtSozluk]::Ekle($SAY2, $mt) }
$sYeni = [math]::Round(((Get-Date) - $t1).TotalSeconds, 1)
if ($Mutasyon) { $SAY2['zzmutasyonkoku'] = @{ 'zzmutasyonkoku' = 1 } }   # ENF'e kesin girer -> prova FARKLI demeli

$a = Sec $SAY1; $b = Sec $SAY2
"sayım: eski $sEski sn · yeni $sYeni sn · kök $($SAY1.Count) / $($SAY2.Count)"
if ($a -ceq $b) { "SONUÇ: AYNI (SOZ+ENF+IVAR bayt bayt, $($a.Length) karakter)"; exit 0 }
$la = $a -split "`n"; $lb = $b -split "`n"; $f = 0
for ($i = 0; $i -lt [Math]::Max($la.Count, $lb.Count) -and $f -lt 5; $i++) { if ($la[$i] -cne $lb[$i]) { "  FARK satır $i : eski [$($la[$i])] yeni [$($lb[$i])]"; $f++ } }
"SONUÇ: FARKLI"; exit 1
