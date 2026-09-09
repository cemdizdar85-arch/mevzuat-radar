# Tur 2 planı: Tur 1'de basılan ama YAYIN ŞARTINI geçemeyen (hakem ∧ sim ∧ kör ∧ hakem2) konuları toplar,
# aynı ders/zorlukla yeni plan üretir. 08.09.2026 Cem "1 ve 2 yap" (GM önerisi 1).
# Kullanım: powershell -NoProfile -File arac/tur2-plan-uret.ps1 -Kaynak sgs-t1 -Ad sgs-t2 [-Yaz]
#   -Yaz yoksa yalnız rapor basar (plan ve konu dosyası yazılmaz).
# Ölçüm mantığı: bitmiş etiket = fabrika/kalip-parti-<etiket>.html var. Bitmemiş etiket rapora "bekliyor" düşer, plana girmez.
# Konu eşleşmesi konu dosyasındaki dize ile seçim kaydındaki `konu` alanı üzerinden (ikisi de ASCII köklü).
param([string]$Kaynak='sgs-t1',[string]$Ad='sgs-t2',[switch]$Yaz,[switch]$KaynakEksikDahil)   # -KaynakEksikDahil: teori notu yazıldıktan sonra o konuları plana geri al
$topKaynak=0
$kok=Split-Path $PSScriptRoot -Parent
$planYol=Join-Path $kok "veri\sinav\plan-$Kaynak.json"
if(-not (Test-Path $planYol)){ throw "plan yok: $planYol" }
$plan=ConvertFrom-Json -InputObject (Get-Content $planYol -Raw -Encoding UTF8)
# A/B yarı planları (pilot id'li) aynı konu dosyasını kullanır; etiket "-b" ekiyle biter. Seçimler ana etiketle birleştirilir.
# Yayın şartı koşucunun 8.1 kuralıyla birebir (kalip-kosucu.ps1): hakem EVET ∧ sim doğru ∧ kör doğru ∧ hakem2 EVET.
# Seçim dosyası çok satırlı hatta ancak HAT bitince yazılıyor → burada fabrika kaydından yeniden türetilir (etiket etiket ölçüm için).
function YayinaGirer($v){
  if(-not $v.soru){ return $false }
  if("$($v.hakem.karar)" -ne 'EVET'){ return $false }
  foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.PSObject.Properties[$sa] -and $v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ return $false } }
  if(-not ($v.PSObject.Properties['kor_cozum'] -and $v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and [bool]$v.kor_cozum.dogru_mu)){ return $false }
  if(-not ($v.PSObject.Properties['hakem2'] -and $v.hakem2 -and "$($v.hakem2.karar)" -eq 'EVET')){ return $false }
  return $true
}
$secim=@{}
# 09.09 ÖLÇÜLDÜ (Cem "bunu nasıl engelleyebiliriz"): Tur 1'de hakemde düşen 207 konunun 137'si "kaynak paketi kuralı içermiyor" diyeydi;
# bunlardan 94'ü Tur 2 planına YİNE alındı ve Tur 2'de 83'ü AYNI sebeple yeniden düştü — yalnız 14'ü yayına girdi. Kaynak düzelmeden
# konuyu yeniden basmak parayı ikinci kez yakmaktır. Artık: kaynak yüzünden düşen konu plana GİRMEZ, ayrı listeye yazılır
# (veri/fabrika/kaynak-eksik-konular.json) — o liste teori notu yazma iş emridir (0 USD); not yazılınca konu -KaynakEksikDahil ile geri alınır.
$kaynakDusen=@{}
foreach($ff in Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter "kalip-parti-$Kaynak-*.json"){
  $e=$ff.BaseName -replace '^kalip-parti-','' -replace '-b$',''
  $fj=ConvertFrom-Json -InputObject (Get-Content $ff.FullName -Raw -Encoding UTF8)
  if(-not $secim.ContainsKey($e)){ $secim[$e]=New-Object System.Collections.Generic.HashSet[string] }
  foreach($p in $fj.PSObject.Properties){
    if($p.Name -notmatch '^kp-\d+$'){ continue }
    $v=$p.Value
    if(YayinaGirer $v){ [void]$secim[$e].Add("$($v.konu)".Trim().ToLowerInvariant()); continue }
    if(-not $v.soru){ continue }
    # hakem reddi KAYNAK sınıfı mı? (gerekçede "kaynak metni/paketi ... içermiyor / yer almamakta" kalıbı)
    if($v.PSObject.Properties['hakem'] -and $v.hakem -and "$($v.hakem.karar)" -ne 'EVET'){
      $g="$($v.hakem.gerekce)"
      if($g -match '(?i)kaynak metn|kaynak paket|kaynakta (yer almam|bulunmam)|içermemekte|içermiyor|yer almamakta'){
        $kk="$($v.konu)".Trim().ToLowerInvariant()
        if(-not $kaynakDusen.ContainsKey($kk)){ $kaynakDusen[$kk]=[pscustomobject]@{ konu="$($v.konu)"; ders="$($v.ders)"; etiket=$e; dayanak="$($v.dayanak)"; gerekce=$g } }
      }
    }
  }
}
$fab=Join-Path $kok 'sql-yerel'   # üretici "yazildi: kalip-parti-<etiket>.html" dosyasını buraya yazar (bitiş damgası)
$yeni=New-Object System.Collections.Generic.List[object]; $rapor=New-Object System.Collections.Generic.List[string]
$topPlan=0; $topSecim=0; $topDusen=0; $bekleyen=0
foreach($s in @($plan)){
  $et="$($s.etiket)"
  $bittiA=Test-Path (Join-Path $fab "kalip-parti-$et.html"); $bittiB=Test-Path (Join-Path $fab "kalip-parti-$et-b.html")
  # PS 5.1: ConvertFrom-Json diziyi TEK nesne döndürür, @() sarmalı 1 sayar → boruyla açılır
  $konular=@(); if($s.konuDosya -and (Test-Path $s.konuDosya)){ $konular=@((ConvertFrom-Json -InputObject (Get-Content $s.konuDosya -Raw -Encoding UTF8)) | ForEach-Object { $_ } | Where-Object { "$_".Trim() }) }
  # A/B bölünmüş etiketlerde iki yarı da bitmeden konu listesi tam ölçülemez: yarısı bitmişse yalnız bitmiş yarının konuları sayılır
  $pilotVar=@(Get-ChildItem (Join-Path $kok 'veri\sinav') -Filter "plan-$Kaynak-p*.json" | Where-Object { (Get-Content $_.FullName -Raw) -match "`"$et-b`"" }).Count -gt 0
  if(-not $bittiA -and -not $bittiB){ $bekleyen++; $rapor.Add(("{0,-34} bekliyor (konu {1})" -f $et,$konular.Count)); continue }
  if($pilotVar -and -not ($bittiA -and $bittiB)){ $bekleyen++; $rapor.Add(("{0,-34} yarısı bitti (A={1} B={2}) — iki yarı da bitince ölçülür" -f $et,$bittiA,$bittiB)); continue }
  $sec=$(if($secim.ContainsKey($et)){ $secim[$et] } else { New-Object System.Collections.Generic.HashSet[string] })
  $dusenHam=@($konular | Where-Object { -not $sec.Contains("$_".Trim().ToLowerInvariant()) })
  # kaynak yüzünden düşenler plana ALINMAZ (yukarıdaki ölçüm: yeniden basılınca %88'i aynı sebeple yine düşüyor)
  $kaynakBu=@($dusenHam | Where-Object { $kaynakDusen.ContainsKey("$_".Trim().ToLowerInvariant()) })
  $dusen=@($dusenHam | Where-Object { $KaynakEksikDahil -or -not $kaynakDusen.ContainsKey("$_".Trim().ToLowerInvariant()) })
  $topPlan+=$konular.Count; $topSecim+=$sec.Count; $topDusen+=$dusen.Count; $topKaynak+=$(if($KaynakEksikDahil){ 0 } else { $kaynakBu.Count })
  $rapor.Add(("{0,-34} konu {1,3} · yayın {2,3} · düşen {3,3} · kaynak eksik {4,3} (plana {5,3})" -f $et,$konular.Count,$sec.Count,$dusenHam.Count,$kaynakBu.Count,$dusen.Count))
  if($dusen.Count){
    $yeniEt=$et -replace "^$([regex]::Escape($Kaynak))-","$Ad-"
    $kd=Join-Path $kok "veri\sinav\konu\$yeniEt.json"
    if($Yaz){ [IO.File]::WriteAllText($kd,(ConvertTo-Json @($dusen) -Compress),[Text.UTF8Encoding]::new($false)) }
    # 09.09 00:40 Cem "şu an başlat toplu modda": Tur 2 satırları toplu (koşucu MEVZUAT_TOPLU=0 ile anlığa çevirebilir; üretici 45 dk'da anlığa düşer)
    $yeni.Add([ordered]@{ ders=$s.ders; dersAd=$s.dersAd; etiket=$yeniEt; adet=$dusen.Count; tavan=$s.tavan; zorluk=$s.zorluk; sinav=$s.sinav; konuDosya=$kd; toplu=$true; disla=$s.disla; tur=2; kaynakEtiket=$et })
  }
}
"TUR 2 PLANI ($Kaynak → $Ad) · $(Get-Date -Format 'dd.MM HH:mm')"
$rapor | ForEach-Object { "  $_" }
"  ---"
"  ölçülen konu $topPlan · yayına giren $topSecim · plana giren düşen $topDusen · KAYNAK EKSİK (plana alınmadı) $topKaynak · bekleyen etiket $bekleyen · yeni plan satırı $($yeni.Count)"
# kaynak eksik listesi = teori notu yazma iş emri (0 USD). Ders ders gruplanır.
if($kaynakDusen.Keys.Count){
  $liste=@($kaynakDusen.Keys | Sort-Object | ForEach-Object { $kaynakDusen[$_] })
  $kyol=Join-Path $kok 'veri\fabrika\kaynak-eksik-konular.json'
  [IO.File]::WriteAllText($kyol,(ConvertTo-Json -InputObject @($liste) -Depth 4),[Text.UTF8Encoding]::new($false))
  "  KAYNAK EKSİK LİSTESİ: $($liste.Count) konu → $kyol"
  $dersG=@{}; foreach($x in $liste){ $dd=(("$($x.ders)" -split '\|')[0]).Trim(); if(-not $dd){ $dd='?' }; if(-not $dersG.ContainsKey($dd)){ $dersG[$dd]=0 }; $dersG[$dd]++ }
  foreach($dd in ($dersG.Keys | Sort-Object { -$dersG[$_] })){ "     $dd : $($dersG[$dd]) konu" }
}
if($Yaz){
  $py=Join-Path $kok "veri\sinav\plan-$Ad.json"
  # PS 5.1: tek satırlık plan ConvertTo-Json ile nesneye çöker → dizi sarmalı korunur
  # PS 5.1: List[object] doğrudan ConvertTo-Json'a verilince "Bağımsız değişken türleri eşleşmiyor" (00:38 yaşandı, boş plan yazıldı) → ToArray + -InputObject
  $dizi=@($yeni.ToArray())
  $json=$(if($dizi.Count -eq 1){ '['+(ConvertTo-Json -InputObject $dizi[0] -Depth 5)+']' } else { ConvertTo-Json -InputObject $dizi -Depth 5 })
  [IO.File]::WriteAllText($py,$json,[Text.UTF8Encoding]::new($false))
  "  yazıldı: $py ($($yeni.Count) satır, $topDusen soru) + $($yeni.Count) konu dosyası"
  "  başlatma: powershell -NoProfile -File motor/kalip-kosucu.ps1 -Plan veri/sinav/plan-$Ad.json   (MEVZUAT_TOPLU=0 anlık modda)"
} else { "  (-Yaz verilmedi: dosya yazılmadı)" }
