# ============================================================================
#  SORU ISTATISTIGI — K1 ZORLUK YUZDESI (02.08.2026)
#  Cem onayi: "bir, iki ve ucu yapalim" (SINAV-KURALLARI.md K bolumu)
#
#  NE YAPAR: cevap_kaydi tablosundaki gercek cevaplari soru bazinda sayar ve
#  "bu soruyu cozenlerin yuzde kaci dogru bildi" degerini cikarir. Cikti
#  veri/soru-istatistik.json; deneme.html soru altinda gosterir.
#
#  ESIK KURALI (K4): 20 cevaptan AZ olan soru dosyaya YAZILMAZ. "3 kisiden
#  1'i bildi" gibi bir rakam guveni artiracakken azaltir; rakam disiplini
#  geregi uydurma/anlamsiz sayi basilmaz.
#
#  PARA HARCAMAZ (yalniz Supabase okumasi). ENV: SUPABASE_SERVICE_KEY
# ============================================================================
param([int]$esik = 20)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/cevap_kaydi"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$ciktiYol = Join-Path $kok 'veri/soru-istatistik.json'

# --- cevaplari cek (sayfalı)
$kayit = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=soru_id,dogru,sure_ms&order=soru_id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($x in $l){ $kayit.Add($x) }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("cevap_kaydi: {0} kayit" -f $kayit.Count)

# --- soru bazinda topla
$top = @{}
foreach($k in $kayit){
  $sid = "$($k.soru_id)"
  if([string]::IsNullOrWhiteSpace($sid)){ continue }
  if(-not $top.ContainsKey($sid)){ $top[$sid] = [ordered]@{ n=0; d=0; sureTop=0; sureN=0 } }
  $top[$sid].n++
  if($k.dogru -eq $true){ $top[$sid].d++ }
  if($k.sure_ms -and [int]$k.sure_ms -gt 0){ $top[$sid].sureTop += [int]$k.sure_ms; $top[$sid].sureN++ }
}

# --- esigi gecenler
$cikti = @{}
$gecen = 0; $esikAlti = 0
foreach($sid in $top.Keys){
  $t = $top[$sid]
  if($t.n -lt $esik){ $esikAlti++; continue }
  $gecen++
  $cikti[$sid] = [ordered]@{
    n = $t.n
    dogruYuzde = [math]::Round(100 * $t.d / $t.n)
    ortSaniye  = $(if($t.sureN){ [math]::Round(($t.sureTop / $t.sureN) / 1000) } else { $null })
  }
}
Write-Host ("Esigi ({0} cevap) gecen soru: {1} | esik alti: {2}" -f $esik, $gecen, $esikAlti)

$paket = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  esik = $esik
  aciklama = "Soru bazinda gercek cevap istatistigi. Yalniz $esik ve uzeri cevap alan sorular yer alir (SINAV-KURALLARI K4). dogruYuzde = dogru bilenlerin yuzdesi; ortSaniye = ortalama cozum suresi."
  soru_sayisi = $gecen
  esik_alti = $esikAlti
  sorular = $cikti
}
$j = ConvertTo-Json -InputObject $paket -Depth 5
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $ciktiYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("-> {0}" -f $ciktiYol)
