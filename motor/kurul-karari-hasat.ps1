# ============================================================================
#  KURUL KARARI HASATCISI - 24.08.2026 (Cem: "kurul karari hasatcisini yaz")
#
#  NEDEN VAR: mevzuat.gov.tr fihristi KURUL KARARLARINI TUTMUYOR. 24.08 olcumu:
#    * MevzuatTur='KurulKarari'  -> HTTP 600 (tur adi reddediliyor)
#    * MevzuatTur=''  (hepsi)    -> HTTP 600 (bos tur da reddediliyor)
#    * sayisal 10/11/12/13       -> 0 kayit
#  Oysa KGK'nin TSRS uygulama kapsami karari, SPK'nin surdurulebilirlik ilkeleri
#  cercevesi ve yesil rehberi KGK sinavinin dogrudan konusu. Bu metinler yalniz
#  RESMI GAZETE fihristinde ve kurumun kendi sitesinde yasiyor.
#  Somut zarar: TSRS esik degerleri 13/01/2026 Kurul Karariyla degisti
#  (500 Mn / 1 Mr / 250 kisi  ->  1 Mr / 2 Mr / 500 kisi); nobetci olmadigi icin
#  bunu ancak elle arama yaparken gorduk. Ambarda eski rakam kalsaydi soru
#  yanlis ogretecekti (bkz. SGK 5 puan dersi).
#
#  NE YAPAR: son N gunun RG fihristini tarar, IZLENEN KURUMLARIN kararlarini
#  ayiklar, daha once gorulmemis olanlari raporlar. LLM YOK, PARA YOK.
#  Yutmayi KENDILIGINDEN YAPMAZ: kurul kararlari cogu zaman TARANMIS PDF olur
#  (metin katmani yok) ve kurumun sitesindeki dijital surumu tercih edilir -
#  bu karar insana birakilir. Robot yalniz "sunlar cikti" der.
#
#  KOSMA:  powershell -File motor\kurul-karari-hasat.ps1 [-Gun 30] [-Yaz]
#    -Yaz  : gorulenler defterini gunceller (ilk kosuda -Yaz VERME, once bak)
#  Cikti : veri/kurul-karari-raporu.json + motor/hafiza/kurul-karari-gorulen.json
# ============================================================================
param([int]$Gun = 30, [switch]$Yaz, [string]$Baslangic = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$UA = 'Mozilla/5.0 (MevzuatRadar-KurulKarariNobetcisi)'
$raporYol  = Join-Path $kok 'veri/kurul-karari-raporu.json'
$defterYol = Join-Path $kok 'motor/hafiza/kurul-karari-gorulen.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# Izlenen kurumlar: baslikta gecen imza + hangi derse besleme yaptigi.
$KURUMLAR = @(
  @{ ad='KGK';   imza=@('kamu gozetimi');                          ders='Surdurulebilirlik / Muhasebe-Denetim Standartlari' },
  @{ ad='SPK';   imza=@('sermaye piyasasi kurul');                 ders='Sermaye Piyasasi Mevzuati' },
  @{ ad='BDDK';  imza=@('bankacilik duzenleme');                   ders='Bankacilik Mevzuati' },
  @{ ad='SEDDK'; imza=@('sigortacilik ve ozel emeklilik duzenleme');ders='Sigortacilik ve Ozel Emeklilik Mevzuati' },
  @{ ad='TCMB';  imza=@('turkiye cumhuriyet merkez bankasi');      ders='Bankacilik Mevzuati' }
)
# Teblig ve yonetmelikler ZATEN gunluk aynada (manifest) var; bu nobetci
# yalniz aynanin GORMEDIGI turu - kararlari - kovalar.
$KARAR_IMZA = @('karari','kararlari','ilke karari','kurul karari')

function Norm([string]$s){
  if($null -eq $s){ return '' }
  $s = $s.Replace([string][char]0x0130,'i').Replace([string][char]0x0131,'i')
  $s = $s.ToLowerInvariant()
  return ($s -replace 'ç','c' -replace 'ğ','g' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u')
}

$defter = @{}
if(Test-Path $defterYol){
  try { (Get-Content $defterYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $defter[$_.Name] = $_.Value } } catch {}
}
Write-Host ("defter: {0} kayit | taranacak gun: {1}" -f $defter.Count, $Gun)

$tz = $null
foreach($id in @('Europe/Istanbul','Turkey Standard Time')){ try { $tz = [TimeZoneInfo]::FindSystemTimeZoneById($id); break } catch {} }
$bugun = if($tz){ [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz) } else { Get-Date }
if($Baslangic -ne ''){ $bugun = [datetime]::ParseExact($Baslangic,'dd.MM.yyyy',$null) }

$yeni = New-Object System.Collections.Generic.List[object]
$taranan = 0; $sayfaYok = 0
$rx = [regex]'(?is)<a[^>]+href="(?<u>[^"]*eskiler/\d{4}/\d{2}/\d{8}[^"]*\.(?:htm|pdf))"[^>]*>(?<t>.*?)</a>'

for($i = 0; $i -lt $Gun; $i++){
  $g = $bugun.AddDays(-$i)
  # -Baslangic gg.aa.yyyy verilirse tarama o gunden GERIYE gider (deneme/kanit icin)
  $tarih = $g.ToString('dd.MM.yyyy')
  $html = $null
  # RG her gun cikmaz; sayfa yoksa 404 doner ve bu HATA DEGILDIR.
  # KODLAMA TUZAGI (24.08 olculdu, bkz. dis-kaynak-cekme-tuzaklari): IWR.Content
  # sayfayi Latin-1 gibi cozuyor -> "Kamu Gozetimi" -> "Kamu GÃ¶zetimi" olup
  # kurum imzasi TUTMUYORDU (ilk kosuda 0 karar bulundu, oysa sayfada vardi).
  # Ham bayt alinip UTF-8 olarak cozulur (teblig-hasat.ps1 ile ayni desen).
  try {
    $resp = Invoke-WebRequest -Uri "https://www.resmigazete.gov.tr/$tarih" -UserAgent $UA -TimeoutSec 45 -UseBasicParsing
    $html = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
  }
  catch { $sayfaYok++; Start-Sleep -Milliseconds 400; continue }
  $taranan++
  foreach($m in $rx.Matches($html)){
    $u = $m.Groups['u'].Value
    if($u -notmatch '^https?:'){ $u = 'https://www.resmigazete.gov.tr' + $(if($u.StartsWith('/')){''}else{'/'}) + $u }
    $t = ($m.Groups['t'].Value -replace '<[^>]+>',' ' -replace '\s+',' ').Trim()
    $t = [System.Net.WebUtility]::HtmlDecode($t).TrimStart([char]0x2013,[char]0x2014,[char]0x2015,'-',' ')
    if($t.Length -lt 20){ continue }
    $n = Norm $t
    $kararMi = $false
    foreach($ki in $KARAR_IMZA){ if($n.Contains($ki)){ $kararMi = $true; break } }
    if(-not $kararMi){ continue }
    $kurum = $null
    foreach($k in $KURUMLAR){
      foreach($im in $k.imza){ if($n.Contains((Norm $im))){ $kurum = $k; break } }
      if($kurum){ break }
    }
    if(-not $kurum){ continue }
    if($defter.ContainsKey($u)){ continue }
    $bicim = if($u.EndsWith('.pdf')){ 'PDF (taranmis olabilir - metin katmani kontrol edilmeli)' } else { 'HTM (metin hazir)' }
    $yeni.Add([pscustomobject]@{ kurum=$kurum.ad; ders=$kurum.ders; rg_tarih=$tarih; baslik=$t; url=$u; bicim=$bicim })
    $defter[$u] = [ordered]@{ tarih=$tarih; kurum=$kurum.ad; baslik=$t; gorulme=(Get-Date -Format 'dd.MM.yyyy') }
  }
  Start-Sleep -Milliseconds 700
}

Write-Host ("taranan gun: {0} | sayfasi olmayan gun: {1} | YENI karar: {2}" -f $taranan, $sayfaYok, $yeni.Count)
foreach($y in $yeni){
  $kisa = $y.baslik.Substring(0, [Math]::Min(90, $y.baslik.Length))
  Write-Host ("  + [{0}] {1} - {2}" -f $y.kurum, $y.rg_tarih, $kisa)
}

if($Yaz){
  $klasor = Split-Path -Parent $defterYol
  if(-not (Test-Path $klasor)){ New-Item -ItemType Directory -Path $klasor -Force | Out-Null }
  [IO.File]::WriteAllText($defterYol, (ConvertTo-Json -InputObject $defter -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host 'defter guncellendi.'
} else {
  Write-Host 'OLCUM modu - defter yazilmadi (-Yaz ile yaz).'
}

# PS 5.1 TUZAGI (24.08 olculdu): [ordered]@{...} literalinin icine BOS bir
# generic List'i @(...) ile koymak ArgumentException firlatiyor
# ("Bagimsiz degisken turleri eslesmiyor") - rapor hic yazilamiyordu.
# Cozum: listeyi literale koymadan ONCE .ToArray() ile duz diziye cevir.
$kararlar = $yeni.ToArray()
$mod = 'OLCUM'
if($Yaz){ $mod = 'YAZ' }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'
  mod=$mod
  taranan_gun=$taranan; sayfasiz_gun=$sayfaYok; defter_kayit=$defter.Count; yeni=$yeni.Count
  kararlar=$kararlar
  not='Kurul kararlari mevzuat.gov.tr fihristinde YOK; kaynak RG fihristi. Yutma ELLE: metni tercihen kurumun kendi sitesinden (dijital PDF/DOCX) al, veri/mevzuat-hazir/<slug>.txt yaz, manifeste pdfId=HAZIR ile ekle, SADECE=<slug> ile motor/mevzuat-yut.ps1 kos.'
})
Write-Host 'KURUL KARARI HASADI TAMAM.'
