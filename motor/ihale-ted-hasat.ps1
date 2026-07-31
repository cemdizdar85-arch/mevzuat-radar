# ============================================================================
#  IHALE TED HASAT - AB resmi ihale bulteni (TED, ted.europa.eu) acik API v3.
#  31.07 Cem: "yurt disinda sadece bu ihaleler mi var? kendini guncelliyor mu?"
#  -> Tohum 6 ilan yerine SEKTOR SEKTOR canli cekim. Anonim API, ucretsiz.
#  Her sektorun CPV'leri icin aktif (son teklif > bugun) ihaleler cekilir,
#  sektor basina en yeni 6, mukerrer ayiklanir -> veri/ihale-ted.json.
#  Robot: kaynak.yml (gunde 2). API bos/hata donerse eski json KORUNUR.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$USUL_TR = @{ open="Açık usul"; restricted="Belli istekliler arası"; negotiated="Pazarlık usulü";
  "neg-w-call"="Pazarlık (ilanlı)"; "neg-wo-call"="Pazarlık (ilansız)"; "comp-dial"="Rekabetçi diyalog";
  "comp-tend"="Rekabetçi usul"; innovation="Yenilik ortaklığı"; "oth-mult"="Diğer (çok aşamalı)"; "oth-single"="Diğer (tek aşamalı)" }

function CevirBaslik($obj){
  if($null -eq $obj){ return "" }
  if($obj -is [string]){ return $obj }
  $p = $obj.PSObject.Properties
  $eng = $p | Where-Object { $_.Name -eq 'eng' } | Select-Object -First 1
  $sec = if($eng){ $eng.Value } else { ($p | Select-Object -First 1).Value }
  if($sec -is [array]){ return "$($sec[0])" }
  return "$sec"
}

# sektor -> CPV on-ekleri (2 ya da 4 hane) -> 8 haneli TED koduna doldurulur
$cpvDosya = Get-Content (Join-Path $kok 'veri/cpv-eslesme.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$ihaleler = @(); $gorulen = @{}
$sektorSayac = 0

foreach($sek in $cpvDosya.sektorler){
  $kodlar = @($sek.cpv | ForEach-Object { ("$_" + "00000000").Substring(0,8) }) | Sort-Object -Unique
  if(-not $kodlar.Count){ continue }
  $sorgu = "(classification-cpv IN (" + ($kodlar -join ' ') + ")) AND deadline-receipt-tender-date-lot > today()"
  # NOT: sortField parametresi API'de YOK (400 doner) - varsayilan sirayla alinir
  $govde = @{ query = $sorgu
    fields = @("publication-number","notice-title","buyer-name","buyer-country","classification-cpv","deadline-receipt-tender-date-lot","procedure-type","publication-date")
    limit = 6; page = 1; scope = "ACTIVE" } | ConvertTo-Json -Depth 4
  # TED hiz siniri (429) icin: 3 deneme, aralarda 20 sn bekleme
  $r = $null
  for($deneme = 1; $deneme -le 3; $deneme++){
    try {
      $w = Invoke-WebRequest -Method Post -Uri "https://api.ted.europa.eu/v3/notices/search" `
        -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" `
        -Headers @{ Accept = "application/json" } -UseBasicParsing -TimeoutSec 90
      $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
      $r = $ham | ConvertFrom-Json
      break
    } catch {
      $mesaj = $_.Exception.Message
      if($mesaj -match '429' -and $deneme -lt 3){ Start-Sleep -Seconds 20; continue }
      Write-Host "  ATLA ($($sek.ad)): $mesaj"
      break
    }
  }
  if($null -eq $r){ continue }
  $sektorSayac++
  foreach($n in @($r.notices)){
    $no = "$($n.'publication-number')"
    if(-not $no -or $gorulen.ContainsKey($no)){ continue }
    $gorulen[$no] = $true
    $ulkeHam = $n.'buyer-country'; if($ulkeHam -is [array]){ $ulkeHam = $ulkeHam[0] }
    $cpvHam = $n.'classification-cpv'; if($cpvHam -is [array]){ $cpvHam = $cpvHam[0] }
    $sonHam = "$($n.'deadline-receipt-tender-date-lot')"; if($sonHam -is [array]){ $sonHam = "$($sonHam[0])" }
    $usulHam = "$($n.'procedure-type')"
    $ihaleler += [ordered]@{
      no = $no
      ulke = "$ulkeHam"
      cpv = "$cpvHam"
      sonTeklif = if($sonHam.Length -ge 10){ $sonHam.Substring(0,10) } else { $sonHam }
      usul = if($USUL_TR.ContainsKey($usulHam)){ $USUL_TR[$usulHam] } else { $usulHam }
      baslik = CevirBaslik $n.'notice-title'
      alici = CevirBaslik $n.'buyer-name'
      url = "https://ted.europa.eu/en/notice/$no/pdf"
    }
  }
  Start-Sleep -Seconds 2
}

if($ihaleler.Count -lt 5){ Write-Host "UYARI: yalniz $($ihaleler.Count) ilan geldi - json GUNCELLENMEDI (eski veri korunur)"; exit 0 }

$cikti = [ordered]@{
  guncelleme = "AB resmî ihale bülteni TED (ted.europa.eu, AB Yayın Ofisi) açık API v3. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + ". Sektör başına en yeni aktif ilanlar (son teklif tarihi geçmemiş). Rakam disiplini: yalnız API'den gelen gerçek ilanlar."
  kaynak = "ted.europa.eu (Publications Office of the EU)"
  ihaleler = $ihaleler
}
($cikti | ConvertTo-Json -Depth 5) | Out-File (Join-Path $kok "veri/ihale-ted.json") -Encoding utf8
Write-Host ("TED HASAT: {0} sektorden {1} aktif ihale -> veri/ihale-ted.json" -f $sektorSayac, $ihaleler.Count)
