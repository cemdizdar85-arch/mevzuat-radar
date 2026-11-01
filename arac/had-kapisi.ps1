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
#
#  ⭐ 01.11.2026 SMMM (BİTİRME) YOLU — D7 YIL KURALI (BITIRME-SORU-STANDARDI.md D7, Cem 30.10: 2026 sınavı 2025 tutarını sorar).
#   Ajan 38 ölçtü: kapı doğru soruları düşürüyordu — üç kök: (1) "güncel had" kanun şerhinden = 2026 tutarı (D7 2025 ister);
#   (2) madde anahtarı kaynak_adlar'ın TAMAMI (hakem paketindeki ilgisiz maddeler de girer); (3) bağlam kökü yanlış maddeye
#   bağlanıyordu (m.153/A sorusundaki "sahte belge" → m.370). Yanlış düşen: smmm-w4-yvergi-kolay/kp-03 (GT 577 EK m.153/A alt
#   sınır 990.000), smmm-4k-a-yvergi-kolay-r10/kp-06 (GT 577 EK m.370 700.000).
#   SMMM yolunda (anahtar 'smmm-' ile başlar, HadYayinNeden): had = veri/sinav/had-d7.json (D7 yılının resmî listesi, ambardan;
#   üreten arac/had-d7-kur.ps1) · madde anahtarı YALNIZ dayanak alanı + kökte adı geçen madde (HadSmmmAnahtarlar) · ibare bir
#   maddeyi adıyla anıyorsa yalnız o maddenin haddiyle kıyaslanır (-MaddeAdiBaglar).
#   KGK ve öteki çağıranlar (anahtar 'smmm-' ile başlamaz) ESKİ yoldan geçer: had-guncel.json + kaynak_adlar — davranış birebir aynı.
#   🚫 GÖRMEZ (SMMM yolu): D7 listesinde olmayan madde (bugün yalnız VUK GT 577 EK + GVK GT 329 m.3; Harçlar, Damga, VİVK,
#     Çevre K. vb. had'i SMMM'de denetlenmez — eskiden 2026 şerhiyle yanlış ölçülüyordu) · dayanağı ve kökü madde anmayan soru ·
#     dayanakta adı geçmeyen maddenin tutarı.
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
# 01.11 SMMM D7 haritası: had-guncel.json ile aynı biçim (maddeler: anahtar → [{tutar, baglam}]); dosya yoksa boş (kapı AÇIK)
function HadD7HaritaOku([string]$depoKokYolu) {
  $h = @{}; if (-not $depoKokYolu) { Write-Warning "KAPI-HAD SMMM: depo kökü boş — D7 had denetimi KÖR"; return $h }
  $y = Join-Path (Join-Path (Join-Path $depoKokYolu 'veri') 'sinav') 'had-d7.json'
  if (Test-Path $y) { foreach ($p in (Get-Content $y -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties) { $h[$p.Name] = @($p.Value | ForEach-Object { [pscustomobject]@{ tutar = [double]$_.tutar; baglam = @($_.baglam) } }) } }
  else { Write-Warning "KAPI-HAD SMMM: veri/sinav/had-d7.json yok — D7 had denetimi KÖR (arac/had-d7-kur.ps1)" }
  return $h
}
# 01.11 metinde adı geçen kanun maddeleri → madde anahtarı ('213|370', '213|ek1'; MdAnahtar biçimi). Madde en yakın ÖNCEKİ
#   kanun anına bağlanır (≤300 kr); araya tebliğ/standart anı girerse (GT 577, Sıra No, Seri No, GUT, TMS…) o madde kanunun
#   değildir, alınmaz. İSTİSNA: "VUK GT 577 EK m.153/A" (ambarın had listesi adı) kanunun maddesidir. Kısaltma listesi DAR:
#   yalnız madde atfının yanlış kanuna yazılmasını önlemek için (D7 listesi bugün 213 + 193).
$script:HAD_KANUN = @(
  @('213', '\bVUK\b|Vergi\s+Usul\s+Kanun'), @('193', '\bGVK\b|Gelir\s+Vergisi\s+Kanun'), @('5520', '\bKVK\b|Kurumlar\s+Vergisi\s+Kanun'),
  @('3065', '\bKDVK\b|Katma\s+De[gğ]er\s+Vergisi\s+Kanun'), @('4760', '\b[ÖO]TVK?\b|[ÖO]zel\s+T[üu]ketim\s+Vergisi\s+Kanun'), @('6183', '\bAATUHK\b|Amme\s+Alacaklar'),
  @('488', 'Damga\s+Vergisi\s+Kanun|\bDVK\b'), @('492', 'Har[çc]lar\s+Kanun'), @('7338', 'Veraset\s+ve\s+[İI]ntikal|\bV[İI]VK\b'), @('6102', '\bTTK\b|T[üu]rk\s+Ticaret\s+Kanun'),
  @('6098', '\bTBK\b|T[üu]rk\s+Bor[çc]lar\s+Kanun'), @('5510', '\bSSGSSK\b|Sosyal\s+Sigortalar\s+ve'), @('4857', '\b[İI][şs]\s+Kanunu'), @('2004', '\b[İI][İI]K\b|[İI]cra\s+ve\s+[İI]flas'))
$script:HAD_KANUN_NO = '(?<![\d.,/])(\d{3,4})\s*(?:s\.|say[ıi]l[ıi])'
$script:HAD_TEBLIG = '(?i)Genel\s+Tebli|\bGT\s*(?>\d+)(?!\s*EK\b)|S[ıi]ra\s+No|Seri\s+No|\bGUT\b|Tebli[gğ]|Y[öo]netmeli|\bTMS\b|\bTFRS\b|\bBDS\b|\bTHP\b|\bSGS\b|Kurul\s+Karar'
$script:HAD_MADDE = '(?i)\bmd?\.\s*(\d{1,4})(?!\d)|(?<![\d.,/])(\d{1,4})(?:\s*/\s*[A-Za-zÇĞİÖŞÜ])?\s*(?:[''\u2019]?\s*(?:inci|ıncı|nci|ncı|uncu|üncü|ncü|ncu)|\.)?\s+madde|\bmadde\s+(\d{1,4})(?!\d)'
function HadMaddeAnahtarlari([string]$metin) {
  $t = "$metin"; if (-not $t.Trim()) { return @() }
  $an = New-Object System.Collections.Generic.List[object]   # {bas, son, no}  no = '' → tebliğ/standart anı
  foreach ($k in $script:HAD_KANUN) { foreach ($m in [regex]::Matches($t, $k[1], 'IgnoreCase')) { $an.Add([pscustomobject]@{ bas = $m.Index; son = $m.Index + $m.Length; no = $k[0] }) } }
  foreach ($m in [regex]::Matches($t, $script:HAD_KANUN_NO)) { $an.Add([pscustomobject]@{ bas = $m.Index; son = $m.Index + $m.Length; no = $m.Groups[1].Value }) }
  foreach ($m in [regex]::Matches($t, $script:HAD_TEBLIG)) { $an.Add([pscustomobject]@{ bas = $m.Index; son = $m.Index + $m.Length; no = '' }) }
  $c = New-Object System.Collections.Generic.List[string]
  foreach ($m in [regex]::Matches($t, $script:HAD_MADDE)) {
    $no = $(if ($m.Groups[1].Success) { $m.Groups[1].Value } elseif ($m.Groups[2].Success) { $m.Groups[2].Value } else { $m.Groups[3].Value })
    $once = @($an | Where-Object { $_.son -le $m.Index -and $_.son -ge ($m.Index - 300) } | Sort-Object son | Select-Object -Last 1)
    if (-not $once.Count -or -not $once[0].no) { continue }
    # 'GT 577 EK m.153/A' (ambarın had listesi adı) ek madde değildir: önünde rakam olan EK seri sayılmaz
    $bas = [Math]::Max(0, $m.Index - 14); $on = $t.Substring($bas, $m.Index - $bas)
    $seri = $(if ($on -match '(?i)ge[çc](ici|\.)\s*$') { 'gec' } elseif ($on -match '(?i)(?<!\d\s*)\bek\s*$') { 'ek' } else { '' })
    $a = "$($once[0].no)|$seri$([int]$no)"; if (-not $c.Contains($a)) { $c.Add($a) }
  }
  return $c.ToArray()
}
# SMMM: madde anahtarı YALNIZ dayanak alanı + kök (kaynak_adlar hakem paketidir, ilgisiz madde taşır — Ajan 38 ölçümü)
function HadSmmmAnahtarlar($v) {
  $c = New-Object System.Collections.Generic.List[string]
  foreach ($a in @(HadMaddeAnahtarlari "$($v.dayanak)") + @(HadMaddeAnahtarlari "$($v.soru)")) { if ($a -and -not $c.Contains($a)) { $c.Add($a) } }
  return $c.ToArray()
}
# Yayın şartı girişi (arac/smmm-yayin-sarti.ps1). 'smmm-' → D7 yolu; öteki (KGK) → 23.09 yolu BİREBİR (had-guncel + kaynak_adlar).
$script:HAD_HARITA = $null; $script:HAD_D7 = $null
function HadYayinNeden([string]$anahtar, $v, [string]$depoKokYolu) {
  if ("$anahtar".StartsWith('smmm-')) {
    if ($null -eq $script:HAD_D7) { $script:HAD_D7 = HadD7HaritaOku $depoKokYolu }
    return (HadIddiasi $v $script:HAD_D7 @(HadSmmmAnahtarlar $v) -MaddeAdiBaglar)
  }
  if ($null -eq $script:HAD_HARITA) { $script:HAD_HARITA = HadHaritaOku $depoKokYolu }
  return (HadIddiasi $v $script:HAD_HARITA @(@($v.kaynak_adlar) | ForEach-Object { MdAnahtar "$_" }))
}
# döner: '' (sorun yok) ya da "<sorudaki> ≠ güncel <had> (<madde>)"
#   -MaddeAdiBaglar (01.11, yalnız SMMM yolu): ibare bir maddeyi adıyla anıyorsa ("m.153/A", "370 inci madde") tutar YALNIZ o
#   maddenin hadleriyle kıyaslanır; bağlam kökü başka maddeye bağlamaz (m.153/A'daki "sahte belge" → m.370 yanlış bağı).
function HadIddiasi($v, $harita, [string[]]$anahtarlar, [switch]$MaddeAdiBaglar) {
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
    if ($MaddeAdiBaglar) {
      $anilan = @([regex]::Matches($ibare, $script:HAD_MADDE) | ForEach-Object { "$([int]$(if ($_.Groups[1].Success) { $_.Groups[1].Value } elseif ($_.Groups[2].Success) { $_.Groups[2].Value } else { $_.Groups[3].Value }))" })
      if ($anilan.Count) {
        $yakin = @($hk | Where-Object { $anilan -contains "$($_.no)" -and $a -ge 0.25 * $_.tutar -and $a -le 4 * $_.tutar } | ForEach-Object { $_.tutar } | Select-Object -Unique)
        if (-not $yakin.Count) { continue }
        return ("{0} ≠ güncel {1} ({2})" -f $m.Groups[1].Value, (($yakin | ForEach-Object { $_.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }) -join ' / '), ($mad -join ','))
      }
    }
    $yakin = @($hk | Where-Object { $a -ge 0.25 * $_.tutar -and $a -le 4 * $_.tutar -and (($ibare -match ("(?i)m\.\s*" + [regex]::Escape("$($_.no)") + "(?!\d)")) -or ($(foreach ($b in @($_.baglam)) { if ($qk -contains $b) { $true; break } }))) } | ForEach-Object { $_.tutar } | Select-Object -Unique)
    if (-not $yakin.Count) { continue }
    return ("{0} ≠ güncel {1} ({2})" -f $m.Groups[1].Value, (($yakin | ForEach-Object { $_.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }) -join ' / '), ($mad -join ','))
  }
  return ''
}
