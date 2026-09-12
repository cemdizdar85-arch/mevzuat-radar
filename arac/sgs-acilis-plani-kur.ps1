# SGS ACILIS PLANI KURUCU (10.09.2026) - 0 USD, model cagrisi YOK.
#
# Girdi : veri/fabrika/sgs-acilis-is-plani.csv  (konu · arsiv_ders · bizim_ders · yazilacak)
# Cikti : veri/sinav/konu/sgs-a6-<ders>-<seviye>-r<tur>.json  (FABRIKA dersleri)
#         veri/fabrika/elle-yazim-<ders>.csv                    (ELLE yazilan dersler: YD, Turkce, Matematik, Inkilap)
#         veri/sinav/plan-sgs-a6.json
#
# KURAL: bir konunun N sorusu 3 seviyeye dagitilir (kolay, zor, cokzor); N>3 ise tur r2, r3... acilir.
#        Her etiket AYRI cache dosyasi -> KAPI-B etiketler arasi benzerligi ayrica denetler.
#        Tur tavani 6 (18 soru/konu); ustu acilistan sonraki gunluk basima kalir.
# DersRegex: bizim_ders biliniyorsa o; bilinmiyorsa arsiv dersi (uretici DersRegex'i bizim_ders+arsiv_ders'e bakar, satir 866).
param([string]$Ad = 'sgs-a6', [int]$TurTavan = 6)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent
function Katla2([string]$s) { ("$s".ToLowerInvariant() -creplace 'I', 'i').Replace([char]0x0131, 'i').Replace([char]0x011F, 'g').Replace([char]0x00FC, 'u').Replace([char]0x015F, 's').Replace([char]0x00F6, 'o').Replace([char]0x00E7, 'c') }

# 10.09 TUZAK (ikinci kez): bu dizi once $ELLE, asagidaki liste $elle adiyla yazildi. PowerShell harf AYIRMAZ,
# hashtable diziyi ezdi, '-contains' hep false dondu ve 118 elle konusu "ders eslesmedi" diye dustu. Kisa/ikiz ad YASAK.
$ELLE_DERSLER = @('Yabanci Dil', 'Turkce', 'Matematik', 'Ataturk Ilke ve Inkilap Tarihi', 'Genel Kultur-Genel Yetenek', 'Matematik-Istatistik')
$SIN = @{
  'Finansal Muhasebe'            = @{ k = 'fmuh';    r = 'Finansal Muhasebe';                                  t = 746 }
  'Denetim'                      = @{ k = 'denetim'; r = 'Denetim';                                            t = 746 }
  'Maliyet Muhasebesi'           = @{ k = 'maliyet'; r = 'Maliyet Muhasebesi';                                 t = 746 }
  'Mali Tablolar Analizi'        = @{ k = 'mta';     r = 'Mali Tablolar Analizi';                              t = 411 }
  'Vergi Hukuku'                 = @{ k = 'vergi';   r = 'Vergi Hukuku';                                       t = 300 }
  'Ticaret Hukuku'               = @{ k = 'ticaret'; r = 'Ticaret Hukuku|Ticaret ve Borclar';                  t = 300 }
  'Borclar Hukuku'               = @{ k = 'borclar'; r = 'Borclar Hukuku|Ticaret ve Borclar';                  t = 300 }
  'Is ve Sosyal Guvenlik Hukuku' = @{ k = 'issgk';   r = 'Is ve Sosyal Guvenlik Hukuku|Is ve Sosyal Guvenlik'; t = 300 }
  'Meslek Hukuku'                = @{ k = 'meslek';  r = 'Meslek Hukuku';                                      t = 300 }
  'Ekonomi'                      = @{ k = 'ekonomi'; r = 'Ekonomi';                                            t = 300 }
  'Maliye'                       = @{ k = 'maliye';  r = '^Maliye$';                                           t = 300 }
  # bizim dersi bilinmeyen arsiv konulari: arsiv dersiyle kosar
  'Muhasebe'                     = @{ k = 'muh';     r = 'Muhasebe';                                           t = 746 }
  'Hukuk'                        = @{ k = 'hukuk';   r = 'Hukuk';                                              t = 300 }
}
$csv = Join-Path $kok 'veri\fabrika\sgs-acilis-is-plani.csv'
$c = @(Import-Csv $csv -Encoding UTF8 | Where-Object { [int]$_.yazilacak -gt 0 })

$konuDir = Join-Path $kok 'veri\sinav\konu'; New-Item -ItemType Directory -Force $konuDir | Out-Null
$plan = New-Object System.Collections.Generic.List[object]
$elleListe = @{}
$fabrika = @{}
foreach ($x in $c) {
  $ders = if ($x.bizim_ders) { $x.bizim_ders } else { $x.arsiv_ders }
  if ($ELLE_DERSLER -contains $ders -or $ELLE_DERSLER -contains $x.arsiv_ders) {
    $eAd = if ($x.bizim_ders) { $x.bizim_ders } else { $x.arsiv_ders }
    if (-not $elleListe.ContainsKey($eAd)) { $elleListe[$eAd] = New-Object System.Collections.Generic.List[object] }
    $elleListe[$eAd].Add([pscustomobject]@{ ders = $eAd; konu = $x.konu; cikan = $x.cikan; hedef = $x.hedef; yazdik = $x.yazdik; yazilacak = $x.yazilacak; onem = $x.onem })
    continue
  }
  if (-not $SIN.ContainsKey($ders)) { $ders = $x.arsiv_ders }
  if (-not $SIN.ContainsKey($ders)) { Write-Host ("ders eslesmedi, atlandi: {0} [{1}]" -f $x.konu, $ders) -ForegroundColor DarkYellow; continue }
  if (-not $fabrika.ContainsKey($ders)) { $fabrika[$ders] = New-Object System.Collections.Generic.List[object] }
  $fabrika[$ders].Add([pscustomobject]@{ konu = $x.konu; n = [int]$x.yazilacak; cikan = [int]$x.cikan })
}

# ELLE yazim listeleri
foreach ($d in $elleListe.Keys) {
  $yol = Join-Path $kok ("veri\fabrika\elle-yazim-{0}.csv" -f (Katla2 $d).Replace(' ', '-'))
  $elleListe[$d] | Sort-Object { -[int]$_.cikan } | Export-Csv $yol -NoTypeInformation -Encoding UTF8 -Delimiter ';'
  Write-Host ("ELLE   {0,-32} konu {1,4} | yazilacak {2,5} -> {3}" -f $d, $elleListe[$d].Count, (($elleListe[$d] | Measure-Object yazilacak -Sum).Sum), (Split-Path $yol -Leaf))
}
# FABRIKA konu dosyalari: seviye x tur
$sevler = @('kolay', 'zor', 'cokzor')
foreach ($d in ($fabrika.Keys | Sort-Object)) {
  $b = $SIN[$d]; $lst = $fabrika[$d]
  $enCok = ($lst | Measure-Object n -Maximum).Maximum
  $turSay = [math]::Min($TurTavan, [math]::Ceiling($enCok / 3.0))
  $toplam = 0
  for ($r = 1; $r -le $turSay; $r++) {
    for ($s = 0; $s -lt 3; $s++) {
      $esik = $s + 3 * ($r - 1)                       # bu slotu dolduran konular: n > esik
      $konular = @($lst | Where-Object { $_.n -gt $esik } | Sort-Object { -$_.cikan } | ForEach-Object { $_.konu })
      if ($konular.Count -eq 0) { continue }
      $et = "{0}-{1}-{2}-r{3}" -f $Ad, $b.k, $sevler[$s], $r
      $kd = Join-Path $konuDir ($et + '.json')
      [IO.File]::WriteAllText($kd, (ConvertTo-Json -InputObject @($konular) -Depth 2), [Text.UTF8Encoding]::new($false))
      $plan.Add([pscustomobject]@{ ders = $b.r; dersAd = $d; etiket = $et; adet = $konular.Count; tavan = $b.t; zorluk = $sevler[$s]; tur = $r; sinav = 'SGS'; konuDosya = ("veri/sinav/konu/" + $et + '.json'); toplu = $false })
      $toplam += $konular.Count
    }
  }
  Write-Host ("FABRIKA {0,-31} konu {1,4} | yazilacak {2,5} | etiket {3,2} | plana giren soru {4,5}" -f $d, $lst.Count, (($lst | Measure-Object n -Sum).Sum), ($plan | Where-Object { $_.dersAd -eq $d }).Count, $toplam)
}
$planYol = Join-Path $kok "veri\sinav\plan-$Ad.json"
[IO.File]::WriteAllText($planYol, (ConvertTo-Json -InputObject @($plan.ToArray()) -Depth 4), [Text.UTF8Encoding]::new($false))
Write-Host ''
$elleToplam = 0; foreach ($d in $elleListe.Keys) { $elleToplam += (($elleListe[$d] | Measure-Object yazilacak -Sum).Sum) }
Write-Host ("PLAN: {0} fabrika etiketi, {1} soru | elle: {2} soru | {3}" -f $plan.Count, (($plan | Measure-Object adet -Sum).Sum), $elleToplam, $planYol) -ForegroundColor Green
