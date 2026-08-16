# ============================================================================
#  KIMLIK DENETIMI (Katman 1 kapisi — her push'ta kosar, 0 USD, cagri YOK)
#
#  NEDEN VAR: Supabase, GIZLI anahtarli istegi PowerShell'in varsayilan
#  "Mozilla..." kimligiyle gorunce 401 ile reddediyor. Kimlik satiri olmayan
#  betik YERELDE calisir gibi gorunur (anahtar yoksa publishable anahtara
#  duser) ama CI'da - yani gercek isin yapildigi yerde - SESSIZCE OLUR.
#
#  16.08.2026'da olculdu: motor/madde-coz.ps1 (soru-dayanak cozucusu) tam da
#  bu yuzden HER kaynaga "ambarda-yok" diyordu; soru koruma zincirinin temeli
#  oluydu ve aylarca kimse gormedi. Ayni gun 49 betikte daha ayni eksik cikti.
#
#  KURAL: /rest/v1 cagiran her betik, Invoke-RestMethod VE Invoke-WebRequest
#  icin AYRI AYRI kimlik satiri tasir (biri otekini kapsamaz), ya da curl
#  kullaniyorsa -H "User-Agent: ..." verir.
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot

$klasorler = @('motor','arac')
$eksik = New-Object System.Collections.Generic.List[string]
$bakilan = 0
foreach($kl in $klasorler){
  $yol = Join-Path $kok $kl
  if(-not (Test-Path $yol)){ continue }
  foreach($d in (Get-ChildItem $yol -Filter *.ps1)){
    $icerik = [IO.File]::ReadAllText($d.FullName)
    if($icerik -notmatch '/rest/v1'){ continue }
    $bakilan++
    if($icerik -match 'UserAgent|User-Agent'){ continue }
    $eksik.Add(($kl + '/' + $d.Name))
  }
}

Write-Host ("Supabase cagiran betik: {0} | kimlik satiri eksik: {1}" -f $bakilan, $eksik.Count)
if($eksik.Count -gt 0){
  Write-Host ''
  Write-Host 'KIRMIZI - su betikler Supabase e KIMLIKSIZ gidiyor (CI da 401 alirlar):'
  foreach($e in $eksik){ Write-Host ("   " + $e) }
  Write-Host ''
  Write-Host 'Cozum: betigin basina (param blogundan sonra) iki satir:'
  Write-Host "   `$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'"
  Write-Host "   `$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'"
  exit 1
}
Write-Host 'Kimlik denetimi yesil - Supabase cagiran her betik kimlik tasiyor.'
