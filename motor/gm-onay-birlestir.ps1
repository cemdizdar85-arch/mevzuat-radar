# GM ONAY BIRLESTIRICI (07.08) - okuma vardiyalarinin parca ciktilarindan
# tek onay listesi uretir; mukerrer id'leri teke indirir, red'le celisen
# id'yi (hem onay hem red'de olan) GUVENLI tarafa alir: RED sayilir, listeye girmez.
param([string]$parcaDir, [string]$cikti)
$onay=@{}; $red=@{}
Get-ChildItem (Join-Path $parcaDir 'gm-red-*.txt') -ErrorAction SilentlyContinue | ForEach-Object {
  Get-Content $_.FullName -Encoding UTF8 | ForEach-Object { $id=($_ -split '\|')[0].Trim(); if($id){ $red[$id]=1 } }
}
Get-ChildItem (Join-Path $parcaDir 'gm-onay-*.txt') -ErrorAction SilentlyContinue | ForEach-Object {
  Get-Content $_.FullName -Encoding UTF8 | ForEach-Object { $id=$_.Trim() -replace '\.json$',''; if($id -and -not $red.ContainsKey($id)){ $onay[$id]=1 } }
}
[IO.File]::WriteAllLines($cikti, @($onay.Keys | Sort-Object))
Write-Host ("onay {0} | red {1} | celisen-red-sayilan dahil | cikti: {2}" -f $onay.Count, $red.Count, $cikti)
