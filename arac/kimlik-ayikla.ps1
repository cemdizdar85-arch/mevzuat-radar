#requires -Version 5.1
<#
================================================================================
  KİMLİK AYIKLAYICI — TEK KAYNAK  (11.09.2026, Cem "1 ve 2 yap")

  NİYE TEK DOSYA: 11.09'da aynı hesap-kodu regex'i ÜÇ ayrı dosyada ayrı ayrı
  yazılmıştı. "BDS 705 uyarınca" ifadesindeki 705'i hesap kodu sanan hata
  bulununca üçünü de tek tek düzeltmek gerekti; biri unutulsaydı kapı yanlış
  çalışacak, mühür konduğunda DOĞRU Denetim sorularını reddedecekti.
  Artık kimlik ayıklama TEK yerde tanımlı; düzeltme bir kez yapılır.

  KİMLİK NEDİR: soruda geçen ve bir kapalı listeye karşı doğrulanabilen alan.
  Bugün iki tanesi var:
    - THP hesap kodu      -> KAPI-H (kod-ad çifti) · KAPI-HS (beyaz liste)
    - Standart numarası   -> KAPI-SS (ambarda var mı)

  KULLANIM (dot-source):
    . (Join-Path $depoKok 'arac\kimlik-ayikla.ps1')
    $kodlar = Get-HesapKodu $metin
    $std    = Get-StandartNo $metin
================================================================================
#>

# THP hesap kodu: 3 haneli (1xx-7xx) + ARDINDAN hesap ADI gelir.
# ⛔ Standart öneki olanlar hesap kodu DEĞİLDİR: "BDS 705", "TMS 16", "TFRS 15".
#    11.09 ölçümü: BDS 705 dört soruda doğru kullanılmıştı; ön ek istisnası
#    olmadan kapı o dört soruyu "onaylı küme dışı" diye reddederdi.
# ⛔ Madde numarası da hesap kodu değildir: "m.482", "madde 516".
$script:KIMLIK_HESAP_DESENI =
  '(?<!(?:BDS|TMS|TFRS|TSRS|KKS|BOBİ FRS|KÜMİ FRS|BOBI FRS|KUMI FRS)\s)' +
  '(?<!\bm\.\s?)(?<!\bmadde\s)' +
  '(?<![\d.,])([1-7]\d{2})(?![\d.,])\s+(?=[A-ZÇĞİÖŞÜa-zçğıöşü])'

$script:KIMLIK_STD_DESENI = '(?i)\b(BDS|TMS|TFRS|TSRS|KKS)\s*(\d{1,4})'

function Get-HesapKodu([string]$metin){
  if(-not "$metin".Trim()){ return @() }
  return @([regex]::Matches("$metin",$script:KIMLIK_HESAP_DESENI) |
           ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
}

function Get-StandartNo([string]$metin){
  if(-not "$metin".Trim()){ return @() }
  return @([regex]::Matches("$metin",$script:KIMLIK_STD_DESENI) |
           ForEach-Object { ($_.Groups[1].Value.ToUpperInvariant() + ' ' + $_.Groups[2].Value) } |
           Select-Object -Unique)
}

# Kanun künyesi: "TTK m.482", "6102 sayılı", "VUK madde 275"
function Get-MaddeKunyesi([string]$metin){
  if(-not "$metin".Trim()){ return @() }
  $c=New-Object System.Collections.Generic.List[string]
  foreach($m in [regex]::Matches("$metin",'(?i)\b(\d{3,5})\s*say[ıi]l[ıi]')){ if($c -notcontains $m.Groups[1].Value){ $c.Add($m.Groups[1].Value) } }
  foreach($m in [regex]::Matches("$metin",'(?i)\b(m\.|madde)\s*(\d{1,4})')){ $v='m.'+$m.Groups[2].Value; if($c -notcontains $v){ $c.Add($v) } }
  return @($c)
}
