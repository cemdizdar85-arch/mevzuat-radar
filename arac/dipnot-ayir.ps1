#requires -Version 5.1
# ============================================================================
#  DIPNOT AYIRICI — ortak yardimci (22.09.2026, Cem "1 ve 2 yap")
#  Iki yutucu da bunu kullanir: motor/standart-yut.ps1 ve motor/kgk-standart-yut.ps1
#  Kullanim:  . (Join-Path $PSScriptRoot '..\arac\dipnot-ayir.ps1')  ->  DipnotAyir $metin
#  Oz-sinav:  powershell -NoProfile -File arac/dipnot-ayir.ps1 -OzSinav
# ============================================================================
param([switch]$OzSinav)
# --- DIPNOT AYIRICI (22.09.2026, Cem "1 ve 2 yap") ---------------------------
# KUSUR (olculdu 21.09, arac/ambar-metin-kusuru.ps1): pdftotext ust simge dipnot
#   numarasini bir onceki kelimeye/standart numarasina KAYNATIYOR. Ambarda 50.045
#   kaydin 1.072'sinde var; BDS ailesinde 3.035 kaydin 253'unde. Somut zarar:
#   "BDS 50027", "BDS 33023", "BDS 3202" gibi diziler OLMAYAN standart numarasi
#   uretir; soru yazan ajanlar bunlari elle ayiklamak zorunda kaldi (19.09 KGK turu).
# KURAL (iki desen, ikisi de KATI):
#   1) AILE+NUMARA: "BDS 50027" -> aile adi + GECERLI numara + kalan rakam(lar).
#      Gecerli numara listesi ASAGIDAKI $STD_NO'dan gelir; liste disinda ayirma YAPILMAZ
#      (GDS 3402, IHS 4400 gibi gercek 4 haneli numaralar bozulmasin diye).
#   2) KELIME+DIPNOT: en az 4 harfli Turkce kelimeye yapisik 1-2 rakam, ardindan
#      bosluk/noktalama: "aciklamalara64" -> "aciklamalara". Aile adlari bu desene
#      girmez (1. kural once kosar), 3 harften kisa kelimeler ve rakamla baslayanlar
#      dokunulmaz.
# BU KAPI SUNU GORMEZ: metnin ortasinda gecen "1)" gibi fikra numaralari, iki sutunlu
#   tablo karismasi, dipnot METNININ govdeye karismasi (ayri kusur, K3).
# Oz-sinav: powershell -NoProfile -File motor/kgk-standart-yut.ps1 -OzSinav
$STD_NO = @{
  'BDS'  = @(200,210,220,230,240,250,260,265,299,300,315,320,330,402,450,500,501,505,510,520,530,540,550,560,570,580,600,610,620,700,701,705,706,710,720,800,805,810)
  'GDS'  = @(3000,3400,3402,3410,3420)
  'IHS'  = @(4400,4410)
  'KYS'  = @(1,2)
  'TSRS' = @(1,2)
  'SBDS' = @(2400,2410)
}
function DipnotAyir([string]$Metin){
  if(-not $Metin){ return $Metin }
  $s = $Metin
  # 1) aile + numara + yapisik dipnot
  $s = [regex]::Replace($s, '\b(BDS|GDS|İHS|IHS|KYS|TSRS|SBDS)\s?(\d{2,6})\b', {
    param($es)
    $aile = $es.Groups[1].Value; $rakam = $es.Groups[2].Value
    $anahtar = $aile.Replace('İ','I')
    if(-not $STD_NO.ContainsKey($anahtar)){ return $es.Value }
    if($STD_NO[$anahtar] -contains [int]$rakam){ return $es.Value }          # gercek numara: dokunma
    for($kes = $rakam.Length - 1; $kes -ge 1; $kes--){
      $bas = $rakam.Substring(0,$kes)
      if($STD_NO[$anahtar] -contains [int]$bas){ return ("$aile $bas") }      # kalan rakam(lar) dipnottur
    }
    return $es.Value                                                          # cozulemedi: dokunma
  })
  # 2) kelime + yapisik dipnot (Turkce harfli, >=4 harf)
  $s = [regex]::Replace($s, '(?<kelime>\p{L}{4,})(?<dipnot>\d{1,2})(?=[\s.,;:)\]])', {
    param($es)
    $k = $es.Groups['kelime'].Value
    if($k -match '^(?i)(BDS|GDS|IHS|KYS|TSRS|SBDS|TMS|TFRS|madde|fikra|paragraf|sayfa|numara)$'){ return $es.Value }
    return $k
  })
  return $s
}


if($OzSinav){
  $vakalar = @(
    @{ ad='BDS 50027 -> BDS 500';   girdi='BDS 50027 uyarinca'; bekle='BDS 500 uyarinca' }
    @{ ad='BDS 3202 -> BDS 320';    girdi='BDS 3202 kapsaminda'; bekle='BDS 320 kapsaminda' }
    @{ ad='GDS 3402 DOKUNULMAZ';    girdi='GDS 3402 hizmet kurulusu'; bekle='GDS 3402 hizmet kurulusu' }
    @{ ad='IHS 4400 DOKUNULMAZ';    girdi='IHS 4400 mutabik kalinan'; bekle='IHS 4400 mutabik kalinan' }
    @{ ad='BDS 200 DOKUNULMAZ';     girdi='BDS 200 genel amaclar'; bekle='BDS 200 genel amaclar' }
    @{ ad='kelime dipnotu ayrilir'; girdi='aciklamalara64 bakilir'; bekle='aciklamalara bakilir' }
    @{ ad='kisa kelime DOKUNULMAZ'; girdi='Ek2 sayili tablo'; bekle='Ek2 sayili tablo' }
    @{ ad='yil rakami DOKUNULMAZ';  girdi='2023 yilinda yayimlandi'; bekle='2023 yilinda yayimlandi' }
  )
  $gecti=0; $kaldi=0
  foreach($v in $vakalar){
    $cikan = DipnotAyir $v.girdi
    if($cikan -eq $v.bekle){ $gecti++; Write-Host ("  OK    {0}" -f $v.ad) }
    else { $kaldi++; Write-Host ("  KALDI {0} | beklenen: {1} | cikan: {2}" -f $v.ad,$v.bekle,$cikan) -ForegroundColor Red }
  }
  Write-Host ("OZ-SINAV: gecti {0} - kaldi {1}" -f $gecti,$kaldi)
  exit $(if($kaldi){ 1 } else { 0 })
}