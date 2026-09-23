#requires -Version 5.1
<#
================================================================================
  BEDEL ARA KAYDI KAPATICI — çöken koşunun harcamasını deftere çevirir   23.09.2026 · bedel 0

  NİYE VAR: 23.09 04:04–04:12 UTC GitHub makineleri çöktü; w9/w10 koşuları deftere HİÇ satır yazamadı
  (satır koşu sonunda yazılıyordu). Bütçe kapısı bu planları 0 USD saydı ve yeniden başlatmaya yeniden
  15 USD izin verdi. Artık her koşu birikmiş tutarını ara kayıt olarak ambara yazıyor
  (motor/api-hedef.ps1 Save-BedelAra, kalip_parti "__bedel-ara/<koşu>/<etiket>"). Koşu normal biterse
  ara kayıt "kapandı" olur. KAPANMAMIŞ ve yeterince ESKİ ara kayıt = çöken koşu → bu betik onu
  bedel_kaydi'na kesin satır olarak yazar ve kaydı kapatır.

  "Yeterince eski": GitHub iş tavanı 350 dk. Son güncellemesi -EsikDk'dan (varsayılan 400) eski olan
  açık kayıt artık hiçbir koşuya ait olamaz.

  ÇAĞRILAN YER: bulut-uretim.yml "Durumu ambardan indir" (bedel-senkron -Indir'den ÖNCE) — böylece
  bütçe kapısı çöken koşunun harcamasını görür. Elle: powershell -File arac/bedel-ara-kapat.ps1 -Yaz

  ⚠ ÇİFT SAYIM RİSKİ (bilinen, dar): koşu kesin satırını yazıp tam o an "kapandı" işaretini yazamadan
    düşerse ara kayıt açık kalır ve bu betik ikinci satır yazar (fazla sayım). Bu, iki ardışık ağ
    çağrısının ikincisinin düşmesini ister; fazla sayım bütçe açısından temkinli yöndür.
  🚫 GÖRMEZ: koşunun sonucunu hiç ALMADIĞI ama Anthropic'in faturaladığı partiler. Console tek doğrulayıcıdır.
  Öz-sınav: arac/bedel-ara-sinavi.ps1
================================================================================
#>
param([switch]$Yaz, [int]$EsikDk = 400)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $kok 'motor\api-hedef.ps1')   # Save-BedelKesin, Get-SbAnahtar

# Karar: bu ara kayıt kesin satıra çevrilmeli mi?  (öz-sınav bu fonksiyonu AST ile koşar)
function BedelAraKapatilmali($icerik, [datetime]$simdi, [int]$esikDk) {
  if (-not $icerik) { return $false }
  if ([bool]$icerik.kapandi) { return $false }
  if ([double]$icerik.toplamUsd -le 0) { return $false }
  $z = [datetime]::MinValue
  if (-not [datetime]::TryParse("$($icerik.zaman)", [ref]$z)) { return $false }   # zamanı okunamayan kayda dokunulmaz
  return (($simdi - $z).TotalMinutes -ge $esikDk)
}

$anah = Get-SbAnahtar; if (-not $anah) { throw 'SUPABASE_SERVICE_KEY yok' }
$H = @{ apikey = $anah; Authorization = "Bearer $anah"; 'User-Agent' = 'mevzuat-radar-robot/1.0'; Accept = 'application/json' }
$u = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$satir = New-Object System.Collections.Generic.List[object]
for ($ofs = 0; ; $ofs += 1000) {
  # ⚠ PS 5.1 (ölçüldü 23.09): boş JSON dizisi @(...) içinde TEK boş nesne olarak gelir → "1 açık kayıt" hayaleti.
  #   Yalnız etiketi dolu satırlar sayılır.
  $r = @(Invoke-RestMethod -Uri "$u`?select=etiket,icerik&etiket=like.__bedel-ara/*&order=etiket.asc&limit=1000&offset=$ofs" -Headers $H -TimeoutSec 120 | ForEach-Object { $_ } | Where-Object { $_ -and "$($_.etiket)" })
  foreach ($x in $r) { $satir.Add($x) }
  if ($r.Count -lt 1000) { break }
}
$simdi = Get-Date
$acik = 0; $kapat = 0; $yazilan = 0; $tutar = 0.0
foreach ($x in $satir) {
  $ic = $x.icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }
  if (-not [bool]$ic.kapandi) { $acik++ }
  if (-not (BedelAraKapatilmali $ic $simdi $EsikDk)) { continue }
  $kapat++; $tutar += [double]$ic.toplamUsd
  Write-Host ("  ÇÖKEN KOŞU: {0} · {1} · {2:N2} USD · son güncelleme {3}" -f $ic.kosu, $ic.etiket, [double]$ic.toplamUsd, $ic.zaman) -ForegroundColor Yellow
  if (-not $Yaz) { continue }
  if (Save-BedelKesin "$($ic.zaman)" "$($ic.etiket)" '' ([double]$ic.toplamUsd) ([bool]$ic.varsayim) $ic.satirlar 'bedel-ara-kapat (coken kosu)') {
    $ic.kapandi = $true
    $gov = [ordered]@{ etiket = "$($x.etiket)"; sinav = 'SISTEM'; yazan = 'bedel-ara-kapat'; icerik = $ic }
    $bayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $gov -Depth 8 -Compress))
    [void](Invoke-RestMethod -Method Post -Uri "$u`?on_conflict=etiket" -Headers ($H + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 60)
    $yazilan++
  }
}
"BEDEL ARA: kayıt {0} · açık {1} · çöken koşu {2} ({3:N2} USD) · deftere yazılan {4}{5}" -f $satir.Count, $acik, $kapat, $tutar, $yazilan, $(if (-not $Yaz) { ' (KURU — yazmak için -Yaz)' } else { '' })
