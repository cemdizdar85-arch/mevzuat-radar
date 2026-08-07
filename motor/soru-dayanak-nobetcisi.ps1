# ============================================================================
#  SORU-DAYANAK NOBETCISI — 07.08.2026 (Cem'e soz: "mevzuat degisince sorular
#  nasil kontrol altinda tutulacak" sorusunun EKSIK HALKASI)
#
#  Zincir: ayna kanunu yeniden yutar -> _madde-damga.json'daki madde parmak
#  izleri degisir -> BU NOBETCI onceki tabanla karsilastirir -> damgasi
#  DEGISEN maddeye dayanan kasa sorulari (kanun_no + madde_no eslesmesi)
#  'mevzuat-degisti' notuyla yayindan cekilir -> hakem + GM yeniden yargilar.
#  Sayfalar icin ayni zincir 29.07'den beri vardi (dayanak-nobetci);
#  SORULAR icin bugune kadar yoktu - SGK 7,5->9 dersinin kalici ilaci.
#
#  Taban: veri/mevzuat/_madde-damga-onceki.json (ilk kosuda tohumlanir,
#  isaret atilmaz). PATCH kanali curl + fren (07.08 modem dersi).
#  Not EKLEME usulu - dolu kusur notu EZILMEZ (dil-kusuru dersi).
# ============================================================================
param([switch]$tohum)   # -tohum: yalniz taban kopyalanir, isaret atilmaz
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$guncelYol = Join-Path $kok 'veri\mevzuat\_madde-damga.json'
$oncekiYol = Join-Path $kok 'veri\mevzuat\_madde-damga-onceki.json'
$raporYol  = Join-Path $kok 'veri\soru-dayanak-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not (Test-Path $guncelYol)){ Write-Host 'madde-damga dosyasi yok - cikildi'; exit 0 }
$curlAd = if($env:OS -match 'Windows'){ 'curl.exe' } else { 'curl' }

$guncel = (Get-Content $guncelYol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler
if($tohum -or -not (Test-Path $oncekiYol)){
  Copy-Item $guncelYol $oncekiYol -Force
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TOHUM'; not='taban kopyalandi; isaret atilmadi. Sonraki kosular gercek degisimi yakalar.' })
  Write-Host 'TOHUM: taban kuruldu.'; exit 0
}
$onceki = (Get-Content $oncekiYol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler

# --- degisenler (damga farkli) + silinenler
$degisen = New-Object System.Collections.Generic.List[string]
$silinen = New-Object System.Collections.Generic.List[string]
foreach($p in $onceki.PSObject.Properties){
  $g = $guncel.PSObject.Properties[$p.Name]
  if($null -eq $g){ $silinen.Add($p.Name); continue }
  if("$($g.Value.damga)" -ne "$($p.Value.damga)"){ $degisen.Add($p.Name) }
}
Write-Host ("degisen madde: {0} | silinen: {1}" -f $degisen.Count, $silinen.Count)

$isaretli=0; $etkilenen = New-Object System.Collections.Generic.List[object]
if($degisen.Count){
  $SRV = $env:SUPABASE_SERVICE_KEY
  foreach($anahtar in ($degisen + $silinen)){
    $par = $anahtar -split '\|'
    if($par.Count -lt 2){ continue }
    $kanun = $par[0]; $madde = $par[1]
    # o maddeye dayanan sorular
    $r = & $curlAd -s -H "apikey: $SRV" -H "User-Agent: mevzuat-radar-robot/1.0" ("$U`?select=id,yayin_notu&kanun_no=eq." + [uri]::EscapeDataString($kanun) + "&madde_no=eq." + [uri]::EscapeDataString($madde) + "&limit=500")
    $sorular = @()
    try { $sorular = @(($r | ConvertFrom-Json)) } catch {}
    if(-not $sorular.Count){ continue }
    $etkilenen.Add([pscustomobject]@{ madde=$anahtar; soru=$sorular.Count; tur=$(if($silinen -contains $anahtar){'SILINDI'}else{'degisti'}) })
    foreach($s in $sorular){
      if("$($s.yayin_notu)" -match 'mevzuat-degisti'){ continue }
      $yeniNot = if("$($s.yayin_notu)".Trim()){ "$($s.yayin_notu)" + ' | mevzuat-degisti: ' + $anahtar } else { ('mevzuat-degisti ' + (Get-Date -Format 'dd.MM.yyyy') + ': ' + $anahtar + ' damgasi degisti - hakem+GM yeniden yargilamali') }
      $gov = ConvertTo-Json -Compress -InputObject @{ yayin=$false; yayin_notu=$yeniNot }
      $tmp=[IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($tmp,$gov,(New-Object Text.UTF8Encoding($false)))
      $kod = & $curlAd -s -o ($(if($env:OS -match 'Windows'){'NUL'}else{'/dev/null'})) -w "%{http_code}" -X PATCH -H "apikey: $SRV" -H "Content-Type: application/json" -H "Prefer: return=minimal" -H "User-Agent: mevzuat-radar-robot/1.0" --data-binary "@$tmp" ("$U`?id=eq." + $s.id)
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
      if("$kod" -eq '204'){ $isaretli++ }
      Start-Sleep -Milliseconds 300
    }
  }
}

Copy-Item $guncelYol $oncekiYol -Force   # taban ilerletilir
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  degisenMadde=$degisen.Count; silinenMadde=$silinen.Count; isaretlenenSoru=$isaretli
  etkilenen=@($etkilenen | Select-Object -First 100)
  not='Isaretlenen sorular yayin=false + mevzuat-degisti notu tasir; hakem+GM yargisi sonrasi geri acilir.'
})
Write-Host ("TAMAM: {0} soru mevzuat-degisti notuyla cekildi." -f $isaretli)
