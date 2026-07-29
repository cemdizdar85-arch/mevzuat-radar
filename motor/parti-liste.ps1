# ============================================================================
#  PARTI LISTESI — KAYIP PARTILERIN KIMLIGINI API'DEN GERI BUL   (0 USD)
#
#  NEDEN VAR: 29.07 emir #14'te on parti gonderildi, islendi, sonuclari
#  cekildi ve betik kasaya YAZMADAN once aylik harcama tavanina (429)
#  carpip oldu. Bellekteki sonuclar gitti. Parti kimlikleri o tarihte
#  loga yazilmadigi icin `-kurtar` ile cekilemedi - ~2.000 sorunun ucreti
#  odenmis, karsiligi alinamamisti.
#
#  AMA PARA HENUZ YANMIS DEGIL: Anthropic bitmis partilerin sonucunu
#  29 gun saklar ve SONUC CEKMEK UCRETSIZDIR - ucret parti islenirken
#  alinir, o zaten alinmistir. Eksik olan tek sey KIMLIKTI; bu betik
#  kimlikleri API'nin kendi liste ucundan geri buluyor.
#
#  BU BETIK PARA HARCAMAZ: tek bir GET cagrisi, hicbir uretim yok.
#  Ciktilari: veri/parti-listesi.json  +  veri/parti-liste-log.txt
#
#  429 NOTU: harcama tavani INFERENCE'i durdurur. Liste/sonuc uclarinin da
#  kapali olup olmadigi BILINMIYOR - bu kosunun asil olctugu sey bu.
#  Kapaliysa 1 Agustos'ta (tavan sifirlaninca) ayni betik tekrar kosar.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/parti-liste-log.txt') -Force | Out-Null } catch {}

$AK = "$env:ANTHROPIC_API_KEY".Trim()
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok - cikiliyor."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

Write-Host "Parti listesi cekiliyor (GET /v1/messages/batches)..."
$hepsi = New-Object System.Collections.Generic.List[object]
$sonra = ''
$sayfa = 0
try {
  while($true){
    $u = 'https://api.anthropic.com/v1/messages/batches?limit=100'
    if($sonra){ $u += "&after_id=$sonra" }
    $ham = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $HDR -TimeoutSec 120
    $govde = if($ham.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($ham.Content) } else { "$($ham.Content)" }
    $r = $govde | ConvertFrom-Json
    foreach($b in @($r.data)){ $hepsi.Add($b) }
    $sayfa++
    Write-Host ("  sayfa {0}: {1} parti (toplam {2})" -f $sayfa, @($r.data).Count, $hepsi.Count)
    if(-not $r.has_more){ break }
    $sonra = "$($r.last_id)"
    if($sayfa -ge 10){ break }
  }
} catch {
  Write-Host "LISTELEME BASARISIZ:"
  Write-Host ("  {0}" -f $_.Exception.Message)
  $govde2 = ""
  if($_.ErrorDetails -and $_.ErrorDetails.Message){ $govde2 = "$($_.ErrorDetails.Message)" }
  if($govde2){ Write-Host ("  sunucu: {0}" -f $govde2.Substring(0,[Math]::Min(500,$govde2.Length))) }
  Write-Host ""
  Write-Host "  YORUM: harcama tavani liste ucunu da kapatiyorsa kayip DEGIL,"
  Write-Host "  ERTELENMIS demektir. 1 Agustos'ta tavan sifirlaninca bu betik"
  Write-Host "  tekrar kosar ve kimlikler geri gelir; sonuclar 29 gun saklaniyor."
  try{Stop-Transcript|Out-Null}catch{}
  exit 1
}

Write-Host ""
Write-Host ("TOPLAM {0} parti bulundu." -f $hepsi.Count)
Write-Host ""
# 29.07 - GM HATASI, DUZELTILDI: bu satir parantezsizdi
#   Write-Host "{0}..." -f 'A','B'
# PowerShell '-f' operatorunu Write-Host'un PARAMETRESI sanip diziyi
# ForegroundColor'a baglamaya calisiyor ve betik ORADA oluyor. Ilk kosuda
# 162 parti BASARIYLA cekildi ama tam bu satirda patladi, dosya yazilamadi
# ve "para yandi" sanildi. Format operatoru Write-Host icinde HEP parantezle.
Write-Host ("{0,-30} {1,-12} {2,8} {3,8} {4}" -f 'KIMLIK','DURUM','BITEN','HATA','OLUSTURULDU')
$ozet = New-Object System.Collections.Generic.List[object]
foreach($b in $hepsi){
  $sc = $b.request_counts
  Write-Host ("{0,-30} {1,-12} {2,8} {3,8} {4}" -f $b.id, $b.processing_status, $sc.succeeded, $sc.errored, $b.created_at)
  $ozet.Add([ordered]@{
    id="$($b.id)"; durum="$($b.processing_status)"
    basarili=[int]$sc.succeeded; hatali=[int]$sc.errored; iptal=[int]$sc.canceled
    olusturuldu="$($b.created_at)"; bitti="$($b.ended_at)"
    sonuc_adresi="$($b.results_url)"
    sonuc_suresi="$($b.expires_at)"
  })
}
$js = ConvertTo-Json -InputObject ([object[]]$ozet) -Depth 5
if([string]::IsNullOrWhiteSpace($js)){ $js = '[]' }
[IO.File]::WriteAllText((Join-Path $kok 'veri/parti-listesi.json'), $js, (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("-> veri/parti-listesi.json ({0} kayit)" -f $ozet.Count)
$hazir = @($ozet | Where-Object { $_.durum -eq 'ended' -and $_.basarili -gt 0 })
Write-Host ("HASADA HAZIR (ended + basarili>0): {0} parti, {1} sonuc" -f $hazir.Count, (($hazir | Measure-Object basarili -Sum).Sum))
try{Stop-Transcript|Out-Null}catch{}
