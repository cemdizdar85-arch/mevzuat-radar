# ============================================================================
#  ARAÇ NÖBETÇİSİ — RG'de tebliğ/karar çıktı, hangi ARAÇ VERİSİ eskidi?
#                                                            (PARA HARCAMAZ)
#
#  Dayanak Nöbetçisi (dayanak-nobetci.ps1) SAYFALARI koruyor: madde damgası
#  "şu madde değişti" dediğinde o maddeye yaslanan sayfaları kırmızı yakıyor.
#  Ama araç VERİSİ kanun maddesine yaslanmıyor — tebliğ ve Cumhurbaşkanı
#  kararlarına yaslanıyor ve madde damgası onları GÖRMÜYOR.
#
#  29.07 ölçümü, acı olan kısım: bu dosyaların hiçbiri otomatik bir kaynaktan
#  beslenmiyor. Hasat betiklerinin başlıkları okundu — hepsi Cem'in bir kere
#  indirdiği YEREL Excel/metin dosyalarından üretilmiş (igv2026 klasörü,
#  damping.xlsx, rejim2026 klasörü, kdv-oranlari-gib.txt). Yani İthalat Rejimi
#  Kararı değiştiğinde GTİP verimiz sessizce eskiyor ve kimse bilmiyor.
#
#  Hash nöbeti kurulamıyor: izlenecek sabit bir adres yok. Onun yerine
#  RESMÎ GAZETE TETİĞİ — kart robotu zaten her gün RG'yi tarayıp başlıklı kart
#  üretiyor (veri/kartlar-guncel.json). Başlıkta anahtar geçerse ilgili dosya
#  "ESKİMİŞ OLABİLİR" diye işaretlenir.
#
#  DÜRÜSTLÜK NOTU — BU BİR TRIPWIRE, GARANTİ DEĞİL:
#  Anahtar kelime eşleşmesi yanlış alarm verebilir; başlık farklı yazılmışsa
#  KAÇIRABİLİR. Ama bugün sinyal SIFIR. Yanlış alarm veren nöbetçi, hiç
#  nöbetçi olmamasından iyidir — yeter ki "kesin yakalar" denmesin.
#
#  Çıktı: veri/arac-uyari.json  ·  etkilenen dosya varsa exit 1 (KIRMIZI)
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/arac-nobet-log.txt') -Force | Out-Null } catch {}

$beyanYol = Join-Path $kok 'veri/arac-dayanak.json'
$kartYol  = Join-Path $kok 'veri/kartlar-guncel.json'

if(-not (Test-Path $beyanYol)){ Write-Host "arac-dayanak.json yok - atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not (Test-Path $kartYol)){  Write-Host "kartlar-guncel.json yok - kart robotu bugun kart uretmemis (sakin RG gunu normaldir). Atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

$beyan = Get-Content $beyanYol -Raw -Encoding UTF8 | ConvertFrom-Json
$kart  = Get-Content $kartYol  -Raw -Encoding UTF8 | ConvertFrom-Json

$kartlar = @($kart.kartlar)
Write-Host ("RG gunu      : {0}" -f $kart.gun)
Write-Host ("Kart sayisi  : {0}" -f $kartlar.Count)
Write-Host ("Izlenen dosya: {0}" -f @($beyan.dosyalar).Count)

if($kartlar.Count -eq 0){
  Write-Host "Bugun kart yok - sakin RG gunu. Temiz."
  [IO.File]::WriteAllText((Join-Path $kok 'veri/arac-uyari.json'),
    ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); rg_gun="$($kart.gun)"; kart=0; etkilenen_dosya=0; uyarilar=@() } | ConvertTo-Json -Depth 5),
    (New-Object Text.UTF8Encoding($false)))
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

# ASCII katlama: RG basliklari bazen Turkce karaktersiz yaziliyor ("gozetim"
# / "gözetim"). Iki yaziliş da yakalanmali - bu tuzak bu depoda daha once
# konu eslestirmede yasandi (imatch ASCII/Turkce).
function Katla([string]$s){
  $t = "$s".ToLowerInvariant()
  $t = $t -replace [char]0x00E7,'c' -replace [char]0x011F,'g' -replace [char]0x0131,'i' `
          -replace [char]0x00F6,'o' -replace [char]0x015F,'s' -replace [char]0x00FC,'u' `
          -replace [char]0x0130,'i' -replace [char]0x00C7,'c' -replace [char]0x011E,'g' `
          -replace [char]0x00D6,'o' -replace [char]0x015E,'s' -replace [char]0x00DC,'u'
  return ($t -replace '\s+',' ')
}

# gunun butun kart metni tek havuzda (baslik + ne_oldu + varsa digerleri)
$havuz = New-Object System.Collections.Generic.List[object]
foreach($k in $kartlar){
  $parcalar = @()
  foreach($p in $k.PSObject.Properties){
    if($p.Value -is [string]){ $parcalar += "$($p.Value)" }
  }
  $havuz.Add([pscustomobject]@{ baslik="$($k.baslik)"; katlanmis=(Katla ($parcalar -join ' ')) })
}

$uyari = New-Object System.Collections.Generic.List[object]
foreach($d in @($beyan.dosyalar)){
  # Ayni kart birden fazla anahtarla eslesebilir ("gozetim" ve "gözetim" ayni
  # basligi tutuyor). Rapor KART bazinda tekillestirilir; yoksa tek bir yayin
  # dort satir gibi gorunur ve GM "dort ayri sey olmus" saniyor.
  $vurulan = @()
  $gorulenKart = @{}
  foreach($ah in @($d.rg_anahtar)){
    $a = Katla $ah
    if(-not $a){ continue }
    foreach($h in $havuz){
      if(-not $h.katlanmis.Contains($a)){ continue }
      if($gorulenKart.ContainsKey($h.baslik)){ continue }
      $gorulenKart[$h.baslik] = 1
      $vurulan += [ordered]@{ anahtar="$ah"; kart_basligi=$h.baslik }
    }
  }
  if($vurulan.Count -gt 0){
    $uyari.Add([ordered]@{
      dosya="$($d.dosya)"; arac="$($d.arac)"; kaynak_ad="$($d.kaynak_ad)"
      hasat="$($d.hasat)"; eslesme_sayisi=$vurulan.Count; eslesmeler=$vurulan
    })
  }
}

$cikti = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  rg_gun = "$($kart.gun)"
  kart = $kartlar.Count
  etkilenen_dosya = $uyari.Count
  not = "TRIPWIRE - anahtar kelime eslesmesi. Yanlis alarm verebilir, farkli yazilmis basligi kacirabilir. GM her satiri tek tek okur."
  uyarilar = $uyari
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/arac-uyari.json'), ($cikti | ConvertTo-Json -Depth 7), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
if($uyari.Count -eq 0){
  Write-Host "TEMIZ: bugunku RG kartlarinda hicbir arac verisini ilgilendiren anahtar gecmiyor."
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

Write-Host "======================================================================"
Write-Host ("  RG'DE ILGILI YAYIN VAR - {0} ARAC VERISI ESKIMIS OLABILIR" -f $uyari.Count)
Write-Host "======================================================================"
foreach($u in $uyari){
  Write-Host ("  {0}   (arac: {1})" -f $u.dosya, $u.arac)
  Write-Host ("      dayanak: {0}" -f $u.kaynak_ad)
  Write-Host ("      hasat  : {0}" -f $u.hasat)
  # Ekranda EN FAZLA 5 - tam liste JSON'da. Onlarca satir doken bir uyari
  # okunmaz hale gelir; okunmayan uyari, olmayan uyaridir.
  $i = 0
  foreach($e in $u.eslesmeler){
    if($i -ge 5){ Write-Host ("      ... ve {0} yayin daha (tamami arac-uyari.json'da)" -f ($u.eslesmeler.Count - 5)); break }
    Write-Host ("      <- {0}" -f $e.kart_basligi); $i++
  }
}
Write-Host ""
Write-Host "  YAPILACAK: ilgili kaynagin GUNCEL halini indirip hasat betigini"
Write-Host "  yeniden kosmak. Bu dosyalar otomatik beslenmiyor - elle tazelenir."
Write-Host "  -> veri/arac-uyari.json"
Write-Host ""
Write-Host "  KOSU BILEREK KIRMIZI: sessiz rapor okunmaz."
try{Stop-Transcript|Out-Null}catch{}
exit 1
