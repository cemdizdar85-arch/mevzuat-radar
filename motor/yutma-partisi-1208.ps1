# ============================================================================
#  YUTMA PARTISI 12.08 - cikmis-sinav talebine gore ince ambar kapatma
#
#  NEDEN: Cem 12.08 - "yutulacak baska birsey olmadigina sinavda cikmis
#  sorulara gore bak emin olalim". Olculdu: 8.409 cikmis soru metninden
#  standart atiflari cikarildi, ambar arziyla caprazlandi. 30 standart ya
#  P2 uretim listesinde ya da cikmislarda >=5 atifli oldugu halde ambarda
#  ozet duzeyinde (<=15 parca). Bu betik: indir -> pdftotext -> standart-yut
#  tanimi uret. Yazma karari yine standart-yut kuru kosu kapisindan gecer.
# ============================================================================
$ErrorActionPreference = 'Stop'
$dizin = Join-Path $env:TEMP 'standart-yut'
if(-not (Test-Path $dizin)){ New-Item -ItemType Directory -Force $dizin | Out-Null }

$MAVI = 'https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/'
$TDS  = 'https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/'

$liste = @(
  @{ ad='TMS-10';  k='TMS 10';  b='Raporlama Doneminden Sonraki Olaylar';                u=($MAVI+'TMS%2010.pdf');  tur='TMS' }
  @{ ad='TMS-12';  k='TMS 12';  b='Gelir Vergileri';                                     u=($MAVI+'TMS%2012.pdf');  tur='TMS' }
  @{ ad='TMS-19';  k='TMS 19';  b='Calisanlara Saglanan Faydalar';                       u=($MAVI+'TMS%2019.pdf');  tur='TMS' }
  @{ ad='TMS-20';  k='TMS 20';  b='Devlet Tesviklerinin Muhasebelestirilmesi';           u=($MAVI+'TMS%2020.pdf');  tur='TMS' }
  @{ ad='TMS-23';  k='TMS 23';  b='Borclanma Maliyetleri';                               u=($MAVI+'TMS%2023.pdf');  tur='TMS' }
  @{ ad='TMS-24';  k='TMS 24';  b='Iliskili Taraf Aciklamalari';                         u=($MAVI+'TMS%2024.pdf');  tur='TMS' }
  @{ ad='TMS-28';  k='TMS 28';  b='Istiraklerdeki ve Is Ortakliklarindaki Yatirimlar';   u=($MAVI+'TMS%2028.pdf');  tur='TMS' }
  @{ ad='TMS-29';  k='TMS 29';  b='Yuksek Enflasyonlu Ekonomilerde Finansal Raporlama';  u=($MAVI+'TMS%2029.pdf');  tur='TMS' }
  @{ ad='TMS-32';  k='TMS 32';  b='Finansal Araclar: Sunum';                             u=($MAVI+'TMS%2032.pdf');  tur='TMS' }
  @{ ad='TMS-33';  k='TMS 33';  b='Hisse Basina Kazanc';                                 u=($MAVI+'TMS%2033.pdf');  tur='TMS' }
  @{ ad='TMS-34';  k='TMS 34';  b='Ara Donem Finansal Raporlama';                        u=($MAVI+'TMS%2034.pdf');  tur='TMS' }
  @{ ad='TMS-36';  k='TMS 36';  b='Varliklarda Deger Dusuklugu';                         u=($MAVI+'TMS%2036.pdf');  tur='TMS' }
  @{ ad='TMS-38';  k='TMS 38';  b='Maddi Olmayan Duran Varliklar';                       u=($MAVI+'TMS%2038.pdf');  tur='TMS' }
  @{ ad='TMS-40';  k='TMS 40';  b='Yatirim Amacli Gayrimenkuller';                       u=($MAVI+'TMS%2040.pdf');  tur='TMS' }
  @{ ad='TFRS-2';  k='TFRS 2';  b='Hisse Bazli Odemeler';                                u=($MAVI+'TFRS%202.pdf');  tur='TMS' }
  @{ ad='TFRS-3';  k='TFRS 3';  b='Isletme Birlesmeleri';                                u=($MAVI+'TFRS%203.pdf');  tur='TMS' }
  @{ ad='TFRS-5';  k='TFRS 5';  b='Satis Amacli Elde Tutulan Duran Varliklar';           u=($MAVI+'TFRS%205.pdf');  tur='TMS' }
  @{ ad='TFRS-7';  k='TFRS 7';  b='Finansal Araclar: Aciklamalar';                       u=($MAVI+'TFRS%207.pdf');  tur='TMS' }
  @{ ad='TFRS-8';  k='TFRS 8';  b='Faaliyet Bolumleri';                                  u=($MAVI+'TFRS%208.pdf');  tur='TMS' }
  @{ ad='TFRS-10'; k='TFRS 10'; b='Konsolide Finansal Tablolar';                         u=($MAVI+'TFRS%2010.pdf'); tur='TMS' }
  @{ ad='TFRS-11'; k='TFRS 11'; b='Musterek Anlasmalar';                                 u=($MAVI+'TFRS%2011.pdf'); tur='TMS' }
  @{ ad='TFRS-13'; k='TFRS 13'; b='Gercege Uygun Deger Olcumu';                          u=($MAVI+'TFRS%2013.pdf'); tur='TMS' }
  @{ ad='BDS-210'; k='BDS 210'; b='Bagimsiz Denetim Sozlesmesinin Sartlari';             u=($TDS+'BDS%20210_2025.pdf'); tur='BDS' }
  @{ ad='BDS-501'; k='BDS 501'; b='Denetim Kanitlari - Belirli Kalemler';                u=($TDS+'BDS%20501_2025.pdf'); tur='BDS' }
  @{ ad='BDS-520'; k='BDS 520'; b='Analitik Prosedurler';                                u=($TDS+'BDS%20520_2025.pdf'); tur='BDS' }
  @{ ad='BDS-550'; k='BDS 550'; b='Iliskili Taraflar';                                   u=($TDS+'BDS%20550_2025.pdf'); tur='BDS' }
  @{ ad='BDS-701'; k='BDS 701'; b='Kilit Denetim Konularinin Bildirilmesi';              u=($TDS+'BDS%20701_2025.pdf'); tur='BDS' }
  @{ ad='BDS-706'; k='BDS 706'; b='Dikkat Cekilen Hususlar Paragraflari';                u=($TDS+'BDS%20706_2025.pdf'); tur='BDS' }
  @{ ad='GDS-3400';k='GDS 3400';b='Ileriye Yonelik Finansal Bilgilerin Incelenmesi';     u=($TDS+'GDS%203400_2025.pdf'); tur='BDS' }
  @{ ad='GDS-3420';k='GDS 3420';b='Proforma Finansal Bilgilerin Derlenmesi';             u=($TDS+'GDS%203420_2025.pdf'); tur='BDS' }
)

$tamam = 0; $hata = 0
$tanimlar = New-Object System.Text.StringBuilder
foreach($x in $liste){
  $pdf = Join-Path $dizin ($x.ad + '.pdf')
  $txt = Join-Path $dizin ($x.ad + '.txt')
  try{
    Invoke-WebRequest -UseBasicParsing -Uri $x.u -OutFile $pdf -TimeoutSec 180 -UserAgent 'Mozilla/5.0'
    $bas = [IO.File]::ReadAllBytes($pdf)[0..4]
    if([Text.Encoding]::ASCII.GetString($bas) -ne '%PDF-'){ throw 'PDF imzasi yok (HTML hata sayfasi olabilir)' }
    & pdftotext -layout -enc UTF-8 $pdf $txt
    $krk = (Get-Content $txt -Raw -Encoding UTF8).Length
    if($krk -lt 5000){ throw "metin cok kisa: $krk krk" }
    Write-Output ("{0,-9} {1,9:N0} bayt -> {2,7:N0} krk  TAMAM" -f $x.ad, (Get-Item $pdf).Length, $krk)
    $tamam++
    if($x.tur -eq 'TMS'){
      $bolucu = '(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; $no = '^\s{0,4}(\d{1,3})\s{2,}'
    } else {
      $bolucu = '(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; $no = '^\s{0,6}(A?\d{1,4})\.'
    }
    [void]$tanimlar.AppendLine(" @{ ad='" + $x.ad + "'; kisaAd='" + $x.k + "'; baslik='" + $x.b + "'")
    [void]$tanimlar.AppendLine("    url='" + $x.u + "'")
    [void]$tanimlar.AppendLine("    bolucu='" + $bolucu + "'; noDesen='" + $no + "' }")
  }catch{
    Write-Output ("{0,-9} HATA: {1}" -f $x.ad, $_.Exception.Message)
    $hata++
  }
}
Write-Output ""
Write-Output ("indirilen+cikarilan: {0} | hata: {1}" -f $tamam, $hata)
[IO.File]::WriteAllText((Join-Path $dizin 'yeni-tanimlar.ps1parcasi'), $tanimlar.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Output ("tanim blogu: " + (Join-Path $dizin 'yeni-tanimlar.ps1parcasi'))
