# ============================================================================
#  CIKMIS SINAV KITAPCIGI -> SORU SORU AYRISTIRICI - 08.08.2026
#
#  CEM: "ayristiriciyi duzelt ve hepsini yut"
#
#  ONCEKI KUSUR: siklar SATIR BASINDA aranıyordu. Olcum gosterdi ki kitapciklarda
#  siklar cogu zaman TEK SATIRDA yan yana yaziliyor: "A) I  B) II  C) III  D) IV
#  E) V". Bu yuzden A) bulunuyor (108/130) ama B) 77, E) 64'te kaliyordu ve
#  "en az 4 sik" sarti tutmadigi icin soru ATILIYORDU. Kitapcik basina 130
#  sorunun ancak ~58'i cikiyordu.
#
#  ONARIM: sik ayirici artik SATIR ICI calisir - metindeki "(A-E))" isaretlerini
#  SIRAYLA bulur ve aralarini boler. Hem satir basi hem yan yana yazimi tanir.
#
#  SUTUN: kitapciklar iki sutun; Xpdf pdftotext'in -marginl/-marginr secenekleri
#  ile her sutun ayri cikarilir (okuma sirasi bozulmasin diye).
#
#  Cikti: veri/cikmis-soru-ayrisma.json (sayim) + -yaz ile ambara tur='cikmis-soru'
#  BEDAVA.
# ============================================================================
param([switch]$yaz, [int]$tavan = 0, [string]$klasor = '', [string]$sinavAdi = '')
$ErrorActionPreference='Continue'
if($klasor -eq ''){ $klasor = Join-Path $env:TEMP 'cikmis-soru' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not (Test-Path $klasor)){ Write-Host "Klasor yok: $klasor"; exit 1 }

# --- SIK AYIRICI: satir ici VE satir basi ---
function SiklariAyir([string]$blok){
  $sonuc = [ordered]@{}
  $isaretler = @([regex]::Matches($blok, '(?<![A-Za-z0-9])([A-E])\)\s'))
  if($isaretler.Count -lt 4){ return $sonuc }
  # 08.08 IKINCI ONARIM: ARTAN SIRA DAYATMASI KALDIRILDI.
  # Olcum: SGS 2026/2'de 130 sorunun 18'i dusuyordu ve sebep buydu - iki sutunlu
  # dizgide siklar metne SIRASIZ dokuluyor. Ornek soru 24:
  #     "A) politely  B) rapidly  D) silently  C) ..."
  # Eski kod A,B'yi alip C bekliyordu; D gorunce zincir kiriliyor, soru
  # "4 sik yok" diye ATILIYORDU. Oysa dort sik da oradaydi.
  # Yeni kural: her harfin ILK gecisi alinir, KONUMA gore siralanir. Sira
  # dayatilmaz; dilimleme yine konuma gore yapildigi icin her sikkin metni
  # dogru esler.
  $ilkGecis = @{}
  foreach($m in $isaretler){
    $h = $m.Groups[1].Value
    if(-not $ilkGecis.ContainsKey($h)){ $ilkGecis[$h] = $m }
  }
  if($ilkGecis.Count -lt 4){ return $sonuc }
  $sirali = New-Object System.Collections.Generic.List[object]
  foreach($m in ($ilkGecis.Values | Sort-Object { $_.Index })){ $sirali.Add($m) }
  for($i=0; $i -lt $sirali.Count; $i++){
    $bas = $sirali[$i].Index + $sirali[$i].Length
    $son = if($i -lt $sirali.Count-1){ $sirali[$i+1].Index } else { $blok.Length }
    $v = $blok.Substring($bas, [Math]::Max(0,$son-$bas))
    $sonuc[$sirali[$i].Groups[1].Value] = ($v -replace '\s+',' ').Trim()
  }
  return $sonuc
}

function SorulariCikar([string]$metin){
  $liste = New-Object System.Collections.Generic.List[object]
  foreach($p in [regex]::Split($metin, '(?m)^(?=\s{0,4}\d{1,3}\.\s)')){
    if($p.Trim().Length -lt 40){ continue }
    $no = [regex]::Match($p, '^\s*(\d{1,3})\.')
    if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value
    if($n -lt 1 -or $n -gt 130){ continue }
    $sk = SiklariAyir $p
    if($sk.Count -lt 4){ continue }
    # kok: ilk sik isaretine kadar
    $ilk = [regex]::Match($p, '(?<![A-Za-z0-9])A\)\s')
    $kk = if($ilk.Success){ $p.Substring(0, $ilk.Index) } else { $p }
    $kk = ($kk -replace '^\s*\d{1,3}\.\s*','') -replace '\s+',' '
    $kk = $kk.Trim()
    if($kk.Length -lt 15){ continue }
    $liste.Add([pscustomobject]@{ no=$n; kok=$kk; siklar=$sk })
  }
  return $liste
}

$pdfler = @(Get-ChildItem (Join-Path $klasor '*.pdf') | Sort-Object Name)
if($tavan -gt 0){ $pdfler = @($pdfler | Select-Object -First $tavan) }
Write-Host ("Kitapcik: {0}" -f $pdfler.Count)

$AMBAR = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
if($yaz){
  if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
  Add-Type -AssemblyName System.Net.Http
  $hc=New-Object System.Net.Http.HttpClient
  $hc.Timeout=[TimeSpan]::FromSeconds(120)
  $hc.DefaultRequestHeaders.Add('apikey',$env:SUPABASE_SERVICE_KEY)
  $hc.DefaultRequestHeaders.Add('Authorization',('Bearer '+$env:SUPABASE_SERVICE_KEY))
}

$rapor = New-Object System.Collections.Generic.List[object]
$topSoru=0; $yazilan=0; $yazHata=0; $isle=0
foreach($f in $pdfler){
  $isle++
  $parca = $f.BaseName -split '-'
  $sv = if($sinavAdi -ne ''){ $sinavAdi } else { $parca[0] }; $don = if($parca.Count -gt 1){ $parca[1] -replace '_','/' } else { '' }
  $sol = Join-Path $klasor ($f.BaseName + '.sol.txt')
  $sag = Join-Path $klasor ($f.BaseName + '.sag.txt')
  if(-not (Test-Path $sol)){ try { & pdftotext -q -enc UTF-8 -marginr 300 $f.FullName $sol 2>&1 | Out-Null } catch {} }
  if(-not (Test-Path $sag)){ try { & pdftotext -q -enc UTF-8 -marginl 295 $f.FullName $sag 2>&1 | Out-Null } catch {} }
  $tekil = @{}
  foreach($t in @($sol,$sag)){
    if(-not (Test-Path $t)){ continue }
    foreach($s in (SorulariCikar (Get-Content $t -Raw -Encoding UTF8))){
      if(-not $tekil.ContainsKey($s.no)){ $tekil[$s.no] = $s }
      elseif($s.kok.Length -gt $tekil[$s.no].kok.Length){ $tekil[$s.no] = $s }
    }
  }
  $adet = $tekil.Count
  $topSoru += $adet
  $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; sinav=$sv; donem=$don; soru=$adet })
  if($yaz -and $adet -ge 20){
    # kitapcigin TUM sorularini TEK belge olarak yaz (soru soru yazmak 130x193 kayit eder)
    $sb = New-Object Text.StringBuilder
    foreach($n in ($tekil.Keys | Sort-Object)){
      $s = $tekil[$n]
      [void]$sb.AppendLine(("SORU " + $n + ": " + $s.kok))
      foreach($h in $s.siklar.Keys){ [void]$sb.AppendLine(("  " + $h + ") " + $s.siklar[$h])) }
      [void]$sb.AppendLine('')
    }
    $govde=[ordered]@{
      id=([guid]::NewGuid().ToString())
      kaynak_ad=('CIKMIS SINAV - ' + $sv + ' ' + $don + ' (' + $f.BaseName + ')')
      baslik=('Cikmis sinav sorulari - ' + $sv + ' ' + $don + ' - ' + $adet + ' soru')
      tur='cikmis-soru'
      metin=$sb.ToString()
    }
    $j = ConvertTo-Json -InputObject $govde -Depth 4 -Compress
    $i2 = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post),$AMBAR
    $i2.Content = New-Object System.Net.Http.StringContent ($j,[Text.Encoding]::UTF8,'application/json')
    $i2.Headers.Add('Prefer','return=minimal')
    $c = $hc.SendAsync($i2).GetAwaiter().GetResult()
    if([int]$c.StatusCode -eq 201){ $yazilan++ } else { $yazHata++; if($yazHata -le 2){ Write-Host ('  YAZMA HATASI kod ' + [int]$c.StatusCode + ' - ' + $c.Content.ReadAsStringAsync().GetAwaiter().GetResult()) } }
    $c.Dispose(); $i2.Dispose()
  }
  if($isle % 25 -eq 0){ Write-Host ("  ... {0}/{1}" -f $isle,$pdfler.Count) }
}
Write-Host "`n--- SINAV BAZINDA ---"
Write-Host ("{0,-8} {1,9} {2,9} {3,10}" -f 'SINAV','KITAPCIK','SORU','SORU/KIT')
foreach($sv in ($rapor.sinav | Sort-Object -Unique)){
  $g = @($rapor | Where-Object { $_.sinav -eq $sv })
  $s = ($g | Measure-Object -Property soru -Sum).Sum
  Write-Host ("{0,-8} {1,9} {2,9} {3,10}" -f $sv,$g.Count,$s,[math]::Round($s/[math]::Max($g.Count,1),1))
}
Write-Host ("`nTOPLAM AYRISAN SORU: {0}" -f $topSoru)
if($yaz){ Write-Host ("AMBARA YAZILAN KITAPCIK: {0} | HATA: {1}" -f $yazilan,$yazHata) }
[IO.File]::WriteAllText((Join-Path $kok 'veri\cikmis-soru-ayrisma.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); toplamSoru=$topSoru; yazilan=$yazilan; kitapciklar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host "Rapor: veri/cikmis-soru-ayrisma.json"
