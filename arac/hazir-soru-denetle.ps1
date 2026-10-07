# HAZIR SORU ÖN DENETİMİ (09.09.2026, GM t2b yazımı) — 0 USD, model çağrısı YOK.
# NE YAPAR: -HazirSoru ile basılacak GM yazımı soru dosyasını, üreticinin kod kapılarını taklit ederek ÖNCEDEN ölçer:
#   şık artan sıra · KokuKusur (onbinlik tutar, uzun tire) · uzunluk tavanı · KAPI-Ç çeldirici yolu (sonuç uyumu + üreticinin gerçek KAPI-Ç'si)
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
param([string]$Dosya='',[string]$Sozluk='',[string]$Ders='',[int]$Pencere=7,[int]$Tavan=0,[switch]$TavanSinavi,
      [string]$IkizEtiket='',[switch]$IkizYok,[switch]$KaynakYok,[switch]$IkizSinavi,[switch]$MulgaSinavi,[switch]$YilSinavi,[switch]$AdimSinavi,[switch]$KapiCSinavi,[switch]$SimSinavi,
      [string]$HarfPlani='',[switch]$HarfPlaniSinavi,[switch]$KapaliSinavi,
      [string]$KokDene='',[switch]$KokTazele,[switch]$KokDeneSinavi,[switch]$IkizOnbellekYok,[switch]$IkizOnbellekProva,[switch]$OnekSinavi,[switch]$KgkKapiSinavi)
$trS=[cultureinfo]::GetCultureInfo('tr-TR')
. (Join-Path (Split-Path -Parent $PSCommandPath) 'ozel-maliyet-kapisi.ps1')   # 27.09 KAPI-OM (üreticiyle aynı işlev; SGS oturumu izniyle eklendi)
# --- UZUNLUK TAVANI (25.09.2026, Cem "devam et" · SGS k2 ölçümü) ---------------------------------------------------------------
# NEDEN: bu betik sabit 746 kr ile ölçüyordu; bulut koşucusu (motor/kalip-kosucu.ps1 DersTavani) ise her satıra DERSİN tavanını verir:
#   plan satırında 'tavan' varsa o, yoksa veri/sinav-anatomisi-sgs.json C_ders_kalibi.<ders>.uzunluk.p90 (iki yönlü eşleşme), bulamazsa 350.
#   Ölçüldü: k2-2'de 'ok' denen 6 Denetim çok zor sorusunun 6'sı da bulutta "uzunluk > 342" ile ÜCRETSİZ kapıda düştü; 479 hazır soruda 47 aşım.
# Burada koşucunun kuralı birebir kopyalanır (SGS anatomisi; SMMM satırı bu betikle denetlenmiyor).
# 🚫 GÖRMEZ: plan satırındaki elle 'tavan' alanı (-Tavan ile verilir) · SMMM tavanları (veri/sinav-anatomisi-smmm.json).
function DersTavaniOlc([string]$dersRx,[string]$kokYol){
  $anY=Join-Path $kokYol 'veri\sinav-anatomisi-sgs.json'; if(-not $dersRx -or -not (Test-Path $anY)){ return 0 }
  $an=ConvertFrom-Json -InputObject (Get-Content $anY -Raw -Encoding UTF8)
  foreach($p in $an.C_ders_kalibi.PSObject.Properties){ if($dersRx -match [regex]::Escape($p.Name) -or $p.Name -match [regex]::Escape($dersRx)){ return [int]$p.Value.uzunluk.p90 } }
  return 350
}
$depoKokD=Split-Path -Parent $(if($PSScriptRoot){ $PSScriptRoot } else { (Get-Location).Path + '\arac' })
if($TavanSinavi){
  # Beklenenler anatomi dosyasından DEĞİL, koşucunun 25.09 bulut günlüğünde gördüğümüz sonuçtan: Denetim 342 (6/6 düştü, 373–573 kr),
  # Borçlar 630 (15 sorunun 15'i 258+ kr ile geçti), '^Maliye$' 393 (desen 'Maliye' adını İÇERİR), kısa 'Ataturk Ilke' 243 (ters yön eşleşmesi).
  $vakalar=@(@('Denetim',342),@('Borclar Hukuku|Ticaret ve Borclar',630),@('^Maliye$',393),@('Ataturk Ilke',243),@('Yabanci Dil',350))
  $hata=0; foreach($v in $vakalar){ $olc=DersTavaniOlc $v[0] $depoKokD; $iyi=($olc -eq $v[1]); if(-not $iyi){ $hata++ }; "  $(if($iyi){'TAMAM'}else{'HATA '}) '$($v[0])' -> $olc (beklenen $($v[1]))" }
  if($hata){ "TAVAN SINAVI KIRMIZI: $hata/$($vakalar.Count)"; exit 1 } else { "TAVAN SINAVI YESIL: $($vakalar.Count)/$($vakalar.Count)"; exit 0 }
}
# --- KAPI-B İKİZ + KAYNAK ADI (26.09.2026, SGS k4/k8 + SMMM gm2 ölçümü) --------------------------------------------------------
# NEDEN: bulutta 8 Türkçe (k4), 7 İngilizce (k8) ve 4 SMMM (gm2) hazır soru KAPI-B ile ÜCRETSİZ kapıda düştü; bu betik ve
#   yerel prova görmedi (prova etiketi 'prova-…' idi, ikiz havuzu etiketin ÖN EKİNDEN kurulur → havuz boştu).
# YÖNTEM: ikiz ölçüsü ELLE KOPYALANMAZ — motor/kalip-parti-uret.ps1'den GERÇEK fonksiyonlar AST ile alınır (BenzerlikKusur,
#   BenzerHavuz, KelimeKume, Jaccard, teori istisnası) + arac/ikiz-olcusu.ps1 (yayın cetveli, anlam ikizi) + arac/smmm-ders-adi.ps1.
#   Havuz = veri/fabrika/kalip-parti-<önek>-*.json (bulut indir_parti ile aynı dosyalar; yerelde önce
#   arac/parti-senkron.ps1 -Indir -Yaz -Sinav <SGS|SMMM> çalıştır — bayat havuz = kaçırma). Dosya içi ikiz: önceki sorular '$don'a eklenir.
# KAYNAK ADI: kaynak_adlar'daki her ad ambarda (dokumanlar.kaynak_ad) BİREBİR yoksa paket boş kalır, hakem soruyu atlar → KUSUR.
# 🚫 GÖRMEZ: çapa (çıkmış soru) benzerliği ($CAPA boş — pencere çapası üretimde kurulur) · kendi etiketinin partisi (üretici de hariç tutar).
function IkizFonkYukle([string]$kokY){
  $uy=[IO.Path]::Combine($kokY,'motor','kalip-parti-uret.ps1'); $tk=$null; $hk=$null   # .NET yolu: Linux'ta '\' ayraç değildir (dogrula.yml pwsh/ubuntu)
  $ast=[System.Management.Automation.Language.Parser]::ParseFile($uy,[ref]$tk,[ref]$hk)
  $gerek=@('Katla2','KelimeKume','Jaccard','SoruTeoriMi','SikKume','KokMaddeNo','TeoriFarkliMi','BenzerHavuz','BenzerlikKusur','KokuKusur','AciklamaDuz')
  $bul=@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true) | Where-Object { $gerek -contains $_.Name })
  $eksikF=@($gerek | Where-Object { $ad=$_; -not ($bul | Where-Object { $_.Name -eq $ad }) })
  if($eksikF.Count){ throw "İKİZ: üreticide fonksiyon bulunamadı: $($eksikF -join ', ')" }
  return $bul
}
# 05.10.2026 İKİZ HAVUZ ÖNBELLEĞİ (Cem "1.2.3" GM3): ölçüldü — tam denetim 157 sn, bunun 136 sn'si ikiz; her koşu 1.140 parti
#   dosyasını baştan ayrıştırıyordu. Önbellek yalnız HAM alanları saklar (soru, şıklar, doğru metin, ders, kaynak); küme/madde/şık kümesi
#   yüklenirken ÜRETİCİNİN AYNI işlevleriyle (KelimeKume, SikKume, KokMaddeNo) yeniden hesaplanır. İz = dosya sayısı + en yeni yazım + toplam
#   boy; iz değişince yeniden kurulur. -IkizOnbellekYok eski yol.
#   🚫 GÖRMEZ: üreticinin BenzerHavuz satırına yeni alan eklenirse (kayıt alanları burada da elle eklenmeli; -IkizOnbellekProva alan
#   listesini üreticinin satırıyla karşılaştırır) · aynı saniyede aynı boyla değişen dosya.
function IkizHavuzSatir($hEt,$id,$v){
  $sk=[pscustomobject]@{ siklar=[pscustomobject]@{ A="$($v.siklar.A)"; B="$($v.siklar.B)"; C="$($v.siklar.C)"; D="$($v.siklar.D)"; E="$($v.siklar.E)" } }
  if("$env:DENETLE_IKIZONB_MUTASYON" -eq 'sikyok'){ $sk=[pscustomobject]@{ siklar=[pscustomobject]@{} } }
  return [pscustomobject]@{ etiket=$hEt; id=$id; konu="$($v.konu)"; soru="$($v.soru)"; siklar=$sk.siklar; ders=$(if($Sinav -eq 'SMMM'){ SmmmDersAdi $hEt $v } else { '' }); dogruMetin=(IkizDogruMetin $v); kaynak=@($v.kaynak_adlar) }
}
function IkizHavuzOnbellek([string]$onekH){
  $fab=Join-Path $kok 'veri\fabrika'; $fs=@(Get-ChildItem $fab -Filter "kalip-parti-$onekH-*.json" -ErrorAction SilentlyContinue)
  $iz="$($fs.Count)|$(@($fs | ForEach-Object { $_.LastWriteTimeUtc.Ticks } | Measure-Object -Maximum).Maximum)|$(@($fs | Measure-Object Length -Sum).Sum)"
  $yol=Join-Path $fab "ikiz-havuz-$onekH.json"; $satir=$null; $kaynakAd='önbellek'
  if(Test-Path $yol){ try{ $c=Get-Content -Raw -Encoding UTF8 $yol | ConvertFrom-Json; if("$($c.iz)" -eq $iz){ $satir=@($c.satir) } }catch{} }
  if($null -eq $satir){ $kaynakAd='yeniden kuruldu'; $l=New-Object System.Collections.Generic.List[object]
    foreach($f in $fs){ try{ $j=ConvertFrom-Json -InputObject (Get-Content $f.FullName -Raw -Encoding UTF8); $hEt=($f.BaseName -replace '^kalip-parti-','')
        foreach($p in $j.PSObject.Properties){ if($p.Value -and $p.Value.soru){ $l.Add((IkizHavuzSatir $hEt $p.Name $p.Value)) } } }catch{} }
    $satir=$l.ToArray(); [IO.File]::WriteAllText($yol,([pscustomobject]@{ iz=$iz; satir=$satir } | ConvertTo-Json -Depth 6 -Compress),(New-Object Text.UTF8Encoding $false)) }
  $h=New-Object System.Collections.Generic.List[object]
  foreach($r in $satir){ if("$($r.etiket)" -eq $Etiket){ continue }
    $h.Add([pscustomobject]@{ etiket="$($r.etiket)"; id="$($r.id)"; konu="$($r.konu)"; kume=(KelimeKume "$($r.soru)"); sikKume=(SikKume ([pscustomobject]@{ siklar=$r.siklar })); madde=(KokMaddeNo "$($r.soru)");
      ders="$($r.ders)"; soruMetin="$($r.soru)"; dogruMetin="$($r.dogruMetin)"; parmak=$null; kaynak=@($r.kaynak); ai=$null; si=$null }) }
  return [pscustomobject]@{ havuz=$h; kaynak=$kaynakAd; dosya=$fs.Count }
}
if($IkizSinavi){
  # Sentetik havuz (CI'da ambar yok): geçici kökte bir SGS partisi kurulur; GERÇEK BenzerlikKusur koşar.
  $gk=Join-Path ([IO.Path]::GetTempPath()) ("ikiz-sinav-" + [guid]::NewGuid().ToString('N')); $gkFab=[IO.Path]::Combine($gk,'veri','fabrika'); New-Item -ItemType Directory -Force $gkFab | Out-Null
  $havuzSoru='Aşağıdaki cümlelerin hangisinde yazım yanlışı yapılmıştır? Toplantıya herkes zamanında geldi fakat müdür biraz geç kaldı.'
  $havuzJ=@{ 'kp-01'=@{ soru=$havuzSoru; konu='yazim kurallari'; siklar=@{A='a';B='b';C='c';D='d';E='e'}; dogru='A' } } | ConvertTo-Json -Depth 5
  [IO.File]::WriteAllText([IO.Path]::Combine($gkFab,'kalip-parti-sgs-eski-turkce-zor.json'),$havuzJ,[Text.UTF8Encoding]::new($false))
  foreach($fn in (IkizFonkYukle $depoKokD)){ . ([scriptblock]::Create($fn.Extent.Text)) }
  . ([IO.Path]::Combine($depoKokD,'arac','ikiz-olcusu.ps1')); . ([IO.Path]::Combine($depoKokD,'arac','smmm-ders-adi.ps1'))
  $kok=$gk; $Sinav='SGS'; $Etiket='sgs-yeni-turkce-zor'; $CAPA=@{}; $amb=$null; $script:GK_DERS=$true; $script:BENZER_HAVUZ=$null
  $v=@(
    @('havuzdaki soruyla birebir aynı kök -> YAKALA', $havuzSoru, @{}, $true),
    @('tamamen farklı kök -> GEÇ', 'Muhasebe bürosunun yıllık raporunda geçen sözcüklerden hangisinin yazımı doğrudur ve neden öyledir?', @{}, $false),
    @('dosya içi kardeş aynı kök -> YAKALA', 'Kargo şirketinin müşteri kayıtlarında yer alan cümlelerden hangisinde soru eki yanlış yazılmıştır?', @{ 'hz-0'=[pscustomobject]@{ soru='Kargo şirketinin müşteri kayıtlarında yer alan cümlelerden hangisinde soru eki yanlış yazılmıştır?'; konu='x' } }, $true)
  )
  $hata=0
  foreach($vk in $v){ $don=$vk[2]; $a=[pscustomobject]@{ soru=$vk[1]; konu='yazim kurallari'; siklar=[pscustomobject]@{A='a';B='b';C='c';D='d';E='e'}; dogru='A' }
    $sonuc=@(BenzerlikKusur $a 'hz-9'); $yak=[bool]$sonuc.Count; $iyi=($yak -eq $vk[3]); if(-not $iyi){ $hata++ }
    "  $(if($iyi){'TAMAM'}else{'HATA '}) $($vk[0]) -> $(if($yak){'yakalandı: ' + $sonuc[0]}else{'geçti'})" }
  Remove-Item -Recurse -Force $gk -ErrorAction SilentlyContinue
  if($hata){ "İKİZ SINAVI KIRMIZI: $hata/$($v.Count)"; exit 1 } else { "İKİZ SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
# 29.09 KAPI-MM (Cem "1.2.3 üçünü de yap"): kaynak_adlar'da ambarda BÜTÜNÜYLE mülga/iptal madde → KUSUR.
#   Liste veri/sinav/ambar-mulga-maddeler.json (arac/ambar-mulga-madde.js). Motor aynı listeyle paketten atar; ön denetim yazarı uyarır.
#   🚫 GÖRMEZ: fıkra düzeyi iptal · listede olmayan (ambar metninde iptali yazmayan) madde · soru gövdesinde anılan mülga kanun (KAPI-M).
function MulgaListeYukle([string]$kok){ $s=New-Object 'System.Collections.Generic.HashSet[string]'; $y=[IO.Path]::Combine($kok,'veri','sinav','ambar-mulga-maddeler.json')
  if(Test-Path $y){ foreach($m in @(([IO.File]::ReadAllText($y,[Text.Encoding]::UTF8) | ConvertFrom-Json).maddeler)){ if($m.kaynak_ad){ [void]$s.Add("$($m.kaynak_ad)") } } }; return ,$s }
function MulgaMaddeKusur($q,$set){ $o=@(); foreach($ad in @($q.kaynak_adlar)){ if("$ad".Trim() -and $set.Contains("$ad")){ $o+="$ad" } }; return $o }
$MULGA_SET=MulgaListeYukle $depoKokD
if($MulgaSinavi){
  $hata=0; $v=@(
    @('mülga madde kaynak adında -> YAKALA', @('VUK (213 s.K.) m.270 - Gayrimaddi haklar. Gayrimenkullerde maliyet bedeline giren giderler','VUK (213 s.K.) m.269'), $true),
    @('yürürlükteki komşu madde -> GEÇ', @('VUK (213 s.K.) m.269','VUK (213 s.K.) m.262'), $false),
    @('kaynak_adlar boş -> GEÇ', @(), $false))
  if($MULGA_SET.Count -lt 1){ "MÜLGA SINAVI KIRMIZI: liste yüklenemedi/boş (veri/sinav/ambar-mulga-maddeler.json) — kapı KÖR"; exit 1 }
  foreach($vk in $v){ $yak=[bool]@(MulgaMaddeKusur ([pscustomobject]@{ kaynak_adlar=$vk[1] }) $MULGA_SET).Count; $iyi=($yak -eq $vk[2]); if(-not $iyi){ $hata++ }
    "  $(if($iyi){'TAMAM'}else{'HATA '}) $($vk[0]) -> $(if($yak){'yakalandı'}else{'geçti'})" }
  if($hata){ "MÜLGA SINAVI KIRMIZI: $hata/$($v.Count) (liste $($MULGA_SET.Count) madde)"; exit 1 } else { "MÜLGA SINAVI YESIL: $($v.Count)/$($v.Count) (liste $($MULGA_SET.Count) madde)"; exit 0 }
}
# 05.10.2026 KAPI-Y yıl ölçüsü (üretici motor/kalip-parti-uret.ps1 FAZ A satırıyla AYNI desen). Mutasyon: $env:DENETLE_YIL_MUTASYON = sayili | enkucuk
function YilKusurOlc([string]$soru,[int]$yilBu){
  $desen=$(if("$env:DENETLE_YIL_MUTASYON" -eq 'sayili'){ '\b(20[0-3]\d)\b' } else { '\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))' })
  $yl=@([regex]::Matches("$soru",$desen) | ForEach-Object { [int]$_.Groups[1].Value }); if(-not $yl.Count){ return '' }
  $en=$(if("$env:DENETLE_YIL_MUTASYON" -eq 'enkucuk'){ ($yl | Measure-Object -Minimum).Minimum } else { ($yl | Measure-Object -Maximum).Maximum })
  if($en -lt $yilBu){ return "sorudaki en yeni yil $en, bugun $yilBu" }; return ''
}
# 05.10.2026 B25: hazır soruda adım + sade (yazar yazar). Mutasyon: $env:DENETLE_ADIM_MUTASYON = adim | sade
function AdimSadeEksik($q){
  $o=@()
  if("$env:DENETLE_ADIM_MUTASYON" -ne 'adim' -and -not ($q.PSObject.Properties['adimlar'] -and @($q.adimlar).Count -ge 2)){ $o+="ADIM YOK: 'adimlar' (en az 2 adım: 1. adım 'Verilen') yazar tarafından yazılır (sözleşme B25)" }
  if("$env:DENETLE_ADIM_MUTASYON" -ne 'sade' -and -not ($q.PSObject.Properties['sade'] -and $q.sade -and "$($q.sade.dogru)".Trim() -and $q.sade.siklar)){ $o+="SADE YOK: 'sade' {dogru, sinav, siklar} yazar tarafından yazılır (sözleşme B25)" }
  return $o
}
function KaliteTek($q){
  $js=Join-Path $depoKokD 'arac\soru-kalite-kapisi.js'; if(-not (Test-Path $js) -or -not (Get-Command node -ErrorAction SilentlyContinue)){ return @('NOT-KALITE KÖR: node ya da arac/soru-kalite-kapisi.js yok') }
  $tmp=[IO.Path]::Combine([IO.Path]::GetTempPath(),"hazir-kalite-$([guid]::NewGuid().ToString('N')).json")
  [IO.File]::WriteAllText($tmp,(ConvertTo-Json -InputObject $q -Depth 12),(New-Object Text.UTF8Encoding($false)))
  try{ $o=@(& node $js --tek $tmp 2>&1 | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
  return $o
}
# 05.10.2026 GERÇEK KAPI-Ç (gm8 ölçümü: GMSİ'nin 3 hazır sorusu bulutta KAPI-Ç "yanlış yol çözülemedi" ile düştü — yollar "… ve …" ile
#   zincirlenmişti; bu betiğin KAPI-Ç taklidi görmedi). KOPYA YOK: CeldiriciYolKapisi + SayiCozC üreticiden AST ile alınır.
#   Mutasyon: $env:DENETLE_KAPIC_MUTASYON=kapali → işlev boş döner (öz-sınav KIRMIZI düşmeli).
$script:KAPIC_YUKLU=$false
function GercekKapiC($q){
  if("$env:DENETLE_KAPIC_MUTASYON" -eq 'kapali'){ return @() }
  if(-not $script:KAPIC_YUKLU){
    $uy=[IO.Path]::Combine($depoKokD,'motor','kalip-parti-uret.ps1'); $tk=$null; $hk=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseFile($uy,[ref]$tk,[ref]$hk)
    $bul=@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true) | Where-Object { @('CeldiriciYolKapisi','SayiCozC') -contains $_.Name })
    if($bul.Count -lt 2){ return @('KAPI-Ç KÖR: üreticide CeldiriciYolKapisi/SayiCozC bulunamadı') }
    foreach($f in $bul){ . ([scriptblock]::Create($f.Extent.Text)); Set-Item -Path ("function:script:"+$f.Name) -Value (Get-Item ("function:"+$f.Name)).ScriptBlock }
    $script:KAPIC_YUKLU=$true
  }
  return @(CeldiriciYolKapisi $q)
}
# 05.10.2026 TERS SADE (uyarı): olumsuz kökte ("hangisi yanlıştır") doğru OLMAYAN şıkkın sade metni "doğru seç/cevap/işaretle" diyorsa öğrenci
#   ters okur (onarım okuyucusu buldu). Banka ölçümü (05.10): olumsuz kökü 1.509 soruda 6 aday, bir kısmı meşru ("doğru seçilse de") → DURDURMAZ.
function TersSadeNot($q){
  if("$env:DENETLE_TERS_MUTASYON" -eq 'kapali'){ return @() }
  if("$($q.soru)" -notmatch '(?i)yanlıştır|değildir|söylenemez|yer almaz|bulunmaz'){ return @() }
  $s=$(if($q.PSObject.Properties['sade'] -and $q.sade -and $q.sade.siklar){ $q.sade.siklar } else { $null }); if(-not $s){ return @() }
  $o=@(); foreach($h in 'A','B','C','D','E'){ if($h -eq "$($q.dogru)"){ continue }; if("$($s.$h)" -match '(?i)do[gğ]ru(yu)?\s*(se[cç]|i[sş]aretle|cevap)'){ $o+="TERS SADE: olumsuz kökte $h şıkkının sade metni 'doğru seç/cevap' diyor" } }
  return $o
}
# ⭐ 07.10.2026 KGK KAPILARI (KGK oturumu, Cem "eksik kuralları yapalım" K4–K6). Yalnız kgk- etiketinde koşar ($KGK_SERT); SGS/SMMM
#   çıktısı birebir aynı kalır (o kollar isterse açar — not iletildi). Üçü de 0 USD, model çağrısı yok.
# K4 HARF ANMA: açıklama/teşhis/sade/adım/çeldirici/hap metninde şık HARFİ anılıyor ("C şıkkı", "Cevap B", "A)"). Seviye testi ve şık
#   kaydırma (arac/sik-kaydir.ps1) şıkların yerini değiştirir → metin yanlış harfi gösterir. Ölçüldü 07.10: yerel KGK hazır dosyalarında
#   814 sorunun 808'i adımlarda harf anıyor ("Cevap B şıkkıdır."); yeterlilikte 393 soru (279 sitede). Desen sik-kaydir.ps1 HARF_ANAN_DESEN
#   ile aynı + "(A) Bey" kişi adı istisnası. Mutasyon: $env:DENETLE_KGK_MUTASYON=harf.
# K5 SORUDA VERİLEN (sözleşme B24 S7, kapısı yoktu): "X (soruda verilen)" etiketli sayı kökte yoksa uydurmadır. Mutasyon: =verilen.
# K6 FIKRA ATFI (sözleşme B24 S6, kanunlar için kapısı yoktu): "m.X/Y" atfında X maddesi sorunun kaynak_adlar'ındaysa ambar metninde
#   "(Y)" fıkrası aranır; madde numaralı fıkralıysa ((1) var) ve (Y) yoksa KUSUR. Mutasyon: =fikra.
#   🚫 GÖRMEZ: kaynak_adlar'da olmayan madde (ölçülmedi notu) · fıkrası numarasız eski kanun · bent harfi · standart paragrafı (BDS → KAPI-BP).
# 07.10 (sinav kolu SMMM banka ölçümü: 2.225 harf bulgusunun 1.324'ü adım ŞABLON alanından — adimlar[].sik='A'): tek harflik değer
#   (alan anahtarı gibi duran "A") metin değildir, ölçülmez.
function KgkMetinler($q){ $o=@(); foreach($alan in 'aciklama','teshis','sade','adimlar','celdirici_yol','hap','sinav_taktigi'){ if($q.PSObject.Properties[$alan]){ foreach($t in @(MetinTopla $q.$alan)){ if("$t".Trim() -match '^[A-E]$'){ continue }; $o+=,@($alan,"$t") } } }; return $o }
# 07.10.2026 SMMM BAĞI (sinav kolu ölçümü): K4/K5/K6 bitirme (smmm-) etiketinde de koşar. Etiket: -IkizEtiket smmm-…/kgk-… ya da dosya adı
#   hazir-kgk-… · hazir-gmN-… (→ smmm-gmN-…) · hazir-smmm-…. SGS'de değişen yok. Durdurma: KGK'da üçü KUSUR; SMMM'de kip satırı (ölçüm).
#   Mutasyon: $env:DENETLE_KGK_MUTASYON=smmm → SMMM bağı kapanır (öz-sınav "bağ: smmm" vakaları düşer).
#   🚫 GÖRMEZ: etiketsiz/başka adlı SMMM dosyası (hazir-<başka>.json, -IkizEtiket verilmemiş) — kapılar koşmaz, söylenmez.
function Kgk3Etiket([string]$ikizEt,[string]$dosyaY){ $b=[IO.Path]::GetFileNameWithoutExtension("$dosyaY")
  if($ikizEt){ if($ikizEt -match '^(kgk|smmm)-'){ return $ikizEt }; return '' }
  if($b -match '^hazir-(kgk-.*)$'){ return $Matches[1] }; if($b -match '^hazir-(gm\d+-.*)$'){ return 'smmm-' + $Matches[1] }; if($b -match '^hazir-(smmm-.*)$'){ return $Matches[1] }; return '' }
function Kgk3Acik([string]$et){ if($et -match '^kgk-'){ return $true }; if("$env:DENETLE_KGK_MUTASYON" -ne 'smmm' -and $et -match '^smmm-'){ return $true }; return $false }
function HarfAnmaKusur($q){
  if("$env:DENETLE_KGK_MUTASYON" -eq 'harf'){ return @() }
  # 07.10 düzeltme (KGK ambar envanteri, 584 cümle): formül '(t x B)' ve 'p.98C)' yanlış alarmdı; 'doğrusu B' ve '→ B' kaçıyordu.
  $d='(?<![A-Za-zÇĞİÖŞÜçğıöşü0-9(])[A-E]\s*(şıkk|şık\b|seçene)|(?<![A-Za-zÇĞİÖŞÜçğıöşü0-9(+*×/=-])(?<![x×*+/=-]\s)[A-E]\)(?=\s)|(şıkk?ı?|seçenek)\s*[A-E]\b|[Cc]evap\s*[A-E]\b|[Dd]o[gğ]rusu\s*:?\s*[A-E]\b|→\s*[A-E](?![A-Za-zÇĞİÖŞÜçğıöşü0-9.])'
  # 07.10 ÇIPLAK HARF (KGK ambar onarımında ölçüldü: 770 sorunun 404'ünde "A ve D düşer", "B söyler →" gibi kalıpsız gönderme vardı, kalıp
  #   deseni görmüyordu): tırnak içi şık metni ve "Ek A" atılınca tek başına duran A–E. Harf KÖKTE de tek başına geçiyorsa (formül değişkeni:
  #   VL = VU + D) sayılmaz.
  $cd='(?<![A-Za-zÇĞİÖŞÜçğıöşü0-9(./+*×=-])([A-E])(?![A-Za-zÇĞİÖŞÜçğıöşü0-9)]|\.[A-ZÇĞİÖŞÜ])'
  $kokHarf=@{}; foreach($km in [regex]::Matches("$($q.soru)",$cd)){ $kokHarf[$km.Groups[1].Value]=1 }
  $out=@(); $gor=@{}
  foreach($p in @(KgkMetinler $q)){ if($gor.ContainsKey($p[0])){ continue }; $m=[regex]::Match($p[1],$d)
    if(-not $m.Success -and "$env:DENETLE_KGK_MUTASYON" -ne 'ciplak'){ $tz=($p[1] -replace '“[^”]*”','' -replace '\bEk [A-E]\b',''); foreach($cm in [regex]::Matches($tz,$cd)){ if(-not $kokHarf.ContainsKey($cm.Groups[1].Value)){ $m=[regex]::Match($p[1],[regex]::Escape($tz.Substring([Math]::Max(0,$cm.Index-10),[Math]::Min(12,$tz.Length-[Math]::Max(0,$cm.Index-10))))); if(-not $m.Success){ $m=[regex]::Match($p[1],'.') }; break } } }
    if($m.Success){ $gor[$p[0]]=1; $s=[Math]::Max(0,$m.Index-30); $out+="HARF ANMA ($($p[0])): '…$($p[1].Substring($s,[Math]::Min(70,$p[1].Length-$s)))…' — şık yer değiştirir; harf değil İÇERİK an ('bildirimi kaldıran seçenek')" } }
  return $out
}
# 07.10 (sinav kolu ölçümü, 311 bulgunun 1 yanlış alarmı): "35,1800" ↔ "35,18" — virgülden sonraki SONDAKİ sıfırlar atılır; tarih
#   parçası ("31.12.2025" kökte, "2025 (soruda verilen)" açıklamada) için kökteki sayının nokta/eğik çizgi parçaları da kümeye girer.
function SayiKatla([string]$s){ $t = ("$s" -replace '[.\s]',''); if($t -match ','){ $t = ($t -replace '0+$','') -replace ',$','' }; return $t }
function SorudaVerilenKusur($q){
  if("$env:DENETLE_KGK_MUTASYON" -eq 'verilen'){ return @() }
  $kok=@{}; foreach($m in [regex]::Matches("$($q.soru)",'\d[\d.,/]*')){ $v=$m.Value.TrimEnd('.',',','/'); $kok[(SayiKatla $v)]=1; if($v -match '[./]'){ foreach($pr in ($v -split '[./]')){ if($pr){ $kok[(SayiKatla $pr)]=1 } } }
    # 07.10 (KGK FY yazarı): kökte "%12" → adımda "0,12 (soruda verilen)" aynı değerdir (yüzde ↔ ondalık); yüzdenin ondalık karşılığı da kümeye girer
    if("$($q.soru)".Substring(0,$m.Index) -match '%\s*$'){ $dv=0.0; if([double]::TryParse(((SayiKatla $v) -replace ',','.'),[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$dv)){ $kok[(SayiKatla (($dv/100).ToString([Globalization.CultureInfo]::InvariantCulture) -replace '\.',','))]=1 } } }
  $out=@(); $gor=@{}
  foreach($p in @(KgkMetinler $q)){
    foreach($m in [regex]::Matches($p[1],'(?<s>\d[\d.,]*)\s*(?:TL|%|gün|ay|yıl|adet)?\s*\(soruda verilen\)')){
      $s=SayiKatla ($m.Groups['s'].Value.TrimEnd('.',',')); if($gor.ContainsKey($s)){ continue }; $gor[$s]=1
      if(-not $kok.ContainsKey($s)){ $out+="SORUDA VERİLEN ($($p[0])): '$($m.Value)' — bu sayı kökte YOK (S7: '(soruda verilen)' yalnız kökte harfiyen geçen değere)" } } }
  return $out
}
function FikraAtifKusur($q,$metinler){
  if("$env:DENETLE_KGK_MUTASYON" -eq 'fikra'){ return @() }
  $out=@(); $gor=@{}
  foreach($p in @(KgkMetinler $q)){
    foreach($m in [regex]::Matches($p[1],'(?<on>.{0,40}?)\bm\.\s*(?<m>\d+(?:/[A-Z])?)\s*/\s*(?<f>\d+)\b')){
      $md=$m.Groups['m'].Value; $f=$m.Groups['f'].Value; $on=$m.Groups['on'].Value
      $esl=@($metinler.Keys | Where-Object { $_ -match ('\bm\.' + [regex]::Escape($md) + '(\s|$)') })
      $no=[regex]::Match($on,'\b(\d{3,4})\b'); if($no.Success -and $esl.Count){ $dar=@($esl | Where-Object { $_ -match ('\(' + $no.Groups[1].Value + ' s\.') }); if($dar.Count){ $esl=$dar } }
      $kanunlar=@($esl | ForEach-Object { ($_ -replace '\s*\bm\.\d.*$','').Trim() } | Sort-Object -Unique)
      $an="$($kanunlar -join '|')|$md|$f"; if($gor.ContainsKey($an)){ continue }; $gor[$an]=1
      if($kanunlar.Count -ne 1){ continue }   # madde kaynak_adlar'da yok ya da iki kanunda aynı numara → ölçülmez
      $govde=($esl | Sort-Object | ForEach-Object { $metinler[$_] }) -join ' '
      # 07.10 (sinav kolu ölçümü: 55 fıkra bulgusunun 19'u yanlış alarm — GVK m.40, İYUK m.28, BKK m.1, 5510 m.3'te metnin İÇİNDE "(1)" bent
      #   numarası geçiyordu, "m.X/Y" bent atfıydı): madde numaralı fıkralı sayılır YALNIZ "MADDE X –" başlığının hemen ardından "(1)" geliyorsa
      #   (araya değişiklik künyesi "(Değişik: …)" girebilir).
      $fikrali = $govde -match '(?i)madde\s+\d+(?:/[A-ZÇĞİÖŞÜ])?\s*[–—‐-]\s*(?:\([^)]{0,80}\)\s*)*\(\s*1\s*\)'
      if($fikrali -and $govde -notmatch ('\(\s*' + $f + '\s*\)')){ $out+="FIKRA ATFI ($($p[0])): 'm.$md/$f' — $($kanunlar[0]) m.$md metninde ($f) fıkrası YOK (S6: numara kaynak metinden okunur)" } } }
  return $out
}
# 05.10.2026 SİMÜLASYON ÖN KONTROLÜ (gm8: VUK'un 3 teori sorusu bulutta öğrenci simülasyonunda kaldı). Üretici cozum_tablo görünce soruyu
#   HESAP sorusu sayar (FAZ Ö teoriMi = tablo yok ∧ yevmiye değil), sayısal ikiz kurar; doğru şık CÜMLE ise simüle öğrenci tek sayı veremez
#   ("U" ≠ "(U)'nun 2019 faturaları") ya da sim hiç koşmaz. Kural: doğru şıkkı cümle olan soruda cozum_tablo olmaz (talimat F.2).
#   Cümle ölçütü üreticinin KAPI-Ç'sindeki ile aynı: şıkta ≥4 harfli kelime. Mutasyon: $env:DENETLE_SIM_MUTASYON=kapali.
#   🚫 GÖRMEZ: hesap sorusunda ikizin kurulup kurulamayacağı (model fazı) · simüle öğrencinin anlatımı yetersiz bulması.
function SimOnKontrol($q){
  if("$env:DENETLE_SIM_MUTASYON" -eq 'kapali'){ return @() }
  $tbl=($q.PSObject.Properties['cozum_tablo'] -and $q.cozum_tablo -and @($q.cozum_tablo.satirlar).Count -ge 1)
  if(-not $tbl){ return @() }
  $ds="$($q.siklar.("$($q.dogru)".Trim().ToUpperInvariant()))"
  # 05.10 gerçek vaka (gm8 VUK çok zor, doğru 'I ve III'): öncüllü cevap da teoridir; 4 harf ölçütü onu kaçırıyordu
  if($ds -match '[A-Za-zÇĞİÖŞÜçğıöşü]{4,}' -or $ds.Trim() -match '^(I{1,3}|IV|V)(\s*(,|ve|ile)\s*(I{1,3}|IV|V))*\s*$'){ return @("SIM: doğru şık cümle (teori sorusu) ama cozum_tablo var — üretici sayısal ikiz kurar, öğrenci simülasyonu çalışmaz; tabloyu kaldır, doldur/verilen [] (talimat F.2)") }
  return @()
}
# 05.10.2026 HARF PLANI (Cem "1.2.3" GM3): gm8'de doğru şık yığıldı (kolay dosya B %80, çok zor C %60); sonradan düzeltmek çeldiricileri
#   yeniden kurdurdu (bir yazar + bir okuyucu turu daha). Plan yazımdan ÖNCE verilir: konu i, zorluk j → 'ABCDE'[(i + 2j) mod 5].
#   Her zorluk dosyasında harf sayıları en çok 1 farklı (5+ konuda hiçbir harf %40'ı aşmaz), her konunun 3 sorusu üç ayrı harf.
#   GÖRMEZ: dosyada önceden duran (yeniden yazılmayan) soruların harfleri; plan yalnız yeni yazılan konular içindir.
function HarfPlani([int]$K,[int]$Z=3){
  $L='ABCDE'; $mut="$env:DENETLE_HARF_MUTASYON"
  $p=@(); for($i=0;$i -lt $K;$i++){ $s=@(); for($j=0;$j -lt $Z;$j++){ $s+=$(if($mut -eq 'sabit'){ 'C' } elseif($mut -eq 'tek'){ "$($L[$i % 5])" } else { "$($L[($i + 2*$j) % 5])" }) }; $p+=,$s }
  return ,$p
}
# 05.10.2026 KAPALI LİSTE NOTU (Cem "1.2.3" GM3): gm8 GMSİ çok zorda "yalnız cezalar düşülmez" / "m.74/4'e göre indirilemeyen para cezaları
#   ve vergi cezalarıdır" — kanun listeyi kapatmıyor, aynı soruda istisnaya düşen gider payı da indirilmiyordu; yalnız ikinci göz yakaladı.
#   Açıklama/teşhis/sade/adımlarda kalıbı arar, YALNIZ NOT yazar (durdurmaz). GÖRMEZ: "sadece", "bir tek", olumlu kapalı liste
#   ("indirilecek giderler şunlardır"), şık ve kök metni (kökte meşru). "kabul edilmeyen" (KKEG terimi) ve "düzeye indirilemez" bilerek dışarıda (05.10: 5.212 hazır soruda 12 notun 9'u bu ikisiydi).
function MetinTopla($o){ if($null -eq $o){ return @() }; if($o -is [string]){ return @($o) }
  if($o -is [System.Collections.IEnumerable]){ $r=@(); foreach($x in $o){ $r+=@(MetinTopla $x) }; return $r }
  if($o -is [pscustomobject]){ $r=@(); foreach($p in $o.PSObject.Properties){ $r+=@(MetinTopla $p.Value) }; return $r }; return @() }
function KapaliListeNot($q){
  if("$env:DENETLE_KAPALI_MUTASYON" -eq 'kapali'){ return @() }
  $out=@()
  foreach($alan in 'aciklama','teshis','sade','adimlar'){ if(-not $q.PSObject.Properties[$alan]){ continue }
    foreach($t in @(MetinTopla $q.$alan)){
      $m=[regex]::Match("$t",'(?i)\byaln[ıi]z(ca)?\b[^.;:]{0,60}?\b(d[üu][şs][üu]lmez|(?<!d[üu]zeye )indirilemez|kabul edilmez|say[ıi]lmaz|gider yaz[ıi]lamaz)')
      if(-not $m.Success){ $m=[regex]::Match("$t",'(?i)\b(indirilemeyen|d[üu][şs][üu]lemeyen)\b[^.;:]{0,80}?\S+[dt][ıiuü]r\b') }
      if($m.Success){ $out+="KAPALI LİSTE ($alan): '$($m.Value)' — kanun listeyi kapatıyor mu? kapatmıyorsa 'X ise indirilemez' yaz (not, durdurmaz)"; break } } }
  return $out
}
# 05.10.2026 ÖNEK ALINTI NOTU (Cem "1.2.3" GM2): talimat E6 ("m.X:" önekli cümle kanunla BİREBİR, değilse "m.X gereği") yazılıydı; gm9'da
#   beş yazarın dördü çiğnedi, 66 cümle elle düzeltildi. Önekten sonraki cümle (ilk '.'/';'ye kadar) sorunun kaynak_adlar'ındaki o maddenin
#   ambar metninde (Türkçe harf katlanmış, noktalama atılmış) geçmiyorsa NOT düşer; soruyu durdurmaz (yanlış alarm oranı henüz ölçülüyor).
#   🚫 GÖRMEZ: kesik ama birebir alıntı (alıntının devamı atılmışsa önek parçası yine metinde geçer) · tebliğ/BKK önekleri · kaynak_adlar'da
#   o madde yoksa (ÖLÇÜLMEDİ notu) · kanun kısaltması listede değilse.
function OnekKatla([string]$s){ return ((("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant() -replace '[^a-z0-9]+',' ').Trim()) }
function OnekAlintiNot($q,$metinler){
  if("$env:DENETLE_ONEK_MUTASYON" -eq 'kapali'){ return @() }
  $out=@(); $gor=@{}
  foreach($alan in 'teshis','aciklama','adimlar','sade'){ if(-not $q.PSObject.Properties[$alan]){ continue }
    foreach($t in @(MetinTopla $q.$alan)){
      foreach($m in [regex]::Matches("$t",'\b(?<k>GVK|VUK|KDVK|KVK|ÖTVK|TTK|TBK|TMK|SPKn|İYUK|AATUHK|HMK|DVK|MK)\s*(?:\([^)]{0,20}\)\s*)?m\.\s*(?<m>\d+(?:/[A-Za-z])?)(?<g>[^:.;]{0,30}):\s*(?<a>(?:[^.;]|\.(?=\d)){12,})')){
        $gp=$m.Groups['g'].Value; if($gp -match '\+|Seri|Tebli|BKK|CBK' -or ($gp.Contains(')') -and -not $gp.Contains('('))){ continue }   # dayanak listesi ("m.103 + GVGT …): hesap") alıntı değil
        $kan=$m.Groups['k'].Value; $md=$m.Groups['m'].Value; $al=$m.Groups['a'].Value.Trim(); $anah="$kan|$md|$al"; if($gor.ContainsKey($anah)){ continue }; $gor[$anah]=1
        $esl=@($metinler.Keys | Where-Object { $_ -match ('^' + [regex]::Escape($kan) + '\b.*\bm\.' + [regex]::Escape($md) + '(\b|$)') })
        if(-not $esl.Count){ $out+="ÖNEK ALINTI ölçülmedi ($alan): '$kan m.${md}:' — kaynak_adlar'da bu madde yok"; continue }
        $govde=OnekKatla (($esl | ForEach-Object { $metinler[$_] }) -join ' ')
        if(-not $govde.Contains((OnekKatla $al))){ $kisa=$(if($al.Length -gt 70){ $al.Substring(0,70) + '…' } else { $al }); $out+="ÖNEK ALINTI ($alan): '$kan m.${md}: $kisa' ambar metninde birebir yok → 'm.$md gereği …' yaz (not, durdurmaz)" } } } }
  return $out
}
if($OnekSinavi){
  $mt=@{ 'GVK (193 s.K.) m.74 - Giderler [1/3]'='Kiraya verilen mal ve haklar için ödenen vergi, resim, harç ve şerefiyeler indirilir.' }
  $v=@(@('birebir alıntı',[pscustomobject]@{ aciklama=[pscustomobject]@{ B='GVK m.74: Kiraya verilen mal ve haklar için ödenen vergi, resim, harç ve şerefiyeler indirilir.' } },0),
       @('çıkarım önekle',[pscustomobject]@{ teshis=[pscustomobject]@{ B=[pscustomobject]@{ gercek='GVK m.74/1-5: emlak vergisi gider yazılır ve 18.375 TL indirilir.' } } },1),
       @('gereği biçimi',[pscustomobject]@{ aciklama=[pscustomobject]@{ B='GVK m.74 gereği emlak vergisi gider yazılır ve 18.375 TL indirilir.' } },0),
       @('kaynakta madde yok',[pscustomobject]@{ aciklama=[pscustomobject]@{ B='VUK m.10: kanuni temsilci sorumludur ve ödevi vardır.' } },1))
  $h=0; foreach($x in $v){ $c=@(OnekAlintiNot $x[1] $mt).Count; if($c -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $c (beklenen $($x[2]))" } }
  if($h){ "ONEK ALINTI SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "ONEK ALINTI SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($KapaliSinavi){
  $v=@(@('gm8 sade: yalnız cezalar düşülmez',[pscustomobject]@{ sade=[pscustomobject]@{ siklar=[pscustomobject]@{ B='vergi gider olarak düşülür, yalnız cezalar düşülmez.' } } },1),
       @('gm8 açıklama: indirilemeyen ... cezalarıdır',[pscustomobject]@{ aciklama=[pscustomobject]@{ B="m.74/4'e göre indirilemeyen para cezaları ve vergi cezalarıdır." } },1),
       @('düzeltilmiş: X ise indirilemez',[pscustomobject]@{ aciklama=[pscustomobject]@{ B="para cezaları ve vergi cezaları ise m.74/4'e göre hasılattan gider olarak indirilemez." } },0),
       @('yalnız olumlu (yasaksız)',[pscustomobject]@{ aciklama='Yalnız gerçek kişiler bu beyannameyi verir.' },0),
       @('kökte kalıp aranmaz',[pscustomobject]@{ soru='Aşağıdakilerden hangisi yalnız cezalar düşülmez ilkesine aykırıdır?' },0))
  $h=0; foreach($x in $v){ $c=@(KapaliListeNot $x[1]).Count; if($c -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $c (beklenen $($x[2]))" } }
  if($h){ "KAPALI LISTE SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KAPALI LISTE SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($KgkKapiSinavi){
  $mt=@{ 'Sermaye Piyasası K. (6362 s.K.) m.35'='MADDE 35 – (1) Bu Kanuna göre faaliyette bulunabilecek kurumlar: a) Yatırım kuruluşları. (2) Kurul düzenler.'; 'Bankacılık K. (5411 s.K.) m.24 [1/2]'='Denetim komitesi Madde 24 — Bankaların denetim komitesi kurması zorunludur.' }
  $v=@(
    @('harf: "Cevap B şıkkıdır."',(@(HarfAnmaKusur ([pscustomobject]@{ adimlar=@([pscustomobject]@{ anlatim='Cevap B şıkkıdır.' }) })).Count),1),
    @('harf: "E şıkkı bu yüzden düşer"',(@(HarfAnmaKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ E='E şıkkı bu yüzden düşer.' } })).Count),1),
    @('harf: içerikle anma geçer',(@(HarfAnmaKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ E='Bildirimi kaldıran seçenek p.14''e aykırıdır.' } })).Count),0),
    @('harf: "(A) Bey" kişi adı geçer',(@(HarfAnmaKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='(A) Bey denetçidir; BDS 701 p.13(b) uygulanır.' } })).Count),0),
    @('harf: formül (t x B), (VU+D) ve p.98C) geçer',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Borç D ise?'; aciklama=[pscustomobject]@{ E='VL = VU + (t x B) formülünde vergi kalkanı eklenir; (VU, D, VU+D) sırası; p.98C) istisnası ayrıdır.' } })).Count),0),
    @('harf: "Doğrusu: B." yakalanır, "Doğrusu: Ağırlıklar" geçer',(@(HarfAnmaKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='Tuzak. Doğrusu: B.'; C='Doğrusu: Ağırlıklar toplamı birdir.' } })).Count),1),
    @('harf: → doğrusu B yakalanır',(@(HarfAnmaKusur ([pscustomobject]@{ adimlar=@([pscustomobject]@{ anlatim='En sık hata (HATALI) → doğrusu B: açıklama yeterlidir.' }) })).Count),1),
    @('harf: yalnız B''de → B yakalanır',(@(HarfAnmaKusur ([pscustomobject]@{ adimlar=@([pscustomobject]@{ formul='görüş yalnız B''de → B' }) })).Count),1),
    @('harf: çıplak "A ve D düşer" yakalanır',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Hangisi doğrudur?'; adimlar=@([pscustomobject]@{ anlatim='A ve D raporun başka bölümüne aittir, düşer.' }) })).Count),1),
    @('harf: kökte değişken D (formül) geçer',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Borç tutarı D = 2.000.000 TL ise VL kaçtır?'; adimlar=@([pscustomobject]@{ formul='VL = VU + t x D' }) })).Count),0),
    @('harf: tırnaklı şık metnindeki A geçer',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Hangisi?'; adimlar=@([pscustomobject]@{ anlatim='Doğru cevap: “Ek A ve plan A uygulanır”.' }) })).Count),0),
    @('harf: kökte harf aranmaz',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Aşağıdakilerden hangisi A) şıkkına benzer?' })).Count),0),
    @('verilen: kökte olmayan sayı',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Önemlilik 400.000 TL olarak belirlenmiştir.'; adimlar=@([pscustomobject]@{ formul='Verilen: 500.000 TL (soruda verilen)' }) })).Count),1),
    @('verilen: kökte geçen sayı',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Önemlilik 400.000 TL olarak belirlenmiştir.'; adimlar=@([pscustomobject]@{ formul='Verilen: 400.000 TL (soruda verilen)' }) })).Count),0),
    @('fıkra: m.35/3 yok',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='SPKn m.35/3 gereği kurul düzenler.' } }) $mt).Count),1),
    @('fıkra: m.35/2 var',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='6362 sayılı Kanun m.35/2 gereği Kurul düzenler.' } }) $mt).Count),0),
    @('fıkra: metin içi "(1)" bent numarası → fıkralı sayılmaz (GVK m.40 vakası)',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='GVK m.40/5 gereği gider indirilir.' } }) @{ 'Gelir Vergisi K. (193 s.K.) m.40 [1/2]'='Safi kazancın tespiti için aşağıdaki giderler indirilir: 1. (1) numaralı bentte sayılan genel giderler; 5. Amortismanlar.' }).Count),0),
    @('fıkra: künyeli "MADDE 35 – (Değişik: …) (1)" fıkralı sayılır',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='SPKn m.35/4 gereği.' } }) @{ 'Sermaye Piyasası K. (6362 s.K.) m.35'='MADDE 35 – (Değişik: 1/1/2020-7000/1 md.) (1) Kurumlar şunlardır. (2) Kurul düzenler.' }).Count),1),
    @('verilen: "35,1800" kökte "35,18"',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Kur 35,18 TL olarak verilmiştir.'; adimlar=@([pscustomobject]@{ formul='Verilen: 35,1800 TL (soruda verilen)' }) })).Count),0),
    @('verilen: kökte %12, adımda 0,12 (yüzde↔ondalık)',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Faiz oranı yıllık %12, vade 3 yıldır.'; adimlar=@([pscustomobject]@{ formul='Verilen: 0,12 (soruda verilen); 3 yıl (soruda verilen)' }) })).Count),0),
    @('verilen: kökte %12, adımda 0,15 → yakalanır',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Faiz oranı yıllık %12, vade 3 yıldır.'; adimlar=@([pscustomobject]@{ formul='Verilen: 0,15 (soruda verilen)' }) })).Count),1),
    @('verilen: tarih parçası "2025" kökte 31.12.2025',(@(SorudaVerilenKusur ([pscustomobject]@{ soru='Raporlama dönemi 31.12.2025 tarihinde sona ermiştir.'; adimlar=@([pscustomobject]@{ formul='Verilen: 2025 (soruda verilen)' }) })).Count),0),
    @('harf: adım şablon alanı sik=A ölçülmez',(@(HarfAnmaKusur ([pscustomobject]@{ soru='Hangisi?'; adimlar=@([pscustomobject]@{ sik='A'; anlatim='Doğru cevap: görüş vermekten kaçınma.' }) })).Count),0),
    @('fıkra: numarasız madde ölçülmez',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='Bankacılık K. m.24/2 gereği komite kurulur.' } }) $mt).Count),0),
    @('fıkra: kaynak_adlar''da olmayan madde ölçülmez',(@(FikraAtifKusur ([pscustomobject]@{ aciklama=[pscustomobject]@{ A='TTK m.397/4 gereği denetçi seçilir.' } }) $mt).Count),0),
    @('bağ: smmm hazir-gm dosyası açık',[int](Kgk3Acik (Kgk3Etiket '' 'veri\fabrika\hazir-gm9-1-yvergi-zor.json')),1),
    @('bağ: smmm hazir-smmm dosyası açık',[int](Kgk3Acik (Kgk3Etiket '' 'veri\fabrika\hazir-smmm-gm-p1-yfta.json')),1),
    @('bağ: smmm -IkizEtiket açık',[int](Kgk3Acik (Kgk3Etiket 'smmm-gm5-1-fmuh-zor' 'x.json')),1),
    @('bağ: kgk dosyası açık',[int](Kgk3Acik (Kgk3Etiket '' 'veri\fabrika\hazir-kgk-gm-tms-r1.json')),1),
    @('bağ: sgs dosyası kapalı',[int](Kgk3Acik (Kgk3Etiket '' 'veri\fabrika\hazir-denetim-zor-1.json')),0),
    @('bağ: sgs -IkizEtiket kapalı (dosya adı gm olsa da)',[int](Kgk3Acik (Kgk3Etiket 'sgs-k10-yd-kolay' 'hazir-gm9-1-yvergi-zor.json')),0))
  $h=0; foreach($x in $v){ if($x[1] -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $($x[1]) (beklenen $($x[2]))" } }
  if($h){ "KGK KAPI SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KGK KAPI SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
# 05.10.2026 KÖK DENEME (Cem "1.2.3" GM3): yazar kökü yazarken bitirme KAPI-K'yı saniyede sınar. Sözlük önbellekten
#   (arac/kapi-k-sozluk.ps1 KapiKSmmmSozlukOnbellek, 12 saat), ölçüm denetimin aynı KapiKOlc'u. Tam denetimin yerine GEÇMEZ.
#   Kullanım: -KokDene "<metin>" ya da -KokDene <hazır dosya.json> · -IkizEtiket smmm-<etiket> (ders buradan) · -KokTazele
if($KokDeneSinavi){
  . (Join-Path $depoKokD 'arac\kapi-k-sozluk.ps1')
  $sz=[pscustomobject]@{ genis=@{ kitap=1; muhas=1; vergi=1; beyan=1; faali=1 }; dar=@{ kitap=1; vergi=1 }; aralik=@('smmm-x'); blok=1; kaynak='sinav' }
  $gy=Join-Path ([IO.Path]::GetTempPath()) "kokdene-sinav-$PID.json"; KapiKSozlukYaz $sz $gy; $oku=KapiKSozlukOku $gy; Remove-Item $gy -ErrorAction SilentlyContinue
  $v=@('vergi beyanname kitapta','muhasebe muhasebe faaliyet faaliyetleri','zemberek kelimesi geçiyor','beyanname tek kez')
  $h=0; foreach($t in $v){ $a=(@((KapiKOlc $t $sz).GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) | Sort-Object) -join ','; $b=(@((KapiKOlc $t $oku).GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) | Sort-Object) -join ','; if($a -ne $b){ $h++; "  DUSTU: '$t' -> taze [$a] / onbellek [$b]" } }
  if($h){ "KOK DENEME SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KOK DENEME SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($KokDene){
  . (Join-Path $depoKokD 'arac\kapi-k-sozluk.ps1'); . (Join-Path $depoKokD 'arac\smmm-ders-adi.ps1')
  $etKD=$(if($IkizEtiket){ $IkizEtiket } elseif($KokDene -match 'hazir-(gm\d+-[^\\/]*?)(-p\d+)?\.json$'){ 'smmm-' + $Matches[1] } else { '' })
  $dersKD=$(if($etKD){ SmmmDersAdi $etKD $null } else { $null }); if(-not $dersKD){ throw '-KokDene: ders çözülemedi; -IkizEtiket smmm-<etiket> ver' }
  $szKD=KapiKSmmmSozlukOnbellek -DersRegex $dersKD -Tazele:$KokTazele; if(-not $szKD){ "KOK DENEME: sözlük kurulamadı ($dersKD) - OLCULMEDI"; exit 2 }
  "KOK DENEME: $dersKD · sözlük $($szKD.kaynak) · genis $($szKD.genis.Keys.Count) dar $(if($szKD.dar){ $szKD.dar.Keys.Count } else { 'yok' })"
  $kokler=$(if($KokDene -like '*.json' -and (Test-Path $KokDene)){ $kj=Get-Content -Raw -Encoding UTF8 $KokDene | ConvertFrom-Json; @($kj) | ForEach-Object { [pscustomobject]@{ ad="$($_.konu)"; metin="$($_.soru)" } } } else { ,[pscustomobject]@{ ad='metin'; metin=$KokDene } })
  foreach($kk in @($kokler)){ $e=KapiKOlc $kk.metin $szKD; $d=@($e.Keys | Sort-Object | ForEach-Object { "$_ ($($e[$_]))" }); $sonuc=$(if($e.Keys.Count -ge 2){ 'DUSER' } elseif($e.Keys.Count -eq 1){ 'not' } else { 'ok' }); "  $sonuc · $($kk.ad) · $($d -join ', ')" }
  exit 0
}
if($HarfPlani){
  if($HarfPlani -match '^\d+$'){ $kon=@(1..[int]$HarfPlani | ForEach-Object { "konu $_" }) } else { $konJ=Get-Content -Raw -Encoding UTF8 $HarfPlani | ConvertFrom-Json; $kon=@($konJ) }
  $p=HarfPlani $kon.Count; $zad=@('kolay','zor','cokzor')
  "HARF PLANI ($($kon.Count) konu) — yazar doğru şıkkı bu harfe koyar, çeldiricileri buna göre büyük/küçük kurar:"
  for($i=0;$i -lt $kon.Count;$i++){ "  $($kon[$i]) → kolay $($p[$i][0]) · zor $($p[$i][1]) · cokzor $($p[$i][2])" }
  for($j=0;$j -lt 3;$j++){ $c=@($p | ForEach-Object { $_[$j] } | Group-Object | ForEach-Object { "$($_.Name)$($_.Count)" }); "  $($zad[$j]) dosyası: $($c -join ' ')" }
  exit 0
}
if($HarfPlaniSinavi){
  $h=0; $n=0
  foreach($K in 1..12){ $p=HarfPlani $K; $tav=[math]::Ceiling($K/5)
    for($j=0;$j -lt 3;$j++){ $n++; $mx=(@($p | ForEach-Object { $_[$j] }) | Group-Object | Measure-Object Count -Maximum).Maximum; if($mx -gt $tav){ $h++; "  DUSTU: K=$K zorluk $j en çok $mx > $tav" } }
    for($i=0;$i -lt $K;$i++){ $n++; if(@($p[$i] | Select-Object -Unique).Count -ne 3){ $h++; "  DUSTU: K=$K konu $i harfleri ayrı değil ($($p[$i] -join ''))" } } }
  if($h){ "HARF PLANI SINAVI KIRMIZI: $h/$n"; exit 1 } else { "HARF PLANI SINAVI YESIL: $n/$n"; exit 0 }
}
if($SimSinavi){
  $tb=[pscustomobject]@{ basliklar=@('a','b'); satirlar=@(@('x','1')) }
  $teoriTablo=[pscustomobject]@{ dogru='B'; siklar=[pscustomobject]@{ A='Alıcı düzenler'; B='Satıcı düzenler'; C='c'; D='d'; E='e' }; cozum_tablo=$tb }
  $teoriTablosuz=[pscustomobject]@{ dogru='B'; siklar=$teoriTablo.siklar }
  $hesapTablo=[pscustomobject]@{ dogru='B'; siklar=[pscustomobject]@{ A='100'; B='120'; C='150'; D='200'; E='300' }; cozum_tablo=$tb }
  $v=@(@('teori + tablo → bulgu',@(SimOnKontrol $teoriTablo).Count,1),@('teori tablosuz → yok',@(SimOnKontrol $teoriTablosuz).Count,0),@('hesap + tablo → yok',@(SimOnKontrol $hesapTablo).Count,0),@('öncüllü teori (I ve III) + tablo → bulgu',@(SimOnKontrol ([pscustomobject]@{ dogru='C'; siklar=[pscustomobject]@{ A='Yalnız I'; B='I ve II'; C='I ve III'; D='II ve III'; E='I, II ve III' }; cozum_tablo=$tb })).Count,1))
  $h=0; foreach($x in $v){ if($x[1] -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $($x[1]) (beklenen $($x[2]))" } }
  if($h){ "SIM ON KONTROL SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "SIM ON KONTROL SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($KapiCSinavi){
  # vaka: ';' ile zincir → üretici çözer (KUSUR yok) · '… ve …' zinciri → "çözülemedi" (gm8 GMSİ sınıfı) · ters sade uyarısı
  $tb=[pscustomobject]@{ basliklar=@('Kalem','Tutar'); satirlar=@(@('a','100'),@('b','200')) }
  $sk=[pscustomobject]@{ A='80'; B='120'; C='150'; D='200'; E='300' }
  $iyi=[pscustomobject]@{ soru='x'; dogru='C'; siklar=$sk; cozum_tablo=$tb; celdirici_yol=[pscustomobject]@{ A='100 - 20 = 80'; B='100 + 20 = 120'; D='100 x 2 = 200'; E='100 + 200 = 300' } }
  $kotu=[pscustomobject]@{ soru='x'; dogru='C'; siklar=$sk; cozum_tablo=$tb; celdirici_yol=[pscustomobject]@{ A='100 - 20 = 80 ve 80 x %10 = 8 (yanlış)'; B='100 + 20 = 120'; D='100 x 2 = 200'; E='100 + 200 = 300' } }
  $ters=[pscustomobject]@{ soru='Aşağıdakilerden hangisi yanlıştır?'; dogru='E'; sade=[pscustomobject]@{ siklar=[pscustomobject]@{ A='Bu ifade kaynakla uyumlu, doğru seçersin'; B='x'; C='x'; D='x'; E='x' } } }
  $v=@(@('noktalı virgül zinciri çözülür → bulgu yok',@(GercekKapiC $iyi).Count,0),@("'ve' zinciri çözülemez → bulgu",[int](@(GercekKapiC $kotu).Count -ge 1),1),@('olumsuz kökte ters sade → uyarı',@(TersSadeNot $ters).Count,1),@('olumlu kökte ters sade aranmaz',@(TersSadeNot ([pscustomobject]@{ soru='Hangisi doğrudur?'; dogru='E'; sade=$ters.sade })).Count,0))
  # 07.10 KGK ölçümü: yüzde ayrıştırma ("%3" → 0.3 okunuyordu, doğru yol düşüyordu). B şıkkının yolu sınanır, öteki şıklar düz.
  # Mutasyon: $env:KAPIC_MUTASYON='eski-yuzde' (üreticide eski iki geçişli sıra) → %3, %3,5, parantez vakaları KIRMIZI.
  $yuzdeQ={ param($yol,$sik) [pscustomobject]@{ soru='x'; dogru='A'; siklar=[pscustomobject]@{ A='1'; B=$sik; C='2'; D='3'; E='4' }; cozum_tablo=$tb; celdirici_yol=[pscustomobject]@{ B=$yol; C='1 + 1 = 2'; D='1 + 2 = 3'; E='2 + 2 = 4' } } }
  foreach($yv in @(@('1.000.000 x %3 = 30.000','30.000',0),@('1.000.000 x %3,5 = 35.000','35.000',0),@('1.000.000 x %15 = 150.000','150.000',0),
                   @('1.000.000 x %30 = 300.000','300.000',0),@('1.000.000 x 0,03 = 30.000','30.000',0),@('(1.000.000 - 200.000) x %3 = 24.000','24.000',0),
                   @('1.000.000 x %3 = 40.000 (yanlış alarm değil: gerçekten tutmuyor)','40.000',1),@('(1.000.000 - 200.000) x %3 = 30.000','30.000',1))){
    $v+=,@("yüzde: $($yv[0]) → $($yv[2]) bulgu",@(GercekKapiC (& $yuzdeQ $yv[0] $yv[1])).Count,$yv[2])
  }
  $h=0; foreach($x in $v){ if($x[1] -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $($x[1]) (beklenen $($x[2]))" } }
  if($h){ "KAPI-C/TERS SADE SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KAPI-C/TERS SADE SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($AdimSinavi){
  $tam=[pscustomobject]@{ adimlar=@([pscustomobject]@{formul='Verilen: a'},[pscustomobject]@{formul='b = 1'}); sade=[pscustomobject]@{ dogru='x'; siklar=[pscustomobject]@{A='a'} } }
  $adimsiz=[pscustomobject]@{ sade=$tam.sade }; $tekAdim=[pscustomobject]@{ adimlar=@([pscustomobject]@{formul='x'}); sade=$tam.sade }
  $sadesiz=[pscustomobject]@{ adimlar=$tam.adimlar }; $bosSade=[pscustomobject]@{ adimlar=$tam.adimlar; sade=[pscustomobject]@{ dogru=' '; siklar=$null } }
  $v=@(@('tam (adım+sade)',$tam,0),@('adım yok',$adimsiz,1),@('tek adım',$tekAdim,1),@('sade yok',$sadesiz,1),@('sade boş',$bosSade,1),@('ikisi yok',[pscustomobject]@{soru='x'},2))
  $h=0; foreach($x in $v){ $c=@(AdimSadeEksik $x[1]).Count; if($c -ne $x[2]){ $h++; "  DUSTU: $($x[0]) -> $c bulgu (beklenen $($x[2]))" } }
  if($h){ "ADIM/SADE SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "ADIM/SADE SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
if($YilSinavi){
  # gm6 gerçek vaka sınıfı: "2025 yılı gelirleri" (KUSUR) · aynı soru "2026 yılı Mart ayında verilecek beyanname" ile (ok) · kanun no sayılmaz
  $v=@(@('2025 yılı gelirleri için yıllık beyan','KUSUR'),@('2025 yılı gelirleri için 2026 yılı Mart ayında verilecek beyanname','ok'),@('2025 gelirleri, beyan 2026''da','ok'),@('6183 ve 2004 sayılı Kanun hükümlerine göre','ok'),@('5520 s. Kanun ve 2004 s. Kanun','ok'),@('yıl geçmeyen soru','ok'),@('2024 ve 2025 yılları','KUSUR'))
  $h=0; foreach($x in $v){ $c=$(if(YilKusurOlc $x[0] 2026){ 'KUSUR' } else { 'ok' }); if($c -ne $x[1]){ $h++; "  DUSTU: '$($x[0])' -> $c (beklenen $($x[1]))" } }
  if($h){ "KAPI-Y SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KAPI-Y SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}if(-not $Dosya){ throw '-Dosya zorunlu (ya da -TavanSinavi / -IkizSinavi / -MulgaSinavi / -YilSinavi / -AdimSinavi / -KapiCSinavi / -SimSinavi)' }
$UZ_TAVAN=$(if($Tavan -gt 0){ $Tavan } elseif($Ders){ DersTavaniOlc $Ders $depoKokD } else { 746 })
function Duz([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'â','a' -creplace 'î','i' -creplace 'û','u').ToLowerInvariant() }
function Sayi([string]$t){ $m=[regex]::Match("$t",'-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?'); if($m.Success){ try{ return [double]::Parse($m.Value,$trS) }catch{ return $null } }; return $null }
function Hesapla([string]$ifade){ $t=$ifade -replace '\.','' -replace ',','.' -replace 'x','*'; if($t -notmatch '^[\d\.\s\*/+\-]+$'){ return $null }; try{ return [double](Invoke-Expression $t) }catch{ return $null } }
$sz=@{}; if($Sozluk -and (Test-Path $Sozluk)){ foreach($w in ((Get-Content $Sozluk -Raw -Encoding UTF8) -split '\s+')){ $w=Duz $w; if($w.Length -ge 5){ $sz[$w.Substring(0,5)]=1 } } }
$kapiK=$null
# 25.09: üretici Yabancı Dil modunda KAPI-K'yı KAPATIR (motor/kalip-parti-uret.ps1 YD_MOD: "KAPI-K kapalı"); ön denetim kapatmıyordu ve
#   YD yazarları report/meeting/credit gibi temel kelimeleri sınav dışı sanıp soruyu fakirleştiriyordu (K3 w3: 6 soru yalnız bu yüzden düştü).
#   Aynı desen üreticiyle birebir: 'Yabanci Dil|Yabancı Dil|Ingilizce|İngilizce'.
$YABANCI_DIL_DENETIMI=[bool]($Ders -and $Ders -match 'Yabanci Dil|Yabancı Dil|Ingilizce|İngilizce')
if($YABANCI_DIL_DENETIMI){ "YABANCI DİL: KAPI-K ve soru/şıkta ASCII-Türkçe kontrolü üreticide kapalı olduğu için burada da ölçülmez" }
elseif($Ders){
  $kutup=Join-Path $(if($PSScriptRoot){ $PSScriptRoot } else { '.' }) 'kapi-k-sozluk.ps1'
  if(Test-Path $kutup){ . $kutup; $kapiK=KapiKSozlukKur -DersRegex $Ders -Pencere $Pencere }
  if(-not $kapiK){ "UYARI: KAPI-K sozlugu kurulamadi (ambar/anahtar/analiz dosyasi) - bu kapi OLCULMEDI" }
}
# 05.10.2026 BİTİRME KAPI-K (gm6 ölçüm koşusu: 15 hazır sorunun 9'u bulutta KAPI-K ile düştü, bu betik 'ok' demişti — SMMM yolu yoktu).
#   Etiket (ya da dosya adı) smmm- ile başlıyor ve -Ders verilmemişse sözlük üreticinin SMMM yolundan kurulur (arac/kapi-k-sozluk.ps1 KapiKSmmmSozlukKur).
if(-not $YABANCI_DIL_DENETIMI -and -not $Ders){
  $etK=$(if($IkizEtiket){ $IkizEtiket } elseif([IO.Path]::GetFileNameWithoutExtension($Dosya) -match '^hazir-(gm\d+-.*)$'){ 'smmm-' + $Matches[1] } else { '' })   # yalnız bitirme GM dosyası
  if($etK -match '^smmm-'){
    . (Join-Path $depoKokD 'arac\smmm-ders-adi.ps1'); $dersK=SmmmDersAdi $etK $null
    $kutup=Join-Path $(if($PSScriptRoot){ $PSScriptRoot } else { '.' }) 'kapi-k-sozluk.ps1'
    if($dersK -and (Test-Path $kutup)){ . $kutup; $kapiK=KapiKSmmmSozlukKur -DersRegex $dersK }
    if(-not $kapiK){ "UYARI: bitirme KAPI-K sozlugu kurulamadi ($etK) - bu kapi OLCULMEDI" } else { "BITIRME KAPI-K: ders $dersK" }
  }
}
$liste=Get-Content $Dosya -Raw -Encoding UTF8 | ConvertFrom-Json
# B25 sertliği: bitirme (smmm-) etiketinde ADIM/SADE YOK kusurdur; öteki sınavlarda uyarı (o kolların kararı)
$GM_ET=$(if($IkizEtiket){ $IkizEtiket } elseif([IO.Path]::GetFileNameWithoutExtension($Dosya) -match '^hazir-(gm\d+-.*)$'){ 'smmm-' + $Matches[1] } else { '' })   # bitirme GM dosyası hazir-gmN-…
$GM_SERT=[bool]($GM_ET -match '^smmm-')
# 07.10.2026 KGK SERTLİĞİ (KGK oturumu, Cem K2): kgk- etiketinde (-IkizEtiket kgk-… ya da dosya hazir-kgk-….json) B25 ADIM/SADE YOK ve SIM
#   ön kontrolü KUSUR (bitirmeyle aynı; bulut aynı üreticiyi koşar) + K4/K5/K6 kapıları. SGS/SMMM'de değişen yok.
$KGK_ET=$(if($IkizEtiket -match '^kgk-'){ $IkizEtiket } elseif(-not $IkizEtiket -and [IO.Path]::GetFileNameWithoutExtension($Dosya) -match '^hazir-(kgk-.*)$'){ $Matches[1] } else { '' })
$KGK_SERT=[bool]$KGK_ET -and "$env:DENETLE_KGK_MUTASYON" -ne 'sert'
$KGK3_ACIK=Kgk3Acik $(if($KGK_ET){ $KGK_ET } else { Kgk3Etiket $IkizEtiket $Dosya })   # 07.10 SMMM BAĞI: K4/K5/K6 kgk- ve smmm- etiketinde
# 07.10.2026 K9 KGK UZUNLUK TAVANI: bulut koşucusu (motor/kalip-kosucu.ps1 DersTavani, sinav=KGK) Muhasebe Standartları'na
#   veri/sinav-anatomisi-kgk.json 'Finansal Muhasebe' p90'ını (661), öteki bütün KGK modüllerine 'Denetim' p90'ını (784) verir; bu betik
#   KGK'da sabit 746 kullanıyordu → TMS sorusu 662–746 kr arası 'ok' alıp bulutta ÜCRETSİZ kapıda düşerdi. Kural koşucuyla aynı.
if($KGK_ET -and $Tavan -le 0){
  $kgkAn=$(if("$Ders $KGK_ET" -match '(?i)Muhasebe Standart|(^|-)(tms|tfrs)(-|$)'){ 'Finansal Muhasebe' } else { 'Denetim' }); $UZ_TAVAN=784
  try{ $akY=Join-Path $depoKokD 'veri\sinav-anatomisi-kgk.json'; $pv=[int]((Get-Content $akY -Raw -Encoding UTF8 | ConvertFrom-Json).C_ders_kalibi.$kgkAn.uzunluk.p90); if($pv -gt 0){ $UZ_TAVAN=$pv } }catch{}
  "KGK UZUNLUK TAVANI: $UZ_TAVAN kr ($kgkAn p90; koşucu DersTavani ile aynı — Muhasebe Standartları etiketi tms/tfrs içermiyorsa -Tavan 661 ver; KGK'da -Ders VERME, SGS sözlüğü kurulur)"
}
if($KGK_ET -and -not $YABANCI_DIL_DENETIMI -and -not $Ders -and -not $kapiK){
  $kutup=Join-Path $(if($PSScriptRoot){ $PSScriptRoot } else { '.' }) 'kapi-k-sozluk.ps1'
  if(Test-Path $kutup){ . $kutup; $kapiK=KapiKKgkSozlukOnbellek }
  if(-not $kapiK){ "UYARI: KGK KAPI-K sozlugu kurulamadi - bu kapi OLCULMEDI" } else { "KGK KAPI-K: tüm KGK kitapçıkları (yalnız ön denetim; bulut KGK'da KAPI-K koşmaz)" }
}
"dosya: $Dosya | soru: $($liste.Count) | sozluk kok: $($sz.Keys.Count) | uzunluk tavani: $UZ_TAVAN kr"
if($kapiK){ "KAPI-K sozlugu: genis $($kapiK.genis.Keys.Count) · dar $($kapiK.dar.Keys.Count) (soru $($kapiK.aralik -join '-')) · $($kapiK.blok) blok · son $Pencere donem: $($kapiK.donemler -join ', ')" }
$i=0; $temizSay=0
# İKİZ kurulumu: etiket verilmezse dosya adından (hazir-<etiket>.json); önek sgs/smmm/kgk değilse ölçülmez (söylenir).
$ikizAcik=$false
if(-not $IkizYok){
  $ikEt=$(if($IkizEtiket){ $IkizEtiket } else { ([IO.Path]::GetFileNameWithoutExtension($Dosya) -replace '^hazir-','' -replace '-\d+$','') })
  if($ikEt -match '^(sgs|smmm|kgk)-'){
    $ikOnek=$Matches[1]; $havuzSay=@(Get-ChildItem (Join-Path $depoKokD 'veri\fabrika') -Filter "kalip-parti-$ikOnek-*.json" -ErrorAction SilentlyContinue).Count
    foreach($fn in (IkizFonkYukle $depoKokD)){ . ([scriptblock]::Create($fn.Extent.Text)) }
    . (Join-Path $depoKokD 'arac\ikiz-olcusu.ps1'); . (Join-Path $depoKokD 'arac\smmm-ders-adi.ps1')
    $kok=$depoKokD; $Sinav=$ikOnek.ToUpperInvariant(); $Etiket=$ikEt; $CAPA=@{}; $amb=$null; $don=@{}; $script:BENZER_HAVUZ=$null
    $script:GK_DERS=[bool]($ikEt -match '-(yd|mat|turkce|inkilap)-')
    $ikizAcik=$true
    if($IkizOnbellekProva){
      # EŞDEĞERLİK PROVASI (havuzun TAMAMI): üreticinin BenzerHavuz'u ile önbellekten kurulan havuz alan alan, soru soru.
      $script:BENZER_HAVUZ=$null; $taze=@(BenzerHavuz); $ob=(IkizHavuzOnbellek $ikOnek).havuz.ToArray()
      $kset={ param($x) (@($x) | ForEach-Object { "$_" } | Sort-Object) -join '|' }
      $alT=(@($taze[0].PSObject.Properties.Name) | Sort-Object) -join ','; $alO=(@($ob[0].PSObject.Properties.Name) | Sort-Object) -join ','
      $fark=0; $ornek=@(); $ix=@{}; foreach($o in $ob){ $ix["$($o.etiket)/$($o.id)"]=$o }
      foreach($t in $taze){ $o=$ix["$($t.etiket)/$($t.id)"]; if(-not $o){ $fark++; if($ornek.Count -lt 5){ $ornek+="yok: $($t.etiket)/$($t.id)" }; continue }
        foreach($al in 'konu','ders','soruMetin','dogruMetin'){ if("$($t.$al)" -cne "$($o.$al)"){ $fark++; if($ornek.Count -lt 5){ $ornek+="$($t.etiket)/$($t.id) $al" } } }
        foreach($al in 'kume','sikKume','madde','kaynak'){ if((& $kset $t.$al) -cne (& $kset $o.$al)){ $fark++; if($ornek.Count -lt 5){ $ornek+="$($t.etiket)/$($t.id) $al" } } } }
      "IKIZ ONBELLEK PROVASI: taze $($taze.Count) · önbellek $($ob.Count) · alan listesi $(if($alT -eq $alO){'AYNI'}else{"FARKLI ($alT / $alO)"}) · fark $fark"
      $ornek | ForEach-Object { "  $_" }; if($fark -or $taze.Count -ne $ob.Count -or $alT -ne $alO){ exit 1 } else { exit 0 }
    }
    if(-not $IkizOnbellekYok){ $ho=IkizHavuzOnbellek $ikOnek; $script:BENZER_HAVUZ=$ho.havuz; "İKİZ HAVUZU: $($ho.havuz.Count) soru · $($ho.kaynak)" }
    "İKİZ (KAPI-B): etiket $ikEt · havuz kalip-parti-$ikOnek-*.json = $havuzSay dosya$(if($havuzSay -lt 50){' · ⚠ HAVUZ KÜÇÜK/BAYAT OLABİLİR: arac/parti-senkron.ps1 -Indir -Yaz -Sinav ' + $Sinav})"
  } else { "İKİZ (KAPI-B): ÖLÇÜLMEDİ — etiket önek sgs/smmm/kgk değil ('$ikEt'); -IkizEtiket <etiket> ver" }
}
# KAYNAK ADI: benzersiz adlar ambarda birebir aranır (anahtar yoksa ÖLÇÜLMEDİ denir)
$kaynakVar=@{}; $kaynakOlcu=$false; $kaynakMetin=@{}
if(-not $KaynakYok){
  $sbK="$($env:SUPABASE_SERVICE_KEY)".Trim(); if(-not $sbK){ $sbK="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
  if($sbK){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $adlarT=@($liste | ForEach-Object { @($_.kaynak_adlar) } | Where-Object { "$_".Trim() } | Sort-Object -Unique)
    foreach($ad in $adlarT){ try{ $r=@(Invoke-RestMethod -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id,metin&limit=1&kaynak_ad=eq." + [uri]::EscapeDataString("$ad")) -Headers @{ apikey=$sbK; Authorization="Bearer $sbK"; 'User-Agent'='mevzuat-radar-robot/1.0' } -TimeoutSec 60); $bulunan=@($r | Where-Object { $_ -and $_.id }); $kaynakVar["$ad"]=[bool]$bulunan.Count; if($bulunan.Count){ $kaynakMetin["$ad"]="$($bulunan[0].metin)" } }catch{ $kaynakVar["$ad"]=$null } }
    $kaynakOlcu=$true; "KAYNAK ADI: $($adlarT.Count) benzersiz ad · ambarda yok: $(@($kaynakVar.Keys | Where-Object { $kaynakVar[$_] -eq $false }).Count) · okunamadı: $(@($kaynakVar.Keys | Where-Object { $null -eq $kaynakVar[$_] }).Count)"
  } else { "KAYNAK ADI: ÖLÇÜLMEDİ (SUPABASE_SERVICE_KEY yok)" }
}
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
  if("$($q.soru)".Length -gt $UZ_TAVAN){ $k.Add("soru uzun $("$($q.soru)".Length) kr > ders tavani $UZ_TAVAN (bulut koşucusu bu soruyu ÜCRETSİZ kapıda düşürür)") }
  # KAPI-Ç: formül sonucu şık tutarıyla uyumlu. 05.10.2026: eski "';' yasak" taklidi kaldırıldı — üretici (kalip-parti-uret.ps1
  #   ~2807) son ';' parçasını alır, talimat F.1 çok adımlı yolu ';' ile ister; taklit gm8 GMSİ k2'de 9 sahte KUSUR verdi.
  if($q.celdirici_yol){ foreach($p in @($q.celdirici_yol.PSObject.Properties)){ $v="$($p.Value)"
      if($sayisal){ $son=[regex]::Matches(($v -replace '\([^)]*\)',''),'=\s*(-?[\d\.,]+)'); if($son.Count){ $cv=Sayi $son[$son.Count-1].Groups[1].Value; $sv=Sayi "$($q.siklar.($p.Name))"; if($null -ne $cv -and $null -ne $sv -and [math]::Abs($cv-$sv) -gt [math]::Max(0.5,[math]::Abs($sv)*0.005)){ $k.Add("celdirici $($p.Name) sonucu $cv != sik $sv") } } }
      if("$($p.Name)" -eq "$($q.dogru)"){ $k.Add("celdirici dogru sikta ($($p.Name))") } } }
  # 05.10.2026 GM ADIM/SADE (Cem "1.2.3", sözleşme B25): gm6+gm7 ölçümü — hazır soruda adimlar yoktu, adımı bulut modeli yazdı;
  #   12 parti sorusunun en az 6'sı o katmanda düştü (ADIM-KAYMA, YY-SIKSIZ, simülasyon, AH "6. adımda bulduk"), teori sorusunda adım
  #   hiç yazılmadı ("simülasyon koşamadı"). Bitirmede (smmm-) adım/sade yoksa KUSUR, öteki sınavlarda uyarı.
  foreach($x in @(AdimSadeEksik $q)){ if($GM_SERT -or $KGK_SERT){ $k.Add($x) } else { $not.Add($x) } }
  if($KGK3_ACIK){   # KGK: üçü KUSUR · SMMM: harf not, verilen durdur, fıkra not (07.10 banka ölçümü)
    foreach($x in @(HarfAnmaKusur $q)){ if($KGK_ET){ $k.Add("KGK $x") } else { $not.Add("SMMM $x") } }
    foreach($x in @(SorudaVerilenKusur $q)){ if($KGK_ET){ $k.Add("KGK $x") } else { $k.Add("SMMM $x") } }
    if($kaynakOlcu){ $kmF=@{}; foreach($ad in @($q.kaynak_adlar)){ if($kaynakMetin.ContainsKey("$ad")){ $kmF["$ad"]=$kaynakMetin["$ad"] } }; foreach($x in @(FikraAtifKusur $q $kmF)){ if($KGK_ET){ $k.Add("KGK $x") } else { $not.Add("SMMM $x") } } }
    else { $not.Add("$(if($KGK_ET){ 'KGK' } else { 'SMMM' }) FIKRA ATFI: ÖLÇÜLMEDİ (kaynak metni okunmadı)") }
  }
  # 05.10.2026 KAPI-KALITE yerelde: bulut FAZ GM'in SoruKaliteKapisi'si (arac/soru-kalite-kapisi.js --tek; KAPI-AS2/EK/HK/BP/BOS/TR/YY/ADIM).
  #   gm7'de 5 soru bununla düştü, ön denetim görmüyordu. Hazır soru tarihsiz = YENİ2 → NOT- dışındaki her satır durdurur.
  foreach($x in @(KaliteTek $q)){ if("$x" -like 'NOT-*'){ $not.Add("$x") } else { $k.Add("KAPI-KALITE $x") } }
  foreach($x in @(GercekKapiC $q)){ $k.Add("KAPI-Ç (üretici): $x") }
  foreach($x in @(TersSadeNot $q)){ $not.Add($x) }
  foreach($x in @(KapaliListeNot $q)){ $not.Add($x) }
  if($kaynakOlcu){ foreach($x in @(OnekAlintiNot $q $(if($q.kaynak_adlar){ $kmS=@{}; foreach($ad in @($q.kaynak_adlar)){ if($kaynakMetin.ContainsKey("$ad")){ $kmS["$ad"]=$kaynakMetin["$ad"] } }; $kmS } else { @{} }))){ $not.Add($x) } }
  foreach($x in @(SimOnKontrol $q)){ if($GM_SERT -or $KGK_SERT){ $k.Add($x) } else { $not.Add($x) } }
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
  # 05.10.2026 KAPI-Y (üretici 07.09 Cem "2025 değil 2026 versin"): kökte yıl geçiyorsa en yenisi bugünün yılı olmalı; "2004 sayılı" sayılmaz.
  #   gm6'da 15 hazır sorunun 12'si bulutta bununla düştü, bu betik görmüyordu. Desen motor/kalip-parti-uret.ps1 FAZ A ile AYNI.
  $yk=YilKusurOlc "$($q.soru)" (Get-Date).Year; if($yk){ $k.Add("KAPI-Y $yk") }
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
  # ASCII Türkçe (25.09: Yabancı Dil'de soru ve şıklar İngilizce -> yalnız adımlar ölçülür; "once" İngilizce kelimesi "önce" sanılıyordu, K3 w2)
  $tum=$(if($YABANCI_DIL_DENETIMI){ '' } else { "$($q.soru) "+(@($harf | ForEach-Object { "$($q.siklar.$_)" }) -join ' ') })+' '+(@($q.adimlar | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')
  $asc=@([regex]::Matches($tum.ToLowerInvariant(),'\b(icin|degil|isletme|donem|uretim|dogru|yanlis|ucret|hesabi|satis|yuzde|deger|iscilik|dagitim|kayit|kaydi|urun|uretilen|tutari|yapilan|icinde|once)\b') | ForEach-Object { $_.Value } | Select-Object -Unique); if($asc.Count){ $k.Add("ASCII Turkce: $($asc -join ',')") }
  # 26.09 KAPI-HG PAKET KİRLENMESİ: üretici (kalip-parti-uret.ps1 KAPI-HG) Matematik/Atatürk DIŞINDA her derste soru+şıklardaki
  #   3 haneli sayıyı (birim yoksa) hesap kodu sanıp hakem paketine THP tanımı ekler; paket tavanı asıl notu dışarı iter →
  #   hakem "kaynak ilgisiz" der (k7 Ekonomi 2 soru: '360', '120'). Hesap kodu kullanan derslerde (FM/Maliyet/MTA/Denetim/Vergi) ölçülmez.
  #   Desen üreticininkiyle aynı biçim (birim listesi dahil); 🚫 GÖRMEZ: üreticinin Get-HesapKodu süzgeci (geçersiz kodu atıyorsa burada fazla uyarı olur).
  if($Ders -and $Ders -notmatch 'Finansal|Maliyet|Mali Tablo|Denetim|Vergi|Muhasebe|Matematik|Atat'){
    $hgM="$($q.soru) " + ((@('A','B','C','D','E') | ForEach-Object { "$($q.siklar.$_)" }) -join ' ')
    $hgB='(?:TL|YTL|TRY|USD|EUR|₺|lira|kuruş|kurus|adet|kg|gram|ton|km|cm|mm|metre|litre|gün|gun|ay|yıl|yil|saat|dakika|saniye|kişi|kisi)'
    $hgS=@([regex]::Matches($hgM,"(?<![\d.,%$])([1-7]\d\d)(?![\d.,%])\s+(?!$hgB(?![A-Za-zÇĞİÖŞÜçğıöşü]))") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    if($hgS.Count){ $k.Add("KAPI-HG riski: '$($hgS -join ', ')' hesap kodu sanılır, hakem paketine THP girer (sayıyı yazıyla yaz ya da birim/% ekle)") }
  }
  foreach($x in @(OzelMaliyetKapisi $q)){ $k.Add("KAPI-OM: $x") }   # 27.09: üretici FAZ GM'de aynı işlevle ÜCRETSİZ düşürür
  if($kaynakOlcu){ foreach($ad in @($q.kaynak_adlar)){ if("$ad".Trim() -and $kaynakVar["$ad"] -eq $false){ $k.Add("KAYNAK ADI ambarda yok: '$ad' (paket boş kalır, hakem soruyu atlar)") } } }
  foreach($ad in @(MulgaMaddeKusur $q $MULGA_SET)){ $k.Add("KAPI-MM: kaynak MÜLGA/İPTAL madde: '$ad' — yürürlükteki maddeye dayandır") }
  # 26.09 KAPI-O (klişe/koku): üreticinin GERÇEK KokuKusur fonksiyonu (AST). Ölçüldü: sgs-k10-yd-kolay 'bu bağlamda' klişesiyle bulutta düşecekti, ön denetim görmüyordu.
  if($ikizAcik){ foreach($x in @(KokuKusur $q)){ $k.Add("KAPI-O: $x") } }
  if($ikizAcik){ foreach($x in @(BenzerlikKusur $q ("hz-{0:d2}" -f $i))){ $k.Add("KAPI-B: $x") }; $don[("hz-{0:d2}" -f $i)]=$q }
  $durumEt=$(if($k.Count){ 'KUSUR' } else { 'ok' })
  if($durumEt -eq 'ok'){ $temizSay++ }
  "{0,2}. {1,-36} {2}" -f $i,$q.konu,$durumEt
  foreach($x in $k){ "      - $x" }
  foreach($x in $not){ "      . $x" }
}
# AYNI KONU İKİ KEZ (27.09, KGK oturumunun ölçümü): üretici FAZ GM'de hazır soruya kimliği KONUDAN verir (kp-id = konu eşleşmesi);
#   aynı dosyada aynı konu adlı ikinci soru aynı kp-id'ye düşer ve HİÇ İZ BIRAKMADAN kaybolur (KGK: 85 sorunun 19'u). Katlama
#   üreticininkiyle aynı (Türkçe harf → ASCII, küçük harf). Bu dosyada bulunursa: ikinci soruyu başka etikete (k…b) taşı.
$konuSay=@{}; foreach($q2 in $liste){ $kk2=("$($q2.konu)" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant().Trim(); $konuSay[$kk2]=[int]$konuSay[$kk2]+1 }
$ciftKonu=@($konuSay.Keys | Where-Object { $konuSay[$_] -gt 1 })
if($ciftKonu.Count){ ""; "AYNI KONU: KUSUR — üretici aynı konudan yalnız BİR soru alır, fazlası iz bırakmadan kaybolur: $(($ciftKonu | ForEach-Object { "$_ x$($konuSay[$_])" }) -join ', ')"; $temizSay=[Math]::Max(0,$temizSay - @($ciftKonu | ForEach-Object { $konuSay[$_] - 1 } | Measure-Object -Sum).Sum) }
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
# 05.10.2026 A4 ŞIK DAĞILIMI (sözleşme A4, kapısı yoktu): doğru harf dağılımı + uyarı (≥5 soruda bir harf %40'ı aşarsa). DURDURMAZ
#   (sayısal şıklar artan sıralı → harf değere bağlı; yazar çeldirici değerleriyle yönlendirir). gm8'de 15 sorunun 12'si B/C idi.
$dag=@{}; foreach($q0 in @($liste)){ $hd="$($q0.dogru)".Trim().ToUpperInvariant(); if($hd){ $dag[$hd]=1+[int]$dag[$hd] } }
"SIK DAGILIMI: " + ((@('A','B','C','D','E') | ForEach-Object { "$_ $([int]$dag[$_])" }) -join ' · ') + $(if(@($liste).Count -ge 5 -and @($dag.Values | Where-Object { $_ / [double]@($liste).Count -gt 0.40 }).Count){ "  ⚠ A4: bir harf %40'ı aşıyor — çeldirici değerleriyle doğru şıkkı başka harfe taşı (durdurmaz)" } else { '' }) + "  · ONERI (siradaki dogru siklar bu harflere): " + ((@('A','B','C','D','E') | Sort-Object { [int]$dag[$_] }, { $_ } | Select-Object -First 2) -join ', ')
"ozet: $temizSay/$($liste.Count) soru kusursuz"
