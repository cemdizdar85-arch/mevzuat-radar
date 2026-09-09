# SİMÜLASYON YENİDEN DEĞERLENDİRME (09.09.2026, Cem "1.2.3 üçünü de yap" → 2)
# Üreticideki sim hedef seçimi kusurluydu (GM pilotu ölçümü): (a) satır etiketinin parantezindeki formül kökleri hedefi kaydırıyordu,
# (b) "Kontrol:/Sağlama:" satırı son satır olunca varsayılan hedef oluyordu, (c) 5 harflik kök "stoku"≠"stok" eşleşmiyordu,
# (d) öğrencinin doğru cevabı tablonun başka bir sonuç satırındaysa yine YANLIŞ sayılıyordu. Üretici düzeltildi (motor/kalip-parti-uret.ps1);
# bu betik ESKİ etiketlerdeki "sim yanlış" kayıtlarını AYNI yeni mantıkla yeniden ölçer. Model çağrısı YOK (0 USD): öğrencinin verdiği cevap
# (simulasyon_sonnet.cevap) ikiz tablosuyla yeniden karşılaştırılır. Değişen kayıtta iz bırakılır: sim_yeniden = { tarih, eski_hedef, yeni_hedef }.
# Kullanım: powershell -NoProfile -File arac/sim-yeniden-degerlendir.ps1 [-Desen 'kalip-parti-sgs-t*.json'] [-Yaz]
param([string]$Desen='kalip-parti-sgs-t*.json',[switch]$Yaz)
$kok=Split-Path $PSScriptRoot -Parent
function Katla([string]$s){ ("$s".ToLowerInvariant() -creplace 'İ','i' -creplace 'I','i').Replace('ı','i').Replace('ğ','g').Replace('ü','u').Replace('ş','s').Replace('ö','o').Replace('ç','c').Replace('â','a').Replace('î','i').Replace('û','u') }
$trO=[cultureinfo]::GetCultureInfo('tr-TR')
function Sayi([string]$t){ $m=[regex]::Match("$t",'-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?'); if($m.Success){ try{ return [double]::Parse($m.Value,$trO) }catch{ return $null } }; return $null }
function KokEs($a,$b){ if($a -eq $b){ return $true }; if("$a".Length -ge 4 -and "$b".Length -ge 4){ return ("$a".StartsWith("$b") -or "$b".StartsWith("$a")) }; return $false }
function Kokler([string]$metin){ @(((Katla $metin) -replace '[^a-z ]+',' ') -split '\s+' | Where-Object { $_ } | ForEach-Object { if($_.Length -gt 5){ $_.Substring(0,5) } else { $_ } }) }
function HucreDeger($st){ for($c=@($st).Count-1;$c -ge 1;$c--){ if("$(@($st)[$c])" -match '\d'){ return "$(@($st)[$c])" } }; return '' }
$topDosya=0; $topAday=0; $duzelen=0; $rapor=New-Object System.Collections.Generic.List[string]
foreach($f in @(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter $Desen)){
  $topDosya++; $degisti=$false
  $don=ConvertFrom-Json -InputObject (Get-Content $f.FullName -Raw -Encoding UTF8)
  foreach($p in $don.PSObject.Properties){
    if($p.Name -notmatch '^kp-\d+$'){ continue }; $v=$p.Value
    if(-not $v.soru -or -not $v.PSObject.Properties['simulasyon_sonnet'] -or -not $v.simulasyon_sonnet){ continue }
    $sim=$v.simulasyon_sonnet
    if([bool]$sim.dogru_mu){ continue }
    if("$($sim.tur)" -eq 'teori'){ continue }                       # teori simülasyonu şık harfiyle çalışır, bu onarımın dışında
    if(-not $v.PSObject.Properties['ikiz'] -or -not $v.ikiz -or -not $v.ikiz.tablo -or -not $v.ikiz.tablo.satirlar){ continue }
    $topAday++
    $cv=Sayi "$($sim.cevap)"; if($null -eq $cv){ continue }        # "yetmedi" gibi sayısız cevap: gerçek düşüş
    $satirlar=@($v.ikiz.tablo.satirlar)
    $aday=@($satirlar | Where-Object { "$(@($_)[0])" -notmatch '^\s*(Kontrol|Sağlama|Saglama)\b' }); if(-not $aday.Count){ $aday=@($satirlar) }
    # 1) yeni hedef seçimi (üreticiyle aynı): ikiz kökündeki istenen son 5 kelime, parantezsiz etiket, önek toleranslı kök
    $hedefSat=$null
    $kokM=[regex]::Match("$($v.ikiz.ikiz_soru)",'([^.?!]{6,}?)\s*(kaç|ne kadardır|hangisidir|nedir)[^.?!]*\?\s*$')
    if($kokM.Success){
      $sonObek=(@(($kokM.Groups[1].Value -split '\s+') | Where-Object { $_ }) | Select-Object -Last 5) -join ' '
      $istenenK=@((Kokler $sonObek) | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(gore|olan|tarih|sonu|basi|donem|yili|urun|urunu|urununun)$' } | Select-Object -Unique)
      if($istenenK -contains 'basin'){ $istenenK=@($istenenK)+@('birim') }
      $enP=0; foreach($st in $aday){ $etK=Kokler ("$(@($st)[0])" -replace '\([^)]*\)',' '); $pp=@($istenenK | Where-Object { $ik=$_; @($etK | Where-Object { KokEs $ik $_ }).Count -gt 0 }).Count; if($pp -gt 0 -and $pp -ge $enP){ $enP=$pp; $hedefSat=$st } }
      if($enP -eq 0){ foreach($st in $aday){ $etK=Kokler "$(@($st)[0])"; $pp=@($istenenK | Where-Object { $ik=$_; @($etK | Where-Object { KokEs $ik $_ }).Count -gt 0 }).Count; if($pp -gt 0 -and $pp -ge $enP){ $enP=$pp; $hedefSat=$st } } }
      if($enP -lt 1){ $hedefSat=$null }
    }
    $hedefS=HucreDeger $(if($hedefSat){ $hedefSat } else { $aday[-1] })
    $hd=Sayi $hedefS
    $yonlu=("$hedefS" -match '(?i)azalış|azalis|olumsuz|olumlu|artış|artis|düşüş|dusus|lehte|aleyhte|\(-\)')
    $dogru=$false
    if($null -ne $hd){ $cvK=$(if($yonlu){ [math]::Abs($cv) } else { $cv }); $hdK=$(if($yonlu){ [math]::Abs($hd) } else { $hd }); $dogru=([math]::Abs($cvK-$hdK) -le [math]::Max(0.5,[math]::Abs($hdK)*0.01)) }
    # 2) öğrenci cevabı başka bir sonuç satırına eşitse doğru — SIKI: istenen biliniyor VE satır etiketi istenenle en az bir kök paylaşıyor;
    #    küçük sayıda tolerans 0,02 (ilk kuru koşuda 1,25 ile "-1/2", 58.571 ile 58.000 eşleşmişti — kalite için kapatıldı)
    if(-not $dogru -and $kokM.Success -and $istenenK -and $istenenK.Count){
      foreach($st in $aday){ $etK2=Kokler ("$(@($st)[0])" -replace '\([^)]*\)',' '); $ort=@($istenenK | Where-Object { $ik=$_; @($etK2 | Where-Object { KokEs $ik $_ }).Count -gt 0 }).Count; if($ort -lt 1){ continue }
        $hv=Sayi (HucreDeger $st); if($null -eq $hv){ continue }; $tol=$(if([math]::Abs($hv) -ge 100){ [math]::Max(0.5,[math]::Abs($hv)*0.01) } else { [math]::Max(0.02,[math]::Abs($hv)*0.01) })
        if([math]::Abs([math]::Abs($cv)-[math]::Abs($hv)) -le $tol){ $dogru=$true; $hedefS=HucreDeger $st; break } } }
    if($dogru){
      $duzelen++; $degisti=$true
      $rapor.Add(("{0,-34} {1,-6} cevap {2,-12} eski hedef {3,-12} yeni hedef {4}" -f ($f.BaseName -replace '^kalip-parti-',''),$p.Name,$sim.cevap,$sim.hedef,$hedefS))
      if($Yaz){
        $sim | Add-Member -NotePropertyName sim_yeniden -NotePropertyValue ([pscustomobject]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); eski_hedef="$($sim.hedef)"; yeni_hedef="$hedefS"; sebep='09.09 hedef mantığı (kontrol satırı / parantez / önek kökü / başka sonuç satırı)' }) -Force
        $sim.hedef="$hedefS"; $sim.dogru_mu=$true
      }
    }
  }
  if($Yaz -and $degisti){ $dN=[ordered]@{}; foreach($x in ($don.PSObject.Properties.Name | Sort-Object)){ $dN[$x]=$don.$x }; [IO.File]::WriteAllText($f.FullName,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false)) }
}
"dosya $topDosya · sim yanlış (hesaplı, ikizli) $topAday · yeni mantıkla DOĞRU $duzelen $(if($Yaz){ '→ YAZILDI (sim_yeniden izi ile)' } else { '(kuru koşu, -Yaz yok)' })"
$rapor | ForEach-Object { "  $_" }
