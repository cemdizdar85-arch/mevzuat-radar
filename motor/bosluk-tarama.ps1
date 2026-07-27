# BOSLUK TARAMASI: kitapciklarda cikan konular vs ambarda olan metinler
$ErrorActionPreference = "Stop"
$kok = $env:TETIKTE_KOK
if(-not $kok){ $kok = (Get-Item "C:\Users\cemdi\OneDrive\Masa*\mevzuat*\mevzuat-radar").FullName }

$ambStd = @('TMS 1','TMS 2','TMS 7','TMS 8','TMS 10','TMS 12','TMS 16','TMS 19','TMS 21','TMS 23','TMS 29','TMS 36','TMS 37','TMS 38','TMS 40',
            'TFRS 3','TFRS 7','TFRS 9','TFRS 10','TFRS 13','TFRS 15','TFRS 16',
            'BDS 200','BDS 230','BDS 240','BDS 300','BDS 315','BDS 320','BDS 450','BDS 500','BDS 501','BDS 505','BDS 520','BDS 530','BDS 570','BDS 700','BDS 705','BDS 706')

$bulunan = @{}
$kanunlar = @{}
foreach($f in @('sgs-analiz.json','smmm-analiz.json')){
  $p = Join-Path $kok "veri\$f"
  if(-not (Test-Path $p)){ continue }
  $d = Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($dn in $d.donemler){
    if(-not $dn.konuSayim){ continue }
    foreach($pp in $dn.konuSayim.PSObject.Properties){
      $parca = $pp.Name -split '\|',2
      $konu = if($parca.Count -gt 1){ $parca[1] } else { $parca[0] }
      $adet = [int]$pp.Value
      foreach($m in [regex]::Matches("$konu",'(?i)(tms|tfrs|bds|kys)\s*(\d+)')){
        $ad = ($m.Groups[1].Value.ToUpper() + ' ' + $m.Groups[2].Value)
        $bulunan[$ad] = [int]$bulunan[$ad] + $adet
      }
      foreach($m2 in [regex]::Matches("$konu",'(?i)(vuk|ttk|tbk|gvk|kvk|kdv|otv|iik|aatuhk|4857|5510|6356|3568|5018|6098|6102|213|193|5520|3065|4760|6183|2004|6331|1475)')){
        $ad2 = $m2.Groups[1].Value.ToUpper()
        $kanunlar[$ad2] = [int]$kanunlar[$ad2] + $adet
      }
    }
  }
}

Write-Host "===== KITAPCIKLARDA GECEN STANDARTLAR (16 SGS + 8 SMMM donem) ====="
$eksik = @()
$bulunan.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
  if($ambStd -contains $_.Key){ $durum = 'AMBARDA' } else { $durum = '>>> EKSIK <<<'; $eksik += $_.Key }
  Write-Host ("  {0,-10}: {1,3} soru   [{2}]" -f $_.Key, $_.Value, $durum)
}
Write-Host ""
Write-Host "===== KITAPCIKLARDA GECEN KANUN ATIFLARI ====="
$kanunlar.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
  Write-Host ("  {0,-10}: {1,3} soru" -f $_.Key, $_.Value)
}
Write-Host ""
Write-Host "===== SONUC ====="
if($eksik.Count -eq 0){ Write-Host "Kitapciklarda gecen TUM standart metinleri ambarda." }
else { Write-Host ("EKSIK STANDART: " + ($eksik -join ', ')) }
