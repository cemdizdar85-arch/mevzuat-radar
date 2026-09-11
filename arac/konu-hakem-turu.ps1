#requires -Version 5.1
<#
================================================================================
  KONU ETIKETI IKINCI GORUS TURU  (11.09.2026, Cem "₺42'lik ikinci gorus turu kos")

  NIYE: arac/konu-etiket-uyumu.ps1 SOZCUK duzeyinde olcum yapiyor ve 648'in
  182'sini (%28) supheli isaretledi. Elle okunan 4 vakada 2 gercek uyusmazlik,
  1 yanlis pozitif, 1 "fazla genel" cikti - yani sozcuk olcumu tek basina hukum
  veremez. Bu tur ANLAM duzeyinde ikinci gorus alir.

  ⛔ URETIM HAKEMINDEN FARKI: uretimdeki hakem soruyu butun yonleriyle yargilar
  (dogruluk, celdirici, kaynak, koku...) ve `konu_uyum` onun BIR alt basligidir.
  11.09 olcumu gosterdi ki o alan ders uygunlugunu yakaliyor ama konu ADININ
  isabetini gevsek denetliyor: elle okudugum uc uyusmazlikta (denetim-zor/kp-20,
  t2-denetim-zor/kp-26, fmuh-kolay/kp-30) hakem konu_uyum=EVET demisti.
  Bu tur SADECE TEK SORUYU sorar: "bu etiket bu soruyu adlandiriyor mu".

  BEDEL - OLCULEREK tahmin edildi, varsayimla degil:
    girdi ≈600 jeton, cikti ≈80 jeton, Haiku 1/5 USD/M
    -> soru basina ≈0,001 USD · 636 soru ≈0,64 USD (≈27 TL)
    Cem'in onayladigi tavan 42 TL. -Tavan ile korunur.
  Karsilastirma: FAZ S cagrisi ≈4.750 girdi jetonla 0,009 USD/soru idi;
  bu cagri ondan ~9 kat kucuk cunku kaynak metni GONDERILMIYOR.

  CIKTI: veri/konu-hakem-turu.json + ekrana ozet.
  KARAR VERMEZ, ONARMAZ. Yalnizca iki liste uretir: duzeltilecekler ve
  yanlis pozitifler. Onarim ayri ve Cem'in karari.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-hakem-turu.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-hakem-turu.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,                 # olmadan: kuru kosu, bedel 0
  [double]$TavanTL = 42,        # Cem'in onayladigi tavan
  [int]$Ornek = 0,              # >0 ise yalniz ilk N soru (prova)
  [string]$Secim = 'veri\sinav\kaydir-secim\sgs-650-secim.json'
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')

$ham = Get-Content (Join-Path $depoKok $Secim) -Raw -Encoding UTF8 | ConvertFrom-Json
$sec = @($ham)
if($Ornek -gt 0){ $sec = @($sec | Select-Object -First $Ornek) }

# Bedel tahmini: 0,0014 USD/soru. Bu sayi TAHMIN DEGIL, 11.09 provasinda OLCULDU:
# 5 soru -> girdi 4.499 · cikti 509 jeton -> 0,007 USD. Ilk yazdigim 0,001
# degeri girdiyi 600 jeton saymisti, gercegi 900. 1 USD = 42 TL.
$tahminUSD = $sec.Count * 0.0014
$tahminTL  = $tahminUSD * 42
Write-Host ("PLAN: {0} soru · tahmini {1:N2} USD (~{2:N0} TL)" -f $sec.Count,$tahminUSD,$tahminTL) -ForegroundColor Cyan
if($tahminTL -gt $TavanTL){ throw ("TAVAN ASILDI: {0:N0} TL > {1:N0} TL. Bilerek asilacaksa -TavanTL yukselt." -f $tahminTL,$TavanTL) }
if(-not $Yaz){ Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Kosmak icin: -Yaz" -ForegroundColor Yellow; return }

$ISTEM = @'
Sen bir sinav soru bankasinin KONU ETIKETI denetcisisin. Sana bir soru ve o
soruya verilmis konu etiketi veriliyor. TEK ISIN: etiketin bu soruyu dogru
adlandirip adlandirmadigini soylemek. Sorunun dogrulugunu, celdiricilerini,
uzunlugunu YARGILAMA - onlar baska hakemin isi.

Uc karardan birini ver:
  UYGUN      : etiket sorunun olctugu konuyu adlandiriyor. Etiketin kelimeleri
               soruda birebir gecmese de olur (ornek: etiket "duran varlik
               satisi", soru "makine satisi" - bu UYGUNDUR, makine duran varliktir).
  GENIS      : etiket yanlis degil ama cok genel; soru daha dar bir konuyu
               olcuyor (ornek: etiket "gelir tablosu hesaplari", soru 611 Satis
               Iskontolari kaydi). Bu durumda daha isabetli etiketi oner.
  YANLIS     : etiket sorunun olctugu konuyu adlandirmiyor. Dogru etiketi yaz.

Kucuk harfli, Turkce, en fazla 5 kelimelik etiket oner (mevcut etiket bicimiyle
ayni: madde numarasi ve kisaltma yok, kucuk harf).

Cevap YALNIZ JSON, oncesinde/sonrasinda hicbir metin yok:
{"karar":"UYGUN|GENIS|YANLIS","onerilen_etiket":"...","gerekce":"tek cumle"}
onerilen_etiket yalniz GENIS ve YANLIS icin doldurulur; UYGUN ise bos string.
'@

function Coz2($metin){
  $t="$metin"
  $i=$t.IndexOf('{'); $j=$t.LastIndexOf('}')
  if($i -lt 0 -or $j -le $i){ return $null }
  try{ return ($t.Substring($i,$j-$i+1) | ConvertFrom-Json) }catch{ return $null }
}

$onb=@{}; $sonuc=New-Object System.Collections.Generic.List[object]
$tokG=0; $tokC=0; $n=0; $bozuk=0
foreach($r in $sec){
  $n++
  $et="$($r.etiket)"
  if(-not $onb.ContainsKey($et)){
    $cf=Join-Path $depoKok "veri\fabrika\kalip-parti-$et.json"
    $onb[$et]= if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
  }
  $v=$onb[$et]; if($v){ $v=$v.($r.id) }
  if(-not $v -or -not $v.soru){ continue }

  $siklar=(@('A','B','C','D','E') | ForEach-Object { "$_) $($v.siklar.$_)" }) -join "`n"
  $istek = $ISTEM + "`n`n=== DERS ===`n$($r.ders)`n=== KONU ETIKETI ===`n$($r.konu)`n=== SORU ===`n$($v.soru)`n=== SIKLAR ===`n$siklar`n=== DOGRU SIK ===`n$($v.dogru)"

  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $istek -MaxTok 300; break }catch{ if($d -eq 3){ throw }; Start-Sleep -Seconds (8*$d) } }
  $tokG+=[int]$y.girdi; $tokC+=[int]$y.cikti
  $k=Coz2 $y.metin
  if(-not $k -or -not $k.karar){
    $bozuk++
    Write-Host ("  COZULEMEDI ({0}/{1}) {2}/{3}: {4}" -f $n,$sec.Count,$et,$r.id,("$($y.metin)" -replace '\s+',' ').Substring(0,[Math]::Min(90,"$($y.metin)".Length))) -ForegroundColor Red
    continue
  }
  $sonuc.Add([pscustomobject]@{
    ders=$r.ders; etiket=$et; id=$r.id; konu="$($r.konu)"
    karar="$($k.karar)"; onerilen="$($k.onerilen_etiket)"; gerekce="$($k.gerekce)"
    uretim_hakemi=$(if($v.hakem -and $v.hakem.PSObject.Properties['konu_uyum']){ "$($v.hakem.konu_uyum)" } else { 'ALAN YOK' })
  })
  if($n % 50 -eq 0){ Write-Host ("  {0}/{1} · YANLIS {2} · GENIS {3}" -f $n,$sec.Count,@($sonuc|Where-Object{$_.karar -eq 'YANLIS'}).Count,@($sonuc|Where-Object{$_.karar -eq 'GENIS'}).Count) -ForegroundColor DarkGray }
}

$bedel = ($tokG*1.0/1e6) + ($tokC*5.0/1e6)
Write-Host ""
Write-Host ("BITTI: {0} soru degerlendirildi · {1} cozulemedi" -f $sonuc.Count,$bozuk) -ForegroundColor Green
Write-Host ("BEDEL: girdi {0} · cikti {1} jeton · ≈{2:N3} USD (~{3:N0} TL) [Haiku 1/5 USD/M varsayimi]" -f $tokG,$tokC,$bedel,($bedel*42))
Write-Host ""
$sonuc | Group-Object karar | Sort-Object Count -Descending | ForEach-Object {
  Write-Host ("  {0,-8} {1,4}  (%{2:N1})" -f $_.Name,$_.Count,(100*$_.Count/$sonuc.Count))
}
Write-Host "`nURETIM HAKEMI ile KARSILASTIRMA (bu turun YANLIS dedikleri):"
$sonuc | Where-Object { $_.karar -eq 'YANLIS' } | Group-Object uretim_hakemi | ForEach-Object {
  Write-Host ("  uretim hakemi '{0}' demisti -> {1} soru" -f $_.Name,$_.Count)
}
Write-Host "`nDERS BAZLI YANLIS ORANI:"
$sonuc | Group-Object ders | Sort-Object Count -Descending | ForEach-Object {
  $y=@($_.Group | Where-Object { $_.karar -eq 'YANLIS' }).Count
  Write-Host ("  {0,-30} {1,4} soru · YANLIS {2,3} (%{3:N0})" -f $_.Name,$_.Count,$y,(100*$y/$_.Count))
}
Write-Host "`nEN ILK 15 YANLIS:"
$sonuc | Where-Object { $_.karar -eq 'YANLIS' } | Select-Object -First 15 | ForEach-Object {
  Write-Host ("  {0,-22} {1,-7} '{2}' -> '{3}'" -f $_.etiket,$_.id,$_.konu,$_.onerilen)
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\konu-hakem-turu.json') -Nesne ([ordered]@{
  olcum  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak = $Secim
  model  = 'claude-haiku-4-5'
  yontem = 'ANLAM duzeyi ikinci gorus: yalniz "bu etiket bu soruyu adlandiriyor mu". Sorunun dogrulugu YARGILANMAZ.'
  bedel_usd = [math]::Round($bedel,4)
  jeton = @{ girdi=$tokG; cikti=$tokC }
  toplam = $sonuc.Count
  cozulemeyen = $bozuk
  kararlar = (@($sonuc | Group-Object karar | ForEach-Object { @{ karar=$_.Name; adet=$_.Count } }))
  satirlar = $sonuc
})
Write-Host "`n-> veri/konu-hakem-turu.json"
