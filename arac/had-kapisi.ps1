# ============================================================================
#  KAPI-HAD — soru, dayandığı maddenin güncel haddinden FARKLI bir tutarı GERÇEK diye veriyor mu?   23.09.2026 · bedel 0
#  (dot-source edilir; arac/smmm-yayin-sarti.ps1 çağırır)
#
#  Cem 23.09 ("1.2.3 üçünü de yap"): had taraması (arac/had-tutar-tarama.ps1) kasada 3 kusur buldu — izaha davet haddi 862.400
#  (gerçek 870.000), VUK m.177/3 karma sınır 1.100.000 (gerçek 2.500.000), SGS'de 5.000.000/2.400.000 (gerçek 2.500.000/1.200.000).
#  Üretim tutarın güncelliğini denetlemiyordu. Tarama 34 şüpheli verdi, 31'i sağlamdı (senaryo tutarı / "varsayılırsa") —
#  o kural KAPI olamazdı. Bu kapı DAR: tutar, bir had ifadesiyle DOĞRUDAN tanımlanmalı ("öngörülen tutar N", "belirlenen N
#  haddi", "sınır N", "haddi N") · önünde senaryo sözcüğü (belge/fatura tutarı, satış, alış, hasılat, kazanç, gelir, bedel,
#  kira, ödeme, matrah) olmamalı · cümlede "varsay" geçmemeli · güncel hadde eşit olmamalı ama 0,25–4 kat yakın olmalı.
#  ÖLÇÜLDÜ (23.09, elle okunmuş 34 vaka): gerçek 3'ün 3'ü yakalanır (SGS vakası 2 kat hata — geniş pencere), sağlam 31'de 0 alarm.
#  Güncel had: veri/sinav/had-guncel.json (had-tutar-tarama.ps1 yazar: madde anahtarı → tutarlar; ambardaki kanun şerhinden).
#  🚫 GÖRMEZ: yazıyla tutar; şerhi olmayan had (tebliğ/yönetmelik: KDV, SGK, asgari ücret); had ifadesi kullanmadan eski tutarı
#     öncül yapan soru; dosya yoksa kapı AÇIK geçer (körlük: dosya yoksa yayın şartı raporunda görünür değil — tarama günlük koşmalı).
#  Öz-sınav: arac/had-kapisi-sinavi.ps1
# ============================================================================
# kökler: ≥4 harfli kelimenin ilk 5 harfi (Türkçe katlanmış); tutar/tarih/yıl gibi her bağlamda geçen sözcükler sayılmaz
$script:HAD_BOS = @{}; foreach ($w in 'yili yilin yilda takvi icin olan olara olmak kadar ayrim hakki haddi hadd sinir sinirl belir ongor tutar lira lirad lirası liras bulun gore hesap uzere'.Split(' ')) { $script:HAD_BOS[$w] = 1 }
function HadKokler([string]$t) { $k = "$t".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant() -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c'; return @([regex]::Matches($k, '[a-z]{4,}') | ForEach-Object { $_.Value.Substring(0, [Math]::Min(5, $_.Value.Length)) } | Where-Object { -not $script:HAD_BOS.ContainsKey($_) } | Select-Object -Unique) }
function HadHaritaOku([string]$depoKokYolu) {
  $h = @{}; $y = Join-Path (Join-Path (Join-Path $depoKokYolu 'veri') 'sinav') 'had-guncel.json'
  if (Test-Path $y) { foreach ($p in (Get-Content $y -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties) { $h[$p.Name] = @($p.Value | ForEach-Object { if ($_ -is [double] -or $_ -is [int] -or $_ -is [long] -or $_ -is [decimal]) { [pscustomobject]@{ tutar = [double]$_; baglam = @() } } else { [pscustomobject]@{ tutar = [double]$_.tutar; baglam = @($_.baglam) } } }) } }
  return $h
}
function HadSayi([string]$s) { $t = ($s -replace '\.', '') -replace ',', '.'; $d = 0.0; if ([double]::TryParse($t, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }; return -1 }
# döner: '' (sorun yok) ya da "<sorudaki> ≠ güncel <had> (<madde>)"
function HadIddiasi($v, $harita, [string[]]$anahtarlar) {
  if (-not $harita -or -not $harita.Count) { return '' }
  $hs = New-Object System.Collections.Generic.List[double]; $hk = New-Object System.Collections.Generic.List[object]; $mad = @()
  foreach ($a in $anahtarlar) { if ($a -and $harita.ContainsKey($a)) { foreach ($x in $harita[$a]) { if (-not $hs.Contains($x.tutar)) { $hs.Add($x.tutar) }; $hk.Add([pscustomobject]@{ tutar = $x.tutar; baglam = @($x.baglam); no = (($a -split '\|')[1] -replace '^\D+', '') }) }; $mad += $a } }
  if (-not $hs.Count) { return '' }
  $metin = "$($v.soru) " + ((@('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$($v.siklar.$_)" }) -join ' | ') + ' ' + ($v.aciklama | ConvertTo-Json -Compress -Depth 4)
  foreach ($m in [regex]::Matches($metin, '(\d{1,3}(?:\.\d{3})+(?:,\d+)?)\s*(?:TL|₺|Türk lirası|lira)')) {
    $a = HadSayi $m.Groups[1].Value; if ($a -lt 1000 -or $hs.Contains($a)) { continue }
    $bas = [Math]::Max(0, $m.Index - 45); $once = $metin.Substring($bas, $m.Index - $bas)
    if ($once -notmatch '(?i)öngörülen\s+tutar\S*\s*$|belirlenen\s*$|belirlenen\s+\S*\s*$|sınır(ı)?\s*$|hadd(i|inin)?\s*$|\bhad\s*$|için\s+belirlenen') { continue }
    if ($once -match '(?i)(belge|fatura)\s+tutar|satış|alış|hasılat|kazanc|kazanç|gelir|bedel|kira\s|ödeme|matrah') { continue }
    $cb = [Math]::Max(0, $metin.LastIndexOfAny([char[]]'.?!', [Math]::Max(0, $m.Index - 1)) + 1)
    if ($metin.Substring($cb, [Math]::Min($metin.Length - $cb, ($m.Index - $cb) + 120)) -match '(?i)varsay') { continue }
    # 23.09: aynı BAĞLAMDAKİ had ile karşılaştır (m.86 beyan haddi 130.000 ≠ m.21 mesken istisnası 58.000 yanlış alarmı)
    # ibare = önceki virgül/nokta/noktalı virgülden tutara kadar (en çok 110 kr). Eşleşme: ibarede hadle ortak bağlam kökü VEYA hadin maddesi açıkça anılıyor (m.370)
    # ayırıcı: ardından BOŞLUK gelen , ; . (m.370 / 1.100.000 içindeki nokta ayırıcı değildir — 23.09 öz-sınav öncesi ölçüldü)
    $ayir = @([regex]::Matches($metin.Substring(0, $m.Index), '[,;.]\s') | ForEach-Object { $_.Index + 1 }); $ib = [Math]::Max([Math]::Max(0, $m.Index - 110), $(if ($ayir.Count) { $ayir[-1] } else { 0 }))
    $ibare = $metin.Substring($ib, $m.Index - $ib); $qk = HadKokler $ibare
    $yakin = @($hk | Where-Object { $a -ge 0.25 * $_.tutar -and $a -le 4 * $_.tutar -and (($ibare -match ("(?i)m\.\s*" + [regex]::Escape("$($_.no)") + "(?!\d)")) -or ($(foreach ($b in @($_.baglam)) { if ($qk -contains $b) { $true; break } }))) } | ForEach-Object { $_.tutar } | Select-Object -Unique)
    if (-not $yakin.Count) { continue }
    return ("{0} ≠ güncel {1} ({2})" -f $m.Groups[1].Value, (($yakin | ForEach-Object { $_.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }) -join ' / '), ($mad -join ','))
  }
  return ''
}
