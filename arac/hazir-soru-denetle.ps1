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
param([string]$Dosya='',[string]$Sozluk='',[string]$Ders='',[int]$Pencere=7,[int]$Tavan=0,[switch]$TavanSinavi,
      [string]$IkizEtiket='',[switch]$IkizYok,[switch]$KaynakYok,[switch]$IkizSinavi)
$trS=[cultureinfo]::GetCultureInfo('tr-TR')
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
  $gerek=@('Katla2','KelimeKume','Jaccard','SoruTeoriMi','SikKume','KokMaddeNo','TeoriFarkliMi','BenzerHavuz','BenzerlikKusur')
  $bul=@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true) | Where-Object { $gerek -contains $_.Name })
  $eksikF=@($gerek | Where-Object { $ad=$_; -not ($bul | Where-Object { $_.Name -eq $ad }) })
  if($eksikF.Count){ throw "İKİZ: üreticide fonksiyon bulunamadı: $($eksikF -join ', ')" }
  return $bul
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
if(-not $Dosya){ throw '-Dosya zorunlu (ya da -TavanSinavi / -IkizSinavi)' }
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
$liste=Get-Content $Dosya -Raw -Encoding UTF8 | ConvertFrom-Json
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
    "İKİZ (KAPI-B): etiket $ikEt · havuz kalip-parti-$ikOnek-*.json = $havuzSay dosya$(if($havuzSay -lt 50){' · ⚠ HAVUZ KÜÇÜK/BAYAT OLABİLİR: arac/parti-senkron.ps1 -Indir -Yaz -Sinav ' + $Sinav})"
  } else { "İKİZ (KAPI-B): ÖLÇÜLMEDİ — etiket önek sgs/smmm/kgk değil ('$ikEt'); -IkizEtiket <etiket> ver" }
}
# KAYNAK ADI: benzersiz adlar ambarda birebir aranır (anahtar yoksa ÖLÇÜLMEDİ denir)
$kaynakVar=@{}; $kaynakOlcu=$false
if(-not $KaynakYok){
  $sbK="$($env:SUPABASE_SERVICE_KEY)".Trim(); if(-not $sbK){ $sbK="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
  if($sbK){ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $adlarT=@($liste | ForEach-Object { @($_.kaynak_adlar) } | Where-Object { "$_".Trim() } | Sort-Object -Unique)
    foreach($ad in $adlarT){ try{ $r=@(Invoke-RestMethod -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id&limit=1&kaynak_ad=eq." + [uri]::EscapeDataString("$ad")) -Headers @{ apikey=$sbK; Authorization="Bearer $sbK"; 'User-Agent'='mevzuat-radar-robot/1.0' } -TimeoutSec 60); $kaynakVar["$ad"]=[bool]@($r | Where-Object { $_ -and $_.id }).Count }catch{ $kaynakVar["$ad"]=$null } }
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
  # ASCII Türkçe (25.09: Yabancı Dil'de soru ve şıklar İngilizce -> yalnız adımlar ölçülür; "once" İngilizce kelimesi "önce" sanılıyordu, K3 w2)
  $tum=$(if($YABANCI_DIL_DENETIMI){ '' } else { "$($q.soru) "+(@($harf | ForEach-Object { "$($q.siklar.$_)" }) -join ' ') })+' '+(@($q.adimlar | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')
  $asc=@([regex]::Matches($tum.ToLowerInvariant(),'\b(icin|degil|isletme|donem|uretim|dogru|yanlis|ucret|hesabi|satis|yuzde|deger|iscilik|dagitim|kayit|kaydi|urun|uretilen|tutari|yapilan|icinde|once)\b') | ForEach-Object { $_.Value } | Select-Object -Unique); if($asc.Count){ $k.Add("ASCII Turkce: $($asc -join ',')") }
  if($kaynakOlcu){ foreach($ad in @($q.kaynak_adlar)){ if("$ad".Trim() -and $kaynakVar["$ad"] -eq $false){ $k.Add("KAYNAK ADI ambarda yok: '$ad' (paket boş kalır, hakem soruyu atlar)") } } }
  if($ikizAcik){ foreach($x in @(BenzerlikKusur $q ("hz-{0:d2}" -f $i))){ $k.Add("KAPI-B: $x") }; $don[("hz-{0:d2}" -f $i)]=$q }
  $durumEt=$(if($k.Count){ 'KUSUR' } else { 'ok' })
  if($durumEt -eq 'ok'){ $temizSay++ }
  "{0,2}. {1,-36} {2}" -f $i,$q.konu,$durumEt
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
