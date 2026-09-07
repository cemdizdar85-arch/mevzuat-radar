# ESKİ SGS KASASI → v29 KALIBI HUNİSİ (07.09.2026 gece, Cem: "önce bedava süz, sonra azını yenile; eksik yerleri tamamlarız")
# 0 USD, API yok. Girdi: veri/fabrika/eski-sgs-dump-<tarih>.json (soru_havuzu SGS dökümü), veri/yayin-havuzu-olcum.json (kapı-temiz idler),
# veri/sgs-analiz.json (son N dönem konu etiketleri). Çıktı: sql-yerel/ESKI-SGS-HUNI-<tarih>.md + veri/fabrika/eski-sgs-huni-<tarih>.json
# Huni katmanları (her ders için): KASA → KAPI-TEMİZ (K1–K17 + kara liste) → KAYNAK DAMGALI → PENCEREDE (son N dönem konusu) = KALIBA ADAY.
# Ayrıca pencere etiketlerinden hiç adayı olmayanlar = YENİ BASIM listesi (Cem'in "eksik olduğumuz yerler").
# Kök eşleşmesi kalip-parti-uret.ps1 KokOnek/Katla2 ile AYNI (07.09 kopya; iki yerde yaşıyor, Ö63 düzeltmesi ikisine de uygulanır).
param([string]$Dump='',[int]$DonemPencere=7,[string]$Tarih=(Get-Date -Format yyyyMMdd))
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
if(-not $Dump){ $Dump=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-dump-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName }
function Katla2([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
function KokOnek([string]$s){ $t=(Katla2 $s) -replace '[^a-z0-9 ]',' '; $es=@{ 'evre'='safha'; 'gug'='genel'; 'ilk'='ilk'; 'dimm'='ilk'; 'esdeger'='esdeger' }
  @(($t -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|ile|veya|icin|bir|olan|sistemi|yontemi|sistem|yontem|hesaplama|hesabi|kaydi|kayit|analizi|analiz|orani|oran|tablosu|tablo|muhasebesi|muhasebe)$' } | ForEach-Object { $w=$_; if($es.ContainsKey($w)){ $w=$es[$w] }; if($w.Length -gt 5){ $w.Substring(0,5) } else { $w } } | Select-Object -Unique) }
# --- girdiler
$sorular=@(ConvertFrom-Json -InputObject (Get-Content $Dump -Raw -Encoding UTF8)); if($sorular.Count -eq 1 -and $sorular[0].PSObject.Properties['SyncRoot']){ $sorular=@($sorular[0].SyncRoot) }
$olc=Get-Content (Join-Path $kok 'veri\yayin-havuzu-olcum.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$temiz=New-Object 'System.Collections.Generic.HashSet[string]'; foreach($x in @($olc.idler)){ $id=$(if($x -is [string]){ $x } else { "$($x.id)" }); if($id){ [void]$temiz.Add($id) } }
$anJ=Get-Content (Join-Path $kok 'veri\sgs-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$dList=New-Object System.Collections.Generic.List[object]; $anJ.donemler | ForEach-Object { $dList.Add($_) }
$sonD=@($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $DonemPencere)
$etiket=@{}   # kök anahtarı -> @{ ad=ilk etiket; bolum=analiz bölümü; donemler=@{} }
foreach($dn in $sonD){ foreach($p in @($dn.konuSayim.PSObject.Properties)){ $bol=($p.Name -split '\|')[0]; $lab=($p.Name -replace '^[^|]*\|',''); $kk=(KokOnek $lab) -join ' '; if(-not $kk){ continue }; if(-not $etiket.ContainsKey($kk)){ $etiket[$kk]=@{ ad=$lab; bolum=$bol; donemler=@{}; kokler=@($kk -split ' ') } }; $etiket[$kk].donemler["$($dn.donem)"]=1 } }
"GİRDİ: soru $($sorular.Count) · kapı-temiz id $($temiz.Count) · pencere $(($sonD | ForEach-Object { $_.donem }) -join ', ') · etiket $($etiket.Count)"
# --- eşleme: soru konusu -> pencere etiketleri (ortak kök ≥ min(2, kök sayısı))
$genelDers=@('Turkce','Matematik','Ataturk Ilkeleri ve Inkilap Tarihi','Ataturk Ilke ve Inkilap Tarihi','Yabanci Dil')
$konuKok=@{}; $etiketAday=@{}; foreach($e in $etiket.Keys){ $etiketAday[$e]=New-Object System.Collections.ArrayList }
# hız: kök -> etiket listesi dizini (15.827 soru × 1.500 etiket doğrudan taramada 10+ dk sürüyordu); konu başına eşleme bir kez hesaplanır
$kokIdx=@{}; foreach($e in $etiket.Keys){ foreach($kk in $etiket[$e].kokler){ if(-not $kokIdx.ContainsKey($kk)){ $kokIdx[$kk]=New-Object System.Collections.ArrayList }; [void]$kokIdx[$kk].Add($e) } }
$konuEs=@{}
$satir=New-Object System.Collections.ArrayList
foreach($s in $sorular){
  $konu="$($s.konu)"; if(-not $konuKok.ContainsKey($konu)){ $konuKok[$konu]=@(KokOnek $konu) }; $kokler=$konuKok[$konu]
  if(-not $konuEs.ContainsKey($konu)){ $bul=@(); if($kokler.Count){ $gerek=[Math]::Min(2,$kokler.Count); $say=@{}; foreach($kk in $kokler){ if($kokIdx.ContainsKey($kk)){ foreach($e in $kokIdx[$kk]){ if(-not $say.ContainsKey($e)){ $say[$e]=0 }; $say[$e]++ } } }; foreach($e in $say.Keys){ if($say[$e] -ge $gerek){ $bul+=$e } } }; $konuEs[$konu]=$bul }
  $es=$konuEs[$konu]
  $kapi=$temiz.Contains("$($s.id)")
  $genel=($genelDers -contains "$($s.ders)")
  $damga=$genel -or (("$($s.kanun_no)".Trim() -ne '' -and "$($s.kanun_no)".Trim() -ne 'YOK') -or "$($s.madde_damga)".Trim() -ne '' -or "$($s.dayanak)".Trim() -ne '')
  $hesapli=[bool]("$($s.cozum_tablo)".Trim() -or "$($s.tablo)".Trim() -or ("$($s.soru)" -match '(?<![\d.,])\d{1,3}(?:\.\d{3})+(?![\d.,])'))
  $aday=($kapi -and $damga -and $es.Count -gt 0)
  if($aday){ foreach($e in $es){ [void]$etiketAday[$e].Add("$($s.id)") } }
  [void]$satir.Add([pscustomobject]@{ id="$($s.id)"; ders="$($s.ders)"; konu=$konu; kapi=$kapi; damga=$damga; pencere=($es.Count -gt 0); pencereEtiket=$es; hesapli=$hesapli; aday=$aday; yayin=[bool]$s.yayin; zorluk="$($s.zorluk)" })
}
# --- ders tablosu
$dersler=@($satir | Group-Object ders | Sort-Object Name)
$tab=@(); foreach($g in $dersler){ $r=@($g.Group); $tab+=[pscustomobject]@{ ders=$g.Name; kasa=$r.Count; kapiTemiz=@($r | Where-Object kapi).Count; damgali=@($r | Where-Object { $_.kapi -and $_.damga }).Count; pencerede=@($r | Where-Object { $_.kapi -and $_.damga -and $_.pencere }).Count; aday=@($r | Where-Object aday).Count; adayHesap=@($r | Where-Object { $_.aday -and $_.hesapli }).Count; adayTeori=@($r | Where-Object { $_.aday -and -not $_.hesapli }).Count } }
# --- pencere etiketleri: kapsanan / boş (yeni basım)
$bos=@(); $dolu=0; foreach($e in $etiket.Keys){ $n=$etiketAday[$e].Count; if($n -eq 0){ $bos+=[pscustomobject]@{ bolum=$etiket[$e].bolum; konu=$etiket[$e].ad; donem=$etiket[$e].donemler.Count; donemler=(($etiket[$e].donemler.Keys | Sort-Object -Descending) -join ' ') } } else { $dolu++ } }
$bos=@($bos | Sort-Object { -$_.donem }, bolum, konu)
# --- çıktı
$md=New-Object System.Text.StringBuilder
[void]$md.AppendLine("# ESKİ SGS KASASI → v29 KALIBI HUNİSİ ($(Get-Date -Format 'dd.MM.yyyy HH:mm'))")
[void]$md.AppendLine("")
[void]$md.AppendLine("Kaynak: $(Split-Path $Dump -Leaf) ($($sorular.Count) soru) · kapı-temiz kümesi veri/yayin-havuzu-olcum.json ($($temiz.Count) id, $($olc.tarih)) · pencere son $DonemPencere dönem: $(($sonD | ForEach-Object { $_.donem }) -join ', ') ($($etiket.Count) konu etiketi).")
[void]$md.AppendLine("Katmanlar: KASA → KAPI-TEMİZ (K1–K17, kara liste) → KAYNAK DAMGALI (kanun_no/madde/dayanak; genel kültürde şart değil) → PENCEREDE (konu kökü son $DonemPencere dönem etiketiyle eşleşir) = **KALIBA ADAY**. Aday = yarı yenilemeye girer; kalıp kapıları (çeldirici, kör çözüm, hakem) orada ayrıca eler.")
[void]$md.AppendLine("")
[void]$md.AppendLine("## 1 · Ders hunisi")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Ders | Kasa | Kapı-temiz | +Damgalı | +Pencerede = ADAY | Aday hesap | Aday teori |")
[void]$md.AppendLine("|---|---:|---:|---:|---:|---:|---:|")
foreach($t in $tab){ [void]$md.AppendLine("| $($t.ders) | $($t.kasa) | $($t.kapiTemiz) | $($t.damgali) | **$($t.aday)** | $($t.adayHesap) | $($t.adayTeori) |") }
$T=[pscustomobject]@{ kasa=($tab | Measure-Object kasa -Sum).Sum; kapi=($tab | Measure-Object kapiTemiz -Sum).Sum; damga=($tab | Measure-Object damgali -Sum).Sum; aday=($tab | Measure-Object aday -Sum).Sum }
[void]$md.AppendLine("| **TOPLAM** | $($T.kasa) | $($T.kapi) | $($T.damga) | **$($T.aday)** | | |")
[void]$md.AppendLine("")
[void]$md.AppendLine("## 2 · Pencere konuları: kapsanan $dolu · **boş $($bos.Count)** (boş = eski kasada adayı yok → yeni basım)")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Bölüm (analiz) | Konu etiketi | Kaç dönem | Dönemler |")
[void]$md.AppendLine("|---|---|---:|---|")
foreach($b in $bos){ [void]$md.AppendLine("| $($b.bolum) | $($b.konu) | $($b.donem) | $($b.donemler) |") }
[void]$md.AppendLine("")
[void]$md.AppendLine("## 3 · Okuma notu")
[void]$md.AppendLine("- Kök eşleşmesi üreticiyle aynı (5 harf önek, ≥2 ortak kök); Ö63'teki şişme burada da vardır → 'pencerede' sayısı iyimser, 'boş' listesi güvenilir yönde (boşsa gerçekten yok).")
[void]$md.AppendLine("- Aday ≠ yayınlanabilir. Aday, yarı yenilemeye (uyarlama fazı + kalıp kapıları) girme hakkı kazanan sorudur.")
[void]$md.AppendLine("- Genel kültür derslerinde kaynak damgası aranmadı (kaynak mevzuat değil); kalıp uyumu ayrı ölçülür.")
$mdYol=Join-Path $kok "sql-yerel\ESKI-SGS-HUNI-$Tarih.md"; [IO.File]::WriteAllText($mdYol,$md.ToString(),[Text.UTF8Encoding]::new($false))
$jsYol=Join-Path $kok "veri\fabrika\eski-sgs-huni-$Tarih.json"; [IO.File]::WriteAllText($jsYol,(ConvertTo-Json -InputObject @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); dump=(Split-Path $Dump -Leaf); pencere=@($sonD | ForEach-Object { $_.donem }); ders=$tab; bosKonu=$bos; adayIdler=@($satir | Where-Object aday | ForEach-Object { [pscustomobject]@{ id=$_.id; ders=$_.ders; konu=$_.konu; hesapli=$_.hesapli } }) } -Depth 6 -Compress),[Text.UTF8Encoding]::new($false))
"yazildi: $mdYol · $jsYol"
$tab | Format-Table -AutoSize | Out-String -Width 200
"TOPLAM aday: $($T.aday) · boş pencere konusu: $($bos.Count) / $($etiket.Count)"
