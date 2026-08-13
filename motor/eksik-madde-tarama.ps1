# ============================================================================
#  EKSIK MADDE TARAMASI - 14.08 kusurunun ambardaki izini olcer.
#  Kusur: parcalayici, maddenin ilk 70 karakterinde "(Mülga" gorunce maddeyi
#  komple atiyordu. Ama "(Mülga ibare:...)" / "(Mülga fıkra:...)" MADDENIN
#  KENDISI degil, icindeki bir parca mulga demektir - madde yururlukte.
#  Yerli Mali Tebligi m.4 ve m.8 bu yuzden ambara hic girmemisti.
#
#  Bu betik her ambar dosyasinda madde numarasi SURESIZLIGINI arar: 1,2,3,5 ise
#  4 eksiktir. Eksik numara TEK BASINA kusur kaniti degildir (madde gercekten
#  mulga olabilir) - ADAY listesidir, elle bakilir.
#  OLCUM betigi - hicbir sey yazmaz.
# ============================================================================
param([int]$EnAz = 1)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ambar = Join-Path $kok "veri\mevzuat"

$rapor = @()
foreach($f in (Get-ChildItem $ambar -Filter *.json | Where-Object { $_.Name -notmatch '^_' })){
  try { $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  $b = @($j.belgeler); if(-not $b.Count){ continue }
  # yalniz duz "m.N" (ek/gecici/mukerrer haric) numaralari
  $nolar = @()
  foreach($x in $b){
    $m = [regex]::Match("$($x.kaynak_ad)", '(?<!ek |gec\. |muk\. )\bm\.(\d+)(?:\s|\[|$)')
    if($m.Success){ $nolar += [int]$m.Groups[1].Value }
  }
  $nolar = @($nolar | Sort-Object -Unique)
  if($nolar.Count -lt 3){ continue }
  $enB = $nolar[0]; $enS = $nolar[-1]
  $eksik = @()
  for($i=$enB; $i -le $enS; $i++){ if($nolar -notcontains $i){ $eksik += $i } }
  if($eksik.Count -ge $EnAz){
    $rapor += [pscustomobject]@{
      dosya = $f.Name; madde = $nolar.Count; aralik = "$enB-$enS"
      eksikSayi = $eksik.Count
      oran = [math]::Round(100.0*$eksik.Count/($enS-$enB+1),1)
      eksikler = ($eksik | Select-Object -First 14) -join ','
    }
  }
}
$rapor = @($rapor | Sort-Object eksikSayi -Descending)
Write-Host ("Ambarda taranan dosya: {0} · madde bosluğu olan: {1}`n" -f @(Get-ChildItem $ambar -Filter *.json).Count, $rapor.Count)
Write-Host ("{0,-26} {1,6} {2,10} {3,7} {4,6}  {5}" -f "DOSYA","MADDE","ARALIK","EKSIK","%","EKSIK NUMARALAR")
Write-Host ("-"*108)
foreach($r in ($rapor | Select-Object -First 30)){
  Write-Host ("{0,-26} {1,6} {2,10} {3,7} {4,6}  {5}" -f $r.dosya, $r.madde, $r.aralik, $r.eksikSayi, $r.oran, $r.eksikler)
}
$toplam = ($rapor | Measure-Object eksikSayi -Sum).Sum
Write-Host ("`nTOPLAM eksik madde adayi: {0} (bu dosyalarda)" -f $toplam)
Write-Host "NOT: eksik numara tek basina kusur degildir - madde gercekten mulga olabilir."
Write-Host "     Kesin hukum icin o maddenin KAYNAK METNI okunur."
