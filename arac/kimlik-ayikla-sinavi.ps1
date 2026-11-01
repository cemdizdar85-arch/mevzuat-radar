#requires -Version 5.1
<#
================================================================================
  KİMLİK AYIKLAYICI — ÖZ-SINAV  (01.11.2026)  bedel 0, ağ yok

  NİYE: arac/kimlik-ayikla.ps1 KIMLIK_HESAP_DESENI "193 sayılı", "213 sayılı"
  gibi kanun numaralarını THP hesap kodu sanıyordu. KAPI-HG (motor/kalip-parti-uret.ps1)
  bu yüzden Vergi sorularının hakem/kör paketine 19x/21x THP grubunu ekledi; ölçüldü:
  6.960 SMMM sorusunun 381'inde tek "kod" bir kanun numarasıydı, 191'inde eklenti
  kayda geçti (smmm-w6-yvergi-zor/kp-03 iki kez hakem HAYIR "kaynak THP 190-199").

  NE SINAR:
    A) Get-HesapKodu (TEK kaynak; KAPI-HG, kör paketi, adım istemi, KAPI-KT bunu çağırır)
    B) Elle yazılı kopyalar — dosyaları yüklemeden AST ile ÇALIŞTIRILIR:
         motor/kalip-parti-uret.ps1  SikHesaplari · HesapKodKapisi (KAPI-H, soru düşürür)
         motor/soru-karnesi.ps1      HesapKodKusur
    C) Kopya sapması: dört dosyada KIMLIK_NUMARA_ONCE/SONRA parçası AYNEN var mı
         (arac/hazir-soru-denetle.ps1 KAPI-HG riski fonksiyon değil, yalnız metinle bakılır)

  -Mutasyon: her kilit parça tek tek bozulur; her bozmada sınav KIRMIZI düşmeli.
  🚫 GÖRMEZ: "401 nolu sipariş" / "417 numaralı sipariş" (sipariş no) bilerek DIŞLANMAZ
     ("257 numaralı hesap" ile aynı kalıp); vaka yalnız davranışın değişmediğini sabitler.
================================================================================
#>
param([switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
. ([IO.Path]::Combine($buDizin, 'kimlik-ayikla.ps1'))
$GERCEK_DESEN = $script:KIMLIK_HESAP_DESENI
$ONCE = $script:KIMLIK_NUMARA_ONCE
$SONRA = $script:KIMLIK_NUMARA_SONRA

function FonkMetni([string]$dosya, [string[]]$adlar) {
  $tk = $null; $hk = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($dosya, [ref]$tk, [ref]$hk)
  if (@($hk).Count) { throw "$dosya ayrıştırma hatası: $(@($hk)[0].Message)" }
  $o = @{}
  foreach ($ad in $adlar) {
    $f = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad }, $true)) | Select-Object -First 1
    if (-not $f) { throw "$ad bulunamadı ($dosya)" }
    $o[$ad] = $f.Extent.Text
  }
  return $o
}
$URETICI = [IO.Path]::Combine($depoKok, 'motor', 'kalip-parti-uret.ps1')
$KARNE = [IO.Path]::Combine($depoKok, 'motor', 'soru-karnesi.ps1')
$HAZIR = [IO.Path]::Combine($depoKok, 'arac', 'hazir-soru-denetle.ps1')
$FU = FonkMetni $URETICI @('SikHesaplari', 'HesapKodKapisi', 'Katla2')
$FK = FonkMetni $KARNE @('HesapKodKusur', 'Katla')
$KOPYA_METIN = @{
  'kalip-parti-uret.ps1' = [IO.File]::ReadAllText($URETICI, [Text.Encoding]::UTF8)
  'soru-karnesi.ps1'     = [IO.File]::ReadAllText($KARNE, [Text.Encoding]::UTF8)
  'hazir-soru-denetle.ps1' = [IO.File]::ReadAllText($HAZIR, [Text.Encoding]::UTF8)
}
$KOPYA_BEKLENEN = @{ 'kalip-parti-uret.ps1' = 2; 'soru-karnesi.ps1' = 1; 'hazir-soru-denetle.ps1' = 1 }

function Kume($x) { return ((@($x) | Where-Object { $_ } | Sort-Object -Unique) -join ',') }

# --- A) Get-HesapKodu vakaları: metin → beklenen kod kümesi ------------------
$VAKA_A = @(
  ,@('193 sayılı → kod değil', "193 sayılı Gelir Vergisi Kanunu'na göre hangisi yerleşmiş sayılmaz?", '')
  ,@('320 Satıcılar → kod', '320 Satıcılar hesabına alacak kaydedilir.', '320')
  ,@('(193 sayılı) 320 → yalnız 320', 'Gelir Vergisi Kanunu (193 sayılı) 320 Satıcılar hesabını ilgilendirmez.', '320')
  ,@('Seri No: 329 → kod değil', 'Seri No: 329 Gelir Vergisi Genel Tebliği uyarınca', '')
  ,@('Sıra No: 588 → kod değil', 'VUK Genel Tebliği Sıra No: 588 uyarınca had belirlenir.', '')
  ,@('486 Sıra No.lu → kod değil', '486 Sıra No.lu Vergi Usul Kanunu Genel Tebliği', '')
  ,@('213 s.K. → kod değil', 'VUK (213 s.K.) hükümleri açısından', '')
  ,@('213 s. K. → kod değil', '213 s. K. m.229 uyarınca', '')
  ,@('BÜYÜK HARF SAYILI → kod değil', '213 SAYILI VERGİ USUL KANUNU', '')
  ,@('Sayılı (baş harf büyük) → kod değil', '488 Sayılı Damga Vergisi Kanunu', '')
  ,@('sayili (ASCII) → kod değil', '634 sayili Kat Mulkiyeti Kanunu', '')
  ,@('197 Sayım ve Tesellüm → kod (sayım ≠ sayılı)', '197 Sayım ve Tesellüm Noksanları hesabına', '197')
  ,@('aynı no hem hesap hem kanun → kod kalır', '193 Peşin Ödenen Vergiler ve Fonlar hesabı; 193 sayılı GVK m.120', '193')
  ,@('No: öncesi kod değil, sonraki gerçek kod kalır', 'Sıra No: 545 Tebliği gereği 120 Alıcılar borçlandırılır.', '120')
  ,@('iki gerçek kod', '102 Bankalar ve 100 Kasa', '100,102')
  ,@('BDS 705 → kod değil (eski kural)', 'BDS 705 uyarınca görüş verilir.', '')
  ,@('m.482 → kod değil (eski kural)', 'TTK m.482 uyarınca', '')
  ,@('401 nolu sipariş → değişmedi (GÖRMEZ)', '401 nolu sipariş için', '401')
  ,@('Piyano 320 Satıcılar → "no" kelime içinde, kod kalır', 'Piyano 320 Satıcılar', '320')
)

# --- B) kopyalar: AST'den çalıştırılır (ThpSozluk sahte, ağ yok) -------------
$THP_SAHTE = 'function ThpSozluk { return @{ "193" = "Peşin Ödenen Vergiler ve Fonlar"; "320" = "Satıcılar"; "588" = "Geçmiş Yıllar Zararları" } }'
$VAKA_B = @(
  ,@('SikHesaplari: 193 sayılı + 320 → 320', 'SikHesaplari', "193 sayılı GVK uyarınca 320 Satıcılar hesabına alacak", '320')
  ,@('SikHesaplari: Sıra No: 588 → boş', 'SikHesaplari', "Sıra No: 588 uyarınca beyan", '')
  ,@('HesapKodKapisi: 193 sayılı → sahte kusur yok', 'HesapKodKapisi', "193 sayılı Gelir Vergisi Kanunu uyarınca beyan edilir", '0')
  ,@('HesapKodKapisi: Sıra No: 588 → kusur yok', 'HesapKodKapisi', "VUK Genel Tebliği Sıra No: 588 uyarınca had uygulanır", '0')
  ,@('HesapKodKapisi: 193 yanlış ad → kusur VAR (kapı kör değil)', 'HesapKodKapisi', "193 İndirilecek Katma Değer Vergisi hesabına borç", '1')
  ,@('HesapKodKusur: 193 sayılı → sahte kusur yok', 'HesapKodKusur', "193 sayılı Gelir Vergisi Kanunu uyarınca beyan edilir", '0')
  ,@('HesapKodKusur: 213 s.K. → kusur yok', 'HesapKodKusur', "VUK (213 s.K.) hükümleri uyarınca", '0')
  ,@('HesapKodKusur: 193 yanlış ad → kusur VAR', 'HesapKodKusur', "193 İndirilecek Katma Değer Vergisi hesabına borç", '1')
)

function Kos([string]$desen, $fu, $fk, $kopyaMetin) {
  $hata = New-Object System.Collections.Generic.List[string]
  $script:KIMLIK_HESAP_DESENI = $desen
  foreach ($v in $VAKA_A) { $g = Kume (Get-HesapKodu $v[1]); if ($g -ne $v[2]) { $hata.Add("A $($v[0]): beklenen '$($v[2])' gelen '$g'") } }
  # kopyalar ayrı kapsamda tanımlanır (dosyaların kendisi yüklenmez)
  $blok = [scriptblock]::Create(($fu.Values + $fk.Values + @($THP_SAHTE)) -join "`n")
  . $blok
  foreach ($v in $VAKA_B) {
    $sik = [pscustomobject]@{ A = $v[2]; B = 'b'; C = 'c'; D = 'd'; E = 'e' }
    $c = [pscustomobject]@{ siklar = $sik; dogru = 'A'; sema = $null }
    switch ($v[1]) {
      'SikHesaplari' { $g = Kume (SikHesaplari $c) }
      'HesapKodKapisi' { $g = "$(@(HesapKodKapisi $c | Where-Object { $_ }).Count)" }
      'HesapKodKusur' { $g = "$(@(HesapKodKusur $c | Where-Object { $_ }).Count)" }
    }
    if ($g -ne $v[3]) { $hata.Add("B $($v[0]): beklenen '$($v[3])' gelen '$g'") }
  }
  foreach ($ad in $KOPYA_BEKLENEN.Keys) {
    $m = $kopyaMetin[$ad]
    $nO = ([regex]::Matches($m, [regex]::Escape($ONCE))).Count; $nS = ([regex]::Matches($m, [regex]::Escape($SONRA))).Count
    if ($nO -lt $KOPYA_BEKLENEN[$ad] -or $nS -lt $KOPYA_BEKLENEN[$ad]) { $hata.Add("C kopya sapması: $ad ONCE=$nO SONRA=$nS (beklenen ≥$($KOPYA_BEKLENEN[$ad]))") }
  }
  $script:KIMLIK_HESAP_DESENI = $GERCEK_DESEN
  return , $hata
}

if (-not $Mutasyon) {
  $h = Kos $GERCEK_DESEN $FU $FK $KOPYA_METIN
  $top = $VAKA_A.Count + $VAKA_B.Count + $KOPYA_BEKLENEN.Count
  if ($h.Count) { foreach ($x in $h) { Write-Host "  KIRMIZI $x" -ForegroundColor Red }; Write-Host "KİMLİK AYIKLAYICI ÖZ-SINAVI KIRMIZI ($($top - $h.Count)/$top)" -ForegroundColor Red; exit 1 }
  "KİMLİK AYIKLAYICI ÖZ-SINAVI YEŞİL (${top}/${top}: $($VAKA_A.Count) desen + $($VAKA_B.Count) kopya + $($KOPYA_BEKLENEN.Count) kopya sapması)"; exit 0
}

# --- MUTASYON: her kilit parça tek tek bozulur → her biri KIRMIZI olmalı ------
function Boz([hashtable]$h, [string]$eski, [string]$yeni) { $o = @{}; foreach ($k in $h.Keys) { $o[$k] = "$($h[$k])".Replace($eski, $yeni) }; return $o }
$parcaSay = '[Ss][Aa][Yy][ıiIİ][Ll][ıiIİ]|'; $parcaSK = '|[Ss]\.\s?[Kk]\b'; $parcaSira = '|[Ss][ıiIİ][Rr][Aa]\s+[Nn][Oo]\b'
$MUT = @(
  ,@('SONRA parçası yok (desen)', { $GERCEK_DESEN.Replace($SONRA, '') }, $FU, $FK, $KOPYA_METIN)
  ,@('ONCE parçası yok (desen)', { $GERCEK_DESEN.Replace($ONCE, '') }, $FU, $FK, $KOPYA_METIN)
  ,@('"sayılı" kolu yok (desen)', { $GERCEK_DESEN.Replace($parcaSay, '') }, $FU, $FK, $KOPYA_METIN)
  ,@('"s.K." kolu yok (desen)', { $GERCEK_DESEN.Replace($parcaSK, '') }, $FU, $FK, $KOPYA_METIN)
  ,@('"Sıra No" kolu yok (desen)', { $GERCEK_DESEN.Replace($parcaSira, '') }, $FU, $FK, $KOPYA_METIN)
  ,@('büyük harf sınıfı yok (desen [Ss]→s, [ıiIİ]→ı)', { $GERCEK_DESEN.Replace('[Ss][Aa][Yy][ıiIİ][Ll][ıiIİ]', 'sayıl[ıi]') }, $FU, $FK, $KOPYA_METIN)
  ,@('SONRA "\s*" yok (desen)', { $GERCEK_DESEN.Replace('(?!\s*(?:[Ss][Aa]', '(?!(?:[Ss][Aa]') }, $FU, $FK, $KOPYA_METIN)
  ,@('aşırı dışlama: "[Ss][Aa][Yy]" (sayım da düşer)', { $GERCEK_DESEN.Replace('[Ss][Aa][Yy][ıiIİ][Ll][ıiIİ]', '[Ss][Aa][Yy]') }, $FU, $FK, $KOPYA_METIN)
  ,@('aşırı dışlama: ONCE \b yok ("Piyano 320")', { $GERCEK_DESEN.Replace('(?<!\b[Nn][Oo]', '(?<![Nn][Oo]') }, $FU, $FK, $KOPYA_METIN)
  ,@('SikHesaplari SONRA yok', { $GERCEK_DESEN }, (Boz $FU $SONRA ''), $FK, $KOPYA_METIN)
  ,@('HesapKodKapisi+SikHesaplari ONCE yok', { $GERCEK_DESEN }, (Boz $FU $ONCE ''), $FK, $KOPYA_METIN)
  ,@('HesapKodKusur (karne) SONRA yok', { $GERCEK_DESEN }, $FU, (Boz $FK $SONRA ''), $KOPYA_METIN)
  ,@('hazir-soru-denetle kopyası sapmış', { $GERCEK_DESEN }, $FU, $FK, @{ 'kalip-parti-uret.ps1' = $KOPYA_METIN['kalip-parti-uret.ps1']; 'soru-karnesi.ps1' = $KOPYA_METIN['soru-karnesi.ps1']; 'hazir-soru-denetle.ps1' = $KOPYA_METIN['hazir-soru-denetle.ps1'].Replace($SONRA, '(?!x)') })
)
$kirmizi = 0
foreach ($m in $MUT) {
  $h = Kos (& $m[1]) $m[2] $m[3] $m[4]
  if ($h.Count) { $kirmizi++; "  KIRMIZI (beklenen)  $($m[0])  ← $($h[0])" } else { Write-Host "  YEŞİL (KÖR SINAV!)  $($m[0])" -ForegroundColor Red }
}
if ($kirmizi -ne $MUT.Count) { Write-Host "KİMLİK AYIKLAYICI MUTASYON: $kirmizi/$($MUT.Count) KIRMIZI — sınav kör" -ForegroundColor Red; exit 1 }
"KİMLİK AYIKLAYICI MUTASYON: $kirmizi/$($MUT.Count) bozma → KIRMIZI (sınav görüyor)"; exit 0
