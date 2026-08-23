# ============================================================================
#  TESMER CIKMIS SINAV ARSIVI - KESIF TARAMASI  - 23.08.2026
#
#  NEDEN: envanterimiz (veri/sinav-arsiv.json) SGS'de 2015'ten, yeterlilikte
#  2021'den basliyordu. 23.08 ornekleme gosterdi ki TESMER cok daha geriye
#  gidiyor: SGS 2005, yeterlilik 2008. Ayrica SGS'nin B grubu ve almanca/
#  fransizca kitapciklari hic toplanmamis.
#
#  TUZAK (kayitli ders): TESMER olmayan dosyada 404 DEGIL, 200 + HTML hata
#  sayfasi donuyor. Bu yuzden StatusCode'a GUVENILMEZ - Content-Type ve
#  Content-Length denetlenir. Ayni tuzak daha once "ASCII'lesmis Turkce dosya
#  adi HTML hata sayfasi indirir" olarak olculmustu.
#
#  Cikti: veri/sinav-arsiv-kesif.json  (yalniz GERCEK PDF satirlari)
#  BEDAVA - yalniz HEAD istegi, indirme yok.
# ============================================================================
param(
  [int]$IlkYil = 2005,
  [int]$SonYil = 2026,
  [int]$Bekleme = 250,
  [switch]$YalnizSGS,
  [switch]$YalnizSMMM
)
$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$kok = Split-Path -Parent $PSScriptRoot
$UA  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
$B   = 'https://www2.tesmer.org.tr/files/ortak/soru_cevaplar'

# GERCEK PDF mi? html donduyse veya 20 KB'in altindaysa YOK sayilir.
function PdfMi([string]$u){
  try {
    $r = Invoke-WebRequest -Uri $u -Method Head -UserAgent $UA -TimeoutSec 25 -UseBasicParsing -ErrorAction Stop
    if("$($r.Headers['Content-Type'])" -match 'html'){ return 0 }
    $b = 0; [void][int]::TryParse("$($r.Headers['Content-Length'])", [ref]$b)
    if($b -lt 20000){ return 0 }
    return $b
  } catch { return 0 }
}

$bulunan = New-Object System.Collections.Generic.List[object]
$denenen = 0

if(-not $YalnizSMMM){
  Write-Host 'SGS taraniyor...'
  foreach($y in $IlkYil..$SonYil){
    foreach($d in 1..3){
      foreach($grup in 'lisans_a_grubu','lisans_b_grubu'){
        # 2015 ve oncesi dil ekisiz ad kullaniyor; ikisini de dene
        foreach($dil in 'ingilizce','almanca','fransizca',''){
          $ad = if($dil -eq ''){ "sgs_${y}_${d}_${grup}.pdf" } else { "sgs_${y}_${d}_${grup}_${dil}.pdf" }
          $u  = "$B/sgs/$y/$d/$grup/$ad"
          $denenen++
          $boy = PdfMi $u
          if($boy -gt 0){
            $bulunan.Add([pscustomobject]@{ sinav='SGS'; donem=("{0}/{1}" -f $y,$d); grup=$grup; dil=$(if($dil -eq ''){'-'}else{$dil}); bayt=$boy; url=$u })
            Write-Host ("  VAR  SGS {0}/{1} {2} {3}  {4} bayt" -f $y,$d,$grup,$(if($dil -eq ''){'(dilsiz)'}else{$dil}),$boy)
          }
          Start-Sleep -Milliseconds $Bekleme
        }
      }
    }
  }
}

if(-not $YalnizSGS){
  Write-Host 'YETERLILIK (SMMM) taraniyor...'
  foreach($y in $IlkYil..$SonYil){
    foreach($d in 1..3){
      foreach($ders in 1..8){
        $dd = '{0:00}' -f $ders
        $u  = "$B/smmm/$y/$d/$dd/smmm_${y}_${d}_${dd}.pdf"
        $denenen++
        $boy = PdfMi $u
        if($boy -gt 0){
          $bulunan.Add([pscustomobject]@{ sinav='SMMM'; donem=("{0}/{1}" -f $y,$d); grup=$dd; dil='-'; bayt=$boy; url=$u })
        }
        Start-Sleep -Milliseconds $Bekleme
      }
      $v = @($bulunan | Where-Object { $_.sinav -eq 'SMMM' -and $_.donem -eq ("{0}/{1}" -f $y,$d) }).Count
      if($v -gt 0){ Write-Host ("  VAR  SMMM {0}/{1}  {2}/8 ders" -f $y,$d,$v) }
    }
  }
}

$cikti = Join-Path $kok 'veri\sinav-arsiv-kesif.json'
[IO.File]::WriteAllText($cikti,
  (ConvertTo-Json -InputObject ([ordered]@{
     tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
     aciklama='TESMER cikmis sinav kesfi. YALNIZ gercek PDF (Content-Type html degil + >20 KB). TESMER olmayan dosyada 200+HTML donuyor, koda guvenilmez.'
     denenen=$denenen; bulunan=$bulunan.Count; satirlar=$bulunan.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host ("`nOZET: denenen={0} bulunan={1}" -f $denenen, $bulunan.Count)
Write-Host "Rapor: veri/sinav-arsiv-kesif.json"
