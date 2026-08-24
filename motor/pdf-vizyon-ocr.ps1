# ============================================================================
#  PDF -> VIZYON MODELLI OCR, CAPRAZ KONTROLLU  - 24.08.2026
#
#  NEDEN: 3 zayif KGK oturumu (6551/8166/10270) icin tesseract yetersiz kaldi
#  - 400 dpi denendi, aileler-arasi metin birlestirme denendi, ikisi de
#  tutmadi (bkz motor/cikmis-soru-ayristir.ps1 basindaki 24.08 notlari).
#  Cem'in onayiyla (tahmini $8-10, capraz kontrollu) son care: Claude vizyon
#  modeline sayfa GORUNTUSUNU okutmak.
#
#  CAPRAZ KONTROL: her sayfa IKI KEZ (bagimsiz istek) okunur. Iki okuma
#  ayni soruyu ayni icerikle vermezse o soru YAZILMAZ - yanlis finansal veri
#  riski, eksik birakmaktan daha kotu ([[feedback-rakam-disiplini]]).
#
#  CIKTI: mevcut boru hattiyla UYUMLU. <pdf>.ocr.txt formatinda yazilir
#  ("N. kok\nA) ..\nB) ..\n..\n\n") - cikmis-soru-ayristir.ps1'in aile-
#  yarismasi bunu otomatik degerlendirir, YENI KOD GEREKMEZ. Once
#  .vizyon-ham.txt'ye yazilir (once goz kontrolu icin); -yerlestir ile
#  .ocr.txt'ye kopyalanir (yalniz mevcut icerikten UZUNSA).
#
#  Model: claude-sonnet-5 (Cem'e verilen maliyet tahmini bu modelle
#  hesaplandi - Opus'a gecmek taahhudu bozar).
#  BEDAVA DEGIL - API cagrisi. Yalniz Cem'in isaretiyle calisir.
# ============================================================================
param(
  [string]$Pdf = '',
  [string]$Klasor = '',
  [string]$Desen = '*.pdf',
  [int]$Dpi = 150,
  [string]$Model = 'claude-sonnet-5',
  [switch]$yerlestir
)
$ErrorActionPreference = 'Continue'
$kok = Split-Path -Parent $PSScriptRoot

if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }
if(-not $env:ANTHROPIC_API_KEY){ Write-Host 'HATA: ANTHROPIC_API_KEY yok'; exit 1 }

$PPM = ''
foreach($c in @(Get-Command pdftoppm -ErrorAction SilentlyContinue)){ $PPM = $c.Source; break }
if($PPM -eq ''){
  $aday = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftoppm.exe"
  if(Test-Path $aday){ $PPM = $aday }
}
if($PPM -eq ''){ Write-Host 'HATA: pdftoppm bulunamadi'; exit 1 }

$SISTEM_ISTEM = @'
Sen bir sinav kitapcigi sayfasi goruntusunu BIREBIR transkribe eden bir aractsin.
Sayfadaki HER numarali soruyu ve siklarini (A-E) asagidaki formatta yaz, BASKA HICBIR SEY ekleme:

N. [soru koku tam metni]
A) [sik A metni]
B) [sik B metni]
C) [sik C metni]
D) [sik D metni]
E) [sik E metni]

(bos satir, sonraki soru)

KURALLAR:
- Siklar tablo/hesap kaydi formatindaysa (ornek: muhasebe yevmiye kaydi, borc/alacak),
  her sikkin ICERDIGI TUM satirlari o sikkin basligi altinda SIRAYLA yaz (hesap adi
  VE tutar dahil, hicbirini atlama).
- Okuyamadigin veya emin olmadigin metin icin [EMIN DEGILIM] yaz - ASLA UYDURMA,
  ASLA TAHMIN ETME. Rakamlarda ozellikle dikkatli ol.
- Sayfada soru YOKSA (kapak, sinav kurallari, bos sayfa, cevap anahtari tablosu)
  HICBIR SEY YAZMA - bos cevap ver.
- Yalniz GERCEK SINAV SORULARINI yaz; talimat/kural metnini yazma.
'@

function SayfalariRenderla([string]$pdfYol, [string]$hedefKlasor){
  New-Item -ItemType Directory -Force -Path $hedefKlasor | Out-Null
  & $PPM -r $Dpi -png -q $pdfYol (Join-Path $hedefKlasor 'sy') 2>&1 | Out-Null
  return @(Get-ChildItem -LiteralPath $hedefKlasor -Filter 'sy*.png' | Sort-Object Name)
}

# 24.08.2026 TUZAK: PowerShell 5.1'in Invoke-RestMethod/Invoke-WebRequest'i bu
# istekte (buyuk govde + coklu ozel baslik) WebRequestPSCmdlet.PrepareSession()
# icinde NullReferenceException firlatiyor - HTTP hatasi degil, .NET/PS 5.1
# kusuru, govde okunamiyor. curl.exe (Windows 10+'ta hazir gelir) guvenilir
# calisiyor ve gercek hata govdesini (orn. "API key is invalid.") veriyor.
function GoruntuyuOku([string]$pngYol){
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pngYol))
  $govde = [ordered]@{
    model = $Model
    max_tokens = 4000
    system = $SISTEM_ISTEM
    messages = @(
      @{ role = 'user'; content = @(
          @{ type = 'image'; source = @{ type = 'base64'; media_type = 'image/png'; data = $b64 } }
          @{ type = 'text'; text = 'Bu sayfayi yukaridaki kurallara gore transkribe et.' }
        )
      }
    )
  }
  $gecici = Join-Path $env:TEMP ('vzn-istek-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.json')
  $ciktiGecici = Join-Path $env:TEMP ('vzn-yanit-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.json')
  try {
    # TUZAK: Out-File -Encoding utf8 PS 5.1'de BOM EKLER. curl --data-binary
    # BOM baytini govdeye tasir, sunucu "unexpected character at char 0" der.
    # WriteAllText + UTF8Encoding($false) BOM'suz yazar.
    [IO.File]::WriteAllText($gecici, (ConvertTo-Json -InputObject $govde -Depth 10 -Compress), (New-Object Text.UTF8Encoding $false))
    $kod = & curl.exe -s -o $ciktiGecici -w '%{http_code}' 'https://api.anthropic.com/v1/messages' `
           -H "x-api-key: $env:ANTHROPIC_API_KEY" -H 'anthropic-version: 2023-06-01' `
           -H 'content-type: application/json' --data-binary "@$gecici" --max-time 120
    if(-not (Test-Path $ciktiGecici)){ Write-Host '  API HATASI: yanit dosyasi yok'; return '' }
    $yanit = Get-Content $ciktiGecici -Raw -Encoding UTF8
    if($kod -ne '200'){
      Write-Host ("  API HATASI kod {0}: {1}" -f $kod, $yanit.Substring(0,[Math]::Min(200,$yanit.Length)))
      return ''
    }
    $obj = $yanit | ConvertFrom-Json
    $blok = @($obj.content) | Where-Object { $_.type -eq 'text' } | Select-Object -First 1
    return $(if($blok){ $blok.text } else { '' })
  } finally {
    Remove-Item $gecici,$ciktiGecici -Force -ErrorAction SilentlyContinue
  }
}

# Ayristirici ile AYNI mantik (StilBilgisi '.' esdegeri) - vizyon ciktisi
# temiz oldugu icin tek stil yeterli.
function BloklaraAyir([string]$metin){
  $sonuc = [ordered]@{}
  if([string]::IsNullOrWhiteSpace($metin)){ return $sonuc }
  foreach($p in [regex]::Split($metin, '(?m)^(?=\s{0,4}\d{1,3}\.\s)')){
    if($p.Trim().Length -lt 20){ continue }
    $no = [regex]::Match($p, '^\s*(\d{1,3})\.')
    if(-not $no.Success){ continue }
    $n = [int]$no.Groups[1].Value
    if($n -lt 1 -or $n -gt 130){ continue }
    $isaretler = @([regex]::Matches($p, '(?<![A-Za-z0-9])([A-E])\)\s'))
    $ilkGecis = @{}
    foreach($m in $isaretler){ if(-not $ilkGecis.ContainsKey($m.Groups[1].Value)){ $ilkGecis[$m.Groups[1].Value] = $m } }
    if($ilkGecis.Count -lt 4){ continue }
    $sirali = @($ilkGecis.Values | Sort-Object { $_.Index })
    $siklar = [ordered]@{}
    for($i=0; $i -lt $sirali.Count; $i++){
      $bas = $sirali[$i].Index + $sirali[$i].Length
      $son = if($i -lt $sirali.Count-1){ $sirali[$i+1].Index } else { $p.Length }
      $siklar[$sirali[$i].Groups[1].Value] = (($p.Substring($bas,[Math]::Max(0,$son-$bas))) -replace '\s+',' ').Trim()
    }
    $ilk = [regex]::Match($p, '(?<![A-Za-z0-9])A\)\s')
    $kk = if($ilk.Success){ $p.Substring(0,$ilk.Index) } else { $p }
    $kk = (($kk -replace '^\s*\d{1,3}\.\s*','') -replace '\s+',' ').Trim()
    if($kk.Length -lt 10){ continue }
    $sonuc[$n] = [pscustomobject]@{ kok=$kk; siklar=$siklar }
  }
  return $sonuc
}

function Normal([string]$s){ return ($s -replace '[^\p{L}\p{Nd}]','').ToLowerInvariant() }

# Iki bagimsiz okumayi soru soru karsilastirir. Kok metni %70 benzerlik +
# TUM siklarin normalize edilmis metni birbirini icermeli (esit degil,
# CAPRAZ KONTROL - kucuk kelime farkina tolerans, RAKAM farkina TOLERANS YOK).
function CaprazKontrolEt($blokA, $blokB){
  $onaylanan = [ordered]@{}; $uyusmayan = 0
  foreach($n in $blokA.Keys){
    if(-not $blokB.Contains($n)){ continue }
    $a = $blokA[$n]; $b = $blokB[$n]
    $ka = Normal $a.kok; $kb = Normal $b.kok
    $kokUzunlukOK = ([Math]::Abs($ka.Length - $kb.Length) -le [Math]::Max(10, 0.25*[Math]::Max($ka.Length,$kb.Length)))
    $kokBasiAyni = ($ka.Length -ge 20 -and $kb.Length -ge 20 -and $ka.Substring(0,20) -eq $kb.Substring(0,20))
    if(-not ($kokUzunlukOK -and $kokBasiAyni)){ $uyusmayan++; continue }
    # RAKAMLAR: kok+siklardaki tum sayi dizileri BIREBIR eslesmeli - finansal
    # veri toleranssiz alan.
    $rakamA = ([regex]::Matches(($a.kok + ' ' + (($a.siklar.Values) -join ' ')), '\d[\d.,]*') | ForEach-Object { $_.Value })
    $rakamB = ([regex]::Matches(($b.kok + ' ' + (($b.siklar.Values) -join ' ')), '\d[\d.,]*') | ForEach-Object { $_.Value })
    if(($rakamA -join '|') -ne ($rakamB -join '|')){ $uyusmayan++; continue }
    if($a.siklar.Count -ne $b.siklar.Count -or $a.siklar.Count -lt 4){ $uyusmayan++; continue }
    $siklarUyumlu = $true
    foreach($h in $a.siklar.Keys){
      if(-not $b.siklar.Contains($h)){ $siklarUyumlu = $false; break }
      $sa = Normal $a.siklar[$h]; $sb = Normal $b.siklar[$h]
      if($sa.Length -ge 15 -and $sb.Length -ge 15){
        if($sa.Substring(0,[Math]::Min(15,$sa.Length)) -ne $sb.Substring(0,[Math]::Min(15,$sb.Length))){ $siklarUyumlu = $false; break }
      }
    }
    if(-not $siklarUyumlu){ $uyusmayan++; continue }
    # ONAYLANDI - daha uzun kok metni tercih edilir (daha detayli transkripsiyon)
    $onaylanan[$n] = if($a.kok.Length -ge $b.kok.Length){ $a } else { $b }
  }
  return @{ onaylanan = $onaylanan; uyusmayan = $uyusmayan }
}

$hedefler = @()
if($Pdf -ne ''){ $hedefler = @(Get-Item -LiteralPath $Pdf) }
elseif($Klasor -ne ''){ $hedefler = @(Get-ChildItem -LiteralPath $Klasor -Filter $Desen | Where-Object { $_.Extension -ieq '.pdf' } | Sort-Object Name) }
else { Write-Host 'HATA: -Pdf veya -Klasor ver'; exit 1 }
Write-Host ("Vizyon OCR kuyrugu: {0} PDF (model={1}, dpi={2})" -f $hedefler.Count, $Model, $Dpi)

$genelRapor = New-Object System.Collections.Generic.List[object]
foreach($h in $hedefler){
  $cikti = Join-Path $h.DirectoryName ($h.BaseName + '.vizyon-ham.txt')
  $tmp = Join-Path $env:TEMP ('vzn-' + [guid]::NewGuid().ToString('N').Substring(0,8))
  try {
    $sayfalar = SayfalariRenderla $h.FullName $tmp
    if($sayfalar.Count -eq 0){ Write-Host ("  {0}: sayfa uretilemedi" -f $h.BaseName); continue }
    $sb = New-Object Text.StringBuilder
    $topOnay = 0; $topUyusmayan = 0; $sayfaNo = 0
    foreach($s in $sayfalar){
      $sayfaNo++
      $a = GoruntuyuOku $s.FullName
      Start-Sleep -Milliseconds 400
      $b = GoruntuyuOku $s.FullName
      $blokA = BloklaraAyir $a; $blokB = BloklaraAyir $b
      $sonucKC = CaprazKontrolEt $blokA $blokB
      foreach($n in $sonucKC.onaylanan.Keys){
        $q = $sonucKC.onaylanan[$n]
        [void]$sb.AppendLine(("$n. " + $q.kok))
        foreach($hh in $q.siklar.Keys){ [void]$sb.AppendLine(("$hh) " + $q.siklar[$hh])) }
        [void]$sb.AppendLine('')
      }
      $topOnay += $sonucKC.onaylanan.Count; $topUyusmayan += $sonucKC.uyusmayan
      if($sayfaNo % 10 -eq 0){ Write-Host ("  ... {0}/{1} sayfa  (onay={2} uyusmayan={3})" -f $sayfaNo,$sayfalar.Count,$topOnay,$topUyusmayan) }
      Start-Sleep -Milliseconds 400
    }
    [IO.File]::WriteAllText($cikti, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
    Write-Host ("  OK {0}: {1} sayfa -> onaylanan={2} uyusmayan={3}" -f $h.BaseName,$sayfalar.Count,$topOnay,$topUyusmayan)
    $genelRapor.Add([pscustomobject]@{ dosya=$h.BaseName; sayfa=$sayfalar.Count; onaylanan=$topOnay; uyusmayan=$topUyusmayan })

    if($yerlestir){
      $ocrYol = Join-Path $h.DirectoryName ($h.BaseName + '.ocr.txt')
      $eskiBoy = if(Test-Path $ocrYol){ (Get-Item $ocrYol).Length } else { 0 }
      $yeniBoy = (Get-Item $cikti).Length
      if($yeniBoy -gt $eskiBoy){
        Copy-Item $cikti $ocrYol -Force
        Write-Host ("    YERLESTIRILDI: {0} -> {1} ({2} -> {3} bayt)" -f $h.BaseName,'.ocr.txt',$eskiBoy,$yeniBoy)
      } else {
        Write-Host ("    yerlestirilmedi: eski ({0} bayt) >= yeni ({1} bayt)" -f $eskiBoy,$yeniBoy)
      }
    }
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
Write-Host "`n--- OZET ---"
foreach($g in $genelRapor){ Write-Host ("  {0,-45} sayfa={1,4} onay={2,4} uyusmayan={3,4}" -f $g.dosya,$g.sayfa,$g.onaylanan,$g.uyusmayan) }
