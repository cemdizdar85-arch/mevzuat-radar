#requires -Version 5.1
<#
================================================================================
  YILLIK HAD TUTARI TARAMASI — eski yıl tutarıyla yazılmış soru var mı?   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): izaha davet (VUK m.370/b) sorusunda 2026 haddi 862.400 ₺ yazılmıştı; kaynak 870.000 TL
  (588 Sıra No.'lu VUK GT). VUK/GVK/Harçlar/Veraset… onlarca had her yıl yeniden değerlenir; aynı hata başka maddede de olabilir.
  KAYNAK (güncel had): ambardaki KANUN MADDESİ metinlerinde mevzuat.gov.tr'nin konsolide şerhi "(870.000 TL)" — tebliğ örnekleri
  had sayılmaz. Madde anahtarı arac/mevzuat-degisti.ps1 MdAnahtar.
  İŞARET: sorunun dayandığı maddenin (kaynak_adlar) güncel haddi h için soruda/şıklarda/açıklamada a ≠ h, 0,6h ≤ a ≤ 1,4h bir tutar
  VE ±90 karakter içinde bir had ifadesi (öngörülen, belirlenen, haddi, had, sınırı, yılı için, geçerli, geçmeyen, aşmayan) → ŞÜPHELİ.
  Karar vermez; şüpheliyi ELLE OKUMAYA sıralar. ÖLÇÜ SINANDI: 23.09 vakası (862.400 ↔ 870.000, "öngörülen tutar") yakalanmalı.
  🚫 GÖRMEZ: yazıyla tutar ("yüz bin lira"); şerhi olmayan had (örn. yönetmelikte, tebliğde); ±%40 dışına düşen eski tutar;
     had ifadesi kullanmadan eski tutarı öncül yapan soru.
  ÇIKTI: veri/sinav/HAD-TUTAR-TARAMASI.md (kimlik + madde + tutar; soru metni YOK) · veri/fabrika/had-tutar-supheli.json
  KULLANIM: powershell -NoProfile -File arac/had-tutar-tarama.ps1
================================================================================
#>
param([double]$Alt = 0.6, [double]$Ust = 1.4, [switch]$YalnizHad)   # -YalnizHad: yalnız veri/sinav/had-guncel.json tazelenir (kasa yayını öncesi, KAPI-HAD için)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'mevzuat-degisti.ps1'); . (Join-Path $buDizin 'smmm-yayin-sarti.ps1')   # had-kapisi.ps1 (HadKokler) yayın şartıyla gelir
$onay = SmmmOnayHarita $kok
$S = $env:SUPABASE_SERVICE_KEY; if (-not $S) { $S = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY', 'User') }
$H = @{ apikey = $S; Authorization = "Bearer $S"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
function Tutar([string]$s) { $t = ($s -replace '\.', '') -replace ',', '.'; $d = 0.0; if ([double]::TryParse($t, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }; return -1 }

# --- 1) güncel had: ambardaki kanun maddelerinde "(N TL)" şerhi
$had = @{}; $hadBaglam = @{}; $son = ''; $belge = 0
$rxSerh = [regex]'\((\d{1,3}(?:\.\d{3})+(?:,\d+)?)\s*(?:TL|Türk lirası)\)'
while ($true) {
  $u = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id,kaynak_ad,metin&tur=eq.kanun-madde&metin=like.*TL)*$(if($son){"&id=gt.$son"})&order=id&limit=500"
  $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $H -TimeoutSec 180
  $j = @((ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()))) | ForEach-Object { $_ })
  if (-not $j.Count) { break }
  foreach ($d in $j) { $a = MdAnahtar "$($d.kaynak_ad)"; if (-not $a) { continue }; $belge++
    foreach ($m in $rxSerh.Matches("$($d.metin)")) { $v = Tutar $m.Groups[1].Value; if ($v -ge 1000) { if (-not $had.ContainsKey($a)) { $had[$a] = New-Object System.Collections.Generic.List[double] }; if (-not $had[$a].Contains($v)) { $had[$a].Add($v) }
        # 23.09: hangi had? — şerhten önceki 120 karakterin kökleri (KAPI-HAD yalnız aynı bağlamdaki tutarı karşılaştırır)
        $bs = [Math]::Max(0, $m.Index - 120); $kk = HadKokler ("$($d.metin)".Substring($bs, $m.Index - $bs)); $ak = "$a|$v"; if (-not $hadBaglam.ContainsKey($ak)) { $hadBaglam[$ak] = @{} }; foreach ($k in $kk) { $hadBaglam[$ak][$k] = 1 } } } }
  $son = "$($j[$j.Count-1].id)"; if ($j.Count -lt 500) { break }
}
# 23.09: KAPI-HAD (arac/had-kapisi.ps1) bu dosyayı okur — yalnız madde anahtarı + tutar (soru metni yok)
$hg = [ordered]@{}; foreach ($a in ($had.Keys | Sort-Object)) { $hg[$a] = @($had[$a] | Sort-Object | ForEach-Object { [ordered]@{ tutar = $_; baglam = @($hadBaglam["$a|$_"].Keys | Sort-Object) } }) }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\had-guncel.json'), (ConvertTo-Json -InputObject ([ordered]@{ aciklama = 'Güncel had tutarları: ambardaki KANUN MADDESİ konsolide şerhleri "(N TL)". Üreten arac/had-tutar-tarama.ps1; okuyan arac/had-kapisi.ps1 (KAPI-HAD).'; olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm'); maddeler = $hg }) -Depth 4), (New-Object Text.UTF8Encoding $false))
Write-Host ("güncel had: {0} kanun maddesinde {1} tutar ({2} belge)" -f $had.Count, (($had.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum), $belge)
if ($YalnizHad) { if ($had.Count -lt 10) { throw "had-guncel: yalnız $($had.Count) madde — ambar okuması şüpheli, dosya YAZILDI ama kontrol et" }; return }

# --- 2) sorular (SMMM: yayın şartını geçen · SGS: bütün taslaklar)
$rxTutar = [regex]'(\d{1,3}(?:\.\d{3})+(?:,\d+)?)\s*(?:TL|₺|Türk lirası|lira)'
$rxHad = '(?i)öngörül|belirlen|hadd|\bhad\b|sınır|yılı için|geçerli|geçmeyen|aşmayan'
$supheli = New-Object System.Collections.Generic.List[object]; $bakilan = 0; $haddeDayanan = 0
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-*.json' | Where-Object { $_.Name -match '^kalip-parti-(smmm|sgs)-' })) {
  $et = $f.BaseName -replace '^kalip-parti-', ''; $smmm = $et -like 'smmm-*'
  $c = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($o in $c.PSObject.Properties) {
    if ($o.Name -notlike 'kp-*') { continue }; $v = $o.Value; if (-not $v -or -not $v.soru) { continue }
    $an = "$et/$($o.Name)"; if ($smmm -and -not (SmmmYayinSarti $an $v $onay).gecer) { continue }
    $bakilan++
    $hs = New-Object System.Collections.Generic.List[double]; $mad = New-Object System.Collections.Generic.List[string]
    foreach ($ka in @($v.kaynak_adlar)) { $a = MdAnahtar "$ka"; if ($a -and $had.ContainsKey($a)) { foreach ($x in $had[$a]) { if (-not $hs.Contains($x)) { $hs.Add($x) } }; if (-not $mad.Contains($a)) { $mad.Add($a) } } }
    if (-not $hs.Count) { continue }; $haddeDayanan++
    $metin = "$($v.soru) " + ((@('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$($v.siklar.$_)" }) -join ' | ') + ' ' + ($v.aciklama | ConvertTo-Json -Compress -Depth 4)
    foreach ($m in $rxTutar.Matches($metin)) {
      $a = Tutar $m.Groups[1].Value; if ($a -lt 1000 -or $hs.Contains($a)) { continue }
      $yakin = @($hs | Where-Object { $a -ge $Alt * $_ -and $a -le $Ust * $_ })
      if (-not $yakin.Count) { continue }
      $bas = [Math]::Max(0, $m.Index - 90); $cevre = $metin.Substring($bas, [Math]::Min($metin.Length - $bas, $m.Length + 180))
      if ($cevre -notmatch $rxHad) { continue }
      $supheli.Add([pscustomobject][ordered]@{ an = $an; madde = ($mad -join ','); bulunan = $m.Groups[1].Value; varsayim = [bool]($cevre -match '(?i)varsay'); guncel_had = (($yakin | ForEach-Object { $_.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }) -join ' / ') })
      break
    }
  }
}
$oz = "HAD TUTARI TARAMASI: bakılan soru $bakilan · şerhli maddeye dayanan $haddeDayanan · ŞÜPHELİ $($supheli.Count)"
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# YILLIK HAD TUTARI TARAMASI'); $md.Add('')
$md.Add("> Türetilmiştir (``arac/had-tutar-tarama.ps1``). $(Get-Date -Format 'dd.MM.yyyy HH:mm') · bedel 0 · soru metni YOK · güncel had = ambardaki kanun maddesi şerhi"); $md.Add('')
$md.Add("**$oz**"); $md.Add(''); $md.Add('Şüpheli = karar değil; elle okunur. Kural ve körlükler betiğin başında. 23.09 elle okuma: 34 şüpheliden 3''ü gerçek (862.400 · 1.100.000 SMMM → elle ret; SGS t1-vergi-cokzor/kp-28 → SGS kolu); çoğu senaryo tutarı ya da ''varsayılırsa'' kurgusu.'); $md.Add('')
$md.Add('## Kapsam dışı — tebliğ / yönetmelik tutarları (KAYNAK BORCU)'); $md.Add('')
$md.Add('23.09.2026 ölçümü: ambarda "2026" geçen kanun dışı belge 54; "2026 … N TL" kalıbında yalnız 7 cümle, hepsi 4 teori notunda (binek oto sınırları, örnek hesaplar). KDV istisna tutarları, SGK prim tabanı/tavanı, asgari ücret, GVK tarife dilimleri gibi TEBLİĞ/KARAR ile yıllık belirlenen tutarlar ambarda bu biçimde YOK → bu tutarları kullanan sorular **taranamıyor** (ölçülmedi, "temiz" değil). Önce 2026 resmî kaynaklarının ambara yutulması gerekir (GVK GT tarife tebliği, SGK 2026 genelgesi, Asgari Ücret Tespit Komisyonu kararı, KDV GUT tutar güncellemeleri).'); $md.Add('')
$md.Add('| kimlik | madde | soruda | güncel had | varsayım mı |'); $md.Add('|---|---|---:|---:|---|')
foreach ($s in $supheli) { $md.Add("| $($s.an) | $($s.madde) | $($s.bulunan) | $($s.guncel_had) | $(if ($s.varsayim) { 'evet (soru varsayım diye kurmuş)' } else { '**hayır — gerçek diye veriyor**' }) |") }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\HAD-TUTAR-TARAMASI.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
[IO.File]::WriteAllText((Join-Path $kok 'veri\fabrika\had-tutar-supheli.json'), (ConvertTo-Json -InputObject $supheli.ToArray() -Depth 3), (New-Object Text.UTF8Encoding $false))
$oz
$supheli | Format-Table an, madde, bulunan, guncel_had -AutoSize | Out-String -Width 200
