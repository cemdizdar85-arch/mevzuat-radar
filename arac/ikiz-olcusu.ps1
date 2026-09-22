#requires -Version 5.1
<#
================================================================================
  İKİZ ÖLÇÜSÜ — TEK CETVEL  (22.09.2026)  bedel 0

  NİYE AYRI DOSYA: aynı iş için İKİ AYRI CETVEL vardı ve ikisi farklı ölçüyordu.
    · üretim (motor/kalip-parti-uret.ps1): ≥4 harfli KELİME kümesi, Jaccard ≥0,60,
      yalnız SORU metni
    · yayın (arac/smmm-kasa-yayin.ps1): 3'LÜ HARF kümesi, Jaccard ≥0,60,
      SORU **VE** DOĞRU ŞIK
  ÖLÇÜLDÜ (22.09): yayın cetvelinin ikiz saydığı 78 çiftte üretim cetvelinin
  değeri 0,33'e kadar iniyor. Ambara girmeyen 107 sorunun 47'sinin ikizi vardı;
  bunların 24'ünü üretim cetveli KAÇIRMIŞTI. Yani soru üretildi, hakemden geçti,
  parası ödendi — sonra yayında ikiz diye elendi.

  Bundan sonra iki taraf da BU dosyayı kullanır. Cetvel değişirse iki tarafta
  birden değişir.

  🚫 BU ÖLÇÜ ŞUNU GÖRMEZ: anlamı — yalnız harf örtüşmesine bakar. Aynı kuralı
    bambaşka kelimelerle soran iki soruyu ikiz saymaz; sayısı değişmiş ama
    kalıbı aynı iki soruyu ise ikiz sayabilir (rakamlar üçlülerde korunur,
    bu yüzden farklı sayı benzerliği DÜŞÜRÜR).
  🚫 Ders ayrımını BU DOSYA yapmaz; çağıran taraf hangi havuzda arayacağına
    kendi karar verir (yayıncı ders içinde arar).

  ÖZ-SINAV: powershell -NoProfile -File arac/ikiz-olcusu-sinavi.ps1
================================================================================
#>

function IkizKatla([string]$s) {
  $x = "$s".ToLowerInvariant()
  foreach ($c in @(@('ç', 'c'), @('ğ', 'g'), @('ı', 'i'), @('İ', 'i'), @('ö', 'o'), @('ş', 's'), @('ü', 'u'))) { $x = $x.Replace($c[0], $c[1]) }
  $x = $x.Replace('²', '2').Replace('³', '3').Replace('¹', '1')
  return ((($x -replace '[^a-z0-9]', ' ') -replace '\s+', ' ').Trim())
}
function IkizUcluler([string]$t) {
  $k = ($t -replace ' ', '')
  $h = New-Object 'System.Collections.Generic.HashSet[string]'
  for ($i = 0; $i -le $k.Length - 3; $i++) { [void]$h.Add($k.Substring($i, 3)) }
  return , $h
}
function IkizBenzerlik($ax, $bx) {
  if (-not $ax -or -not $bx -or $ax.Count -eq 0 -or $bx.Count -eq 0) { return 0.0 }
  $n = 0; foreach ($u in $ax) { if ($bx.Contains($u)) { $n++ } }
  $b = $ax.Count + $bx.Count - $n
  if ($b -le 0) { return 0.0 }
  return $n / [double]$b
}
# Bir sorunun ikiz parmak izi: soru metni + doğru şık metni üçlüleri
function IkizParmak([string]$soru, [string]$dogruSik) {
  return [pscustomobject]@{ uc = (IkizUcluler (IkizKatla $soru)); ucD = (IkizUcluler (IkizKatla $dogruSik)) }
}
# İKİ ÖLÇÜT BİRDEN: soru ≥ esik VE doğru şık ≥ sikEsik
function IkizMi($parmakA, $parmakB, [double]$esik = 0.60, [double]$sikEsik = 0.60) {
  if (-not $parmakA -or -not $parmakB) { return $false }
  if ((IkizBenzerlik $parmakA.uc $parmakB.uc) -lt $esik) { return $false }
  if ((IkizBenzerlik $parmakA.ucD $parmakB.ucD) -lt $sikEsik) { return $false }
  return $true
}
# Ölçülen değeri de isteyen çağıran için
function IkizDeger($parmakA, $parmakB) {
  return [pscustomobject]@{ soru = (IkizBenzerlik $parmakA.uc $parmakB.uc); sik = (IkizBenzerlik $parmakA.ucD $parmakB.ucD) }
}
# Bir nesnenin doğru şık metnini çıkarır (siklar.<dogru>)
function IkizDogruMetin($v) {
  $d = "$($v.dogru)".Trim().ToUpperInvariant()
  if (-not $d -or -not $v.PSObject.Properties['siklar'] -or -not $v.siklar) { return '' }
  return "$($v.siklar.$d)"
}
# ⭐ ÖN SÜZGEÇ EŞİĞİ — üretim tarafı her çift için üçlü hesaplamasın diye önce ucuz
#   kelime ölçüsüyle eler. ÖLÇÜLDÜ (22.09, 78 gerçek ikiz çifti): kelime-Jaccard'ın
#   EN DÜŞÜĞÜ 0,33. Eşik 0,25 seçildi — ölçülen en düşüğün altında pay bırakır.
#   ⚠ Bu bir HIZ süzgecidir, kalite kapısı değil; düşürdüğü çift ikiz SAYILMAZ, yani
#   eşik yanlış seçilirse kapı KÖR kalır (yanlış alarm değil, KAÇIRMA üretir).
$script:IKIZ_ON_ESIK = 0.25
