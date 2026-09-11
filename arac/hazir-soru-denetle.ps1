# HAZIR SORU ÖN DENETİMİ (09.09.2026, GM t2b yazımı) — 0 USD, model çağrısı YOK.
# NE YAPAR: -HazirSoru ile basılacak GM yazımı soru dosyasını, üreticinin kod kapılarını taklit ederek ÖNCEDEN ölçer:
#   şık artan sıra · KokuKusur (onbinlik tutar, uzun tire) · uzunluk tavanı · KAPI-Ç çeldirici yolu (';' yasağı + sonuç uyumu)
#   · adım aritmetiği (zincir eşitlik) · doldur koordinatı · tablo son satırı = doğru şık · KAPI-K pencere sözlüğü · ASCII Türkçe.
# NEDEN: Cem'in DÖRT KURALI — kusur koşuda değil YAZIMDA yakalanır, düşen soru yeniden basım bedeli demektir.
#   Maliyet zor koşusunda ölçüldü: bu betikten geçen 25 sorunun 25'i yayınlanabilir çıktı.
# SÖZLÜK: -Sozluk ile ders penceresi kök sözlüğü verilir (Maliyet için kitapçık S57-64 kelimeleri).
#   'DAR tekrarli' = gerçek kusur (üretici düşürür) · 'DAR disi tek' = yalnız uyarı (geniş sözlükte olabilir).
# KAPI-K GERÇEK SÖZLÜK (10.09.2026, GM Borçlar t2b): -Ders verilirse sözlük DIŞARIDAN beklenmez, arac/kapi-k-sozluk.ps1
#   ile ambardan kurulur ve üreticinin PencereKavram kuralı birebir uygulanır. NEDEN: 10.09 Borçlar koşusunda düşen 6
#   sorunun 6'sı da bu kapıdan düştü ve bu betik hepsine 'ok' demişti — çünkü sözlüğü üreten bir araç yoktu.
#   Doğrulama: -Ders yoluyla kurulan sözlük, o koşunun düşürdüğü 6 sorunun 6'sını da AYNI kelimelerle yakalıyor.
# KULLANIM: powershell -NoProfile -File arac/hazir-soru-denetle.ps1 -Dosya veri/fabrika/hazir-<etiket>.json
#             [-Ders 'Borclar Hukuku|Ticaret ve Borclar'] [-Pencere 7] [-Sozluk <kelime dosyasi>]
#   -Ders, üretici çağrısındaki -DersRegex ile AYNI yazılır (ders aralığı üreticinin $DERS_ARALIK tablosundan okunur).
# GM hazır soru dosyası ÖN DENETİMİ (0 USD): üreticinin kod kapılarını çalıştırmadan taklit eder.
param([Parameter(Mandatory)][string]$Dosya,[string]$Sozluk='',[string]$Ders='',[int]$Pencere=7)
$trS=[cultureinfo]::GetCultureInfo('tr-TR')
function Duz([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant() }
function Sayi([string]$t){ $m=[regex]::Match("$t",'-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?'); if($m.Success){ try{ return [double]::Parse($m.Value,$trS) }catch{ return $null } }; return $null }
function Hesapla([string]$ifade){ $t=$ifade -replace '\.','' -replace ',','.' -replace 'x','*'; if($t -notmatch '^[\d\.\s\*/+\-]+$'){ return $null }; try{ return [double](Invoke-Expression $t) }catch{ return $null } }
$sz=@{}; if($Sozluk -and (Test-Path $Sozluk)){ foreach($w in ((Get-Content $Sozluk -Raw -Encoding UTF8) -split '\s+')){ $w=Duz $w; if($w.Length -ge 5){ $sz[$w.Substring(0,5)]=1 } } }
$kapiK=$null
if($Ders){
  $kutup=Join-Path $(if($PSScriptRoot){ $PSScriptRoot } else { '.' }) 'kapi-k-sozluk.ps1'
  if(Test-Path $kutup){ . $kutup; $kapiK=KapiKSozlukKur -DersRegex $Ders -Pencere $Pencere }
  if(-not $kapiK){ "UYARI: KAPI-K sozlugu kurulamadi (ambar/anahtar/analiz dosyasi) - bu kapi OLCULMEDI" }
}
$liste=Get-Content $Dosya -Raw -Encoding UTF8 | ConvertFrom-Json
"dosya: $Dosya | soru: $($liste.Count) | sozluk kok: $($sz.Keys.Count)"
if($kapiK){ "KAPI-K sozlugu: genis $($kapiK.genis.Keys.Count) · dar $($kapiK.dar.Keys.Count) (soru $($kapiK.aralik -join '-')) · $($kapiK.blok) blok · son $Pencere donem: $($kapiK.donemler -join ', ')" }
$i=0; $temizSay=0
foreach($q in $liste){
  $i++; $k=New-Object System.Collections.Generic.List[string]
  $not=New-Object System.Collections.Generic.List[string]   # kapıyı DÜŞÜRMEYEN uyarılar (KAPI-K tek kelime gibi)
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
  # KAPI-Ş şık dengesi (10.09 eklendi). NEDEN: Meslek zor+çok zor koşusunda 19 soru YALNIZ bu kapıdan
  # düştü (zor 7/22, çok zor 12/21) ve bu betik hepsine 'ok' demişti. Üreticinin kuralı (uret satır 1419-1425):
  # sayısal şık <=1 ve yönlü şık <4 ise -> doğru şık EN UZUN ve medyanın >=1,3 katıysa düşer; ayrıca
  # parantezli açıklama ya da birim yalnız doğru şıkta olamaz. Eşik 1,3: çıkmışta doğru şık en uzun %5-24.
  $sikM=@($harf | ForEach-Object { "$($q.siklar.$_)".Trim() })
  $dogruS="$($q.siklar.($q.dogru))".Trim()
  $sayiN=@($sikM | Where-Object { $_ -match '^%?\s*-?\d{1,3}(?:\.\d{3})*(?:,\d+)?\s*(TL|%|adet|kg|saat|birim)?\s*$' }).Count
  $yonlu=@($sikM | Where-Object { $_ -match '(?i)\b(olumlu|olumsuz|lehte|aleyhte|eksik y[uü]kleme|fazla y[uü]kleme)\b' }).Count
  if($sayiN -le 1 -and $yonlu -lt 4 -and $dogruS){
    $uz=@($sikM | ForEach-Object { $_.Length } | Sort-Object)
    $medyan=[double]$uz[[int]($uz.Count/2)]
    if($medyan -gt 0 -and $dogruS.Length -eq $uz[-1] -and $dogruS.Length -ge 1.3*$medyan){
      $k.Add("KAPI-S dogru sik EN UZUN ve medyanin $([math]::Round($dogruS.Length/$medyan,2)) kati (esik 1,3) - uzunluk $($dogruS.Length), medyan $medyan; celdiricilerden en az biri dogrudan uzun olsun")
    }
    $par=@($sikM | Where-Object { $_ -match '\(' }).Count
    if($par -eq 1 -and $dogruS -match '\('){ $k.Add("KAPI-S parantezli aciklama yalniz dogru sikta") }
  }
  $brm=@($sikM | Where-Object { $_ -match '(₺|TL|%|adet|kg|saat)' }).Count
  if($sayiN -ge 2 -and $brm -eq 1 -and $dogruS -match '(₺|TL|%|adet|kg|saat)'){ $k.Add("KAPI-S birim yalniz dogru sikta") }
  # KAPI-K GERÇEK SÖZLÜK: -Ders verildiyse üreticinin kuralı birebir uygulanır (geniş sözlükte yok → kusur;
  # dar sözlükte yok VE gövdede >=2 kez → kusur). Üretici, dönen kelime sayısı >=2 ise soruyu DÜŞÜRÜR, 1 ise
  # yalnız rapora not düşer — bu ayrım burada da korunur, tek kelime KUSUR sayılmaz.
  if($kapiK){
    $eks=KapiKOlc -Metin "$($q.soru)" -Sozluk $kapiK
    $dk=@($eks.Keys | Sort-Object | ForEach-Object { "$_ ($($eks[$_]))" })
    if($eks.Keys.Count -ge 2){ $k.Add("KAPI-K DUSER ($($eks.Keys.Count) kelime pencere disi): $($dk -join ', ')") }
    elseif($eks.Keys.Count -eq 1){ $not.Add("KAPI-K notu (tek kelime, kapi dusurmez): $($dk -join ', ')") }
  }
  # -Ders yoksa eski (yaklaşık) yol: dışarıdan verilen tek sözlük dosyası
  elseif($sz.Keys.Count){ $say=@{}; $kel=@{}; foreach($w in ((Duz "$($q.soru)") -replace '[^a-z ]+',' ' -split '\s+')){ if($w.Length -lt 6){ continue }; $on=$w.Substring(0,5); if(-not $say.ContainsKey($on)){ $say[$on]=0; $kel[$on]=$w }; $say[$on]++ }
    $eksik=@(); $tekrar=@(); foreach($on in $say.Keys){ if(-not $sz.ContainsKey($on)){ if($say[$on] -ge 2){ $tekrar+=$kel[$on] } else { $eksik+=$kel[$on] } } }
    if($tekrar.Count){ $k.Add("KAPI-K DAR tekrarli (kusur): $($tekrar -join ', ')") }
    if($eksik.Count){ $k.Add("KAPI-K DAR disi tek (genis sozlukte olmali): $($eksik -join ', ')") } }
  # ASCII Türkçe
  $tum="$($q.soru) "+(@($harf | ForEach-Object { "$($q.siklar.$_)" }) -join ' ')+' '+(@($q.adimlar | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')
  $asc=@([regex]::Matches($tum.ToLowerInvariant(),'\b(icin|degil|isletme|donem|uretim|dogru|yanlis|ucret|hesabi|satis|yuzde|deger|iscilik|dagitim|kayit|kaydi|urun|uretilen|tutari|yapilan|icinde|once)\b') | ForEach-Object { $_.Value } | Select-Object -Unique); if($asc.Count){ $k.Add("ASCII Turkce: $($asc -join ',')") }
  $etiket=$(if($k.Count){ 'KUSUR' } else { 'ok' })
  if($etiket -eq 'ok'){ $temizSay++ }
  "{0,2}. {1,-36} {2}" -f $i,$q.konu,$etiket
  foreach($x in $k){ "      - $x" }
  foreach($x in $not){ "      . $x" }
}
# CEVAP DAGILIMI (10.09 eklendi) — DOSYA duzeyinde kapi, tek soruya bakarak gorulmez.
# NEDEN: Meslek Hukuku'nda zor 22/22 ve cok zor 21/21 sorunun dogru cevabi A cikti; "hep A" yazan
# ogrenci bankadan 100 alirdi. Her soru tek tek kusursuzdu, kusur DAGILIMDAYDI. Sayisal sikli
# sorular (MTA gibi) haric tutulur: orada siklar artan sirali oldugu icin cevabin yeri sayinin
# buyuklugune baglidir, yazarin tercihine degil.
$metinli=@($liste | Where-Object { $q2=$_; @('A','B','C','D','E' | Where-Object { "$($q2.siklar.$_)".Trim() -notmatch '^%?\s*-?\d{1,3}(?:\.\d{3})*(?:,\d+)?\s*(TL|%|adet|kg|saat|birim)?\s*$' }).Count -gt 0 })
if($metinli.Count -ge 5){
  $dag=@{}; foreach($h in @('A','B','C','D','E')){ $dag[$h]=0 }
  foreach($q2 in $metinli){ $d="$($q2.dogru)"; if($dag.ContainsKey($d)){ $dag[$d]++ } }
  $ozet=(@('A','B','C','D','E') | ForEach-Object { "$_`:$($dag[$_])" }) -join '  '
  $enCok=($dag.Values | Measure-Object -Maximum).Maximum
  $oran=[math]::Round($enCok/$metinli.Count,2)
  $bos=@(@('A','B','C','D','E') | Where-Object { $dag[$_] -eq 0 })
  ""
  "CEVAP DAGILIMI (metin sikli $($metinli.Count) soru): $ozet | en cok harf %$([math]::Round($oran*100))"
  if($oran -gt 0.40){ "  - KUSUR: tek harf sorularin %$([math]::Round($oran*100))'ini aliyor (tavan %40) - dogru cevaplari A-E arasinda dagit" }
  elseif($bos.Count -and $metinli.Count -ge 10){ "  - UYARI: hic kullanilmayan harf var ($($bos -join ', '))" }
  else{ "  - ok" }
}
"ozet: $temizSay/$($liste.Count) soru kusursuz"
