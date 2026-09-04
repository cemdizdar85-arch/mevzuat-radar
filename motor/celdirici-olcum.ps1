# ============================================================================
#  ÇELDİRİCİ KALIBI ÖLÇÜMÜ (04.09.2026, Cem "cevap belli, sınavda böyle mi?" → GM 2 "2 yap")
#
#  NE YAPAR: Ambardaki çıkmış kitapçıklardan ("CIKMIS SINAV - <Sınav> 20xx…", SORU N: / A)…E) yapılı) her sorunun
#  ŞIKLARINI ayıklar, derse atar (cikmis-ders-kalibi ile aynı anahtar-kelime sınıflandırıcı) ve ders bazında
#  ŞIK YAPISINI ölçer: şık tipi (sayı / sayı+yön / hesap-kayıt / cümle), sayı şıklarında tekil tutar sayısı ve
#  artan sıralama oranı, yön şıklarında "her tutar iki yönle" oranı, cümle şıklarında uzunluk dengesi
#  (en uzun / medyan). Her ders-tip için 2 gerçek örnek saklar → üretici isteme "ŞIK KALIBI" olarak girer.
#  ÇIKTI: veri/celdirici-kalibi-<sinav>.json (RaporYaz) + veri/CELDIRICI-KALIBI-<sinav>.md
#  KURAL: cevap anahtarı olmadan "doğru şık en uzun mu" ÖLÇÜLEMEZ → o hücre "ölçülmedi"; yalnız yapısal ölçüler.
# ============================================================================
param([string]$Sinav='SGS',[int]$KitapcikTavan=400)   # liste yabancı dil kitapçıklarını da içerir (ad süzgeciyle atılır); 80 yetmiyordu
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$KEY=$env:SUPABASE_SERVICE_KEY; if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$H=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
function Katla([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
$DERSLER=[ordered]@{
  'Finansal Muhasebe'   = @('yevmiye','muhasebe kayd','hesab[ıi]na','mizan','bilancoda yer','amortisman','reeskont','karsilik ayr','stok','alacak senedi','bono','police','kdv hesapla','doneme ait','tekduzen','aktiflestir','deger dusuklugu','hesap kalani','sermaye artir','kar dagitim')
  'Maliyet Muhasebesi'  = @('safha maliyet','siparis maliyet','esdeger urun','genel uretim gider','gug','standart maliyet','sapma','ortak maliyet','yan urun','direkt iscilik','direkt ilk madde','maliyet dagitim','birim maliyet')
  'Mali Tablolar Analizi'= @('oran analiz','cari oran','asit-test','likidite','devir hiz','kar marj','nakit akis','net calisma sermayesi','dikey yuzde','yatay analiz','kaldirac','ozkaynak karlilik','faaliyet kari oran')
  'Denetim'             = @('bds ','bagimsiz denet','denetci','denetim kanit','ornekleme','ic kontrol','onemli yanlislik','denetim riski','gorus','calisma kagit','teyit')
  'Ekonomi'             = @('arz egri','talep egri','piyasa denge','tekel','oligopol','esneklik','enflasyon','gsyh','issizlik','para politikasi','faiz oran','marjinal fayda','uretim imkan')
  'Maliye'              = @('kamu geliri','kamu harcama','butce','parafiskal','vergi yuku','transfer harcama','mali politika','laffer','vergi teori','operasyonel acik','borclanma')
  'Meslek Hukuku'       = @('3568','smmm','ymm','turmob','meslek mensub','oda','ruhsat','staj','disiplin','serbest muhasebeci')
  'Is ve Sosyal Guvenlik'= @('4857','is kanunu','is sozlesme','sendika','6356','5510','sosyal sigorta','kidem','ihbar','prim','isci')
  'Vergi Hukuku'        = @('213 sayili','vuk','3065','katma deger vergisi kanun','5520','kurumlar vergisi kanun','193','gelir vergisi kanun','damga vergisi','tarhiyat','vergi ziyai','uzlasma','beyanname ver')
  'Ticaret ve Borclar'  = @('6102','turk ticaret kanun','6098','turk borclar kanun','sirket tur','anonim sirket','limited sirket','ciro','kambiyo senet','sebepsiz zenginlesme','temsil','vekalet','haksiz fiil')
}
function DersBul([string]$govde){ $k=Katla $govde; $enIyi=''; $enPuan=0; foreach($d in $DERSLER.Keys){ $p=0; foreach($desen in $DERSLER[$d]){ if($k -match [regex]::Escape($desen)){ $p++ } }; if($p -gt $enPuan){ $enPuan=$p; $enIyi=$d } }; if($enPuan -lt 1){ return 'belirsiz' }; return $enIyi }
$YON='(?i)\b(olumlu|olumsuz|lehte|aleyhte|eksik yükleme|fazla yükleme|eksik yukleme|fazla yukleme)\b'
function Sayi([string]$s){ $m=[regex]::Match($s,'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?'); if(-not $m.Success){ return $null }; try{ return [double]::Parse($m.Value,[cultureinfo]::GetCultureInfo('tr-TR')) }catch{ return $null } }
function SikTip([string[]]$sik){
  $yon=@($sik | Where-Object { $_ -match $YON }).Count
  $sayi=@($sik | Where-Object { ($_ -replace '[\s₺TL%]|\bTL\b|\badet\b|\bkg\b|\bsaat\b','') -match '^[\d.,\-–]+$' -or $_ -match '^\s*[\d.,]+\s*(₺|TL|%|adet|kg|saat)?\s*$' }).Count
  $hesap=@($sik | Where-Object { $_ -match '(?<![\d.,])\d{3}(?![\d.,])' -and $_ -match '(?i)borç|alacak|hesab|hs\.' }).Count
  if($yon -ge 4){ return 'sayi+yon' }
  if($sayi -ge 4){ return 'sayi' }
  if($hesap -ge 3){ return 'hesap' }
  return 'cumle'
}
# --- KİTAPÇIKLAR --------------------------------------------------------------
$u1=$SB+'?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString("CIKMIS SINAV - $Sinav 20%")+"&limit=$KitapcikTavan&order=kaynak_ad.desc"
$adlar=@((Invoke-RestMethod -Uri $u1 -Headers $H -TimeoutSec 120) | ForEach-Object { "$($_.kaynak_ad)" } | Where-Object { $_ -and $_ -notmatch '(?i)yabanci dil|ingilizce|cevap' })
Write-Host "kitapçık: $($adlar.Count)"
$kayit=New-Object System.Collections.Generic.List[object]
foreach($ad in $adlar){
  try{ $m="$((Invoke-RestMethod -Uri ($SB+'?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ad)+'&limit=1') -Headers $H -TimeoutSec 120)[0].metin)" }catch{ Write-Host "  ATLA: $ad"; continue }
  if(-not $m){ continue }
  $parca=@([regex]::Split($m,'(?m)^SORU\s+(\d{1,3})\s*:\s*'))
  for($i=1;$i -lt $parca.Count-1;$i+=2){
    $b=$parca[$i+1]
    $sp=@([regex]::Split($b,'(?m)^\s{0,4}([A-E])\)\s*'))   # [govde, 'A', metinA, 'B', metinB, ...]
    if($sp.Count -lt 11){ continue }
    $govde=$sp[0].Trim(); $sik=@(); for($q=2;$q -lt $sp.Count;$q+=2){ $sik+=(($sp[$q] -split "`n")[0]).Trim() }
    $sik=@($sik | Select-Object -First 5); if(@($sik | Where-Object { $_ }).Count -lt 5){ continue }
    $tip=SikTip $sik; $ders=DersBul $govde
    $sayilar=@($sik | ForEach-Object { Sayi $_ } | Where-Object { $null -ne $_ })
    $tekil=@($sayilar | Select-Object -Unique).Count
    $artan=$false; if($sayilar.Count -ge 4){ $artan=$true; for($q=1;$q -lt $sayilar.Count;$q++){ if($sayilar[$q] -lt $sayilar[$q-1]){ $artan=$false; break } } }
    $ciftYon=0; if($tip -eq 'sayi+yon'){ $g=@{}; foreach($s in $sik){ $v=Sayi $s; if($null -eq $v){ continue }; $y=if($s -match '(?i)\b(olumlu|lehte|fazla)'){ '+' } else { '-' }; if(-not $g.ContainsKey($v)){ $g[$v]=@{} }; $g[$v][$y]=1 }; $ciftYon=@($g.Keys | Where-Object { $g[$_].Count -ge 2 }).Count }
    $uz=@($sik | ForEach-Object { $_.Length } | Sort-Object); $medyan=$uz[[int]($uz.Count/2)]; $oran=if($medyan -gt 0){ [math]::Round($uz[-1]/[double]$medyan,2) } else { 0 }
    $kayit.Add([pscustomobject]@{ kitapcik=$ad; ders=$ders; tip=$tip; sayiN=$sayilar.Count; tekil=$tekil; artan=$artan; ciftYon=$ciftYon; uzOran=$oran; sik=$sik; govde=$govde.Substring([math]::Max(0,$govde.Length-160)) })
  }
  Write-Host "  $ad -> toplam $($kayit.Count)"
}
# --- DERS BAZINDA KALIP -------------------------------------------------------
$dersler=[ordered]@{}
foreach($g in ($kayit | Where-Object { $_.ders -ne 'belirsiz' } | Group-Object ders | Sort-Object Count -Descending)){
  $n=$g.Count; if($n -lt 10){ continue }
  $tipler=[ordered]@{}; foreach($tg in ($g.Group | Group-Object tip | Sort-Object Count -Descending)){ $tipler[$tg.Name]=$tg.Count }
  $sayi=@($g.Group | Where-Object { $_.tip -eq 'sayi' }); $yon=@($g.Group | Where-Object { $_.tip -eq 'sayi+yon' }); $cum=@($g.Group | Where-Object { $_.tip -eq 'cumle' })
  $ornek=[ordered]@{}; foreach($t in @('sayi','sayi+yon','hesap','cumle')){ $o=@($g.Group | Where-Object { $_.tip -eq $t } | Select-Object -First 2 | ForEach-Object { [ordered]@{ kitapcik=$_.kitapcik; govde_sonu=$_.govde; siklar=$_.sik } }); if($o.Count){ $ornek[$t]=$o } }
  $dersler[$g.Name]=[ordered]@{
    soru=$n; tip=$tipler
    sayi_tekil_orani=$(if($sayi.Count){ [math]::Round((@($sayi | Where-Object { $_.tekil -eq $_.sayiN }).Count/[double]$sayi.Count),2) } else { $null })
    sayi_artan_orani=$(if($sayi.Count){ [math]::Round((@($sayi | Where-Object { $_.artan }).Count/[double]$sayi.Count),2) } else { $null })
    yon_cift_orani=$(if($yon.Count){ [math]::Round((@($yon | Where-Object { $_.ciftYon -ge 2 }).Count/[double]$yon.Count),2) } else { $null })
    cumle_uzunluk_orani_medyan=$(if($cum.Count){ $u=@($cum | ForEach-Object { $_.uzOran } | Sort-Object); $u[[int]($u.Count/2)] } else { $null })
    dogru_en_uzun_mu='ölçülmedi (cevap anahtarı yok)'
    ornek=$ornek
  }
}
$cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); sinav=$Sinav; kitapcik=$adlar.Count; soru=$kayit.Count; belirsiz=@($kayit | Where-Object { $_.ders -eq 'belirsiz' }).Count
  aciklama='Ders bazında ÇIKMIŞ şık yapısı. sayi_tekil_orani: sayı şıklarında beş tutarın hepsi farklı olan soru payı; sayi_artan_orani: küçükten büyüğe sıralı payı; yon_cift_orani: tutar+yön sorularında en az iki tutarın iki yönle göründüğü payı; cumle_uzunluk_orani_medyan: en uzun şık / medyan şık uzunluğu. Üretici kural 2a için ders örneklerini buradan okur.'
  dersler=$dersler }
$hedef=Join-Path $kok ("veri\celdirici-kalibi-"+$Sinav.ToLowerInvariant()+".json")
$null=RaporYaz -Hedef $hedef -Nesne $cikti -Derinlik 8
$md=New-Object System.Text.StringBuilder
[void]$md.AppendLine("# ÇELDİRİCİ KALIBI — $Sinav ($($cikti.olcum)) · $($adlar.Count) kitapçık · $($kayit.Count) soru")
[void]$md.AppendLine(""); [void]$md.AppendLine("| Ders | Soru | sayı | sayı+yön | hesap | cümle | sayı: hepsi farklı | sayı: artan sıralı | yön: çift tutar | cümle: en uzun/medyan |"); [void]$md.AppendLine("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
foreach($d in $dersler.Keys){ $x=$dersler[$d]; $t=$x.tip; [void]$md.AppendLine("| $d | $($x.soru) | $($t['sayi']) | $($t['sayi+yon']) | $($t['hesap']) | $($t['cumle']) | $($x.sayi_tekil_orani) | $($x.sayi_artan_orani) | $($x.yon_cift_orani) | $($x.cumle_uzunluk_orani_medyan) |") }
[void]$md.AppendLine(""); [void]$md.AppendLine("Doğru şık en uzun mu: ölçülmedi (kitapçıklarda cevap anahtarı yok).")
foreach($d in $dersler.Keys){ [void]$md.AppendLine(""); [void]$md.AppendLine("## $d — örnekler"); foreach($t in $dersler[$d].ornek.Keys){ foreach($o in $dersler[$d].ornek[$t]){ [void]$md.AppendLine("- **[$t]** $($o.kitapcik): …$(($o.govde_sonu -replace '\s+',' '))  "); [void]$md.AppendLine("  " + (($o.siklar | ForEach-Object { $_ }) -join ' · ')) } } }
[IO.File]::WriteAllText((Join-Path $kok ("veri\CELDIRICI-KALIBI-"+$Sinav.ToUpperInvariant()+".md")),$md.ToString(),[Text.UTF8Encoding]::new($false))
Write-Host ("çeldirici ölçümü: {0} kitapçık · {1} soru · {2} ders" -f $adlar.Count,$kayit.Count,$dersler.Count)
