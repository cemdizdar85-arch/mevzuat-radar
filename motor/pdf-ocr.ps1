# ============================================================================
#  PDF -> OCR METNI  - 23.08.2026
#
#  NEDEN: cikmis sinav arsivindeki bazi kitapciklar pdftotext ile OKUNAMIYOR.
#  Uc ayri hastalik olculdu (23.08):
#    * 8166 (11 Kasim 2018) - Xerox WorkCentre tarama, metin katmani HIC YOK
#      (pdftotext 34 bayt = 34 sayfa besleme karakteri).
#    * 6551 (15 Mayis 2016) - CorelDRAW cikisli goruntu PDF, 31 bayt.
#    * 6557_SABAH (16 Mart 2014) - metin katmani VAR (107 KB) ama gomulu font
#      esleme tablosu bozuk: "Adayin Adi ve Soyadi" -> "Adain Adi e Sadi".
#      p/c/y/v/g/u harfleri sistematik dusuyor. Hicbir metin cikarici duzeltemez.
#
#  COZUM: sayfayi goruntuye cevir (pdftoppm) + tesseract -l tur ile yeniden oku.
#  BEDAVA. API yok. Sonraki bozuk taramalar icin GENEL AMACLI yazildi.
#
#  KULLANIM:
#    .\pdf-ocr.ps1 -Pdf "veri\kgk-arsiv\pdf\8166_...pdf"
#    .\pdf-ocr.ps1 -Klasor "veri\kgk-arsiv\pdf" -Desen "6551_*"
#  Cikti: <ayni klasor>\<ad>.ocr.txt   (varsa atlanir; -Zorla ile ezilir)
# ============================================================================
param(
  [string]$Pdf = '',
  [string]$Klasor = '',
  [string]$Desen = '*.pdf',
  [int]$Dpi = 300,
  [string]$Dil = 'tur',
  [switch]$Zorla,
  [switch]$TekSutun
)
$ErrorActionPreference = 'Continue'

# --- araclari bul (PATH'te olmayabilir; winget kurulumu PATH'e yazmiyor) ---
function AracBul([string]$ad, [string[]]$adaylar){
  $c = Get-Command $ad -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  foreach($a in $adaylar){ if(Test-Path $a){ return $a } }
  return ''
}
$TESS = AracBul 'tesseract' @(
  'C:\Program Files\Tesseract-OCR\tesseract.exe',
  'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe'
)
$PPM = AracBul 'pdftoppm' @(
  "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftoppm.exe"
)
if($TESS -eq ''){ Write-Host 'HATA: tesseract bulunamadi (winget install UB-Mannheim.TesseractOCR)'; exit 1 }
if($PPM  -eq ''){ Write-Host 'HATA: pdftoppm bulunamadi (poppler)'; exit 1 }

# Turkce dil verisi var mi? Yoksa sessizce ingilizceye dusup cop uretir.
$tessdata = Join-Path (Split-Path -Parent $TESS) 'tessdata'
if($Dil -eq 'tur' -and -not (Test-Path (Join-Path $tessdata 'tur.traineddata'))){
  Write-Host 'HATA: tur.traineddata yok - Turkce OCR yapilamaz'; exit 1
}

# --- islenecek dosyalar ---
$hedefler = @()
if($Pdf -ne ''){ $hedefler = @(Get-Item -LiteralPath $Pdf) }
elseif($Klasor -ne ''){ $hedefler = @(Get-ChildItem -LiteralPath $Klasor -Filter $Desen | Where-Object { $_.Extension -ieq '.pdf' }) }
else { Write-Host 'HATA: -Pdf veya -Klasor ver'; exit 1 }
if($hedefler.Count -eq 0){ Write-Host 'Islenecek PDF yok'; exit 0 }
Write-Host ("OCR kuyrugu: {0} PDF  (dpi={1} dil={2})" -f $hedefler.Count, $Dpi, $Dil)

$ok = 0; $atlanan = 0; $hata = 0
foreach($h in $hedefler){
  $cikti = Join-Path $h.DirectoryName ($h.BaseName + '.ocr.txt')
  if((Test-Path -LiteralPath $cikti) -and -not $Zorla){
    if((Get-Item -LiteralPath $cikti).Length -gt 3000){ $atlanan++; continue }
  }
  $tmp = Join-Path $env:TEMP ('ocr-' + [guid]::NewGuid().ToString('N').Substring(0,8))
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  try {
    # --- 1) SAYFALARI GORUNTUYE CEVIR ---
    # ONEMLI OLCUM (23.08): sinav kitapciklari IKI SUTUN. Tam sayfayi --psm 1 ile
    # okutunca metin dogru siralaniyor AMA SORU NUMARALARI DUSUYOR:
    #     ". TMS-39'a gore..."   <- basindaki "2" yok
    # Numara kenar bosluguna tasan ayri bir blok oldugu icin duzen cozumleyici
    # onu atiyor. Ayni sayfada olculdu: psm 1 -> 1 numara, psm 4/6 -> 5 numara,
    # SUTUN KIRPMA + psm 6 -> numaralar tam ("20. Asagidakilerden hangisi...").
    # Ayristirici soruyu numarasindan tanidigi icin bu fark kitapcigi olduruyor.
    # Cozum: her sayfayi SOL ve SAG yarim olarak ayri render et, ayri oku.
    # Yarimlar 120 px ust uste biner (sutun ortasindaki soru numarasi kesilmesin);
    # ayristirici zaten numaraya gore tekillestiriyor.
    if($TekSutun){
      & $PPM -r $Dpi -gray -png -q $h.FullName (Join-Path $tmp 'tam') 2>&1 | Out-Null
      $kumeler = @(,@('tam', (Get-ChildItem -LiteralPath $tmp -Filter 'tam*.png' | Sort-Object Name)))
    } else {
      # A4 300 dpi = 2480 px genislik. Sol 0-1300, sag 1180-2580 (120 px bindirme).
      & $PPM -r $Dpi -gray -png -q -x 0    -W 1300 $h.FullName (Join-Path $tmp 'sol') 2>&1 | Out-Null
      & $PPM -r $Dpi -gray -png -q -x 1180 -W 1400 $h.FullName (Join-Path $tmp 'sag') 2>&1 | Out-Null
      $kumeler = @(
        ,@('sol', (Get-ChildItem -LiteralPath $tmp -Filter 'sol*.png' | Sort-Object Name))
        ,@('sag', (Get-ChildItem -LiteralPath $tmp -Filter 'sag*.png' | Sort-Object Name))
      )
    }
    $toplamSayfa = ($kumeler | ForEach-Object { @($_[1]).Count } | Measure-Object -Sum).Sum
    if($toplamSayfa -eq 0){ throw 'pdftoppm sayfa uretmedi' }

    # --- 2) HER PARCAYI OKU ---
    # psm 6 = "tek tip metin blogu": kirpilmis sutunda satir sirasini ve satir
    # basi numaralarini koruyor. Tam sayfada psm 4 kullanilir (tek sutun varsayimi).
    $psm = if($TekSutun){ '4' } else { '6' }
    $sb = New-Object Text.StringBuilder
    $n = 0
    foreach($kume in $kumeler){
      foreach($s in @($kume[1])){
        $n++
        $metin = & $TESS $s.FullName stdout -l $Dil --psm $psm 2>$null
        [void]$sb.AppendLine(($metin -join "`n"))
        [void]$sb.AppendLine("`f")
      }
    }
    [IO.File]::WriteAllText($cikti, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
    $boy = (Get-Item -LiteralPath $cikti).Length
    Write-Host ("  OK  {0}  {1} sayfa -> {2} bayt" -f $h.BaseName, $n, $boy)
    $ok++
  } catch {
    Write-Host ("  HATA {0} :: {1}" -f $h.BaseName, $_.Exception.Message)
    $hata++
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
Write-Host ("OZET: ok={0} atlanan={1} hata={2}" -f $ok, $atlanan, $hata)
