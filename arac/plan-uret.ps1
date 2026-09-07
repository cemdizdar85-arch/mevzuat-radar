# PLAN ÜRETİCİ (08.09, Cem: "konu konu formül yapalım, 2×A basalım") — 0 USD
# Huninin pencere konularından (son 7 dönem, etiket → ders → kez) ders × seviye plan satırları ve konu dosyaları üretir; koşucu bunu okur.
#   Formül A : her konu 3 × kez soru (her kez için kolay/zor/çok zor birer) → seviye geçişi: kez kadar tekrar (tur)
#   Formül E : 1 kez çıkan konu 1 soru (dersin anatomisine göre seviye), 2+ kez 3 soru (üç seviye)
# Çıktı: veri/sinav/plan-<ad>.json (koşucu planı) + veri/sinav/konu/<ad>-<ders>-<seviye>.json (konu adı listesi, üretici -KonuDosya)
# Kullanım: powershell -NoProfile -File arac/plan-uret.ps1 -Ad sgs-t1 -Formul A -Toplu -Disla 'Yabanci|Matematik|Turkce|Ataturk|Ekonomi|Maliye$' -Parca 4
param([string]$Ad='sgs-t1',[ValidateSet('A','E')][string]$Formul='A',[switch]$Toplu,[int]$Tur=1,[string]$DersSuz='',[string]$Disla='',[int]$Parca=1)
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
$huniYol=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$h=ConvertFrom-Json -InputObject (Get-Content $huniYol -Raw -Encoding UTF8)
# r = üreticiye giden -DersRegex. 08.09 Tur 1 denetimi: üç tablo üç ayrı ad kullanıyor — çıkmış kalıp json ("Ticaret ve Borclar", "Is ve Sosyal Guvenlik",
# "Ataturk Ilkeleri"), ders profili ("Ataturk Ilkeleri ve Inkilap Tarihi") ve üreticinin DERS_KANUN anahtarları ("Ticaret Hukuku", "Is ve Sosyal
# Guvenlik Hukuku"). Düz ad verilince 4 ders kalıbı (tip kotası, çapa, p75) ve profili (hakem ders uyumu) kaybediyordu → regex ÜÇÜNÜ de yakalar:
# DERS_KANUN anahtarı regex METNİNİN İÇİNDE geçmeli (üretici `dersAdi -match Escape(anahtar)` yapar), kalıp/profil adı ise regex'e -match uymalı.
$SIN=@{ 'Finansal Muhasebe'=@{s=26;r='Finansal Muhasebe';k='fmuh'}; 'Denetim'=@{s=16;r='Denetim';k='denetim'}; 'Yabanci Dil'=@{s=10;r='Yabanci Dil';k='yd'}; 'Matematik'=@{s=8;r='Matematik';k='mat'}; 'Maliyet Muhasebesi'=@{s=8;r='Maliyet Muhasebesi';k='maliyet'}; 'Mali Tablolar Analizi'=@{s=8;r='Mali Tablolar Analizi';k='mta'}; 'Turkce'=@{s=7;r='Turkce';k='turkce'}; 'Ekonomi'=@{s=6;r='Ekonomi';k='ekonomi'}; 'Maliye'=@{s=6;r='^Maliye$';k='maliye'}; 'Meslek Hukuku'=@{s=6;r='Meslek Hukuku';k='meslek'}; 'Is ve Sosyal Guvenlik Hukuku'=@{s=6;r='Is ve Sosyal Guvenlik Hukuku|Is ve Sosyal Guvenlik';k='issgk'}; 'Vergi Hukuku'=@{s=6;r='Vergi Hukuku';k='vergi'}; 'Ticaret Hukuku'=@{s=6;r='Ticaret Hukuku|Ticaret ve Borclar';k='ticaret'}; 'Borclar Hukuku'=@{s=6;r='Borclar Hukuku|Ticaret ve Borclar';k='borclar'}; 'Ataturk Ilke ve Inkilap Tarihi'=@{s=5;r='Ataturk Ilke';k='inkilap'} }
# kalıp adı (uzunluk p75 için): plan dersi → cikmis-ders-kalibi-sgs.json dersi
$KALIP_AD=@{ 'Ticaret Hukuku'='Ticaret ve Borclar'; 'Borclar Hukuku'='Ticaret ve Borclar'; 'Is ve Sosyal Guvenlik Hukuku'='Is ve Sosyal Guvenlik'; 'Ataturk Ilke ve Inkilap Tarihi'='Ataturk Ilkeleri' }
$kalip=$null; $kalipYol=Join-Path $kok 'veri\cikmis-ders-kalibi-sgs.json'; if(Test-Path $kalipYol){ $kalip=ConvertFrom-Json -InputObject (Get-Content $kalipYol -Raw -Encoding UTF8) }
function DersTavan([string]$ders){
  # 08.09 Tur 1 denetimi: plan 350 yazınca koşucu -UzunlukTavan 350 geçiyor ve üreticinin "dersin çıkmış p75'i" kuralı (SORU-BASMA-KURALLARI 1.3) devre dışı kalıyordu
  # (Maliyet p75 746, FMuh 414, hukuk 263–300). Tavan kalıptan: p75, taban 300; kalıp yoksa 350.
  $ad=$(if($KALIP_AD.ContainsKey($ders)){ $KALIP_AD[$ders] } else { $ders })
  if($kalip -and $kalip.dersler.PSObject.Properties[$ad] -and [int]$kalip.dersler.$ad.p75 -gt 0){ return [Math]::Max(300,[int]$kalip.dersler.$ad.p75) }
  return 350
}
# dersin anatomi zorluğu (02.09 ölçümü, 0-100): tek soruluk konuda seviye buna göre
$ANAT=@{ 'Maliyet Muhasebesi'=60;'Finansal Muhasebe'=30;'Mali Tablolar Analizi'=29;'Meslek Hukuku'=23;'Is ve Sosyal Guvenlik Hukuku'=22;'Ticaret Hukuku'=21;'Denetim'=18;'Vergi Hukuku'=17;'Maliye'=16;'Ekonomi'=15;'Turkce'=12;'Matematik'=10;'Ataturk Ilke ve Inkilap Tarihi'=9;'Yabanci Dil'=12;'Borclar Hukuku'=21 }
# 08.09 Cem "atladık demeyelim": analiz BÖLÜMÜ dersle uyuşmayan konu plana girmez (kök eşleşmesi "cümle bilgisi"ni FMuh'a, "Atatürk ilkeleri"ni
# FMuh'a yazmıştı → üretim para harcayıp hakemde DERS-DIŞI düşerdi). Bölüm → izinli dersler:
$BOLUM_DERS=@{ 'Muhasebe'=@('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Denetim'); 'Hukuk'=@('Vergi Hukuku','Ticaret Hukuku','Borclar Hukuku','Is ve Sosyal Guvenlik Hukuku','Meslek Hukuku'); 'Ekonomi'=@('Ekonomi'); 'Maliye'=@('Maliye'); 'Matematik-Istatistik'=@('Matematik'); 'Genel Kultur-Genel Yetenek'=@('Turkce','Ataturk Ilke ve Inkilap Tarihi'); 'Yabanci Dil'=@('Yabanci Dil') }
# 08.09 Tur 1 denetimi: huni etiketi olarak sızan ÇÖP konu adları ("okunamadi (2 soru - pdf iki sutun dizgisi)") plana girmez
$COP_KONU='(?i)okunamad|okunmad|bilinmiyor|belirsiz|\(\d+\s*soru|^\?+$|^\s*$'
$konular=@(); $dusen=@(); $cop=@(); $dislanan=@{}
foreach($p in $h.etiketDonemSay.PSObject.Properties){ $ders=("$($h.etiketDers.$($p.Name))" -replace '\*$',''); if(-not $SIN.ContainsKey($ders)){ continue }; if($DersSuz -and $ders -notmatch $DersSuz){ continue }
  if($Disla -and $ders -match $Disla){ if(-not $dislanan.ContainsKey($ders)){ $dislanan[$ders]=0 }; $dislanan[$ders]++; continue }
  if("$($p.Name)" -match $COP_KONU){ $cop+="$($p.Name) [$ders]"; continue }
  $bol=$(if($h.PSObject.Properties['etiketBolum'] -and $h.etiketBolum.PSObject.Properties[$p.Name]){ "$($h.etiketBolum.$($p.Name))" } else { '' })
  if($bol -and $BOLUM_DERS.ContainsKey($bol) -and ($BOLUM_DERS[$bol] -notcontains $ders)){ $dusen+="$($p.Name) [$bol→$ders]"; continue }
  $konular+=[pscustomobject]@{ konu=$p.Name; kez=[int]$p.Value; ders=$ders } }
if($dusen.Count){ "bölüm-ders uyumsuz, plana alınmadı ($($dusen.Count)): $(($dusen | Select-Object -First 12) -join ' · ')$(if($dusen.Count -gt 12){ ' …' })" }
if($cop.Count){ "çöp konu adı, plana alınmadı ($($cop.Count)): $($cop -join ' · ')" }
if($dislanan.Count){ "dışlanan dersler (-Disla): $(($dislanan.Keys | Sort-Object | ForEach-Object { "$_ ($($dislanan[$_]) konu)" }) -join ' · ')" }
$konuDir=Join-Path $kok 'veri\sinav\konu'; New-Item -ItemType Directory -Force $konuDir | Out-Null
$plan=@(); $toplam=0
foreach($g in ($konular | Group-Object ders | Sort-Object { -$SIN[$_.Name].s })){
  $ders=$g.Name; $bilgi=$SIN[$ders]; $tavan=DersTavan $ders
  # seviye listeleri: kolay / zor / cokzor → her seviyeye giren konular
  $sev=@{ kolay=@(); zor=@(); cokzor=@() }
  foreach($x in $g.Group){
    if($Formul -eq 'A'){ foreach($sv in 'kolay','zor','cokzor'){ $sev[$sv]+=$x.konu } }   # 3 × kez: tur sayısı = kez (aynı konu sonraki turda benzerlik kapısıyla özgün)
    else { if($x.kez -ge 2){ foreach($sv in 'kolay','zor','cokzor'){ $sev[$sv]+=$x.konu } } else { $a=$ANAT[$ders]; $sv=$(if($a -ge 28){ 'zor' } elseif($a -ge 15){ 'zor' } else { 'kolay' }); $sev[$sv]+=$x.konu } }
  }
  foreach($sv in 'kolay','zor','cokzor'){ $liste=@($sev[$sv] | Select-Object -Unique); if(-not $liste.Count){ continue }
    $kd=Join-Path $konuDir "$Ad-$($bilgi.k)-$sv.json"; [IO.File]::WriteAllText($kd,(ConvertTo-Json -InputObject @($liste) -Depth 2),[Text.UTF8Encoding]::new($false))
    $plan+=[pscustomobject]@{ ders=$bilgi.r; dersAd=$ders; etiket="$Ad-$($bilgi.k)-$sv"; adet=$liste.Count; tavan=$tavan; zorluk=$sv; sinav='SGS'; konuDosya=$kd; toplu=[bool]$Toplu; disla=''; tur=$Tur }
    $toplam+=$liste.Count }
}
$planYol=Join-Path $kok "veri\sinav\plan-$Ad.json"; [IO.File]::WriteAllText($planYol,(ConvertTo-Json -InputObject @($plan) -Depth 3),[Text.UTF8Encoding]::new($false))
"yazildi: $planYol · $($plan.Count) satır · $toplam soru (formül $Formul, tur $Tur, toplu $([bool]$Toplu)) · ≈$([math]::Round($toplam*0.45*$(if($Toplu){0.55}else{1}))) USD (0,25/soru varsayımı; pilot ölçümü ayrı okunur)"
$plan | Group-Object dersAd | ForEach-Object { "  {0,-32} {1,5} soru · tavan {2,3} kr ({3})" -f $_.Name,(($_.Group | Measure-Object adet -Sum).Sum),$_.Group[0].tavan,(($_.Group | ForEach-Object { "$($_.zorluk) $($_.adet)" }) -join ' · ') }
# 08.09 Tur 1 denetimi: koşucu dersleri ARDIŞIK koşar; anlık fazlar (sim, hakem, kapı tekrarı) soru başına ≈1–1,5 dk → 1.500 soru tek hatta ≈30 saat.
# -Parca N: satırlar soru sayısına göre N dengeli dosyaya bölünür (plan-<ad>-p1..pN.json); her biri ayrı koşucu sürecinde paralel koşar.
if($Parca -gt 1){
  $kova=@(1..$Parca | ForEach-Object { [pscustomobject]@{ satir=@(); yuk=0 } })
  foreach($s in ($plan | Sort-Object { -[int]$_.adet })){ $en=$kova | Sort-Object yuk | Select-Object -First 1; $en.satir+=$s; $en.yuk+=[int]$s.adet }
  for($i=0;$i -lt $Parca;$i++){ $py=Join-Path $kok "veri\sinav\plan-$Ad-p$($i+1).json"; [IO.File]::WriteAllText($py,(ConvertTo-Json -InputObject @($kova[$i].satir) -Depth 3),[Text.UTF8Encoding]::new($false)); "  parça $($i+1): $($kova[$i].satir.Count) satır · $($kova[$i].yuk) soru -> $py" }
}
