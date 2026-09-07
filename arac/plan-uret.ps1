# PLAN ÜRETİCİ (08.09, Cem: "konu konu formül yapalım, 2×A basalım") — 0 USD
# Huninin pencere konularından (son 7 dönem, etiket → ders → kez) ders × seviye plan satırları ve konu dosyaları üretir; koşucu bunu okur.
#   Formül A : her konu 3 × kez soru (her kez için kolay/zor/çok zor birer) → seviye geçişi: kez kadar tekrar (tur)
#   Formül E : 1 kez çıkan konu 1 soru (dersin anatomisine göre seviye), 2+ kez 3 soru (üç seviye)
# Çıktı: veri/sinav/plan-<ad>.json (koşucu planı) + veri/sinav/konu/<ad>-<ders>-<seviye>.json (konu adı listesi, üretici -KonuDosya)
# Kullanım: powershell -NoProfile -File arac/plan-uret.ps1 -Ad sgs-t1 -Formul A -Toplu
param([string]$Ad='sgs-t1',[ValidateSet('A','E')][string]$Formul='A',[switch]$Toplu,[int]$Tur=1,[string]$DersSuz='')
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
$huniYol=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$h=ConvertFrom-Json -InputObject (Get-Content $huniYol -Raw -Encoding UTF8)
$SIN=@{ 'Finansal Muhasebe'=@{s=26;r='Finansal Muhasebe';t=350;k='fmuh'}; 'Denetim'=@{s=16;r='Denetim';t=350;k='denetim'}; 'Yabanci Dil'=@{s=10;r='Yabanci Dil';t=350;k='yd'}; 'Matematik'=@{s=8;r='Matematik';t=350;k='mat'}; 'Maliyet Muhasebesi'=@{s=8;r='Maliyet Muhasebesi';t=600;k='maliyet'}; 'Mali Tablolar Analizi'=@{s=8;r='Mali Tablolar Analizi';t=350;k='mta'}; 'Turkce'=@{s=7;r='Turkce';t=350;k='turkce'}; 'Ekonomi'=@{s=6;r='Ekonomi';t=350;k='ekonomi'}; 'Maliye'=@{s=6;r='Maliye';t=350;k='maliye'}; 'Meslek Hukuku'=@{s=6;r='Meslek Hukuku';t=350;k='meslek'}; 'Is ve Sosyal Guvenlik Hukuku'=@{s=6;r='Is ve Sosyal Guvenlik Hukuku';t=350;k='issgk'}; 'Vergi Hukuku'=@{s=6;r='Vergi Hukuku';t=350;k='vergi'}; 'Ticaret Hukuku'=@{s=6;r='Ticaret Hukuku';t=350;k='ticaret'}; 'Borclar Hukuku'=@{s=6;r='Borclar Hukuku';t=350;k='borclar'}; 'Ataturk Ilke ve Inkilap Tarihi'=@{s=5;r='Ataturk Ilke ve Inkilap Tarihi';t=350;k='inkilap'} }
# dersin anatomi zorluğu (02.09 ölçümü, 0-100): tek soruluk konuda seviye buna göre
$ANAT=@{ 'Maliyet Muhasebesi'=60;'Finansal Muhasebe'=30;'Mali Tablolar Analizi'=29;'Meslek Hukuku'=23;'Is ve Sosyal Guvenlik Hukuku'=22;'Ticaret Hukuku'=21;'Denetim'=18;'Vergi Hukuku'=17;'Maliye'=16;'Ekonomi'=15;'Turkce'=12;'Matematik'=10;'Ataturk Ilke ve Inkilap Tarihi'=9;'Yabanci Dil'=12;'Borclar Hukuku'=21 }
$konular=@(); foreach($p in $h.etiketDonemSay.PSObject.Properties){ $ders=("$($h.etiketDers.$($p.Name))" -replace '\*$',''); if(-not $SIN.ContainsKey($ders)){ continue }; if($DersSuz -and $ders -notmatch $DersSuz){ continue }; $konular+=[pscustomobject]@{ konu=$p.Name; kez=[int]$p.Value; ders=$ders } }
$konuDir=Join-Path $kok 'veri\sinav\konu'; New-Item -ItemType Directory -Force $konuDir | Out-Null
$plan=@(); $toplam=0
foreach($g in ($konular | Group-Object ders | Sort-Object { -$SIN[$_.Name].s })){
  $ders=$g.Name; $bilgi=$SIN[$ders]
  # seviye listeleri: kolay / zor / cokzor → her seviyeye giren konular
  $sev=@{ kolay=@(); zor=@(); cokzor=@() }
  foreach($x in $g.Group){
    if($Formul -eq 'A'){ foreach($sv in 'kolay','zor','cokzor'){ $sev[$sv]+=$x.konu } }   # 3 × kez: tur sayısı = kez (aynı konu sonraki turda benzerlik kapısıyla özgün)
    else { if($x.kez -ge 2){ foreach($sv in 'kolay','zor','cokzor'){ $sev[$sv]+=$x.konu } } else { $a=$ANAT[$ders]; $sv=$(if($a -ge 28){ 'zor' } elseif($a -ge 15){ 'zor' } else { 'kolay' }); $sev[$sv]+=$x.konu } }
  }
  foreach($sv in 'kolay','zor','cokzor'){ $liste=@($sev[$sv] | Select-Object -Unique); if(-not $liste.Count){ continue }
    $kd=Join-Path $konuDir "$Ad-$($bilgi.k)-$sv.json"; [IO.File]::WriteAllText($kd,(ConvertTo-Json -InputObject @($liste) -Depth 2),[Text.UTF8Encoding]::new($false))
    $plan+=[pscustomobject]@{ ders=$bilgi.r; etiket="$Ad-$($bilgi.k)-$sv"; adet=$liste.Count; tavan=$bilgi.t; zorluk=$sv; sinav='SGS'; konuDosya=$kd; toplu=[bool]$Toplu; disla=''; tur=$Tur }
    $toplam+=$liste.Count }
}
$planYol=Join-Path $kok "veri\sinav\plan-$Ad.json"; [IO.File]::WriteAllText($planYol,(ConvertTo-Json -InputObject @($plan) -Depth 3),[Text.UTF8Encoding]::new($false))
"yazildi: $planYol · $($plan.Count) satır · $toplam soru (formül $Formul, tur $Tur, toplu $([bool]$Toplu)) · ≈$([math]::Round($toplam*0.45*$(if($Toplu){0.55}else{1}))) USD"
$plan | Group-Object ders | ForEach-Object { "  {0,-32} {1,5} soru ({2})" -f $_.Name,(($_.Group | Measure-Object adet -Sum).Sum),(($_.Group | ForEach-Object { "$($_.zorluk) $($_.adet)" }) -join ' · ') }
