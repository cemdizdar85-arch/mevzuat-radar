# ============================================================================
#  KGK CEVAP ANAHTARI ÇIKARIMI (04.09.2026, Cem "1 yap": KGK anahtarlarını ayıkla)
#
#  GİRDİ (yerel, gitignore): veri/kgk-arsiv/pdf/*.duz.txt
#   (a) 10202_{A|B}_KİTAPÇIĞI-{SABAH|ÖĞLEDENSONRA}-CEVAPANAHTARI  — 29.06.2019 sınavı; modüller SÜTUN hâlinde ("1. D"),
#       sütunlar x-konumuyla ayrılır; sabah 4 modül (Muhasebe Standartları · SPK-Bankacılık-Sigortacılık · Kurumsal Yönetim
#       ve Finansal Yönetim · Denetim), öğleden sonra 2 modül (Muhasebe · Genel Hukuk Mevzuatı).
#   (b) 8166_{Birinci|İkinci}_Oturum_{A|B}_Grubu_Sınav_Soru_ve_Cevapları — 11.11.2018; sonda "CEVAP ANAHTARI" bloğu,
#       OCR'lu ve gürültülü ("il D", "5... C", "4 C"); satır = bir soru numarası, sütun sırası = modül sırası.
#  ÇIKTI: veri/kgk-cevap-anahtari.json  { oturumlar: { "<dosya kökü>": { tarih, kitapcik, oturum, moduller:{ad:{no:harf}}, uyari } } }
#  KURAL: belirsiz/okunamayan hücre yazılmaz; sayım ve uyarı raporlanır. Elle düzenlenmez.
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$dir=Join-Path $kok 'veri\kgk-arsiv\pdf'
if(-not (Test-Path $dir)){ Write-Host 'KÖR: veri/kgk-arsiv yok (yalnız yerelde). Dosyaya dokunulmadı.'; exit 0 }
$SABAH=@('Muhasebe Standartları','Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı','Kurumsal Yönetim İlkeleri ve Finansal Yönetim','Denetim')
$OS=@('Muhasebe','Genel Hukuk Mevzuatı')
$oturumlar=[ordered]@{}
# --- (a) 10202: sütunlu düzen ------------------------------------------------------------------
foreach($f in (Get-ChildItem $dir -Filter '10202_*CEVAPANAHTARI.duz.txt' | Sort-Object Name)){
  $t=[IO.File]::ReadAllText($f.FullName)
  $kitapcik=$(if($f.Name -match '10202_([AB])_'){ $Matches[1] } else { '?' })
  $sabahMi=($f.Name -match '(?i)SABAH')
  $modAd=$(if($sabahMi){ $SABAH } else { $OS })
  # token: "N. X" ve satır içi karakter konumu
  $tok=New-Object System.Collections.Generic.List[object]
  foreach($satir in ($t -split "`n")){ foreach($m in [regex]::Matches($satir,'(?<![\d])(\d{1,3})\.\s+([A-E])(?![A-Za-zÇĞİÖŞÜ])')){ $tok.Add([pscustomobject]@{ x=$m.Index; no=[int]$m.Groups[1].Value; harf=$m.Groups[2].Value }) } }
  # sütun kümeleri: x konumları sıralanır, 6 karakterden büyük boşluk yeni sütun
  $xs=@($tok | ForEach-Object { $_.x } | Sort-Object -Unique); $kume=@(); $cur=@()
  foreach($x in $xs){ if($cur.Count -and ($x-$cur[-1]) -gt 6){ $kume+=,$cur; $cur=@() }; $cur+=$x }; if($cur.Count){ $kume+=,$cur }
  $uyari=@(); if($kume.Count -ne $modAd.Count){ $uyari+="sütun sayısı $($kume.Count), beklenen $($modAd.Count)" }
  $moduller=[ordered]@{}
  for($ci=0;$ci -lt [math]::Min($kume.Count,$modAd.Count);$ci++){
    $h=[ordered]@{}; $set=$kume[$ci]
    foreach($tk in ($tok | Where-Object { $set -contains $_.x } | Sort-Object no)){ if(-not $h.Contains("$($tk.no)")){ $h["$($tk.no)"]=$tk.harf } }
    $nolar=@($h.Keys | ForEach-Object { [int]$_ } | Sort-Object); if($nolar.Count -and -not ($nolar[0] -eq 1 -and $nolar[-1] -eq $nolar.Count)){ $uyari+="$($modAd[$ci]): numaralar kesintili ($($nolar[0])-$($nolar[-1]), $($nolar.Count) adet)" }
    $moduller[$modAd[$ci]]=$h
  }
  $oturumlar[($f.BaseName -replace '\.duz$','')]=[ordered]@{ tarih='2019-06-29'; kitapcik=$kitapcik; oturum=$(if($sabahMi){'sabah'}else{'ogleden-sonra'}); kaynak=$f.Name; moduller=$moduller; uyari=$uyari }
}
# --- (b) 8166: OCR'lu satır düzeni ----------------------------------------------------------------
foreach($f in (Get-ChildItem $dir -Filter '8166_*Cevaplar*.duz.txt' | Sort-Object Name)){
  $t=[IO.File]::ReadAllText($f.FullName)
  $kitapcik=$(if($f.Name -match '_([AB])_Grubu'){ $Matches[1] } else { '?' })
  $birinci=($f.Name -match '(?i)Birinci'); $modAd=$(if($birinci){ $SABAH } else { $OS })
  $bas=[regex]::Match($t,'(?i)CEVAP ANAHTARI'); if(-not $bas.Success){ $oturumlar[$f.BaseName]=[ordered]@{ tarih='2018-11-11'; kitapcik=$kitapcik; oturum=$(if($birinci){'sabah'}else{'ogleden-sonra'}); kaynak=$f.Name; moduller=@{}; uyari=@('CEVAP ANAHTARI bloğu yok') }; continue }
  $blok=$t.Substring($bas.Index)
  $moduller=[ordered]@{}; foreach($ad in $modAd){ $moduller[$ad]=[ordered]@{} }
  $sonNo=@(0)*$modAd.Count; $uyari=@(); $satirSay=0
  foreach($satir in ($blok -split "`n")){
    # OCR: "1." → "il"/"Il."/"iL"/"LL"; nokta yerine virgül ("34, C"); "4 C" noktasız
    $tk=@([regex]::Matches($satir,'(?:(\d{1,2})|[iIlL]{1,2})\s*[.,]{0,3}\s*([A-E])(?![A-Za-zÇĞİÖŞÜ])'))
    if($tk.Count -ne $modAd.Count){ if($tk.Count -gt 0){ $uyari+="satır atlandı ($($tk.Count) hücre): $($satir.Trim())" }; continue }
    $satirSay++
    for($ci=0;$ci -lt $tk.Count;$ci++){
      $noS=$tk[$ci].Groups[1].Value; $no=$(if($noS){ [int]$noS } else { $sonNo[$ci]+1 })
      # OCR "1." kaybı: "il"→1, tek haneli sapma (19→9) → önceki+1 ile tutarlıysa onu al
      if($noS -and $no -ne $sonNo[$ci]+1 -and ($sonNo[$ci]+1) -ge 10 -and "$($sonNo[$ci]+1)".EndsWith($noS)){ $no=$sonNo[$ci]+1 }
      if(-not $moduller[$modAd[$ci]].Contains("$no")){ $moduller[$modAd[$ci]]["$no"]=$tk[$ci].Groups[2].Value }
      $sonNo[$ci]=$no
    }
  }
  foreach($ad in $modAd){ $nolar=@($moduller[$ad].Keys | ForEach-Object { [int]$_ } | Sort-Object); if(-not $nolar.Count -or -not ($nolar[0] -eq 1 -and $nolar[-1] -eq $nolar.Count)){ $uyari+="$ad`: numaralar kesintili ($(if($nolar.Count){"$($nolar[0])-$($nolar[-1]), $($nolar.Count) adet"}else{'boş'}))" } }
  $oturumlar[$f.BaseName]=[ordered]@{ tarih='2018-11-11'; kitapcik=$kitapcik; oturum=$(if($birinci){'sabah'}else{'ogleden-sonra'}); kaynak=$f.Name; ocr=$true; satir=$satirSay; moduller=$moduller; uyari=$uyari }
}
$toplam=0; foreach($o in $oturumlar.Values){ foreach($mm in $o.moduller.Values){ $toplam+=$mm.Count } }
$cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); sinav='KGK'; kaynak='veri/kgk-arsiv/pdf cevap anahtarı PDF metinleri (2019 sütunlu, 2018 OCR)'; oturum=$oturumlar.Count; cevap=$toplam; oturumlar=$oturumlar }
$null=RaporYaz -Hedef (Join-Path $kok 'veri\kgk-cevap-anahtari.json') -Nesne $cikti -Derinlik 6 -Sessiz:$Sessiz
if(-not $Sessiz){ Write-Host ("KGK cevap anahtarı: {0} oturum · {1} cevap" -f $oturumlar.Count,$toplam); foreach($k1 in $oturumlar.Keys){ $o=$oturumlar[$k1]; Write-Host ("  {0}: {1} · uyarı {2}" -f $k1,(($o.moduller.Keys | ForEach-Object { "$_=$($o.moduller[$_].Count)" }) -join ', '),$o.uyari.Count); foreach($u in $o.uyari){ Write-Host "     ! $u" } } }
