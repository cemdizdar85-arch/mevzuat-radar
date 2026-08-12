# ============================================================================
#  BEKLEYEN PARTI HASADI   (10.08.2026)
#
#  NEDEN: 10.08'de bekleyen-partiler.json'da 07.08 tarihli UC parti bulundu.
#  Ucu de "ended", 334 sorunun HEPSI basarili, sonuclar hala cekilebilir
#  durumda. Yani PARASI ODENMIS ama HASAT EDILMEMIS is.
#  Sigorta calismis (kimlikler kaydedilmis) ama hasat adimi atlanmis.
#
#  KAYIT KUSURU: o uc satir dosyaya NESNE olarak yazilmis
#  ("@{id=msgbatch_...; kaynak=...; emir=41}"), duz kimlik degil. Kurtarma
#  betikleri duz kimlik bekledigi icin okuyamamis - gozden kacmasinin sebebi
#  buyuk ihtimalle bu. Bu betik iki bicimi de okur.
#
#  PARA HARCAMAZ: yalnizca INDIRIR. Batch sonuclari 29 gun saklanir; ayni
#  parti ikinci kez GONDERILMEZ.
#
#  KASAYA YAZMAZ. Hasat dosyaya iner, sonra kapilardan gecirilir.
#  Cikti: veri/hasat-bekleyen-partiler.json
# ============================================================================
param([string]$liste = '', [switch]$temizle)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path $PSScriptRoot -Parent
if($liste -eq ''){ $liste = Join-Path $kok 'veri\bekleyen-partiler.json' }
# 12.08: cift hat - hedef api-hedef.ps1'den (anthropic | aws)
# DIKKAT: parti KIMLIGI hangi hedefte gonderildiyse hasat da O hedeften yapilir.
. (Join-Path $PSScriptRoot 'api-hedef.ps1')
$HEDEF = Get-ApiHedef
$AK = $HEDEF.anahtar
$HDR = $HEDEF.basliklar
$API_TABAN = $HEDEF.taban
Write-Host ("API hedefi: {0}" -f $HEDEF.ad)

if(-not (Test-Path $liste)){ Write-Host "Bekleyen parti dosyasi yok: $liste"; exit 0 }
$ham = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($liste,[Text.Encoding]::UTF8))

# Iki bicimi de coz: duz "msgbatch_..." ya da "@{id=msgbatch_...; ...}"
$kimlikler = New-Object System.Collections.Generic.List[object]
foreach($x in @($ham)){
  $t = "$x"
  $m = [regex]::Match($t,'msgbatch_[A-Za-z0-9]+')
  if(-not $m.Success){ continue }
  $bilgi = ''
  $mb = [regex]::Match($t,'kaynak=([^;}]+).*?emir=([^;}]+).*?sinav=([^;}]+).*?soru=([^;}]+)')
  if($mb.Success){ $bilgi = ("{0} emir={1} {2} {3} soru" -f $mb.Groups[1].Value.Trim(),$mb.Groups[2].Value.Trim(),$mb.Groups[3].Value.Trim(),$mb.Groups[4].Value.Trim()) }
  $kimlikler.Add([pscustomobject]@{ id=$m.Value; bilgi=$bilgi })
}
Write-Host ("Bekleyen parti kimligi: {0}" -f $kimlikler.Count)

$hasat = New-Object System.Collections.Generic.List[object]
$kalanlar = New-Object System.Collections.Generic.List[string]
$toplamGirdi = 0; $toplamCikti = 0

foreach($p in $kimlikler){
  Write-Host ''
  Write-Host ("--- {0}  {1}" -f $p.id,$p.bilgi)
  $st = $null
  try{ $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$($p.id)" -Headers $HDR -TimeoutSec 120 }
  catch{
    Write-Host ("  ERISILEMEDI: {0}" -f $_.Exception.Message)
    $kalanlar.Add($p.id); continue
  }
  Write-Host ("  durum: {0} | basarili {1} | hatali {2} | suresi gecen {3}" -f $st.processing_status,$st.request_counts.succeeded,$st.request_counts.errored,$st.request_counts.expired)
  if($st.processing_status -ne 'ended'){ Write-Host '  henuz bitmemis - listede birakiliyor'; $kalanlar.Add($p.id); continue }

  $adres = if($st.results_url){ "$($st.results_url)" } else { "$API_TABAN/v1/messages/batches/$($p.id)/results" }
  try{ $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 600 }
  catch{ Write-Host ("  SONUC CEKILEMEDI: {0}" -f $_.Exception.Message); $kalanlar.Add($p.id); continue }

  # PS7 metin saymadigi cevabi BYTE DIZISI dondurur; string sanip bolunce
  # her bayt ayri "satir" olur ve odenmis parti IKINCI kez cope gider.
  $metin = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  $satirlar = $metin -split "`r?`n"
  $alinan = 0
  foreach($sat in $satirlar){
    if("$sat".Trim().Length -eq 0){ continue }
    try{ $r = $sat | ConvertFrom-Json }catch{ continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $msj = $r.result.message
    $toplamGirdi += [int]$msj.usage.input_tokens
    $toplamCikti += [int]$msj.usage.output_tokens
    $govde = ''
    foreach($bl in @($msj.content)){ if("$($bl.type)" -eq 'text'){ $govde += "$($bl.text)" } }
    $hasat.Add([pscustomobject]@{
      parti=$p.id; bilgi=$p.bilgi; custom_id="$($r.custom_id)"
      stop="$($msj.stop_reason)"; girdiJeton=[int]$msj.usage.input_tokens
      ciktiJeton=[int]$msj.usage.output_tokens; metin=$govde
    })
    $alinan++
  }
  Write-Host ("  HASAT EDILDI: {0} cevap ({1:N0} KB)" -f $alinan,($metin.Length/1024))
}

Write-Host ''
Write-Host '================ HASAT SONUCU ================'
Write-Host ("Toplam cevap : {0}" -f $hasat.Count)
Write-Host ("Jeton        : girdi {0:N0} | cikti {1:N0}" -f $toplamGirdi,$toplamCikti)
$deger = ($toplamGirdi/1e6*5.0 + $toplamCikti/1e6*25.0)/2
Write-Host ("Bu isin degeri: ~{0:N2} USD (Batch fiyatiyla) - YENIDEN ODENMEDI" -f $deger)
Write-Host ("Listede kalan : {0}" -f $kalanlar.Count)

if($hasat.Count -gt 0){
  $yol = Join-Path $kok 'veri\hasat-bekleyen-partiler.json'
  [IO.File]::WriteAllText($yol, ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); cevap=$hasat.Count
    girdiJeton=$toplamGirdi; ciktiJeton=$toplamCikti
    not='PARASI ONCEDEN ODENMIS partilerin hasadi. Kasaya YAZILMADI - once kapilardan gecirilecek.'
    kayitlar=$hasat
  } | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("-> {0}" -f $yol)
}

if($temizle){
  # Hasat edilenler listeden dusurulur; edilemeyenler KALIR.
  [IO.File]::WriteAllText($liste, (ConvertTo-Json -InputObject ([object[]]$kalanlar) -Depth 3), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("bekleyen-partiler.json guncellendi - kalan {0} kimlik" -f $kalanlar.Count)
} else {
  Write-Host 'Liste DOKUNULMADI (-temizle ile hasat edilenler dusurulur).'
}
