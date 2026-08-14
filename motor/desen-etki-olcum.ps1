# ============================================================================
#  DESEN ETKI OLCUMU - 14.08
#  Madde ayirici deseni genisletildi (madde numarasindan sonra parantez gelen
#  yazimlar da yakalansin diye). Genisletme KAZANC saglar ama SAHTE MADDE de
#  uretebilir. Bu betik, yutmadan once etkiyi olcer: depodaki her hazir metinde
#  ESKI desenle ve YENI desenle kac madde basligi bulunuyor, fark nedir.
#
#  Yorum kurali: kucuk artis = kazanilmis madde (iyi). Anormal artis (>%15 ya da
#  >30 madde) = SAHTE ESLESME suphesi, o dosya ELLE bakilir.
#  OLCUM betigi - hicbir sey yazmaz.
# ============================================================================
param([int]$Esik = 15)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$hazir = Join-Path $kok "veri\mevzuat-hazir"

$turler = 'MÜKERRER MADDE|EK GEÇİCİ MADDE|EK MADDE|GEÇİCİ MADDE|Mükerrer MADDE|Ek Geçici MADDE|Ek MADDE|Geçici MADDE|MADDE|Mükerrer Madde|Ek Geçici Madde|Ek Madde|Geçici Madde|Madde'
$eskiRx = [regex]::new("(?:(?<pre>\p{Lu}[^:]{1,70}):\s*)?(?<tur>$turler)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*[–—-]", [Text.RegularExpressions.RegexOptions]::Compiled)
$yeniRx = [regex]::new("(?:(?<pre>\p{Lu}[^:]{1,70}):\s*)?(?<tur>$turler)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*(?:\(\s*(?:Değişik|Mülga|Ek|Yeniden|Başlığı|Değiştirilen)[^)]{0,140}\)\s*[:–—-]?|[–—-])", [Text.RegularExpressions.RegexOptions]::Compiled)

$rapor = @()
foreach($f in (Get-ChildItem $hazir -Filter *.txt)){
  # TUZAK (olculdu): yutma betigi metni DUZLESTIREREK isliyor (flatMetin).
  # Ham metinde satir sonlariyla saymak farkli sonuc veriyor: kik icin "+8 madde"
  # gorunuyordu, duzlestirilmis metinde fark SIFIR cikti. Olcum, yutmanin
  # gordugu metinle ayni olmali - yoksa var olmayan kazanc raporlanir.
  $t = ([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)) -replace '\s+',' '
  $e = $eskiRx.Matches($t).Count
  $y = $yeniRx.Matches($t).Count
  if($y -eq $e){ continue }
  $oran = if($e -gt 0){ [math]::Round(100.0*($y-$e)/$e,1) } else { 999 }
  $rapor += [pscustomobject]@{ dosya=$f.BaseName; eski=$e; yeni=$y; fark=($y-$e); oran=$oran }
}
$rapor = @($rapor | Sort-Object fark -Descending)
Write-Host ("Taranan hazir metin : {0}" -f @(Get-ChildItem $hazir -Filter *.txt).Count)
Write-Host ("Sayisi DEGISEN      : {0}" -f $rapor.Count)
Write-Host ("Toplam kazanc       : {0} madde basligi" -f (($rapor | Measure-Object fark -Sum).Sum))
$supheli = @($rapor | Where-Object { $_.oran -gt $Esik -or $_.fark -gt 30 })
Write-Host ("SUPHELI (>{0}% ya da >30 madde) : {1}`n" -f $Esik, $supheli.Count)
Write-Host ("{0,-26} {1,6} {2,6} {3,6} {4,7}" -f "DOSYA","ESKI","YENI","FARK","%")
Write-Host ("-"*58)
foreach($r in ($rapor | Select-Object -First 30)){
  $im = if($r.oran -gt $Esik -or $r.fark -gt 30){ " <-- ELLE BAK" } else { "" }
  Write-Host ("{0,-26} {1,6} {2,6} {3,6} {4,7}{5}" -f $r.dosya, $r.eski, $r.yeni, $r.fark, $r.oran, $im)
}
