# ============================================================================
#  CIKMIS SINAV SORULARI vs BIZIM SORULARIMIZ - AYNI CETVEL - 08.08.2026
#
#  CEM: "eski sinav sorulari ile kontrol edemiyoruz ki, oyle bir kontrol
#        saglayalim: bizim sorularimiz eski cikmis sinav sorularindan ne kadar
#        kolay, yoksa ayni mi?"
#  CEM: "daha eski butun staja giris yeterlilik ve bagimsiz denetim sorularini
#        indirmedin ki nasil olcum yaptin - indir sonra bunlarin hepsini olc"
#
#  ONEMLI - ADIL KOSUL: cikmis soruda ACIKLAMA YOKTUR. Bu yuzden iki taraf da
#  YALNIZCA KOK + SIKLAR ile puanlanir. Bizim sorulari aciklamalariyla puanlayip
#  cikmis soruyla kiyaslamak bizimkilere haksiz puan verirdi.
#
#  SUTUN AYIRMA: kitapciklar IKI SUTUN dizgisinde. Karakter konumundan bolmek
#  kirilgandi (kitapcik basina 130 sorunun ancak ~%34'u cikiyordu). Xpdf
#  pdftotext'in -marginl / -marginr secenekleriyle her sutun AYRI cikarilir.
#
#  BEDAVA: yerel metin isleme. API yok.
# ============================================================================
param([string]$klasor = '', [int]$tavan = 0, [switch]$ayrinti)
$ErrorActionPreference='Continue'
if($klasor -eq ''){ $klasor = Join-Path $env:TEMP 'cikmis-soru' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not (Test-Path $klasor)){ Write-Host ("Klasor yok: $klasor"); exit 1 }

$zSayi  = [regex]'\d[\d\.]*(?:,\d+)?'
$zIslem = [regex]'[+\-x*/]\s*%?\d'
function Puan([string]$kok, [string[]]$siklar){
  $puan = 0
  $sa = $zSayi.Matches($kok).Count
  if($sa -ge 6){ $puan += 2 } elseif($sa -ge 3){ $puan += 1 }
  $ia = $zIslem.Matches($kok).Count
  if($ia -ge 6){ $puan += 2 } elseif($ia -ge 2){ $puan += 1 }
  $dg = @()
  foreach($v in $siklar){
    $mm = $zSayi.Match($v)
    if($mm.Success -and $v.Length -le 90){
      $n = ($mm.Value -replace '\.','') -replace ',','.'
      $dd = 0.0
      if([double]::TryParse($n,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$dd)){ $dg += $dd }
    }
  }
  if(@($dg).Count -ge 4){
    $sr = @($dg | Sort-Object); $ey = 1.0
    for($i=1; $i -lt $sr.Count; $i++){
      if($sr[$i-1] -eq 0){ continue }
      $ff = [math]::Abs($sr[$i]-$sr[$i-1]) / [math]::Abs($sr[$i-1])
      if($ff -lt $ey){ $ey = $ff }
    }
    if($ey -lt 0.03){ $puan += 2 } elseif($ey -lt 0.08){ $puan += 1 }
  }
  $kelime = @($kok -split '\s+' | Where-Object { $_ }).Count
  if($kelime -ge 90){ $puan += 1 }
  if($kok -imatch '(yanl[^ ]{0,2}[st][^ ]{0,2}r|de[^ ]{0,2}ildir|degildir|s[^ ]{0,2}ylenemez|olamaz|yer almaz|bulunmaz|gerekmez)'){ $puan += 1 }
  $oa = ([regex]::Matches($kok,'(?m)^\s*(I{1,3}V?|IV|VI?)\s*[\.\)]\s')).Count
  if($oa -ge 4){ $puan += 3 } elseif($oa -eq 3){ $puan += 2 } elseif($oa -eq 2){ $puan += 1 }
  elseif($kok -imatch 'hangileri'){ $puan += 1 }
  $ist = ([regex]::Matches($kok,'(?i)(ancak|istisna|d[^ ]{0,2}[st][^ ]{0,2}nda|hari[^ ]{0,2}|[^ ]{0,2}art[^ ]{0,2}yla|ko[^ ]{0,2}uluyla)')).Count
  if($ist -ge 4){ $puan += 2 } elseif($ist -ge 2){ $puan += 1 }
  $su = @($siklar | ForEach-Object { @($_ -split '\s+' | Where-Object { $_ }).Count })
  if($su.Count -ge 4){
    $ort = ($su | Measure-Object -Average).Average
    if($ort -ge 18){ $puan += 2 } elseif($ort -ge 10){ $puan += 1 }
  }
  if($kelime -ge 35 -and $kok -imatch '(buna g[^ ]{0,2}re|bu durum|s[^ ]{0,2}z konusu|bu olayda|nas[^ ]{0,2}l|ka[^ ]{0,2} TL)'){ $puan += 1 }
  $zn = ([regex]::Matches($kok,'=')).Count
  if($zn -ge 5){ $puan += 2 } elseif($zn -ge 3){ $puan += 1 }
  if($kok -imatch '(s[^ ]{0,2}ras[^ ]{0,2}yla|ayr[^ ]{0,2}m[^ ]{0,2}|birlikte do|hangisinde do|farkl)'){ $puan += 1 }
  return $puan
}

function SorulariCikar([string]$metin){
  $liste = New-Object System.Collections.Generic.List[object]
  $parcalar = [regex]::Split($metin, '(?m)^(?=\s{0,4}\d{1,3}\.\s)')
  foreach($p in $parcalar){
    if($p.Trim().Length -lt 50){ continue }
    $no = [regex]::Match($p, '^\s*(\d{1,3})\.')
    if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value
    if($n -lt 1 -or $n -gt 130){ continue }
    $sk = @()
    foreach($h in 'A','B','C','D','E'){
      $m = [regex]::Match($p, '(?ms)^\s*' + $h + '\)\s*(.+?)(?=^\s*[A-E]\)|\z)')
      if($m.Success){ $sk += ($m.Groups[1].Value -replace '\s+',' ').Trim() }
    }
    if($sk.Count -lt 4){ continue }
    $ilk = [regex]::Match($p, '(?m)^\s*A\)')
    $kk = if($ilk.Success){ $p.Substring(0, $ilk.Index) } else { $p }
    $kk = ($kk -replace '\s+',' ').Trim()
    if($kk.Length -lt 20){ continue }
    $liste.Add([pscustomobject]@{ no=$n; kok=$kk; siklar=$sk })
  }
  return $liste
}

$pdfler = @(Get-ChildItem (Join-Path $klasor '*.pdf') | Sort-Object Name)
if($tavan -gt 0){ $pdfler = @($pdfler | Select-Object -First $tavan) }
Write-Host ("Kitapcik: {0}" -f $pdfler.Count)
$sinavlar = @{}
$isle = 0
foreach($f in $pdfler){
  $isle++
  $sv = ($f.BaseName -split '-')[0]
  if(-not $sinavlar.ContainsKey($sv)){ $sinavlar[$sv] = @{ kitapcik=0; soru=0; k=0; o=0; z=0; puanlar=New-Object System.Collections.Generic.List[int] } }
  $sol = Join-Path $klasor ($f.BaseName + '.sol.txt')
  $sag = Join-Path $klasor ($f.BaseName + '.sag.txt')
  if(-not (Test-Path $sol)){ try { & pdftotext -q -enc UTF-8 -marginr 300 $f.FullName $sol 2>&1 | Out-Null } catch {} }
  if(-not (Test-Path $sag)){ try { & pdftotext -q -enc UTF-8 -marginl 295 $f.FullName $sag 2>&1 | Out-Null } catch {} }
  $bulunan = New-Object System.Collections.Generic.List[object]
  foreach($t in @($sol,$sag)){
    if(-not (Test-Path $t)){ continue }
    $metin = Get-Content $t -Raw -Encoding UTF8
    foreach($s in (SorulariCikar $metin)){ $bulunan.Add($s) }
  }
  # ayni soru numarasi iki sutundan da gelebilir - tekille
  $tekil = @{}
  foreach($s in $bulunan){ if(-not $tekil.ContainsKey($s.no)){ $tekil[$s.no] = $s } }
  $sinavlar[$sv].kitapcik++
  foreach($s in $tekil.Values){
    $p = Puan $s.kok $s.siklar
    $sinavlar[$sv].soru++
    $sinavlar[$sv].puanlar.Add($p)
    if($p -le 2){ $sinavlar[$sv].k++ } elseif($p -le 5){ $sinavlar[$sv].o++ } else { $sinavlar[$sv].z++ }
  }
  if($ayrinti){ Write-Host ("  {0,-22} {1,4} soru" -f $f.BaseName,$tekil.Count) }
  if($isle % 25 -eq 0){ Write-Host ("  ... {0}/{1} kitapcik islendi" -f $isle,$pdfler.Count) }
}
Write-Host ("`n{0,-8} {1,9} {2,7} {3,8} {4,7} {5,7} {6,7} {7,9}" -f 'SINAV','KITAPCIK','SORU','SORU/KIT','KOLAY%','ORTA%','ZOR%','ORT.PUAN')
$cikti = [ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); sinavlar=[ordered]@{} }
foreach($sv in ($sinavlar.Keys | Sort-Object)){
  $g = $sinavlar[$sv]
  $t = [math]::Max($g.soru,1)
  $ort = if($g.puanlar.Count){ [math]::Round(($g.puanlar | Measure-Object -Average).Average,2) } else { 0 }
  $sk = if($g.kitapcik){ [math]::Round($g.soru/$g.kitapcik,1) } else { 0 }
  Write-Host ("{0,-8} {1,9} {2,7} {3,8} {4,6}% {5,6}% {6,6}% {7,9}" -f $sv,$g.kitapcik,$g.soru,$sk,[math]::Round(100*$g.k/$t,1),[math]::Round(100*$g.o/$t,1),[math]::Round(100*$g.z/$t,1),$ort)
  $cikti.sinavlar[$sv] = [ordered]@{ kitapcik=$g.kitapcik; soru=$g.soru; soruBasinaKitapcik=$sk; kolay=$g.k; orta=$g.o; zor=$g.z; ortalamaPuan=$ort }
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-soru-olcum.json'), (ConvertTo-Json -InputObject $cikti -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host "`nRapor: veri/cikmis-soru-olcum.json"
Write-Host "NOT: kitapcik basina 130 soru beklenir; SORU/KIT bundan dusukse ayristirici hala kaybediyor demektir."
