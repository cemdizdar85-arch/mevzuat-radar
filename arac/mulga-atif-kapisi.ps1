# KAPI-MA MÜLGA MADDEYE METİN ATFI (29.09.2026, Cem "1.2.3"; SGS oturumu VUK m.270'i bildirdi)
#
# NEDEN: 5 SMMM sorusu bütünüyle mülga VUK m.270'i (14.10.2021, 7338/29) METİNDE dayanak gösteriyordu ("VUK m.270
#   mantığında…"); biri anahtarı yanlış çıktı (w13-1-fmuh-zor/kp-13: kural m.262'ye taşınmış, noter/harç zorunlu olmuş).
# İŞ BÖLÜMÜ (çakışma olmasın): liste ve kaynak paketi SGS oturumunun KAPI-MM'sinde (79396fd0): arac/ambar-mulga-madde.js →
#   veri/sinav/ambar-mulga-maddeler.json; üretici mülga maddeyi pakete almaz; hazır soru denetimi kaynak_adlar'a bakar.
#   KAPI-MM'nin yazılı körlüğü "soru gövdesindeki mülga atıf"tır → KAPI-MA yalnız onu, AYNI listeyle ölçer.
# KURAL: sorunun ÖĞRENCİNİN GÖRDÜĞÜ metninde (kök, şık, açıklama, teşhis, sade, adımlar, dayanak…) listedeki bir maddeye
#   atıf varsa kusur. Tanınan biçimler: "VUK m.270" · "VUK (213 s.K.) m.270" · "VUK 270. madde" · "VUK'nun 270 inci
#   maddesi" · "213 sayılı … 270 nci madde" · "Vergi Usul Kanunu 270. madde" (tam ad yalnız $MA_TAM_AD'daki kanunlarda).
# 🚫 GÖRMEZ: listede olmayan mülga madde (liste körlükleri KAPI-MM'de yazılı) · başka atıf biçimi ("anılan madde") ·
#   iç alanlar (kaynak özeti, kaynak_adlar, atif_genisletme, hakem, kör, ikiz) · geçici/ek madde numaraları.
#   ÖLÇÜLDÜ 29.09: atif_genisletme (hakemin kaynak genişletmesi, öğrenci görmez) iç alan sayılmayınca m.270'i 2 yamalı soruda yakalıyordu.
# Öz-sınav: arac/mulga-atif-kapisi-sinavi.ps1 (dogrula.yml). Kullanan: arac/smmm-yayin-sarti.ps1.

$script:MA_IC_ALAN = @('kaynak_metin_ozet','dayanak_alinti','atif_genisletme','kaynak_adlar','capa_metin','hakem','hakem2','ikiz','ikiz_sema','kor_cozum','kor_cozum_kaynakli','simulasyon_sonnet','gm_kapi','aritmetik','hesap_kod','hesap_genisletme','yazar','donem','konu','pencere_kavram')
$script:MA_TAM_AD = @{ 'VUK' = 'Vergi Usul Kanunu'; 'GVK' = 'Gelir Vergisi Kanunu'; 'KDVK' = 'Katma De[ğg]er Vergisi Kanunu'; 'Damga V.K.' = 'Damga Vergisi Kanunu'; 'Emlak V.K.' = 'Emlak Vergisi Kanunu'; 'TCK' = 'T[üu]rk Ceza Kanunu' }
$script:MA_LISTE = $null
$script:MA_KOR = $false
$script:MA_KOK = $(if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { '' })
$script:MA_EK = "(?:'?\s*(?:nci|ncı|inci|ıncı|üncü|uncu|ncü|ncu))?"

function MaListeOku([string]$yol = '') {
  if (-not $yol) { $yol = [IO.Path]::Combine($script:MA_KOK, 'veri', 'sinav', 'ambar-mulga-maddeler.json') }
  if (-not (Test-Path $yol)) { Write-Host "  KAPI-MA KÖR: mülga madde listesi yok ($yol) — mülga atıf DENETLENMİYOR (arac/ambar-mulga-madde.js)" -ForegroundColor Yellow; $script:MA_KOR = $true; return , @() }
  $sonuc = New-Object System.Collections.Generic.List[object]
  foreach ($m in @((Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler | ForEach-Object { $_ })) {
    $km = [regex]::Match("$($m.kaynak_ad)", '^(?<kisa>[^\(]+?)\s*\((?<no>\d{3,5})\s*s\.K\.\)\s*m\.\s*(?<md>\d{1,4})(?![\d/])')
    if (-not $km.Success -or "$($m.kaynak_ad)" -match '(?i)ge[çc]ici|\bek\s+m\.') { continue }
    $kisa = $km.Groups['kisa'].Value.Trim(); $k = [regex]::Escape($kisa); $no = $km.Groups['no'].Value; $md = $km.Groups['md'].Value
    $desen = @(
      "\b$k\s*(?:\(\s*$no\s*s\.\s*K\.\s*\)\s*)?(?:m\.|md\.|madde)\s*$md(?![\d/])",
      "\b$k(?:'?n[iıuü]n)?\s+$md\.?\s*$($script:MA_EK)\s*madde",
      "\b$no\s*say[ıi]l[ıi][^.;]{0,80}?\b$md\.?\s*$($script:MA_EK)\s*madde",
      "\b$no\s*say[ıi]l[ıi][^.;]{0,80}?\bm(?:adde)?\.\s*$md(?![\d/])"
    )
    if ($script:MA_TAM_AD.ContainsKey($kisa)) { $t = $script:MA_TAM_AD[$kisa]; $desen += "$t(?:'?n[iıuü]n)?[^.;]{0,12}?\b$md\.?\s*$($script:MA_EK)\s*madde"; $desen += "$t[^.;]{0,12}?\bm(?:adde)?\.\s*$md(?![\d/])" }
    $sonuc.Add([pscustomobject]@{ kok = "$kisa ($no s.K.) m.$md"; iptal = "$($m.iptal)"; desen = [regex]::new('(?:' + ($desen -join '|') + ')', 'IgnoreCase, Compiled') })   # derlenmiş: 24+ desen .NET önbelleğini (15) aşar
  }
  return , $sonuc.ToArray()
}

function MaMetinler($deger) {
  $liste = New-Object System.Collections.Generic.List[string]
  $yigin = New-Object System.Collections.Stack; $yigin.Push($deger)
  while ($yigin.Count) {
    $x = $yigin.Pop()
    if ($null -eq $x) { continue }
    if ($x -is [string]) { if ($x.Trim()) { $liste.Add($x) }; continue }
    if ($x -is [System.Collections.IDictionary]) { foreach ($v in $x.Values) { $yigin.Push($v) }; continue }
    if ($x -is [System.Collections.IEnumerable]) { foreach ($v in $x) { $yigin.Push($v) }; continue }
    if ($x -is [pscustomobject]) { foreach ($p in $x.PSObject.Properties) { $yigin.Push($p.Value) }; continue }
  }
  return , $liste
}

function MulgaAtifKapisi($a) {
  $out = @(); if (-not $a) { return $out }
  if ($null -eq $script:MA_LISTE) { $script:MA_LISTE = MaListeOku }
  $gorunen = [ordered]@{}
  if ($a -is [pscustomobject]) { foreach ($p in $a.PSObject.Properties) { if ($script:MA_IC_ALAN -notcontains $p.Name) { $gorunen[$p.Name] = $p.Value } } } else { $gorunen['x'] = $a }
  $tum = (MaMetinler $gorunen) -join ' '
  foreach ($m in $script:MA_LISTE) { if ($m.desen.IsMatch($tum)) { $out += "mülga maddeye atıf: $($m.kok) ($($m.iptal))" } }
  return @($out | Select-Object -Unique)
}
