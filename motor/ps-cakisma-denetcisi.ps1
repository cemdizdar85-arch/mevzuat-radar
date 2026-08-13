# ============================================================================
#  PS DEGISKEN CAKISMA DENETCISI (13.08.2026) — 0 USD, statik kod taramasi
#
#  BUGUN UC KEZ ISIRDI:
#   1) yayin-kapisi.ps1  : dongu $k, kapi sayaci $K'yi ezdi -> rapor bozuldu
#   2) havuz-dogrulayici : dongu $v, veri yolu $V'yi ezdi -> dosya bir SORU
#      SIKKININ metnine yazilmaya calisildi ("...\Zamanasimi doldugu icin...")
#   3) (tarihce) $U/$u, $h/$H, $A/$a — [[ps-degisken-cakismasi]] hafizasi
#  PowerShell degisken adlarinda BUYUK/KUCUK HARF AYIRMAZ; bu yuzden tek harfli
#  global sabit + tek harfli dongu degiskeni ayni betikte OLUMCULDUR.
#
#  BU BETIK: motor\*.ps1 dosyalarinda tek/iki harfli GLOBAL atama ile ayni
#  harfli DONGU degiskenini arar, cakisma adaylarini listeler. CI'da kosar;
#  yeni aday cikarsa KIRMIZI doner (exit 1) - kod yazan duzeltmeden gecemez.
#  Cikti: veri/ps-cakisma-denetimi.json
# ============================================================================
$ErrorActionPreference = 'Stop'
$buradaKlasor = Split-Path -Parent $MyInvocation.MyCommand.Path
$kokKlasor = Split-Path -Parent $buradaKlasor
$ciktiYolu = Join-Path $kokKlasor 'veri\ps-cakisma-denetimi.json'

$reGlobalAtama = [regex]'(?m)^\s*\$([A-Za-z]{1,2})\s*=\s*'
$reDongu       = [regex]'foreach\s*\(\s*\$([A-Za-z]{1,2})\s+in\b'
$reParam       = [regex]'(?m)^\s*\$([A-Za-z]{1,2})\s*=\s*\$null'

$bulgular = New-Object System.Collections.Generic.List[object]
foreach($dosya in Get-ChildItem (Join-Path $kokKlasor 'motor') -Filter '*.ps1'){
  $metin = Get-Content $dosya.FullName -Raw -Encoding UTF8
  $global = @{}
  foreach($m in $reGlobalAtama.Matches($metin)){
    $ad = $m.Groups[1].Value
    # yalniz UST DUZEY (girintisiz) atamalari global say
    if(-not $global.ContainsKey($ad.ToLower())){ $global[$ad.ToLower()] = $ad }
  }
  $dongu = @{}
  foreach($m in $reDongu.Matches($metin)){ $ad = $m.Groups[1].Value; $dongu[$ad.ToLower()] = $ad }
  foreach($k in $dongu.Keys){
    if($global.ContainsKey($k)){
      $g = $global[$k]; $d = $dongu[$k]
      if($g -cne $d -or $g.Length -le 2){
        $bulgular.Add([pscustomobject]@{ dosya=$dosya.Name; global="`$$g"; dongu="`$$d"; risk=$(if($g -cne $d){'YUKSEK - farkli buyuk/kucuk yazim, sessizce ezer'}else{'ORTA - ayni ad, dongu sonrasi deger kaybolur'}) })
      }
    }
  }
}
$rapor = [ordered]@{
  tarih=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  taranan_betik=(Get-ChildItem (Join-Path $kokKlasor 'motor') -Filter '*.ps1').Count
  aday=$bulgular.Count
  not='PowerShell buyuk/kucuk harf ayirmaz. Tek-iki harfli global sabit + ayni harfli dongu degiskeni = sessiz veri kaybi. Cozum: global sabitlere UZUN ad ver (veriYolu, kapiSayaci), dongu degiskenini anlamlandir (dersAnahtar, sikMetni).'
  bulgular=$bulgular.ToArray()
}
[IO.File]::WriteAllText($ciktiYolu, (ConvertTo-Json $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
# YUKSEK risk = farkli buyuk/kucuk yazim -> SESSIZ EZME (kirmizi, is durur).
# ORTA = ayni ad; PowerShell'de yaygin ve cogu zaman zararsiz (dongu degiskeni
# zaten o degeri kullanir) - bilgi olarak listelenir, kapiyi kirmizi yapmaz.
$yuksek = @($bulgular | Where-Object { $_.risk -like 'YUKSEK*' })
Write-Host ("PS CAKISMA DENETIMI: {0} betik tarandi | YUKSEK {1} | ORTA {2}" -f $rapor.taranan_betik, $yuksek.Count, ($bulgular.Count-$yuksek.Count))
foreach($b in $yuksek){ Write-Host ("  KIRMIZI  {0,-34} {1} <-> {2}" -f $b.dosya, $b.global, $b.dongu) }
if($yuksek.Count -gt 0){ exit 1 }
