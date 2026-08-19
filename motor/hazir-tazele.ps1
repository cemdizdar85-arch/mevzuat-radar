# ============================================================================
#  HAZIR KAYNAK TAZELEYICI (19.08.2026)
#
#  NEDEN VAR: manifestte pdfId=HAZIR olan metinleri gunluk ayna INDIREMEZ
#  (kaynak mevzuat.gov.tr disinda: GIB portal HTML'i, ticaret.gov.tr PDF'i...).
#  Bunlar elle tazelenir. 19.08'de bu dort metin ambara yutuldu ama HAM METIN
#  scratchpad'de kaldi, veri\mevzuat-hazir\ altina KONMADI -> Nabiz Nobetcisi
#  gunlerce "HAZIR kaynak dosyasi YOK" alarmi verdi. Cekme tarifinin gecici
#  klasorde yasamasi arizanin kok nedeniydi; bu betik tarifi repoda tutar.
#
#  KURAL: yeni bir HAZIR kaynak yutuldugunda ham metni MUTLAKA
#  veri\mevzuat-hazir\<slug>.txt olarak yaz ve cekme tarifini buraya ekle.
#
#  KOSMA: powershell -File motor\hazir-tazele.ps1
#  Sonrasi: push -> mevzuat.yml (hazir yolu izleniyor) yeniden yutar.
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$hazirDir = Join-Path $kok 'veri\mevzuat-hazir'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

function Indir([string]$url, [string]$hedefDosya){
  # IRM/IWR kodlamayi bozuyor (bkz. dis-kaynak-cekme-tuzaklari) -> ham bayt.
  $wc = [System.Net.WebClient]::new(); $wc.Headers.Add('User-Agent', $UA)
  if($hedefDosya){ $wc.DownloadFile($url, $hedefDosya); return $null }
  return $wc.DownloadData($url)
}

function Yaz([string]$slug, [string]$metin){
  $yol = Join-Path $hazirDir "$slug.txt"
  [IO.File]::WriteAllText($yol, $metin, (New-Object Text.UTF8Encoding $true))
  "  yazildi: {0}.txt ({1:N0} karakter)" -f $slug, $metin.Length
}

# --- 1) GIB PORTAL BKK KONSOLIDELERI ---------------------------------------
# mevzuat.gov.tr Bakanlar Kurulu Karari metinlerini HIC tutmuyor (tur listesinde
# yok), RG karar PDF'leri taranmis goruntu (pdftotext bos, OCR yasak). Tek
# konsolide kaynak GIB mevzuat portali. API JSON doner, govde 'description'
# alaninda HTML'dir.
function HtmlMetne([string]$h){
  $h = $h -replace '(?is)<(script|style)[^>]*>.*?</\1>', ''
  $h = $h -replace '(?i)<br\s*/?>', "`n"
  $h = $h -replace '(?i)</(p|div|tr|h[1-6]|li)>', "`n"
  $h = $h -replace '(?i)</t[dh]>', ' '
  $h = $h -replace '<[^>]+>', ''
  $h = [System.Net.WebUtility]::HtmlDecode($h)
  $h = $h -replace "`r`n", "`n" -replace "`r", "`n"
  $h = $h -replace '[ \t ]+', ' '
  $h = ($h -split "`n" | ForEach-Object { $_.Trim() }) -join "`n"
  ($h -replace "`n{3,}", "`n`n").Trim()
}

$bkk = @(
  @{ slug='tevkifat14592'; id=1232; ad='GVK 94 Tevkifat Oranlari BKK (2009/14592)' },
  @{ slug='tevkifat14593'; id=1379; ad='KVK 30 Tevkifat Oranlari BKK (2009/14593)' },
  @{ slug='tevkifat14594'; id=1378; ad='KVK 15 Vergi Kesintisi Oranlari BKK (2009/14594)' }
)
foreach($b in $bkk){
  Write-Host ("GIB BKK: {0}" -f $b.ad)
  $bayt = Indir "https://www.gib.gov.tr/api/gibportal/mevzuat/bkk/findById?id=$($b.id)" $null
  $j = [Text.Encoding]::UTF8.GetString($bayt) | ConvertFrom-Json
  if($j.status -ne 200){ throw "$($b.slug): API status $($j.status)" }
  $rc = $j.resultContainer
  Yaz $b.slug ((HtmlMetne $rc.title) + "`n`n" + (HtmlMetne $rc.description)).Trim()
  Write-Host ("  kaynak damgasi: {0}" -f $rc.updated_at)
}

# --- 2) TICARET.GOV.TR FUAR GENELGESI --------------------------------------
# 19.08 TUZAK: dosya adi TURKCE HARFLI ("İlişkin"); ASCII'ye duzlestirilmis
# ad 500 doner ve HTML hata sayfasini PDF sanip indirir. Ad aynen korunmali.
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
if($null -eq $pdftotext){
  Write-Host "UYARI: pdftotext yok (poppler kurulu degil) - fuar-genelge atlandi"
} else {
  Write-Host "Ticaret Bakanligi: Fuar Desteklerine Iliskin Genelge"
  $tmp = Join-Path $env:TEMP 'hazir-tazele'
  if(-not (Test-Path $tmp)){ New-Item -ItemType Directory -Path $tmp | Out-Null }
  $pdf = Join-Path $tmp 'fuar-genelge.pdf'
  $ad = [Uri]::EscapeDataString('Fuar Desteklerine İlişkin Genelge.pdf')
  Indir "https://ticaret.gov.tr/data/5b868a8d13b87818a009d3b0/$ad" $pdf | Out-Null
  $ilk = [IO.File]::ReadAllBytes($pdf)[0..3]
  if(-join ([char[]]$ilk) -ne '%PDF'){ throw "fuar-genelge: PDF degil (hata sayfasi indi?) - dosya adini kontrol et" }
  $txt = Join-Path $tmp 'fuar-genelge.txt'
  if(Test-Path $txt){ Remove-Item $txt -Force }
  & pdftotext -enc UTF-8 $pdf $txt      # ayna ile AYNI bayraklar (yerel-indirici)
  Yaz 'fuar-genelge' ([IO.File]::ReadAllText($txt, [Text.Encoding]::UTF8))
}

Write-Host "`nBITTI. Simdi: git add veri/mevzuat-hazir && commit && push (ayna yeniden yutar)."
