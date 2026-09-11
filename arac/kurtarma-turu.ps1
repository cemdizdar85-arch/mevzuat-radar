#requires -Version 5.1
<#
================================================================================
  KURTARMA TURU — ret kutugundeki sorulari PAKET DUZELTEREK geri kazanir
  11.09.2026, Cem "777'nin tamamini kurtarma turuna al"

  PROVA SONUCU (20 soru, 10 dersten 2'ser): %40 kurtuldu, soru basi 1,03 TL.
  Sifirdan uretmek 13 KAT pahali.

  NE YAPAR: secilen sorularin `hakem` karari VE `kaynak_metin_ozet`i silinir;
  uretici paketi KAPI-KP ile (konuya gore SIRALI, sinirda kesilmis) yeniden
  kurar ve hakem yeniden karar verir.
  ⛔ SORU YENIDEN YAZILMAZ - metin, siklar, aciklama AYNEN kalir. Bu bir
     ONARIM turu, uretim turu degil.
  ⛔ ESKI KARAR YEDEKLENIR (veri/fabrika/_kurtarma-yedek-<tur>.json). Hakem
     yeni kararinda daha sert davranirsa neyin degistigi gorulebilsin.

  PROVANIN OGRETTIGI: kurtulmayanlarin bir kismi paket sorunu DEGIL, AMBARDA
  OLMAYAN MEVZUAT. Tur sonunda o gerekceler ayri dosyaya cikarilir
  (veri/kurtarma-ambar-eksigi.json) - yutma is emri olur.

  BEDEL: soru basina ~1 hakem cagrisi (~0,010 USD). 770 soru ≈ 7,7 USD ≈ 316 TL.
================================================================================
#>
param(
  [string]$Sinif   = 'KAYNAK-EKSIK',
  [string]$Kapi    = 'KAPI-HAKEM',
  [int]$Tavan      = 900,        # kac soruyu asarsa DURUR (bedel emniyeti)
  [ValidateRange(1,6)][int]$Paralel = 2,
  [switch]$Yaz
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

$uret=Join-Path $depoKok 'motor\kalip-parti-uret.ps1'
$turAd=(Get-Date -Format 'ddMM-HHmm')

# --- SECIM --------------------------------------------------------------------
$rk=Get-Content (Join-Path $depoKok 'veri\ret-kutugu.json') -Raw -Encoding UTF8|ConvertFrom-Json
# ⛔ URETIMDEKI partiler (sgs-p-*) DISARIDA: o partiler su an kosuyor, ayni
#    dosyaya iki surec yazarsa kayit bozulur.
$aday=@($rk.kayitlar | Where-Object {
  $_.sinif -eq $Sinif -and $_.kapi -eq $Kapi -and "$($_.etiket)" -notmatch '^sgs-p-' })
Write-Host ("SECIM: sinif={0} · kapi={1} -> {2:N0} soru" -f $Sinif,$Kapi,$aday.Count) -ForegroundColor Cyan
if($aday.Count -gt $Tavan){ throw "TAVAN ASILDI: $($aday.Count) soru > $Tavan. Bilerek asilacaksa -Tavan yukselt." }
if(-not $aday.Count){ throw 'secimden soru cikmadi' }

# ders adi (KAPI-DR gercek ders adi ister)
$MAP=[ordered]@{'fmuh'='Finansal Muhasebe';'denetim'='Denetim';'maliyet'='Maliyet Muhasebesi'
  'mta'='Mali Tablolar Analizi';'ticaret'='Ticaret Hukuku';'borclar'='Borclar Hukuku'
  'vergi'='Vergi Hukuku';'meslek'='Meslek Hukuku';'issgk'='Is ve Sosyal Guvenlik Hukuku'
  'mat'='Matematik';'turkce'='Turkce';'yd'='Yabanci Dil';'ydil'='Yabanci Dil'
  'yabancidil'='Yabanci Dil';'ekonomi'='Ekonomi';'maliye'='Maliye'
  'inkilap'='Ataturk Ilkeleri ve Inkilap Tarihi';'ataturk'='Ataturk Ilkeleri ve Inkilap Tarihi'}
function DersBul([string]$et){ foreach($k in $MAP.Keys){ if($et -match "(^|-)$k(-|$)"){ return $MAP[$k] } }; return '' }

$grup=@($aday | Group-Object etiket)
$is=New-Object System.Collections.Generic.List[object]
$dersiz=@{}
foreach($g in $grup){
  $d=DersBul "$($g.Name)"
  if(-not $d){ $dersiz["$($g.Name)"]=$g.Count; continue }   # ders cozulemeyen ATLANIR
  $is.Add([pscustomobject]@{ etiket=$g.Name; ders=$d; idler=((@($g.Group)|ForEach-Object{$_.id}) -join ','); adet=$g.Count })
}
$topSoru=0; foreach($x in (Dizi $is)){ $topSoru+=$x.adet }
Write-Host ("PLAN: {0} parti · {1:N0} soru · tahmini {2:N2} USD ≈ {3:N0} TL" -f (Dizi $is).Count,$topSoru,($topSoru*0.010),($topSoru*0.010*41)) -ForegroundColor Cyan
if($dersiz.Count){ Write-Host ("  dersi cozulemedigi icin ATLANAN: {0} parti" -f $dersiz.Count) -ForegroundColor Yellow }
if(-not $Yaz){
  Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Kosmak icin: -Yaz" -ForegroundColor Yellow
  foreach($x in (Dizi $is | Sort-Object adet -Descending | Select-Object -First 12)){ Write-Host ("  {0,-32} {1,3} soru" -f $x.etiket,$x.adet) }
  return
}

# --- YEDEK + TEMIZLE ----------------------------------------------------------
$yedek=New-Object System.Collections.Generic.List[object]
foreach($x in (Dizi $is)){
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$($x.etiket).json"
  if(-not (Test-Path $f)){ continue }
  $c=Get-Content $f -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($id in ($x.idler -split ',')){
    $v=$c.$id; if(-not $v){ continue }
    $yedek.Add([ordered]@{ etiket=$x.etiket; id=$id; ders=$x.ders; konu="$($v.konu)"
      eskiKarar="$($v.hakem.karar)"; eskiGerekce=(("$($v.hakem.gerekce)") -replace '\s+',' ').Trim()
      hakem=$v.hakem; kaynak_metin_ozet="$($v.kaynak_metin_ozet)"; kaynak_adlar=@($v.kaynak_adlar) })
    foreach($alan in 'hakem','kaynak_metin_ozet','atif_genisletme','atif_ambarda_yok'){
      if($v.PSObject.Properties[$alan]){ $v.PSObject.Properties.Remove($alan) }
    }
  }
  $dN=[ordered]@{}; foreach($k in ($c.PSObject.Properties.Name|Sort-Object)){ $dN[$k]=$c.$k }
  [IO.File]::WriteAllText($f,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false))
}
$yolYedek=Join-Path $depoKok "veri\fabrika\_kurtarma-yedek-$turAd.json"
[IO.File]::WriteAllText($yolYedek,((Dizi $yedek)|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding $false))
Write-Host ("YEDEK: {0} ({1} kayit)" -f $yolYedek,(Dizi $yedek).Count) -ForegroundColor DarkCyan

# --- PARALEL KOSU -------------------------------------------------------------
$env:MEVZUAT_CLAIM='0'
$logDir=Join-Path $depoKok 'veri\fabrika\kurtarma-log'; New-Item -ItemType Directory -Force $logDir|Out-Null
function Tir([string]$s){ if($s -match '\s'){ return ('"'+$s+'"') }; return $s }
$kuyruk=New-Object System.Collections.Generic.Queue[object]
foreach($x in (Dizi $is | Sort-Object adet -Descending)){ $kuyruk.Enqueue($x) }
$ucan=New-Object System.Collections.Generic.List[object]
$sira=0; $bitti=0
while($kuyruk.Count -gt 0 -or $ucan.Count -gt 0){
  while($ucan.Count -lt $Paralel -and $kuyruk.Count -gt 0){
    $x=$kuyruk.Dequeue(); $sira++
    $log=Join-Path $logDir ("$($x.etiket).log")
    Write-Host ("[{0}] {1}/{2} {3} · {4} soru · ucan {5}" -f (Get-Date -Format HH:mm),$sira,(Dizi $is).Count,$x.etiket,$x.adet,($ucan.Count+1)) -ForegroundColor Cyan
    $arg=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Tir $uret),
           '-Sinav','SGS','-DersRegex',(Tir $x.ders),'-Etiket',(Tir $x.etiket),
           '-Adet',"$($x.adet)",'-CizmeAtla','-PilotId',(Tir $x.idler))
    $ps=Start-Process -FilePath 'powershell' -ArgumentList $arg -PassThru -WindowStyle Hidden `
                      -RedirectStandardOutput $log -RedirectStandardError ("$log.err")
    $ucan.Add([pscustomobject]@{ x=$x; ps=$ps })
  }
  if(-not $ucan.Count){ break }
  [void]$ucan[0].ps.WaitForExit(5000)
  foreach($a in $ucan.ToArray()){
    if(-not $a.ps.HasExited){ continue }
    try{ $a.ps.WaitForExit() }catch{}
    $bitti++
    [void]$ucan.Remove($a)
  }
}
Write-Host ("`nKOSU BITTI: {0} parti" -f $bitti) -ForegroundColor Green

# --- SONUC --------------------------------------------------------------------
$kurtulan=0; $halaDusen=0; $kayit=New-Object System.Collections.Generic.List[object]
$ambarEksik=New-Object System.Collections.Generic.List[object]
foreach($r in (Dizi $yedek)){
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$($r.etiket).json"
  if(-not (Test-Path $f)){ continue }
  $c=Get-Content $f -Raw -Encoding UTF8|ConvertFrom-Json
  $v=$c.($r.id); if(-not $v -or -not $v.hakem){ continue }
  $yeni="$($v.hakem.karar)"
  $ger=(("$($v.hakem.gerekce)") -replace '\s+',' ').Trim()
  if($yeni -eq 'EVET'){ $kurtulan++ } else { $halaDusen++ }
  $kayit.Add([ordered]@{ etiket=$r.etiket; id=$r.id; ders=$r.ders; konu=$r.konu; eski=$r.eskiKarar; yeni=$yeni; gerekce=$ger })
  # AMBAR EKSIGI: gerekce belirli bir KANUN MADDESI'nin kaynakta olmadigini soyluyorsa
  if($yeni -ne 'EVET'){
    foreach($m in [regex]::Matches($ger,'(?i)(\d{3,5})\s*say[ıi]l[ıi][^,;.]{0,40}?\bm\.?\s*(\d{1,4})')){
      $ambarEksik.Add([ordered]@{ etiket=$r.etiket; id=$r.id; konu=$r.konu; kanun=$m.Groups[1].Value; madde=$m.Groups[2].Value; gerekce=$ger })
    }
    foreach($m in [regex]::Matches($ger,'(?i)\b(IYUK|VUK|TTK|TBK|KVK|GVK|KDVK|AATUHK|BDS|TMS|TFRS)\s*m\.?\s*(\d{1,4})')){
      $ambarEksik.Add([ordered]@{ etiket=$r.etiket; id=$r.id; konu=$r.konu; kanun=$m.Groups[1].Value.ToUpperInvariant(); madde=$m.Groups[2].Value; gerekce=$ger })
    }
  }
}
$top=$kurtulan+$halaDusen
Write-Host "`n=== SONUC ===" -ForegroundColor Cyan
Write-Host ("KURTULAN (HAYIR -> EVET): {0:N0}/{1:N0}  (%{2:N1})" -f $kurtulan,$top,$(if($top){100*$kurtulan/[double]$top}else{0})) -ForegroundColor Green
Write-Host ("HALA DUSEN              : {0:N0}" -f $halaDusen)
Write-Host "`nDERS DERS:"
foreach($g in ((Dizi $kayit)|Group-Object ders|Sort-Object Name)){
  $k=@($g.Group|Where-Object{$_.yeni -eq 'EVET'}).Count
  Write-Host ("  {0,-32} {1,4}/{2,-4} %{3,5:N1}" -f $g.Name,$k,$g.Count,(100*$k/[double]$g.Count))
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\kurtarma-turu.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); tur=$turAd; sinif=$Sinif
  yontem='hakem karari + eski kaynak paketi silindi; paket KAPI-KP ile yeniden kuruldu, hakem yeniden soruldu. SORU YENIDEN YAZILMADI.'
  soru=$top; kurtulan=$kurtulan; hala_dusen=$halaDusen
  kurtarma_orani=$(if($top){[math]::Round(100*$kurtulan/[double]$top,1)}else{0})
  yedek=$yolYedek
  kayitlar=@((Dizi $kayit)|ForEach-Object{ [pscustomobject]$_ })
})
# Ambar eksigi: benzersiz kanun|madde
$benzersiz=@{}
foreach($a in (Dizi $ambarEksik)){ $benzersiz["$($a.kanun) m.$($a.madde)"]=$a }
RaporYaz -Hedef (Join-Path $depoKok 'veri\kurtarma-ambar-eksigi.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kural='Kurtarma turunda hakem "kaynak metni su maddeyi ICERMEMEKTEDIR" dedi. Bunlar PAKET sorunu degil AMBAR EKSIGI - yutma is emri.'
  benzersiz_madde=$benzersiz.Count; toplam_vaka=(Dizi $ambarEksik).Count
  maddeler=@($benzersiz.Keys|Sort-Object)
  kayitlar=@((Dizi $ambarEksik)|ForEach-Object{ [pscustomobject]$_ })
})
Write-Host ("`nAMBAR EKSIGI: {0} benzersiz madde ({1} vaka) -> veri/kurtarma-ambar-eksigi.json" -f $benzersiz.Count,(Dizi $ambarEksik).Count) -ForegroundColor Yellow
Write-Host "-> veri/kurtarma-turu.json" -ForegroundColor Green
