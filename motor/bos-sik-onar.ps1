# ============================================================================
#  BOS SIK ONARICI - KOORDINATLA ESLESTIRME  - 24.08.2026
#
#  SORUN (olculdu): ambardaki 20.851 sorunun 256'sinda bir veya daha fazla sik
#  BOS. Ornek (SGS 2011/3, soru 13):
#      A)
#      B)
#      C)
#      D)
#      E) A 3.200 3.600 4.000 4.300 4.500 TURMOB-TESMER-...
#  Sebep: eski SGS kitapciklarinda sik HARFLERI bir sutunda, sik METINLERI
#  ayri bir sutunda dizilmis. pdftotext duz metne cevirirken harfleri alt alta
#  yigip metinleri en sondaki harfin arkasina dokuyor.
#
#  METIN KAYIP DEGIL - yeri yanlis. Ve eslestirme TAHMIN DEGIL, OLCULEBILIR:
#  pdftotext -tsv ile her kelimenin X/Y koordinati alinir; sik harfi ile ona
#  ait metin AYNI Y satirindadir. Olcum (SGS 2011/3 sayfa 3):
#      A) Y=170.6  <->  6.400 Y=170.6
#      B) Y=180.6  <->  6.000 Y=180.6
#      C) Y=191.0  <->  5.000 Y=191.0
#  Birebir tutuyor.
#
#  YONTEM: her sayfa icin TSV alinir, "A)".."E)" isaretleri bulunur, her
#  birinin Y'sine +-TOLERANS icinde ve SAGINDA kalan kelimeler o sikkin metni
#  olur. Ayni sayfada iki sutun varsa (X~82 ve X~331) her isaret kendi
#  sutununda kalir cunku "saginda" sarti sutunu asmaz - bir sonraki sik
#  sutununun X'i sinir kabul edilir.
#
#  GUVENLIK: bir soru YALNIZ tum siklari (>=4) dolu cikarsa duzeltilir.
#  Kismi sonuc yazilmaz - eksik birakmak, yanlis eslestirmekten iyidir.
#
#  Cikti: veri/bos-sik-onarim.json  (-yaz ile ambar PATCH'lenir)
#  BEDAVA - yalniz yerel PDF okuma.
# ============================================================================
param(
  [string]$Klasor = '',
  [string]$Desen = '*.pdf',
  [switch]$yaz,
  [double]$Tolerans = 3.0
)
$ErrorActionPreference = 'Continue'
$kok = Split-Path -Parent $PSScriptRoot
if($Klasor -eq ''){ $Klasor = Join-Path $kok 'veri\sgs-arsiv\pdf' }
$AMBAR_URL = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# TSV veren pdftotext (poppler'da var, xpdf 4.06'da YOK - bkz
# cikmis-soru-ayristir.ps1'deki iki-ikili tuzagi; burada TERSI gerekiyor)
$PDFTOTEXT_TSV = ''
$adaylar = @(
  "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe"
)
foreach($c in @(Get-Command pdftotext -All -ErrorAction SilentlyContinue)){ $adaylar += $c.Source }
foreach($a in $adaylar){
  if(-not (Test-Path $a)){ continue }
  if((& $a -h 2>&1 | Out-String) -match '-tsv'){ $PDFTOTEXT_TSV = $a; break }
}
if($PDFTOTEXT_TSV -eq ''){ Write-Host 'HATA: -tsv destekleyen pdftotext yok (poppler gerekli)'; exit 1 }
Write-Host ("pdftotext (tsv): {0}" -f $PDFTOTEXT_TSV)

function Normal([string]$s){ return ($s -replace '[^\p{L}\p{Nd}]','').ToLowerInvariant() }

# Bir PDF'in TUM sayfalarindan "koordinatla kurtarilmis sik takimlari" cikarir.
# Donen: kok-metin-anahtari -> [ordered]@{A=..;B=..;..}
function SayfalardanSikTakimlari([string]$pdfYol){
  $sonuc = New-Object System.Collections.Generic.List[object]
  $tsv = Join-Path $env:TEMP ('bsk-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.tsv')
  try {
    & $PDFTOTEXT_TSV -tsv $pdfYol $tsv 2>&1 | Out-Null
    if(-not (Test-Path $tsv)){ return $sonuc }
    $satirlar = Get-Content $tsv -Encoding UTF8
    if($satirlar.Count -lt 2){ return $sonuc }
    # DUZ dizi + Group-Object. (Once "sayfa -> List" sozlugu kullanildi;
    # PS 5.1 o sozlukten deger okurken "Bagimsiz degisken turleri eslesmiyor"
    # ArgumentException'i atti. Duz dizi + gruplama ayni isi sorunsuz yapiyor.)
    $tumKelimeler = New-Object System.Collections.Generic.List[object]
    for($i=1; $i -lt $satirlar.Count; $i++){
      $p = $satirlar[$i] -split "`t"
      if($p.Count -lt 12){ continue }
      $metin = $p[11]
      if([string]::IsNullOrWhiteSpace($metin) -or $metin -like '###*'){ continue }
      $tumKelimeler.Add([pscustomobject]@{
        sayfa=[int]$p[1]; x=[double]$p[6]; y=[double]$p[7]; g=[double]$p[8]; metin=$metin
      })
    }
    foreach($grup in ($tumKelimeler | Group-Object sayfa)){
      $sy = $grup.Name
      $kelimeler = @($grup.Group)
      $isaretler = @($kelimeler | Where-Object { $_.metin -match '^[A-E]\)$' } | Sort-Object y)
      if($isaretler.Count -lt 4){ continue }
      # ayni X'te (ayni sutun) ve ardisik Y'de A..E gruplari bul
      $sutunlar = $isaretler | Group-Object { [math]::Round($_.x / 5) * 5 }
      foreach($sut in $sutunlar){
        $sirali = @($sut.Group | Sort-Object y)
        for($b=0; $b -lt $sirali.Count; $b++){
          if($sirali[$b].metin -ne 'A)'){ continue }
          # A) den itibaren ardisik B,C,D,(E) topla
          $takim = @($sirali[$b])
          $beklenen = @('B)','C)','D)','E)')
          $bi = 0
          for($j=$b+1; $j -lt $sirali.Count -and $bi -lt 4; $j++){
            if($sirali[$j].metin -eq $beklenen[$bi]){ $takim += $sirali[$j]; $bi++ } else { break }
          }
          if($takim.Count -lt 4){ continue }
          # her isaret icin AYNI Y'de ve SAGINDA kalan kelimeler
          $sikMetin = [ordered]@{}
          $eksik = $false
          foreach($t in $takim){
            $harf = $t.metin.Substring(0,1)
            $ayniSatir = @($kelimeler | Where-Object {
              [math]::Abs($_.y - $t.y) -le $Tolerans -and $_.x -gt ($t.x + $t.g - 1)
            } | Sort-Object x)
            # sutun siniri: bu satirdaki BIR SONRAKI sik sutununun X'i
            $sonrakiSutunX = 99999
            foreach($d2 in $isaretler){ if($d2.x -gt $t.x + 20 -and $d2.x -lt $sonrakiSutunX){ $sonrakiSutunX = $d2.x } }
            $ayniSatir = @($ayniSatir | Where-Object { $_.x -lt $sonrakiSutunX })
            $mt = (($ayniSatir | ForEach-Object { $_.metin }) -join ' ').Trim()
            if($mt.Length -eq 0){ $eksik = $true; break }
            $sikMetin[$harf] = $mt
          }
          if($eksik -or $sikMetin.Count -lt 4){ continue }
          # SORU NUMARASINI KOORDINATTAN BUL (metin eslestirmesinden cok daha
          # saglam - metin eslestirmesi denendi, 60 bos sikta 0 eslesme verdi).
          # Olcum (SGS 2011/3 s.3): numara sik isaretinden ~16pt SOLDA ve
          # takimin USTUNDE duruyor: "13." X=65.0 / "A)" X=81.8.
          $ustY = $takim[0].y
          $numAday = @($kelimeler | Where-Object {
            $_.metin -match '^\d{1,3}\.?$' -and
            $_.y -lt $ustY -and $_.y -gt ($ustY - 400) -and
            $_.x -lt $takim[0].x -and $_.x -gt ($takim[0].x - 40)
          } | Sort-Object { $ustY - $_.y })
          if($numAday.Count -eq 0){ continue }
          $soruNo = 0
          [void][int]::TryParse(($numAday[0].metin -replace '\.',''), [ref]$soruNo)
          if($soruNo -lt 1 -or $soruNo -gt 130){ continue }
          $sonuc.Add([pscustomobject]@{ sayfa=$sy; no=$soruNo; siklar=$sikMetin })
        }
      }
    }
  } finally { Remove-Item $tsv -Force -ErrorAction SilentlyContinue }
  return $sonuc
}

# --- ambardan bos sikli sorulari cek ---
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$hdr = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization=('Bearer '+$env:SUPABASE_SERVICE_KEY) }
$belgeler = Invoke-RestMethod -Uri ($AMBAR_URL + '?select=id,kaynak_ad,baslik,metin&tur=eq.cikmis-soru&limit=1000') -Headers $hdr -UserAgent 'mevzuat-radar-robot/1.0'
Write-Host ("Ambardaki cikmis-soru belgesi: {0}" -f @($belgeler).Count)

$pdfler = @(Get-ChildItem (Join-Path $Klasor $Desen) | Where-Object { $_.Extension -ieq '.pdf' } | Sort-Object Name)
Write-Host ("Taranacak PDF: {0}" -f $pdfler.Count)

$rapor = New-Object System.Collections.Generic.List[object]
$toplamOnarilan = 0; $yazilan = 0; $yazHata = 0
foreach($f in $pdfler){
  $ilgili = @($belgeler | Where-Object { $_.kaynak_ad -like ("*(" + $f.BaseName + ")") })
  if($ilgili.Count -eq 0){ continue }
  $belge = $ilgili[0]
  $metin = "$($belge.metin)"
  # bu belgede bos sik var mi?
  $bosSayisi = ([regex]::Matches($metin, '(?m)^\s+[A-E]\)\s*$')).Count
  if($bosSayisi -eq 0){ continue }

  $takimlar = SayfalardanSikTakimlari $f.FullName
  if($takimlar.Count -eq 0){
    $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; bosSik=$bosSayisi; onarilan=0; not='TSV-den takim cikmadi' })
    continue
  }
  # SORU NUMARASINA gore indeksle. Ayni numara birden fazla sayfada
  # gorunuyorsa (iki sutunlu dizgide olabilir) ILK bulunan tutulur;
  # cakisma varsa o numara HIC kullanilmaz - yanlis eslestirmektense atla.
  $indeks = @{}; $cakisan = @{}
  foreach($t in $takimlar){
    if($indeks.ContainsKey($t.no)){ $cakisan[$t.no] = $true } else { $indeks[$t.no] = $t }
  }
  foreach($c in @($cakisan.Keys)){ $indeks.Remove($c) }

  $yeniBloklar = New-Object System.Collections.Generic.List[string]
  $onarildi = 0
  foreach($b in [regex]::Split($metin, '(?m)^(?=SORU \d)')){
    if($b.Trim().Length -eq 0){ continue }
    $siklar = @([regex]::Matches($b, '(?m)^\s+([A-E])\)(.*)$'))
    $bos = 0
    foreach($s in $siklar){ if($s.Groups[2].Value.Trim().Length -eq 0){ $bos++ } }
    if($bos -eq 0 -or $siklar.Count -lt 4){ $yeniBloklar.Add($b.TrimEnd()); continue }

    $kokM = [regex]::Match($b, '(?m)^SORU (\d+):\s*(.*)$')
    if(-not $kokM.Success){ $yeniBloklar.Add($b.TrimEnd()); continue }
    $no = [int]$kokM.Groups[1].Value
    if(-not $indeks.ContainsKey($no)){ $yeniBloklar.Add($b.TrimEnd()); continue }
    $bulunan = $indeks[$no]

    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine("SORU " + $no + ": " + $kokM.Groups[2].Value.Trim())
    foreach($h in $bulunan.siklar.Keys){ [void]$sb.AppendLine("  " + $h + ") " + $bulunan.siklar[$h]) }
    $yeniBloklar.Add($sb.ToString().TrimEnd())
    $onarildi++
  }

  if($onarildi -eq 0){
    $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; bosSik=$bosSayisi; onarilan=0; not='eslesme bulunamadi' })
    continue
  }
  $toplamOnarilan += $onarildi
  $yeniMetin = ($yeniBloklar -join "`r`n`r`n") + "`r`n"
  $rapor.Add([pscustomobject]@{ dosya=$f.BaseName; bosSik=$bosSayisi; onarilan=$onarildi; not='' })
  Write-Host ("  {0,-42} bos={1,3} ONARILAN={2,3}" -f $f.BaseName,$bosSayisi,$onarildi)

  if($yaz){
    $govde = @{ metin = $yeniMetin } | ConvertTo-Json -Depth 3 -Compress
    $u = $AMBAR_URL + '?id=eq.' + $belge.id
    try {
      Invoke-RestMethod -Uri $u -Method Patch -Headers ($hdr + @{'Content-Type'='application/json'; 'Prefer'='return=minimal'}) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -UserAgent 'mevzuat-radar-robot/1.0' | Out-Null
      $yazilan++
    } catch { $yazHata++; if($yazHata -le 3){ Write-Host ('    YAZMA HATASI: ' + $_.Exception.Message) } }
  }
}

Write-Host ("`nTOPLAM ONARILAN SORU: {0}" -f $toplamOnarilan)
if($yaz){ Write-Host ("AMBARDA GUNCELLENEN BELGE: {0} | HATA: {1}" -f $yazilan,$yazHata) }
[IO.File]::WriteAllText((Join-Path $kok 'veri\bos-sik-onarim.json'),
  (ConvertTo-Json -InputObject ([ordered]@{
     tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
     aciklama='Bos sik onarimi - sik harfi ile metni AYNI Y koordinatinda eslestirilerek. Kismi sonuc yazilmaz.'
     toplamOnarilan=$toplamOnarilan; guncellenenBelge=$yazilan; kayitlar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host 'Rapor: veri/bos-sik-onarim.json'
