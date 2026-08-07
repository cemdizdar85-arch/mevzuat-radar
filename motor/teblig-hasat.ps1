# ============================================================================
#  TEBLIG HASAT ROBOTU — 07.08.2026 (YUTMA-LISTESI'nin 'yarim saatlik is'i)
#
#  KESIF: mevzuat.gov.tr /Anasayfa/MevzuatDatatable POST ucu (cerezli oturum +
#  XHR basligiyla) fihristi JSON dondurur. ILK KOSUDA YAKALANAN: VUK GT
#  591/592/593 (Subat-Mayis 2026) manifestimizde YOKTU - fihrist nobetcisi
#  olmadigi icin sessizce kacmisti. Bu robot o deligi kapatir.
#
#  NE YAPAR: takip basliklarini fihristten sorgular; manifest'te (pdfId
#  G9:<mevzuatNo>) olmayan kayitlari BULUR, manifeste EKLER (Cem kurali:
#  'otomatik guncelleme varsayilan' + robot raporlar), rapor yazar. Yeni
#  eklenen teblig ertesi yerel-ayna kosusunda ambara iner (ayna basinda
#  kosarsa AYNI kosuda iner - zincir oyle bagli).
#
#  Bot korumasi: once ana sayfadan cerez alinir (yerel-ayna deseni).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$manYol = Join-Path $kok 'veri\mevzuat-kaynaklar.json'
$raporYol = Join-Path $kok 'veri\teblig-hasat-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# takip basliklari: baslik-deseni -> slug oneki
$TAKIP = @(
  @{ ara='VERGİ USUL KANUNU GENEL TEBLİĞİ';                     onek='vukgt' },
  @{ ara='GELİR VERGİSİ GENEL TEBLİĞİ';                          onek='gvkgt' },
  @{ ara='KATMA DEĞER VERGİSİ GENEL UYGULAMA TEBLİĞİNDE DEĞİŞİKLİK'; onek='kdvgutd' },
  @{ ara='KURUMLAR VERGİSİ GENEL TEBLİĞİ';                       onek='kvkgt' },
  @{ ara='ÖZEL TÜKETİM VERGİSİ';                                 onek='otvgt' },
  @{ ara='SERBEST MUHASEBECİ MALİ MÜŞAVİRLİK';                   onek='smmmgt' },
  @{ ara='ASGARİ ÜCRET TESPİT KOMİSYONU';                        onek='asgariucret' }
)

$oturum = $null
Invoke-WebRequest -Uri 'https://www.mevzuat.gov.tr/' -UserAgent $UA -TimeoutSec 45 -UseBasicParsing -SessionVariable oturum | Out-Null

$man = Get-Content $manYol -Raw -Encoding UTF8 | ConvertFrom-Json
$mevcutNo = @{}
foreach($l in $man.kanunlar){ if("$($l.pdfId)" -like 'G9:*'){ $mevcutNo["$($l.pdfId)".Substring(3)] = $l.slug } }
Write-Host ("manifest: {0} kaynak, {1} G9-teblig" -f @($man.kanunlar).Count, $mevcutNo.Count)

$yeniler = New-Object System.Collections.Generic.List[object]
foreach($t in $TAKIP){
  $govNesne = @{ draw=1; start=0; length=25; parameters=@{ AranacakIfade=$t.ara; AranacakYer='2'; MevzuatTur='Teblig'; TamCumle=$false } }
  $gov = ConvertTo-Json -InputObject $govNesne -Depth 4 -Compress
  $r = Invoke-WebRequest -Uri 'https://www.mevzuat.gov.tr/Anasayfa/MevzuatDatatable' -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -ContentType 'application/json; charset=UTF-8' -Headers @{ 'X-Requested-With'='XMLHttpRequest'; Referer='https://www.mevzuat.gov.tr/' } -UserAgent $UA -WebSession $oturum -TimeoutSec 60 -UseBasicParsing
  $j = ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())) | ConvertFrom-Json
  foreach($d in @($j.data)){
    $no = "$($d.mevzuatNo)"
    if($mevcutNo.ContainsKey($no)){ continue }
    $ad = ("$($d.mevAdi)" -replace '<[^>]+>','' -replace '\s+',' ').Trim()
    # slug: 'SIRA NO: 593' varsa onek+sira, yoksa onek+mevzuatNo
    $sira = ''
    $ms = [regex]::Match($ad, 'SIRA NO[:\s]*(\d+)')
    $slug = if($ms.Success){ $t.onek + $ms.Groups[1].Value } else { $t.onek + '-' + $no }
    if(@($man.kanunlar | Where-Object { $_.slug -eq $slug }).Count){ $slug = $t.onek + '-' + $no }
    $yeniler.Add([pscustomobject]@{ slug=$slug; ad=$ad; pdfId=('G9:'+$no); rg="$($d.resmiGazeteTarihi)"
      not=('teblig-hasat robotu ekledi ' + (Get-Date -Format 'dd.MM.yyyy') + ' (RG ' + $d.resmiGazeteTarihi + '); fihrist nobetcisi kesfi') })
  }
  Start-Sleep -Seconds 2
}
Write-Host ("YENI bulunan: {0}" -f $yeniler.Count)
$yeniler | ForEach-Object { Write-Host ("  + {0} <- {1} (RG {2})" -f $_.slug, $_.ad.Substring(0,[Math]::Min(60,$_.ad.Length)), $_.rg) }

if($yeniler.Count){
  foreach($y in $yeniler){
    $man.kanunlar += [pscustomobject]@{ slug=$y.slug; ad=$y.ad; pdfId=$y.pdfId; not=$y.not; seyrek=$true }
  }
  [IO.File]::WriteAllText($manYol, (ConvertTo-Json -InputObject $man -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host 'manifest guncellendi.'
}
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  taranan_baslik=@($TAKIP).Count; yeni=$yeniler.Count
  eklenenler=@($yeniler | Select-Object slug,ad,pdfId,rg)
})
Write-Host 'TEBLIG HASAT TAMAM.'
