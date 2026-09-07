# DAYANAK DÜŞÜŞ SAYACI (08.09, Ö73 GM-3; Cem "1.2.3 yap") — 0 USD
# Bir planın (ya da etiket listesinin) fabrika dosyalarını okur; hakem HAYIR kararlarını sınıflar:
#   ATIF-YANLIS (hakem 6)  · GUNCELLIK ESKI (hakem 5) · gerekçesi "madde/dayanak/kaynak ... içermez" (eski hakem biçimi) · diğer HAYIR.
# Eşik: dayanak kaynaklı düşüş üretilen soruların %10'unu aşarsa istemdeki dayanak talimatı güçlendirilir (SORU-BASMA-KURALLARI 6.10).
# Kullanım: powershell -NoProfile -File arac/dayanak-dusus-olcum.ps1 -Plan veri/sinav/plan-sgs-t1.json   |  -Etiketler a,b,c
param([string]$Plan='',[string]$Etiketler='',[double]$Esik=10)
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
$etk=@()
if($Plan){ $py=$(if(Test-Path $Plan){ $Plan } else { Join-Path $kok $Plan }); $sat=ConvertFrom-Json -InputObject (Get-Content $py -Raw -Encoding UTF8); foreach($s in @($sat)){ if($s.PSObject.Properties['SyncRoot']){ foreach($x in $s.SyncRoot){ $etk+="$($x.etiket)" } } else { $etk+="$($s.etiket)" } } }
if($Etiketler){ $etk+=($Etiketler -split ',') | ForEach-Object { $_.Trim() } }
$etk=@($etk | Where-Object { $_ } | Select-Object -Unique)
if(-not $etk.Count){ throw 'plan ya da etiket ver' }
$top=0; $hayir=0; $atifY=0; $eski=0; $maddeG=0; $teyitsiz=0; $ambarYok=0; $ornek=New-Object System.Collections.Generic.List[string]
$dersSay=@{}
foreach($e in $etk){
  $f=Join-Path $kok "veri\fabrika\kalip-parti-$e.json"; if(-not (Test-Path $f)){ continue }
  $c=ConvertFrom-Json -InputObject (Get-Content $f -Raw -Encoding UTF8)
  foreach($p in $c.PSObject.Properties){ $v=$p.Value; if(-not $v.soru){ continue }; $top++
    $ders=$(if($v.PSObject.Properties['ders'] -and $v.ders){ "$($v.ders)" } else { $e -replace '-(kolay|zor|cokzor)$','' }); if(-not $dersSay.ContainsKey($ders)){ $dersSay[$ders]=@{top=0;day=0} }; $dersSay[$ders].top++
    if($v.PSObject.Properties['atif_ambarda_yok'] -and $v.atif_ambarda_yok){ $ambarYok++ }
    if(-not ($v.PSObject.Properties['hakem'] -and $v.hakem)){ continue }
    $h=$v.hakem
    if($h.PSObject.Properties['atif'] -and "$($h.atif)" -eq 'TEYITSIZ'){ $teyitsiz++ }
    if("$($h.karar)" -ne 'HAYIR'){ continue }
    $hayir++; $day=$false
    if($h.PSObject.Properties['atif'] -and "$($h.atif)" -eq 'ATIF-YANLIS'){ $atifY++; $day=$true }
    elseif($h.PSObject.Properties['guncellik'] -and "$($h.guncellik)" -eq 'ESKI'){ $eski++; $day=$true }
    elseif("$($h.gerekce)" -match '(?i)madde|dayanak|kaynak (metni|metin)|paragraf|içermez|icermez|tanımlar|düzenlemez'){ $maddeG++; $day=$true }
    if($day){ $dersSay[$ders].day++; if($ornek.Count -lt 12){ $ornek.Add("$e/$($p.Name) [$($v.konu)] dayanak='$($v.dayanak)' → $($h.gerekce)") } }
  }
}
$dayToplam=$atifY+$eski+$maddeG
$yuzde=$(if($top){ [math]::Round(100.0*$dayToplam/$top,1) } else { 0 })
"DAYANAK DÜŞÜŞ ÖLÇÜMÜ · etiket $($etk.Count) · üretilen soru $top · hakem HAYIR $hayir"
"  dayanak kaynaklı: $dayToplam (%$yuzde) = atıf yanlış $atifY · güncellik eski $eski · gerekçe madde/kaynak $maddeG · (teyitsiz atıf $teyitsiz, atıf ambarda yok $ambarYok — düşüş değil, iz)"
"  eşik %$Esik → " + $(if($yuzde -gt $Esik){ "AŞILDI: istemdeki dayanak talimatı güçlendirilir (kural 6.10)" } else { "altında" })
"  ders ders (dayanak düşüş / üretilen):"
foreach($d in ($dersSay.Keys | Sort-Object)){ $x=$dersSay[$d]; "    {0,-32} {1,3} / {2,-4} %{3}" -f $d,$x.day,$x.top,$(if($x.top){ [math]::Round(100.0*$x.day/$x.top) } else { 0 }) }
if($ornek.Count){ "  örnekler:"; $ornek | ForEach-Object { "    $_" } }
