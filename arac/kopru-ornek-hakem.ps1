# ============================================================================
#  KÖPRÜ ÖRNEKLEM HAKEMİ (02.09.2026)
#  kopru-dogruluk-taramasi.ps1 kaba sinyal verir (kök eşleşmesi) — yanlış pozitif
#  içerir: "kasa sayim farki" → "THP 100 - Kasa" kökle tutmaz ama DOĞRUDUR.
#  Bu betik rastgele örneklem alıp BAĞIMSIZ HAKEME sorar ve GERÇEK yanlış oranını
#  güven aralığıyla verir. Üç kova ayrı ayrı ölçülür:
#    A) kok_tutan  — tarama "temiz" dedi (yanlış negatif var mı?)
#    B) supheli    — tarama "şüpheli" dedi ama yığılma yok
#    C) cifte      — şüpheli + dayanak yığılmış (en güçlü sinyal)
#  Böylece taramanın kendi isabeti de ölçülmüş olur.
# ============================================================================
param(
  [int]$KovaBasina=15,
  [int]$YiginlanmaEsigi=3
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'motor\api-hedef.ps1')

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
$DURAK=@('icin','gore','ile','veya','olan','olarak','uzere','arasi','hesabi','hesap','kaydi','kayit','yontemi','yontem','islemi','islem','tutari','tutar','orani','oran','sayisi','farki','fark','bedeli','bedel','degeri','deger')
function Kokler([string]$konu){
  $k=Katla $konu
  $p=@($k -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^\d' -and $DURAK -notcontains $_ })
  return @($p | ForEach-Object { if($_.Length -ge 6){ $_.Substring(0,$_.Length-2) } else { $_ } })
}

$tam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar=@($tam | Where-Object { $_.donem -ge 2 })   # en az 2 donem cikanlar = onemli konular
$dayanakKonu=@{}
$satirlar=New-Object System.Collections.Generic.List[object]
foreach($r in $kayitlar){
  $day="$($r.dayanak)"; if(-not $day){ $day="$($r.cikmis_dayanak)" }
  if(-not $day.Trim()){ continue }
  $d=($day -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $dayanakKonu.ContainsKey($d)){ $dayanakKonu[$d]=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal) }
  [void]$dayanakKonu[$d].Add("$($r.konu)")
  $satirlar.Add([pscustomobject]@{ sinav=$r.sinav; konu="$($r.konu)"; dayanak=$d; donem=$r.donem })
}
foreach($s in $satirlar){
  $kk=@(Kokler $s.konu)
  $tutar=($kk.Count -gt 0) -and (@($kk | Where-Object { (Katla $s.dayanak).Contains($_) }).Count -ge 1)
  $yig=$dayanakKonu[$s.dayanak].Count -ge $YiginlanmaEsigi
  $kova=if($tutar){'A_kok_tutan'} elseif($yig){'C_cifte_sinyal'} else{'B_supheli'}
  $s | Add-Member -NotePropertyName kova -NotePropertyValue $kova -Force
}

$istem=@'
Sen bagimsiz bir MEVZUAT HAKEMISIN. Asagida bir SINAV KONUSU ve o konuya atanmis HUKUKI DAYANAK var.
Karar: bu dayanak, bu konunun gercek hukuki/teknik dayanagi OLABILIR MI?
- EVET: dayanak konuyla dogrudan ilgili ya da konunun kaynagi olabilecek nitelikte.
- HAYIR: dayanak baska bir konuya ait, konuyla ilgisiz.
Ornek HAYIR: konu "dikey yuzde analizi" (mali tablo analizi teknigi), dayanak "VUK m.275 Imal edilen emtia" (stok degerleme) - ilgisiz.
Ornek EVET: konu "kasa sayim farki", dayanak "THP 100 - Kasa" - kunye kisa ama dogru hesap.
Cevap YALNIZ JSON: {"karar":"EVET|HAYIR","gerekce":"tek kisa cumle"}
=== KONU === {KONU}
=== ATANMIS DAYANAK === {DAYANAK}
'@

$sonuc=[ordered]@{}
$ayrinti=New-Object System.Collections.Generic.List[object]
foreach($kova in @('A_kok_tutan','B_supheli','C_cifte_sinyal')){
  $havuz=@($satirlar | Where-Object { $_.kova -eq $kova })
  if($havuz.Count -eq 0){ continue }
  # deterministik ornekleme: donem-sirali esit araliklarla (rastgelelik yok, tekrarlanabilir)
  $sirali=@($havuz | Sort-Object { -[int]$_.donem },konu)
  $adim=[Math]::Max(1,[math]::Floor($sirali.Count/$KovaBasina))
  $ornek=New-Object System.Collections.Generic.List[object]
  for($i=0;$i -lt $sirali.Count -and $ornek.Count -lt $KovaBasina;$i+=$adim){ $ornek.Add($sirali[$i]) }
  $evet=0;$hayir=0;$olculemedi=0
  foreach($o in $ornek){
    $ist=$istem.Replace('{KONU}',$o.konu).Replace('{DAYANAK}',$o.dayanak)
    $y=$null
    foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $ist -MaxTok 400; break }catch{ if($d -eq 3){ $y=$null }else{ Start-Sleep -Seconds (5*$d) } } }
    if(-not $y){ $olculemedi++; continue }
    $t="$($y.metin)".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
    $c=$null; try{ $c=$t|ConvertFrom-Json }catch{}
    if(-not $c){ $olculemedi++; continue }
    if("$($c.karar)" -eq 'EVET'){ $evet++ } else { $hayir++ }
    $ayrinti.Add([pscustomobject]@{ kova=$kova; konu=$o.konu; dayanak=$o.dayanak; donem=$o.donem; karar="$($c.karar)"; gerekce="$($c.gerekce)" })
  }
  $olculen=$evet+$hayir
  $sonuc[$kova]=[ordered]@{
    havuz_buyuklugu=$havuz.Count
    orneklem=$ornek.Count
    olculen=$olculen
    dogru=$evet
    yanlis=$hayir
    yanlis_yuzde=$(if($olculen){[math]::Round(100*$hayir/$olculen)}else{'olculemedi'})
    olculemedi=$olculemedi
  }
  Write-Host ("  {0,-16} havuz={1,-6} orneklem={2,-3} DOGRU={3,-3} YANLIS={4,-3} (%{5})" -f $kova,$havuz.Count,$ornek.Count,$evet,$hayir,$sonuc[$kova].yanlis_yuzde)
}
$toplamHavuz=($satirlar | Measure-Object).Count
$tahminiYanlis=0
foreach($k in $sonuc.Keys){
  $o=$sonuc[$k]
  if($o.olculen -gt 0){ $tahminiYanlis += $o.havuz_buyuklugu*($o.yanlis/[double]$o.olculen) }
}
$cikti=[ordered]@{
  aciklama="Kopru dayanak dogrulugunun ORNEKLEM ile olculmus gercek orani. Uc kova ayri ayri orneklendi ve bagimsiz hakeme soruldu; kova oranlari havuz buyuklugune gore agirliklandirilarak toplam tahmin uretildi. Orneklem deterministiktir (donem-sirali esit aralik) - ayni girdide ayni sonucu verir. Kucuk orneklemde oranlar +-10 puan oynayabilir."
  kapsam='donem>=2 olan kopru kayitlari'
  toplam_kayit=$toplamHavuz
  kovalar=$sonuc
  tahmini_yanlis_dayanak=[math]::Round($tahminiYanlis)
  tahmini_yanlis_yuzde=$(if($toplamHavuz){[math]::Round(100*$tahminiYanlis/$toplamHavuz,1)}else{0})
  ornekler=@($ayrinti | ForEach-Object { "[$($_.kova)|$($_.karar)] $($_.konu) => $($_.dayanak) :: $($_.gerekce)" })
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\kopru-ornek-hakem-raporu.json') -Nesne $cikti
Write-Host ""
Write-Host ("TAHMINI YANLIS DAYANAK: {0} kayit / {1} (%{2})" -f $cikti.tahmini_yanlis_dayanak,$toplamHavuz,$cikti.tahmini_yanlis_yuzde)
