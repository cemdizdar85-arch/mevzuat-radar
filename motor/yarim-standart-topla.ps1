# ============================================================================
#  YARIM STANDART TOPLU YUTMA — 25.08.2026
#  Cem: "eski yarim okunan varsa onlari tumden oku"
#  Butunluk kapisinin bulduğu delikli TMS/TFRS standartlarini sirayla,
#  standart-yut.ps1 ile BASTAN SONA yeniden yutar. Her biri kendi geri
#  okumasiyla dogrulanir; dogrulanmayan KIRMIZI raporlanir ve sonraki
#  standarda gecilir (bir standardin dusmesi butun turu durdurmaz).
#  0 USD, model yok.
# ============================================================================
# ⚠ 25.08 TUZAK: bu betik "powershell -File ... -liste @(...)" ile cagrilirsa
# PowerShell diziyi AYRI ARGUMANLARA bolerek gonderir; -liste yalniz ILK
# ogeyi alir ve 35 standartlik kosu SESSIZCE 1 standarda duser ("[1/1]").
# Hata vermez - yalniz eksik is yapar. Bu yuzden liste artik DOSYADAN da
# okunabilir: -listeDosya <satir satir standart adi>. Cagiran dizi yerine
# dosya verir, kirpilma olmaz.
param([switch]$uygula, [string[]]$liste = @(), [string]$listeDosya = '')
$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
if($listeDosya){
  $ly = if(Test-Path $listeDosya){ $listeDosya } else { Join-Path $depoKok $listeDosya }
  if(Test-Path $ly){ $liste = @([IO.File]::ReadAllLines($ly,[Text.Encoding]::UTF8) | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }) }
  else { Write-Host "Liste dosyasi yok: $ly"; exit 1 }
}
if($liste.Count -eq 0){
  # butunluk kapisinin delikli buldugu TMS/TFRS'ler (25.08 olcumu)
  $liste = @('TMS 34','TMS 36','TFRS 17','TMS 38','TMS 32','TFRS 18','TFRS 15','TMS 40',
             'TFRS 13','TMS 12','TMS 19','TFRS 7','TMS 37','TFRS 3','TMS 21','TMS 41',
             'TMS 1','TMS 16','TMS 20','TMS 28','TFRS 9','TFRS 5','TMS 2','TMS 7','TMS 8','TMS 10')
}
$sonuc = New-Object System.Collections.Generic.List[object]
$i=0
foreach($std in $liste){
  $i++
  Write-Host ''
  Write-Host ("===== [{0}/{1}] {2} =====" -f $i,$liste.Count,$std)
  $arg = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $here 'standart-yut.ps1'),'-standart',$std)
  if($uygula){ $arg += '-uygula' }
  $cikti = & powershell @arg 2>&1
  $kod = $LASTEXITCODE
  $satirlar = @($cikti | ForEach-Object { "$_" })
  $eski=''; $yeni=''; $dogru=$false; $hata=''
  foreach($s in $satirlar){
    if($s -match 'AMBARDAKI HALI\s*:\s*(\d+) parca · ([\d\.]+) karakter'){ $eski = "$($Matches[1]) parca / $($Matches[2]) krk" }
    if($s -match 'YENI HALI\s*:\s*(\d+) parca · ([\d\.]+) karakter'){ $yeni = "$($Matches[1]) parca / $($Matches[2]) krk" }
    if($s -match 'DOGRULANDI'){ $dogru=$true }
    if($s -match 'PDF DEGIL|bulunamadi|TUTMUYOR|Exception|hata'){ if(-not $hata){ $hata = $s.Trim() } }
  }
  $durum = if($kod -ne 0 -and -not $dogru){ 'DUSTU' } elseif($uygula -and $dogru){ 'YAZILDI' } elseif(-not $uygula){ 'PROVA' } else { 'BELIRSIZ' }
  Write-Host ("   {0,-9} eski: {1,-24} yeni: {2}" -f $durum,$(if($eski){$eski}else{'?'}),$(if($yeni){$yeni}else{'?'}))
  if($hata){ Write-Host ("   ! {0}" -f $hata.Substring(0,[Math]::Min(110,$hata.Length))) }
  $sonuc.Add([pscustomobject]@{ standart=$std; durum=$durum; eski=$eski; yeni=$yeni; hata=$hata })
}
Write-Host ''
Write-Host '================ OZET ================'
foreach($g in ($sonuc | Group-Object durum | Sort-Object Count -Descending)){ Write-Host ("  {0,-10} {1}" -f $g.Name,$g.Count) }
$duz=@(); foreach($s in $sonuc){ $duz += ,$s }
[IO.File]::WriteAllText((Join-Path $depoKok 'veri/yarim-standart-yutma.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); uygulandi=[bool]$uygula; sonuc=$duz }) -Depth 6),
  (New-Object Text.UTF8Encoding($false)))
Write-Host '-> veri/yarim-standart-yutma.json'