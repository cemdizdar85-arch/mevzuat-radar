# ============================================================================
#  ONBELLEK (PROMPT CACHE) OLCUMU   (10.08.2026, 0 USD - yalniz OKUR)
#
#  CEM 10.08: konsolda "prompt cache hit rate %99 dustu" uyarisi cikti.
#  Onbellekten okunan jeton normal girdinin ONDA BIRINE mal olur; onbellege
#  YAZMAK ise 1,25 KATINA. Yani onbellek bozuksa ayni is kat kat pahaliya gelir.
#
#  BU BETIK TAHMIN ETMEZ: bitmis partilerin sonuclarindaki usage alanlarini
#  tek tek toplar. Dort ayri jeton turu vardir ve BIRBIRINE KARISTIRILMAZ:
#     input_tokens                 -> tam fiyat
#     cache_read_input_tokens      -> %10 fiyat   (ISTEDIGIMIZ BU)
#     cache_creation_input_tokens  -> %125 fiyat  (ilk yazim, kacinilmaz)
#     output_tokens                -> cikti fiyati
#
#  NOT: Batch sonuclarini indirmek PARA HARCAMAZ ve parti YENIDEN
#  GONDERILMEZ. Sonuclar 29 gun saklanir.
#
#  Cikti: veri/onbellek-olcumu.json
# ============================================================================
param(
  [string[]]$partiler = @('msgbatch_012CCJE9RKSHX1oLzFtscPHn','msgbatch_01GxNRQtWaJ1PRCS3mx7D1PQ','msgbatch_015vZykJQxTQrb8Y1CHF8sRa'),
  [double]$girdiFiyat = 5.0,     # USD / 1M jeton (Opus 5)
  [double]$ciktiFiyat = 25.0
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path $PSScriptRoot -Parent
# 12.08: cift hat - hedef api-hedef.ps1'den (anthropic | aws)
. (Join-Path $PSScriptRoot 'api-hedef.ps1')
$HEDEF = Get-ApiHedef
$AK = $HEDEF.anahtar
$HDR = $HEDEF.basliklar
$API_TABAN = $HEDEF.taban
Write-Host ("API hedefi: {0}" -f $HEDEF.ad)

$T_girdi = 0.0; $T_oku = 0.0; $T_yaz = 0.0; $T_cikti = 0.0; $T_istek = 0
$T_okuyan = 0; $T_yazan = 0
$partiRapor = New-Object System.Collections.Generic.List[object]

foreach($partiKimlik in $partiler){
  Write-Host ''
  Write-Host ("--- {0}" -f $partiKimlik)
  $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$partiKimlik" -Headers $HDR -TimeoutSec 120
  if("$($st.processing_status)" -ne 'ended'){ Write-Host '  bitmemis - atlandi'; continue }
  $adres = if($st.results_url){ "$($st.results_url)" } else { "$API_TABAN/v1/messages/batches/$partiKimlik/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 900
  # PS7 BYTE DIZISI dondurebilir; string sanip bolunce her bayt ayri satir olur
  $metin = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }

  $g=0.0; $o=0.0; $y=0.0; $c=0.0; $n=0; $okuyan=0; $yazan=0
  foreach($sat in ($metin -split "`r?`n")){
    if("$sat".Trim().Length -eq 0){ continue }
    try{ $r = $sat | ConvertFrom-Json }catch{ continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $u = $r.result.message.usage
    $ci = 0; $cr = 0
    if($u.PSObject.Properties['cache_creation_input_tokens']){ $ci = [int]$u.cache_creation_input_tokens }
    if($u.PSObject.Properties['cache_read_input_tokens']){     $cr = [int]$u.cache_read_input_tokens }
    $g += [int]$u.input_tokens; $c += [int]$u.output_tokens
    $y += $ci; $o += $cr
    if($cr -gt 0){ $okuyan++ }
    if($ci -gt 0){ $yazan++ }
    $n++
  }
  Write-Host ("  istek {0} | girdi {1:N0} | ONBELLEK OKUMA {2:N0} | onbellek yazma {3:N0} | cikti {4:N0}" -f $n,$g,$o,$y,$c)
  $oran = 0.0
  if(($g+$o+$y) -gt 0){ $oran = [math]::Round(100.0*$o/($g+$o+$y),1) }
  Write-Host ("  onbellekten gelen girdi payi : %{0}" -f $oran)
  Write-Host ("  onbellekten OKUYAN istek     : {0}/{1}" -f $okuyan,$n)
  Write-Host ("  onbellege YAZAN istek        : {0}/{1}" -f $yazan,$n)
  $partiRapor.Add([pscustomobject]@{ parti=$partiKimlik; istek=$n; girdi=$g; onbellekOkuma=$o; onbellekYazma=$y; cikti=$c; okuyanIstek=$okuyan; yazanIstek=$yazan })
  $T_girdi+=$g; $T_oku+=$o; $T_yaz+=$y; $T_cikti+=$c; $T_istek+=$n; $T_okuyan+=$okuyan; $T_yazan+=$yazan
}

# --- PARA -------------------------------------------------------------------
# Batch %50 indirimli. Onbellek okuma girdinin %10'u, yazma %125'i.
$B = 0.5
$mGirdi = $T_girdi/1e6*$girdiFiyat*$B
$mOku   = $T_oku  /1e6*$girdiFiyat*0.10*$B
$mYaz   = $T_yaz  /1e6*$girdiFiyat*1.25*$B
$mCikti = $T_cikti/1e6*$ciktiFiyat*$B
$toplam = $mGirdi+$mOku+$mYaz+$mCikti

# Onbellek HIC olmasaydi: okunan+yazilan jetonlarin hepsi tam fiyat girdi olurdu
$onbelleksiz = ($T_girdi+$T_oku+$T_yaz)/1e6*$girdiFiyat*$B + $mCikti
$kazanc = $onbelleksiz - $toplam

Write-Host ''
Write-Host '================ ONBELLEK OLCUMU ================'
Write-Host ("Istek            : {0:N0}" -f $T_istek)
Write-Host ("Girdi (tam fiyat): {0,15:N0} jeton" -f $T_girdi)
Write-Host ("ONBELLEK OKUMA   : {0,15:N0} jeton   (%10 fiyat)" -f $T_oku)
Write-Host ("Onbellek yazma   : {0,15:N0} jeton   (%125 fiyat)" -f $T_yaz)
Write-Host ("Cikti            : {0,15:N0} jeton" -f $T_cikti)
$toplamGirdi = $T_girdi+$T_oku+$T_yaz
$pay = 0.0; if($toplamGirdi -gt 0){ $pay = [math]::Round(100.0*$T_oku/$toplamGirdi,1) }
Write-Host ''
Write-Host ("ONBELLEK ISABET ORANI : %{0}   <- girdinin yuzde kaci onbellekten geldi" -f $pay)
Write-Host ("  onbellekten okuyan istek : {0}/{1}  (%{2})" -f $T_okuyan,$T_istek,[math]::Round(100.0*$T_okuyan/[math]::Max(1,$T_istek),1))
Write-Host ("  onbellege yazan istek    : {0}/{1}  (%{2})  <- her yazma 1,25 kat" -f $T_yazan,$T_istek,[math]::Round(100.0*$T_yazan/[math]::Max(1,$T_istek),1))
Write-Host ''
Write-Host 'PARA (Batch fiyatiyla):'
Write-Host ("  girdi           : {0,8:N2} USD" -f $mGirdi)
Write-Host ("  onbellek okuma  : {0,8:N2} USD" -f $mOku)
Write-Host ("  onbellek yazma  : {0,8:N2} USD" -f $mYaz)
Write-Host ("  cikti           : {0,8:N2} USD" -f $mCikti)
Write-Host ("  TOPLAM          : {0,8:N2} USD" -f $toplam)
Write-Host ''
Write-Host ("Onbellek HIC olmasaydi : {0:N2} USD" -f $onbelleksiz)
Write-Host ("Onbellegin KAZANDIRDIGI: {0:N2} USD  (%{1})" -f $kazanc,[math]::Round(100.0*$kazanc/[math]::Max(0.01,$onbelleksiz),1))

[IO.File]::WriteAllText((Join-Path $kok 'veri\onbellek-olcumu.json'), ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); istek=$T_istek
  girdiJeton=$T_girdi; onbellekOkuma=$T_oku; onbellekYazma=$T_yaz; ciktiJeton=$T_cikti
  isabetOrani=$pay; okuyanIstek=$T_okuyan; yazanIstek=$T_yazan
  maliyetUSD=[math]::Round($toplam,2); onbelleksizUSD=[math]::Round($onbelleksiz,2); kazancUSD=[math]::Round($kazanc,2)
  partiler=$partiRapor
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host '-> veri/onbellek-olcumu.json'
