# ============================================================================
#  TASLAK LISTECISI — 07.08.2026 (0 USD)
#
#  NEDEN: Yerel makinenin modemi Supabase storage LISTELEME'yi (POST) kesiyor
#  (07.08 ag dersi); tekil GET'ler geciyor. Bu script RUNNER'da kosar, ozel
#  'onarim-taslak' kovasindaki dosya YOLLARINI cikarir ve repoya yazar.
#  Icerik TASINMAZ — yalniz yol+uuid listesi (paralı soru icerigi public
#  repoya girmez kurali korunur). Yerel makine bu listeyle taslaklari
#  tek tek GET ile indirir (GM okuma tezgahi).
# ============================================================================
$ErrorActionPreference = 'Stop'
$STOR = 'https://bjrleanjpyujtajmazxn.supabase.co/storage/v1'
$KOVA = 'onarim-taslak'
$SK = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)"; 'Content-Type'='application/json' }

function Listele([string]$onek){
  $tum = @()
  $offset = 0
  while($true){
    $govde = '{"prefix":"' + $onek + '","limit":1000,"offset":' + $offset + '}'
    $parca = @(Invoke-RestMethod -Uri "$STOR/object/list/$KOVA" -Method Post -Headers $SK -Body $govde -TimeoutSec 90 | ForEach-Object { $_ })
    $tum += $parca
    if($parca.Count -lt 1000){ break }
    $offset += 1000
  }
  return $tum
}

$kokler = @(Listele 'ic-tutarlilik-onar')
$yollar = @()
foreach($kk in $kokler){
  if($null -ne $kk.id){ $yollar += ('ic-tutarlilik-onar/' + $kk.name); continue }   # kok seviyesinde dosya
  $altlar = @(Listele ('ic-tutarlilik-onar/' + $kk.name))
  foreach($d in $altlar){
    if($null -ne $d.id){ $yollar += ('ic-tutarlilik-onar/' + $kk.name + '/' + $d.name) }
  }
}
$yollar = @($yollar | Sort-Object -Unique)
Write-Host ("kova taslak dosyasi: {0}" -f $yollar.Count)

$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kova = $KOVA
  adet = $yollar.Count
  yollar = $yollar
}
New-Item -ItemType Directory -Force veri | Out-Null
[IO.File]::WriteAllText('veri/onarim-taslak-listesi.json', (ConvertTo-Json -InputObject $rapor -Depth 3), (New-Object Text.UTF8Encoding($false)))
Write-Host 'liste yazildi: veri/onarim-taslak-listesi.json'
