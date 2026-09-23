#requires -Version 5.1
<#
================================================================================
  SMMM KONU–SORU UYUMU — PARASIZ ÖN ÖLÇÜM   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): site oturumu 94 vitrin sorusunu elle okudu; bazı soruların KONU ETİKETİ
  soruyla uyuşmuyor ("kdv mahsubu" → sipariş avansı mahsubu; "görüş bildirmekten kaçınma" → KYS 2). Etiket
  yanlışsa rozetteki "N kez çıktı" iddiası yanlış, kapsama tablosundaki "yazdık" sayısı şişkin olur.

  ÖLÇÜ (kelime): konu adının anlamlı kelimeleri (≥3 harf, dolgu kelimeler hariç, ilk 5 harf kökü) soru kökü +
  şıklarda geçiyor mu? puan = geçen / toplam. puan < -Esik → ŞÜPHELİ (model kontrolüne aday).
  ÖLÇÜNÜN KENDİSİ SINANIR (kapı kuralı md.2): site oturumunun ELLE okuduğu sorular anahtar —
    yanlış etiketli 12 (arac/vitrin-haric.json, "kök bozuk" hariç) · doğru etiketli 70 (vitrin seçimi).
  Rapor yakalama ve yanlış alarm oranını YAZAR; oran kötüyse bu ölçü karar vermez, yalnız sıralar.
  🚫 GÖRMEZ: ince konu kayması (aynı kelimeyi paylaşan komşu konu — "GÜG birinci dağıtım" etiketiyle kademeli
     dağıtım sorusu); eş anlamlı (konu "hizmet akdi", soru "iş sözleşmesi"). Bunlar ancak model/insan okumasıyla.
  ÇIKTI: veri/sinav/SMMM-KONU-UYUM.md (sayılar, soru metni YOK) · veri/fabrika/smmm-konu-uyum-supheli.json (kimlik, gitignore)
  KULLANIM: powershell -NoProfile -File arac/smmm-konu-uyum-olc.ps1 [-Esik 0.34]
================================================================================
#>
param([double]$Esik = 0.34)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1'); . (Join-Path $buDizin 'smmm-ders-adi.ps1')
$onay = SmmmOnayHarita $kok
function Nrm([string]$s) {
  $t = "$s".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant() -replace 'ı', 'i' -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'
  return (($t -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}
$DOLGU = @{}; foreach ($w in 'ile ve veya icin gore olarak olan hesap hesabi hesaplari kaydi kayitlari islem islemleri genel ozel diger tur turleri unsurlari tanimi esaslari hukumleri uygulama uygulamasi'.Split(' ')) { $DOLGU[$w] = 1 }
function Puan([string]$konu, [string]$metin) {
  $kel = @((Nrm $konu).Split(' ') | Where-Object { $_.Length -ge 3 -and -not $DOLGU.ContainsKey($_) })
  if (-not $kel.Count) { return -1 }
  $m = ' ' + (Nrm $metin) + ' '
  $gec = 0; foreach ($k in $kel) { $kk = $k.Substring(0, [Math]::Min(5, $k.Length)); if ($m.Contains(' ' + $kk)) { $gec++ } }
  return [Math]::Round($gec / $kel.Count, 2)
}
# anahtar
$yanlis = @{}; $h = Get-Content (Join-Path $buDizin 'vitrin-haric.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($p in $h.haric.PSObject.Properties) { if ("$($p.Value)" -match '^etiket') { $yanlis[$p.Name] = 1 } }
$dogru = @{}; foreach ($s in @(Get-Content (Join-Path $kok 'veri\sinav\kaydir-secim\vitrin-smmm-secim.json') -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })) { $dogru["$($s.etiket)/$($s.id)"] = 1 }

$sonuc = New-Object System.Collections.Generic.List[object]
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json')) {
  $et = $f.BaseName -replace '^kalip-parti-', ''; if ($et -match '(^|-)pilot\d*(-|$)') { continue }
  $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($o in $j.PSObject.Properties) {
    if ($o.Name -notlike 'kp-*') { continue }; $v = $o.Value; if (-not $v -or -not $v.soru) { continue }
    $an = "$et/$($o.Name)"
    $kasa = (SmmmYayinSarti $an $v $onay).gecer
    if (-not $kasa -and -not $yanlis.ContainsKey($an) -and -not $dogru.ContainsKey($an)) { continue }
    $metin = "$($v.soru) " + ((@('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$($v.siklar.$_)" }) -join ' ')
    $sonuc.Add([pscustomobject]@{ an = $an; ders = (SmmmDersAdi $et $null); konu = "$($v.konu)"; puan = (Puan "$($v.konu)" $metin); kasa = $kasa })
  }
}
$ky = @($sonuc | Where-Object { $yanlis.ContainsKey($_.an) }); $kd = @($sonuc | Where-Object { $dogru.ContainsKey($_.an) })
$yak = @($ky | Where-Object { $_.puan -ge 0 -and $_.puan -lt $Esik }); $ya = @($kd | Where-Object { $_.puan -ge 0 -and $_.puan -lt $Esik })
$kasaS = @($sonuc | Where-Object { $_.kasa }); $sup = @($kasaS | Where-Object { $_.puan -ge 0 -and $_.puan -lt $Esik }); $olcmez = @($kasaS | Where-Object { $_.puan -lt 0 })
$oz = "KONU UYUMU (kelime, eşik $Esik): kasa adayı $($kasaS.Count) · ŞÜPHELİ $($sup.Count) · ölçülemeyen (konu adında anlamlı kelime yok) $($olcmez.Count) · ANAHTAR: yanlış etiketli $($ky.Count)'in $($yak.Count)'ini yakaladı · doğru etiketli $($kd.Count)'in $($ya.Count)'ine yanlış alarm"
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# SMMM KONU–SORU UYUMU — parasız ön ölçüm'); $md.Add('')
$md.Add("> Türetilmiştir (``arac/smmm-konu-uyum-olc.ps1``). $(Get-Date -Format 'dd.MM.yyyy HH:mm') · bedel 0 · soru metni YOK"); $md.Add('')
$md.Add("**$oz**"); $md.Add('')
$md.Add('Anahtar = site oturumunun elle okuduğu sorular (23.09). Yakalama düşükse bu ölçü karar vermez; yalnız model/insan okumasının SIRASINI kurar.'); $md.Add('')
$md.Add('| ders | kasa adayı | şüpheli | oran |'); $md.Add('|---|---:|---:|---:|')
foreach ($g in ($kasaS | Group-Object ders | Sort-Object Name)) { $s = @($g.Group | Where-Object { $_.puan -ge 0 -and $_.puan -lt $Esik }).Count; $md.Add("| $($g.Name) | $($g.Count) | $s | $([Math]::Round(100.0 * $s / [Math]::Max(1, $g.Count), 1))% |") }
$md.Add(''); $md.Add('## Anahtar ayrıntısı (yanlış etiketliler)'); $md.Add('| kimlik | puan | yakalandı |'); $md.Add('|---|---:|---|')
foreach ($x in $ky) { $md.Add("| $($x.an) | $($x.puan) | $(if ($x.puan -ge 0 -and $x.puan -lt $Esik) { 'EVET' } else { 'hayır' }) |") }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\SMMM-KONU-UYUM.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
[IO.File]::WriteAllText((Join-Path $kok 'veri\fabrika\smmm-konu-uyum-supheli.json'), (ConvertTo-Json -InputObject @($sup | ForEach-Object { [ordered]@{ an = $_.an; ders = $_.ders; konu = $_.konu; puan = $_.puan } }) -Depth 3), (New-Object Text.UTF8Encoding $false))
$oz
foreach ($x in $ky) { "  yanlış etiketli $($x.an) puan $($x.puan)" }
