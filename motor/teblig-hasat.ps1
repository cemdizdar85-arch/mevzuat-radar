# ============================================================================
#  TEBLIG HASAT ROBOTU (02.08.2026 — Cem: "o hasat robotunu yaz")
#
#  SORUN: Kanunlar manifeste elle yazildi ve yetti (119 kanun). Ama TEBLIGLER
#  oyle degil: VUK'un tek basina yuzlerce Genel Tebligi var, her birinin
#  mevzuat.gov.tr'de AYRI ve tahmin edilemeyen bir MevzuatNo'su var. Numaradan
#  teblig sirasina giden bir dizin yok - tek tek denemek saatler surer ve
#  eksik birakir. Hakem "yetersiz" dedigi VUK sorularinin bir kismi tam da bu
#  bosluktan: amortisman orani, yeniden degerleme orani, enflasyon duzeltmesi
#  KANUNDA degil TEBLIGDE.
#
#  NE YAPAR: mevzuat.gov.tr'nin kendi arama ucundan (MevzuatDatatable) teblig
#  fihristini sayfa sayfa tarar, basligi verilen desene uyanlari toplar ve
#  manifeste eklenecek satirlari cikarir. PARA HARCAMAZ (API cagrisi yok).
#
#  KURAL (KURALLAR.md #1): dogrulanmamis belge ambara girmez. Robot yalnizca
#  BASLIGI eslesen ve mevzuatNo'su gecerli kayitlari yazar; her satirin RG
#  tarih/sayisi da rapora islenir ki insan gozuyle denetlenebilsin.
#
#  KULLANIM:
#    ./motor/teblig-hasat.ps1                 # KURU KOSU - yalniz olcer, rapor yazar
#    ./motor/teblig-hasat.ps1 -uygula         # manifeste ekler (mevcut slug'lara dokunmaz)
#    ./motor/teblig-hasat.ps1 -desen 'KATMA DEĞER'   # baska teblig ailesi
#  Cikti: veri/teblig-hasat-raporu.json
# ============================================================================
param(
  [switch]$uygula,
  [string]$desen = 'VERGİ USUL KANUNU GENEL TEBLİĞİ',
  [string]$slugOnek = 'vukgt',
  [int]$tavan = 400          # tek kosuda en fazla kac teblig alinsin (guvenlik)
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)
$raporYol = Join-Path $kok 'veri/teblig-hasat-raporu.json'
function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), $enc) }
trap {
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$UC = 'https://www.mevzuat.gov.tr/Anasayfa/MevzuatDatatable'
$H  = @{ 'User-Agent'='Mozilla/5.0'; 'X-Requested-With'='XMLHttpRequest'; 'Referer'='https://www.mevzuat.gov.tr/' }

function Sayfa([int]$bas, [int]$boy){
  $govde = [ordered]@{ draw=1; start=$bas; length=$boy; parameters=[ordered]@{ AranacakIfade=$desen; AranacakYer='1'; MevzuatTur='9'; TertipNo='5' } }
  $json = ConvertTo-Json -InputObject $govde -Depth 4 -Compress
  # UTF-8 byte govdesi sart: Turkce harfli arama ifadesi ANSI gidince sonuc bosalir (02.08 olcumu)
  $c = Invoke-WebRequest -Method Post -Uri $UC -Headers $H -ContentType 'application/json; charset=utf-8' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 90 -UseBasicParsing
  $ham = if($c.RawContentStream){ [Text.Encoding]::UTF8.GetString($c.RawContentStream.ToArray()) } else { "$($c.Content)" }
  return ($ham | ConvertFrom-Json)
}

Write-Host ("Desen: '{0}'  (MevzuatTur=9 Teblig, Tertip 5)" -f $desen)
$ilk = Sayfa 0 1
$toplam = [int]$ilk.recordsTotal
Write-Host ("Fihristte eslesen kayit: {0}" -f $toplam)
if($toplam -eq 0){ Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='SONUC YOK'; desen=$desen }); exit 0 }

# Basligi GERCEKTEN desene uyanlari sec: arama ucu tam-metin de tarayabiliyor,
# o yuzden gelen her kayit teblig ailemizden degil. Baslik suzgeci sart.
$normDesen = ($desen.ToUpperInvariant() -replace '[İI]','I' -replace '[ĞG]','G' -replace '[ÜU]','U' -replace '[ŞS]','S' -replace '[ÖO]','O' -replace '[ÇC]','C')
$bulunan = New-Object System.Collections.Generic.List[object]
$gorulen = New-Object 'System.Collections.Generic.HashSet[string]'
$bas = 0; $boy = 100
while($bas -lt $toplam -and $bulunan.Count -lt $tavan){
  $s = Sayfa $bas $boy
  $veri = @($s.data)
  if($veri.Count -eq 0){ break }
  foreach($d in $veri){
    # 02.08 TUZAK: arama ucu eslesen kelimeleri <span style='background-color:yellow'>
    # ile SARIYA BOYAYIP donduruyor. Etiketi temizlemeden eslestirirsen desen
    # ikiye bolunur ve 1.364 kaydin yalnizca 187'si tutar - kalani sessizce
    # kaybolur. Once HTML soyulur, sonra eslestirilir.
    $ad = ((("$($d.mevAdi)" -replace '<[^>]+>','') -replace '&amp;','&' -replace '&nbsp;',' ' -replace '\s+',' ')).Trim()
    $normAd = ($ad.ToUpperInvariant() -replace '[İI]','I' -replace '[ĞG]','G' -replace '[ÜU]','U' -replace '[ŞS]','S' -replace '[ÖO]','O' -replace '[ÇC]','C')
    if(-not $normAd.Contains($normDesen)){ continue }
    $no = "$($d.mevzuatNo)"
    if([string]::IsNullOrWhiteSpace($no) -or -not $gorulen.Add($no)){ continue }
    # seri/sira numarasini baslikten cikar (slug icin)
    $seri = ''
    $m = [regex]::Match($ad, '(?i)(?:SERİ|SIRA)\s*NO\s*[:\-]?\s*(\d+)')
    if($m.Success){ $seri = $m.Groups[1].Value }
    $slug = if($seri){ "$slugOnek$seri" } else { "$slugOnek-$no" }
    $bulunan.Add([pscustomobject]@{
      slug = $slug; ad = $ad; pdfId = "G9:$no"
      rg_tarih = "$($d.resmiGazeteTarihi)"; rg_sayi = "$($d.resmiGazeteSayisi)"
    })
  }
  $bas += $boy
  Write-Host ("  ... tarandi {0}/{1}, eslesen {2}" -f ([Math]::Min($bas,$toplam)), $toplam, $bulunan.Count)
}

# manifestte zaten olanlari ayikla
$manifestYol = Join-Path $kok 'veri/mevzuat-kaynaklar.json'
$man = Get-Content $manifestYol -Raw -Encoding UTF8 | ConvertFrom-Json
$mevcutPdf = @{}; foreach($k in $man.kanunlar){ $mevcutPdf["$($k.pdfId)"] = 1 }
$yeni = @($bulunan | Where-Object { -not $mevcutPdf.ContainsKey($_.pdfId) })
Write-Host ("Eslesen teblig: {0} | manifestte olmayan (YENI): {1}" -f $bulunan.Count, $yeni.Count)

$eklenen = 0
if($uygula -and $yeni.Count){
  $liste = [System.Collections.Generic.List[object]]::new()
  foreach($k in $man.kanunlar){ $liste.Add($k) }
  # seyrek=true: teblig arsivi HER GUN indirilmez. 185 teblig gunluk aynaya
  # eklenirse kosu 4 saatten 8+ saate cikar ve kanunlarin tazeligi gecikir.
  # Ilk kosuda hepsi yutulur (durumda kaydi yok), sonra HAFTADA BIR tazelenir;
  # ZORLA=1 her zaman yeniden yutar. Metin ambara girer, kimse kor kalmaz.
  foreach($y in $yeni){ $liste.Add([pscustomobject]@{ slug=$y.slug; ad=$y.ad; pdfId=$y.pdfId; seyrek=$true }); $eklenen++ }
  $man.kanunlar = $liste.ToArray()
  [IO.File]::WriteAllText($manifestYol, ($man | ConvertTo-Json -Depth 6), $enc)
  Write-Host ("MANIFESTE EKLENDI: {0} teblig (toplam kaynak {1})" -f $eklenen, $man.kanunlar.Count)
}

Rapor ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($uygula){'UYGULA'}else{'KURU KOSU'})
  desen = $desen
  fihrist_kayit = $toplam
  baslik_eslesen = $bulunan.Count
  manifestte_olmayan = $yeni.Count
  eklenen = $eklenen
  ornekler = @($yeni | Select-Object -First 40)
  not = "Robot yalniz BASLIGI desene uyan kayitlari alir; RG tarih/sayi da yazilir ki insan denetleyebilsin. Eklenen tebligler bir sonraki Kanun Aynasi kosusunda bolum parcalayicisiyla yutulur."
})
Write-Host ("-> {0}" -f $raporYol)
