# ============================================================================
#  SINAV EXCEL — "sınav sınav gideceğiz" (03.09.2026, Cem)
#
#  Tek sınav için Cem'in okuyacağı Excel: dersler · çıkmış dersler · bütün konular
#  (bizim / çıkmış / dayanak / ambarda var mı / üretilebilir mi) · eksikler · GM notu.
#  Hiçbir şeyi kendisi ölçmez; robot çıktılarını birleştirir:
#    veri/ders-profili.json            resmî ders listesi + sınavdaki soru sayısı
#    veri/kasa-sayim.json              bizim soru (canlı sayım)
#    veri/*-uretim-kotasi.json         onaylı kota
#    veri/fabrika/konu-koprusu.json    konu köprüsü V2 (bizim ↔ çıkmış, dayanak, dönem)
#    veri/fabrika/dayanak-durum.json   her dayanağın ambar durumu (metinsiz tarama)
#    veri/konu-kaynak-karnesi*.json    çıkmış konu → ambarda kaynak kararı
#    veri/<sinav>-analiz.json          çıkmış arşiv (dönem × ders)
#    veri/dayanak-kara-liste.json      güvenilmez dayanaklar
#  Excel COM ile yazar (bu makinede Office 16 var; python yok). Çıktı: sql-yerel/SINAV-<SINAV>-<tarih>.xlsx
#  ⚠ PS 5.1: @($list) ve [ordered]@{ a=@() } tuzakları — .ToArray() ve tek tek atama.
# ============================================================================
param([string]$Sinav='SGS',[string]$Cikti='')
$ErrorActionPreference='Stop'
$here=if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$depoKok=Split-Path -Parent $here
function Yukle([string]$yol){ $tam=Join-Path $depoKok $yol; if(-not (Test-Path $tam)){ return $null }; return (Get-Content $tam -Raw -Encoding UTF8 | ConvertFrom-Json) }
function Norm([string]$metin){
  $s="$metin".Replace([char]0x0130,'I').Replace([char]0x0131,'i').Replace([char]0x015E,'S').Replace([char]0x015F,'s').Replace([char]0x011E,'G').Replace([char]0x011F,'g').Replace([char]0x00DC,'U').Replace([char]0x00FC,'u').Replace([char]0x00D6,'O').Replace([char]0x00F6,'o').Replace([char]0x00C7,'C').Replace([char]0x00E7,'c').ToLowerInvariant()
  $s=$s -replace '[çÇ]','c' -replace '[ğĞ]','g' -replace '[ıİİ]','i' -replace '[öÖ]','o' -replace '[şŞ]','s' -replace '[üÜ]','u'
  $s=$s -replace '[^a-z0-9| ]',' ' -replace '\s+',' '
  return $s.Trim()
}
function Katla([string]$metin){ return ((Norm $metin) -replace '[^a-z0-9]','') }
$DERS_ESANLAM=@{ 'ataturkilkeveinkilaptarihi'='ataturkilkeleriveinkilaptarihi'; 'muhvemalimusmeslekhukuku'='muhasebecilikvemalimusavirlikmeslekhukuku'; 'muhasebestandartlari'='turkiyemuhasebestandartlari'; 'denetimstandartlari'='turkiyedenetimstandartlari'; 'kurumsalyonetim'='kurumsalyonetimilkelerivefinansalyonetim'; 'finansalyonetim'='kurumsalyonetimilkelerivefinansalyonetim'; 'surdurulebilirlikraporlamasi'='kurumsalsurdurulebilirlikraporlamasi'; 'surdurulebilirlik'='kurumsalsurdurulebilirlikraporlamasi' }
function DersAnahtar([string]$ders){ $sade="$ders" -replace '^\s*[a-zçğıöşü]\)\s*','' -replace '\([^)]*\)','' -replace '\[[^\]]*\]',''; $k=Katla $sade; if($DERS_ESANLAM.ContainsKey($k)){ return $DERS_ESANLAM[$k] }; return $k }
function Sayi($v){ $n=0; if([int]::TryParse("$v",[ref]$n)){ return $n }; return 0 }

$SINAV_UZUN=@{ 'SGS'='STAJA BAŞLAMA (SGS)'; 'SMMM'='STAJ BİTİRME / YETERLİLİK (SMMM)'; 'KGK'='BAĞIMSIZ DENETÇİLİK (KGK)'; 'SPL'='SPK LİSANSLAMA (SPL)' }
$ANALIZ=@{ 'SGS'='veri\sgs-analiz.json'; 'SMMM'='veri\smmm-analiz.json'; 'KGK'='veri\kgk-analiz.json' }
$KARNE=@{ 'SGS'='veri\konu-kaynak-karnesi.json'; 'SMMM'='veri\konu-kaynak-karnesi-smmm.json'; 'KGK'='veri\konu-kaynak-karnesi-kgk.json' }
$KOTA=@{ 'SGS'='veri\sgs-uretim-kotasi.json'; 'SMMM'='veri\uretim-kotasi.json'; 'KGK'='veri\kgk-uretim-kotasi.json' }
$simdi=Get-Date

# --- girdiler ---
$profil=Yukle 'veri\ders-profili.json'
$kasa=Yukle 'veri\kasa-sayim.json'
$kopruTam=Yukle 'veri\fabrika\konu-koprusu.json'
$dayanakDurum=Yukle 'veri\fabrika\dayanak-durum.json'
$karne=Yukle $KARNE[$Sinav]
$analiz=Yukle $ANALIZ[$Sinav]
$kota=Yukle $KOTA[$Sinav]
$kara=Yukle 'veri\dayanak-kara-liste.json'
$kopruOzet=Yukle 'veri\konu-koprusu-ozet.json'
if(-not $profil -or -not $kopruTam -or -not $dayanakDurum){ throw 'girdi eksik: ders-profili / konu-koprusu / dayanak-durum' }
$karaListe=@(); if($kara -and $kara.kara_liste){ $karaListe=@($kara.kara_liste | ForEach-Object { "$_" }) }
$durumSoz=@{}; foreach($p in $dayanakDurum.PSObject.Properties){ $durumSoz[$p.Name]="$($p.Value)" }
function DayanakDurumu([string]$d){ $d=("$d" -replace '\s*\(\d+\)\s*$','' -replace '\s*⚠.*$','').Trim(); if(-not $d){ return '' }; if($durumSoz.ContainsKey($d)){ return $durumSoz[$d] }; return 'ÖLÇÜLMEDİ' }

# --- 1) DERSLER ---
$sinavUzun=$SINAV_UZUN[$Sinav]
$dersProfil=$profil.sinavlar.$sinavUzun
$kasaDers=@{}
if($kasa -and $kasa.sinav_ders){ foreach($p in $kasa.sinav_ders.PSObject.Properties){ $parca=$p.Name -split '\|',2; if($parca[0] -ne $Sinav){ continue }; $ak=DersAnahtar $parca[1]; if(-not $kasaDers.ContainsKey($ak)){ $kasaDers[$ak]=0 }; $kasaDers[$ak]+=(Sayi $p.Value) } }
$hedefDers=@{}
if($kota){
  if($Sinav -eq 'SGS' -and $kota.ozet){ foreach($o in @($kota.ozet)){ $hedefDers[(DersAnahtar $o.ders)]=Sayi $o.hedef } }
  if($Sinav -eq 'SMMM' -and $kota.ozet){ foreach($o in @($kota.ozet)){ $hedefDers[(DersAnahtar $o.ders)]=Sayi $o.toplam_kota } }
  if($Sinav -eq 'KGK' -and $kota.plan){ foreach($o in @($kota.plan)){ $ak=DersAnahtar $o.ders; if(-not $hedefDers.ContainsKey($ak)){ $hedefDers[$ak]=0 }; $hedefDers[$ak]+=(Sayi $o.adet) } }
}
$kopru=@($kopruTam | Where-Object { $_.sinav -eq $Sinav })
# köprü konusu → resmî ders: bizim_ders varsa o; yoksa arşiv dersi → ders köprüsü çoğunluğu
$arsivToBizim=@{}
if($kopruOzet -and $kopruOzet.ders_koprusu){ foreach($dk in @($kopruOzet.ders_koprusu)){ if($dk.sinav -eq $Sinav -and $dk.bizim_ders){ $arsivToBizim[(Norm $dk.arsiv_ders)]="$($dk.bizim_ders)" } } }
function ResmiDers($kayit){
  if($kayit.bizim_ders){ return "$($kayit.bizim_ders)" }
  foreach($ad in ("$($kayit.arsiv_ders)" -split ' / ')){ $na=Norm $ad; if($arsivToBizim.ContainsKey($na)){ return $arsivToBizim[$na] } }
  return "(arşiv: $((("$($kayit.arsiv_ders)" -split ' / ') | Select-Object -First 1)))"
}
$dersSatir=New-Object System.Collections.Generic.List[object]
foreach($dp in $dersProfil.PSObject.Properties){
  $ad=$dp.Name; $d=$dp.Value; $ak=DersAnahtar $ad
  $konular=@($kopru | Where-Object { (DersAnahtar (ResmiDers $_)) -eq $ak })
  $cikmisKonu=@($konular | Where-Object { $_.cikmis -gt 0 }).Count
  $bosluk=@($konular | Where-Object { $_.durum -like 'BOSLUK*' }).Count
  $mevcut=if($kasaDers.ContainsKey($ak)){ $kasaDers[$ak] } else { 0 }
  $hedef=if($hedefDers.ContainsKey($ak)){ $hedefDers[$ak] } else { -1 }
  $dersSatir.Add([pscustomobject]@{ ders=$ad; bolum="$($d.bolum)"; sinav_soru=(Sayi $d.soru_sayisi); liste_dayanagi="$($d.liste_dayanagi)"; hukuki_dayanak="$($d.hukuki_dayanak)"; bizim_soru=$mevcut; kota=$hedef; eksik=$(if($hedef -ge 0){ [Math]::Max(0,$hedef-$mevcut) } else { -1 }); konu_toplam=$konular.Count; cikmis_konu=$cikmisKonu; bosluk_konu=$bosluk; onay="$($d._onay)" })
}

# --- 2) ÇIKMIŞ DERSLER (arşiv etiketi) ---
$cikmisDers=@{}
$donemSet=@{}
if($analiz){
  foreach($dn in @($analiz.donemler)){
    if(-not $dn.konuSayim){ continue }
    $donemSet["$($dn.donem)"]=1
    if($dn.dersSayim){ foreach($p in $dn.dersSayim.PSObject.Properties){ $lbl="$($p.Name)"; if(-not $cikmisDers.ContainsKey($lbl)){ $cikmisDers[$lbl]=@{ soru=0; donemler=@{}; konu=@{} } }; $cikmisDers[$lbl].soru+=(Sayi $p.Value); $cikmisDers[$lbl].donemler["$($dn.donem)"]=1 } }
    foreach($p in $dn.konuSayim.PSObject.Properties){ $parca="$($p.Name)" -split '\|',2; if($parca.Count -lt 2){ continue }; $lbl=$parca[0].Trim(); if(-not $cikmisDers.ContainsKey($lbl)){ $cikmisDers[$lbl]=@{ soru=0; donemler=@{}; konu=@{} } }; $cikmisDers[$lbl].konu[(Norm $parca[1])]=1; $cikmisDers[$lbl].donemler["$($dn.donem)"]=1 }
  }
}
$cikmisSatir=New-Object System.Collections.Generic.List[object]
foreach($lbl in ($cikmisDers.Keys | Sort-Object)){
  $b=$arsivToBizim[(Norm $lbl)]; if(-not $b){ $b='(köprüsüz)' }
  $cikmisSatir.Add([pscustomobject]@{ arsiv_ders=$lbl; bizim_ders=$b; donem=$cikmisDers[$lbl].donemler.Count; soru=$cikmisDers[$lbl].soru; tekil_konu=$cikmisDers[$lbl].konu.Count })
}

# --- 3) KONULAR ---
$karneSoz=@{}
if($karne -and $karne.konular){ foreach($k in @($karne.konular)){ $karneSoz[(Norm $k.konu)]=$k } }
function Uretilebilir($kayit,[string]$dDurum,[string]$cDurum,$kr){
  # kural sırası: kara liste → mevzuat dışı → dayanak ambarda → karne URET → yok
  if($kayit.dayanak -and ($karaListe -contains ("$($kayit.dayanak)" -replace '\s*\(\d+\)\s*$',''))){ return 'DİKKAT: dayanak kara listede (üretici konu adıyla arar)' }
  if($dDurum -eq 'MEVZUAT-DISI' -or $cDurum -eq 'MEVZUAT-DISI'){ return 'ELLE (mevzuat dışı ders; fabrika girmez)' }
  if($dDurum -like 'VAR*' -or $cDurum -like 'VAR*'){ return 'EVET (dayanak ambarda)' }
  if($kr -and "$($kr.karar)" -eq 'URET'){ return 'EVET (karne: ambarda kaynak var)' }
  if($kr -and "$($kr.karar)" -eq 'MEVZUAT-DISI'){ return 'ELLE (mevzuat dışı ders; fabrika girmez)' }
  if($dDurum -eq 'YOK' -or $cDurum -eq 'YOK'){ return 'HAYIR (dayanak ambarda yok — teori notu/kaynak gerek)' }
  if(-not $kayit.dayanak -and -not $kayit.cikmis_dayanak){ return 'ÖLÇÜLMEDİ (dayanak yok; üretici konu adıyla arar)' }
  return 'ÖLÇÜLMEDİ'
}
$konuSatir=New-Object System.Collections.Generic.List[object]
foreach($k in ($kopru | Sort-Object @{Expression={ResmiDers $_}}, @{Expression='donem';Descending=$true}, konu)){
  $dD=DayanakDurumu $k.dayanak; $cD=DayanakDurumu $k.cikmis_dayanak
  $kr=$null; $nk=Norm $k.konu; if($karneSoz.ContainsKey($nk)){ $kr=$karneSoz[$nk] }
  $konuSatir.Add([pscustomobject]@{ resmi_ders=(ResmiDers $k); bizim_ders="$($k.bizim_ders)"; arsiv_ders="$($k.arsiv_ders)"; konu="$($k.konu)"; bizim_soru=$k.bizim; cikmis_soru=$k.cikmis; donem=$k.donem; durum="$($k.durum)"; dayanak="$($k.dayanak)"; dayanak_ambar=$dD; cikmis_dayanak=("$($k.cikmis_dayanak)" -replace '\s*⚠.*$',''); cikmis_dayanak_ambar=$cD; guc="$($k.guc)"; karne=$(if($kr){ "$($kr.karar)" } else { '' }); karne_not=$(if($kr){ "$($kr.not)" } else { '' }); uretilebilir=(Uretilebilir $k $dD $cD $kr) })
}

# --- 4) EKSİKLER ---
$eksikSatir=New-Object System.Collections.Generic.List[object]
foreach($s in ($konuSatir | Where-Object { $_.durum -like 'BOSLUK*' -or $_.uretilebilir -like 'HAYIR*' -or $_.uretilebilir -like 'DİKKAT*' } | Sort-Object @{Expression='donem';Descending=$true}, resmi_ders)){
  $tur=if($s.uretilebilir -like 'HAYIR*'){ 'KAYNAK YOK' } elseif($s.uretilebilir -like 'DİKKAT*'){ 'DAYANAK KARA LİSTE' } else { 'BOŞLUK (çıkmışta var, bizde yok)' }
  $eksikSatir.Add([pscustomobject]@{ tur=$tur; resmi_ders=$s.resmi_ders; konu=$s.konu; donem=$s.donem; cikmis_soru=$s.cikmis_soru; bizim_soru=$s.bizim_soru; dayanak=$(if($s.dayanak){ $s.dayanak } else { $s.cikmis_dayanak }); uretilebilir=$s.uretilebilir })
}

# --- 5) GM NOTU ---
$toplamKonu=$konuSatir.Count
$uretEvet=@($konuSatir | Where-Object { $_.uretilebilir -like 'EVET*' }).Count
$uretElle=@($konuSatir | Where-Object { $_.uretilebilir -like 'ELLE*' }).Count
$uretHayir=@($konuSatir | Where-Object { $_.uretilebilir -like 'HAYIR*' }).Count
$uretOlc=@($konuSatir | Where-Object { $_.uretilebilir -like 'ÖLÇÜLMEDİ*' }).Count
$uretDikkat=@($konuSatir | Where-Object { $_.uretilebilir -like 'DİKKAT*' }).Count
$boslukSay=@($konuSatir | Where-Object { $_.durum -like 'BOSLUK*' }).Count
$agirBosluk=@($konuSatir | Where-Object { $_.durum -like 'BOSLUK*' -and $_.donem -ge 3 }).Count
$hayirDers=@($konuSatir | Where-Object { $_.uretilebilir -like 'HAYIR*' } | Group-Object resmi_ders | Sort-Object Count -Descending | ForEach-Object { "$($_.Name) $($_.Count)" })
$gm=New-Object System.Collections.Generic.List[string]
$gm.Add("GENEL MÜDÜR NOTU — $Sinav — $($simdi.ToString('dd.MM.yyyy HH:mm'))")
$gm.Add('')
$gm.Add("1) DERSLER: resmî listede $($dersSatir.Count) ders. Kasada $((($dersSatir | Measure-Object bizim_soru -Sum).Sum)) soru, onaylı kota $((($dersSatir | Where-Object { $_.kota -ge 0 } | Measure-Object kota -Sum).Sum)), eksik $((($dersSatir | Where-Object { $_.eksik -ge 0 } | Measure-Object eksik -Sum).Sum)).")
$gm.Add("2) ÇIKMIŞ ARŞİV: $($donemSet.Count) dönem, $($cikmisSatir.Count) arşiv ders etiketi; köprüsüz etiket: $(@($cikmisSatir | Where-Object { $_.bizim_ders -eq '(köprüsüz)' }).Count).")
$gm.Add("3) KONULAR: $toplamKonu konu. Üretilebilir EVET $uretEvet · ELLE (mevzuat dışı) $uretElle · HAYIR (kaynak yok) $uretHayir · DİKKAT (kara liste) $uretDikkat · ÖLÇÜLMEDİ $uretOlc.")
$gm.Add("4) BOŞLUK (çıkmışta var, bizde yok): $boslukSay konu; ≥3 dönem çıkan ağır boşluk $agirBosluk. Bunlar üretim sırasının başıdır.")
$gm.Add("5) KAYNAK YOK konuların ders dağılımı: $(($hayirDers | Select-Object -First 8) -join ' · ').")
$gm.Add('')
$gm.Add('OKUMA KURALI: "EVET" = dayanağın metni ambarda, üretici soru yazabilir. "ELLE" = Türkçe/Matematik/İnkılap/Yabancı Dil gibi mevzuatı olmayan ders; fabrika girmez, elle yazılır. "HAYIR" = dayanak adı var ama ambarda metni yok; çoğu teori notu (ekonomi/maliye). "ÖLÇÜLMEDİ" = köprüde dayanak yok; üretici konu adıyla arar, sonuç parti koşunca belli olur.')
$gm.Add('KAYNAKLAR: ders-profili.json (resmî liste, Cem onaylı 01.09) · kasa-sayim.json (canlı) · konu-koprusu.json V2 (canlı kasa + arşiv analizleri) · dayanak-durum.json (metinsiz tarama 03.09) · konu-kaynak-karnesi.json · dayanak-kara-liste.json. Sayfa elle düzenlenmez; robot çıktıları değişince arac/sinav-excel.ps1 yeniden koşar.')

# --- EXCEL ---
if(-not $Cikti){ $Cikti=Join-Path $depoKok ("sql-yerel\SINAV-$Sinav-" + $simdi.ToString('yyyyMMdd') + '.xlsx') }
$xl=New-Object -ComObject Excel.Application; $xl.DisplayAlerts=$false; $xl.Visible=$false
$wb=$xl.Workbooks.Add()
function SayfaYaz($wb,[string]$ad,[string[]]$basliklar,$satirlar,[string[]]$alanlar,[int]$sira){
  $ws=$wb.Worksheets.Add([Type]::Missing,$wb.Worksheets.Item($wb.Worksheets.Count))
  $ws.Name=$ad
  $n=@($satirlar).Count; $m=$basliklar.Count
  # COM'a yalnız [double] ve [string] gider; PSObject/Int64/uzun metin "bellek yeterli degil"
  # diye patlıyor (03.09 ölçüldü). Değerler sadeleştirilir, 2.000 satırlık dilimlerle yazılır.
  $bas=New-Object 'object[,]' 1,$m
  for($j=0;$j -lt $m;$j++){ $bas[0,$j]=[string]$basliklar[$j] }
  $ws.Range($ws.Cells.Item(1,1),$ws.Cells.Item(1,$m)).Value2=$bas
  $dilim=2000; $satirDizi=@($satirlar)
  for($b0=0;$b0 -lt $n;$b0+=$dilim){
    $b1=[Math]::Min($b0+$dilim,$n)
    $dizi=New-Object 'object[,]' ($b1-$b0),$m
    for($i=$b0;$i -lt $b1;$i++){
      $s=$satirDizi[$i]
      for($j=0;$j -lt $m;$j++){
        $v=$s.($alanlar[$j])
        if($null -eq $v){ $dizi[($i-$b0),$j]='' ; continue }
        if($v -is [int] -or $v -is [long] -or $v -is [double] -or $v -is [decimal] -or $v -is [int16]){ if([double]$v -lt 0){ $dizi[($i-$b0),$j]='' } else { $dizi[($i-$b0),$j]=[double]$v }; continue }
        $t=[string]$v; if($t.Length -gt 30000){ $t=$t.Substring(0,30000) }
        $dizi[($i-$b0),$j]=$t
      }
    }
    $ws.Range($ws.Cells.Item($b0+2,1),$ws.Cells.Item($b1+1,$m)).Value2=$dizi
  }
  $aralik=$ws.Range($ws.Cells.Item(1,1),$ws.Cells.Item($n+1,$m))
  $ws.Rows.Item(1).Font.Bold=$true
  $ws.Range($ws.Cells.Item(1,1),$ws.Cells.Item(1,$m)).Interior.Color=0xE0E0E0
  $ws.Application.ActiveWindow.FreezePanes=$false
  $ws.Activate(); $ws.Range('A2').Select(); $xl.ActiveWindow.FreezePanes=$true
  $aralik.AutoFilter() | Out-Null
  $ws.Columns.AutoFit() | Out-Null
  for($j=1;$j -le $m;$j++){ if($ws.Columns.Item($j).ColumnWidth -gt 60){ $ws.Columns.Item($j).ColumnWidth=60 } }
  return $ws
}
# 0 OKU BENİ (ilk sayfa = varsayılan)
$ws0=$wb.Worksheets.Item(1); $ws0.Name='0-OKU BENI'
$oku=New-Object System.Collections.Generic.List[string]
$oku.Add("SINAV DOSYASI — $sinavUzun — üretim $($simdi.ToString('dd.MM.yyyy HH:mm')) (makine; elle düzenlenmez: arac/sinav-excel.ps1)")
$oku.Add('')
$oku.Add('SAYFALAR:')
$oku.Add('1-DERSLER ......... resmî ders listesi (kaynağı ve hukuki dayanağıyla), sınavdaki soru sayısı, kasadaki sorumuz, kota, eksik, köprüdeki konu sayısı')
$oku.Add('2-CIKMIS DERSLER .. çıkmış arşivin ders etiketleri: kaç dönem, kaç soru, kaç tekil konu, bizim hangi derse köprülendi')
$oku.Add('3-KONULAR ......... bütün konular: bizim/çıkmış soru, dönem, durum, dayanak, dayanağın AMBARDA olup olmadığı, karne kararı, ÜRETİLEBİLİR Mİ')
$oku.Add('4-EKSIKLER ........ çıkmışta var bizde yok + kaynağı olmayan + kara listeli dayanaklı konular, dönem sırasıyla')
$oku.Add('5-GM NOTU ......... genel müdür özeti: sayılar, ne eksik, sıra')
$oku.Add('')
foreach($g in $gm){ $oku.Add($g) }
$d0=New-Object 'object[,]' $oku.Count,1; for($i=0;$i -lt $oku.Count;$i++){ $d0[$i,0]=$oku[$i] }
$ws0.Range($ws0.Cells.Item(1,1),$ws0.Cells.Item($oku.Count,1)).Value2=$d0
$ws0.Columns.Item(1).ColumnWidth=160; $ws0.Rows.Item(1).Font.Bold=$true
[void](SayfaYaz $wb '1-DERSLER' @('Ders (resmî)','Bölüm','Sınavda soru','Liste dayanağı','Hukuki dayanak','Bizim soru (kasa)','Kota','Eksik','Köprüde konu','Çıkmış konu','Boşluk konu','Onay') $dersSatir.ToArray() @('ders','bolum','sinav_soru','liste_dayanagi','hukuki_dayanak','bizim_soru','kota','eksik','konu_toplam','cikmis_konu','bosluk_konu','onay') 1)
[void](SayfaYaz $wb '2-CIKMIS DERSLER' @('Arşiv ders etiketi','Bizim ders (köprü)','Dönem','Çıkmış soru','Tekil konu') $cikmisSatir.ToArray() @('arsiv_ders','bizim_ders','donem','soru','tekil_konu') 2)
[void](SayfaYaz $wb '3-KONULAR' @('Resmî ders','Bizim ders etiketi','Arşiv ders etiketi','Konu','Bizim soru','Çıkmış soru','Dönem','Durum','Dayanak (bizim)','Dayanak ambarda?','Çıkmış dayanak','Çıkmış dayanak ambarda?','Güç','Karne','Karne notu','ÜRETİLEBİLİR Mİ') $konuSatir.ToArray() @('resmi_ders','bizim_ders','arsiv_ders','konu','bizim_soru','cikmis_soru','donem','durum','dayanak','dayanak_ambar','cikmis_dayanak','cikmis_dayanak_ambar','guc','karne','karne_not','uretilebilir') 3)
[void](SayfaYaz $wb '4-EKSIKLER' @('Tür','Resmî ders','Konu','Dönem','Çıkmış soru','Bizim soru','Dayanak','Üretilebilir') $eksikSatir.ToArray() @('tur','resmi_ders','konu','donem','cikmis_soru','bizim_soru','dayanak','uretilebilir') 4)
$ws5=$wb.Worksheets.Add([Type]::Missing,$wb.Worksheets.Item($wb.Worksheets.Count)); $ws5.Name='5-GM NOTU'
$d5=New-Object 'object[,]' $gm.Count,1; for($i=0;$i -lt $gm.Count;$i++){ $d5[$i,0]=$gm[$i] }
$ws5.Range($ws5.Cells.Item(1,1),$ws5.Cells.Item($gm.Count,1)).Value2=$d5; $ws5.Columns.Item(1).ColumnWidth=160; $ws5.Rows.Item(1).Font.Bold=$true
$wb.Worksheets.Item(1).Activate()
if(Test-Path $Cikti){ Remove-Item $Cikti -Force }
$wb.SaveAs($Cikti,51)
$wb.Close($false); $xl.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
Write-Host "yazıldı: $Cikti | ders $($dersSatir.Count) · çıkmış etiket $($cikmisSatir.Count) · konu $($konuSatir.Count) · eksik $($eksikSatir.Count)"
foreach($g in $gm){ Write-Host "  $g" }
