# ============================================================================
#  CIKMIS SINAV SORULARINI INDIR VE OLC - 08.08.2026
#
#  CEM DEFALARCA SORDU, YAPILMADI:
#    "eski sinav sorularini cikmis sorulari yukleyebiliyormuyuz"
#    "patron sinav sorulari yok anlamiyormusun beni sen sinav sorulari nerde"
#    "daha eski butun staja giris yeterlilik ve bagimsiz denetim sorularini
#     indirmedin ki nasil olcum yaptin - indir sonra bunlarin hepsini olc"
#
#  NE OLMUSTU: analiz dosyalari yalnizca KONU ETIKETI ve SAYI tutuyordu
#  ("Hukuk|sebepsiz zenginlesme = 1"). Sorularin METNI hicbir yerde yoktu.
#  Fabrika soru yazarken eline konu adi + kanun maddesi geciyordu; TEK BIR
#  GERCEK SINAV SORUSUNU HIC GORMEDI.
#
#  KAYNAK: veri/sinav-arsiv.json - 193 kitapcik (SGS 49 + SMMM 144), TESMER
#  resmi adresleri. sgs-analiz.json'daki aktifonline adresleri MUKERRER dosya
#  veriyordu (18 Nisan 2026 adli dosya 22 Kasim 2025 sinavini donduruyordu,
#  md5 ayni) - bu yuzden resmi kaynak esas alinir.
#
#  BEDAVA: indirme + pdftotext. API yok.
#  NOT: kaynak site GitHub runner'ini engelleyebilir; TR IP'li makinede kosar.
# ============================================================================
param([switch]$yaz, [int]$tavan = 0, [string]$sinav = '')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$tmp = Join-Path $env:TEMP 'cikmis-soru'
if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp | Out-Null }
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
if($null -eq $pdftotext){ Write-Host 'HATA: pdftotext yok (poppler)'; exit 1 }

$a = Get-Content (Join-Path $kok 'veri\sinav-arsiv.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($a.donemler) | Where-Object { "$($_.url)" -match '^https?://' }
if($sinav -ne ''){ $kayitlar = @($kayitlar | Where-Object { "$($_.sinav)" -eq $sinav }) }
Write-Host ("Adresi olan kitapcik: {0}" -f $kayitlar.Count)

$md5 = [Security.Cryptography.MD5]::Create()
$gorulen = @{}
$rapor = New-Object System.Collections.Generic.List[object]
$ok=0; $hata=0; $mukerrer=0; $atla=0; $i=0

foreach($k in $kayitlar){
  $i++
  if($tavan -gt 0 -and $i -gt $tavan){ break }
  $sv = "$($k.sinav)"; $don = "$($k.donem)"
  $ad = ($sv + '-' + ($don -replace '[^0-9A-Za-z]','_') + '-' + $i)
  $pdf = Join-Path $tmp ($ad + '.pdf')
  $txt = Join-Path $tmp ($ad + '.txt')
  if(Test-Path $txt){ $atla++; continue }          # daha once indirilmis
  try {
    Invoke-WebRequest -Uri "$($k.url)" -OutFile $pdf -UserAgent 'Mozilla/5.0' -TimeoutSec 90 -UseBasicParsing
  } catch {
    $hata++; $rapor.Add([pscustomobject]@{ sinav=$sv; donem=$don; durum='INDIRILEMEDI'; not="$($_.Exception.Message)" }); continue
  }
  $h = [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($pdf))).Replace('-','').ToLower()
  if($gorulen.ContainsKey($h)){
    $mukerrer++
    $rapor.Add([pscustomobject]@{ sinav=$sv; donem=$don; durum='MUKERRER'; not=('ayni dosya: ' + $gorulen[$h]) })
    Remove-Item $pdf -Force -ErrorAction SilentlyContinue
    continue
  }
  $gorulen[$h] = ($sv + ' ' + $don)
  # PS 5.1 TUZAGI: yerel program stderr'e YAZINCA (pdftotext "Syntax Warning"
  # basiyor) ErrorActionPreference='Stop' altinda NativeCommandError firlatiyor
  # ve tum kosuyu olduruyor - 193 kitapciklik hasat ilk uyarida durmustu.
  # Cozum: cagriyi kendi hata kapsamina al.
  $eskiEAP = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & pdftotext -enc UTF-8 -layout $pdf $txt 2>&1 | Out-Null } catch {}
  $ErrorActionPreference = $eskiEAP
  if(-not (Test-Path $txt)){ $hata++; $rapor.Add([pscustomobject]@{ sinav=$sv; donem=$don; durum='PDFTOTEXT-FAIL' }); continue }
  $boy = (Get-Item $txt).Length
  if($boy -lt 8000){ $hata++; $rapor.Add([pscustomobject]@{ sinav=$sv; donem=$don; durum='KISA'; not=("$boy bayt") }); continue }
  $ok++
  $rapor.Add([pscustomobject]@{ sinav=$sv; donem=$don; durum='OK'; not=("$boy bayt") })
  if($ok % 10 -eq 0){ Write-Host ("  ... {0} kitapcik indi" -f $ok) }
  Start-Sleep -Milliseconds 700
}
Write-Host ("`nOK {0} | MUKERRER {1} | HATA {2} | ATLANDI(zaten var) {3}" -f $ok,$mukerrer,$hata,$atla)
$grup = $rapor | Group-Object -Property sinav,durum | Sort-Object Name
Write-Host "`n--- SINAV x DURUM ---"
foreach($g in $grup){ Write-Host ("   {0,-28} {1}" -f $g.Name,$g.Count) }
$cikti = Join-Path $kok 'veri\cikmis-soru-hasat.json'
[IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ok=$ok; mukerrer=$mukerrer; hata=$hata; atlanan=$atla
  klasor=$tmp; kayitlar=$rapor.ToArray() }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
Write-Host ("`nRapor: veri/cikmis-soru-hasat.json   Metinler: {0}" -f $tmp)
