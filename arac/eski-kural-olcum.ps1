# ESKİ SORU × KURAL ÖLÇÜMÜ (08.09, Cem: "eski sorulara ne olacak? 2026 kuralı 2025'lileri eleyecekse konuşalım") — 0 USD
# Huninin ADAY saydığı eski SGS sorularını SORU-BASMA-KURALLARI'nın deterministik kurallarından tek tek geçirir; her kuralın kaç soruyu
# eleyeceğini, kaçının MEKANİK düzeltilebileceğini (yıl kaydırma, Türkçe harf onarımı, yer tutucu ad, şık sıralama) ve kaç sorunun
# hiçbir sert kurala takılmadığını ders ders yazar. Çıktı: sql-yerel/ESKI-KURAL-OLCUM-<tarih>.md + veri/fabrika/eski-kural-olcum-<tarih>.json
param([string]$Tarih=(Get-Date -Format yyyyMMdd))
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$dump=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-dump-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$huniYol=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$d=@(ConvertFrom-Json -InputObject (Get-Content $dump -Raw -Encoding UTF8)); if($d.Count -eq 1 -and $d[0].PSObject.Properties['SyncRoot']){ $d=@($d[0].SyncRoot) }
$h=ConvertFrom-Json -InputObject (Get-Content $huniYol -Raw -Encoding UTF8)
$aday=New-Object 'System.Collections.Generic.HashSet[string]'; foreach($a in @($h.adayIdler)){ [void]$aday.Add("$($a.id)") }
$sorular=@($d | Where-Object { $aday.Contains("$($_.id)") })
"aday: $($sorular.Count) / döküm $($d.Count)"
# THP sözlüğü (kod-ad çifti kuralı 5.1)
$thp=@{}
try{ if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
  $H=@{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'User-Agent'='mevzuat-radar-robot/1.0' }
  $r=Invoke-WebRequest -Uri ('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString('THP %')+'&limit=1000') -Headers $H -UseBasicParsing -TimeoutSec 120
  foreach($x in (ConvertFrom-Json -InputObject $r.Content)){ $m=[regex]::Match("$($x.kaynak_ad)",'^THP\s+(\d{3})\s*-\s*(.+)$'); if($m.Success){ $thp[$m.Groups[1].Value]=$m.Groups[2].Value.Trim() } } }catch{ "THP sözlüğü çekilemedi: $($_.Exception.Message)" }
"THP sözlüğü: $($thp.Count) hesap"
function Katla([string]$s){ $s="$s".ToLowerInvariant() -replace 'ı','i' -replace 'İ','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ç','c' -replace 'ö','o' -replace 'ü','u' -replace 'â','a' -replace 'î','i' -replace 'û','u'; ($s -replace '[^a-z0-9%.,/ ]+',' ' -replace '\s+',' ').Trim() }
$ASCII_TR='(?i)\b(icin|degil|gunu|sirket|isletme|isletmenin|donem|donemin|uretim|butun|dogru|yanlis|ucret|ucreti|olcum|hesabi|hesabina|karsilik|karsiligi|musteri|satis|satislar|alis|odeme|yukumluluk|ozkaynak|donen|buyuk|kucuk|yil|yilinda|yilinin|yuzde|deger|degeri|sayi|isci|iscilik|surec|sure|gecerli|gecmis|dagitim|dagitimi|olusan|olusur|bagli|bagimsiz|yonetim|denetci|dusuk|yuksek|artis|azalis|gerceklesen|gercek|agirlikli|musavir|mudur|kayit|kaydi|birikmis|odenmis|odenecek|verilmis|alinmis|bagis|tasit|tasitlar|demirbas|demirbaslar|ozel|dogrudan|gunluk|gunler|aylik|yillik|uyesi|uyeler|tuketim|urun|urunler|uretilen|cikardigi|cikarmis|basladigi|kar|zarar|ozsermaye|ozkaynaklar|fatura|iade|iadesi)\b'
$genel=@('Turkce','Matematik','Ataturk Ilke ve Inkilap Tarihi','Yabanci Dil')
$hukuk=@('Vergi Hukuku','Ticaret Hukuku','Borclar Hukuku','Is ve Sosyal Guvenlik Hukuku','Meslek Hukuku','Maliye','Ekonomi')
$yilBu=(Get-Date).Year
$satir=New-Object System.Collections.ArrayList
foreach($s in $sorular){
  $soru="$($s.soru)"; $harf=@('A','B','C','D','E'); $sik=@($harf | ForEach-Object { "$($s.siklar.$_)" }); $tum=$soru+' '+($sik -join ' ')
  $k=[ordered]@{ id="$($s.id)"; ders="$($s.ders)"; konu="$($s.konu)" }
  # sayı şıklı mı
  $sayiN=0; foreach($x in $sik){ if($x -match '^\s*%?\s*-?\d[\d.,]*\s*(TL|₺|%|adet|kg|gün|yıl|ay|saat|birim)?\s*$'){ $sayiN++ } }; $k.hesap=($sayiN -ge 4)
  # 4 · yıl
  $yillar=@([regex]::Matches($soru,'\b(20[0-3]\d)\b(?!\s*(sayılı|s\.))') | ForEach-Object { [int]$_.Groups[1].Value }); $k.yilVar=($yillar.Count -gt 0); $k.yilEski=($yillar.Count -and (($yillar | Measure-Object -Maximum).Maximum -lt $yilBu))
  # 2 · koku
  $k.yerTutucu=[bool]($tum -match '(?i)\b(ABC|XYZ|DEF|KLM|XY|AB)\b\s*(A\.?\s?Ş\.?|Ltd|Ticaret|İşletme|Şirket|San\.|A\.S\.)' -or $soru -match '(?i)\bABC\b|\bXYZ\b')
  $tutar=@([regex]::Matches($soru,'(?<![\d.,])\d{1,3}(?:\.\d{3})+(?![\d.,])') | ForEach-Object { [long]($_.Value -replace '\.','') }); $k.yuvarlak=($tutar.Count -ge 4 -and -not @($tutar | Where-Object { $_ % 10000 -ne 0 }).Count)
  $k.klise=[bool]($tum -match '(?i)önem arz et|bu bağlamda|göz önünde bulundur|unutulmamalıdır ki|dikkat edilmesi gereken'); $k.uzunTire=[bool]($tum -match '—')
  $k.turkce=@([regex]::Matches($tum,$ASCII_TR) | ForEach-Object { $_.Value.ToLowerInvariant() } | Select-Object -Unique).Count
  # 6.5 · kanun kısaltması (yalnız KDV/TMS/TFRS/BDS serbest)
  $k.kisaltma=@([regex]::Matches($tum,'\b(VUK|TTK|TBK|GVK|KVK|AATUHK|İİK|IIK|SGK|THP|MSUGT|HMK|TCK|SPKn)\b') | ForEach-Object { $_.Value } | Select-Object -Unique).Count
  # 1.5 · şıkka gerekçe / doğru en uzun / sayı sıralı
  $k.sikGerekce=(-not $k.hesap) -and @($sik | Where-Object { $_ -match '(?i)\b(çünkü|nedeniyle|dolayısıyla|bu yüzden|zira)\b' -or $_.Length -gt 160 }).Count -gt 0
  if(-not $k.hesap){ $uz=@($sik | ForEach-Object { $_.Length } | Sort-Object); $dU="$($s.siklar.$($s.dogru))".Length; $k.dogruEnUzun=($uz[2] -gt 0 -and $dU -eq $uz[4] -and $dU -gt 1.3*$uz[2] -and $uz[4] -ne $uz[3]) } else { $k.dogruEnUzun=$false }
  if($k.hesap){ $deg=@(); foreach($x in $sik){ $m=[regex]::Match($x,'-?\d[\d.]*(?:,\d+)?'); $t=$m.Value -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ $deg+=$v } }; $k.sayiSirasiz=($deg.Count -eq 5 -and (($deg | Sort-Object) -join ',') -ne ($deg -join ',')); $k.sayiTekrar=($deg.Count -eq 5 -and @($deg | Select-Object -Unique).Count -lt 5) } else { $k.sayiSirasiz=$false; $k.sayiTekrar=$false }
  # 5.1 · kod-ad çifti
  $kk=0; if($thp.Count){ foreach($t in $sik+@($soru)){ foreach($m in [regex]::Matches($t,'(?<![\d.,])([1-7]\d{2})(?![\d.,])(?!\s*(?:TL|₺|adet|kg|gün|yıl|ay|saat|birim|%))\s+([^\d]{3,60})')){ $kod=$m.Groups[1].Value; if(-not $thp.ContainsKey($kod)){ continue }; $yaz=Katla $m.Groups[2].Value; $res=Katla $thp[$kod]; $resK=@(($res -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|veya|ile|hesabi|hs)$' }); if(-not $resK.Count){ continue }; $eksik=@($resK | Where-Object { $w=$_; $on=$(if($w.Length -gt 5){ $w.Substring(0,5) } else { $w }); $yaz -notmatch ('\b'+[regex]::Escape($on)) }); if($eksik.Count -gt [Math]::Floor($resK.Count/2)){ $kk++ } } } }; $k.kodAd=$kk
  # 1.4 · kök kalıbı (bilgi)
  $k.olumsuz=[bool]($soru -match '(?i)yanlıştır|değildir|söylenemez|yer almaz|sayılmaz|olamaz'); $k.oncul=[bool]($soru -match '(?m)(^|\s)II\.\s.*?(^|\s)III\.\s|hangileri')
  # sınıf: SERT (elenir) / MEKANİK (düzeltilebilir) / TEMİZ
  $sert=@(); if($k.yuvarlak){ $sert+='yuvarlak' }; if($k.sikGerekce){ $sert+='şıkta gerekçe' }; if($k.kodAd){ $sert+='kod-ad' }; if($k.klise){ $sert+='klişe' }; if($k.dogruEnUzun){ $sert+='doğru en uzun' }; if($k.sayiTekrar){ $sert+='tekrar tutar' }
  $mek=@(); if($k.yilEski){ $mek+='yıl' }; if($k.yerTutucu){ $mek+='yer tutucu' }; if($k.turkce){ $mek+='Türkçe harf' }; if($k.kisaltma){ $mek+='kısaltma' }; if($k.sayiSirasiz){ $mek+='sıra' }; if($k.uzunTire){ $mek+='uzun tire' }
  $k.sert=($sert -join ','); $k.mekanik=($mek -join ','); $k.sinif=$(if($sert.Count){ 'ELENİR' } elseif($mek.Count){ 'MEKANİK DÜZELTME' } else { 'TEMİZ' })
  [void]$satir.Add([pscustomobject]$k)
}
$N=$satir.Count
function Y($say){ if($N){ "$say (%$([math]::Round(100*$say/$N)))" } else { '0' } }   # PS harf tuzağı: parametre $n ile toplam $N AYNI değişkendi → hep %100 çıktı (08.09)
$kurallar=[ordered]@{
  'Yıl eski (en yeni yıl < 2026)'=@($satir | Where-Object yilEski).Count; '  · yıl geçen soru (toplam)'=@($satir | Where-Object yilVar).Count
  'Yer tutucu unvan (ABC/XYZ)'=@($satir | Where-Object yerTutucu).Count; 'Tutarların hepsi onbinlik yuvarlak (≥4 tutar)'=@($satir | Where-Object yuvarlak).Count
  'Türkçe harf eksik (ASCII kelime)'=@($satir | Where-Object { $_.turkce -gt 0 }).Count; 'Kanun kısaltması (VUK/TTK/GVK…)'=@($satir | Where-Object { $_.kisaltma -gt 0 }).Count
  'Şıkta gerekçe / uzun cümle şık'=@($satir | Where-Object sikGerekce).Count; 'Doğru şık en uzun'=@($satir | Where-Object dogruEnUzun).Count
  'Sayı şıkları sırasız'=@($satir | Where-Object sayiSirasiz).Count; 'Sayı şıklarında tekrar tutar'=@($satir | Where-Object sayiTekrar).Count
  'Kod-ad çifti tutmuyor'=@($satir | Where-Object { $_.kodAd -gt 0 }).Count; 'Klişe'=@($satir | Where-Object klise).Count; 'Uzun tire'=@($satir | Where-Object uzunTire).Count
  'Olumsuz kök (bilgi)'=@($satir | Where-Object olumsuz).Count; 'Öncüllü (bilgi)'=@($satir | Where-Object oncul).Count
}
$sinif=[ordered]@{ 'TEMİZ (hiçbir kurala takılmadı)'=@($satir | Where-Object { $_.sinif -eq 'TEMİZ' }).Count; 'MEKANİK DÜZELTME ile geçer'=@($satir | Where-Object { $_.sinif -eq 'MEKANİK DÜZELTME' }).Count; 'ELENİR (sert kural)'=@($satir | Where-Object { $_.sinif -eq 'ELENİR' }).Count }
$md=New-Object System.Text.StringBuilder
[void]$md.AppendLine("# ESKİ SORU × KURAL ÖLÇÜMÜ ($(Get-Date -Format 'dd.MM.yyyy HH:mm')) — $N kalıba aday eski SGS sorusu")
[void]$md.AppendLine(""); [void]$md.AppendLine("Kaynak: $(Split-Path $dump -Leaf) · aday kümesi $(Split-Path $huniYol -Leaf) · kurallar SORU-BASMA-KURALLARI.md (deterministik olanlar; hakem, kör çözüm, kaynak-uyum bu ölçümde YOK — onlar paralı)."); [void]$md.AppendLine("")
[void]$md.AppendLine("## 1 · Kural kural: kaç soru takılıyor"); [void]$md.AppendLine(""); [void]$md.AppendLine("| Kural | Takılan | Ne yapılır |"); [void]$md.AppendLine("|---|---:|---|")
$neYap=@{ 'Yıl eski (en yeni yıl < 2026)'='MEKANİK: muhasebe sorusunda yıllar aynı farkla kaydırılır (süreler korunur); hukukta yıla bağlı had varsa ELENİR'; 'Yer tutucu unvan (ABC/XYZ)'='MEKANİK: "işletme" ya da gerçekçi ad (soru metnine dokunur — Cem kararı)'; 'Tutarların hepsi onbinlik yuvarlak (≥4 tutar)'='SERT: tutar değişirse şıklar bozulur → elenir ya da yeni basım'; 'Türkçe harf eksik (ASCII kelime)'='MEKANİK: YazimOnar sözlüğüyle onarım (anlam değişmez — Cem kararı)'; 'Kanun kısaltması (VUK/TTK/GVK…)'='MEKANİK: DilOnar uzun ada çevirir ("213 sayılı Vergi Usul Kanunu")'; 'Şıkta gerekçe / uzun cümle şık'='SERT: şık yeniden yazılmaz → elenir'; 'Doğru şık en uzun'='SERT (sızıntı) → elenir'; 'Sayı şıkları sırasız'='MEKANİK: SikSirala (harf/açıklama birlikte taşınır)'; 'Sayı şıklarında tekrar tutar'='SERT → elenir'; 'Kod-ad çifti tutmuyor'='SERT → elenir (toptan düzeltme yasak)'; 'Klişe'='SERT (koku)'; 'Uzun tire'='MEKANİK: virgül/nokta' }
foreach($kv in $kurallar.GetEnumerator()){ [void]$md.AppendLine("| $($kv.Key) | $(Y $kv.Value) | $(if($neYap.ContainsKey($kv.Key)){ $neYap[$kv.Key] } else { 'bilgi' }) |") }
[void]$md.AppendLine(""); [void]$md.AppendLine("## 2 · Sınıflama"); [void]$md.AppendLine(""); [void]$md.AppendLine("| Sınıf | Soru |"); [void]$md.AppendLine("|---|---:|"); foreach($kv in $sinif.GetEnumerator()){ [void]$md.AppendLine("| $($kv.Key) | $(Y $kv.Value) |") }
[void]$md.AppendLine(""); [void]$md.AppendLine("## 3 · Ders ders"); [void]$md.AppendLine(""); [void]$md.AppendLine("| Ders | Aday | Temiz | Mekanik | Elenir | Yıl eski | Türkçe | Yer tutucu | Yuvarlak | Şık gerekçe | Kod-ad |"); [void]$md.AppendLine("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
foreach($g in ($satir | Group-Object ders | Sort-Object Name)){ $r=@($g.Group); [void]$md.AppendLine("| $($g.Name) | $($r.Count) | $(@($r | Where-Object { $_.sinif -eq 'TEMİZ' }).Count) | $(@($r | Where-Object { $_.sinif -eq 'MEKANİK DÜZELTME' }).Count) | $(@($r | Where-Object { $_.sinif -eq 'ELENİR' }).Count) | $(@($r | Where-Object yilEski).Count) | $(@($r | Where-Object { $_.turkce -gt 0 }).Count) | $(@($r | Where-Object yerTutucu).Count) | $(@($r | Where-Object yuvarlak).Count) | $(@($r | Where-Object sikGerekce).Count) | $(@($r | Where-Object { $_.kodAd -gt 0 }).Count) |") }
[void]$md.AppendLine(""); [void]$md.AppendLine("## 4 · Not"); [void]$md.AppendLine("- Bu ölçüm yalnız deterministik kurallardır. Hakem (kaynak-uyum), kör çözüm ve ikinci hakem paralı ve ayrıca eler; pilot onları ölçer.")
[void]$md.AppendLine("- 'Türkçe harf' sayımı sözlük tabanlıdır (sık ASCII kelimeler); gerçek oran biraz daha yüksek olabilir. 'Şıkta gerekçe' ölçüsü: cümle şıkta 'çünkü/nedeniyle/dolayısıyla' ya da >160 karakter.")
[void]$md.AppendLine("- MEKANİK düzeltmeler soru metnine dokunur; 29.07 kuralı (soru/şık/doğru değişmez) için Cem'in istisna kararı gerekir. Anlam değişmez, yazım ve ad değişir.")
$mdYol=Join-Path $kok "sql-yerel\ESKI-KURAL-OLCUM-$Tarih.md"; [IO.File]::WriteAllText($mdYol,$md.ToString(),[Text.UTF8Encoding]::new($false))
$jsYol=Join-Path $kok "veri\fabrika\eski-kural-olcum-$Tarih.json"; [IO.File]::WriteAllText($jsYol,(ConvertTo-Json -InputObject @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); aday=$N; kurallar=$kurallar; sinif=$sinif; sorular=@($satir) } -Depth 4 -Compress),[Text.UTF8Encoding]::new($false))
"yazildi: $mdYol"; ""; foreach($kv in $kurallar.GetEnumerator()){ "  {0,-46} {1}" -f $kv.Key,(Y $kv.Value) }; ""; foreach($kv in $sinif.GetEnumerator()){ "  {0,-46} {1}" -f $kv.Key,(Y $kv.Value) }
