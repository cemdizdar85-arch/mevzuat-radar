# 08.09 19:55 Cem "bir yerden sen bas, bir yerden başka gönder": anlık dört hat (p1–p4) planın başından ilerliyor;
# bu betik HENÜZ BAŞLAMAMIŞ etiketleri anlık kuyrukların TERSİNDEN sıralayıp N toplu hat planı yazar (plan-<Ad>-toplu-pK.json).
# İki cephe ortada buluşur; aynı etiketi iki hattın basmaması üreticideki ETİKET SAHİPLİĞİ (claim) kapısıyla sağlanır.
# Kullanım: powershell -NoProfile -File arac/toplu-hat-plan.ps1 -Ad sgs-t1 -Hat 3
param([string]$Ad='sgs-t1',[int]$Hat=3)
$kok=Split-Path $PSScriptRoot -Parent
$logDir=Join-Path $kok 'veri\fabrika\kosucu-log'
function Oku($p){ $j=ConvertFrom-Json -InputObject (Get-Content $p -Raw -Encoding UTF8); $r=@($j | ForEach-Object { $_ }); if($r.Count -eq 1 -and $r[0].PSObject.Properties['value']){ $r=@($r[0].value) }; return $r }
# anlık parçalar: plan-<Ad>-pN.json (pilot id'li A/B yarıları hariç: onlar bitti ya da tek satır)
$anlik=@(Get-ChildItem (Join-Path $kok 'veri\sinav') -Filter "plan-$Ad-p*.json" | Where-Object { $_.Name -match "^plan-$Ad-p\d+\.json$" } | Sort-Object { [int]($_.BaseName -replace '.*-p','') })
$kuyruklar=New-Object System.Collections.Generic.List[object]
foreach($pf in $anlik){
  $rows=Oku $pf.FullName
  $kalan=New-Object System.Collections.Generic.List[object]
  foreach($r in $rows){
    if($r.PSObject.Properties['pilot'] -and "$($r.pilot)"){ continue }
    $et="$($r.etiket)"
    $bitti=Test-Path (Join-Path $kok "sql-yerel\kalip-parti-$et.html")
    $claim=Join-Path $logDir "claim-$et.json"; $sahipli=$false
    if(Test-Path $claim){ try{ $c=ConvertFrom-Json -InputObject (Get-Content $claim -Raw); $sahipli=[bool](Get-Process -Id ([int]$c.pid) -ErrorAction SilentlyContinue) }catch{} }
    # koşan etiket = etiket logu var ve bitiş damgası yok
    $kosan=(Test-Path (Join-Path $logDir "plan-$($pf.BaseName -replace '^plan-','')\$et.log")) -and -not $bitti
    if($bitti -or $sahipli -or $kosan){ continue }
    $kalan.Add($r)
  }
  $kalan.Reverse()   # anlık hat sondan en son ulaşır → toplu hat oradan başlar
  $kuyruklar.Add(@{ ad=$pf.BaseName; rows=$kalan })
  "  $($pf.BaseName): kalan $($kalan.Count) → " + (($kalan | ForEach-Object { "$($_.etiket)($($_.adet))" }) -join ' → ')
}
# hatlara dağıt: her toplu hat bir anlık kuyruğun tersini alır; kuyruk sayısı hat sayısını aşarsa fazlalar sırayla eklenir
$hatlar=@(); for($i=0;$i -lt $Hat;$i++){ $hatlar+=,(New-Object System.Collections.Generic.List[object]) }
for($i=0;$i -lt $kuyruklar.Count;$i++){ foreach($r in $kuyruklar[$i].rows){ $hatlar[$i % $Hat].Add($r) } }
$topSoru=0
for($i=0;$i -lt $Hat;$i++){
  $rows=@($hatlar[$i] | ForEach-Object { $o=[ordered]@{}; foreach($p in $_.PSObject.Properties){ $o[$p.Name]=$p.Value }; $o['toplu']=$true; $o['hat']='toplu'; [pscustomobject]$o })
  $yol=Join-Path $kok "veri\sinav\plan-$Ad-toplu-p$($i+1).json"
  $json=$(if($rows.Count -eq 1){ '['+(ConvertTo-Json $rows[0] -Depth 5)+']' } else { ConvertTo-Json @($rows) -Depth 5 })
  [IO.File]::WriteAllText($yol,$json,[Text.UTF8Encoding]::new($false))
  $s=($rows | Measure-Object adet -Sum).Sum; $topSoru+=$s
  "toplu-p$($i+1): $($rows.Count) etiket · $s soru → " + (($rows | ForEach-Object { $_.etiket -replace "^$Ad-",'' }) -join ' → ')
}
"toplam $topSoru soru · başlatma: `$env:MEVZUAT_TOPLU='1'; powershell -NoProfile -File motor/kalip-tur-baslat.ps1 -Ad $Ad-toplu -Parca $Hat"
