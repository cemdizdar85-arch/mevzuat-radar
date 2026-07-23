# ============================================================================
#  MEVZUAT YUKLEYICI  —  veri/mevzuat/*.json (kanun madde-belgeleri) -> Supabase
#  'dokumanlar' tablosu. Beyin (net-cevap) FTS ile MADDENIN KENDISINDEN alintiyla
#  cevaplar. Kaynak: mevzuat.gov.tr konsolide metin (pdftotext, madde madde).
#  tur='kanun-madde' -> kuratorlu 14 ambar belgesine (ambar-yukle) DOKUNMAZ.
#  Idempotent: once tur=kanun-madde siler, sonra toplu ekler (batch=500).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu). Yoksa zarifce atlar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - mevzuat yukleyici atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

$dir = Join-Path $kok "veri/mevzuat"
if(-not (Test-Path $dir)){ Write-Host "veri/mevzuat yok."; exit 0 }

# --- topla + dedup (kaynak_ad) ---
$hepsi = New-Object System.Collections.Generic.List[object]
$gorulen = @{}
Get-ChildItem $dir -Filter *.json | ForEach-Object {
  $d = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($b in @($d.belgeler)){
    if(-not $b.kaynak_ad -or -not $b.metin){ continue }
    $k = "$($b.kaynak_ad)"
    if($gorulen.ContainsKey($k)){ continue }
    $gorulen[$k] = $true
    $hepsi.Add([ordered]@{
      tur          = $(if($b.tur){ "$($b.tur)" } else { "kanun-madde" })   # standart-madde (TMS/BDS) belgeleri kendi turunu tasir
      kaynak_ad    = $k
      baslik       = "$($b.baslik)"
      metin        = "$($b.metin)"
      kaynak_url   = "$($b.kaynak_url)"
      belge_tarihi = $null
    })
  }
}
Write-Host ("Yuklenecek: {0} madde-belgesi" -f $hepsi.Count)
if($hepsi.Count -eq 0){ exit 0 }

# --- once eski kanun-madde kayitlarini sil (idempotent) ---
try {
  Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=in.(kanun-madde,standart-madde)" -Headers ($H + @{ Prefer = "return=minimal" }) -TimeoutSec 120 | Out-Null
  Write-Host "Eski kanun-madde + standart-madde kayitlari silindi."
} catch { Write-Host "UYARI: silme ($_)" }

# --- toplu ekle (batch=500) ---
$batch = 500; $eklenen = 0
for($i=0; $i -lt $hepsi.Count; $i += $batch){
  $son = [Math]::Min($i+$batch, $hepsi.Count) - 1
  $dilim = $hepsi[$i..$son]
  $json = ($dilim | ConvertTo-Json -Depth 5)
  if($dilim.Count -eq 1){ $json = "[$json]" }   # tek elemanda PS array'i acar
  $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 180 | Out-Null
    $eklenen += $dilim.Count
    Write-Host ("  batch {0}-{1} eklendi ({2}/{3})" -f $i, $son, $eklenen, $hepsi.Count)
  } catch {
    Write-Host ("HATA batch {0}: {1}" -f $i, $_)
  }
}
Write-Host ("MEVZUAT YUKLENDI - toplam {0} madde-belgesi (tur=kanun-madde)" -f $eklenen)
exit 0
