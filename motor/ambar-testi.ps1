# ============================================================================
#  AMBAR ALTIN TESTI — retrieval sigortasi (guven katmani C-1)
#  veri/ambar-altin-test.json'daki her soru icin madde_ara RPC'sini cagirir;
#  beklenen kaynak top-6'da yoksa vaka DUSER. Dusen vaka varsa exit 1 →
#  CI kirmizi + GitHub bildirimi. LLM YOK: bu kapi saf retrieval olcer.
#  Yerel: pwsh motor/ambar-testi.ps1   CI: mevzuat.yml hasat sonrasi adim.
# ============================================================================
$ErrorActionPreference = 'Stop'
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY = if ($env:SB_PUBLISHABLE) { $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }  # public anon key

$kok = Split-Path -Parent $PSScriptRoot
$setYol = Join-Path $kok 'veri/ambar-altin-test.json'
$set = Get-Content -Raw -Encoding UTF8 $setYol | ConvertFrom-Json

# edge/net-cevap.ts ile AYNI on-isleme: tr-lower + noktalama temizle + stop + fold
$STOP = @('var','varsa','yok','kac','ne','nasil','mi','mu','olur','odeme','sure','suresi','icin','ile','bir','bu','kesilir','geldi','aldim','nedir','kadar','gibi','daha','cok','hangi')  # 'vergi' cikarildi (17.07.2026) — edge ile AYNI kalmali
function Fold([string]$s) {
  $s = $s.ToLower([System.Globalization.CultureInfo]::GetCultureInfo('tr-TR'))
  ($s -replace 'ı','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ü','u' -replace 'ö','o' -replace 'ç','c' -replace 'â','a' -replace 'î','i' -replace 'û','u')
}
function Sorgula([string]$soru) {
  $tokler = (Fold $soru) -replace '[^\w\s]',' ' -split '\s+' | Where-Object { $_.Length -ge 3 -and $STOP -notcontains $_ } | Select-Object -First 8
  # KURUM TAKMA ADI (edge ile AYNI): 'sgk' -> kanunun kendi dili
  $tokler = @($tokler | ForEach-Object { if ($_ -eq 'sgk') { 'sigortali','sosyal','prim' } else { $_ } }) | Select-Object -First 8
  if (-not $tokler) { return @() }
  $govde = @{ sorgu = ($tokler -join ' '); adet = 6 } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers @{ apikey = $KEY; Authorization = "Bearer $KEY" } -ContentType 'application/json' -Body $govde
  return @($r)
}

$dusen = 0; $gecen = 0
foreach ($v in $set.vakalar) {
  $sonuc = @()
  try { $sonuc = Sorgula $v.soru } catch { Write-Host "HATA (RPC): $($v.soru) -> $_"; $dusen++; continue }
  $adlar = $sonuc | ForEach-Object { Fold ([string]$_.kaynak_ad) }
  $tutan = $false
  foreach ($b in @($v.beklenen)) { if ($adlar | Where-Object { $_ -like "*$b*" }) { $tutan = $true; break } }
  if ($tutan) { $gecen++ }
  else {
    $dusen++
    Write-Host "DUSTU: '$($v.soru)'  beklenen: $($v.beklenen -join ' | ')"
    Write-Host "   top-6: $((($sonuc | ForEach-Object { $_.kaynak_ad }) | Select-Object -First 6) -join ' § ')"
  }
}
Write-Host "----------------------------------------------"
Write-Host "ALTIN TEST: $gecen gecti, $dusen dustu / $($set.vakalar.Count) vaka"
if ($dusen -gt 0) { exit 1 }
