# ============================================================================
#  SGS YABANCI DIL VARYANTI - YALNIZ FARKI AMBARA YAZ  - 23.08.2026
#
#  DURUM: TESMER her SGS donemi icin ayni kitapcigi uc dilde basiyor
#  (ingilizce / almanca / fransizca). 130 sorunun buyuk cogunlugu UCUNDE DE
#  AYNI; yalnizca Yabanci Dil bolumu (~20 soru) degisiyor.
#
#  NEDEN AYRI BETIK: almanca kitapcigi butun halinde ambara yazsak her donem
#  icin ~110 MUKERRER soru girerdi. Ambar sisip tam-metin aramasi bozulur
#  (21.08'de tam bu yasandi: tek satir 68 bin karakterlik sinav kagitlari
#  butun sorgulari kazaniyordu). Bu betik INGILIZCE surumu TABAN alir,
#  almanca/fransizca surumde AYNI OLMAYAN sorulari ayirir, yalniz onlari yazar.
#
#  ESLESME: soru koku harf-rakam disi karakterlerden arindirilip kucultulur,
#  ilk 60 karakteri anahtar olur. Ayni soru iki dosyada tipografik olarak
#  farkli cikabilir (tireli satir sonu, bosluk farki) - normalizasyon bunu yutar.
#
#  Girdi : veri/sgs-arsiv/pdf  (ingilizce TABAN dosyasi da orada olmali)
#  Cikti : veri/sgs-dil-farki-raporu.json
#  BEDAVA.  Kullanim: .\sgs-dil-farki-yut.ps1 [-yaz]
# ============================================================================
param([switch]$yaz, [int]$Tavan = 0)
$ErrorActionPreference = 'Continue'
$kok = Split-Path -Parent $PSScriptRoot
$AMBAR_URL = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
$klasor = Join-Path $kok 'veri\sgs-arsiv\pdf'
if(-not (Test-Path $klasor)){ Write-Host "Klasor yok: $klasor"; exit 1 }

# --- DOGRU pdftotext (bkz cikmis-soru-ayristir.ps1: poppler -marginr'i tanimiyor) ---
$PDFTOTEXT = 'pdftotext'; $KIRPMA_VAR = $false
$adaylar = @('C:\Program Files\Git\mingw64\bin\pdftotext.exe')
foreach($c in @(Get-Command pdftotext -All -ErrorAction SilentlyContinue)){ $adaylar += $c.Source }
foreach($a in $adaylar){
  if(-not (Test-Path $a)){ continue }
  if((& $a -h 2>&1 | Out-String) -match '-marginr'){ $PDFTOTEXT = $a; $KIRPMA_VAR = $true; break }
  if($PDFTOTEXT -eq 'pdftotext'){ $PDFTOTEXT = $a }
}

# Ayristirma mantigi cikmis-soru-ayristir.ps1 ile AYNI olmali; orasi degisirse
# burasi da degisir. (Dot-source edilmiyor cunku o betigin param blogu var.)
function SiklariAyir([string]$blok){
  $sonuc = [ordered]@{}
  $isaretler = @([regex]::Matches($blok, '(?<![A-Za-z0-9])([A-E])\)\s'))
  if($isaretler.Count -lt 4){ return $sonuc }
  $ilkGecis = @{}
  foreach($m in $isaretler){ $hrf = $m.Groups[1].Value; if(-not $ilkGecis.ContainsKey($hrf)){ $ilkGecis[$hrf] = $m } }
  if($ilkGecis.Count -lt 4){ return $sonuc }
  $sirali = New-Object System.Collections.Generic.List[object]
  foreach($m in ($ilkGecis.Values | Sort-Object { $_.Index })){ $sirali.Add($m) }
  for($i = 0; $i -lt $sirali.Count; $i++){
    $bas = $sirali[$i].Index + $sirali[$i].Length
    $son = if($i -lt $sirali.Count - 1){ $sirali[$i+1].Index } else { $blok.Length }
    $sonuc[$sirali[$i].Groups[1].Value] = (($blok.Substring($bas, [Math]::Max(0, $son - $bas))) -replace '\s+',' ').Trim()
  }
  return $sonuc
}

function SorulariCikar([string]$metin, [string]$stil){
  $liste = New-Object System.Collections.Generic.List[object]
  $ayrac = if($stil -eq ')'){ '\)' } else { '\.' }
  $modul = 0; $onceki = 0
  foreach($p in [regex]::Split($metin, ('(?m)^(?=\s{0,4}\d{1,3}' + $ayrac + '\s)'))){
    if($p.Trim().Length -lt 40){ continue }
    $no = [regex]::Match($p, ('^\s*(\d{1,3})' + $ayrac)); if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value; if($n -lt 1 -or $n -gt 130){ continue }
    $sk = SiklariAyir $p; if($sk.Count -lt 4){ continue }
    $ilk = [regex]::Match($p, '(?<![A-Za-z0-9])A\)\s')
    $kk = if($ilk.Success){ $p.Substring(0, $ilk.Index) } else { $p }
    $kk = (($kk -replace ('^\s*\d{1,3}' + $ayrac + '\s*'), '') -replace '\s+',' ').Trim()
    if($kk.Length -lt 15){ continue }
    if($n -le $onceki){ $modul++ }
    $onceki = $n
    $liste.Add([pscustomobject]@{ no = $n; modul = $modul; kok = $kk; siklar = $sk })
  }
  return $liste
}

function Normal([string]$s){
  $z = ($s -replace '[^\p{L}\p{Nd}]','').ToLowerInvariant()
  if($z.Length -gt 60){ $z = $z.Substring(0,60) }
  return $z
}

# Aile x stil yarismasi (ayristiricidaki ile ayni mantik, kucuk hali)
function EnIyi([string]$temelAd){
  $pdf = Join-Path $klasor ($temelAd + '.pdf')
  $ocr = Join-Path $klasor ($temelAd + '.ocr.txt')
  $sol = Join-Path $klasor ($temelAd + '.sol.txt')
  $sag = Join-Path $klasor ($temelAd + '.sag.txt')
  $kardes = Join-Path (Join-Path (Split-Path -Parent $klasor) 'txt') ($temelAd + '.txt')
  if($KIRPMA_VAR -and (Test-Path $pdf)){
    if(-not (Test-Path $sol)){ try { & $PDFTOTEXT -q -enc UTF-8 -marginr 300 $pdf $sol 2>&1 | Out-Null } catch {} }
    if(-not (Test-Path $sag)){ try { & $PDFTOTEXT -q -enc UTF-8 -marginl 295 $pdf $sag 2>&1 | Out-Null } catch {} }
  }
  $aileler = @()
  if((Test-Path $ocr) -and (Get-Item $ocr).Length -gt 3000){ $aileler = @(,@($ocr)) }
  else {
    if((Test-Path $sol) -and (Test-Path $sag)){ $aileler += ,@($sol,$sag) }
    if(Test-Path $kardes){ $aileler += ,@($kardes) }
  }
  $en = @{}
  foreach($aile in $aileler){
    foreach($stil in @('.', ')')){
      $t = @{}
      foreach($dosya in @($aile)){
        if(-not (Test-Path $dosya)){ continue }
        foreach($s in (SorulariCikar (Get-Content $dosya -Raw -Encoding UTF8) $stil)){
          $a = "$($s.modul)#$($s.no)"
          if(-not $t.ContainsKey($a) -or $s.kok.Length -gt $t[$a].kok.Length){ $t[$a] = $s }
        }
      }
      if($t.Count -gt $en.Count){ $en = $t }
    }
  }
  return $en
}

$hedefler = @(@(Get-ChildItem (Join-Path $klasor 'sgs_*_lisans_a_almanca.pdf') -ErrorAction SilentlyContinue) +
              @(Get-ChildItem (Join-Path $klasor 'sgs_*_lisans_a_fransizca.pdf') -ErrorAction SilentlyContinue)) | Sort-Object Name
if($Tavan -gt 0){ $hedefler = @($hedefler | Select-Object -First $Tavan) }
Write-Host ("Dil varyanti kitapcigi: {0}" -f $hedefler.Count)
if($hedefler.Count -eq 0){ exit 0 }

$VAROLAN = @{}
if($yaz){
  if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
  Add-Type -AssemblyName System.Net.Http
  $hc = New-Object System.Net.Http.HttpClient; $hc.Timeout = [TimeSpan]::FromSeconds(120)
  $hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
  $hc.DefaultRequestHeaders.Add('Authorization', ('Bearer ' + $env:SUPABASE_SERVICE_KEY))
  try {
    $m = Invoke-RestMethod -Uri ($AMBAR_URL + '?select=kaynak_ad&tur=eq.cikmis-soru&limit=5000') `
         -Headers @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = ('Bearer ' + $env:SUPABASE_SERVICE_KEY) } `
         -UserAgent 'mevzuat-radar-robot/1.0'
    foreach($x in @($m)){ $VAROLAN["$($x.kaynak_ad)"] = 1 }
  } catch { Write-Host ('mevcut liste cekilemedi: ' + $_.Exception.Message); exit 1 }
}

$rapor = New-Object System.Collections.Generic.List[object]
$yazilan = 0; $zaten = 0; $atlanan = 0; $toplamFark = 0
foreach($f in $hedefler){
  $mm = [regex]::Match($f.BaseName, '^sgs_(\d{4})_(\d)_lisans_a_(almanca|fransizca)$')
  if(-not $mm.Success){ continue }
  $yil = $mm.Groups[1].Value; $don = $mm.Groups[2].Value; $dil = $mm.Groups[3].Value
  $tabanAd = "sgs_${yil}_${don}_lisans_a_ingilizce"
  if(-not (Test-Path (Join-Path $klasor ($tabanAd + '.pdf')))){
    $atlanan++; $rapor.Add([pscustomobject]@{ dosya = $f.BaseName; durum = 'TABAN-YOK'; not = $tabanAd }); continue
  }
  $taban = EnIyi $tabanAd
  $varyant = EnIyi $f.BaseName
  # Zayif okumada "fark" aslinda okunamayan sorudur - yanlis veri yazmaktansa atla
  if($taban.Count -lt 50 -or $varyant.Count -lt 50){
    $atlanan++
    $rapor.Add([pscustomobject]@{ dosya = $f.BaseName; durum = 'OKUMA-ZAYIF'; not = ("taban=$($taban.Count) varyant=$($varyant.Count)") })
    continue
  }
  $tabanSet = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach($v in $taban.Values){ [void]$tabanSet.Add((Normal $v.kok)) }
  $fark = @($varyant.Values | Where-Object { -not $tabanSet.Contains((Normal $_.kok)) } | Sort-Object no)

  # --- KARDES VARYANT SIGORTASI (23.08.2026) ---
  # Yabanci dil blogu ayni donemin HER varyantinda AYNI soru numaralarinda
  # durur (olculdu: 63 kitapcikta 9-12 soru, hep 21-30 araligi). Bir varyantin
  # metni zayif okunursa (2021/1 almanca: OCR 130 yerine 115 soru cikardi)
  # eslesmeyen her soru sahte "fark" sayilir - o kitapcik 33 fark verdi, 23'u
  # coptu. Kardes varyantin (almanca<->fransizca) fark NUMARALARIYLA kesistir:
  # gercek dil sorusu ikisinde de farkli olmak zorunda.
  $kardesDil = if($dil -eq 'almanca'){ 'fransizca' } else { 'almanca' }
  $kardesAd = "sgs_${yil}_${don}_lisans_a_$kardesDil"
  if($fark.Count -gt 15 -and (Test-Path (Join-Path $klasor ($kardesAd + '.pdf')))){
    $kv = EnIyi $kardesAd
    if($kv.Count -ge 50){
      $kFark = @($kv.Values | Where-Object { -not $tabanSet.Contains((Normal $_.kok)) })
      if($kFark.Count -ge 5 -and $kFark.Count -le 15){
        $noSet = New-Object 'System.Collections.Generic.HashSet[int]'
        foreach($x in $kFark){ [void]$noSet.Add([int]$x.no) }
        $onceki = $fark.Count
        $fark = @($fark | Where-Object { $noSet.Contains([int]$_.no) } | Sort-Object no)
        Write-Host ("     kardes sigortasi: {0} -> {1} (kardes {2})" -f $onceki, $fark.Count, $kardesDil)
      }
    }
  }
  $toplamFark += $fark.Count
  $rapor.Add([pscustomobject]@{ dosya = $f.BaseName; durum = 'OK'; taban = $taban.Count; varyant = $varyant.Count; fark = $fark.Count })
  Write-Host ("  {0,-36} taban={1,3} varyant={2,3} FARK={3,3}" -f $f.BaseName, $taban.Count, $varyant.Count, $fark.Count)
  if(-not $yaz){ continue }
  if($fark.Count -lt 5){ continue }   # 5'in altinda fark = eslesme kusuru, yazma
  $kad = "CIKMIS SINAV - SGS $yil/$don yabanci dil ($dil) ($($f.BaseName))"
  if($VAROLAN.ContainsKey($kad)){ $zaten++; continue }
  $sb = New-Object Text.StringBuilder
  foreach($s in $fark){
    [void]$sb.AppendLine(("SORU " + $s.no + ": " + $s.kok))
    foreach($hrf in $s.siklar.Keys){ [void]$sb.AppendLine(("  " + $hrf + ") " + $s.siklar[$hrf])) }
    [void]$sb.AppendLine('')
  }
  $govde = [ordered]@{
    id = ([guid]::NewGuid().ToString()); kaynak_ad = $kad
    baslik = ("Cikmis sinav sorulari - SGS $yil/$don yabanci dil: $dil - $($fark.Count) soru")
    tur = 'cikmis-soru'; metin = $sb.ToString()
  }
  $j = ConvertTo-Json -InputObject $govde -Depth 4 -Compress
  $i2 = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post), $AMBAR_URL
  $i2.Content = New-Object System.Net.Http.StringContent ($j, [Text.Encoding]::UTF8, 'application/json')
  $i2.Headers.Add('Prefer','return=minimal')
  $c = $hc.SendAsync($i2).GetAwaiter().GetResult()
  if([int]$c.StatusCode -eq 201){ $yazilan++ } else { Write-Host ('  YAZMA HATASI ' + [int]$c.StatusCode + ' - ' + $c.Content.ReadAsStringAsync().GetAwaiter().GetResult()) }
  $c.Dispose(); $i2.Dispose()
}

Write-Host ("`nTOPLAM FARK SORUSU: {0} | YAZILAN {1} | ZATEN VARDI {2} | ATLANAN {3}" -f $toplamFark, $yazilan, $zaten, $atlanan)
[IO.File]::WriteAllText((Join-Path $kok 'veri\sgs-dil-farki-raporu.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
     tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
     aciklama = 'SGS yabanci dil varyantlarinin ingilizce surumden FARKI. Ayni sorunun uc dilde tekrarlanmamasi icin yalniz fark ambara yazilir.'
     toplamFark = $toplamFark; yazilan = $yazilan; atlanan = $atlanan; kayitlar = $rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host 'Rapor: veri/sgs-dil-farki-raporu.json'
