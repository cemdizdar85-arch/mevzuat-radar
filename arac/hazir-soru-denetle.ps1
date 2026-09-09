# HAZIR SORU ÖN DENETİMİ (09.09.2026, GM t2b yazımı) — 0 USD, model çağrısı YOK.
# NE YAPAR: -HazirSoru ile basılacak GM yazımı soru dosyasını, üreticinin kod kapılarını taklit ederek ÖNCEDEN ölçer:
#   şık artan sıra · KokuKusur (onbinlik tutar, uzun tire) · uzunluk tavanı · KAPI-Ç çeldirici yolu (';' yasağı + sonuç uyumu)
#   · adım aritmetiği (zincir eşitlik) · doldur koordinatı · tablo son satırı = doğru şık · KAPI-K pencere sözlüğü · ASCII Türkçe.
# NEDEN: Cem'in DÖRT KURALI — kusur koşuda değil YAZIMDA yakalanır, düşen soru yeniden basım bedeli demektir.
#   Maliyet zor koşusunda ölçüldü: bu betikten geçen 25 sorunun 25'i yayınlanabilir çıktı.
# SÖZLÜK: -Sozluk ile ders penceresi kök sözlüğü verilir (Maliyet için kitapçık S57-64 kelimeleri).
#   'DAR tekrarli' = gerçek kusur (üretici düşürür) · 'DAR disi tek' = yalnız uyarı (geniş sözlükte olabilir).
# KULLANIM: powershell -NoProfile -File arac/hazir-soru-denetle.ps1 -Dosya veri/fabrika/hazir-<etiket>.json [-Sozluk <kelime dosyasi>]
# GM hazır soru dosyası ÖN DENETİMİ (0 USD): üreticinin kod kapılarını çalıştırmadan taklit eder.
param([Parameter(Mandatory)][string]$Dosya,[string]$Sozluk='')
$trS=[cultureinfo]::GetCultureInfo('tr-TR')
function Duz([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant() }
function Sayi([string]$t){ $m=[regex]::Match("$t",'-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?'); if($m.Success){ try{ return [double]::Parse($m.Value,$trS) }catch{ return $null } }; return $null }
function Hesapla([string]$ifade){ $t=$ifade -replace '\.','' -replace ',','.' -replace 'x','*'; if($t -notmatch '^[\d\.\s\*/+\-]+$'){ return $null }; try{ return [double](Invoke-Expression $t) }catch{ return $null } }
$sz=@{}; if($Sozluk -and (Test-Path $Sozluk)){ foreach($w in ((Get-Content $Sozluk -Raw -Encoding UTF8) -split '\s+')){ $w=Duz $w; if($w.Length -ge 5){ $sz[$w.Substring(0,5)]=1 } } }
$liste=Get-Content $Dosya -Raw -Encoding UTF8 | ConvertFrom-Json
"dosya: $Dosya | soru: $($liste.Count) | sozluk kok: $($sz.Keys.Count)"
$i=0
foreach($q in $liste){
  $i++; $k=New-Object System.Collections.Generic.List[string]
  $harf=@('A','B','C','D','E')
  foreach($h in $harf){ if(-not $q.siklar.PSObject.Properties[$h]){ $k.Add("sik $h yok") } }
  if($harf -notcontains "$($q.dogru)"){ $k.Add("dogru harfi bozuk") }
  # sayısal şıklar: artan sıra, tekrar yok
  $sayisal=$true; $deg=@()
  foreach($h in $harf){ $s="$($q.siklar.$h)".Trim(); $m=[regex]::Match($s,'^%?\s*(-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?)\s*(TL|%|adet|kg|saat|birim)?\s*$'); if($m.Success){ $deg+=[double]::Parse($m.Groups[1].Value,$trS) } else { $sayisal=$false } }
  if($sayisal){ for($j=1;$j -lt 5;$j++){ if($deg[$j] -le $deg[$j-1]){ $k.Add("siklar artan degil/tekrar: $($deg -join ' ')"); break } } }
  # KokuKusur: gövdede >=4 tutar hepsi onbinlik
  $tutar=@([regex]::Matches("$($q.soru)",'(?<![\d.,])\d{1,3}(?:\.\d{3})+(?![\d.,])') | ForEach-Object { [long]($_.Value -replace '\.','') })
  if($tutar.Count -ge 4 -and -not @($tutar | Where-Object { $_ % 10000 -ne 0 }).Count){ $k.Add("tutarlarin hepsi onbinlik ($($tutar.Count))") }
  if("$($q.soru)" -match '—|…'){ $k.Add('uzun tire / uc nokta') }
  if("$($q.soru)".Length -gt 746){ $k.Add("soru uzun $("$($q.soru)".Length)") }
  # KAPI-Ç: çeldirici yolunda ';' yasak; formül sonucu şık tutarıyla uyumlu
  if($q.celdirici_yol){ foreach($p in @($q.celdirici_yol.PSObject.Properties)){ $v="$($p.Value)"; if($v -match ';'){ $k.Add("celdirici $($p.Name) icinde ';'") }
      if($sayisal){ $son=[regex]::Matches(($v -replace '\([^)]*\)',''),'=\s*(-?[\d\.,]+)'); if($son.Count){ $cv=Sayi $son[$son.Count-1].Groups[1].Value; $sv=Sayi "$($q.siklar.($p.Name))"; if($null -ne $cv -and $null -ne $sv -and [math]::Abs($cv-$sv) -gt [math]::Max(0.5,[math]::Abs($sv)*0.005)){ $k.Add("celdirici $($p.Name) sonucu $cv != sik $sv") } } }
      if("$($p.Name)" -eq "$($q.dogru)"){ $k.Add("celdirici dogru sikta ($($p.Name))") } } }
  # adım aritmetiği (AritmetikKusur taklidi) + ';' zinciri
  $n=0; foreach($a in @($q.adimlar)){ $n++; $f="$($a.formul)"
    if($f -match ';' -and $f -match '=.*;.*='){ $k.Add("adim $n formulde ';' zinciri") }
    $tmz=$f -replace '×','x' -replace '\([^)]*\)',' ' -replace '(?i)\b(TL|kg|adet|saat|birim|ay|yil|yıl|gun|gün)\b',' ' -replace '−','-' -replace '–','-'
    $segs=@($tmz -split '\s=\s' | ForEach-Object { $_.Trim() } | Where-Object { $_ }); if($segs.Count -lt 2){ continue }
    $sonS=$segs[$segs.Count-1]; if($sonS -notmatch '^[\d\.,\-\s]+$'){ continue }; $son=Sayi $sonS; if($null -eq $son){ continue }
    foreach($sol in $segs[0..($segs.Count-2)]){ if($sol -notmatch '^[\d\.,\s]+(?:[x*/+\-]\s*[\d\.,]+\s*)+$'){ continue }; $h=Hesapla $sol; if($null -eq $h){ continue }
      $tol=[math]::Max(0.51,[math]::Abs($son)*0.001); if([math]::Abs($h-$son) -gt $tol -and [math]::Abs($h*100-$son) -gt $tol -and [math]::Abs($h/100-$son) -gt $tol){ $k.Add("adim $n aritmetik: '$sol' = $([math]::Round($h,2)) ama yazilan $son") } }
    if($a.doldur){ foreach($d in @($a.doldur)){ if($q.cozum_tablo -and $q.cozum_tablo.satirlar){ if($d[0] -ge @($q.cozum_tablo.satirlar).Count){ $k.Add("adim $n doldur satir $($d[0]) tablo disi") } } } } }
  # tablo son satırı = cevap (hesaplı soruda)
  if($sayisal -and $q.cozum_tablo -and $q.cozum_tablo.satirlar){ $sonSat=@($q.cozum_tablo.satirlar)[-1]; $sv=Sayi "$($sonSat[-1])"; $dv=Sayi "$($q.siklar.($q.dogru))"; if($null -ne $sv -and $null -ne $dv -and [math]::Abs($sv-$dv) -gt [math]::Max(0.5,[math]::Abs($dv)*0.005)){ $k.Add("tablo son satir $sv != dogru sik $dv") } }
  # KAPI-K (DAR): >=6 harf, 5 harf önek; sözlükte yok → listele; >=2 tekrar → kusur adayı
  if($sz.Keys.Count){ $say=@{}; $kel=@{}; foreach($w in ((Duz "$($q.soru)") -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -lt 6){ continue }; $on=$w.Substring(0,5); if(-not $say.ContainsKey($on)){ $say[$on]=0; $kel[$on]=$w }; $say[$on]++ }
    $eksik=@(); $tekrar=@(); foreach($on in $say.Keys){ if(-not $sz.ContainsKey($on)){ if($say[$on] -ge 2){ $tekrar+=$kel[$on] } else { $eksik+=$kel[$on] } } }
    if($tekrar.Count){ $k.Add("KAPI-K DAR tekrarli (kusur): $($tekrar -join ', ')") }
    if($eksik.Count){ $k.Add("KAPI-K DAR disi tek (genis sozlukte olmali): $($eksik -join ', ')") } }
  # ASCII Türkçe
  $tum="$($q.soru) "+(@($harf | ForEach-Object { "$($q.siklar.$_)" }) -join ' ')+' '+(@($q.adimlar | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')
  $asc=@([regex]::Matches($tum.ToLowerInvariant(),'\b(icin|degil|isletme|donem|uretim|dogru|yanlis|ucret|hesabi|satis|yuzde|deger|iscilik|dagitim|kayit|kaydi|urun|uretilen|tutari|yapilan|icinde|once)\b') | ForEach-Object { $_.Value } | Select-Object -Unique); if($asc.Count){ $k.Add("ASCII Turkce: $($asc -join ',')") }
  $etiket=$(if($k.Count){ 'KUSUR' } else { 'ok' })
  "{0,2}. {1,-36} {2}" -f $i,$q.konu,$etiket
  foreach($x in $k){ "      - $x" }
}
