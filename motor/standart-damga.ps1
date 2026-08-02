# ============================================================================
#  STANDART DAMGASI — TMS/TFRS/BDS hash nobeti (03.08.2026, Gorev #60)
#
#  NEDEN: Kanunlarda madde-damga var (degisen madde -> dayanan soru isaretlenir)
#  ama STANDARTLARDA yoktu. KGK bir standardi guncellerse (or. TMS 8 tahmin
#  tanimi 2018'de degisti) ona dayanan sorular ESKI kalir ve kimse gormez.
#  Cem 03.08: "standartlarda hash nobeti yok" — kuruldu.
#
#  NE YAPAR: ambardaki (dokumanlar) TMS/TFRS/BDS/KKS/GDS/SBDS kayitlarinin
#  kaynak_ad+metin hash'ini cikarir, veri/standart-damga.json ile karsilastirir:
#   - YENI kayit -> damgalanir
#   - HASH DEGISTI -> "degisenler" listesine yazilir (soru isaretleme icin
#     dayanak-nobetcisi bu listeyi okuyabilir; simdilik RAPOR + kirmizi satir)
#   - SILINEN kayit -> raporlanir (standart ambardan dusmus = alarm)
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY (yoksa publishable ile dener -
#  dokumanlar anon-okunur).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc = New-Object Text.UTF8Encoding($false)
$damgaYol = Join-Path $kok 'veri/standart-damga.json'
$raporYol = Join-Path $kok 'veri/standart-damga-rapor.json'
function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), $enc) }
trap {
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$ANAHTAR = if($env:SUPABASE_SERVICE_KEY){ "$env:SUPABASE_SERVICE_KEY" } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$BASLIK = @{ apikey = $ANAHTAR; Authorization = "Bearer $ANAHTAR" }
$TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

$sha = [System.Security.Cryptography.SHA256]::Create()
function Ozet([string]$s){
  $b = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$s"))
  return ([BitConverter]::ToString($b) -replace '-','').Substring(0,16)
}

# --- ambardaki standart kayitlarini cek (kaynak_ad TMS/TFRS/BDS/KKS/GDS/SBDS ile baslar)
$kayitlar = @{}
foreach($onek in @('TMS','TFRS','BDS','KKS','GDS','SBDS')){
  $offset = 0
  while($true){
    $istekUri = "${TABAN}?select=kaynak_ad,metin&kaynak_ad=ilike." + [uri]::EscapeDataString("$onek *") + "&order=kaynak_ad&limit=1000&offset=$offset"
    $hw = Invoke-WebRequest -UseBasicParsing -Uri $istekUri -Headers $BASLIK -TimeoutSec 120
    $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
    $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
    if(-not $parti.Count){ break }
    foreach($k in $parti){ $kayitlar["$($k.kaynak_ad)"] = Ozet "$($k.metin)" }
    if($parti.Count -lt 1000){ break }
    $offset += 1000
  }
}
Write-Host ("Ambardaki standart kaydi: {0}" -f $kayitlar.Count)
if($kayitlar.Count -eq 0){
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='BOS'; not='ambarda standart kaydi bulunamadi - sorgu/anahtar kontrol' })
  exit 1
}

# --- eski damga ile karsilastir
$eski = @{}
if(Test-Path $damgaYol){
  try { (Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $eski[$_.Name] = "$($_.Value)" } } catch {}
}
$yeni = New-Object System.Collections.Generic.List[string]
$degisen = New-Object System.Collections.Generic.List[string]
$silinen = New-Object System.Collections.Generic.List[string]
foreach($ad in $kayitlar.Keys){
  if(-not $eski.ContainsKey($ad)){ $yeni.Add($ad) }
  elseif($eski[$ad] -ne $kayitlar[$ad]){ $degisen.Add($ad) }
}
foreach($ad in $eski.Keys){ if(-not $kayitlar.ContainsKey($ad)){ $silinen.Add($ad) } }

# --- damgayi guncelle + rapor
[IO.File]::WriteAllText($damgaYol, (ConvertTo-Json -InputObject $kayitlar -Depth 3), $enc)
$ilkKurulum = ($eski.Count -eq 0)
Rapor ([ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum   = $(if($degisen.Count -or $silinen.Count){ 'DEGISIKLIK VAR' } elseif($ilkKurulum){ 'ILK KURULUM' } else { 'DEGISIKLIK YOK' })
  toplam_kayit = $kayitlar.Count
  yeni    = $yeni.Count
  degisen = @($degisen)
  silinen = @($silinen)
  not     = 'degisen/silinen varsa: o standarda dayanan sorular GM okumasina girer (dayanak bagi).'
})
Write-Host ("STANDART DAMGA: toplam {0} | yeni {1} | DEGISEN {2} | SILINEN {3}" -f $kayitlar.Count, $yeni.Count, $degisen.Count, $silinen.Count)
if($degisen.Count -or $silinen.Count){ exit 1 }   # kirmizi satir: degisiklik goz ister
