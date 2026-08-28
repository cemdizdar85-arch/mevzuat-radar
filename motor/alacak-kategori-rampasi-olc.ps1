# OLCUM 3: 'iflas-ve-tasfiye' alt kategorisi HANGI AY basliyor?
# Derin bolgeyi tarayip iflas-hukuku ilanlarini AY x ALT-KATEGORI olarak sayar.
# Kasadaki 06.04.2026 sinirini KAYNAKTAN dogrular (ya da curutur).
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$H = @{ 'Accept'='application/json'; 'User-Agent'='Mozilla/5.0 (MevzuatRadar-AlacakRobotu)' }

function Sayfa([int]$skip){
  $govde = @{ adFilterAttributes = @(); maxResultCount = 20; skipCount = $skip } | ConvertTo-Json -Depth 5
  Invoke-RestMethod -Method Post -Uri 'https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter' `
    -Headers $H -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 90
}

$ay = @{}   # 'YYYY-MM' -> @{tasfiye=n; konkordato=n}
$toplam = 0
for($s=0; $s -le 26000; $s+=20){
  try { $r = Sayfa $s } catch { Start-Sleep -Seconds 2; continue }
  $ads = @($r.result.ads); if(-not $ads.Count){ break }
  foreach($a in $ads){
    $sl = "$($a.slugifyTitle)"
    if($sl -notmatch '^iflas-hukuku'){ continue }
    $k = if($sl -match 'iflas-ve-tasfiye'){ 'tasfiye' } elseif($sl -match 'konkordato-ve-muhlet'){ 'konkordato' } else { 'diger' }
    $d = $null; if($a.publishStartDate){ try{ $d=[datetime]$a.publishStartDate }catch{} }
    if(-not $d){ continue }
    $anahtar = $d.ToString('yyyy-MM')
    if(-not $ay.ContainsKey($anahtar)){ $ay[$anahtar] = @{tasfiye=0; konkordato=0; diger=0} }
    $ay[$anahtar][$k]++
    $toplam++
  }
  if($s % 4000 -eq 0){ Write-Host ("  ... skip={0} · toplanan={1}" -f $s, $toplam) }
  Start-Sleep -Milliseconds 180
}

Write-Host ""
Write-Host ("TOPLAM iflas-hukuku ilani: {0}" -f $toplam)
Write-Host ""
Write-Host "ay      | tasfiye | konkordato | diger"
Write-Host ("-" * 45)
$ay.Keys | Sort-Object | ForEach-Object {
  Write-Host ("{0} | {1,7} | {2,10} | {3,5}" -f $_, $ay[$_].tasfiye, $ay[$_].konkordato, $ay[$_].diger)
}
