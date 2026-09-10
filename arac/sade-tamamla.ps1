#requires -Version 5.1
<#
================================================================================
  SADE TAMAMLAMA TURU — üretilmiş soruya FAZ S'i sonradan koşar (11.09.2026)
  Cem: "sade olsun ve 650 soruyu basalım"

  NEDEN: `sade` (Sade Doğrusu + sınav dili + anahtar kavramlar) Kaydır-Çöz
  ekranının 2. ve 5. parçasıdır. Ölçüldü (10.09): 213 partinin yalnız 15'inde
  var, hepsi 04-06.09 arası ELLE koşulan partiler. 07.09'da toplu hatta
  geçilirken `kalip-kosucu.ps1`in argüman listesine `-Sade` KONMAMIŞ; 198 parti
  FAZ S çalışmadan üretti. Üretici bozulmadı — çağrılmayan bir faz vardı.

  BU BETİK YENİDEN ÜRETMEZ. Soru, şık, açıklama, HAP, tuzak, dayanak hepsi
  yerinde; yalnız eksik alan doldurulur. FAZ S zaten `sade`si olanı atlar.

  ⛔ BEDEL EMNİYETİ — üç katman:
    1) -PilotId : model fazları YALNIZ seçili id'lere koşar. Parti dosyasında
       500 soru olsa da yalnız listedekiler işlenir.
    2) -Tavan   : toplam soru tavanı. Aşılırsa DURUR.
    3) Kuru koşu varsayılan: -Yaz demeden HİÇBİR API çağrısı yapılmaz.
  09.09 dersi: `uret.ps1` sınamak için çalıştırıldı, gerçek üretim başladı,
  5,75 USD gitti. O yüzden bu betik varsayılanda hiçbir şey harcamaz.

  ÖLÇÜLEN BEDEL: 0,009 USD/soru (Haiku 4.5, 10.09 provası: 6 soru / 0,054 USD).

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sade-tamamla.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/sade-tamamla.ps1 -Yaz
================================================================================
#>
param(
  [switch]$Yaz,                       # olmadan: kuru koşu, bedel 0
  [int]$Tavan = 700,                  # toplam soru tavanı
  [string]$PlanDosyasi = 'veri\_sade-plan.json'   # ⚠ adi "$Plan" OLMAZ: asagidaki
)                                                 # is listesi $isler'e okunur; PS harf
                                                  # ayirmadigi icin [string] tur kisiti
                                                  # diziyi sessizce string'e cevirirdi.
$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$uret    = Join-Path $depoKok 'motor\kalip-parti-uret.ps1'
$logDir  = Join-Path $depoKok 'veri\fabrika\sade-log'
if(-not (Test-Path $logDir)){ New-Item -ItemType Directory -Force $logDir | Out-Null }

$planYol = if([IO.Path]::IsPathRooted($PlanDosyasi)){ $PlanDosyasi } else { Join-Path $depoKok $PlanDosyasi }
$isler = @((Get-Content $planYol -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })
$toplam = ($isler | Measure-Object -Property adet -Sum).Sum
Write-Host ("PLAN: {0} parti · {1} soru · tahmini {2:N2} USD" -f $isler.Count, $toplam, ($toplam*0.009)) -ForegroundColor Cyan
if($toplam -gt $Tavan){ throw "TAVAN ASILDI: $toplam soru > $Tavan. Bilerek asilacaksa -Tavan yukselt." }
if(-not $Yaz){
  Write-Host "`nKURU KOSU - hicbir API cagrisi yapilmadi. Gercekten kosmak icin: -Yaz" -ForegroundColor Yellow
  $isler | Sort-Object adet -Descending | ForEach-Object { Write-Host ("  {0,-38} {1,3} soru" -f $_.etiket,$_.adet) }
  return
}

# Bitis damgasi olan partide uretici "ATLANDI" deyip cikar; tamamlama turunda
# damgayi asmak GEREKLI - yeni soru uretmiyoruz, var olani tamamliyoruz.
$env:MEVZUAT_CLAIM = '0'

$sira=0; $basarili=0; $dusen=0
foreach($p in ($isler | Sort-Object adet -Descending)){
  $sira++
  $log = Join-Path $logDir ("$($p.etiket).log")
  Write-Host ("[{0}] {1}/{2}  {3}  ({4} soru)" -f (Get-Date -Format HH:mm), $sira, $isler.Count, $p.etiket, $p.adet)
  $arg = @('-Sinav','SGS','-DersRegex','.','-Etiket',"$($p.etiket)",'-Adet',"$([int]$p.adet)",'-Sade','-PilotId',"$($p.idler)")
  try{
    & powershell -NoProfile -ExecutionPolicy Bypass -File $uret @arg *> $log
    $bedel = (Select-String -Path $log -Pattern 'BEDEL TOPLAM' | Select-Object -Last 1).Line
    if($bedel){ Write-Host ("      {0}" -f $bedel.Trim()) }
    $basarili++
  }catch{
    $dusen++
    Write-Host ("      ! DUSTU: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
  }

  # Her partiden sonra NABIZ: kac soruda sade doldu (iddia degil sayim)
  try{
    $c = Get-Content (Join-Path $depoKok "veri\fabrika\kalip-parti-$($p.etiket).json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $n=0;$s=0
    foreach($pp in $c.PSObject.Properties){ $v=$pp.Value; if(-not $v.soru){continue}; $n++; if($v.sade -and $v.sade.dogru){$s++} }
    Write-Host ("      NABIZ: sade {0}/{1}" -f $s,$n)
  }catch{}
}
Write-Host ""
Write-Host ("TAMAMLAMA TURU BITTI: {0} parti basarili · {1} dustu" -f $basarili,$dusen) -ForegroundColor Green
Write-Host "Siradaki: motor/kaydir-coz.ps1 -SecimDosya <yayin-sgs-*.json>"
