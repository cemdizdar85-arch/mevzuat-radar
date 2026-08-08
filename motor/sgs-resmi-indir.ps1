# ============================================================================
#  SGS KITAPCIKLARI - RESMI KAYNAKTAN (TESMER) 2015-2026 - 08.08.2026
#
#  CEM: "hepsini resmi kaynaktan indir 2015 kadar"
#
#  NEDEN GEREKLI: kitapciklarin cogu aktifonline.net'ten indirilmisti ve o
#  arsiv BOZUK - "18_Nisan_2026" adli dosya ile "22_Kasim_2025" dosyasi BAYT
#  BAYT AYNI (md5 esit). Bu yuzden 2026/1 kaydimiz sahteydi ve arsivde %54,7
#  gibi imkansiz bir konu ortusmesi goruluyordu. TESMER'in kendi sunucusunda
#  bu karisiklik yok.
#
#  TESMER'in sinav arsivi SAYFASI kirik (?p=2050 - icinde hala "Lorem ipsum"
#  var, duyurulardaki "tiklayiniz" oraya gidiyor), ama DOSYALAR duruyor ve
#  adres kalibi duzenli. Iki kalip var:
#     2016-2026 : sgs_{y}_{d}_lisans_a_grubu_ingilizce.pdf
#     2015      : sgs_{y}_{d}_lisans_a_grubu.pdf          (dil eki YOK)
#
#  BEDAVA: indirme + pdftotext. API yok. TR IP'li makinede kosar.
# ============================================================================
param([int]$basYil = 2015, [int]$sonYil = 2026, [switch]$zorla)
$ErrorActionPreference='Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$tmp = Join-Path $env:TEMP 'cikmis-soru-resmi'
if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp | Out-Null }
$B = 'https://www2.tesmer.org.tr/files/ortak/soru_cevaplar/sgs'
$md5 = [Security.Cryptography.MD5]::Create()
$gorulen = @{}
$rapor = New-Object System.Collections.Generic.List[object]
$ok=0; $yok=0; $mukerrer=0

foreach($y in $basYil..$sonYil){
  foreach($d in 1..3){
    $adaylar = @(
      ('{0}/{1}/lisans_a_grubu/sgs_{0}_{1}_lisans_a_grubu_ingilizce.pdf' -f $y,$d),
      ('{0}/{1}/lisans_a_grubu/sgs_{0}_{1}_lisans_a_grubu.pdf' -f $y,$d)
    )
    $pdf = Join-Path $tmp ("SGS-{0}_{1}.pdf" -f $y,$d)
    if((Test-Path $pdf) -and -not $zorla){
      $ok++; $rapor.Add([pscustomobject]@{ donem=("$y/$d"); durum='ZATEN VAR'; bayt=(Get-Item $pdf).Length }); continue
    }
    $indi = $false
    foreach($a in $adaylar){
      $u = "$B/$a"
      try { Invoke-WebRequest -Uri $u -OutFile $pdf -UserAgent 'Mozilla/5.0' -TimeoutSec 90 -UseBasicParsing } catch { continue }
      if(-not (Test-Path $pdf)){ continue }
      $bayt = (Get-Item $pdf).Length
      if($bayt -lt 50000){ Remove-Item $pdf -Force -ErrorAction SilentlyContinue; continue }
      $h = [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($pdf))).Replace('-','').ToLower()
      if($gorulen.ContainsKey($h)){
        $mukerrer++
        $rapor.Add([pscustomobject]@{ donem=("$y/$d"); durum='MUKERRER'; not=('ayni: ' + $gorulen[$h]) })
        Remove-Item $pdf -Force -ErrorAction SilentlyContinue
        $indi = $true; break
      }
      $gorulen[$h] = "$y/$d"
      $ok++; $indi = $true
      $rapor.Add([pscustomobject]@{ donem=("$y/$d"); durum='OK'; bayt=$bayt; adres=$u })
      Write-Host ("  OK  {0}/{1}  {2,9} bayt" -f $y,$d,$bayt)
      Start-Sleep -Milliseconds 600
      break
    }
    if(-not $indi){ $yok++; $rapor.Add([pscustomobject]@{ donem=("$y/$d"); durum='YOK' }); Write-Host ("  --  {0}/{1}  bulunamadi" -f $y,$d) }
  }
}
Write-Host ("`nOK {0} | MUKERRER {1} | BULUNAMADI {2}" -f $ok,$mukerrer,$yok)
Write-Host "`n--- YIL YIL ---"
foreach($y in $basYil..$sonYil){
  $g = @($rapor | Where-Object { $_.donem -like ("$y/*") })
  $v = @($g | Where-Object { $_.durum -in @('OK','ZATEN VAR') }).Count
  Write-Host ("  {0}  {1}/3 donem" -f $y,$v)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\sgs-resmi-indirme.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ok=$ok; mukerrer=$mukerrer; bulunamadi=$yok; klasor=$tmp; kayitlar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host ("`nRapor: veri/sgs-resmi-indirme.json   Klasor: {0}" -f $tmp)
