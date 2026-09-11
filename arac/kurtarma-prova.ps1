#requires -Version 5.1
<#
================================================================================
  KURTARMA PROVASI — KAYNAK-EKSIK sorular paket duzelince kurtuluyor mu?
  11.09.2026, Cem "1 kurtarma provasi yap"

  SORU: Ret kutugunde 777 soru KAYNAK-EKSIK sinifinda. Hakem "kaynak metinde
  bu kural yok" dedigi icin dustuler. SORU KENDISI SAGLAM olabilir - kusur
  PAKETTE. Ayni gun kurulan KAPI-KP (paket konuya gore SIRALANIR, sigmayan
  kaynak KOMPLE duser, yarim blok kalmaz) bu paketleri duzeltiyor.
  Paket duzelince hakem fikrini degistirir mi?

  YONTEM: 10 dersten 2'ser soru (20 soru, taraflilik olmasin diye ders ders).
  Her birinde `hakem` karari VE `kaynak_metin_ozet` SILINDI -> uretici paketi
  KAPI-KP ile yeniden kurar, hakem yeniden karar verir.
  Eski karar ve eski paket veri/fabrika/_kurtarma-yedek.json'da DURUYOR.

  ⛔ SORU YENIDEN YAZILMAZ. Yalniz paket yeniden kurulur ve hakem yeniden
     sorulur. Soru metni, siklar, aciklama AYNEN kalir.

  BEDEL: soru basina 1 hakem cagrisi (~0,008 USD). 20 soru ≈ 0,16 USD ≈ 7 TL.
================================================================================
#>
param([switch]$Yaz)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$ok=Test-OlcumKapilari -Sessiz
if((Dizi $ok).Count){ foreach($h in (Dizi $ok)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

$uret=Join-Path $depoKok 'motor\kalip-parti-uret.ps1'
$yHam=Get-Content (Join-Path $depoKok 'veri\fabrika\_kurtarma-yedek.json') -Raw -Encoding UTF8|ConvertFrom-Json
$y=@($yHam)
$grup=@($y|Group-Object etiket)
Write-Host ("KURTARMA PROVASI: {0} soru · {1} parti · tahmini {2:N2} USD" -f $y.Count,$grup.Count,($y.Count*0.008)) -ForegroundColor Cyan
if(-not $Yaz){
  Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Kosmak icin: -Yaz" -ForegroundColor Yellow
  foreach($g in $grup){ Write-Host ("  {0,-30} {1}" -f $g.Name,((@($g.Group)|ForEach-Object{$_.id}) -join ',')) }
  return
}

# ders adi: hakem KAPI-DR icin GERCEK ders adi ister ('.' YASAK)
$DERS_AD=@{ 'FMuh'='Finansal Muhasebe'; 'Denetim'='Denetim'; 'Maliyet'='Maliyet Muhasebesi'
  'MTA'='Mali Tablolar Analizi'; 'Ticaret'='Ticaret Hukuku'; 'Borclar'='Borclar Hukuku'
  'Vergi'='Vergi Hukuku'; 'Meslek'='Meslek Hukuku'; 'IsSGK'='Is ve Sosyal Guvenlik Hukuku'
  'Ekonomi'='Ekonomi'; 'Maliye'='Maliye' }
$env:MEVZUAT_CLAIM='0'
$logDir=Join-Path $depoKok 'veri\fabrika\kurtarma-log'; New-Item -ItemType Directory -Force $logDir|Out-Null
$sira=0
foreach($g in $grup){
  $sira++
  $idler=((@($g.Group)|ForEach-Object{$_.id}) -join ',')
  $ders=$DERS_AD[(@($g.Group)[0].ders)]
  if(-not $ders){ Write-Host ("  ATLANDI {0}: ders cozulemedi" -f $g.Name) -ForegroundColor Yellow; continue }
  $log=Join-Path $logDir ("$($g.Name).log")
  Write-Host ("[{0}] {1}/{2} {3} · {4} · {5}" -f (Get-Date -Format HH:mm),$sira,$grup.Count,$g.Name,$ders,$idler)
  $arg=@('-Sinav','SGS','-DersRegex',$ders,'-Etiket',"$($g.Name)",'-Adet',"$(@($g.Group).Count)",'-CizmeAtla','-PilotId',$idler)
  & powershell -NoProfile -ExecutionPolicy Bypass -File $uret @arg *> $log
}

# --- SONUC --------------------------------------------------------------------
Write-Host "`n=== SONUC ===" -ForegroundColor Cyan
$kurtulan=0; $halaDusen=0; $karsilastirma=New-Object System.Collections.Generic.List[object]
foreach($r in $y){
  $f=Join-Path $depoKok "veri\fabrika\kalip-parti-$($r.etiket).json"
  if(-not (Test-Path $f)){ continue }
  $c=Get-Content $f -Raw -Encoding UTF8|ConvertFrom-Json
  $v=$c.($r.id); if(-not $v -or -not $v.hakem){ continue }
  $yeni="$($v.hakem.karar)"
  if($yeni -eq 'EVET'){ $kurtulan++ } else { $halaDusen++ }
  $karsilastirma.Add([ordered]@{ etiket=$r.etiket; id=$r.id; ders=$r.ders; konu=$r.konu
    eski="$($r.eskiKarar)"; yeni=$yeni
    yeniGerekce=(("$($v.hakem.gerekce)") -replace '\s+',' ').Trim() })
}
$top=$kurtulan+$halaDusen
Write-Host ("KURTULAN (HAYIR -> EVET) : {0}/{1}  (%{2:N1})" -f $kurtulan,$top,$(if($top){100*$kurtulan/[double]$top}else{0})) -ForegroundColor Green
Write-Host ("HALA DUSEN               : {0}/{1}" -f $halaDusen,$top)
Write-Host ""
foreach($z in (Dizi $karsilastirma)){
  $renk=if($z.yeni -eq 'EVET'){'Green'}else{'DarkGray'}
  Write-Host ("  {0,-9} {1,-32} {2} -> {3}" -f $z.ders,$z.konu,$z.eski,$z.yeni) -ForegroundColor $renk
  if($z.yeni -ne 'EVET'){ $g2=$z.yeniGerekce; if($g2.Length -gt 130){$g2=$g2.Substring(0,130)+'…'}; Write-Host ("       $g2") -ForegroundColor DarkGray }
}
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\kurtarma-prova.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  yontem='KAYNAK-EKSIK sinifindaki sorularda hakem karari VE eski kaynak paketi silindi; paket KAPI-KP ile yeniden kuruldu, hakem yeniden soruldu. SORU YENIDEN YAZILMADI.'
  soru=$top; kurtulan=$kurtulan; hala_dusen=$halaDusen
  kurtarma_orani=$(if($top){[math]::Round(100*$kurtulan/[double]$top,1)}else{0})
  kayitlar=@(Dizi $karsilastirma | ForEach-Object { [pscustomobject]$_ })
})
Write-Host "`n-> veri/kurtarma-prova.json" -ForegroundColor Green
