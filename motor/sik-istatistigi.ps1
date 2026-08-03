# ============================================================================
#  SIK ISTATISTIGI (03.08.2026) — 0 USD, API YOK
#
#  CEM ONAYI: "adaylarin %38'i C'yi secti" - UWorld'un imza ozelligi. Ogrenci
#  yanlis yapinca "ben mi bilemedim" demiyor, "bu tuzaga her dort kisiden biri
#  dusuyor" diye goruyor. Ayni veri BIZE de yazdigimiz tuzagin gercekten
#  calisip calismadigini soyluyor.
#
#  VERI ZATEN VARDI: cevap_kaydi tablosu 02.08'den beri secilen sikki
#  kaydediyor. Eksik olan GOSTERIMDI. Bu robot gunluk toplayip
#  veri/sik-istatistigi.json yazar; deneme.html oradan okur.
#
#  MAHREMIYET: yalniz SAYIM yazilir - kim, ne zaman, hangi oturum YAZILMAZ.
#  cevap_kaydi'ni tarayiciya acmiyoruz; ozet dosyada kimlik yok.
#
#  RAKAM DISIPLINI: 20 cevaptan az olan soru dosyaya GIRMEZ. Uc kisilik
#  ornekten "%33" demek, rakam vermemekten kotudur.
#
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/sik-istatistigi.json
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiYol = Join-Path $kok 'veri/sik-istatistigi.json'
$raporYol = Join-Path $kok 'veri/sik-istatistigi-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g }))
  Write-Host ("HATA: {0}" -f $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/cevap_kaydi"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

$sayac = @{}
$satir = 0
for($o=0; $o -lt 500000; $o+=1000){
  $r = CekListe "$U`?select=soru_id,secilen&order=soru_id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){
    if($null -eq $x){ continue }
    $satir++
    $sid = "$($x.soru_id)"; $sec = "$($x.secilen)".Trim().ToUpper()
    if($sid -eq '' -or $sec -notmatch '^[A-E]$'){ continue }
    if(-not $sayac.ContainsKey($sid)){ $sayac[$sid] = @{ A=0;B=0;C=0;D=0;E=0;toplam=0 } }
    $sayac[$sid][$sec]++; $sayac[$sid]['toplam']++
  }
  if($r.Count -lt 1000){ break }
}
Write-Host ("cevap_kaydi satiri: {0} | soru: {1}" -f $satir, $sayac.Count)

# 20 cevaptan az olan soru DISARIDA kalir (rakam disiplini)
$ESIK = 20
$cikti = [ordered]@{}
$giren = 0
foreach($sid in ($sayac.Keys | Sort-Object)){
  if($sayac[$sid]['toplam'] -lt $ESIK){ continue }
  $cikti[$sid] = [ordered]@{ A=$sayac[$sid]['A']; B=$sayac[$sid]['B']; C=$sayac[$sid]['C']
                             D=$sayac[$sid]['D']; E=$sayac[$sid]['E']; toplam=$sayac[$sid]['toplam'] }
  $giren++
}
$paket = [ordered]@{
  guncelleme=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  esik=$ESIK
  not='Yalniz sayim. Kimlik/oturum/zaman YAZILMAZ. Esigin altindaki soru dosyaya girmez.'
  sorular=$cikti
}
Set-Content -LiteralPath $ciktiYol -Value (ConvertTo-Json -InputObject $paket -Depth 4) -Encoding UTF8 -NoNewline
Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  cevap_satiri=$satir; kayitli_soru=$sayac.Count; esigi_gecen=$giren; esik=$ESIK
  not='Esigi gecen soru yoksa bu normaldir - henuz yeterli cevap birikmemistir.' }))
Write-Host ("Esigi gecen ({0}+ cevap): {1} soru -> {2}" -f $ESIK, $giren, $ciktiYol)
